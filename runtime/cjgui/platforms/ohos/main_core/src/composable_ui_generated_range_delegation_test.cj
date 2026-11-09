package cjgui

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*

// The generic range bridge never owns a cross-version caret policy. It must
// delegate to the provider's mapping (including a refusal) exactly as the
// thermostat provider does for its abc -> abcX prefix change.

private class GeneratedRangeDelegationProvider <: CjguiGeneratedUiBindingProvider {
    private var versionValue: Int64 = 1
    private var textValue: String = "abc"

    public func fieldResourceId(fieldId: String): Int64 {
        return if (fieldId == "note") { 1 } else { -1 }
    }
    public func fieldOperationResourceId(fieldId: String): Int64 {
        return fieldResourceId(fieldId)
    }
    public func draftText(fieldId: String): String {
        return if (fieldId == "note") { textValue } else { "" }
    }
    public func appliedText(fieldId: String): String {
        return draftText(fieldId)
    }
    public func draftBoolean(fieldId: String): ?Bool {
        let _ = fieldId
        return None
    }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let _ = actionName
        let _ = nodeKey
        return CjguiGeneratedUiActionResult(false, "test_noop")
    }
    public func actionAvailable(actionName: String): Bool {
        let _ = actionName
        return false
    }
    public func rangeTextEditSupported(fieldId: String): Bool {
        return fieldId == "note"
    }
    public func fieldTextVersion(fieldId: String): Int64 {
        return if (fieldId == "note") { versionValue } else { -1 }
    }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        if (fieldId != "note" || expectedVersion != versionValue) {
            return CjguiRangeTextEditOutcome.conflict(versionValue, "version_moved")
        }
        textValue = newText
        versionValue += 1
        return CjguiRangeTextEditOutcome.accepted(expectedVersion, versionValue)
    }
    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool): Bool {
        return fieldId == "note" && expectedVersion == versionValue && action()
    }
    // The thermostat's own domain mapping: only the caret after "a" maps
    // unambiguously; every other request is its explicit refusal.
    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        if (fieldId != "note" || fromVersion != 1 || versionValue != 2 ||
            startByte != 1 || endByte != 1) {
            return None
        }
        return Some((versionValue, 1, 1))
    }

    public func appendX(): Unit {
        textValue = "abcX"
        versionValue = 2
    }
}

@Test
func generatedRangeBridgeDelegatesMappingAndRefusalToItsProvider(): Unit {
    let provider = GeneratedRangeDelegationProvider()
    let bridge = CjguiGeneratedFieldRangeSession(provider, "note")
    @Assert(bridge.readRangeText(0, 64).content, "abc")
    provider.appendX()
    // The provider maps the caret; the bridge does not move it to the end.
    let mapped = bridge.rebaseRangeTextSelection(1, 1, 1)
    @Assert(mapped.isSome(), true)
    if (let Some(range) <- mapped) {
        @Assert(range[0], 2)
        @Assert(range[1], 1)
        @Assert(range[2], 1)
    }
    // A provider refusal is preserved without a generic end-of-body fallback.
    @Assert(bridge.rebaseRangeTextSelection(1, 0, 0).isNone(), true)
    let unsupported = CjguiGeneratedFieldRangeSession(provider, "eco")
    @Assert(unsupported.rebaseRangeTextSelection(1, 0, 0).isNone(), true)
}

/// A provider that keeps two owners with the SAME text and SAME numeric
/// version. The instance key can be repointed between them, which is exactly
/// the case a version-only guard cannot distinguish.
private class RetirableRangeProvider <: CjguiGeneratedUiBindingProvider {
    private let texts = HashMap<Int64, String>()
    private let versions = HashMap<Int64, Int64>()
    var currentKey: String = "cardA"
    var currentTarget: Int64 = 1
    var incarnation: Int64 = 1

