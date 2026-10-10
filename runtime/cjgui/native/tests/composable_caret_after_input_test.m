// Real TextKit insert callbacks after the native caret FIFO. Owner settlement
// below is an explicit protocol fixture; normal Cangjie consumers are separate.
#define CJGUI_CARET_AFTER_INPUT_FIXTURE 1
#import "composable_installed_range_prefix_test.m"
static void CaretRecoveryExplicitDispose(CJGuiInternalSession *ctx);

static void CaretAfterInputBeforeOwnerFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,
        @"first\nsecond\nthird\n",71,910,7002);
    CHECK(overlay!=nil,"caret_after_actual_installed_fixture");
    if(!overlay)return;
    CJGuiInternalSession *ctx=overlay.session;
    NSString *before=[overlay.inputProxy.string copy];
    CHECK([overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)] &&
        [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)],
        "caret_after_two_native_navigation_callbacks");
    [overlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK([overlay.inputProxy.string isEqualToString:before],
        "caret_after_textkit_not_mutated_before_predecessor_owner_result");
    CHECK(ctx.installedRangeLocalTailSequence==0,
        "caret_after_no_old_coordinate_range_edit_before_navigation_settles");
    CHECK(cjgui_internal_renderer_cancel_caret_prefix(ctx.rendererSessionToken,
        ctx.installedRangeBasis.candidate.windowInstanceToken,ctx.ownedTextSessionBindingEpoch)==0,
        "caret_close_cancels_actual_pending_prefix_without_replay");
    CaretRecoveryExplicitDispose(ctx);
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static CjguiInternalRendererStatus CaretFixtureBoundary(CJGuiInternalSession *ctx,
    uint64_t sequence,uint64_t previous) {
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;
    return cjgui_internal_renderer_finish_caret_input(ctx.rendererSessionToken,
        ctx.sessionGeneration,sequence,previous,2,basis.candidate.nonce,
        ctx.installedRangeProxyGeneration,ctx.composableSceneOverlay.installedRangeSelectionRevision,
        ctx.installedRangeObservedAckVersion,basis.candidate.contextEpoch,basis.candidate.windowInstanceToken);
}

// The real Cangjie navigation owner creates a Pending selection installation
// after dequeuing the first key. Its following keys are descendants of that
// key, rather than independent inputs cancelling a pointer's Pending choice.
static void CaretAfterPendingSelectionFixture(id<MTLDevice> device,BOOL hasCaretPrefix,BOOL bindCaretPrefix) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=overlay.session;
    uint64_t token=ctx.rendererSessionToken;
    if(hasCaretPrefix) {
        [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveUp:)];
        CjguiInternalRendererEvent event={0};
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
            ctx.activeCaretNavigation.inputSequence==1,"caret_pending_real_navigation_dequeued");
    }
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0 && transfer,
        "caret_pending_selection_cell_created");
    NSData *body=[overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate={0};
    candidate.transferId=transfer;candidate.sourceWindowInstanceToken=7002;
    candidate.sourceOwnerVersion=10;candidate.sourceContextEpoch=4;candidate.sourceMirrorRevision=2;
    candidate.targetNodeId=401;candidate.targetResourceId=1;
    candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    candidate.targetSceneVersion=ctx.composableSceneVersion;
    candidate.targetProjectionVersion=overlay.activeProjectionVersion;
    candidate.targetAnchor16=4;candidate.targetFocus16=4;
    candidate.targetBodyUtf8=body.bytes;candidate.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&candidate,source,sizeof(source))==0,
        "caret_pending_captures_actual_source");
    if(bindCaretPrefix) {
        CHECK(cjgui_internal_renderer_bind_caret_selection_transfer(token,transfer,ctx.sessionGeneration+1,1,0)==
            CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
            cjgui_internal_renderer_bind_caret_selection_transfer(token,transfer,ctx.sessionGeneration,2,1)==
            CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ctx.selectionTransferCapsule.caretInputBranch,
            "caret_pending_old_generation_and_wrong_fifo_owner_refused");
        CHECK(cjgui_internal_renderer_bind_caret_selection_transfer(token,transfer,ctx.sessionGeneration,1,0)==0,
            "caret_pending_binds_only_actual_dequeued_owner");
    }
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "caret_pending_selection_published");
    if(hasCaretPrefix) {
        NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
            modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:@"x"
            charactersIgnoringModifiers:@"x" isARepeat:NO keyCode:7];
        // This is the same admission call at the beginning of both keyDown
        // paths. TextKit's actual insert callback follows it below.
        CHECK(!CjguiSelectionTransferDeferNativeInput(ctx,1,key,overlay.inputProxy.selectedRange,
            NSMakeRange(NSNotFound,0)),"caret_pending_dependent_key_reaches_textkit");
        uint32_t state=0,refs=0;uint8_t cancelled=0;
        cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancelled,&refs);
        CHECK(bindCaretPrefix ? (state==CJGUI_SELECTION_TRANSFER_PENDING && !cancelled) :
            (state==CJGUI_SELECTION_TRANSFER_ABORTED),bindCaretPrefix ?
            "caret_pending_dependent_key_does_not_abort_its_navigation" :
            "caret_pending_unbound_pointer_choice_is_not_a_caret_owner");
    }
    NSString *before=[overlay.inputProxy.string copy];
    [overlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    uint32_t state=0,refs=0;uint8_t cancelled=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancelled,&refs);
    if(hasCaretPrefix) {
        CHECK((bindCaretPrefix ? (state==CJGUI_SELECTION_TRANSFER_PENDING && !cancelled) :
            state==CJGUI_SELECTION_TRANSFER_ABORTED) &&
            [overlay.inputProxy.string isEqualToString:before] &&
            ctx.pendingInteractions.lastObject.afterCaretTextInput.previousSequence==1,
            "caret_pending_actual_insert_retains_prefix_without_old_coordinate_write");
        if(state==CJGUI_SELECTION_TRANSFER_PENDING)
            CHECK(cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer)==0,
                "caret_pending_explicit_abort_for_fixture_cleanup");
    } else {
        CHECK(state==CJGUI_SELECTION_TRANSFER_ABORTED &&
            ctx.pendingInteractions.lastObject.afterCaretTextInput==nil &&
            ![overlay.inputProxy.string isEqualToString:before],
            "caret_pending_unrelated_input_still_supersedes_pending_pointer_choice");
    }
    CHECK(cjgui_internal_renderer_selection_transfer_replay_input(token,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,
        "caret_pending_transfer_retired_without_replaying_dependent_input");
    if(hasCaretPrefix) {
        CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,1,0,3,
            0,0,0,0,0,0)==0,"caret_pending_cleanup_preserves_input_as_recovery");
        CaretRecoveryExplicitDispose(ctx);
    }
    cjgui_internal_renderer_destroy(token);
}

static void CaretAfterInputPrefixFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=overlay.session;
    uint64_t token=ctx.rendererSessionToken;
    NSRange initial=overlay.inputProxy.selectedRange;
    fprintf(stderr,"CARET_AFTER_FIXTURE initial=%lu:%lu\n",(unsigned long)initial.location,
        (unsigned long)NSMaxRange(initial));
    CHECK(initial.location==8 && initial.length==0,"caret_after_fixture_actual_focus_at_end");
    [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)];
    [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)];
    [overlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    [overlay.inputProxy insertText:@"Y" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
        ctx.activeCaretNavigation.inputSequence==1,"caret_after_first_navigation_actual_dequeue");
    CHECK(CaretFixtureBoundary(ctx,2,1)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.caretInputBranch.settledSequence==0,"caret_after_out_of_order_owner_result_refused");
    CHECK(CaretFixtureBoundary(ctx,1,0)==0,"caret_after_first_protocol_boundary_settled");
    event=(CjguiInternalRendererEvent){0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
        ctx.activeCaretNavigation.inputSequence==2,"caret_after_second_navigation_actual_dequeue");
    CHECK(CaretFixtureBoundary(ctx,2,1)==0,"caret_after_second_protocol_boundary_settled");
    event=(CjguiInternalRendererEvent){0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        [overlay.inputProxy.string isEqualToString:@"abc\ndef\nX"],
        "caret_after_first_actual_textkit_range_occurs_after_prefix");
    CjguiInternalInstalledRangeIntent x={0};
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,
        ctx.composableSceneVersion,&x)==0 && x.seq==1 && x.previousSeq==0 &&
        x.observedAckSeq==0 && x.ownerVersion==10,"caret_after_first_range_has_actual_install_origin");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&x,1,11)==0,
        "caret_after_first_explicit_protocol_owner_ack");
    event=(CjguiInternalRendererEvent){0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        [overlay.inputProxy.string isEqualToString:@"abc\ndef\nXY"],
        "caret_after_second_textkit_range_inherits_actual_ack_result");
    CjguiInternalInstalledRangeIntent y={0};
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,
        ctx.composableSceneVersion,&y)==0 && y.seq==2 && y.previousSeq==1 &&
        y.observedAckSeq==1 && y.observedAckVersion==11,
        "caret_after_second_prefix_contains_first_real_ack");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&y,1,12)==0 &&
        ctx.pendingInteractions.count==0 && ctx.retainedAfterCaretInputBytes==0 &&
        ctx.installedRangeObservedAckVersion==12,
        "caret_after_each_text_intent_exactly_once_capacity_retired");
    CaretRecoveryExplicitDispose(ctx);
    cjgui_internal_renderer_destroy(token);
}

