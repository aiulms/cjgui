// Cost RED for current-accepted identity continuity across a prefix slot shift.
// The seven controls are the real TAB_TITLE/TEXT_INPUT/INTEGER_INPUT shapes
// from the filter event; a real prefix node is inserted/removed through the
// production sync configure/set/prepare/commit path. No texture is cleared by
// hand and no control leaves the scene.
#define main CjguiPreparationReuseFixtureMain
#import "composable_preparation_reuse_test.m"
#undef main

typedef struct {
    uint64_t nodeId;
    uint32_t resourceId;
    uint32_t kind;
    double x, y, w, h;
    const char *text;
} ReorderControl;

static const ReorderControl kReorderControls[7] = {
    { 8000000000000000005ULL, 8005, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE,   24,  24, 208, 30, "概览" },
    { 8000000000000000006ULL, 8006, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE,   24,  64, 247, 30, "筛选条件" },
    { 8000000000000000007ULL, 8007, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE,   24, 104, 229, 30, "汇总信息" },
    { 200000016ULL,           2016, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,  24, 160, 684, 38, "COST-2026-1" },
    { 200000018ULL,           2018, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,  24, 210, 140, 38, "ACME01" },
    { 200000019ULL,           2019, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,  24, 260, 684, 38, "SHANGHAI-1" },
    { 200000020ULL,           2020, CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT, 24, 310, 684, 38, "12345" },
};

enum { kReorderMeasuredTransitions = 6 };

typedef struct {
    uint64_t configureUs, setUs, resourceUs, commitUs, totalUs;
    uint64_t rasterDelta, uploadDelta, layoutDelta, sealedDelta;
    uint64_t textureBytes;
    uint32_t preseeded, wrongInherited, emptyInherited, reused;
} ReorderTransition;

typedef struct {
    ReorderTransition rows[kReorderMeasuredTransitions];
    uint64_t resourceUs[kReorderMeasuredTransitions];
    uint64_t totalUs[kReorderMeasuredTransitions];
    uint64_t raster[kReorderMeasuredTransitions];
    uint64_t upload[kReorderMeasuredTransitions];
    uint64_t layout[kReorderMeasuredTransitions];
    uint64_t sealed[kReorderMeasuredTransitions];
    NSArray<NSArray<NSData *> *> *pixels; // per control, final accepted scene
} ReorderArm;

static BOOL makeWideSession(CJGuiInternalSession **outCtx, uint64_t *outToken) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return NO;
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 700)
        device:device commandQueue:[device newCommandQueue]];
    ctx.view.testBackingScaleOverride = 2.0;
    ReusePrepOverlay *overlay = [[ReusePrepOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
    overlay.recordedWindow = [[ReusePrepWindow alloc] initWithContentRect:ctx.view.bounds
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    overlay.recordedWindow.testScale = 2.0;
    overlay.recordedWindow.releasedWhenClosed = NO;
    overlay.recordedWindow.contentView = overlay;
    ctx.window = overlay.recordedWindow;
    ctx.composableSceneOverlay = overlay;
    ctx.composableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    ctx.stagedComposableSceneVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token) return NO;
    ctx.view.sessionToken = token;
    *outCtx = ctx; *outToken = token;
    return YES;
}

static NSArray<id<MTLTexture>> *reorderTextures(CJGuiInternalComposableSceneNode *node) {
    return CjguiComposableTextTexturesInNodes(@[node]);
}

static CJGuiInternalComposableSceneNode *acceptedByIdentity(CJGuiInternalSession *ctx,
    const ReorderControl *control) {
    for (CJGuiInternalComposableSceneNode *node in ctx.composableNodes)
        if (node.node.nodeId == control->nodeId && node.node.resourceId == control->resourceId &&
            node.node.nodeKind == control->kind) return node;
    return nil;
}

static NSData *textureBytes(id<MTLTexture> texture) {
    if (!texture || texture.storageMode == MTLStorageModePrivate) return nil;
    NSUInteger row = texture.width * 4;
    NSMutableData *data = [NSMutableData dataWithLength:row * texture.height];
    [texture getBytes:data.mutableBytes bytesPerRow:row
          fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
    return data;
}

static NSArray<NSData *> *texturePixels(CJGuiInternalComposableSceneNode *node) {
    NSMutableArray *out = [NSMutableArray array];
    for (id<MTLTexture> texture in reorderTextures(node)) {
        NSData *data = textureBytes(texture);
        if (!data) return nil;
        [out addObject:data];
    }
    return out;
}

static BOOL declarePrefix(uint64_t token, uint32_t index, uint64_t version) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 1; raw.resourceId = 1; raw.projectionVersion = version;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    raw.width = 10; raw.height = 10; raw.clipWidth = 1000; raw.clipHeight = 700;
    if (CjguiSetComposableSceneNodeOnMain(token, index, &raw, "", "", NULL, NULL, 0, nil) != 0)
        return NO;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = 1;
    return CjguiSetComposableSceneGeometryOnMain(token, version, index, &geometry) == 0;
}

static BOOL declareControl(uint64_t token, uint32_t index, const ReorderControl *control,
    uint64_t version) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = control->nodeId; raw.resourceId = control->resourceId;
    raw.projectionVersion = version; raw.nodeKind = control->kind;
    raw.x = control->x; raw.y = control->y; raw.width = control->w; raw.height = control->h;
    raw.clipWidth = 1000; raw.clipHeight = 700;
    raw.fontSize = control->kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ? 14 : 13;
    raw.textRed = control->kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ? 0.2 : 0.1;
    raw.textGreen = raw.textRed; raw.textBlue = raw.textRed; raw.textAlpha = 1;
    const char *label = control->kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE
        ? control->text : "";
    const char *value = control->kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE
        ? "tab-page" : control->text;
    if (CjguiSetComposableSceneNodeOnMain(token, index, &raw, label, value,
            NULL, NULL, 0, nil) != 0) return NO;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = control->nodeId;
    return CjguiSetComposableSceneGeometryOnMain(token, version, index, &geometry) == 0;
}

