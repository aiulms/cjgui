package cjgui

import std.collection.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class AliasSceneOwner <: CjguiGeneratedUiRegionBinding {
    var a: String = "A draft"
    var b: String = "B draft"
    var aVersion: Int64 = 0
    var bVersion: Int64 = 0
    public func ownerRevision(): Int64 { return aVersion + bVersion }
    public func fieldResourceId(fieldId: String): Int64 { return 6201 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 6200 }
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return if (instanceKey == "cardA") { 6301 } else if (instanceKey == "cardB") { 6302 } else { 6200 }
    }
    public func draftText(fieldId: String): String { return "fallback" }
    public func draftText(fieldId: String, instanceKey: String): String {
        return if (instanceKey == "cardA") { a } else if (instanceKey == "cardB") { b } else { "fallback" }
    }
    public func appliedText(fieldId: String): String { return "fallback" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "test_noop")
    }
    public func actionAvailable(actionName: String): Bool { return false }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rangeTextEditSupported(fieldId: String): Bool { return true }
    public func rangeTextEditSupported(fieldId: String, instanceKey: String): Bool {
        return instanceKey == "cardA" || instanceKey == "cardB"
    }
    public func fieldTextVersion(fieldId: String): Int64 { return -1 }
    public func fieldTextVersion(fieldId: String, instanceKey: String): Int64 {
        return if (instanceKey == "cardA") { aVersion } else if (instanceKey == "cardB") { bVersion } else { -1 }
    }
    public func confirmFieldTextVersion(fieldId: String, version: Int64, action: () -> Bool,
        instanceKey: String): Bool {
        return fieldTextVersion(fieldId, instanceKey) == version && action()
    }
    public func applyTextEdit(fieldId: String, version: Int64, text: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        if (fieldTextVersion(fieldId, instanceKey) != version) {
            return CjguiRangeTextEditOutcome.conflict(version, "version_moved")
        }
        if (instanceKey == "cardA") { a = text; aVersion += 1 }
        else if (instanceKey == "cardB") { b = text; bVersion += 1 }
        else { return CjguiRangeTextEditOutcome.rejected(version, "unknown_owner") }
        return CjguiRangeTextEditOutcome.accepted(version, version + 1)
    }
}

private class AliasSceneController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let owner = AliasSceneOwner()
    let region: CjguiGeneratedUiWindowRegion
    var key: String = "cardA"
    var handwritten: Bool = true
    var revision: Int64 = 1
    var commits: Int64 = 0
    var rollbacks: Int64 = 0
    init() {
        let catalog = CjguiGeneratedUiCapabilityCatalog()
        let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("jobName", "Name", "TEXT", 6201))
        region = CjguiGeneratedUiWindowRegion(catalog, owner, "alias-scene-test")
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func commitSceneRefresh(): Unit { region.commitSceneRefresh(); commits += 1 }
    public func rollbackSceneRefresh(): Unit { region.rollbackSceneRefresh(); rollbacks += 1 }
    public func rollbackSceneRefresh(reason: String): Unit { region.rollbackSceneRefresh(reason); rollbacks += 1 }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList() }
    public func disposeSceneRefreshResources(): Unit { region.disposeSceneRefreshResources() }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9700, "alias-root", CjguiComposableUiStyle())
        // This is the application's actual prepare-time clear/redeclare pattern.
        region.clearHandwrittenInstanceAliases()
        if (handwritten) {
            region.declareHandwrittenInstanceAlias(9710, key)
            root.add(cjguiComposableTextInput(9710, "alias-name", "Name", owner.draftText("jobName", key),
                6201, CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 32), fieldId: "jobName",
                operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: owner.fieldOperationResourceId("jobName", key)))
        } else { root.add(cjguiComposableText(9701, "alias-generated", "Generated", CjguiComposableUiStyle())) }
        root.add(region.buildNode())
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return region.handleEvent(event)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

// Continue one original pending scene, as the existing source-handoff driver
// does. A participant terminal stops this driver, including a rejection: no
// requestRefresh/re-submission is hidden in this completion loop.
private func aliasSceneComplete(window: CjguiComposableUiWindow, controller: AliasSceneController): Bool {
    let commits = controller.commits
    let rollbacks = controller.rollbacks
    let started = MonoTime.now()
    while (controller.commits == commits && controller.rollbacks == rollbacks &&
        (MonoTime.now() - started).toNanoseconds() < 5000000000) {
        let _ = window.refreshIfNeeded()
        if (controller.commits != commits || controller.rollbacks != rollbacks) { break }
        let _ = window.pump(0u32)
    }
    println("ALIAS_SCENE_TERMINAL commit=${controller.commits - commits} " +
        "rollback=${controller.rollbacks - rollbacks} accepted=${window.windowProgress().acceptedSceneVersion}")
    return controller.commits > commits && controller.rollbacks == rollbacks
}

