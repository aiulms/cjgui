// 设置与计数：首个跨平台（macOS + 鸿蒙）同源消费者。
//
// 领域规则只有这一份（仓颉 owner）：
//  - 计数范围 0–99，越界拒绝且不产生部分写入；
//  - 启用开关关闭时增减动作被拒绝；
//  - 人（按钮/开关）与外部（INVOKE）进入同一 execute，遵守同一版本契约。
//
// 控制器把这套规则投影为 CJGUI 组件树（中文标题、数值、增减按钮、
// 启用开关、状态提示与混排样例）；宿主差异不进入本文件。

package cjgui_settings_counter_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.random.*
import std.sync.*
import std.time.*
import std.unicode.*

/// 已应用的真实业务状态（无草稿层：设置类动作直接生效）。
public class CjguiSettingsCounterSnapshot {
    public let version: Int64
    public let count: Int64
    public let enabled: Bool
    public let name: String
    public let alias: String
    public let scrollNote: String
    public let imageVersion: Int64
    public init(version: Int64, count: Int64, enabled: Bool, name: String, alias: String,
        scrollNote: String, imageVersion: Int64) {
        this.version = version; this.count = count; this.enabled = enabled; this.name = name
        this.alias = alias
        this.scrollNote = scrollNote
        this.imageVersion = imageVersion
    }
}

public class CjguiSettingsCounterDomain <: CjguiSharedOperationDomain & CjguiSharedOperationChangeDomain {
    public static let resourceId: Int64 = 9700
    public static let counterMin: Int64 = 0
    public static let counterMax: Int64 = 99
    // 双字段表单：同一后端，多条不同的业务规则。
    // name：1–32 个 Unicode scalar；alias：1–8 个 Unicode scalar；
    // scrollNote：1–32 个 Unicode scalar（手写滚动区内编辑器，验证滚动后
    // 编辑与 owner 读回）。
    public static let nameMaxUnits: Int64 = 32
    public static let aliasMaxUnits: Int64 = 8
    public static let scrollNoteMaxUnits: Int64 = 32

    private var versionValue: Int64
    private var countValue: Int64
    private var enabledValue: Bool
    private var nameValue: String
    private var aliasValue: String
    private var scrollNoteValue: String
    private var imageVersionValue: Int64
    private var imageCatalog: ?CjguiGeneratedUiCapabilityCatalog
    private let streamIdentity: String
    private let changeLog: ArrayList<CjguiSharedOperationChangeEntry>
    // 可选的重启缓存路径：只有平台适配层给出私有沙箱路径时才落盘；
    // 没有路径（例如单元测试或未配置的消费者）时行为与原来完全一致。
    private let statePath: Option<String>
    private let stateStore: CjguiSettingsCounterStateStore
    public var lastPersistReason: String = "settings_state_not_configured"

    public init(persistPath!: Option<String> = None) {
        this.versionValue = 0
        this.countValue = 10
        this.enabledValue = true
        this.nameValue = "我的设备"
        this.aliasValue = "前台"
        this.scrollNoteValue = "滚动备注"
        this.imageVersionValue = 1
        this.imageCatalog = None
        this.statePath = persistPath
        this.stateStore = CjguiSettingsCounterStateStore()
        this.lastPersistReason = "settings_state_not_configured"
        // 每次启动的 capability 均为新发；把它编入流标识，防止重启后
        // 调用方把数值版本当作同一游标续读。
        this.streamIdentity = "settings_counter_stream_${Random().nextUInt64()}"
        this.changeLog = ArrayList<CjguiSharedOperationChangeEntry>()
        if (let Some(path) <- persistPath) {
            if (let Some(saved) <- this.stateStore.load(path)) {
                this.versionValue = saved.version
                this.countValue = saved.count
                this.enabledValue = saved.enabled
                this.nameValue = saved.name
                this.aliasValue = saved.alias
                this.scrollNoteValue = saved.scrollNote
                this.imageVersionValue = saved.imageVersion
            }
            this.lastPersistReason = this.stateStore.lastReason
        }
    }

    public func resourceType(): String { return "settings_counter" }

    public func counterSnapshot(): CjguiSettingsCounterSnapshot {
        return CjguiSettingsCounterSnapshot(versionValue, countValue, enabledValue, nameValue, aliasValue,
            scrollNoteValue, imageVersionValue)
    }

    public func imageResourceSpec(): CjguiGeneratedUiImageResourceSpec {
        return CjguiSettingsCounterImage.spec(imageVersionValue)
    }

