extern "C" {
// ===========================================================================
// Frozen main-core OHOS narrow adapter (2026-10-27)
//
// The frozen common core (platforms/ohos/main_core) calls a wider C ABI than
// the old fork host implemented. This file supplies exactly that surface.
//
// Rules used here:
//   * A function whose platform work the OHOS host really owns is implemented
//     against the existing Session/candidate/paint machinery; it never writes
//     a success value without doing the work.
//   * A capability this backend does not own (macOS proxy installed ranges,
//     composition reanchor, PNG byte transfer, layered context-menu guards,
//     per-line text geometry enumeration) returns a named refusal from the
//     shared status enum. No success stub is used to satisfy the linker.
//   * This file is textually included at the end of ohos_renderer.cpp so it can
//     use the host's private Session table and helpers. It is part of host_main
//     (the platform delta), never part of the frozen core.
// ===========================================================================

// ---------------------------------------------------------------------------
// Owner scheduler (Linux-shaped ABI)
//
// The OHOS application loop drives pump_event directly; this revision/condvar
// pair exists because the frozen linux_application_host is part of the common
// core. Notification is real: every notify advances the revision and wakes all
// waiters, and only an actual timeout is reported as idle time.
// ---------------------------------------------------------------------------
static std::mutex g_mainOwnerSchedLock;
static std::condition_variable g_mainOwnerSchedCv;
static uint64_t g_mainOwnerSchedRevision = 1;

uint64_t cjgui_internal_renderer_owner_work_revision_linux(void)
{
    std::lock_guard<std::mutex> g(g_mainOwnerSchedLock);
    return g_mainOwnerSchedRevision;
}

void cjgui_internal_renderer_owner_notify_work_linux(void)
{
    {
        std::lock_guard<std::mutex> g(g_mainOwnerSchedLock);
        ++g_mainOwnerSchedRevision;
    }
    g_mainOwnerSchedCv.notify_all();
}

static int cjguiOhosOwnerWaitLinux(uint64_t observedRevision, uint64_t absoluteDeadlineNs,
    uint64_t *outIdleWaitNs)
{
    if (!outIdleWaitNs) return static_cast<int>(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
    *outIdleWaitNs = 0;
    const auto started = std::chrono::steady_clock::now();
    bool woke = false;
    {
        std::unique_lock<std::mutex> lk(g_mainOwnerSchedLock);
        const auto deadline = std::chrono::steady_clock::time_point(
            std::chrono::nanoseconds(absoluteDeadlineNs));
        woke = g_mainOwnerSchedCv.wait_until(lk, deadline, [&] {
            return g_mainOwnerSchedRevision != observedRevision ||
                g_applicationStopRequested.load();
        });
    }
    // A revision change is work and must never be credited as idle. Only the
    // deadline expiring with the same revision is an idle wait.
    if (!woke) {
        *outIdleWaitNs = static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now() - started).count());
    }
    return static_cast<int>(CJGUI_INTERNAL_RENDERER_OK);
}

int cjgui_internal_renderer_owner_wait_work_linux(uint64_t observedRevision,
    uint64_t absoluteDeadlineNs, uint64_t *outIdleWaitNs)
{
    return cjguiOhosOwnerWaitLinux(observedRevision, absoluteDeadlineNs, outIdleWaitNs);
}

int cjgui_internal_renderer_owner_wait_idle_work_linux(uint64_t observedRevision,
    uint64_t absoluteDeadlineNs, uint64_t *outIdleWaitNs)
{
    return cjguiOhosOwnerWaitLinux(observedRevision, absoluteDeadlineNs, outIdleWaitNs);
}

static uint64_t cjguiOhosMainClockNs(clockid_t clockId)
{
    struct timespec value {};
    if (clock_gettime(clockId, &value) != 0) return 0;
    return static_cast<uint64_t>(value.tv_sec) * 1000000000 +
        static_cast<uint64_t>(value.tv_nsec);
}

uint64_t cjgui_internal_renderer_owner_trace_ns(void)
{
    return cjguiOhosMainClockNs(CLOCK_MONOTONIC);
}

uint64_t cjgui_internal_renderer_owner_clock_ns(void)
{
    return cjguiOhosMainClockNs(CLOCK_MONOTONIC);
}

uint64_t cjgui_internal_renderer_owner_thread_cpu_ns(void)
{
    return cjguiOhosMainClockNs(CLOCK_THREAD_CPUTIME_ID);
}

// ---------------------------------------------------------------------------
// Accepted-layout coordinate lifetime
//
// The generation is the real surface generation. The coordinate epoch advances
// with the surface resize version (one real geometry transition per epoch), so
// a caller that froze an epoch can detect a resize instead of silently reusing
// coordinates from the previous surface.
// ---------------------------------------------------------------------------
uint64_t cjgui_internal_renderer_coordinate_lifetime(uint64_t session,
    uint64_t *outSessionGeneration)
{
    if (outSessionGeneration) *outSessionGeneration = 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return 0;
    cjguiOhosRefreshSurfaceLocked(s);
    if (outSessionGeneration) *outSessionGeneration = s->surfaceGeneration;
    return s->surfaceResizeVersion + 1;
}

int cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(uint64_t session,
    uint64_t *outSessionGeneration, uint64_t *outCoordinateEpoch)
{
    if (!outSessionGeneration || !outCoordinateEpoch) {
        return static_cast<int>(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
    }
    *outSessionGeneration = 0;
    *outCoordinateEpoch = 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s || !s->consumedPointerValid || s->consumedPointerGeneration == 0 ||
        s->consumedPointerEpoch == 0) {
        return 0;
    }
    *outSessionGeneration = s->consumedPointerGeneration;
    *outCoordinateEpoch = s->consumedPointerEpoch;
    return 1;
}

