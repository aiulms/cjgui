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

// B: a generated scroll in an ordinary, non-scrolling host. The content is
// several rows tall so the public viewport has a real offset range.
private let COMMIT_PROBE_SCROLL: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 scrollOuter vertical
NODE 1 panelScroll scrollArea
PROPERTY 1 panelScroll offset 0
NODE 2 scrollContent vertical
NODE 3 row0 label
PROPERTY 3 row0 text 行0
NODE 3 row1 label
PROPERTY 3 row1 text 行1
NODE 3 row2 label
PROPERTY 3 row2 text 行2
NODE 3 row3 label
PROPERTY 3 row3 text 行3
NODE 3 row4 label
PROPERTY 3 row4 text 行4
NODE 3 row5 label
PROPERTY 3 row5 text 行5
NODE 3 row6 label
PROPERTY 3 row6 text 行6
NODE 3 row7 label
PROPERTY 3 row7 text 行7
END
"""

// The same scroll instance with much shorter content: the accepted offset must
// clamp to the new range instead of leaving blank space.
private let COMMIT_PROBE_SCROLL_SHORT: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 scrollOuter vertical
NODE 1 panelScroll scrollArea
PROPERTY 1 panelScroll offset 0
NODE 2 scrollContent vertical
NODE 3 row0 label
PROPERTY 3 row0 text 行0
END
"""

// A structure that no longer contains the scroll instance at all.
private let COMMIT_PROBE_NO_SCROLL: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 plainRoot vertical
NODE 1 caption label
PROPERTY 1 caption text 无滚动
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
    // The generated scroll container: the framework's public viewport with the
    // ONE property it consumes, so the probe exercises the production
    // presentation instead of a hand-written wrapper.
    let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        scrollProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
        childLimit: 1))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "字段", "TEXT", 4242,
        writeActionName: "EDIT_DRAFT_TEXT"))
    return catalog
}

/// The PUBLIC viewport fact of the probe's single generated scroll, exactly as
/// the window publishes it in its progress projection.
private func commitProbeViewportFact(window: CjguiComposableUiWindow): String {
    for (fact in window.windowProgress().viewportFacts) {
        if (fact.startsWith("WINDOW_VIEWPORT ")) {
            return fact
        }
    }
    return ""
}

/// The accepted rectangle of one node in the window's ACCEPTED scene.
private func commitProbeAcceptedBounds(window: CjguiComposableUiWindow, nodeId: Int64): CjguiComposableUiRect {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return node.bounds
        }
    }
    return CjguiComposableUiRect(0, 0, 0, 0)
}