// Actual copy/confirm/release protocol, with generation and origin checks.
static void CaretRecoveryExplicitDispose(CJGuiInternalSession *ctx) {
    while(ctx.rejectedAfterCaretInputs.count) {
        uint64_t m[21]={0};
        CHECK(cjgui_internal_renderer_peek_caret_recovery(ctx.rendererSessionToken,m,21)==0 &&
            m[0] && m[1]==ctx.sessionGeneration && m[15]==910,
            "caret_recovery_export_actual_generation_origin");
        NSMutableData *payload=[NSMutableData dataWithLength:(NSUInteger)m[12]];
        NSMutableData *reason=[NSMutableData dataWithLength:(NSUInteger)m[18]];
        CHECK(cjgui_internal_renderer_copy_caret_recovery(ctx.rendererSessionToken,m[1]+1,m[0],
            payload.mutableBytes,(uint32_t)m[12],reason.mutableBytes,(uint32_t)m[18])==
            CJGUI_INTERNAL_RENDERER_SCENE_STALE,"caret_recovery_old_session_copy_refused");
        CHECK(cjgui_internal_renderer_copy_caret_recovery(ctx.rendererSessionToken,m[1],m[0],
            payload.mutableBytes,(uint32_t)m[12],reason.mutableBytes,(uint32_t)m[18])==0 &&
            [payload isEqualToData:[ctx.rejectedAfterCaretInputs.firstObject.payload
                dataUsingEncoding:NSUTF8StringEncoding]],"caret_recovery_payload_exact_copy_before_confirm");
        CHECK(cjgui_internal_renderer_finish_caret_recovery(ctx.rendererSessionToken,m[1],m[0],2)==
            CJGUI_INTERNAL_RENDERER_SCENE_STALE,"caret_recovery_no_release_before_handoff");
        CHECK(cjgui_internal_renderer_finish_caret_recovery(ctx.rendererSessionToken,m[1],m[0],1)==0 &&
            cjgui_internal_renderer_finish_caret_recovery(ctx.rendererSessionToken,m[1],m[0],1)==0,
            "caret_recovery_same_copy_confirmation_idempotent");
        CHECK(cjgui_internal_renderer_destroy(ctx.rendererSessionToken)==
            CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED && !ctx.destroyed,
            "caret_recovery_exported_unclaimed_copy_still_blocks_close");
        CHECK(cjgui_internal_renderer_finish_caret_recovery(ctx.rendererSessionToken,m[1],m[0],2)==0 &&
            cjgui_internal_renderer_finish_caret_recovery(ctx.rendererSessionToken,m[1],m[0],2)==
                CJGUI_INTERNAL_RENDERER_SCENE_STALE,"caret_recovery_explicit_disposition_once");
    }
    CHECK(ctx.retainedAfterCaretInputBytes==0 && ctx.exportedCaretRecoveryBytes.count==0,
        "caret_recovery_explicit_disposition_releases_bytes_slots");
}

static void CaretAfterInputRejectFixture(id<MTLDevice> device,NSUInteger mode) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=overlay.session;
    uint64_t token=ctx.rendererSessionToken;
    [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)];
    [overlay.inputProxy insertText:@"保留" replacementRange:NSMakeRange(NSNotFound,0)];
    NSString *before=[overlay.inputProxy.string copy];
    if(mode==0) [overlay.inputProxy setSelectedRange:overlay.inputProxy.selectedRange];
    if(mode==1) ctx.installedRangeObservedAckVersion=11; // Explicit external-version discriminator.
    if(mode==2) ctx.ownedTextSessionBindingEpoch=72;
    CjguiInternalRendererEvent event={0};
    cjgui_internal_renderer_pump_event(token,0,&event);
    if(mode==3) cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,1,0,3,0,0,0,0,0,0);
    fprintf(stderr,"CARET_AFTER_REJECTION mode=%lu retained=%lu\n",(unsigned long)mode,
        (unsigned long)ctx.rejectedAfterCaretInputs.count);
    CHECK(ctx.rejectedAfterCaretInputs.count==1 &&
        [ctx.rejectedAfterCaretInputs[0].payload isEqualToString:@"保留"] &&
        ctx.rejectedAfterCaretInputs[0].origin.candidate.nonce==910 &&
        ctx.rejectedAfterCaretInputs[0].origin.acceptedVersion==10 &&
        [overlay.inputProxy.string isEqualToString:before] &&
        ctx.installedRangeLocalTailSequence==0,"caret_after_refusal_preserves_original_payload_and_origin_no_write");
    CHECK(!ctx.activeCaretNavigation && ctx.pendingInputQueueFullNotice,
        "caret_after_refusal_has_explicit_terminal_and_notice");
    CaretRecoveryExplicitDispose(ctx);
    cjgui_internal_renderer_destroy(token);
}

// Real scene commit, with an older genuine input installation. An accepted
// repaint is not a new source; a different body must never certify that source.
static void CaretAfterAcceptedSceneFixture(id<MTLDevice> device,BOOL changedBody) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=overlay.session;
    CJGuiInternalComposableSceneNode *old=ctx.composableNodes[0];
    CJGuiInternalComposableSceneNode *next=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=old.node;raw.projectionVersion=2;
    next.node=raw;next.index=0;next.value=changedBody?@"different\n":old.value;
    next.styleRunsSignature=@"";next.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:next];
    ctx.stagedComposableSceneVersion=2;ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=2;
    CHECK(CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken)==0,
        "caret_after_new_actual_accepted_scene_committed");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    [ctx.pendingInteractions removeAllObjects];
    [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)];
    if(changedBody)[overlay.inputProxy insertText:@"保留" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererEvent event={0};
    cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event);
    if(!changedBody) {
        CHECK(event.kind==35 && event.projectionVersion==2 &&
            ctx.installedRangeBasis.candidate.installedSceneVersion==1,
            "caret_after_uses_actual_accepted_node_keeps_original_install_identity");
    } else {
        CHECK(event.kind==0 && ctx.rejectedAfterCaretInputs.count==1 &&
            [ctx.rejectedAfterCaretInputs[0].payload isEqualToString:@"保留"],
            "caret_after_unrelated_changed_body_frame_does_not_certify_input");
    }
    if(changedBody)CaretRecoveryExplicitDispose(ctx);
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void CaretAfterUnclaimedRecoveryCloseFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=overlay.session;
    [ctx.pendingInteractions removeAllObjects];
    [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveDown:)];
    [overlay.inputProxy insertText:@"未提交" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererEvent event={0};
    cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event);
    cjgui_internal_renderer_finish_caret_input(ctx.rendererSessionToken,ctx.sessionGeneration,
        1,0,3,0,0,0,0,0,0);
    CHECK(ctx.rejectedAfterCaretInputs.count==1,"caret_recovery_real_refusal_has_payload");
    CHECK(cjgui_internal_renderer_destroy(ctx.rendererSessionToken)==
        CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED && !ctx.destroyed,
        "caret_recovery_unclaimed_payload_blocks_destructive_close");
    CaretRecoveryExplicitDispose(ctx);
    if(!ctx.destroyed)cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

// Delete keys 51/117 are the same kind of dependent NAVIGATE intent as the
// relative arrows: their target caret is the dequeued navigation this pending
// installation belongs to. A real normal-consumer RED (fast Down then Delete on
// the cold Unicode fixture) deleted at the OLD caret byte because the delete
// aborted that installation, so the bypass must cover them under the exact same
// binding checks; an unbound pointer/external choice must still be superseded.
static void CaretAfterPendingDeleteKeyFixture(id<MTLDevice> device,BOOL bindCaretPrefix) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=overlay.session;
    uint64_t token=ctx.rendererSessionToken;
    [overlay textView:overlay.inputProxy doCommandBySelector:@selector(moveUp:)];
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
        ctx.activeCaretNavigation.inputSequence==1,"caret_delete_predecessor_navigation_dequeued");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0 && transfer,
        "caret_delete_selection_cell_created");
    NSData *body=[overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate={0};
    candidate.transferId=transfer;candidate.sourceWindowInstanceToken=7002;
    candidate.sourceOwnerVersion=10;candidate.sourceContextEpoch=4;candidate.sourceMirrorRevision=2;
    candidate.targetNodeId=401;candidate.targetResourceId=1;
    candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    candidate.targetSceneVersion=ctx.composableSceneVersion;
    candidate.targetProjectionVersion=overlay.activeProjectionVersion;
    candidate.targetAnchor16=4;candidate.targetFocus16=4;
    candidate.targetBodyUtf8=body.bytes;candidate.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&candidate,source,sizeof(source))==0,
        "caret_delete_captures_actual_source");
    if(bindCaretPrefix) {
        CHECK(cjgui_internal_renderer_bind_caret_selection_transfer(token,transfer,ctx.sessionGeneration,1,0)==0,
            "caret_delete_binds_only_actual_dequeued_owner");
    }
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "caret_delete_selection_published");
    NSEvent *del=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:@"\x7f"
        charactersIgnoringModifiers:@"\x7f" isARepeat:NO keyCode:51];
    // The same admission call at the beginning of both keyDown paths.
    CHECK(!CjguiSelectionTransferDeferNativeInput(ctx,1,del,overlay.inputProxy.selectedRange,
        NSMakeRange(NSNotFound,0)),"caret_delete_dependent_key_reaches_textkit");
    uint32_t state=0,refs=0;uint8_t cancelled=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancelled,&refs);
    CHECK(bindCaretPrefix ? (state==CJGUI_SELECTION_TRANSFER_PENDING && !cancelled) :
        (state==CJGUI_SELECTION_TRANSFER_ABORTED),bindCaretPrefix ?
        "caret_delete_does_not_abort_its_own_navigation" :
        "caret_delete_unbound_pointer_choice_is_not_a_caret_owner");
    if(bindCaretPrefix) {
        NSUInteger before=ctx.pendingInteractions.count;
        CHECK([overlay textView:overlay.inputProxy doCommandBySelector:@selector(deleteBackward:)] &&
            ctx.pendingInteractions.count==before+1 &&
            ctx.pendingInteractions.lastObject.kind==
                CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            [ctx.pendingInteractions.lastObject.formText isEqualToString:@"deleteBackward"],
            "caret_delete_joins_the_same_navigate_fifo_behind_the_prefix");
    }
    // A bound delete leaves the installation PENDING (that is the fix), so the
    // owner terminal must retire the branch before the transfer can be replayed
    // and released. An unbound delete already aborted it above.
    if(bindCaretPrefix) {
        CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,1,0,3,
            0,0,0,0,0,0)==0,"caret_delete_cleanup_preserves_input_as_recovery");
        // The owner terminal rejects the branch but leaves the cell PENDING by
        // design; the fixture then retires it explicitly.
        CHECK(cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer)==0,
            "caret_delete_explicit_abort_for_fixture_cleanup");
    }
    CHECK(cjgui_internal_renderer_selection_transfer_replay_input(token,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,
        "caret_delete_transfer_retired_without_replaying_dependent_input");
    if(bindCaretPrefix) { CaretRecoveryExplicitDispose(ctx); }
    cjgui_internal_renderer_destroy(token);
}

