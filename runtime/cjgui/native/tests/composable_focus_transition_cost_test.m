#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>
#include <string.h>

typedef struct {
    uint64_t rasterCount;
    uint64_t rasterBytes;
    uint64_t rasterMicros;
    uint64_t uploadCount;
    uint64_t uploadBytes;
    uint64_t uploadMicros;
    uint64_t bodyGeneration;
    uint64_t attributedGeneration;
    uint64_t rangeLayouts;
    uint64_t fullLayouts;
    uint64_t textCallbacks;
    uint64_t selectionCallbacks;
    uint64_t fallbackPasses;
    uint64_t fallbackCharacters;
    uint64_t refreshMicros;
    uint64_t preparationMicros;
    uint64_t fallbackMicros;
    uint64_t decorationMicros;
    uint64_t selectionRevealMicros;
    uint64_t sealedLayoutCount;
    NSUInteger storageLength;
    NSUInteger glyphCount;
    NSUInteger firstUnlaid;
    NSRange selection;
    NSString *key;
    NSString *layoutSignature;
    CGFloat scrollOffset;
    NSData *pixels;
    BOOL textMatches;
} PhaseSnapshot;

static uint64_t nowNs(void) { return CjguiDiagnosticMonotonicNanoseconds(); }

static void warmFonts(void) {
    NSString *seed = @"仓颉🙂abc e\u0301";
    NSFont *font = [NSFont systemFontOfSize:13.0];
    for (NSUInteger i = 0; i < seed.length;) {
        NSRange cluster = [seed rangeOfComposedCharacterSequenceAtIndex:i];
        CTFontRef fallback = CTFontCreateForString((__bridge CTFontRef)font,
            (__bridge CFStringRef)seed, CFRangeMake(cluster.location, cluster.length));
        if (fallback) CFRelease(fallback);
        i = NSMaxRange(cluster);
    }
}

static NSString *exactUtf8Body(NSUInteger targetBytes) {
    NSString *unit = @"仓颉🙂abc e\u0301 row 0123456789\n";
    NSMutableString *body = [NSMutableString string];
    NSUInteger bytes = 0;
    NSUInteger unitBytes = [unit lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    while (bytes + unitBytes <= targetBytes) {
        [body appendString:unit];
        bytes += unitBytes;
    }
    while (bytes < targetBytes) {
        [body appendString:@"x"];
        bytes += 1;
    }
    return body;
}

static CJGuiInternalComposableSceneNode *makeNode(NSString *body, uint64_t nodeId) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.nodeId = nodeId;
    raw.resourceId = 1;
    raw.projectionVersion = 1;
    // Model the product's tall content node clipped to a 680x500 viewport.
    raw.x = 0; raw.y = 0; raw.width = 680; raw.height = 1200;
    raw.clipX = 0; raw.clipY = 0; raw.clipWidth = 680; raw.clipHeight = 500;
    raw.fontSize = 13;
    raw.textRed = 0.08; raw.textGreen = 0.10; raw.textBlue = 0.13;
    raw.textAlpha = 1.0;
    raw.isInteractive = 1;
    node.node = raw;
    node.index = 0;
    node.value = body;
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    return node;
}

