// Native submission failure -> participant rollback -> recovery.
//
// The generated candidate is published only when the window's scene transaction
// accepts it. This probe injects a native present failure (test-only seam) while
// a candidate is prepared, and asserts:
//
//   1. the accepted structure version and node identity do not move;
//   2. no candidate stays pending (the participant was rolled back);
//   3. the previously accepted structure is still buildable and addressable;
//   4. a fresh candidate commits normally afterwards, keeping the surviving key
//      identity.
//
// The window, its transaction and the generated holder are production code; only
// the native failure injection is test-only.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

foreign {
    func cjgui_internal_renderer_test_set_composable_present_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
}

private class CommitProbeProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return 4242 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 7 }
    public func draftText(fieldId: String): String { return "draft" }
    public func appliedText(fieldId: String): String { return "applied" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

private class CommitProbeController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    public let holder: CjguiGeneratedUiStructureHolder
    private let provider = CommitProbeProvider()
    private var version: Int64 = 1

    public init(catalog: CjguiGeneratedUiCapabilityCatalog) {
        this.holder = CjguiGeneratedUiStructureHolder(catalog,
            rootScope: CjguiComposableUiIdentityScope("commit-probe"))
    }

    public func bump(): Unit {
        version += 1
    }

    public func uiSceneVersion(): Int64 {
        return version
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(10, "commit-probe-root", CjguiComposableUiStyle(gap: 4))
        root.add(cjguiComposableText(11, "commit-probe-caption", "提交回滚探针", CjguiComposableUiStyle()))
        root.add(holder.buildRefreshNode(provider))
        return root
    }

    public func beginSceneRefresh(): Bool { return holder.beginCandidateRefresh() }
    public func prepareSceneRefresh(): Bool { return holder.prepareCandidateRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { let _ = holder.commitCandidateRefresh() }
    public func rollbackSceneRefresh(): Unit { holder.rollbackCandidateRefresh() }

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

private let COMMIT_PROBE_S1: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel vertical
NODE 1 fieldA textInput field=label
END
"""

private let COMMIT_PROBE_S2: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 panel2 vertical
NODE 1 note label
PROPERTY 1 note text 第二版
NODE 1 fieldA textInput field=label
END
"""

private func commitProbeCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 16))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([CjguiGeneratedUiPropertySpec("text", "STRING", required: true)]),
        false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "字段", "TEXT", 4242,
        writeActionName: "EDIT_DRAFT_TEXT"))
    return catalog
}

main(): Int64 {
    let controller = CommitProbeController(commitProbeCatalog())
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_GENERATED_COMMIT start=false status=${window.nativeStatus()}")
        return 1
    }
    let holder = controller.holder

    // First structure is accepted normally.
    if (!holder.submit(CjguiGeneratedUiEncoding.decode(COMMIT_PROBE_S1).root.getOrThrow(), CommitProbeProvider()).candidateAccepted) {
        println("CJGUI_GENERATED_COMMIT submit_s1=false")
        window.close()
        return 1
    }
    controller.bump()
    if (!window.refreshIfNeeded() || holder.structureVersion() != 1) {
        println("CJGUI_GENERATED_COMMIT commit_s1=false version=${holder.structureVersion()}")
        window.close()
        return 1
    }
    let acceptedId = holder.nodeIdForKey("fieldA")
    if (acceptedId <= 0) {
        println("CJGUI_GENERATED_COMMIT identity_missing=true")
        window.close()
        return 1
    }
    println("CJGUI_GENERATED_COMMIT first_commit version=1 node=${acceptedId}")

    // A candidate is prepared while the next native present fails.
    if (!holder.submit(CjguiGeneratedUiEncoding.decode(COMMIT_PROBE_S2).root.getOrThrow(), CommitProbeProvider()).candidateAccepted) {
        println("CJGUI_GENERATED_COMMIT submit_s2=false")
        window.close()
        return 1
    }
    controller.bump()
    let injected = unsafe {
        cjgui_internal_renderer_test_set_composable_present_failures(window.testSessionToken(), 1u32)
    }
    let refreshed = window.refreshIfNeeded()
    let failed = window.windowProjection()
    let nativeFailed = failed.lastNativeFailure != "none"
    let rolledBack = holder.structureVersion() == 1 && !holder.hasPendingCandidate() &&
        holder.nodeIdForKey("fieldA") == acceptedId && holder.nodeIdForKey("note") < 0
    println("CJGUI_GENERATED_COMMIT native_failure injected=${injected} refresh=${refreshed} " +
        "native_failed=${nativeFailed} reason=${failed.lastNativeFailure} rolled_back=${rolledBack} " +
        "version=${holder.structureVersion()} pending=${holder.hasPendingCandidate()}")

    // The previously accepted structure is still addressable and buildable.
    let rebuilt = holder.buildAccepted(CommitProbeProvider())
    let stillUsable = holder.acceptedNodeForKey("fieldA").isSome() &&
        holder.keyForNodeId(acceptedId) == "fieldA" && rebuilt.nodeId >= 0
    println("CJGUI_GENERATED_COMMIT old_structure_usable=${stillUsable}")

    // A fresh candidate commits normally, keeping the surviving identity.
    if (!holder.submit(CjguiGeneratedUiEncoding.decode(COMMIT_PROBE_S2).root.getOrThrow(), CommitProbeProvider()).candidateAccepted) {
        println("CJGUI_GENERATED_COMMIT resubmit=false")
        window.close()
        return 1
    }
    controller.bump()
    let recovered = window.refreshIfNeeded() && holder.structureVersion() == 2 &&
        holder.nodeIdForKey("fieldA") == acceptedId && holder.nodeIdForKey("note") > 0
    println("CJGUI_GENERATED_COMMIT recovered=${recovered} version=${holder.structureVersion()}")

    let passed = injected == CJGUI_INTERNAL_RENDERER_OK && nativeFailed && rolledBack && stillUsable && recovered
    println("CJGUI_GENERATED_COMMIT passed=${passed}")
    window.close()
    return if (passed) { 0 } else { 1 }
}