// Both the real drag highlight and the navigation restore install a selection
// transfer whose B preparation was captured against ONE accepted scene. This
// pins what the framework does when an accepted scene is published in between:
// the install must refuse with a named status instead of adopting geometry that
// belongs to the retired scene. Measured on the normal consumer this is
// SCENE_STALE (33) for the drag and PRESENT_PENDING (20) for a long-text
// restore, and the fallback then paints an older, shorter span.
static void CaretAfterSceneAdvanceInstallFixture(id<MTLDevice> device,BOOL advanceScene) {
    NSMutableString *body=[NSMutableString stringWithCapacity:1300];
    for(NSUInteger line=0;line<48;line++)
        [body appendFormat:@"line %lu abcdefghijklmnopqrstuvwxyz\n",(unsigned long)line];
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,body,71,910,7002);
    if(!overlay){CHECK(NO,"caret_scene_advance_actual_installed_fixture");return;}
    CJGuiInternalSession *ctx=overlay.session;
    uint64_t token=ctx.rendererSessionToken;
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0 && transfer,
        "caret_scene_advance_selection_cell_created");
    NSData *bodyData=[overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate={0};
    candidate.transferId=transfer;candidate.sourceWindowInstanceToken=7002;
    candidate.sourceOwnerVersion=10;candidate.sourceContextEpoch=4;candidate.sourceMirrorRevision=2;
    candidate.targetNodeId=401;candidate.targetResourceId=1;
    candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    candidate.targetSceneVersion=ctx.composableSceneVersion;
    candidate.targetProjectionVersion=overlay.activeProjectionVersion;
    candidate.targetAnchor16=4;candidate.targetFocus16=4;
    candidate.targetBodyUtf8=bodyData.bytes;candidate.targetBodyUtf8Length=(uint32_t)bodyData.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&candidate,source,sizeof(source))==0,
        "caret_scene_advance_captures_actual_source");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "caret_scene_advance_selection_published");
    uint8_t ready=0;
    CjguiInternalRendererStatus prepared=cjgui_internal_renderer_selection_transfer_prepare_b(
        token,transfer,0,&ready);
    uint64_t sceneBefore=ctx.composableSceneVersion;
    if(advanceScene) ctx.composableSceneVersion=sceneBefore+1;
    CjguiInternalSelectionTransferReceipt receipt={0};
    CjguiInternalRendererStatus installed=cjgui_internal_renderer_selection_transfer_install_b(
        token,transfer,&receipt);
    if(advanceScene) ctx.composableSceneVersion=sceneBefore;
    fprintf(stderr,"CARET_SCENE_ADVANCE_INSTALL advance=%d prepared=%d ready=%d installed=%d\n",
        (int)advanceScene,(int)prepared,(int)ready,(int)installed);
    CHECK(prepared==CJGUI_INTERNAL_RENDERER_OK,"caret_scene_advance_prepare_status_named");
    if(advanceScene) {
        // A scene published between prepare and install must never be adopted.
        CHECK(installed==CJGUI_INTERNAL_RENDERER_SCENE_STALE ||
            installed==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING,
            "caret_scene_advance_install_refuses_retired_scene_geometry");
    }
    (void)cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_replay_input(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token,transfer);
    cjgui_internal_renderer_destroy(token);
}


// The scene re-base must be a mechanism, not a gate removal: with the source
// identity intact a scene published between prepare and install re-bases (Zed
// resolves selections against the current DisplaySnapshot), while a transfer
// whose recorded body no longer matches the live node must still be refused.
static void CaretAfterSceneRebaseFixture(id<MTLDevice> device,BOOL breakIdentity) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    if(!overlay){CHECK(NO,"caret_rebase_actual_installed_fixture");return;}
    CJGuiInternalSession *ctx=overlay.session;
    uint64_t token=ctx.rendererSessionToken;
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0 && transfer,
        "caret_rebase_selection_cell_created");
    NSData *body=[overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate={0};
    candidate.transferId=transfer;candidate.sourceWindowInstanceToken=7002;
    candidate.sourceOwnerVersion=10;candidate.sourceContextEpoch=4;candidate.sourceMirrorRevision=2;
    candidate.targetNodeId=401;candidate.targetResourceId=1;
    candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    candidate.targetSceneVersion=ctx.composableSceneVersion;
    candidate.targetProjectionVersion=overlay.activeProjectionVersion;
    candidate.targetAnchor16=4;candidate.targetFocus16=4;
    candidate.targetBodyUtf8=body.bytes;candidate.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&candidate,source,sizeof(source))==0,
        "caret_rebase_captures_actual_source");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "caret_rebase_selection_published");
    // A selection update publishes a new scene; that is what used to invalidate
    // the very installation the update belongs to.
    ctx.composableSceneVersion=ctx.composableSceneVersion+1;
    if(breakIdentity) ctx.selectionTransferCapsule.bBody=@"a body that is not the live node";
    CjguiInternalSelectionTransferReceipt receipt={0};
    CjguiInternalRendererStatus installed=cjgui_internal_renderer_selection_transfer_install_b(
        token,transfer,&receipt);
    fprintf(stderr,"CARET_SCENE_REBASE break=%d installed=%d\n",(int)breakIdentity,(int)installed);
    CHECK(breakIdentity ? installed!=CJGUI_INTERNAL_RENDERER_OK : installed==CJGUI_INTERNAL_RENDERER_OK,
        breakIdentity ? "caret_rebase_still_refuses_a_changed_identity"
                      : "caret_rebase_adopts_the_live_scene_for_an_intact_identity");
    (void)cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_replay_input(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token,transfer);
    cjgui_internal_renderer_destroy(token);
}