// ---------------------------------------------------------------------------
// Measured pump + pointer geometry sideband
//
// pump_event_measured is the existing pump plus two frozen facts: the real
// idle duration of a timeout turn, and the exact event this session consumed.
// pumped_pointer_geometry answers from that frozen copy against the accepted
// scene; a missing/stale match reports present=0 rather than another event's
// geometry.
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_pump_event_measured(uint64_t session,
    uint32_t timeoutMs, CjguiInternalRendererEvent *outEvent, uint64_t *outIdleWaitNs)
{
    if (!outEvent || !outIdleWaitNs) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outIdleWaitNs = 0;
    const auto started = std::chrono::steady_clock::now();
    const CjguiInternalRendererStatus status =
        cjgui_internal_renderer_pump_event(session, timeoutMs, outEvent);
    if (status == CJGUI_INTERNAL_RENDERER_OK && outEvent->kind == 0) {
        *outIdleWaitNs = static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now() - started).count());
    }
    if (status == CJGUI_INTERNAL_RENDERER_OK && outEvent->kind != 0) {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (s) {
            QueuedEvent &q = s->lastPumpedEvent;
            q = QueuedEvent{};
            q.kind = outEvent->kind;
            q.recordIndex = outEvent->recordIndex;
            q.selectionStart = outEvent->selectionStart;
            q.selectionEnd = outEvent->selectionEnd;
            q.modifierFlags = static_cast<uint32_t>(outEvent->modifierFlags);
            q.nodeId = outEvent->nodeId;
            q.projectionVersion = outEvent->projectionVersion;
            q.resourceId = outEvent->resourceId;
            q.nodeKind = outEvent->nodeKind;
            q.pointerX = outEvent->pointerX;
            q.pointerY = outEvent->pointerY;
            q.gestureEpoch = outEvent->gestureEpoch;
            q.appInstance = outEvent->gestureAppInstance;
            q.componentInstance = outEvent->gestureComponentInstance;
            q.surfaceGeneration = outEvent->gestureSurfaceGeneration;
            q.pointerId = outEvent->gesturePointerId;
            q.bindingEpoch = outEvent->bindingEpoch;
            s->lastPumpedValid = true;
            s->consumedPointerGeneration = s->surfaceGeneration;
            s->consumedPointerEpoch = s->surfaceResizeVersion + 1;
            s->consumedPointerValid = true;
        }
    }
    return status;
}

CjguiInternalRendererStatus cjgui_internal_renderer_pumped_pointer_geometry(uint64_t session,
    CjguiInternalRendererPointerEventGeometry *outGeometry)
{
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outGeometry = CjguiInternalRendererPointerEventGeometry{};
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!s->lastPumpedValid) return CJGUI_INTERNAL_RENDERER_OK;
    const QueuedEvent &q = s->lastPumpedEvent;
    const SceneNode *node = nullptr;
    for (const SceneNode &n : s->accepted) {
        if (n.pod.nodeId == q.nodeId && n.pod.resourceId == q.resourceId &&
            n.pod.nodeKind == q.nodeKind) {
            node = &n;
            break;
        }
    }
    // The consumed event may target a node the accepted scene no longer has;
    // that is an absent geometry fact, not another node's transform.
    if (node == nullptr) return CJGUI_INTERNAL_RENDERER_OK;
    double translateX = 0.0, translateY = 0.0, scaleX = 1.0, scaleY = 1.0;
    (void)cjguiOhosNodePaintTransform(*node, &translateX, &translateY, &scaleX, &scaleY);
    outGeometry->present = 1;
    outGeometry->kind = q.kind;
    outGeometry->nodeId = q.nodeId;
    outGeometry->projectionVersion = q.projectionVersion;
    outGeometry->resourceId = q.resourceId;
    outGeometry->nodeKind = q.nodeKind;
    outGeometry->x = static_cast<double>(q.pointerX);
    outGeometry->y = static_cast<double>(q.pointerY);
    outGeometry->translateX = translateX;
    outGeometry->translateY = translateY;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// Prepared scene transaction
