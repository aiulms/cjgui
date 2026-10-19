// A frozen preparation must not rescan every node for each text/tile unit.
// Exercise the real Metal pipeline preparation and its lifetime refusals.
#define main existingFramePipelineMain
#import "composable_frame_pipeline_preparation_test.m"
#undef main

static NSUInteger descriptorNodeReads;
@interface DescriptorCountingNode : CJGuiInternalComposableSceneNode
@end
@implementation DescriptorCountingNode
- (CjguiInternalRendererComposableNode)node {
    descriptorNodeReads++;
    return [super node];
}
@end

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx = MakeSession(MTLCreateSystemDefaultDevice());
    CjguiComposablePreparation *p = [CjguiComposablePreparation new];
    p.sessionToken = ctx.rendererSessionToken; p.sessionGeneration = ctx.sessionGeneration;
    p.preparationId = 91; p.projectionVersion = 17;
    p.nodes = [NSMutableArray array]; p.filled = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < 256; i++) {
        DescriptorCountingNode *node = [DescriptorCountingNode new];
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = i + 1; raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.projectionVersion = p.projectionVersion;
        node.node = raw; [p.nodes addObject:node]; [p.filled addIndex:i];
    }
    uint32_t ready = 0;
    uint64_t deadline = cjgui_internal_renderer_owner_clock_ns() + 5000000000ull;
    CHECK(CjguiPrepareCandidateFrameResourcesOnMain(ctx, p, deadline, &ready) == 0,
        "fully_filled_candidate_starts_real_pipeline_preparation");
    DrainUntil(p.frameResourcePipelines);
    CHECK(CjguiPrepareCandidateFrameResourcesOnMain(ctx, p, deadline, &ready) == 0 && ready,
        "completed_pipeline_has_device_bound_descriptor_proof");
    CjguiPreparedFrameResourceProof *proof = p.frameResourceProof;
    NSUInteger before = descriptorNodeReads;
    BOOL continued = YES;
    for (NSUInteger i = 0; i < 64; i++) {
        ready = 0;
        continued &= CjguiPrepareCandidateFrameResourcesOnMain(ctx, p, deadline, &ready) == 0 &&
            ready && p.frameResourceProof == proof;
    }
    fprintf(stderr, "DESCRIPTOR_REUSE nodes=256 units=64 repeat_node_reads=%lu\n",
        (unsigned long)(descriptorNodeReads - before));
    CHECK(continued, "later_units_keep_the_same_frozen_pipeline_proof");
    CHECK(descriptorNodeReads == before,
        "text_units_do_not_repeat_whole_scene_descriptor_scans");

    ctx.view.metalLayer.pixelFormat = MTLPixelFormatRGBA8Unorm;
    CHECK(CjguiPrepareCandidateFrameResourcesOnMain(ctx, p, deadline, &ready) ==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ready,
        "changed_layer_format_rejects_cached_preparation");
    ctx.view.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    ctx.view.invalidated = YES;
    CHECK(CjguiPrepareCandidateFrameResourcesOnMain(ctx, p, deadline, &ready) ==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ready,
        "invalidated_view_rejects_cached_preparation");
    ctx.view.invalidated = NO;
    ctx.sessionGeneration++;
    CHECK(CjguiPrepareCandidateFrameResourcesOnMain(ctx, p, deadline, &ready) ==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ready,
        "changed_session_generation_rejects_cached_preparation");
    ctx.sessionGeneration--;
    CHECK(CjguiPreparedFrameProofMatches(ctx, proof, p.nodes, p.projectionVersion),
        "adoption_still_checks_actual_final_scene_descriptor");
    // Other text nodes still require the image pipeline; remove every text
    // role to distinguish a frozen advance proof from the final adoption gate.
    for (CJGuiInternalComposableSceneNode *node in p.nodes) {
        CjguiInternalRendererComposableNode raw = node.node;
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
        node.node = raw;
    }
    CHECK(!CjguiPreparedFrameProofMatches(ctx, proof, p.nodes, p.projectionVersion),
        "final_adoption_refuses_changed_actual_scene_descriptor");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
    return failures ? 1 : 0;
} }
