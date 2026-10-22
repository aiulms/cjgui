#define main CjguiPreparationReuseFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main
static uint32_t syncKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
static BOOL syncTextScene(CJGuiInternalSession *ctx,uint64_t version,BOOL reverse,uint32_t mutation,BOOL commit) {
    uint64_t token=ctx.rendererSessionToken;
    if(CjguiConfigureComposableSceneOnMain(token,version,2)!=0)return NO;
    for(uint32_t i=0;i<2;i++) {
        uint64_t identity=(reverse ? 1-i : i) ? 200 : 100;
        CjguiInternalRendererComposableNode raw={0};
        raw.nodeId=identity;raw.resourceId=identity;raw.projectionVersion=version;
        raw.nodeKind=syncKind;
        raw.x=24;raw.y=40+i*36;raw.width=300;raw.height=28;
        raw.clipWidth=480;raw.clipHeight=320;raw.fontSize=14;
        raw.textRed=.8;raw.textGreen=.8;raw.textBlue=.8;raw.textAlpha=1;
        const char *body=identity==100 ? "alpha 中🙂" : "beta 👩‍👩‍👧‍👦";
        NSString *content=@(body);
        if(identity==200) {
            if(mutation>=1)content=[content stringByAppendingString:@"Z"];
            if(mutation>=2)raw.width=280;
            if(mutation>=3)raw.fontSize=15;
            if(mutation>=4)raw.textRed=.4;
            if(mutation>=5){raw.textMaxLines=1;raw.textOverflow=1;}
        }
        body=content.UTF8String;
        if(CjguiSetComposableSceneNodeOnMain(token,i,&raw,"",body,NULL,NULL,0,nil)!=0)return NO;
        CjguiInternalRendererComposableGeometry g={0};g.nodeId=identity;
        if(CjguiSetComposableSceneGeometryOnMain(token,version,i,&g)!=0)return NO;
    }
    return !commit || CjguiCommitComposableSceneOnMain(token)==0;
}
static NSArray *syncTextures(CJGuiInternalComposableSceneNode *node) {
    return CjguiComposableTextTexturesInNodes(@[node]);
}
static void checkKind(uint32_t kind) {
    syncKind=kind;
    CJGuiInternalSession *ctx=nil;uint64_t token=0;
    CHECK(makeSession(&ctx,&token),"sync_normal_fixture");if(!ctx)return;
    CHECK(syncTextScene(ctx,2,NO,0,YES),"sync_initial_committed");
    CJGuiInternalComposableSceneNode *a=ctx.composableNodes[0],*b=ctx.composableNodes[1];
    NSArray *at=syncTextures(a),*bt=syncTextures(b);id credential=b.textTextureSourceCredential;
    uint64_t raster=ctx.view.textRasterCount,upload=ctx.view.textUploadCount;
    CHECK(syncTextScene(ctx,3,YES,0,NO) && CjguiPrepareComposableTextResources(ctx)==0,
        "sync_actual_text_prepare_without_publishing");
    CJGuiInternalComposableSceneNode *staged=ctx.stagedComposableNodes[0];
    CHECK([syncTextures(staged) isEqualToArray:bt] && ctx.view.textRasterCount==raster && ctx.view.textUploadCount==upload,
        "sync_reordered_resource_identity_reuses_actual_textures");
    CHECK(NSEqualPoints(((CjguiTextRasterSourceCredential *)staged.textTextureSourceCredential).origin,NSMakePoint(24,40)) &&
          !CjguiTextRasterSourceCredentialsEqual(credential,staged.textTextureSourceCredential),
        "sync_covered_tiles_publish_current_full_geometry_credential");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(token)==0 &&
          ctx.composableNodes[0]==a && ctx.composableNodes[1]==b &&
          b.textTextureSourceCredential==credential && [syncTextures(a) isEqualToArray:at] && [syncTextures(b) isEqualToArray:bt],
        "sync_cancel_keeps_accepted_nodes_layout_and_resources");
    CHECK(syncTextScene(ctx,3,YES,0,YES) && [syncTextures(ctx.composableNodes[0]) isEqualToArray:bt] &&
          [syncTextures(ctx.composableNodes[1]) isEqualToArray:at] &&
          ctx.view.textRasterCount==raster && ctx.view.textUploadCount==upload,
        "sync_same_identity_reorder_commits_without_raster_or_upload");
    for(uint32_t mutation=1;mutation<=5;mutation++) {
        NSArray *before=syncTextures(ctx.composableNodes[0]);
        CHECK(syncTextScene(ctx,3+mutation,YES,mutation,YES),"sync_real_dependency_change_commits");
        CHECK(![syncTextures(ctx.composableNodes[0]) isEqualToArray:before] &&
              [syncTextures(ctx.composableNodes[1]) isEqualToArray:at],
              "sync_body_width_font_color_line_limit_invalidates_only_changed_text");
    }
    CJGuiInternalComposableSceneNode *old=ctx.composableNodes[0],*untouched=ctx.composableNodes[1];
    NSArray *before=syncTextures(old);id oldProof=old.textTextureSourceCredential;
    CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=9;
    CjguiInternalRendererComposableGeometry geometry=old.geometry, otherGeometry=untouched.geometry;
    CHECK(CjguiConfigureComposableSceneOnMain(token,9,2)==0 &&
          CjguiSetComposableSceneNodeOnMain(token,0,&raw,"","rejected edit",NULL,NULL,0,nil)==0 &&
          CjguiSetComposableSceneGeometryOnMain(token,9,0,&geometry)==0 &&
          CjguiSetComposableSceneGeometryOnMain(token,9,1,&otherGeometry)==0,
          "sync_sparse_candidate_uses_real_COW_setter");
    ctx.forcedComposableTextPreparationFailures=1;
    CHECK(CjguiCommitComposableSceneOnMain(token)!=0 && ctx.forcedComposableTextPreparationFailures==0 && ctx.composableSceneVersion==8 &&
          ctx.composableNodes[0]==old && ctx.composableNodes[1]==untouched &&
          old.textTextureSourceCredential==oldProof && [syncTextures(old) isEqualToArray:before] &&
          [syncTextures(untouched) isEqualToArray:at],"sync_preparation_failure_keeps_accepted_graph_exact");
    (void)cjgui_internal_renderer_discard_composable_scene_candidate(token);
    CHECK(CjguiConfigureComposableSceneOnMain(token,9,2)==0 && ctx.stagedComposableNodes[1]==untouched,
          "sync_unchanged_slot_stays_sparse_and_shared");
    CHECK(CjguiSetComposableSceneGeometryOnMain(token,9,0,&geometry)==0 &&
          CjguiSetComposableSceneGeometryOnMain(token,9,1,&otherGeometry)==0,
          "sync_sparse_geometry_transport_still_covers_all_slots");
    ctx.view.testBackingScaleOverride=1.0;
    CjguiInternalRendererStatus dpiStatus=CjguiCommitComposableSceneOnMain(token);
    fprintf(stderr,"SYNC_DPI status=%d actual_scale=%g source_scale=%g tex0_changed=%d tex1_changed=%d\n",dpiStatus,[ctx.view currentBackingScale],
        ((CjguiTextRasterSourceCredential *)ctx.composableNodes[1].textTextureSourceCredential).scale,
        ![syncTextures(ctx.composableNodes[0]) isEqualToArray:before],![syncTextures(ctx.composableNodes[1]) isEqualToArray:at]);
    CHECK(dpiStatus==0 &&
          ![syncTextures(ctx.composableNodes[0]) isEqualToArray:before] &&
          ![syncTextures(ctx.composableNodes[1]) isEqualToArray:at] &&
          ((CjguiTextRasterSourceCredential *)ctx.composableNodes[1].textTextureSourceCredential).scale==1.0,
          "sync_DPI_change_still_reprepares_and_publishes_current_scale");
    CjguiReleaseSession(token);
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    checkKind(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT);
    checkKind(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON);
    return failures ? 1 : 0;
} }
