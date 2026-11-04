// Controller-level regression coverage for one close intent spanning the
// business work session and both mounted UI-document workspaces.
package cjgui_mixed_form_starter

import cjgui.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private func mixedWorkSessionCloseUiText(value: String): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\n" +
        "NODE 1 label label\nPROPERTY 1 label text ${value}\nEND"
}

private func commitMixedWorkSessionCloseRegion(controller: MixedFormController): Unit {
    @Assert(controller.region.beginSceneRefresh(), true)
    let _ = controller.region.buildNode()
    @Assert(controller.region.prepareSceneRefresh(), true)
    controller.region.commitSceneRefresh()
}

private func acceptMixedWorkSessionCloseUi(controller: MixedFormController, text: String): Unit {
    let submitted = controller.region.submitStructure(text, controller.region.acceptedStructureVersion())
    @Assert(submitted.reason, "")
    @Assert(submitted.candidateAccepted, true)
    commitMixedWorkSessionCloseRegion(controller)
}

private func mixedWorkSessionCloseAction(controller: MixedFormController,
    action: String): CjguiComposableUiDispatchResult {
    let rect = CjguiComposableUiRect(0, 0, 96, 34)
    let button = cjguiComposableButton(990, "work-session-close-test-${action}", action, action,
        PrintPresetDomain.ownerId, CjguiComposableUiStyle())
    let node = CjguiComposableUiLayoutNode(button, rect, rect)
    return controller.applyUiEvent(CjguiComposableUiEvent(node,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0,
        controller.region.acceptedStructureVersion()))
}

private func mixedWorkSessionCloseHasNode(controller: MixedFormController, semantic: String): Bool {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, 1200, 900)
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) { return false }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, 1,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    for (node in scene.nodes()) {
        if (node.semanticId == semantic) { return true }
    }
    return false
}

private class MixedWorkSessionCloseFixture {
    let directory: Path
    let uiPath: String
    let businessPath: String
    let controller: MixedFormController

    init(commandSurfaces!: Bool = false) {
        let directory = Directory.createTemp("/tmp")
        this.directory = directory
        this.uiPath = directory.join("main-layout.cjgui").toString()
        this.businessPath = directory.join("business-session.cjwork").toString()
        let exported = cjguiExportUiDocument(mixedWorkSessionCloseUiText("saved-layout"))
        if (!exported.ok) { throw Exception("work_session_close_ui_export") }
        File.writeTo(uiPath, exported.text.toArray())
        this.controller = MixedFormController(PrintPresetDomain(), commandSurfaces: commandSurfaces,
            uiDocument: uiPath, workSessionPath: businessPath)
        if (!controller.beginStartupUiDocument(uiPath).submitted) {
            throw Exception("work_session_close_ui_startup_not_submitted")
        }
        commitMixedWorkSessionCloseRegion(controller)
        if (!controller.finishStartupUiDocument().accepted) {
            throw Exception("work_session_close_ui_startup_not_accepted")
        }
        if (!mixedWorkSessionCloseAction(controller, "SAVE_WORK_SESSION").didApply) {
            throw Exception("work_session_close_business_baseline_save_failed")
        }
        if (!controller.requestWindowClose().shouldClose) {
            throw Exception("work_session_close_fixture_not_clean")
        }
    }

    func dirtyBusiness(value: String): Unit {
        let card = controller.cards.card("cardA").getOrThrow()
        @Assert(card.setText("jobName", value), true)
    }

    func changeUi(value: String): Unit {
        acceptMixedWorkSessionCloseUi(controller, mixedWorkSessionCloseUiText(value))
    }

    func close(): Unit {
        controller.closeResources()
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func workSessionCloseDiscardsBothDirtyLayersInSequence(): Unit {
    let fixture = MixedWorkSessionCloseFixture()
    try {
        fixture.dirtyBusiness("A pending close")
        fixture.changeUi("unsaved-layout")
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller,
            "preset-work-session-close-guard"), true)

        @Assert(mixedWorkSessionCloseAction(fixture.controller,
            "WORK_SESSION_CLOSE_DISCARD").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller,
            "preset-ui-close-guard"), true)

        @Assert(mixedWorkSessionCloseAction(fixture.controller, "UI_CLOSE_DISCARD").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, true)
        // A technical delay does not consume either discard permission.
        @Assert(fixture.controller.requestWindowClose().shouldClose, true)
        fixture.controller.windowCloseDidCommit()
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
    } finally {
        fixture.close()
    }
}

@Test
func workSessionCloseCancelThenEditUiAndSaveOnlyBusinessStillBlocks(): Unit {
    let fixture = MixedWorkSessionCloseFixture()
    try {
        fixture.dirtyBusiness("A pending close")
        fixture.changeUi("first-unsaved-layout")
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller,
            "WORK_SESSION_CLOSE_DISCARD").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller, "UI_CLOSE_CANCEL").didApply, true)

        fixture.changeUi("changed-after-cancel")
        @Assert(mixedWorkSessionCloseAction(fixture.controller, "SAVE_WORK_SESSION").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller, "preset-ui-close-guard"), true)
    } finally {
        fixture.close()
    }
}

