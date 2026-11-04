package cjgui_ui_only_starter

import std.unittest.*
import std.unittest.testmacro.*

@Test
func uiOnlyWorkPayloadRoundTripsApplicationStateWithoutNativeIdentity(): Unit {
    let original = UiOnlyWorkState("第二个应用\n未保存的短注释", 3, 17)
    let encoded = original.payload()
    let candidate = uiOnlyDecodeWorkPayload(encoded)
    @Assert(candidate.isSome(), true)
    let restored = candidate.getOrThrow()
    @Assert(restored.note, original.note)
    @Assert(restored.count, 3)
    @Assert(restored.revision, 17)
    @Assert(uiOnlyDecodeWorkPayload(UiOnlyWorkState("", 0, 1).payload()).isSome(), true)
    @Assert(encoded.contains("endpoint"), false)
    @Assert(encoded.contains("window"), false)
}

@Test
func uiOnlyWorkPayloadRefusesOtherSchemasPartialAndOutOfBudgetState(): Unit {
    @Assert(uiOnlyDecodeWorkPayload("another-app\n0\n1\n").isSome(), false)
    @Assert(uiOnlyDecodeWorkPayload("ui-only.note-counter.v1\n3\n17").isSome(), false)
    @Assert(uiOnlyDecodeWorkPayload("ui-only.note-counter.v1\n-1\n17\n00").isSome(), false)
    @Assert(uiOnlyDecodeWorkPayload("ui-only.note-counter.v1\n3\n0\n00").isSome(), false)
    @Assert(uiOnlyDecodeWorkPayload("ui-only.note-counter.v1\n3\n17\nFF").isSome(), false)
    @Assert(uiOnlyDecodeWorkPayload("ui-only.note-counter.v1\n3\n9223372036854775807\n-").isSome(), false)
    let note = StringBuilder()
    for (_ in 0..8193) { note.append("x") }
    @Assert(uiOnlyDecodeWorkPayload(UiOnlyWorkState(note.toString(), 0, 1).payload()).isSome(), false)
}
