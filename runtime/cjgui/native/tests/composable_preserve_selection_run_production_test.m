// Real prepared source, omitted body and tagged nonempty selection background.
// Uses the normal AppKit/TextKit/Metal renderer, no CJGUI_INTERNAL_TESTING.
#define CJGUI_PRESERVE_SOURCE_NO_MAIN 1
#import "composable_preserve_caret_source_production_test.m"

static NSString *RunWire(int start,int end) {
    return [NSString stringWithFormat:@"%d:%d:13:400:0:0:0:0:1:1:0.2:0.4:0.8:0.45:1",start,end];
}
static int RunPrepare(CJGuiInternalSession *ctx,uint64_t prep,uint64_t from,uint64_t to,
    NSString *literal,NSString *wire,BOOL preserve,BOOL reuse) {
    uint64_t token=ctx.rendererSessionToken;
    int status=cjgui_internal_renderer_begin_composable_preparation(token,prep,from,to,3);
    if(status)return status;
    CHECK(ctx.composablePreparation.activeSourceCredential!=nil,
        "run_real_begin_captures_actual_source_credential");
    status=cjgui_internal_renderer_stage_candidate_caret(token,prep,to,1,401,0,2);
    if(status)return status;
    for(uint32_t i=0;i<3;i++) {
        CJGuiInternalComposableSceneNode *old=ctx.composableNodes[i];
        CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=to;
        if(i==0)raw.preservesActiveLocalText=preserve;
        CjguiInternalRendererComposableGeometry g=old.geometry;g.nodeId=raw.nodeId;
        if(reuse) {
            uint32_t reused=0;
            status=cjgui_internal_renderer_reuse_composable_node_batch(token,prep,i,1,&raw,&g,0,&reused);
            if(status)return status;
            if(reused!=1)return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        } else {
            status=cjgui_internal_renderer_prepare_composable_node(token,prep,i,&raw,&g,
                "",i==0?literal.UTF8String:old.value.UTF8String,"","","","","",i==0?wire.UTF8String:"");
            if(status) {
                fprintf(stderr,"RUN_FIRST_REFUSAL prep=%llu node=%u status=%d filled=%lu owned=%lu\n",
                    (unsigned long long)prep,i,status,(unsigned long)ctx.composablePreparation.filled.count,
                    (unsigned long)ctx.composablePreparation.ownedPacketBytes);
                return status;
            }
        }
    }
    return 0;
}
static int RunPublish(CJGuiInternalSession *ctx,uint64_t prep,uint64_t scene) {
    uint64_t token=ctx.rendererSessionToken;uint32_t ready=0;
    uint64_t end=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(5000000000);
    while(!ready && cjgui_internal_renderer_owner_clock_ns()<end) {
        int st=cjgui_internal_renderer_advance_composable_preparation(token,prep,0,&ready);
        if(st)return st;
        if(!ready)CFRunLoopRunInMode(kCFRunLoopDefaultMode,.005,true);
    }
    if(!ready)return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    int st=cjgui_internal_renderer_configure_composable_scene(token,scene,3);if(st)return st;
    st=cjgui_internal_renderer_stage_window_background(token,scene,0,1);if(st)return st;
    st=cjgui_internal_renderer_promote_composable_preparation(token,prep);if(st)return st;
    CjguiInternalRendererFrameObservation obs={0};
    st=cjgui_internal_renderer_present_composable_scene(token,&obs);
    return st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED?0:st;
}
static BOOL ExactBackground(NSAttributedString *text) {
    if(text.length<3)return NO;
    NSColor *color=[[text attribute:NSBackgroundColorAttributeName atIndex:1 effectiveRange:NULL]
        colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    return color && fabs(color.redComponent-.2)<.000001 && fabs(color.greenComponent-.4)<.000001 &&
        fabs(color.blueComponent-.8)<.000001 && fabs(color.alphaComponent-.45)<.000001 &&
        ![text attribute:NSBackgroundColorAttributeName atIndex:0 effectiveRange:NULL] &&
        ![text attribute:NSBackgroundColorAttributeName atIndex:2 effectiveRange:NULL];
}
static BOOL CurrentRun(CJGuiInternalSession *ctx,NSString *body,NSString *wire) {
    CJGuiInternalComposableSceneNode *node=ctx.composableNodes[0];
    uint64_t meta[16]={0};double rect[8]={0};
    int caret=cjgui_internal_renderer_accepted_caret_value(ctx.rendererSessionToken,ctx.sessionGeneration,
        ctx.composableSceneVersion,401,0,2,NULL,meta,rect);
    BOOL layoutBackground=ExactBackground(node.preparedTextLayout.storage);
    BOOL proxyBackground=ExactBackground(ctx.composableSceneOverlay.inputProxy.attributedString);
    fprintf(stderr,"RUN_ACCEPTED body=%d layout=%d runs=%d layoutBackground=%d proxyBackground=%d caret=%d\n",
        [node.value isEqualToString:body],[node.preparedTextLayout.storage.string isEqualToString:body],
        [ctx.composableTextStyleRunsRaw[@401] isEqualToString:wire],layoutBackground,proxyBackground,caret);
    return [node.value isEqualToString:body] && [node.preparedTextLayout.storage.string isEqualToString:body] &&
        [ctx.composableTextStyleRunsRaw[@401] isEqualToString:wire] && layoutBackground && proxyBackground && caret==0;
}
static void TaggedPreserve(NSString *body,NSString *wire,BOOL valid,int change) {
    NSString *oldWire=body.length?RunWire(1,4):@"";
    CJGuiInternalSession *ctx=PreserveFixtureWithRuns(MTLCreateSystemDefaultDevice(),body,oldWire);
    CHECK(ctx!=nil,"run_actual_normal_multiline_fixture");if(!ctx)return;
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    int seed=RunPrepare(ctx,971,1,2,body,oldWire,YES,NO);
    if(!seed)seed=RunPublish(ctx,971,2);
    fprintf(stderr,"RUN_SEED status=%d scene=%llu\n",seed,(unsigned long long)ctx.composableSceneVersion);
    CHECK(seed==0,"run_initial_literal_candidate_published");
    if(seed){CjguiReleaseSession(ctx.rendererSessionToken);return;}
    NSDictionary *oldRuns=[ctx.composableTextStyleRunsRaw copy];
    NSArray *accepted=ctx.composableNodes;
    NSAttributedString *highlight=[ctx.composableSceneOverlay.inputProxy.attributedString copy];
    NSAttributedString *layoutHighlight=[ctx.composableNodes[0].preparedTextLayout.storage copy];
    int st=RunPrepare(ctx,972,2,3,@"",wire,YES,NO);
    if(!valid) {
        CHECK(st==CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID,
            "run_real_empty_oob_or_scalar_interior_refused_at_effective_body");
        fprintf(stderr,"RUN_RETAIN scene=%llu nodesSame=%d wireSame=%d highlightSame=%d filled=%lu owned=%lu\n",(unsigned long long)ctx.composableSceneVersion,ctx.composableNodes==accepted,[ctx.composableTextStyleRunsRaw isEqual:oldRuns],[ctx.composableSceneOverlay.inputProxy.attributedString isEqualToAttributedString:highlight],(unsigned long)ctx.composablePreparation.filled.count,(unsigned long)ctx.composablePreparation.ownedPacketBytes);
        CHECK(ctx.composableSceneVersion==2 && ctx.composableNodes==accepted &&
            [ctx.composableTextStyleRunsRaw isEqual:oldRuns] &&
            [ctx.composableSceneOverlay.inputProxy.attributedString isEqualToAttributedString:highlight] &&
            [ctx.composableNodes[0].preparedTextLayout.storage isEqualToAttributedString:layoutHighlight] &&
            ![ctx.composablePreparation.filled containsIndex:0] && ctx.composablePreparation.ownedPacketBytes==0,
            "run_failed_prepare_keeps_original_accepted_highlight_and_no_admission");
    } else {
        CHECK(st==0,"run_omitted_transport_nonempty_tagged_run_prepares");
        if(!st) {
            if(change==1)ctx.ownedTextSessionBindingEpoch++;
            if(change==2)ctx.composableSceneOverlay.activeTextBodyGeneration++;
            st=RunPublish(ctx,972,3);
            if(change) {
                CHECK(st==CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.composableSceneVersion==2 &&
                    ctx.composableNodes==accepted && [ctx.composableSceneOverlay.inputProxy.attributedString isEqualToAttributedString:highlight],
                    "run_same_bytes_new_binding_or_source_generation_cannot_borrow");
            } else {
                CHECK(st==0 && CurrentRun(ctx,body,wire),
                    "run_accepted_background_body_layout_caret_share_actual_source");
                if(!st) {
                    int reused=RunPrepare(ctx,973,3,4,@"",wire,YES,YES);
                    if(!reused)reused=RunPublish(ctx,973,4);
                    CHECK(reused==0 && CurrentRun(ctx,body,wire),
                        "run_real_declaration_reuse_keeps_effective_source_validation");
                }
            }
        }
    }
    fprintf(stderr,"RUN_CASE bodyBytes=%lu wire=%s valid=%d change=%d finalScene=%llu status=%d\n",
        (unsigned long)[body lengthOfBytesUsingEncoding:NSUTF8StringEncoding],wire.UTF8String,valid,change,
        (unsigned long long)ctx.composableSceneVersion,st);
    CjguiReleaseSession(ctx.rendererSessionToken);
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    TaggedPreserve(@"A中😀B",RunWire(1,4),YES,0);
    TaggedPreserve(@"",RunWire(0,1),NO,0);
    TaggedPreserve(@"A中😀B",RunWire(1,10),NO,0);
    TaggedPreserve(@"A中😀B",RunWire(2,4),NO,0);
    TaggedPreserve(@"A中😀B",RunWire(1,5),NO,0);
    TaggedPreserve(@"A中😀B",RunWire(1,4),YES,1);
    TaggedPreserve(@"A中😀B",RunWire(1,4),YES,2);
    fprintf(stderr,"selection run preserved source production failures=%d\n",failures);
    return failures?1:0;
} }
