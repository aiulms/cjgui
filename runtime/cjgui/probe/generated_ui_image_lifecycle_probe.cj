// Generated-interface image lifecycle, on the SAME public path an application
// uses: a CjguiGeneratedUiCapabilityCatalog declares the raster under a logical
// key + exact version, a generated structure references it, and the real
// CjguiComposableUiWindow commits the scene.
//
// This closes the runtime-evidence gap the previous package left open for
// NORMAL GENERATED interfaces (the existing image probes drive handwritten
// controllers):
//
//   1. cold -> loading -> ready on the generated node, with the rendered pixel
//      read back from the real drawable (the image is painted, not merely
//      "state == ready");
//   2. failure -> recovery: a declaration whose raster cannot be decoded makes
//      the generated binding `failed`, and a NEW declared version recovers to a
//      painted image without disturbing the accepted structure version;
//   3. an OLD completion event: a version-1 request is still in flight when the
//      accepted structure rebinds to version 2; releasing the old decode must
//      not repaint the scene with the older raster (the committed texture key
//      still belongs to v2);
//   4. release convergence: after the owner windows close, the bounded
//      application resource domain drops subscribers, in-flight and pending
//      work (only the still-live observer session remains);
//   5. another window's owner advance while this window is still loading.
//
// Only the launch gate and the fixture writer/pixel reader are test seams; the
// window, the transaction, the generated holder and the resource domain are all
// production code.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

