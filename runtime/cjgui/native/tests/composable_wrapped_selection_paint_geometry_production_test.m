// Compare owner-declared and installed-proxy selection paint geometry through
// the real accepted-scene and selection-transfer paths. The window fixture is
// deliberately never ordered front or activated.
#include <math.h>
#define main prior_selection_transfer_paint_test_main
#import "composable_selection_transfer_paint_production_test.m"
#undef main

static NSString * const kWrappedSelectionBody =
    @"The first wrapped line ends here    \nA second paragraph ends with more spaces      and wraps again into another line. This final sentence ensures the tail wraps too and ends with spaces      ";
static NSString * const kWrappedUnicodeBidiBody =
    @"LTR alpha beta    עברית mixed العربية text wraps with bidi runs. café e\u0301 🙂 emoji crosses a line, then trailing spaces      ";
static NSString * const kWrappedClippedBody =
    @"Head    \nA clipped viewport shows a selected partial line and several wrapped lines while the rest of this body remains beyond the visible vertical edge. The ending is also long enough to wrap repeatedly and must stay owned by the same accepted source text. End spaces      ";
static NSString * const kZeroVisibleResidencyBody =
    @"01234567890123456789012345678901234567890123456789012345678901234567890123456789abcde";

@interface WrappedDropEnclosingRectsLayoutManager : NSLayoutManager
@end
@implementation WrappedDropEnclosingRectsLayoutManager
- (void)enumerateEnclosingRectsForGlyphRange:(NSRange)glyphRange
    withinSelectedGlyphRange:(NSRange)selectedGlyphRange
    inTextContainer:(NSTextContainer *)container
    usingBlock:(void (^)(NSRect rect, BOOL *stop))block {
    (void)glyphRange; (void)selectedGlyphRange; (void)container; (void)block;
}
@end

@interface WrappedBudgetOverrunLayoutManager : NSLayoutManager
@property(nonatomic, assign) NSRect repeatedRect;
@end
@implementation WrappedBudgetOverrunLayoutManager
- (void)enumerateEnclosingRectsForGlyphRange:(NSRange)glyphRange
    withinSelectedGlyphRange:(NSRange)selectedGlyphRange
    inTextContainer:(NSTextContainer *)container
    usingBlock:(void (^)(NSRect rect, BOOL *stop))block {
    (void)glyphRange; (void)selectedGlyphRange; (void)container;
    for (NSUInteger index = 0; index < 1025; index++) {
        BOOL stop = NO;
        block(self.repeatedRect, &stop);
        if (stop) break;
    }
}
@end

static NSArray<NSValue *> *WrappedGeometryFromDecorations(NSArray<NSDictionary *> *decorations) {
    NSMutableArray<NSValue *> *result = [NSMutableArray arrayWithCapacity:decorations.count];
    for (NSDictionary *entry in decorations) {
        NSValue *value = entry[@"rect"];
        if ([value isKindOfClass:NSValue.class]) [result addObject:value];
    }
    return [result copy];
}

static BOOL WrappedGeometryContainsPoint(NSArray<NSValue *> *rects, NSPoint point) {
    for (NSValue *value in rects) {
        if (NSPointInRect(point, value.rectValue)) return YES;
    }
    return NO;
}

static NSArray<NSValue *> *WrappedGlyphSceneRects(CJGuiInternalComposableSceneNode *node,
                                                  NSRange characters) {
    CjguiPreparedTextNodeLayout *prepared = node.preparedTextLayout;
    if (!prepared.layoutManager || NSMaxRange(characters) > prepared.storage.string.length) return @[];
    NSLayoutManager *layout = prepared.layoutManager;
    NSRange glyphs = [layout glyphRangeForCharacterRange:characters actualCharacterRange:NULL];
    if (glyphs.length == 0) return @[];
    NSRect nodeRect = CjguiComposableVisualNodeRect(node);
    NSMutableArray<NSValue *> *result = [NSMutableArray arrayWithCapacity:glyphs.length];
    for (NSUInteger glyph = glyphs.location; glyph < NSMaxRange(glyphs); glyph++) {
        NSRect local = [layout boundingRectForGlyphRange:NSMakeRange(glyph, 1)
                                          inTextContainer:prepared.container];
        if (NSIsEmptyRect(local)) continue;
        NSRect scene = NSOffsetRect(local, NSMinX(nodeRect) + NSMinX(prepared.textRect),
            NSMinY(nodeRect) + NSMinY(prepared.textRect));
        [result addObject:[NSValue valueWithRect:scene]];
    }
    return [result copy];
}

static BOOL WrappedIsLineEndSpace(NSString *body, NSUInteger index) {
    if ([body characterAtIndex:index] != ' ') return NO;
    NSUInteger next = index + 1;
    while (next < body.length && [body characterAtIndex:next] == ' ') next++;
    return next == body.length || [body characterAtIndex:next] == '\n' ||
        [body characterAtIndex:next] == '\r';
}

static NSUInteger WrappedRealLineFragmentCount(NSLayoutManager *layout) {
    if (!layout || layout.numberOfGlyphs == 0) return 0;
    __block NSUInteger count = 0;
    [layout enumerateLineFragmentsForGlyphRange:NSMakeRange(0, layout.numberOfGlyphs)
        usingBlock:^(NSRect lineRect, NSRect usedRect, NSTextContainer *container,
                     NSRange glyphRange, BOOL *stop) {
            (void)lineRect; (void)usedRect; (void)container; (void)glyphRange; (void)stop;
            count++;
        }];
    return count;
}

typedef struct {
    BOOL valid;
    NSRect cell;
    NSRect glyphBounds;
} WrappedTextInsertionCell;

