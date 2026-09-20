// Regression guard for the rule-set tree panel's row identities.
//
// A projected row mixes two identities: record leaves keep the real record id
// (business identity) while group rows are view-only. Group and record ids must
// stay in disjoint ranges, and each row kind must derive its declaration node
// ids from its own block. When a group id overlapped the first record id, an
// expanded tree declared the same numeric node id twice, the framework
// correctly rejected the whole candidate with `duplicate_node_id`, and the
// window kept showing the previous collapsed scene while every later external
// mutation was rejected as well. These tests fail on that defect without
// needing a desktop session.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func treeIdentityRoot(panel: CjguiRuleSetTreePanel, theme: CjguiComposableUiTheme): CjguiComposableUiNode {
    let root = cjguiComposableVertical(9100, "tree-row-identity-root", CjguiComposableUiStyle())
    root.add(panel.buildSection(theme, theme.body))
    return root
}

private func containsId(values: ArrayList<Int64>, value: Int64): Bool {
    var index: Int64 = 0
    while (index < values.size) {
        if (values[index] == value) {
            return true
        }
        index += 1
    }
    return false
}

/// The layout node id a semantic id resolved to, or -1 when absent.
private func nodeIdForSemanticId(scene: CjguiComposableUiScene, semanticId: String): Int64 {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return node.nodeId
        }
    }
    return -1
}

@Test
func treeRowsKeepDisjointResourceIdentities(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    var index: Int64 = 1
    while (index <= 3) {
        @Assert(domain.createRecordFromHuman("记录${index}", true, 7, "-", "tree-identity-${index}").applied, true)
        index += 1
    }
    let panel = CjguiRuleSetTreePanel(domain)
    // Expanding is exactly the state in which groups and leaves coexist.
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(panel.projection.setExpanded("group-disabled", true), true)
    @Assert(panel.projection.rowCount(), 5)
    let resourceIds = ArrayList<Int64>()
    var rowIndex: Int64 = 0
    while (rowIndex < panel.projection.rowCount()) {
        let row = panel.projection.rowAt(rowIndex)
        // A duplicated projected resource id would also make `keyForResource`
        // resolve a click to the wrong row, so assert the invariant that the
        // panel's own lookup depends on.
        @Assert(containsId(resourceIds, row.resourceId), false)
        resourceIds.add(row.resourceId)
        rowIndex += 1
    }
    // A record click must never resolve to a group row and vice versa.
    var recordIndex: Int64 = 1
    while (recordIndex <= 3) {
        let key = panel.keyForResource(recordIndex)
        @Assert(key, "record-${recordIndex}")
        recordIndex += 1
    }
    @Assert(panel.keyForResource(CJGUI_RULE_SET_TREE_GROUP_RESOURCE_BASE + 1), "group-enabled")
    @Assert(panel.keyForResource(CJGUI_RULE_SET_TREE_GROUP_RESOURCE_BASE + 2), "group-disabled")
}

@Test
func expandedTreeSectionProducesAValidScene(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    var index: Int64 = 1
    while (index <= 3) {
        @Assert(domain.createRecordFromHuman("记录${index}", true, 7, "-", "tree-scene-${index}").applied, true)
        index += 1
    }
    let panel = CjguiRuleSetTreePanel(domain)
    let theme = CjguiComposableUiTheme.paperLight()
    // First pass syncs the projection with the domain (a fresh projection
    // starts invalidated), then the groups are expanded and the section is
    // rebuilt the same way one scene refresh does.
    let _ = treeIdentityRoot(panel, theme)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(panel.projection.setExpanded("group-disabled", true), true)
    @Assert(panel.projection.rowCount(), 5)
    let root = treeIdentityRoot(panel, theme)
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    @Assert(identityRegistry.beginCandidate(), true)
    @Assert(identityRegistry.resolveCandidate(root), "")
    @Assert(identityRegistry.replaceCandidateRoot(root), "")
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(root,
        CjguiComposableUiRect(0, 0, 900, 620), 1, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(identityRegistry))
    // `duplicate_node_id` is the exact framework rejection this guards; an
    // expanded group and a record leaf must never share a declaration id.
    @Assert(result.scene.layoutError(), "")
    @Assert(result.scene.isValid(), true)
    let nodes = result.scene.nodes()
    let nodeIds = ArrayList<Int64>()
    var nodeIndex: Int64 = 0
    while (nodeIndex < nodes.size) {
        @Assert(containsId(nodeIds, nodes[nodeIndex].nodeId), false)
        nodeIds.add(nodes[nodeIndex].nodeId)
        nodeIndex += 1
    }
    // The leaves really materialized, so the assertion above is not vacuous.
    @Assert(panel.listState.materializedEnd() >= panel.projection.rowCount(), true)
    // Row declarations now take their node ids from the window's identity
    // registry, addressed by the row's stable key. The row for record 3 must be
    // present under its own semantic id with a registry-allocated id, and it
    // must NOT be the legacy hand-computed block id: production binding no
    // longer reserves numeric segments to avoid collisions.
    let leafNodeId = nodeIdForSemanticId(result.scene, "rule-tree-vleaf-record-3")
    @Assert(leafNodeId > 0, true)
    @Assert(leafNodeId != CJGUI_RULE_SET_TREE_LEAF_ROW_NODE_BASE + 3 * CJGUI_RULE_SET_TREE_ROW_NODE_STRIDE + 3, true)
}

