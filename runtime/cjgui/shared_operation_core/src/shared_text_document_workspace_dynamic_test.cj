package cjgui_shared_operation_core

import std.collection.*
import std.env.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private func dynamicTextArgument(name: String, value: String): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.string(value))
}

private func dynamicIntegerArgument(name: String, value: Int64): CjguiSharedOperationActionArgument {
    return CjguiSharedOperationActionArgument(name, CjguiSharedOperationValue.integer(value))
}

private func dynamicReplace(workspace: CjguiTextDocumentWorkspace, documentId: Int64,
    expectedVersion: Int64, text: String): CjguiSharedOperationActionResult {
    return workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "REPLACE_RANGE", expectedVersion, ArrayList<Int64>([documentId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            dynamicIntegerArgument("start", 0), dynamicIntegerArgument("end", 0),
            dynamicTextArgument("text", text)
        ])
    ))
}

@Test
func dynamicWorkspaceReopeningTheSameVersionStillRejectsTheOldTarget(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("same-version.txt").toString()
    File.writeTo(path, "A0".toArray())
    let sibling = CjguiTextDocument(5102, "B", "B0")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([sibling]))

    let opened = workspace.openDocumentFromFileFromHuman("A", CjguiTextDocumentFileBinding(), path)
    @Assert(opened.applied, true)
    let firstId = opened.resourceId
    @Assert(firstId != 5102, true)
    @Assert(workspace.closeDocumentFromHuman(firstId).applied, true)

    let reopened = workspace.openDocumentFromFileFromHuman("A", CjguiTextDocumentFileBinding(), path)
    @Assert(reopened.applied, true)
    @Assert(reopened.resourceId != firstId, true)
    let secondId = reopened.resourceId

    // The file and the new document are both at version zero. The old target
    // is rejected because its instance was retired, not because a version
    // happened to differ.
    let stale = dynamicReplace(workspace, firstId, 0, "STALE")
    @Assert(stale.applied, false)
    @Assert(stale.reason, "document_closed")
    if (let Some(snapshot) <- workspace.documentSnapshot(secondId)) {
        @Assert(snapshot.content, "A0")
        @Assert(snapshot.version, 0)
    } else {
        @Assert(true, false)
    }
    @Assert(sibling.snapshot().content, "B0")
    @Assert(sibling.version(), 0)

    let accepted = dynamicReplace(workspace, secondId, 0, "NEW-")
    @Assert(accepted.applied, true)
    if (let Some(snapshot) <- workspace.documentSnapshot(secondId)) {
        @Assert(snapshot.content, "NEW-A0")
        @Assert(snapshot.version, 1)
    } else {
        @Assert(true, false)
    }
    @Assert(sibling.snapshot().content, "B0")
    @Assert(sibling.version(), 0)
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func dynamicWorkspaceNeverReusesARetiredIdOrAllocatesItAgain(): Unit {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(5201, "A", "A"), CjguiTextDocument(5202, "B", "B")
    ]))
    let opened = workspace.openDocumentFromHuman("C", "C")
    @Assert(opened.applied, true)
    let retiredId = opened.resourceId
    @Assert(workspace.closeDocumentFromHuman(retiredId).applied, true)

    let rebound = workspace.registerDocumentFromHuman(CjguiTextDocument(retiredId, "rebound", "X"))
    @Assert(rebound.applied, false)
    @Assert(rebound.reason, "retired_document_id")
    @Assert(workspace.documentLiveness(retiredId), "document_closed")

    let next = workspace.openDocumentFromHuman("D", "D")
    @Assert(next.applied, true)
    @Assert(next.resourceId != retiredId, true)
    @Assert(next.resourceId > retiredId, true)
    @Assert(workspace.documentLiveness(next.resourceId), "open")
    @Assert(workspace.documentLiveness(999999), "unknown_document")
}

