// A warm native text-field edit must discover the existing unsupported active
// source before rasterizing unrelated private candidate nodes. Reuse the real
// accepted scene/proxy/Metal fixture; no source credential or status is forged.
#define main activePreflightPreviousFixtureMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

static BOOL PreflightSubmitField(CJGuiInternalSession *ctx) {
    if(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken,2,1)!=0)return NO;
    CJGuiInternalComposableSceneNode *n=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[0],0,2);
    CjguiInternalRendererComposableNode raw=n.node;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    raw.projectionVersion=2;raw.x=20;raw.y=100;raw.width=424;raw.height=40;
    raw.clipX=20;raw.clipY=100;raw.clipWidth=424;raw.clipHeight=40;
    raw.fontSize=13;raw.textAlpha=1;raw.isInteractive=1;raw.preservesActiveLocalText=0;
    n.node=raw;n.value=@"Seed Ω";n.label=@"Name";ctx.stagedComposableNodes[0]=n;
    if(CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken)!=0)return NO;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];return YES;
}

static CJGuiInternalSession *PreflightFixture(uint64_t preparation, BOOL fillActive, BOOL includeActive) {
    CJGuiInternalSession *ctx=ProductionFixture(MTLCreateSystemDefaultDevice());
    if(!ctx)return nil;
    ctx.ownedTextSessionEnabled=NO;ctx.rangeTextEditDeltaDeliveryEnabled=NO;
    if(!PreflightSubmitField(ctx))return nil;
    if(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken,3,2)!=0)return nil;
    CJGuiInternalComposableSceneNode *active=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[0],1,3);
    CjguiInternalRendererComposableNode a=active.node;a.projectionVersion=3;active.node=a;
    CJGuiInternalComposableSceneNode *prefix=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};raw.nodeId=900;raw.resourceId=90;raw.projectionVersion=3;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;raw.x=20;raw.y=20;raw.width=400;raw.height=40;
    raw.clipX=20;raw.clipY=20;raw.clipWidth=400;raw.clipHeight=40;raw.fontSize=13;raw.textAlpha=1;
    prefix.node=raw;prefix.index=0;prefix.value=@"unchanged accepted prefix";prefix.styleRunsSignature=@"";
    ctx.stagedComposableNodes[0]=prefix;ctx.stagedComposableNodes[1]=active;
    if(CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken)!=0)return nil;
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    [o setNodesFromProjection:ctx.view.composableNodes];
    if(![o focusCommittedNodeId:401])return nil;
    [o.inputProxy insertText:@"1" replacementRange:NSMakeRange(o.inputProxy.string.length,0)];
    if(![o.inputProxy.string isEqualToString:@"Seed Ω1"])return nil;
    if(cjgui_internal_renderer_begin_composable_preparation(ctx.rendererSessionToken,preparation,3,4,2)!=0)return nil;
    for(uint32_t i=0;i<(fillActive?2u:1u);i++) {
        CJGuiInternalComposableSceneNode *accepted=ctx.composableNodes[i];
        CjguiInternalRendererComposableNode n=accepted.node;n.projectionVersion=4;
        CjguiInternalRendererComposableGeometry g=accepted.geometry;g.nodeId=n.nodeId;
        const char *value=i==0?"changed private prefix":o.inputProxy.string.UTF8String;
        if(i==1 && !includeActive){n.nodeId=901;n.resourceId=91;n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;n.isInteractive=0;g.nodeId=n.nodeId;value="replacement, no focused input";}
        if(cjgui_internal_renderer_prepare_composable_node(ctx.rendererSessionToken,preparation,i,&n,&g,
            accepted.label.UTF8String,value,"","","","","","")!=0)return nil;
    }
    // Prepare only the existing frame descriptor/pipeline proof, never a node.
    // Main-queue compiler completion is serviced without displaying a window.
    if(fillActive){uint64_t end=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(5000000000);uint32_t ready=0;
        while(!ready && cjgui_internal_renderer_owner_clock_ns()<end){
            if(CjguiPrepareCandidateFrameResourcesOnMain(ctx,ctx.composablePreparation,end,&ready)!=0)return nil;
            if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.002,true);
        }
        if(!ready)return nil;
    }
    return ctx;
}

