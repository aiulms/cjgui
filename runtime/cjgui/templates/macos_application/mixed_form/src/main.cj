package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.fs.*

/// The appearance the window currently paints with. It is a plain object (not a
/// second theme registry): the handwritten area, the command surfaces and the
/// generated cards all read the SAME value on every build.
class MixedAppearance {
    var light: Bool = true
}

func mixedFormTheme(light: Bool): CjguiComposableUiTheme {
    return if (light) { CjguiComposableUiTheme.paperLight() } else { CjguiComposableUiTheme.beaconDark() }
}

/// Theme-driven named paint roles for generated workbench content. The
/// external capability text publishes these STYLE definitions (with purpose),
/// so a model/discovery client can choose a readable role instead of guessing
/// colours. Every value comes from the SAME theme the handwritten area uses.
func syncMixedWorkbenchNamedStyles(catalog: CjguiGeneratedUiCapabilityCatalog,
    theme: CjguiComposableUiTheme): Bool {
    let input = theme.input
    let action = theme.primaryAction
    let definitions = ArrayList<CjguiComposableUiNamedStyle>([
        CjguiComposableUiNamedStyle("mixed-workbench-title",
            CjguiComposableUiStyle(textColor: theme.heading.textColor, fontSize: 20.0, fontWeight: 1),
            purpose: "workbench title"),
        CjguiComposableUiNamedStyle("mixed-workbench-body",
            CjguiComposableUiStyle(textColor: theme.body.textColor, fontSize: 13.0),
            purpose: "workbench body"),
        CjguiComposableUiNamedStyle("mixed-workbench-note",
            CjguiComposableUiStyle(textColor: theme.body.textColor, fontSize: 13.0,
                lineHeight: 20.0), purpose: "workbench note"),
        CjguiComposableUiNamedStyle("mixed-workbench-input",
            CjguiComposableUiStyle(textColor: input.textColor, background: input.background,
                border: input.border, borderWidth: input.borderWidth, fontSize: 14.0,
                fixedHeight: 40, padding: input.padding, cornerRadius: input.cornerRadius),
            purpose: "workbench input"),
        CjguiComposableUiNamedStyle("mixed-workbench-action",
            CjguiComposableUiStyle(textColor: action.textColor, background: action.background,
                fontSize: 14.0, fixedWidth: 120, fixedHeight: 36),
            purpose: "workbench action")
    ])
    var ok = true
    for (definition in definitions) {
        if (catalog.namedStyles().forName(definition.name).isSome()) {
            if (!catalog.namedStyles().update(definition)) { ok = false }
        } else if (!catalog.namedStyles().register(definition)) {
            ok = false
        }
    }
    return ok
}

func mixedDuplexOptions(): ArrayList<CjguiSelectOption> {
    let options = ArrayList<CjguiSelectOption>()
    options.add(CjguiSelectOption("single", "单面", "false"))
    options.add(CjguiSelectOption("double", "双面", "true"))
    return options
}

interface MixedApplicationExitRetry {
    func retry(): Bool
}

class MixedApplicationExitRetryAction <: MixedApplicationExitRetry {
    private let action: () -> Bool
    init(action: () -> Bool) { this.action = action }
    public func retry(): Bool { return action() }
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
    /// Test/verification injection for the business-area logical width: when
    /// set, the narrow/wide branch decision uses THIS value instead of the
    /// live window frame, so the narrow layout can be exercised without a
    /// frontmost window (Sol owns the foreground during this package).
    private var businessWidthOverride: ?Int64 = None
    private var fontFinishRequested = false
    /// The dialog's return anchor. The DEFAULT and the no-focus fallback is
    /// the help trigger itself (node 73): it is mounted on the first screen in
    /// every mode, so the reference can never point at a hidden node (the old
    /// default 101 lives only inside the developer fold). OPEN_HELP re-selects
    /// the reference on every open; the previous value is never reused.
    /// Which return-anchor branch the last OPEN_HELP selected; recorded for
    /// the offline wiring test ("manual-73" / "editing-reference" /
    /// "focused-reference"). Initial value matches the initial fallback.
    private var helpReturnSelection = "manual-73"
    private var helpReturn = CjguiComposableUiNodeReference.manual(73)
    /// The help-layer change that has NOT reached an accepted scene yet:
    /// "" none, "open" an OPEN_HELP whose candidate is in flight, "close" a
    /// CLOSE/Esc whose candidate is in flight. Commit clears it; rollback
    /// restores `helpVisible` to the pre-intent value so the controller can
    /// never believe the dialog is open while the accepted scene shows none.
    private var pendingHelpIntent = ""
    private var stepNotice = ""
    private var stepKind = CJGUI_STATUS_INFO
    private let commandSurfaces: Bool
    private let fontMode: Bool
    private let fontOwner: PrintPresetFontResources
    private let styledMode: Bool
    private var fontPreviewRequested = false
    /// A4: this close request came from the APPLICATION-EXIT decision, not from
    /// ⌘W/system close. It is cleared on cancel or after one retry; it never
    /// outlives the refusal it was created for.
    private var applicationExitIntent: Bool = false
    private var applicationExitRetry: ?MixedApplicationExitRetry = None
    private let fontCatalog: CjguiGeneratedUiCapabilityCatalog
    private var appearance: MixedAppearance
    private let commandScope = CjguiComposableUiIdentityScope("print-preset-commands")
    private let palette = CjguiCommandPalette("print-preset-palette")
    private let contextMenu = CjguiContextCommandMenu(CjguiComposableUiIdentityScope("print-preset-context"),
        "print-preset-context-menu")
    private var contextTargetNodeId: Int64 = -1
    private let viewport = CjguiComposableUiScrollViewport()
    // Ordinary public controls over the SAME owner: the select confirms the
    // duplex field through the existing EDIT_DRAFT_BOOLEAN writer, the popover
    // only presents help, and the scrollbar shares `viewport` with the wheel.
    private let duplexSelectBinding: CjguiSelectFieldBinding
    private let duplexSelect: CjguiSelect
    /// Real consumer controls for the choice-family acceptance chain: hide the
    /// handwritten presentations (generated-only mount) and cycle the field's
    /// live option list (disable/delete/restore) through the same binding.
    private var duplexGeneratedOnly = false
    private var duplexOptionsStage = 0
    private let duplexTooltip = CjguiTooltip("preset-duplex-tip", "preset-duplex-tip")
    private let layoutPopover = CjguiPopover("preset-layout-help", "preset-layout-help")
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
    // One small recomputable swatch pair published for ordinary handwritten and
    // generated preview nodes. Bundle-relative names resolve through the SAME
    // native loader; no absolute path or generated-only registry is involved.
    private let previewPng = CjguiGeneratedUiImageResourceSpec("preview-swatch", "PNG", 1,
        "四色色块 PNG", "preview-swatch.png")
    private let previewJpeg = CjguiGeneratedUiImageResourceSpec("preview-jpeg", "JPEG", 1,
        "四色色块 JPEG", "preview-swatch.jpg")
    private let previewJpeg2 = CjguiGeneratedUiImageResourceSpec("preview-jpeg-alt", "JPEG", 1,
        "四色色块 JPEG 另一幅", "preview-swatch-v2.jpg")
    private let previewCorrupt = CjguiGeneratedUiImageResourceSpec("preview-corrupt", "JPEG", 1,
        "截断的 JPEG（失败守卫）", "preview-corrupt.jpg")
    private var previewResourceKey: String = "preview-jpeg"
    private var previewResourceVersion: Int64 = 1
    // ONE thin document workflow over the accepted region. It keeps only the
    // path, the last saved document digest/baseline and the current operation
    // result; the live interface is always the region's accepted snapshot and
    // drafts stay in the business owners.
    private let documentSession: CjguiGeneratedUiDocumentSession
    // ONE optional public composition owns the five document actions, their
    // availability and the status/preview projection. The application keeps
    // its owner, theme and close policy.
    private let documentWorkspace: CjguiUiDocumentWorkspace
    /// The SECOND real region of the same window: an independent surface,
    /// session and file association for the auxiliary summary layout. The
    /// business owner set is shared; document identity is not.
    private let summaryRegion: CjguiGeneratedUiWindowRegion
    private let summarySession: CjguiGeneratedUiDocumentSession
    private let summaryWorkspace: CjguiUiDocumentWorkspace
    /// Ordinary path entry for opening or saving another interface file. The
    /// application owns this small string; the workspace owns the operation.
    private var uiDocumentPathInput: String
    private var uiDocumentSummaryPathInput: String
    /// ONE shared close coordination over BOTH document workspaces. The
    /// business close policy stays in this application; the guard only
    /// settles document facts and offers save/discard/cancel.
    private let uiCloseGuard: CjguiUiDocumentCloseGuard
    private var uiCloseGuardActive: Bool = false
    private var uiCloseGuardNotice: String = ""
    /// Layout position of the two document workspaces; swapping must not
    /// change which workspace a command or save belongs to.
    private var workspacesSwapped: Bool = false
    private var uiWorkspaceVisible: Bool = false
    private var uiWorkspaceSelection: String = "main"
    private var developerInfoVisible: Bool = false
    private var columnEditorVisible: Bool = false
    private var viewToolsVisible: Bool = false

