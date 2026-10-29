package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*
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

/// The same workspace with the CONVERGED public detail as its own page: the
/// handwritten page keeps the app's layout, the public page is one
/// `cjguiSharedEditableDetailFields` call over the same binding, and both edit
/// the same record. The two-page composition above stays available for the
/// shipped contract test.
public func ruleDetailTabWorkspaceWithPublicDetail(state: CjguiComposableUiTabsState,
    basicPage: CjguiComposableUiNode, publicDetailPage: CjguiComposableUiNode,
    retentionPage: CjguiComposableUiNode): CjguiComposableUiNode {
    let scope = CjguiComposableUiIdentityScope("rule-detail-pages")
    let pages = ArrayList<CjguiComposableUiTabPage>()
    pages.add(CjguiComposableUiTabPage("basic", "基本", basicPage))
    pages.add(CjguiComposableUiTabPage("publicDetail", "公共详情", publicDetailPage))
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
    /// Optional demonstration load for the table cluster. Rows are created
    /// through the same public owner entry as a human "新增", never injected
    /// into a second store; zero leaves the example's normal startup empty.
    let seedTableRows: Int64
    let performanceScene: Bool
    let observeCosts: Bool
    /// Presentation preferences live beside, never inside, the rule document.
    /// An empty explicit value derives `<document>.cjgui-views`; no document
    /// means no preference file until `--view-preferences` is supplied.
    let viewPreferencesPath: String
    /// A saved `cjgui.ui-document` to load through the ordinary generated
    /// structure candidate on startup. Empty keeps the historic startup.
    let uiDocumentPath: String
    init(openPath: String, saveAsPath: String, verifiesHostCloseDecisions: Bool, measurementDurationMs: Int64,
        measurementWarmupMs: Int64, retentionMinimum: Int64, retentionMaximum: Int64,
        retentionPreset!: String = "", seedTableRows!: Int64 = 0, viewPreferencesPath!: String = "",
        performanceScene!: Bool = false, observeCosts!: Bool = false, uiDocumentPath!: String = "") {
        this.openPath = openPath
        this.saveAsPath = saveAsPath
        this.verifiesHostCloseDecisions = verifiesHostCloseDecisions
        this.measurementDurationMs = measurementDurationMs
        this.measurementWarmupMs = measurementWarmupMs
        this.retentionMinimum = retentionMinimum
        this.retentionMaximum = retentionMaximum
        this.retentionPreset = retentionPreset
        this.seedTableRows = seedTableRows
        this.performanceScene = performanceScene
        this.observeCosts = observeCosts
        this.viewPreferencesPath = viewPreferencesPath
        this.uiDocumentPath = uiDocumentPath
    }
}

/// The visual command role a task area gives an action. Roles map to the
/// PUBLIC theme's primary/secondary action styles (base paint plus the whole
/// interaction set); no consumer-side palette exists for buttons.
enum CjguiRuleSetCommandRole {
    | PRIMARY
    | SECONDARY
}

/// Rule-set presentation adapter for the variable-height range source. It
/// asks the domain for one item only when the composable list materializes
/// that row; it does not copy `collectionSnapshot().allItems()` into a
/// component tree. A row revision is the record's own draft revision, never
/// the collection-wide version, so one changed draft invalidates one cache
/// entry without moving the viewport or selection.
class CjguiRuleSetVirtualListSource <: CjguiComposableUiVariableHeightListSource {
    private let domain: CjguiRuleSetEditingDomain
    // Presentation is refreshed by the controller once per accepted
    // declaration; identity and range remain domain-owned. Keeping ONE source
    // instance lets the public text-filter wrapper cache its visible order
    // across unrelated refreshes.
    private var theme: CjguiComposableUiTheme
    private var bodyStyle: CjguiComposableUiStyle
    private let cardScope: CjguiComposableUiIdentityScope
    // The controller's ONE collection selection; the list only asks whether a
    // stable key is selected so multiple rows paint as selected. The virtual
    // list's own single selected key remains the active detail record.
    private let collectionSelection: ?CjguiComposableUiCollectionSelection

    init(domain: CjguiRuleSetEditingDomain, theme: CjguiComposableUiTheme, bodyStyle: CjguiComposableUiStyle,
        cardScope!: CjguiComposableUiIdentityScope = CjguiComposableUiIdentityScope("rule-record-card"),
        collectionSelection!: ?CjguiComposableUiCollectionSelection = None) {
        this.domain = domain
        this.theme = theme
        this.bodyStyle = bodyStyle
        this.cardScope = cardScope
        this.collectionSelection = collectionSelection
    }
    public func updatePresentation(theme: CjguiComposableUiTheme, bodyStyle: CjguiComposableUiStyle): Unit {
        this.theme = theme
        this.bodyStyle = bodyStyle
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
        // With a shared collection selection attached, the multi-selection is
        // the only source of the selected fill. The single-key virtual-list
        // highlight stays for consumers that have no collection selection; it
        // must not paint a row the person just Command-deselected.
        let multiSelected = if (let Some(selection) <- collectionSelection) {
            selection.isSelected(item.key)
        } else {
            isSelected || isFocused
        }
        let rowTextColor = if (multiSelected) {
            theme.primaryAction.textColor
        } else {
            bodyStyle.textColor
        }
        let rowBackground = if (multiSelected) {
            theme.primaryAction.background
        } else {
            theme.card.background
        }
        // Rows and every child carry a scoped identity: the SAME source is
        // mounted twice (main list and public mount), and the mount wrapper
        // rebases these identities per mount. Raw numeric ids alone would
        // make the second mount duplicate the first scene's ids.
        let rowScope = cardScope.child("rule_${item.resourceId}").child("row")
        let row = cjguiComposableVertical(10000000 + item.resourceId, "rule-row-${item.resourceId}",
            CjguiComposableUiStyle(minHeight: 76, padding: 6, gap: 3, background: rowBackground,
                border: theme.card.border, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily),
            identity: Some(rowScope.local("root")))
        row.add(
            cjguiComposableText(11000000 + item.resourceId, "rule-title-${item.resourceId}", item.title,
                CjguiComposableUiStyle(textColor: rowTextColor, fontFamily: bodyStyle.fontFamily, fontWeight: 0),
                resourceId: item.resourceId, displayValueRole: "applied",
                identity: Some(rowScope.local("title"))))
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
                    maxWidth: 300), resourceId: item.resourceId, displayValueRole: "draft",
                identity: Some(rowScope.local("summary"))))
        // Keep the existing externally discoverable SELECT_RECORD descriptor
        // and action routing while making title/summary ordinary wrapping
        // text children whose height is solved by the regular layout path.
        row.add(
            cjguiComposableButton(100000 + item.resourceId, "rule-select-${item.resourceId}", "选择", "SELECT_RECORD",
                item.resourceId,
                CjguiComposableUiStyle(fixedHeight: 26, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily),
                operationActionName: "SELECT_RECORD", operationResourceId: item.resourceId,
                interactionStyle: theme.secondaryActionInteraction,
                ownerInteractionState: if (multiSelected) { CjguiComposableUiInteractionState.SELECTED } else {
                    CjguiComposableUiInteractionState.NONE
                }, identity: Some(rowScope.local("select"))))
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
class CjguiRuleSetComposableController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiDataTransferProvider & CjguiComposableUiPlatformThemeConsumer & CjguiRuleSetViewStateHost {
    private let domain: CjguiRuleSetEditingDomain
    private let ownerWriteObservation = RuleSetOwnerWriteObservation()
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
    /// Explicit UI-document workflow over the SAME accepted generated region.
    /// It stores only the chosen path, the last saved digest/baseline and the
    /// current operation result; drafts and rule data stay in the domain.
    private let documentSession: CjguiGeneratedUiDocumentSession
    // ONE optional public document composition. The application keeps its
    // business owner, navigation and close policy; this only projects the five
    // document actions, their availability and the status/preview text.
    private let documentWorkspace: CjguiUiDocumentWorkspace
    /// Ordinary path entry for the UI file (open / save-as) reachable from a
    /// blank startup with no CLI document argument. The string is app-owned.
    private var uiDocumentPathInput: String = ""
    // DS51 §12 C1 bounded evidence: how many TEXT_CHANGED deliveries the path
    // draft received, and the exact value the save command read.
    private var pathInputEvents: Int64 = 0
    private var uiWorkspaceVisible: Bool = false
    private var developerInfoVisible: Bool = false
    private var columnEditorVisible: Bool = false
    private var viewToolsVisible: Bool = false
    /// Shared close coordination for the document workspace; the business
    /// close policy stays in the rule domain.
    private let uiCloseGuard: CjguiUiDocumentCloseGuard = CjguiUiDocumentCloseGuard()
    private var uiCloseGuardActive: Bool = false
    private var uiCloseGuardNotice: String = ""
    /// Set when the user settled the document facts and the business close
    /// agreed; the host turn loop performs the real window close.
    private var pendingCloseRequested: Bool = false
    /// True once an explicit document file was accepted (including a legal
    /// empty surface). A missing path stays a save target and may seed the
    /// normal generated detail.
    private var defaultDetailAttempted: Bool = false
    // ONE public viewport for the whole mixed panel: the handwritten form, the
    // tree panel and the generated section all scroll through the same object.
    private let rootViewport: CjguiComposableUiScrollViewport
    // ONE public tab view state for the rule detail pane: "基本" keeps the draft
    // fields, "保留策略" keeps the file/retention work. Which page is ACTIVE is
    // window view state, so an ordinary refresh never moves a person back.
    private let detailTabs: CjguiComposableUiTabsState = CjguiComposableUiTabsState("basic")
    // ONE stable-key virtual source, refreshed in place, plus the PUBLIC
    // text-filter projection over it. Filtering therefore never reparses a
    // displayed row number and never builds a row for every record.
    private let ruleListSource: CjguiRuleSetVirtualListSource
    private let filteredListSource: CjguiComposableUiFilteredListSource
    // The table is a THIRD projection over the same filtered stable-key rows:
    // it owns display order and column projection, never business records.
    private let tableSource: CjguiComposableUiTableSource
    // The SAME records/selection presented by the public generated collection
    // component. This is the second consumer's minimal real mount; it owns a
    // viewport and reveal target separate from the handwritten list/table.
    private let publicCollection: CjguiGeneratedUiCollection
    // Declared columns plus their ONE public layout state. Both the menu and
    // the external action host mutate this object; the table only projects it.
    private let tableColumns: Array<CjguiComposableUiTableColumn>
    private let tableLayout: CjguiComposableUiTableColumnLayout
    // Card mode is the third projection over the same filtered/sorted rows:
    // the public grid source groups them into responsive rows and materializes
    // only visible rows through a normal variable-height list.
    private let cardGridRenderer: CjguiRuleSetCardGridRenderer
    private let cardGridSource: CjguiComposableUiCardGridSource
    private let cardListState: CjguiComposableUiVirtualListState
    // ONE public collection selection shared by the list and table. It stores
    // only stable keys; the active detail record stays the owner's selected
    // record, and drafts are never touched by selection or filtering.
    private let collectionSelection: CjguiComposableUiCollectionSelection
    private let collectionFilteredOrder: CjguiComposableUiFlatCollectionOrder
    private let collectionEligibilityOrder: CjguiComposableUiFlatCollectionOrder
    private let collectionTableOrder: CjguiComposableUiFlatCollectionOrder
    // ONE typed collection view over the same filtered/table/layout objects:
    // mode, query, sort target and stable-key column layout, plus the one
    // presentation revision both a human control and an external client use.
    private let collectionView: CjguiComposableUiCollectionViewState
    // DS51 §12 B3: the ONE public collection workspace this consumer mounts. It
    // joins the existing table/view state with reveal and the view actions; the
    // named preference catalog and the file stay this application's policy.
    private let collectionWorkspace: CjguiCollectionWorkspace
    // Named presets and their separate preference file are application-owned.
    private let viewPreferences: CjguiRuleSetViewPreferences
    private var viewDraftName: String
    // §13 C: the public workspace action bar's SESSION snapshot. Named-view
    // preferences remain the application's separate persistence.
    private var sessionViewSnapshot: String = ""
    private var collectionPrunedVersion: Int64
    private var collectionBatchSerial: Int64
    // The detail pane offers two REAL field/layout combinations over the SAME
    // owner form: "standard" stacks every declared field, "compact" binds the
    // name+enabled pair side by side and presents retention through the
    // declared composite. It is window view state and never submits a draft.
    private var detailLayout: String
    private let recordSearchPanel: CjguiSearchableSelectionPanel
    // The rules business presents its declared boolean field through the same
    // public Select the mixed consumer uses: one option list and one owner
    // writer, so the normal interface and the generated region cannot disagree
    // about the field's value or transaction.
    private let enabledSelectBinding: CjguiSelectFieldBinding
    private let enabledSelect: CjguiSelect
    private let enabledTooltip = CjguiTooltip("rule-enabled-tip", "rule-enabled-tip")
    private var panelWindow: ?CjguiComposableUiWindow = None
    // The edit dialog's return target is the public node reference of the
    // control that owned input when the modal opened. The window's existing
    // modal-return machinery consumes it as the layer anchor; this is not a
    // second focus state machine.
    private var editDialogReturnTarget: ?CjguiComposableUiNodeReference = None
    private var editDialogReturnRecordId: Int64 = -1

