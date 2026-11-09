package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

private func cjguiGeneratedFormLeafProperties(content: ArrayList<CjguiGeneratedUiPropertySpec>, readonly: Bool): ArrayList<CjguiGeneratedUiPropertySpec> {
    var styledText = false
    for (property in content) { if (property.name == "text") { styledText = readonly } }
    let style = if (styledText) {
        CjguiGeneratedUiPresentation.styledTextStyleProperties()
    } else if (readonly) {
        CjguiGeneratedUiPresentation.readonlyTextStyleProperties()
    } else {
        CjguiGeneratedUiPresentation.leafStyleProperties()
    }
    for (property in style) {
        content.add(property)
    }
    return content
}

/// Experimental adapter for the existing editable-form contract. Declarations
/// come from formBinding; every value/write remains in the serial form owner.
/// It owns no draft, selection history, input queue, or generated structure.
public class CjguiGeneratedUiFormBinding <: CjguiGeneratedUiRegionBinding {
    private let domain: CjguiSharedEditableFormDomain
    private let ownerResourceId: Int64
    private let fields: ArrayList<CjguiGeneratedUiFieldSpec>
    private let selectBindings: ArrayList<CjguiSelectFieldBinding>
    // Bounded per-field body history. A standard form edit replaces the whole
    // value, so a cross-version selection can only be mapped when this
    // provider remembers the older body; the generic range bridge never
    // substitutes a caret policy for a provider refusal.
    private static let fieldBodyHistoryLimit: Int64 = 4
    private let fieldBodies: HashMap<String, ArrayList<(Int64, String)>> = HashMap<String, ArrayList<(Int64, String)>>()

    public init(domain: CjguiSharedEditableFormDomain, ownerResourceId: Int64,
        selectBindings!: ArrayList<CjguiSelectFieldBinding> = ArrayList<CjguiSelectFieldBinding>()) {
        this.domain = domain
        this.ownerResourceId = ownerResourceId
        this.selectBindings = ArrayList<CjguiSelectFieldBinding>(selectBindings)
        // A declared select is the field's presentation: the published field
        // kind must name it so any generated consumer builds the same control
        // instead of the editor kind's default input.
        let selectIds = ArrayList<String>()
        for (declaredSelect in this.selectBindings) { selectIds.add(declaredSelect.fieldId) }
        this.fields = CjguiGeneratedUiFieldSpec.fromFormBinding(domain.formBinding(), textArgument: "text",
            booleanArgument: "value", selectFieldIds: Some(selectIds))
        for (declaredSelect in this.selectBindings) {
            var known = false
            for (field in this.fields) { if (field.fieldId == declaredSelect.fieldId) { known = true } }
            if (!known) { throw IllegalArgumentException("select_binding_unknown_field:${declaredSelect.fieldId}") }
        }
    }

    public func generatedSelectBinding(fieldId: String): ?CjguiSelectFieldBinding {
        for (declaredSelect in selectBindings) {
            if (declaredSelect.fieldId == fieldId) { return Some(declaredSelect) }
        }
        return None
    }

    public func generatedSelectBindings(): ArrayList<CjguiSelectFieldBinding> {
        return ArrayList<CjguiSelectFieldBinding>(selectBindings)
    }

    public func fieldSpecs(): ArrayList<CjguiGeneratedUiFieldSpec> {
        return ArrayList<CjguiGeneratedUiFieldSpec>(fields)
    }

