package cjgui_shared_operation_core

import std.collection.*
import std.unicode.*

/// An application-supplied condition evaluated INSIDE the owner's write
/// transaction. Returning "" accepts the request; any other string is the
/// rejection reason and is published unchanged to every entry point.
///
/// The owner calls this with the authoritative in-transaction values instead of
/// letting the application read the domain again: the domain lock is held at
/// that moment, so a callback that re-entered `snapshot()` would deadlock.
public interface CjguiSharedFieldWriteCondition {
    func rejectionFor(request: CjguiSharedFieldWriteRequest): String
}

/// One declared write request plus the values that are authoritative at the
/// moment the owner evaluates it. Also carries the condition's input, which is
/// how a business condition (for example "a submitted task is frozen") can
/// change the verdict of an otherwise legal request without a version conflict.
public class CjguiSharedFieldWriteRequest {
    public let fieldId: String
    public let writer: String
    public let argument: String
    public let targetResourceId: Int64
    public let requestedText: String
    public let requestedBoolean: Bool
    public let currentText: String
    public let currentMarked: Bool
    public let version: Int64

    public init(fieldId: String, writer: String, argument: String, targetResourceId: Int64,
                requestedText: String, requestedBoolean: Bool, currentText: String,
                currentMarked: Bool, version: Int64) {
        this.fieldId = fieldId
        this.writer = writer
        this.argument = argument
        this.targetResourceId = targetResourceId
        this.requestedText = requestedText
        this.requestedBoolean = requestedBoolean
        this.currentText = currentText
        this.currentMarked = currentMarked
        this.version = version
    }
}

/// The ONE declaration of a writable application field: its stable field id,
/// the owner operation and argument name that perform the write, and the rule
/// the owner enforces. Handwritten panes, generated editors and external
/// callers all derive from this object; none of them restates the writer, the
/// argument or the constraint.
///
/// `maximumLength` is measured in Unicode scalar values (Rune), not UTF-8
/// bytes, so a CJK title is not silently limited to a third of the declared
/// length. It applies to text fields; `required` applies to text fields as
/// well (`isMarked`-style switches declare no required constraint).
public class CjguiSharedFieldRule {
    public let fieldId: String
    public let editorKind: String
    public let targetResourceId: Int64
    public let writer: String
    public let argument: String
    public let required: Bool
    public let maximumLength: Int64
    private let condition: ?CjguiSharedFieldWriteCondition

    public init(fieldId: String, editorKind: String, targetResourceId: Int64, writer: String,
                argument: String, required!: Bool = false, maximumLength!: Int64 = 0,
                condition!: ?CjguiSharedFieldWriteCondition = None) {
        this.fieldId = fieldId
        this.editorKind = editorKind
        this.targetResourceId = targetResourceId
        this.writer = writer
        this.argument = argument
        this.required = required
        this.maximumLength = maximumLength
        this.condition = condition
    }

    /// The declared constraint alone, for a caller that only has the requested
    /// text (the handwritten pane's immediate feedback). The owner uses
    /// `rejectionFor`, which adds its own condition on top of this.
    public func declaredTextRejection(text: String): String {
        if (this.editorKind == "BOOLEAN") {
            return ""
        }
        if (this.required && text.trim().size == 0) {
            return "${this.fieldId}_required"
        }
        if (this.maximumLength > 0 && CjguiSharedFieldRule.scalarCount(text) > this.maximumLength) {
            return "${this.fieldId}_too_long"
        }
        return ""
    }

    /// The declared constraint alone, with no application condition.
    public func declaredRejectionFor(request: CjguiSharedFieldWriteRequest): String {
        return this.declaredTextRejection(request.requestedText)
    }

    /// The authoritative rule: the declared constraint plus the application's
    /// own condition. The argument name is checked first, so a declared writer
    /// invoked with another argument is refused instead of writing a different
    /// field.
    public func rejectionFor(request: CjguiSharedFieldWriteRequest): String {
        if (request.argument != this.argument) {
            return "unknown_argument"
        }
        let declared = this.declaredRejectionFor(request)
        if (declared.size > 0) {
            return declared
        }
        if (let Some(applicationCondition) <- this.condition) {
            return applicationCondition.rejectionFor(request)
        }
        return ""
    }

    /// Length unit of `maximumLength`: Unicode scalar values.
    public static func scalarCount(text: String): Int64 {
        var count: Int64 = 0
        for (_ in text.runes()) {
            count += 1
        }
        return count
    }
}
