package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.unittest.*
import std.unittest.testmacro.*

private func cursorRaceRename(domain: CjguiRuleSetEditingDomain): Unit {
    let result = domain.executeFromExternal(CjguiSharedOperationActionInvocation("RENAME_RECORD", domain.version(),
        ArrayList<Int64>([1]), ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("label", CjguiSharedOperationValue.string("raced label"))])))
    @Assert(result.applied, true)
}

private func cursorRaceLabel(projection: CjguiComposableUiTreeProjection): String {
    let index = projection.indexForKey("record-1")
    return if (index >= 0) { projection.rowAt(index).label } else { "<hidden>" }
}

// The provider always returns the actual domain version and makes no claim of
// content-only stability. The old mark-time read triggered one real commit.
private class CursorRaceProvider <: CjguiComposableUiTreeContentUpdateSource {
    let domain: CjguiRuleSetEditingDomain
    public var reads: Int64 = 0
    public var committed: Bool = false
    public var commitContext: Int64 = -1
    public var commitApplied: Int64 = -1
    public var location: String = ""
    init(domain: CjguiRuleSetEditingDomain) { this.domain = domain }
    public func commit(location: String): Unit {
        @Assert(committed, false)
        commitContext = domain.version()
        commitApplied = domain.appliedCollectionRevision()
        cursorRaceRename(domain)
        committed = true
        this.location = location
    }
    public func contentVersion(): Int64 {
        reads += 1
        if (reads == 2 && !committed) { commit("legacy_mark_live_read") }
        return domain.version()
    }
    public func contentUpdates(sinceVersion: Int64): ?ArrayList<CjguiComposableUiTreeContentUpdate> {
        return None
    }
}

@Test
func cursorRaceRulesMarksCapturedContextWithoutAnotherLiveRead(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("before", true, 7, "cache", "cursor-first").applied, true)
    let panel = CjguiRuleSetTreePanel(domain)
    @Assert(panel.syncWithData(), true)
    @Assert(panel.projection.setExpanded("group-enabled", true), true)
    @Assert(domain.createRecordFromHuman("second", false, 7, "cache", "cursor-second").applied, true)
    let provider = CursorRaceProvider(domain)
    panel.projection.attachContentUpdateSource(provider)
    @Assert(panel.syncWithData(), true)
    let readsAfterRefresh = provider.reads
    let labelBeforeNext = cursorRaceLabel(panel.projection)
    let context = domain.version()
    let applied = domain.appliedCollectionRevision()
    let next = panel.syncWithData()
    let labelAfterNext = cursorRaceLabel(panel.projection)
    let finalSync = panel.syncWithData()
    getStdOut().writeln("TREE_CURSOR_RACE location=${provider.location} reads_after_refresh=${readsAfterRefresh} " +
        "commit_context=${provider.commitContext} commit_applied=${provider.commitApplied} " +
        "live_context=${context} live_applied=${applied} " +
        "label_before_next=${labelBeforeNext} next_sync=${next} label_after_next=${labelAfterNext} " +
        "final_sync=${finalSync}")
    // Integration seam only: the old mark-time hook no longer exists, and no
    // commit is moved or resent to manufacture a GREEN race. The fixed datasource
    // barrier below is the actual same-interleave RED-to-GREEN proof.
    @Assert(readsAfterRefresh, 1)
    @Assert(provider.committed, false)
    @Assert(context, 2)
    @Assert(applied, 2)
    @Assert(labelBeforeNext, "before")
    @Assert(next, false)
    @Assert(labelAfterNext, "before")
    @Assert(finalSync, false)
}

// All child data is the real source's captured index. The one-shot barrier is
// entered during invalidate, after refresh captured its snapshot and before mark.
private class CursorRaceDataSource <: CjguiComposableUiTreeDataSource {
    let source: CjguiRuleSetTreeSource
    let domain: CjguiRuleSetEditingDomain
    public var armed: Bool = false
    public var commits: Int64 = 0
    public var commitSnapshot: Int64 = -1
    public var commitContext: Int64 = -1
    public var commitApplied: Int64 = -1
    init(source: CjguiRuleSetTreeSource, domain: CjguiRuleSetEditingDomain) {
        this.source = source; this.domain = domain
    }
    public func childCount(parentKey: String): Int64 {
        if (armed) {
            armed = false
            commitSnapshot = source.snapshotVersion()
            commitContext = domain.version()
            commitApplied = domain.appliedCollectionRevision()
            cursorRaceRename(domain)
            commits += 1
        }
        return source.childCount(parentKey)
    }
    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        return source.childAt(parentKey, index)
    }
}

@Test
func cursorRaceCapturedIndexDoesNotConsumeCommitBetweenRefreshAndMark(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("before", true, 7, "cache", "barrier-first").applied, true)
    let source = CjguiRuleSetTreeSource(domain)
    let barrier = CursorRaceDataSource(source, domain)
    let projection = CjguiComposableUiTreeProjection(barrier)
    projection.attachContentUpdateSource(source)
    projection.markSourceIndexCurrent()
    @Assert(projection.setExpanded("group-enabled", true), true)
    @Assert(domain.createRecordFromHuman("second", false, 7, "cache", "barrier-second").applied, true)
    source.refresh()
    barrier.armed = true
    @Assert(projection.invalidate(), true)
    // This consumer call is migrated to the explicit snapshot-context overload
    // in GREEN; the real commit barrier and all observations stay unchanged.
    projection.markSourceIndexCurrent(source.snapshotVersion())
    let snapshotBeforeNext = source.snapshotVersion()
    let labelBeforeNext = cursorRaceLabel(projection)
    let context = domain.version()
    let applied = domain.appliedCollectionRevision()
    let refreshed = projection.refreshContentOnly()
    let labelAfterNext = cursorRaceLabel(projection)
    let snapshotAfterNext = source.snapshotVersion()
    getStdOut().writeln("TREE_CURSOR_BARRIER commits=${barrier.commits} " +
        "commit_snapshot=${barrier.commitSnapshot} commit_context=${barrier.commitContext} commit_applied=${barrier.commitApplied} " +
        "live_context=${context} live_applied=${applied} snapshot_before_next=${snapshotBeforeNext} " +
        "label_before_next=${labelBeforeNext} refresh_result=${refreshed} label_after_next=${labelAfterNext} " +
        "snapshot_after_next=${snapshotAfterNext} patched_rows=${projection.lastContentPatchedRows()}")
    @Assert(barrier.commits, 1)
    @Assert(barrier.commitSnapshot, 2)
    @Assert(barrier.commitContext, 2)
    @Assert(barrier.commitApplied, 2)
    @Assert(context, 3)
    @Assert(applied, 3)
    @Assert(snapshotBeforeNext, 2)
    @Assert(labelBeforeNext, "before")
    @Assert(refreshed, true)
    @Assert(labelAfterNext, "raced label")
    @Assert(snapshotAfterNext, context)
    @Assert(projection.lastContentPatchedRows(), 1)
}
