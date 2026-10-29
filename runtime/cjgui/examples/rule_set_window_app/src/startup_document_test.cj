package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.convert.*
import std.fs.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private func startupDocumentText(label: String): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\n" +
        "NODE 1 title label\nPROPERTY 1 title text ${label}\nEND\n"
}

private func startupDocumentWrite(path: Path, label: String): String {
    let exported = cjguiExportUiDocument(startupDocumentText(label))
    @Assert(exported.ok, true)
    File.writeTo(path, exported.text.toArray())
    return exported.digest
}

// Arrive through the shipping controller's existing scoped document commands.
// No test-only session setter or fabricated accepted/ticket fact is used.
private func startupDocumentCommand(controller: CjguiRuleSetComposableController, suffix: String): Bool {
    let commands = CjguiUiDocumentWorkspace(CjguiComposableUiIdentityScope("rule-set"), "ui-document",
        CjguiGeneratedUiDocumentSession(), controller.generatedUiRegion())
    let command = commands.commandId(if (suffix == "save") {
        CJGUI_UI_DOCUMENT_ACTION_SAVE
    } else {
        CJGUI_UI_DOCUMENT_ACTION_RESTORE
    })
    return controller
        .applyUiEvent(
            CjguiComposableUiEvent(CjguiComposableUiLayoutNode.missing(), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, command, 0,
                0, 0))
        .didApply
}

private func startupDocumentToken(region: CjguiRuleSetGeneratedRegion): Int64 {
    for (line in region.candidateTicketForDiagnosis().split("\n")) {
        if (line.startsWith("CANDIDATE_TOKEN ")) {
            return Int64.parse(line[16..line.size])
        }
    }
    throw IllegalStateException("document submission has no ticket")
}

private func startupDocumentBegin(controller: CjguiRuleSetComposableController, path: String): Int64 {
    let submitted = controller.beginStartupUiDocument(path)
    @Assert(submitted.submitted, true)
    @Assert(controller.generatedUiRegion().uiDocumentTicket(submitted.token).terminalState, "PENDING")
    return submitted.token
}

// Commit through the real region transaction. The test controls WHEN a scene
// accepts, while the region supplies all ticket/version/digest facts itself.
private func startupDocumentCommit(region: CjguiRuleSetGeneratedRegion): Unit {
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildSection(CjguiComposableUiTheme.paperLight(), CjguiComposableUiStyle())
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
}

@Test
func startupDocumentBusinessCloseRefusalKeepsExactLoadedOutcome(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("close-race.ui.json")
        let text = startupDocumentText("close race")
        let exported = cjguiExportUiDocument(text[0..text.size - 1])
        @Assert(exported.ok, true)
        File.writeTo(path, exported.text.toArray())
        let domain = CjguiRuleSetEditingDomain.newUntitled()
        @Assert(domain.createRecordFromHuman("unsaved business", true, 7,
            "cache", "startup-close-race").applied, true)
        let controller = CjguiRuleSetComposableController(domain, uiDocument: path.toString())
        @Assert(controller.beginStartupUiDocument(path.toString()).submitted, true)
        let region = controller.generatedUiRegion()
        startupDocumentCommit(region)
        @Assert(region.acceptedUiDocument().digest, exported.digest)
        // A native close callback can arrive before the ordinary finisher.
        // Only business data blocks this close; UI settlement must still be
        // recorded by the startup observer exactly once.
        @Assert(controller.requestWindowClose().shouldClose, false)
        let _ = controller.settleStartupDocument()
        @Assert(controller.uiDocumentLoaded(), true)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(cjguiReadUiDocument(path.toString()).structureSha256, exported.digest)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func startupDocumentPendingHandoffCompletesOnHostWake(): Unit {
    cjguiMacosOwnerTest(
        {
            =>
                let directory = Directory.createTemp("/tmp")
                let path = directory.join("host-wake.ui.json")
                let digest = startupDocumentWrite(path, "host wake")
                let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
                    uiDocument: path.toString())
                let host = CjguiMacosApplicationHost(controller,
                    configuration: CjguiMacosApplicationWindowConfiguration("DS16 Startup completion", 980u32, 620u32))
                let window = host.window()
                let region = controller.generatedUiRegion()
                region.attachWindow(window)
                controller.bindWindow(window)
                try {
                    @Assert(host.start(), true)
                    let readiness = MonoTime.now()
                    while (window.windowProgress().acceptedSceneVersion <= 0 &&
                            (MonoTime.now() - readiness).toMilliseconds() < 2500) {
                        let remaining = max(1, 2500 - (MonoTime.now() - readiness).toMilliseconds())
                        let _ = host.pumpUntilWork(timeoutMs: UInt32(remaining))
                    }
                    @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
                    @Assert(controller.beginStartupUiDocument(path.toString()).submitted, true)
                    let token = startupDocumentToken(region)
                    @Assert(region.uiDocumentTicket(token).terminalState, "PENDING")
                    // Model the bounded-pump handoff with the SAME held submission.
                    // No manual scene commit, extra input, delay or resubmission.
                    let waiting = MonoTime.now()
                    var turns: Int64 = 0
                    while (controller.hasPendingStartupDocument() && host.isOpen() &&
                            (MonoTime.now() - waiting).toMilliseconds() < 5000) {
                        let remaining = max(1, 5000 - (MonoTime.now() - waiting).toMilliseconds())
                        let _ = host.pumpUntilWork(timeoutMs: UInt32(remaining))
                        controller.finishUiDocumentAction(window)
                        turns += 1
                    }
                    @Assert(controller.hasPendingStartupDocument(), false)
                    @Assert(controller.uiDocumentLoaded(), true)
                    @Assert(region.uiDocumentTicket(token).acceptedVersion, 1)
                    @Assert(startupDocumentToken(region), token)
                    @Assert(startupDocumentCommand(controller, "save"), true)
                    print(
                        "STARTUP_DOCUMENT_HOST_WAKE token=${token} turns=${turns} " +
                            "version=${region.acceptedStructureVersion()}\n")
                    @Assert(host.requestClose(), true)
                } finally {
                    host.close()
                    let _ = removeIfExists(directory, recursive: true)
                }
        }
    )
}

