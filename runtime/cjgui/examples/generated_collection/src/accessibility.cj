package cjgui_generated_collection

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

// An ordinary opt-in form over the existing rule-set owner. Only presentation
// lives here; edits, validation, Apply and external writes use the same binding.
class AccessibleFormController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiPointerCaptureVersionProvider & CjguiComposableUiSliderCaptureProvider {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let binding: CjguiGeneratedUiFormBinding
    let catalog: CjguiGeneratedUiCapabilityCatalog
    let region: CjguiGeneratedUiWindowRegion
    let viewport = CjguiComposableUiScrollViewport()
    var window: ?CjguiComposableUiWindow = None

    init() {
        let created = domain.createRecordFromHuman("可访问规则", true, 7, "cache", "accessible-seed")
        if (!created.applied) { throw Exception(created.reason) }
        this.binding = CjguiGeneratedUiFormBinding(domain, domain.selectedRecordId())
        this.catalog = binding.capabilityCatalog(maxNodes: 60)
        if (!catalog.registerComponent(cjguiGeneratedSliderComponent())) { throw Exception("slider_registration") }
        this.region = CjguiGeneratedUiWindowRegion(catalog, binding, "accessible-form")
        let payload = "GENERATED_UI_STRUCTURE 1\nNODE 0 form vertical\nPROPERTY 0 form gap 10\n" +
            "NODE 1 heading label\nPROPERTY 1 heading text 生成表单 · 同一个业务草稿\n" +
            "NODE 1 name textInput field=label\nPROPERTY 1 name label 规则名称（生成）\n" +
            "PROPERTY 1 name fixedHeight 42\n" +
            "NODE 1 enabled booleanInput field=enabled\nPROPERTY 1 enabled label 启用规则（生成）\n" +
            "NODE 1 retention integerInput field=retentionCount\nPROPERTY 1 retention label 保留天数（生成）\n" +
            "NODE 1 limit slider field=retentionCount\nPROPERTY 1 limit step 3\n" +
            "NODE 1 excluded textInput field=excludedType\nPROPERTY 1 excluded label 排除类型（生成）\n" +
            "NODE 1 apply action action=APPLY_DRAFT\nPROPERTY 1 apply label 应用草稿（生成）\n" +
            "END"
        let submitted = region.submitStructure(payload, 0)
        if (!submitted.candidateAccepted) { throw Exception("initial_form_rejected:${submitted.reason}:${submitted.path}") }
    }
    public func attach(value: CjguiComposableUiWindow): Unit { window = Some(value); region.attachWindow(value) }
    public func uiSceneVersion(): Int64 { return domain.version() + region.revision() }
    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        return if (node.fieldId == "retentionCount") { region.sliderCaptureVersion() } else { uiSceneVersion() }
    }
    public func sliderCaptureMapping(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSliderCaptureMapping {
        return region.sliderCaptureMapping(node)
    }
    private func feedbackProjection(snapshot: CjguiSharedFormSnapshot): CjguiFormFeedbackProjection {
        return CjguiFormFeedbackProjection(snapshot, domain.formBinding(), domain.selectedRecordId(),
            policy: CjguiFormFeedbackPolicy(focusSemanticId: Some({ id =>
                if (id == "excludedType") { "accessible-excluded" } else { "accessible-${id}-editor" }
            })))
    }
    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.paperLight()
        let root = cjguiComposableVertical(10000, "accessible-page", theme.page)
        root.add(cjguiComposableText(10001, "accessible-heading", "公共表单 · 可访问交互与反馈", theme.heading))
        let scroll = cjguiComposableScrollArea(10002, "accessible-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true))
        scroll.semanticLabel = "表单内容"
        let body = cjguiComposableVertical(10003, "accessible-content", CjguiComposableUiStyle(growX: 1, gap: 10))
        let feedback = binding.formFeedback().getOrThrow()
        let snapshot = feedback.snapshot
        body.add(cjguiComposableText(10004, "accessible-manual-heading", "手写表单", theme.heading))
        var index: Int64 = 0
        for (id in ["label", "enabled", "retentionCount"]) {
            let descriptor = feedback.descriptorFor(id).getOrThrow()
            let field = feedback.fieldFor(id).getOrThrow()
            body.add(cjguiComposableBoundFormField(10020 + index * 5, "accessible-${id}",
                10021 + index * 5, 10022 + index * 5, descriptor, field, domain.selectedRecordId(),
                theme.input, cjguiComposableFormValidationStyle()))
            index += 1
        }
        body.add(cjguiComposableText(10034, "accessible-limit-label", "保留天数 · 每步 3", theme.body))
        body.add(cjguiComposableFieldSlider(10035, "accessible-limit", catalog.fieldFor("retentionCount").getOrThrow(),
            binding, CjguiComposableUiStyle(growX: 1, fixedHeight: 32), step: 3,
            appearance: CjguiComposableUiSliderAppearance.fromTheme(theme)))
        let excluded = feedback.descriptorFor("excludedType").getOrThrow()
        let excludedValue = feedback.fieldFor("excludedType").getOrThrow()
        let multiline = cjguiComposableMultilineTextInput(10040, "accessible-excluded", "排除类型（多行）",
            excludedValue.draftText, excluded.resourceId,
            CjguiComposableUiNamedStyle("editor", theme.input).localStyle(fixedHeight: Some(90), growX: Some(1)),
            fieldId: excluded.fieldId, operationActionName: "EDIT_DRAFT_TEXT",
            operationResourceId: domain.selectedRecordId(), displayValueRole: "draft")
        multiline.semanticHelp = cjguiComposableFormFieldHelp(excluded, excludedValue,
            helpText: "可输入多行，修改后应用草稿")
        body.add(multiline)
        let labelDescriptor = feedback.descriptorFor("label").getOrThrow()
        let labelValue = feedback.fieldFor("label").getOrThrow()
        body.add(cjguiComposableBoundFormField(10045, "accessible-readonly", 10046, 10047,
            labelDescriptor, labelValue, domain.selectedRecordId(), theme.input, cjguiComposableFormValidationStyle(),
            readOnly: true, editorLabel: "规则名称（只读镜像）"))
        body.add(cjguiComposableBoundFormField(10050, "accessible-disabled", 10051, 10052,
            feedback.descriptorFor("enabled").getOrThrow(), feedback.fieldFor("enabled").getOrThrow(),
            domain.selectedRecordId(), theme.input, cjguiComposableFormValidationStyle(), enabled: false,
            unavailableReason: "本页只展示这一项", editorLabel: "启用规则（禁用镜像）"))
        body.add(cjguiComposableButton(10055, "accessible-apply", "应用草稿", "APPLY_DRAFT",
            domain.selectedRecordId(), theme.primaryAction,
            enabled: binding.actionAvailability("APPLY_DRAFT").isAvailable))
        let projection = feedbackProjection(snapshot)
        body.add(cjguiComposableFormFeedbackSummary(10060, "accessible-feedback", projection, "LOCATE_FIELD"))
        body.add(region.buildNode(feedback: Some(feedback)))
        body.add(cjguiComposableText(10080, "accessible-owner", "草稿 v${snapshot.draftVersion} · owner v${domain.version()}\n" +
            "名称：${binding.draftText("label")}\n保留天数：${binding.draftText("retentionCount")}", theme.body))
        scroll.add(body); root.add(scroll)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId == 10035) { return region.handleFieldSliderEvent(event) }
        let generated = region.handleEvent(event)
        if (generated.didApply) { return generated }
        if (let Some(value) <- window) {
            let edit = binding.handleFormEvent(event, value)
            if (edit.didApply) { return edit }
            if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE && event.node.actionName == "LOCATE_FIELD") {
                let declarations = domain.formBinding()
                let index = declarations.controlIndexForResourceId(event.node.resourceId)
                if (index < 0) { return CjguiComposableUiDispatchResult(false) }
                let outcome = cjguiFocusFormFeedback(value,
                    feedbackProjection(binding.formFeedback().getOrThrow().snapshot),
                    declarations.fieldAtControlIndex(index).fieldId)
                return CjguiComposableUiDispatchResult(outcome.requestAccepted)
            }
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE && event.node.actionName == "APPLY_DRAFT") {
            return CjguiComposableUiDispatchResult(binding.executeAction("APPLY_DRAFT", "accessible-apply").applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func commitSceneRefresh(): Unit { region.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { region.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { region.disposeSceneRefreshResources() }
}

func runAccessibleForm(): Int64 {
    let controller = AccessibleFormController()
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("公共表单 · 可访问交互与反馈", 900u32, 760u32))
    let window = host.window(); controller.attach(window)
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>()
    for (action in ["GET_CONTEXT", "GET_GENERATED_UI", "GET_WINDOW_INTERACTION", "SUBMIT_GENERATED_UI",
        "EDIT_DRAFT_TEXT", "EDIT_DRAFT_BOOLEAN"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action, ArrayList<Int64>(), true))
    }
    let auth = CjguiSharedOperationExternalAuthorization("accessible-client", "accessible-local-capability", scopes)
    let connection = CjguiSharedOperationExternalConnection(controller.domain, auth, window)
    let refused = CjguiSharedOperationExternalConnection(controller.domain,
        CjguiSharedOperationExternalAuthorization("accessible-readonly", "accessible-no-generated-read",
            ArrayList<CjguiSharedOperationExternalActionScope>([
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)])), window)
    try {
        if (!connection.enableGeneratedUiProvider(controller.region) || !connection.enableWindowProgressReads(window) ||
            !refused.enableGeneratedUiProvider(controller.region) || !host.attachExternalConnection(connection) ||
            !host.adoptExternalConnectionForClose(refused) || !host.start() || !refused.start()) {
            eprintln("ACCESSIBLE_START_FAILED native=${window.windowProgress().lastNativeFailure}"); return 1
        }
        println("ACCESSIBLE_READY descriptor=${connection.connectionInfo().getOrThrow().descriptorPath} " +
            "refused=${refused.connectionInfo().getOrThrow().descriptorPath} owner=${controller.domain.selectedRecordId()}")
        getStdOut().flush()
        while (host.isOpen()) { let _ = refused.pump(0u32); let _ = host.pumpOneTurn() }
    } finally {
        host.close(); refused.close(); connection.close()
    }
    println("ACCESSIBLE_CLOSED endpoint_cleared=${connection.connectionInfo().isNone()} " +
        "refused_cleared=${refused.connectionInfo().isNone()}")
    getStdOut().flush()
    return 0
}

