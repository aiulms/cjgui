package cjgui

import cjgui_shared_operation_core.*
import std.time.*

// A normal CjguiComposableUiWindow load probe. The native test entry points
// drive the production FIFO and a real AppKit resize; the controller and all
// layout/staging/presentation work remain the shipped code path. This is not
// a public application protocol client and does not claim physical IME or
// VoiceOver input.
foreign {
    func cjgui_internal_renderer_test_enqueue_composable_event(
        session: UInt64, nodeIndex: UInt32, eventKind: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_resize_composable_window(
        session: UInt64, outResizeVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_image_stats(
        session: UInt64, outLoadedTextureCount: CPointer<UInt32>, outCacheEntryCount: CPointer<UInt32>,
        outDecodeCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_image_pipeline_stats(
        session: UInt64, outPathResolveMicros: CPointer<UInt64>, outCacheHitCount: CPointer<UInt64>,
        outAsyncLaunchCount: CPointer<UInt64>, outAsyncTotalMicros: CPointer<UInt64>,
        outPeakInFlight: CPointer<UInt32>, outPeakPending: CPointer<UInt32>,
        outCacheBytes: CPointer<UInt64>, outResourceCompletionVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_scene_update_stats(
        session: UInt64, outCommittedNodeCount: CPointer<UInt32>, outNodeUpdateCount: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_image_launch_gate(session: UInt64, held: UInt8): Int32
}

private class RenderResourceEfficiencyController <: CjguiComposableUiController {
    private var caption: String
    private var largeFont: Bool
    private var imageVisible: Bool
    private var imagePath: String
    private var imageId: String
    private var imageVersion: Int64
    private var scrollOffset: Int64
    private var revision: Int64

    init() {
        this.caption = "局部内容初始值"; this.largeFont = false; this.imageVisible = true
        this.imagePath = "runtime/cjgui/resources/composable-beacon.png"; this.imageId = "render-resource-image"
        this.imageVersion = 1; this.scrollOffset = 0; this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "render-resource-root", CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableText(2, "render-resource-caption", caption,
            CjguiComposableUiStyle(fontSize: if (largeFont) { 22.0 } else { 13.0 })))
        root.add(cjguiComposableTextInput(3, "render-resource-input", "局部内容", caption, 1,
            CjguiComposableUiStyle(fixedHeight: 32)))
        root.add(cjguiComposableButton(4, "render-resource-font", "切换字体", "TOGGLE_FONT", 2,
            CjguiComposableUiStyle(fixedHeight: 30)))
        root.add(cjguiComposableButton(5, "render-resource-image", "替换或移除图像", "TOGGLE_IMAGE", 3,
            CjguiComposableUiStyle(fixedHeight: 30)))
        if (imageVisible) {
            root.add(cjguiComposableImage(6, "render-resource-image-node", imagePath,
                CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 64, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
                imageResourceId: imageId, imageResourceVersion: imageVersion))
        }
        let scroll = cjguiComposableScrollArea(7, "render-resource-scroll", scrollOffset,
            CjguiComposableUiStyle(fixedHeight: 120, padding: 4, background: CjguiComposableUiColor(0.94, 0.95, 0.97, 1.0)))
        let content = cjguiComposableVertical(8, "render-resource-scroll-content", CjguiComposableUiStyle(gap: 2))
        var row: Int64 = 0
        while (row < 48) {
            content.add(cjguiComposableText(100 + row, "render-resource-row-${row}", "稳定滚动行 ${row}",
                CjguiComposableUiStyle(fixedHeight: 22)))
            row += 1
        }
        scroll.add(content); root.add(scroll)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 3) {
            caption = event.text; revision += 1; return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_FONT") {
            largeFont = !largeFont; revision += 1; return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_IMAGE") {
            imageVisible = !imageVisible
            if (imageVisible) { imageVersion += 1 }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && event.node.nodeId == 7) {
            scrollOffset = if (scrollOffset >= 360) { 0 } else { scrollOffset + 24 }
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
    public func useImageVersion(version: Int64): Unit { imageVisible = true; imageVersion = version; revision += 1 }
    public func useImage(path: String, version: Int64): Unit {
        useImageResource(path, "render-resource-image", version)
    }
    public func useImageResource(path: String, resourceId: String, version: Int64): Unit {
        imageVisible = true; imagePath = path; imageId = resourceId; imageVersion = version; revision += 1
    }
}

// Uses distinct logical IDs for one real raster so the per-session cache has
// to exercise its byte budget while every image remains visibly bound in the
// same ordinary window.
private class MultiImageResourceController <: CjguiComposableUiController {
    private let imageCount: Int64
    private let imagePath: String
    private var resourcesVisible: Bool
    private var revision: Int64
    init(imageCount: Int64, imagePath: String, resourcesVisible: Bool) {
        this.imageCount = imageCount; this.imagePath = imagePath
        this.resourcesVisible = resourcesVisible; this.revision = 1
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9000, "multi-image-resource-root", CjguiComposableUiStyle(padding: 4, gap: 1))
        if (resourcesVisible) {
            var index: Int64 = 0
            while (index < imageCount) {
                root.add(cjguiComposableImage(9100 + index, "multi-image-resource-node-${index}",
                    imagePath, CjguiComposableUiStyle(fixedWidth: 48, fixedHeight: 32),
                    imageResourceId: "multi-image-resource-${index}", imageResourceVersion: 1))
                index += 1
            }
        }
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
    public func revealResources(): Unit { resourcesVisible = true; revision += 1 }
}

private class ResourcePipelineObservation {
    let status: Int32
    let loaded: UInt32
    let cache: UInt32
    let decode: UInt32
    let launches: UInt64
    let completion: UInt64
    let submissions: Int64
    init(status: Int32, loaded: UInt32, cache: UInt32, decode: UInt32, launches: UInt64,
        completion: UInt64, submissions: Int64) {
        this.status = status; this.loaded = loaded; this.cache = cache; this.decode = decode
        this.launches = launches; this.completion = completion; this.submissions = submissions
    }
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

private func emitSample(kind: String, ordinal: Int64, elapsedMs: Int64, projection: CjguiSharedOperationWindowProjection): Unit {
    // Timing fields are separate snapshots: layout includes native text
    // measurement and the values must never be summed into `elapsedMs`.
    println("CJGUI_RENDER_RESOURCE_SAMPLE kind=${kind} ordinal=${ordinal} elapsed_ms=${elapsedMs} build_ms=${projection.lastBuildElapsedMs} layout_ms=${projection.lastLayoutElapsedMs} native_measurement_ms=${projection.lastNativeMeasurementElapsedMs} native_stage_submit_ms=${projection.lastNativeStageAndSubmitElapsedMs} measurement_calls=${projection.lastNativeMeasurementCallCount} gpu_micros=${projection.observedMetalGpuDurationMicros} submitted_frame=${projection.submittedFrameIndex} completed_frame=${projection.observedMetalCompletionFrameIndex}")
}

private func runNativeEventSamples(window: CjguiComposableUiWindow, kind: String, nodeIndex: UInt32,
    eventKind: UInt32, textPrefix: String): Bool {
    var ordinal: Int64 = 0
    while (ordinal < 30) {
        if (!enqueue(window, nodeIndex, eventKind, "${textPrefix}-${ordinal}")) { return false }
        let started = MonoTime.now()
        let result = window.pump(0u32)
        let elapsedMs = (MonoTime.now() - started).toMilliseconds()
        if (!result.isOpen || !result.didApplyHumanAction || window.nativeStatus() != CJGUI_INTERNAL_RENDERER_OK) { return false }
        emitSample(kind, ordinal, elapsedMs, window.windowProjection())
        ordinal += 1
    }
    return true
}

private func runResizeSamples(window: CjguiComposableUiWindow): Bool {
    var ordinal: Int64 = 0
    while (ordinal < 30) {
        var resizeVersion: UInt64 = 0
        let beforeSceneVersion = window.displayedSceneVersion()
        let started = MonoTime.now()
        let status = unsafe { cjgui_internal_renderer_test_resize_composable_window(window.testSessionToken(), inout resizeVersion) }
        let result = window.pump(0u32)
        let elapsedMs = (MonoTime.now() - started).toMilliseconds()
        if (status != CJGUI_INTERNAL_RENDERER_OK || resizeVersion == 0u64 || !result.isOpen ||
            window.displayedSceneVersion() <= beforeSceneVersion || window.nativeStatus() != CJGUI_INTERNAL_RENDERER_OK) { return false }
        emitSample("resize", ordinal, elapsedMs, window.windowProjection())
        ordinal += 1
    }
    return true
}

private func runIdleSamples(window: CjguiComposableUiWindow): Bool {
    let before = window.windowProjection()
    var ordinal: Int64 = 0
    while (ordinal < 30) {
        let started = MonoTime.now()
        let turn = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 8u32)
        let elapsedMs = (MonoTime.now() - started).toMilliseconds()
        let after = window.windowProjection()
        if (!turn.windowPumpResult.isOpen || turn.externalActionCount != 0 || after.buildPassCount != before.buildPassCount ||
            after.layoutPassCount != before.layoutPassCount || after.nativeSubmissionCount != before.nativeSubmissionCount) { return false }
        emitSample("idle", ordinal, elapsedMs, after)
        ordinal += 1
    }
    return true
}

private func verifyImageLifecycle(window: CjguiComposableUiWindow): Bool {
    // The final rebind is asynchronous. Wait for its real completion and let
    // the normal completion-generation refresh attach that texture before
    // observing the committed node/cache counts.
    if (!waitForImageState(window, "runtime/cjgui/resources/composable-beacon.png", "render-resource-image", 16, "ready")) {
        return false
    }
    var loaded: UInt32 = 0; var cache: UInt32 = 0; var decode: UInt32 = 0
    let status = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(), inout loaded, inout cache, inout decode)
    }
    println("CJGUI_RENDER_RESOURCE_IMAGE_STATS loaded=${loaded} cache_entries=${cache} decode_count=${decode}")
    // Initial image plus fifteen visible replacements. The LRU holds a
    // bounded reusable working set instead of purging each hidden version;
    // this beacon reaches the 32 MiB budget at five entries, so older
    // versions are deliberately re-decoded during the later churn. The
    // earlier A/B assertion separately proves a hot reuse before eviction.
    // Earlier cold-key timing samples deliberately evict this resource before
    // the lifecycle toggle series. Their decodes are part of the same real
    // session, so this remains a lower bound; the version-16 ready readback
    // above is the lifecycle-specific completion proof.
    return status == CJGUI_INTERNAL_RENDERER_OK && loaded == 1u32 && cache == 5u32 && decode >= 20u32
}

private func waitForImageState(window: CjguiComposableUiWindow, resourcePath: String, resourceId: String,
    resourceVersion: Int64, expected: String): Bool {
    var turns: Int64 = 0
    while (turns < 80) {
        if (window.imageResourceStatus(resourcePath, resourceId, resourceVersion).state == expected) {
            // `ready` is the native preparation fact. Let the same ordinary
            // window invalidation path consume its completion generation
            // before an image-node observation asserts the new texture.
            let _ = window.refreshIfNeeded()
            return true
        }
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        turns += 1
    }
    println("CJGUI_RESOURCE_PIPELINE_WAIT expected=${expected} actual=${window.imageResourceStatus(resourcePath, resourceId, resourceVersion).state} turns=${turns}")
    return false
}

/// Identical bounded wait, but deliberately leaves the completion generation
/// unconsumed so timing callers can measure the following normal scene
/// acceptance separately from request-to-ready.
private func waitForImageReadyBeforeSceneAcceptance(window: CjguiComposableUiWindow, resourcePath: String,
    resourceId: String, resourceVersion: Int64): Bool {
    var turns: Int64 = 0
    while (turns < 80) {
        if (window.imageResourceStatus(resourcePath, resourceId, resourceVersion).state == "ready") {
            return true
        }
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        turns += 1
    }
    println("CJGUI_RESOURCE_READY_TO_SCENE_WAIT actual=${window.imageResourceStatus(resourcePath, resourceId, resourceVersion).state} turns=${turns}")
    return false
}

private func resourcePipelineObservation(window: CjguiComposableUiWindow): ResourcePipelineObservation {
    var loaded: UInt32 = 0; var cache: UInt32 = 0; var decode: UInt32 = 0
    let imageStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(), inout loaded, inout cache, inout decode)
    }
    var resolve: UInt64 = 0; var hits: UInt64 = 0; var launches: UInt64 = 0; var total: UInt64 = 0
    var peakInFlight: UInt32 = 0; var peakPending: UInt32 = 0; var bytes: UInt64 = 0; var completion: UInt64 = 0
    let pipelineStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_pipeline_stats(window.testSessionToken(), inout resolve, inout hits,
            inout launches, inout total, inout peakInFlight, inout peakPending, inout bytes, inout completion)
    }
    let status = if (imageStatus == CJGUI_INTERNAL_RENDERER_OK) { pipelineStatus } else { imageStatus }
    return ResourcePipelineObservation(status, loaded, cache, decode, launches, completion,
        window.windowProjection().nativeSubmissionCount)
}

