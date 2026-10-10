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

static BOOL SameCounts(CjguiInternalRendererWorkloadAttemptCounts a,
    CjguiInternalRendererDiagnosticWorkload b) {
    return a.nodeWriteCount == b.nodeWriteCount && a.nodeCloneCount == b.nodeCloneCount &&
        a.nodeAllocationCount == b.nodeAllocationCount &&
        a.textLayoutPreparationCount == b.textLayoutPreparationCount &&
        a.imageDecodeStartCount == b.imageDecodeStartCount;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    gCjguiMainThreadDispatchEnabled = YES;
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    CjguiInternalRendererWorkloadAttemptCounts base = {0}, current = {0};
    CHECK(cjgui_internal_renderer_workload_attempt_counts(token, 0, &base) ==
        CJGUI_INTERNAL_RENDERER_OK && base.sessionGeneration == ctx.sessionGeneration,
        "first_read_binds_actual_session_incarnation");
    CjguiPublishDiagnosticScalarSnapshot(ctx);
    uint64_t acceptedScene = ctx.composableSceneVersion, acceptedFrame = ctx.view.frameIndex;
    CJGuiInternalComposableSceneNode *accepted = ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw = accepted.node;
    raw.projectionVersion = 2;
    CjguiInternalRendererComposableGeometry geometry = accepted.geometry;
    geometry.nodeId = raw.nodeId;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 901, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "begin_private_candidate");
    CjguiInternalRendererStatus preparedStatus = cjgui_internal_renderer_prepare_composable_node(
        token, 901, 0, &raw, &geometry, "changed label", "changed body", "accepted-button",
        "binding-100", "row", "parent", "Go", "");
    fprintf(stderr, "WORKLOAD_REAL_PREPARATION status=%d\n", preparedStatus);
    CHECK(preparedStatus == CJGUI_INTERNAL_RENDERER_OK, "prepare_real_changed_node");
    CjguiInternalRendererDiagnosticWorkload fresh = {0}, published = {0};
    CjguiInternalRendererComposableDisplayProgress progress = {0};
    CjguiInternalRendererDiagnosticTiming timing = {0};
    CHECK(cjgui_internal_renderer_diagnostic_workload(token, &fresh) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_workload_attempt_counts(token, base.sessionGeneration, &current) ==
        CJGUI_INTERNAL_RENDERER_OK && SameCounts(current, fresh) &&
        current.nodeAllocationCount > base.nodeAllocationCount,
        "private_preparation_work_is_current_before_acceptance");
    CHECK(cjgui_internal_renderer_diagnostic_scalar_snapshot(token, base.sessionGeneration,
        acceptedScene, &progress, &published, &timing) == CJGUI_INTERNAL_RENDERER_OK &&
        published.nodeAllocationCount < current.nodeAllocationCount &&
        ctx.composableSceneVersion == acceptedScene && ctx.view.frameIndex == acceptedFrame,
        "same_accepted_scene_and_frame_do_not_make_cached_counts_current");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token, 901) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_workload_attempt_counts(token, base.sessionGeneration, &current) ==
        CJGUI_INTERNAL_RENDERER_OK && SameCounts(current, fresh) && ctx.composableNodes[0] == accepted,
        "cancel_keeps_real_work_and_preserves_accepted_node");

    // All five real work properties can change without any viewport/snapshot
    // publication. The native setters are the existing work-point boundary.
    ctx.composableSceneNodeUpdateCount += 7;
    ctx.composableSceneCloneCount += 11;
    ctx.composableSceneNodeAllocationCount += 13;
    ctx.composableTextLayoutPreparationCount += 17;
    ctx.composableImageDecodeStartCount += 19;
    (void)cjgui_internal_renderer_diagnostic_workload(token, &fresh);
    __block CjguiInternalRendererWorkloadAttemptCounts offMain = {0};
    __block CjguiInternalRendererStatus offMainStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    dispatch_semaphore_t finished = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        offMainStatus = cjgui_internal_renderer_workload_attempt_counts(token, base.sessionGeneration, &offMain);
        dispatch_semaphore_signal(finished);
    });
    // Main deliberately does not service its queue here: a sync-main reader
    // cannot pass this check. This is a responsiveness test, not a 16 ms claim.
    CHECK(dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0 &&
        offMainStatus == CJGUI_INTERNAL_RENDERER_OK && SameCounts(offMain, fresh),
        "off_main_reads_all_current_fields_without_main_queue_service");
    ctx.composableSceneNodeUpdateCount = UINT64_MAX;
    ctx.composableSceneCloneCount = UINT64_MAX;
    ctx.composableSceneNodeAllocationCount = UINT64_MAX;
    ctx.composableTextLayoutPreparationCount = UINT64_MAX;
    ctx.composableImageDecodeStartCount = UINT64_MAX;
    CHECK(cjgui_internal_renderer_workload_attempt_counts(token, base.sessionGeneration, &current) ==
        CJGUI_INTERNAL_RENDERER_OK && current.nodeWriteCount == UINT64_MAX &&
        current.nodeCloneCount == UINT64_MAX && current.nodeAllocationCount == UINT64_MAX &&
        current.textLayoutPreparationCount == UINT64_MAX && current.imageDecodeStartCount == UINT64_MAX,
        "saturation_is_preserved_for_every_counter");
    uint64_t oldGeneration = base.sessionGeneration;
    CHECK(cjgui_internal_renderer_destroy(token) == CJGUI_INTERNAL_RENDERER_OK,
        "normal_native_destroy_retires_counter_publication");
    CHECK(cjgui_internal_renderer_workload_attempt_counts(token, oldGeneration, &current) !=
        CJGUI_INTERNAL_RENDERER_OK && current.sessionGeneration == 0 && current.nodeWriteCount == 0,
        "closed_incarnation_returns_no_old_counts");
    CJGuiInternalSession *successor = nil; uint64_t successorToken = 0;
    CHECK(makeSession(&successor, &successorToken) && successorToken == token &&
        successor.sessionGeneration != oldGeneration, "same_slot_has_new_incarnation");
    CHECK(cjgui_internal_renderer_workload_attempt_counts(successorToken, oldGeneration, &current) ==
        CJGUI_INTERNAL_RENDERER_INVALID_SESSION && current.sessionGeneration == 0,
        "old_attempt_cannot_finish_against_reused_slot");
    CHECK(cjgui_internal_renderer_workload_attempt_counts(successorToken, 0, &current) ==
        CJGUI_INTERNAL_RENDERER_OK && current.sessionGeneration == successor.sessionGeneration &&
        current.nodeWriteCount != UINT64_MAX, "successor_first_read_binds_only_successor_counts");
    (void)cjgui_internal_renderer_destroy(successorToken);
    CHECK(cjgui_internal_renderer_workload_attempt_counts(0, 0, &current) ==
        CJGUI_INTERNAL_RENDERER_INVALID_SESSION && current.sessionGeneration == 0 &&
        cjgui_internal_renderer_workload_attempt_counts(1, 0, NULL) ==
        CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR, "invalid_calls_fail_closed");
    fprintf(stderr, "workload_attempt_counts failures=%d\n", failures);
    return failures ? 1 : 0;
}}