// TextKit boundingRectForGlyphRange is a glyph bounding box, not necessarily a
// blank character's advance cell. Use exactly one primary insertion point for
// each side of this ASCII space in display order. Missing, duplicate, capped,
// or zero-width boundaries are invalid; callers must count them as failures.
static WrappedTextInsertionCell WrappedTextInsertionCellForCharacter(
    CJGuiInternalComposableSceneNode *node, NSUInteger characterIndex) {
    WrappedTextInsertionCell result = {0};
    NSString *body = node.value ?: @"";
    if (characterIndex >= body.length || [body characterAtIndex:characterIndex] != ' ') return result;
    CjguiPreparedTextNodeLayout *prepared = node.preparedTextLayout;
    NSLayoutManager *layout = prepared.layoutManager;
    NSRange actualCharacters = NSMakeRange(NSNotFound, 0);
    NSRange glyphRange = [layout glyphRangeForCharacterRange:NSMakeRange(characterIndex, 1)
                                          actualCharacterRange:&actualCharacters];
    if (actualCharacters.location != characterIndex || actualCharacters.length != 1 ||
        glyphRange.length != 1 || glyphRange.location >= layout.numberOfGlyphs) return result;

    NSUInteger glyph = glyphRange.location;
    NSRange lineGlyphs = NSMakeRange(NSNotFound, 0);
    NSRect lineRect = [layout lineFragmentRectForGlyphAtIndex:glyph effectiveRange:&lineGlyphs];
    if (lineGlyphs.location == NSNotFound || lineGlyphs.length == 0 ||
        NSIsEmptyRect(lineRect)) return result;
    NSRange lineCharacters = [layout characterRangeForGlyphRange:lineGlyphs actualGlyphRange:NULL];
    if (lineCharacters.location == NSNotFound || lineCharacters.length >= 255 ||
        NSMaxRange(lineCharacters) > body.length) return result;

    CGFloat positions[256] = {0};
    NSUInteger insertionCharacters[256] = {0};
    NSUInteger count = [layout getLineFragmentInsertionPointsForCharacterAtIndex:characterIndex
        alternatePositions:NO inDisplayOrder:YES positions:positions
        characterIndexes:insertionCharacters];
    if (count == 0 || count > 256) return result;
    CGFloat beforeX = 0;
    CGFloat afterX = 0;
    NSUInteger beforeCount = 0;
    NSUInteger afterCount = 0;
    for (NSUInteger i = 0; i < count; i++) {
        if (insertionCharacters[i] == characterIndex) {
            beforeX = positions[i];
            beforeCount++;
        }
        if (insertionCharacters[i] == characterIndex + 1) {
            afterX = positions[i];
            afterCount++;
        }
    }
    CGFloat advance = fabs(afterX - beforeX);
    if (beforeCount != 1 || afterCount != 1 || !isfinite(beforeX) ||
        !isfinite(afterX) || !isfinite(advance) || advance <= 0.01 ||
        NSHeight(lineRect) <= 0.01) return result;

    NSRect nodeRect = CjguiComposableVisualNodeRect(node);
    NSRect sceneTextRect = NSOffsetRect(prepared.textRect, NSMinX(nodeRect), NSMinY(nodeRect));
    CGFloat x = NSMinX(sceneTextRect) + lineRect.origin.x + MIN(beforeX, afterX);
    CGFloat y = NSMinY(sceneTextRect) + lineRect.origin.y;
    result.cell = NSMakeRect(x, y, advance, NSHeight(lineRect));
    result.glyphBounds = [layout boundingRectForGlyphRange:NSMakeRange(glyph, 1)
                                          inTextContainer:prepared.container];
    result.valid = !NSIsEmptyRect(result.cell);
    return result;
}

typedef struct {
    NSUInteger allSamples;
    NSUInteger mismatches;
    NSUInteger lineEndWhitespaceSamples;
    NSUInteger lineEndWhitespaceMismatches;
    NSUInteger selectedLineEndSpaces;
    NSUInteger lineEndSpaceCellMappingFailures;
    NSUInteger unicodeLineEndBoundsWiderThanCells;
    NSUInteger expectedOrdinaryGlyphCenters;
    NSUInteger leftOrdinaryGlyphCentersCovered;
    NSUInteger rightOrdinaryGlyphCentersCovered;
    NSUInteger expectedLineEndSpaceCenters;
    NSUInteger leftLineEndSpaceCentersCovered;
    NSUInteger rightLineEndSpaceCentersCovered;
} WrappedCoverageResult;

