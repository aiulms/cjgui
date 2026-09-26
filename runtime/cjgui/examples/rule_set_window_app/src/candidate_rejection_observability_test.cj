// Window-level contract for a rejected scene candidate.
//
// The framework refuses an invalid candidate (for example two declarations
// sharing one numeric node id) and keeps the previously accepted scene live.
// That rejection must stay diagnosable through window progress: an external
// operator driving the window has to be able to tell why the visible scene did
// not follow its change without a diagnostic build. This test pins the concrete
// reason, the retained scene, and the recovery once the declaration is fixed.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class CjguiRejectingSceneController <: CjguiComposableUiController {
    private var versionValue: Int64 = 1
    // When set, the second declaration reuses the first one's node id.
    public var duplicateNodeId: Bool = false
    // Ordinary content of the second declaration, used to prove the window is
    // fully working again after a rejection.
    public var secondLabel: String = "第二"

    public func bump(): Unit {
        versionValue += 1
    }

    public func uiSceneVersion(): Int64 {
        return versionValue
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "reject-root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(2, "reject-first", "第一", "REJECT_FIRST", -1,
            CjguiComposableUiStyle(fixedHeight: 30)))
        root.add(cjguiComposableButton(if (duplicateNodeId) { 2 } else { 3 }, "reject-second", secondLabel,
            "REJECT_SECOND", -1, CjguiComposableUiStyle(fixedHeight: 30)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}
@Test
func rejectedCandidateKeepsLiveSceneAndPublishesItsReason(): Unit {
    let controller = CjguiRejectingSceneController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let accepted = window.windowProjection()
    @Assert(accepted.acceptedSceneVersion > 0, true)
    @Assert(accepted.lastNativeFailure, "none")

    // A duplicate declaration is rejected; the accepted scene must not move.
    controller.duplicateNodeId = true
    controller.bump()
    @Assert(window.refreshIfNeeded(), false)
    let rejected = window.windowProjection()
    @Assert(rejected.lastNativeFailure, "duplicate_node_id")
    @Assert(rejected.pendingRefreshReason, "refresh_duplicate_node_id")
    @Assert(rejected.acceptedSceneVersion, accepted.acceptedSceneVersion)
    @Assert(rejected.submittedSceneVersion, accepted.submittedSceneVersion)

    // Fixing the declaration recovers in the same session, without a restart.
    // The repaired declaration is identical to the accepted scene again, so the
    // window legitimately republishes it without a new native scene version.
    controller.duplicateNodeId = false
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let recovered = window.windowProjection()
    @Assert(recovered.lastNativeFailure, "none")
    @Assert(recovered.pendingRefreshReason, "none")
    @Assert(recovered.acceptedSceneVersion, accepted.acceptedSceneVersion)
    @Assert(window.isOpen(), true)

    // A real content change after the rejection must still reach the window.
    controller.secondLabel = "第二（已恢复）"
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let functioning = window.windowProjection()
    @Assert(functioning.lastNativeFailure, "none")
    @Assert(functioning.acceptedSceneVersion > accepted.acceptedSceneVersion, true)
    window.close()
}

// --- rejected scene with a generated candidate ------------------------------
//
// A generated structure is only published when the window's scene transaction
// accepts it. When the scene is rejected (here: a duplicate declaration in the
// handwritten half of the same scene), the candidate must be rolled back: the
// accepted structure, its version and the accepted editor stay operable, and a
// later legal structure can still be committed.

private class CjguiGeneratedRejectionSceneController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let region: CjguiRuleSetGeneratedRegion
    private var versionValue: Int64 = 1
    // When set, the second declaration reuses the first one's node id.
    public var duplicateNodeId: Bool = false

    public init(domain: CjguiRuleSetEditingDomain) {
        this.region = CjguiRuleSetGeneratedRegion(domain)
        this.versionValue = 1
    }

    public func generatedRegion(): CjguiRuleSetGeneratedRegion {
        return region
    }

    public func bump(): Unit {
        versionValue += 1
    }

    public func uiSceneVersion(): Int64 {
        return versionValue + region.revision()
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let root = cjguiComposableVertical(1, "gen-reject-root", CjguiComposableUiStyle(gap: 4))
        root.add(cjguiComposableButton(2, "gen-reject-anchor", "锚点", "GEN_ANCHOR", -1,
            CjguiComposableUiStyle(fixedHeight: 30)))
        root.add(cjguiComposableButton(if (duplicateNodeId) { 2 } else { 3 }, "gen-reject-second", "第二",
            "GEN_SECOND", -1, CjguiComposableUiStyle(fixedHeight: 30)))
        root.add(region.buildSection(theme, CjguiComposableUiStyle()))
        return root
    }

    public func beginSceneRefresh(): Bool {
        return region.beginSceneRefresh()
    }

    public func prepareSceneRefresh(): Bool {
        return region.prepareSceneRefresh()
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }

    public func commitSceneRefresh(): Unit {
        region.commitSceneRefresh()
    }

    public func rollbackSceneRefresh(): Unit {
        region.rollbackSceneRefresh()
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

private let GEN_REJECT_S1: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 nameField textInput field=label
END
"""

private let GEN_REJECT_S2: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel2 vertical
NODE 1 note label
PROPERTY 1 note text 第二版
NODE 1 nameField textInput field=label
END
"""

@Test
func rejectedSceneRollsBackGeneratedCandidateAndKeepsEditor(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("回滚续写", true, 7, "cache", "gen-reject-create").applied, true)
    let recordId = domain.selectedRecordId()
    @Assert(recordId >= 0, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()

    // First structure is accepted normally.
    @Assert(region.submitStructure(GEN_REJECT_S1, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let acceptedBefore = window.windowProjection()
    let nodeBefore = region.acceptedNodeIdForKey("nameField")
    @Assert(nodeBefore > 0, true)

    // The next candidate is received while the scene itself becomes invalid.
    @Assert(region.submitStructure(GEN_REJECT_S2, 1).candidateAccepted, true)
    controller.duplicateNodeId = true
    controller.bump()
    @Assert(window.refreshIfNeeded(), false)
    let rejected = window.windowProjection()
    @Assert(rejected.lastNativeFailure, "duplicate_node_id")
    @Assert(rejected.acceptedSceneVersion, acceptedBefore.acceptedSceneVersion)
    // The generated candidate was rolled back with the scene: nothing was
    // published, and its identities are gone.
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.acceptedNodeIdForKey("nameField"), nodeBefore)
    @Assert(region.acceptedNodeIdForKey("note"), -1)

    // The old accepted editor still writes the owner it was rendered for.
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    let editor = CjguiComposableUiLayoutNode(
        cjguiComposableTextInput(nodeBefore, "gen-reject-nameField", "规则名称", "",
            CjguiRuleSetEditingDomain.formLabelResourceId, CjguiComposableUiStyle(fixedHeight: 26),
            fieldId: "label", operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: recordId,
            displayValueRole: "draft"),
        bounds, bounds)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(editor, 28, "回滚后仍可写", 0, 0, 1)).didApply, true)
    @Assert(domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText,
        "回滚后仍可写")

    // Recovery: a repaired scene republishes the accepted structure, and a
    // fresh candidate can then be committed with the same identity.
    controller.duplicateNodeId = false
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.submitStructure(GEN_REJECT_S2, 1).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedNodeIdForKey("nameField"), nodeBefore)
    @Assert(window.windowProjection().lastNativeFailure, "none")
    window.close()
}