/// Same key, same identity: a rebuilt row keeps its registry-allocated node id
/// across a scene refresh, a reordered row does not steal another row's id, and
/// a newly appearing row receives a fresh one. This is the contract that
/// replaces the hand-computed id segments.
@Test
func treeRowsKeepStableIdentityAcrossRebuildAndReorder(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    var index: Int64 = 1
    while (index <= 3) {
        @Assert(domain.createRecordFromHuman("记录${index}", true, 7, "-", "tree-stable-${index}").applied, true)
        index += 1
    }
    let panel = CjguiRuleSetTreePanel(domain)
    let theme = CjguiComposableUiTheme.paperLight()
    let _ = treeIdentityRoot(panel, theme)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    // One registry for the whole test: this is how the window owns it across
    // refreshes.
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    let firstRoot = treeIdentityRoot(panel, theme)
    @Assert(identityRegistry.beginCandidate(), true)
    @Assert(identityRegistry.resolveCandidate(firstRoot), "")
    @Assert(identityRegistry.replaceCandidateRoot(firstRoot), "")
    let firstLayout = CjguiComposableUiLayoutEngine.layoutWithMetrics(firstRoot,
        CjguiComposableUiRect(0, 0, 900, 620), 1, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(identityRegistry))
    @Assert(firstLayout.scene.isValid(), true)
    @Assert(identityRegistry.prepareCandidate(), true)
    identityRegistry.commitCandidate()
    let oneBefore = nodeIdForSemanticId(firstLayout.scene, "rule-tree-vleaf-record-1")
    let twoBefore = nodeIdForSemanticId(firstLayout.scene, "rule-tree-vleaf-record-2")
    let groupBefore = nodeIdForSemanticId(firstLayout.scene, "rule-tree-vgroup-group-enabled")
    @Assert(oneBefore > 0, true)
    @Assert(twoBefore > 0, true)
    @Assert(groupBefore > 0, true)
    @Assert(oneBefore != twoBefore, true)
    @Assert(oneBefore != groupBefore, true)
    // A business update rebuilds the same rows with the same keys.
    @Assert(domain.createRecordFromHuman("记录4", true, 7, "-", "tree-stable-4").applied, true)
    let secondRoot = treeIdentityRoot(panel, theme)
    @Assert(identityRegistry.beginCandidate(), true)
    @Assert(identityRegistry.resolveCandidate(secondRoot), "")
    @Assert(identityRegistry.replaceCandidateRoot(secondRoot), "")
    let secondLayout = CjguiComposableUiLayoutEngine.layoutWithMetrics(secondRoot,
        CjguiComposableUiRect(0, 0, 900, 620), 1, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(identityRegistry))
    @Assert(secondLayout.scene.isValid(), true)
    @Assert(identityRegistry.prepareCandidate(), true)
    identityRegistry.commitCandidate()
    @Assert(nodeIdForSemanticId(secondLayout.scene, "rule-tree-vleaf-record-1"), oneBefore)
    @Assert(nodeIdForSemanticId(secondLayout.scene, "rule-tree-vleaf-record-2"), twoBefore)
    @Assert(nodeIdForSemanticId(secondLayout.scene, "rule-tree-vgroup-group-enabled"), groupBefore)
    let four = nodeIdForSemanticId(secondLayout.scene, "rule-tree-vleaf-record-4")
    @Assert(four > 0, true)
    @Assert(four != oneBefore, true)
    @Assert(four != twoBefore, true)
}

