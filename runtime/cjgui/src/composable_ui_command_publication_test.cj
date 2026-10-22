// Minimal counterexamples for command publication freshness. The accepted
// scene version may stay put across replace/revoke, so the diagnostic
// publication revision is the only scalar that can tell an old command page
// from the current one; these tests pin the same-scene replace, the
// no-change projection, the failed candidate, and bounded paging.
package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class PublicationProbeController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    var revision: Int64 = 1
    var commands: ArrayList<CjguiComposableUiCommand>

    init() {
        this.commands = ArrayList<CjguiComposableUiCommand>()
    }

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "publication-root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(2, "publication-button", "Target", "PRESS", 0,
            CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 32)))
        return root
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>(commands)
    }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func publicationSet(checked: Bool, withSecond: Bool): ArrayList<CjguiComposableUiCommand> {
    let commands = ArrayList<CjguiComposableUiCommand>()
    commands.add(CjguiComposableUiCommand("pub.toggle", CjguiComposableUiNodeReference.manual(2),
        "切换", CjguiComposableUiShortcut("t"), "View", 0, true, checked, isCheckable: true))
    if (withSecond) {
        commands.add(CjguiComposableUiCommand("pub.plain", CjguiComposableUiNodeReference.manual(2),
            "普通动作", "", 1, true, false))
    }
    return commands
}

// Drive the window to a settled accepted state that includes the candidate
// commands; declaration binding follows an accepted refresh, not start alone.
private func publicationSettle(window: CjguiComposableUiWindow): Bool {
    window.requestRefresh()
    var settled = false
    var turns: Int64 = 0
    while (!settled && turns < 80) {
        settled = window.refreshIfNeeded()
        if (!settled) {
            let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        }
        turns += 1
    }
    return settled
}

@Test
func commandPublicationFreshnessUnderSameSceneReplaceRevoke(): Unit {
    let owner = PublicationProbeController()
    owner.commands = publicationSet(false, true)
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    @Assert(publicationSettle(window), true)

    let first = window.diagnosticCommandSnapshot(maximumCommands: 8)
    @Assert(first.status, "ok")
    @Assert(first.totalCommands, 2)
    @Assert(first.publicationRevision, window.commandPublicationRevision())
    let sceneAtFirst = window.displayedSceneVersion()
    let revisionAtFirst = first.publicationRevision

    // Replace inside one unchanged scene version, with no refresh at all: the
    // checked fact flips, so the old page must stop being current even though
    // the scene did not move.
    let directReplace = publicationSet(true, true)
    @Assert(window.replaceCommands(directReplace), true)
    @Assert(window.displayedSceneVersion(), sceneAtFirst)
    let afterReplace = window.commandPublicationRevision()
    @Assert(afterReplace > revisionAtFirst, true)
    let staleFirst = window.diagnosticCommandSnapshot(maximumCommands: 8,
        expectedPublicationRevision: revisionAtFirst)
    @Assert(staleFirst.status, "stale_publication")
    let current = window.diagnosticCommandSnapshot(maximumCommands: 8,
        expectedPublicationRevision: afterReplace)
    @Assert(current.status, "ok")
    @Assert(current.publicationRevision, afterReplace)
    @Assert(current.commands[0].checked, true)
    @Assert(current.commands[0].checkable, true)
    // Unchecked checkable and plain action are different declared facts.
    @Assert(current.commands[1].checkable, false)

    // The identical projection must not move the publication revision.
    @Assert(window.replaceCommands(publicationSet(true, true)), true)
    @Assert(window.commandPublicationRevision(), afterReplace)
    @Assert(window.displayedSceneVersion(), sceneAtFirst)

    // A failed candidate keeps the old publication: the old page stays
    // current instead of being masked by a forced scene refresh.
    let broken = ArrayList<CjguiComposableUiCommand>()
    broken.add(CjguiComposableUiCommand("pub.missing", CjguiComposableUiNodeReference.manual(999),
        "无目标", "", 0, true, false))
    @Assert(window.replaceCommands(broken), false)
    @Assert(window.commandPublicationRevision(), afterReplace)
    @Assert(window.displayedSceneVersion(), sceneAtFirst)

    // Revoke lands the same way: revision moves inside the same scene, the
    // count drops, and the old snapshot cannot pose as current.
    @Assert(window.revokeCommand("pub.plain"), true)
    @Assert(window.displayedSceneVersion(), sceneAtFirst)
    @Assert(window.commandPublicationRevision() > afterReplace, true)
    let afterRevoke = window.diagnosticCommandSnapshot(maximumCommands: 8,
        expectedPublicationRevision: afterReplace)
    @Assert(afterRevoke.status, "stale_publication")
    let fresh = window.diagnosticCommandSnapshot(maximumCommands: 8)
    @Assert(fresh.totalCommands, 1)
    @Assert(fresh.commands[0].id, "pub.toggle")
    @Assert(fresh.publicationRevision, window.commandPublicationRevision())
    window.close()
}

@Test
func commandDiagnosticPagingCoversBeyondFirstPage(): Unit {
    let owner = PublicationProbeController()
    let commands = ArrayList<CjguiComposableUiCommand>()
    var index: Int64 = 0
    while (index < 5) {
        commands.add(CjguiComposableUiCommand("pub.item${index}", CjguiComposableUiNodeReference.manual(2),
            "命令${index}", "", index, true, false))
        index += 1
    }
    owner.commands = commands
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    @Assert(publicationSettle(window), true)

    let publication = window.commandPublicationRevision()
    let page1 = window.diagnosticCommandSnapshot(maximumCommands: 2)
    @Assert(page1.status, "ok")
    @Assert(page1.totalCommands, 5)
    @Assert(page1.commands.size, 2)
    @Assert(page1.startIndex, 0)
    @Assert(page1.nextIndex, 2)
    @Assert(page1.truncated, true)
    @Assert(page1.commands[0].id, "pub.item0")
    @Assert(page1.commands[1].id, "pub.item1")

    let page2 = window.diagnosticCommandSnapshot(maximumCommands: 2, startIndex: page1.nextIndex,
        expectedPublicationRevision: publication)
    @Assert(page2.status, "ok")
    @Assert(page2.commands.size, 2)
    @Assert(page2.startIndex, 2)
    @Assert(page2.nextIndex, 4)
    @Assert(page2.commands[0].id, "pub.item2")

    let page3 = window.diagnosticCommandSnapshot(maximumCommands: 2, startIndex: page2.nextIndex,
        expectedPublicationRevision: publication)
    @Assert(page3.status, "ok")
    @Assert(page3.commands.size, 1)
    @Assert(page3.startIndex, 4)
    @Assert(page3.nextIndex, 5)
    @Assert(page3.truncated, false)
    @Assert(page3.commands[0].id, "pub.item4")

    // A startIndex past the end answers an empty, non-truncated page instead
    // of pretending the earlier page was everything.
    let tail = window.diagnosticCommandSnapshot(maximumCommands: 2, startIndex: 9)
    @Assert(tail.status, "ok")
    @Assert(tail.commands.size, 0)
    @Assert(tail.truncated, false)
    @Assert(tail.startIndex, 5)
    @Assert(tail.nextIndex, 5)
    window.close()
}