static NSData *textureSnapshot(CJGuiInternalComposableSceneNode *node) {
    NSMutableData *result = [NSMutableData data];
    NSArray<id<MTLTexture>> *textures = node.textTileTextures;
    if (textures.count == 0 && node.textTexture) textures = @[node.textTexture];
    if (textures.count == 0) return nil;
    for (id<MTLTexture> texture in textures) {
        if (!texture || texture.pixelFormat != MTLPixelFormatBGRA8Unorm) return nil;
        uint32_t dimensions[2] = {(uint32_t)texture.width, (uint32_t)texture.height};
        [result appendBytes:dimensions length:sizeof(dimensions)];
        NSUInteger rowBytes = texture.width * 4;
        NSMutableData *bytes = [NSMutableData dataWithLength:rowBytes * texture.height];
        [texture getBytes:bytes.mutableBytes bytesPerRow:rowBytes
              fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
        [result appendData:bytes];
    }
    return result;
}

static uint64_t fnv1a(const void *data, NSUInteger length) {
    const uint8_t *bytes = data;
    uint64_t hash = 1469598103934665603ull;
    for (NSUInteger i = 0; i < length; i++) { hash ^= bytes[i]; hash *= 1099511628211ull; }
    return hash;
}

static PhaseSnapshot snapshot(CJGuiInternalSession *session,
                              CJGuiInternalComposableSceneNode *node,
                              NSString *body) {
    CJGuiInternalComposableSceneOverlay *overlay = session.composableSceneOverlay;
    CJGuiInternalMetalView *view = session.view;
    CJGuiInternalComposableInputCallbackTrace *trace = overlay.testInputCallbackTrace;
    NSTextStorage *storage = overlay.inputProxy.textStorage;
    PhaseSnapshot result = {0};
    result.rasterCount = view.testComposableTextRasterCount;
    result.rasterBytes = view.testComposableTextRasterBytes;
    result.rasterMicros = view.testComposableTextRasterMicros;
    result.uploadCount = view.testComposableTextUploadCount;
    result.uploadBytes = view.testComposableTextUploadBytes;
    result.uploadMicros = view.testComposableTextUploadMicros;
    result.bodyGeneration = overlay.activeTextBodyGeneration;
    result.attributedGeneration = overlay.activeTextAttributedGeneration;
    result.rangeLayouts = overlay.activeTextRangeLayoutCount;
    result.fullLayouts = overlay.activeTextFullLayoutCount;
    result.textCallbacks = trace.textCallbackCount;
    result.selectionCallbacks = trace.selectionCallbackCount;
    result.fallbackPasses = trace.fallbackApplyCount;
    result.fallbackCharacters = trace.fallbackCharacters;
    result.refreshMicros = trace.refreshMicros;
    result.preparationMicros = trace.preparationMicros;
    result.fallbackMicros = trace.fallbackMicros;
    result.decorationMicros = trace.decorationsMicros;
    result.selectionRevealMicros = trace.selectionRevealMicros;
    result.sealedLayoutCount = CjguiTestSealedRasterLayoutCreateCount;
    result.storageLength = storage.length;
    result.glyphCount = overlay.inputProxy.layoutManager.numberOfGlyphs;
    result.firstUnlaid = overlay.inputProxy.layoutManager.firstUnlaidCharacterIndex;
    result.selection = overlay.inputProxy.selectedRange;
    result.key = [node.textTextureCacheKey copy] ?: @"";
    result.layoutSignature = [overlay.activeTextLayoutSignature copy] ?: @"";
    result.scrollOffset = [overlay multilineScrollOffsetForNode:node];
    result.pixels = textureSnapshot(node);
    result.textMatches = [storage.string isEqualToString:body];
    return result;
}

static void logPhase(NSUInteger targetBytes, const char *name, uint64_t elapsed,
                     PhaseSnapshot before, PhaseSnapshot after, NSString *body) {
    BOOL keySame = [before.key isEqualToString:after.key];
    BOOL pixelsSame = before.pixels && after.pixels && [before.pixels isEqualToData:after.pixels];
    fprintf(stderr,
        "phase bytes=%lu name=%s elapsed_ns=%llu raster_count=%llu->%llu raster_bytes=%llu->%llu "
        "raster_us=%llu->%llu upload_count=%llu->%llu upload_bytes=%llu->%llu upload_us=%llu->%llu "
        "body_gen=%llu->%llu attr_gen=%llu->%llu key_len=%lu->%lu key_hash=%016llx->%016llx "
        "key_same=%d pixels=%lu->%lu pixels_same=%d storage=%lu text_match=%d "
        "selection=%lu:%lu->%lu:%lu scroll=%.2f layout_sig=%s glyphs=%lu first_unlaid=%lu range_layouts=%llu->%llu "
        "full_layouts=%llu->%llu text_cb=%llu->%llu selection_cb=%llu->%llu "
        "refresh_us=%llu->%llu prep_us=%llu->%llu fallback=%llu/%llu/%llu->%llu/%llu/%llu "
        "decor_us=%llu->%llu reveal_us=%llu->%llu\n",
        (unsigned long)targetBytes, name, (unsigned long long)elapsed,
        (unsigned long long)before.rasterCount, (unsigned long long)after.rasterCount,
        (unsigned long long)before.rasterBytes, (unsigned long long)after.rasterBytes,
        (unsigned long long)before.rasterMicros, (unsigned long long)after.rasterMicros,
        (unsigned long long)before.uploadCount, (unsigned long long)after.uploadCount,
        (unsigned long long)before.uploadBytes, (unsigned long long)after.uploadBytes,
        (unsigned long long)before.uploadMicros, (unsigned long long)after.uploadMicros,
        (unsigned long long)before.bodyGeneration, (unsigned long long)after.bodyGeneration,
        (unsigned long long)before.attributedGeneration, (unsigned long long)after.attributedGeneration,
        (unsigned long)before.key.length, (unsigned long)after.key.length,
        (unsigned long long)fnv1a(before.key.UTF8String, [before.key lengthOfBytesUsingEncoding:NSUTF8StringEncoding]),
        (unsigned long long)fnv1a(after.key.UTF8String, [after.key lengthOfBytesUsingEncoding:NSUTF8StringEncoding]),
        keySame, (unsigned long)before.pixels.length, (unsigned long)after.pixels.length, pixelsSame,
        (unsigned long)after.storageLength, after.textMatches,
        (unsigned long)before.selection.location, (unsigned long)before.selection.length,
        (unsigned long)after.selection.location, (unsigned long)after.selection.length,
        after.scrollOffset, after.layoutSignature.UTF8String,
        (unsigned long)after.glyphCount, (unsigned long)after.firstUnlaid,
        (unsigned long long)before.rangeLayouts, (unsigned long long)after.rangeLayouts,
        (unsigned long long)before.fullLayouts, (unsigned long long)after.fullLayouts,
        (unsigned long long)before.textCallbacks, (unsigned long long)after.textCallbacks,
        (unsigned long long)before.selectionCallbacks, (unsigned long long)after.selectionCallbacks,
        (unsigned long long)before.refreshMicros, (unsigned long long)after.refreshMicros,
        (unsigned long long)before.preparationMicros, (unsigned long long)after.preparationMicros,
        (unsigned long long)before.fallbackPasses, (unsigned long long)before.fallbackCharacters,
        (unsigned long long)before.fallbackMicros, (unsigned long long)after.fallbackPasses,
        (unsigned long long)after.fallbackCharacters, (unsigned long long)after.fallbackMicros,
        (unsigned long long)before.decorationMicros, (unsigned long long)after.decorationMicros,
        (unsigned long long)before.selectionRevealMicros, (unsigned long long)after.selectionRevealMicros);
    (void)body;
}

static void logPixelDifference(NSData *before, NSData *after) {
    const uint8_t *a = before.bytes, *b = after.bytes;
    NSUInteger ai = 0, bi = 0, tile = 0;
    if (!before || !after || before.length == 0 || before.length != after.length) {
        fprintf(stderr, "static_active_pixels comparable=0 before=%lu after=%lu\n",
            (unsigned long)before.length, (unsigned long)after.length);
        return;
    }
    while (ai + 8 <= before.length && bi + 8 <= after.length) {
        uint32_t ad[2], bd[2]; memcpy(ad, a + ai, 8); memcpy(bd, b + bi, 8);
        ai += 8; bi += 8;
        if (ad[0] != bd[0] || ad[1] != bd[1]) {
            fprintf(stderr, "static_active_pixel_tile tile=%lu dimensions=%ux%u/%ux%u incompatible=1\n",
                (unsigned long)tile, ad[0], ad[1], bd[0], bd[1]);
            return;
        }
        NSUInteger bytes = (NSUInteger)ad[0] * (NSUInteger)ad[1] * 4u;
        if (bytes > before.length - ai || bytes > after.length - bi) break;
        uint64_t changedPixels = 0, changedAlpha = 0, changedColor = 0;
        NSUInteger minX = ad[0], minY = ad[1], maxX = 0, maxY = 0;
        for (NSUInteger p = 0; p < bytes; p += 4) {
            BOOL alphaDiff = a[ai + p + 3] != b[bi + p + 3];
            BOOL colorDiff = a[ai + p] != b[bi + p] || a[ai + p + 1] != b[bi + p + 1] ||
                a[ai + p + 2] != b[bi + p + 2];
            if (!alphaDiff && !colorDiff) continue;
            NSUInteger pixel = p / 4, x = pixel % ad[0], y = pixel / ad[0];
            changedPixels++;
            if (alphaDiff) changedAlpha++;
            if (colorDiff) changedColor++;
            minX = MIN(minX, x); minY = MIN(minY, y); maxX = MAX(maxX, x); maxY = MAX(maxY, y);
            if (changedPixels <= 12) {
                fprintf(stderr, "static_active_pixel tile=%lu x=%lu y=%lu static=%u,%u,%u,%u active=%u,%u,%u,%u\n",
                    (unsigned long)tile, (unsigned long)x, (unsigned long)y,
                    a[ai + p], a[ai + p + 1], a[ai + p + 2], a[ai + p + 3],
                    b[bi + p], b[bi + p + 1], b[bi + p + 2], b[bi + p + 3]);
            }
        }
        fprintf(stderr, "static_active_pixel_tile tile=%lu size=%ux%u changed_pixels=%llu "
            "alpha_changed=%llu color_changed=%llu bbox=%s%lu,%lu..%lu,%lu\n",
            (unsigned long)tile, ad[0], ad[1], (unsigned long long)changedPixels,
            (unsigned long long)changedAlpha, (unsigned long long)changedColor,
            changedPixels ? "" : "empty:", (unsigned long)minX, (unsigned long)minY,
            (unsigned long)maxX, (unsigned long)maxY);
        ai += bytes; bi += bytes; tile++;
    }
    fprintf(stderr, "static_active_pixel_summary tiles=%lu parsed_bytes=%lu total_bytes=%lu\n",
        (unsigned long)tile, (unsigned long)ai, (unsigned long)before.length);
}

static void logStaticActiveTextParity(CJGuiInternalComposableSceneNode *node,
                                      CJGuiInternalComposableSceneOverlay *overlay,
                                      NSString *body, NSString *staticKey,
                                      NSArray<NSValue *> *staticTiles,
                                      NSRect staticCoverage, NSPoint staticOrigin,
                                      CGFloat scale, NSData *staticPixels, NSData *activePixels) {
    CjguiPreparedTextNodeLayout *prepared = node.preparedTextLayout;
    NSTextStorage *staticStorage = prepared.storage;
    NSTextStorage *activeStorage = overlay.inputProxy.textStorage;
    NSLayoutManager *staticLayout = prepared.layoutManager;
    NSLayoutManager *activeLayout = overlay.inputProxy.layoutManager;
    NSParagraphStyle *staticParagraph = staticStorage.length > 0
        ? [staticStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] : nil;
    NSParagraphStyle *activeParagraph = activeStorage.length > 0
        ? [activeStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] : nil;
    NSUInteger fontMismatches = 0, colorMismatches = 0, paragraphMismatches = 0;
    NSUInteger firstFontMismatch = NSNotFound, firstColorMismatch = NSNotFound;
    NSUInteger firstParagraphMismatch = NSNotFound;
    NSUInteger length = MIN(staticStorage.length, activeStorage.length);
    NSUInteger fullAttributeMismatchCount = 0;
    for (NSUInteger i = 0; i < length; i++) {
        NSDictionary *sa = [staticStorage attributesAtIndex:i effectiveRange:NULL];
        NSDictionary *aa = [activeStorage attributesAtIndex:i effectiveRange:NULL];
        if (![sa isEqualToDictionary:aa]) {
            fullAttributeMismatchCount++;
            if (fullAttributeMismatchCount == 1) {
                NSMutableSet<NSAttributedStringKey> *keys = [NSMutableSet setWithArray:sa.allKeys];
                [keys addObjectsFromArray:aa.allKeys];
                for (NSAttributedStringKey key in keys) {
                    id sv = sa[key], av = aa[key];
                    if (sv == av || [sv isEqual:av]) continue;
                    NSString *sd = [sv description] ?: @"(nil)";
                    NSString *ad = [av description] ?: @"(nil)";
                    if (sd.length > 180) sd = [[sd substringToIndex:180] stringByAppendingString:@"…"];
                    if (ad.length > 180) ad = [[ad substringToIndex:180] stringByAppendingString:@"…"];
                    fprintf(stderr, "full_attribute_delta char=%lu key=%s static_class=%s static=%s active_class=%s active=%s\n",
                        (unsigned long)i, key.UTF8String,
                        sv ? NSStringFromClass([sv class]).UTF8String : "nil", sd.UTF8String,
                        av ? NSStringFromClass([av class]).UTF8String : "nil", ad.UTF8String);
                }
            }
        }
        if (![sa[NSFontAttributeName] isEqual:aa[NSFontAttributeName]]) {
            fontMismatches++; if (firstFontMismatch == NSNotFound) firstFontMismatch = i;
        }
        if (![sa[NSForegroundColorAttributeName] isEqual:aa[NSForegroundColorAttributeName]]) {
            colorMismatches++; if (firstColorMismatch == NSNotFound) firstColorMismatch = i;
        }
        NSParagraphStyle *sp = sa[NSParagraphStyleAttributeName];
        NSParagraphStyle *ap = aa[NSParagraphStyleAttributeName];
        if (![sp isEqual:ap]) {
            paragraphMismatches++; if (firstParagraphMismatch == NSNotFound) firstParagraphMismatch = i;
        }
    }
    NSRect activeCoverage = CjguiComposableTextTextureRectForNode(node);
    uint64_t plannedBytes = 0;
    NSArray<NSValue *> *activeTiles = CjguiPlanComposableTextTiles(activeCoverage,
        CjguiComposableTextNodeLayoutRect(node), scale, &plannedBytes);
    fprintf(stderr,
        "static_active_layout body_equal=%d static_chars=%lu active_chars=%lu static_font=%s active_base_font=%s "
        "static_container=%.2fx%.2f static_pad=%.2f active_container=%.2fx%.2f active_pad=%.2f "
        "static_noncontiguous=%d active_noncontiguous=%d static_background_layout=%d active_background_layout=%d "
        "static_linebreak=%lu active_linebreak=%lu static_strategy=%lu active_strategy=%lu "
        "font_attr_mismatch_chars=%lu first=%lu color_attr_mismatch_chars=%lu first=%lu "
        "paragraph_attr_mismatch_chars=%lu first=%lu full_attr_mismatch_chars=%lu static_key_len=%lu active_key_len=%lu "
        "scale=%.3f scroll=%.2f static_coverage=%s active_coverage=%s static_origin=%.2f,%.2f active_origin=%.2f,%.2f "
        "static_tiles=%lu active_tiles=%lu tile_rects_equal=%d\n",
        [staticStorage.string isEqualToString:body] && [activeStorage.string isEqualToString:body],
        (unsigned long)staticStorage.length, (unsigned long)activeStorage.length,
        [[staticStorage attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL] fontName].UTF8String,
        overlay.activeTextBaseFont.fontName.UTF8String,
        prepared.container.size.width, prepared.container.size.height, prepared.container.lineFragmentPadding,
        overlay.inputProxy.textContainer.containerSize.width, overlay.inputProxy.textContainer.containerSize.height,
        overlay.inputProxy.textContainer.lineFragmentPadding,
        staticLayout.allowsNonContiguousLayout, activeLayout.allowsNonContiguousLayout,
        staticLayout.backgroundLayoutEnabled, activeLayout.backgroundLayoutEnabled,
        (unsigned long)staticParagraph.lineBreakMode, (unsigned long)activeParagraph.lineBreakMode,
        (unsigned long)staticParagraph.lineBreakStrategy, (unsigned long)activeParagraph.lineBreakStrategy,
        (unsigned long)fontMismatches, (unsigned long)firstFontMismatch,
        (unsigned long)colorMismatches, (unsigned long)firstColorMismatch,
        (unsigned long)paragraphMismatches, (unsigned long)firstParagraphMismatch,
        (unsigned long)fullAttributeMismatchCount,
        (unsigned long)staticKey.length, (unsigned long)node.textTextureCacheKey.length,
        scale, [overlay multilineScrollOffsetForNode:node], NSStringFromRect(staticCoverage).UTF8String,
        NSStringFromRect(activeCoverage).UTF8String, staticOrigin.x, staticOrigin.y,
        node.textTileLayoutOrigin.x, node.textTileLayoutOrigin.y,
        (unsigned long)staticTiles.count, (unsigned long)activeTiles.count,
        [staticTiles isEqualToArray:activeTiles]);
    // The retained attribute and visible-layout objects are compared only
    // after the measured phases so this oracle cannot alter their timings.
    if (staticLayout && activeLayout) {
        [staticLayout ensureLayoutForTextContainer:prepared.container];
        [activeLayout ensureLayoutForTextContainer:overlay.inputProxy.textContainer];
        NSRect firstTile = staticTiles.count > 0 ? staticTiles[0].rectValue : NSZeroRect;
        NSRect contentRect = NSInsetRect(NSMakeRect(0, 0, node.node.width, node.node.height), 7.0, 6.0);
        NSRect tileTextRect = NSIntersectionRect(firstTile, contentRect);
        NSRect tileLayoutRect = NSOffsetRect(tileTextRect, -NSMinX(contentRect), -NSMinY(contentRect));
        fprintf(stderr, "pixel_probe tile0=%s content=%s visible_layout=%s scale=%.1f pixel_bbox=81,500..99,500\n",
            NSStringFromRect(firstTile).UTF8String, NSStringFromRect(contentRect).UTF8String,
            NSStringFromRect(tileLayoutRect).UTF8String, scale);
        NSRect probes[] = {NSMakeRect(32.0, 242.0, 20.0, 10.0), NSMakeRect(32.0, 244.0, 20.0, 8.0),
                           NSMakeRect(32.0, 249.0, 20.0, 3.0)};
        for (NSUInteger probeIndex = 0; probeIndex < sizeof(probes) / sizeof(probes[0]); probeIndex++) {
            NSRange sr = [staticLayout glyphRangeForBoundingRect:probes[probeIndex] inTextContainer:prepared.container];
            NSRange ar = [activeLayout glyphRangeForBoundingRect:probes[probeIndex] inTextContainer:overlay.inputProxy.textContainer];
            NSRange sc = [staticLayout characterRangeForGlyphRange:sr actualGlyphRange:NULL];
            NSRange ac = [activeLayout characterRangeForGlyphRange:ar actualGlyphRange:NULL];
            NSRect sfr = sr.length ? [staticLayout lineFragmentRectForGlyphAtIndex:sr.location effectiveRange:NULL] : NSZeroRect;
            NSRect afr = ar.length ? [activeLayout lineFragmentRectForGlyphAtIndex:ar.location effectiveRange:NULL] : NSZeroRect;
            fprintf(stderr, "pixel_probe_range probe=%lu rect=%s static_glyph=%lu:%lu chars=%lu:%lu line=%s "
                "active_glyph=%lu:%lu chars=%lu:%lu line=%s\n",
                (unsigned long)probeIndex, NSStringFromRect(probes[probeIndex]).UTF8String,
                (unsigned long)sr.location, (unsigned long)sr.length,
                (unsigned long)sc.location, (unsigned long)sc.length, NSStringFromRect(sfr).UTF8String,
                (unsigned long)ar.location, (unsigned long)ar.length,
                (unsigned long)ac.location, (unsigned long)ac.length, NSStringFromRect(afr).UTF8String);
        }
        NSUInteger glyphs = MIN(staticLayout.numberOfGlyphs, activeLayout.numberOfGlyphs);
        NSUInteger geometryMismatches = 0, firstGeometryMismatch = NSNotFound;
        for (NSUInteger glyph = 0; glyph < glyphs; glyph++) {
            NSRect sr = [staticLayout lineFragmentRectForGlyphAtIndex:glyph effectiveRange:NULL];
            NSRect ar = [activeLayout lineFragmentRectForGlyphAtIndex:glyph effectiveRange:NULL];
            if (!NSEqualRects(sr, ar)) {
                geometryMismatches++; if (firstGeometryMismatch == NSNotFound) firstGeometryMismatch = glyph;
            }
        }
        fprintf(stderr, "static_active_geometry forced_full_layout=1 static_glyphs=%lu active_glyphs=%lu "
            "line_fragment_mismatch_glyphs=%lu first=%lu static_used=%s active_used=%s\n",
            (unsigned long)staticLayout.numberOfGlyphs, (unsigned long)activeLayout.numberOfGlyphs,
            (unsigned long)geometryMismatches, (unsigned long)firstGeometryMismatch,
            NSStringFromRect([staticLayout usedRectForTextContainer:prepared.container]).UTF8String,
            NSStringFromRect([activeLayout usedRectForTextContainer:overlay.inputProxy.textContainer]).UTF8String);
    }
    logPixelDifference(staticPixels, activePixels);
}

typedef NS_ENUM(NSUInteger, ReuseMutationKind) {
    ReuseMutationBody, ReuseMutationFont, ReuseMutationWidth,
    ReuseMutationRuns, ReuseMutationScale, ReuseMutationCoverage,
    ReuseMutationOriginalFontValue, ReuseMutationOriginalFontMissing,
    ReuseMutationOriginalFontRange
};

static CjguiTextRasterSourceCredential *currentActiveRasterSource(
    CJGuiInternalComposableSceneOverlay *overlay, CJGuiInternalComposableSceneNode *node,
    CGFloat scale) {
    NSRect coverage = CjguiComposableTextTextureRectForNode(node);
    NSArray<NSValue *> *tiles = CjguiPlanComposableTextTiles(coverage,
        CjguiComposableTextNodeLayoutRect(node), scale, NULL);
    return CjguiCreateTextRasterSourceCredential(node, overlay.inputProxy.textStorage,
        overlay.inputProxy.layoutManager, overlay.inputProxy.textContainer, overlay.inputProxy,
        overlay.inputProxy.string ?: @"", scale, coverage, tiles,
        NSMakePoint((CGFloat)node.node.x, (CGFloat)node.node.y),
        [overlay multilineScrollOffsetForNode:node], overlay.activeTextBodyGeneration,
        overlay.activeTextAttributedGeneration);
}

static BOOL runReuseInvalidationCase(id<MTLDevice> device, ReuseMutationKind kind) {
    static const char *names[] = {"body", "font", "width", "runs", "scale", "coverage",
        "original-font-value", "original-font-missing", "original-font-range"};
    @autoreleasepool {
        NSString *body = exactUtf8Body(1024);
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
            device:device commandQueue:[device newCommandQueue]];
        session.composableNodes = [NSMutableArray array];
        session.stagedComposableNodes = [NSMutableArray array];
        session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
        session.composableSceneOverlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 680, 500) session:session];
        session.stagedComposableDataTransferItems = [NSMutableArray array];
        session.stagedComposableDataTransferVersion = 1;
        CJGuiInternalComposableSceneNode *node = makeNode(body, 800 + kind);
        session.stagedComposableNodes = [NSMutableArray arrayWithObject:node];
        session.stagedComposableSceneVersion = 1;
        session.composableTextStyleRunsRaw[@(node.node.nodeId)] = @"";
        uint64_t token = CjguiAllocateSession(session);
        if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) return NO;
        if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) {
            CjguiReleaseSession(token); return NO;
        }

        CJGuiInternalComposableSceneOverlay *overlay = session.composableSceneOverlay;
        [overlay setNodesFromProjection:session.view.composableNodes];
        overlay.activeTextBodyGeneration = 0;
        overlay.activeTextAttributedGeneration = 0;
        PhaseSnapshot beforeFocus = snapshot(session, node, body);
        [overlay focusNode:node enqueue:NO];
        BOOL baselineRaster = session.view.testComposableTextRasterCount > beforeFocus.rasterCount &&
            session.view.testComposableTextUploadCount > beforeFocus.uploadCount;
        CGFloat scale = MAX(1.0, [session.view currentBackingScale]);
        CjguiTextRasterSourceCredential *baselineSource = node.textTextureSourceCredential;
        BOOL baselineSourceAccepted = baselineRaster && baselineSource &&
            CjguiTextRasterSourceCredentialsEqual(baselineSource,
                currentActiveRasterSource(overlay, node, scale));
        NSTextStorage *storage = overlay.inputProxy.textStorage;
        BOOL changed = NO;
        switch (kind) {
            case ReuseMutationBody:
                overlay.inputProxy.selectedRange = NSMakeRange(0, 0);
                [storage replaceCharactersInRange:NSMakeRange(storage.length, 0) withString:@" changed"];
                node.value = storage.string;
                changed = ![node.value isEqualToString:body] &&
                    [node.value isEqualToString:overlay.inputProxy.string];
                break;
            case ReuseMutationFont: {
                NSFont *oldFont = [storage attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
                [storage addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:17.0]
                    range:NSMakeRange(0, storage.length)];
                NSFont *newFont = [storage attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
                changed = ![oldFont isEqual:newFont];
                break;
            }
            case ReuseMutationWidth: {
                CjguiInternalRendererComposableNode value = node.node;
                value.width -= 20; node.node = value; changed = value.width != 680;
                break;
            }
            case ReuseMutationRuns: {
                CjguiInternalRendererStatus status = cjgui_internal_renderer_set_composable_text_runs(
                    token, node.node.nodeId, "0:8:18:700:2:0:0:0:1:1:0.1:0.9:0.2:0.8");
                changed = status == CJGUI_INTERNAL_RENDERER_OK &&
                    [node.styleRunsSignature length] > 0 &&
                    [overlay activeTextRunsSignatureForNode:node].length > 0;
                [overlay prepareActiveMultilineFallbackRunsForNode:node];
                break;
            }
            case ReuseMutationScale:
                session.view.testBackingScaleOverride = scale + 1.0;
                changed = [session.view currentBackingScale] != scale;
                break;
            case ReuseMutationCoverage: {
                CjguiInternalRendererComposableNode value = node.node;
                value.clipWidth -= 32; node.node = value; changed = value.clipWidth != 680;
                break;
            }
            case ReuseMutationOriginalFontValue: {
                NSFont *oldFont = [storage attribute:@"NSOriginalFont" atIndex:0 effectiveRange:NULL];
                NSFont *replacement = [NSFont systemFontOfSize:oldFont.pointSize + 1.0];
                [storage addAttribute:@"NSOriginalFont" value:replacement range:NSMakeRange(0, storage.length)];
                NSFont *newFont = [storage attribute:@"NSOriginalFont" atIndex:0 effectiveRange:NULL];
                changed = newFont && ![newFont isEqual:oldFont];
                break;
            }
            case ReuseMutationOriginalFontMissing: {
                BOOL existed = [storage attribute:@"NSOriginalFont" atIndex:0 effectiveRange:NULL] != nil;
                [storage removeAttribute:@"NSOriginalFont" range:NSMakeRange(0, storage.length)];
                changed = existed && [storage attribute:@"NSOriginalFont" atIndex:0 effectiveRange:NULL] == nil;
                break;
            }
            case ReuseMutationOriginalFontRange: {
                NSUInteger target = storage.length / 2;
                NSFont *beforeFont = [storage attribute:@"NSOriginalFont" atIndex:target effectiveRange:NULL];
                NSFont *font = [NSFont systemFontOfSize:27.0];
                [storage addAttribute:@"NSOriginalFont" value:font range:NSMakeRange(target, 1)];
                NSRange effective = NSMakeRange(0, 0);
                NSFont *afterFont = [storage attribute:@"NSOriginalFont" atIndex:target effectiveRange:&effective];
                changed = target < storage.length && effective.location == target && effective.length == 1 &&
                    ![afterFont isEqual:beforeFont];
                break;
            }
        }
        CGFloat actualScale = MAX(1.0, [session.view currentBackingScale]);
        BOOL accepted = CjguiTextRasterSourceCredentialsEqual(baselineSource,
            currentActiveRasterSource(overlay, node, actualScale));
        BOOL rasterAttributesEqual = baselineSource
            ? CjguiAttributedTextRasterAttributesEqual(baselineSource.frozenAttributedBody, storage) : NO;
        fprintf(stderr,
            "reuse_negative case=%s baseline_raster=%d baseline_source=%d changed=%d accepted=%d raster_attributes_equal=%d\n",
            names[kind], baselineRaster, baselineSourceAccepted, changed, accepted, rasterAttributesEqual);
        CjguiReleaseSession(token);
        BOOL checksAttributes = kind == ReuseMutationFont || kind == ReuseMutationBody ||
            kind == ReuseMutationOriginalFontValue || kind == ReuseMutationOriginalFontMissing ||
            kind == ReuseMutationOriginalFontRange;
        return baselineRaster && baselineSourceAccepted && changed && !accepted &&
            (!checksAttributes || !rasterAttributesEqual);
    }
}

