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
