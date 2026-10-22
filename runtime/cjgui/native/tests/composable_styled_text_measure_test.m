// The ordinary text measurer used by auto layout must agree with the actual
// attributed painter. No fixed text height or application-side line estimate.
#define main previousFontResourceMain
#import "composable_font_resource_test.m"
#undef main

static void CheckStyledAutoPlacement(uint64_t session,uint32_t width,uint32_t limit) {
    NSString *body=@"normal BIG 中文 é 👩🏽‍💻 and ordinary words that wrap naturally";
    const char *encoded="7:10:36:0:1:1:0:0:1:0:0:0:0:0";
    CjguiInternalRendererTextMeasurement measured={0};
    int status;
#ifdef CJGUI_STYLED_TEXT_MEASUREMENT_VERSION
    status=cjgui_internal_renderer_measure_composable_styled_text(session,body.UTF8String,14,0,0,width,
        0.25,0,limit,limit?1:0,encoded,&measured);
#else
    // Exact pre-fix route called by preferredWidth / readonlyTextHeight.
    status=cjgui_internal_renderer_measure_composable_text_typography(session,body.UTF8String,14,0,0,width,
        0.25,0,&measured);
#endif
    CJGuiInternalComposableSceneNode *text=[CJGuiInternalComposableSceneNode new];
    text.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .width=width?width+14:10000,.height=10000,.fontSize=14,.fontFamily=0,.textAlpha=1,
        .letterSpacing=0.25,.textMaxLines=limit,.textOverflow=limit?1:0};
    text.value=body;text.styleRunsSignature=[NSString stringWithUTF8String:encoded];
    CjguiPreparedTextNodeLayout *paint=CjguiPrepareTextNodeLayout(text,body,1,CjguiComposableDecodeStyleRuns(text.styleRunsSignature),nil);
    [paint.layoutManager ensureLayoutForTextContainer:paint.container];
    NSRect actual=[paint.layoutManager usedRectForTextContainer:paint.container];
    CGFloat fullHeight=ceil(NSMaxY(actual));
    CJGuiInternalComposableSceneNode *followingButton=[CJGuiInternalComposableSceneNode new];
    followingButton.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        .y=measured.height+4,.width=160,.height=32};
    CHECK(status==0,"styled_auto_measurement_succeeds");
    CHECK(measured.height==fullHeight,"mixed_font_height_uses_actual_textkit_lines");
    CHECK(followingButton.node.y>=NSMaxY(actual)+4,"following_normal_button_clears_full_text_height");
    fprintf(stderr,"styled_auto width=%u limit=%u measured=%u painted=%.2f next_button_y=%lld\n",
        width,limit,measured.height,fullHeight,(long long)followingButton.node.y);
}
static NSData *StyledPixels(CJGuiInternalMetalView *view,CJGuiInternalComposableSceneNode *node,CjguiPreparedTextNodeLayout *layout) {
    uint64_t bytes=0;
    id<MTLTexture> texture=CjguiRasterComposableTextTexture(view,node,1,1,node.value,NSMakeRect(0,0,node.node.width,node.node.height),&bytes,layout,
        CjguiInternalTextWorkReasonStaticCandidate,NULL,0);
    if(!texture)return nil;
    NSMutableData *pixels=[NSMutableData dataWithLength:texture.width*texture.height*4];
    [texture getBytes:pixels.mutableBytes bytesPerRow:texture.width*4 fromRegion:MTLRegionMake2D(0,0,texture.width,texture.height) mipmapLevel:0];
    return pixels;
}
static void CheckPaintReuse(CJGuiInternalMetalView *view,BOOL hardBreak) {
    CJGuiInternalComposableSceneNode *old=[CJGuiInternalComposableSceneNode new];
    old.node=(CjguiInternalRendererComposableNode){.nodeId=200,.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .width=180,.height=110,.clipWidth=180,.clipHeight=110,.fontSize=14,.textAlpha=1,.textRed=1,.textGreen=1,.textBlue=1,
        .textMaxLines=hardBreak?2:0,.textOverflow=hardBreak?1:0};
    old.value=hardBreak?@"normal BIG 中文\nsecond line\nthird line":@"normal BIG 中文 é 👩🏽‍💻 and ordinary words that wrap naturally";
    old.styleRunsSignature=@"7:10:36:0:1:1:0:0:1:0:0:0:0:0";
    old.preparedTextLayout=CjguiPrepareTextNodeLayout(old,old.value,1,CjguiComposableDecodeStyleRuns(old.styleRunsSignature),nil);
    NSData *before=StyledPixels(view,old,old.preparedTextLayout);
    NSRect extent=CjguiComposableTextTextureRectForNodeWithText(old,old.value);
    CHECK(NSHeight(extent)>=NSHeight([old.preparedTextLayout.layoutManager usedRectForTextContainer:old.preparedTextLayout.container]),"mixed_font_texture_extent_does_not_crop_large_glyphs");
    CJGuiInternalComposableSceneNode *next=CjguiCloneComposableSceneNode(CjguiLookupSession(view.sessionToken),old,0,2);
    next.styleRunsSignature=@"7:10:36:0:1:0:1:1:1:1:0.2:0.1:0:1";
    next.node=(CjguiInternalRendererComposableNode){.nodeId=200,.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .width=180,.height=110,.clipWidth=180,.clipHeight=110,.fontSize=14,.textAlpha=1,.textRed=1,.textGreen=1,.textBlue=1,
        .textMaxLines=hardBreak?2:0,.textOverflow=hardBreak?1:0};
    uint64_t builds=CjguiTestAttributedGeometryBuilds;
    CjguiPreparedTextNodeLayout *reuse=CjguiReusableReadonlyLayout(next,next.value,1);
    CHECK(reuse && reuse.layoutManager==old.preparedTextLayout.layoutManager,"paint_only_update_reuses_existing_geometry");
    NSData *changed=StyledPixels(view,next,reuse);
    CHECK(CjguiTestAttributedGeometryBuilds==builds,"paint_only_update_builds_no_geometry");
    CjguiPreparedTextNodeLayout *oracle=CjguiPrepareTextNodeLayout(next,next.value,1,CjguiComposableDecodeStyleRuns(next.styleRunsSignature),nil);
    NSData *expected=StyledPixels(view,next,oracle);
    CHECK(before && changed && ![before isEqualToData:changed],"paint_only_update_changes_pixels");
    CHECK([changed isEqualToData:expected],"reused_geometry_pixels_equal_independent_fresh_layout");
    CHECK([before isEqualToData:StyledPixels(view,old,old.preparedTextLayout)],"private_paint_candidate_preserves_accepted_pixels");
    CjguiInternalRendererComposableNode metric=next.node;metric.fontSize=15;next.node=metric;
    CHECK(CjguiReusableReadonlyLayout(next,next.value,1)==nil,"metric_change_cannot_reuse_old_geometry");
}
static void CheckDestroyedWindowGraph() {
    CJGuiInternalSession *closed=[CJGuiInternalSession new];
    CJGuiInternalComposableSceneOverlay *overlay=[[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSMakeRect(0,0,300,200)];
    closed.composableSceneOverlay=overlay;overlay.session=closed;
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    node.node=(CjguiInternalRendererComposableNode){.nodeId=300,.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,.fontSize=18};
    overlay.nodes=@[node];closed.composableNodes=[NSMutableArray arrayWithObject:node];
    CJGuiInternalComposableAccessibilityAction *externalAX=[[CJGuiInternalComposableAccessibilityAction alloc] initWithOverlay:overlay node:node];
    overlay.accessibilityActions=[NSMutableArray arrayWithObject:externalAX];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    CJGuiInternalMetalView *retainedView=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,300,200) device:device commandQueue:[device newCommandQueue]];
    retainedView.composableNodes=@[node];closed.view=retainedView;
    uint64_t token=CjguiAllocateSession(closed);
    CHECK(cjgui_internal_renderer_destroy(token)==0,"normal_native_window_destroy_succeeds");
    CHECK(overlay.nodes.count==0 && closed.composableSceneOverlay==nil,"destroy_retires_overlay_scene_holder_before_callback_scope_ends");
    CHECK(externalAX.node==nil,"destroy_retires_node_in_external_ax_element");
    CHECK(retainedView.composableNodes.count==0,"invalidated_metal_view_releases_accepted_scene_nodes");
}
static void CheckColdStyledTransport(CJGuiInternalSession *ctx) {
    NSString *line=@"normal BIG 中文 é 👩🏽‍💻 and ordinary words that wrap naturally ";
    NSString *body=[line stringByPaddingToLength:line.length*40 withString:line startingAtIndex:0];
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    node.node=(CjguiInternalRendererComposableNode){.nodeId=410,.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .width=174,.height=10000,.clipWidth=174,.clipHeight=10000,.fontSize=14,.textAlpha=1};
    node.value=body;node.styleRunsSignature=@"7:10:36:0:1:1:0:0:1:0:0:0:0:0";
    CjguiComposablePreparation *preparation=[CjguiComposablePreparation new];preparation.scale=1;
    uint64_t charge=0;
    CjguiTextPreparationWorkerInput *input=CjguiCreateTextPreparationWorkerInput(ctx,preparation,node,body,node.styleRunsSignature,&charge);
    CHECK(input && charge>body.length,"long_styled_input_frozen_on_existing_bounded_worker_path");
    CJGuiInternalComposableSceneNode *snapshot=CjguiTextPreparationNodeSnapshot(input,NSMakeSize(160,10));
    CHECK([snapshot.styleRunsSignature isEqualToString:node.styleRunsSignature],"cold_worker_snapshot_preserves_metric_run_declaration");
    CHECK(NSHeight(CjguiComposableTextTextureRectForNodeWithText(snapshot,body))==10000,"cold_styled_coverage_ignores_plain_font_extent_memo");
    CjguiPreparedTextNodeLayout *layout=CjguiTextPreparationLayoutFromAttributedBody(input,input.sourceAttributedBody);
    node.preparedTextLayout=layout;node.styleRunsSignature=@"7:10:36:0:1:0:1:1:1:0:0:0:0:0";
    CjguiPreparedTextNodeLayout *paint=CjguiReusableReadonlyLayout(node,body,1);
    CHECK(paint && paint.layoutManager==layout.layoutManager,"long_worker_geometry_is_reusable_for_palette_changes");
}
static void CheckStyledAsyncAndCost(uint64_t session,const char *fontPath) {
    uint32_t code=0;uint64_t job=0;
    CHECK(cjgui_internal_renderer_font_resource_register(2,fontPath,0,&code)==0,"styled_job_registers_font");
    NSString *body=@"normal BIG 中文 é 👩🏽‍💻 and ordinary words that wrap naturally";
    NSString *wire=[NSString stringWithFormat:@"7:10:36:0:%u:1:0:0:1:0:0:0:0:0",code];
    NSString *asyncBody=[body stringByPaddingToLength:body.length*100 withString:body startingAtIndex:0];
    CjguiInternalRendererTextMeasurement expected={0};
    CHECK(cjgui_internal_renderer_measure_composable_styled_text(session,asyncBody.UTF8String,14,0,0,160,.25,0,0,0,wire.UTF8String,&expected)==0,"styled_sync_reference_ready");
    CjguiAsyncMultilineMeasureTestCloseWorkerGate();
    CHECK(cjgui_async_composable_styled_text_begin(asyncBody.UTF8String,strlen(asyncBody.UTF8String),14,0,0,160,.25,0,0,0,wire.UTF8String,&job)==CJGUI_ASYNC_MEASURE_STARTED,"styled_async_uses_existing_job_channel");
    CHECK(CjguiAsyncMultilineMeasureTestWaitForWorkerGate(1000),"styled_original_worker_paused");
    CHECK(cjgui_internal_renderer_font_resource_release(code)==0,"styled_job_font_registry_retired");
    CHECK(CjguiFontResourceLease(code)!=nil,"styled_job_holds_declared_font_generation");
    CjguiAsyncMultilineMeasureTestOpenWorkerGate();
    CjguiAsyncTextMetrics metrics={0};CjguiAsyncMultilineMeasureFailure failure=0;CjguiAsyncMultilineMeasureStatus status=0;
    for(int i=0;i<2000;i++){
        status=CjguiAsyncTextMetricsPoll(job,&metrics,&failure);
        if(status==CJGUI_ASYNC_MEASURE_READY || status==CJGUI_ASYNC_MEASURE_FAILED)break;
        usleep(1000);
    }
    CHECK(status==CJGUI_ASYNC_MEASURE_READY && !failure && metrics.height==expected.height && metrics.width==expected.width,"styled_original_async_completion_matches_sync_geometry");
    CHECK(CjguiAsyncMultilineMeasureRelease(job,CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED)==CJGUI_ASYNC_MEASURE_READY,"styled_job_consumed_on_original_channel");
    CJGuiInternalSession *ctx=CjguiLookupSession(session);ctx.forcedComposableMeasurementFailures=1;
    CjguiInternalRendererTextMeasurement refused={1,1,1,1};
    CHECK(cjgui_internal_renderer_measure_composable_styled_text(session,body.UTF8String,14,0,0,160,.25,0,0,0,wire.UTF8String,&refused)!=0 && refused.height==0,"styled_measurement_failure_is_explicit_without_output");
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    node.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,.width=174,.height=110,.fontSize=14,.textAlpha=1,.textRed=1,.textGreen=1,.textBlue=1};
    node.value=body;node.styleRunsSignature=@"7:10:36:0:1:1:0:0:1:0:0:0:0:0";
    uint64_t before=CjguiTestAttributedGeometryBuilds,started=CjguiDiagnosticMonotonicNanoseconds();
    node.preparedTextLayout=CjguiPrepareTextNodeLayout(node,body,1,CjguiComposableDecodeStyleRuns(node.styleRunsSignature),nil);
    CHECK(StyledPixels(ctx.view,node,node.preparedTextLayout)!=nil,"fixed_paragraph_cold_pixels_ready");
    uint64_t cold=CjguiDiagnosticMonotonicNanoseconds()-started,coldBuilds=CjguiTestAttributedGeometryBuilds-before;
    started=CjguiDiagnosticMonotonicNanoseconds();before=CjguiTestAttributedGeometryBuilds;
    for(int i=0;i<100;i++){@autoreleasepool{
        node.styleRunsSignature=i%2?@"7:10:36:0:1:0:1:1:1:0:0:0:0:0":@"7:10:36:0:1:1:0:0:1:0:0:0:0:0";
        CjguiPreparedTextNodeLayout *paint=CjguiReusableReadonlyLayout(node,body,1);
        CHECK(paint && StyledPixels(ctx.view,node,paint)!=nil,"fixed_paragraph_hot_paint_pixels_ready");
    }}
    uint64_t hot=CjguiDiagnosticMonotonicNanoseconds()-started,hotBuilds=CjguiTestAttributedGeometryBuilds-before;
    CHECK(coldBuilds==1 && hotBuilds==0,"fixed_paragraph_hot_palette_updates_build_no_geometry");
    fprintf(stderr,"styled_cost utf8_bytes=%zu width=160 base_pt=14 run_pt=36 cold_ns=%llu hot_100_ns=%llu cold_geometry_builds=%llu hot_geometry_builds=%llu scope=native_layout_raster_upload_readback_not_e2e\n",strlen(body.UTF8String),(unsigned long long)cold,(unsigned long long)hot,(unsigned long long)coldBuilds,(unsigned long long)hotBuilds);
}
int main(int argc,const char **argv) {
    if(previousFontResourceMain(argc,argv))return 1;
    @autoreleasepool{
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,600,400)
        device:device commandQueue:[device newCommandQueue]];
    uint64_t session=CjguiAllocateSession(ctx);
    CheckStyledAutoPlacement(session,160,0);
    CheckStyledAutoPlacement(session,460,0);
    CheckStyledAutoPlacement(session,160,2);
    ctx.view.sessionToken=session;
    CheckPaintReuse(ctx.view,NO);CheckPaintReuse(ctx.view,YES);
    CheckDestroyedWindowGraph();
    CheckColdStyledTransport(ctx);
    CheckStyledAsyncAndCost(session,argv[1]);
    CjguiReleaseSession(session);
    fprintf(stderr,"styled_auto failures=%d\n",failures);
    return failures?1:0;
}}
