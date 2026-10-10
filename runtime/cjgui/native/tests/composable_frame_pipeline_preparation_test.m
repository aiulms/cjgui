// Actual asynchronous Metal compilation and immutable device-key reuse.
// Native protocol fixture; normal Cangjie consumers are verified separately.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
static int failures;
#define CHECK(c,label) do { BOOL ok=(c); fprintf(stderr,"frame_pipeline case=%s result=%s\n",label,ok?"PASS":"FAIL");if(!ok)++failures; } while(0)
static CJGuiInternalSession *MakeSession(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];ctx.app=NSApp;ctx.device=device;
    ctx.window=[[NSWindow alloc] initWithContentRect:NSMakeRect(40,80,320,220)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    // Match the production session's strong window ownership through normal close.
    ctx.window.releasedWhenClosed=NO;
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,320,220)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window.contentView=ctx.view;CjguiAllocateSession(ctx);return ctx;
}
static void DrainUntil(CjguiPreparedFramePipelines *set) {
    uint64_t end=cjgui_internal_renderer_owner_clock_ns()+5000000000ull;
    while(set.completed!=2 && cjgui_internal_renderer_owner_clock_ns()<end)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.002]];
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 1;
    CJGuiInternalSession *first=MakeSession(device);uint32_t ready=99;
    uint64_t begin=cjgui_internal_renderer_owner_clock_ns();
    CHECK(cjgui_internal_renderer_prepare_frame_resources(first.rendererSessionToken,17,begin-1,&ready)==0 &&
        ready==0 && gCjguiPreparedFramePipelines.count==0,"expired_deadline_does_not_start_compile");
    begin=cjgui_internal_renderer_owner_clock_ns();
    CHECK(cjgui_internal_renderer_prepare_frame_resources(first.rendererSessionToken,17,begin+16000000,&ready)==0 &&
        ready==0 && gCjguiPreparedFramePipelines.count==1,"cold_preparation_yields_before_real_compiler_completes");
    uint64_t owner=cjgui_internal_renderer_owner_clock_ns()-begin;
    fprintf(stderr,"FRAME_PIPELINE_COST cold_owner_ns=%llu\n",(unsigned long long)owner);
    CHECK(owner<16000000,"cold_preparation_owner_budget_kept");
    CjguiPreparedFramePipelines *set=gCjguiPreparedFramePipelines.firstObject;
    CHECK(set.device==device && !first.view.composablePipeline && !first.view.composableImagePipeline,
        "pending_resource_cannot_be_painted_as_ready");
    CHECK(cjgui_internal_renderer_destroy(first.rendererSessionToken)==0 && first.destroyed,
        "closing_pending_compile_has_no_window_or_input_lease");
    DrainUntil(set);
    CHECK(set.completed==2 && !set.failed && set.scene.device==device && set.image.device==device &&
        set.readyNs>=set.startedNs,"actual_metal_device_pipeline_and_completion_observed");
    CHECK(!first.view && first.destroyed,"late_completion_does_not_publish_to_closed_view");
    CJGuiInternalSession *second=MakeSession(device);begin=cjgui_internal_renderer_owner_clock_ns();
    CHECK(cjgui_internal_renderer_prepare_frame_resources(second.rendererSessionToken,18,begin+16000000,&ready)==0 &&
        ready==1 && gCjguiPreparedFramePipelines.count==1,"same_device_and_samples_reuse_actual_completed_set");
    id<MTLRenderPipelineState> scene=second.view.composableUsesMultisampling?second.view.composableMultisamplePipeline:second.view.composablePipeline;
    id<MTLRenderPipelineState> image=second.view.composableUsesMultisampling?second.view.composableMultisampleImagePipeline:second.view.composableImagePipeline;
    CHECK(scene==set.scene && image==set.image,"adoption_uses_same_real_pipeline_objects");
    second.view.composableUsesMultisampling=!second.view.composableUsesMultisampling;
    begin=cjgui_internal_renderer_owner_clock_ns();
    CHECK(cjgui_internal_renderer_prepare_frame_resources(second.rendererSessionToken,19,begin+16000000,&ready)==0 &&
        ready==0 && gCjguiPreparedFramePipelines.count==2,"different_sample_count_never_uses_wrong_cache_identity");
    CjguiPreparedFramePipelines *other=gCjguiPreparedFramePipelines.lastObject;DrainUntil(other);
    CHECK(other.sampleCount!=set.sampleCount && other.completed==2 && !other.failed,
        "different_descriptor_has_independent_real_resources");
    cjgui_internal_renderer_destroy(second.rendererSessionToken);
    fprintf(stderr,"frame_pipeline failures=%d\n",failures);return failures?1:0;
} }
