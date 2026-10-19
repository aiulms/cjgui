// The real production preparation/mailbox with a caller-owned allowance.
// No displayed scene, proxy, source ticket or input is fabricated by this test.
#define main CjguiContinuationBatchFixtureMain
#import "composable_preparation_batch_test.m"
#undef main

static CjguiPreparationAdvanceTicket continuationTicket(uint64_t session, BOOL *scheduled) {
    pthread_mutex_lock(&gCjguiPreparationAdvanceLock);
    CjguiPreparationAdvanceSlot value=gCjguiPreparationAdvanceSlots[session-1];
    pthread_mutex_unlock(&gCjguiPreparationAdvanceLock);
    if (scheduled) *scheduled=value.serviceScheduled;
    return value.ticket;
}
static BOOL continuationService(uint64_t session) {
    NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:2];
    BOOL scheduled=NO;
    while ((continuationTicket(session,&scheduled),scheduled) && limit.timeIntervalSinceNow>0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    return !scheduled;
}
static BOOL continuationCall(uint64_t session,uint64_t preparation,uint64_t deadline,
    CjguiInternalRendererStatus *status,uint32_t *ready) {
    dispatch_semaphore_t done=dispatch_semaphore_create(0);
    __block CjguiInternalRendererStatus result=-1;
    __block uint32_t resultReady=UINT32_MAX;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        result=cjgui_internal_renderer_advance_composable_preparation(session,preparation,deadline,&resultReady);
        dispatch_semaphore_signal(done);
    });
    if (dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,16000000))!=0) return NO;
    *status=result;*ready=resultReady;return YES;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    if (!makeSession(&ctx,&token)) return 2;
    gCjguiMainThreadDispatchEnabled=YES;
    NSArray *accepted=ctx.composableNodes;
    CjguiInternalRendererStatus status=-1;uint32_t ready=UINT32_MAX;
    // 600 real nodes exceed the unchanged maximum256 private units. A
    // successful original service must still have actual work left to do.
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,20,1,2,600)==0 &&
        fillButtons(token,20,2,600)==0,"real_detached_graph_exceeds_one_bounded_service");
    CHECK(continuationCall(token,20,nowNs()+100000000,&status,&ready) && status==0 && !ready,
        "original_owner_advance_nonblocking");
    CjguiPreparationAdvanceTicket original=continuationTicket(token,NULL);
    CHECK(continuationService(token),"original_main_service_completed");
    CjguiPreparationAdvanceTicket completed=continuationTicket(token,NULL);
    NSUInteger before=ctx.composablePreparation.nodeCursor;
    CHECK(completed.state==2 && completed.nonce==original.nonce && completed.status==0 &&
        !completed.ready && before>0 && !ctx.composablePreparation.ready,
        "original_completion_proves_real_progress_not_ready");
    uint64_t callerDeadline=nowNs()+100000000;
    CHECK(continuationCall(token,20,callerDeadline,&status,&ready) && status==0 && !ready,
        "consume_original_in_next_actual_owner_call");
    BOOL scheduled=NO;
    CjguiPreparationAdvanceTicket next=continuationTicket(token,&scheduled);
    CHECK(next.state==1 && scheduled && next.nonce!=original.nonce && next.preparationId==20 &&
        next.generation==original.generation && next.deadlineNs==callerDeadline,
        "unfinished_progress_continues_in_same_call_without_empty_owner_round");
    if (next.state==1) {
        for (NSUInteger i=0;i<4;i++) {
            CHECK(continuationCall(token,20,nowNs()+200000000,&status,&ready) && status==0 && !ready &&
                continuationTicket(token,NULL).nonce==next.nonce &&
                continuationTicket(token,NULL).deadlineNs==callerDeadline,
                "pending_continuation_never_renews_original_deadline_or_resubmits");
        }
        CHECK(continuationService(token) && ctx.composablePreparation.nodeCursor>before,
            "continuation_wake_makes_actual_private_progress");
        // This new call has no remaining allowance. It may take the result
        // but cannot create a fresh wake, extend the old deadline or do work.
        NSUInteger observed=ctx.composablePreparation.nodeCursor;
        CHECK(continuationCall(token,20,nowNs(),&status,&ready) && status==0 && !ready &&
            continuationTicket(token,&scheduled).state==0 && !scheduled &&
            ctx.composablePreparation.nodeCursor==observed,
            "expired_new_allowance_consumes_once_without_empty_work_or_renewal");
    }
    CHECK(ctx.composableNodes==accepted && ctx.composableSceneVersion==1,
        "private_continuation_does_not_install_or_present");
    BOOL actualReady=NO;
    // The first fixture failure also occurs with the original mailbox: eight
    // fast owner observations finish before a cold real pipeline compiler.
    // Wait for that compiler's actual completion, without setting ready or
    // extending any queued advance ticket. This is fixture initialization,
    // not a delay/retry inserted into a normal input/performance sequence.
    NSDate *pipelineLimit=[NSDate dateWithTimeIntervalSinceNow:4];
    while (ctx.composablePreparation.frameResourcePipelines &&
        (ctx.composablePreparation.frameResourcePipelines.completedRoles &
            ctx.composablePreparation.frameResourceRoles)!=ctx.composablePreparation.frameResourceRoles &&
        !ctx.composablePreparation.frameResourcePipelines.failed && pipelineLimit.timeIntervalSinceNow>0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    CHECK(ctx.composablePreparation.frameResourcePipelines &&
        !ctx.composablePreparation.frameResourcePipelines.failed &&
        (ctx.composablePreparation.frameResourcePipelines.completedRoles &
            ctx.composablePreparation.frameResourceRoles)==ctx.composablePreparation.frameResourceRoles,
        "actual_pipeline_completion_before_ready_terminal_control");
    for (NSUInteger i=0;i<8 && !actualReady;i++) {
        CHECK(continuationCall(token,20,nowNs()+100000000,&status,&ready) && status==0 &&
            continuationService(token),"finite_original_steps_finish_private_resources");
        actualReady=continuationTicket(token,NULL).ready==1;
    }
    CHECK(actualReady && continuationCall(token,20,nowNs()+100000000,&status,&ready) && status==0 &&
        ready==1 && continuationTicket(token,&scheduled).state==0 && !scheduled,
        "actual_ready_completion_is_terminal_without_another_service");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,20)==0 &&
        continuationService(token),"cancel_retires_original_private_graph_and_wake");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,21,1,3,600)==0 &&
        fillButtons(token,21,3,600)==0 &&
        continuationCall(token,21,nowNs()+100000000,&status,&ready) && continuationService(token),
        "next_real_candidate_has_productive_unfinished_result");
    CHECK(continuationCall(token,21,nowNs()+100000000,&status,&ready) && status==0 && !ready &&
        continuationTicket(token,&scheduled).state==1 && scheduled,
        "next_candidate_has_one_continuation_wake");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,21)==0 &&
        continuationTicket(token,NULL).state==0 && continuationService(token) &&
        continuationTicket(token,&scheduled).state==0 && !scheduled,
        "cancelled_continuation_cannot_publish_or_keep_a_wake");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,22,1,4,1)==0 &&
        continuationCall(token,22,nowNs()+100000000,&status,&ready) && continuationService(token),
        "real_unfilled_producer_refusal");
    CHECK(continuationCall(token,22,nowNs()+100000000,&status,&ready) && status!=0 && !ready &&
        continuationTicket(token,&scheduled).state==0 && !scheduled,
        "failed_completion_is_returned_once_without_continuation");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,22);
    (void)cjgui_internal_renderer_destroy(token);
    fprintf(stderr,"PREPARATION_CONTINUATION failures=%d original_cursor=%lu\n",failures,(unsigned long)before);
    return failures?1:0;
} }