// Candidate OWNERSHIP at the application provider (package A1): the token is
// allocated before the payload is decoded, so a malformed submit and a
// structure-version conflict are attributable to their own attempt, and two
// submitters that share a base version stay distinguishable.
@Test
func generatedCandidateTicketsArePerAttemptInTheApplicationProvider(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("票据归属", true, 7, "cache", "gen-ticket-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()

    // (a) A payload that never becomes a structure still owns an attempt.
    let malformed = region.submitStructure("GENERATED_UI_STRUCTURE 1\nNODE 0 broken", 0)
    @Assert(malformed.accepted, false)
    @Assert(malformed.candidateToken > 0, true)
    let malformedTicket = region.candidateTicketPayload(malformed.candidateToken)
    @Assert(malformedTicket.contains("TERMINAL_STATE REJECTED"), true)
    @Assert(malformedTicket.contains("REASON malformed_node"), true)

    // (b) A structure-version conflict is also THIS attempt's rejection.
    let conflict = region.submitStructure(GEN_REJECT_S1, 7)
    @Assert(conflict.accepted, false)
    @Assert(conflict.candidateToken > malformed.candidateToken, true)
    let conflictTicket = region.candidateTicketPayload(conflict.candidateToken)
    @Assert(conflictTicket.contains("REASON structure_version_conflict"), true)
    @Assert(conflictTicket.contains("TERMINAL_STATE REJECTED"), true)

    // (c) Two submits against the SAME base version: the first is superseded,
    // never accepted, and the second becomes the accepted one only after the
    // scene transaction commits.
    let first = region.submitStructure(GEN_REJECT_S1, 0)
    let second = region.submitStructure(GEN_REJECT_S2, 0)
    @Assert(first.candidateAccepted, true)
    @Assert(second.candidateAccepted, true)
    @Assert(second.candidateToken > first.candidateToken, true)
    @Assert(first.receipt != second.receipt, true)
    let firstTicket = region.candidateTicketPayload(first.candidateToken)
    @Assert(firstTicket.contains("TERMINAL_STATE SUPERSEDED"), true)
    @Assert(firstTicket.contains("TERMINAL_STATE ACCEPTED"), false)
    @Assert(region.acceptedStructureVersion(), 0)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let secondTicket = region.candidateTicketPayload(second.candidateToken)
    @Assert(secondTicket.contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(secondTicket.contains("CURRENT_ACCEPTED_TOKEN ${second.candidateToken}"), true)

    // (d) Accepted-then-replaced is an observation, not a rewrite: the earlier
    // ticket stays ACCEPTED while the endpoint reports a newer accepted token.
    let third = region.submitStructure(GEN_REJECT_S1, 1)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 2)
    let replacedTicket = region.candidateTicketPayload(second.candidateToken)
    @Assert(replacedTicket.contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(replacedTicket.contains("ACCEPTED_VERSION 1"), true)
    @Assert(replacedTicket.contains("CURRENT_ACCEPTED_TOKEN ${third.candidateToken}"), true)
    window.close()
}

/// The accepted layout node for one declared key of the generated region.
private func ruleStyleNodeBounds(window: CjguiComposableUiWindow, region: CjguiRuleSetGeneratedRegion,
    key: String): CjguiComposableUiRect {
    let nodeId = region.acceptedNodeIdForKey(key)
    if (nodeId <= 0) {
        return CjguiComposableUiRect(0, 0, 0, 0)
    }
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return node.bounds
        }
    }
    return CjguiComposableUiRect(0, 0, 0, 0)
}

