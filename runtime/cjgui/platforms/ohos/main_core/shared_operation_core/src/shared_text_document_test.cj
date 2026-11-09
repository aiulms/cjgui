package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class RangeReadProbeDomain <: CjguiSharedOperationDomain & CjguiSharedOperationRangeReadDomain {
    public func resourceType(): String { return "range_probe" }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(
            4,
            "范围读取探针",
            resourceType(),
            ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(7101, "说明", ArrayList<CjguiSharedOperationField>([
                    CjguiSharedOperationField("documentVersion", CjguiSharedOperationValue.integer(4))
                ]))
            ])
        )
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>()
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 4, 4, "not_supported")
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 4, 4, "not_supported")
    }

    public func readRangeFromExternal(
        resourceId: Int64,
        start: Int64,
        end: Int64,
        expectedVersion: Int64
    ): CjguiSharedOperationRangeRead {
        if (resourceId != 7101) {
            return CjguiSharedOperationRangeRead(false, false, 7101, 4, 0, 0, "", "unknown_resource")
        }
        if (expectedVersion != 4) {
            return CjguiSharedOperationRangeRead(false, true, 7101, 4, 0, 0, "", "version_conflict")
        }
        if (start != 3 || end != 9) {
            return CjguiSharedOperationRangeRead(false, false, 7101, 4, 0, 0, "", "invalid_range")
        }
        return CjguiSharedOperationRangeRead(true, false, 7101, 4, 3, 9, "甲乙", "available")
    }
}

@Test
func transportDiscoversAndReturnsAuthorizedBoundedDocumentRange(): Unit {
    let domain = RangeReadProbeDomain()
    let authorization = CjguiSharedOperationExternalAuthorization(
        "范围读取者",
        "range-read-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([7101]), false),
            CjguiSharedOperationExternalActionScope("READ_RANGE", ArrayList<Int64>([7101]), false)
        ])
    )
    let connection = CjguiSharedOperationExternalConnection(domain, authorization)
    @Assert(connection.enableRangeReads(domain), true)

    let descriptor = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH range-read-capability\nGET_CONTEXT 1\nID 7101"
    )
    @Assert(descriptor.contains("ACTION READ_RANGE PARAMETERS 3 TARGETS 1 1"), true)

    let response = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH range-read-capability\nREAD_RANGE 7101 3 9 4"
    )
    @Assert(response.contains("KIND RANGE"), true)
    @Assert(response.contains("AVAILABLE true"), true)
    @Assert(response.contains("CONTENT_UTF8_HEX 6 E794B2E4B999"), true)

    let stale = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH range-read-capability\nREAD_RANGE 7101 3 9 3"
    )
    @Assert(stale.contains("CONFLICT true"), true)
    let hidden = connection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH range-read-capability\nREAD_RANGE 7102 3 9 4"
    )
    @Assert(hidden.contains("ERROR unauthorized_resource"), true)
}

@Test
func textDocumentRejectsUnicodeInteriorOffsetsAndStaleExternalEdits(): Unit {
    let document = CjguiTextDocument(7101, "说明", "开始🙂\n第二行 e\u{301}", historyLimit: 2)
    let initial = document.snapshot()

    @Assert(initial.positionUnit, "UTF8_BYTE")
    let splitEmoji = document.replaceRangeFromExternal(CjguiTextDocumentRange(7, 10), "X", initial.version)
    @Assert(splitEmoji.applied, false)
    @Assert(splitEmoji.reason, "invalid_text_boundary")
    @Assert(document.snapshot().content, "开始🙂\n第二行 e\u{301}")

    let replaced = document.replaceRangeFromExternal(CjguiTextDocumentRange(6, 10), "🌟", initial.version)
    @Assert(replaced.applied, true)
    @Assert(replaced.versionAfter, initial.version + 1)
    @Assert(document.snapshot().content, "开始🌟\n第二行 e\u{301}")

    let stale = document.insertFromExternal(0, "过期：", initial.version)
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(document.snapshot().content, "开始🌟\n第二行 e\u{301}")
}

@Test
func textDocumentConvertsNativeUtf16SelectionsWithoutSplittingClusters(): Unit {
    let document = CjguiTextDocument(7103, "UTF16", "甲🙂\n乙e\u{301}")
    if (let Some(range) <- document.rangeFromUtf16(1, 3)) {
        @Assert(range.start, 3)
        @Assert(range.end, 7)
    } else {
        @Assert(false, true)
    }
    if (let Some(_) <- document.rangeFromUtf16(2, 3)) { @Assert(false, true) }
    if (let Some(_) <- document.rangeFromUtf16(6, 7)) { @Assert(false, true) }
}

