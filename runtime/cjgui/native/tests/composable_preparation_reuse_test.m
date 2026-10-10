#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

@interface ReusePrepWindow : NSWindow
@property(nonatomic, strong) NSResponder *recordedResponder;
@property(nonatomic, assign) CGFloat testScale;
@end
@implementation ReusePrepWindow
- (NSResponder *)firstResponder { return self.recordedResponder; }
- (BOOL)makeFirstResponder:(NSResponder *)responder { self.recordedResponder = responder; return YES; }
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (CGFloat)backingScaleFactor { return self.testScale; }
@end

@interface ReusePrepOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) ReusePrepWindow *recordedWindow;
@end
@implementation ReusePrepOverlay
- (NSWindow *)window { return self.recordedWindow; }
@end

static int failures;
#define CHECK(condition, label) do { \
    BOOL ok = (condition); \
    fprintf(stderr, "prepare_reuse case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static BOOL makeSession(CJGuiInternalSession **outCtx, uint64_t *outToken) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return NO;
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 480, 320)
        device:device commandQueue:[device newCommandQueue]];
    ctx.view.testBackingScaleOverride = 2.0;
    ReusePrepOverlay *overlay = [[ReusePrepOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
    overlay.recordedWindow = [[ReusePrepWindow alloc] initWithContentRect:ctx.view.bounds
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    overlay.recordedWindow.testScale = 2.0;
    overlay.recordedWindow.releasedWhenClosed = NO;
    overlay.recordedWindow.contentView = overlay;
    ctx.window = overlay.recordedWindow;
    ctx.composableSceneOverlay = overlay;
    ctx.composableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    ctx.stagedComposableSceneVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token) return NO;
    ctx.view.sessionToken = token;

    CJGuiInternalComposableSceneNode *old = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 100; raw.resourceId = 1; raw.projectionVersion = 1;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    raw.isInteractive = 1; raw.width = 80; raw.height = 32;
    raw.clipWidth = 80; raw.clipHeight = 32; raw.textAlpha = 1;
    raw.inputScope = 7; raw.acceptedBindingEpoch = 9;
    old.node = raw; old.value = @"accepted"; old.label = @"go";
    old.semanticId = @"accepted-button"; old.semanticBindingKey = @"binding-100";
    old.semanticLabel = @"Go"; old.semanticRowKey = @"row";
    old.semanticParentRowKey = @"parent"; old.styleRunsSignature = @"";
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = raw.nodeId;
    old.geometry = geometry;
    old.textTextureCacheKey = @"";
    [ctx.stagedComposableNodes addObject:old];
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    *outCtx = ctx; *outToken = token;
    return YES;
}

static void copyAcceptedStrings(CJGuiInternalComposableSceneNode *old, const CjguiInternalRendererComposableNode *raw,
    uint64_t token, uint64_t preparationId, CjguiInternalRendererComposableGeometry geometry) {
    CjguiInternalRendererComposableNode candidate = *raw;
    candidate.projectionVersion = 2;
    (void)cjgui_internal_renderer_prepare_composable_node(token, preparationId, 0, &candidate, &geometry,
        old.label.UTF8String, old.value.UTF8String, old.semanticId.UTF8String,
        old.semanticBindingKey.UTF8String, old.semanticRowKey.UTF8String,
        old.semanticParentRowKey.UTF8String, old.semanticLabel.UTF8String,
        old.styleRunsSignature.UTF8String);
}

static CjguiInternalRendererStatus tryReuseOne(uint64_t token, uint64_t preparationId,
    const CjguiInternalRendererComposableNode *raw, CjguiInternalRendererComposableGeometry geometry,
    uint32_t *outReused) {
    return cjgui_internal_renderer_reuse_composable_node_batch(token, preparationId, 0, 1,
        raw, &geometry, 0, outReused);
}

static uint32_t countReuseScalars(uint64_t first, uint64_t after, uint64_t preparationId,
    uint32_t wantedPhase, uint64_t wantedValue) {
    uint32_t count = 0;
    for (uint64_t sequence = first + 1; sequence <= after; ++sequence) {
        CjguiOwnerTraceRecord *record = &gCjguiOwnerTraceRecords[(sequence - 1) % CJGUI_OWNER_TRACE_CAPACITY];
        if (atomic_load_explicit(&record->publishedSequence, memory_order_acquire) != sequence) continue;
        if (record->kind == CJGUI_OWNER_TRACE_OBSERVATION_SCALAR && record->request == preparationId &&
            record->phase == wantedPhase && record->span == wantedValue) count++;
    }
    return count;
}

static uint32_t countCriticalReuseScalars(uint64_t firstOrdinal, uint64_t afterOrdinal,
    uint64_t preparationId, uint32_t wantedPhase, uint64_t wantedValue) {
    uint32_t count = 0;
    uint64_t first = firstOrdinal > CJGUI_OWNER_TRACE_CRITICAL_CAPACITY
        ? firstOrdinal - CJGUI_OWNER_TRACE_CRITICAL_CAPACITY : 0;
    if (first < firstOrdinal) first = firstOrdinal;
    for (uint64_t ordinal = first; ordinal < afterOrdinal; ++ordinal) {
        CjguiOwnerTraceRecord *record = &gCjguiOwnerTraceCriticalRecords[
            ordinal % CJGUI_OWNER_TRACE_CRITICAL_CAPACITY];
        if (atomic_load_explicit(&record->publishedSequence, memory_order_acquire) != ordinal + 1) continue;
        if (record->kind == CJGUI_OWNER_TRACE_OBSERVATION_SCALAR && record->request == preparationId &&
            record->phase == wantedPhase && record->span == wantedValue) count++;
    }
    return count;
}

static BOOL runPODMiss(CJGuiInternalSession *ctx, uint64_t token, uint64_t preparationId, const char *label,
    uint32_t mutation) {
    CJGuiInternalComposableSceneNode *accepted = ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw = accepted.node;
    raw.projectionVersion = 2;
    CjguiInternalRendererComposableGeometry geometry = accepted.geometry;
    geometry.nodeId = raw.nodeId; geometry.translateY = 24.0;
    switch (mutation) {
        case 0: raw.fontSize += 1.0; break; // style/POD
        case 1: raw.semanticRole += 1; break; // semantic identity
        case 2: raw.inputScope += 1; break; // native scope
        case 3: raw.acceptedBindingEpoch += 1; break; // binding epoch
        case 4: raw.clipWidth += 1; break; // clip/POD
        case 5: raw.effectGroupOpacity -= 0.1; break; // effect declaration
        case 6: raw.resourceId += 1; break; // resource identity
        case 7: raw.preservesActiveLocalText = 1; break; // focus/input state
        default: return NO;
    }
    if (cjgui_internal_renderer_begin_composable_preparation(token, preparationId, 1, 2, 1) !=
        CJGUI_INTERNAL_RENDERER_OK) return NO;
    uint32_t reused = UINT32_MAX;
    CjguiInternalRendererStatus status = tryReuseOne(token, preparationId, &raw, geometry, &reused);
    BOOL missed = status == CJGUI_INTERNAL_RENDERER_OK && reused == 0 &&
        ctx.composablePreparation.filled.count == 0 &&
        ctx.composablePreparation.nodes[0].geometry.translateY == accepted.geometry.translateY;
    fprintf(stderr, "prepare_reuse negative=%s status=%d reused=%u result=%s\n",
        label, status, reused, missed ? "PASS" : "FAIL");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, preparationId);
    return missed;
}

