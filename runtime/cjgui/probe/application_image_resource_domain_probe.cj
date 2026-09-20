package cjgui

import std.time.*
import std.collection.*

// This normal-window probe is deliberately narrower than the developer
// consumer: it establishes the RED/GREEN ownership fact for one exact image
// identity.  The controller owns only the scene declaration; the native
// renderer remains the sole owner of decode, texture, queue, and lifetime.
foreign {
    func cjgui_internal_renderer_test_composable_image_stats(
        session: UInt64, outLoadedTextureCount: CPointer<UInt32>, outCacheEntryCount: CPointer<UInt32>,
        outDecodeCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_image_launch_gate(session: UInt64, held: UInt8): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(session: UInt64, failureCount: UInt32): Int32
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>, outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_write_solid_image_fixture(
        path: CString, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8
    ): Int32
    func cjgui_internal_renderer_test_write_solid_image_fixture_sized(
        path: CString, width: UInt32, height: UInt32, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8
    ): Int32
    func cjgui_internal_renderer_test_composable_application_image_domain_stats(
        session: UInt64, outReusableCacheEntries: CPointer<UInt32>, outReusableCacheBytes: CPointer<UInt64>,
        outInFlight: CPointer<UInt32>, outPending: CPointer<UInt32>, outActualLoadCount: CPointer<UInt64>,
        outActualDecodeCount: CPointer<UInt64>, outCommittedTextureRefs: CPointer<UInt32>,
        outSubscriberCount: CPointer<UInt32>, outActiveSessionCount: CPointer<UInt32>,
        outResourceRecordCount: CPointer<UInt32>
    ): Int32
}

private class ApplicationImageResourceController <: CjguiComposableUiController {
    private var imageVisible: Bool
    private var imagePath: String
    private var imageVersion: Int64
    private var captureRevision: Int64
    private var revision: Int64

    init() {
        this.imageVisible = false
        this.imagePath = ""
        this.imageVersion = 0
        this.captureRevision = 0
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "application-image-domain-root-${captureRevision}", CjguiComposableUiStyle(padding: 8))
        if (imageVisible) {
            root.add(cjguiComposableImage(3, "application-image-domain-image",
                imagePath,
                CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 64),
                imageResourceId: "application-image-domain-beacon", imageResourceVersion: imageVersion))
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

    public func showImage(path: String, version: Int64): Unit {
        imageVisible = true
        imagePath = path
        imageVersion = version
        revision += 1
    }

    /// The native test request is deliberately passive. Advance a probe-only
    /// semantic revision so the following ordinary window refresh submits the
    /// already-ready scene to Metal instead of being coalesced as identical.
    public func requestDrawableCapture(): Unit {
        captureRevision += 1
        revision += 1
    }
}

private class ImagePressureController <: CjguiComposableUiController {
    private var paths: ArrayList<String>
    private var revision: Int64

    init(paths!: ArrayList<String>) {
        this.paths = paths
        this.revision = 1
    }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(700, "application-image-pressure-root", CjguiComposableUiStyle(padding: 4))
        var index: Int64 = 0
        for (path in paths) {
            root.add(cjguiComposableImage(701 + index, "application-image-pressure-${index}", path,
                CjguiComposableUiStyle(fixedWidth: 48, fixedHeight: 32),
                imageResourceId: "application-image-pressure-${index}", imageResourceVersion: 1))
            index += 1
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

    public func setPaths(paths: ArrayList<String>): Unit {
        this.paths = paths
        revision += 1
    }
}

private func pumpBoth(a: CjguiComposableUiWindow, b: CjguiComposableUiWindow): Unit {
    let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(a, turnBudgetMs: 4u32)
    let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(b, turnBudgetMs: 4u32)
}

/// Waits for the real MetalKit completion but deliberately leaves the normal
/// completion invalidation pending. The next `refresh()` then performs the
/// production scene attach and can capture a drawable texel from that frame.
private func waitForStateBeforeSceneAttach(a: CjguiComposableUiWindow, b: CjguiComposableUiWindow,
    target: CjguiComposableUiWindow, path: String, version: Int64, expected: String): Bool {
    var turns: Int64 = 0
    while (turns < 120) {
        if (target.imageResourceStatus(path, "application-image-domain-beacon", version).state == expected) {
            return true
        }
        pumpBoth(a, b)
        turns += 1
    }
    return false
}

private class DrawablePixel {
    let status: Int32
    let blue: UInt8
    let green: UInt8
    let red: UInt8
    let alpha: UInt8

    init(status: Int32, blue: UInt8, green: UInt8, red: UInt8, alpha: UInt8) {
        this.status = status
        this.blue = blue
        this.green = green
        this.red = red
        this.alpha = alpha
    }
}

private func captureImagePixel(window: CjguiComposableUiWindow, controller: ApplicationImageResourceController): DrawablePixel {
    let requested = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(
        window.testSessionToken(), 40u32, 30u32) }
    if (requested != CJGUI_INTERNAL_RENDERER_OK) {
        return DrawablePixel(-100, 0u8, 0u8, 0u8, 0u8)
    }
    controller.requestDrawableCapture()
    if (!window.refresh()) {
        return DrawablePixel(-101, 0u8, 0u8, 0u8, 0u8)
    }
    var blue: UInt8 = 0u8
    var green: UInt8 = 0u8
    var red: UInt8 = 0u8
    var alpha: UInt8 = 0u8
    let status = unsafe { cjgui_internal_renderer_test_composable_drawable_pixel(
        window.testSessionToken(), inout blue, inout green, inout red, inout alpha) }
    return DrawablePixel(status, blue, green, red, alpha)
}

private func writeSolidFixture(path: String, red: UInt8, green: UInt8, blue: UInt8): Bool {
    let cPath = unsafe { LibC.mallocCString(path) }
    var written = false
    try (pathResource = cPath.asResource()) {
        written = unsafe { cjgui_internal_renderer_test_write_solid_image_fixture(
            pathResource.value, red, green, blue, 255u8) } == CJGUI_INTERNAL_RENDERER_OK
    }
    return written
}

private func writeSolidFixtureSized(path: String, width: UInt32, height: UInt32,
    red: UInt8, green: UInt8, blue: UInt8): Bool {
    let cPath = unsafe { LibC.mallocCString(path) }
    var written = false
    try (pathResource = cPath.asResource()) {
        written = unsafe { cjgui_internal_renderer_test_write_solid_image_fixture_sized(
            pathResource.value, width, height, red, green, blue, 255u8) } == CJGUI_INTERNAL_RENDERER_OK
    }
    return written
}

private func decodeCount(window: CjguiComposableUiWindow): Int64 {
    var loaded: UInt32 = 0u32
    var cache: UInt32 = 0u32
    var decode: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(), inout loaded, inout cache, inout decode)
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK) { Int64(decode) } else { -1 }
}

