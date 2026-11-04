package cjgui_mixed_form_starter

import cjgui.*
import std.collection.*
import std.time.*

// This is a deliberately small app-owned workload, not a general telemetry
// layer. The private image-domain ABI keeps its original 14 slots and adds
// two weak-ledger counters for effect targets submitted after observation was
// enabled. They do not describe historical or unobserved GPU work. Accepted-
// scene text/effect/frame facts come from the normal diagnosticSnapshot API.
private let MIXED_RESOURCE_CYCLE_SCHEMA: UInt64 = 1u64
private let MIXED_RESOURCE_CYCLE_EFFECT_SCOPE: String = "observed_submissions_after_enable"
private let MIXED_RESOURCE_CYCLE_IMAGE_SNAPSHOT_SLOTS: Int = 16
private let MIXED_RESOURCE_CYCLE_COUNT: Int64 = 10
private let MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS: Int64 = 5
private let MIXED_RESOURCE_CYCLE_STABLE_TURNS: Int64 = 3

@When[os == "macOS"]
foreign func cjgui_internal_renderer_application_image_lifecycle_snapshot(values: CPointer<UInt64>, capacity: UInt32): Int32

private class MixedResourceCycleImageSnapshot {
    let status: Int32
    let schema: UInt64
    let activeSessions: UInt64
    let cacheEntries: UInt64
    let cacheBytes: UInt64
    let cacheBudgetBytes: UInt64
    let inFlight: UInt64
    let pending: UInt64
    let committedTextureRefs: UInt64
    let subscribers: UInt64
    let records: UInt64
    let decodeStarts: UInt64
    let rawSubscribers: UInt64
    let liveImageAllocations: UInt64
    let liveImageAllocationBytes: UInt64
    let effectInFlightTargets: UInt64
    let effectInFlightBytes: UInt64

    init(status: Int32, values: Array<UInt64>) {
        this.status = status
        this.schema = values[0]
        this.activeSessions = values[1]
        this.cacheEntries = values[2]
        this.cacheBytes = values[3]
        this.cacheBudgetBytes = values[4]
        this.inFlight = values[5]
        this.pending = values[6]
        this.committedTextureRefs = values[7]
        this.subscribers = values[8]
        this.records = values[9]
        this.decodeStarts = values[10]
        this.rawSubscribers = values[11]
        this.liveImageAllocations = values[12]
        this.liveImageAllocationBytes = values[13]
        this.effectInFlightTargets = values[14]
        this.effectInFlightBytes = values[15]
    }
}

@When[os == "macOS"]
private func mixedReadResourceCycleImageSnapshot(): MixedResourceCycleImageSnapshot {
    let values = Array<UInt64>(MIXED_RESOURCE_CYCLE_IMAGE_SNAPSHOT_SLOTS, repeat: 0u64)
    let status = unsafe {
        let raw = acquireArrayRawData(values)
        let result = cjgui_internal_renderer_application_image_lifecycle_snapshot(raw.pointer, UInt32(values.size))
        releaseArrayRawData(raw)
        result
    }
    return MixedResourceCycleImageSnapshot(status, values)
}

@When[os != "macOS"]
private func mixedReadResourceCycleImageSnapshot(): MixedResourceCycleImageSnapshot {
    return MixedResourceCycleImageSnapshot(-2, Array<UInt64>(MIXED_RESOURCE_CYCLE_IMAGE_SNAPSHOT_SLOTS, repeat: 0u64))
}

private class MixedResourceCycleWindowSnapshot {
    let image: MixedResourceCycleImageSnapshot
    let windowCount: Int64
    let sceneVersion: Int64
    let submittedFrame: Int64
    let completedFrame: Int64
    let textLiveBytes: Int64
    let reusableBytes: Int64
    let effectLiveBytes: Int64
    let effectCachedBytes: Int64
    let effectInFlightBytes: Int64
    let effectPassCount: Int64
    let generatedNodeCount: Int64
    let effectGroupNodeCount: Int64
    let scrollOffset: Int64
    let imageState: String

    init(image: MixedResourceCycleImageSnapshot, windowCount: Int64, diagnostic: CjguiComposableUiDiagnosticSnapshot,
        generatedNodeCount: Int64, effectGroupNodeCount: Int64, scrollOffset: Int64, imageState: String) {
        this.image = image
        this.windowCount = windowCount
        this.sceneVersion = diagnostic.acceptedSceneVersion
        this.submittedFrame = diagnostic.submittedFrameIndex
        this.completedFrame = diagnostic.completedFrameIndex
        this.textLiveBytes = diagnostic.textTextureLiveBytes
        this.reusableBytes = diagnostic.reusableResourceBytes
        this.effectLiveBytes = diagnostic.effectLiveBytes
        this.effectCachedBytes = diagnostic.effectCachedBytes
        this.effectInFlightBytes = diagnostic.effectInFlightBytes
        this.effectPassCount = diagnostic.effectPassCount
        this.generatedNodeCount = generatedNodeCount
        this.effectGroupNodeCount = effectGroupNodeCount
        this.scrollOffset = scrollOffset
        this.imageState = imageState
    }
}

