// Real normal multiline preserve transport and byte caret, no testing renderer.
#define main existingPaintProductionMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main
static CJGuiInternalSession *PreserveFixtureWithRuns(id<MTLDevice> device, NSString *body, NSString *initialRuns) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.app = [NSApplication sharedApplication];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 680, 500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window.releasedWhenClosed = NO;
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    if (initialRuns.length) ctx.composableTextStyleRunsRaw[@401] = initialRuns;
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 680, 500) session:ctx];
    ctx.composableSceneOverlay = overlay;
    ctx.window.contentView = overlay;
    for (NSUInteger index = 0; index < 3; index++) {
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 401 + index; raw.resourceId = 1; raw.projectionVersion = 1;
        raw.nodeKind = index == 0 ? CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT : CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x = 0; raw.y = index * 130; raw.width = 680; raw.height = 120;
        raw.clipWidth = 680; raw.clipHeight = 500; raw.fontSize = 13;
        raw.textAlpha = 1; raw.isInteractive = 1;
        node.node = raw; node.index = (uint32_t)index;
        node.value = index == 0 ? body : (index == 1 ? @"FGHIJ" : @"KLMNO");
        node.styleRunsSignature = index == 0 ? (initialRuns ?: @"") : @""; node.textTextureCacheKey = @"";
        [ctx.stagedComposableNodes addObject:node];
    }
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token || CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return nil;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled = YES;
    ctx.ownedTextSessionNodeId = 401;
    ctx.ownedTextSessionResourceId = 1;
    ctx.ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    ctx.ownedTextSessionBindingEpoch = 81;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    if (![overlay focusCommittedNodeId:401]) return nil;
    [ctx.pendingInteractions removeAllObjects];
    [overlay refreshGpuTextForActiveInput];
    return ctx;
}

static CJGuiInternalSession *PreserveFixture(id<MTLDevice> device, NSString *body) {
    return PreserveFixtureWithRuns(device,body,@"");
}

static BOOL RecoverPreservedCandidate(CJGuiInternalSession *ctx,int64_t byte) {
    uint64_t token=ctx.rendererSessionToken,prep=746;
    if(cjgui_internal_renderer_begin_composable_preparation(token,prep,1,2,3)!=0 ||
        cjgui_internal_renderer_stage_candidate_caret(token,prep,2,1,401,byte,2)!=0)return NO;
    for(uint32_t i=0;i<3;i++) {
        CJGuiInternalComposableSceneNode *old=ctx.composableNodes[i];
        CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=2;
        if(i==0)raw.preservesActiveLocalText=1;
        CjguiInternalRendererComposableGeometry g=old.geometry;g.nodeId=raw.nodeId;
        if(cjgui_internal_renderer_prepare_composable_node(token,prep,i,&raw,&g,
            "",i==0?"":old.value.UTF8String,"","","","","","")!=0)return NO;
    }
    uint32_t ready=0;uint64_t end=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(5000000000);
    while(!ready && cjgui_internal_renderer_owner_clock_ns()<end) {
        if(cjgui_internal_renderer_advance_composable_preparation(token,prep,0,&ready)!=0)return NO;
        if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.005,true);
    }
    if(!ready || cjgui_internal_renderer_configure_composable_scene(token,2,3)!=0 ||
        cjgui_internal_renderer_stage_window_background(token,2,0,1)!=0 ||
        cjgui_internal_renderer_promote_composable_preparation(token,prep)!=0)return NO;
    CjguiInternalRendererFrameObservation obs={0};int presented=cjgui_internal_renderer_present_composable_scene(token,&obs);
    uint64_t meta[16]={0};double rect[8]={0};
    return (presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==2 && !ctx.stagedNativeTextSourcePreparation &&
        cjgui_internal_renderer_accepted_caret_value(token,ctx.sessionGeneration,2,401,byte,2,NULL,meta,rect)==0 && rect[3]>0;
}