/// A cache eviction must remove only the reusable reference. Active nodes own
/// their already accepted textures, so later unrelated completions cannot
/// restart those resources or keep producing refreshes forever. The caller
/// runs this against both twelve generated 16px images and six full-size
/// 1254px images, exercising the entry and byte budgets independently.
private func verifyActiveImageCacheEvictionConverges(kind: String, imagePath: String, imageCount: Int64,
    maximumCacheEntries: UInt32): Bool {
    let controller = MultiImageResourceController(imageCount, imagePath, true)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { window.close(); return false }
    var previous = resourcePipelineObservation(window)
    var stableTurns: Int64 = 0
    var turns: Int64 = 0
    while (turns < 240) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        let current = resourcePipelineObservation(window)
        if (current.status != CJGUI_INTERNAL_RENDERER_OK) { window.close(); return false }
        if (current.loaded == UInt32(imageCount) && current.cache <= maximumCacheEntries &&
            current.launches == UInt64(imageCount) && current.decode == UInt32(imageCount) &&
            current.completion == UInt64(imageCount) && current.launches == previous.launches &&
            current.decode == previous.decode && current.completion == previous.completion &&
            current.submissions == previous.submissions) {
            stableTurns += 1
            if (stableTurns >= 16) {
                println("CJGUI_RESOURCE_ACTIVE_CACHE_CONVERGED kind=${kind} images=${imageCount} loaded=${current.loaded} cache=${current.cache} decodes=${current.decode} launches=${current.launches} completion=${current.completion} submissions=${current.submissions} stable_turns=${stableTurns}")
                window.close(); return true
            }
        } else {
            stableTurns = 0
        }
        previous = current
        turns += 1
    }
    let current = resourcePipelineObservation(window)
    println("CJGUI_RESOURCE_ACTIVE_CACHE_NOT_CONVERGED kind=${kind} images=${imageCount} loaded=${current.loaded} cache=${current.cache} decodes=${current.decode} launches=${current.launches} completion=${current.completion} submissions=${current.submissions} turns=${turns}")
    window.close()
    return false
}

