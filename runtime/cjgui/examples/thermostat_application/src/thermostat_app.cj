// 恒温示例：第二个真实独立消费者（第六次复核第 5 项）。
//
// 与设置计数示例的差异（每个都是本消费者存在的理由）：
//  - 不同领域字段：目标温度（16–30 整数）、节能开关（布尔）、备注（**可空**
//    字符串 ≤64——空串是合法业务值，与设置计数「非空」规则相反）；
//  - 独立 resourceId（9801）与独立外部授权身份（thermo agent）；
//  - 独立 bundle（labs/ohos_thermo_app，com.example.cjguithermo）与独立传输
//    端口（7857，由该 lab 的宿主层声明）。
//
// 领域规则只有这一份（仓颉 owner）：人与外部经同一 execute，遵守同一版本契约。
// 控制器把规则投影为 CJGUI 组件树；宿主差异不进入本文件。

package cjgui_thermostat_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.random.*

/// 已应用的真实业务状态（无草稿层：设置类动作直接生效）。
public class CjguiThermostatSnapshot {
    public let version: Int64
    public let targetTemp: Int64
    public let eco: Bool
    public let note: String
    public let imageVersion: Int64
    public init(version: Int64, targetTemp: Int64, eco: Bool, note: String, imageVersion: Int64) {
        this.version = version; this.targetTemp = targetTemp; this.eco = eco
        this.note = note
        this.imageVersion = imageVersion
    }
}

public class CjguiThermostatDomain <: CjguiSharedOperationDomain & CjguiSharedOperationChangeDomain {
    public static let resourceId: Int64 = 9801
    public static let tempMin: Int64 = 16
    public static let tempMax: Int64 = 30
    // 备注可空：空串合法；非空时不超过 64 个 Unicode 标量。
    // 与生成字段公开的 maximumLength 使用同一单位。
    public static let noteMaxUnits: Int64 = 64

    private var versionValue: Int64
    private var targetTempValue: Int64
    private var ecoValue: Bool
    private var noteValue: String
    private var imageVersionValue: Int64
    private var imageCatalog: ?CjguiGeneratedUiCapabilityCatalog
    private let streamIdentity: String
    private let changeLog: ArrayList<CjguiSharedOperationChangeEntry>

    public init() {
        this.versionValue = 0
        this.targetTempValue = 22
        this.ecoValue = false
        this.noteValue = ""
        this.imageVersionValue = 1
        this.imageCatalog = None
        // 每次启动的 capability 均为新发；编入流标识防跨重启续读。
        this.streamIdentity = "thermostat_stream_${Random().nextUInt64()}"
        this.changeLog = ArrayList<CjguiSharedOperationChangeEntry>()
    }

    public func resourceType(): String { return "thermostat" }

    public func thermostatSnapshot(): CjguiThermostatSnapshot {
        return CjguiThermostatSnapshot(versionValue, targetTempValue, ecoValue, noteValue,
            imageVersionValue)
    }

    public func imageResourceSpec(): CjguiGeneratedUiImageResourceSpec {
        return CjguiThermostatImage.spec(imageVersionValue)
    }

