// The original166-node refresh split into103 declarations. One bounded owned
// packet must resolve per-node reuse and true misses without another owner trip.
#define CJGUI_OWNED_OPERATION_SKIP_MAIN 1
#import "composable_preparation_owned_operation_test.m"

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=nil;uint64_t token=0;if(!makeSession(&ctx,&token))return 2;
    gCjguiMainThreadDispatchEnabled=YES;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,201,1,2,8)==0,"mixed_candidate");
    CjguiInternalRendererComposableNode nodes[8];CjguiInternalRendererComposableGeometry geometry[8]={0};
    char values[8][32];const char *strings[72];uint64_t words[32]={0xAA};
    for(unsigned n=0;n<8;n++) {
        nodes[n]=ctx.composableNodes[0].node;nodes[n].nodeId=100+n;nodes[n].resourceId=1+n;
        nodes[n].projectionVersion=2;geometry[n].nodeId=100+n;
        snprintf(values[n],sizeof(values[n]),n?"new-%u":"accepted",n);
        for(unsigned s=0;s<9;s++)strings[n*9+s]="";
        strings[n*9+1]=values[n];strings[n*9+2]="mixed-node";
    }
    // Kind9 is the internal mixed declaration contract. A literal keeps RED a
    // runtime admission failure rather than a missing-enum compilation failure.
    CjguiInternalRendererPreparationOperation op={.kind=9,.count=8,.nodes=nodes,
        .geometry=geometry,.strings=strings,.stringCount=72,.values32=words};
    CjguiInternalRendererPreparationOperationResult r=admitHeld(token,201,&op,nowNs()+1000000000u);
    CHECK(r.state==1 && r.nonce && !r.prefix,"one_mixed_packet_admitted_without_main_service");
    if (r.state==1) {
        uint64_t nonce=r.nonce;
        words[0]=0xFF;for(unsigned n=0;n<8;n++){nodes[n].nodeId=999;memset(values[n],'x',8);}
        r=settle(token,201,nonce,YES);
        CHECK(r.state==2 && r.status==0 && r.stop==0 && r.prefix==8,
            "mixed_hits_and_true_misses_finish_in_one_owned_result");
        CHECK(ctx.composablePreparation.filled.count==8 && ctx.composablePreparation.declarationReusedCount==1,
            "actual_reuse_retained_and_misses_declared_without_replaying_prefix");
        BOOL exact=YES;for(unsigned n=0;n<8;n++) {
            NSString *expected=n?[NSString stringWithFormat:@"new-%u",n]:@"accepted";
            exact=exact && ctx.composablePreparation.nodes[n].node.nodeId==100+n &&
                [ctx.composablePreparation.nodes[n].value isEqualToString:expected];
        }
        CHECK(exact,"caller_nodes_strings_and_mode_mask_are_owned_exactly");
        (void)cjgui_internal_renderer_preparation_operation_poll(token,201,nonce,1,&r);
        CHECK(r.state==4 && !r.prefix,"mixed_result_consumed_once");
    }
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,201);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"mixed_payload_released");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,94,1,3,8)==0,"mixed_deadline_candidate");
    for(unsigned n=0;n<8;n++){nodes[n]=ctx.composableNodes[0].node;nodes[n].nodeId=200+n;
        nodes[n].resourceId=1+n;nodes[n].projectionVersion=3;geometry[n].nodeId=200+n;
        snprintf(values[n],sizeof(values[n]),"deadline-%u",n);}
    words[0]=0; // All true misses, requiring the complete declaration in-place.
    gCjguiOwnedPreparationNodeCompletedTestHook=ownedNodeGate;
    r=admitHeld(token,94,&op,nowNs()+30000000u);
    if(r.state==1)r=settle(token,94,r.nonce,YES);
    CHECK(r.state==2 && r.status==0 && r.stop==2 && r.prefix==1 && ctx.composablePreparation.filled.count==1,
        "mixed_deadline_returns_actual_prefix_without_treating_expiry_as_miss");
    gCjguiOwnedPreparationNodeCompletedTestHook=NULL;
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,94);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"mixed_deadline_payload_released");

    // Sixteen real nodes must complete in one owned round trip, including a
    // real reuse and true misses. Admission alone is not the performance or
    // correctness assertion: inspect all accepted copied values and release.
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,301,1,4,16)==0,"wide_candidate");
    CjguiInternalRendererComposableNode wideNodes[16];
    CjguiInternalRendererComposableGeometry wideGeometry[16]={0};
    char wideValues[16][32]; const char *wideStrings[144]; uint64_t wideWords[32]={0xAAAA};
    for(unsigned n=0;n<16;n++) {
        wideNodes[n]=ctx.composableNodes[0].node; wideNodes[n].nodeId=100+n;
        wideNodes[n].resourceId=1+n; wideNodes[n].projectionVersion=4; wideGeometry[n].nodeId=100+n;
        snprintf(wideValues[n],sizeof(wideValues[n]),n?"wide-%u":"accepted",n);
        for(unsigned s=0;s<9;s++)wideStrings[n*9+s]="";
        wideStrings[n*9+1]=wideValues[n];wideStrings[n*9+2]="mixed-node";
    }
    CjguiInternalRendererPreparationOperation wide={.kind=9,.count=16,.nodes=wideNodes,
        .geometry=wideGeometry,.strings=wideStrings,.stringCount=144,.values32=wideWords};
    r=admitHeld(token,301,&wide,nowNs()+1000000000u);
    BOOL oneTrip=r.state==1 && r.nonce && !r.prefix;
    if(oneTrip) {
        uint64_t nonce=r.nonce;wideWords[0]=0xffff;
        for(unsigned n=0;n<16;n++){wideNodes[n].nodeId=999;memset(wideValues[n],'x',8);}
        r=settle(token,301,nonce,YES);
        BOOL exact=r.state==2 && r.status==0 && r.stop==0 && r.prefix==16 &&
            ctx.composablePreparation.filled.count==16 && ctx.composablePreparation.declarationReusedCount==1;
        for(unsigned n=0;n<16;n++) {
            NSString *expected=n?[NSString stringWithFormat:@"wide-%u",n]:@"accepted";
            exact=exact && ctx.composablePreparation.nodes[n].node.nodeId==100+n &&
                [ctx.composablePreparation.nodes[n].value isEqualToString:expected];
        }
        oneTrip=exact;
        (void)cjgui_internal_renderer_preparation_operation_poll(token,301,nonce,1,&r);
        CHECK(r.state==4 && !r.prefix,"wide_result_consumed_once");
    }
    CHECK(oneTrip,"sixteen_actual_mixed_nodes_one_owned_round_trip");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,301);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"wide_payload_released");

    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,94,1,5,16)==0,"wide_deadline_candidate");
    for(unsigned n=0;n<16;n++) {
        wideNodes[n]=ctx.composableNodes[0].node;wideNodes[n].nodeId=300+n;
        wideNodes[n].resourceId=1+n;wideNodes[n].projectionVersion=5;wideGeometry[n].nodeId=300+n;
        snprintf(wideValues[n],sizeof(wideValues[n]),"limit-%u",n);
    }
    wideWords[0]=0;gCjguiOwnedPreparationNodeCompletedTestHook=ownedNodeGate;
    r=admitHeld(token,94,&wide,nowNs()+30000000u);
    if(r.state==1)r=settle(token,94,r.nonce,YES);
    CHECK(r.state==2 && r.status==0 && r.stop==2 && r.prefix==1 &&
        ctx.composablePreparation.filled.count==1,"wide_deadline_exact_prefix_and_original_allowance");
    gCjguiOwnedPreparationNodeCompletedTestHook=NULL;
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,94);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"wide_deadline_payload_released");

    CjguiInternalRendererPreparationOperation tooWide=wide;
    tooWide.count=17;tooWide.stringCount=153;
    CjguiInternalRendererPreparationOperationResult rejected={0};
    CjguiInternalRendererStatus rejectedStatus=cjgui_internal_renderer_preparation_operation_admit(
        token,302,nowNs()+1000000000u,&tooWide,&rejected);
    CHECK(rejectedStatus!=CJGUI_INTERNAL_RENDERER_OK && atomic_load(&gCjguiPreparationOwnedBytes)==0,
        "seventeen_nodes_rejected_without_lease");

    // The unchanged owned-byte ceiling rejects an oversized wide request
    // before it acquires a lease or changes the preparation.
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,303,1,6,16)==0,"byte_limit_candidate");
    char *large=malloc(300001);memset(large,'x',300000);large[300000]=0;
    for(unsigned n=0;n<16;n++) {
        wideNodes[n]=ctx.composableNodes[0].node;wideNodes[n].nodeId=400+n;
        wideNodes[n].resourceId=1+n;wideNodes[n].projectionVersion=6;wideGeometry[n].nodeId=400+n;
        wideStrings[n*9+1]=large;
    }
    wideWords[0]=0xffff;
    r=(CjguiInternalRendererPreparationOperationResult){0};
    CjguiInternalRendererStatus wideStatus=cjgui_internal_renderer_preparation_operation_admit(
        token,303,nowNs()+1000000000u,&wide,&r);
    CHECK(wideStatus==CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED &&
        ctx.composablePreparation.filled.count==0 && atomic_load(&gCjguiPreparationOwnedBytes)==0,
        "wide_byte_rejection_has_no_effect_or_lease");
    free(large);
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,303);
    CHECK(atomic_load(&gCjguiPreparationOwnedBytes)==0,"byte_limit_payload_released");
    CjguiReleaseSession(token);
    fprintf(stderr,"mixed_owned failures=%d\n",failures);return failures?1:0;
} }