foreign {
    func cjgui_internal_renderer_test_composable_image_stats(
        session: UInt64, outLoadedTextureCount: CPointer<UInt32>, outCacheEntryCount: CPointer<UInt32>,
        outDecodeCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_image_launch_gate(session: UInt64, held: UInt8): Int32
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>, outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_write_solid_image_fixture(
        path: CString, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8
    ): Int32
    func cjgui_internal_renderer_test_composable_application_image_domain_stats(
        session: UInt64, outReusableCacheEntries: CPointer<UInt32>, outReusableCacheBytes: CPointer<UInt64>,
        outInFlight: CPointer<UInt32>, outPending: CPointer<UInt32>, outActualLoadCount: CPointer<UInt64>,
        outActualDecodeCount: CPointer<UInt64>, outCommittedTextureRefs: CPointer<UInt32>,
        outSubscriberCount: CPointer<UInt32>, outActiveSessionCount: CPointer<UInt32>,
        outResourceRecordCount: CPointer<UInt32>
    ): Int32
}

private let LIFECYCLE_KEY: String = "generated-lifecycle-beacon"

private class LifecycleProvider <: CjguiGeneratedUiBindingProvider {
    /// The OWNER value behind the label field. A probe can change it while another
    /// window holds image work, which is the real owner operation the same-app
    /// fairness scenario needs: the value is read from the owner at build time and
    /// never copied into the framework.
    public var ownerDraft: String = "draft"
    public func fieldResourceId(fieldId: String): Int64 { return 8801 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 11 }
    public func draftText(fieldId: String): String { return ownerDraft }
    public func appliedText(fieldId: String): String { return "applied" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let _ = actionName
        let _ = nodeKey
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// One generated consumer: it owns a catalog, a structure holder and the scene
/// transaction, exactly like a normal application window.
private class LifecycleController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    public let catalog: CjguiGeneratedUiCapabilityCatalog
    public let holder: CjguiGeneratedUiStructureHolder
    private let provider = LifecycleProvider()
    private var version: Int64 = 1
    /// Probe-only scene discriminator: a real content change is what makes the
    /// native side submit (and therefore draw) instead of coalescing an
    /// identical scene.
    private var captureRevision: Int64 = 0
    private var attachedWindow: ?CjguiComposableUiWindow = None
    private var plainOnly: Bool

    public init(catalog: CjguiGeneratedUiCapabilityCatalog, plainOnly!: Bool = false) {
        this.catalog = catalog
        this.holder = CjguiGeneratedUiStructureHolder(catalog,
            rootScope: CjguiComposableUiIdentityScope("generated-image-lifecycle"))
        this.plainOnly = plainOnly
    }

    public func attach(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
    }

    public func bump(): Unit {
        version += 1
    }

    /// Changes the built tree as well as the declared revision, so the next
    /// ordinary refresh is a real native submission rather than a coalesced
    /// identical scene.
    public func requestCapture(): Unit {
        captureRevision += 1
        version += 1
    }

    public func uiSceneVersion(): Int64 {
        return version
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(20, "generated-lifecycle-root-${captureRevision}",
            CjguiComposableUiStyle(padding: 8, gap: 4))
        if (plainOnly) {
            root.add(cjguiComposableText(21, "generated-lifecycle-caption", "observer", CjguiComposableUiStyle()))
            return root
        }
        match (attachedWindow) {
            case Some(window) =>
                // The ordinary application samples the accepted bindings on the
                // window's own thread during a build; this probe does the same so
                // the PUBLIC projection (not a private read) carries the state.
                holder.sampleImageResourceStates(window)
            case None => ()
        }
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

    /// Commits one generated structure and returns whether the scene accepted it
    /// at the expected version.
    public func commitStructure(text: String, expectedVersion: Int64): Bool {
        match (CjguiGeneratedUiEncoding.decode(text).root) {
            case Some(root) =>
                if (!holder.submit(root, provider).candidateAccepted) {
                    println("CJGUI_GENERATED_IMAGE_REJECT reason=${holder.rejectedReason()} issue=${holder.lastIssue()} version=${holder.structureVersion()}")
                    return false
                }
            case None =>
                println("CJGUI_GENERATED_IMAGE_REJECT reason=decode_failed")
                return false
        }
        bump()
        if (!replyRefresh()) {
            return false
        }
        if (holder.structureVersion() != expectedVersion) {
            println("CJGUI_GENERATED_IMAGE_REJECT reason=scene_${holder.lastSceneOutcome()} version=${holder.structureVersion()} expected=${expectedVersion}")
            return false
        }
        return true
    }

    /// A REAL owner operation on this application: the OWNER value behind the
    /// label field changes and the next ordinary refresh must present it. Returns
    /// the value the ACCEPTED tree really carries, so a caller can prove the write
    /// reached this window's scene instead of trusting the declared revision.
    public func setOwnerLabelFromOwner(value: String): String {
        provider.ownerDraft = value
        bump()
        let _ = replyRefresh()
        return acceptedFieldValue("editor")
    }

    /// The value the CURRENTLY BUILT tree carries for one generated key. The node
    /// is found through the holder's STABLE KEY -> id map, because generated
    /// semantic ids are intentionally OPAQUE (they never contain a business key).
    public func acceptedFieldValue(key: String): String {
        let built = holder.buildRefreshNode(provider)
        let targetId = holder.nodeIdForKey(key)
        if (targetId <= 0) {
            return ""
        }
        return fieldValueWithId(built, targetId)
    }

    /// The value this window's ACCEPTED SCENE really carries for one generated key.
    /// It reads the accepted scene nodes the window already committed; rebuilding
    /// the tree would only show what the OWNER declares, not what was accepted.
    public func acceptedSceneFieldValue(window: CjguiComposableUiWindow, key: String): String {
        let targetId = holder.nodeIdForKey(key)
        if (targetId <= 0) {
            return ""
        }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == targetId) {
                return node.value
            }
        }
        return ""
    }

    /// A real owner write plus a new declared revision. The caller pumps the
    /// NORMAL application loop and then reads the ACCEPTED scene, so the value can
    /// never be a rebuilt tree or a self-reported revision.
    public func setOwnerLabel(value: String): Unit {
        provider.ownerDraft = value
        bump()
    }

    /// One ordinary host turn (which refreshes the window when the declared
    /// scene or the native viewport moved). The structure version is what proves
    /// the commit, so a no-op refresh is not treated as a failure here.
    public func replyRefresh(): Bool {
        match (attachedWindow) {
            case Some(window) =>
                return CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 8u32)
                    .windowPumpResult.isOpen
            case None => return false
        }
    }
}

