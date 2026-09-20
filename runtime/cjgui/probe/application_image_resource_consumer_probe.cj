package cjgui

// Normal-consumer image lifecycle probe.  Every image is declared through the
// ordinary Cangjie scene API; this file never receives a native texture or
// invokes a private renderer operation.  The test-only scalar stats are used
// only to prove decode/cache/lifecycle facts around the normal scene boundary.
foreign {
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
    func cjgui_internal_renderer_test_set_composable_image_launch_gate(session: UInt64, held: UInt8): Int32
}

private let BLUE_IMAGE = "runtime/cjgui/resources/composable-beacon.png"
private let CORAL_IMAGE = "runtime/cjgui/resources/composable-beacon-coral.png"
private let MISSING_IMAGE = "/private/tmp/cjgui-application-image-resource-missing.png"

private class ApplicationImageController <: CjguiComposableUiController {
    private var imagePath: String
    private var imageVersion: Int64
    private var revision: Int64
    private var visible: Bool
    private let title: String

    init(title: String, imagePath: String, imageVersion: Int64) {
        this.title = title
        this.imagePath = imagePath
        this.imageVersion = imageVersion
        this.revision = 1
        this.visible = false
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "application-image-root-${title}",
            CjguiComposableUiStyle(padding: 8, gap: 4))
        root.add(cjguiComposableText(2, "application-image-title-${title}",
            "应用图片消费者 ${title} v${imageVersion}", CjguiComposableUiStyle(fixedHeight: 22)))
        if (visible) {
            root.add(cjguiComposableImage(3, "application-image-node-${title}", imagePath,
                CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64),
                imageResourceId: "application-shared-beacon", imageResourceVersion: imageVersion))
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

    public func useImage(path: String, version: Int64): Unit {
        imagePath = path
        imageVersion = version
        visible = true
        revision += 1
    }

    public func showImage(): Unit {
        visible = true
        revision += 1
    }

    public func removeImage(): Unit {
        visible = false
        revision += 1
    }

    public func currentPath(): String { return imagePath }
    public func currentVersion(): Int64 { return imageVersion }
}

private class ImageStats {
    let status: Int32
    let loaded: UInt32
    let cacheEntries: UInt32
    let decodes: UInt32
    let launches: UInt64
    let cacheHits: UInt64
    let completions: UInt64
    let cacheBytes: UInt64
    init(status: Int32, loaded: UInt32, cacheEntries: UInt32, decodes: UInt32,
        launches: UInt64, cacheHits: UInt64, completions: UInt64, cacheBytes: UInt64) {
        this.status = status
        this.loaded = loaded
        this.cacheEntries = cacheEntries
        this.decodes = decodes
        this.launches = launches
        this.cacheHits = cacheHits
        this.completions = completions
        this.cacheBytes = cacheBytes
    }
}

private func readStats(window: CjguiComposableUiWindow): ImageStats {
    var loaded: UInt32 = 0
    var cacheEntries: UInt32 = 0
    var decodes: UInt32 = 0
    var resolveMicros: UInt64 = 0
    var cacheHits: UInt64 = 0
    var launches: UInt64 = 0
    var asyncMicros: UInt64 = 0
    var peakInFlight: UInt32 = 0
    var peakPending: UInt32 = 0
    var cacheBytes: UInt64 = 0
    var completions: UInt64 = 0
    let imageStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(
            window.testSessionToken(), inout loaded, inout cacheEntries, inout decodes)
    }
    let pipelineStatus = unsafe {
        cjgui_internal_renderer_test_composable_image_pipeline_stats(
            window.testSessionToken(), inout resolveMicros, inout cacheHits, inout launches,
            inout asyncMicros, inout peakInFlight, inout peakPending, inout cacheBytes, inout completions)
    }
    let status = if (imageStatus != CJGUI_INTERNAL_RENDERER_OK) { imageStatus } else { pipelineStatus }
    return ImageStats(status, loaded, cacheEntries, decodes, launches, cacheHits, completions, cacheBytes)
}