static void CaretRelativeDeleteProducerFixture(id<MTLDevice> device) {
    SourceInstallOverlay *o = InstalledRangeCreateActivatedFixture(device,
        @"first\nsecond\nthird\n",71,910,7002);
    CJGuiInternalSession *ctx = o.session;
    NSString *body = [o.inputProxy.string copy];
    [o textView:o.inputProxy doCommandBySelector:@selector(moveDown:)];
    [o textView:o.inputProxy doCommandBySelector:@selector(moveDown:)];
    [o textView:o.inputProxy doCommandBySelector:@selector(deleteBackward:)];
    CJGuiInternalQueuedInteraction *delete = ctx.pendingInteractions.lastObject;
    CHECK(delete.inputSequence == 3 && delete.inputPreviousSequence == 2 &&
        delete.caretInputBranch == ctx.caretInputBranch && delete.caretInputBranch.valid,
        "relative_delete_has_actual_navigation_predecessor");
    CHECK([o.inputProxy.string isEqualToString:body] && ctx.installedRangeLocalTailSequence == 0,
        "relative_delete_never_mutates_proxy_before_owner");
    CjguiInternalRendererEvent event = {0};
    cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event);
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(ctx.rendererSessionToken,
        ctx.sessionGeneration,1,0,10,11,4,7002) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "navigation_cannot_claim_edit_result");
    CHECK(CaretFixtureBoundary(ctx,1,0) == 0, "relative_delete_first_nav_settled");
    cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event);
    CHECK(CaretFixtureBoundary(ctx,2,1) == 0, "relative_delete_second_nav_settled");
    cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event);
    CHECK(ctx.activeCaretNavigation.inputSequence == 3 &&
        [ctx.activeCaretNavigation.formText isEqualToString:@"deleteBackward"],
        "relative_delete_dispatches_after_both_predecessors");
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(ctx.rendererSessionToken,
        ctx.sessionGeneration,3,2,10,11,4,7002) == 0 &&
        cjgui_internal_renderer_mark_caret_edit_applied(ctx.rendererSessionToken,
        ctx.sessionGeneration,3,2,10,11,4,7002) == 0,
        "one_edit_result_reack_is_immutable_and_body_free");
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(ctx.rendererSessionToken,
        ctx.sessionGeneration,3,2,10,12,4,7002) == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        CaretFixtureBoundary(ctx,3,2) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "edit_waits_for_actual_after_version_and_never_navigation_ack");
    cjgui_internal_renderer_cancel_caret_prefix(ctx.rendererSessionToken,7002,71);
    CaretRecoveryExplicitDispose(ctx);
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void CaretEditProjectionOwnerFixture(id<MTLDevice> device,BOOL superseded,BOOL history) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"first\nsecond\n",71,910,7002);
    if(!o){CHECK(NO,"edit_projection_actual_A_created");return;}
    CJGuiInternalSession *ctx=o.session; uint64_t token=ctx.rendererSessionToken;
    NSString *a=[o.inputProxy.string copy]; NSTextView *old=o.inputProxy;
    [o textView:o.inputProxy doCommandBySelector:history ? @selector(undo:) : @selector(deleteBackward:)];
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==(history ? 34 : 35),
        "edit_projection_real_delete_dequeued");
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,1,0,10,11,4,7002)==0,
        "edit_projection_real_owner_terminal_recorded");
    NSString *b=superseded?a:@"firs\nsecond\n";
    if(!superseded) {
        CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
        raw.projectionVersion=2;node.node=raw;node.value=b;node.styleRunsSignature=@"";
        ctx.composableSceneVersion+=1;
        [o setNodesFromProjection:@[node]];
        CHECK(o.sourceInputParked && o.inputProxy==old && [o.inputProxy.string isEqualToString:a] &&
            CjguiCaretSnapshotMatchesActual(ctx,ctx.caretInputBranch.result),
            "edit_projection_preserves_actual_A_until_same_edit_B");
    }
    uint64_t transfer=0; cjgui_internal_renderer_selection_transfer_create(token,&transfer);
    NSData *bytes=[b dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=7002;c.sourceOwnerVersion=superseded?12:11;
    c.sourceContextEpoch=4;c.sourceMirrorRevision=3;c.targetNodeId=401;c.targetResourceId=1;
    c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    c.targetSceneVersion=ctx.composableSceneVersion;c.targetAnchor16=4;c.targetFocus16=4;
    c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&c,source,sizeof(source))==0,
        "edit_projection_capture_reads_actual_A_and_exact_B");
    CjguiInternalRendererStatus bound=cjgui_internal_renderer_bind_caret_selection_transfer(
        token,transfer,ctx.sessionGeneration,1,0);
    CHECK(superseded?bound==CJGUI_INTERNAL_RENDERER_SCENE_STALE:bound==0,
        superseded?"edit_projection_later_owner_version_cannot_settle_old_delete":
                   "edit_projection_same_edit_B_binds_actual_delete");
    (void)cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_replay_input(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token,transfer);
    cjgui_internal_renderer_cancel_caret_prefix(token,7002,71);
    CaretRecoveryExplicitDispose(ctx); cjgui_internal_renderer_destroy(token);
}

static void CaretHistoryReceiptFixture(id<MTLDevice> device,BOOL redo) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"first\nsecond\n",71,910,7002);
    if(!o){CHECK(NO,"history_actual_A_created");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken;
    NSString *body=[o.inputProxy.string copy];
    [o textView:o.inputProxy doCommandBySelector:@selector(moveLeft:)];
    [o textView:o.inputProxy doCommandBySelector:redo ? @selector(redo:) : @selector(undo:)];
    CJGuiInternalQueuedInteraction *history=ctx.pendingInteractions.lastObject;
    CHECK(history.kind==34 && history.inputSequence==2 && history.inputPreviousSequence==1 &&
        history.caretInputOrigin && history.caretInputBranch==ctx.caretInputBranch &&
        [o.inputProxy.string isEqualToString:body],
        redo ? "redo_keeps_actual_text_origin_after_navigation" : "undo_keeps_actual_text_origin_after_navigation");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
        CaretFixtureBoundary(ctx,1,0)==0,"history_navigation_predecessor_settles_first");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34 &&
        ctx.activeCaretNavigation==history,"history_command_dequeues_once_on_original_prefix");
    uint64_t generation=0,sequence=0,previous=0;uint32_t kind=0;
    CHECK(cjgui_internal_renderer_owner_consumed_input_provenance(token,&generation,&sequence,&previous,&kind)==1 &&
        generation==ctx.sessionGeneration && sequence==2 && previous==1 && kind==34,
        "history_exact_prefix_reaches_normal_managed_consumer_sideband");
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,2,1,10,11,4,7002)==0 &&
        cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,2,1,10,11,4,7002)==0,
        "history_exact_owner_receipt_confirmation_idempotent");
    CHECK(cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,2,1,10,12,4,7002)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,2,1,11,12,4,7002)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && CaretFixtureBoundary(ctx,2,1)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "history_no_version_inference_and_no_success_before_actual_install");
    CHECK([o.inputProxy.string isEqualToString:body] && ctx.installedRangeObservedAckVersion==10,
        "history_receipt_confirmation_never_replays_owner_or_mutates_proxy");
    cjgui_internal_renderer_cancel_caret_prefix(token,7002,71);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

static void CaretEditParkedSelectorFixture(id<MTLDevice> device,uint32_t physical) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"first\nsecond\n",71,910,7002);
    if(!o){CHECK(NO,"parked_delete_actual_A_created");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken;
    NSString *a=[o.inputProxy.string copy];
    [o textView:o.inputProxy doCommandBySelector:@selector(deleteBackward:)];
    CjguiInternalRendererEvent event={0};cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==35 && cjgui_internal_renderer_mark_caret_edit_applied(token,
        ctx.sessionGeneration,1,0,10,11,4,7002)==0,"parked_delete_first_owner_result_recorded");
    cjgui_internal_renderer_set_composable_owned_text_session(token,401,1,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT,72,1);
    ctx.composableSceneVersion=2;[o setNodesFromProjection:@[]];
    CHECK(o.sourceInputParked && ![o activeFocusableNode] && CjguiInputProxyIsFirstResponder(o),
        "parked_delete_has_real_first_responder_without_current_scene_node");
    if (physical==3) cjgui_internal_renderer_set_source_install_gate(token,72,88,1);
    if(physical) {
        NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
            modifierFlags:0 timestamp:0 windowNumber:ctx.window.windowNumber context:nil
            characters:@"\177" charactersIgnoringModifiers:@"\177" isARepeat:NO keyCode:51];
        if (physical>=2) [o.inputHost keyDown:key];
        else [o keyDown:key];
    } else { [o.inputProxy doCommandBySelector:@selector(deleteBackward:)]; }
    CHECK([o.inputProxy.string isEqualToString:a] && ctx.installedRangeLocalTailSequence==0 &&
        ctx.pendingInteractions.count==1 && ctx.pendingInteractions.firstObject.kind==35 &&
        ctx.pendingInteractions.firstObject.caretInputBranch==ctx.activeCaretNavigation.caretInputBranch &&
        ctx.pendingInteractions.firstObject.caretInputOrigin.acceptedVersion==10 &&
        ctx.pendingInteractions.firstObject.inputSequence==2 &&
        ctx.pendingInteractions.firstObject.inputPreviousSequence==1,
        physical==3 ? "parked_delete_actual_input_host_precedes_new_install_gate_with_original_FIFO" :
        physical==2 ? "parked_delete_actual_input_host_successor_keeps_original_FIFO_without_proxy_write" :
        physical ? "parked_delete_physical_successor_captures_original_FIFO_without_proxy_write" :
                   "parked_delete_selector_successor_captures_original_FIFO_without_proxy_write");
    cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==0 && ctx.activeCaretNavigation.inputSequence==1,
        "parked_delete_successor_waits_for_first_real_install_receipt");
    cjgui_internal_renderer_cancel_caret_prefix(token,7002,72);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