@Test
func dynamicWorkspaceClosePreservesTheSiblingBodyVersionAndTarget(): Unit {
    let first = CjguiTextDocument(5301, "A", "A0")
    let second = CjguiTextDocument(5302, "B", "B0")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([first, second]))
    let bTarget = workspace.setSelectionFromHuman(5302, CjguiTextDocumentRange(0, 0))
    @Assert(bTarget.isAvailable, true)
    @Assert(dynamicReplace(workspace, 5302, 0, "B1").applied, true)
    @Assert(dynamicReplace(workspace, 5302, 1, "B2").applied, true)
    @Assert(second.version(), 2)

    @Assert(workspace.closeDocumentFromHuman(5301).applied, true)
    let bRead = workspace.readRangeFromExternal(5302, 0, 6, 2)
    @Assert(bRead.isAvailable, true)
    @Assert(bRead.content, "B2B1B0")
    @Assert(workspace.selection().documentId, 5302)
    @Assert(workspace.selection().documentVersion, 2)
    @Assert(second.snapshot().content, "B2B1B0")

    let staleA = dynamicReplace(workspace, 5301, 0, "STALE")
    @Assert(staleA.applied, false)
    @Assert(staleA.reason, "document_closed")
}

@Test
func dynamicWorkspaceFailedOpenAndSaveHaveNoDocumentSideEffects(): Unit {
    let directory = Directory.createTemp("/tmp")
    let missingPath = directory.join("missing.txt").toString()
    let first = CjguiTextDocument(5401, "A", "A0")
    let second = CjguiTextDocument(5402, "B", "B0")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([first, second]))
    let versionBefore = workspace.contextSnapshot().version
    let selectionBefore = workspace.selection()

    let failedOpen = workspace.openDocumentFromFileFromHuman("missing", CjguiTextDocumentFileBinding(), missingPath)
    @Assert(failedOpen.applied, false)
    @Assert(failedOpen.reason, "file_read_failed")
    @Assert(workspace.contextSnapshot().version, versionBefore)
    @Assert(workspace.openDocumentCount(), 2)
    @Assert(workspace.selection().documentId, selectionBefore.documentId)
    @Assert(workspace.selection().documentVersion, selectionBefore.documentVersion)

    let path = directory.join("conflict.txt").toString()
    File.writeTo(path, "baseline".toArray())
    let binding = CjguiTextDocumentFileBinding()
    let opened = workspace.openDocumentFromFileFromHuman("conflict", binding, path)
    @Assert(opened.applied, true)
    let documentId = opened.resourceId
    File.writeTo(path, "external".toArray())
    let snapshot = match (workspace.documentSnapshot(documentId)) {
        case Some(value) => value
        case None => CjguiTextDocumentSnapshot(documentId, "", "", -1)
    }
    let refused = binding.saveFromHuman(snapshot, path)
    @Assert(refused.applied, false)
    @Assert(refused.reason, "external_file_conflict")
    @Assert(workspace.documentLiveness(documentId), "open")
    if (let Some(current) <- workspace.documentSnapshot(documentId)) {
        @Assert(current.content, "baseline")
        @Assert(current.version, 0)
    } else {
        @Assert(true, false)
    }
    @Assert(binding.persistedState(snapshot, path), "clean")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func dynamicWorkspaceStaleInputCannotReachAReopenedDocument(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("input.txt").toString()
    File.writeTo(path, "original".toArray())
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(5501, "B", "B0")
    ]))
    let opened = workspace.openDocumentFromFileFromHuman("A", CjguiTextDocumentFileBinding(), path)
    @Assert(opened.applied, true)
    let firstId = opened.resourceId
    @Assert(workspace.replaceProjectionTextFromHuman(firstId, "edited").applied, true)
    @Assert(workspace.closeDocumentFromHuman(firstId).applied, true)

    let reopened = workspace.openDocumentFromFileFromHuman("A", CjguiTextDocumentFileBinding(), path)
    @Assert(reopened.applied, true)
    let secondId = reopened.resourceId
    @Assert(secondId != firstId, true)
    let staleInput = workspace.replaceProjectionTextFromHuman(firstId, "stale completion")
    @Assert(staleInput.applied, false)
    @Assert(staleInput.reason, "document_closed")
    if (let Some(snapshot) <- workspace.documentSnapshot(secondId)) {
        @Assert(snapshot.content, "original")
        @Assert(snapshot.version, 0)
    } else {
        @Assert(true, false)
    }
    @Assert(workspace.replaceProjectionTextFromHuman(secondId, "fresh").applied, true)
    if (let Some(snapshot) <- workspace.documentSnapshot(secondId)) {
        @Assert(snapshot.content, "fresh")
        @Assert(snapshot.version, 1)
    } else {
        @Assert(true, false)
    }
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func dynamicWorkspaceClosingEveryDocumentLeavesALegalEmptyState(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("a.txt").toString()
    File.writeTo(path, "A".toArray())
    let binding = CjguiTextDocumentFileBinding()
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(5601, "B", "B0")
    ]))
    let opened = workspace.openDocumentFromFileFromHuman("A", binding, path)
    @Assert(opened.applied, true)
    let firstId = opened.resourceId
    @Assert(workspace.closeDocumentFromHuman(firstId).applied, true)
    @Assert(workspace.closeDocumentFromHuman(5601).applied, true)
    @Assert(workspace.openDocumentCount(), 0)
    @Assert(workspace.openDocumentSummaries().size, 0)
    @Assert(workspace.selection().isAvailable, false)
    @Assert(workspace.selection().reason, "no_open_document")
    @Assert(workspace.contextSnapshot().resources.size, 0)
    var leakedBinding = false
    if (let Some(_) <- workspace.fileBindingForDocument(firstId)) { leakedBinding = true }
    @Assert(leakedBinding, false)
    @Assert(workspace.filePathForDocument(firstId), "")

    let fresh = workspace.openDocumentFromHuman("fresh", "hello")
    @Assert(fresh.applied, true)
    @Assert(workspace.openDocumentCount(), 1)
    @Assert(workspace.selection().isAvailable, true)
    @Assert(workspace.replaceProjectionTextFromHuman(fresh.resourceId, "hello!").applied, true)
    if (let Some(snapshot) <- workspace.documentSnapshot(fresh.resourceId)) {
        @Assert(snapshot.content, "hello!")
        @Assert(snapshot.version, 1)
    } else {
        @Assert(true, false)
    }
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func dynamicWorkspaceRejectsAllocationPastTheInt64Boundary(): Unit {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(Int64.Max, "last", "x")
    ]))
    let exhausted = workspace.openDocumentFromHuman("new", "y")
    @Assert(exhausted.applied, false)
    @Assert(exhausted.reason, "document_id_exhausted")
    @Assert(workspace.openDocumentCount(), 1)
}

