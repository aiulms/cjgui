package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

/// Per-field presentation state for the shared detail form. The APPLICATION
/// decides whether a field may be written (and why not) and may add a display
/// message; everything else (editor kind, identity, validation, read-only,
/// focus/help semantics) comes from the shared binding and feedback projection.
public class CjguiSharedDetailFieldState {
    public let enabled: Bool
    public let validationError: String
    public let unavailableReason: String

    public init(enabled: Bool, validationError!: String = "", unavailableReason!: String = "") {
        this.enabled = enabled
        this.validationError = validationError
        this.unavailableReason = unavailableReason
    }
}

/// The EDITABLE FIELD AREA of a detail form, composed from the SAME assets the
/// handwritten form uses: `CjguiFormFeedbackProjection` (one snapshot, field
/// identity, availability/read-only/error from the owner projection) and
/// `cjguiComposableBoundFormField` (TEXT/INTEGER/BOOLEAN dispatch, validation
/// wording, accessible help). This function owns only layout and the caller's
/// stable node ids/semantics; it keeps no field rules of its own.
///
/// - Each field `i` becomes a group at `firstEditorId + i*10 - 1`, its editor at
///   `firstEditorId + i*10` (the historical editor id) and, when invalid, a
///   validation line at `+1`.
/// - `stateOf(fieldId)` only reports whether the owner currently accepts a
///   write (and the reason/wording); the field's editor kind, identity and
///   validation state are never re-declared here.
public func cjguiSharedEditableDetailFields(
    boxId: Int64,
    firstEditorId: Int64,
    statusId: Int64,
    semanticPrefix: String,
    ownerId: Int64,
    declarations: CjguiSharedFormBinding,
    snapshot: CjguiSharedFormSnapshot,
    stateOf: (String) -> CjguiSharedDetailFieldState,
    statusText: String,
    theme: CjguiComposableUiTheme,
    textActionName!: String = "EDIT_DRAFT_TEXT",
    booleanActionName!: String = "EDIT_DRAFT_BOOLEAN",
    readOnlyFields!: ArrayList<String> = ArrayList<String>(),
    displayMessage!: ?((String, String) -> String) = None,
    helpTextOf!: ?((String) -> String) = None
): CjguiComposableUiNode {
    let ownerVersion = snapshot.contextVersion
    // ONE projection for the whole detail: the same availability/read-only/
    // error facts the summary and every editor read, so they cannot disagree.
    let projection = CjguiFormFeedbackProjection(snapshot, declarations, ownerId,
        policy: CjguiFormFeedbackPolicy(
            // The caller's `validationError` is the wording for THIS field's
            // owner error. It keeps the pre-convergence semantics without
            // inventing a second validation: the projection still decides
            // WHICH fields are invalid (from the owner snapshot), and this only
            // supplies the display text through the existing feedback channel.
            displayMessage: { fieldId, reason =>
                let state = stateOf(fieldId)
                if (!state.validationError.isEmpty()) {
                    state.validationError
                } else {
                    match (displayMessage) {
                        case Some(handler) => handler(fieldId, reason)
                        case None => reason
                    }
                }
            },
            availability: { fieldId =>
                let state = stateOf(fieldId)
                if (state.enabled) {
                    CjguiSharedAvailability.allowed(ownerId, ownerVersion)
                } else {
                    CjguiSharedAvailability.blocked(state.unavailableReason, ownerId, ownerVersion)
                }
            }), readOnlyFields: readOnlyFields)
    let box = cjguiComposableVertical(boxId, "${semanticPrefix}-fields",
        CjguiComposableUiStyle(gap: 6, growX: 1))
    for (index in 0..declarations.fieldCount()) {
        let descriptor = declarations.fieldAtControlIndex(index)
        let field = match (projection.fieldFor(descriptor.fieldId)) {
            case Some(value) =>
                if (value.resourceId != descriptor.resourceId) {
                    throw IllegalArgumentException("shared_detail_field_identity_mismatch:${descriptor.fieldId}")
                }
                value
            case None => throw IllegalArgumentException("shared_detail_field_missing:${descriptor.fieldId}")
        }
        let availability = projection.availabilityOf(descriptor.fieldId)
        let enabled = availability.known && availability.isAvailable
        let readOnly = projection.isReadOnly(descriptor.fieldId)
        let errorMessage = match (projection.errorFor(descriptor.fieldId)) {
            case Some(value) => value.displayMessage
            case None => ""
        }
        let helpText = match (helpTextOf) {
            case Some(value) => value(descriptor.fieldId)
            case None => ""
        }
        box.add(cjguiComposableBoundFormField(
            firstEditorId + index * 10 - 1, "${semanticPrefix}-${descriptor.fieldId}-group",
            firstEditorId + index * 10, firstEditorId + index * 10 + 1,
            descriptor, field, ownerId, theme.input, cjguiComposableFormValidationStyle(),
            editorSemanticId: "${semanticPrefix}-${descriptor.fieldId}",
            validationSemanticId: "${semanticPrefix}-${descriptor.fieldId}-error",
            validationDisplayMessage: errorMessage, enabled: enabled, readOnly: readOnly,
            textOperationActionName: textActionName, booleanOperationActionName: booleanActionName,
            helpText: helpText, unavailableReason: if (availability.known) { availability.reason } else { "" }))
    }
    box.add(cjguiComposableText(statusId, "${semanticPrefix}-status", statusText, theme.body))
    return box
}