// Zed at crates/editor/src/element.rs::paint_highlighted_range clips to the
// visible display-row range and computes a separate x_for_index start/end for
// each shaped row (with line-end overshoot on intermediate rows). Keep this
// oracle tied to CJGUI's actual TextKit glyphs and visible clip so the test
// checks path agreement and nonempty semantic coverage per visible character.
static WrappedCoverageResult CompareWrappedSelectionCoverage(
    CJGuiInternalComposableSceneNode *node, NSArray<NSValue *> *left,
    NSArray<NSValue *> *right, NSRange selected) {
    WrappedCoverageResult result = {0};
    NSString *body = node.value ?: @"";
    CjguiPreparedTextNodeLayout *prepared = node.preparedTextLayout;
    NSRect nodeRect = CjguiComposableVisualNodeRect(node);
    NSRect sceneTextRect = NSOffsetRect(prepared.textRect, NSMinX(nodeRect), NSMinY(nodeRect));
    NSRect visibleText = NSIntersectionRect(sceneTextRect, CjguiComposableVisualClipBounds(node));
    for (NSUInteger index = 0; index < body.length;) {
        NSRange characters = [body rangeOfComposedCharacterSequenceAtIndex:index];
        index = NSMaxRange(characters);
        if (characters.location < selected.location || NSMaxRange(characters) > NSMaxRange(selected)) continue;
        NSString *cluster = [body substringWithRange:characters];
        if ([cluster rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound)
            continue;
        BOOL lineEndSpace = characters.length == 1 && WrappedIsLineEndSpace(body, characters.location);
        BOOL ordinary = [cluster rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location == NSNotFound;
        if (lineEndSpace) {
            result.selectedLineEndSpaces++;
            WrappedTextInsertionCell insertionCell = WrappedTextInsertionCellForCharacter(
                node, characters.location);
            if (!insertionCell.valid) {
                result.lineEndSpaceCellMappingFailures++;
            } else {
                if ([body isEqualToString:kWrappedUnicodeBidiBody] &&
                    NSWidth(insertionCell.glyphBounds) > NSWidth(insertionCell.cell) + 0.01)
                    result.unicodeLineEndBoundsWiderThanCells++;
                NSPoint center = NSMakePoint(NSMidX(insertionCell.cell), NSMidY(insertionCell.cell));
                if (NSPointInRect(center, visibleText)) {
                    result.expectedLineEndSpaceCenters++;
                    if (WrappedGeometryContainsPoint(left, center))
                        result.leftLineEndSpaceCentersCovered++;
                    if (WrappedGeometryContainsPoint(right, center))
                        result.rightLineEndSpaceCentersCovered++;
                }
            }
        }
        for (NSValue *glyphValue in WrappedGlyphSceneRects(node, characters)) {
            NSRect glyph = glyphValue.rectValue;
            NSPoint center = NSMakePoint(NSMidX(glyph), NSMidY(glyph));
            if (!NSPointInRect(center, visibleText)) continue;
            BOOL a = WrappedGeometryContainsPoint(left, center);
            BOOL b = WrappedGeometryContainsPoint(right, center);
            if (ordinary) {
                result.expectedOrdinaryGlyphCenters++;
                if (a) result.leftOrdinaryGlyphCentersCovered++;
                if (b) result.rightOrdinaryGlyphCentersCovered++;
            }
            // Sample actual glyph cells using rectangles emitted by the two
            // native paths; these legacy bbox samples remain a path-difference
            // check, while semantic blank coverage uses insertion cells above.
            for (CGFloat y = NSMinY(glyph) + 0.25; y < NSMaxY(glyph); y += 0.5) {
                for (CGFloat x = NSMinX(glyph) + 0.25; x < NSMaxX(glyph); x += 0.5) {
                    NSPoint sample = NSMakePoint(x, y);
                    BOOL leftPainted = WrappedGeometryContainsPoint(left, sample);
                    BOOL rightPainted = WrappedGeometryContainsPoint(right, sample);
                    result.allSamples++;
                    if (leftPainted != rightPainted) result.mismatches++;
                    if (lineEndSpace) {
                        result.lineEndWhitespaceSamples++;
                        if (leftPainted != rightPainted) result.lineEndWhitespaceMismatches++;
                    }
                }
            }
        }
    }
    NSRect paintArea = visibleText;
    for (CGFloat y = NSMinY(paintArea) + 0.25; y < NSMaxY(paintArea); y += 0.5) {
        for (CGFloat x = NSMinX(paintArea) + 0.25; x < NSMaxX(paintArea); x += 0.5) {
            NSPoint sample = NSMakePoint(x, y);
            if (WrappedGeometryContainsPoint(left, sample) !=
                WrappedGeometryContainsPoint(right, sample)) result.mismatches++;
            result.allSamples++;
        }
    }
    return result;
}

static CJGuiInternalSession *WrappedSelectionProductionFixtureWithClip(
    id<MTLDevice> device, NSString *body, BOOL clippedViewport,
    CGFloat selectionClipOffsetY, CGFloat selectionClipHeight) {
    const CGFloat windowWidth = 680, windowHeight = 1320;
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.app = [NSApplication sharedApplication];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, windowWidth, windowHeight)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, windowWidth, windowHeight)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window.releasedWhenClosed = NO;
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, windowWidth, windowHeight) session:ctx];
    ctx.composableSceneOverlay = overlay;
    ctx.window.contentView = overlay;
    for (NSUInteger index = 0; index < 3; index++) {
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 401 + index; raw.resourceId = 1; raw.projectionVersion = 1;
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x = 0; raw.y = index * 430; raw.width = 180; raw.height = 420;
        raw.clipWidth = windowWidth; raw.clipHeight = windowHeight; raw.fontSize = 13;
        if ((clippedViewport || selectionClipHeight > 0) && index == 1) {
            raw.clipX = 0;
            raw.clipY = raw.y + selectionClipOffsetY;
            raw.clipWidth = 150;
            raw.clipHeight = selectionClipHeight;
        }
        raw.textAlpha = 1; raw.isInteractive = 1;
        node.node = raw; node.index = (uint32_t)index;
        node.value = body;
        node.styleRunsSignature = @""; node.textTextureCacheKey = @"";
        [ctx.stagedComposableNodes addObject:node];
    }
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token || CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return nil;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled = YES;
    ctx.ownedTextSessionNodeId = 401;
    ctx.ownedTextSessionResourceId = 1;
    ctx.ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    ctx.ownedTextSessionBindingEpoch = 81;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    if (![overlay focusCommittedNodeId:401]) return nil;
    [ctx.pendingInteractions removeAllObjects];
    return ctx;
}

static CJGuiInternalSession *WrappedSelectionProductionFixture(id<MTLDevice> device,
                                                                NSString *body,
                                                                BOOL clippedViewport) {
    return WrappedSelectionProductionFixtureWithClip(device, body, clippedViewport,
        0, clippedViewport ? 96 : 0);
}