static void PreflightRelease(CJGuiInternalSession *ctx,uint64_t preparation){
    if(!ctx)return;
    if(ctx.composablePreparation)(void)CjguiCancelComposablePreparationOnMain(ctx.rendererSessionToken,preparation);
    (void)CjguiDrainComposableRetirement(ctx,0);
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static void PreflightEarlyRefusal(void){
    const uint64_t prepId=700;CJGuiInternalSession *ctx=PreflightFixture(prepId,YES,YES);
    CHECK(ctx!=nil,"preflight_real_warm_native_edit_fixture");if(!ctx)return;
    CjguiComposablePreparation *p=ctx.composablePreparation;
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    const char *reason=CjguiPreparationActiveNodeReuseRefusal(ctx,p.nodes[1],@"",p.scale);
    CHECK(reason && !strcmp(reason,"active_raster_source_changed"),"preflight_exact_production_refusal");
    NSArray *accepted=[ctx.composableNodes copy];id prefixTexture=p.nodes[0].textTexture;id prefixLayout=p.nodes[0].preparedTextLayout;
    NSAttributedString *body=[o.inputProxy.textStorage copy];NSRange selected=o.inputProxy.selectedRange,marked=o.inputProxy.markedRange;
    uint64_t rasters=ctx.view.textRasterCount,uploads=ctx.view.textUploadCount;
    uint32_t ready=99;int status=CjguiAdvanceComposablePreparationOnMain(ctx.rendererSessionToken,prepId,
        cjgui_internal_renderer_owner_clock_ns()+UINT64_C(100000000),&ready);
    fprintf(stderr,"PREFLIGHT_COST status=%d ready=%u cursor=%lu phase=%lu raster_delta=%llu upload_delta=%llu\n",
        status,ready,(unsigned long)p.nodeCursor,(unsigned long)p.phase,
        (unsigned long long)(ctx.view.textRasterCount-rasters),(unsigned long long)(ctx.view.textUploadCount-uploads));
    CHECK(status==CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED && !ready && p.nodeCursor==0 && p.phase==0 &&
        p.nodes[0].textTexture==prefixTexture && p.nodes[0].preparedTextLayout==prefixLayout &&
        ctx.view.textRasterCount==rasters && ctx.view.textUploadCount==uploads,
        "known_unsupported_refuses_before_any_private_prefix_work");
    CHECK([ctx.composableNodes isEqualToArray:accepted] && ctx.composableSceneVersion==3 &&
        [o.inputProxy.textStorage isEqualToAttributedString:body] && NSEqualRanges(selected,o.inputProxy.selectedRange) &&
        NSEqualRanges(marked,o.inputProxy.markedRange) && CjguiPreparationNativeSourceMatches(ctx,p),
        "early_refusal_preserves_accepted_proxy_selection_marked_and_source");
    CHECK(CjguiCancelComposablePreparationOnMain(ctx.rendererSessionToken,prepId)==0 && !ctx.composablePreparation &&
        [ctx.composableNodes isEqualToArray:accepted] && [o.inputProxy.textStorage isEqualToAttributedString:body],
        "original_cancel_keeps_accepted_resources_and_body");
    CHECK(CjguiDrainComposableRetirement(ctx,0) && ctx.retiringComposablePreparations.count==0,
        "original_bounded_retirement_finishes");
    PreflightRelease(ctx,prepId);
}

static void PreflightGuards(void){
    for(int scenario=0;scenario<8;scenario++){
        uint64_t prepId=710+(uint64_t)scenario;BOOL filled=scenario!=5;BOOL active=scenario!=7;
        CJGuiInternalSession *ctx=PreflightFixture(prepId,filled,active);
        CHECK(ctx!=nil,"preflight_guard_real_fixture");if(!ctx)continue;
        CjguiComposablePreparation *p=ctx.composablePreparation;CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
        uint32_t ready=99;uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(100000000);
        int expected=CJGUI_INTERNAL_RENDERER_SCENE_STALE;const char *name="";
        switch(scenario){
            case 0:deadline=0;expected=0;name="zero_deadline_retains_original_one_unit_contract";break;
            case 1:deadline=cjgui_internal_renderer_owner_clock_ns();expected=0;name="expired_allowance_precedes_preflight";break;
            case 2:[o.inputProxy insertText:@"2" replacementRange:NSMakeRange(o.inputProxy.string.length,0)];name="body_change_still_rejects_source_first";break;
            case 3:[o.inputProxy setSelectedRange:NSMakeRange(0,1)];name="selection_change_still_rejects_source_first";break;
            case 4:[o.inputProxy setMarkedText:@"n" selectedRange:NSMakeRange(1,0) replacementRange:NSMakeRange(o.inputProxy.string.length,0)];name="marked_change_still_rejects_source_first";break;
            case 5:expected=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;name="unfilled_declarations_keep_original_error";break;
            case 6:ctx.view.invalidated=YES;name="invalid_frame_keeps_original_error";break;
            case 7:expected=0;name="removed_active_candidate_does_not_trigger_preflight";break;
        }
        int status=CjguiAdvanceComposablePreparationOnMain(ctx.rendererSessionToken,prepId,deadline,&ready);
        BOOL correct=status==expected;
        if(scenario==0)correct=correct && !ready && p.nodeCursor==0 && p.phase==1;
        else if(scenario!=7)correct=correct && !ready && p.nodeCursor==0;
        else correct=correct && ready && p.ready;
        fprintf(stderr,"PREFLIGHT_GUARD scenario=%s status=%d ready=%u cursor=%lu phase=%lu\n",name,status,ready,(unsigned long)p.nodeCursor,(unsigned long)p.phase);
        CHECK(correct,name);
        if(scenario==6)ctx.view.invalidated=NO;
        PreflightRelease(ctx,prepId);
    }
}

int main(void){@autoreleasepool{
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    PreflightEarlyRefusal();PreflightGuards();return failures?1:0;
}}
