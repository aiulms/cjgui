package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func printPresetOtherFieldWriteKeepsTheTextFieldVersion(): Unit {
    let domain = PrintPresetDomain()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let text = CjguiGeneratedFieldRangeSession(form, "jobName")
    let session = CjguiTextSession(CjguiRangeTextWindow(101, "job", text, text))
    session.bind()
    session.setSelection16(0, 1)
    let before = text.rangeTextVersion()
    @Assert(domain.editTextFromHuman(6202, "8", 1, 1).applied, true)
    @Assert(text.rangeTextVersion(), before)
    let _ = session.refreshMirror()
    @Assert(session.selection16()[0], 0)
    @Assert(session.selection16()[1], 1)
    let selected = session.selectedSourceRange().getOrThrow()
    @Assert(selected[0], before)
    @Assert(selected[1], 0)
    @Assert(selected[2], 3)
    @Assert(domain.editBooleanFromHuman(6203, false).applied, true)
    @Assert(text.rangeTextVersion(), before)
    @Assert(text.applyRangeTextEdit(before, 0, text.rangeTextByteLength(), "Package").applied, true)
    let changed = text.rangeTextVersion()
    @Assert(changed > before, true)
    @Assert(form.executeAction("APPLY_DRAFT", "apply").applied, true)
    @Assert(text.rangeTextVersion(), changed)
    @Assert(text.applyRangeTextEdit(before, 0, 0, "STALE").isVersionConflict, true)
    @Assert(form.draftText("jobName"), "Package")
}

@Test
func printPresetPublicCatalogUsesTheBusinessDeclaration(): Unit {
    let domain = PrintPresetDomain()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let catalog = form.capabilityCatalog()
    @Assert(catalog.fieldIds().size, 3)
    @Assert(catalog.fieldFor("jobName").getOrThrow().maximumLength, 24)
    @Assert(catalog.fieldFor("copies").getOrThrow().minimum, 1)
    @Assert(catalog.fieldFor("copies").getOrThrow().maximum, 24)
    @Assert(catalog.fieldFor("duplex").getOrThrow().editorKind, "BOOLEAN")
    @Assert(catalog.componentFor("textInput").isSome(), true)
    @Assert(catalog.componentFor("label").isSome(), true)
    @Assert(catalog.actionFor("APPLY_DRAFT").getOrThrow().label, "提交打印预设")
    @Assert(catalog.actionFor("CANCEL_DRAFT").isSome(), true)
    @Assert(catalog.componentKinds().size, 7)
}

@Test
func printPresetRefusedApplyPreservesDraftAndOneOwnerThenCorrects(): Unit {
    let domain = PrintPresetDomain()
    @Assert(domain.editTextFromHuman(6202, "0", 1, 1).applied, true)
    let invalid = domain.formSnapshot()
    @Assert(invalid.canApply, false)
    @Assert(invalid.fieldForResourceId(6202).validationError.isEmpty(), false)
    @Assert(domain.applyDraftFromHuman(invalid.draftVersion, invalid.baseAppliedConfigVersion).applied, false)
    @Assert(domain.formSnapshot().draftVersion, invalid.draftVersion)
    @Assert(domain.formSnapshot().fieldForResourceId(6202).draftText, "0")
    @Assert(domain.formSnapshot().fieldForResourceId(6202).appliedValue.integerValue, 4)
    @Assert(domain.editTextFromHuman(6203, "false", 0, 0).applied, false)
    @Assert(domain.editTextFromHuman(6202, "6", 1, 1).applied, true)
    let corrected = domain.formSnapshot()
    @Assert(domain.applyDraftFromHuman(corrected.draftVersion, corrected.baseAppliedConfigVersion).applied, true)
    @Assert(domain.formSnapshot().fieldForResourceId(6202).appliedValue.integerValue, 6)
    let stale = CjguiSharedOperationActionInvocation("CANCEL_DRAFT", invalid.contextVersion,
        ArrayList<Int64>([PrintPresetDomain.ownerId]), ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("expectedDraftVersion", CjguiSharedOperationValue.integer(invalid.draftVersion))]))
    @Assert(domain.executeFromExternal(stale).isVersionConflict, true)
    @Assert(domain.formSnapshot().fieldForResourceId(6202).appliedValue.integerValue, 6)
}