static NSUInteger WrappedUtf8RunOffset(NSString *body, NSUInteger utf16Offset) {
    if (utf16Offset > body.length) return NSNotFound;
    NSString *prefix = [body substringToIndex:utf16Offset];
    return [prefix lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

static BOOL CommitWrappedSelectionSceneWithClip(CJGuiInternalSession *ctx, uint64_t scene,
                                                NSString *body, uint32_t anchor,
                                                uint32_t focus, BOOL replaceTargetClip,
                                                CGFloat clipOffsetY, CGFloat clipHeight) {
    uint64_t token = ctx.rendererSessionToken;
    NSUInteger start = WrappedUtf8RunOffset(body, MIN(anchor, focus));
    NSUInteger end = WrappedUtf8RunOffset(body, MAX(anchor, focus));
    if (start == NSNotFound || end == NSNotFound || end <= start) return NO;
    NSString *runs = [NSString stringWithFormat:
        @"%lu:%lu:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1",
        (unsigned long)start, (unsigned long)end];
    if (cjgui_internal_renderer_configure_composable_scene(token, scene, 3) !=
        CJGUI_INTERNAL_RENDERER_OK) return NO;
    if (replaceTargetClip) {
        CJGuiInternalComposableSceneNode *target = CjguiCloneComposableSceneNode(
            ctx, ctx.stagedComposableNodes[1], 1, scene);
        if (!target) return NO;
        CjguiInternalRendererComposableNode adjusted = target.node;
        adjusted.clipY = adjusted.y + clipOffsetY;
        adjusted.clipHeight = clipHeight;
        target.node = adjusted;
        ctx.stagedComposableNodes[1] = target;
    }
    ctx.stagedComposableDataTransferVersion = scene;
    if (cjgui_internal_renderer_set_composable_text_runs(token, 402, runs.UTF8String) !=
        CJGUI_INTERNAL_RENDERER_OK) return NO;
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    return ctx.composableSceneVersion == scene && ctx.view.composableNodes.count == 3 &&
        [ctx.view.composableNodes[1].value isEqualToString:body];
}

static BOOL CommitWrappedSelectionScene(CJGuiInternalSession *ctx, uint64_t scene,
                                        NSString *body, uint32_t anchor,
                                        uint32_t focus) {
    return CommitWrappedSelectionSceneWithClip(ctx, scene, body, anchor, focus,
        NO, 0, 0);
}

static BOOL WrappedSelectedGlyphsAreFullyClipped(CJGuiInternalComposableSceneNode *node,
                                                  NSRange selection) {
    NSArray<NSValue *> *glyphRects = WrappedGlyphSceneRects(node, selection);
    if (glyphRects.count == 0) return NO;
    NSRect visibleText = NSIntersectionRect(
        NSOffsetRect(node.preparedTextLayout.textRect,
            NSMinX(CjguiComposableVisualNodeRect(node)),
            NSMinY(CjguiComposableVisualNodeRect(node))),
        CjguiComposableVisualClipBounds(node));
    for (NSValue *value in glyphRects) {
        if (!NSIsEmptyRect(NSIntersectionRect(value.rectValue, visibleText))) return NO;
    }
    return YES;
}

static CjguiPreparedTextNodeLayout *WrappedPreparedLayoutDroppingEnclosingRects(
    CjguiPreparedTextNodeLayout *source) {
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:source.storage];
    WrappedDropEnclosingRectsLayoutManager *layout =
        [WrappedDropEnclosingRectsLayoutManager new];
    NSTextContainer *container = [[NSTextContainer alloc]
        initWithContainerSize:source.container.containerSize];
    container.lineFragmentPadding = source.container.lineFragmentPadding;
    [storage addLayoutManager:layout];
    [layout addTextContainer:container];
    [layout ensureLayoutForTextContainer:container];
    CjguiPreparedTextNodeLayout *prepared = [CjguiPreparedTextNodeLayout new];
    prepared.storage = storage;
    prepared.layoutManager = layout;
    prepared.container = container;
    prepared.textRect = source.textRect;
    return prepared;
}

static CjguiPreparedTextNodeLayout *WrappedIncompletePreparedLayout(NSString *body,
                                                                     NSRect textRect) {
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:body];
    NSLayoutManager *layout = [NSLayoutManager new];
    layout.allowsNonContiguousLayout = YES;
    NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(180, 1)];
    container.lineFragmentPadding = 5;
    [storage addLayoutManager:layout];
    [layout addTextContainer:container];
    [layout ensureLayoutForGlyphRange:NSMakeRange(0, 1)];
    CjguiPreparedTextNodeLayout *prepared = [CjguiPreparedTextNodeLayout new];
    prepared.storage = storage;
    prepared.layoutManager = layout;
    prepared.container = container;
    prepared.textRect = textRect;
    return prepared;
}

static CjguiPreparedTextNodeLayout *WrappedPreparedLayoutOverrunningRectBudget(
    CjguiPreparedTextNodeLayout *source, NSRect repeatedRect, NSPoint sceneTextOrigin) {
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:source.storage];
    WrappedBudgetOverrunLayoutManager *layout = [WrappedBudgetOverrunLayoutManager new];
    layout.repeatedRect = NSOffsetRect(repeatedRect,
        -sceneTextOrigin.x, -sceneTextOrigin.y);
    NSTextContainer *container = [[NSTextContainer alloc]
        initWithContainerSize:source.container.containerSize];
    container.lineFragmentPadding = source.container.lineFragmentPadding;
    [storage addLayoutManager:layout];
    [layout addTextContainer:container];
    [layout ensureLayoutForTextContainer:container];
    CjguiPreparedTextNodeLayout *prepared = [CjguiPreparedTextNodeLayout new];
    prepared.storage = storage;
    prepared.layoutManager = layout;
    prepared.container = container;
    prepared.textRect = source.textRect;
    return prepared;
}

