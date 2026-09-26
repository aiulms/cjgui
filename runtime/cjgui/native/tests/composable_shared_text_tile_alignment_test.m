// RED-first native regression for candidate-scoped shared TextKit drawing.
// It compiles the current production renderer into this translation unit and
// compares its tiled shared-layout pixels to the renderer's fused
// drawWithRect reference, using a node at nonzero scene coordinates whose
// visible texture is clipped at nonzero x/y. Scale 1 must use one fused tile;
// the same geometry at scale 2 must exercise multiple shared TextKit tiles.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static NSString *alignmentProbeText(void) {
    NSMutableString *text = [NSMutableString stringWithString:@"iiiiiiii\n"];
    for (NSUInteger row = 0; row < 320; row++) {
        // Wide glyphs make it distinguishable if the first visible glyph band
        // is accidentally sourced from a later layout row.
        [text appendString:@"WWWW WWWW WWWW WWWW WWWW WWWW WWWW\n"];
    }
    return text;
}

static CJGuiInternalComposableSceneNode *alignmentProbeNode(NSString *text) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode value = {0};
    value.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    value.nodeId = 0xA17;
    value.resourceId = 0xB19;
    value.x = 73; value.y = 91; value.width = 280; value.height = 3500;
    value.clipX = 87; value.clipY = 103; value.clipWidth = 250; value.clipHeight = 3460;
    value.fontSize = 13;
    value.textAlpha = 1.0;
    node.node = value;
    node.label = @"alignment probe";
    node.value = text;
    return node;
}

static NSString *unicodeNearWrapText(void) {
    NSFont *font = [NSFont systemFontOfSize:13.0];
    NSDictionary *attributes = @{NSFontAttributeName:font};
    NSArray<NSString *> *clusters = @[@"中🙂e\u0301", @"🙂中e\u0301", @"e\u0301中🙂"];
    NSMutableString *text = [NSMutableString stringWithCapacity:80 * 320];
    for (NSUInteger row = 0; row < 320; row++) {
        NSMutableString *nearWrap = [NSMutableString string];
        NSString *cluster = clusters[row % clusters.count];
        while (nearWrap.length < 80 && [nearWrap sizeWithAttributes:attributes].width < 242.0) {
            [nearWrap appendString:cluster];
        }
        [text appendString:nearWrap];
        [text appendString:@"\n"];
    }
    return text;
}

static CJGuiInternalComposableSceneNode *unicodeNearWrapNode(NSString *text) {
    CJGuiInternalComposableSceneNode *node = alignmentProbeNode(text);
    CjguiInternalRendererComposableNode value = node.node;
    value.nodeId = 0xA18;
    value.x = 117; value.y = 149; value.width = 280; value.height = 3500;
    value.clipX = 131; value.clipY = 161; value.clipWidth = 250; value.clipHeight = 3460;
    node.node = value;
    node.label = @"unicode near-wrap probe";
    return node;
}

typedef struct {
    NSUInteger left;
    NSUInteger right;
    NSUInteger firstY;
    NSUInteger lastY;
    NSUInteger alphaPixels;
} InkBand;

static NSData *readTexture(id<MTLTexture> texture) {
    if (!texture || texture.pixelFormat != MTLPixelFormatBGRA8Unorm) return nil;
    NSUInteger rowBytes = texture.width * 4;
    NSMutableData *bytes = [NSMutableData dataWithLength:rowBytes * texture.height];
    [texture getBytes:bytes.mutableBytes bytesPerRow:rowBytes
          fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
    return bytes;
}

static InkBand firstInkBand(id<MTLTexture> texture) {
    NSData *bytes = readTexture(texture);
    InkBand result = {0, 0, 0, 0, 0};
    if (!bytes) return result;
    const uint8_t *pixels = bytes.bytes;
    NSUInteger rowBytes = texture.width * 4;
    BOOL inBand = NO;
    NSUInteger blankRows = 0;
    for (NSUInteger y = 0; y < texture.height; y++) {
        NSUInteger left = texture.width, right = 0, count = 0;
        for (NSUInteger x = 0; x < texture.width; x++) {
            if (pixels[y * rowBytes + x * 4 + 3] != 0) {
                left = MIN(left, x); right = MAX(right, x); count++;
            }
        }
        if (count == 0) {
            if (inBand && ++blankRows >= 2) break;
            continue;
        }
        if (!inBand) {
            inBand = YES; result.left = left; result.right = right; result.firstY = y;
        }
        blankRows = 0;
        result.left = MIN(result.left, left); result.right = MAX(result.right, right);
        result.lastY = y; result.alphaPixels += count;
    }
    return result;
}

static NSUInteger alphaPixelsInRows(id<MTLTexture> texture, NSUInteger startRow, NSUInteger rowCount) {
    NSData *bytes = readTexture(texture);
    if (!bytes || startRow >= texture.height) return 0;
    const uint8_t *pixels = bytes.bytes;
    NSUInteger endRow = MIN(texture.height, startRow + rowCount), count = 0;
    NSUInteger rowBytes = texture.width * 4;
    for (NSUInteger y = startRow; y < endRow; y++) for (NSUInteger x = 0; x < texture.width; x++)
        if (pixels[y * rowBytes + x * 4 + 3] != 0) count++;
    return count;
}

static InkBand inkBoundsInRows(id<MTLTexture> texture, NSUInteger startRow, NSUInteger rowCount) {
    NSData *bytes = readTexture(texture);
    InkBand result = {0, 0, 0, 0, 0};
    if (!bytes || startRow >= texture.height) return result;
    const uint8_t *pixels = bytes.bytes;
    NSUInteger rowBytes = texture.width * 4, endRow = MIN(texture.height, startRow + rowCount);
    result.left = texture.width; result.firstY = endRow;
    for (NSUInteger y = startRow; y < endRow; y++) {
        for (NSUInteger x = 0; x < texture.width; x++) {
            if (pixels[y * rowBytes + x * 4 + 3] == 0) continue;
            result.left = MIN(result.left, x); result.right = MAX(result.right, x);
            result.firstY = MIN(result.firstY, y); result.lastY = MAX(result.lastY, y);
            result.alphaPixels++;
        }
    }
    if (result.alphaPixels == 0) result.left = result.firstY = 0;
    return result;
}

static NSUInteger differingBytes(NSData *a, NSData *b) {
    if (!a || !b || a.length != b.length) return NSUIntegerMax;
    const uint8_t *ap = a.bytes, *bp = b.bytes;
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < a.length; i++) if (ap[i] != bp[i]) count++;
    return count;
}