// Pins default-window compatibility against the real form owner. Even an
// existing range declaration cannot suppress whole-value delivery while the
// window's range-delta transport is disabled.
func checkAccessibleWholeValue(): Int64 {
    let controller = AccessibleFormController()
    let window = CjguiComposableUiWindow(controller)
    let feedback = controller.binding.formFeedback().getOrThrow()
    let descriptor = feedback.descriptorFor("label").getOrThrow()
    let node = cjguiComposableBoundFormField(10020, "accessible-label", 10021, 10022,
        descriptor, feedback.fieldFor("label").getOrThrow(), controller.domain.selectedRecordId(),
        CjguiComposableUiStyle(), cjguiComposableFormValidationStyle()).children()[0]
    let bridge = CjguiGeneratedFieldRangeSession(controller.binding, "label")
    let _ = window.bindRangeTextSession(node.nodeId, node.semanticId, bridge, bridge,
        node.resourceId, node.nodeKind)
    let bounds = CjguiComposableUiRect(0, 0, 300, 40)
    let result = controller.binding.handleFormEvent(CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(node, bounds, bounds), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED,
        "共同整值写入", 0, 0, 1), window)
    let valid = !window.isTextRangeEditDeltaDeliveryEnabled() && result.didApply &&
        controller.binding.draftText("label") == "共同整值写入"
    window.releaseTextSession(); window.close()
    if (!valid) { return 101 }
    println("ACCESSIBLE_WHOLE_VALUE_OK original_owner range_delivery_disabled bound_session_does_not_swallow")
    return 0
}
