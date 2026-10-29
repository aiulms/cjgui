package cjgui

import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private class UiHistoryProductionBinding <: CjguiGeneratedUiRegionBinding {
    public func ownerRevision(): Int64 { return 0 }
    public func fieldResourceId(fieldId: String): Int64 { return 6201 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 6200 }
    public func draftText(fieldId: String): String { return "business draft" }
    public func appliedText(fieldId: String): String { return "business applied" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func actionAvailable(actionName: String): Bool { return false }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "not_a_business_action")
    }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

// The existing public workspace must describe unsupported/disabled history
// honestly, and route the SAME named refusal as its human command entry.
// No future history API is used in this baseline counterexample.
@Test
func uiHistoryPublicWorkspaceReportsDisabledHistoryWithoutOptIn(): Unit {
    let region = CjguiGeneratedUiWindowRegion(CjguiGeneratedUiCapabilityCatalog(),
        UiHistoryProductionBinding(), "history-production")
    let workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("history-red"),
        "document", CjguiGeneratedUiDocumentSession(), region)
    let state = workspace.actionState("UI_DOC_UNDO")
    @Assert(state.isSome(), true)
    @Assert(state.getOrThrow().enabled, false)
    @Assert(state.getOrThrow().disabledReason, "ui_document_history_disabled")
    let result = workspace.handleAction("UI_DOC_UNDO")
    @Assert(result.isSome(), true)
    @Assert(result.getOrThrow().applied, false)
    @Assert(result.getOrThrow().reason, "ui_document_history_disabled")
    @Assert(region.acceptedStructureVersion(), 0)
}

private func historyText(key: String): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 ${key} vertical\nEND\n"
}

private func historyRegion(): CjguiGeneratedUiWindowRegion {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 8))
    return CjguiGeneratedUiWindowRegion(catalog, UiHistoryProductionBinding(), "history-region")
}

private func historyCommit(region: CjguiGeneratedUiWindowRegion): Unit {
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
}

private func historyAccept(region: CjguiGeneratedUiWindowRegion, text: String): Unit {
    let submitted = region.submitStructure(text, region.acceptedStructureVersion())
    @Assert(submitted.reason, "")
    @Assert(submitted.candidateAccepted, true)
    historyCommit(region)
    @Assert(region.uiDocumentTicketSnapshot(submitted.candidateToken).terminalState, "ACCEPTED")
}

private func historyWorkspace(region: CjguiUiDocumentSurface,
    policy!: CjguiUiDocumentHistoryPolicy = CjguiUiDocumentHistoryPolicy()): CjguiUiDocumentWorkspace {
    let session = CjguiGeneratedUiDocumentSession(historyPolicy: Some(policy))
    let workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("history-workspace"),
        "main", session, region)
    let _ = workspace.historyState()
    return workspace
}

@Test
func uiHistoryRealRegionMovesOnlyAfterExactTerminalAndVersionsKeepIncreasing(): Unit {
    let region = historyRegion()
    historyAccept(region, historyText("boardA"))
    let workspace = historyWorkspace(region)
    historyAccept(region, historyText("boardB"))
    let _ = workspace.finish()
    @Assert(workspace.historyState().undoDepth, 1)
    let submitted = workspace.handleAction("UI_DOC_UNDO").getOrThrow()
    @Assert(submitted.submitted, true)
    @Assert(workspace.historyState().undoDepth, 1)
    @Assert(workspace.historyState().redoDepth, 0)
    @Assert(workspace.finish().reason, "ui_document_pending")
    historyCommit(region)
    @Assert(region.acceptedStructureVersion(), 3)
    @Assert(workspace.historyState().undoDepth, 1) // accepted is not yet settled
    @Assert(workspace.finish().accepted, true)
    @Assert(workspace.historyState().undoDepth, 0)
    @Assert(workspace.historyState().redoDepth, 1)
    @Assert(workspace.session().savedDigest(), "")
    let redo = workspace.handleAction("UI_DOC_REDO").getOrThrow()
    @Assert(redo.submitted, true)
    historyCommit(region)
    @Assert(workspace.finish().accepted, true)
    @Assert(region.acceptedStructureVersion(), 4)
    @Assert(region.acceptedUiDocument().text.contains("boardB"), true)
    @Assert(workspace.historyState().undoDepth, 1)
    @Assert(workspace.historyState().redoDepth, 0)
}