private func commitProbeSubmit(holder: CjguiGeneratedUiStructureHolder, source: String,
    provider: CjguiGeneratedUiBindingProvider): Bool {
    return holder.submit(CjguiGeneratedUiEncoding.decode(source).root.getOrThrow(), provider).candidateAccepted
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

    // --- B: viewport facts are CANDIDATE facts --------------------------------
    // A generated scroll is accepted normally, then a real offset request is laid
    // out while the NEXT native present fails. The PUBLIC window must keep the
    // previous accepted offset/extent/scene, the request must survive, and the
    // next legal refresh must present exactly it with the content really moving.
    let scrollSubmission = holder.submit(CjguiGeneratedUiEncoding.decode(COMMIT_PROBE_SCROLL).root.getOrThrow(),
        CommitProbeProvider())
    if (!scrollSubmission.candidateAccepted) {
        println("CJGUI_GENERATED_COMMIT submit_scroll=false reason=${scrollSubmission.reason}")
        window.close()
        return 1
    }
    controller.bump()
    let scrollCommitted = window.refreshIfNeeded() && holder.nodeIdForKey("panelScroll") > 0
    let viewport = holder.scrollViewportForInstance("panelScroll", 0)
    let factAccepted = commitProbeViewportFact(window)
    let offsetBefore = viewport.acceptedOffset()
    let contentBefore = viewport.contentExtent()
    let extentBefore = viewport.viewportExtent()
    let sceneBefore = window.windowProgress().acceptedSceneVersion
    let rowNodeId = holder.nodeIdForKey("row3")
    let rowBefore = commitProbeAcceptedBounds(window, rowNodeId)
    let request = viewport.maximumOffset()
    let requested = request > 0 && viewport.requestOffset(request)
    println("CJGUI_GENERATED_COMMIT scroll_accepted committed=${scrollCommitted} content=${contentBefore} " +
        "viewport=${extentBefore} accepted=${offsetBefore} request=${request} requested=${requested} fact='${factAccepted}'")

    controller.bump()
    let injectedScroll = unsafe {
        cjgui_internal_renderer_test_set_composable_present_failures(window.testSessionToken(), 1u32)
    }
    let rejectedRefresh = window.refreshIfNeeded()
    let rejectedProgress = window.windowProgress()
    let factRejected = commitProbeViewportFact(window)
    let rejectedKeptOld = injectedScroll == CJGUI_INTERNAL_RENDERER_OK &&
        rejectedProgress.acceptedSceneVersion == sceneBefore && rejectedProgress.lastNativeFailure != "none" &&
        viewport.acceptedOffset() == offsetBefore && viewport.contentExtent() == contentBefore &&
        viewport.viewportExtent() == extentBefore && viewport.hasPendingRequest() &&
        factRejected.contains("accepted=${offsetBefore}") && factRejected.contains("content=${contentBefore}") &&
        factRejected.contains("viewport=${extentBefore}") && factRejected.contains("pending=1")
    println("CJGUI_GENERATED_COMMIT scroll_rejected injected=${injectedScroll} refresh=${rejectedRefresh} " +
        "reason=${rejectedProgress.lastNativeFailure} scene=${rejectedProgress.acceptedSceneVersion}/${sceneBefore} " +
        "accepted=${viewport.acceptedOffset()} content=${viewport.contentExtent()} pending=${viewport.hasPendingRequest()} " +
        "kept_old=${rejectedKeptOld} fact='${factRejected}'")

    controller.bump()
    let presentedRefresh = window.refreshIfNeeded()
    let factPresented = commitProbeViewportFact(window)
    let rowAfter = commitProbeAcceptedBounds(window, rowNodeId)
    let presented = presentedRefresh && viewport.acceptedOffset() == request && !viewport.hasPendingRequest() &&
        factPresented.contains("accepted=${request}") && factPresented.contains("pending=0") &&
        rowAfter.y == rowBefore.y - request
    println("CJGUI_GENERATED_COMMIT scroll_presented refresh=${presentedRefresh} accepted=${viewport.acceptedOffset()} " +
        "request=${request} row_y=${rowBefore.y}->${rowAfter.y} presented=${presented} fact='${factPresented}'")

    // Shorter content: the accepted offset clamps into the new range instead of
    // leaving blank space, and the viewport keeps its real geometry.
    if (!commitProbeSubmit(holder, COMMIT_PROBE_SCROLL_SHORT, CommitProbeProvider())) {
        println("CJGUI_GENERATED_COMMIT submit_short=false")
        window.close()
        return 1
    }
    controller.bump()
    let shrunkRefresh = window.refreshIfNeeded()
    let shrunk = shrunkRefresh && viewport.contentExtent() < contentBefore &&
        viewport.acceptedOffset() <= viewport.maximumOffset() && viewport.viewportExtent() > 0 &&
        !viewport.hasPendingRequest()
    println("CJGUI_GENERATED_COMMIT scroll_shrunk refresh=${shrunkRefresh} content=${viewport.contentExtent()} " +
        "accepted=${viewport.acceptedOffset()} max=${viewport.maximumOffset()} viewport=${viewport.viewportExtent()} " +
        "clamped=${shrunk}")

    // Removing the instance releases its view state: the same key declared again
    // resolves to a FRESH viewport instead of inheriting the removed one.
    if (!commitProbeSubmit(holder, COMMIT_PROBE_NO_SCROLL, CommitProbeProvider())) {
        println("CJGUI_GENERATED_COMMIT submit_removed=false")
        window.close()
        return 1
    }
    controller.bump()
    let removedRefresh = window.refreshIfNeeded()
    let freshViewport = holder.scrollViewportForInstance("panelScroll", 0)
    let released = removedRefresh && freshViewport.acceptedOffset() == 0 && freshViewport.contentExtent() == 0 &&
        freshViewport.viewportExtent() == 0 && freshViewport.acceptedSolveCount() == 0 &&
        !freshViewport.hasPendingRequest()
    println("CJGUI_GENERATED_COMMIT scroll_released refresh=${removedRefresh} fresh_accepted=${freshViewport.acceptedOffset()} " +
        "fresh_content=${freshViewport.contentExtent()} fresh_viewport=${freshViewport.viewportExtent()} " +
        "solves=${freshViewport.acceptedSolveCount()} released=${released}")

    let passed = injected == CJGUI_INTERNAL_RENDERER_OK && nativeFailed && rolledBack && stillUsable && recovered &&
        scrollCommitted && requested && rejectedKeptOld && presented && shrunk && released
    println("CJGUI_GENERATED_COMMIT passed=${passed} scroll_committed=${scrollCommitted} rejected_kept_old=${rejectedKeptOld} " +
        "presented=${presented} shrunk=${shrunk} released=${released}")
    window.close()
    return if (passed) { 0 } else { 1 }
}
