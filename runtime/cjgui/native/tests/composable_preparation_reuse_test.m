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

// A declaration-only selection background must not claim that the actual
// focused TEXT glyph source changed while its private scene is being prepared.
static void testSelectionBackgroundDoesNotInvalidateFrozenGlyphSource(void) {
    CJGuiInternalSession *ctx=nil; uint64_t token=0;
    CHECK(makeSession(&ctx,&token), "selection_runs_source_fixture");
    if (!ctx) return;
    CJGuiInternalComposableSceneNode *node=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=node.node;
    ctx.composableTextStyleRunsRaw[@(node.node.nodeId)]=@"";
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.fontSize=14; raw.width=400; raw.height=120; raw.clipWidth=400; raw.clipHeight=120;
    node.node=raw; node.value=@"Hi 中🙂"; node.styleRunsSignature=@"";
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    o.activeNodeId=raw.nodeId; o.activeNodeResourceId=raw.resourceId; o.activeNodeKind=raw.nodeKind;
    o.inputProxy.string=node.value; o.inputProxy.selectedRange=NSMakeRange(0,1);
    NSAttributedString *original=[o.inputProxy.textStorage copy];
    uint64_t generation=o.activeTextAttributedGeneration;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,80,1,2,1)==CJGUI_INTERNAL_RENDERER_OK,
        "begin_real_preparation_before_background_declaration");
    CjguiComposablePreparation *p=ctx.composablePreparation;
    const char *selection="0:1:0:0:0:0:0:0:0:1:0:0:0:1:2";
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token,raw.nodeId,selection)==CJGUI_INTERNAL_RENDERER_OK,
        "selection_background_original_declaration_admitted");
    CHECK([o.inputProxy.textStorage isEqualToAttributedString:original] &&
        [ctx.composableTextStyleRunsRaw[@(raw.nodeId)] isEqualToString:@(selection)],
        "selection_background_keeps_actual_storage_and_full_paint_declaration");
    CHECK(o.activeTextAttributedGeneration==generation && CjguiPreparationNativeSourceMatches(ctx,p),
        "paint_only_selection_preserves_frozen_glyph_source_gate");
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token,raw.nodeId,"")==CJGUI_INTERNAL_RENDERER_OK &&
        o.activeTextAttributedGeneration==generation && CjguiPreparationNativeSourceMatches(ctx,p),
        "selection_background_clear_preserves_source_and_gate");
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token,raw.nodeId,
        "0:1:14:400:0:1:0:0:1:0:0:0:0:0")==CJGUI_INTERNAL_RENDERER_OK &&
        o.activeTextAttributedGeneration>generation && !CjguiPreparationNativeSourceMatches(ctx,p),
        "real_glyph_style_change_still_invalidates_original_source");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,80);
    CjguiReleaseSession(token);
}

static BOOL frameWaitReady(uint64_t token, uint64_t request) {
    uint64_t end = cjgui_internal_renderer_owner_clock_ns() + UINT64_C(2000000000);
    uint32_t ready = 0;
    while (!ready && cjgui_internal_renderer_owner_clock_ns() < end) {
        CjguiInternalRendererStatus status = cjgui_internal_renderer_advance_composable_preparation(token, request, 0, &ready);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return NO;
        if (!ready) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.005, true);
    }
    return ready != 0;
}

