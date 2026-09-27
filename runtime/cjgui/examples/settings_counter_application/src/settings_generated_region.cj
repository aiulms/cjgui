// Settings-specific declarations and owner bindings for the shared generated
// window region. All writes still enter CjguiSettingsCounterDomain.execute.
package cjgui_settings_counter_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

/// The application owns the two packaged rasters and their public identity.
/// Both handwritten and generated nodes resolve this exact declaration.
public class CjguiSettingsCounterImage {
    public static let key: String = "settings-beacon"

    public static func spec(version: Int64): CjguiGeneratedUiImageResourceSpec {
        // The normal HAP has no override; macOS same-source consumers may point
        // this app-owned declaration at the checked-in rawfile fixture directory.
        let directory = match (getVariable("CJGUI_IMAGE_FIXTURE_DIR")) {
            case Some(path) => path
            case None => "/data/storage/el2/base/files"
        }
        return CjguiGeneratedUiImageResourceSpec(key, "PNG", version, "设置标志图",
            "${directory}/cjgui_image_v${version}.png")
    }
}

/// One authored field declaration feeds the public generated catalog and its
/// event binding. The domain owns the length bounds and enforces them for every
/// caller, including handwritten inputs and external operation invocations.
public class CjguiSettingsCounterFieldDefinition {
    public let fieldId: String
    public let label: String
    public let editorKind: String
    public let writer: String
    public let argument: String
    public let maximumLength: Int64

    public init(fieldId: String, label: String, editorKind: String, writer: String,
                argument: String, maximumLength!: Int64 = 0) {
        this.fieldId = fieldId
        this.label = label
        this.editorKind = editorKind
        this.writer = writer
        this.argument = argument
        this.maximumLength = maximumLength
    }
}

public class CjguiSettingsCounterFields {
    public static func definitions(): ArrayList<CjguiSettingsCounterFieldDefinition> {
        return ArrayList<CjguiSettingsCounterFieldDefinition>([
            CjguiSettingsCounterFieldDefinition("name", "名称", "TEXT", "EDIT_NAME", "text",
                maximumLength: CjguiSettingsCounterDomain.nameMaxUnits),
            CjguiSettingsCounterFieldDefinition("alias", "别名", "TEXT", "EDIT_ALIAS", "text",
                maximumLength: CjguiSettingsCounterDomain.aliasMaxUnits),
            CjguiSettingsCounterFieldDefinition("enabled", "启用计数", "BOOLEAN", "SET_ENABLED", "value")
        ])
    }

    public static func definition(fieldId: String): ?CjguiSettingsCounterFieldDefinition {
        for (field in definitions()) {
            if (field.fieldId == fieldId) { return Some(field) }
        }
        return None
    }
}

public class CjguiSettingsCounterGeneratedBinding <: CjguiGeneratedUiRegionBinding {
    private let domain: CjguiSettingsCounterDomain

    public init(domain: CjguiSettingsCounterDomain) { this.domain = domain }

    public func ownerRevision(): Int64 { return domain.counterSnapshot().version }

    public func fieldResourceId(fieldId: String): Int64 {
        return match (CjguiSettingsCounterFields.definition(fieldId)) {
            case Some(_) => CjguiSettingsCounterDomain.resourceId
            case None => -1
        }
    }

    public func fieldOperationResourceId(fieldId: String): Int64 {
        return fieldResourceId(fieldId)
    }

    public func draftText(fieldId: String): String { return appliedText(fieldId) }

    public func appliedText(fieldId: String): String {
        let snapshot = domain.counterSnapshot()
        if (fieldId == "name") { return snapshot.name }
        if (fieldId == "alias") { return snapshot.alias }
        return ""
    }

    public func draftBoolean(fieldId: String): ?Bool {
        if (fieldId == "enabled") { return Some(domain.counterSnapshot().enabled) }
        return None
    }

