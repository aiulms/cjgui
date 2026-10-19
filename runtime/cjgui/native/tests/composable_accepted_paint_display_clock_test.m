// Candidate receipt/input publication precedes display-paced derived paint.
#define CJGUI_CARET_PUBLICATION_FIXTURE_ONLY 1
#import "composable_caret_publication_production_test.m"
#import "accepted_paint_manual_display_link.h"

static void DrainDispatchOnly(void) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:.015];
    while (end.timeIntervalSinceNow > 0)
        [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:end];
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication]; CjguiTestExchangeDisplayClock();
    CJGuiInternalSession *ctx = ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx, 2, 2) && AdoptActualReceipt(ctx),
        "display_clock_starts_with_real_installed_A_and_owner_adoption");
    if (!ctx) return 1;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    [overlay stopCaretBlink];
    CjguiInternalRendererClearColor clear = { .08, .16, .20, 1 };
    uint64_t initialFrame = ctx.view.frameIndex;
    CjguiInternalRendererStatus initialStatus = cjgui_internal_renderer_present_clear(
        ctx.rendererSessionToken, &clear, NULL);
    CHECK((initialStatus == 0 || initialStatus == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.view.frameIndex == initialFrame + 1,
        "initial_accepted_paint_is_actually_submitted");
    DrainDispatchOnly();

    uint64_t key[12] = {0}; int64_t origin[16] = {0};
    ActualReceiptIdentity(ctx, key, origin); ConfigureActualBackground(ctx, 2);
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(ctx.rendererSessionToken,
        0, 2, 1, 402, 2, 2, key, origin) == 0,
        "candidate_freezes_actual_caret_origin");
    CjguiInternalRendererFrameObservation observation = {0};
    CHECK(cjgui_internal_renderer_present_composable_scene(ctx.rendererSessionToken,
        &observation) == 0 && ctx.composableSceneVersion == 2 && observation.frameIndex,
        "candidate_submits_and_publishes_before_next_display_tick");
    uint64_t meta[16] = {0}; double rect[8] = {0};
    CHECK(cjgui_internal_renderer_accepted_caret_value(ctx.rendererSessionToken,
        ctx.sessionGeneration, 2, 402, 2, 2, key, meta, rect) == 0,
        "accepted_B_caret_receipt_is_available_before_derived_paint");
    // This is the real post-publication paint seam, not a second candidate.
    [overlay resetCaretBlink]; [overlay scheduleAcceptedScenePresent];
    uint64_t submitted = ctx.view.frameIndex;
    DrainDispatchOnly();
    CHECK(ctx.view.frameIndex == submitted && overlay.acceptedScenePresentScheduled,
        "post_publication_paint_does_not_take_drawable_in_main_dispatch_burst");
    CjguiTestManualDisplayLink *clock = CjguiTestLastDisplayLink;
    CHECK(clock.registered && !clock.paused && !clock.invalidated,
        "pending_paint_uses_window_display_clock_in_common_modes");
    [clock fire];
    CHECK(ctx.view.frameIndex == submitted + 1 && !overlay.acceptedScenePresentScheduled &&
        ctx.composableSceneVersion == 2 && ctx.acceptedCaretProjection.nodeId == 402,
        "one_display_tick_submits_latest_accepted_paint_and_keeps_B_receipt");
    [clock fire];
    CHECK(ctx.view.frameIndex == submitted + 1 && clock.paused,
        "clean_display_clock_is_paused_without_extra_drawable");

    [overlay scheduleAcceptedScenePresent]; ctx.view.invalidated = YES;
    [clock fire]; DrainDispatchOnly();
    CHECK(overlay.acceptedScenePresentScheduled && ctx.view.frameIndex == submitted + 1,
        "failed_display_submission_keeps_dirty_without_faking_a_frame");
    ctx.view.invalidated = NO; [clock fire];
    CHECK(!overlay.acceptedScenePresentScheduled && ctx.view.frameIndex == submitted + 2,
        "next_display_tick_completes_previously_failed_paint");

    CjguiCandidateCaretProjection *acceptedCaret = ctx.acceptedCaretProjection;
    ConfigureActualBackground(ctx, 3); ctx.view.invalidated = YES;
    CHECK(cjgui_internal_renderer_present_composable_scene(ctx.rendererSessionToken,
        &observation) == CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED &&
        ctx.composableSceneVersion == 2 && ctx.acceptedCaretProjection == acceptedCaret &&
        ctx.view.frameIndex == submitted + 2 && !overlay.acceptedScenePresentScheduled,
        "rejected_next_candidate_keeps_accepted_B_without_candidate_paint");
    ctx.view.invalidated = NO;
    [clock fire];
    CHECK(ctx.view.frameIndex == submitted + 2,
        "display_tick_cannot_publish_rejected_candidate");

    [overlay scheduleAcceptedScenePresent];
    ctx.window.contentView = [[NSView alloc] initWithFrame:overlay.frame];
    CHECK(clock.invalidated && overlay.acceptedScenePresentScheduled,
        "detaching_view_retires_clock_but_keeps_unsubmitted_dirty");
    ctx.window.contentView = overlay;
    CjguiTestManualDisplayLink *reattached = CjguiTestLastDisplayLink;
    CHECK(reattached != clock && reattached.registered && !reattached.paused,
        "reattaching_pending_view_arms_new_display_source");
    [reattached fire]; clock = reattached;
    CHECK(ctx.view.frameIndex == submitted + 3 && ctx.composableSceneVersion == 2,
        "reattached_tick_draws_accepted_scene_only");
    [overlay scheduleAcceptedScenePresent];
    uint64_t token = ctx.rendererSessionToken; CjguiReleaseSession(token);
    [clock fire]; DrainDispatchOnly();
    CHECK(clock.invalidated && !CjguiLookupSession(token) && ctx.view.frameIndex == submitted + 3,
        "normal_session_retirement_cancels_pending_display_source");
    CjguiTestExchangeDisplayClock(); return failures ? 1 : 0;
} }
