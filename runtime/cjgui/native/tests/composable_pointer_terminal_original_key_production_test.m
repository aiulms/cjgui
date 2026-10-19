// The real pointer producer has ended capture, while its common final choice
// has not installed yet. The original Window key must not edit BEGIN's caret.
#define CJGUI_ORIGINAL_KEY_CUSTODY_NO_MAIN 1
#import "composable_command_original_key_custody_production_test.m"

#ifdef CJGUI_INTERNAL_POINTER_END_ORIGINAL_KEY_CUSTODY
static uint64_t FreezeActualPointer(CJGuiInternalSession *ctx,int64_t revision,int64_t anchor,int64_t focus) {
    CJGuiInternalQueuedInteraction *q=ctx.pumpedPointerInteraction;
    CjguiInternalPointerSelectionOrigin origin={.generation=q.pointerStreamSessionGeneration,
        .gesture=q.pointerStreamBindingEpoch,.first=q.pointerStreamFirstSequence,.last=q.pointerStreamLastSequence,
        .previous=q.pointerStreamPreviousSequence,.coordinate=q.coordinateEpoch,.scene=q.projectionVersion,
        .nodeId=q.nodeId,.resourceId=q.resourceId,.nodeKind=q.nodeKind,.phase=q.pointerStreamPhase};
    uint64_t identity=0;int status=cjgui_internal_renderer_freeze_pointer_selection_dispatch(ctx.rendererSessionToken,
        &origin,10,revision,anchor,focus,&identity);
    fprintf(stderr,"pointer_actual_dispatch_frozen phase=%u sequence=%llu:%llu status=%d identity=%llu\n",
        origin.phase,(unsigned long long)origin.first,(unsigned long long)origin.last,status,(unsigned long long)identity);
    CHECK(status==0 && identity,"pointer_raw_dispatch_frozen_from_actual_dequeued_FIFO_not_local_sequence");
    return identity;
}
static CjguiInternalSelectionTransferReceipt lastActualPointerReceipt;
static BOOL InstallActualPointerB(CJGuiInternalSession *ctx,uint64_t identity,uint32_t anchor,uint32_t focus,
    int64_t revision,uint8_t coversEnd) {
    uint64_t token=ctx.rendererSessionToken,transfer=0;
    int created=cjgui_internal_renderer_selection_transfer_create(token,&transfer);
    CjguiInternalSelectionTransferCandidate c=CaptureCandidateForTarget(ctx,transfer,1,0,
        [@"FGHIJ" dataUsingEncoding:NSUTF8StringEncoding]);
    c.targetAnchor16=anchor;c.targetFocus16=focus;uint8_t bytes[65536]={0};
    int captured=created==0 ? cjgui_internal_renderer_selection_transfer_capture_current(token,&c,bytes,sizeof(bytes)) : -1;
    int bound=captured==0 ? cjgui_internal_renderer_bind_pointer_selection_dispatch(token,identity,transfer) : -1;
    int published=bound==0 ? cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer) : -1;
    CjguiInternalSelectionTransferReceipt r={0};uint8_t retired=0;
    if(published==0) {
        for(CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
            if(q.originalCommandKey && !q.originalCommandKey.completedB)
                CHECK(CjguiOriginalKeyWaitsForB(ctx,q,ctx.selectionTransferCapsule),
                    "pointer_actual_predecessor_and_raw_share_the_same_Present_Finalizing_proof");
    }
    int installed=published==0 ? cjgui_internal_renderer_selection_transfer_install_b_retiring(token,transfer,&r,&retired) : -1;
    if(installed==0)lastActualPointerReceipt=r;
    int completed=installed==0 ? cjgui_internal_renderer_complete_pointer_selection_dispatch(token,identity,
        ctx.sessionGeneration,c.sourceWindowInstanceToken,c.sourceContextEpoch,&r,10,revision,anchor,focus,coversEnd) : -1;
    fprintf(stderr,"pointer_actual_B_first_status create=%d capture=%d bind=%d publish=%d install=%d completion=%d transfer=%llu retired=%u\n",
        created,captured,bound,published,installed,completed,(unsigned long long)transfer,retired);
    CHECK(created==0 && captured==0 && bound==0 && published==0 && installed==0 && completed==0,
        "pointer_original_raw_successor_allows_its_original_predecessor_actual_B");
    if(installed==0) {
        uint8_t needs=0;
        CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,transfer,ctx.sessionGeneration,
            r.bindingEpoch,r.proxyGeneration,r.selectionRevision,10,revision,1,&needs)==0,
            "pointer_raw_actual_owner_metadata_and_paint_are_separate");
        if(!retired)(void)cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer);
        CHECK(cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,
            "pointer_raw_actual_transfer_owner_descriptor_released");
    }
    return completed==0;
}
#endif