static BOOL framePromote(CJGuiInternalSession *ctx, uint64_t token, uint64_t request) {
    CjguiComposablePreparation *p = ctx.composablePreparation;
    if (!p || p.preparationId != request || !p.frameResourceProof) return NO;
    if (cjgui_internal_renderer_configure_composable_scene(token, p.projectionVersion, (uint32_t)p.nodes.count) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    for (NSNumber *key in p.runs)
        if (cjgui_internal_renderer_set_composable_text_runs(token, key.longLongValue, p.runs[key].UTF8String) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    if (cjgui_internal_renderer_promote_composable_preparation(token, request) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    return CjguiCommitComposableSceneOnMain(token) == CJGUI_INTERNAL_RENDERER_OK;
}

// Normal panel RED: a reused non-text slot retained the former text slot's
// paint signature (node314, 94 B), while its accepted declaration was empty.
// Paint-cache metadata must never become the next candidate's declaration.
static void testReuseFreezesDeclaredRunsInsteadOfCachedPaintSignature(void) {
    CJGuiInternalSession *ctx=nil; uint64_t token=0;
    CHECK(makeSession(&ctx,&token), "declared_runs_fixture");
    if (!ctx) return;
    CJGuiInternalComposableSceneNode *accepted=ctx.composableNodes[0];
    accepted.styleRunsSignature=@"0:1:14:400:0:1:0:0:1:0:0:0:0:0";
    ctx.composableTextStyleRunsRaw[@100]=@"";
    CjguiInternalRendererComposableNode raw=accepted.node; raw.projectionVersion=2;
    CjguiInternalRendererComposableGeometry geometry=accepted.geometry; geometry.nodeId=raw.nodeId;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,190,1,2,1)==0,
        "declared_runs_preparation_started");
    uint32_t reused=0;
    CjguiInternalRendererStatus reuseStatus=tryReuseOne(token,190,&raw,geometry,&reused);
    CHECK(reuseStatus==0 && reused==1,
        "declared_runs_equal_declaration_reuses_slot");
    CHECK([ctx.composablePreparation.runs[@100] isEqualToString:@""],
        "declared_runs_cache_signature_is_not_transport_authority");
    CHECK(frameWaitReady(token,190), "declared_runs_real_resources_ready");
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,1)==0,
        "declared_runs_actual_scene_staged");
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token,100,
        "0:1:16:400:0:0:1:0:1:0:0:0:0:0")==0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,190)==CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
        "declared_runs_real_mismatch_still_refused");
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token,100,"")==0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,190)==0 &&
        CjguiCommitComposableSceneOnMain(token)==0,
        "declared_runs_independent_empty_declaration_promotes");
    CjguiReleaseSession(token);
}

static BOOL frameEncodeAndRead(CJGuiInternalSession *ctx, uint32_t *outPixel) {
    CJGuiInternalMetalView *view = ctx.view;
    BOOL multi = CjguiComposableSceneNeedsMultisampling(view.composableNodes);
    view.composableUsesMultisampling = multi; // Same real derivation as normal frame.
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:960 height:640 mipmapped:NO];
    descriptor.usage = MTLTextureUsageRenderTarget;
    id<MTLTexture> resolved = [view.device newTextureWithDescriptor:descriptor];
    if (!resolved) return NO;
    id<MTLTexture> msaa = nil;
    if (multi) {
        descriptor.textureType = MTLTextureType2DMultisample; descriptor.sampleCount = 4;
        descriptor.storageMode = MTLStorageModePrivate;
        msaa = [view.device newTextureWithDescriptor:descriptor]; if (!msaa) return NO;
    }
    id<MTLCommandBuffer> command = [view.commandQueue commandBuffer];
    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = msaa ?: resolved;
    pass.colorAttachments[0].resolveTexture = msaa ? resolved : nil;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = msaa ? MTLStoreActionMultisampleResolve : MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
    if (!encoder) return NO;
    uint64_t buildsBefore = view.testComposablePipelineBuildCount;
    BOOL encoded = CjguiEncodeComposableNodes(view, encoder, CGSizeMake(960,640));
    [encoder endEncoding]; if (!encoded) return NO;
    [command commit]; [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted || buildsBefore != view.testComposablePipelineBuildCount) return NO;
    [resolved getBytes:outPixel bytesPerRow:4 fromRegion:MTLRegionMake2D(80,32,1,1) mipmapLevel:0];
    return (*outPixel & 0x00ffffffu) != 0;
}

