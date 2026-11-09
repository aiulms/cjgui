// The public button content-alignment fact must reach actual text geometry:
// START/CENTER/END, the raster key, the retained-layout source and the
// drawWithRect paragraph. Same node, same text, same size; only alignment
// changes. This is the native counterexample the region-signature test does
// not cover.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <math.h>

static int failures;

#define CHECK(condition, label) do { \
    BOOL ok = (condition); \
    fprintf(stderr, "content_align case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static CJGuiInternalComposableSceneNode *makeButton(int64_t alignX, int64_t alignY) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 7001;
    raw.resourceId = 7001;
    raw.projectionVersion = 1;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    raw.x = 10; raw.y = 10; raw.width = 140; raw.height = 32;
    raw.clipX = 10; raw.clipY = 10; raw.clipWidth = 140; raw.clipHeight = 32;
    raw.textAlpha = 1.0;
    raw.fontSize = 13.0;
    raw.fontWeight = 400;
    raw.textMaxLines = 1;
    raw.contentAlignX = alignX;
    raw.contentAlignY = alignY;
    node.node = raw;
    node.value = @"Reset 42";
    node.label = node.value;
    node.semanticId = @"content-align-button";
    node.semanticBindingKey = @"content-align-binding";
    node.semanticLabel = node.value;
    node.semanticRowKey = @"";
    node.semanticParentRowKey = @"";
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    return node;
}

static CjguiPreparedTextNodeLayout *build(CJGuiInternalComposableSceneNode *node) {
    NSFont *font = nil;
    NSAttributedString *frozen = CjguiFreezeTextAttributes(node, node.value, nil, &font);
    if (!frozen || !font) return nil;
    return CjguiBuildPreparedAttributedLayout(node, frozen, font, NULL, 1);
}

static CGFloat maxBottom(NSRect rect) { return rect.origin.y + rect.size.height; }

int main(void) {
    @autoreleasepool {
        CJGuiInternalComposableSceneNode *start = makeButton(0, 0);
        CJGuiInternalComposableSceneNode *center = makeButton(2, 2);
        CJGuiInternalComposableSceneNode *end = makeButton(2, 3);

        CjguiPreparedTextNodeLayout *startLayout = build(start);
        CjguiPreparedTextNodeLayout *centerLayout = build(center);
        CjguiPreparedTextNodeLayout *endLayout = build(end);
        CHECK(startLayout && centerLayout && endLayout, "prepared_layouts_exist");
        if (startLayout && centerLayout && endLayout) {
            CHECK(startLayout.textRect.origin.y < centerLayout.textRect.origin.y,
                "center_below_start");
            CHECK(centerLayout.textRect.origin.y < endLayout.textRect.origin.y,
                "end_below_center");
            CHECK(fabs(maxBottom(startLayout.textRect) - maxBottom(endLayout.textRect)) < 0.01,
                "end_bottom_matches_start_bottom");
            CHECK(fabs(centerLayout.textRect.size.height - endLayout.textRect.size.height) < 0.01,
                "line_box_height_preserved");
            [endLayout.layoutManager ensureLayoutForTextContainer:endLayout.container];
            NSRect used = [endLayout.layoutManager usedRectForTextContainer:endLayout.container];
            CHECK(used.size.height > 0.0, "end_layout_has_used_rect");
            [centerLayout.layoutManager ensureLayoutForTextContainer:centerLayout.container];
            NSRect centeredUsed = [centerLayout.layoutManager usedRectForTextContainer:centerLayout.container];
            CGFloat expectedX = (centerLayout.container.size.width - centeredUsed.size.width) / 2.0;
            CHECK(fabs(centeredUsed.origin.x - expectedX) < 0.51,
                "horizontal_center_glyph_origin");
            [startLayout.layoutManager ensureLayoutForTextContainer:startLayout.container];
            NSRect startUsed = [startLayout.layoutManager usedRectForTextContainer:startLayout.container];
            CHECK(fabs(startUsed.origin.x) < 0.51, "start_glyph_origin");
        }

        NSRect coverage = NSMakeRect(10, 10, 140, 32);
        NSString *text = @"Reset 42";
        NSString *startKey = CjguiComposableTextTextureKey(start, 2.0, 2.0, text, coverage);
        NSString *centerKey = CjguiComposableTextTextureKey(center, 2.0, 2.0, text, coverage);
        NSString *endKey = CjguiComposableTextTextureKey(end, 2.0, 2.0, text, coverage);
        CHECK(![startKey isEqualToString:centerKey], "vertical_center_changes_key");
        CHECK(![centerKey isEqualToString:endKey], "vertical_end_changes_key");
        CJGuiInternalComposableSceneNode *left = makeButton(0, 0);
        CJGuiInternalComposableSceneNode *middle = makeButton(2, 0);
        CHECK(![CjguiComposableTextTextureKey(left, 2.0, 2.0, text, coverage)
            isEqualToString:CjguiComposableTextTextureKey(middle, 2.0, 2.0, text, coverage)],
            "horizontal_center_changes_key");

        if (startLayout) {
            NSArray<NSValue *> *tiles = @[[NSValue valueWithRect:coverage]];
            start.preparedTextLayout = startLayout;
            CjguiTextRasterSourceCredential *same = CjguiRetainedLayoutRasterSource(start, 2.0, text,
                coverage, tiles);
            CHECK(same != nil, "retained_source_available_for_same_alignment");
            CjguiInternalRendererComposableNode raw = start.node;
            raw.contentAlignY = 3;
            start.node = raw;
            CjguiTextRasterSourceCredential *moved = CjguiRetainedLayoutRasterSource(start, 2.0, text,
                coverage, tiles);
            CHECK(moved == nil, "retained_source_refused_after_vertical_change");
            raw.contentAlignY = 0;
            raw.contentAlignX = 2;
            start.node = raw;
            CjguiTextRasterSourceCredential *shifted = CjguiRetainedLayoutRasterSource(start, 2.0, text,
                coverage, tiles);
            CHECK(shifted == nil, "retained_source_refused_after_horizontal_change");
        }

        printf("%s\n", failures == 0 ? "PASS text content alignment (START/CENTER/END, key, retained source)"
                                     : "FAIL text content alignment");
        return failures == 0 ? 0 : 1;
    }
}