static void EmptySourceCaretFixture(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"",71,910,7002);
    if(!o){CHECK(NO,"empty_source_actual_installed_receipt");return;}
    CJGuiInternalSession *ctx=o.session;
    CJGuiInternalComposableSceneNode *node=ctx.view.composableNodes.firstObject;
    o.inputProxy.font=[NSFont systemFontOfSize:18];
    o.inputProxy.selectedRange=NSMakeRange(0,0);
    [o setMultilineScrollOffset:47 forNode:node];
    [o updateActiveMultilineTextDecorationsForNode:node];
    CGFloat height=MAX(1.0,[o.inputProxy.layoutManager defaultLineHeightForFont:o.inputProxy.font]-4.0);
    CHECK(CjguiInputProxyIsFirstResponder(o) && !NSIsEmptyRect(node.textCaretRect) &&
        fabs(NSHeight(node.textCaretRect)-height)<0.01 && NSHeight(node.textCaretRect)<36 &&
        fabs([o multilineScrollOffsetForNode:node])<0.01,
        "empty_source_current_proxy_has_one_font_line_caret_and_no_old_scroll");
    CHECK(node.textSelectionRects.count==0 && node.textMarkedRects.count==0,
        "empty_source_caret_does_not_fabricate_selection_or_marked_text");
    o.testWindow.testResponder=nil;
    [o updateActiveMultilineTextDecorationsForNode:node];
    CHECK(NSIsEmptyRect(node.textCaretRect),"empty_source_unfocused_proxy_does_not_draw_caret");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void OwnerHandoffProducerFixture(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken,h=0;
    NSString *a=[o.inputProxy.string copy];
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,71,10,0,0,&h)==0 && h,
        "owner_handoff_begins_before_owner_mutation");
    [o textView:o.inputProxy doCommandBySelector:@selector(moveLeft:)];
    [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererEvent event={0};cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==0 && !ctx.activeCaretNavigation && [o.inputProxy.string isEqualToString:a] &&
        ctx.pendingInteractions.count==2 && ctx.pendingInteractions[0].ownerHandoff.identity==h &&
        ctx.pendingInteractions[1].afterCaretTextInput.ownerHandoff.identity==h,
        "owner_handoff_actual_producers_hold_original_A_in_same_FIFO_before_seal");
    CHECK(cjgui_internal_renderer_owner_handoff_seal(token,h,11,2,0,0,99)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,h,12,2,0,0,100)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "owner_handoff_sealed_owner_result_is_immutable");
    event=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==0 && [o.inputProxy.string isEqualToString:a],
        "owner_handoff_seal_alone_never_releases_input");
    CHECK(cjgui_internal_renderer_owner_handoff_abort(token,h)==0 &&
        ctx.rejectedAfterCaretInputs.count==1 &&
        [ctx.rejectedAfterCaretInputs[0].payload isEqualToString:@"X"] &&
        ctx.rejectedAfterCaretInputs[0].origin.acceptedVersion==10 &&
        cjgui_internal_renderer_owner_handoff_complete(token,h,99,11,2,0,0)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "owner_handoff_abort_preserves_exact_original_input_and_late_B_is_zero_write");
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

static void OwnerHandoffParkedSelectorFixture(id<MTLDevice> device,uint32_t physical) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken,h=0;
    NSString *a=[o.inputProxy.string copy];
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,71,10,0,0,&h)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,h,11,2,0,0,99)==0,
        "owner_handoff_parked_selector_actual_root_created");
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
    raw.projectionVersion=2;node.node=raw;node.value=@"abcZ\ndef\n";node.styleRunsSignature=@"";
    ctx.composableSceneVersion=2;[o setNodesFromProjection:@[node]];
    CHECK(o.sourceInputParked && ![o activeFocusableNode],
        "owner_handoff_parked_selector_old_A_absent_from_new_scene");
    if(physical==2)cjgui_internal_renderer_set_source_install_gate(token,71,88,1);
    if(physical) {
        NSEvent *left=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
            modifierFlags:0 timestamp:0 windowNumber:ctx.window.windowNumber context:nil
            characters:@"\uf702" charactersIgnoringModifiers:@"\uf702" isARepeat:NO keyCode:123];
        [o keyDown:left];
    } else { [o.inputProxy doCommandBySelector:@selector(deleteBackward:)]; }
    CjguiInternalRendererEvent event={0};cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==0 && [o.inputProxy.string isEqualToString:a] && ctx.pendingInteractions.count==1 &&
        ctx.pendingInteractions.firstObject.kind==35 &&
        [ctx.pendingInteractions.firstObject.formText isEqualToString:physical ? @"left" : @"deleteBackward"] &&
        ctx.pendingInteractions.firstObject.ownerHandoff.identity==h &&
        ctx.pendingInteractions.firstObject.caretInputOrigin.acceptedVersion==10,
        physical==2 ? "owner_handoff_parked_physical_arrow_precedes_install_gate_with_original_FIFO" :
        physical ? "owner_handoff_parked_physical_arrow_joins_original_FIFO_without_proxy_delete" :
        "owner_handoff_parked_selector_joins_original_FIFO_without_proxy_delete");
    cjgui_internal_renderer_owner_handoff_abort(token,h);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

// A local range has already changed the real proxy before its owner ACK.
// That ACK advances the installed source extent, while the next selector can
// arrive before B installs. The producer must retain its real origin and FIFO.
static void OwnerHandoffRangeAckProducerFixture(id<MTLDevice> device,NSUInteger supersede,BOOL history) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    if(!o){CHECK(NO,"owner_handoff_range_ack_actual_A_available");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken,h=0;
    [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererEvent event={0};CjguiInternalInstalledRangeIntent x={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,ctx.composableSceneVersion,&x)==0 &&
        cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,71,10,910,x.seq,&h)==0,
        "owner_handoff_range_ack_root_before_actual_owner_ACK");
    CjguiCaretInputSnapshot *original=ctx.ownerSelectionHandoff.initialA;
    CHECK(original && cjgui_internal_renderer_ack_installed_range(token,&x,1,11)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,h,11,2,1,1,99)==0 &&
        ctx.installedRangeBasis.candidate.sourceEndByte==original.candidate.sourceEndByte+1,
        "owner_handoff_range_ack_advances_extent_from_exact_original_range_only");
    if(supersede==1) o.inputProxy.string=@"unrelated";
    if(supersede==2) o.inputProxy.selectedRange=NSMakeRange(0,0);
    NSString *before=[o.inputProxy.string copy];
    NSUInteger pending=ctx.pendingInteractions.count;
    [o textView:o.inputProxy doCommandBySelector:history ? @selector(undo:) : @selector(deleteBackward:)];
    if(supersede) {
        CHECK(ctx.pendingInteractions.count==pending &&
            [o.inputProxy.string isEqualToString:before] &&
            cjgui_internal_renderer_owner_handoff_state(token,h)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "owner_handoff_range_ack_changed_real_body_or_selection_cannot_borrow_original_receipt");
    } else {
        CHECK(ctx.pendingInteractions.count==pending+1 &&
            ctx.pendingInteractions.lastObject.kind==(history ? 34 : 35) &&
            ctx.pendingInteractions.lastObject.ownerHandoff.identity==h &&
            ctx.pendingInteractions.lastObject.caretInputOrigin.acceptedVersion==11 &&
            ctx.ownerSelectionHandoff.initialA==original &&
            ctx.caretInputBranch.origin==original &&
            [o.inputProxy.string isEqualToString:before],
            history ? "history_selector_follows_exact_range_ACK_on_original_FIFO" :
            "owner_handoff_range_ack_next_selector_keeps_actual_origin_and_original_FIFO_without_proxy_delete");
    }
    if(ctx.ownerSelectionHandoff.valid)cjgui_internal_renderer_owner_handoff_abort(token,h);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

