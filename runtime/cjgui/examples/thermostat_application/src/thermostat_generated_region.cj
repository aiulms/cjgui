// The thermostat's generated region uses the framework's window-owned holder.
// All values and actions still belong to CjguiThermostatDomain; a description
// can only select the fields and operations declared here.
package cjgui_thermostat_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

/// Thermostat-owned packaged image. Handwritten and generated controls use the
/// same key, version and sandbox resolution; callers never provide a path.
public class CjguiThermostatImage {
    public static let key: String = "thermo-heat-map"

    public static func spec(version: Int64): CjguiGeneratedUiImageResourceSpec {
        let directory = match (getVariable("CJGUI_IMAGE_FIXTURE_DIR")) {
            case Some(path) => path
            case None => "/data/storage/el2/base/files"
        }
        return CjguiGeneratedUiImageResourceSpec(key, "PNG", version, "恒温热图",
            "${directory}/cjgui_image_v${version}.png")
    }
}

public class CjguiThermostatGeneratedBinding <: CjguiGeneratedUiRegionBinding {
    private let domain: CjguiThermostatDomain

    public init(domain: CjguiThermostatDomain) {
        this.domain = domain
    }

    public func ownerRevision(): Int64 { return domain.thermostatSnapshot().version }

    public func fieldResourceId(fieldId: String): Int64 {
        return if (fieldId == "note" || fieldId == "eco") { CjguiThermostatDomain.resourceId } else { -1 }
    }

    public func fieldOperationResourceId(fieldId: String): Int64 { return fieldResourceId(fieldId) }

    public func draftText(fieldId: String): String {
        return if (fieldId == "note") { domain.thermostatSnapshot().note } else { "" }
    }

    public func appliedText(fieldId: String): String { return draftText(fieldId) }

    // R3（h-source-preview-followup 2026-10-02）：备注字段接入生成范围会话的
    // owner 事务文本写。系统输入经框架通用桥（CjguiGeneratedFieldRangeSession）
    // 以精确范围到达这里的 applyTextEdit；规则（可空、≤64 标量）与公开
    // SET_NOTE 完全同一条 owner 事务，不建第二写路径。
    public func rangeTextEditSupported(fieldId: String): Bool {
        return fieldId == "note"
    }

