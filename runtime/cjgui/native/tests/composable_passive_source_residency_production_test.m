// Real installed source receipt and normal projection replacement; no testing renderer.
#define main existingSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

static void UnqualifiedSourceRemoval(void) {
    CJGuiInternalSession *ctx = ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx != nil, "passive_resident_real_native_fixture");
    if (!ctx) return;
    uint64_t token = ctx.rendererSessionToken;
    CHECK(InstallSelectionOnSameAcceptedScene(ctx, 2, 2), "passive_resident_actual_selection_install");
    CjguiCaretInputSnapshot *source = CjguiCaptureCaretInputSnapshot(ctx);
    CHECK(source && CjguiFrozenCaretSourceMatchesActual(ctx, source), "passive_resident_original_actual_source");
    if (!source) { CjguiReleaseSession(token); return; }
    NSResponder *responder = ctx.window.firstResponder;
    NSTextView *proxy = ctx.composableSceneOverlay.inputProxy;
    NSString *body = [proxy.string copy];
    uint64_t binding = ctx.ownedTextSessionBindingEpoch;
    // The owner declaration and installed source stay unchanged. The accepted
    // paint projection materializes other fragments, omitting this TEXT only.
    ctx.stagedComposableNodes = [NSMutableArray array];
    for (CJGuiInternalComposableSceneNode *old in ctx.composableNodes) {
        if (old.node.nodeId == 402) continue;
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = old.node; raw.projectionVersion = 2;
        node.node = raw; node.index = (uint32_t)ctx.stagedComposableNodes.count;
        node.value = old.value; node.styleRunsSignature = old.styleRunsSignature;
        [ctx.stagedComposableNodes addObject:node];
    }
    ctx.stagedComposableSceneVersion = 2;
    ctx.stagedComposableDataTransferVersion = 2;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    CHECK(CjguiCommitComposableSceneOnMain(token) == CJGUI_INTERNAL_RENDERER_OK,
          "passive_resident_real_next_paint_scene_commits");
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    BOOL resident = ctx.window.firstResponder == responder &&
        ctx.composableSceneOverlay.inputProxy == proxy && [proxy.string isEqualToString:body] &&
        ctx.ownedTextSessionBindingEpoch == binding && CjguiFrozenCaretSourceMatchesActual(ctx, source);
    CHECK(!resident, "unqualified_missing_paint_does_not_keep_input");
    CHECK(cjgui_internal_renderer_parked_text_input_focus(token,
        source.candidate.windowInstanceToken, source.candidate.contextEpoch,
        source.candidate.nodeId, source.candidate.resourceId, source.nodeKind) != CJGUI_INTERNAL_RENDERER_OK,
        "unqualified_missing_paint_has_no_resident_permission");
    if (resident) {
        [ctx.pendingInteractions removeAllObjects];
        [(CJGuiInternalComposableInputProxy *)proxy insertText:@"中" replacementRange:NSMakeRange(NSNotFound, 0)];
        CjguiInstalledRangeIntentState *intent = nil;
        NSUInteger count = 0;
        for (CJGuiInternalQueuedInteraction *item in ctx.pendingInteractions) {
            if (item.installedRangeIntent) { intent = item.installedRangeIntent; count++; }
        }
        CHECK(count == 1 && intent &&
            intent.value.nonce == source.candidate.nonce &&
            intent.value.proxyGeneration == source.proxyGeneration &&
            [intent.replacement isEqualToData:[@"中" dataUsingEncoding:NSUTF8StringEncoding]],
            "passive_resident_original_callback_one_existing_range_intent");
    }
    // A real other field owns focus now; the original source cannot inherit it.
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:403], "passive_resident_actual_new_field_focus");
    CHECK(cjgui_internal_renderer_parked_text_input_focus(token,
        source.candidate.windowInstanceToken, source.candidate.contextEpoch,
        source.candidate.nodeId, source.candidate.resourceId, source.nodeKind) != CJGUI_INTERNAL_RENDERER_OK,
        "passive_resident_new_focus_refuses_original_source");
    CjguiReleaseSession(token);
}

#include <dlfcn.h>
typedef CjguiInternalRendererStatus (*ResidentStage)(uint64_t,uint64_t,uint64_t,uint64_t,
    uint64_t,uint64_t,uint64_t,uint64_t,int64_t,uint32_t,uint32_t,uint64_t,int64_t,uint32_t);

