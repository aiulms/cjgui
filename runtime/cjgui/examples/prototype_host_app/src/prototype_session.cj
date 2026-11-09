package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.fs.*

// Button text uses a 6pt top/bottom inset. These heights keep a complete line
// box for both rows (12pt title, 11pt meta) instead of reusing label insets.
let PROTOTYPE_RECORD_TITLE_HEIGHT: Int64 = 28
let PROTOTYPE_RECORD_META_HEIGHT: Int64 = 26
let PROTOTYPE_RECORD_ROW_HEIGHT: Int64 = PROTOTYPE_RECORD_TITLE_HEIGHT + PROTOTYPE_RECORD_META_HEIGHT + 4

private func prototypeRowMix(a: CjguiComposableUiColor, b: CjguiComposableUiColor, amount: Float64): CjguiComposableUiColor {
    return CjguiComposableUiColor(a.red + (b.red - a.red) * amount, a.green + (b.green - a.green) * amount,
        a.blue + (b.blue - a.blue) * amount, 1.0)
}

/// 生成式区域绑定：把框架的标准表单绑定接到「当前选中的原型对象」。
///
/// 这不是第二套表单实现：`CjguiGeneratedUiFormBinding` 仍是字段写入、范围文本
/// 会话、草稿版本与反馈的唯一实现；本类只在**选择变化**时把同一实现重新接到
/// 新的 owner 上，并拒绝把写请求派给已经退役的旧 owner。
class PrototypeRegionBinding <: CjguiGeneratedUiRegionBinding {
    private let domain: PrototypeProjectDomain
    private var current: CjguiGeneratedUiFormBinding
    private var selectBindings: ArrayList<CjguiSelectFieldBinding>
    private var boundOwner: Int64

    init(domain: PrototypeProjectDomain) {
        this.domain = domain
        this.selectBindings = prototypeSelectBindings(domain)
        this.current = CjguiGeneratedUiFormBinding(domain.activeObject(), domain.activeObject().ownerId,
            selectBindings: this.selectBindings)
        this.boundOwner = domain.activeObject().ownerId
    }

    /// 选中对象变化或项目声明变化后重接。旧 owner 的写请求不再被解析到新对象：
    /// 框架在换绑时会看到不同的 ownerTarget 并重新绑定文本会话。
    func rebind(): Unit {
        this.selectBindings = prototypeSelectBindings(domain)
        this.current = CjguiGeneratedUiFormBinding(domain.activeObject(), domain.activeObject().ownerId,
            selectBindings: this.selectBindings)
        this.boundOwner = domain.activeObject().ownerId
    }

    func currentOwner(): Int64 {
        return domain.activeObject().ownerId
    }

    func referenceSelectBindings(): ArrayList<CjguiSelectFieldBinding> {
        return selectBindings
    }

    /// 标准表单词表由框架的 `CjguiGeneratedUiFormBinding` 生成：字段约束、select
    /// 选项与 Apply/Cancel 动作都来自同一份 owner 声明，宿主不另写一套目录。
    func capabilityCatalogForHost(): CjguiGeneratedUiCapabilityCatalog {
        return current.capabilityCatalog(maxDepth: 10, maxNodes: 96, maxStringLength: 512)
    }

    public func ownerRevision(): Int64 {
        return current.ownerRevision()
    }

    public func fieldResourceId(fieldId: String): Int64 {
        return current.fieldResourceId(fieldId)
    }

    public func fieldOperationResourceId(fieldId: String): Int64 {
        return current.fieldOperationResourceId(fieldId)
    }

    public func draftText(fieldId: String): String {
        return current.draftText(fieldId)
    }

    public func appliedText(fieldId: String): String {
        return current.appliedText(fieldId)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return current.draftBoolean(fieldId)
    }

    public func appliedBoolean(fieldId: String): ?Bool {
        return current.appliedBoolean(fieldId)
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return current.fieldAvailability(fieldId)
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return current.actionAvailability(actionName)
    }