//
// begin -> prepare(index) -> advance(ready) -> configure -> promote. Prepare
// only copies values; promote runs the ordinary node/geometry/semantic setters
// so run admission, image ownership and candidate-failure rules are shared with
// the direct path. Configure stays untouched and still seeds unchanged slots
// from the accepted scene.
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_begin_composable_preparation(uint64_t session,
    uint64_t preparationId, uint64_t baseSceneVersion, uint64_t projectionVersion,
    uint32_t nodeCount)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (baseSceneVersion != s->acceptedSceneVersion) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (nodeCount > 16384u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    auto preparation = std::make_shared<CjguiOhosMainPreparation>();
    preparation->active = true;
    preparation->id = preparationId;
    preparation->baseSceneVersion = baseSceneVersion;
    preparation->projectionVersion = projectionVersion;
    preparation->nodeCount = nodeCount;
    preparation->entries.assign(nodeCount, CjguiOhosMainPreparation::Entry{});
    s->mainPreparation = std::move(preparation);
    RLOGI("main-prepare begin session=%{public}llu id=%{public}llu base=%{public}llu projection=%{public}llu nodes=%{public}u",
          static_cast<unsigned long long>(session),
          static_cast<unsigned long long>(preparationId),
          static_cast<unsigned long long>(baseSceneVersion),
          static_cast<unsigned long long>(projectionVersion), nodeCount);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_node(uint64_t session,
    uint64_t preparationId, uint32_t index, const CjguiInternalRendererComposableNode *node,
    const CjguiInternalRendererComposableGeometry *geometry, const char *label, const char *value,
    const char *semanticId, const char *bindingKey, const char *rowKey, const char *parentRowKey,
    const char *semanticLabel, const char *encodedRuns)
{
    if (!node) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    const auto &preparation = s->mainPreparation;
    if (!preparation || !preparation->active || preparation->id != preparationId) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (index >= preparation->entries.size()) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CjguiOhosMainPreparation::Entry &entry = preparation->entries[index];
    entry.staged = true;
    entry.pod = *node;
    if (geometry) {
        entry.geometry = *geometry;
        entry.hasGeometry = true;
    } else {
        entry.geometry = CjguiInternalRendererComposableGeometry{};
        entry.hasGeometry = false;
    }
    entry.label = label ? label : "";
    entry.value = value ? value : "";
    entry.semanticId = semanticId ? semanticId : "";
    entry.bindingKey = bindingKey ? bindingKey : "";
    entry.rowKey = rowKey ? rowKey : "";
    entry.parentRowKey = parentRowKey ? parentRowKey : "";
    entry.semanticLabel = semanticLabel ? semanticLabel : "";
    entry.encodedRuns = encodedRuns ? encodedRuns : "";
    // prepare_composable_node carries no image identity: image nodes are staged
    // through the direct set_composable_scene_node path, which owns the path/id
    // arguments. Keeping empty strings makes that boundary explicit.
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_advance_composable_preparation(
    uint64_t session, uint64_t preparationId, uint64_t deadlineNs, uint32_t *outReady)
{
    (void)deadlineNs;
    if (!outReady) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outReady = 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    const auto &preparation = s->mainPreparation;
    if (!preparation || !preparation->active || preparation->id != preparationId) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    // Every prepared entry is scalar data; there is no platform worker to wait
    // for. The caller prepares exactly the nodes it wants restaged (retained
    // nodes stay seeded by configure), so readiness never requires every slot.
    preparation->ready = true;
    *outReady = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_promote_composable_preparation(
    uint64_t session, uint64_t preparationId)
{
    std::shared_ptr<CjguiOhosMainPreparation> preparation;
    uint64_t projectionVersion = 0;
    uint32_t nodeCount = 0;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        if (!s->mainPreparation || !s->mainPreparation->active ||
            s->mainPreparation->id != preparationId || !s->mainPreparation->ready) {
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        }
        if (!s->candidateOpen) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
        if (s->mainPreparation->baseSceneVersion != s->acceptedSceneVersion ||
            s->mainPreparation->projectionVersion != s->candidateProjectionVersion ||
            s->mainPreparation->nodeCount != s->candidate.size()) {
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        }
        preparation = s->mainPreparation;
        projectionVersion = preparation->projectionVersion;
        nodeCount = preparation->nodeCount;
    }
    for (uint32_t index = 0; index < nodeCount; ++index) {
        const CjguiOhosMainPreparation::Entry &entry = preparation->entries[index];
        if (!entry.staged) continue;  // unchanged slot stays seeded from accepted
        CjguiInternalRendererStatus status = cjgui_internal_renderer_set_composable_scene_node(
            session, index, &entry.pod, entry.label.c_str(), entry.value.c_str(),
            entry.imagePath.c_str(), entry.imageId.c_str(), entry.imageVersion);
        if (status == CJGUI_INTERNAL_RENDERER_OK && entry.hasGeometry) {
            status = cjgui_internal_renderer_set_composable_scene_geometry(
                session, projectionVersion, index, &entry.geometry);
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK && !entry.semanticId.empty()) {
            status = cjgui_internal_renderer_set_composable_node_semantic_identity(
                session, index, entry.semanticId.c_str());
        }
        if (status == CJGUI_INTERNAL_RENDERER_OK &&
            (!entry.bindingKey.empty() || !entry.rowKey.empty() ||
             !entry.parentRowKey.empty() || !entry.semanticLabel.empty())) {
            status = cjgui_internal_renderer_set_composable_node_semantic_metadata(
                session, index, entry.bindingKey.c_str(), entry.rowKey.c_str(),
                entry.parentRowKey.c_str(), entry.semanticLabel.c_str());
        }
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            RLOGW("main-prepare promote failed session=%{public}llu id=%{public}llu index=%{public}u status=%{public}d",
                  static_cast<unsigned long long>(session),
                  static_cast<unsigned long long>(preparationId), index,
                  static_cast<int>(status));
            return status;
        }
    }
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        if (s->mainPreparation == preparation) s->mainPreparation.reset();
    }
    RLOGI("main-prepare promote session=%{public}llu id=%{public}llu projection=%{public}llu nodes=%{public}u",
          static_cast<unsigned long long>(session),
          static_cast<unsigned long long>(preparationId),
          static_cast<unsigned long long>(projectionVersion), nodeCount);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_preparation(
    uint64_t session, uint64_t preparationId)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (s->mainPreparation && s->mainPreparation->id == preparationId) {
        s->mainPreparation.reset();
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_discard_composable_scene_candidate(uint64_t session)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->candidateOpen = false;
    s->candidateFailed = false;
    s->candidate.clear();
    s->candidateProjectionVersion = 0;
    // A discarded candidate drops its run declarations with it (the accepted
    // snapshot is the only surviving truth source).
    s->buildingRunTable = s->acceptedRunTable;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// Node semantic metadata / bytes staging
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_metadata(
    uint64_t session, uint32_t nodeIndex, const char *bindingKey, const char *rowKey,
    const char *parentRowKey, const char *semanticLabel)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!s->candidateOpen || nodeIndex >= s->candidate.size()) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    SceneNode &slot = s->candidate[nodeIndex];
    slot.semanticBindingKey = bindingKey ? bindingKey : "";
    slot.semanticRowKey = rowKey ? rowKey : "";
    slot.semanticParentRowKey = parentRowKey ? parentRowKey : "";
    slot.semanticLabel = semanticLabel ? semanticLabel : "";
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node_bytes(uint64_t session,
    uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node, const char *label,
    const char *value, const char *imageResourcePath, const char *imageResourceId,
    uint64_t imageResourceVersion, const uint8_t *bytes, uint32_t length)
{
    if (!node) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (bytes && length > 0u) {
        // The OHOS host decodes images from its own resource registry; the
        // transfer-call byte path has no decoder wired here. Refuse by name so
        // the caller keeps the previous accepted scene instead of drawing a
        // node whose image was silently dropped.
        RLOGW("scene node bytes refused: png transfer decode unavailable node=%{public}llu bytes=%{public}u",
              static_cast<unsigned long long>(node->nodeId), length);
        return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
    }
    return cjgui_internal_renderer_set_composable_scene_node(session, nodeIndex, node, label, value,
        imageResourcePath, imageResourceId, imageResourceVersion);
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_png_transfer(uint64_t session,
    const char *resourceIdentity, const uint8_t *bytes, uint32_t length, uint32_t *outWidth,
    uint32_t *outHeight, uint64_t *outDecodeMicros)
{
    (void)session;
    (void)resourceIdentity;
    (void)bytes;
    (void)length;
    if (outWidth) *outWidth = 0;
    if (outHeight) *outHeight = 0;
    if (outDecodeMicros) *outDecodeMicros = 0;
    return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_finish_composable_png_transfer(uint64_t session,
    const char *resourceIdentity, uint8_t accepted)
{
    (void)session;
    (void)resourceIdentity;
    (void)accepted;
    return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
}

// ---------------------------------------------------------------------------
// Window background staging
//
// The host really paints an opaque surface background. "system_content_area"
// cannot be installed on OHOS, so the snapshot reports the honest fallback
// instead of claiming the transparent system host was applied.
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_stage_window_background(uint64_t session,
    uint64_t projectionVersion, uint32_t mode, uint32_t colorScheme)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (mode > 1u || (colorScheme != 1u && colorScheme != 2u)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->stagedBackgroundMode = mode;
    s->stagedBackgroundColorScheme = colorScheme;
    s->stagedBackgroundProjection = projectionVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_background_snapshot(uint64_t session,
    CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot)
{
    if (!outSnapshot) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSnapshot = CjguiInternalRendererWindowBackgroundSnapshot{};
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    outSnapshot->acceptedSceneVersion = s->acceptedSceneVersion;
    outSnapshot->frameIndex = s->submittedFrameIndex;
    outSnapshot->requestRevision = s->stagedBackgroundProjection;
    outSnapshot->environmentRevision = s->backgroundRevision;
    outSnapshot->observationRevision = s->surfaceResizeVersion;
    outSnapshot->requestedMode = s->stagedBackgroundMode;
    outSnapshot->backend = 0;  // no system behind-window host on OHOS
    outSnapshot->actualMode = 2;  // opaque fallback
    outSnapshot->fallbackReason = s->stagedBackgroundMode == 0 ? 0 : 3;  // unsupported
    outSnapshot->completion = 1;  // current surface is painted
    outSnapshot->reduceTransparency = 0;
    outSnapshot->windowActive =
        (g_ingress.foregroundLevel && g_ingress.foregroundLevel() == 1) ? 1 : 0;
    outSnapshot->colorScheme = s->stagedBackgroundColorScheme == 2 ? 2 : 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// Selection background support + context menu guard
// ---------------------------------------------------------------------------
uint32_t cjgui_internal_renderer_selection_background_version(void)
{
    // Version 1: the shared selection paint path draws a real background run.
    return 1;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_context_menu_guard(
    uint64_t session, uint64_t sceneVersion, uint64_t layerScope, uint64_t requestId,
    uint64_t layerNodeId, int64_t resourceId, uint32_t nodeKind, int64_t x, int64_t y,
    int64_t width, int64_t height, uint32_t enabled)
{
    (void)layerScope;
    (void)layerNodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)x;
    (void)y;
    (void)width;
    (void)height;
    (void)enabled;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (sceneVersion != s->acceptedSceneVersion) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    // The OHOS command menu is a host surface with its own dismissal path; the
    // layered guard that suppresses owner dismissal belongs to the macOS
    // backing-layer implementation. Refuse by name rather than pretending it
    // is armed.
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

// ---------------------------------------------------------------------------
// Diagnostics
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_set_diagnostic_overlay(uint64_t session,
    uint32_t flags, uint64_t selectedNodeId, uint8_t hasSelection)
{
    (void)selectedNodeId;
    (void)hasSelection;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->diagnosticOverlayFlags = flags;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_diagnostic_timing(uint64_t session,
    uint32_t enabled)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->diagnosticTimingEnabled = enabled != 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_timing(uint64_t session,
    CjguiInternalRendererDiagnosticTiming *outTiming)
{
    if (!outTiming) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outTiming = CjguiInternalRendererDiagnosticTiming{};
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    outTiming->sceneVersion = s->acceptedSceneVersion;
    outTiming->frameIndex = s->submittedFrameIndex;
    outTiming->enabled = s->diagnosticTimingEnabled ? 1 : 0;
    outTiming->clockAvailable = 1;
    // The per-phase counters were never collected for this backend; zero is
    // the honest value, not a fabricated measurement.
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_workload(uint64_t session,
    CjguiInternalRendererDiagnosticWorkload *outWorkload)
{
    if (!outWorkload) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outWorkload = CjguiInternalRendererDiagnosticWorkload{};
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    outWorkload->sceneVersion = s->acceptedSceneVersion;
    outWorkload->frameIndex = s->submittedFrameIndex;
    outWorkload->reusableResourceBytes = g_imageLiveBytes.load();
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_resources(uint64_t session,
    CjguiInternalRendererDiagnosticResources *outResources)
{
    if (!outResources) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outResources = CjguiInternalRendererDiagnosticResources{};
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    outResources->sceneVersion = s->acceptedSceneVersion;
    outResources->frameIndex = s->submittedFrameIndex;
    outResources->liveEffectBytes = g_imageLiveBytes.load();
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_node_geometry(uint64_t session,
    uint32_t nodeIndex, CjguiInternalRendererDiagnosticNodeGeometry *outGeometry)
{
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outGeometry = CjguiInternalRendererDiagnosticNodeGeometry{};
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (nodeIndex >= s->accepted.size()) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    const SceneNode &node = s->accepted[nodeIndex];
    outGeometry->sceneVersion = s->acceptedSceneVersion;
    outGeometry->frameIndex = s->submittedFrameIndex;
    outGeometry->outputX = node.pod.x;
    outGeometry->outputY = node.pod.y;
    outGeometry->outputWidth = node.pod.width;
    outGeometry->outputHeight = node.pod.height;
    outGeometry->sampleX = node.pod.x;
    outGeometry->sampleY = node.pod.y;
    outGeometry->sampleWidth = node.pod.width;
    outGeometry->sampleHeight = node.pod.height;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// Font resource registry
//
// OHOS text uses the system font collection; there is no installed-font
// registry in this host. Every entry that would claim a registered resource is
// refused by name. Stats describe that (all zeros) with OK because it is a
// complete answer about an empty registry.
// ---------------------------------------------------------------------------
int32_t cjgui_internal_renderer_font_resource_register(uint32_t kind, const char *source,
    uint32_t fallback, uint32_t *code)
{
    (void)kind;
    (void)source;
    (void)fallback;
    if (code) *code = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

int32_t cjgui_internal_renderer_font_resource_release(uint32_t code)
{
    (void)code;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

int64_t cjgui_internal_renderer_font_resource_copy_family(uint32_t code, uint8_t *buffer,
    uint64_t capacity)
{
    (void)code;
    (void)buffer;
    (void)capacity;
    return -1;
}

int32_t cjgui_internal_renderer_font_resource_stats(uint64_t *values)
{
    if (values) {
        for (int index = 0; index < 8; ++index) values[index] = 0;
    }
    return static_cast<int32_t>(CJGUI_INTERNAL_RENDERER_OK);
}

uint32_t cjgui_internal_renderer_font_resource_version(void)
{
    return 0;
}

// ---------------------------------------------------------------------------
// Platform state queries
// ---------------------------------------------------------------------------
int64_t cjgui_macos_control_accent_srgb8(void)
{
    // OHOS exposes no per-app control accent through this host; 0 means
    // "unknown", so the shared layer keeps its default token.
    return 0;
}

int32_t cjgui_macos_effective_dark_mode(void)
{
    // No system color-scheme observation is wired in this host. Light is the
    // honest current effective value, not a guess at the platform setting.
    return 0;
}

int32_t cjgui_macos_reduce_motion_enabled(void)
{
    return 0;
}

int32_t cjgui_macos_window_minimized(int64_t windowNumber)
{
    (void)windowNumber;
    return 0;
}

int32_t cjgui_macos_window_visible(int64_t windowNumber)
{
    (void)windowNumber;
    return (g_ingress.foregroundLevel && g_ingress.foregroundLevel() == 1) ? 1 : 0;
}

// ---------------------------------------------------------------------------
// Data transfer / installed range / owned source selection / composition
//
// These families belong to the macOS resident source adapter. The OHOS host
// owns its text through the existing proxy/IME path (which keeps FIFO,
// binding epochs and late-callback refusal). Named refusals here prevent a
// caller from treating an unimplemented transfer as completed.
// ---------------------------------------------------------------------------
int64_t cjgui_internal_renderer_data_transfer_event_expected_owner_version(uint64_t session)
{
    (void)session;
    return -1;
}

uint64_t cjgui_internal_renderer_data_transfer_event_delivery_ordinal(uint64_t session)
{
    (void)session;
    return 0;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_data_transfer_item_bytes(
    uint64_t session, uint32_t itemIndex, const uint8_t *bytes, uint32_t length)
{
    (void)session;
    (void)itemIndex;
    (void)bytes;
    (void)length;
    // Binary transfer payloads are not decoded by this host; the caller sees a
    // named refusal and keeps the previous accepted menu/transfer state.
    return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
}

uint32_t cjgui_internal_renderer_data_transfer_event_binary_size(uint64_t session, uint64_t eventId)
{
    (void)session;
    (void)eventId;
    return 0;
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_data_transfer_event_binary(uint64_t session,
    uint64_t eventId, uint8_t *outBytes, uint32_t capacity)
{
    (void)session;
    (void)eventId;
    (void)outBytes;
    (void)capacity;
    return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_arm(uint64_t session,
    const CjguiInternalInstalledRangeCandidate *candidate)
{
    (void)session;
    (void)candidate;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_receipt(uint64_t session,
    uint64_t nonce, CjguiInternalInstalledRangeReceipt *outReceipt)
{
    (void)session;
    (void)nonce;
    if (outReceipt) *outReceipt = CjguiInternalInstalledRangeReceipt{};
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_active_receipt(uint64_t session,
    uint64_t nonce, CjguiInternalInstalledRangeReceipt *outReceipt)
{
    return cjgui_internal_renderer_installed_range_receipt(session, nonce, outReceipt);
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_activate(uint64_t session,
    uint64_t nonce, uint64_t proxyGeneration, uint64_t selectionRevision)
{
    (void)session;
    (void)nonce;
    (void)proxyGeneration;
    (void)selectionRevision;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_cancel(uint64_t session,
    uint64_t nonce)
{
    (void)session;
    (void)nonce;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_ack_installed_range(uint64_t session,
    const CjguiInternalInstalledRangeIntent *intent, uint32_t accepted, int64_t receiptVersionAfter)
{
    (void)session;
    (void)intent;
    (void)accepted;
    (void)receiptVersionAfter;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_release_installed_range(uint64_t session,
    uint64_t windowInstanceToken, uint64_t bindingEpoch)
{
    (void)session;
    (void)windowInstanceToken;
    (void)bindingEpoch;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_claim_last_pumped_range(uint64_t session,
    uint64_t nodeId, int64_t resourceId, uint64_t bindingEpoch, uint64_t sceneVersion,
    CjguiInternalInstalledRangeIntent *outIntent)
{
    (void)session;
    (void)nodeId;
    (void)resourceId;
    (void)bindingEpoch;
    (void)sceneVersion;
    if (outIntent) *outIntent = CjguiInternalInstalledRangeIntent{};
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_claimed_range_bytes(uint64_t session,
    uint64_t seq, uint8_t *preBody, uint32_t preBodyCapacity, uint8_t *replacement,
    uint32_t replacementCapacity, uint8_t *postBody, uint32_t postBodyCapacity)
{
    (void)session;
    (void)seq;
    (void)preBody;
    (void)preBodyCapacity;
    (void)replacement;
    (void)replacementCapacity;
    (void)postBody;
    (void)postBodyCapacity;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_install_owned_source_selection(
    uint64_t session, uint64_t nodeId, int64_t resourceId, uint64_t sceneVersion,
    uint64_t bindingEpoch, uint64_t requestId, uint64_t deadlineNs, const char *expectedValue,
    uint32_t selectionStart, uint32_t selectionEnd, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd, uint8_t *outDeferred)
{
    (void)session;
    (void)nodeId;
    (void)resourceId;
    (void)sceneVersion;
    (void)bindingEpoch;
    (void)requestId;
    (void)deadlineNs;
    (void)expectedValue;
    if (outSelectionStart) *outSelectionStart = selectionStart;
    if (outSelectionEnd) *outSelectionEnd = selectionEnd;
    if (outDeferred) *outDeferred = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_read_composable_selection(uint64_t session,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *expectedValue, uint32_t *outSelectionStart, uint32_t *outSelectionEnd)
{
    (void)session;
    (void)nodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)sceneVersion;
    (void)expectedValue;
    if (outSelectionStart) *outSelectionStart = 0;
    if (outSelectionEnd) *outSelectionEnd = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_reanchor_composition(uint64_t session,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *newBaseText, uint32_t replacementStart16, uint32_t replacementLength16,
    uint32_t *outMechanism, uint32_t *outMarkedStart16, uint32_t *outMarkedLength16,
    uint32_t *outInnerStart16, uint32_t *outInnerEnd16)
{
    (void)session;
    (void)nodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)sceneVersion;
    (void)newBaseText;
    (void)replacementStart16;
    (void)replacementLength16;
    if (outMechanism) *outMechanism = 0;
    if (outMarkedStart16) *outMarkedStart16 = 0;
    if (outMarkedLength16) *outMarkedLength16 = 0;
    if (outInnerStart16) *outInnerStart16 = 0;
    if (outInnerEnd16) *outInnerEnd16 = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_arm_composition_reanchor(uint64_t session,
    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, const char *baseText,
    uint32_t replacementStart16, uint32_t replacementLength16)
{
    (void)session;
    (void)nodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)baseText;
    (void)replacementStart16;
    (void)replacementLength16;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(
    uint64_t session, uint64_t gestureEpoch)
{
    uint64_t appInstance = 0, componentInstance = 0, surfaceGeneration = 0;
    int64_t pointerId = -1;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        if (!s->lastPumpedValid || s->lastPumpedEvent.gestureEpoch != gestureEpoch) {
            // No captured pointer for this epoch: nothing to cancel.
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        appInstance = s->lastPumpedEvent.appInstance;
        componentInstance = s->lastPumpedEvent.componentInstance;
        surfaceGeneration = s->lastPumpedEvent.surfaceGeneration;
        pointerId = s->lastPumpedEvent.pointerId;
    }
    return cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(session,
        appInstance, componentInstance, surfaceGeneration, pointerId, gestureEpoch);
}

// ---------------------------------------------------------------------------
// Source install gate (Windows-shaped) and present holds (test-only)
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_set_source_install_gate(uint64_t session,
    uint64_t bindingEpoch, uint64_t requestId, uint8_t pending)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->sourceInstallGatePending = pending != 0;
    s->sourceInstallGateBinding = bindingEpoch;
    s->sourceInstallGateRequest = requestId;
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint8_t cjgui_internal_renderer_source_install_pending_scalar(uint64_t session)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s || !s->sourceInstallGatePending) return 0;
    return 1;
}

CjguiInternalRendererStatus cjgui_internal_renderer_test_hold_next_composable_present(uint64_t session)
{
    (void)session;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_test_resolve_pending_composable_present(
    uint64_t session)
{
    (void)session;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

// ---------------------------------------------------------------------------
// Text measurement
//
// Plain measurement (no style runs) is produced by an own OH_Drawing typography
// so it can run on any owner thread without borrowing the render thread's font
// pool. Style runs are a real capability of the shared measure declaration;
// this host has not wired run segmentation into this entry, so it refuses by
// name instead of returning the base-style measurement as if runs applied.
// ---------------------------------------------------------------------------
struct CjguiOhosPlainMetrics {
    bool ok = false;
    uint32_t width = 0;
    uint32_t height = 0;
    uint32_t lineHeight = 0;
    uint32_t baseline = 0;
};

static int cjguiOhosMainMapWeight(uint32_t weight)
{
    if (weight < 100u) return FONT_WEIGHT_400;
    int step = (static_cast<int>(weight) + 50) / 100 * 100;
    if (step < 100) step = 100;
    if (step > 900) step = 900;
    return step;
}

static CjguiOhosPlainMetrics cjguiOhosMainMeasurePlain(const std::string &text, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, uint32_t maximumWidth, double letterSpacing,
    double lineHeightPoints, uint32_t maximumLines, bool ellipsis)
{
    CjguiOhosPlainMetrics out;
    if (fontSize <= 0.0) return out;
    // An empty text is a legal label: the shared layout measures it to place
    // its zero-width leaf. Native typography reports no line for it, so answer
    // with the same deterministic zero-width line metrics the Cangjie fallback
    // measurer uses instead of refusing the candidate.
    if (text.empty()) {
        const double line = std::max(1.0, std::round(fontSize * 1.30));
        out.ok = true;
        out.width = 0;
        out.height = static_cast<uint32_t>(line);
        out.lineHeight = static_cast<uint32_t>(line);
        out.baseline = static_cast<uint32_t>(std::max(0.0, std::round(fontSize * 0.98)));
        return out;
    }
    OH_Drawing_FontCollection *collection = OH_Drawing_CreateFontCollection();
    if (!collection) return out;
    OH_Drawing_TypographyStyle *style = OH_Drawing_CreateTypographyStyle();
    if (!style) {
        OH_Drawing_DestroyFontCollection(collection);
        return out;
    }
    if (maximumLines > 0u) {
        OH_Drawing_SetTypographyTextMaxLines(style, static_cast<int>(maximumLines));
        if (ellipsis) {
            OH_Drawing_SetTypographyTextEllipsisModal(style, static_cast<int>(ELLIPSIS_MODAL_TAIL));
            OH_Drawing_SetTypographyTextEllipsis(style, "\u2026");
        }
    }
    OH_Drawing_TypographyCreate *handler = OH_Drawing_CreateTypographyHandler(style, collection);
    OH_Drawing_DestroyTypographyStyle(style);
    if (!handler) {
        OH_Drawing_DestroyFontCollection(collection);
        return out;
    }
    OH_Drawing_TextStyle *textStyle = OH_Drawing_CreateTextStyle();
    if (!textStyle) {
        OH_Drawing_DestroyTypographyHandler(handler);
        OH_Drawing_DestroyFontCollection(collection);
        return out;
    }
    OH_Drawing_SetTextStyleFontSize(textStyle, fontSize);
    OH_Drawing_SetTextStyleFontWeight(textStyle, cjguiOhosMainMapWeight(fontWeight));
    const char *family = "HarmonyOS Sans";
    OH_Drawing_SetTextStyleFontFamilies(textStyle, 1, &family);
    if (fontFamily == 2u || fontFamily == 3u) {
        OH_Drawing_SetTextStyleFontStyle(textStyle, FONT_STYLE_ITALIC);
    }
    if (letterSpacing != 0.0) OH_Drawing_SetTextStyleLetterSpacing(textStyle, letterSpacing);
    if (lineHeightPoints > 0.0) OH_Drawing_SetTextStyleFontHeight(textStyle, lineHeightPoints / fontSize);
    OH_Drawing_TypographyHandlerPushTextStyle(handler, textStyle);
    OH_Drawing_TypographyHandlerAddText(handler, text.c_str());
    OH_Drawing_DestroyTextStyle(textStyle);
    OH_Drawing_Typography *typography = OH_Drawing_CreateTypography(handler);
    OH_Drawing_DestroyTypographyHandler(handler);
    if (!typography) {
        OH_Drawing_DestroyFontCollection(collection);
        return out;
    }
    const double layoutWidth = maximumWidth == 0u ? 1000000.0 : static_cast<double>(maximumWidth);
    OH_Drawing_TypographyLayout(typography, layoutWidth);
    const double height = OH_Drawing_TypographyGetHeight(typography);
    const double longest = OH_Drawing_TypographyGetLongestLine(typography);
    const size_t lines = OH_Drawing_TypographyGetLineCount(typography);
    OH_Drawing_DestroyTypography(typography);
    OH_Drawing_DestroyFontCollection(collection);
    if (!std::isfinite(height) || height <= 0.0) return out;
    double lineHeight = lines > 0 ? height / static_cast<double>(lines) : height;
    if (lineHeight < 1.0) lineHeight = fontSize * 1.2;
    out.ok = true;
    out.width = static_cast<uint32_t>(longest + 0.5);
    out.height = static_cast<uint32_t>(height + 0.5);
    out.lineHeight = static_cast<uint32_t>(lineHeight + 0.5);
    out.baseline = static_cast<uint32_t>(lineHeight * 0.8 + 0.5);
    return out;
}

static bool cjguiOhosMainRunsEmpty(const char *runs)
{
    return runs == nullptr || runs[0] == '\0';
}

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_styled_text(uint64_t session,
    const char *text, double fontSize, uint32_t weight, uint32_t family, uint32_t width,
    double spacing, double height, uint32_t maximumLines, uint32_t overflow, const char *runs,
    CjguiInternalRendererTextMeasurement *output)
{
    if (!text || !output) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (!cjguiOhosMainRunsEmpty(runs)) {
        RLOGW("styled text measure refused: style runs not wired on this backend session=%{public}llu",
              static_cast<unsigned long long>(session));
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    const CjguiOhosPlainMetrics m = cjguiOhosMainMeasurePlain(text, fontSize, weight, family, width,
        spacing, height, maximumLines, overflow == 1);
    if (!m.ok) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    output->width = m.width;
    output->height = m.height;
    output->lineHeight = m.lineHeight;
    output->baseline = m.baseline;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// Async measurement ABI
//
// Jobs are measured synchronously in begin because the shared caller accepts
// READY on the first poll (it only treats PENDING as "still running"). The
// result is a real typography measurement of the copied text; the caller's
// pointer is never retained. A later worker-thread implementation can keep this
// exact handle/poll contract.
// ---------------------------------------------------------------------------
struct CjguiOhosMainAsyncJob {
    uint32_t height = 0;
    CjguiInternalRendererTextMeasurement metrics{};
    int32_t failure = 0;
};

static std::mutex g_mainAsyncLock;
static std::map<uint64_t, CjguiOhosMainAsyncJob> g_mainAsyncJobs;
static uint64_t g_mainAsyncNextHandle = 1u;

static uint64_t cjguiOhosMainStoreAsyncJob(const CjguiOhosMainAsyncJob &job)
{
    std::lock_guard<std::mutex> g(g_mainAsyncLock);
    const uint64_t handle = g_mainAsyncNextHandle++;
    g_mainAsyncJobs[handle] = job;
    return handle;
}

static bool cjguiOhosMainTakeAsyncJob(uint64_t handle, CjguiOhosMainAsyncJob *out)
{
    std::lock_guard<std::mutex> g(g_mainAsyncLock);
    auto it = g_mainAsyncJobs.find(handle);
    if (it == g_mainAsyncJobs.end()) return false;
    if (out) *out = it->second;
    return true;
}

static bool cjguiOhosMainReleaseAsyncJob(uint64_t handle)
{
    std::lock_guard<std::mutex> g(g_mainAsyncLock);
    return g_mainAsyncJobs.erase(handle) > 0;
}

static bool cjguiOhosMainAsyncTextValid(const char *text, uint64_t byteLength)
{
    // Empty text is a valid measurable label (see cjguiOhosMainMeasurePlain);
    // only a null pointer, an over-budget payload or a non-NUL-terminated
    // mismatch is refused here.
    if (!text || byteLength > 131072u) return false;
    return std::strlen(text) == byteLength;
}

int32_t cjgui_async_composable_multiline_begin(const char *text, uint64_t byteLength,
    double fontSize, uint32_t fontWeight, uint32_t fontFamily, uint32_t contentWidth,
    uint64_t *outHandle)
{
    if (outHandle) *outHandle = 0;
    if (!outHandle || !cjguiOhosMainAsyncTextValid(text, byteLength) || fontSize <= 0.0) {
        return 7;  // CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT
    }
    const CjguiOhosPlainMetrics m = cjguiOhosMainMeasurePlain(std::string(text, byteLength),
        fontSize, fontWeight, fontFamily, contentWidth, 0.0, 0.0, 0, false);
    if (!m.ok) return 4;  // CJGUI_ASYNC_MEASURE_FAILED
    CjguiOhosMainAsyncJob job;
    job.height = m.height;
    job.metrics.width = m.width;
    job.metrics.height = m.height;
    job.metrics.lineHeight = m.lineHeight;
    job.metrics.baseline = m.baseline;
    *outHandle = cjguiOhosMainStoreAsyncJob(job);
    return 0;  // CJGUI_ASYNC_MEASURE_STARTED
}

int32_t cjgui_async_composable_text_metrics_begin(const char *text, uint64_t byteLength,
    double fontSize, uint32_t fontWeight, uint32_t fontFamily, uint32_t maximumWidth,
    uint64_t *outHandle)
{
    if (outHandle) *outHandle = 0;
    if (!outHandle || !cjguiOhosMainAsyncTextValid(text, byteLength) || fontSize <= 0.0) {
        RLOGW("ohos main async text invalid: bytes=%{public}llu font=%{public}.2f family=%{public}u null=%{public}d "
              "strlen=%{public}zu head=%.32s",
              static_cast<unsigned long long>(byteLength), fontSize, fontFamily, text ? 0 : 1,
              text ? std::strlen(text) : static_cast<size_t>(0), text ? text : "");
        return 7;
    }
    const CjguiOhosPlainMetrics m = cjguiOhosMainMeasurePlain(std::string(text, byteLength),
        fontSize, fontWeight, fontFamily, maximumWidth, 0.0, 0.0, 0, false);
    if (!m.ok) {
        RLOGW("ohos main async text measure failed: bytes=%{public}llu font=%{public}.2f family=%{public}u head=%.32s",
              static_cast<unsigned long long>(byteLength), fontSize, fontFamily, text);
        return 4;
    }
    CjguiOhosMainAsyncJob job;
    job.height = m.height;
    job.metrics.width = m.width;
    job.metrics.height = m.height;
    job.metrics.lineHeight = m.lineHeight;
    job.metrics.baseline = m.baseline;
    *outHandle = cjguiOhosMainStoreAsyncJob(job);
    return 0;
}

int32_t CjguiAsyncMultilineMeasurePoll(uint64_t handle, uint32_t *outHeight, int32_t *outFailure)
{
    if (outHeight) *outHeight = 0;
    if (outFailure) *outFailure = 0;
    CjguiOhosMainAsyncJob job;
    if (!cjguiOhosMainTakeAsyncJob(handle, &job)) return 6;  // STALE_HANDLE
    if (outHeight) *outHeight = job.height;
    if (outFailure) *outFailure = job.failure;
    return 3;  // READY
}

int32_t CjguiAsyncMultilineMeasureRelease(uint64_t handle, int32_t disposition)
{
    (void)disposition;
    return cjguiOhosMainReleaseAsyncJob(handle) ? 0 : 6;
}

int32_t CjguiAsyncTextMetricsPoll(uint64_t handle,
    CjguiInternalRendererTextMeasurement *outMetrics, int32_t *outFailure)
{
    if (outMetrics) *outMetrics = CjguiInternalRendererTextMeasurement{};
    if (outFailure) *outFailure = 0;
    CjguiOhosMainAsyncJob job;
    if (!cjguiOhosMainTakeAsyncJob(handle, &job)) return 6;
    if (outMetrics) *outMetrics = job.metrics;
    if (outFailure) *outFailure = job.failure;
    return 3;
}

// ---------------------------------------------------------------------------
// Accepted text geometry
//
// The host retains the accepted editing caret rectangle from the last real
// paint. A caret query can answer exactly for that accepted caret. Per-line
// enumeration, position v1 and neighbor queries need a retained per-line
// layout table that this host does not publish; they refuse by name instead of
// returning offsets from a different layout.
// ---------------------------------------------------------------------------
CjguiInternalRendererStatus cjgui_internal_renderer_text_geometry_caret(uint64_t session,
    int64_t nodeId, int64_t displayByte, double caretWidthPt, uint64_t expectedSceneVersion,
    uint32_t affinity, double *outX, double *outY, double *outWidth, double *outHeight)
{
    if (!outX || !outY || !outWidth || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outX = 0.0;
    *outY = 0.0;
    *outWidth = 0.0;
    *outHeight = 0.0;
    (void)caretWidthPt;
    (void)affinity;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (expectedSceneVersion != 0 && expectedSceneVersion != s->acceptedSceneVersion) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    const AcceptedCaretRect &rect = s->activeCaret;
    if (!rect.valid || rect.nodeId != static_cast<uint64_t>(nodeId)) {
        return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    }
    // The accepted caret names a UTF-16 offset in the exact painted text; the
    // caller's displayByte is a UTF-8 offset into the same display value.
    const size_t displayByteForCaret = utf16ToUtf8(rect.text.substr(0, rect.caret)).size();
    if (displayByte != static_cast<int64_t>(displayByteForCaret)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    *outX = rect.left;
    *outY = rect.top;
    *outWidth = rect.right - rect.left;
    *outHeight = rect.bottom - rect.top;
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_text_line_rect_count(uint64_t session, int64_t nodeId,
    int64_t startByte, int64_t endByte, int32_t maxRects, uint64_t expectedSceneVersion)
{
    (void)session;
    (void)nodeId;
    (void)startByte;
    (void)endByte;
    (void)maxRects;
    (void)expectedSceneVersion;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

double cjgui_internal_renderer_text_line_rect_value(uint64_t session, int64_t nodeId,
    int64_t startByte, int64_t endByte, int32_t maxRects, int32_t index, int32_t component,
    uint64_t expectedSceneVersion)
{
    (void)session;
    (void)nodeId;
    (void)startByte;
    (void)endByte;
    (void)maxRects;
    (void)index;
    (void)component;
    (void)expectedSceneVersion;
    return 0.0;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_v1(uint64_t session, uint64_t nodeId, uint64_t scene,
    uint32_t operation, int64_t displayByte, uint32_t affinity, uint64_t layoutLease,
    uint64_t stopId, uint32_t direction, double x, double y, uint64_t *meta, double *rect)
{
    (void)session;
    (void)nodeId;
    (void)scene;
    (void)operation;
    (void)displayByte;
    (void)affinity;
    (void)layoutLease;
    (void)stopId;
    (void)direction;
    (void)x;
    (void)y;
    if (meta) {
        for (int index = 0; index < 8; ++index) meta[index] = 0;
    }
    if (rect) {
        for (int index = 0; index < 4; ++index) rect[index] = 0.0;
    }
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_stats_v1(uint64_t session, uint64_t *counts)
{
    (void)session;
    if (counts) {
        for (int index = 0; index < 4; ++index) counts[index] = 0;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_stop_resolve(uint64_t session, uint64_t nodeId,
    int64_t displayByte, uint32_t branchIn, uint64_t expectedSceneVersion, uint32_t *outByte,
    uint32_t *outBranch, uint32_t *outLineFirstChar, uint32_t *outLineLength, double *outX)
{
    (void)session;
    (void)nodeId;
    (void)displayByte;
    (void)branchIn;
    (void)expectedSceneVersion;
    if (outByte) *outByte = 0;
    if (outBranch) *outBranch = 0;
    if (outLineFirstChar) *outLineFirstChar = 0;
    if (outLineLength) *outLineLength = 0;
    if (outX) *outX = 0.0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_stop_neighbor(uint64_t session, uint64_t nodeId,
    int64_t displayByte, uint32_t branchIn, uint32_t left, uint64_t expectedSceneVersion,
    uint32_t *outByte, uint32_t *outBranch)
{
    (void)session;
    (void)nodeId;
    (void)displayByte;
    (void)branchIn;
    (void)left;
    (void)expectedSceneVersion;
    if (outByte) *outByte = 0;
    if (outBranch) *outBranch = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

int32_t cjgui_internal_renderer_text_visual_neighbor(uint64_t session, int64_t nodeId,
    int64_t displayByte, uint32_t left, uint64_t expectedSceneVersion, uint32_t caretAffinity,
    uint32_t *outNeighborByte, uint32_t *outAffinity)
{
    (void)session;
    (void)nodeId;
    (void)displayByte;
    (void)left;
    (void)expectedSceneVersion;
    (void)caretAffinity;
    if (outNeighborByte) *outNeighborByte = 0;
    if (outAffinity) *outAffinity = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

} // extern "C" (frozen main-core adapter)
