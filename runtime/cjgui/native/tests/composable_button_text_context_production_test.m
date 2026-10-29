// Actual DOWN changes responder; only the declared activated command can
// carry its genuine pre-focus text source into the real selection transfer.
#define main existingButtonContextSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

#ifndef CJGUI_INTERNAL_COMMAND_TEXT_CONTEXT_ABI
static CjguiInternalRendererStatus cjgui_internal_renderer_admit_command_text_context(
    uint64_t session,uint64_t serial,uint64_t token,uint64_t sequence,uint64_t node,
    int64_t resource,uint32_t kind,uint64_t binding,int64_t owner,uint64_t handoff) {
    (void)session;(void)serial;(void)token;(void)sequence;(void)node;(void)resource;
    (void)kind;(void)binding;(void)owner;(void)handoff;return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
}
#endif

static BOOL InstallButtonContextA(CJGuiInternalSession *ctx,CjguiInternalSelectionTransferReceipt *outReceipt) {
    uint64_t transfer=0,token=ctx.rendererSessionToken;
    if(cjgui_internal_renderer_selection_transfer_create(token,&transfer)!=0)return NO;
    NSData *body=[ctx.composableSceneOverlay.nodes[1].value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c=CaptureCandidateForTarget(ctx,transfer,1,0,body);
    c.targetAnchor16=1;c.targetFocus16=4;uint8_t actual[65536]={0};
    CjguiInternalSelectionTransferReceipt receipt={0};
    CjguiInternalRendererStatus status=cjgui_internal_renderer_selection_transfer_capture_current(token,&c,actual,sizeof(actual));
    if(status==0)status=cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer);
    if(status==0)status=cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt);
    if(status==0 && outReceipt)*outReceipt=receipt;
    (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token,transfer);
    return status==0;
}

static CJGuiInternalSession *ButtonFixture(id<MTLDevice> device,BOOL declared,
    CjguiInternalSelectionTransferReceipt *outReceipt) {
    CJGuiInternalSession *ctx=ProductionFixture(device);if (!ctx) return nil;
    CJGuiInternalComposableSceneNode *button=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw=ctx.composableNodes[2].node;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    button.node=raw;button.index=2;button.value=@"Mode";
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];ctx.stagedComposableNodes[2]=button;
    CHECK(CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken)==0,"button_context_actual_button_scene");
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    CHECK(InstallButtonContextA(ctx,outReceipt),"button_context_actual_A_installed");
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
        a.selectionTransferId,ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,
        a.selectionRevision,10,1,1,&needs)==0,"button_context_original_completion_published");
    CHECK(CjguiConfigureComposableCommandMenuOnMain(ctx.rendererSessionToken,1,declared?1:0)==0,
        "button_context_command_table_staged");
    if (declared) {
        CHECK(CjguiSetComposableCommandMenuItemOnMain(ctx.rendererSessionToken,0,"mode","Mode","","",0,0,1,0,0)==0 &&
            cjgui_internal_renderer_set_composable_command_identity(ctx.rendererSessionToken,0,9001,
                403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON)==0,"button_context_mode_identity_declared");
    }
    CHECK(CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,"button_context_command_table_published");
    [ctx.pendingInteractions removeAllObjects];return ctx;
}

