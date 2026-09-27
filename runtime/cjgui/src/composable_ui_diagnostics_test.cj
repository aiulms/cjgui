package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private class DiagnosticAcceptedController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var showSelected: Bool = true

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "diagnostic-root", CjguiComposableUiStyle())
        if (showSelected) {
            root.add(cjguiComposableButton(2, "diagnostic-button", "Button", "PRESS", 0,
                CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 32)))
        }
        return root
    }
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

@Test
func diagnosticsAcceptedPaginationRemovalAndReopen(): Unit {
    let owner = DiagnosticAcceptedController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.start(), true)
    let first = window.diagnosticSnapshot(maximumNodes: 1)
    @Assert(first.status, "ok")
    @Assert(first.nodes.size <= 1, true)
    @Assert(first.totalNodes > 1, true)
    @Assert(first.truncated, true)
    @Assert(first.overlayEnabled, false)
    @Assert(first.submittedSceneVersion, first.acceptedSceneVersion)
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
        selectedIdentityKey: "semantic:diagnostic-button")), true)
    let shown = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(shown.overlayEnabled, true)
    @Assert(shown.nativeSubmissionCount, first.nativeSubmissionCount)
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
        selectedIdentityKey: "semantic:missing")), false)
    @Assert(window.diagnosticSnapshot(maximumNodes: 8).overlayEnabled, true)

    owner.showSelected = false
    owner.revision += 1
    @Assert(window.refresh(), true)
    let afterRemoval = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(afterRemoval.acceptedSceneVersion > first.acceptedSceneVersion, true)
    @Assert(afterRemoval.overlayEnabled, true)
    @Assert(window.diagnosticSnapshot(maximumNodes: 8,
        expectedSessionIdentity: first.sessionIdentity,
        expectedAcceptedSceneVersion: first.acceptedSceneVersion).status, "stale_accepted")
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(false)), true)
    window.close()
    let closed = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(closed.status, "closed")
    @Assert(closed.nodes.size, 0)
    @Assert(window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true)), false)

    @Assert(window.start(), true)
    let reopened = window.diagnosticSnapshot(maximumNodes: 8)
    @Assert(reopened.status, "ok")
    @Assert(reopened.sessionIdentity != first.sessionIdentity, true)
    @Assert(reopened.overlayEnabled, false)
    window.close()
}