@Test
func handwrittenAliasScenePreparationAndRollbackKeepAcceptedRangeSource(): Unit {
    let controller = AliasSceneController()
    let window = CjguiComposableUiWindow(controller, configuration:
        CjguiMacosApplicationWindowConfiguration("alias scene contract", 480u32, 240u32,
            rangeTextEditDeltaDelivery: true))
    controller.region.attachWindow(window)
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0 || aliasSceneComplete(window, controller), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        @Assert(window.focusAcceptedNodeById(9710), true)
        let session = window.textSession().getOrThrow()
        @Assert(window.ownedTextSessionBoundNodeId(), 9710)
        let ticket = session.freezeSelectionTicket()
        @Assert(ticket.sourceVersion, 0)
        @Assert(session.selectionTicketMatches(ticket), true)
        controller.handwritten = false
        @Assert(controller.beginSceneRefresh(), true)
        let _ = controller.buildUi()
        let preparedTicketMatches = session.selectionTicketMatches(ticket)
        let preparedSourceVersion = session.freezeSelectionTicket().sourceVersion
        controller.rollbackSceneRefresh("test_rejected_scene")
        println("ALIAS_SCENE_PREPARE source=${preparedSourceVersion} ticket=${preparedTicketMatches} " +
            "rollbackSource=${session.freezeSelectionTicket().sourceVersion}")
        @Assert(preparedTicketMatches, true)
        @Assert(preparedSourceVersion, 0)
        @Assert(session.selectionTicketMatches(ticket), true)
        @Assert(controller.owner.a, "A draft")
        @Assert(controller.owner.b, "B draft")
    } finally { window.close() }
}

@Test
func handwrittenAliasSceneAcceptedRebindRetiresOldInputAndPreservesOtherOwner(): Unit {
    let controller = AliasSceneController()
    let window = CjguiComposableUiWindow(controller, configuration:
        CjguiMacosApplicationWindowConfiguration("alias owner rebind", 480u32, 240u32,
            rangeTextEditDeltaDelivery: true))
    controller.region.attachWindow(window)
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0 || aliasSceneComplete(window, controller), true)
        @Assert(window.focusAcceptedNodeById(9710), true)
        let old = window.textSession().getOrThrow()
        let before = window.windowProgress().acceptedSceneVersion
        controller.key = "cardB"
        controller.revision += 1
        window.requestRefresh()
        let accepted = aliasSceneComplete(window, controller)
        println("ALIAS_SCENE_REBIND before=${before} after=${window.windowProgress().acceptedSceneVersion} " +
            "oldBound=${old.isBound()}")
        @Assert(accepted, true)
        @Assert(window.windowProgress().acceptedSceneVersion > before, true)
        @Assert(old.isBound(), false)
        @Assert(old.replaceRange16(0, 0, "late A").accepted, false)
        @Assert(window.focusAcceptedNodeById(9710), true)
        let fresh = window.textSession().getOrThrow()
        @Assert(refEq(old, fresh), false)
        @Assert(fresh.replaceRange16(0, 0, "B+").accepted, true)
        @Assert(controller.owner.a, "A draft")
        @Assert(controller.owner.b, "B+B draft")
        @Assert(controller.owner.aVersion, 0)
        @Assert(controller.owner.bVersion, 1)
    } finally { window.close() }
}

@Test
func handwrittenAliasSceneAcceptedRemovalAndReaddNeverReviveOldInput(): Unit {
    let controller = AliasSceneController()
    let window = CjguiComposableUiWindow(controller, configuration:
        CjguiMacosApplicationWindowConfiguration("alias removal", 480u32, 240u32,
            rangeTextEditDeltaDelivery: true))
    controller.region.attachWindow(window)
    try {
        @Assert(window.start(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > 0 || aliasSceneComplete(window, controller), true)
        @Assert(window.focusAcceptedNodeById(9710), true)
        let old = window.textSession().getOrThrow()
        let before = window.windowProgress().acceptedSceneVersion
        controller.handwritten = false
        controller.revision += 1
        window.requestRefresh()
        let accepted = aliasSceneComplete(window, controller)
        println("ALIAS_SCENE_REMOVE before=${before} after=${window.windowProgress().acceptedSceneVersion} " +
            "oldBound=${old.isBound()}")
        @Assert(accepted, true)
        @Assert(window.windowProgress().acceptedSceneVersion > before, true)
        @Assert(old.isBound(), false)
        @Assert(window.ownedTextSessionBoundNodeId(), -1)
        @Assert(old.replaceRange16(0, 0, "late removed").accepted, false)
        controller.handwritten = true
        controller.revision += 1
        window.requestRefresh()
        @Assert(aliasSceneComplete(window, controller), true)
        @Assert(window.focusAcceptedNodeById(9710), true)
        @Assert(old.replaceRange16(0, 0, "late returned").accepted, false)
        let fresh = window.textSession().getOrThrow()
        @Assert(refEq(old, fresh), false)
        @Assert(fresh.replaceRange16(0, 0, "A+").accepted, true)
        @Assert(controller.owner.a, "A+A draft")
        @Assert(controller.owner.b, "B draft")
    } finally { window.close() }
}