static BOOL useActualAccessibilityPress;
static uint64_t ButtonActualCommandSequence(CJGuiInternalSession *ctx,CjguiInternalRendererEvent event) {
    return useActualAccessibilityPress ? ctx.pumpedCommandInteraction.activationPrefix.nonce : event.bindingEpoch;
}
static CjguiInternalRendererEvent ActualButtonPress(CJGuiInternalSession *ctx,BOOL cancel) {
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    if(useActualAccessibilityPress) {
        uint64_t pointerBefore=ctx.nextPointerGestureEpoch,actionBefore=ctx.nextActivationPairNonce;
        CHECK([o accessibilityPerformPressForNode:o.nodes[2]],"button_context_real_AXPress_action_queued");
        CHECK(ctx.pendingInteractions.count==2 &&
            ctx.pendingInteractions[0].kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS &&
            ctx.pendingInteractions[1].kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE &&
            ctx.pendingInteractions[1].activationPrefix.nonce &&
            ctx.pendingInteractions[1].activationPrefix.memberCount==2,
            "button_context_AXPress_uses_actual_FOCUS_ACTIVATE_pair_without_fabricated_pointer_edges");
        CHECK(ctx.nextPointerGestureEpoch==pointerBefore && ctx.nextActivationPairNonce==actionBefore+1,
            "button_context_AXPress_authority_uses_real_activation_nonce_not_pointer_gesture_counter");
        CHECK(ctx.pendingInteractions[1].bindingEpoch==0,
            "button_context_AXPress_terminal_never_masquerades_as_physical_press_sequence");
    } else {
        [o beginPressForNode:o.nodes[2] atPoint:NSMakePoint(20,280)];
        CHECK(o.activeNodeId==403 && o.activeNodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON &&
            ctx.window.firstResponder==o && !CjguiInputProxyIsFirstResponder(o),
            "button_context_real_DOWN_gives_button_actual_focus");
        if (cancel) [o cancelPressAtPoint:NSMakePoint(20,480)];
        [o completePressAtPoint:cancel?NSMakePoint(20,480):NSMakePoint(20,280)];
    }
    CjguiInternalRendererEvent event={0};
    for (NSUInteger n=0;n<8 && ctx.pendingInteractions.count;n++) {
        CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event)==0,
            "button_context_actual_press_FIFO_dispatch");
        if (event.kind==27) return event;
    }
    return (CjguiInternalRendererEvent){0};
}