static void OwnerHandoffActualBFixture(id<MTLDevice> device,BOOL beforeSink,BOOL textOnly) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    if(!o){CHECK(NO,"owner_handoff_B_actual_A_available");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken,h=0,transfer=0;
    int64_t beforeVersion=10,afterVersion=11;
    if(textOnly) {
        [o.inputProxy insertText:@"Q" replacementRange:NSMakeRange(NSNotFound,0)];
        CjguiInternalRendererEvent prior={0};CjguiInternalInstalledRangeIntent edit={0};
        CHECK(cjgui_internal_renderer_pump_event(token,0,&prior)==0 && prior.kind==51 &&
            cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,ctx.composableSceneVersion,&edit)==0 &&
            cjgui_internal_renderer_ack_installed_range(token,&edit,1,11)==0,
            "owner_handoff_text_only_real_prior_ACK_without_navigation");
        beforeVersion=11;afterVersion=12;
    }
    NSString *a=[o.inputProxy.string copy];
    if(beforeSink) {
        [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
        [o textView:o.inputProxy doCommandBySelector:@selector(moveLeft:)];
        [o.inputProxy insertText:@"Y" replacementRange:NSMakeRange(NSNotFound,0)];
        CjguiInternalRendererEvent first={0};CjguiInternalInstalledRangeIntent x={0};
        CHECK(cjgui_internal_renderer_pump_event(token,0,&first)==0 && first.kind==51 &&
            cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,ctx.composableSceneVersion,&x)==0,
            "owner_handoff_B_same_batch_original_range_claimed");
        CJGuiInternalQueuedInteraction *relative=ctx.pendingInteractions.firstObject;
        CjguiCaretInputSnapshot *original=relative.caretInputOrigin;
        CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,71,10,910,x.seq,&h)==0 &&
            original && relative.caretInputOrigin==original && original.acceptedVersion==10 &&
            [original.body isEqualToData:[o.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding]] &&
            relative.ownerHandoff.identity==h &&
            ctx.pendingInteractions.lastObject.afterCaretTextInput.ownerHandoff.identity==h &&
            cjgui_internal_renderer_ack_installed_range(token,&x,1,11)==0,
            "owner_handoff_B_same_batch_relative_and_text_enrolled_at_original_cutoff_before_Sink");
        a=[o.inputProxy.string copy];
    } else {
        CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,71,beforeVersion,0,0,&h)==0,
            "owner_handoff_B_prospective_boundary_before_real_producers");
        if(!textOnly)[o textView:o.inputProxy doCommandBySelector:@selector(moveLeft:)];
        [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    }
    CHECK(cjgui_internal_renderer_owner_handoff_seal(token,h,afterVersion,2,0,0,99)==0,
        "owner_handoff_B_actual_owner_result_sealed");
    NSString *b=beforeSink ? a : @"abcZ\ndef\n";
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
    raw.projectionVersion=2;node.node=raw;node.value=b;node.styleRunsSignature=@"";
    // This protocol fixture publishes the same complete bounded layout that
    // the normal scene preparer supplies, rather than an unprepared raw node.
    node.preparedTextLayout=CjguiPrepareTextNodeLayout(node,b,1.0,nil,ctx);
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=2;ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=2;
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,"owner_handoff_B_new_scene_committed");
    [o setNodesFromProjection:ctx.view.composableNodes];
    CHECK(o.sourceInputParked && [o.inputProxy.string isEqualToString:a],
        "owner_handoff_B_projection_does_not_replace_original_A");
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,
        "owner_handoff_B_real_transfer_created");
    NSData *bytes=[b dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=7002;c.sourceOwnerVersion=afterVersion;
    c.sourceContextEpoch=4;c.sourceMirrorRevision=3;c.targetNodeId=401;c.targetResourceId=1;
    c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    c.targetSceneVersion=ctx.composableSceneVersion;c.targetProjectionVersion=2;
    c.targetAnchor16=0;c.targetFocus16=0;c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&c,source,sizeof(source))==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,h,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "owner_handoff_B_binds_original_A_and_same_target_receipt");
    CjguiInternalRendererEvent event={0};cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==0 && !ctx.activeCaretNavigation && [o.inputProxy.string isEqualToString:a],
        "owner_handoff_B_pending_never_dispatches_relative_successor");
    CjguiInternalSelectionTransferReceipt receipt={0};
    CjguiInternalRendererStatus installed=cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt);
    fprintf(stderr,"OWNER_HANDOFF_B_INSTALL status=%u transfer=%llu scene=%llu receipt=%llu first=%u\n",
        (unsigned)installed,(unsigned long long)transfer,(unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)receipt.transferId,(unsigned)receipt.firstResponder);
    CHECK(installed==0 && receipt.transferId==transfer && receipt.firstResponder,
        "owner_handoff_B_installs_actual_first_responder_receipt");
    event=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&event);
    CHECK(event.kind==0 && !ctx.activeCaretNavigation,
        "owner_handoff_B_install_alone_waits_for_common_publication");
    CHECK(cjgui_internal_renderer_owner_handoff_complete(token,h,transfer,afterVersion,3,0,0)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        cjgui_internal_renderer_owner_handoff_complete(token,h,transfer,afterVersion,2,0,0)==0 &&
        ctx.caretInputBranch.origin.acceptedVersion==beforeVersion && ctx.caretInputBranch.result.acceptedVersion==afterVersion,
        "owner_handoff_B_common_publication_preserves_origin_and_advances_only_result");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,
        "owner_handoff_B_real_transfer_terminal_retired");
    if(textOnly) {
        uint64_t originalTail=ctx.installedRangeLocalTailSequence;
        [o.inputProxy insertText:@"Y" replacementRange:NSMakeRange(NSNotFound,0)];
        CHECK([o.inputProxy.string isEqualToString:b] &&
            ctx.installedRangeLocalTailSequence==originalTail && ctx.pendingInteractions.count==2 &&
            ctx.pendingInteractions.lastObject.afterCaretTextInput.origin.acceptedVersion==afterVersion,
            "owner_handoff_completed_new_text_cannot_overtake_original_held_head");
    }
    event=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&event);
    if(!textOnly)CHECK(event.kind==35 && ctx.activeCaretNavigation.inputSequence==1 &&
        ctx.activeCaretNavigation.caretInputOrigin.acceptedVersion==10 &&
        CaretFixtureBoundary(ctx,1,0)==0,
        "owner_handoff_B_relative_successor_consumes_actual_result_in_original_FIFO");
    if(!textOnly) { event=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&event); }
    CjguiInternalInstalledRangeIntent x={0};
    fprintf(stderr,"OWNER_HANDOFF_TEXT_HEAD text_only=%d event=%u active=%llu settled=%llu previous=%llu tail=%llu ack=%llu pending=%lu\n",textOnly,event.kind,(unsigned long long)ctx.activeCaretNavigation.inputSequence,(unsigned long long)ctx.caretInputBranch.settledSequence,(unsigned long long)ctx.pendingInteractions.firstObject.afterCaretTextInput.previousSequence,(unsigned long long)ctx.installedRangeLocalTailSequence,(unsigned long long)ctx.installedRangeObservedAckSequence,(unsigned long)ctx.pendingInteractions.count);
    NSString *expected=beforeSink ? @"Yabc\ndef\nX" : @"XabcZ\ndef\n";
    CHECK(event.kind==51 && [o.inputProxy.string isEqualToString:expected] &&
        cjgui_internal_renderer_claim_last_pumped_range(token,401,1,receipt.bindingEpoch,
            ctx.composableSceneVersion,&x)==0 && x.nonce==transfer && x.ownerVersion==afterVersion &&
        x.seq==((beforeSink||textOnly)?2:1) && x.previousSeq==((beforeSink||textOnly)?1:0) && x.rangeStart16==0,
        "owner_handoff_B_exact_text_once_after_real_relative_owner_boundary");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&x,1,afterVersion+1)==0,
        "owner_handoff_B_first_original_input_ACK_once");
    if(textOnly) {
        event=(CjguiInternalRendererEvent){0};CjguiInternalInstalledRangeIntent y={0};
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
            [o.inputProxy.string isEqualToString:@"XYabcZ\ndef\n"] &&
            cjgui_internal_renderer_claim_last_pumped_range(token,401,1,receipt.bindingEpoch,
                ctx.composableSceneVersion,&y)==0 && y.ownerVersion==afterVersion &&
            y.seq==3 && y.previousSeq==2 && y.rangeStart16==1 &&
            cjgui_internal_renderer_ack_installed_range(token,&y,1,afterVersion+2)==0,
            "owner_handoff_completed_old_head_and_new_character_keep_original_FIFO_once");
    }
    CHECK(ctx.pendingInteractions.count==0 && ctx.retainedAfterCaretInputBytes==0,
        "owner_handoff_B_each_original_input_once_and_capacity_released");
    cjgui_internal_renderer_destroy(token);
}

static void OwnerInputFocusResidencyFixture(id<MTLDevice> device,BOOL explicitFocus) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken,h=0;
    NSString *a=[o.inputProxy.string copy];
    if(explicitFocus) {
        CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,71,10,0,0,&h)==0,
            "owner_focus_root_begins_with_real_text_responder");
        [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
        CJGuiInternalComposableSceneNode *button=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
        raw.nodeId=402;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
        button.node=raw;button.value=@"button";button.index=1;
        [o focusNode:button enqueue:NO];
        CHECK(cjgui_internal_renderer_owner_handoff_state(token,h)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
            ctx.rejectedAfterCaretInputs.count==1 &&
            [ctx.rejectedAfterCaretInputs.firstObject.payload isEqualToString:@"X"] &&
            ctx.rejectedAfterCaretInputs.firstObject.origin.nodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
            CjguiCaptureCaretInputSnapshot(ctx)==nil && [o.inputProxy.string isEqualToString:a],
            "owner_focus_real_button_focus_retires_original_root_and_preserves_exact_suffix");
    } else {
        [o textView:o.inputProxy doCommandBySelector:@selector(deleteBackward:)];
        CjguiInternalRendererEvent event={0};cjgui_internal_renderer_pump_event(token,0,&event);
        CHECK(event.kind==35 && cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,
            ctx.activeCaretNavigation.inputSequence,ctx.activeCaretNavigation.inputPreviousSequence,10,11,4,7002)==0,
            "owner_focus_delete_has_actual_dequeued_EditApplied_receipt");
        CHECK(cjgui_internal_renderer_set_composable_owned_text_session(token,401,1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT,72,1)==0,
            "owner_focus_target_declaration_advances_without_replacing_actual_A");
        ctx.composableSceneVersion=2;[o setNodesFromProjection:@[]];
        CHECK(o.sourceInputParked && CjguiInputProxyIsFirstResponder(o) &&
            [o.inputProxy.string isEqualToString:a] &&
            ctx.activeCaretNavigation.caretEditApplied && ![o activeFocusableNode],
            "owner_focus_EditApplied_parks_real_A_when_projection_omits_text_and_target_binding_advances");
    }
    if(ctx.ownerSelectionHandoff)cjgui_internal_renderer_owner_handoff_abort(token,ctx.ownerSelectionHandoff.identity);
    cjgui_internal_renderer_cancel_caret_prefix(token,7002,ctx.ownedTextSessionBindingEpoch);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