/// A full bounded queue is back-pressure, not a bad URL. Every resource in a
/// visible ordinary scene must eventually receive fair admission as existing
/// loads complete; only an actual loader error may become `failed`.
private func verifyVisibleResourceBackPressureDrains(): Bool {
    let imagePath = "/private/tmp/cjgui-render-resource-efficiency/small-resource.png"
    let controller = MultiImageResourceController(24, imagePath, false)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { window.close(); return false }
    controller.revealResources()
    if (!window.refresh()) { window.close(); return false }
    // Scene staging synchronously admits four loaders and sixteen pending
    // records. Before the main run-loop processes their callbacks, hold the
    // next-start gate so this exact 4 + 16 + 4 saturation state is observable.
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) { window.close(); return false }
    var initialLoading: Int64 = 0; var initialBusy: Int64 = 0; var initialFailed: Int64 = 0
    var initialIndex: Int64 = 0
    while (initialIndex < 24) {
        let state = window.imageResourceStatus(imagePath, "multi-image-resource-${initialIndex}", 1).state
        if (state == "loading") { initialLoading += 1 }
        else if (state == "busy") { initialBusy += 1 }
        else if (state == "failed") { initialFailed += 1 }
        initialIndex += 1
    }
    if (initialLoading != 20 || initialBusy != 4 || initialFailed != 0 ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8) } !=
            CJGUI_INTERNAL_RENDERER_OK) {
        println("CJGUI_RESOURCE_VISIBLE_BACKPRESSURE_ADMISSION_REJECT loading=${initialLoading} busy=${initialBusy} failed=${initialFailed}")
        window.close(); return false
    }
    var turns: Int64 = 0
    while (turns < 320) {
        var ready: Int64 = 0; var loading: Int64 = 0; var busy: Int64 = 0; var failed: Int64 = 0
        var index: Int64 = 0
        while (index < 24) {
            let state = window.imageResourceStatus(imagePath,
                "multi-image-resource-${index}", 1).state
            if (state == "ready") { ready += 1 }
            else if (state == "loading") { loading += 1 }
            else if (state == "busy") { busy += 1 }
            else if (state == "failed") { failed += 1 }
            index += 1
        }
        if (failed > 0) {
            println("CJGUI_RESOURCE_VISIBLE_BACKPRESSURE_FAILED ready=${ready} loading=${loading} busy=${busy} failed=${failed} turns=${turns}")
            window.close(); return false
        }
        if (ready == 24 && loading == 0 && busy == 0) {
            // `ready` is native preparation. Consume the final completion
            // through the same ordinary refresh before reading the post-
            // commit cache budget; a staged candidate may temporarily retain
            // more reusable entries than the accepted cache permits.
            let _ = window.refreshIfNeeded()
            let pipeline = resourcePipelineObservation(window)
            if (pipeline.launches == 24u64 && pipeline.decode == 24u32 && pipeline.cache <= 8u32) {
                println("CJGUI_RESOURCE_VISIBLE_BACKPRESSURE_DRAINED initial_loading=${initialLoading} initial_busy=${initialBusy} ready=${ready} loading=${loading} busy=${busy} failed=${failed} launches=${pipeline.launches} decodes=${pipeline.decode} cache=${pipeline.cache} turns=${turns}")
                window.close(); return true
            }
        }
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        turns += 1
    }
    let pipeline = resourcePipelineObservation(window)
    println("CJGUI_RESOURCE_VISIBLE_BACKPRESSURE_TIMEOUT launches=${pipeline.launches} decodes=${pipeline.decode} cache=${pipeline.cache} turns=${turns}")
    window.close()
    return false
}