private class ApplicationImageDomainStats {
    let status: Int32
    let cacheEntries: UInt32
    let cacheBytes: UInt64
    let inFlight: UInt32
    let pending: UInt32
    let actualLoads: UInt64
    let actualDecodes: UInt64
    let committedTextureRefs: UInt32
    let subscribers: UInt32
    let activeSessions: UInt32
    let resourceRecords: UInt32

    init(status: Int32, cacheEntries: UInt32, cacheBytes: UInt64, inFlight: UInt32, pending: UInt32,
        actualLoads: UInt64, actualDecodes: UInt64, committedTextureRefs: UInt32, subscribers: UInt32,
        activeSessions: UInt32, resourceRecords: UInt32) {
        this.status = status
        this.cacheEntries = cacheEntries
        this.cacheBytes = cacheBytes
        this.inFlight = inFlight
        this.pending = pending
        this.actualLoads = actualLoads
        this.actualDecodes = actualDecodes
        this.committedTextureRefs = committedTextureRefs
        this.subscribers = subscribers
        this.activeSessions = activeSessions
        this.resourceRecords = resourceRecords
    }
}

private func applicationDomainStats(window: CjguiComposableUiWindow): ApplicationImageDomainStats {
    var cacheEntries: UInt32 = 0u32
    var cacheBytes: UInt64 = 0u64
    var inFlight: UInt32 = 0u32
    var pending: UInt32 = 0u32
    var actualLoads: UInt64 = 0u64
    var actualDecodes: UInt64 = 0u64
    var committedTextureRefs: UInt32 = 0u32
    var subscribers: UInt32 = 0u32
    var activeSessions: UInt32 = 0u32
    var resourceRecords: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_composable_application_image_domain_stats(window.testSessionToken(),
            inout cacheEntries, inout cacheBytes, inout inFlight, inout pending, inout actualLoads,
            inout actualDecodes, inout committedTextureRefs, inout subscribers, inout activeSessions, inout resourceRecords)
    }
    return ApplicationImageDomainStats(status, cacheEntries, cacheBytes, inFlight, pending, actualLoads,
        actualDecodes, committedTextureRefs, subscribers, activeSessions, resourceRecords)
}

