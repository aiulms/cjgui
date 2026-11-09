// Public read-only feedback projection for shared editable forms.
//
// One owner snapshot is the only business input. Field errors, the summary and
// submit availability are derived from that same snapshot; `canApply` stays the
// owner's answer. This module owns no validation rule, draft, timer or focus
// state, and it never changes native focus by itself. Stability: experimental.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

public let CJGUI_FORM_FEEDBACK_FIELD_ERROR: String = "field_error"
public let CJGUI_FORM_FEEDBACK_READ_ONLY: String = "read_only"
public let CJGUI_FORM_FEEDBACK_BLOCKED: String = "blocked"
public let CJGUI_FORM_FEEDBACK_STABILITY: String = "experimental"

/// Caller-supplied presentation policy. Every handler is pure data policy: it
/// must not read the owner, dispatch an action or request focus. The defaults
/// keep the machine reason visible, expose no focus target and treat fields as
/// available, which is the handwritten form's ordinary state.
public class CjguiFormFeedbackPolicy {
    private let displayHandler: ?((String, String) -> String)
    private let focusHandler: ?((String) -> String)
    private let availabilityHandler: ?((String) -> CjguiSharedAvailability)

    public init(displayMessage!: ?((String, String) -> String) = None,
        focusSemanticId!: ?((String) -> String) = None,
        availability!: ?((String) -> CjguiSharedAvailability) = None) {
        this.displayHandler = displayMessage
        this.focusHandler = focusSemanticId
        this.availabilityHandler = availability
    }

    public func displayMessage(fieldId: String, reason: String): String {
        return match (displayHandler) {
            case Some(handler) => handler(fieldId, reason)
            case None => reason
        }
    }

    /// Semantic id of the accepted editor for this field. "" means the caller
    /// has not declared a public focus target.
    public func focusSemanticId(fieldId: String): String {
        return match (focusHandler) {
            case Some(handler) => handler(fieldId)
            case None => ""
        }
    }

    public func availability(fieldId: String): CjguiSharedAvailability {
        return match (availabilityHandler) {
            case Some(handler) => handler(fieldId)
            case None => CjguiSharedAvailability.allowed(-1, 0)
        }
    }
}

/// One read-only feedback fact. `reasonCode` is the owner/machine vocabulary;
/// `displayMessage` is the caller-resolved human wording. They are never
/// inferred from each other by this module.
public class CjguiFormFeedbackEntry {
    public let kind: String
    public let fieldId: String
    public let label: String
    public let reasonCode: String
    public let displayMessage: String
    public let resourceId: Int64
    public let focusSemanticId: String

    public init(kind: String, fieldId: String, label: String, reasonCode: String, displayMessage: String,
        resourceId: Int64, focusSemanticId: String) {
        this.kind = kind
        this.fieldId = fieldId
        this.label = label
        this.reasonCode = reasonCode
        this.displayMessage = displayMessage
        this.resourceId = resourceId
        this.focusSemanticId = focusSemanticId
    }

    public func isFieldError(): Bool {
        return kind == CJGUI_FORM_FEEDBACK_FIELD_ERROR
    }
}

/// Pure answer to "can this summary item locate its field right now?". A ready
/// answer does not guarantee the accepted scene still contains the node; the
/// public focus call makes that final check and reports failure explicitly.
public class CjguiFormFocusResolution {
    public let fieldId: String
    public let semanticId: String
    public let reason: String
    public let detail: String

    public init(fieldId: String, semanticId: String, reason: String, detail!: String = "") {
        this.fieldId = fieldId
        this.semanticId = semanticId
        this.reason = reason
        this.detail = detail
    }

    public func ready(): Bool {
        return reason.size == 0
    }
}

public class CjguiFormFocusOutcome {
    public let fieldId: String
    /// The window accepted the request. A reveal can queue it for the next
    /// accepted scene, so this is not proof that the editor is the keyboard target.
    public let requestAccepted: Bool
    /// The window's recorded focus reference names the requested editor node.
    /// This is a bookkeeping fact only; it is not proof that native installed
    /// focus or a text selection.
    public let focusRecorded: Bool
    public let reason: String
    public let detail: String

    public init(fieldId: String, requestAccepted: Bool, focusRecorded: Bool, reason: String,
        detail!: String = "") {
        this.fieldId = fieldId
        this.requestAccepted = requestAccepted
        this.focusRecorded = focusRecorded
        this.reason = reason
        this.detail = detail
    }
}

