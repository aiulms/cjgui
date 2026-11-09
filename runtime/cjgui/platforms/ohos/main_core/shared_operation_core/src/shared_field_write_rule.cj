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
/// The authoritative STATE a write condition may judge on its own. It contains
/// no requested value: a legality question about "may this field be edited right
/// now" must never be answered by inventing the value a caller might write.
public class CjguiSharedFieldState {
    public let fieldId: String
    public let targetResourceId: Int64
    public let currentText: String
    public let currentMarked: Bool
    public let version: Int64

    public init(fieldId: String, targetResourceId: Int64, currentText: String,
                currentMarked: Bool, version: Int64) {
        this.fieldId = fieldId
        this.targetResourceId = targetResourceId
        this.currentText = currentText
        this.currentMarked = currentMarked
        this.version = version
    }
}

/// Sentinel a condition returns when it cannot answer from state alone. It is
/// never published as a rejection reason.
public let CJGUI_SHARED_FIELD_STATE_UNKNOWN: String = "state_verdict_unknown"

public interface CjguiSharedFieldWriteCondition {
    /// The full write verdict: the condition may inspect the CANDIDATE value and
    /// the current state. This is what the owner enforces on a real write.
    func rejectionFor(request: CjguiSharedFieldWriteRequest): String

    /// State-only verdict for READERS (an editor's enabled projection). The
    /// default is the unknown sentinel: a condition that has not declared how to
    /// judge from state alone must not be evaluated with a fabricated candidate
    /// value. A state-only condition (for example "a submitted task is frozen")
    /// overrides this and answers with the SAME reason the write path uses.
    func stateRejectionFor(state: CjguiSharedFieldState): String {
        return CJGUI_SHARED_FIELD_STATE_UNKNOWN
    }
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

/// Current, read-only availability of one declared field or action.
///
/// This is the DYNAMIC fact ("may this be edited right now, and if not, why"),
/// deliberately separate from the STATIC declaration (a writer/type/range
/// exists). It is derived from the SAME application condition the owner enforces
/// on write, so an editor's `enabled` state and the owner's rejection can never
/// disagree — and a fresh "available" answer is still not a permission: the
/// owner re-checks the condition inside its write transaction.
///
/// `known=false` means the owner cannot evaluate the condition right now (for
/// example no rule is registered). A caller must then not present the answer as
/// either "allowed" or "blocked".
public class CjguiSharedAvailability {
    public let known: Bool
    public let isAvailable: Bool
    /// The owner's reason when blocked ("" when available or unknown). It is the
    /// SAME string the owner publishes on a refused write.
    public let reason: String
    /// Owner/target the decision applies to (-1 when none).
    public let ownerResourceId: Int64
    /// Authoritative state revision the answer was evaluated against, so a
    /// consumer can tell whether its own view is stale.
    public let stateVersion: Int64

    public init(known: Bool, isAvailable: Bool, reason: String, ownerResourceId: Int64,
                stateVersion: Int64) {
        this.known = known
        this.isAvailable = isAvailable
        this.reason = reason
        this.ownerResourceId = ownerResourceId
        this.stateVersion = stateVersion
    }

    /// No rule/condition is reachable: neither allowed nor blocked is claimed.
    public static func unknown(): CjguiSharedAvailability {
        return CjguiSharedAvailability(false, false, "", -1, 0)
    }

    public static func blocked(reason: String, ownerResourceId: Int64,
                               stateVersion: Int64): CjguiSharedAvailability {
        return CjguiSharedAvailability(true, false, reason, ownerResourceId, stateVersion)
    }

    public static func allowed(ownerResourceId: Int64, stateVersion: Int64): CjguiSharedAvailability {
        return CjguiSharedAvailability(true, true, "", ownerResourceId, stateVersion)
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

    /// The application's OWN condition alone, evaluated with the authoritative
    /// values the owner supplies. "" accepts; any other string is the rejection
    /// reason. This is the ONE place the business condition is read, so a refused
    /// write and a read-only availability answer share the same reason source
    /// instead of two hand-maintained judgments.
    public func conditionRejectionFor(request: CjguiSharedFieldWriteRequest): String {
        if (let Some(applicationCondition) <- this.condition) {
            return applicationCondition.rejectionFor(request)
        }
        return ""
    }

    /// Current availability of this field for a READER: may it be edited now,
    /// and if not, why. It consults ONLY state-related facts. The declared
    /// value-dependent constraint is deliberately NOT evaluated here: a query
    /// must not invent a candidate value to test with (an empty required field is
    /// perfectly editable; it merely cannot be submitted empty). A fresh
    /// `isAvailable` answer is not a permission — the owner re-checks inside its
    /// write transaction.
    public func availabilityFor(currentText: String, currentMarked: Bool,
                                targetResourceId: Int64, version: Int64): CjguiSharedAvailability {
        if (targetResourceId < 0) {
            return CjguiSharedAvailability.blocked("field_target_unavailable",
                targetResourceId, version)
        }
        // STATE-ONLY evaluation: the requested value is deliberately NOT
        // fabricated from the current value. A condition that only knows how to
        // judge a candidate write answers "unknown" here instead of being handed
        // the current value and declaring the field blocked.
        let state = CjguiSharedFieldState(this.fieldId, targetResourceId, currentText,
            currentMarked, version)
        let reason = this.stateRejectionFor(state)
        if (reason == CJGUI_SHARED_FIELD_STATE_UNKNOWN) {
            return CjguiSharedAvailability.unknown()
        }
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, targetResourceId, version)
        }
        return CjguiSharedAvailability.allowed(targetResourceId, version)
    }

    /// The application condition's state-only verdict, or the unknown sentinel
    /// when no condition is declared at all (an unconditional rule is available
    /// whenever its target is).
    public func stateRejectionFor(state: CjguiSharedFieldState): String {
        if (let Some(applicationCondition) <- this.condition) {
            return applicationCondition.stateRejectionFor(state)
        }
        return ""
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
        return this.conditionRejectionFor(request)
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
