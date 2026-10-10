#define main OriginalScenePreparationFixtureMain
#import "composable_scene_preparation_test.m"
#undef main

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,300,180)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes = [NSMutableArray arrayWithObject:[CJGuiInternalComposableSceneNode new]];
    ctx.composableSceneVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    ctx.view.sessionToken = token;
    ctx.retiringComposablePreparations = [NSMutableArray array];
    for (NSUInteger graph = 0; graph < 2; ++graph) {
        CjguiComposablePreparation *p = [CjguiComposablePreparation new];
        p.retiring = YES; p.nodes = [NSMutableArray array];
        for (NSUInteger node = 0; node < 117; ++node)
            [p.nodes addObject:[CJGuiInternalComposableSceneNode new]];
        [ctx.retiringComposablePreparations addObject:p];
    }
    NSArray *accepted = ctx.composableNodes;
    uint8_t mayBegin = 1;
    CHECK(cjgui_internal_renderer_drain_composable_retirement(token,
        cjgui_internal_renderer_owner_clock_ns(), &mayBegin) == 0 && !mayBegin &&
        ctx.retiringComposablePreparations.count == 2,
        "expired_allowance_releases_zero_units");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,91,1,2,1) == 0 &&
        ctx.retiringComposablePreparations.count < 2,
        "two_cancelled_graphs_release_before_new_admission");
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == 1,
        "retirement_has_no_accepted_scene_write");
    CjguiReleaseSession(token);
    return failures ? 1 : 0;
} }