@Test
func uiHistoryRealRegionRejectedSceneKeepsLedgerAndCurrentUi(): Unit {
    let region = historyRegion()
    historyAccept(region, historyText("boardA"))
    let workspace = historyWorkspace(region)
    historyAccept(region, historyText("boardB"))
    let _ = workspace.finish()
    let before = region.acceptedUiDocument()
    let submitted = workspace.handleAction("UI_DOC_UNDO").getOrThrow()
    @Assert(submitted.submitted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    region.rollbackSceneRefresh("history_reject")
    @Assert(workspace.finish().accepted, false)
    @Assert(region.acceptedUiDocument().digest, before.digest)
    @Assert(region.acceptedUiDocument().version, before.version)
    @Assert(workspace.historyState().undoDepth, 1)
    @Assert(workspace.historyState().redoDepth, 0)
}

@Test
func uiHistoryBranchAndStaleDigestRefusalDoNotSubmitOrRestoreOldRedo(): Unit {
    let region = historyRegion()
    historyAccept(region, historyText("boardA"))
    let workspace = historyWorkspace(region)
    historyAccept(region, historyText("boardB"))
    let _ = workspace.finish()
    let old = workspace.historyState()
    let _ = workspace.handleAction("UI_DOC_UNDO")
    historyCommit(region)
    let _ = workspace.finish()
    historyAccept(region, historyText("branchC"))
    let _ = workspace.finish()
    @Assert(workspace.historyState().redoDepth, 0)
    let before = region.acceptedUiDocument()
    let stale = workspace.handleHistoryAction("UI_DOC_REDO", old.acceptedVersion, old.acceptedDigest)
    @Assert(stale.reason, "ui_document_history_baseline_changed")
    @Assert(stale.submitted, false)
    let wrongDigest = workspace.handleHistoryAction("UI_DOC_UNDO", before.version, "wrong")
    @Assert(wrongDigest.reason, "ui_document_history_baseline_changed")
    @Assert(region.acceptedUiDocument().digest, before.digest)
    @Assert(region.candidateStructureVersion(), 0)
    @Assert(workspace.handleAction("UI_DOC_REDO").getOrThrow().reason, "ui_document_nothing_to_redo")
}

// Adversarial public surface: controls only the accepted/ticket observations,
// never emulates the region's tree, native scene or candidate implementation.
private class UiHistoryProbeSurface <: CjguiUiDocumentSurface {
    var text: String = historyText("boardA")
    var version: Int64 = 1
    let identity = cjguiNextUiDocumentSurfaceIdentity()
    var submits: Int64 = 0
    var known: Bool = true
    var terminal: String = "PENDING"
    var acceptedVersion: Int64 = 0
    var tokenOffset: Int64 = 0
    var rejectSubmit: String = ""
    var documentReads: Int64 = 0
    var revisionReads: Int64 = 0

    public func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument {
        documentReads += 1
        return CjguiGeneratedUiAcceptedDocument(text, version, cjguiUiDocumentDigest(text))
    }
    public func acceptedUiDocumentVersion(): Int64 { revisionReads += 1; return version }
    public func uiDocumentSurfaceIdentity(): Int64 { return identity }
    public func submitUiDocument(candidate: String, expectedVersion: Int64): CjguiUiDocumentSubmit {
        @Assert(expectedVersion, version)
        submits += 1
        terminal = "PENDING"
        return CjguiUiDocumentSubmit(rejectSubmit.size == 0, rejectSubmit, submits + 100)
    }
    public func uiDocumentTicket(token: Int64): CjguiUiDocumentTicket {
        return CjguiUiDocumentTicket(token + tokenOffset, known, terminal, "probe", "probe_refusal",
            acceptedVersion, version, cjguiUiDocumentDigest(text))
    }
    func change(key: String, step!: Int64 = 1): Unit { text = historyText(key); version += step }
    func acceptPending(session: CjguiGeneratedUiDocumentSession): Unit {
        let plan = session.preview().getOrThrow()
        text = plan.expectedText
        version = plan.expectedVersion
        acceptedVersion = version
        terminal = "ACCEPTED"
    }
}

@Test
func uiHistoryUnknownWrongTicketAndLateClosedCompletionNeverMoveLedger(): Unit {
    let surface = UiHistoryProbeSurface()
    let workspace = historyWorkspace(surface)
    surface.change("boardB")
    let _ = workspace.finish()
    let submitted = workspace.handleAction("UI_DOC_UNDO").getOrThrow()
    @Assert(submitted.submitted, true)
    surface.known = false
    @Assert(workspace.finish().reason, "ui_document_pending")
    @Assert(workspace.historyState().undoDepth, 1)
    surface.known = true
    surface.tokenOffset = 1
    @Assert(workspace.finish().reason, "ui_document_ticket_mismatch")
    @Assert(workspace.historyState().undoDepth, 1)
    let current = surface.acceptedUiDocument()
    @Assert(workspace.resetHistory(current.version, current.digest).reason, "ui_document_operation_pending")
    workspace.closeHistory()
    surface.tokenOffset = 0
    surface.acceptPending(workspace.session())
    @Assert(workspace.finish().reason, "ui_document_history_invalidated")
    @Assert(workspace.historyState().enabled, false)
    @Assert(workspace.historyState().undoDepth, 0)
    @Assert(surface.submits, 1)
}

@Test
func uiHistoryAcceptedThenChangedAndUnobservedExternalVersionsCreateVisibleBoundary(): Unit {
    let surface = UiHistoryProbeSurface()
    let workspace = historyWorkspace(surface)
    surface.change("boardB")
    let _ = workspace.finish()
    let _ = workspace.handleAction("UI_DOC_UNDO")
    surface.acceptPending(workspace.session())
    surface.change("externalC")
    @Assert(workspace.finish().reason, "accepted_then_changed")
    @Assert(workspace.historyState().undoDepth, 0)
    @Assert(workspace.historyState().boundaryReason, "ui_document_history_unobserved_change")
    surface.change("externalD")
    let _ = workspace.finish()
    @Assert(workspace.historyState().undoDepth, 1)
    surface.change("skipped", step: 2)
    let _ = workspace.finish()
    @Assert(workspace.historyState().undoDepth, 0)
    @Assert(workspace.historyState().boundaryReason, "ui_document_history_unobserved_change")
    @Assert(workspace.handleAction("UI_DOC_UNDO").getOrThrow().submitted, false)
}

@Test
func uiHistorySurfaceIsolationAndCurrentAdmissionRefusalPreserveHistory(): Unit {
    let a = UiHistoryProbeSurface()
    let b = UiHistoryProbeSurface()
    let wa = historyWorkspace(a)
    let wb = historyWorkspace(b)
    a.change("aNext")
    let _ = wa.finish()
    @Assert(wa.historyState().undoDepth, 1)
    @Assert(wb.historyState().undoDepth, 0)
    let ba = b.acceptedUiDocument()
    @Assert(wa.session().historyAction(b, "UI_DOC_UNDO", ba.version, ba.digest).reason,
        "ui_document_surface_mismatch")
    @Assert(wa.historyState().undoDepth, 1)
    a.rejectSubmit = "field_not_authorized"
    @Assert(wa.handleAction("UI_DOC_UNDO").getOrThrow().reason,
        "ui_document_rejected:field_not_authorized")
    @Assert(wa.historyState().undoDepth, 1)
    @Assert(wa.historyState().redoDepth, 0)
    @Assert(wb.historyState().undoDepth, 0)
}

@Test
func uiHistoryTransactionAndByteLimitsEvictWholeTransactionsAndOversizeCreatesBoundary(): Unit {
    let surface = UiHistoryProbeSurface()
    let workspace = historyWorkspace(surface,
        policy: CjguiUiDocumentHistoryPolicy(maximumTransactions: 2, maximumSerializedBytes: 10000))
    for (key in ["b", "c", "d"]) { surface.change(key); let _ = workspace.finish() }
    @Assert(workspace.historyState().undoDepth, 2)
    @Assert(workspace.historyState().boundaryReason, "ui_document_history_evicted")
    let byteSurface = UiHistoryProbeSurface()
    let bytes = byteSurface.text.size
    let byteWorkspace = historyWorkspace(byteSurface,
        policy: CjguiUiDocumentHistoryPolicy(maximumTransactions: 20, maximumSerializedBytes: bytes * 2))
    for (key in ["boardB", "boardC"]) { byteSurface.change(key); let _ = byteWorkspace.finish() }
    @Assert(byteWorkspace.historyState().undoDepth, 1)
    @Assert(byteWorkspace.historyState().retainedSerializedBytes <= bytes * 2, true)
    byteSurface.change("boardWithAVeryLongButLegalRootKeyThatExceedsTheHistoryBytes")
    let _ = byteWorkspace.finish()
    @Assert(byteWorkspace.historyState().undoDepth, 0)
    @Assert(byteWorkspace.historyState().retainedSerializedBytes, 0)
    @Assert(byteWorkspace.historyState().undoReason, "ui_document_history_entry_too_large")
}

@Test
func uiHistoryNoopDoesNotCreateTransactionAndDirtyUsesActualSavedDigest(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let region = historyRegion()
        historyAccept(region, historyText("boardA"))
        let session = CjguiGeneratedUiDocumentSession(path: directory.join("ui.cjgui").toString(),
            historyPolicy: Some(CjguiUiDocumentHistoryPolicy()))
        let workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("saved-history"),
            "main", session, region)
        let _ = workspace.historyState()
        @Assert(session.save(region).applied, true)
        historyAccept(region, historyText("boardA"))
        let _ = workspace.finish()
        @Assert(workspace.historyState().undoDepth, 0)
        historyAccept(region, historyText("boardB"))
        let _ = workspace.finish()
        @Assert(session.stateFor(region).unsaved, true)
        let _ = workspace.handleAction("UI_DOC_UNDO")
        historyCommit(region)
        @Assert(workspace.finish().accepted, true)
        @Assert(session.stateFor(region).unsaved, false)
        @Assert(session.savedBaseline(), 1)
        @Assert(region.acceptedStructureVersion(), 4)
        @Assert(workspace.historyState().redoDepth, 1)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func uiHistoryDisabledSessionHasNoAddedTurnSnapshotsOrRevisionPolling(): Unit {
    let surface = UiHistoryProbeSurface()
    let session = CjguiGeneratedUiDocumentSession()
    for (_ in 0..10) {
        let _ = session.finishReload(surface)
        @Assert(session.historyState(surface).enabled, false)
    }
    @Assert(surface.documentReads, 0)
    @Assert(surface.revisionReads, 0)
}

@Test
func uiHistoryPublicProviderAndHumanCommandUseOneSessionAndOpaqueEpoch(): Unit {
    let region = historyRegion()
    historyAccept(region, historyText("boardA"))
    let workspace = historyWorkspace(region)
    @Assert(region.capabilitiesPayload().contains("UI_DOCUMENT_HISTORY version=1"), true)
    historyAccept(region, historyText("boardB"))
    let _ = workspace.finish()
    let before = workspace.historyState()
    @Assert(region.uiDocumentHistoryPayload().contains("UNDO_DEPTH 1"), true)
    let accepted = region.submitUiDocumentHistory("UI_DOC_UNDO", before.acceptedVersion,
        before.acceptedDigest, before.surfaceIdentity, before.epoch)
    @Assert(accepted.candidateAccepted, true)
    @Assert(accepted.candidateToken, workspace.historyState().pendingToken)
    historyCommit(region)
    @Assert(workspace.finish().accepted, true)
    @Assert(workspace.historyState().redoDepth, 1)
    let current = region.acceptedUiDocument()
    let oldEpoch = workspace.historyState().epoch
    @Assert(workspace.resetHistory(current.version, current.digest).applied, true)
    let stale = region.submitUiDocumentHistory("UI_DOC_UNDO", current.version, current.digest,
        before.surfaceIdentity, oldEpoch)
    @Assert(stale.reason, "ui_document_history_epoch_changed")
    @Assert(stale.candidateAccepted, false)
    workspace.closeHistory()
    let next = historyWorkspace(region)
    @Assert(next.historyState().epoch != oldEpoch, true)
    @Assert(next.historyState().undoDepth, 0)
    // An old workspace closing again cannot detach its replacement.
    workspace.closeHistory()
    @Assert(region.uiDocumentHistoryPayload().contains("ENABLED true"), true)
}

@Test
func uiHistorySaveAsAndPathChangesResetOnlyHistoryNotTheAcceptedUi(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let surface = UiHistoryProbeSurface()
        let workspace = historyWorkspace(surface)
        surface.change("boardB")
        let _ = workspace.finish()
        let before = surface.acceptedUiDocument()
        @Assert(workspace.saveAs(directory.join("other.cjgui").toString()).applied, true)
        @Assert(workspace.historyState().undoDepth, 0)
        @Assert(surface.acceptedUiDocument().digest, before.digest)
        surface.change("boardC")
        let _ = workspace.finish()
        @Assert(workspace.historyState().undoDepth, 1)
        workspace.session().setPath(directory.join("third.cjgui").toString())
        @Assert(workspace.historyState().undoDepth, 0)
        @Assert(surface.submits, 0)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

private func uiHistoryCompositionSection(name: String, caption: String): String {
    return "COMPOSITION ${name} 16 4\nCPARAM caption STRING 0 0 40 40 ${caption}\n" +
        "CELEMENT label field field=label argument=text label=标签\n" +
        "CTEMPLATE 0 root vertical\nCTEMPLATE 1 label element element=label presentation=text\n" +
        "COMPOSITION_END ${name}\n"
}

@Test
func uiHistoryRestoresFullAcceptedDefinitionsParametersAndInstancesThroughReplace(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 8))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "标签", "TEXT", 6201,
        maximumLength: 64, argumentName: "text"))
    let region = CjguiGeneratedUiWindowRegion(catalog, UiHistoryProductionBinding(), "history-compositions")
    let first = "GENERATED_UI_STRUCTURE 2\n" + uiHistoryCompositionSection("historyCardA", "oldA") +
        uiHistoryCompositionSection("historyCardB", "oldB") +
        "NODE 0 board vertical\nNODE 1 a historyCardA\nPROPERTY 1 a caption firstA\n" +
        "NODE 1 b historyCardB\nPROPERTY 1 b caption firstB\nEND"
    historyAccept(region, first)
    let original = region.acceptedUiDocument()
    let workspace = historyWorkspace(region)
    let second = "GENERATED_UI_STRUCTURE 2\n" + uiHistoryCompositionSection("historyCardA", "newA") +
        "COMPOSITION_REMOVE historyCardB\nNODE 0 board vertical\nNODE 1 a historyCardA\n" +
        "PROPERTY 1 a caption secondA\nEND"
    historyAccept(region, second)
    let current = region.acceptedUiDocument()
    let _ = workspace.finish()
    @Assert(workspace.historyState().undoDepth, 1)
    let undo = workspace.handleAction("UI_DOC_UNDO").getOrThrow()
    @Assert(undo.submitted, true)
    @Assert(undo.version, current.version + 1)
    historyCommit(region)
    @Assert(workspace.finish().accepted, true)
    @Assert(region.acceptedUiDocument().text, original.text)
    @Assert(region.acceptedUiDocument().digest, original.digest)
    @Assert(region.acceptedUiDocument().version > current.version, true)
    let redo = workspace.handleAction("UI_DOC_REDO").getOrThrow()
    @Assert(redo.submitted, true)
    @Assert(workspace.session().preview().getOrThrow().candidateText.contains("COMPOSITION_REMOVE historyCardB"), true)
    historyCommit(region)
    @Assert(workspace.finish().accepted, true)
    @Assert(region.acceptedUiDocument().text, current.text)
    @Assert(region.acceptedUiDocument().digest, current.digest)
    @Assert(workspace.historyState().redoDepth, 0)
}