/// A launch gate is a test-only pause, not a request cancellation.  Once A
/// closes, however, its 16 never-started requests have no eligible requester
/// and must release their bounded pending slots so live B can make progress.
/// This fails against the initial shared-domain implementation: it requeues
/// those orphaned `loading` records forever and B remains `busy`.
private func verifyOrphanPendingDoesNotStarveLiveWindow(bluePath: String, coralPath: String): Bool {
    let controllerA = ApplicationImageResourceController()
    let controllerB = ApplicationImageResourceController()
    let windowA = CjguiComposableUiWindow(controllerA)
    let windowB = CjguiComposableUiWindow(controllerB)
    if (!windowA.start() || !windowB.start()) {
        windowA.close()
        windowB.close()
        return false
    }
    let tokenA = windowA.testSessionToken()
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) {
        windowA.close()
        windowB.close()
        return false
    }

    var ordinal: Int64 = 0
    var filled = true
    while (ordinal < 16) {
        let request = windowA.prepareImageResource(bluePath, "orphan-pending-a-${ordinal}", ordinal + 100)
        filled = filled && request.state == "loading"
        ordinal += 1
    }
    let beforeClose = applicationDomainStats(windowB)
    windowA.close()

    controllerB.showImage(coralPath, 1000)
    let liveRequest = windowB.prepareImageResource(coralPath, "application-image-domain-beacon", 1000)
    let refreshed = windowB.refresh()
    var turns: Int64 = 0
    var current = windowB.imageResourceStatus(coralPath, "application-image-domain-beacon", 1000).state
    while (turns < 160 && current != "ready" && current != "failed") {
        let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(windowB, turnBudgetMs: 4u32)
        if (!turnResult.windowPumpResult.isOpen) { break }
        current = windowB.imageResourceStatus(coralPath, "application-image-domain-beacon", 1000).state
        turns += 1
    }
    let after = applicationDomainStats(windowB)
    println("CJGUI_APPLICATION_IMAGE_ORPHAN_PENDING filled=${filled} pending_before_close=${beforeClose.pending} live_request=${liveRequest.state} b_state=${current} pending_after=${after.pending} inflight_after=${after.inFlight} active_after=${after.activeSessions} turns=${turns}")
    windowB.close()
    // The first B attempt may truthfully report `busy` while the bounded
    // queue is full.  Its ordinary refresh immediately drives queue cleanup
    // and re-admission; the contract is that it cannot remain busy forever.
    return filled && beforeClose.status == CJGUI_INTERNAL_RENDERER_OK && beforeClose.pending == 16u32 &&
        refreshed && current == "ready" &&
        after.status == CJGUI_INTERNAL_RENDERER_OK && after.pending == 0u32 && after.inFlight == 0u32 &&
        after.activeSessions == 1u32
}

