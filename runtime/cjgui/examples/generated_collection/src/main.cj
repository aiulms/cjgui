package cjgui_generated_collection

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

// Values and every write stay in the existing rule-set domain. This adapter
// only resolves its current selection to the existing common form binding.
class RuleBinding <: CjguiGeneratedUiRegionBinding {
    let domain: CjguiRuleSetEditingDomain
    init(domain: CjguiRuleSetEditingDomain) {
        this.domain = domain
    }
    func current(): CjguiGeneratedUiFormBinding {
        return CjguiGeneratedUiFormBinding(domain, domain.selectedRecordId())
    }
    public func ownerRevision(): Int64 {
        return domain.version()
    }
    public func fieldResourceId(id: String): Int64 {
        return current().fieldResourceId(id)
    }
    public func fieldOperationResourceId(id: String): Int64 {
        return current().fieldOperationResourceId(id)
    }
    public func draftText(id: String): String {
        return current().draftText(id)
    }
    public func appliedText(id: String): String {
        return current().appliedText(id)
    }
    public func draftBoolean(id: String): ?Bool {
        return current().draftBoolean(id)
    }
    public func appliedBoolean(id: String): ?Bool {
        return current().appliedBoolean(id)
    }
    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        return current().formFeedback()
    }
    public func fieldAvailability(id: String): CjguiSharedAvailability {
        return current().fieldAvailability(id)
    }
    public func actionAvailability(id: String): CjguiSharedAvailability {
        return current().actionAvailability(id)
    }
    public func actionAvailable(id: String): Bool {
        return current().actionAvailable(id)
    }
    public func executeAction(id: String, key: String): CjguiGeneratedUiActionResult {
        return current().executeAction(id, key)
    }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return current().applyFieldIntent(intent)
    }
}

class RuleRows <: CjguiComposableUiVariableHeightListSource {
    let domain: CjguiRuleSetEditingDomain
    var built: Int64 = 0
    let scope = CjguiComposableUiIdentityScope("collection-rules-list")
    init(domain: CjguiRuleSetEditingDomain) {
        this.domain = domain
    }
    public func itemCount(): Int64 {
        return domain.collectionRangeSnapshot().totalCount
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        let row = domain.collectionItemAt(index)
        if (row.resourceId < 0) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return CjguiComposableUiVariableHeightListItem("rule_${row.resourceId}", row.resourceId, row.title,
            domain.baseAppliedVersionForCollectionItem(row.resourceId), estimatedHeight: 32)
    }
    public func indexForKey(key: String): Int64 {
        // This small business projection uses the domain's stable resource IDs;
        // the common table/filter performs view ordering, never row renumbering.
        for (index in 0..itemCount()) {
            if (itemAt(index).key == key) {
                return index
            }
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        return 0
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, selected: Bool, focused: Bool): CjguiComposableUiNode {
        built += 1
        return cjguiComposableButton(-1, "rules-list-${item.key}", item.title, "SELECT_RECORD", item.resourceId,
            CjguiComposableUiStyle(fixedHeight: 32, growX: 1, padding: 6, background: if (selected || focused) {
                CjguiComposableUiColor(0.15, 0.35, 0.65, 1.0)
            } else {
                CjguiComposableUiColor(0.08, 0.10, 0.15, 1.0)
            }, textColor: CjguiComposableUiColor(0.95, 0.96, 1.0, 1.0), textMaxLines: 1, textOverflow: "ellipsis"),
            operationActionName: "SELECT_RECORD", operationResourceId: item.resourceId,
            identity: Some(scope.child(item.key).local("row")))
    }
}

class CollectionController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiSliderCaptureProvider {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let binding: RuleBinding
    let rows: RuleRows
    let collection: CjguiGeneratedUiCollection
    let region: CjguiGeneratedUiWindowRegion
    let catalog: CjguiGeneratedUiCapabilityCatalog
    var revision: Int64 = 0
    private var inspectorRequested: Bool = false
    private var editHelpVisible: Bool = false
    private var editHelpReturn: CjguiComposableUiNodeReference = CjguiComposableUiNodeReference.manual(41)
    private var navigationNotice: String = ""
    var window: ?CjguiComposableUiWindow = None
    private var observingCosts: Bool = false
    private var originalWorkload: Bool = false
    private var originalTiming: Bool = false
    private var costSampleCount: Int64 = 0
    private var sliderTraceCount: Int64 = 0

