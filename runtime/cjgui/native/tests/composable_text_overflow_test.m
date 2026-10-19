#import "../cjgui_internal_renderer.m"
#include <stdio.h>
static int failures;
#define CHECK(c,n) do { BOOL ok=(c); fprintf(stderr,"text_overflow case=%s result=%s\n",n,ok?"PASS":"FAIL"); if(!ok) failures++; } while(0)
static CjguiPreparedTextNodeLayout *layoutRuns(NSString *value,uint32_t lines,uint32_t overflow,NSData *runs) {
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0}; raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width=154;raw.height=200;raw.fontSize=16;raw.textAlpha=1;raw.textMaxLines=lines;raw.textOverflow=overflow;
    node.node=raw;return CjguiPrepareTextNodeLayout(node,value,1.0,runs,nil);
}
static CjguiPreparedTextNodeLayout *layout(NSString *value,uint32_t lines,uint32_t overflow) { return layoutRuns(value,lines,overflow,nil); }
int main(void) { @autoreleasepool {
    NSString *body=@"中文文件名👩🏽‍💻与家人👨‍👩‍👧‍👦路径/很长的说明文字abcdef0123456789，后续内容不能改写。";
    CjguiPreparedTextNodeLayout *legacy=layout(body,0,0),*one=layout(body,1,1),*two=layout(body,2,1),*clip=layout(body,2,0);
    CHECK([one.storage.string isEqualToString:body] && [two.storage.string isEqualToString:body],"full_utf16_and_business_text_retained");
    CHECK(one.container.maximumNumberOfLines==1 && one.container.lineBreakMode==NSLineBreakByTruncatingTail,"single_line_ellipsis_declaration");
    CHECK(two.container.maximumNumberOfLines==2 && two.container.lineBreakMode==NSLineBreakByTruncatingTail,"last_line_ellipsis_declaration");
    CHECK(clip.container.maximumNumberOfLines==2 && clip.container.lineBreakMode==NSLineBreakByClipping,"line_limit_without_ellipsis");
    [one.layoutManager ensureLayoutForTextContainer:one.container];[two.layoutManager ensureLayoutForTextContainer:two.container];
    __block NSUInteger count=0,truncations=0; __block NSRange truncated=NSMakeRange(NSNotFound,0);
    [two.layoutManager enumerateLineFragmentsForGlyphRange:[two.layoutManager glyphRangeForTextContainer:two.container] usingBlock:^(NSRect rect,NSRect used,NSTextContainer *container,NSRange glyphs,BOOL *stop){count++;NSRange t=[two.layoutManager truncatedGlyphRangeInLineFragmentForGlyphAtIndex:glyphs.location];if(t.location!=NSNotFound){truncations++;truncated=[two.layoutManager characterRangeForGlyphRange:t actualGlyphRange:NULL];}}];
    CHECK(count==2 && truncations==1,"two_lines_only_last_truncated");
    BOOL cluster=truncated.location!=NSNotFound && NSEqualRanges([body rangeOfComposedCharacterSequencesForRange:truncated],truncated);
    CHECK(cluster,"emoji_and_cjk_truncation_at_composed_boundaries");
    CHECK(legacy.container.maximumNumberOfLines==0,"default_layout_unlimited");
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];node.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,.width=154,.height=200,.fontSize=16};
    NSString *keyA=CjguiComposableTextTextureKey(node,1,1,body,NSZeroRect);CjguiInternalRendererComposableNode raw=node.node;raw.textMaxLines=1;raw.textOverflow=1;node.node=raw;
    CHECK(![keyA isEqualToString:CjguiComposableTextTextureKey(node,1,1,body,NSZeroRect)],"overflow_change_invalidates_raster_cache");
    CjguiInternalRendererComposableNode before=node.node,after=before;after.textMaxLines=2;
    CHECK(!CjguiPreparationDeclarationEquals(&before,&after,after.projectionVersion),"line_limit_change_refuses_stale_preparation_reuse");
    after=before;after.textOverflow=0;
    CHECK(!CjguiPreparationDeclarationEquals(&before,&after,after.projectionVersion),"overflow_change_refuses_stale_preparation_reuse");
    CHECK(CjguiPreparationDeclarationEquals(&before,&before,before.projectionVersion),"unchanged_preparation_reuse_preserved");
    CjguiPreparedTextNodeLayout *newline=layout(@"短标题\n第二行还有内容中文👩🏽‍💻",1,1);
    [newline.layoutManager ensureLayoutForTextContainer:newline.container];
    NSRange newlineGlyphs=[newline.layoutManager glyphRangeForTextContainer:newline.container];
    NSRange newlineTruncated=[newline.layoutManager truncatedGlyphRangeInLineFragmentForGlyphAtIndex:newlineGlyphs.location];
    CHECK(newlineTruncated.location!=NSNotFound || newline.terminalEllipsis!=nil,"hard_line_break_tail_is_ellipsized");
    CHECK([newline.storage.string isEqualToString:@"短标题\n第二行还有内容中文👩🏽‍💻"],"hard_break_original_storage_retained");
    NSBitmapImageRep *(^paintAt)(CjguiPreparedTextNodeLayout *,NSPoint) = ^(CjguiPreparedTextNodeLayout *p,NSPoint origin) {
        NSBitmapImageRep *bitmap=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:154 pixelsHigh:200 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:154*4 bitsPerPixel:32];
        memset(bitmap.bitmapData,0,bitmap.bytesPerRow*bitmap.pixelsHigh);
        [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
        CjguiDrawPreparedGlyphs(p,[p.layoutManager glyphRangeForTextContainer:p.container],origin);
        [NSGraphicsContext restoreGraphicsState];return bitmap;
    };
    NSBitmapImageRep *(^paint)(CjguiPreparedTextNodeLayout *) = ^(CjguiPreparedTextNodeLayout *p) { return paintAt(p,NSZeroPoint); };
    CjguiPreparedTextNodeLayout *literal=layout(@"短标题…",1,1);
    NSBitmapImageRep *actual=paint(newline),*oracle=paint(literal);
    fprintf(stderr,"hard_break_fonts cjk=%s break=%s suffix=%s literal_suffix=%s\n",[[newline.storage attribute:NSFontAttributeName atIndex:2 effectiveRange:NULL] fontName].UTF8String,[[newline.storage attribute:NSFontAttributeName atIndex:3 effectiveRange:NULL] fontName].UTF8String,[[newline.terminalEllipsis.storage attribute:NSFontAttributeName atIndex:3 effectiveRange:NULL] fontName].UTF8String,[[literal.storage attribute:NSFontAttributeName atIndex:3 effectiveRange:NULL] fontName].UTF8String);
    NSInteger minX=154,minY=200,maxX=-1,maxY=-1;NSUInteger diffs=0;
    for(NSInteger y=0;y<200;y++)for(NSInteger x=0;x<154;x++)if(memcmp(actual.bitmapData+y*actual.bytesPerRow+x*4,oracle.bitmapData+y*oracle.bytesPerRow+x*4,4)!=0){diffs++;minX=MIN(minX,x);maxX=MAX(maxX,x);minY=MIN(minY,y);maxY=MAX(maxY,y);}
    fprintf(stderr,"hard_break_pixels diff=%lu rect=%ld,%ld:%ld,%ld suffix_origin=%.3f,%.3f source_baseline=%.3f token_baseline=%.3f\n",(unsigned long)diffs,(long)minX,(long)minY,(long)maxX,(long)maxY,newline.terminalEllipsisOrigin.x,newline.terminalEllipsisOrigin.y,[newline.layoutManager locationForGlyphAtIndex:0].y,[newline.terminalEllipsis.layoutManager locationForGlyphAtIndex:0].y);
    CHECK(diffs==0,"hard_break_suffix_pixels_equal_literal_ellipsis");
    CjguiPreparedTextNodeLayout *twoBreaks=layout(@"第一行\n短标题\n第三行保留中文👩🏽‍💻",2,1);
    NSBitmapImageRep *actualTwo=paint(twoBreaks),*oracleTwo=paint(layout(@"第一行\n短标题…",2,1));
    CHECK(memcmp(actualTwo.bitmapData,oracleTwo.bitmapData,actualTwo.bytesPerRow*actualTwo.pixelsHigh)==0,"two_hard_lines_only_terminal_line_ellipsized_pixels");
    CjguiPreparedTextNodeLayout *implicit=layout(body,0,1);
    CHECK(implicit.container.maximumNumberOfLines==1,"ellipsis_without_explicit_limit_means_one_line");
    __block NSUInteger clipLines=0;
    [clip.layoutManager enumerateLineFragmentsForGlyphRange:[clip.layoutManager glyphRangeForTextContainer:clip.container] usingBlock:^(NSRect rect,NSRect used,NSTextContainer *container,NSRange glyphs,BOOL *stop){clipLines++;}];
    CHECK(clipLines==2,"clip_mode_keeps_two_wrapped_lines");
    CjguiInternalTextStyleRun mixedRun={0};mixedRun.start=0;mixedRun.end=9;mixedRun.fontSize=22;
    mixedRun.fontWeight=700;mixedRun.red=0.7;mixedRun.green=0.2;mixedRun.blue=0.1;mixedRun.alpha=1;
    CjguiPreparedTextNodeLayout *mixed=layoutRuns(@"短标题\n下一段中文👩🏽‍💻",1,1,[NSData dataWithBytes:&mixedRun length:sizeof(mixedRun)]);
    mixedRun.end=12;
    CjguiPreparedTextNodeLayout *mixedLiteral=layoutRuns(@"短标题…",1,1,[NSData dataWithBytes:&mixedRun length:sizeof(mixedRun)]);
    mixedRun.end=9;
    CjguiPreparedTextNodeLayout *clipSource=layoutRuns(@"短标题\n下一段中文👩🏽‍💻",1,0,[NSData dataWithBytes:&mixedRun length:sizeof(mixedRun)]);
    [clipSource.layoutManager ensureLayoutForTextContainer:clipSource.container];
    NSRect clipLine=[clipSource.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
    NSRect sourceLine=[mixed.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
    NSRect literalLine=[mixedLiteral.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
    CGFloat clipBaseline=NSMinY(clipLine)+[clipSource.layoutManager locationForGlyphAtIndex:0].y;
    CGFloat sourceBaseline=NSMinY(sourceLine)+[mixed.layoutManager locationForGlyphAtIndex:0].y;
    CGFloat literalBaseline=NSMinY(literalLine)+[mixedLiteral.layoutManager locationForGlyphAtIndex:0].y;
    CHECK(NSEqualRects(clipLine,sourceLine) && clipBaseline==sourceBaseline && [clipSource.storage.string isEqualToString:mixed.storage.string],"mixed_run_source_geometry_matches_independent_clip_layout");
    // Literal punctuation is real content and changes line height. Its glyph
    // oracle uses the independently frozen source baseline; no fitted offset,
    // tolerance, canvas crop or production terminal origin enters the expected.
    NSBitmapImageRep *mixedPaint=paint(mixed),*mixedOracle=paintAt(mixedLiteral,NSMakePoint(0,clipBaseline-literalBaseline));
    NSInteger mixMinX=154,mixMinY=200,mixMaxX=-1,mixMaxY=-1;NSUInteger mixDiffs=0;
    for(NSInteger y=0;y<200;y++)for(NSInteger x=0;x<154;x++)if(memcmp(mixedPaint.bitmapData+y*mixedPaint.bytesPerRow+x*4,mixedOracle.bitmapData+y*mixedOracle.bytesPerRow+x*4,4)!=0){mixDiffs++;mixMinX=MIN(mixMinX,x);mixMaxX=MAX(mixMaxX,x);mixMinY=MIN(mixMinY,y);mixMaxY=MAX(mixMaxY,y);}
    fprintf(stderr,"mixed_run_pixels diff=%lu rect=%ld,%ld:%ld,%ld baseline_source=%.3f baseline_terminal=%.3f baseline_literal=%.3f terminal_origin=%.3f,%.3f source_line=%s terminal_line=%s literal_line=%s terminal_font=%s literal_font=%s\n",(unsigned long)mixDiffs,(long)mixMinX,(long)mixMinY,(long)mixMaxX,(long)mixMaxY,[mixed.layoutManager locationForGlyphAtIndex:0].y,[mixed.terminalEllipsis.layoutManager locationForGlyphAtIndex:0].y,[mixedLiteral.layoutManager locationForGlyphAtIndex:0].y,mixed.terminalEllipsisOrigin.x,mixed.terminalEllipsisOrigin.y,NSStringFromRect([mixed.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL]).UTF8String,NSStringFromRect([mixed.terminalEllipsis.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL]).UTF8String,NSStringFromRect([mixedLiteral.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL]).UTF8String,[[mixed.terminalEllipsis.storage attribute:NSFontAttributeName atIndex:3 effectiveRange:NULL] fontName].UTF8String,[[mixedLiteral.storage attribute:NSFontAttributeName atIndex:3 effectiveRange:NULL] fontName].UTF8String);
    CHECK(mixDiffs==0,"mixed_run_font_weight_color_tail_matches_independent_literal_pixels");
    CHECK([[mixed.storage attribute:CjguiDeclaredPaintFontAttribute atIndex:2 effectiveRange:NULL] isEqual:CjguiComposableFontForStyle(22,700,0)],"run_declared_font_survives_cjk_fallback");
    CHECK([mixed.storage.string isEqualToString:@"短标题\n下一段中文👩🏽‍💻"],"mixed_run_source_remains_complete");
    fprintf(stderr,"text_overflow failures=%d\n",failures);return failures?1:0;
}}