static BOOL rowHasInk(NSData *pixels, NSUInteger width, NSUInteger y) {
    if (!pixels) return NO;
    const uint8_t *bytes = pixels.bytes;
    NSUInteger rowBytes = width * 4;
    for (NSUInteger x = 0; x < width; x++) if (bytes[y * rowBytes + x * 4 + 3] != 0) return YES;
    return NO;
}

static NSUInteger firstInkRow(NSData *pixels, NSUInteger width, NSUInteger height) {
    for (NSUInteger y = 0; y < height; y++) if (rowHasInk(pixels, width, y)) return y;
    return height;
}

static NSUInteger lastInkRow(NSData *pixels, NSUInteger width, NSUInteger height) {
    for (NSUInteger y = height; y > 0; y--) if (rowHasInk(pixels, width, y - 1)) return y - 1;
    return height;
}

static BOOL seamRowsEqual(NSData *a, NSData *b, NSUInteger width, NSUInteger height,
                          NSUInteger seamRow, NSUInteger bandRows) {
    if (!a || !b || a.length != b.length || seamRow < bandRows || seamRow + bandRows > height) return NO;
    for (NSUInteger y = seamRow - bandRows; y < seamRow + bandRows; y++)
        if (rowHasInk(a, width, y) != rowHasInk(b, width, y)) return NO;
    return YES;
}

static NSUInteger rowMaskDifferences(NSData *a, NSData *b, NSUInteger width, NSUInteger height,
                                    NSUInteger startRow, NSUInteger rowCount) {
    if (!a || !b || a.length != b.length || startRow >= height) return NSUIntegerMax;
    NSUInteger endRow = MIN(height, startRow + rowCount), differences = 0;
    for (NSUInteger y = startRow; y < endRow; y++)
        if (rowHasInk(a, width, y) != rowHasInk(b, width, y)) differences++;
    return differences;
}

static id<MTLTexture> firstTextTexture(CJGuiInternalComposableSceneNode *node) {
    return node.textTexture ?: node.textTileTextures.firstObject;
}

static NSData *sceneTopDownRows(NSData *raw, NSUInteger rowBytes, NSUInteger height) {
    if (!raw || raw.length != rowBytes * height) return nil;
    NSMutableData *flipped = [NSMutableData dataWithLength:raw.length];
    const uint8_t *src = raw.bytes;
    uint8_t *dst = flipped.mutableBytes;
    for (NSUInteger y = 0; y < height; y++) {
        memcpy(dst + y * rowBytes, src + (height - 1 - y) * rowBytes, rowBytes);
    }
    return flipped;
}

static NSRange glyphRangeForTile(CjguiPreparedTextNodeLayout *prepared,
                                CjguiInternalRendererComposableNode node,
                                NSRect textureRect) {
    NSRect tileInContainer = NSMakeRect(textureRect.origin.x - (CGFloat)node.x - prepared.textRect.origin.x,
                                        textureRect.origin.y - (CGFloat)node.y - prepared.textRect.origin.y,
                                        textureRect.size.width, textureRect.size.height);
    return [prepared.layoutManager glyphRangeForBoundingRect:tileInContainer
                                           inTextContainer:prepared.container];
}