/// The image loader must not block a normal text intent. The test-only launch
/// gate holds actual decoding while the production window accepts a loading
/// scene, then releases the real MetalKit completion into the ordinary
/// refresh-if-needed path. It also proves that a prior explicit preload is
/// reused when the application returns to its first version.
private func verifyResponsiveImagePreparation(window: CjguiComposableUiWindow,
    controller: RenderResourceEfficiencyController): Bool {
    let imagePath = "runtime/cjgui/resources/composable-beacon.png"
    let imageId = "render-resource-image"
    if (!waitForImageState(window, imagePath, imageId, 1, "ready")) { return false }
    var initialLoaded: UInt32 = 0; var initialCache: UInt32 = 0; var initialDecode: UInt32 = 0
    let initialStats = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(), inout initialLoaded,
            inout initialCache, inout initialDecode)
    }
    if (initialStats != CJGUI_INTERNAL_RENDERER_OK || initialLoaded != 1u32 || initialDecode == 0u32) { return false }
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) { return false }
    let preload = window.prepareImageResource(imagePath, imageId, 2)
    if (preload.state != "loading") { return false }
    controller.useImageVersion(2)
    if (!window.refresh() || window.imageResourceStatus(imagePath, imageId, 2).state != "loading") { return false }
    if (!enqueue(window, 2u32, 28u32, "图片加载期间仍可输入")) { return false }
    let inputStarted = MonoTime.now()
    let inputDuringLoad = window.pump(0u32)
    let inputDuringLoadElapsedMs = (MonoTime.now() - inputStarted).toMilliseconds()
    if (!inputDuringLoad.didApplyHumanAction || !window.isOpen() ||
        window.imageResourceStatus(imagePath, imageId, 2).state != "loading") { return false }
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8) } !=
        CJGUI_INTERNAL_RENDERER_OK || !waitForImageState(window, imagePath, imageId, 2, "ready")) { return false }
    var readyLoaded: UInt32 = 0; var readyCache: UInt32 = 0; var readyDecode: UInt32 = 0
    let readyStats = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(), inout readyLoaded,
            inout readyCache, inout readyDecode)
    }
    if (readyStats != CJGUI_INTERNAL_RENDERER_OK || readyLoaded != 1u32 || readyDecode != initialDecode + 1u32) { return false }
    controller.useImageVersion(1)
    if (!window.refresh() || window.imageResourceStatus(imagePath, imageId, 1).state != "ready") { return false }
    var hotLoaded: UInt32 = 0; var hotCache: UInt32 = 0; var hotDecode: UInt32 = 0
    let hotStats = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(), inout hotLoaded,
            inout hotCache, inout hotDecode)
    }
    if (hotStats != CJGUI_INTERNAL_RENDERER_OK || hotLoaded != 1u32 || hotDecode != readyDecode || hotCache < 2u32) {
        return false
    }
    // Two queued versions model a controller overtaking a still-loading
    // image. v3 is no longer referenced when it completes; only v4 may wake
    // the normal window and replace its target texture.
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) { return false }
    let v3 = window.prepareImageResource(imagePath, imageId, 3)
    controller.useImageVersion(3)
    if (v3.state != "loading" || !window.refresh()) { return false }
    let v4 = window.prepareImageResource(imagePath, imageId, 4)
    controller.useImageVersion(4)
    if (v4.state != "loading" || !window.refresh()) { return false }
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8) } !=
        CJGUI_INTERNAL_RENDERER_OK || !waitForImageState(window, imagePath, imageId, 3, "ready") ||
        !waitForImageState(window, imagePath, imageId, 4, "ready") ||
        window.imageResourceStatus(imagePath, imageId, 4).state != "ready") { return false }
    controller.useImageVersion(1)
    if (!window.refresh() || window.imageResourceStatus(imagePath, imageId, 1).state != "ready") { return false }
    let settledV3 = window.imageResourceStatus(imagePath, imageId, 3).state
    let settledV4 = window.imageResourceStatus(imagePath, imageId, 4).state
    println("CJGUI_RESOURCE_PIPELINE preload=${preload.state} input_during_load=${inputDuringLoad.didApplyHumanAction} input_during_load_ms=${inputDuringLoadElapsedMs} ready_decode=${readyDecode} hot_decode=${hotDecode} ready_cache=${readyCache} hot_cache=${hotCache} superseded_v3=${settledV3} current_v4=${settledV4}")
    return true
}

