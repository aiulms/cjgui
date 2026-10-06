#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static CJGuiInternalComposableSceneNode *testNode(void) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode value = {0};
    value.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    value.nodeId = 81;
    value.resourceId = 1;
    value.width = 180;
    value.height = 48;
    value.clipWidth = 180;
    value.clipHeight = 48;
    value.fontSize = 18;
    value.textAlpha = 1.0;
    node.node = value;
    node.value = @"     ";
    return node;
}

static NSDictionary *baseAttributes(void) {
    return @{ NSFontAttributeName: [NSFont systemFontOfSize:18],
              NSForegroundColorAttributeName: [NSColor blackColor],
              NSParagraphStyleAttributeName: [NSParagraphStyle defaultParagraphStyle] };
}

static BOOL hasRunDecoration(NSTextStorage *storage, NSUInteger index) {
    return [storage attribute:NSBackgroundColorAttributeName atIndex:index effectiveRange:NULL] != nil ||
           [storage attribute:NSObliquenessAttributeName atIndex:index effectiveRange:NULL] != nil;
}

static void refreshFallback(CJGuiInternalComposableSceneOverlay *overlay) {
    overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    overlay.activeTextBaseFont = [NSFont systemFontOfSize:18];
    overlay.activeTextFallbackNeedsFullRefresh = YES;
    overlay.activeTextFallbackRunsDirty = YES;
    [overlay applySystemFallbackRunsToActiveInput];
}

static NSUInteger paintedPixels(CJGuiInternalComposableSceneOverlay *overlay,
                                CJGuiInternalComposableSceneNode *node) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL pixelsWide:180 pixelsHigh:48
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    NSGraphicsContext *prior = NSGraphicsContext.currentContext;
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    [overlay drawMultilineNode:node active:YES sourceLayout:nil outLayoutMicros:NULL outDrawMicros:NULL
        outSaveMicros:NULL outClipMicros:NULL outRestoreMicros:NULL outGlyphs:NULL];
    [context flushGraphics];
    [NSGraphicsContext setCurrentContext:prior];
    NSUInteger count = 0;
    for (NSInteger y = 0; y < 48; y++) {
        for (NSInteger x = 0; x < 180; x++) {
            NSColor *sample = [[bitmap colorAtX:x y:y] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
            if (sample.alphaComponent > 0.5 && sample.redComponent > 0.7 &&
                sample.greenComponent < 0.3 && sample.blueComponent < 0.3) count++;
        }
    }
    return count;
}

int main(void) {
    @autoreleasepool {
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
        CJGuiInternalComposableSceneOverlay *overlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSMakeRect(0, 0, 180, 48) session:session];
        CJGuiInternalComposableSceneNode *node = testNode();
        overlay.inputProxy.string = node.value;
        NSTextStorage *storage = overlay.inputProxy.textStorage;
        [storage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle)
                        range:NSMakeRange(0, 5)];
        NSColor *platformColor = [NSColor blueColor];
        [storage addAttribute:NSBackgroundColorAttributeName value:platformColor range:NSMakeRange(3, 2)];
        [storage addAttribute:NSObliquenessAttributeName value:@0.08 range:NSMakeRange(3, 1)];

        NSString *rich = @"0:4:18:400:2:0:0:0:1:1:1:0:0:1";
        NSString *ordinary = @"0:4:18:400:0:0:0:0:1";
        session.composableTextStyleRunsRaw[@(81)] = rich;
        [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:baseAttributes()];
        refreshFallback(overlay);
        BOOL richAttributes = hasRunDecoration(storage, 0) &&
            [storage attribute:NSObliquenessAttributeName atIndex:0 effectiveRange:NULL] != nil;
        NSUInteger richPixels = paintedPixels(overlay, node);

        session.composableTextStyleRunsRaw[@(81)] = ordinary;
        [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:baseAttributes()];
        refreshFallback(overlay);
        BOOL ordinaryClean = !hasRunDecoration(storage, 0);
        NSUInteger ordinaryRedPixels = paintedPixels(overlay, node);
        BOOL platformPreserved = [[storage attribute:NSBackgroundColorAttributeName
            atIndex:3 effectiveRange:NULL] isEqual:platformColor] &&
            [[storage attribute:NSObliquenessAttributeName atIndex:3 effectiveRange:NULL] isEqual:@0.08] &&
            [storage attribute:NSUnderlineStyleAttributeName atIndex:0 effectiveRange:NULL] != nil;

        session.composableTextStyleRunsRaw[@(81)] = rich;
        [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:baseAttributes()];
        refreshFallback(overlay);
        session.composableTextStyleRunsRaw[@(81)] = @"";
        [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:baseAttributes()];
        refreshFallback(overlay);
        BOOL emptyClean = !hasRunDecoration(storage, 0);
        NSUInteger emptyRedPixels = paintedPixels(overlay, node);
        BOOL platformStillPreserved = [[storage attribute:NSBackgroundColorAttributeName
            atIndex:3 effectiveRange:NULL] isEqual:platformColor] &&
            [[storage attribute:NSObliquenessAttributeName atIndex:3 effectiveRange:NULL] isEqual:@0.08];
        fprintf(stderr, "rich_attrs=%d red_pixels=%lu/%lu/%lu ordinary_clean=%d empty_clean=%d platform=%d/%d\n",
            richAttributes, (unsigned long)richPixels, (unsigned long)ordinaryRedPixels,
            (unsigned long)emptyRedPixels, ordinaryClean, emptyClean,
            platformPreserved, platformStillPreserved);
        return richAttributes && richPixels > 0 && ordinaryRedPixels == 0 &&
            emptyRedPixels == 0 && ordinaryClean && emptyClean &&
            platformPreserved && platformStillPreserved ? 0 : 1;
    }
}