static BOOL compareForcedPartition(CJGuiInternalMetalView *view, NSString *text,
                                  BOOL unicodeFixture) {
    CJGuiInternalComposableSceneNode *node = unicodeFixture
        ? unicodeNearWrapNode(text) : alignmentProbeNode(text);
    CjguiInternalRendererComposableNode geometry = node.node;
    geometry.height = 1400;
    geometry.clipHeight = 1360;
    node.node = geometry;
    NSRect visibleRect = CjguiComposableTextTextureRectForNode(node);
    if (!NSEqualRects(visibleRect, NSMakeRect(geometry.clipX, geometry.clipY, 250, 1360))) {
        fprintf(stderr, "PARTITION_FAIL fixture=%s unexpected rect=(%.1f,%.1f,%.1f,%.1f)\n",
                unicodeFixture ? "unicode" : "ascii", visibleRect.origin.x, visibleRect.origin.y,
                visibleRect.size.width, visibleRect.size.height);
        return NO;
    }

    // At scale 2 this complete 250 x 1360pt rectangle is a legal single
    // 5.44MB native bitmap. Both outputs below use this one prepared layout.
    CjguiPreparedTextNodeLayout *shared = CjguiPrepareTextNodeLayout(node, text, 2.0);
    if (!shared) {
        fprintf(stderr, "PARTITION_FAIL fixture=%s shared TextKit preparation returned nil\n",
                unicodeFixture ? "unicode" : "ascii");
        return NO;
    }
    uint64_t fullBytes = 0, upperBytes = 0, lowerBytes = 0;
    id<MTLTexture> full = CjguiRasterComposableTextTexture(
        view, node, 2.0, 2.0, text, visibleRect, &fullBytes, shared,
        CjguiInternalTextWorkReasonUnknown);
    NSRect upperRect = NSMakeRect(NSMinX(visibleRect), NSMinY(visibleRect), NSWidth(visibleRect), 680);
    NSRect lowerRect = NSMakeRect(NSMinX(visibleRect), NSMinY(visibleRect) + 680, NSWidth(visibleRect), 680);
    id<MTLTexture> upper = CjguiRasterComposableTextTexture(
        view, node, 2.0, 2.0, text, upperRect, &upperBytes, shared,
        CjguiInternalTextWorkReasonUnknown);
    id<MTLTexture> lower = CjguiRasterComposableTextTexture(
        view, node, 2.0, 2.0, text, lowerRect, &lowerBytes, shared,
        CjguiInternalTextWorkReasonUnknown);
    NSData *fullPixels = readTexture(full), *upperPixels = readTexture(upper), *lowerPixels = readTexture(lower);
    if (!fullPixels || !upperPixels || !lowerPixels || full.width != upper.width ||
        full.width != lower.width || upper.height + lower.height != full.height ||
        fullBytes != upperBytes + lowerBytes) {
        fprintf(stderr, "PARTITION_FAIL fixture=%s textures/byte geometry invalid full=%d upper=%d lower=%d\n",
                unicodeFixture ? "unicode" : "ascii", full != nil, upper != nil, lower != nil);
        return NO;
    }
    NSMutableData *stitched = [NSMutableData dataWithLength:fullPixels.length];
    NSMutableData *reversed = [NSMutableData dataWithLength:fullPixels.length];
    NSUInteger rowBytes = full.width * 4;
    memcpy(stitched.mutableBytes, upperPixels.bytes, upperPixels.length);
    memcpy((uint8_t *)stitched.mutableBytes + upperPixels.length, lowerPixels.bytes, lowerPixels.length);
    memcpy(reversed.mutableBytes, lowerPixels.bytes, lowerPixels.length);
    memcpy((uint8_t *)reversed.mutableBytes + lowerPixels.length, upperPixels.bytes, upperPixels.length);
    NSData *fullUpper = [fullPixels subdataWithRange:NSMakeRange(0, upperPixels.length)];
    NSData *fullLower = [fullPixels subdataWithRange:NSMakeRange(upperPixels.length, lowerPixels.length)];
    NSUInteger seamRow = upper.height;
    NSUInteger bandRows = (NSUInteger)ceil(24.0 * 2.0);
    NSUInteger seamPixels = alphaPixelsInRows(upper, upper.height > bandRows ? upper.height - bandRows : 0, bandRows) +
        alphaPixelsInRows(lower, 0, bandRows);
    BOOL seamPresent = seamPixels > 0;
    BOOL seamSameRows = seamRowsEqual(fullPixels, stitched, full.width, full.height, seamRow, bandRows);
    NSUInteger fullFirst = firstInkRow(fullPixels, full.width, full.height);
    NSUInteger splitFirst = firstInkRow(stitched, full.width, full.height);
    NSUInteger fullLast = lastInkRow(fullPixels, full.width, full.height);
    NSUInteger splitLast = lastInkRow(stitched, full.width, full.height);
    NSUInteger diffBytes = differingBytes(fullPixels, stitched);
    NSUInteger reverseDiffBytes = differingBytes(fullPixels, reversed);
    NSUInteger upperDiffBytes = differingBytes(fullUpper, upperPixels);
    NSUInteger lowerDiffBytes = differingBytes(fullLower, lowerPixels);
    NSUInteger upperRowDiffs = rowMaskDifferences(fullUpper, upperPixels, full.width, upper.height, 0, upper.height);
    NSUInteger lowerRowDiffs = rowMaskDifferences(fullLower, lowerPixels, full.width, lower.height, 0, lower.height);
    NSUInteger allRowMaskDiffs = rowMaskDifferences(fullPixels, stitched, full.width, full.height, 0, full.height);
    NSUInteger reverseRowMaskDiffs = rowMaskDifferences(fullPixels, reversed, full.width, full.height, 0, full.height);
    NSUInteger seamRowMaskDiffs = rowMaskDifferences(fullPixels, stitched, full.width, full.height,
                                                      seamRow - bandRows, bandRows * 2);
    NSUInteger reverseSeamRowMaskDiffs = rowMaskDifferences(fullPixels, reversed, full.width, full.height,
                                                             seamRow - bandRows, bandRows * 2);
    NSData *fullSceneRows = sceneTopDownRows(fullPixels, rowBytes, full.height);
    NSData *upperSceneRows = sceneTopDownRows(upperPixels, rowBytes, upper.height);
    NSData *lowerSceneRows = sceneTopDownRows(lowerPixels, rowBytes, lower.height);
    NSMutableData *sceneStitched = [NSMutableData dataWithLength:fullPixels.length];
    memcpy(sceneStitched.mutableBytes, upperSceneRows.bytes, upperSceneRows.length);
    memcpy((uint8_t *)sceneStitched.mutableBytes + upperSceneRows.length,
           lowerSceneRows.bytes, lowerSceneRows.length);
    NSUInteger sceneDiffBytes = differingBytes(fullSceneRows, sceneStitched);
    NSUInteger sceneRowMaskDiffs = rowMaskDifferences(fullSceneRows, sceneStitched,
                                                       full.width, full.height, 0, full.height);
    NSUInteger sceneFirst = firstInkRow(fullSceneRows, full.width, full.height);
    NSUInteger sceneSplitFirst = firstInkRow(sceneStitched, full.width, full.height);
    NSUInteger sceneLast = lastInkRow(fullSceneRows, full.width, full.height);
    NSUInteger sceneSplitLast = lastInkRow(sceneStitched, full.width, full.height);
    BOOL sceneSeamSame = seamRowsEqual(fullSceneRows, sceneStitched, full.width, full.height,
                                       seamRow, bandRows);
    NSRange fullGlyphRange = glyphRangeForTile(shared, geometry, visibleRect);
    NSRange upperGlyphRange = glyphRangeForTile(shared, geometry, upperRect);
    NSRange lowerGlyphRange = glyphRangeForTile(shared, geometry, lowerRect);
    BOOL byteEqual = [fullPixels isEqualToData:stitched];

    printf("PARTITION fixture=%s scale=2 geometry=(%.0f,%.0f,%.0f,%.0f) node=(%.0f,%.0f) prepared_same=1 full_bytes=%llu split_bytes=%llu full_glyphs=%lu:%lu upper_glyphs=%lu:%lu lower_glyphs=%lu:%lu first_row=%lu/%lu last_row=%lu/%lu seam_row=%lu seam_alpha=%lu seam_row_mask_equal=%d seam_row_mask_diffs=%lu upper_diff_bytes=%lu upper_row_mask_diffs=%lu lower_diff_bytes=%lu lower_row_mask_diffs=%lu all_row_mask_diffs=%lu pixel_diff_bytes=%lu byte_equal=%d reverse_pixel_diff_bytes=%lu reverse_row_mask_diffs=%lu reverse_seam_row_mask_diffs=%lu scene_pixel_diff_bytes=%lu scene_row_mask_diffs=%lu scene_first=%lu/%lu scene_last=%lu/%lu scene_seam_equal=%d\n",
           unicodeFixture ? "unicode" : "ascii", visibleRect.origin.x, visibleRect.origin.y,
           visibleRect.size.width, visibleRect.size.height, (double)geometry.x, (double)geometry.y,
           (unsigned long long)fullBytes, (unsigned long long)(upperBytes + lowerBytes),
           (unsigned long)fullGlyphRange.location, (unsigned long)fullGlyphRange.length,
           (unsigned long)upperGlyphRange.location, (unsigned long)upperGlyphRange.length,
           (unsigned long)lowerGlyphRange.location, (unsigned long)lowerGlyphRange.length,
           (unsigned long)fullFirst, (unsigned long)splitFirst,
           (unsigned long)fullLast, (unsigned long)splitLast, (unsigned long)seamRow,
           (unsigned long)seamPixels, seamSameRows, (unsigned long)seamRowMaskDiffs,
           (unsigned long)upperDiffBytes, (unsigned long)upperRowDiffs,
           (unsigned long)lowerDiffBytes, (unsigned long)lowerRowDiffs,
           (unsigned long)allRowMaskDiffs, (unsigned long)diffBytes, byteEqual,
           (unsigned long)reverseDiffBytes, (unsigned long)reverseRowMaskDiffs,
           (unsigned long)reverseSeamRowMaskDiffs, (unsigned long)sceneDiffBytes,
           (unsigned long)sceneRowMaskDiffs, (unsigned long)sceneFirst,
           (unsigned long)sceneSplitFirst, (unsigned long)sceneLast,
           (unsigned long)sceneSplitLast, sceneSeamSame);

    BOOL sameRows = fullFirst == splitFirst && fullLast == splitLast && seamSameRows && seamPresent;
    BOOL sameSceneRows = sceneFirst == sceneSplitFirst && sceneLast == sceneSplitLast &&
        sceneSeamSame && sceneRowMaskDiffs == 0 && seamPresent;
    if (unicodeFixture) {
        // Deliberately perturb one fixed byte in a copy so the strict
        // same-geometry comparator has a deterministic negative control.
        NSMutableData *mutatedScene = [sceneStitched mutableCopy];
        ((uint8_t *)mutatedScene.mutableBytes)[0] ^= 0x01;
        NSUInteger mutationDiffBytes = differingBytes(fullSceneRows, mutatedScene);
        BOOL mutationRejected = mutationDiffBytes == 1 && mutationDiffBytes != 0;
        printf("PARTITION_PIXEL_MUTATION fixture=unicode byte_offset=0 diff_bytes=%lu rejected=%d\n",
               (unsigned long)mutationDiffBytes, mutationRejected);
        // The same prepared layout, text, scale, and geometry must render
        // identical scene pixels even when fallback glyphs cross tile seams.
        if (sceneDiffBytes != 0 || !sameSceneRows)
            fprintf(stderr, "PARTITION_FAIL fixture=unicode scene-order split changed full-plane bytes or row mask\n");
        if (!mutationRejected)
            fprintf(stderr, "PARTITION_FAIL fixture=unicode deterministic pixel mutation was not detected\n");
        return sceneDiffBytes == 0 && sameSceneRows && mutationRejected;
    }
    if (sceneDiffBytes != 0 || !sameSceneRows) {
        fprintf(stderr, "PARTITION_FAIL fixture=ascii scene-order split changed full-plane bytes or row mask\n");
        return NO;
    }
    (void)sameRows;
    (void)byteEqual;
    (void)reverseDiffBytes;
    (void)rowBytes;
    return YES;
}

