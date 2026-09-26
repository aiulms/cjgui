package cjgui_shared_operation_core

import std.unittest.*
import std.unittest.testmacro.*

@Test
func transferContractWillBoundTextAndStructuredOffers(): Unit {
    // `String.size` is UTF-8 bytes: 仓(3) + 颉(3) + 🙂(4) == 10.
    let text = CjguiSharedOperationTransferFormat.utf8Text(maximumBytes: 10)
    let valid = CjguiSharedOperationTransferOffer.create(
        "COPY", "text_input", "text-window-a", 7, text, "仓颉🙂")
    @Assert(valid.isSome(), true)

    let oversized = CjguiSharedOperationTransferOffer.create(
        "COPY", "text_input", "text-window-a", 7, text, "仓颉🙂扩展")
    @Assert(oversized.isNone(), true)

    let structured = CjguiSharedOperationTransferFormat.structured(
        "cjgui.rule.record", version: 1, maximumBytes: 256)
    let structuredOffer = CjguiSharedOperationTransferOffer.create(
        "COPY", "rule_record", "rule-window-a", 101, structured,
        "CJGUI_RULE_RECORD/1\nlabel 4 规则甲")
    @Assert(structuredOffer.isSome(), true)
}

@Test
func transferContractWillRejectWrongFormatTargetAndOperation(): Unit {
    let text = CjguiSharedOperationTransferFormat.utf8Text(maximumBytes: 32)
    let offer = CjguiSharedOperationTransferOffer.create(
        "COPY", "text_input", "text-window-a", 7, text, "可粘贴")
    if (let Some(validOffer) <- offer) {
        let accepted = CjguiSharedOperationTransferAcceptRequest.create(
            "text_document", "workspace-a", 7101, validOffer, text, 0)
        @Assert(accepted.isSome(), true)

        let structured = CjguiSharedOperationTransferFormat.structured(
            "cjgui.rule.record", version: 1, maximumBytes: 256)
        let wrongFormat = CjguiSharedOperationTransferAcceptRequest.create(
            "text_document", "workspace-a", 7101, validOffer, structured, 0)
        @Assert(wrongFormat.isNone(), true)
    } else {
        @Assert(false, true)
    }

    let invalidOperation = CjguiSharedOperationTransferOffer.create(
        "MOVE", "text_input", "text-window-a", 7, text, "不可移动")
    @Assert(invalidOperation.isNone(), true)
}

@Test
func transferResultWillPreserveExistingActionCasOutcome(): Unit {
    let format = CjguiSharedOperationTransferFormat.utf8Text(maximumBytes: 64)
    let offer = CjguiSharedOperationTransferOffer.create(
        "COPY", "text_input", "text-window-a", 7, format, "新文本")
    if (let Some(validOffer) <- offer) {
        let applied = CjguiSharedOperationTransferResult.fromActionResult(
            CjguiSharedOperationActionResult(true, false, 2, 3, "applied"), validOffer)
        @Assert(applied.applied, true)
        @Assert(applied.versionBefore, 2)
        @Assert(applied.versionAfter, 3)
        @Assert(applied.formatIdentifier, format.identifier)

        let conflict = CjguiSharedOperationTransferResult.fromActionResult(
            CjguiSharedOperationActionResult(false, true, 3, 3, "version_conflict"), validOffer)
        @Assert(conflict.applied, false)
        @Assert(conflict.isVersionConflict, true)
        @Assert(conflict.reason, "version_conflict")
    } else {
        @Assert(false, true)
    }
}