// Focus moves from a fully settled caret branch to a real physical control
// press. Retiring that old branch must not produce a later input-failure
// notice that the window would apply to the newly admitted press.
static void SettledCaretFocusPressFixture(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    if(!o){CHECK(NO,"settled_caret_press_actual_source");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken;
    NSString *before=[o.inputProxy.string copy];
    [o textView:o.inputProxy doCommandBySelector:@selector(moveLeft:)];
    CjguiInternalRendererEvent e={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&e)==0 && e.kind==35 &&
        CaretFixtureBoundary(ctx,1,0)==0 && ctx.caretInputBranch.lastProducedSequence==1 &&
        ctx.caretInputBranch.settledSequence==1,
        "settled_caret_press_actual_navigation_and_same_receipt_complete");
    CJGuiInternalComposableSceneNode *button=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
    raw.nodeId=402;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    raw.x=420;raw.y=20;raw.width=120;raw.height=28;
    button.node=raw;button.value=@"button";button.index=1;
    [ctx.composableNodes addObject:button];o.nodes=ctx.composableNodes;
    [o beginPressForNode:button atPoint:NSMakePoint(450,30)];
    CHECK(ctx.caretInputBranch==nil && !ctx.pendingInputQueueFullNotice &&
        ctx.rejectedAfterCaretInputs.count==0 && [o.inputProxy.string isEqualToString:before],
        "settled_caret_focus_retirement_has_no_failure_and_zero_body_write");
    BOOL foundBegin=NO,lateFailure=NO;
    for(NSUInteger i=0;i<8;i++) {
        e=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&e);
        if(e.kind==45)foundBegin=YES;
        if(e.kind==11)lateFailure=YES;
        if(!e.kind)break;
    }
    CHECK(foundBegin && !lateFailure && o.pressedNodeId==402 && o.pressedSequence,
        "settled_caret_new_press_not_cancelled_by_old_branch_failure_notice");
    [o completePressAtPoint:NSMakePoint(450,30)];
    NSUInteger activations=0,terminals=0;
    for(NSUInteger i=0;i<8;i++) {
        e=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&e);
        if(e.kind==27 && e.nodeId==402)activations++;
        if(e.kind==46 && e.nodeId==402)terminals++;
        if(e.kind==11)lateFailure=YES;
        if(!e.kind)break;
    }
    CHECK(activations==1 && terminals==1 && !lateFailure &&
        [o.inputProxy.string isEqualToString:before],
        "settled_caret_same_physical_press_releases_and_activates_once");
    cjgui_internal_renderer_destroy(token);
}

// AppKit asks this before delivering the activating click to an inactive
// window. An accepted live scene must receive that original press, while a
// private or retired scene must never become an input consumer.
static void AcceptedSceneFirstMouseFixture(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    if(!o){CHECK(NO,"first_mouse_actual_source");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken;
    CJGuiInternalComposableSceneNode *button=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
    raw.nodeId=402;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    raw.x=420;raw.y=20;raw.width=120;raw.height=28;
    button.node=raw;button.value=@"button";button.index=1;
    [ctx.composableNodes addObject:button];o.nodes=ctx.composableNodes;
    NSString *body=[o.inputProxy.string copy];NSRange selection=o.inputProxy.selectedRange;
    NSEvent *down=[NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
        location:[o convertPoint:NSMakePoint(450,30) toView:nil] modifierFlags:0 timestamp:0
        windowNumber:ctx.window.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];
    BOOL admitted=[o acceptsFirstMouse:down];
    CHECK(admitted,"first_mouse_live_accepted_scene_delivers_original_activating_press");
    CHECK(ctx.pendingInteractions.count==0 && !o.pressedSequence &&
        [o.inputProxy.string isEqualToString:body] && NSEqualRanges(o.inputProxy.selectedRange,selection),
        "first_mouse_admission_does_not_synthesize_focus_selection_or_input");
    o.detachedSourcePreparation=YES;
    CHECK(![o acceptsFirstMouse:down],"first_mouse_private_preparation_refuses_input");
    o.detachedSourcePreparation=NO;
    ctx.composableSceneOverlay=nil;
    CHECK(![o acceptsFirstMouse:down],"first_mouse_replaced_scene_refuses_input");
    ctx.composableSceneOverlay=o;ctx.destroyed=YES;
    CHECK(![o acceptsFirstMouse:down],"first_mouse_destroyed_session_refuses_input");
    ctx.destroyed=NO;
    if(admitted){
        [o mouseDown:down];
        NSEvent *up=[NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:down.locationInWindow
            modifierFlags:0 timestamp:0 windowNumber:ctx.window.windowNumber context:nil
            eventNumber:2 clickCount:1 pressure:0];
        [o mouseUp:up];
    }
    NSUInteger begins=0,ends=0,activations=0;CjguiInternalRendererEvent e={0};
    for(NSUInteger i=0;i<8;i++){
        e=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&e);
        if(e.kind==45&&e.nodeId==402)begins++;
        if(e.kind==46&&e.nodeId==402)ends++;
        if(e.kind==27&&e.nodeId==402)activations++;
        if(!e.kind)break;
    }
    CHECK(begins==1&&ends==1&&activations==1&&[o.inputProxy.string isEqualToString:body],
        "first_mouse_one_original_press_has_one_lease_terminal_and_activation_zero_body_write");
    cjgui_internal_renderer_destroy(token);
}


// A real installed B can arrive before managed confirms this same history
// prefix. A successor captures its actual B, waits in the original FIFO and
// cannot reinterpret an earlier admitted character at B's coordinates.
static void CaretInstalledHistorySuccessorFixture(id<MTLDevice> device,BOOL redo,BOOL newSelection,BOOL physical,BOOL beforeInstall) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"first\nsecond\n",71,910,7002);
    if(!o){CHECK(NO,"history_installed_successor_actual_A_created");return;}
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken;
    [o textView:o.inputProxy doCommandBySelector:@selector(undo:)];
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34 &&
        cjgui_internal_renderer_mark_caret_edit_applied(token,ctx.sessionGeneration,1,0,10,11,4,7002)==0,
        "history_installed_successor_first_owner_receipt_recorded");
    CJGuiInternalQueuedInteraction *first=ctx.activeCaretNavigation;
    CjguiCaretInputSnapshot *original=first.caretInputBranch.origin;
    NSString *b=@"firs\nsecond\n";
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
    raw.projectionVersion=2;node.node=raw;node.value=b;node.styleRunsSignature=@"";
    node.preparedTextLayout=CjguiPrepareTextNodeLayout(node,b,1.0,nil,ctx);
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=2;ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=2;
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,"history_installed_successor_actual_B_scene_committed");
    [o setNodesFromProjection:ctx.view.composableNodes];
    if(physical) {
        // Match the ordinary consumer's declared command route through the
        // actual native menu projection, rather than its undeclared fallback.
        CHECK(cjgui_internal_renderer_configure_composable_command_menu(token,2,2)==0 &&
            cjgui_internal_renderer_set_composable_command_menu_item(token,0,"fixture.undo","Undo","Edit",
                "shortcut:command+z",0,0,1,0)==0 &&
            cjgui_internal_renderer_set_composable_command_menu_item(token,1,"fixture.redo","Redo","Edit",
                "shortcut:shift+command+z",0,0,1,0)==0 &&
            cjgui_internal_renderer_commit_composable_command_menu(token)==0,
            "history_installed_successor_real_declared_command_projection");
    }
    uint64_t transfer=0;cjgui_internal_renderer_selection_transfer_create(token,&transfer);
    NSData *bytes=[b dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=7002;c.sourceOwnerVersion=11;
    c.sourceContextEpoch=4;c.sourceMirrorRevision=3;c.targetNodeId=401;c.targetResourceId=1;
    c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    c.targetSceneVersion=2;c.targetProjectionVersion=2;c.targetAnchor16=4;c.targetFocus16=4;
    c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0};CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&c,source,sizeof(source))==0 &&
        cjgui_internal_renderer_bind_caret_selection_transfer(token,transfer,ctx.sessionGeneration,1,0)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "history_installed_successor_same_prefix_actual_pending_B");
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand | (redo ? NSEventModifierFlagShift : 0)
        timestamp:0 windowNumber:ctx.window.windowNumber context:nil
        characters:@"z" charactersIgnoringModifiers:@"z" isARepeat:NO keyCode:6];
    if(beforeInstall)[o performKeyEquivalent:key];
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)==0 &&
        receipt.transferId==transfer && receipt.firstResponder,
        "history_installed_successor_same_prefix_real_B_receipt_installed");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,transfer)==0 &&
        first.caretInputBranch.result.acceptedVersion==10 && first.caretInputBranch.settledSequence==0,
        "history_installed_successor_receipt_survives_capsule_retirement_without_early_ACK");
    if(newSelection)[o.inputProxy setSelectedRange:NSMakeRange(1,0)];
    if(!beforeInstall) {
        if(physical)[o performKeyEquivalent:key];
        else [o textView:o.inputProxy doCommandBySelector:redo ? @selector(redo:) : @selector(undo:)];
    }
    if(newSelection) {
        BOOL oldPrefixQueued=NO;
        for(CJGuiInternalQueuedInteraction *queued in ctx.pendingInteractions)
            if(queued.caretInputBranch==first.caretInputBranch ||
                queued.afterCaretTextInput.branch==first.caretInputBranch)oldPrefixQueued=YES;
        CHECK(!first.caretInputBranch.valid && !oldPrefixQueued &&
            cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,1,0,1,transfer,
                receipt.proxyGeneration,receipt.selectionRevision,11,4,7002)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
            [o.inputProxy.string isEqualToString:b],
            "history_installed_successor_new_selection_refuses_old_receipt_zero_write");
    } else {
        CJGuiInternalQueuedInteraction *next=ctx.pendingInteractions.firstObject;
        CHECK(CjguiInteractionIsTextHistory(next) && next.inputSequence==2 && next.inputPreviousSequence==1 &&
            next.caretInputBranch==first.caretInputBranch &&
            next.caretInputOrigin.candidate.nonce==(beforeInstall ? original.candidate.nonce : transfer) &&
            next.caretInputOrigin.acceptedVersion==(beforeInstall ? 10 : 11) &&
            (beforeInstall ? [next.caretInputOrigin.body isEqualToData:original.body] : next.caretInputOrigin.proxy==o.inputProxy) &&
            NSEqualRanges(next.caretInputOrigin.selection,beforeInstall ? original.selection : NSMakeRange(4,0)) &&
            first.caretInputBranch.origin==original && first.caretInputBranch.result.acceptedVersion==10 &&
            [o.inputProxy.string isEqualToString:b],
            redo ? "redo_installed_successor_retains_actual_B_and_original_FIFO_without_proxy_write" :
                   "undo_installed_successor_retains_actual_B_and_original_FIFO_without_proxy_write");
        event=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&event);
        CHECK(event.kind==0 && ctx.activeCaretNavigation==first,
            "history_installed_successor_waits_for_common_receipt_ACK");
        CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,1,0,1,transfer,
            receipt.proxyGeneration,receipt.selectionRevision,11,4,7002)==0,
            "history_installed_successor_first_receipt_ACK_advances_result_once");
        event=(CjguiInternalRendererEvent){0};cjgui_internal_renderer_pump_event(token,0,&event);
        CHECK(event.kind==next.kind && CjguiInteractionIsTextHistory(ctx.activeCaretNavigation) && ctx.activeCaretNavigation==next &&
            next.caretInputOrigin.acceptedVersion==(beforeInstall ? 10 : 11) && next.caretInputBranch.origin==original &&
            next.caretInputBranch.settledSequence==1 && ctx.pendingInteractions.count==0 &&
            [o.inputProxy.string isEqualToString:b],
            "history_installed_successor_dequeues_once_after_exact_predecessor_receipt");
    }
    cjgui_internal_renderer_cancel_caret_prefix(token,7002,ctx.ownedTextSessionBindingEpoch);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