static void ValidButtonContext(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);if(!ctx)return;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    CjguiInternalRendererEvent activate=ActualButtonPress(ctx,NO);
    CHECK(activate.kind==27 && ButtonActualCommandSequence(ctx,activate),"button_context_actual_activation_once");
    CjguiInternalCommandSource source={0};
    CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 &&
        source.isValid && source.originEventKind==27 && source.focusedNodeId==402 &&
        source.targetNodeId==403 && source.declarationToken==9001,
        "button_context_origin_is_real_pre_DOWN_text_focus");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(ctx.rendererSessionToken,&transfer)==0,
        "button_context_one_real_transfer_created");
    CHECK(receipt.transferId==a.selectionTransferId && receipt.firstResponder && receipt.sceneVersion==1,
        "button_context_original_receipt_retained");
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferVersion=2;ctx.stagedComposableCommandMenuVersion=2;
    CHECK([ctx.stagedComposableNodes[1].value isEqualToString:@"FGHIJ"],
        "button_context_candidate_keeps_original_staged_B_body");
    CHECK(cjgui_internal_renderer_stage_window_background(ctx.rendererSessionToken,2,0,1)==0,
        "button_context_candidate_background_prepared");
    NSData *body=[ctx.composableSceneOverlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};c.transferId=transfer;
    c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;c.sourceOwnerVersion=10;
    c.sourceContextEpoch=a.candidate.contextEpoch;c.sourceMirrorRevision=a.candidate.mirrorRevision;
    c.targetNodeId=402;c.targetResourceId=1;c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    c.targetSceneVersion=2;c.targetAnchor16=1;c.targetFocus16=4;
    c.targetBodyUtf8=body.bytes;c.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t actual[65536]={0};
    CHECK(cjgui_internal_renderer_capture_candidate_selection(ctx.rendererSessionToken,&c,&receipt,
        actual,sizeof(actual),a.candidate.contextEpoch,3,1,0)==33,
        "button_context_old_receipt_alone_does_not_authorize_button_focus");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial+1,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)!=0,"button_context_wrong_serial_rejected_without_consuming_origin");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken+1,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)!=0,"button_context_wrong_token_rejected_without_consuming_origin");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate)+1,403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)!=0,"button_context_wrong_sequence_rejected_without_consuming_origin");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,UINT64_C(0xBAD))!=0,
        "button_context_unrelated_handoff_rejected_without_consuming_origin");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)==0,"button_context_valid_activation_admits_exact_origin_once");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)!=0,"button_context_duplicate_admit_is_one_shot");
    CHECK(cjgui_internal_renderer_capture_candidate_selection(ctx.rendererSessionToken,&c,&receipt,
        actual,sizeof(actual),a.candidate.contextEpoch,3,1,0)==0 &&
        ctx.selectionTransferCapsule.aNodeId==402 && ctx.composableSceneOverlay.activeNodeId==403 &&
        ctx.window.firstResponder==ctx.composableSceneOverlay,
        "button_context_B_prepare_uses_original_source_while_button_remains_focused");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(ctx.rendererSessionToken,transfer)==0 &&
        cjgui_internal_renderer_prepare_candidate_selection(ctx.rendererSessionToken,transfer,0,&ready)==0 && ready,
        "button_context_real_B_prepared_before_install");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==transfer && CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay) &&
        ctx.composableSceneOverlay.activeNodeId==402 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
        "button_context_actual_B_install_returns_text_focus_without_body_transaction");
    CHECK(ctx.commandTextContext==nil,
        "button_context_terminal_B_retires_one_shot_command_text_authority");
    CHECK(receipt.transferId==a.selectionTransferId && receipt.sceneVersion==1,
        "button_context_original_receipt_not_resigned");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static void NewProxySelectionRejectsAdmission(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);if(!ctx)return;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    CjguiInternalRendererEvent activate=ActualButtonPress(ctx,NO);
    CjguiInternalCommandSource source={0};
    CHECK(activate.kind==27 && cjgui_internal_renderer_owner_consumed_command_source(
        ctx.rendererSessionToken,&source)==0 && source.isValid,
        "button_context_selection_change_starts_from_valid_producer_source");
    uint64_t revisionBefore=ctx.composableSceneOverlay.installedRangeSelectionRevision;
    NSRange selectedBefore=ctx.composableSceneOverlay.inputProxy.selectedRange;
    [ctx.composableSceneOverlay.inputProxy setSelectedRange:NSMakeRange(2,1)
        affinity:NSSelectionAffinityDownstream stillSelecting:NO];
    CHECK(ctx.composableSceneOverlay.installedRangeSelectionRevision>revisionBefore &&
        !NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange,selectedBefore),
        "button_context_selection_change_uses_real_textview_and_installed_selection_update");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)!=0,
        "button_context_new_actual_selection_rejects_unadmitted_origin");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static void AdmittedProxyMutationRejectsB(id<MTLDevice> device,BOOL changeBody) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);if(!ctx)return;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    CjguiInternalRendererEvent activate=ActualButtonPress(ctx,NO);
    CjguiInternalCommandSource source={0};
    CHECK(activate.kind==27 && cjgui_internal_renderer_owner_consumed_command_source(
        ctx.rendererSessionToken,&source)==0 && source.isValid,
        "button_context_post_admit_selection_starts_from_valid_source");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)==0,"button_context_post_admit_origin_admitted_once");
    uint64_t revisionBefore=ctx.composableSceneOverlay.installedRangeSelectionRevision;
    if (changeBody) {
        [ctx.composableSceneOverlay.inputProxy setString:@"FAKE!"];
        [ctx.composableSceneOverlay.inputProxy setSelectedRange:NSMakeRange(1,3)
            affinity:NSSelectionAffinityDownstream stillSelecting:NO];
        CHECK([ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FAKE!"] &&
            NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange,NSMakeRange(1,3)) &&
            ctx.composableSceneOverlay.installedRangeSelectionRevision>revisionBefore &&
            ctx.installedRangeObservedAckSequence==0,
            "button_context_post_admit_body_change_keeps_original_A_selection_without_owner_write");
    } else {
        [ctx.composableSceneOverlay.inputProxy setSelectedRange:NSMakeRange(2,1)
            affinity:NSSelectionAffinityDownstream stillSelecting:NO];
        CHECK(ctx.composableSceneOverlay.installedRangeSelectionRevision>revisionBefore &&
            NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange,NSMakeRange(2,1)),
            "button_context_post_admit_selection_change_updates_real_proxy_basis");
    }

    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(ctx.rendererSessionToken,&transfer)==0,
        "button_context_post_admit_transfer_created");
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferVersion=2;ctx.stagedComposableCommandMenuVersion=2;
    CHECK([ctx.stagedComposableNodes[1].value isEqualToString:@"FGHIJ"],
        "button_context_post_admit_candidate_keeps_original_B_body");
    CHECK(cjgui_internal_renderer_stage_window_background(ctx.rendererSessionToken,2,0,1)==0,
        "button_context_post_admit_candidate_background_prepared");
    // The staged B declaration remains the original FGHIJ target in both
    // variants; the body-change variant mutates only the resident A proxy.
    NSData *body=[@"FGHIJ" dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};c.transferId=transfer;
    c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;c.sourceOwnerVersion=10;
    c.sourceContextEpoch=a.candidate.contextEpoch;c.sourceMirrorRevision=a.candidate.mirrorRevision;
    c.targetNodeId=402;c.targetResourceId=1;c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    c.targetSceneVersion=2;c.targetAnchor16=1;c.targetFocus16=4;
    c.targetBodyUtf8=body.bytes;c.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t actual[65536]={0};
    CHECK(cjgui_internal_renderer_capture_candidate_selection(ctx.rendererSessionToken,&c,&receipt,
        actual,sizeof(actual),a.candidate.contextEpoch,3,1,0)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.composableSceneOverlay.activeNodeId==403 &&
        ctx.installedRangeBasis.selectionTransferId==a.selectionTransferId,
        changeBody ? "button_context_new_proxy_body_after_admit_rejects_B_before_install" :
            "button_context_new_proxy_selection_after_admit_rejects_B_before_install");
    (void)cjgui_internal_renderer_selection_transfer_discard_capsule(ctx.rendererSessionToken,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(ctx.rendererSessionToken,transfer);
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static void BindingChangeRejectsAdmission(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);if(!ctx)return;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    CjguiInternalRendererEvent activate=ActualButtonPress(ctx,NO);
    CjguiInternalCommandSource source={0};
    CHECK(activate.kind==27 && cjgui_internal_renderer_owner_consumed_command_source(
        ctx.rendererSessionToken,&source)==0 && source.isValid,
        "button_context_binding_change_starts_from_valid_source");
    ctx.ownedTextSessionBindingEpoch=a.candidate.bindingEpoch+1;
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        source.declarationToken,ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)!=0,
        "button_context_changed_installed_binding_rejects_old_origin");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static void InvalidButtonContext(id<MTLDevice> device,BOOL declared,BOOL cancel) {
    CJGuiInternalSession *ctx=ButtonFixture(device,declared,NULL);if(!ctx)return;
    CjguiInternalRendererEvent activation=ActualButtonPress(ctx,cancel);
    CjguiInternalCommandSource source={0};
    CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && !source.isValid,
        cancel ? "button_context_cancelled_press_has_no_handoff" : "button_context_unrelated_button_has_no_handoff");
    CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,source.originSerial,
        9001,ButtonActualCommandSequence(ctx,activation),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        ctx.ownedTextSessionBindingEpoch,10,0)!=0,"button_context_invalid_origin_never_admitted");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static CJGuiInternalSession *AXFocusReentrySession;
