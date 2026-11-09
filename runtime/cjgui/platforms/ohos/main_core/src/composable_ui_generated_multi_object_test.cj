package cjgui

import std.unittest.*
import std.unittest.testmacro.*
import cjgui_shared_operation_core.*

// The adapter must refuse EVERY write path — legacy overloads, the default
// instance and owned range sessions — when the owner publishes a block. A
// blocked action that still reaches the fallback is a write the UI promised
// not to make. Reads (availability, drafts, rebase) stay observable.

private class MultiObjectTestFallback <: CjguiGeneratedUiRegionBinding {
    var executions: Int64 = 0
    var intents: Int64 = 0
    var textEdits: Int64 = 0
    var confirmations: Int64 = 0
    var availability: CjguiSharedAvailability = CjguiSharedAvailability.allowed(900, 1)
    var actionBool: Bool = true

    public func ownerRevision(): Int64 { return 1 }
    public func fieldResourceId(fieldId: String): Int64 { return 81001 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 900 }
    public func draftText(fieldId: String): String { return "fallback" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        executions += 1
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return actionBool }
    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return availability
    }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        intents += 1
        return CjguiComposableUiDispatchResult(true)
    }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        textEdits += 1
        return CjguiRangeTextEditOutcome.accepted(expectedVersion, expectedVersion + 1)
    }
    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool {
        confirmations += 1
        return true
    }
}

private class MultiObjectTestOwnedObject <: CjguiGeneratedUiObjectBinding {
    let target: Int64
    let text: String
    var executions: Int64 = 0
    var intents: Int64 = 0
    var textEdits: Int64 = 0
    var confirmations: Int64 = 0
    var lastText: String = ""
    var lastVersion: Int64 = -1

    init(target: Int64, text: String) {
        this.target = target
        this.text = text
    }

    public func ownerTargetResourceId(): Int64 { return target }
    public func formFeedback(): ?CjguiGeneratedUiFormFeedback { return None }
    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return CjguiSharedAvailability.allowed(target, 1)
    }
    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return CjguiSharedAvailability.allowed(target, 1)
    }
    public func draftText(fieldId: String): String { return text }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        intents += 1
        return CjguiComposableUiDispatchResult(true)
    }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        executions += 1
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        textEdits += 1
        lastText = newText
        lastVersion = expectedVersion
        return CjguiRangeTextEditOutcome.accepted(expectedVersion, expectedVersion + 1)
    }
    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool {
        confirmations += 1
        return true
    }
}

private class MultiObjectTestFixture {
    let fallback = MultiObjectTestFallback()
    let first = MultiObjectTestOwnedObject(501, "A4")
    let second = MultiObjectTestOwnedObject(502, "B4")
    let adapter: CjguiGeneratedUiMultiObjectBinding

    init(blockedReason!: String = "") {
        let firstObject = first
        let secondObject = second
        adapter = CjguiGeneratedUiMultiObjectBinding(fallback,
            { key => key == "ruleA" || key == "ruleB" || key == "gone" },
            { key =>
                if (key == "ruleA") { return Some(firstObject) }
                if (key == "ruleB") { return Some(secondObject) }
                return None
            },
            namesDefaultInstance: { key => key == "" },
            ownerBlockedReason: { => blockedReason })
    }
}

private func multiObjectTestFieldIntent(instanceKey: String,
    ownerTarget: Int64): CjguiGeneratedUiIntent {
    return CjguiGeneratedUiIntent("field_change", "label", "",
        fieldId: "label", writerOperation: "EDIT_DRAFT_TEXT",
        ownerTargetResourceId: ownerTarget, argumentName: "text",
        value: CjguiSharedOperationValue.string("x"), instanceKey: instanceKey)
}

