// Thin multi-object adapter between a generated region and application objects.
//
// The application keeps owning its objects, drafts, rules, persistence and
// authorization: it maps one DECLARED instance key to one object binding and
// supplies a fallback region binding for its single-owner/default instances.
// This adapter only forwards reads, availability, intents, actions and range
// sessions with the SAME accepted owner target and never invents a second
// draft table or version counter.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

/// One application object addressed by a declared instance key. The provider
/// gateway in the consumer supplies these; the framework never constructs or
/// caches one across an accepted structure version.
public interface CjguiGeneratedUiObjectBinding {
    /// The owner target this object currently IS. Compared with the target
    /// frozen in the accepted scene, so an event for a retired object can never
    /// reach its replacement.
    func ownerTargetResourceId(): Int64
    func formFeedback(): ?CjguiGeneratedUiFormFeedback
    func fieldAvailability(fieldId: String): CjguiSharedAvailability
    func actionAvailability(actionName: String): CjguiSharedAvailability
    func draftText(fieldId: String): String
    func draftBoolean(fieldId: String): ?Bool
    func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult
    func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult
    // Owned range-session capabilities. An object that does not implement the
    // owner text transaction keeps the safe defaults, exactly like a legacy
    // single-owner provider that never opted in.
    func rangeTextEditSupported(fieldId: String): Bool { false }
    func fieldTextVersion(fieldId: String): Int64 { -1 }
    func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome.rejected(-1, "text_edit_unsupported")
    }
    func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool { false }
    func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64,
        startByte: Int64, endByte: Int64): ?(Int64, Int64, Int64) { None }
}

/// The single-owner subset a default-instance fallback may delegate to.
/// `CjguiGeneratedUiFormBinding` is the normal implementation; a consumer with
/// another single-owner binding can supply its own without copying forwarding.
public interface CjguiGeneratedUiSingleOwnerBinding {
    func ownerRevision(): Int64
    func formFeedback(): ?CjguiGeneratedUiFormFeedback
    func fieldResourceId(fieldId: String): Int64
    func fieldOperationResourceId(fieldId: String): Int64
    func draftText(fieldId: String): String
    func draftBoolean(fieldId: String): ?Bool
    func appliedText(fieldId: String): String
    func fieldAvailability(fieldId: String): CjguiSharedAvailability
    func actionAvailability(actionName: String): CjguiSharedAvailability
    func actionAvailable(actionName: String): Bool
    func generatedSelectBinding(fieldId: String): ?CjguiSelectFieldBinding
    func generatedSelectBindings(): ArrayList<CjguiSelectFieldBinding>
    func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult
    func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult
}

extend CjguiGeneratedUiFormBinding <: CjguiGeneratedUiSingleOwnerBinding {}

/// Resolves DECLARED instance keys to application objects.
///
/// `namesObject` stays true for a retired key so a late event is refused by
/// name. A key that names neither an object nor a declared default instance is
/// refused as `unknownReason`; it never falls back to the single owner. A key
/// that IS an object but no longer resolves is refused as `retiredReason`.
public class CjguiGeneratedUiMultiObjectBinding <: CjguiGeneratedUiRegionBinding {
    private let fallback: CjguiGeneratedUiRegionBinding
    private let namesObject: (String) -> Bool
    private let resolveObject: (String) -> ?CjguiGeneratedUiObjectBinding
    private let namesDefaultInstance: (String) -> Bool
    private let ownerBlockedReason: () -> String
    private let retiredReason: String
    private let unknownReason: String

    public init(fallback: CjguiGeneratedUiRegionBinding,
        namesObject: (String) -> Bool,
        resolveObject: (String) -> ?CjguiGeneratedUiObjectBinding,
        namesDefaultInstance!: (String) -> Bool = { key => key.size == 0 },
        ownerBlockedReason!: () -> String = { => "" },
        retiredReason!: String = "对象已删除",
        unknownReason!: String = "unknown_instance") {
        this.fallback = fallback
        this.namesObject = namesObject
        this.resolveObject = resolveObject
        this.namesDefaultInstance = namesDefaultInstance
        this.ownerBlockedReason = ownerBlockedReason
        this.retiredReason = retiredReason
        this.unknownReason = unknownReason
    }

    private func isDefault(instanceKey: String): Bool {
        return !namesObject(instanceKey) && namesDefaultInstance(instanceKey)
    }

    private func refused(instanceKey: String): Bool {
        return namesObject(instanceKey) || isDefault(instanceKey)
    }

    private func blocked(): Bool {
        return ownerBlockedReason().size > 0
    }

    private func blockedAvailability(): CjguiSharedAvailability {
        return CjguiSharedAvailability.blocked(ownerBlockedReason(), -1, fallback.ownerRevision())
    }