    // Opt-in, bounded scalar observations on external requests. This uses the
    // existing diagnostics; it adds neither a timer nor a diagnostic protocol.
    func beginCostObservation(): Unit {
        if (let Some(value) <- window) {
            let settings = value.diagnosticCollectionSettings()
            originalWorkload = settings[0]
            originalTiming = settings[1]
            let workload = value.setWorkloadDiagnostics(true)
            let timing = value.setTimingDiagnostics(true)
            observingCosts = true
            getStdOut().writeln("COLLECTION_COST_ENABLED workload=${workload} timing=${timing}")
            observeCost("initial")
        }
    }
    func observeCost(phase: String): Unit {
        if (!observingCosts || costSampleCount >= 96) { return }
        if (let Some(value) <- window) {
            // At most one node is read; all emitted values are existing scalars.
            let s = value.diagnosticSnapshot(maximumNodes: 1)
            costSampleCount += 1
            getStdOut().writeln("COLLECTION_COST sample=${costSampleCount} phase=${phase} owner=${domain.version()} status=${s.status} scene=${s.acceptedSceneVersion} submitted=${s.submittedSceneVersion} frame=${s.submittedFrameIndex} completed=${s.completedFrameIndex} failed=${s.failedFrameIndex} gpu_us=${s.gpuDurationMicros} nodes=${s.totalNodes} builds=${s.buildPassCount} layouts=${s.layoutPassCount} submissions=${s.nativeSubmissionCount} build_ns=${s.totalBuildNanoseconds} layout_ns=${s.totalLayoutNanoseconds} native_ns=${s.totalNativeStageAndSubmitNanoseconds} writes=${s.nodeWriteCount} clones=${s.nodeCloneCount} allocations=${s.nodeAllocationCount} text_preparations=${s.textLayoutPreparationCount} line_builds=${s.positionLineBuildCount} line_hits=${s.positionCacheHitCount} raster_count=${s.textRasterCount} raster_bytes=${s.textRasterBytes} raster_us=${s.textRasterMicros} upload_count=${s.textUploadCount} upload_bytes=${s.textUploadBytes} upload_us=${s.textUploadMicros} text_live=${s.textTextureLiveBytes} text_candidate_peak=${s.textCandidatePeakBytes} reusable=${s.reusableResourceBytes} effect_live=${s.effectLiveBytes} effect_cached=${s.effectCachedBytes} effect_flight=${s.effectInFlightBytes} timing_reads=${s.timingReadCount} timing_read_ns=${s.timingReadNanoseconds}")
            getStdOut().flush()
        }
    }
    func endCostObservation(): Unit {
        if (!observingCosts) { return }
        observeCost("before_close")
        observingCosts = false
        if (let Some(value) <- window) {
            let _ = value.setWorkloadDiagnostics(originalWorkload)
            let _ = value.setTimingDiagnostics(originalTiming)
            let settings = value.diagnosticCollectionSettings()
            getStdOut().writeln("COLLECTION_COST_RESTORED workload=${settings[0]} timing=${settings[1]}")
            getStdOut().flush()
        }
    }
    init() {
        for (index in 1..81) {
            let created = domain.createRecordFromHuman("规则 ${index}", true, 7, "cache", "collection-seed-${index}")
            if (!created.applied) {
                throw Exception("seed rejected: ${created.reason}")
            }
        }
        this.binding = RuleBinding(domain)
        this.rows = RuleRows(domain)
        let filtered = CjguiComposableUiFilteredListSource(rows, {item => item.title})
        let columns = [CjguiComposableUiTableColumn("name", "名称", "label", 0, "SORT_NAME", {item => item.title}, {
            a, b => if (a.title < b.title) {
                -1
            } else if (a.title > b.title) {
                1
            } else {
                0
            }
        }),
            CjguiComposableUiTableColumn("id", "ID", "recordId", 70, "SORT_ID", {item => "${item.resourceId}"},
            {a, b => a.resourceId - b.resourceId})]
        let style = CjguiComposableUiTableStyle(32, 34, 6, 13.0, "PingFang SC",
            CjguiComposableUiColor(0.08, 0.10, 0.15, 1.0), CjguiComposableUiColor(0.15, 0.35, 0.65, 1.0),
            CjguiComposableUiColor(0.13, 0.16, 0.22, 1.0), CjguiComposableUiColor(0.25, 0.30, 0.40, 1.0),
            CjguiComposableUiColor(0.95, 0.96, 1.0, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            CjguiComposableUiColor(0.70, 0.75, 0.85, 1.0), CjguiComposableUiColor(0.3, 0.6, 1.0, 1.0))
        let selection = CjguiComposableUiCollectionSelection()
        let table = CjguiComposableUiTableSource(filtered, "collection-rules-table", columns, style,
            rowAction: Some({item => CjguiComposableUiTableRowAction("SELECT_RECORD", item.resourceId)}),
            rowSelected: Some({key => selection.isSelected(key)}))
        this.collection = CjguiGeneratedUiCollection("rules", "ruleCollection", rows, table, selection)
        selection.click("rule_${domain.selectedRecordId()}", false, false, collection.order())
        this.catalog = binding.current().capabilityCatalog(maxNodes: 80)
        if (!catalog.registerComponent(cjguiGeneratedSliderComponent())) {
            throw Exception("slider registration rejected")
        }
        if (!collection.register(catalog)) {
            throw Exception("collection registration rejected")
        }
        this.region = CjguiGeneratedUiWindowRegion(catalog, binding, "generated-collection-window")
    }
    public func attach(value: CjguiComposableUiWindow): Unit {
        window = Some(value)
        region.attachWindow(value)
    }
    public func takeInspectorRequest(): Bool {
        let requested = inspectorRequested
        inspectorRequested = false
        return requested
    }
    public func uiSceneVersion(): Int64 {
        return revision + domain.version() + region.revision()
    }
    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        return if (node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER) { region.sliderCaptureVersion() }
            else { uiSceneVersion() }
    }
    public func sliderCaptureMapping(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSliderCaptureMapping {
        return region.sliderCaptureMapping(node)
    }
    public func buildUi(): CjguiComposableUiNode {
        collection.table.dataChanged(domain.version())
        let theme = CjguiComposableUiTheme.beaconDark()
        let root = cjguiComposableVertical(1, "collection-root", theme.page)
        root.add(cjguiComposableText(2, "collection-title", "公共集合 · 手写与生成", theme.heading))
        let filter = cjguiComposableHorizontal(3, "filter-row", CjguiComposableUiStyle(gap: 8))
        filter.add(cjguiComposableTextInput(4, "collection-query", "筛选", collection.table.query(), -1, theme.input))
        filter.add(cjguiComposableButton(5, "collection-sort", "名称排序", "SORT_NAME", -1, theme.primaryAction))
        filter.add(
            cjguiComposableButton(40, "collection-inspector", "开发：Inspector", "OPEN_INSPECTOR", -1,
                theme.primaryAction))
        filter.add(
            cjguiComposableButton(41, "collection-edit-help", "编辑说明 ⌘K", "OPEN_EDIT_HELP", domain.selectedRecordId(),
                theme.primaryAction))
        filter.add(
            cjguiComposableButton(42, "collection-export-unavailable", "导出（未提供）", "UNAVAILABLE", -1,
                theme.primaryAction, enabled: false))
        root.add(filter)
        let panels = cjguiComposableHorizontal(6, "collection-panels", CjguiComposableUiStyle(gap: 16, growX: 1))
        let view = cjguiComposableVertical(7, "collection-view", CjguiComposableUiStyle(growX: 1))
        if (region.acceptedStructureVersion() == 0 && region.candidateStructureVersion() == 0) {
            view.add(
                collection.buildNode(8, "manual-collection", 9, "manual-collection-content", "list",
                    CjguiComposableUiStyle(fixedHeight: 360, growX: 1)))
        } else {
            view.add(region.buildNode())
        }
        panels.add(view)
        let detail = cjguiComposableVertical(10, "collection-detail", CjguiComposableUiStyle(fixedWidth: 320, gap: 10))
        let feedback = binding.formFeedback().getOrThrow()
        let field = domain
            .formBinding()
            .fieldAtControlIndex(
                domain.formBinding().controlIndexForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId))
        detail.add(cjguiComposableText(11, "detail-title", "共同 owner 草稿", theme.heading))
        detail.add(
            cjguiComposableBoundFormField(20, "rule-label", 21, 22, field,
                feedback.snapshot.fieldForResourceId(field.resourceId), domain.selectedRecordId(), theme.input,
                cjguiComposableFormValidationStyle()))
        let enabledField = domain
            .formBinding()
            .fieldAtControlIndex(
                domain.formBinding().controlIndexForResourceId(CjguiRuleSetEditingDomain.formEnabledResourceId))
        detail.add(
            cjguiComposableBoundFormField(25, "rule-enabled", 26, 27, enabledField,
                feedback.snapshot.fieldForResourceId(enabledField.resourceId), domain.selectedRecordId(), theme.input,
                cjguiComposableFormValidationStyle()))
        detail.add(
            cjguiComposableButton(23, "rule-apply", "应用草稿", "APPLY_DRAFT", domain.selectedRecordId(),
                theme.primaryAction, enabled: feedback.actionAvailability("APPLY_DRAFT").isAvailable))
        let retention = catalog.fieldFor("retentionCount").getOrThrow()
        detail.add(cjguiComposableText(61, "manual-retention-label",
            "手写保留天数：${binding.draftText(retention.fieldId)}", theme.body))
        let slider = cjguiComposableFieldSlider(62, "manual-retention-slider", retention, binding,
            CjguiComposableUiStyle(fixedHeight: 32, growX: 1),
            appearance: CjguiComposableUiSliderAppearance.fromTheme(theme))
        slider.semanticLabel = "手写保留天数"
        detail.add(slider)
        detail.add(
            cjguiComposableText(24, "collection-state",
                "选中 ${collection.selection.focus()} / ${collection.selection.selectedCount()} 条\n查询 ${collection.table.query()} / 排序 ${collection.table.sortColumnKey()}\n草稿 ${feedback.snapshot.fieldForResourceId(field.resourceId).draftText}\n已应用 ${feedback.snapshot.fieldForResourceId(field.resourceId).appliedValue.displayText()}\n${navigationNotice}",
                theme.body))
        panels.add(detail);
        root.add(panels)
        root.add(
            cjguiComposableText(30, "collection-footer",
                "80 条真实记录 · 外部目录仅引用注册集合和展示方式 · 选择与草稿由原 owner 保留", theme.body))
        let host = cjguiComposableLayerHost(50, "collection-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        host.add(root)
        if (editHelpVisible) {
            let dialog = cjguiComposableDialogLayerWithReference(51, "collection-edit-help-dialog", "edit-help",
                "collection-host", editHelpReturn,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 210, padding: 18, gap: 12,
                    background: theme.card.background, border: theme.card.border),
                initialFocus: Some(CjguiComposableUiNodeReference.manual(54)))
            dialog.add(cjguiComposableText(52, "collection-edit-help-title", "编辑说明", theme.heading))
            dialog.add(
                cjguiComposableText(53, "collection-edit-help-body",
                    "修改先保留为草稿，点击“应用草稿”后生效。\n按 Esc 或返回按钮继续原字段的编辑。", theme.body))
            dialog.add(
                cjguiComposableButton(54, "collection-edit-help-close", "返回编辑", "CLOSE_EDIT_HELP", -1,
                    theme.primaryAction))
            host.add(dialog)
        }
        return host
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && sliderTraceCount < 48 &&
            getVariable("CJGUI_SLIDER_EVENT_TRACE").isSome()) {
            sliderTraceCount += 1
            getStdOut().writeln("SLIDER_EVENT kind=${event.eventKind} node=${event.node.nodeId} " +
                "x=${event.pointerX} scene=${event.projectionVersion} value=${event.node.value} " +
                "draft=${binding.draftText(event.node.fieldId)} intent=${event.sliderCaptureIntent.isSome()}")
            getStdOut().flush()
        }
        if (event.node.nodeId == 62) { return region.handleFieldSliderEvent(event) }
        if (event.eventKind == 31 && event.node.actionName == "SELECT_RECORD") {
            let key = "rule_${event.node.resourceId}"
            let order = collection.order()
            if (order.indexOfKey(key) >= 0) {
                let before = collection.selection.selectionVersion()
                let _ = collection.selection.moveFocus(key, false, order)
                // View focus is never a second click or a business revision.
                return CjguiComposableUiDispatchResult(before != collection.selection.selectionVersion())
            }
        }
        if (event.eventKind == 36 && editHelpVisible) {
            editHelpVisible = false
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 35 && event.node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            if (let Some(viewport) <- event.node.scrollViewport) {
                if (refEq(viewport, collection.viewport)) {
                    let navigation = cjguiNavigateGeneratedCollection(collection, event, window)
                    if (!navigation.isHandled || (!navigation.didChange && !navigation.didAcceptViewFocus)) {
                        return CjguiComposableUiDispatchResult(false)
                    }
                    navigationNotice = if (navigation.didAcceptViewFocus) {
                        "键盘定位已更新"
                    } else {
                        "选择已更新，显示目标暂不可用"
                    }
                    if (event.text != "select_all") {
                        let index = collection.table.indexForKey(navigation.focus)
                        if (index >= 0 && collection.table.itemAt(index).resourceId != domain.selectedRecordId()) {
                            let _ = domain.selectCollectionItemFromHuman(collection.table.itemAt(index).resourceId)
                        }
                    }
                    revision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
            }
        }
        let generated = region.handleEvent(event)
        if (generated.didApply) {
            return generated
        }
        if (event.node.nodeId == 4 && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED) {
            let changed = collection.table.setQuery(event.text);
            revision += 1
            return CjguiComposableUiDispatchResult(changed)
        }
        if (let Some(w) <- window) {
            let result = binding.current().handleFormEvent(event, w)
            if (result.didApply) {
                return result
            }
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (event.node.actionName == "OPEN_INSPECTOR") {
                inspectorRequested = true
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "OPEN_EDIT_HELP") {
                // No text bookmark exists before the first edit. Return to
                // the trigger unless the window has a real editing target;
                // do not invent a selection restore for the detail field.
                editHelpReturn = CjguiComposableUiNodeReference.manual(41)
                if (let Some(w) <- window) {
                    if (let Some(target) <- w.editingFocusReference()) {
                        editHelpReturn = target
                    }
                }
                editHelpVisible = true
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "CLOSE_EDIT_HELP") {
                editHelpVisible = false
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "SELECT_RECORD") {
                collection
                    .selection
                    .click("rule_${event.node.resourceId}", (event.modifierFlags & CJGUI_UI_MODIFIER_COMMAND) != 0,
                        (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0, collection.order())
                let result = domain.selectCollectionItemFromHuman(event.node.resourceId)
                revision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
            if (event.node.actionName == "SORT_NAME" || event.node.actionName == "SORT_ID") {
                let changed = collection.table.setSort(if (event.node.actionName == "SORT_ID") {
                    "id"
                } else {
                    "name"
                })
                revision += 1
                return CjguiComposableUiDispatchResult(changed)
            }
            if (event.node.actionName == "APPLY_DRAFT") {
                let result = binding.executeAction("APPLY_DRAFT", "rule-apply")
                revision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        let _ = kind;
        let _ = node
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        endCostObservation()
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool {
        return region.beginSceneRefresh()
    }
    public func prepareSceneRefresh(): Bool {
        return region.prepareSceneRefresh()
    }
    public func commitSceneRefresh(): Unit {
        region.commitSceneRefresh()
    }
    public func rollbackSceneRefresh(): Unit {
        region.rollbackSceneRefresh()
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (!editHelpVisible) {
            commands.add(CjguiComposableUiCommand("collection-edit-help", 41, CjguiComposableUiShortcut("k")))
        }
        return commands
    }
    public func disposeSceneRefreshResources(): Unit {
        region.disposeSceneRefreshResources()
    }
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--accessibility") { return runAccessibleForm() }
    if (args.size == 1 && args[0] == "--check-accessibility-whole-value") { return checkAccessibleWholeValue() }
    if (args.size == 1 && args[0] == "--check-slider-visual") { return checkSliderVisual() }
    if (args.size == 1 && args[0] == "--check-slider-generated") { return checkSliderGeneratedRegistration() }
    if (args.size == 1 && args[0] == "--check-inspector") {
        return checkInspector()
    }
    let controller = CollectionController()
    if (args.size == 1 && args[0] == "--check-slider-binding") { return checkSliderBinding(controller) }
    if (args.size == 1 && args[0] == "--check-slider-context") { return checkSliderContext(controller) }
    if (args.size == 1 && args[0] == "--check") {
        return checkCollection(controller)
    }
    if (args.size == 1 && args[0] == "--check-keyboard") {
        return checkKeyboard(controller)
    }
    let observeCosts = args.size == 1 && args[0] == "--observe-costs"
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let opened = application.openWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            if (observeCosts) { "公共集合 · 更新成本" } else { "公共集合 · 键盘与旁白" }, 1000u32, 640u32))
    if (!opened.didOpen) {
        getStdOut().writeln("COLLECTION_OPEN_FAILED reason=${opened.reason}")
        getStdOut().flush()
        application.close();
        return 1
    }
    let businessId = opened.identifier.getOrThrow()
    let business = application.window(businessId).getOrThrow()
    controller.attach(business)
    // One opt-in inspector on the existing application/window lifecycle.
    let inspector = CjguiMacosInspector(application, businessId)
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>()
    for (action in ["GET_CONTEXT", "GET_GENERATED_UI", "SUBMIT_GENERATED_UI"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action, ArrayList<Int64>(), true))
    }
    // Expose the registered field's existing writer to the same public client.
    // Validation, version checks and mutation stay in the original rule owner.
    let sliderField = controller.catalog.fieldFor("retentionCount").getOrThrow()
    scopes.add(CjguiSharedOperationExternalActionScope(sliderField.writeActionName, ArrayList<Int64>(), true))
    if (observeCosts) {
        scopes.add(CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true))
    }
    let authorization = CjguiSharedOperationExternalAuthorization("generated-collection-local", "collection-demo",
        scopes)
    let connection = CjguiSharedOperationExternalConnection(controller.domain, authorization, business)
    try {
        if (!connection.enableGeneratedUiProvider(controller.region) ||
            (observeCosts && !connection.enableWindowProgressReads(business)) ||
            !application.attachExternalConnection(connection)) {
            getStdOut().writeln("COLLECTION_CONNECTION_FAILED ready=${connection.connectionInfo().isSome()}")
            getStdOut().flush()
            return 2
        }
        getStdOut().writeln(
            "COLLECTION_READY DESCRIPTOR_PATH ${connection.connectionInfo().getOrThrow().descriptorPath}")
        let initialDiagnosticSettings = business.diagnosticCollectionSettings()
        getStdOut().writeln(
            "INSPECTOR_DEFAULT workload=${initialDiagnosticSettings[0]} timing=${initialDiagnosticSettings[1]}")
        getStdOut().flush()
        if (observeCosts) { controller.beginCostObservation() }
        var observedInspectorOpen = false
        while (application.isOpen()) {
            let turn = application.pumpOneTurn()
            if (observeCosts && turn.externalActionCount > 0) { controller.observeCost("request") }
            if (controller.takeInspectorRequest()) {
                let _ = inspector.open(collectCosts: true)
            }
            inspector.synchronizeLifetime()
            let inspectorOpen = inspector.isOpen()
            if (inspectorOpen != observedInspectorOpen) {
                let settings = business.diagnosticCollectionSettings()
                getStdOut().writeln(
                    "INSPECTOR_LIFETIME open=${inspectorOpen} workload=${settings[0]} timing=${settings[1]} owner_version=${controller.domain.version()}")
                getStdOut().flush()
                observedInspectorOpen = inspectorOpen
            }
        }
    } finally {
        controller.endCostObservation()
        inspector.close();
        application.close();
        connection.close()
    }
    getStdOut().writeln("COLLECTION_CLOSED endpoint=cleared");
    getStdOut().flush()
    return 0
}