static BOOL runReuseInvalidationMatrix(id<MTLDevice> device) {
    BOOL pass = YES;
    for (ReuseMutationKind kind = ReuseMutationBody; kind <= ReuseMutationOriginalFontRange; kind++)
        pass &= runReuseInvalidationCase(device, kind);
    fprintf(stderr, "reuse_negative_matrix result=%s cases=body,font,width,runs,scale,coverage,"
        "original-font-value,original-font-missing,original-font-range\n",
        pass ? "PASS" : "FAIL");
    return pass;
}

static BOOL writeData(NSData *data, NSString *directory, NSString *name) {
    if ([NSProcessInfo.processInfo.environment[@"CJGUI_FOCUS_TRANSITION_SAVE_PIXELS"] isEqualToString:@"0"])
        return data != nil;
    return data && [data writeToFile:[directory stringByAppendingPathComponent:name] atomically:YES];
}

static CJGuiInternalComposableSceneNode *makeButton(NSString *value, uint64_t version) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    raw.nodeId = 990;
    raw.resourceId = 7;
    raw.projectionVersion = version;
    raw.x = 20; raw.y = 20; raw.width = version == 1 ? 180 : 260; raw.height = 44;
    raw.clipX = 0; raw.clipY = 0; raw.clipWidth = 680; raw.clipHeight = 500;
    raw.fontSize = version == 1 ? 13 : 19;
    raw.fontWeight = version == 1 ? 400 : 700;
    raw.textRed = 0.2; raw.textGreen = 0.3; raw.textBlue = 0.4; raw.textAlpha = 1.0;
    raw.isInteractive = 1;
    node.node = raw;
    node.index = 0;
    node.value = value;
    node.label = value;
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    return node;
}

