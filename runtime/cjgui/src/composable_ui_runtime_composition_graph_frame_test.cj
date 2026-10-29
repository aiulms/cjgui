package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func graphFrameSection(name: String, refs: ArrayList<String>): String {
    let out = StringBuilder()
    out.append("COMPOSITION ${name} 40 6\n")
    out.append("CELEMENT value${name} field field=title argument=text\nCTEMPLATE 0 root vertical\n")
    var index: Int64 = 0
    for (ref in refs) {
        out.append("CTEMPLATE 1 ref${index} composition compose=${ref}\n")
        index += 1
    }
    out.append("COMPOSITION_END ${name}\n")
    return out.toString()
}

private func graphFrameDefinition(name: String, refs: ArrayList<String>): CjguiRuntimeCompositionDefinition {
    let decoded = CjguiGeneratedUiEncoding.decode("GENERATED_UI_STRUCTURE 2\n" +
        graphFrameSection(name, refs) + "NODE 0 form vertical\nEND")
    if (!decoded.ok) { throw IllegalStateException(decoded.reason) }
    return decoded.definitions[0].definition
}

@Test
func compositionGraphFrameSingleLeafAndSharedRepeatedDag(): Unit {
    let leaf = graphFrameDefinition("fieldGroup", ArrayList<String>())
    @Assert(cjguiCompositionReferenceGraphIssue(ArrayList([leaf])), "")
    let left = graphFrameDefinition("left", ArrayList(["fieldGroup", "fieldGroup"]))
    let right = graphFrameDefinition("right", ArrayList(["fieldGroup"]))
    let root = graphFrameDefinition("panel", ArrayList(["left", "right"]))
    @Assert(cjguiCompositionReferenceGraphIssue(ArrayList([root, left, right, leaf])), "")
    let a = graphFrameDefinition("outerA", ArrayList(["outerB"]))
    let b = graphFrameDefinition("outerB", ArrayList(["outerA"]))
    @Assert(cjguiCompositionReferenceGraphIssue(ArrayList([a, b])).startsWith(
        "composition_rejected:composition_compose_cycle:"), true)
    let unknown = graphFrameDefinition("usesGhost", ArrayList(["ghost"]))
    @Assert(cjguiCompositionReferenceGraphIssue(ArrayList([unknown])),
        "composition_rejected:composition_compose_unknown:ghost")
}

private class GraphFrameBinding <: CjguiGeneratedUiRegionBinding {
    public func ownerRevision(): Int64 { return 0 }
    public func fieldResourceId(fieldId: String): Int64 { return 501 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 500 }
    public func draftText(fieldId: String): String { return "unchanged draft" }
    public func appliedText(fieldId: String): String { return "unchanged applied" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func actionAvailable(actionName: String): Bool { return false }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "not_a_business_action")
    }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

@Test
func compositionGraphFrameRejectionsKeepAcceptedCatalogAndScene(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 8))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("title", "Title", "TEXT", 501))
    let region = CjguiGeneratedUiWindowRegion(catalog, GraphFrameBinding(), "graph-frame")
    let initial = region.submitStructure("GENERATED_UI_STRUCTURE 1\nNODE 0 kept vertical\nEND", 0)
    @Assert(initial.reason, "")
    @Assert(initial.candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildNode()
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    let before = region.acceptedUiDocument()
    @Assert(before.version, 1)
    let unknown = "GENERATED_UI_STRUCTURE 2\n" + graphFrameSection("usesGhost", ArrayList(["ghost"])) +
        "NODE 0 changed vertical\nEND"
    let cycle = "GENERATED_UI_STRUCTURE 2\n" + graphFrameSection("outerA", ArrayList(["outerB"])) +
        graphFrameSection("outerB", ArrayList(["outerA"])) + "NODE 0 changed vertical\nEND"
    for (candidate in [unknown, cycle]) {
        let refused = region.submitStructure(candidate, before.version)
        @Assert(refused.candidateAccepted, false)
        @Assert(region.acceptedUiDocument().text, before.text)
        @Assert(region.acceptedUiDocument().version, before.version)
        @Assert(catalog.acceptedRuntimeCompositionDefinitions().size, 0)
    }
}
