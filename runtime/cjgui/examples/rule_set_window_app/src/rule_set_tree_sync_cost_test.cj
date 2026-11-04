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

foreign func cjgui_internal_renderer_owner_thread_id(): UInt64
foreign func cjgui_internal_renderer_owner_clock_ns(): UInt64

@Test
func treeSyncUnchangedSavedThousandRecordsKeepsAllocationBounded(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("tree-sync.rules")
        let data = StringBuilder()
        data.append("CJGUI_RULE_SET 2\nNEXT_ID 1001\nSELECTED 1\n")
        for (index in 1..1001) {
            data.append("RECORD ${index} 1 7 E9878DE5A48DE8A784E58899 6361636865 -\n")
        }
        data.append("END\n")
        let originalFile = data.toString()
        File.writeTo(path, originalFile.toArray())
        let domain = CjguiRuleSetEditingDomain.newUntitled()
        @Assert(domain.openFromHuman(path.toString()).applied, true)
        let initial = domain.snapshot()
        @Assert(initial.records.size, 1000)
        @Assert(initial.filePath, path.toString())
        @Assert(initial.isSaved, true)
        let panel = CjguiRuleSetTreePanel(domain)
        @Assert(panel.syncWithData(), true)
        @Assert(panel.projection.setExpanded("group-enabled", true), true)
        panel.selection.click("record-1", false, false)
        @Assert(panel.projection.setExpanded("group-enabled", false), true)
        panel.selection.ensureFocusVisible()
        @Assert(panel.projection.isVisible("record-1"), false)
        @Assert(panel.selection.isSelected("record-1"), true)
        @Assert(panel.syncWithData(), false)
        let selected = panel.selection.snapshot()
        let version = domain.version()
        gc(heavy: true)
        var allBounded = true
        var allReadsValid = true
        var allUnchanged = true
        for (sample in 0..5) {
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
                monoBefore != 0u64 && monoAfter >= monoBefore && freedAfter >= freedBefore &&
                heapBefore >= 0 && heapAfter >= 0 && allocated >= 0
            let after = panel.selection.snapshot()
            let unchanged = !changed && domain.version() == version && after.keys.size == selected.keys.size &&
                after.keys.size == 1 && after.keys[0] == "record-1" && after.focus == selected.focus &&
                after.anchor == selected.anchor && after.selectionVersion == selected.selectionVersion &&
                after.projectionVersion == selected.projectionVersion && !panel.projection.isVisible("record-1")
            getStdOut().writeln("RULES_TREE_SYNC_COST records=1000 saved=true sample=${sample} changed=${changed} " +
                "selection_unchanged=${unchanged} allocation_bytes=${allocated} allocation_valid=${readsValid} " +
                "heap_before=${heapBefore} heap_after=${heapAfter} freed_before=${freedBefore} freed_after=${freedAfter} " +
                "thread_before=${threadBefore} thread_after=${threadAfter} mono_before=${monoBefore} mono_after=${monoAfter}")
            allBounded = allBounded && allocated <= 65536
            allReadsValid = allReadsValid && readsValid
            allUnchanged = allUnchanged && unchanged
        }
        @Assert(domain.snapshot().isSaved, true)
        @Assert(String.fromUtf8(File.readFrom(path)), originalFile)
        @Assert(allReadsValid, true)
        @Assert(allUnchanged, true)
        @Assert(allBounded, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}

@Test
func treeSyncKeepsContentUpdateStructuralRefreshAndHiddenSelection(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    for (index in 1..4) {
        @Assert(domain.createRecordFromHuman("record ${index}", true, 7, "cache", "tree-sync-${index}").applied, true)
    }
    let panel = CjguiRuleSetTreePanel(domain)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(panel.projection.rowCount(), 5)
    panel.selection.click("record-2", false, false)
    let renamed = domain.executeFromHuman(CjguiSharedOperationActionInvocation("RENAME_RECORD", domain.version(),
        ArrayList<Int64>([2]), ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string("renamed record"))])))
    @Assert(renamed.applied, true)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.lastContentPatchedRows(), 1)
    let row = panel.projection.rowAt(panel.projection.indexForKey("record-2"))
    @Assert(row.label, "renamed record")
    @Assert(row.resourceId, 2)
    @Assert(row.selectable, true)
    @Assert(panel.selection.isSelected("record-2"), true)
    @Assert(panel.projection.setExpanded("group-enabled", false), true)
    panel.selection.ensureFocusVisible()
    @Assert(domain.createRecordFromHuman("structural addition", true, 7, "cache", "tree-sync-add").applied, true)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.isVisible("record-2"), false)
    @Assert(panel.selection.isSelected("record-2"), true)
    @Assert(domain.selectRecordFromHuman(2).applied, true)
    let _ = panel.syncWithData()
    @Assert(panel.selection.isSelected("record-2"), true)
    @Assert(domain.deleteSelectedCollectionItemFromHuman().applied, true)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.selection.isSelected("record-2"), false)
    @Assert(panel.selection.selectedCount(), 0)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(panel.projection.indexForKey("record-2"), -1)
    @Assert(panel.keyForResource(4), "record-4")
    @Assert(panel.syncWithData(), false)
}
