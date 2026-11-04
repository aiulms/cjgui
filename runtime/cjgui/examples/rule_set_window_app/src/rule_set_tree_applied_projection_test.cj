package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.fs.*
import std.runtime.*
import std.unittest.*
import std.unittest.testmacro.*

private func appliedTreeFile(path: Path, count: Int64, labelHex!: String = "E9878DE5A48DE8A784E58899"): String {
    let data = StringBuilder()
    data.append("CJGUI_RULE_SET 2\nNEXT_ID ${count + 1}\nSELECTED 1\n")
    for (index in 1..(count + 1)) {
        data.append("RECORD ${index} 1 7 ${labelHex} 6361636865 -\n")
    }
    data.append("END\n")
    let payload = data.toString()
    File.writeTo(path, payload.toArray())
    return payload
}

private func appliedTreeOpen(path: Path): CjguiRuleSetEditingDomain {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.openFromHuman(path.toString()).applied, true)
    @Assert(domain.snapshot().isSaved, true)
    return domain
}

private func appliedTreeRename(domain: CjguiRuleSetEditingDomain, id: Int64, value: String): CjguiSharedOperationActionResult {
    return domain.executeFromExternal(CjguiSharedOperationActionInvocation("RENAME_RECORD", domain.version(),
        ArrayList<Int64>([id]), ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string(value))])))
}

private func appliedTreeLabel(panel: CjguiRuleSetTreePanel, key: String): String {
    let index = panel.projection.indexForKey(key)
    return if (index >= 0) { panel.projection.rowAt(index).label } else { "<hidden>" }
}

@Test
func appliedTreeContinuousDraftsDoNotRebuildSavedThousandRecords(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("drafts.rules")
        let original = appliedTreeFile(path, 1000)
        let domain = appliedTreeOpen(path)
        @Assert(domain.snapshot().records.size, 1000)
        @Assert(domain.snapshot().filePath, path.toString())
        let panel = CjguiRuleSetTreePanel(domain)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.setExpanded("group-enabled", true), true)
        panel.selection.click("record-1", false, false)
        @Assert(panel.projection.setExpanded("group-enabled", false), true)
        panel.selection.ensureFocusVisible()
        let selected = panel.selection.snapshot()
        let applied = domain.appliedCollectionRevision()
        let draftBefore = domain.formSnapshot().draftVersion
        gc(heavy: true)
        var text = "重复规则"
        var unchanged = true
        var bounded = true
        var valid = true
        for (sample in 0..5) {
            text += (sample + 1).toString()
            @Assert(domain.editSelectedLabelFromHuman(text, text.size, text.size).applied, true)
            let form = domain.formSnapshot()
            let threadBefore = unsafe { cjgui_internal_renderer_owner_thread_id() }
            let monoBefore = unsafe { cjgui_internal_renderer_owner_clock_ns() }
            let freedBefore = getGCFreedSize()
            let heapBefore = getAllocatedHeapSize()
            let changed = panel.syncWithData()
            let heapAfter = getAllocatedHeapSize()
            let freedAfter = getGCFreedSize()
            let monoAfter = unsafe { cjgui_internal_renderer_owner_clock_ns() }
            let threadAfter = unsafe { cjgui_internal_renderer_owner_thread_id() }
            let allocated = heapAfter - heapBefore + freedAfter - freedBefore
            let readsValid = threadBefore != 0u64 && threadBefore != UInt64.Max && threadBefore == threadAfter &&
                monoBefore > 0u64 && monoAfter >= monoBefore && freedAfter >= freedBefore && allocated >= 0
            let after = panel.selection.snapshot()
            let treeUnchanged = !changed && panel.projection.isExpanded("group-enabled") == false &&
                after.keys.size == 1 && after.keys[0] == "record-1" && after.focus == selected.focus &&
                after.anchor == selected.anchor && after.selectionVersion == selected.selectionVersion &&
                after.projectionVersion == selected.projectionVersion
            let ownerCurrent = form.draftVersion == draftBefore + sample + 1 &&
                form.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText == text &&
                domain.appliedCollectionRevision() == applied &&
                domain.appliedRecordForResourceId(1).getOrThrow().label == "重复规则" && domain.hasUnsavedContent()
            getStdOut().writeln("APPLIED_TREE_DRAFT_COST records=1000 file_baseline_saved=true sample=${sample} " +
                "context=${form.contextVersion} draft=${form.draftVersion} applied_revision=${applied} changed=${changed} " +
                "tree_unchanged=${treeUnchanged} owner_current=${ownerCurrent} allocation_bytes=${allocated} " +
                "allocation_valid=${readsValid} heap_before=${heapBefore} heap_after=${heapAfter} " +
                "freed_before=${freedBefore} freed_after=${freedAfter} thread_before=${threadBefore} thread_after=${threadAfter} " +
                "mono_before=${monoBefore} mono_after=${monoAfter}")
            unchanged = unchanged && treeUnchanged && ownerCurrent
            bounded = bounded && allocated <= 65536
            valid = valid && readsValid
        }
        @Assert(String.fromUtf8(File.readFrom(path)), original)
        @Assert(valid, true)
        @Assert(unchanged, true)
        @Assert(bounded, true)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func appliedTreeCancelSelectionAndSaveKeepTreeWhileOwnerErrorsStayLive(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("owner.rules")
        let _ = appliedTreeFile(path, 3)
        let domain = appliedTreeOpen(path)
        let panel = CjguiRuleSetTreePanel(domain)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.setExpanded("group-enabled", true), true)
        panel.selection.click("record-1", false, false)
        let row = panel.projection.rowAt(panel.projection.indexForKey("record-1"))
        let projection = panel.projection.dataVersion()
        let applied = domain.appliedCollectionRevision()
        @Assert(domain.editTextFromHuman(CjguiRuleSetEditingDomain.formRetentionResourceId, "oops", 4, 4).applied, true)
        @Assert(panel.syncWithData(), false)
        let draft = domain.formSnapshot()
        let refused = domain.applySelectedDraftFromHuman(draft.draftVersion)
        @Assert(refused.applied, false)
        @Assert(refused.reason, "invalid_draft")
        let invalid = domain.formSnapshot()
        @Assert(invalid.contextVersion > draft.contextVersion, true)
        @Assert(invalid.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId).validationError.size > 0, true)
        // canApply is the owner's current base-revision permission; validation
        // errors remain visible and another Apply may retry the unchanged draft.
        @Assert(invalid.canApply, true)
        @Assert(invalid.baseAppliedConfigVersion, invalid.appliedConfigVersion)
        @Assert(invalid.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "oops")
        @Assert(invalid.statusMessage.contains("校验失败"), true)
        @Assert(domain.hasUnsavedContent(), true)
        @Assert(panel.syncWithData(), false)
        @Assert(domain.cancelDraftFromHuman(invalid.draftVersion, invalid.baseAppliedConfigVersion).applied, true)
        let cancelled = domain.formSnapshot()
        @Assert(cancelled.contextVersion > invalid.contextVersion, true)
        @Assert(cancelled.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId).draftText, "7")
        @Assert(cancelled.fieldForResourceId(CjguiRuleSetEditingDomain.formRetentionResourceId).validationError, "")
        @Assert(cancelled.statusMessage.contains("草稿已取消"), true)
        @Assert(panel.syncWithData(), false)
        @Assert(domain.selectRecordFromHuman(2).applied, true)
        @Assert(panel.syncWithData(), false)
        @Assert(domain.saveFromHuman().applied, true)
        @Assert(panel.syncWithData(), false)
        @Assert(domain.snapshot().isSaved, true)
        @Assert(domain.appliedCollectionRevision(), applied)
        @Assert(panel.projection.dataVersion(), projection)
        let after = panel.projection.rowAt(panel.projection.indexForKey("record-1"))
        @Assert(after.key, row.key)
        @Assert(after.resourceId, row.resourceId)
        @Assert(after.label, row.label)
        @Assert(after.depth, row.depth)
        @Assert(after.selectable, row.selectable)
        @Assert(panel.selection.isSelected("record-1"), true)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

