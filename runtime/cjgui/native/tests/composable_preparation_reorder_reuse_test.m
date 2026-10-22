// Same production preparation/commit fixture, with stable identities reordered.
#define main CjguiPreparationReuseFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main

static uint32_t reorderKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
static NSArray<id<MTLTexture>> *reorderTextures(CJGuiInternalComposableSceneNode *node) {
    return CjguiComposableTextTexturesInNodes(@[node]);
}
static BOOL prepareReorder(CJGuiInternalSession *ctx, uint64_t request, uint64_t version,
    BOOL reverse, uint32_t mutation) {
    uint64_t token = ctx.rendererSessionToken;
    if (cjgui_internal_renderer_begin_composable_preparation(token, request,
        ctx.composableSceneVersion, version, 2) != 0) return NO;
    for (uint32_t i = 0; i < 2; i++) {
        uint64_t identity = (reverse ? 1 - i : i) ? 200 : 100;
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = identity; raw.resourceId = identity; raw.projectionVersion = version;
        raw.nodeKind = reorderKind;
        raw.x = 24; raw.y = 40 + i * 36; raw.width = 300; raw.height = 28;
        raw.clipWidth = 480; raw.clipHeight = 320;
        raw.fontSize = 14; raw.textRed = .8; raw.textGreen = .8; raw.textBlue = .8; raw.textAlpha = 1;
        NSString *body = identity == 100 ? @"alpha 中🙂" : @"beta 👩‍👩‍👧‍👦";
        if (identity == 200) {
            if (mutation >= 1) body = [body stringByAppendingString:@"Z"];
            if (mutation >= 2) raw.width = 280;
            if (mutation >= 3) raw.fontSize = 15;
            if (mutation >= 4) raw.textMaxLines = 1;
        }
        CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = identity;
        if (cjgui_internal_renderer_prepare_composable_node(token, request, i, &raw, &geometry,
            "", body.UTF8String, identity == 100 ? "alpha" : "beta", "", "", "", "", "") != 0)
            return NO;
    }
    if (request == 701) {
        for (CJGuiInternalComposableSceneNode *n in ctx.composablePreparation.nodes)
            fprintf(stderr, "REORDER_PACKET node=%llu texture=%p layout=%p credential=%p key=%s\n",
                n.node.nodeId, (__bridge void *)n.textTexture, (__bridge void *)n.preparedTextLayout,
                (__bridge void *)n.textTextureSourceCredential, n.textTextureCacheKey.UTF8String);
    }
    BOOL ready = frameWaitReady(token, request);
    if (request == 701) {
        for (CJGuiInternalComposableSceneNode *n in ctx.composablePreparation.nodes)
            fprintf(stderr, "REORDER_READY node=%llu texture=%p layout=%p credential=%p key=%s\n",
                n.node.nodeId, (__bridge void *)n.textTexture, (__bridge void *)n.preparedTextLayout,
                (__bridge void *)n.textTextureSourceCredential, n.textTextureCacheKey.UTF8String);
    }
    return ready;
}
static void testReorderedKind(uint32_t kind) {
    reorderKind = kind;
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    CHECK(makeSession(&ctx, &token), "reorder_real_preparation_fixture");
    if (!ctx) return;
    CHECK(prepareReorder(ctx, 700, 2, NO, 0) && framePromote(ctx, token, 700),
        "two_distinct_unicode_texts_prepared_and_committed");
    CJGuiInternalComposableSceneNode *a = ctx.composableNodes[0], *b = ctx.composableNodes[1];
    NSArray *aTextures = reorderTextures(a), *bTextures = reorderTextures(b);
    CHECK(aTextures.count > 0 && bTextures.count > 0 && ![aTextures isEqualToArray:bTextures],
        "independent_actual_glyph_resources");
    uint64_t rasters = ctx.view.textRasterCount, uploads = ctx.view.textUploadCount;
    CHECK(prepareReorder(ctx, 701, 3, YES, 0), "position_only_same_identity_candidate_ready");
    CHECK([reorderTextures(ctx.composablePreparation.nodes[0]) isEqualToArray:bTextures] &&
          [reorderTextures(ctx.composablePreparation.nodes[1]) isEqualToArray:aTextures] &&
          ctx.view.textRasterCount == rasters && ctx.view.textUploadCount == uploads,
        "reorder_retains_matching_identity_resources_without_raster_or_upload");
    CHECK(!CjguiTextRasterSourceCredentialsEqual(ctx.composablePreparation.nodes[0].textTextureSourceCredential,
              b.textTextureSourceCredential) &&
          NSEqualPoints(((CjguiTextRasterSourceCredential *)ctx.composablePreparation.nodes[0].textTextureSourceCredential).origin,
              NSMakePoint(24, 40)), "published_source_credential_keeps_exact_current_geometry");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token, 701) == 0 &&
          ctx.composableNodes[0] == a && ctx.composableNodes[1] == b &&
          [reorderTextures(a) isEqualToArray:aTextures] && [reorderTextures(b) isEqualToArray:bTextures],
        "cancel_keeps_accepted_graph_and_resources_untouched");
    CHECK(prepareReorder(ctx, 702, 3, YES, 0) && framePromote(ctx, token, 702),
        "same_identity_reorder_commits_normally");
    CHECK([reorderTextures(ctx.composableNodes[0]) isEqualToArray:bTextures] &&
          [reorderTextures(ctx.composableNodes[1]) isEqualToArray:aTextures],
        "committed_order_keeps_resource_identity");
    for (uint32_t mutation = 1; mutation <= 4; mutation++) {
        NSArray *before = reorderTextures(ctx.composableNodes[0]);
        uint64_t request = 702 + mutation, version = 3 + mutation;
        CHECK(prepareReorder(ctx, request, version, YES, mutation) && framePromote(ctx, token, request),
            "actual_dependency_change_commits");
        CHECK(![reorderTextures(ctx.composableNodes[0]) isEqualToArray:before] &&
              [reorderTextures(ctx.composableNodes[1]) isEqualToArray:aTextures],
            "content_width_font_or_line_limit_invalidates_only_affected_text");
    }
    CjguiReleaseSession(token);
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    testReorderedKind(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT);
    testReorderedKind(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON);
    return failures ? 1 : 0;
} }