    /// Opt-in standard form vocabulary. Field constraints and action signatures
    /// come from the same domain; callers can instead build their own catalog.
    /// Stability: experimental. Presentation consumption is currently macOS.
    public func capabilityCatalog(maxDepth!: Int64 = 8, maxNodes!: Int64 = 48, maxStringLength!: Int64 = 256): CjguiGeneratedUiCapabilityCatalog {
        let catalog = CjguiGeneratedUiCapabilityCatalog(maxDepth: maxDepth, maxNodes: maxNodes, maxPropertiesPerNode: 16,
            maxStringLength: maxStringLength)
        for (kind in ["vertical", "horizontal"]) {
            let _ = catalog.registerComponent(
                CjguiGeneratedUiComponentSpec(kind, CjguiGeneratedUiPresentation.containerStyleProperties(), true,
                    childLimit: 12))
        }
        let _ = catalog.registerComponent(
            CjguiGeneratedUiComponentSpec("label",
                cjguiGeneratedFormLeafProperties(
                    ArrayList<CjguiGeneratedUiPropertySpec>(
                        [CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: maxStringLength)]),
                    true), false))
        // Only an application that actually declared Select fields publishes
        // the kind; existing forms keep their exact catalog vocabulary.
        if (selectBindings.size > 0) {
            let selectProperties = ArrayList<CjguiGeneratedUiPropertySpec>()
            selectProperties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
            selectProperties.add(CjguiGeneratedUiPropertySpec("placeholder", "STRING", maxLength: 80))
            selectProperties.add(CjguiGeneratedUiPropertySpec("searchable", "BOOLEAN", defaultValue: "false"))
            if (!catalog.registerComponent(
                CjguiGeneratedUiComponentSpec("select", cjguiGeneratedFormLeafProperties(selectProperties, false), false))) {
                throw Exception("select_component_registration:${catalog.registrationIssue()}")
            }
            // The always-visible presentations of the SAME field share its
            // options and commit; their catalogs deliberately omit
            // searchable/placeholder, so naming those is a named rejection.
            if (!catalog.registerComponent(cjguiGeneratedRadioGroupComponent()) ||
                !catalog.registerComponent(cjguiGeneratedSegmentedComponent())) {
                throw Exception("choice_component_registration:${catalog.registrationIssue()}")
            }
        }
        for (kind in ["textInput", "integerInput", "booleanInput"]) {
            let _ = catalog.registerComponent(
                CjguiGeneratedUiComponentSpec(kind,
                    cjguiGeneratedFormLeafProperties(
                        ArrayList<CjguiGeneratedUiPropertySpec>(
                            [CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80)]), false), false))
        }
        let _ = catalog.registerComponent(
            CjguiGeneratedUiComponentSpec("action",
                cjguiGeneratedFormLeafProperties(
                    ArrayList<CjguiGeneratedUiPropertySpec>(
                        [CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80),
                            CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 64)]), true), false))
        let _ = catalog.registerFields(fieldSpecs())
        // The choice options can only be published after their fields exist:
        // one option list per choice field, consumed by all three
        // presentations and published verbatim by the discovery text.
        for (declaredSelect in selectBindings) {
            if (!catalog.registerChoiceOptions(declaredSelect.fieldId, declaredSelect.options())) {
                throw Exception("choice_options_registration:${catalog.registrationIssue()}")
            }
            // Dynamic options: discovery and validation read the binding's
            // CURRENT list, never the registration copy.
            if (!catalog.bindChoiceOptions(declaredSelect.fieldId, declaredSelect)) {
                throw Exception("choice_options_binding:${catalog.registrationIssue()}")
            }
        }
        for (action in domain.actionDescriptors()) {
            if (action.name == "APPLY_DRAFT" || action.name == "CANCEL_DRAFT") {
                let parameters = ArrayList<String>()
                for (parameter in action.parameters) {
                    parameters.add(parameter.name)
                }
                let _ = catalog.registerAction(
                    CjguiGeneratedUiActionSpec(action.name, action.displayName, parameterNames: parameters))
            }
        }
        return catalog
    }

    public func fieldSpec(fieldId: String): ?CjguiGeneratedUiFieldSpec {
        for (field in fields) {
            if (field.fieldId == fieldId) {
                return Some(field)
            }
        }
        return None
    }

    public func ownerRevision(): Int64 {
        return domain.formSnapshot().contextVersion
    }
    public func fieldResourceId(fieldId: String): Int64 {
        return match (fieldSpec(fieldId)) {
            case Some(field) => field.resourceId;
            case None => -1
        }
    }
    public func fieldOperationResourceId(fieldId: String): Int64 {
        return if (fieldSpec(fieldId).isSome()) {
            ownerResourceId
        } else {
            -1
        }
    }
    public func draftText(fieldId: String): String {
        let id = fieldResourceId(fieldId)
        if (id < 0) {
            return ""
        }
        let projection = domain.formSnapshot().fieldForResourceId(id)
        this.rememberFieldBody(fieldId, projection.draftFieldVersion, projection.draftText)
        return projection.draftText
    }
    private func rememberFieldBody(fieldId: String, version: Int64, text: String): Unit {
        var entries: ArrayList<(Int64, String)>
        if (let Some(existing) <- fieldBodies.get(fieldId)) {
            entries = existing
        } else {
            entries = ArrayList<(Int64, String)>()
            fieldBodies.add(fieldId, entries)
        }
        var index = 0
        while (index < entries.size) {
            if (entries[index][0] == version) {
                entries[index] = (version, text)
                return
            }
            index += 1
        }
        entries.add((version, text), at: 0)
        while (entries.size > fieldBodyHistoryLimit) {
            let _ = entries.remove(at: entries.size - 1)
        }
    }
    private func fieldBodyAt(fieldId: String, version: Int64): ?String {
        if (let Some(entries) <- fieldBodies.get(fieldId)) {
            for (entry in entries) {
                if (entry[0] == version) {
                    return Some(entry[1])
                }
            }
        }
        return None
    }
    private func validFieldSelection(text: String, startByte: Int64, endByte: Int64): Bool {
        let bytes = text.toArray()
        return startByte >= 0 && endByte >= startByte && endByte <= bytes.size &&
            cjguiIsUtf8Boundary(bytes, startByte) && cjguiIsUtf8Boundary(bytes, endByte)
    }
    public func appliedText(fieldId: String): String {
        let id = fieldResourceId(fieldId)
        return if (id >= 0) {
            domain.formSnapshot().fieldForResourceId(id).appliedValue.displayText()
        } else {
            ""
        }
    }
    public func draftBoolean(fieldId: String): ?Bool {
        let spec = match (fieldSpec(fieldId)) {
            case Some(value) => value;
            case None => return None
        }
        return if (spec.editorKind == "BOOLEAN") {
            Some(draftText(fieldId) == "true")
        } else {
            None
        }
    }
    public func appliedBoolean(fieldId: String): ?Bool {
        let spec = match (fieldSpec(fieldId)) {
            case Some(value) => value;
            case None => return None
        }
        return if (spec.editorKind == "BOOLEAN") {
            Some(domain.formSnapshot().fieldForResourceId(spec.resourceId).appliedValue.booleanValue)
        } else {
            None
        }
    }
    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return fieldAvailabilityForSnapshot(fieldId, domain.formSnapshot())
    }
    private func fieldAvailabilityForSnapshot(fieldId: String, snapshot: CjguiSharedFormSnapshot): CjguiSharedAvailability {
        return if (fieldSpec(fieldId).isSome() && ownerResourceId >= 0) {
            CjguiSharedAvailability.allowed(ownerResourceId, snapshot.contextVersion)
        } else {
            CjguiSharedAvailability.unknown()
        }
    }
    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return actionAvailabilityForSnapshot(actionName, domain.formSnapshot())
    }
    private func actionAvailabilityForSnapshot(actionName: String, snapshot: CjguiSharedFormSnapshot): CjguiSharedAvailability {
        if (actionName != "APPLY_DRAFT" && actionName != "CANCEL_DRAFT") {
            return CjguiSharedAvailability.unknown()
        }
        if (actionName == "APPLY_DRAFT" && !snapshot.canApply) {
            return CjguiSharedAvailability.blocked(snapshot.statusMessage, ownerResourceId, snapshot.contextVersion)
        }
        return CjguiSharedAvailability.allowed(ownerResourceId, snapshot.contextVersion)
    }
    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        let snapshot = domain.formSnapshot()
        let fieldStates = HashMap<String, CjguiSharedAvailability>()
        for (field in fields) {
            fieldStates.add(field.fieldId, fieldAvailabilityForSnapshot(field.fieldId, snapshot))
        }
        let actionStates = HashMap<String, CjguiSharedAvailability>()
        for (action in domain.actionDescriptors()) {
            actionStates.add(action.name, actionAvailabilityForSnapshot(action.name, snapshot))
        }
        return Some(CjguiGeneratedUiFormFeedback(snapshot, domain.formBinding(), ownerResourceId,
            fieldStates, actionStates))
    }
    public func actionAvailable(actionName: String): Bool {
        return actionAvailability(actionName).isAvailable
    }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        let availability = actionAvailability(actionName)
        if (!availability.known || !availability.isAvailable) {
            return CjguiGeneratedUiActionResult(false, availability.reason)
        }
        let snapshot = domain.formSnapshot()
        let result = if (actionName == "APPLY_DRAFT") {
            domain.applyDraftFromHuman(snapshot.draftVersion, snapshot.baseAppliedConfigVersion)
        } else {
            domain.cancelDraftFromHuman(snapshot.draftVersion, snapshot.baseAppliedConfigVersion)
        }
        return CjguiGeneratedUiActionResult(result.applied, result.reason)
    }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        let field = match (fieldSpec(intent.fieldId)) {
            case Some(value) => value;
            case None => return CjguiComposableUiDispatchResult(false)
        }
        let valueType = if (field.editorKind == "BOOLEAN") {
            "BOOLEAN"
        } else {
            "STRING"
        }
        if (!intent.isFieldEdit() || intent.ownerTargetResourceId != ownerResourceId || intent.writerOperation != field
            .writeActionName || intent.argumentName != field.argumentName || intent.value.valueType != valueType) {
            return CjguiComposableUiDispatchResult(false)
        }
        let result = if (field.editorKind == "BOOLEAN") {
            domain.editBooleanFromHuman(field.resourceId, intent.value.booleanValue)
        } else {
            let text = intent.value.stringValue
            let end = cjguiUtf16Length(text)
            domain.editTextFromHuman(field.resourceId, text, end, end)
        }
        return CjguiComposableUiDispatchResult(result.applied)
    }

    /// Same declared field route for handwritten controls. A bound range input
    /// already settles through the range sink; a whole-value preview is not a
    /// second owner write. The window remains the authority for that binding.
    public func handleFormEvent(event: CjguiComposableUiEvent, window: CjguiComposableUiWindow): CjguiComposableUiDispatchResult {
        let field = match (fieldSpec(event.node.fieldId)) {
            case Some(value) => value;
            case None => return CjguiComposableUiDispatchResult(false)
        }
        if (!field.acceptsChangeEventKind(event.eventKind) || event.node.resourceId != field.resourceId ||
            event.node.operationResourceId != ownerResourceId || event.node.operationActionName != field.writeActionName) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (field.editorKind == "TEXT" && window.isTextRangeEditDeltaDeliveryEnabled() &&
            window.ownedTextSessionBoundNodeId() == event.node.nodeId) {
            return CjguiComposableUiDispatchResult(false)
        }
        let value = if (field.editorKind == "BOOLEAN") {
            CjguiSharedOperationValue.boolean(event.text == "true")
        } else {
            CjguiSharedOperationValue.string(event.text)
        }
        return applyFieldIntent(
            CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, "", "", fieldId: field.fieldId,
                writerOperation: field.writeActionName, ownerTargetResourceId: ownerResourceId,
                argumentName: field.argumentName, value: value))
    }

    public func rangeTextEditSupported(fieldId: String): Bool {
        return match (fieldSpec(fieldId)) {
            case Some(field) => field.editorKind == "TEXT";
            case None => false
        }
    }
    public func fieldTextVersion(fieldId: String): Int64 {
        return if (rangeTextEditSupported(fieldId)) {
            domain.formSnapshot().fieldForResourceId(fieldResourceId(fieldId)).draftFieldVersion
        } else {
            -1
        }
    }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String): CjguiRangeTextEditOutcome {
        if (!rangeTextEditSupported(fieldId)) {
            return CjguiRangeTextEditOutcome.rejected(-1, "text_edit_unsupported")
        }
        let snapshot = domain.formSnapshot()
        let current = snapshot.fieldForResourceId(fieldResourceId(fieldId)).draftFieldVersion
        if (current != expectedVersion) {
            return CjguiRangeTextEditOutcome.conflict(current, "form_version_moved")
        }
        // The standard form owner and its public connection share one serial
        // owner turn, as required by the existing editable-form contract.
        let end = cjguiUtf16Length(newText)
        let result = domain.editTextFromHuman(fieldResourceId(fieldId), newText, end, end)
        return if (result.applied) {
            CjguiRangeTextEditOutcome.accepted(current, fieldTextVersion(fieldId))
        } else if (result.isVersionConflict) {
            CjguiRangeTextEditOutcome.conflict(current, result.reason)
        } else {
            CjguiRangeTextEditOutcome.rejected(current, result.reason)
        }
    }
    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool): Bool {
        return rangeTextEditSupported(fieldId) && fieldTextVersion(fieldId) == expectedVersion && action()
    }
    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64, endByte: Int64): ?(Int64, 
        Int64, Int64) {
        if (!rangeTextEditSupported(fieldId)) {
            return None
        }
        let projection = domain.formSnapshot().fieldForResourceId(fieldResourceId(fieldId))
        let currentVersion = projection.draftFieldVersion
        let current = projection.draftText
        this.rememberFieldBody(fieldId, currentVersion, current)
        if (currentVersion == fromVersion) {
            return if (validFieldSelection(current, startByte, endByte)) {
                Some((fromVersion, startByte, endByte))
            } else {
                None
            }
        }
        if (currentVersion < fromVersion) {
            return None
        }
        // A focused owner already names its selection in the current body; that
        // observation is newer than any reconstruction from history.
        if (projection.isFocused && projection.selectionStart >= 0 &&
            projection.selectionEnd >= projection.selectionStart) {
            if (let Some(start) <- cjguiUtf16OffsetToUtf8(current, projection.selectionStart)) {
                if (let Some(end) <- cjguiUtf16OffsetToUtf8(current, projection.selectionEnd)) {
                    return Some((currentVersion, start, end))
                }
            }
        }
        let previous = match (this.fieldBodyAt(fieldId, fromVersion)) {
            case Some(value) => value
            case None => return None
        }
        if (previous != current) {
            // The standard form owner replaces a field value as a whole. Without
            // an owner selection, the new end is the only unambiguous caret.
            let end = Int64(current.toArray().size)
            return Some((currentVersion, end, end))
        }
        return if (validFieldSelection(current, startByte, endByte)) {
            Some((currentVersion, startByte, endByte))
        } else {
            None
        }
    }
}