static void DestroyAfterActualPointerOwnerSettlement(CJGuiInternalSession *ctx) {
    uint64_t token=ctx.rendererSessionToken;
    int status=cjgui_internal_renderer_destroy(token);
    fprintf(stderr,"pointer_normal_destroy_first_leaf status=%d retained=%llu terminal_completed=%d tail=%llu ack=%llu queue=%lu\n",
        status,(unsigned long long)ctx.retainedAfterCaretInputBytes,ctx.pointerTerminalCustody.completed,
        (unsigned long long)ctx.installedRangeLocalTailSequence,(unsigned long long)ctx.installedRangeObservedAckSequence,
        (unsigned long)ctx.pendingInteractions.count);
    CHECK(status==0,"pointer_completed_metadata_cannot_hold_normal_destroy_after_all_originals_and_real_ACKs");
    if(status!=0)CjguiReleaseSession(token); // Only failed fixture cleanup; never the success oracle.
}

static void PointerEndBeforeOriginalKey(id<MTLDevice> device,BOOL covered) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&receipt);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken;
    CHECK(InstallSelectionOnSameAcceptedScene(ctx,2,2),"pointer_raw_BEGIN_actual_caret_B_installed");
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,10,2,1,&needs)==0,
        "pointer_raw_BEGIN_actual_caret_owner_published");
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *node=o.nodes[1];
    CHECK([o beginPointerCaptureForNode:node atPoint:NSMakePoint(20,150)],"pointer_raw_real_BEGIN_producer");
    CjguiInternalRendererEvent begin={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&begin)==0 && begin.kind==37,
        "pointer_raw_original_BEGIN_consumed_before_final_choice");
    uint64_t gesture=o.pointerCaptureGestureEpoch;
    CHECK(CjguiEnqueueComposableCapturedPointerInteraction(ctx,38,node,NSMakePoint(30,150),gesture) &&
        CjguiEnqueueComposableCapturedPointerInteraction(ctx,38,node,NSMakePoint(40,150),gesture),
        "pointer_raw_real_adjacent_MOVE_coalesces_in_existing_FIFO");
    [o endPointerCaptureAtPoint:NSMakePoint(40,150) cancelled:NO];
    CHECK(!o.pointerCaptureActive && ctx.pendingInteractions.lastObject.kind==39 &&
        ctx.pendingInteractions.firstObject.pointerStreamFirstSequence==2 &&
        ctx.pendingInteractions.firstObject.pointerStreamLastSequence==3,
        "pointer_raw_real_END_queued_and_capture_already_stopped");
    NSEvent *original=OriginalCommandKey(ctx,@"X",7);
    [ctx.window sendEvent:original];
    CHECK(ctx.pendingInteractions.lastObject.originalCommandKey.event==original &&
        [o.inputProxy.string isEqualToString:@"FGHIJ"] &&
        ctx.installedRangeLocalTailSequence==ctx.installedRangeObservedAckSequence,
        "pointer_original_X_retained_before_first_system_interpretation_until_actual_END_B");

