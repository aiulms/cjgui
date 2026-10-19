// Actual producer/FIFO/Present seam. No TESTING renderer or forged receipt.
#define CJGUI_CANDIDATE_NO_MAIN 1
#import "composable_candidate_selection_projection_test.m"

static void *RequestWaitingPump(void *opaque) {
    @autoreleasepool {
        uint64_t token=*(uint64_t *)opaque;
        CjguiInternalRendererEvent event={0};
        // A bounded waiting request survives the owner's deadline even when
        // main has not acquired an event. Zero can expire before allocation.
        CjguiInternalRendererStatus status=cjgui_internal_renderer_pump_event(token,10,&event);
        fprintf(stderr,"prefix_pending_worker status=%u generation=%llu event=%u\n",status,
            (unsigned long long)CjguiOwnerPumpLiveSessionGeneration(token),event.kind);
    }
    return NULL;
}

static void PreparePlainCandidate(CJGuiInternalSession *ctx) {
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,3)==0 &&
        cjgui_internal_renderer_stage_window_background(token,2,0,1)==0,
        "prefix_present_plain_candidate_prepared");
    ctx.stagedComposableDataTransferVersion=2;
}

static void WaitingRequestFixture(id<MTLDevice> device) {
    cjgui_internal_renderer_enable_main_thread_dispatch();
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"prefix_present_waiting_owned_fixture");
    if (!ctx) return;
    uint64_t token=ctx.rendererSessionToken;
    PreparePlainCandidate(ctx);
    pthread_t worker;
    CHECK(pthread_create(&worker,NULL,RequestWaitingPump,&token)==0,
        "prefix_present_actual_off_main_pump_request");
    pthread_join(worker,NULL);
    NSUInteger index=CjguiOwnerPumpTicketIndex(token);
    pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
    BOOL waiting=gCjguiOwnerPumpTickets[index].state==CjguiOwnerPumpTicketPending &&
        gCjguiOwnerPumpTickets[index].wantsEvent;
    fprintf(stderr,"prefix_pending_ticket state=%u wants=%u session=%llu generation=%llu\n",
        gCjguiOwnerPumpTickets[index].state,gCjguiOwnerPumpTickets[index].wantsEvent,
        (unsigned long long)gCjguiOwnerPumpTickets[index].session,
        (unsigned long long)gCjguiOwnerPumpTickets[index].sessionGeneration);
    pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    CHECK(waiting && ctx.pendingInteractions.count==0,
        "prefix_present_real_Pending_request_has_no_event");
    CHECK(cjgui_internal_renderer_owner_pump_has_unconsumed_input(token)==0,
        "prefix_present_Pending_request_is_not_unconsumed_input");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(token,&frame);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==2,
        "prefix_present_Pending_without_event_allows_publish");
    CjguiReleaseSession(token);
}

static void ActualCommandFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"prefix_present_actual_command_owned_fixture");
    if (!ctx) return;
    uint64_t token=ctx.rendererSessionToken;
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,1,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"shift-source","Move source","Edit",
            "shortcut:shift+command+n",0,0,1,0)==0 &&
        CjguiCommitComposableCommandMenuOnMain(token)==0,
        "prefix_present_original_A_command_published");
    PreparePlainCandidate(ctx);
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"shift-source","Move source","Edit",
            "shortcut:shift+command+n",0,0,1,0)==0,
        "prefix_present_candidate_command_complete");
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand|NSEventModifierFlagShift timestamp:1
        windowNumber:ctx.window.windowNumber context:nil characters:@"N"
        charactersIgnoringModifiers:@"n" isARepeat:NO keyCode:45];
    CHECK([ctx.composableSceneOverlay handleWindowCommandKeyDown:key] &&
        ctx.pendingInteractions.count==1,"prefix_present_real_keyboard_producer_once");
    CJGuiInternalQueuedInteraction *original=ctx.pendingInteractions.firstObject;
    uint64_t beforeFrame=ctx.view.frameIndex;
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(token,&frame);
    // 39 is the new private no-submission disposition, distinct from a GPU
    // Present ticket. Keeping the constant local lets this production RED
    // run before the disposition is implemented.
    CHECK(status==39,"prefix_present_A_command_preempts_before_publish");
    CHECK(ctx.composableSceneVersion==1 && ctx.view.frameIndex==beforeFrame &&
        ctx.pendingInteractions.firstObject==original && original.projectionVersion==1,
        "prefix_present_A_and_immutable_original_FIFO_preserved");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34 &&
        event.projectionVersion==1 && ctx.pendingInteractions.count==0,
        "prefix_present_original_command_consumed_once");
    status=CjguiPresentComposableSceneOnMain(token,&frame);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==2,"prefix_present_drained_A_command_allows_B");
    CjguiReleaseSession(token);
}