/// A failed path stays honestly failed; correcting the application-owned
/// declaration creates a new resource key and returns through the same ready
/// completion path. No stale failed texture can be relabelled as the new one.
private func verifyFailedImageRecovery(window: CjguiComposableUiWindow,
    controller: RenderResourceEfficiencyController): Bool {
    let missingPath = "runtime/cjgui/resources/does-not-exist.png"
    let goodPath = "runtime/cjgui/resources/composable-beacon.png"
    let imageId = "render-resource-recovery"
    let failedStart = window.prepareImageResource(missingPath, imageId, 17)
    controller.useImageResource(missingPath, imageId, 17)
    let failedRefresh = window.refresh()
    let failedReady = if (failedRefresh) { waitForImageState(window, missingPath, imageId, 17, "failed") } else { false }
    if (failedStart.state != "loading" || !failedRefresh || !failedReady || !window.isOpen()) {
        println("CJGUI_RESOURCE_FAILURE_RECOVERY_REJECT failed_start=${failedStart.state} failed_refresh=${failedRefresh} failed_ready=${failedReady} open=${window.isOpen()} native=${window.nativeStatus()}")
        return false
    }
    let recoveredStart = window.prepareImageResource(goodPath, imageId, 17)
    controller.useImageResource(goodPath, imageId, 17)
    let recoveredRefresh = window.refresh()
    let recoveredReady = if (recoveredRefresh) { waitForImageState(window, goodPath, imageId, 17, "ready") } else { false }
    if (recoveredStart.state != "loading" || !recoveredRefresh || !recoveredReady || !window.isOpen()) {
        println("CJGUI_RESOURCE_FAILURE_RECOVERY_REJECT recovered_start=${recoveredStart.state} recovered_refresh=${recoveredRefresh} recovered_ready=${recoveredReady} open=${window.isOpen()} native=${window.nativeStatus()}")
        return false
    }
    controller.useImage(goodPath, 1)
    // The thirty cold samples intentionally exercise a bounded LRU, so the
    // original image may legitimately need a fresh async admission here. A
    // cache hit is an optimization, not the recovery contract.
    if (!window.refresh() || !waitForImageState(window, goodPath, "render-resource-image", 1, "ready")) { return false }
    println("CJGUI_RESOURCE_FAILURE_RECOVERY failed=${window.imageResourceStatus(missingPath, imageId, 17).state} recovered=${window.imageResourceStatus(goodPath, imageId, 17).state}")
    return true
}

