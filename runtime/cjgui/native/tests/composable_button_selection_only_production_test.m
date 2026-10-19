// Real button producer + admitted command + same-version owner choice + real B.
#define CJGUI_BUTTON_CONTEXT_NO_MAIN 1
#import "composable_button_text_context_production_test.m"

@interface ButtonSelectionSystemKeyWindow : NSWindow
@end
@implementation ButtonSelectionSystemKeyWindow
- (BOOL)canBecomeKeyWindow { return YES; }
@end

static int systemCallbackFault;
static uint64_t systemCallbackToken,systemCallbackHandoff;
@interface ButtonSelectionCallbackHost : CJGuiInternalComposableInputHost
@end
@implementation ButtonSelectionCallbackHost
- (void)insertText:(id)text replacementRange:(NSRange)range {
    int fault=systemCallbackFault;systemCallbackFault=0;
    if(fault==10) CHECK(cjgui_internal_renderer_owner_handoff_abort(systemCallbackToken,systemCallbackHandoff)==0,
        "button_selection_real_system_callback_cancels_original_root");
    if(fault==11) CHECK([self.window makeFirstResponder:nil],"button_selection_real_system_callback_loses_focus");
    if(fault==12) {
        CJGuiInternalComposableSceneOverlay *o=self.composableOverlay;
        CJGuiInternalComposableInputProxy *next=[[CJGuiInternalComposableInputProxy alloc] initWithFrame:NSMakeRect(0,0,50,30)];
        next.composableOverlay=o;next.string=@"CURRENT-C";o.inputProxy=next;
        o.session.ownedTextSessionBindingEpoch++;
        [o focusNode:o.nodes[0] enqueue:NO];
        CHECK(o.activeNodeId==401 && [next.string isEqualToString:@"abcde"],
            "button_selection_real_callback_changes_binding_and_proxy_before_forwarding");
    }

    [super insertText:text replacementRange:range];
}
@end
static uint64_t cancelAttachmentToken, cancelAttachmentTransfer;
@interface ButtonSelectionCancelOverlay : CJGuiInternalComposableSceneOverlay
@end
@implementation ButtonSelectionCancelOverlay
- (void)addSubview:(NSView *)view {
    [super addSubview:view];
    if(cancelAttachmentToken==self.session.rendererSessionToken && [view isKindOfClass:NSScrollView.class]) {
        uint64_t token=cancelAttachmentToken;cancelAttachmentToken=0;
        CHECK(cjgui_internal_renderer_selection_transfer_request_cancel(token,cancelAttachmentTransfer)==0,
            "button_selection_real_attachment_callback_cancels_original");
    }
}
@end