static BOOL InstallPrefixSelectionA(CJGuiInternalSession *ctx,CjguiInternalSelectionTransferReceipt *receipt) {
    uint64_t transfer=0,token=ctx.rendererSessionToken;
    if (cjgui_internal_renderer_selection_transfer_create(token,&transfer)!=0) return NO;
    NSData *body=[ctx.composableSceneOverlay.nodes[1].value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c=CaptureCandidateForTarget(ctx,transfer,1,0,body);
    c.targetAnchor16=1;c.targetFocus16=4;uint8_t actual[65536]={0};
    CjguiInternalRendererStatus status=cjgui_internal_renderer_selection_transfer_capture_current(token,&c,actual,sizeof(actual));
    if (status==0) status=cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer);
    if (status==0) status=cjgui_internal_renderer_selection_transfer_install_b(token,transfer,receipt);
    (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token,transfer);
    return status==0;
}

static void ActualOwnerPrefixCandidateFixture(id<MTLDevice> device, BOOL late, uint32_t variant) {
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
    if (late) {
        CHECK([ctx.composableSceneOverlay performKeyEquivalent:key] && ctx.pendingInteractions.count==1,
            "registered_undo_real_PKEQ_after_pending_B_once");
        undo=ctx.pendingInteractions.firstObject;
        CjguiOwnerSelectionHandoff *h=ctx.ownerSelectionHandoff;
        uint32_t state=0;
        BOOL cell=CjguiSelectionTransferCellState(token,transfer,&state,NULL);
        fprintf(stderr,"registered_undo_late_state handoff_id=%llu valid=%d completed=%d transfer=%llu cell=%d state=%u queued_kind=%u source_scene=%llu seq=%llu prev=%llu queued_handoff=%llu branch_valid=%d\n",
            (unsigned long long)h.identity,h.valid,h.completed,(unsigned long long)transfer,cell,state,
            undo.kind,(unsigned long long)undo.projectionVersion,(unsigned long long)undo.inputSequence,
            (unsigned long long)undo.inputPreviousSequence,(unsigned long long)undo.ownerHandoff.identity,
            undo.caretInputBranch.valid);
        BOOL preserved=h.valid && !h.completed && undo.ownerHandoff.identity==handoff &&
            undo.inputSequence==1 && undo.inputPreviousSequence==0 && cell &&
            state==CJGUI_SELECTION_TRANSFER_PENDING;
        CHECK(preserved,"registered_undo_after_pending_B_preserves_same_prefix_and_original_FIFO");
        if (!preserved) { CjguiReleaseSession(token); return; }
    }
    uint64_t originalScene=undo.projectionVersion;
    CjguiInternalRendererFrameObservation frame={0};
    uint64_t originalPrevious=undo.inputPreviousSequence;
    undo.inputPreviousSequence=undo.inputSequence;
    CHECK(CjguiPresentComposableSceneOnMain(token,&frame)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.composableSceneVersion==1 && ctx.pendingInteractions.firstObject==undo,
        "prefix_B_wrong_successor_predecessor_cannot_publish");
    undo.inputPreviousSequence=originalPrevious;
    CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&frame);
    BOOL installed=(presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==2 && ctx.pendingInteractions.firstObject==undo &&
        undo.projectionVersion==originalScene && ctx.installedRangeBasis.selectionTransferId==transfer;
    fprintf(stderr,"registered_undo_present_status=%u scene=%llu expected_transfer=%llu installed_transfer=%llu original_source_scene=%llu source_scene=%llu\n",
        presented,(unsigned long long)ctx.composableSceneVersion,(unsigned long long)transfer,
        (unsigned long long)ctx.installedRangeBasis.selectionTransferId,(unsigned long long)originalScene,
        (unsigned long long)undo.projectionVersion);
    CHECK(installed,"prefix_B_actual_install_progresses_with_original_Undo_still_held");
    if (!installed) { CjguiReleaseSession(token); return; }
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

static void ActualCaretMutationHandoffFixture(id<MTLDevice> device,BOOL history) {
    fprintf(stderr,"ORIGINAL_CARET_OWNER_COMMAND kind=%u\n",history ? 34u : 35u);
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&receipt),"caret_owner_handoff_actual_A_installed");
    if(!ctx || !ctx.installedRangeBasis.hasReceipt)return;
    uint64_t token=ctx.rendererSessionToken;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,
        10,1,1,&needs)==0,"caret_owner_handoff_actual_A_published");
    CHECK([ctx.composableSceneOverlay textView:ctx.composableSceneOverlay.inputProxy
        doCommandBySelector:history ? @selector(undo:) : @selector(deleteBackward:)],
        "caret_owner_handoff_real_owner_command_received");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==(history ? 34u : 35u),
        "caret_owner_handoff_original_owner_command_dequeued");
    CJGuiInternalQueuedInteraction *active=ctx.activeCaretNavigation;
    CjguiCaretInputBranch *branch=active.caretInputBranch;
    uint64_t sequence=active.inputSequence,previous=active.inputPreviousSequence,handoff=0;
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"prefix-fixture",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,
        10,0,sequence+1,&handoff)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.activeCaretNavigation==active && branch.valid && !handoff,
        "caret_owner_handoff_wrong_original_sequence_zero_mutation");
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"prefix-fixture",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,
        10,0,sequence,&handoff)==0 && handoff && ctx.activeCaretNavigation==active &&
        ctx.caretInputBranch==branch && branch.valid && branch.settledSequence==previous,
        "caret_owner_handoff_begin_preserves_original_owner_command_prefix");
    if(!handoff || !active || ctx.activeCaretNavigation!=active || !branch.valid) {
        CjguiReleaseSession(token);return;
    }
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,sequence,previous,
        10,11,a.candidate.contextEpoch,a.candidate.windowInstanceToken)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,handoff,11,2,1,1,99)==0,
        "caret_owner_handoff_actual_owner_result_seals_same_original_input");
    CHECK([ctx.composableSceneOverlay textView:ctx.composableSceneOverlay.inputProxy
        doCommandBySelector:@selector(undo:)],"caret_owner_handoff_original_Undo_received");
    CJGuiInternalQueuedInteraction *undo=ctx.pendingInteractions.firstObject;
    CHECK(undo.inputPreviousSequence==sequence && undo.caretInputBranch==branch,
        "caret_owner_handoff_Undo_keeps_original_FIFO");
    PreparePlainCandidate(ctx);
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node;raw.nodeId=1013;raw.projectionVersion=2;
    target.node=raw;
    NSMutableString *after=[ctx.composableSceneOverlay.inputProxy.string mutableCopy];
    [after deleteCharactersInRange:NSMakeRange(1,3)];target.value=after;
    ctx.stagedComposableNodes[2]=target;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"caret_owner_handoff_actual_B_layout_prepared");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,
        "caret_owner_handoff_B_transfer_created");
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;
    c.sourceOwnerVersion=11;c.sourceAcceptedVersion=11;c.targetNodeId=1013;c.targetResourceId=1;
    c.targetNodeKind=raw.nodeKind;c.targetSceneVersion=2;c.targetAnchor16=1;c.targetFocus16=1;
    NSData *bytes=[after dataUsingEncoding:NSUTF8StringEncoding];
    c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,2,0)==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,handoff,transfer)==0 &&
        cjgui_internal_renderer_bind_caret_selection_transfer(token,transfer,ctx.sessionGeneration,
            sequence,previous)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "caret_owner_handoff_B_binds_H_and_same_original_Delete");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==0 && ready,
        "caret_owner_handoff_B_preparation_progresses_with_Undo_held");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&frame);
    BOOL installed=(presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==transfer && active.caretInstalledResult;
    fprintf(stderr,"caret_owner_actual_B present=%u expected=%llu installed=%llu active=%d edit=%d before=%lld after=%lld branch_owner=%lld retained_B=%d capsule_caret=%llu\n",
        presented,(unsigned long long)transfer,(unsigned long long)ctx.installedRangeBasis.selectionTransferId,
        ctx.activeCaretNavigation==active,active.caretEditApplied,(long long)active.caretEditBeforeVersion,
        (long long)active.caretEditAfterVersion,(long long)branch.result.acceptedVersion,
        active.caretInstalledResult!=nil,(unsigned long long)ctx.selectionTransferCapsule.caretInputSequence);
    CHECK(installed,"caret_owner_handoff_retains_real_B_for_original_Delete_ACK");
    if(!installed){CjguiReleaseSession(token);return;}
    CHECK(cjgui_internal_renderer_owner_handoff_complete(token,handoff,transfer,11,2,1,1)==0 &&
        ctx.activeCaretNavigation==active && branch.settledSequence==previous,
        "caret_owner_handoff_common_completion_does_not_invent_original_ACK");
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;
    CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,sequence,previous,1,
        b.candidate.nonce,b.proxyGeneration,b.selectionRevision,11,b.candidate.contextEpoch,
        b.candidate.windowInstanceToken)==0 && branch.settledSequence==sequence && !ctx.activeCaretNavigation,
        "caret_owner_handoff_original_Delete_ACK_after_common_B_once");
    CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,sequence,previous,1,
        b.candidate.nonce,b.proxyGeneration,b.selectionRevision,11,b.candidate.contextEpoch,
        b.candidate.windowInstanceToken)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "caret_owner_handoff_duplicate_ACK_cannot_resettle");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34 &&
        ctx.activeCaretNavigation==undo && ctx.pendingInteractions.count==0,
        "caret_owner_handoff_original_Undo_resumes_without_relabel_or_replay");
    CjguiReleaseSession(token);
}