private func mixedResourceCycleImagePath(key: String): String {
    if (key == "preview-swatch") {
        return "preview-swatch.png"
    }
    if (key == "preview-jpeg-alt") {
        return "preview-swatch-v2.jpg"
    }
    return "preview-swatch.jpg"
}

private func mixedResourceCycleImageKey(cycle: Int64, replacement: Bool): String {
    let index = cycle + if (replacement) {
        1
    } else {
        0
    }
    return if (index % 3 == 0) {
        "preview-swatch"
    } else if (index % 3 == 1) {
        "preview-jpeg-alt"
    } else {
        "preview-jpeg"
    }
}

private func mixedResourceCycleAnchorImageState(anchor: CjguiComposableUiWindow): String {
    let key = mixedResourceCycleImageKey(0, false)
    return anchor.imageResourceStatus(mixedResourceCycleImagePath(key), key, 1).state
}

private func mixedResourceCycleEffectToken(cycle: Int64, replacement: Bool): String {
    if ((cycle + if (replacement) {
        1
    } else {
        0
    }) % 2 == 0) {
        return "55,normal,none;blur=6,unblurred"
    }
    return "65,multiply,25,50,75,50,0:0|50:50|100:100"
}

func mixedResourceCycleStructure(cycle: Int64, replacement: Bool): String {
    let imageKey = mixedResourceCycleImageKey(cycle, replacement)
    let revision = if (replacement) {
        "replacement"
    } else {
        "initial"
    }
    let marker = "cycle-${cycle}-${revision}"
    let effect = mixedResourceCycleEffectToken(cycle, replacement)
    return "GENERATED_UI_STRUCTURE 1\n" + "NODE 0 root vertical\n" + "NODE 1 cycle-scroll scrollArea\n" +
        "PROPERTY 1 cycle-scroll fixedWidth 280\n" + "PROPERTY 1 cycle-scroll fixedHeight 96\n" +
        "NODE 2 cycle-content vertical\n" + "NODE 3 cycle-card vertical\n" +
        "PROPERTY 3 cycle-card effectGroup ${effect}\n" + "NODE 4 cycle-image image\n" +
        "PROPERTY 4 cycle-image resource ${imageKey}\n" + "PROPERTY 4 cycle-image resourceVersion 1\n" +
        "PROPERTY 4 cycle-image contentMode fill\n" + "PROPERTY 4 cycle-image fixedWidth 120\n" +
        "PROPERTY 4 cycle-image fixedHeight 64\n" + "NODE 4 cycle-title label\n" +
        "PROPERTY 4 cycle-title text ${marker}\n" + "NODE 4 cycle-row-a label\n" +
        "PROPERTY 4 cycle-row-a text text replacement ${marker} · 甲\n" + "NODE 4 cycle-row-b label\n" +
        "PROPERTY 4 cycle-row-b text text replacement ${marker} · 乙\n" + "NODE 4 cycle-row-c label\n" +
        "PROPERTY 4 cycle-row-c text text replacement ${marker} · 丙\n" + "NODE 4 cycle-row-d label\n" +
        "PROPERTY 4 cycle-row-d text text replacement ${marker} · 丁\n" + "NODE 4 cycle-row-e label\n" +
        "PROPERTY 4 cycle-row-e text text replacement ${marker} · 戊\n" + "NODE 4 cycle-row-f label\n" +
        "PROPERTY 4 cycle-row-f text text replacement ${marker} · 己\n" + "END"
}

private func mixedResourceCycleAcceptedNode(window: CjguiComposableUiWindow, semanticId: String): ?CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return Some(node)
        }
    }
    return None
}

private func mixedResourceCycleAcceptedNodeByKey(window: CjguiComposableUiWindow, region: CjguiGeneratedUiWindowRegion,
    key: String): ?CjguiComposableUiLayoutNode {
    let nodeId = region.acceptedNodeIdForKey(key)
    if (nodeId <= 0) {
        return None
    }
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return Some(node)
        }
    }
    return None
}

private func mixedResourceCycleActionNode(window: CjguiComposableUiWindow, actionName: String): ?CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.actionName == actionName) {
            return Some(node)
        }
    }
    return None
}

/// Count only the generated keys declared by this workload. Generated layout
/// semantic ids are opaque component identities, so the business key must be
/// resolved through the region's accepted key-to-node-id map.
func mixedResourceCycleCountAcceptedNodesByKey(window: CjguiComposableUiWindow, region: CjguiGeneratedUiWindowRegion): (Int64, 
    Int64) {
    let keys = ["root", "cycle-scroll", "cycle-content", "cycle-card", "cycle-image", "cycle-title", "cycle-row-a",
        "cycle-row-b", "cycle-row-c", "cycle-row-d", "cycle-row-e", "cycle-row-f"]
    let acceptedIds = HashSet<Int64>()
    for (key in keys) {
        let nodeId = region.acceptedNodeIdForKey(key)
        if (nodeId > 0) {
            let _ = acceptedIds.add(nodeId)
        }
    }
    let effectNodeId = region.acceptedNodeIdForKey("cycle-card")
    var generatedCount = Int64(0)
    var effectGroupCount = Int64(0)
    for (node in window.acceptedSceneNodes()) {
        if (acceptedIds.contains(node.nodeId)) {
            generatedCount += 1
            if (node.nodeId == effectNodeId && node.style.effectGroup.isSome()) {
                effectGroupCount += 1
            }
        }
    }
    return (generatedCount, effectGroupCount)
}

