// Availability is a STATE-ONLY question. A reader asking "may this field be
// edited right now" must never be answered by handing the current value to a
// condition as if it were the candidate the caller intends to write: a rule that
// refuses a no-op write would then report the whole field as blocked. A
// condition that only knows how to judge a candidate answers `unknown`, and the
// real write still evaluates the REAL candidate.
package cjgui_shared_operation_core

import std.collection.*

/// Refuses a write that would not change the value, but accepts a new one.
private class AvailabilityValueSensitiveCondition <: CjguiSharedFieldWriteCondition {
    public func rejectionFor(request: CjguiSharedFieldWriteRequest): String {
        if (request.requestedText == request.currentText) {
            return "value_unchanged"
        }
        return ""
    }
}

/// A state-only business condition: a submitted task freezes its title.
private class AvailabilityStateCondition <: CjguiSharedFieldWriteCondition {
    public func rejectionFor(request: CjguiSharedFieldWriteRequest): String {
        return if (request.currentMarked) { "title_frozen_after_submit" } else { "" }
    }

    public func stateRejectionFor(state: CjguiSharedFieldState): String {
        return if (state.currentMarked) { "title_frozen_after_submit" } else { "" }
    }
}

@Test
func availabilityForNeverInventsARequestedValue(): Unit {
    let valueRule = CjguiSharedFieldRule("title", "TEXT", 42, "SET_TITLE", "title",
        condition: Some(AvailabilityValueSensitiveCondition()))
    // Not blocked, not allowed: a state-only question this condition cannot answer.
    let unknown = valueRule.availabilityFor("same", false, 42, 7)
    @Assert(unknown.known, false)
    @Assert(unknown.isAvailable, false)
    // The WRITE path still enforces the condition against the real candidate.
    @Assert(valueRule.rejectionFor(CjguiSharedFieldWriteRequest("title", "SET_TITLE", "title",
        42, "same", false, "same", false, 7)), "value_unchanged")
    @Assert(valueRule.rejectionFor(CjguiSharedFieldWriteRequest("title", "SET_TITLE", "title",
        42, "new", false, "same", false, 7)), "")

    let stateRule = CjguiSharedFieldRule("title", "TEXT", 42, "SET_TITLE", "title",
        condition: Some(AvailabilityStateCondition()))
    let editable = stateRule.availabilityFor("t", false, 42, 7)
    @Assert(editable.known, true)
    @Assert(editable.isAvailable, true)
    @Assert(editable.ownerResourceId, 42)
    @Assert(editable.stateVersion, 7)
    let frozen = stateRule.availabilityFor("t", true, 42, 7)
    @Assert(frozen.known, true)
    @Assert(frozen.isAvailable, false)
    @Assert(frozen.reason, "title_frozen_after_submit")
    // The SAME reason the write refuses with.
    @Assert(stateRule.rejectionFor(CjguiSharedFieldWriteRequest("title", "SET_TITLE", "title",
        42, "new", false, "t", true, 7)), "title_frozen_after_submit")

    // No condition: available whenever the target exists.
    let plainRule = CjguiSharedFieldRule("title", "TEXT", 42, "SET_TITLE", "title")
    @Assert(plainRule.availabilityFor("t", false, 42, 7).isAvailable, true)
    let noTarget = plainRule.availabilityFor("t", false, -1, 7)
    @Assert(noTarget.isAvailable, false)
    @Assert(noTarget.reason, "field_target_unavailable")
}
