// Independent public consumer of the experimental generic tree view: a
// three-level knowledge catalog (领域 → 主题 → 条目) with a different data
// shape, row presentation and selection handling from the rule window.
// UI-only: it depends on the public cjgui package alone, keeps its own
// in-memory catalog, and never touches files or other applications.
package cjgui_ui_only_starter

import cjgui.*
import std.collection.*
import std.env.*
import std.time.*

/// The tree list is one virtual-list scroll node; native delivers keyboard
/// navigation (35) and wheel scrolling (30) on it.
let CJGUI_CATALOG_LIST_NODE_ID: Int64 = 27
/// One identity scope per projected row, keyed by the row's stable key.
let CJGUI_CATALOG_ROW_IDENTITY_SCOPE: CjguiComposableUiIdentityScope =
    CjguiComposableUiIdentityScope("catalog-rows")

public class CatalogSource <: CjguiComposableUiTreeDataSource &
    CjguiComposableUiTreeContentUpdateSource {
    public let domains: ArrayList<String>
    public let topicsPerDomain: Int64
    public let entriesPerTopic: Int64
    // Content-only overrides: the owner's current display label per stable key.
    // A rename changes no parent, order or kind, so the projection may patch the
    // row by key instead of rebuilding the whole logical tree.
    private let labels: HashMap<String, String> = HashMap<String, String>()
    private var contentVersionValue: Int64 = 0
    private var lastContentKeys: ArrayList<String> = ArrayList<String>()
    private var lastContentLabels: ArrayList<String> = ArrayList<String>()
    private var lastChangeDescribable: Bool = false

    public init(domains: ArrayList<String>, topicsPerDomain: Int64, entriesPerTopic: Int64) {
        this.domains = domains
        this.topicsPerDomain = topicsPerDomain
        this.entriesPerTopic = entriesPerTopic
    }

    static func domainKey(index: Int64): String {
        return "domain-${index}"
    }

    static func topicKey(domainIndex: Int64, topicIndex: Int64): String {
        return "domain-${domainIndex}-topic-${topicIndex}"
    }

    static func entryKey(domainIndex: Int64, topicIndex: Int64, entryIndex: Int64): String {
        return "domain-${domainIndex}-topic-${topicIndex}-entry-${entryIndex}"
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return domains.size }
        let numbers = numericSegments(parentKey)
        if (numbers.size == 1) { return topicsPerDomain }
        if (numbers.size == 2) { return entriesPerTopic }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        let numbers = numericSegments(parentKey)
        if (numbers.size == 0) {
            let key = domainKey(index)
            return CjguiComposableUiTreeNode(
                key, labelFor(key, domains[index]), 100 + index, true, selectable: false)
        }
        if (numbers.size == 1) {
            let domainIndex = numbers[0]
            let key = topicKey(domainIndex, index)
            return CjguiComposableUiTreeNode(
                key, labelFor(key, "主题 ${domainIndex}.${index}"),
                200 + domainIndex * 10 + index, true, selectable: false)
        }
        if (numbers.size == 2) {
            let domainIndex = numbers[0]
            let topicIndex = numbers[1]
            let key = entryKey(domainIndex, topicIndex, index)
            return CjguiComposableUiTreeNode(
                key, labelFor(key, "条目 ${domainIndex}.${topicIndex}.${index}"),
                300 + domainIndex * 100 + topicIndex * 10 + index, false, selectable: true)
        }
        return CjguiComposableUiTreeNode("missing", "missing", -1, false, selectable: false)
    }

    private func labelFor(key: String, fallback: String): String {
        if (let Some(value) <- labels.get(key)) {
            return value
        }
        return fallback
    }

    /// Owner-side content change: rename one existing domain/topic/entry. The
    /// parent, order and kind are untouched, so this is a content-only change.
    /// An unknown key is refused instead of silently creating a row.
    ///
    /// Identity is checked against the CANONICAL key rebuilt from the parsed
    /// segments, not against "the segments look plausible": parsing only the
    /// digit runs would accept `domain-0garbage` or `domain-0-topic-1-junk` as
    /// valid keys, bump the version and notify, while the real entry never
    /// changed. A refused key changes no label, no version and no notification.
    public func renameEntry(key: String, label: String): Bool {
        if (key.size == 0 || label.size == 0) {
            return false
        }
        let numbers = numericSegments(key)
        if (numbers.size == 0 || numbers[0] < 0 || numbers[0] >= domains.size) {
            return false
        }
        let canonical = match (numbers.size) {
            case 1 => domainKey(numbers[0])
            case 2 => topicKey(numbers[0], numbers[1])
            case 3 => entryKey(numbers[0], numbers[1], numbers[2])
            case _ => ""
        }
        if (canonical.isEmpty() || key != canonical) {
            return false
        }
        let isTopic = numbers.size == 2 && numbers[1] >= 0 && numbers[1] < topicsPerDomain
        let isEntry = numbers.size == 3 && numbers[1] >= 0 && numbers[1] < topicsPerDomain &&
            numbers[2] >= 0 && numbers[2] < entriesPerTopic
        if (!(numbers.size == 1 || isTopic || isEntry)) {
            return false
        }
        labels.add(key, label)
        lastContentKeys = ArrayList<String>([key])
        lastContentLabels = ArrayList<String>([label])
        lastChangeDescribable = true
        contentVersionValue += 1
        return true
    }

    /// An owner change that is NOT content-only (a row appears or disappears):
    /// the projection must rebuild.
    public func markStructuralChange(): Unit {
        lastContentKeys = ArrayList<String>()
        lastContentLabels = ArrayList<String>()
        lastChangeDescribable = false
        contentVersionValue += 1
    }

    public func contentVersion(): Int64 {
        return contentVersionValue
    }

    public func contentUpdates(sinceVersion: Int64): ?ArrayList<CjguiComposableUiTreeContentUpdate> {
        if (sinceVersion == contentVersionValue) {
            return Some(ArrayList<CjguiComposableUiTreeContentUpdate>())
        }
        if (sinceVersion == contentVersionValue - 1 && lastChangeDescribable) {
            let updates = ArrayList<CjguiComposableUiTreeContentUpdate>()
            var index: Int64 = 0
            while (index < lastContentKeys.size) {
                updates.add(CjguiComposableUiTreeContentUpdate(lastContentKeys[index], lastContentLabels[index]))
                index += 1
            }
            return Some(updates)
        }
        return None
    }

    // "domain-0-topic-1-entry-2" -> [0, 1, 2]
    func numericSegments(key: String): ArrayList<Int64> {
        let result = ArrayList<Int64>()
        if (!key.startsWith("domain-")) { return result }
        var value: Int64 = 0
        var hasDigits = false
        let chars = key.toArray()
        var index: Int64 = 0
        while (index < Int64(chars.size)) {
            let byte = chars[index]
            if (byte == 45) {  // '-'
                if (hasDigits) { result.add(value) }
                value = 0
                hasDigits = false
            } else if (byte >= 48 && byte <= 57) {
                value = value * 10 + Int64(byte - 48)
                hasDigits = true
            }
            index += 1
        }
        if (hasDigits) { result.add(value) }
        return result
    }
}