/// Close one resource-cycle window through its ordinary UI-document discard
/// decision. A refused request must first publish the real guard action; after
/// dispatch, this waits for the application to retire the window.
func mixedResourceCycleDiscardUiAndClose(application: CjguiMacosApplication, controller: MixedFormController,
    identifier: CjguiMacosApplicationWindowIdentifier): (Bool, String) {
    let window = match (application.window(identifier)) {
        case Some(value) => value
        case None => return (false, "window_not_live")
    }
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
    if (application.requestClose(identifier)) {
        return (false, "ui_discard_guard_not_required")
    }
    var dispatched = false
    var dispatchCloseApproved = false
    let _ = window.refresh()
    while (MonoTime.now() < deadline) {
        if (let Some(node) <- mixedResourceCycleActionNode(window, "UI_CLOSE_DISCARD")) {
            let outcome = controller.applyUiEvent(
                CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0,
                    window.windowProgress().acceptedSceneVersion))
            if (!outcome.didApply) {
                return (false, "ui_discard_action_refused")
            }
            dispatchCloseApproved = outcome.shouldClose
            dispatched = true
            break
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            return (false, "application_closed_before_ui_discard")
        }
    }
    if (!dispatched) {
        return (false, "ui_discard_guard_not_published")
    }
    // The app-owned discard action is dispatched directly here, so its normal
    // window event adapter does not get a chance to hand the close decision to
    // the application host. Ask the host to re-evaluate the accepted discard
    // and retire the participant through its ordinary close path.
    let closeAccepted = application.requestClose(identifier)
    if (!closeAccepted && window.isOpen()) {
        return (false, "ui_discard_host_close_refused_dispatch_should_close_${dispatchCloseApproved}")
    }
    while (MonoTime.now() < deadline) {
        if (application.window(identifier).isNone()) {
            return (true, "closed")
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            return if (application.window(identifier).isNone()) {
                (true, "closed")
            } else {
                (false, "application_closed_before_window_retired")
            }
        }
    }
    return (false, "window_retirement_timeout")
}

