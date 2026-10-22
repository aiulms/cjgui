package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

/// The appearance the window currently paints with. It is a plain object (not a
/// second theme registry): the handwritten area, the command surfaces and the
/// generated cards all read the SAME value on every build.
class MixedAppearance {
    var light: Bool = false
}

func mixedFormTheme(light: Bool): CjguiComposableUiTheme {
    return if (light) { CjguiComposableUiTheme.paperLight() } else { CjguiComposableUiTheme.beaconDark() }
}

class MixedFormController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiContextMenuRequestHandler & CjguiComposableUiPointerCaptureVersionProvider &
    CjguiComposableUiSliderCaptureProvider {
    private let domain: PrintPresetDomain
    private let form: CjguiGeneratedUiFormBinding
    /// Two live preset cards over the SAME field declarations; the generated
    /// area edits them through one composite kind and per-instance owners.
    public let cards: PresetCardCollection
    public let region: CjguiGeneratedUiWindowRegion
    private var window: ?CjguiComposableUiWindow = None
    private var revision: Int64 = 0
    private var collaborationRequested = false
    private var collaborationEnabled = false
    private var connectionStatus = "仅本地编辑；协作默认关闭"
    private var inspectorRequested = false
    private var helpVisible = false
    // The concrete editor the human last typed into: the modal returns HERE, so
    // the first key after closing edits the same field (not a hardcoded node).
    private var helpReturnNodeId: Int64 = 101
    private var fontFinishRequested = false
    private var helpReturn = CjguiComposableUiNodeReference.manual(101)
    private var stepNotice = ""
    private var stepKind = CJGUI_STATUS_INFO
    private let commandSurfaces: Bool
    private let fontMode: Bool
    private let fontOwner: PrintPresetFontResources
    private let styledMode: Bool
    private var fontPreviewRequested = false
    private let fontCatalog: CjguiGeneratedUiCapabilityCatalog
    private var appearance: MixedAppearance
    private let commandScope = CjguiComposableUiIdentityScope("print-preset-commands")
    private let palette = CjguiCommandPalette("print-preset-palette")
    private let contextMenu = CjguiContextCommandMenu(CjguiComposableUiIdentityScope("print-preset-context"),
        "print-preset-context-menu")
    private var contextTargetNodeId: Int64 = -1
    private let viewport = CjguiComposableUiScrollViewport()
    // The ordinary object collection over the SAME preset cards: stable keys,
    // filtered/sorted view, one selection object and a real SELECT_CARD row
    // action. It is a framework collection composite, not a second renderer.
    private let cardList: PresetCardList
    // The selected object's HANDWRITTEN detail is the app's own layout; the
    // generated composite card beside it is the second presentation of the SAME
    // owner. The toggle only chooses which presentation is shown, never which
    // object/field/draft is authoritative.
    private var detailMode: String = "handwritten"
    private var lastRevealedSelection: String = ""
    private let beacon = CjguiGeneratedUiImageResourceSpec("print-preset-beacon", "PNG", 1,
        "打印预设图标", "composable-beacon.png")

    init(domain: PrintPresetDomain, commandSurfaces!: Bool = false, fontResources!: Bool = false,
        styledText!: Bool = false, sharedFonts!: ?PrintPresetFontResources = None) {
        this.domain = domain
        this.commandSurfaces = commandSurfaces
        this.fontMode = fontResources
        this.styledMode = styledText
        this.fontOwner = sharedFonts ?? PrintPresetFontResources(fontResources)
        this.form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
        let catalog = form.capabilityCatalog(maxNodes: 64)
        // The object COLLECTION's own public vocabulary. The form catalog only
        // publishes field writers plus Apply/Cancel; these four are application
        // operations on the collection, so the application registers them (the
        // description may then place an action node and external clients may
        // invoke them by name).
        for (spec in [
            CjguiGeneratedUiActionSpec("SELECT_CARD", "选择预设卡片",
                parameterNames: ArrayList<String>(["cardKey"])),
            CjguiGeneratedUiActionSpec("ADD_CARD", "新增预设卡片",
                parameterNames: ArrayList<String>(["title"])),
            CjguiGeneratedUiActionSpec("DELETE_CARD", "删除预设卡片",
                parameterNames: ArrayList<String>(["cardKey"])),
            CjguiGeneratedUiActionSpec("SORT_CARDS", "排序预设集合",
                parameterNames: ArrayList<String>(["column"])),
            CjguiGeneratedUiActionSpec("FILTER_CARDS", "筛选预设集合",
                parameterNames: ArrayList<String>(["query"]))
        ]) {
            if (!catalog.registerAction(spec)) {
                throw Exception("print_preset_collection_action_registration: ${spec.name}")
            }
        }
        this.fontCatalog = catalog
        if (fontMode) {
            if (!catalog.registerFontResource(fontOwner.serif.getOrThrow()) ||
                !catalog.registerFontResource(fontOwner.mono.getOrThrow())) {
                let _ = fontOwner.close(); throw Exception("print_preset_font_registration")
            }
        }
        if (commandSurfaces) {
            let imageProperties = CjguiGeneratedUiPresentation.imageContentProperties()
            for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) { imageProperties.add(property) }
            if (!catalog.registerComponent(cjguiGeneratedSliderComponent()) ||
                !catalog.registerComponent(CjguiGeneratedUiComponentSpec("image", imageProperties, false)) ||
                !catalog.registerImageResource(beacon)) {
                let _ = fontOwner.close(); throw Exception("print_preset_component_registration")
            }
        }
        this.cards = domain.cards
        this.cardList = PresetCardList(domain.cards)
        // The card paints itself from the SAME appearance the handwritten area
        // uses, read at BUILD time: a theme change repaints the card on the next
        // refresh instead of freezing one theme's colours into the scene. The
        // closure captures the LOCAL object because the remaining members are
        // not initialized yet; the same object becomes the controller's member.
        let appearance = MixedAppearance()
        if (!registerPresetCardComposite(catalog, { => mixedFormTheme(appearance.light) }) ||
            !syncPresetCardNamedStyles(catalog, mixedFormTheme(appearance.light)) ||
            !cardList.register(catalog)) {
            let _ = fontOwner.close()
            throw Exception("print_preset_card_registration")
        }
        this.region = CjguiGeneratedUiWindowRegion(catalog, MixedPresetProvider(form, cards, domain),
            "print-preset-runtime")
        this.appearance = appearance
    }
    public func closeResources(): Unit {
        let first = fontOwner.close()
        if (fontMode && first) {
            let values = cjguiFontResourceDiagnostics()
            getStdOut().writeln("CJGUI_FONT_RESOURCES_CLOSED active=${values[0]} leased=${values[1]} bytes=${values[2]} snapshots=${values[3]} registrations=${values[4]}")
            getStdOut().flush()
        }
    }
    private func fontEditorStyle(theme: CjguiComposableUiTheme): CjguiComposableUiStyle {
        if (!fontMode) { return theme.input }
        return CjguiComposableUiStyle(fontFamily: fontOwner.serif.getOrThrow().fontFamily, fontSize: 17.0,
            background: theme.input.background, border: theme.input.border, borderWidth: theme.input.borderWidth,
            textColor: theme.input.textColor, padding: theme.input.padding, fixedHeight: 42, growX: 1,
            cornerRadius: theme.input.cornerRadius)
    }
    private func replacePreviewFont(): Unit {
        let next = fontOwner.replace()
        if (!fontCatalog.registerFontResource(next)) { throw Exception("print_preset_font_replacement") }
        getStdOut().writeln("CJGUI_FONT_RESOURCE key=${next.key} version=${next.version} state=${next.state} family=${next.resolvedFamily}")
        getStdOut().flush(); revision += 1
    }

    public func attachWindow(value: CjguiComposableUiWindow): Unit {
        window = Some(value)
        region.attachWindow(value)
    }
    public func uiSceneVersion(): Int64 {
        return revision + fontOwner.revision + domain.formSnapshot().contextVersion + region.revision() + palette.revision()
    }
    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        return if (node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER) { region.sliderCaptureVersion() }
            else { uiSceneVersion() }
    }
    public func sliderCaptureMapping(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSliderCaptureMapping {
        return region.sliderCaptureMapping(node)
    }
    public func requestCollaboration(): Unit {
        collaborationRequested = true
    }
    public func takeCollaborationRequest(): Bool {
        let requested = collaborationRequested;
        collaborationRequested = false
        return requested
    }
    public func takeInspectorRequest(): Bool {
        let requested = inspectorRequested
        inspectorRequested = false
        return requested
    }
    public func collaborationOpened(success: Bool): Unit {
        collaborationEnabled = success
        connectionStatus = if (success) {
            "本地协作已开启"
        } else {
            "协作连接未能开启，可再次点击"
        }
        revision += 1
    }
    public func takeFontFinishRequest(): Bool {
        let result=fontFinishRequested; fontFinishRequested=false; return result
    }
    public func takeFontPreviewRequest(): Bool {
        let requested = fontPreviewRequested
        fontPreviewRequested = false
        return requested
    }
    public func buildUi(): CjguiComposableUiNode {
        // A filter is owner state; the view reads the SAME query (no second
        // filter copy). Unchanged queries are a no-op.
        if (cardList.syncFilter()) {
            let view = cardList.viewSnapshot()
            getStdOut().writeln("PRESET_COLLECTION sort=${view[0]} query=[${view[1]}] selected=${view[2]}")
            getStdOut().flush()
        }
        // ONE owner selection projects to the view (externally selected objects
        // highlight and become the detail target too). A NEW selection is also
        // brought into the collection's visible range with the public viewport
        // reveal; ordinary rebuilds of the same selection do not move the scroll.
        let ownerSelection = domain.cards.selectedKey()
        let _ = cardList.projectOwnerSelection(ownerSelection)
        if (ownerSelection.size > 0 && ownerSelection != lastRevealedSelection) {
            let revealed = cardList.revealItem(ownerSelection)
            getStdOut().writeln("PRESET_COLLECTION_REVEAL key=${ownerSelection} applied=${revealed}")
            getStdOut().flush()
            lastRevealedSelection = ownerSelection
        }
        if (fontMode) {
            let _ = fontCatalog.registerFontResource(fontOwner.serif.getOrThrow())
            let _ = fontCatalog.registerFontResource(fontOwner.mono.getOrThrow())
        }
        let theme = currentTheme()
        // The card children reference these named styles; the CURRENT theme's
        // paint is republished here so a light/dark switch reaches the already
        // accepted structure on this refresh (no resubmit needed).
        let _ = syncPresetCardNamedStyles(fontCatalog, theme)
        let feedback = form.formFeedback().getOrThrow()
        let snapshot = feedback.snapshot
        let root = cjguiComposableVertical(1, "preset-root", theme.page)
        root.add(cjguiComposableText(2, "preset-title", "打印预设 · 混合表单", theme.heading))
        if (commandSurfaces) {
            let presentation = commandPresentation()
            palette.updateItems(presentation.placement())
            if (let Some(value) <- window) {
                if (contextMenu.isOpen()) {
                    let context = contextPresentation(contextTargetNodeId)
                    let _ = contextMenu.reconcile(value, context.commands, context.metadata)
                }
            }
            root.add(cjguiComposableCommandToolbar(commandScope, "preset-command-toolbar", presentation.placement(),
                style: CjguiCommandToolbarStyle.themed(theme), searchLabel: "操作面板 ⌘P",
                searchActionName: "OPEN_COMMANDS", searchResourceId: PrintPresetDomain.ownerId))
            root.add(cjguiComposableText(78, "preset-composition-help",
                "手写、命令与生成区共用这份打印预设。编辑草稿后应用；右键操作按钮可使用相同命令。中文与 emoji 👩🏽‍💻 的完整说明保留供读取。",
                CjguiComposableUiStyle(fontSize: 12.5, textColor: theme.body.textColor,
                    letterSpacing: 0.25, lineHeight: 18.0, textMaxLines: 2, textOverflow: "ellipsis")))
        }
        let tools = cjguiComposableWrap(72, "preset-tools", CjguiComposableUiStyle(gap: 8), rowGap: 6)
        tools.add(cjguiComposableButton(73, "preset-help", "编辑说明 ⌘K", "OPEN_HELP",
            PrintPresetDomain.ownerId, theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        tools.add(cjguiComposableButton(75, "preset-inspector", "开发：Inspector", "OPEN_INSPECTOR",
            PrintPresetDomain.ownerId, theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        // The appearance switch is its own control in BOTH modes: a normal window
        // must be able to change the theme, and the generated card has to stay
        // readable across that change (the accepted scene is not resubmitted).
        tools.add(cjguiComposableButton(76, "preset-theme", if (appearance.light) { "深色外观" } else { "浅色外观" },
            "TOGGLE_THEME", PrintPresetDomain.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        if (commandSurfaces) {
            tools.add(cjguiComposableButton(77, "preset-command-owner", "操作面板 ⌘P", "OPEN_COMMANDS",
                PrintPresetDomain.ownerId, theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        }
        if (fontMode) {
            tools.add(cjguiComposableButton(1700, "preset-font-version", "字体换版／缺失回退", "REPLACE_FONT",
                PrintPresetDomain.ownerId, CjguiComposableUiStyle(fontFamily: fontOwner.serif.getOrThrow().fontFamily,
                    fontSize: 14.0, padding: 8, fixedHeight: 38, background: theme.primaryAction.background,
                    textColor: theme.primaryAction.textColor)))
            let serif = fontOwner.serif.getOrThrow(); let mono = fontOwner.mono.getOrThrow()
            root.add(cjguiComposableText(1701, "preset-font-status",
                "${serif.key} v${serif.version} ${serif.state} ${serif.resolvedFamily} | ${mono.key} v${mono.version} ${mono.state} ${mono.resolvedFamily}",
                CjguiComposableUiStyle(fontFamily: serif.fontFamily, fontSize: 13.0, textColor: theme.body.textColor,
                    textMaxLines: 2, textOverflow: "ellipsis", lineHeight: 19.0)))
        }
        if (styledMode) {
            for ((id, label, action) in [(1710, "说明配色", "STYLED_COLOR"),
                (1711, "说明字号", "STYLED_SIZE"), (1712, "打开字体对照窗", "FONT_PREVIEW"),
                (1713, "结束字体核对", "FONT_FINISH")]) {
                tools.add(cjguiComposableButton(id, "preset-${action}", label, action,
                    PrintPresetDomain.ownerId, theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
            }
        }
        root.add(tools)
        let columns = cjguiComposableHorizontal(3, "preset-columns", CjguiComposableUiStyle(gap: 18, growX: 1))
        let manual = cjguiComposableVertical(4, "preset-manual", CjguiComposableUiStyle(gap: 10, padding: 14, growX: 1))
        manual.add(cjguiComposableText(5, "preset-manual-title", "手写区域", theme.heading))
        if (styledMode) {
            let runs = fontOwner.description.getOrThrow().runs(fontOwner)
            manual.add(cjguiComposableText(1720, "preset-styled-description", fontOwner.description.getOrThrow().text,
                CjguiComposableUiStyle(fontFamily: fontOwner.serif.getOrThrow().fontFamily, fontSize: 14.0,
                    growX: 1, textColor: theme.body.textColor, letterSpacing: 0.25), textStyleRuns: runs))
            manual.add(cjguiComposableButton(1721, "preset-description-confirm", "核对预设说明", "STYLED_CONFIRM",
                PrintPresetDomain.ownerId, theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
            manual.add(cjguiComposableText(1722, "preset-styled-limited", fontOwner.description.getOrThrow().text,
                CjguiComposableUiStyle(fontFamily: fontOwner.serif.getOrThrow().fontFamily, fontSize: 14.0,
                    growX: 1, textColor: theme.body.textColor, textMaxLines: 2, textOverflow: "ellipsis",
                    letterSpacing: 0.25), textStyleRuns: runs))
        }
        let declarations = domain.formBinding()
        for (index in 0..declarations.fieldCount()) {
            let field = declarations.fieldAtControlIndex(index)
            let value = snapshot.fieldForResourceId(field.resourceId)
            if (field.editorKind == "INTEGER") {
                // All constraints, labels and owner writers still come from
                // the one form declaration; the component owns no draft.
                let spec = form.fieldSpec(field.fieldId).getOrThrow()
                let id = 1000 + index * 10
                let numeric = CjguiNumericStepperBinding(id, "preset-${field.fieldId}-stepper", id + 1, id + 2,
                    101 + index * 10, "preset-${field.fieldId}", id + 3, "preset-${field.fieldId}-down",
                    id + 4, "preset-${field.fieldId}-up", field.label, value.draftText, field.minimum, field.maximum, 1,
                    field.fieldId, spec.writeActionName, field.resourceId, PrintPresetDomain.ownerId,
                    "PRESET_STEP_DOWN", "PRESET_STEP_UP")
                let editor = CjguiNumericStepper.build(numeric,
                    style: CjguiNumericStepperStyle(input: theme.input,
                        button: CjguiComposableUiStyle(fixedWidth: 40, fixedHeight: 40,
                            background: theme.primaryAction.background, textColor: theme.body.textColor),
                        feedback: theme.body, buttonInteraction: theme.primaryActionInteraction))
                if (!value.validationError.isEmpty()) {
                    editor.add(cjguiComposableText(102 + index * 10, "preset-${field.fieldId}-validation",
                        value.validationError, cjguiComposableFormValidationStyle(), resourceId: field.resourceId,
                        fieldId: field.fieldId, displayValueRole: "validation"))
                }
                manual.add(editor)
                if (commandSurfaces) {
                    manual.add(cjguiComposableFieldSlider(140, "preset-copies-slider", spec, form,
                        CjguiComposableUiStyle(growX: 1, fixedHeight: 30), step: 1,
                        appearance: CjguiComposableUiSliderAppearance.fromTheme(theme)))
                }
            } else {
                manual.add(
                cjguiComposableBoundFormField(100 + index * 10, "preset-${field.fieldId}", 101 + index * 10,
                    102 + index * 10, field, value, PrintPresetDomain.ownerId, if (field.editorKind == "TEXT") { fontEditorStyle(theme) } else { theme.input }, cjguiComposableFormValidationStyle(),
                    validationDisplayMessage: value.validationError,
                    helpText: if (commandSurfaces) { "修改先进入草稿，应用后更新打印预设" } else { "" }))
            }
        }
        if (fontMode) {
            let mono = fontOwner.mono.getOrThrow()
            let serif = fontOwner.serif.getOrThrow()
            manual.add(cjguiComposableText(1703, "preset-font-runs", "iiiiWWWW 中文 é 👩🏽‍💻 · 字体与系统 fallback",
                CjguiComposableUiStyle(fontFamily: mono.fontFamily, fontSize: 17.0, growX: 1,
                    textColor: theme.body.textColor, lineHeight: 24.0, letterSpacing: 0.25,
                    textMaxLines: 2, textOverflow: "ellipsis"),
                textStyleRuns: [CjguiComposableUiTextStyleRun(0, 4, 17.0, 0, serif.fontFamily,
                    theme.body.textColor.red, theme.body.textColor.green, theme.body.textColor.blue, 1.0)]))
            let original = snapshot.fieldForResourceId(6201)
            manual.add(cjguiComposableMultilineTextInput(1702, "preset-font-multiline", "同一任务 · 多行只读投影",
                original.draftText, 6201,
                CjguiComposableUiStyle(fontFamily: mono.fontFamily, fontSize: 17.0, fixedHeight: 66,
                    growX: 1, padding: 6, border: theme.input.border, borderWidth: 1,
                    background: theme.input.background, textColor: theme.input.textColor, letterSpacing: 0.25, lineHeight: 24.0),
                readOnly: true, fieldId: "jobName", displayValueRole: "draft"))
        }
        let actions = cjguiComposableWrap(40, "preset-actions", CjguiComposableUiStyle(gap: 8), rowGap: 6)
        var actionIndex: Int64 = 0
        for (action in domain.actionDescriptors()) {
            if (action.name == "APPLY_DRAFT" || action.name == "CANCEL_DRAFT") {
                actions.add(
                    cjguiComposableButton(50 + actionIndex, "preset-${action.name}", action.displayName, action.name,
                        PrintPresetDomain.ownerId, theme.primaryAction,
                        enabled: feedback.actionAvailability(action.name).isAvailable, operationActionName: action.name,
                        interactionStyle: theme.primaryActionInteraction))
                actionIndex += 1
            }
        }
        manual.add(actions)
        manual.add(buildSelectedDetail(theme))
        if (commandSurfaces) {
            manual.add(cjguiComposableFormFeedbackSummary(155, "preset-form-feedback",
                feedbackProjection(snapshot), "LOCATE_FIELD",
                style: CjguiFormFeedbackSummaryStyle(title: theme.body, note: theme.body,
                    entry: theme.input, entryInteraction: theme.cardInteraction,
                    ready: theme.body, rejection: theme.body)))
            manual.add(cjguiComposableImage(79, "preset-beacon", beacon.rasterPath,
                CjguiComposableUiStyle(fixedWidth: 56, fixedHeight: 56),
                imageResourceId: beacon.key, imageResourceVersion: beacon.version))
        }
        manual.add(CjguiStatusFeedback.buildMessage(52, "preset-validation", 53, 54, -1,
            CjguiStatusMessageSpec(if (!snapshot.canApply) { CJGUI_STATUS_ERROR } else { stepKind },
                if (stepNotice.isEmpty()) { snapshot.statusMessage } else { stepNotice }),
            style: CjguiStatusMessageStyle(chip: CjguiComposableUiStyle(fixedWidth: 52, fixedHeight: 24,
                textColor: theme.body.textColor), text: theme.body)))
        let runtime = cjguiComposableVertical(60, "preset-runtime", CjguiComposableUiStyle(gap: 10, padding: 14,
            growX: 1))
        runtime.add(cjguiComposableText(61, "preset-runtime-title", "运行时区域", theme.heading))
        runtime.add(cjguiComposableText(62, "preset-connection-status", connectionStatus, theme.body))
        runtime.add(
            cjguiComposableButton(63, "preset-enable-collaboration", "开启本地协作", "ENABLE_COLLABORATION", 0,
                theme.primaryAction, enabled: !collaborationEnabled, interactionStyle: theme.primaryActionInteraction))
        if (collaborationEnabled) {
            runtime.add(region.buildNode(feedback: Some(feedback)))
        } else {
            runtime.add(
                cjguiComposableText(64, "preset-runtime-help", "开启后，独立客户端可生成界面并编辑同一草稿。",
                    theme.body))
        }
        columns.add(manual);
        columns.add(runtime);
        root.add(columns)
        var summary = "已应用："
        for (field in declarations.allFields()) {
            summary += "${field.label}=${snapshot.fieldForResourceId(field.resourceId).appliedValue.displayText()}  "
        }
        root.add(cjguiComposableText(70, "preset-applied", summary, theme.body))
        root.add(
            cjguiComposableText(71, "preset-version",
                "草稿 v${snapshot.draftVersion} · 已应用 v${snapshot.appliedConfigVersion}", theme.body))
        let layers = cjguiComposableLayerHost(80, "preset-layers", CjguiComposableUiStyle(growX: 1, growY: 1))
        // The CONTENT scrolls in every mode: the two live cards plus the flat
        // generated controls are taller than a normal window, and a card whose
        // actions sit below the window edge is not operable. This is the same
        // public scroll area the command mode already used, not a second one.
        let scroll = cjguiComposableScrollArea(6, "preset-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true))
        scroll.add(root)
        layers.add(scroll)
        if (helpVisible) {
            let dialog = cjguiComposableDialogLayerWithReference(81, "preset-help-dialog", "preset-help",
                "preset-layers", helpReturn,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 210, padding: 18, gap: 12,
                    background: theme.card.background, border: theme.card.border),
                initialFocus: Some(CjguiComposableUiNodeReference.manual(82)))
            dialog.add(cjguiComposableText(82, "preset-help-title", "编辑与应用", theme.heading))
            dialog.add(cjguiComposableText(83, "preset-help-body",
                "编辑先进入同一份草稿；点击应用或⌘S后更新已应用值。\nEsc返回原字段及选区。示例数据只保存在内存中。", theme.body))
            dialog.add(cjguiComposableButton(84, "preset-help-close", "返回编辑", "CLOSE_HELP",
                PrintPresetDomain.ownerId, theme.primaryAction))
            layers.add(dialog)
        }
        if (commandSurfaces) {
            let _ = contextMenu.attachTo(layers)
            return palette.attachTo(layers, theme)
        }
        return layers
    }
    private func rememberHelpReturnTarget(event: CjguiComposableUiEvent): Unit {
        if ((event.eventKind == 28 || event.eventKind == 29) && event.node.fieldId.size > 0 &&
            event.node.nodeId >= 0) {
            helpReturnNodeId = event.node.nodeId
        }
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        rememberHelpReturnTarget(event)
        if (commandSurfaces) {
            if (let Some(value) <- window) {
                if (let Some(result) <- contextMenu.applyUiEvent(event, value)) { return result }
            }
            if (let Some(result) <- palette.applyUiEvent(event)) { return result }
            if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                return match (window) {
                    case Some(value) => CjguiComposableUiDispatchResult(value.invokeCommand(commandId))
                    case None => CjguiComposableUiDispatchResult(false)
                }
            }
            if (event.node.nodeId == 140) { return region.handleFieldSliderEvent(event) }
        }
        if (event.eventKind == 36 && helpVisible) {
            helpVisible = false
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "SELECT_CARD") {
            // The row activation is routed to the OWNER first; only an applied
            // transaction may move the view's selection. A refused/retired row
            // leaves the old selection, focus and detail target in place.
            //
            // A virtual collection row is a DYNAMIC child of the accepted
            // composite, not a declared ELEMENT, so the generated-scene action
            // guard deliberately does not cover it. The app therefore routes the
            // same public SELECT_CARD transaction itself, using only the owner id
            // the row was built for (a retired owner resolves to no live key).
            let generatedByOwner = region.handleEvent(event)
            var applied = generatedByOwner.didApply
            var appliedKey = if (applied) { domain.cards.selectedKey() } else { "" }
            if (!applied && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
                let key = domain.cards.keyForOwner(event.node.resourceId)
                if (key.size > 0) {
                    let call = CjguiSharedOperationActionInvocation("SELECT_CARD",
                        domain.formSnapshot().contextVersion,
                        ArrayList<Int64>([PrintPresetDomain.ownerId]),
                        ArrayList<CjguiSharedOperationActionArgument>([
                            CjguiSharedOperationActionArgument("cardKey", CjguiSharedOperationValue.string(key))
                        ]))
                    let outcome = domain.executeFromHuman(call)
                    if (outcome.applied) {
                        applied = true
                        appliedKey = key
                        revision += 1
                    }
                }
            }
            if (applied && appliedKey.size > 0 && domain.cards.selectedKey() == appliedKey) {
                let _ = cardList.projectOwnerSelection(appliedKey)
                let view = cardList.viewSnapshot()
                getStdOut().writeln("PRESET_COLLECTION_SELECTION row=${appliedKey} selected=${view[2]} " +
                    "owner=${event.node.resourceId}")
                getStdOut().flush()
            }
            return CjguiComposableUiDispatchResult(applied)
        }
        if (event.node.actionName == "SORT_NAME" || event.node.actionName == "SORT_OWNER") {
            if (cardList.toggleSort(event.node.actionName)) {
                let view = cardList.viewSnapshot()
                getStdOut().writeln("PRESET_COLLECTION sort=${view[0]} query=[${view[1]}] selected=${view[2]}")
                getStdOut().flush()
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
        }
        let generated = region.handleEvent(event)
        if (generated.didApply) {
            stepNotice = ""
            stepKind = CJGUI_STATUS_INFO
            return generated
        }
        if (let Some(value) <- window) {
            let handled = form.handleFormEvent(event, value)
            if (handled.didApply) {
                stepNotice = ""
                stepKind = CJGUI_STATUS_INFO
                return handled
            }
            // This field already used the shared writer. A refusal also means an
            // owned range session may be consuming this whole-value preview;
            // retrying it below would advance its owner before the real delta.
            if ((event.eventKind == 28 || event.eventKind == 29) && event.node.fieldId.size > 0 &&
                event.node.operationResourceId == PrintPresetDomain.ownerId) {
                return handled
            }
        }
        if (event.eventKind == 28 || event.eventKind == 29) {
            // Handwritten editors (the print preset area AND the selected
            // object's detail) submit through the SAME owner draft writers.
            let isBoolean = event.eventKind == 29
            if (event.node.nodeId >= 910 && event.node.nodeId < 990) {
                let index = (event.node.nodeId - 910) / 10
                let declarations = domain.formBinding()
                if (index < 0 || index >= declarations.fieldCount()) {
                    return CjguiComposableUiDispatchResult(false)
                }
                let field = declarations.fieldAtControlIndex(index)
                let key = domain.cards.selectedKey()
                let card = match (domain.cards.card(key)) {
                    case Some(value) => value
                    case None => return CjguiComposableUiDispatchResult(false)
                }
                let applied = if (isBoolean) {
                    card.setBoolean(field.fieldId, event.text == "true")
                } else {
                    card.setText(field.fieldId, event.text)
                }
                getStdOut().writeln("PRESET_DETAIL_EDIT key=${key} field=${field.fieldId} applied=${applied} " +
                    "text=[${event.text}]")
                getStdOut().flush()
                if (applied) { revision += 1 }
                return CjguiComposableUiDispatchResult(applied)
            }
            if (event.node.fieldId.size > 0 && event.node.operationResourceId == PrintPresetDomain.ownerId) {
                let index = domain.formBinding().controlIndexForResourceId(event.node.resourceId)
                if (index < 0) {
                    return CjguiComposableUiDispatchResult(false)
                }
                let field = domain.formBinding().fieldAtControlIndex(index)
                let result = if (isBoolean) {
                    domain.editBooleanFromHuman(field.resourceId, event.text == "true")
                } else {
                    domain.editTextFromHuman(field.resourceId, event.text, event.selectionStart, event.selectionEnd)
                }
                getStdOut().writeln("PRESET_MANUAL_EDIT field=${field.fieldId} applied=${result.applied} " +
                    "reason=${result.reason}")
                getStdOut().flush()
                if (result.applied) { revision += 1 }
                return CjguiComposableUiDispatchResult(result.applied)
            }
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (event.node.nodeId == 904) {
                detailMode = if (detailMode == "handwritten") { "generated" } else { "handwritten" }
                getStdOut().writeln("PRESET_DETAIL_MODE mode=${detailMode} key=${domain.cards.selectedKey()}")
                getStdOut().flush()
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.nodeId == 905 || event.node.nodeId == 906) {
                let key = domain.cards.selectedKey()
                let card = match (domain.cards.card(key)) {
                    case Some(value) => value
                    case None => return CjguiComposableUiDispatchResult(false)
                }
                let outcome = if (event.node.nodeId == 905) { card.apply() } else { card.cancel() }
                getStdOut().writeln("PRESET_DETAIL_ACTION key=${key} action=${event.node.actionName} " +
                    "applied=${outcome[0]} reason=${outcome[1]}")
                getStdOut().flush()
                revision += 1
                return CjguiComposableUiDispatchResult(outcome[0])
            }
            if (commandSurfaces && event.node.actionName == "LOCATE_FIELD") {
                let index = domain.formBinding().controlIndexForResourceId(event.node.resourceId)
                if (index >= 0) {
                    if (let Some(value) <- window) {
                        let located = cjguiFocusFormFeedback(value, feedbackProjection(domain.formSnapshot()),
                            domain.formBinding().fieldAtControlIndex(index).fieldId)
                        return CjguiComposableUiDispatchResult(located.requestAccepted)
                    }
                }
                return CjguiComposableUiDispatchResult(false)
            }
            if (commandSurfaces && event.node.actionName == "OPEN_COMMANDS") {
                let target = match (window) {
                    case Some(value) => value.editingFocusReference() ?? CjguiComposableUiNodeReference.manual(77)
                    case None => CjguiComposableUiNodeReference.manual(77)
                }
                palette.open("打印预设操作", commandPresentation().placement(), target,
                    hint: "操作当前草稿；禁用原因来自同一表单")
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "TOGGLE_THEME") {
                appearance.light = !appearance.light
                if (commandSurfaces) {
                    let _ = contextMenu.restyle(CjguiContextCommandMenuStyle.themed(currentTheme()))
                }
                // The next build republishes the card's named styles and the card
                // factory reads this same theme, so the accepted generated scene
                // is repainted without re-submitting a structure.
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "OPEN_INSPECTOR") {
                inspectorRequested = true
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "OPEN_HELP") {
                if (let Some(value) <- window) {
                    if (let Some(target) <- value.editingFocusReference()) { helpReturn = target } else {
                        helpReturn = CjguiComposableUiNodeReference.manual(helpReturnNodeId)
                    }
                }
                helpVisible = true
                getStdOut().writeln("PRESET_HELP state=open")
                getStdOut().flush()
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (styledMode) {
                let action = event.node.actionName
                if (action == "STYLED_COLOR" || action == "STYLED_SIZE") {
                    if (action == "STYLED_COLOR") { fontOwner.alternateColor = !fontOwner.alternateColor }
                    else { fontOwner.largeType = !fontOwner.largeType }
                    fontOwner.revision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
                if (action == "FONT_FINISH") { fontFinishRequested=true; return CjguiComposableUiDispatchResult(true) }
                if (action == "FONT_PREVIEW") {
                    fontPreviewRequested = true
                    return CjguiComposableUiDispatchResult(true)
                }
                if (action == "STYLED_CONFIRM") {
                    stepNotice = "说明已核对；正文未改写"
                    revision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
            }
            if (event.node.actionName == "REPLACE_FONT" && fontMode) {
                replacePreviewFont()
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "CLOSE_HELP") {
                helpVisible = false
                if (let Some(value) <- window) {
                    let _ = value.focusAcceptedNodeById(helpReturnNodeId)
                }
                getStdOut().writeln("PRESET_HELP state=closed")
                getStdOut().flush()
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "PRESET_STEP_DOWN" || event.node.actionName == "PRESET_STEP_UP") {
                let declarations = domain.formBinding()
                let index = declarations.controlIndexForResourceId(event.node.resourceId)
                if (index < 0) { return CjguiComposableUiDispatchResult(false) }
                let field = declarations.fieldAtControlIndex(index)
                let current = domain.formSnapshot().fieldForResourceId(field.resourceId).draftText
                let step = CjguiNumericStepper.resolve(current,
                    if (event.node.actionName == "PRESET_STEP_UP") { CJGUI_NUMERIC_STEP_UP } else { CJGUI_NUMERIC_STEP_DOWN },
                    field.minimum, field.maximum, 1)
                if (!step.canWrite()) {
                    stepNotice = "步进被拒：${step.issue}"
                    stepKind = CJGUI_STATUS_ERROR
                    revision += 1
                    return CjguiComposableUiDispatchResult(false)
                }
                let result = domain.editTextFromHuman(field.resourceId, step.text, 0, step.text.size)
                stepNotice = if (result.applied) { "${field.label}草稿已更新为 ${step.text}" } else { "步进被拒：${result.reason}" }
                stepKind = if (result.applied) { CJGUI_STATUS_SUCCESS } else { CJGUI_STATUS_ERROR }
                revision += 1
                return CjguiComposableUiDispatchResult(result.applied)
            }
            if (event.node.actionName == "ENABLE_COLLABORATION") {
                requestCollaboration();
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "APPLY_DRAFT" || event.node.actionName == "CANCEL_DRAFT") {
                stepNotice = ""
                stepKind = CJGUI_STATUS_INFO
                let result = form.executeAction(event.node.actionName, event.node.semanticId)
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
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool {
        return region.beginSceneRefresh()
    }
    public func prepareSceneRefresh(): Bool {
        return region.prepareSceneRefresh()
    }
    private let countersTrace = getVariable("CJGUI_PRINT_COUNTERS_TRACE").isSome()

    public func commitSceneRefresh(): Unit {
        region.commitSceneRefresh()
        if (countersTrace) {
            // Existing counters only; this reads them after the commit and
            // prints one line per real scene commit.
            getStdOut().writeln("CJGUI_MIXED_FORM_COUNTS ${region.testWorkCounts()} outcome=${region.sceneState()}")
            getStdOut().flush()
        }
    }
    public func rollbackSceneRefresh(): Unit {
        region.rollbackSceneRefresh()
    }
    public func disposeSceneRefreshResources(): Unit {
        region.disposeSceneRefreshResources()
    }
    /// The handwritten detail of the collection's SELECTED object. It reads the
    /// same card (owner, declarations, drafts, validation, lock) the generated
    /// composite reads; the layout is app UI, the facts are the owner's.
    private func buildSelectedDetail(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let box = cjguiComposableVertical(900, "preset-detail", CjguiComposableUiStyle(gap: 6, padding: 8,
            growX: 1, border: theme.card.border, borderWidth: 1, cornerRadius: theme.card.cornerRadius))
        let key = domain.cards.selectedKey()
        let card = match (domain.cards.card(key)) {
            case Some(value) => value
            case None =>
                box.add(cjguiComposableText(901, "preset-detail-title", "选中对象", theme.heading))
                box.add(cjguiComposableText(902, "preset-detail-empty", "没有选中对象", theme.body))
                return box
        }
        box.add(cjguiComposableText(901, "preset-detail-title", "选中对象 ${key} · ${card.ownerId}", theme.heading))
        let bar = cjguiComposableWrap(903, "preset-detail-toolbar", CjguiComposableUiStyle(gap: 6), rowGap: 4)
        bar.add(cjguiComposableButton(904, "preset-detail-mode",
            if (detailMode == "handwritten") { "切到生成详情" } else { "切到手写详情" },
            "TOGGLE_DETAIL_MODE", card.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        bar.add(cjguiComposableButton(905, "preset-detail-apply", "应用", "APPLY_DRAFT", card.ownerId,
            theme.primaryAction, enabled: card.actionAvailability("APPLY_DRAFT").isAvailable,
            operationActionName: "APPLY_DRAFT", interactionStyle: theme.primaryActionInteraction))
        bar.add(cjguiComposableButton(906, "preset-detail-cancel", "还原", "CANCEL_DRAFT", card.ownerId,
            theme.primaryAction, enabled: card.actionAvailability("CANCEL_DRAFT").isAvailable,
            operationActionName: "CANCEL_DRAFT", interactionStyle: theme.primaryActionInteraction))
        box.add(bar)
        if (detailMode == "generated") {
            box.add(cjguiComposableText(907, "preset-detail-generated-note",
                "生成详情：运行时区域里 ${key} 的组合卡片（若当前结构声明了该对象）；两处读写同一 owner 与草稿。",
                theme.body))
        } else {
            let snapshot = card.snapshot(domain.formSnapshot().contextVersion)
            let declarations = domain.formBinding()
            let cardSnapshot = snapshot
            let lockedReason = card.lockedReason()
            var error = ""
            for (index in 0..declarations.fieldCount()) {
                let fieldError = card.validation(declarations.fieldAtControlIndex(index).fieldId)
                if (!fieldError.isEmpty()) {
                    error = fieldError
                    break
                }
            }
            let dirty = cardSnapshot.draftVersion != cardSnapshot.appliedConfigVersion
            let status = if (!lockedReason.isEmpty()) {
                lockedReason
            } else if (!error.isEmpty()) {
                error
            } else if (dirty) {
                "草稿未应用"
            } else {
                "草稿与已应用值一致"
            }
            // The field area and status line come from the SHARED detail builder:
            // the same public function the rule-set consumer uses, so the layout
            // is not a second app-local copy.
            box.add(cjguiSharedEditableDetailFields(890, 910, 908, "preset-detail", card.ownerId,
                declarations, snapshot, { fieldId =>
                    let availability = card.fieldAvailability(fieldId)
                    CjguiSharedDetailFieldState(availability.isAvailable,
                        unavailableReason: availability.reason)
                }, status, theme))
        }
        return box
    }

    private func currentTheme(): CjguiComposableUiTheme {
        return mixedFormTheme(appearance.light)
    }
    private func feedbackProjection(snapshot: CjguiSharedFormSnapshot): CjguiFormFeedbackProjection {
        return CjguiFormFeedbackProjection(snapshot, domain.formBinding(), PrintPresetDomain.ownerId,
            policy: CjguiFormFeedbackPolicy(focusSemanticId: Some({ id =>
                if (id == "copies") { "preset-copies" } else { "preset-${id}-editor" }
            }), availability: Some({ id =>
                let _ = id
                let reason = domain.lockReason()
                if (reason.size > 0) {
                    CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId,
                        domain.formSnapshot().contextVersion)
                } else {
                    CjguiSharedAvailability.unknown()
                }
            })))
    }

    // One command declaration list, projected into toolbar, native menu,
    // palette and context menu. Labels/rules remain the original form's.
    private func commandPresentation(): CjguiCommandPresentation {
        let commands = ArrayList<CjguiComposableUiCommand>()
        let metadata = ArrayList<CjguiCommandToolbarMetadata>()
        let feedback = form.formFeedback().getOrThrow()
        var index: Int64 = 0
        for (action in domain.actionDescriptors()) {
            if (action.name != "APPLY_DRAFT" && action.name != "CANCEL_DRAFT") { continue }
            let availability = feedback.actionAvailability(action.name)
            let id = "preset.${action.name}"
            commands.add(CjguiComposableUiCommand(id, CjguiComposableUiNodeReference.manual(50 + index),
                action.displayName, CjguiComposableUiShortcut(if (action.name == "APPLY_DRAFT") { "s" } else { "r" }),
                "Edit", 0, availability.isAvailable, false))
            metadata.add(CjguiCommandToolbarMetadata(id, action.name, PrintPresetDomain.ownerId,
                detail: action.displayName, disabledReason: availability.reason))
            index += 1
        }
        commands.add(CjguiComposableUiCommand("preset.theme", CjguiComposableUiNodeReference.manual(76),
            "浅色外观", CjguiComposableUiShortcut("t"), "View", 0, true, appearance.light, presentationOnly: true))
        metadata.add(CjguiCommandToolbarMetadata("preset.theme", "TOGGLE_THEME", PrintPresetDomain.ownerId,
            detail: "切换显示外观"))
        commands.add(CjguiComposableUiCommand("preset.help", CjguiComposableUiNodeReference.manual(73),
            "编辑说明", CjguiComposableUiShortcut("k"), "Help", 0, true, false))
        metadata.add(CjguiCommandToolbarMetadata("preset.help", "OPEN_HELP", PrintPresetDomain.ownerId))
        return CjguiCommandPresentation(commands, metadata)
    }

    public func finishCommandAction(value: CjguiComposableUiWindow): Unit {
        if (!commandSurfaces) { return }
        if (let Some(item) <- palette.takeConfirmed(value)) {
            if (!value.invokeCommand(item.commandId)) {
                stepNotice = "命令没有完成，请查看字段与状态提示"
                stepKind = CJGUI_STATUS_ERROR
                revision += 1
            }
        }
        if (!palette.takeConfirmationFailure().isEmpty()) {
            stepNotice = "命令未执行：无法返回原控件，请检查字段提示"
            stepKind = CJGUI_STATUS_ERROR
            revision += 1
        }
    }

    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool {
        if (!commandSurfaces) { return false }
        let value = match (window) { case Some(v) => v; case None => return false }
        // WindowCommand rows retain their live target. An input field cannot
        // authorize a different button's command merely by opening a menu.
        let opened = contextMenu.open(value, request, contextPresentation(request.nodeId), "preset-root",
            source: CjguiContextMenuCommandSource.WindowCommand,
            style: CjguiContextCommandMenuStyle.themed(currentTheme()))
        if (opened) { contextTargetNodeId = request.nodeId; revision += 1 }
        return opened
    }
    private func contextPresentation(nodeId: Int64): CjguiCommandPresentation {
        let source = commandPresentation()
        let commands = ArrayList<CjguiComposableUiCommand>()
        let metadata = ArrayList<CjguiCommandToolbarMetadata>()
        for (command in source.commands) {
            if (command.manualTargetNodeId() != nodeId) { continue }
            commands.add(command)
            for (item in source.metadata) {
                if (item.commandId == command.id) { metadata.add(item) }
            }
        }
        return CjguiCommandPresentation(commands, metadata)
    }
    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit {
        let _ = reason
        if (contextMenu.requestEnded(requestId)) {
            contextTargetNodeId = -1
            revision += 1
            if (let Some(value) <- window) { value.requestRefresh() }
        }
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        if (commandSurfaces && !helpVisible) {
            let declarations = commandPresentation().commands
            declarations.add(CjguiComposableUiCommand("preset.commands", 77, CjguiComposableUiShortcut("p")))
            for (command in palette.commands()) { declarations.add(command) }
            return declarations
        }
        return if (helpVisible) { ArrayList<CjguiComposableUiCommand>() } else {
            ArrayList<CjguiComposableUiCommand>([
                CjguiComposableUiCommand("preset.apply", 50, CjguiComposableUiShortcut("s")),
                CjguiComposableUiCommand("preset.help", 73, CjguiComposableUiShortcut("k"))])
        }
    }
}

private func localAuthorization(): CjguiSharedOperationExternalAuthorization {
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>()
    for (action in ["GET_CONTEXT", "GET_GENERATED_UI", "SUBMIT_GENERATED_UI"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action, ArrayList<Int64>(), true))
    }
    // The SAME declared vocabulary is authorized for the handwritten preset and
    // for each card's own owner; an unknown target is still refused by the
    // domain, and each scope names the exact objects it may touch.
    let presetTargets = ArrayList<Int64>([PrintPresetDomain.ownerId,
        PresetCardCollection.cardAOwner, PresetCardCollection.cardBOwner])
    scopes.add(CjguiSharedOperationExternalActionScope("REBIND_CARD",
        ArrayList<Int64>([PresetCardCollection.cardAOwner, PresetCardCollection.cardBOwner]), false))
    // Locking is owner state for the handwritten preset and every card; the
    // scope names exactly those objects.
    scopes.add(CjguiSharedOperationExternalActionScope("SET_LOCK",
        ArrayList<Int64>([PrintPresetDomain.ownerId, PresetCardCollection.cardAOwner,
            PresetCardCollection.cardBOwner]), false))
    for (action in ["EDIT_DRAFT_TEXT", "EDIT_DRAFT_BOOLEAN", "APPLY_DRAFT", "CANCEL_DRAFT"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action, presetTargets, false))
    }
    // The object collection's own public operations live on the PRESET owner:
    // they change which objects are selected/visible/present, never another
    // owner's draft, and each is still re-checked by the domain transaction.
    for (action in ["SELECT_CARD", "ADD_CARD", "DELETE_CARD", "FILTER_CARDS", "SORT_CARDS"]) {
        scopes.add(CjguiSharedOperationExternalActionScope(action,
            ArrayList<Int64>([PrintPresetDomain.ownerId]), false))
    }
    // A local example capability, carried by the existing private descriptor.
    return CjguiSharedOperationExternalAuthorization("mixed-form-local-client", "mixed-form-demo-capability", scopes)
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--check-composition") { return checkMixedComposition() }
    if (args.size == 1 && args[0] == "--check-font-resources") { return checkFontResources() }
    var collaboration = false
    var commands = false
    var fontResources = false
    var styledText = false
    for (arg in args) {
        if (arg == "--collaboration" && !collaboration) { collaboration = true }
        else if (arg == "--commands" && !commands) { commands = true }
        else if (arg == "--fonts" && !fontResources) { fontResources = true }
        else if (arg == "--styled-text" && !styledText) { styledText = true }
        else { return 2 }
    }
    let domain = PrintPresetDomain()
    fontResources = fontResources || styledText
    commands = commands || fontResources
    let sharedFonts = PrintPresetFontResources(fontResources, styled: styledText)
    let controller = MixedFormController(domain, commandSurfaces: commands, fontResources: fontResources,
        styledText: styledText, sharedFonts: Some(sharedFonts))
    let application = CjguiMacosApplication(maximumWindowCount: if (styledText) { 3 } else { 2 })
    let opened = application.openWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            if (styledText) { "打印预设 · 公共样式" } else if (fontResources) { "打印预设 · 公共字体" } else if (commands) { "打印预设 · 公共组合" } else { "打印预设 · 混合表单" }, 1000u32, 680u32,
            rangeTextEditDeltaDelivery: true))
    if (!opened.didOpen) {
        application.close(); controller.closeResources()
        return 1
    }
    let businessId = opened.identifier.getOrThrow()
    let business = application.window(businessId).getOrThrow()
    controller.attachWindow(business)
    // Off until the explicit development button is used; no sampling loop.
    let inspector = CjguiMacosInspector(application, businessId)
    if (collaboration) {
        controller.requestCollaboration()
    }
    var companionId: ?CjguiMacosApplicationWindowIdentifier = None
    var finishingFonts=false
    var companion: ?CjguiComposableUiWindow = None
    var companionController: ?MixedFormController = None
    var connection: ?CjguiSharedOperationExternalConnection = None
    getStdOut().writeln("CJGUI_MIXED_FORM_READY collaboration=off")
    getStdOut().flush()
    try {
        while (if (styledText) { application.isOpen() } else { business.isOpen() }) {
            let _ = application.pumpUntilWork()
            if (styledText && !finishingFonts && (controller.takeFontPreviewRequest() ||
                (companionController.isSome() && companionController.getOrThrow().takeFontPreviewRequest()))) {
                if (companion.isNone() || !companion.getOrThrow().isOpen()) {
                    let peer = MixedFormController(domain, commandSurfaces: true, fontResources: true,
                        styledText: true, sharedFonts: Some(sharedFonts))
                    let created = application.openWindow(peer,
                        configuration: CjguiMacosApplicationWindowConfiguration("打印预设 · 公共样式 · 对照", 900u32, 640u32,
                            rangeTextEditDeltaDelivery: true))
                    if (created.didOpen) {
                        companionId = created.identifier
                        companionController = Some(peer)
                        companion = application.window(created.identifier.getOrThrow())
                        peer.attachWindow(companion.getOrThrow())
                        println("CJGUI_STYLED_COMPANION_OPENED")
                    }
                }
            }
            if (styledText && !finishingFonts && (controller.takeFontFinishRequest() ||
                (companionController.isSome() && companionController.getOrThrow().takeFontFinishRequest()))) {
                let summary=StyledFontLifetimeSummary()
                let shown=application.openWindow(summary,
                    configuration:CjguiMacosApplicationWindowConfiguration("打印预设 · 字体资源结束",620u32,240u32))
                if(shown.didOpen){
                    finishingFonts=true
                    let _=application.requestClose(businessId)
                    if(let Some(peerId)<-companionId){let _=application.requestClose(peerId)}
                }
            }
            if(finishingFonts && !business.isOpen() &&
                (companion.isNone() || !companion.getOrThrow().isOpen()) && !sharedFonts.closed){
                inspector.close()
                if(let Some(endpoint)<-connection){endpoint.close()}
                controller.closeResources()
                getStdOut().writeln("CJGUI_STYLED_FONT_WINDOWS_CLOSED endpoint=cleared")
                getStdOut().flush()
            }
            if (let Some(peerWindow) <- companion) {
                if (peerWindow.isOpen()) { companionController.getOrThrow().finishCommandAction(peerWindow) }
            }
            if (!business.isOpen()) {
                if (styledText) { continue } else { break }
            }
            controller.finishCommandAction(business)
            if (controller.takeInspectorRequest()) { let _ = inspector.open() }
            inspector.synchronizeLifetime()
            if (connection.isNone() && controller.takeCollaborationRequest()) {
                let candidate = CjguiSharedOperationExternalConnection(domain, localAuthorization(), business)
                let enabled = candidate.enableGeneratedUiProvider(controller.region) &&
                    application.attachExternalConnection(candidate)
                if (enabled) {
                    connection = Some(candidate)
                    if (let Some(info) <- candidate.connectionInfo()) {
                        getStdOut().writeln("CJGUI_MIXED_FORM_READY DESCRIPTOR_PATH ${info.descriptorPath}")
                        getStdOut().flush()
                    }
                } else {
                    candidate.close()
                }
                controller.collaborationOpened(enabled)
            }
        }
    } finally {
        inspector.close()
        application.close()
        controller.closeResources()
    }
    if (let Some(value) <- connection) {
        if (value.connectionInfo().isSome()) {
            return 3
        }
    }
    getStdOut().writeln("CJGUI_MIXED_FORM_CLOSED endpoint=cleared")
    getStdOut().flush()
    return 0
}
