// Focused ordinary input moving out of a clip and back. Reuses the production
// scene fixture and actual Metal encoder; no owner/input/focus fallback is added.
#define main activeSingleLinePreviousFixtureMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main
#undef CHECK
#define CHECK(c,n) do { BOOL probePassed=(c); fprintf(stderr,"active_clip case=%s result=%s\n",n,probePassed?"PASS":"FAIL"); if(!probePassed)failures++; } while(0)

static BOOL SubmitActiveClip(CJGuiInternalSession *ctx,uint64_t version,double y,double width,
    BOOL preserve,NSString *body) {
    if(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken,version,1)!=0)return NO;
    CJGuiInternalComposableSceneNode *n=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[0],0,version);
    CjguiInternalRendererComposableNode raw=n.node;
    raw.nodeId=401;raw.resourceId=1;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    raw.projectionVersion=version;raw.x=20;raw.y=y;raw.width=width;raw.height=40;
    raw.clipX=20;raw.clipY=MAX(0,y);raw.clipWidth=width;
    raw.clipHeight=MAX(0,MIN(500,y+40)-MAX(0,y));
    raw.textAlpha=1;raw.fontSize=13;raw.preservesActiveLocalText=preserve;
    n.node=raw;n.value=body;n.label=@"规则名称";ctx.stagedComposableNodes[0]=n;
    CjguiInternalRendererStatus s=CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken);
    if(s!=0){fprintf(stderr,"active_clip submit=%llu status=%u\n",version,s);return NO;}
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    return YES;
}

static NSUInteger ActiveClipLastOldInk;
static NSUInteger ActiveClipInk(CJGuiInternalSession *ctx,const char *label) {
    const NSUInteger w=680,h=500;
    CJGuiInternalMetalView *view=ctx.view;
    // The reference target below has one sample, like the existing text-pixel
    // fixture; match its pipeline rather than the window's MSAA drawable.
    view.composableUsesMultisampling=NO;
    MTLTextureDescriptor *td=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:w height:h mipmapped:NO];td.storageMode=MTLStorageModeShared;td.usage=MTLTextureUsageRenderTarget;
    id<MTLTexture> target=[view.device newTextureWithDescriptor:td];
    id<MTLCommandBuffer> command=[view.commandQueue commandBuffer];
    MTLRenderPassDescriptor *pass=[MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction=MTLLoadActionClear;
    pass.colorAttachments[0].storeAction=MTLStoreActionStore;
    pass.colorAttachments[0].clearColor=MTLClearColorMake(0,0,0,0);
    id<MTLRenderCommandEncoder> encoder=[command renderCommandEncoderWithDescriptor:pass];
    // Isolate the exact production glyph shader from caret/background shape
    // buffers, which belong to the normal prepared-frame submission fixture.
    CJGuiInternalComposableSceneNode *n=ctx.composableNodes[0];
    BOOL ok=CjguiEnsureComposableImagePipeline(view) && n.textTexture!=nil;
    if(ok){
        [encoder setRenderPipelineState:view.composableImagePipeline];
        NSRect rect=n.textTextureRect;
        CjguiEncodeMetalTexture(encoder,w,h,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height,
            n.textTexture,n,YES,1.0f);
    }
    [encoder endEncoding];[command commit];[command waitUntilCompleted];
    CHECK(ok && command.status==MTLCommandBufferStatusCompleted,"actual_Metal_glyph_pass_encoded");
    NSMutableData *pixels=[NSMutableData dataWithLength:w*h*4];
    [target getBytes:pixels.mutableBytes bytesPerRow:w*4 fromRegion:MTLRegionMake2D(0,0,w,h) mipmapLevel:0];
    const char *directory=getenv("CJGUI_ACTIVE_CLIP_PIXELS");
    if(directory) [pixels writeToFile:[[NSString stringWithUTF8String:directory]
        stringByAppendingPathComponent:[NSString stringWithFormat:@"%s.bgra",label]] atomically:YES];
    const uint8_t *p=pixels.bytes;NSUInteger ink=0;
    NSUInteger top=(NSUInteger)MAX(0,n.node.y),bottom=(NSUInteger)MIN(h,n.node.y+n.node.height);
    for(NSUInteger y=top;y<bottom;y++)for(NSUInteger x=20;x<300;x++)
        if(p[(y*w+x)*4+3]>32)ink++;
    ActiveClipLastOldInk=0;
    for(NSUInteger y=100;y<140;y++)for(NSUInteger x=20;x<300;x++)
        if(p[(y*w+x)*4+3]>32)ActiveClipLastOldInk++;
    fprintf(stderr,"active_clip facts=%s ink=%lu bytes=%llu textures=%lu rect=%s origin=%s value=%s proxy=%s prepared=%s\n",
        label,(unsigned long)ink,(unsigned long long)n.textTextureByteCount,
        (unsigned long)(n.textTileTextures.count ?: (n.textTexture?1:0)),NSStringFromRect(n.textTextureRect).UTF8String,
        NSStringFromPoint(n.textTileLayoutOrigin).UTF8String,n.value.UTF8String,
        ctx.composableSceneOverlay.inputProxy.string.UTF8String,n.preparedTextLayout.storage.string.UTF8String);
    return ink;
}