/// One window scene refresh: build the panel section, run the same identity
/// candidate transaction the window runs, and promote it. Returns None when any
/// step reports a framework rejection, so the caller can attribute the failure.
private func refreshedTreeScene(panel: CjguiRuleSetTreePanel, theme: CjguiComposableUiTheme,
    identityRegistry: CjguiComposableUiIdentityRegistry, sceneVersion: Int64): ?CjguiComposableUiScene {
    let root = treeIdentityRoot(panel, theme)
    if (!identityRegistry.beginCandidate()) { return None }
    if (identityRegistry.resolveCandidate(root) != "") { return None }
    if (identityRegistry.replaceCandidateRoot(root) != "") { return None }
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(root,
        CjguiComposableUiRect(0, 0, 900, 620), sceneVersion, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(identityRegistry))
    if (!result.scene.isValid()) { return None }
    if (!identityRegistry.prepareCandidate()) { return None }
    identityRegistry.commitCandidate()
    return Some(result.scene)
}

private func hasDuplicateNodeIds(scene: CjguiComposableUiScene): Bool {
    let seen = ArrayList<Int64>()
    let nodes = scene.nodes()
    var index: Int64 = 0
    while (index < nodes.size) {
        if (containsId(seen, nodes[index].nodeId)) {
            return true
        }
        seen.add(nodes[index].nodeId)
        index += 1
    }
    return false
}

private func createEnabledRecords(domain: CjguiRuleSetEditingDomain, count: Int64,
    prefix: String): Bool {
    var index: Int64 = 1
    while (index <= count) {
        if (!domain.createRecordFromHuman("记录${index}", true, 7, "-", "${prefix}-${index}").applied) {
            return false
        }
        index += 1
    }
    return true
}

/// Re-parent and reorder: a row that moves to the other group or shifts index
/// keeps the identity the registry already accepted for its stable key, and no
/// other row can take that id. This is the "no cross-wired object" contract
/// that replaced the hand-computed numeric row segments.
@Test
func treeRowsKeepIdentityAcrossReparentAndReorder(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(createEnabledRecords(domain, 3, "tree-reparent"), true)
    let panel = CjguiRuleSetTreePanel(domain)
    let theme = CjguiComposableUiTheme.paperLight()
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    let _ = panel.syncWithData()
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(panel.projection.setExpanded("group-disabled", true), true)
    let first = refreshedTreeScene(panel, theme, identityRegistry, 1)
    @Assert(first.isSome(), true)
    if (let Some(scene) <- first) {
        let oneBefore = nodeIdForSemanticId(scene, "rule-tree-vleaf-record-1")
        let twoBefore = nodeIdForSemanticId(scene, "rule-tree-vleaf-record-2")
        let threeBefore = nodeIdForSemanticId(scene, "rule-tree-vleaf-record-3")
        @Assert(oneBefore > 0, true)
        @Assert(twoBefore > 0, true)
        @Assert(threeBefore > 0, true)
        // Re-parent: record 2 becomes disabled, so it moves to the other group.
        @Assert(domain.selectRecordFromHuman(2).applied, true)
        @Assert(domain.editBooleanFromHuman(CjguiRuleSetEditingDomain.formEnabledResourceId, false).applied, true)
        let second = refreshedTreeScene(panel, theme, identityRegistry, 2)
        @Assert(second.isSome(), true)
        if (let Some(reparentedScene) <- second) {
            @Assert(hasDuplicateNodeIds(reparentedScene), false)
            @Assert(nodeIdForSemanticId(reparentedScene, "rule-tree-vleaf-record-1"), oneBefore)
            @Assert(nodeIdForSemanticId(reparentedScene, "rule-tree-vleaf-record-2"), twoBefore)
            @Assert(nodeIdForSemanticId(reparentedScene, "rule-tree-vleaf-record-3"), threeBefore)
            // The row still addresses the same business record.
            @Assert(panel.keyForResource(2), "record-2")
        }
        // Reorder: deleting the first row shifts every surviving row's index.
        @Assert(domain.selectRecordFromHuman(1).applied, true)
        @Assert(domain.deleteSelectedCollectionItemFromHuman().applied, true)
        let third = refreshedTreeScene(panel, theme, identityRegistry, 3)
        @Assert(third.isSome(), true)
        if (let Some(reorderedScene) <- third) {
            @Assert(hasDuplicateNodeIds(reorderedScene), false)
            @Assert(nodeIdForSemanticId(reorderedScene, "rule-tree-vleaf-record-1") == -1, true)
            @Assert(nodeIdForSemanticId(reorderedScene, "rule-tree-vleaf-record-2"), twoBefore)
            @Assert(nodeIdForSemanticId(reorderedScene, "rule-tree-vleaf-record-3"), threeBefore)
            @Assert(panel.keyForResource(3), "record-3")
        }
    }
}