/// Explicit public preloads are demand independent of a scene candidate.  A
/// full 16-item pending queue must not strand later `busy` preloads forever
/// once launches free capacity.  The initial scene-only busy promotion leaves
/// the final four of these 20 requests busy after the first 16 settle.
private func verifyExplicitPreloadOverflowMakesProgress(bluePath: String): Bool {
    let controller = ApplicationImageResourceController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return false }
    let token = window.testSessionToken()
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(token, 1u8) } !=
        CJGUI_INTERNAL_RENDERER_OK) {
        window.close()
        return false
    }
    var ordinal: Int64 = 0
    var loading: Int64 = 0
    var busy: Int64 = 0
    while (ordinal < 20) {
        let request = window.prepareImageResource(bluePath, "explicit-overflow-${ordinal}", ordinal + 3000)
        if (request.state == "loading") {
            loading += 1
        } else if (request.state == "busy") {
            busy += 1
        }
        ordinal += 1
    }
    let queued = applicationDomainStats(window)
    let releaseGate = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(token, 0u8) }
    let nudge = window.prepareImageResource(bluePath, "explicit-overflow-0", 3000)
    var turns: Int64 = 0
    var allSettled = false
    var ready: Int64 = 0
    var unrequested: Int64 = 0
    while (turns < 240 && !allSettled) {
        let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        if (!turnResult.windowPumpResult.isOpen) { break }
        ready = 0
        unrequested = 0
        ordinal = 0
        while (ordinal < 20) {
            let state = window.imageResourceStatus(bluePath, "explicit-overflow-${ordinal}", ordinal + 3000).state
            if (state == "ready") {
                ready += 1
            } else if (state == "unrequested") {
                unrequested += 1
            }
            ordinal += 1
        }
        // The cache remains deliberately bounded at eight.  An explicit
        // preload must make progress, but it does not reserve a permanent
        // texture beyond that reusable-cache budget.
        allSettled = ready + unrequested == 20
        turns += 1
    }
    let settled = applicationDomainStats(window)
    println("CJGUI_APPLICATION_IMAGE_EXPLICIT_OVERFLOW loading=${loading} busy=${busy} queued_pending=${queued.pending} release_gate=${releaseGate} nudge=${nudge.state} all_settled=${allSettled} ready=${ready} unrequested=${unrequested} loads=${settled.actualLoads} pending=${settled.pending} inflight=${settled.inFlight} turns=${turns}")
    window.close()
    return loading == 16 && busy == 4 && queued.status == CJGUI_INTERNAL_RENDERER_OK && queued.pending == 16u32 &&
        releaseGate == CJGUI_INTERNAL_RENDERER_OK && nudge.state == "loading" && allSettled && ready <= 8 &&
        settled.status == CJGUI_INTERNAL_RENDERER_OK && settled.actualLoads == 20u64 &&
        settled.pending == 0u32 && settled.inFlight == 0u32
}

/// A rejected candidate must leave the accepted blue subscription usable, but
/// it must not retain a coral requester just because native staging prepared
/// that candidate before the forced present failure.  The held gate makes an
/// accidental retained requester observable: releasing it after blue is
/// recommitted must not start a coral load.
private func verifyRejectedCandidateDoesNotRetainRequester(bluePath: String, coralPath: String): Bool {
    let controller = ApplicationImageResourceController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return false }
    let token = window.testSessionToken()
    controller.showImage(bluePath, 2001)
    let blueRequest = window.prepareImageResource(bluePath, "application-image-domain-beacon", 2001)
    if (blueRequest.state != "loading" || !window.refresh() ||
        !waitForStateBeforeSceneAttach(window, window, window, bluePath, 2001, "ready") || !window.refresh()) {
        window.close()
        return false
    }
    let baseline = applicationDomainStats(window)
    let holdGate = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(token, 1u8) }
    controller.showImage(coralPath, 2002)
    let forceFailure = unsafe { cjgui_internal_renderer_test_set_composable_present_failures(token, 1u32) }
    let candidateRejected = !window.refresh()

    controller.showImage(bluePath, 2001)
    let restored = window.refresh()
    let releaseGate = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(token, 0u8) }
    let trigger = window.prepareImageResource(bluePath, "application-image-domain-beacon", 2001)
    var turns: Int64 = 0
    var settled = applicationDomainStats(window)
    while (turns < 80 && (settled.inFlight > 0u32 || settled.pending > 0u32)) {
        let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        if (!turnResult.windowPumpResult.isOpen) { break }
        let _ = window.refreshIfNeeded()
        settled = applicationDomainStats(window)
        turns += 1
    }
    let coralState = window.imageResourceStatus(coralPath, "application-image-domain-beacon", 2002).state
    println("CJGUI_APPLICATION_IMAGE_REJECTED_CANDIDATE blue_request=${blueRequest.state} candidate_scene_request=true hold_gate=${holdGate} force_failure=${forceFailure} candidate_rejected=${candidateRejected} restored=${restored} release_gate=${releaseGate} trigger=${trigger.state} baseline_loads=${baseline.actualLoads} settled_loads=${settled.actualLoads} coral_state=${coralState} pending=${settled.pending} inflight=${settled.inFlight} turns=${turns}")
    window.close()
    return holdGate == CJGUI_INTERNAL_RENDERER_OK && forceFailure == CJGUI_INTERNAL_RENDERER_OK && candidateRejected &&
        restored && releaseGate == CJGUI_INTERNAL_RENDERER_OK && trigger.state == "ready" &&
        settled.actualLoads == baseline.actualLoads && settled.pending == 0u32 && settled.inFlight == 0u32 && coralState == "unrequested"
}

