// Actual AppKit/TextKit/Metal A -> B and existing FIFO, no TESTING renderer.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static CjguiInternalRendererStatus BeginSelectionOnly(CJGuiInternalSession *ctx,
    CjguiInstalledRangeState *a,uint64_t *identity) {
#ifdef CJGUI_SELECTION_ONLY_HANDOFF_SUPPORTED
    return cjgui_internal_renderer_owner_handoff_begin_with_purpose(ctx.rendererSessionToken,
        "selection-only-fixture",1,a.candidate.windowInstanceToken,a.candidate.contextEpoch,
        a.candidate.bindingEpoch,10,0,0,CJGUI_OWNER_HANDOFF_SELECTION_ONLY,identity);
#else
    // Executable RED on the unchanged production path, not a missing symbol.
    return cjgui_internal_renderer_owner_handoff_begin(ctx.rendererSessionToken,
        "selection-only-fixture",1,a.candidate.windowInstanceToken,a.candidate.contextEpoch,
        a.candidate.bindingEpoch,10,0,0,identity);
#endif
}

static void SelectionOnlyFixture(id<MTLDevice> device,BOOL cancel,BOOL predecessor) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&receipt),"selection_only_actual_A_installed");
    if(!ctx || !ctx.installedRangeBasis.hasReceipt)return;
    uint64_t token=ctx.rendererSessionToken,identity=0;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,
        10,1,1,&needs)==0,"selection_only_actual_A_published");
    if(predecessor) {
        [ctx.composableSceneOverlay.inputProxy insertText:@"先" replacementRange:NSMakeRange(NSNotFound,0)];
        NSString *body=[ctx.composableSceneOverlay.inputProxy.string copy];
        CHECK(BeginSelectionOnly(ctx,a,&identity)==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING && !identity &&
            !ctx.ownerSelectionHandoff && [body isEqualToString:ctx.composableSceneOverlay.inputProxy.string],
            "selection_only_cannot_overtake_original_A_range_before_ACK");
        CjguiReleaseSession(token);return;
    }
    CHECK(BeginSelectionOnly(ctx,a,&identity)==0 && identity,
        "selection_only_begin_freezes_actual_A_before_choice");
    // Native fixture checks the sealed global choice; the normal 4MiB owner
    // separately proves this byte against its real bounded source mirror.
    CjguiInternalRendererStatus sealed=cjgui_internal_renderer_owner_handoff_seal(token,identity,
        10,2,4194370,4194370,-1);
    CHECK(sealed==0,"selection_only_same_body_version_real_choice_seals");
    if(sealed!=0){CjguiReleaseSession(token);return;}
    CjguiOwnerSelectionHandoff *h=ctx.ownerSelectionHandoff;
    NSString *original=[ctx.composableSceneOverlay.inputProxy.string copy];
    [ctx.composableSceneOverlay.inputProxy insertText:@"尾" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(ctx.pendingInteractions.count==1 &&
        [ctx.pendingInteractions.firstObject.afterCaretTextInput.payload isEqualToString:@"尾"] &&
        ctx.pendingInteractions.firstObject.afterCaretTextInput.ownerHandoff==h &&
        [original isEqualToString:ctx.composableSceneOverlay.inputProxy.string],
        "selection_only_original_text_waits_uninterpreted_in_existing_FIFO");
    if(cancel) {
        CHECK(cjgui_internal_renderer_owner_handoff_abort(token,identity)==0 &&
            ctx.pendingInteractions.count==0 && ctx.rejectedAfterCaretInputs.count==1 &&
            [ctx.rejectedAfterCaretInputs.firstObject.payload isEqualToString:@"尾"] &&
            [original isEqualToString:ctx.composableSceneOverlay.inputProxy.string],
            "selection_only_cancel_preserves_payload_in_existing_recovery_not_A");
        uint64_t metadata[21]={0};uint8_t payload[3]={0},reason[256]={0};
        CHECK(cjgui_internal_renderer_peek_caret_recovery(token,metadata,21)==0 &&
            metadata[12]==3 && metadata[18]>0 && metadata[18]<sizeof(reason) &&
            cjgui_internal_renderer_copy_caret_recovery(token,metadata[1],metadata[0],payload,3,
                reason,(uint32_t)metadata[18])==0 && memcmp(payload,"尾",3)==0,
            "selection_only_cancel_copies_original_payload_and_named_reason");
        CHECK(cjgui_internal_renderer_finish_caret_recovery(token,metadata[1],metadata[0],1)==0 &&
            ctx.rejectedAfterCaretInputs.count==0 && ctx.retainedAfterCaretInputBytes==3 &&
            cjgui_internal_renderer_finish_caret_recovery(token,metadata[1],metadata[0],2)==0 &&
            ctx.retainedAfterCaretInputBytes==0,
            "selection_only_recovery_releases_charge_only_after_copy_confirm");
        CjguiReleaseSession(token);return;
    }
    PreparePlainCandidate(ctx);
    CJGuiInternalComposableSceneNode *departed=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[1],1,2);
    CjguiInternalRendererComposableNode replacement=departed.node;replacement.nodeId=1202;
    departed.node=replacement;ctx.stagedComposableNodes[1]=departed;
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node;raw.nodeId=1013;raw.projectionVersion=2;
    target.node=raw;target.value=@"尾端\n\n";ctx.stagedComposableNodes[2]=target;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"selection_only_B_has_real_prepared_tail_lines");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,"selection_only_B_transfer_created");
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;
    c.sourceOwnerVersion=10;c.sourceAcceptedVersion=10;c.targetNodeId=1013;c.targetResourceId=1;
    c.targetNodeKind=raw.nodeKind;c.targetSceneVersion=2;c.targetAnchor16=3;c.targetFocus16=3;
    NSData *bytes=[target.value dataUsingEncoding:NSUTF8StringEncoding];
    c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,2,0)==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,identity,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "selection_only_B_binds_frozen_A_and_exact_sealed_choice");
    [ctx.composableSceneOverlay.inputProxy insertText:@"中" replacementRange:NSMakeRange(NSNotFound,0)];
    uint32_t pendingState=0;
    CHECK(ctx.pendingInteractions.count==2 &&
        CjguiSelectionTransferCellState(token,transfer,&pendingState,NULL) &&
        pendingState==CJGUI_SELECTION_TRANSFER_PENDING &&
        [original isEqualToString:ctx.composableSceneOverlay.inputProxy.string],
        "selection_only_pending_B_producer_keeps_root_and_original_FIFO");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==0 && ready,
        "selection_only_real_B_prepares_with_original_text_held");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&frame);
    CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==transfer && h.installedBCommitted,
        "selection_only_queued_original_does_not_block_real_B_commit");
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;
    // Candidate Present already publishes the exact accepted selection. The
    // explicit-restore finish-paint entry is not a second candidate callback.
    CHECK(ctx.selectionPaintTransferId==0 && ctx.selectionReceiptOwnerVersion==10 &&
        ctx.selectionReceiptOwnerRevision==2 && ctx.selectionReceiptTransferId==transfer,
        "selection_only_candidate_Present_published_actual_B_receipt");
    CjguiInternalRendererStatus completion=cjgui_internal_renderer_owner_handoff_complete(token,
        identity,transfer,10,2,4194370,4194370);
    CHECK(completion==0,
        "selection_only_actual_B_publication_completes_root_without_body_transaction");
    CjguiInternalRendererEvent event={0};CjguiInternalInstalledRangeIntent intent={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
            b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 &&
        intent.rangeStart16==3 && intent.rangeLength16==0 && intent.replacementUtf8Length==3 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"尾端\n尾\n"],
        "selection_only_original_text_materializes_once_at_real_B_tail_newline");
    CjguiInternalRendererEvent waiting={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&waiting)==0 && waiting.kind==0 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"尾端\n尾\n"],
        "selection_only_second_text_waits_first_real_range_ACK");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0,
        "selection_only_original_text_retains_real_range_ACK");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
            b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 &&
        intent.rangeStart16==4 && intent.rangeLength16==0 && intent.replacementUtf8Length==3 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"尾端\n尾中\n"] &&
        cjgui_internal_renderer_ack_installed_range(token,&intent,1,12)==0,
        "selection_only_second_text_follows_first_ACK_once_at_B");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0,
        "selection_only_original_text_has_no_duplicate_range");
    CjguiReleaseSession(token);
}

int main(void) { @autoreleasepool {
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 77;
    SelectionOnlyFixture(device,NO,NO);SelectionOnlyFixture(device,YES,NO);
    SelectionOnlyFixture(device,NO,YES);
    fprintf(stderr,"selection_only_summary failures=%d\n",failures);
    return failures?1:0;
} }