/// Immutable projection of one owner read. Construct it once per scene build
/// and use it for both the field nodes and the summary so they cannot disagree.
public class CjguiFormFeedbackProjection {
    public let snapshot: CjguiSharedFormSnapshot
    public let declarations: CjguiSharedFormBinding
    public let ownerResourceId: Int64
    /// False when a declared field has no matching current projection (or its
    /// stable identity no longer matches). The summary must not present that
    /// state as "no errors".
    public let known: Bool
    public let canApply: Bool
    public let formMessage: String
    private let policy: CjguiFormFeedbackPolicy
    private let descriptors: HashMap<String, CjguiSharedFormFieldDescriptor>
    private let fields: HashMap<String, CjguiSharedFormFieldProjection>
    private let readOnlyFields: HashMap<String, Bool>
    private let availabilities: HashMap<String, CjguiSharedAvailability>
    private let errors: ArrayList<CjguiFormFeedbackEntry>
    private let noteEntries: ArrayList<CjguiFormFeedbackEntry>
    private let unmapped: ArrayList<CjguiFormFeedbackEntry>
    private let unknownAvailabilityCountValue: Int64

    public init(snapshot: CjguiSharedFormSnapshot, declarations: CjguiSharedFormBinding, ownerResourceId: Int64,
        policy!: CjguiFormFeedbackPolicy = CjguiFormFeedbackPolicy(),
        readOnlyFields!: ArrayList<String> = ArrayList<String>()) {
        this.snapshot = snapshot
        this.declarations = declarations
        this.ownerResourceId = ownerResourceId
        this.policy = policy
        this.canApply = snapshot.canApply
        this.formMessage = snapshot.statusMessage
        this.descriptors = HashMap<String, CjguiSharedFormFieldDescriptor>()
        this.fields = HashMap<String, CjguiSharedFormFieldProjection>()
        this.readOnlyFields = HashMap<String, Bool>()
        this.availabilities = HashMap<String, CjguiSharedAvailability>()
        this.errors = ArrayList<CjguiFormFeedbackEntry>()
        this.noteEntries = ArrayList<CjguiFormFeedbackEntry>()
        this.unmapped = ArrayList<CjguiFormFeedbackEntry>()
        var unknownAvailability = 0
        for (fieldId in readOnlyFields) {
            this.readOnlyFields.add(fieldId, true)
        }
        for (descriptor in declarations.allFields()) {
            if (this.descriptors.get(descriptor.fieldId).isSome()) {
                continue
            }
            this.descriptors.add(descriptor.fieldId, descriptor)
        }
        for (field in snapshot.allFields()) {
            if (this.fields.get(field.fieldId).isNone()) {
                this.fields.add(field.fieldId, field)
            }
        }
        var missing = 0
        for (descriptor in declarations.allFields()) {
            let availability = policy.availability(descriptor.fieldId)
            this.availabilities.add(descriptor.fieldId, availability)
            if (!availability.known) {
                unknownAvailability += 1
            }
            let fieldOption = this.fields.get(descriptor.fieldId)
            if (fieldOption.isNone()) {
                missing += 1
                continue
            }
            let field = fieldOption.getOrThrow()
            if (field.resourceId != descriptor.resourceId) {
                missing += 1
                continue
            }
            let semanticId = policy.focusSemanticId(descriptor.fieldId)
            let isReadOnly = this.readOnlyFields.get(descriptor.fieldId).isSome()
            if (isReadOnly) {
                this.noteEntries.add(CjguiFormFeedbackEntry(CJGUI_FORM_FEEDBACK_READ_ONLY, descriptor.fieldId,
                    descriptor.label, "", "", descriptor.resourceId, semanticId))
            }
            if (availability.known && !availability.isAvailable) {
                this.noteEntries.add(CjguiFormFeedbackEntry(CJGUI_FORM_FEEDBACK_BLOCKED, descriptor.fieldId,
                    descriptor.label, availability.reason, policy.displayMessage(descriptor.fieldId,
                    availability.reason), descriptor.resourceId, semanticId))
            }
            if (field.validationError.size > 0) {
                this.errors.add(CjguiFormFeedbackEntry(CJGUI_FORM_FEEDBACK_FIELD_ERROR, descriptor.fieldId,
                    descriptor.label, field.validationError, policy.displayMessage(descriptor.fieldId,
                    field.validationError), descriptor.resourceId, semanticId))
            }
        }
        for (field in snapshot.allFields()) {
            if (this.descriptors.get(field.fieldId).isNone() && field.validationError.size > 0) {
                this.unmapped.add(CjguiFormFeedbackEntry(CJGUI_FORM_FEEDBACK_FIELD_ERROR, field.fieldId,
                    field.fieldId, field.validationError, policy.displayMessage(field.fieldId, field.validationError),
                    field.resourceId, ""))
            }
        }
        this.known = missing == 0
        this.unknownAvailabilityCountValue = unknownAvailability
    }