    public func actionAvailable(actionName: String): Bool {
        return current.actionAvailable(actionName)
    }

    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        return current.formFeedback()
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        if (actionName == "APPLY_DRAFT" || actionName == "CANCEL_DRAFT") {
            return current.executeAction(actionName, nodeKey)
        }
        // 项目声明的动作先到项目 owner，再按其类型派发。
        let (ok, reason) = domain.performDeclaredAction(actionName)
        return CjguiGeneratedUiActionResult(ok, reason)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return current.applyFieldIntent(intent)
    }

    public func generatedSelectBinding(fieldId: String): ?CjguiSelectFieldBinding {
        return current.generatedSelectBinding(fieldId)
    }

    public func generatedSelectBindings(): ArrayList<CjguiSelectFieldBinding> {
        return current.generatedSelectBindings()
    }

    public func draftSource(fieldId: String): String {
        return current.draftSource(fieldId)
    }

    public func rangeTextEditSupported(fieldId: String): Bool {
        return current.rangeTextEditSupported(fieldId)
    }

    public func fieldTextVersion(fieldId: String): Int64 {
        return current.fieldTextVersion(fieldId)
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String): CjguiRangeTextEditOutcome {
        return current.applyTextEdit(fieldId, expectedVersion, newText)
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool): Bool {
        return current.confirmFieldTextVersion(fieldId, expectedVersion, action)
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        return current.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte)
    }
}

/// 每个 select 字段一条公共选择绑定：选项、呈现与提交闭包都来自同一份字段声明。
func prototypeSelectBindings(domain: PrototypeProjectDomain): ArrayList<CjguiSelectFieldBinding> {
    return prototypeSelectBindingsForProject(domain.project, domain)
}

func prototypeSelectBindingsForProject(project: PrototypeProject,
    domain: PrototypeProjectDomain): ArrayList<CjguiSelectFieldBinding> {
    let bindings = ArrayList<CjguiSelectFieldBinding>()
    for (field in project.fields) {
        if (!field.isSelect()) {
            continue
        }
        let domainRef = domain
        let fieldId = field.id
        let binding = CjguiSelectFieldBinding(fieldId, "prototype-select-${fieldId}", "prototype-${fieldId}",
            ArrayList<CjguiSelectOption>(field.options),
            commit: { option =>
                domainRef.activeObject().setSelectValue(fieldId, option.value)
            }, searchable: false)
        bindings.add(binding)
    }
    return bindings
}

/// 手写 chrome 的虚拟列表源：记录来自项目声明；行只为本轮可见窗口构建。
class PrototypeListSource <: CjguiComposableUiVirtualListSource {
    private let domain: PrototypeProjectDomain
    private let epoch: Int64
    // Row paint comes from the active theme: a hard-coded black label is
    // unreadable on the dark card, and the selected tint must follow accent.
    private let theme: CjguiComposableUiTheme

    init(domain: PrototypeProjectDomain, epoch: Int64, theme: CjguiComposableUiTheme) {
        this.domain = domain
        this.epoch = epoch
        this.theme = theme
    }