/// Request-to-ready begins before admission and ends only after the native
/// state readback is `ready`. Cold samples use unique keys; hot samples
/// alternate two preloaded keys. Neither case treats `pump` return as image
/// completion.
private func verifyRequestToReadySamples(window: CjguiComposableUiWindow,
    controller: RenderResourceEfficiencyController): Bool {
    let imagePath = "runtime/cjgui/resources/composable-beacon.png"
    var ordinal: Int64 = 0
    while (ordinal < 30) {
        let imageId = "request-ready-cold-${ordinal}"
        let started = MonoTime.now()
        if (window.prepareImageResource(imagePath, imageId, 1).state != "loading") { return false }
        controller.useImageResource(imagePath, imageId, 1)
        if (!window.refresh() || !waitForImageReadyBeforeSceneAcceptance(window, imagePath, imageId, 1)) { return false }
        println("CJGUI_RESOURCE_REQUEST_TO_READY kind=cold ordinal=${ordinal} elapsed_ms=${(MonoTime.now() - started).toMilliseconds()}")
        let beforeSubmission = window.windowProjection().nativeSubmissionCount
        let sceneStarted = MonoTime.now()
        if (!window.refreshIfNeeded() || window.windowProjection().nativeSubmissionCount <= beforeSubmission) { return false }
        println("CJGUI_RESOURCE_READY_TO_SCENE kind=cold ordinal=${ordinal} elapsed_ms=${(MonoTime.now() - sceneStarted).toMilliseconds()}")
        ordinal += 1
    }
    let hotA = "request-ready-hot-a"
    let hotB = "request-ready-hot-b"
    if (window.prepareImageResource(imagePath, hotA, 1).state != "loading" ||
        !waitForImageReadyBeforeSceneAcceptance(window, imagePath, hotA, 1) ||
        window.prepareImageResource(imagePath, hotB, 1).state != "loading" ||
        !waitForImageReadyBeforeSceneAcceptance(window, imagePath, hotB, 1)) { return false }
    ordinal = 0
    while (ordinal < 30) {
        let imageId = if (ordinal % 2 == 0) { hotA } else { hotB }
        let started = MonoTime.now()
        controller.useImageResource(imagePath, imageId, 1)
        let beforeSubmission = window.windowProjection().nativeSubmissionCount
        if (!window.refresh() || !waitForImageReadyBeforeSceneAcceptance(window, imagePath, imageId, 1)) { return false }
        println("CJGUI_RESOURCE_REQUEST_TO_READY kind=hot ordinal=${ordinal} elapsed_ms=${(MonoTime.now() - started).toMilliseconds()}")
        if (window.windowProjection().nativeSubmissionCount <= beforeSubmission) { return false }
        // The resource was ready before this controller revision. Its scene
        // acceptance is the `refresh` above, so retain only that synchronous
        // normal-path interval rather than inventing a loader completion.
        println("CJGUI_RESOURCE_READY_TO_SCENE kind=hot ordinal=${ordinal} elapsed_ms=${(MonoTime.now() - started).toMilliseconds()}")
        ordinal += 1
    }
    return true
}

