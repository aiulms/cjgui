// Actual owner mailbox + real blocked TextKit worker. A resource wait must not
// manufacture completed empty steps and wake its own owner indefinitely.
#define CJGUI_PREPARATION_OWNER_QUEUE_HELPERS_ONLY 1
#import "composable_preparation_owner_queue_test.m"
#undef CJGUI_PREPARATION_OWNER_QUEUE_HELPERS_ONLY

static BOOL waitForMailbox(uint64_t token, uint32_t state, double seconds) {
    NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:seconds];
    while (queueTicket(token,NULL).state!=state && limit.timeIntervalSinceNow>0)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.001,true);
    return queueTicket(token,NULL).state==state;
}
static BOOL warmWaitPipelines(CJGuiInternalSession *ctx,uint64_t token) {
    if(cjgui_internal_renderer_begin_composable_preparation(token,30,1,2,1)!=0 || fillButtons(token,30,2,1)!=0)return NO;
    uint32_t ready=0;
    NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:3];
    while(!ready && limit.timeIntervalSinceNow>0) {
        if(cjgui_internal_renderer_advance_composable_preparation(token,30,0,&ready)!=0)return NO;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.001,true);
    }
    return ready && cjgui_internal_renderer_cancel_composable_preparation(token,30)==0;
}
static BOOL enterBlockedText(CJGuiInternalSession *ctx,uint64_t token,uint64_t request,NSString *body) {
    if(cjgui_internal_renderer_begin_composable_preparation(token,request,1,request,1)!=0 ||
        fillCold(token,request,request,body)!=0)return NO;
    CjguiTextPreparationTestCloseWorkerGate();
    CjguiInternalRendererStatus status=-1;uint32_t ready=UINT32_MAX;
    if(!ownerAdvance(token,request,nowNs()+100000000u,&status,&ready) || status!=0 || ready)return NO;
    if(!drainQueueService(token))return NO;
    return CjguiTextPreparationTestWaitForWorkerGate(1000);
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    if(!makeSession(&ctx,&token))return 2;
    gCjguiMainThreadDispatchEnabled=YES;
    CHECK(warmWaitPipelines(ctx,token),"real_pipelines_warmed_before_blocked_worker_counterexample");
    NSMutableString *body=[NSMutableString string];
    for(NSUInteger i=0;i<256;i++)[body appendString:@"真实中文 owner pending 👩🏽‍💻\n"];
    CHECK(enterBlockedText(ctx,token,31,body),"real_native_text_worker_is_held");
    CjguiPreparationAdvanceTicket held=queueTicket(token,NULL);
    BOOL scheduled=YES;queueTicket(token,&scheduled);
    CHECK(held.state==1 && !scheduled && !held.ready,"resource_pending_is_retained_not_empty_completion");
    uint64_t before=cjgui_internal_renderer_owner_work_revision();
    CjguiInternalRendererStatus status=-1;uint32_t ready=UINT32_MAX;
    for(NSUInteger i=0;i<4;i++) {
        CHECK(ownerAdvance(token,31,nowNs()+200000000u,&status,&ready) && status==0 && !ready,
            "pending_observation_is_nonblocking");
        CHECK(drainQueueService(token),"no_repeated_pending_service");
        CjguiPreparationAdvanceTicket same=queueTicket(token,&scheduled);
        CHECK(same.state==1 && same.nonce==held.nonce && same.deadlineNs==held.deadlineNs && !scheduled,
            "pending_keeps_one_nonce_deadline_and_no_queued_service");
    }
    uint64_t after=cjgui_internal_renderer_owner_work_revision();
    CHECK(after==before,"pending_observations_do_not_wake_the_owner");
    fprintf(stderr,"PREPARATION_PENDING held_state=%u nonce=%llu revision_before=%llu revision_after=%llu\n",
        held.state,(unsigned long long)held.nonce,(unsigned long long)before,(unsigned long long)after);
    CjguiTextPreparationTestOpenWorkerGate();
    CHECK(waitForMailbox(token,2,3),"actual_worker_completion_wakes_existing_pending_mailbox");
    CHECK(queueTicket(token,NULL).nonce==held.nonce,"completion_does_not_replace_original_pending_ticket");
    CHECK(ctx.composableSceneVersion==1,"private_ready_never_publishes_without_owner_acceptance");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,31);
    CHECK(enterBlockedText(ctx,token,32,[@"second " stringByAppendingString:body]),"second_real_worker_held_for_cancel");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,32)==0 && queueTicket(token,NULL).state==0,
        "cancel_retires_held_resource_ticket");
    CjguiTextPreparationTestOpenWorkerGate();
    CHECK(CjguiTextPreparationTestWaitForFinished(3000) && drainQueueService(token) && queueTicket(token,&scheduled).state==0 && !scheduled,
        "late_worker_wake_does_not_resurrect_retired_ticket");
    (void)cjgui_internal_renderer_destroy(token);
    fprintf(stderr,"PREPARATION_WAIT_WAKE failures=%d\n",failures);
    return failures?1:0;
} }
