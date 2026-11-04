package cjgui_mixed_form_starter

import cjgui.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private let closeGuardDocumentA = "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\nEND\n"
private let closeGuardDocumentB = "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\nNODE 1 label label\nPROPERTY 1 label text changed\nEND\n"

private class CloseGuardSurface <: CjguiUiDocumentSurface {
    var text: String = closeGuardDocumentA
    var version: Int64 = 1
    var identity: Int64 = cjguiNextUiDocumentSurfaceIdentity()
    public func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument {
        return CjguiGeneratedUiAcceptedDocument(text, version, cjguiUiDocumentDigest(text))
    }
    public func uiDocumentSurfaceIdentity(): Int64 { return identity }
    public func submitUiDocument(candidate: String, expectedVersion: Int64): CjguiUiDocumentSubmit {
        let _ = candidate
        let _ = expectedVersion
        return CjguiUiDocumentSubmit(true, "candidate_pending", 7)
    }
}

@Test
func mixedCloseGuardDiscardIsBoundAndCanBeRevoked(): Unit {
    let surface = CloseGuardSurface()
    let session = CjguiGeneratedUiDocumentSession()
    let workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("guard-test"), "document",
        session, surface)
    let guard = CjguiUiDocumentCloseGuard()
    guard.add(workspace)
    @Assert(guard.settleAndReport().contains("未保存"), true)
    guard.discardUnsaved()
    @Assert(guard.inspectAndReport(), "")
    @Assert(guard.inspectAndReport(), "")
    guard.cancelDiscard()
    @Assert(guard.settleAndReport().contains("未保存"), true)
    guard.discardUnsaved()
    surface.text = closeGuardDocumentB
    surface.version = 2
    @Assert(guard.settleAndReport().contains("未保存"), true)
    guard.discardUnsaved()
    @Assert(guard.inspectAndReport(), "")
    @Assert(guard.settleAndReport(), "")
    @Assert(guard.settleAndReport().contains("未保存"), true)
}

@Test
func mixedCloseGuardPendingAndSaveFailureCannotReuseDiscard(): Unit {
    let surface = CloseGuardSurface()
    let session = CjguiGeneratedUiDocumentSession()
    let workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("guard-failure"), "document",
        session, surface)
    let guard = CjguiUiDocumentCloseGuard()
    guard.add(workspace)
    guard.discardUnsaved()
    @Assert(guard.saveUnsaved({ _ => "" }), "ui_document_path_empty")
    @Assert(guard.settleAndReport().contains("未保存"), true)
    let directory = Directory.createTemp("/tmp")
    try {
        let exported = cjguiExportUiDocument(closeGuardDocumentB)
        @Assert(exported.ok, true)
        let path = directory.join("pending.cjgui")
        File.writeTo(path, exported.text.toArray())
        @Assert(session.previewReloadPath(surface, path.toString(), policy: CJGUI_UI_DOCUMENT_POLICY_MERGE).applied, true)
        @Assert(session.confirmReload(surface).submitted, true)
        guard.discardUnsaved()
        @Assert(guard.inspectAndReport().contains("结算"), true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}