static void ActiveClipScenario(id<MTLDevice> device,double clippedY,const char *prefix){
    CJGuiInternalSession *ctx=ProductionFixture(device);CHECK(ctx!=nil,"existing_production_fixture");if(!ctx)return;
    ctx.ownedTextSessionEnabled=NO;ctx.rangeTextEditDeltaDeliveryEnabled=NO;
    CHECK(SubmitActiveClip(ctx,2,100,592,NO,@"Narrow"),"initial_visible_scene");
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:401],"original_focus");
    char initial[64],returned[64];snprintf(initial,sizeof(initial),"%s_initial",prefix);snprintf(returned,sizeof(returned),"%s_returned",prefix);
    CHECK(ActiveClipInk(ctx,initial)>80,"initial_glyph_pixels");
    CHECK(SubmitActiveClip(ctx,3,clippedY,424,YES,@""),"focused_same_identity_moves_outside_clip");
    [ctx.composableSceneOverlay.inputProxy insertText:@"H" replacementRange:NSMakeRange(6,0)];
    CHECK([ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"NarrowH"],"one_native_commit_keeps_exact_body");
    CHECK(SubmitActiveClip(ctx,4,100,424,YES,@""),"same_active_source_returns_to_visible_clip");
    CHECK(ActiveClipInk(ctx,returned)>80,"returned_focused_glyph_pixels");
    CHECK(ctx.composableSceneOverlay.activeNodeId==401 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"NarrowH"],"identity_and_text_still_exact");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static void ActiveSameWidthMove(id<MTLDevice> device){
    CJGuiInternalSession *ctx=ProductionFixture(device);CHECK(ctx!=nil,"same_width_fixture");if(!ctx)return;
    ctx.ownedTextSessionEnabled=NO;ctx.rangeTextEditDeltaDeliveryEnabled=NO;
    CHECK(SubmitActiveClip(ctx,2,100,424,NO,@"Narrow"),"same_width_initial_scene");
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:401],"same_width_original_focus");
    CHECK(ActiveClipInk(ctx,"move_initial")>80,"same_width_initial_glyphs");
    CJGuiInternalComposableSceneNode *original=ctx.composableNodes[0];
    id<MTLTexture> texture=original.textTexture;
    id credential=original.textTextureSourceCredential;
    NSRect oldRect=original.textTextureRect;
    NSPoint oldOrigin=original.textTileLayoutOrigin;
    uint64_t rasters=ctx.view.textRasterCount;
    CHECK(SubmitActiveClip(ctx,3,220,424,YES,@""),"same_width_same_body_visible_move");
    CHECK(ActiveClipInk(ctx,"move_returned")>80,"same_width_moved_glyphs_at_new_bounds");
    CJGuiInternalComposableSceneNode *moved=ctx.composableNodes[0];
    CHECK(ActiveClipLastOldInk==0,"same_width_old_bounds_have_no_glyphs");
    CHECK(moved.textTexture==texture && moved.textTextureSourceCredential==credential,
        "same_width_reuses_pixels_and_original_raster_credential");
    CHECK(ctx.view.textRasterCount==rasters,"same_width_move_does_not_rasterize");
    CHECK(NSEqualRects(moved.textTextureRect,NSMakeRect(20,220,424,40)) &&
        NSEqualPoints(moved.textTileLayoutOrigin,NSMakePoint(20,220)),"same_width_destination_adopted");
    CHECK(moved!=original && NSEqualRects(original.textTextureRect,oldRect) &&
        NSEqualPoints(original.textTileLayoutOrigin,oldOrigin),"same_width_accepted_source_not_mutated");
    CHECK(ctx.composableSceneOverlay.activeNodeId==401 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"Narrow"],"same_width_identity_and_body_preserved");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
int main(void){@autoreleasepool{
    [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 2;
    ActiveClipScenario(device,-80,"outside");ActiveClipScenario(device,-39,"edge");ActiveSameWidthMove(device);
    fprintf(stderr,"active_clip failures=%d\n",failures);return failures?1:0;
}}