/// Virtual unmount is a real removal from the committed candidate: the registry
/// releases the key, so re-materialising the same logical row later allocates a
/// fresh accepted identity instead of reviving a stale one, while the row still
/// resolves to its own business object through the stable key.
@Test
func treeRowsReleaseIdentityAcrossVirtualUnmount(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(createEnabledRecords(domain, 30, "tree-unmount"), true)
    let panel = CjguiRuleSetTreePanel(domain)
    let theme = CjguiComposableUiTheme.paperLight()
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    let _ = panel.syncWithData()
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    let first = refreshedTreeScene(panel, theme, identityRegistry, 1)
    @Assert(first.isSome(), true)
    if (let Some(scene) <- first) {
        // The list really virtualises, otherwise the unmount assertion is vacuous.
        @Assert(panel.projection.rowCount() > 30, true)
        @Assert(panel.listState.materializedEnd() - panel.listState.materializedStart() < 30, true)
        let oneBefore = nodeIdForSemanticId(scene, "rule-tree-vleaf-record-1")
        @Assert(oneBefore > 0, true)
        panel.listState.scrollToIndex(29)
        let second = refreshedTreeScene(panel, theme, identityRegistry, 2)
        @Assert(second.isSome(), true)
        if (let Some(scrolledScene) <- second) {
            @Assert(nodeIdForSemanticId(scrolledScene, "rule-tree-vleaf-record-1") == -1, true)
            @Assert(nodeIdForSemanticId(scrolledScene, "rule-tree-vleaf-record-30") > 0, true)
        }
        panel.listState.scrollToIndex(0)
        let third = refreshedTreeScene(panel, theme, identityRegistry, 3)
        @Assert(third.isSome(), true)
        if (let Some(backScene) <- third) {
            @Assert(hasDuplicateNodeIds(backScene), false)
            let oneAfter = nodeIdForSemanticId(backScene, "rule-tree-vleaf-record-1")
            @Assert(oneAfter > 0, true)
            @Assert(oneAfter != oneBefore, true)
            // The re-materialised row is still record-1, not another object.
            @Assert(panel.keyForResource(1), "record-1")
        }
    }
}

/// Delete then re-enter: the removed key is released from the committed
/// candidate, undo re-enters it under the same business key with a fresh
/// identity, and the untouched rows keep theirs, so a recycled row can never be
/// addressed as a stale one.
@Test
func treeRowsReleaseIdentityAcrossDeleteAndUndo(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(createEnabledRecords(domain, 3, "tree-delete"), true)
    let panel = CjguiRuleSetTreePanel(domain)
    let theme = CjguiComposableUiTheme.paperLight()
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    let _ = panel.syncWithData()
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(panel.projection.setExpanded("group-disabled", true), true)
    let first = refreshedTreeScene(panel, theme, identityRegistry, 1)
    @Assert(first.isSome(), true)
    if (let Some(scene) <- first) {
        let twoBefore = nodeIdForSemanticId(scene, "rule-tree-vleaf-record-2")
        let threeBefore = nodeIdForSemanticId(scene, "rule-tree-vleaf-record-3")
        @Assert(twoBefore > 0, true)
        @Assert(threeBefore > 0, true)
        @Assert(domain.selectRecordFromHuman(2).applied, true)
        @Assert(domain.deleteSelectedCollectionItemFromHuman().applied, true)
        let second = refreshedTreeScene(panel, theme, identityRegistry, 2)
        @Assert(second.isSome(), true)
        if (let Some(deletedScene) <- second) {
            @Assert(hasDuplicateNodeIds(deletedScene), false)
            @Assert(nodeIdForSemanticId(deletedScene, "rule-tree-vleaf-record-2") == -1, true)
            @Assert(nodeIdForSemanticId(deletedScene, "rule-tree-vleaf-record-3"), threeBefore)
        }
        @Assert(domain.undoFromHuman().applied, true)
        let third = refreshedTreeScene(panel, theme, identityRegistry, 3)
        @Assert(third.isSome(), true)
        if (let Some(restoredScene) <- third) {
            @Assert(hasDuplicateNodeIds(restoredScene), false)
            let twoAfter = nodeIdForSemanticId(restoredScene, "rule-tree-vleaf-record-2")
            @Assert(twoAfter > 0, true)
            @Assert(twoAfter != twoBefore, true)
            @Assert(nodeIdForSemanticId(restoredScene, "rule-tree-vleaf-record-3"), threeBefore)
            @Assert(panel.keyForResource(2), "record-2")
        }
    }
}