static void PresentationSelectAllSourceFixture(id<MTLDevice> device, BOOL parked, BOOL changedBinding) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixture(device,@"abc\ndef\n",71,910,7002);
    CHECK(o!=nil,"presentation_select_all_real_installed_text_fixture");if(!o)return;
    CJGuiInternalSession *ctx=o.session;uint64_t token=ctx.rendererSessionToken,h=0;
    // Presentation TEXT becomes an input owner through the real transfer
    // installer, not the ordinary editable-field focus/arm entry.
    CJGuiInternalComposableSceneNode *target=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode data=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
    data.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;data.projectionVersion=2;
    target.node=data;target.value=@"abc\ndef\n";target.styleRunsSignature=@"";
    target.preparedTextLayout=CjguiPrepareTextNodeLayout(target,target.value,1.0,nil,ctx);
    cjgui_internal_renderer_set_source_install_gate(token,71,401,1);
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:target];ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];ctx.stagedComposableDataTransferVersion=2;
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,"presentation_select_all_real_TEXT_scene");
    [o setNodesFromProjection:ctx.view.composableNodes];
    uint64_t installed=0;CjguiInternalSelectionTransferCandidate candidate={0};
    NSData *body=[target.value dataUsingEncoding:NSUTF8StringEncoding];
    candidate.sourceWindowInstanceToken=7002;candidate.sourceOwnerVersion=10;
    candidate.sourceContextEpoch=4;candidate.sourceMirrorRevision=2;
    candidate.targetNodeId=401;candidate.targetResourceId=1;
    candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion=2;candidate.targetProjectionVersion=2;
    candidate.targetBodyUtf8=body.bytes;candidate.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t captured[65536]={0};CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&installed)==0,
        "presentation_select_all_real_TEXT_transfer_created");candidate.transferId=installed;
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&candidate,captured,sizeof(captured))==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,installed)==0 &&
        cjgui_internal_renderer_selection_transfer_install_b(token,installed,&receipt)==0 && receipt.firstResponder &&
        cjgui_internal_renderer_selection_transfer_discard_capsule(token,installed)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,installed)==0,
        "presentation_select_all_real_TEXT_installed_receipt");
    cjgui_internal_renderer_set_source_install_gate(token,ctx.ownedTextSessionBindingEpoch,401,0);
    [ctx.pendingInteractions removeAllObjects];
    NSString *before=[o.inputProxy.string copy];NSRange choice=o.inputProxy.selectedRange;
    if(parked) {
        CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"fixture",1,7002,4,ctx.ownedTextSessionBindingEpoch,10,0,0,&h)==0 &&
            cjgui_internal_renderer_owner_handoff_seal(token,h,11,2,0,0,99)==0,
            "presentation_select_all_actual_pending_owner_handoff");
        CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw=((CJGuiInternalComposableSceneNode *)o.nodes.firstObject).node;
        raw.projectionVersion=3;node.node=raw;node.value=@"abcZ\ndef\n";node.styleRunsSignature=@"";
        ctx.composableSceneVersion=3;[o setNodesFromProjection:@[node]];
        CHECK(o.sourceInputParked && ![o activeFocusableNode],
            "presentation_select_all_original_installed_responder_outlives_accepted_node");
    }
    if(changedBinding)ctx.ownedTextSessionBindingEpoch+=1;
    [o.inputHost selectAll:nil];
    CJGuiInternalQueuedInteraction *q=ctx.pendingInteractions.lastObject;
    if(changedBinding) {
        CHECK(!q && !ctx.installedWholeChoiceNonce && [o.inputProxy.string isEqualToString:before],
            "presentation_select_all_changed_binding_cannot_reuse_old_receipt");
    } else {
        CHECK(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            [q.formText isEqualToString:@"select_all"] && q.inputSequence==1 && q.inputPreviousSequence==0 &&
            q.caretInputOrigin.acceptedVersion==10 && q.caretInputOrigin.candidate.nonce==installed &&
            (!parked || q.ownerHandoff.identity==h),
            "presentation_select_all_actual_source_intent_enters_existing_FIFO_once");
        CHECK(!ctx.installedWholeChoiceNonce && NSEqualRanges(o.inputProxy.selectedRange,choice) &&
            [o.inputProxy.string isEqualToString:before],
            "presentation_select_all_does_not_select_or_edit_local_proxy_instead_of_owner");
    }
    if(h)cjgui_internal_renderer_owner_handoff_abort(token,h);
    CaretRecoveryExplicitDispose(ctx);cjgui_internal_renderer_destroy(token);
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(!device)return 1;
    PresentationSelectAllSourceFixture(device,NO,NO);
    PresentationSelectAllSourceFixture(device,YES,NO);
    PresentationSelectAllSourceFixture(device,YES,YES);
    OwnerHandoffProducerFixture(device);
    OwnerHandoffParkedSelectorFixture(device,0);
    OwnerHandoffParkedSelectorFixture(device,1);
    OwnerHandoffParkedSelectorFixture(device,2);
    OwnerHandoffRangeAckProducerFixture(device,0,NO);
    OwnerHandoffRangeAckProducerFixture(device,1,NO);
    OwnerHandoffRangeAckProducerFixture(device,2,NO);
    OwnerHandoffRangeAckProducerFixture(device,0,YES);
    OwnerHandoffRangeAckProducerFixture(device,1,YES);
    OwnerHandoffRangeAckProducerFixture(device,2,YES);
    OwnerHandoffActualBFixture(device,NO,NO);
    OwnerHandoffActualBFixture(device,NO,YES);
    OwnerHandoffActualBFixture(device,YES,NO);
    OwnerInputFocusResidencyFixture(device,NO);
    OwnerInputFocusResidencyFixture(device,YES);
    SettledCaretFocusPressFixture(device);
    AcceptedSceneFirstMouseFixture(device);
    CaretEditProjectionOwnerFixture(device,NO,NO);
    CaretEditProjectionOwnerFixture(device,YES,NO);
    CaretEditProjectionOwnerFixture(device,NO,YES);
    CaretEditProjectionOwnerFixture(device,YES,YES);
    CaretHistoryReceiptFixture(device,NO);
    CaretHistoryReceiptFixture(device,YES);
    CaretInstalledHistorySuccessorFixture(device,NO,NO,NO,NO);
    CaretInstalledHistorySuccessorFixture(device,YES,NO,NO,NO);
    CaretInstalledHistorySuccessorFixture(device,NO,YES,NO,NO);
    CaretInstalledHistorySuccessorFixture(device,NO,NO,YES,NO);
    CaretInstalledHistorySuccessorFixture(device,YES,NO,YES,YES);
    EmptySourceCaretFixture(device);
    CaretEditParkedSelectorFixture(device,NO);
    CaretEditParkedSelectorFixture(device,YES);
    CaretEditParkedSelectorFixture(device,2);
    CaretEditParkedSelectorFixture(device,3);
    CaretRelativeDeleteProducerFixture(device);
    CaretAfterInputBeforeOwnerFixture(device);
    CaretAfterInputPrefixFixture(device);
    CaretAfterPendingSelectionFixture(device,YES,YES);
    CaretAfterPendingSelectionFixture(device,YES,NO);
    CaretAfterPendingSelectionFixture(device,NO,NO);
    CaretAfterPendingDeleteKeyFixture(device,YES);
    CaretAfterPendingDeleteKeyFixture(device,NO);
    CaretAfterSceneAdvanceInstallFixture(device,NO);
    CaretAfterSceneAdvanceInstallFixture(device,YES);
    CaretAfterSceneRebaseFixture(device,NO);
    CaretAfterSceneRebaseFixture(device,YES);
    for(NSUInteger mode=0;mode<4;mode++)CaretAfterInputRejectFixture(device,mode);
    CaretAfterAcceptedSceneFixture(device,NO);
    CaretAfterAcceptedSceneFixture(device,YES);
    CaretAfterUnclaimedRecoveryCloseFixture(device);
    fprintf(stderr,"caret_after_input failures=%d\n",failures);
    return failures?1:0;
} }