@Test
func appliedTreeApplyExternalContentStructureLoadAndUndoRefreshCorrectly(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("applied.rules")
        let _ = appliedTreeFile(path, 3)
        let domain = appliedTreeOpen(path)
        let panel = CjguiRuleSetTreePanel(domain)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.setExpanded("group-enabled", true), true)
        @Assert(panel.projection.setExpanded("group-disabled", true), true)
        panel.selection.click("record-2", false, false)
        let applied = domain.appliedCollectionRevision()
        @Assert(domain.editSelectedLabelFromHuman("applied label", 13, 13).applied, true)
        @Assert(panel.syncWithData(), false)
        let draft = domain.formSnapshot()
        @Assert(domain.applySelectedDraftFromHuman(draft.draftVersion).applied, true)
        @Assert(domain.appliedCollectionRevision(), applied + 1)
        @Assert(panel.syncWithData(), true)
        @Assert(appliedTreeLabel(panel, "record-1"), "applied label")
        @Assert(panel.syncWithData(), false)
        let patches = panel.projection.contentRefreshCount()
        @Assert(appliedTreeRename(domain, 2, "external label").applied, true)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.contentRefreshCount(), patches + 1)
        @Assert(panel.projection.lastContentPatchedRows(), 1)
        @Assert(appliedTreeLabel(panel, "record-2"), "external label")
        @Assert(panel.projection.setExpanded("group-enabled", false), true)
        panel.selection.ensureFocusVisible()
        @Assert(domain.createRecordFromHuman("new disabled", false, 7, "cache", "applied-new").applied, true)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.selection.isSelected("record-2"), true)
        @Assert(appliedTreeLabel(panel, "record-4"), "new disabled")
        @Assert(domain.selectRecordFromHuman(2).applied, true)
        @Assert(panel.syncWithData(), false)
        @Assert(domain.deleteSelectedCollectionItemFromHuman().applied, true)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.selection.isSelected("record-2"), false)
        @Assert(domain.undoFromHuman().applied, true)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.setExpanded("group-enabled", true), true)
        @Assert(appliedTreeLabel(panel, "record-2"), "external label")
        @Assert(domain.redoFromHuman().applied, true)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.indexForKey("record-2"), -1)
        @Assert(domain.saveFromHuman().applied, true)
        @Assert(panel.syncWithData(), false)
        let load = directory.join("loaded.rules")
        let _ = appliedTreeFile(load, 2, labelHex: "6C6F61646564")
        @Assert(domain.openFromHuman(load.toString()).applied, true)
        @Assert(panel.syncWithData(), true)
        @Assert(appliedTreeLabel(panel, "record-1"), "loaded")
        @Assert(panel.projection.indexForKey("record-4"), -1)
        @Assert(panel.projection.isExpanded("group-enabled"), true)
        @Assert(panel.projection.isExpanded("group-disabled"), true)
        @Assert(panel.syncWithData(), false)
        let remounted = CjguiRuleSetTreePanel(domain)
        @Assert(remounted.syncWithData(), true)
        @Assert(remounted.projection.setExpanded("group-enabled", true), true)
        @Assert(appliedTreeLabel(remounted, "record-1"), "loaded")
        @Assert(remounted.syncWithData(), false)
    } finally { let _ = removeIfExists(directory, recursive: true) }
}