static void testPreparedSubmissionWaitsForActualPipelines(void) {
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    CHECK(makeSession(&ctx, &token), "frame_ready_real_device_session");
    if (!ctx) return;
    CHECK(ctx.view.composablePipeline == nil && ctx.view.composableImagePipeline == nil,
        "frame_ready_fixture_actual_pipelines_missing");
    CJGuiInternalComposableSceneNode *accepted = ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw = accepted.node;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 71, 1, 2, 1) ==
        CJGUI_INTERNAL_RENDERER_OK, "frame_ready_begin_real_native_preparation");
    CjguiInternalRendererComposableGeometry geometry = accepted.geometry;
    geometry.nodeId = accepted.node.nodeId;
    raw.textAlpha = 0.0; // Isolate real scene-pipeline readiness from TextKit.
    copyAcceptedStrings(accepted, &raw, token, 71, geometry);
    CHECK(ctx.composablePreparation.filled.count == 1, "frame_ready_actual_node_declaration_accepted");
    uint32_t ready = 0; CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    for (NSUInteger i = 0; i < 16 && !ready && status == CJGUI_INTERNAL_RENDERER_OK; i++)
        status = cjgui_internal_renderer_advance_composable_preparation(token, 71, 0, &ready);
    fprintf(stderr, "frame_ready_actual status=%d ready=%u layout=%d cursor=%lu phase=%lu filled=%lu count=%lu\n", status, ready, ctx.composablePreparation.ready, (unsigned long)ctx.composablePreparation.nodeCursor, (unsigned long)ctx.composablePreparation.phase, (unsigned long)ctx.composablePreparation.filled.count, (unsigned long)ctx.composablePreparation.nodes.count);
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ctx.composablePreparation.ready,
        "frame_ready_actual_layout_completed_independently");
    CHECK(ready == 0, "frame_ready_missing_gpu_resources_never_submission_ready");
    CHECK(ctx.composableSceneVersion == 1 && ctx.composableNodes[0] == accepted,
        "frame_ready_pending_keeps_actual_A");
    CHECK(frameWaitReady(token, 71), "frame_ready_actual_async_metal_completes_original_p");
    CjguiPreparedFrameResourceProof *firstProof = ctx.composablePreparation.frameResourceProof;
    CHECK(firstProof && firstProof.sampleCount == 1 && firstProof.scene.device == ctx.view.device,
        "frame_ready_success_has_real_immutable_resource_key");
    CjguiPreparedFramePipelines *firstSet = ctx.composablePreparation.frameResourcePipelines;
    uint32_t started = firstSet.startedRoles;
    uint64_t readyAt = firstSet.readyNs;
    uint32_t again = 0;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token, 71, 0, &again) == CJGUI_INTERNAL_RENDERER_OK && again == 1 &&
        ctx.composablePreparation.frameResourceProof == firstProof && firstSet.startedRoles == started && firstSet.readyNs == readyAt,
        "frame_ready_same_p_holds_actual_success_no_recompile");
    raw.fillRed=0.2; raw.fillGreen=0.4; raw.fillBlue=0.6; raw.fillAlpha=1.0;
    // Use a new genuinely declared candidate for the visible colour; old71 is
    // cancelled, never rewritten after its frozen layout.
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,71);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,72,1,2,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_new_real_colour_candidate");
    copyAcceptedStrings(accepted,&raw,token,72,geometry);
    CHECK(frameWaitReady(token,72) && framePromote(ctx,token,72), "frame_ready_real_resources_promote_colour");
    uint32_t pixel=0;
    CHECK(frameEncodeAndRead(ctx,&pixel), "frame_ready_actual_colour_gpu_no_sync_shader_compile");

    // Same view, no resize: required vector causes4x independently of A's flag.
    uint64_t resize = ctx.resizeVersion;
    CjguiInternalRendererComposableNode vectorRaw = raw;
    vectorRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VECTOR_GRAPHIC; vectorRaw.projectionVersion=3;
    const char *vectorValue="cg1;3;120;80;3;2;3;0.92;0.12;0.18;0.82;0.10;0.68;0.94;1;60;40;34;24;1;60;40";
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,73,2,3,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_vector_same_view_candidate");
    CHECK(cjgui_internal_renderer_prepare_composable_node(token,73,0,&vectorRaw,&geometry,"",vectorValue,"vector","","","","vector","")==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_real_vector_packet_accepted");
    CHECK(frameWaitReady(token,73) && ctx.composablePreparation.frameResourceProof.sampleCount==4 &&
        (ctx.composablePreparation.frameResourceProof.roles & CjguiFramePipelineVector) && ctx.resizeVersion==resize,
        "frame_ready_vector4x_key_from_B_not_old_view_no_resize");
    CHECK(framePromote(ctx,token,73), "frame_ready_vector_real_completion_promotes");
    CHECK(frameEncodeAndRead(ctx,&pixel), "frame_ready_vector_gpu_pixel_no_sync_shader_compile");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,74,3,4,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_nonvector_successor_same_view");
    CjguiInternalRendererComposableNode returnRaw=raw; returnRaw.projectionVersion=4;
    CHECK(cjgui_internal_renderer_prepare_composable_node(token,74,0,&returnRaw,&geometry,"go","accepted","button","binding-100","row","parent","Go","")==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_nonvector_successor_real_packet");
    CHECK(frameWaitReady(token,74) && ctx.composablePreparation.frameResourceProof.sampleCount==1 && ctx.resizeVersion==resize,
        "frame_ready_nonvector_returns1x_without_resize");
    CHECK(framePromote(ctx,token,74) && frameEncodeAndRead(ctx,&pixel),
        "frame_ready_nonvector_successor_gpu_no_sync_shader_compile");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,75,4,5,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_format_drift_candidate");
    returnRaw.projectionVersion=5;
    CHECK(cjgui_internal_renderer_prepare_composable_node(token,75,0,&returnRaw,&geometry,"go","accepted","button","binding-100","row","parent","Go","")==CJGUI_INTERNAL_RENDERER_OK && frameWaitReady(token,75),
        "frame_ready_format_drift_original_real_ready");
    ctx.view.metalLayer.pixelFormat=MTLPixelFormatBGRA8Unorm_sRGB;
    uint32_t driftReady=99;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,75,0,&driftReady)==CJGUI_INTERNAL_RENDERER_SCENE_STALE && driftReady==0 && ctx.composableSceneVersion==4,
        "frame_ready_changed_actual_format_rejects_old_fact_keeps_A");
    ctx.view.metalLayer.pixelFormat=MTLPixelFormatBGRA8Unorm;
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,75);

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,76,4,5,1)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_prepare_composable_node(token,76,0,&returnRaw,&geometry,"go","accepted","button","binding-100","row","parent","Go","")==CJGUI_INTERNAL_RENDERER_OK && frameWaitReady(token,76),
        "frame_ready_real_before_dpi_change");
    ctx.view.testBackingScaleOverride=3.0;
    uint32_t dpiReady=99;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,76,0,&dpiReady)==CJGUI_INTERNAL_RENDERER_SCENE_STALE && dpiReady==0 && ctx.composableSceneVersion==4,
        "frame_ready_dpi_old_geometry_refused_not_bypassed_by_pipelines");
    ctx.view.testBackingScaleOverride=2.0;
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,76);

    // The4x image role is still cold: real GPU compilation remains in flight
    // when this original native candidate is cancelled and its slot released.
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,77,4,5,2)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_pending_late_cancel_candidate");
    vectorRaw.projectionVersion=5;
    CHECK(cjgui_internal_renderer_prepare_composable_node(token,77,0,&vectorRaw,&geometry,"",vectorValue,"vector","","","","vector","")==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_late_vector_node");
    CjguiInternalRendererComposableNode secondRaw=returnRaw;secondRaw.nodeId=101;secondRaw.projectionVersion=5;
    CjguiInternalRendererComposableGeometry secondGeometry=geometry;secondGeometry.nodeId=101;
    CHECK(cjgui_internal_renderer_prepare_composable_node(token,77,1,&secondRaw,&secondGeometry,"go","accepted","second","","","","second","")==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_late_image_role_node");
    uint32_t lateReady=99;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,77,0,&lateReady)==CJGUI_INTERNAL_RENDERER_OK && lateReady==0,
        "frame_ready_actual_late_image_compilation_pending");
    CjguiComposablePreparation *cancelled=ctx.composablePreparation;
    CjguiPreparedFramePipelines *lateSet=cancelled.frameResourcePipelines;
    uint64_t oldGeneration=ctx.sessionGeneration;
    CHECK((lateSet.startedRoles & CjguiFramePipelineImage)!=0 && (lateSet.completedRoles & CjguiFramePipelineImage)==0,
        "frame_ready_late_fixture_real_inflight_role");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,77)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.composablePreparation==nil && cancelled.frameResourceProof==nil && cancelled.frameResourcePipelines==nil,
        "frame_ready_cancel_releases_candidate_qualification");
    CjguiReleaseSession(token);
    CJGuiInternalSession *fresh=nil;uint64_t freshToken=0;
    CHECK(makeSession(&fresh,&freshToken) && freshToken==token && fresh.sessionGeneration!=oldGeneration,
        "frame_ready_same_slot_real_new_generation");
    CJGuiInternalComposableSceneNode *freshA=fresh.composableNodes[0];
    CjguiInternalRendererComposableNode freshRaw=freshA.node;freshRaw.textAlpha=0;
    CjguiInternalRendererComposableGeometry freshGeometry=freshA.geometry;freshGeometry.nodeId=freshA.node.nodeId;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(freshToken,77,1,2,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_same_request_new_session_candidate");
    copyAcceptedStrings(freshA,&freshRaw,freshToken,77,freshGeometry);
    CjguiComposablePreparation *freshP=fresh.composablePreparation;
    uint64_t lateEnd=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(2000000000);
    while ((lateSet.completedRoles & CjguiFramePipelineImage)==0 && cjgui_internal_renderer_owner_clock_ns()<lateEnd)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.005,true);
    CHECK((lateSet.completedRoles & CjguiFramePipelineImage)!=0 && !lateSet.failedRoles &&
        fresh.composablePreparation==freshP && !freshP.ready && freshP.frameResourceProof==nil && fresh.composableSceneVersion==1,
        "frame_ready_late_real_success_only_warms_key_never_completes_new_p");
    CHECK(frameWaitReady(freshToken,77) && freshP.frameResourceProof.sessionGeneration==fresh.sessionGeneration,
        "frame_ready_new_p_requires_own_actual_advance_and_key");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(freshToken,77)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_ready_new_p_cleanup");
    CjguiReleaseSession(freshToken);

}

