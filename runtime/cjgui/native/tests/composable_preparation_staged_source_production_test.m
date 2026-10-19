#define main existingSelectionPaintProductionMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx=ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx!=nil,"staged_source_real_active_A");if(!ctx)return 1;
    uint64_t session=ctx.rendererSessionToken;
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    NSAttributedString *before=[o.inputProxy.textStorage copy];
    uint64_t generation=o.activeTextAttributedGeneration;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(session,145,1,2,3)==0,
        "staged_source_begin_frozen_A_real_preparation");
    const char *runs="0:13:14:600:0:1:0:0:1:0:0:0:0:0";
    for(uint32_t i=0;i<3;i++) {
        CjguiInternalRendererComposableNode raw=ctx.composableNodes[i].node;raw.projectionVersion=2;
        CjguiInternalRendererComposableGeometry geometry=ctx.composableNodes[i].geometry;
        geometry.nodeId=raw.nodeId;
        const char *value=i==0?"ACHAFTERabcde":ctx.composableNodes[i].value.UTF8String;
        CHECK(cjgui_internal_renderer_prepare_composable_node(session,145,i,&raw,&geometry,
            "",value,"","","","","",i==0?runs:"")==0,"staged_source_B_nodes_private");
    }
    uint32_t ready=0;uint64_t end=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(2000000000);
    while(!ready && cjgui_internal_renderer_owner_clock_ns()<end) {
        int advance=cjgui_internal_renderer_advance_composable_preparation(session,145,0,&ready);
        CHECK(advance==0,"staged_source_real_private_work_advances");if(advance!=0)break;
        if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.005,true);
    }
    CHECK(ready && [o.inputProxy.textStorage isEqualToAttributedString:before] &&
        o.activeTextAttributedGeneration==generation,"staged_source_ready_still_preserves_A");
    CHECK(cjgui_internal_renderer_configure_composable_scene(session,2,3)==0,
        "staged_source_configure_original_submit_order");
    CjguiComposablePreparation *p=ctx.composablePreparation;
    for(NSNumber *key in p.runs)
        CHECK(cjgui_internal_renderer_set_composable_text_runs(session,key.longLongValue,p.runs[key].UTF8String)==0,
            "staged_source_original_candidate_runs_transport");
    CHECK([o.inputProxy.textStorage isEqualToAttributedString:before] &&
        o.activeTextAttributedGeneration==generation,"staged_source_transport_cannot_restyle_accepted_A");
    CHECK([[o activeTextRunsSignatureForNode:ctx.composableNodes[0]] isEqualToString:@""],
        "staged_source_accepted_reader_never_borrows_B_transport_runs");
    int status=cjgui_internal_renderer_promote_composable_preparation(session,145);
    fprintf(stderr,"STAGED_SOURCE_PROMOTE status=%d old_attributes=%llu actual_attributes=%llu\n",status,
        (unsigned long long)generation,(unsigned long long)o.activeTextAttributedGeneration);
    CHECK(status==0,"staged_source_same_ticket_promotes_without_self_retirement");
    if(ctx.composablePreparation)cjgui_internal_renderer_cancel_composable_preparation(session,145);
    CjguiReleaseSession(session);return failures?1:0;
} }
