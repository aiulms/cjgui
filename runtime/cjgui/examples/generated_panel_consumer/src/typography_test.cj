package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*

private func typographyCandidate(spacing: String, height: String): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\nNODE 1 editor textInput field=title\n" +
        "PROPERTY 1 editor letterSpacing ${spacing}\nPROPERTY 1 editor lineHeight ${height}\nEND"
}
private func typographyNode(root: CjguiComposableUiNode, id: Int64): ?CjguiComposableUiNode {
    if (root.nodeId == id) { return Some(root) }
    for (child in root.children()) {
        if (let Some(node) <- typographyNode(child, id)) { return Some(node) }
    }
    return None
}

@Test
func typographyGeneratedDecimalsApplyAndInvalidCandidateRetainsAccepted(): Unit {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(TYPOGRAPHY_OWNER, TYPOGRAPHY_SAMPLE, false)
    ]))
    @Assert(CjguiTaskFields.installIntoEveryRecord(domain), true)
    let _ = domain.selectFromHuman(TYPOGRAPHY_OWNER)
    let region = CjguiTaskGeneratedRegion(domain, TYPOGRAPHY_OWNER)
    @Assert(region.submitStructure(typographyCandidate("1.25", "32.5"), 0).candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let tree = region.buildSection(CjguiComposableUiTheme.beaconDark())
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    let id = region.acceptedNodeIdForKey("editor")
    let node = typographyNode(tree, id) ?? cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    @Assert(node.style.letterSpacing, 1.25)
    @Assert(node.style.lineHeight, 32.5)
    @Assert(node.value, TYPOGRAPHY_SAMPLE)
    let version = region.acceptedStructureVersion()
    for ((spacing, height) in [("NaN", "32"), ("1000", "32"), ("1", "-1"), ("1.2345", "32")]) {
        @Assert(region.submitStructure(typographyCandidate(spacing, height), version).candidateAccepted, false)
        @Assert(region.acceptedStructureVersion(), version)
        @Assert(region.acceptedNodeIdForKey("editor"), id)
    }
    @Assert(domain.snapshot().recordAt(0).title, TYPOGRAPHY_SAMPLE)
}