/// The value carried by the built node with this exact id. Generated semantic ids
/// are opaque on purpose, so a caller resolves a KEY through the holder's map and
/// then finds the node by ID - never by guessing a semantic string.
private func fieldValueWithId(node: CjguiComposableUiNode, nodeId: Int64): String {
    if (node.nodeId == nodeId) {
        return node.value
    }
    for (child in node.children()) {
        let found = fieldValueWithId(child, nodeId)
        if (found.size > 0) {
            return found
        }
    }
    return ""
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

private class ImageDomainStats {
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

private func applicationDomainStats(window: CjguiComposableUiWindow): ImageDomainStats {
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
    return ImageDomainStats(status, cacheEntries, cacheBytes, inFlight, pending, actualLoads,
        actualDecodes, committedTextureRefs, subscribers, activeSessions, resourceRecords)
}

private func imageStats(window: CjguiComposableUiWindow): (UInt32, UInt32, UInt32) {
    var loaded: UInt32 = 0u32
    var cache: UInt32 = 0u32
    var decode: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_composable_image_stats(window.testSessionToken(),
            inout loaded, inout cache, inout decode)
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        return (0u32, 0u32, 0u32)
    }
    return (loaded, cache, decode)
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

private func capturePixel(window: CjguiComposableUiWindow, controller: LifecycleController): DrawablePixel {
    var turns: Int64 = 0
    while (turns < 60) {
        let requested = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(
            window.testSessionToken(), 40u32, 30u32) }
        if (requested != CJGUI_INTERNAL_RENDERER_OK) {
            return DrawablePixel(-100, 0u8, 0u8, 0u8, 0u8)
        }
        // A probe-only scene change: the following ordinary refresh must submit
        // the already-ready scene to Metal instead of being coalesced as
        // identical.
        controller.requestCapture()
        if (!window.refresh()) {
            return DrawablePixel(-101, 0u8, 0u8, 0u8, 0u8)
        }
        var blue: UInt8 = 0u8
        var green: UInt8 = 0u8
        var red: UInt8 = 0u8
        var alpha: UInt8 = 0u8
        let status = unsafe { cjgui_internal_renderer_test_composable_drawable_pixel(
            window.testSessionToken(), inout blue, inout green, inout red, inout alpha) }
        if (status == CJGUI_INTERNAL_RENDERER_OK) {
            return DrawablePixel(status, blue, green, red, alpha)
        }
        turns += 1
    }
    return DrawablePixel(-102, 0u8, 0u8, 0u8, 0u8)
}

/// Bounded pump until the generated binding's PUBLIC sampled state reaches the
/// wanted value (or the other tolerated value). The controller is bumped before
/// each attempt because a normal `refreshIfNeeded` only rebuilds when the
/// declared scene or the native viewport actually moved.
private func waitSampledState(controller: LifecycleController, window: CjguiComposableUiWindow,
    key: String, version: Int64, first: String, second: String, maxTurns: Int64): String {
    var turns: Int64 = 0
    var current = controller.holder.imageResourceState(key, version)
    while (turns < maxTurns) {
        if (current == first || current == second) {
            return current
        }
        controller.bump()
        let turn = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 8u32)
        if (!turn.windowPumpResult.isOpen) {
            return "closed"
        }
        current = controller.holder.imageResourceState(key, version)
        turns += 1
    }
    return current
}

/// The same bounded wait, driven by the NORMAL multi-window application loop
/// instead of a single window's own pump: fairness between two live windows is a
/// property of that loop, so it must be observed there.
private func waitSampledStateInApplication(application: CjguiMacosApplication, controller: LifecycleController,
    key: String, version: Int64, first: String, second: String, maxTurns: Int64): String {
    var turns: Int64 = 0
    var current = controller.holder.imageResourceState(key, version)
    while (turns < maxTurns) {
        if (current == first || current == second) {
            return current
        }
        controller.bump()
        let turn = application.pumpOneTurn(turnBudgetMs: 8u32)
        if (!turn.isOpen) {
            return "closed"
        }
        current = controller.holder.imageResourceState(key, version)
        turns += 1
    }
    return current
}

