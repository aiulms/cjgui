// Real installed range edit -> committed B -> original Undo before common
// completion. Production native code, no TESTING or forged receipts.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static void ActualRangeInstalledBHistoryGapFixture(id<MTLDevice> device,BOOL retireCapsule) {
    BOOL late=YES;uint32_t variant=0;
    fprintf(stderr,"registered_history_variant=%u\n",variant);
    fprintf(stderr,"registered_undo_case=%s\n",late ? "after_pending_B" : "before_B_capture");
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&receipt),
        "prefix_B_source_uses_real_installed_receipt");
    if (!ctx || !ctx.installedRangeBasis.hasReceipt) return;
    uint64_t token=ctx.rendererSessionToken;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    NSString *shortcut=variant==1 ? @"shortcut:shift+command+z" : @"shortcut:command+z";
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,1,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"range-text-undo","Undo","Edit",
            shortcut.UTF8String,0,0,1,0)==0 &&
        CjguiCommitComposableCommandMenuOnMain(token)==0,
        "registered_undo_original_A_declaration_published");
    NSEventModifierFlags flags=NSEventModifierFlagCommand;
    if(variant==1)flags|=NSEventModifierFlagShift;
    if(variant==2)flags|=NSEventModifierFlagControl;
    if(variant==3)flags|=NSEventModifierFlagOption;
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:flags timestamp:1 windowNumber:ctx.window.windowNumber
        context:nil characters:@"z" charactersIgnoringModifiers:@"z" isARepeat:NO keyCode:6];
    uint8_t sourceNeeds=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,
        10,1,1,&sourceNeeds)==0,"prefix_B_original_receipt_published_before_X");
    [ctx.composableSceneOverlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererEvent xEvent={0};CjguiInternalInstalledRangeIntent x={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&xEvent)==0 && xEvent.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,a.candidate.nodeId,a.candidate.resourceId,
            a.candidate.bindingEpoch,ctx.composableSceneVersion,&x)==0,
        "prefix_B_original_X_claimed_once");
    uint64_t handoff=0;
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"prefix-fixture",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,
        a.candidate.ownerVersion,a.candidate.nonce,x.seq,&handoff)==0 &&
        cjgui_internal_renderer_ack_installed_range(token,&x,1,11)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,handoff,11,2,0,0,99)==0,
        "prefix_B_actual_X_ACK_and_immutable_owner_result_sealed");
    CJGuiInternalQueuedInteraction *undo=nil;
    if (!late) {
        CHECK([ctx.composableSceneOverlay performKeyEquivalent:key] && ctx.pendingInteractions.count==1,
            "registered_undo_real_PKEQ_before_B_capture_once");
        undo=ctx.pendingInteractions.firstObject;
        CHECK(undo.ownerHandoff.identity==handoff && undo.inputSequence==1 &&
            undo.inputPreviousSequence==0,"registered_undo_before_B_keeps_same_predecessor");
    }
    PreparePlainCandidate(ctx);
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"range-text-undo","Undo","Edit",
            shortcut.UTF8String,0,0,1,0)==0,
        "registered_undo_candidate_keeps_same_actual_declaration");
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node;raw.nodeId=1013;raw.projectionVersion=2;
    target.node=raw;target.value=[ctx.composableSceneOverlay.inputProxy.string copy];
    ctx.stagedComposableNodes[2]=target;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"prefix_B_actual_candidate_layout_prepared");
    uint64_t transfer=0;CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,
        "prefix_B_actual_transfer_created");
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;
    c.sourceOwnerVersion=11;c.sourceAcceptedVersion=11;c.targetNodeId=1013;c.targetResourceId=1;
    c.targetNodeKind=raw.nodeKind;c.targetSceneVersion=2;c.targetAnchor16=0;c.targetFocus16=0;
    NSData *bytes=[target.value dataUsingEncoding:NSUTF8StringEncoding];
    c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0};
    uint8_t needs=0;
    fprintf(stderr,"prefix_source_after_X paint=%llu paint_owner=%lld receipt=%llu receipt_owner=%lld native_revision=%llu basis_revision=%llu actual_revision=%llu actual_range=%llu:%llu receipt_range=%u:%u\n",
        (unsigned long long)ctx.selectionPaintTransferId,(long long)ctx.selectionPaintOwnerVersion,
        (unsigned long long)ctx.selectionReceiptTransferId,(long long)ctx.selectionReceiptOwnerVersion,
        (unsigned long long)ctx.selectionPaintNativeRevision,(unsigned long long)a.selectionRevision,
        (unsigned long long)ctx.composableSceneOverlay.installedRangeSelectionRevision,
        (unsigned long long)ctx.composableSceneOverlay.inputProxy.selectedRange.location,
        (unsigned long long)NSMaxRange(ctx.composableSceneOverlay.inputProxy.selectedRange),
        receipt.selectionStart16,receipt.selectionEnd16);
    CHECK(ctx.selectionReceiptOwnerVersion==10 && ctx.selectionReceiptOwnerRevision==1,
        "prefix_B_original_receipt_is_never_resigned_after_X");
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,3,0)==CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ctx.selectionTransferCapsule,
        "prefix_B_wrong_choice_revision_cannot_capture_old_receipt");
    c.sourceOwnerVersion=12;
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,2,0)==CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ctx.selectionTransferCapsule,
        "prefix_B_wrong_owner_result_cannot_capture_old_receipt");
    c.sourceOwnerVersion=11;
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,2,0)==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,handoff,transfer+1)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        cjgui_internal_renderer_owner_handoff_bind(token,handoff,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "prefix_B_candidate_binds_only_THIS_sealed_prefix");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==0 && ready,
        "prefix_B_prepare_can_progress_before_Undo");
    if(late && variant>=2) {
        CjguiOwnerSelectionHandoff *h=ctx.ownerSelectionHandoff;
        CjguiSelectionTransferCapsule *pending=ctx.selectionTransferCapsule;
        if(variant==4)h.transferId++;
        if(variant==5) {
            CjguiInternalInstalledRangeCandidate wrong=pending.bInputBasis.candidate;
            wrong.ownerVersion++;pending.bInputBasis.candidate=wrong;
        }
        if(variant==6)pending.ownerSelectionRevision++;
        if(variant==7)h.generation++;
        if(variant==8)ctx.composableCommandMenuItems.firstObject.enabled=NO;
        NSData *before=[ctx.composableSceneOverlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
        (void)[ctx.composableSceneOverlay performKeyEquivalent:key];
        uint32_t state=0;
        BOOL cell=CjguiSelectionTransferCellState(token,transfer,&state,NULL);
        CHECK(!h.valid && cell && state==CJGUI_SELECTION_TRANSFER_ABORTED &&
            ctx.composableSceneVersion==1 && ctx.installedRangeBasis.selectionTransferId!=transfer &&
            ctx.selectionReceiptOwnerVersion==10 &&
            [before isEqualToData:[ctx.composableSceneOverlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding]],
            "registered_history_conflict_cannot_inherit_prefix_or_install_B");
        CjguiReleaseSession(token);return;
    }
    uint64_t originalScene=ctx.composableSceneVersion;
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&frame);
    BOOL installed=(presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==2 && ctx.pendingInteractions.count==0 &&
        ctx.installedRangeBasis.selectionTransferId==transfer;
    fprintf(stderr,"registered_undo_present_status=%u scene=%llu expected_transfer=%llu installed_transfer=%llu original_source_scene=%llu source_scene=%llu\n",
        presented,(unsigned long long)ctx.composableSceneVersion,(unsigned long long)transfer,
        (unsigned long long)ctx.installedRangeBasis.selectionTransferId,(unsigned long long)originalScene,
        (unsigned long long)undo.projectionVersion);
    CHECK(installed,"prefix_B_actual_install_progresses_with_original_Undo_still_held");
    if (!installed) { CjguiReleaseSession(token); return; }
    CjguiOwnerSelectionHandoff *originalRoot=ctx.ownerSelectionHandoff;
    const char *why="none";
    CHECK(originalRoot.installedBCommitted && originalRoot.installedB &&
        CjguiOwnerHandoffProducerPhase(ctx,originalRoot,&why)==CjguiOwnerProducerInstalledOwnB,
        "range_installed_B_has_original_atomic_commit_and_saved_install");
    originalRoot.installedBCommitted=NO;
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,originalRoot,&why)==CjguiOwnerProducerInvalid,
        "range_installed_B_prepared_or_uncommitted_is_not_producer_authority");
    originalRoot.installedBCommitted=YES;
    originalRoot.installedBSourceNonce++;
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,originalRoot,&why)==CjguiOwnerProducerInvalid,
        "range_installed_B_wrong_original_range_ACK_is_not_authority");
    originalRoot.installedBSourceNonce--;
    if(retireCapsule) {
        CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer)==0 &&
            cjgui_internal_renderer_selection_transfer_release(token,transfer)==0 &&
            !ctx.selectionTransferCapsule && !ctx.selectionTransferId,
            "range_installed_B_real_capsule_and_cell_retired_before_common_completion");
        CHECK(CjguiOwnerHandoffProducerPhase(ctx,originalRoot,&why)==CjguiOwnerProducerInstalledOwnB,
            "range_installed_B_same_immutable_commit_survives_capsule_retirement");
    }
    originalScene=ctx.composableSceneVersion;
    CHECK([ctx.composableSceneOverlay performKeyEquivalent:key] && ctx.pendingInteractions.count==1,
        "range_installed_B_actual_Undo_received_in_original_completion_gap");
    undo=ctx.pendingInteractions.firstObject;
    CjguiOwnerSelectionHandoff *live=ctx.ownerSelectionHandoff;
    CHECK(live.valid && undo.ownerHandoff==live && undo.caretInputOrigin.candidate.nonce==transfer &&
        undo.caretInputOrigin.acceptedVersion==11,"range_installed_B_original_Undo_keeps_same_root_and_real_B");
    CjguiInternalRendererEvent held={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&held)==0 && held.kind==0,
        "prefix_B_install_alone_cannot_publish_prefix_completion");
    CHECK(cjgui_internal_renderer_owner_handoff_complete(token,handoff,transfer,11,3,0,0)==33 &&
        cjgui_internal_renderer_owner_handoff_complete(token,handoff,transfer,11,2,0,0)==0,
        "prefix_B_completion_requires_exact_revision_and_real_install");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&held)==0 && held.kind==34 &&
        ctx.pendingInteractions.count==0 && undo.caretInputOriginalSceneVersion==originalScene,
        "prefix_B_original_Undo_resumes_once_after_common_completion");
    CjguiReleaseSession(token);
}

int main(void) { @autoreleasepool { [NSApplication sharedApplication];
    ActualRangeInstalledBHistoryGapFixture(MTLCreateSystemDefaultDevice(),NO);ActualRangeInstalledBHistoryGapFixture(MTLCreateSystemDefaultDevice(),YES);return failures?1:0; } }