    public func itemCount(): Int64 {
        domain.visibleIndices().size
    }

    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        let visible = domain.visibleIndices()
        if (index < 0 || index >= visible.size) {
            return CjguiComposableUiVirtualListItem.missing()
        }
        let recordIndex = visible[index]
        let record = domain.project.recordSet.records[recordIndex]
        return CjguiComposableUiVirtualListItem(record.key, recordIndex, record.title)
    }

    public func indexForKey(key: String): Int64 {
        let visible = domain.visibleIndices()
        var position: Int64 = 0
        for (index in visible) {
            if (domain.project.recordSet.records[index].key == key) {
                return position
            }
            position += 1
        }
        return -1
    }

    /// 列表配方：主标题一行 + 次行信息（稳定 id · 数量 · 状态）都由声明数据派生。
    /// 次行是普通 label，点击时控制器按 semanticId 前缀路由到同一次选择，整行都可用。
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        let record = domain.project.recordSet.records[item.resourceId]
        let nodeId = epoch * 100000 + item.resourceId * 8 + 1
        let surface = theme.card.background
        let bodyText = theme.body.textColor
        let selectedText = theme.heading.textColor
        let selectedBackground = prototypeRowMix(surface, theme.primaryAction.background, 0.14)
        let metaText = prototypeRowMix(surface, bodyText, 0.75)
        let row = cjguiComposableVertical(nodeId, "prototype-record-row-${item.key}",
            CjguiComposableUiStyle(growX: 1, fixedHeight: PROTOTYPE_RECORD_ROW_HEIGHT, gap: 0, padding: 2,
                cornerRadius: 5,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, background: if (isSelected) {
                    selectedBackground
                } else {
                    CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)
                }))
        let titleStyle = CjguiComposableUiStyle(growX: 1, fixedHeight: PROTOTYPE_RECORD_TITLE_HEIGHT,
            padding: 2, fontSize: 12.0,
            fontWeight: if (isSelected) { 500 } else { 400 },
            textColor: if (isSelected) { selectedText } else { bodyText },
            textMaxLines: 1, textOverflow: "ellipsis")
        row.add(cjguiComposableButton(nodeId + 1, "prototype-record-${item.key}", item.title, "SELECT_RECORD",
            item.resourceId, titleStyle, semanticHelp: "选择记录 ${item.title}",
            ownerInteractionState: if (isSelected) {
                CjguiComposableUiInteractionState.SELECTED
            } else {
                CjguiComposableUiInteractionState.NONE
            }))
        // R8: the secondary line is a BUTTON carrying the same SELECT_RECORD
        // action and record resource as the title, so both lines (the whole
        // visible row) enter the one existing selection handler. No new list
        // state machine and no global "labels are clickable" change.
        row.add(cjguiComposableButton(nodeId + 2, "prototype-record-meta-${item.key}",
            prototypeRecordRowMeta(domain.project, record), "SELECT_RECORD", item.resourceId,
            CjguiComposableUiStyle(growX: 1, fixedHeight: PROTOTYPE_RECORD_META_HEIGHT, padding: 2, fontSize: 11.0,
                textColor: metaText, textMaxLines: 1,
                textOverflow: "ellipsis"),
            semanticHelp: "选择记录 ${item.title}"))
        return row
    }
}

/// 一个原型项目的运行期会话：owner、主题、能力目录、生成式区域与界面文档会话，
/// 以及 chrome 的视图状态（列表视口/列表状态）。切换项目 = 换一个会话，
/// 不是改编译好的整页。
class PrototypeSession {
    var project: PrototypeProject
    let domain: PrototypeProjectDomain
    let binding: PrototypeRegionBinding
    let catalog: CjguiGeneratedUiCapabilityCatalog
    let region: CjguiGeneratedUiWindowRegion
    let documentSession: CjguiGeneratedUiDocumentSession
    let workspace: CjguiUiDocumentWorkspace
    let listViewport: CjguiComposableUiScrollViewport
    let listState: CjguiComposableUiVirtualListState
    let cardViewport: CjguiComposableUiScrollViewport
    var theme: CjguiComposableUiTheme
    var dark: Bool
    var revisionValue: Int64 = 1
    var startupDocumentPending: Bool = false
    var notice: String = ""

