#define main CjguiDrawableAcquisitionFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main
#import "accepted_paint_manual_display_link.h"
#include <mach/mach_time.h>

extern void cjgui_internal_renderer_test_drawable_gate_close(void);
extern uint64_t cjgui_internal_renderer_test_drawable_gate_entries(void);
extern void cjgui_internal_renderer_test_drawable_gate_open(void);

static uint64_t drawableNowNs(void) {
    mach_timebase_info_data_t info={0};mach_timebase_info(&info);
    return (uint64_t)(((__uint128_t)mach_absolute_time()*info.numer)/info.denom);
}
static void *openDrawableGateAfter(void *opaque) {
    uint32_t milliseconds=(uint32_t)(uintptr_t)opaque;
    usleep(milliseconds*1000u);
    cjgui_internal_renderer_test_drawable_gate_open();
    return NULL;
}
static BOOL releaseGateAfter(uint32_t milliseconds,pthread_t *thread) {
    return pthread_create(thread,NULL,openDrawableGateAfter,(void *)(uintptr_t)milliseconds)==0;
}
static BOOL waitGateEntry(uint64_t timeoutNs) {
    uint64_t end=drawableNowNs()+timeoutNs;
    while(drawableNowNs()<end) {
        if(cjgui_internal_renderer_test_drawable_gate_entries())return YES;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.002,true);
    }
    return cjgui_internal_renderer_test_drawable_gate_entries()!=0;
}
static BOOL waitSlotState(CJGuiInternalMetalView *view,uint32_t state,uint64_t timeoutNs) {
    uint64_t end=drawableNowNs()+timeoutNs;
    while(drawableNowNs()<end) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.004,true);
        if(view.drawableAcquireSlot.state==state)return YES;
    }
    return view.drawableAcquireSlot.state==state;
}
static BOOL beginRealText(CJGuiInternalSession *ctx,uint64_t request,uint64_t version,
    CjguiInternalRendererComposableGeometry geometry,NSString *body,BOOL full) {
    uint64_t token=ctx.rendererSessionToken;
    CJGuiInternalComposableSceneNode *accepted=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=accepted.node;raw.projectionVersion=version;
    if(full) {
        raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x=24;raw.y=40;raw.width=420;raw.height=28;
        raw.clipX=0;raw.clipY=0;raw.clipWidth=480;raw.clipHeight=320;
        raw.fontSize=14;raw.textRed=.8;raw.textGreen=.8;raw.textBlue=.8;raw.textAlpha=1;
    }
    if(cjgui_internal_renderer_begin_composable_preparation(token,request,
        ctx.composableSceneVersion,version,1)!=CJGUI_INTERNAL_RENDERER_OK)return NO;
    if(full)return cjgui_internal_renderer_prepare_composable_node(token,request,0,&raw,&geometry,
        "",body.UTF8String,"row","binding-100","row","","row","")==CJGUI_INTERNAL_RENDERER_OK;
    uint32_t reused=0;
    return cjgui_internal_renderer_reuse_composable_node_batch(token,request,0,1,&raw,&geometry,0,&reused)==
        CJGUI_INTERNAL_RENDERER_OK && reused==1;
}
static BOOL waitReady(uint64_t token,uint64_t request) {
    uint64_t end=drawableNowNs()+UINT64_C(3000000000);uint32_t ready=0;
    while(!ready && drawableNowNs()<end) {
        CjguiInternalRendererStatus status=cjgui_internal_renderer_advance_composable_preparation(
            token,request,0,&ready);
        if(status!=CJGUI_INTERNAL_RENDERER_OK)return NO;
        if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.004,true);
    }
    return ready!=0;
}
static BOOL waitCandidateDrawable(uint64_t token,uint64_t prep,uint64_t projection) {
    uint64_t end=drawableNowNs()+UINT64_C(3000000000);uint32_t ready=0;
    while(!ready && drawableNowNs()<end) {
        CjguiInternalRendererStatus status=cjgui_internal_renderer_reserve_composable_drawable(
            token,prep,projection,&ready);
        if(status!=CJGUI_INTERNAL_RENDERER_OK)return NO;
        if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.004,true);
    }
    return ready!=0;
}

