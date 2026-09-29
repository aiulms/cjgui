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

    public init() {
        this.versionValue = 0
        this.countValue = 10
        this.enabledValue = true
        this.nameValue = "我的设备"
        this.aliasValue = "前台"
        this.scrollNoteValue = "滚动备注"
        this.imageVersionValue = 1
        this.imageCatalog = None
        // 每次启动的 capability 均为新发；把它编入流标识，防止重启后
        // 调用方把数值版本当作同一游标续读。
        this.streamIdentity = "settings_counter_stream_${Random().nextUInt64()}"
        this.changeLog = ArrayList<CjguiSharedOperationChangeEntry>()
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
    private var pendingFocusSemantic: ?String = None

    public func requestFocusSemantic(semanticId: String): Unit {
        pendingFocusSemantic = Some(semanticId)
    }

    public func takePendingFocusRequest(): ?String {
        let pending = pendingFocusSemantic
        pendingFocusSemantic = None
        return pending
    }

    // C（惯性包）：推进手写视口的活跃惯性（由宿主循环每轮调用）。
    public func stepActiveInertialScrolls(now: MonoTime): Bool {
        return handScrollViewport.stepInertialScroll(now)
    }

    private let domain: CjguiSettingsCounterDomain
    private let generatedRegion: CjguiGeneratedUiWindowRegion
    private var localRevision: Int64
    private var statusText: String

    public init(domain: CjguiSettingsCounterDomain) {
        // C（惯性包）：启用实验性惯性滚动（手写/生成共同策略声明）。
        cjguiComposableInertialScrollEnabled = true
        this.domain = domain
        this.generatedRegion = CjguiGeneratedUiWindowRegion(settingsGeneratedCatalog(domain),
            CjguiSettingsCounterGeneratedBinding(domain), "settings-generated")
        this.localRevision = 1
        this.statusText = "编辑后应用计数配置"
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
        let heading = CjguiComposableUiStyle(fixedHeight: 52, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0),
            fontSize: 30.0, fontWeight: 700)
        let body = CjguiComposableUiStyle(fixedHeight: 40, textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0),
            fontSize: 22.0)
        let value = CjguiComposableUiStyle(fixedHeight: 84, textColor: CjguiComposableUiColor(1.0, 0.92, 0.55, 1.0),
            fontSize: 54.0, fontWeight: 600)
        let action = CjguiComposableUiStyle(fixedWidth: 190, fixedHeight: 64, gap: 16,
            background: CjguiComposableUiColor(0.18, 0.32, 0.52, 1.0),
            border: CjguiComposableUiColor(0.38, 0.55, 0.78, 1.0), borderWidth: 2,
            cornerRadius: 14, fontSize: 30.0, fontWeight: 600,
            textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))
        let card = CjguiComposableUiStyle(growX: 1, padding: 24, gap: 14,
            background: CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0),
            border: CjguiComposableUiColor(0.28, 0.34, 0.46, 1.0), borderWidth: 1,
            cornerRadius: 18)

        let root = cjguiComposableVertical(1, "counter-root",
            CjguiComposableUiStyle(padding: 28, gap: 18,
                background: CjguiComposableUiColor(0.06, 0.09, 0.15, 1.0)))
        root.add(cjguiComposableText(10, "counter-title", "设置与计数", heading))
        root.add(cjguiComposableText(11, "counter-mixed", "混排 Mixed 0129 样例", body))

        let cardBox = cjguiComposableVertical(15, "counter-card", card)
        cardBox.add(cjguiComposableText(12, "counter-value", "计数：${snapshot.count}",
            value, resourceId: CjguiSettingsCounterDomain.resourceId, fieldId: "count",
            displayValueRole: "applied"))
        let image = domain.imageResourceSpec()
        let imageRow = cjguiComposableHorizontal(29, "counter-image-row",
            CjguiComposableUiStyle(fixedHeight: 72, gap: 16))
        imageRow.add(cjguiComposableImage(CjguiSettingsCounterController.nodeIdImage, "counter-beacon",
            image.rasterPath, CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 72),
            contentMode: 1, imageResourceId: image.key, imageResourceVersion: image.version))
        imageRow.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdImageSwitch,
            "counter-image-switch", "切换图片", "SWITCH_IMAGE", CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 60,
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
            CjguiComposableUiStyle(fixedHeight: 420, growX: 1, cornerRadius: 12, clipsContent: true,
                background: CjguiComposableUiColor(0.09, 0.12, 0.20, 1.0),
                border: CjguiComposableUiColor(0.26, 0.34, 0.50, 1.0), borderWidth: 1))
        let handContent = cjguiComposableVertical(901, "settings-hand-scroll-content",
            CjguiComposableUiStyle(padding: 20, gap: 12, growX: 1))
        handContent.add(cjguiComposableText(902, "hand-scroll-head", "手写滚动区（上下拖动查看）",
            CjguiComposableUiStyle(fixedHeight: 46, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0),
                fontSize: 26.0, fontWeight: 600)))
        handContent.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdFocusNoteNav,
            "settings-focus-note-nav", "定位滚动备注", "FOCUS_SCROLL_NOTE",
            CjguiSettingsCounterDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 56,
                background: CjguiComposableUiColor(0.16, 0.26, 0.44, 1.0),
                textColor: CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0))))
        var rowNodeId: Int64 = 910
        for (i in 1..=8) {
            handContent.add(cjguiComposableText(rowNodeId, "hand-scroll-row${i}",
                "滚动行 ${i}：内容超过三屏，行号用于滚动后画面与命中对照",
                CjguiComposableUiStyle(fixedHeight: 44, growX: 1,
                    textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0), fontSize: 22.0)))
            rowNodeId += 1
            if (i == 4) {
                // 屏2：图片与切换按钮（复用既有图片资源与 owner 动作）。
                let handImageRow = cjguiComposableHorizontal(930, "hand-scroll-image-row",
                    CjguiComposableUiStyle(fixedHeight: 72, gap: 16))
                handImageRow.add(cjguiComposableImage(CjguiSettingsCounterController.nodeIdHandScrollImage,
                    "hand-scroll-beacon", handImageSpec.rasterPath,
                    CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 72),
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
                    CjguiComposableUiStyle(fixedHeight: 64, growX: 1, fontSize: 24.0,
                        background: CjguiComposableUiColor(0.07, 0.10, 0.16, 1.0),
                        border: CjguiComposableUiColor(0.32, 0.40, 0.54, 1.0), borderWidth: 1,
                        cornerRadius: 10, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0)),
                    fieldId: "scrollNote", operationActionName: "EDIT_SCROLL_NOTE",
                    displayValueRole: "applied"))
            }
        }
        handContent.add(cjguiComposableButton(CjguiSettingsCounterController.nodeIdHandScrollDecrement,
            "hand-scroll-decrement", "滚动区减少", "DECREMENT",
            CjguiSettingsCounterDomain.resourceId, action, enabled: snapshot.enabled))
        handScroll.add(handContent)
        root.add(handScroll)
        root.add(cardBox)
        root.add(generatedRegion.buildNode())
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generated = generatedRegion.handleEvent(event)
        if (generated.didApply) {
            localRevision += 1
            return generated
        }
        let snapshot = domain.counterSnapshot()
        if (event.eventKind == 27 && event.node.nodeId == CjguiSettingsCounterController.nodeIdFocusNoteNav) {
            // 显式目标导航：请求聚焦滚动区内编辑器（屏外 reveal→系统输入）。
            requestFocusSemantic("hand-scroll-note")
            statusText = "已请求定位滚动备注"
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