    init(project: PrototypeProject, dark: Bool) {
        this.project = project
        this.dark = dark
        this.theme = if (dark) {
            CjguiComposableUiTheme.higDark()
        } else {
            CjguiComposableUiTheme.higLight()
        }
        this.domain = PrototypeProjectDomain(project)
        this.binding = PrototypeRegionBinding(domain)
        let catalog = prototypeBuildCatalog(project, binding, theme)
        this.catalog = catalog
        this.region = CjguiGeneratedUiWindowRegion(catalog, binding, "prototype-${project.id}")
        // A/R1: the workspace keeps a real undo/redo history so session-scoped
        // document identity (surface/epoch/digest/version) is exercised by the
        // host, not only by unit tests.
        this.documentSession = CjguiGeneratedUiDocumentSession(path: project.uiDocumentPath,
            historyPolicy: Some(CjguiUiDocumentHistoryPolicy()))
        this.workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("prototype-${project.id}"),
            "ui-document", this.documentSession, this.region, title: "原型界面文档")
        this.listViewport = CjguiComposableUiScrollViewport()
        this.listState = CjguiComposableUiVirtualListState()
        this.cardViewport = CjguiComposableUiScrollViewport()
    }

    func close(): Unit {
        workspace.closeHistory()
    }

    func bump(): Unit {
        revisionValue += 1
    }

    func sceneVersion(): Int64 {
        return revisionValue + domain.revision() + region.revision()
    }

    /// 亮/暗切换只换角色取值并重发同名命名样式；已接受结构不重新提交。
    func setDark(value: Bool): Unit {
        if (dark == value) {
            return
        }
        dark = value
        theme = if (dark) {
            CjguiComposableUiTheme.higDark()
        } else {
            CjguiComposableUiTheme.higLight()
        }
        synchronizeNamedStyles(catalog, theme)
        bump()
    }

    /// 兼容修改：同一项目新增字段时，项目声明、能力目录、真实 owner、校验与绑定同步更新；
    /// 同 id 同类型字段保留 draft/applied/fieldVersion，新字段用声明默认值初始化。
    /// 不支持的变化以具名原因拒绝，且不改变任何已有状态。
    func adoptDeclaration(updated: PrototypeProject): String {
        let issue = prototypeDeclarationAdoptionIssue(project, updated)
        if (issue.size > 0) {
            return issue
        }
        let added = ArrayList<PrototypeFieldDeclaration>()
        var nextResourceId: Int64 = 1000
        for (field in project.fields) {
            if (field.resourceId >= nextResourceId) {
                nextResourceId = field.resourceId + 10
            }
        }
        let merged = ArrayList<PrototypeFieldDeclaration>(project.fields)
        for (field in updated.fields) {
            if (project.fieldIndex(field.id) >= 0) {
                continue
            }
            let assigned = PrototypeFieldDeclaration(field.id, field.label, field.kind, field.group, field.help,
                field.errorText, field.placeholder, field.required, field.minimum, field.maximum,
                field.maximumLength, ArrayList<CjguiSelectOption>(field.options),
                ArrayList<String>(field.optionValues), field.defaultValue, nextResourceId, field.sourceField,
                field.readonly)
            nextResourceId += 10
            merged.add(assigned)
            added.add(assigned)
        }
        if (added.size == 0 && updated.title == project.title) {
            return "declaration_unchanged"
        }
        let nextProject = prototypeProjectWithFields(project, updated.title, merged)
        // 注册前把能失败的都先查清：重复字段、缺少的标准组件、select 选项重复。
        for (field in added) {
            if (catalog.fieldFor(field.id).isSome()) {
                return "field_registration_failed:duplicate:${field.id}"
            }
        }
        let kindIssue = prototypeEnsureFieldKindComponents(catalog, added)
        if (kindIssue.size > 0) {
            return kindIssue
        }
        let nextDeclarations = prototypeFormBinding(nextProject)
        let nextSelects = prototypeSelectBindingsForProject(nextProject, domain)
        // 以下步骤在预检通过后执行；字段/选项注册失败时报告并交由调用方保留旧项目，
        // owner 尚未改动（adopt 放在最后）。
        for (field in added) {
            if (!catalog.registerField(prototypeFieldSpecFor(field))) {
                return "field_registration_failed:${field.id}:${catalog.registrationIssue()}"
            }
        }
        for (field in added) {
            if (!field.isSelect()) {
                continue
            }
            if (!catalog.registerChoiceOptions(field.id, ArrayList<CjguiSelectOption>(field.options))) {
                return "choice_registration_failed:${field.id}:${catalog.registrationIssue()}"
            }
            var bound = false
            for (candidate in nextSelects) {
                if (candidate.fieldId == field.id) {
                    bound = catalog.bindChoiceOptions(field.id, candidate)
                }
            }
            if (!bound) {
                return "choice_binding_failed:${field.id}"
            }
        }
        if (!domain.adoptDeclaration(nextProject, nextDeclarations)) {
            return "declaration_adopt_failed"
        }
        this.project = nextProject
        bump()
        notice = "已载入项目声明更新：新增 ${added.size} 个字段（未重启、未重编译）"
        return "declaration_updated:${added.size}"
    }
}

