// Direct regression for the accepted-layout-only surface visibility diagnostic.
// No window, input injection, or production drawing behavior is exercised.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <string.h>

static int failures = 0;
static int checks = 0;
#define CHECK(condition, name) do { checks++; BOOL ok = (condition); \
    fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name); if (!ok) failures++; } while (0)

static CJGuiInternalComposableSceneNode *VisibilityNode(NSString *body) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 1012; raw.resourceId = 1; raw.projectionVersion = 54;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 180; raw.height = 100; raw.clipWidth = 180; raw.clipHeight = 100;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    node.node = raw; node.value = body;
    node.preparedTextLayout = CjguiPrepareTextNodeLayout(node, body, 1.0, nil, nil);
    return node;
}

static void CompleteLayout(CJGuiInternalComposableSceneNode *node) {
    [node.preparedTextLayout.layoutManager ensureLayoutForTextContainer:node.preparedTextLayout.container];
}

static void SetClip(CJGuiInternalComposableSceneNode *node, NSRect clip) {
    CjguiInternalRendererComposableNode raw = node.node;
    raw.clipX = (float)NSMinX(clip);
    raw.clipY = (float)NSMinY(clip);
    raw.clipWidth = (float)NSWidth(clip);
    raw.clipHeight = (float)NSHeight(clip);
    node.node = raw;
}