static BOOL sourceHasCompatibleFrozenText(CJGuiInternalSession *ctx,
    CJGuiInternalComposableSceneNode *source, const ReorderControl *control, CGFloat scale) {
    if (!source || !source.preparedTextLayout || !source.textTextureSourceCredential) return NO;
    if (![CjguiComposableGpuTextValue(source) isEqualToString:@(control->text)]) return NO;
    if (source.node.nodeKind != control->kind || source.node.width != control->w ||
        source.node.height != control->h || source.node.fontSize !=
            (control->kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ? 14 : 13))
        return NO;
    if (reorderTextures(source).count == 0 || source.textTextureByteCount == 0) return NO;
    NSString *text = CjguiComposableGpuTextValue(source);
    NSRect textureRect = CjguiComposableTextTextureRectForNode(source);
    uint64_t plannedBytes = 0;
    NSArray<NSValue *> *tiles = CjguiPlanComposableTextTiles(textureRect,
        CjguiComposableTextNodeLayoutRect(source), scale, &plannedBytes);
    if (tiles.count == 0 || plannedBytes != source.textTextureByteCount) return NO;
    NSString *key = CjguiComposableTextTextureKey(source, scale, scale, text, textureRect);
    if (!CjguiComposableTextTilesAlreadyCovered(source, key, tiles, scale)) return NO;
    CjguiTextRasterSourceCredential *current =
        CjguiRetainedLayoutRasterSource(source, scale, text, textureRect, tiles);
    return CjguiTextRasterSourceCredentialsEqual(source.textTextureSourceCredential, current);
}

// Test-only counterfactual: place the SAME current-accepted identity in the
// new slot before the ordinary setter. The setter still runs, commit still
// runs, and CjguiPrepareComposableTextResources still performs its complete
// key/width/scale/credential admission.
static BOOL preseedAcceptedSource(CJGuiInternalSession *ctx, uint32_t index,
    const ReorderControl *control) {
    CJGuiInternalComposableSceneNode *source = acceptedByIdentity(ctx, control);
    if (!source || !source.preparedTextLayout || !source.textTextureSourceCredential) return NO;
    CJGuiInternalComposableSceneNode *copy = CjguiCloneComposableSceneNode(
        ctx, source, index, ctx.stagedComposableSceneVersion);
    if (!copy) return NO;
    ctx.stagedComposableNodes[index] = copy;
    return YES;
}

static uint64_t medianUs(uint64_t *values, uint32_t count) {
    uint64_t sorted[kReorderMeasuredTransitions];
    memcpy(sorted, values, sizeof(uint64_t) * count);
    for (uint32_t i = 1; i < count; i++)
        for (uint32_t j = i; j > 0 && sorted[j - 1] > sorted[j]; j--) {
            uint64_t tmp = sorted[j]; sorted[j] = sorted[j - 1]; sorted[j - 1] = tmp;
        }
    return count ? sorted[count / 2] : 0;
}