    public func seed(target: Int64, text: String, version: Int64): Unit {
        texts.add(target, text)
        versions.add(target, version)
    }
    public func textAt(target: Int64): String {
        return texts.get(target) ?? ""
    }
    public func versionAt(target: Int64): Int64 {
        return versions.get(target) ?? -1
    }
    private func targetFor(key: String): Int64 {
        return if (key == currentKey) { currentTarget } else { -1 }
    }
    private func applyTo(target: Int64, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        if (target < 0 || (versions.get(target) ?? -1) != expectedVersion) {
            return CjguiRangeTextEditOutcome.conflict(expectedVersion, "version_moved")
        }
        texts.add(target, newText)
        let next = expectedVersion + 1
        versions.add(target, next)
        return CjguiRangeTextEditOutcome.accepted(expectedVersion, next)
    }
    public func fieldResourceId(fieldId: String): Int64 { return 7 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return currentTarget }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return targetFor(instanceKey)
    }
    public func draftText(fieldId: String): String { return textAt(currentTarget) }
    public func draftText(fieldId: String, instanceKey: String): String {
        return textAt(targetFor(instanceKey))
    }
    public func appliedText(fieldId: String): String { return draftText(fieldId) }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "test_noop")
    }
    public func actionAvailable(actionName: String): Bool { return false }
    public func rangeTextEditSupported(fieldId: String): Bool { return true }
    public func rangeTextEditSupported(fieldId: String, instanceKey: String): Bool {
        return targetFor(instanceKey) >= 0
    }
    public func fieldTextVersion(fieldId: String): Int64 { return versionAt(currentTarget) }
    public func fieldTextVersion(fieldId: String, instanceKey: String): Int64 {
        return versionAt(targetFor(instanceKey))
    }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        return applyTo(currentTarget, expectedVersion, newText)
    }
    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        return applyTo(targetFor(instanceKey), expectedVersion, newText)
    }
    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool {
        return versionAt(currentTarget) == expectedVersion && action()
    }
    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool,
        instanceKey: String): Bool {
        return versionAt(targetFor(instanceKey)) == expectedVersion && action()
    }
    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        return None
    }
    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64, instanceKey: String): ?(Int64, Int64, Int64) {
        return None
    }
}

@Test
func generatedRangeSessionFreezesOwnerIdentityNotJustKeyAndVersion(): Unit {
    let provider = RetirableRangeProvider()
    provider.seed(1, "same", 7)
    provider.seed(2, "same", 7)
    let firstBinding = { => provider.incarnation == 1 }
    let old = CjguiGeneratedFieldRangeSession(provider, "note", instanceKey: "cardA",
        ownerTarget: 1, bindingCurrent: firstBinding)
    @Assert(old.rangeTextVersion(), 7)
    @Assert(old.readRangeText(0, 64).content, "same")

    // Same key, same text, same numeric version, DIFFERENT owner.
    provider.currentTarget = 2
    @Assert(old.rangeTextVersion(), -1)
    let refused = old.applyRangeTextEdit(7, 0, 4, "OLD")
    @Assert(refused.applied, false)
    @Assert(refused.reason, "owner_target_retired")
    @Assert(provider.textAt(1), "same")
    @Assert(provider.textAt(2), "same")
    let staleRead = old.readRangeText(0, 64)
    @Assert(staleRead.complete, false)
    @Assert(staleRead.pendingReason, "owner_target_retired")
    @Assert(old.rebaseRangeTextSelection(7, 0, 4).isNone(), true)

    // The NEW binding edits the new owner normally.
    let fresh = CjguiGeneratedFieldRangeSession(provider, "note", instanceKey: "cardA",
        ownerTarget: 2, bindingCurrent: firstBinding)
    let applied = fresh.applyRangeTextEdit(7, 0, 4, "B2")
    @Assert(applied.applied, true)
    @Assert(provider.textAt(2), "B2")
    @Assert(provider.textAt(1), "same")

    // Removal + re-add: even the same key/target/text/version is a NEW
    // accepted generation, so the held session stays retired.
    provider.incarnation = 2
    let late = fresh.applyRangeTextEdit(8, 0, 2, "LATE")
    @Assert(late.applied, false)
    @Assert(late.reason, "binding_retired")
    @Assert(provider.textAt(2), "B2")

    let readded = CjguiGeneratedFieldRangeSession(provider, "note", instanceKey: "cardA",
        ownerTarget: 2, bindingCurrent: { => provider.incarnation == 2 })
    let continued = readded.applyRangeTextEdit(8, 0, 2, "C3")
    @Assert(continued.applied, true)
    @Assert(provider.textAt(2), "C3")
}
