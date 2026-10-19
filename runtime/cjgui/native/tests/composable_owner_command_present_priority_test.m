// A real queued history successor already has an owner receipt. Publishing
// the predecessor's B first would retire its captured declaration/binding.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static void OwnerCommandBeforePresentation(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&receipt),"history_priority_actual_A");
    if(!ctx || !ctx.installedRangeBasis.hasReceipt)return;
    uint64_t token=ctx.rendererSessionToken;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,
        10,1,1,&needs)==0,"history_priority_original_install_published");
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,1,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"history-undo","Undo","Edit",
            "shortcut:command+z",0,0,1,0)==0 &&
        cjgui_internal_renderer_set_composable_command_identity(token,0,7001,402,1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT)==0 &&
        cjgui_internal_renderer_set_composable_command_completion_policy(token,0,1)==0 &&
        CjguiCommitComposableCommandMenuOnMain(token)==0,"history_priority_declaration_published");
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand timestamp:1 windowNumber:ctx.window.windowNumber
        context:nil characters:@"z" charactersIgnoringModifiers:@"z" isARepeat:NO keyCode:6];
    CHECK([ctx.composableSceneOverlay performKeyEquivalent:key],"history_priority_original_first_command");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34,
        "history_priority_first_command_dequeued");
    CJGuiInternalQueuedInteraction *first=ctx.activeCaretNavigation;
    uint64_t handoff=0;
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"prefix-fixture",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,
        10,0,first.inputSequence,&handoff)==0 && handoff &&
        cjgui_internal_renderer_owner_handoff_seal(token,handoff,11,2,1,1,-1)==0 &&
        cjgui_internal_renderer_accept_owner_command_receipt(token,handoff,ctx.sessionGeneration,
            first.inputSequence,first.inputPreviousSequence,10,11,2,1,1,1)==0 &&
        !ctx.activeCaretNavigation,"history_priority_real_original_owner_receipt");
    PreparePlainCandidate(ctx);
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"history-undo","Undo","Edit",
            "shortcut:command+z",0,0,1,0)==0 &&
        cjgui_internal_renderer_set_composable_command_identity(token,0,7002,402,1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT)==0 &&
        cjgui_internal_renderer_set_composable_command_completion_policy(token,0,1)==0,
        "history_priority_future_B_declaration_staged");
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node;raw.nodeId=1013;raw.projectionVersion=2;target.node=raw;
    NSMutableString *after=[ctx.composableSceneOverlay.inputProxy.string mutableCopy];
    [after deleteCharactersInRange:NSMakeRange(1,3)];target.value=after;ctx.stagedComposableNodes[2]=target;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"history_priority_actual_B_layout");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,"history_priority_B_created");
    CjguiInternalSelectionTransferCandidate c={0};c.transferId=transfer;
    c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;c.sourceOwnerVersion=11;c.sourceAcceptedVersion=11;
    c.targetNodeId=1013;c.targetResourceId=1;c.targetNodeKind=raw.nodeKind;c.targetSceneVersion=2;
    c.targetAnchor16=1;c.targetFocus16=1;NSData *bytes=[after dataUsingEncoding:NSUTF8StringEncoding];
    c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,2,0)==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,handoff,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "history_priority_B_bound_to_same_owner_receipt");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==0 && ready,
        "history_priority_B_prepared");
    CHECK([ctx.composableSceneOverlay performKeyEquivalent:key],"history_priority_original_successor_queued");
    CJGuiInternalQueuedInteraction *second=ctx.pendingInteractions.firstObject;
    CHECK(second.inputPreviousSequence==first.inputSequence &&
        CjguiOwnerCommandSourceMatches(ctx,second),"history_priority_successor_has_real_owner_prefix");
    CjguiOwnerSelectionHandoff *h=ctx.ownerSelectionHandoff;
    h.ownerReceiptAccepted=NO;
    CHECK(CjguiPresentInputDispositionOnMain(ctx,ctx.selectionTransferCapsule)!=CjguiPresentDispatchOriginalA,
        "history_priority_unconfirmed_owner_cannot_preempt");
    h.ownerReceiptAccepted=YES;
    uint64_t binding=ctx.ownedTextSessionBindingEpoch;ctx.ownedTextSessionBindingEpoch++;
    CHECK(!CjguiOwnerCommandSourceMatches(ctx,second),"history_priority_changed_binding_still_refused");
    ctx.ownedTextSessionBindingEpoch=binding;
    ctx.composableCommandMenuItems.firstObject.enabled=NO;
    CHECK(!CjguiOwnerCommandSourceMatches(ctx,second),"history_priority_revoked_declaration_still_refused");
    ctx.composableCommandMenuItems.firstObject.enabled=YES;
    uint64_t frameBefore=ctx.view.frameIndex;
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(token,&frame);
    CHECK(status==39 && ctx.composableSceneVersion==1 && ctx.view.frameIndex==frameBefore &&
        ctx.pendingInteractions.firstObject==second && second.commandSource.declarationToken==7001 &&
        ctx.installedRangeBasis==a,"history_priority_ready_owner_command_preempts_B_without_rebinding");
    if(status==39) {
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==34 &&
            ctx.activeCaretNavigation==second && !ctx.pendingInteractions.count &&
            second.inputSequence==first.inputSequence+1 && second.caretInputOrigin.acceptedVersion==10,
            "history_priority_original_successor_dequeued_once");
    }
    CjguiReleaseSession(token);
}

int main(void) { @autoreleasepool { [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 77;
    OwnerCommandBeforePresentation(device);return failures?1:0; } }