/// Pumps the NORMAL multi-window application loop until one window's ACCEPTED
/// scene really carries the wanted value for a generated key. It reads the
/// accepted scene nodes; a rebuilt tree is not accepted state.
private func pumpUntilAcceptedField(application: CjguiMacosApplication, window: CjguiComposableUiWindow,
    controller: LifecycleController, key: String, expected: String, maxTurns: Int64): Bool {
    var turns: Int64 = 0
    while (turns < maxTurns) {
        if (controller.acceptedSceneFieldValue(window, key) == expected) {
            return true
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 8u32)
        if (!turn.isOpen) {
            return false
        }
        turns += 1
    }
    return controller.acceptedSceneFieldValue(window, key) == expected
}

private func structureWithImage(key: String, version: Int64): String {
    return """
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 icon image
PROPERTY 1 icon resource ${key}
PROPERTY 1 icon resourceVersion ${version}
PROPERTY 1 icon contentMode fit
PROPERTY 1 icon fixedWidth 96
PROPERTY 1 icon fixedHeight 64
NODE 1 editor textInput field=label
END
"""
}

/// The generated image kind carries the shared content properties AND the
/// shared box/leaf style properties, exactly like the application catalogs in
/// this repository (a generated description must be able to size the raster).
private func imageComponentProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
    let properties = CjguiGeneratedUiPresentation.imageContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        properties.add(property)
    }
    return properties
}

private func lifecycleCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 16))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image",
        imageComponentProperties(), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "备注", "TEXT", 8801,
        writeActionName: "EDIT_DRAFT_TEXT"))
    return catalog
}

