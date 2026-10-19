#define main ExistingSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

int main(void) { @autoreleasepool {
    NSString *path = NSProcessInfo.processInfo.environment[@"CJGUI_FRAME_CADENCE_TRACE_PATH"];
    CHECK(path.length > 0, "explicit_private_trace_destination");
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx = ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx != nil, "normal_production_renderer_fixture");
    if (!ctx) return 1;
    // Use a real visible Metal layer. An offscreen command-buffer completion
    // cannot prove a drawable was presented on a display.
    NSView *root = [[NSView alloc] initWithFrame:ctx.view.frame];
    ctx.window.contentView = root;
    [root addSubview:ctx.view];
    [root addSubview:ctx.composableSceneOverlay];
    [ctx.window orderFrontRegardless];
    NSDate *visible = [NSDate dateWithTimeIntervalSinceNow:.05];
    while (visible.timeIntervalSinceNow > 0)
        [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:visible];
    CjguiInternalRendererClearColor clear = {.08,.16,.20,1};
    for (NSUInteger i=0; i<3; ++i) {
        CjguiInternalRendererStatus status=cjgui_internal_renderer_present_clear(ctx.rendererSessionToken,&clear,NULL);
        CHECK(status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED,
            "actual_frame_submission");
        NSDate *end = [NSDate dateWithTimeIntervalSinceNow:.08];
        while (end.timeIntervalSinceNow > 0)
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:end];
    }
    CjguiReleaseSession(ctx.rendererSessionToken);
    [ctx.window orderOut:nil];
    NSString *trace = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] ?: @"";
    CHECK([trace containsString:@"stage=commit "], "trace_contains_real_commits");
    CHECK([trace containsString:@"stage=presented "], "trace_contains_actual_drawable_presentation");
    NSUInteger valid=0;
    for (NSString *row in [trace componentsSeparatedByString:@"\n"]) {
        if (![row containsString:@"stage=presented "]) continue;
        unsigned long long when=0,seen=0;
        NSRange r=[row rangeOfString:@"time_ns="];
        if(r.location!=NSNotFound) sscanf([[row substringFromIndex:r.location] UTF8String],
            "time_ns=%llu observed_ns=%llu",&when,&seen);
        CHECK(when==0 ? [row containsString:@"valid=0 "] : [row containsString:@"valid=1 "],
            "presented_zero_is_preserved_as_unknown");
        CHECK(when==0 || (seen>=when && seen-when<1000000000ull),
            "presentation_and_observation_share_host_monotonic_epoch");
        if(when>0) valid++;
    }
    CHECK(valid>=3, "all_three_visible_frames_have_presentation_facts");
    CHECK([trace containsString:@"dropped=0"], "trace_never_hides_overflow");
    return failures ? 1 : 0;
} }