/// Input remains owned by the controller while a bounded batch of real image
/// requests is held in loading/busy state. Each sample is a completed native
/// FIFO input turn, not merely an enqueue acknowledgement.
private func verifyLoadingInputSamples(window: CjguiComposableUiWindow,
    controller: RenderResourceEfficiencyController): Bool {
    let imagePath = "/private/tmp/cjgui-render-resource-efficiency/small-resource.png"
    let imageId = "loading-input-resource"
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) { return false }
    var ordinal: Int64 = 0
    while (ordinal < 30) {
        let version = 100 + ordinal
        let preparation = window.prepareImageResource(imagePath, imageId, version)
        controller.useImageResource(imagePath, imageId, version)
        if ((preparation.state != "loading" && preparation.state != "busy") || !window.refresh() ||
            !enqueue(window, 2u32, 28u32, "加载中输入-${ordinal}")) {
            println("CJGUI_RESOURCE_LOADING_INPUT_REJECT stage=admit ordinal=${ordinal} preparation=${preparation.state} open=${window.isOpen()} native=${window.nativeStatus()}")
            let _ = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8) }
            return false
        }
        let started = MonoTime.now()
        let turn = window.pump(0u32)
        let state = window.imageResourceStatus(imagePath, imageId, version).state
        if (!turn.isOpen || !turn.didApplyHumanAction || (state != "loading" && state != "busy") ||
            window.nativeStatus() != CJGUI_INTERNAL_RENDERER_OK) {
            println("CJGUI_RESOURCE_LOADING_INPUT_REJECT stage=pump ordinal=${ordinal} open=${turn.isOpen} applied=${turn.didApplyHumanAction} state=${state} native=${window.nativeStatus()}")
            let _ = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8) }
            return false
        }
        println("CJGUI_RESOURCE_LOADING_INPUT ordinal=${ordinal} elapsed_ms=${(MonoTime.now() - started).toMilliseconds()} state=${state}")
        ordinal += 1
    }
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8) } !=
        CJGUI_INTERNAL_RENDERER_OK || !waitForImageState(window, imagePath, imageId, 129, "ready")) { return false }
    return true
}

private func verifyResourcePipelineAccounting(window: CjguiComposableUiWindow): Bool {
    var pathResolve: UInt64 = 0; var cacheHits: UInt64 = 0; var launches: UInt64 = 0; var asyncTotal: UInt64 = 0
    var peakInFlight: UInt32 = 0; var peakPending: UInt32 = 0; var cacheBytes: UInt64 = 0; var completionVersion: UInt64 = 0
    let status = unsafe {
        cjgui_internal_renderer_test_composable_image_pipeline_stats(window.testSessionToken(), inout pathResolve,
            inout cacheHits, inout launches, inout asyncTotal, inout peakInFlight, inout peakPending,
            inout cacheBytes, inout completionVersion)
    }
    let projection = window.windowProjection()
    println("CJGUI_RESOURCE_PIPELINE_TIMING path_resolve_us=${pathResolve} cache_hits=${cacheHits} async_launches=${launches} metalkit_url_loader_total_us=${asyncTotal} peak_inflight=${peakInFlight} peak_pending=${peakPending} cache_bytes=${cacheBytes} completion_version=${completionVersion} scene_stage_submit_ms=${projection.lastNativeStageAndSubmitElapsedMs} readback_boundary=focused_native_diagnostic")
    // MetalKit owns file read/decode/texture creation/upload as one async URL
    // loader interval. This probe records that interval faithfully instead of
    // inventing unsupported sub-timings; cache/queue and scene submission are
    // separately observed above.
    return status == CJGUI_INTERNAL_RENDERER_OK && launches >= 17u64 && asyncTotal > 0u64 && cacheHits >= 2u64 &&
        peakInFlight <= 4u32 && peakPending <= 16u32 && cacheBytes > 0u64 && cacheBytes <= 32u64 * 1024u64 * 1024u64 &&
        completionVersion > 0u64
}