/// Move the app's ordinary outer viewport until the generated work region is
/// fully within its accepted clip. Generated ids are opaque component ids, so
/// the root is resolved through the region's accepted key map. Scroll reveal
/// takes content coordinates; accepted bounds are viewport-relative, so add
/// the viewport's accepted offset before requesting the reveal.
private func mixedResourceCycleRevealGenerated(application: CjguiMacosApplication, window: CjguiComposableUiWindow,
    controller: MixedFormController, diagnosticRows: ArrayList<String>): Bool {
    let root = match (mixedResourceCycleAcceptedNodeByKey(window, controller.region, "root")) {
        case Some(value) => value
        case None =>
            diagnosticRows.add(
                "CJGUI_RESOURCE_CYCLE_REVEAL stage=root_missing " +
                    "accepted_structure=${controller.region.acceptedStructureVersion()} " +
                    "scene_state=[${controller.region.sceneState()}]")
            return false
    }
    let outer = match (mixedResourceCycleAcceptedNode(window, "preset-scroll")) {
        case Some(value) => value
        case None =>
            diagnosticRows.add(
                "CJGUI_RESOURCE_CYCLE_REVEAL stage=outer_scroll_missing " +
                    "root_node=${root.nodeId} root_semantic=${root.semanticId}")
            return false
    }
    let viewport = match (outer.scrollViewport) {
        case Some(value) => value
        case None =>
            diagnosticRows.add(
                "CJGUI_RESOURCE_CYCLE_REVEAL stage=outer_viewport_missing " +
                    "outer_node=${outer.nodeId} outer_semantic=${outer.semanticId}")
            return false
    }
    let oldScene = window.windowProgress().acceptedSceneVersion
    let oldFrame = window.diagnosticSnapshot(maximumNodes: 128).submittedFrameIndex
    let start = root.bounds.y + viewport.acceptedOffset()
    let end = start + root.bounds.height
    let current = viewport.acceptedOffset()
    let visibleEnd = current + viewport.viewportExtent()
    let alreadyVisible = start >= current && end <= visibleEnd
    let requested = if (alreadyVisible) {
        false
    } else {
        viewport.reveal(start, end, margin: 8)
    }
    if (!alreadyVisible && !requested) {
        diagnosticRows.add(
            "CJGUI_RESOURCE_CYCLE_REVEAL stage=request_refused " +
                "root_node=${root.nodeId} root_semantic=${root.semanticId} bounds=${root.bounds.y}:" +
                "${root.bounds.height} clip=${root.clip.y}:${root.clip.height} " +
                "offset=${current} extent=${viewport.viewportExtent()} content=${viewport.contentExtent()}")
        return false
    }
    if (requested) {
        let _ = window.refresh()
    }
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
    while (MonoTime.now() < deadline) {
        let currentRoot = match (mixedResourceCycleAcceptedNodeByKey(window, controller.region, "root")) {
            case Some(value) => value
            case None =>
                let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
                if (!turn.isOpen) {
                    return false
                }
                continue
        }
        let diagnostic = window.diagnosticSnapshot(maximumNodes: 128)
        let fullyVisible = currentRoot.clip.y <= currentRoot.bounds.y && currentRoot.clip.y + currentRoot.clip.height >=
            currentRoot.bounds.y + currentRoot.bounds.height && currentRoot.clip.x <= currentRoot.bounds.x &&
            currentRoot.clip.x + currentRoot.clip.width >= currentRoot.bounds.x + currentRoot.bounds.width
        let offsetAccepted = viewport.acceptedOffset() == viewport.offset()
        let acceptedScene = window.windowProgress().acceptedSceneVersion
        let sceneAccepted = if (requested) {
            acceptedScene > oldScene
        } else {
            acceptedScene >= oldScene
        }
        let frameAdvanced = if (requested) {
            diagnostic.submittedFrameIndex > oldFrame
        } else {
            diagnostic.submittedFrameIndex >= oldFrame
        }
        let frameSettled = frameAdvanced && diagnostic.submittedFrameIndex == diagnostic.completedFrameIndex
        if (fullyVisible && offsetAccepted && sceneAccepted && frameSettled) {
            return true
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            return false
        }
    }
    let finalRoot = mixedResourceCycleAcceptedNodeByKey(window, controller.region, "root")
    let finalDiagnostic = window.diagnosticSnapshot(maximumNodes: 128)
    var finalNodeId = Int64(-1)
    var finalSemantic = "missing"
    var finalBoundsY = Int64(-1)
    var finalBoundsHeight = Int64(-1)
    var finalClipY = Int64(-1)
    var finalClipHeight = Int64(-1)
    if (let Some(value) <- finalRoot) {
        finalNodeId = value.nodeId
        finalSemantic = value.semanticId
        finalBoundsY = value.bounds.y
        finalBoundsHeight = value.bounds.height
        finalClipY = value.clip.y
        finalClipHeight = value.clip.height
    }
    diagnosticRows.add(
        "CJGUI_RESOURCE_CYCLE_REVEAL stage=timeout " +
            "requested=${requested} root_node=${finalNodeId} root_semantic=${finalSemantic} " +
            "root_bounds=${finalBoundsY}:${finalBoundsHeight} root_clip=${finalClipY}:${finalClipHeight} " +
            "offset=${viewport.acceptedOffset()} requested_offset=${viewport.offset()} " +
            "extent=${viewport.viewportExtent()} scene=${finalDiagnostic.acceptedSceneVersion} " +
            "submitted=${finalDiagnostic.submittedFrameIndex} completed=${finalDiagnostic.completedFrameIndex}")
    return false
}

private func mixedResourceCycleSubmit(application: CjguiMacosApplication, controller: MixedFormController,
    window: CjguiComposableUiWindow, structure: String, diagnosticRows: ArrayList<String>): Bool {
    let previousVersion = controller.region.acceptedStructureVersion()
    let result = controller.region.submitStructure(structure, previousVersion)
    let submissionState = "candidate_accepted=${result.candidateAccepted} accepted=${result.accepted} " +
        "reason=[${result.reason}] path=[${result.path}] version_before=${result.versionBefore} " +
        "version_after=${result.versionAfter} candidate_version=${result.candidateVersion} " +
        "scene_accepted=${result.sceneAccepted} candidate_token=${result.candidateToken} " +
        "accepted_version_now=${controller.region.acceptedStructureVersion()} " +
        "scene_state=[${controller.region.sceneState()}]"
    if (!result.candidateAccepted) {
        diagnosticRows.add("CJGUI_RESOURCE_CYCLE_SUBMIT_DIAGNOSTIC stage=rejected ${submissionState}")
        return false
    }
    // Candidate acceptance is the contract. `reason` describes refusal; it is
    // not a second acceptance bit. Keep unexpected text visible without
    // overriding the authoritative accepted flag.
    if (result.reason.size > 0) {
        diagnosticRows.add("CJGUI_RESOURCE_CYCLE_SUBMIT_DIAGNOSTIC stage=accepted_with_reason ${submissionState}")
    }
    let targetVersion = previousVersion + 1
    let _ = window.refresh()
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
    while (MonoTime.now() < deadline) {
        if (controller.region.acceptedStructureVersion() == targetVersion && controller.region.sceneState() ==
            "scene_accepted") {
            return true
        }
        if (controller.region.sceneState().startsWith("scene_rejected:")) {
            diagnosticRows.add(
                "CJGUI_RESOURCE_CYCLE_SUBMIT_DIAGNOSTIC stage=scene_rejected ${submissionState} " +
                    "target_version=${targetVersion} scene_state=[${controller.region.sceneState()}] " +
                    "native_status=${window.nativeStatus()}")
            return false
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            diagnosticRows.add(
                "CJGUI_RESOURCE_CYCLE_SUBMIT_DIAGNOSTIC stage=host_closed ${submissionState} " +
                    "target_version=${targetVersion}")
            return false
        }
    }
    diagnosticRows.add(
        "CJGUI_RESOURCE_CYCLE_SUBMIT_DIAGNOSTIC stage=scene_timeout ${submissionState} " +
            "target_version=${targetVersion} accepted_version=${controller.region.acceptedStructureVersion()} " +
            "scene_state=[${controller.region.sceneState()}]")
    return false
}

