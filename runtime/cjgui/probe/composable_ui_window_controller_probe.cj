package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*

// Probe-only declaration for the native FIFO seam.  It is compiled only by
// verify_composable_ui_window_controller.sh together with the production
// renderer under CJGUI_INTERNAL_TESTING; no production Cangjie API exposes it.
foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_composable_image_stats(
        session: UInt64, outLoadedTextureCount: CPointer<UInt32>, outCacheEntryCount: CPointer<UInt32>,
        outDecodeCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_measurement_count(
        session: UInt64, outMeasurementCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_measurement_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
    func cjgui_internal_renderer_test_set_composable_scene_node_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_version(
        session: UInt64, outSceneVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_update_stats(
        session: UInt64, outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_stats(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>, outMaxPendingInteractionCount: CPointer<UInt32>,
        outAccessibilityNotificationCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_interaction_trace(
        session: UInt64, outPendingInteractionCount: CPointer<UInt32>, outLastEnqueuedKind: CPointer<UInt32>,
        outLastEnqueuedNodeId: CPointer<UInt64>, outLastEnqueuedProjectionVersion: CPointer<UInt64>,
        outLastPumpedKind: CPointer<UInt32>, outLastPumpedNodeId: CPointer<UInt64>,
        outLastPumpedProjectionVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_process_resource_stats(
        session: UInt64, outResidentBytes: CPointer<UInt64>, outUserMicros: CPointer<UInt64>, outSystemMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_invalidate_composable_drawable(session: UInt64): Int32
    func cjgui_internal_renderer_test_resize_composable_window(
        session: UInt64, outResizeVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_send_composable_key(
        session: UInt64, keyCode: UInt16, modifiers: UInt64, outFocusedNodeId: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_capture_composable_accessibility_action(
        session: UInt64, nodeIndex: UInt32
    ): Int32
    func cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session: UInt64): Int32
    func cjgui_internal_renderer_test_click_composable_point(
        session: UInt64, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_press_composable_node(
        session: UInt64, nodeIndex: UInt32
    ): Int32
}

private func enqueueForSession(session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(session, nodeIndex, eventKind, textResource.value)
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

/// Exercise the narrow local-text exception against a controller whose
/// `uiSceneVersion` is its real owner revision.  Each stale callback is
/// deliberately captured from the prior native scene; it must never become
/// an edit merely because the replacement happens to retain the same field
/// object or string value.
private func verifyContinuationOwnerGuards(): Bool {
    // The only positive case: one local successor from the focused native
    // adapter is accepted while the owner revision remains unchanged.
    let acceptedController = NativeEventController()
    let acceptedWindow = CjguiComposableUiWindow(acceptedController)
    if (!acceptedWindow.start() || internalRendererFocusComposableNode(acceptedWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { acceptedWindow.close(); return false }
    acceptedController.armContinuationRace(acceptedWindow.testSessionToken())
    if (!enqueueForSession(acceptedWindow.testSessionToken(), 2u32, 28u32, "initiala")) {
        acceptedWindow.close(); return false
    }
    let acceptedFirst = acceptedWindow.pump(0u32)
    let acceptedSecond = acceptedWindow.pump(0u32)
    let accepted = acceptedFirst.didApplyHumanAction && acceptedSecond.didApplyHumanAction &&
        acceptedController.didInjectContinuation() && acceptedController.hasDraft("initialab") &&
        acceptedController.rejectedTextEvents() == 0
    acceptedWindow.close()
    if (!accepted) { return false }

    // Same object/value, but the external owner revision changes while the
    // successor projection is being assembled (before its native commit).
    let beforeController = NativeEventController()
    let beforeWindow = CjguiComposableUiWindow(beforeController)
    if (!beforeWindow.start() || internalRendererFocusComposableNode(beforeWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { beforeWindow.close(); return false }
    beforeController.armContinuationRace(beforeWindow.testSessionToken())
    beforeController.scheduleExternalReplacementDuringNextBuild("initiala")
    if (!enqueueForSession(beforeWindow.testSessionToken(), 2u32, 28u32, "initiala")) {
        beforeWindow.close(); return false
    }
    let beforeFirst = beforeWindow.pump(0u32)
    let beforeSecond = beforeWindow.pump(0u32)
    let rejectedBeforeRefresh = beforeFirst.didApplyHumanAction && !beforeSecond.didApplyHumanAction &&
        beforeController.didInjectContinuation() && beforeController.hasDraft("initiala") &&
        beforeController.rejectedTextEvents() == 1
    beforeWindow.close()
    if (!rejectedBeforeRefresh) { return false }

    // The same replacement after the v2 scene is visible must also reject:
    // `nativeInputScene` alone would otherwise still see the same value.
    let afterController = NativeEventController()
    let afterWindow = CjguiComposableUiWindow(afterController)
    if (!afterWindow.start() || internalRendererFocusComposableNode(afterWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { afterWindow.close(); return false }
    afterController.armContinuationRace(afterWindow.testSessionToken())
    if (!enqueueForSession(afterWindow.testSessionToken(), 2u32, 28u32, "initiala")) {
        afterWindow.close(); return false
    }
    let afterFirst = afterWindow.pump(0u32)
    afterController.externalSameObjectReplace("initiala")
    let afterSecond = afterWindow.pump(0u32)
    let rejectedAfterRefresh = afterFirst.didApplyHumanAction && !afterSecond.didApplyHumanAction &&
        afterController.didInjectContinuation() && afterController.hasDraft("initiala") &&
        afterController.rejectedTextEvents() == 1
    afterWindow.close()
    if (!rejectedAfterRefresh) { return false }

    // A different external value remains rejectable too; this guards both
    // value and owner revision rather than weakening the earlier rule.
    let valueController = NativeEventController()
    let valueWindow = CjguiComposableUiWindow(valueController)
    if (!valueWindow.start() || internalRendererFocusComposableNode(valueWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { valueWindow.close(); return false }
    valueController.armContinuationRace(valueWindow.testSessionToken())
    if (!enqueueForSession(valueWindow.testSessionToken(), 2u32, 28u32, "initiala")) {
        valueWindow.close(); return false
    }
    let valueFirst = valueWindow.pump(0u32)
    valueController.externalSameObjectReplace("external-value")
    let valueSecond = valueWindow.pump(0u32)
    let rejectedDifferentValue = valueFirst.didApplyHumanAction && !valueSecond.didApplyHumanAction &&
        valueController.hasDraft("external-value") && valueController.rejectedTextEvents() == 1
    valueWindow.close()
    if (!rejectedDifferentValue) { return false }

    // A blur/re-focus captured in the old FIFO deliberately invalidates the
    // one-event handoff before its queued continuation is observed.
    let focusController = NativeEventController()
    let focusWindow = CjguiComposableUiWindow(focusController)
    if (!focusWindow.start() || internalRendererFocusComposableNode(focusWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { focusWindow.close(); return false }
    focusController.armContinuationRace(focusWindow.testSessionToken())
    if (!enqueueForSession(focusWindow.testSessionToken(), 2u32, 28u32, "initiala") ||
        !enqueueForSession(focusWindow.testSessionToken(), 3u32, 31u32, "") ||
        !enqueueForSession(focusWindow.testSessionToken(), 2u32, 31u32, "")) {
        focusWindow.close(); return false
    }
    let focusFirst = focusWindow.pump(0u32)
    let focusSecond = focusWindow.pump(0u32)
    let rejectedAfterRefocus = focusFirst.didApplyHumanAction && !focusSecond.didApplyHumanAction &&
        focusController.didInjectContinuation() && focusController.rejectedTextEvents() == 1
    focusWindow.close()
    if (!rejectedAfterRefocus) { return false }

    // A same-id resource rebind and a read-only replacement each deny the
    // stale local callback even before their next ordinary projection retry.
    let rebindController = NativeEventController()
    let rebindWindow = CjguiComposableUiWindow(rebindController)
    if (!rebindWindow.start() || internalRendererFocusComposableNode(rebindWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { rebindWindow.close(); return false }
    rebindController.armContinuationRace(rebindWindow.testSessionToken())
    rebindController.scheduleExternalReplacementDuringNextBuild("initiala", resourceId: 99)
    if (!enqueueForSession(rebindWindow.testSessionToken(), 2u32, 28u32, "initiala")) {
        rebindWindow.close(); return false
    }
    let rebindFirst = rebindWindow.pump(0u32)
    let rebindSecond = rebindWindow.pump(0u32)
    let rejectedRebind = rebindFirst.didApplyHumanAction && !rebindSecond.didApplyHumanAction &&
        rebindController.rejectedTextEvents() == 1
    rebindWindow.close()
    if (!rejectedRebind) { return false }

    let readOnlyController = NativeEventController()
    let readOnlyWindow = CjguiComposableUiWindow(readOnlyController)
    if (!readOnlyWindow.start() || internalRendererFocusComposableNode(readOnlyWindow.testSessionToken(), 2) !=
        CJGUI_INTERNAL_RENDERER_OK) { readOnlyWindow.close(); return false }
    readOnlyController.armContinuationRace(readOnlyWindow.testSessionToken())
    readOnlyController.scheduleExternalReplacementDuringNextBuild("initiala", readOnly: true)
    if (!enqueueForSession(readOnlyWindow.testSessionToken(), 2u32, 28u32, "initiala")) {
        readOnlyWindow.close(); return false
    }
    let readOnlyFirst = readOnlyWindow.pump(0u32)
    let readOnlySecond = readOnlyWindow.pump(0u32)
    let rejectedReadOnly = readOnlyFirst.didApplyHumanAction && !readOnlySecond.didApplyHumanAction &&
        readOnlyController.rejectedTextEvents() == 1
    readOnlyWindow.close()
    println("CJGUI_RAPID_TEXT_OWNER_GUARDS accepted=${accepted} before_refresh=${rejectedBeforeRefresh} after_refresh=${rejectedAfterRefresh} different_value=${rejectedDifferentValue} refocus=${rejectedAfterRefocus} rebind=${rejectedRebind} read_only=${rejectedReadOnly}")
    return rejectedReadOnly
}

private class NativeEventController <: CjguiComposableUiController {
    private var draft: String
    private var appliedValue: String
    private var showImage: Bool
    private var imageResourceVersion: Int64
    private var imageVariantCount: Int64
    private var uniqueImageResources: Bool
    private var usesCoralImage: Bool
    private var caption: String
    private var captionFontSize: Float64
    private var observedSelection: Bool
    private var declarationRevision: Int64
    private var showsTextInput: Bool
    private var rejectedTextAfterRemoval: Bool
    private var rejectedTextEventCount: Int64
    private var textResourceId: Int64
    private var textReadOnly: Bool
    private var continuationRaceSession: UInt64
    private var injectContinuationOnNextBuild: Bool
    private var injectedContinuation: Bool
    private var externalReplacementDuringNextBuild: Bool
    private var scheduledExternalDraft: String
    private var scheduledExternalResourceId: Int64
    private var scheduledExternalReadOnly: Bool

    init() {
        this.draft = "initial"; this.appliedValue = ""; this.showImage = true; this.imageResourceVersion = 1
        this.imageVariantCount = 2; this.uniqueImageResources = false; this.usesCoralImage = false
        this.caption = "cached AppKit caption"; this.captionFontSize = 13.0; this.observedSelection = false; this.declarationRevision = 1
        this.showsTextInput = true; this.rejectedTextAfterRemoval = false
        this.rejectedTextEventCount = 0; this.textResourceId = 42; this.textReadOnly = false
        this.continuationRaceSession = 0u64; this.injectContinuationOnNextBuild = false; this.injectedContinuation = false
        this.externalReplacementDuringNextBuild = false; this.scheduledExternalDraft = ""
        this.scheduledExternalResourceId = 42; this.scheduledExternalReadOnly = false
    }

    public func uiSceneVersion(): Int64 { return declarationRevision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "controller-probe-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        // Deliberately leaves height natural so the normal window must use the
        // production text measurer on initial layout and on any cache miss.
        root.add(cjguiComposableText(40, "controller-probe-measured-caption", caption, CjguiComposableUiStyle(fontSize: captionFontSize)))
        if (showsTextInput) {
            root.add(cjguiComposableTextInput(2, "controller-probe-text", "value", draft, textResourceId,
                CjguiComposableUiStyle(fixedHeight: 32), readOnly: textReadOnly))
        }
        root.add(cjguiComposableButton(3, "controller-probe-apply", "apply", "APPLY", 42, CjguiComposableUiStyle(fixedHeight: 32)))
        if (showImage) {
            var imageIndex: Int64 = 0
            while (imageIndex < imageVariantCount) {
                let resourceId = if (uniqueImageResources) { "controller-probe-beacon-${imageIndex}" } else { "controller-probe-beacon" }
                let rasterPath = if (usesCoralImage) { "runtime/cjgui/resources/composable-beacon-coral.png" } else { "runtime/cjgui/resources/composable-beacon.png" }
                root.add(cjguiComposableImage(4 + imageIndex, "controller-probe-image-${imageIndex}", rasterPath,
                    CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 64, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
                    contentMode: if (imageIndex == 0) { 1 } else { 2 }, imageResourceId: resourceId, imageResourceVersion: imageResourceVersion))
                imageIndex += 1
            }
        }
        // Native callbacks can land after the input FIFO has supplied the
        // accepted edit but before its replacement projection is committed.
        // Model that host timing explicitly: the queued continuation retains
        // the prior scene version, while its text contains the next local
        // value for the still-focused stable node.
        if (injectContinuationOnNextBuild) {
            injectContinuationOnNextBuild = false
            injectedContinuation = enqueueForSession(continuationRaceSession, 2u32, 28u32, "initialab")
        }
        // This simulates the actual owner accepting an external replacement
        // while the local callback's successor scene is still being built.
        // The field may retain node/value identity; only its durable revision
        // proves the local continuation is no longer authoritative.
        if (externalReplacementDuringNextBuild) {
            externalReplacementDuringNextBuild = false
            draft = scheduledExternalDraft
            textResourceId = scheduledExternalResourceId
            textReadOnly = scheduledExternalReadOnly
            declarationRevision += 1
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 33 && event.node.nodeId == 2) {
            observedSelection = true
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            draft = event.text
            declarationRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "APPLY") {
            appliedValue = draft
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        if (eventKind == 28 && nodeId == 2) {
            rejectedTextAfterRemoval = true
            rejectedTextEventCount += 1
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func didApplyNativeText(): Bool { return appliedValue == "native-updated" }
    public func hasDraft(value: String): Bool { return draft == value }
    public func draftValue(): String { return draft }
    public func didObserveSelection(): Bool { return observedSelection }
    public func removeTextInput(): Unit { showsTextInput = false }
    public func didRejectTextAfterRemoval(): Bool { return rejectedTextAfterRemoval }
    public func rejectedTextEvents(): Int64 { return rejectedTextEventCount }
    public func armContinuationRace(session: UInt64): Unit {
        continuationRaceSession = session
        injectContinuationOnNextBuild = true
        injectedContinuation = false
    }
    public func didInjectContinuation(): Bool { return injectedContinuation }
    public func externalSameObjectReplace(value: String): Unit {
        draft = value
        declarationRevision += 1
    }
    public func scheduleExternalReplacementDuringNextBuild(value: String, resourceId!: Int64 = 42,
        readOnly!: Bool = false): Unit {
        scheduledExternalDraft = value
        scheduledExternalResourceId = resourceId
        scheduledExternalReadOnly = readOnly
        externalReplacementDuringNextBuild = true
    }
    public func removeImage(): Unit { showImage = false }
    public func replaceSamePathImage(): Unit { imageResourceVersion += 1 }
    public func replaceImagePixels(): Unit { usesCoralImage = true; imageResourceVersion += 1 }
    public func showOneFitImage(): Unit { showImage = true; imageVariantCount = 1; uniqueImageResources = false }
    public func showManyUniqueImages(): Unit { showImage = true; imageVariantCount = 10; uniqueImageResources = true }
    public func changeCaption(value: String): Unit { caption = value; declarationRevision += 1 }
    public func useLargeCaptionFont(): Unit { captionFontSize = 24.0; declarationRevision += 1 }
}

/// Its transparent groups deliberately differ only by parent/child relation:
/// the button's resolved pixels stay identical. The window must still publish
/// the derived containment change to external context without forcing Metal
/// to redraw an unchanged scene.
private class HierarchyOnlyController <: CjguiComposableUiController {
    private var nested: Bool
    private var actionRemoved: Bool
    private var appliedStableAction: Bool
    private var rejectedStableAction: Bool
    init() {
        this.nested = false; this.actionRemoved = false
        this.appliedStableAction = false; this.rejectedStableAction = false
    }
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(700, "hierarchy-root", CjguiComposableUiStyle())
        let outer = cjguiComposableVertical(701, "hierarchy-outer", CjguiComposableUiStyle())
        let group = cjguiComposableVertical(702, "hierarchy-group", CjguiComposableUiStyle())
        let action = cjguiComposableButton(703, "hierarchy-action", "stable action", "STABLE", 42,
            CjguiComposableUiStyle(fixedHeight: 30), operationActionName: "STABLE")
        root.add(outer); outer.add(group)
        if (!actionRemoved) {
            if (nested) { group.add(action) } else { outer.add(action) }
        }
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "STABLE") {
            appliedStableAction = true
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        if (eventKind == 27 && nodeId == 703) { rejectedStableAction = true }
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func nestAction(): Unit { nested = true }
    public func removeAction(): Unit { nested = false; actionRemoved = true }
    public func didApplyStableAction(): Bool { return appliedStableAction }
    public func didRejectStableAction(): Bool { return rejectedStableAction }
}

/// A semantic-only reparenting has no native draw delta, yet both the public
/// participant's command declaration and the Cangjie containment projection
/// change. Once that candidate starts being accepted, a participant exception
/// must close the window rather than roll a committed candidate back.
private class SameSceneParticipantExceptionController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private var nested: Bool
    private var revision: Int64
    private var throwAfterCommit: Bool
    private var beginCountValue: Int64
    private var prepareCountValue: Int64
    private var commitCountValue: Int64
    private var rollbackCountValue: Int64

    init() {
        this.nested = false; this.revision = 1; this.throwAfterCommit = false
        this.beginCountValue = 0; this.prepareCountValue = 0
        this.commitCountValue = 0; this.rollbackCountValue = 0
    }

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(750, "same-scene-participant-root", CjguiComposableUiStyle())
        let outer = cjguiComposableVertical(751, "same-scene-participant-outer", CjguiComposableUiStyle())
        let group = cjguiComposableVertical(752, "same-scene-participant-group", CjguiComposableUiStyle())
        let action = cjguiComposableButton(753, "same-scene-participant-action", "stable action", "STABLE", 42,
            CjguiComposableUiStyle(fixedHeight: 30), operationActionName: "STABLE")
        root.add(outer); outer.add(group)
        if (nested) { group.add(action) } else { outer.add(action) }
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func beginSceneRefresh(): Bool { beginCountValue += 1; return true }
    public func prepareSceneRefresh(): Bool { prepareCountValue += 1; return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([CjguiComposableUiCommand(
            if (nested) { "same-scene.nested" } else { "same-scene.flat" }, 753, CjguiComposableUiShortcut("j")
        )])
    }
    public func commitSceneRefresh(): Unit {
        commitCountValue += 1
        if (throwAfterCommit) { throw IllegalArgumentException("same_scene_participant_commit_exception") }
    }
    public func rollbackSceneRefresh(): Unit { rollbackCountValue += 1 }
    public func reparentThenThrowAfterCommit(): Unit { nested = true; throwAfterCommit = true; revision += 1 }
    public func commitCount(): Int64 { return commitCountValue }
    public func rollbackCount(): Int64 { return rollbackCountValue }
}

/// An intentionally tiny consumer that proves the real window input chain:
/// modal backdrop hit testing, scope-confined Tab, Escape dismissal, and
/// focus restoration all use the ordinary Cangjie scene/controller route.
private class LayerInputController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private var layerMode: String
    private var backgroundWasActivated: Bool
    private var topMenuActionWasApplied: Bool
    private var revision: Int64

    init() {
        this.layerMode = ""; this.backgroundWasActivated = false; this.topMenuActionWasApplied = false; this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let host = cjguiComposableLayerHost(9000, "layer-input-host", CjguiComposableUiStyle())
        let base = cjguiComposableVertical(9001, "layer-input-base", CjguiComposableUiStyle(padding: 12, gap: 8))
        base.add(cjguiComposableButton(9002, "layer-open", "open dialog", "OPEN_LAYER", 42,
            CjguiComposableUiStyle(fixedHeight: 32)))
        base.add(cjguiComposableButton(9003, "layer-background", "base action", "BACKGROUND", 42,
            CjguiComposableUiStyle(fixedHeight: 32)))
        base.add(cjguiComposableButton(9010, "layer-open-menu", "open menu", "OPEN_MENU", 42,
            CjguiComposableUiStyle(fixedHeight: 32)))
        host.add(base)
        if (layerMode == "menu") {
            let menu = cjguiComposableAnchoredLayer(9011, "layer-top-menu", "layer-input-top-menu", "menu",
                "layer-input-base", 9010, CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 40, padding: 4))
            menu.add(cjguiComposableButton(9012, "layer-top-menu-action", "menu action", "TOP_MENU_ACTION", 42,
                CjguiComposableUiStyle(fixedHeight: 30)))
            host.add(menu)
        }
        if (layerMode == "dialog" || layerMode == "dialog-menu") {
            let dialog = cjguiComposableDialogLayer(9004, "layer-dialog", "layer-input-dialog", "layer-input-base", 9002,
                CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 180, padding: 12, gap: 8), initialFocusNodeId: 9005)
            dialog.add(cjguiComposableTextInput(9005, "layer-dialog-input", "draft", "", 42,
                CjguiComposableUiStyle(fixedHeight: 32)))
            dialog.add(cjguiComposableButton(9006, "layer-dialog-more", "more", "OPEN_SUBMENU", 42,
                CjguiComposableUiStyle(fixedHeight: 30)))
            dialog.add(cjguiComposableButton(9007, "layer-dialog-close", "close", "CLOSE_LAYER", 42,
                CjguiComposableUiStyle(fixedHeight: 30)))
            host.add(dialog)
            if (layerMode == "dialog-menu") {
                let menu = cjguiComposableAnchoredLayer(9008, "layer-dialog-menu", "layer-input-menu", "menu",
                    "layer-dialog", 9006, CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 40, padding: 4))
                menu.add(cjguiComposableButton(9009, "layer-dialog-menu-action", "submenu action", "SUBMENU_ACTION", 42,
                    CjguiComposableUiStyle(fixedHeight: 30)))
                host.add(menu)
            }
        }
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "OPEN_LAYER") { layerMode = "dialog"; revision += 1; return CjguiComposableUiDispatchResult(true) }
        if (event.eventKind == 27 && event.node.actionName == "OPEN_MENU") { layerMode = "menu"; revision += 1; return CjguiComposableUiDispatchResult(true) }
        if (event.eventKind == 27 && event.node.actionName == "OPEN_SUBMENU") { layerMode = "dialog-menu"; revision += 1; return CjguiComposableUiDispatchResult(true) }
        if (event.eventKind == 27 && event.node.actionName == "BACKGROUND") { backgroundWasActivated = true; return CjguiComposableUiDispatchResult(true) }
        if (event.eventKind == 27 && event.node.actionName == "TOP_MENU_ACTION") { topMenuActionWasApplied = true; return CjguiComposableUiDispatchResult(true) }
        if (event.eventKind == 27 && (event.node.actionName == "CLOSE_LAYER" || event.node.actionName == "LAYER_OUTSIDE")) {
            layerMode = ""; revision += 1; return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 36) {
            if (layerMode == "dialog-menu") { layerMode = "dialog" } else { layerMode = "" }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    // The top menu action only exists while the anchored layer is present.
    // Publish it with the candidate scene so the native command map cannot
    // name a node or focus scope that is absent from the accepted projection.
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (layerMode == "menu") {
            commands.add(CjguiComposableUiCommand(
                "layer.top-menu-action", 9012, CjguiComposableUiShortcut("k"),
                focusScopeId: "layer-input-top-menu"
            ))
        }
        return commands
    }
    public func commitSceneRefresh(): Unit {}
    public func rollbackSceneRefresh(): Unit {}
    public func isDialogOpen(): Bool { return layerMode == "dialog" || layerMode == "dialog-menu" }
    public func isDialogMenuOpen(): Bool { return layerMode == "dialog-menu" }
    public func isTopMenuOpen(): Bool { return layerMode == "menu" }
    public func didActivateBackground(): Bool { return backgroundWasActivated }
    public func didApplyTopMenuAction(): Bool { return topMenuActionWasApplied }
    // Probe-only external owner transition used to prove that an Escape
    // captured by an old native scene cannot close a later/recreated layer.
    public func closeForStaleEscapeRegression(): Unit { layerMode = ""; revision += 1 }
}

/// Keeps the target layer's node order and stable action identity unchanged
/// while a preceding transient layer stops owning a focus scope.  A staged
/// native clone must not retain the old numeric scope for the stable action:
/// Tab must still reach its changed sibling in the target's one Cangjie scope.
private class ScopeRemapController <: CjguiComposableUiController {
    private var prefixOwnsScope: Bool
    private var targetCaptionChanged: Bool
    private var stableActionWasApplied: Bool
    private var revision: Int64

    init() {
        this.prefixOwnsScope = true
        this.targetCaptionChanged = false
        this.stableActionWasApplied = false
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        // Keep every layout node in the ordinary compositional tree. A
        // LayerHost intentionally drops a child that no longer declares a
        // layer, which changes later indexes and would not exercise staged
        // reuse of the target nodes.
        let host = cjguiComposableVertical(9400, "scope-remap-host", CjguiComposableUiStyle(padding: 8, gap: 4))
        let base = cjguiComposableVertical(9401, "scope-remap-base", CjguiComposableUiStyle(padding: 8, gap: 4))
        base.add(cjguiComposableButton(9402, "scope-remap-anchor", "anchor", "ANCHOR", 42,
            CjguiComposableUiStyle(fixedHeight: 30)))
        host.add(base)
        let prefix = if (prefixOwnsScope) {
            cjguiComposableAnchoredLayer(9403, "scope-remap-prefix", "scope-remap-prefix", "menu",
                "scope-remap-base", 9402, CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 40, padding: 4))
        } else {
            cjguiComposableVertical(9403, "scope-remap-prefix", CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 40, padding: 4))
        }
        prefix.add(cjguiComposableButton(9404, "scope-remap-prefix-action", "prefix", "PREFIX", 42,
            CjguiComposableUiStyle(fixedHeight: 30)))
        host.add(prefix)
        let target = cjguiComposableAnchoredLayer(9405, "scope-remap-target", "scope-remap-target", "menu",
            "scope-remap-base", 9402, CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 72, padding: 4, gap: 4))
        target.add(cjguiComposableButton(9406, "scope-remap-stable", "stable", "STABLE_SCOPE", 42,
            CjguiComposableUiStyle(fixedHeight: 30)))
        target.add(cjguiComposableButton(9407, "scope-remap-changed",
            if (targetCaptionChanged) { "changed after scope removal" } else { "changed before scope removal" },
            "CHANGED_SCOPE", 42, CjguiComposableUiStyle(fixedHeight: 30)))
        host.add(target)
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.nodeId == 9406) { stableActionWasApplied = true }
        return CjguiComposableUiDispatchResult(event.eventKind == 27)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func removePrefixScope(): Unit {
        prefixOwnsScope = false
        targetCaptionChanged = true
        revision += 1
    }

    public func didApplyStableAction(): Bool { return stableActionWasApplied }
}

/// Focus ownership is a Cangjie projection decision.  These two transitions
/// keep the neighboring node IDs stable while the active middle control first
/// becomes disabled, then disappears, so the native scene must not leave the
/// user on a stale responder or guess a business target.
private class FocusReplacementController <: CjguiComposableUiController {
    private var middleState: Int64
    private var revision: Int64

    init() {
        this.middleState = 0
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9500, "focus-replacement-root", CjguiComposableUiStyle(padding: 8, gap: 4))
        root.add(cjguiComposableButton(9501, "focus-replacement-before", "before", "BEFORE", 42,
            CjguiComposableUiStyle(fixedHeight: 30)))
        if (middleState != 2) {
            root.add(cjguiComposableButton(9502, "focus-replacement-middle", "middle", "MIDDLE", 42,
                CjguiComposableUiStyle(fixedHeight: 30), enabled: middleState == 0))
        }
        root.add(cjguiComposableButton(9503, "focus-replacement-after", "after", "AFTER", 42,
            CjguiComposableUiStyle(fixedHeight: 30)))
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

    public func disableMiddle(): Unit { middleState = 1; revision += 1 }
    public func removeMiddle(): Unit { middleState = 2; revision += 1 }
}

/// Deliberately removes a visible AX target, then reuses its raw node fields
/// for a different controller action. A retained old accessibility element
/// must remain dead rather than follow that new declaration.
private class AccessibilityRebindController <: CjguiComposableUiController {
    private var targetState: Int64
    private var replacementActivated: Bool
    private var revision: Int64

    init() {
        this.targetState = 0
        this.replacementActivated = false
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9600, "accessibility-rebind-root", CjguiComposableUiStyle(padding: 8))
        if (targetState != 1) {
            let isReplacement = targetState == 2
            root.add(cjguiComposableButton(9601,
                if (isReplacement) { "accessibility-rebind-replacement" } else { "accessibility-rebind-original" },
                if (isReplacement) { "replacement" } else { "original" },
                if (isReplacement) { "REPLACEMENT" } else { "ORIGINAL" }, 42,
                CjguiComposableUiStyle(fixedHeight: 30)))
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "REPLACEMENT") {
            replacementActivated = true
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

    public func removeTarget(): Unit { targetState = 1; revision += 1 }
    public func addReplacement(): Unit { targetState = 2; revision += 1 }
    public func didActivateReplacement(): Bool { return replacementActivated }
}

/// A normal repeated-editor consumer of only the public instance API. The
/// stable business keys, not its display order, own identity; hiding retains
/// an instance while deleting lets a later mount receive a fresh lifecycle.
private class ComponentInstanceController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let components: CjguiComposableUiComponentRegistry
    private var order: ArrayList<String>
    private var betaHidden: Bool
    private var revision: Int64
    private var alphaApplied: Int64
    private var betaApplied: Int64
    private var alphaActionNodeIdValue: Int64
    private var betaActionNodeIdValue: Int64
    private var alphaScopeValue: String
    private var betaScopeValue: String
    private var candidateCaptionRevision: Int64

    init() {
        this.components = CjguiComposableUiComponentRegistry()
        this.order = ArrayList<String>(["alpha", "beta"]); this.betaHidden = false; this.revision = 1
        this.alphaApplied = 0; this.betaApplied = 0; this.alphaActionNodeIdValue = -1; this.betaActionNodeIdValue = -1
        this.alphaScopeValue = ""; this.betaScopeValue = ""
        this.candidateCaptionRevision = 0
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9700, "component-instance-root", CjguiComposableUiStyle(padding: 8, gap: 6))
        alphaActionNodeIdValue = -1; betaActionNodeIdValue = -1
        for (key in order) {
            if (key == "beta" && betaHidden) { let _ = components.retain(key); continue }
            let instance = components.use(key)
            if (!instance.isLive()) { continue }
            let group = cjguiComposableVertical(instance.nodeId("root"), instance.semanticId("root"),
                CjguiComposableUiStyle(padding: 4, gap: 2), inputScopeId: instance.focusScopeId())
            let action = cjguiComposableButton(instance.nodeId("apply"), instance.semanticId("apply"), "apply ${key}",
                if (key == "alpha") { "APPLY_ALPHA" } else { "APPLY_BETA" }, if (key == "alpha") { 51 } else { 52 },
                CjguiComposableUiStyle(fixedHeight: 30))
            group.add(action); root.add(group)
            if (key == "alpha") { alphaActionNodeIdValue = action.nodeId; alphaScopeValue = instance.focusScopeId() }
            else { betaActionNodeIdValue = action.nodeId; betaScopeValue = instance.focusScopeId() }
        }
        // Keep the deterministic native measurement-failure reproduction
        // outside the action index order exercised below.
        root.add(cjguiComposableText(9799, "component-candidate-caption", "component candidate ${candidateCaptionRevision}", CjguiComposableUiStyle()))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "APPLY_ALPHA") { alphaApplied += 1; return CjguiComposableUiDispatchResult(true) }
        if (event.eventKind == 27 && event.node.actionName == "APPLY_BETA") { betaApplied += 1; return CjguiComposableUiDispatchResult(true) }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func commands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (alphaActionNodeIdValue >= 0) { commands.add(CjguiComposableUiCommand("editor.alpha.apply", alphaActionNodeIdValue, CjguiComposableUiShortcut("k"), focusScopeId: alphaScopeValue)) }
        if (betaActionNodeIdValue >= 0 && !betaHidden) { commands.add(CjguiComposableUiCommand("editor.beta.apply", betaActionNodeIdValue, CjguiComposableUiShortcut("k"), focusScopeId: betaScopeValue)) }
        return commands
    }
    public func beginSceneRefresh(): Bool { return components.beginTransaction() }
    public func prepareSceneRefresh(): Bool { return components.prepareTransaction() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return commands() }
    public func commitSceneRefresh(): Unit { components.commitTransaction() }
    public func rollbackSceneRefresh(): Unit { components.rollbackTransaction() }
    public func alphaActionNodeId(): Int64 { return alphaActionNodeIdValue }
    public func betaActionNodeId(): Int64 { return betaActionNodeIdValue }
    public func alphaCount(): Int64 { return alphaApplied }
    public func betaCount(): Int64 { return betaApplied }
    public func liveComponentCount(): Int64 { return components.liveCount() }
    public func hideBeta(): Unit { betaHidden = true; revision += 1 }
    public func showBeta(): Unit { betaHidden = false; revision += 1 }
    public func removeAlpha(): Unit { order = ArrayList<String>(["beta"]); revision += 1 }
    public func restoreAlphaAfterBeta(): Unit { order = ArrayList<String>(["beta", "alpha"]); revision += 1 }
    public func forceUncachedCaption(): Unit { candidateCaptionRevision += 1; revision += 1 }
}

/// Exercises the public participant boundary with real recoverable Cangjie
/// exceptions.  It deliberately opens a new keyed candidate before buildUi
/// throws, then throws again after prepare has closed the candidate.  The
/// normal window must retain the prior accepted scene in both inverse cases.
private class RecoverableExceptionController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let components: CjguiComposableUiComponentRegistry
    private var revision: Int64
    private var includeCandidate: Bool
    private var throwFromBuild: Bool
    private var throwFromPrepare: Bool
    private var throwAfterCommit: Bool
    private var candidateNodeIdValue: Int64
    private var beginCountValue: Int64
    private var prepareCountValue: Int64
    private var rollbackCountValue: Int64
    private var commitCountValue: Int64

    init() {
        this.components = CjguiComposableUiComponentRegistry()
        this.revision = 1
        this.includeCandidate = false
        this.throwFromBuild = false
        this.throwFromPrepare = false
        this.throwAfterCommit = false
        this.candidateNodeIdValue = -1
        this.beginCountValue = 0
        this.prepareCountValue = 0
        this.rollbackCountValue = 0
        this.commitCountValue = 0
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9800, "exception-root", CjguiComposableUiStyle(padding: 8, gap: 4))
        let accepted = components.use("accepted")
        if (accepted.isLive()) {
            root.add(cjguiComposableButton(accepted.nodeId("apply"), accepted.semanticId("apply"), "accepted",
                "ACCEPTED", 80, CjguiComposableUiStyle(fixedHeight: 28)))
        }
        if (includeCandidate) {
            let candidate = components.use("candidate")
            if (candidate.isLive()) {
                candidateNodeIdValue = candidate.nodeId("apply")
                root.add(cjguiComposableButton(candidateNodeIdValue, candidate.semanticId("apply"), "candidate",
                    "CANDIDATE", 81, CjguiComposableUiStyle(fixedHeight: 28)))
            }
        }
        if (throwFromBuild) {
            throw IllegalArgumentException("recoverable_build_exception")
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func beginSceneRefresh(): Bool {
        beginCountValue += 1
        return components.beginTransaction()
    }
    public func prepareSceneRefresh(): Bool {
        prepareCountValue += 1
        if (!components.prepareTransaction()) { return false }
        if (throwFromPrepare) {
            throw IllegalArgumentException("recoverable_prepare_exception")
        }
        return true
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {
        commitCountValue += 1
        components.commitTransaction()
        if (throwAfterCommit) {
            throw IllegalArgumentException("recoverable_accepted_commit_exception")
        }
    }
    public func rollbackSceneRefresh(): Unit {
        rollbackCountValue += 1
        components.rollbackTransaction()
    }

    public func failAfterCandidateBuild(): Unit {
        includeCandidate = true
        throwFromBuild = true
        revision += 1
    }
    public func recoverCandidateBuild(): Unit {
        throwFromBuild = false
        revision += 1
    }
    public func failAfterPrepare(): Unit {
        throwFromPrepare = true
        revision += 1
    }
    public func recoverPrepare(): Unit {
        throwFromPrepare = false
        revision += 1
    }
    public func failAfterAcceptedCommit(): Unit {
        // Force a real scene replacement so the throw is reached only after
        // native present has accepted the staged projection.
        includeCandidate = false
        throwAfterCommit = true
        revision += 1
    }
    public func candidateNodeId(): Int64 { return candidateNodeIdValue }
    public func liveComponentCount(): Int64 { return components.liveCount() }
    public func beginCount(): Int64 { return beginCountValue }
    public func prepareCount(): Int64 { return prepareCountValue }
    public func rollbackCount(): Int64 { return rollbackCountValue }
    public func commitCount(): Int64 { return commitCountValue }
}

/// Exercises the public scoped-composite surface through the ordinary window
/// transaction.  The controller deliberately keeps its business order and
/// action ownership separate from UI identity: scopes identify only the
/// repeated component declaration below this one window.
private class ScopedIdentityController <: CjguiComposableUiController {
    private var order: ArrayList<String>
    private var revision: Int64
    private var includeDuplicateAlpha: Bool
    private var alphaApplyCountValue: Int64
    private var betaApplyCountValue: Int64

    init() {
        this.order = ArrayList<String>(["alpha", "beta"])
        this.revision = 1
        this.includeDuplicateAlpha = false
        this.alphaApplyCountValue = 0
        this.betaApplyCountValue = 0
    }

    public func uiSceneVersion(): Int64 { return revision }

    private func actionRow(key: String, semanticPrefix: String): CjguiComposableUiNode {
        let scope = CjguiComposableUiIdentityScope("window-identity").child("card").child(key)
        let actionSuffix = if (key == "alpha") { "ALPHA" } else { "BETA" }
        let items = ArrayList<CjguiComposableUiActionItem>()
        items.add(CjguiComposableUiActionItem("apply", "apply ${key}", "APPLY_${actionSuffix}",
            if (key == "alpha") { 611 } else { 612 }, CjguiComposableUiStyle(fixedHeight: 28),
            semanticId: "${semanticPrefix}-apply"))
        items.add(CjguiComposableUiActionItem("secondary", "secondary ${key}", "SECONDARY_${actionSuffix}",
            if (key == "alpha") { 613 } else { 614 }, CjguiComposableUiStyle(fixedHeight: 28),
            semanticId: "${semanticPrefix}-secondary"))
        return cjguiComposableScopedActionRow(scope, semanticPrefix, items, CjguiComposableUiStyle(gap: 4))
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9850, "scoped-identity-root", CjguiComposableUiStyle(padding: 8, gap: 4))
        for (key in order) {
            root.add(actionRow(key, "scoped-identity-${key}"))
        }
        if (includeDuplicateAlpha) {
            // This must fail before native staging: it deliberately declares
            // the same scope/local components as the accepted alpha row.
            root.add(actionRow("alpha", "scoped-identity-alpha-duplicate"))
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "APPLY_ALPHA") {
            alphaApplyCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "APPLY_BETA") {
            betaApplyCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
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
    public func reorder(): Unit { order = ArrayList<String>(["beta", "alpha"]); revision += 1 }
    public func removeAlpha(): Unit { order = ArrayList<String>(["beta"]); revision += 1 }
    public func restoreAlpha(): Unit { order = ArrayList<String>(["beta", "alpha"]); revision += 1 }
    public func addDuplicateAlpha(): Unit { includeDuplicateAlpha = true; revision += 1 }
    public func clearDuplicateAlpha(): Unit { includeDuplicateAlpha = false; revision += 1 }
    public func alphaApplyCount(): Int64 { return alphaApplyCountValue }
    public func betaApplyCount(): Int64 { return betaApplyCountValue }
}

/// Deliberately returns the identical declaration instance to two ordinary
/// windows. The second build first consumes a scoped mapping, so an in-place
/// resolver would rewrite the first window's public projection even before
/// that window refreshes. Window-owned candidate snapshots must isolate it.
private class SharedDeclarationController <: CjguiComposableUiController {
    private let scope: CjguiComposableUiIdentityScope
    private let sharedRoot: CjguiComposableUiNode
    private var includePreambleValue: Bool
    private var revision: Int64

    init() {
        this.scope = CjguiComposableUiIdentityScope("shared-declaration")
        this.sharedRoot = CjguiComposableUiNode(-1, "shared-declaration-action", CJGUI_COMPOSABLE_UI_BUTTON,
            "共享动作", "", "APPLY_SHARED", 733, CjguiComposableUiStyle(fixedHeight: 28),
            identity: Some(scope.local("shared-action")))
        this.includePreambleValue = false
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9860, "shared-declaration-wrapper", CjguiComposableUiStyle(gap: 2))
        if (includePreambleValue) {
            root.add(CjguiComposableUiNode(-1, "shared-declaration-preamble", CJGUI_COMPOSABLE_UI_TEXT,
                "前置", "", "", -1, CjguiComposableUiStyle(fixedHeight: 18),
                identity: Some(scope.local("preamble"))))
        }
        root.add(sharedRoot)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(event.eventKind == 27 && event.node.actionName == "APPLY_SHARED")
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func includePreamble(): Unit { includePreambleValue = true; revision += 1 }
}

private func nodeIdForSemanticId(projection: CjguiSharedOperationWindowProjection, semanticId: String): Int64 {
    for (node in projection.nodes) {
        if (node.semanticId == semanticId) { return node.nodeId }
    }
    return -1
}

private func hasRelation(projection: CjguiSharedOperationWindowProjection, sourceId: String, targetId: String): Bool {
    for (relation in projection.relations) {
        if (relation.relation == "CONTAINS" && relation.sourceId == sourceId && relation.targetId == targetId) { return true }
    }
    return false
}

private func enqueue(window: CjguiComposableUiWindow, nodeIndex: UInt32, eventKind: UInt32, text: String): Bool {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_test_enqueue_composable_event(
                window.testSessionToken(), nodeIndex, eventKind, textResource.value
            )
        }
    }
    return status == CJGUI_INTERNAL_RENDERER_OK
}

// Image preparation now completes through MetalKit's asynchronous callback
// and the ordinary AppKit turn pump.  Establish image assertions only after
// that normal continuation has settled; this probe must not make the product
// path synchronous merely to preserve an old instant-load assumption.
private func settleComposableImages(window: CjguiComposableUiWindow, expectedLoaded: UInt32,
    expectedDecodeCount: UInt32): Bool {
    let deadline = MonoTime.now()
    while ((MonoTime.now() - deadline).toMilliseconds() < 800) {
        var loadedTextureCount: UInt32 = 0
        var cacheEntryCount: UInt32 = 0
        var imageDecodeCount: UInt32 = 0
        let imageStatus = unsafe {
            cjgui_internal_renderer_test_composable_image_stats(
                window.testSessionToken(), inout loadedTextureCount, inout cacheEntryCount, inout imageDecodeCount
            )
        }
        if (imageStatus == CJGUI_INTERNAL_RENDERER_OK && loadedTextureCount == expectedLoaded &&
            imageDecodeCount == expectedDecodeCount) {
            println("CJGUI_ASYNC_IMAGE_SETTLED loaded=${loadedTextureCount} cache_entries=${cacheEntryCount} decodes=${imageDecodeCount}")
            return true
        }
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
    }
    var finalLoaded: UInt32 = 0
    var finalCacheEntries: UInt32 = 0
    var finalDecodes: UInt32 = 0
    let finalStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(),
            inout finalLoaded, inout finalCacheEntries, inout finalDecodes)
    }
    let progress = window.windowProgress()
    println("CJGUI_ASYNC_IMAGE_TIMEOUT expected_loaded=${expectedLoaded} expected_decodes=${expectedDecodeCount} " +
        "status=${finalStatus} loaded=${finalLoaded} cache_entries=${finalCacheEntries} decodes=${finalDecodes} " +
        "accepted=${progress.acceptedSceneVersion} pending='${progress.pendingRefreshReason}' " +
        "native_failure='${progress.lastNativeFailure}'")
    return false
}

// The optional multiline natural-height query must obey the same candidate
// rejection boundary as the older four-metric measurement path. Keep this in
// the ordinary window probe so the native failure seam reaches the real
// controller, layout, and accepted-scene transaction.
private class MultilineNaturalHeightFailureController <: CjguiComposableUiController {
    private var value: String
    private var revision: Int64

    init() { this.value = "accepted before measurement\n第二行 😀"; this.revision = 1 }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9900, "natural-height-failure-root",
            CjguiComposableUiStyle(fixedWidth: 320, padding: 8))
        root.add(cjguiComposableMultilineTextInput(9901, "natural-height-failure-field", "",
            value, 9901, CjguiComposableUiStyle(fixedWidth: 280)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind; let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func replace(value: String): Unit { this.value = value; revision += 1 }
}

private func acceptedNaturalHeightValue(window: CjguiComposableUiWindow, value: String): Bool {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "natural-height-failure-field" && node.value == value) { return true }
    }
    return false
}

private func verifyMultilineNaturalHeightFailureRecovery(): Bool {
    let controller = MultilineNaturalHeightFailureController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return false }
    let oldVersion = window.displayedSceneVersion()
    let oldValue = "accepted before measurement\n第二行 😀"
    let newValue = "replacement after measurement failure\n第二行 😀\nthird line wraps at the resolved width"
    controller.replace(newValue)
    let forced = unsafe {
        cjgui_internal_renderer_test_set_composable_measurement_failures(window.testSessionToken(), 1u32)
    }
    let failedRefresh = window.refresh()
    let failedProjection = window.windowProjection()
    let retained = forced == CJGUI_INTERNAL_RENDERER_OK && !failedRefresh &&
        window.nativeStatus() != CJGUI_INTERNAL_RENDERER_OK &&
        window.displayedSceneVersion() == oldVersion &&
        failedProjection.acceptedSceneVersion == oldVersion &&
        failedProjection.lastNativeMeasurementCallCount > 0 &&
        acceptedNaturalHeightValue(window, oldValue)
    let recoveredRefresh = window.refresh()
    let recovered = recoveredRefresh && window.displayedSceneVersion() > oldVersion &&
        acceptedNaturalHeightValue(window, newValue)
    println("CJGUI_MULTILINE_NATURAL_HEIGHT_FAILURE forced=${forced} retained=${retained} " +
        "failed_measure_calls=${failedProjection.lastNativeMeasurementCallCount} recovered=${recovered}")
    window.close()
    return retained && recovered
}

private func focusScopeRemapStable(window: CjguiComposableUiWindow): Bool {
    // The native focus helper alone does not update the Cangjie focus owner.
    // Deliver the matching focus intent so a scoped shortcut is live in both
    // the old scene and the remapped scene.
    var targetIndex: UInt32 = 0u32
    var targetFound = false
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 9406) { targetFound = true; break }
        targetIndex += 1u32
    }
    let nativeFocus = if (targetFound) {
        internalRendererFocusComposableNode(window.testSessionToken(), 9406)
    } else {
        CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    }
    let focusQueued = nativeFocus == CJGUI_INTERNAL_RENDERER_OK &&
        enqueue(window, targetIndex, 31u32, "")
    if (focusQueued) { let _ = window.pump(0u32) }
    let focusedControl = window.windowProgress().focusedControlId
    println("CJGUI_SCOPE_REMAP_FOCUS scene=${window.displayedSceneVersion()} target_index=${targetIndex} " +
        "native=${nativeFocus} queued=${focusQueued} focused='${focusedControl}'")
    return targetFound && focusQueued && focusedControl == "scope-remap-stable"
}

main(args: Array<String>): Int64 {
    if (args.size == 1 && args[0] == "--natural-height-failure-only") {
        return if (verifyMultilineNaturalHeightFailureRecovery()) { 0 } else { 162 }
    }
    if (args.size != 0) { return 2 }
    if (!verifyMultilineNaturalHeightFailureRecovery()) { return 162 }
    let controller = NativeEventController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 3 }
    if (!settleComposableImages(window, 2u32, 1u32)) { window.close(); return 161 }
    // A read-only refresh must not create a different native scene when both
    // the viewport and controller output are unchanged.  Otherwise every
    // external GET would invalidate queued input and submit a new frame.
    let initialSceneVersion = window.displayedSceneVersion()
    let initialProgress = window.windowProjection()
    var initialMeasurementCount: UInt32 = 0
    let initialMeasurementStatus = unsafe {
        cjgui_internal_renderer_test_composable_measurement_count(window.testSessionToken(), inout initialMeasurementCount)
    }
    if (initialMeasurementStatus != CJGUI_INTERNAL_RENDERER_OK || initialMeasurementCount == 0u32) { window.close(); return 17 }
    // Session identity is observable transport context, never a native
    // capability.  It nevertheless must distinguish simultaneous windows
    // and a reopened instance, rather than restarting at `_1` per object.
    if (initialProgress.sessionIdentity == "cjgui_window_1" || initialProgress.acceptedSceneVersion != initialSceneVersion ||
        initialProgress.submittedSceneVersion != initialSceneVersion || initialProgress.submittedFrameIndex <= 0 ||
        initialProgress.observedMetalCompletionFrameIndex <= 0 || initialProgress.presentationState != "unavailable" ||
        initialProgress.pendingRefreshReason != "none" || initialProgress.buildPassCount != 2 ||
        initialProgress.layoutPassCount != 2 || initialProgress.nativeSubmissionCount != 2) { window.close(); return 39 }
    var initialCommittedNodeCount: UInt32 = 0
    var initialNativeNodeUpdateCount: UInt64 = 0
    let initialNativeUpdateStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_update_stats(
            window.testSessionToken(), inout initialCommittedNodeCount, inout initialNativeNodeUpdateCount
        )
    }
    println("CJGUI_NATIVE_NODE_UPDATES initial_nodes=${initialCommittedNodeCount} initial_updates=${initialNativeNodeUpdateCount}")
    if (initialNativeUpdateStatus != CJGUI_INTERNAL_RENDERER_OK || initialCommittedNodeCount < 6u32 ||
        initialNativeNodeUpdateCount != UInt64(initialCommittedNodeCount) + 2u64) { window.close(); return 89 }
    if (!window.refreshIfNeeded() || window.displayedSceneVersion() != initialSceneVersion) { window.close(); return 8 }
    let idleProgress = window.windowProjection()
    if (idleProgress.buildPassCount != initialProgress.buildPassCount || idleProgress.layoutPassCount != initialProgress.layoutPassCount ||
        idleProgress.nativeSubmissionCount != initialProgress.nativeSubmissionCount || idleProgress.submittedFrameIndex != initialProgress.submittedFrameIndex) {
        window.close(); return 40
    }
    // An idle ordinary application turn delegates its remaining time to the
    // native bounded event wait. A Metal/AppKit completion event is allowed
    // to wake that wait early; a second application-level 16 ms sleep would
    // instead push it beyond the single-wait upper bound even when no refresh
    // is needed.
    let idleTurnStarted = MonoTime.now()
    let idleTurn = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 16u32)
    let idleTurnElapsedMs = (MonoTime.now() - idleTurnStarted).toMilliseconds()
    let afterIdleTurn = window.windowProjection()
    if (idleTurn.externalActionCount != 0 || idleTurn.eventWaitBudgetMs != 16u32 ||
        idleTurnElapsedMs > 80 ||
        afterIdleTurn.buildPassCount != idleProgress.buildPassCount ||
        afterIdleTurn.layoutPassCount != idleProgress.layoutPassCount ||
        afterIdleTurn.nativeSubmissionCount != idleProgress.nativeSubmissionCount) {
        window.close(); return 74
    }
    // This goes through the same scheduler entry that a normal application
    // uses.  A FIFO interaction already owned by the native side must reach
    // Cangjie promptly; it must not first consume an otherwise-idle 16 ms
    // AppKit acquisition interval.  A selection is production input but does
    // not make this latency regression depend on a later scene rebuild.
    if (!enqueue(window, 2u32, 33u32, "")) { window.close(); return 75 }
    let queuedTurnStarted = MonoTime.now()
    let queuedTurn = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 16u32)
    let queuedTurnElapsedMs = (MonoTime.now() - queuedTurnStarted).toMilliseconds()
    let afterQueuedTurn = window.windowProjection()
    if (!queuedTurn.windowPumpResult.didApplyHumanAction || !controller.didObserveSelection() || queuedTurnElapsedMs >= 8 ||
        afterQueuedTurn.buildPassCount != afterIdleTurn.buildPassCount ||
        afterQueuedTurn.layoutPassCount != afterIdleTurn.layoutPassCount ||
        afterQueuedTurn.nativeSubmissionCount != afterIdleTurn.nativeSubmissionCount ||
        afterQueuedTurn.submittedFrameIndex != afterIdleTurn.submittedFrameIndex) {
        window.close(); return 76
    }
    // Selection is platform-originated but a document consumer needs one
    // explicit callback to translate its UTF-16 range into document bytes.
    // It must not masquerade as an external action.
    let beforeSelectionProgress = window.windowProjection()
    if (!enqueue(window, 2u32, 33u32, "")) { window.close(); return 37 }
    let selected = window.pump(0u32)
    if (!selected.didApplyHumanAction || !controller.didObserveSelection()) { window.close(); return 38 }
    let afterSelectionProgress = window.windowProjection()
    if (afterSelectionProgress.buildPassCount != beforeSelectionProgress.buildPassCount ||
        afterSelectionProgress.layoutPassCount != beforeSelectionProgress.layoutPassCount ||
        afterSelectionProgress.nativeSubmissionCount != beforeSelectionProgress.nativeSubmissionCount) {
        window.close(); return 43
    }
    var refreshedMeasurementCount: UInt32 = 0
    let refreshedMeasurementStatus = unsafe {
        cjgui_internal_renderer_test_composable_measurement_count(window.testSessionToken(), inout refreshedMeasurementCount)
    }
    if (refreshedMeasurementStatus != CJGUI_INTERNAL_RENDERER_OK || refreshedMeasurementCount != initialMeasurementCount) {
        window.close(); return 18
    }
    // A native shaping failure is never published using fallback geometry.
    // The old scene remains interactive, and the next healthy refresh retries
    // the cache miss through the ordinary production measurement path.
    controller.changeCaption("uncached failure boundary")
    let forceMeasurementFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_measurement_failures(window.testSessionToken(), 1u32)
    }
    if (forceMeasurementFailure != CJGUI_INTERNAL_RENDERER_OK) { window.close(); return 19 }
    if (window.refresh() || window.nativeStatus() == CJGUI_INTERNAL_RENDERER_OK ||
        window.displayedSceneVersion() != initialSceneVersion || !window.isOpen()) { window.close(); return 20 }
    let failedProgress = window.windowProjection()
    if (failedProgress.pendingRefreshReason != "refresh_internal_error" || failedProgress.lastNativeFailure != "internal_error" ||
        failedProgress.acceptedSceneVersion != initialSceneVersion) { window.close(); return 41 }
    // A failed v2 measurement is a retained pending attempt, not a stale v1
    // signal that the idle loop may immediately attempt again. Repeated
    // no-change refreshes must neither consume the controlled next success nor
    // add build/layout/submission work.
    if (window.refreshIfNeeded()) { window.close(); return 44 }
    let idleAfterFailure = window.windowProjection()
    if (idleAfterFailure.pendingRefreshReason != "refresh_internal_error" ||
        idleAfterFailure.buildPassCount != failedProgress.buildPassCount ||
        idleAfterFailure.layoutPassCount != failedProgress.layoutPassCount ||
        idleAfterFailure.nativeSubmissionCount != failedProgress.nativeSubmissionCount ||
        window.displayedSceneVersion() != initialSceneVersion) { window.close(); return 45 }
    if (!window.refresh() || window.displayedSceneVersion() <= initialSceneVersion) { window.close(); return 21 }
    let recoveredProgress = window.windowProjection()
    if (recoveredProgress.pendingRefreshReason != "none" || recoveredProgress.lastNativeFailure != "none" ||
        recoveredProgress.acceptedSceneVersion != window.displayedSceneVersion()) { window.close(); return 42 }
    // A caption change crosses the real Cangjie/native scene submission but
    // must not repeatedly stringify/rebind its unchanged input, action, and
    // image nodes. The staged generation copies their immutable native data;
    // exactly the caption becomes one node update.
    var recoveredCommittedNodeCount: UInt32 = 0
    var recoveredNativeNodeUpdateCount: UInt64 = 0
    let recoveredNativeUpdateStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_update_stats(
            window.testSessionToken(), inout recoveredCommittedNodeCount, inout recoveredNativeNodeUpdateCount
        )
    }
    println("CJGUI_NATIVE_NODE_UPDATES recovered_nodes=${recoveredCommittedNodeCount} recovered_updates=${recoveredNativeNodeUpdateCount}")
    if (recoveredNativeUpdateStatus != CJGUI_INTERNAL_RENDERER_OK || recoveredCommittedNodeCount != initialCommittedNodeCount ||
        recoveredNativeNodeUpdateCount != initialNativeNodeUpdateCount + 1u64) { window.close(); return 90 }
    // The recovery refresh submitted a normal frame after the first-frame
    // readback.  Completion must subsequently advance through the reusable
    // progress projection without another readback or a synchronous GPU wait.
    var completedProgress = recoveredProgress
    let completionDeadline = MonoTime.now()
    while (completedProgress.observedMetalCompletionFrameIndex < completedProgress.submittedFrameIndex &&
        (MonoTime.now() - completionDeadline).toMilliseconds() < 240) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        completedProgress = window.windowProjection()
    }
    if (completedProgress.observedMetalCompletionFrameIndex < completedProgress.submittedFrameIndex ||
        completedProgress.observedMetalFailureFrameIndex >= completedProgress.submittedFrameIndex ||
        completedProgress.observedMetalGpuDurationMicros < -1) { window.close(); return 77 }
    // A real AppKit resize is a distinct refresh condition. If its first
    // measurement fails, the next idle check must retain that failure rather
    // than retrying the identical resize forever.
    var resizeRevision: UInt64 = 0
    let resizeStatus = unsafe {
        cjgui_internal_renderer_test_resize_composable_window(window.testSessionToken(), inout resizeRevision)
    }
    if (resizeStatus != CJGUI_INTERNAL_RENDERER_OK || resizeRevision == 0u64) { window.close(); return 46 }
    let beforeResizeFailure = window.windowProjection()
    let forceResizeMeasurementFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_measurement_failures(window.testSessionToken(), 1u32)
    }
    if (forceResizeMeasurementFailure != CJGUI_INTERNAL_RENDERER_OK || window.refreshIfNeeded() ||
        window.nativeStatus() == CJGUI_INTERNAL_RENDERER_OK || window.displayedSceneVersion() != recoveredProgress.acceptedSceneVersion) {
        window.close(); return 47
    }
    let failedResizeProgress = window.windowProjection()
    if (failedResizeProgress.pendingRefreshReason != "refresh_internal_error" ||
        failedResizeProgress.buildPassCount != beforeResizeFailure.buildPassCount + 1 ||
        failedResizeProgress.layoutPassCount != beforeResizeFailure.layoutPassCount + 1) { window.close(); return 48 }
    if (window.refreshIfNeeded()) { window.close(); return 49 }
    let idleAfterResizeFailure = window.windowProjection()
    if (idleAfterResizeFailure.buildPassCount != failedResizeProgress.buildPassCount ||
        idleAfterResizeFailure.layoutPassCount != failedResizeProgress.layoutPassCount ||
        idleAfterResizeFailure.nativeSubmissionCount != failedResizeProgress.nativeSubmissionCount) { window.close(); return 50 }
    if (!window.refresh() || window.displayedSceneVersion() <= recoveredProgress.acceptedSceneVersion) { window.close(); return 51 }
    var beforeFontMeasurementCount: UInt32 = 0
    let beforeFontMeasurementStatus = unsafe {
        cjgui_internal_renderer_test_composable_measurement_count(window.testSessionToken(), inout beforeFontMeasurementCount)
    }
    if (beforeFontMeasurementStatus != CJGUI_INTERNAL_RENDERER_OK || beforeFontMeasurementCount == 0u32) { window.close(); return 78 }
    controller.useLargeCaptionFont()
    if (!window.refresh()) { window.close(); return 79 }
    var afterFontMeasurementCount: UInt32 = 0
    let afterFontMeasurementStatus = unsafe {
        cjgui_internal_renderer_test_composable_measurement_count(window.testSessionToken(), inout afterFontMeasurementCount)
    }
    if (afterFontMeasurementStatus != CJGUI_INTERNAL_RENDERER_OK || afterFontMeasurementCount <= beforeFontMeasurementCount) {
        window.close(); return 80
    }
    println("CJGUI_APPKIT_MEASUREMENT_COUNT before_font=${beforeFontMeasurementCount} after_font=${afterFontMeasurementCount}")
    let hierarchyController = HierarchyOnlyController()
    let hierarchyWindow = CjguiComposableUiWindow(hierarchyController)
    if (!hierarchyWindow.start()) { window.close(); return 22 }
    let hierarchyBeforeVersion = hierarchyWindow.displayedSceneVersion()
    var nativeHierarchyBefore: UInt64 = 0
    let nativeHierarchyBeforeStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_version(hierarchyWindow.testSessionToken(), inout nativeHierarchyBefore)
    }
    if (nativeHierarchyBeforeStatus != CJGUI_INTERNAL_RENDERER_OK || nativeHierarchyBefore == 0u64) { hierarchyWindow.close(); window.close(); return 23 }
    hierarchyController.nestAction()
    if (!hierarchyWindow.refresh() || hierarchyWindow.displayedSceneVersion() <= hierarchyBeforeVersion) { hierarchyWindow.close(); window.close(); return 24 }
    var nativeHierarchyAfter: UInt64 = 0
    let nativeHierarchyAfterStatus = unsafe {
        cjgui_internal_renderer_test_composable_scene_version(hierarchyWindow.testSessionToken(), inout nativeHierarchyAfter)
    }
    let hierarchyProjection = hierarchyWindow.windowProjection()
    if (nativeHierarchyAfterStatus != CJGUI_INTERNAL_RENDERER_OK || nativeHierarchyAfter != nativeHierarchyBefore ||
        hierarchyProjection.sessionIdentity == initialProgress.sessionIdentity ||
        !hasRelation(hierarchyProjection, "hierarchy-group", "hierarchy-action") ||
        hasRelation(hierarchyProjection, "hierarchy-outer", "hierarchy-action")) { hierarchyWindow.close(); window.close(); return 25 }
    // Reparenting a visually-neutral group changed the external semantic tree,
    // not the last native input snapshot. A native event from that unchanged
    // snapshot must still reach the stable action.
    if (!enqueue(hierarchyWindow, 3u32, 27u32, "")) { hierarchyWindow.close(); window.close(); return 32 }
    let hierarchyApplied = hierarchyWindow.pump(0u32)
    if (!hierarchyApplied.didApplyHumanAction || !hierarchyController.didApplyStableAction() ||
        hierarchyController.didRejectStableAction()) { hierarchyWindow.close(); window.close(); return 33 }
    // A queued intent whose target was removed before the next pump remains
    // stale. The input snapshot may not turn that old node ID into a live
    // target merely because a semantic-only revision was accepted earlier.
    if (!enqueue(hierarchyWindow, 3u32, 27u32, "")) { hierarchyWindow.close(); window.close(); return 34 }
    hierarchyController.removeAction()
    if (!hierarchyWindow.refresh()) { hierarchyWindow.close(); window.close(); return 35 }
    let hierarchyRejected = hierarchyWindow.pump(0u32)
    if (hierarchyRejected.didApplyHumanAction || !hierarchyController.didRejectStableAction()) {
        hierarchyWindow.close(); window.close(); return 36
    }
    hierarchyWindow.close()
    // Reopening retains no native session capability, but publishes a fresh
    // logical session identity so an old wait cannot mistake it for the prior
    // endpoint window.
    if (!hierarchyWindow.start()) { window.close(); return 46 }
    let reopenedProjection = hierarchyWindow.windowProjection()
    if (reopenedProjection.sessionIdentity == hierarchyProjection.sessionIdentity ||
        reopenedProjection.sessionIdentity == initialProgress.sessionIdentity) {
        hierarchyWindow.close(); window.close(); return 47
    }
    hierarchyWindow.close()
    // A public participant may change only containment/command context, so
    // native input and Metal correctly stay on the old scene. Its Cangjie
    // candidate is nevertheless already being accepted before commit. A
    // commit exception must not invoke rollback after that boundary.
    let sameSceneExceptionController = SameSceneParticipantExceptionController()
    let sameSceneExceptionWindow = CjguiComposableUiWindow(sameSceneExceptionController)
    if (!sameSceneExceptionWindow.start() || sameSceneExceptionController.commitCount() != 1) {
        sameSceneExceptionWindow.close(); window.close(); return 155
    }
    let sameSceneDisplayedVersion = sameSceneExceptionWindow.displayedSceneVersion()
    sameSceneExceptionController.reparentThenThrowAfterCommit()
    let sameSceneExceptionRefresh = sameSceneExceptionWindow.refresh()
    println("CJGUI_PARTICIPANT_SAME_SCENE_COMMIT_EXCEPTION refresh=${sameSceneExceptionRefresh} open=${sameSceneExceptionWindow.isOpen()} displayed_scene=${sameSceneExceptionWindow.displayedSceneVersion()} prior_displayed_scene=${sameSceneDisplayedVersion} rollbacks=${sameSceneExceptionController.rollbackCount()} commits=${sameSceneExceptionController.commitCount()}")
    if (sameSceneExceptionRefresh || sameSceneExceptionWindow.isOpen() ||
        sameSceneExceptionWindow.displayedSceneVersion() != sameSceneDisplayedVersion + 1 ||
        sameSceneExceptionController.rollbackCount() != 0 || sameSceneExceptionController.commitCount() != 2) {
        sameSceneExceptionWindow.close(); window.close(); return 156
    }
    sameSceneExceptionWindow.close()
    // The normal native mouse target path must resolve the modal backdrop
    // above a visually identical base action.  It may close the layer, but
    // it must never dispatch that base action through the Cangjie controller.
    let layerController = LayerInputController()
    let layerWindow = CjguiComposableUiWindow(layerController)
    if (!layerWindow.start()) { window.close(); return 52 }
    // A top-level anchored menu is not modal, but the normal mouse path must
    // still enter its declared input scope.  This mirrors the visible rule
    // editor menu: without that focus transition, Tab walks base controls and
    // Escape never reaches the controller's layer-dismissal event.
    let topMenuPressStatus = unsafe {
        cjgui_internal_renderer_test_press_composable_node(layerWindow.testSessionToken(), 4u32)
    }
    let topMenuOpened = layerWindow.pump(0u32)
    if (topMenuPressStatus != CJGUI_INTERNAL_RENDERER_OK || !topMenuOpened.didApplyHumanAction ||
        !layerController.isTopMenuOpen()) {
        layerWindow.close(); window.close(); return 70
    }
    // This conflict is checked only after the candidate command and its
    // target have been accepted. Before opening the menu, neither exists and
    // the public fail-closed declaration rule must reject the pre-registration.
    if (layerWindow.declareCommand(CjguiComposableUiCommand(
        "layer.conflicting-shortcut", 9012, CjguiComposableUiShortcut("k"),
        focusScopeId: "layer-input-top-menu"
    ))) { layerWindow.close(); window.close(); return 106 }
    // The native path only normalizes Cmd-K. Cangjie resolves the declared
    // shortcut and focused menu scope to the same controller action that an
    // AX/menu press uses; the conflicting declaration above was rejected.
    var topMenuCommandFocus: UInt64 = 0u64
    let topMenuCommandStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 40u16, 1048576u64, inout topMenuCommandFocus)
    }
    let topMenuCommandPumped = layerWindow.pump(0u32)
    if (topMenuCommandStatus != CJGUI_INTERNAL_RENDERER_OK || topMenuCommandFocus != 9012u64 ||
        !topMenuCommandPumped.didApplyHumanAction || !layerController.didApplyTopMenuAction()) {
        layerWindow.close(); window.close(); return 107
    }
    var layerPendingInteractions: UInt32 = 0
    var layerMaxPendingInteractions: UInt32 = 0
    var layerAccessibilityNotifications: UInt64 = 0u64
    let layerInteractionStats = unsafe {
        cjgui_internal_renderer_test_composable_interaction_stats(
            layerWindow.testSessionToken(), inout layerPendingInteractions, inout layerMaxPendingInteractions,
            inout layerAccessibilityNotifications
        )
    }
    if (layerInteractionStats != CJGUI_INTERNAL_RENDERER_OK || layerPendingInteractions != 0u32 ||
        layerMaxPendingInteractions == 0u32 || layerAccessibilityNotifications == 0u64) {
        layerWindow.close(); window.close(); return 112
    }
    println("CJGUI_INTERACTION_COST_SAMPLE samples=1 warm_after_start=true idle_wait_ms=${idleTurnElapsedMs} queued_turn_ms=${queuedTurnElapsedMs} build_delta=${afterQueuedTurn.buildPassCount - initialProgress.buildPassCount} layout_delta=${afterQueuedTurn.layoutPassCount - initialProgress.layoutPassCount} submit_delta=${afterQueuedTurn.nativeSubmissionCount - initialProgress.nativeSubmissionCount} layer_queue_pending=${layerPendingInteractions} layer_queue_high_water=${layerMaxPendingInteractions} layer_ax_notifications=${layerAccessibilityNotifications}")
    if (!layerWindow.invokeCommand("layer.top-menu-action")) { layerWindow.close(); window.close(); return 108 }
    var topMenuFocused: UInt64 = 0u64
    let topMenuTabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 48u16, 0u64, inout topMenuFocused)
    }
    let topMenuTabPumped = layerWindow.pump(0u32)
    if (topMenuTabStatus != CJGUI_INTERNAL_RENDERER_OK || topMenuFocused != 9012u64 ||
        topMenuTabPumped.didApplyHumanAction || !layerController.isTopMenuOpen()) {
        layerWindow.close(); window.close(); return 71
    }
    var topMenuEscapeFocused: UInt64 = 0u64
    let topMenuEscapeStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 53u16, 0u64, inout topMenuEscapeFocused)
    }
    let topMenuDismissed = layerWindow.pump(0u32)
    if (topMenuEscapeStatus != CJGUI_INTERNAL_RENDERER_OK || topMenuEscapeFocused != 9012u64 ||
        !topMenuDismissed.didApplyHumanAction || layerController.isTopMenuOpen()) {
        layerWindow.close(); window.close(); return 72
    }
    if (layerWindow.invokeCommand("layer.top-menu-action")) {
        layerWindow.close(); window.close(); return 157
    }
    var topMenuRestoredFocused: UInt64 = 0u64
    let topMenuRestoreStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 1u16, 0u64, inout topMenuRestoredFocused)
    }
    if (topMenuRestoreStatus != CJGUI_INTERNAL_RENDERER_OK || topMenuRestoredFocused != 9010u64) {
        layerWindow.close(); window.close(); return 73
    }
    if (!enqueue(layerWindow, 2u32, 27u32, "")) { layerWindow.close(); window.close(); return 53 }
    let dialogOpenedForOutside = layerWindow.pump(0u32)
    if (!dialogOpenedForOutside.didApplyHumanAction || !layerController.isDialogOpen()) {
        layerWindow.close(); window.close(); return 54
    }
    let outsideStatus = unsafe {
        cjgui_internal_renderer_test_click_composable_point(layerWindow.testSessionToken(), 4.0f32, 4.0f32)
    }
    let outsideDismissed = layerWindow.pump(0u32)
    if (outsideStatus != CJGUI_INTERNAL_RENDERER_OK || !outsideDismissed.didApplyHumanAction ||
        layerController.isDialogOpen() || layerController.didActivateBackground()) {
        layerWindow.close(); window.close(); return 55
    }
    // Reopen through the ordinary action and drive AppKit's real key path.
    // The first Tab starts from the dialog's Cangjie-declared input and must
    // remain inside that layer rather than moving to the background button.
    if (!enqueue(layerWindow, 2u32, 27u32, "")) { layerWindow.close(); window.close(); return 56 }
    let dialogOpened = layerWindow.pump(0u32)
    if (!dialogOpened.didApplyHumanAction || !layerController.isDialogOpen()) { layerWindow.close(); window.close(); return 57 }
    // Capture Escape, then let the ordinary Cangjie owner remove the dialog
    // before the FIFO is drained. The queued native event belongs to the old
    // scene and must be rejected, never retargeted to any successor layer.
    var staleEscapeFocused: UInt64 = 0u64
    let staleEscapeStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 53u16, 0u64, inout staleEscapeFocused)
    }
    layerController.closeForStaleEscapeRegression()
    if (!layerWindow.refresh()) { layerWindow.close(); window.close(); return 130 }
    let staleEscapePumped = layerWindow.pump(0u32)
    if (staleEscapeStatus != CJGUI_INTERNAL_RENDERER_OK || staleEscapeFocused != 9005u64 ||
        staleEscapePumped.didApplyHumanAction || layerController.isDialogOpen()) {
        layerWindow.close(); window.close(); return 131
    }
    if (!enqueue(layerWindow, 2u32, 27u32, "") || !layerWindow.pump(0u32).didApplyHumanAction ||
        !layerController.isDialogOpen()) { layerWindow.close(); window.close(); return 132 }
    var dialogFocused: UInt64 = 0u64
    let tabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 48u16, 0u64, inout dialogFocused)
    }
    let tabPumped = layerWindow.pump(0u32)
    if (tabStatus != CJGUI_INTERNAL_RENDERER_OK || dialogFocused != 9006u64 ||
        tabPumped.didApplyHumanAction || !layerController.isDialogOpen()) {
        layerWindow.close(); window.close(); return 58
    }
    // Escape is delivered from the focused dialog control as generic layer
    // dismissal. After the controller removes the modal, focus must restore
    // to the live opener, not stay on a removed node.
    var escapeFocused: UInt64 = 0u64
    let escapeStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 53u16, 0u64, inout escapeFocused)
    }
    let escapePumped = layerWindow.pump(0u32)
    if (escapeStatus != CJGUI_INTERNAL_RENDERER_OK || escapeFocused != 9006u64 ||
        !escapePumped.didApplyHumanAction || layerController.isDialogOpen()) {
        layerWindow.close(); window.close(); return 59
    }
    var restoredFocused: UInt64 = 0u64
    let restoredStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 1u16, 0u64, inout restoredFocused)
    }
    if (restoredStatus != CJGUI_INTERNAL_RENDERER_OK || restoredFocused != 9002u64) { layerWindow.close(); window.close(); return 60 }
    // A menu may live above a dialog but is still an ordinary anchored layer.
    // Its own scope traps Tab, and closing it restores its declared anchor in
    // the still-open dialog before that dialog later closes.
    if (!enqueue(layerWindow, 2u32, 27u32, "")) { layerWindow.close(); window.close(); return 61 }
    if (!layerWindow.pump(0u32).didApplyHumanAction) { layerWindow.close(); window.close(); return 62 }
    dialogFocused = 0u64
    let focusMoreStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 48u16, 0u64, inout dialogFocused)
    }
    let _ = layerWindow.pump(0u32)
    if (focusMoreStatus != CJGUI_INTERNAL_RENDERER_OK || dialogFocused != 9006u64) { layerWindow.close(); window.close(); return 63 }
    var openMenuFocused: UInt64 = 0u64
    let openMenuStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 36u16, 0u64, inout openMenuFocused)
    }
    let menuOpened = layerWindow.pump(0u32)
    if (openMenuStatus != CJGUI_INTERNAL_RENDERER_OK || openMenuFocused != 9006u64 ||
        !menuOpened.didApplyHumanAction || !layerController.isDialogMenuOpen()) {
        layerWindow.close(); window.close(); return 64
    }
    if (internalRendererFocusComposableNode(layerWindow.testSessionToken(), 9009) != CJGUI_INTERNAL_RENDERER_OK) {
        layerWindow.close(); window.close(); return 65
    }
    var menuFocused: UInt64 = 0u64
    let menuTabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 48u16, 0u64, inout menuFocused)
    }
    let _ = layerWindow.pump(0u32)
    if (menuTabStatus != CJGUI_INTERNAL_RENDERER_OK || menuFocused != 9009u64) { layerWindow.close(); window.close(); return 66 }
    let menuEscapeStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 53u16, 0u64, inout menuFocused)
    }
    let menuDismissed = layerWindow.pump(0u32)
    if (menuEscapeStatus != CJGUI_INTERNAL_RENDERER_OK || !menuDismissed.didApplyHumanAction ||
        !layerController.isDialogOpen() || layerController.isDialogMenuOpen()) {
        layerWindow.close(); window.close(); return 67
    }
    restoredFocused = 0u64
    let menuRestoreStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 1u16, 0u64, inout restoredFocused)
    }
    if (menuRestoreStatus != CJGUI_INTERNAL_RENDERER_OK || restoredFocused != 9006u64) { layerWindow.close(); window.close(); return 68 }
    let finalEscapeStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(layerWindow.testSessionToken(), 53u16, 0u64, inout restoredFocused)
    }
    let finalDismissed = layerWindow.pump(0u32)
    if (finalEscapeStatus != CJGUI_INTERNAL_RENDERER_OK || !finalDismissed.didApplyHumanAction || layerController.isDialogOpen()) {
        var tracePending: UInt32 = 0; var traceEnqueuedKind: UInt32 = 0; var traceEnqueuedNode: UInt64 = 0u64
        var traceEnqueuedScene: UInt64 = 0u64; var tracePumpedKind: UInt32 = 0; var tracePumpedNode: UInt64 = 0u64
        var tracePumpedScene: UInt64 = 0u64
        let traceStatus = unsafe {
            cjgui_internal_renderer_test_composable_interaction_trace(layerWindow.testSessionToken(), inout tracePending,
                inout traceEnqueuedKind, inout traceEnqueuedNode, inout traceEnqueuedScene, inout tracePumpedKind,
                inout tracePumpedNode, inout tracePumpedScene)
        }
        let progress = layerWindow.windowProgress()
        println("CJGUI_ESCAPE_69_TRACE status=${finalEscapeStatus};pump_status=${finalDismissed.nativeStatus};pump_budget_ms=0;did_apply=${finalDismissed.didApplyHumanAction};controller_dialog=${layerController.isDialogOpen()};accepted_scene=${progress.acceptedSceneVersion};submitted_scene=${progress.submittedSceneVersion};focus=${progress.focusedControlId};active_layer=${progress.activeLayerId};native_trace_status=${traceStatus};pending=${tracePending};enqueued_kind=${traceEnqueuedKind};enqueued_node=${traceEnqueuedNode};enqueued_scene=${traceEnqueuedScene};pumped_kind=${tracePumpedKind};pumped_node=${tracePumpedNode};pumped_scene=${tracePumpedScene}")
        layerWindow.close(); window.close(); return 69
    }
    layerWindow.close()
    // Regression: the target layer remains at the same native indexes while
    // an earlier transient layer becomes ordinary content.  The changed target
    // sibling receives the target scope's *new* compact code; a retained
    // stable node must be refreshed to that same code before real Tab walks.
    let scopeRemapController = ScopeRemapController()
    let scopeRemapWindow = CjguiComposableUiWindow(scopeRemapController)
    if (!scopeRemapWindow.start()) { window.close(); return 91 }
    // A layer target may only bind a command in that layer's input scope.
    // The old unscoped declaration reached this point and failed at exit109;
    // retain that failure as an explicit negative control.
    let unscopedRemapCommand = CjguiComposableUiCommand(
        "scope-remap.invalid-empty-scope", 9406, CjguiComposableUiShortcut("k")
    )
    let scopedRemapCommand = CjguiComposableUiCommand(
        "scope-remap.stable", 9406, CjguiComposableUiShortcut("k"),
        focusScopeId: "scope-remap-target"
    )
    var remapTargetDeclared = false
    for (node in scopeRemapWindow.acceptedSceneNodes()) {
        if (node.nodeId == 9406) {
            remapTargetDeclared = node.actionName == "STABLE_SCOPE" &&
                node.inputScopeId == scopedRemapCommand.focusScopeId &&
                unscopedRemapCommand.focusScopeId == ""
            println("CJGUI_SCOPE_REMAP_DECLARATION target=${node.nodeId} action='${node.actionName}' " +
                "input_scope='${node.inputScopeId}' invalid_scope='${unscopedRemapCommand.focusScopeId}' " +
                "command_scope='${scopedRemapCommand.focusScopeId}' " +
                "scene=${scopeRemapWindow.displayedSceneVersion()}")
        }
    }
    let invalidScopeRejected = !scopeRemapWindow.declareCommand(unscopedRemapCommand)
    let validScopeRegistered = scopeRemapWindow.declareCommand(scopedRemapCommand)
    println("CJGUI_SCOPE_REMAP_REGISTRATION target_declared=${remapTargetDeclared} " +
        "invalid_rejected=${invalidScopeRejected} valid_registered=${validScopeRegistered}")
    if (!remapTargetDeclared || !invalidScopeRejected || !validScopeRegistered) {
        scopeRemapWindow.close(); window.close(); return 109
    }
    if (!focusScopeRemapStable(scopeRemapWindow)) {
        scopeRemapWindow.close(); window.close(); return 93
    }
    // Queue a normalized key from the old native scene, then accept a new
    // Cangjie projection before draining it. A shortcut cannot be rebound to
    // the current target merely because its declaration string still exists.
    let queuedRemapScene = scopeRemapWindow.displayedSceneVersion()
    if (!enqueue(scopeRemapWindow, 0u32, 34u32, "shortcut:command+k")) {
        scopeRemapWindow.close(); window.close(); return 110
    }
    scopeRemapController.removePrefixScope()
    if (!scopeRemapWindow.refresh()) { scopeRemapWindow.close(); window.close(); return 92 }
    let acceptedRemapScene = scopeRemapWindow.displayedSceneVersion()
    let staleShortcutPump = scopeRemapWindow.pump(0u32)
    let staleShortcutRejected = acceptedRemapScene > queuedRemapScene &&
        !staleShortcutPump.didApplyHumanAction &&
        !scopeRemapController.didApplyStableAction()
    println("CJGUI_SCOPE_REMAP_STALE queued_scene=${queuedRemapScene} accepted_scene=${acceptedRemapScene} " +
        "rejected=${staleShortcutRejected}")
    if (!staleShortcutRejected) {
        scopeRemapWindow.close(); window.close(); return 111
    }
    if (!focusScopeRemapStable(scopeRemapWindow)) {
        scopeRemapWindow.close(); window.close(); return 93
    }
    var freshShortcutFocused: UInt64 = 0u64
    let freshShortcutStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(
            scopeRemapWindow.testSessionToken(), 40u16, 1048576u64, inout freshShortcutFocused
        )
    }
    let freshShortcutPump = scopeRemapWindow.pump(0u32)
    let freshShortcutApplied = freshShortcutStatus == CJGUI_INTERNAL_RENDERER_OK &&
        freshShortcutFocused == 9406u64 && freshShortcutPump.didApplyHumanAction &&
        scopeRemapController.didApplyStableAction()
    var remapPending: UInt32 = 0
    var remapEnqueuedKind: UInt32 = 0
    var remapEnqueuedNode: UInt64 = 0u64
    var remapEnqueuedScene: UInt64 = 0u64
    var remapPumpedKind: UInt32 = 0
    var remapPumpedNode: UInt64 = 0u64
    var remapPumpedScene: UInt64 = 0u64
    let remapTraceStatus = unsafe {
        cjgui_internal_renderer_test_composable_interaction_trace(scopeRemapWindow.testSessionToken(),
            inout remapPending, inout remapEnqueuedKind, inout remapEnqueuedNode, inout remapEnqueuedScene,
            inout remapPumpedKind, inout remapPumpedNode, inout remapPumpedScene)
    }
    println("CJGUI_SCOPE_REMAP_SHORTCUT stale_rejected=${staleShortcutRejected} " +
        "fresh_status=${freshShortcutStatus} fresh_focused=${freshShortcutFocused} " +
        "fresh_applied=${freshShortcutApplied} pump_applied=${freshShortcutPump.didApplyHumanAction} " +
        "controller_applied=${scopeRemapController.didApplyStableAction()} trace_status=${remapTraceStatus} " +
        "pending=${remapPending} enqueued=${remapEnqueuedKind}/${remapEnqueuedNode}/${remapEnqueuedScene} " +
        "pumped=${remapPumpedKind}/${remapPumpedNode}/${remapPumpedScene} " +
        "accepted_scene=${scopeRemapWindow.displayedSceneVersion()}")
    if (!freshShortcutApplied) { scopeRemapWindow.close(); window.close(); return 167 }
    var scopeRemapFocused: UInt64 = 0u64
    let scopeRemapTabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(
            scopeRemapWindow.testSessionToken(), 48u16, 0u64, inout scopeRemapFocused
        )
    }
    let _ = scopeRemapWindow.pump(0u32)
    println("CJGUI_SCOPE_REMAP_TAB status=${scopeRemapTabStatus} focused=${scopeRemapFocused} " +
        "expected=9407")
    if (scopeRemapTabStatus != CJGUI_INTERNAL_RENDERER_OK || scopeRemapFocused != 9407u64) {
        scopeRemapWindow.close(); window.close(); return 94
    }
    scopeRemapWindow.close()
    // Public component instances remove global ID ranges from a repeated
    // editor: the same Cmd-K resolves only inside the focused instance. The
    // registry's duplicate-key failure happens before it can alias a node.
    let duplicateRegistry = CjguiComposableUiComponentRegistry()
    if (!duplicateRegistry.begin() || !duplicateRegistry.use("duplicate").isLive() ||
        duplicateRegistry.use("duplicate").isLive() || duplicateRegistry.lastIssue() != "duplicate_component_key") {
        window.close(); return 113
    }
    let _ = duplicateRegistry.finish()
    let componentController = ComponentInstanceController()
    let componentWindow = CjguiComposableUiWindow(componentController)
    if (!componentWindow.start()) {
        componentWindow.close(); window.close(); return 114
    }
    let initialAlphaNodeId = componentController.alphaActionNodeId()
    let initialBetaNodeId = componentController.betaActionNodeId()
    if (initialAlphaNodeId < 0 || initialBetaNodeId < 0 || initialAlphaNodeId == initialBetaNodeId) {
        componentWindow.close(); window.close(); return 115
    }
    // The public transport must serialize a live component projection for
    // both complete and target-filtered context reads. This goes through the
    // actual window projection, rather than manufacturing a parallel test
    // projection with friendlier identifiers.
    let componentReadDomain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(701, "component context", false)
    ]))
    let componentReadAuthorization = CjguiSharedOperationExternalAuthorization(
        "component projection test", "component-projection-test-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
    let componentReadConnection = CjguiSharedOperationExternalConnection(
        componentReadDomain, componentReadAuthorization, componentWindow
    )
    let componentFullSnapshot = componentReadConnection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH component-projection-test-capability\nGET_CONTEXT 0"
    )
    let componentTargetedSnapshot = componentReadConnection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH component-projection-test-capability\nGET_CONTEXT 1\nID 701"
    )
    let componentProjectionForContext = componentWindow.windowProjection()
    var componentSemanticNodeCount: Int64 = 0
    var componentSemanticLength: Int64 = 0
    var componentSemanticTokenSafe = true
    for (node in componentProjectionForContext.nodes) {
        if (node.semanticId.startsWith("component")) {
            componentSemanticNodeCount += 1; componentSemanticLength = node.semanticId.size
            if (!node.semanticId.isAscii() || node.semanticId.contains(":")) { componentSemanticTokenSafe = false }
        }
    }
    let componentFullResult = if (componentFullSnapshot.contains("KIND SNAPSHOT")) { "snapshot" }
        else if (componentFullSnapshot.contains("response_too_large")) { "too_large" } else { "invalid" }
    let componentTargetedResult = if (componentTargetedSnapshot.contains("KIND SNAPSHOT")) { "snapshot" }
        else if (componentTargetedSnapshot.contains("response_too_large")) { "too_large" } else { "invalid" }
    println("CJGUI_COMPONENT_CONTEXT_DIAGNOSTIC projection_nodes=${componentProjectionForContext.nodes.size} component_nodes=${componentSemanticNodeCount} component_semantic_length=${componentSemanticLength} component_semantic_token_safe=${componentSemanticTokenSafe} full_result=${componentFullResult} targeted_result=${componentTargetedResult}")
    if (!componentFullSnapshot.contains("KIND SNAPSHOT") || !componentTargetedSnapshot.contains("KIND SNAPSHOT") ||
        !componentFullSnapshot.contains("WINDOW_NODE component-")) {
        componentWindow.close(); window.close(); return 134
    }
    let alphaPressStatus = unsafe {
        cjgui_internal_renderer_test_press_composable_node(componentWindow.testSessionToken(), 2u32)
    }
    if (alphaPressStatus != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.alphaCount() != 1) {
        componentWindow.close(); window.close(); return 116
    }
    var componentFocused: UInt64 = 0u64
    let alphaShortcutStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(componentWindow.testSessionToken(), 40u16, 1048576u64, inout componentFocused)
    }
    if (alphaShortcutStatus != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.alphaCount() != 2 || componentController.betaCount() != 0) {
        componentWindow.close(); window.close(); return 117
    }
    let betaPressStatus = unsafe {
        cjgui_internal_renderer_test_press_composable_node(componentWindow.testSessionToken(), 4u32)
    }
    if (betaPressStatus != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.betaCount() != 1) {
        componentWindow.close(); window.close(); return 118
    }
    let betaShortcutStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(componentWindow.testSessionToken(), 40u16, 1048576u64, inout componentFocused)
    }
    if (betaShortcutStatus != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.alphaCount() != 2 || componentController.betaCount() != 2) {
        componentWindow.close(); window.close(); return 119
    }
    // A candidate that deletes alpha must not destroy its accepted component
    // identity while native measurement still rejects that candidate.  The
    // visible scene and its existing input route remain the truth until one
    // later scene is accepted; restoring the same candidate must reuse alpha
    // rather than manufacture a second instance identity.
    let beforeComponentFailure = componentWindow.windowProjection()
    componentController.removeAlpha()
    componentController.forceUncachedCaption()
    let forceComponentMeasurementFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_measurement_failures(componentWindow.testSessionToken(), 1u32)
    }
    let componentFailureRefresh = componentWindow.refresh()
    println("CJGUI_COMPONENT_FAILURE_REPRO set_status=${forceComponentMeasurementFailure} refresh=${componentFailureRefresh} open=${componentWindow.isOpen()} live_instances=${componentController.liveComponentCount()}")
    if (forceComponentMeasurementFailure != CJGUI_INTERNAL_RENDERER_OK || componentFailureRefresh ||
        !componentWindow.isOpen() || componentController.liveComponentCount() != 2) {
        componentWindow.close(); window.close(); return 135
    }
    let afterComponentFailure = componentWindow.windowProjection()
    if (afterComponentFailure.acceptedSceneVersion != beforeComponentFailure.acceptedSceneVersion ||
        afterComponentFailure.nodes.size != beforeComponentFailure.nodes.size ||
        afterComponentFailure.pendingRefreshReason != "refresh_internal_error") {
        componentWindow.close(); window.close(); return 136
    }
    let preservedAlphaPressStatus = unsafe {
        cjgui_internal_renderer_test_press_composable_node(componentWindow.testSessionToken(), 2u32)
    }
    if (preservedAlphaPressStatus != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.alphaCount() != 3) {
        componentWindow.close(); window.close(); return 137
    }
    // The preceding accepted human action explicitly retries the pending
    // deletion; only that accepted retry may retire alpha. Reattaching alpha
    // now creates one candidate identity. A second measurement failure must
    // retain that scalar candidate for an unchanged retry rather than leaking
    // a new generation on every attempt.
    if (componentController.liveComponentCount() != 1) {
        componentWindow.close(); window.close(); return 138
    }
    componentController.restoreAlphaAfterBeta()
    componentController.forceUncachedCaption()
    let forceReattachMeasurementFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_measurement_failures(componentWindow.testSessionToken(), 1u32)
    }
    let reattachFailureRefresh = componentWindow.refresh()
    let pendingReattachedAlphaNodeId = componentController.alphaActionNodeId()
    println("CJGUI_COMPONENT_FAILURE_RECOVERY set_status=${forceReattachMeasurementFailure} refresh=${reattachFailureRefresh} pending_alpha=${pendingReattachedAlphaNodeId} live_instances=${componentController.liveComponentCount()}")
    if (forceReattachMeasurementFailure != CJGUI_INTERNAL_RENDERER_OK || reattachFailureRefresh ||
        pendingReattachedAlphaNodeId < 0 || componentController.liveComponentCount() != 1) {
        componentWindow.close(); window.close(); return 139
    }
    if (!componentWindow.refresh() || componentController.alphaActionNodeId() != pendingReattachedAlphaNodeId ||
        componentController.liveComponentCount() != 2) {
        componentWindow.close(); window.close(); return 140
    }
    // The same candidate transaction must retain the old component owner,
    // scene and command target when native staging fails one node write.
    // This is deliberately after the measurement recovery above so it tests
    // an already accepted A/B scene and its real command route.
    let beforeSetterFailure = componentWindow.windowProjection()
    componentController.removeAlpha()
    componentController.forceUncachedCaption()
    let forceSetterFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_scene_node_failures(componentWindow.testSessionToken(), 1u32)
    }
    let setterFailureRefresh = componentWindow.refresh()
    let afterSetterFailure = componentWindow.windowProjection()
    let preservedSetterAlphaPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(componentWindow.testSessionToken(), 4u32)
    }
    if (forceSetterFailure != CJGUI_INTERNAL_RENDERER_OK || setterFailureRefresh ||
        afterSetterFailure.acceptedSceneVersion != beforeSetterFailure.acceptedSceneVersion ||
        afterSetterFailure.nodes.size != beforeSetterFailure.nodes.size ||
        afterSetterFailure.pendingRefreshReason != "refresh_internal_error" ||
        componentController.liveComponentCount() != 2 ||
        preservedSetterAlphaPress != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.alphaCount() != 4) {
        componentWindow.close(); window.close(); return 141
    }
    if (!componentWindow.refresh() || componentController.liveComponentCount() != 1) {
        componentWindow.close(); window.close(); return 142
    }
    componentController.restoreAlphaAfterBeta()
    if (!componentWindow.refresh() || componentController.liveComponentCount() != 2) {
        componentWindow.close(); window.close(); return 143
    }
    // present is the native acceptance boundary.  A rejected presentation is
    // still a rejected component transaction: Cangjie and native retain the
    // prior scene together, then one explicit healthy retry may retire alpha.
    let beforePresentFailure = componentWindow.windowProjection()
    componentController.removeAlpha()
    componentController.forceUncachedCaption()
    let forcePresentFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_present_failures(componentWindow.testSessionToken(), 1u32)
    }
    let presentFailureRefresh = componentWindow.refresh()
    let afterPresentFailure = componentWindow.windowProjection()
    let preservedPresentAlphaPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(componentWindow.testSessionToken(), 4u32)
    }
    println("CJGUI_COMPONENT_NATIVE_FAILURE_REPRO setter=${setterFailureRefresh} present=${presentFailureRefresh} live_instances=${componentController.liveComponentCount()}")
    if (forcePresentFailure != CJGUI_INTERNAL_RENDERER_OK || presentFailureRefresh ||
        afterPresentFailure.acceptedSceneVersion != beforePresentFailure.acceptedSceneVersion ||
        afterPresentFailure.nodes.size != beforePresentFailure.nodes.size ||
        afterPresentFailure.pendingRefreshReason != "refresh_internal_error" ||
        componentController.liveComponentCount() != 2 ||
        preservedPresentAlphaPress != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction ||
        componentController.alphaCount() != 5) {
        componentWindow.close(); window.close(); return 144
    }
    if (!componentWindow.refresh() || componentController.liveComponentCount() != 1) {
        componentWindow.close(); window.close(); return 145
    }
    componentController.restoreAlphaAfterBeta()
    if (!componentWindow.refresh() || componentController.liveComponentCount() != 2) {
        componentWindow.close(); window.close(); return 146
    }
    componentController.hideBeta()
    if (!componentWindow.refresh()) {
        componentWindow.close(); window.close(); return 120
    }
    componentController.showBeta()
    if (!componentWindow.refresh() ||
        componentController.betaActionNodeId() != initialBetaNodeId) {
        componentWindow.close(); window.close(); return 121
    }
    componentController.removeAlpha()
    if (!componentWindow.refresh()) {
        componentWindow.close(); window.close(); return 122
    }
    componentController.restoreAlphaAfterBeta()
    if (!componentWindow.refresh() ||
        componentController.alphaActionNodeId() == initialAlphaNodeId) {
        componentWindow.close(); window.close(); return 123
    }
    // Same-process lifecycle cost: each turn changes focus ownership through
    // the real native FIFO, hides/restores one instance, destroys/recreates
    // the other, and atomically replaces the complete command set. No idle
    // sleep or synthetic timing threshold is used.
    var cycleMinMs: Int64 = -1; var cycleMaxMs: Int64 = 0; var cycleTotalMs: Int64 = 0
    var componentQueuePending: UInt32 = 0; var componentQueueHighWater: UInt32 = 0
    var componentAccessibilityNotifications: UInt64 = 0u64
    let cycleBefore = componentWindow.windowProjection()
    var cycle: Int64 = 0
    while (cycle < 30) {
        let cycleStarted = MonoTime.now()
        let alphaIndex = if (cycle == 0) { 4u32 } else { 4u32 }
        let cyclePress = unsafe { cjgui_internal_renderer_test_press_composable_node(componentWindow.testSessionToken(), alphaIndex) }
        if (cyclePress != CJGUI_INTERNAL_RENDERER_OK || !componentWindow.pump(0u32).didApplyHumanAction) {
            componentWindow.close(); window.close(); return 124
        }
        componentController.hideBeta()
        if (!componentWindow.refresh()) {
            componentWindow.close(); window.close(); return 125
        }
        componentController.showBeta()
        if (!componentWindow.refresh()) {
            componentWindow.close(); window.close(); return 126
        }
        componentController.removeAlpha()
        if (!componentWindow.refresh()) {
            componentWindow.close(); window.close(); return 127
        }
        componentController.restoreAlphaAfterBeta()
        if (!componentWindow.refresh() ||
            componentController.liveComponentCount() != 2 || componentController.commands().size != 2) {
            componentWindow.close(); window.close(); return 128
        }
        let elapsed = (MonoTime.now() - cycleStarted).toMilliseconds()
        if (cycleMinMs < 0 || elapsed < cycleMinMs) { cycleMinMs = elapsed }
        if (elapsed > cycleMaxMs) { cycleMaxMs = elapsed }
        cycleTotalMs += elapsed; cycle += 1
    }
    let componentInteractionStats = unsafe {
        cjgui_internal_renderer_test_composable_interaction_stats(componentWindow.testSessionToken(),
            inout componentQueuePending, inout componentQueueHighWater, inout componentAccessibilityNotifications)
    }
    let cycleAfter = componentWindow.windowProjection()
    if (componentInteractionStats != CJGUI_INTERNAL_RENDERER_OK || componentQueuePending != 0u32 ||
        componentController.liveComponentCount() != 2 || componentController.commands().size != 2) {
        componentWindow.close(); window.close(); return 129
    }
    var workloadResidentBytes: UInt64 = 0u64; var workloadUserMicros: UInt64 = 0u64; var workloadSystemMicros: UInt64 = 0u64
    let workloadResourceStatus = unsafe {
        cjgui_internal_renderer_test_process_resource_stats(componentWindow.testSessionToken(), inout workloadResidentBytes,
            inout workloadUserMicros, inout workloadSystemMicros)
    }
    // Keep the *same* ordinary window alive and idle for thirty seconds after
    // the workload.  This is a bounded native event wait, not a sleep: no
    // scene refresh, layout, or submit is requested during recovery.
    let idleRecoveryBefore = componentWindow.windowProjection()
    var idleRecoveryTurn: Int64 = 0
    while (idleRecoveryTurn < 1875) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(componentWindow, turnBudgetMs: 16u32)
        idleRecoveryTurn += 1
    }
    let idleRecoveryAfter = componentWindow.windowProjection()
    var idleResidentBytes: UInt64 = 0u64; var idleUserMicros: UInt64 = 0u64; var idleSystemMicros: UInt64 = 0u64
    let idleResourceStatus = unsafe {
        cjgui_internal_renderer_test_process_resource_stats(componentWindow.testSessionToken(), inout idleResidentBytes,
            inout idleUserMicros, inout idleSystemMicros)
    }
    if (workloadResourceStatus != CJGUI_INTERNAL_RENDERER_OK || idleResourceStatus != CJGUI_INTERNAL_RENDERER_OK ||
        idleRecoveryAfter.buildPassCount != idleRecoveryBefore.buildPassCount ||
        idleRecoveryAfter.layoutPassCount != idleRecoveryBefore.layoutPassCount ||
        idleRecoveryAfter.nativeSubmissionCount != idleRecoveryBefore.nativeSubmissionCount ||
        idleRecoveryAfter.submittedFrameIndex != idleRecoveryBefore.submittedFrameIndex) {
        componentWindow.close(); window.close(); return 133
    }
    println("CJGUI_COMPONENT_LIFECYCLE_COST cycles=30 min_ms=${cycleMinMs} mean_ms=${cycleTotalMs / 30} max_ms=${cycleMaxMs} build_delta=${cycleAfter.buildPassCount - cycleBefore.buildPassCount} layout_delta=${cycleAfter.layoutPassCount - cycleBefore.layoutPassCount} submit_delta=${cycleAfter.nativeSubmissionCount - cycleBefore.nativeSubmissionCount} queue_pending=${componentQueuePending} queue_high_water=${componentQueueHighWater} ax_notifications=${componentAccessibilityNotifications} live_instances=${componentController.liveComponentCount()} live_commands=${componentController.commands().size} workload_rss_bytes=${workloadResidentBytes} idle_rss_bytes=${idleResidentBytes} workload_cpu_micros=${workloadUserMicros + workloadSystemMicros} idle_cpu_micros=${idleUserMicros + idleSystemMicros} idle_turns=${idleRecoveryTurn} idle_build_delta=${idleRecoveryAfter.buildPassCount - idleRecoveryBefore.buildPassCount} idle_layout_delta=${idleRecoveryAfter.layoutPassCount - idleRecoveryBefore.layoutPassCount} idle_submit_delta=${idleRecoveryAfter.nativeSubmissionCount - idleRecoveryBefore.nativeSubmissionCount}")
    componentWindow.close()
    // Scoped composition gets the same accepted-scene, pointer, focus and
    // stale-target rules as a manual node tree.  Reordering must retain live
    // scope/local mappings, while deletion/rebuild must allocate a new scalar
    // and keep a captured native accessibility target dead.
    let scopedIdentityController = ScopedIdentityController()
    let scopedIdentityWindow = CjguiComposableUiWindow(scopedIdentityController)
    if (!scopedIdentityWindow.start()) { scopedIdentityWindow.close(); window.close(); return 166 }
    let scopedInitialProjection = scopedIdentityWindow.windowProjection()
    let initialScopedAlphaApply = nodeIdForSemanticId(scopedInitialProjection, "scoped-identity-alpha-apply")
    let initialScopedBetaApply = nodeIdForSemanticId(scopedInitialProjection, "scoped-identity-beta-apply")
    if (initialScopedAlphaApply < 8000000000000000000 || initialScopedBetaApply < 0 ||
        initialScopedAlphaApply == initialScopedBetaApply) {
        scopedIdentityWindow.close(); window.close(); return 167
    }
    let initialScopedPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(scopedIdentityWindow.testSessionToken(), 2u32)
    }
    if (initialScopedPress != CJGUI_INTERNAL_RENDERER_OK || !scopedIdentityWindow.pump(0u32).didApplyHumanAction ||
        scopedIdentityController.alphaApplyCount() != 1) {
        scopedIdentityWindow.close(); window.close(); return 168
    }
    var scopedTabFocus: UInt64 = 0u64
    let scopedTabStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(scopedIdentityWindow.testSessionToken(), 1u16, 0u64,
            inout scopedTabFocus)
    }
    println("CJGUI_SCOPED_IDENTITY_FOCUS tab_status=${scopedTabStatus} focused=${scopedTabFocus} expected=${initialScopedAlphaApply}")
    if (scopedTabStatus != CJGUI_INTERNAL_RENDERER_OK || scopedTabFocus != UInt64(initialScopedAlphaApply)) {
        scopedIdentityWindow.close(); window.close(); return 169
    }
    scopedIdentityController.reorder()
    if (!scopedIdentityWindow.refresh()) { scopedIdentityWindow.close(); window.close(); return 170 }
    let scopedReorderedProjection = scopedIdentityWindow.windowProjection()
    if (nodeIdForSemanticId(scopedReorderedProjection, "scoped-identity-alpha-apply") != initialScopedAlphaApply ||
        nodeIdForSemanticId(scopedReorderedProjection, "scoped-identity-beta-apply") != initialScopedBetaApply) {
        scopedIdentityWindow.close(); window.close(); return 171
    }
    let reorderedScopedPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(scopedIdentityWindow.testSessionToken(), 5u32)
    }
    if (reorderedScopedPress != CJGUI_INTERNAL_RENDERER_OK || !scopedIdentityWindow.pump(0u32).didApplyHumanAction ||
        scopedIdentityController.alphaApplyCount() != 2) {
        scopedIdentityWindow.close(); window.close(); return 172
    }
    let captureScopedAlphaAccessibility = unsafe {
        cjgui_internal_renderer_test_capture_composable_accessibility_action(scopedIdentityWindow.testSessionToken(), 5u32)
    }
    scopedIdentityController.removeAlpha()
    if (captureScopedAlphaAccessibility != CJGUI_INTERNAL_RENDERER_OK || !scopedIdentityWindow.refresh()) {
        scopedIdentityWindow.close(); window.close(); return 173
    }
    scopedIdentityController.restoreAlpha()
    if (!scopedIdentityWindow.refresh()) { scopedIdentityWindow.close(); window.close(); return 174 }
    let rebuiltScopedProjection = scopedIdentityWindow.windowProjection()
    let rebuiltScopedAlphaApply = nodeIdForSemanticId(rebuiltScopedProjection, "scoped-identity-alpha-apply")
    let staleScopedAccessibility = unsafe {
        cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(scopedIdentityWindow.testSessionToken())
    }
    let staleScopedPump = scopedIdentityWindow.pump(0u32)
    if (rebuiltScopedAlphaApply == initialScopedAlphaApply || staleScopedAccessibility == CJGUI_INTERNAL_RENDERER_OK ||
        staleScopedPump.didApplyHumanAction || scopedIdentityController.alphaApplyCount() != 2) {
        scopedIdentityWindow.close(); window.close(); return 175
    }
    let beforeScopedDuplicate = scopedIdentityWindow.windowProjection()
    scopedIdentityController.addDuplicateAlpha()
    let duplicateScopedRefresh = scopedIdentityWindow.refresh()
    let afterScopedDuplicate = scopedIdentityWindow.windowProjection()
    let scopedDiagnosticDomain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(711, "scoped identity diagnostic", false)
    ]))
    let scopedDiagnosticAuthorization = CjguiSharedOperationExternalAuthorization(
        "scoped identity diagnostic", "scoped-identity-diagnostic-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)
        ])
    )
    let scopedDiagnosticConnection = CjguiSharedOperationExternalConnection(
        scopedDiagnosticDomain, scopedDiagnosticAuthorization, scopedIdentityWindow
    )
    let scopedDiagnosticSnapshot = scopedDiagnosticConnection.dispatchPayload(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH scoped-identity-diagnostic-capability\nGET_CONTEXT 0"
    )
    let preservedScopedAlphaPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(scopedIdentityWindow.testSessionToken(), 5u32)
    }
    if (duplicateScopedRefresh || afterScopedDuplicate.acceptedSceneVersion != beforeScopedDuplicate.acceptedSceneVersion ||
        afterScopedDuplicate.lastNativeFailure != "identity_duplicate_scope_window-identity--card--alpha_key_row" ||
        afterScopedDuplicate.pendingRefreshReason != "refresh_identity_duplicate_scope_window-identity--card--alpha_key_row" ||
        !scopedDiagnosticSnapshot.contains("WINDOW_LAST_NATIVE_FAILURE identity_duplicate_scope_window-identity--card--alpha_key_row") ||
        nodeIdForSemanticId(afterScopedDuplicate, "scoped-identity-alpha-apply") != rebuiltScopedAlphaApply ||
        preservedScopedAlphaPress != CJGUI_INTERNAL_RENDERER_OK || !scopedIdentityWindow.pump(0u32).didApplyHumanAction ||
        scopedIdentityController.alphaApplyCount() != 3) {
        scopedIdentityWindow.close(); window.close(); return 176
    }
    scopedIdentityController.clearDuplicateAlpha()
    if (!scopedIdentityWindow.refresh() ||
        nodeIdForSemanticId(scopedIdentityWindow.windowProjection(), "scoped-identity-alpha-apply") != rebuiltScopedAlphaApply) {
        scopedIdentityWindow.close(); window.close(); return 177
    }
    println("CJGUI_SCOPED_IDENTITY_WINDOW accepted_alpha=${initialScopedAlphaApply} rebuilt_alpha=${rebuiltScopedAlphaApply} beta=${initialScopedBetaApply} alpha_actions=${scopedIdentityController.alphaApplyCount()} duplicate_rejected=${!duplicateScopedRefresh}")
    scopedIdentityWindow.close()
    // RED: an accepted projection must not keep the caller's mutable node
    // object. Starting B with a preamble assigns a different scoped ID to the
    // same declaration; A has not refreshed and must retain its own accepted
    // public projection.
    let sharedDeclarationController = SharedDeclarationController()
    let sharedDeclarationWindowA = CjguiComposableUiWindow(sharedDeclarationController)
    if (!sharedDeclarationWindowA.start()) { sharedDeclarationWindowA.close(); window.close(); return 178 }
    let sharedDeclarationAId = nodeIdForSemanticId(sharedDeclarationWindowA.windowProjection(), "shared-declaration-action")
    sharedDeclarationController.includePreamble()
    let sharedDeclarationWindowB = CjguiComposableUiWindow(sharedDeclarationController)
    if (!sharedDeclarationWindowB.start()) {
        sharedDeclarationWindowB.close(); sharedDeclarationWindowA.close(); window.close(); return 179
    }
    let sharedDeclarationAAfterBId = nodeIdForSemanticId(sharedDeclarationWindowA.windowProjection(),
        "shared-declaration-action")
    let sharedDeclarationBId = nodeIdForSemanticId(sharedDeclarationWindowB.windowProjection(),
        "shared-declaration-action")
    if (sharedDeclarationAId < 8000000000000000000 || sharedDeclarationBId < 8000000000000000000 ||
        sharedDeclarationAAfterBId != sharedDeclarationAId) {
        sharedDeclarationWindowB.close(); sharedDeclarationWindowA.close(); window.close(); return 180
    }
    println("CJGUI_SHARED_DECLARATION_ISOLATION a=${sharedDeclarationAId} b=${sharedDeclarationBId} a_after_b=${sharedDeclarationAAfterBId}")
    sharedDeclarationWindowB.close(); sharedDeclarationWindowA.close()
    // A real language Exception during buildUi must not leave the public
    // participant candidate open.  The accepted single component and scene
    // remain live; the following retry commits exactly the candidate that
    // the failed attempt had allocated, rather than inventing another one.
    let exceptionController = RecoverableExceptionController()
    let exceptionWindow = CjguiComposableUiWindow(exceptionController)
    if (!exceptionWindow.start() || exceptionController.liveComponentCount() != 1 ||
        exceptionController.commitCount() != 1) {
        exceptionWindow.close(); window.close(); return 147
    }
    let beforeBuildException = exceptionWindow.windowProjection()
    exceptionController.failAfterCandidateBuild()
    let buildExceptionRefresh = exceptionWindow.refresh()
    let failedCandidateNodeId = exceptionController.candidateNodeId()
    let afterBuildException = exceptionWindow.windowProjection()
    if (buildExceptionRefresh || !exceptionWindow.isOpen() || failedCandidateNodeId < 0 ||
        exceptionController.liveComponentCount() != 1 || exceptionController.rollbackCount() != 1 ||
        afterBuildException.acceptedSceneVersion != beforeBuildException.acceptedSceneVersion ||
        afterBuildException.pendingRefreshReason != "refresh_internal_error") {
        exceptionWindow.close(); window.close(); return 148
    }
    if (exceptionWindow.refreshIfNeeded()) {
        exceptionWindow.close(); window.close(); return 149
    }
    exceptionController.recoverCandidateBuild()
    if (!exceptionWindow.refresh() || exceptionController.liveComponentCount() != 2 ||
        exceptionController.candidateNodeId() != failedCandidateNodeId || exceptionController.commitCount() != 2) {
        exceptionWindow.close(); window.close(); return 150
    }
    // The participant may also throw only after it has prepared a candidate.
    // Its rollback must be just as complete: no accepted identity, scene, or
    // command projection changes until the subsequent healthy retry.
    let beforePrepareException = exceptionWindow.windowProjection()
    let rollbackBeforePrepareException = exceptionController.rollbackCount()
    exceptionController.failAfterPrepare()
    let prepareExceptionRefresh = exceptionWindow.refresh()
    let afterPrepareException = exceptionWindow.windowProjection()
    println("CJGUI_PARTICIPANT_EXCEPTION_REPRO build=${buildExceptionRefresh} prepare=${prepareExceptionRefresh} live_instances=${exceptionController.liveComponentCount()} rollbacks=${exceptionController.rollbackCount()} commits=${exceptionController.commitCount()}")
    if (prepareExceptionRefresh || exceptionController.liveComponentCount() != 2 ||
        exceptionController.rollbackCount() != rollbackBeforePrepareException + 1 ||
        afterPrepareException.acceptedSceneVersion != beforePrepareException.acceptedSceneVersion ||
        afterPrepareException.pendingRefreshReason != "refresh_internal_error") {
        exceptionWindow.close(); window.close(); return 151
    }
    exceptionController.recoverPrepare()
    let recoveredPrepareRefresh = exceptionWindow.refresh()
    println("CJGUI_PARTICIPANT_EXCEPTION_RECOVERY refresh=${recoveredPrepareRefresh} live_instances=${exceptionController.liveComponentCount()} begins=${exceptionController.beginCount()} prepares=${exceptionController.prepareCount()} rollbacks=${exceptionController.rollbackCount()} commits=${exceptionController.commitCount()}")
    if (!recoveredPrepareRefresh || exceptionController.liveComponentCount() != 2 ||
        exceptionController.commitCount() != 3 || exceptionController.beginCount() != exceptionController.prepareCount() + 1) {
        exceptionWindow.close(); window.close(); return 152
    }
    // Once native present has accepted a replacement, a participant's commit
    // callback may not masquerade as a failed candidate. This controller
    // throws after its component swap: the window must terminate without
    // invoking rollback against an already accepted native scene.
    let rollbackBeforeAcceptedCommitException = exceptionController.rollbackCount()
    exceptionController.failAfterAcceptedCommit()
    let acceptedCommitExceptionRefresh = exceptionWindow.refresh()
    println("CJGUI_PARTICIPANT_ACCEPTED_COMMIT_EXCEPTION refresh=${acceptedCommitExceptionRefresh} open=${exceptionWindow.isOpen()} rollbacks=${exceptionController.rollbackCount()} commits=${exceptionController.commitCount()}")
    if (acceptedCommitExceptionRefresh || exceptionWindow.isOpen() ||
        exceptionController.rollbackCount() != rollbackBeforeAcceptedCommitException ||
        exceptionController.commitCount() != 4) {
        exceptionWindow.close(); window.close(); return 154
    }
    exceptionWindow.close()
    // A Cangjie-owned scene update that disables/removes the focused control
    // must transfer native focus to the next live control.  This uses actual
    // AppKit press/key routing, not a direct focus assignment after refresh.
    let disabledFocusController = FocusReplacementController()
    let disabledFocusWindow = CjguiComposableUiWindow(disabledFocusController)
    if (!disabledFocusWindow.start()) { window.close(); return 95 }
    let disabledFocusPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(disabledFocusWindow.testSessionToken(), 2u32)
    }
    let _ = disabledFocusWindow.pump(0u32)
    disabledFocusController.disableMiddle()
    if (disabledFocusPress != CJGUI_INTERNAL_RENDERER_OK || !disabledFocusWindow.refresh()) {
        disabledFocusWindow.close(); window.close(); return 96
    }
    var disabledReplacementFocus: UInt64 = 0u64
    let disabledReplacementStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(
            disabledFocusWindow.testSessionToken(), 1u16, 0u64, inout disabledReplacementFocus
        )
    }
    if (disabledReplacementStatus != CJGUI_INTERNAL_RENDERER_OK || disabledReplacementFocus != 9503u64) {
        disabledFocusWindow.close(); window.close(); return 97
    }
    disabledFocusWindow.close()
    let removedFocusController = FocusReplacementController()
    let removedFocusWindow = CjguiComposableUiWindow(removedFocusController)
    if (!removedFocusWindow.start()) { window.close(); return 98 }
    let removedFocusPress = unsafe {
        cjgui_internal_renderer_test_press_composable_node(removedFocusWindow.testSessionToken(), 2u32)
    }
    let _ = removedFocusWindow.pump(0u32)
    removedFocusController.removeMiddle()
    if (removedFocusPress != CJGUI_INTERNAL_RENDERER_OK || !removedFocusWindow.refresh()) {
        removedFocusWindow.close(); window.close(); return 99
    }
    var removedReplacementFocus: UInt64 = 0u64
    let removedReplacementStatus = unsafe {
        cjgui_internal_renderer_test_send_composable_key(
            removedFocusWindow.testSessionToken(), 1u16, 0u64, inout removedReplacementFocus
        )
    }
    if (removedReplacementStatus != CJGUI_INTERNAL_RENDERER_OK || removedReplacementFocus != 9503u64) {
        removedFocusWindow.close(); window.close(); return 100
    }
    removedFocusWindow.close()
    // Keep one real AX element while its owner removes the target, then adds
    // a different action using the same raw node fields. The old object must
    // fail closed; a newly queried AX element still reaches the replacement
    // through the normal FIFO/controller route.
    let accessibilityRebindController = AccessibilityRebindController()
    let accessibilityRebindWindow = CjguiComposableUiWindow(accessibilityRebindController)
    if (!accessibilityRebindWindow.start()) { window.close(); return 101 }
    let captureStaleAccessibility = unsafe {
        cjgui_internal_renderer_test_capture_composable_accessibility_action(
            accessibilityRebindWindow.testSessionToken(), 1u32
        )
    }
    accessibilityRebindController.removeTarget()
    if (captureStaleAccessibility != CJGUI_INTERNAL_RENDERER_OK || !accessibilityRebindWindow.refresh()) {
        accessibilityRebindWindow.close(); window.close(); return 102
    }
    accessibilityRebindController.addReplacement()
    if (!accessibilityRebindWindow.refresh()) { accessibilityRebindWindow.close(); window.close(); return 103 }
    let staleAccessibilityInvoke = unsafe {
        cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(accessibilityRebindWindow.testSessionToken())
    }
    let staleAccessibilityPump = accessibilityRebindWindow.pump(0u32)
    if (staleAccessibilityInvoke == CJGUI_INTERNAL_RENDERER_OK || staleAccessibilityPump.didApplyHumanAction ||
        accessibilityRebindController.didActivateReplacement()) {
        accessibilityRebindWindow.close(); window.close(); return 104
    }
    let captureFreshAccessibility = unsafe {
        cjgui_internal_renderer_test_capture_composable_accessibility_action(
            accessibilityRebindWindow.testSessionToken(), 1u32
        )
    }
    let freshAccessibilityInvoke = unsafe {
        cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(accessibilityRebindWindow.testSessionToken())
    }
    let freshAccessibilityPump = accessibilityRebindWindow.pump(0u32)
    if (captureFreshAccessibility != CJGUI_INTERNAL_RENDERER_OK || freshAccessibilityInvoke != CJGUI_INTERNAL_RENDERER_OK ||
        !freshAccessibilityPump.didApplyHumanAction || !accessibilityRebindController.didActivateReplacement()) {
        accessibilityRebindWindow.close(); window.close(); return 105
    }
    accessibilityRebindWindow.close()
    // A non-readback submission can still complete after close. Reuse the
    // same native slot immediately and let normal bounded turns drain the
    // callback: the old generation must not advance the replacement window's
    // progress or report a spurious failure.
    let inFlightController = NativeEventController()
    let inFlightWindow = CjguiComposableUiWindow(inFlightController)
    if (!inFlightWindow.start()) { window.close(); return 78 }
    inFlightController.changeCaption("retiring command buffer")
    if (!inFlightWindow.refresh()) { inFlightWindow.close(); window.close(); return 79 }
    let retiringProgress = inFlightWindow.windowProjection()
    if (retiringProgress.submittedFrameIndex <= 1) { inFlightWindow.close(); window.close(); return 80 }
    inFlightWindow.close()
    if (!inFlightWindow.start()) { window.close(); return 81 }
    // The still-live application image domain reuses its decoded texture on
    // reopen. Both image nodes must load, while this new session performs no
    // additional decode. Settle that normal work before checking that no late
    // completion from the retired session advances the replacement's counters.
    if (!settleComposableImages(inFlightWindow, 2u32, 0u32)) { inFlightWindow.close(); window.close(); return 165 }
    let replacementProgress = inFlightWindow.windowProjection()
    println("CJGUI_INFLIGHT_REOPEN_PROGRESS accepted=${replacementProgress.acceptedSceneVersion} " +
        "submitted=${replacementProgress.submittedFrameIndex} " +
        "completed=${replacementProgress.observedMetalCompletionFrameIndex} " +
        "build=${replacementProgress.buildPassCount} layout=${replacementProgress.layoutPassCount} " +
        "native_submit=${replacementProgress.nativeSubmissionCount} " +
        "pending='${replacementProgress.pendingRefreshReason}' " +
        "failure='${replacementProgress.lastNativeFailure}'")
    // Reused image textures are present in the reopened session's first
    // frame. A late completion from the retired generation must not add a
    // second submitted or completed frame to this replacement session.
    if (replacementProgress.submittedFrameIndex != 1) { inFlightWindow.close(); window.close(); return 82 }
    if (replacementProgress.observedMetalCompletionFrameIndex > replacementProgress.submittedFrameIndex ||
        replacementProgress.observedMetalFailureFrameIndex >= replacementProgress.submittedFrameIndex) {
        inFlightWindow.close(); window.close(); return 83
    }
    if (replacementProgress.observedMetalFailureFrameIndex != -1) { inFlightWindow.close(); window.close(); return 84 }
    let replacementDeadline = MonoTime.now()
    while ((MonoTime.now() - replacementDeadline).toMilliseconds() < 48) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(inFlightWindow, turnBudgetMs: 4u32)
    }
    let settledReplacement = inFlightWindow.windowProjection()
    if (settledReplacement.submittedFrameIndex != 1 || settledReplacement.observedMetalCompletionFrameIndex != 1 ||
        settledReplacement.observedMetalFailureFrameIndex != -1) { inFlightWindow.close(); window.close(); return 85 }
    inFlightWindow.close()
    // An actual native view invalidation is a no-drawable failure before a
    // command buffer is committed. It must retain the last accepted scene and
    // never manufacture completion/failure progress for a frame it did not
    // submit.
    let unavailableController = NativeEventController()
    let unavailableWindow = CjguiComposableUiWindow(unavailableController)
    if (!unavailableWindow.start()) { window.close(); return 86 }
    let beforeUnavailable = unavailableWindow.windowProjection()
    let invalidatedStatus = unsafe {
        cjgui_internal_renderer_test_invalidate_composable_drawable(unavailableWindow.testSessionToken())
    }
    unavailableController.changeCaption("no drawable after invalidation")
    if (invalidatedStatus != CJGUI_INTERNAL_RENDERER_OK || unavailableWindow.refresh() ||
        unavailableWindow.nativeStatus() != CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED) {
        unavailableWindow.close(); window.close(); return 87
    }
    let afterUnavailable = unavailableWindow.windowProjection()
    if (afterUnavailable.submittedFrameIndex != beforeUnavailable.submittedFrameIndex ||
        afterUnavailable.observedMetalCompletionFrameIndex != beforeUnavailable.observedMetalCompletionFrameIndex ||
        afterUnavailable.observedMetalFailureFrameIndex != beforeUnavailable.observedMetalFailureFrameIndex) {
        unavailableWindow.close(); window.close(); return 88
    }
    unavailableWindow.close()
    // The normal window's layout source must be real AppKit glyph metrics,
    // not UTF-8 byte counts. A combining mark stays with its base glyph and
    // increasing font size changes the measured output.
    let nativeText = unsafe { LibC.mallocCString("e\u{301}通知") }
    var small = CjguiInternalRendererTextMeasurement()
    var large = CjguiInternalRendererTextMeasurement()
    var measureStatus: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        unsafe {
            measureStatus = cjgui_internal_renderer_measure_composable_text(window.testSessionToken(), textResource.value, 12.0, 0u32, 0u32, 72u32, inout small)
            if (measureStatus == CJGUI_INTERNAL_RENDERER_OK) {
                measureStatus = cjgui_internal_renderer_measure_composable_text(window.testSessionToken(), textResource.value, 20.0, 1u32, 1u32, 72u32, inout large)
            }
        }
    }
    if (measureStatus != CJGUI_INTERNAL_RENDERER_OK || small.width == 0u32 || small.height == 0u32 ||
        large.lineHeight <= small.lineHeight || large.baseline <= small.baseline) { window.close(); return 9 }
    // The shared descriptor must reach AppKit rather than being normalized
    // away at the C FFI boundary: a narrow ASCII run has different metrics in
    // the system and monospaced families at the same point size.
    let narrowText = unsafe { LibC.mallocCString("iiiiiiii") }
    var narrowSystem = CjguiInternalRendererTextMeasurement()
    var narrowMonospaced = CjguiInternalRendererTextMeasurement()
    var familyMeasureStatus: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = narrowText.asResource()) {
        unsafe {
            familyMeasureStatus = cjgui_internal_renderer_measure_composable_text(window.testSessionToken(), textResource.value, 16.0, 0u32, 0u32, 240u32, inout narrowSystem)
            if (familyMeasureStatus == CJGUI_INTERNAL_RENDERER_OK) {
                familyMeasureStatus = cjgui_internal_renderer_measure_composable_text(window.testSessionToken(), textResource.value, 16.0, 0u32, 1u32, 240u32, inout narrowMonospaced)
            }
        }
    }
    if (familyMeasureStatus != CJGUI_INTERNAL_RENDERER_OK || narrowSystem.width == narrowMonospaced.width) { window.close(); return 31 }
    var loadedTextureCount: UInt32 = 0
    var cacheEntryCount: UInt32 = 0
    var imageDecodeCount: UInt32 = 0
    let imageStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(
            window.testSessionToken(), inout loadedTextureCount, inout cacheEntryCount, inout imageDecodeCount
        )
    }
    if (imageStatus != CJGUI_INTERNAL_RENDERER_OK || loadedTextureCount != 2u32 || cacheEntryCount != 1u32 || imageDecodeCount != 1u32) { window.close(); return 10 }
    // A same-path replacement must be an explicit resource-version change.
    // It must invalidate the texture cache without relying on a renamed file.
    let beforeReplacementVersion = window.displayedSceneVersion()
    controller.replaceSamePathImage()
    if (!window.refresh() || window.displayedSceneVersion() <= beforeReplacementVersion) { window.close(); return 13 }
    if (!settleComposableImages(window, 2u32, 2u32)) { window.close(); return 162 }
    loadedTextureCount = 0; cacheEntryCount = 0; imageDecodeCount = 0
    let replacementImageStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(
            window.testSessionToken(), inout loadedTextureCount, inout cacheEntryCount, inout imageDecodeCount
        )
    }
    if (replacementImageStatus != CJGUI_INTERNAL_RENDERER_OK || loadedTextureCount != 2u32 || cacheEntryCount == 0u32 || cacheEntryCount > 8u32 || imageDecodeCount != 2u32) { window.close(); return 14 }
    // Same logical identity can also replace actual source pixels. The
    // version moves once more and the coral asset is decoded.
    controller.replaceImagePixels()
    if (!window.refresh()) { window.close(); return 27 }
    if (!settleComposableImages(window, 2u32, 3u32)) { window.close(); return 163 }
    loadedTextureCount = 0; cacheEntryCount = 0; imageDecodeCount = 0
    let coralReplacementStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(
            window.testSessionToken(), inout loadedTextureCount, inout cacheEntryCount, inout imageDecodeCount
        )
    }
    if (coralReplacementStatus != CJGUI_INTERNAL_RENDERER_OK || loadedTextureCount != 2u32 || cacheEntryCount == 0u32 || cacheEntryCount > 8u32 || imageDecodeCount != 3u32) { window.close(); return 28 }
    // Retain the opposite content mode in the normal-window lifecycle path;
    // exact FIT/FILL pixel expectations are verified with the deterministic
    // native PNG fixture instead of a decorative transparent lighthouse.
    controller.showOneFitImage()
    if (!window.refresh()) { window.close(); return 29 }
    // Replacing the scene without an image must release the cache's last
    // strong reference after the old scene retires. Keeping it until window
    // close makes a long-lived dynamic UI retain every removed raster.
    controller.removeImage()
    if (!window.refresh()) { window.close(); return 11 }
    loadedTextureCount = 0; cacheEntryCount = 0; imageDecodeCount = 0
    let removedImageStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(
            window.testSessionToken(), inout loadedTextureCount, inout cacheEntryCount, inout imageDecodeCount
        )
    }
    if (removedImageStatus != CJGUI_INTERNAL_RENDERER_OK || loadedTextureCount != 0u32 || cacheEntryCount > 8u32 || imageDecodeCount != 3u32) { window.close(); return 12 }
    // An application may declare many logical resources during one session.
    // Nodes retain their active textures, but the reusable cache itself must
    // remain bounded after the scene is committed.
    controller.showManyUniqueImages()
    if (!window.refresh()) { window.close(); return 15 }
    if (!settleComposableImages(window, 10u32, 13u32)) { window.close(); return 164 }
    loadedTextureCount = 0; cacheEntryCount = 0; imageDecodeCount = 0
    let boundedImageStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(
            window.testSessionToken(), inout loadedTextureCount, inout cacheEntryCount, inout imageDecodeCount
        )
    }
    if (boundedImageStatus != CJGUI_INTERNAL_RENDERER_OK || loadedTextureCount != 10u32 || cacheEntryCount > 8u32 || imageDecodeCount != 13u32) { window.close(); return 16 }
    // The continuation exception is conditioned on the controller's durable
    // owner revision, not only the materialized native input scene. Cover
    // external same-object writes around refresh, changed values, focus
    // transfer, resource rebind and a read-only replacement before retaining
    // the ordinary rapid-keyboard positive path below.
    if (!verifyContinuationOwnerGuards()) { window.close(); return 153 }
    // Reproduce the host timing in which another character is queued during
    // construction of the replacement scene.  The second event was generated
    // by the still-live input adapter, not by an external caller, but it has
    // the prior projection version by the time the new scene is published.
    if (internalRendererFocusComposableNode(window.testSessionToken(), 2) != CJGUI_INTERNAL_RENDERER_OK) {
        window.close(); return 141
    }
    controller.armContinuationRace(window.testSessionToken())
    if (!enqueue(window, 2u32, 28u32, "initiala")) { window.close(); return 142 }
    let raceFirst = window.pump(0u32)
    let raceContinuation = window.pump(0u32)
    if (!raceFirst.didApplyHumanAction || !controller.didInjectContinuation() ||
        !raceContinuation.didApplyHumanAction || !controller.hasDraft("initialab")) {
        window.close(); return 143
    }
    println("CJGUI_RAPID_TEXT_CONTINUATION draft=initialab source=precommit_native_callback")
    // A normal keyboard can arrive one key event per host turn.  Each local
    // refresh must retain the live text identity so a following key is not
    // rejected merely because the same focused field was republished.
    if (internalRendererFocusComposableNode(window.testSessionToken(), 2) != CJGUI_INTERNAL_RENDERER_OK) {
        window.close(); return 144
    }
    var rapidInputFocused: UInt64 = 0u64
    var rapidKeyIndex: Int64 = 0
    while (rapidKeyIndex < 3) {
        let rapidKeyStatus = unsafe {
            cjgui_internal_renderer_test_send_composable_key(window.testSessionToken(), 0u16, 0u64,
                inout rapidInputFocused)
        }
        let rapidKeyPumped = window.pump(0u32)
        if (rapidKeyStatus != CJGUI_INTERNAL_RENDERER_OK || rapidInputFocused != 2u64 ||
            !rapidKeyPumped.didApplyHumanAction) {
            window.close(); return 145
        }
        rapidKeyIndex += 1
    }
    println("CJGUI_RAPID_TEXT_KEYBOARD draft=${controller.draftValue()} turns=3")
    // The probe seam queues the continuation without mutating NSTextView;
    // the following real key path therefore starts from its adapter baseline
    // ("initial") and independently proves three successive host turns.
    if (!controller.hasDraft("initialaaa")) { window.close(); return 146 }
    if (!enqueue(window, 2u32, 28u32, "native-updated")) { window.close(); return 4 }
    let edited = window.pump(0u32)
    if (!edited.didApplyHumanAction) { window.close(); return 5 }
    if (!enqueue(window, 3u32, 27u32, "")) { window.close(); return 6 }
    let applied = window.pump(0u32)
    let success = applied.didApplyHumanAction && controller.didApplyNativeText()
    // The continuation exception is deliberately narrow.  A queued text
    // event whose target has been removed by an external projection must
    // still reach rejectUiEvent rather than being retargeted by identity.
    if (!enqueue(window, 2u32, 28u32, "must-reject-after-delete")) { window.close(); return 147 }
    controller.removeTextInput()
    if (!window.refresh()) { window.close(); return 148 }
    let deletedTarget = window.pump(0u32)
    if (deletedTarget.didApplyHumanAction || !controller.didRejectTextAfterRemoval()) {
        window.close(); return 149
    }
    println("CJGUI_RAPID_TEXT_STALE_DELETE rejected=true")
    window.close()
    if (!success) { return 7 }
    println("cjgui composable window controller probe: native text then apply passed")
    return 0
}
