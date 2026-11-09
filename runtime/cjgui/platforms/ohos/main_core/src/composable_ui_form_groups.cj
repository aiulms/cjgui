// Public grouped form composition over the shared editable-form contract.
//
// The caller declares stable group keys and field order; every field still uses
// its existing descriptor/projection/binding. This layer renders ordinary
// expanded groups and owns no validation, draft, action, timer or focus state.
// Reordering a placement changes presentation only. Stability: experimental.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

public let CJGUI_FORM_GROUPS_STABILITY: String = "experimental"

/// Stable semantic id convention shared by handwritten fields and the
/// feedback summary's focus resolver.
public func cjguiFormFieldSemanticId(prefix: String, fieldId: String): String {
    if (prefix.size == 0) {
        return "field-${fieldId}"
    }
    return "${prefix}-field-${fieldId}"
}

/// One field's presentation declaration. `fieldId` is the only identity;
/// `nodeBase` is a presentation slot reserved for this field's editor tree:
/// base = field group, +1 editor, +2 validation, +3 required/help text,
/// +4 read-only note, +5 blocked note. Callers may move this placement between
/// groups freely as long as the node range stays unique.
public class CjguiComposableFormFieldPlacement {
    public let fieldId: String
    public let nodeBase: Int64
    public let editorSemanticId: String
    public let helpText: String
    public let readOnly: Bool
    public let enabled: Bool

    public init(fieldId: String, nodeBase: Int64, editorSemanticId!: String = "", helpText!: String = "",
        readOnly!: Bool = false, enabled!: Bool = true) {
        this.fieldId = fieldId
        this.nodeBase = nodeBase
        this.editorSemanticId = editorSemanticId
        this.helpText = helpText
        this.readOnly = readOnly
        this.enabled = enabled
    }
}

public class CjguiComposableFormGroupPlacement {
    public let key: String
    public let title: String
    public let description: String
    public let nodeBase: Int64
    public let fields: ArrayList<CjguiComposableFormFieldPlacement>

    public init(key: String, title: String, nodeBase: Int64, fields: ArrayList<CjguiComposableFormFieldPlacement>,
        description!: String = "") {
        this.key = key
        this.title = title
        this.description = description
        this.nodeBase = nodeBase
        this.fields = ArrayList<CjguiComposableFormFieldPlacement>(fields)
    }
}

/// Caller-owned ordering. Construction rejects duplicate group keys, duplicate
/// field ids and empty groups: those are declaration errors, not runtime
/// fallbacks that would silently route input to an arbitrary field.
public class CjguiComposableFormPlacement {
    public let groups: ArrayList<CjguiComposableFormGroupPlacement>

    public init(groups: ArrayList<CjguiComposableFormGroupPlacement>) {
        if (groups.size == 0) {
            throw IllegalArgumentException("form placement needs a group")
        }
        let copied = ArrayList<CjguiComposableFormGroupPlacement>(groups)
        let groupKeys = HashMap<String, Bool>()
        let fieldIds = HashMap<String, Bool>()
        for (group in copied) {
            if (group.key.size == 0 || group.title.size == 0 || group.nodeBase < 0) {
                throw IllegalArgumentException("form group metadata is required")
            }
            if (groupKeys.get(group.key).isSome()) {
                throw IllegalArgumentException("form group key must be unique")
            }
            groupKeys.add(group.key, true)
            if (group.fields.size == 0) {
                throw IllegalArgumentException("form group needs a field")
            }
            for (field in group.fields) {
                if (field.fieldId.size == 0 || field.nodeBase < 0) {
                    throw IllegalArgumentException("form field placement is invalid")
                }
                if (fieldIds.get(field.fieldId).isSome()) {
                    throw IllegalArgumentException("form field placement must be unique")
                }
                fieldIds.add(field.fieldId, true)
            }
        }
        this.groups = copied
    }

    public func fieldCount(): Int64 {
        var count: Int64 = 0
        for (group in groups) {
            count += group.fields.size
        }
        return count
    }

    /// The editor node id already reserved by this placement. Focus receipts
    /// compare this id with the window's installed focus rather than treating
    /// an accepted request as a finished focus.
    public func editorNodeId(fieldId: String): Int64 {
        for (group in groups) {
            for (field in group.fields) {
                if (field.fieldId == fieldId) {
                    return field.nodeBase + 1
                }
            }
        }
        return -1
    }