    public func fieldTextVersion(fieldId: String): Int64 {
        return if (fieldId == "note") { ownerRevision() } else { -1 }
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        if (fieldId != "note") {
            return CjguiRangeTextEditOutcome.rejected(-1, "text_edit_unsupported")
        }
        // 与 applyFieldIntent 同一入口/同一规则/同一版本校验（execute 内
        // expectedVersion != versionValue → version_conflict）。
        let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation("SET_NOTE",
            expectedVersion, ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(newText))
            ])))
        if (result.applied) {
            return CjguiRangeTextEditOutcome.accepted(result.versionBefore, result.versionAfter)
        }
        if (result.isVersionConflict) {
            return CjguiRangeTextEditOutcome.conflict(result.versionBefore, result.reason)
        }
        return CjguiRangeTextEditOutcome.rejected(result.versionBefore, result.reason)
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool {
        if (fieldId != "note" || ownerRevision() != expectedVersion) {
            return false
        }
        // owner 循环单线程串行：版本核对与 action 之间无并发写（外部请求经
        // 同一 serveOnce 分发，人与系统输入同队列）。
        return action()
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64,
        startByte: Int64, endByte: Int64): ?(Int64, Int64, Int64) {
        if (fieldId != "note") {
            return None
        }
        return domain.rebaseNoteSelection(fromVersion, startByte, endByte)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return if (fieldId == "eco") { Some(domain.thermostatSnapshot().eco) } else { None }
    }

    public func actionAvailable(actionName: String): Bool {
        if (actionName == "SWITCH_IMAGE") { return true }
        let temp = domain.thermostatSnapshot().targetTemp
        if (actionName == "TEMP_UP") { return temp < CjguiThermostatDomain.tempMax }
        if (actionName == "TEMP_DOWN") { return temp > CjguiThermostatDomain.tempMin }
        return false
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        let target = fieldResourceId(fieldId)
        if (target < 0) { return CjguiSharedAvailability.unknown() }
        return CjguiSharedAvailability.allowed(target, ownerRevision())
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        if (actionName == "SWITCH_IMAGE") {
            return CjguiSharedAvailability.allowed(CjguiThermostatDomain.resourceId, ownerRevision())
        }
        if (actionName != "TEMP_UP" && actionName != "TEMP_DOWN") {
            return CjguiSharedAvailability.unknown()
        }
        return if (actionAvailable(actionName)) {
            CjguiSharedAvailability.allowed(CjguiThermostatDomain.resourceId, ownerRevision())
        } else {
            CjguiSharedAvailability.blocked("temp_out_of_range", CjguiThermostatDomain.resourceId, ownerRevision())
        }
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        if (actionName != "TEMP_UP" && actionName != "TEMP_DOWN" && actionName != "SWITCH_IMAGE") {
            return CjguiGeneratedUiActionResult(false, "invalid_action")
        }
        let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation(actionName,
            ownerRevision(), ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>()))
        return CjguiGeneratedUiActionResult(result.applied, result.reason)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        if (!intent.isFieldEdit() || intent.ownerTargetResourceId != CjguiThermostatDomain.resourceId) {
            return CjguiComposableUiDispatchResult(false)
        }
        let spec = CjguiThermostatGeneratedBinding.fieldFor(intent.fieldId)
        let expectedType = if (spec.editorKind == "BOOLEAN") { "BOOLEAN" } else { "STRING" }
        if (spec.fieldId.isEmpty() || intent.writerOperation != spec.writeActionName ||
            intent.argumentName != spec.argumentName || intent.value.valueType != expectedType) {
            return CjguiComposableUiDispatchResult(false)
        }
        let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation(intent.writerOperation,
            ownerRevision(), ArrayList<Int64>([intent.ownerTargetResourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument(intent.argumentName, intent.value)
            ])))
        return CjguiComposableUiDispatchResult(result.applied)
    }

    public static func fieldFor(fieldId: String): CjguiGeneratedUiFieldSpec {
        for (field in CjguiThermostatGeneratedBinding.fields()) {
            if (field.fieldId == fieldId) { return field }
        }
        return CjguiGeneratedUiFieldSpec("", "", "", -1)
    }

    /// These declarations carry the same owner actions and limit used by the
    /// handwritten controls and domain rule. Only presentation differs.
    public static func fields(): ArrayList<CjguiGeneratedUiFieldSpec> {
        return ArrayList<CjguiGeneratedUiFieldSpec>([
            CjguiGeneratedUiFieldSpec("note", "备注", "TEXT", CjguiThermostatDomain.resourceId,
                writeActionName: "SET_NOTE", maximumLength: CjguiThermostatDomain.noteMaxUnits,
                argumentName: "text"),
            CjguiGeneratedUiFieldSpec("eco", "节能模式", "BOOLEAN", CjguiThermostatDomain.resourceId,
                writeActionName: "SET_ECO", argumentName: "value")
        ])
    }

    private static func withStyle(content: ArrayList<CjguiGeneratedUiPropertySpec>,
                                  style: ArrayList<CjguiGeneratedUiPropertySpec>):
        ArrayList<CjguiGeneratedUiPropertySpec> {
        let all = ArrayList<CjguiGeneratedUiPropertySpec>()
        for (property in content) { all.add(property) }
        for (property in style) { all.add(property) }
        return all
    }

    public static func catalog(domain: CjguiThermostatDomain): CjguiGeneratedUiCapabilityCatalog {
        let catalog = CjguiGeneratedUiCapabilityCatalog()
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
            CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 16))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
            CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 16))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
            withStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 200)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
            withStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput",
            withStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
            withStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60),
                CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 60)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let imageProperties = CjguiGeneratedUiPresentation.imageContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            imageProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image", imageProperties, false))
        let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            scrollProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
            childLimit: 1))
        let _ = catalog.registerImageResource(domain.imageResourceSpec())
        domain.bindImageCatalog(catalog)
        for (field in fields()) { let _ = catalog.registerField(field) }
        // Only parameter-free owner actions can be selected by generated
        // buttons; editors use their field's declared writer/argument.
        for (action in domain.actionDescriptors()) {
            if (action.name == "TEMP_UP" || action.name == "TEMP_DOWN" || action.name == "SWITCH_IMAGE") {
                let _ = catalog.registerAction(CjguiGeneratedUiActionSpec(action.name, action.displayName))
            }
        }
        return catalog
    }
}
