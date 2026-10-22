// Reuse the existing controlled native session, without rerunning its suite.
#define main CjguiGeometryBatchReuseBaseMain
#import "composable_preparation_reuse_test.m"
#undef main

enum { GeometryCount = 256 };
static _Atomic(bool) geometryDone;
static CjguiInternalRendererStatus geometryStatus;
static uint64_t geometrySession;
static CjguiInternalRendererComposableGeometry geometryValues[GeometryCount];

static void *writeGeometry(void *unused) {
    (void)unused;
    @autoreleasepool {
        geometryStatus = cjgui_internal_renderer_set_composable_scene_geometry_batch(
            geometrySession, 2, GeometryCount, geometryValues);
        atomic_store(&geometryDone, true);
    }
    return NULL;
}

static BOOL geometryWorker(void) {
    atomic_store(&geometryDone, false);
    pthread_t worker;
    if (pthread_create(&worker, NULL, writeGeometry, NULL)) return NO;
    uint64_t end = CjguiOwnerTraceNanoseconds() + UINT64_C(2000000000);
    while (!atomic_load(&geometryDone) && CjguiOwnerTraceNanoseconds() < end)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
    if (!atomic_load(&geometryDone)) return NO;
    pthread_join(worker, NULL);
    return YES;
}

int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_TRACE_LIGHT", "1", 1);
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil, *other = nil;
    uint64_t token = 0, otherToken = 0;
    if (!makeSession(&ctx, &token) || !makeSession(&other, &otherToken)) return 2;
    geometrySession = token;
    CJGuiInternalComposableSceneNode *accepted = ctx.composableNodes[0];
    CjguiInternalRendererComposableGeometry original = accepted.geometry;
    CHECK(CjguiConfigureComposableSceneOnMain(token, 2, GeometryCount) == 0, "geometry_batch_configure");
    for (uint32_t i = 0; i < GeometryCount; i++) {
        CjguiInternalRendererComposableNode node = accepted.node;
        node.nodeId = 100 + i; node.resourceId = 100 + i; node.projectionVersion = 2;
        CHECK(CjguiSetComposableSceneNodeOnMain(token, i, &node, "", "", "", "", 0, nil) == 0,
              "geometry_batch_stage_node");
        geometryValues[i] = (CjguiInternalRendererComposableGeometry){.nodeId = node.nodeId,
            .translateX = 12.5 + i * .125, .translateY = -.375, .scaleX = 1, .scaleY = 1};
    }
    CHECK(cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, 0, geometryValues) != 0 &&
          cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, 1025, geometryValues) != 0 &&
          cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 3, GeometryCount, geometryValues) != 0 &&
          cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, GeometryCount, NULL) != 0,
          "geometry_batch_rejects_shape_and_scene");
    geometryValues[GeometryCount - 1].nodeId++;
    CHECK(cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, GeometryCount, geometryValues) != 0 &&
          ctx.stagedComposableGeometryIndices.count == 0, "geometry_batch_bad_tail_does_not_consume_prefix");
    geometryValues[GeometryCount - 1].nodeId--;
    geometryValues[GeometryCount - 1].translateX = NAN;
    CHECK(cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, GeometryCount, geometryValues) != 0 &&
          ctx.stagedComposableGeometryIndices.count == 0, "geometry_batch_nan_does_not_consume_prefix");
    geometryValues[GeometryCount - 1].translateX = 12.5 + (GeometryCount - 1) * .125;
    geometryValues[0].clipCount = 1;
    CHECK(cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, GeometryCount, geometryValues) != 0 &&
          ctx.stagedComposableGeometryIndices.count == 0, "geometry_batch_clip_contract_unchanged");
    geometryValues[0].clipCount = 0;
    gCjguiMainThreadDispatchEnabled = NO;
    CHECK(geometryWorker() && geometryStatus == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD &&
          ctx.stagedComposableGeometryIndices.count == 0, "geometry_batch_respects_dispatch_disabled");
    gCjguiMainThreadDispatchEnabled = YES;
    uint64_t dispatchBefore = atomic_load(&gCjguiOwnerTraceDispatchSequence);
    CHECK(geometryWorker() && geometryStatus == 0, "geometry_batch_owner_to_main");
    uint64_t dispatches = atomic_load(&gCjguiOwnerTraceDispatchSequence) - dispatchBefore;
    CHECK(dispatches == 1, "geometry_batch_256_nodes_one_main_hop");
    CHECK(ctx.stagedComposableGeometryIndices.count == GeometryCount, "geometry_batch_complete_snapshot");
    for (uint32_t i = 0; i < GeometryCount; i++) {
        CjguiInternalRendererComposableGeometry actual = ctx.stagedComposableNodes[i].geometry;
        CHECK(memcmp(&actual, &geometryValues[i], sizeof(actual)) == 0, "geometry_batch_exact_fractional_geometry");
    }
    CjguiInternalRendererComposableGeometry stillAccepted = accepted.geometry;
    CHECK(ctx.composableSceneVersion == 1 && ctx.composableNodes[0] == accepted &&
          memcmp(&stillAccepted, &original, sizeof(original)) == 0 && other.composableSceneVersion == 1 &&
          other.composableNodes.count == 1, "geometry_batch_keeps_accepted_and_peer_unchanged");
    CHECK(cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, GeometryCount, geometryValues) != 0,
          "geometry_batch_duplicate_slots_refused");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(token) == 0 &&
          ctx.stagedComposableNodes.count == 0 && ctx.composableNodes[0] == accepted,
          "geometry_batch_discard_preserves_accepted");
    CHECK(cjgui_internal_renderer_destroy(token) == 0 && cjgui_internal_renderer_destroy(otherToken) == 0,
          "geometry_batch_releases_sessions");
    CHECK(cjgui_internal_renderer_set_composable_scene_geometry_batch(token, 2, GeometryCount, geometryValues) ==
          CJGUI_INTERNAL_RENDERER_INVALID_SESSION, "geometry_batch_closed_identity_refused");
    fprintf(stdout, "geometry_batch nodes=%u main_dispatches=%llu geometry_bytes=%zu failures=%d\n",
        GeometryCount, (unsigned long long)dispatches, sizeof(geometryValues), failures);
    return failures ? 1 : 0;
}}