@Test
func multiObjectBlockedOwnerRefusesLegacyDefaultAndRangeWrites(): Unit {
    let fixture = MultiObjectTestFixture(blockedReason: "owner_locked")
    let adapter = fixture.adapter
    @Assert(adapter.actionAvailable("APPLY_DRAFT"), false)
    @Assert(adapter.actionAvailability("APPLY_DRAFT").reason, "owner_locked")
    @Assert(adapter.executeAction("APPLY_DRAFT", "root").reason, "owner_locked")
    @Assert(adapter.executeAction("APPLY_DRAFT", "root", "").reason, "owner_locked")
    @Assert(adapter.executeAction("APPLY_DRAFT", "root", "", 900, 1).reason, "owner_locked")
    @Assert(adapter.executeAction("APPLY_DRAFT", "root", "ruleA", 501, 1).reason,
        "owner_locked")
    @Assert(adapter.applyFieldIntent(multiObjectTestFieldIntent("", 900)).didApply, false)
    @Assert(adapter.applyFieldIntent(multiObjectTestFieldIntent("ruleA", 501)).didApply, false)
    let defaultEdit = adapter.applyTextEdit("label", 4, "x")
    @Assert(defaultEdit.applied, false)
    @Assert(defaultEdit.reason, "owner_locked")
    let ownedEdit = adapter.applyTextEdit("label", 4, "x", "ruleA")
    @Assert(ownedEdit.applied, false)
    @Assert(ownedEdit.reason, "owner_locked")
    @Assert(adapter.confirmFieldTextVersion("label", 4, { => true }), false)
    @Assert(adapter.confirmFieldTextVersion("label", 4, { => true }, "ruleA"), false)
    @Assert(fixture.fallback.executions, 0)
    @Assert(fixture.fallback.intents, 0)
    @Assert(fixture.fallback.textEdits, 0)
    @Assert(fixture.fallback.confirmations, 0)
    @Assert(fixture.first.executions, 0)
    @Assert(fixture.first.intents, 0)
    @Assert(fixture.first.textEdits, 0)
    @Assert(fixture.first.confirmations, 0)
}

@Test
func multiObjectRoutesEachInstanceByItsOwnAcceptedOwner(): Unit {
    let fixture = MultiObjectTestFixture()
    let adapter = fixture.adapter
    // Same field, same version, different owners: the instance key must reach
    // exactly that object and nothing else.
    @Assert(adapter.draftText("label", "ruleA"), "A4")
    @Assert(adapter.draftText("label", "ruleB"), "B4")
    @Assert(adapter.applyTextEdit("label", 4, "A5", "ruleA").applied, true)
    @Assert(fixture.first.lastText, "A5")
    @Assert(fixture.first.lastVersion, 4)
    @Assert(fixture.second.textEdits, 0)
    // A frozen target that no longer matches the resolved object is refused,
    // not redirected to the replacement.
    @Assert(adapter.executeAction("APPLY_DRAFT", "root", "ruleB", 501, 1).reason,
        "owner_target_retired")
    @Assert(fixture.second.executions, 0)
    @Assert(adapter.executeAction("APPLY_DRAFT", "root", "ruleA", 501, 1).applied, true)
    @Assert(fixture.first.executions, 1)
    // A retired key is named; an undeclared key never falls back to an owner.
    @Assert(adapter.applyTextEdit("label", 4, "x", "gone").reason, "对象已删除")
    @Assert(adapter.applyTextEdit("label", 4, "x", "ghost").reason, "unknown_instance")
    @Assert(adapter.executeAction("APPLY_DRAFT", "root", "ghost").reason, "unknown_instance")
}

@Test
func multiObjectLegacyAvailabilityAgreesWithKnownOwnerAnswer(): Unit {
    let fixture = MultiObjectTestFixture()
    let adapter = fixture.adapter
    fixture.fallback.availability = CjguiSharedAvailability.blocked("not_now", 900, 1)
    fixture.fallback.actionBool = true
    @Assert(adapter.actionAvailability("APPLY_DRAFT").reason, "not_now")
    @Assert(adapter.actionAvailable("APPLY_DRAFT"), false)
    fixture.fallback.availability = CjguiSharedAvailability.allowed(900, 1)
    @Assert(adapter.actionAvailable("APPLY_DRAFT"), true)
    // A legacy provider that publishes no availability keeps its boolean.
    fixture.fallback.availability = CjguiSharedAvailability.unknown()
    fixture.fallback.actionBool = true
    @Assert(adapter.actionAvailable("APPLY_DRAFT"), true)
    fixture.fallback.actionBool = false
    @Assert(adapter.actionAvailable("APPLY_DRAFT"), false)
}