#ifdef CJGUI_INTERNAL_POINTER_END_ORIGINAL_KEY_CUSTODY
    CjguiOriginalCommandKey *held=ctx.pendingInteractions.lastObject.originalCommandKey;
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==38,
        "pointer_raw_original_merged_UPDATE_is_consumed_before_END");
    uint64_t update=FreezeActualPointer(ctx,2,2,2);
    if(!InstallActualPointerB(ctx,update,2,covered ? 4 : 3,3,0)) {CjguiReleaseSession(token);return;}
    CHECK(held.phase==0 && !held.completedB && [o.inputProxy.string isEqualToString:@"FGHIJ"],
        "pointer_intermediate_UPDATE_B_cannot_release_original_after_END_key");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==39 && !o.pointerCaptureActive,
        "pointer_raw_actual_END_consumed_after_capture_clear");
    uint64_t end=FreezeActualPointer(ctx,3,2,covered ? 4 : 3);
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0 &&
        held.phase==0 && [o.inputProxy.string isEqualToString:@"FGHIJ"],
        "pointer_actual_END_consumption_alone_does_not_interpret_before_its_final_completion");
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"Y",16)];
    if(covered) {
        CjguiInstalledRangeState *actual=ctx.installedRangeBasis;
        CHECK(cjgui_internal_renderer_complete_pointer_selection_dispatch(token,end,ctx.sessionGeneration,
            actual.candidate.windowInstanceToken,actual.candidate.contextEpoch,&lastActualPointerReceipt,
            10,3,2,4,2)==0,
            "pointer_original_END_explicit_no_change_result_covers_actual_last_UPDATE_B");
    } else if(!InstallActualPointerB(ctx,end,2,4,4,1)) {CjguiReleaseSession(token);return;}
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;CjguiInternalInstalledRangeIntent intent={0};
    uint64_t completedCharge=ctx.retainedAfterCaretInputBytes;
    CHECK(cjgui_internal_renderer_destroy(token)==CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED &&
        ctx.pointerTerminalCustody==held.pointerTerminal && ctx.retainedAfterCaretInputBytes==completedCharge &&
        held.phase==0 && [o.inputProxy.string isEqualToString:@"FGHIJ"],
        "pointer_destroy_keeps_completed_B_raw_originals_and_their_root_unchanged");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 && held.phase==2 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,402,1,b.candidate.bindingEpoch,
            ctx.composableSceneVersion,&intent)==0 && intent.rangeStart16==2 && intent.rangeLength16==2 &&
        [o.inputProxy.string isEqualToString:@"FGXJ"],
        "pointer_original_X_first_system_interpretation_replaces_final_END_range_once");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0 &&
        [o.inputProxy.string isEqualToString:@"FGXJ"] &&
        cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0,
        "pointer_second_original_cannot_pass_first_real_range_ACK");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        [o.inputProxy.string isEqualToString:@"FGXYJ"],
        "pointer_original_X_Y_follow_same_actual_B_and_real_ACK_FIFO");
    CHECK(cjgui_internal_renderer_destroy(token)==CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED &&
        ctx.pointerTerminalCustody==held.pointerTerminal,
        "pointer_destroy_keeps_the_original_root_while_real_produced_range_is_not_yet_claimed");
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,402,1,b.candidate.bindingEpoch,
        ctx.composableSceneVersion,&intent)==0 && intent.rangeStart16==3,
        "pointer_last_real_range_claim_remains_available_after_refused_destroy");
    CHECK(cjgui_internal_renderer_destroy(token)==CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED &&
        ctx.pointerTerminalCustody==held.pointerTerminal,
        "pointer_destroy_still_waits_for_the_genuine_owner_range_ACK");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&intent,1,12)==0,
        "pointer_last_original_actual_owner_ACK_settles_before_destroy");