    public func errorCount(): Int64 {
        return errors.size
    }

    public func hasErrors(): Bool {
        return errors.size > 0 || unmapped.size > 0
    }

    public func fieldErrors(): ArrayList<CjguiFormFeedbackEntry> {
        return ArrayList<CjguiFormFeedbackEntry>(errors)
    }

    /// Read-only and blocked fields, never counted as validation errors.
    public func notes(): ArrayList<CjguiFormFeedbackEntry> {
        return ArrayList<CjguiFormFeedbackEntry>(noteEntries)
    }

    /// Errors whose field id is not declared anymore. They cannot be located
    /// and are never attached to a guessed neighbouring field.
    public func unmappedErrors(): ArrayList<CjguiFormFeedbackEntry> {
        return ArrayList<CjguiFormFeedbackEntry>(unmapped)
    }

    public func unknownAvailabilityCount(): Int64 {
        return unknownAvailabilityCountValue
    }

    public func descriptorFor(fieldId: String): ?CjguiSharedFormFieldDescriptor {
        return descriptors.get(fieldId)
    }

    public func fieldFor(fieldId: String): ?CjguiSharedFormFieldProjection {
        return fields.get(fieldId)
    }

    public func availabilityOf(fieldId: String): CjguiSharedAvailability {
        return match (availabilities.get(fieldId)) {
            case Some(value) => value
            case None => CjguiSharedAvailability.unknown()
        }
    }

    public func isReadOnly(fieldId: String): Bool {
        return readOnlyFields.get(fieldId).isSome()
    }

    public func errorFor(fieldId: String): ?CjguiFormFeedbackEntry {
        for (entry in errors) {
            if (entry.fieldId == fieldId) {
                return Some(entry)
            }
        }
        return None
    }

    /// Stable business resource -> field id for summary activation. The caller
    /// resolves the clicked resource through this map, not through a display
    /// index.
    public func fieldIdForResourceId(resourceId: Int64): String {
        for (descriptor in declarations.allFields()) {
            if (descriptor.resourceId == resourceId) {
                return descriptor.fieldId
            }
        }
        return ""
    }

    /// "field_errors", "form_rejected", "rejection_reason_unknown" or "".
    public func submitBlocker(): String {
        if (canApply) {
            return ""
        }
        if (errors.size > 0 || unmapped.size > 0) {
            return "field_errors"
        }
        if (formMessage.size > 0) {
            return "form_rejected"
        }
        return "rejection_reason_unknown"
    }

    /// Whether the summary may claim the form is ready. Unknown feedback and
    /// unknown field availability are explicitly not ready.
    public func ready(): Bool {
        return known && canApply && errors.size == 0 && unmapped.size == 0 && unknownAvailabilityCountValue == 0
    }

    public func focusResolution(fieldId: String): CjguiFormFocusResolution {
        let semanticId = policy.focusSemanticId(fieldId)
        let descriptor = match (descriptors.get(fieldId)) {
            case Some(value) => value
            case None => return CjguiFormFocusResolution(fieldId, semanticId, "field_not_declared")
        }
        let field = match (fields.get(fieldId)) {
            case Some(value) => value
            case None => return CjguiFormFocusResolution(fieldId, semanticId, "field_not_in_snapshot")
        }
        if (field.resourceId != descriptor.resourceId) {
            return CjguiFormFocusResolution(fieldId, semanticId, "field_identity_changed")
        }
        if (semanticId.size == 0) {
            return CjguiFormFocusResolution(fieldId, semanticId, "focus_target_missing")
        }
        if (readOnlyFields.get(fieldId).isSome()) {
            return CjguiFormFocusResolution(fieldId, semanticId, "field_read_only")
        }
        let availability = availabilityOf(fieldId)
        if (availability.known && !availability.isAvailable) {
            return CjguiFormFocusResolution(fieldId, semanticId, "field_blocked", detail: availability.reason)
        }
        return CjguiFormFocusResolution(fieldId, semanticId, "")
    }
}

