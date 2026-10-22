// Ordinary interaction paint must wait on the existing drawable slot away
// from the owner/main loop, without publishing or retaining business input.
#define main InteractionPreviousPreparationMain
#import "composable_preparation_reuse_test.m"
#undef main
#import "accepted_paint_manual_display_link.h"
#include <mach/mach_time.h>

static uint64_t interactionNow(void) {
    mach_timebase_info_data_t info={0};mach_timebase_info(&info);
    return (uint64_t)(((__uint128_t)mach_absolute_time()*info.numer)/info.denom);
}
static void *interactionOpenGate(void *unused) {
    (void)unused; usleep(160000);
    cjgui_internal_renderer_test_drawable_gate_open();return NULL;
}
static BOOL interactionReady(CJGuiInternalSession *ctx) {
    uint64_t end=interactionNow()+UINT64_C(2000000000);
    while(ctx.view.drawableAcquireSlot.state!=2 && interactionNow()<end)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.004,true);
    return ctx.view.drawableAcquireSlot.state==2;
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];CjguiTestExchangeDisplayClock();
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    CHECK(makeSession(&ctx,&token),"interaction_real_window");if(!ctx)return 1;
    uint64_t accepted=ctx.composableSceneVersion,frame=ctx.view.frameIndex;
    cjgui_internal_renderer_test_drawable_gate_close();pthread_t watchdog;
    BOOL started=pthread_create(&watchdog,NULL,interactionOpenGate,NULL)==0;
    uint32_t ready=99;uint64_t begin=interactionNow();
    CjguiInternalRendererStatus status=cjgui_internal_renderer_reserve_composable_drawable(token,0,2,&ready);
    uint64_t elapsed=interactionNow()-begin;
    CHECK(status==0 && ready==0 && elapsed<UINT64_C(40000000) &&
        ctx.composableSceneVersion==accepted && ctx.view.frameIndex==frame,
        "ordinary_interaction_preflight_yields_without_scene_or_frame_publication");
    if(started)pthread_join(watchdog,NULL);else cjgui_internal_renderer_test_drawable_gate_open();
    if(status!=0){CjguiReleaseSession(token);return failures?1:0;}
    CHECK(interactionReady(ctx),"ordinary_interaction_existing_slot_becomes_ready");
    uint64_t request=ctx.view.drawableAcquireSlot.requestSequence;
    [ctx.composableSceneOverlay scheduleAcceptedScenePresent];
    [ctx.composableSceneOverlay presentAcceptedSceneIfNeeded];
    CHECK(ctx.view.frameIndex==frame && ctx.view.drawableAcquireSlot.state==2 &&
        ctx.view.drawableAcquireSlot.projectionVersion==2,
        "old_accepted_paint_cannot_consume_interaction_projection_lease");
    CJGuiInternalComposableSceneNode *old=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=2;
    CjguiInternalRendererComposableGeometry geometry=old.geometry;
    geometry.nodeId=raw.nodeId;
    int configured=cjgui_internal_renderer_configure_composable_scene(token,2,1);
    int node=CjguiSetComposableSceneNodeOnMain(token,0,&raw,"Go","changed",NULL,NULL,0,nil);
    int geo=cjgui_internal_renderer_set_composable_scene_geometry(token,2,0,&geometry);
    int background=cjgui_internal_renderer_stage_window_background(token,2,0,2);
    fprintf(stderr,"INTERACTION_STAGE configure=%d node=%d geometry=%d background=%d\n",configured,node,geo,background);
    CHECK(configured==0 && node==0 && geo==0 && background==0,
        "ordinary_interaction_stages_one_changed_node");
    // Same real host/fallback setup as composable_drawable_acquisition_test;
    // a sidecar-only session otherwise cannot apply its window background.
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    // A ready lease must be consumed once; a second real nextDrawable call
    // would hit this controlled gate and fail the bounded return assertion.
    cjgui_internal_renderer_test_drawable_gate_close();started=pthread_create(&watchdog,NULL,interactionOpenGate,NULL)==0;
    CjguiInternalRendererFrameObservation observation={0};begin=interactionNow();
    status=cjgui_internal_renderer_present_composable_scene(token,&observation);elapsed=interactionNow()-begin;
    if(started)pthread_join(watchdog,NULL);else cjgui_internal_renderer_test_drawable_gate_open();
    fprintf(stderr,"INTERACTION_PRESENT status=%d elapsed_ns=%llu frame=%llu/%llu lease=%llu/%llu slot=%u gate_entries=%llu\n",
        status,(unsigned long long)elapsed,(unsigned long long)ctx.view.frameIndex,(unsigned long long)(frame+1),
        (unsigned long long)ctx.view.lastDrawableAcquireRequest,(unsigned long long)request,ctx.view.drawableAcquireSlot.state,
        (unsigned long long)cjgui_internal_renderer_test_drawable_gate_entries());
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        elapsed<UINT64_C(40000000) && ctx.view.frameIndex==frame+1 &&
        ctx.view.lastDrawableAcquireRequest==request && ctx.view.drawableAcquireSlot.state==0 &&
        cjgui_internal_renderer_test_drawable_gate_entries()==0,
        "ordinary_interaction_consumes_ready_slot_once_without_synchronous_acquisition");
    CjguiReleaseSession(token);CjguiTestExchangeDisplayClock();
    fprintf(stderr,"interaction_drawable summary failures=%d present_ns=%llu\n",failures,(unsigned long long)elapsed);
    return failures?1:0;
} }