static void RunZeroVisibleResidencyCase(id<MTLDevice> device, const char *name,
                                        uint32_t anchor, uint32_t focus,
                                        CGFloat clipOffsetY, CGFloat clipHeight) {
    CJGuiInternalSession *ctx = WrappedSelectionProductionFixtureWithClip(
        device, kZeroVisibleResidencyBody, NO, clipOffsetY, clipHeight);
    if (!ctx) { CHECK(NO, name); return; }
    CHECK(kZeroVisibleResidencyBody.length == 85,
          "zero_visible_fixture_has_exact_85_utf16_body");
    CHECK(CommitWrappedSelectionScene(ctx, 2, kZeroVisibleResidencyBody, anchor, focus),
          "zero_visible_exact_range_is_in_real_accepted_scene");
    CJGuiInternalComposableSceneNode *target = ctx.composableSceneOverlay.nodes[1];
    CjguiPreparedTextNodeLayout *layout = target.preparedTextLayout;
    NSRange selected = NSMakeRange(MIN(anchor, focus),
        (NSUInteger)llabs((int64_t)focus - (int64_t)anchor));
    NSRect nodeRect = CjguiComposableVisualNodeRect(target);
    NSRect sceneText = NSOffsetRect(layout.textRect, NSMinX(nodeRect), NSMinY(nodeRect));
    NSRect clip = CjguiComposableVisualClipBounds(target);
    NSRect visibleText = NSIntersectionRect(sceneText, clip);
    CHECK(ctx.composableSceneVersion == 2 && target.node.width == 180 &&
          [layout.storage.string isEqualToString:kZeroVisibleResidencyBody] &&
          layout.layoutManager.firstUnlaidCharacterIndex == kZeroVisibleResidencyBody.length &&
          WrappedRealLineFragmentCount(layout.layoutManager) >= 3,
          "zero_visible_full_real_layout_and_accepted_scene");
    CHECK(!NSIsEmptyRect(NSIntersectionRect(nodeRect, clip)) &&
          !NSIsEmptyRect(visibleText) && NSHeight(visibleText) < NSHeight(sceneText),
          "zero_visible_target_and_partial_text_viewport_are_really_visible");
    CHECK(WrappedSelectedGlyphsAreFullyClipped(target, selected),
          "zero_visible_selected_source_glyphs_are_all_outside_current_clip");
    CjguiSelectionPaintGeometry *emptyProof = CjguiPreparedSelectionPaintGeometry(
        layout, selected, sceneText, visibleText);
    CHECK(emptyProof && emptyProof.completion ==
              CjguiSelectionPaintGeometryCompleteClippedEmpty && emptyProof.rects.count == 0,
          "zero_visible_empty_has_same_graph_complete_clip_proof");

    NSArray<NSValue *> *declaredBefore = WrappedGeometryFromDecorations(
        target.textDeclaredSelectionDecorations);
    CHECK(declaredBefore.count == 0,
          "zero_visible_real_declaration_has_no_visible_rectangles");
    BOOL installed = InstallSelectionOnSameAcceptedScene(ctx, anchor, focus);
    target = ctx.composableSceneOverlay.nodes[1];
    NSArray<NSValue *> *proxyRects = [target.textSelectionRects copy];
    NSArray<NSValue *> *declaredAfter = WrappedGeometryFromDecorations(
        target.textDeclaredSelectionDecorations);
    CHECK(installed && ctx.installedRangeBasis.hasReceipt &&
          ctx.composableSceneVersion == 2 &&
          NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange, selected),
          "zero_visible_real_transfer_installs_same_source_range_and_receipt");
    CHECK(proxyRects.count == 0 && declaredAfter.count == 0 &&
          [proxyRects isEqualToArray:declaredAfter],
          "zero_visible_installed_and_declared_geometry_are_same_empty_result");

    BOOL revealedScene = CommitWrappedSelectionSceneWithClip(ctx, 3,
        kZeroVisibleResidencyBody, anchor, focus, YES, 0, 96);
    target = ctx.composableSceneOverlay.nodes[1];
    NSArray<NSValue *> *revealedDeclaration = WrappedGeometryFromDecorations(
        target.textDeclaredSelectionDecorations);
    CHECK(revealedScene && ctx.composableSceneVersion == 3 &&
          [target.value isEqualToString:kZeroVisibleResidencyBody] &&
          target.preparedTextLayout.layoutManager.firstUnlaidCharacterIndex ==
              kZeroVisibleResidencyBody.length && revealedDeclaration.count > 0 &&
          !WrappedSelectedGlyphsAreFullyClipped(target, selected),
          "zero_visible_same_choice_reappears_in_new_visible_accepted_scene");
    nodeRect = CjguiComposableVisualNodeRect(target);
    sceneText = NSOffsetRect(target.preparedTextLayout.textRect,
        NSMinX(nodeRect), NSMinY(nodeRect));
    visibleText = NSIntersectionRect(sceneText, CjguiComposableVisualClipBounds(target));
    CjguiSelectionPaintGeometry *visibleProof = CjguiPreparedSelectionPaintGeometry(
        target.preparedTextLayout, selected, sceneText, visibleText);
    CHECK(visibleProof && visibleProof.completion ==
              CjguiSelectionPaintGeometryCompleteVisible && visibleProof.rects.count > 0,
          "revealed_same_graph_has_complete_visible_geometry");
    CjguiPreparedTextNodeLayout *overBudget = WrappedPreparedLayoutOverrunningRectBudget(
        target.preparedTextLayout, visibleProof.rects.firstObject.rectValue,
        NSMakePoint(NSMinX(sceneText), NSMinY(sceneText)));
    CjguiSelectionPaintGeometry *overBudgetProof = CjguiPreparedSelectionPaintGeometry(
        overBudget, selected, sceneText, visibleText);
    CHECK(overBudget.layoutManager.firstUnlaidCharacterIndex == overBudget.storage.length &&
          !overBudgetProof,
          "1025_visible_enclosing_rects_interrupt_budget_without_empty_success");
    CjguiPreparedTextNodeLayout *dropped = WrappedPreparedLayoutDroppingEnclosingRects(
        target.preparedTextLayout);
    CHECK(dropped && [dropped.storage.string isEqualToString:kZeroVisibleResidencyBody] &&
          dropped.layoutManager.firstUnlaidCharacterIndex == dropped.storage.length,
          "visible_enumeration_mutation_retains_full_same_body_graph");
    CjguiSelectionPaintGeometry *droppedProof = CjguiPreparedSelectionPaintGeometry(
        dropped, selected, sceneText, visibleText);
    CHECK(!droppedProof,
          "visible_characters_with_enclosing_rects_dropped_are_not_clipped_empty");
    NSArray<NSValue *> *rejectedRects = nil;
    BOOL missingGraphAccepted = CjguiBuildAcceptedTextSelectionGeometry(ctx, target,
        [CjguiPreparedTextNodeLayout new], ctx.composableSceneOverlay.inputProxy,
        selected, &rejectedRects, NULL, NO);
    CHECK(!missingGraphAccepted,
          "missing_text_graph_still_rejected_by_actual_install_geometry_gate");
    CjguiPreparedTextNodeLayout *incomplete = WrappedIncompletePreparedLayout(
        kZeroVisibleResidencyBody, target.preparedTextLayout.textRect);
    fprintf(stderr, "WRAPPED_INCOMPLETE_DIAGNOSTIC body=%lu firstUnlaid=%lu glyphs=%lu "
        "container=%.1fx%.1f allowsNonContiguous=%u\n",
        (unsigned long)incomplete.storage.length,
        (unsigned long)incomplete.layoutManager.firstUnlaidCharacterIndex,
        (unsigned long)incomplete.layoutManager.numberOfGlyphs,
        incomplete.container.containerSize.width, incomplete.container.containerSize.height,
        incomplete.layoutManager.allowsNonContiguousLayout);
    CHECK(incomplete.layoutManager.firstUnlaidCharacterIndex < incomplete.storage.length,
          "incomplete_negative_fixture_stops_before_same_body_end");
    BOOL incompleteAccepted = CjguiBuildAcceptedTextSelectionGeometry(ctx, target,
        incomplete, ctx.composableSceneOverlay.inputProxy, selected,
        &rejectedRects, NULL, NO);
    CHECK(!incompleteAccepted,
          "incomplete_text_graph_still_rejected_by_actual_install_geometry_gate");
    NSRect retainedTextRect = target.preparedTextLayout.textRect;
    target.preparedTextLayout.textRect = NSOffsetRect(retainedTextRect, 0, 1);
    BOOL wrongTextRectAccepted = CjguiBuildAcceptedTextSelectionGeometry(ctx, target,
        target.preparedTextLayout, ctx.composableSceneOverlay.inputProxy, selected,
        &rejectedRects, NULL, NO);
    target.preparedTextLayout.textRect = retainedTextRect;
    CHECK(!wrongTextRectAccepted,
          "wrong_text_rect_still_rejected_by_actual_install_geometry_gate");
    CJGuiInternalComposableSceneNode *wrongBody = CjguiCloneComposableSceneNode(ctx,
        target, target.index, target.node.projectionVersion);
    wrongBody.value = [@"X" stringByAppendingString:
        [kZeroVisibleResidencyBody substringFromIndex:1]];
    BOOL wrongBodyAccepted = CjguiBuildAcceptedTextSelectionGeometry(ctx, wrongBody,
        target.preparedTextLayout, ctx.composableSceneOverlay.inputProxy, selected,
        &rejectedRects, NULL, NO);
    CHECK(wrongBody.value.length == kZeroVisibleResidencyBody.length &&
          !wrongBodyAccepted,
          "equal_length_wrong_body_still_rejected_by_actual_install_geometry_gate");
    BOOL visibleInstalled = revealedScene &&
        InstallSelectionOnSameAcceptedScene(ctx, anchor, focus);
    target = ctx.composableSceneOverlay.nodes[1];
    NSArray<NSValue *> *revealedProxy = [target.textSelectionRects copy];
    CHECK(visibleInstalled && ctx.installedRangeBasis.hasReceipt &&
          ctx.installedRangeBasis.candidate.installedSceneVersion == 3 &&
          NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange, selected) &&
          revealedProxy.count > 0,
          "zero_visible_reveal_runs_real_B_and_restores_visible_proxy_coverage");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void RunWrappedSelectionCase(id<MTLDevice> device, NSString *body,
                                     BOOL clippedViewport, const char *name,
                                     uint32_t anchor, uint32_t focus) {
    CJGuiInternalSession *ctx = WrappedSelectionProductionFixture(device, body, clippedViewport);
    if (!ctx) { CHECK(NO, name); return; }
    NSUInteger bodyLength = body.length;
    CHECK(bodyLength < UINT32_MAX && focus <= bodyLength && anchor <= bodyLength,
          "wrapped_case_range_within_fixed_body");
    if (bodyLength >= UINT32_MAX || focus > bodyLength || anchor > bodyLength) {
        cjgui_internal_renderer_destroy(ctx.rendererSessionToken); return;
    }
    CHECK(CommitWrappedSelectionScene(ctx, 2, body, anchor, focus),
          "wrapped_owner_declaration_accepted_scene");
    CJGuiInternalComposableSceneNode *target = ctx.view.composableNodes[1];
    NSArray<NSValue *> *ownerBefore = WrappedGeometryFromDecorations(
        target.textDeclaredSelectionDecorations);
    CjguiPreparedTextNodeLayout *layoutBefore = target.preparedTextLayout;
    NSUInteger lineFragments = WrappedRealLineFragmentCount(layoutBefore.layoutManager);
    CHECK(layoutBefore.layoutManager.numberOfGlyphs > 1 &&
          layoutBefore.layoutManager.firstUnlaidCharacterIndex == bodyLength &&
          NSWidth(target.preparedTextLayout.textRect) < 180 && lineFragments >= 3,
          "wrapped_fixture_uses_full_real_180pt_layout");
    if (clippedViewport) {
        NSRect clip = CjguiComposableVisualClipBounds(target);
        NSRect nodeRect = CjguiComposableVisualNodeRect(target);
        NSRect sceneText = NSOffsetRect(layoutBefore.textRect, NSMinX(nodeRect), NSMinY(nodeRect));
        NSRect visible = NSIntersectionRect(sceneText, clip);
        CHECK(NSWidth(visible) > 0 && NSHeight(visible) > 0 &&
              NSWidth(visible) < NSWidth(sceneText) && NSHeight(visible) < NSHeight(sceneText),
              "clipped_variant_really_exposes_only_partial_text_lines");
    }
    CHECK(ownerBefore.count > 0, "wrapped_owner_path_emits_actual_declared_rects");

    BOOL installed = InstallSelectionOnSameAcceptedScene(ctx, anchor, focus);
    target = ctx.view.composableNodes[1];
    NSArray<NSValue *> *proxyInstalled = [target.textSelectionRects copy];
    NSRange selected = NSMakeRange(MIN(anchor, focus), (NSUInteger)llabs((int64_t)focus - anchor));
    WrappedCoverageResult ownerVsProxy = CompareWrappedSelectionCoverage(
        target, ownerBefore, proxyInstalled, selected);
    fprintf(stderr, "WRAPPED_SELECTION_CASE name=%s scene=%llu body16=%lu nodeWidth=%.1f "
        "layout=%p container=%p runs=%lu:%lu ownerRects=%lu proxyRects=%lu installed=%u "
        "sampledPixels=%lu mismatchPixels=%lu lineEndSpaces=%lu lineEndSamples=%lu "
        "lineEndMismatch=%lu lineEndCellFailures=%lu unicodeWideBounds=%lu "
        "glyphCenters=%lu/%lu,%lu lineEndCenters=%lu/%lu,%lu "
        "range=%lu:%lu\n",
        name, (unsigned long long)ctx.composableSceneVersion, (unsigned long)bodyLength,
        NSWidth(target.preparedTextLayout.textRect), target.preparedTextLayout.layoutManager,
        target.preparedTextLayout.container, (unsigned long)selected.location,
        (unsigned long)NSMaxRange(selected), (unsigned long)ownerBefore.count,
        (unsigned long)proxyInstalled.count, installed, (unsigned long)ownerVsProxy.allSamples,
        (unsigned long)ownerVsProxy.mismatches,
        (unsigned long)ownerVsProxy.selectedLineEndSpaces,
        (unsigned long)ownerVsProxy.lineEndWhitespaceSamples,
        (unsigned long)ownerVsProxy.lineEndWhitespaceMismatches,
        (unsigned long)ownerVsProxy.lineEndSpaceCellMappingFailures,
        (unsigned long)ownerVsProxy.unicodeLineEndBoundsWiderThanCells,
        (unsigned long)ownerVsProxy.expectedOrdinaryGlyphCenters,
        (unsigned long)ownerVsProxy.leftOrdinaryGlyphCentersCovered,
        (unsigned long)ownerVsProxy.rightOrdinaryGlyphCentersCovered,
        (unsigned long)ownerVsProxy.expectedLineEndSpaceCenters,
        (unsigned long)ownerVsProxy.leftLineEndSpaceCentersCovered,
        (unsigned long)ownerVsProxy.rightLineEndSpaceCentersCovered,
        (unsigned long)anchor, (unsigned long)focus);
    CHECK(installed && ctx.installedRangeBasis.hasReceipt &&
          ctx.composableSceneOverlay.inputProxy.selectedRange.location == selected.location &&
          ctx.composableSceneOverlay.inputProxy.selectedRange.length == selected.length &&
          proxyInstalled.count > 0,
          "wrapped_actual_native_B_receipt_and_proxy_geometry");
    CHECK(target.preparedTextLayout == layoutBefore &&
          [target.preparedTextLayout.storage.string isEqualToString:body] &&
          target.node.width == 180 && target.node.fontSize == 13,
          "wrapped_same_frozen_layout_identity_during_actual_B");
    CHECK(ownerVsProxy.selectedLineEndSpaces > 0 && ownerVsProxy.lineEndWhitespaceSamples > 0,
          "wrapped_selected_line_end_whitespace_is_sampled");
    CHECK(ownerVsProxy.lineEndSpaceCellMappingFailures == 0,
          "wrapped_every_selected_line_end_space_has_two_unambiguous_primary_insertions");
    CHECK(ownerVsProxy.expectedOrdinaryGlyphCenters > 0 &&
          ownerVsProxy.leftOrdinaryGlyphCentersCovered == ownerVsProxy.expectedOrdinaryGlyphCenters &&
          ownerVsProxy.rightOrdinaryGlyphCentersCovered == ownerVsProxy.expectedOrdinaryGlyphCenters,
          "wrapped_both_real_paths_cover_every_visible_selected_ordinary_glyph_center");
    CHECK(ownerVsProxy.expectedLineEndSpaceCenters > 0 &&
          ownerVsProxy.leftLineEndSpaceCentersCovered == ownerVsProxy.expectedLineEndSpaceCenters &&
          ownerVsProxy.rightLineEndSpaceCentersCovered == ownerVsProxy.expectedLineEndSpaceCenters,
          "wrapped_both_real_paths_cover_every_visible_selected_line_end_insertion_cell_center");
    if ([body isEqualToString:kWrappedUnicodeBidiBody]) {
        CHECK(ownerVsProxy.selectedLineEndSpaces == 6 &&
              ownerVsProxy.expectedLineEndSpaceCenters == 6 &&
              ownerVsProxy.unicodeLineEndBoundsWiderThanCells == 6,
              "unicode_six_real_blank_cells_are_distinct_from_wide_glyph_bounds");
    }
    CHECK(ownerVsProxy.mismatches == 0 && ownerVsProxy.lineEndWhitespaceMismatches == 0,
          "wrapped_declared_and_real_proxy_pixel_coverage_match_before_scene_handoff");

    BOOL acceptedNext = CommitWrappedSelectionScene(ctx, 3, body, anchor, focus);
    target = ctx.composableSceneOverlay.nodes[1];
    NSArray<NSValue *> *ownerAfter = WrappedGeometryFromDecorations(
        target.textDeclaredSelectionDecorations);
    WrappedCoverageResult proxyVsNewOwner = CompareWrappedSelectionCoverage(
        target, proxyInstalled, ownerAfter, selected);
    fprintf(stderr, "WRAPPED_SELECTION_HANDOFF name=%s accepted=%u scene=%llu "
        "body16=%lu ownerBefore=%lu proxyB=%lu ownerAfter=%lu sampledPixels=%lu "
        "mismatchPixels=%lu lineEndSpaces=%lu lineEndSamples=%lu lineEndMismatch=%lu "
        "lineEndCellFailures=%lu unicodeWideBounds=%lu glyphCenters=%lu/%lu,%lu "
        "lineEndCenters=%lu/%lu,%lu "
        "receiptScene=%llu acceptedScene=%llu\n",
        name, acceptedNext, (unsigned long long)ctx.composableSceneVersion,
        (unsigned long)bodyLength, (unsigned long)ownerBefore.count,
        (unsigned long)proxyInstalled.count, (unsigned long)ownerAfter.count,
        (unsigned long)proxyVsNewOwner.allSamples, (unsigned long)proxyVsNewOwner.mismatches,
        (unsigned long)proxyVsNewOwner.selectedLineEndSpaces,
        (unsigned long)proxyVsNewOwner.lineEndWhitespaceSamples,
        (unsigned long)proxyVsNewOwner.lineEndWhitespaceMismatches,
        (unsigned long)proxyVsNewOwner.lineEndSpaceCellMappingFailures,
        (unsigned long)proxyVsNewOwner.unicodeLineEndBoundsWiderThanCells,
        (unsigned long)proxyVsNewOwner.expectedOrdinaryGlyphCenters,
        (unsigned long)proxyVsNewOwner.leftOrdinaryGlyphCentersCovered,
        (unsigned long)proxyVsNewOwner.rightOrdinaryGlyphCentersCovered,
        (unsigned long)proxyVsNewOwner.expectedLineEndSpaceCenters,
        (unsigned long)proxyVsNewOwner.leftLineEndSpaceCentersCovered,
        (unsigned long)proxyVsNewOwner.rightLineEndSpaceCentersCovered,
        (unsigned long long)ctx.installedRangeBasis.candidate.installedSceneVersion,
        (unsigned long long)ctx.composableSceneVersion);
    CHECK(acceptedNext && ctx.composableSceneVersion == 3 && ownerAfter.count > 0 &&
          ctx.installedRangeBasis.candidate.installedSceneVersion == 2,
          "wrapped_same_body_range_layout_accepted_after_real_B");
    NSString *expectedRuns = [NSString stringWithFormat:
        @"%lu:%lu:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1",
        (unsigned long)WrappedUtf8RunOffset(body, selected.location),
        (unsigned long)WrappedUtf8RunOffset(body, NSMaxRange(selected))];
    CHECK([target.preparedTextLayout.storage.string isEqualToString:body] &&
          target.node.width == 180 && target.node.fontSize == 13 &&
          NSEqualRects(target.preparedTextLayout.textRect, layoutBefore.textRect) &&
          [target.styleRunsSignature isEqualToString:expectedRuns],
          "wrapped_next_scene_keeps_same_body_range_runs_font_and_layout_rect");
    CHECK(proxyVsNewOwner.selectedLineEndSpaces > 0 &&
          proxyVsNewOwner.lineEndWhitespaceSamples > 0,
          "wrapped_handoff_samples_selected_line_end_whitespace");
    CHECK(proxyVsNewOwner.lineEndSpaceCellMappingFailures == 0,
          "wrapped_handoff_every_line_end_space_has_two_unambiguous_primary_insertions");
    CHECK(proxyVsNewOwner.expectedOrdinaryGlyphCenters > 0 &&
          proxyVsNewOwner.leftOrdinaryGlyphCentersCovered == proxyVsNewOwner.expectedOrdinaryGlyphCenters &&
          proxyVsNewOwner.rightOrdinaryGlyphCentersCovered == proxyVsNewOwner.expectedOrdinaryGlyphCenters,
          "wrapped_handoff_both_paths_cover_every_visible_selected_ordinary_glyph_center");
    CHECK(proxyVsNewOwner.expectedLineEndSpaceCenters > 0 &&
          proxyVsNewOwner.leftLineEndSpaceCentersCovered == proxyVsNewOwner.expectedLineEndSpaceCenters &&
          proxyVsNewOwner.rightLineEndSpaceCentersCovered == proxyVsNewOwner.expectedLineEndSpaceCenters,
          "wrapped_handoff_both_paths_cover_every_visible_line_end_insertion_cell_center");
    if ([body isEqualToString:kWrappedUnicodeBidiBody]) {
        CHECK(proxyVsNewOwner.selectedLineEndSpaces == 6 &&
              proxyVsNewOwner.expectedLineEndSpaceCenters == 6 &&
              proxyVsNewOwner.unicodeLineEndBoundsWiderThanCells == 6,
              "unicode_handoff_preserves_all_six_blank_cells_and_bounds_contrast");
    }
    CHECK(proxyVsNewOwner.mismatches == 0 &&
          proxyVsNewOwner.lineEndWhitespaceMismatches == 0,
          "wrapped_real_proxy_and_next_accepted_scene_pixel_coverage_match");
    if ([body isEqualToString:kWrappedUnicodeBidiBody]) {
        NSRange emoji = [body rangeOfString:@"🙂"];
        NSRange splitScalar = NSMakeRange(emoji.location + 1, 1);
        NSTextView *proxy = ctx.composableSceneOverlay.inputProxy;
        NSRange originalProxyRange = proxy.selectedRange;
        [proxy setSelectedRange:splitScalar];
        NSRange actualProxyRange = proxy.selectedRange;
        NSArray<NSValue *> *invalidRects = nil;
        BOOL splitScalarAccepted = CjguiBuildAcceptedTextSelectionGeometry(ctx, target,
            target.preparedTextLayout, proxy, splitScalar, &invalidRects, NULL, NO);
        NSRange normalizedActual = actualProxyRange.location == NSNotFound
            ? actualProxyRange
            : CjguiComposedSelection(body, actualProxyRange.location, NSMaxRange(actualProxyRange));
        [proxy setSelectedRange:originalProxyRange];
        fprintf(stderr, "WRAPPED_SPLIT_SCALAR_DIAGNOSTIC emoji=%lu:%lu split=%lu:%lu "
            "actualProxy=%lu:%lu normalizedActual=%lu:%lu rejected=%u\n",
            (unsigned long)emoji.location, (unsigned long)emoji.length,
            (unsigned long)splitScalar.location, (unsigned long)splitScalar.length,
            (unsigned long)actualProxyRange.location, (unsigned long)actualProxyRange.length,
            (unsigned long)normalizedActual.location, (unsigned long)normalizedActual.length,
            !splitScalarAccepted);
        BOOL proxyKeptInvalidSplit = NSEqualRanges(actualProxyRange, splitScalar);
        BOOL appKitStoredComposedRange = actualProxyRange.location != NSNotFound &&
            NSEqualRanges(normalizedActual, actualProxyRange);
        CHECK(emoji.location != NSNotFound && emoji.length == 2 &&
              (proxyKeptInvalidSplit || appKitStoredComposedRange) && !splitScalarAccepted,
              "unicode_half_surrogate_is_rejected_by_real_geometry_gate");
    }
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

int main(void) {
    @autoreleasepool {
        unsetenv("CJGUI_OWNER_PHASE_TRACE");
        unsetenv("CJGUI_OWNER_TURN_TRACE");
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "SKIP no Metal device\n"); return 77; }
        NSUInteger end = kWrappedSelectionBody.length;
        RunWrappedSelectionCase(device, kWrappedSelectionBody, NO, "forward_full", 0, (uint32_t)end);
        RunWrappedSelectionCase(device, kWrappedSelectionBody, NO, "reverse_full", (uint32_t)end, 0);
        RunWrappedSelectionCase(device, kWrappedSelectionBody, NO, "move_start_one", 1, (uint32_t)end);
        RunWrappedSelectionCase(device, kWrappedSelectionBody, NO, "move_end_back_one", 0, (uint32_t)end - 1);
        RunWrappedSelectionCase(device, kWrappedSelectionBody, NO, "reverse_start_one", (uint32_t)end - 1, 0);
        RunWrappedSelectionCase(device, kWrappedSelectionBody, NO, "reverse_end_back_one", (uint32_t)end, 1);
        NSUInteger clippedEnd = kWrappedClippedBody.length;
        RunWrappedSelectionCase(device, kWrappedClippedBody, YES,
            "clipped_partial_lines", 0, (uint32_t)clippedEnd);
        NSUInteger unicodeEnd = kWrappedUnicodeBidiBody.length;
        RunWrappedSelectionCase(device, kWrappedUnicodeBidiBody, NO,
            "unicode_bidi_full", 0, (uint32_t)unicodeEnd);
        RunZeroVisibleResidencyCase(device, "resident_top_selection_outside_clip",
            0, 2, 24, 72);
        RunZeroVisibleResidencyCase(device, "resident_bottom_reverse_selection_outside_clip",
            85, 83, 0, 28);
        fprintf(stderr, "wrapped selection paint geometry production failures=%d\n", failures);
    }
    return failures ? 1 : 0;
}