static BOOL runNonTextProjectionProxyGuard(id<MTLDevice> device) {
    CJGuiInternalSession *session = [CJGuiInternalSession new];
    session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
        device:device commandQueue:[device newCommandQueue]];
    session.composableNodes = [NSMutableArray array];
    session.stagedComposableNodes = [NSMutableArray array];
    session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    session.composableDataTransferItems = [NSMutableArray array];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 680, 500) session:session];
    session.composableSceneOverlay = overlay;
    CJGuiInternalComposableSceneNode *button = makeButton(@"Continue", 1);
    overlay.nodes = [NSMutableArray arrayWithObject:button];
    session.composableNodes = [NSMutableArray arrayWithObject:button];
    session.view.composableNodes = @[button];
    overlay.activeNodeId = button.node.nodeId;
    overlay.activeNodeResourceId = button.node.resourceId;
    overlay.activeNodeKind = button.node.nodeKind;
    overlay.activeNodeIndex = button.index;
    overlay.activeProjectionVersion = button.node.projectionVersion;
    overlay.activeTextBodyGeneration = 29;
    overlay.activeTextAttributedGeneration = 37;
    overlay.activeTextLayoutSignature = @"retained-text-layout-sentinel";
    overlay.activeTextRunsSignature = @"retained-runs-sentinel";
    NSString *proxyBody = @"Kept multiline proxy: 仓颉🙂 and retained attributes.";
    overlay.applyingProjection = YES;
    overlay.inputProxy.string = proxyBody;
    overlay.inputProxy.selectedRange = NSMakeRange(7, 4);
    overlay.applyingProjection = NO;
    overlay.inputProxy.textContainer.maximumNumberOfLines = 0;
    overlay.inputProxy.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    overlay.inputProxy.textContainer.containerSize = NSMakeSize(333, CGFLOAT_MAX);
    overlay.inputProxy.textContainer.widthTracksTextView = NO;
    overlay.inputProxy.textContainer.heightTracksTextView = NO;
    overlay.inputProxy.font = [NSFont systemFontOfSize:17.0];
    overlay.inputProxy.textColor = [NSColor systemPurpleColor];
    [overlay.inputProxy.textStorage addAttribute:@"CJGUI_test_retained_marker"
        value:@"proxy-attribute" range:NSMakeRange(0, proxyBody.length)];
    NSDictionary *attributesBefore = [[overlay.inputProxy.textStorage attributesAtIndex:0 effectiveRange:NULL] copy];
    NSDictionary *typingBefore = [overlay.inputProxy.typingAttributes copy];
    NSTextContainer *container = overlay.inputProxy.textContainer;
    NSLayoutManager *layout = overlay.inputProxy.layoutManager;
    NSSize containerSizeBefore = container.containerSize;
    NSUInteger maxLinesBefore = container.maximumNumberOfLines;
    NSLineBreakMode breakModeBefore = container.lineBreakMode;
    BOOL widthTracksBefore = container.widthTracksTextView;
    BOOL heightTracksBefore = container.heightTracksTextView;
    uint64_t rangeLayoutsBefore = overlay.activeTextRangeLayoutCount;
    uint64_t fullLayoutsBefore = overlay.activeTextFullLayoutCount;
    NSUInteger glyphCountBefore = layout.numberOfGlyphs;
    NSUInteger firstUnlaidBefore = layout.firstUnlaidCharacterIndex;
    uint64_t bodyGenBefore = overlay.activeTextBodyGeneration;
    uint64_t attrGenBefore = overlay.activeTextAttributedGeneration;
    NSString *layoutSigBefore = [overlay.activeTextLayoutSignature copy];
    NSString *runsSigBefore = [overlay.activeTextRunsSignature copy];
    NSRange selectionBefore = overlay.inputProxy.selectedRange;
    uint64_t token = CjguiAllocateSession(session);
    if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) return NO;
    CJGuiInternalComposableSceneNode *updated = makeButton(@"Continue now", 2);
    [overlay setNodesFromProjection:@[updated]];
    NSDictionary *attributesAfter = [[overlay.inputProxy.textStorage attributesAtIndex:0 effectiveRange:NULL] copy];
    NSDictionary *typingAfter = [overlay.inputProxy.typingAttributes copy];
    BOOL proxyStringSame = [overlay.inputProxy.string isEqualToString:proxyBody];
    BOOL attributesSame = [attributesAfter isEqualToDictionary:attributesBefore] &&
        [typingAfter isEqualToDictionary:typingBefore];
    BOOL containerSame = overlay.inputProxy.textContainer == container &&
        NSEqualSizes(container.containerSize, containerSizeBefore) &&
        container.maximumNumberOfLines == maxLinesBefore && container.lineBreakMode == breakModeBefore &&
        container.widthTracksTextView == widthTracksBefore && container.heightTracksTextView == heightTracksBefore;
    BOOL layoutSame = overlay.inputProxy.layoutManager == layout &&
        layout.numberOfGlyphs == glyphCountBefore && layout.firstUnlaidCharacterIndex == firstUnlaidBefore &&
        overlay.activeTextRangeLayoutCount == rangeLayoutsBefore && overlay.activeTextFullLayoutCount == fullLayoutsBefore;
    BOOL selectionSame = NSEqualRanges(overlay.inputProxy.selectedRange, selectionBefore);
    BOOL generationsSame = overlay.activeTextBodyGeneration == bodyGenBefore &&
        overlay.activeTextAttributedGeneration == attrGenBefore &&
        [overlay.activeTextLayoutSignature isEqualToString:layoutSigBefore] &&
        [overlay.activeTextRunsSignature isEqualToString:runsSigBefore];
    fprintf(stderr,
        "nontext_projection_proxy old_value=%s new_value=%s string_same=%d attrs_same=%d container_same=%d "
        "layout_same=%d selection_same=%d generations_same=%d body_gen=%llu->%llu attr_gen=%llu->%llu "
        "range_layouts=%llu->%llu glyphs=%lu->%lu selection=%lu:%lu->%lu:%lu result=%s\n",
        button.value.UTF8String, updated.value.UTF8String, proxyStringSame, attributesSame, containerSame,
        layoutSame, selectionSame, generationsSame,
        (unsigned long long)bodyGenBefore, (unsigned long long)overlay.activeTextBodyGeneration,
        (unsigned long long)attrGenBefore, (unsigned long long)overlay.activeTextAttributedGeneration,
        (unsigned long long)rangeLayoutsBefore, (unsigned long long)overlay.activeTextRangeLayoutCount,
        (unsigned long)glyphCountBefore, (unsigned long)layout.numberOfGlyphs,
        (unsigned long)selectionBefore.location, (unsigned long)selectionBefore.length,
        (unsigned long)overlay.inputProxy.selectedRange.location, (unsigned long)overlay.inputProxy.selectedRange.length,
        proxyStringSame && attributesSame && containerSame && layoutSame && selectionSame && generationsSame
            ? "PASS" : "RED_PROXY_RECONCILED_BY_NON_TEXT_PROJECTION");
    CjguiReleaseSession(token);
    return proxyStringSame && attributesSame && containerSame && layoutSame && selectionSame && generationsSame;
}