private func mixedResourceCycleReadSnapshot(application: CjguiMacosApplication, window: CjguiComposableUiWindow,
    transientController: ?MixedFormController, scrollOffset: Int64, imageState: String): MixedResourceCycleWindowSnapshot {
    let diagnostic = window.diagnosticSnapshot(maximumNodes: 128)
    var count = Int64(0)
    var effects = Int64(0)
    if (let Some(controller) <- transientController) {
        let (acceptedGeneratedCount, acceptedEffectGroupCount) = mixedResourceCycleCountAcceptedNodesByKey(window,
            controller.region)
        count = acceptedGeneratedCount
        effects = acceptedEffectGroupCount
    }
    return MixedResourceCycleWindowSnapshot(mixedReadResourceCycleImageSnapshot(),
        Int64(application.windowIdentifiers().size), diagnostic, count, effects, scrollOffset, imageState)
}

private func mixedResourceCycleSampleFields(label: String, sample: MixedResourceCycleWindowSnapshot): String {
    let image = sample.image
    return "label=${label} status=${image.status} schema=${image.schema} " +
        "active_sessions=${image.activeSessions} cache_entries=${image.cacheEntries} " +
        "cache_bytes=${image.cacheBytes} cache_budget=${image.cacheBudgetBytes} " +
        "inflight=${image.inFlight} pending=${image.pending} committed_refs=${image.committedTextureRefs} " +
        "subscribers=${image.subscribers} records=${image.records} decode_starts=${image.decodeStarts} " +
        "raw_subscribers=${image.rawSubscribers} live_allocations=${image.liveImageAllocations} " +
        "live_allocation_bytes=${image.liveImageAllocationBytes} " +
        "global_effect_inflight_targets=${image.effectInFlightTargets} " +
        "global_effect_inflight_bytes=${image.effectInFlightBytes} " +
        "global_effect_scope=${MIXED_RESOURCE_CYCLE_EFFECT_SCOPE} " +
        "windows=${sample.windowCount} scene=${sample.sceneVersion} submitted=${sample.submittedFrame} " +
        "completed=${sample.completedFrame} text_live=${sample.textLiveBytes} " +
        "reusable=${sample.reusableBytes} effect_live=${sample.effectLiveBytes} " +
        "effect_cache=${sample.effectCachedBytes} effect_inflight=${sample.effectInFlightBytes} " +
        "effect_passes=${sample.effectPassCount} generated_nodes=${sample.generatedNodeCount} " +
        "effect_nodes=${sample.effectGroupNodeCount} " + "scroll=${sample.scrollOffset} image_state=${sample.imageState}"
}

private func mixedResourceCycleSampleLine(label: String, sample: MixedResourceCycleWindowSnapshot): String {
    return "CJGUI_RESOURCE_CYCLE ${mixedResourceCycleSampleFields(label, sample)}"
}

private func mixedResourceCycleFailureLine(reason: String, sample: MixedResourceCycleWindowSnapshot): String {
    return "CJGUI_RESOURCE_CYCLE_FAILURE_SAMPLE reason=${reason} " + mixedResourceCycleSampleFields("failure", sample)
}

private func mixedResourceCycleReport(rows: ArrayList<String>, terminal: String, reason: String,
    sample: ?MixedResourceCycleWindowSnapshot): String {
    var output = ""
    for (row in rows) {
        output += row + "\n"
    }
    if (sample.isSome()) {
        output += mixedResourceCycleFailureLine(reason, sample.getOrThrow()) + "\n"
    }
    output += terminal + "\n"
    return output
}

private func mixedResourceCycleSignature(sample: MixedResourceCycleWindowSnapshot): String {
    let image = sample.image
    return "${image.activeSessions}:${image.inFlight}:${image.pending}:${image.committedTextureRefs}:" +
        "${image.subscribers}:${image.rawSubscribers}:${image.records}:${image.cacheEntries}:" +
        "${image.cacheBytes}:${image.liveImageAllocations}:${image.liveImageAllocationBytes}:" +
        "${image.effectInFlightTargets}:${image.effectInFlightBytes}:" +
        "${sample.textLiveBytes}:${sample.effectLiveBytes}:${sample.effectInFlightBytes}:" +
        "${sample.submittedFrame}:${sample.completedFrame}:${sample.imageState}"
}

