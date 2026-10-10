package cjgui

private func ownerContinuationTestNode(fieldId!: String = "name", action!: String = "EDIT_NAME",
    operationResourceId!: Int64 = 9700, value!: String = "owner", enabled!: Bool = true): CjguiComposableUiLayoutNode {
    let declaration = cjguiComposableTextInput(51, "generated-name", "Name", value, 9700, CjguiComposableUiStyle(),
        enabled: enabled, fieldId: fieldId, operationActionName: action,
        operationResourceId: operationResourceId)
    let bounds = CjguiComposableUiRect(0, 0, 180, 24)
    return CjguiComposableUiLayoutNode(declaration, bounds, bounds, inputScopeId: "panel")
}

@Test
func generatedReorderRetainsFocusedTextOnlyForStableOwnerAndCompleteBinding(): Unit {
    let accepted = ownerContinuationTestNode()
    let reordered = ownerContinuationTestNode()
    @Assert(cjguiPreservesOwnerStableText(accepted, reordered, 8, 8, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), true)
    // A same-value external owner replacement is still a new authority version.
    @Assert(cjguiPreservesOwnerStableText(accepted, reordered, 8, 9, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, reordered, -1, -1, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, reordered, 8, 8, -1, -1, -1), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, ownerContinuationTestNode(fieldId: "other"), 8, 8,
        51, 9700, CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, ownerContinuationTestNode(action: "OTHER"), 8, 8,
        51, 9700, CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, ownerContinuationTestNode(operationResourceId: 9701), 8, 8,
        51, 9700, CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, ownerContinuationTestNode(value: "external"), 8, 8,
        51, 9700, CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiPreservesOwnerStableText(accepted, ownerContinuationTestNode(enabled: false), 8, 8,
        51, 9700, CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    // Equal pixels cannot take the semantic-only branch after an external
    // same-value owner write while this editor remains focused.
    @Assert(cjguiOwnerRevisionRequiresNativeTextReconcile(8, 9, accepted, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), true)
    @Assert(cjguiOwnerRevisionRequiresNativeTextReconcile(8, 8, accepted, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
    @Assert(cjguiOwnerRevisionRequiresNativeTextReconcile(8, 9, accepted, -1, -1, -1), false)
    @Assert(cjguiOwnerRevisionRequiresNativeTextReconcile(-1, 9, accepted, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), true)
    @Assert(cjguiFocusedTextBindingRequiresNativeReconcile(accepted,
        ownerContinuationTestNode(fieldId: "other"), 51, 9700, CJGUI_COMPOSABLE_UI_TEXT_INPUT), true)
    @Assert(cjguiFocusedTextBindingRequiresNativeReconcile(accepted, reordered, 51, 9700,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT), false)
}

@Test
func localTextFastPathDoesNotBorrowLaterExternalOwnerRevision(): Unit {
    @Assert(cjguiLocalTextOwnerRevisionMatches(false, -1, -1), true)
    @Assert(cjguiLocalTextOwnerRevisionMatches(true, 9, 9), true)
    @Assert(cjguiLocalTextOwnerRevisionMatches(true, 9, 10), false)
    @Assert(cjguiLocalTextOwnerRevisionMatches(true, -1, 10), false)
}

@Test
func historyPresenterRemapKeepsOnlyItsFrozenSourceChoiceAndInputSequence(): Unit {
    let semantic = CjguiTextSelectionTicket(3, 9, 7, 7, 34)
    let original = CjguiPendingSelectionRestore(6, 19u64, semantic, 107, 1,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "bounded", 0, 7, 0, 7, false, { => },
        frozenSourceChoice: Some(CjguiSourceSelectionSnapshot(7, 34, 0, 5185,
            documentId: "history-owner", sessionEpoch: 2, viewGeneration: 1)), caretInputSequence: 5u64)
    // The accepted presenter is bounded; its seven local UTF-16 units cannot
    // replace the frozen 5,185 source-byte choice or authorize a successor.
    @Assert(original.matchesCaretSourceRemap(semantic, 19u64, 5u64, 0, 5185), true)
    @Assert(original.matchesCaretSourceRemap(semantic, 19u64, 6u64, 0, 5185), false)
    @Assert(original.matchesCaretSourceRemap(semantic, 20u64, 5u64, 0, 5185), false)
    @Assert(original.matchesCaretSourceRemap(semantic, 19u64, 5u64, 0, 7), false)
    @Assert(original.matchesCaretSourceRemap(semantic, 19u64, 5u64, 5185, 0), false)
    @Assert(original.matchesCaretSourceRemap(CjguiTextSelectionTicket(3, 9, 7, 7, 35),
        19u64, 5u64, 0, 5185), false)
    @Assert(original.matchesCaretSourceRemap(CjguiTextSelectionTicket(4, 9, 7, 7, 34),
        19u64, 5u64, 0, 5185), false)
    @Assert(original.matchesCaretSourceRemap(CjguiTextSelectionTicket(3, 10, 7, 7, 34),
        19u64, 5u64, 0, 5185), false)
    @Assert(original.matchesCaretSourceRemap(CjguiTextSelectionTicket(3, 9, 8, 8, 34),
        19u64, 5u64, 0, 5185), false)
}

@Test
func historyPresenterRemapCannotInventMissingFrozenChoice(): Unit {
    let semantic = CjguiTextSelectionTicket(3, 9, 7, 7, 34)
    let missing = CjguiPendingSelectionRestore(6, 19u64, semantic, 107, 1,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "bounded", 0, 7, 0, 7, false, { => },
        caretInputSequence: 5u64)
    @Assert(missing.matchesCaretSourceRemap(semantic, 19u64, 5u64, 0, 5185), false)
}