    /// Presentation-only reorder helper. The returned placement contains the
    /// same field objects; no owner call is made.
    public func withGroupOrder(keys: ArrayList<String>): CjguiComposableFormPlacement {
        if (keys.size != groups.size) {
            throw IllegalArgumentException("form group order is incomplete")
        }
        let ordered = ArrayList<CjguiComposableFormGroupPlacement>()
        for (key in keys) {
            var found = false
            for (group in groups) {
                if (group.key == key) {
                    ordered.add(group)
                    found = true
                    break
                }
            }
            if (!found) {
                throw IllegalArgumentException("form group order names an unknown key")
            }
        }
        return CjguiComposableFormPlacement(ordered)
    }
}

public class CjguiComposableFormGroupStyle {
    public let container: CjguiComposableUiStyle
    public let group: CjguiComposableUiStyle
    public let title: CjguiComposableUiStyle
    public let description: CjguiComposableUiStyle
    public let help: CjguiComposableUiStyle
    public let note: CjguiComposableUiStyle

    public init(container!: CjguiComposableUiStyle = CjguiComposableUiStyle(gap: 16, growX: 1),
        group!: CjguiComposableUiStyle = CjguiComposableUiStyle(gap: 8, growX: 1),
        title!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 16.0, growX: 1),
        description!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.5, growX: 1),
        help!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.0, growX: 1),
        note!: CjguiComposableUiStyle = CjguiComposableUiStyle(fontSize: 12.0, growX: 1)) {
        this.container = container
        this.group = group
        this.title = title
        this.description = description
        this.help = help
        this.note = note
    }
}

/// Compose all groups from one feedback projection, so inline hints, read-only
/// notes and the summary share exactly the same owner snapshot.
public func cjguiComposableBoundFormGroups(nodeId: Int64, semanticId: String,
    placement: CjguiComposableFormPlacement, feedback: CjguiFormFeedbackProjection,
    editorStyle!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 32, fontSize: 15.0, growX: 1),
    validationStyle!: CjguiComposableUiStyle = cjguiComposableFormValidationStyle(),
    style!: CjguiComposableFormGroupStyle = CjguiComposableFormGroupStyle(),
    textOperationActionName!: String = "EDIT_DRAFT_TEXT",
    booleanOperationActionName!: String = "EDIT_DRAFT_BOOLEAN",
    requiredMarker!: String = " *", requiredHint!: String = "必填", readOnlyLabel!: String = "只读",
    blockedLabel!: String = "当前不可编辑", unknownFieldText!: String = "反馈不可用，未渲染编辑器"):
    CjguiComposableUiNode {
    let root = cjguiComposableVertical(nodeId, semanticId, style.container)
    for (group in placement.groups) {
        let groupSemanticId = "${semanticId}-group-${group.key}"
        let groupNode = cjguiComposableVertical(group.nodeBase, groupSemanticId, style.group)
        groupNode.add(cjguiComposableText(group.nodeBase + 1, "${groupSemanticId}-title", group.title, style.title))
        if (group.description.size > 0) {
            groupNode.add(cjguiComposableText(group.nodeBase + 2, "${groupSemanticId}-description",
                group.description, style.description))
        }
        for (fieldPlacement in group.fields) {
            groupNode.add(cjguiComposableGroupedField(fieldPlacement, semanticId, feedback, editorStyle,
                validationStyle, style, textOperationActionName, booleanOperationActionName, requiredMarker,
                requiredHint, readOnlyLabel, blockedLabel, unknownFieldText))
        }
        root.add(groupNode)
    }
    return root
}