private func appliedTreeScene(panel: CjguiRuleSetTreePanel, registry: CjguiComposableUiIdentityRegistry,
    version: Int64): CjguiComposableUiScene {
    let theme = CjguiComposableUiTheme.paperLight()
    let root = panel.buildSection(theme, theme.body)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(root), "")
    @Assert(registry.replaceCandidateRoot(root), "")
    let layout = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, CjguiComposableUiRect(0, 0, 900, 620),
        version, CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry))
    @Assert(layout.scene.isValid(), true)
    @Assert(registry.prepareCandidate(), true)
    registry.commitCandidate()
    return layout.scene
}

private func appliedTreeLeafId(scene: CjguiComposableUiScene): Int64 {
    for (node in scene.nodes()) { if (node.semanticId == "rule-tree-vleaf-record-1") { return node.nodeId } }
    return -1
}

@Test
func appliedTreeDraftsKeepRowIdentityAndUnmountRemountShowsLatestApplied(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("original", true, 7, "cache", "identity-one").applied, true)
    let panel = CjguiRuleSetTreePanel(domain)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    let registry = CjguiComposableUiIdentityRegistry()
    let originalId = appliedTreeLeafId(appliedTreeScene(panel, registry, 1))
    @Assert(originalId > 0, true)
    @Assert(domain.editSelectedLabelFromHuman("private draft", 13, 13).applied, true)
    @Assert(panel.syncWithData(), false)
    @Assert(appliedTreeLeafId(appliedTreeScene(panel, registry, 2)), originalId)
    @Assert(appliedTreeLabel(panel, "record-1"), "original")
    let draft = domain.formSnapshot()
    @Assert(domain.cancelDraftFromHuman(draft.draftVersion, draft.baseAppliedConfigVersion).applied, true)
    @Assert(panel.syncWithData(), false)
    @Assert(panel.projection.setExpanded("group-enabled", false), true)
    @Assert(appliedTreeLeafId(appliedTreeScene(panel, registry, 3)), -1)
    @Assert(appliedTreeRename(domain, 1, "latest applied").applied, true)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    let remountedId = appliedTreeLeafId(appliedTreeScene(panel, registry, 4))
    @Assert(remountedId > 0 && remountedId != originalId, true)
    @Assert(appliedTreeLabel(panel, "record-1"), "latest applied")
}

private class AppliedTreeFailOnceProvider <: CjguiComposableUiTreeContentUpdateSource {
    let domain: CjguiRuleSetEditingDomain
    var fail: Bool = true
    init(domain: CjguiRuleSetEditingDomain) { this.domain = domain }
    public func contentVersion(): Int64 {
        if (fail) { fail = false; throw Exception("applied_tree_test_refresh_failure") }
        return domain.version()
    }
    public func contentUpdates(sinceVersion: Int64): ?ArrayList<CjguiComposableUiTreeContentUpdate> { return None }
}

@Test
func appliedTreeFailedRefreshDoesNotConsumeAppliedRevision(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("before", true, 7, "cache", "failure-one").applied, true)
    let panel = CjguiRuleSetTreePanel(domain)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(appliedTreeRename(domain, 1, "after").applied, true)
    panel.projection.attachContentUpdateSource(AppliedTreeFailOnceProvider(domain))
    var threw = false
    try { let _ = panel.syncWithData() } catch (error: Exception) {
        threw = error.message == "applied_tree_test_refresh_failure"
    }
    @Assert(threw, true)
    @Assert(appliedTreeLabel(panel, "record-1"), "before")
    let retried = panel.syncWithData()
    getStdOut().writeln("APPLIED_TREE_FAILURE threw=${threw} next_sync=${retried} label=${appliedTreeLabel(panel, "record-1")}")
    @Assert(retried, true)
    @Assert(appliedTreeLabel(panel, "record-1"), "after")
    @Assert(panel.syncWithData(), false)
}