@Test
func dynamicWorkspaceDuplicateRegistrationIsRejectedWithoutChangingTruth(): Unit {
    let first = CjguiTextDocument(5701, "A", "A")
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([first]))
    let before = workspace.contextSnapshot().version
    let duplicate = workspace.registerDocumentFromHuman(CjguiTextDocument(5701, "again", "B"))
    @Assert(duplicate.applied, false)
    @Assert(duplicate.reason, "duplicate_document_id")
    @Assert(workspace.contextSnapshot().version, before)
    @Assert(workspace.openDocumentCount(), 1)
    @Assert(first.snapshot().content, "A")
}

@Test
func dynamicWorkspaceRejectsReusingOneBindingForAnotherLiveDocument(): Unit {
    let directory = Directory.createTemp("/tmp")
    let aPath = directory.join("binding-a.txt").toString()
    let bPath = directory.join("binding-b.txt").toString()
    File.writeTo(aPath, "A-content".toArray())
    File.writeTo(bPath, "B-content".toArray())
    let binding = CjguiTextDocumentFileBinding()
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(5802, "sibling", "S0")
    ]))
    let a = workspace.openDocumentFromFileFromHuman("A", binding, aPath)
    @Assert(a.applied, true)
    let b = workspace.openDocumentFromFileFromHuman("B", binding, bPath)
    @Assert(b.applied, false)
    @Assert(b.reason, "binding_in_use")
    @Assert(workspace.filePathForDocument(a.resourceId), aPath)
    if (let Some(snapshot) <- workspace.documentSnapshot(a.resourceId)) {
        @Assert(snapshot.content, "A-content")
    } else {
        @Assert(true, false)
    }
    let savedA = binding.saveFromHuman(workspace.documentSnapshot(a.resourceId).getOrThrow(), aPath)
    @Assert(savedA.applied, true)
    @Assert(String.fromUtf8(File.readFrom(aPath)), "A-content")

    // Retirement releases the binding. Reuse then starts from the new file,
    // without changing the retired document's file on disk.
    @Assert(workspace.closeDocumentFromHuman(a.resourceId).applied, true)
    let reused = workspace.openDocumentFromFileFromHuman("B", binding, bPath)
    @Assert(reused.applied, true)
    @Assert(workspace.filePathForDocument(reused.resourceId), bPath)
    if (let Some(snapshot) <- workspace.documentSnapshot(reused.resourceId)) {
        @Assert(snapshot.content, "B-content")
    } else {
        @Assert(true, false)
    }
    @Assert(String.fromUtf8(File.readFrom(aPath)), "A-content")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func dynamicWorkspaceRejectsAttachingOneBindingToTwoLiveDocuments(): Unit {
    let directory = Directory.createTemp("/tmp")
    let aPath = directory.join("attach-a.txt").toString()
    let bPath = directory.join("attach-b.txt").toString()
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(5811, "A", "A"), CjguiTextDocument(5812, "B", "B")
    ]))
    let binding = CjguiTextDocumentFileBinding()
    @Assert(workspace.attachFileBindingFromHuman(5811, binding, aPath).applied, true)
    let second = workspace.attachFileBindingFromHuman(5812, binding, bPath)
    @Assert(second.applied, false)
    @Assert(second.reason, "binding_in_use")
    @Assert(workspace.filePathForDocument(5811), aPath)
    @Assert(workspace.filePathForDocument(5812), "")
    if (let Some(_) <- workspace.fileBindingForDocument(5812)) {
        @Assert(true, false)
    }
    let savedA = binding.saveFromHuman(workspace.documentSnapshot(5811).getOrThrow(), aPath)
    @Assert(savedA.applied, true)
    @Assert(String.fromUtf8(File.readFrom(aPath)), "A")

    // The retired owner releases its binding; B can attach and save then.
    @Assert(workspace.closeDocumentFromHuman(5811).applied, true)
    @Assert(workspace.attachFileBindingFromHuman(5812, binding, bPath).applied, true)
    if (let Some(_) <- workspace.fileBindingForDocument(5812)) {
        @Assert(true, true)
    } else {
        @Assert(true, false)
    }
    let savedB = binding.saveFromHuman(workspace.documentSnapshot(5812).getOrThrow(), bPath)
    @Assert(savedB.applied, true)
    @Assert(String.fromUtf8(File.readFrom(bPath)), "B")
    @Assert(String.fromUtf8(File.readFrom(aPath)), "A")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func dynamicWorkspaceRejectsReplacingLiveBindingBeforeClaimAndReleasesOriginalOnClose(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let aPath = directory.join("original-a.txt").toString()
        let rejectedPath = directory.join("unadopted-y.txt").toString()
        let bPath = directory.join("reused-x-b.txt").toString()
        File.writeTo(rejectedPath, "Y-sentinel".toArray())
        let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
            CjguiTextDocument(5821, "A", "A0"), CjguiTextDocument(5822, "B", "B0")
        ]))
        let original = CjguiTextDocumentFileBinding()
        let replacement = CjguiTextDocumentFileBinding()
        @Assert(workspace.attachFileBindingFromHuman(5821, original, aPath).applied, true)
        @Assert(original.saveFromHuman(workspace.documentSnapshot(5821).getOrThrow(), aPath).applied, true)
        @Assert(original.persistedState(workspace.documentSnapshot(5821).getOrThrow(), aPath), "clean")
        // Repeating the same object remains legal after it has a real baseline.
        @Assert(workspace.attachFileBindingFromHuman(5821, original, aPath).applied, true)
        @Assert(original.persistedState(workspace.documentSnapshot(5821).getOrThrow(), aPath), "clean")
        let contextBefore = workspace.contextSnapshot().version

        let refused = workspace.attachFileBindingFromHuman(5821, replacement, rejectedPath)
        let originalStillMapped = refEq(workspace.fileBindingForDocument(5821).getOrThrow(), original)
        let pathAfterRefusal = workspace.filePathForDocument(5821)
        let contextAfterRefusal = workspace.contextSnapshot().version
        let replacementClaimAfterRefusal = replacement.claimedDocumentId()
        let replacementBoundAfterRefusal = replacement.boundDocumentId()
        let replacementPathAfterRefusal = replacement.currentPath()
        let baselineAfterRefusal = original.persistedState(workspace.documentSnapshot(5821).getOrThrow(), aPath)
        @Assert(workspace.replaceRangeFromHuman(5821, CjguiTextDocumentRange(0, 2), "A-edited").applied, true)
        let savedOriginal = original.saveFromHuman(workspace.documentSnapshot(5821).getOrThrow(), aPath)
        let originalContentAfterSave = String.fromUtf8(File.readFrom(aPath))

        // Keep observing through close on RED: stopping at the unexpected
        // replacement acceptance would hide the original binding's leaked claim.
        let closed = workspace.closeDocumentFromHuman(5821)
        let originalClaimAfterClose = original.claimedDocumentId()
        let originalBoundAfterClose = original.boundDocumentId()
        let originalPathAfterClose = original.currentPath()
        let reused = workspace.attachFileBindingFromHuman(5822, original, bPath)
        var reusedSaveApplied = false
        if (reused.applied) {
            reusedSaveApplied = original.saveFromHuman(workspace.documentSnapshot(5822).getOrThrow(), bPath).applied
        }
        getStdOut().writeln("CJGUI_BINDING_REPLACEMENT replacement_applied=${refused.applied} " +
            "reason=${refused.reason} original_mapped=${originalStillMapped} y_claim_after_refusal=${replacementClaimAfterRefusal} " +
            "original_saved=${savedOriginal.applied} close_applied=${closed.applied} " +
            "x_claim_after_close=${originalClaimAfterClose} reuse_applied=${reused.applied} reuse_reason=${reused.reason}")
        @Assert(refused.applied, false)
        @Assert(refused.reason, "binding_replacement_unsupported")
        @Assert(originalStillMapped, true)
        @Assert(pathAfterRefusal, aPath)
        @Assert(contextAfterRefusal, contextBefore)
        @Assert(replacementClaimAfterRefusal, -1)
        @Assert(replacementBoundAfterRefusal, -1)
        @Assert(replacementPathAfterRefusal, "")
        @Assert(baselineAfterRefusal, "clean")
        @Assert(savedOriginal.applied, true)
        @Assert(originalContentAfterSave, "A-edited")
        @Assert(closed.applied, true)
        @Assert(originalClaimAfterClose, -1)
        @Assert(originalBoundAfterClose, -1)
        @Assert(originalPathAfterClose, "")
        @Assert(reused.applied, true)
        @Assert(reusedSaveApplied, true)
        @Assert(String.fromUtf8(File.readFrom(bPath)), "B0")
        @Assert(String.fromUtf8(File.readFrom(aPath)), "A-edited")
        @Assert(String.fromUtf8(File.readFrom(rejectedPath)), "Y-sentinel")
        @Assert(workspace.closeDocumentFromHuman(5822).applied, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func authorizationRevokesOnlyRetiredDynamicGrants(): Unit {
    let readScope = CjguiSharedOperationExternalActionScope("READ_RANGE", ArrayList<Int64>([10]), false)
    let closeScope = CjguiSharedOperationExternalActionScope("CLOSE_DOCUMENT", ArrayList<Int64>(), false)
    let allScope = CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
    let authorization = CjguiSharedOperationExternalAuthorization("caller", "token",
        ArrayList<CjguiSharedOperationExternalActionScope>([readScope, closeScope, allScope]))
    @Assert(authorization.permitsAction("CLOSE_DOCUMENT"), true)
    @Assert(authorization.permitsResource("CLOSE_DOCUMENT", 30), false)
    @Assert(authorization.grantResource("UNKNOWN_ACTION", 30), false)
    @Assert(authorization.grantResource("READ_RANGE", -1), false)
    @Assert(authorization.grantResource("READ_RANGE", 20), true)
    @Assert(authorization.grantResource("CLOSE_DOCUMENT", 30), true)
    @Assert(authorization.grantResource("GET_CONTEXT", 40), true)
    @Assert(authorization.permitsResource("READ_RANGE", 20), true)
    @Assert(authorization.permitsResource("READ_RANGE", 10), true)
    @Assert(authorization.permitsResource("CLOSE_DOCUMENT", 30), true)

    @Assert(authorization.revokeResource("READ_RANGE", 20), true)
    @Assert(authorization.revokeResource("READ_RANGE", 20), false)
    @Assert(authorization.permitsResource("READ_RANGE", 20), false)
    @Assert(authorization.permitsResource("READ_RANGE", 10), true)
    @Assert(authorization.permitsResource("CLOSE_DOCUMENT", 30), true)

    // Static policy and all-resource scopes are not narrowed by retirement.
    @Assert(authorization.revokeResource("READ_RANGE", 10), false)
    @Assert(authorization.permitsResource("READ_RANGE", 10), true)
    @Assert(authorization.revokeResource("GET_CONTEXT", 40), false)
    @Assert(authorization.allowsAllResources("GET_CONTEXT"), true)
}

private class DynamicLifecycleProbe <: CjguiTextDocumentLifecycleDomain {
    public var openCalls: Int64 = 0
    public var closeCalls: Int64 = 0
    public var lastTarget: Int64 = -1
    public var lastVersion: Int64 = -1
    public var lastDecision: String = ""

    public func openAuthorizedDocumentFromExternal(): CjguiSharedOperationActionResult {
        openCalls += 1
        return CjguiSharedOperationActionResult(true, false, 0, 1, "opened")
    }

    public func closeDocumentFromExternal(
        documentId: Int64,
        expectedVersion: Int64,
        decision: String
    ): CjguiSharedOperationActionResult {
        closeCalls += 1
        lastTarget = documentId
        lastVersion = expectedVersion
        lastDecision = decision
        return CjguiSharedOperationActionResult(false, false, 0, 0, "close_refused_probe")
    }
}

@Test
func dynamicWorkspaceRoutesLifecycleActionsToExplicitTargets(): Unit {
    let workspace = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(6101, "A", "A"), CjguiTextDocument(6102, "B", "B")
    ]))
    let absent = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "OPEN_DOCUMENT", 0, ArrayList<Int64>(), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(absent.applied, false)
    @Assert(absent.reason, "lifecycle_unavailable")

    let before = workspace.contextSnapshot().version
    let probe = DynamicLifecycleProbe()
    @Assert(workspace.attachLifecycleDomainFromHuman(probe), true)
    @Assert(workspace.attachLifecycleDomainFromHuman(probe), false)
    let opened = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "OPEN_DOCUMENT", 0, ArrayList<Int64>(), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(opened.applied, true)
    @Assert(probe.openCalls, 1)

    // The close target is explicit; selected B must not replace the request's A.
    @Assert(workspace.selectDocumentFromHuman(6102).applied, true)
    let closed = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "CLOSE_DOCUMENT", 7, ArrayList<Int64>([6101]),
        ArrayList<CjguiSharedOperationActionArgument>([dynamicTextArgument("decision", "discard")])))
    @Assert(closed.applied, false)
    @Assert(probe.closeCalls, 1)
    @Assert(probe.lastTarget, 6101)
    @Assert(probe.lastVersion, 7)
    @Assert(probe.lastDecision, "discard")
    @Assert(workspace.selection().documentId, 6102)

    let invalidOpen = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "OPEN_DOCUMENT", 0, ArrayList<Int64>([6101]), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(invalidOpen.reason, "invalid_parameters")
    let invalidClose = workspace.executeFromExternal(CjguiSharedOperationActionInvocation(
        "CLOSE_DOCUMENT", 0, ArrayList<Int64>(), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(invalidClose.reason, "invalid_target")
    @Assert(probe.openCalls, 1)
    @Assert(probe.closeCalls, 1)
    @Assert(workspace.contextSnapshot().version, before + 1)
}