@Test
func textDocumentKeepsCrlfAndRegionalIndicatorPairBoundaries(): Unit {
    // UAX #29 keeps CRLF together and groups regional indicators in pairs.
    // The UTF-16 range after the first flag is therefore valid; a range
    // beginning between CR and LF is not.
    let document = CjguiTextDocument(7106, "换行与旗帜", "A\r\nB🇦🇧🇨e\u{301}")
    if (let Some(range) <- document.rangeFromUtf16(8, 10)) {
        @Assert(range.start, 12)
        @Assert(range.end, 16)
    } else {
        @Assert(false, true)
    }
    if (let Some(_) <- document.rangeFromUtf16(2, 3)) { @Assert(false, true) }
}

@Test
func textDocumentKeepsBoundedUndoRedoWithoutCopyingDocumentTruth(): Unit {
    let document = CjguiTextDocument(7102, "第二篇", "甲", historyLimit: 2)
    let first = document.insertFromHuman(3, "乙")
    let second = document.insertFromHuman(6, "丙")
    let third = document.insertFromHuman(9, "丁")

    @Assert(first.applied, true)
    @Assert(second.applied, true)
    @Assert(third.applied, true)
    @Assert(document.snapshot().content, "甲乙丙丁")
    @Assert(document.undoDepth(), 2)

    let undo = document.undoFromHuman()
    @Assert(undo.applied, true)
    @Assert(document.snapshot().content, "甲乙丙")
    let redo = document.redoFromHuman()
    @Assert(redo.applied, true)
    @Assert(document.snapshot().content, "甲乙丙丁")
}

@Test
func textDocumentAtomicallyAppliesOriginalVersionMultiRangeReplacementAsOneUndo(): Unit {
    let document = CjguiTextDocument(7104, "多段替换", "甲乙丙丁")
    let original = document.snapshot()
    let result = document.replaceRangesFromExternal(ArrayList<CjguiTextDocumentReplacement>([
        CjguiTextDocumentReplacement(CjguiTextDocumentRange(3, 6), "A"),
        CjguiTextDocumentReplacement(CjguiTextDocumentRange(9, 12), "丁丁")
    ]), original.version)

    @Assert(result.applied, true)
    @Assert(result.versionBefore, 0)
    @Assert(result.versionAfter, 1)
    @Assert(result.ranges.size, 2)
    @Assert(result.ranges[0].start, 3)
    @Assert(result.ranges[0].end, 4)
    @Assert(result.ranges[1].start, 7)
    @Assert(result.ranges[1].end, 13)
    @Assert(document.snapshot().content, "甲A丙丁丁")
    @Assert(document.undoDepth(), 1)

    let undo = document.undoFromHuman()
    @Assert(undo.applied, true)
    @Assert(document.snapshot().content, "甲乙丙丁")
    @Assert(document.undoDepth(), 0)
    @Assert(document.redoDepth(), 1)
    let redo = document.redoFromHuman()
    @Assert(redo.applied, true)
    @Assert(document.snapshot().content, "甲A丙丁丁")

    let overlapping = document.replaceRangesFromExternal(ArrayList<CjguiTextDocumentReplacement>([
        CjguiTextDocumentReplacement(CjguiTextDocumentRange(0, 3), "X"),
        CjguiTextDocumentReplacement(CjguiTextDocumentRange(0, 3), "Y")
    ]), document.version())
    @Assert(overlapping.applied, false)
    @Assert(overlapping.reason, "overlapping_text_ranges")
    @Assert(document.snapshot().content, "甲A丙丁丁")
}

@Test
func textDocumentAppliesNativeProjectionAsOneClusterSafeHumanUndo(): Unit {
    let document = CjguiTextDocument(7105, "组合输入", "A🙂👩‍💻e\u{301}\n乙")
    let committed = document.replaceProjectionTextFromHuman("A🌟e\u{301}\n乙")

    @Assert(committed.applied, true)
    @Assert(committed.versionBefore, 0)
    @Assert(committed.versionAfter, 1)
    @Assert(document.snapshot().content, "A🌟e\u{301}\n乙")
    @Assert(document.undoDepth(), 1)

    let undo = document.undoFromHuman()
    @Assert(undo.applied, true)
    @Assert(document.snapshot().content, "A🙂👩‍💻e\u{301}\n乙")

    let unchanged = document.replaceProjectionTextFromHuman("A🙂👩‍💻e\u{301}\n乙")
    @Assert(unchanged.applied, false)
    @Assert(unchanged.reason, "unchanged")
    @Assert(document.undoDepth(), 0)
}
