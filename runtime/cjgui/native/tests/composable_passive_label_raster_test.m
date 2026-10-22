#define main CjguiPreparationReuseFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main
static BOOL declareControl(CJGuiInternalSession *ctx,uint64_t version,uint32_t kind) {
    uint64_t t=ctx.rendererSessionToken;
    if(CjguiConfigureComposableSceneOnMain(t,version,1)!=0)return NO;
    CjguiInternalRendererComposableNode n={0};n.nodeId=100;n.resourceId=1;n.projectionVersion=version;
    n.nodeKind=kind;n.width=280;n.height=42;n.clipWidth=480;n.clipHeight=320;n.fontSize=14;
    n.textRed=.8;n.textGreen=.8;n.textBlue=.8;n.textAlpha=1;
    CjguiInternalRendererComposableGeometry g={0};g.nodeId=100;
    const char *value=kind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ? "true" : "CostA";
    return CjguiSetComposableSceneNodeOnMain(t,0,&n,"Name",value,NULL,NULL,0,nil)==0 &&
        CjguiSetComposableSceneGeometryOnMain(t,version,0,&g)==0 && CjguiCommitComposableSceneOnMain(t)==0;
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    uint32_t kinds[]={CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT};
    for(uint32_t i=0;i<2;i++) {
        CJGuiInternalSession *ctx=nil;uint64_t t=0;CHECK(makeSession(&ctx,&t),"passive_label_fixture");if(!ctx)return 1;
        CHECK(declareControl(ctx,2,kinds[i]),"passive_label_initial_committed");
        CJGuiInternalComposableSceneNode *node=ctx.composableNodes[0];
        CHECK(node.textTextureSourceCredential!=nil &&
              [((CjguiTextRasterSourceCredential *)node.textTextureSourceCredential).body isEqualToString:CjguiComposableGpuTextValue(node)],
              "passive_glyph_credential_seals_actual_painted_label_and_value");
        uint64_t raster=ctx.view.textRasterCount,upload=ctx.view.textUploadCount;
        CHECK(declareControl(ctx,3,kinds[i]),"passive_same_declaration_committed");
        fprintf(stderr,"PASSIVE_LABEL kind=%u raster_delta=%llu upload_delta=%llu\n",kinds[i],ctx.view.textRasterCount-raster,ctx.view.textUploadCount-upload);
        CHECK(ctx.view.textRasterCount==raster && ctx.view.textUploadCount==upload,
              "passive_unchanged_control_does_not_reraster");
        CjguiReleaseSession(t);
    }
    return failures ? 1 : 0;
} }
