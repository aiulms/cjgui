package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func textArgument(name: String, value: String): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.string(value))
}

private func integerArgument(name: String, value: Int64): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.integer(value))
}

private func textReplacementsArgument(name: String, value: String): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.textReplacements(value))
}

@Test
func documentWorkspaceKeepsRangeTruthSelectionAndStaleWritesOnTheirOriginalDocument(): Unit {
    let description = CjguiTextDocument(7101, "说明", "甲\n乙🙂")
    let notes = CjguiTextDocument(7102, "笔记", "保留段")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([description, notes]))

    let selected = workspace.setSelectionFromHuman(7101, CjguiTextDocumentRange(0, 7))
    @Assert(selected.isAvailable, true)
    @Assert(selected.documentId, 7101)
    @Assert(selected.documentVersion, 0)

    let nativeSelection = workspace.setSelectionFromNativeUtf16(7101, 3, 5)
    @Assert(nativeSelection.isAvailable, true)
    @Assert(nativeSelection.start, 7)
    @Assert(nativeSelection.end, 11)
    @Assert(workspace.setSelectionFromNativeUtf16(7101, 4, 5).reason, "invalid_text_boundary")
    let directSnapshot = workspace.documentSnapshot(7101)
    if (let Some(snapshot) <- directSnapshot) {
        @Assert(snapshot.content, "甲\n乙🙂")
        @Assert(snapshot.version, 0)
    } else {
        @Assert(true, false)
    }

    let range = workspace.readRangeFromExternal(7101, 0, 7, 0)
    @Assert(range.isAvailable, true)
    @Assert(range.content, "甲\n乙")
    let replace = workspace.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "REPLACE_RANGE",
            0,
            ArrayList<Int64>([7101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                integerArgument("start", 0), integerArgument("end", 7), textArgument("text", "首段")
            ])
        )
    )
    @Assert(replace.applied, true)
    @Assert(description.snapshot().content, "首段🙂")
    @Assert(workspace.selection().documentVersion, 1)
    @Assert(workspace.selection().end, 6)

    let stale = workspace.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "REPLACE_RANGE",
            0,
            ArrayList<Int64>([7101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                integerArgument("start", 0), integerArgument("end", 6), textArgument("text", "过期")
            ])
        )
    )
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(notes.snapshot().content, "保留段")

    @Assert(workspace.selectDocumentFromHuman(7102).applied, true)
    @Assert(workspace.closeDocumentFromHuman(7101).applied, true)
    let closed = workspace.executeFromExternal(
        CjguiSharedOperationActionInvocation(
            "REPLACE_RANGE",
            1,
            ArrayList<Int64>([7101]),
            ArrayList<CjguiSharedOperationActionArgument>([
                integerArgument("start", 0), integerArgument("end", 6), textArgument("text", "不应串文档")
            ])
        )
    )
    @Assert(closed.applied, false)
    @Assert(closed.reason, "document_closed")
    @Assert(notes.snapshot().content, "保留段")
}

@Test
func documentWorkspaceSharesHumanUndoRedoWithoutTurningSelectionIntoDocumentContent(): Unit {
    let description = CjguiTextDocument(7201, "说明", "第一行\n第二行")
    let notes = CjguiTextDocument(7202, "笔记", "原样")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([description, notes]))

    @Assert(workspace.replaceRangeFromHuman(7201, CjguiTextDocumentRange(0, 19), "首行").applied, true)
    @Assert(workspace.selection().documentId, 7201)
    @Assert(workspace.selection().end, 6)
    @Assert(workspace.undoDocumentFromHuman(7201).applied, true)
    @Assert(description.snapshot().content, "第一行\n第二行")
    @Assert(workspace.redoDocumentFromHuman(7201).applied, true)
    @Assert(description.snapshot().content, "首行")
    @Assert(notes.snapshot().content, "原样")

    let context = workspace.contextSnapshot()
    @Assert(context.resources.size, 2)
    for (resource in context.resources) {
        for (field in resource.fields) {
            @Assert(field.name == "content", false)
        }
    }
}

@Test
func documentWorkspaceAppliesNativeProjectionThroughOneClusterSafeUndoEntry(): Unit {
    let document = CjguiTextDocument(7211, "组合输入", "A🙂👩‍💻e\u{301}\n乙")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([document]))

    let committed = workspace.replaceProjectionTextFromHuman(7211, "A🌟e\u{301}\n乙")
    @Assert(committed.applied, true)
    @Assert(committed.versionBefore, 0)
    @Assert(committed.versionAfter, 1)
    @Assert(document.snapshot().content, "A🌟e\u{301}\n乙")
    @Assert(document.undoDepth(), 1)
    @Assert(workspace.undoDocumentFromHuman(7211).applied, true)
    @Assert(document.snapshot().content, "A🙂👩‍💻e\u{301}\n乙")

    let unchanged = workspace.replaceProjectionTextFromHuman(7211, "A🙂👩‍💻e\u{301}\n乙")
    @Assert(unchanged.applied, false)
    @Assert(unchanged.reason, "unchanged")
    @Assert(document.undoDepth(), 0)
}

