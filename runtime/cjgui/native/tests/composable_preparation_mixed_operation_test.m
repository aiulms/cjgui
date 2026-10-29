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
    CjguiReleaseSession(token);
    fprintf(stderr,"mixed_owned failures=%d\n",failures);return failures?1:0;
} }
