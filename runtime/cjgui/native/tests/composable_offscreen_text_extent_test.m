#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static NSString *fixtureBody(void) {
    NSMutableString *body = [NSMutableString string];
    NSString *phrase = @"static extent coverage remains a derived GPU memo ";
    for (NSUInteger index = 0; index < 80; index++) [body appendString:phrase];
    return body;
}

static CJGuiInternalComposableSceneNode *fixtureNode(NSString *body, uint64_t nodeId,
                                                       CGFloat y, CGFloat translateY) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.nodeId = nodeId;
    raw.resourceId = 1;
    raw.projectionVersion = 1;
    raw.x = 40; raw.y = y; raw.width = 280; raw.height = 30000;
    raw.clipX = 0; raw.clipY = 0; raw.clipWidth = 680; raw.clipHeight = 500;
    raw.clipConstraintCount = 1;
    raw.clip0X = 0; raw.clip0Y = 0; raw.clip0Width = 680; raw.clip0Height = 500;
    raw.fontSize = 14;
    raw.textRed = 0.1; raw.textGreen = 0.2; raw.textBlue = 0.3; raw.textAlpha = 1.0;
    node.node = raw;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = nodeId;
    geometry.translateY = translateY;
    node.geometry = geometry;
    node.value = body;
    node.textMeasureValid = NO;
    node.testTextExtentMeasurementCount = 0;
    return node;
}

static BOOL sameRect(NSRect a, NSRect b) {
    return NSEqualRects(a, b);
}

static NSRect measuredBoundsForNode(CJGuiInternalComposableSceneNode *node) {
    CjguiInternalRendererComposableNode value = node.node;
    NSRect nodeRect = NSMakeRect((CGFloat)value.x, (CGFloat)value.y,
                                 MAX(0.0, (CGFloat)value.width), MAX(0.0, (CGFloat)value.height));
    CGFloat insetY = CjguiComposableNodeUsesLabelTextInset(value.nodeKind) ? 2.0 : 6.0;
    NSRect drawRect = NSInsetRect(nodeRect, 7.0, insetY);
    NSSize extent = node.textMeasuredExtent;
    CGFloat drawnWidth = MIN(NSWidth(drawRect), MAX(1.0, ceil(extent.width) + 2.0));
    CGFloat drawnHeight = MIN(NSHeight(drawRect), MAX(1.0, ceil(extent.height) + 2.0));
    return NSIntersectionRect(nodeRect,
        NSMakeRect(NSMinX(drawRect) - 1.0, NSMinY(drawRect) - 1.0,
                   drawnWidth + 2.0, drawnHeight + 2.0));
}

// Reconstruct the pre-early-return helper's order: measurement shrinks nodeRect
// before visualBody is intersected with the clip.
static NSRect oldCoverageOracle(CJGuiInternalComposableSceneNode *node) {
    NSRect measuredBounds = measuredBoundsForNode(node);
    NSRect visualClip = CjguiComposableVisualClipBounds(node);
    if (node.geometry.clipCount == 0) {
        CjguiInternalRendererComposableNode value = node.node;
        visualClip = NSMakeRect((CGFloat)value.clipX, (CGFloat)value.clipY,
                                MAX(0.0, (CGFloat)value.clipWidth), MAX(0.0, (CGFloat)value.clipHeight));
    }
    NSRect visualBody = NSOffsetRect(measuredBounds, (CGFloat)node.geometry.translateX,
                                    (CGFloat)node.geometry.translateY);
    NSRect visible = NSIntersectionRect(visualBody, visualClip);
    if (NSIsEmptyRect(visible)) return NSZeroRect;
    NSRect layoutVisible = NSOffsetRect(visible, -(CGFloat)node.geometry.translateX,
                                       -(CGFloat)node.geometry.translateY);
    return NSIntersectionRect(measuredBounds, NSInsetRect(layoutVisible, -2.0, -2.0));
}