@Test
func printFormFeedbackPreservesInvalidDraftCorrectsAndCancels(): Unit {
    let domain = PrintPresetDomain()
    let binding = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    @Assert(domain.editTextFromHuman(6202, "0", 1, 1).applied, true)
    let invalid = binding.formFeedback().getOrThrow()
    let error = invalid.fieldFor("copies").getOrThrow().validationError
    @Assert(error.isEmpty(), false)
    @Assert(invalid.fieldFor("copies").getOrThrow().draftText, "0")
    @Assert(invalid.fieldAvailability("copies").isAvailable, true)
    @Assert(invalid.actionAvailability("APPLY_DRAFT").isAvailable, false)
    @Assert(invalid.actionAvailability("APPLY_DRAFT").reason, error)
    @Assert(invalid.actionAvailability("APPLY_DRAFT").stateVersion, invalid.snapshot.contextVersion)
    @Assert(domain.editTextFromHuman(6202, "6", 1, 1).applied, true)
    let corrected = binding.formFeedback().getOrThrow()
    @Assert(corrected.fieldFor("copies").getOrThrow().validationError, "")
    @Assert(corrected.actionAvailability("APPLY_DRAFT").isAvailable, true)
    // The earlier read is an immutable projection, not a second live draft.
    @Assert(invalid.fieldFor("copies").getOrThrow().draftText, "0")
    @Assert(binding.executeAction("CANCEL_DRAFT", "cancel").applied, true)
    let cancelled = binding.formFeedback().getOrThrow()
    @Assert(cancelled.fieldFor("copies").getOrThrow().draftText, "4")
    @Assert(cancelled.fieldFor("copies").getOrThrow().validationError, "")
    @Assert(cancelled.snapshot.appliedConfigVersion, 0)
}

// A legacy binding deliberately supplies no formFeedback implementation.
private class LegacyFeedbackBinding <: CjguiGeneratedUiRegionBinding {
    private let moving: Bool
    private var stamp: Int64 = 12
    public init(moving!: Bool = false) { this.moving = moving }
    public func ownerRevision(): Int64 {
        if (moving) { stamp += 1 }
        return stamp
    }
    public func draftSource(fieldId: String): String { return "legacy_test_projection" }
    public func fieldResourceId(fieldId: String): Int64 { return 6202 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 6200 }
    public func draftText(fieldId: String): String { return "0" }
    public func appliedText(fieldId: String): String { return "4" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "legacy")
    }
    public func actionAvailable(actionName: String): Bool { return true }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

private class FrozenFeedbackBinding <: CjguiGeneratedUiRegionBinding {
    private let binding: CjguiGeneratedUiFormBinding
    public var reads: Int64 = 0
    public init(binding: CjguiGeneratedUiFormBinding) { this.binding = binding }
    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        reads += 1
        return binding.formFeedback()
    }
    public func ownerRevision(): Int64 { return 9999 }
    public func fieldResourceId(fieldId: String): Int64 { return binding.fieldResourceId(fieldId) }
    public func fieldOperationResourceId(fieldId: String): Int64 { return PrintPresetDomain.ownerId }
    public func draftText(fieldId: String): String { throw IllegalStateException("split_live_read") }
    public func appliedText(fieldId: String): String { throw IllegalStateException("split_live_read") }
    public func draftBoolean(fieldId: String): ?Bool { throw IllegalStateException("split_live_read") }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return binding.executeAction(actionName, nodeKey)
    }
    public func actionAvailable(actionName: String): Bool { throw IllegalStateException("split_live_read") }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

@Test
func printRegionReadsOneFeedbackAndLegacyIsUnknown(): Unit {
    let domain = PrintPresetDomain()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    @Assert(domain.editTextFromHuman(6202, "0", 1, 1).applied, true)
    let provider = FrozenFeedbackBinding(form)
    let region = CjguiGeneratedUiWindowRegion(form.capabilityCatalog(), provider, "coherent")
    let fields = region.fieldsPayload()
    @Assert(provider.reads, 1)
    @Assert(fields.contains("FORM_STATE KNOWN 1 CONSISTENT 1 VERSION 1 DRAFT_VERSION 1"), true)
    @Assert(fields.contains("FIELD copies 6202 DRAFT_HEX 30 APPLIED_HEX 34 ERROR invalid"), true)
    @Assert(fields.contains("VALIDATION_VERSION 1 FIELD_VERSION 1"), true)
    @Assert(fields.contains("ACTION_STATE APPLY_DRAFT AVAILABLE 0"), true)
    @Assert(fields.contains("9999"), false)
    let snapshot = region.snapshotPayload()
    @Assert(provider.reads, 2)
    @Assert(snapshot.contains("SNAPSHOT_FIELD FORM_STATE KNOWN 1 CONSISTENT 1 VERSION 1"), true)
    @Assert(snapshot.contains("9999"), false)
    let legacy = CjguiGeneratedUiWindowRegion(form.capabilityCatalog(), LegacyFeedbackBinding(), "legacy")
    let unknown = legacy.fieldsPayload()
    @Assert(unknown.contains("FORM_STATE KNOWN 0"), true)
    @Assert(unknown.contains("ERROR unknown"), true)
    @Assert(unknown.contains("VALIDATION_STATE unknown"), true)
    @Assert(unknown.contains("ACTION_STATE APPLY_DRAFT AVAILABLE unknown"), true)
    @Assert(unknown.contains("DRAFT_SOURCE legacy_test_projection"), true)
    let moving = CjguiGeneratedUiWindowRegion(form.capabilityCatalog(), LegacyFeedbackBinding(moving: true), "moving")
    let refused = moving.fieldsPayload()
    @Assert(refused.contains("FORM_STATE KNOWN 0 CONSISTENT 0"), true)
    @Assert(refused.contains("FIELD copies"), false)
}