int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    CJGuiInternalComposableSceneNode *accepted = ctx.composableNodes[0];
    CjguiInternalRendererComposableNode acceptedRaw = accepted.node;
    CjguiInternalRendererComposableGeometry newGeometry = accepted.geometry;
    newGeometry.nodeId = accepted.node.nodeId;
    newGeometry.translateY = 24.0;

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 70, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "begin_invalid_packet_candidate");
    CjguiComposablePreparation *invalidCandidate = ctx.composablePreparation;
    CJGuiInternalComposableSceneNode *invalidNode = invalidCandidate.nodes[0];
    CjguiInternalRendererComposableNode invalidBefore = invalidNode.node;
    CjguiInternalRendererComposableGeometry geometryBefore = invalidNode.geometry;
    CjguiInternalRendererComposableNode validRaw = acceptedRaw;
    validRaw.projectionVersion = 2;
    CjguiInternalRendererStatus nullRaw = cjgui_internal_renderer_prepare_composable_node(
        token, 70, 0, NULL, &newGeometry, "", "", "", "", "", "", "", "");
    CjguiInternalRendererStatus nullGeometry = cjgui_internal_renderer_prepare_composable_node(
        token, 70, 0, &validRaw, NULL, "", "", "", "", "", "", "", "");
    CHECK(nullRaw == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
        nullGeometry == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
        "public_single_node_null_packet_returns_error");
    CjguiInternalRendererComposableNode invalidAfter = invalidNode.node;
    CjguiInternalRendererComposableGeometry geometryAfter = invalidNode.geometry;
    CHECK(ctx.composablePreparation == invalidCandidate && invalidCandidate.filled.count == 0 &&
        invalidCandidate.nodes[0] == invalidNode &&
        memcmp(&invalidBefore, &invalidAfter, sizeof(invalidBefore)) == 0 &&
        memcmp(&geometryBefore, &geometryAfter, sizeof(geometryBefore)) == 0 &&
        invalidCandidate.ownedPacketBytes == 0 &&
        ctx.composableNodes[0] == accepted && ctx.composableSceneVersion == 1,
        "null_packet_preserves_candidate_and_accepted");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 70);

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 51, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "begin_scroll_only_candidate_from_accepted_cow_base");
    acceptedRaw.projectionVersion = 2;
    uint32_t reused = 0;
    CjguiInternalRendererStatus reuseStatus = tryReuseOne(token, 51, &acceptedRaw, newGeometry, &reused);
    CjguiComposablePreparation *candidate = ctx.composablePreparation;
    fprintf(stderr, "prepare_reuse scroll status=%d copied_string_bytes=%llu reused=%llu geometry_writes=%llu geometry_y=%.3f filled=%lu\n",
        reuseStatus,
        (unsigned long long)candidate.ownedPacketBytes,
        (unsigned long long)candidate.declarationReusedCount,
        (unsigned long long)candidate.geometryWrittenCount,
        candidate.nodes[0].geometry.translateY, (unsigned long)candidate.filled.count);
    CHECK(reuseStatus == CJGUI_INTERNAL_RENDERER_OK && reused == 1 && candidate.declarationReusedCount == 1,
        "scroll_only_complete_POD_reuses_accepted_declaration");
    CHECK(candidate.nodes[0].geometry.translateY == 24.0 && candidate.filled.count == 1,
        "scroll_candidate_keeps_fresh_geometry_on_private_clone");
    CHECK(candidate.ownedPacketBytes == 0,
        "scroll_only_declaration_does_not_copy_eight_accepted_strings");
    CHECK(candidate.declarationCopiedCount == 0 && candidate.geometryWrittenCount == 1,
        "scroll_reuse_and_geometry_counters_are_separate");
    CHECK(ctx.composableNodes[0] == accepted && accepted.geometry.translateY == 0.0,
        "private_scroll_geometry_does_not_mutate_accepted_node");
    uint64_t traceBefore = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 51);
    uint64_t traceAfter = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    CHECK(countReuseScalars(traceBefore, traceAfter, 51,
        CJGUI_OWNER_PHASE_PREPARATION_DECLARATIONS_COPIED, 0) == 1 &&
        countReuseScalars(traceBefore, traceAfter, 51,
        CJGUI_OWNER_PHASE_PREPARATION_DECLARATIONS_REUSED, 1) == 1 &&
        countReuseScalars(traceBefore, traceAfter, 51,
        CJGUI_OWNER_PHASE_PREPARATION_GEOMETRY_WRITTEN, 1) == 1,
        "bounded_ring_retains_one_per_preparation_copy_reuse_geometry_summary");
    CHECK(ctx.composableNodes[0] == accepted && ctx.composableSceneVersion == 1,
        "cancelled_scroll_candidate_preserves_accepted_scene");

    uint64_t activityBefore = atomic_load_explicit(&gCjguiOwnerTraceActivityNext, memory_order_acquire);
    uint64_t captureBefore = atomic_load_explicit(&gCjguiOwnerTraceActivityCaptureCount, memory_order_acquire);
    uint64_t criticalBefore = atomic_load_explicit(&gCjguiOwnerTraceCriticalNext, memory_order_acquire);
    uint64_t summaryTurn = 9901;
    uint64_t summaryRequest = 9902;
    (void)cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_BOUNDARY, token, summaryTurn,
        0, 0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0);
    (void)cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, token, summaryTurn,
        summaryRequest, 0, 1, CJGUI_OWNER_PHASE_PREPARATION_DECLARATIONS_COPIED, 4);
    (void)cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, token, summaryTurn,
        summaryRequest, 0, 1, CJGUI_OWNER_PHASE_PREPARATION_DECLARATIONS_REUSED, 5);
    (void)cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, token, summaryTurn,
        summaryRequest, 0, 1, CJGUI_OWNER_PHASE_PREPARATION_GEOMETRY_WRITTEN, 9);
    BOOL summaryMarkedAsActivity = atomic_load_explicit(
        &gCjguiOwnerTraceActiveHasCriticalObservation, memory_order_acquire);
    (void)cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_BOUNDARY, token, summaryTurn,
        0, 0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_END, 0);
    uint64_t activityAfter = atomic_load_explicit(&gCjguiOwnerTraceActivityNext, memory_order_acquire);
    uint64_t captureAfter = atomic_load_explicit(&gCjguiOwnerTraceActivityCaptureCount, memory_order_acquire);
    uint64_t criticalAfter = atomic_load_explicit(&gCjguiOwnerTraceCriticalNext, memory_order_acquire);
    CHECK(!summaryMarkedAsActivity && activityAfter == activityBefore && captureAfter == captureBefore,
        "reuse_summaries_do_not_trigger_full_turn_activity_capture");
    CHECK(criticalAfter == criticalBefore + 5 &&
        countCriticalReuseScalars(criticalBefore, criticalAfter, summaryRequest,
            CJGUI_OWNER_PHASE_PREPARATION_DECLARATIONS_COPIED, 4) == 1 &&
        countCriticalReuseScalars(criticalBefore, criticalAfter, summaryRequest,
            CJGUI_OWNER_PHASE_PREPARATION_DECLARATIONS_REUSED, 5) == 1 &&
        countCriticalReuseScalars(criticalBefore, criticalAfter, summaryRequest,
            CJGUI_OWNER_PHASE_PREPARATION_GEOMETRY_WRITTEN, 9) == 1,
        "reuse_summaries_are_directly_retained_in_bounded_critical_ring");

    CHECK(runPODMiss(ctx, token, 52, "style", 0), "style_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 53, "semantic", 1), "semantic_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 54, "scope", 2), "scope_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 55, "binding", 3), "binding_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 56, "clip", 4), "clip_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 57, "effect", 5), "effect_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 58, "resource", 6), "resource_difference_refuses_reuse");
    CHECK(runPODMiss(ctx, token, 59, "focus_state", 7), "focus_difference_refuses_reuse");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 60, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "begin_scale_stale_candidate");
    ReusePrepOverlay *overlay = (ReusePrepOverlay *)ctx.composableSceneOverlay;
    ctx.view.testBackingScaleOverride = 3.0;
    reused = 99;
    CjguiInternalRendererStatus scaleStatus = tryReuseOne(token, 60, &acceptedRaw, newGeometry, &reused);
    CHECK(scaleStatus == CJGUI_INTERNAL_RENDERER_SCENE_STALE && reused == 0 &&
        ctx.composablePreparation.filled.count == 0,
        "backing_scale_change_rejects_reuse_before_geometry_mutation");
    ctx.view.testBackingScaleOverride = 2.0;
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 60);

    overlay.inputProxy.string = @"abc";
    [overlay.inputProxy setSelectedRange:NSMakeRange(0, 0)];
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 61, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "begin_selection_stale_candidate");
    // Begin captured the zero selection; change it after the immutable basis.
    [overlay.inputProxy setSelectedRange:NSMakeRange(2, 0)];
    reused = 99;
    CjguiInternalRendererStatus selectionStatus = tryReuseOne(token, 61, &acceptedRaw, newGeometry, &reused);
    CHECK(selectionStatus == CJGUI_INTERNAL_RENDERER_SCENE_STALE && reused == 0 &&
        ctx.composablePreparation.filled.count == 0,
        "selection_change_rejects_reuse_before_geometry_mutation");
    [overlay.inputProxy setSelectedRange:NSMakeRange(0, 0)];
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 61);

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 62, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "begin_full_copy_negative_control");
    CjguiInternalRendererComposableNode changedFullRaw = acceptedRaw;
    changedFullRaw.fontSize += 1.0;
    copyAcceptedStrings(accepted, &changedFullRaw, token, 62, newGeometry);
    CHECK(ctx.composablePreparation.ownedPacketBytes > 0 &&
        ctx.composablePreparation.declarationCopiedCount == 1 &&
        ctx.composablePreparation.declarationReusedCount == 0,
        "changed_slot_keeps_original_full_string_copy_path");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 62);
    CjguiReleaseSession(token);
    fprintf(stderr, "prepare_reuse summary failures=%d\n", failures);
    return failures ? 1 : 0;
} }
