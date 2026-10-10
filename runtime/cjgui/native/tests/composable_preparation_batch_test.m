#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>
#include <time.h>

@interface BatchPrepWindow : NSWindow
@property(nonatomic, strong) NSResponder *recordedResponder;
@end
@implementation BatchPrepWindow
- (NSResponder *)firstResponder { return self.recordedResponder; }
- (BOOL)makeFirstResponder:(NSResponder *)responder { self.recordedResponder = responder; return YES; }
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (CGFloat)backingScaleFactor { return 2.0; }
@end

@interface BatchPrepOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) BatchPrepWindow *recordedWindow;
@end
@implementation BatchPrepOverlay
- (NSWindow *)window { return self.recordedWindow; }
@end

static int failures;
#define CHECK(condition, label) do { \
    BOOL ok = (condition); \
    fprintf(stderr, "prepare_batch case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static BOOL makeSession(CJGuiInternalSession **outCtx, uint64_t *outToken) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return NO;
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 480, 320)
        device:device commandQueue:[device newCommandQueue]];
    BatchPrepOverlay *overlay = [[BatchPrepOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
    overlay.recordedWindow = [[BatchPrepWindow alloc] initWithContentRect:ctx.view.bounds
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
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
    old.node = raw; old.value = @"accepted"; old.semanticId = @"accepted-button";
    old.textTextureCacheKey = @"";
    [ctx.stagedComposableNodes addObject:old];
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    *outCtx = ctx; *outToken = token;
    return YES;
}

static CjguiInternalRendererStatus fillButtons(uint64_t token, uint64_t preparationId,
    uint64_t projectionVersion, uint32_t count) {
    for (uint32_t index = 0; index < count; ++index) {
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 200 + index; raw.resourceId = 1 + index;
        raw.projectionVersion = projectionVersion;
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
        raw.isInteractive = 1; raw.x = (double)index * 84; raw.y = 0;
        raw.width = 80; raw.height = 32; raw.clipWidth = 480; raw.clipHeight = 320;
        raw.textAlpha = 1;
        CjguiInternalRendererComposableGeometry geometry = {0};
        geometry.nodeId = raw.nodeId;
        CjguiInternalRendererStatus status = cjgui_internal_renderer_prepare_composable_node(
            token, preparationId, index, &raw, &geometry, "", "", "button", "", "", "", "", "");
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus fillCold(uint64_t token, uint64_t preparationId,
    uint64_t projectionVersion, NSString *body) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 700; raw.resourceId = 7; raw.projectionVersion = projectionVersion;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 680; raw.height = 8000; raw.clipWidth = 680; raw.clipHeight = 689;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = raw.nodeId;
    return cjgui_internal_renderer_prepare_composable_node(token, preparationId, 0, &raw,
        &geometry, "", body.UTF8String, "cold-text", "binding-700", "", "", "cold text", "");
}

static uint64_t nowNs(void) { return cjgui_internal_renderer_owner_clock_ns(); }

static uint32_t countPreparationUnitTraces(uint64_t firstSequence, uint64_t afterSequence,
    uint64_t preparationId, uint32_t wantedKind) {
    uint32_t count = 0;
    for (uint64_t sequence = firstSequence + 1; sequence <= afterSequence; ++sequence) {
        CjguiOwnerTraceRecord *record = &gCjguiOwnerTraceRecords[(sequence - 1) % CJGUI_OWNER_TRACE_CAPACITY];
        if (atomic_load_explicit(&record->publishedSequence, memory_order_acquire) != sequence) continue;
        if (record->request == preparationId && record->phase == CJGUI_OWNER_PHASE_NATIVE_PREPARATION_UNIT &&
            record->kind == wantedKind) count++;
    }
    return count;
}

int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    NSArray *accepted = ctx.composableNodes;
    uint64_t acceptedVersion = ctx.composableSceneVersion;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 10, 1, 2, 8) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 10, 2, 8) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_eight_real_cheap_button_nodes");
    CjguiComposablePreparation *candidate = ctx.composablePreparation;
    uint32_t ready = 0;
    uint64_t began = nowNs();
    CjguiInternalRendererStatus status = cjgui_internal_renderer_advance_composable_preparation(
        token, 10, began + 250000000ull, &ready);
    uint64_t advanced = ctx.composablePreparation.nodeCursor;
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && advanced > 1 && advanced <= 8,
        "one_budgeted_call_advances_multiple_units_red_on_single_unit_impl");
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == acceptedVersion &&
        ctx.composablePreparation == candidate,
        "private_batch_does_not_mutate_or_replace_accepted_graph");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 11, 1, 3, 1) ==
        CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR && ctx.composablePreparation == candidate,
        "different_handle_cannot_steal_batch_candidate");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token, 10) == CJGUI_INTERNAL_RENDERER_OK,
        "cancel_budgeted_candidate");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 12, 1, 4, 3) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 12, 4, 3) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_zero_deadline_candidate");
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(token, 12, 0, &ready);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ctx.composablePreparation.nodeCursor == 1 && !ready,
        "deadline_zero_preserves_single_unit_contract");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 12);

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 13, 1, 5, 3) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 13, 5, 3) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_expired_deadline_candidate");
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(token, 13, nowNs(), &ready);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ctx.composablePreparation.nodeCursor == 0 && !ready,
        "expired_deadline_advances_zero_units");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 13);

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 14, 1, 6, 3) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 14, 6, 3) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_nine_ms_deadline_candidate");
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(token, 14, nowNs() + 9000000ull, &ready);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ctx.composablePreparation.nodeCursor == 0 && !ready,
        "nine_ms_allowance_advances_zero_units");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 14);
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == acceptedVersion,
        "all_abandoned_batches_preserve_accepted_scene");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 15, 1, 7, 300) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 15, 7, 300) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_300_unit_hard_cap_candidate");
    uint64_t traceBefore = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(token, 15, nowNs() + 5000000000ull, &ready);
    uint64_t traceAfter = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    uint64_t firstCursor = ctx.composablePreparation.nodeCursor;
    uint32_t firstBegins = countPreparationUnitTraces(traceBefore, traceAfter, 15,
        CJGUI_OWNER_TRACE_PHASE_BEGIN);
    uint32_t firstEnds = countPreparationUnitTraces(traceBefore, traceAfter, 15,
        CJGUI_OWNER_TRACE_PHASE_END);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && firstCursor == 256 && !ready,
        "one_call_obeys_256_unit_hard_cap");
    CHECK(firstBegins == firstCursor && firstEnds == firstCursor,
        "phase79_unit_trace_count_matches_first_call_progress");
    traceBefore = traceAfter;
    status = cjgui_internal_renderer_advance_composable_preparation(token, 15, nowNs() + 5000000000ull, &ready);
    traceAfter = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    uint64_t finalCursor = ctx.composablePreparation.nodeCursor;
    uint32_t secondBegins = countPreparationUnitTraces(traceBefore, traceAfter, 15,
        CJGUI_OWNER_TRACE_PHASE_BEGIN);
    uint32_t secondEnds = countPreparationUnitTraces(traceBefore, traceAfter, 15,
        CJGUI_OWNER_TRACE_PHASE_END);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ready && finalCursor == 300,
        "successor_call_finishes_remaining_nodes_and_marks_ready");
    CHECK(secondBegins == secondEnds && secondBegins == 45 &&
        secondBegins == finalCursor - firstCursor + 1,
        "phase79_unit_trace_count_matches_successor_progress_and_ready_unit");
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == acceptedVersion,
        "bounded_batch_still_keeps_accepted_graph_live_until_promotion");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 15);

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 16, 1, 8, 300) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 16, 8, 300) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_deadline_yield_candidate");
    traceBefore = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(token, 16, nowNs() + 13000000ull, &ready);
    traceAfter = atomic_load_explicit(&gCjguiOwnerTraceNextSequence, memory_order_acquire);
    uint64_t deadlineCursor = ctx.composablePreparation.nodeCursor;
    uint32_t deadlineBegins = countPreparationUnitTraces(traceBefore, traceAfter, 16,
        CJGUI_OWNER_TRACE_PHASE_BEGIN);
    uint32_t deadlineEnds = countPreparationUnitTraces(traceBefore, traceAfter, 16,
        CJGUI_OWNER_TRACE_PHASE_END);
    fprintf(stderr, "prepare_batch deadline_yield_units=%llu\n", (unsigned long long)deadlineCursor);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && !ready && deadlineCursor > 0 && deadlineCursor < 256,
        "original_deadline_yields_inside_batch_before_hard_cap");
    CHECK(deadlineBegins == deadlineEnds && deadlineBegins == deadlineCursor,
        "deadline_yield_trace_matches_only_completed_units");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 16);
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == acceptedVersion,
        "deadline_yield_does_not_accept_partial_candidate");
    CjguiReleaseSession(token);

    // A closed real worker gate makes no-progress deterministic: one native
    // batch may admit the worker, but it must return instead of spinning.
    CJGuiInternalSession *cold = nil; uint64_t coldToken = 0;
    if (!makeSession(&cold, &coldToken)) return 2;
    NSMutableString *body = [NSMutableString stringWithCapacity:16384];
    for (NSUInteger i = 0; i < 16384; ++i) [body appendString:@"a"];
    CjguiTextPreparationTestCloseWorkerGate();
    CHECK(cjgui_internal_renderer_begin_composable_preparation(coldToken, 20, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK && fillCold(coldToken, 20, 2, body) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_real_cold_worker_candidate");
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(coldToken, 20, 0, &ready);
    BOOL gateReached = CjguiTextPreparationTestWaitForWorkerGate(5000);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && !ready && gateReached &&
        cold.composablePreparation.textLayoutJob.workerLive,
        "cold_worker_started_and_parked_at_real_gate");
    uint64_t waitStart = nowNs();
    status = cjgui_internal_renderer_advance_composable_preparation(coldToken, 20,
        waitStart + 250000000ull, &ready);
    uint64_t waitMs = (nowNs() - waitStart) / 1000000ull;
    fprintf(stderr, "prepare_batch worker_wait_call_ms=%llu\n", (unsigned long long)waitMs);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && !ready &&
        cold.composablePreparation.nodeCursor == 0 && waitMs < 50,
        "live_worker_no_progress_yields_promptly");
    CjguiTextPreparationTestOpenWorkerGate();
    CHECK(CjguiTextPreparationTestWaitForFinished(15000), "cold_worker_finishes_after_gate_release");
    for (NSUInteger attempt = 0; attempt < 256 && !ready; ++attempt) {
        status = cjgui_internal_renderer_advance_composable_preparation(coldToken, 20,
            nowNs() + 250000000ull, &ready);
        if (status != CJGUI_INTERNAL_RENDERER_OK) break;
    }
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ready &&
        cold.composablePreparation.nodeCursor == 1,
        "completed_worker_is_adopted_then_candidate_finishes");
    (void)cjgui_internal_renderer_cancel_composable_preparation(coldToken, 20);
    CjguiReleaseSession(coldToken);

    // Reuse the actual worker publication gate to prove a scene/source change
    // while a built private graph waits cannot be adopted or promoted.
    CJGuiInternalSession *stale = nil; uint64_t staleToken = 0;
    if (!makeSession(&stale, &staleToken)) return 2;
    NSMutableString *staleBody = [NSMutableString stringWithCapacity:1200];
    for (NSUInteger i = 0; i < 128; ++i) [staleBody appendString:@"source change line\n"];
    CHECK(cjgui_internal_renderer_begin_composable_preparation(staleToken, 30, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK && fillCold(staleToken, 30, 2, staleBody) == CJGUI_INTERNAL_RENDERER_OK,
        "begin_source_stale_candidate");
    CjguiTextPreparationTestClosePublicationGate();
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(staleToken, 30, 0, &ready);
    BOOL publicationReached = CjguiTextPreparationTestWaitForPublicationGate(15000);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && publicationReached &&
        gCjguiTextPreparationTestWeakSourceLayout != nil,
        "worker_built_private_source_graph_before_publish");
    stale.composableSceneVersion = 2;
    ready = 0;
    status = cjgui_internal_renderer_advance_composable_preparation(staleToken, 30, nowNs() + 250000000ull, &ready);
    CHECK(status == CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ready &&
        stale.composablePreparation.nodeCursor == 0,
        "changed_source_version_rejects_private_worker_graph");
    stale.composableSceneVersion = 1;
    (void)cjgui_internal_renderer_cancel_composable_preparation(staleToken, 30);
    CjguiTextPreparationTestOpenPublicationGate();
    CHECK(CjguiTextPreparationTestWaitForFinished(15000), "stale_worker_retires_after_publication_gate");
    CjguiRetireComposablePreparationUnit(stale);
    CjguiReleaseSession(staleToken);

    fprintf(stderr, "prepare_batch summary failures=%d\n", failures);
    return failures ? 1 : 0;
} }