public class CatalogController <: CjguiComposableUiController {
    private let source: CatalogSource
    private let projection: CjguiComposableUiTreeProjection
    private let selection: CjguiComposableUiTreeSelection
    private let listState: CjguiComposableUiVirtualListState
    // The list source is kept so keyboard navigation can reveal an off-screen
    // focus target through the same virtual list the scene renders.
    private var activeListSource: ?CjguiComposableUiTreeListSource = None
    // Attached by the application so a model-side focus move can keep the
    // native focus on the row the tree model just focused.
    private var attachedWindow: ?CjguiComposableUiWindow = None
    private var revision: Int64 = 1
    // The SAME shared definitions the generated panels use, consumed here by a
    // UI-only consumer: one named style for the catalog surface + one declared
    // image resource (logical key/version, never a path this file invents), and
    // the window's own interaction projection. No server, descriptor or Agent is
    // involved, and adding another field/condition needs no second definition.
    private let styles: CjguiComposableUiNamedStyleCatalog = CjguiComposableUiNamedStyleCatalog()
    // The SAME shared dark theme the two application consumers already resolve.
    // The catalog's roles below carry PAINT ONLY, so a theme update moves every
    // title/body/status/action together without moving geometry or re-measuring
    // text, and this consumer never invents a second palette.
    private let theme: CjguiComposableUiTheme = CjguiComposableUiTheme.beaconDark()
    // The same public vertical viewport the other consumers use. This consumer
    // has no descriptor, UDS or model: it only shares the one published
    // container, and a keyboard focus that lands on a clipped control reveals it
    // through the framework instead of an application-specific offset.
    private let viewport = CjguiComposableUiScrollViewport()
    /// The UI-only workspace state: "目录" keeps the actions and the derived
    /// detail text, "条目" keeps the tree list. Which page is ACTIVE is window
    /// view state, exactly like the two application consumers.
    private let workspaceTabs: CjguiComposableUiTabsState = CjguiComposableUiTabsState("catalog")
    private let imageDeclarations: CjguiGeneratedUiCapabilityCatalog =
        CjguiGeneratedUiCapabilityCatalog()
    private var catalogIcon: ?CjguiGeneratedUiImageResourceSpec = None
    // This is a normal consumer parameter. The default catalog keeps its
    // ordinary compact detail text; the opt-in fixture exercises the same
    // public text node with a bounded, multi-thousand-character value.
    private let largeTextFixtureValue: Bool
    private let largeTextIdentityScope = CjguiComposableUiIdentityScope("catalog-large-text")

