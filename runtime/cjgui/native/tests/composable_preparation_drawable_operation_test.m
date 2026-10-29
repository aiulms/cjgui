// A promoted candidate waiting for its drawable is pending resource work,
// rather than18 synchronous owner retries. Reuse the original mailbox/wake.
#define CJGUI_DRAWABLE_ACQUISITION_HELPERS_ONLY 1
#import "composable_drawable_acquisition_test.m"

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];CjguiTestExchangeDisplayClock();
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    CHECK(makeSession(&ctx,&token),"owned_drawable_fixture");if(!ctx)return 1;
    CjguiInternalRendererComposableGeometry geometry={0};geometry.nodeId=100;
    CHECK(beginRealText(ctx,301,2,geometry,@"drawable owner wake",YES) && frameWaitReady(token,301),
        "real_text_and_pipeline_prepared");
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,1)==0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,301)==0 &&
        cjgui_internal_renderer_stage_window_background(token,2,0,2)==0,"original_candidate_staged");
    gCjguiMainThreadDispatchEnabled=YES;
    cjgui_internal_renderer_test_drawable_gate_close();
    uint64_t words[32]={2};CjguiInternalRendererPreparationOperation op={.kind=10,.values32=words};
    __block CjguiInternalRendererPreparationOperationResult r={0};__block int status=-1;
    dispatch_semaphore_t returned=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        status=cjgui_internal_renderer_preparation_operation_admit(token,301,drawableNowNs()+1000000000u,&op,&r);
        dispatch_semaphore_signal(returned);
    });
    CHECK(dispatch_semaphore_wait(returned,dispatch_time(DISPATCH_TIME_NOW,16000000u))==0 && status==0 && r.state==1,
        "drawable_admission_returns_before_main_and_worker");
    if(r.state==1) {
        uint64_t nonce=r.nonce;
        CHECK(waitGateEntry(1000000000u),"original_acquisition_worker_at_gate");
        CHECK(cjgui_internal_renderer_preparation_operation_waiting(token)==1,"pending_drawable_allows_owner_to_wait");
        for(unsigned n=0;n<8;n++)
            (void)cjgui_internal_renderer_preparation_operation_poll(token,301,nonce,0,&r);
        CHECK(r.state==1 && r.nonce==nonce && !gCjguiPreparationAdvanceSlots[token-1].serviceScheduled,
            "polling_does_not_reschedule_resource_service_or_renew_nonce");
        cjgui_internal_renderer_test_drawable_gate_open();
        uint64_t end=drawableNowNs()+2000000000u;
        do {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode,.002,true);
            (void)cjgui_internal_renderer_preparation_operation_poll(token,301,nonce,0,&r);
        }while(r.state==1 && drawableNowNs()<end);
        CHECK(r.state==2 && !r.status && r.prefix==1 && !r.stop &&
            CjguiStagedDrawableLeaseIsCurrent(ctx,ctx.stagedFrameResourceProof),
            "real_drawable_completion_wakes_and_publishes_exact_original_candidate");
        (void)cjgui_internal_renderer_preparation_operation_poll(token,301,nonce,1,&r);
        CHECK(cjgui_internal_renderer_preparation_operation_waiting(token)==0 &&
            atomic_load(&gCjguiPreparationOwnedBytes)==0,"consumed_drawable_result_releases_transport");
        cjgui_internal_renderer_preparation_operation_retire(token,301);
        end=drawableNowNs()+1000000000u;
        while(cjgui_internal_renderer_preparation_operation_waiting(token) && drawableNowNs()<end)
            CFRunLoopRunInMode(kCFRunLoopDefaultMode,.002,true);
        CHECK(!ctx.stagedFrameResourceProof && !ctx.view.drawableAcquireSlot.state,
            "same_retirement_releases_promoted_proof_and_drawable_without_sync_tail");
    }
    cjgui_internal_renderer_test_drawable_gate_open();
    if (!failures) {
        CHECK(beginRealText(ctx,302,3,geometry,@"late drawable must retire",YES) && frameWaitReady(token,302) &&
            cjgui_internal_renderer_configure_composable_scene(token,3,1)==0 &&
            cjgui_internal_renderer_promote_composable_preparation(token,302)==0 &&
            cjgui_internal_renderer_stage_window_background(token,3,0,2)==0,"pending_cancel_candidate_staged");
        cjgui_internal_renderer_test_drawable_gate_close();words[0]=3;r=(CjguiInternalRendererPreparationOperationResult){0};
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            status=cjgui_internal_renderer_preparation_operation_admit(token,302,drawableNowNs()+1000000000u,&op,&r);
            dispatch_semaphore_signal(returned);
        });
        CHECK(dispatch_semaphore_wait(returned,dispatch_time(DISPATCH_TIME_NOW,16000000u))==0 && !status && r.state==1,
            "second_original_request_admitted");
        uint64_t oldNonce=r.nonce,oldGeneration=ctx.sessionGeneration;
        CHECK(waitGateEntry(1000000000u),"second_worker_pending_at_cancellation");
        CjguiDrawableAcquireSlot *oldSlot=ctx.view.drawableAcquireSlot;
        cjgui_internal_renderer_preparation_operation_retire(token,302);
        (void)cjgui_internal_renderer_preparation_operation_poll(token,302,oldNonce,0,&r);
        CHECK(r.state==4 && !atomic_load(&gCjguiPreparationOwnedBytes),"pending_cancel_revokes_old_nonce_once");
        CHECK(cjgui_internal_renderer_destroy(token)==0,"close_while_acquisition_worker_holds_original_layer");
        CJGuiInternalSession *reopened=nil;uint64_t reopenedToken=0;
        CHECK(makeSession(&reopened,&reopenedToken) && reopenedToken==token && reopened.sessionGeneration!=oldGeneration,
            "same_slot_reopens_with_new_generation_before_late_completion");
        cjgui_internal_renderer_test_drawable_gate_open();uint64_t end=drawableNowNs()+2000000000u;
        while(oldSlot.state && drawableNowNs()<end)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.002,true);
        CHECK(!oldSlot.state && reopened.composableSceneVersion==1 && !reopened.view.drawableAcquireSlot &&
            !gCjguiPreparationAdvanceSlots[token-1].ticket.state,
            "late_original_drawable_cannot_mutate_reopened_session_or_publish_completion");
        (void)cjgui_internal_renderer_destroy(reopenedToken);
    } else (void)cjgui_internal_renderer_destroy(token);
    CHECK(!atomic_load(&gCjguiPreparationOwnedBytes),"owned_drawable_final_bytes_zero");
    return failures?1:0;
} }