/// Locate a field through the window's existing public focus entry. The caller
/// invokes this only from an explicit summary activation; no polling, timer or
/// repeated focus stealing happens here. `targetNodeId` is the editor id already
/// reserved by the caller's placement: the receipt compares it with the
/// window's recorded focus reference. Equality is a bookkeeping observation,
/// not a native focus/selection installation proof. No nearest-field guess is
/// made.
public func cjguiFocusFormFeedback(window: CjguiComposableUiWindow, feedback: CjguiFormFeedbackProjection,
    fieldId: String, targetNodeId!: Int64 = -1): CjguiFormFocusOutcome {
    let resolution = feedback.focusResolution(fieldId)
    if (!resolution.ready()) {
        return CjguiFormFocusOutcome(fieldId, false, false, resolution.reason, detail: resolution.detail)
    }
    if (!window.focusAcceptedSemanticNode(resolution.semanticId)) {
        return CjguiFormFocusOutcome(fieldId, false, false, "focus_request_rejected",
            detail: "window_refused")
    }
    var recorded = false
    if (targetNodeId >= 0) {
        if (let Some(reference) <- window.focusedNodeReference()) {
            recorded = reference.manualNodeId() == targetNodeId
        }
    }
    if (recorded) {
        return CjguiFormFocusOutcome(fieldId, true, true, "")
    }
    return CjguiFormFocusOutcome(fieldId, true, false, "focus_pending",
        detail: "target_node=${targetNodeId}")
}

/// Caller-localizable summary wording. Machine reasons stay in the projection
/// entries; this class only chooses human text.
public class CjguiFormFeedbackCopy {
    public let errorTitle: String
    public let readyText: String
    public let unknownText: String
    public let rejectionPrefix: String
    public let readOnlyLabel: String
    public let blockedLabel: String
    public let unmappedLabel: String

    public init(errorTitle!: String = "需要修正的字段", readyText!: String = "可以提交",
        unknownText!: String = "反馈状态未知，请刷新后重试", rejectionPrefix!: String = "无法提交",
        readOnlyLabel!: String = "只读", blockedLabel!: String = "当前不可编辑",
        unmappedLabel!: String = "未能对应到已声明字段") {
        this.errorTitle = errorTitle
        this.readyText = readyText
        this.unknownText = unknownText
        this.rejectionPrefix = rejectionPrefix
        this.readOnlyLabel = readOnlyLabel
        this.blockedLabel = blockedLabel
        this.unmappedLabel = unmappedLabel
    }
}

public class CjguiFormFeedbackSummaryStyle {
    public let container: CjguiComposableUiStyle
    public let title: CjguiComposableUiStyle
    public let entry: CjguiComposableUiStyle
    public let entryInteraction: CjguiComposableUiInteractionStyle
    public let note: CjguiComposableUiStyle
    public let rejection: CjguiComposableUiStyle
    public let ready: CjguiComposableUiStyle

    public init(container!: CjguiComposableUiStyle = CjguiComposableUiStyle(padding: 8, gap: 4, growX: 1),
        title!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 13.5, growX: 1),
        entry!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 13.0, growX: 1, minHeight: 26),
        entryInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        note!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.0, growX: 1),
        rejection!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.5, growX: 1),
        ready!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.5, growX: 1)) {
        this.container = container
        this.title = title
        this.entry = entry
        this.entryInteraction = entryInteraction
        this.note = note
        this.rejection = rejection
        this.ready = ready
    }
}