    init(domain: CjguiRuleSetEditingDomain, presetOverride!: String = "",
        viewPreferencesPath!: String = "", uiDocument!: String = "") {
        this.domain = domain
        this.treePanel = CjguiRuleSetTreePanel(domain)
        this.generatedRegion = CjguiRuleSetGeneratedRegion(domain, presetOverride: presetOverride)
        this.documentSession = CjguiGeneratedUiDocumentSession(path: uiDocument,
            historyPolicy: Some(CjguiUiDocumentHistoryPolicy(maximumTransactions: 16,
                maximumSerializedBytes: 1048576)))
        this.uiDocumentPathInput = uiDocument
        this.documentWorkspace = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("rule-set"), "ui-document",
            this.documentSession, this.generatedRegion,
            title: "界面文档 · 保存与重新载入")
        this.uiCloseGuard.add(this.documentWorkspace)
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
        this.viewDraftName = ""
        this.detailLayout = "standard"
        this.recordSearchPanel = CjguiSearchableSelectionPanel("rule-record-search")
        let declaredEnabled = this.generatedRegion.enabledSelectBinding()
        this.enabledSelectBinding = declaredEnabled
        this.enabledSelect = declaredEnabled.select
        this.editDialogReturnTarget = None
        this.editDialogReturnRecordId = -1
        let selection = CjguiComposableUiCollectionSelection()
        this.collectionSelection = selection
        this.collectionPrunedVersion = -1
        this.collectionBatchSerial = 0
        let baseListSource = CjguiRuleSetVirtualListSource(domain, CjguiComposableUiTheme.paperLight(),
            CjguiComposableUiStyle(), cardScope: recordCardScope, collectionSelection: Some(selection))
        this.ruleListSource = baseListSource
        this.collectionEligibilityOrder = CjguiComposableUiFlatCollectionOrder(baseListSource,
            { item => item.resourceId >= 0 })
        this.filteredListSource = CjguiComposableUiFilteredListSource(baseListSource,
            { item => item.title })
        this.collectionFilteredOrder = CjguiComposableUiFlatCollectionOrder(filteredListSource,
            { item => item.resourceId >= 0 })
        let tableColumns = CjguiRuleSetTableColumns.create(domain)
        let tableLayout = CjguiComposableUiTableColumnLayout(tableColumns)
        this.tableColumns = tableColumns
        this.tableLayout = tableLayout
        let table = CjguiComposableUiTableSource(filteredListSource, "rule-set-table",
            tableColumns,
            CjguiRuleSetTableColumns.style(CjguiComposableUiTheme.paperLight(),
                CjguiComposableUiStyle()),
            rowAction: { item =>
                if (item.resourceId >= 0) {
                    CjguiComposableUiTableRowAction("SELECT_RECORD", item.resourceId)
                } else {
                    CjguiComposableUiTableRowAction.none()
                }
            }, rowSelected: { key => selection.isSelected(key) }, layout: tableLayout)
        this.tableSource = table
        this.publicCollection = CjguiGeneratedUiCollection("ruleRecords", "ruleRecordCollection",
            filteredListSource, table, selection)
        this.collectionTableOrder = CjguiComposableUiFlatCollectionOrder(table,
            { item => item.resourceId >= 0 })
        let cardRenderer = CjguiRuleSetCardGridRenderer(domain,
            CjguiComposableUiTheme.paperLight(), CjguiComposableUiStyle())
        this.cardGridRenderer = cardRenderer
        this.cardListState = CjguiComposableUiVirtualListState()
        this.cardGridSource = CjguiComposableUiCardGridSource(table, "rule-set-cards",
            CjguiComposableUiCardGridSpec(190, 118, columnGap: 10, rowGap: 10),
            { item, context => cardRenderer.build(item, context) },
            actionOf: { item =>
                if (item.resourceId >= 0) {
                    CjguiComposableUiTableRowAction("SELECT_RECORD", item.resourceId)
                } else {
                    CjguiComposableUiTableRowAction.none()
                }
            },
            selectedOf: { key => selection.isSelected(key) },
            focusedKeyOf: { => selection.focus() })
        let view = CjguiComposableUiCollectionViewState(table, ["list", "table", "grid"], "list")
        this.collectionView = view
        let workspaceModes = HashMap<String, String>()
        workspaceModes.add("list", "list")
        workspaceModes.add("table", "table")
        workspaceModes.add("grid", "grid")
        this.collectionWorkspace = CjguiCollectionWorkspace(publicCollection, view,
            CjguiComposableUiIdentityScope("rule-set-collection-workspace"),
            title: "规则集合", modePresentations: workspaceModes)
        // The generated region may mount the SAME public collection declaration:
        // one catalog registration, no second registry or hand-built view state.
        let _ = this.generatedRegion.registerCollection(publicCollection)
        let preferences = CjguiRuleSetViewPreferences()
        this.viewPreferences = preferences
        if (viewPreferencesPath.size > 0) {
            preferences.setFilePath(viewPreferencesPath)
            let loaded = preferences.load(viewPreferencesPath)
            if (!loaded.applied) {
                this.inputNotice = "视图偏好未载入：${loaded.reason}"
            } else if (preferences.activeName().size > 0) {
                if (let Some(snapshot) <- preferences.snapshot(preferences.activeName())) {
                    let restored = view.applySnapshot(snapshot)
                    if (!restored.applied) {
                        this.inputNotice = "视图偏好未恢复：${restored.reason}"
                    }
                }
                this.viewDraftName = preferences.activeName()
            }
        }
        domain.attachViewStateHost(this)
    }

    /// The searchable-record panel restores focus through the accepted layer
    /// machinery, so it needs the ordinary window it is presented in.
    public func bindWindow(window: CjguiComposableUiWindow): Unit {
        panelWindow = Some(window)
    }

    /// Called after each normal window turn. A confirmed record action leaves
    /// the panel only after its modal layer closed AND focus restoration
    /// finished; cancellation consumes no business action and returns focus to
    /// the control that opened the panel.
    public func finishPanelAction(window: CjguiComposableUiWindow): Unit {
        if (let Some(item) <- recordSearchPanel.takeConfirmed(window)) {
            if (let Some(recordId) <- Int64.tryParse(item.key)) {
                let result = domain.selectCollectionItemFromHuman(recordId)
                if (result.applied) {
                    listState.setFocusedKey("rule_${recordId}")
                    listState.setSelectedKey("rule_${recordId}")
                    inputNotice = "已定位规则：${item.title}"
                } else {
                    inputNotice = "定位未应用：${result.reason}"
                }
            } else {
                inputNotice = "定位未应用：记录标识无效"
            }
            localRevision += 1
            window.requestRefresh()
        }
        let failure = recordSearchPanel.takeConfirmationFailure()
        if (failure.size > 0) {
            inputNotice = "焦点恢复失败，未执行查找操作：${failure}"
            localRevision += 1
            window.requestRefresh()
        }
    }

    /// Called from the ordinary turn loop. A confirmed document reload is one
    /// submitted candidate; its acceptance becomes visible here without a
    /// second session-owned interface tree.
    public func finishUiDocumentAction(window: CjguiComposableUiWindow): Unit {
        let done = settleStartupDocument()
        if (done.reason == "ui_document_pending" || done.reason == "ui_document_no_submission" || done.reason ==
            "ui_document_ticket_mismatch") {
            return
        }
        localRevision += 1
        window.requestRefresh()
        getStdOut().writeln(
            "RULE_SET_UI_DOCUMENT_SETTLED state=${done.reason} " +
                "accepted=${done.accepted} version=${generatedRegion.acceptedStructureVersion()} " +
                "saved=${documentSession.savedDigest()}")
        if (done.accepted) {
            getStdOut().writeln(
                "RULE_SET_UI_DOCUMENT_ACCEPTED " + "version=${generatedRegion.acceptedStructureVersion()} " +
                    "digest=${documentSession.savedDigest()}")
        }
        getStdOut().flush()
    }

    /// Shared lifecycle facts remain in the bound session, including when the
    /// close guard consumes a startup ticket before the next ordinary turn.
    public func uiDocumentLoaded(): Bool {
        let result = documentWorkspace.startupResult()
        return result.accepted || (result.applied && result.reason == "ui_document_file_adopted")
    }

    public func hasPendingStartupDocument(): Bool {
        return documentWorkspace.startupPending()
    }

    public func beginStartupUiDocument(path: String): CjguiUiDocumentSessionResult {
        let done = documentWorkspace.beginStartup(path)
        if (done.applied && done.reason == "ui_document_file_adopted") {
            reportStartupDocumentResult(done, 0)
        }
        localRevision += 1
        return done
    }

    private func reportStartupDocumentResult(done: CjguiUiDocumentSessionResult,
        waitTurns: Int64): Unit {
        if (!done.startup || done.reason == "ui_document_pending" ||
            done.reason == "ui_document_ticket_mismatch") { return }
        let state = if (done.accepted || (done.applied && done.reason == "ui_document_file_adopted")) {
            "LOADED"
        } else { "SETTLED" }
        getStdOut().writeln("CJGUI_RULE_SET_UI_DOCUMENT_${state} reason=${done.reason} " +
            "version=${done.version} token=${done.token} file_sha=${done.fileDigest} " +
            "path=${done.path} startup_turns=${waitTurns}")
        getStdOut().flush()
    }

    /// A thin normal-turn call; the public workspace owns completion and close
    /// provenance. There is no application token/digest observer to resettle.
    public func settleStartupDocument(waitTurns!: Int64 = -1): CjguiUiDocumentSessionResult {
        let done = documentWorkspace.finish()
        reportStartupDocumentResult(done, waitTurns)
        return done
    }

    public func takePendingCloseRequest(): Bool {
        let value = pendingCloseRequested
        pendingCloseRequested = false
        return value
    }

    /// The startup file became the accepted document without a submit (exact
    /// parse + accepted surface, or a legal empty file). The shared session
    /// adopts that REAL baseline so restore/preview start from the file.
    public func adoptUiDocumentBaseline(version: Int64, digest: String): Unit {
        documentSession.adoptAcceptedBaseline(version, digest)
    }

    /// Seeds ONE non-empty generated detail when no document was loaded and the
    /// region is still empty. The structure is composed through the public
    /// encoder and submitted through the ordinary candidate path; there is no
    /// per-layout factory or private write. Up to two real records become two
    /// distinct owner instances.
    public func ensureDefaultGeneratedDetail(): String {
        if (uiDocumentLoaded() || defaultDetailAttempted ||
            documentSession.stateFor(generatedRegion).mode != "idle") { return "" }
        if (generatedRegion.acceptedStructureVersion() != 0 ||
            generatedRegion.candidateStructureVersion() > 0) {
            return ""
        }
        let snapshot = domain.snapshot()
        if (snapshot.records.size == 0) { return "" }
        let first = snapshot.records[0]
        let second: ?CjguiRuleSetRecord = if (snapshot.records.size > 1) {
            Some(snapshot.records[1])
        } else {
            None
        }
        defaultDetailAttempted = true
        let payload = ruleSetDefaultDetailPayload(first.id, first.label, second)
        let submitted = generatedRegion.submitStructure(payload, 0)
        if (!submitted.candidateAccepted) {
            return "rejected:${submitted.reason}"
        }
        return "submitted:${submitted.candidateToken}"
    }

    /// The default detail is an ordinary public document: one runtime
    /// composition plus the real record keys it instances. Field, Select and
    /// action owners stay in the rule domain.
    private func ruleSetDefaultDetailPayload(firstId: Int64, firstLabel: String,
        second: ?CjguiRuleSetRecord): String {
        let parameters = ArrayList<CjguiCompositionParameter>()
        parameters.add(CjguiCompositionParameter("title", "STRING", maxLength: 40,
            defaultValue: "规则"))
        let elements = ArrayList<CjguiCompositeElementSpec>()
        elements.add(CjguiCompositeElementSpec("name", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "label", argumentName: "text", label: "名称"))
        elements.add(CjguiCompositeElementSpec("notes", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "notes", argumentName: "text", label: "备注"))
        elements.add(CjguiCompositeElementSpec("enabled", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "enabled", argumentName: "value", label: "启用"))
        elements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
            actionName: "APPLY_DRAFT", label: "应用草稿"))
        elements.add(CjguiCompositeElementSpec("cancel", CJGUI_COMPOSITE_ELEMENT_ACTION,
            actionName: "CANCEL_DRAFT", label: "取消草稿"))
        let actions = ArrayList<CjguiCompositionTemplateNode>()
        actions.add(CjguiCompositionTemplateNode("apply", CJGUI_COMPOSITION_NODE_ELEMENT,
            elementKey: "apply", presentation: CJGUI_COMPOSITION_PRESENTATION_TEXT))
        actions.add(CjguiCompositionTemplateNode("cancel", CJGUI_COMPOSITION_NODE_ELEMENT,
            elementKey: "cancel", presentation: CJGUI_COMPOSITION_PRESENTATION_TEXT))
        let children = ArrayList<CjguiCompositionTemplateNode>()
        children.add(CjguiCompositionTemplateNode("title", CJGUI_COMPOSITION_NODE_LABEL,
            text: "$" + "{title}"))
        children.add(CjguiCompositionTemplateNode("name", CJGUI_COMPOSITION_NODE_ELEMENT,
            elementKey: "name", presentation: CJGUI_COMPOSITION_PRESENTATION_TEXT))
        children.add(CjguiCompositionTemplateNode("notes", CJGUI_COMPOSITION_NODE_ELEMENT,
            elementKey: "notes", presentation: CJGUI_COMPOSITION_PRESENTATION_TEXT))
        children.add(CjguiCompositionTemplateNode("enabled", CJGUI_COMPOSITION_NODE_ELEMENT,
            elementKey: "enabled", presentation: CJGUI_COMPOSITION_PRESENTATION_SELECT))
        children.add(CjguiCompositionTemplateNode("actions", CJGUI_COMPOSITION_NODE_HORIZONTAL,
            gap: 4, children: actions))
        let template = CjguiCompositionTemplateNode("root", CJGUI_COMPOSITION_NODE_VERTICAL,
            gap: 6, padding: 4, children: children)
        let definition = CjguiRuntimeCompositionDefinition("ruleDetailCard", parameters,
            elements, template, expandedNodeLimit: 64, expandedDepthLimit: 8)
        let definitionText = cjguiCompositionDefinitionPayload(definition)
        let cards = ArrayList<CjguiGeneratedUiNodeSpec>()
        let firstProperties = HashMap<String, String>()
        firstProperties.add("title", firstLabel)
        cards.add(CjguiGeneratedUiNodeSpec("rule${firstId}", "ruleDetailCard",
            properties: firstProperties))
        if (let Some(value) <- second) {
            let secondProperties = HashMap<String, String>()
            secondProperties.add("title", value.label)
            cards.add(CjguiGeneratedUiNodeSpec("rule${value.id}", "ruleDetailCard",
                properties: secondProperties))
        }
        // The default seed is a card-detail presentation only. A generated
        // collection mount is exercised through the explicit public mount path;
        // including it in the startup seed made the accepted scene fail to
        // prepare (duplicate instance lifecycle) before any human interaction.
        let root = CjguiGeneratedUiNodeSpec("rule-default-detail", "vertical",
            children: cards)
        return CjguiGeneratedUiEncoding.encodeCandidate(root, 2,
            definitions: definitionText)
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
            generatedRegion.revision()).saturatingAdd(treePanel.viewRevision()).saturatingAdd(
            recordSearchPanel.revision()).saturatingAdd(collectionView.revision()).saturatingAdd(
            tableLayout.revision()).saturatingAdd(cardGridSource.measurementGeneration())
    }

    // --- shared view-state host (human controls and external verbs) ----------

    public func viewStateField(name: String): String {
        if (name == "tableColumns") {
            return tableLayout.encodeState()
        }
        if (name == "tableColumnsRevision") {
            return tableLayout.revision().toString()
        }
        if (name == "collectionView") {
            return collectionWorkspace.encodedSnapshot()
        }
        if (name == "collectionViews") {
            return viewPreferences.catalog()
        }
        if (name == "collectionViewRevision") {
            return collectionView.revision().toString()
        }
        if (name == "collectionViewsRevision") {
            return viewPreferences.revision().toString()
        }
        if (name == "collectionViewDirty") {
            return if (viewPreferences.isDirty()) { "true" } else { "false" }
        }
        return ""
    }

    /// Human controls and external verbs both reach this function through the
    /// domain's executeFromHuman/executeFromExternal entry. Column actions use
    /// the published layout revision; preset reads/writes use the collection
    /// view revision; catalog saves use the preset-catalog revision. None of
    /// these borrow the document version.
    public func applyViewStateAction(
        invocation: CjguiSharedOperationActionInvocation
    ): CjguiSharedOperationActionResult {
        let action = invocation.actionName
        // Detail layout is a pure view choice; the generated action carries no
        // business target/version and only changes this window's presentation.
        if (action == "SET_DETAIL_LAYOUT_STANDARD" || action == "SET_DETAIL_LAYOUT_COMPACT") {
            detailLayout = if (action == "SET_DETAIL_LAYOUT_COMPACT") { "compact" } else { "standard" }
            let draft = domain.formSnapshot()
            let layoutLabel = if (detailLayout == "compact") { "紧凑" } else { "标准" }
            inputNotice = "已切换到${layoutLabel}字段布局；草稿 v${draft.draftVersion} 未提交"
            localRevision += 1
            return CjguiSharedOperationActionResult(true, false, 0, 0, "detail_layout_set")
        }
        let columnAction = action == "SET_TABLE_COLUMN_WIDTH" || action == "SET_TABLE_COLUMN_VISIBLE" ||
            action == "MOVE_TABLE_COLUMN" || action == "RESET_TABLE_COLUMNS"
        let saveViewAction = action == "SAVE_COLLECTION_VIEW"
        let savePreferencesAction = action == "SAVE_COLLECTION_VIEW_PREFERENCES"
        let selectOrResetAction = action == "SELECT_COLLECTION_VIEW" ||
            action == "RESET_COLLECTION_VIEW"
        let modeAction = action == "SET_COLLECTION_VIEW_MODE"
        if (!columnAction && !saveViewAction && !savePreferencesAction && !selectOrResetAction &&
            !modeAction) {
            return CjguiSharedOperationActionResult(false, false, 0, 0, "unknown_view_state_action")
        }
        let before = if (columnAction) {
            tableLayout.revision()
        } else if (saveViewAction || savePreferencesAction) {
            viewPreferences.revision()
        } else {
            collectionView.revision()
        }
        if (!CjguiRuleSetEditingDomain.isRuleSetActionTarget(invocation.targetResourceIds)) {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_target")
        }
        if (invocation.expectedVersion != before) {
            return CjguiSharedOperationActionResult(false, true, before, before,
                "view_state_version_conflict")
        }
        let key = viewStateString(invocation, "columnKey")
        var accepted = false
        var reason = "unknown_view_state_action"
        if (action == "SET_TABLE_COLUMN_WIDTH") {
            if (!tableColumnKeys().contains(key)) {
                reason = "unknown_column"
            } else if (let Some(width) <- viewStateInteger(invocation, "width")) {
                let _ = tableLayout.setWidth(key, width)
                accepted = true
                reason = "column_width_set"
            } else {
                reason = "invalid_width"
            }
        } else if (action == "SET_TABLE_COLUMN_VISIBLE") {
            if (!tableColumnKeys().contains(key)) {
                reason = "unknown_column"
            } else if (let Some(visible) <- viewStateBoolean(invocation, "visible")) {
                if (tableLayout.setVisible(key, visible)) {
                    accepted = true
                    reason = "column_visibility_set"
                } else {
                    reason = if (tableLayout.isVisible(key) == visible) {
                        "column_visibility_unchanged"
                    } else {
                        "last_visible_column"
                    }
                }
            } else {
                reason = "invalid_visibility"
            }
        } else if (action == "MOVE_TABLE_COLUMN") {
            if (!tableColumnKeys().contains(key)) {
                reason = "unknown_column"
            } else if (let Some(offset) <- viewStateInteger(invocation, "offset")) {
                let _ = tableLayout.move(key, offset)
                accepted = true
                reason = "column_moved"
            } else {
                reason = "invalid_offset"
            }
        } else if (action == "RESET_TABLE_COLUMNS") {
            let _ = tableLayout.reset()
            accepted = true
            reason = "columns_reset"
        } else if (saveViewAction) {
            let name = viewStateString(invocation, "name")
            if (name.size == 0) {
                reason = "invalid_view_name"
            } else {
                let changed = viewPreferences.upsert(name, collectionView.snapshot())
                let catalogReason = viewPreferences.lastReason()
                if (changed || catalogReason == "view_unchanged") {
                    accepted = true
                    reason = catalogReason
                    viewDraftName = name
                } else {
                    reason = catalogReason
                }
            }
        } else if (action == "SELECT_COLLECTION_VIEW") {
            let name = viewStateString(invocation, "name")
            if (name.size == 0) {
                reason = "invalid_view_name"
            } else if (let Some(snapshot) <- viewPreferences.snapshot(name)) {
                let encoded = CjguiComposableUiCollectionViewCodec.encode(snapshot)
                let restored = collectionWorkspace.restoreEncoded(encoded)
                if (restored.applied) {
                    let _ = viewPreferences.setActive(name)
                    viewDraftName = name
                    syncCollectionFocusWithView()
                    inputNotice = collectionWorkspace.status()
                    accepted = true
                    reason = "view_selected"
                } else {
                    reason = restored.reason
                }
            } else {
                reason = "unknown_view"
            }
        } else if (action == "RESET_COLLECTION_VIEW") {
            let reset = collectionWorkspace.resetView()
            if (reset.applied) {
                let _ = viewPreferences.clearActive()
                viewDraftName = ""
                syncCollectionFocusWithView()
                inputNotice = reset.status
                accepted = true
                reason = "view_reset"
            } else {
                reason = reset.reason
            }
        } else if (modeAction) {
            let mode = viewStateString(invocation, "mode")
            if (mode.size == 0) {
                reason = "invalid_view_mode"
            } else if (!collectionView.validModeNames().contains(mode)) {
                reason = "unknown_view_mode"
            } else if (collectionWorkspace.setMode(mode)) {
                syncCollectionFocusWithView()
                accepted = true
                reason = "view_mode_set"
            } else {
                accepted = true
                reason = "view_mode_unchanged"
            }
        } else if (savePreferencesAction) {
            let saved = viewPreferences.save(viewPreferences.filePath(),
                protectedViewPreferencePaths())
            accepted = saved.applied
            reason = saved.reason
        }
        let after = if (columnAction) {
            tableLayout.revision()
        } else if (saveViewAction || savePreferencesAction) {
            viewPreferences.revision()
        } else {
            collectionView.revision()
        }
        if (columnAction && after != before) {
            collectionView.notePresentationChanged()
        }
        if (after != before || (accepted && !columnAction)) {
            localRevision += 1
        }
        return CjguiSharedOperationActionResult(accepted, false, before, after, reason)
    }

    private func viewStateString(invocation: CjguiSharedOperationActionInvocation,
        name: String): String {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "STRING") {
                return argument.value.stringValue
            }
        }
        return ""
    }

    private func viewStateInteger(invocation: CjguiSharedOperationActionInvocation,
        name: String): ?Int64 {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "INTEGER") {
                return Some(argument.value.integerValue)
            }
        }
        return None
    }

    private func viewStateBoolean(invocation: CjguiSharedOperationActionInvocation,
        name: String): ?Bool {
        for (argument in invocation.arguments) {
            if (argument.name == name && argument.value.valueType == "BOOLEAN") {
                return Some(argument.value.booleanValue)
            }
        }
        return None
    }

    private func tableColumnKeys(): ArrayList<String> {
        return tableLayout.columnKeys()
    }

    /// Human preset controls use the SAME domain view-state entry external
    /// clients use. Only the preset name is added as an ordinary argument.
    private func executeViewStateFromHuman(actionName: String, expectedVersion: Int64,
        name: String): CjguiSharedOperationActionResult {
        let arguments = ArrayList<CjguiSharedOperationActionArgument>()
        if (name.size > 0) {
            arguments.add(CjguiSharedOperationActionArgument("name",
                CjguiSharedOperationValue.string(name)))
        }
        return domain.executeFromHuman(CjguiSharedOperationActionInvocation(actionName,
            expectedVersion, ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
            arguments))
    }

    private func viewPresetIndex(semanticId: String): Int64 {
        let parts = semanticId.split("view-preset-")
        if (parts.size == 2) {
            if (let Some(index) <- Int64.tryParse(parts[1])) {
                return index
            }
        }
        return -1
    }

    public func collectionViewState(): CjguiComposableUiCollectionViewState {
        return collectionView
    }

    public func viewPreferencesStore(): CjguiRuleSetViewPreferences {
        return viewPreferences
    }

    public func viewPreferencesPath(): String {
        return viewPreferences.filePath()
    }

    /// Paths a preference write must never replace. The current document path
    /// is read at write time (not startup), and the pending save-as input is
    /// included when it names a different target. The preference store applies
    /// ordinary relative/absolute normalization to both sides.
    private func protectedViewPreferencePaths(): ArrayList<String> {
        let paths = ArrayList<String>()
        let documentPath = domain.snapshot().filePath
        if (documentPath.size > 0) {
            paths.add(documentPath)
        }
        if (filePath.size > 0 && !paths.contains(filePath)) {
            paths.add(filePath)
        }
        return paths
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
        if (node.actionName == CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION) {
            return tableLayout.resizeCaptureVersion()
        }
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
        let workspaceWidth = workspaceContentWidth()
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
        // The ONE list source is refreshed in place, then the PUBLIC text
        // filter projects it. The applied-data revision invalidates a cached
        // visible order, while an unrelated event (focus, theme) does not.
        ruleListSource.updatePresentation(theme, bodyStyle)
        tableSource.updatePresentation(CjguiRuleSetTableColumns.style(theme, bodyStyle))
        cardGridRenderer.updatePresentation(theme, bodyStyle)
        // Sorting and filtering are projections over ONE owner-backed source.
        // Both revisions are refreshed here; a rebuild per frame never scans.
        tableSource.dataChanged(domain.version())
        let _ = collectionWorkspace.projectBusinessQuery(collectionView.query())
        // Responsive card columns use the actual window/first-pane width. The
        // previous top business item is re-revealed only when the grouping or
        // card width really changed, so ordinary refreshes do not reset scroll.
        if (collectionView.mode() == "grid") {
            let anchorKey = cardGridSource.itemKeyForRowStart(cardListState.materializedStart())
            if (cardGridSource.setAvailableWidth(cardGridViewportWidth())) {
                let anchorRowKey = cardGridSource.rowKeyForItem(anchorKey)
                if (anchorRowKey.size > 0) {
                    let _ = cardListState.revealKey(cardGridSource, anchorRowKey)
                }
            }
        }
        // Real deletion / lost eligibility prunes selected keys; a filter that
        // merely hides a selected record does not.
        syncCollectionSelectionWithData()
        let collectionOrder = currentCollectionOrder()
        let selectionCount = collectionSelection.selectedCount()
        let hiddenSelectionCount = collectionSelection.hiddenCount(collectionOrder)
        // External selection reads use the same live object and current order.
        treePanel.attachCollectionSurface(collectionSelection, collectionOrder,
            collectionViewVersion())
        let visibleRuleCount = if (collectionView.mode() == "table" ||
            collectionView.mode() == "grid") {
            tableSource.itemCount()
        } else {
            filteredListSource.visibleCount()
        }
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
        // The header, the split panes and the tree panel together are longer
        // than one screen. ONE public scroll container shares ONE public
        // viewport, so a real wheel gesture and the framework's focus reveal
        // reach the lower content while every author declares only its own
        // content. The generated instanced detail lives in the 公共详情 page
        // and scrolls through its own bounded viewport.
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
        // The header height follows its content. The action row and the
        // secondary view switches wrap when the window is narrow; a fixed
        // header height used to clip the second row.
        let header = cjguiComposableVertical(5, "rule-set-header", CjguiComposableUiStyle(gap: 4),
            layoutReuseKey: "rule-header|applied=${form.appliedConfigVersion}|draft=${form.draftVersion}|dark=${usesDarkAppearance}|mono=${usesMonospacedText}|filter=${collectionView.query()}|view=${collectionView.mode()}|sort=${tableSource.sortColumnKey()}:${tableSource.sortAscending()}|selected=${selectionCount}|hidden=${hiddenSelectionCount}|viewTools=${viewToolsVisible}|columns=${columnEditorVisible}")
        // The header row keeps the document name, the user-readable state and
        // the main file action. Low-frequency commands (copy/delete/undo/redo/
        // new/discard/edit-dialog) live behind the SAME named menu entry; their
        // node ids and semantic ids move with them, so command targeting,
        // keyboard bindings and external discovery stay unchanged.
        let titleRow = cjguiComposableHorizontal(4, "rule-set-title-row", CjguiComposableUiStyle(gap: 8))
        titleRow.add(
            cjguiComposableText(3, "rule-set-title",
                "规则集编辑 · 已应用 v${form.appliedConfigVersion} · 草稿 v${form.draftVersion}", headingStyle,
                resourceId: CjguiRuleSetEditingDomain.ruleSetResourceId, fieldId: "ruleSet", displayValueRole: "applied"))
        // A BUSINESS close refusal owns no UI-document panel. Project it at the
        // top of the page (the same refresh scrolls here) so the reason is
        // visible without another click, tab or wheel gesture.
        if (inputNotice.startsWith("未关闭：")) {
            titleRow.add(cjguiComposableText(6, "rule-close-business-notice", inputNotice,
                CjguiComposableUiStyle(growX: 1, fontSize: 13.0, textColor: bodyStyle.textColor, lineHeight: 19.0,
                    textMaxLines: 2, textOverflow: "ellipsis")))
        }
        // ONE primary action per task area: the top area's main file action is
        // Save. Every other command stays reachable through the named menu and
        // its existing command declaration.
        titleRow.add(command(15, "save", "保存", "SAVE", role: CjguiRuleSetCommandRole.PRIMARY))
        titleRow.add(scopedLocalPresentationButton(18, "open-rule-set-menu", "更多", "OPEN_PRESENTATION_MENU", 68,
            presentationScope.local("open-menu"), styleName: "rule_secondary_action"))
        header.add(titleRow)
        // The close protection is ordinary scene content at the top of the
        // scrolling page, so a blocked close is visible after the same
        // refresh without a second alert or window.
        if (uiCloseGuardActive) {
            root.add(buildUiCloseGuardPanel(theme))
        }
        // The primary filter keeps a usable minimum width; the collection
        // match count lives in the SAME row so the object area's state is one
        // glance, not a separate view row.
        let filterRow = cjguiComposableHorizontal(28, "rule-list-filter-row",
            CjguiComposableUiStyle(gap: 5))
        filterRow.add(
            cjguiComposableTextInput(24, "rule-list-filter", "筛选规则", collectionView.query(), -1,
                CjguiComposableUiStyle(minWidth: 200, fixedHeight: 30, growX: 1, fontSize: inputStyle.fontSize,
                    textColor: inputStyle.textColor, background: inputStyle.background, border: inputStyle.border,
                    borderWidth: inputStyle.borderWidth, fontFamily: inputStyle.fontFamily),
                displayValueRole: "filter", interactionStyle: theme.inputInteraction))
        filterRow.add(
            cjguiComposableButton(25, "rule-list-filter-clear", "清除", "CLEAR_RULE_FILTER", -1,
                presentationButtonStyle(52), enabled: collectionView.query().size > 0))
        filterRow.add(localPresentationButton(27, "open-record-search", "查找规则 ⌘K", "OPEN_RECORD_SEARCH", 110))
        if (collectionView.query().size > 0) {
            filterRow.add(
                cjguiComposableText(26, "rule-list-filter-count",
                    "匹配 ${visibleRuleCount} / 共 ${collection.totalCount}",
                    CjguiComposableUiStyle(fixedHeight: 30, fontSize: 11.0,
                        textColor: bodyStyle.textColor, fontFamily: bodyStyle.fontFamily, textMaxLines: 1,
                        textOverflow: "ellipsis")))
        }
        header.add(filterRow)
        // ONE collection settings entry, collapsed by default: the three view
        // actions used to occupy their own stacked wrap rows in the header even
        // when untouched. The mixed consumer already ships this "视图 / 列"
        // entry over the same public workspace; rules reuses that pattern.
        let viewEntryRow = cjguiComposableHorizontal(209, "rule-view-entry-row",
            CjguiComposableUiStyle(fixedHeight: 30, gap: 5))
        // The interface-document workspace is ordinary business-reachable
        // content: one explicit secondary entry toggles it, so saving and
        // reopening the UI file never depends on a startup argument.
        viewEntryRow.add(localPresentationButton(60034, "toggle-ui-workspace",
            if (uiWorkspaceVisible) { "收起界面" } else { "编辑界面" },
            if (uiWorkspaceVisible) { "CLOSE_UI_WORKSPACE" } else { "OPEN_UI_WORKSPACE" }, 76))
        viewEntryRow.add(localPresentationButton(60032, "toggle-view-tools",
            if (viewToolsVisible) { "收起视图 / 列" } else { "视图 / 列" }, "TOGGLE_VIEW_TOOLS", 96))
        viewEntryRow.add(localPresentationButton(205, "open-view-menu", "视图预设", "OPEN_VIEW_MENU", 76))
        header.add(viewEntryRow)
        if (viewToolsVisible) {
            // The view switches and the public workspace action bar sit on
            // their OWN header rows while expanded: a Wrap nested inside the
            // old view Wrap was measured at one button's width and stacked the
            // three workspace actions vertically in every wide window.
            let detailOptions = ArrayList<CjguiChoiceOption>([
                CjguiChoiceOption("standard", 39, "标准", "standard", "SET_DETAIL_LAYOUT_STANDARD",
                    semanticId: "detail-layout-standard"),
                CjguiChoiceOption("compact", 36, "紧凑", "compact", "SET_DETAIL_LAYOUT_COMPACT",
                    semanticId: "detail-layout-compact")
            ])
            let viewSwitchRow = cjguiComposableWrap(206, "rule-list-view-row",
                CjguiComposableUiStyle(gap: 5), rowGap: 4)
            viewSwitchRow.add(CjguiChoiceGroup.build(38, "detail-layout-choice", 3810, detailOptions, detailLayout,
                3811, style: CjguiChoiceGroupStyle(container: CjguiComposableUiStyle(fixedWidth: 136),
                    button: presentationButtonStyle(64), interaction: theme.secondaryActionInteraction)))
            viewSwitchRow.add(localPresentationButton(200, "toggle-rule-view", if (collectionView.mode() == "list") {
                "表格视图"
            } else {
                "列表视图"
            }, "TOGGLE_RULE_VIEW", 84))
            viewSwitchRow.add(localPresentationButton(207, "toggle-card-view", if (collectionView.mode() == "grid") {
                "卡片视图 ✓"
            } else {
                "卡片视图"
            }, "TOGGLE_CARD_VIEW", 84))
            viewSwitchRow.add(localPresentationButton(60033, "toggle-column-editor",
                if (columnEditorVisible) { "隐藏列设置" } else { "列设置" }, "TOGGLE_COLUMN_EDITOR", 72))
            header.add(viewSwitchRow)
            header.add(collectionWorkspace.buildActionBar(1300,
                CjguiComposableUiStyle(gap: 4), sessionViewSnapshot,
                CjguiComposableUiStyle(fixedHeight: 28, padding: 5, background: theme.card.background,
                    textColor: bodyStyle.textColor, border: theme.card.border, borderWidth: 1,
                    cornerRadius: 6)))
            if (columnEditorVisible) {
                header.add(collectionWorkspace.buildColumnEditor(1330,
                    CjguiComposableUiStyle(gap: 3), CjguiComposableUiStyle(fixedHeight: 26)))
            }
        }
        root.add(header)
        // The document workflow is reachable without a CLI file argument: the
        // panel and the path row are ordinary scene content, and the business
        // file path stays a SEPARATE, clearly named fact.
        if (uiWorkspaceVisible) {
            // ONE named interface workspace; selecting the main/summary area is
            // an application decision, not two duplicated always-open panels.
            root.add(documentWorkspace.build(
                CjguiComposableUiStyle(gap: 5, padding: 8, border: theme.card.border,
                    borderWidth: 1, cornerRadius: theme.card.cornerRadius),
                headingStyle, bodyStyle, theme.primaryAction,
                interactionStyle: theme.primaryActionInteraction))
            root.add(documentWorkspace.buildPathRow(uiDocumentPathInput,
                CjguiComposableUiStyle(fixedHeight: 28, growX: 1, border: theme.card.border,
                    borderWidth: 1, cornerRadius: 5),
                theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        } else {
            // Business first: the rule list/detail is the default page. The
            // generated structure and interface-document controls live behind
            // the explicit "编辑界面" entry above.
            if (developerInfoVisible) {
                root.add(cjguiComposableText(61000, "rule-public-collection-title",
                    "规则集合 · 公共挂载（独立滚动）", bodyStyle))
                root.add(publicCollection.buildNode(61001, "rule-public-collection", 61002,
                    "rule-public-collection-content", "list",
                    CjguiComposableUiStyle(fixedHeight: 140, growX: 1),
                    identityScope: Some(CjguiComposableUiIdentityScope("rule-set-public-mount"))))
            }
        }
        // The generated region must be mounted even while its business page is
        // hidden: the startup seed is a generated candidate, and a candidate
        // cannot prepare when its region is absent from the accepted scene.
        // Empty accepted content contributes no paint, so the business-first
        // layout stays unchanged until a real structure is accepted.

        // The list pane is the SAME public variable-height list over the public
        // stable-key text filter. Every visible row still resolves its applied
        // record by business ID, and no off-screen record becomes a UI node.
        let emptyFiltered = collectionView.query().size > 0
        let emptySpec = CjguiContentStateSpec(CJGUI_CONTENT_EMPTY,
            emptyReason: if (emptyFiltered) { CJGUI_EMPTY_NO_MATCH } else { CJGUI_EMPTY_NO_DATA },
            detail: if (emptyFiltered) { "可清除筛选后重试" } else { "可用新增创建第一条规则" },
            actionLabel: if (emptyFiltered) { "清除筛选" } else { "新增规则" },
            actionName: if (emptyFiltered) { "CLEAR_RULE_FILTER" } else { "CREATE_RECORD" })
        let emptyText = CjguiContentFeedback.build(23, "empty-list", 2301, 2302, 2303, emptySpec,
            style: CjguiContentStateStyle(container: CjguiComposableUiStyle(minWidth: 160, idealWidth: 260,
                    maxWidth: 340, growX: 1, padding: 8, gap: 4),
                title: CjguiComposableUiStyle(fontSize: 12.0, textColor: bodyStyle.textColor,
                    fontFamily: bodyStyle.fontFamily),
                detail: CjguiComposableUiStyle(fontSize: 10.5, textColor: bodyStyle.textColor,
                    fontFamily: bodyStyle.fontFamily),
                action: CjguiComposableUiStyle(minWidth: 90, fixedHeight: theme.primaryAction.fixedHeight,
                    background: theme.primaryAction.background, border: theme.primaryAction.border,
                    textColor: theme.primaryAction.textColor, cornerRadius: 6),
                actionInteraction: theme.primaryActionInteraction))
        let listPane = if (visibleRuleCount == 0) {
            emptyText
        } else {
            cjguiComposableVariableHeightList(21, "rule-list-scroll", 22, filteredListSource, listState, 76, 5, 3,
                CjguiComposableUiStyle(minWidth: 160, idealWidth: 260, maxWidth: 340, growX: 1,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, background: theme.card.background,
                    border: theme.card.border))
        }
        // The card pane is a THIRD presentation over the same filtered/sorted
        // source. The grid source groups visible items into responsive rows and
        // the normal variable-height list only materializes the visible range.
        let cardPane = if (collectionView.mode() == "grid") {
            let pane = cjguiComposableVertical(20, "rule-card-pane",
                CjguiComposableUiStyle(minWidth: 160, growX: 1, growY: 1, gap: 0,
                    background: theme.card.background, border: theme.card.border))
            let bar = cjguiComposableHorizontal(220, "rule-card-bar",
                CjguiComposableUiStyle(fixedHeight: 28, gap: 6,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
            bar.add(cjguiComposableText(221, "rule-card-hint",
                "卡片视图 · ${cardGridSource.columns()} 列 · ${cardGridSource.cardWidth()} pt",
                CjguiComposableUiStyle(growX: 1, fontSize: 10.5, textColor: theme.card.textColor,
                    fontFamily: bodyStyle.fontFamily, textMaxLines: 1, textOverflow: "ellipsis")))
            pane.add(bar)
            if (visibleRuleCount == 0) {
                pane.add(emptyText)
            } else {
                pane.add(cjguiComposableVariableHeightList(21, "rule-card-scroll", 22,
                    cardGridSource, cardListState, cardGridSource.spec().cardHeight,
                    cardGridSource.spec().rowGap, 2,
                    CjguiComposableUiStyle(minWidth: 160, growX: 1, growY: 1,
                        alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
                        background: theme.card.background)))
            }
            pane
        } else {
            emptyText
        }
        // The table pane reuses the same public list/viewport for its body and
        // only adds a header plus one rule. A flexible name column and fixed
        // status columns come from the SAME declarations the header uses.
        let tablePane = if (collectionView.mode() == "table") {
            let pane = cjguiComposableVertical(20, "rule-table-pane",
                CjguiComposableUiStyle(idealWidth: 560, growX: 1, growY: 1,
                    gap: 0, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
                    background: theme.card.background, border: theme.card.border))
            let columnBar = cjguiComposableHorizontal(202, "rule-table-column-bar",
                CjguiComposableUiStyle(fixedHeight: 28, gap: 6,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
            columnBar.add(cjguiComposableText(203, "rule-table-column-hint",
                if (tableSource.minimumContentWidth() > tablePaneWidth(workspaceWidth)) {
                    "列宽超出当前空间；列设置可缩窄或恢复默认"
                } else { "拖动表头竖条调宽；菜单可显隐、换序" }, CjguiComposableUiStyle(growX: 1, fontSize: 10.5,
                    textColor: theme.card.textColor, fontFamily: bodyStyle.fontFamily,
                    textMaxLines: 1, textOverflow: "ellipsis")))
            columnBar.add(cjguiComposableButton(204, "open-column-menu", "列设置", "OPEN_COLUMN_MENU", -1,
                presentationButtonStyle(84), operationActionName: "OPEN_COLUMN_MENU",
                operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
            pane.add(columnBar)
            pane.add(tableSource.buildHeader())
            pane.add(cjguiComposableHorizontal(201, "rule-table-header-rule",
                CjguiComposableUiStyle(fixedHeight: 1, growX: 1, background: theme.card.border)))
            if (visibleRuleCount == 0) {
                pane.add(emptyText)
            } else {
                pane.add(cjguiComposableVariableHeightList(21, "rule-table-scroll", 22, tableSource, listState, 30,
                    1, 3,
                    CjguiComposableUiStyle(growX: 1, growY: 1,
                        alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, background: theme.card.background)))
            }
            pane
        } else if (collectionView.mode() == "grid") {
            cardPane
        } else {
            listPane
        }
        // The batch controls follow the collection they act on, not the page
        // header: selection count, select-all and batch enable/disable describe
        // the object area and stay reachable beside its list/table/grid.
        // Selection over the public selection keeps hidden-by-filter keys.
        let batchRow = cjguiComposableWrap(210, "rule-batch-row",
            CjguiComposableUiStyle(gap: 6), rowGap: 4)
        let selectionLabel = if (hiddenSelectionCount > 0) {
            "已选 ${selectionCount} 项，其中隐藏 ${hiddenSelectionCount} 项"
        } else {
            "已选 ${selectionCount} 项"
        }
        batchRow.add(cjguiComposableText(211, "rule-batch-count", selectionLabel,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 30, fontSize: 11.0,
                textColor: bodyStyle.textColor, fontFamily: bodyStyle.fontFamily,
                textMaxLines: 1, textOverflow: "ellipsis")))
        // The copy command stays MOUNTED with the selection it copies: it is
        // also the data-transfer drag/paste source whose semantic id the
        // transfer declaration binds to, so it cannot live only in a menu
        // layer that is closed at startup.
        batchRow.add(command(11, "copy", "复制所选", "COPY_RECORD"))
        batchRow.add(cjguiComposableButton(212, "rule-batch-select-all", "全选筛选结果",
            "COLLECTION_SELECT_ALL", -1, secondaryActionPresentationStyle(theme, 110),
            interactionStyle: theme.secondaryActionInteraction, enabled: visibleRuleCount > 0))
        batchRow.add(cjguiComposableButton(213, "rule-batch-enable", "批量启用",
            "COLLECTION_BATCH_ENABLE", -1, secondaryActionPresentationStyle(theme, 76),
            interactionStyle: theme.secondaryActionInteraction, enabled: selectionCount > 0))
        batchRow.add(cjguiComposableButton(214, "rule-batch-disable", "批量停用",
            "COLLECTION_BATCH_DISABLE", -1, secondaryActionPresentationStyle(theme, 76),
            interactionStyle: theme.secondaryActionInteraction, enabled: selectionCount > 0))
        batchRow.add(cjguiComposableButton(215, "rule-batch-clear", "清除选择",
            "COLLECTION_CLEAR", -1, secondaryActionPresentationStyle(theme, 76),
            interactionStyle: theme.secondaryActionInteraction, enabled: selectionCount > 0))
        let collectionPane = cjguiComposableVertical(208, "rule-collection-pane",
            CjguiComposableUiStyle(growX: 1, gap: 4))
        // The object area's ONE primary action: create sits with the list it
        // grows, exactly where the collection's own search already lives.
        collectionPane.add(command(10, "create", "新增规则", "CREATE_RECORD",
            role: CjguiRuleSetCommandRole.PRIMARY))
        collectionPane.add(batchRow)
        collectionPane.add(tablePane)

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
        // The detail header carries the SAME public searchable-record panel
        // (keyboard selection + layer-close focus restore) and the second
        // field/layout combination. Both are window view state: neither
        // writes, applies nor discards the owner's draft.
        // The search and layout switches live in the shallow header row; the
        // detail declares its title and status directly so the tab/field
        // subtree keeps its existing layout depth.
        detail.add(cjguiComposableText(31, "detail-title", if (renderedSelectedId >= 0) {
            "当前规则草稿"
        } else {
            "请选择或新增一条规则"
        }, headingStyle))
        let detailStatusStyle = CjguiStatusMessageStyle(
            chip: CjguiComposableUiStyle(fixedWidth: 52, fixedHeight: 20, fontSize: 10.5,
                textColor: bodyStyle.textColor, fontFamily: bodyStyle.fontFamily),
            text: CjguiComposableUiStyle(fontSize: 11.0, textColor: bodyStyle.textColor,
                fontFamily: bodyStyle.fontFamily),
            container: CjguiComposableUiStyle(gap: 4, padding: 0))
        let detailStatusText = viewStatusText(form.statusMessage)
        detail.add(CjguiStatusFeedback.buildMessage(33, "detail-status", 3301, 3302, -1,
            CjguiStatusMessageSpec(statusKindFor(detailStatusText), detailStatusText),
            style: detailStatusStyle))
        let detailVisual = cjguiComposableHorizontal(3400, "detail-visual-row",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        let detailTags = cjguiComposableWrap(3401, "detail-tags",
            CjguiComposableUiStyle(growX: 1, gap: 6), rowGap: 4)
        let tagStyle = CjguiComposableUiStyle(fixedHeight: 20, padding: 4, fontSize: 10.5,
            textColor: theme.card.textColor, fontFamily: bodyStyle.fontFamily,
            background: theme.card.background, border: theme.card.border, borderWidth: 1, cornerRadius: 4)
        detailTags.add(cjguiComposableText(3402, "detail-tag-applied",
            "已应用 v${form.appliedConfigVersion}", tagStyle))
        detailTags.add(cjguiComposableText(3403, "detail-tag-draft", "草稿 v${form.draftVersion}", tagStyle))
        detailTags.add(cjguiComposableText(3404, "detail-tag-view", "视图 ${collectionView.mode()}", tagStyle))
        detailTags.add(cjguiComposableText(3405, "detail-tag-selection",
            if (hiddenSelectionCount > 0) {
                "已选 ${selectionCount} · 隐藏 ${hiddenSelectionCount}"
            } else {
                "已选 ${selectionCount}"
            }, tagStyle))
        detailVisual.add(detailTags)
        if (developerInfoVisible) {
        let beaconCard = cjguiComposableStack(3410, "detail-beacon-card",
            CjguiComposableUiStyle(fixedWidth: 128, fixedHeight: 96, clipsContent: true))
        let beaconFrame = cjguiComposableAspectRatio(3411, "detail-beacon-frame", 4, 3,
            CjguiComposableUiStyle(fixedWidth: 128, fixedHeight: 96))
        beaconFrame.add(cjguiComposableImage(3412, "detail-beacon-image", beacon.rasterPath,
            CjguiComposableUiStyle(fixedWidth: 128, fixedHeight: 96),
            imageResourceId: beacon.key, imageResourceVersion: beacon.version))
        beaconCard.add(beaconFrame)
        beaconCard.add(cjguiComposableButton(3413, "detail-beacon-edit",
            if (renderedSelectedId >= 0) { "编辑" } else { "未选" }, "OPEN_EDIT_DIALOG", -1,
            CjguiComposableUiStyle(fixedWidth: 44, fixedHeight: 22, fontSize: 10.0,
                background: theme.primaryAction.background, textColor: theme.primaryAction.textColor,
                border: theme.primaryAction.border, borderWidth: 1, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_START, zIndex: 2),
            enabled: renderedSelectedId >= 0, operationActionName: "OPEN_EDIT_DIALOG"))
        detailVisual.add(beaconCard)
        }
        detail.add(detailVisual)
        // The detail pane is a real multi-page workspace through the PUBLIC tab
        // container: "基本" holds the draft fields, "保留策略" holds the file and
        // retention work. Both pages share the app's existing identities, and
        // which page is active is window view state.
        let basicPage = cjguiComposableVertical(60, "rule-detail-basic",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        let retentionPage = cjguiComposableVertical(61, "rule-detail-retention",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        let publicDetailPage = cjguiComposableVertical(65, "rule-detail-public",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        if (renderedSelectedId >= 0) {
            // The SAME owner through the CONVERGED public seam as its own normal
            // page: one call composes BoundFormField/FormFeedback over this app's
            // binding, so the rule business carries no second field layout.
            publicDetailPage.add(cjguiSharedEditableDetailFields(
                publicDetailStatusNodeId(renderedSelectedId) - 50, publicDetailEditorNodeId(renderedSelectedId),
                publicDetailStatusNodeId(renderedSelectedId), "public-detail", renderedSelectedId,
                binding, form, { fieldId =>
                    let availability = generatedRegion.fieldAvailability(fieldId)
                    CjguiSharedDetailFieldState(availability.known && availability.isAvailable,
                        unavailableReason: availability.reason)
                }, "", theme))
            let publicActions = cjguiComposableHorizontal(66, "public-detail-actions",
                CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
            // The public page's own Apply/Cancel: same owner actions, wide enough
            // for the full label (the compact 64pt command button ellipsized it).
            publicActions.add(localPresentationButton(detailActionNodeId(renderedSelectedId, 2),
                "public-detail-apply", "应用草稿", "APPLY", 96, operationResourceId: renderedSelectedId))
            publicActions.add(localPresentationButton(detailActionNodeId(renderedSelectedId, 3),
                "public-detail-cancel", "取消草稿", "CANCEL", 96, operationResourceId: renderedSelectedId))
            publicDetailPage.add(publicActions)
        } else {
            publicDetailPage.add(cjguiComposableText(3910, "public-detail-empty",
                "未选择规则。请从左侧列表选择，或点击“新增”。", bodyStyle))
        }
        if (renderedSelectedId >= 0) {
            // The modal dialog is painted above these fields. Keeping the
            // ordinary detail field declared under it gives the layer's public
            // return reference a LIVE target (a removed node cannot be an
            // anchor) and avoids a second focus restoration protocol.
            basicPage.add(buildDetailFields(form, binding, renderedSelectedId, inputStyle, validationStyle))
        } else {
            basicPage.add(
                cjguiComposableText(37, "detail-empty-selection",
                    "未选择规则。请从左侧列表选择，或点击“新增”。", bodyStyle))
        }
        retentionPage.add(
            cjguiComposableTextInput(390, "file-path", "文件路径", filePath, -1, inputStyle,
                displayValueRole: "draft", interactionStyle: theme.inputInteraction))
        let fileActions = cjguiComposableHorizontal(40, "file-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
        fileActions.add(command(403, "save-as", "另存为", "SAVE_AS"));
        fileActions.add(command(404, "open", "打开", "OPEN"));
        fileActions.add(command(405, "close", "关闭", "CLOSE"));
        retentionPage.add(fileActions)
        let retentionStatusText = viewStatusText(collection.statusMessage)
        retentionPage.add(CjguiStatusFeedback.buildMessage(50, "status", 5001, 5002, -1,
            CjguiStatusMessageSpec(statusKindFor(retentionStatusText), retentionStatusText),
            style: detailStatusStyle))
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
        detail.add(ruleDetailTabWorkspaceWithPublicDetail(detailTabs, basicPage, publicDetailPage,
            retentionPage))
        let splitScope = CjguiComposableUiIdentityScope("rule-set-content")
        let narrowWindow = workspaceWidth > 0 && workspaceWidth < 700
        if (narrowWindow || tableWorkspaceStacks(workspaceWidth)) {
            // Keep the original table, detail, field and selection identities.
            // Only their composition changes; no owner/view preference writes.
            // In a real narrow window the editor comes FIRST and the object list
            // follows below; wide windows keep list|detail side by side.
            let stacked = cjguiComposableVertical(-1, "rule-set-content-stacked",
                CjguiComposableUiStyle(growX: 1, gap: 12), identity: Some(splitScope.local("stacked")))
            if (narrowWindow) {
                stacked.add(detail); stacked.add(collectionPane)
            } else {
                stacked.add(collectionPane); stacked.add(detail)
            }
            root.add(stacked)
        } else {
            root.add(cjguiComposableScopedSplitView(splitScope, "rule-set-content", collectionPane, detail,
                CjguiComposableUiSplitAxis.HORIZONTAL,
                if (collectionView.mode() == "table") { tablePaneWidth(workspaceWidth) } else { domain.splitFirstSize() },
                tablePaneMinimumWidth(), 260,
                CjguiComposableUiStyle(growX: 1, growY: 1), operationActionName: "SET_SPLIT_SIZE",
                operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
        }
        // The tree section sits directly under the header so its virtual rows
        // materialize inside the visible viewport (a human can reach them);
        // the generated region follows below.
        root.add(treePanel.buildSection(theme, bodyStyle))
            // Mounted in every mode so the startup generated candidate can
            // prepare; the workspace toggle reveals the document panel above,
            // while this section keeps its REAL height in the page's ONE
            // public scroll. The two cards are taller than the old fixed 300pt
            // clip, which laid the oversized child's head ABOVE the band where
            // no wheel could reach it (followup-20261027 geometry originals),
            // and a nested scroll inside the page scroll is not a supported
            // common entry (the generated validator pre-rejects nested
            // scrolls). Natural height plus the page scroll keep every field
            // and action of both cards reachable by wheel and focus reveal, in
            // a narrow window too.
            let generatedHost = cjguiComposableVertical(62001, "rule-generated-host",
                CjguiComposableUiStyle(growX: 1, clipsContent: true))
            generatedHost.add(generatedRegion.buildSection(theme, bodyStyle))
        root.add(generatedHost)
        scroll.add(root)
        host.add(scroll)
        if (layerMode == "menu") {
            // The named "更多" entry: the low-frequency commands keep their
            // ORIGINAL node ids and semantic ids from the old header row, so
            // the command table, keyboard bindings and external discovery keep
            // addressing the same controls. Presentation toggles stay here too.
            let menu = cjguiComposableAnchoredLayer(500, "rule-set-menu", "rule-set-menu", "menu", "open-rule-set-menu",
                18,
                CjguiComposableUiStyle(fixedWidth: 168, fixedHeight: 380, background: theme.card.background,
                    border: theme.card.border, padding: 6, gap: 4))
            menu.add(command(12, "delete", "删除所选", "DELETE_RECORD"))
            menu.add(command(13, "undo", "撤销", "UNDO"))
            menu.add(command(14, "redo", "重做", "REDO"))
            menu.add(command(16, "new", "清空新建", "NEW"))
            menu.add(command(17, "discard", "放弃修改", "DISCARD"))
            menu.add(localPresentationButton(29, "open-rule-set-editor", "编辑草稿", "OPEN_EDIT_DIALOG", 156))
            menu.add(localPresentationButton(501, "menu-toggle-presentation", "外观/字体", "TOGGLE_PRESENTATION", 156))
            // The application-menu command follows focus into this layer. Give
            // its visible action a distinct stable identity, rather than
            // allowing the command to point through the active layer at the
            // header action behind it.
            menu.add(scopedLocalPresentationButton(502, "menu-toggle-beacon", "切换图标", "TOGGLE_BEACON", 156,
                presentationScope.local("menu-toggle-beacon")))
            menu.add(localPresentationButton(503, "menu-close", "关闭菜单", "CLOSE_LAYER", 156))
            host.add(menu)
        }
        if (layerMode == "columns") {
            let columnKeys = tableLayout.columnKeys()
            let menuHeight = columnKeys.size * 32 + 44
            let menu = cjguiComposableAnchoredLayer(560, "rule-columns-menu", "rule-columns-menu", "menu",
                "open-column-menu", 204,
                CjguiComposableUiStyle(fixedWidth: 470, fixedHeight: menuHeight,
                    background: theme.card.background, border: theme.card.border, padding: 6, gap: 4))
            var menuIndex: Int64 = 0
            for (key in columnKeys) {
                let visible = tableLayout.isVisible(key)
                let width = tableLayout.width(key)
                let widthLabel = if (width > 0) { "${width}" } else { "弹性" }
                let row = cjguiComposableHorizontal(560100 + menuIndex, "column-row-${key}",
                    CjguiComposableUiStyle(fixedHeight: 30, gap: 4,
                        alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
                row.add(cjguiComposableButton(570000 + menuIndex * 10, "column-toggle-${key}",
                    "${tableSource.columnTitle(key)} ${if (visible) { "✓" } else { "○" }}  ${widthLabel}",
                    "TABLE_COLUMN_TOGGLE", -1, CjguiComposableUiStyle(growX: 1, fixedHeight: 28,
                        fontSize: 11.0, textColor: bodyStyle.textColor,
                        fontFamily: bodyStyle.fontFamily, textMaxLines: 1, textOverflow: "ellipsis"),
                    operationActionName: "TABLE_COLUMN_TOGGLE",
                    operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
                row.add(cjguiComposableButton(570001 + menuIndex * 10, "column-left-${key}", "←", "TABLE_COLUMN_MOVE_LEFT", -1,
                    presentationButtonStyle(30), operationActionName: "TABLE_COLUMN_MOVE_LEFT",
                    operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
                row.add(cjguiComposableButton(570002 + menuIndex * 10, "column-right-${key}", "→", "TABLE_COLUMN_MOVE_RIGHT", -1,
                    presentationButtonStyle(30), operationActionName: "TABLE_COLUMN_MOVE_RIGHT",
                    operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
                row.add(cjguiComposableButton(570003 + menuIndex * 10, "column-narrower-${key}", "−", "TABLE_COLUMN_NARROWER", -1,
                    presentationButtonStyle(30), enabled: width > 0,
                    operationActionName: "TABLE_COLUMN_NARROWER",
                    operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
                row.add(cjguiComposableButton(570004 + menuIndex * 10, "column-wider-${key}", "+", "TABLE_COLUMN_WIDER", -1,
                    presentationButtonStyle(30), enabled: width > 0,
                    operationActionName: "TABLE_COLUMN_WIDER",
                    operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
                menu.add(row)
                menuIndex += 1
            }
            let menuActions = cjguiComposableHorizontal(560199, "column-menu-actions",
                CjguiComposableUiStyle(fixedHeight: 30, gap: 6,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
            menuActions.add(cjguiComposableButton(570900, "column-menu-reset", "恢复默认列布局",
                "TABLE_COLUMN_RESET", -1, presentationButtonStyle(150),
                operationActionName: "TABLE_COLUMN_RESET",
                operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
            menuActions.add(localPresentationButton(560198, "column-menu-close", "关闭菜单", "CLOSE_LAYER", 100))
            menu.add(menuActions)
            host.add(menu)
        }
        if (layerMode == "views") {
            let presetNames = viewPreferences.names()
            let activeName = viewPreferences.activeName()
            let menuHeight = 244 + (if (presetNames.size > 0) { presetNames.size } else { 1 }) * 30
            let menu = cjguiComposableAnchoredLayer(590, "rule-view-menu", "rule-view-menu", "menu",
                "open-view-menu", 205,
                CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: menuHeight,
                    background: theme.card.background, border: theme.card.border, padding: 6, gap: 4))
            menu.add(cjguiComposableText(590001, "view-menu-title",
                if (activeName.size > 0) { "视图预设 · 当前：${activeName}" } else { "视图预设 · 当前：默认" },
                CjguiComposableUiStyle(fixedHeight: 22, fontSize: 12.0, textColor: bodyStyle.textColor,
                    fontFamily: bodyStyle.fontFamily, textMaxLines: 1, textOverflow: "ellipsis")))
            menu.add(cjguiComposableTextInput(591, "view-preset-name", "视图名称", viewDraftName, -1,
                CjguiComposableUiStyle(fixedHeight: 30, fontSize: inputStyle.fontSize,
                    textColor: inputStyle.textColor, background: inputStyle.background,
                    border: inputStyle.border, borderWidth: inputStyle.borderWidth,
                    fontFamily: inputStyle.fontFamily),
                displayValueRole: "draft", interactionStyle: theme.inputInteraction))
            menu.add(localPresentationButton(592, "view-save", "保存当前视图", "SAVE_COLLECTION_VIEW", 380))
            var presetIndex: Int64 = 0
            for (name in presetNames) {
                let marker = if (name == activeName) { "● " } else { "○ " }
                menu.add(cjguiComposableButton(590100 + presetIndex * 10, "view-preset-${presetIndex}",
                    "${marker}${name}", "SELECT_COLLECTION_VIEW", -1,
                    presentationButtonStyle(380),
                    operationActionName: "SELECT_COLLECTION_VIEW",
                    operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
                presetIndex += 1
            }
            if (presetNames.size == 0) {
                menu.add(cjguiComposableText(590002, "view-menu-empty", "尚未保存视图",
                    CjguiComposableUiStyle(fixedHeight: 30, fontSize: 11.0,
                        textColor: bodyStyle.textColor, fontFamily: bodyStyle.fontFamily)))
            }
            menu.add(localPresentationButton(593, "view-reset", "恢复默认视图", "RESET_COLLECTION_VIEW", 380))
            menu.add(cjguiComposableButton(594, "view-save-preferences", "保存偏好",
                "SAVE_COLLECTION_VIEW_PREFERENCES", -1, presentationButtonStyle(380),
                enabled: viewPreferences.filePath().size > 0,
                operationActionName: "SAVE_COLLECTION_VIEW_PREFERENCES",
                operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId))
            menu.add(localPresentationButton(595, "view-menu-close", "关闭菜单", "CLOSE_LAYER", 380))
            menu.add(cjguiComposableText(596, "view-menu-status",
                if (viewPreferences.filePath().size == 0) {
                    "偏好文件未设置；用 --open 文档或 --view-preferences 启动"
                } else if (viewPreferences.isDirty()) {
                    "偏好：有未保存修改 · ${viewPreferences.filePath()}"
                } else {
                    "偏好：已保存 · ${viewPreferences.filePath()}"
                },
                CjguiComposableUiStyle(fixedHeight: 20, fontSize: 10.5,
                    textColor: bodyStyle.textColor, fontFamily: bodyStyle.fontFamily,
                    textMaxLines: 1, textOverflow: "ellipsis")))
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
        // Initial values, validation and later reads come from the draft of the
        // record THIS layer edits. The selected record's snapshot is a different
        // owner whenever the person opened a card other than the selected one.
        let recordEditForm: ?CjguiSharedFormSnapshot =
            if (layerMode == "record-edit" && activeRecordId >= 0) {
                domain.formSnapshotForRecord(activeRecordId)
            } else {
                None
            }
        if (let Some(recordForm) <- recordEditForm) {
            let cardScope = recordCardScope.child("rule_${activeRecordId}")
            let editorScope = cardScope.child("editor")
            let dialog = cjguiComposableDialogLayerWithReference(540, "rule-card-edit-dialog-${activeRecordId}",
                "rule-card-edit-dialog-${activeRecordId}", "rule-row-${activeRecordId}",
                CjguiComposableUiNodeReference.scoped(cardScope.child("actions").child("item"), "edit"),
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 360, background: theme.card.background,
                    border: theme.card.border, padding: 14, gap: 8),
                initialFocus: Some(CjguiComposableUiNodeReference.scoped(editorScope, "editor-name")))
            dialog.add(cjguiComposableText(541, "rule-card-edit-title", "编辑规则草稿", headingStyle))
            let labelField = recordForm.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId)
            dialog.add(
                CjguiComposableUiNode(dialogFieldNodeId(activeRecordId, 0), "rule-card-editor-name-${activeRecordId}",
                    CJGUI_COMPOSABLE_UI_TEXT_INPUT, "规则名称", labelField.draftText, "EDIT_TEXT",
                    CjguiRuleSetEditingDomain.formLabelResourceId, inputStyle, fieldId: "label",
                    operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: activeRecordId,
                    displayValueRole: "draft", identity: Some(editorScope.local("editor-name"))))
            var dialogFieldIndex: Int64 = 1
            while (dialogFieldIndex < binding.fieldCount()) {
                let descriptor = binding.fieldAtControlIndex(dialogFieldIndex)
                let field = recordForm.fieldForResourceId(descriptor.resourceId)
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
            // The owner travels WITH the command, so routing and the public
            // TARGETS relation do not depend on an encoded action node id.
            dialogActions.add(command(dialogActionNodeId(activeRecordId, 0), "rule-card-dialog-apply", "应用草稿",
                "APPLY", operationResourceId: activeRecordId))
            dialogActions.add(
                command(dialogActionNodeId(activeRecordId, 1), "rule-card-dialog-cancel", "取消草稿", "CANCEL",
                    operationResourceId: activeRecordId))
            dialog.add(dialogActions)
            host.add(dialog)
        }
        if ((layerMode == "edit" || layerMode == "edit-menu") && renderedSelectedId >= 0) {
            // Feed the captured public reference to the existing dialog layer
            // declaration. The window restores this anchor (and the text
            // bookmark when it is a field) after the modal closes.
            let returnTarget = if (editDialogReturnRecordId == renderedSelectedId) {
                match (editDialogReturnTarget) {
                    case Some(value) => value
                    case None => CjguiComposableUiNodeReference.manual(30)
                }
            } else {
                CjguiComposableUiNodeReference.manual(30)
            }
            let dialog = cjguiComposableDialogLayerWithReference(510, "rule-set-edit-dialog",
                "rule-set-edit-dialog", "rule-detail", returnTarget,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 360, background: theme.card.background,
                    border: theme.card.border, padding: 14, gap: 8),
                initialFocus: Some(CjguiComposableUiNodeReference.manual(dialogFieldNodeId(renderedSelectedId, 0))))
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
                    let preset = generatedRegion.retentionPreset()
                    let stepBinding = CjguiNumericStepperBinding(
                        dialogFieldGroupNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}",
                        dialogStepperRowNodeId(renderedSelectedId, dialogFieldIndex),
                        dialogStepperPresetsNodeId(renderedSelectedId, dialogFieldIndex),
                        dialogFieldNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}-editor",
                        dialogStepDownNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}-step-down",
                        dialogStepUpNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}-step-up",
                        descriptor.label, field.draftText, descriptor.minimum, descriptor.maximum, 1,
                        descriptor.fieldId, "EDIT_DRAFT_TEXT", descriptor.resourceId, renderedSelectedId,
                        CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION,
                        CjguiRetentionIntegerEditComposite.STEP_UP_ACTION,
                        enabled: renderedSelectedId >= 0, readOnly: false,
                        feedback: field.validationError)
                    let stepPreset = CjguiNumericStepperPreset("primary",
                        dialogPresetNodeId(renderedSelectedId, dialogFieldIndex), preset.label, preset.value,
                        actionName: CjguiRetentionIntegerEditComposite.PRESET_ACTION,
                        writerOperation: "EDIT_DRAFT_TEXT", bindingResourceId: descriptor.resourceId,
                        ownerTargetResourceId: renderedSelectedId)
                    let compositeRow = CjguiRetentionIntegerEditComposite.buildEditor(stepBinding,
                        ArrayList<CjguiNumericStepperPreset>([stepPreset]),
                        CjguiNumericStepperStyle(input: inputStyle,
                            button: CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 26),
                            preset: inputStyle))
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
            dialogActions.add(command(dialogActionNodeId(renderedSelectedId, 0), "dialog-apply", "应用草稿", "APPLY",
                operationResourceId: renderedSelectedId))
            dialogActions.add(command(dialogActionNodeId(renderedSelectedId, 1), "dialog-cancel", "取消草稿", "CANCEL",
                operationResourceId: renderedSelectedId))
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
        var result = recordSearchPanel.attachTo(host, theme)
        result = enabledSelect.attachTo(result)
        return enabledTooltip.attachTo(result)
    }

    /// The visible close protection over the document workspace. The three
    /// actions are ordinary application buttons; the framework never closes
    /// the window or writes business data here.
    private func buildUiCloseGuardPanel(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let panel = cjguiComposableVertical(2830, "rule-ui-close-guard",
            CjguiComposableUiStyle(gap: 6, padding: 10, border: theme.card.border,
                borderWidth: 1, cornerRadius: theme.card.cornerRadius, fixedWidth: 420))
        panel.add(cjguiComposableText(2831, "rule-ui-close-guard-title",
            "关闭前的界面文档检查", presentationTextStyle(theme.heading)))
        panel.add(cjguiComposableText(2832, "rule-ui-close-guard-reason",
            "${uiCloseGuardNotice}\n保存界面不会应用业务草稿；放弃界面变更也不会改动业务内容。",
            CjguiComposableUiStyle(fontSize: 12.0, lineHeight: 17.0)))
        let bar = cjguiComposableWrap(2833, "rule-ui-close-guard-actions",
            CjguiComposableUiStyle(gap: 6), rowGap: 4)
        bar.add(cjguiComposableButton(2834, "rule-ui-close-guard-save",
            "保存界面并关闭", "RULE_UI_CLOSE_SAVE_ALL", -1, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        bar.add(cjguiComposableButton(2835, "rule-ui-close-guard-discard",
            "放弃界面变更并关闭", "RULE_UI_CLOSE_DISCARD", -1, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        bar.add(cjguiComposableButton(2836, "rule-ui-close-guard-cancel",
            "取消关闭", "RULE_UI_CLOSE_CANCEL", -1, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        panel.add(bar)
        return panel
    }

    /// Two REAL field/layout combinations over the SAME owner form. The
    /// switch only changes this consumer's declaration; it never calls the
    /// domain's apply/cancel and therefore cannot submit or discard a draft.
    private func buildDetailFields(form: CjguiSharedFormSnapshot, binding: CjguiSharedFormBinding,
        recordId: Int64, inputStyle: CjguiComposableUiStyle,
        validationStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        return if (detailLayout == "compact") {
            buildCompactDetailFields(form, binding, recordId, inputStyle, validationStyle)
        } else {
            buildStandardDetailFields(form, binding, recordId, inputStyle, validationStyle)
        }
    }

    /// Combination A: every declared field in declaration order, one per row.
    private func buildStandardDetailFields(form: CjguiSharedFormSnapshot, binding: CjguiSharedFormBinding,
        recordId: Int64, inputStyle: CjguiComposableUiStyle,
        validationStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let column = cjguiComposableVertical(62, "rule-detail-standard",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        var fieldIndex: Int64 = 0
        while (fieldIndex < binding.fieldCount()) {
            let descriptor = binding.fieldAtControlIndex(fieldIndex)
            let field = form.fieldForResourceId(descriptor.resourceId)
            if (descriptor.fieldId == "enabled") {
                column.add(enabledSelectEditor(field.draftText, recordId,
                    detailFieldNodeId(recordId, fieldIndex)))
                fieldIndex += 1
                continue
            }
            if (descriptor.fieldId == "retentionCount") {
                // The standard layout also consumes the ONE public numeric
                // stepper; its preset comes from the same composite config.
                let preset = generatedRegion.retentionPreset()
                let stepBinding = CjguiNumericStepperBinding(
                    detailFieldGroupNodeId(recordId, fieldIndex), "field-group-${descriptor.fieldId}",
                    detailStepperRowNodeId(recordId, fieldIndex), detailStepperPresetsNodeId(recordId, fieldIndex),
                    detailFieldNodeId(recordId, fieldIndex), "field-${descriptor.fieldId}",
                    detailStepDownNodeId(recordId, fieldIndex), "field-${descriptor.fieldId}-step-down",
                    detailStepUpNodeId(recordId, fieldIndex), "field-${descriptor.fieldId}-step-up",
                    descriptor.label, field.draftText, descriptor.minimum, descriptor.maximum, 1,
                    descriptor.fieldId, "EDIT_DRAFT_TEXT", descriptor.resourceId, recordId,
                    CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION,
                    CjguiRetentionIntegerEditComposite.STEP_UP_ACTION,
                    feedbackNodeId: detailValidationNodeId(recordId, fieldIndex),
                    enabled: recordId >= 0, readOnly: false, feedback: field.validationError)
                let stepPreset = CjguiNumericStepperPreset("primary",
                    detailPresetNodeId(recordId, fieldIndex), preset.label, preset.value,
                    actionName: CjguiRetentionIntegerEditComposite.PRESET_ACTION,
                    writerOperation: "EDIT_DRAFT_TEXT", bindingResourceId: descriptor.resourceId,
                    ownerTargetResourceId: recordId)
                column.add(CjguiRetentionIntegerEditComposite.buildEditor(stepBinding,
                    ArrayList<CjguiNumericStepperPreset>([stepPreset]),
                    CjguiNumericStepperStyle(input: inputStyle,
                        button: CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 30),
                        preset: inputStyle)))
                fieldIndex += 1
                continue
            }
            column.add(
                cjguiComposableBoundFormField(detailFieldGroupNodeId(recordId, fieldIndex),
                    "field-group-${descriptor.fieldId}", detailFieldNodeId(recordId, fieldIndex),
                    detailValidationNodeId(recordId, fieldIndex), descriptor, field, recordId, inputStyle,
                    validationStyle, editorSemanticId: "field-${descriptor.fieldId}",
                    validationSemanticId: "error-${descriptor.fieldId}", textOperationActionName: "EDIT_DRAFT_TEXT",
                    booleanOperationActionName: "EDIT_DRAFT_BOOLEAN"))
            fieldIndex += 1
        }
        column.add(detailApplyRow(41, recordId))
        return column
    }

    /// Combination B: name+enabled bind side by side, retention uses the
    /// declared composite (integer input + preset), and excluded type keeps
    /// the remaining full row. Values, validation and actions still come from
    /// the same binding and the same owner entries.
    private func buildCompactDetailFields(form: CjguiSharedFormSnapshot, binding: CjguiSharedFormBinding,
        recordId: Int64, inputStyle: CjguiComposableUiStyle,
        validationStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let column = cjguiComposableVertical(63, "rule-detail-compact",
            CjguiComposableUiStyle(gap: 7, growX: 1))
        let identityRow = cjguiComposableHorizontal(64, "rule-detail-compact-identity",
            CjguiComposableUiStyle(gap: 8, growX: 1))
        identityRow.add(compactBoundField(form, binding, recordId,
            binding.controlIndexForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId), inputStyle,
            validationStyle))
        identityRow.add(compactBoundField(form, binding, recordId,
            binding.controlIndexForResourceId(CjguiRuleSetEditingDomain.formEnabledResourceId), inputStyle,
            validationStyle))
        column.add(identityRow)
        let retentionIndex = binding.controlIndexForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId)
        let retentionDescriptor = binding.fieldAtControlIndex(retentionIndex)
        let retention = form.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId)
        let preset = generatedRegion.retentionPreset()
        let compactInputStyle = CjguiComposableUiStyle(fixedHeight: 30, growX: 1,
            fontSize: inputStyle.fontSize, textColor: inputStyle.textColor,
            background: inputStyle.background, border: inputStyle.border,
            borderWidth: inputStyle.borderWidth, fontFamily: inputStyle.fontFamily)
        let stepBinding = CjguiNumericStepperBinding(
            detailFieldGroupNodeId(recordId, retentionIndex), "compact-field-group-retentionCount",
            detailStepperRowNodeId(recordId, retentionIndex),
            detailStepperPresetsNodeId(recordId, retentionIndex),
            detailFieldNodeId(recordId, retentionIndex),
            "compact-field-group-retentionCount-editor",
            detailStepDownNodeId(recordId, retentionIndex), "compact-field-group-retentionCount-step-down",
            detailStepUpNodeId(recordId, retentionIndex), "compact-field-group-retentionCount-step-up",
            retentionDescriptor.label, retention.draftText, retentionDescriptor.minimum,
            retentionDescriptor.maximum, 1, retentionDescriptor.fieldId, "EDIT_DRAFT_TEXT",
            retentionDescriptor.resourceId, recordId,
            CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION,
            CjguiRetentionIntegerEditComposite.STEP_UP_ACTION,
            enabled: recordId >= 0, readOnly: false, feedback: retention.validationError)
        let stepPreset = CjguiNumericStepperPreset("primary", detailPresetNodeId(recordId, retentionIndex),
            preset.label, preset.value, actionName: CjguiRetentionIntegerEditComposite.PRESET_ACTION,
            writerOperation: "EDIT_DRAFT_TEXT", bindingResourceId: retentionDescriptor.resourceId,
            ownerTargetResourceId: recordId)
        let compositeRow = CjguiRetentionIntegerEditComposite.buildEditor(stepBinding,
            ArrayList<CjguiNumericStepperPreset>([stepPreset]),
            CjguiNumericStepperStyle(input: compactInputStyle,
                button: CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 30),
                preset: compactInputStyle))
        column.add(compositeRow)
        if (retention.validationError.size > 0) {
            // Presentation wording derived from the owner's machine reason; the
            // declared numeric bound itself still lives only in the field
            // declaration the domain validates.
            let message = if (retention.validationError.contains("range") || retention.validationError
                .contains("count")) {
                "${retentionDescriptor.label}超出允许范围"
            } else {
                "请检查${retentionDescriptor.label}"
            }
            column.add(
                cjguiComposableText(detailValidationNodeId(recordId, retentionIndex),
                    "compact-error-retentionCount", message, validationStyle,
                    resourceId: retentionDescriptor.resourceId, fieldId: retentionDescriptor.fieldId,
                    displayValueRole: "validation", operationResourceId: recordId))
        }
        column.add(compactBoundField(form, binding, recordId,
            binding.controlIndexForResourceId(CjguiRuleSetEditingDomain.formExcludedTypeResourceId), inputStyle,
            validationStyle))

        return column
    }

    private func compactBoundField(form: CjguiSharedFormSnapshot, binding: CjguiSharedFormBinding,
        recordId: Int64, fieldIndex: Int64, inputStyle: CjguiComposableUiStyle,
        validationStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let descriptor = binding.fieldAtControlIndex(fieldIndex)
        let field = form.fieldForResourceId(descriptor.resourceId)
        if (descriptor.fieldId == "enabled") {
            return enabledSelectEditor(field.draftText, recordId,
                detailFieldNodeId(recordId, fieldIndex))
        }
        return cjguiComposableBoundFormField(detailFieldGroupNodeId(recordId, fieldIndex),
            "compact-field-group-${descriptor.fieldId}", detailFieldNodeId(recordId, fieldIndex),
            detailValidationNodeId(recordId, fieldIndex), descriptor, field, recordId, inputStyle, validationStyle,
            editorSemanticId: "compact-field-${descriptor.fieldId}",
            validationSemanticId: "compact-error-${descriptor.fieldId}",
            textOperationActionName: "EDIT_DRAFT_TEXT", booleanOperationActionName: "EDIT_DRAFT_BOOLEAN")
    }

    /// The owner's draft value is declared on every scene build, so an external
    /// write shows up in the trigger without the control keeping a second copy.
    /// The SAME field is also presented as a radio group: one declaration, one
    /// commit transaction, two presentations in the ordinary detail.
    private func enabledSelectEditor(draftText: String, recordId: Int64, nodeId: Int64): CjguiComposableUiNode {
        enabledSelectBinding.declare(draftText, enabled: recordId >= 0)
        // The handwritten trigger keeps the select's own scope identity so the
        // popup anchor resolves; the caller's semantic id stays the AX name.
        let trigger = enabledSelect.trigger(nodeId: nodeId)
        trigger.semanticLabel = "启用：${enabledSelect.selectedLabel()}"
        let bound = enabledTooltip.bind(trigger, "启用或停用该规则；应用草稿后写入",
            reference: enabledSelect.triggerReference())
        // The always-visible radio presentation reuses the ONE public choice
        // group over the same declared facts; a dedicated id range inside the
        // detail block avoids another record's per-field ids.
        let group = cjguiComposableVertical(200900000 + recordId * 16, "rule-enabled-field",
            CjguiComposableUiStyle(gap: 4, growX: 1))
        group.add(bound)
        // One trigger by default; the redundant radio presentation is a
        // developer-information alternative, not a second editor on first screen.
        if (developerInfoVisible) {
            group.add(enabledSelectBinding.radioGroupNode("rule-enabled-radio", "rule-enabled-radio",
                label: "启用状态"))
        }
        return group
    }

    private func detailApplyRow(nodeId: Int64, recordId: Int64): CjguiComposableUiNode {
        let applyRow = cjguiComposableHorizontal(nodeId, "draft-actions",
            CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
        applyRow.add(cjguiComposableSpacer(nodeId + 900, "draft-actions-spacer"))
        // ONE primary action per task area: the detail's main action is Apply;
        // Cancel stays the secondary counterpart of the SAME draft decision.
        applyRow.add(command(detailActionNodeId(recordId, 0), "apply", "应用", "APPLY",
            role: CjguiRuleSetCommandRole.PRIMARY, operationResourceId: recordId))
        applyRow.add(command(detailActionNodeId(recordId, 1), "cancel", "取消", "CANCEL",
            operationResourceId: recordId))
        return applyRow
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // DS51 §12 C1 bounded evidence: did ANY public text event reach the
        // consumer for this keystroke? kind/node/text-size only; no value copy.
        if (event.eventKind == 28 || event.eventKind == 29) {
            getStdOut().writeln("RULE_SET_TEXT_EVENT kind=${event.eventKind} node=${event.node.nodeId} " +
                "semantic=${event.node.semanticId} field=${event.node.fieldId} size=${event.text.size} " +
                "pathEvents=${pathInputEvents}")
            getStdOut().flush()
        }
        // §13 C: the public workspace's own action/column events. The scoped
        // node identity owns them; another component's same-named action is not
        // claimed. Persistence is the application's session store here.
        if (let Some(action) <- collectionWorkspace.commandForEvent(event)) {
            let outcome = collectionWorkspace.executeAction(action,
                { encoded => sessionViewSnapshot = encoded; true }, { => sessionViewSnapshot })
            inputNotice = outcome.status
            getStdOut().writeln("RULE_SET_COLLECTION_COMMAND command=${event.text} " +
                "applied=${outcome.applied} reason=${outcome.reason} status=[${outcome.status}]")
            getStdOut().flush()
            localRevision += 1
            return CjguiComposableUiDispatchResult(outcome.applied)
        }
        if (let Some(action) <- collectionWorkspace.actionForEvent(event)) {
            let outcome = collectionWorkspace.executeAction(action,
                { encoded => sessionViewSnapshot = encoded; true }, { => sessionViewSnapshot })
            inputNotice = outcome.status
            getStdOut().writeln("RULE_SET_COLLECTION_VIEW action=${action} applied=${outcome.applied} " +
                "reason=${outcome.reason} status=[${outcome.status}]")
            getStdOut().flush()
            localRevision += 1
            return CjguiComposableUiDispatchResult(outcome.applied)
        }
        if (let Some(applied) <- collectionWorkspace.applyColumnEvent(event)) {
            inputNotice = collectionWorkspace.status()
            getStdOut().writeln("RULE_SET_COLLECTION_COLUMN action=${event.node.actionName} " +
                "applied=${applied} status=[${collectionWorkspace.status()}]")
            getStdOut().flush()
            localRevision += 1
            return CjguiComposableUiDispatchResult(applied)
        }
        // An open searchable-record layer owns its own query/keys/pointer. The
        // panel only forwards a stable record key after its layer closed and
        // focus restoration finished (see finishPanelAction).
        if (let Some(panelResult) <- recordSearchPanel.applyUiEvent(event)) {
            localRevision += 1
            return panelResult
        }
        // The public choice family owns its surfaces here: the Select's
        // trigger/query/row keys and the radio rows of the SAME field all
        // resolve through the one binding before the ordinary node route. A
        // confirmed option is the only path that reaches the owner writer.
        if (let Some(result) <- enabledSelectBinding.applyUiEvent(event)) {
            var applied = result.didApply
            if (enabledSelect.isOpen()) { enabledTooltip.hide() }
            if (applied) {
                if (let Some(option) <- enabledSelectBinding.takeConfirmed()) {
                    let committed = enabledSelectBinding.commit(option)
                    inputNotice = if (committed) {
                        "启用状态已更新为${option.label}；应用草稿后写入"
                    } else {
                        "启用状态未写入：${enabledSelectBinding.lastFailure()}"
                    }
                    print("RULE_ENABLED_SELECT key=${option.key} value=${option.value} applied=${committed}\n")
                    applied = committed
                }
                localRevision += 1
            }
            if ((event.text == "shortcut:up" || event.text == "shortcut:down") && enabledSelect.isOpen()) {
                let local = enabledSelect.highlightedLocalKey()
                if (local.size > 0) {
                    if (let Some(value) <- panelWindow) {
                        let _ = value.focusScopedNode(enabledSelect.scopeKey(), local)
                    }
                }
            }
            return CjguiComposableUiDispatchResult(applied)
        }
        if (let Some(result) <- enabledTooltip.applyUiEvent(event)) {
            localRevision += 1
            return result
        }
        // The UI path entry is application-owned; the scoped field's semantic
        // id identifies it. (28 is TEXT_CHANGED as the framework routes it.)
        // A path DRAFT is not a file association: it is read when a path
        // command arrives below. Rebuilding the whole scene on every keystroke
        // would replace the live text session needlessly; the native field
        // already owns the visible draft until the next ordinary projection.
        if (event.eventKind == 28 &&
            event.node.semanticId == documentWorkspace.pathFieldSemanticId()) {
            // Bounded A2 evidence: the exact text the CONSUMER received for
            // each keystroke, so a native/consumer divergence is attributable.
            pathInputEvents += 1
            getStdOut().writeln("RULE_SET_PATH_INPUT seq=${pathInputEvents} size=${event.text.size} " +
                "node=${event.node.semanticId} text=${event.text}")
            getStdOut().flush()
            uiDocumentPathInput = event.text
            return CjguiComposableUiDispatchResult(true)
        }
        // Command ARRIVAL (event.text carries the command id from the window's
        // command dispatch, e.g. the native menu) executes the owner action.
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.text.size > 0 &&
            documentWorkspace.ownsCommand(event.text)) {
            return finishRuleDocumentEvent("arrival", event.text,
                executeRuleDocumentCommand(event.text))
        }
        // A real click on the built button asks for the command through the
        // public CJGUICOMMAND activation action; this consumer has no window
        // handle inside applyUiEvent, so the request executes directly into
        // the SAME workspace the command id is scoped to.
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                if (documentWorkspace.ownsCommand(commandId)) {
                    return finishRuleDocumentEvent("direct", commandId,
                        executeRuleDocumentCommand(commandId))
                }
            }
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "RULE_UI_CLOSE_SAVE_ALL") {
            let issue = uiCloseGuard.saveUnsaved({ workspace => uiDocumentPathInput })
            if (issue.size > 0) {
                uiCloseGuardNotice = "保存界面被拒：${issue}；可换路径另存，或取消关闭继续编辑"
                localRevision += 1
                getStdOut().writeln("RULE_SET_UI_CLOSE save_all refused=${issue}")
                getStdOut().flush()
                return CjguiComposableUiDispatchResult(false)
            }
            uiCloseGuardActive = false
            localRevision += 1
            getStdOut().writeln("RULE_SET_UI_CLOSE save_all=done")
            getStdOut().flush()
            closeAfterUiFactsSettled()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "RULE_UI_CLOSE_DISCARD") {
            // Discarding UI-document changes writes NOTHING; the business
            // domain's own close policy still runs below. The one-shot flag
            // releases only THIS close attempt.
            uiCloseGuard.discardUnsaved()
            uiCloseGuardActive = false
            localRevision += 1
            getStdOut().writeln("RULE_SET_UI_CLOSE discard_ui")
            getStdOut().flush()
            closeAfterUiFactsSettled()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "RULE_UI_CLOSE_CANCEL") {
            uiCloseGuardActive = false
            uiCloseGuardNotice = ""
            localRevision += 1
            getStdOut().writeln("RULE_SET_UI_CLOSE cancel")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
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
        // Column grips reuse the existing split-handle kind so native capture
        // delivers real pointer phases, but they are NOT the pane divider:
        // their states and constraints belong to the table layout object.
        if (node.actionName == CJGUI_COMPOSABLE_UI_TABLE_COLUMN_RESIZE_ACTION) {
            let key = columnKeyFromSemantic(node.semanticId, "rule-set-table-header-resize-")
            if (key.size == 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            if (event.eventKind == 35) {
                let delta = if (event.text == "left") {
                    -8
                } else if (event.text == "right") {
                    8
                } else {
                    0
                }
                if (delta == 0) {
                    return CjguiComposableUiDispatchResult(false)
                }
                let changed = tableLayout.nudgeWidth(key, delta)
                if (changed) {
                    collectionView.notePresentationChanged()
                    localRevision += 1
                }
                return CjguiComposableUiDispatchResult(changed)
            }
            if (event.eventKind == 37) {
                let began = tableLayout.beginResize(key, event.pointerX, tableLayout.width(key))
                return CjguiComposableUiDispatchResult(began)
            }
            if (event.eventKind == 38 || event.eventKind == 39 || event.eventKind == 40) {
                if (!tableLayout.resizeActive() || tableLayout.resizingKey() != key) {
                    return CjguiComposableUiDispatchResult(false)
                }
                let layoutRevisionBefore = tableLayout.revision()
                if (event.eventKind == 38) {
                    let _ = tableLayout.updateResize(event.pointerX)
                } else if (event.eventKind == 39) {
                    let _ = tableLayout.endResizeAt(event.pointerX)
                } else {
                    let _ = tableLayout.cancelResize()
                }
                if (tableLayout.revision() != layoutRevisionBefore) {
                    collectionView.notePresentationChanged()
                }
                localRevision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            return CjguiComposableUiDispatchResult(false)
        }
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
                    max(tablePaneMinimumWidth(), node.pointerControlFirstSize.saturatingSub(8))
                } else {
                    min(720, node.pointerControlFirstSize.saturatingAdd(8))
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
            let splitFirstSize = CjguiComposableUiSplitGeometry.firstSizeForPointer(event.pointerX, trackOrigin,
                workspaceContentWidth(), node.pointerControlHandleThickness, tablePaneMinimumWidth(), 260)
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
            if (layerMode.size == 0) {
                clearEditDialogReturnTarget()
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && node.nodeId == 21) {
            if (collectionView.mode() == "grid") {
                cardListState.scrollByViewport(event.text)
            } else {
                listState.scrollByViewport(event.text)
            }
            layerMode = ""
            activeRecordId = -1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        // A pointer press produces FOCUS(31) followed by ACTIVATE(27); only
        // ACTIVATE carries that gesture's Command/Shift. Consume the real
        // activation so FOCUS never becomes a second, modifier-less click.
        if (event.eventKind == 27 && node.actionName == "SELECT_RECORD") {
            let key = "rule_${node.resourceId}"
            let order = currentCollectionOrder()
            if (node.resourceId < 0 || order.indexOfKey(key) < 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            let command = (event.modifierFlags & CJGUI_UI_MODIFIER_COMMAND) != 0
            let shift = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            collectionSelection.click(key, command, shift, order)
            treePanel.markCollectionActive()
            // Every plain/Command/Shift click also makes this row the active
            // detail record. The owner preserves all other records' drafts.
            let _ = domain.selectCollectionItemFromHuman(node.resourceId)
            listState.setFocusedKey(key)
            listState.setSelectedKey(key)
            layerMode = ""
            activeRecordId = -1
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 35 && node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            if (let Some(activeView) <- generatedRegion.acceptedCollectionViewForEvent(
                    publicCollection, event)) {
                let navigation = cjguiNavigateGeneratedCollection(publicCollection, activeView,
                    event, panelWindow)
                if (navigation.isHandled) {
                    let plain = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) == 0 &&
                        event.text != "select_all"
                    var ownerApplied = false
                    if (plain && navigation.focus.size > 0) {
                        let focusId = ruleIdForKey(navigation.focus)
                        if (focusId >= 0) {
                            let selected = domain.selectCollectionItemFromHuman(focusId)
                            ownerApplied = selected.applied
                            if (selected.applied) {
                                // The batch transaction consumes the SAME shared
                                // multi-selection, so a plain keyboard move must
                                // make the focused row the explicit selection.
                                let _ = collectionSelection.click(navigation.focus, false, false,
                                    currentCollectionOrder())
                                listState.setSelectedKey(navigation.focus)
                            }
                        }
                    }
                    if (navigation.focus.size > 0) {
                        listState.setFocusedKey(navigation.focus)
                        treePanel.markCollectionActive()
                    }
                    getStdOut().writeln("RULE_SET_GENERATED_COLLECTION_KEYBOARD key=${event.text} " +
                        "focus=${navigation.focus} changed=${navigation.didChange} " +
                        "reveal=${navigation.didAcceptViewFocus} owner=${ownerApplied} " +
                        "offset=${activeView.scrollOffset()}")
                    getStdOut().flush()
                    localRevision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
            }
        }
        if (event.eventKind == 35 && node.nodeId == 21) {
            let order = currentCollectionOrder()
            let extendRange = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            if (collectionView.mode() == "grid") {
                if (event.text == "select_all") {
                    collectionSelection.selectAll(order)
                    let _ = collectionSelection.ensureFocusInOrder(order)
                    let focus = collectionSelection.focus()
                    if (focus.size > 0) {
                        let focusRowKey = cardGridSource.rowKeyForItem(focus)
                        if (focusRowKey.size > 0) {
                            let _ = cardListState.revealKey(cardGridSource, focusRowKey)
                        }
                    }
                    treePanel.markCollectionActive()
                    inputNotice = "全选当前筛选结果：${collectionSelection.selectedCount()} 条（含屏幕外行）"
                    localRevision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
                let target = CjguiComposableUiCardGridNavigation.targetKey(order,
                    collectionSelection.focus(), event.text, cardGridSource.columns())
                if (target.size == 0) {
                    return CjguiComposableUiDispatchResult(false)
                }
                if (!extendRange && target == collectionSelection.focus()) {
                    return CjguiComposableUiDispatchResult(false)
                }
                collectionSelection.moveFocus(target, extendRange, order)
                treePanel.markCollectionActive()
                let targetRowKey = cardGridSource.rowKeyForItem(target)
                if (targetRowKey.size > 0) {
                    cardListState.setFocusedKey(targetRowKey)
                    let _ = cardListState.revealKey(cardGridSource, targetRowKey)
                }
                let focusId = ruleIdForKey(target)
                if (focusId >= 0) {
                    let selected = domain.selectCollectionItemFromHuman(focusId)
                    if (selected.applied) {
                        listState.setSelectedKey(target)
                    }
                }
                localRevision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            let navigation = collectionSelection.navigate(event.text, extendRange, order)
            if (!navigation.didChange) {
                return CjguiComposableUiDispatchResult(false)
            }
            treePanel.markCollectionActive()
            let focus = navigation.focus
            if (focus.size > 0) {
                listState.setFocusedKey(focus)
                let _ = listState.revealKey(currentListSource(), focus)
                let _ = publicCollection.revealItem(focus)
            }
            // Arrow/page/home/end move the active detail record with focus;
            // select-all only changes the multi-selection.
            if (event.text != "select_all" && focus.size > 0) {
                let focusId = ruleIdForKey(focus)
                if (focusId >= 0) {
                    let selected = domain.selectCollectionItemFromHuman(focusId)
                    if (selected.applied) {
                        listState.setSelectedKey(focus)
                    }
                }
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && node.nodeId == 24) {
            applyListFilter(event.text)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && node.nodeId == 390) {
            filePath = event.text
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && node.nodeId == 591) {
            viewDraftName = event.text
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        // A draft-edit control declares its owner. The runtime identity
        // registry may legitimately remap the declared node id, so the numeric
        // ranges below are only a fallback for controls that carry no owner
        // metadata. Declared-but-unusable metadata is refused by name; it never
        // falls back to the selected record or to a guessed id.
        let declaredOwner = declaredDraftOwner(node)
        let targetRecordId = if (declaredOwner >= 0) {
            declaredOwner
        } else if (declaredOwner == -2) {
            -2
        } else {
            let detailTargetRecordId = detailRecordId(node.nodeId)
            if (detailTargetRecordId >= 0) {
                detailTargetRecordId
            } else {
                let dialogId = dialogRecordId(node.nodeId)
                if (dialogId >= 0) {
                    dialogId
                } else {
                    // The converged public-detail block edits the SAME record through
                    // the same owner writer; without this its editors would only
                    // change the native text proxy.
                    publicDetailRecordId(node.nodeId)
                }
            }
        }
        let isDraftEditEvent = event.eventKind == 28 || event.eventKind == 29
        if (isDraftEditEvent && targetRecordId == -2) {
            inputNotice = "未应用：owner_metadata_invalid"
            localRevision += 1
            return CjguiComposableUiDispatchResult(false)
        }
        if (isDraftEditEvent && targetRecordId >= 0 && !domain.hasRecord(targetRecordId)) {
            inputNotice = "未应用：owner_record_retired"
            localRevision += 1
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.eventKind == 28 && targetRecordId >= 0) {
            let observation = ownerWriteObservation.begin(domain, targetRecordId, node.resourceId)
            let result = domain.editTextForCollectionItemFromHuman(targetRecordId, node.resourceId, event.text,
                event.selectionStart, event.selectionEnd)
            ownerWriteObservation.finish(observation, event, targetRecordId, node.resourceId, result, domain)
            if (result.applied) {
                localRevision += 1
            } else {
                // A refused public write used to be silent: an input-loss
                // incident could not be attributed between the owner writer
                // and a later display write-back. One bounded fact, no value
                // copy — the same evidence contract as the kind28 line above.
                getStdOut().writeln("RULE_SET_TEXT_WRITE_REFUSED kind=28 node=${node.nodeId} " +
                    "semantic=${node.semanticId} owner=${targetRecordId} reason=${result.reason} " +
                    "size=${event.text.size}")
                getStdOut().flush()
            };
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 29 && targetRecordId >= 0) {
            let observation = ownerWriteObservation.begin(domain, targetRecordId, node.resourceId)
            let result = domain.editBooleanForCollectionItemFromHuman(targetRecordId, node.resourceId,
                event.text == "true")
            ownerWriteObservation.finish(observation, event, targetRecordId, node.resourceId, result, domain)
            if (result.applied) {
                localRevision += 1
            };
            return CjguiComposableUiDispatchResult(result.applied)
        }
        // The handwritten stepper buttons use the SAME owner action names and
        // shared numeric-step contract the generated composite resolves. The
        // domain reads the current draft and sends the target through the
        // ordinary draft writer; a boundary or invalid value is refused.
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            (node.actionName == CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION ||
             node.actionName == CjguiRetentionIntegerEditComposite.STEP_UP_ACTION) &&
            node.resourceId == CjguiRuleSetEditingDomain.formRetentionResourceId && node.operationResourceId >= 0) {
            let arguments = ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("expectedDraftVersion",
                    CjguiSharedOperationValue.integer(domain.formSnapshot().draftVersion))
            ])
            let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation(node.actionName,
                domain.version(), ArrayList<Int64>([node.operationResourceId]), arguments))
            inputNotice = if (result.applied) {
                "保留天数已步进；草稿尚未应用"
            } else {
                "保留天数步进被拒：${result.reason}"
            }
            localRevision += 1
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
        if (event.eventKind == 27 && node.actionName == "COLLECTION_SELECT_ALL") {
            let order = currentCollectionOrder()
            collectionSelection.selectAll(order)
            let _ = collectionSelection.ensureFocusInOrder(order)
            let focus = collectionSelection.focus()
            if (focus.size > 0) {
                if (collectionView.mode() == "grid") {
                    let _ = cardGridSource.setAvailableWidth(cardGridViewportWidth())
                    let focusRowKey = cardGridSource.rowKeyForItem(focus)
                    if (focusRowKey.size > 0) {
                        let _ = cardListState.revealKey(cardGridSource, focusRowKey)
                    }
                } else {
                    listState.setFocusedKey(focus)
                    let _ = listState.revealKey(currentListSource(), focus)
                }
            }
            treePanel.markCollectionActive()
            inputNotice = "全选当前筛选结果：${collectionSelection.selectedCount()} 条（含屏幕外行）"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && node.actionName == "COLLECTION_CLEAR") {
            collectionSelection.clearSelection()
            treePanel.markCollectionActive()
            inputNotice = "已清除选择"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 &&
            (node.actionName == "COLLECTION_BATCH_ENABLE" || node.actionName == "COLLECTION_BATCH_DISABLE")) {
            return batchSetCollectionEnabled(node.actionName == "COLLECTION_BATCH_ENABLE")
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (node.actionName == "TOGGLE_RULE_VIEW") {
            let nextMode = if (collectionView.mode() == "list") { "table" } else { "list" }
            return CjguiComposableUiDispatchResult(switchViewModeFromHuman(nextMode))
        }
        if (node.actionName == "TOGGLE_CARD_VIEW") {
            let nextMode = if (collectionView.mode() == "grid") { "list" } else { "grid" }
            return CjguiComposableUiDispatchResult(switchViewModeFromHuman(nextMode))
        }
        let sortColumn = sortColumnKeyForAction(node.actionName)
        if (sortColumn.size > 0) {
            if (collectionView.mode() != "table") {
                return CjguiComposableUiDispatchResult(false)
            }
            if (collectionWorkspace.toggleSort(sortColumn)) {
                if (tableSource.indexForKey(listState.focusedKey()) < 0) {
                    let first = tableSource.itemAt(0)
                    listState.setFocusedKey(if (first.resourceId >= 0) {
                        first.key
                    } else {
                        ""
                    })
                }
                // Selected keys are untouched; only the ORDER they cover
                // changes. A hidden focus is repaired on the new order.
                syncCollectionFocusWithView()
                let directionLabel = if (tableSource.sortAscending()) {
                    "升序"
                } else {
                    "降序"
                }
                inputNotice = "已按${sortColumnLabel(sortColumn)}${directionLabel}排序"
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_COLUMN_MENU") {
            if (collectionView.mode() != "table") {
                inputNotice = "列设置仅在表格视图可用"
            } else {
                layerMode = "columns"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(collectionView.mode() == "table")
        }
        if (node.actionName.startsWith("TABLE_COLUMN_")) {
            let togglePrefix = "column-toggle-"
            let leftPrefix = "column-left-"
            let rightPrefix = "column-right-"
            let narrowerPrefix = "column-narrower-"
            let widerPrefix = "column-wider-"
            var changed = false
            if (node.actionName == "TABLE_COLUMN_TOGGLE") {
                let key = columnKeyFromSemantic(node.semanticId, togglePrefix)
                if (key.size == 0) {
                    return CjguiComposableUiDispatchResult(false)
                }
                changed = tableLayout.toggleVisible(key)
                inputNotice = if (changed) {
                    "${tableSource.columnTitle(key)}：${if (tableLayout.isVisible(key)) { "显示" } else { "隐藏" }}"
                } else {
                    "至少保留一列可见"
                }
            } else if (node.actionName == "TABLE_COLUMN_MOVE_LEFT" ||
                node.actionName == "TABLE_COLUMN_MOVE_RIGHT") {
                let left = node.actionName == "TABLE_COLUMN_MOVE_LEFT"
                let key = columnKeyFromSemantic(node.semanticId, if (left) { leftPrefix } else { rightPrefix })
                if (key.size == 0) {
                    return CjguiComposableUiDispatchResult(false)
                }
                changed = tableLayout.move(key, if (left) { -1 } else { 1 })
                inputNotice = if (changed) {
                    "${tableSource.columnTitle(key)}已${if (left) { "左移" } else { "右移" }}"
                } else {
                    "已在该方向边缘"
                }
            } else if (node.actionName == "TABLE_COLUMN_NARROWER" ||
                node.actionName == "TABLE_COLUMN_WIDER") {
                let narrower = node.actionName == "TABLE_COLUMN_NARROWER"
                let key = columnKeyFromSemantic(node.semanticId,
                    if (narrower) { narrowerPrefix } else { widerPrefix })
                if (key.size == 0) {
                    return CjguiComposableUiDispatchResult(false)
                }
                changed = tableLayout.nudgeWidth(key, if (narrower) { -16 } else { 16 })
                inputNotice = if (changed) {
                    "${tableSource.columnTitle(key)}宽度 ${tableLayout.width(key)}"
                } else {
                    "弹性列没有固定宽度"
                }
            } else if (node.actionName == "TABLE_COLUMN_RESET") {
                changed = tableLayout.reset()
                inputNotice = "已恢复默认列布局"
            }
            if (changed) {
                collectionView.notePresentationChanged()
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(changed)
        }
        if (node.actionName == "OPEN_PRESENTATION_MENU") {
            layerMode = "menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_VIEW_MENU") {
            layerMode = "views"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "SAVE_COLLECTION_VIEW") {
            // Human and external callers both reach the domain's view-state
            // host; the preset name is the only extra argument.
            let result = executeViewStateFromHuman("SAVE_COLLECTION_VIEW",
                viewPreferences.revision(), viewDraftName)
            inputNotice = if (result.applied) {
                if (result.reason == "view_unchanged") {
                    "当前视图与“${viewDraftName}”一致"
                } else {
                    "已保存视图“${viewDraftName}”"
                }
            } else {
                "保存视图未应用：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (node.actionName == "SELECT_COLLECTION_VIEW") {
            let presetIndex = viewPresetIndex(node.semanticId)
            let names = viewPreferences.names()
            if (presetIndex < 0 || presetIndex >= names.size) {
                return CjguiComposableUiDispatchResult(false)
            }
            let name = names[presetIndex]
            // The layout/query/sort restore happens before the active name is
            // recorded, so a rejected view never leaves a half-applied preset.
            let result = executeViewStateFromHuman("SELECT_COLLECTION_VIEW",
                collectionView.revision(), name)
            inputNotice = if (result.applied) {
                "已切换视图“${name}”；草稿与选择保持"
            } else {
                "切换视图未应用：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (node.actionName == "RESET_COLLECTION_VIEW") {
            let result = executeViewStateFromHuman("RESET_COLLECTION_VIEW",
                collectionView.revision(), "")
            inputNotice = if (result.applied) {
                "已恢复默认视图；保存的预设仍保留"
            } else {
                "恢复默认视图未应用：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (node.actionName == "SAVE_COLLECTION_VIEW_PREFERENCES") {
            let result = executeViewStateFromHuman("SAVE_COLLECTION_VIEW_PREFERENCES",
                viewPreferences.revision(), "")
            inputNotice = if (result.applied) {
                "视图偏好已保存"
            } else {
                "保存偏好未应用：${result.reason}"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (node.actionName == "TOGGLE_COLUMN_EDITOR") {
            columnEditorVisible = !columnEditorVisible
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "TOGGLE_VIEW_TOOLS") {
            viewToolsVisible = !viewToolsVisible
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_UI_WORKSPACE" || node.actionName == "CLOSE_UI_WORKSPACE" ||
            node.actionName == "TOGGLE_DEVELOPER_INFO") {
            if (node.actionName == "OPEN_UI_WORKSPACE") { uiWorkspaceVisible = true }
            else if (node.actionName == "CLOSE_UI_WORKSPACE") { uiWorkspaceVisible = false }
            else { developerInfoVisible = !developerInfoVisible }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_EDIT_DIALOG") {
            if (renderedSelectedId < 0) {
                inputNotice = "请先选择一条规则"
            } else {
                // Capture the public return reference for the EXISTING modal
                // machinery. `editingFocusReference` is the live text editor;
                // `focusedNodeReference` covers a just-focused ordinary control.
                let returnTarget = match (panelWindow) {
                    case Some(value) => value.editingFocusReference() ?? value.focusedNodeReference() ??
                        CjguiComposableUiNodeReference.manual(29)
                    case None => CjguiComposableUiNodeReference.manual(29)
                }
                editDialogReturnTarget = Some(returnTarget)
                editDialogReturnRecordId = renderedSelectedId
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
                clearEditDialogReturnTarget()
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_RECORD_SEARCH") {
            let snapshot = domain.snapshot()
            let items = ArrayList<CjguiSearchableSelectionItem>()
            for (record in snapshot.records) {
                let enabledLabel = if (record.enabled) { "已启用" } else { "已停用" }
                items.add(
                    CjguiSearchableSelectionItem("${record.id}", record.label,
                        detail: "保留 ${record.retentionCount} 天 · ${enabledLabel} · 排除 ${record.excludedType}",
                        keywords: record.excludedType))
            }
            if (items.size == 0) {
                inputNotice = "没有可查找的规则；请先新增"
                localRevision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            // returnTarget is the control that owned input when the panel was
            // opened. The panel restores exactly that control after a cancel.
            let returnTarget = match (panelWindow) {
                case Some(value) => value.editingFocusReference() ?? value.focusedNodeReference() ??
                    CjguiComposableUiNodeReference.manual(27)
                case None => CjguiComposableUiNodeReference.manual(27)
            }
            recordSearchPanel.open("查找规则", items, returnTarget,
                hint: "输入名称筛选；↑ ↓ 选择，Enter 定位，Esc 取消")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "CLEAR_RULE_FILTER") {
            if (collectionView.query().size == 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            applyListFilter("")
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "TOGGLE_DETAIL_LAYOUT") {
            detailLayout = if (detailLayout == "compact") { "standard" } else { "compact" }
            let draft = domain.formSnapshot()
            let layoutLabel = if (detailLayout == "compact") { "紧凑" } else { "标准" }
            inputNotice = "已切换到${layoutLabel}字段布局；草稿 v${draft.draftVersion} 未提交"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        // The single-choice group uses direct set actions rather than a toggle:
        // selecting the already-current option is a no-op, and every option
        // carries its stable key/value.
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            (node.actionName == "SET_DETAIL_LAYOUT_STANDARD" || node.actionName == "SET_DETAIL_LAYOUT_COMPACT")) {
            let nextLayout = if (node.actionName == "SET_DETAIL_LAYOUT_COMPACT") { "compact" } else { "standard" }
            if (nextLayout == detailLayout) {
                return CjguiComposableUiDispatchResult(true)
            }
            detailLayout = nextLayout
            let draft = domain.formSnapshot()
            let layoutLabel = if (detailLayout == "compact") { "紧凑" } else { "标准" }
            inputNotice = "已切换到${layoutLabel}字段布局；草稿 v${draft.draftVersion} 未提交"
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
        // Apply/Cancel carry their owner on the command. The encoded action-node
        // ranges remain the fallback for controls that declare no owner.
        let commandOwner = if (node.actionName == "APPLY" || node.actionName == "CANCEL") {
            commandOwnerForNode(node)
        } else {
            -1
        }
        if ((node.actionName == "APPLY" || node.actionName == "CANCEL") && commandOwner == -2) {
            inputNotice = "未应用：owner_metadata_invalid"
            localRevision += 1
            return CjguiComposableUiDispatchResult(false)
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
        } else if (node.actionName == "APPLY" && commandOwner >= 0) {
            let itemId = commandOwner
            domain.applyDraftForCollectionItemFromHuman(itemId, domain.draftVersionForCollectionItem(itemId),
                domain.baseAppliedVersionForCollectionItem(itemId))
        } else if (node.actionName == "CANCEL" && commandOwner >= 0) {
            let itemId = commandOwner
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
            clearEditDialogReturnTarget()
        }
        if (result.applied) {
            localRevision += 1
        } else if (result.reason.size > 0 && result.reason != "unknown_ui_action") {
            // A disabled/no-selection/rejected owner action still produces
            // visible feedback; it never reports success or drops the draft.
            inputNotice = "未应用：${result.reason}"
            localRevision += 1
        }
        return CjguiComposableUiDispatchResult(result.applied, shouldClose: node.actionName == "CLOSE" && result.applied)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        // UI-document facts settle first and become visible through the
        // ordinary refresh; only a clean document state reaches the business
        // close policy. The system close button, ⌘W and ⌘Q all arrive here.
        let blocking = uiCloseGuard.settleAndReport()
        if (blocking.size > 0) {
            uiCloseGuardActive = true
            uiCloseGuardNotice = blocking
            let _ = rootViewport.requestOffset(0)
            localRevision += 1
            // A native close request carries no input event; wake the ordinary
            // scene loop so the blocked decision becomes visible immediately.
            if (let Some(value) <- panelWindow) { value.requestRefresh() }
            getStdOut().writeln("RULE_SET_UI_CLOSE blocked reason=${blocking}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(false, shouldClose: false)
        }
        let result = domain.requestCloseFromHuman();
        // UI clean does not imply the RULE document is clean. A business
        // refusal must be visible in the same refresh and must keep the window
        // open; a clean decision reaches the host as a real close request.
        getStdOut().writeln("RULE_SET_UI_CLOSE business applied=${result.applied} reason=${result.reason}")
        getStdOut().flush()
        if (!result.applied) {
            inputNotice = "未关闭：${result.reason}"
            let _ = rootViewport.requestOffset(0)
            if (let Some(value) <- panelWindow) { value.requestRefresh() }
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied, shouldClose: result.applied)
    }

    /// The document facts are settled and the user chose to close: the host
    /// turn loop performs one ordinary host close request, which re-enters
    /// requestWindowClose (guard now clean) and then the business policy.
    private func closeAfterUiFactsSettled(): Unit {
        pendingCloseRequested = true
    }

    /// One shared execution of a scoped document command (arrival or direct).
    private func executeRuleDocumentCommand(commandId: String): CjguiUiDocumentSessionResult {
        // C1: the save command reads exactly this draft. A divergence between
        // the posted text, the public TEXT_CHANGED sequence and this value is
        // attributable here instead of from the final generic error.
        if (commandId == documentWorkspace.pathCommandId(open: false) ||
            commandId == documentWorkspace.pathCommandId()) {
            getStdOut().writeln("RULE_SET_SAVE_READ command=${commandId} events=${pathInputEvents} " +
                "size=${uiDocumentPathInput.size} text=${uiDocumentPathInput}")
            getStdOut().flush()
        }
        if (let Some(done) <- documentWorkspace.handlePathCommand(commandId,
                uiDocumentPathInput)) {
            return done
        }
        return documentWorkspace.handleCommand(commandId).getOrThrow()
    }

    private func finishRuleDocumentEvent(channel: String, commandId: String,
        done: CjguiUiDocumentSessionResult): CjguiComposableUiDispatchResult {
        inputNotice = done.detail
        getStdOut().writeln("RULE_SET_UI_DOCUMENT channel=${channel} command=${commandId} " +
            "applied=${done.applied} reason=${done.reason} submitted=${done.submitted} " +
            "accepted=${done.accepted} " +
            "acceptedVersion=${generatedRegion.acceptedStructureVersion()}")
        getStdOut().flush()
        localRevision += 1
        return CjguiComposableUiDispatchResult(done.applied)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        inputNotice = if (eventKind == 11) {
            "输入队列已满：本次输入未应用，请重试"
        } else {
            // User-facing wording stays short; the detail stays in the app log so
            // a developer can still identify the exact stale control.
            print("CJGUI_RULE_REJECTED_EVENT kind=${eventKind} node=${nodeId}\n")
            "输入未应用：界面已刷新，请重试"
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
            // DS51 §12 C2: name the REAL seam. The window reports only
            // "participant_prepare"; this line says whether the handwritten
            // registry or the generated holder refused, and why.
            getStdOut().writeln("CJGUIRULE_PREPARE_FAIL phase=handwritten " +
                "issue=${componentRegistry.lastIssue()}")
            getStdOut().flush()
            generatedRegion.rollbackSceneRefresh()
            return false
        }
        if (!generatedRegion.prepareSceneRefresh()) {
            getStdOut().writeln("CJGUIRULE_PREPARE_FAIL phase=generated scene=${generatedRegion.sceneState()} " +
                "accepted=${generatedRegion.acceptedStructureVersion()} " +
                "candidate=${generatedRegion.candidateStructureVersion()}")
            getStdOut().writeln("CJGUIRULE_PREPARE_TICKET ${generatedRegion.candidateTicketForDiagnosis()}")
            getStdOut().flush()
            generatedRegion.rollbackSceneRefresh()
            return false
        }
        return true
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        // The reusable panel contributes its scoped arrow/enter/escape keys;
        // the application contributes the one ⌘K entry that opens it.
        let commands = recordSearchPanel.commands()
        commands.add(
            CjguiComposableUiCommand(
                "rule-set.find-record",
                CjguiComposableUiNodeReference.manual(27),
                "查找规则",
                CjguiComposableUiShortcut("k"),
                "Edit",
                2,
                layerMode.size == 0 && !recordSearchPanel.isOpen(),
                false
            ))
        commands.add(
            CjguiComposableUiCommand(
                "rule-set.open-presentation-menu",
                CjguiComposableUiNodeReference.scoped(presentationScope, "open-menu"),
                "更多",
                CjguiComposableUiShortcut("m"),
                "View",
                0,
                layerMode != "menu" && !recordSearchPanel.isOpen(),
                false
            ))
        // The beacon toggle's one live control is the menu item, so the command
        // joins the table with the menu layer; a declaration whose target is
        // absent from the scene would reject the whole candidate.
        if (layerMode == "menu") {
            commands.add(
                CjguiComposableUiCommand(
                    "rule-set.toggle-beacon",
                    CjguiComposableUiNodeReference.scoped(presentationScope, "menu-toggle-beacon"),
                    "切换图标",
                    "View",
                    1,
                    !recordSearchPanel.isOpen(),
                    usesCoralBeacon,
                    focusScopeId: "rule-set-menu"
                ))
        }
        // The document commands come from the workspace's OWN projection; the
        // overlay gate (modal layer / open panel) is this consumer's menu
        // placement decision, not a second availability owner.
        if (uiWorkspaceVisible) {
            for (declaration in documentWorkspace.commandDeclarations()) {
                commands.add(CjguiComposableUiCommand(declaration.id,
                    declaration.targetReference, declaration.displayName, "File", 3,
                    declaration.isEnabled && layerMode.size == 0 && !recordSearchPanel.isOpen(),
                    false))
            }
        }
        // The collection workspace's commands target its action-bar controls,
        // which are mounted while the "视图 / 列" fold is expanded; a
        // declaration whose controls are not in the scene would reject the
        // candidate, so the commands follow the same fold.
        if (viewToolsVisible) {
            for (declaration in collectionWorkspace.commandDeclarations(sessionViewSnapshot)) {
                commands.add(declaration)
            }
        }
        for (command in enabledSelect.commands()) { commands.add(command) }
        return commands
    }
    public func commitSceneRefresh(): Unit {
        componentRegistry.commitTransaction()
        // Published only now: the candidate structure, its version and its
        // event identity table become the accepted interface together with the
        // scene the window accepted.
        generatedRegion.commitSceneRefresh()
    }
    public func disposeSceneRefreshResources(): Unit {
        let _ = documentWorkspace.closeHistory()
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
    public func rollbackSceneRefresh(reason: String): Unit {
        componentRegistry.rollbackTransaction()
        generatedRegion.rollbackSceneRefresh(reason)
    }

    /// One command, one role. The secondary role carries its own base paint AND
    /// the full hover/pressed/focused/disabled coverage from the SAME public
    /// theme; passing a neutral base together with `primaryActionInteraction`
    /// used to repaint secondary commands solid blue because `resolve` applies
    /// `normal` first.
    private func command(nodeId: Int64, semanticId: String, label: String, actionName: String,
        role!: CjguiRuleSetCommandRole = CjguiRuleSetCommandRole.SECONDARY,
        operationResourceId!: Int64 = -1): CjguiComposableUiNode {
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        let (base, interaction) = match (role) {
            case CjguiRuleSetCommandRole.PRIMARY => (theme.primaryAction, theme.primaryActionInteraction)
            case CjguiRuleSetCommandRole.SECONDARY => (theme.secondaryAction, theme.secondaryActionInteraction)
        }
        let style = CjguiComposableUiStyle(minWidth: 48, fixedHeight: base.fixedHeight,
            background: base.background, border: base.border, textColor: base.textColor,
            borderWidth: base.borderWidth, cornerRadius: 6, fontFamily: if (usesMonospacedText) {
                "monospaced"
            } else {
                "system"
            })
        return cjguiComposableButton(nodeId, semanticId, label, actionName, CjguiRuleSetEditingDomain.ruleSetResourceId,
            style, operationActionName: operationActionName(actionName),
            operationResourceId: operationResourceId, interactionStyle: interaction)
    }
    private func localPresentationButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
        width: Int64, operationResourceId!: Int64 = -1): CjguiComposableUiNode {
        // Command targets carry the owning rule-set resource. A native menu
        // binding rejects a negative target resource id, and this control may
        // be addressed through the window's command table (⌘K, menus, keys).
        // Presentation utilities are SECONDARY actions: the base paint and the
        // whole interaction set come from the one public secondary role.
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        return cjguiComposableButton(nodeId, semanticId, label, actionName,
            CjguiRuleSetEditingDomain.ruleSetResourceId, secondaryActionPresentationStyle(theme, width),
            operationResourceId: operationResourceId, interactionStyle: theme.secondaryActionInteraction)
    }
    private func scopedLocalPresentationButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
        width: Int64, identity: CjguiComposableUiIdentity, styleName!: String = "rule_primary_action"): CjguiComposableUiNode {
        // ONE definition: the application's named paint role supplies the paint,
        // the helper keeps its own geometry. The same style objects are
        // registered in the capability catalog the generated nodes resolve
        // against, so the handwritten entry and generated content reference the
        // SAME named role (primary or secondary).
        let sized = presentationButtonStyle(width)
        let accent = generatedRegion.namedStyle(styleName)
        let painted = match (accent) {
            case Some(value) => cjguiComposableUiPaintOverlay(sized, value.base)
            case None => sized
        }
        let fallback = CjguiComposableUiTheme.paperLight()
        let interaction = match (accent) {
            case Some(value) => value.interaction
            case None => if (styleName == "rule_secondary_action") {
                fallback.secondaryActionInteraction
            } else {
                fallback.primaryActionInteraction
            }
        }
        return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_BUTTON, label, label, actionName,
            CjguiRuleSetEditingDomain.ruleSetResourceId, painted, interactionStyle: interaction,
            identity: Some(identity))
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
    /// A secondary command's geometry with paint from the PUBLIC secondary
    /// role: callers pass `theme.secondaryActionInteraction` next to it so the
    /// button keeps the whole hover/pressed/focused/disabled coverage instead
    /// of a neutral base repainted solid primary.
    private func secondaryActionPresentationStyle(theme: CjguiComposableUiTheme, width: Int64): CjguiComposableUiStyle {
        let base = theme.secondaryAction
        return CjguiComposableUiStyle(minWidth: if (width > 48) {
            48
        } else {
            width
        }, idealWidth: width, fixedHeight: base.fixedHeight, background: base.background,
            border: base.border, textColor: base.textColor, borderWidth: base.borderWidth,
            cornerRadius: 6, fontFamily: if (usesMonospacedText) {
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
    private func currentListSource(): CjguiComposableUiVariableHeightListSource {
        // Keyboard navigation resolves the SAME projection the scene presents,
        // so "down" walks visible rows by stable key even while filtered and
        // sorted. The table never turns a display position into business id.
        return if (collectionView.mode() == "table" || collectionView.mode() == "grid") {
            tableSource
        } else {
            filteredListSource
        }
    }

    private func currentCollectionOrder(): CjguiComposableUiCollectionOrder {
        return if (collectionView.mode() == "table" || collectionView.mode() == "grid") {
            collectionTableOrder
        } else {
            collectionFilteredOrder
        }
    }

    /// Actual content width of the split's first pane. The window frame gives
    /// the current size after a native resize; the split geometry applies the
    /// same handle and pane minima the layout will use. The card grid then
    /// decides how many fixed-height cards fit.
    private func workspaceContentWidth(): Int64 {
        let frame: ?(Int64, Int64, Int64, Int64) = match (panelWindow) {
            case Some(window) => window.windowScreenFrame()
            case None => None
        }
        let windowWidth = match (frame) {
            case Some(value) => value[2]
            case None => 980
        }
        return max(0, windowWidth - 28)
    }

    private func tablePaneMinimumWidth(): Int64 {
        return if (collectionView.mode() == "table") { max(420, tableSource.minimumContentWidth()) } else { 160 }
    }

    private func tableWorkspaceStacks(width: Int64): Bool {
        return collectionView.mode() == "table" && width < tablePaneMinimumWidth() + 268
    }

    private func tablePaneWidth(width: Int64): Int64 {
        return if (tableWorkspaceStacks(width)) { width } else {
            CjguiComposableUiSplitGeometry.firstSizeForTrack(domain.splitFirstSize(), width, 8,
                tablePaneMinimumWidth(), 260)
        }
    }

    private func cardGridViewportWidth(): Int64 {
        let requested = domain.splitFirstSize()
        let firstPane = CjguiComposableUiSplitGeometry.firstSizeForTrack(requested,
            workspaceContentWidth(), 8, 160, 260)
        return if (firstPane > 0) { firstPane } else { 190 }
    }

    /// Human mode controls use the SAME view-state host external clients use.
    /// The split widening is a separate existing presentation action and is
    /// only applied for table/grid modes that need more horizontal room.
    private func switchViewModeFromHuman(mode: String): Bool {
        let arguments = ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("mode", CjguiSharedOperationValue.string(mode))
        ])
        let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation(
            "SET_COLLECTION_VIEW_MODE", collectionView.revision(),
            ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]), arguments))
        if (!result.applied) {
            inputNotice = "视图切换未应用：${result.reason}"
            localRevision += 1
            return false
        }
        if ((mode == "table" || mode == "grid") && domain.splitFirstSize() < 520) {
            let _ = domain.setSplitFirstSizeFromHuman(520)
        }
        syncCollectionFocusWithView()
        inputNotice = if (mode == "grid") {
            "卡片视图：拖动窗口边缘可改变列数"
        } else if (mode == "table") {
            "表格视图：点击表头排序"
        } else {
            "列表视图"
        }
        localRevision += 1
        return true
    }

    /// A mode hint left by an earlier human switch must not describe the new
    /// mode after an external client changed it. Non-mode notices (draft,
    /// batch, save results) still take precedence.
    /// Display-only classification of the owner's message. It never changes the
    /// message or the owner's validation; the textual kind marker keeps status
    /// readable without relying on colour.
    private func statusKindFor(message: String): String {
        if (message.contains("被拒") || message.contains("失败") || message.contains("冲突") ||
            message.contains("错误")) {
            return CJGUI_STATUS_ERROR
        }
        if (message.contains("已保存") || message.contains("已应用") || message.contains("成功")) {
            return CJGUI_STATUS_SUCCESS
        }
        if (message.contains("尚未") || message.contains("隐藏") || message.contains("警告")) {
            return CJGUI_STATUS_WARNING
        }
        return CJGUI_STATUS_INFO
    }

    private func viewStatusText(fallback: String): String {
        let modeNotice = inputNotice == "列表视图" ||
            inputNotice.startsWith("卡片视图：") || inputNotice.startsWith("表格视图：")
        if (modeNotice) {
            if (collectionView.mode() == "grid") {
                return "卡片视图：拖动窗口边缘可改变列数"
            }
            if (collectionView.mode() == "table") {
                return "表格视图：点击表头排序"
            }
            return "列表视图"
        }
        return if (inputNotice.size > 0) { inputNotice } else { fallback }
    }

    /// Keeps the virtual-list cursor on the collection focus after a filter,
    /// sort or view switch. A focus hidden by the new projection falls back to
    /// the still-visible anchor, then to the first selectable row; selected
    /// keys themselves are never dropped here.
    private func syncCollectionFocusWithView(): Unit {
        let order = currentCollectionOrder()
        let _ = collectionSelection.ensureFocusInOrder(order)
        let focus = collectionSelection.focus()
        if (collectionView.mode() == "grid") {
            let _ = cardGridSource.setAvailableWidth(cardGridViewportWidth())
            if (focus.size > 0) {
                let focusRowKey = cardGridSource.rowKeyForItem(focus)
                if (focusRowKey.size > 0) {
                    let _ = cardListState.revealKey(cardGridSource, focusRowKey)
                }
            }
            return
        }
        if (focus.size > 0) {
            listState.setFocusedKey(focus)
            let _ = listState.revealKey(currentListSource(), focus)
        }
    }

    /// Runs once per owner data version. Deleting a record or losing
    /// selectability prunes its key; editing a draft does not.
    private func syncCollectionSelectionWithData(): Unit {
        let version = domain.version()
        if (version == collectionPrunedVersion) {
            return
        }
        collectionPrunedVersion = version
        collectionSelection.pruneToEligible(collectionEligibilityOrder)
    }

    private func ruleIdForKey(key: String): Int64 {
        let parts = key.split("_")
        if (parts.size == 2 && parts[0] == "rule") {
            if (let Some(id) <- Int64.tryParse(parts[1])) {
                return id
            }
        }
        return -1
    }

    /// One owner transaction for the whole selection. Hidden selected keys are
    /// included on purpose; the owner validates every target, version, draft
    /// conflict and transaction rule once, exactly like its external batch
    /// entry. The UI never loops row-by-row writes.
    private func batchSetCollectionEnabled(enabled: Bool): CjguiComposableUiDispatchResult {
        let keys = collectionSelection.selectedKeysInOrder()
        if (keys.size == 0) {
            inputNotice = "批量：未选择记录"
            localRevision += 1
            return CjguiComposableUiDispatchResult(false)
        }
        let ids = ArrayList<Int64>()
        let seen = HashSet<Int64>()
        for (key in keys) {
            let id = ruleIdForKey(key)
            if (id < 0) {
                inputNotice = "批量被拒：选择中存在非记录 key"
                localRevision += 1
                return CjguiComposableUiDispatchResult(false)
            }
            if (!seen.contains(id)) {
                seen.add(id)
                ids.add(id)
            }
        }
        collectionBatchSerial += 1
        let hidden = collectionSelection.hiddenCount(currentCollectionOrder())
        let requestId = "collection-batch-${collectionBatchSerial}-${domain.version()}-${ids.size}"
        let arguments = ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("enabled", CjguiSharedOperationValue.boolean(enabled)),
            CjguiSharedOperationActionArgument("requestId", CjguiSharedOperationValue.string(requestId))
        ])
        let invocation = CjguiSharedOperationActionInvocation(
            "BATCH_SET_ENABLED", domain.snapshot().version, ids, arguments)
        let result = domain.executeFromHuman(invocation)
        let actionLabel = if (enabled) { "启用" } else { "停用" }
        let hiddenLabel = if (hidden > 0) { "（含隐藏 ${hidden} 条）" } else { "" }
        inputNotice = if (result.applied) {
            "批量${actionLabel} ${ids.size} 条${hiddenLabel} → v${result.versionAfter}"
        } else {
            "批量被拒：${result.reason}"
        }
        localRevision += 1
        treePanel.markCollectionActive()
        return CjguiComposableUiDispatchResult(result.applied)
    }

    /// Uses the controller's existing scene revision instead of the owner data
    /// version: filtering, sorting and view switching change the projection
    /// without changing the document, so domain.version alone would look stale.
    private func collectionViewVersion(): Int64 {
        return uiSceneVersion()
    }

    /// The ONE column layout object shared by the table, the column menu and
    /// the external action host.
    public func tableColumnLayout(): CjguiComposableUiTableColumnLayout {
        return tableLayout
    }

    /// Public selection snapshot for consumers/tests: the same object the
    /// external provider reports, never a second projection.
    public func collectionSelectionSnapshot(): CjguiComposableUiCollectionSelectionSnapshot {
        return collectionSelection.snapshot(collectionViewVersion())
    }

    public func collectionHiddenCount(): Int64 {
        return collectionSelection.hiddenCount(currentCollectionOrder())
    }

    public func collectionSelectionVersion(): Int64 {
        return collectionSelection.selectionVersion()
    }

    private func columnKeyFromSemantic(semanticId: String, prefix: String): String {
        let parts = semanticId.split(prefix)
        if (parts.size == 2) {
            return parts[1]
        }
        return ""
    }

    private func sortColumnKeyForAction(actionName: String): String {
        if (actionName == CjguiRuleSetTableColumns.sortNameAction) {
            return "name"
        }
        if (actionName == CjguiRuleSetTableColumns.sortEnabledAction) {
            return "enabled"
        }
        if (actionName == CjguiRuleSetTableColumns.sortRetentionAction) {
            return "retention"
        }
        if (actionName == CjguiRuleSetTableColumns.sortExcludedAction) {
            return "excluded"
        }
        return ""
    }

    private func sortColumnLabel(columnKey: String): String {
        if (columnKey == "name") {
            return "规则名称"
        }
        if (columnKey == "enabled") {
            return "启用状态"
        }
        if (columnKey == "retention") {
            return "保留天数"
        }
        if (columnKey == "excluded") {
            return "排除类型"
        }
        return columnKey
    }

    /// Drops the captured public return reference once the dialog is really
    /// closing. The window's own modal-return anchor remains the single focus
    /// owner; this only releases the consumer-side reference.
    private func clearEditDialogReturnTarget(): Unit {
        editDialogReturnTarget = None
        editDialogReturnRecordId = -1
    }

    /// Applies a filter query and keeps focus on a row that still exists.
    /// Selection is domain-owned and is not cleared just because the selected
    /// record left the filter; the detail pane intentionally keeps it.
    private func applyListFilter(value: String): Unit {
        // The view owns the text query and the table delegates it to the same
        // filtered source, so the list and table projections cannot diverge.
        let _ = collectionView.setQuery(value)
        tableSource.dataChanged(domain.version())
        let visible = tableSource.itemCount()
        // Selected keys stay selected even when the filter hides their rows;
        // only the keyboard cursor is repaired onto the new order.
        syncCollectionFocusWithView()
        if (tableSource.indexForKey(listState.focusedKey()) < 0) {
            let first = tableSource.itemAt(0)
            listState.setFocusedKey(if (first.resourceId >= 0) {
                first.key
            } else {
                ""
            })
        }
        let selected = domain.selectedRecordId()
        listState.setSelectedKey(if (selected >= 0) {
            "rule_${selected}"
        } else {
            ""
        })
        inputNotice = if (value.size == 0) {
            "已清除筛选"
        } else {
            "筛选“${value}”：${visible} 条匹配"
        }
        localRevision += 1
    }
    private func detailFieldNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 200000000 + recordId * 16 + fieldIndex
    }
    /// The converged public-detail block owns its own id range so it can sit
    /// beside the app's handwritten fields without colliding with them.
    private func publicDetailEditorNodeId(recordId: Int64): Int64 {
        return 810000000 + recordId * 100
    }
    private func publicDetailStatusNodeId(recordId: Int64): Int64 {
        return 830000000 + recordId * 100
    }
    /// Record id encoded by the public-detail block's own editor ids. Only this
    /// block's range resolves here; ordinary detail/dialog ids keep their own
    /// mapping.
    private func publicDetailRecordId(nodeId: Int64): Int64 {
        if (nodeId >= 810000000 && nodeId < 830000000) {
            return (nodeId - 810000000) / 100
        }
        return -1
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
    /// Identity of the composite preset button inside the COMPACT detail
    /// layout. The same composite implementation is shared with the dialog and
    /// the generated region; only the declared identity differs.
    private func detailPresetNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1100000000 + recordId * 16 + fieldIndex
    }
    private func dialogStepperRowNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1200000000 + recordId * 16 + fieldIndex
    }
    private func dialogStepperPresetsNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1300000000 + recordId * 16 + fieldIndex
    }
    private func dialogStepDownNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1400000000 + recordId * 16 + fieldIndex
    }
    private func dialogStepUpNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1500000000 + recordId * 16 + fieldIndex
    }
    private func detailStepperRowNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1600000000 + recordId * 16 + fieldIndex
    }
    private func detailStepperPresetsNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1700000000 + recordId * 16 + fieldIndex
    }
    private func detailStepDownNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1800000000 + recordId * 16 + fieldIndex
    }
    private func detailStepUpNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 1900000000 + recordId * 16 + fieldIndex
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
    /// Owner declared by a draft-edit control. -1 = none (legacy numeric
    /// fallback); -2 = declared but unusable (unknown owner or unbound field).
    private func declaredDraftOwner(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.operationActionName != "EDIT_DRAFT_TEXT" && node.operationActionName != "EDIT_DRAFT_BOOLEAN") {
            return -1
        }
        if (node.operationResourceId < 0 || !domain.hasRecord(node.operationResourceId)) {
            return -2
        }
        if (!isBoundFieldResource(node.resourceId)) {
            return -2
        }
        return node.operationResourceId
    }
    private func isBoundFieldResource(resourceId: Int64): Bool {
        let binding = domain.formBinding()
        var index: Int64 = 0
        while (index < binding.fieldCount()) {
            if (binding.fieldAtControlIndex(index).resourceId == resourceId) {
                return true
            }
            index += 1
        }
        return false
    }
    /// Owner for APPLY/CANCEL. Declared metadata wins; the encoded action-node
    /// ranges remain only for controls that declare none. -2 = declared but
    /// unknown owner (refused by name, never redirected to another card).
    private func commandOwnerForNode(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.operationResourceId >= 0) {
            if (!domain.hasRecord(node.operationResourceId)) {
                return -2
            }
            return node.operationResourceId
        }
        let encoded = actionRecordId(node.nodeId)
        if (encoded >= 0 && !domain.hasRecord(encoded)) {
            return -1
        }
        return encoded
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
    var seedTableRows: Int64 = 0
    var performanceScene = false
    var observeCosts = false
    var viewPreferencesPath = ""
    var uiDocumentPath = ""
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
        } else if (args[index] == "--seed-table-rows" && index + 1 < args.size && seedTableRows == 0) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value > 0 && value <= 2000) {
                    seedTableRows = value
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
        } else if (args[index] == "--performance-scene" && !performanceScene) {
            performanceScene = true
            index += 1
        } else if (args[index] == "--observe-costs" && !observeCosts) {
            observeCosts = true
            index += 1
        } else if (args[index] == "--ui-document" && index + 1 < args.size && uiDocumentPath.size == 0) {
            uiDocumentPath = args[index + 1]
            index += 2
        } else if (args[index] == "--view-preferences" && index + 1 < args.size && viewPreferencesPath.size == 0) {
            // Explicit presentation preference file. It is deliberately a
            // separate path from --open/--save-as: a document save never writes
            // view preferences and a preference save never rewrites the rule set.
            viewPreferencesPath = args[index + 1]
            index += 2
        } else {
            return None
        }
    }
    return Some(
        CjguiRuleSetStartupFiles(openPath, saveAsPath, verifiesHostCloseDecisions, measurementDurationMs,
            measurementWarmupMs, retentionMinimum, retentionMaximum,
            retentionPreset: retentionPreset, seedTableRows: seedTableRows,
            viewPreferencesPath: viewPreferencesPath, performanceScene: performanceScene, observeCosts: observeCosts,
            uiDocumentPath: uiDocumentPath))
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
                CjguiSharedOperationExternalActionScope("SET_TABLE_COLUMN_WIDTH", all, true),
                CjguiSharedOperationExternalActionScope("SET_TABLE_COLUMN_VISIBLE", all, true),
                CjguiSharedOperationExternalActionScope("MOVE_TABLE_COLUMN", all, true),
                CjguiSharedOperationExternalActionScope("RESET_TABLE_COLUMNS", all, true),
                CjguiSharedOperationExternalActionScope("SAVE_COLLECTION_VIEW", all, true),
                CjguiSharedOperationExternalActionScope("SELECT_COLLECTION_VIEW", all, true),
                CjguiSharedOperationExternalActionScope("RESET_COLLECTION_VIEW", all, true),
                CjguiSharedOperationExternalActionScope("SET_COLLECTION_VIEW_MODE", all, true),
                CjguiSharedOperationExternalActionScope("SAVE_COLLECTION_VIEW_PREFERENCES", all, true),
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

// The current window contract is asynchronous: `refresh()` only requests a
// refresh and the scene is accepted during a later ordinary host turn (an
// image/drawable may need bounded preparation). Tests therefore request the
// refresh and pump normal host turns until the accepted scene reaches the
// target and no refresh remains pending, instead of asserting the request call
// itself succeeded.
//
// Test cleanup uses `window.close()` rather than `host.close()`: the Host's
// close additionally calls the process-global `stopApplicationLoop`, and
// creating the next native window in the same test process after that stop
// aborts the renderer bridge (recorded runtime lifecycle defect in this frozen
// tree). `window.close()` destroys this test's native session; the Host owns no
// external connection here, so nothing else needs releasing.
private func pumpSceneAccepted(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow,
    atLeast!: Int64 = 1): Bool {
    let _ = window.refresh()
    var turns: Int64 = 0
    while (turns < 128) {
        let progress = window.windowProgress()
        if (progress.acceptedSceneVersion >= atLeast && progress.pendingRefreshReason == "none") {
            return true
        }
        if (!host.isOpen()) {
            break
        }
        let _ = host.pumpOneTurn()
        turns += 1
    }
    let progress = window.windowProgress()
    return progress.acceptedSceneVersion >= atLeast && progress.pendingRefreshReason == "none"
}

// Wait for the NEXT accepted scene (the usual case after an owner write or a
// view-state change that bumps the controller's declared UI revision).
private func pumpNextScene(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow): Bool {
    return pumpSceneAccepted(host, window, atLeast: window.windowProgress().acceptedSceneVersion + 1)
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

// Resolve a command by its stable id. The command table also contains the
// search panel's keys only while that panel is open, so a positional index is
// not a stable identity for the toggle command.
private func ruleSetCommandChecked(controller: CjguiRuleSetComposableController, commandId: String): Bool {
    for (command in controller.candidateSceneCommands()) {
        if (command.id == commandId) {
            return command.isChecked
        }
    }
    throw IllegalArgumentException("candidate command missing: ${commandId}")
}

// Command-menu regression: a self-drawn presentation layer is opened and its
// existing toggle action is re-entered through the same stable command table
// used by the application menu/shortcut bridge. The real rule owner remains
// the only state writer, and a later owner mutation still refreshes normally.
@Test
func commandMenuRouteKeepsRuleOwnerAndLayerInSync(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Command menu", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        // The beacon toggle's one live control is the menu item, so the
        // command joins the table with the menu layer itself.
        @Assert(window.invokeCommand("rule-set.open-presentation-menu"), true)
        @Assert(pumpNextScene(host, window), true)
        @Assert(ruleSetProjectionNode(window.windowProjection(), "rule-set-menu").nodeId > 0, true)
        @Assert(ruleSetCommandChecked(controller, "rule-set.toggle-beacon"), false)
        @Assert(window.invokeCommand("rule-set.toggle-beacon"), true)
        @Assert(ruleSetCommandChecked(controller, "rule-set.toggle-beacon"), true)
        @Assert(domain.snapshot().version, 0)
        let external = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "命令菜单回归", true, 7, "cache", "command-menu"))
        @Assert(external.applied, true)
        @Assert(pumpNextScene(host, window), true)
        @Assert(window.windowProjection().pendingRefreshReason, "none")
    } finally {
        window.close()
    }
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("First create probe", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        let before = window.windowProjection()
        let initialScene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(),
            CjguiComposableUiRect(0, 0, 980, 620), 1)
        let create = initialScene.nodeForId(10)
        @Assert(create.nodeId, 10)
        let dispatched = controller.applyUiEvent(CjguiComposableUiEvent(create, 27, "", 0, 0, initialScene.version))
        @Assert(dispatched.didApply, true)
        @Assert(domain.collectionRangeSnapshot().totalCount, 1)
        @Assert(pumpNextScene(host, window), true)
        assertRuleSetProjectionIdentity(window.windowProjection())
        let createdId = domain.collectionRangeSnapshot().selectedResourceId
        assertRuleCardProjection(window.windowProjection(), createdId)
        let cardMenu = cjguiComposableButton(117000, "rule-card-menu-${createdId}", "操作", "OPEN_RULE_CARD_MENU",
            createdId, CjguiComposableUiStyle(fixedHeight: 26))
        let cardMenuEvent = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(cardMenu, CjguiComposableUiRect(0, 0, 80, 26),
                    CjguiComposableUiRect(0, 0, 80, 26)), 27, "", 0, 0, 1))
        @Assert(cardMenuEvent.didApply, true)
        @Assert(pumpNextScene(host, window), true)
        @Assert(ruleSetProjectionNode(window.windowProjection(), "rule-card-menu-${createdId}").nodeId > 0, true)
        let cardEdit = cjguiComposableButton(117001, "rule-card-edit-${createdId}", "编辑", "OPEN_RULE_CARD_EDIT",
            createdId, CjguiComposableUiStyle(fixedHeight: 26))
        let cardEditEvent = controller.applyUiEvent(
            CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(cardEdit, CjguiComposableUiRect(0, 0, 80, 26),
                    CjguiComposableUiRect(0, 0, 80, 26)), 27, "", 0, 0, 1))
        @Assert(cardEditEvent.didApply, true)
        @Assert(pumpNextScene(host, window), true)
        @Assert(ruleSetProjectionNode(window.windowProjection(), "rule-card-edit-dialog-${createdId}").nodeId > 0,
            true)
        let after = window.windowProjection()
        @Assert(after.acceptedSceneVersion > before.acceptedSceneVersion, true)
        @Assert(after.pendingRefreshReason, "none")
    } finally {
        window.close()
    }
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Transfer cost", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
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
        @Assert(pumpNextScene(host, window), true)
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
        @Assert(pumpNextScene(host, window), true)
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
    } finally {
        window.close()
    }
}

// The public shared-operation route may add a run of records while the
// window remains open. Each accepted owner version must reach the same list
// projection as a local action; a stale scene is not an acceptable fallback.
@Test
func externalRuleFixtureProjectsEveryVisibleListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("External list refresh", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        var index: Int64 = 1
        while (index <= 16) {
            let created = domain.executeFromExternal(
                CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "外部滚动验证规则 ${index}", true, 7,
                    "cache", "external-scroll-${index}"))
            @Assert(created.applied, true)
            @Assert(pumpNextScene(host, window), true)
            let progress = window.windowProjection()
            @Assert(progress.pendingRefreshReason, "none")
            @Assert(progress.lastNativeFailure, "none")
            index += 1
        }
        @Assert(domain.collectionRangeSnapshot().totalCount, 16)
        assertRuleSetProjectionIdentity(window.windowProjection())
    } finally {
        window.close()
    }
}

// The normal host drains multiple already-accepted external actions in one
// turn, then requests one projection refresh. Keep that coalesced path
// distinct from the per-action case above: virtual-list materialization must
// converge from one visible row to a populated viewport in a single commit.
@Test
func batchedExternalRuleFixtureProjectsCoalescedListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Batched list refresh", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        var index: Int64 = 1
        while (index <= 16) {
            let created = domain.executeFromExternal(
                CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "批量滚动验证规则 ${index}", true, 7,
                    "cache", "batched-scroll-${index}"))
            @Assert(created.applied, true)
            if (index == 1) {
                @Assert(pumpNextScene(host, window), true)
            }
            index += 1
        }
        @Assert(domain.collectionRangeSnapshot().totalCount, 16)
        @Assert(pumpNextScene(host, window), true)
        let progress = window.windowProjection()
        @Assert(progress.pendingRefreshReason, "none")
        @Assert(progress.lastNativeFailure, "none")
        assertRuleSetProjectionIdentity(progress)
    } finally {
        window.close()
    }
}

// A local first create leaves controller-local presentation revision state;
// subsequent externally authored records are still coalesced by the normal
// host. This is the exact mixed-owner sequence exercised by a real button
// followed by a public fixture load.
@Test
func localFirstCreateThenBatchedExternalFixtureProjectsListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Mixed list refresh", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        let initialScene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(),
            CjguiComposableUiRect(0, 0, 980, 620), 1)
        let localCreated = controller.applyUiEvent(
            CjguiComposableUiEvent(initialScene.nodeForId(10), 27, "", 0, 0, initialScene.version))
        @Assert(localCreated.didApply, true)
        @Assert(pumpNextScene(host, window), true)
        var index: Int64 = 2
        while (index <= 16) {
            let created = domain.executeFromExternal(
                CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "混合滚动验证规则 ${index}", true, 7,
                    "cache", "mixed-scroll-${index}"))
            @Assert(created.applied, true)
            index += 1
        }
        @Assert(domain.collectionRangeSnapshot().totalCount, 16)
        @Assert(pumpNextScene(host, window), true)
        let progress = window.windowProjection()
        @Assert(progress.pendingRefreshReason, "none")
        @Assert(progress.lastNativeFailure, "none")
        assertRuleSetProjectionIdentity(progress)
    } finally {
        window.close()
    }
}

private func seedRuleSetTableRows(domain: CjguiRuleSetEditingDomain, rows: Int64): Bool {
    let names = ["重复规则", "登录审计", "临时文件清理", "长期归档", "重复规则"]
    let retentions: Array<Int64> = [2, 10, 100, 7, 30]
    let excludedTypes = ["cache", "temp", "log", "cache", "temp"]
    var index: Int64 = 0
    while (index < rows) {
        let ordinal = index + 1
        // Every fifth row repeats an existing name; the rest stay distinguishable.
        // Numeric sorting must therefore handle equal leaves and 2 < 10 < 100.
        let label = if (ordinal % 5 == 0) {
            names[index % names.size]
        } else {
            "${names[index % names.size]} ${ordinal}"
        }
        let result = domain.createRecordFromHuman(label, ordinal % 4 != 0,
            retentions[index % retentions.size], excludedTypes[index % excludedTypes.size],
            "table-seed-${ordinal}")
        if (!result.applied) {
            return false
        }
        index += 1
    }
    return true
}

/// Consume one standard-Quit intent through the window's public seam and route
/// it to the SAME business close decision a title-bar close uses. A document
/// with unsaved content refuses; the intent is already acknowledged so a later
/// save/discard leaves Quit available.
private func consumeRuleSetExitRequest(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow): Bool {
    if (!window.consumeApplicationExitRequest()) {
        return false
    }
    let accepted = host.requestClose()
    if (!accepted) { window.requestRefresh() }
    getStdOut().writeln("CJGUI_RULE_SET_EXIT_REQUESTED accepted=${accepted}")
    getStdOut().flush()
    return accepted
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
    if (startup.seedTableRows > 0 && !seedRuleSetTableRows(domain, startup.seedTableRows)) {
        getStdErr().writeln("rule set: cannot seed table rows through the owner");
        CjguiMacosApplicationHost.stopApplicationLoop();
        return 2
    }
    let preferencePath = if (startup.viewPreferencesPath.size > 0) {
        startup.viewPreferencesPath
    } else if (startup.openPath.size > 0) {
        "${startup.openPath}.cjgui-views"
    } else if (startup.saveAsPath.size > 0) {
        "${startup.saveAsPath}.cjgui-views"
    } else {
        ""
    }
    let controller = CjguiRuleSetComposableController(domain,
        presetOverride: startup.retentionPreset, viewPreferencesPath: preferencePath,
        uiDocument: startup.uiDocumentPath)
    if (startup.performanceScene && !seedRuleSetPerformanceScene(controller.generatedUiRegion())) {
        getStdErr().writeln("rule set: performance scene declaration rejected")
        CjguiMacosApplicationHost.stopApplicationLoop()
        return 2
    }
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
    // The searchable-record panel is an ordinary modal over this window; it
    // needs the accepted window to finish layer return/focus restoration.
    controller.bindWindow(window)
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableTargetedContextReads(domain) || !connection.enableWindowProgressReads(window) ||
        !connection.enableGeneratedUiProvider(controller.generatedUiRegion()) ||
        !connection.enableTreeSelectionProvider(controller.treeSelectionProvider()) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close();
        return 1
    }
    let costObservation = RuleSetCostObservation(window, domain, startup.observeCosts)
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
    // A window start may report a pending first frame; the ordinary scheduler
    // finishes that submission on later owner turns. Readiness is therefore
    // observed through the normal event-driven turn loop, not assumed from
    // start() or a fixed count of nonblocking turns.
    var readinessTurns: Int64 = 0
    while (host.isOpen() && window.windowProjection().submittedFrameIndex <= 0 &&
        window.windowProjection().lastNativeFailure == "none") {
        // Preparing and a retained native ticket are both live startup states.
        // Let the normal work revision wake the owner instead of exhausting a
        // fixed number of nonblocking turns before the first scene can settle.
        let _ = host.pumpUntilWork()
        let _ = consumeRuleSetExitRequest(host, window)
        if (controller.takePendingCloseRequest() && host.isOpen()) { let _ = host.requestClose() }
        if (host.isOpen()) {
            controller.finishPanelAction(window)
            controller.finishUiDocumentAction(window)
        }
        readinessTurns += 1
    }
    if (!host.isOpen()) { return 0 }
    let startupProjection = window.windowProjection()
    if (!startupProjection.isActive || startupProjection.sessionIdentity.size == 0 ||
        startupProjection.submittedFrameIndex <= 0) {
        getStdOut().writeln("CJGUI_RULE_SET_READY NOT_READY active=${startupProjection.isActive} " +
            "session=${startupProjection.sessionIdentity.size} submitted=${startupProjection.submittedFrameIndex} " +
            "failure=${startupProjection.lastNativeFailure} turns=${readinessTurns}")
        getStdOut().flush()
        host.close()
        return 1
    }
    // A saved interface document starts through the ordinary provider only
    // after the first frame is ready: the current catalog re-validates every
    // declaration, and a refusal leaves the default interface running.
    if (startup.uiDocumentPath.size > 0 && host.isOpen()) {
        if (!exists(Path(startup.uiDocumentPath))) {
            getStdOut().writeln("CJGUI_RULE_SET_UI_DOCUMENT_SAVE_TARGET path=${startup.uiDocumentPath}")
            getStdOut().flush()
        } else {
            let submitted = controller.beginStartupUiDocument(startup.uiDocumentPath)
            if (!submitted.applied) {
                getStdErr().writeln("CJGUI_RULE_SET_UI_DOCUMENT_REJECTED reason=${submitted.reason}")
                getStdErr().flush()
            } else if (submitted.submitted) {
                var documentTurns: Int64 = 0
                while (host.isOpen() && controller.hasPendingStartupDocument() &&
                    window.windowProjection().lastNativeFailure == "none") {
                    let _ = host.pumpUntilWork()
                    let _ = consumeRuleSetExitRequest(host, window)
                    if (controller.takePendingCloseRequest() && host.isOpen()) { let _ = host.requestClose() }
                    if (host.isOpen()) {
                        controller.finishPanelAction(window)
                        documentTurns += 1
                        let _ = controller.settleStartupDocument(waitTurns: documentTurns)
                    }
                }
                if (controller.hasPendingStartupDocument()) {
                    getStdOut().writeln("CJGUI_RULE_SET_UI_DOCUMENT_PENDING " + "turns=${documentTurns}")
                    getStdOut().flush()
                }
            }
        }
    }
    // No explicit document baseline was accepted: seed ONE non-empty generated
    // detail from the real records through the public candidate path. A legal
    // empty document above is a loaded baseline and is left exactly as empty.
    if (host.isOpen() && !controller.uiDocumentLoaded() && !controller.hasPendingStartupDocument()) {
        let seeded = controller.ensureDefaultGeneratedDetail()
        if (seeded.size > 0) {
            getStdOut().writeln("CJGUI_RULE_SET_GENERATED_SEED ${seeded} " +
                "records=${domain.snapshot().records.size}")
            getStdOut().flush()
            var seedTurns: Int64 = 0
            let region = controller.generatedUiRegion()
            let seedToken = if (seeded.startsWith("submitted:")) { Int64.parse(seeded[10..seeded.size]) } else { 0 }
            while (host.isOpen() && seedToken > 0 &&
                region.uiDocumentTicket(seedToken).terminalState == "PENDING" &&
                window.windowProjection().lastNativeFailure == "none") {
                let _ = host.pumpUntilWork()
                let _ = consumeRuleSetExitRequest(host, window)
                if (controller.takePendingCloseRequest() && host.isOpen()) { let _ = host.requestClose() }
                if (host.isOpen()) {
                    controller.finishPanelAction(window)
                    controller.finishUiDocumentAction(window)
                    seedTurns += 1
                }
            }
            // Preserve this exact candidate's real terminal or pending state.
            let seedTerminal = if (seedToken > 0) { region.uiDocumentTicket(seedToken).terminalState } else { "NOT_SUBMITTED" }
            getStdOut().writeln("CJGUI_RULE_SET_GENERATED_SEED_STATE " +
                "token=${seedToken} terminal=${seedTerminal} accepted=${region.acceptedStructureVersion()} " +
                "candidate=${region.candidateStructureVersion()} " +
                "scene=${region.sceneState()} records=${domain.snapshot().records.size} " +
                "turns=${seedTurns}")
            getStdOut().flush()
        }
    }
    if (host.isOpen() && window.windowProjection().lastNativeFailure != "none") {
        getStdErr().writeln("CJGUI_RULE_SET_STARTUP_FAILED reason=${window.windowProjection().lastNativeFailure}")
        getStdErr().flush()
        host.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_RULE_SET_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_RULE_SET_READY PROTOCOL ${info.protocol}")
        output.writeln("CJGUI_RULE_SET_READY VIEW_PREFERENCES ${controller.viewPreferencesPath()}")
        output.writeln("CJGUI_RULE_SET_READY VIEW_ACTIVE ${controller.viewPreferencesStore().activeName()}")
        output.flush()
        let projection = window.windowProjection()
        if (!projection.isActive || projection.sessionIdentity.size == 0 || projection.submittedFrameIndex <= 0) {
            output.writeln("CJGUI_RULE_SET_READY NOT_READY active=${projection.isActive} " +
                "session=${projection.sessionIdentity.size} submitted=${projection.submittedFrameIndex} " +
                "failure=${projection.lastNativeFailure} turns=${readinessTurns}")
            output.flush();
            host.close();
            return 1
        }
        output.writeln(
            "CJGUI_RULE_SET_READY WINDOW_READY ${projection.sessionIdentity} ${projection.submittedFrameIndex}")
        output.flush()
    }
    costObservation.sample("ready")
    let warmupStarted = MonoTime.now()
    while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < startup.measurementWarmupMs) {
        let remaining = max(1, startup.measurementWarmupMs - (MonoTime.now() - warmupStarted).toMilliseconds())
        let _ = host.pumpUntilWork(timeoutMs: UInt32(remaining))
        let _ = consumeRuleSetExitRequest(host, window)
        if (host.isOpen()) {
            controller.finishPanelAction(window)
            controller.finishUiDocumentAction(window)
            if (!controller.uiDocumentLoaded() && !controller.hasPendingStartupDocument()) {
                let seeded = controller.ensureDefaultGeneratedDetail()
                if (seeded.size > 0) {
                    getStdOut().writeln("CJGUI_RULE_SET_GENERATED_SEED ${seeded}")
                    getStdOut().flush()
                }
            }
        }
        costObservation.poll()
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
        let remaining = if (startup.measurementDurationMs <= 0) { UInt32.Max } else {
            UInt32(max(1, startup.measurementDurationMs - (MonoTime.now() - measurementStarted).toMilliseconds()))
        }
        let _ = host.pumpUntilWork(timeoutMs: remaining)
        let _ = consumeRuleSetExitRequest(host, window)
        if (controller.takePendingCloseRequest() && host.isOpen()) {
            let _ = host.requestClose()
        }
        if (host.isOpen()) {
            controller.finishPanelAction(window)
            controller.finishUiDocumentAction(window)
            if (!controller.uiDocumentLoaded() && !controller.hasPendingStartupDocument()) {
                let seeded = controller.ensureDefaultGeneratedDetail()
                if (seeded.size > 0) {
                    getStdOut().writeln("CJGUI_RULE_SET_GENERATED_SEED ${seeded}")
                    getStdOut().flush()
                }
            }
        }
        costObservation.poll()
    }
    getStdOut().writeln("CJGUI_RULE_TRANSFER_METRICS ${controller.transferMetricsSummary()}")
    getStdOut().flush()
    costObservation.finish()
    host.close();
    return 0
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--check-performance-declarations") {
        let domain = CjguiRuleSetEditingDomain.newUntitled()
        let created = domain.createRecordFromHuman("规则", true, 9, "cache", "declaration-check")
        let region = CjguiRuleSetGeneratedRegion(domain)
        let ok = created.applied && seedRuleSetPerformanceScene(region) &&
            !CjguiGeneratedUiPresentation.isPropertyImplemented(CJGUI_GENERATED_PRESENTATION_IMAGE,
                "textOverflow", "STRING")
        println("RULE_SET_PERFORMANCE_DECLARATIONS accepted=${ok}")
        return if (ok) { 0 } else { 1 }
    }
    if (args.size == 1 && args[0] == "--verify-transfer-cost") {
        return Int64(runTransferCostProbe())
    }
    if (let Some(startup) <- parseStartupFiles(args)) {
        return Int64(runRuleSetApp(startup))
    }
    getStdErr().writeln(
        "usage: CJGUIRuleSet [--open PATH] [--save-as PATH] [--view-preferences PATH] [--verify-host-close-decisions] [--retention-range MIN MAX] [--retention-preset VALUE] [--seed-table-rows 1..2000] [--performance-scene] [--observe-costs] [--measurement-warmup-ms 0..60000] [--measurement-duration-ms 1..900000]")
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Tree navigation", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        createNavigationTestRule(domain, "导航甲", true, "nav-1")
        createNavigationTestRule(domain, "导航乙", false, "nav-2")
        createNavigationTestRule(domain, "导航丙", false, "nav-3")
        let panel = controller.treeSelectionProvider()
        // Expand both groups through the same shared entry a human click reaches.
        let _ = panel.applySelection("expand", "group-enabled", panel.selectionVersion())
        let _ = panel.applySelection("expand", "group-disabled", panel.selectionVersion())
        @Assert(pumpNextScene(host, window), true)
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
        @Assert(pumpNextScene(host, window), true)
        let after = window.windowProjection()
        @Assert(after.pendingRefreshReason, "none")
        @Assert(after.lastNativeFailure, "none")
        @Assert(after.acceptedSceneVersion >= before.acceptedSceneVersion, true)
    } finally {
        window.close()
    }
}

@Test
func treeNavigationIsRejectedOutsideItsListNode(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Tree scope rejection", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
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
    } finally {
        window.close()
    }
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Generated window transaction", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        let region = controller.generatedUiRegion()

        // S1: candidate received, then scene-accepted by the window transaction.
        @Assert(region.submitStructure(GENERATED_WINDOW_S1, 0).candidateAccepted, true)
        @Assert(region.acceptedStructureVersion(), 0)
        @Assert(pumpNextScene(host, window), true)
        @Assert(region.acceptedStructureVersion(), 1)
        let nodeIdS1 = region.acceptedNodeIdForKey("nameField")
        @Assert(nodeIdS1 > 0, true)

        // S2 re-orders the same key: the accepted identity must survive.
        @Assert(region.submitStructure(GENERATED_WINDOW_S2, 1).candidateAccepted, true)
        @Assert(pumpNextScene(host, window), true)
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
        @Assert(pumpNextScene(host, window), true)
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
        @Assert(pumpNextScene(host, window), true)
        @Assert(region.acceptedStructureVersion(), 4)
        @Assert(region.acceptedNodeIdForKey("nameFieldRenamed"), -1)
        let renamedEditor = generatedEditorNode(renamedId, recordId)
        @Assert(region.handleEvent(CjguiComposableUiEvent(renamedEditor, 28, "不应写入2", 0, 0, 4)).didApply, false)
    } finally {
        window.close()
    }
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Generated editor reorder", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        let region = controller.generatedUiRegion()

        @Assert(region.submitStructure(EDITOR_STATE_S1, 0).candidateAccepted, true)
        @Assert(pumpNextScene(host, window), true)
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
        @Assert(pumpNextScene(host, window), true)
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
    } finally {
        window.close()
    }
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Generated integer editor", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        @Assert(pumpSceneAccepted(host, window), true)
        let region = controller.generatedUiRegion()
        @Assert(region.submitStructure(TRANSIENT_STRUCTURE, 0).candidateAccepted, true)
        @Assert(pumpNextScene(host, window), true)
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
    } finally {
        window.close()
    }
}

/// The external field query must expose every field of the application's single
/// shared form definition - not a subset. A missing field here would make the
/// generated capability payload look complete while an external caller silently
/// loses a business field (the window's own "enabled" projection is the case
/// that exposed it). The payload is per-owner, so the fixture creates the
/// record the external reader addresses instead of asking an empty selection.
@Test
func generatedRegionPublishesEveryBindingField(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("字段发布", true, 7, "cache", "binding-fields").applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let payload = controller.generatedUiRegion().fieldsPayload()
    for (fieldId in ["label", "enabled", "retentionCount", "excludedType", "notes"]) {
        @Assert(payload.contains("FIELD ${fieldId} "), true)
    }
    @Assert(payload.contains("FIELD notes 81005 DRAFT_HEX "), true)
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
    // The new notes field is published from the SAME binding: its declared
    // maximum is the one business constant, not a second copy in the window.
    @Assert(payload.contains("FIELD notes TEXT resource=81005 writer=EDIT_DRAFT_TEXT"), true)
    @Assert(payload.contains("maxlen=${CjguiRuleSetEditingDomain.defaultNotesMaximumLength}"), true)
    println("NOTES_CAPABILITY declared=${CjguiRuleSetEditingDomain.defaultNotesMaximumLength}")
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Composite shape", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
    @Assert(pumpSceneAccepted(host, window), true)

    // Generated side: the app's generated region accepts the composite kind and
    // resolves its field + preset elements.
    let region = controller.generatedUiRegion()
    @Assert(region.submitStructure(RETENTION_COMPOSITE_S1, 0).candidateAccepted, true)
    if (!pumpNextScene(host, window)) {
        throw IllegalArgumentException("retention composite refresh failed: " +
            window.windowProjection().lastNativeFailure + " / " + region.sceneState())
    }
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
    let retentionDescriptor = domain.formBinding().fieldAtControlIndex(
        domain.formBinding().controlIndexForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId))
    let directBinding = CjguiNumericStepperBinding(1, "direct-row", 2, 3, 4, "direct-input", 5,
        "direct-step-down", 6, "direct-step-up", descriptorLabel, field.draftText,
        retentionDescriptor.minimum, retentionDescriptor.maximum, 1, "retentionCount", "EDIT_DRAFT_TEXT",
        CjguiRuleSetEditingDomain.formRetentionResourceId, recordId,
        CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION,
        CjguiRetentionIntegerEditComposite.STEP_UP_ACTION)
    let directPreset = CjguiNumericStepperPreset("primary", 7, region.retentionPreset().label,
        region.retentionPreset().value, actionName: CjguiRetentionIntegerEditComposite.PRESET_ACTION,
        writerOperation: "EDIT_DRAFT_TEXT",
        bindingResourceId: CjguiRuleSetEditingDomain.formRetentionResourceId,
        ownerTargetResourceId: recordId)
    let directBuild = CjguiRetentionIntegerEditComposite.buildEditor(directBinding,
        ArrayList<CjguiNumericStepperPreset>([directPreset]),
        CjguiNumericStepperStyle(input: CjguiComposableUiStyle(fixedHeight: 26, growX: 1)))
    let directShape = ArrayList<String>()
    compositeShapeOf(directBuild, directShape)
    @Assert(handwrittenShape.size, directShape.size)
    var index: Int64 = 0
    while (index < handwrittenShape.size) {
        @Assert(handwrittenShape[index], directShape[index])
        index += 1
    }
    // The shape really is input + step buttons + preset, not a plain editor.
    var sawInput = false
    var sawPreset = false
    for (shape in handwrittenShape) {
        if (shape.contains("|retentionCount|EDIT_DRAFT_TEXT|")) { sawInput = true }
        if (shape.contains("|${CjguiRetentionIntegerEditComposite.PRESET_ACTION}")) { sawPreset = true }
    }
    @Assert(sawInput, true)
    @Assert(sawPreset, true)
    } finally {
        window.close()
    }
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Composite preset", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
    @Assert(pumpSceneAccepted(host, window), true)
    let region = controller.generatedUiRegion()
    @Assert(region.submitStructure(RETENTION_COMPOSITE_S1, 0).candidateAccepted, true)
    @Assert(pumpNextScene(host, window), true)
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
    } finally {
        window.close()
    }

    // Negative control: the same composite with an explicitly out-of-range preset
    // must hand 200 to the owner (no clamping here) and the owner refuses it.
    // It is accepted through the region's own public scene transaction rather
    // than a second native window: one test process may own only one native
    // window lifetime (a second sequential native window crashes the renderer
    // bridge), and this control needs the accepted generated binding, not a
    // native drawable.
    let outOfRangeDomain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(outOfRangeDomain.createRecordFromHuman("越界预设", true, 30, "x", "composite-preset-oor").applied, true)
    let outOfRangeRecord = outOfRangeDomain.selectedRecordId()
    let outOfRangeRegion = CjguiRuleSetGeneratedRegion(outOfRangeDomain, presetOverride: "200")
    @Assert(outOfRangeRegion.retentionPreset().value, "200")
    let outOfRangeController = CjguiRuleSetComposableController(outOfRangeDomain, presetOverride: "200")
    let outOfRangeLive = outOfRangeController.generatedUiRegion()
    @Assert(outOfRangeLive.submitStructure(RETENTION_COMPOSITE_S1, 0).candidateAccepted, true)
    @Assert(outOfRangeLive.beginSceneRefresh(), true)
    let _ = outOfRangeLive.buildSection(CjguiComposableUiTheme.paperLight(), CjguiComposableUiStyle())
    @Assert(outOfRangeLive.prepareSceneRefresh(), true)
    outOfRangeLive.commitSceneRefresh()
    @Assert(outOfRangeLive.acceptedStructureVersion(), 1)
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
}

/// The handwritten preset button goes through the same owner draft entry the
/// typed edit uses, reading the same one configuration.
@Test
func handwrittenCompositePresetWritesTheOwnerDraft(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("手写预设", true, 30, "hand", "composite-hand-preset").applied, true)
    let recordId = domain.selectedRecordId()
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Handwritten preset", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
    @Assert(pumpSceneAccepted(host, window), true)
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
    } finally {
        window.close()
    }
}

private func ruleUiDocumentHasContent(text: String): Bool {
    for (line in text.split("\n")) {
        // Definitions are content too: a file that declares compositions but no
        // nodes must reach the real candidate protocol (and its named refusal),
        // not be re-labelled as an accepted empty surface.
        if (line.startsWith("NODE ") || line.startsWith("COMPOSITION ")) {
            return true
        }
    }
    return false
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
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Composite gap", 980u32, 620u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
    @Assert(pumpSceneAccepted(host, window), true)
    let region = controller.generatedUiRegion()

    let declared = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 retentionEdit retentionIntegerEdit
PROPERTY 1 retentionEdit gap 12
PROPERTY 1 retentionEdit presetLabel 间距预设
END"""
    @Assert(region.submitStructure(declared, 0).candidateAccepted, true)
    @Assert(pumpNextScene(host, window), true)
    let section = region.buildSection(CjguiComposableUiTheme.paperLight(), CjguiComposableUiStyle())
    let rowId = region.acceptedCompositeElementNodeId("retentionEdit", "root")
    @Assert(rowId > 0, true)
    let row = findNodeById(section, rowId) ??
        cjguiComposableVertical(-1, "missing-composite-row", CjguiComposableUiStyle())
    @Assert(row.nodeId, rowId)
    @Assert(row.style.gap, 12)
    } finally {
        window.close()
    }
}

// --- list filtering + second field/layout combination ---------------------

private func filterLayoutCreateRule(domain: CjguiRuleSetEditingDomain, label: String, enabled: Bool,
    requestId: String): Unit {
    let result = domain.executeFromExternal(cjguiRuleSetInvocationForFilterTest(domain, label, enabled, requestId))
    if (!result.applied) {
        throw IllegalArgumentException("filter test rule create failed: ${result.reason}")
    }
}

private func cjguiRuleSetInvocationForFilterTest(domain: CjguiRuleSetEditingDomain, label: String, enabled: Bool,
    requestId: String): CjguiSharedOperationActionInvocation {
    return CjguiRuleSetInvocationFactory.create(domain.snapshot().version, label, enabled, 7, "cache", requestId)
}

private func ruleSetScene(controller: CjguiRuleSetComposableController,
    version: Int64): CjguiComposableUiScene {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, 980, 620)
    // Resolve the same candidate identities a window resolves so the virtual
    // list materializes its visible range; this is still a pure headless scene,
    // not a native window.
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    return scene
}

private func sceneHasSemantic(scene: CjguiComposableUiScene, semanticId: String): Bool {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return true
        }
    }
    return false
}

/// Filtering is a projection over the EXISTING virtual range: visible rows are
/// chosen by business record id, an off-filter record does not become a row,
/// keyboard navigation walks only visible records, and the detail selection is
/// not silently rewritten when the selected record leaves the filter.
@Test
func ruleListFilterAndKeyboardNavigationKeepStableRecordIdentity(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    filterLayoutCreateRule(domain, "Alpha 规则", true, "filter-1")
    filterLayoutCreateRule(domain, "Beta 规则", false, "filter-2")
    filterLayoutCreateRule(domain, "Alpine 规则", true, "filter-3")
    let controller = CjguiRuleSetComposableController(domain)
    var scene = ruleSetScene(controller, 1)
    let filterNode = scene.nodeForId(24)
    @Assert(filterNode.nodeId, 24)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(filterNode, 28, "alp", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = ruleSetScene(controller, 2)
    @Assert(sceneHasSemantic(scene, "rule-row-1"), true)
    @Assert(sceneHasSemantic(scene, "rule-row-3"), true)
    @Assert(sceneHasSemantic(scene, "rule-row-2"), false)
    // Filtering never moves the owner selection: it was record 3 and remains 3.
    @Assert(domain.selectedRecordId(), 3)
    let listNode = scene.nodeForId(21)
    @Assert(listNode.nodeId, 21)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "home", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(domain.selectedRecordId(), 1)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(listNode, 35, "down", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    // "down" lands on the SECOND VISIBLE record (3), never on the filtered-out
    // display position 2.
    @Assert(domain.selectedRecordId(), 3)
    // A query with no match presents ordinary empty feedback and keeps the
    // owner selection untouched.
    let filterNodeAgain = scene.nodeForId(24)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(filterNodeAgain, 28, "zzz", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = ruleSetScene(controller, 3)
    @Assert(sceneHasSemantic(scene, "empty-list"), true)
    @Assert(sceneHasSemantic(scene, "rule-row-1"), false)
    @Assert(domain.selectedRecordId(), 3)
}

/// The second detail layout really binds the same owner fields differently:
/// name+enabled side by side and retention through the declared composite. The
/// switch itself is window view state; only the explicit owner actions apply or
/// cancel the draft.
@Test
func detailLayoutSwitchKeepsDraftAndUsesTheSameOwnerActions(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    filterLayoutCreateRule(domain, "布局规则", true, "layout-1")
    let recordId = domain.selectedRecordId()
    @Assert(recordId > 0, true)
    let controller = CjguiRuleSetComposableController(domain)
    var scene = ruleSetScene(controller, 1)
    let standardEditor = scene.nodeForId(200000000 + recordId * 16)
    @Assert(standardEditor.nodeId, 200000000 + recordId * 16)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(standardEditor, 28, "布局草稿", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    let draftBefore = domain.formSnapshot()
    @Assert(draftBefore.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "布局草稿")
    let appliedLabelBefore = domain.snapshot().recordById(recordId).label
    let toggle = scene.nodeForId(36)
    @Assert(toggle.nodeId, 36)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(toggle, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    scene = ruleSetScene(controller, 2)
    @Assert(sceneHasSemantic(scene, "rule-detail-compact"), true)
    @Assert(sceneHasSemantic(scene, "rule-detail-standard"), false)
    @Assert(sceneHasSemantic(scene, "compact-field-label"), true)
    // The enabled field is the public choice family in BOTH detail layouts:
    // the Select trigger plus the radio rows of the same declared field.
    @Assert(sceneHasSemantic(scene, "rule-enabled-trigger"), true)
    @Assert(sceneHasSemantic(scene, "rule-enabled-radio-group"), true)
    // The switch neither submitted nor discarded the draft.
    let draftAfterSwitch = domain.formSnapshot()
    @Assert(draftAfterSwitch.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "布局草稿")
    @Assert(draftAfterSwitch.draftVersion, draftBefore.draftVersion)
    @Assert(draftAfterSwitch.appliedConfigVersion, draftBefore.appliedConfigVersion)
    @Assert(domain.snapshot().recordById(recordId).label, appliedLabelBefore)
    // Cancel through the SAME owner action the standard layout uses.
    let cancelNode = scene.nodeForId(300000000 + recordId * 4 + 1)
    @Assert(cancelNode.nodeId, 300000000 + recordId * 4 + 1)
    @Assert(cancelNode.actionName, "CANCEL")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(cancelNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        appliedLabelBefore)
    // Edit again inside the compact layout and apply through the same entry.
    var compactEditor = scene.nodeForId(200000000 + recordId * 16)
    for (node in scene.nodes()) {
        if (node.semanticId == "compact-field-label") {
            compactEditor = node
        }
    }
    @Assert(compactEditor.semanticId, "compact-field-label")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(compactEditor, 28, "紧凑布局已应用", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    let applyNode = scene.nodeForId(300000000 + recordId * 4)
    @Assert(applyNode.actionName, "APPLY")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(applyNode, 27, "", 0, 0,
        controller.uiSceneVersion())).didApply, true)
    // Owner readback, not button colour or a log line.
    @Assert(domain.snapshot().recordById(recordId).label, "紧凑布局已应用")
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "紧凑布局已应用")
    @Assert(domain.formSnapshot().appliedConfigVersion > draftBefore.appliedConfigVersion, true)
}
