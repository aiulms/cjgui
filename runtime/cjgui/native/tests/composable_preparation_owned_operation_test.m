// The retained normal RED is owner1084ms / main-queue wait1065ms in
// runtime-converge7-mixed-overlap. Here a gate makes that queue hold exact.
#define main CjguiOwnedOperationPriorMain
#import "composable_preparation_batch_test.m"
#undef main

static CjguiInternalRendererPreparationOperationResult admitHeld(uint64_t token,
    uint64_t preparation, CjguiInternalRendererPreparationOperation *op, uint64_t deadline) {
    dispatch_semaphore_t entered=dispatch_semaphore_create(0), done=dispatch_semaphore_create(0);
    __block CjguiInternalRendererPreparationOperationResult result={0};
    __block CjguiInternalRendererStatus status=-1;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        dispatch_semaphore_signal(entered);
        status=cjgui_internal_renderer_preparation_operation_admit(token,preparation,deadline,op,&result);
        dispatch_semaphore_signal(done);
    });
    CHECK(dispatch_semaphore_wait(entered,dispatch_time(DISPATCH_TIME_NOW,1000000000))==0,
        "owner_entered_original_admission");
    BOOL returned=dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,16000000))==0;
    CHECK(returned,"admission_returns_while_original_main_service_is_held");
    if (!returned) {
        NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:2];
        while(dispatch_semaphore_wait(done,DISPATCH_TIME_NOW)!=0 && limit.timeIntervalSinceNow>0)
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    }
    CHECK(status==CJGUI_INTERNAL_RENDERER_OK,"admission_has_explicit_result");
    return result;
}
static CjguiInternalRendererPreparationOperationResult settle(uint64_t token,
    uint64_t preparation,uint64_t nonce,BOOL consume) {
    CjguiInternalRendererPreparationOperationResult r={0};
    NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:2];
    do {
        (void)cjgui_internal_renderer_preparation_operation_poll(token,preparation,nonce,0,&r);
        if(r.state!=CJGUI_PREPARATION_OPERATION_PENDING) break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    }while(limit.timeIntervalSinceNow>0);
    if(consume && r.state==CJGUI_PREPARATION_OPERATION_COMPLETED)
        (void)cjgui_internal_renderer_preparation_operation_poll(token,preparation,nonce,1,&r);
    return r;
}
static BOOL heldExecutingBytes, capacityDeclined, replacementAdmitted;
static uint64_t replacementNonce;
static CjguiInternalRendererPreparationOperation *heldLargeRequest;
static void ownedNodeGate(uint64_t token,uint64_t preparation,uint32_t prefix,uint64_t deadline) {
    if(prefix!=1)return;
    if(preparation==94) {
        dispatch_semaphore_t gate=dispatch_semaphore_create(0);uint64_t now=nowNs();
        if(now<=deadline)(void)dispatch_semaphore_wait(gate,dispatch_time(DISPATCH_TIME_NOW,deadline-now+1000000u));
    } else if(preparation==96) {
        dispatch_semaphore_t returned=dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            cjgui_internal_renderer_preparation_operation_retire(token,96);
            heldExecutingBytes=atomic_load(&gCjguiPreparationOwnedBytes)>0;
            CjguiInternalRendererPreparationOperationResult capacity={0};
            (void)cjgui_internal_renderer_preparation_operation_admit(token,98,nowNs()+1000000000u,heldLargeRequest,&capacity);
            capacityDeclined=capacity.state==CJGUI_PREPARATION_OPERATION_CAPACITY && capacity.requiredBytes>0;
            uint64_t values[32]={1,7,1};
            CjguiInternalRendererPreparationOperation begin={.kind=CJGUI_PREPARATION_OPERATION_BEGIN,.values32=values};
            CjguiInternalRendererPreparationOperationResult next={0};
            (void)cjgui_internal_renderer_preparation_operation_admit(token,97,nowNs()+1000000000u,&begin,&next);
            replacementAdmitted=next.state==CJGUI_PREPARATION_OPERATION_PENDING;
            replacementNonce=next.nonce;
            dispatch_semaphore_signal(returned);
        });
        CHECK(dispatch_semaphore_wait(returned,dispatch_time(DISPATCH_TIME_NOW,1000000000))==0,
            "executing_main_does_not_hold_mailbox_lock_against_retirement");
    }
}
#ifndef CJGUI_OWNED_OPERATION_SKIP_MAIN
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=nil;uint64_t token=0;if(!makeSession(&ctx,&token))return 2;
    gCjguiMainThreadDispatchEnabled=YES;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,91,1,2,1)==0,"original_private_candidate");
    CjguiInternalRendererComposableNode raw={0};raw.nodeId=201;raw.resourceId=2;
    raw.projectionVersion=2;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    raw.width=80;raw.height=32;raw.clipWidth=480;raw.clipHeight=320;raw.textAlpha=1;
    CjguiInternalRendererComposableGeometry geometry={0};geometry.nodeId=201;
    char body[]="original-body", help[]="original-help";
    const char *strings[9]={"label",body,"owned-button","binding","","","semantic-label","",help};
    CjguiInternalRendererPreparationOperation op={.kind=CJGUI_PREPARATION_OPERATION_DECLARE,
        .count=1,.nodes=&raw,.geometry=&geometry,.strings=strings,.stringCount=9};
    CjguiInternalRendererPreparationOperationResult r=admitHeld(token,91,&op,nowNs()+1000000000u);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_PENDING && r.prefix==0 && r.nonce,
        "queued_is_not_completed_or_copied");
    CHECK(ctx.composablePreparation.filled.count==0,"main_has_not_seen_borrowed_packet");
    // Destroy/change every borrowed category after admission; no queued call
    // is allowed to read these arrays, strings or caller output addresses.
    raw.nodeId=999;geometry.nodeId=999;memset(body,'x',sizeof(body)-1);memset(help,'y',sizeof(help)-1);
    for(NSUInteger i=0;i<9;i++)strings[i]="replaced";
    uint64_t nonce=r.nonce;
    for(NSUInteger i=0;i<8;i++) {
        (void)cjgui_internal_renderer_preparation_operation_poll(token,91,nonce,0,&r);
        CHECK(r.state==CJGUI_PREPARATION_OPERATION_PENDING && r.nonce==nonce && !r.prefix,
            "pending_poll_does_not_copy_renew_or_consume");
    }
    r=settle(token,91,nonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.stop==CJGUI_PREPARATION_STOP_COMPLETE &&
        r.status==0 && r.prefix==1,"actual_complete_prefix_consumed_once");
    CJGuiInternalComposableSceneNode *node=ctx.composablePreparation.nodes[0];
    CHECK(node.node.nodeId==201 && [node.value isEqualToString:@"original-body"] &&
        [node.semanticHelp isEqualToString:@"original-help"],"payload_and_help_are_owned_exactly");
    (void)cjgui_internal_renderer_preparation_operation_poll(token,91,nonce,1,&r);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_STALE && !r.prefix,"completion_cannot_be_consumed_twice");
    CHECK(ctx.composableSceneVersion==1 && ctx.composableNodes[0].node.nodeId==100,
        "private_completion_never_installs_candidate");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,91);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"consumed_payload_releases_real_byte_reservation");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,92,1,3,1)==0,"reuse_candidate");
    raw.nodeId=201;raw.projectionVersion=3;geometry.nodeId=201;
    const char *empty[9]={"","","","","","","","",""};
    op.kind=CJGUI_PREPARATION_OPERATION_REUSE;op.nodes=&raw;op.geometry=&geometry;op.strings=empty;
    r=admitHeld(token,92,&op,nowNs()+1000000000u);nonce=r.nonce;
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_PENDING && ctx.composablePreparation.filled.count==0,
        "pending_reuse_is_neither_cache_miss_nor_full_upload");
    r=settle(token,92,nonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.status==0 && !r.prefix &&
        r.stop==CJGUI_PREPARATION_STOP_CACHE_MISS && ctx.composablePreparation.filled.count==0,
        "actual_reuse_miss_is_explicit_without_full_fallback");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,92);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,93,1,4,1)==0,"expiry_candidate");
    raw.projectionVersion=4;op.kind=CJGUI_PREPARATION_OPERATION_DECLARE;
    uint64_t originalDeadline=nowNs()+50000000u;
    r=admitHeld(token,93,&op,originalDeadline);nonce=r.nonce;
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_PENDING,"original_deadline_queued_once");
    dispatch_semaphore_t held=dispatch_semaphore_create(0);
    uint64_t current=nowNs();
    if(current<=originalDeadline)
        (void)dispatch_semaphore_wait(held,dispatch_time(DISPATCH_TIME_NOW,originalDeadline-current+1000000u));
    CHECK(nowNs()>originalDeadline,"main_gate_passes_the_exact_original_deadline");
    r=settle(token,93,nonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.status==0 && !r.prefix &&
        r.stop==CJGUI_PREPARATION_STOP_DEADLINE && ctx.composablePreparation.filled.count==0,
        "expired_zero_prefix_is_not_a_cache_miss");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,93);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,94,1,5,2)==0,"partial_candidate");
    CjguiInternalRendererComposableNode pair[2]={raw,raw};
    CjguiInternalRendererComposableGeometry pairGeometry[2]={geometry,geometry};
    for(uint32_t i=0;i<2;i++){pair[i].nodeId=201+i;pair[i].projectionVersion=5;pairGeometry[i].nodeId=201+i;}
    const char *pairStrings[18]={"","a","a","","","","","","", "","b","b","","","","","",""};
    op=(CjguiInternalRendererPreparationOperation){.kind=CJGUI_PREPARATION_OPERATION_DECLARE,.count=2,
        .nodes=pair,.geometry=pairGeometry,.strings=pairStrings,.stringCount=18};
    gCjguiOwnedPreparationNodeCompletedTestHook=ownedNodeGate;
    r=admitHeld(token,94,&op,nowNs()+50000000u);nonce=r.nonce;
    r=settle(token,94,nonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.status==0 && r.prefix==1 &&
        r.stop==CJGUI_PREPARATION_STOP_DEADLINE && ctx.composablePreparation.filled.count==1,
        "expired_partial_prefix_is_exact_not_replayed");
    gCjguiOwnedPreparationNodeCompletedTestHook=NULL;
    op.firstIndex=1;op.count=1;op.nodes=pair+1;op.geometry=pairGeometry+1;op.strings=pairStrings+9;op.stringCount=9;
    r=admitHeld(token,94,&op,nowNs()+1000000000u);r=settle(token,94,r.nonce,YES);
    CHECK(r.status==0 && r.prefix==1 && ctx.composablePreparation.filled.count==2,
        "fresh_allowance_copies_only_uncompleted_suffix");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,94);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,95,1,5,1)==0,"queued_cancel_candidate");
    pair[0].projectionVersion=5;op.firstIndex=0;op.nodes=pair;op.geometry=pairGeometry;op.strings=pairStrings;
    r=admitHeld(token,95,&op,nowNs()+1000000000u);uint64_t cancelledNonce=r.nonce;
    cjgui_internal_renderer_preparation_operation_retire(token,95);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"queued_cancel_releases_slot_packet");
    (void)cjgui_internal_renderer_preparation_operation_poll(token,95,cancelledNonce,1,&r);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_STALE && !r.prefix,"cancelled_nonce_has_no_completion");
    uint64_t beginValues[32]={1,6,2};
    CjguiInternalRendererPreparationOperation begin={.kind=CJGUI_PREPARATION_OPERATION_BEGIN,.values32=beginValues};
    r=admitHeld(token,96,&begin,nowNs()+1000000000u);r=settle(token,96,r.nonce,YES);
    CHECK(r.status==0 && ctx.composablePreparation.preparationId==96,
        "replacement_begin_observes_ordered_actual_retirement");
    size_t payloadBytes=1792u*1024u;char *large=malloc(payloadBytes+1);memset(large,'z',payloadBytes);large[payloadBytes]=0;
    for(uint32_t i=0;i<2;i++){
        pair[i].projectionVersion=6;pair[i].nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
    }
    const char *largeStrings[18]={"",large,"a","","","","","","", "",large,"b","","","","","",""};
    op=(CjguiInternalRendererPreparationOperation){.kind=CJGUI_PREPARATION_OPERATION_DECLARE,.count=2,
        .nodes=pair,.geometry=pairGeometry,.strings=largeStrings,.stringCount=18};heldLargeRequest=&op;
    gCjguiOwnedPreparationNodeCompletedTestHook=ownedNodeGate;
    r=admitHeld(token,96,&op,nowNs()+1000000000u);cancelledNonce=r.nonce;
    NSDate *gateLimit=[NSDate dateWithTimeIntervalSinceNow:2];
    while(!replacementNonce && gateLimit.timeIntervalSinceNow>0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    gCjguiOwnedPreparationNodeCompletedTestHook=NULL;
    CHECK(heldExecutingBytes,"executing_service_keeps_its_independent_owned_reference");
    CHECK(capacityDeclined,"actual_inflight_bytes_bound_replacement_admission");
    CHECK(replacementAdmitted && replacementNonce,"small_replacement_uses_single_existing_service_wake");
    r=settle(token,97,replacementNonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.status==0 &&
        ctx.composablePreparation.preparationId==97,"late_old_service_cannot_publish_into_replacement");
    (void)cjgui_internal_renderer_preparation_operation_poll(token,96,cancelledNonce,1,&r);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_STALE,"executing_cancel_old_nonce_stays_stale");
    free(large);heldLargeRequest=NULL;
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"all_executing_and_completed_packet_bytes_released");
    pair[0].projectionVersion=7;pair[0].nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    op=(CjguiInternalRendererPreparationOperation){.kind=CJGUI_PREPARATION_OPERATION_DECLARE,.count=1,
        .nodes=pair,.geometry=pairGeometry,.strings=pairStrings,.stringCount=9};
    r=admitHeld(token,97,&op,nowNs()+1000000000u);
    uint64_t closedNonce=r.nonce, oldGeneration=ctx.sessionGeneration;
    (void)cjgui_internal_renderer_destroy(token);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"close_releases_queued_packet_before_same_slot_reuse");
    CJGuiInternalSession *reopened=nil;uint64_t reopenedToken=0;
    CHECK(makeSession(&reopened,&reopenedToken) && reopenedToken==token &&
        reopened.sessionGeneration!=oldGeneration,"actual_close_reopen_has_new_generation_in_same_slot");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,97,1,2,1)==0,"same_preparation_id_new_session");
    pair[0].projectionVersion=2;r=admitHeld(token,97,&op,nowNs()+1000000000u);uint64_t newNonce=r.nonce;
    (void)cjgui_internal_renderer_preparation_operation_poll(token,97,closedNonce,1,&r);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_STALE && !r.prefix,"old_generation_result_cannot_consume_new_slot");
    r=settle(token,97,newNonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.status==0 && r.prefix==1 &&
        reopened.composablePreparation.filled.count==1,"single_surviving_wake_serves_only_new_generation");
    cjgui_internal_renderer_preparation_operation_retire(token,97);
    uint64_t menuValues[32]={2,1};menuValues[16]=1;menuValues[17]=2;
    CjguiInternalRendererPreparationOperation menu={.kind=CJGUI_PREPARATION_OPERATION_COMMAND_BEGIN,.values32=menuValues};
    r=admitHeld(token,97,&menu,nowNs()+1000000000u);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_CAPACITY && !r.nonce,
        "same_candidate_fallback_waits_for_actual_old_graph_retirement");
    NSDate *retirementLimit=[NSDate dateWithTimeIntervalSinceNow:2];
    while(cjgui_internal_renderer_preparation_operation_waiting(token) && retirementLimit.timeIntervalSinceNow>0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    CHECK(!reopened.composablePreparation,"actual_private_graph_retired_before_fallback_menu");
    r=admitHeld(token,97,&menu,nowNs()+1000000000u);r=settle(token,97,r.nonce,YES);
    CHECK(r.state==CJGUI_PREPARATION_OPERATION_COMPLETED && r.status==0 &&
        reopened.stagedComposableCommandMenuVersion==2,"owned_menu_configure_works_after_real_resource_fallback");
    char commandId[]="owned-command", commandTitle[]="original-menu-title";
    const char *menuStrings[4]={commandId,commandTitle,"File","super+s"};
    memset(menuValues,0,sizeof(menuValues));menuValues[2]=1;menuValues[5]=123;
    menuValues[6]=100;menuValues[7]=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    menuValues[16]=1;menuValues[17]=2;int64_t menuSigned[32]={1};
    menu=(CjguiInternalRendererPreparationOperation){.kind=CJGUI_PREPARATION_OPERATION_COMMAND_ITEM,
        .values32=menuValues,.signedValues32=menuSigned,.strings=menuStrings,.stringCount=4};
    r=admitHeld(token,97,&menu,nowNs()+1000000000u);nonce=r.nonce;
    memset(commandId,'x',sizeof(commandId)-1);memset(commandTitle,'y',sizeof(commandTitle)-1);
    memset(menuValues,0,sizeof(menuValues));menuSigned[0]=-99;
    r=settle(token,97,nonce,YES);
    CJGuiInternalComposableCommandMenuItem *item=reopened.stagedComposableCommandMenuItems[0];
    CHECK(r.status==0 && [item.commandId isEqualToString:@"owned-command"] &&
        [item.title isEqualToString:@"original-menu-title"] && item.declarationToken==123 &&
        item.targetNodeId==100 && item.targetResourceId==1,
        "menu_strings_identity_and_policy_share_owned_ordered_operation");
    CHECK(reopened.composableSceneVersion==1,"staged_menu_does_not_publish_or_invoke_commands");
    gCjguiOwnedPreparationAllocationFailureTest=YES;
    uint64_t allocationWords[32]={1,3,1};
    CjguiInternalRendererPreparationOperation allocationRequest={.kind=CJGUI_PREPARATION_OPERATION_BEGIN,.values32=allocationWords};
    CjguiInternalRendererPreparationOperationResult allocationResult={0};
    CjguiInternalRendererStatus allocationStatus=cjgui_internal_renderer_preparation_operation_admit(token,98,
        nowNs()+1000000000u,&allocationRequest,&allocationResult);
    gCjguiOwnedPreparationAllocationFailureTest=NO;
    CHECK(allocationStatus==CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
        atomic_load(&gCjguiPreparationOwnedBytes)==0 && !allocationResult.nonce,
        "allocation_failure_releases_reservation_without_publishing_ticket");
    (void)cjgui_internal_renderer_destroy(token);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"real_final_transport_bytes_zero");
    return failures?1:0;
}}
#endif
