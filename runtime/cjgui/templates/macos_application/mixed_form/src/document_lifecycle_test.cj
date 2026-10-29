package cjgui_mixed_form_starter

import cjgui.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private func mixedLifecycleText(value: String): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\n" +
        "NODE 1 label label\nPROPERTY 1 label text ${value}\nEND"
}

private func mixedLifecycleCommit(region: CjguiGeneratedUiWindowRegion): Unit {
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
}

@Test
func mixedStartupSupersededTicketCannotAdoptOtherDocument(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("startup.cjgui")
    let exported = cjguiExportUiDocument(mixedLifecycleText("original file"))
    @Assert(exported.ok, true)
    File.writeTo(path, exported.text.toArray())
    let controller = MixedFormController(PrintPresetDomain(), uiDocument: path.toString())
    try {
        @Assert(controller.beginStartupUiDocument(path.toString()).submitted, true)
        // Another admitted candidate supersedes startup before any scene accepts.
        // Its v1 is NOT evidence about the startup file's exact ticket.
        let replacement = controller.region.submitStructure(mixedLifecycleText("other document"), 0)
        @Assert(replacement.candidateAccepted, true)
        mixedLifecycleCommit(controller.region)
        @Assert(controller.region.acceptedStructureVersion(), 1)
        @Assert(controller.finishStartupUiDocument().accepted, false)
        @Assert(controller.requestWindowClose().shouldClose, false)
        @Assert(cjguiReadUiDocument(path.toString()).structureSha256, exported.digest)
    } finally {
        controller.closeResources()
        let _ = removeIfExists(directory, recursive: true)
    }
}