static BOOL AXFocusReentryArmed;
@interface AXCommandFocusReentryWindow : NSWindow
@end
@implementation AXCommandFocusReentryWindow
- (BOOL)makeFirstResponder:(NSResponder *)responder {
    BOOL result=[super makeFirstResponder:responder];
    CJGuiInternalSession *ctx=AXFocusReentrySession;
    if(AXFocusReentryArmed && ctx.window==self && responder==ctx.composableSceneOverlay) {
        AXFocusReentryArmed=NO;
        CHECK([ctx.composableSceneOverlay accessibilityPerformPressForNode:ctx.composableSceneOverlay.nodes[2]],
            "AX_command_actual_focus_callback_reenters_existing_AX_action");
    }
    return result;
}
@end
static void AXFocusReentryCannotResignOriginalCommandSource(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    ProductionFixtureWindowClass=AXCommandFocusReentryWindow.class;
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);
    ProductionFixtureWindowClass=Nil;if(!ctx)return;
    uint64_t pointer=ctx.nextPointerGestureEpoch;
    AXFocusReentrySession=ctx;AXFocusReentryArmed=YES;
    CHECK([ctx.composableSceneOverlay accessibilityPerformPressForNode:ctx.composableSceneOverlay.nodes[2]] &&
        !AXFocusReentryArmed && ctx.nextPointerGestureEpoch==pointer,
        "AX_command_reentrant_focus_does_not_fabricate_pointer_gesture");
    AXFocusReentrySession=nil;
    NSUInteger activations=0;
    while(ctx.pendingInteractions.count) {
        CjguiInternalRendererEvent event={0};
        CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event)==0,
            "AX_command_reentrant_original_FIFO_drains");
        if(event.kind==27) {
            activations++;CjguiInternalCommandSource source={0};
            CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && !source.isValid,
                "AX_command_reentry_cannot_attach_old_A_to_either_actual_activation");
        }
    }
    CHECK(activations==2 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"] &&
        ctx.installedRangeBasis.selectionTransferId==receipt.transferId && !ctx.selectionTransferCapsule,
        "AX_command_reentry_keeps_original_owner_proxy_and_receipt_without_new_transfer");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