#endif
    DestroyAfterActualPointerOwnerSettlement(ctx);
    CHECK(ctx.retainedAfterCaretInputBytes==0,"pointer_original_custody_close_releases_all_owned_charges");
}

static void PointerWindowDownBeforeResponderTransition(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt r={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&r);if(!ctx)return;
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    CjguiCaretInputSnapshot *before=CjguiCaptureCaretInputSnapshot(ctx);
    CHECK(before && CjguiInputProxyIsFirstResponder(o),"pointer_window_original_source_is_actual_before_DOWN");
    NSPoint down=[o convertPoint:NSMakePoint(20,150) toView:nil];
    NSEvent *event=[NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:down modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber
        context:nil eventNumber:1 clickCount:1 pressure:1];
    [ctx.window sendEvent:event];
    CHECK(o.pointerCaptureActive && !CjguiInputProxyIsFirstResponder(o),
        "pointer_real_Window_DOWN_moves_responder_before_common_BEGIN");
    NSPoint up=[o convertPoint:NSMakePoint(40,150) toView:nil];
    event=[NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:up modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber
        context:nil eventNumber:1 clickCount:1 pressure:0];
    [ctx.window sendEvent:event];
    NSEvent *x=OriginalCommandKey(ctx,@"X",7);[ctx.window sendEvent:x];
    CHECK(!o.pointerCaptureActive && ctx.pointerTerminalCustody.originalA &&
        CjguiOriginalCommandSnapshotsEqual(before,ctx.pointerTerminalCustody.originalA) &&
        ctx.pendingInteractions.lastObject.originalCommandKey.event==x &&
        [o.inputProxy.string isEqualToString:@"FGHIJ"],
        "pointer_actual_DOWN_source_survives_platform_focus_transition_and_END_without_priming_BEGIN");
#ifdef CJGUI_INTERNAL_POINTER_END_ORIGINAL_KEY_CUSTODY
    CjguiInternalRendererEvent consumed={0};uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_pump_event(token,0,&consumed)==0 && consumed.kind==37,
        "pointer_real_Window_BEGIN_is_actual_common_predecessor_before_original_X");
    uint64_t begin=FreezeActualPointer(ctx,1,1,4);
    if(begin && InstallActualPointerB(ctx,begin,2,2,2,0)) {
        CHECK(cjgui_internal_renderer_pump_event(token,0,&consumed)==0 && consumed.kind==39,
            "pointer_real_Window_END_remains_after_actual_BEGIN_install");
        uint64_t end=FreezeActualPointer(ctx,2,2,2);
        if(end && InstallActualPointerB(ctx,end,2,4,3,1)) {
            CjguiInstalledRangeState *b=ctx.installedRangeBasis;CjguiInternalInstalledRangeIntent input={0};
            CHECK(cjgui_internal_renderer_pump_event(token,0,&consumed)==0 && consumed.kind==51 &&
                cjgui_internal_renderer_claim_last_pumped_range(token,402,1,b.candidate.bindingEpoch,
                    ctx.composableSceneVersion,&input)==0 && input.rangeStart16==2 && input.rangeLength16==2 &&
                [o.inputProxy.string isEqualToString:@"FGXJ"] &&
                cjgui_internal_renderer_ack_installed_range(token,&input,1,11)==0,
                "pointer_real_Window_original_X_waits_BEGIN_and_final_END_actual_B_once");
        }
    }
#endif
    DestroyAfterActualPointerOwnerSettlement(ctx);
    CHECK(ctx.retainedAfterCaretInputBytes==0,"pointer_pre_focus_root_close_releases_all_owned_charges");
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    CHECK(device!=nil,"pointer_raw_real_Metal_device");
    if(device) {PointerEndBeforeOriginalKey(device,NO);PointerEndBeforeOriginalKey(device,YES);PointerWindowDownBeforeResponderTransition(device);}
    return failures ? 1 : 0;
} }