private func state(window: CjguiComposableUiWindow, controller: ApplicationImageController): String {
    return window.imageResourceStatus(controller.currentPath(), "application-shared-beacon",
        controller.currentVersion()).state
}

private func waitForState(window: CjguiComposableUiWindow, controller: ApplicationImageController,
    expected: String, phase: String): Bool {
    var turn: Int64 = 0
    while (turn < 240) {
        let current = state(window, controller)
        if (current == expected) {
            let _ = window.refreshIfNeeded()
            let stats = readStats(window)
            println("CJGUI_APPLICATION_IMAGE_STATE phase=${phase} expected=${expected} actual=${current} path=${controller.currentPath()} version=${controller.currentVersion()} loaded=${stats.loaded} cache=${stats.cacheEntries} decode=${stats.decodes} launches=${stats.launches} cache_hits=${stats.cacheHits} completions=${stats.completions} cache_bytes=${stats.cacheBytes}")
            return true
        }
        let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        if (!turnResult.windowPumpResult.isOpen) { return false }
        turn += 1
    }
    println("CJGUI_APPLICATION_IMAGE_STATE_TIMEOUT phase=${phase} expected=${expected} actual=${state(window, controller)} path=${controller.currentPath()} version=${controller.currentVersion()} turns=${turn}")
    return false
}

