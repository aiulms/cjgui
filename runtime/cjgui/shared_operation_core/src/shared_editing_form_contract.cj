package cjgui_shared_operation_core

import std.collection.*

/// Experimental pure-Cangjie form descriptor. It deliberately carries only
/// stable control identity and presentation metadata; application validation
/// and persistence stay in the application domain.
public class CjguiSharedFormFieldDescriptor {
    public let resourceId: Int64
    public let fieldId: String
    public let label: String
    public let editorKind: String

    public init(resourceId: Int64, fieldId: String, label: String, editorKind: String) {
        this.resourceId = resourceId
        this.fieldId = fieldId
        this.label = label
        this.editorKind = editorKind
    }
}

/// Stable mapping from a bounded native control slot to an application field.
/// A duplicate ID is a programmer error: it is rejected when the binding is
/// constructed rather than silently routing input to an arbitrary field.
public class CjguiSharedFormBinding {
    private let descriptors: ArrayList<CjguiSharedFormFieldDescriptor>

    public init(descriptors: ArrayList<CjguiSharedFormFieldDescriptor>) {
        if (descriptors.size == 0) {
            throw IllegalArgumentException("shared form needs a field")
        }
        let copied = ArrayList<CjguiSharedFormFieldDescriptor>(descriptors)
        var outer: Int64 = 0
        while (outer < copied.size) {
            if (copied[outer].fieldId.size == 0 || copied[outer].label.size == 0 || copied[outer].editorKind.size == 0) {
                throw IllegalArgumentException("shared form field metadata is required")
            }
            var inner = outer + 1
            while (inner < copied.size) {
                if (copied[outer].resourceId == copied[inner].resourceId || copied[outer].fieldId == copied[inner].fieldId) {
                    throw IllegalArgumentException("shared form field identity must be unique")
                }
                inner += 1
            }
            outer += 1
        }
        this.descriptors = copied
    }

    public func fieldCount(): Int64 {
        return descriptors.size
    }

    public func fieldAtControlIndex(controlIndex: Int64): CjguiSharedFormFieldDescriptor {
        return descriptors[controlIndex]
    }

    public func controlIndexForResourceId(resourceId: Int64): Int64 {
        var index: Int64 = 0
        while (index < descriptors.size) {
            if (descriptors[index].resourceId == resourceId) {
                return index
            }
            index += 1
        }
        return -1
    }

    public func allFields(): ArrayList<CjguiSharedFormFieldDescriptor> {
        return ArrayList<CjguiSharedFormFieldDescriptor>(descriptors)
    }
}

/// Projection of one application-owned draft field. Selection offsets use the
/// native text control's UTF-16 convention and are copied as data; the core
/// never splits or edits Unicode text itself.
public class CjguiSharedFormFieldProjection {
    public let resourceId: Int64
    public let fieldId: String
    public let appliedValue: CjguiSharedOperationValue
    public let draftText: String
    public let validationError: String
    public let draftFieldVersion: Int64
    public let isFocused: Bool
    public let selectionStart: Int64
    public let selectionEnd: Int64

    public init(
        resourceId: Int64,
        fieldId: String,
        appliedValue: CjguiSharedOperationValue,
        draftText: String,
        validationError: String,
        draftFieldVersion: Int64,
        isFocused: Bool,
        selectionStart: Int64,
        selectionEnd: Int64
    ) {
        this.resourceId = resourceId
        this.fieldId = fieldId
        this.appliedValue = appliedValue
        this.draftText = draftText
        this.validationError = validationError
        this.draftFieldVersion = draftFieldVersion
        this.isFocused = isFocused
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
    }
}

/// One atomic read of an application's editable truth. `contextVersion`
/// changes for a visible content/validation update; focus alone is not a
/// content write. `baseAppliedConfigVersion` is compared on Apply so a human
/// cannot silently apply a draft based on an obsolete configuration.
public class CjguiSharedFormSnapshot {
    public let contextVersion: Int64
    public let appliedConfigVersion: Int64
    public let draftVersion: Int64
    public let baseAppliedConfigVersion: Int64
    private let fields: ArrayList<CjguiSharedFormFieldProjection>
    public let canApply: Bool
    public let statusMessage: String

    public init(
        contextVersion: Int64,
        appliedConfigVersion: Int64,
        draftVersion: Int64,
        baseAppliedConfigVersion: Int64,
        fields: ArrayList<CjguiSharedFormFieldProjection>,
        canApply: Bool,
        statusMessage: String
    ) {
        this.contextVersion = contextVersion
        this.appliedConfigVersion = appliedConfigVersion
        this.draftVersion = draftVersion
        this.baseAppliedConfigVersion = baseAppliedConfigVersion
        this.fields = ArrayList<CjguiSharedFormFieldProjection>(fields)
        this.canApply = canApply
        this.statusMessage = statusMessage
    }

    public func allFields(): ArrayList<CjguiSharedFormFieldProjection> {
        return ArrayList<CjguiSharedFormFieldProjection>(fields)
    }