/// A loader completion retains only the scalar session generation and key.
/// Closing its isolated window before completion must make that callback a
/// no-op; another normal window continues to pump its ordinary AppKit turn.
private func verifyLateImageCompletionIgnored(liveWindow: CjguiComposableUiWindow): Bool {
    let controller = RenderResourceEfficiencyController()
    let retiringWindow = CjguiComposableUiWindow(controller)
    let imagePath = "runtime/cjgui/resources/composable-beacon.png"
    let imageId = "late-close-image"
    if (!retiringWindow.start() || !waitForImageState(retiringWindow, imagePath, "render-resource-image", 1, "ready") ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(retiringWindow.testSessionToken(), 1u8) } !=
            CJGUI_INTERNAL_RENDERER_OK) { return false }
    let preload = retiringWindow.prepareImageResource(imagePath, imageId, 2)
    controller.useImage(imagePath, 2)
    if (preload.state != "loading" || !retiringWindow.refresh() ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(retiringWindow.testSessionToken(), 0u8) } !=
            CJGUI_INTERNAL_RENDERER_OK) { return false }
    retiringWindow.close()
    var turn: Int64 = 0
    while (turn < 12) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(liveWindow, turnBudgetMs: 4u32)
        turn += 1
    }
    let retired = retiringWindow.imageResourceStatus(imagePath, imageId, 2)
    let live = liveWindow.imageResourceStatus(imagePath, "render-resource-image", 1)
    println("CJGUI_RESOURCE_LATE_CLOSE retired_status=${retired.nativeStatus} live_state=${live.state} live_open=${liveWindow.isOpen()}")
    return retired.nativeStatus == CJGUI_INTERNAL_RENDERER_INVALID_SESSION && liveWindow.isOpen() && live.state == "ready"
}

private func nativeNodeUpdateCount(window: CjguiComposableUiWindow): Int64 {
    var nodeCount: UInt32 = 0; var updateCount: UInt64 = 0
    let status = unsafe {
        cjgui_internal_renderer_test_composable_scene_update_stats(
            window.testSessionToken(), inout nodeCount, inout updateCount
        )
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Int64(updateCount) } else { -1 }
}

private func emitNodeWriteDelta(kind: String, before: Int64, after: Int64): Bool {
    println("CJGUI_RENDER_RESOURCE_NODE_WRITES kind=${kind} before=${before} after=${after} delta=${after - before}")
    return before >= 0 && after >= before
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = RenderResourceEfficiencyController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 3 }
    // One short warmup makes shader/text system setup distinct from the 30
    // measured samples in every category.
    let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 8u32)
    let responsiveOk = verifyResponsiveImagePreparation(window, controller)
    let loadingInputOk = responsiveOk && verifyLoadingInputSamples(window, controller)
    let requestToReadyOk = loadingInputOk && verifyRequestToReadySamples(window, controller)
    let recoveryOk = requestToReadyOk && verifyFailedImageRecovery(window, controller)
    let lateCompletionOk = recoveryOk && verifyLateImageCompletionIgnored(window)
    let activeSmallCacheConverges = lateCompletionOk && verifyActiveImageCacheEvictionConverges(
        "small", "/private/tmp/cjgui-render-resource-efficiency/small-resource.png", 12, 8u32)
    let activeBigCacheConverges = activeSmallCacheConverges && verifyActiveImageCacheEvictionConverges(
        "big", "runtime/cjgui/resources/composable-beacon.png", 6, 5u32)
    let visibleBackPressureDrains = activeBigCacheConverges && verifyVisibleResourceBackPressureDrains()
    let beforeContent = nativeNodeUpdateCount(window)
    let contentOk = visibleBackPressureDrains && runNativeEventSamples(window, "content", 2u32, 28u32, "局部内容")
    let afterContent = nativeNodeUpdateCount(window)
    let contentWritesOk = emitNodeWriteDelta("content", beforeContent, afterContent)
    let fontOk = contentOk && contentWritesOk && runNativeEventSamples(window, "font", 3u32, 27u32, "")
    let afterFont = nativeNodeUpdateCount(window)
    let fontWritesOk = emitNodeWriteDelta("font", afterContent, afterFont)
    let imageOk = fontOk && fontWritesOk && runNativeEventSamples(window, "image_remove_rebind", 4u32, 27u32, "")
    let afterImage = nativeNodeUpdateCount(window)
    let imageWritesOk = emitNodeWriteDelta("image_remove_rebind", afterFont, afterImage)
    let imageLifecycleOk = imageOk && imageWritesOk && verifyImageLifecycle(window)
    let pipelineAccountingOk = imageLifecycleOk && verifyResourcePipelineAccounting(window)
    let scrollOk = pipelineAccountingOk && runNativeEventSamples(window, "scroll", 6u32, 30u32, "")
    let afterScroll = nativeNodeUpdateCount(window)
    let scrollWritesOk = emitNodeWriteDelta("scroll", afterImage, afterScroll)
    let resizeOk = scrollOk && scrollWritesOk && runResizeSamples(window)
    let afterResize = nativeNodeUpdateCount(window)
    let resizeWritesOk = emitNodeWriteDelta("resize", afterScroll, afterResize)
    let idleOk = resizeOk && resizeWritesOk && runIdleSamples(window)
    let afterIdle = nativeNodeUpdateCount(window)
    let idleWritesOk = emitNodeWriteDelta("idle", afterResize, afterIdle)
    window.close()
    if (!idleOk || !idleWritesOk) { return 4 }
    println("CJGUI_RENDER_RESOURCE_PROBE passed=true warmup=1 samples_per_kind=30")
    return 0
}