    public func bindImageCatalog(catalog: CjguiGeneratedUiCapabilityCatalog): Unit {
        imageCatalog = Some(catalog)
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(versionValue, "恒温示例", resourceType(),
            ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(CjguiThermostatDomain.resourceId, "恒温器",
                    ArrayList<CjguiSharedOperationField>([
                        CjguiSharedOperationField("targetTemp", CjguiSharedOperationValue.integer(targetTempValue)),
                        CjguiSharedOperationField("eco", CjguiSharedOperationValue.boolean(ecoValue)),
                        CjguiSharedOperationField("tempRange", CjguiSharedOperationValue.string("16-30")),
                        CjguiSharedOperationField("note", CjguiSharedOperationValue.string(noteValue)),
                        CjguiSharedOperationField("imageVersion", CjguiSharedOperationValue.integer(imageVersionValue))
                    ]))
            ]))
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            CjguiSharedOperationActionDescriptor("TEMP_UP", "目标温度加一",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("TEMP_DOWN", "目标温度减一",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("SWITCH_IMAGE", "切换恒温热图",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("SET_ECO", "设置节能开关",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("value", "BOOLEAN", true)
                ]), 1, 1),
            CjguiSharedOperationActionDescriptor("SET_NOTE", "设置备注（可空）",
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
                resourceFilter[0] == CjguiThermostatDomain.resourceId)) {
                changes.add(entry)
            }
        }
        return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, false, changes)
    }

    // 唯一的业务执行入口：人与外部共用，规则与原子性只在这里。
    private func execute(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = versionValue
        if (invocation.targetResourceIds.size != 1 ||
            invocation.targetResourceIds[0] != CjguiThermostatDomain.resourceId) {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_target")
        }
        if (invocation.expectedVersion != versionValue) {
            return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict")
        }
        if (invocation.actionName == "TEMP_UP") {
            return applyTemp(before, targetTempValue + 1)
        }
        if (invocation.actionName == "TEMP_DOWN") {
            return applyTemp(before, targetTempValue - 1)
        }
        if (invocation.actionName == "SWITCH_IMAGE") {
            let nextVersion: Int64 = if (imageVersionValue == 1) { 2 } else { 1 }
            if (let Some(catalog) <- imageCatalog) {
                if (!catalog.updateImageResource(CjguiThermostatImage.spec(nextVersion))) {
                    return rejected(before, false, catalog.lastRegistrationRejection())
                }
            }
            imageVersionValue = nextVersion
            versionValue += 1
            recordChange("image_changed")
            return accepted(before, "image_changed")
        }
        if (invocation.actionName == "SET_ECO") {
            for (argument in invocation.arguments) {
                if (argument.name == "value" && argument.value.valueType == "BOOLEAN") {
                    ecoValue = argument.value.booleanValue
                    versionValue += 1
                    recordChange(if (ecoValue) { "eco_enabled" } else { "eco_disabled" })
                    return accepted(before, "eco_state_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        if (invocation.actionName == "SET_NOTE") {
            for (argument in invocation.arguments) {
                if (argument.name == "text" && argument.value.valueType == "STRING") {
                    let next = argument.value.stringValue
                    // 备注规则：**可空**（空串是合法业务值），非空 ≤64 码元。
                    // 这与设置计数的「非空」规则相反，是本消费者的存在理由之一。
                    if (CjguiSharedFieldRule.scalarCount(next) > CjguiThermostatDomain.noteMaxUnits) {
                        return rejected(before, false, "note_out_of_range")
                    }
                    noteValue = next
                    versionValue += 1
                    recordChange("note_changed")
                    return accepted(before, "note_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        return rejected(before, false, "invalid_action")
    }

    private func applyTemp(before: Int64, next: Int64): CjguiSharedOperationActionResult {
        if (next < CjguiThermostatDomain.tempMin || next > CjguiThermostatDomain.tempMax) {
            // 越界拒绝：不产生部分业务写入。
            return rejected(before, false, "temp_out_of_range")
        }
        targetTempValue = next
        versionValue += 1
        recordChange("target_temp_changed")
        return accepted(before, "target_temp_changed")
    }

    private func recordChange(kind: String) {
        changeLog.add(CjguiSharedOperationChangeEntry(versionValue, CjguiThermostatDomain.resourceId, kind))
    }

    private func rejected(before: Int64, conflict: Bool, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, conflict, before, before, reason)
    }

    private func accepted(before: Int64, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(true, false, before, versionValue, reason)
    }
}

/// 授权：外部 Agent 可读取上下文/变更并调用与人类相同的动作。
/// 身份与设置计数示例完全不同（独立 agent 标识）。
public func thermostatAuthorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization("恒温示例本地 Agent", "cjgui-thermo-agent-20260926",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("TEMP_UP", all, true),
            CjguiSharedOperationExternalActionScope("TEMP_DOWN", all, true),
            CjguiSharedOperationExternalActionScope("SWITCH_IMAGE", all, true),
            CjguiSharedOperationExternalActionScope("SET_ECO", all, true),
            CjguiSharedOperationExternalActionScope("SET_NOTE", all, true)
        ]))
}

/// 控制器：把领域状态投影为 CJGUI 组件树；人机共用同一身份与样式。
public class CjguiThermostatController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiBusinessOwnerRevisionProvider {
    public static let nodeIdTempDown: Int64 = 21
    public static let nodeIdTempUp: Int64 = 22
    public static let nodeIdEco: Int64 = 23
    public static let nodeIdNote: Int64 = 24
    public static let nodeIdImage: Int64 = 31
    public static let nodeIdImageSwitch: Int64 = 32

    private let domain: CjguiThermostatDomain
    private let generatedRegion: CjguiGeneratedUiWindowRegion
    private var localRevision: Int64
    private var statusText: String

    public init(domain: CjguiThermostatDomain) {
        this.domain = domain
        this.generatedRegion = CjguiGeneratedUiWindowRegion(
            CjguiThermostatGeneratedBinding.catalog(domain), CjguiThermostatGeneratedBinding(domain),
            "thermo-generated")
        this.localRevision = 1
        this.statusText = "编辑后应用恒温配置"
    }

    public func uiSceneVersion(): Int64 {
        return localRevision + domain.thermostatSnapshot().version + generatedRegion.revision()
    }

    public func uiBusinessOwnerRevision(): Int64 { return domain.thermostatSnapshot().version }

    public func generatedUiRegion(): CjguiGeneratedUiWindowRegion { return generatedRegion }

    public func beginSceneRefresh(): Bool { return generatedRegion.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return generatedRegion.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { generatedRegion.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { generatedRegion.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { generatedRegion.disposeSceneRefreshResources() }

    public func buildUi(): CjguiComposableUiNode {
        let snapshot = domain.thermostatSnapshot()
        let heading = CjguiComposableUiStyle(fixedHeight: 52, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0),
            fontSize: 30.0, fontWeight: 700)
        let value = CjguiComposableUiStyle(fixedHeight: 84, textColor: CjguiComposableUiColor(1.0, 0.82, 0.55, 1.0),
            fontSize: 54.0, fontWeight: 600)
        let action = CjguiComposableUiStyle(fixedWidth: 190, fixedHeight: 64, gap: 16,
            background: CjguiComposableUiColor(0.42, 0.24, 0.12, 1.0),
            border: CjguiComposableUiColor(0.66, 0.44, 0.26, 1.0), borderWidth: 2,
            cornerRadius: 14, fontSize: 30.0, fontWeight: 600,
            textColor: CjguiComposableUiColor(0.98, 0.94, 0.90, 1.0))
        let card = CjguiComposableUiStyle(growX: 1, padding: 24, gap: 14,
            background: CjguiComposableUiColor(0.16, 0.13, 0.10, 1.0),
            border: CjguiComposableUiColor(0.38, 0.30, 0.22, 1.0), borderWidth: 1,
            cornerRadius: 18)

        let root = cjguiComposableVertical(1, "thermo-root",
            CjguiComposableUiStyle(padding: 28, gap: 18,
                background: CjguiComposableUiColor(0.10, 0.07, 0.05, 1.0)))
        root.add(cjguiComposableText(10, "thermo-title", "恒温示例", heading))

        let cardBox = cjguiComposableVertical(15, "thermo-card", card)
        cardBox.add(cjguiComposableText(12, "thermo-value", "目标温度：${snapshot.targetTemp}℃",
            value, resourceId: CjguiThermostatDomain.resourceId, fieldId: "targetTemp",
            displayValueRole: "applied"))
        let image = domain.imageResourceSpec()
        let imageRow = cjguiComposableHorizontal(29, "thermo-image-row",
            CjguiComposableUiStyle(fixedHeight: 72, gap: 16))
        imageRow.add(cjguiComposableImage(CjguiThermostatController.nodeIdImage, "thermo-heat-map",
            image.rasterPath, CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 72),
            contentMode: 1, imageResourceId: image.key, imageResourceVersion: image.version))
        imageRow.add(cjguiComposableButton(CjguiThermostatController.nodeIdImageSwitch,
            "thermo-image-switch", "切换热图", "SWITCH_IMAGE", CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 60,
                background: CjguiComposableUiColor(0.43, 0.27, 0.12, 1.0),
                textColor: CjguiComposableUiColor(0.98, 0.94, 0.90, 1.0))))
        cardBox.add(imageRow)
        let actions = cjguiComposableHorizontal(20, "thermo-actions",
            CjguiComposableUiStyle(fixedHeight: 64, gap: 16))
        actions.add(cjguiComposableButton(CjguiThermostatController.nodeIdTempDown, "thermo-down",
            "降温", "TEMP_DOWN", CjguiThermostatDomain.resourceId, action))
        actions.add(cjguiComposableButton(CjguiThermostatController.nodeIdTempUp, "thermo-up",
            "升温", "TEMP_UP", CjguiThermostatDomain.resourceId, action))
        cardBox.add(actions)
        cardBox.add(cjguiComposableBooleanInput(CjguiThermostatController.nodeIdEco, "thermo-eco",
            "节能模式", snapshot.eco, CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 56, fontSize: 26.0,
                textColor: CjguiComposableUiColor(0.92, 0.90, 0.82, 1.0)),
            fieldId: "eco", operationActionName: "SET_ECO", displayValueRole: "applied"))
        // 备注字段：可空字符串（空串合法）——与设置计数的非空规则相反。
        cardBox.add(cjguiComposableTextInput(CjguiThermostatController.nodeIdNote, "thermo-note",
            "备注", snapshot.note, CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 72, growX: 1, fontSize: 28.0,
                background: CjguiComposableUiColor(0.13, 0.10, 0.07, 1.0),
                border: CjguiComposableUiColor(0.44, 0.36, 0.26, 1.0), borderWidth: 1,
                cornerRadius: 10, textColor: CjguiComposableUiColor(0.95, 0.93, 0.88, 1.0)),
            fieldId: "note", operationActionName: "SET_NOTE", displayValueRole: "applied"))
        cardBox.add(cjguiComposableText(30, "thermo-status", statusLine(), value,
            resourceId: CjguiThermostatDomain.resourceId, fieldId: "eco",
            displayValueRole: "applied"))
        root.add(cardBox)
        // Every accepted generated node enters the same layout, scene and
        // XComponent input path as the handwritten controls above.
        let generatedBox = cjguiComposableVertical(800, "thermo-generated-region",
            CjguiComposableUiStyle(growX: 1, gap: 8))
        generatedBox.add(generatedRegion.buildNode())
        root.add(generatedBox)
        return root
    }

    private func statusLine(): String {
        let snapshot = domain.thermostatSnapshot()
        let note = if (snapshot.note.size > 0) { "备注：${snapshot.note}" } else { "备注：（空）· 节能 ${snapshot.eco}" }
        return "${statusText} · ${note}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generatedResult = generatedRegion.handleEvent(event)
        if (generatedResult.didApply) {
            localRevision += 1
            return generatedResult
        }
        let snapshot = domain.thermostatSnapshot()
        if (event.eventKind == 27 && event.node.nodeId == CjguiThermostatController.nodeIdImageSwitch) {
            return applyImage(domain.executeFromHuman(invoke("SWITCH_IMAGE", snapshot.version)))
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiThermostatController.nodeIdTempUp) {
            return applyTemp(domain.executeFromHuman(invoke("TEMP_UP", snapshot.version)))
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiThermostatController.nodeIdTempDown) {
            return applyTemp(domain.executeFromHuman(invoke("TEMP_DOWN", snapshot.version)))
        }
        if (event.eventKind == 29 && event.node.nodeId == CjguiThermostatController.nodeIdEco) {
            let next = event.text == "true"
            return applyEco(domain.executeFromHuman(invokeBoolean(next, snapshot.version)))
        }
        if (event.eventKind == 28 && event.node.nodeId == CjguiThermostatController.nodeIdNote) {
            return applyNote(domain.executeFromHuman(invokeNote(event.text, snapshot.version)))
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
            ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>())
    }

    private func invokeBoolean(value: Bool, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("SET_ECO", expectedVersion,
            ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.boolean(value))
            ]))
    }

    private func invokeNote(text: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("SET_NOTE", expectedVersion,
            ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))
            ]))
    }

    private func applyTemp(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.thermostatSnapshot()
        statusText = if (result.applied) {
            "目标温度已应用 v${result.versionAfter} · ${snapshot.targetTemp}℃"
        } else if (result.reason == "temp_out_of_range") {
            "温度未应用：16-30℃（当前 ${snapshot.targetTemp}℃）"
        } else if (result.reason == "version_conflict") {
            "温度未应用：内容已被外部更新，请基于新值重试"
        } else {
            "温度未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyImage(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        statusText = if (result.applied) { "热图已切换到 v${domain.thermostatSnapshot().imageVersion}" }
            else { "热图未切换：${result.reason}" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyEco(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.thermostatSnapshot()
        statusText = if (result.applied) { "节能已应用 v${result.versionAfter} · ${snapshot.eco}" }
            else if (result.reason == "version_conflict") { "节能未应用：内容已被外部更新" }
            else { "节能未应用：${result.reason}" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyNote(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.thermostatSnapshot()
        statusText = if (result.applied) {
            "备注已应用 v${result.versionAfter} · ${snapshot.note}"
        } else if (result.reason == "note_out_of_range") {
            "备注未应用：≤64 字符（当前 ${snapshot.note}）"
        } else if (result.reason == "version_conflict") {
            "备注未应用：内容已被外部更新，请基于新值重试"
        } else {
            "备注未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }
}