main(): Int64 {
    let root = if (let Some(value) <- getVariable("CJGUI_GENERATED_IMAGE_LIFECYCLE_DIR")) {
        value
    } else {
        "/private/tmp/cjgui-generated-image-lifecycle"
    }
    let bluePath = "${root}/generated-blue.png"
    let coralPath = "${root}/generated-coral.png"
    let missingPath = "${root}/generated-missing.png"
    if (!writeSolidFixture(bluePath, 20u8, 40u8, 240u8) ||
        !writeSolidFixture(coralPath, 240u8, 60u8, 30u8)) {
        println("CJGUI_GENERATED_IMAGE_LIFECYCLE fixtures=false")
        return 1
    }

    var allValid = true

    // --- 1. cold -> loading -> ready, with a real painted pixel -------------
    let catalog = lifecycleCatalog()
    let _ = catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec(LIFECYCLE_KEY, "PNG", 1, "生成图片", bluePath))
    let controller = LifecycleController(catalog)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_GENERATED_IMAGE_LIFECYCLE start=false")
        return 1
    }
    controller.attach(window)
    let coldState = window.imageResourceStatus(bluePath, LIFECYCLE_KEY, 1).state
    let gateHeld = unsafe {
        cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 1u8)
    }
    let committed = controller.commitStructure(structureWithImage(LIFECYCLE_KEY, 1), 1)
    let loadingState = window.imageResourceStatus(bluePath, LIFECYCLE_KEY, 1).state
    let sampledLoading = waitSampledState(controller, window, LIFECYCLE_KEY, 1,
        "loading", "ready", 20)
    let statsDuringGate = applicationDomainStats(window)
    let releaseGate = unsafe {
        cjgui_internal_renderer_test_set_composable_image_launch_gate(window.testSessionToken(), 0u8)
    }
    let readyState = waitSampledState(controller, window, LIFECYCLE_KEY, 1,
        "ready", "failed", 200)
    let directReady = window.imageResourceStatus(bluePath, LIFECYCLE_KEY, 1).state
    let pixel = capturePixel(window, controller)
    let (loaded, cache, decode) = imageStats(window)
    let painted = pixel.status == CJGUI_INTERNAL_RENDERER_OK && pixel.alpha == 255u8 &&
        pixel.blue > pixel.red + 80u8
    let coldOk = coldState == "unrequested"
    let loadingOk = committed && gateHeld == CJGUI_INTERNAL_RENDERER_OK && releaseGate == CJGUI_INTERNAL_RENDERER_OK &&
        loadingState == "loading" && sampledLoading == "loading" &&
        statsDuringGate.pending + statsDuringGate.inFlight > 0u32
    let readyOk = (readyState == "ready" && directReady == "ready") && painted &&
        loaded >= 1u32 && cache >= 1u32 && decode >= 1u32
    println("CJGUI_GENERATED_IMAGE_COLD cold=${coldState} cold_ok=${coldOk} gate_held=${gateHeld}")
    println("CJGUI_GENERATED_IMAGE_LOADING state=${loadingState} sampled=${sampledLoading} pending=${statsDuringGate.pending} inflight=${statsDuringGate.inFlight} committed=${committed}")
    println("CJGUI_GENERATED_IMAGE_READY sampled=${readyState} direct=${directReady} pixel_status=${pixel.status} pixel_bgra=${pixel.blue},${pixel.green},${pixel.red},${pixel.alpha} painted=${painted} loaded=${loaded} cache=${cache} decode=${decode}")
    allValid = allValid && coldOk && loadingOk && readyOk

    // --- 2. failure -> recovery on a NEW declared version -------------------
    let _ = catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("generated-broken-beacon", "PNG", 1, "坏资源", missingPath))
    let brokenCommitted = controller.commitStructure(structureWithImage("generated-broken-beacon", 1), 2)
    let failedSampled = waitSampledState(controller, window, "generated-broken-beacon", 1,
        "failed", "ready", 120)
    let failedDirect = window.imageResourceStatus(missingPath, "generated-broken-beacon", 1).state
    let versionAfterFailure = controller.holder.structureVersion()
    // The application fixes the raster by declaring a NEW version; the same
    // (key, version) can never be silently repointed at different content.
    let sameVersionRewrite = catalog.updateImageResource(
        CjguiGeneratedUiImageResourceSpec("generated-broken-beacon", "PNG", 1, "坏资源", bluePath))
    let _ = catalog.updateImageResource(
        CjguiGeneratedUiImageResourceSpec("generated-broken-beacon", "PNG", 2, "恢复资源", coralPath))
    let recovered = controller.commitStructure(structureWithImage("generated-broken-beacon", 2), 3)
    let recoverySampled = waitSampledState(controller, window, "generated-broken-beacon", 2,
        "ready", "failed", 200)
    let recoveryPixel = capturePixel(window, controller)
    let recoveryPainted = recoverySampled == "ready" && recoveryPixel.status == CJGUI_INTERNAL_RENDERER_OK &&
        recoveryPixel.alpha == 255u8 && recoveryPixel.red > recoveryPixel.blue + 80u8
    let failureOk = brokenCommitted && failedSampled == "failed" && failedDirect == "failed" &&
        versionAfterFailure == 2 && !sameVersionRewrite && recovered && recoveryPainted
    println("CJGUI_GENERATED_IMAGE_FAILED committed=${brokenCommitted} sampled=${failedSampled} direct=${failedDirect} version=${versionAfterFailure} same_version_rewrite=${sameVersionRewrite}")
    println("CJGUI_GENERATED_IMAGE_RECOVERY committed=${recovered} sampled=${recoverySampled} pixel_status=${recoveryPixel.status} pixel_bgra=${recoveryPixel.blue},${recoveryPixel.green},${recoveryPixel.red},${recoveryPixel.alpha} painted=${recoveryPainted} version=${controller.holder.structureVersion()}")
    allValid = allValid && failureOk

    // --- 3. an OLD completion must not repaint the accepted scene -----------
    // v1 (blue, same key) starts loading behind the gate; the accepted structure
    // then rebinds to v2 (coral). Releasing the gate lets the v1 decode finish
    // late; the committed node must still carry the v2 raster.
    let staleCatalog = lifecycleCatalog()
    let _ = staleCatalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("generated-stale-beacon", "PNG", 1, "旧资源", bluePath))
    let staleController = LifecycleController(staleCatalog)
    let staleWindow = CjguiComposableUiWindow(staleController)
    var staleOk = false
    if (staleWindow.start()) {
        staleController.attach(staleWindow)
        let staleToken = staleWindow.testSessionToken()
        let staleGate = unsafe {
            cjgui_internal_renderer_test_set_composable_image_launch_gate(staleToken, 1u8)
        }
        let staleV1 = staleController.commitStructure(structureWithImage("generated-stale-beacon", 1), 1)
        let v1State = waitSampledState(staleController, staleWindow, "generated-stale-beacon", 1,
            "loading", "ready", 20)
        let _ = staleCatalog.updateImageResource(
            CjguiGeneratedUiImageResourceSpec("generated-stale-beacon", "PNG", 2, "新资源", coralPath))
        let staleV2 = staleController.commitStructure(structureWithImage("generated-stale-beacon", 2), 2)
        let staleRelease = unsafe {
            cjgui_internal_renderer_test_set_composable_image_launch_gate(staleToken, 0u8)
        }
        let v2State = waitSampledState(staleController, staleWindow, "generated-stale-beacon", 2,
            "ready", "failed", 200)
        let stalePixel = capturePixel(staleWindow, staleController)
        // Give any late v1 completion extra turns to (wrongly) overwrite the
        // committed texture, then read the pixel again.
        var extra: Int64 = 0
        while (extra < 40) {
            staleController.bump()
            let turn = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(staleWindow, turnBudgetMs: 8u32)
            if (!turn.windowPumpResult.isOpen) { break }
            extra += 1
        }
        let afterStalePixel = capturePixel(staleWindow, staleController)
        let acceptedInstance = staleController.holder.acceptedNodeForKey("icon").isSome()
        let v2Painted = afterStalePixel.status == CJGUI_INTERNAL_RENDERER_OK &&
            afterStalePixel.alpha == 255u8 && afterStalePixel.red > afterStalePixel.blue + 80u8
        staleOk = staleV1 && staleGate == CJGUI_INTERNAL_RENDERER_OK && v1State == "loading" &&
            staleV2 && staleRelease == CJGUI_INTERNAL_RENDERER_OK && v2State == "ready" && acceptedInstance &&
            staleController.holder.structureVersion() == 2 && v2Painted &&
            afterStalePixel.red > afterStalePixel.blue + 80u8
        println("CJGUI_GENERATED_IMAGE_STALE v1_committed=${staleV1} v1_state=${v1State} v2_committed=${staleV2} v2_state=${v2State} accepted_identity=${acceptedInstance} version=${staleController.holder.structureVersion()} pixel_status=${stalePixel.status} pixel_bgra=${stalePixel.blue},${stalePixel.green},${stalePixel.red},${stalePixel.alpha} after_extra_turns_status=${afterStalePixel.status} after_extra_turns_bgra=${afterStalePixel.blue},${afterStalePixel.green},${afterStalePixel.red},${afterStalePixel.alpha} v2_painted=${v2Painted}")
    } else {
        println("CJGUI_GENERATED_IMAGE_STALE start=false")
    }
    allValid = allValid && staleOk

    // --- 5. same-application fairness: A loads behind a gate, B really works ---
    // TWO live windows under the NORMAL application loop (`CjguiMacosApplication`,
    // the same class every multi-window application uses). A holds a REAL
    // `loading` image binding; B performs a real OWNER write on a VISIBLE field
    // and B's ACCEPTED scene must carry the new value while A is still loading.
    // Nothing here uses a single window's private pump for the fairness claim, and
    // no value is read from a rebuilt tree.
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    // A uses its OWN raster path and key, so its decode is really gated: reusing a
    // raster another window already decoded would resolve from the shared cache
    // and never be `loading`.
    let fairnessAKey = "generated-fairness-a"
    let catalogA = lifecycleCatalog()
    let _ = catalogA.registerImageResource(
        CjguiGeneratedUiImageResourceSpec(fairnessAKey, "PNG", 1, "A生成图片", coralPath))
    let controllerA = LifecycleController(catalogA)
    let openA = application.openWindow(controllerA,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 图片双窗 A", 720u32, 480u32))
    let catalogB = lifecycleCatalog()
    let _ = catalogB.registerImageResource(
        CjguiGeneratedUiImageResourceSpec(LIFECYCLE_KEY, "PNG", 1, "B生成图片", bluePath))
    let controllerB = LifecycleController(catalogB)
    let openB = application.openWindow(controllerB,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 图片双窗 B", 720u32, 480u32))
    var otherOk = false
    if (openA.didOpen && openB.didOpen) {
        let identifiers = application.windowIdentifiers()
        let windowA = match (application.window(identifiers[0])) {
            case Some(value) => value
            case None => throw Exception("application lost image window A")
        }
        let windowB = match (application.window(identifiers[1])) {
            case Some(value) => value
            case None => throw Exception("application lost image window B")
        }
        controllerA.attach(windowA)
        controllerB.attach(windowB)
        // B first commits its OWN accepted structure and is fully ready and
        // VISIBLE: its ACCEPTED scene carries the owner's value before A starts
        // loading anything.
        let bCommitted = controllerB.commitStructure(structureWithImage(LIFECYCLE_KEY, 1), 1)
        controllerB.setOwnerLabel("B-初始值")
        let bFirstAccepted = pumpUntilAcceptedField(application, windowB, controllerB, "editor", "B-初始值", 60)
        // A holds a REAL loading binding behind the launch gate.
        let tokenA = windowA.testSessionToken()
        let gateA = unsafe {
            cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 1u8)
        }
        let aCommitted = controllerA.commitStructure(structureWithImage(fairnessAKey, 1), 1)
        let aLoading = waitSampledStateInApplication(application, controllerA, fairnessAKey, 1,
            "loading", "ready", 20)
        // While A is STILL gated, B writes through the owner entry and the
        // APPLICATION loop accepts it in B's OWN scene.
        let sceneBBefore = windowB.displayedSceneVersion()
        controllerB.setOwnerLabel("B-在A加载期间")
        // The ACCEPTED scene must still carry the OLD value right after the owner
        // write: only the application loop's acceptance may publish the new one.
        // A read that rebuilt the tree would already show the new value here.
        let bAcceptedBeforePump = controllerB.acceptedSceneFieldValue(windowB, "editor")
        let bAcceptedDuringLoad = pumpUntilAcceptedField(application, windowB, controllerB, "editor",
            "B-在A加载期间", 60)
        let aStillLoading = controllerA.holder.imageResourceState(fairnessAKey, 1) == "loading"
        let bSceneAdvanced = windowB.displayedSceneVersion() > sceneBBefore
        // A's own accepted scene must NOT have been dragged along: its structure
        // version is still the one its gated commit accepted.
        let aStructureDuringLoad = controllerA.holder.structureVersion()
        // NEGATIVE CONTROL: the SAME write performed only AFTER A's gate is
        // released must NOT be observable "while A was loading". The positive
        // observation therefore depends on the real ordering, not on the write.
        let releaseA = unsafe {
            cjgui_internal_renderer_test_set_composable_image_launch_gate(tokenA, 0u8)
        }
        let aReady = waitSampledStateInApplication(application, controllerA, fairnessAKey, 1,
            "ready", "failed", 200)
        controllerB.setOwnerLabel("B-负对照")
        let bNegativeAccepted = pumpUntilAcceptedField(application, windowB, controllerB, "editor",
            "B-负对照", 60)
        let aLoadingDuringNegative = controllerA.holder.imageResourceState(fairnessAKey, 1) == "loading"
        // A closes; B keeps working through the same loop and its NEXT owner write
        // is still accepted.
        let closeARequested = application.requestClose(identifiers[0])
        var closeTurns: Int64 = 0
        while (closeTurns < 40 && application.windowIdentifiers().size > 1) {
            let turn = application.pumpOneTurn(turnBudgetMs: 8u32)
            if (!turn.isOpen) {
                break
            }
            closeTurns += 1
        }
        let aClosed = application.windowIdentifiers().size == 1
        controllerB.setOwnerLabel("B-A关闭后")
        let bAcceptedAfterClose = pumpUntilAcceptedField(application, windowB, controllerB, "editor",
            "B-A关闭后", 60)
        otherOk = gateA == CJGUI_INTERNAL_RENDERER_OK && aCommitted && aLoading == "loading" && bCommitted &&
            bFirstAccepted && bAcceptedBeforePump == "B-初始值" && bAcceptedDuringLoad && aStillLoading &&
            bSceneAdvanced &&
            aStructureDuringLoad == 1 && releaseA == CJGUI_INTERNAL_RENDERER_OK && aReady == "ready" &&
            bNegativeAccepted && !aLoadingDuringNegative &&
            closeARequested && aClosed && bAcceptedAfterClose
        println("CJGUI_GENERATED_IMAGE_SAME_APPLICATION a_loading=${aLoading} a_committed=${aCommitted} " +
            "b_committed=${bCommitted} b_first_accepted=${bFirstAccepted} b_scene=${sceneBBefore}->${windowB.displayedSceneVersion()} " +
            "b_owner_value='${controllerB.acceptedSceneFieldValue(windowB, "editor")}' " +
            "b_accepted_before_pump='${bAcceptedBeforePump}' b_accepted_during_load=${bAcceptedDuringLoad} " +
            "a_still_loading=${aStillLoading} " +
            "a_structure_during_load=${aStructureDuringLoad} a_converged=${aReady} " +
            "negative_accepted=${bNegativeAccepted} a_loading_during_negative=${aLoadingDuringNegative} " +
            "a_close_requested=${closeARequested} a_closed=${aClosed} b_accepted_after_close=${bAcceptedAfterClose}")
        windowA.close()
        windowB.close()
    } else {
        println("CJGUI_GENERATED_IMAGE_SAME_APPLICATION start=false openA=${openA.didOpen} openB=${openB.didOpen}")
    }
    allValid = allValid && otherOk

    // --- 4. release convergence --------------------------------------------
    // An observer window stays alive so the bounded application domain can still
    // be read: the closed owners must drop to zero subscribers/in-flight/pending.
    let observerController = LifecycleController(lifecycleCatalog(), plainOnly: true)
    let observer = CjguiComposableUiWindow(observerController)
    var releaseOk = false
    if (observer.start()) {
        staleWindow.close()
        window.close()
        let converged = applicationDomainStats(observer)
        releaseOk = converged.status == CJGUI_INTERNAL_RENDERER_OK && converged.subscribers == 0u32 &&
            converged.inFlight == 0u32 && converged.pending == 0u32 &&
            converged.activeSessions == 1u32 && converged.cacheEntries <= 8u32 &&
            converged.cacheBytes <= 32u64 * 1024u64 * 1024u64 && converged.committedTextureRefs == 0u32
        println("CJGUI_GENERATED_IMAGE_RELEASE subscribers=${converged.subscribers} inflight=${converged.inFlight} pending=${converged.pending} active=${converged.activeSessions} cache_entries=${converged.cacheEntries} cache_bytes=${converged.cacheBytes} texture_refs=${converged.committedTextureRefs} records=${converged.resourceRecords} converged=${releaseOk}")
        observer.close()
    } else {
        staleWindow.close()
        window.close()
        println("CJGUI_GENERATED_IMAGE_RELEASE start=false")
    }
    allValid = allValid && releaseOk

    println("CJGUI_GENERATED_IMAGE_LIFECYCLE passed=${allValid}")
    return if (allValid) { 0 } else { 1 }
}
