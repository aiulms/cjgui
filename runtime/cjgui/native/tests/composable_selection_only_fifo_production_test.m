#define main existingSelectionPaintProductionMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx=ProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx!=nil,"selection_only_fifo_real_window"); if(!ctx)return 1;
    CHECK(InstallSelectionOnSameAcceptedScene(ctx,2,4),"selection_only_fifo_real_installed_A");
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    uint64_t session=ctx.rendererSessionToken;
    [o.inputHost selectAll:nil];
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:0.1 windowNumber:ctx.window.windowNumber context:nil
        characters:@"\x7f" charactersIgnoringModifiers:@"\x7f" isARepeat:NO keyCode:51];
    [o.inputHost keyDown:key];
    CHECK(ctx.pendingInteractions.count==2,"selection_only_fifo_original_select_all_and_Delete_received");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(session,0,&event)==0 && event.kind==35,
        "selection_only_fifo_original_select_all_dequeued");
    CJGuiInternalQueuedInteraction *active=ctx.activeCaretNavigation;
    CHECK(active && [active.formText isEqualToString:@"select_all"] && !active.caretEditApplied,
        "selection_only_fifo_predecessor_did_not_write_body");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(session,&transfer)==0,
        "selection_only_fifo_original_B_created");
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;
    c.sourceWindowInstanceToken=ctx.installedRangeBasis.candidate.windowInstanceToken;
    c.sourceOwnerVersion=ctx.installedRangeObservedAckVersion;
    c.sourceContextEpoch=ctx.installedRangeBasis.candidate.contextEpoch;
    c.sourceMirrorRevision=ctx.installedRangeBasis.candidate.mirrorRevision;
    c.targetNodeId=401;c.targetResourceId=1;c.targetNodeKind=3;
    c.targetSceneVersion=ctx.composableSceneVersion;c.targetAnchor16=0;c.targetFocus16=5;
    NSData *body=[ctx.composableNodes[0].value dataUsingEncoding:NSUTF8StringEncoding];
    c.targetBodyUtf8=body.bytes;c.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t actual[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(session,&c,actual,sizeof(actual))==0,
        "selection_only_fifo_actual_A_capture");
    CjguiCaretInputSnapshot *originalAssociation=active.caretInputBranch.result;
    CHECK(cjgui_internal_renderer_bind_caret_projection_transfer(session,transfer,
        active.inputSessionGeneration,active.inputSequence,active.inputPreviousSequence+1)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "projection_carry_shared_bind_wrong_predecessor_refused");
    CHECK(cjgui_internal_renderer_bind_caret_projection_transfer(session,transfer,
        active.inputSessionGeneration+1,active.inputSequence,active.inputPreviousSequence)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "projection_carry_shared_bind_other_generation_refused");
    CHECK(active==ctx.activeCaretNavigation && active.caretInputBranch.result==originalAssociation &&
        active.caretInputBranch.settledSequence==active.inputPreviousSequence,
        "projection_carry_bad_identity_keeps_original_actual_basis_and_unsettled_sequence");
    CHECK(cjgui_internal_renderer_bind_caret_selection_transfer(session,transfer,
        active.inputSessionGeneration,active.inputSequence,active.inputPreviousSequence)==0,
        "selection_only_fifo_B_bound_to_original_predecessor");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(session,transfer)==0,
        "selection_only_fifo_original_B_pending");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_selection_transfer_prepare_b(session,transfer,
        cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&ready)==0 && ready,
        "selection_only_fifo_actual_B_graph_and_geometry_ready");
    CJGuiInternalQueuedInteraction *successor=ctx.pendingInteractions.firstObject;
    CHECK(successor && [successor.formText isEqualToString:@"deleteBackward"] &&
        CjguiQueuedCaretSuccessorOfInflight(ctx,successor),"selection_only_fifo_original_Delete_is_same_prefix_successor");
    CHECK(CjguiQueuedInputWaitsForThisB(ctx,successor,ctx.selectionTransferCapsule),
        "selection_only_fifo_successor_waits_for_original_selection_B");
    NSString *originalIntent=active.formText;
    for(NSString *notSelection in @[@"deleteBackward",@"undo",@"redo"]) {
        active.formText=notSelection;
        CHECK(!CjguiQueuedInputWaitsForThisB(ctx,successor,ctx.selectionTransferCapsule),
            "selection_only_fifo_uncommitted_body_or_history_not_pure_selection");
    }
    active.formText=originalIntent;
    uint64_t originalSequence=successor.inputSequence;
    successor.inputSequence+=1;
    CHECK(!CjguiQueuedInputWaitsForThisB(ctx,successor,ctx.selectionTransferCapsule),
        "selection_only_fifo_missing_sequence_refused");
    successor.inputSequence=originalSequence;
    CjguiInternalInstalledRangeCandidate originalB=ctx.selectionTransferCapsule.bInputBasis.candidate;
    CjguiInternalInstalledRangeCandidate newerB=originalB;newerB.ownerVersion+=1;
    ctx.selectionTransferCapsule.bInputBasis.candidate=newerB;
    CHECK(!CjguiQueuedInputWaitsForThisB(ctx,successor,ctx.selectionTransferCapsule),
        "selection_only_fifo_same_bytes_new_owner_refused");
    ctx.selectionTransferCapsule.bInputBasis.candidate=originalB;
    uint64_t bound=ctx.selectionTransferCapsule.caretInputSequence;
    ctx.selectionTransferCapsule.caretInputSequence+=1;
    CHECK(!CjguiQueuedInputWaitsForThisB(ctx,successor,ctx.selectionTransferCapsule),
        "selection_only_fifo_other_bound_predecessor_refused");
    ctx.selectionTransferCapsule.caretInputSequence=bound;
    CjguiInternalSelectionTransferReceipt receipt={0};
    int status=cjgui_internal_renderer_selection_transfer_install_b(session,transfer,&receipt);
    fprintf(stderr,"SELECTION_ONLY_FIFO_INSTALL status=%d ready=%d predecessor_wrote_body=%d pending=%lu\n",
        status,ready,active.caretEditApplied,(unsigned long)ctx.pendingInteractions.count);
    CHECK(status==0 && receipt.transferId==transfer,"selection_only_fifo_real_B_install_serves_original_Delete");
    if(status==0) {
        CHECK(cjgui_internal_renderer_finish_caret_input(session,active.inputSessionGeneration,
            active.inputSequence,active.inputPreviousSequence,1,transfer,receipt.proxyGeneration,
            receipt.selectionRevision,ctx.installedRangeObservedAckVersion,
            ctx.installedRangeBasis.candidate.contextEpoch,ctx.installedRangeBasis.candidate.windowInstanceToken)==0,
            "selection_only_fifo_existing_non_body_finish_consumes_actual_receipt");
        CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(session,transfer)==0,
            "selection_only_fifo_same_B_capsule_retired");
        CHECK(cjgui_internal_renderer_selection_transfer_release(session,transfer)==0,
            "selection_only_fifo_original_B_reference_released");
        CjguiInternalRendererEvent next={0};
        CHECK(cjgui_internal_renderer_pump_event(session,0,&next)==0 && next.kind==35 &&
            ctx.activeCaretNavigation==successor && successor.inputSequence==2 &&
            successor.inputPreviousSequence==1 && successor.nodeId==401 &&
            successor.caretInputOriginalNodeId==402 &&
            [successor.formText isEqualToString:@"deleteBackward"],
            "selection_only_fifo_original_Delete_dequeues_only_after_B_without_relabeling_capture");
    }
    CjguiReleaseSession(session);return failures?1:0;
} }