static void ActualHistoryNoChangeKeepsOriginalSuccessor(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&receipt),"history_no_change_real_A_installed");
    if(!ctx || !ctx.installedRangeBasis.hasReceipt)return;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    uint8_t needs=0;uint64_t token=ctx.rendererSessionToken,handoff=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,
        10,1,1,&needs)==0,"history_no_change_real_A_published");
    CHECK([ctx.composableSceneOverlay textView:ctx.composableSceneOverlay.inputProxy
        doCommandBySelector:@selector(undo:)],"history_no_change_original_command_received");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34,
        "history_no_change_original_command_dequeued");
    CJGuiInternalQueuedInteraction *active=ctx.activeCaretNavigation;
    CjguiCaretInputBranch *branch=active.caretInputBranch;
    uint64_t sequence=active.inputSequence,previous=active.inputPreviousSequence;
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"prefix-fixture",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,
        10,0,sequence,&handoff)==0,"history_no_change_actual_A_held_before_owner");
    CHECK([ctx.composableSceneOverlay textView:ctx.composableSceneOverlay.inputProxy
        doCommandBySelector:@selector(undo:)],"history_no_change_successor_received_once");
    CJGuiInternalQueuedInteraction *successor=ctx.pendingInteractions.firstObject;
    uint64_t charged=ctx.retainedAfterCaretInputBytes;
    CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,sequence,previous,2,
        a.candidate.nonce,a.proxyGeneration,a.selectionRevision,10,a.candidate.contextEpoch,
        a.candidate.windowInstanceToken)==0 && branch.valid && branch.settledSequence==sequence &&
        !ctx.ownerSelectionHandoff && ctx.retainedAfterCaretInputBytes<charged,
        "history_no_change_original_ACK_releases_hold_without_retiring_FIFO");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34 &&
        ctx.activeCaretNavigation==successor && successor.caretInputBranch==branch &&
        successor.inputPreviousSequence==sequence && branch.result.acceptedVersion==10,
        "history_no_change_original_successor_dequeued_on_same_actual_A");
    CjguiReleaseSession(token);
}

#ifndef CJGUI_PREFIX_NO_MAIN
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        if (!device) return 77;
        WaitingRequestFixture(device);
        ActualCommandFixture(device);
        ActualOwnerPrefixCandidateFixture(device,NO,0);
        ActualOwnerPrefixCandidateFixture(device,YES,0);
        ActualOwnerPrefixCandidateFixture(device,YES,1);
        for(uint32_t variant=2;variant<=8;variant++)ActualOwnerPrefixCandidateFixture(device,YES,variant);
        ActualCaretMutationHandoffFixture(device,NO);
        ActualCaretMutationHandoffFixture(device,YES);
        ActualHistoryNoChangeKeepsOriginalSuccessor(device);
        fprintf(stderr,"prefix_present_handoff failures=%d\n",failures);
        return failures ? 1 : 0;
    }
}

#endif
