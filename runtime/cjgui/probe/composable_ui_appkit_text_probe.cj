package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*

// These test-only entries drive the production AppKit event path. They expose
// scalar evidence only; application code cannot receive native objects.
foreign {
    func cjgui_internal_renderer_test_edit_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_composable_text_matches(session: UInt64, expected: CString): Int32
    func cjgui_internal_renderer_test_composable_multiline_fallback_runs(
        session: UInt64, outExpectedFallbackRuns: CPointer<UInt32>, outMismatchedRuns: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_insert_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_delete_composable_text(session: UInt64, nodeIndex: UInt32): Int32
    func cjgui_internal_renderer_test_press_composable_node(
        session: UInt64, nodeIndex: UInt32
    ): Int32
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_multiline_proxy_opacity(
        session: UInt64, outScrollAlpha: CPointer<Float32>, outTextAlpha: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_scroll_composable_multiline(
        session: UInt64, deltaY: Float32, outScrollOffset: CPointer<Float32>, outVisibleGlyphCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_drag_composable_text_selection(
        session: UInt64, nodeIndex: UInt32,
        startX: Float32, startY: Float32, endX: Float32, endY: Float32,
        outSelectionStart: CPointer<UInt32>, outSelectionEnd: CPointer<UInt32>
    ): Int32
    // This normal keyDown route is intentionally absent before the focus
    // chain is implemented. It must not be replaced by FIFO injection.
    func cjgui_internal_renderer_test_send_composable_key(
        session: UInt64, keyCode: UInt16, modifiers: UInt64, outFocusedNodeId: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_standard_editing_commands(session: UInt64): Int32
    // Candidate placement must be derived from the self-drawn editor, not
    // the off-canvas NSTextView used solely for macOS text services.
    func cjgui_internal_renderer_test_composable_candidate_rect(
        session: UInt64, location: UInt32, length: UInt32,
        outX: CPointer<Float32>, outY: CPointer<Float32>,
        outWidth: CPointer<Float32>, outHeight: CPointer<Float32>
    ): Int32
    // The resize helper changes an actual NSWindow content size and only
    // succeeds after its production delegate has advanced the revision.
    func cjgui_internal_renderer_test_resize_composable_window(
        session: UInt64, outResizeVersion: CPointer<UInt64>
    ): Int32
    // Test-only: toggles a controlled backing-scale source and posts the
    // ordinary NSWindow backing-properties notification. The Cangjie window
    // must still observe the resulting production geometry revision itself.
    func cjgui_internal_renderer_test_toggle_composable_backing_scale(
        session: UInt64, outResizeVersion: CPointer<UInt64>,
        outBeforeScale: CPointer<Float64>, outAfterScale: CPointer<Float64>,
        outDrawableWidth: CPointer<UInt32>, outDrawableHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_multiline_layout_ownership(
        session: UInt64, outCacheEntries: CPointer<UInt32>,
        outCacheHighWater: CPointer<UInt32>,
        outBuildsAfterFirstPass: CPointer<UInt64>, outBuildsAfterSecondPass: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_local_acknowledgement_count(
        session: UInt64, outCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_input_timing(
        session: UInt64, outMutationMicros: CPointer<UInt64>, outTextDelegateMicros: CPointer<UInt64>,
        outSelectionDelegateMicros: CPointer<UInt64>, outEventEnqueueMicros: CPointer<UInt64>,
        outAccessibilityMicros: CPointer<UInt64>
    ): Int32
    // Test-only scalar trace for one normal NSTextView insertion. It keeps
    // the current production default, while allowing the probe to compare
    // that default with a no-temporary-single-line candidate without exposing
    // any native TextKit object to the framework.
    func cjgui_internal_renderer_test_set_composable_bounded_input_layout(
        session: UInt64, enabled: UInt8
    ): Int32
    // Test-only one-shot A/B control: selection either reuses the accepted
    // body texture or forces the existing full body preparation path.
    func cjgui_internal_renderer_test_set_composable_selection_body_preparation_mode(
        session: UInt64, mode: UInt8
    ): Int32
    func cjgui_internal_renderer_test_reset_composable_input_callback_trace(session: UInt64): Int32
    func cjgui_internal_renderer_test_composable_input_callback_trace(
        session: UInt64,
        outSuperInsertMicros: CPointer<UInt64>, outModeChangeCount: CPointer<UInt64>,
        outModeChangeMicros: CPointer<UInt64>, outTextCallbackCount: CPointer<UInt64>,
        outTextCallbackMicros: CPointer<UInt64>, outSelectionCallbackCount: CPointer<UInt64>,
        outPendingEditSelectionCount: CPointer<UInt64>, outSelectionCallbackMicros: CPointer<UInt64>,
        outSelectionRevealMicros: CPointer<UInt64>, outSelectionQueueMicros: CPointer<UInt64>,
        outSelectionAccessibilityMicros: CPointer<UInt64>, outRefreshMicros: CPointer<UInt64>,
        outPreparationMicros: CPointer<UInt64>, outWholeAttributeWriteCount: CPointer<UInt64>,
        outWholeAttributeCharacters: CPointer<UInt64>, outFallbackApplyCount: CPointer<UInt64>,
        outFallbackCharacters: CPointer<UInt64>, outFallbackMicros: CPointer<UInt64>
    ): Int32
    // Production text rendering remains native; this test-only scalar view
    // distinguishes CPU bitmap raster work from the Metal texture upload.
    // It deliberately cannot return a texture, bitmap or AppKit object.
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>,
        outUploadBytes: CPointer<UInt64>, outUploadMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_work_reason_stats(
        session: UInt64,
        outUnknownRaster: CPointer<UInt64>, outStaticCandidateRaster: CPointer<UInt64>,
        outActiveContentRaster: CPointer<UInt64>, outSelectionCaretRaster: CPointer<UInt64>,
        outVisibleTileScrollRaster: CPointer<UInt64>, outRetryRaster: CPointer<UInt64>,
        outProjectionGeometryRaster: CPointer<UInt64>,
        outExternalProjectionContentRaster: CPointer<UInt64>,
        outUnknownUpload: CPointer<UInt64>, outStaticCandidateUpload: CPointer<UInt64>,
        outActiveContentUpload: CPointer<UInt64>, outSelectionCaretUpload: CPointer<UInt64>,
        outVisibleTileScrollUpload: CPointer<UInt64>, outRetryUpload: CPointer<UInt64>,
        outProjectionGeometryUpload: CPointer<UInt64>,
        outExternalProjectionContentUpload: CPointer<UInt64>,
        outLastProjectionVersion: CPointer<UInt64>, outLastContentUtf8Bytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_stats(
        session: UInt64, outShapeNodeCount: CPointer<UInt32>, outShapeBatchCount: CPointer<UInt32>,
        outTextureDrawCount: CPointer<UInt32>, outShapeVertexBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_batch_stats(
        session: UInt64, outVertexStride: CPointer<UInt32>, outMaxShapeBatchVertexBytes: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_encoder_cpu_stats(
        session: UInt64, outEncodeMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_text_preparation_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_text_preparation_failures_remaining(
        session: UInt64, outFailureCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_active_text_resource_preparation_state(
        session: UInt64, outScheduled: CPointer<UInt8>, outFailed: CPointer<UInt8>, outRetryCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_active_layout_work_counts(
        session: UInt64, outRangeLayoutCount: CPointer<UInt64>, outFullLayoutCount: CPointer<UInt64>
    ): Int32
    // Fine-grained test-only observability for one active TextKit graph. It
    // returns scalars only; no native object or callback crosses into Cangjie.
    func cjgui_internal_renderer_test_reset_composable_active_layout_trace(session: UInt64): Int32
    func cjgui_internal_renderer_test_composable_active_layout_trace(
        session: UInt64,
        outCharacterEnsureCount: CPointer<UInt64>, outCharacterEnsureMicros: CPointer<UInt64>,
        outBoundingEnsureCount: CPointer<UInt64>, outBoundingEnsureMicros: CPointer<UInt64>,
        outGlyphIndexCount: CPointer<UInt64>, outGlyphIndexMicros: CPointer<UInt64>,
        outLineFragmentCount: CPointer<UInt64>, outLineFragmentMicros: CPointer<UInt64>,
        outGlyphLocationCount: CPointer<UInt64>, outGlyphLocationMicros: CPointer<UInt64>,
        outPositionProxyMicros: CPointer<UInt64>, outPositionNoopWrites: CPointer<UInt64>,
        outPositionChangedWrites: CPointer<UInt64>, outFirstUnlaidBefore: CPointer<UInt64>,
        outFirstUnlaidAfter: CPointer<UInt64>, outInvalidatedLocation: CPointer<UInt64>,
        outInvalidatedLength: CPointer<UInt64>, outRevealMicros: CPointer<UInt64>,
        outCandidateMicros: CPointer<UInt64>, outPositionFirstUnlaidBefore: CPointer<UInt64>,
        outPositionFirstUnlaidAfter: CPointer<UInt64>, outPositionChangedMask: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_nstextview_insert_baseline(
        text: CString, selectionLocation: UInt32, contentWidth: Float32, outMutationMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_nstextview_insert_visible_layout_baseline(
        text: CString, selectionLocation: UInt32, contentWidth: Float32, outMutationMicros: CPointer<UInt64>,
        outSelectionLayoutMicros: CPointer<UInt64>
    ): Int32
    // Test-only composition seam: it drives NSTextInputClient, while the
    // application continues to receive only a normal text-changed event.
    func cjgui_internal_renderer_test_set_composable_marked_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_commit_composable_marked_text(
        session: UInt64, text: CString
    ): Int32
}

private let LONG_MULTILINE_TEXT = "第01行 scrolling line\n第02行 scrolling line\n第03行 scrolling line\n第04行 scrolling line\n第05行 scrolling line\n第06行 scrolling line\n第07行 scrolling line\n第08行 scrolling line\n第09行 scrolling line\n第10行 scrolling line\n第11行 scrolling line\n第12行 scrolling line\n第13行 scrolling line\n第14行 scrolling line\n第15行 scrolling line\n第16行 scrolling line"

private class AppKitTextController <: CjguiComposableUiController {
    private let document: CjguiTextDocument
    private let singleDocument: CjguiTextDocument
    private let staticRowCount: Int64
    private var draft: String
    private var navigationDraft: String
    private var singleDraft: String
    private var appliedValue: String
    private var textEvents: Int64
    private var booleanEvents: Int64
    private var enabled: Bool
    private var resourceId: Int64
    private var sceneRevision: Int64
    private var editorEnabled: Bool
    private var editorReadOnly: Bool
    private var lastHumanOwnerMs: Int64
    private var rejectsNextClose: Bool

    init(staticRowCount: Int64) {
        this.document = CjguiTextDocument(42, "AppKit 探针", "initial")
        this.singleDocument = CjguiTextDocument(43, "单行探针", "single")
        this.staticRowCount = staticRowCount
        this.draft = "initial"
        this.navigationDraft = "navigation"
        this.singleDraft = "single"
        this.appliedValue = ""
        this.textEvents = 0
        this.booleanEvents = 0
        this.enabled = false
        this.resourceId = 42
        this.sceneRevision = 1
        this.editorEnabled = true
        this.editorReadOnly = false
        this.lastHumanOwnerMs = 0
        this.rejectsNextClose = true
    }

    public func uiSceneVersion(): Int64 { return sceneRevision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "appkit-probe-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableMultilineTextInput(2, "appkit-probe-text", "", draft, resourceId,
            CjguiComposableUiStyle(fixedHeight: 96), enabled: editorEnabled, readOnly: editorReadOnly, tabInsertsText: true))
        root.add(cjguiComposableMultilineTextInput(5, "appkit-probe-navigation", "", navigationDraft, resourceId,
            CjguiComposableUiStyle(fixedHeight: 32)))
        root.add(cjguiComposableBooleanInput(3, "appkit-probe-enabled", "enabled", enabled, resourceId,
            CjguiComposableUiStyle(fixedHeight: 32)))
        root.add(cjguiComposableButton(4, "appkit-probe-apply", "apply", "APPLY", resourceId,
            CjguiComposableUiStyle(fixedHeight: 32)))
        root.add(cjguiComposableTextInput(6, "appkit-probe-single", "", singleDraft, resourceId,
            CjguiComposableUiStyle(fixedHeight: 32)))
        var row: Int64 = 0
        while (row < staticRowCount) {
            root.add(cjguiComposableText(1000 + row, "appkit-probe-static-${row}", "static-${row}",
                CjguiComposableUiStyle(fixedHeight: 14, fontSize: 10.0)))
            row += 1
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            let started = MonoTime.now()
            let result = document.replaceProjectionTextFromHuman(event.text)
            lastHumanOwnerMs = (MonoTime.now() - started).toMilliseconds()
            if (result.applied) {
                draft = document.snapshot().content
                textEvents += 1
            }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 28 && event.node.nodeId == 6) {
            let result = singleDocument.replaceProjectionTextFromHuman(event.text)
            if (result.applied) { singleDraft = singleDocument.snapshot().content }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 29 && event.node.nodeId == 3) {
            enabled = event.text == "true"
            booleanEvents += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "APPLY") {
            appliedValue = draft
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        if (rejectsNextClose) {
            rejectsNextClose = false
            return CjguiComposableUiDispatchResult(false)
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func acceptedTextBeforeApplyAfter(textEventCount: Int64): Bool {
        return textEvents == textEventCount + 1 && appliedValue == LONG_MULTILINE_TEXT
    }

    public func observedTextEvents(): Int64 { return textEvents }
    public func observedBooleanEvents(): Int64 { return booleanEvents }
    public func isEnabled(): Bool { return enabled }
    public func rebindResource(): Unit { resourceId = 43 }
    // The native test holds one committed event in its FIFO while this uses
    // the production document's version-checked external mutation path.
    // The scene refresh therefore represents a real owner replacement, not
    // a controller-local string assignment.
    public func replaceDraftFromExternal(value: String): Bool {
        let before = document.snapshot()
        let result = document.replaceRangeFromExternal(
            CjguiTextDocumentRange(0, before.content.size), value, before.version
        )
        if (result.applied) { draft = document.snapshot().content; sceneRevision += 1 }
        return result.applied
    }
    public func replaceInactiveNavigation(value: String): Bool {
        navigationDraft = value
        sceneRevision += 1
        return true
    }
    public func setEditorReadOnly(value: Bool): Unit { editorReadOnly = value; sceneRevision += 1 }
    public func setEditorEnabled(value: Bool): Unit { editorEnabled = value; sceneRevision += 1 }
    public func compositionCommittedOnceAfter(eventCount: Int64, value: String): Bool {
        return textEvents == eventCount + 1 && draft == value
    }
    public func hasDraft(value: String): Bool { return draft == value }
    public func undoLastHuman(): Bool {
        let result = document.undoFromHuman()
        if (result.applied) { draft = document.snapshot().content; sceneRevision += 1 }
        return result.applied
    }
    public func redoLastHuman(): Bool {
        let result = document.redoFromHuman()
        if (result.applied) { draft = document.snapshot().content; sceneRevision += 1 }
        return result.applied
    }
    public func documentContentSize(): Int64 { return document.snapshot().content.size }
    public func documentVersion(): Int64 { return document.snapshot().version }
    public func currentDraft(): String { return draft }
    public func lastDocumentOwnerMs(): Int64 { return lastHumanOwnerMs }
}

// The four projections below deliberately share only the existing document
// owner.  A window owns its controller and native session, while the document
// remains the sole mutation/CAS authority; no controller keeps a writable
// mirror of its text.
private class MultiWindowDocumentController <: CjguiComposableUiController {
    private let document: CjguiTextDocument
    private let viewName: String
    private var rejectsNextClose: Bool

    init(document: CjguiTextDocument, viewName: String) {
        this.document = document
        this.viewName = viewName
        this.rejectsNextClose = true
    }

    public func uiSceneVersion(): Int64 {
        return document.snapshot().version
    }

    public func buildUi(): CjguiComposableUiNode {
        let snapshot = document.snapshot()
        let root = cjguiComposableVertical(1, "multi-window-root-${viewName}",
            CjguiComposableUiStyle(padding: 12, gap: 8))
        // Keep an ordinary AppKit-editable control in the controlled probe so
        // its human mutation travels through the normal native delegate and
        // the existing Cangjie document owner, rather than a test-only write.
        root.add(cjguiComposableTextInput(2, "multi-window-input-${viewName}", "${viewName}",
            snapshot.content, snapshot.documentId, CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            return CjguiComposableUiDispatchResult(document.replaceProjectionTextFromHuman(event.text).applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        if (rejectsNextClose) {
            rejectsNextClose = false
            return CjguiComposableUiDispatchResult(false)
        }
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func appendFromExternal(value: String): Bool {
        let before = document.snapshot()
        return document.replaceRangeFromExternal(
            CjguiTextDocumentRange(before.content.size, before.content.size), value, before.version
        ).applied
    }

    public func content(): String {
        return document.snapshot().content
    }

    public func sharedDocument(): CjguiTextDocument {
        return document
    }
}

/// The exit owner deliberately rejects the callback's application-exit
/// request. The probe proves that this ordinary business rejection does not
/// tear down a sibling or consume the one outer-turn event wait.
private class ReentrantApplicationExitDecision <: CjguiMacosApplicationExitDecisionProvider {
    private var requestCount: Int64

    init() {
        this.requestCount = 0
    }

    public func requestApplicationExit(): Bool {
        requestCount += 1
        return false
    }

    public func observedRequestCount(): Int64 {
        return requestCount
    }
}

private class ReentrantPassiveController <: CjguiComposableUiController {
    private let semanticId: String

    init(semanticId: String) {
        this.semanticId = semanticId
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "reentrant-passive-root-${semanticId}",
            CjguiComposableUiStyle(padding: 12))
        root.add(cjguiComposableTextInput(2, "reentrant-passive-input-${semanticId}", semanticId, "initial", 8301,
            CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(event.eventKind == 28)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

/// This controller performs three structural application calls while its
/// normal AppKit text event is being delivered: it asks to close B, asks for
/// an application exit that business rejects, and attempts to open C. The
/// application must defer B's close, reject opening C for the active turn,
/// and reject nested pumping without using a second wait.
private class ReentrantApplicationController <: CjguiComposableUiController {
    private var application: ?CjguiMacosApplication
    private var siblingIdentifier: ?CjguiMacosApplicationWindowIdentifier
    private var didTrigger: Bool
    private var closeQueued: Bool
    private var exitRejected: Bool
    private var openRejected: Bool
    private var nestedWaitWasSuppressed: Bool

    init() {
        this.application = None
        this.siblingIdentifier = None
        this.didTrigger = false
        this.closeQueued = false
        this.exitRejected = false
        this.openRejected = false
        this.nestedWaitWasSuppressed = false
    }

    public func arm(application: CjguiMacosApplication, sibling: CjguiMacosApplicationWindowIdentifier): Unit {
        this.application = Some(application)
        this.siblingIdentifier = Some(sibling)
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "reentrant-active-root", CjguiComposableUiStyle(padding: 12))
        root.add(cjguiComposableTextInput(2, "reentrant-active-input", "A", "initial", 8301,
            CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2 && !didTrigger) {
            didTrigger = true
            if (let Some(activeApplication) <- application) {
                let nested = activeApplication.pumpOneTurn(turnBudgetMs: 1u32)
                var nestedWaited = false
                if (let Some(_) <- nested.waitedWindow) {
                    nestedWaited = true
                }
                nestedWaitWasSuppressed = nested.eventWaitBudgetMs == 0u32 && !nestedWaited
                if (let Some(sibling) <- siblingIdentifier) {
                    closeQueued = activeApplication.requestClose(sibling)
                }
                exitRejected = !activeApplication.requestApplicationExit()
                let open = activeApplication.openWindow(ReentrantPassiveController("C"),
                    configuration: CjguiMacosApplicationWindowConfiguration("CJGUI reentrant C", 360u32, 220u32))
                openRejected = !open.didOpen && open.reason == "application_turn_active"
            }
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func callbackResultIsSafe(): Bool {
        return didTrigger && closeQueued && exitRejected && openRejected && nestedWaitWasSuppressed
    }
}

private func applicationHasLiveWindow(application: CjguiMacosApplication,
    identifier: CjguiMacosApplicationWindowIdentifier): Bool {
    if (let Some(_) <- application.window(identifier)) {
        return true
    }
    return false
}

private func waitedForIdentifier(result: CjguiMacosApplicationTurnResult,
    identifier: CjguiMacosApplicationWindowIdentifier): Bool {
    if (let Some(waited) <- result.waitedWindow) {
        return waited.value == identifier.value && waited.generation == identifier.generation
    }
    return false
}

private func exerciseMultiWindowApplication(
    application: CjguiMacosApplication,
    controllerA: MultiWindowDocumentController,
    controllerB: MultiWindowDocumentController,
    controllerC: MultiWindowDocumentController,
    controllerD: MultiWindowDocumentController,
    identifierA: CjguiMacosApplicationWindowIdentifier,
    identifierB: CjguiMacosApplicationWindowIdentifier,
    identifierC: CjguiMacosApplicationWindowIdentifier,
    identifierD: CjguiMacosApplicationWindowIdentifier,
    configuration: CjguiMacosApplicationWindowConfiguration
): Bool {
    var passed = application.windowIdentifiers().size == 4 && internalRendererOccupiedSessionCount() == 4u32

    // Four 1ms turns prove that the application has one bounded wait and
    // rotates it across every live projection instead of allowing A to own a
    // per-window full wait.
    let first = application.pumpOneTurn(turnBudgetMs: 1u32)
    let second = application.pumpOneTurn(turnBudgetMs: 1u32)
    let third = application.pumpOneTurn(turnBudgetMs: 1u32)
    let fourth = application.pumpOneTurn(turnBudgetMs: 1u32)
    passed = passed && first.windowCount == 4 && second.windowCount == 4 && third.windowCount == 4 && fourth.windowCount == 4 &&
        first.eventWaitBudgetMs <= 1u32 && second.eventWaitBudgetMs <= 1u32 && third.eventWaitBudgetMs <= 1u32 && fourth.eventWaitBudgetMs <= 1u32 &&
        waitedForIdentifier(first, identifierA) && waitedForIdentifier(second, identifierB) &&
        waitedForIdentifier(third, identifierC) && waitedForIdentifier(fourth, identifierD)

    if (passed) {
        if (let Some(windowA) <- application.window(identifierA)) {
            // This delegates to the normal NSTextView route in this test-only
            // probe. `pumpOneTurn` then delivers its ordinary event to the
            // shared Cangjie owner and observes all projections.
            passed = editWithAppKit(windowA, "initial human")
        } else {
            passed = false
        }
    }
    if (passed) {
        let humanTurn = application.pumpOneTurn(turnBudgetMs: 1u32)
        passed = humanTurn.isOpen && controllerA.content() == "initial human" && controllerB.content() == "initial human" &&
            controllerD.content() == "initial human" && controllerC.content() == "other"
    }
    if (passed) {
        passed = controllerB.appendFromExternal(" external")
        let externalTurn = application.pumpOneTurn(turnBudgetMs: 1u32)
        passed = passed && externalTurn.isOpen && controllerA.content() == "initial human external" &&
            controllerB.content() == "initial human external" && controllerD.content() == "initial human external" &&
            controllerC.content() == "other"
    }

    // First close is rejected by A's controller; acceptance retires only A's
    // native generation. B remains live and reopening A must have a fresh
    // public identity that old input cannot address.
    if (passed) {
        passed = !application.requestClose(identifierA) && application.windowIdentifiers().size == 4 &&
            application.requestClose(identifierA) && application.windowIdentifiers().size == 3 &&
            !applicationHasLiveWindow(application, identifierA) && applicationHasLiveWindow(application, identifierB) &&
            internalRendererOccupiedSessionCount() == 3u32
    }
    if (passed) {
        let reopened = application.openWindow(MultiWindowDocumentController(controllerA.sharedDocument(), "A-reopened"),
            configuration: configuration)
        if (let Some(reopenedIdentifier) <- reopened.identifier) {
            passed = reopened.didOpen && reopenedIdentifier.generation > identifierA.generation &&
                !application.requestClose(identifierA) && applicationHasLiveWindow(application, reopenedIdentifier) &&
                application.windowIdentifiers().size == 4 && internalRendererOccupiedSessionCount() == 4u32
            if (passed) {
                let _ = application.pumpOneTurn(turnBudgetMs: 1u32)
                passed = controllerB.content() == "initial human external" && controllerD.content() == "initial human external"
            }
            // All original controllers reject their first close and accept
            // their second. The reopened controller follows the same policy.
            if (passed) {
                passed = !application.requestClose(identifierB) && application.requestClose(identifierB) &&
                    !application.requestClose(identifierC) && application.requestClose(identifierC) &&
                    !application.requestClose(identifierD) && application.requestClose(identifierD) &&
                    !application.requestClose(reopenedIdentifier) && application.requestClose(reopenedIdentifier) &&
                    !application.isOpen() && internalRendererOccupiedSessionCount() == 0u32
            }
        } else {
            passed = false
        }
    }
    application.close()
    return passed
}

private func runMultiWindowApplicationProbe(): Bool {
    let shared = CjguiTextDocument(8101, "共享", "initial")
    let other = CjguiTextDocument(8102, "独立", "other")
    let controllerA = MultiWindowDocumentController(shared, "A")
    let controllerB = MultiWindowDocumentController(shared, "B")
    let controllerC = MultiWindowDocumentController(other, "C")
    let controllerD = MultiWindowDocumentController(shared, "D")
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI multi-window probe", 420u32, 260u32)
    let application = CjguiMacosApplication(maximumWindowCount: 4)
    let openedA = application.openWindow(controllerA, configuration: configuration)
    let openedB = application.openWindow(controllerB, configuration: configuration)
    let openedC = application.openWindow(controllerC, configuration: configuration)
    let openedD = application.openWindow(controllerD, configuration: configuration)
    let overLimit = application.openWindow(MultiWindowDocumentController(shared, "over-limit"), configuration: configuration)
    if (!openedA.didOpen || !openedB.didOpen || !openedC.didOpen || !openedD.didOpen || overLimit.didOpen || overLimit.reason != "window_limit") {
        application.close()
        return false
    }
    if (let Some(identifierA) <- openedA.identifier) {
        if (let Some(identifierB) <- openedB.identifier) {
            if (let Some(identifierC) <- openedC.identifier) {
                if (let Some(identifierD) <- openedD.identifier) {
                    let passed = exerciseMultiWindowApplication(application, controllerA, controllerB, controllerC, controllerD,
                        identifierA, identifierB, identifierC, identifierD, configuration)
                    if (passed) {
                        println("CJGUI_MULTI_WINDOW_APPLICATION windows=1,2,4 shared_owner=appkit_human_and_external close_reject_reopen=passed single_wait_rotation=passed")
                    }
                    return passed
                }
            }
        }
    }
    application.close()
    return false
}

private func runMultiWindowReentrancyProbe(): Bool {
    let exitDecision = ReentrantApplicationExitDecision()
    let application = CjguiMacosApplication(maximumWindowCount: 4, exitDecisionProvider: exitDecision)
    let controllerA = ReentrantApplicationController()
    let controllerB = ReentrantPassiveController("B")
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI reentrant", 360u32, 220u32)
    let openedA = application.openWindow(controllerA, configuration: configuration)
    let openedB = application.openWindow(controllerB, configuration: configuration)
    if (!openedA.didOpen || !openedB.didOpen) {
        application.close()
        return false
    }
    if (let Some(identifierA) <- openedA.identifier) {
        if (let Some(identifierB) <- openedB.identifier) {
            controllerA.arm(application, identifierB)
            let appliedInput = editApplicationWindow(application, identifierA, "callback")
            let turn = application.pumpOneTurn(turnBudgetMs: 2u32)
            let safe = appliedInput && controllerA.callbackResultIsSafe() && exitDecision.observedRequestCount() == 1 &&
                turn.isOpen && application.windowIdentifiers().size == 1 && applicationHasLiveWindow(application, identifierA) &&
                !applicationHasLiveWindow(application, identifierB) && internalRendererOccupiedSessionCount() == 1u32
            application.close()
            let reclaimed = internalRendererOccupiedSessionCount() == 0u32
            if (safe && reclaimed) {
                println("CJGUI_MULTI_WINDOW_REENTRANCY callback_close_deferred=true nested_wait_suppressed=true exit_rejected_preserved_a=true open_rejected_during_turn=true reclaimed=true")
            }
            return safe && reclaimed
        }
    }
    application.close()
    return false
}

/// A controller exception is deliberately allowed to reach the caller: the
/// framework must not turn an application callback failure into an invented
/// successful input result. It must, however, release the outer-turn guard so
/// an independent live projection can take its next ordinary event.
private class ThrowingApplicationController <: CjguiComposableUiController {
    private var throwsNextInput: Bool

    init() {
        this.throwsNextInput = true
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "throwing-application-root", CjguiComposableUiStyle(padding: 12))
        root.add(cjguiComposableTextInput(2, "throwing-application-input", "A", "initial", 8302,
            CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2 && throwsNextInput) {
            throwsNextInput = false
            throw IllegalArgumentException("application_turn_controller_exception")
        }
        return CjguiComposableUiDispatchResult(event.eventKind == 28)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private class ExceptionRecoveryController <: CjguiComposableUiController {
    private var appliedInputCount: Int64

    init() {
        this.appliedInputCount = 0
    }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "exception-recovery-root", CjguiComposableUiStyle(padding: 12))
        root.add(cjguiComposableTextInput(2, "exception-recovery-input", "B", "initial", 8303,
            CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            appliedInputCount += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func observedInputCount(): Int64 { return appliedInputCount }
}

private func runMultiWindowExceptionGuardProbe(): Bool {
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let controllerA = ThrowingApplicationController()
    let controllerB = ExceptionRecoveryController()
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI exception guard", 360u32, 220u32)
    let openedA = application.openWindow(controllerA, configuration: configuration)
    let openedB = application.openWindow(controllerB, configuration: configuration)
    if (!openedA.didOpen || !openedB.didOpen) {
        application.close()
        return false
    }
    if (let Some(identifierA) <- openedA.identifier) {
        if (let Some(identifierB) <- openedB.identifier) {
            let enqueuedThrow = editApplicationWindow(application, identifierA, "throw-once")
            var propagated = false
            try {
                let _ = application.pumpOneTurn(turnBudgetMs: 2u32)
            } catch (_: Exception) {
                propagated = true
            }
            let enqueuedSibling = editApplicationWindow(application, identifierB, "sibling-after-throw")
            let recoveryTurn = application.pumpOneTurn(turnBudgetMs: 2u32)
            let recovered = enqueuedThrow && propagated && enqueuedSibling && recoveryTurn.isOpen &&
                recoveryTurn.windowCount == 2 && controllerB.observedInputCount() == 1 && applicationHasLiveWindow(application, identifierA) &&
                applicationHasLiveWindow(application, identifierB)
            application.close()
            let reclaimed = internalRendererOccupiedSessionCount() == 0u32
            if (recovered && reclaimed) {
                println("CJGUI_MULTI_WINDOW_EXCEPTION_GUARD callback_exception_propagated=true guard_released=true sibling_turn_served=true reclaimed=true")
            }
            return recovered && reclaimed
        }
    }
    application.close()
    return false
}

/// Two applications intentionally allocate their first window at the same
/// logical position. Their public scalar identifiers must still be foreign to
/// each other; closing/rebuilding A cannot make its stale id address B or C.
private func runMultiWindowIdentityProbe(): Bool {
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI identity", 360u32, 220u32)
    let applicationA = CjguiMacosApplication(maximumWindowCount: 1)
    let applicationB = CjguiMacosApplication(maximumWindowCount: 1)
    let openedA = applicationA.openWindow(ReentrantPassiveController("identity-A"), configuration: configuration)
    let controllerB = ExceptionRecoveryController()
    let openedB = applicationB.openWindow(controllerB, configuration: configuration)
    if (!openedA.didOpen || !openedB.didOpen) {
        applicationA.close()
        applicationB.close()
        return false
    }
    if (let Some(identifierA) <- openedA.identifier) {
        if (let Some(identifierB) <- openedB.identifier) {
            let foreignRejected = identifierA.applicationIdentifier != identifierB.applicationIdentifier &&
                !applicationHasLiveWindow(applicationB, identifierA) && !applicationB.requestClose(identifierA) &&
                applicationHasLiveWindow(applicationB, identifierB)
            applicationA.close()
            let bInputAfterAExit = editApplicationWindow(applicationB, identifierB, "B survives A exit")
            let bTurnAfterAExit = applicationB.pumpOneTurn(turnBudgetMs: 2u32)
            let bSurvivedAExit = applicationHasLiveWindow(applicationB, identifierB) && bInputAfterAExit &&
                bTurnAfterAExit.isOpen && bTurnAfterAExit.windowCount == 1 && controllerB.observedInputCount() == 1
            applicationB.close()
            let applicationC = CjguiMacosApplication(maximumWindowCount: 1)
            let openedC = applicationC.openWindow(ReentrantPassiveController("identity-C"), configuration: configuration)
            if (let Some(identifierC) <- openedC.identifier) {
                let rebuiltRejected = identifierC.applicationIdentifier != identifierA.applicationIdentifier &&
                    identifierC.value != identifierA.value && !applicationHasLiveWindow(applicationC, identifierA) &&
                    !applicationC.requestClose(identifierA) && applicationHasLiveWindow(applicationC, identifierC)
                applicationC.close()
                let reclaimed = internalRendererOccupiedSessionCount() == 0u32
                if (foreignRejected && bSurvivedAExit && rebuiltRejected && reclaimed) {
                    println("CJGUI_MULTI_WINDOW_IDENTITY cross_application_rejected=true stale_rebuild_rejected=true sibling_application_turn_survived=true reclaimed=true")
                }
                return foreignRejected && bSurvivedAExit && rebuiltRejected && reclaimed
            }
            applicationC.close()
        }
    }
    applicationA.close()
    applicationB.close()
    return false
}

/// Exhaust the real four-session renderer capacity in A, then ask B to open
/// one window. `CjguiComposableUiWindow.start` must clean its failed native
/// creation completely: B owns no partial window or application reference,
/// A remains intact, and B can open normally after A releases the capacity.
private func runMultiWindowPartialCreationProbe(): Bool {
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI partial creation", 360u32, 220u32)
    let applicationA = CjguiMacosApplication(maximumWindowCount: 4)
    let applicationB = CjguiMacosApplication(maximumWindowCount: 1)
    var openedCount: Int64 = 0
    while (openedCount < 4) {
        let opened = applicationA.openWindow(ReentrantPassiveController("capacity-A-${openedCount}"),
            configuration: configuration)
        if (!opened.didOpen) {
            applicationA.close()
            applicationB.close()
            return false
        }
        openedCount += 1
    }
    let blockedB = applicationB.openWindow(ReentrantPassiveController("capacity-B-blocked"), configuration: configuration)
    let cleanFailure = !blockedB.didOpen && blockedB.reason == "native_start_failed" &&
        applicationA.windowIdentifiers().size == 4 && applicationB.windowIdentifiers().size == 0 &&
        applicationA.isOpen() && !applicationB.isOpen() && internalRendererOccupiedSessionCount() == 4u32
    applicationA.close()
    let reopenedB = applicationB.openWindow(ReentrantPassiveController("capacity-B-reopened"), configuration: configuration)
    let recovered = reopenedB.didOpen && applicationB.windowIdentifiers().size == 1 &&
        internalRendererOccupiedSessionCount() == 1u32
    applicationB.close()
    let reclaimed = internalRendererOccupiedSessionCount() == 0u32
    if (cleanFailure && recovered && reclaimed) {
        println("CJGUI_MULTI_WINDOW_PARTIAL_CREATION native_start_failed=true failed_owner_empty=true sibling_preserved=true reopen_after_capacity_release=true reclaimed=true")
    }
    return cleanFailure && recovered && reclaimed
}

private func applicationBuildPassCount(application: CjguiMacosApplication,
    identifier: CjguiMacosApplicationWindowIdentifier): Int64 {
    if (let Some(window) <- application.window(identifier)) {
        return window.windowProjection().buildPassCount
    }
    return -1
}

private func applicationSubmissionCount(application: CjguiMacosApplication,
    identifier: CjguiMacosApplicationWindowIdentifier): Int64 {
    if (let Some(window) <- application.window(identifier)) {
        return window.windowProjection().nativeSubmissionCount
    }
    return -1
}

private func editApplicationWindow(application: CjguiMacosApplication,
    identifier: CjguiMacosApplicationWindowIdentifier, value: String): Bool {
    if (let Some(window) <- application.window(identifier)) {
        return editWithAppKit(window, value)
    }
    return false
}

// A fixed-binary 30-sample condition. Each sample admits exactly one owner
// mutation (alternating a normal AppKit human edit and a version-checked
// external write), then records the one application turn that reaches the
// affected scenes. At 2/4 windows A and B share the owner; C/D are unrelated
// owners and must retain their build/submission counts for that turn.
private func exerciseMultiWindowFairnessCondition(windowCount: Int64): Bool {
    let shared = CjguiTextDocument(8201, "公平性共享", "initial")
    let unrelatedC = CjguiTextDocument(8202, "公平性独立 C", "other-c")
    let unrelatedD = CjguiTextDocument(8203, "公平性独立 D", "other-d")
    let controllerA = MultiWindowDocumentController(shared, "fair-A")
    let controllerB = MultiWindowDocumentController(shared, "fair-B")
    let controllerC = MultiWindowDocumentController(unrelatedC, "fair-C")
    let controllerD = MultiWindowDocumentController(unrelatedD, "fair-D")
    let configuration = CjguiMacosApplicationWindowConfiguration("CJGUI fairness ${windowCount}", 420u32, 260u32)
    let application = CjguiMacosApplication(maximumWindowCount: 4)
    let openedA = application.openWindow(controllerA, configuration: configuration)
    if (!openedA.didOpen) {
        application.close()
        return false
    }
    if (windowCount >= 2 && !application.openWindow(controllerB, configuration: configuration).didOpen) {
        application.close()
        return false
    }
    if (windowCount >= 3 && !application.openWindow(controllerC, configuration: configuration).didOpen) {
        application.close()
        return false
    }
    if (windowCount >= 4 && !application.openWindow(controllerD, configuration: configuration).didOpen) {
        application.close()
        return false
    }
    let identifiers = application.windowIdentifiers()
    if (identifiers.size != windowCount || internalRendererOccupiedSessionCount() != UInt32(windowCount)) {
        application.close()
        return false
    }
    let identifierA = identifiers[0]
    let identifierB = if (windowCount >= 2) { identifiers[1] } else { identifierA }
    let identifierC = if (windowCount >= 3) { identifiers[2] } else { identifierA }
    let identifierD = if (windowCount >= 4) { identifiers[3] } else { identifierA }
    var waitedA: Int64 = 0
    var waitedB: Int64 = 0
    var waitedC: Int64 = 0
    var waitedD: Int64 = 0
    var sample: Int64 = 0
    var passed = true
    while (sample < 30) {
        let beforeABuild = applicationBuildPassCount(application, identifierA)
        let beforeASubmit = applicationSubmissionCount(application, identifierA)
        let beforeBBuild = applicationBuildPassCount(application, identifierB)
        let beforeBSubmit = applicationSubmissionCount(application, identifierB)
        let beforeCBuild = applicationBuildPassCount(application, identifierC)
        let beforeCSubmit = applicationSubmissionCount(application, identifierC)
        let beforeDBuild = applicationBuildPassCount(application, identifierD)
        let beforeDSubmit = applicationSubmissionCount(application, identifierD)
        let action = if (sample % 2 == 0) { "appkit_human" } else { "external_cas" }
        let admitted = if (sample % 2 == 0) {
            editApplicationWindow(application, identifierA, "fairness-${windowCount}-${sample}")
        } else {
            controllerA.appendFromExternal("-external-${sample}")
        }
        let started = MonoTime.now()
        let turn = application.pumpOneTurn(turnBudgetMs: 8u32)
        let turnMs = (MonoTime.now() - started).toMilliseconds()
        let afterABuild = applicationBuildPassCount(application, identifierA)
        let afterASubmit = applicationSubmissionCount(application, identifierA)
        let afterBBuild = applicationBuildPassCount(application, identifierB)
        let afterBSubmit = applicationSubmissionCount(application, identifierB)
        let afterCBuild = applicationBuildPassCount(application, identifierC)
        let afterCSubmit = applicationSubmissionCount(application, identifierC)
        let afterDBuild = applicationBuildPassCount(application, identifierD)
        let afterDSubmit = applicationSubmissionCount(application, identifierD)
        let aBuildDelta = afterABuild - beforeABuild
        let aSubmitDelta = afterASubmit - beforeASubmit
        let bBuildDelta = if (windowCount >= 2) { afterBBuild - beforeBBuild } else { 0 }
        let bSubmitDelta = if (windowCount >= 2) { afterBSubmit - beforeBSubmit } else { 0 }
        let cBuildDelta = if (windowCount >= 3) { afterCBuild - beforeCBuild } else { 0 }
        let cSubmitDelta = if (windowCount >= 3) { afterCSubmit - beforeCSubmit } else { 0 }
        let dBuildDelta = if (windowCount >= 4) { afterDBuild - beforeDBuild } else { 0 }
        let dSubmitDelta = if (windowCount >= 4) { afterDSubmit - beforeDSubmit } else { 0 }
        if (waitedForIdentifier(turn, identifierA)) {
            waitedA += 1
        } else if (windowCount >= 2 && waitedForIdentifier(turn, identifierB)) {
            waitedB += 1
        } else if (windowCount >= 3 && waitedForIdentifier(turn, identifierC)) {
            waitedC += 1
        } else if (windowCount >= 4 && waitedForIdentifier(turn, identifierD)) {
            waitedD += 1
        } else {
            passed = false
        }
        let relatedUpdated = aBuildDelta == 1 && aSubmitDelta == 1 &&
            (windowCount < 2 || (bBuildDelta == 1 && bSubmitDelta == 1))
        let unrelatedIdle = (windowCount < 3 || (cBuildDelta == 0 && cSubmitDelta == 0)) &&
            (windowCount < 4 || (dBuildDelta == 0 && dSubmitDelta == 0))
        let valid = admitted && turn.isOpen && turn.windowCount == windowCount && turn.eventWaitBudgetMs <= 8u32 &&
            relatedUpdated && unrelatedIdle
        println("CJGUI_MULTI_WINDOW_FAIRNESS windows=${windowCount} sample=${sample} total_work_items=1 action=${action} turn_ms=${turnMs} event_wait_budget_ms=${turn.eventWaitBudgetMs} related_build_delta=${aBuildDelta},${bBuildDelta} related_submit_delta=${aSubmitDelta},${bSubmitDelta} unrelated_build_delta=${cBuildDelta},${dBuildDelta} unrelated_submit_delta=${cSubmitDelta},${dSubmitDelta} valid=${valid}")
        passed = passed && valid
        sample += 1
    }
    let fairRotation = if (windowCount == 1) {
        waitedA == 30
    } else if (windowCount == 2) {
        waitedA == 15 && waitedB == 15
    } else {
        waitedA == 8 && waitedB == 8 && waitedC == 7 && waitedD == 7
    }
    application.close()
    let reclaimed = internalRendererOccupiedSessionCount() == 0u32
    println("CJGUI_MULTI_WINDOW_FAIRNESS_SUMMARY windows=${windowCount} samples=30 waited=${waitedA},${waitedB},${waitedC},${waitedD} fair_rotation=${fairRotation} reclaimed=${reclaimed}")
    return passed && fairRotation && reclaimed
}

private func runMultiWindowFairnessProbe(): Bool {
    return exerciseMultiWindowFairnessCondition(1) && exerciseMultiWindowFairnessCondition(2) &&
        exerciseMultiWindowFairnessCondition(4)
}

private func editWithAppKit(window: CjguiComposableUiWindow, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_edit_composable_text(window.testSessionToken(), 1u32, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func nativeTextMatches(window: CjguiComposableUiWindow, expected: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(expected) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_composable_text_matches(window.testSessionToken(), textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

// A real owner acknowledgement may reposition the hidden NSTextView, but it
// must not flatten the active document's per-character fallback fonts.  Keep
// this scalar-only assertion beside the real AppKit text helper; the public
// UI still owns no native TextKit object.
private func activeMultilineFallbackRunsMatch(window: CjguiComposableUiWindow): Bool {
    var expectedFallbackRuns: UInt32 = 0u32
    var mismatchedRuns: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_composable_multiline_fallback_runs(
            window.testSessionToken(), inout expectedFallbackRuns, inout mismatchedRuns
        )
    }
    let valid = status == CJGUI_INTERNAL_RENDERER_OK && expectedFallbackRuns > 0u32 && mismatchedRuns == 0u32
    if (!valid) {
        println("CJGUI_MULTILINE_FALLBACK_RUNS status=${status} expected_fallback_runs=${expectedFallbackRuns} mismatched_runs=${mismatchedRuns}")
    }
    return valid
}

// Reproduce the normal-window regression with a script that requires an
// actual CJK fallback run: external truth establishes the document, AppKit
// focuses its multiline adapter, and a local ASCII insert is acknowledged by
// the Cangjie owner.  The subsequent scalar check catches a global font write
// that would otherwise flatten the earlier Chinese/emoji runs.
private func exerciseActiveMultilineFallbackAcknowledgement(
    window: CjguiComposableUiWindow, controller: AppKitTextController): Bool {
    let baseline = "第一行：把实际输入交给仓颉文档。\n第二行：emoji 🙂 不会被拆开。"
    if (!controller.replaceDraftFromExternal(baseline) || !window.refresh()) { return false }
    if (!selectRange(window, 1u32, 1000000u32, 1000000u32) || window.pump(0u32).didApplyHumanAction) { return false }
    if (!insertAtCurrentSelectionWithAppKit(window, "Z")) { return false }
    let acknowledgement = window.pump(0u32)
    if (!acknowledgement.didApplyHumanAction || !activeMultilineFallbackRunsMatch(window)) { return false }
    // Emptying the active field must still take the normal global-base-font
    // path.  Re-establishing CJK/emoji afterwards must rebuild its fallback
    // runs rather than treating the empty-field assignment as a same-style
    // no-op.  This covers the guarded setter's empty-storage boundary.
    if (!selectRange(window, 1u32, 0u32, 1000000u32) || window.pump(0u32).didApplyHumanAction ||
        !deleteAtCurrentSelectionWithAppKit(window)) { return false }
    let cleared = window.pump(0u32)
    if (!cleared.didApplyHumanAction || !controller.hasDraft("") || !nativeTextMatches(window, "")) { return false }
    if (!controller.replaceDraftFromExternal(baseline) || !window.refresh() ||
        !selectRange(window, 1u32, 1000000u32, 1000000u32) || window.pump(0u32).didApplyHumanAction ||
        !insertAtCurrentSelectionWithAppKit(window, "Y")) { return false }
    let restoredAcknowledgement = window.pump(0u32)
    return restoredAcknowledgement.didApplyHumanAction && activeMultilineFallbackRunsMatch(window)
}

private func insertAtCurrentSelectionWithAppKit(window: CjguiComposableUiWindow, text: String): Bool {
    return insertAtNodeWithAppKit(window, 1u32, text)
}

private func insertAtNodeWithAppKit(window: CjguiComposableUiWindow, nodeIndex: UInt32, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_insert_composable_text(window.testSessionToken(), nodeIndex, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func deleteAtCurrentSelectionWithAppKit(window: CjguiComposableUiWindow): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_delete_composable_text(window.testSessionToken(), 1u32)
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private class AppKitInputTiming {
    let status: Int32
    let mutationMicros: UInt64
    let textDelegateMicros: UInt64
    let selectionDelegateMicros: UInt64
    let eventEnqueueMicros: UInt64
    let accessibilityMicros: UInt64

    init(status: Int32, mutationMicros: UInt64, textDelegateMicros: UInt64,
        selectionDelegateMicros: UInt64, eventEnqueueMicros: UInt64, accessibilityMicros: UInt64) {
        this.status = status
        this.mutationMicros = mutationMicros
        this.textDelegateMicros = textDelegateMicros
        this.selectionDelegateMicros = selectionDelegateMicros
        this.eventEnqueueMicros = eventEnqueueMicros
        this.accessibilityMicros = accessibilityMicros
    }
}

private class AppKitInputCallbackTrace {
    let status: Int32
    let superInsertMicros: UInt64
    let modeChangeCount: UInt64
    let modeChangeMicros: UInt64
    let textCallbackCount: UInt64
    let textCallbackMicros: UInt64
    let selectionCallbackCount: UInt64
    let pendingEditSelectionCount: UInt64
    let selectionCallbackMicros: UInt64
    let selectionRevealMicros: UInt64
    let selectionQueueMicros: UInt64
    let selectionAccessibilityMicros: UInt64
    let refreshMicros: UInt64
    let preparationMicros: UInt64
    let wholeAttributeWriteCount: UInt64
    let wholeAttributeCharacters: UInt64
    let fallbackApplyCount: UInt64
    let fallbackCharacters: UInt64
    let fallbackMicros: UInt64

    init(status: Int32, superInsertMicros: UInt64, modeChangeCount: UInt64, modeChangeMicros: UInt64,
        textCallbackCount: UInt64, textCallbackMicros: UInt64, selectionCallbackCount: UInt64,
        pendingEditSelectionCount: UInt64, selectionCallbackMicros: UInt64, selectionRevealMicros: UInt64,
        selectionQueueMicros: UInt64, selectionAccessibilityMicros: UInt64, refreshMicros: UInt64,
        preparationMicros: UInt64, wholeAttributeWriteCount: UInt64, wholeAttributeCharacters: UInt64,
        fallbackApplyCount: UInt64, fallbackCharacters: UInt64, fallbackMicros: UInt64) {
        this.status = status
        this.superInsertMicros = superInsertMicros
        this.modeChangeCount = modeChangeCount
        this.modeChangeMicros = modeChangeMicros
        this.textCallbackCount = textCallbackCount
        this.textCallbackMicros = textCallbackMicros
        this.selectionCallbackCount = selectionCallbackCount
        this.pendingEditSelectionCount = pendingEditSelectionCount
        this.selectionCallbackMicros = selectionCallbackMicros
        this.selectionRevealMicros = selectionRevealMicros
        this.selectionQueueMicros = selectionQueueMicros
        this.selectionAccessibilityMicros = selectionAccessibilityMicros
        this.refreshMicros = refreshMicros
        this.preparationMicros = preparationMicros
        this.wholeAttributeWriteCount = wholeAttributeWriteCount
        this.wholeAttributeCharacters = wholeAttributeCharacters
        this.fallbackApplyCount = fallbackApplyCount
        this.fallbackCharacters = fallbackCharacters
        this.fallbackMicros = fallbackMicros
    }
}

private class AppKitTextWorkStats {
    let status: Int32
    let rasterCount: UInt64
    let rasterBytes: UInt64
    let rasterMicros: UInt64
    let uploadCount: UInt64
    let uploadBytes: UInt64
    let uploadMicros: UInt64

    init(status: Int32, rasterCount: UInt64, rasterBytes: UInt64, rasterMicros: UInt64,
        uploadCount: UInt64, uploadBytes: UInt64, uploadMicros: UInt64) {
        this.status = status
        this.rasterCount = rasterCount
        this.rasterBytes = rasterBytes
        this.rasterMicros = rasterMicros
        this.uploadCount = uploadCount
        this.uploadBytes = uploadBytes
        this.uploadMicros = uploadMicros
    }
}

// Latest-frame, scalar command-encoding facts. These intentionally remain
// separate from raster/upload counters and from GPU completion: they compare
// the same human-input scene after its accepted submission, not a synthetic
// sum of nested intervals.
private class AppKitEncoderStats {
    let status: Int32
    let shapeNodes: UInt32
    let shapeBatches: UInt32
    let textureDraws: UInt32
    let shapeVertexBytes: UInt64
    let vertexStride: UInt32
    let maxShapeBatchVertexBytes: UInt64
    let cpuEncodeMicros: UInt64

    init(status: Int32, shapeNodes: UInt32, shapeBatches: UInt32, textureDraws: UInt32,
        shapeVertexBytes: UInt64, vertexStride: UInt32, maxShapeBatchVertexBytes: UInt64,
        cpuEncodeMicros: UInt64) {
        this.status = status
        this.shapeNodes = shapeNodes
        this.shapeBatches = shapeBatches
        this.textureDraws = textureDraws
        this.shapeVertexBytes = shapeVertexBytes
        this.vertexStride = vertexStride
        this.maxShapeBatchVertexBytes = maxShapeBatchVertexBytes
        this.cpuEncodeMicros = cpuEncodeMicros
    }
}

private class AppKitActiveTextPreparationState {
    let status: Int32
    let scheduled: UInt8
    let failed: UInt8
    let retryCount: UInt32
    let remainingFailures: UInt32

    init(status: Int32, scheduled: UInt8, failed: UInt8, retryCount: UInt32, remainingFailures: UInt32) {
        this.status = status
        this.scheduled = scheduled
        this.failed = failed
        this.retryCount = retryCount
        this.remainingFailures = remainingFailures
    }
}

private class AppKitActiveLayoutWork {
    let status: Int32
    let rangeLayoutCount: UInt64
    let fullLayoutCount: UInt64

    init(status: Int32, rangeLayoutCount: UInt64, fullLayoutCount: UInt64) {
        this.status = status
        this.rangeLayoutCount = rangeLayoutCount
        this.fullLayoutCount = fullLayoutCount
    }
}

private class AppKitActiveLayoutTrace {
    let status: Int32
    let characterEnsureCount: UInt64
    let characterEnsureMicros: UInt64
    let boundingEnsureCount: UInt64
    let boundingEnsureMicros: UInt64
    let glyphIndexCount: UInt64
    let glyphIndexMicros: UInt64
    let lineFragmentCount: UInt64
    let lineFragmentMicros: UInt64
    let glyphLocationCount: UInt64
    let glyphLocationMicros: UInt64
    let positionProxyMicros: UInt64
    let positionNoopWrites: UInt64
    let positionChangedWrites: UInt64
    let firstUnlaidBefore: UInt64
    let firstUnlaidAfter: UInt64
    let invalidatedLocation: UInt64
    let invalidatedLength: UInt64
    let revealMicros: UInt64
    let candidateMicros: UInt64
    let positionFirstUnlaidBefore: UInt64
    let positionFirstUnlaidAfter: UInt64
    let positionChangedMask: UInt64

    init(status: Int32, characterEnsureCount: UInt64, characterEnsureMicros: UInt64,
        boundingEnsureCount: UInt64, boundingEnsureMicros: UInt64, glyphIndexCount: UInt64,
        glyphIndexMicros: UInt64, lineFragmentCount: UInt64, lineFragmentMicros: UInt64,
        glyphLocationCount: UInt64, glyphLocationMicros: UInt64, positionProxyMicros: UInt64,
        positionNoopWrites: UInt64, positionChangedWrites: UInt64, firstUnlaidBefore: UInt64,
        firstUnlaidAfter: UInt64, invalidatedLocation: UInt64, invalidatedLength: UInt64,
        revealMicros: UInt64, candidateMicros: UInt64, positionFirstUnlaidBefore: UInt64,
        positionFirstUnlaidAfter: UInt64, positionChangedMask: UInt64) {
        this.status = status
        this.characterEnsureCount = characterEnsureCount
        this.characterEnsureMicros = characterEnsureMicros
        this.boundingEnsureCount = boundingEnsureCount
        this.boundingEnsureMicros = boundingEnsureMicros
        this.glyphIndexCount = glyphIndexCount
        this.glyphIndexMicros = glyphIndexMicros
        this.lineFragmentCount = lineFragmentCount
        this.lineFragmentMicros = lineFragmentMicros
        this.glyphLocationCount = glyphLocationCount
        this.glyphLocationMicros = glyphLocationMicros
        this.positionProxyMicros = positionProxyMicros
        this.positionNoopWrites = positionNoopWrites
        this.positionChangedWrites = positionChangedWrites
        this.firstUnlaidBefore = firstUnlaidBefore
        this.firstUnlaidAfter = firstUnlaidAfter
        this.invalidatedLocation = invalidatedLocation
        this.invalidatedLength = invalidatedLength
        this.revealMicros = revealMicros
        this.candidateMicros = candidateMicros
        this.positionFirstUnlaidBefore = positionFirstUnlaidBefore
        this.positionFirstUnlaidAfter = positionFirstUnlaidAfter
        this.positionChangedMask = positionChangedMask
    }
}

private func inputTiming(window: CjguiComposableUiWindow): AppKitInputTiming {
    var mutationMicros: UInt64 = 0u64
    var textDelegateMicros: UInt64 = 0u64
    var selectionDelegateMicros: UInt64 = 0u64
    var eventEnqueueMicros: UInt64 = 0u64
    var accessibilityMicros: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_input_timing(
            window.testSessionToken(), inout mutationMicros, inout textDelegateMicros,
            inout selectionDelegateMicros, inout eventEnqueueMicros, inout accessibilityMicros
        )
    }
    return AppKitInputTiming(status, mutationMicros, textDelegateMicros, selectionDelegateMicros,
        eventEnqueueMicros, accessibilityMicros)
}

private func setBoundedInputLayout(window: CjguiComposableUiWindow, enabled: Bool): Bool {
    let raw: UInt8 = if (enabled) { 1u8 } else { 0u8 }
    return unsafe {
        cjgui_internal_renderer_test_set_composable_bounded_input_layout(window.testSessionToken(), raw)
    } == CJGUI_INTERNAL_RENDERER_OK
}

private func resetInputCallbackTrace(window: CjguiComposableUiWindow): Bool {
    return unsafe {
        cjgui_internal_renderer_test_reset_composable_input_callback_trace(window.testSessionToken())
    } == CJGUI_INTERNAL_RENDERER_OK
}

private func inputCallbackTrace(window: CjguiComposableUiWindow): AppKitInputCallbackTrace {
    var superInsertMicros: UInt64 = 0u64
    var modeChangeCount: UInt64 = 0u64
    var modeChangeMicros: UInt64 = 0u64
    var textCallbackCount: UInt64 = 0u64
    var textCallbackMicros: UInt64 = 0u64
    var selectionCallbackCount: UInt64 = 0u64
    var pendingEditSelectionCount: UInt64 = 0u64
    var selectionCallbackMicros: UInt64 = 0u64
    var selectionRevealMicros: UInt64 = 0u64
    var selectionQueueMicros: UInt64 = 0u64
    var selectionAccessibilityMicros: UInt64 = 0u64
    var refreshMicros: UInt64 = 0u64
    var preparationMicros: UInt64 = 0u64
    var wholeAttributeWriteCount: UInt64 = 0u64
    var wholeAttributeCharacters: UInt64 = 0u64
    var fallbackApplyCount: UInt64 = 0u64
    var fallbackCharacters: UInt64 = 0u64
    var fallbackMicros: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_input_callback_trace(
            window.testSessionToken(), inout superInsertMicros, inout modeChangeCount, inout modeChangeMicros,
            inout textCallbackCount, inout textCallbackMicros, inout selectionCallbackCount,
            inout pendingEditSelectionCount, inout selectionCallbackMicros, inout selectionRevealMicros,
            inout selectionQueueMicros, inout selectionAccessibilityMicros, inout refreshMicros,
            inout preparationMicros, inout wholeAttributeWriteCount, inout wholeAttributeCharacters,
            inout fallbackApplyCount, inout fallbackCharacters, inout fallbackMicros
        )
    }
    return AppKitInputCallbackTrace(status, superInsertMicros, modeChangeCount, modeChangeMicros,
        textCallbackCount, textCallbackMicros, selectionCallbackCount, pendingEditSelectionCount,
        selectionCallbackMicros, selectionRevealMicros, selectionQueueMicros, selectionAccessibilityMicros,
        refreshMicros, preparationMicros, wholeAttributeWriteCount, wholeAttributeCharacters,
        fallbackApplyCount, fallbackCharacters, fallbackMicros)
}

private func textWorkStats(window: CjguiComposableUiWindow): AppKitTextWorkStats {
    var rasterCount: UInt64 = 0u64
    var rasterBytes: UInt64 = 0u64
    var rasterMicros: UInt64 = 0u64
    var uploadCount: UInt64 = 0u64
    var uploadBytes: UInt64 = 0u64
    var uploadMicros: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_text_work_stats(
            window.testSessionToken(), inout rasterCount, inout rasterBytes, inout rasterMicros,
            inout uploadCount, inout uploadBytes, inout uploadMicros
        )
    }
    return AppKitTextWorkStats(status, rasterCount, rasterBytes, rasterMicros,
        uploadCount, uploadBytes, uploadMicros)
}

// TDD RED assertion: the baseline must expose a bounded reason dimension,
// not just an aggregate raster/upload count.
private func textWorkReasonStatsAvailable(window: CjguiComposableUiWindow): Bool {
    var unknownRaster: UInt64 = 0u64
    var staticCandidateRaster: UInt64 = 0u64
    var activeContentRaster: UInt64 = 0u64
    var selectionCaretRaster: UInt64 = 0u64
    var visibleTileScrollRaster: UInt64 = 0u64
    var retryRaster: UInt64 = 0u64
    var projectionGeometryRaster: UInt64 = 0u64
    var externalProjectionContentRaster: UInt64 = 0u64
    var unknownUpload: UInt64 = 0u64
    var staticCandidateUpload: UInt64 = 0u64
    var activeContentUpload: UInt64 = 0u64
    var selectionCaretUpload: UInt64 = 0u64
    var visibleTileScrollUpload: UInt64 = 0u64
    var retryUpload: UInt64 = 0u64
    var projectionGeometryUpload: UInt64 = 0u64
    var externalProjectionContentUpload: UInt64 = 0u64
    var lastProjectionVersion: UInt64 = 0u64
    var lastContentUtf8Bytes: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_text_work_reason_stats(
            window.testSessionToken(),
            inout unknownRaster, inout staticCandidateRaster, inout activeContentRaster,
            inout selectionCaretRaster, inout visibleTileScrollRaster, inout retryRaster,
            inout projectionGeometryRaster, inout externalProjectionContentRaster,
            inout unknownUpload, inout staticCandidateUpload, inout activeContentUpload,
            inout selectionCaretUpload, inout visibleTileScrollUpload, inout retryUpload,
            inout projectionGeometryUpload, inout externalProjectionContentUpload,
            inout lastProjectionVersion, inout lastContentUtf8Bytes
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func printTextWorkReasonSummary(window: CjguiComposableUiWindow, workload: String,
    nodes: Int64, ownerVersion: Int64, ownerContentUtf8Bytes: Int64): Bool {
    var unknownRaster: UInt64 = 0u64
    var staticCandidateRaster: UInt64 = 0u64
    var activeContentRaster: UInt64 = 0u64
    var selectionCaretRaster: UInt64 = 0u64
    var visibleTileScrollRaster: UInt64 = 0u64
    var retryRaster: UInt64 = 0u64
    var projectionGeometryRaster: UInt64 = 0u64
    var externalProjectionContentRaster: UInt64 = 0u64
    var unknownUpload: UInt64 = 0u64
    var staticCandidateUpload: UInt64 = 0u64
    var activeContentUpload: UInt64 = 0u64
    var selectionCaretUpload: UInt64 = 0u64
    var visibleTileScrollUpload: UInt64 = 0u64
    var retryUpload: UInt64 = 0u64
    var projectionGeometryUpload: UInt64 = 0u64
    var externalProjectionContentUpload: UInt64 = 0u64
    var lastProjectionVersion: UInt64 = 0u64
    var lastContentUtf8Bytes: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_text_work_reason_stats(
            window.testSessionToken(),
            inout unknownRaster, inout staticCandidateRaster, inout activeContentRaster,
            inout selectionCaretRaster, inout visibleTileScrollRaster, inout retryRaster,
            inout projectionGeometryRaster, inout externalProjectionContentRaster,
            inout unknownUpload, inout staticCandidateUpload, inout activeContentUpload,
            inout selectionCaretUpload, inout visibleTileScrollUpload, inout retryUpload,
            inout projectionGeometryUpload, inout externalProjectionContentUpload,
            inout lastProjectionVersion, inout lastContentUtf8Bytes
        )
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) { return false }
    let aggregate = textWorkStats(window)
    let reasonRaster = unknownRaster + staticCandidateRaster + activeContentRaster + selectionCaretRaster + visibleTileScrollRaster + retryRaster + projectionGeometryRaster + externalProjectionContentRaster
    let reasonUpload = unknownUpload + staticCandidateUpload + activeContentUpload + selectionCaretUpload + visibleTileScrollUpload + retryUpload + projectionGeometryUpload + externalProjectionContentUpload
    println("CJGUI_TEXT_WORK_REASON_SUMMARY workload=${workload} nodes=${nodes} owner_version=${ownerVersion} owner_content_utf8_bytes=${ownerContentUtf8Bytes} reason_last_projection_version=${lastProjectionVersion} reason_last_content_utf8_bytes=${lastContentUtf8Bytes} unknown_raster=${unknownRaster} static_candidate_raster=${staticCandidateRaster} active_content_raster=${activeContentRaster} selection_caret_raster=${selectionCaretRaster} visible_tile_scroll_raster=${visibleTileScrollRaster} retry_raster=${retryRaster} projection_geometry_raster=${projectionGeometryRaster} external_projection_content_raster=${externalProjectionContentRaster} unknown_upload=${unknownUpload} static_candidate_upload=${staticCandidateUpload} active_content_upload=${activeContentUpload} selection_caret_upload=${selectionCaretUpload} visible_tile_scroll_upload=${visibleTileScrollUpload} retry_upload=${retryUpload} projection_geometry_upload=${projectionGeometryUpload} external_projection_content_upload=${externalProjectionContentUpload}")
    return reasonRaster == aggregate.rasterCount && reasonUpload == aggregate.uploadCount &&
        unknownRaster == 0u64 && unknownUpload == 0u64
}

private func encoderStats(window: CjguiComposableUiWindow): AppKitEncoderStats {
    var shapeNodes: UInt32 = 0u32
    var shapeBatches: UInt32 = 0u32
    var textureDraws: UInt32 = 0u32
    var shapeVertexBytes: UInt64 = 0u64
    var vertexStride: UInt32 = 0u32
    var maxShapeBatchVertexBytes: UInt64 = 0u64
    var cpuEncodeMicros: UInt64 = 0u64
    let session = window.testSessionToken()
    var status = unsafe {
        cjgui_internal_renderer_test_composable_encoder_stats(
            session, inout shapeNodes, inout shapeBatches, inout textureDraws, inout shapeVertexBytes
        )
    }
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        status = unsafe {
            cjgui_internal_renderer_test_composable_encoder_batch_stats(
                session, inout vertexStride, inout maxShapeBatchVertexBytes
            )
        }
    }
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        status = unsafe { cjgui_internal_renderer_test_composable_encoder_cpu_stats(session, inout cpuEncodeMicros) }
    }
    return AppKitEncoderStats(status, shapeNodes, shapeBatches, textureDraws, shapeVertexBytes,
        vertexStride, maxShapeBatchVertexBytes, cpuEncodeMicros)
}

private func activeTextPreparationState(window: CjguiComposableUiWindow): AppKitActiveTextPreparationState {
    var scheduled: UInt8 = 0u8
    var failed: UInt8 = 0u8
    var retryCount: UInt32 = 0u32
    var remainingFailures: UInt32 = 0u32
    let session = window.testSessionToken()
    var status = unsafe {
        cjgui_internal_renderer_test_composable_active_text_resource_preparation_state(
            session, inout scheduled, inout failed, inout retryCount
        )
    }
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        status = unsafe {
            cjgui_internal_renderer_test_composable_text_preparation_failures_remaining(session, inout remainingFailures)
        }
    }
    return AppKitActiveTextPreparationState(status, scheduled, failed, retryCount, remainingFailures)
}

private func activeLayoutWork(window: CjguiComposableUiWindow): AppKitActiveLayoutWork {
    var rangeLayoutCount: UInt64 = 0u64
    var fullLayoutCount: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_active_layout_work_counts(
            window.testSessionToken(), inout rangeLayoutCount, inout fullLayoutCount
        )
    }
    return AppKitActiveLayoutWork(status, rangeLayoutCount, fullLayoutCount)
}

private func resetActiveLayoutTrace(window: CjguiComposableUiWindow): Bool {
    return unsafe {
        cjgui_internal_renderer_test_reset_composable_active_layout_trace(window.testSessionToken())
    } == CJGUI_INTERNAL_RENDERER_OK
}

private func activeLayoutTrace(window: CjguiComposableUiWindow): AppKitActiveLayoutTrace {
    var characterEnsureCount: UInt64 = 0u64
    var characterEnsureMicros: UInt64 = 0u64
    var boundingEnsureCount: UInt64 = 0u64
    var boundingEnsureMicros: UInt64 = 0u64
    var glyphIndexCount: UInt64 = 0u64
    var glyphIndexMicros: UInt64 = 0u64
    var lineFragmentCount: UInt64 = 0u64
    var lineFragmentMicros: UInt64 = 0u64
    var glyphLocationCount: UInt64 = 0u64
    var glyphLocationMicros: UInt64 = 0u64
    var positionProxyMicros: UInt64 = 0u64
    var positionNoopWrites: UInt64 = 0u64
    var positionChangedWrites: UInt64 = 0u64
    var firstUnlaidBefore: UInt64 = 0u64
    var firstUnlaidAfter: UInt64 = 0u64
    var invalidatedLocation: UInt64 = 0u64
    var invalidatedLength: UInt64 = 0u64
    var revealMicros: UInt64 = 0u64
    var candidateMicros: UInt64 = 0u64
    var positionFirstUnlaidBefore: UInt64 = 0u64
    var positionFirstUnlaidAfter: UInt64 = 0u64
    var positionChangedMask: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_active_layout_trace(
            window.testSessionToken(), inout characterEnsureCount, inout characterEnsureMicros,
            inout boundingEnsureCount, inout boundingEnsureMicros, inout glyphIndexCount,
            inout glyphIndexMicros, inout lineFragmentCount, inout lineFragmentMicros,
            inout glyphLocationCount, inout glyphLocationMicros, inout positionProxyMicros,
            inout positionNoopWrites, inout positionChangedWrites, inout firstUnlaidBefore,
            inout firstUnlaidAfter, inout invalidatedLocation, inout invalidatedLength,
            inout revealMicros, inout candidateMicros, inout positionFirstUnlaidBefore,
            inout positionFirstUnlaidAfter, inout positionChangedMask
        )
    }
    return AppKitActiveLayoutTrace(status, characterEnsureCount, characterEnsureMicros,
        boundingEnsureCount, boundingEnsureMicros, glyphIndexCount, glyphIndexMicros,
        lineFragmentCount, lineFragmentMicros, glyphLocationCount, glyphLocationMicros,
        positionProxyMicros, positionNoopWrites, positionChangedWrites, firstUnlaidBefore,
        firstUnlaidAfter, invalidatedLocation, invalidatedLength, revealMicros, candidateMicros,
        positionFirstUnlaidBefore, positionFirstUnlaidAfter, positionChangedMask)
}

private func nativeTextViewBaselineMicros(value: String, selectionLocation: UInt32): Int64 {
    let nativeText = unsafe { LibC.mallocCString(value) }
    var micros: UInt64 = 0u64
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_nstextview_insert_baseline(
                textResource.value, selectionLocation, 942.0f32, inout micros
            )
        }
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Int64(micros) } else { -1 }
}

private class AppKitNativeVisibleLayoutBaseline {
    let status: Int32
    let mutationMicros: UInt64
    let selectionLayoutMicros: UInt64

    init(status: Int32, mutationMicros: UInt64, selectionLayoutMicros: UInt64) {
        this.status = status
        this.mutationMicros = mutationMicros
        this.selectionLayoutMicros = selectionLayoutMicros
    }
}

private func nativeTextViewVisibleLayoutBaseline(value: String, selectionLocation: UInt32): AppKitNativeVisibleLayoutBaseline {
    let nativeText = unsafe { LibC.mallocCString(value) }
    var mutationMicros: UInt64 = 0u64
    var selectionLayoutMicros: UInt64 = 0u64
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_nstextview_insert_visible_layout_baseline(
                textResource.value, selectionLocation, 942.0f32, inout mutationMicros, inout selectionLayoutMicros
            )
        }
    }
    return AppKitNativeVisibleLayoutBaseline(status, mutationMicros, selectionLayoutMicros)
}

private func longUnicodeText(minimumUtf8Bytes: Int64, multipleParagraphs!: Bool = true): String {
    // The first 16-byte ASCII run makes UTF-16 position 2048 a known scalar
    // boundary; each following repeat includes CRLF, an emoji and a combining
    // sequence so the document is not an ASCII-only fast path.
    let fragment = if (multipleParagraphs) { "abcdefghijklmnop🙂e\u{301}\r\n" } else { "abcdefghijklmnop🙂e\u{301}" }
    let builder = StringBuilder()
    var bytes: Int64 = 0
    while (bytes < minimumUtf8Bytes) {
        builder.append(fragment)
        bytes += fragment.size
    }
    return builder.toString()
}

private func exerciseLongDocument(window: CjguiComposableUiWindow, controller: AppKitTextController,
    minimumUtf8Bytes: Int64, multipleParagraphs: Bool, emitsMetric: Bool): Bool {
    let source = longUnicodeText(minimumUtf8Bytes, multipleParagraphs: multipleParagraphs)
    if (!controller.replaceDraftFromExternal(source) || !window.refresh()) { return false }
    let before = window.windowProjection()
    let beforeEvents = controller.observedTextEvents()
    let beforeVersion = controller.documentVersion()
    let layoutWorkBefore = activeLayoutWork(window)
    if (layoutWorkBefore.status != CJGUI_INTERNAL_RENDERER_OK) { return false }
    var acknowledgementsBefore: UInt64 = 0u64
    let acknowledgementBeforeStatus = unsafe {
        cjgui_internal_renderer_test_composable_local_acknowledgement_count(window.testSessionToken(), inout acknowledgementsBefore)
    }
    if (acknowledgementBeforeStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }

    // Start, middle, and end use real native selection+insert events. The
    // final oversized UTF-16 position is clamped by NSTextView to its end.
    if (!selectRange(window, 1u32, 0u32, 0u32) || window.pump(0u32).didApplyHumanAction) { return false }
    let firstBaselineMicros = nativeTextViewBaselineMicros(source, 0u32)
    let started = MonoTime.now()
    if (!insertAtCurrentSelectionWithAppKit(window, "S")) { return false }
    let firstTiming = inputTiming(window)
    let afterFirstInput = MonoTime.now()
    if (!window.pump(0u32).didApplyHumanAction) { return false }
    let firstEditMs = (MonoTime.now() - started).toMilliseconds()
    let firstInputMs = (afterFirstInput - started).toMilliseconds()
    let firstPumpMs = (MonoTime.now() - afterFirstInput).toMilliseconds()
    let firstOwnerMs = controller.lastDocumentOwnerMs()
    if (!scrollWithinActiveMultilineViewport(window)) { return false }
    if (!selectRange(window, 1u32, 2048u32, 2048u32) || window.pump(0u32).didApplyHumanAction) { return false }
    let middleBaselineMicros = nativeTextViewBaselineMicros(source, 2048u32)
    let middleStarted = MonoTime.now()
    if (!insertAtCurrentSelectionWithAppKit(window, "M")) { return false }
    let middleTiming = inputTiming(window)
    let afterMiddleInput = MonoTime.now()
    if (!window.pump(0u32).didApplyHumanAction) { return false }
    let middleEditMs = (MonoTime.now() - middleStarted).toMilliseconds()
    let middleInputMs = (afterMiddleInput - middleStarted).toMilliseconds()
    let middlePumpMs = (MonoTime.now() - afterMiddleInput).toMilliseconds()
    let middleOwnerMs = controller.lastDocumentOwnerMs()
    if (!scrollWithinActiveMultilineViewport(window)) { return false }
    if (!selectRange(window, 1u32, 1000000u32, 1000000u32) || window.pump(0u32).didApplyHumanAction) { return false }
    let endBaselineMicros = nativeTextViewBaselineMicros(source, 1000000u32)
    let endStarted = MonoTime.now()
    if (!insertAtCurrentSelectionWithAppKit(window, "E")) { return false }
    let endTiming = inputTiming(window)
    let afterEndInput = MonoTime.now()
    if (!window.pump(0u32).didApplyHumanAction) { return false }
    let endEditMs = (MonoTime.now() - endStarted).toMilliseconds()
    let endInputMs = (afterEndInput - endStarted).toMilliseconds()
    let endPumpMs = (MonoTime.now() - afterEndInput).toMilliseconds()
    let endOwnerMs = controller.lastDocumentOwnerMs()
    // The selection callback has just revealed this remote caret; verify the
    // candidate rect while it is visible, then exercise the following small
    // wheel movement independently.
    if (!hasMappedCandidateRectAt(window, 1000000u32)) { return false }
    if (!scrollWithinActiveMultilineViewport(window)) { return false }

    let after = window.windowProjection()
    let layoutWorkAfter = activeLayoutWork(window)
    var acknowledgementsAfter: UInt64 = 0u64
    let acknowledgementAfterStatus = unsafe {
        cjgui_internal_renderer_test_composable_local_acknowledgement_count(window.testSessionToken(), inout acknowledgementsAfter)
    }
    let isCorrect = controller.observedTextEvents() == beforeEvents + 3 &&
        controller.documentContentSize() == source.size + 3 && controller.documentVersion() == beforeVersion + 3 &&
        after.buildPassCount >= before.buildPassCount + 3 && after.layoutPassCount >= before.layoutPassCount + 3 &&
        after.nativeSubmissionCount >= before.nativeSubmissionCount + 3 &&
        acknowledgementAfterStatus == CJGUI_INTERNAL_RENDERER_OK && acknowledgementsAfter >= acknowledgementsBefore + 3u64 &&
        layoutWorkAfter.status == CJGUI_INTERNAL_RENDERER_OK &&
        layoutWorkAfter.rangeLayoutCount > layoutWorkBefore.rangeLayoutCount &&
        layoutWorkAfter.fullLayoutCount == layoutWorkBefore.fullLayoutCount &&
        firstBaselineMicros >= 0 && middleBaselineMicros >= 0 && endBaselineMicros >= 0 &&
        firstTiming.status == CJGUI_INTERNAL_RENDERER_OK && middleTiming.status == CJGUI_INTERNAL_RENDERER_OK && endTiming.status == CJGUI_INTERNAL_RENDERER_OK
    if (isCorrect && emitsMetric) {
        let shape = if (multipleParagraphs) { "multiple" } else { "single" }
        println("CJGUI_LONG_TEXT_COST paragraphs=${shape} bytes=${source.size} local_edits=3 start_ms=${firstEditMs} middle_ms=${middleEditMs} end_ms=${endEditMs} input_ms=${firstInputMs},${middleInputMs},${endInputMs} input_mutation_us=${firstTiming.mutationMicros},${middleTiming.mutationMicros},${endTiming.mutationMicros} standalone_fully_laid_mutation_us=${firstBaselineMicros},${middleBaselineMicros},${endBaselineMicros} input_text_delegate_us=${firstTiming.textDelegateMicros},${middleTiming.textDelegateMicros},${endTiming.textDelegateMicros} input_selection_delegate_us=${firstTiming.selectionDelegateMicros},${middleTiming.selectionDelegateMicros},${endTiming.selectionDelegateMicros} input_event_enqueue_us=${firstTiming.eventEnqueueMicros},${middleTiming.eventEnqueueMicros},${endTiming.eventEnqueueMicros} input_accessibility_us=${firstTiming.accessibilityMicros},${middleTiming.accessibilityMicros},${endTiming.accessibilityMicros} pump_ms=${firstPumpMs},${middlePumpMs},${endPumpMs} owner_ms=${firstOwnerMs},${middleOwnerMs},${endOwnerMs} build_delta=${after.buildPassCount - before.buildPassCount} layout_delta=${after.layoutPassCount - before.layoutPassCount} submit_delta=${after.nativeSubmissionCount - before.nativeSubmissionCount} active_range_layout_delta=${layoutWorkAfter.rangeLayoutCount - layoutWorkBefore.rangeLayoutCount} active_full_layout_delta=${layoutWorkAfter.fullLayoutCount - layoutWorkBefore.fullLayoutCount}")
    } else if (!isCorrect) {
        let shape = if (multipleParagraphs) { "multiple" } else { "single" }
        println("CJGUI_LONG_TEXT_COST_FAILURE paragraphs=${shape} events=${controller.observedTextEvents() - beforeEvents} version_delta=${controller.documentVersion() - beforeVersion} range_before=${layoutWorkBefore.rangeLayoutCount} range_after=${layoutWorkAfter.rangeLayoutCount} full_before=${layoutWorkBefore.fullLayoutCount} full_after=${layoutWorkAfter.fullLayoutCount} work_status=${layoutWorkAfter.status}")
    }
    return isCorrect
}

private func printLayoutTrace(phase: String, sourceBytes: Int64, trace: AppKitActiveLayoutTrace,
    inputMutation: String, selection: String) {
    println("CJGUI_LAYOUT_TRACE phase=${phase} bytes=${sourceBytes} input_mutation_us=${inputMutation} selection_us=${selection} char_ensure_count=${trace.characterEnsureCount} char_ensure_us=${trace.characterEnsureMicros} bounding_ensure_count=${trace.boundingEnsureCount} bounding_ensure_us=${trace.boundingEnsureMicros} glyph_index_count=${trace.glyphIndexCount} glyph_index_us=${trace.glyphIndexMicros} line_fragment_count=${trace.lineFragmentCount} line_fragment_us=${trace.lineFragmentMicros} glyph_location_count=${trace.glyphLocationCount} glyph_location_us=${trace.glyphLocationMicros} position_us=${trace.positionProxyMicros} position_noop_writes=${trace.positionNoopWrites} position_changed_writes=${trace.positionChangedWrites} position_first_unlaid_before=${trace.positionFirstUnlaidBefore} position_first_unlaid_after=${trace.positionFirstUnlaidAfter} position_changed_mask=${trace.positionChangedMask} first_unlaid_before=${trace.firstUnlaidBefore} first_unlaid_after=${trace.firstUnlaidAfter} sdk_actual_invalidation=not_bound reveal_us=${trace.revealMicros} candidate_us=${trace.candidateMicros}")
}

private func exerciseLayoutTrace(window: CjguiComposableUiWindow, controller: AppKitTextController): Bool {
    let source = longUnicodeText(100 * 1024, multipleParagraphs: true)
    if (!controller.replaceDraftFromExternal(source) || !window.refresh()) { return false }
    if (!selectRange(window, 1u32, 1000000u32, 1000000u32) || window.pump(0u32).didApplyHumanAction) { return false }
    if (!resetActiveLayoutTrace(window)) { return false }
    if (!insertAtCurrentSelectionWithAppKit(window, "T")) { return false }
    let input = inputTiming(window)
    let trace = activeLayoutTrace(window)
    if (!window.pump(0u32).didApplyHumanAction) { return false }
    let inputObserved = input.status == CJGUI_INTERNAL_RENDERER_OK && trace.status == CJGUI_INTERNAL_RENDERER_OK &&
        trace.characterEnsureCount > 0u64 &&
        trace.positionNoopWrites + trace.positionChangedWrites == 9u64
    if (inputObserved) { printLayoutTrace("tail_insert", source.size, trace, input.mutationMicros.toString(), input.selectionDelegateMicros.toString()) }
    if (!resetActiveLayoutTrace(window)) { return false }
    let candidateMapped = hasMappedCandidateRectAt(window, 1000000u32)
    let candidateTrace = activeLayoutTrace(window)
    if (candidateTrace.status == CJGUI_INTERNAL_RENDERER_OK) { printLayoutTrace("tail_candidate", source.size, candidateTrace, "none", "none") }
    if (!resetActiveLayoutTrace(window)) { return false }
    let scrollObserved = scrollWithinActiveMultilineViewport(window)
    let scrollTrace = activeLayoutTrace(window)
    if (scrollTrace.status == CJGUI_INTERNAL_RENDERER_OK) { printLayoutTrace("viewport_scroll", source.size, scrollTrace, "none", "none") }
    if (!resetActiveLayoutTrace(window)) { return false }
    let hitObserved = dragAcrossVisibleLines(window)
    let hitTrace = activeLayoutTrace(window)
    if (hitTrace.status == CJGUI_INTERNAL_RENDERER_OK) { printLayoutTrace("visible_hit", source.size, hitTrace, "none", "none") }
    // A geometry/style write which is byte-for-byte identical must not
    // invalidate the existing TextKit layout. The current implementation
    // intentionally fails here until positionInputProxy stops reassigning
    // identical values.
    let scrollKeepsLaidFrontier = scrollTrace.positionNoopWrites > 0u64 &&
        scrollTrace.positionChangedMask == 0u64 &&
        scrollTrace.positionFirstUnlaidBefore == scrollTrace.positionFirstUnlaidAfter
    let isObserved = inputObserved && candidateMapped && scrollObserved && scrollKeepsLaidFrontier &&
        candidateTrace.status == CJGUI_INTERNAL_RENDERER_OK && scrollTrace.status == CJGUI_INTERNAL_RENDERER_OK
    if (!isObserved) {
        println("CJGUI_LAYOUT_TRACE_FAILURE input_observed=${inputObserved} candidate_mapped=${candidateMapped} scroll_observed=${scrollObserved} scroll_keeps_laid_frontier=${scrollKeepsLaidFrontier} hit_observed=${hitObserved}")
    }
    return isObserved
}

private func exerciseSteadyHotLocation(window: CjguiComposableUiWindow, controller: AppKitTextController,
    minimumUtf8Bytes: Int64, multipleParagraphs: Bool, selection: UInt32, position: String): Bool {
    let source = longUnicodeText(minimumUtf8Bytes, multipleParagraphs: multipleParagraphs)
    if (!controller.replaceDraftFromExternal(source) || !window.refresh()) { return false }
    let beforeEvents = controller.observedTextEvents()
    let beforeVersion = controller.documentVersion()
    let shape = if (multipleParagraphs) { "multiple" } else { "single" }
    var iteration: Int64 = 0
    while (iteration < 35) {
        if (!selectRange(window, 1u32, selection, selection) || window.pump(0u32).didApplyHumanAction) { return false }
        if (!resetActiveLayoutTrace(window)) { return false }
        let insertStarted = MonoTime.now()
        if (!insertAtCurrentSelectionWithAppKit(window, "H")) { return false }
        let insertTiming = inputTiming(window)
        let afterInsertInput = MonoTime.now()
        let insertTrace = activeLayoutTrace(window)
        if (!window.pump(0u32).didApplyHumanAction) { return false }
        let insertTurnMs = (MonoTime.now() - insertStarted).toMilliseconds()
        let insertInputMs = (afterInsertInput - insertStarted).toMilliseconds()
        let insertPumpMs = (MonoTime.now() - afterInsertInput).toMilliseconds()
        let insertOwnerMs = controller.lastDocumentOwnerMs()

        if (!resetActiveLayoutTrace(window)) { return false }
        let deleteStarted = MonoTime.now()
        if (!deleteAtCurrentSelectionWithAppKit(window)) { return false }
        let deleteTiming = inputTiming(window)
        let afterDeleteInput = MonoTime.now()
        let deleteTrace = activeLayoutTrace(window)
        if (!window.pump(0u32).didApplyHumanAction) { return false }
        let deleteTurnMs = (MonoTime.now() - deleteStarted).toMilliseconds()
        let deleteInputMs = (afterDeleteInput - deleteStarted).toMilliseconds()
        let deletePumpMs = (MonoTime.now() - afterDeleteInput).toMilliseconds()
        let deleteOwnerMs = controller.lastDocumentOwnerMs()
        if (iteration >= 5) {
            println("CJGUI_STEADY_TEXT shape=${shape} position=${position} bytes=${source.size} sample=${iteration - 5} action=insert selection=${selection} input_ms=${insertInputMs} turn_ms=${insertTurnMs} owner_ms=${insertOwnerMs} pump_ms=${insertPumpMs} mutation_us=${insertTiming.mutationMicros} selection_us=${insertTiming.selectionDelegateMicros} char_ensure_count=${insertTrace.characterEnsureCount} char_ensure_us=${insertTrace.characterEnsureMicros} bounding_ensure_count=${insertTrace.boundingEnsureCount} bounding_ensure_us=${insertTrace.boundingEnsureMicros} first_unlaid_before=${insertTrace.firstUnlaidBefore} first_unlaid_after=${insertTrace.firstUnlaidAfter}")
            println("CJGUI_STEADY_TEXT shape=${shape} position=${position} bytes=${source.size} sample=${iteration - 5} action=delete selection=${selection + 1u32} input_ms=${deleteInputMs} turn_ms=${deleteTurnMs} owner_ms=${deleteOwnerMs} pump_ms=${deletePumpMs} mutation_us=${deleteTiming.mutationMicros} selection_us=${deleteTiming.selectionDelegateMicros} char_ensure_count=${deleteTrace.characterEnsureCount} char_ensure_us=${deleteTrace.characterEnsureMicros} bounding_ensure_count=${deleteTrace.boundingEnsureCount} bounding_ensure_us=${deleteTrace.boundingEnsureMicros} first_unlaid_before=${deleteTrace.firstUnlaidBefore} first_unlaid_after=${deleteTrace.firstUnlaidAfter}")
        }
        if (insertTiming.status != CJGUI_INTERNAL_RENDERER_OK || deleteTiming.status != CJGUI_INTERNAL_RENDERER_OK) { return false }
        iteration += 1
    }
    return controller.documentContentSize() == source.size &&
        controller.observedTextEvents() == beforeEvents + 70 && controller.documentVersion() == beforeVersion + 70
}

private func exerciseSteadyHotLocations(window: CjguiComposableUiWindow, controller: AppKitTextController): Bool {
    return exerciseSteadyHotLocation(window, controller, 100 * 1024, true, 0u32, "start") &&
        exerciseSteadyHotLocation(window, controller, 100 * 1024, true, 2048u32, "middle") &&
        exerciseSteadyHotLocation(window, controller, 100 * 1024, true, 1000000u32, "tail") &&
        exerciseSteadyHotLocation(window, controller, 100 * 1024, false, 0u32, "start") &&
        exerciseSteadyHotLocation(window, controller, 100 * 1024, false, 2048u32, "middle") &&
        exerciseSteadyHotLocation(window, controller, 100 * 1024, false, 1000000u32, "tail")
}

private func exerciseNativeVisibleLayoutBaseline(minimumUtf8Bytes: Int64, multipleParagraphs: Bool,
    selection: UInt32, position: String): Bool {
    let source = longUnicodeText(minimumUtf8Bytes, multipleParagraphs: multipleParagraphs)
    let shape = if (multipleParagraphs) { "multiple" } else { "single" }
    var iteration: Int64 = 0
    while (iteration < 12) {
        let baseline = nativeTextViewVisibleLayoutBaseline(source, selection)
        if (baseline.status != CJGUI_INTERNAL_RENDERER_OK) { return false }
        if (iteration >= 2) {
            println("CJGUI_NATIVE_VISIBLE_LAYOUT_BASELINE shape=${shape} position=${position} bytes=${source.size} sample=${iteration - 2} mutation_us=${baseline.mutationMicros} selection_layout_us=${baseline.selectionLayoutMicros}")
        }
        iteration += 1
    }
    return true
}

private func exerciseNativeVisibleLayoutBaselines(): Bool {
    return exerciseNativeVisibleLayoutBaseline(100 * 1024, true, 0u32, "start") &&
        exerciseNativeVisibleLayoutBaseline(100 * 1024, true, 2048u32, "middle") &&
        exerciseNativeVisibleLayoutBaseline(100 * 1024, true, 1000000u32, "tail") &&
        exerciseNativeVisibleLayoutBaseline(100 * 1024, false, 0u32, "start") &&
        exerciseNativeVisibleLayoutBaseline(100 * 1024, false, 2048u32, "middle") &&
        exerciseNativeVisibleLayoutBaseline(100 * 1024, false, 1000000u32, "tail")
}

private func exerciseContinuousInput(window: CjguiComposableUiWindow, controller: AppKitTextController,
    minimumUtf8Bytes: Int64, emitsMetric: Bool): Bool {
    let source = longUnicodeText(minimumUtf8Bytes, multipleParagraphs: true)
    if (!controller.replaceDraftFromExternal(source) || !window.refresh()) { return false }
    let beforeEvents = controller.observedTextEvents()
    let beforeVersion = controller.documentVersion()
    if (!selectRange(window, 1u32, 2048u32, 2048u32) || window.pump(0u32).didApplyHumanAction) { return false }
    let started = MonoTime.now()
    if (!insertAtCurrentSelectionWithAppKit(window, "c") || !insertAtCurrentSelectionWithAppKit(window, "o") ||
        !insertAtCurrentSelectionWithAppKit(window, "n")) { return false }
    let afterInput = MonoTime.now()
    let pumpStarted = MonoTime.now()
    if (!window.pump(0u32).didApplyHumanAction) { return false }
    let after = window.windowProjection()
    let inputMs = (afterInput - started).toMilliseconds()
    let pumpMs = (MonoTime.now() - pumpStarted).toMilliseconds()
    let ownerEdits = controller.observedTextEvents() - beforeEvents
    let isCorrect = ownerEdits >= 1 && ownerEdits <= 3 &&
        controller.documentVersion() == beforeVersion + ownerEdits && controller.documentContentSize() == source.size + 3 &&
        after.buildPassCount >= 1 && after.layoutPassCount >= 1 && after.nativeSubmissionCount >= 1
    if (isCorrect && emitsMetric) {
        println("CJGUI_CONTINUOUS_TEXT_COST paragraphs=multiple bytes=${source.size} local_edits=3 owner_edits=${ownerEdits} input_ms=${inputMs} pump_ms=${pumpMs}")
    }
    return isCorrect
}

private func press(window: CjguiComposableUiWindow): Bool {
    return pressNode(window, 4u32)
}

private func pressNode(window: CjguiComposableUiWindow, nodeIndex: UInt32): Bool {
    let status = unsafe { cjgui_internal_renderer_test_press_composable_node(window.testSessionToken(), nodeIndex) }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func sendKey(window: CjguiComposableUiWindow, keyCode: UInt16, modifiers: UInt64, expectedNodeId: UInt64): Bool {
    var focusedNodeId: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_send_composable_key(
            window.testSessionToken(), keyCode, modifiers, inout focusedNodeId
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && focusedNodeId == expectedNodeId
}

private func standardEditingCommandsUseTextView(window: CjguiComposableUiWindow): Bool {
    let status = unsafe { cjgui_internal_renderer_test_composable_standard_editing_commands(window.testSessionToken()) }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func selectRange(window: CjguiComposableUiWindow, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_set_composable_selection(
            window.testSessionToken(), nodeIndex, selectionStart, selectionEnd
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func setSelectionBodyPreparationMode(window: CjguiComposableUiWindow, mode: UInt8): Bool {
    return unsafe {
        cjgui_internal_renderer_test_set_composable_selection_body_preparation_mode(
            window.testSessionToken(), mode
        )
    } == CJGUI_INTERNAL_RENDERER_OK
}

private func hasInputOnlyMultilineProxy(window: CjguiComposableUiWindow): Bool {
    var scrollAlpha: Float32 = 0.0
    var textAlpha: Float32 = 0.0
    let status = unsafe {
        cjgui_internal_renderer_test_composable_multiline_proxy_opacity(
            window.testSessionToken(), inout scrollAlpha, inout textAlpha
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && scrollAlpha <= 0.02 && textAlpha <= 0.02
}

private func hasMappedCandidateRectAt(window: CjguiComposableUiWindow, location: UInt32): Bool {
    var x: Float32 = 0.0
    var y: Float32 = 0.0
    var width: Float32 = 0.0
    var height: Float32 = 0.0
    let status = unsafe {
        cjgui_internal_renderer_test_composable_candidate_rect(
            window.testSessionToken(), location, 0u32, inout x, inout y, inout width, inout height
        )
    }
    let mapped = status == CJGUI_INTERNAL_RENDERER_OK && width > 0.0f32 && height > 0.0f32
    if (!mapped) {
        println("CJGUI_CANDIDATE_RECT_DIAGNOSTIC status=${status} x=${x} y=${y} width=${width} height=${height}")
    }
    return mapped
}

private func hasMappedCandidateRect(window: CjguiComposableUiWindow): Bool {
    return hasMappedCandidateRectAt(window, 1u32)
}

private func candidateRectSurvivesNativeResize(window: CjguiComposableUiWindow): Bool {
    var resizeVersion: UInt64 = 0u64
    let resizeStatus = unsafe {
        cjgui_internal_renderer_test_resize_composable_window(window.testSessionToken(), inout resizeVersion)
    }
    return resizeStatus == CJGUI_INTERNAL_RENDERER_OK && resizeVersion > 0u64 && hasMappedCandidateRect(window)
}

// RED: a scale-only backing-properties change must travel through the normal
// native revision, then through the existing Cangjie refresh transaction. It
// is not a direct scene mutation and does not claim a physical second display.
private func backingScaleChangeRebuildsNormalWindow(window: CjguiComposableUiWindow): Bool {
    if (!pressNode(window, 1u32) || !selectRange(window, 1u32, 1u32, 1u32)) { return false }
    window.pump(0u32)
    let beforeProjection = window.windowProjection()
    let beforeWork = textWorkStats(window)
    var revision: UInt64 = 0u64
    var beforeScale: Float64 = 0.0
    var afterScale: Float64 = 0.0
    var drawableWidth: UInt32 = 0u32
    var drawableHeight: UInt32 = 0u32
    let changeStatus = unsafe {
        cjgui_internal_renderer_test_toggle_composable_backing_scale(
            window.testSessionToken(), inout revision, inout beforeScale, inout afterScale,
            inout drawableWidth, inout drawableHeight
        )
    }
    let refreshed = window.refreshIfNeeded()
    let afterProjection = window.windowProjection()
    let afterWork = textWorkStats(window)
    let candidateMapped = hasMappedCandidateRect(window)
    let valid = changeStatus == CJGUI_INTERNAL_RENDERER_OK && revision > 0u64 &&
        beforeScale > 0.0 && afterScale > 0.0 && beforeScale != afterScale &&
        drawableWidth > 0u32 && drawableHeight > 0u32 && refreshed &&
        afterProjection.buildPassCount >= beforeProjection.buildPassCount + 1 &&
        afterProjection.layoutPassCount >= beforeProjection.layoutPassCount + 1 &&
        afterProjection.nativeSubmissionCount >= beforeProjection.nativeSubmissionCount + 1 &&
        afterWork.status == CJGUI_INTERNAL_RENDERER_OK &&
        afterWork.rasterCount > beforeWork.rasterCount && afterWork.uploadCount > beforeWork.uploadCount &&
        candidateMapped
    println("CJGUI_BACKING_SCALE_TRANSITION revision=${revision} before_scale=${beforeScale} after_scale=${afterScale} drawable=${drawableWidth}x${drawableHeight} build_delta=${afterProjection.buildPassCount - beforeProjection.buildPassCount} layout_delta=${afterProjection.layoutPassCount - beforeProjection.layoutPassCount} submit_delta=${afterProjection.nativeSubmissionCount - beforeProjection.nativeSubmissionCount} raster_delta=${afterWork.rasterCount - beforeWork.rasterCount} upload_delta=${afterWork.uploadCount - beforeWork.uploadCount} candidate_mapped=${candidateMapped} valid=${valid}")
    return valid
}

private func hasSingleActiveMultilineLayoutOwner(window: CjguiComposableUiWindow): Bool {
    var entries: UInt32 = 0u32
    var highWater: UInt32 = 0u32
    var afterFirst: UInt64 = 0u64
    var afterSecond: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_multiline_layout_ownership(
            window.testSessionToken(), inout entries, inout highWater, inout afterFirst, inout afterSecond
        )
    }
    let ownsOnlyActive = status == CJGUI_INTERNAL_RENDERER_OK && entries == 0u32 && highWater == 0u32 && afterFirst == afterSecond
    if (!ownsOnlyActive) {
        println("CJGUI_TEXT_LAYOUT_OWNER_DIAGNOSTIC status=${status} inactive_cache_entries=${entries} inactive_cache_high_water=${highWater} after_first=${afterFirst} after_second=${afterSecond}")
    }
    return ownsOnlyActive
}

private func inactiveMultilineLayoutBuildCount(window: CjguiComposableUiWindow): Int64 {
    var entries: UInt32 = 0u32
    var highWater: UInt32 = 0u32
    var afterFirst: UInt64 = 0u64
    var afterSecond: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_multiline_layout_ownership(
            window.testSessionToken(), inout entries, inout highWater, inout afterFirst, inout afterSecond
        )
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK || entries != 0u32 || highWater != 0u32 || afterFirst != afterSecond) { return -1 }
    return Int64(afterSecond)
}

private func scrollAndObserveMultilineBy(window: CjguiComposableUiWindow, deltaY: Float32): Bool {
    var offset: Float32 = 0.0
    var glyphCount: UInt32 = 0
    let status = unsafe {
        cjgui_internal_renderer_test_scroll_composable_multiline(
            window.testSessionToken(), deltaY, inout offset, inout glyphCount
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && offset > 0.0f32 && glyphCount > 0u32
}

private func scrollAndObserveMultiline(window: CjguiComposableUiWindow): Bool {
    // Explicit long jump/near-End path: it may request exact extent to clamp.
    return scrollAndObserveMultilineBy(window, -10000.0f32)
}

private func scrollWithinActiveMultilineViewport(window: CjguiComposableUiWindow): Bool {
    // Ordinary wheel movement must remain a range-layout path. This is kept
    // distinct from the long-jump test above so its permitted cold cost does
    // not mask a hot selection regression.
    return scrollAndObserveMultilineBy(window, -48.0f32)
}

private func dragAcrossVisibleLines(window: CjguiComposableUiWindow): Bool {
    var selectionStart: UInt32 = 0u32
    var selectionEnd: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_drag_composable_text_selection(
            window.testSessionToken(), 1u32,
            30.0f32, 30.0f32, 100.0f32, 62.0f32,
            inout selectionStart, inout selectionEnd
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && selectionEnd > selectionStart
}

private func setMarkedText(window: CjguiComposableUiWindow, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_set_composable_marked_text(
                window.testSessionToken(), 1u32, textResource.value
            )
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func commitMarkedText(window: CjguiComposableUiWindow, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_commit_composable_marked_text(window.testSessionToken(), textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

private func textWorkDeltaIsActual(before: AppKitTextWorkStats, after: AppKitTextWorkStats): Bool {
    return before.status == CJGUI_INTERNAL_RENDERER_OK && after.status == CJGUI_INTERNAL_RENDERER_OK &&
        after.rasterCount > before.rasterCount && after.uploadCount > before.uploadCount &&
        after.rasterBytes > before.rasterBytes && after.uploadBytes > before.uploadBytes &&
        after.rasterCount - before.rasterCount == after.uploadCount - before.uploadCount &&
        after.rasterBytes - before.rasterBytes == after.uploadBytes - before.uploadBytes
}

private func textWorkDeltaIsIdle(before: AppKitTextWorkStats, after: AppKitTextWorkStats): Bool {
    return before.status == CJGUI_INTERNAL_RENDERER_OK && after.status == CJGUI_INTERNAL_RENDERER_OK &&
        after.rasterCount == before.rasterCount && after.rasterBytes == before.rasterBytes &&
        after.rasterMicros == before.rasterMicros && after.uploadCount == before.uploadCount &&
        after.uploadBytes == before.uploadBytes && after.uploadMicros == before.uploadMicros
}

private func printTextWorkSample(workload: String, nodes: Int64, sample: Int64, phase: String,
    input: AppKitInputTiming, before: AppKitTextWorkStats, after: AppKitTextWorkStats, encoder: AppKitEncoderStats): Unit {
    println("CJGUI_RENDER_WORK_SAMPLE workload=${workload} nodes=${nodes} sample=${sample} phase=${phase} input_mutation_us=${input.mutationMicros} input_delegate_us=${input.textDelegateMicros} input_selection_us=${input.selectionDelegateMicros} raster_count=${after.rasterCount - before.rasterCount} raster_bytes=${after.rasterBytes - before.rasterBytes} raster_us=${after.rasterMicros - before.rasterMicros} upload_count=${after.uploadCount - before.uploadCount} upload_bytes=${after.uploadBytes - before.uploadBytes} upload_us=${after.uploadMicros - before.uploadMicros} encoder_status=${encoder.status} encoder_shape_nodes=${encoder.shapeNodes} encoder_shape_batches=${encoder.shapeBatches} encoder_texture_draws=${encoder.textureDraws} encoder_vertex_bytes=${encoder.shapeVertexBytes} encoder_vertex_stride=${encoder.vertexStride} encoder_max_batch_bytes=${encoder.maxShapeBatchVertexBytes} encoder_cpu_us=${encoder.cpuEncodeMicros}")
}

// This is a deliberately delayed active-multiline preparation, not a timing
// around `pump` alone. The first derived texture admission is rejected by the
// existing test seam; the next main-queue continuation must prepare it while
// the Cangjie owner has accepted the exact typed value/version and submitted
// its corresponding scene. No nested native intervals are added to this
// clock: it starts at the real NSTextView insertion and ends only when every
// independently observed condition below holds.
private func exerciseDelayedTextAcceptance(window: CjguiComposableUiWindow,
    controller: AppKitTextController, workload: String): Bool {
    if (!pressNode(window, 1u32) || !selectRange(window, 1u32, 0u32, 0u32)) { return false }
    let target = "D${controller.currentDraft()}"
    let beforeVersion = controller.documentVersion()
    let beforeDisplayedScene = window.displayedSceneVersion()
    let beforeProjection = window.windowProjection()
    let forceStatus = unsafe {
        cjgui_internal_renderer_test_set_composable_text_preparation_failures(window.testSessionToken(), 1u32)
    }
    if (forceStatus != CJGUI_INTERNAL_RENDERER_OK) { return false }
    let started = MonoTime.now()
    if (!insertAtNodeWithAppKit(window, 1u32, "D")) { return false }
    let immediate = activeTextPreparationState(window)
    // This establishes a real deferred continuation before the application
    // pump is allowed to accept the owner event.
    if (immediate.status != CJGUI_INTERNAL_RENDERER_OK || immediate.scheduled != 1u8 || immediate.failed != 1u8 ||
        immediate.retryCount != 1u32 || immediate.remainingFailures != 0u32) {
        println("CJGUI_TEXT_ACCEPTANCE_FAILED workload=${workload} phase=after_insert state_status=${immediate.status} scheduled=${immediate.scheduled} failed=${immediate.failed} retry=${immediate.retryCount} remaining_failures=${immediate.remainingFailures}")
        return false
    }
    var turns: Int64 = 0
    var didApply = false
    var sawFailedOrRetry = immediate.failed == 1u8 || immediate.retryCount > 0u32
    var accepted = false
    var finalState = immediate
    var finalProjection = beforeProjection
    while (turns < 25) {
        let pump = window.pump(4u32)
        didApply = didApply || pump.didApplyHumanAction
        finalState = activeTextPreparationState(window)
        finalProjection = window.windowProjection()
        sawFailedOrRetry = sawFailedOrRetry || finalState.failed == 1u8 || finalState.retryCount > 0u32
        accepted = didApply && controller.hasDraft(target) && controller.documentVersion() == beforeVersion + 1 &&
            nativeTextMatches(window, target) && finalState.status == CJGUI_INTERNAL_RENDERER_OK &&
            finalState.scheduled == 0u8 && finalState.failed == 0u8 && finalState.retryCount == 0u32 &&
            finalState.remainingFailures == 0u32 && window.displayedSceneVersion() > beforeDisplayedScene &&
            finalProjection.nativeSubmissionCount > beforeProjection.nativeSubmissionCount &&
            finalProjection.pendingRefreshReason == "none"
        if (accepted) { break }
        turns += 1
    }
    let totalMs = (MonoTime.now() - started).toMilliseconds()
    println("CJGUI_TEXT_ACCEPTANCE_TOTAL workload=${workload} target_utf8_bytes=${target.size} target_version=${beforeVersion + 1} total_ms=${totalMs} turns=${turns + 1} delayed_scheduled_before_pump=${immediate.scheduled} retry_or_failure_observed=${sawFailedOrRetry} accepted=${accepted} displayed_scene=${window.displayedSceneVersion()} submitted_frame=${finalProjection.submittedFrameIndex} native_submissions=${finalProjection.nativeSubmissionCount} pending=${finalProjection.pendingRefreshReason}")
    return accepted
}

// Two real Cangjie controllers exercise the ordinary host path.  The 256-node
// variant is deliberately mixed: root + two multiline inputs + one single
// input + boolean + button + 250 static text nodes.  All typing still enters
// the actual NSTextView delegate and controller owner; no FIFO edit injection
// or mock renderer participates in these samples.
// TDD RED: one real 100KiB multiline insertion must report the nested system
// insert and callback boundaries separately, and it must let this probe
// compare the production bounded-edit setting against an otherwise identical
// multiline setting. This does not assert which setting is faster.
private func exerciseInputCallbackTrace(window: CjguiComposableUiWindow, controller: AppKitTextController): Bool {
    let source = longUnicodeText(100 * 1024, multipleParagraphs: true)
    var sample: Int64 = 0
    while (sample < 3) {
        let mode = if (sample == 0) { "production" } else if (sample == 1) { "bounded_test_control" } else { "multiline_test_control" }
        let expectedModeChanges: UInt64 = if (sample == 1) { 2u64 } else { 0u64 }
        if (!controller.replaceDraftFromExternal(source) || !window.refresh() ||
            !selectRange(window, 1u32, 0u32, 0u32) || window.pump(0u32).didApplyHumanAction) {
            return false
        }
        if (sample == 1 && !setBoundedInputLayout(window, true)) { return false }
        if (sample == 2 && !setBoundedInputLayout(window, false)) { return false }
        if (!resetInputCallbackTrace(window)) { return false }
        let beforeProjection = window.windowProjection()
        let beforeVersion = controller.documentVersion()
        let started = MonoTime.now()
        if (!insertAtCurrentSelectionWithAppKit(window, "Q")) { return false }
        let timing = inputTiming(window)
        let inputElapsedMs = (MonoTime.now() - started).toMilliseconds()
        let trace = inputCallbackTrace(window)
        if (!window.pump(0u32).didApplyHumanAction) { return false }
        let totalElapsedMs = (MonoTime.now() - started).toMilliseconds()
        let afterProjection = window.windowProjection()
        let candidateMapped = hasMappedCandidateRectAt(window, 1u32)
        let scrollMapped = scrollWithinActiveMultilineViewport(window)
        let valid = timing.status == CJGUI_INTERNAL_RENDERER_OK && trace.status == CJGUI_INTERNAL_RENDERER_OK &&
            trace.superInsertMicros > 0u64 && trace.textCallbackCount > 0u64 && trace.selectionCallbackCount > 0u64 &&
            trace.modeChangeCount == expectedModeChanges && trace.wholeAttributeWriteCount == 0u64 &&
            controller.documentVersion() == beforeVersion + 1 && controller.documentContentSize() == source.size + 1 &&
            afterProjection.buildPassCount >= beforeProjection.buildPassCount + 1 &&
            afterProjection.layoutPassCount >= beforeProjection.layoutPassCount + 1 &&
            afterProjection.nativeSubmissionCount >= beforeProjection.nativeSubmissionCount + 1 &&
            candidateMapped && scrollMapped
        println("CJGUI_INPUT_CALLBACK_TRACE mode=${mode} bytes=${source.size} input_ms=${inputElapsedMs} total_ms=${totalElapsedMs} super_insert_us=${trace.superInsertMicros} mode_change_count=${trace.modeChangeCount} mode_change_us=${trace.modeChangeMicros} text_callback_count=${trace.textCallbackCount} text_callback_us=${trace.textCallbackMicros} selection_callback_count=${trace.selectionCallbackCount} pending_edit_selection_count=${trace.pendingEditSelectionCount} selection_callback_us=${trace.selectionCallbackMicros} selection_reveal_us=${trace.selectionRevealMicros} selection_queue_us=${trace.selectionQueueMicros} selection_accessibility_us=${trace.selectionAccessibilityMicros} refresh_us=${trace.refreshMicros} preparation_us=${trace.preparationMicros} whole_attribute_writes=${trace.wholeAttributeWriteCount} whole_attribute_characters=${trace.wholeAttributeCharacters} fallback_apply_count=${trace.fallbackApplyCount} fallback_characters=${trace.fallbackCharacters} fallback_us=${trace.fallbackMicros} owner_version_delta=${controller.documentVersion() - beforeVersion} accepted_build_delta=${afterProjection.buildPassCount - beforeProjection.buildPassCount} accepted_layout_delta=${afterProjection.layoutPassCount - beforeProjection.layoutPassCount} accepted_submit_delta=${afterProjection.nativeSubmissionCount - beforeProjection.nativeSubmissionCount} candidate_mapped=${candidateMapped} scroll_mapped=${scrollMapped} valid=${valid}")
        if (!valid) { return false }
        sample += 1
    }
    return setBoundedInputLayout(window, true)
}

private func exerciseRendererWorkCost(staticRows: Int64, workload: String): Bool {
    let controller = AppKitTextController(staticRows)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return false }
    if (!textWorkReasonStatsAvailable(window)) {
        println("CJGUI_RENDER_WORK_FAILED workload=${workload} phase=reason_stats_missing")
        window.close()
        return false
    }
    let expectedNodes = staticRows + 6
    if (window.windowProjection().nodes.size != expectedNodes ||
        !controller.replaceDraftFromExternal(LONG_MULTILINE_TEXT) || !window.refresh()) { window.close(); return false }
    var sample: Int64 = 0
    while (sample < 30) {
        if (!pressNode(window, 5u32) || !selectRange(window, 5u32, 0u32, 0u32)) { window.close(); return false }
        // Settle the focus-only projection before beginning the next input
        // sample. A real focus hand-off may turn the previously active input
        // into a static candidate; that resource work belongs to focus, not
        // to the subsequent text owner's acknowledgement.
        window.pump(0u32)
        let singleBefore = textWorkStats(window)
        if (!insertAtNodeWithAppKit(window, 5u32, "s")) { window.close(); return false }
        let singleTiming = inputTiming(window)
        let singleAfterInput = textWorkStats(window)
        if (!window.pump(0u32).didApplyHumanAction) { window.close(); return false }
        let singleAfter = textWorkStats(window)
        let singleEncoder = encoderStats(window)
        if (!textWorkDeltaIsActual(singleBefore, singleAfter) || singleEncoder.status != CJGUI_INTERNAL_RENDERER_OK ||
            singleEncoder.textureDraws == 0u32 || singleEncoder.vertexStride == 0u32 ||
            singleEncoder.maxShapeBatchVertexBytes > 4096u64 || !textWorkDeltaIsIdle(singleAfterInput, singleAfter)) {
            println("CJGUI_RENDER_WORK_FAILED workload=${workload} phase=single_owner_ack expected_nodes=${expectedNodes} owner_ack_raster_count=${singleAfter.rasterCount - singleAfterInput.rasterCount} owner_ack_raster_bytes=${singleAfter.rasterBytes - singleAfterInput.rasterBytes} owner_ack_upload_count=${singleAfter.uploadCount - singleAfterInput.uploadCount} owner_ack_upload_bytes=${singleAfter.uploadBytes - singleAfterInput.uploadBytes} encoder_status=${singleEncoder.status} encoder_shape_nodes=${singleEncoder.shapeNodes} encoder_batches=${singleEncoder.shapeBatches} encoder_texture_draws=${singleEncoder.textureDraws} encoder_vertex_bytes=${singleEncoder.shapeVertexBytes} encoder_stride=${singleEncoder.vertexStride} encoder_max_batch_bytes=${singleEncoder.maxShapeBatchVertexBytes} encoder_cpu_us=${singleEncoder.cpuEncodeMicros}")
            window.close(); return false
        }
        printTextWorkSample(workload, expectedNodes, sample, "single_insert", singleTiming, singleBefore, singleAfter, singleEncoder)

        if (!pressNode(window, 1u32) || !selectRange(window, 1u32, 0u32, 0u32)) { window.close(); return false }
        window.pump(0u32)
        let multilineBefore = textWorkStats(window)
        if (!insertAtNodeWithAppKit(window, 1u32, "m")) { window.close(); return false }
        let multilineTiming = inputTiming(window)
        let multilineAfterInput = textWorkStats(window)
        if (!window.pump(0u32).didApplyHumanAction) { window.close(); return false }
        let multilineAfter = textWorkStats(window)
        let multilineEncoder = encoderStats(window)
        if (!textWorkDeltaIsActual(multilineBefore, multilineAfter) || multilineEncoder.status != CJGUI_INTERNAL_RENDERER_OK ||
            multilineEncoder.textureDraws == 0u32 || multilineEncoder.vertexStride == 0u32 ||
            multilineEncoder.maxShapeBatchVertexBytes > 4096u64 || !textWorkDeltaIsIdle(multilineAfterInput, multilineAfter)) {
            println("CJGUI_RENDER_WORK_FAILED workload=${workload} phase=multiline_owner_ack owner_ack_raster_count=${multilineAfter.rasterCount - multilineAfterInput.rasterCount} owner_ack_raster_bytes=${multilineAfter.rasterBytes - multilineAfterInput.rasterBytes} owner_ack_upload_count=${multilineAfter.uploadCount - multilineAfterInput.uploadCount} owner_ack_upload_bytes=${multilineAfter.uploadBytes - multilineAfterInput.uploadBytes}")
            window.close(); return false
        }
        printTextWorkSample(workload, expectedNodes, sample, "multiline_insert", multilineTiming, multilineBefore, multilineAfter, multilineEncoder)

        let scrollBefore = textWorkStats(window)
        if (!scrollWithinActiveMultilineViewport(window)) { window.close(); return false }
        let scrollAfter = textWorkStats(window)
        let scrollEncoder = encoderStats(window)
        if (!textWorkDeltaIsActual(scrollBefore, scrollAfter) || scrollEncoder.status != CJGUI_INTERNAL_RENDERER_OK ||
            scrollEncoder.textureDraws == 0u32 || scrollEncoder.vertexStride == 0u32 ||
            scrollEncoder.maxShapeBatchVertexBytes > 4096u64) { window.close(); return false }
        // Scrolling has no NSTextView mutation. Report zero input-delegate
        // intervals instead of accidentally carrying forward the preceding
        // insertion's timing values.
        printTextWorkSample(workload, expectedNodes, sample, "multiline_scroll",
            AppKitInputTiming(CJGUI_INTERNAL_RENDERER_OK, 0u64, 0u64, 0u64, 0u64, 0u64), scrollBefore, scrollAfter, scrollEncoder)
        sample += 1
    }
    if (!exerciseDelayedTextAcceptance(window, controller, workload)) { window.close(); return false }
    if (!printTextWorkReasonSummary(window, workload, expectedNodes, controller.documentVersion(), controller.currentDraft().size)) { window.close(); return false }
    let idleBefore = textWorkStats(window)
    let idle = window.refreshIfNeeded()
    let idleAfter = textWorkStats(window)
    println("CJGUI_RENDER_WORK_IDLE workload=${workload} nodes=${expectedNodes} accepted=${idle} raster_count=${idleAfter.rasterCount - idleBefore.rasterCount} raster_bytes=${idleAfter.rasterBytes - idleBefore.rasterBytes} raster_us=${idleAfter.rasterMicros - idleBefore.rasterMicros} upload_count=${idleAfter.uploadCount - idleBefore.uploadCount} upload_bytes=${idleAfter.uploadBytes - idleBefore.uploadBytes} upload_us=${idleAfter.uploadMicros - idleBefore.uploadMicros}")
    let valid = idle && textWorkDeltaIsIdle(idleBefore, idleAfter)
    window.close()
    return valid
}

// A selection-only turn stays inside the regular normal window and its one
// TextKit input proxy. The owner text/version must remain stable while the
// GPU receives a freshly ordered caret or selection rectangle, not a new body
// bitmap/texture upload. Keep 30 alternating range/caret samples so this is
// a repeatable resource-reuse proof rather than a single happy-path counter.
private func exerciseSelectionResourceCost(staticRows: Int64, workload: String, bodyMode: UInt8, sampleLimit: Int64): Bool {
    let controller = AppKitTextController(staticRows)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return false }
    let source = longUnicodeText(100 * 1024, multipleParagraphs: true)
    let expectedNodes = staticRows + 6
    if (window.windowProjection().nodes.size != expectedNodes ||
        !controller.replaceDraftFromExternal(source) || !window.refresh() ||
        !pressNode(window, 1u32) || !selectRange(window, 1u32, 0u32, 0u32)) {
        window.close()
        return false
    }
    // Attribute the focus hand-off's one-time body admission to setup, never
    // to a later selection-only sample.
    window.pump(0u32)
    let ownerVersion = controller.documentVersion()
    var sample: Int64 = 0
    while (sample < sampleLimit) {
        let condition = if (sampleLimit <= 6) { sample } else { sample / 30 }
        let positionIndex = condition / 2
        let position = if (positionIndex == 0) { "start" } else if (positionIndex == 1) { "middle" } else { "end" }
        let start: UInt32 = if (positionIndex == 0) { 0u32 } else if (positionIndex == 1) { 2048u32 } else { 1000000u32 }
        let isRange = condition % 2 == 0
        let end: UInt32 = if (isRange) { start + 1u32 } else { start }
        let phase = if (isRange) { "range" } else { "caret" }
        // Establish the same-position warm state outside the measured turn so
        // moving between start/middle/end cannot attribute a reveal-induced
        // scroll/body-key change to selection-only work.
        if (!selectRange(window, 1u32, start + 1u32, start + 1u32) || window.pump(0u32).didApplyHumanAction) {
            window.close(); return false
        }
        let before = textWorkStats(window)
        if (!setSelectionBodyPreparationMode(window, bodyMode)) { window.close(); return false }
        let started = MonoTime.now()
        if (!selectRange(window, 1u32, start, end)) { window.close(); return false }
        let timing = inputTiming(window)
        let afterInput = textWorkStats(window)
        let pumped = window.pump(0u32)
        let afterPump = textWorkStats(window)
        let encoder = encoderStats(window)
        let projection = window.windowProjection()
        let totalMs = (MonoTime.now() - started).toMilliseconds()
        let candidateMapped = hasMappedCandidateRectAt(window, 1u32)
        let bodyModeName = if (bodyMode == 0u8) { "reuse_body" } else { "full_body" }
        let projectedSelectionValid = if (positionIndex == 2) {
            projection.selectionStart > 2048 && projection.selectionEnd >= projection.selectionStart
        } else {
            projection.selectionStart == Int64(start) && projection.selectionEnd == Int64(end)
        }
        let fullDeltaHasBodyWork = afterPump.rasterCount > before.rasterCount &&
            afterPump.rasterBytes > before.rasterBytes && afterPump.uploadCount > before.uploadCount &&
            afterPump.uploadBytes > before.uploadBytes
        let resourceValid = if (bodyMode == 0u8) { textWorkDeltaIsIdle(before, afterPump) } else { fullDeltaHasBodyWork }
        let valid = timing.status == CJGUI_INTERNAL_RENDERER_OK && encoder.status == CJGUI_INTERNAL_RENDERER_OK &&
            encoder.textureDraws > 0u32 && encoder.vertexStride > 0u32 &&
            encoder.maxShapeBatchVertexBytes <= 4096u64 && !pumped.didApplyHumanAction &&
            controller.documentVersion() == ownerVersion && controller.documentContentSize() == source.size &&
            projection.focusedControlId == "appkit-probe-text" && projectedSelectionValid && candidateMapped && resourceValid
        println("CJGUI_SELECTION_RESOURCE_SAMPLE workload=${workload} body_mode=${bodyModeName} nodes=${expectedNodes} bytes=${source.size} sample=${sample} position=${position} phase=${phase} selection_start=${start} selection_end=${end} selection_caret_total_ms=${totalMs} input_mutation_us=${timing.mutationMicros} input_delegate_us=${timing.textDelegateMicros} input_selection_us=${timing.selectionDelegateMicros} raster_count=${afterPump.rasterCount - before.rasterCount} raster_bytes=${afterPump.rasterBytes - before.rasterBytes} raster_us=${afterPump.rasterMicros - before.rasterMicros} upload_count=${afterPump.uploadCount - before.uploadCount} upload_bytes=${afterPump.uploadBytes - before.uploadBytes} upload_us=${afterPump.uploadMicros - before.uploadMicros} sub_raster_count=${afterInput.rasterCount - before.rasterCount} sub_upload_count=${afterInput.uploadCount - before.uploadCount} encoder_texture_draws=${encoder.textureDraws} encoder_shape_batches=${encoder.shapeBatches} encoder_cpu_us=${encoder.cpuEncodeMicros} owner_version=${controller.documentVersion()} candidate_mapped=${candidateMapped} valid=${valid}")
        if (!valid) { window.close(); return false }
        sample += 1
    }
    window.close()
    return true
}

main(args: Array<String>): Int64 {
    let diagnosticMode = args.size == 1 && args[0] == "--diagnostic"
    let multiWindowMode = args.size == 1 && args[0] == "--multi-window"
    let multiWindowFairnessMode = args.size == 1 && args[0] == "--multi-window-fairness"
    let multiWindowReentrancyMode = args.size == 1 && args[0] == "--multi-window-reentrancy"
    let multiWindowExceptionGuardMode = args.size == 1 && args[0] == "--multi-window-exception-guard"
    let multiWindowIdentityMode = args.size == 1 && args[0] == "--multi-window-identity"
    let multiWindowPartialCreationMode = args.size == 1 && args[0] == "--multi-window-partial-creation"
    let steadyCostMode = args.size == 1 && args[0] == "--steady-cost"
    let inputCallbackTraceMode = args.size == 1 && args[0] == "--input-callback-trace"
    let backingScaleMode = args.size == 1 && args[0] == "--backing-scale"
    let visibleLayoutBaselineMode = args.size == 1 && args[0] == "--visible-layout-baseline"
    let coldMultipleCostMode = args.size == 1 && args[0] == "--cost-cold"
    let coldSingleCostMode = args.size == 1 && args[0] == "--cost-cold-single"
    let rendererWorkCostMode = args.size == 1 && args[0] == "--renderer-work-cost"
    let selectionResourceCostMode = args.size >= 1 && (args[0] == "--selection-resource-cost" || args[0] == "--selection-resource-cost=full")
    let selectionFullBodyMode = args.size == 1 && args[0] == "--selection-resource-cost=full"
    let selectionSmokeMode = args.size == 1 && (args[0] == "--selection-resource-cost-smoke" || args[0] == "--selection-resource-cost-smoke=full")
    let selectionSmokeFullBodyMode = args.size == 1 && args[0] == "--selection-resource-cost-smoke=full"
    let selectionCoverageSmokeMode = args.size == 1 && (args[0] == "--selection-resource-cost-smoke-coverage" || args[0] == "--selection-resource-cost-smoke-coverage=full")
    let selectionCoverageSmokeFullBodyMode = args.size == 1 && args[0] == "--selection-resource-cost-smoke-coverage=full"
    let coldCostMode = coldMultipleCostMode || coldSingleCostMode
    let costMode = (args.size == 1 && args[0] == "--cost") || coldCostMode
    if (args.size != 0 && !costMode && !diagnosticMode && !multiWindowMode && !multiWindowFairnessMode && !multiWindowReentrancyMode && !multiWindowExceptionGuardMode && !multiWindowIdentityMode && !multiWindowPartialCreationMode && !steadyCostMode && !inputCallbackTraceMode && !backingScaleMode && !visibleLayoutBaselineMode && !rendererWorkCostMode && !selectionResourceCostMode && !selectionSmokeMode && !selectionCoverageSmokeMode) { return 2 }
    if (multiWindowMode) {
        return if (runMultiWindowApplicationProbe()) { 0 } else { 77 }
    }
    if (multiWindowFairnessMode) {
        return if (runMultiWindowFairnessProbe()) { 0 } else { 78 }
    }
    if (multiWindowReentrancyMode) {
        return if (runMultiWindowReentrancyProbe()) { 0 } else { 79 }
    }
    if (multiWindowExceptionGuardMode) {
        return if (runMultiWindowExceptionGuardProbe()) { 0 } else { 81 }
    }
    if (multiWindowIdentityMode) {
        return if (runMultiWindowIdentityProbe()) { 0 } else { 80 }
    }
    if (multiWindowPartialCreationMode) {
        return if (runMultiWindowPartialCreationProbe()) { 0 } else { 82 }
    }
    if (rendererWorkCostMode) {
        return if (exerciseRendererWorkCost(0, "normal") && exerciseRendererWorkCost(250, "mixed_256")) { 0 } else { 71 }
    }
    if (selectionResourceCostMode) {
        let bodyMode: UInt8 = if (selectionFullBodyMode) { 1u8 } else { 0u8 }
        return if (exerciseSelectionResourceCost(0, "normal", bodyMode, 180) && exerciseSelectionResourceCost(250, "mixed_256", bodyMode, 180)) { 0 } else { 74 }
    }
    if (selectionSmokeMode) {
        let bodyMode: UInt8 = if (selectionSmokeFullBodyMode) { 1u8 } else { 0u8 }
        return if (exerciseSelectionResourceCost(0, "smoke", bodyMode, 2)) { 0 } else { 75 }
    }
    if (selectionCoverageSmokeMode) {
        let bodyMode: UInt8 = if (selectionCoverageSmokeFullBodyMode) { 1u8 } else { 0u8 }
        return if (exerciseSelectionResourceCost(0, "smoke_coverage", bodyMode, 6)) { 0 } else { 76 }
    }
    let controller = AppKitTextController(0)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 3 }
    if (backingScaleMode) {
        let passed = backingScaleChangeRebuildsNormalWindow(window)
        window.close()
        return if (passed) { 0 } else { 73 }
    }
    if (diagnosticMode) {
        if (!exerciseLayoutTrace(window, controller)) { return 68 }
    } else if (inputCallbackTraceMode) {
        if (!exerciseInputCallbackTrace(window, controller)) { return 72 }
    } else if (steadyCostMode) {
        if (!exerciseSteadyHotLocations(window, controller)) { return 69 }
    } else if (visibleLayoutBaselineMode) {
        if (!exerciseNativeVisibleLayoutBaselines()) { return 70 }
    } else if (costMode) {
        if (coldCostMode) {
            // Each process starts from the ordinary window startup path and
            // records its first 100KB document edit before this probe warms
            // a matching TextKit/layout graph.  Keep this separate from the
            // hot `--cost` report instead of silently comparing the two.
            let multipleParagraphs = !coldSingleCostMode
            let paragraphShape = if (multipleParagraphs) { "multiple" } else { "single" }
            println("CJGUI_TEXT_COST_SAMPLE temperature=cold paragraphs=${paragraphShape}")
            if (!exerciseLongDocument(window, controller, 100 * 1024, multipleParagraphs, true)) {
                return 61
            }
        } else {
        // Warm TextKit/layout and the document delta path at each scale, then
        // emit the second pass only. The verifier repeats this process three
        // times and records process CPU/RSS independently.
        if (!exerciseLongDocument(window, controller, 10 * 1024, true, false) ||
            !exerciseLongDocument(window, controller, 10 * 1024, true, true) ||
            !exerciseLongDocument(window, controller, 100 * 1024, true, false) ||
            !exerciseLongDocument(window, controller, 100 * 1024, true, true) ||
            !exerciseLongDocument(window, controller, 10 * 1024, false, false) ||
            !exerciseLongDocument(window, controller, 10 * 1024, false, true) ||
            !exerciseLongDocument(window, controller, 100 * 1024, false, false) ||
            !exerciseLongDocument(window, controller, 100 * 1024, false, true) ||
            !exerciseContinuousInput(window, controller, 100 * 1024, false) ||
            !exerciseContinuousInput(window, controller, 100 * 1024, true)) {
            return 61
        }
        }
        // Restore the same production owner through its versioned external
        // mutation path before the short-form interaction assertions below.
        // Cost mode must not silently change those fixtures' text extent.
        if (!controller.replaceDraftFromExternal("initial") || !window.refresh()) { return 68 }
    }
    // The application binds a semantic command to its existing button.  The
    // renderer must not learn the business action name or call it directly.
    if (!window.bindCommand("save", 4)) { return 17 }
    if (!exerciseActiveMultilineFallbackAcknowledgement(window, controller)) { return 75 }
    // Both native calls enqueue before this single pump. The controller must
    // receive the committed NSTextView value before the Apply activation.
    let textEventsBeforeApply = controller.observedTextEvents()
    if (!editWithAppKit(window, LONG_MULTILINE_TEXT)) { return 4 }
    if (!hasInputOnlyMultilineProxy(window)) { return 9 }
    if (!scrollAndObserveMultiline(window)) { return 10 }
    if (!press(window)) { return 5 }
    let result = window.pump(0u32)
    if (!result.didApplyHumanAction || !controller.acceptedTextBeforeApplyAfter(textEventsBeforeApply)) { return 6 }
    // A selection-only event is query state: it must update the live window
    // projection without delivering another domain/controller edit.
    if (!selectRange(window, 1u32, 1u32, 10u32)) { return 7 }
    if (!hasMappedCandidateRect(window)) { return 22 }
    if (!candidateRectSurvivesNativeResize(window)) { return 52 }
    let selectionResult = window.pump(0u32)
    let projection = window.windowProjection()
    // Command-A arrives through the same NSTextView-first-responder path as
    // real text editing. It must remain a text-service command rather than
    // being consumed by the composable window command router.
    if (!sendKey(window, 0u16, 1048576u64, 2u64)) { return 24 }
    let selectAllResult = window.pump(0u32)
    let allTextProjection = window.windowProjection()
    if (selectAllResult.didApplyHumanAction || allTextProjection.focusedControlId != "appkit-probe-text" ||
        !allTextProjection.hasTextSelection || allTextProjection.selectionStart != 0 || allTextProjection.selectionEnd <= 10) {
        return 25
    }
    if (!dragAcrossVisibleLines(window)) { return 11 }
    let dragResult = window.pump(0u32)
    let dragProjection = window.windowProjection()
    if (!sendKey(window, 48u16, 0u64, 2u64)) { return 20 }
    let tabInserted = window.pump(0u32)
    if (!selectRange(window, 2u32, 0u32, 0u32)) { return 21 }
    let navigationFocus = window.pump(0u32)
    if (!sendKey(window, 48u16, 0u64, 3u64)) { return 12 }
    let booleanFocus = window.pump(0u32)
    if (!sendKey(window, 49u16, 0u64, 3u64)) { return 13 }
    let booleanToggle = window.pump(0u32)
    if (!sendKey(window, 48u16, 0u64, 4u64)) { return 14 }
    let buttonFocus = window.pump(0u32)
    if (!sendKey(window, 49u16, 0u64, 4u64)) { return 15 }
    let keyboardApply = window.pump(0u32)
    if (!sendKey(window, 1u16, 1048576u64, 4u64)) { return 18 }
    let commandApply = window.pump(0u32)
    if (!commandApply.didApplyHumanAction) { return 19 }
    if (!hasSingleActiveMultilineLayoutOwner(window)) { return 23 }
    if (costMode) { println("CJGUI_TEXT_LAYOUT_OWNER inactive_cache_entries=0 inactive_cache_high_water=0") }
    // GPU-derived resources own the inactive multiline pixels. Keep the
    // multiline adapter active, then change an unrelated navigation field:
    // it must neither create a second TextKit graph nor replace the active
    // adapter's owner-backed value.
    if (!selectRange(window, 1u32, 0u32, 0u32)) { return 65 }
    let layoutOwnerFocus = window.pump(0u32)
    if (layoutOwnerFocus.didApplyHumanAction) { return 65 }
    let inactiveBuildsBefore = inactiveMultilineLayoutBuildCount(window)
    // The preceding Tab test intentionally committed an edit. Compare the
    // dormant adapter against the controller's current authoritative value,
    // rather than the pre-edit fixture constant.
    let inactiveAdapterValue = controller.currentDraft()
    let inactiveAdapterMatchesBefore = nativeTextMatches(window, inactiveAdapterValue)
    let inactiveNavigationReplaced = controller.replaceInactiveNavigation("navigation externally updated")
    let inactiveNavigationRefresh = window.refresh()
    if (inactiveBuildsBefore < 0 || !inactiveAdapterMatchesBefore ||
        !inactiveNavigationReplaced || !inactiveNavigationRefresh) {
        return 65
    }
    let inactiveBuildsAfter = inactiveMultilineLayoutBuildCount(window)
    if (inactiveBuildsAfter != inactiveBuildsBefore || !nativeTextMatches(window, inactiveAdapterValue)) { return 66 }
    // A committed NSTextView change may already be in the native FIFO when a
    // newer authoritative projection arrives.  The stale event must be
    // rejected by the normal window version check, and the proxy must adopt
    // that external value before another composition can begin.
    let queuedExternalEventCount = controller.observedTextEvents()
    if (!editWithAppKit(window, "本地已提交")) { return 53 }
    if (!controller.replaceDraftFromExternal("远端排队")) { return 54 }
    if (!window.refresh()) { return 54 }
    let staleCommittedDrain = window.pump(0u32)
    let staleOwnerCountMatches = controller.observedTextEvents() == queuedExternalEventCount
    let staleDraftMatches = controller.hasDraft("远端排队")
    let staleNativeMatches = nativeTextMatches(window, "远端排队")
    if (staleCommittedDrain.didApplyHumanAction || !staleOwnerCountMatches || !staleDraftMatches || !staleNativeMatches) {
        println("CJGUI_STALE_EXTERNAL_DIAGNOSTIC applied=${staleCommittedDrain.didApplyHumanAction} owner_count_matches=${staleOwnerCountMatches} draft_matches=${staleDraftMatches} native_matches=${staleNativeMatches}")
        return 55
    }
    if (!setMarkedText(window, "排队后的新组合")) { return 56 }
    if (!commitMarkedText(window, "!")) { return 57 }
    let queuedExternalContinuation = window.pump(0u32)
    if (!queuedExternalContinuation.didApplyHumanAction ||
        !controller.compositionCommittedOnceAfter(queuedExternalEventCount, "远端排队!")) {
        return 58
    }
    if (!controller.undoLastHuman() || !controller.hasDraft("远端排队") ||
        !controller.redoLastHuman() || !controller.hasDraft("远端排队!")) {
        return 59
    }
    if (!window.refresh()) { return 60 }
    // A real controller may reject a close for domain reasons. That refusal
    // must leave the same TextKit/document owner usable for the next edit.
    if (window.requestCloseFromApplication() || !window.isOpen()) { return 62 }
    let rejectedCloseEventCount = controller.observedTextEvents()
    if (!editWithAppKit(window, "拒绝关闭后继续编辑")) { return 63 }
    let rejectedCloseContinuation = window.pump(0u32)
    if (!rejectedCloseContinuation.didApplyHumanAction ||
        !controller.compositionCommittedOnceAfter(rejectedCloseEventCount, "拒绝关闭后继续编辑")) {
        return 64
    }
    // A marked TextKit composition has no domain mutation yet. If an external
    // replacement reaches the same resource, the preedit must be cancelled;
    // a later commit must append to the external value exactly once.
    if (!setMarkedText(window, "本地")) { return 28 }
    if (!setMarkedText(window, "本地组合")) { return 29 }
    if (!controller.replaceDraftFromExternal("远端基线")) { return 30 }
    if (!window.refresh()) { return 30 }
    let compositionEventCount = controller.observedTextEvents()
    // The interrupted preedit is no longer a valid input transaction.
    if (commitMarkedText(window, "!")) { return 31 }
    if (!setMarkedText(window, "新组合")) { return 32 }
    if (!commitMarkedText(window, "!")) { return 33 }
    let compositionCommit = window.pump(0u32)
    if (!compositionCommit.didApplyHumanAction ||
        !controller.compositionCommittedOnceAfter(compositionEventCount, "远端基线!")) {
        return 34
    }
    // Moving focus must discard a pending TextKit preedit instead of letting
    // `unmarkText` turn it into a late domain edit on the old resource.
    let cancellationEventCount = controller.observedTextEvents()
    if (!setMarkedText(window, "焦点取消")) { return 36 }
    if (!selectRange(window, 2u32, 0u32, 0u32)) { return 37 }
    let focusCancellation = window.pump(0u32)
    if (focusCancellation.didApplyHumanAction || controller.observedTextEvents() != cancellationEventCount) {
        return 38
    }
    // Escape takes the same cancellation path while the NSTextView adapter is
    // first responder; it must not turn the marked fragment into a commit.
    if (!setMarkedText(window, "Escape取消")) { return 39 }
    if (!sendKey(window, 53u16, 0u64, 2u64)) { return 40 }
    let escapeCancellation = window.pump(0u32)
    if (escapeCancellation.didApplyHumanAction || controller.observedTextEvents() != cancellationEventCount) {
        return 41
    }
    // Projection changes to read-only or disabled are identity-preserving
    // updates, yet must still interrupt a pending preedit before it can reach
    // the old domain target.
    if (!setMarkedText(window, "只读取消")) { return 42 }
    controller.setEditorReadOnly(true)
    if (!window.refresh()) { return 43 }
    if (commitMarkedText(window, "!")) { return 44 }
    let readOnlyCancellation = window.pump(0u32)
    if (readOnlyCancellation.didApplyHumanAction || controller.observedTextEvents() != cancellationEventCount) {
        return 45
    }
    controller.setEditorReadOnly(false)
    if (!window.refresh()) { return 46 }
    if (!setMarkedText(window, "禁用取消")) { return 47 }
    controller.setEditorEnabled(false)
    if (!window.refresh()) { return 48 }
    if (commitMarkedText(window, "!")) { return 49 }
    let disabledCancellation = window.pump(0u32)
    if (disabledCancellation.didApplyHumanAction || controller.observedTextEvents() != cancellationEventCount) {
        return 50
    }
    controller.setEditorEnabled(true)
    if (!window.refresh()) { return 51 }
    let success = !selectionResult.didApplyHumanAction && !selectAllResult.didApplyHumanAction && !dragResult.didApplyHumanAction &&
        !booleanFocus.didApplyHumanAction && booleanToggle.didApplyHumanAction &&
        !buttonFocus.didApplyHumanAction && keyboardApply.didApplyHumanAction && commandApply.didApplyHumanAction &&
        tabInserted.didApplyHumanAction && !navigationFocus.didApplyHumanAction &&
        controller.observedBooleanEvents() == 1 && controller.isEnabled() &&
        projection.focusedControlId == "appkit-probe-text" && projection.hasTextSelection &&
        projection.selectionStart == 1 && projection.selectionEnd == 10 &&
        dragProjection.focusedControlId == "appkit-probe-text" && dragProjection.hasTextSelection &&
        dragProjection.selectionEnd > dragProjection.selectionStart
    controller.rebindResource()
    if (!window.refresh()) { return 16 }
    let reboundProjection = window.windowProjection()
    // Keep the actual native first responder on the editor, then exercise
    // Cmd-C/X/V as NSTextView methods. The native seam restores the user's
    // clipboard before returning and intentionally does not expose it.
    // The native standard-editing seam verifies Copy against the complete
    // current text value before it performs Cut and Paste. Select precisely
    // the known UTF-16 length of "远端基线!" rather than only its first
    // composed character.
    if (!selectRange(window, 1u32, 0u32, 5u32)) { return 26 }
    let editingFocus = window.pump(0u32)
    if (editingFocus.didApplyHumanAction) { return 35 }
    if (!standardEditingCommandsUseTextView(window)) { return 27 }
    if (!success || reboundProjection.focusedControlId.size != 0 || reboundProjection.hasTextSelection) {
        return 8
    }
    println("cjgui composable AppKit text probe: text/apply and selection projection passed")
    window.close()
    return 0
}