static BOOL applyReorderScene(CJGuiInternalSession *ctx, uint64_t version, BOOL withPrefix,
    BOOL counterfactual, ReorderTransition *out) {
    memset(out, 0, sizeof(*out));
    uint64_t token = ctx.rendererSessionToken;
    NSMutableDictionary<NSNumber *, CJGuiInternalComposableSceneNode *> *sources =
        [NSMutableDictionary dictionary];
    for (uint32_t i = 0; i < 7; i++) {
        CJGuiInternalComposableSceneNode *source = acceptedByIdentity(ctx, &kReorderControls[i]);
        if (source) sources[@(kReorderControls[i].nodeId)] = source;
    }
    uint64_t rasterBefore = ctx.view.textRasterCount;
    uint64_t uploadBefore = ctx.view.textUploadCount;
    uint64_t layoutBefore = ctx.composableTextLayoutPreparationCount;
    uint64_t sealedBefore = atomic_load_explicit(&CjguiTestSealedRasterLayoutCreateCount,
        memory_order_relaxed);
    uint64_t start = CjguiMonotonicMicros();
    uint32_t count = withPrefix ? 8 : 7;
    if (CjguiConfigureComposableSceneOnMain(token, version, count) != 0) return NO;
    uint32_t first = withPrefix ? 1 : 0;
    for (uint32_t i = 0; i < 7; i++) {
        uint64_t inherited = ctx.stagedComposableNodes[first + i].node.nodeId;
        if (inherited == 0) out->emptyInherited++;
        else if (inherited != kReorderControls[i].nodeId) out->wrongInherited++;
    }
    uint64_t configured = CjguiMonotonicMicros();
    if (withPrefix && !declarePrefix(token, 0, version)) return NO;
    for (uint32_t i = 0; i < 7; i++) {
        uint32_t index = first + i;
        if (counterfactual && preseedAcceptedSource(ctx, index, &kReorderControls[i]))
            out->preseeded++;
        if (!declareControl(token, index, &kReorderControls[i], version)) return NO;
    }
    uint64_t declared = CjguiMonotonicMicros();
    if (CjguiPrepareComposableTextResources(ctx) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    uint64_t prepared = CjguiMonotonicMicros();
    for (uint32_t i = 0; i < 7; i++) {
        CJGuiInternalComposableSceneNode *staged = ctx.stagedComposableNodes[first + i];
        CJGuiInternalComposableSceneNode *source = sources[@(kReorderControls[i].nodeId)];
        if (source && [reorderTextures(staged) isEqualToArray:reorderTextures(source)])
            out->reused++;
    }
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    uint64_t committed = CjguiMonotonicMicros();
    out->configureUs = configured - start;
    out->setUs = declared - configured;
    out->resourceUs = prepared - declared;
    out->commitUs = committed - prepared;
    out->totalUs = committed - start;
    out->rasterDelta = ctx.view.textRasterCount - rasterBefore;
    out->uploadDelta = ctx.view.textUploadCount - uploadBefore;
    out->layoutDelta = ctx.composableTextLayoutPreparationCount - layoutBefore;
    out->sealedDelta = atomic_load_explicit(&CjguiTestSealedRasterLayoutCreateCount,
        memory_order_relaxed) - sealedBefore;
    for (uint32_t i = 0; i < 7; i++) {
        CJGuiInternalComposableSceneNode *accepted = acceptedByIdentity(ctx, &kReorderControls[i]);
        if (!accepted || ![CjguiComposableGpuTextValue(accepted) isEqualToString:@(kReorderControls[i].text)])
            return NO;
        out->textureBytes += accepted.textTextureByteCount;
    }
    return YES;
}

static BOOL runArm(BOOL counterfactual, ReorderArm *arm, CJGuiInternalSession **outCtx,
    uint64_t *outToken) {
    memset(arm, 0, sizeof(*arm));
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeWideSession(&ctx, &token)) return NO;
    if (!applyReorderScene(ctx, 2, NO, counterfactual, &(ReorderTransition){0})) return NO; // cold A
    if (!applyReorderScene(ctx, 3, YES, counterfactual, &(ReorderTransition){0})) return NO; // warm B
    if (!applyReorderScene(ctx, 4, NO, counterfactual, &(ReorderTransition){0})) return NO; // warm A
    for (uint32_t i = 0; i < kReorderMeasuredTransitions; i++) {
        BOOL prefix = (i % 2) == 0;
        if (!applyReorderScene(ctx, 5 + i, prefix, counterfactual, &arm->rows[i])) return NO;
        arm->resourceUs[i] = arm->rows[i].resourceUs;
        arm->totalUs[i] = arm->rows[i].totalUs;
        arm->raster[i] = arm->rows[i].rasterDelta;
        arm->upload[i] = arm->rows[i].uploadDelta;
        arm->layout[i] = arm->rows[i].layoutDelta;
        arm->sealed[i] = arm->rows[i].sealedDelta;
    }
    NSMutableArray<NSArray<NSData *> *> *pixels = [NSMutableArray array];
    for (uint32_t i = 0; i < 7; i++) {
        CJGuiInternalComposableSceneNode *accepted = acceptedByIdentity(ctx, &kReorderControls[i]);
        NSArray<NSData *> *data = accepted ? texturePixels(accepted) : nil;
        [pixels addObject:data ?: @[]];
    }
    arm->pixels = [pixels copy];
    *outCtx = ctx; *outToken = token;
    return YES;
}

