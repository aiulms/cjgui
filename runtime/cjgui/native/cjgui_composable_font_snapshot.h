#ifndef CJGUI_COMPOSABLE_FONT_SNAPSHOT_H
#define CJGUI_COMPOSABLE_FONT_SNAPSHOT_H

#import <AppKit/AppKit.h>
#include <stdint.h>

// Shared by the accepted scene painter and the private multiline measurement
// worker's main-thread input preparation. The NSFont itself is copied before
// it crosses to the worker; AppKit font selection stays on the owning thread.
static inline NSFontWeight CjguiComposableFontWeightForCode(uint32_t fontWeight) {
    if (fontWeight == 0) return NSFontWeightRegular;
    if (fontWeight < 100) return NSFontWeightBold;
    if (fontWeight < 500) return NSFontWeightRegular;
    if (fontWeight < 600) return NSFontWeightMedium;
    if (fontWeight < 700) return NSFontWeightSemibold;
    return NSFontWeightBold;
}

static inline NSFont *CjguiComposableFontSnapshotForStyle(
    double requested, uint32_t fontWeight, uint32_t fontFamily) {
    CGFloat size = MIN(144.0, MAX(6.0, requested));
    NSFontWeight weight = CjguiComposableFontWeightForCode(fontWeight);
    BOOL italic = fontFamily == 2 || fontFamily == 3;
    NSFont *base = (fontFamily == 1 || fontFamily == 3)
        ? [NSFont monospacedSystemFontOfSize:size weight:weight]
        : [NSFont systemFontOfSize:size weight:weight];
    if (!italic) return base;
    NSFont *slanted = [[NSFontManager sharedFontManager]
        convertFont:base toHaveTrait:NSItalicFontMask];
    return slanted ?: base;
}

#endif
