// A frozen TextKit painter is the drawing authority. Rasterizing its tiles
// must not resolve the current node font again; fallback must still do so.
#define main CjguiPreparedRasterPriorMain
#import "composable_preparation_batch_test.m"
#undef main

static NSData *pixels(id<MTLTexture> texture) {
    if (!texture) return nil;
    NSUInteger row = texture.width * 4;
    NSMutableData *bytes = [NSMutableData dataWithLength:row * texture.height];
    [texture getBytes:bytes.mutableBytes bytesPerRow:row
        fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
    return bytes;
}

static NSData *draw(CJGuiInternalSession *ctx, CJGuiInternalComposableSceneNode *node,
    NSString *body, NSRect coverage, CjguiPreparedTextNodeLayout *prepared) {
    uint64_t bytes = 0;
    id<MTLTexture> texture = CjguiRasterComposableTextTexture(ctx.view, node, 2, 2,
        body, coverage, &bytes, prepared, CjguiInternalTextWorkReasonStaticCandidate, NULL, 0);
    CHECK(texture && bytes == texture.width * texture.height * 4, "actual_tile_uploaded");
    return pixels(texture);
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    CJGuiInternalComposableSceneNode *node = CjguiCloneComposableSceneNode(ctx, ctx.composableNodes[0], 0, 2);
    CjguiInternalRendererComposableNode raw = node.node;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 300; raw.height = 90; raw.clipWidth = 300; raw.clipHeight = 90;
    raw.fontSize = 14; raw.textRed = .1; raw.textGreen = .2; raw.textBlue = .3; raw.textAlpha = 1;
    node.node = raw; node.styleRunsSignature = @"";
    NSString *body = @"Frozen painter 中文 é 👩🏽‍💻";
    node.value = body;
    CjguiPreparedTextNodeLayout *prepared = CjguiPrepareTextNodeLayout(node, body, 2, nil, ctx);
    CHECK(prepared != nil, "real_frozen_textkit_layout");
    NSRect coverage = NSMakeRect(0, 0, 300, 90);
    gCjguiComposableFontResolutionTestCount = 0;
    NSData *first = draw(ctx, node, body, coverage, prepared);
    CHECK(gCjguiComposableFontResolutionTestCount == 0, "prepared_tile_does_not_resolve_live_font");
    raw.fontSize = 30; raw.textRed = 1; raw.textGreen = 0; raw.textBlue = 0;
    node.node = raw;
    NSData *second = draw(ctx, node, body, coverage, prepared);
    CHECK(first.length && [first isEqualToData:second], "frozen_painter_pixels_survive_live_node_font_and_colour_change");
    CHECK(gCjguiComposableFontResolutionTestCount == 0, "frozen_source_never_queries_replacement_font");
    gCjguiComposableFontResolutionTestCount = 0;
    NSData *fallback = draw(ctx, node, body, coverage, nil);
    CHECK(gCjguiComposableFontResolutionTestCount > 0, "fallback_resolves_its_actual_current_font");
    CHECK(fallback.length == first.length && ![fallback isEqualToData:first], "fallback_uses_current_font_and_colour_pixels");
    CHECK(ctx.view.testComposableTextCpuScratchCurrentBytes == 0, "raster_scratch_released");
    CjguiReleaseSession(token);
    CHECK(cjgui_internal_renderer_occupied_session_count() == 0, "session_lifetime_terminal");
    fprintf(stderr, "prepared_raster_font_query failures=%d\n", failures);
    return failures ? 1 : 0;
} }