private func mixedResourceCycleDrain(application: CjguiMacosApplication, anchor: CjguiComposableUiWindow): Bool {
    var previous = ""
    var stableTurns = Int64(0)
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
    while (MonoTime.now() < deadline) {
        let result = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!result.isOpen) {
            return false
        }
        let sample = mixedResourceCycleReadSnapshot(application, anchor, None, 0,
            mixedResourceCycleAnchorImageState(anchor))
        let image = sample.image
        let drained = image.status == 0 && image.schema == MIXED_RESOURCE_CYCLE_SCHEMA && image.inFlight == 0u64 &&
            image.pending == 0u64 && sample.effectLiveBytes >= 0 && sample.effectInFlightBytes == 0 &&
            image.effectInFlightTargets == 0u64 && image.effectInFlightBytes == 0u64 && sample.submittedFrame >= 0 &&
            sample.submittedFrame == sample.completedFrame
        if (drained) {
            let current = mixedResourceCycleSignature(sample)
            if (current == previous) {
                stableTurns += 1
            } else {
                stableTurns = 1
            }
            if (stableTurns >= MIXED_RESOURCE_CYCLE_STABLE_TURNS) {
                return true
            }
            previous = current
        } else {
            previous = ""
            stableTurns = 0
        }
    }
    return false
}

private func mixedResourceCycleWaitForActiveSample(application: CjguiMacosApplication,
    transient: CjguiComposableUiWindow, controller: MixedFormController, scrollOffset: Int64, imageState: String,
    initialRefs: UInt64, previousScene: Int64, previousFrame: Int64): ?MixedResourceCycleWindowSnapshot {
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
    while (MonoTime.now() < deadline) {
        let sample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), scrollOffset, imageState)
        if (controller.region.sceneState() == "scene_accepted" && sample.image.status == 0 && sample.image.schema ==
            MIXED_RESOURCE_CYCLE_SCHEMA && sample.image.committedTextureRefs > initialRefs && sample.textLiveBytes > 0 &&
            sample.effectLiveBytes > 0 && sample.effectPassCount > 0 && sample.effectInFlightBytes == 0 &&
            sample.sceneVersion > previousScene && sample.submittedFrame > previousFrame && sample.submittedFrame >= 0 &&
            sample.submittedFrame == sample.completedFrame) {
            return Some(sample)
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            return None
        }
    }
    return None
}

/// Run ten fixed accepted-window cycles inside the same macOS application and
/// domain. A warm anchor remains alive as the comparison owner. Each transient
/// scene replaces text/image/effect content, scrolls its accepted generated
/// viewport, removes the region and closes through the application host. The
/// returned text is a compact row stream for the external bounded validator.
private func mixedResourceCycleWarmAnchor(application: CjguiMacosApplication, controller: MixedFormController,
    anchor: CjguiComposableUiWindow, diagnosticRows: ArrayList<String>): ?MixedResourceCycleWindowSnapshot {
    if (!anchor.setWorkloadDiagnostics(true)) {
        diagnosticRows.add(
            "CJGUI_RESOURCE_CYCLE_WARM_DIAGNOSTIC stage=diagnostic_enable " +
                "accepted=false window_open=${anchor.isOpen()}")
        return None
    }
    let before = mixedResourceCycleReadSnapshot(application, anchor, Some(controller), 0,
        mixedResourceCycleAnchorImageState(anchor))
    let targetStructure = controller.region.acceptedStructureVersion() + 1
    if (!mixedResourceCycleSubmit(application, controller, anchor, mixedResourceCycleStructure(0, false), diagnosticRows)) {
        return None
    }
    let key = mixedResourceCycleImageKey(0, false)
    let path = mixedResourceCycleImagePath(key)
    let prepared = anchor.prepareImageResource(path, key, 1)
    if (prepared.state == "failed") {
        let observed = anchor.imageResourceStatus(path, key, 1)
        diagnosticRows.add(
            "CJGUI_RESOURCE_CYCLE_WARM_DIAGNOSTIC stage=image_prepare " +
                "prepare_state=${prepared.state} prepare_status=${prepared.nativeStatus} " +
                "observed_state=${observed.state} observed_status=${observed.nativeStatus} " +
                "key=${key} path=${path} version=1 scene=${anchor.windowProgress().acceptedSceneVersion} " +
                "accepted_structure=${controller.region.acceptedStructureVersion()} " +
                "region_scene=[${controller.region.sceneState()}]")
        return None
    }
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
    while (MonoTime.now() < deadline) {
        let imageState = anchor.imageResourceStatus(path, key, 1).state
        let sample = mixedResourceCycleReadSnapshot(application, anchor, Some(controller), 0, imageState)
        if (imageState == "ready" && controller.region.sceneState() == "scene_accepted" &&
            controller.region.acceptedStructureVersion() == targetStructure && sample.sceneVersion > before
            .sceneVersion && sample.submittedFrame > before.submittedFrame && sample.submittedFrame == sample
            .completedFrame && sample.image.committedTextureRefs > before.image.committedTextureRefs &&
            sample.image.liveImageAllocations > 0u64 && sample.image.liveImageAllocationBytes > 0u64 &&
            sample.generatedNodeCount > 0 && sample.effectGroupNodeCount > 0 && sample.effectPassCount > 0 &&
            sample.textLiveBytes > 0) {
            if (!mixedResourceCycleDrain(application, anchor)) {
                return None
            }
            return Some(
                mixedResourceCycleReadSnapshot(application, anchor, Some(controller), 0,
                    mixedResourceCycleAnchorImageState(anchor)))
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            return None
        }
    }
    return None
}

