#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import "../cjgui_async_multiline_measure.h"
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
static CjguiPreparedTextNodeLayout *typographyLayout(NSString *value, double spacing, double height, NSData *runs) {
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    node.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .width=220,.height=200,.fontSize=16,.fontFamily=1,.textAlpha=1,
        .letterSpacing=spacing,.lineHeightPoints=height};
    CjguiPreparedTextNodeLayout *p=CjguiPrepareTextNodeLayout(node,value,1.0,runs,nil);
    [p.layoutManager ensureLayoutForTextContainer:p.container];
    return p;
}
static void typographyChecks(void) {
    CjguiPreparedTextNodeLayout *plain=typographyLayout(@"AA",0,0,nil);
    CjguiPreparedTextNodeLayout *spaced=typographyLayout(@"AA",4,0,nil);
    CGFloat advance=[spaced.layoutManager locationForGlyphAtIndex:1].x-
        [plain.layoutManager locationForGlyphAtIndex:1].x;
    fprintf(stderr,"typography advance_delta=%.3f\n",advance);
    CHECK(fabs(advance-4.0)<0.05,"letter_spacing_changes_glyph_advance_in_points");
    CjguiPreparedTextNodeLayout *tall=typographyLayout(@"AA\nAA",1.5,32,nil);
    __block NSUInteger lines=0; __block CGFloat first=0, delta=0;
    [tall.layoutManager enumerateLineFragmentsForGlyphRange:[tall.layoutManager glyphRangeForTextContainer:tall.container]
        usingBlock:^(NSRect rect,NSRect used,NSTextContainer *container,NSRange glyphs,BOOL *stop){
            if(lines==0)first=rect.origin.y;else if(lines==1)delta=rect.origin.y-first;lines++;
        }];
    fprintf(stderr,"typography line_delta=%.3f line_count=%lu\n",delta,(unsigned long)lines);
    CHECK(lines==2 && fabs(delta-32.0)<0.05,"absolute_line_height_changes_line_layout");
    CJGuiInternalComposableSceneNode *button=[CJGuiInternalComposableSceneNode new];
    button.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        .width=220,.height=120,.fontSize=16,.fontFamily=1,.textAlpha=1,
        .letterSpacing=4,.lineHeightPoints=32,.textMaxLines=2,.textOverflow=1};
    CjguiPreparedTextNodeLayout *buttonLayout=CjguiPrepareTextNodeLayout(button,@"AA\nAA\nAA",1,nil,nil);
    [buttonLayout.layoutManager ensureLayoutForTextContainer:buttonLayout.container];
    NSParagraphStyle *buttonParagraph=[buttonLayout.storage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
    CHECK(buttonParagraph.minimumLineHeight==32 && buttonLayout.container.maximumNumberOfLines==2 &&
        fabs([buttonLayout.layoutManager locationForGlyphAtIndex:1].x-
            [plain.layoutManager locationForGlyphAtIndex:1].x-4)<0.05 &&
        [buttonLayout.storage.string isEqualToString:@"AA\nAA\nAA"],"button_label_combines_typography_and_overflow");
    CjguiInternalTextStyleRun run={.start=0,.end=2,.fontSize=22,.fontWeight=700,.alpha=1};
    CjguiPreparedTextNodeLayout *mixed=typographyLayout(@"AA\n中文 é 👩🏽‍💻",1.5,32,
        [NSData dataWithBytes:&run length:sizeof(run)]);
    NSParagraphStyle *paragraph=[mixed.storage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
    CHECK(paragraph.minimumLineHeight==32 && paragraph.maximumLineHeight==32,
        "style_runs_preserve_node_absolute_line_height");
    CHECK([mixed.storage.string isEqualToString:@"AA\n中文 é 👩🏽‍💻"],"typography_preserves_unicode_and_newlines");
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    node.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .width=220,.height=200,.fontSize=16,.fontFamily=1};
    NSString *base=CjguiComposableTextTextureKey(node,1,1,@"AA",NSZeroRect);
    CjguiInternalRendererComposableNode raw=node.node;raw.letterSpacing=4;node.node=raw;
    CHECK(![base isEqualToString:CjguiComposableTextTextureKey(node,1,1,@"AA",NSZeroRect)],"spacing_invalidates_texture_key");
    raw.letterSpacing=0;raw.lineHeightPoints=32;node.node=raw;
    CHECK(![base isEqualToString:CjguiComposableTextTextureKey(node,1,1,@"AA",NSZeroRect)],"line_height_invalidates_texture_key");
    raw.lineHeightPoints=0;node.node=raw;
    CHECK([base isEqualToString:CjguiComposableTextTextureKey(node,1,1,@"AA",NSZeroRect)],"default_restores_texture_identity");
    raw.fontSize=16.0001;node.node=raw;
    CHECK(![base isEqualToString:CjguiComposableTextTextureKey(node,1,1,@"AA",NSZeroRect)],"fractional_font_change_invalidates_texture");
    raw.fontSize=16;raw.width=219;node.node=raw;
    CHECK(![base isEqualToString:CjguiComposableTextTextureKey(node,1,1,@"AA",NSZeroRect)],"width_invalidates_texture");

    raw.width=220;raw.x=0;raw.y=0;raw.clipWidth=220;raw.clipHeight=200;raw.letterSpacing=2;
    raw.lineHeightPoints=32;node.node=raw;node.value=@"中文 é 👩🏽‍💻\n末行";
    (void)CjguiComposableTextTextureRectForNodeWithText(node,node.value);
    uint64_t measured=node.testTextExtentMeasurementCount;
    for(int i=0;i<12;i++)(void)CjguiComposableTextTextureRectForNodeWithText(node,node.value);
    CHECK(measured==1 && node.testTextExtentMeasurementCount==measured,"stable_text_reuses_extent_measurement");
    raw.letterSpacing=0;raw.lineHeightPoints=0;node.node=raw;
    (void)CjguiComposableTextTextureRectForNodeWithText(node,node.value);
    CHECK(node.testTextExtentMeasurementCount==measured+1,"default_reset_invalidates_extent_once");

    [NSApplication sharedApplication];
    CJGuiInternalComposableSceneOverlay *overlay=[[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSMakeRect(0,0,220,200)];
    overlay.inputProxy=[[NSTextView alloc] initWithFrame:NSMakeRect(0,0,206,188)];
    overlay.inputProxy.string=node.value;overlay.inputProxy.selectedRange=NSMakeRange(3,2);
    raw.letterSpacing=2;raw.lineHeightPoints=32;node.node=raw;
    NSDictionary *styled=CjguiComposableTypographyAttributesForNode(@{NSFontAttributeName:CjguiComposableFont(node)},node);
    [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:styled];
    CHECK([[overlay.inputProxy.textStorage attribute:NSKernAttributeName atIndex:0 effectiveRange:NULL] doubleValue]==2,
        "active_text_uses_declared_tracking");
    NSString *signature=[overlay activeTextLayoutSignatureForNode:node contentWidth:206];
    raw.letterSpacing=0;raw.lineHeightPoints=0;node.node=raw;
    NSDictionary *natural=CjguiComposableTypographyAttributesForNode(@{NSFontAttributeName:CjguiComposableFont(node)},node);
    [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:natural];
    NSParagraphStyle *restored=[overlay.inputProxy.textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
    CHECK([overlay.inputProxy.textStorage attribute:NSKernAttributeName atIndex:0 effectiveRange:NULL]==nil &&
        restored.minimumLineHeight==0 && restored.maximumLineHeight==0,"active_default_clears_previous_typography");
    CHECK([overlay.inputProxy.string isEqualToString:node.value] && NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(3,2)),
        "style_change_retains_body_and_selection");
    CHECK(![signature isEqualToString:[overlay activeTextLayoutSignatureForNode:node contentWidth:206]],
        "active_layout_signature_tracks_typography");
    for(int i=0;i<3;i++) {
        double spacing[]={1.5,-0.75,0};double heights[]={32,12,0};
        NSString *body=@"中文 é 👩🏽‍💻\n家人👨‍👩‍👧‍👦\n";NSData *bytes=[body dataUsingEncoding:NSUTF8StringEncoding];
        NSFont *font=CjguiComposableFontSnapshotForStyle(16,0,0);
        NSMutableDictionary *attributes=[@{NSFontAttributeName:font} mutableCopy];
        NSMutableParagraphStyle *p=[NSMutableParagraphStyle new];p.lineBreakMode=NSLineBreakByWordWrapping;
        p.lineBreakStrategy=NSLineBreakStrategyPushOut;attributes[NSParagraphStyleAttributeName]=p;
        CjguiApplyComposableTypography(attributes,spacing[i],heights[i]);
        CjguiComposableTextMetrics expected=CjguiMeasureComposableTypography(body,attributes,font,96,heights[i]);
        CjguiAsyncMultilineMeasureHandle handle=0;
        CHECK(CjguiAsyncTextMetricsBeginTypography(bytes.bytes,bytes.length,font,96,spacing[i],heights[i],&handle)==CJGUI_ASYNC_MEASURE_STARTED,
            "styled_async_metrics_admitted");
        CjguiAsyncTextMetrics result={0};CjguiAsyncMultilineMeasureFailure failure=0;
        CjguiAsyncMultilineMeasureStatus status=CJGUI_ASYNC_MEASURE_PENDING;
        double deadline=CFAbsoluteTimeGetCurrent()+5;
        while(status==CJGUI_ASYNC_MEASURE_PENDING && CFAbsoluteTimeGetCurrent()<deadline) {
            status=CjguiAsyncTextMetricsPoll(handle,&result,&failure);
            if(status==CJGUI_ASYNC_MEASURE_PENDING)usleep(1000);
        }
        // Natural defaults retain the previous scalar-measurement contract.
        BOOL equal=i==2 || (result.width==(uint32_t)ceil(expected.width) && result.height==(uint32_t)ceil(expected.height) &&
            result.lineHeight==(uint32_t)ceil(expected.lineHeight) && result.baseline==(uint32_t)ceil(expected.baseline));
        CHECK(status==CJGUI_ASYNC_MEASURE_READY && equal,"styled_async_matches_synchronous_layout");
        CjguiAsyncMultilineMeasureRelease(handle,CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED);
    }
}
int main(int argc,const char **argv) { @autoreleasepool {
    typographyChecks();
    if(argc==2 && strcmp(argv[1],"--typography-only")==0)return failures?1:0;
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
    CJGuiInternalComposableSceneNode *sealedNode=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode sealedRaw={0};sealedRaw.nodeId=99;sealedRaw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    sealedRaw.width=154;sealedRaw.height=200;sealedRaw.fontSize=16;sealedRaw.textAlpha=1;sealedRaw.textMaxLines=1;sealedRaw.textOverflow=1;
    sealedNode.node=sealedRaw;sealedNode.value=newline.storage.string;
    NSArray *sealedTiles=@[[NSValue valueWithRect:NSMakeRect(0,0,154,200)]];
    CjguiTextRasterSourceCredential *sealedCredential=CjguiCreateTextRasterSourceCredential(sealedNode,newline.storage,newline.layoutManager,newline.container,nil,newline.storage.string,1.0,NSMakeRect(0,0,154,200),sealedTiles,NSZeroPoint,0,0,0);
    CjguiPreparedTextNodeLayout *sealed=sealedCredential?CjguiCreateSealedRasterLayout(sealedCredential):nil;
    CHECK(sealedCredential!=nil && sealed!=nil,"production_immutable_credential_seals_readonly_source");
    if(sealed){NSBitmapImageRep *sealedPixels=paint(sealed);CHECK(memcmp(sealedPixels.bitmapData,oracle.bitmapData,sealedPixels.bytesPerRow*sealedPixels.pixelsHigh)==0,"production_sealed_painter_keeps_hard_break_ellipsis_pixels");}
    // Cover the normal cold-label admission, not a preconfigured test-only
    // layout: this path owns the immutable input for >=1024 UTF-16 units.
    NSString *coldBody=[@"短标题\n" stringByAppendingString:[@"中文👩🏽‍💻" stringByPaddingToLength:1600 withString:@"中文👩🏽‍💻" startingAtIndex:0]];
    sealedRaw.clipWidth=154;sealedRaw.clipHeight=200;sealedNode.node=sealedRaw;sealedNode.value=coldBody;
    CJGuiInternalSession *coldContext=[CJGuiInternalSession new];
    CjguiComposablePreparation *coldPreparation=[CjguiComposablePreparation new];coldPreparation.scale=1;
    uint64_t coldReservation=0;
    CjguiTextPreparationWorkerInput *coldInput=CjguiCreateTextPreparationWorkerInput(coldContext,coldPreparation,sealedNode,coldBody,@"",&coldReservation);
    CHECK(coldInput!=nil && coldReservation>0 && [coldInput.body isEqualToString:coldBody],"cold_readonly_admission_retains_complete_business_text");
    CjguiPreparedTextNodeLayout *coldSource=coldInput?CjguiTextPreparationLayoutFromAttributedBody(coldInput,coldInput.sourceAttributedBody):nil;
    CHECK(coldSource.container.maximumNumberOfLines==1 && coldSource.container.lineBreakMode==NSLineBreakByTruncatingTail,"cold_readonly_source_keeps_overflow_declaration");
    CjguiTextRasterSourceCredential *coldCredential=coldSource?CjguiCreateTextRasterSourceCredential(sealedNode,coldSource.storage,coldSource.layoutManager,coldSource.container,nil,coldBody,1,NSMakeRect(0,0,154,200),sealedTiles,NSZeroPoint,0,0,0):nil;
    CjguiPreparedTextNodeLayout *coldPainter=coldCredential?CjguiCreateSealedRasterLayout(coldCredential):nil;
    CHECK(coldPainter!=nil && [coldPainter.storage.string isEqualToString:coldBody],"cold_readonly_painter_keeps_complete_source");
    if(coldPainter){NSBitmapImageRep *coldPixels=paint(coldPainter);CHECK(memcmp(coldPixels.bitmapData,oracle.bitmapData,coldPixels.bytesPerRow*coldPixels.pixelsHigh)==0,"cold_readonly_sealed_pixels_equal_literal_ellipsis");}
    sealedRaw.textMaxLines=2;sealedRaw.textOverflow=0;sealedNode.node=sealedRaw;
    CjguiTextPreparationWorkerInput *coldClip=CjguiCreateTextPreparationWorkerInput(coldContext,coldPreparation,sealedNode,coldBody,@"",&coldReservation);
    CHECK(coldClip.containerMaximumNumberOfLines==2 && coldClip.containerLineBreakMode==NSLineBreakByClipping,"cold_readonly_clip_line_limit");
    sealedRaw.textMaxLines=0;sealedNode.node=sealedRaw;
    CjguiTextPreparationWorkerInput *coldDefault=CjguiCreateTextPreparationWorkerInput(coldContext,coldPreparation,sealedNode,coldBody,@"",&coldReservation);
    CHECK(coldDefault.containerMaximumNumberOfLines==0 && coldDefault.containerLineBreakMode==NSLineBreakByWordWrapping,"cold_readonly_default_remains_unlimited");
    fprintf(stderr,"text_overflow failures=%d\n",failures);return failures?1:0;
}}
