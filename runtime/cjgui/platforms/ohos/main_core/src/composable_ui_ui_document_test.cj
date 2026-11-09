package cjgui

import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

// The startup loader must be the SAME contract as the Python importer: one
// bounded file read, strict JSON (duplicate keys/escapes/types), a verified
// structure digest and requirements that agree with the structure references.

private let UI_DOCUMENT_TEST_STRUCTURE = "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\nEND\n"
private let UI_DOCUMENT_TEST_DIGEST =
    "158972c1e55d9f885a44b705fd0c2b8d07dcea59c773737c11d073c26f4df5a4"

private func uiDocumentTestJson(structure!: String = UI_DOCUMENT_TEST_STRUCTURE,
    components!: String = "[\"vertical\"]", digest!: String = UI_DOCUMENT_TEST_DIGEST,
    formatVersion!: String = "1"): String {
    let escaped = structure.replace("\\", "\\\\").replace("\"", "\\\"")
        .replace("\n", "\\n")
    return "{\"format\":\"cjgui.ui-document\",\"format_version\":${formatVersion}," +
        "\"requirements\":{\"actions\":[],\"components\":${components},\"fields\":[]," +
        "\"fonts\":[],\"image_resources\":[],\"runtime_compositions\":[],\"styles\":[]}," +
        "\"structure\":\"${escaped}\",\"structure_format\":1," +
        "\"structure_sha256\":\"${digest}\"}"
}

private func uiDocumentTestWrite(directory: Path, name: String, text: String): String {
    let path = directory.join(name)
    File.writeTo(path, text.toArray())
    return path.toString()
}

private func uiDocumentTestHasLine(lines: ArrayList<String>, needle: String): Bool {
    for (line in lines) {
        if (line.contains(needle)) { return true }
    }
    return false
}