static BOOL verifyPreparationRollbackAndEmptyInset(CJGuiInternalMetalView *view) {
    CGFloat scale = MAX(1.0, [view currentBackingScale]);
    CJGuiInternalComposableSceneNode *accepted = alignmentProbeNode(@"accepted old value 😀");
    CjguiInternalRendererComposableNode acceptedGeometry = accepted.node;
    acceptedGeometry.nodeId = 0xA19;
    acceptedGeometry.resourceId = 0xB20;
    acceptedGeometry.projectionVersion = 1;
    accepted.node = acceptedGeometry;
    id<MTLTexture> acceptedTexture = CjguiComposableTextTexture(
        view, accepted, scale, scale, accepted.value, CjguiInternalTextWorkReasonUnknown);
    if (!acceptedTexture || accepted.textTextureByteCount == 0) {
        fprintf(stderr, "PREPARE_BOUNDARY_FAIL accepted baseline could not rasterize\n");
        return NO;
    }

    CJGuiInternalSession *session = [CJGuiInternalSession new];
    session.view = view;
    session.composableNodes = @[accepted];
    session.stagedComposableSceneVersion = 2;
    CJGuiInternalComposableSceneNode *candidate = CjguiCloneComposableSceneNode(
        session, accepted, 0, session.stagedComposableSceneVersion);
    if (!candidate) {
        fprintf(stderr, "PREPARE_BOUNDARY_FAIL candidate clone unavailable\n");
        return NO;
    }
    candidate.value = @"rejected candidate value 中🙂e\u0301";
    session.stagedComposableNodes = [NSMutableArray arrayWithObject:candidate];
    view.testForceSharedTextLayoutNilOnce = YES;
    CjguiInternalRendererStatus rejected = CjguiPrepareComposableTextResources(session);
    BOOL acceptedRetained = rejected == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
        !view.testForceSharedTextLayoutNilOnce &&
        session.composableNodes.firstObject == accepted &&
        firstTextTexture(accepted) == acceptedTexture &&
        accepted.textTextureByteCount > 0 &&
        [accepted.value isEqualToString:@"accepted old value 😀"];

    // Drop the rejected candidate exactly as the transaction rollback does,
    // then retry the same value without the one-shot preparation failure.
    session.stagedComposableNodes = [NSMutableArray arrayWithObject:accepted];
    CJGuiInternalComposableSceneNode *retry = CjguiCloneComposableSceneNode(
        session, accepted, 0, session.stagedComposableSceneVersion + 1);
    retry.value = candidate.value;
    session.stagedComposableSceneVersion += 1;
    session.stagedComposableNodes = [NSMutableArray arrayWithObject:retry];
    CjguiInternalRendererStatus recovered = CjguiPrepareComposableTextResources(session);
    BOOL recoveryAccepted = recovered == CJGUI_INTERNAL_RENDERER_OK &&
        retry.textTextureByteCount > 0 && retry.textTextureCacheKey.length > 0 &&
        ![retry.textTextureCacheKey isEqualToString:accepted.textTextureCacheKey] &&
        firstTextTexture(retry) != firstTextTexture(accepted) &&
        firstTextTexture(accepted) == acceptedTexture &&
        [accepted.value isEqualToString:@"accepted old value 😀"];
    printf("PREPARE_ROLLBACK reject_status=%d nil_hook_consumed=%d accepted_retained=%d recovery_status=%d recovery_accepted=%d old_bytes=%llu new_bytes=%llu\n",
           (int)rejected, !view.testForceSharedTextLayoutNilOnce, acceptedRetained,
           (int)recovered, recoveryAccepted, (unsigned long long)accepted.textTextureByteCount,
           (unsigned long long)retry.textTextureByteCount);

    CJGuiInternalComposableSceneNode *emptyInset = alignmentProbeNode(@"empty inset has no text area");
    CjguiInternalRendererComposableNode emptyGeometry = emptyInset.node;
    emptyGeometry.nodeId = 0xA1A;
    emptyGeometry.x = 21; emptyGeometry.y = 27;
    emptyGeometry.width = 14; emptyGeometry.height = 12;
    emptyGeometry.clipX = 21; emptyGeometry.clipY = 27;
    emptyGeometry.clipWidth = 14; emptyGeometry.clipHeight = 12;
    emptyInset.node = emptyGeometry;
    NSRect emptyTextRect = NSInsetRect(NSMakeRect(0, 0, emptyGeometry.width, emptyGeometry.height), 7.0, 6.0);
    BOOL prepareNilIsLegal = NSIsEmptyRect(emptyTextRect) &&
        CjguiPrepareTextNodeLayout(emptyInset, emptyInset.value, scale) == nil;
    id<MTLTexture> emptyInsetTexture = CjguiComposableTextTexture(
        view, emptyInset, scale, scale, emptyInset.value, CjguiInternalTextWorkReasonUnknown);
    uint64_t emptyInsetBytes = emptyInset.textTextureByteCount;
    BOOL emptyInsetAccepted = emptyInsetTexture != nil && emptyInsetBytes > 0 &&
        alphaPixelsInRows(emptyInsetTexture, 0, emptyInsetTexture.height) == 0;
    printf("PREPARE_EMPTY_INSET rect=(%.0f,%.0f) prepare_nil=%d texture=%d bytes=%llu alpha=0 accepted=%d\n",
           emptyTextRect.size.width, emptyTextRect.size.height, prepareNilIsLegal,
           emptyInsetTexture != nil, (unsigned long long)emptyInsetBytes, emptyInsetAccepted);
    return acceptedRetained && recoveryAccepted && prepareNilIsLegal && emptyInsetAccepted;
}