int main(void) {
    @autoreleasepool {
        NSString *body = fixtureBody();

        CJGuiInternalComposableSceneNode *oracle = fixtureNode(body, 700, 480, 0);
        NSRect oraclePartial = CjguiComposableTextTextureRectForNodeWithText(oracle, body);
        if (NSIsEmptyRect(oraclePartial) || oracle.testTextExtentMeasurementCount != 1) {
            fprintf(stderr, "fixture_error partial coverage oracle missing count=%llu rect=%s\n",
                (unsigned long long)oracle.testTextExtentMeasurementCount,
                NSStringFromRect(oraclePartial).UTF8String);
            return 2;
        }

        CJGuiInternalComposableSceneNode *offscreen = fixtureNode(body, 701, 2000, 0);
        NSRect offscreenCoverage = CjguiComposableTextTextureRectForNodeWithText(offscreen, body);
        BOOL offscreenCoverageEmpty = NSIsEmptyRect(offscreenCoverage);
        BOOL offscreenSkippedMeasure = offscreen.testTextExtentMeasurementCount == 0;

        CJGuiInternalComposableSceneNode *translatedOffscreen = fixtureNode(body, 702, 80, 1000);
        NSRect translatedOffscreenCoverage = CjguiComposableTextTextureRectForNodeWithText(
            translatedOffscreen, body);
        BOOL translatedOffscreenEmpty = NSIsEmptyRect(translatedOffscreenCoverage);
        BOOL translatedOffscreenSkippedMeasure = translatedOffscreen.testTextExtentMeasurementCount == 0;

        CJGuiInternalComposableSceneNode *partial = fixtureNode(body, 703, 480, 0);
        NSRect partialCoverage = CjguiComposableTextTextureRectForNodeWithText(partial, body);
        BOOL partialMatchesOracle = sameRect(partialCoverage, oraclePartial);
        BOOL partialMeasured = partial.testTextExtentMeasurementCount == 1;

        CJGuiInternalComposableSceneNode *translatedVisible = fixtureNode(body, 704, 1000, -520);
        NSRect translatedVisibleCoverage = CjguiComposableTextTextureRectForNodeWithText(
            translatedVisible, body);
        NSRect translatedSceneCoverage = NSOffsetRect(translatedVisibleCoverage, 0, -520);
        BOOL translatedVisibleMatchesOracle = sameRect(translatedSceneCoverage, oraclePartial);
        BOOL translatedVisibleMeasured = translatedVisible.testTextExtentMeasurementCount == 1;

        CJGuiInternalComposableSceneNode *moveAfterWarm = fixtureNode(body, 705, 480, 0);
        NSRect beforeMove = CjguiComposableTextTextureRectForNodeWithText(moveAfterWarm, body);
        CjguiInternalRendererComposableGeometry movedGeometry = moveAfterWarm.geometry;
        movedGeometry.translateY = 1000;
        moveAfterWarm.geometry = movedGeometry;
        NSRect afterMoveOffscreen = CjguiComposableTextTextureRectForNodeWithText(moveAfterWarm, body);
        BOOL movedMemoStable = moveAfterWarm.testTextExtentMeasurementCount == 1 &&
            !NSIsEmptyRect(beforeMove) && NSIsEmptyRect(afterMoveOffscreen);

        CJGuiInternalComposableSceneNode *edgeClip = fixtureNode(body, 706, 480, 0);
        (void)CjguiComposableTextTextureRectForNodeWithText(edgeClip, body);
        NSRect measuredBounds = measuredBoundsForNode(edgeClip);
        CjguiInternalRendererComposableNode edgeValue = edgeClip.node;
        // Integer clip coordinates put this one point below the measured
        // coverage edge while still touching the raw node bounds.
        edgeValue.clipY = edgeValue.y;
        edgeValue.clipHeight = 1.0;
        edgeClip.node = edgeValue;
        NSRect strictOldOracle = oldCoverageOracle(edgeClip);
        NSRect edgeCoverage = CjguiComposableTextTextureRectForNodeWithText(edgeClip, body);
        BOOL edgeClipMatchesOldOracle = sameRect(edgeCoverage, strictOldOracle);
        BOOL edgeClipOldOracleEmpty = NSIsEmptyRect(strictOldOracle);
        BOOL edgeClipStillMeasuredOnce = edgeClip.testTextExtentMeasurementCount == 1;

        fprintf(stderr,
            "offscreen_extent_probe body_utf16=%lu partial_oracle=%s oracle_measurements=%llu "
            "fresh_offscreen=%s offscreen_measurements=%llu fresh_translated_offscreen=%s "
            "translated_offscreen_measurements=%llu partial_matches=%s partial_measurements=%llu "
            "translated_visible_matches_scene_oracle=%s translated_visible_measurements=%llu "
            "warm_move_offscreen_zero_coverage=%s warm_measurements=%llu "
            "edge_clip_y=%.2f measured_min_y=%.2f old_oracle=%s edge_coverage=%s "
            "edge_matches_old=%s edge_measurements=%llu result=%s\n",
            (unsigned long)body.length, NSStringFromRect(oraclePartial).UTF8String,
            (unsigned long long)oracle.testTextExtentMeasurementCount,
            offscreenCoverageEmpty ? "zero" : "nonzero",
            (unsigned long long)offscreen.testTextExtentMeasurementCount,
            translatedOffscreenEmpty ? "zero" : "nonzero",
            (unsigned long long)translatedOffscreen.testTextExtentMeasurementCount,
            partialMatchesOracle ? "yes" : "no",
            (unsigned long long)partial.testTextExtentMeasurementCount,
            translatedVisibleMatchesOracle ? "yes" : "no",
            (unsigned long long)translatedVisible.testTextExtentMeasurementCount,
            movedMemoStable ? "yes" : "no",
            (unsigned long long)moveAfterWarm.testTextExtentMeasurementCount,
            (double)edgeValue.clipY,
            NSMinY(measuredBounds), edgeClipOldOracleEmpty ? "zero" : "nonzero",
            NSIsEmptyRect(edgeCoverage) ? "zero" : NSStringFromRect(edgeCoverage).UTF8String,
            edgeClipMatchesOldOracle ? "yes" : "no",
            (unsigned long long)edgeClip.testTextExtentMeasurementCount,
            offscreenSkippedMeasure && translatedOffscreenSkippedMeasure && partialMatchesOracle &&
                partialMeasured && translatedVisibleMatchesOracle && translatedVisibleMeasured && movedMemoStable &&
                edgeClipOldOracleEmpty && edgeClipMatchesOldOracle && edgeClipStillMeasuredOnce
                    ? "PASS" : "RED_SCREENSPACE_EXTENT_MISSED");
        return offscreenCoverageEmpty && offscreenSkippedMeasure && translatedOffscreenEmpty &&
            translatedOffscreenSkippedMeasure && partialMatchesOracle && partialMeasured &&
            translatedVisibleMatchesOracle && translatedVisibleMeasured && movedMemoStable &&
            edgeClipOldOracleEmpty && edgeClipMatchesOldOracle && edgeClipStillMeasuredOnce ? 0 : 1;
    }
}