private func mixedResourceCycleFailure(rows: ArrayList<String>, reason: String,
    sample: ?MixedResourceCycleWindowSnapshot): (Bool, String) {
    return (false, mixedResourceCycleReport(rows, "CJGUI_RESOURCE_CYCLE_FAILURE reason=${reason}", reason, sample))
}

@When[os == "macOS"]
func mixedRunResourceCycleWorkload(application: CjguiMacosApplication, domain: PrintPresetDomain,
    anchorId: CjguiMacosApplicationWindowIdentifier, anchorController: MixedFormController): (Bool, String) {
    let rows = ArrayList<String>()
    let anchor = match (application.window(anchorId)) {
        case Some(value) => value
        case None => return mixedResourceCycleFailure(rows, "anchor_not_live", None)
    }
    let warm = mixedResourceCycleWarmAnchor(application, anchorController, anchor, rows)
    if (warm.isNone()) {
        let key = mixedResourceCycleImageKey(0, false)
        let path = mixedResourceCycleImagePath(key)
        let state = anchor.imageResourceStatus(path, key, 1).state
        let sample = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0, state)
        return mixedResourceCycleFailure(rows, "anchor_image_frame_not_ready", Some(sample))
    }
    let initial = warm.getOrThrow()
    if (initial.image.status != 0 || initial.image.schema != MIXED_RESOURCE_CYCLE_SCHEMA ||
        initial.image.committedTextureRefs == 0u64 || initial.image.liveImageAllocations == 0u64 ||
        initial.image.liveImageAllocationBytes == 0u64 || initial.imageState != "ready" ||
        initial.image.effectInFlightTargets != 0u64 || initial.image.effectInFlightBytes != 0u64 ||
        initial.submittedFrame != initial.completedFrame) {
        rows.add(mixedResourceCycleSampleLine("initial", initial))
        return mixedResourceCycleFailure(rows, "warm_anchor_baseline_incomplete", Some(initial))
    }
    rows.add(mixedResourceCycleSampleLine("initial", initial))
    var cycle = Int64(0)
    while (cycle < MIXED_RESOURCE_CYCLE_COUNT) {
        var lastSample = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
            mixedResourceCycleAnchorImageState(anchor))
        let controller = MixedFormController(domain, commandSurfaces: true)
        let opened = application.openWindow(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("资源周期 ${cycle + 1}", 720u32, 560u32,
                rangeTextEditDeltaDelivery: true))
        if (!opened.didOpen) {
            controller.closeResources()
            lastSample = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
                mixedResourceCycleAnchorImageState(anchor))
            return mixedResourceCycleFailure(rows, "open_failed_${cycle + 1}", Some(lastSample))
        }
        let identity = match (opened.identifier) {
            case Some(value) => value
            case None =>
                controller.closeResources()
                lastSample = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
                    mixedResourceCycleAnchorImageState(anchor))
                return mixedResourceCycleFailure(rows, "open_identity_missing_${cycle + 1}", Some(lastSample))
        }
        let transient = match (application.window(identity)) {
            case Some(value) => value
            case None =>
                controller.closeResources()
                lastSample = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
                    mixedResourceCycleAnchorImageState(anchor))
                return mixedResourceCycleFailure(rows, "opened_window_not_live_${cycle + 1}", Some(lastSample))
        }
        if (!transient.setWorkloadDiagnostics(true)) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, "not_ready")
            let closeAccepted = application.requestClose(identity)
            if (closeAccepted) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "diagnostic_probe_unavailable_${cycle + 1}", Some(lastSample))
        }
        let transientBaseline = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, "not_ready")
        lastSample = transientBaseline
        if (!mixedResourceCycleSubmit(application, controller, transient, mixedResourceCycleStructure(cycle, false),
            rows)) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, "not_ready")
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "scene_submit_failed_${cycle + 1}_${closeReason}", Some(lastSample))
        }
        if (!mixedResourceCycleRevealGenerated(application, transient, controller, rows)) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, "not_ready")
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "generated_region_not_revealed_${cycle + 1}_${closeReason}",
                Some(lastSample))
        }
        let resourceKey = mixedResourceCycleImageKey(cycle, false)
        let resourcePath = mixedResourceCycleImagePath(resourceKey)
        let prepared = transient.prepareImageResource(resourcePath, resourceKey, 1)
        if (prepared.state == "failed") {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, prepared.state)
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "image_prepare_failed_${cycle + 1}_${closeReason}", Some(lastSample))
        }
        var imageState = prepared.state
        var imageReady = false
        let imageDeadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
        while (MonoTime.now() < imageDeadline) {
            let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
            if (!turn.isOpen) {
                break
            }
            imageState = transient.imageResourceStatus(resourcePath, resourceKey, 1).state
            if (imageState == "ready") {
                imageReady = true
                break
            }
            if (imageState == "failed") {
                break
            }
        }
        if (!imageReady) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, imageState)
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "image_not_ready_${cycle + 1}_${imageState}_${closeReason}",
                Some(lastSample))
        }
        let cycleScroll = match (mixedResourceCycleAcceptedNodeByKey(transient, controller.region, "cycle-scroll")) {
            case Some(value) => value
            case None =>
                lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, imageState)
                let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
                if (closed) {
                    controller.closeResources()
                }
                return mixedResourceCycleFailure(rows, "scroll_node_missing_${cycle + 1}_${closeReason}",
                    Some(lastSample))
        }
        let viewport = match (cycleScroll.scrollViewport) {
            case Some(value) => value
            case None =>
                lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, imageState)
                let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
                if (closed) {
                    controller.closeResources()
                }
                return mixedResourceCycleFailure(rows, "scroll_viewport_missing_${cycle + 1}_${closeReason}",
                    Some(lastSample))
        }
        if (!viewport.scrollBy(48)) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller), 0, imageState)
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "scroll_not_accepted_${cycle + 1}_${closeReason}", Some(lastSample))
        }
        let _ = transient.refresh()
        var scrollAccepted = false
        let scrollDeadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_DRAIN_TIMEOUT_SECONDS * Duration.second
        while (MonoTime.now() < scrollDeadline) {
            let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
            if (!turn.isOpen) {
                break
            }
            if (viewport.acceptedOffset() > 0) {
                scrollAccepted = true
                break
            }
        }
        if (!scrollAccepted) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller),
                viewport.acceptedOffset(), imageState)
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "scroll_not_accepted_${cycle + 1}_${closeReason}", Some(lastSample))
        }
        let active = match (mixedResourceCycleWaitForActiveSample(application, transient, controller,
            viewport.acceptedOffset(), imageState, initial.image.committedTextureRefs, transientBaseline.sceneVersion,
            transientBaseline.submittedFrame)) {
            case Some(value) => value
            case None =>
                lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller),
                    viewport.acceptedOffset(), imageState)
                let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
                if (closed) {
                    controller.closeResources()
                }
                return mixedResourceCycleFailure(rows, "active_resources_did_not_settle_${cycle + 1}_${closeReason}",
                    Some(lastSample))
        }
        lastSample = active
        rows.add(mixedResourceCycleSampleLine("active-${cycle + 1}", active))
        if (active.image.status != 0 || active.image.activeSessions < initial.image.activeSessions + 1u64 ||
            active.generatedNodeCount < 5 || active.image.committedTextureRefs <= initial.image.committedTextureRefs ||
            active.effectGroupNodeCount <= 0 || active.effectPassCount <= 0 || active.textLiveBytes <= 0 ||
            active.scrollOffset <= 0) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller),
                viewport.acceptedOffset(), imageState)
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "active_workload_not_observed_${cycle + 1}_${closeReason}",
                Some(lastSample))
        }
        if (!mixedResourceCycleSubmit(application, controller, transient, mixedResourceCycleStructure(cycle, true), rows) ||
            !mixedResourceCycleSubmit(application, controller, transient,
            "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\nEND", rows)) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller),
                viewport.acceptedOffset(), imageState)
            let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
            if (closed) {
                controller.closeResources()
            }
            return mixedResourceCycleFailure(rows, "replacement_or_removal_failed_${cycle + 1}_${closeReason}",
                Some(lastSample))
        }
        let (closed, closeReason) = mixedResourceCycleDiscardUiAndClose(application, controller, identity)
        if (!closed) {
            lastSample = mixedResourceCycleReadSnapshot(application, transient, Some(controller),
                viewport.acceptedOffset(), imageState)
            return mixedResourceCycleFailure(rows, "close_not_settled_${cycle + 1}_${closeReason}", Some(lastSample))
        }
        controller.closeResources()
        if (!mixedResourceCycleDrain(application, anchor)) {
            lastSample = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
                mixedResourceCycleAnchorImageState(anchor))
            return mixedResourceCycleFailure(rows, "drain_failed_${cycle + 1}", Some(lastSample))
        }
        let drained = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
            mixedResourceCycleAnchorImageState(anchor))
        rows.add(mixedResourceCycleSampleLine("drained-${cycle + 1}", drained))
        if (drained.image.effectInFlightTargets != 0u64 || drained.image.effectInFlightBytes != 0u64) {
            return mixedResourceCycleFailure(rows, "global_effect_targets_not_drained_${cycle + 1}", Some(drained))
        }
        lastSample = drained
        cycle += 1
    }
    let final = mixedResourceCycleReadSnapshot(application, anchor, Some(anchorController), 0,
        mixedResourceCycleAnchorImageState(anchor))
    rows.add(mixedResourceCycleSampleLine("final", final))
    if (final.image.effectInFlightTargets != 0u64 || final.image.effectInFlightBytes != 0u64) {
        return mixedResourceCycleFailure(rows, "global_effect_targets_not_drained_final", Some(final))
    }
    return (true, mixedResourceCycleReport(rows, "CJGUI_RESOURCE_CYCLE_RESULT status=ok", "", None))
}