    public func bindImageCatalog(catalog: CjguiGeneratedUiCapabilityCatalog): Unit {
        imageCatalog = Some(catalog)
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(versionValue, "设置与计数", resourceType(),
            ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(CjguiSettingsCounterDomain.resourceId, "计数器",
                    ArrayList<CjguiSharedOperationField>([
                        CjguiSharedOperationField("count", CjguiSharedOperationValue.integer(countValue)),
                        CjguiSharedOperationField("enabled", CjguiSharedOperationValue.boolean(enabledValue)),
                        CjguiSharedOperationField("counterRange", CjguiSharedOperationValue.string("0-99")),
                        CjguiSharedOperationField("name", CjguiSharedOperationValue.string(nameValue)),
                        CjguiSharedOperationField("alias", CjguiSharedOperationValue.string(aliasValue)),
                        CjguiSharedOperationField("scrollNote", CjguiSharedOperationValue.string(scrollNoteValue)),
                        CjguiSharedOperationField("imageVersion", CjguiSharedOperationValue.integer(imageVersionValue))
                    ]))
            ]))
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            CjguiSharedOperationActionDescriptor("INCREMENT", "计数加一",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("DECREMENT", "计数减一",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("SWITCH_IMAGE", "切换设置标志图",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("SET_ENABLED", "设置启用开关",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("value", "BOOLEAN", true)
                ]), 1, 1),
            CjguiSharedOperationActionDescriptor("EDIT_NAME", "编辑设备名称",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("text", "STRING", true)
                ]), 1, 1),
            CjguiSharedOperationActionDescriptor("EDIT_ALIAS", "编辑设备别名",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("text", "STRING", true)
                ]), 1, 1),
            CjguiSharedOperationActionDescriptor("EDIT_SCROLL_NOTE", "编辑滚动备注",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("text", "STRING", true)
                ]), 1, 1)
        ])
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(invocation)
    }

    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>,
        expectedStreamIdentity: String): CjguiSharedOperationChanges {
        if ((expectedStreamIdentity.size > 0 && expectedStreamIdentity != streamIdentity) || sinceVersion < 0 ||
            sinceVersion > versionValue) {
            return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, true,
                ArrayList<CjguiSharedOperationChangeEntry>())
        }
        let changes = ArrayList<CjguiSharedOperationChangeEntry>()
        for (entry in changeLog) {
            if (entry.version > sinceVersion && (resourceFilter.size == 0 ||
                resourceFilter[0] == CjguiSettingsCounterDomain.resourceId)) {
                changes.add(entry)
            }
        }
        return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, false, changes)
    }

    // 唯一的业务执行入口：人与外部共用，规则与原子性只在这里。
    private func execute(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = versionValue
        if (invocation.targetResourceIds.size != 1 ||
            invocation.targetResourceIds[0] != CjguiSettingsCounterDomain.resourceId) {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_target")
        }
        if (invocation.expectedVersion != versionValue) {
            return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict")
        }
        if (invocation.actionName == "INCREMENT") {
            return applyCount(before, countValue + 1)
        }
        if (invocation.actionName == "DECREMENT") {
            return applyCount(before, countValue - 1)
        }
        if (invocation.actionName == "SWITCH_IMAGE") {
            let nextVersion: Int64 = if (imageVersionValue == 1) { 2 } else { 1 }
            if (let Some(catalog) <- imageCatalog) {
                if (!catalog.updateImageResource(CjguiSettingsCounterImage.spec(nextVersion))) {
                    return rejected(before, false, catalog.lastRegistrationRejection())
                }
            }
            imageVersionValue = nextVersion
            versionValue += 1
            recordChange("image_changed")
            return accepted(before, "image_changed")
        }
        if (invocation.actionName == "EDIT_NAME") {
            for (argument in invocation.arguments) {
                if (argument.name == "text" && argument.value.valueType == "STRING") {
                    let next = argument.value.stringValue
                    // 唯一 owner 规则的单位与公共 FieldSpec 相同：Unicode scalar。
                    if (unicodeScalarCount(next) == 0 ||
                        unicodeScalarCount(next) > CjguiSettingsCounterDomain.nameMaxUnits) {
                        return rejected(before, false, "name_out_of_range")
                    }
                    nameValue = next
                    versionValue += 1
                    recordChange("name_changed")
                    return accepted(before, "name_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        if (invocation.actionName == "EDIT_ALIAS") {
            for (argument in invocation.arguments) {
                if (argument.name == "text" && argument.value.valueType == "STRING") {
                    let next = argument.value.stringValue
                    // 别名规则：非空且不超过 8 个 Unicode scalar（与 name 不同，
                    // 只有这一份定义；人与外部走同一入口）。
                    if (unicodeScalarCount(next) == 0 ||
                        unicodeScalarCount(next) > CjguiSettingsCounterDomain.aliasMaxUnits) {
                        return rejected(before, false, "alias_out_of_range")
                    }
                    aliasValue = next
                    versionValue += 1
                    recordChange("alias_changed")
                    return accepted(before, "alias_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        if (invocation.actionName == "EDIT_SCROLL_NOTE") {
            for (argument in invocation.arguments) {
                if (argument.name == "text" && argument.value.valueType == "STRING") {
                    let next = argument.value.stringValue
                    // 滚动备注规则：非空且不超过 32 个 Unicode scalar；人与
                    // 外部走同一入口（滚动区内编辑器与公开客户端共用）。
                    if (unicodeScalarCount(next) == 0 ||
                        unicodeScalarCount(next) > CjguiSettingsCounterDomain.scrollNoteMaxUnits) {
                        return rejected(before, false, "scroll_note_out_of_range")
                    }
                    scrollNoteValue = next
                    versionValue += 1
                    recordChange("scroll_note_changed")
                    return accepted(before, "scroll_note_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        if (invocation.actionName == "SET_ENABLED") {
            for (argument in invocation.arguments) {
                if (argument.name == "value" && argument.value.valueType == "BOOLEAN") {
                    enabledValue = argument.value.booleanValue
                    versionValue += 1
                    recordChange(if (enabledValue) { "counter_enabled" } else { "counter_disabled" })
                    return accepted(before, "counter_enabled_state_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        return rejected(before, false, "invalid_action")
    }

    private func applyCount(before: Int64, next: Int64): CjguiSharedOperationActionResult {
        if (!enabledValue) {
            return rejected(before, false, "counter_disabled")
        }
        if (next < CjguiSettingsCounterDomain.counterMin || next > CjguiSettingsCounterDomain.counterMax) {
            // 越界拒绝：不产生部分业务写入。
            return rejected(before, false, "counter_out_of_range")
        }
        countValue = next
        versionValue += 1
        recordChange("counter_changed")
        return accepted(before, "counter_changed")
    }

    private func recordChange(kind: String) {
        changeLog.add(CjguiSharedOperationChangeEntry(versionValue, CjguiSettingsCounterDomain.resourceId, kind))
        persistAcceptedState()
    }

    // 接受后的状态是唯一权威；落盘只是重启缓存。写入失败不回滚业务，
    // 也不冒充成功：原因保留在 lastPersistReason 供诊断读取。
    private func persistAcceptedState(): Unit {
        match (statePath) {
            case Some(path) =>
                let ok = stateStore.save(path, CjguiSettingsCounterSnapshot(versionValue, countValue, enabledValue,
                    nameValue, aliasValue, scrollNoteValue, imageVersionValue))
                lastPersistReason = stateStore.lastReason
                let _ = ok
            case None => lastPersistReason = "settings_state_not_configured"
        }
    }

    private func accepted(before: Int64, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(true, false, before, versionValue, reason)
    }

    private func rejected(before: Int64, conflict: Bool, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, conflict, before, before, reason)
    }

    private func unicodeScalarCount(value: String): Int64 {
        var count: Int64 = 0
        for (scalar in value.runes()) {
            let _ = scalar
            count += 1
        }
        return count
    }
}

/// 授权：外部 Agent 可读业务与生成界面，并调用同一组 owner 动作。
public func settingsCounterAuthorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization("设置与计数本地 Agent", "cjgui-settings-counter-agent-20260925",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", all, true),
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("INCREMENT", all, true),
            CjguiSharedOperationExternalActionScope("DECREMENT", all, true),
            CjguiSharedOperationExternalActionScope("SWITCH_IMAGE", all, true),
            CjguiSharedOperationExternalActionScope("SET_ENABLED", all, true),
            CjguiSharedOperationExternalActionScope("EDIT_NAME", all, true),
            CjguiSharedOperationExternalActionScope("EDIT_ALIAS", all, true),
            CjguiSharedOperationExternalActionScope("EDIT_SCROLL_NOTE", all, true)
        ]))
}

/// Table rows over the already-published owner fields. Read-only projection:
/// the table never writes owner state, and row activation only selects locally.
class CjguiSettingsFieldRowSource <: CjguiComposableUiVariableHeightListSource {
    private let rows: Array<CjguiComposableUiVariableHeightListItem>
    init(rows: Array<CjguiComposableUiVariableHeightListItem>) { this.rows = rows }
    public func itemCount(): Int64 { return rows.size }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= rows.size) { return CjguiComposableUiVariableHeightListItem.missing() }
        return rows[index]
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < rows.size) {
            if (rows[index].key == key) { return index }
            index += 1
        }
        return -1
    }
    public func measurementGeneration(): Int64 { return 0 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(-1, "settings-field-row-${item.key}", item.title,
            CjguiComposableUiStyle(fixedHeight: 26))
    }
}

/// 集合列表视图的行内容：字段名可激活按钮 + 当前 owner 值。选中/焦点只画在
/// 本地行上；选中事实仍由共同 CjguiComposableUiCollectionSelection 持有。
class CjguiSettingsFieldCardRowSource <: CjguiComposableUiVariableHeightListSource {
    private let rows: Array<CjguiComposableUiVariableHeightListItem>
    private let valueOf: (String) -> String
    init(rows: Array<CjguiComposableUiVariableHeightListItem>, valueOf: (String) -> String) {
        this.rows = rows
        this.valueOf = valueOf
    }
    public func itemCount(): Int64 { return rows.size }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= rows.size) { return CjguiComposableUiVariableHeightListItem.missing() }
        return rows[index]
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < rows.size) {
            if (rows[index].key == key) { return index }
            index += 1
        }
        return -1
    }
    public func measurementGeneration(): Int64 { return 0 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        let selected = isSelected || isFocused
        let root = CjguiComposableUiIdentityScope("settings-field-card")
        let row = cjguiComposableHorizontal(-1, "settings-field-card-${item.key}",
            CjguiComposableUiStyle(fixedHeight: 30, growX: 1, padding: 4, gap: 6,
                background: if (selected) {
                    CjguiComposableUiColor(0.20, 0.32, 0.52, 1.0)
                } else {
                    CjguiComposableUiColor(0.09, 0.12, 0.20, 1.0)
                }, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
            identity: Some(root.child("rows").local(item.key)))
        row.add(cjguiComposableButton(-1, "settings-field-card-select-${item.key}", item.title,
            "SELECT_FIELD", item.resourceId,
            CjguiComposableUiStyle(fixedWidth: 70, fixedHeight: 26, fontSize: 11.5,
                background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0)),
            identity: Some(root.child("cells").child(item.key).local("select"))))
        row.add(cjguiComposableText(-1, "settings-field-card-value-${item.key}", valueOf(item.key),
            CjguiComposableUiStyle(growX: 1, fixedHeight: 26, fontSize: 11.5,
                textColor: if (selected) {
                    CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)
                } else {
                    CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0)
                }, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
            identity: Some(root.child("cells").child(item.key).local("value"))))
        return row
    }
}

/// 控制器：把领域状态投影为 CJGUI 组件树；人机共用同一身份与样式。
/// 节点身份固定（1/10/11/12/20/21/22/23/30，控制 id 均低于 200）。
public class CjguiSettingsCounterController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiBusinessOwnerRevisionProvider {
    public static let nodeIdDecrement: Int64 = 21
    public static let nodeIdIncrement: Int64 = 22
    public static let nodeIdEnabled: Int64 = 23
    public static let nodeIdName: Int64 = 24
    public static let nodeIdAlias: Int64 = 25
    public static let nodeIdImage: Int64 = 31
    public static let nodeIdImageSwitch: Int64 = 32
    // C（h-source-preview-next）：样式阶段循环按钮（本地 UI 状态，不经 owner）。
    public static let nodeIdStylePhase: Int64 = 34
    // H 触摸滚动区（手写视口）：滚动区容器/内容与区内控件。
    public static let nodeIdHandScroll: Int64 = 900
    public static let nodeIdHandScrollImage: Int64 = 940
    public static let nodeIdHandScrollIncrement: Int64 = 941
    public static let nodeIdHandScrollNote: Int64 = 942
    public static let nodeIdHandScrollDecrement: Int64 = 943
    // 手写滚动视口：与生成 scrollArea 共用核心同一 viewport 机制。
    public let handScrollViewport: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()
    // C（触摸包指导接续）：屏外 reveal 的显式目标导航——应用内导航按钮经
    // 公共 focusAcceptedSemanticNode 请求滚动区内编辑器（reveal→新 accepted
    // 几何→正确系统上下文→输入→owner）。宿主循环在 pump 后消费挂起请求。
    public static let nodeIdFocusNoteNav: Int64 = 944
    // 集合/表格：手写滚动区内的字段表（读取既有 owner 字段，不改业务状态）。
    public static let nodeIdFieldTable: Int64 = 950
    public static let nodeIdFieldTableNav: Int64 = 951
    // 集合：共同 CjguiGeneratedUiCollection 的列表/表格两种呈现，工作区状态
    // （模式/列/排序/视图快照）由 CjguiCollectionWorkspace 持有。视图快照只存
    // 本进程内存，不写业务状态，也不替代 cjgui.ui-document。
    public static let nodeIdFieldCollection: Int64 = 960
    public static let nodeIdFieldCollectionNav: Int64 = 961
    // 生成区宿主：动态生成树放在有界滚动视口的内容侧；内容高度由共同布局
    // 按自然高度求解，根节点不再作为有界竖排容器的可收缩子项被压到 0。
    public static let nodeIdGeneratedScroll: Int64 = 895
    public static let nodeIdGeneratedContent: Int64 = 896
    // 公共界面文档工作区（会话/预览/保存/恢复）挂在手写滚动内容里。
    public static let nodeIdUiDocumentPanel: Int64 = 897
    public static let nodeIdUiDocumentNavRow: Int64 = 898
    public static let nodeIdUiDocumentNav: Int64 = 899
    // 平台可选的正常退出入口：仅在平台显式开启时出现，动作由平台注入。
    public static let nodeIdExitApp: Int64 = 905
    private let collectionRows: Array<CjguiComposableUiVariableHeightListItem>
    private let collectionViewState: CjguiComposableUiCollectionViewState
    private let collectionWorkspace: CjguiCollectionWorkspace
    private let collectionSelection = CjguiComposableUiCollectionSelection()
    private let collectionValues = HashMap<String, String>()
    private let collectionMountScope = CjguiComposableUiIdentityScope("settings-field-collection-mount")
    private var collectionColumnEditorVisible: Bool = false
    private var collectionViewSnapshot: String = ""
    private var selectedFieldKey: String = ""
    private let fieldTableListState = CjguiComposableUiVirtualListState()
    private var pendingFocusSemantic: ?String = None

    public func requestFocusSemantic(semanticId: String): Unit {
        pendingFocusSemantic = Some(semanticId)
    }

    public func takePendingFocusRequest(): ?String {
        let pending = pendingFocusSemantic
        pendingFocusSemantic = None
        return pending
    }

    // H2：滚动物理策略与活动由**窗口**拥有；样例不再逐个枚举视口，也不再有
    // 全局开关。宿主声明策略（`configureScrollPhysicsToken`）并只调
    // `window.stepWindowActivities`。
    private let domain: CjguiSettingsCounterDomain
    private let generatedRegion: CjguiGeneratedUiWindowRegion
    // 公共界面文档会话：打开/预览/确认/保存/恢复都走共同 workspace；文件路径
    // 由平台适配层给出的应用沙箱提供，框架不解释业务内容。
    private let uiDocumentSession: CjguiGeneratedUiDocumentSession
    private let uiDocumentWorkspace: CjguiUiDocumentWorkspace
    private let uiDocumentCloseGuard: CjguiUiDocumentCloseGuard
    private var uiDocumentPathText: String
    private let generatedScrollViewport: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()
    private var localRevision: Int64
    private var statusText: String
    private let showExitApp: Bool
    private let exitRequest: () -> Unit
    // C：样式阶段（0 混合 → 1 修改 → 2 倒置 → 3 重叠 → 4 超 64 → 5 清除）。
    // 纯 UI 声明状态：非法批次的拒绝与保旧都发生在框架渲染器，这里只负责
    // 把每阶段的声明真实送到同一条 wire。
    private var styleRunsPhase: Int64

    public init(domain: CjguiSettingsCounterDomain, uiDocumentPath!: Option<String> = None,
        showExitApp!: Bool = false, exitRequest!: () -> Unit = { => }) {
        this.domain = domain
        this.showExitApp = showExitApp
        this.exitRequest = exitRequest
        let region = CjguiGeneratedUiWindowRegion(settingsGeneratedCatalog(domain),
            CjguiSettingsCounterGeneratedBinding(domain), "settings-generated")
        this.generatedRegion = region
        // H 只提供沙箱路径与生命周期时机；打开/预览/确认/保存/恢复、脏态与
        // 文件保护都归公共 UI document session。没有路径时工作区只展示状态，
        // 不写任何默认文件。
        let documentPath = match (uiDocumentPath) {
            case Some(path) => path
            case None => ""
        }
        let documentSession = CjguiGeneratedUiDocumentSession(path: documentPath)
        this.uiDocumentSession = documentSession
        let documentWorkspace = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("settings-ui-document-mount"), "workspace", documentSession,
            region, title: "界面文档")
        this.uiDocumentWorkspace = documentWorkspace
        let closeGuard = CjguiUiDocumentCloseGuard()
        closeGuard.add(documentWorkspace)
        this.uiDocumentCloseGuard = closeGuard
        this.uiDocumentPathText = documentPath
        this.localRevision = 1
        this.statusText = "编辑后应用计数配置"
        this.styleRunsPhase = 0
        // 集合视图只读已发布 owner 字段：行来自同一组字段名，值列在每次构建前
        // 刷新；列/排序/模式与视图快照都归共同集合工作区。
        let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
        rows.add(CjguiComposableUiVariableHeightListItem("name", 1, "名称", 0, estimatedHeight: 30))
        rows.add(CjguiComposableUiVariableHeightListItem("alias", 2, "别名", 0, estimatedHeight: 30))
        rows.add(CjguiComposableUiVariableHeightListItem("count", 3, "计数", 0, estimatedHeight: 30))
        rows.add(CjguiComposableUiVariableHeightListItem("enabled", 4, "启用", 0, estimatedHeight: 30))
        this.collectionRows = rows.toArray()
        let values = this.collectionValues
        let selection = this.collectionSelection
        let cards = CjguiSettingsFieldCardRowSource(this.collectionRows, { key =>
            match (values.get(key)) {
                case Some(value) => value
                case None => "-"
            }
        })
        let filtered = CjguiComposableUiFilteredListSource(cards, { item => item.title })
        let columns = ArrayList<CjguiComposableUiTableColumn>()
        columns.add(CjguiComposableUiTableColumn("field", "字段", "field", 64, "COLLECTION_SORT_FIELD",
            { item => item.title },
            { left, right =>
                if (left.title < right.title) {
                    -1
                } else if (left.title > right.title) {
                    1
                } else {
                    0
                }
            }, minWidth: 48, maxWidth: 80))
        columns.add(CjguiComposableUiTableColumn("value", "值", "value", 0, "",
            { item =>
                match (values.get(item.key)) {
                    case Some(value) => value
                    case None => "-"
                }
            }, { left, right => 0 }, minWidth: 90, maxWidth: 200))
        columns.add(CjguiComposableUiTableColumn("writer", "公共写入", "writer", 88, "",
            { item => CjguiSettingsCounterController.collectionWriter(item.key) },
            { left, right => 0 }, minWidth: 76, maxWidth: 110))
        let table = CjguiComposableUiTableSource(filtered, "settings-field-collection-source",
            columns.toArray(), CjguiSettingsCounterController.collectionTableStyle(),
            rowAction: { item => CjguiComposableUiTableRowAction("SELECT_FIELD", item.resourceId) },
            rowSelected: { key => selection.isSelected(key) })
        let collection = CjguiGeneratedUiCollection("settingsFields", "settingsFieldCollection",
            filtered, table, selection)
        let view = CjguiComposableUiCollectionViewState(table, ["list", "table"], "list")
        this.collectionViewState = view
        let presentations = HashMap<String, String>()
        presentations.add("list", "list")
        presentations.add("table", "table")
        this.collectionWorkspace = CjguiCollectionWorkspace(collection, view,
            CjguiComposableUiIdentityScope("settings-field-collection-workspace"),
            title: "字段集合", modePresentations: presentations)
    }

    static func collectionWriter(key: String): String {
        return match (key) {
            case "name" => "EDIT_NAME"
            case "alias" => "EDIT_ALIAS"
            case "count" => "INCREMENT"
            case "enabled" => "SET_ENABLED"
            case _ => "-"
        }
    }

    static func collectionTableStyle(): CjguiComposableUiTableStyle {
        return CjguiComposableUiTableStyle(26, 24, 6, 11.5, "system",
            CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
            CjguiComposableUiColor(0.20, 0.32, 0.52, 1.0),
            CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0),
            CjguiComposableUiColor(0.28, 0.34, 0.46, 1.0),
            CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0),
            CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            CjguiComposableUiColor(0.60, 0.64, 0.72, 1.0),
            CjguiComposableUiColor(0.38, 0.55, 0.78, 1.0))
    }

    public func generatedUiRegion(): CjguiGeneratedUiWindowRegion { return generatedRegion }

    public func uiBusinessOwnerRevision(): Int64 { return domain.counterSnapshot().version }

    public func uiSceneVersion(): Int64 {
        return localRevision + domain.counterSnapshot().version + generatedRegion.revision()
    }

    public func beginSceneRefresh(): Bool { return generatedRegion.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return generatedRegion.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { generatedRegion.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { generatedRegion.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { generatedRegion.disposeSceneRefreshResources() }

    public func buildUi(): CjguiComposableUiNode {
        let snapshot = domain.counterSnapshot()
        // N2-V 密度修复后布局单位是 vp（模拟器窗口实测 377x487 vp）。头部与手写
        // 视口按 vp 收紧，让生成区与手写视口同屏可见；卡片与 D 夹具的相对几何
        // 保持原样（裁剪/命中负控依赖 50/40/80 的比例），它们位于首屏之下。
        let heading = CjguiComposableUiStyle(fixedHeight: 24, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0),
            fontSize: 17.0, fontWeight: 700)
        let body = CjguiComposableUiStyle(fixedHeight: 16, textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0),
            fontSize: 12.0)
        let value = CjguiComposableUiStyle(fixedHeight: 84, textColor: CjguiComposableUiColor(1.0, 0.92, 0.55, 1.0),
            fontSize: 54.0, fontWeight: 600)
        // Narrow-window fit: two fixed buttons must fit the 377vp card's
        // remaining width (the old 190vp pair clipped past the right edge).
        let action = CjguiComposableUiStyle(fixedWidth: 130, fixedHeight: 64, gap: 16,
            background: CjguiComposableUiColor(0.18, 0.32, 0.52, 1.0),
            border: CjguiComposableUiColor(0.38, 0.55, 0.78, 1.0), borderWidth: 2,
            cornerRadius: 14, fontSize: 26.0, fontWeight: 600,
            textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))
        let card = CjguiComposableUiStyle(growX: 1, padding: 24, gap: 14,
            background: CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0),
            border: CjguiComposableUiColor(0.28, 0.34, 0.46, 1.0), borderWidth: 1,
            cornerRadius: 18)

        let root = cjguiComposableVertical(1, "counter-root",
            CjguiComposableUiStyle(padding: 12, gap: 10,
                background: CjguiComposableUiColor(0.06, 0.09, 0.15, 1.0)))
        root.add(cjguiComposableText(10, "counter-title", "设置与计数", heading))
        // C（h-source-preview-next）：既有第二消费者经同一框架声明消费混合
        // textStyleRuns。run 端点是节点显示文本的 UTF-8 显示字节偏移（与
        // macOS/网格 caret run 同一 wire 契约）："混排 Mixed 0129 样例" 共
        // 24 字节——混排 0..6、"Mixed" 7..12、"0129" 13..17。阶段由样式按钮
        // 循环推进（0 混合生效 → 1 修改 → 2 倒置 → 3 重叠 → 4 超 64 → 5 清除），
        // 非法批次在框架渲染器整批拒绝、保留旧 runs；不新增第二编辑面。
        let phase = styleRunsPhase
        let mixedRuns = match (phase) {
            case 1 => [
                CjguiComposableUiTextStyleRun(0, 6, 12.0, 400, "system", 0.98, 0.85, 0.30, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 700, "system", 0.35, 0.90, 0.55, 1.0),
                CjguiComposableUiTextStyleRun(13, 17, 14.0, 600, "monospaced", 1.0, 1.0, 1.0, 1.0,
                    hasBackground: true, backgroundRed: 0.10, backgroundGreen: 0.45,
                    backgroundBlue: 0.42, backgroundAlpha: 1.0)]
            case 2 => [
                CjguiComposableUiTextStyleRun(9, 3, 12.0, 700, "system", 1.0, 0.0, 0.0, 1.0)]
            case 3 => [
                CjguiComposableUiTextStyleRun(0, 8, 12.0, 700, "system", 0.20, 0.40, 1.0, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 400, "system", 1.0, 0.60, 0.10, 1.0)]
            case _ => [
                CjguiComposableUiTextStyleRun(0, 6, 12.0, 700, "system", 1.0, 1.0, 1.0, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 700, "system", 1.0, 0.30, 0.28, 1.0),
                CjguiComposableUiTextStyleRun(13, 17, 12.0, 400, "monospaced", 0.92, 0.96, 1.0, 1.0,
                    hasBackground: true, backgroundRed: 0.16, backgroundGreen: 0.22,
                    backgroundBlue: 0.30, backgroundAlpha: 1.0)]
        }
        root.add(cjguiComposableText(11, "counter-mixed", "混排 Mixed 0129 样例", body,
            textStyleRuns: mixedRuns))
        // 超 64 预算的载具：100 字节 ASCII 长文本，常规阶段两段样式，阶段 4
        // 声明 65 个单字节 run（排序、不重叠、各自非空）——按数量上限整批
        // 拒绝、保旧。
        let stressText = "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        let stressRuns = ArrayList<CjguiComposableUiTextStyleRun>()
        if (phase == 4) {
            var i: Int64 = 0
            while (i < 65) {
                stressRuns.add(CjguiComposableUiTextStyleRun(i, i + 1, 11.0, 400, "system",
                    1.0, 0.50, 0.10, 1.0))
                i += 1
            }
        } else if (phase != 5) {
            stressRuns.add(CjguiComposableUiTextStyleRun(0, 10, 11.0, 700, "system", 1.0, 0.45, 0.95, 1.0))
            stressRuns.add(CjguiComposableUiTextStyleRun(10, 20, 11.0, 400, "monospaced", 0.92, 0.96, 1.0, 1.0,
                hasBackground: true, backgroundRed: 0.16, backgroundGreen: 0.22,
                backgroundBlue: 0.30, backgroundAlpha: 1.0))
        }
        root.add(cjguiComposableText(33, "counter-runs-stress", stressText,
            CjguiComposableUiStyle(fixedHeight: 14, growX: 1,
                textColor: CjguiComposableUiColor(0.70, 0.74, 0.82, 1.0), fontSize: 11.0),
            textStyleRuns: stressRuns.toArray()))
        root.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdStylePhase,
            "counter-style-phase", "样式阶段 ${phase}", "CYCLE_STYLE_PHASE",
            CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 34,
                background: CjguiComposableUiColor(0.20, 0.24, 0.40, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0), fontSize: 13.0)))
        // 生成区提到手写视口之前：487 vp 的首屏里两者必须同时可见，
        // 公开生成视口与手写视口才能在同一个 normal 产物上被消费。
        // 生成树是动态内容：放进有界滚动视口的内容侧（内容高度按自然高度
        // 求解），而不是作为有界竖排根的可收缩子项；根节点因此不需要
        // fixedHeight，内容增长时由视口滚动，不是把根压到 0 高。
        let generatedScroll = cjguiComposableScrollArea(
            CjguiSettingsCounterController.nodeIdGeneratedScroll, "settings-generated-scroll",
            generatedScrollViewport,
            CjguiComposableUiStyle(fixedHeight: 120, growX: 1, cornerRadius: 12, clipsContent: true,
                background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                border: CjguiComposableUiColor(0.26, 0.34, 0.50, 1.0), borderWidth: 1))
        let generatedHost = cjguiComposableVertical(
            CjguiSettingsCounterController.nodeIdGeneratedContent, "settings-generated-content",
            CjguiComposableUiStyle(gap: 0, growX: 1))
        generatedHost.add(generatedRegion.buildNode())
        generatedScroll.add(generatedHost)
        root.add(generatedScroll)

        let cardBox = cjguiComposableVertical(15, "counter-card", card)
        cardBox.add(cjguiComposableText(12, "counter-value", "计数：${snapshot.count}",
            value, resourceId: CjguiSettingsCounterDomain.resourceId, fieldId: "count",
            displayValueRole: "applied"))
        let image = domain.imageResourceSpec()
        let imageRow = cjguiComposableHorizontal(29, "counter-image-row",
            CjguiComposableUiStyle(fixedHeight: 72, gap: 16))
        imageRow.add(cjguiComposableImage(CjguiSettingsCounterController.nodeIdImage, "counter-beacon",
            image.rasterPath, CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 72),
            contentMode: 1, imageResourceId: image.key, imageResourceVersion: image.version))
        imageRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdImageSwitch,
            "counter-image-switch", "切换图片", "SWITCH_IMAGE", CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 60, fontSize: 15.0,
                background: CjguiComposableUiColor(0.23, 0.30, 0.48, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        cardBox.add(imageRow)
        let actions = cjguiComposableHorizontal(20, "counter-actions",
            CjguiComposableUiStyle(fixedHeight: 64, gap: 16))
        actions.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdDecrement, "counter-decrement",
            "减少", "DECREMENT", CjguiSettingsCounterDomain.resourceId, action,
            enabled: snapshot.enabled))
        actions.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdIncrement, "counter-increment",
            "增加", "INCREMENT", CjguiSettingsCounterDomain.resourceId, action,
            enabled: snapshot.enabled))
        cardBox.add(actions)
        cardBox.add(cjguiComposableBooleanInput(CjguiSettingsCounterController.nodeIdEnabled, "counter-enabled",
            "启用计数", snapshot.enabled, CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 56, fontSize: 26.0,
                textColor: CjguiComposableUiColor(0.9, 0.93, 0.98, 1.0)),
            fieldId: "enabled", operationActionName: "SET_ENABLED", displayValueRole: "applied"))
        // 名称字段：即时生效模式；人的输入与外部 EDIT_NAME 走同一 owner 入口。
        cardBox.add(cjguiComposableTextInput(CjguiSettingsCounterController.nodeIdName, "counter-name",
            "名称", snapshot.name, CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 72, growX: 1, fontSize: 28.0,
                background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                border: CjguiComposableUiColor(0.32, 0.40, 0.54, 1.0), borderWidth: 1,
                cornerRadius: 10, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0)),
            fieldId: "name", operationActionName: "EDIT_NAME", displayValueRole: "applied"))
        // 第二个文字字段：与 name 不同的几何（更矮、更小字号、不同配色）与
        // 不同的规则（1-8 个 Unicode scalar），但使用相同的文字代理上下文机制。
        // 它用于验证「同一后端 + 应用侧声明即可复用」，不是新增业务能力。
        cardBox.add(cjguiComposableTextInput(CjguiSettingsCounterController.nodeIdAlias, "counter-alias",
            "别名", snapshot.alias, CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 56, fontSize: 22.0,
                background: CjguiComposableUiColor(0.10, 0.13, 0.20, 1.0),
                border: CjguiComposableUiColor(0.30, 0.36, 0.48, 1.0), borderWidth: 1,
                cornerRadius: 8, textColor: CjguiComposableUiColor(0.78, 0.90, 0.86, 1.0)),
            fieldId: "alias", operationActionName: "EDIT_ALIAS", displayValueRole: "applied"))
        cardBox.add(cjguiComposableText(30, "counter-status", statusLine(), body,
            resourceId: CjguiSettingsCounterDomain.resourceId, fieldId: "enabled",
            displayValueRole: "applied"))
        // D 夹具：裁剪边界。clipsContent 容器高 50，三个 40 高文字：
        // d-clip-cross (y 0..40 相对) 完全可见；d-clip-cross2 (y 40..80) 跨越
        // 下边界（仅 10pt 可见）；d-clip-out (y 80..120) 完全在界外（空交集）。
        let clipBox = cjguiComposableVertical(40, "d-clip-box",
            CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 50, gap: 0,
                background: CjguiComposableUiColor(0.30, 0.12, 0.12, 1.0),
                clipsContent: true))
        clipBox.add(cjguiComposableText(41, "d-clip-in", "界内文字 ABC", body))
        // 42 用专属底色覆盖跨界节点的整块布局，避免只采到别处的同色文字。
        clipBox.add(cjguiComposableText(42, "d-clip-cross", "跨边界文字 DEF",
            CjguiComposableUiStyle(fixedHeight: 40, fontSize: 22.0,
                background: CjguiComposableUiColor(0.04, 0.82, 0.75, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        // 43 必须有正尺寸布局；其专属底色在关闭 clip 的负控里应真实可见。
        clipBox.add(cjguiComposableText(43, "d-clip-out", "界外文字 XYZ",
            CjguiComposableUiStyle(fixedHeight: 40, fontSize: 20.0,
                background: CjguiComposableUiColor(0.95, 0.45, 0.10, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        cardBox.add(clipBox)
        // 透明观察区隔开后续不透明按钮：关闭 clip 时 42/43 的像素不会被遮住。
        cardBox.add(cjguiComposableVertical(48, "d-clip-observation-space",
            CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 70)))
        // D2 夹具（第六次复核第 4 项）：跨边界的**可交互按钮**。容器高 50、
        // 按钮高 80 → 可见部分 0..50、被裁部分 50..80。可见区命中必须推进
        // owner，被裁区命中必须不推进（裁剪边界命中的真负控）；noclip 孪生
        // 容器（clipsContent:false）同几何同动作，两处都命中——证明被裁区
        // 未命中确由裁剪所致，而非几何不可达。
        let clipBtnBox = cjguiComposableVertical(44, "d-clip-btn-box",
            CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 50, gap: 0,
                background: CjguiComposableUiColor(0.12, 0.30, 0.14, 1.0),
                clipsContent: true))
        clipBtnBox.add(cjguiComposableButton(45, "d-clip-btn", "裁剪增加",
            "INCREMENT", CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 380, fixedHeight: 80, cornerRadius: 0,
                background: CjguiComposableUiColor(0.16, 0.44, 0.20, 1.0),
                textColor: CjguiComposableUiColor(0.90, 0.95, 0.88, 1.0))))
        cardBox.add(clipBtnBox)
        // 被裁按钮下方保留无交互空间；负控点击落在按钮自身布局内且不被孪生按钮覆盖。
        cardBox.add(cjguiComposableVertical(49, "d-clip-hit-observation-space",
            CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 50)))
        let noclipBtnBox = cjguiComposableVertical(46, "d-noclip-btn-box",
            CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 50, gap: 0,
                background: CjguiComposableUiColor(0.30, 0.22, 0.08, 1.0),
                clipsContent: false))
        noclipBtnBox.add(cjguiComposableButton(47, "d-noclip-btn", "不裁增加",
            "INCREMENT", CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 380, fixedHeight: 80, cornerRadius: 0,
                background: CjguiComposableUiColor(0.44, 0.34, 0.12, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.92, 0.85, 1.0))))
        cardBox.add(noclipBtnBox)
        // H 触摸滚动：手写视口（>3 屏有界内容，混排文字/图片/按钮/编辑器）。
        // 滚动经共享 viewport 的 scroll 意图通道，不改 owner；区内按钮与
        // 编辑器照常推进 owner，与生成 scrollArea 共同调用同一机制。
        let handImageSpec = domain.imageResourceSpec()
        let handScroll = cjguiComposableScrollArea(CjguiSettingsCounterController.nodeIdHandScroll,
            "settings-hand-scroll", handScrollViewport,
            CjguiComposableUiStyle(fixedHeight: 150, growX: 1, cornerRadius: 12, clipsContent: true,
                background: CjguiComposableUiColor(0.09, 0.12, 0.20, 1.0),
                border: CjguiComposableUiColor(0.26, 0.34, 0.50, 1.0), borderWidth: 1))
        let handContent = cjguiComposableVertical(901, "settings-hand-scroll-content",
            CjguiComposableUiStyle(padding: 8, gap: 6, growX: 1))
        handContent.add(cjguiComposableText(902, "hand-scroll-head", "手写滚动区（上下拖动查看）",
            CjguiComposableUiStyle(fixedHeight: 18, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0),
                fontSize: 13.0, fontWeight: 600)))
        let navStyle = CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 30,
            background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
            textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))
        let navRow = cjguiComposableHorizontal(952, "hand-nav-row",
            CjguiComposableUiStyle(fixedHeight: 30, gap: 8))
        navRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdFocusNoteNav,
            "settings-focus-note-nav", "定位滚动备注", "FOCUS_SCROLL_NOTE",
            CjguiSettingsCounterDomain.resourceId, navStyle))
        navRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdFieldTableNav,
            "settings-focus-field-table", "定位字段表", "FOCUS_FIELD_TABLE",
            CjguiSettingsCounterDomain.resourceId, navStyle))
        navRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdFieldCollectionNav,
            "settings-focus-field-collection", "定位字段集合", "FOCUS_FIELD_COLLECTION",
            CjguiSettingsCounterDomain.resourceId, navStyle))
        handContent.add(navRow)
        let uiDocNavRow = cjguiComposableHorizontal(
            CjguiSettingsCounterController.nodeIdUiDocumentNavRow, "settings-uidoc-nav-row",
            CjguiComposableUiStyle(fixedHeight: 30, gap: 8))
        uiDocNavRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdUiDocumentNav,
            "settings-focus-ui-document", "定位界面文档", "FOCUS_UI_DOCUMENT",
            CjguiSettingsCounterDomain.resourceId, navStyle))
        if (showExitApp) {
            uiDocNavRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdExitApp,
                "settings-exit-app", "退出应用", "EXIT_APP",
                CjguiSettingsCounterDomain.resourceId, navStyle))
        }
        handContent.add(uiDocNavRow)
        var rowNodeId: Int64 = 910
        for (i in 1..=8) {
            handContent.add(cjguiComposableText(rowNodeId, "hand-scroll-row${i}",
                "滚动行 ${i}：内容超过三屏，行号用于滚动后画面与命中对照",
                CjguiComposableUiStyle(fixedHeight: 28, growX: 1,
                    textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0), fontSize: 12.0)))
            rowNodeId += 1
            if (i == 4) {
                // 屏2：图片与切换按钮（复用既有图片资源与 owner 动作）。
                let handImageRow = cjguiComposableHorizontal(930, "hand-scroll-image-row",
                    CjguiComposableUiStyle(fixedHeight: 40, gap: 8))
                handImageRow.add(cjguiComposableImage(CjguiSettingsCounterController.nodeIdHandScrollImage,
                    "hand-scroll-beacon", handImageSpec.rasterPath,
                    CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 40),
                    contentMode: 1, imageResourceId: handImageSpec.key,
                    imageResourceVersion: handImageSpec.version))
                handImageRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdHandScrollIncrement,
                    "hand-scroll-increment", "滚动区增加", "INCREMENT",
                    CjguiSettingsCounterDomain.resourceId, action, enabled: snapshot.enabled))
                handContent.add(handImageRow)
            }
            if (i == 8) {
                // 屏3：滚动备注编辑器（owner 字段 scrollNote）。
                handContent.add(cjguiComposableTextInput(CjguiSettingsCounterController.nodeIdHandScrollNote,
                    "hand-scroll-note", "滚动备注", snapshot.scrollNote,
                    CjguiSettingsCounterDomain.resourceId,
                    CjguiComposableUiStyle(fixedHeight: 32, growX: 1, fontSize: 13.0,
                        background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                        border: CjguiComposableUiColor(0.32, 0.40, 0.54, 1.0), borderWidth: 1,
                        cornerRadius: 6, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0)),
                    fieldId: "scrollNote", operationActionName: "EDIT_SCROLL_NOTE",
                    displayValueRole: "applied"))
            }
        }
        handContent.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdHandScrollDecrement,
            "hand-scroll-decrement", "滚动区减少", "DECREMENT",
            CjguiSettingsCounterDomain.resourceId, action, enabled: snapshot.enabled))
        handContent.add(buildFieldTable(snapshot))
        handContent.add(buildFieldCollection(snapshot))
        handContent.add(buildUiDocumentPanel())
        handScroll.add(handContent)
        root.add(handScroll)
        root.add(cardBox)
        return root
    }

    /// 公共表格（CjguiComposableUiTableSource）读取已发布的 owner 字段：
    /// 列布局、表头、单元格与行选中都来自共同实现；行激活只改本地选中，
    /// 不写 owner，也不新增业务字段。
    private func buildFieldTable(snapshot: CjguiSettingsCounterSnapshot): CjguiComposableUiNode {
        let values = HashMap<String, String>()
        values.add("name", snapshot.name)
        values.add("alias", snapshot.alias)
        values.add("count", "${snapshot.count}")
        values.add("enabled", if (snapshot.enabled) { "true" } else { "false" })
        let writers = HashMap<String, String>()
        writers.add("name", "EDIT_NAME")
        writers.add("alias", "EDIT_ALIAS")
        writers.add("count", "INCREMENT")
        writers.add("enabled", "SET_ENABLED")
        let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
        rows.add(CjguiComposableUiVariableHeightListItem("name", 1, "名称", 0, estimatedHeight: 26))
        rows.add(CjguiComposableUiVariableHeightListItem("alias", 2, "别名", 0, estimatedHeight: 26))
        rows.add(CjguiComposableUiVariableHeightListItem("count", 3, "计数", 0, estimatedHeight: 26))
        rows.add(CjguiComposableUiVariableHeightListItem("enabled", 4, "启用", 0, estimatedHeight: 26))
        let source = CjguiComposableUiFilteredListSource(CjguiSettingsFieldRowSource(rows.toArray()),
            { item => item.title })
        let columns = ArrayList<CjguiComposableUiTableColumn>()
        columns.add(CjguiComposableUiTableColumn("field", "字段", "field", 64, "",
            { item => item.title }, { left, right => 0 }, minWidth: 48, maxWidth: 80))
        columns.add(CjguiComposableUiTableColumn("value", "值", "value", 0, "",
            { item => match (values.get(item.key)) {
                case Some(value) => value
                case None => "-"
            } }, { left, right => 0 }, minWidth: 90, maxWidth: 200))
        columns.add(CjguiComposableUiTableColumn("writer", "公共写入", "writer", 88, "",
            { item => match (writers.get(item.key)) {
                case Some(value) => value
                case None => "-"
            } }, { left, right => 0 }, minWidth: 76, maxWidth: 110))
        let style = CjguiComposableUiTableStyle(26, 24, 6, 11.5, "system",
            CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
            CjguiComposableUiColor(0.20, 0.32, 0.52, 1.0),
            CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0),
            CjguiComposableUiColor(0.28, 0.34, 0.46, 1.0),
            CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0),
            CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            CjguiComposableUiColor(0.60, 0.64, 0.72, 1.0),
            CjguiComposableUiColor(0.38, 0.55, 0.78, 1.0))
        let selected = selectedFieldKey
        let table = CjguiComposableUiTableSource(source, "settings-field-table-source",
            columns.toArray(), style,
            rowAction: { item => CjguiComposableUiTableRowAction("SELECT_FIELD", item.resourceId) },
            rowSelected: { key => key == selected })
        let tableBox = cjguiComposableVertical(CjguiSettingsCounterController.nodeIdFieldTable,
            "settings-field-table", CjguiComposableUiStyle(gap: 4, growX: 1, padding: 4,
                background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                border: CjguiComposableUiColor(0.26, 0.34, 0.50, 1.0), borderWidth: 1))
        tableBox.add(cjguiComposableText(953, "settings-field-table-title",
            "字段表（点行选中）", CjguiComposableUiStyle(fixedHeight: 18, fontSize: 12.0,
                textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0))))
        tableBox.add(table.buildHeader())
        if (selected.size > 0) {
            fieldTableListState.setSelectedKey(selected)
        }
        // 行由共同变高列表按表源物化（身份在布局期解析），与表头同源于表源。
        tableBox.add(cjguiComposableVariableHeightList(954, "settings-field-table-list", 955, table,
            fieldTableListState, 26, 0, 2,
            CjguiComposableUiStyle(fixedHeight: 130, growX: 1)))
        return tableBox
    }

    /// 字段集合：同一组 owner 字段经共同 CjguiGeneratedUiCollection 以列表/
    /// 表格两种呈现挂载，模式、列设置、排序与视图快照都走共同集合工作区。
    /// 视图动作只改视图状态；行激活只改本地选中，都不写 owner。
    private func buildFieldCollection(snapshot: CjguiSettingsCounterSnapshot): CjguiComposableUiNode {
        collectionValues.clear()
        collectionValues.add("name", snapshot.name)
        collectionValues.add("alias", snapshot.alias)
        collectionValues.add("count", "${snapshot.count}")
        collectionValues.add("enabled", if (snapshot.enabled) { "true" } else { "false" })
        let mode = collectionViewState.mode()
        let presentation = collectionWorkspace.presentationForMode(mode)
        let box = cjguiComposableVertical(CjguiSettingsCounterController.nodeIdFieldCollection,
            "settings-field-collection", CjguiComposableUiStyle(gap: 4, growX: 1, padding: 4,
                background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                border: CjguiComposableUiColor(0.26, 0.34, 0.50, 1.0), borderWidth: 1))
        box.add(cjguiComposableText(966, "settings-field-collection-title",
            "字段集合 · ${mode}（共同集合/表格）", CjguiComposableUiStyle(fixedHeight: 18, fontSize: 12.0,
                textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0))))
        let modeStyle = CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 24, fontSize: 10.5,
            background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
            textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))
        let modeRow = cjguiComposableHorizontal(967, "settings-field-collection-mode-row",
            CjguiComposableUiStyle(fixedHeight: 24, gap: 6))
        modeRow.add(cjguiComposableButton(963, "settings-collection-mode-list", "列表视图",
            "COLLECTION_MODE_LIST", -1, modeStyle))
        modeRow.add(cjguiComposableButton(964, "settings-collection-mode-table", "表格视图",
            "COLLECTION_MODE_TABLE", -1, modeStyle))
        modeRow.add(cjguiComposableButton(965, "settings-collection-columns-toggle",
            if (collectionColumnEditorVisible) { "隐藏列设置" } else { "列设置" },
            "COLLECTION_COLUMNS_TOGGLE", -1,
            CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 24, fontSize: 10.5,
                background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        box.add(modeRow)
        box.add(collectionWorkspace.buildActionBar(970, CjguiComposableUiStyle(gap: 4),
            collectionViewSnapshot, CjguiComposableUiStyle(fixedHeight: 24, padding: 4, fontSize: 10.5,
                background: CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0),
                textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0),
                border: CjguiComposableUiColor(0.28, 0.34, 0.46, 1.0), borderWidth: 1,
                cornerRadius: 6)))
        if (collectionColumnEditorVisible) {
            box.add(collectionWorkspace.buildColumnEditor(1000, CjguiComposableUiStyle(gap: 3),
                CjguiComposableUiStyle(fixedHeight: 24, fontSize: 10.0, padding: 4,
                    background: CjguiComposableUiColor(0.14, 0.20, 0.32, 1.0),
                    textColor: CjguiComposableUiColor(0.90, 0.93, 0.98, 1.0))))
        }
        box.add(collectionWorkspace.collection().buildNode(980, "settings-field-collection-view",
            981, "settings-field-collection-content", presentation,
            CjguiComposableUiStyle(fixedHeight: 130, growX: 1),
            identityScope: Some(collectionMountScope)))
        box.add(collectionWorkspace.buildStatusLine(982))
        return box
    }

    /// 公共界面文档工作区：按钮/状态/预览都来自共同 workspace，文件路径由
    /// 平台沙箱给出；应用只负责挂载与事件转交，不另写一套文档状态机。
    private func buildUiDocumentPanel(): CjguiComposableUiNode {
        let box = cjguiComposableVertical(CjguiSettingsCounterController.nodeIdUiDocumentPanel,
            "settings-ui-document-panel", CjguiComposableUiStyle(gap: 4, growX: 1))
        box.add(uiDocumentWorkspace.build(
            CjguiComposableUiStyle(background: CjguiComposableUiColor(0.10, 0.14, 0.22, 1.0),
                border: CjguiComposableUiColor(0.26, 0.34, 0.50, 1.0), borderWidth: 1, cornerRadius: 10),
            CjguiComposableUiStyle(fixedHeight: 20, fontSize: 13.0, fontWeight: 600,
                textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0)),
            CjguiComposableUiStyle(fontSize: 11.5,
                textColor: CjguiComposableUiColor(0.80, 0.84, 0.92, 1.0)),
            CjguiComposableUiStyle(fixedWidth: 92, fixedHeight: 26, fontSize: 11.0,
                background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        // 公共 path row：打开/另存都走同一 workspace 命令与受保护写路径；路径
        // 字符串仍由应用持有（沙箱注入），框架不发明默认文件。
        box.add(uiDocumentWorkspace.buildPathRow(uiDocumentPathText,
            CjguiComposableUiStyle(fixedHeight: 30, fontSize: 10.5, growX: 1, padding: 4,
                background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0),
                border: CjguiComposableUiColor(0.28, 0.34, 0.46, 1.0), borderWidth: 1, cornerRadius: 6),
            CjguiComposableUiStyle(fixedWidth: 76, fixedHeight: 26, fontSize: 10.5,
                background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        return box
    }

    /// 启动时的正常文件打开：公共 session 读文件→预览→确认提交；文件缺失/
    /// 损坏是具名拒绝，保留手写界面。返回可记录的启动事实。
    public func beginUiDocumentStartup(): String {
        if (uiDocumentPathText.size == 0) {
            return "ui_document_no_path"
        }
        let result = uiDocumentWorkspace.beginStartup(uiDocumentPathText,
            policy: CJGUI_UI_DOCUMENT_POLICY_REPLACE)
        return "startup applied=${result.applied} reason=${result.reason} token=${result.token} " +
            "version=${result.version}"
    }

    /// 每轮只结算真正提交中的票据；返回 true 表示发生了需要重绘的终态变化。
    public func settleUiDocument(): Bool {
        if (uiDocumentSession.stateFor(generatedRegion).mode != "submitted") {
            return false
        }
        let result = uiDocumentWorkspace.finish()
        if (result.reason == "ui_document_pending") {
            return false
        }
        statusText = "界面文档结算 ${result.reason} accepted=${result.accepted}"
        localRevision += 1
        return true
    }

    public func uiDocumentPending(): Bool {
        return uiDocumentSession.stateFor(generatedRegion).mode == "submitted"
    }

    public func uiDocumentStatus(): String {
        return uiDocumentSession.statusTextFor(generatedRegion)
    }

    /// 生命周期收尾：先结算提交中的票据/取消未确认预览，再对未保存界面走
    /// 同一受保护写路径保存；返回事实供日志，不伪造成功。
    public func prepareUiDocumentForShutdown(): String {
        let before = uiDocumentCloseGuard.settleAndReport()
        let saveIssue = uiDocumentCloseGuard.saveUnsaved({ _ => uiDocumentPathText })
        let after = uiDocumentCloseGuard.settleAndReport()
        return "before=${before} save=${saveIssue} after=${after}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generated = generatedRegion.handleEvent(event)
        if (generated.didApply) {
            localRevision += 1
            return generated
        }
        if (event.eventKind == 27) {
            if (let Some(commandId) <- cjguiCommandToolbarCommandId(event.node.actionName)) {
                if (uiDocumentWorkspace.ownsCommand(commandId)) {
                    // The path-row commands act on the consumer's CURRENT path
                    // string; the other commands own only session state.
                    let isPathCommand = commandId == uiDocumentWorkspace.pathCommandId() ||
                        commandId == uiDocumentWorkspace.pathCommandId(open: false)
                    let outcome = if (isPathCommand) {
                        uiDocumentWorkspace.handlePathCommand(commandId, uiDocumentPathText)
                    } else {
                        uiDocumentWorkspace.handleCommand(commandId)
                    }
                    let reason = match (outcome) {
                        case Some(value) => value.reason
                        case None => "ui_document_command_unhandled"
                    }
                    statusText = "界面文档 ${reason}"
                    localRevision += 1
                    return CjguiComposableUiDispatchResult(true)
                }
            }
            if (event.node.nodeId == CjguiSettingsCounterController.nodeIdExitApp) {
                statusText = "正在退出应用"
                localRevision += 1
                exitRequest()
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.nodeId == CjguiSettingsCounterController.nodeIdUiDocumentNav) {
                requestFocusSemantic("${uiDocumentWorkspace.semanticPrefix()}-save")
                statusText = "已请求定位界面文档"
                localRevision += 1
                return CjguiComposableUiDispatchResult(true)
            }
        }
        // 集合视图动作：模式/列/排序/快照都归共同工作区；保存快照只存本进程
        // 内存，恢复在无快照时按真实可用性拒绝。
        if (event.eventKind == 27) {
            if (let Some(action) <- collectionWorkspace.actionForEvent(event)) {
                let outcome = collectionWorkspace.executeAction(action,
                    { encoded => collectionViewSnapshot = encoded; true }, { => collectionViewSnapshot })
                statusText = outcome.status
                localRevision += 1
                return CjguiComposableUiDispatchResult(outcome.applied)
            }
            if (let Some(applied) <- collectionWorkspace.applyColumnEvent(event)) {
                collectionViewState.notePresentationChanged()
                statusText = collectionWorkspace.status()
                localRevision += 1
                return CjguiComposableUiDispatchResult(applied)
            }
            if (event.node.nodeId == 963 || event.node.nodeId == 964) {
                let mode = if (event.node.nodeId == 963) { "list" } else { "table" }
                let applied = collectionWorkspace.setMode(mode)
                if (applied) { statusText = collectionWorkspace.status() }
                localRevision += 1
                return CjguiComposableUiDispatchResult(applied)
            }
            if (event.node.nodeId == 965) {
                collectionColumnEditorVisible = !collectionColumnEditorVisible
                statusText = if (collectionColumnEditorVisible) { "展示列设置" } else { "隐藏列设置" }
                localRevision += 1
                return CjguiComposableUiDispatchResult(true)
            }
            if (event.node.actionName == "COLLECTION_SORT_FIELD") {
                // 表头排序是公共表源事实：字段列按标题显式切换升降序。
                let applied = collectionWorkspace.toggleSort("field")
                statusText = if (applied) { "字段列排序已切换" } else { "字段列排序未变化" }
                localRevision += 1
                return CjguiComposableUiDispatchResult(applied)
            }
        }
        if (event.eventKind == 27
            && event.node.nodeId == CjguiSettingsCounterController.nodeIdFieldCollectionNav) {
            // 集合自身是滚动区；把焦点交给首行可聚焦控件，让整段集合落入
            // 150vp 手写视口。表格呈现时目标改为表内首行首列单元格。
            let target = if (collectionViewState.mode() == "table") {
                "settings-field-collection-source-cell-name-field"
            } else {
                "settings-field-card-select-name"
            }
            requestFocusSemantic(target)
            statusText = "已请求定位字段集合"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiSettingsCounterController.nodeIdFieldTableNav) {
            // 目标选表内末个数据单元格（可聚焦按钮）：容器本身不是焦点目标，
            // 对齐末行可让整张 130vp 表落入 150vp 手写视口；单元格在共同
            // 表格的身份作用域内随行物化，导航照样经同一 reveal→外滚视口。
            requestFocusSemantic("settings-field-table-source-cell-enabled-field")
            statusText = "已请求定位字段表"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        // 行激活：表格只做本地选中，不写 owner，也不产生业务版本。
        if (event.eventKind == 27 && event.node.actionName == "SELECT_FIELD") {
            let key = match (event.node.resourceId) {
                case 1 => "name"
                case 2 => "alias"
                case 3 => "count"
                case 4 => "enabled"
                case _ => ""
            }
            if (key.size == 0) { return CjguiComposableUiDispatchResult(false) }
            selectedFieldKey = key
            // 表格与集合共用这一行激活事实；集合的选中/焦点由共同选择对象持有。
            collectionSelection.click(key, false, false, collectionWorkspace.collection().order())
            statusText = "字段选中 ${key}"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        let snapshot = domain.counterSnapshot()
        if (event.eventKind == 27 && event.node.nodeId == CjguiSettingsCounterController.nodeIdFocusNoteNav) {
            // 显式目标导航：请求聚焦滚动区内编辑器（屏外 reveal→系统输入）。
            requestFocusSemantic("hand-scroll-note")
            statusText = "已请求定位滚动备注"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiSettingsCounterController.nodeIdStylePhase) {
            // 本地循环：阶段推进只改 UI 声明（localRevision 驱动重建与 runs 重装），
            // 不产生 owner 写入——C 的判别对象是渲染器准入，不是业务状态。
            styleRunsPhase = (styleRunsPhase + 1) % 6
            statusText = "样式阶段 ${styleRunsPhase}"
            println("SETTINGS_STYLE_PHASE phase=${styleRunsPhase}")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiSettingsCounterController.nodeIdImageSwitch) {
            return applyImage(domain.executeFromHuman(invoke("SWITCH_IMAGE", snapshot.version)))
        }
        if (event.eventKind == 27 && (event.node.nodeId == CjguiSettingsCounterController.nodeIdIncrement
            || event.node.nodeId == 45 || event.node.nodeId == 47
            || event.node.nodeId == CjguiSettingsCounterController.nodeIdHandScrollIncrement)) {
            // 45/47：D2 裁剪命中夹具按钮；941：手写滚动区按钮——同一条
            // INCREMENT owner 入口。
            return applyCounter(domain.executeFromHuman(invoke("INCREMENT", snapshot.version)))
        }
        if (event.eventKind == 27 && (event.node.nodeId == CjguiSettingsCounterController.nodeIdDecrement
            || event.node.nodeId == CjguiSettingsCounterController.nodeIdHandScrollDecrement)) {
            return applyCounter(domain.executeFromHuman(invoke("DECREMENT", snapshot.version)))
        }
        if (event.eventKind == 29 && event.node.nodeId == CjguiSettingsCounterController.nodeIdEnabled) {
            let next = event.text == "true"
            return applyCounter(domain.executeFromHuman(invokeBoolean("SET_ENABLED", next, snapshot.version)))
        }
        if (event.eventKind == 28 && event.node.semanticId == uiDocumentWorkspace.pathFieldSemanticId()) {
            uiDocumentPathText = event.text
            statusText = "界面文档路径 ${uiDocumentPathText}"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && event.node.nodeId == CjguiSettingsCounterController.nodeIdName) {
            return applyName(domain.executeFromHuman(invokeName(event.text, snapshot.version)))
        }
        if (event.eventKind == 28 && event.node.nodeId == CjguiSettingsCounterController.nodeIdAlias) {
            return applyAlias(domain.executeFromHuman(invokeAlias(event.text, snapshot.version)))
        }
        if (event.eventKind == 28 && event.node.nodeId == CjguiSettingsCounterController.nodeIdHandScrollNote) {
            return applyScrollNote(domain.executeFromHuman(invokeScrollNote(event.text, snapshot.version)))
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        statusText = if (eventKind == 11) { "输入队列已满：本次输入未应用，请重试" }
            else { "输入未应用：事件 ${eventKind} 的原控件已刷新（节点 ${nodeId}）" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }

    private func invoke(action: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation(action, expectedVersion,
            ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>())
    }

    private func invokeName(text: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("EDIT_NAME", expectedVersion,
            ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))
            ]))
    }

    private func invokeAlias(text: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("EDIT_ALIAS", expectedVersion,
            ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))
            ]))
    }

    private func invokeScrollNote(text: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("EDIT_SCROLL_NOTE", expectedVersion,
            ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))
            ]))
    }

    private func applyScrollNote(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.counterSnapshot()
        statusText = if (result.applied) {
            "滚动备注已应用 v${result.versionAfter} · ${snapshot.scrollNote}"
        } else if (result.reason == "scroll_note_out_of_range") {
            "滚动备注未应用：1-32 字符（当前 ${snapshot.scrollNote}）"
        } else if (result.reason == "version_conflict") {
            "滚动备注未应用：内容已被外部更新，请基于新值重试"
        } else {
            "滚动备注未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyAlias(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.counterSnapshot()
        statusText = if (result.applied) {
            "别名已应用 v${result.versionAfter} · ${snapshot.alias}"
        } else if (result.reason == "alias_out_of_range") {
            "别名未应用：1-8 字符（当前 ${snapshot.alias}）"
        } else if (result.reason == "version_conflict") {
            "别名未应用：内容已被外部更新，请基于新值重试"
        } else {
            "别名未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyName(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.counterSnapshot()
        statusText = if (result.applied) {
            "名称已应用 v${result.versionAfter} · ${snapshot.name}"
        } else if (result.reason == "name_out_of_range") {
            "名称未应用：1-32 字符（当前 ${snapshot.name}）"
        } else if (result.reason == "version_conflict") {
            "名称未应用：内容已被外部更新，请基于新值重试"
        } else {
            "名称未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func invokeBoolean(action: String, value: Bool, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation(action, expectedVersion,
            ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.boolean(value))
            ]))
    }

    private func applyCounter(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.counterSnapshot()
        statusText = if (result.applied) {
            "已应用 v${result.versionAfter} · 计数 ${snapshot.count} · ${if (snapshot.enabled) { "已启用" } else { "已停用" }}"
        } else if (result.reason == "counter_out_of_range") {
            "越界拒绝：计数保持在 ${snapshot.count}（范围 0-99）"
        } else if (result.reason == "counter_disabled") {
            "已停用：先打开启用开关"
        } else {
            "未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyImage(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        statusText = if (result.applied) { "标志图已切换到 v${domain.counterSnapshot().imageVersion}" }
            else { "标志图未切换：${result.reason}" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func statusLine(): String {
        let snapshot = domain.counterSnapshot()
        return "${statusText} · v${snapshot.version}"
    }
}