static void testActualFrameCompilerFailureCannotCompleteReusedSlot(void) {
    // Previous owned fixtures have closed and all actual role callbacks ended.
    for (CjguiPreparedFramePipelines *set in gCjguiPreparedFramePipelines)
        CHECK(set.completedRoles == set.startedRoles, "frame_failure_fixture_prior_callbacks_terminal");
    gCjguiPreparedFramePipelines = nil;
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    CHECK(makeSession(&ctx,&token), "frame_failure_real_device_session");
    CJGuiInternalComposableSceneNode *a=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=a.node;raw.textAlpha=0;
    CjguiInternalRendererComposableGeometry geometry=a.geometry;geometry.nodeId=a.node.nodeId;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,91,1,2,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_failure_original_candidate");
    copyAcceptedStrings(a,&raw,token,91,geometry);
    gCjguiTestFailNextFrameShaderRoles=CjguiFramePipelineScene;
    uint32_t ready=99;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,91,0,&ready)==CJGUI_INTERNAL_RENDERER_OK && ready==0,
        "frame_failure_actual_failed_shader_request_pending");
    CjguiPreparedFramePipelines *oldSet=ctx.composablePreparation.frameResourcePipelines;
    uint64_t generation=ctx.sessionGeneration;
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,91)==CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion==1,
        "frame_failure_cancel_preserves_actual_A");
    CjguiReleaseSession(token);
    CJGuiInternalSession *fresh=nil;uint64_t newToken=0;
    CHECK(makeSession(&fresh,&newToken) && newToken==token && fresh.sessionGeneration!=generation,
        "frame_failure_slot_reused_real_new_generation");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(newToken,91,1,2,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_failure_same_request_new_session");
    CjguiComposablePreparation *freshP=fresh.composablePreparation;
    uint64_t end=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(2000000000);
    while (oldSet.completedRoles!=oldSet.startedRoles && cjgui_internal_renderer_owner_clock_ns()<end)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.005,true);
    CHECK(oldSet.completedRoles==oldSet.startedRoles && (oldSet.failedRoles & CjguiFramePipelineScene) && oldSet.scene==nil,
        "frame_failure_real_metal_error_terminal_no_fake_ready");
    CHECK(fresh.composablePreparation==freshP && !freshP.ready && freshP.frameResourceProof==nil && fresh.composableSceneVersion==1,
        "frame_failure_late_error_not_new_candidate_terminal_or_success");
    (void)cjgui_internal_renderer_cancel_composable_preparation(newToken,91);
    CJGuiInternalComposableSceneNode *freshA=fresh.composableNodes[0];
    CjguiInternalRendererComposableNode newRaw=freshA.node;newRaw.textAlpha=0;
    CjguiInternalRendererComposableGeometry newGeometry=freshA.geometry;newGeometry.nodeId=freshA.node.nodeId;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(newToken,92,1,2,1)==CJGUI_INTERNAL_RENDERER_OK,
        "frame_failure_required_failed_key_fresh_candidate");
    copyAcceptedStrings(freshA,&newRaw,newToken,92,newGeometry);
    ready=99;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(newToken,92,0,&ready)==CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR && ready==0 && fresh.composableSceneVersion==1,
        "frame_failure_real_failed_required_resource_refuses_keeps_A");
    (void)cjgui_internal_renderer_cancel_composable_preparation(newToken,92);
    CjguiReleaseSession(newToken);
    gCjguiPreparedFramePipelines=nil; // Only this terminal fixture's cache.
}

int main(int argc, const char **argv) { @autoreleasepool {
    if (argc == 2 && strcmp(argv[1], "--frame-resources-only") == 0) {
        testPreparedSubmissionWaitsForActualPipelines();
        testActualFrameCompilerFailureCannotCompleteReusedSlot();
        fprintf(stderr, "frame_resources summary failures=%d\n", failures);
        return failures ? 1 : 0;
    }
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
    testSelectionBackgroundDoesNotInvalidateFrozenGlyphSource();
    testReuseFreezesDeclaredRunsInsteadOfCachedPaintSignature();
    fprintf(stderr, "prepare_reuse summary failures=%d\n", failures);
    return failures ? 1 : 0;
} }
