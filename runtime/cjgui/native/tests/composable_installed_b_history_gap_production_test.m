#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static void ActualInstalledBHistoryGapFixture(id<MTLDevice> device,BOOL cancel) {
    BOOL history=NO;
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
    PreparePlainCandidate(ctx);
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"actual-gap-undo","Undo","Edit",
            "shortcut:command+z",0,0,1,0)==0,"actual_gap_declared_history_in_B");
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
    const char *why="none";
    CjguiOwnerSelectionHandoff *h=ctx.ownerSelectionHandoff;
    CjguiSelectionTransferCapsule *capsule=ctx.selectionTransferCapsule;
    CjguiCaretInputSnapshot *saved=active.caretInstalledResult;
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,h,&why)==CjguiOwnerProducerInstalledOwnB,
        "actual_gap_classifier_uses_saved_real_B");
#define GAP_REFUSES(label,mutation,restore) do { mutation; \
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,h,&why)==CjguiOwnerProducerInvalid,label); restore; } while(0)
    GAP_REFUSES("actual_gap_rejects_other_root",h.identity++;capsule.ownerHandoff=nil,
        h.identity--;capsule.ownerHandoff=h);
    GAP_REFUSES("actual_gap_rejects_owner_version_same_bytes",h.afterVersion++,h.afterVersion--);
    GAP_REFUSES("actual_gap_rejects_owner_choice_revision",h.choiceRevision++,h.choiceRevision--);
    GAP_REFUSES("actual_gap_rejects_missing_install_fact",active.caretInstalledResult=nil,active.caretInstalledResult=saved);
    CjguiInternalInstalledRangeCandidate original=saved.candidate,bad=original;
    bad.nonce++;GAP_REFUSES("actual_gap_rejects_transfer_nonce",saved.candidate=bad,saved.candidate=original);
    bad=original;bad.bindingEpoch++;GAP_REFUSES("actual_gap_rejects_B_binding",saved.candidate=bad,saved.candidate=original);
    bad=original;bad.nodeId++;GAP_REFUSES("actual_gap_rejects_B_target",saved.candidate=bad,saved.candidate=original);
    bad=original;bad.contextEpoch++;GAP_REFUSES("actual_gap_rejects_context",saved.candidate=bad,saved.candidate=original);
    bad=original;bad.windowInstanceToken++;GAP_REFUSES("actual_gap_rejects_window",saved.candidate=bad,saved.candidate=original);
    bad=original;bad.sourceEndByte++;GAP_REFUSES("actual_gap_rejects_source_span",saved.candidate=bad,saved.candidate=original);
    GAP_REFUSES("actual_gap_rejects_proxy_generation",saved.proxyGeneration++,saved.proxyGeneration--);
    GAP_REFUSES("actual_gap_rejects_native_selection",saved.selectionRevision++,saved.selectionRevision--);
    GAP_REFUSES("actual_gap_rejects_sequence_gap",active.inputPreviousSequence++,active.inputPreviousSequence--);
    GAP_REFUSES("actual_gap_rejects_old_A_receipt",ctx.selectionReceiptTransferId=a.candidate.nonce,ctx.selectionReceiptTransferId=transfer);
    int64_t ownerRevision=ctx.selectionReceiptOwnerRevision;
    ctx.selectionReceiptOwnerRevision=-1;
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,h,&why)==CjguiOwnerProducerInstalledOwnB,
        "actual_gap_unpublished_owner_revision_keeps_same_sealed_B_only");
    ctx.selectionReceiptOwnerRevision=ownerRevision;
#undef GAP_REFUSES
    uint8_t retired=9;
    CHECK(cjgui_internal_renderer_caret_input_terminal(token,ctx.sessionGeneration,sequence,previous,&retired)==0 &&
        retired==0,"actual_gap_live_pending_confirmation_is_not_terminal");
    if(cancel) {
        CjguiRetireOwnerHandoff(ctx,h,"new_pointer_choice");
        CHECK(cjgui_internal_renderer_caret_input_terminal(token,ctx.sessionGeneration,sequence,previous,&retired)==0 &&
            retired==1 && active.caretEditApplied,"actual_gap_retired_confirmation_preserves_owner_commit_fact");
        CHECK(cjgui_internal_renderer_caret_input_terminal(token,ctx.sessionGeneration,sequence+1,sequence,&retired)==
            CJGUI_INTERNAL_RENDERER_SCENE_STALE && retired==0,"actual_gap_terminal_cannot_relabel_next_input");
        CjguiInstalledRangeState *current=ctx.installedRangeBasis;
        CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,sequence,previous,1,
            current.candidate.nonce,current.proxyGeneration,current.selectionRevision,11,
            current.candidate.contextEpoch,current.candidate.windowInstanceToken)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "actual_gap_retirement_never_reports_successful_ACK");
        CjguiReleaseSession(token);return;
    }
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand timestamp:1 windowNumber:ctx.window.windowNumber
        context:nil characters:@"z" charactersIgnoringModifiers:@"z" isARepeat:NO keyCode:6];
    CHECK([ctx.composableSceneOverlay performKeyEquivalent:key],"actual_gap_real_Undo_after_committed_B_before_common_completion");
    CJGuiInternalQueuedInteraction *undo=ctx.pendingInteractions.firstObject;
    CjguiOwnerSelectionHandoff *root=ctx.ownerSelectionHandoff;
    CHECK(root && root.valid && !root.completed && ctx.activeCaretNavigation==active && branch.valid &&
        undo.ownerHandoff==root && undo.inputPreviousSequence==sequence &&
        undo.caretInputOrigin.candidate.nonce==transfer && undo.caretInputOrigin.acceptedVersion==11,
        "actual_gap_Undo_preserves_original_root_and_actual_B_producer");
    CjguiInternalRendererEvent waiting={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&waiting)==0 && waiting.kind==0,
        "actual_gap_original_Undo_cannot_execute_before_original_Delete_completion");
    CjguiInstalledRangeState *installedBasis=ctx.installedRangeBasis;
    CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,sequence,previous,1,
        installedBasis.candidate.nonce+1,installedBasis.proxyGeneration,installedBasis.selectionRevision,
        11,installedBasis.candidate.contextEpoch,installedBasis.candidate.windowInstanceToken)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.activeCaretNavigation==active && branch.settledSequence==previous && active.caretEditApplied,
        "actual_gap_failed_confirmation_keeps_same_original_input_and_owner_commit");
    CHECK(cjgui_internal_renderer_owner_handoff_complete(token,handoff,transfer,11,2,1,1)==0 &&
        ctx.activeCaretNavigation==active && branch.settledSequence==previous,
        "caret_owner_handoff_common_completion_does_not_invent_original_ACK");
    CHECK(cjgui_internal_renderer_owner_handoff_complete(token,handoff,transfer,11,2,1,1)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.activeCaretNavigation==active,
        "actual_gap_duplicate_common_completion_cannot_execute_owner_again");
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

int main(void) { @autoreleasepool { [NSApplication sharedApplication];ActualInstalledBHistoryGapFixture(MTLCreateSystemDefaultDevice(),NO);ActualInstalledBHistoryGapFixture(MTLCreateSystemDefaultDevice(),YES);return failures?1:0; } }