@Test
func documentWorkspacePublishesAndAtomicallyExecutesMultiRangeReplacement(): Unit {
    let document = CjguiTextDocument(7301, "批量文档", "甲乙丙丁")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([document]))
    var hasBatchAction = false
    for (action in workspace.actionDescriptors()) {
        if (action.name == "REPLACE_RANGES" && action.parameters.size == 1 &&
            action.parameters[0].name == "replacements" && action.parameters[0].valueType == "TEXT_REPLACEMENTS") {
            hasBatchAction = true
        }
    }
    @Assert(hasBatchAction, true)

    let result = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "REPLACE_RANGES",
        0,
        ArrayList<Int64>([7301]),
        ArrayList<CjguiSharedOperationActionArgument>([
            textReplacementsArgument("replacements", "CJGUI_TEXT_REPLACEMENTS/1\n3 6 1 41\n9 12 6 E4B881E4B881")
        ])
    ))
    @Assert(result.applied, true)
    @Assert(result.versionBefore, 0)
    @Assert(result.versionAfter, 1)
    @Assert(document.snapshot().content, "甲A丙丁丁")
    @Assert(workspace.selection().start, 7)
    @Assert(workspace.selection().end, 13)
    @Assert(document.undoDepth(), 1)

    let deletion = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "REPLACE_RANGES",
        1,
        ArrayList<Int64>([7301]),
        ArrayList<CjguiSharedOperationActionArgument>([
            textReplacementsArgument("replacements", "CJGUI_TEXT_REPLACEMENTS/1\n3 4 0 -")
        ])
    ))
    @Assert(deletion.applied, true)
    @Assert(document.snapshot().content, "甲丙丁丁")
}

@Test
func documentWorkspaceTargetedContextReadsOnlyTheRequestedOpenDocument(): Unit {
    let first = CjguiTextDocument(401, "第一份", "一")
    let second = CjguiTextDocument(402, "第二份", "二")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([first, second]))
    let fullSnapshot = workspace.contextSnapshot()
    @Assert(fullSnapshot.streamIdentity.size > 0, true)
    let currentChanges = workspace.changesSince(
        fullSnapshot.version, ArrayList<Int64>([402]), fullSnapshot.streamIdentity
    )
    @Assert(currentChanges.streamIdentity, fullSnapshot.streamIdentity)

    if (let Some(snapshot) <- workspace.contextSnapshotForExternalTargets(ArrayList<Int64>([402]))) {
        @Assert(snapshot.resources.size, 1)
        @Assert(snapshot.resources[0].id, 402)
        @Assert(snapshot.resources[0].name, "第二份")
        @Assert(snapshot.version, fullSnapshot.version)
        @Assert(snapshot.streamIdentity, fullSnapshot.streamIdentity)
    } else {
        @Assert(false, true)
    }
    @Assert(workspace.closeDocumentFromHuman(402).applied, true)
    if (let Some(_) <- workspace.contextSnapshotForExternalTargets(ArrayList<Int64>([402]))) {
        @Assert(false, true)
    }
}

@Test
func previewLimitUsesTheWorkspaceOwnerCasWithoutEditingDocumentContent(): Unit {
    let document = CjguiTextDocument(7401, "预览", "内容保持不变")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([document]))
    let before = workspace.contextSnapshot().version
    @Assert(workspace.previewLimitVersionForDocument(7401), 0)
    let applied = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_PREVIEW_LIMIT", before, ArrayList<Int64>([7401]),
        ArrayList<CjguiSharedOperationActionArgument>([
            integerArgument("value", 256)
        ])
    ))
    @Assert(applied.applied, true)
    @Assert(applied.versionBefore, before)
    @Assert(applied.versionAfter, before + 1)
    @Assert(workspace.previewLimitVersionForDocument(7401), 1)
    @Assert(document.snapshot().content, "内容保持不变")

    let stale = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_PREVIEW_LIMIT", before, ArrayList<Int64>([7401]),
        ArrayList<CjguiSharedOperationActionArgument>([
            integerArgument("value", 128)
        ])
    ))
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(workspace.previewLimitVersionForDocument(7401), 1)

    var hasPublishedValue = false
    for (resource in workspace.contextSnapshot().resources) {
        if (resource.id == 7401) {
            for (field in resource.fields) {
                if (field.name == "previewLimit" && field.value.integerValue == 256) {
                    hasPublishedValue = true
                }
            }
        }
    }
    @Assert(hasPublishedValue, true)
}