    public func fieldForResourceId(resourceId: Int64): CjguiSharedFormFieldProjection {
        for (field in fields) {
            if (field.resourceId == resourceId) {
                return field
            }
        }
        throw IllegalArgumentException("unknown form resource")
    }
}

/// Reusable form-domain bridge used by the normal CJGUI window. Each human
/// method must delegate to the domain's ordinary shared-operation dispatcher;
/// it exists only to keep window code independent of a consumer's action IDs.
public interface CjguiSharedEditableFormDomain <: CjguiSharedOperationDomain {
    func formBinding(): CjguiSharedFormBinding
    func formSnapshot(): CjguiSharedFormSnapshot
    func editTextFromHuman(resourceId: Int64, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult
    func editBooleanFromHuman(resourceId: Int64, value: Bool): CjguiSharedOperationActionResult
    func applyDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult
    func cancelDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult
}

/// Experimental collection projection used alongside an editable detail form.
/// IDs are domain-owned and stable; `visible` window slots are never object
/// identity and can be paged independently of the collection size.
public class CjguiSharedCollectionItemProjection {
    public let resourceId: Int64
    public let title: String
    public let isSelected: Bool
    public init(resourceId: Int64, title: String, isSelected: Bool) {
        this.resourceId = resourceId; this.title = title; this.isSelected = isSelected
    }
    public static func missing(): CjguiSharedCollectionItemProjection {
        return CjguiSharedCollectionItemProjection(-1, "", false)
    }
}

public class CjguiSharedCollectionSnapshot {
    public let version: Int64
    public let selectedResourceId: Int64
    private let items: ArrayList<CjguiSharedCollectionItemProjection>
    public let statusMessage: String
    public init(version: Int64, selectedResourceId: Int64, items: ArrayList<CjguiSharedCollectionItemProjection>, statusMessage: String) {
        this.version = version; this.selectedResourceId = selectedResourceId
        this.items = ArrayList<CjguiSharedCollectionItemProjection>(items); this.statusMessage = statusMessage
    }
    public func allItems(): ArrayList<CjguiSharedCollectionItemProjection> { return ArrayList<CjguiSharedCollectionItemProjection>(items) }
}

/// Bounded collection metadata for range consumers. It avoids copying every
/// item merely to learn the visible list size, selection and status; the
/// underlying domain still owns ordering and authorization.
public class CjguiSharedCollectionRangeSnapshot {
    public let version: Int64
    public let totalCount: Int64
    public let selectedResourceId: Int64
    public let statusMessage: String
    public init(version: Int64, totalCount: Int64, selectedResourceId: Int64, statusMessage: String) {
        this.version = version; this.totalCount = if (totalCount > 0) { totalCount } else { 0 }
        this.selectedResourceId = selectedResourceId; this.statusMessage = statusMessage
    }
}

/// Optional public composition contract for a normal list/detail editor.
/// Each helper must route through the consumer's ordinary action dispatcher;
/// it does not introduce a second collection business implementation.
public interface CjguiSharedCollectionEditorDomain <: CjguiSharedEditableFormDomain {
    func collectionSnapshot(): CjguiSharedCollectionSnapshot
    func selectCollectionItemFromHuman(resourceId: Int64): CjguiSharedOperationActionResult
    func createCollectionItemFromHuman(): CjguiSharedOperationActionResult
    func copySelectedCollectionItemFromHuman(): CjguiSharedOperationActionResult
    func deleteSelectedCollectionItemFromHuman(): CjguiSharedOperationActionResult
    func undoFromHuman(): CjguiSharedOperationActionResult
    func redoFromHuman(): CjguiSharedOperationActionResult
    func saveFromHuman(): CjguiSharedOperationActionResult
    func saveAsFromHuman(path: String): CjguiSharedOperationActionResult
    func openFromHuman(path: String): CjguiSharedOperationActionResult
    func newUntitledFromHuman(): CjguiSharedOperationActionResult
    func discardUnsavedContentFromHuman(): CjguiSharedOperationActionResult
    func requestCloseFromHuman(): CjguiSharedOperationActionResult
    /// Stable-item forms prevent a queued UI event from being reinterpreted
    /// against a record selected by a later external operation.
    func editTextForCollectionItemFromHuman(itemResourceId: Int64, resourceId: Int64, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult
    func editBooleanForCollectionItemFromHuman(itemResourceId: Int64, resourceId: Int64, value: Bool): CjguiSharedOperationActionResult
    func applyDraftForCollectionItemFromHuman(itemResourceId: Int64, expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult
    func cancelDraftForCollectionItemFromHuman(itemResourceId: Int64, expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult
}

/// Optional range extension for normal virtual-list consumers. It does not
/// alter the existing full-snapshot or external-operation contracts; a domain
/// may retain a full protocol/context scan elsewhere while the framework only
/// asks it for materialized row objects.
public interface CjguiSharedRangeCollectionEditorDomain <: CjguiSharedCollectionEditorDomain {
    func collectionRangeSnapshot(): CjguiSharedCollectionRangeSnapshot
    func collectionItemAt(index: Int64): CjguiSharedCollectionItemProjection
    func collectionIndexForResourceId(resourceId: Int64): Int64
}