static BOOL runOne(NSUInteger targetBytes, NSUInteger ordinal, id<MTLDevice> device,
                   NSString *outputDirectory) {
    @autoreleasepool {
        NSString *body = exactUtf8Body(targetBytes);
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
            device:device commandQueue:[device newCommandQueue]];
        session.composableNodes = [NSMutableArray array];
        session.stagedComposableNodes = [NSMutableArray array];
        session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
        session.composableSceneOverlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 680, 500) session:session];
        CJGuiInternalComposableSceneNode *node = makeNode(body, 700 + ordinal);
        session.stagedComposableNodes = [NSMutableArray arrayWithObject:node];
        session.stagedComposableSceneVersion = 1;
        session.stagedComposableDataTransferItems = [NSMutableArray array];
        session.stagedComposableDataTransferVersion = 1;
        session.composableTextStyleRunsRaw[@(node.node.nodeId)] = @"";
        session.composableSceneOverlay.nodes = [NSMutableArray array];
        session.composableSceneOverlay.applyingProjection = YES;
        session.composableSceneOverlay.inputProxy.string = @"";
        session.composableSceneOverlay.applyingProjection = NO;
        uint64_t token = CjguiAllocateSession(session);
        if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) return NO;

        // Commit the production static text resources to the accepted scene on
        // an offscreen session. No window is created or frame submitted.
        uint64_t staticStarted = nowNs();
        CjguiInternalRendererStatus status = CjguiCommitComposableSceneOnMain(token);
        uint64_t staticElapsed = nowNs() - staticStarted;
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            fprintf(stderr, "setup bytes=%lu status=%d static_commit_ns=%llu RED_STATIC_COMMIT\n",
                (unsigned long)targetBytes, (int)status, (unsigned long long)staticElapsed);
            CjguiReleaseSession(token);
            return NO;
        }
        CJGuiInternalComposableSceneOverlay *overlay = session.composableSceneOverlay;
        [overlay setNodesFromProjection:session.view.composableNodes];
        overlay.activeTextBodyGeneration = 0;
        overlay.activeTextAttributedGeneration = 0;
        PhaseSnapshot staticSnapshot = snapshot(session, node, body);
        NSString *staticKey = [node.textTextureCacheKey copy];
        NSArray<NSValue *> *staticTiles = [node.textTileRects copy] ?: @[];
        NSRect staticCoverage = CjguiComposableTextTextureRectForNode(node);
        NSPoint staticOrigin = node.textTileLayoutOrigin;
        CGFloat backingScale = MAX(1.0, [session.view currentBackingScale]);
        NSString *prefix = [NSString stringWithFormat:@"focus-%lu-%lu", (unsigned long)targetBytes,
            (unsigned long)ordinal];
        BOOL staticPixelsSaved = writeData(staticSnapshot.pixels, outputDirectory,
            [prefix stringByAppendingString:@"-static.texture-bytes"]);
        uint64_t staticTextureCount = node.textTileTextures.count ?: (node.textTexture ? 1 : 0);
        fprintf(stderr,
            "stage bytes=%lu actual_utf8=%lu utf16=%lu static_commit_ns=%llu status=%d "
            "static_raster_count=%llu raster_bytes=%llu raster_us=%llu static_upload_count=%llu "
            "upload_bytes=%llu upload_us=%llu static_tiles=%llu static_key_len=%lu body_match=%d\n",
            (unsigned long)targetBytes, (unsigned long)[body lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
            (unsigned long)body.length, (unsigned long long)staticElapsed, (int)status,
            (unsigned long long)staticSnapshot.rasterCount, (unsigned long long)staticSnapshot.rasterBytes,
            (unsigned long long)staticSnapshot.rasterMicros, (unsigned long long)staticSnapshot.uploadCount,
            (unsigned long long)staticSnapshot.uploadBytes, (unsigned long long)staticSnapshot.uploadMicros,
            (unsigned long long)staticTextureCount, (unsigned long)node.textTextureCacheKey.length,
            [node.value isEqualToString:body]);

        if (getenv("CJGUI_TEST_MATCH_LAYOUT_MANAGER_FLAGS")) {
            overlay.inputProxy.layoutManager.allowsNonContiguousLayout = node.preparedTextLayout.layoutManager.allowsNonContiguousLayout;
            overlay.inputProxy.layoutManager.backgroundLayoutEnabled = node.preparedTextLayout.layoutManager.backgroundLayoutEnabled;
            fprintf(stderr, "layout_manager_flag_experiment static_noncontiguous=%d active_noncontiguous=%d "
                "static_background=%d active_background=%d\n",
                node.preparedTextLayout.layoutManager.allowsNonContiguousLayout,
                overlay.inputProxy.layoutManager.allowsNonContiguousLayout,
                node.preparedTextLayout.layoutManager.backgroundLayoutEnabled,
                overlay.inputProxy.layoutManager.backgroundLayoutEnabled);
        }

        uint64_t started = nowNs();
        [overlay focusNode:node enqueue:NO];
        uint64_t firstFocusNs = nowNs() - started;
        PhaseSnapshot firstFocus = snapshot(session, node, body);
        logStaticActiveTextParity(node, overlay, body, staticKey, staticTiles,
            staticCoverage, staticOrigin, backingScale, staticSnapshot.pixels, firstFocus.pixels);
        BOOL firstPixelsSaved = writeData(firstFocus.pixels, outputDirectory,
            [prefix stringByAppendingString:@"-first-focus.texture-bytes"]);
        logPhase(targetBytes, "first-focus", firstFocusNs, staticSnapshot, firstFocus, body);

        // In this windowless fixture, makeFirstResponder cannot deliver the
        // platform's initial caret reveal. Run the same native reveal+refresh
        // explicitly, then use that accepted viewport as the pure-selection
        // baseline below.
        PhaseSnapshot beforeReveal = firstFocus;
        started = nowNs();
        [overlay revealActiveMultilineCaret:node];
        [overlay refreshGpuTextForActiveInput];
        uint64_t revealNs = nowNs() - started;
        PhaseSnapshot focusedViewport = snapshot(session, node, body);
        BOOL focusedViewportSaved = writeData(focusedViewport.pixels, outputDirectory,
            [prefix stringByAppendingString:@"-revealed-focus.texture-bytes"]);
        logPhase(targetBytes, "initial-caret-reveal-and-refresh", revealNs,
            beforeReveal, focusedViewport, body);

        started = nowNs();
        [overlay focusNode:node enqueue:NO];
        uint64_t sameFocusNs = nowNs() - started;
        PhaseSnapshot sameFocus = snapshot(session, node, body);
        BOOL samePixelsSaved = writeData(sameFocus.pixels, outputDirectory,
            [prefix stringByAppendingString:@"-same-focus.texture-bytes"]);
        logPhase(targetBytes, "same-node-focus", sameFocusNs, focusedViewport, sameFocus, body);

        // Keep the caret in the viewport already revealed by the focused end
        // selection. This isolates a pure selection move from scroll changes.
        NSUInteger caret = body.length > 1 ? body.length - 1 : 0;
        if (caret < body.length) {
            NSRange composed = [body rangeOfComposedCharacterSequenceAtIndex:caret];
            caret = composed.location;
        }
        started = nowNs();
        [overlay.inputProxy setSelectedRange:NSMakeRange(caret, 0)];
        uint64_t selectionMoveNs = nowNs() - started;
        PhaseSnapshot selectionMove = snapshot(session, node, body);
        BOOL selectionPixelsSaved = writeData(selectionMove.pixels, outputDirectory,
            [prefix stringByAppendingString:@"-selection-move.texture-bytes"]);
        logPhase(targetBytes, "selection-only-move", selectionMoveNs, sameFocus, selectionMove, body);

        BOOL strictPixelsSame = staticSnapshot.pixels && firstFocus.pixels &&
            [staticSnapshot.pixels isEqualToData:firstFocus.pixels];
        BOOL firstSemantic = firstFocus.textMatches && firstFocus.storageLength == body.length &&
            firstFocus.pixels.length > 0 && strictPixelsSame;
        BOOL sameSemantic = sameFocus.textMatches && NSEqualRanges(focusedViewport.selection, sameFocus.selection) &&
            focusedViewport.pixels && sameFocus.pixels && [focusedViewport.pixels isEqualToData:sameFocus.pixels];
        BOOL selectionSemantic = selectionMove.textMatches && selectionMove.selection.location == caret &&
            selectionMove.selection.length == 0 && selectionMove.pixels &&
            [focusedViewport.pixels isEqualToData:selectionMove.pixels];
        BOOL firstActiveRasterSemantic = firstFocus.rasterCount > staticSnapshot.rasterCount &&
            firstFocus.uploadCount > staticSnapshot.uploadCount &&
            firstFocus.bodyGeneration > staticSnapshot.bodyGeneration &&
            firstFocus.attributedGeneration > staticSnapshot.attributedGeneration;
        BOOL sealedLayoutReuseSemantic = firstFocus.sealedLayoutCount > staticSnapshot.sealedLayoutCount &&
            focusedViewport.sealedLayoutCount == firstFocus.sealedLayoutCount &&
            sameFocus.sealedLayoutCount == focusedViewport.sealedLayoutCount &&
            selectionMove.sealedLayoutCount == sameFocus.sealedLayoutCount;
        BOOL stableBodyWork = focusedViewport.rasterCount == firstFocus.rasterCount &&
            focusedViewport.uploadCount == firstFocus.uploadCount &&
            sameFocus.rasterCount == focusedViewport.rasterCount && sameFocus.uploadCount == focusedViewport.uploadCount &&
            selectionMove.rasterCount == sameFocus.rasterCount && selectionMove.uploadCount == sameFocus.uploadCount;
        BOOL saved = firstPixelsSaved && focusedViewportSaved && samePixelsSaved && selectionPixelsSaved;
        fprintf(stderr,
            "invariants bytes=%lu first_focus_text_pixels=%d strict_static_active_pixels=%d same_focus_selection_pixels=%d "
            "selection_move_text_range_pixels=%d first_active_raster=%d stable_body_raster_upload=%d "
            "sealed_layouts=%llu/%llu/%llu/%llu/%llu sealed_layout_hot_reuse=%d "
            "saved=%d expected_caret=%lu actual_caret=%lu:%lu "
            "result=%s\n",
            (unsigned long)targetBytes, firstSemantic, strictPixelsSame, sameSemantic, selectionSemantic,
            firstActiveRasterSemantic, stableBodyWork,
            (unsigned long long)staticSnapshot.sealedLayoutCount,
            (unsigned long long)firstFocus.sealedLayoutCount,
            (unsigned long long)focusedViewport.sealedLayoutCount,
            (unsigned long long)sameFocus.sealedLayoutCount,
            (unsigned long long)selectionMove.sealedLayoutCount, sealedLayoutReuseSemantic,
            saved,
            (unsigned long)caret, (unsigned long)selectionMove.selection.location,
            (unsigned long)selectionMove.selection.length,
            firstSemantic && strictPixelsSame && sameSemantic && selectionSemantic &&
            firstActiveRasterSemantic && stableBodyWork && sealedLayoutReuseSemantic && saved
                ? "PASS" : "FAIL");
        CjguiReleaseSession(token);
        return firstSemantic && strictPixelsSame && sameSemantic && selectionSemantic &&
            firstActiveRasterSemantic && stableBodyWork && sealedLayoutReuseSemantic && saved;
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "focus transition cost: no Metal device\n"); return 2; }
        warmFonts();
        NSString *output = NSProcessInfo.processInfo.environment[@"CJGUI_FOCUS_TRANSITION_OUTPUT_DIR"] ?: @".";
        [[NSFileManager defaultManager] createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:nil];
        if (argc == 2 && strcmp(argv[1], "--invalidation-matrix-only") == 0) {
            BOOL matrix = runReuseInvalidationMatrix(device);
            fprintf(stderr, "focus_transition_cost_matrix=%s mode=offscreen-no-window-frame\n",
                matrix ? "PASS" : "FAIL");
            return matrix ? 0 : 1;
        }
        if (argc == 2 && strcmp(argv[1], "--sealed-layout-hot-only") == 0) {
            BOOL hot = runOne(1024, 1, device, output);
            fprintf(stderr, "sealed_layout_hot_probe=%s mode=offscreen-no-window-frame\n",
                hot ? "PASS" : "FAIL");
            return hot ? 0 : 1;
        }
        BOOL nonTextProxyOk = runNonTextProjectionProxyGuard(device);
        BOOL ok = nonTextProxyOk && runOne(1024, 1, device, output) && runOne(2048, 2, device, output) &&
            runReuseInvalidationMatrix(device);
        fprintf(stderr, "focus_transition_cost_probe=%s mode=offscreen-no-window-frame\n", ok ? "PASS" : "FAIL");
        return ok ? 0 : 1;
    }
}
