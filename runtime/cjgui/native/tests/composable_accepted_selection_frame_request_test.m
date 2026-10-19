#define main existingCaretPublicationMain
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
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx, 2, 2),
        "changed_selection_has_real_installed_and_adopted_receipt");
    if (!ctx) return 1;
    // Let genuine installation requests settle before observing this paint.
    // No owner refresh or candidate scene is submitted during the observation.
    DrainMainFor(.03);
    uint64_t key[12] = {0};
    CjguiInstalledRangeState *basis = ctx.installedRangeBasis;
    uint8_t needs = 0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
        basis.selectionTransferId, ctx.sessionGeneration, basis.candidate.bindingEpoch,
        basis.proxyGeneration, basis.selectionRevision, basis.candidate.ownerVersion, 38, 1, &needs) == 0,
        "owner_adopts_actual_selection_before_paint");
    key[0] = basis.candidate.windowInstanceToken; key[1] = basis.candidate.bindingEpoch;
    key[2] = basis.candidate.contextEpoch; key[3] = basis.candidate.mirrorRevision;
    key[4] = basis.candidate.ownerVersion; key[5] = key[4]; key[6] = 38;
    key[7] = 1; key[8] = key[4]; key[9] = 38; key[10] = 2; key[11] = 4;
    key[11] = 2;
    CHECK(cjgui_internal_renderer_stage_accepted_selection_decoration(ctx.rendererSessionToken,
        basis.selectionTransferId, ctx.sessionGeneration, key[1], key[4], key[9], 1,
        ctx.composableSceneVersion, .4, .6, .9, .5, "401:0:0;402:2:2", key) == 0,
        "initial_caret_paint_settles_before_changed_selection");
    DrainMainFor(.03);
    CHECK(InstallSelectionOnSameAcceptedScene(ctx, 2, 4), "next_actual_selection_expands_on_same_layout");
    basis = ctx.installedRangeBasis;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
        basis.selectionTransferId, ctx.sessionGeneration, basis.candidate.bindingEpoch,
        basis.proxyGeneration, basis.selectionRevision, basis.candidate.ownerVersion, 39, 1, &needs) == 0,
        "owner_adopts_expanded_selection");
    key[1] = basis.candidate.bindingEpoch; key[6] = 39; key[9] = 39; key[11] = 4;
    uint64_t before = ctx.view.frameIndex, scene = ctx.composableSceneVersion;
    uint64_t layouts = ctx.composableTextLayoutPreparationCount;
    uint64_t transfer = ctx.installedRangeBasis.selectionTransferId;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_stage_accepted_selection_decoration(
        ctx.rendererSessionToken, transfer, ctx.sessionGeneration, key[1], key[4], key[9],
        1, scene, .4, .6, .9, .5, "401:0:0;402:2:4", key);
    CHECK(status == 0, "accepted_changed_selection_stages_on_current_layout");
    CHECK(ctx.view.frameIndex == before, "accepted_paint_never_presents_inline_inside_commit");
    CHECK(ctx.composableSceneOverlay.acceptedScenePresentScheduled,
        "accepted_changed_selection_requests_existing_async_frame");
    // A second paint in the same main turn coalesces at the existing request.
    CHECK(cjgui_internal_renderer_stage_accepted_selection_decoration(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, key[1], key[4], key[9], 1, scene,
        .4, .6, .9, .5, "401:0:0;402:2:4", key) == 0,
        "same_turn_accepted_paint_can_coalesce_without_new_input");
    DrainMainFor(.03);
    fprintf(stderr, "FRAME_REQUEST_FACT before=%llu after=%llu scene=%llu layouts=%llu\n",
        (unsigned long long)before, (unsigned long long)ctx.view.frameIndex,
        (unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)ctx.composableTextLayoutPreparationCount);
    CHECK(ctx.view.frameIndex == before + 1 && ctx.composableSceneVersion == scene &&
        ctx.composableTextLayoutPreparationCount == layouts &&
        ctx.installedRangeBasis.selectionTransferId == transfer,
        "changed_selection_submits_one_frame_without_owner_refresh_layout_or_install");
    before = ctx.view.frameIndex;
    CHECK(cjgui_internal_renderer_stage_accepted_selection_decoration(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, key[1] + 1, key[4], key[9], 1, scene,
        .4, .6, .9, .5, "401:0:0;402:2:4", key) != 0 &&
        !ctx.composableSceneOverlay.acceptedScenePresentScheduled,
        "rejected_source_does_not_request_a_frame");
    DrainMainFor(.01);
    CHECK(ctx.view.frameIndex == before, "rejected_source_preserves_submitted_frame");
    uint64_t token = ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_stage_accepted_selection_decoration(token,
        transfer, ctx.sessionGeneration, key[1], key[4], key[9], 1, scene,
        .4, .6, .9, .5, "401:0:0;402:2:4", key) == 0,
        "accepted_paint_can_be_queued_before_close");
    CjguiReleaseSession(token);
    DrainMainFor(.01);
    CHECK(!CjguiLookupSession(token) && ctx.view.frameIndex == before,
        "queued_frame_rechecks_exact_session_lifetime_after_close");
    CjguiTestExchangeDisplayClock();
    return failures ? 1 : 0;
} }