    public init(source: CatalogSource, largeTextFixture!: Bool = false) {
        this.source = source
        this.largeTextFixtureValue = largeTextFixture
        let treeProjection = CjguiComposableUiTreeProjection(source)
        // The source can prove content-only changes, so a rename patches the row
        // by key instead of re-walking the logical tree.
        treeProjection.attachContentUpdateSource(source)
        treeProjection.markSourceIndexCurrent()
        this.projection = treeProjection
        this.selection = CjguiComposableUiTreeSelection(treeProjection)
        this.listState = CjguiComposableUiVirtualListState()
        // The shared theme turned into the roles this dark surface needs. Every
        // colour comes from `beaconDark` (the theme the other consumers use), and
        // every role states its normal / focused / disabled paint, so the title,
        // body, status and action read on the dark catalog surface - default and
        // large-text alike - instead of falling back to the near-black default
        // text colour. Roles are PAINT ONLY: the node keeps its own font size
        // and geometry.
        let themeHeading = theme.heading
        let themeBody = theme.body
        let themeAction = theme.primaryAction
        let rowInteraction = CjguiComposableUiInteractionStyle(
            normal: CjguiComposableUiPaintStyle(textColor: Some(themeBody.textColor)),
            hover: CjguiComposableUiPaintStyle(background: theme.inputInteraction.selected.background,
                textColor: Some(themeHeading.textColor)),
            pressed: CjguiComposableUiPaintStyle(background: themeAction.background,
                textColor: Some(themeAction.textColor)),
            focused: theme.inputInteraction.focused,
            disabled: theme.inputInteraction.disabled,
            selected: CjguiComposableUiPaintStyle(background: theme.inputInteraction.selected.background,
                textColor: Some(themeHeading.textColor)),
            checked: theme.inputInteraction.checked)
        let titleInteraction = CjguiComposableUiInteractionStyle(
            normal: CjguiComposableUiPaintStyle(textColor: Some(themeHeading.textColor)),
            hover: CjguiComposableUiPaintStyle(textColor: Some(themeAction.textColor)),
            pressed: CjguiComposableUiPaintStyle(textColor: Some(themeAction.textColor)),
            focused: theme.inputInteraction.focused,
            disabled: theme.inputInteraction.disabled,
            selected: CjguiComposableUiPaintStyle(background: theme.inputInteraction.selected.background,
                textColor: Some(themeHeading.textColor)))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_surface",
            CjguiComposableUiStyle(padding: 10, gap: 6,
                background: CjguiComposableUiColor(0.06, 0.10, 0.16, 1.0),
                border: CjguiComposableUiColor(0.30, 0.50, 0.80, 1.0),
                textColor: themeBody.textColor),
            purpose: "目录面板表面"))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_title",
            CjguiComposableUiStyle(textColor: themeHeading.textColor, fontWeight: themeHeading.fontWeight),
            interaction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(textColor: Some(themeHeading.textColor)),
                focused: theme.inputInteraction.focused,
                disabled: theme.inputInteraction.disabled),
            purpose: "目录标题"))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_body",
            CjguiComposableUiStyle(textColor: themeBody.textColor),
            interaction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(textColor: Some(themeBody.textColor)),
                disabled: theme.inputInteraction.disabled),
            purpose: "目录正文"))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_status",
            CjguiComposableUiStyle(textColor: themeBody.textColor),
            interaction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(textColor: Some(themeBody.textColor)),
                disabled: theme.inputInteraction.disabled),
            purpose: "目录状态文字"))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_action",
            CjguiComposableUiStyle(background: themeAction.background, border: themeAction.border,
                textColor: themeAction.textColor, borderWidth: themeAction.borderWidth),
            interaction: theme.primaryActionInteraction, purpose: "目录操作按钮"))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_row",
            CjguiComposableUiStyle(textColor: themeBody.textColor),
            interaction: rowInteraction, purpose: "目录行控件"))
        let _ = this.styles.register(CjguiComposableUiNamedStyle("catalog_tab_title",
            CjguiComposableUiStyle(textColor: themeHeading.textColor, fontWeight: themeHeading.fontWeight),
            interaction: titleInteraction, purpose: "目录页签标题"))
        let _ = this.imageDeclarations.registerImageResource(
            CjguiGeneratedUiImageResourceSpec("catalog_icon", "PNG", 1, "目录图标",
                "composable-beacon.png"))
        this.catalogIcon = this.imageDeclarations.imageResourceFor("catalog_icon", 1)
    }

    /// The consumer's ONE shared style definition, exposed so a test and the
    /// export chain can prove it is really consumed rather than merely declared.
    public func namedStyles(): CjguiComposableUiNamedStyleCatalog {
        return styles
    }

    /// The framework's one-shot role consumption: interaction paint comes from
    /// the named style definition, never re-assembled here.
    private func roleInteraction(name: String): CjguiComposableUiInteractionStyle {
        return match (styles.forName(name)) {
            case Some(value) => value.interaction
            case None => CjguiComposableUiInteractionStyle()
        }
    }

    /// The framework's one-shot role consumption with this node's own geometry:
    /// `localStyle` keeps paint single-sourced in the named definition and the
    /// consumer only translates its local geometry into the optional overrides.
    private func roleStyle(name: String, fontSize!: Float64 = 0.0, fontWeight!: Int64 = -1,
        fixedHeight!: Int64 = 0, minHeight!: Int64 = 0, maxHeight!: Int64 = 0,
        growX!: Int64 = 0, growY!: Int64 = 0): CjguiComposableUiStyle {
        return match (styles.forName(name)) {
            case Some(value) => value.localStyle(
                fontSize: if (fontSize > 0.0) { Some(fontSize) } else { None<Float64> },
                fontWeight: if (fontWeight >= 0) { Some(fontWeight) } else { None<Int64> },
                fixedHeight: if (fixedHeight > 0) { Some(fixedHeight) } else { None<Int64> },
                minHeight: if (minHeight > 0) { Some(minHeight) } else { None<Int64> },
                maxHeight: if (maxHeight > 0) { Some(maxHeight) } else { None<Int64> },
                growX: if (growX > 0) { Some(growX) } else { None<Int64> },
                growY: if (growY > 0) { Some(growY) } else { None<Int64> })
            case None => CjguiComposableUiStyle()
        }
    }

    /// The UI-only workspace's shared tab view state. Switching a page is a WINDOW
    /// view fact, so it is exposed instead of being mirrored into the catalogue.
    public func workspaceState(): CjguiComposableUiTabsState {
        return workspaceTabs
    }

    /// Presents the selected workspace page on the next refresh. Returns false when
    /// the selection did not move.
    public func requestWorkspacePage(pageKey: String): Bool {
        if (!workspaceTabs.select(pageKey)) {
            return false
        }
        revision += 1
        return true
    }

    /// The declared image resource this consumer consumes (logical key/version,
    /// never a path invented at the call site).
    public func imageDeclaration(): ?CjguiGeneratedUiImageResourceSpec {
        return catalogIcon
    }

    /// The window's CURRENT interaction context read through the shared
    /// projection: the three focus facts stay distinct (`valid` / `unfocused` /
    /// `unknown`) and the revision travels with them. This is a READ — it writes
    /// nothing and authorizes nothing.
    public func interactionContext(): String {
        return match (attachedWindow) {
            case Some(window) =>
                let progress = window.windowProgress()
                "${progress.focusState}|${progress.focusedControlId}|${progress.interactionVersion}"
            case None => "unknown|none|0"
        }
    }

    /// Owner-side rename through the consumer, followed by a scene revision so
    /// the window repaints the patched row.
    public func renameEntry(key: String, label: String): Bool {
        if (!source.renameEntry(key, label)) {
            return false
        }
        revision += 1
        return true
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
    }

    public func buildUi(): CjguiComposableUiNode {
        let _ = syncWithData()
        // The surface paint/geometry comes from the SHARED named style: retuning
        // or renaming it in the catalogue moves this consumer too, with no local
        // copy of the colors.
        let surface = match (styles.forName("catalog_surface")) {
            case Some(value) => value.base
            case None => CjguiComposableUiStyle()
        }
        let scroll = cjguiComposableScrollArea(20, "catalog-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
        let section = cjguiComposableVertical(2000, "catalog-tree-section", surface)
        section.add(cjguiComposableText(21, "catalog-tree-title", "知识目录（树形多选）",
            roleStyle("catalog_title", fontSize: 15.0),
            interactionStyle: roleInteraction("catalog_title")))
        // The icon is mounted from the application's SHARED declaration: the
        // layout names the logical key/version, and replacing the raster is a new
        // version of that key instead of a path edited here.
        if (let Some(icon) <- catalogIcon) {
            section.add(cjguiComposableImage(29, "catalog-tree-icon", icon.rasterPath,
                CjguiComposableUiStyle(fixedWidth: 24, fixedHeight: 24, cornerRadius: 6,
                    clipsContent: true),
                imageResourceId: icon.key, imageResourceVersion: icon.version))
        }

        // The action row uses the shared action ROLE, so its normal, hover,
        // pressed, focused and disabled paint come from the same theme entry as
        // the other consumers' primary action; only the height is local.
        let actionInteraction = roleInteraction("catalog_action")
        let actions = cjguiComposableHorizontal(22, "catalog-tree-actions",
            CjguiComposableUiStyle(gap: 6))
        actions.add(cjguiComposableButton(23, "catalog-expand-all", "展开全部", "CATALOG_EXPAND_ALL", 1,
            roleStyle("catalog_action", fixedHeight: 28), interactionStyle: actionInteraction))
        actions.add(cjguiComposableButton(24, "catalog-collapse-all", "收起全部", "CATALOG_COLLAPSE_ALL", 2,
            roleStyle("catalog_action", fixedHeight: 28), interactionStyle: actionInteraction))
        actions.add(cjguiComposableButton(25, "catalog-select-all", "全选条目", "CATALOG_SELECT_ALL", 3,
            roleStyle("catalog_action", fixedHeight: 28), interactionStyle: actionInteraction))
        actions.add(cjguiComposableButton(26, "catalog-clear", "清空多选", "CATALOG_CLEAR", 4,
            roleStyle("catalog_action", fixedHeight: 28), interactionStyle: actionInteraction))
        // The public tab container turns this UI-only consumer into a workspace
        // too: "目录" keeps the shared-definition actions and the derived detail
        // text, "条目" keeps the tree list. All of it is the SAME framework
        // component the two application consumers use.
        let catalogPage = cjguiComposableVertical(70, "catalog-workspace-page", CjguiComposableUiStyle(gap: 6))
        let rowsPage = cjguiComposableVertical(71, "catalog-rows-page", CjguiComposableUiStyle(gap: 6))
        catalogPage.add(actions)

        // A bounded detail panel derived from the SAME projection. It is long
        // enough that the tree list below it falls outside a normal window: the
        // consumer keeps NO scroll arithmetic, so reaching the list is exactly
        // the shared viewport plus the framework's focus reveal.
        var details = if (largeTextFixtureValue) {
            "大文字正常数据夹具（同一树投影）"
        } else {
            "可见条目（同一投影）"
        }
        var detailIndex = 0
        let detailLimit = if (largeTextFixtureValue) { 96 } else { 18 }
        while (detailIndex < detailLimit) {
            let row = projection.rowAt(detailIndex % projection.rowCount())
            if (largeTextFixtureValue) {
                details = "${details}\n[正文 ${detailIndex}] ${row.key} · ${row.label}：这是应用正常数据中的一段较长文字，用于验证公开文本节点的身份、内容与几何尺寸在窗口中保持一致。"
            } else {
                details = "${details}\n${row.key} · ${row.label}"
            }
            detailIndex += 1
        }
        let detailSemanticId = if (largeTextFixtureValue) { "catalog-large-details" } else { "catalog-details" }
        // BOTH configurations resolve the SAME body role, so the default and the
        // large-text fixture can only differ in font size - never in readability.
        let detailStyle = roleStyle("catalog_body",
            fontSize: if (largeTextFixtureValue) { 18.0 } else { 11.0 })
        let detailIdentity: ?CjguiComposableUiIdentity = if (largeTextFixtureValue) {
            Some(largeTextIdentityScope.local("details"))
        } else {
            None
        }
        catalogPage.add(cjguiComposableText(64, detailSemanticId, details, detailStyle,
            interactionStyle: roleInteraction("catalog_body"), identity: detailIdentity))

        // Only viewport + overscan rows materialize: the expanded projection
        // is exposed through the existing fixed-row virtual list engine, and
        // each row builder receives the real projected row with its stable key.
        // Row declarations carry a scoped identity derived from that key, so
        // the window's identity registry allocates their node ids instead of a
        // hand-reserved numeric block per consumer.
        rowsPage.add(cjguiComposableVirtualList(CJGUI_CATALOG_LIST_NODE_ID, "catalog-tree-list", 28,
            catalogListSource(), listState, 30, 4, 6,
            CjguiComposableUiStyle(minHeight: 220, maxHeight: 320, background:
                CjguiComposableUiColor(0.04, 0.07, 0.11, 1.0))))

        let status = cjguiComposableText(63, "catalog-status",
            "多选 ${selection.selectedCount()} 条 · 可见 ${projection.rowCount()} 行 · 焦点 ${interactionContext()}",
            roleStyle("catalog_status", fontSize: 11.0),
            interactionStyle: roleInteraction("catalog_status"))
        catalogPage.add(status)
        let workspaceScope = CjguiComposableUiIdentityScope("catalog-workspace")
        let workspacePages = ArrayList<CjguiComposableUiTabPage>()
        workspacePages.add(CjguiComposableUiTabPage("catalog", "目录", catalogPage))
        workspacePages.add(CjguiComposableUiTabPage("rows", "条目", rowsPage))
        // The tabs container gets the page-title ROLE from the same catalogue:
        // the shared component keeps its geometry and takes the light title paint
        // plus its focused/disabled states, so "目录"/"条目" are readable on the
        // dark catalog surface without a second focus owner.
        section.add(cjguiComposableTabs(workspaceScope, "catalog-workspace", workspacePages, workspaceTabs,
            CjguiComposableUiStyle(growX: 1), titleHeight: 24,
            titleStyle: roleStyle("catalog_tab_title"),
            titleInteraction: roleInteraction("catalog_tab_title")))
        scroll.add(section)
        return scroll
    }

    /// Builds (and remembers) the tree list source. Row declarations carry a
    /// scoped identity derived from the row's stable key, so the window's
    /// identity registry allocates their node ids: there is no hand-reserved
    /// numeric block per consumer, two rows can never collide, and the same key
    /// keeps its identity across reorder, re-parenting and re-materialization.
    private func catalogListSource(): CjguiComposableUiTreeListSource {
        // Row paint comes from the shared row ROLE (light text on the dark list
        // surface, with the focused/selected/disabled states the list already
        // projects), so a row is readable on the same terms as the rest of the
        // catalog instead of using the near-black default.
        let rowInteraction = roleInteraction("catalog_row")
        let listSource = CjguiComposableUiTreeListSource(projection, selection,
            { row, isSelected, isFocused =>
                let rowScope = CJGUI_CATALOG_ROW_IDENTITY_SCOPE.child(row.key)
                var indentText = ""
                var depthIndex: Int64 = 0
                while (depthIndex < row.depth) {
                    indentText += "      "
                    depthIndex += 1
                }
                let line = cjguiComposableHorizontal(0, "catalog-vrow-${row.key}",
                    CjguiComposableUiStyle(gap: 4), identity: Some(rowScope.local("line")))
                line.add(cjguiComposableText(0, "catalog-vindent-${row.key}", indentText,
                    roleStyle("catalog_row", fontSize: 11.0), interactionStyle: rowInteraction,
                    identity: Some(rowScope.local("indent"))))
                if (row.isGroup) {
                    let marker = if (row.expanded) { "▾" } else { "▸" }
                    line.add(cjguiComposableButton(0, "catalog-vgroup-${row.key}",
                        "${marker} ${row.label}", "CATALOG_GROUP_TOGGLE", row.resourceId,
                        roleStyle("catalog_row", fixedHeight: 26), interactionStyle: rowInteraction,
                        identity: Some(rowScope.local("group"))))
                } else {
                    let mark = if (isSelected) { "◉" } else { "○" }
                    line.add(cjguiComposableButton(0, "catalog-vleaf-${row.key}",
                        "${mark} ${row.label}", "CATALOG_LEAF_TOGGLE", row.resourceId,
                        roleStyle("catalog_row", fixedHeight: 26), interactionStyle: rowInteraction,
                        ownerInteractionState: if (isSelected) { CjguiComposableUiInteractionState.SELECTED }
                            else { CjguiComposableUiInteractionState.NONE },
                        identity: Some(rowScope.local("leaf"))))
                }
                line
            })
        activeListSource = Some(listSource)
        return listSource
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // Keyboard navigation / scroll inside the tree focus scope. Native
        // delivers the command on the virtual-list scroll node (27) with the
        // key event's own modifiers, so Shift extends a range; the tree model
        // owns visible order, anchor and expand/collapse, and the list state
        // materializes an off-screen target instead of leaving it unreachable.
        if (event.eventKind == 35 && event.node.nodeId == CJGUI_CATALOG_LIST_NODE_ID) {
            let extendRange = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            let result = selection.navigate(event.text, extendRange)
            if (!result.didChange) {
                return CjguiComposableUiDispatchResult(false)
            }
            if (let Some(listSource) <- activeListSource) {
                let _ = listState.revealKey(listSource, result.focus)
            }
            // Keep native focus, tree focus and the materialized row consistent:
            // the row declaration's scoped identity is what the window resolves.
            if (let Some(window) <- attachedWindow) {
                let index = projection.indexForKey(result.focus)
                if (index >= 0) {
                    let row = projection.rowAt(index)
                    let localKey = if (row.isGroup) { "group" } else { "leaf" }
                    let _ = window.focusScopedNode(CJGUI_CATALOG_ROW_IDENTITY_SCOPE.child(result.focus), localKey)
                }
            }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && event.node.nodeId == CJGUI_CATALOG_LIST_NODE_ID) {
            let before = listState.scrollOffset()
            listState.scrollByViewport(event.text)
            if (listState.scrollOffset() == before) {
                return CjguiComposableUiDispatchResult(false)
            }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        // Focus (31) carries the same actionable row identity as activation.
        // Only an actual press (27) may mutate expansion or selection.
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.actionName == "CATALOG_GROUP_TOGGLE") {
            let key = keyForResource(event.node.resourceId)
            if (key.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let changed = projection.toggleExpand(key)
            if (changed) {
                selection.ensureFocusVisible()
                revision += 1
            }
            return CjguiComposableUiDispatchResult(changed)
        }
        if (event.node.actionName == "CATALOG_LEAF_TOGGLE") {
            let key = keyForResource(event.node.resourceId)
            if (key.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let command = (event.modifierFlags & CJGUI_UI_MODIFIER_COMMAND) != 0
            let shift = (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0
            selection.click(key, command, shift)
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_EXPAND_ALL") {
            expandAll()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_COLLAPSE_ALL") {
            collapseAll()
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_SELECT_ALL") {
            selection.selectAllVisible()
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.actionName == "CATALOG_CLEAR") {
            clearSelection()
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func selectedCount(): Int64 {
        return selection.selectedCount()
    }

    /// Exact public readback of the shared tree selection state. An external
    /// consumer (and the export chain) asserts keys, focus and anchor instead of
    /// a count, so a wrong row cannot hide behind the same total.
    public func selectedKeys(): ArrayList<String> {
        return selection.snapshot().keys
    }

    public func focusKey(): String {
        return selection.focus()
    }

    public func anchorKey(): String {
        return selection.anchor()
    }

    public func clearSelection(): Unit {
        selection.clearSelection()
        revision += 1
    }

    public func visibleRowCount(): Int64 {
        return projection.rowCount()
    }

    // Bulk expand/collapse: one expanded-set update and one projection
    // rebuild, so a 10k-node tree is never rebuilt once per group.
    public func expandAll(): Unit {
        if (projection.setExpandedBatch(projection.groupKeys(), true)) {
            selection.ensureFocusVisible()
            revision += 1
        }
    }

    public func collapseAll(): Unit {
        if (projection.setExpandedBatch(projection.groupKeys(), false)) {
            selection.ensureFocusVisible()
            revision += 1
        }
    }

    // Resolves the stable key of a projected row by its application resource
    // id. The id is only a lookup key into the accepted projection; the
    // selection/toggle always uses the real stable key.
    private func keyForResource(resourceId: Int64): String {
        var index: Int64 = 0
        while (index < projection.rowCount()) {
            let row = projection.rowAt(index)
            if (row.resourceId == resourceId) {
                return row.key
            }
            index += 1
        }
        return ""
    }

    private func syncWithData(): Unit {
        // Content-only change: patch the changed rows by key (no walk). Anything
        // structural or undescribable still takes the rebuild path.
        if (projection.refreshContentOnly()) {
            return
        }
        let _ = projection.rebuild()
        projection.markSourceIndexCurrent()
    }
}

private func largeTextFixtureEnabled(): Bool {
    if (let Some(value) <- getVariable("CJGUI_TREE_OUTLINE_TEXT_FIXTURE")) {
        return value == "large" || value == "large-text" || value == "1"
    }
    return false
}

private func acceptedNode(window: CjguiComposableUiWindow, semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

main(): Int64 {
    let domains = ArrayList<String>(["绘制", "布局", "输入"])
    let source = CatalogSource(domains, 3, 3)
    let largeTextFixture = largeTextFixtureEnabled()
    let controller = CatalogController(source, largeTextFixture: largeTextFixture)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 知识目录", 640u32, 520u32)
    )
    controller.attachWindow(host.window())
    if (!host.start()) { return 2 }
    // The READY line publishes the SHARED facts this UI-only consumer actually
    // consumed: its named style, its declared image resource (logical key/version)
    // and the window's own interaction context. Nothing here needs a server, a
    // descriptor or an Agent.
    let iconToken = match (controller.imageDeclaration()) {
        case Some(value) => "${value.key}@${value.version}"
        case None => "none"
    }
    let styleToken = match (controller.namedStyles().forName("catalog_surface")) {
        case Some(value) => value.name
        case None => "none"
    }
    println("TREE_OUTLINE_CONSUMER_READY rows=${controller.visibleRowCount()} " +
        "style=${styleToken} image=${iconToken} fixture=${if (largeTextFixture) { "large-text" } else { "default" }} " +
        "focus=${controller.interactionContext()}")
    getStdOut().flush()
    if (largeTextFixture) {
        let before = acceptedNode(host.window(), "catalog-large-details")
        let beforeIdentity = before.identityKey
        let beforeValueSize = before.value.size
        let beforeHeight = before.bounds.height
        let renamed = controller.renameEntry("domain-0", "验收重命名")
        let refreshed = host.window().refresh()
        let after = acceptedNode(host.window(), "catalog-large-details")
        println("TREE_OUTLINE_CONSUMER_LARGE_TEXT node_id=${before.nodeId} identity=${beforeIdentity} " +
            "value_size=${beforeValueSize} width=${before.bounds.width} height=${beforeHeight} " +
            "rename=${renamed} refreshed=${refreshed} identity_same=${after.identityKey == beforeIdentity} " +
            "value_changed=${after.value != before.value} after_size=${after.value.size}")
        getStdOut().flush()
        if (let Some(value) <- getVariable("CJGUI_TREE_OUTLINE_ACCEPTANCE_ONESHOT")) {
            if (value == "1") {
                host.close()
                return 0
            }
        }
    }
    // Pump the public application loop until the window closes; this is the
    // same host the handwritten examples use, so the tree rows, expansion and
    // multi-selection all re-render through the ordinary scene path.
    while (host.isOpen()) {
        let _ = host.pumpOneTurn()
    }
    return 0
}