static BOOL sourcesCompatibleBeforeShift(CJGuiInternalSession *ctx) {
    CGFloat scale = [ctx.view currentBackingScale];
    for (uint32_t i = 0; i < 7; i++) {
        CJGuiInternalComposableSceneNode *source = acceptedByIdentity(ctx, &kReorderControls[i]);
        BOOL ok = sourceHasCompatibleFrozenText(ctx, source, &kReorderControls[i], scale);
        fprintf(stderr, "REORDER_SOURCE id=%llu kind=%u compatible=%s texture=%p layout=%p bytes=%llu\n",
            (unsigned long long)kReorderControls[i].nodeId, kReorderControls[i].kind,
            ok ? "PASS" : "FAIL", (__bridge void *)(source.textTexture),
            (__bridge void *)source.preparedTextLayout,
            (unsigned long long)source.textTextureByteCount);
        if (!ok) return NO;
    }
    return YES;
}

static BOOL pixelsEqualAcrossArms(ReorderArm *baseline, ReorderArm *cf) {
    for (uint32_t i = 0; i < 7; i++) {
        NSArray<NSData *> *left = baseline->pixels[i], *right = cf->pixels[i];
        BOOL ok = left.count > 0 && left.count == right.count && [left isEqualToArray:right];
        fprintf(stderr, "REORDER_PIXELS id=%llu tiles=%lu equal=%s\n",
            (unsigned long long)kReorderControls[i].nodeId, (unsigned long)left.count,
            ok ? "PASS" : "FAIL");
        if (!ok) return NO;
    }
    return YES;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *baseCtx = nil, *cfCtx = nil;
    uint64_t baseToken = 0, cfToken = 0;
    CHECK(makeWideSession(&baseCtx, &baseToken), "reorder_cost_wide_session");
    if (!baseCtx) return 1;
    CHECK(applyReorderScene(baseCtx, 2, NO, NO, &(ReorderTransition){0}),
        "reorder_cost_initial_scene_a_committed");
    CHECK(sourcesCompatibleBeforeShift(baseCtx),
        "reorder_same_identity_accepted_source_is_frozen_and_fully_compatible");
    CjguiReleaseSession(baseToken); baseCtx = nil;

    ReorderArm baseline, counterfactual;
    CHECK(runArm(NO, &baseline, &baseCtx, &baseToken), "reorder_cost_baseline_arm_ran");
    CHECK(runArm(YES, &counterfactual, &cfCtx, &cfToken), "reorder_cost_counterfactual_arm_ran");
    if (!baseCtx || !cfCtx) return 1;

    for (uint32_t i = 0; i < kReorderMeasuredTransitions; i++) {
        ReorderTransition *b = &baseline.rows[i], *c = &counterfactual.rows[i];
        fprintf(stderr, "REORDER_ROW i=%u prefix=%d base_us=%llu cf_us=%llu delta_us=%lld "
            "base_raster=%llu cf_raster=%llu base_upload=%llu cf_upload=%llu "
            "base_layout=%llu cf_layout=%llu base_sealed=%llu cf_sealed=%llu "
            "base_wrong=%u base_empty=%u base_reused=%u cf_preseeded=%u cf_reused=%u "
            "base_bytes=%llu cf_bytes=%llu\n",
            i, (i % 2) == 0, (unsigned long long)b->resourceUs,
            (unsigned long long)c->resourceUs,
            (long long)((int64_t)b->resourceUs - (int64_t)c->resourceUs),
            (unsigned long long)b->rasterDelta, (unsigned long long)c->rasterDelta,
            (unsigned long long)b->uploadDelta, (unsigned long long)c->uploadDelta,
            (unsigned long long)b->layoutDelta, (unsigned long long)c->layoutDelta,
            (unsigned long long)b->sealedDelta, (unsigned long long)c->sealedDelta,
            b->wrongInherited, b->emptyInherited, b->reused, c->preseeded, c->reused,
            (unsigned long long)b->textureBytes, (unsigned long long)c->textureBytes);
    }
    uint64_t baseMed = medianUs(baseline.resourceUs, kReorderMeasuredTransitions);
    uint64_t cfMed = medianUs(counterfactual.resourceUs, kReorderMeasuredTransitions);
    uint64_t baseTotal = medianUs(baseline.totalUs, kReorderMeasuredTransitions);
    uint64_t cfTotal = medianUs(counterfactual.totalUs, kReorderMeasuredTransitions);
    uint64_t baseRaster = medianUs(baseline.raster, kReorderMeasuredTransitions);
    uint64_t cfRaster = medianUs(counterfactual.raster, kReorderMeasuredTransitions);
    uint64_t baseUpload = medianUs(baseline.upload, kReorderMeasuredTransitions);
    uint64_t cfUpload = medianUs(counterfactual.upload, kReorderMeasuredTransitions);
    uint64_t baseLayout = medianUs(baseline.layout, kReorderMeasuredTransitions);
    uint64_t cfLayout = medianUs(counterfactual.layout, kReorderMeasuredTransitions);
    uint64_t baseSealed = medianUs(baseline.sealed, kReorderMeasuredTransitions);
    uint64_t cfSealed = medianUs(counterfactual.sealed, kReorderMeasuredTransitions);
    fprintf(stderr, "REORDER_SUMMARY resource_base_us=%llu resource_cf_us=%llu delta_us=%lld "
        "total_base_us=%llu total_cf_us=%llu raster_base=%llu raster_cf=%llu "
        "upload_base=%llu upload_cf=%llu layout_base=%llu layout_cf=%llu "
        "sealed_base=%llu sealed_cf=%llu gate_2ms=%s\n",
        (unsigned long long)baseMed, (unsigned long long)cfMed,
        (long long)((int64_t)baseMed - (int64_t)cfMed),
        (unsigned long long)baseTotal, (unsigned long long)cfTotal,
        (unsigned long long)baseRaster, (unsigned long long)cfRaster,
        (unsigned long long)baseUpload, (unsigned long long)cfUpload,
        (unsigned long long)baseLayout, (unsigned long long)cfLayout,
        (unsigned long long)baseSealed, (unsigned long long)cfSealed,
        (baseMed >= cfMed + 2000) ? "PASS" : "FAIL");
    CHECK(baseline.rows[0].wrongInherited == 6 && baseline.rows[0].emptyInherited == 1 &&
          counterfactual.rows[0].wrongInherited == 6 && counterfactual.rows[0].emptyInherited == 1,
        "prefix_insert_new_slots_inherit_six_other_sources");
    CHECK(baseline.rows[1].wrongInherited == 7 && baseline.rows[1].emptyInherited == 0 &&
          counterfactual.rows[1].wrongInherited == 7 && counterfactual.rows[1].emptyInherited == 0,
        "prefix_remove_new_slots_inherit_seven_other_sources");
    CHECK(baseline.rows[0].rasterDelta >= 7 && baseline.rows[0].uploadDelta >= 7 &&
        baseline.rows[0].layoutDelta >= 7,
        "baseline_really_rerasterizes_the_seven_controls");
    CHECK(counterfactual.rows[0].rasterDelta == 0 && counterfactual.rows[0].uploadDelta == 0 &&
        counterfactual.rows[0].layoutDelta == 0 && counterfactual.rows[0].sealedDelta == 0 &&
        counterfactual.rows[0].reused == 7,
        "counterfactual_reuses_all_seven_through_full_admission");
    CHECK(counterfactual.rows[1].rasterDelta == 0 && counterfactual.rows[1].uploadDelta == 0 &&
        counterfactual.rows[1].layoutDelta == 0 && counterfactual.rows[1].sealedDelta == 0 &&
        counterfactual.rows[1].reused == 7,
        "counterfactual_remove_reuses_all_seven_through_full_admission");
    CHECK(pixelsEqualAcrossArms(&baseline, &counterfactual),
        "reused_glyph_pixels_equal_independent_cold_raster");
    CHECK(baseline.rows[kReorderMeasuredTransitions - 1].textureBytes ==
          counterfactual.rows[kReorderMeasuredTransitions - 1].textureBytes,
        "reuse_keeps_actual_texture_byte_accounting_equal");
    CjguiReleaseSession(baseToken);
    CjguiReleaseSession(cfToken);
    fprintf(stderr, "reorder_cost summary failures=%d\n", failures);
    return failures ? 1 : 0;
} }