@Test
func startupDocumentLateExactAcceptanceSettlesOnceThroughSession(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("startup.ui.json")
        let digest = startupDocumentWrite(path, "startup")
        let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
            uiDocument: path.toString())
        let region = controller.generatedUiRegion()
        let token = startupDocumentBegin(controller, path.toString())
        // The startup budget has already expired. More ordinary completion
        // checks neither submit again nor invent a refusal or file baseline.
        for (_ in 0..3) {
            controller.settleStartupDocument()
        }
        @Assert(controller.hasPendingStartupDocument(), true)
        @Assert(controller.uiDocumentLoaded(), false)
        @Assert(startupDocumentCommand(controller, "save"), false)
        @Assert(startupDocumentToken(region), token)
        startupDocumentCommit(region)
        // This file deliberately has a trailing newline that the accepted
        // encoder omits: its real file observation is NOT the expected digest.
        @Assert(digest != region.acceptedUiDocument().digest, true)
        controller.settleStartupDocument()
        @Assert(controller.uiDocumentLoaded(), true)
        @Assert(controller.hasPendingStartupDocument(), false)
        // Saving the existing file succeeds only if the REAL session adopted
        // its observed baseline, rather than merely setting a loaded flag.
        @Assert(startupDocumentCommand(controller, "save"), true)
        controller.settleStartupDocument()
        @Assert(startupDocumentToken(region), token)
        @Assert(region.acceptedStructureVersion(), 1)
        let _ = startupDocumentWrite(path, "external writer")
        @Assert(startupDocumentCommand(controller, "save"), false)
        @Assert(cjguiReadUiDocument(path.toString()).structureText.contains("external writer"), true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func startupDocumentApplicationEntryFinishesOnOrdinaryTurn(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("startup.ui.json")
        let _ = startupDocumentWrite(path, "entry")
        let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
            uiDocument: path.toString())
        let window = CjguiMacosApplicationHost(controller).window()
        let region = controller.generatedUiRegion()
        @Assert(controller.beginStartupUiDocument(path.toString()).submitted, true)
        let token = startupDocumentToken(region)
        // No native window or keyboard wake is needed to test this application
        // completion seam; real render acceptance remains the region's fact.
        controller.finishUiDocumentAction(window)
        @Assert(controller.hasPendingStartupDocument(), true)
        startupDocumentCommit(region)
        controller.finishUiDocumentAction(window)
        @Assert(controller.uiDocumentLoaded(), true)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(startupDocumentCommand(controller, "save"), true)
        controller.finishUiDocumentAction(window)
        @Assert(startupDocumentToken(region), token)
        @Assert(controller.requestWindowClose().shouldClose, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func startupDocumentEmptyFileAdoptsWithoutCandidateOrSeed(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("empty.ui.json")
        let exported = cjguiExportUiDocument("GENERATED_UI_STRUCTURE 1\nEND")
        @Assert(exported.ok, true)
        File.writeTo(path, exported.text.toArray())
        let domain = CjguiRuleSetEditingDomain.newUntitled()
        @Assert(domain.createRecordFromHuman("seed would have content", true, 7,
            "cache", "empty-startup").applied, true)
        let controller = CjguiRuleSetComposableController(domain, uiDocument: path.toString())
        let result = controller.beginStartupUiDocument(path.toString())
        @Assert(result.reason, "ui_document_file_adopted")
        @Assert(result.submitted, false)
        @Assert(controller.uiDocumentLoaded(), true)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(controller.ensureDefaultGeneratedDetail(), "")
        @Assert(controller.generatedUiRegion().acceptedStructureVersion(), 0)
        @Assert(startupDocumentCommand(controller, "save"), true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func startupDocumentClosedTicketRefusesWithoutFileBaseline(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("closed.ui.json")
        let digest = startupDocumentWrite(path, "closed")
        let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
            uiDocument: path.toString())
        @Assert(controller.beginStartupUiDocument(path.toString()).submitted, true)
        controller.generatedUiRegion().releaseImageIdentities()
        let done = controller.settleStartupDocument()
        @Assert(done.reason, "ui_document_rejected:window_closed")
        @Assert(controller.uiDocumentLoaded(), false)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(startupDocumentCommand(controller, "save"), false)
        @Assert(cjguiReadUiDocument(path.toString()).structureSha256, digest)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func startupDocumentSupersededTicketDoesNotAdoptReplacement(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("superseded.ui.json")
        let digest = startupDocumentWrite(path, "startup")
        let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
            uiDocument: path.toString())
        @Assert(controller.beginStartupUiDocument(path.toString()).submitted, true)
        let region = controller.generatedUiRegion()
        let replacement = region.submitStructure(startupDocumentText("replacement"), 0)
        @Assert(replacement.candidateAccepted, true)
        @Assert(controller.settleStartupDocument().reason, "ui_document_superseded")
        @Assert(controller.uiDocumentLoaded(), false)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(region.uiDocumentTicket(replacement.candidateToken).terminalState, "PENDING")
        startupDocumentCommit(region)
        @Assert(startupDocumentCommand(controller, "save"), false)
        @Assert(cjguiReadUiDocument(path.toString()).structureSha256, digest)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func startupDocumentAcceptedThenChangedKeepsFileUnadopted(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("startup.ui.json")
        let digest = startupDocumentWrite(path, "startup")
        let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
            uiDocument: path.toString())
        let region = controller.generatedUiRegion()
        let token = startupDocumentBegin(controller, path.toString())
        startupDocumentCommit(region)
        let changed = region.submitStructure(startupDocumentText("later document"), 1)
        @Assert(changed.candidateAccepted, true)
        startupDocumentCommit(region)
        @Assert(region.uiDocumentTicket(token).acceptedVersion, 1)
        @Assert(region.uiDocumentTicket(token).currentVersion, 2)
        controller.settleStartupDocument()
        @Assert(controller.uiDocumentLoaded(), false)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(startupDocumentCommand(controller, "save"), false)
        @Assert(cjguiReadUiDocument(path.toString()).structureSha256, digest)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

// UNKNOWN belongs to the public session operation now; its unchanged pending
// expectation is covered by uiDocumentLifecycleUnknownAndNewInteractiveOperationKeepOwnership.

@Test
func startupDocumentOldCompletionCannotConsumeNewDocumentOperation(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("startup.ui.json")
        let digest = startupDocumentWrite(path, "startup")
        let controller = CjguiRuleSetComposableController(CjguiRuleSetEditingDomain.newUntitled(),
            uiDocument: path.toString())
        let region = controller.generatedUiRegion()
        let initial = region.submitStructure(startupDocumentText("startup"), 0)
        @Assert(initial.candidateAccepted, true)
        let oldToken = initial.candidateToken
        startupDocumentCommit(region)
        // A completed startup observation may outlive its original operation.
        // The public baseline helper records that already-observed file, then
        // a NEW session submission must remain owned by its own token.
        controller.adoptUiDocumentBaseline(1, digest)
        let secondDigest = startupDocumentWrite(path, "new file operation")
        @Assert(startupDocumentCommand(controller, "restore"), true)
        let newToken = startupDocumentToken(region)
        @Assert(newToken != oldToken, true)
        @Assert(controller.beginStartupUiDocument(path.toString()).reason,
            "ui_document_operation_pending")
        controller.settleStartupDocument()
        @Assert(controller.uiDocumentLoaded(), false)
        @Assert(controller.hasPendingStartupDocument(), false)
        @Assert(region.uiDocumentTicket(newToken).terminalState, "PENDING")
        @Assert(startupDocumentCommand(controller, "save"), false)
        @Assert(cjguiReadUiDocument(path.toString()).structureSha256, secondDigest)
        startupDocumentCommit(region)
        controller.settleStartupDocument()
        @Assert(controller.uiDocumentLoaded(), false)
        @Assert(region.acceptedStructureVersion(), 2)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}