// The framework's shared style vocabulary must change the geometry the RULE
// consumer really accepts: growth consumes the row's slack, a declared font size
// changes the measured height, and a property the presentation would ignore is
// refused at registration instead of being silently dropped.
@Test
func generatedStyleVocabularyReachesTheRuleConsumerGeometry(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("样式验收", true, 7, "cache", "gen-style-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()

    let row = """
GENERATED_UI_STRUCTURE 1
NODE 0 styleRow horizontal
PROPERTY 0 styleRow gap 0
NODE 1 first label
PROPERTY 1 first text 固定
PROPERTY 1 first fixedWidth 40
NODE 1 second label
PROPERTY 1 second text 生长
PROPERTY 1 second growX 1
END
"""
    @Assert(region.submitStructure(row, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let first = ruleStyleNodeBounds(window, region, "first")
    let second = ruleStyleNodeBounds(window, region, "second")
    @Assert(first.width, 40)
    @Assert(second.width > first.width, true)
    @Assert(second.x > first.x, true)

    // A declared font size changes the measured height of the same label.
    let small = """
GENERATED_UI_STRUCTURE 1
NODE 0 smallRoot vertical
NODE 1 smallNote label
PROPERTY 1 smallNote text 小字号
PROPERTY 1 smallNote fontSize 12
END
"""
    let large = """
GENERATED_UI_STRUCTURE 1
NODE 0 largeRoot vertical
NODE 1 largeNote label
PROPERTY 1 largeNote text 大字号
PROPERTY 1 largeNote fontSize 24
END
"""
    @Assert(region.submitStructure(small, 1).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let smallHeight = ruleStyleNodeBounds(window, region, "smallNote").height
    @Assert(region.submitStructure(large, 2).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let largeHeight = ruleStyleNodeBounds(window, region, "largeNote").height
    @Assert(smallHeight > 0, true)
    @Assert(largeHeight > smallHeight, true)

    // The capability the application publishes is the SAME declaration the
    // renderer consumes: a leaf that never applies padding cannot publish it.
    let catalog = CjguiRuleSetGeneratedRegion.buildCatalog(domain)[0]
    let labelSpec = match (catalog.componentFor("label")) {
        case Some(value) => value
        case None => CjguiGeneratedUiComponentSpec("missing",
            ArrayList<CjguiGeneratedUiPropertySpec>(), false)
    }
    if (labelSpec.kind == "label") {
        var paddingPublished = false
        var fontSizePublished = false
        for (property in labelSpec.properties) {
            if (property.name == "padding") { paddingPublished = true }
            if (property.name == "fontSize") { fontSizePublished = true }
        }
        @Assert(fontSizePublished, true)
        @Assert(paddingPublished, false)
    } else {
        @Assert(false, true)
    }
    window.close()
}

/// Reads one `<LABEL> <value>` non-negative number out of an observation payload.
private func observationField(payload: String, label: String): Int64 {
    for (line in payload.split("\n")) {
        let parts = line.split(" ")
        if (parts.size >= 2 && parts[0] == label) {
            let text = parts[1]
            if (text.size == 0) { continue }
            var parsed: Int64 = 0
            var ok = true
            for (byte in text.toArray()) {
                if (byte < 48 || byte > 57) { ok = false; break }
                parsed = parsed * 10 + Int64(byte - 48)
            }
            if (ok) { return parsed }
        }
    }
    return -1
}

// The observation source separates a REBIND from a re-layout: a structure
// change that keeps every key/target binding must not claim BINDINGS, while the
// same declared key pointing at a different owner field must.
@Test
func generatedObservationSeparatesRebindFromRelayout(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("换绑观测", true, 7, "cache", "gen-rebind-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()
    // The same wiring the application performs: the accepted-instance
    // projection (and therefore the binding/geometry/instance revisions) needs
    // the window whose accepted scene carries the generated nodes.
    region.attachWindow(window)

    let s1 = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 nameField textInput field=label
END
"""
    @Assert(region.submitStructure(s1, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let baseline = region.snapshotPayload()
    let streamEpoch = observationField(baseline, "STREAM_EPOCH")
    let baselineCursor = observationField(baseline, "CURSOR")
    @Assert(streamEpoch > 0, true)
    @Assert(baselineCursor >= 0, true)

    // Re-layout: same key, same owner binding, one added label.
    let s2 = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 hint label
PROPERTY 1 hint text 仅重排
NODE 1 nameField textInput field=label
END
"""
    @Assert(region.submitStructure(s2, 1).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let relayout = region.changesPayload(streamEpoch, baselineCursor)
    @Assert(relayout.contains("STRUCTURE"), true)
    @Assert(relayout.contains("BINDINGS"), false)
    let relayoutCursor = observationField(relayout, "CURRENT")
    @Assert(relayoutCursor > baselineCursor, true)

    // Rebind: the SAME declared key now writes a different owner field.
    let s3 = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 hint label
PROPERTY 1 hint text 仅重排
NODE 1 nameField textInput field=excludedType
END
"""
    @Assert(region.submitStructure(s3, 2).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let rebind = region.changesPayload(streamEpoch, relayoutCursor)
    @Assert(rebind.contains("BINDINGS"), true)
    @Assert(rebind.contains("STRUCTURE"), true)
    window.close()
}

/// Bounded history on the REAL application: once the tracker's history floor
/// moves past a cursor, that cursor must be answered with RESYNC_REQUIRED and no
/// fabricated increment.
@Test
func generatedObservationTruncatedHistoryAsksForResync(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("截断观测", true, 7, "cache", "gen-history-create").applied, true)
    // A two-entry history makes truncation reachable with three real changes.
    let region = CjguiRuleSetGeneratedRegion(domain, observationHistoryLimit: 2)
    let baseline = region.snapshotPayload()
    let streamEpoch = observationField(baseline, "STREAM_EPOCH")
    let baselineCursor = observationField(baseline, "CURSOR")
    @Assert(streamEpoch > 0, true)

    // Three real submission attempts: each one moves the candidate state and is
    // observed, so the two-entry history must drop the oldest cursors.
    var cursor = baselineCursor
    var round = 0
    while (round < 3) {
        // A payload that never becomes a structure: the attempt still moves the
        // candidate state, which is what the observation records.
        let _ = region.submitStructure("GENERATED_UI_STRUCTURE 1\nNODE 0 x\n", 99)
        let observed = region.changesPayload(streamEpoch, cursor)
        let current = observationField(observed, "CURRENT")
        @Assert(current > cursor, true)
        @Assert(observed.contains("RESYNC_REQUIRED 0"), true)
        cursor = current
        round += 1
    }
    @Assert(cursor > baselineCursor, true)

    // The cursor from before the truncation is no longer serviceable.
    let truncated = region.changesPayload(streamEpoch, baselineCursor)
    @Assert(truncated.contains("RESYNC_REQUIRED 1"), true)
    @Assert(truncated.contains("CHANGE "), false)
}

/// One application image declaration, from the public discovery text down to the
/// accepted geometry: an unknown key and a stale version are refused as a whole,
/// and swapping the declaration version moves the observation revision while the
/// old accepted interface stays usable.
@Test
func generatedImageDeclarationDrivesDiscoveryAndSwap(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let region = CjguiRuleSetGeneratedRegion(domain)

    // Discovery publishes the logical identity/type/version/name and never the
    // application's raster path.
    let described = region.capabilitiesPayload()
    @Assert(described.contains("IMAGE_RESOURCE rule-set-beacon PNG 1 规则面板图标"), true)
    @Assert(described.contains("composable-beacon.png"), false)

    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let live = controller.generatedRegion()
    live.attachWindow(window)

    let imageStructure = """
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 1
PROPERTY 1 icon fixedWidth 48
PROPERTY 1 icon fixedHeight 48
END
"""
    // Wrong version and unknown key are refused with distinct public reasons.
    let wrongVersion = live.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource rule-set-beacon
PROPERTY 1 icon resourceVersion 7
END
""", 0)
    @Assert(wrongVersion.candidateAccepted, false)
    @Assert(wrongVersion.reason, "image_resource_version_mismatch")
    let unknownKey = live.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource not-registered
PROPERTY 1 icon resourceVersion 1
END
""", 0)
    @Assert(unknownKey.candidateAccepted, false)
    @Assert(unknownKey.reason, "image_resource_not_registered")
    @Assert(live.acceptedStructureVersion(), 0)

    @Assert(live.submitStructure(imageStructure, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(live.acceptedStructureVersion(), 1)
    let iconNodeId = live.acceptedNodeIdForKey("icon")
    @Assert(iconNodeId > 0, true)
    // The public accepted-instance projection (the region's own holder + the
    // attached window) names the logical resource, never the raster path.
    let instances = live.acceptedInstancesPayload()
    @Assert(instances.contains("INSTANCE icon "), true)
    @Assert(instances.contains("kind=image"), true)
    @Assert(instances.contains("resource=rule-set-beacon"), true)
    @Assert(instances.contains("resource_version=1"), true)
    @Assert(instances.contains("composable-beacon.png"), false)

    // Swapping the declaration version moves the observed revision and withdraws
    // the old reference; the accepted scene keeps the resource it accepted.
    let sender = live.snapshotPayload()
    let epoch = observationField(sender, "STREAM_EPOCH")
    let cursor = observationField(sender, "CURSOR")
    @Assert(observationField(sender, "RESOURCE_REVISION") > 0, true)
    @Assert(live.setBeaconVersion(2), true)
    let changes = live.changesPayload(epoch, cursor)
    @Assert(changes.contains("RESOURCES"), true)
    @Assert(live.beaconResource().rasterPath, "composable-beacon-coral.png")
    @Assert(live.beaconResource().version, 2)

    // A candidate that still references the withdrawn version is refused.
    let staleReference = live.submitStructure(imageStructure, 1)
    @Assert(staleReference.candidateAccepted, false)
    @Assert(staleReference.reason, "image_resource_version_mismatch")
    let current = live.snapshotPayload()
    @Assert(observationField(current, "RESOURCE_REVISION") != observationField(sender, "RESOURCE_REVISION"), true)
    // The accepted image state did not silently change with the declaration.
    @Assert(live.acceptedStructureVersion(), 1)
    window.close()
}

/// The DRAFT_HEX token of one published field line, so a test can prove a
/// non-target draft did not move.
private func fieldDraftToken(fields: String, fieldId: String): String {
    for (line in fields.split("\n")) {
        let parts = line.split(" ")
        if (parts.size >= 2 && parts[0] == "FIELD" && parts[1] == fieldId) {
            var index = 0
            while (index < parts.size) {
                if (parts[index] == "DRAFT_HEX" && index + 1 < parts.size) {
                    return parts[index + 1]
                }
                index += 1
            }
        }
    }
    return ""
}

/// A real declaration swap must NOT empty the accepted generated interface. After
/// the application redeclares the same key at v2 and an ORDINARY refresh runs
/// (with no structure resubmission), the accepted image instance, its version,
/// the sampled resource state and the field editor stay addressable, and the
/// human's unapplied draft survives. A legal v2 candidate is then accepted with
/// the same draft; the withdrawn v1 reference stays refused.
@Test
func generatedAcceptedInterfaceKeepsEditingAcrossDeclarationSwap(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("换版连续", true, 7, "cache", "gen-continuity-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()
    region.attachWindow(window)

    let v1 = """
GENERATED_UI_STRUCTURE 1
NODE 0 continuityRoot vertical
NODE 1 beacon image
PROPERTY 1 beacon resource rule-set-beacon
PROPERTY 1 beacon resourceVersion 1
PROPERTY 1 beacon fixedWidth 48
PROPERTY 1 beacon fixedHeight 48
NODE 1 nameEditor textInput field=label
PROPERTY 1 nameEditor label 规则名称编辑
END
"""
    @Assert(region.submitStructure(v1, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let acceptedV1 = region.acceptedInstancesPayload()
    @Assert(acceptedV1.contains("kind=image"), true)
    @Assert(acceptedV1.contains("resource_version=1"), true)
    @Assert(acceptedV1.contains("kind=textInput"), true)
    // The accepted reference publishes a real preparation state, not a path.
    @Assert(acceptedV1.contains("resource=rule-set-beacon resource_version=1 resource_state="), true)
    @Assert(acceptedV1.contains("resource=rule-set-beacon resource_version=1 resource_state=-"), false)
    @Assert(acceptedV1.contains("composable-beacon.png"), false)

    // A human draft that was NOT applied.
    let recordId = domain.selectedRecordId()
    let draftVersion = domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftFieldVersion
    let arguments = ArrayList<CjguiSharedOperationActionArgument>()
    arguments.add(CjguiSharedOperationActionArgument("fieldId", CjguiSharedOperationValue.string("label")))
    arguments.add(CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string("换版草稿")))
    arguments.add(CjguiSharedOperationActionArgument("expectedDraftVersion",
        CjguiSharedOperationValue.integer(draftVersion)))
    @Assert(domain.executeFromHuman(CjguiSharedOperationActionInvocation("EDIT_DRAFT_TEXT",
        domain.version(), ArrayList<Int64>([recordId]), arguments)).applied, true)
    let draftToken = fieldDraftToken(region.fieldsPayload(), "label")
    @Assert(draftToken.size > 0, true)

    // The application's own swap: the catalog only has v2 from here on.
    let beforeSwap = region.snapshotPayload()
    @Assert(region.setBeaconVersion(2), true)
    @Assert(region.capabilitiesPayload().contains("IMAGE_RESOURCE rule-set-beacon PNG 2"), true)
    // An ORDINARY refresh, with NO structure resubmission.
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let afterSwap = region.acceptedInstancesPayload()
    @Assert(afterSwap.contains("kind=image"), true)
    @Assert(afterSwap.contains("resource=rule-set-beacon"), true)
    @Assert(afterSwap.contains("resource_version=1"), true)
    @Assert(afterSwap.contains("kind=textInput"), true)
    @Assert(fieldDraftToken(region.fieldsPayload(), "label"), draftToken)
    // The declaration change and the sampled resource state are observable.
    let afterSnapshot = region.snapshotPayload()
    @Assert(observationField(afterSnapshot, "RESOURCE_REVISION") !=
        observationField(beforeSwap, "RESOURCE_REVISION"), true)
    @Assert(observationField(afterSnapshot, "IMAGE_RESOURCE_STATE_REVISION") > 0, true)

    // The withdrawn v1 reference is refused; the legal v2 candidate is accepted.
    let withdrawn = region.submitStructure(v1, 1)
    @Assert(withdrawn.candidateAccepted, false)
    @Assert(withdrawn.reason, "image_resource_version_mismatch")
    let v2 = """
GENERATED_UI_STRUCTURE 1
NODE 0 continuityRoot vertical
NODE 1 beacon image
PROPERTY 1 beacon resource rule-set-beacon
PROPERTY 1 beacon resourceVersion 2
PROPERTY 1 beacon fixedWidth 48
PROPERTY 1 beacon fixedHeight 48
NODE 1 nameEditor textInput field=label
PROPERTY 1 nameEditor label 规则名称编辑
END
"""
    @Assert(region.submitStructure(v2, 1).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 2)
    let acceptedV2 = region.acceptedInstancesPayload()
    @Assert(acceptedV2.contains("resource_version=2"), true)
    @Assert(acceptedV2.contains("kind=textInput"), true)
    @Assert(fieldDraftToken(region.fieldsPayload(), "label"), draftToken)
    window.close()
}

/// ONE named paint role drives the handwritten helper, the generated action node
/// and (through the shared context) the registered composite. Switching the
/// application's appearance repaints them together and preserves the human's
/// draft, focus, selection and the accepted image binding.
@Test
func sharedNamedStyleDrivesGeneratedPaintAndKeepsEditing(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("主题连续", true, 7, "cache", "gen-theme-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()
    region.attachWindow(window)

    // Discovery publishes the named style and its interaction paint.
    let described = region.capabilitiesPayload()
    @Assert(described.contains("STYLE rule_primary_action "), true)
    @Assert(described.contains("STYLE_STATE rule_primary_action normal["), true)

    let structure = """
GENERATED_UI_STRUCTURE 1
NODE 0 themeRoot vertical
NODE 1 themeBeacon image
PROPERTY 1 themeBeacon resource rule-set-beacon
PROPERTY 1 themeBeacon resourceVersion 1
PROPERTY 1 themeBeacon fixedWidth 40
PROPERTY 1 themeBeacon fixedHeight 40
NODE 1 themeAction action action=APPLY_DRAFT
PROPERTY 1 themeAction label 应用
PROPERTY 1 themeAction style rule_primary_action
NODE 1 themeEditor textInput field=label
PROPERTY 1 themeEditor label 规则名称编辑
END
"""
    @Assert(region.submitStructure(structure, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(region.acceptedStructureVersion(), 1)
    let actionNodeId = region.acceptedNodeIdForKey("themeAction")
    @Assert(actionNodeId > 0, true)
    let namedOption = region.namedStyle("rule_primary_action")
    @Assert(namedOption.isSome(), true)
    let named = match (namedOption) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("", CjguiComposableUiStyle())
    }
    var actionPaint = ""
    var actionResolved = ""
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == actionNodeId) {
            // `declaredStyle` is the immutable declared paint; `style` is the paint
            // resolved for the current interaction state. The DECLARED paint must be
            // exactly the application's named style; the resolved one may carry an
            // interaction overlay.
            actionPaint = sharedPaintSignature(node.declaredStyle)
            actionResolved = sharedPaintSignature(node.style)
            @Assert(node.interactionStyle.hover.background.isSome(), true)
            @Assert(actionPaint, sharedPaintSignature(named.base))
            @Assert(node.style.background.red, node.declaredStyle.background.red)
        }
    }
    @Assert(actionPaint.size > 0, true)

    // A human draft that was NOT applied, with focus and selection.
    let recordId = domain.selectedRecordId()
    let draftVersion = domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftFieldVersion
    let arguments = ArrayList<CjguiSharedOperationActionArgument>()
    arguments.add(CjguiSharedOperationActionArgument("fieldId", CjguiSharedOperationValue.string("label")))
    arguments.add(CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string("主题草稿")))
    arguments.add(CjguiSharedOperationActionArgument("expectedDraftVersion",
        CjguiSharedOperationValue.integer(draftVersion)))
    @Assert(domain.executeFromHuman(CjguiSharedOperationActionInvocation("EDIT_DRAFT_TEXT",
        domain.version(), ArrayList<Int64>([recordId]), arguments)).applied, true)
    let draftToken = fieldDraftToken(region.fieldsPayload(), "label")
    let identityBefore = region.acceptedNodeIdForKey("themeEditor")
    let imageBefore = region.acceptedInstancesPayload()

    // The application's own appearance switch retargets the named style.
    @Assert(region.setAccentAppearance(true), true)
    @Assert(region.capabilitiesPayload().contains("STYLE rule_primary_action "), true)
    @Assert(window.refreshIfNeeded(), true)

    // Paint changed on the SAME accepted structure, geometry and identity.
    var switchedPaint = ""
    var switchedResolved = ""
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == actionNodeId) {
            switchedPaint = sharedPaintSignature(node.declaredStyle)
            switchedResolved = sharedPaintSignature(node.style)
        }
    }
    @Assert(switchedPaint.size > 0, true)
    // The declared paint followed the application's named style, and the resolved
    // paint of the SAME identity really changed.
    @Assert(switchedPaint, sharedPaintSignature(CjguiRuleSetGeneratedRegion.accentStyle(true).base))
    @Assert(switchedResolved != actionResolved, true)
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.acceptedNodeIdForKey("themeEditor"), identityBefore)
    @Assert(fieldDraftToken(region.fieldsPayload(), "label"), draftToken)
    let imageAfter = region.acceptedInstancesPayload()
    @Assert(imageAfter.contains("resource_version=1"), true)
    @Assert(imageAfter.contains("kind=textInput"), true)
    // A color-only change moves no layout: the accepted instance bounds are equal.
    @Assert(instanceBoundsText(imageBefore, "themeEditor"), instanceBoundsText(imageAfter, "themeEditor"))
    @Assert(instanceBoundsText(imageBefore, "themeBeacon"), instanceBoundsText(imageAfter, "themeBeacon"))
    window.close()
}

/// The full paint of one style, so a theme switch is compared on everything that
/// may change and not on the background alone.
private func sharedPaintSignature(style: CjguiComposableUiStyle): String {
    return "${cjguiComposableUiColorToken(style.background)}|${cjguiComposableUiColorToken(style.border)}|" +
        "${cjguiComposableUiColorToken(style.textColor)}|${style.borderWidth}"
}

/// The accepted `bounds=` text of one declared key, so a paint-only change can be
/// proven not to move layout.
private func instanceBoundsText(payload: String, key: String): String {
    for (line in payload.split("\n")) {
        let parts = line.split(" ")
        if (parts.size >= 2 && parts[0] == "INSTANCE" && parts[1] == key) {
            for (part in parts) {
                if (part.startsWith("bounds=")) {
                    return part
                }
            }
        }
    }
    return ""
}

/// The STYLES section is really generated and really re-read: a definition
/// change is observed as STYLES and the client reads the concrete new paint, a
/// withdrawal removes the name while the section stays a real (possibly empty)
/// directory, and a stale cursor serializes nothing.
@Test
func stylesSectionPublishesUpdateRemovalAndEmptyDirectory(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let region = CjguiRuleSetGeneratedRegion(domain)
    let snapshot = region.snapshotPayload()
    let epoch = observationField(snapshot, "STREAM_EPOCH")
    let cursor = observationField(snapshot, "CURSOR")
    @Assert(epoch > 0, true)

    // The two variants share a background; the border and interaction paint
    // differ, so the border token is the discriminating one.
    let lightToken = cjguiComposableUiColorToken(CjguiRuleSetGeneratedRegion.accentStyle(false).base.border)
    let darkToken = cjguiComposableUiColorToken(CjguiRuleSetGeneratedRegion.accentStyle(true).base.border)
    @Assert(lightToken != darkToken, true)

    let baseline = region.sectionPayload("STYLES", cursor)
    @Assert(baseline.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    @Assert(baseline.contains("SNAPSHOT_STYLE "), true)
    @Assert(baseline.contains("STYLE rule_primary_action "), true)
    @Assert(baseline.contains("border=${lightToken}"), true)
    @Assert(baseline.contains("STYLE_REVISION "), true)

    // A stale cursor serializes NO section.
    let stale = region.sectionPayload("STYLES", cursor + 99)
    @Assert(stale.contains("SNAPSHOT_REVISION_CHANGED 1"), true)
    @Assert(stale.contains("SNAPSHOT_STYLE"), false)

    // A real definition change: observed as STYLES, then re-read concretely.
    @Assert(region.setAccentAppearance(true), true)
    let changes = region.changesPayload(epoch, cursor)
    @Assert(changes.contains("STYLES"), true)
    let updatedCursor = observationField(changes, "CURRENT")
    @Assert(updatedCursor > cursor, true)
    let updated = region.sectionPayload("STYLES", updatedCursor)
    @Assert(updated.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    @Assert(updated.contains("border=${darkToken}"), true)
    @Assert(updated.contains("border=${lightToken}"), false)

    // Withdrawal: the name disappears, the section stays a real directory.
    @Assert(region.withdrawNamedStyle("rule_primary_action"), true)
    let removedChanges = region.changesPayload(epoch, updatedCursor)
    @Assert(removedChanges.contains("STYLES"), true)
    let removedCursor = observationField(removedChanges, "CURRENT")
    let removed = region.sectionPayload("STYLES", removedCursor)
    @Assert(removed.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    @Assert(removed.contains("STYLE rule_primary_action"), false)
    @Assert(removed.contains("STYLE_REVISION "), true)

    // Re-registering publishes the name again for fresh candidates.
    @Assert(region.setAccentAppearance(true), false)
    @Assert(region.withdrawNamedStyle("rule_primary_action"), false)
}

/// Owner progress and structure-candidate progress are separate facts: an
/// ordinary business write makes the owner projection pending until the window
/// accepts a scene built from it, and no structure candidate is involved.
@Test
func generatedObservationSeparatesOwnerProgressFromCandidatePending(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("进度观测", true, 7, "cache", "gen-progress-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()
    region.attachWindow(window)

    let structural = """
GENERATED_UI_STRUCTURE 1
NODE 0 progressRoot vertical
NODE 1 nameField textInput field=label
END
"""
    @Assert(region.submitStructure(structural, 0).candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    let settled = region.snapshotPayload()
    @Assert(observationField(settled, "OWNER_PENDING_SCENE"), 0)
    @Assert(observationField(settled, "STRUCTURE_CANDIDATE_PENDING"), 0)

    // An ordinary business write with NO structure candidate: the owner value is
    // new, the accepted scene is still the old projection, so owner progress is
    // pending while the structure candidate stays idle.
    let recordId = domain.selectedRecordId()
    let draftVersion = domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftFieldVersion
    let arguments = ArrayList<CjguiSharedOperationActionArgument>()
    arguments.add(CjguiSharedOperationActionArgument("fieldId", CjguiSharedOperationValue.string("label")))
    arguments.add(CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string("进度已写入")))
    arguments.add(CjguiSharedOperationActionArgument("expectedDraftVersion",
        CjguiSharedOperationValue.integer(draftVersion)))
    let edit = domain.executeFromHuman(CjguiSharedOperationActionInvocation("EDIT_DRAFT_TEXT",
        domain.version(), ArrayList<Int64>([recordId]), arguments))
    @Assert(edit.applied, true)
    let pending = region.snapshotPayload()
    @Assert(observationField(pending, "OWNER_PENDING_SCENE"), 1)
    @Assert(observationField(pending, "STRUCTURE_CANDIDATE_PENDING"), 0)
    @Assert(observationField(pending, "OWNER_FIELD_REVISION") !=
        observationField(settled, "OWNER_FIELD_REVISION"), true)

    // The window accepts a scene built from the new projection: pending clears.
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let accepted = region.snapshotPayload()
    @Assert(observationField(accepted, "OWNER_PENDING_SCENE"), 0)
    @Assert(observationField(accepted, "STRUCTURE_CANDIDATE_PENDING"), 0)

    // A structure candidate is pending on its own, without pretending an owner
    // projection changed.
    @Assert(region.submitStructure(structural, 1).candidateAccepted, true)
    let candidatePending = region.snapshotPayload()
    @Assert(observationField(candidatePending, "STRUCTURE_CANDIDATE_PENDING"), 1)
    @Assert(observationField(candidatePending, "OWNER_PENDING_SCENE"), 0)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(observationField(region.snapshotPayload(), "STRUCTURE_CANDIDATE_PENDING"), 0)
    window.close()
}

/// A guarded section read performs only the work it is asked for: a stale cursor
/// serializes nothing, and a valid request serializes exactly one section. The
/// accepted-instance enumeration (the O(n) source sample) is reported separately
/// so bandwidth reduction is never presented as zero CPU work.
@Test
func generatedSectionReadsDoOnlyTheRequestedWork(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("工作量观测", true, 7, "cache", "gen-work-create").applied, true)
    let controller = CjguiGeneratedRejectionSceneController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let region = controller.generatedRegion()
    region.attachWindow(window)

    region.testResetWorkCounts()
    let baseline = region.snapshotPayload()
    @Assert(region.testWorkCounts(), "counts=fields:1 structure:1 instances:1 samples:1")
    let cursor = observationField(baseline, "CURSOR")

    // A cursor that no longer matches serializes NOTHING.
    region.testResetWorkCounts()
    let stale = region.sectionPayload("FIELDS", cursor + 99)
    @Assert(stale.contains("SNAPSHOT_REVISION_CHANGED 1"), true)
    @Assert(region.testWorkCounts(), "counts=fields:0 structure:0 instances:0 samples:1")

    // A valid FIELDS request serializes only FIELDS.
    region.testResetWorkCounts()
    let fields = region.sectionPayload("FIELDS", cursor)
    @Assert(fields.contains("SNAPSHOT_FIELD"), true)
    @Assert(region.testWorkCounts(), "counts=fields:1 structure:0 instances:0 samples:1")

    // A valid INSTANCES request serializes only INSTANCES.
    region.testResetWorkCounts()
    let _ = region.sectionPayload("INSTANCES", cursor)
    @Assert(region.testWorkCounts(), "counts=fields:0 structure:0 instances:1 samples:1")

    // The section response carries its own provenance.
    @Assert(fields.contains("SECTION FIELDS"), true)
    @Assert(observationField(fields, "STREAM_EPOCH") > 0, true)
    window.close()
}