static BOOL compareUnicodeScale(CJGuiInternalMetalView *view, NSString *text, CGFloat scale,
                                NSUInteger expectedTileCount) {
    CJGuiInternalComposableSceneNode *node = unicodeNearWrapNode(text);
    NSRect expectedRect = NSMakeRect(131, 161, 250, 3460);
    NSRect actualRect = CjguiComposableTextTextureRectForNode(node);
    if (!NSEqualRects(actualRect, expectedRect)) {
        fprintf(stderr, "UNICODE_FAIL scale=%.0f textureRect=(%.1f,%.1f,%.1f,%.1f)\n",
                scale, actualRect.origin.x, actualRect.origin.y, actualRect.size.width, actualRect.size.height);
        return NO;
    }
    uint64_t plannedBytes = 0;
    NSArray<NSValue *> *plannedRects = CjguiPlanComposableTextTiles(actualRect, scale, &plannedBytes);
    if (plannedRects.count != expectedTileCount) {
        fprintf(stderr, "UNICODE_FAIL scale=%.0f tileCount=%lu expected=%lu bytes=%llu\n",
                scale, (unsigned long)plannedRects.count, (unsigned long)expectedTileCount,
                (unsigned long long)plannedBytes);
        return NO;
    }
    id<MTLTexture> first = CjguiComposableTextTexture(view, node, scale, scale, text,
                                                       CjguiInternalTextWorkReasonUnknown);
    NSArray<id<MTLTexture>> *actualTiles = node.textTileTextures.count > 0 ? node.textTileTextures :
        (node.textTexture ? @[node.textTexture] : @[]);
    NSArray<NSValue *> *actualRects = node.textTileRects.count > 0 ? node.textTileRects :
        (node.textTexture ? @[ [NSValue valueWithRect:node.textTextureRect] ] : @[]);
    if (!first || actualTiles.count != expectedTileCount || actualRects.count != expectedTileCount) {
        fprintf(stderr, "UNICODE_FAIL scale=%.0f prepared tileCount=%lu rectCount=%lu texture=%d\n",
                scale, (unsigned long)actualTiles.count, (unsigned long)actualRects.count, first != nil);
        return NO;
    }

    BOOL valid = YES;
    for (NSUInteger index = 0; index < actualTiles.count; index++) {
        NSRect tileRect = actualRects[index].rectValue;
        uint64_t referenceBytes = 0;
        id<MTLTexture> reference = CjguiRasterComposableTextTexture(
            view, node, scale, scale, text, tileRect, &referenceBytes, nil,
            CjguiInternalTextWorkReasonUnknown);
        NSData *actualPixels = readTexture(actualTiles[index]);
        NSData *referencePixels = readTexture(reference);
        NSUInteger lineWindowRows = (NSUInteger)ceil(20.0 * scale);
        InkBand actualFirst = inkBoundsInRows(actualTiles[index], 0, lineWindowRows);
        InkBand referenceFirst = inkBoundsInRows(reference, 0, lineWindowRows);
        NSUInteger actualLastStart = actualTiles[index].height > lineWindowRows
            ? actualTiles[index].height - lineWindowRows : 0;
        NSUInteger referenceLastStart = reference && reference.height > lineWindowRows
            ? reference.height - lineWindowRows : 0;
        InkBand actualLast = inkBoundsInRows(actualTiles[index], actualLastStart, lineWindowRows);
        InkBand referenceLast = inkBoundsInRows(reference, referenceLastStart, lineWindowRows);
        NSUInteger seamRows = (NSUInteger)ceil(32.0 * scale);
        NSUInteger actualHead = alphaPixelsInRows(actualTiles[index], 0, seamRows);
        NSUInteger referenceHead = alphaPixelsInRows(reference, 0, seamRows);
        NSUInteger actualTail = alphaPixelsInRows(actualTiles[index],
            actualTiles[index].height > seamRows ? actualTiles[index].height - seamRows : 0, seamRows);
        NSUInteger referenceTail = alphaPixelsInRows(reference,
            reference ? (reference.height > seamRows ? reference.height - seamRows : 0) : 0, seamRows);
        BOOL regionsPresent = actualFirst.alphaPixels > 0 && referenceFirst.alphaPixels > 0 &&
            actualLast.alphaPixels > 0 && referenceLast.alphaPixels > 0 &&
            actualHead > 0 && referenceHead > 0 && actualTail > 0 && referenceTail > 0;
        NSInteger firstYDelta = (NSInteger)actualFirst.firstY - (NSInteger)referenceFirst.firstY;
        NSInteger lastYDelta = (NSInteger)actualLast.firstY - (NSInteger)referenceLast.firstY;
        NSInteger tolerance = (NSInteger)ceil(4.0 * scale);
        NSInteger firstLeftDelta = (NSInteger)actualFirst.left - (NSInteger)referenceFirst.left;
        NSInteger firstRightDelta = (NSInteger)actualFirst.right - (NSInteger)referenceFirst.right;
        NSInteger lastLeftDelta = (NSInteger)actualLast.left - (NSInteger)referenceLast.left;
        NSInteger lastRightDelta = (NSInteger)actualLast.right - (NSInteger)referenceLast.right;
        BOOL firstLastPlaced = llabs((long long)firstYDelta) <= tolerance &&
            llabs((long long)lastYDelta) <= tolerance &&
            llabs((long long)firstLeftDelta) <= tolerance * 2 &&
            llabs((long long)firstRightDelta) <= tolerance * 2 &&
            llabs((long long)lastLeftDelta) <= tolerance * 2 &&
            llabs((long long)lastRightDelta) <= tolerance * 2;
        BOOL validBytes = reference && actualPixels && referencePixels &&
            actualPixels.length == referencePixels.length && referenceBytes > 0;
        printf("UNICODE_TILE scale=%.0f index=%lu rect=(%.1f,%.1f,%.1f,%.1f) first_actual=(x=%lu..%lu,y=%lu..%lu,alpha=%lu) first_reference=(x=%lu..%lu,y=%lu..%lu,alpha=%lu) last_actual=(x=%lu..%lu,y=%lu..%lu,alpha=%lu) last_reference=(x=%lu..%lu,y=%lu..%lu,alpha=%lu) seam_head=%lu/%lu seam_tail=%lu/%lu pixel_diff_bytes=%lu\n",
               scale, (unsigned long)index, tileRect.origin.x, tileRect.origin.y,
               tileRect.size.width, tileRect.size.height,
               (unsigned long)actualFirst.left, (unsigned long)actualFirst.right, (unsigned long)actualFirst.firstY, (unsigned long)actualFirst.lastY, (unsigned long)actualFirst.alphaPixels,
               (unsigned long)referenceFirst.left, (unsigned long)referenceFirst.right, (unsigned long)referenceFirst.firstY, (unsigned long)referenceFirst.lastY, (unsigned long)referenceFirst.alphaPixels,
               (unsigned long)actualLast.left, (unsigned long)actualLast.right, (unsigned long)actualLast.firstY, (unsigned long)actualLast.lastY, (unsigned long)actualLast.alphaPixels,
               (unsigned long)referenceLast.left, (unsigned long)referenceLast.right, (unsigned long)referenceLast.firstY, (unsigned long)referenceLast.lastY, (unsigned long)referenceLast.alphaPixels,
               (unsigned long)actualHead, (unsigned long)referenceHead,
               (unsigned long)actualTail, (unsigned long)referenceTail,
               (unsigned long)differingBytes(actualPixels, referencePixels));
        if (!validBytes || !regionsPresent || !firstLastPlaced) {
            fprintf(stderr, "UNICODE_FAIL scale=%.0f index=%lu blank-or-misaligned firstYDelta=%ld lastYDelta=%ld firstXDelta=(%ld,%ld) lastXDelta=(%ld,%ld) tolerance=%ld\n",
                    scale, (unsigned long)index, (long)firstYDelta, (long)lastYDelta,
                    (long)firstLeftDelta, (long)firstRightDelta, (long)lastLeftDelta, (long)lastRightDelta,
                    (long)tolerance);
            valid = NO;
        }
    }
    return valid;
}