/// 生成式字段声明：与 `CjguiGeneratedUiFormBinding` 的目录词表使用同一字段身份与约束。
func prototypeFieldSpecFor(field: PrototypeFieldDeclaration): CjguiGeneratedUiFieldSpec {
    return CjguiGeneratedUiFieldSpec(field.id, field.label, field.editorKind(), field.resourceId,
        minimum: field.minimum, maximum: field.maximum, required: field.required,
        maximumLength: field.maximumLength,
        argumentName: if (field.editorKind() == "BOOLEAN") { "value" } else { "text" },
        declaredInputKind: if (field.isSelect()) { "select" } else { "" })
}

/// 运行期新增字段可能首次引入某个叶子类型：按既有生成式词表补齐对应组件。
/// 这是接入层的注册，不新造组件；已存在的组件不重复注册。
func prototypeEnsureFieldKindComponents(catalog: CjguiGeneratedUiCapabilityCatalog,
    added: ArrayList<PrototypeFieldDeclaration>): String {
    let needed = ArrayList<String>()
    for (field in added) {
        let kind = if (field.isSelect()) { "select" } else if (field.editorKind() == "BOOLEAN") {
            "booleanInput"
        } else if (field.editorKind() == "INTEGER") {
            "integerInput"
        } else {
            "textInput"
        }
        if (!needed.contains(kind)) {
            needed.add(kind)
        }
    }
    let hasSelect = needed.contains("select")
    for (kind in needed) {
        if (catalog.componentFor(kind).isSome()) {
            continue
        }
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        if (kind == "select") {
            properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
            properties.add(CjguiGeneratedUiPropertySpec("placeholder", "STRING", maxLength: 80))
            properties.add(CjguiGeneratedUiPropertySpec("searchable", "BOOLEAN", defaultValue: "false"))
        } else {
            properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
            properties.add(CjguiGeneratedUiPropertySpec("labelVisible", "BOOLEAN", defaultValue: "true"))
            if (kind == "integerInput") {
                properties.add(CjguiGeneratedUiPropertySpec("stepper", "BOOLEAN", defaultValue: "false"))
            }
        }
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            properties.add(property)
        }
        if (!catalog.registerComponent(CjguiGeneratedUiComponentSpec(kind, properties, false))) {
            return "component_registration_failed:${kind}:${catalog.registrationIssue()}"
        }
    }
    if (hasSelect && catalog.componentFor("radioGroup").isNone()) {
        if (!catalog.registerComponent(cjguiGeneratedRadioGroupComponent())) {
            return "component_registration_failed:radioGroup"
        }
    }
    if (hasSelect && catalog.componentFor("segmented").isNone()) {
        if (!catalog.registerComponent(cjguiGeneratedSegmentedComponent())) {
            return "component_registration_failed:segmented"
        }
    }
    return ""
}

/// 主题角色一次性注册进能力目录：手写与生成式消费同一批命名样式。
func synchronizeNamedStyles(catalog: CjguiGeneratedUiCapabilityCatalog, theme: CjguiComposableUiTheme): Unit {
    for (role in theme.namedStyles()) {
        if (catalog.namedStyles().forName(role.name).isSome()) {
            let _ = catalog.namedStyles().update(role)
        } else {
            let _ = catalog.namedStyles().register(role)
        }
    }
}

/// 宿主为项目生成的能力目录：标准表单词表 + 公共工作区原语 + 图片资源 +
/// HIG 主题角色 + 项目声明的动作 + 宿主 chrome 动作（不会伪装成业务动作）。
func prototypeBuildCatalog(project: PrototypeProject, binding: PrototypeRegionBinding,
    theme: CjguiComposableUiTheme): CjguiGeneratedUiCapabilityCatalog {
    let catalog = binding.capabilityCatalogForHost()
    let issue = CjguiGeneratedUiWorkspaceCatalog.registerInto(catalog, includeImage: true)
    if (issue.size > 0) {
        throw Exception(issue)
    }
    synchronizeNamedStyles(catalog, theme)
    for (asset in project.assets()) {
        let spec = CjguiGeneratedUiImageResourceSpec(asset[0], asset[1], 1, asset[0], asset[2])
        if (!catalog.registerImageResource(spec)) {
            throw Exception("image_resource_registration:${asset[0]}")
        }
    }
    for (action in project.actions) {
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec(action.name, action.label))
    }
    return catalog
}

