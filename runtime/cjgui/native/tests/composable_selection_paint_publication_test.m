// Reuse the real production A-to-B fixture. No testing renderer seam.
#define main LegacySelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        CJGuiInternalSession *ctx = ProductionFixture(device);
        // The input-only legacy fixture did not present complete scenes. Supply
        // the ordinary opaque host required by the real candidate presenter.
        ctx.windowContentHost = ctx.window.contentView;
        ctx.windowOpaqueFallbackView = [[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
        ctx.windowOpaqueFallbackView.wantsLayer = YES;
        [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
        CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx, 0, 3),
            "actual_b_terminal_and_capsule_retirement");
        if (!ctx) return 1;
        uint64_t before = ctx.view.frameIndex;
        CjguiInternalRendererFrameObservation observation = {0};
        CjguiInternalRendererStatus first = cjgui_internal_renderer_present_clear(
            ctx.rendererSessionToken, NULL, &observation);
        CHECK(first == CJGUI_INTERNAL_RENDERER_SCENE_STALE && observation.ticketId == 0 &&
            ctx.view.frameIndex == before, "async_present_before_owner_publication_keeps_coherent_frame");
        CjguiInternalRendererStatus second = cjgui_internal_renderer_present_clear(
            ctx.rendererSessionToken, NULL, &observation);
        CHECK(second == CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.view.frameIndex == before,
            "repeated_present_cannot_bypass_publication");
        CjguiInstalledRangeState *basis = ctx.installedRangeBasis;
        uint64_t transfer = basis.selectionTransferId;
        uint8_t full = 0;
        CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
            transfer + 1, ctx.sessionGeneration, basis.candidate.bindingEpoch,
            basis.proxyGeneration, basis.selectionRevision, basis.candidate.ownerVersion, 42, 0, &full)
            == CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.selectionPaintOwnerRevision == -1,
            "late_receipt_cannot_publish_new_choice");
        CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
            transfer, ctx.sessionGeneration, basis.candidate.bindingEpoch,
            basis.proxyGeneration, basis.selectionRevision, basis.candidate.ownerVersion, 42, 0, &full)
            == CJGUI_INTERNAL_RENDERER_OK && full == 1,
            "actual_receipt_after_callback_retains_full_publication");
        CHECK(cjgui_internal_renderer_present_clear(ctx.rendererSessionToken, NULL, &observation)
            == CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.view.frameIndex == before,
            "after_callback_before_scene_still_keeps_coherent_frame");
        CHECK(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken, 2, 3)
            == CJGUI_INTERNAL_RENDERER_OK, "full_candidate_configured");
        for (uint32_t i = 0; i < 3; i++) {
            CJGuiInternalComposableSceneNode *node = CjguiCloneComposableSceneNode(ctx,
                ctx.composableNodes[i], i, 2);
            ctx.stagedComposableNodes[i] = node;
            NSString *runs = i < 2 ? [NSString stringWithFormat:
                @"0:%u:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1", i == 0 ? 5 : 3] : @"";
            CHECK(cjgui_internal_renderer_set_composable_text_runs(ctx.rendererSessionToken,
                node.node.nodeId, runs.UTF8String) == CJGUI_INTERNAL_RENDERER_OK,
                "owner_selection_run_staged_on_full_candidate");
        }
        CHECK(cjgui_internal_renderer_stage_window_background(ctx.rendererSessionToken, 2, 0, 1)
            == CJGUI_INTERNAL_RENDERER_OK, "full_candidate_background");
        CHECK(cjgui_internal_renderer_present_composable_scene(ctx.rendererSessionToken, &observation)
            == CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.composableSceneVersion == 1,
            "newer_scene_alone_cannot_bypass_receipt_publication");
        CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
            transfer, ctx.sessionGeneration, basis.candidate.bindingEpoch,
            basis.candidate.ownerVersion, 41, 2) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "different_owner_revision_cannot_tag_candidate");
        CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
            transfer, ctx.sessionGeneration, basis.candidate.bindingEpoch,
            basis.candidate.ownerVersion, 42, 2) == CJGUI_INTERNAL_RENDERER_OK,
            "full_candidate_carries_same_receipt_and_owner_revision");
        ctx.view.invalidated = YES;
        fprintf(stderr, "candidate before background=%d bgscene=%llu staged=%llu nodes=%lu view=%p overlay=%p\n",
            ctx.hasStagedWindowBackground, ctx.stagedWindowBackgroundVersion,
            ctx.stagedComposableSceneVersion, ctx.stagedComposableNodes.count, ctx.view, ctx.composableSceneOverlay);
        CjguiInternalRendererStatus rejected = cjgui_internal_renderer_present_composable_scene(
            ctx.rendererSessionToken, &observation);
        fprintf(stderr, "candidate rejected=%u scene=%llu fence=%llu frame=%llu\n", rejected,
            ctx.composableSceneVersion, ctx.selectionPaintTransferId, ctx.view.frameIndex);
        CHECK(rejected == CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED && ctx.composableSceneVersion == 1 &&
            ctx.selectionPaintTransferId == transfer && ctx.view.frameIndex == before,
            "failed_candidate_preserves_fence_and_last_coherent_scene");
        ctx.view.invalidated = NO;
        CjguiInternalRendererStatus accepted = cjgui_internal_renderer_present_composable_scene(
            ctx.rendererSessionToken, &observation);
        fprintf(stderr, "candidate accepted=%u scene=%llu fence=%llu frame=%llu\n", accepted,
            ctx.composableSceneVersion, ctx.selectionPaintTransferId, ctx.view.frameIndex);
        CHECK((accepted == CJGUI_INTERNAL_RENDERER_OK || accepted == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.selectionPaintTransferId == 0 &&
            ctx.view.frameIndex == before + 1 && ctx.composableSceneVersion == 2 &&
            CjguiEffectiveDeclaredSelectionDecorations(ctx, ctx.view.composableNodes[0]).count == 1 &&
            CjguiEffectiveDeclaredSelectionDecorations(ctx, ctx.view.composableNodes[1]).count == 1 &&
            CjguiEffectiveTransferTextSelectionRects(ctx, ctx.view.composableNodes[1]).count == 0 &&
            CjguiEffectiveDeclaredSelectionDecorations(ctx, ctx.view.composableNodes[2]).count == 0,
            "accepted_full_scene_retires_fence_with_all_fragments_and_no_double_proxy");
        CHECK(InstallSelectionOnSameAcceptedScene(ctx, 3, 3), "next_actual_choice_installed");
        basis = ctx.installedRangeBasis;
        CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
            basis.selectionTransferId, ctx.sessionGeneration, basis.candidate.bindingEpoch,
            basis.proxyGeneration, basis.selectionRevision, basis.candidate.ownerVersion, 43, 1, &full)
            == CJGUI_INTERNAL_RENDERER_OK && full == 1 && ctx.selectionPaintTransferId != 0,
            "proxy_intent_cannot_hide_other_fragment_declarations");
        CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
            transfer, ctx.sessionGeneration, basis.candidate.bindingEpoch,
            basis.candidate.ownerVersion, 42, 3) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "superseded_candidate_cannot_release_new_fence");
        CHECK(cjgui_internal_renderer_release_installed_range(ctx.rendererSessionToken,
            basis.candidate.windowInstanceToken, basis.candidate.bindingEpoch) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.selectionPaintTransferId == 0, "true_unbind_retires_paint_obligation");
        CJGuiInternalSession *fast = ProductionFixture(device);
        CHECK(fast && InstallSelectionOnSameAcceptedScene(fast, 0, 2), "same_node_fast_fixture");
        basis = fast.installedRangeBasis;
        CjguiInternalRendererStatus finished = cjgui_internal_renderer_finish_selection_paint_publication(fast.rendererSessionToken,
            basis.selectionTransferId, fast.sessionGeneration, basis.candidate.bindingEpoch,
            basis.proxyGeneration, basis.selectionRevision, basis.candidate.ownerVersion, 1, 1, &full);
        CjguiInternalRendererStatus fastPaint = cjgui_internal_renderer_present_clear(fast.rendererSessionToken, NULL, &observation);
        CHECK(finished == CJGUI_INTERNAL_RENDERER_OK && full == 0 && fast.selectionPaintTransferId == 0 &&
            (fastPaint == CJGUI_INTERNAL_RENDERER_OK || fastPaint == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && fast.composableSceneVersion == 1,
            "same_node_after_callback_paints_without_full_layout");
        (void)cjgui_internal_renderer_destroy(fast.rendererSessionToken);
        fprintf(stderr, "selection_paint_publication failures=%d\n", failures);
        (void)cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
        return failures ? 1 : 0;
    }
}
