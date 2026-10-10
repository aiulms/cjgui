package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private func candidateSelectionFixture(mapping: String, focus!: Int64 = 8,
    target!: Int64 = 107): ?CjguiCandidateSelectionDeclaration {
    let source = CjguiSourceSelectionSnapshot(1, 9, 4, focus,
        documentId: "candidate-owner", sessionEpoch: 2, viewGeneration: 3)
    let semantic = CjguiTextSelectionTicket(2, 3, 1, 1, 9)
    return Some(CjguiCandidateSelectionDeclaration(Some(CjguiComposableUiCandidateSelectionProjection(
        None, source, semantic, mapping, target, 1, CJGUI_COMPOSABLE_UI_TEXT, "abcdefghijkl",
        4, 8, 8))))
}

@Test
func candidateSelectionRequiresNativePublicationForSamePixelsAtNewSourceOrigin(): Unit {
    let accepted = candidateSelectionFixture("owner:1:source=0")
    @Assert(cjguiSameCandidateSelection(accepted, candidateSelectionFixture("owner:1:source=0")), true)
    @Assert(cjguiSameCandidateSelection(accepted, candidateSelectionFixture("owner:1:source=64")), false)
    @Assert(cjguiSameCandidateSelection(accepted, candidateSelectionFixture("owner:1:source=0", focus: 7)), false)
    @Assert(cjguiSameCandidateSelection(accepted, candidateSelectionFixture("owner:1:source=0", target: 1013)), false)
}

@Test
func candidateSelectionExplicitAbsenceIsDifferentFromLegacyAndPreviouslyVisibleCaret(): Unit {
    let absent: ?CjguiCandidateSelectionDeclaration = Some(CjguiCandidateSelectionDeclaration(None))
    @Assert(cjguiSameCandidateSelection(None, absent), false)
    @Assert(cjguiSameCandidateSelection(absent, absent), true)
    @Assert(cjguiSameCandidateSelection(candidateSelectionFixture("owner:1:source=0"), absent), false)
}