static BOOL compareScale(CJGuiInternalMetalView *view, NSString *text, CGFloat scale,
                        NSUInteger expectedTileCount) {
    CJGuiInternalComposableSceneNode *node = alignmentProbeNode(text);
    NSRect expectedRect = NSMakeRect(87, 103, 250, 3460);
    NSRect actualRect = CjguiComposableTextTextureRectForNode(node);
    if (!NSEqualRects(actualRect, expectedRect)) {
        fprintf(stderr, "ALIGNMENT_FAIL scale=%.0f textureRect=(%.1f,%.1f,%.1f,%.1f) expected=(87,103,250,3460)\n",
                scale, actualRect.origin.x, actualRect.origin.y, actualRect.size.width, actualRect.size.height);
        return NO;
    }

    uint64_t plannedBytes = 0;
    NSArray<NSValue *> *plannedRects = CjguiPlanComposableTextTiles(actualRect, scale, &plannedBytes);
    if (plannedRects.count != expectedTileCount) {
        fprintf(stderr, "ALIGNMENT_FAIL scale=%.0f tileCount=%lu expected=%lu bytes=%llu\n",
                scale, (unsigned long)plannedRects.count, (unsigned long)expectedTileCount,
                (unsigned long long)plannedBytes);
        return NO;
    }

    id<MTLTexture> first = CjguiComposableTextTexture(view, node, scale, scale, text,
                                                       CjguiInternalTextWorkReasonUnknown);
    NSArray<id<MTLTexture>> *actualTiles = node.textTileTextures.count > 0 ? node.textTileTextures :
        (node.textTexture ? @[node.textTexture] : @[]);
    NSArray<NSValue *> *actualRects = node.textTileRects.count > 0 ? node.textTileRects :
        (node.textTexture ? @[ [NSValue valueWithRect:node.textTextureRect] ] : @[]);
    if (!first || actualTiles.count != expectedTileCount || actualRects.count != expectedTileCount) {
        fprintf(stderr, "ALIGNMENT_FAIL scale=%.0f prepared tileCount=%lu rectCount=%lu texture=%d\n",
                scale, (unsigned long)actualTiles.count, (unsigned long)actualRects.count, first != nil);
        return NO;
    }

    BOOL matched = YES;
    for (NSUInteger index = 0; index < actualTiles.count; index++) {
        NSRect tileRect = actualRects[index].rectValue;
        uint64_t referenceBytes = 0;
        id<MTLTexture> reference = CjguiRasterComposableTextTexture(
            view, node, scale, scale, text, tileRect, &referenceBytes, nil,
            CjguiInternalTextWorkReasonUnknown);
        NSData *actualPixels = readTexture(actualTiles[index]);
        NSData *referencePixels = readTexture(reference);
        InkBand actualBand = firstInkBand(actualTiles[index]);
        InkBand referenceBand = firstInkBand(reference);
        NSUInteger actualBandWidth = actualBand.alphaPixels ? actualBand.right - actualBand.left + 1 : 0;
        NSUInteger referenceBandWidth = referenceBand.alphaPixels ? referenceBand.right - referenceBand.left + 1 : 0;
        NSUInteger horizontalTolerance = (NSUInteger)ceil(12.0 * scale); // allow renderer's 5pt TextKit padding plus raster edge variation
        NSUInteger widthDelta = actualBandWidth > referenceBandWidth
            ? actualBandWidth - referenceBandWidth : referenceBandWidth - actualBandWidth;
        BOOL alignedFirstBand = actualBand.alphaPixels > 0 && referenceBand.alphaPixels > 0 &&
            widthDelta <= horizontalTolerance &&
            (actualBand.firstY > referenceBand.firstY ? actualBand.firstY - referenceBand.firstY
                                                        : referenceBand.firstY - actualBand.firstY) <= 2;
        BOOL bytesValid = reference != nil && actualPixels && referencePixels &&
            actualPixels.length == referencePixels.length && referenceBytes > 0;
        printf("TILE scale=%.0f index=%lu rect=(%.1f,%.1f,%.1f,%.1f) pixels=%lux%lu actual_first_band=(x=%lu..%lu,y=%lu..%lu,alpha=%lu) reference_first_band=(x=%lu..%lu,y=%lu..%lu,alpha=%lu) byte_equal=%d\n",
               scale, (unsigned long)index, tileRect.origin.x, tileRect.origin.y,
               tileRect.size.width, tileRect.size.height,
               (unsigned long)actualTiles[index].width, (unsigned long)actualTiles[index].height,
               (unsigned long)actualBand.left, (unsigned long)actualBand.right,
               (unsigned long)actualBand.firstY, (unsigned long)actualBand.lastY,
               (unsigned long)actualBand.alphaPixels,
               (unsigned long)referenceBand.left, (unsigned long)referenceBand.right,
               (unsigned long)referenceBand.firstY, (unsigned long)referenceBand.lastY,
               (unsigned long)referenceBand.alphaPixels,
               [actualPixels isEqualToData:referencePixels]);
        if (!bytesValid || !alignedFirstBand) {
            fprintf(stderr, "ALIGNMENT_FAIL scale=%.0f index=%lu first visible row is blank/misaligned (widthDelta=%lu tolerance=%lu)\n",
                    scale, (unsigned long)index, (unsigned long)widthDelta, (unsigned long)horizontalTolerance);
            matched = NO;
        }
    }
    return matched;
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "shared text tile alignment test: no Metal device available\n");
            return 2;
        }
        CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
            initWithFrame:NSMakeRect(0, 0, 320, 240) device:device
            commandQueue:[device newCommandQueue]];
        NSString *text = alignmentProbeText();
        if (!compareScale(view, text, 1.0, 1)) return 1;
        if (!compareScale(view, text, 2.0, 2)) return 3;
        NSString *unicodeText = unicodeNearWrapText();
        NSString *nearWrapLine = [unicodeText componentsSeparatedByString:@"\n"].firstObject;
        NSFont *nearWrapFont = [NSFont systemFontOfSize:13.0];
        CGFloat nearWrapWidth = [nearWrapLine sizeWithAttributes:@{NSFontAttributeName:nearWrapFont}].width;
        printf("UNICODE_FIXTURE utf16=%lu rows=320 near_wrap_width=%.2f near_wrap_utf16=%lu utf8=%lu\n",
               (unsigned long)unicodeText.length, nearWrapWidth, (unsigned long)nearWrapLine.length,
               (unsigned long)[unicodeText lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        BOOL unicodeOneX = compareUnicodeScale(view, unicodeText, 1.0, 1);
        BOOL unicodeTwoX = compareUnicodeScale(view, unicodeText, 2.0, 2);
        if (!unicodeOneX) return 4;
        if (!unicodeTwoX) return 5;
        BOOL asciiPartition = compareForcedPartition(view, text, NO);
        BOOL unicodePartition = compareForcedPartition(view, unicodeText, YES);
        if (!asciiPartition) return 6;
        if (!unicodePartition) return 7;
        if (!verifyPreparationRollbackAndEmptyInset(view)) return 8;
        puts("shared text tile alignment: first visible bands aligned at 1x/2x");
    }
    return 0;
}