    private func retiredAvailability(): CjguiSharedAvailability {
        return CjguiSharedAvailability.blocked(retiredReason, -1, fallback.ownerRevision())
    }

    private func unknownAvailability(): CjguiSharedAvailability {
        return CjguiSharedAvailability.blocked(unknownReason, -1, fallback.ownerRevision())
    }

    public func ownerRevision(): Int64 {
        return fallback.ownerRevision()
    }

    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        return fallback.formFeedback()
    }

    public func formFeedback(instanceKey: String): ?CjguiGeneratedUiFormFeedback {
        if (isDefault(instanceKey)) {
            return fallback.formFeedback(instanceKey)
        }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.formFeedback()
            case None => None
        }
    }

    public func fieldResourceId(fieldId: String): Int64 {
        return fallback.fieldResourceId(fieldId)
    }

    public func generatedSelectBinding(fieldId: String): ?CjguiSelectFieldBinding {
        return fallback.generatedSelectBinding(fieldId)
    }

    public func generatedSelectBindings(): ArrayList<CjguiSelectFieldBinding> {
        return fallback.generatedSelectBindings()
    }

    public func fieldOperationResourceId(fieldId: String): Int64 {
        return fallback.fieldOperationResourceId(fieldId)
    }

    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        if (isDefault(instanceKey)) {
            return fallback.fieldOperationResourceId(fieldId, instanceKey)
        }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.ownerTargetResourceId()
            case None => -1
        }
    }

    public func draftText(fieldId: String): String {
        return fallback.draftText(fieldId)
    }

    public func draftText(fieldId: String, instanceKey: String): String {
        if (isDefault(instanceKey)) {
            return fallback.draftText(fieldId, instanceKey)
        }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.draftText(fieldId)
            case None => ""
        }
    }

    public func appliedText(fieldId: String): String {
        return fallback.appliedText(fieldId)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return fallback.draftBoolean(fieldId)
    }

    public func draftBoolean(fieldId: String, instanceKey: String): ?Bool {
        if (isDefault(instanceKey)) {
            return fallback.draftBoolean(fieldId, instanceKey)
        }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.draftBoolean(fieldId)
            case None => None
        }
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        if (blocked()) { return blockedAvailability() }
        return fallback.fieldAvailability(fieldId)
    }

    public func fieldAvailability(fieldId: String, instanceKey: String): CjguiSharedAvailability {
        if (blocked()) { return blockedAvailability() }
        if (isDefault(instanceKey)) {
            return fallback.fieldAvailability(fieldId, instanceKey)
        }
        if (!namesObject(instanceKey)) { return unknownAvailability() }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.fieldAvailability(fieldId)
            case None => retiredAvailability()
        }
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        if (blocked()) { return blockedAvailability() }
        return fallback.actionAvailability(actionName)
    }

    public func actionAvailability(actionName: String, instanceKey: String):
        CjguiSharedAvailability {
        if (blocked()) { return blockedAvailability() }
        if (isDefault(instanceKey)) {
            return fallback.actionAvailability(actionName, instanceKey)
        }
        if (!namesObject(instanceKey)) { return unknownAvailability() }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.actionAvailability(actionName)
            case None => retiredAvailability()
        }
    }

    public func actionAvailable(actionName: String): Bool {
        if (blocked()) { return false }
        // When the owner publishes a known availability, that answer IS the
        // answer; a legacy boolean must not disagree with the same state.
        let availability = fallback.actionAvailability(actionName)
        if (availability.known) { return availability.isAvailable }
        return fallback.actionAvailable(actionName)
    }

    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        if (isDefault(instanceKey)) {
            return fallback.actionOperationResourceId(actionName, instanceKey)
        }
        if (!namesObject(instanceKey)) { return -1 }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.ownerTargetResourceId()
            case None => -1
        }
    }

    public func executeAction(actionName: String, nodeKey: String):
        CjguiGeneratedUiActionResult {
        if (blocked()) {
            return CjguiGeneratedUiActionResult(false, ownerBlockedReason())
        }
        return fallback.executeAction(actionName, nodeKey)
    }

    public func executeAction(actionName: String, nodeKey: String, instanceKey: String):
        CjguiGeneratedUiActionResult {
        if (blocked()) {
            return CjguiGeneratedUiActionResult(false, ownerBlockedReason())
        }
        if (isDefault(instanceKey)) {
            return fallback.executeAction(actionName, nodeKey, instanceKey)
        }
        if (!namesObject(instanceKey)) {
            return CjguiGeneratedUiActionResult(false, unknownReason)
        }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.executeAction(actionName, nodeKey)
            case None => CjguiGeneratedUiActionResult(false, retiredReason)
        }
    }

    public func executeAction(actionName: String, nodeKey: String, instanceKey: String,
        ownerTargetResourceId: Int64, instanceIncarnation: Int64): CjguiGeneratedUiActionResult {
        if (blocked()) {
            return CjguiGeneratedUiActionResult(false, ownerBlockedReason())
        }
        if (isDefault(instanceKey)) {
            return fallback.executeAction(actionName, nodeKey, instanceKey,
                ownerTargetResourceId, instanceIncarnation)
        }
        if (!namesObject(instanceKey)) {
            return CjguiGeneratedUiActionResult(false, unknownReason)
        }
        let binding = match (resolveObject(instanceKey)) {
            case Some(value) => value
            case None => return CjguiGeneratedUiActionResult(false, retiredReason)
        }
        // The accepted target is the authority. Re-resolving the key and finding
        // a NEW object must not redirect the original event.
        if (binding.ownerTargetResourceId() != ownerTargetResourceId) {
            return CjguiGeneratedUiActionResult(false, "owner_target_retired")
        }
        return binding.executeAction(actionName, nodeKey)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        if (blocked()) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (isDefault(intent.instanceKey)) {
            return fallback.applyFieldIntent(intent)
        }
        if (!namesObject(intent.instanceKey)) {
            return CjguiComposableUiDispatchResult(false)
        }
        let binding = match (resolveObject(intent.instanceKey)) {
            case Some(value) => value
            case None => return CjguiComposableUiDispatchResult(false)
        }
        // A field event carries the SAME frozen owner target as an action. A
        // key that now resolves to another object must not redirect it.
        if (!intent.isFieldEdit() || intent.fieldId.size == 0 ||
            intent.ownerTargetResourceId != binding.ownerTargetResourceId()) {
            return CjguiComposableUiDispatchResult(false)
        }
        return binding.applyFieldIntent(intent)
    }

    public func rangeTextEditSupported(fieldId: String): Bool {
        return fallback.rangeTextEditSupported(fieldId)
    }

    public func rangeTextEditSupported(fieldId: String, instanceKey: String): Bool {
        if (isDefault(instanceKey)) {
            return fallback.rangeTextEditSupported(fieldId, instanceKey)
        }
        if (!namesObject(instanceKey)) { return false }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.rangeTextEditSupported(fieldId)
            case None => false
        }
    }

    public func fieldTextVersion(fieldId: String): Int64 {
        return fallback.fieldTextVersion(fieldId)
    }

    public func fieldTextVersion(fieldId: String, instanceKey: String): Int64 {
        if (isDefault(instanceKey)) {
            return fallback.fieldTextVersion(fieldId, instanceKey)
        }
        if (!namesObject(instanceKey)) { return -1 }
        return match (resolveObject(instanceKey)) {
            case Some(binding) => binding.fieldTextVersion(fieldId)
            case None => -1
        }
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        if (blocked()) {
            return CjguiRangeTextEditOutcome.rejected(expectedVersion, ownerBlockedReason())
        }
        return fallback.applyTextEdit(fieldId, expectedVersion, newText)
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        if (blocked()) {
            return CjguiRangeTextEditOutcome.rejected(expectedVersion, ownerBlockedReason())
        }
        if (isDefault(instanceKey)) {
            return fallback.applyTextEdit(fieldId, expectedVersion, newText, instanceKey)
        }
        if (!namesObject(instanceKey)) {
            return CjguiRangeTextEditOutcome.rejected(expectedVersion, unknownReason)
        }
        return match (resolveObject(instanceKey)) {
            case Some(binding) =>
                binding.applyTextEdit(fieldId, expectedVersion, newText)
            case None => CjguiRangeTextEditOutcome.rejected(expectedVersion, retiredReason)
        }
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool {
        if (blocked()) { return false }
        return fallback.confirmFieldTextVersion(fieldId, expectedVersion, action)
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool, instanceKey: String): Bool {
        if (blocked()) { return false }
        if (isDefault(instanceKey)) {
            return fallback.confirmFieldTextVersion(fieldId, expectedVersion, action, instanceKey)
        }
        if (!namesObject(instanceKey)) { return false }
        return match (resolveObject(instanceKey)) {
            case Some(binding) =>
                binding.confirmFieldTextVersion(fieldId, expectedVersion, action)
            case None => false
        }
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64,
        startByte: Int64, endByte: Int64): ?(Int64, Int64, Int64) {
        return fallback.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte)
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64,
        startByte: Int64, endByte: Int64, instanceKey: String): ?(Int64, Int64, Int64) {
        if (isDefault(instanceKey)) {
            return fallback.rebaseFieldTextSelection(fieldId, fromVersion, startByte,
                endByte, instanceKey)
        }
        if (!namesObject(instanceKey)) { return None }
        return match (resolveObject(instanceKey)) {
            case Some(binding) =>
                binding.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte)
            case None => None
        }
    }

    public func draftSource(fieldId: String): String {
        return fallback.draftSource(fieldId)
    }
}
