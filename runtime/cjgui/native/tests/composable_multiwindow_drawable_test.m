// Only A's real layer is gated. B must acquire AND submit before A is opened.
#define CJGUI_DRAWABLE_ACQUISITION_HELPERS_ONLY 1
#import "composable_drawable_acquisition_test.m"
#undef CJGUI_DRAWABLE_ACQUISITION_HELPERS_ONLY

static BOOL windowGateClosed(void) {
    pthread_mutex_lock(&gCjguiTestDrawableGateLock);
    BOOL closed=gCjguiTestDrawableGateClosed;
    pthread_mutex_unlock(&gCjguiTestDrawableGateLock);return closed;
}
static BOOL warmWindow(CJGuiInternalSession *ctx) {
    CjguiInternalRendererComposableGeometry g={0};g.nodeId=100;
    if(!beginRealText(ctx,80,2,g,@"Original 中文 👩🏽‍💻",YES) ||
       !frameWaitReady(ctx.rendererSessionToken,80) ||
       !framePromote(ctx,ctx.rendererSessionToken,80))return NO;
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CjguiInternalRendererClearColor clear={.08,.16,.20,1};
    uint64_t before=ctx.view.frameIndex;
    CjguiInternalRendererStatus status=cjgui_internal_renderer_present_clear(ctx.rendererSessionToken,&clear,NULL);
    return (status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.view.frameIndex==before+1;
}
static BOOL startWindowResource(CJGuiInternalSession *ctx,uint64_t version) {
    uint32_t ready=0;
    return cjgui_internal_renderer_reserve_composable_drawable(ctx.rendererSessionToken,0,version,&ready)==0;
}
static BOOL submitWindowResource(CJGuiInternalSession *ctx,uint64_t version,NSString *body) {
    CJGuiInternalComposableSceneNode *old=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=version;
    CjguiInternalRendererComposableGeometry g=old.geometry;g.nodeId=raw.nodeId;
    uint64_t token=ctx.rendererSessionToken,frame=ctx.view.frameIndex;
    uint64_t request=ctx.view.drawableAcquireSlot.requestSequence;
    if(cjgui_internal_renderer_configure_composable_scene(token,version,1)!=0 ||
       CjguiSetComposableSceneNodeOnMain(token,0,&raw,"",body.UTF8String,NULL,NULL,0,nil)!=0 ||
       cjgui_internal_renderer_set_composable_scene_geometry(token,version,0,&g)!=0 ||
       cjgui_internal_renderer_stage_window_background(token,version,0,2)!=0)return NO;
    CjguiInternalRendererFrameObservation observation={0};
    CjguiInternalRendererStatus status=cjgui_internal_renderer_present_composable_scene(token,&observation);
    return (status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==version && ctx.view.frameIndex==frame+1 &&
        ctx.view.lastDrawableAcquireRequest==request && ctx.view.drawableAcquireSlot.state==0;
}
static void drainWindowResource(CJGuiInternalSession *ctx) {
    CjguiCancelDrawableSlot(ctx);
    cjgui_internal_renderer_test_drawable_gate_open();
    CHECK(waitSlotState(ctx.view,0,UINT64_C(2000000000)),"retired_request_reaches_idle");
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];CjguiTestExchangeDisplayClock();
    CJGuiInternalSession *a=nil,*b=nil;uint64_t ta=0,tb=0;
    CHECK(makeSession(&a,&ta) && makeSession(&b,&tb),"two_real_windows");
    if(!a || !b)return 1;
    CHECK(warmWindow(a) && warmWindow(b),"both_windows_have_real_accepted_frames");
    CjguiTestCloseDrawableGateForLayer(a.view.metalLayer);
    CHECK(startWindowResource(a,3) && waitGateEntry(UINT64_C(500000000)),"only_A_enters_controlled_gate");
    uint64_t begin=drawableNowNs();
    CHECK(startWindowResource(b,3),"B_requests_its_own_resource");
    BOOL independent=waitSlotState(b.view,2,UINT64_C(350000000));
    fprintf(stderr,"MULTIWINDOW independent=%u B_ready_ns=%llu A_gate=%u entries=%llu\n",
        independent,(unsigned long long)(drawableNowNs()-begin),windowGateClosed(),
        (unsigned long long)cjgui_internal_renderer_test_drawable_gate_entries());
    CHECK(independent && windowGateClosed() && a.view.drawableAcquireSlot.state==1,
        "B_ready_while_only_A_layer_is_blocked");
    if(independent) {
        CHECK(submitWindowResource(b,3,@"B continues before A") && windowGateClosed(),
            "B_really_submits_before_A_is_released");
    }
    drainWindowResource(a);
    if(!independent) {
        drainWindowResource(b);CjguiReleaseSession(ta);CjguiReleaseSession(tb);
        CjguiTestExchangeDisplayClock();
        fprintf(stderr,"multiwindow_drawable summary failures=%d\n",failures);
        return failures?1:0;
    }

    // Cancellation is local: keep B's exact Ready lease across A's late return.
    CjguiTestCloseDrawableGateForLayer(a.view.metalLayer);
    CHECK(startWindowResource(a,4) && waitGateEntry(UINT64_C(500000000)),"cancel_A_is_inflight");
    CHECK(startWindowResource(b,4) && waitSlotState(b.view,2,UINT64_C(350000000)),"B_ready_before_A_cancel");
    uint64_t bRequest=b.view.drawableAcquireSlot.requestSequence;
    drainWindowResource(a);
    CHECK(b.view.drawableAcquireSlot.state==2 && b.view.drawableAcquireSlot.requestSequence==bRequest &&
        submitWindowResource(b,4,@"B after A cancel"),"A_cancel_and_late_completion_preserve_B_exact_lease");

    // Size invalidation rejects A's frozen resource rather than B's live one.
    CjguiTestCloseDrawableGateForLayer(a.view.metalLayer);
    CHECK(startWindowResource(a,5) && waitGateEntry(UINT64_C(500000000)),"resize_A_is_inflight");
    CHECK(startWindowResource(b,5) && waitSlotState(b.view,2,UINT64_C(350000000)),"B_ready_before_A_resize");
    bRequest=b.view.drawableAcquireSlot.requestSequence;
    CGSize size=a.view.metalLayer.drawableSize;
    a.view.metalLayer.drawableSize=CGSizeMake(size.width+2,size.height);
    cjgui_internal_renderer_test_drawable_gate_open();
    CHECK(waitSlotState(a.view,0,UINT64_C(2000000000)),"A_old_size_late_drawable_rejected");
    CHECK(b.view.drawableAcquireSlot.requestSequence==bRequest && submitWindowResource(b,5,@"B after A resize"),
        "A_size_invalidation_preserves_B_exact_lease");

    // A closes while its worker is blocked; the callback cannot resurrect it.
    CjguiTestCloseDrawableGateForLayer(a.view.metalLayer);
    CHECK(startWindowResource(a,6) && waitGateEntry(UINT64_C(500000000)),"closing_A_is_inflight");
    CHECK(startWindowResource(b,6) && waitSlotState(b.view,2,UINT64_C(350000000)),"B_ready_before_A_close");
    bRequest=b.view.drawableAcquireSlot.requestSequence;
    CjguiDrawableAcquireSlot *retired=a.view.drawableAcquireSlot;
    CjguiReleaseSession(ta);a=nil;ta=0;
    cjgui_internal_renderer_test_drawable_gate_open();
    uint64_t end=drawableNowNs()+UINT64_C(2000000000);
    while(retired.state!=0 && drawableNowNs()<end)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.004,true);
    CHECK(retired.state==0 && !retired.drawable && !retired.layer,"closed_A_late_resource_released_without_resurrection");
    CHECK(b.view.drawableAcquireSlot.requestSequence==bRequest && submitWindowResource(b,6,@"B survives closed A"),
        "B_submits_after_A_destroy_and_late_return");
    cjgui_internal_renderer_test_drawable_gate_open();
    if(ta)CjguiReleaseSession(ta);if(tb)CjguiReleaseSession(tb);
    CjguiTestExchangeDisplayClock();
    fprintf(stderr,"multiwindow_drawable summary failures=%d\n",failures);
    return failures?1:0;
} }
