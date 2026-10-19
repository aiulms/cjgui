#define main existingSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main
#import "accepted_paint_manual_display_link.h"

static void DrainMainFor(NSTimeInterval seconds) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while (end.timeIntervalSinceNow > 0)
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:end];
    [CjguiTestLastDisplayLink fire];
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CjguiTestExchangeDisplayClock();
    CJGuiInternalSession *ctx = ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx != nil, "normal_renderer_fixture_has_accepted_scene");
    if (!ctx) return 1;
    DrainMainFor(.03);
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CjguiInternalRendererClearColor clear = { .08, .16, .20, 1.0 };
    uint64_t before = ctx.view.frameIndex;
    [overlay scheduleAcceptedScenePresent];
    CHECK(overlay.acceptedScenePresentScheduled,
        "accepted_paint_has_one_pending_request");
    CjguiInternalRendererStatus submitted = cjgui_internal_renderer_present_clear(
        ctx.rendererSessionToken, &clear, NULL);
    CHECK((submitted == CJGUI_INTERNAL_RENDERER_OK ||
        submitted == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.view.frameIndex == before + 1,
        "normal_present_submits_the_already_requested_accepted_nodes");
    CHECK(!overlay.acceptedScenePresentScheduled,
        "successful_present_consumes_paint_request_encoded_in_that_frame");
    DrainMainFor(.03);
    CHECK(ctx.view.frameIndex == before + 1,
        "consumed_async_request_does_not_acquire_a_second_drawable");

    // A paint invalidation after the successful frame still needs a frame.
    before = ctx.view.frameIndex;
    [overlay scheduleAcceptedScenePresent];
    [overlay scheduleAcceptedScenePresent];
    DrainMainFor(.03);
    CHECK(ctx.view.frameIndex == before + 1 && !overlay.acceptedScenePresentScheduled,
        "newer_paint_still_submits_exactly_one_frame");

    before = ctx.view.frameIndex;
    [overlay scheduleAcceptedScenePresent];
    ctx.view.invalidated = YES;
    CHECK(cjgui_internal_renderer_present_clear(ctx.rendererSessionToken, &clear, NULL) ==
        CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED && overlay.acceptedScenePresentScheduled,
        "failed_present_keeps_pending_paint_obligation");
    ctx.view.invalidated = NO;
    DrainMainFor(.03);
    CHECK(ctx.view.frameIndex == before + 1,
        "pending_paint_submits_after_failed_inline_present");
    uint64_t token = ctx.rendererSessionToken;
    before = ctx.view.frameIndex;
    [overlay scheduleAcceptedScenePresent];
    CjguiReleaseSession(token);
    DrainMainFor(.01);
    CHECK(!CjguiLookupSession(token) && ctx.view.frameIndex == before,
        "queued_paint_respects_normal_session_retirement");
    CjguiTestExchangeDisplayClock();
    return failures ? 1 : 0;
} }
