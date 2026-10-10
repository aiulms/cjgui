#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static uint64_t nowNs(void) { return CjguiDiagnosticMonotonicNanoseconds(); }
static BOOL gTallPixelOracleValid = NO;
static BOOL gTallProductionGlyphsBounded = NO;
static BOOL gDecorationClipValid = NO;

static NSString *bodyNearUtf8Target(NSUInteger targetBytes) {
    NSString *line = @"仓颉🙂abc e\u0301 short row 012345\n";
    NSUInteger lineBytes = [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSMutableString *body = [NSMutableString stringWithCapacity:targetBytes];
    NSUInteger bodyBytes = 0;
    while (bodyBytes + lineBytes <= targetBytes) {
        [body appendString:line];
        bodyBytes += lineBytes;
    }
    return body;
}

static void warmCommonFonts(void) {
    NSString *seed = @"仓颉🙂abc e\u0301 مرحبا हिन्दी";
    NSFont *base = [NSFont systemFontOfSize:13.0];
    NSUInteger cursor = 0;
    while (cursor < seed.length) {
        NSRange cluster = [seed rangeOfComposedCharacterSequenceAtIndex:cursor];
        CTFontRef font = CTFontCreateForString((__bridge CTFontRef)base,
            (__bridge CFStringRef)seed, CFRangeMake(cluster.location, cluster.length));
        if (font) CFRelease(font);
        cursor = NSMaxRange(cluster);
    }
}

static CJGuiInternalComposableSceneNode *makeNode(NSString *body, uint64_t nodeId) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.nodeId = nodeId;
    raw.resourceId = 1;
    raw.projectionVersion = 1;
    raw.x = 0; raw.y = 0; raw.width = 680; raw.height = 30000;
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

static NSData *bitmapPixels(NSBitmapImageRep *bitmap) {
    if (!bitmap || !bitmap.bitmapData || bitmap.isPlanar) return nil;
    return [NSData dataWithBytes:bitmap.bitmapData length:bitmap.bytesPerRow * bitmap.pixelsHigh];
}

static BOOL writeBitmap(NSBitmapImageRep *bitmap, NSString *directory, NSString *name) {
    NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return png && [png writeToFile:[directory stringByAppendingPathComponent:name] atomically:YES];
}

static BOOL writeTextureBytes(id<MTLTexture> texture, NSString *directory, NSString *name) {
    if (!texture || texture.pixelFormat != MTLPixelFormatBGRA8Unorm) return NO;
    NSUInteger rowBytes = texture.width * 4;
    NSMutableData *bytes = [NSMutableData dataWithLength:rowBytes * texture.height];
    [texture getBytes:bytes.mutableBytes bytesPerRow:rowBytes
          fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
    return [bytes writeToFile:[directory stringByAppendingPathComponent:name] atomically:YES];
}

static NSBitmapImageRep *newViewportBitmap(void) {
    return [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:680 pixelsHigh:500
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
}

static NSUInteger drawProductionFrame(CJGuiInternalComposableSceneOverlay *overlay,
                                      CJGuiInternalComposableSceneNode *node,
                                      NSBitmapImageRep *bitmap);

static NSUInteger drawBoundedVisibleGlyphs(CJGuiInternalComposableSceneOverlay *overlay,
                                             CJGuiInternalComposableSceneNode *node,
                                             NSBitmapImageRep *bitmap) {
    NSRect rect = CjguiComposableRect(node, overlay);
    NSRect clip = NSIntersectionRect(rect, CjguiComposableClipBounds(node));
    NSRect content = NSInsetRect(rect, 7.0, 6.0);
    NSRect visible = NSIntersectionRect(content, clip);
    NSTextContainer *container = overlay.inputProxy.textContainer;
    NSLayoutManager *layout = overlay.inputProxy.layoutManager;
    CGFloat scroll = [overlay multilineScrollOffsetForNode:node];
    CGFloat topOffset = NSMinY(visible) - NSMinY(content);
    NSRect boundedLayout = NSMakeRect(0, scroll + topOffset, NSWidth(content), NSHeight(visible));
    [overlay ensureActiveLayoutForBoundingRect:boundedLayout container:container layoutManager:layout];
    NSRange range = [layout glyphRangeForBoundingRectWithoutAdditionalLayout:boundedLayout inTextContainer:container];
    if (range.location == NSNotFound) range = NSMakeRange(0, 0);
    NSGraphicsContext *prior = NSGraphicsContext.currentContext;
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    [NSGraphicsContext saveGraphicsState];
    NSRectClip(visible);
    NSPoint origin = NSMakePoint(NSMinX(content), NSMinY(content) - scroll);
    [layout drawBackgroundForGlyphRange:range atPoint:origin];
    [layout drawGlyphsForGlyphRange:range atPoint:origin];
    [NSGraphicsContext restoreGraphicsState];
    [context flushGraphics];
    [NSGraphicsContext setCurrentContext:prior];
    return range.length;
}

static BOOL runClipOracle(CJGuiInternalComposableSceneOverlay *overlay,
                          CJGuiInternalComposableSceneNode *node,
                          CGFloat clipY, CGFloat clipHeight, CGFloat scroll,
                          NSString *name, NSString *output, BOOL *outGlyphsBounded) {
    CjguiInternalRendererComposableNode raw = node.node;
    raw.clipY = clipY;
    raw.clipHeight = clipHeight;
    node.node = raw;
    [overlay setMultilineScrollOffset:scroll forNode:node];
    NSBitmapImageRep *production = newViewportBitmap();
    NSBitmapImageRep *bounded = newViewportBitmap();
    NSUInteger productionGlyphs = drawProductionFrame(overlay, node, production);
    NSUInteger boundedGlyphs = drawBoundedVisibleGlyphs(overlay, node, bounded);
    NSData *productionPixels = bitmapPixels(production);
    NSData *boundedPixels = bitmapPixels(bounded);
    NSUInteger differingBytes = NSUIntegerMax;
    if (productionPixels.length == boundedPixels.length && productionPixels.length > 0) {
        differingBytes = 0;
        const uint8_t *a = productionPixels.bytes;
        const uint8_t *b = boundedPixels.bytes;
        for (NSUInteger i = 0; i < productionPixels.length; i++)
            if (a[i] != b[i]) differingBytes++;
    }
    NSString *productionPNG = [NSString stringWithFormat:@"tall-%@-production-frame.png", name];
    NSString *boundedPNG = [NSString stringWithFormat:@"tall-%@-bounded-frame.png", name];
    NSString *productionRaw = [NSString stringWithFormat:@"tall-%@-production-frame.bitmap-bytes", name];
    NSString *boundedRaw = [NSString stringWithFormat:@"tall-%@-bounded-frame.bitmap-bytes", name];
    BOOL saved = output.length && writeBitmap(production, output, productionPNG) &&
        writeBitmap(bounded, output, boundedPNG) && productionPixels &&
        [productionPixels writeToFile:[output stringByAppendingPathComponent:productionRaw] atomically:YES] &&
        boundedPixels && [boundedPixels writeToFile:[output stringByAppendingPathComponent:boundedRaw] atomically:YES];
    BOOL pixelsEqual = saved && differingBytes == 0;
    BOOL boundedGlyphsOk = productionGlyphs <= boundedGlyphs;
    if (outGlyphsBounded) *outGlyphsBounded = boundedGlyphsOk;
    NSRect visible = NSIntersectionRect(NSInsetRect(CjguiComposableRect(node, overlay), 7.0, 6.0),
        NSIntersectionRect(CjguiComposableRect(node, overlay), CjguiComposableClipBounds(node)));
    NSRect content = NSInsetRect(CjguiComposableRect(node, overlay), 7.0, 6.0);
    CGFloat layoutTop = scroll + NSMinY(visible) - NSMinY(content);
    fprintf(stderr,
        "clip_oracle case=%s clip_y=%.2f clip_h=%.2f scroll=%.2f textkit_y=%.2f textkit_h=%.2f "
        "production_glyphs=%lu bounded_glyphs=%lu diff_bytes=%lu pixel_bytes=%lu pixels=%s glyph_bound=%s\n",
        name.UTF8String, clipY, clipHeight, scroll, layoutTop, NSHeight(visible),
        (unsigned long)productionGlyphs, (unsigned long)boundedGlyphs,
        (unsigned long)differingBytes, (unsigned long)productionPixels.length,
        pixelsEqual ? "EQUAL" : "DIFFERENT_OR_UNSAVED",
        boundedGlyphsOk ? "PASS" : "RED_UNBOUNDED_PRODUCTION_GLYPHS");
    return pixelsEqual;
}

static BOOL rectanglesInside(NSArray<NSValue *> *rectangles, NSRect clip) {
    for (NSValue *value in rectangles) {
        NSRect rect = value.rectValue;
        if (!NSIsEmptyRect(rect) && !NSEqualRects(NSIntersectionRect(rect, clip), rect)) return NO;
    }
    return YES;
}

static BOOL runDecorationClipOracle(CJGuiInternalComposableSceneOverlay *overlay,
                                    CJGuiInternalComposableSceneNode *node,
                                    NSString *body) {
    CjguiInternalRendererComposableNode raw = node.node;
    raw.clipY = 0;
    raw.clipHeight = 500;
    node.node = raw;
    CGFloat scroll = 1200;
    [overlay setMultilineScrollOffset:scroll forNode:node];
    NSRect content = NSInsetRect(CjguiComposableRect(node, overlay), 7.0, 6.0);
    NSRect visible = NSIntersectionRect(content,
        NSIntersectionRect(CjguiComposableRect(node, overlay), CjguiComposableClipBounds(node)));
    NSRect layoutRect = NSMakeRect(0, scroll + NSMinY(visible) - NSMinY(content),
        NSWidth(visible), NSHeight(visible));
    [overlay ensureActiveLayoutForBoundingRect:layoutRect container:overlay.inputProxy.textContainer
                                  layoutManager:overlay.inputProxy.layoutManager];
    NSRange glyphs = [overlay.inputProxy.layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:layoutRect
        inTextContainer:overlay.inputProxy.textContainer];
    NSRange visibleCharacters = glyphs.location == NSNotFound ? NSMakeRange(0, 0) :
        [overlay.inputProxy.layoutManager characterRangeForGlyphRange:glyphs actualGlyphRange:NULL];
    if (visibleCharacters.length < 2) return NO;
    [overlay.inputProxy setSelectedRange:visibleCharacters];
    NSRange selectedForDecoration = overlay.inputProxy.selectedRange;
    uint64_t generationBefore = overlay.activeTextAttributedGeneration;
    uint64_t attrsBefore = overlay.testInputCallbackTrace.wholeAttributeCharacters;
    uint64_t fallbackBefore = overlay.testInputCallbackTrace.fallbackCharacters;
    [overlay updateActiveMultilineTextDecorationsForNode:node];
    BOOL selectionClipped = rectanglesInside(node.textSelectionRects, visible);
    BOOL selectionPresent = node.textSelectionRects.count > 0;
    NSUInteger selectionRectCount = node.textSelectionRects.count;
    BOOL selectionNoMutation = overlay.activeTextAttributedGeneration == generationBefore &&
        overlay.testInputCallbackTrace.wholeAttributeCharacters == attrsBefore &&
        overlay.testInputCallbackTrace.fallbackCharacters == fallbackBefore;

    NSRange markedCharacters = NSMakeRange(visibleCharacters.location, MIN((NSUInteger)2, visibleCharacters.length));
    NSString *sameMarkedText = [body substringWithRange:markedCharacters];
    [overlay.inputProxy setSelectedRange:markedCharacters];
    [overlay.inputProxy setMarkedText:sameMarkedText selectedRange:NSMakeRange(sameMarkedText.length, 0)
                    replacementRange:NSMakeRange(NSNotFound, 0)];
    generationBefore = overlay.activeTextAttributedGeneration;
    attrsBefore = overlay.testInputCallbackTrace.wholeAttributeCharacters;
    fallbackBefore = overlay.testInputCallbackTrace.fallbackCharacters;
    [overlay updateActiveMultilineTextDecorationsForNode:node];
    NSRange actualMarked = overlay.inputProxy.markedRange;
    BOOL markedPresent = overlay.inputProxy.hasMarkedText && actualMarked.location != NSNotFound && actualMarked.length > 0;
    BOOL markedClipped = markedPresent && node.textMarkedRects.count > 0 &&
        rectanglesInside(node.textMarkedRects, visible);
    BOOL caretClipped = NSIsEmptyRect(node.textCaretRect) ||
        NSEqualRects(NSIntersectionRect(node.textCaretRect, visible), node.textCaretRect);
    BOOL markedNoMutation = overlay.activeTextAttributedGeneration == generationBefore &&
        overlay.testInputCallbackTrace.wholeAttributeCharacters == attrsBefore &&
        overlay.testInputCallbackTrace.fallbackCharacters == fallbackBefore;
    fprintf(stderr,
        "decoration_clip_oracle visible=%s scroll=%.2f selection=%lu:%lu selection_chars=%lu:%lu "
        "selection_rects=%lu selection_clipped=%s "
        "marked=%s marked_range=%lu:%lu marked_rects=%lu marked_clipped=%s caret=%s caret_clipped=%s "
        "selection_no_mutation=%s marked_no_mutation=%s result=%s\n",
        NSStringFromRect(visible).UTF8String, scroll, (unsigned long)selectedForDecoration.location,
        (unsigned long)selectedForDecoration.length, (unsigned long)visibleCharacters.location,
        (unsigned long)visibleCharacters.length, (unsigned long)selectionRectCount,
        selectionClipped && selectionPresent ? "yes" : "no",
        overlay.inputProxy.hasMarkedText ? "yes" : "no", (unsigned long)actualMarked.location,
        (unsigned long)actualMarked.length,
        (unsigned long)node.textMarkedRects.count, markedClipped ? "yes" : "no",
        NSStringFromRect(node.textCaretRect).UTF8String, caretClipped ? "yes" : "no",
        selectionNoMutation ? "yes" : "no", markedNoMutation ? "yes" : "no",
        selectionClipped && selectionPresent && markedClipped && caretClipped &&
            selectionNoMutation && markedNoMutation ? "PASS" : "FAIL");
    return selectionClipped && selectionPresent && markedClipped && caretClipped &&
        selectionNoMutation && markedNoMutation;
}

static BOOL rasterClipScenario(CJGuiInternalComposableSceneOverlay *overlay,
                               CJGuiInternalComposableSceneNode *node,
                               NSUInteger sampleIndex, CGFloat clipY, CGFloat clipHeight,
                               CGFloat scroll, NSString *name, NSString *output) {
    CjguiInternalRendererComposableNode raw = node.node;
    raw.clipY = clipY;
    raw.clipHeight = clipHeight;
    node.node = raw;
    [overlay setMultilineScrollOffset:scroll forNode:node];
    uint64_t plannedBytes = 0;
    NSRect coverage = CjguiComposableTextTextureRectForNode(node);
    NSArray<NSValue *> *tiles = CjguiPlanComposableTextTiles(coverage,
        CjguiComposableTextNodeLayoutRect(node), 1.0, &plannedBytes);
    if (tiles.count != 4) {
        fprintf(stderr, "raster_clip_scenario case=%s expected_tiles=4 actual_tiles=%lu RED_SETUP_ERROR\n",
            name.UTF8String, (unsigned long)tiles.count);
        return NO;
    }
    uint64_t started = nowNs();
    uint64_t rasterBefore = overlay.session.view.testComposableTextRasterCount;
    uint64_t totalBytes = 0;
    for (NSUInteger index = 0; index < tiles.count; index++) {
        uint64_t bytes = 0;
        id<MTLTexture> texture = [overlay rasterizeMultilineNode:node active:YES scale:1.0
            tileRect:tiles[index].rectValue outByteCount:&bytes outTextureRect:NULL
            reason:CjguiInternalTextWorkReasonVisibleTileScroll];
        if (!texture || bytes == 0 || !writeTextureBytes(texture, output,
            [NSString stringWithFormat:@"raster-%@-tile-%lu.bgra", name, (unsigned long)index])) return NO;
        totalBytes += bytes;
    }
    uint64_t elapsed = nowNs() - started;
    uint64_t rasterAfter = overlay.session.view.testComposableTextRasterCount;
    fprintf(stderr,
        "raster_clip_scenario case=%s sample=%lu clip_y=%.2f clip_h=%.2f scroll=%.2f "
        "tiles=%lu planned_bytes=%llu raster_bytes=%llu raster_count=%llu->%llu elapsed_ns=%llu\n",
        name.UTF8String, (unsigned long)sampleIndex, clipY, clipHeight, scroll,
        (unsigned long)tiles.count, (unsigned long long)plannedBytes,
        (unsigned long long)totalBytes, (unsigned long long)rasterBefore,
        (unsigned long long)rasterAfter, (unsigned long long)elapsed);
    return rasterAfter - rasterBefore == tiles.count;
}

static NSUInteger drawProductionFrame(CJGuiInternalComposableSceneOverlay *overlay,
                                      CJGuiInternalComposableSceneNode *node,
                                      NSBitmapImageRep *bitmap) {
    NSGraphicsContext *prior = NSGraphicsContext.currentContext;
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    NSUInteger glyphs = 0;
    [overlay drawMultilineNode:node active:YES outLayoutMicros:NULL outDrawMicros:NULL
        outSaveMicros:NULL outClipMicros:NULL outRestoreMicros:NULL outGlyphs:&glyphs];
    [context flushGraphics];
    [NSGraphicsContext setCurrentContext:prior];
    return glyphs;
}

static BOOL measureSample(NSUInteger targetBytes, NSUInteger sampleIndex, id<MTLDevice> device) {
    @autoreleasepool {
        NSString *body = bodyNearUtf8Target(targetBytes);
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
            device:device commandQueue:[device newCommandQueue]];
        session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
        CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 680, 500) session:session];
        session.composableSceneOverlay = overlay;
        CJGuiInternalComposableSceneNode *node = makeNode(body, 400 + sampleIndex);
        overlay.nodes = @[node];
        overlay.activeNodeId = node.node.nodeId;
        overlay.activeNodeResourceId = node.node.resourceId;
        overlay.activeNodeKind = node.node.nodeKind;
        overlay.activeNodeIndex = node.index;
        overlay.activeProjectionVersion = node.node.projectionVersion;
        overlay.activeTextBodyGeneration = 1;
        session.composableTextStyleRunsRaw[@(node.node.nodeId)] = @"";
        overlay.applyingProjection = YES;
        overlay.inputProxy.string = body;
        overlay.inputProxy.selectedRange = NSMakeRange(0, 0);
        overlay.applyingProjection = NO;
        overlay.activeTextFallbackNeedsFullRefresh = YES;
        overlay.activeTextFallbackRunsDirty = YES;

        NSUInteger utf8Bytes = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        NSUInteger utf16Units = body.length;
        NSUInteger composedSequences = 0;
        for (NSUInteger cursor = 0; cursor < body.length;) {
            NSRange cluster = [body rangeOfComposedCharacterSequenceAtIndex:cursor];
            composedSequences++;
            cursor = NSMaxRange(cluster);
        }

        CJGuiInternalComposableInputCallbackTrace *trace = overlay.testInputCallbackTrace;
        uint64_t beforeAttributes = trace.wholeAttributeCharacters;
        uint64_t beforeFallbackChars = trace.fallbackCharacters;
        uint64_t beforeFallbackCount = trace.fallbackApplyCount;
        uint64_t beforeGeneration = overlay.activeTextAttributedGeneration;
        uint64_t start = nowNs();
        [overlay prepareActiveMultilineFallbackRunsForNode:node];
        uint64_t prepareNs = nowNs() - start;
        uint64_t afterGeneration = overlay.activeTextAttributedGeneration;
        uint64_t attributeChars = trace.wholeAttributeCharacters - beforeAttributes;
        uint64_t fallbackChars = trace.fallbackCharacters - beforeFallbackChars;
        uint64_t fallbackCount = trace.fallbackApplyCount - beforeFallbackCount;

        uint64_t hotBeforeFallback = trace.fallbackCharacters;
        uint64_t hotBeforeGeneration = overlay.activeTextAttributedGeneration;
        start = nowNs();
        [overlay prepareActiveMultilineFallbackRunsForNode:node];
        uint64_t hotPrepareNs = nowNs() - start;
        uint64_t hotFallbackChars = trace.fallbackCharacters - hotBeforeFallback;
        uint64_t hotGenerationDelta = overlay.activeTextAttributedGeneration - hotBeforeGeneration;

        NSRect contentRect = NSInsetRect(CjguiComposableRect(node, overlay), 7.0, 6.0);
        overlay.inputProxy.textContainer.containerSize = NSMakeSize(NSWidth(contentRect), CGFLOAT_MAX);
        overlay.inputProxy.textContainer.widthTracksTextView = NO;
        NSLayoutManager *layout = overlay.inputProxy.layoutManager;
        NSRect visibleTextRect = NSIntersectionRect(contentRect,
            NSIntersectionRect(CjguiComposableRect(node, overlay), CjguiComposableClipBounds(node)));
        NSRect visibleLayout = NSMakeRect(0, 0, NSWidth(contentRect), NSHeight(visibleTextRect));
        uint64_t beforeRangeCount = overlay.activeTextRangeLayoutCount;
        uint64_t beforeFullCount = overlay.activeTextFullLayoutCount;
        start = nowNs();
        [overlay ensureActiveLayoutForBoundingRect:visibleLayout
            container:overlay.inputProxy.textContainer layoutManager:layout];
        NSRange visibleGlyphRange = [layout glyphRangeForBoundingRectWithoutAdditionalLayout:visibleLayout
            inTextContainer:overlay.inputProxy.textContainer];
        uint64_t visibleLayoutNs = nowNs() - start;
        uint64_t rangeLayoutDelta = overlay.activeTextRangeLayoutCount - beforeRangeCount;
        uint64_t fullLayoutDelta = overlay.activeTextFullLayoutCount - beforeFullCount;
        NSUInteger visibleGlyphs = visibleGlyphRange.location == NSNotFound ? 0 : visibleGlyphRange.length;
        NSRect naturalUsed = NSZeroRect;

        uint64_t plannedBytes = 0;
        NSRect coverage = CjguiComposableTextTextureRectForNode(node);
        NSArray<NSValue *> *tiles = CjguiPlanComposableTextTiles(coverage,
            CjguiComposableTextNodeLayoutRect(node), 1.0, &plannedBytes);
        NSMutableArray<id<MTLTexture>> *textures = [NSMutableArray array];
        uint64_t rasterBefore = session.view.testComposableTextRasterCount;
        uint64_t rasterBytes = 0;
        start = nowNs();
        for (NSValue *tile in tiles) {
            uint64_t tileBytes = 0;
            id<MTLTexture> texture = [overlay rasterizeMultilineNode:node active:YES scale:1.0
                tileRect:tile.rectValue outByteCount:&tileBytes outTextureRect:NULL
                reason:CjguiInternalTextWorkReasonUnknown];
            if (!texture || tileBytes == 0) return NO;
            [textures addObject:texture];
            rasterBytes += tileBytes;
            if (targetBytes == 65536 && sampleIndex == 0) {
                NSString *output = NSProcessInfo.processInfo.environment[@"CJGUI_COLD_PREPARE_OUTPUT_DIR"];
                if (output.length && !writeTextureBytes(texture, output,
                    [NSString stringWithFormat:@"raster-top-tile-%lu.bgra", (unsigned long)(textures.count - 1)]))
                return NO;
            }
        }
        uint64_t tileRasterNs = nowNs() - start;
        uint64_t rasterAfter = session.view.testComposableTextRasterCount;
        naturalUsed = [layout usedRectForTextContainer:overlay.inputProxy.textContainer];

        BOOL tallOracleOk = YES;
        if (targetBytes == 65536 && sampleIndex == 0) {
            NSString *output = NSProcessInfo.processInfo.environment[@"CJGUI_COLD_PREPARE_OUTPUT_DIR"];
            BOOL partialTiles = rasterClipScenario(overlay, node, sampleIndex, 170, 160, 0,
                @"partial", output);
            BOOL scrollTiles = rasterClipScenario(overlay, node, sampleIndex, 0, 500, 1200,
                @"scroll", output);
            BOOL topBounded = NO, partialBounded = NO, scrollBounded = NO;
            BOOL topPixels = runClipOracle(overlay, node, 0, 500, 0, @"top", output, &topBounded);
            BOOL partialPixels = runClipOracle(overlay, node, 170, 160, 0, @"partial", output, &partialBounded);
            BOOL scrollPixels = runClipOracle(overlay, node, 0, 500, 1200, @"scroll", output, &scrollBounded);
            gDecorationClipValid = runDecorationClipOracle(overlay, node, body);
            gTallPixelOracleValid = topPixels && partialPixels && scrollPixels;
            gTallProductionGlyphsBounded = topBounded && partialBounded && scrollBounded;
            tallOracleOk = gTallPixelOracleValid && partialTiles && scrollTiles;
            fprintf(stderr,
                "tall_pixel_oracles natural_height=%.2f viewport=680x500 artifacts=%s pixels=%s glyph_bound=%s\n",
                NSHeight(naturalUsed), output.fileSystemRepresentation,
                gTallPixelOracleValid ? "PASS" : "FAIL",
                gTallProductionGlyphsBounded ? "PASS" : "RED_UNBOUNDED_PRODUCTION_GLYPHS");
        }

        fprintf(stderr,
            "sample target_bytes=%lu actual_utf8=%lu utf16=%lu composed=%lu instance=%lu "
            "fallback_ns=%llu attributed_gen=%llu->%llu attr_chars=%llu fallback_chars=%llu fallback_passes=%llu "
            "hot_prepare_ns=%llu hot_fallback_chars=%llu hot_generation_delta=%llu "
            "visible_layout_ns=%llu visible_glyphs=%lu range_layout_delta=%llu full_layout_delta=%llu "
            "natural_used_height=%.2f "
            "tiles=%lu planned_bytes=%llu tile_raster_ns=%llu raster_count=%llu->%llu raster_bytes=%llu\n",
            (unsigned long)targetBytes, (unsigned long)utf8Bytes, (unsigned long)utf16Units,
            (unsigned long)composedSequences, (unsigned long)sampleIndex,
            (unsigned long long)prepareNs, (unsigned long long)beforeGeneration,
            (unsigned long long)afterGeneration, (unsigned long long)attributeChars,
            (unsigned long long)fallbackChars, (unsigned long long)fallbackCount,
            (unsigned long long)hotPrepareNs, (unsigned long long)hotFallbackChars,
            (unsigned long long)hotGenerationDelta, (unsigned long long)visibleLayoutNs,
            (unsigned long)visibleGlyphs, (unsigned long long)rangeLayoutDelta,
            (unsigned long long)fullLayoutDelta, NSHeight(naturalUsed), (unsigned long)tiles.count,
            (unsigned long long)plannedBytes, (unsigned long long)tileRasterNs,
            (unsigned long long)rasterBefore, (unsigned long long)rasterAfter,
            (unsigned long long)rasterBytes);
        return fallbackChars == utf16Units && fallbackCount == 1 &&
            hotFallbackChars == 0 && hotGenerationDelta == 0 && tiles.count > 0 &&
            fullLayoutDelta == 0 && rasterAfter - rasterBefore == tiles.count && tallOracleOk;
    }
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "focused cold prepare cost: no Metal device available\n");
            return 2;
        }
        uint64_t warmStarted = nowNs();
        warmCommonFonts();
        uint64_t warmNs = nowNs() - warmStarted;
        fprintf(stderr, "font_warm_ns=%llu (common CJK/emoji/ASCII/combining/Arabic/Devanagari seed)\n",
            (unsigned long long)warmNs);
        const NSUInteger sizes[] = {2048, 8192, 65536};
        BOOL allSamplesValid = YES;
        for (NSUInteger size = 0; size < sizeof(sizes) / sizeof(sizes[0]); size++) {
            for (NSUInteger sample = 0; sample < 3; sample++)
                allSamplesValid &= measureSample(sizes[size], sample, device);
        }
        fprintf(stderr, "cold_prepare_cost_probe=%s clipped_glyph_contract=%s pixel_oracle=%s\n",
            allSamplesValid ? "PASS" : "INVALID_SAMPLE",
            gTallProductionGlyphsBounded ? "PASS" : "RED_UNBOUNDED_PRODUCTION_GLYPHS",
            gTallPixelOracleValid && gDecorationClipValid ? "PASS_EQUAL_PIXELS_AND_DECORATIONS" : "INVALID");
        return allSamplesValid && gTallPixelOracleValid && gTallProductionGlyphsBounded &&
            gDecorationClipValid ? 0 : 1;
    }
}