static void QualifiedSourceResidency(int mode) {
    CJGuiInternalSession *ctx = ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx, 2, 2),
          "qualified_resident_actual_installed_source");
    if (!ctx) return;
    uint64_t token = ctx.rendererSessionToken;
    // Complete the normal native publication phase of the fixture's actual
    // receipt. Version10/revision2 are caller facts of this isolated native
    // fixture; normal Pharos owner proof is checked separately in production.
    uint8_t needsPaint = 0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,
        ctx.installedRangeBasis.selectionTransferId,ctx.sessionGeneration,
        ctx.ownedTextSessionBindingEpoch,ctx.installedRangeProxyGeneration,
        ctx.composableSceneOverlay.installedRangeSelectionRevision,
        ctx.installedRangeBasis.candidate.ownerVersion,2,1,&needsPaint) == 0,
        "qualified_resident_actual_receipt_publication_completed");
    // A real containing scroll record, while the installed input is still on
    // screen. No source/version/selection/receipt flag is manufactured.
    ctx.stagedComposableNodes = [NSMutableArray array];
    for (CJGuiInternalComposableSceneNode *old in ctx.composableNodes) {
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = old.node; raw.projectionVersion = 2;
        if (raw.nodeId == 401) { raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA; raw.effectGroupSubtreeCount = 3; }
        node.node = raw; node.index = old.index; node.value = old.value;
        node.styleRunsSignature = old.styleRunsSignature; [ctx.stagedComposableNodes addObject:node];
    }
    ctx.stagedComposableSceneVersion = 2; ctx.stagedComposableDataTransferVersion = 2;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    CHECK(CjguiCommitComposableSceneOnMain(token) == 0, "qualified_resident_container_scene_real");
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    CjguiCaretInputSnapshot *source = CjguiCaptureCaretInputSnapshot(ctx);
    CHECK(source && CjguiFrozenCaretSourceMatchesActual(ctx, source), "qualified_resident_actual_A_after_paint");
    uint64_t preparation = 867;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, preparation, 2, 3, 2) == 0,
          "qualified_resident_original_preparation");
    ResidentStage stage = (ResidentStage)dlsym(RTLD_DEFAULT,"cjgui_internal_renderer_stage_resident_text_source");
    int status = stage
        ? stage(token, preparation,
            ctx.installedRangeBasis.selectionTransferId, source.proxyGeneration,
            source.candidate.windowInstanceToken, source.candidate.contextEpoch,
            source.candidate.bindingEpoch,source.selectionRevision,source.acceptedVersion,
            (uint32_t)source.selection.location,(uint32_t)NSMaxRange(source.selection),
            401, 1, CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA)
        : CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    CHECK(status == 0, "qualified_resident_common_candidate_offer_supported");
    if (status != 0) { CjguiReleaseSession(token); return; }
    if (mode == 2) {
        CHECK(cjgui_internal_renderer_cancel_composable_preparation(token, preparation) == 0 &&
            !ctx.residentTextSource && CjguiFrozenCaretSourceMatchesActual(ctx, source),
            "qualified_resident_cancel_discards_candidate_keeps_actual_A");
        CjguiReleaseSession(token); return;
    }
    NSResponder *originalResponder = ctx.window.firstResponder;
    NSTextView *originalProxy = ctx.composableSceneOverlay.inputProxy;
    uint32_t index = 0;
    for (CJGuiInternalComposableSceneNode *old in ctx.composableNodes) {
        if (old.node.nodeId == 402) continue;
        CjguiInternalRendererComposableNode raw = old.node; raw.projectionVersion = 3;
        if (raw.nodeId == 401) { raw.effectGroupSubtreeCount = 2; if (mode == 3) raw.resourceId = 2; }
        CjguiInternalRendererComposableGeometry geometry = old.geometry; geometry.nodeId = raw.nodeId;
        CHECK(cjgui_internal_renderer_prepare_composable_node(token, preparation, index++, &raw, &geometry,
            "",old.value.UTF8String,"","","","","","") == 0,
            "qualified_resident_original_candidate_node");
    }
    uint32_t ready = 0;
    uint64_t deadline = cjgui_internal_renderer_owner_clock_ns() + UINT64_C(5000000000);
    while (!ready && cjgui_internal_renderer_owner_clock_ns() < deadline) {
        int advanced = cjgui_internal_renderer_advance_composable_preparation(token,preparation,0,&ready);
        if (advanced != 0) { fprintf(stderr,"resident advance status=%d\n",advanced); break; }
        if (!ready) CFRunLoopRunInMode(kCFRunLoopDefaultMode,.005,true);
    }
    CHECK(ready, "qualified_resident_actual_candidate_ready");
    if (!ready) { CjguiReleaseSession(token); return; }
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,3,2) == 0 &&
        cjgui_internal_renderer_stage_window_background(token,3,0,1) == 0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,preparation) == 0,
        "qualified_resident_original_promote");
    ctx.windowContentHost = ctx.window.contentView;
    ctx.windowOpaqueFallbackView = [[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer = YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CjguiInternalRendererFrameObservation observation = {0};
    CjguiComposablePreparation *sourcePreparation = ctx.stagedNativeTextSourcePreparation;
    fprintf(stderr,"RESIDENT_BEFORE_PRESENT actual=%d viewport=%d native_source=%d staged=%llu accepted=%llu\n",
        CjguiResidentTextSourceMatchesActual(ctx,sourcePreparation.residentTextSource),
        CjguiResidentViewportInNodes(sourcePreparation.residentTextSource,ctx.stagedComposableNodes),
        CjguiPreparationNativeSourceMatches(ctx,ctx.stagedNativeTextSourcePreparation),
        (unsigned long long)ctx.stagedComposableSceneVersion,(unsigned long long)ctx.composableSceneVersion);
    int presented = cjgui_internal_renderer_present_composable_scene(token,&observation);
    fprintf(stderr,"RESIDENT_PRESENT status=%d scene=%llu nodes=%lu overlay=%lu resident=%d parked=%d first=%d source=%d\n",
        presented,(unsigned long long)ctx.composableSceneVersion,(unsigned long)ctx.composableNodes.count,
        (unsigned long)ctx.composableSceneOverlay.nodes.count,ctx.residentTextSource!=nil,
        ctx.composableSceneOverlay.sourceInputParked,CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),
        CjguiFrozenCaretSourceMatchesActual(ctx,source));
    if (mode == 3) {
        CHECK(presented != 0 && ctx.composableSceneVersion == 2 &&
            !ctx.residentTextSource && CjguiFrozenCaretSourceMatchesActual(ctx,source) &&
            ctx.window.firstResponder == originalResponder,
            "qualified_resident_failed_Present_does_not_publish_candidate_or_retire_actual_A");
        CjguiReleaseSession(token); return;
    }
    CHECK((presented == 0 || presented == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion == 3 && ctx.residentTextSource &&
        ctx.composableSceneOverlay.sourceInputParked && ctx.window.firstResponder == originalResponder &&
        ctx.composableSceneOverlay.inputProxy == originalProxy &&
        [originalProxy.string isEqualToString:@"FGHIJ"],
        "qualified_resident_real_Present_keeps_exact_actual_source");
    CHECK([ctx.composableSceneOverlay activeFocusableNode] == nil,
        "qualified_resident_old_paint_not_a_focusable_hit_target");
    if (mode == 4 || mode == 7 || mode == 8) {
        [ctx.pendingInteractions removeAllObjects];
        CHECK([ctx.composableSceneOverlay textView:originalProxy
            doCommandBySelector:(mode == 7 ? @selector(deleteBackward:) :
                mode == 8 ? @selector(deleteForward:) : @selector(moveRightAndModifySelection:))],
            "qualified_resident_original_selector_consumed");
        CHECK(ctx.pendingInteractions.count == 1,
            "qualified_resident_selector_one_existing_FIFO_entry");
        CJGuiInternalQueuedInteraction *navigation=ctx.pendingInteractions.firstObject;
        CHECK(navigation.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            navigation.caretInputBranch.valid &&
            navigation.caretInputBranch.result.candidate.nonce == source.candidate.nonce &&
            navigation.caretInputBranch.result.proxyGeneration == source.proxyGeneration &&
            navigation.inputSequence > 0 &&
            [originalProxy.string isEqualToString:@"FGHIJ"],
            "qualified_resident_selector_actual_source_branch_without_proxy_mutation");
        CjguiInternalRendererEvent event={0};
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event) == 0 &&
            event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            ctx.activeCaretNavigation == navigation && event.nodeId == source.candidate.nodeId &&
            event.projectionVersion == source.candidate.installedSceneVersion,
            "qualified_resident_selector_actual_dequeue_preserves_original_identity");
        int64_t meta[21]={0};uint8_t bytes[128]={0};
        CHECK(cjgui_internal_renderer_resident_caret_source(token,ctx.sessionGeneration,
            navigation.inputSequence,navigation.inputPreviousSequence,meta,bytes,sizeof(bytes)) == 0 &&
            meta[3] == (int64_t)source.candidate.nonce && meta[4] == (int64_t)source.proxyGeneration &&
            meta[17] == (int64_t)source.body.length && !memcmp(bytes,source.body.bytes,source.body.length),
            "qualified_resident_selector_current_head_exports_actual_source_only");
        CHECK(cjgui_internal_renderer_resident_caret_source(token,ctx.sessionGeneration+1,
            navigation.inputSequence,navigation.inputPreviousSequence,meta,bytes,sizeof(bytes)) != 0,
            "qualified_resident_selector_wrong_generation_cannot_claim_head");
        CHECK(cjgui_internal_renderer_resident_caret_source(token,ctx.sessionGeneration,
            navigation.inputSequence+1,navigation.inputPreviousSequence,meta,bytes,sizeof(bytes)) != 0,
            "qualified_resident_selector_old_or_other_sequence_cannot_claim_head");
        CHECK([ctx.composableSceneOverlay focusCommittedNodeId:403],
            "qualified_resident_selector_new_focus_is_real");
        CHECK(cjgui_internal_renderer_resident_caret_source(token,ctx.sessionGeneration,
            navigation.inputSequence,navigation.inputPreviousSequence,meta,bytes,sizeof(bytes)) != 0,
            "qualified_resident_selector_new_focus_invalidates_current_claim");
        CjguiReleaseSession(token); return;
    }
    if (mode == 5) {
        CHECK(cjgui_internal_renderer_set_composable_owned_text_session(token,
            0, -1, 0, ctx.ownedTextSessionBindingEpoch + 1, 0) == 0 && !ctx.residentTextSource,
            "qualified_resident_real_binding_disable_releases_custody");
        CHECK(cjgui_internal_renderer_parked_text_input_focus(token,
            source.candidate.windowInstanceToken,source.candidate.contextEpoch,
            source.candidate.nodeId,source.candidate.resourceId,source.nodeKind) != 0,
            "qualified_resident_disabled_binding_cannot_inherit_source");
        CjguiReleaseSession(token); return;
    }
    if (mode == 0) {
        [ctx.pendingInteractions removeAllObjects];
        [(CJGuiInternalComposableInputProxy *)originalProxy insertText:@"中" replacementRange:NSMakeRange(NSNotFound,0)];
        NSUInteger count = 0; CjguiInstalledRangeIntentState *intent = nil;
        for (CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
            if (q.installedRangeIntent) { count++; intent=q.installedRangeIntent; }
        CHECK(count == 1 && intent && intent.value.nonce == source.candidate.nonce &&
            intent.value.proxyGeneration == source.proxyGeneration &&
            [intent.replacement isEqualToData:[@"中" dataUsingEncoding:NSUTF8StringEncoding]],
            "qualified_resident_first_callback_once_in_existing_range_FIFO");
        CHECK(cjgui_internal_renderer_parked_text_input_focus(token,
            source.candidate.windowInstanceToken,source.candidate.contextEpoch,
            source.candidate.nodeId,source.candidate.resourceId,source.nodeKind) == 0,
            "qualified_resident_real_pending_range_owns_its_changed_proxy");
    } else {
        CHECK([ctx.composableSceneOverlay focusCommittedNodeId:403], "qualified_resident_actual_new_field_focus");
        CHECK(!ctx.residentTextSource && cjgui_internal_renderer_parked_text_input_focus(token,
            source.candidate.windowInstanceToken,source.candidate.contextEpoch,
            source.candidate.nodeId,source.candidate.resourceId,source.nodeKind) != 0,
            "qualified_resident_new_focus_cannot_inherit_original_source");
    }
    CjguiReleaseSession(token);
}

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        UnqualifiedSourceRemoval();
        QualifiedSourceResidency(0);
        QualifiedSourceResidency(1);
        QualifiedSourceResidency(2);
        QualifiedSourceResidency(3);
        QualifiedSourceResidency(4);
        QualifiedSourceResidency(5);
        QualifiedSourceResidency(7);
        QualifiedSourceResidency(8);
    }
    fprintf(stderr, "passive source residency production failures=%d\n", failures);
    return failures ? 1 : 0;
}
