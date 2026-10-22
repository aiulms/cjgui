// Ordinary synchronous publication repeats all run declarations before the
// sparse node writes. An unchanged declaration must preserve accepted COW
// nodes, while a changed/cleared declaration still owns an isolated candidate.
#define main SparseRunsPreviousFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main

static const char *sparseBodies[] = {"alpha 中文👩🏽‍💻", "beta 中🙂", "gamma é"};
static const char *sparseRuns = "0:4:22:0:1:1:0:0:1:0:0:0:0:0";

static BOOL sparseDeclarations(uint64_t token, const char *middle) {
    for (uint32_t i = 0; i < 3; i++) {
        if (cjgui_internal_renderer_set_composable_text_runs(token, 100 + i * 100,
            i == 1 ? middle : "") != 0) return NO;
    }
    return YES;
}

static BOOL sparseInitial(CJGuiInternalSession *ctx, uint64_t token) {
    if (CjguiConfigureComposableSceneOnMain(token, 2, 3) != 0 || !sparseDeclarations(token, "")) return NO;
    for (uint32_t i = 0; i < 3; i++) {
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 100 + i * 100; raw.resourceId = (int64_t)raw.nodeId;
        raw.projectionVersion = 2; raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x = 24; raw.y = 24 + 60 * i; raw.width = 320; raw.height = 48;
        raw.clipWidth = 480; raw.clipHeight = 320; raw.fontSize = 14;
        raw.textRed = .9; raw.textGreen = .9; raw.textBlue = .9; raw.textAlpha = 1;
        CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = raw.nodeId;
        if (CjguiSetComposableSceneNodeOnMain(token, i, &raw, "", sparseBodies[i], NULL, NULL, 0, nil) != 0 ||
            CjguiSetComposableSceneGeometryOnMain(token, 2, i, &geometry) != 0) return NO;
    }
    return CjguiCommitComposableSceneOnMain(token) == 0;
}

static BOOL sparseGeometry(CJGuiInternalSession *ctx, uint64_t token, uint64_t version) {
    for (uint32_t i = 0; i < 3; i++) {
        CjguiInternalRendererComposableGeometry geometry = ctx.composableNodes[i].geometry;
        if (CjguiSetComposableSceneGeometryOnMain(token, version, i, &geometry) != 0) return NO;
    }
    return YES;
}

#ifndef CJGUI_SPARSE_RUNS_NO_MAIN
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    CHECK(makeSession(&ctx, &token) && sparseInitial(ctx, token), "sparse_runs_actual_initial_scene");
    if (!ctx || ctx.composableNodes.count != 3) return 1;
    NSArray *accepted = [ctx.composableNodes copy];
    CJGuiInternalComposableSceneNode *untouched = accepted[1], *other = accepted[2];
    NSArray *untouchedTextures = CjguiComposableTextTexturesInNodes(@[untouched]);
    id untouchedLayout = untouched.preparedTextLayout;
    uint64_t clones = ctx.composableSceneCloneCount;
    CHECK(CjguiConfigureComposableSceneOnMain(token, 3, 3) == 0 && sparseDeclarations(token, ""),
        "sparse_runs_repeat_complete_empty_declarations");
    fprintf(stderr, "sparse_runs repeated_clones=%llu nodes=3\n",
        (unsigned long long)(ctx.composableSceneCloneCount - clones));
    CHECK(ctx.composableSceneCloneCount == clones && ctx.stagedComposableNodes[1] == untouched &&
        ctx.stagedComposableNodes[2] == other, "sparse_runs_unchanged_publication_does_not_clone_static_nodes");
    CJGuiInternalComposableSceneNode *first = accepted[0];
    CjguiInternalRendererComposableNode raw = first.node; raw.projectionVersion = 3;
    CHECK(CjguiSetComposableSceneNodeOnMain(token, 0, &raw, "", "edited 中文👩🏽‍💻", NULL, NULL, 0, nil) == 0 &&
        sparseGeometry(ctx, token, 3) && CjguiCommitComposableSceneOnMain(token) == 0,
        "sparse_runs_local_value_commits_through_real_setter");
    CHECK(ctx.composableSceneCloneCount == clones + 1 && ctx.composableNodes[1] == untouched &&
        ctx.composableNodes[2] == other && untouched.preparedTextLayout == untouchedLayout &&
        [CjguiComposableTextTexturesInNodes(@[untouched]) isEqualToArray:untouchedTextures],
        "sparse_runs_local_value_retains_unrelated_node_layout_and_textures");

    CHECK(CjguiConfigureComposableSceneOnMain(token, 4, 3) == 0 && sparseDeclarations(token, sparseRuns) &&
        sparseGeometry(ctx, token, 4), "sparse_runs_changed_style_is_staged");
    CHECK(ctx.stagedComposableNodes[1] != untouched && untouched.styleRunsSignature.length == 0,
        "sparse_runs_style_candidate_is_isolated");
    ctx.forcedComposableTextPreparationFailures = 1;
    CHECK(CjguiCommitComposableSceneOnMain(token) != 0 && ctx.forcedComposableTextPreparationFailures == 0 &&
        ctx.composableNodes[1] == untouched && untouched.styleRunsSignature.length == 0 &&
        untouched.preparedTextLayout == untouchedLayout &&
        [CjguiComposableTextTexturesInNodes(@[untouched]) isEqualToArray:untouchedTextures],
        "sparse_runs_failed_style_keeps_accepted_graph_and_resources");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(token) == 0 &&
        CjguiConfigureComposableSceneOnMain(token, 4, 3) == 0 && sparseDeclarations(token, sparseRuns) &&
        sparseGeometry(ctx, token, 4) && CjguiCommitComposableSceneOnMain(token) == 0,
        "sparse_runs_retry_uses_accepted_signature_even_when_transport_table_already_changed");
    CHECK([ctx.composableNodes[1].styleRunsSignature isEqualToString:@(sparseRuns)] &&
        ctx.composableNodes[2] == other &&
        ![CjguiComposableTextTexturesInNodes(@[ctx.composableNodes[1]]) isEqualToArray:untouchedTextures],
        "sparse_runs_real_style_change_invalidates_only_affected_text");
    CJGuiInternalComposableSceneNode *styled = ctx.composableNodes[1];
    clones = ctx.composableSceneCloneCount;
    CHECK(CjguiConfigureComposableSceneOnMain(token, 5, 3) == 0 && sparseDeclarations(token, sparseRuns) &&
        sparseGeometry(ctx, token, 5) && CjguiCommitComposableSceneOnMain(token) == 0 &&
        ctx.composableSceneCloneCount == clones && ctx.composableNodes[1] == styled,
        "sparse_runs_repeat_nonempty_style_retains_accepted_node");
    clones = ctx.composableSceneCloneCount;
    CHECK(CjguiConfigureComposableSceneOnMain(token, 6, 3) == 0 && sparseDeclarations(token, "") &&
        sparseGeometry(ctx, token, 6) && CjguiCommitComposableSceneOnMain(token) == 0 &&
        ctx.composableSceneCloneCount == clones + 1 && ctx.composableNodes[1].styleRunsSignature.length == 0 &&
        ctx.composableNodes[2] == other &&
        ![CjguiComposableTextTexturesInNodes(@[ctx.composableNodes[1]])
            isEqualToArray:CjguiComposableTextTexturesInNodes(@[styled])],
        "sparse_runs_explicit_empty_clears_previous_style_without_cloning_other_nodes");
    CjguiReleaseSession(token);
    return failures ? 1 : 0;
} }
#endif