static void ActualCommandProducerDomainsDoNotShareScalarAuthority(id<MTLDevice> device) {
    for(int ax=0;ax<2;ax++) {
        useActualAccessibilityPress=ax;
        CjguiInternalSelectionTransferReceipt receipt={0};
        CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);if(!ctx)continue;
        CjguiInternalRendererEvent event=ActualButtonPress(ctx,NO);
        CjguiCommandTextContext *command=ctx.commandTextContext;
        CJGuiInternalQueuedInteraction *queued=ctx.pumpedCommandInteraction;
        CjguiInternalCommandSource source={0};
        CHECK(event.kind==27 && command.pressSequence &&
            cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && source.isValid,
            "command_domain_original_production_source_valid_before_fault");
        uint64_t savedBinding=queued.bindingEpoch;
        CjguiInternalActivationPrefix savedPrefix=queued.activationPrefix,savedFrozen=command.actualActivationPrefix;
        if(ax) {
            queued.bindingEpoch=command.pressSequence;
            queued.activationPrefix=(CjguiInternalActivationPrefix){0};
        } else {
            CjguiInternalActivationPrefix other={.sessionGeneration=ctx.sessionGeneration,.nonce=command.pressSequence,
                .sceneVersion=queued.projectionVersion,.nodeId=403,.resourceId=1,.nodeKind=4,
                .bindingEpoch=ctx.ownedTextSessionBindingEpoch,.ordinal=2,.secondKind=27,.memberCount=2,.memberKind=27};
            queued.bindingEpoch=0;queued.activationPrefix=other;command.actualActivationPrefix=other;
        }
        CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && !source.isValid,
            "command_domain_same_numeric_AX_nonce_and_physical_sequence_cannot_cross_borrow");
        CHECK(cjgui_internal_renderer_admit_command_text_context(ctx.rendererSessionToken,
            command.origin.originSerial,command.origin.declarationToken,command.pressSequence,403,1,4,
            ctx.ownedTextSessionBindingEpoch,10,0)!=0,
            "command_domain_admission_uses_same_original_producer_check_as_getter");
        queued.bindingEpoch=savedBinding;queued.activationPrefix=savedPrefix;command.actualActivationPrefix=savedFrozen;
        CjguiCommandTextContext *foreign=[CjguiCommandTextContext new];
        foreign.origin=command.origin;foreign.source=command.source;foreign.pressSequence=command.pressSequence;
        foreign.producerDomain=command.producerDomain;foreign.actualActivationPrefix=command.actualActivationPrefix;
        foreign.valid=YES;foreign.activated=YES;queued.commandTextContext=foreign;
        CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && !source.isValid,
            "command_domain_identical_scalar_foreign_command_object_cannot_replace_original");
        queued.commandTextContext=command;
        CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && source.isValid,
            "command_domain_fault_rejection_does_not_consume_genuine_original_source");
        CHECK(CjguiConfigureComposableCommandMenuOnMain(ctx.rendererSessionToken,1,0)==0 &&
            CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,
            "command_domain_declaration_actually_withdrawn");
        CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source)==0 && !source.isValid &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "command_domain_withdrawn_declaration_cannot_write_or_recover_old_A");
        CjguiReleaseSession(ctx.rendererSessionToken);
    }
    useActualAccessibilityPress=NO;
}

#ifndef CJGUI_BUTTON_CONTEXT_NO_MAIN
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 77;
        ValidButtonContext(device);
        useActualAccessibilityPress=YES;
        fprintf(stderr,"actual_AXPress_production_begin\n");ValidButtonContext(device);
        InvalidButtonContext(device,NO,NO);
        NewProxySelectionRejectsAdmission(device);
        AdmittedProxyMutationRejectsB(device,NO);AdmittedProxyMutationRejectsB(device,YES);
        BindingChangeRejectsAdmission(device);
        useActualAccessibilityPress=NO;
        NewProxySelectionRejectsAdmission(device);
        AdmittedProxyMutationRejectsB(device,NO);AdmittedProxyMutationRejectsB(device,YES);
        BindingChangeRejectsAdmission(device);
        InvalidButtonContext(device,YES,YES);InvalidButtonContext(device,NO,NO);
        ActualCommandProducerDomainsDoNotShareScalarAuthority(device);
        AXFocusReentryCannotResignOriginalCommandSource(device);
        fprintf(stderr,"button_text_context_production failures=%d\n",failures);return failures?1:0;
    }
}

#endif