int main(void) { @autoreleasepool {
    NSRect viewBounds = NSMakeRect(0, 0, 180, 100);
    setenv("CJGUI_TEXT_SURFACE_TRACE_ALL_FRAMES", "1", 1);
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    CJGuiInternalMetalView *paintView = [[CJGuiInternalMetalView alloc]
        initWithFrame:viewBounds device:device commandQueue:[device newCommandQueue]];
    CJGuiInternalComposableSceneNode *coldPaint = VisibilityNode(@"actual sealed paint");
    id<MTLTexture> painted = CjguiComposableTextTexture(paintView, coldPaint, 1.0, 1.0,
        coldPaint.value, CjguiInternalTextWorkReasonStaticCandidate);
    NSUInteger sourceFrontier = coldPaint.preparedTextLayout.layoutManager.firstUnlaidCharacterIndex;
    CjguiAcceptedTextVisibility coldPaintVisibility =
        CjguiAcceptedTextVisibilityForNode(coldPaint, viewBounds);
    fprintf(stderr, "TEXT_VISIBILITY_REAL_PAINT texture=%u source_frontier=%lu body=%lu available=%u reason=%s\n",
        painted != nil, (unsigned long)sourceFrontier, (unsigned long)coldPaint.value.length,
        coldPaintVisibility.available, coldPaintVisibility.reason);
    CHECK(painted && sourceFrontier < coldPaint.value.length && coldPaintVisibility.available &&
        !coldPaintVisibility.empty && coldPaintVisibility.utf8End == coldPaint.value.length,
        "actual_sealed_raster_visibility_does_not_require_unpainted_source_layout");
    CHECK(sourceFrontier == coldPaint.preparedTextLayout.layoutManager.firstUnlaidCharacterIndex,
        "real_paint_diagnostic_does_not_complete_source_layout");
    // A real short CJK raster uses its painted ink bounds, which are narrower
    // than the accepted layout container. Empty right-side padding is not
    // missing paint; truncating visible glyph ink still has to fail closed.
    CJGuiInternalComposableSceneNode *shortCjk = VisibilityNode(@"甲乙丙丁戊己庚辛壬癸");
    CjguiInternalRendererComposableNode shortRaw = shortCjk.node;
    shortRaw.width = 666; shortRaw.height = 22; shortRaw.clipWidth = 666;
    shortRaw.clipHeight = 100; shortRaw.fontSize = 18;
    shortCjk.node = shortRaw;
    shortCjk.preparedTextLayout = CjguiPrepareTextNodeLayout(shortCjk, shortCjk.value, 1.0, nil, nil);
    id<MTLTexture> shortTexture = CjguiComposableTextTexture(paintView, shortCjk,
        1.0, 1.0, shortCjk.value, CjguiInternalTextWorkReasonStaticCandidate);
    NSRect shortView = NSMakeRect(0, 0, 666, 100);
    CjguiPreparedTextNodeLayout *shortPainter = shortCjk.textVisibilityRasterLayout;
    NSUInteger shortFrontier = shortPainter.layoutManager.firstUnlaidCharacterIndex;
    CjguiAcceptedTextVisibility shortVisibility = CjguiAcceptedTextVisibilityForNode(shortCjk, shortView);
    CHECK(shortTexture && shortVisibility.available && !shortVisibility.empty &&
        shortVisibility.utf8Start == 0 && shortVisibility.utf8End == 30,
        "actual_short_cjk_raster_does_not_require_container_padding_paint");
    CHECK(shortFrontier == shortPainter.layoutManager.firstUnlaidCharacterIndex,
        "short_cjk_visibility_does_not_extend_the_actual_paint_frontier");
    NSRect sealedTextureRect = shortCjk.textTextureRect;
    shortCjk.textTextureRect = NSMakeRect(sealedTextureRect.origin.x, sealedTextureRect.origin.y,
        1, sealedTextureRect.size.height);
    CjguiAcceptedTextVisibility truncatedVisibility = CjguiAcceptedTextVisibilityForNode(shortCjk, shortView);
    CHECK(!truncatedVisibility.available && strcmp(truncatedVisibility.reason, "paint_coverage_incomplete") == 0,
        "missing_visible_glyph_ink_is_still_unavailable");
    shortCjk.textTextureRect = sealedTextureRect;

    NSMutableString *croppedBody = [NSMutableString string];
    for (int line = 0; line < 30; line++) [croppedBody appendString:@"cropped visible line\n"];
    CJGuiInternalComposableSceneNode *croppedPaint = VisibilityNode(croppedBody);
    CjguiInternalRendererComposableNode croppedRaw = croppedPaint.node;
    croppedRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    croppedPaint.node = croppedRaw;
    id<MTLTexture> croppedTexture = CjguiComposableTextTexture(paintView, croppedPaint,
        1.0, 1.0, croppedPaint.value, CjguiInternalTextWorkReasonStaticCandidate);
    CjguiPreparedTextNodeLayout *actualPainter = croppedPaint.textVisibilityRasterLayout;
    NSUInteger painterFrontier = actualPainter.layoutManager.firstUnlaidCharacterIndex;
    CjguiAcceptedTextVisibility croppedVisibility =
        CjguiAcceptedTextVisibilityForNode(croppedPaint, viewBounds);
    fprintf(stderr, "TEXT_VISIBILITY_CROPPED_PAINT texture=%u painter_frontier=%lu body=%lu available=%u reason=%s\n",
        croppedTexture != nil, (unsigned long)painterFrontier, (unsigned long)croppedPaint.value.length,
        croppedVisibility.available, croppedVisibility.reason);
    CHECK(croppedTexture && actualPainter && painterFrontier < croppedPaint.value.length &&
        croppedVisibility.available && !croppedVisibility.empty &&
        croppedVisibility.utf8End < croppedPaint.value.length,
        "actual_cropped_paint_exposes_only_already_drawn_glyphs");
    CHECK(painterFrontier == actualPainter.layoutManager.firstUnlaidCharacterIndex,
        "cropped_paint_diagnostic_does_not_advance_painter_frontier");

    CJGuiInternalComposableSceneNode *padding = VisibilityNode(@"x");
    CompleteLayout(padding);
    CjguiPreparedTextNodeLayout *paddingLayout = padding.preparedTextLayout;
    NSRange allGlyphs = NSMakeRange(0, paddingLayout.layoutManager.numberOfGlyphs);
    NSRect glyphRect = [paddingLayout.layoutManager boundingRectForGlyphRange:allGlyphs
        inTextContainer:paddingLayout.container];
    NSRect textRect = NSOffsetRect(paddingLayout.textRect,
        NSMinX(CjguiComposableVisualNodeRect(padding)), NSMinY(CjguiComposableVisualNodeRect(padding)));
    CGFloat paddingX = NSMaxX(glyphRect) + NSMinX(textRect) + 1.0;
    NSRect rightPadding = NSMakeRect(paddingX, NSMinY(textRect),
        NSMaxX(textRect) - paddingX, NSHeight(textRect));
    SetClip(padding, rightPadding);
    NSRect rightPaddingLocal = NSOffsetRect(rightPadding, -NSMinX(textRect), -NSMinY(textRect));
    NSRange candidateGlyphs = [paddingLayout.layoutManager
        glyphRangeForBoundingRectWithoutAdditionalLayout:rightPaddingLocal
        inTextContainer:paddingLayout.container];
    NSRect candidateBounds = NSZeroRect;
    if (candidateGlyphs.location != NSNotFound && candidateGlyphs.length > 0) {
        candidateBounds = [paddingLayout.layoutManager boundingRectForGlyphRange:candidateGlyphs
            inTextContainer:paddingLayout.container];
    }
    fprintf(stderr, "TEXT_VISIBILITY_PADDING_PROBE clip_local=%.2f,%.2f,%.2f,%.2f candidate_glyphs=%lu:%lu candidate_bounds=%.2f,%.2f,%.2f,%.2f\n",
        NSMinX(rightPaddingLocal),NSMinY(rightPaddingLocal),NSWidth(rightPaddingLocal),NSHeight(rightPaddingLocal),
        (unsigned long)candidateGlyphs.location,(unsigned long)candidateGlyphs.length,
        NSMinX(candidateBounds),NSMinY(candidateBounds),NSWidth(candidateBounds),NSHeight(candidateBounds));
    for (NSUInteger glyph = candidateGlyphs.location;
         candidateGlyphs.location != NSNotFound && glyph < NSMaxRange(candidateGlyphs); glyph++) {
        NSRect glyphBounds = [paddingLayout.layoutManager boundingRectForGlyphRange:NSMakeRange(glyph, 1)
            inTextContainer:paddingLayout.container];
        NSRange lineGlyphs = NSMakeRange(0, 0);
        NSRect lineBounds = [paddingLayout.layoutManager lineFragmentRectForGlyphAtIndex:glyph
            effectiveRange:&lineGlyphs];
        NSRect glyphHit = NSIntersectionRect(glyphBounds, rightPaddingLocal);
        NSRect lineHit = NSIntersectionRect(lineBounds, rightPaddingLocal);
        fprintf(stderr, "TEXT_VISIBILITY_PADDING_GLYPH index=%lu bounds=%.2f,%.2f,%.2f,%.2f glyph_clip=%.2f,%.2f,%.2f,%.2f line=%.2f,%.2f,%.2f,%.2f line_clip=%.2f,%.2f,%.2f,%.2f\n",
            (unsigned long)glyph,NSMinX(glyphBounds),NSMinY(glyphBounds),NSWidth(glyphBounds),NSHeight(glyphBounds),
            NSMinX(glyphHit),NSMinY(glyphHit),NSWidth(glyphHit),NSHeight(glyphHit),
            NSMinX(lineBounds),NSMinY(lineBounds),NSWidth(lineBounds),NSHeight(lineBounds),
            NSMinX(lineHit),NSMinY(lineHit),NSWidth(lineHit),NSHeight(lineHit));
    }
    CjguiAcceptedTextVisibility paddingResult = CjguiAcceptedTextVisibilityForNode(padding, viewBounds);
    fprintf(stderr, "TEXT_VISIBILITY_PADDING_RESULT available=%u empty=%u reason=%s utf8=%lu:%lu\n",
        paddingResult.available,paddingResult.empty,paddingResult.reason,
        (unsigned long)paddingResult.utf8Start,(unsigned long)paddingResult.utf8End);
    CHECK(!NSIsEmptyRect(NSIntersectionRect(textRect, rightPadding)) && paddingResult.available &&
        paddingResult.empty && paddingResult.utf8Start == 0 && paddingResult.utf8End == 0,
        "padding_intersects_text_rect_but_contains_no_visible_glyphs");

    CJGuiInternalComposableSceneNode *visible = VisibilityNode(@"visible");
    CompleteLayout(visible);
    CjguiAcceptedTextVisibility visibleResult = CjguiAcceptedTextVisibilityForNode(visible, viewBounds);
    CHECK(visibleResult.available && !visibleResult.empty && visibleResult.utf8Start == 0 &&
        visibleResult.utf8End == 7, "visible_glyphs_produce_local_utf8_range");

    CJGuiInternalComposableSceneNode *emptyText = VisibilityNode(@"");
    CjguiAcceptedTextVisibility emptyTextResult = CjguiAcceptedTextVisibilityForNode(emptyText, viewBounds);
    CHECK(emptyTextResult.available && emptyTextResult.empty,
        "empty_prepared_text_is_available_empty");

    CJGuiInternalComposableSceneNode *emptyClip = VisibilityNode(@"clipped");
    CompleteLayout(emptyClip);
    SetClip(emptyClip, NSZeroRect);
    CjguiAcceptedTextVisibility emptyClipResult = CjguiAcceptedTextVisibilityForNode(emptyClip, viewBounds);
    CHECK(emptyClipResult.available && emptyClipResult.empty,
        "empty_effective_clip_is_available_empty");

    CJGuiInternalComposableSceneNode *missing = VisibilityNode(@"body");
    missing.preparedTextLayout = nil;
    CjguiAcceptedTextVisibility missingResult = CjguiAcceptedTextVisibilityForNode(missing, viewBounds);
    CHECK(!missingResult.available && strcmp(missingResult.reason, "missing_prepared_layout") == 0,
        "missing_prepared_layout_is_unavailable");

    CJGuiInternalComposableSceneNode *missingValue = VisibilityNode(@"");
    missingValue.value = nil;
    CjguiAcceptedTextVisibility missingValueResult =
        CjguiAcceptedTextVisibilityForNode(missingValue, viewBounds);
    CHECK(!missingValueResult.available && strcmp(missingValueResult.reason, "missing_node_value") == 0,
        "missing_node_value_is_unavailable_even_for_empty_layout");

    CJGuiInternalComposableSceneNode *wrongBody = VisibilityNode(@"original");
    CompleteLayout(wrongBody);
    wrongBody.value = @"replacement";
    CjguiAcceptedTextVisibility wrongBodyResult = CjguiAcceptedTextVisibilityForNode(wrongBody, viewBounds);
    CHECK(!wrongBodyResult.available && strcmp(wrongBodyResult.reason, "prepared_body_mismatch") == 0,
        "prepared_layout_for_different_body_is_unavailable");

    CJGuiInternalComposableSceneNode *incomplete = VisibilityNode(@"not yet laid out");
    // Do not ask TextKit for glyph geometry here. The diagnostic must report
    // the incomplete accepted layout rather than completing it itself.
    NSUInteger firstUnlaidBefore = incomplete.preparedTextLayout.layoutManager.firstUnlaidCharacterIndex;
    CjguiAcceptedTextVisibility incompleteResult = CjguiAcceptedTextVisibilityForNode(incomplete, viewBounds);
    NSUInteger firstUnlaidAfter = incomplete.preparedTextLayout.layoutManager.firstUnlaidCharacterIndex;
    CHECK(!incompleteResult.available && strcmp(incompleteResult.reason, "layout_incomplete") == 0,
        "unfinished_layout_is_unavailable_without_forcing_layout");
    CHECK(firstUnlaidBefore == firstUnlaidAfter && firstUnlaidAfter < incomplete.value.length,
        "diagnostic_does_not_advance_unlaid_character_frontier");

    NSString *unicodeBody = @"A🌍B";
    CJGuiInternalComposableSceneNode *unicode = VisibilityNode(unicodeBody);
    CompleteLayout(unicode);
    CjguiAcceptedTextVisibility unicodeResult = CjguiAcceptedTextVisibilityForNode(unicode, viewBounds);
    CHECK(unicodeResult.available && !unicodeResult.empty && unicodeResult.utf8Start == 0 &&
        unicodeResult.utf8End == 6, "unicode_visible_range_uses_complete_utf8_scalar_boundaries");

    fprintf(stderr, "text_visibility_diagnostic checks=%d failures=%d\n", checks, failures);
    return failures ? 1 : 0;
} }
