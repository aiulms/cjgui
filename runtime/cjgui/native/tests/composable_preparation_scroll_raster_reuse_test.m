#define main CjguiPreparationReuseFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main

static NSArray<id<MTLTexture>> *textures(CJGuiInternalComposableSceneNode *n) {
    return CjguiComposableTextTexturesInNodes(@[n]);
}
static NSArray<NSData *> *pixels(CJGuiInternalComposableSceneNode *n) {
    NSMutableArray *out=[NSMutableArray array];
    for(id<MTLTexture> t in textures(n)) {
        if(t.storageMode==MTLStorageModePrivate) return nil;
        NSUInteger row=t.width*4;
        NSMutableData *data=[NSMutableData dataWithLength:row*t.height];
        [t getBytes:data.mutableBytes bytesPerRow:row fromRegion:MTLRegionMake2D(0,0,t.width,t.height) mipmapLevel:0];
        [out addObject:data];
    }
    return out.count ? out : nil;
}
static BOOL beginText(CJGuiInternalSession *ctx,uint64_t request,uint64_t version,
    CjguiInternalRendererComposableGeometry geometry,NSString *body,BOOL full) {
    uint64_t token=ctx.rendererSessionToken;
    CJGuiInternalComposableSceneNode *a=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=a.node;
    raw.projectionVersion=version;
    if(full) {
        raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x=24;raw.y=40;raw.width=420;raw.height=28;
        raw.clipX=0;raw.clipY=0;raw.clipWidth=480;raw.clipHeight=320;
        raw.fontSize=14;raw.textRed=.8;raw.textGreen=.8;raw.textBlue=.8;raw.textAlpha=1;
    }
    if(cjgui_internal_renderer_begin_composable_preparation(token,request,ctx.composableSceneVersion,version,1)!=0) return NO;
    if(full) return cjgui_internal_renderer_prepare_composable_node(token,request,0,&raw,&geometry,
        "",body.UTF8String,"row","binding-100","row","","row","")==0;
    uint32_t reused=0;
    return cjgui_internal_renderer_reuse_composable_node_batch(token,request,0,1,&raw,&geometry,0,&reused)==0 && reused==1;
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    CHECK(makeSession(&ctx,&token),"scroll_raster_real_preparation_fixture");
    if(!ctx)return 1;
    CjguiInternalRendererComposableGeometry g={0};g.nodeId=100;
    NSString *body=@"row000017 alpha beta gamma delta 中🙂 normal continuous editing.";
    CHECK(beginText(ctx,80,2,g,body,YES) && frameWaitReady(token,80) && framePromote(ctx,token,80),
        "initial_static_TEXT_prepared_and_committed_through_real_owner_path");
    CJGuiInternalComposableSceneNode *accepted=ctx.composableNodes[0];
    NSArray *before=textures(accepted);NSArray *beforePixels=pixels(accepted);
    CjguiPreparedTextNodeLayout *layout=accepted.preparedTextLayout;
    uint64_t sealedBefore=atomic_load(&CjguiTestSealedRasterLayoutCreateCount);
    CHECK(before.count>0 && beforePixels.count==before.count && layout,
        "accepted_TEXT_has_actual_raster_and_query_layout");
    g.translateY=-24;
    CHECK(beginText(ctx,81,3,g,body,NO) && frameWaitReady(token,81),
        "scroll_translation_uses_existing_frozen_geometry_packet");
    CJGuiInternalComposableSceneNode *moved=ctx.composablePreparation.nodes[0];
    CHECK([textures(moved) isEqualToArray:before] && moved.preparedTextLayout==layout &&
        atomic_load(&CjguiTestSealedRasterLayoutCreateCount)==sealedBefore,
        "pure_shader_scroll_retains_actual_glyph_textures_and_layout");
    CHECK(CjguiTextRasterSourceCredentialsEqual(moved.textTextureSourceCredential,
        accepted.textTextureSourceCredential)==NO,
        "full_source_credentials_remain_strict_about_changed_geometry");
    CHECK(framePromote(ctx,token,81),"translated_static_TEXT_really_committed");
    // Ancestor clipping is shader state. These two clips both cover the SAME
    // planned local tile; keep strict source credentials and compare the actual
    // texture bytes against the independent cold oracle below.
    CHECK(beginText(ctx,84,4,g,body,NO),"clip_extent_candidate_begins");
    CJGuiInternalComposableSceneNode *clip=ctx.composablePreparation.nodes[0];
    CjguiInternalRendererComposableNode clipped=clip.node;
    clipped.clipWidth-=50; clipped.clipHeight-=8; clip.node=clipped;
    CHECK(frameWaitReady(token,84),"clip_extent_candidate_prepares");
    CHECK([textures(clip) isEqualToArray:before] && clip.preparedTextLayout==layout &&
        atomic_load(&CjguiTestSealedRasterLayoutCreateCount)==sealedBefore,
        "shader_clip_extent_preserves_covered_local_glyph_tiles");
    CHECK(!CjguiTextRasterSourceCredentialsEqual(clip.textTextureSourceCredential,
        ctx.composableNodes[0].textTextureSourceCredential),"clip_extent_full_proof_remains_strict");
    NSArray *clippedPixels=pixels(clip);
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,84);
    CHECK(beginText(ctx,85,4,g,body,NO),"clip_cold_oracle_begins");
    CJGuiInternalComposableSceneNode *clipCold=ctx.composablePreparation.nodes[0];
    clipCold.node=clipped;CjguiReleaseComposableTextResource(clipCold);clipCold.preparedTextLayout=nil;
    CHECK(frameWaitReady(token,85) && [clippedPixels isEqualToArray:pixels(clipCold)],
        "changed_visible_coverage_retained_tile_bytes_equal_cold_oracle");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,85);
    NSArray *reusePixels=pixels(ctx.composableNodes[0]);
    CHECK(beginText(ctx,82,4,g,body,NO),"cold_oracle_same_final_declaration");
    CJGuiInternalComposableSceneNode *cold=ctx.composablePreparation.nodes[0];
    CjguiReleaseComposableTextResource(cold);cold.preparedTextLayout=nil;
    CHECK(frameWaitReady(token,82),"cold_oracle_prepared_by_real_raster_path");
    CHECK(reusePixels && [reusePixels isEqualToArray:pixels(cold)],
        "translated_retained_glyph_bytes_equal_independent_cold_raster");
    CHECK(![textures(cold) isEqualToArray:textures(ctx.composableNodes[0])],
        "cold_oracle_does_not_consume_the_retained_textures");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,82);
    CHECK(beginText(ctx,83,4,g,@"row000017 DIFFERENT CONTENT 中🙂",YES) && frameWaitReady(token,83),
        "changed_body_keeps_real_preparation_path");
    CHECK(![textures(ctx.composablePreparation.nodes[0]) isEqualToArray:textures(ctx.composableNodes[0])],
        "same_resource_with_changed_body_never_reuses_old_pixels");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token,83);
    for (unsigned variant=0;variant<6;variant++) {
        uint64_t request=90+variant;
        CHECK(beginText(ctx,request,4,g,body,NO),"raster_dependency_negative_begins");
        CJGuiInternalComposableSceneNode *changed=ctx.composablePreparation.nodes[0];
        CjguiInternalRendererComposableNode raw=changed.node;
        if(variant==0)raw.width-=20;
        if(variant==1)raw.fontSize+=2;
        if(variant==2)raw.letterSpacing+=0.5;
        if(variant==3)raw.lineHeightPoints=20;
        if(variant==4)raw.resourceId+=7;
        if(variant==5)raw.textRed=0.1;
        changed.node=raw;
        CHECK(frameWaitReady(token,request),"changed_width_font_typography_identity_color_prepares");
        CHECK(![textures(changed) isEqualToArray:textures(ctx.composableNodes[0])],
            "changed_raster_dependency_does_not_retain_old_pixels");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token,request);
    }
    CjguiReleaseSession(token);
    fprintf(stderr,"scroll_raster summary failures=%d\n",failures);
    return failures ? 1 : 0;
} }