@Test
func uiDocumentLoaderAcceptsThePortableDocument(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestWrite(directory, "valid.ui.json",
            uiDocumentTestJson())
        let loaded = cjguiReadUiDocument(path)
        @Assert(loaded.ok, true)
        @Assert(loaded.issue, "")
        @Assert(loaded.structureText, UI_DOCUMENT_TEST_STRUCTURE)
        @Assert(loaded.structureFormat, 1)
        @Assert(loaded.structureSha256, UI_DOCUMENT_TEST_DIGEST)
        @Assert(loaded.formatVersion, 1)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentLoaderRefusesTamperedAndInconsistentDocuments(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let tampered = uiDocumentTestWrite(directory, "tampered.ui.json",
            uiDocumentTestJson(digest: "0000000000000000000000000000000000000000000000000000000000000000"))
        let digestResult = cjguiReadUiDocument(tampered)
        @Assert(digestResult.ok, false)
        @Assert(digestResult.issue, "ui_document_structure_digest")

        let mismatch = uiDocumentTestWrite(directory, "mismatch.ui.json",
            uiDocumentTestJson(components: "[\"ghost\"]"))
        let mismatchResult = cjguiReadUiDocument(mismatch)
        @Assert(mismatchResult.ok, false)
        @Assert(mismatchResult.issue, "ui_document_requirements_mismatch")

        let duplicate = uiDocumentTestWrite(directory, "duplicate.ui.json",
            uiDocumentTestJson().replace("\"format_version\":1,",
                "\"format_version\":1,\"format_version\":1,"))
        @Assert(cjguiReadUiDocument(duplicate).issue, "ui_document_not_object")

        let stringVersion = uiDocumentTestWrite(directory, "string-version.ui.json",
            uiDocumentTestJson(formatVersion: "\"1\""))
        @Assert(cjguiReadUiDocument(stringVersion).issue, "ui_document_version")

        let badRequirements = uiDocumentTestWrite(directory, "requirements.ui.json",
            uiDocumentTestJson().replace("[],\"image_resources\"",
                "[\"serif\"],\"image_resources\""))
        @Assert(cjguiReadUiDocument(badRequirements).issue, "ui_document_requirements")

        let unknown = uiDocumentTestWrite(directory, "unknown.ui.json",
            uiDocumentTestJson().replace("\"format_version\":1,",
                "\"format_version\":1,\"endpoint\":{},",))
        @Assert(cjguiReadUiDocument(unknown).issue, "ui_document_unknown_key:endpoint")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentLoaderRefusesMalformedJsonAndBadUtf8(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let loneSurrogate = uiDocumentTestWrite(directory, "surrogate.ui.json",
            uiDocumentTestJson().replace("\"format\":\"cjgui.ui-document\",",
                "\"format\":\"cjgui.ui-document\\uD800\","))
        @Assert(cjguiReadUiDocument(loneSurrogate).issue, "ui_document_not_object")

        let badEscape = uiDocumentTestWrite(directory, "escape.ui.json",
            uiDocumentTestJson().replace("cjgui.ui-document", "cjgui.ui-do\\qcument"))
        @Assert(cjguiReadUiDocument(badEscape).issue, "ui_document_not_object")

        let badUtf8 = directory.join("bad-utf8.ui.json")
        File.writeTo(badUtf8, [UInt8(0x7b), UInt8(0xff), UInt8(0x7d)])
        @Assert(cjguiReadUiDocument(badUtf8.toString()).issue, "ui_document_not_utf8")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentLoaderRefusesOversizedAndSpecialInputs(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let oversized = directory.join("oversized.ui.json")
        File.writeTo(oversized,
            Array<UInt8>(CJGUI_UI_DOCUMENT_MAX_BYTES + 1, repeat: UInt8(32)))
        @Assert(cjguiReadUiDocument(oversized.toString()).issue, "ui_document_too_large")
        @Assert(cjguiReadUiDocument(directory.join("missing.ui.json").toString()).issue,
            "ui_document_unreadable")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

// --- DS50: the session owns an operation record, the region owns settlement ---

private class UiDocumentTestSurface <: CjguiUiDocumentSurface {
    var text: String
    var version: Int64
    var submits: Int64 = 0
    var lastToken: Int64 = 0
    var lastCandidate: String = ""
    var lastExpectedVersion: Int64 = 0
    var ticketState: String = "PENDING"
    var ticketReason: String = ""
    var ticketAcceptedVersion: Int64 = 0
    var ticketTokenOffset: Int64 = 0
    let surfaceIdentity: Int64 = cjguiNextUiDocumentSurfaceIdentity()

    init(text: String, version!: Int64 = 1) {
        this.text = text
        this.version = version
    }

    public func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument {
        return CjguiGeneratedUiAcceptedDocument(text, version, cjguiUiDocumentDigest(text))
    }

    public func submitUiDocument(candidate: String,
        expectedVersion: Int64): CjguiUiDocumentSubmit {
        submits += 1
        lastToken = 100 + submits
        lastCandidate = candidate
        lastExpectedVersion = expectedVersion
        ticketState = "PENDING"
        ticketReason = ""
        return CjguiUiDocumentSubmit(true, "candidate_pending", lastToken)
    }

    public func uiDocumentTicket(token: Int64): CjguiUiDocumentTicket {
        return CjguiUiDocumentTicket(token + ticketTokenOffset, true, ticketState,
            "scene_" + ticketState, ticketReason, ticketAcceptedVersion, version,
            cjguiUiDocumentDigest(text))
    }

    public func uiDocumentSurfaceIdentity(): Int64 {
        return surfaceIdentity
    }

    func settleAccepted(expected: String, newVersion: Int64, token: Int64): Unit {
        text = expected
        version = newVersion
        ticketState = "ACCEPTED"
        ticketReason = ""
        ticketAcceptedVersion = newVersion
    }

    func settleRejected(token: Int64, reason: String): Unit {
        ticketState = "REJECTED"
        ticketReason = reason
    }
}

private func uiDocumentTestExport(directory: Path, name: String, structure: String): String {
    let exported = cjguiExportUiDocument(structure)
    if (!exported.ok) {
        throw IllegalStateException("test export refused: ${exported.issue}")
    }
    return uiDocumentTestWrite(directory, name, exported.text)
}

@Test
func uiDocumentLifecycleLateExactFileObservationAndCloseShareOneOutcome(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "startup.cjgui", UI_DOCUMENT_TEST_STRUCTURE)
        let file = cjguiReadUiDocument(path)
        let surface = UiDocumentTestSurface("GENERATED_UI_STRUCTURE 1\nEND", version: 0)
        let session = CjguiGeneratedUiDocumentSession()
        let workspace = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("lifecycle"),
            "main", session, surface)
        let submitted = workspace.beginStartup(path)
        @Assert(submitted.submitted, true)
        @Assert(submitted.path, path)
        @Assert(workspace.startupPending(), true)
        for (_ in 0..3) { @Assert(workspace.finish().reason, "ui_document_pending") }
        @Assert(surface.submits, 1)
        @Assert(session.savedDigest(), "")
        let plan = session.preview().getOrThrow()
        @Assert(plan.fileDigest != plan.expectedDigest, true)
        surface.settleAccepted(plan.expectedText, plan.expectedVersion, submitted.token)
        let guard = CjguiUiDocumentCloseGuard()
        guard.add(workspace)
        let _ = guard.settleAndReport()
        @Assert(workspace.startupPending(), false)
        @Assert(workspace.startupResult().accepted, true)
        @Assert(workspace.startupResult().token, submitted.token)
        @Assert(workspace.startupResult().fileDigest, file.structureSha256)
        @Assert(session.savedDigest(), file.structureSha256)
        @Assert(workspace.finish().reason, "ui_document_no_submission")
        @Assert(workspace.startupResult().accepted, true)
        @Assert(session.save(surface).reason, "saved")
        @Assert(surface.submits, 1)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func uiDocumentLifecycleAcceptedThenChangedRetainsOriginalAssociation(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let pathA = directory.join("original.cjgui").toString()
        let pathB = uiDocumentTestExport(directory, "startup.cjgui", UI_DOCUMENT_TEST_STRUCTURE)
        let surface = UiDocumentTestSurface("GENERATED_UI_STRUCTURE 1\nEND", version: 0)
        let session = CjguiGeneratedUiDocumentSession(path: pathA)
        @Assert(session.save(surface).applied, true)
        let oldDigest = session.savedDigest()
        let started = session.beginStartup(surface, pathB)
        let plan = session.preview().getOrThrow()
        surface.settleAccepted(plan.expectedText, plan.expectedVersion, started.token)
        surface.version += 1
        surface.text = "GENERATED_UI_STRUCTURE 1\nEND"
        @Assert(session.finishReload(surface).reason, "accepted_then_changed")
        @Assert(session.startupResult(surface).accepted, false)
        @Assert(session.path(), pathA)
        @Assert(session.savedDigest(), oldDigest)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func uiDocumentLifecycleUnknownAndNewInteractiveOperationKeepOwnership(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "startup.cjgui", UI_DOCUMENT_TEST_STRUCTURE)
        let surface = UiDocumentTestSurface("GENERATED_UI_STRUCTURE 1\nEND", version: 0)
        let session = CjguiGeneratedUiDocumentSession()
        let started = session.beginStartup(surface, path)
        surface.ticketState = "UNKNOWN"
        @Assert(session.finishReload(surface).reason, "ui_document_pending")
        @Assert(session.startupPending(surface), true)
        @Assert(surface.submits, 1)
        surface.ticketState = "REJECTED"
        surface.ticketReason = "window_closed"
        @Assert(session.finishReload(surface).reason, "ui_document_rejected:window_closed")
        @Assert(session.startupPending(surface), false)
        @Assert(session.previewReloadPath(surface, path,
            policy: CJGUI_UI_DOCUMENT_POLICY_REPLACE).applied, true)
        let preview = session.preview().getOrThrow()
        @Assert(session.beginStartup(surface, path).reason, "ui_document_operation_pending")
        @Assert(session.preview().getOrThrow().fileDigest, preview.fileDigest)
        @Assert(session.stateFor(surface).mode, "preview")
        @Assert(session.startupResult(surface).token, started.token)
        @Assert(session.startupResult(surface).accepted, false)
        @Assert(surface.submits, 1)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func uiDocumentLifecycleTwoWorkspacesAndReplacementSurfaceCannotCrossAdopt(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "startup.cjgui", UI_DOCUMENT_TEST_STRUCTURE)
        let a = UiDocumentTestSurface("GENERATED_UI_STRUCTURE 1\nEND", version: 0)
        let b = UiDocumentTestSurface("GENERATED_UI_STRUCTURE 1\nEND", version: 0)
        let sa = CjguiGeneratedUiDocumentSession()
        let sb = CjguiGeneratedUiDocumentSession()
        let scope = CjguiComposableUiIdentityScope("lifecycle-pair")
        let wa = CjguiUiDocumentWorkspace(scope, "a", sa, a)
        let wb = CjguiUiDocumentWorkspace(scope, "b", sb, b)
        let first = wa.beginStartup(path)
        let _ = wb.beginStartup(path)
        let expected = sa.preview().getOrThrow()
        a.settleAccepted(expected.expectedText, expected.expectedVersion, first.token)
        @Assert(wa.finish().accepted, true)
        @Assert(wb.finish().reason, "ui_document_pending")
        @Assert(sb.savedDigest(), "")
        let rebound = CjguiUiDocumentWorkspace(scope, "replacement", sa, b)
        @Assert(rebound.beginStartup(path).reason, "ui_document_surface_mismatch")
        @Assert(rebound.startupResult().accepted, false)
        @Assert(wb.startupPending(), true)
        @Assert(sa.path(), path)
        @Assert(b.submits, 1)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func uiDocumentLifecycleLegalEmptyStartupAdoptsWithoutSubmit(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let text = "GENERATED_UI_STRUCTURE 1\nEND"
        let path = uiDocumentTestExport(directory, "empty.cjgui", text)
        let surface = UiDocumentTestSurface(text, version: 0)
        let session = CjguiGeneratedUiDocumentSession()
        let result = session.beginStartup(surface, path)
        @Assert(result.reason, "ui_document_file_adopted")
        @Assert(result.submitted, false)
        @Assert(result.version, 0)
        @Assert(surface.submits, 0)
        @Assert(session.savedDigest(), cjguiReadUiDocument(path).structureSha256)
        @Assert(session.startupResult(surface).reason, "ui_document_file_adopted")
        @Assert(session.save(surface).applied, true)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

private let UI_DOC_TEST_MERGE_BASE = """
GENERATED_UI_STRUCTURE 2
COMPOSITION cardA 64 6
CPARAM title STRING 0 0 40 40 A
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=2
CTEMPLATE 1 name element element=name presentation=text
COMPOSITION_END cardA
COMPOSITION cardB 64 6
CPARAM title STRING 0 0 40 40 B
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=2
CTEMPLATE 1 name element element=name presentation=text
COMPOSITION_END cardB
NODE 0 board vertical
NODE 1 cardA cardA
PROPERTY 1 cardA title A
NODE 1 cardB cardB
PROPERTY 1 cardB title B
END
"""

private let UI_DOC_TEST_MERGE_FILE = """
GENERATED_UI_STRUCTURE 2
COMPOSITION cardA 64 6
CPARAM title STRING 0 0 40 40 A1
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=2
CTEMPLATE 1 name element element=name presentation=text
COMPOSITION_END cardA
NODE 0 board vertical
NODE 1 cardA cardA
PROPERTY 1 cardA title A1
END
"""

@Test
func uiDocumentPreviewKeepsMergeAndReplaceDistinct(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "merge.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let merge = session.previewReload(surface)
        @Assert(merge.applied, true)
        let mergePreview = session.preview().getOrThrow()
        @Assert(mergePreview.policy, CJGUI_UI_DOCUMENT_POLICY_MERGE)
        @Assert(mergePreview.removals.size, 0)
        @Assert(mergePreview.expectedText.contains("COMPOSITION cardB"), true)
        @Assert(mergePreview.expectedText.contains("NODE 1 cardB cardB"), false)
        let mergeText = session.previewText()
        @Assert(mergeText.contains("保留定义 cardB"), true)
        @Assert(mergeText.contains("移除定义 cardB"), false)
        let replace = session.previewReload(surface, policy: CJGUI_UI_DOCUMENT_POLICY_REPLACE)
        @Assert(replace.applied, true)
        let replacePreview = session.preview().getOrThrow()
        @Assert(replacePreview.removals.size, 1)
        @Assert(replacePreview.removals[0], "cardB")
        @Assert(replacePreview.expectedText.contains("COMPOSITION cardB"), false)
        @Assert(replacePreview.candidateText.contains("COMPOSITION_REMOVE cardB"), true)
        @Assert(replacePreview.candidateDigest != replacePreview.expectedDigest, true)
        @Assert(session.previewText().contains("移除定义 cardB"), true)
        @Assert(surface.submits, 0)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentSessionSubmitsOneTicketAndSettlesOnlyItsOwnResult(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "accept.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let preview = session.previewReload(surface)
        @Assert(preview.applied, true)
        let expected = session.preview().getOrThrow()
        let first = session.confirmReload(surface)
        @Assert(first.submitted, true)
        @Assert(surface.submits, 1)
        let again = session.confirmReload(surface)
        @Assert(again.submitted, false)
        @Assert(again.reason, "ui_document_already_submitted")
        @Assert(surface.submits, 1)
        let cancel = session.cancelPreview()
        @Assert(cancel.applied, false)
        @Assert(cancel.reason, "ui_document_submitted")
        @Assert(session.finishReload(surface).reason, "ui_document_pending")
        // Another operation accepting these same bytes is NOT this ticket.
        surface.text = expected.expectedText
        surface.version = 9
        @Assert(session.finishReload(surface).reason, "ui_document_pending")
        surface.settleRejected(surface.lastToken, "catalog_missing")
        let rejected = session.finishReload(surface)
        @Assert(rejected.applied, false)
        @Assert(rejected.accepted, false)
        @Assert(rejected.reason, "ui_document_rejected:catalog_missing")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentSessionAcceptsOnlyTheExpectedCompleteDocument(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "settle.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let _ = session.previewReload(surface)
        let expected = session.preview().getOrThrow()
        let confirmation = session.confirmReload(surface)
        @Assert(confirmation.submitted, true)
        surface.settleAccepted(expected.expectedText, expected.expectedVersion, surface.lastToken)
        let settled = session.finishReload(surface)
        @Assert(settled.accepted, true)
        @Assert(settled.reason, "accepted")
        // The file baseline is the file actually read, not the merged
        // expected document: retaining cardB keeps the surface dirty.
        @Assert(session.savedDigest(), expected.fileDigest)
        @Assert(session.savedBaseline(), expected.expectedVersion)
        @Assert(session.stateFor(surface).unsaved, true)
        @Assert(session.stateFor(surface).acceptedDigest, expected.expectedDigest)
        // The candidate really was the file text; the expected digest is the
        // complete document with the retained definition.
        @Assert(surface.lastCandidate == expected.candidateText, true)
        @Assert(surface.lastExpectedVersion, expected.acceptedVersion)
        @Assert(surface.lastCandidate != expected.expectedText, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentPreviewCancelSubmitsNothing(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "cancel.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        @Assert(session.previewReload(surface).applied, true)
        let cancelled = session.cancelPreview()
        @Assert(cancelled.applied, true)
        @Assert(cancelled.reason, "cancelled")
        @Assert(surface.submits, 0)
        @Assert(session.confirmReload(surface).reason, "ui_document_no_preview")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentDiffReportsReorderAndEveryDefinitionField(): Unit {
    let base = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 a label
PROPERTY 1 a text A
NODE 1 b label
PROPERTY 1 b text B
END
"""
    let reordered = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 b label
PROPERTY 1 b text B
NODE 1 a label
PROPERTY 1 a text A
END
"""
    let reorderDiff = cjguiUiDocumentDiffLines(base, reordered)
    @Assert(uiDocumentTestHasLine(reorderDiff, "重排节点 b：1 -> 0"), true)
    @Assert(uiDocumentTestHasLine(reorderDiff, "重排节点 a：0 -> 1"), true)
    let definitionBase = """
GENERATED_UI_STRUCTURE 2
COMPOSITION card 64 6
CPARAM title STRING 0 0 40 40 A
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=2
CTEMPLATE 1 name element element=name presentation=text
COMPOSITION_END card
NODE 0 board vertical
END
"""
    let definitionChanged = """
GENERATED_UI_STRUCTURE 2
COMPOSITION card 64 6
CPARAM title INTEGER 1 0 40 40 B
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=8
CTEMPLATE 1 name element element=name presentation=select
COMPOSITION_END card
NODE 0 board vertical
END
"""
    let definitionDiff = cjguiUiDocumentDiffLines(definitionBase, definitionChanged)
    @Assert(uiDocumentTestHasLine(definitionDiff, "修改定义 card"), true)
    @Assert(uiDocumentTestHasLine(definitionDiff, "参数 title 类型: STRING -> INTEGER"), true)
    @Assert(uiDocumentTestHasLine(definitionDiff, "参数 title 必填: false -> true"), true)
    @Assert(uiDocumentTestHasLine(definitionDiff, "参数 title 默认值: A -> B"), true)
    @Assert(uiDocumentTestHasLine(definitionDiff, "模板 root gap: 2 -> 8"), true)
    @Assert(uiDocumentTestHasLine(definitionDiff, "模板 name 呈现: text -> select"), true)
    @Assert(cjguiUiDocumentDiffLines(definitionBase,
        definitionBase).size, 0)
}

@Test
func uiDocumentNoChangePreviewOnlyAdoptsTheFile(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "same.ui.json", UI_DOC_TEST_MERGE_BASE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let preview = session.previewReload(surface)
        @Assert(preview.applied, true)
        @Assert(preview.reason, "ui_document_no_changes")
        @Assert(session.confirmReload(surface).reason, "ui_document_file_adopted")
        @Assert(surface.submits, 0)
        @Assert(session.savedDigest().size, 64)
        @Assert(session.stateFor(surface).unsaved, false)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentMergeAcceptsButStaysDirtyAndPathSwitchClearsBaseline(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "merge-dirty.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let _ = session.previewReload(surface)
        let expected = session.preview().getOrThrow()
        let _ = session.confirmReload(surface)
        surface.settleAccepted(expected.expectedText, expected.expectedVersion, surface.lastToken)
        @Assert(session.finishReload(surface).accepted, true)
        let state = session.stateFor(surface)
        @Assert(state.unsaved, true)
        @Assert(state.savedDigest, expected.fileDigest)
        session.setPath(directory.join("other.ui.json").toString())
        @Assert(session.savedDigest(), "")
        @Assert(session.stateFor(surface).unsaved, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentSessionRefusesToRetargetAnotherSurface(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "surface.ui.json", UI_DOC_TEST_MERGE_FILE)
        let first = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let second = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        @Assert(session.previewReload(first).applied, true)
        let swapped = session.confirmReload(second)
        @Assert(swapped.applied, false)
        @Assert(swapped.reason, "ui_document_surface_mismatch")
        @Assert(second.submits, 0)
        @Assert(first.submits, 0)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentSaveAsAndConflictKeepTheOldAssociation(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let first = directory.join("first.ui.json").toString()
        let second = directory.join("second.ui.json").toString()
        let session = CjguiGeneratedUiDocumentSession(path: first)
        @Assert(session.closeDecision(surface).reason, "ui_document_unsaved")
        @Assert(session.save(surface).reason, "saved")
        @Assert(session.closeDecision(surface).canClose, true)
        // An external writer changes the current file; ordinary save must not
        // silently overwrite it.
        let _ = uiDocumentTestExport(directory, "first.ui.json", UI_DOC_TEST_MERGE_FILE)
        @Assert(session.save(surface).reason, "ui_document_save_conflict")
        @Assert(session.path(), first)
        @Assert(session.saveAs(surface, second).reason, "saved_as")
        @Assert(session.path(), second)
        @Assert(session.savedDigest().size, 64)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentScopedWorkspacesRouteCommandsIndependently(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let first = uiDocumentTestExport(directory, "a.ui.json", UI_DOC_TEST_MERGE_FILE)
        let second = uiDocumentTestExport(directory, "b.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let scope = CjguiComposableUiIdentityScope("two-workspaces")
        let firstSession = CjguiGeneratedUiDocumentSession(path: first)
        let secondSession = CjguiGeneratedUiDocumentSession(path: second)
        let firstWorkspace = CjguiUiDocumentWorkspace(scope, "first",
            firstSession, surface)
        let secondWorkspace = CjguiUiDocumentWorkspace(scope, "second",
            secondSession, surface)
        @Assert(firstWorkspace.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE) !=
            secondWorkspace.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE), true)
        @Assert(firstWorkspace.ownsCommand(firstWorkspace.commandId(
            CJGUI_UI_DOCUMENT_ACTION_SAVE)), true)
        @Assert(firstWorkspace.ownsCommand(secondWorkspace.commandId(
            CJGUI_UI_DOCUMENT_ACTION_SAVE)), false)
        // A bare action token is not a command id for either branch.
        @Assert(firstWorkspace.ownsCommand(CJGUI_UI_DOCUMENT_ACTION_SAVE), false)
        @Assert(secondWorkspace.handleCommand(firstWorkspace.commandId(
            CJGUI_UI_DOCUMENT_ACTION_SAVE)).isNone(), true)
        // Scoped workspaces carry distinct scoped identities, not distinct
        // numeric pools: the SAME scope rebuilt answers the same identity.
        let firstKey = firstWorkspace.nodeReference(CJGUI_UI_DOCUMENT_ACTION_SAVE)
            .scopedIdentity().getOrThrow().canonicalKey()
        let secondKey = secondWorkspace.nodeReference(CJGUI_UI_DOCUMENT_ACTION_SAVE)
            .scopedIdentity().getOrThrow().canonicalKey()
        @Assert(firstKey != secondKey, true)
        @Assert(CjguiUiDocumentWorkspace(
            scope, "first", firstSession, surface).nodeReference(
            CJGUI_UI_DOCUMENT_ACTION_SAVE).scopedIdentity().getOrThrow().canonicalKey(),
            firstKey)
        @Assert(firstSession.saveAs(surface, directory.join("a-saved.ui.json").toString()).applied, true)
        @Assert(secondSession.path(), second)
        @Assert(secondSession.savedDigest(), "")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

// --- DS51 continuation: lossless semantics, write protection, settlement ---

private let UI_DOC_TEST_EMPTY_DEFAULT_BASE = """
GENERATED_UI_STRUCTURE 2
COMPOSITION card 64 6
CPARAM title STRING 0 0 40 40 \\e
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=2
CTEMPLATE 1 name element element=name presentation=text
COMPOSITION_END card
NODE 0 board vertical
END
"""

private let UI_DOC_TEST_LITERAL_DEFAULT_FILE = """
GENERATED_UI_STRUCTURE 2
COMPOSITION card 64 6
CPARAM title STRING 0 0 40 40 空
CELEMENT name field field=label argument=text
CTEMPLATE 0 root vertical gap=2
CTEMPLATE 1 name element element=name presentation=text
COMPOSITION_END card
NODE 0 board vertical
END
"""

private func uiDocumentUnicodeFixture(defaultValue: String): String {
    return "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION card 64 6\n" +
        "CPARAM title STRING 0 0 200 200 ${defaultValue}\n" +
        "CELEMENT name field field=label argument=text\n" +
        "CTEMPLATE 0 root vertical gap=2\n" +
        "CTEMPLATE 1 name element element=name presentation=text\n" +
        "COMPOSITION_END card\n" +
        "NODE 0 board vertical\n" +
        "END\n"
}

private let UI_DOC_TEST_UNICODE_A = uiDocumentUnicodeFixture("A中文测试")
private let UI_DOC_TEST_UNICODE_B = uiDocumentUnicodeFixture("B中文测试")
private let UI_DOC_TEST_UNICODE_TAIL_A = uiDocumentUnicodeFixture("commonprefixcommonprefixTAILA")
private let UI_DOC_TEST_UNICODE_TAIL_B = uiDocumentUnicodeFixture("commonprefixcommonprefixTAILB")
private let UI_DOC_TEST_UNICODE_MIDDLE_A =
    uiDocumentUnicodeFixture("0123456789abcdefghijMIDDLEA0123456789abcdefghij")
private let UI_DOC_TEST_UNICODE_MIDDLE_B =
    uiDocumentUnicodeFixture("0123456789abcdefghijMIDDLEB0123456789abcdefghij")

@Test
func uiDocumentUnicodePreviewIsLegalAndDistinguishesLongValues(): Unit {
    // The old fixed 12-BYTE slice split 中文 and threw while rendering legal
    // values. Both the diff and the preview must stay legal and readable.
    let unicodeDiff = cjguiUiDocumentDiffLines(UI_DOC_TEST_UNICODE_A, UI_DOC_TEST_UNICODE_B)
    var unicodeText = ""
    for (line in unicodeDiff) {
        unicodeText += line + "\n"
    }
    @Assert(unicodeDiff.size > 0, true)
    @Assert(unicodeText.contains("A中文测试"), true)
    @Assert(unicodeText.contains("B中文测试"), true)

    // A long shared prefix must not make different tails render identically.
    let tailDiff = cjguiUiDocumentDiffLines(UI_DOC_TEST_UNICODE_TAIL_A, UI_DOC_TEST_UNICODE_TAIL_B)
    var tailLine = ""
    for (line in tailDiff) {
        if (line.contains("默认值")) { tailLine = line }
    }
    @Assert(tailLine.contains("TAILA"), true)
    @Assert(tailLine.contains("TAILB"), true)
    @Assert(tailLine.contains("…"), true)

    // Same length and prefix but a middle difference is shown, not only a hash.
    let middleDiff = cjguiUiDocumentDiffLines(UI_DOC_TEST_UNICODE_MIDDLE_A,
        UI_DOC_TEST_UNICODE_MIDDLE_B)
    var middleLine = ""
    for (line in middleDiff) {
        if (line.contains("默认值")) { middleLine = line }
    }
    @Assert(middleLine.contains("MIDDLEA"), true)
    @Assert(middleLine.contains("MIDDLEB"), true)

    // A genuinely identical Unicode document is still a zero-line diff.
    @Assert(cjguiUiDocumentDiffLines(UI_DOC_TEST_UNICODE_A, UI_DOC_TEST_UNICODE_A).size, 0)
}

@Test
func uiDocumentEmptyDefaultIsNotTheLiteralEmptyText(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        // The display text must show the two defaults distinctly; a lossless
        // fact comparison must report a real definition change.
        let diff = cjguiUiDocumentDiffLines(UI_DOC_TEST_EMPTY_DEFAULT_BASE,
            UI_DOC_TEST_LITERAL_DEFAULT_FILE)
        @Assert(uiDocumentTestHasLine(diff, "修改定义 card"), true)
        @Assert(uiDocumentTestHasLine(diff, "参数 title 默认值: <空字符串> -> 空"), true)
        @Assert(diff.size > 0, true)
        // A truly identical input is still a semantic no-op.
        @Assert(cjguiUiDocumentDiffLines(UI_DOC_TEST_EMPTY_DEFAULT_BASE,
            UI_DOC_TEST_EMPTY_DEFAULT_BASE).size, 0)
        // The real workflow: preview reports a change and confirm submits ONCE;
        // re-previewing the same file afterwards is a zero-submit adoption.
        let path = uiDocumentTestExport(directory, "literal.ui.json",
            UI_DOC_TEST_LITERAL_DEFAULT_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_EMPTY_DEFAULT_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let preview = session.previewReload(surface)
        @Assert(preview.applied, true)
        @Assert(preview.reason, "preview")
        let expected = session.preview().getOrThrow()
        @Assert(expected.changed, true)
        let confirmation = session.confirmReload(surface)
        @Assert(confirmation.submitted, true)
        @Assert(surface.submits, 1)
        surface.settleAccepted(expected.expectedText, expected.expectedVersion, surface.lastToken)
        let settled = session.finishReload(surface)
        @Assert(settled.accepted, true)
        // The accepted definition now carries the literal 空 default.
        @Assert(surface.text.contains("CPARAM title STRING 0 0 40 40 空"), true)
        let again = session.previewReloadPath(surface, path,
            policy: CJGUI_UI_DOCUMENT_POLICY_MERGE)
        @Assert(again.reason, "ui_document_no_changes")
        @Assert(session.confirmReload(surface).reason, "ui_document_file_adopted")
        @Assert(surface.submits, 1)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentSaveAsCannotBypassExistingTargetProtection(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let first = directory.join("first.ui.json").toString()
        let session = CjguiGeneratedUiDocumentSession(path: first)
        @Assert(session.save(surface).reason, "saved")
        let savedFirst = File.readFrom(first).toArray()
        // External writer changes the current file; ordinary save refuses...
        let _ = uiDocumentTestExport(directory, "first.ui.json", UI_DOC_TEST_MERGE_FILE)
        @Assert(session.save(surface).reason, "ui_document_save_conflict")
        // ...and saveAs to the SAME path must not become an overwrite permit.
        let samePath = session.saveAs(surface, first)
        @Assert(samePath.applied, false)
        @Assert(samePath.reason, "ui_document_save_conflict")
        // The external bytes survive.
        @Assert(File.readFrom(first).toArray() == File.readFrom(
            uiDocumentTestExport(directory, "check-external.ui.json",
                UI_DOC_TEST_MERGE_FILE)).toArray(), true)
        // A DIFFERENT existing target without a trusted observation is a named
        // refusal, whatever the empty/full baseline state is.
        let existingOther = uiDocumentTestExport(directory, "other.ui.json",
            UI_DOC_TEST_MERGE_FILE)
        let refused = session.saveAs(surface, existingOther)
        @Assert(refused.applied, false)
        @Assert(refused.reason, "ui_document_save_as_target_exists")
        // First-time association with an existing file also cannot save over
        // it: an empty baseline grants no overwrite right.
        let fresh = CjguiGeneratedUiDocumentSession(path: existingOther)
        @Assert(fresh.save(surface).reason, "ui_document_save_target_exists")
        // A brand-new path still saves and switches the association.
        let created = directory.join("created 目录 中文.ui.json").toString()
        @Assert(session.saveAs(surface, created).reason, "saved_as")
        @Assert(session.path(), created)
        @Assert(exists(Path(existingOther)), true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentAcceptedThenChangedKeepsTheOriginalAssociation(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        // Associate A and save it, so a REAL file baseline exists.
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let pathA = directory.join("a.ui.json").toString()
        let pathB = uiDocumentTestExport(directory, "b.ui.json", UI_DOC_TEST_MERGE_FILE)
        let session = CjguiGeneratedUiDocumentSession(path: pathA)
        @Assert(session.save(surface).reason, "saved")
        let baselineA = session.savedDigest()
        // Open B as one operation; A's association stays while previewing.
        @Assert(session.previewReloadPath(surface, pathB,
            policy: CJGUI_UI_DOCUMENT_POLICY_MERGE).applied, true)
        let expected = session.preview().getOrThrow()
        @Assert(session.path(), pathA)
        let _ = session.confirmReload(surface)
        // The ticket WAS accepted at the expected version, but a later change
        // already moved the accepted document on.
        surface.settleAccepted(expected.expectedText, expected.expectedVersion, surface.lastToken)
        surface.text = UI_DOC_TEST_LITERAL_DEFAULT_FILE
        surface.version = expected.expectedVersion + 5
        let settled = session.finishReload(surface)
        @Assert(settled.accepted, false)
        @Assert(settled.reason, "accepted_then_changed")
        // The original A association and its REAL file baseline are retained;
        // nothing about B or the new current state is recorded as saved.
        @Assert(session.path(), pathA)
        @Assert(session.savedDigest(), baselineA)
        @Assert(session.stateFor(surface).unsaved, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentFinishRefusesATicketAnswerForAnotherToken(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "token.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        let _ = session.previewReload(surface)
        let expected = session.preview().getOrThrow()
        let _ = session.confirmReload(surface)
        surface.settleAccepted(expected.expectedText, expected.expectedVersion, surface.lastToken)
        // A surface that answers with ANOTHER token's fact cannot settle this
        // operation, even when every other field looks exact.
        surface.ticketTokenOffset = 1
        let mismatch = session.finishReload(surface)
        @Assert(mismatch.applied, false)
        @Assert(mismatch.reason, "ui_document_ticket_mismatch")
        // The operation is still in flight; the honest answer returns once
        // the surface reports the frozen token again.
        surface.ticketTokenOffset = 0
        @Assert(session.finishReload(surface).reason, "accepted")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentCloseGuardSavesDiscardsAndChecksEveryWorkspace(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let surfaceA = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let surfaceB = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let pathA = directory.join("guard-a.ui.json").toString()
        let pathB = directory.join("guard-b.ui.json").toString()
        let sessionA = CjguiGeneratedUiDocumentSession(path: pathA)
        let sessionB = CjguiGeneratedUiDocumentSession(path: pathB)
        @Assert(sessionA.save(surfaceA).applied, true)
        @Assert(sessionB.save(surfaceB).applied, true)
        let scope = CjguiComposableUiIdentityScope("guard")
        let workspaceA = CjguiUiDocumentWorkspace(scope, "a", sessionA, surfaceA, title: "区域一")
        let workspaceB = CjguiUiDocumentWorkspace(scope, "b", sessionB, surfaceB, title: "区域二")
        let guard = CjguiUiDocumentCloseGuard()
        guard.add(workspaceA)
        guard.add(workspaceB)
        @Assert(guard.workspaceCount(), 2)
        @Assert(guard.settleAndReport(), "")
        // A real change in the SECOND workspace must block, not just the first.
        surfaceB.text = UI_DOC_TEST_MERGE_FILE
        surfaceB.version = 2
        let blocked = guard.settleAndReport()
        @Assert(blocked.contains("区域二"), true)
        @Assert(blocked.contains("未保存"), true)
        // Saving every workspace uses the ordinary protected save; A is
        // already clean and must not be written again.
        let savedA = File.readFrom(pathA).toArray()
        @Assert(guard.saveUnsaved({ _ => "" }), "")
        @Assert(File.readFrom(pathA).toArray() == savedA, true)
        @Assert(guard.settleAndReport(), "")
        // New changes after the panel appears still block.
        surfaceB.text = UI_DOC_TEST_LITERAL_DEFAULT_FILE
        surfaceB.version = 3
        @Assert(guard.settleAndReport().contains("未保存"), true)
        // Explicit discard is one-shot: it releases THIS close attempt, then
        // a later close (after a business refusal) protects the facts again.
        guard.discardUnsaved()
        @Assert(guard.settleAndReport(), "")
        @Assert(guard.settleAndReport().contains("未保存"), true)
        guard.discardUnsaved()
        @Assert(guard.settleAndReport(), "")
        // An in-flight submitted ticket still refuses, even with discard.
        let surfaceC = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let pathC = uiDocumentTestExport(directory, "guard-c.ui.json", UI_DOC_TEST_MERGE_FILE)
        let sessionC = CjguiGeneratedUiDocumentSession()
        let workspaceC = CjguiUiDocumentWorkspace(scope, "c", sessionC, surfaceC, title: "区域三")
        let preview = sessionC.previewReloadPath(surfaceC, pathC,
            policy: CJGUI_UI_DOCUMENT_POLICY_MERGE)
        @Assert(preview.applied, true)
        let confirmation = sessionC.confirmReload(surfaceC)
        @Assert(confirmation.submitted, true)
        let pendingGuard = CjguiUiDocumentCloseGuard()
        pendingGuard.add(workspaceC)
        pendingGuard.discardUnsaved()
        let pending = pendingGuard.settleAndReport()
        @Assert(pending.contains("区域三"), true)
        @Assert(pending.contains("结算"), true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func uiDocumentScopedBuildUsesRealScopeIdentitiesAndActivationActions(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = uiDocumentTestExport(directory, "scoped.ui.json", UI_DOC_TEST_MERGE_FILE)
        let surface = UiDocumentTestSurface(UI_DOC_TEST_MERGE_BASE)
        let session = CjguiGeneratedUiDocumentSession(path: path)
        // `a--b` (one root key) and `a.child("b")` (nested) share diagnostic
        // text but are DIFFERENT canonical identities; their command ids and
        // node identities must never collide.
        let dashed = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("a--b"), "doc", session, surface)
        let nested = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("a").child("b"), "doc", session, surface)
        @Assert(dashed.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE) !=
            nested.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE), true)
        @Assert(dashed.ownsCommand(nested.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE)), false)
        // The built button really asks for THIS workspace's command through
        // the public activation codec, and every node carries a scoped
        // identity instead of a fabricated numeric id.
        let theme = CjguiComposableUiTheme.beaconDark()
        let tree = dashed.build(theme.card, theme.heading, theme.body, theme.primaryAction)
        @Assert(tree.children().size >= 3, true)
        let buttons = tree.children()[1].children()
        @Assert(buttons.size, 5)
        let saveCommand = dashed.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE)
        var matched = 0
        for (button in buttons) {
            let decoded = cjguiCommandToolbarCommandId(button.actionName)
            @Assert(decoded.isSome(), true)
            if (decoded.getOrThrow() == saveCommand) { matched += 1 }
            @Assert(button.nodeId >= 0, false)
        }
        @Assert(matched, 1)
        // The command projection derives from the REAL action states and
        // targets the scoped nodes; disabled reasons ride along. The two file
        // entries are part of the same projection, with real scoped targets.
        let declarations = dashed.commandDeclarations()
        @Assert(declarations.size, 7)
        var sawOpen = false
        var sawSaveAs = false
        for (declaration in declarations) {
            @Assert(dashed.ownsCommand(declaration.id), true)
            @Assert(declaration.targetReference.isValid(), true)
            if (declaration.id == dashed.pathCommandId()) { sawOpen = true }
            if (declaration.id == dashed.pathCommandId(open: false)) { sawSaveAs = true }
        }
        @Assert(sawOpen, true)
        @Assert(sawSaveAs, true)
        let metadata = dashed.commandMetadata(-7)
        @Assert(metadata.size, 7)
        // The path row really carries these command ids and no numeric ids.
        let row = dashed.buildPathRow("", theme.input, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction)
        @Assert(row.children().size, 3)
        @Assert(cjguiCommandToolbarCommandId(row.children()[1].actionName).getOrThrow(),
            dashed.pathCommandId())
        @Assert(cjguiCommandToolbarCommandId(row.children()[2].actionName).getOrThrow(),
            dashed.pathCommandId(open: false))
        for (child in row.children()) {
            @Assert(child.nodeId >= 0, false)
        }
        // The manual branch keeps its documented numeric compatibility.
        let manual = CjguiUiDocumentWorkspace(session, surface, "manual-doc",
            1, "manual-doc")
        @Assert(manual.nodeReference(CJGUI_UI_DOCUMENT_ACTION_OPEN).manualNodeId(), 13)
        @Assert(manual.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE_AS), "manual-doc.save-as")
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}