int main(int argc,char **argv) { @autoreleasepool {
    [NSApplication sharedApplication];
    if(argc>1 && argv[1][0]=='/') setenv("CJGUI_FRAME_CADENCE_TRACE_PATH",argv[1],1);
    setenv("CJGUI_CANDIDATE_FIRST_FAILURE","1",1);
    CjguiTestExchangeDisplayClock();
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    CHECK(makeSession(&ctx,&token),"real_CAMetalLayer_session_fixture");
    if(!ctx)return 1;
    CjguiInternalRendererComposableGeometry geometry={0};geometry.nodeId=100;
    NSString *body=@"TEXT3 real drawable admission keeps the accepted source and glyph raster.";
    CHECK(beginRealText(ctx,80,2,geometry,body,YES) && frameWaitReady(token,80) && framePromote(ctx,token,80),
        "accepted_TEXT3_source_is_real_and_prepared");
    CjguiInternalRendererClearColor clear={.08,.16,.20,1};
    uint64_t initialFrame=ctx.view.frameIndex;
    CjguiInternalRendererStatus initial=cjgui_internal_renderer_present_clear(token,&clear,NULL);
    CHECK((initial==CJGUI_INTERNAL_RENDERER_OK || initial==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.view.frameIndex==initialFrame+1,"accepted_TEXT3_initial_real_frame_submitted");

    // A test-only, watchdog-released gate sits immediately before the real
    // CAMetalLayer call. It is a controlled acquisition delay, not a claim of
    // drawable-pool exhaustion.
    cjgui_internal_renderer_test_drawable_gate_close();pthread_t redWatchdog;
    BOOL redWatchdogStarted=releaseGateAfter(140,&redWatchdog);
    uint64_t redFrame=ctx.view.frameIndex,redStart=drawableNowNs();
    CjguiInternalRendererStatus redStatus=cjgui_internal_renderer_present_clear(token,&clear,NULL);
    uint64_t redElapsed=drawableNowNs()-redStart;
    BOOL redJoined=redWatchdogStarted && pthread_join(redWatchdog,NULL)==0;
    CHECK(redJoined && cjgui_internal_renderer_test_drawable_gate_entries()==1 &&
        (redStatus==CJGUI_INTERNAL_RENDERER_OK || redStatus==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        redElapsed>=UINT64_C(100000000) && ctx.view.frameIndex==redFrame+1,
        "controlled_real_acquisition_gate_blocks_legacy_main_RED");

    cjgui_internal_renderer_test_drawable_gate_close();pthread_t greenWatchdog;
    BOOL greenWatchdogStarted=releaseGateAfter(160,&greenWatchdog);
    CJGuiInternalComposableSceneOverlay *overlay=ctx.composableSceneOverlay;
    uint64_t greenFrame=ctx.view.frameIndex,greenStart=drawableNowNs();
    [overlay scheduleAcceptedScenePresent];[overlay presentAcceptedSceneIfNeeded];
    uint64_t mainElapsed=drawableNowNs()-greenStart;
    BOOL entered=waitGateEntry(UINT64_C(50000000));
    CjguiInternalRendererWindowBackgroundSnapshot snapshot={0};
    CjguiInternalRendererStatus mainService=cjgui_internal_renderer_window_background_snapshot(token,&snapshot);
    CHECK(greenWatchdogStarted && entered && mainService==CJGUI_INTERNAL_RENDERER_OK &&
        mainElapsed<UINT64_C(40000000) && ctx.view.frameIndex==greenFrame &&
        overlay.acceptedScenePresentScheduled && ctx.view.drawableAcquireSlot.state==1,
        "accepted_paint_waits_off_main_dirty_retained_while_main_services_native_readback");
    BOOL greenJoined=greenWatchdogStarted && pthread_join(greenWatchdog,NULL)==0;
    CHECK(greenJoined && waitSlotState(ctx.view,2,UINT64_C(2000000000)) &&
        ctx.view.frameIndex==greenFrame && overlay.acceptedScenePresentScheduled,
        "real_drawable_ready_does_not_consume_paint_or_publish_frame");
    uint64_t acceptedRequest=ctx.view.drawableAcquireSlot.requestSequence;
    [CjguiTestLastDisplayLink fire];
    CHECK(ctx.view.frameIndex==greenFrame+1 && !overlay.acceptedScenePresentScheduled &&
        ctx.view.lastDrawableAcquireRequest==acceptedRequest && ctx.view.drawableAcquireSlot.state==0,
        "one_display_tick_consumes_exact_ready_lease_and_submits_A");

    geometry.translateY=-12;
    CHECK(beginRealText(ctx,81,3,geometry,body,NO) && waitReady(token,81),
        "same_candidate_waits_for_real_TEXT3_pipeline_resources");
    CjguiComposablePreparation *p=ctx.composablePreparation;
    CHECK(p && p.ready && p.frameResourceProof && !p.frameResourceProof.drawableLease,
        "candidate_pipeline_ready_does_not_reserve_drawable_before_selection_gate");
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,3,1)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_scene_configured_from_same_preparation");
    for(NSNumber *key in p.runs)
        CHECK(cjgui_internal_renderer_set_composable_text_runs(token,key.longLongValue,
            p.runs[key].UTF8String)==CJGUI_INTERNAL_RENDERER_OK,"candidate_runs_staged");
    CHECK(cjgui_internal_renderer_stage_window_background(token,3,0,1)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_background_staged");
    CHECK(cjgui_internal_renderer_promote_composable_preparation(token,81)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_preparation_promoted_without_early_drawable");
    uint32_t reserved=0;
    CjguiInternalRendererStatus reserveStatus=cjgui_internal_renderer_reserve_composable_drawable(
        token,81,3,&reserved);
    if(reserveStatus==CJGUI_INTERNAL_RENDERER_OK && !reserved) waitCandidateDrawable(token,81,3);
    CHECK(reserveStatus==CJGUI_INTERNAL_RENDERER_OK &&
        CjguiStagedDrawableLeaseIsCurrent(ctx,ctx.stagedFrameResourceProof),
        "selection_ready_candidate_owns_exact_real_drawable_lease");
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CjguiInternalRendererFrameObservation observation={0};
    uint64_t candidateFrame=ctx.view.frameIndex;
    CjguiInternalRendererStatus candidate=cjgui_internal_renderer_present_composable_scene(token,&observation);
    fprintf(stderr,"CANDIDATE_RESULT status=%u scene=%llu frame_before=%llu frame_after=%llu staged_proof=%p view_proof=%p slot=%u\n",
        candidate,(unsigned long long)ctx.composableSceneVersion,(unsigned long long)candidateFrame,
        (unsigned long long)ctx.view.frameIndex,ctx.stagedFrameResourceProof,ctx.view.preparedFrameResourceProof,
        ctx.view.drawableAcquireSlot.state);
    CHECK((candidate==CJGUI_INTERNAL_RENDERER_OK || candidate==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==3 && ctx.view.frameIndex==candidateFrame+1 &&
        ctx.view.drawableAcquireSlot.state==0 && ctx.view.preparedFrameResourceProof==nil,
        "normal_candidate_consumes_bound_drawable_only_after_commit_and_encode");

    cjgui_internal_renderer_test_drawable_gate_close();pthread_t resizeWatchdog;
    BOOL resizeWatchdogStarted=releaseGateAfter(120,&resizeWatchdog);
    uint64_t resizeFrame=ctx.view.frameIndex;
    [overlay scheduleAcceptedScenePresent];[overlay presentAcceptedSceneIfNeeded];
    BOOL oldRequestEntered=waitGateEntry(UINT64_C(50000000));
    uint64_t oldRequest=ctx.view.drawableAcquireSlot.requestSequence;
    ctx.view.bounds=NSMakeRect(0,0,500,340);[ctx.view updateDrawableSize];
    BOOL resizeWatchdogJoined=resizeWatchdogStarted && pthread_join(resizeWatchdog,NULL)==0;
    BOOL staleDropped=waitSlotState(ctx.view,0,UINT64_C(2000000000));
    CHECK(oldRequestEntered && resizeWatchdogJoined && staleDropped &&
        ctx.view.frameIndex==resizeFrame && overlay.acceptedScenePresentScheduled,
        "resized_layer_drops_old_actual_drawable_and_keeps_A_dirty");
    [overlay presentAcceptedSceneIfNeeded];
    BOOL newReady=waitSlotState(ctx.view,2,UINT64_C(2000000000));
    uint64_t newRequest=ctx.view.drawableAcquireSlot.requestSequence;
    CHECK(newReady && newRequest>oldRequest && ctx.view.frameIndex==resizeFrame &&
        overlay.acceptedScenePresentScheduled,
        "new_size_gets_separate_ready_request_without_early_ack");
    [CjguiTestLastDisplayLink fire];
    CHECK(ctx.view.frameIndex==resizeFrame+1 && !overlay.acceptedScenePresentScheduled &&
        ctx.view.lastDrawableAcquireRequest==newRequest,
        "only_new_size_lease_submits_one_A_frame");

    // The existing zero-deadline native Present contract is separate from
    // the Cangjie consumer's explicit resource-reservation seam.
    CHECK(beginRealText(ctx,82,4,geometry,body,NO) && waitReady(token,82),
        "legacy_zero_deadline_preparation_keeps_original_native_contract");
    p=ctx.composablePreparation;
    BOOL legacyStaged=cjgui_internal_renderer_configure_composable_scene(token,4,1)==0;
    for(NSNumber *key in p.runs)
        legacyStaged=legacyStaged && cjgui_internal_renderer_set_composable_text_runs(token,
            key.longLongValue,p.runs[key].UTF8String)==0;
    legacyStaged=legacyStaged && cjgui_internal_renderer_stage_window_background(token,4,0,1)==0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,82)==0;
    uint64_t legacyFrame=ctx.view.frameIndex;
    CjguiInternalRendererStatus legacyPresent=legacyStaged
        ? cjgui_internal_renderer_present_composable_scene(token,&observation) : 99;
    CHECK((legacyPresent==0 || legacyPresent==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==4 && ctx.view.frameIndex==legacyFrame+1,
        "legacy_zero_deadline_candidate_still_really_presents");

    [overlay scheduleAcceptedScenePresent];[overlay presentAcceptedSceneIfNeeded];
    uint64_t replacementFrame=ctx.view.frameIndex;
    CjguiInternalRendererStatus replacement=cjgui_internal_renderer_present_clear(token,&clear,NULL);
    BOOL retiredObsolete=waitSlotState(ctx.view,0,UINT64_C(2000000000));
    CHECK((replacement==0 || replacement==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.view.frameIndex==replacementFrame+1 && !overlay.acceptedScenePresentScheduled && retiredObsolete,
        "real_legacy_submission_retires_obsolete_A_acquisition_without_orphan_Ready");

    CjguiReleaseSession(token);CjguiTestExchangeDisplayClock();
    fprintf(stderr,"drawable_acquisition summary failures=%d controlled_legacy_main_ns=%llu accepted_main_ns=%llu\n",
        failures,(unsigned long long)redElapsed,(unsigned long long)mainElapsed);
    return failures?1:0;
} }