private func cjguiComposableGroupedField(placement: CjguiComposableFormFieldPlacement, formSemanticId: String,
    feedback: CjguiFormFeedbackProjection, editorStyle: CjguiComposableUiStyle,
    validationStyle: CjguiComposableUiStyle, style: CjguiComposableFormGroupStyle,
    textOperationActionName: String, booleanOperationActionName: String, requiredMarker: String,
    requiredHint: String, readOnlyLabel: String, blockedLabel: String,
    unknownFieldText: String): CjguiComposableUiNode {
    let semanticId = if (placement.editorSemanticId.size > 0) {
        placement.editorSemanticId
    } else {
        cjguiFormFieldSemanticId(formSemanticId, placement.fieldId)
    }
    let descriptorOption = feedback.descriptorFor(placement.fieldId)
    if (descriptorOption.isNone()) {
        let unavailable = cjguiComposableVertical(placement.nodeBase,
            "${semanticId}-unavailable", style.group)
        unavailable.add(cjguiComposableText(placement.nodeBase + 1, "${semanticId}-unavailable-text",
            "${placement.fieldId}：${unknownFieldText}", style.note))
        return unavailable
    }
    let descriptor = descriptorOption.getOrThrow()
    let fieldOption = feedback.fieldFor(placement.fieldId)
    if (fieldOption.isNone()) {
        let unavailable = cjguiComposableVertical(placement.nodeBase,
            "${semanticId}-unavailable", style.group)
        unavailable.add(cjguiComposableText(placement.nodeBase + 1, "${semanticId}-unavailable-text",
            "${descriptor.label}：${unknownFieldText}", style.note))
        return unavailable
    }
    let field = fieldOption.getOrThrow()
    if (field.resourceId != descriptor.resourceId) {
        let unavailable = cjguiComposableVertical(placement.nodeBase, "${semanticId}-identity-changed",
            style.group)
        unavailable.add(cjguiComposableText(placement.nodeBase + 1, "${semanticId}-identity-changed-text",
            "${descriptor.label}：字段绑定身份已变化，未渲染编辑器", style.note))
        return unavailable
    }
    if (descriptor.editorKind != "TEXT" && descriptor.editorKind != "INTEGER" &&
        descriptor.editorKind != "BOOLEAN") {
        let unavailable = cjguiComposableVertical(placement.nodeBase, "${semanticId}-unsupported", style.group)
        unavailable.add(cjguiComposableText(placement.nodeBase + 1, "${semanticId}-unsupported-text",
            "${descriptor.label}：未支持的字段编辑器", style.note))
        return unavailable
    }
    let availability = feedback.availabilityOf(placement.fieldId)
    let blocked = availability.known && !availability.isAvailable
    let readOnly = placement.readOnly || feedback.isReadOnly(placement.fieldId)
    let error = feedback.errorFor(placement.fieldId)
    let validationDisplayMessage = match (error) {
        case Some(value) => value.displayMessage
        case None => ""
    }
    let editorLabel = if (descriptor.required) {
        "${descriptor.label}${requiredMarker}"
    } else {
        descriptor.label
    }
    let group = cjguiComposableBoundFormField(placement.nodeBase, semanticId, placement.nodeBase + 1,
        placement.nodeBase + 2, descriptor, field, feedback.ownerResourceId, editorStyle, validationStyle,
        editorSemanticId: semanticId, validationSemanticId: "${semanticId}-validation",
        validationDisplayMessage: validationDisplayMessage, enabled: placement.enabled && !blocked,
        readOnly: readOnly, textOperationActionName: textOperationActionName,
        booleanOperationActionName: booleanOperationActionName, editorLabel: editorLabel,
        helpText: placement.helpText, unavailableReason: availability.reason)
    let requiredNote = descriptor.required && requiredHint.size > 0
    let helpNote = placement.helpText.size > 0
    if (requiredNote || helpNote) {
        let text = if (requiredNote && helpNote) {
            "${requiredHint} · ${placement.helpText}"
        } else if (requiredNote) {
            requiredHint
        } else {
            placement.helpText
        }
        // Required and help share the one +3 text slot, so read-only (+4) and
        // blocked (+5) can never collide with them. The editor and validation
        // identities stay untouched.
        let noteSemanticId = if (helpNote) {
            "${semanticId}-help"
        } else {
            "${semanticId}-required"
        }
        group.add(cjguiComposableText(placement.nodeBase + 3, noteSemanticId, text, style.help))
    }
    if (readOnly) {
        group.add(cjguiComposableText(placement.nodeBase + 4, "${semanticId}-read-only", readOnlyLabel, style.note))
    }
    if (blocked) {
        let detail = if (availability.reason.size > 0) {
            "${blockedLabel}：${availability.reason}"
        } else {
            blockedLabel
        }
        group.add(cjguiComposableText(placement.nodeBase + 5, "${semanticId}-blocked", detail, style.note))
    }
    return group
}