/// The reusable cache is intentionally stricter than scene ownership: nine
/// visible nodes and one 36MiB texture may remain retained by their committed
/// scene nodes, while only reuse entries stay within 8 / 32MiB.  Afterwards
/// 65 explicit identities exercise record pruning without claiming that scene
/// or active GPU references are governed by the reuse-cache budget.
private func verifyImageResourcePressureBudgets(): Bool {
    let fixtureRoot = "/private/tmp/cjgui-application-image-resource-domain/pressure"
    let smallPaths = ArrayList<String>()
    var ordinal: Int64 = 0
    var fixturesWritten = true
    while (ordinal < 9) {
        let path = "${fixtureRoot}-small-${ordinal}.png"
        fixturesWritten = fixturesWritten && writeSolidFixture(path, UInt8(20 + ordinal), UInt8(80 + ordinal), UInt8(140 + ordinal))
        smallPaths.add(path)
        ordinal += 1
    }
    let largePath = "${fixtureRoot}-large.png"
    fixturesWritten = fixturesWritten && writeSolidFixtureSized(largePath, 3072u32, 3072u32, 180u8, 50u8, 90u8)
    let controller = ImagePressureController(paths: smallPaths)
    let window = CjguiComposableUiWindow(controller)
    if (!fixturesWritten || !window.start()) {
        window.close()
        return false
    }

    var nineReady = false
    var turns: Int64 = 0
    while (turns < 240 && !nineReady) {
        nineReady = true
        ordinal = 0
        while (ordinal < 9) {
            if (window.imageResourceStatus(smallPaths[ordinal], "application-image-pressure-${ordinal}", 1).state != "ready") {
                nineReady = false
            }
            ordinal += 1
        }
        if (!nineReady) {
            let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
            if (!turnResult.windowPumpResult.isOpen) { break }
            let _ = window.refreshIfNeeded()
            turns += 1
        }
    }
    let nineStats = applicationDomainStats(window)
    controller.setPaths(ArrayList<String>())
    let clearedNine = window.refresh()

    controller.setPaths(ArrayList<String>([largePath]))
    let largeStarted = window.refresh()
    var largeReady = false
    var largeTurns: Int64 = 0
    while (largeTurns < 240 && !largeReady) {
        largeReady = window.imageResourceStatus(largePath, "application-image-pressure-0", 1).state == "ready"
        if (!largeReady) {
            let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 8u32)
            if (!turnResult.windowPumpResult.isOpen) { break }
            let _ = window.refreshIfNeeded()
            largeTurns += 1
        }
    }
    let attachedLarge = largeReady && window.refresh()
    let largeStats = applicationDomainStats(window)
    controller.setPaths(ArrayList<String>())
    let clearedLarge = window.refresh()

    var churnReady = true
    ordinal = 0
    while (ordinal < 65) {
        let requested = window.prepareImageResource(smallPaths[0], "application-image-pressure-churn", ordinal + 1)
        var state = requested.state
        var churnTurns: Int64 = 0
        while (churnTurns < 120 && state == "loading") {
            let turnResult = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
            if (!turnResult.windowPumpResult.isOpen) { break }
            state = window.imageResourceStatus(smallPaths[0], "application-image-pressure-churn", ordinal + 1).state
            churnTurns += 1
        }
        if (state != "ready") { churnReady = false }
        ordinal += 1
    }
    let churnStats = applicationDomainStats(window)
    println("CJGUI_APPLICATION_IMAGE_PRESSURE fixtures=${fixturesWritten} nine_ready=${nineReady} nine_cache_entries=${nineStats.cacheEntries} nine_cache_bytes=${nineStats.cacheBytes} nine_scene_refs=${nineStats.committedTextureRefs} large_started=${largeStarted} large_ready=${largeReady} large_attached=${attachedLarge} large_cache_entries=${largeStats.cacheEntries} large_cache_bytes=${largeStats.cacheBytes} large_scene_refs=${largeStats.committedTextureRefs} cleared_nine=${clearedNine} cleared_large=${clearedLarge} churn_ready=${churnReady} churn_records=${churnStats.resourceRecords} churn_cache_entries=${churnStats.cacheEntries} churn_cache_bytes=${churnStats.cacheBytes} churn_pending=${churnStats.pending} churn_inflight=${churnStats.inFlight} turns=${turns} large_turns=${largeTurns}")
    window.close()
    return fixturesWritten && nineReady && nineStats.cacheEntries <= 8u32 && nineStats.cacheBytes <= 32u64 * 1024u64 * 1024u64 &&
        nineStats.committedTextureRefs == 9u32 && clearedNine && largeStarted && largeReady && attachedLarge &&
        largeStats.cacheEntries <= 8u32 && largeStats.cacheBytes <= 32u64 * 1024u64 * 1024u64 &&
        largeStats.committedTextureRefs == 1u32 && clearedLarge && churnReady && churnStats.resourceRecords <= 64u32 &&
        churnStats.cacheEntries <= 8u32 && churnStats.cacheBytes <= 32u64 * 1024u64 * 1024u64 &&
        churnStats.pending == 0u32 && churnStats.inFlight == 0u32
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let bluePath = "/private/tmp/cjgui-application-image-resource-domain/application-blue.png"
    let coralPath = "/private/tmp/cjgui-application-image-resource-domain/application-coral.png"
    if (!writeSolidFixture(bluePath, 24u8, 96u8, 224u8) ||
        !writeSolidFixture(coralPath, 236u8, 100u8, 76u8)) { return 3 }
    let controllerA = ApplicationImageResourceController()
    let controllerB = ApplicationImageResourceController()
    let windowA = CjguiComposableUiWindow(controllerA)
    let windowB = CjguiComposableUiWindow(controllerB)
    if (!windowA.start() || !windowB.start()) {
        windowA.close()
        windowB.close()
        return 4
    }

    let tokenA = windowA.testSessionToken()
    let tokenB = windowB.testSessionToken()
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 1u8) } != CJGUI_INTERNAL_RENDERER_OK ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 1u8) } != CJGUI_INTERNAL_RENDERER_OK) {
        windowA.close()
        windowB.close()
        return 5
    }

    controllerA.showImage(bluePath, 1)
    controllerB.showImage(bluePath, 1)
    let requestA = windowA.prepareImageResource(bluePath,
        "application-image-domain-beacon", 1)
    let requestB = windowB.prepareImageResource(bluePath,
        "application-image-domain-beacon", 1)
    if (requestA.state != "loading" || requestB.state != "loading" || !windowA.refresh() || !windowB.refresh()) {
        let _ = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 0u8) }
        let _ = unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 0u8) }
        windowA.close()
        windowB.close()
        return 6
    }

    // RED baseline (before this application-domain migration): this exact
    // two-window sequence emitted `decode_a=1 decode_b=1 total_decode=2`.
    // Releasing B after A was ready launched a second MetalKit load. The
    // required GREEN result is one application-wide decode and two ready
    // consumers, while closing A leaves B's subscription and texture alive.
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 0u8) } != CJGUI_INTERNAL_RENDERER_OK ||
        !waitForStateBeforeSceneAttach(windowA, windowB, windowA, bluePath, 1, "ready")) {
        windowA.close()
        windowB.close()
        return 7
    }
    let bluePixel = captureImagePixel(windowA, controllerA)
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 0u8) } != CJGUI_INTERNAL_RENDERER_OK ||
        !waitForStateBeforeSceneAttach(windowA, windowB, windowB, bluePath, 1, "ready")) {
        windowA.close()
        windowB.close()
        return 8
    }
    // B gets the same ready texture but receives its own completion epoch and
    // attaches it through its ordinary refresh. The domain diagnostic is read
    // once here; do not add it across both windows.
    let bBluePixel = captureImagePixel(windowB, controllerB)
    println("CJGUI_APPLICATION_IMAGE_BLUE_READBACK status=${bBluePixel.status} bgra=${bBluePixel.blue},${bBluePixel.green},${bBluePixel.red},${bBluePixel.alpha}")
    if (bBluePixel.status != CJGUI_INTERNAL_RENDERER_OK) {
        windowA.close()
        windowB.close()
        return 9
    }

    let sourceDecodeA = decodeCount(windowA)
    let sourceDecodeB = decodeCount(windowB)
    let sharedStats = applicationDomainStats(windowA)

    controllerB.showImage(coralPath, 2)
    let coralRequest = windowB.prepareImageResource(coralPath, "application-image-domain-beacon", 2)
    if (coralRequest.state != "loading" || !windowB.refresh() ||
        !waitForStateBeforeSceneAttach(windowA, windowB, windowB, coralPath, 2, "ready")) {
        windowA.close()
        windowB.close()
        return 10
    }
    let coralPixel = captureImagePixel(windowB, controllerB)
    let distinguishablePixels = bBluePixel.status == CJGUI_INTERNAL_RENDERER_OK &&
        coralPixel.status == CJGUI_INTERNAL_RENDERER_OK && bBluePixel.alpha == 255u8 && coralPixel.alpha == 255u8 &&
        bBluePixel.blue > bBluePixel.red + 80u8 && coralPixel.red > coralPixel.blue + 80u8

    var hotSwapOk = distinguishablePixels
    var ordinal: Int64 = 0
    while (ordinal < 30) {
        let version = if (ordinal % 2 == 0) { 1 } else { 2 }
        let path = if (version == 1) { bluePath } else { coralPath }
        let started = MonoTime.now()
        controllerB.showImage(path, version)
        let preparation = windowB.prepareImageResource(path, "application-image-domain-beacon", version)
        let refreshed = windowB.refresh()
        let state = windowB.imageResourceStatus(path, "application-image-domain-beacon", version).state
        let elapsedMs = (MonoTime.now() - started).toMilliseconds()
        println("CJGUI_APPLICATION_IMAGE_HOT_SWAP ordinal=${ordinal} version=${version} state=${state} elapsed_ms=${elapsedMs}")
        hotSwapOk = hotSwapOk && preparation.state == "ready" && refreshed && state == "ready"
        ordinal += 1
    }

    // Start a third identity in both windows. A launches its real MetalKit
    // request, then closes before the callback; B remains a committed v3
    // subscriber, so A's close cannot cancel work B still needs or revive A.
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 1u8) } != CJGUI_INTERNAL_RENDERER_OK ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 1u8) } != CJGUI_INTERNAL_RENDERER_OK) {
        windowA.close()
        windowB.close()
        return 11
    }
    controllerA.showImage(bluePath, 3)
    controllerB.showImage(bluePath, 3)
    let lateRequestA = windowA.prepareImageResource(bluePath, "application-image-domain-beacon", 3)
    let lateRequestB = windowB.prepareImageResource(bluePath, "application-image-domain-beacon", 3)
    if (lateRequestA.state != "loading" || lateRequestB.state != "loading" || !windowA.refresh() || !windowB.refresh() ||
        unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 0u8) } != CJGUI_INTERNAL_RENDERER_OK) {
        windowA.close()
        windowB.close()
        return 12
    }
    windowA.close()
    if (unsafe { cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenB, 0u8) } != CJGUI_INTERNAL_RENDERER_OK) {
        windowB.close()
        return 12
    }
    var settleTurns: Int64 = 0
    var finalStats = applicationDomainStats(windowB)
    while (settleTurns < 120 && (finalStats.inFlight != 0u32 || finalStats.pending != 0u32)) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(windowB, turnBudgetMs: 4u32)
        finalStats = applicationDomainStats(windowB)
        settleTurns += 1
    }
    let lateBState = windowB.imageResourceStatus(bluePath, "application-image-domain-beacon", 3).state
    let bSurvives = windowB.isOpen() && lateBState == "ready"
    println("CJGUI_APPLICATION_IMAGE_DOMAIN_SHARED source_decode_a=${sourceDecodeA} source_decode_b=${sourceDecodeB} blue_a_bgra=${bluePixel.blue},${bluePixel.green},${bluePixel.red},${bluePixel.alpha} blue_b_bgra=${bBluePixel.blue},${bBluePixel.green},${bBluePixel.red},${bBluePixel.alpha} coral_bgra=${coralPixel.blue},${coralPixel.green},${coralPixel.red},${coralPixel.alpha} shared_cache_entries=${sharedStats.cacheEntries} shared_cache_bytes=${sharedStats.cacheBytes} shared_actual_loads=${sharedStats.actualLoads} shared_actual_decodes=${sharedStats.actualDecodes} shared_inflight=${sharedStats.inFlight} shared_pending=${sharedStats.pending} shared_subscribers=${sharedStats.subscribers} shared_active_sessions=${sharedStats.activeSessions} domain_actual_loads=${finalStats.actualLoads} domain_actual_decodes=${finalStats.actualDecodes} final_cache_entries=${finalStats.cacheEntries} final_cache_bytes=${finalStats.cacheBytes} final_inflight=${finalStats.inFlight} final_pending=${finalStats.pending} b_texture_refs=${finalStats.committedTextureRefs} subscribers_after_a_close=${finalStats.subscribers} active_after_a_close=${finalStats.activeSessions} late_b_state=${lateBState} late_settle_turns=${settleTurns} b_survives=${bSurvives}")
    windowB.close()
    let sharedBounded = sharedStats.status == CJGUI_INTERNAL_RENDERER_OK &&
        sharedStats.cacheEntries <= 8u32 && sharedStats.cacheBytes <= 32u64 * 1024u64 * 1024u64 &&
        sharedStats.actualLoads == 1u64 && sharedStats.actualDecodes == 1u64 &&
        sharedStats.inFlight == 0u32 && sharedStats.pending == 0u32 && sharedStats.subscribers == 2u32 &&
        sharedStats.activeSessions == 2u32
    let finalConverged = finalStats.status == CJGUI_INTERNAL_RENDERER_OK &&
        finalStats.cacheEntries <= 8u32 && finalStats.cacheBytes <= 32u64 * 1024u64 * 1024u64 &&
        finalStats.actualLoads == 3u64 && finalStats.actualDecodes == 3u64 &&
        finalStats.inFlight == 0u32 && finalStats.pending == 0u32 && finalStats.committedTextureRefs == 1u32 &&
        finalStats.subscribers == 1u32 && finalStats.activeSessions == 1u32
    let orphanPendingReleased = verifyOrphanPendingDoesNotStarveLiveWindow(bluePath, coralPath)
    let explicitOverflowProgressed = verifyExplicitPreloadOverflowMakesProgress(bluePath)
    let rejectedCandidateCleaned = verifyRejectedCandidateDoesNotRetainRequester(bluePath, coralPath)
    let pressureBudgetsHeld = verifyImageResourcePressureBudgets()
    return if (sourceDecodeA == 1 && sourceDecodeB == 0 && hotSwapOk && bSurvives && sharedBounded && finalConverged &&
        orphanPendingReleased && explicitOverflowProgressed && rejectedCandidateCleaned && pressureBudgetsHeld) { 0 } else { 13 }
}