    public func draftSource(fieldId: String): String {
        let _ = fieldId
        return "owner_applied"
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return match (CjguiSettingsCounterFields.definition(fieldId)) {
            case Some(_) => CjguiSharedAvailability.allowed(CjguiSettingsCounterDomain.resourceId,
                ownerRevision())
            case None => CjguiSharedAvailability.unknown()
        }
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        if (actionName == "SWITCH_IMAGE") {
            return CjguiSharedAvailability.allowed(CjguiSettingsCounterDomain.resourceId, ownerRevision())
        }
        if (actionName != "INCREMENT" && actionName != "DECREMENT") {
            return CjguiSharedAvailability.unknown()
        }
        let snapshot = domain.counterSnapshot()
        if (!snapshot.enabled) {
            return CjguiSharedAvailability.blocked("counter_disabled",
                CjguiSettingsCounterDomain.resourceId, snapshot.version)
        }
        if ((actionName == "INCREMENT" && snapshot.count >= CjguiSettingsCounterDomain.counterMax) ||
            (actionName == "DECREMENT" && snapshot.count <= CjguiSettingsCounterDomain.counterMin)) {
            return CjguiSharedAvailability.blocked("counter_out_of_range",
                CjguiSettingsCounterDomain.resourceId, snapshot.version)
        }
        return CjguiSharedAvailability.allowed(CjguiSettingsCounterDomain.resourceId, snapshot.version)
    }

    public func actionAvailable(actionName: String): Bool {
        return actionAvailability(actionName).isAvailable
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        if (actionName != "INCREMENT" && actionName != "DECREMENT" && actionName != "SWITCH_IMAGE") {
            return CjguiGeneratedUiActionResult(false, "invalid_action")
        }
        let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation(actionName,
            domain.counterSnapshot().version, ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>()))
        return CjguiGeneratedUiActionResult(result.applied, result.reason)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        let definition = match (CjguiSettingsCounterFields.definition(intent.fieldId)) {
            case Some(value) => value
            case None => return CjguiComposableUiDispatchResult(false)
        }
        if (intent.writerOperation != definition.writer || intent.argumentName != definition.argument ||
            intent.ownerTargetResourceId != CjguiSettingsCounterDomain.resourceId) {
            return CjguiComposableUiDispatchResult(false)
        }
        let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation(definition.writer,
            domain.counterSnapshot().version, ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument(definition.argument, intent.value)
            ])))
        return CjguiComposableUiDispatchResult(result.applied)
    }
}

private func settingsGeneratedLeafProperties(content: ArrayList<CjguiGeneratedUiPropertySpec>):
    ArrayList<CjguiGeneratedUiPropertySpec> {
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) { content.add(property) }
    return content
}

public func settingsGeneratedCatalog(domain: CjguiSettingsCounterDomain): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog(maxDepth: 8, maxNodes: 96,
        maxPropertiesPerNode: 8, maxStringLength: 160)
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 24))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 24))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        settingsGeneratedLeafProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 160)
        ])), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        settingsGeneratedLeafProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60)
        ])), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput",
        settingsGeneratedLeafProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60)
        ])), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
        settingsGeneratedLeafProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60),
            CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 40)
        ])), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image",
        settingsGeneratedLeafProperties(CjguiGeneratedUiPresentation.imageContentProperties()), false))
    let _ = catalog.registerImageResource(domain.imageResourceSpec())
    domain.bindImageCatalog(catalog)
    for (field in CjguiSettingsCounterFields.definitions()) {
        let _ = catalog.registerField(CjguiGeneratedUiFieldSpec(field.fieldId, field.label,
            field.editorKind, CjguiSettingsCounterDomain.resourceId, writeActionName: field.writer,
            required: true, maximumLength: field.maximumLength, argumentName: field.argument))
    }
    for (action in domain.actionDescriptors()) {
        // Buttons carry no input arguments. Field writers are published through
        // their field specs and use holder.resolveIntent instead.
        if (action.parameters.size == 0) {
            let _ = catalog.registerAction(CjguiGeneratedUiActionSpec(action.name, action.displayName))
        }
    }
    return catalog
}