/// Compose the read-only summary. `actionName` is the caller's own common
/// operation; the clicked entry carries the stable field resource through
/// `operationResourceId`, so the handler resolves the field identity instead of
/// using a display index. Node ids: root, +1 title, +2 rejection, +3 unknown,
/// +4 ready, +10.. errors, +1000.. notes, +2000.. unmapped.
public func cjguiComposableFormFeedbackSummary(nodeId: Int64, semanticId: String,
    feedback: CjguiFormFeedbackProjection, actionName: String,
    style!: CjguiFormFeedbackSummaryStyle = CjguiFormFeedbackSummaryStyle(),
    copy!: CjguiFormFeedbackCopy = CjguiFormFeedbackCopy()): CjguiComposableUiNode {
    let root = cjguiComposableVertical(nodeId, semanticId, style.container)
    if (!feedback.known) {
        root.add(cjguiComposableText(nodeId + 3, "${semanticId}-unknown", copy.unknownText, style.note))
    } else if (feedback.hasErrors()) {
        root.add(cjguiComposableText(nodeId + 1, "${semanticId}-title",
            "${copy.errorTitle} · ${feedback.errorCount()}", style.title))
        var index = 0
        for (entry in feedback.fieldErrors()) {
            let item = cjguiComposableButton(nodeId + 10 + index, "${semanticId}-error-${index}",
                "${entry.label}：${entry.displayMessage}", actionName, entry.resourceId, style.entry,
                operationActionName: actionName, operationResourceId: entry.resourceId,
                interactionStyle: style.entryInteraction)
            root.add(item)
            index += 1
        }
    }
    let blocker = feedback.submitBlocker()
    if (blocker.size > 0) {
        let rejectionText = if (blocker == "rejection_reason_unknown" || feedback.formMessage.size == 0) {
            copy.unknownText
        } else {
            feedback.formMessage
        }
        root.add(cjguiComposableText(nodeId + 2, "${semanticId}-rejection",
            "${copy.rejectionPrefix}：${rejectionText}", style.rejection))
    } else if (feedback.known && feedback.unknownAvailabilityCount() > 0) {
        root.add(cjguiComposableText(nodeId + 3, "${semanticId}-unknown-availability", copy.unknownText,
            style.note))
    } else if (feedback.ready() && copy.readyText.size > 0) {
        root.add(cjguiComposableText(nodeId + 4, "${semanticId}-ready", copy.readyText, style.ready))
    }
    var noteIndex = 0
    for (entry in feedback.notes()) {
        let text = if (entry.kind == CJGUI_FORM_FEEDBACK_READ_ONLY) {
            "${copy.readOnlyLabel}：${entry.label}"
        } else if (entry.displayMessage.size > 0) {
            "${copy.blockedLabel}：${entry.label}（${entry.displayMessage}）"
        } else {
            "${copy.blockedLabel}：${entry.label}"
        }
        root.add(cjguiComposableText(nodeId + 1000 + noteIndex, "${semanticId}-note-${noteIndex}", text, style.note))
        noteIndex += 1
    }
    var unmappedIndex = 0
    for (entry in feedback.unmappedErrors()) {
        root.add(cjguiComposableText(nodeId + 2000 + unmappedIndex, "${semanticId}-unmapped-${unmappedIndex}",
            "${copy.unmappedLabel}：${entry.label}（${entry.displayMessage}）", style.note))
        unmappedIndex += 1
    }
    return root
}

/// One explanation derived from the same descriptor/projection as a field.
/// A renderer or screen reader consumes it; no validation or value is stored here.
/// Stability: experimental. Native transport: macOS; other platforms retain the fact only.
public func cjguiComposableFormFieldHelp(descriptor: CjguiSharedFormFieldDescriptor,
    field: CjguiSharedFormFieldProjection, validationDisplayMessage!: String = "",
    helpText!: String = "", readOnly!: Bool = false, enabled!: Bool = true,
    unavailableReason!: String = ""): String {
    if (descriptor.resourceId != field.resourceId || descriptor.fieldId != field.fieldId) {
        throw IllegalArgumentException("composable_bound_form_field_identity_mismatch")
    }
    let notes = ArrayList<String>()
    if (helpText.size > 0) { notes.add(helpText) }
    if (descriptor.required) { notes.add("必填") }
    if (readOnly) { notes.add("只读") }
    if (!enabled) {
        notes.add(if (unavailableReason.isEmpty()) { "当前不可用" } else { "当前不可用：${unavailableReason}" })
    }
    if (field.validationError.size > 0) {
        let message = if (validationDisplayMessage.size > 0) { validationDisplayMessage }
            else { userFacingBoundFieldValidationMessage(descriptor, field.validationError) }
        notes.add(if (message == field.validationError) { "错误：${message}" }
            else { "错误：${message}（${field.validationError}）" })
    }
    return String.join(notes.toArray(), delimiter: "；")
}
