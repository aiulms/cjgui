// The actual retained AppKit adapter and production scene commit. No focus
// restoration after an external write: values and raster invalidation must
// settle together for either view of one field.
#define main priorSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main
#undef CHECK
#define CHECK(c,n) do { BOOL ok=(c); fprintf(stderr,"form_sync case=%s result=%s\n",n,ok?"PASS":"FAIL"); if(!ok) failures++; } while(0)

static CJGuiInternalComposableSceneNode *Field(CJGuiInternalSession *ctx,NSUInteger index,uint64_t id,
    uint64_t version,NSString *body) {
    CJGuiInternalComposableSceneNode *n=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[index],(uint32_t)index,version);
    CjguiInternalRendererComposableNode raw=n.node;
    raw.nodeId=id; raw.resourceId=1; raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    raw.projectionVersion=version; raw.x=20; raw.y=20+index*100; raw.width=400; raw.height=40;
    raw.clipX=0; raw.clipY=0; raw.clipWidth=680; raw.clipHeight=500; raw.semanticIncarnation=0;
    n.node=raw; n.value=body; return n;
}

static void PublishForm(CJGuiInternalSession *ctx, uint64_t version, NSString *first, NSString *second) {
    CHECK(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken, version, 2)==0,
        "candidate_configured");
    ctx.stagedComposableNodes[0]=Field(ctx,0,401,version,first);
    ctx.stagedComposableNodes[1]=Field(ctx,1,402,version,second);
    CHECK(CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken)==0,"scene_accepted");
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    CHECK(device!=nil,"real_metal_device");
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"production_fixture");
    if (!ctx) return 1;
    CJGuiInternalComposableSceneOverlay *overlay=ctx.composableSceneOverlay;
    uint64_t version=3;
    for (NSUInteger index=0; index<2; index++) {
        PublishForm(ctx,version++,@"Local",@"Local");
        uint64_t nodeId=401+index;
        CHECK([overlay focusCommittedNodeId:nodeId],"initial_focus");
        [ctx.pendingInteractions removeAllObjects];
        uint64_t generation=overlay.activeTextBodyGeneration;
        NSResponder *responder=ctx.window.firstResponder;
        NSTimeInterval started=NSProcessInfo.processInfo.systemUptime;
        PublishForm(ctx,version++,@"Package",@"Package");
        fprintf(stderr,"FORM_SYNC_OBSERVATION node=%llu elapsed_us=%llu accepted=%s proxy=%s generation=%llu:%llu\n",
            (unsigned long long)nodeId,(unsigned long long)((NSProcessInfo.processInfo.systemUptime-started)*1000000.0),
            ctx.composableNodes[index].value.UTF8String,overlay.inputProxy.string.UTF8String,
            (unsigned long long)generation,(unsigned long long)overlay.activeTextBodyGeneration);
        CHECK([ctx.composableNodes[index].value isEqualToString:@"Package"],"accepted_value");
        CHECK([overlay.inputProxy.string isEqualToString:@"Package"],"same_responder_new_buffer");
        CHECK(overlay.activeTextBodyGeneration>generation,"changed_buffer_invalidates_active_raster");
        CHECK(overlay.activeNodeId==nodeId && ctx.window.firstResponder==responder,"focus_and_responder_retained");
        CHECK(overlay.inputProxy.delegate==overlay &&
            ((CJGuiInternalComposableInputProxy *)overlay.inputProxy).composableOverlay==overlay,
            "prepared_frame_keeps_live_input_delegate");
        BOOL selectionReported=NO;
        for (CJGuiInternalQueuedInteraction *event in ctx.pendingInteractions)
            if (event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED)
                selectionReported=YES;
        CHECK(selectionReported,"installed_selection_keeps_original_callback");
        overlay.inputProxy.selectedRange=NSMakeRange(4,3);
        generation=overlay.activeTextBodyGeneration;
        PublishForm(ctx,version++,index==0?@"Package":@"8",index==0?@"8":@"Package");
        CHECK([overlay.inputProxy.string isEqualToString:@"Package"] &&
            NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(4,3)),"other_field_keeps_buffer_and_selection");
        CHECK(overlay.activeTextBodyGeneration==generation,"other_field_does_not_rebuild_active_body");
        [ctx.pendingInteractions removeAllObjects];
        [overlay.inputProxy insertText:@"q" replacementRange:NSMakeRange(4,3)];
        BOOL textReported=NO;
        for (CJGuiInternalQueuedInteraction *event in ctx.pendingInteractions)
            if (event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED)
                textReported=YES;
        CHECK([overlay.inputProxy.string isEqualToString:@"Packq"] && textReported,
            "next_AppKit_input_uses_installed_text_and_reports_change");
    }
    CHECK(cjgui_internal_renderer_destroy(ctx.rendererSessionToken)==0,"normal_destroy");
    return failures?1:0;
} }