private func printPhase(phase: String, windowA: CjguiComposableUiWindow, controllerA: ApplicationImageController,
    windowB: CjguiComposableUiWindow, controllerB: ApplicationImageController): ImageStats {
    let a = readStats(windowA)
    let b = readStats(windowB)
    // Decode ownership is session-local and can be summed. Pipeline counters
    // belong to the shared application domain, so exposing two snapshots is
    // useful but summing them would falsely double-count one real load.
    println("CJGUI_APPLICATION_IMAGE_PHASE phase=${phase} a_state=${state(windowA, controllerA)} b_state=${state(windowB, controllerB)} a_version=${controllerA.currentVersion()} b_version=${controllerB.currentVersion()} a_loaded=${a.loaded} b_loaded=${b.loaded} a_decode=${a.decodes} b_decode=${b.decodes} total_decode=${UInt64(a.decodes) + UInt64(b.decodes)} domain_snapshot_a_loads=${a.launches} domain_snapshot_b_loads=${b.launches} domain_snapshot_a_cache_hits=${a.cacheHits} domain_snapshot_b_cache_hits=${b.cacheHits} domain_snapshot_a_completions=${a.completions} domain_snapshot_b_completions=${b.completions} domain_snapshot_a_cache_bytes=${a.cacheBytes} domain_snapshot_b_cache_bytes=${b.cacheBytes}")
    return a
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controllerA = ApplicationImageController("A", BLUE_IMAGE, 1)
    let controllerB = ApplicationImageController("B", BLUE_IMAGE, 1)
    let windowA = CjguiComposableUiWindow(controllerA)
    let windowB = CjguiComposableUiWindow(controllerB)
    if (!windowA.start()) { return 3 }
    if (!windowB.start()) { windowA.close(); return 4 }
    let tokenA = windowA.testSessionToken()
    let tokenB = windowB.testSessionToken()
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) {
        windowB.close(); windowA.close(); return 5
    }
    controllerA.showImage()
    controllerB.showImage()
    let requestA = windowA.prepareImageResource(BLUE_IMAGE, "application-shared-beacon", 1)
    let requestB = windowB.prepareImageResource(BLUE_IMAGE, "application-shared-beacon", 1)
    if (requestA.state != "loading" || requestB.state != "loading" || !windowA.refresh() || !windowB.refresh()) {
        let _ = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 0u8) }
        let _ = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 0u8) }
        windowB.close(); windowA.close(); return 5
    }
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 0u8) } !=
        CJGUI_INTERNAL_RENDERER_OK || !waitForState(windowA, controllerA, "ready", "initial_a") ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 0u8) } !=
        CJGUI_INTERNAL_RENDERER_OK || !waitForState(windowB, controllerB, "ready", "initial_b")) {
        windowB.close(); windowA.close(); return 5
    }
    let initial = printPhase("initial_shared", windowA, controllerA, windowB, controllerB)
    let initialB = readStats(windowB)
    // One application-domain decode/launch is the required post-fix result.
    // The current per-window owner is intentionally expected to print 2 here;
    // the shell runner preserves that output as the historical RED baseline.
    let sharedInitial = UInt64(initial.decodes) + UInt64(initialB.decodes) == 1u64
    if (!sharedInitial) {
        println("CJGUI_APPLICATION_IMAGE_EXPECTED shared_initial_decode=1 actual=${UInt64(initial.decodes) + UInt64(initialB.decodes)}")
    }

    controllerA.useImage(CORAL_IMAGE, 2)
    if (!windowA.refresh() || !waitForState(windowA, controllerA, "ready", "version_a_coral")) {
        windowB.close(); windowA.close(); return 6
    }
    if (state(windowB, controllerB) != "ready") { windowB.close(); windowA.close(); return 7 }
    let beforeBVersion = readStats(windowB)
    controllerB.useImage(CORAL_IMAGE, 2)
    if (!windowB.refresh() || !waitForState(windowB, controllerB, "ready", "version_b_coral")) {
        windowB.close(); windowA.close(); return 8
    }
    let afterVersions = printPhase("version_replace", windowA, controllerA, windowB, controllerB)
    if (afterVersions.status != CJGUI_INTERNAL_RENDERER_OK || state(windowA, controllerA) != "ready" ||
        state(windowB, controllerB) != "ready" || afterVersions.loaded != 1u32 || beforeBVersion.loaded != 1u32) {
        windowB.close(); windowA.close(); return 9
    }

    // A real bad path is a terminal failed state for this version. Recovery
    // uses a new explicit version and the normal image declaration path.
    controllerB.useImage(MISSING_IMAGE, 3)
    if (!windowB.refresh() || !waitForState(windowB, controllerB, "failed", "failure_missing")) {
        windowB.close(); windowA.close(); return 10
    }
    controllerB.useImage(CORAL_IMAGE, 4)
    if (!windowB.refresh() || !waitForState(windowB, controllerB, "ready", "failure_recovery")) {
        windowB.close(); windowA.close(); return 11
    }
    let recovered = printPhase("failure_recovery", windowA, controllerA, windowB, controllerB)
    if (recovered.status != CJGUI_INTERNAL_RENDERER_OK || state(windowB, controllerB) != "ready") {
        windowB.close(); windowA.close(); return 12
    }

    // Retire A while B remains a live normal consumer.  A's late completion
    // must not revive A or mutate B's accepted scene/resource state.
    let beforeCloseB = windowB.windowProjection()
    windowA.close()
    var bPumpOpen = true
    var turns: Int64 = 0
    while (turns < 12) {
        let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(windowB, turnBudgetMs: 4u32)
        if (!turnResult.windowPumpResult.isOpen) { bPumpOpen = false; break }
        turns += 1
    }
    let afterCloseB = readStats(windowB)
    let afterCloseProjection = windowB.windowProjection()
    println("CJGUI_APPLICATION_IMAGE_CLOSE_A a_open=false b_open=true b_scene_before=${beforeCloseB.acceptedSceneVersion} b_scene_after=${afterCloseProjection.acceptedSceneVersion} b_loaded=${afterCloseB.loaded} b_decode=${afterCloseB.decodes} b_state=${state(windowB, controllerB)}")
    if (afterCloseB.status != CJGUI_INTERNAL_RENDERER_OK || afterCloseB.loaded != 1u32 ||
        state(windowB, controllerB) != "ready" || !bPumpOpen) {
        windowB.close(); return 14
    }
    windowB.close()
    if (!sharedInitial) {
        println("CJGUI_APPLICATION_IMAGE_CONSUMER passed=false reason=duplicate_initial_decode")
        return 15
    }
    println("CJGUI_APPLICATION_IMAGE_CONSUMER passed=true phases=initial_shared,version_replace,failure_recovery,close_a_b_continues")
    return 0
}