    init(domain: PrintPresetDomain, commandSurfaces!: Bool = false, fontResources!: Bool = false,
        styledText!: Bool = false, sharedFonts!: ?PrintPresetFontResources = None,
        uiDocument!: String = "") {
        this.domain = domain
        this.documentSession = CjguiGeneratedUiDocumentSession(path: uiDocument,
            historyPolicy: Some(CjguiUiDocumentHistoryPolicy()))
        this.uiDocumentPathInput = uiDocument
        this.uiDocumentSummaryPathInput = ""
        this.commandSurfaces = commandSurfaces
        this.fontMode = fontResources
        this.styledMode = styledText
        this.fontOwner = sharedFonts ?? PrintPresetFontResources(fontResources)
        // ONE duplex option declaration feeds the handwritten Select and the
        // generated field factory. Its commit closure is the same owner edit
        // both paths use; neither keeps a second value or transaction.
        let declaredDuplex = CjguiSelectFieldBinding("duplex", "preset-duplex-select", "preset-duplex",
            mixedDuplexOptions(), commit: { option => domain.editBooleanFromHuman(6203, option.value == "true").applied },
            searchable: true)
        this.duplexSelectBinding = declaredDuplex
        this.duplexSelect = declaredDuplex.select
        let declaredSelects = ArrayList<CjguiSelectFieldBinding>()
        declaredSelects.add(declaredDuplex)
        this.form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId,
            selectBindings: declaredSelects)
        let formBinding = form
        let catalog = form.capabilityCatalog(maxNodes: 64)
        // Workspace containers come from the shared optional registration: the
        // form catalog stays small, and this application opts into the same
        // Tabs/ScrollArea/Split (and, when commands are enabled, Image)
        // declarations the rules consumer uses.
        let workspaceIssue = CjguiGeneratedUiWorkspaceCatalog.registerInto(catalog,
            includeImage: commandSurfaces)
        if (workspaceIssue.size > 0) {
            let _ = fontOwner.close(); throw Exception(workspaceIssue)
        }
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
            // The image KIND was already registered with the workspace set; only
            // the application's own slider kind and resource identity remain.
            if (!catalog.registerComponent(cjguiGeneratedSliderComponent()) ||
                !catalog.registerImageResource(beacon) ||
                !catalog.registerImageResource(previewPng) ||
                !catalog.registerImageResource(previewJpeg) ||
                !catalog.registerImageResource(previewJpeg2) ||
                !catalog.registerImageResource(previewCorrupt)) {
                let _ = fontOwner.close(); throw Exception("print_preset_component_registration")
            }
        }
        this.cards = domain.cards
        let cardObjects = cards
        // Card row paint reads the SAME live appearance as the handwritten
        // page, at build time. The object becomes the controller member below.
        let appearance = MixedAppearance()
        this.cardList = PresetCardList(domain.cards, { => mixedFormTheme(appearance.light) })
        // The card paints itself from the SAME appearance the handwritten area
        // uses, read at BUILD time: a theme change repaints the card on the next
        // refresh instead of freezing one theme's colours into the scene. The
        // closure captures the LOCAL object because the remaining members are
        // not initialized yet; the same object becomes the controller's member.
        if (!registerPresetCardComposite(catalog, { => mixedFormTheme(appearance.light) }) ||
            !syncPresetCardNamedStyles(catalog, mixedFormTheme(appearance.light)) ||
            !syncMixedWorkbenchNamedStyles(catalog, mixedFormTheme(appearance.light)) ||
            !cardList.register(catalog)) {
            let _ = fontOwner.close()
            throw Exception("print_preset_card_registration")
        }
        // ONE shared multi-object adapter now routes every card instance; the
        // provider remains only the default-instance fallback (handwritten form
        // and the collection row's SELECT_CARD transaction).
        let fallback = MixedPresetProvider(formBinding, cardObjects, domain)
        let multiObject = CjguiGeneratedUiMultiObjectBinding(
            fallback,
            { key => key.size > 0 && key.startsWith("card") },
            { key => presetCardObjectBinding(cardObjects, key) },
            ownerBlockedReason: { => domain.lockReason() })
        this.region = CjguiGeneratedUiWindowRegion(catalog, multiObject,
            "print-preset-runtime")
        this.documentWorkspace = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("print-preset"), "ui-document",
            this.documentSession, this.region,
            title: "界面文档 · 人机共同编辑")
        // The second REAL region: its own surface identity, its own holder
        // scope and its own session, so the two file associations can never
        // cross-write even though the business owner set is shared.
        this.summaryRegion = CjguiGeneratedUiWindowRegion(catalog, multiObject,
            "print-preset-summary")
        this.summarySession = CjguiGeneratedUiDocumentSession()
        this.summaryWorkspace = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("print-preset"), "ui-document-summary",
            this.summarySession, this.summaryRegion,
            title: "辅助摘要 · 界面文档")
        this.uiCloseGuard = CjguiUiDocumentCloseGuard()
        this.uiCloseGuard.add(this.documentWorkspace)
        this.uiCloseGuard.add(this.summaryWorkspace)
        this.appearance = appearance
    }
    /// Same public startup operation used by Rules and the close guard.
    public func beginStartupUiDocument(path: String): CjguiUiDocumentSessionResult {
        let done = documentWorkspace.beginStartup(path)
        let status = if (done.applied && done.reason == "ui_document_file_adopted") { "LOADED" } else { "START" }
        getStdOut().writeln("CJGUI_MIXED_FORM_UI_DOCUMENT_${status} reason=${done.reason} " +
            "token=${done.token} version=${done.version} path=${done.path} file_sha=${done.fileDigest}")
        getStdOut().flush()
        return done
    }

    public func finishStartupUiDocument(): CjguiUiDocumentSessionResult {
        return documentWorkspace.finish()
    }

    public func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument {
        return region.acceptedUiDocument()
    }

    public func closeResources(): Unit {
        documentWorkspace.closeHistory()
        summaryWorkspace.closeHistory()
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
        summaryRegion.attachWindow(value)
    }
    public func uiSceneVersion(): Int64 {
        return revision + fontOwner.revision + domain.formSnapshot().contextVersion +
            region.revision() + summaryRegion.revision() + palette.revision()
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
            // Both mounts are read AFTER the targeted reveal: the table moves,
            // the list keeps its own scroll. -1 means the instance is not
            // currently accepted (e.g. before the structure is submitted).
            let tableOffset = cardList.mountOffset("preset-card-table")
            let listOffset = cardList.mountOffset("preset-card-list")
            getStdOut().writeln("PRESET_COLLECTION_REVEAL key=${ownerSelection} applied=${revealed} " +
                "tableOffset=${tableOffset} listOffset=${listOffset}")
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
        // The same theme republishes the generated workbench roles, so a
        // light/dark switch repaints accepted generated labels too.
        let _ = syncMixedWorkbenchNamedStyles(fontCatalog, theme)
        let feedback = form.formFeedback().getOrThrow()
        let snapshot = feedback.snapshot
        let root = cjguiComposableVertical(1, "preset-root", theme.page)
        root.add(cjguiComposableText(2, "preset-title", "打印预设 · 混合表单", theme.heading))
        // The close protection is ordinary scene content at the TOP of the
        // scrolling page: a blocked close scrolls here, so the decision is
        // visible without a second window or a hidden bottom section.
        if (uiCloseGuardActive) {
            root.add(buildUiCloseGuardPanel(theme))
        }
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
        // Top utilities are SECONDARY commands from the public theme: the main
        // action of the business area is the selected object's Apply, and a
        // row of solid primary buttons used to erase that hierarchy. The
        // developer Inspector is diagnostic and lives in the developer-info
        // fold, not on the first screen.
        tools.add(cjguiComposableButton(73, "preset-help", "编辑说明 ⌘K", "OPEN_HELP",
            PrintPresetDomain.ownerId, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        // The appearance switch is its own control in BOTH modes: a normal window
        // must be able to change the theme, and the generated card has to stay
        // readable across that change (the accepted scene is not resubmitted).
        tools.add(cjguiComposableButton(76, "preset-theme", if (appearance.light) { "深色外观" } else { "浅色外观" },
            "TOGGLE_THEME", PrintPresetDomain.ownerId, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        if (commandSurfaces) {
            tools.add(cjguiComposableButton(77, "preset-command-owner", "操作面板 ⌘P", "OPEN_COMMANDS",
                PrintPresetDomain.ownerId, theme.secondaryAction,
                interactionStyle: theme.secondaryActionInteraction))
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
        // DS51 §12 B2/B3: the SAME public collection workspace the rules
        // consumer mounts. These three ordinary buttons save/restore/reset the
        // validated view snapshot; the collection's filter, sort and columns stay
        // the ONE shared table/view fact underneath.
        let viewTools = cjguiComposableWrap(1800, "preset-collection-view-tools",
            CjguiComposableUiStyle(gap: 8), rowGap: 6)
        viewTools.add(cjguiComposableText(1801, "preset-collection-view-title",
            "集合视图（${cardList.viewMode()}）", CjguiComposableUiStyle(fontSize: 13.0,
                textColor: theme.body.textColor, textMaxLines: 1)))
        viewTools.add(cjguiComposableButton(1807, "preset-view-tools-toggle",
            if (viewToolsVisible) { "收起视图" } else { "视图 / 列" },
            "TOGGLE_VIEW_TOOLS", PrintPresetDomain.ownerId, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        root.add(viewTools)
        if (viewToolsVisible) {
            root.add(cardList.buildViewActions(1810,
                CjguiComposableUiStyle(gap: 6, growX: 1),
                CjguiComposableUiStyle(fixedHeight: 28, padding: 6, background: theme.card.background,
                    textColor: theme.body.textColor, border: theme.card.border, borderWidth: 1,
                    cornerRadius: 6)))
            root.add(cjguiComposableButton(1806, "preset-columns-toggle",
                if (columnEditorVisible) { "隐藏列设置" } else { "列设置" },
                "TOGGLE_COLUMN_EDITOR", PrintPresetDomain.ownerId, theme.secondaryAction,
                interactionStyle: theme.secondaryActionInteraction))
            if (columnEditorVisible) {
                root.add(cardList.buildColumnControls(1830,
                    CjguiComposableUiStyle(gap: 4, growX: 1), CjguiComposableUiStyle(fixedHeight: 26)))
            }
            root.add(cjguiComposableText(1805, "preset-collection-view-status", cardList.viewStatus(),
                CjguiComposableUiStyle(fontSize: 12.5, textColor: theme.body.textColor,
                    textMaxLines: 2, textOverflow: "ellipsis")))
        }
        // The document workflow is reachable from a blank window with NO file
        // argument: the panels, path rows and open/save-as actions are always
        // present, and "尚未保存" is a visible fact instead of a hidden
        // default path. Swapping positions changes only layout order; every
        // command and file association still belongs to its own workspace.
        // The business page owns the selected-card detail; the developer fold
        // must not remount it (duplicate ids). Decided once, before any build.
        let businessFirstPage = !uiWorkspaceVisible
        let uiEntry = cjguiComposableWrap(1900, "preset-ui-entry",
            CjguiComposableUiStyle(gap: 8, padding: 4), rowGap: 4)
        uiEntry.add(cjguiComposableButton(1901, "preset-ui-open",
            if (uiWorkspaceVisible) { "返回业务" } else { "编辑界面" },
            if (uiWorkspaceVisible) { "CLOSE_UI_WORKSPACE" } else { "OPEN_UI_WORKSPACE" },
            PrintPresetDomain.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        if (uiWorkspaceVisible) {
            // The area selector's ACTIVE side reads as the primary choice; the
            // inactive side is the same command in the secondary role, not a
            // neutral base repainted solid primary.
            uiEntry.add(cjguiComposableButton(1902, "preset-ui-main", "主界面",
                "SELECT_UI_WORKSPACE_MAIN", PrintPresetDomain.ownerId,
                if (uiWorkspaceSelection == "main") { theme.primaryAction } else { theme.secondaryAction },
                interactionStyle: if (uiWorkspaceSelection == "main") {
                    theme.primaryActionInteraction
                } else {
                    theme.secondaryActionInteraction
                }))
            uiEntry.add(cjguiComposableButton(1903, "preset-ui-summary", "摘要界面",
                "SELECT_UI_WORKSPACE_SUMMARY", PrintPresetDomain.ownerId,
                if (uiWorkspaceSelection == "summary") { theme.primaryAction } else { theme.secondaryAction },
                interactionStyle: if (uiWorkspaceSelection == "summary") {
                    theme.primaryActionInteraction
                } else {
                    theme.secondaryActionInteraction
                }))
        }
        uiEntry.add(cjguiComposableButton(1904, "preset-ui-developer",
            if (developerInfoVisible) { "隐藏开发者信息" } else { "开发者信息" },
            "TOGGLE_DEVELOPER_INFO", PrintPresetDomain.ownerId, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        root.add(uiEntry)
        let columns = cjguiComposableHorizontal(3, "preset-columns", CjguiComposableUiStyle(gap: 18, growX: 1))
        let manual = cjguiComposableVertical(4, "preset-manual", CjguiComposableUiStyle(gap: 10, padding: 14, growX: 1))
        manual.add(cjguiComposableText(5, "preset-manual-title", "预设列表", theme.heading))

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
            } else if (field.fieldId == "duplex") {
                // The owner's lock is the same fact the provider publishes and
                // the write transaction enforces; the select must not offer a
                // confirm it is going to refuse.
                let lockReason = domain.lockReason()
                duplexSelectBinding.declare(value.draftText, enabled: lockReason.isEmpty(),
                    error: value.validationError,
                    style: CjguiSelectStyle.fromTheme(theme), theme: theme)
                if (duplexGeneratedOnly) {
                    // Generated-only mount: this field's Select lives ONLY in
                    // the generated area; the manual side shows the same draft
                    // as a note instead of keeping a hidden handwritten anchor.
                    manual.add(cjguiComposableText(1614, "preset-duplex-generated-only",
                        "双面打印选择仅由生成界面呈现（当前草稿：${duplexSelectBinding.select.selectedLabel()}）",
                        theme.body))
                } else {
                    let trigger = duplexSelect.trigger()
                    let _ = duplexTooltip.bind(trigger, "选择单面或双面打印；确认后进入同一份草稿，应用时提交",
                        reference: duplexSelect.triggerReference())
                    manual.add(trigger)
                    // The SAME field through the two always-visible choice
                    // presentations: facts come from the one declared binding,
                    // each instance manages only its own interaction state.
                    manual.add(duplexSelectBinding.radioGroupNode("preset-duplex-radio", "preset-duplex-radio",
                        label: "双面打印"))
                    manual.add(duplexSelectBinding.segmentedNode("preset-duplex-seg", "preset-duplex-seg",
                        label: "双面打印分段"))
                }
                manual.add(cjguiComposableButton(1601, "preset-layout-help", "排版提示", "OPEN_LAYOUT_HELP",
                    PrintPresetDomain.ownerId, theme.primaryAction,
                    interactionStyle: theme.primaryActionInteraction))
                manual.add(cjguiComposableButton(1615, "preset-duplex-mount",
                    if (duplexGeneratedOnly) { "恢复手写选择" } else { "仅生成选择" }, "DUPLEX_GENERATED_ONLY",
                    PrintPresetDomain.ownerId, theme.primaryAction,
                    interactionStyle: theme.primaryActionInteraction))
                manual.add(cjguiComposableButton(1616, "preset-duplex-options",
                    "选项维护（当前 ${duplexOptionsStage}）", "DUPLEX_OPTIONS_STAGE",
                    PrintPresetDomain.ownerId, theme.primaryAction,
                    interactionStyle: theme.primaryActionInteraction))
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
                // Apply keeps the primary role; Cancel is its secondary
                // counterpart, from the same public role set as the selected
                // object detail above.
                let (base, interaction) = if (action.name == "APPLY_DRAFT") {
                    (theme.primaryAction, theme.primaryActionInteraction)
                } else {
                    (theme.secondaryAction, theme.secondaryActionInteraction)
                }
                actions.add(
                    cjguiComposableButton(50 + actionIndex, "preset-${action.name}", action.displayName, action.name,
                        PrintPresetDomain.ownerId, base,
                        enabled: feedback.actionAvailability(action.name).isAvailable, operationActionName: action.name,
                        interactionStyle: interaction))
                actionIndex += 1
            }
        }
        manual.add(actions)
        // The selected-card detail is the business page's first-screen editor
        // (buildUi mounts it there). This developer-fold copy keeps the legacy
        // demo surface reachable WITHOUT remounting the same node ids twice:
        // a second id-900 subtree in one scene is a duplicate_node_id refusal,
        // which used to wedge the help dialog's close candidate.
        if (!businessFirstPage) {
            manual.add(buildSelectedDetail(theme))
        }
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
        // Handwritten preview of ONE registered small resource; the controller
        // picks the key/version below through ordinary buttons (no Apply).
        let previewSpec = if (previewResourceKey == "preview-jpeg") {
            previewJpeg
        } else if (previewResourceKey == "preview-jpeg-alt") {
            previewJpeg2
        } else if (previewResourceKey == "preview-corrupt") {
            previewCorrupt
        } else {
            previewPng
        }
        manual.add(cjguiComposableImageResource(1860, "preset-preview-image", previewSpec,
            CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, cornerRadius: 8,
                clipsContent: true), contentMode: 2))
        let previewActions = cjguiComposableHorizontal(1861, "preset-preview-actions",
            CjguiComposableUiStyle(gap: 6, fixedHeight: 30))
        previewActions.add(cjguiComposableButton(1862, "preset-preview-png", "PNG 色块",
            "PREVIEW_RESOURCE_PNG", PrintPresetDomain.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        previewActions.add(cjguiComposableButton(1863, "preset-preview-jpeg", "JPEG 色块",
            "PREVIEW_RESOURCE_JPEG", PrintPresetDomain.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        previewActions.add(cjguiComposableButton(1864, "preset-preview-jpeg2", "JPEG 另一幅",
            "PREVIEW_RESOURCE_JPEG2", PrintPresetDomain.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        previewActions.add(cjguiComposableButton(1866, "preset-preview-corrupt", "损坏 JPEG",
            "PREVIEW_RESOURCE_CORRUPT", PrintPresetDomain.ownerId, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        manual.add(previewActions)
        manual.add(cjguiComposableText(1865, "preset-preview-status",
            "预览资源：${previewSpec.key} v${previewSpec.version} ${previewSpec.contentType}",
            CjguiComposableUiStyle(fontSize: 12.0, fixedHeight: 20, textMaxLines: 1)))
        manual.add(CjguiStatusFeedback.buildMessage(52, "preset-validation", 53, 54, -1,
            CjguiStatusMessageSpec(if (!snapshot.canApply) { CJGUI_STATUS_ERROR } else { stepKind },
                if (stepNotice.isEmpty()) { snapshot.statusMessage } else { stepNotice }),
            style: CjguiStatusMessageStyle(chip: CjguiComposableUiStyle(fixedWidth: 52, fixedHeight: 24,
                textColor: theme.body.textColor), text: theme.body)))
        let runtime = cjguiComposableVertical(60, "preset-runtime", CjguiComposableUiStyle(gap: 10, padding: 14,
            growX: 1))
        runtime.add(cjguiComposableText(61, "preset-runtime-title", "运行时区域", theme.heading))
        runtime.add(cjguiComposableText(62, "preset-runtime-connection-status", connectionStatus, theme.body))
        // The Inspector is a developer diagnostic: it moved here from the
        // first-screen tool row so the top area keeps only what a normal
        // print-preset edit session needs.
        runtime.add(cjguiComposableButton(75, "preset-inspector", "开发：Inspector", "OPEN_INSPECTOR",
            PrintPresetDomain.ownerId, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        runtime.add(
            cjguiComposableButton(63, "preset-enable-collaboration", "开启本地协作", "ENABLE_COLLABORATION", 0,
                theme.primaryAction, enabled: !collaborationEnabled, interactionStyle: theme.primaryActionInteraction))
        if (!collaborationEnabled) {
            runtime.add(
                cjguiComposableText(64, "preset-runtime-help", "开启后，独立客户端可生成界面并编辑同一草稿。",
                    theme.body))
        }
        columns.add(manual)
        if (developerInfoVisible) { columns.add(runtime) }
        if (uiWorkspaceVisible) {
            if (uiWorkspaceSelection == "summary") {
                root.add(buildDocumentArea(424, theme, "辅助摘要布局", summaryWorkspace, summaryRegion,
                    None, uiDocumentSummaryPathInput))
            } else {
                root.add(buildDocumentArea(420, theme, "主详情布局", documentWorkspace, region,
                    feedback, uiDocumentPathInput))
            }
            root.add(cjguiComposableButton(406, "preset-workspaces-swap",
                if (workspacesSwapped) { "恢复工作区位置" } else { "交换工作区位置" },
                "SWAP_DOCUMENT_WORKSPACES", PrintPresetDomain.ownerId, theme.primaryAction,
                interactionStyle: theme.primaryActionInteraction))
        } else {
            // Business-first: the current object collection and its detail are
            // the first screen. Interface-document management is a named entry
            // above, never two always-open panels.
            // Business-first split: the SELECTED object detail is the first
            // column; the collection below/right is the SAME public
            // CjguiGeneratedUiCollection (filter/sort/selection/virtualization/
            // accepted mounts), not a second keysInOrder row list. A Wrap
            // measures children at their intrinsic width and never hands the
            // remaining window width to a growX child, so the wide window used
            // to leave a large idle band beside the detail. The wide window
            // therefore uses the SAME public split view the rule-set consumer
            // mounts (real column allocation, draggable handle). The narrow
            // window (below 700 logical points) is an EXPLICIT public vertical
            // stack: the detail first, the collection BELOW it at the full
            // usable width - a Wrap does not wrap when detail+list still fit
            // the narrow width, which squeezed the list into a right-side
            // strip instead.
            let businessWidth = match (businessWidthOverride) {
                case Some(value) => value
                case None => match (window) {
                    case Some(value) => match (value.windowScreenFrame()) {
                        case Some(frame) => max(0, frame[2] - 28)
                        case None => 980
                    }
                    case None => 980
                }
            }
            let narrowBusiness = businessWidth > 0 && businessWidth < 700
            let detailNode = buildSelectedDetail(theme)
            let listBox = cjguiComposableVertical(3000, "preset-business-list",
                if (narrowBusiness) {
                    CjguiComposableUiStyle(gap: 6, growX: 1)
                } else {
                    CjguiComposableUiStyle(gap: 6, fixedWidth: 300, growX: 0)
                })
            listBox.add(cjguiComposableText(3001, "preset-business-list-title", "对象", theme.heading))
            listBox.add(cjguiComposableTextInput(3003, "preset-business-filter", "筛选对象",
                cardList.filterQuery(), -1, CjguiComposableUiStyle(fixedHeight: 30, growX: 1,
                    background: theme.input.background, textColor: theme.input.textColor,
                    border: theme.input.border, borderWidth: 1, cornerRadius: 6),
                displayValueRole: "filter", interactionStyle: theme.inputInteraction))
            listBox.add(cardList.collection.buildNode(3004, "preset-business-collection",
                3005, "preset-business-collection-content", "list",
                CjguiComposableUiStyle(fixedHeight: 300, growX: 1)))
            let businessRow = if (narrowBusiness) {
                let column = cjguiComposableVertical(1905, "preset-business",
                    CjguiComposableUiStyle(gap: 12, growX: 1))
                column.add(detailNode)
                column.add(listBox)
                column
            } else {
                cjguiComposableScopedSplitView(CjguiComposableUiIdentityScope("preset-business"),
                    "preset-business", detailNode, listBox, CjguiComposableUiSplitAxis.HORIZONTAL,
                    max(320, businessWidth - 316), 280, 200,
                    CjguiComposableUiStyle(growX: 1, growY: 1),
                    operationActionName: "SET_PRESET_SPLIT_SIZE",
                    operationResourceId: PrintPresetDomain.ownerId)
            }
            root.add(businessRow)
            // The generated region must stay mounted even before the first
            // accepted structure: the external candidate lifecycle prepares it
            // in this scene. With zero accepted nodes it contributes no paint.
            root.add(region.attachTransientLayers(region.buildNode(feedback: feedback)))
            // The old 6200 demonstration form/preview is a named developer/demo
            // surface, not the selected-card editor.
            if (developerInfoVisible) { root.add(columns) }
        }
        // The bottom summary follows the SAME selected card as the detail and
        // commands. It used to show the 6200 demonstration form's applied values
        // even when cardB was selected.
        let selectedKey = domain.cards.selectedKey()
        let selectedSnapshot = match (domain.cards.card(selectedKey)) {
            case Some(card) => card.snapshot(domain.formSnapshot().contextVersion)
            case None => snapshot
        }
        var summary = "当前对象 ${selectedKey} 已应用："
        for (field in declarations.allFields()) {
            summary += "${field.label}=${selectedSnapshot.fieldForResourceId(field.resourceId).appliedValue.displayText()}  "
        }
        root.add(cjguiComposableText(70, "preset-applied", summary, theme.body))
        root.add(
            cjguiComposableText(71, "preset-version",
                "草稿 v${selectedSnapshot.draftVersion} · 已应用 v${selectedSnapshot.appliedConfigVersion}", theme.body))
        let layers = cjguiComposableLayerHost(80, "preset-layers", CjguiComposableUiStyle(growX: 1, growY: 1))
        // The CONTENT scrolls in every mode: the two live cards plus the flat
        // generated controls are taller than a normal window, and a card whose
        // actions sit below the window edge is not operable. This is the same
        // public scroll area the command mode already used, not a second one.
        let scroll = cjguiComposableScrollArea(6, "preset-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, clipsContent: true,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
        scroll.add(root)
        let scrollRow = cjguiComposableHorizontal(1600, "preset-scroll-row",
            CjguiComposableUiStyle(growX: 1, growY: 1, gap: 6))
        scrollRow.add(scroll)
        scrollRow.add(cjguiComposableScrollBar(1602, "preset-scrollbar", viewport, 10,
            style: CjguiScrollbarStyle.fromTheme(theme)))
        layers.add(scrollRow)
        if (helpVisible) {
            let dialog = cjguiComposableDialogLayerWithReference(81, "preset-help-dialog", "preset-help",
                "preset-layers", helpReturn,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 210, padding: 18, gap: 12,
                    background: theme.card.background, border: theme.card.border),
                initialFocus: Some(CjguiComposableUiNodeReference.manual(84)))
            dialog.add(cjguiComposableText(82, "preset-help-title", "编辑与应用", theme.heading))
            dialog.add(cjguiComposableText(83, "preset-help-body",
                "编辑先进入同一份草稿；点击应用或⌘S后更新已应用值。\nEsc返回原字段及选区。示例数据只保存在内存中。", theme.body))
            dialog.add(cjguiComposableButton(84, "preset-help-close", "返回编辑", "CLOSE_HELP",
                PrintPresetDomain.ownerId, theme.primaryAction))
            layers.add(dialog)
        }
        var result = layers
        if (layoutPopover.isOpen()) {
            let content = cjguiComposableVertical(1611, "preset-layout-popover-body",
                CjguiComposableUiStyle(gap: 6))
            content.add(cjguiComposableText(1612, "preset-layout-popover-text",
                "长表单在窄窗口中滚动查看；右侧滚动条与滚轮、键盘揭示共用同一位置。",
                CjguiComposableUiStyle(fontSize: 12.5, textColor: theme.body.textColor,
                    textMaxLines: 3, textOverflow: "ellipsis", lineHeight: 18.0)))
            content.add(cjguiComposableButton(1613, "preset-layout-popover-close", "关闭提示",
                "CLOSE_LAYOUT_HELP", PrintPresetDomain.ownerId, theme.primaryAction))
            result = layoutPopover.attachTo(result, content)
        }
        result = duplexSelect.attachTo(result)
        result = duplexTooltip.attachTo(result)
        if (commandSurfaces) {
            let _ = contextMenu.attachTo(result)
            return palette.attachTo(result, theme)
        }
        return result
    }
    /// A plain-key move of the generated collection becomes the SAME public
    /// SELECT_CARD owner transaction as a row click. A refused selection is not
    /// projected as if the detail switched: the view returns to the owner's
    /// current key instead.
    private func selectCardFromKeyboard(key: String): Bool {
        if (key.isEmpty()) { return false }
        let call = CjguiSharedOperationActionInvocation("SELECT_CARD",
            domain.formSnapshot().contextVersion,
            ArrayList<Int64>([PrintPresetDomain.ownerId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("cardKey", CjguiSharedOperationValue.string(key))
            ]))
        let outcome = domain.executeFromHuman(call)
        if (outcome.applied && domain.cards.selectedKey() == key) {
            let _ = cardList.projectOwnerSelection(key)
            return true
        }
        let current = domain.cards.selectedKey()
        if (current.size > 0) { let _ = cardList.projectOwnerSelection(current) }
        return false
    }

    private func matchesAcceptedPrimaryField(event: CjguiComposableUiEvent,
        value: CjguiComposableUiWindow): Bool {
        let node = event.node
        if ((event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED &&
            event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED) || node.fieldId.size == 0 ||
            node.operationResourceId != PrintPresetDomain.ownerId) { return false }
        for (accepted in value.acceptedSceneNodes()) {
            if (accepted.nodeId == node.nodeId) {
                return accepted.semanticId == node.semanticId &&
                    accepted.semanticIncarnation == node.semanticIncarnation &&
                    accepted.nodeKind == node.nodeKind && accepted.fieldId == node.fieldId &&
                    accepted.resourceId == node.resourceId &&
                    accepted.operationResourceId == node.operationResourceId &&
                    accepted.operationActionName == node.operationActionName &&
                    accepted.isEnabled && !accepted.isReadOnly
            }
        }
        return false
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // §13 B bounded probe: what shape does a focused collection key event
        // have? kind/node kind/semantic/viewport presence only, no values.
        if (event.eventKind == 35) {
            let hasViewport = match (event.node.scrollViewport) {
                case Some(_) => true
                case None => false
            }
            getStdOut().writeln("PRESET_KEY_EVENT kind=35 nodeKind=${event.node.nodeKind} " +
                "semantic=${event.node.semanticId} viewport=${hasViewport} text=${event.text}")
            getStdOut().flush()
        }
        // Generated collection keyboards navigate the ACTIVE accepted mount.
        // The event carries its exact viewport; a stale generation or a foreign
        // mount is unhandled here (no selection/owner write). Text fields and
        // other layers never reach this branch.
        if (event.eventKind == 35 &&
            event.node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            if (let Some(activeView) <- cardList.acceptedViewForEvent(event)) {
                let navigation = cjguiNavigateGeneratedCollection(cardList.collection, activeView,
                    event, window)
                if (navigation.isHandled) {
                    let plain = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) == 0 &&
                        event.text != "select_all"
                    var ownerApplied = false
                    if (plain && navigation.focus.size > 0) {
                        ownerApplied = selectCardFromKeyboard(navigation.focus)
                    }
                    getStdOut().writeln("PRESET_COLLECTION_KEYBOARD key=${event.text} " +
                        "focus=${navigation.focus} changed=${navigation.didChange} " +
                        "reveal=${navigation.didAcceptViewFocus} owner=${ownerApplied} " +
                        "offset=${activeView.scrollOffset()}")
                    getStdOut().flush()
                    revision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
            }
        }
        // Escape shares the button's completion path: the modal help layer
        // closes here and the framework restores the anchor reference the
        // dialog was declared with (focus, and the owned session's selection
        // through the same restore transaction). A context-menu Escape is
        // consumed by the menu's own route before it reaches this branch.
        if (event.eventKind == 36 && helpVisible) {
            helpVisible = false
            pendingHelpIntent = "close"
            getStdOut().writeln("PRESET_HELP state=closed-escape")
            getStdOut().flush()
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        // Path entries: each workspace's path string is application-owned;
        // the scoped field's semantic id identifies WHICH workspace's entry
        // the human edited. (28 is TEXT_CHANGED, as the framework routes it.)
        // The draft is read by the command handlers; it is not a file
        // association, so a keystroke does not force a whole-scene rebuild.
        if (event.eventKind == 28 && event.node.semanticId == "preset-business-filter") {
            let _ = domain.cards.setFilterText(event.text)
            let _ = cardList.syncFilter()
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 &&
            event.node.semanticId == documentWorkspace.pathFieldSemanticId()) {
            uiDocumentPathInput = event.text
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 &&
            event.node.semanticId == summaryWorkspace.pathFieldSemanticId()) {
            uiDocumentSummaryPathInput = event.text
            return CjguiComposableUiDispatchResult(true)
        }
        // Document-command ARRIVAL: the window's command dispatch carries the
        // command id in event.text. This is the owner action; it never
        // re-invokes the command, so the path cannot recurse.
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            // A declared document command reaches the controller from the
            // window's command entry as an ACTIVATE on the command's target
            // button with an EMPTY text. Deriving the id from that button keeps
            // the arrival on the owner action; treating it as a fresh request
            // called invokeCommand again and re-entered this event forever.
            var arrivalCommandId = event.text
            if (arrivalCommandId.size == 0) {
                if (let Some(derived) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                    arrivalCommandId = derived
                }
            }
            if (arrivalCommandId.size > 0) {
                if (let Some(done) <- executeDocumentCommand(documentWorkspace,
                        arrivalCommandId, uiDocumentPathInput)) {
                    return finishDocumentCommandEvent("arrival", arrivalCommandId, done,
                        documentWorkspace)
                }
                if (let Some(done) <- executeDocumentCommand(summaryWorkspace,
                        arrivalCommandId, uiDocumentSummaryPathInput)) {
                    return finishDocumentCommandEvent("arrival", arrivalCommandId, done,
                        summaryWorkspace)
                }
            }
        }
        // Document-command REQUEST: a real click on the built button carries
        // the public CJGUICOMMAND activation action. Route through the
        // window's command entry when the commands are declared; otherwise
        // execute directly into the owning workspace. Both channels end in
        // the same owner action for the SAME workspace.
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                if (documentWorkspace.ownsCommand(commandId) ||
                    summaryWorkspace.ownsCommand(commandId)) {
                    if (commandSurfaces) {
                        match (window) {
                            case Some(value) =>
                                let invoked = value.invokeCommand(commandId)
                                if (!invoked) {
                                    stepNotice = "命令没有完成，请查看界面文档状态提示"
                                    stepKind = CJGUI_STATUS_ERROR
                                }
                                revision += 1
                                return CjguiComposableUiDispatchResult(invoked)
                            case None =>
                                let owner = if (documentWorkspace.ownsCommand(commandId)) {
                                    documentWorkspace
                                } else {
                                    summaryWorkspace
                                }
                                let pathInput = if (documentWorkspace.ownsCommand(commandId)) {
                                    uiDocumentPathInput
                                } else {
                                    uiDocumentSummaryPathInput
                                }
                                let done = executeDocumentCommand(owner, commandId, pathInput)
                                if (let Some(value2) <- done) {
                                    return finishDocumentCommandEvent("direct", commandId,
                                        value2, owner)
                                }
                        }
                    } else {
                        let owner = if (documentWorkspace.ownsCommand(commandId)) {
                            documentWorkspace
                        } else {
                            summaryWorkspace
                        }
                        let pathInput = if (documentWorkspace.ownsCommand(commandId)) {
                            uiDocumentPathInput
                        } else {
                            uiDocumentSummaryPathInput
                        }
                        let done = executeDocumentCommand(owner, commandId, pathInput)
                        if (let Some(value2) <- done) {
                            return finishDocumentCommandEvent("direct", commandId, value2, owner)
                        }
                    }
                }
            }
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "TOGGLE_VIEW_TOOLS") {
            viewToolsVisible = !viewToolsVisible
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "TOGGLE_COLUMN_EDITOR") {
            columnEditorVisible = !columnEditorVisible
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            (event.node.actionName == "OPEN_UI_WORKSPACE" ||
             event.node.actionName == "CLOSE_UI_WORKSPACE" ||
             event.node.actionName == "SELECT_UI_WORKSPACE_MAIN" ||
             event.node.actionName == "SELECT_UI_WORKSPACE_SUMMARY" ||
             event.node.actionName == "TOGGLE_DEVELOPER_INFO")) {
            if (event.node.actionName == "OPEN_UI_WORKSPACE") { uiWorkspaceVisible = true }
            else if (event.node.actionName == "CLOSE_UI_WORKSPACE") { uiWorkspaceVisible = false }
            else if (event.node.actionName == "SELECT_UI_WORKSPACE_MAIN") { uiWorkspaceSelection = "main" }
            else if (event.node.actionName == "SELECT_UI_WORKSPACE_SUMMARY") { uiWorkspaceSelection = "summary" }
            else { developerInfoVisible = !developerInfoVisible }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "SWAP_DOCUMENT_WORKSPACES") {
            workspacesSwapped = !workspacesSwapped
            revision += 1
            getStdOut().writeln("PRESET_WORKSPACES swapped=${workspacesSwapped}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "UI_CLOSE_SAVE_ALL") {
            let mainScope = documentWorkspace.semanticPrefix()
            let issue = uiCloseGuard.saveUnsaved({ workspace =>
                if (workspace.semanticPrefix() == mainScope) { uiDocumentPathInput }
                else { uiDocumentSummaryPathInput }
            })
            if (issue.size > 0) {
                uiCloseGuardNotice = "保存界面被拒：${issue}；可换路径另存，或取消关闭继续编辑"
                revision += 1
                getStdOut().writeln("PRESET_UI_CLOSE save_all refused=${issue}")
                getStdOut().flush()
                return CjguiComposableUiDispatchResult(false)
            }
            uiCloseGuardActive = false
            revision += 1
            // Saving is synchronous, but the close intention is only valid
            // for the state that was just saved: re-report before leaving so
            // a workspace that changed while the panel was open still blocks.
            let remaining = uiCloseGuard.settleAndReport()
            if (remaining.size > 0) {
                uiCloseGuardActive = true
                uiCloseGuardNotice = remaining
                revision += 1
                getStdOut().writeln("PRESET_UI_CLOSE save_all=reblocked reason=${remaining}")
                getStdOut().flush()
                return CjguiComposableUiDispatchResult(false)
            }
            getStdOut().writeln("PRESET_UI_CLOSE save_all=done closing")
            getStdOut().flush()
            closeCurrentOrRetryApplicationExit()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "UI_CLOSE_DISCARD") {
            // Discarding UI-document changes writes NOTHING; business drafts
            // are untouched and remain this application's own in-memory state.
            // The one-shot flag lets THIS close attempt pass the unsaved-UI
            // guard; the application close policy is still consulted.
            uiCloseGuard.discardUnsaved()
            uiCloseGuardActive = false
            revision += 1
            getStdOut().writeln("PRESET_UI_CLOSE discard_ui closing")
            getStdOut().flush()
            closeCurrentOrRetryApplicationExit()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "UI_CLOSE_CANCEL") {
            applicationExitIntent = false
            uiCloseGuardActive = false
            uiCloseGuardNotice = ""
            revision += 1
            getStdOut().writeln("PRESET_UI_CLOSE cancel")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "OPEN_LAYOUT_HELP" && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (layoutPopover.isOpen()) {
                layoutPopover.close()
            } else {
                let theme = currentTheme()
                layoutPopover.open(CjguiComposableUiNodeReference.manual(1601),
                    style: CjguiComposableUiStyle(fixedWidth: 300, padding: 12, gap: 8,
                        background: theme.card.background, border: theme.card.border, borderWidth: 1,
                        cornerRadius: 6))
            }
            revision += 1
            getStdOut().writeln("PRESET_LAYOUT_POPOVER open=${layoutPopover.isOpen()}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CLOSE_LAYOUT_HELP" && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            layoutPopover.close()
            revision += 1
            getStdOut().writeln("PRESET_LAYOUT_POPOVER open=false")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "DUPLEX_GENERATED_ONLY" && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            duplexGeneratedOnly = !duplexGeneratedOnly
            revision += 1
            getStdOut().writeln("PRESET_DUPLEX_MOUNT generatedOnly=${duplexGeneratedOnly}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "DUPLEX_OPTIONS_STAGE" && event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            // Cycle the field's live option list through the SAME declared
            // binding: disable the current option, delete it, then restore.
            // A removed current value is explained, never rewritten.
            duplexOptionsStage = (duplexOptionsStage + 1) % 3
            var items = ArrayList<CjguiSelectOption>()
            if (duplexOptionsStage == 1) {
                items.add(CjguiSelectOption("single", "单面", "false"))
                items.add(CjguiSelectOption("double", "双面", "true", enabled: false, disabledReason: "选项维护中"))
            } else if (duplexOptionsStage == 2) {
                items.add(CjguiSelectOption("single", "单面", "false"))
            } else {
                items = mixedDuplexOptions()
            }
            let issue = duplexSelectBinding.updateOptions(items)
            revision += 1
            getStdOut().writeln("PRESET_DUPLEX_OPTIONS stage=${duplexOptionsStage} issue=${issue} " +
                "draft=${duplexSelectBinding.currentValue()} label=${duplexSelectBinding.select.selectedLabel()}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(issue.size == 0)
        }
        if (let Some(result) <- duplexSelectBinding.applyUiEvent(event)) {
            var applied = result.didApply
            if (duplexSelect.isOpen()) { duplexTooltip.hide() }
            if (applied) {
                if (let Some(option) <- duplexSelectBinding.takeConfirmed()) {
                    let committed = duplexSelectBinding.commit(option)
                    let reason = if (committed) { "applied" } else { duplexSelectBinding.lastFailure() }
                    stepNotice = if (committed) {
                        "双面打印草稿已更新为 ${option.label}；应用后提交"
                    } else {
                        "选择被拒：${reason}"
                    }
                    stepKind = if (committed) { CJGUI_STATUS_SUCCESS } else { CJGUI_STATUS_ERROR }
                    getStdOut().writeln("PRESET_DUPLEX_SELECT key=${option.key} value=${option.value} " +
                        "applied=${committed} reason=${reason}")
                    getStdOut().flush()
                    applied = committed
                }
                revision += 1
            }
            if ((event.text == "shortcut:up" || event.text == "shortcut:down") && duplexSelect.isOpen()) {
                let local = duplexSelect.highlightedLocalKey()
                if (local.size > 0) {
                    if (let Some(value) <- window) {
                        let _ = value.focusScopedNode(duplexSelect.scopeKey(), local)
                    }
                }
            }
            return CjguiComposableUiDispatchResult(applied)
        }
        if (let Some(result) <- layoutPopover.applyUiEvent(event)) {
            revision += 1
            getStdOut().writeln("PRESET_LAYOUT_POPOVER open=${layoutPopover.isOpen()} " +
                "cause=${event.node.actionName}/${event.eventKind}")
            getStdOut().flush()
            return result
        }
        if (let Some(result) <- duplexTooltip.applyUiEvent(event)) {
            revision += 1
            getStdOut().writeln("PRESET_DUPLEX_TIP open=${duplexTooltip.isOpen()} kind=${event.eventKind}")
            getStdOut().flush()
            return result
        }
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
        if (let Some(applied) <- cardList.handleCommandEvent(event)) {
            getStdOut().writeln("PRESET_COLLECTION_COMMAND command=${event.text} applied=${applied} " +
                "status=[${cardList.viewStatus()}]")
            getStdOut().flush()
            revision += 1
            return CjguiComposableUiDispatchResult(applied)
        }
        if (let Some(applied) <- cardList.handleWorkspaceEvent(event)) {
            getStdOut().writeln("PRESET_COLLECTION_VIEW action=${event.node.actionName} " +
                "applied=${applied} mode=${cardList.viewMode()} status=[${cardList.viewStatus()}] " +
                "snapshotBytes=${cardList.encodedView().size} savedBytes=${cardList.savedView().size}")
            getStdOut().flush()
            revision += 1
            return CjguiComposableUiDispatchResult(applied)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            (event.node.actionName == "PREVIEW_RESOURCE_PNG" ||
            event.node.actionName == "PREVIEW_RESOURCE_JPEG" ||
            event.node.actionName == "PREVIEW_RESOURCE_JPEG2" ||
            event.node.actionName == "PREVIEW_RESOURCE_CORRUPT")) {
            // Ordinary view/资源 choice, not a business Apply: changing the
            // preview never commits an unrelated preset draft.
            if (event.node.actionName == "PREVIEW_RESOURCE_PNG") {
                previewResourceKey = "preview-swatch"
                previewResourceVersion = 1
            } else if (event.node.actionName == "PREVIEW_RESOURCE_JPEG") {
                previewResourceKey = "preview-jpeg"
                previewResourceVersion = 1
            } else if (event.node.actionName == "PREVIEW_RESOURCE_JPEG2") {
                previewResourceKey = "preview-jpeg-alt"
                previewResourceVersion = 1
            } else {
                previewResourceKey = "preview-corrupt"
                previewResourceVersion = 1
            }
            getStdOut().writeln("PRESET_PREVIEW_RESOURCE key=${previewResourceKey} " +
                "version=${previewResourceVersion}")
            getStdOut().flush()
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
        if (let Some(generated) <- region.handleEventIfClaimed(event)) {
            if (generated.didApply) {
                stepNotice = ""
                stepKind = CJGUI_STATUS_INFO
            }
            return generated
        }
        if (let Some(value) <- window) {
            // Only the exact accepted primary form target may enter this
            // separate route. A retired alias or altered card event cannot
            // borrow the primary owner's valid field declaration.
            let handled = if (matchesAcceptedPrimaryField(event, value)) {
                form.handleFormEvent(event, value)
            } else { CjguiComposableUiDispatchResult(false) }
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
                // Re-select the return anchor on EVERY open - the same
                // selection the command palette uses: the window's CURRENT
                // editing reference, else its current focus reference, else
                // the help trigger itself (node 73, mounted on every first
                // screen). Keeping the previous value can anchor the dialog
                // to a hidden node (the old default 101 sat in the developer
                // fold), and the framework then rejects the whole candidate
                // scene with identity_reference_invalid, so the help never
                // presents. The references keep their full scoped identity;
                // no arbitrary node id is wrapped into a manual reference.
                let editingReference: ?CjguiComposableUiNodeReference = match (window) {
                    case Some(value) => value.editingFocusReference()
                    case None => None
                }
                let focusedReference: ?CjguiComposableUiNodeReference = match (window) {
                    case Some(value) => value.focusedNodeReference()
                    case None => None
                }
                helpReturn = editingReference ?? focusedReference ??
                    CjguiComposableUiNodeReference.manual(73)
                helpReturnSelection = if (editingReference.isSome()) {
                    "editing-reference"
                } else if (focusedReference.isSome()) {
                    "focused-reference"
                } else {
                    "manual-73"
                }
                helpVisible = true
                pendingHelpIntent = "open"
                getStdOut().writeln("PRESET_HELP state=open return=${helpReturnSelection}")
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
                // The framework completes the return when the modal layer
                // leaves the accepted scene: it restores the layer anchor's
                // focus (and the owned session's selection through the same
                // restore transaction). No parallel restore lives here.
                helpVisible = false
                pendingHelpIntent = "close"
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
                let appliedSnapshot = domain.formSnapshot()
                getStdOut().writeln("PRESET_APPLY action=${event.node.actionName} applied=${result.applied} " +
                    "reason=${result.reason} draft=${appliedSnapshot.draftVersion} " +
                    "appliedVersion=${appliedSnapshot.appliedConfigVersion} " +
                    "jobName=[${appliedSnapshot.fieldForResourceId(6201).appliedValue.displayText()}] " +
                    "duplex=[${appliedSnapshot.fieldForResourceId(6203).appliedValue.displayText()}]")
                getStdOut().flush()
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
    public func bindApplicationExitRetry(retry: () -> Bool): Unit {
        applicationExitRetry = Some(MixedApplicationExitRetryAction(retry))
    }

    /// Provider-side probe: a refused decision leaves the application-exit
    /// intent on THIS window so the existing save/discard panel can hand the
    /// decision back to the application instead of closing only this window.
    public func requestApplicationExitDecision(): Bool {
        let decision = requestWindowClose()
        if (!decision.shouldClose) { applicationExitIntent = true }
        return decision.shouldClose
    }

    private func closeCurrentOrRetryApplicationExit(): Unit {
        if (applicationExitIntent) {
            applicationExitIntent = false
            if (let Some(retry) <- applicationExitRetry) {
                let allowed = retry.retry()
                getStdOut().writeln("PRESET_APP_EXIT retry allowed=${allowed}")
            } else {
                match (window) {
                    case Some(value) => let _ = value.requestCloseFromApplication()
                    case None => ()
                }
            }
            return
        }
        match (window) {
            case Some(value) => let _ = value.requestCloseFromApplication()
            case None => ()
        }
    }

    public func isWindowOpen(): Bool {
        match (window) {
            case Some(value) => value.isOpen()
            case None => false
        }
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        // UI-document facts settle first and are visible in the ordinary
        // refresh; the business close policy (this app has no extra business
        // gate) follows only when every workspace is clean. The system close
        // button, ⌘W and ⌘Q all arrive here.
        let blocking = uiCloseGuard.settleAndReport()
        if (blocking.size > 0) {
            uiCloseGuardActive = true
            uiCloseGuardNotice = blocking
            // The panel is at the top of the scroll page; bring it into view
            // in the same refresh that shows the blocked decision. A native
            // close request carries no input event, so it also has to wake the
            // ordinary scene loop explicitly.
            let _ = viewport.requestOffset(0)
            revision += 1
            if (let Some(value) <- window) { value.requestRefresh() }
            getStdOut().writeln("PRESET_UI_CLOSE blocked reason=${blocking}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(false, shouldClose: false)
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool {
        // Both regions open their transactions in the same scene commit, so a
        // candidate is either accepted everywhere or rolled back everywhere.
        if (!region.beginSceneRefresh()) { return false }
        if (!summaryRegion.beginSceneRefresh()) {
            region.rollbackSceneRefresh()
            return false
        }
        return true
    }
    public func prepareSceneRefresh(): Bool {
        if (!region.prepareSceneRefresh()) {
            summaryRegion.rollbackSceneRefresh()
            region.rollbackSceneRefresh()
            return false
        }
        if (!summaryRegion.prepareSceneRefresh()) {
            summaryRegion.rollbackSceneRefresh()
            region.rollbackSceneRefresh()
            return false
        }
        return true
    }
    private let countersTrace = getVariable("CJGUI_PRINT_COUNTERS_TRACE").isSome()

    public func commitSceneRefresh(): Unit {
        region.commitSceneRefresh()
        summaryRegion.commitSceneRefresh()
        // The help-layer change is now part of the accepted scene; the
        // controller's flag and the picture agree.
        pendingHelpIntent = ""
        if (countersTrace) {
            // Existing counters only; this reads them after the commit and
            // prints one line per real scene commit.
            getStdOut().writeln("CJGUI_MIXED_FORM_COUNTS ${region.testWorkCounts()} outcome=${region.sceneState()}")
            getStdOut().flush()
        }
    }
    public func rollbackSceneRefresh(): Unit {
        reconcileHelpIntentWithRejectedScene("")
        region.rollbackSceneRefresh()
        summaryRegion.rollbackSceneRefresh()
    }
    public func rollbackSceneRefresh(reason: String): Unit {
        reconcileHelpIntentWithRejectedScene(reason)
        region.rollbackSceneRefresh(reason)
        summaryRegion.rollbackSceneRefresh(reason)
    }

    /// A rejected candidate leaves NO accepted dialog: undo the in-flight
    /// help-layer change so `helpVisible` matches the screen again. The
    /// rejection itself is the framework's own fact (not swallowed, not
    /// relaxed); the user's click is answered with a state that can be
    /// retried, and no unrelated user state is cleared here.
    private func reconcileHelpIntentWithRejectedScene(reason: String): Unit {
        if (pendingHelpIntent == "open") {
            helpVisible = false
            pendingHelpIntent = ""
            getStdOut().writeln("PRESET_HELP state=open_rejected reason=${reason}")
            getStdOut().flush()
            revision += 1
        } else if (pendingHelpIntent == "close") {
            helpVisible = true
            pendingHelpIntent = ""
            getStdOut().writeln("PRESET_HELP state=close_rejected reason=${reason}")
            getStdOut().flush()
            revision += 1
        }
    }

    /// Verification accessors for the offline help-layer tests: the dialog's
    /// visibility flag and WHICH return-anchor branch the last OPEN_HELP
    /// selected ("manual-73" fallback, "editing-reference" or
    /// "focused-reference"). The branch is the wiring fact under test; the
    /// reference object itself stays opaque outside the framework package.
    public func isHelpLayerVisible(): Bool { return helpVisible }
    public func lastHelpReturnSelection(): String { return helpReturnSelection }
    public func setBusinessWidthOverrideForVerification(width!: ?Int64): Unit {
        businessWidthOverride = width
    }
    public func disposeSceneRefreshResources(): Unit {
        region.disposeSceneRefreshResources()
        summaryRegion.disposeSceneRefreshResources()
    }
    /// The handwritten detail of the collection's SELECTED object. It reads the
    /// same card (owner, declarations, drafts, validation, lock) the generated
    /// composite reads; the layout is app UI, the facts are the owner's.
    private func buildSelectedDetail(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let box = cjguiComposableVertical(900, "preset-detail", CjguiComposableUiStyle(gap: 8, padding: 14,
            minWidth: 280, growX: 1, border: theme.card.border, borderWidth: 1,
            cornerRadius: theme.card.cornerRadius))
        let key = domain.cards.selectedKey()
        // The handwritten selected-card editors are NOT generated composite
        // elements: without a declaration the range-session entry would
        // resolve them to the DEFAULT instance's provider (the root form
        // owner), whose owner never matches the card's frozen target. Refresh
        // the scene's staged aliases with the current selection on every
        // build. The existing scene hooks publish them only on acceptance,
        // or keep the old accepted range binding on rollback. The region's
        // provider-owner check still refuses any stale or wrong
        // alias, and the binding itself keeps every owner_target_retired and
        // calibration protection.
        region.clearHandwrittenInstanceAliases()
        summaryRegion.clearHandwrittenInstanceAliases()
        let card = match (domain.cards.card(key)) {
            case Some(value) => value
            case None =>
                box.add(cjguiComposableText(901, "preset-detail-title", "选中对象", theme.heading))
                box.add(cjguiComposableText(902, "preset-detail-empty", "没有选中对象", theme.body))
                return box
        }
        if (detailMode == "handwritten") {
            let fieldCount = domain.formBinding().fieldCount()
            for (index in 0..fieldCount) {
                let editorNodeId = 910 + index * 10
                region.declareHandwrittenInstanceAlias(editorNodeId, key)
                summaryRegion.declareHandwrittenInstanceAlias(editorNodeId, key)
            }
        }
        box.add(cjguiComposableText(901, "preset-detail-title", "选中对象 ${key} · ${card.ownerId}", theme.heading))
        let bar = cjguiComposableWrap(903, "preset-detail-toolbar", CjguiComposableUiStyle(gap: 6), rowGap: 4)
        bar.add(cjguiComposableButton(904, "preset-detail-mode",
            if (detailMode == "handwritten") { "切到生成详情" } else { "切到手写详情" },
            "TOGGLE_DETAIL_MODE", card.ownerId, theme.secondaryAction,
            interactionStyle: theme.secondaryActionInteraction))
        // The selected object's ONE primary action is Apply; Cancel/还原 is its
        // secondary counterpart from the SAME public role set.
        bar.add(cjguiComposableButton(905, "preset-detail-apply", "应用", "APPLY_DRAFT", card.ownerId,
            theme.primaryAction, enabled: card.actionAvailability("APPLY_DRAFT").isAvailable,
            operationActionName: "APPLY_DRAFT", interactionStyle: theme.primaryActionInteraction))
        bar.add(cjguiComposableButton(906, "preset-detail-cancel", "还原", "CANCEL_DRAFT", card.ownerId,
            theme.secondaryAction, enabled: card.actionAvailability("CANCEL_DRAFT").isAvailable,
            operationActionName: "CANCEL_DRAFT", interactionStyle: theme.secondaryActionInteraction))
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

    /// One document workspace area: the region's generated content, the five
    /// document actions and the path row, all sharing the workspace's scoped
    /// identity. Two areas mount the SAME public composition twice; only the
    /// area title and the workspace instance differ.
    private func buildDocumentArea(idBase: Int64, theme: CjguiComposableUiTheme, areaTitle: String,
        workspace: CjguiUiDocumentWorkspace, areaRegion: CjguiGeneratedUiWindowRegion,
        feedback: ?CjguiGeneratedUiFormFeedback, pathInput: String): CjguiComposableUiNode {
        let area = cjguiComposableVertical(idBase, "preset-doc-area-${workspace.semanticPrefix()}",
            CjguiComposableUiStyle(gap: 6, padding: 10, growX: 1, border: theme.card.border,
                borderWidth: 1, cornerRadius: theme.card.cornerRadius))
        area.add(cjguiComposableText(idBase + 1, "preset-doc-area-title-${workspace.semanticPrefix()}",
            "${areaTitle} · ${workspace.title()}", theme.heading))
        area.add(areaRegion.attachTransientLayers(areaRegion.buildNode(
            feedback: feedback)))
        area.add(workspace.build(
            CjguiComposableUiStyle(gap: 6, padding: 10, growX: 1, border: theme.card.border,
                borderWidth: 1, cornerRadius: theme.card.cornerRadius),
            theme.heading, theme.body, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction,
            ownerResourceId: PrintPresetDomain.ownerId))
        area.add(workspace.buildPathRow(pathInput,
            CjguiComposableUiStyle(fixedHeight: 30, growX: 1, border: theme.card.border,
                borderWidth: 1, cornerRadius: 6),
            theme.primaryAction, interactionStyle: theme.primaryActionInteraction,
            ownerResourceId: PrintPresetDomain.ownerId,
            inputInteractionStyle: theme.inputInteraction))
        return area
    }

    /// The visible close protection over BOTH document workspaces. The three
    /// actions are ordinary application buttons; the framework never closes
    /// the window or writes business data here.
    private func buildUiCloseGuardPanel(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let panel = cjguiComposableVertical(430, "preset-ui-close-guard",
            CjguiComposableUiStyle(gap: 8, padding: 12, growX: 1, border: theme.card.border,
                borderWidth: 1, cornerRadius: theme.card.cornerRadius))
        panel.add(cjguiComposableText(431, "preset-ui-close-guard-title",
            "关闭前的界面文档检查", theme.heading))
        panel.add(cjguiComposableText(432, "preset-ui-close-guard-reason",
            "${uiCloseGuardNotice}\n保存界面不会应用业务草稿；放弃界面变更也不会改动业务内容。",
            CjguiComposableUiStyle(fontSize: 12.5, textColor: theme.body.textColor,
                lineHeight: 18.0)))
        let bar = cjguiComposableWrap(433, "preset-ui-close-guard-actions",
            CjguiComposableUiStyle(gap: 6), rowGap: 4)
        bar.add(cjguiComposableButton(434, "preset-ui-close-guard-save",
            "保存界面并关闭", "UI_CLOSE_SAVE_ALL", PrintPresetDomain.ownerId,
            theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        bar.add(cjguiComposableButton(435, "preset-ui-close-guard-discard",
            "放弃界面变更并关闭", "UI_CLOSE_DISCARD", PrintPresetDomain.ownerId,
            theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        bar.add(cjguiComposableButton(436, "preset-ui-close-guard-cancel",
            "取消关闭", "UI_CLOSE_CANCEL", PrintPresetDomain.ownerId,
            theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        panel.add(bar)
        return panel
    }

    /// Executes one document command in ITS owning workspace. Open/save-as
    /// consume this workspace's current path string; the five stateful
    /// actions run through the same handleCommand the palette/menu use.
    private func executeDocumentCommand(workspace: CjguiUiDocumentWorkspace,
        commandId: String, pathInput: String): ?CjguiUiDocumentSessionResult {
        if (!workspace.ownsCommand(commandId)) { return None }
        if (let Some(done) <- workspace.handlePathCommand(commandId, pathInput)) {
            return Some(done)
        }
        return workspace.handleCommand(commandId)
    }

    /// One visible result for one executed document command, whichever
    /// channel (arrival/direct) delivered it.
    private func finishDocumentCommandEvent(channel: String, commandId: String,
        done: CjguiUiDocumentSessionResult,
        workspace: CjguiUiDocumentWorkspace): CjguiComposableUiDispatchResult {
        stepNotice = done.detail
        stepKind = if (done.applied) { CJGUI_STATUS_SUCCESS } else { CJGUI_STATUS_ERROR }
        getStdOut().writeln("PRESET_UI_DOCUMENT channel=${channel} command=${commandId} " +
            "applied=${done.applied} reason=${done.reason} submitted=${done.submitted} " +
            "accepted=${done.accepted} scope=${workspace.semanticPrefix()}")
        getStdOut().flush()
        revision += 1
        return CjguiComposableUiDispatchResult(done.applied)
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
        // Commands and their metadata belong to the CURRENT selected owner, not
        // the original 6200 demonstration form. The button already writes the
        // selected card's result; menu/shortcut availability must agree with it.
        let selectedCard = domain.cards.card(domain.cards.selectedKey())
        let currentOwner: Int64 = match (selectedCard) {
            case Some(card) => card.ownerId
            case None => PrintPresetDomain.ownerId
        }
        // The Apply/Cancel targets (905/906) live on the selected-card detail,
        // which mounts only on the business page. Declaring them while the
        // interface-document workspace is open names absent targets and the
        // window rejects the whole candidate (candidate_commands_invalid).
        if (!uiWorkspaceVisible) {
            for (action in domain.actionDescriptors()) {
                if (action.name != "APPLY_DRAFT" && action.name != "CANCEL_DRAFT") { continue }
                let availability = match (selectedCard) {
                    case Some(card) => card.actionAvailability(action.name)
                    case None => feedback.actionAvailability(action.name)
                }
                let id = "preset.${action.name}"
                // The visible target is the SELECTED detail's existing button;
                // the old demo action row is not on the default page.
                let target = if (action.name == "APPLY_DRAFT") { 905 } else { 906 }
                commands.add(CjguiComposableUiCommand(id, CjguiComposableUiNodeReference.manual(target),
                    action.displayName,
                    CjguiComposableUiShortcut(if (action.name == "APPLY_DRAFT") { "s" } else { "r" }),
                    "Edit", 0, availability.isAvailable, false))
                metadata.add(CjguiCommandToolbarMetadata(id, action.name, currentOwner,
                    detail: action.displayName, disabledReason: availability.reason))
            }
        }
        commands.add(CjguiComposableUiCommand("preset.theme", CjguiComposableUiNodeReference.manual(76),
            "浅色外观", CjguiComposableUiShortcut("t"), "View", 0, true, appearance.light, presentationOnly: true))
        metadata.add(CjguiCommandToolbarMetadata("preset.theme", "TOGGLE_THEME", PrintPresetDomain.ownerId,
            detail: "切换显示外观"))
        commands.add(CjguiComposableUiCommand("preset.help", CjguiComposableUiNodeReference.manual(73),
            "编辑说明", CjguiComposableUiShortcut("k"), "Help", 0, true, false))
        metadata.add(CjguiCommandToolbarMetadata("preset.help", "OPEN_HELP", PrintPresetDomain.ownerId))
        // The document commands come from the workspace's OWN projection
        // (derived from the real session action states); both workspaces
        // declare their scoped commands here without a second entries loop.
        // Exactly ONE document area mounts (buildUi selects main or summary);
        // publishing both workspaces' commands named the inactive area's
        // scoped targets, which is the second half of the same rejection.
        if (uiWorkspaceVisible && uiWorkspaceSelection != "summary") {
            for (declaration in documentWorkspace.commandDeclarations()) {
                commands.add(declaration)
            }
            for (entry in documentWorkspace.commandMetadata(PrintPresetDomain.ownerId)) {
                metadata.add(entry)
            }
        }
        if (uiWorkspaceVisible && uiWorkspaceSelection == "summary") {
            for (declaration in summaryWorkspace.commandDeclarations()) {
                commands.add(declaration)
            }
            for (entry in summaryWorkspace.commandMetadata(PrintPresetDomain.ownerId)) {
                metadata.add(entry)
            }
        }
        // The collection workspace publishes its OWN scoped commands; the
        // action bar nodes carry the matching scoped identity. They are
        // mounted only inside the "视图 / 列" fold, so the declarations join
        // the table with their controls: a declaration whose scoped target is
        // absent from the scene rejects the WHOLE candidate (the --commands
        // first frame failed on exactly this). Expanding the fold brings the
        // commands back; nothing is deleted.
        if (viewToolsVisible) {
            for (declaration in cardList.commandDeclarations()) {
                commands.add(declaration)
            }
            for (entry in cardList.commandMetadata(PrintPresetDomain.ownerId)) {
                metadata.add(entry)
            }
        }
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

    /// Called from the ordinary window turn loop. A confirmed reload is one
    /// submitted candidate; acceptance becomes visible here (and the caller
    /// refreshes) without a second, session-owned node tree. BOTH workspaces
    /// settle their own tickets; one workspace's in-flight operation never
    /// silences the other's.
    public func finishUiDocumentAction(value: CjguiComposableUiWindow): Unit {
        var changed = false
        for (workspace in [documentWorkspace, summaryWorkspace]) {
            let done = workspace.finish()
            if (done.reason == "ui_document_pending" ||
                done.reason == "ui_document_no_submission" ||
                done.reason == "ui_document_ticket_mismatch") { continue }
            changed = true
            if (done.startup) {
                getStdOut().writeln("CJGUI_MIXED_FORM_UI_DOCUMENT_BASELINE accepted=${done.accepted} " +
                    "reason=${done.reason} version=${done.version} token=${done.token} " +
                    "path=${done.path} file_sha=${done.fileDigest}")
            }
            getStdOut().writeln("PRESET_UI_DOCUMENT_SETTLED state=${done.reason} " +
                "accepted=${done.accepted} version=${workspace.surface().acceptedUiDocument().version} " +
                "saved=${workspace.session().savedDigest()} scope=${workspace.semanticPrefix()}")
            if (done.accepted) {
                getStdOut().writeln("PRESET_UI_DOCUMENT_ACCEPTED version=${workspace.surface().acceptedUiDocument().version} " +
                    "digest=${workspace.session().savedDigest()} scope=${workspace.semanticPrefix()}")
            }
        }
        if (changed) {
            revision += 1
            value.requestRefresh()
        }
        getStdOut().flush()
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
            // The generated region already publishes every open declared Select,
            // including the one the handwritten trigger presents. Adding the
            // controller's commands here as well duplicates ids and the window
            // rejects the whole candidate scene.
            for (command in region.generatedSceneCommands()) { declarations.add(command) }
            return declarations
        }
        return if (helpVisible) { ArrayList<CjguiComposableUiCommand>() } else {
            let declarations = ArrayList<CjguiComposableUiCommand>([
                CjguiComposableUiCommand("preset.help", 73, CjguiComposableUiShortcut("k"))])
            // The Apply shortcut targets the selected-card detail's toolbar,
            // which mounts on the business page (not only inside the developer
            // fold). In the interface-document workspace the toolbar is absent:
            // a declaration whose target left the scene rejects the whole
            // candidate (candidate_commands_invalid), so the command follows
            // the same mount. ⌘S stays available whenever Apply is visible.
            if (!uiWorkspaceVisible) {
                declarations.add(CjguiComposableUiCommand("preset.apply", 905,
                    CjguiComposableUiShortcut("s")))
            }
            for (command in region.generatedSceneCommands()) { declarations.add(command) }
            declarations
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
    // ONE app-declared owner set for the public card deck: every owner the
    // collection may currently hold (seeded, added or rebound) plus the two
    // declared REBIND_CARD demonstration targets. The domain re-checks that the
    // named owner is live for the operation, so this declaration does not turn
    // a deleted/retired id into a writable one.
    let presetTargets = ArrayList<Int64>([PrintPresetDomain.ownerId])
    for (target in PresetCardCollection.externalOwnerTargets()) { presetTargets.add(target) }
    scopes.add(CjguiSharedOperationExternalActionScope("REBIND_CARD",
        PresetCardCollection.externalOwnerTargets(), false))
    // Locking is owner state for the handwritten preset and every card; the
    // scope names exactly those objects.
    let lockTargets = ArrayList<Int64>([PrintPresetDomain.ownerId])
    for (target in PresetCardCollection.externalOwnerTargets()) { lockTargets.add(target) }
    scopes.add(CjguiSharedOperationExternalActionScope("SET_LOCK", lockTargets, false))
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

/// A4: the application owns process exit; this consumer supplies the business
/// decision by consulting EVERY live window's EXISTING close guard. It never
/// closes a window itself, so a later refusal leaves all windows usable.
/// A4 controlled seam: a live window's EXISTING close decision, without any
/// close side effect. Real windows adapt their controller; tests can supply a
/// bounded fake to pin "first allows, second refuses" with zero closes.
interface MixedExitWindowDecision {
    func isOpen(): Bool
    func requestCloseDecision(): Bool
}

class MixedControllerExitWindow <: MixedExitWindowDecision {
    private let controller: MixedFormController
    init(controller: MixedFormController) { this.controller = controller }
    public func isOpen(): Bool { return controller.isWindowOpen() }
    public func requestCloseDecision(): Bool {
        return controller.requestApplicationExitDecision()
    }
}

class MixedApplicationExitDecision <: CjguiMacosApplicationExitDecisionProvider {
    private let windows = ArrayList<MixedExitWindowDecision>()

    /// Closed controllers retire here; the set remains bounded by the actual
    /// live participants, not by every companion reopen ever attached.
    private func pruneClosed(): Unit {
        var index = windows.size - 1
        while (index >= 0) {
            if (!windows[index].isOpen()) { windows.remove(at: index) }
            index -= 1
        }
    }

    public func attach(controller: MixedFormController): Unit {
        pruneClosed()
        windows.add(MixedControllerExitWindow(controller))
    }

    /// Test-only injection at the exact decision list: production never calls
    /// this with anything but the live controller adapters above.
    func attachForTest(window: MixedExitWindowDecision): Unit {
        pruneClosed()
        windows.add(window)
    }

    public func requestApplicationExit(): Bool {
        pruneClosed()
        var consulted: Int64 = 0
        var index: Int64 = 0
        for (window in windows) {
            consulted += 1
            if (!window.requestCloseDecision()) {
                getStdOut().writeln("PRESET_APP_EXIT refused window=${index}")
                getStdOut().flush()
                return false
            }
            index += 1
        }
        getStdOut().writeln("PRESET_APP_EXIT allowed live=${consulted}")
        getStdOut().flush()
        return true
    }
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--check-composition") { return checkMixedComposition() }
    if (args.size == 1 && args[0] == "--check-font-resources") { return checkFontResources() }
    var collaboration = false
    var commands = false
    var fontResources = false
    var styledText = false
    var uiDocumentPath = ""
    var index: Int64 = 0
    while (index < args.size) {
        let arg = args[index]
        if (arg == "--collaboration" && !collaboration) { collaboration = true; index += 1 }
        else if (arg == "--commands" && !commands) { commands = true; index += 1 }
        else if (arg == "--fonts" && !fontResources) { fontResources = true; index += 1 }
        else if (arg == "--styled-text" && !styledText) { styledText = true; index += 1 }
        else if (arg == "--ui-document" && index + 1 < args.size && uiDocumentPath.size == 0) {
            uiDocumentPath = args[index + 1]
            index += 2
        } else { return 2 }
    }
    let domain = PrintPresetDomain()
    fontResources = fontResources || styledText
    commands = commands || fontResources
    let sharedFonts = PrintPresetFontResources(fontResources, styled: styledText)
    let controller = MixedFormController(domain, commandSurfaces: commands, fontResources: fontResources,
        styledText: styledText, sharedFonts: Some(sharedFonts), uiDocument: uiDocumentPath)
    let exitDecision = MixedApplicationExitDecision()
    let application = CjguiMacosApplication(maximumWindowCount: if (styledText) { 3 } else { 2 },
        exitDecisionProvider: exitDecision)
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
    exitDecision.attach(controller)
    controller.bindApplicationExitRetry({ => application.requestApplicationExit() })
    // Off until the explicit development button is used; no sampling loop.
    let inspector = CjguiMacosInspector(application, businessId)
    // A saved interface document needs the public generated region; request the
    // same collaboration connection the button would open.
    if (collaboration || uiDocumentPath.size > 0) {
        controller.requestCollaboration()
    }
    var pendingUiDocument = uiDocumentPath
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
            // A startup document is submitted only at an idle scene boundary
            // (never inside an in-flight transaction), through the ordinary
            // generated provider; a refusal leaves the default interface.
            if (pendingUiDocument.size > 0 && connection.isSome() && business.isOpen() &&
                business.windowProjection().acceptedSceneVersion > 0 &&
                controller.region.sceneTransactionIdle()) {
                let path = pendingUiDocument
                pendingUiDocument = ""
                if (!exists(Path(path))) {
                    // A new path is a SAVE TARGET; reading/validation of an
                    // existing document belongs only to the shared session.
                    getStdOut().writeln("CJGUI_MIXED_FORM_UI_DOCUMENT_SAVE_TARGET path=" + path)
                    getStdOut().flush()
                } else {
                    let submitted = controller.beginStartupUiDocument(path)
                    if (!submitted.applied) {
                        getStdErr().writeln("CJGUI_MIXED_FORM_UI_DOCUMENT_REJECTED reason=" + submitted.reason)
                        getStdErr().flush()
                    } else if (submitted.submitted) {
                        business.requestRefresh()
                    }
                }
            }
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
                        exitDecision.attach(peer)
                        peer.bindApplicationExitRetry({ => application.requestApplicationExit() })
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
            controller.finishUiDocumentAction(business)
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