static void PreserveCaret(NSString *body,int64_t byte,BOOL literalEmpty,int boundary) {
    CJGuiInternalSession *ctx=PreserveFixture(MTLCreateSystemDefaultDevice(),body);
    CHECK(ctx!=nil,"preserve_caret_actual_multiline_A");if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken,prep=745;
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,prep,1,2,3)==0,
        "preserve_caret_actual_prepare_freezes_source");
    CHECK(cjgui_internal_renderer_stage_candidate_caret(token,prep,2,1,401,byte,2)==0,
        "preserve_caret_original_byte_declared");
    for(uint32_t i=0;i<3;i++) {
        CJGuiInternalComposableSceneNode *old=ctx.composableNodes[i];
        CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=2;
        if(i==0)raw.preservesActiveLocalText=!literalEmpty;
        CjguiInternalRendererComposableGeometry g=old.geometry;g.nodeId=raw.nodeId;
        CHECK(cjgui_internal_renderer_prepare_composable_node(token,prep,i,&raw,&g,
            "",i==0?"":old.value.UTF8String,"","","","","","")==0,
            "preserve_caret_original_omitted_or_real_empty_transport");
    }
    uint32_t ready=0;uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(5000000000);
    int advanced=0;
    while(!ready && cjgui_internal_renderer_owner_clock_ns()<deadline) {
        advanced=cjgui_internal_renderer_advance_composable_preparation(token,prep,0,&ready);
        if(advanced!=0)break;
        if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.005,true);
    }
    if(literalEmpty && body.length>0) {
        CHECK(!ready && advanced==CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED && ctx.composableSceneVersion==1,
            "literal_owner_mutation_without_owner_handoff_keeps_existing_refusal");
        CjguiReleaseSession(token);return;
    }
    CHECK(ready && advanced==0,"preserve_caret_actual_resources_ready");
    if(!ready){fprintf(stderr,"PRESERVE_PREP_ERROR status=%d\n",advanced);CjguiReleaseSession(token);return;}
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,3)==0 &&
        cjgui_internal_renderer_stage_window_background(token,2,0,1)==0,
        "preserve_caret_original_submit_order");
    if(boundary==1)ctx.ownedTextSessionBindingEpoch++;
    if(boundary==2)ctx.composableSceneOverlay.activeTextBodyGeneration++;
    if(boundary==3)ctx.composableSceneOverlay.activeTextAttributedGeneration++;
    int promoted=cjgui_internal_renderer_promote_composable_preparation(token,prep);
    if(boundary==1 || boundary==2 || boundary==3) {
        CHECK(promoted==CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.composableSceneVersion==1,
            "preserve_caret_same_bytes_new_binding_or_generation_cannot_borrow");
        CjguiReleaseSession(token);return;
    }
    CHECK(promoted==0,"preserve_caret_same_ticket_promoted");
    CJGuiInternalComposableSceneNode *candidate=ctx.stagedComposableNodes[0];
    fprintf(stderr,"PRESERVE_ORIGINAL transport_bytes=%lu prepared_bytes=%lu preserve=%u byte=%lld old_scene=%llu\n",
        (unsigned long)[candidate.value lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
        (unsigned long)[candidate.preparedTextLayout.storage.string lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
        candidate.node.preservesActiveLocalText,(long long)byte,(unsigned long long)ctx.composableSceneVersion);
    if(boundary==4)candidate.preparedTextLayout=ctx.composableNodes[1].preparedTextLayout;
    if(boundary==5)ctx.composableSceneOverlay.activeTextBodyGeneration++;
    CjguiInternalRendererFrameObservation obs={0};int presented=cjgui_internal_renderer_present_composable_scene(token,&obs);
    BOOL invalid=byte==2 && [body isEqualToString:@"A中😀B"];
    if(boundary==4 || boundary==5) {
        CHECK(presented==(boundary==4?CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID:CJGUI_INTERNAL_RENDERER_SCENE_STALE) && ctx.composableSceneVersion==1,
            "preserve_caret_wrong_layout_or_post_promote_source_change_never_commits");
        if(boundary==4)CHECK(RecoverPreservedCandidate(ctx,byte),
            "preserve_caret_new_real_candidate_recovers_after_failed_present_and_releases_old_proof");
    } else if(invalid) {
        CHECK(presented==CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID && ctx.composableSceneVersion==1,
            "preserve_caret_scalar_internal_byte_still_rejected");
    } else {
        uint64_t meta[16]={0};double rect[8]={0};
        int read=cjgui_internal_renderer_accepted_caret_value(token,ctx.sessionGeneration,2,401,byte,2,NULL,meta,rect);
        CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            ctx.composableSceneVersion==2 && read==0 && rect[3]>0,
            "preserve_caret_current_accepted_readback_uses_same_proved_body_and_layout");
        CHECK([ctx.composableSceneOverlay.inputProxy.string isEqualToString:literalEmpty?@"":body],
            "preserve_caret_never_writes_or_recovers_old_body");
        fprintf(stderr,"PRESERVE_RESULT presented=%d read=%d height=%.3f scene=%llu\n",
            presented,read,rect[3],(unsigned long long)ctx.composableSceneVersion);
    }
    CjguiReleaseSession(token);
}
#ifndef CJGUI_PRESERVE_SOURCE_NO_MAIN
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    PreserveCaret(@"alpha beta gamma\n\n",0,NO,0);
    PreserveCaret(@"A中😀B",4,NO,0);
    PreserveCaret(@"",0,YES,0);
    PreserveCaret(@"A中😀B",2,NO,0);
    PreserveCaret(@"same",0,NO,1);
    PreserveCaret(@"same",0,NO,2);
    PreserveCaret(@"same",0,NO,3);
    PreserveCaret(@"same",0,NO,4);
    PreserveCaret(@"same",0,NO,5);
    PreserveCaret(@"old document",0,YES,0);
    return failures?1:0;
} }
#endif