@Test
func workSessionCloseBusinessChangeRevokesEarlierDiscardPermission(): Unit {
    let fixture = MixedWorkSessionCloseFixture()
    try {
        fixture.dirtyBusiness("A first draft")
        fixture.changeUi("unsaved-layout")
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller,
            "WORK_SESSION_CLOSE_DISCARD").didApply, true)

        // A different business payload cannot inherit the previous discard.
        fixture.dirtyBusiness("A later draft")
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller,
            "preset-work-session-close-guard"), true)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller, "preset-ui-close-guard"), false)
    } finally {
        fixture.close()
    }
}

@Test
func workSessionCloseBusinessSaveConflictKeepsOwnersAndExternalBytes(): Unit {
    let fixture = MixedWorkSessionCloseFixture()
    try {
        fixture.dirtyBusiness("A save-conflict draft")
        let payloadBefore = fixture.controller.cards.workSessionPayload()
        let externalBytes = "external business session bytes"
        File.writeTo(fixture.businessPath, externalBytes.toArray())

        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller,
            "WORK_SESSION_CLOSE_SAVE").didApply, false)
        @Assert(fixture.controller.cards.workSessionPayload(), payloadBefore)
        @Assert(String.fromUtf8(File.readFrom(fixture.businessPath)), externalBytes)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller,
            "preset-work-session-close-guard"), true)
    } finally {
        fixture.close()
    }
}

@Test
func workSessionCloseUiSaveConflictKeepsBusinessAndExternalBytes(): Unit {
    let fixture = MixedWorkSessionCloseFixture()
    try {
        fixture.dirtyBusiness("A while UI is dirty")
        fixture.changeUi("unsaved-layout")
        let payloadBefore = fixture.controller.cards.workSessionPayload()
        let externalDocument = cjguiExportUiDocument(mixedWorkSessionCloseUiText("external-layout"))
        @Assert(externalDocument.ok, true)
        File.writeTo(fixture.uiPath, externalDocument.text.toArray())
        let externalBytes = String.fromUtf8(File.readFrom(fixture.uiPath))

        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller,
            "WORK_SESSION_CLOSE_DISCARD").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller, "UI_CLOSE_SAVE_ALL").didApply, false)
        @Assert(fixture.controller.cards.workSessionPayload(), payloadBefore)
        @Assert(String.fromUtf8(File.readFrom(fixture.uiPath)), externalBytes)

        @Assert(mixedWorkSessionCloseAction(fixture.controller, "SAVE_WORK_SESSION").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller, "preset-ui-close-guard"), true)
        @Assert(String.fromUtf8(File.readFrom(fixture.uiPath)), externalBytes)
    } finally {
        fixture.close()
    }
}

@Test
func workSessionCloseWorkspaceSaveFailureRevokesBusinessDiscard(): Unit {
    let fixture = MixedWorkSessionCloseFixture(commandSurfaces: true)
    try {
        fixture.dirtyBusiness("A before workspace save failure")
        fixture.changeUi("unsaved-layout")
        let payloadBefore = fixture.controller.cards.workSessionPayload()

        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseAction(fixture.controller,
            "WORK_SESSION_CLOSE_DISCARD").didApply, true)
        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller, "preset-ui-close-guard"), true)

        @Assert(mixedWorkSessionCloseAction(fixture.controller, "OPEN_UI_WORKSPACE").didApply, true)
        let externalDocument = cjguiExportUiDocument(mixedWorkSessionCloseUiText("external-layout"))
        @Assert(externalDocument.ok, true)
        File.writeTo(fixture.uiPath, externalDocument.text.toArray())
        let externalBytes = String.fromUtf8(File.readFrom(fixture.uiPath))

        // Derive the production scoped command id through the public workspace
        // helper. Scoped identities use canonical length-encoded paths, so a
        // human-readable suffix is not a valid way to locate this declaration.
        let commandIdSource = CjguiUiDocumentWorkspace(
            CjguiComposableUiIdentityScope("print-preset"), "ui-document",
            CjguiGeneratedUiDocumentSession(), fixture.controller.region)
        let expectedSaveCommandId = commandIdSource.commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE)
        var saveCommandId = ""
        for (command in fixture.controller.candidateSceneCommands()) {
            if (command.id == expectedSaveCommandId) {
                saveCommandId = command.id
                break
            }
        }
        @Assert(saveCommandId.size > 0, true)
        let rect = CjguiComposableUiRect(0, 0, 96, 34)
        let button = cjguiComposableButton(991, "work-session-close-main-ui-save",
            "UI_DOC_SAVE", "UI_DOC_SAVE", PrintPresetDomain.ownerId, CjguiComposableUiStyle())
        let commandArrival = CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(button, rect, rect), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            saveCommandId, 0, 0, fixture.controller.region.acceptedStructureVersion())
        @Assert(fixture.controller.applyUiEvent(commandArrival).didApply, false)
        @Assert(fixture.controller.cards.workSessionPayload(), payloadBefore)
        @Assert(String.fromUtf8(File.readFrom(fixture.uiPath)), externalBytes)

        @Assert(fixture.controller.requestWindowClose().shouldClose, false)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller,
            "preset-work-session-close-guard"), true)
        @Assert(mixedWorkSessionCloseHasNode(fixture.controller, "preset-ui-close-guard"), false)
    } finally {
        fixture.close()
    }
}