static void ButtonSelectionOnly(id<MTLDevice> device,int boundary) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,&receipt);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken,identity=0,transfer=0;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    if(boundary>=7) {
        object_setClass(ctx.window,ButtonSelectionSystemKeyWindow.class);
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];
        [ctx.window setTitle:@"E Button Selection System Context Fixture"];
        [ctx.window makeKeyAndOrderFront:nil];
        [ctx.window makeKeyWindow];
        NSDate *keyDeadline=[NSDate dateWithTimeIntervalSinceNow:3];
        while(NSApp.keyWindow!=ctx.window && keyDeadline.timeIntervalSinceNow>0) {
            NSEvent *startup=[NSApp nextEventMatchingMask:NSEventMaskAny
                untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01] inMode:NSDefaultRunLoopMode dequeue:YES];
            if(startup)[NSApp sendEvent:startup];
        }
        (void)ctx.composableSceneOverlay.inputHost.inputContext;
        fprintf(stderr,"button_key_fixture_bootstrap visible=%d active=%d can_key=%d key=%ld wanted=%ld\n",
            ctx.window.isVisible,NSApp.isActive,ctx.window.canBecomeKeyWindow,
            (long)NSApp.keyWindow.windowNumber,(long)ctx.window.windowNumber);
        CHECK(NSApp.keyWindow==ctx.window,"button_selection_original_system_key_window");
    }
    CjguiInternalRendererEvent activation=ActualButtonPress(ctx,NO);
    CjguiInternalCommandSource source={0};
    CHECK(activation.kind==27 && cjgui_internal_renderer_owner_consumed_command_source(token,&source)==0 &&
        source.isValid && source.focusedNodeId==402 && source.targetNodeId==403,
        "button_selection_real_DOWN_ACTIVATE_source");
    if(boundary!=8) {
    CHECK(cjgui_internal_renderer_admit_command_text_context(token,source.originSerial,source.declarationToken,
        ButtonActualCommandSequence(ctx,activation),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,a.candidate.bindingEpoch,10,0)==0,
        "button_selection_real_origin_admitted_before_choice");
    }
    CHECK(cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"button-selection",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
        CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&identity)==0 && identity &&
        cjgui_internal_renderer_owner_handoff_seal(token,identity,10,2,4,4,-1)==0,
        "button_selection_same_version_new_choice_sealed");
    if(boundary==7 || boundary==13) {
        NSEvent *quit=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
            modifierFlags:NSEventModifierFlagCommand timestamp:NSProcessInfo.processInfo.systemUptime
            windowNumber:ctx.window.windowNumber context:nil characters:@"q" charactersIgnoringModifiers:@"q"
            isARepeat:NO keyCode:12];
        CHECK(![ctx.composableSceneOverlay performKeyEquivalent:quit] && !ctx.pendingInteractions.count &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "button_selection_CmdQ_not_consumed_or_reinterpreted_as_button_text");
    }
    if(boundary==13) {
        NSEvent *left=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0
            timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber context:nil
            characters:@"\uf702" charactersIgnoringModifiers:@"\uf702" isARepeat:NO keyCode:123];
        [ctx.composableSceneOverlay keyDown:left];
        CHECK(ctx.pendingInteractions.count==1 &&
            ctx.pendingInteractions.firstObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            [ctx.pendingInteractions.firstObject.formText isEqualToString:@"left"] &&
            ctx.pendingInteractions.firstObject.nodeId==a.candidate.nodeId &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "button_selection_original_selector_keeps_original_owner_route_without_interpretation");
        CjguiReleaseSession(token);return;
    }
    if(boundary>=7) {
        if(boundary>=10) {
            object_setClass(ctx.composableSceneOverlay.inputHost,ButtonSelectionCallbackHost.class);
            systemCallbackFault=boundary;systemCallbackToken=token;systemCallbackHandoff=identity;
        }
        NSWindow *other=nil;
        if(boundary==9) other=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,10,10)
            styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
        NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0
            timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:(other ?: ctx.window).windowNumber context:nil
            characters:@"中" charactersIgnoringModifiers:@"中" isARepeat:NO keyCode:0];
        [ctx.composableSceneOverlay keyDown:key];
        if(boundary==8 || boundary==9) {
            CHECK(ctx.pendingInteractions.count==0 && !ctx.rejectedAfterCaretInputs.count &&
                [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
                "button_selection_unadmitted_or_foreign_key_never_hijacks_system_context");
            CjguiReleaseSession(token);return;
        }
        if(boundary>=10) {
            CHECK(systemCallbackFault==0 && ctx.rejectedAfterCaretInputs.count==1 &&
                [ctx.rejectedAfterCaretInputs.firstObject.payload isEqualToString:@"中"] &&
                ctx.rejectedAfterCaretInputs.firstObject.origin.candidate.nonce==a.candidate.nonce &&
                [ctx.composableSceneOverlay.inputProxy.string isEqualToString:(boundary==12 ? @"abcde" : @"FGHIJ")] &&
                [ctx.rejectedAfterCaretInputs.firstObject.origin.body isEqualToData:[@"FGHIJ" dataUsingEncoding:NSUTF8StringEncoding]],
                "button_selection_invalidated_real_callback_recovers_original_without_writing_A_or_C");
            uint64_t metadata[21]={0};uint8_t payload[3]={0},reason[256]={0};
            CHECK(cjgui_internal_renderer_peek_caret_recovery(token,metadata,21)==0 && metadata[12]==3 &&
                metadata[18]>0 && metadata[18]<sizeof(reason) &&
                cjgui_internal_renderer_copy_caret_recovery(token,metadata[1],metadata[0],payload,3,reason,(uint32_t)metadata[18])==0 &&
                memcmp(payload,"中",3)==0 && cjgui_internal_renderer_finish_caret_recovery(token,metadata[1],metadata[0],1)==0 &&
                cjgui_internal_renderer_finish_caret_recovery(token,metadata[1],metadata[0],2)==0,
                "button_selection_invalidated_callback_existing_copy_confirm_preserves_real_bytes");
            CjguiReleaseSession(token);return;
        }
        NSEvent *emoji=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0
            timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber context:nil
            characters:@"😀" charactersIgnoringModifiers:@"😀" isARepeat:NO keyCode:0];
        [ctx.composableSceneOverlay keyDown:emoji];
        CHECK(ctx.pendingInteractions.count==2 &&
            [ctx.pendingInteractions[0].afterCaretTextInput.payload isEqualToString:@"中"] &&
            [ctx.pendingInteractions[1].afterCaretTextInput.payload isEqualToString:@"😀"] &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "button_selection_original_keys_before_B_enter_existing_afterCaret_without_writing_A");
    }
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferVersion=2;ctx.stagedComposableCommandMenuVersion=2;
    CHECK(cjgui_internal_renderer_stage_window_background(token,2,0,1)==0 &&
        cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,"button_selection_real_B_staged");
    NSData *body=[ctx.composableSceneOverlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};c.transferId=transfer;
    c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;c.sourceOwnerVersion=10;
    c.sourceContextEpoch=a.candidate.contextEpoch;c.sourceMirrorRevision=a.candidate.mirrorRevision;
    c.targetNodeId=402;c.targetResourceId=1;c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    c.targetSceneVersion=2;c.targetAnchor16=4;c.targetFocus16=4;
    c.targetBodyUtf8=body.bytes;c.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t actual[65536]={0};
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,actual,sizeof(actual),
        a.candidate.contextEpoch,3,2,0)==0 && cjgui_internal_renderer_owner_handoff_bind(token,identity,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0,
        "button_selection_real_A_captured_and_root_bound");
    fprintf(stderr,"button_selection_observe phase=before_prepare proxy_first=%d button_first=%d actual_source=%d\n",
        CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),ctx.window.firstResponder==ctx.composableSceneOverlay,
        CjguiCandidateSelectionActualSourceReadbackMatches(ctx,ctx.selectionTransferCapsule));
    if(boundary==6) {
        object_setClass(ctx.composableSceneOverlay,ButtonSelectionCancelOverlay.class);
        cancelAttachmentToken=token;cancelAttachmentTransfer=transfer;
    }
    uint8_t ready=0;
    CjguiInternalRendererStatus preparation=cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready);
    if(boundary!=6) CHECK(preparation==0 && ready,"button_selection_real_preparation_ready");
    else CHECK(cancelAttachmentToken==0 && ctx.installedRangeBasis==a &&
        !CjguiCandidateSelectionSourceReadbackMatches(ctx,ctx.selectionTransferCapsule),
        "button_selection_callback_cancel_cannot_become_B_authority");
    fprintf(stderr,"button_selection_observe phase=after_prepare proxy_first=%d button_first=%d active=%llu actual_source=%d\n",
        CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),ctx.window.firstResponder==ctx.composableSceneOverlay,
        (unsigned long long)ctx.composableSceneOverlay.activeNodeId,
        CjguiCandidateSelectionActualSourceReadbackMatches(ctx,ctx.selectionTransferCapsule));
    if(boundary && boundary!=7) {
        if(boundary==1) CHECK([ctx.window makeFirstResponder:nil],"button_selection_external_responder_moved");
        if(boundary==2) ctx.ownedTextSessionBindingEpoch++;
        if(boundary==3) [ctx.composableSceneOverlay.inputProxy setSelectedRange:NSMakeRange(2,1)
            affinity:NSSelectionAffinityDownstream stillSelecting:NO];
        if(boundary==4) CHECK(cjgui_internal_renderer_selection_transfer_request_cancel(token,transfer)==0,
            "button_selection_original_pending_cancel_requested");
        if(boundary==5) ctx.hasStagedWindowBackground=NO;
        CjguiInternalRendererFrameObservation refusedFrame={0};
        CjguiInternalRendererStatus refused=CjguiPresentComposableSceneOnMain(token,&refusedFrame);
        CHECK(refused!=0 && refused!=CJGUI_INTERNAL_RENDERER_READBACK_FAILED && ctx.installedRangeBasis==a &&
            ctx.selectionReceiptOwnerRevision==1,"button_selection_invalid_custody_cannot_commit_or_resign_A");
        fprintf(stderr,"button_selection_boundary mode=%d status=%u source=%d\n",boundary,refused,
            CjguiCandidateSelectionActualSourceReadbackMatches(ctx,ctx.selectionTransferCapsule));
        if(boundary==5) {
            CjguiSelectionTransferCapsule *capsule=ctx.selectionTransferCapsule;
            uint32_t state=0;uint8_t cancelled=0;
            CHECK(CjguiSelectionTransferCellState(token,transfer,&state,&cancelled) &&
                CjguiSelectionTransferTransition(token,transfer,CJGUI_SELECTION_TRANSFER_PENDING,
                    CJGUI_SELECTION_TRANSFER_FINALIZING,YES)==0,"button_selection_actual_failed_present_rollback_lease");
            CHECK(cjgui_internal_renderer_selection_transfer_restore_a(token,transfer)==0 &&
                ctx.window.firstResponder==capsule.firstResponder && ctx.composableSceneOverlay.activeNodeId==403 &&
                [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
                "button_selection_failed_present_restores_original_button_responder_and_A");
        }
        CjguiReleaseSession(token);return;
    }
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(token,&frame);
    fprintf(stderr,"button_selection_observe phase=first_present status=%u committed=%d\n",status,
        ctx.installedRangeBasis.selectionTransferId==transfer);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==transfer && ctx.selectionReceiptOwnerVersion==10 &&
        ctx.selectionReceiptOwnerRevision==2 && ctx.composableSceneOverlay.activeNodeId==402 &&
        CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),
        "button_selection_first_present_commits_same_version_actual_B");
    if(ctx.installedRangeBasis.selectionTransferId==transfer) {
        CHECK(cjgui_internal_renderer_owner_handoff_complete(token,identity,transfer,10,2,4,4)==0 &&
            ctx.commandTextContext==nil,"button_selection_actual_B_completes_and_retires_command");
        if(boundary==7 && ctx.pendingInteractions.count==2) {
            CjguiInternalRendererEvent event={0};CjguiInternalInstalledRangeIntent intent={0};
            CjguiInstalledRangeState *b=ctx.installedRangeBasis;
            CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
                cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
                    b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 &&
                intent.rangeStart16==4 && intent.rangeLength16==0 && intent.replacementUtf8Length==3,
                "button_selection_original_Chinese_materializes_once_only_at_actual_B");
            CjguiInternalRendererEvent waiting={0};
            CHECK(cjgui_internal_renderer_pump_event(token,0,&waiting)==0 && waiting.kind==0 &&
                cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0,
                "button_selection_emoji_waits_real_Chinese_ACK");
            CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
                cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
                    b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 &&
                intent.rangeStart16==5 && intent.rangeLength16==0 && intent.replacementUtf8Length==4 &&
                cjgui_internal_renderer_ack_installed_range(token,&intent,1,12)==0 &&
                [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHI中😀J"],
                "button_selection_original_emoji_follows_ACK_once_full_body_exact");
            CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0,
                "button_selection_no_duplicate_system_interpretation_or_body_intent");
        }

    }
    CjguiReleaseSession(token);
}
int main(void) { @autoreleasepool { [NSApplication sharedApplication]; [NSApp finishLaunching];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 77;
    for(int boundary=0;boundary<=13;boundary++)ButtonSelectionOnly(device,boundary);useActualAccessibilityPress=YES;ButtonSelectionOnly(device,0);useActualAccessibilityPress=NO;fprintf(stderr,"button_selection_summary failures=%d\n",failures);return failures?1:0;
} }
