// Original window delivery before the real ACTIVATE is admitted. No text
// callback, artificial DOWN or retry is used to bridge that interval.
#define CJGUI_BUTTON_CONTEXT_NO_MAIN 1
#import "composable_button_text_context_production_test.m"

@interface CommandCustodyWindow : CJGuiInternalWindow
@end
@implementation CommandCustodyWindow
- (BOOL)canBecomeKeyWindow { return YES; }
@end

static int originalCallbackFault;
static BOOL reenterThirdOriginal;
static NSEvent *OriginalCommandKey(CJGuiInternalSession *ctx, NSString *text, unsigned short code);
static int originalContextCalls,originalKeyUpContextCalls;
static IMP originalHostInsertIMP,originalContextHandleIMP;
static void OriginalHostInsert(id host,SEL selector,id text,NSRange range) {
    CJGuiInternalSession *ctx=((CJGuiInternalComposableInputHost *)host).composableOverlay.session;
    if(ctx.interpretingOriginalCommandKey && reenterThirdOriginal) {
        reenterThirdOriginal=NO;
        [ctx.window sendEvent:OriginalCommandKey(ctx,@"z",6)];
        CHECK(ctx.pendingInteractions.count==2 &&
            [ctx.pendingInteractions[0].originalCommandKey.event.characters isEqualToString:@"n"] &&
            [ctx.pendingInteractions[1].originalCommandKey.event.characters isEqualToString:@"z"] &&
            !ctx.pendingInteractions[1].inputProductionInvocation,
            "raw_reentrant_third_original_stays_after_already_queued_second");
    }
    if(ctx.interpretingOriginalCommandKey && originalCallbackFault) {
        int fault=originalCallbackFault;originalCallbackFault=0;
        if(fault==1) {
            NSUInteger before=ctx.pendingInteractions.count;
            [ctx.window sendEvent:ctx.interpretingOriginalCommandKey.event];
            CHECK(ctx.pendingInteractions.count==before && !CjguiMaterializeOriginalCommandKeyAtHead(ctx),
                "raw_same_original_window_reentry_and_nested_materialization_do_not_interpret_twice");
        } else if(fault==2) {
            CHECK([ctx.window makeFirstResponder:nil],"raw_real_system_callback_focus_loss_before_forward");
        }
    }
    ((void(*)(id,SEL,id,NSRange))originalHostInsertIMP)(host,selector,text,range);
}
static BOOL OriginalContextHandle(id context,SEL selector,NSEvent *event) {
    originalContextCalls++;
    if(event.type==NSEventTypeKeyUp)originalKeyUpContextCalls++;
    if(originalCallbackFault==6) {
        originalCallbackFault=0;
        CJGuiInternalSession *ctx=((CJGuiInternalWindow *)event.window).cjguiSession;
        [ctx.composableSceneOverlay.inputHost setMarkedText:@"候" selectedRange:NSMakeRange(1,0)
            replacementRange:NSMakeRange(NSNotFound,0)];
        return YES;
    }
    if(originalCallbackFault==4) {originalCallbackFault=5;return NO;}
    if(originalCallbackFault==5 && event.type==NSEventTypeKeyUp) {originalCallbackFault=0;return NO;}
    if(originalCallbackFault==3) { originalCallbackFault=0;return NO; }
    return ((BOOL(*)(id,SEL,NSEvent *))originalContextHandleIMP)(context,selector,event);
}
static BOOL originalQueueBeforePump,publicationBeforeCompletion;
static NSEvent *OriginalCommandKey(CJGuiInternalSession *ctx, NSString *text, unsigned short code);

static NSEvent *OriginalCommandKey(CJGuiInternalSession *ctx, NSString *text, unsigned short code) {
    return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber
        context:nil characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:code];
}

static uint64_t CompleteOriginalSelectionB(CJGuiInternalSession *ctx,CjguiInstalledRangeState *a,uint64_t identity, const CjguiInternalSelectionTransferReceipt *sourceReceipt) {
    uint64_t token=ctx.rendererSessionToken,transfer=0;
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferVersion=2;ctx.stagedComposableCommandMenuVersion=2;
    CHECK(cjgui_internal_renderer_stage_window_background(token,2,0,1)==0 &&
        cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,"raw_command_real_B_scene_staged");
    NSData *body=[ctx.composableSceneOverlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};c.transferId=transfer;
    c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;c.sourceOwnerVersion=10;
    c.sourceContextEpoch=a.candidate.contextEpoch;c.sourceMirrorRevision=a.candidate.mirrorRevision;
    c.targetNodeId=402;c.targetResourceId=1;c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    c.targetSceneVersion=2;c.targetAnchor16=4;c.targetFocus16=4;c.targetBodyUtf8=body.bytes;
    c.targetBodyUtf8Length=(uint32_t)body.length;uint8_t actual[65536]={0};
    CjguiInternalRendererStatus captured=cjgui_internal_renderer_capture_candidate_selection(token,&c,sourceReceipt,actual,sizeof(actual),
        a.candidate.contextEpoch,3,2,0);
    CjguiInternalRendererStatus bound=captured==0 ? cjgui_internal_renderer_owner_handoff_bind(token,identity,transfer) : -1;
    CjguiInternalRendererStatus published=bound==0 ? cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer) : -1;
    fprintf(stderr,"raw_command_B_first_status capture=%d bind=%d publish=%d pending=%lu\n",captured,bound,published,(unsigned long)ctx.pendingInteractions.count);
    CHECK(captured==0 && bound==0 && published==0,"raw_command_original_A_and_real_B_bound_to_root");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==0 && ready,
        "raw_command_original_successors_do_not_deadlock_real_preparation");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&frame);
    CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==transfer && CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),
        "raw_command_original_successors_do_not_deadlock_real_Present");
    if(publicationBeforeCompletion) {
        CjguiInternalSelectionTransferReceipt actual={0};
        CHECK(cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&actual)==0 &&
            cjgui_internal_renderer_publish_installed_selection_owner(token,ctx.sessionGeneration,
                a.candidate.windowInstanceToken,a.candidate.contextEpoch,&actual,10,2)==0,
            "raw_actual_B_same_adopted_revision_metadata_published_without_completing_handoff");
        CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,1)==0 &&
            CjguiSetComposableCommandMenuItemOnMain(token,0,"mode","Mode","","",0,0,1,0,0)==0 &&
            cjgui_internal_renderer_set_composable_command_identity(token,0,9100,403,1,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON)==0 &&
            cjgui_internal_renderer_commit_installed_selection_command_menu(token,transfer,
                ctx.sessionGeneration,actual.bindingEpoch,10,2)==0,
            "raw_actual_installation_certifies_new_declaration_before_handoff_completion");
        CHECK(ctx.pendingInteractions.firstObject.originalCommandKey.publicationB &&
            !ctx.pendingInteractions.firstObject.originalCommandKey.completedB &&
            ctx.pendingInteractions.firstObject.originalCommandKey.phase==0 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "raw_publication_receipt_is_separate_from_completed_B_and_never_interprets_early");
    }
    CHECK(cjgui_internal_renderer_owner_handoff_complete(token,identity,transfer,10,2,4,4)==0 &&
        ctx.commandTextContext==nil,"raw_command_real_B_completed_before_first_interpretation");
    return transfer;
}

static CJGuiInternalSession *OriginalCommandFixture(id<MTLDevice> device,CjguiInternalSelectionTransferReceipt *receipt) {
    ProductionFixtureWindowClass=CommandCustodyWindow.class;
    CJGuiInternalSession *ctx=ButtonFixture(device,YES,receipt);
    ProductionFixtureWindowClass=Nil;
    if(!ctx)return nil;
    ((CJGuiInternalWindow *)ctx.window).cjguiSession=ctx;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
    [ctx.window makeKeyAndOrderFront:nil];[ctx.window makeKeyWindow];
    NSDate *keyDeadline=[NSDate dateWithTimeIntervalSinceNow:3];
    while(NSApp.keyWindow!=ctx.window && keyDeadline.timeIntervalSinceNow>0) {
        NSEvent *startup=[NSApp nextEventMatchingMask:NSEventMaskAny
            untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01] inMode:NSDefaultRunLoopMode dequeue:YES];
        if(startup)[NSApp sendEvent:startup];
    }
    CHECK(NSApp.keyWindow==ctx.window,"raw_command_original_key_window");
    return ctx;
}

static void OriginalKeyBeforeAdmission(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&receipt);if(!ctx)return;
    CjguiInternalRendererEvent activate={0};
    if(originalQueueBeforePump) {
        CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
        [o beginPressForNode:o.nodes[2] atPoint:NSMakePoint(20,280)];
        [o completePressAtPoint:NSMakePoint(20,280)];
    } else { activate=ActualButtonPress(ctx,NO); }
    CjguiCommandTextContext *command=ctx.commandTextContext;
    CHECK((originalQueueBeforePump ? command.originalActivation.kind==27 : activate.kind==27) &&
        command.valid && command.activated && !command.admitted,
        "raw_command_real_ACTIVATE_paused_before_admission");
    NSString *before=[ctx.composableSceneOverlay.inputProxy.string copy];
    NSEvent *original=OriginalCommandKey(ctx,@"m",46);
    [ctx.window sendEvent:original];
    if(originalQueueBeforePump) {
        CHECK(ctx.pendingInteractions.lastObject.originalCommandKey.event==original &&
            ctx.pendingInteractions.count>1,"raw_original_key_can_arrive_before_ACTIVATE_is_pumped");
        while(ctx.pendingInteractions.firstObject.kind!=0) {
            CjguiInternalRendererEvent next={0};
            CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&next)==0,
                "raw_actual_predecessors_pump_in_original_FIFO_before_key_placeholder");
            if(next.kind==27)activate=next;
        }
        CHECK(activate.kind==27,"raw_original_ACTIVATE_reaches_owner_before_held_key");
    }
    CHECK(ctx.pendingInteractions.count==1 && ctx.pendingInteractions.firstObject.kind==0,
        "raw_command_original_window_key_retained_before_admission");
    CHECK([ctx.composableSceneOverlay.inputProxy.string isEqualToString:before] &&
        ctx.installedRangeLocalTailSequence==ctx.installedRangeObservedAckSequence,
        "raw_command_before_admission_no_interpretation_proxy_or_owner_write");
    CjguiInternalRendererEvent pending={0};
    CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&pending)==0 && pending.kind==0,
        "raw_command_original_key_waits_in_normal_pump");
    uint64_t token=ctx.rendererSessionToken;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    CjguiInternalCommandSource source=command.origin;
    CHECK(ctx.pendingInteractions.firstObject.originalCommandKey.event==original,
        "raw_command_custody_is_original_NSEvent_not_characters_reconstructed");
    CHECK(cjgui_internal_renderer_admit_command_text_context(token,source.originSerial,source.declarationToken,
        ButtonActualCommandSequence(ctx,activate),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        a.candidate.bindingEpoch,10,0)==0,"raw_command_original_admission_released");
    uint64_t identity=0;
    CHECK(cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"raw-original",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
        CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&identity)==0 && identity &&
        cjgui_internal_renderer_owner_handoff_seal(token,identity,10,2,4,4,-1)==0,
        "raw_command_own_successor_exemption_allows_original_begin_seal");
    NSEvent *second=OriginalCommandKey(ctx,@"n",45);[ctx.window sendEvent:second];
    CHECK(ctx.pendingInteractions.count==2 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:before],
        "raw_command_second_original_key_after_admit_waits_B_behind_first");
    BOOL third=reenterThirdOriginal;
    uint64_t transfer=CompleteOriginalSelectionB(ctx,a,identity,&receipt);
    CHECK(ctx.pendingInteractions.count==2 && ctx.pendingInteractions[0].originalCommandKey.completedB &&
        ctx.pendingInteractions[1].originalCommandKey.completedB &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
        "raw_command_actual_completion_transport_survives_command_retirement_without_early_interpretation");
    CjguiInternalRendererEvent event={0};CjguiInternalInstalledRangeIntent intent={0};
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
            b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 &&
        intent.rangeStart16==4 && intent.rangeLength16==0 && intent.replacementUtf8Length==1 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImJ"],
        "raw_command_original_m_first_system_interpretation_is_exact_at_B");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImJ"],
        "raw_command_original_n_cannot_pass_first_real_ACK");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0,
        "raw_command_original_m_real_ACK");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
            b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 &&
        intent.rangeStart16==5 && intent.rangeLength16==0 &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImnJ"] &&
        cjgui_internal_renderer_ack_installed_range(token,&intent,1,12)==0,
        "raw_command_original_m_n_FIFO_only_on_completed_B_and_actual_ACK_prefix");
    if(third) {
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
            cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
                b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 && intent.rangeStart16==6 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImnzJ"] &&
            cjgui_internal_renderer_ack_installed_range(token,&intent,1,13)==0,
            "raw_first_callback_then_second_then_reentrant_third_obey_real_ACK_FIFO");
    }
    for(NSUInteger n=0;n<4;n++) {
        int status=cjgui_internal_renderer_pump_event(token,0,&event);
        if(status!=0 || event.kind!=0)fprintf(stderr,"raw_duplicate_pump_original_leaf status=%d kind=%u node=%llu actual_body=%s tail=%llu ack=%llu\n",
            status,event.kind,(unsigned long long)event.nodeId,
            ctx.composableSceneOverlay.inputProxy.string.UTF8String,
            (unsigned long long)ctx.installedRangeLocalTailSequence,(unsigned long long)ctx.installedRangeObservedAckSequence);
        CHECK(status==0 && event.kind==0,"raw_command_duplicate_pump_never_interprets_twice");
    }
    CHECK(ctx.retainedAfterCaretInputBytes==0 && !ctx.interpretingOriginalCommandKey &&
        ctx.installedRangeBasis.selectionTransferId==transfer,"raw_command_all_raw_event_charges_released_once");
    CjguiReleaseSession(token);
}

// Counterfactuals alter only original retained fields/queue members. They
// never create another production producer or relax the normal input path.
static void OriginalCommandNegative(id<MTLDevice> device,int fault) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&receipt);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken;
    CjguiInternalRendererEvent activation=ActualButtonPress(ctx,NO);
    CjguiCommandTextContext *command=ctx.commandTextContext;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"m",46)];
    CJGuiInternalQueuedInteraction *raw=ctx.pendingInteractions.firstObject;
    CHECK(raw.originalCommandKey && raw.kind==0,"raw_negative_has_real_original_window_input");
    uint64_t identity=0;
    if(fault>=5) {
        CHECK(cjgui_internal_renderer_admit_command_text_context(token,command.origin.originSerial,
            command.origin.declarationToken,ButtonActualCommandSequence(ctx,activation),403,1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,a.candidate.bindingEpoch,10,0)==0,
            "raw_negative_admits_original_command_only");
        if(fault==5 || fault==6) {
            CJGuiInternalQueuedInteraction *foreign=nil;
            if(fault==5) {
                raw.originalCommandKey.domain=CjguiCommandProducerActualAXPair;
            } else {
                // An unrelated private NONE record remains a real occupied
                // predecessor; excluding every NONE would incorrectly pass.
                foreign=[[CJGuiInternalQueuedInteraction alloc] initWithKind:0 recordIndex:0
                    selectionStart:0 selectionEnd:0 formText:@"" nodeId:401 projectionVersion:1
                    resourceId:1 nodeKind:CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT];
                [ctx.pendingInteractions insertObject:foreign atIndex:0];
            }
            CHECK(cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"raw-negative",1,
                a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
                CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&identity)==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING && !identity,
                fault==5 ? "raw_wrong_domain_same_scalar_cannot_claim_successor_exemption" :
                    "raw_true_foreign_NONE_predecessor_still_blocks_begin");
            if(foreign)[ctx.pendingInteractions removeObjectIdenticalTo:foreign];
            CjguiCancelOriginalCommandKeys(ctx,command,"negative_original_complete");
        } else {
            CHECK(cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"raw-negative",1,
                a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
                CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&identity)==0 && identity &&
                cjgui_internal_renderer_owner_handoff_seal(token,identity,10,2,4,4,-1)==0,
                "raw_negative_real_selection_root");
            if(fault==7) {
                CHECK(cjgui_internal_renderer_owner_handoff_abort(token,identity)==0,"raw_cancelled_original_root");
            } else {
                CompleteOriginalSelectionB(ctx,a,identity,&receipt);
                CHECK(raw.originalCommandKey.completedB!=nil,"raw_negative_reaches_actual_B_before_fault");
                if(fault==8) {
                    ctx.caretInputBranch.valid=NO; // independent choice retires the original prefix
                } else if(fault==9 || fault==10 || fault==11) {
                    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,1)==0 &&
                        CjguiSetComposableCommandMenuItemOnMain(token,0,"mode","Mode","","",0,0,1,0,0)==0 &&
                        cjgui_internal_renderer_set_composable_command_identity(token,0,9002,
                            fault==11 ? 401 : 403,1,fault==11 ? CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT : CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON)==0,
                        "raw_changed_declaration_group_staged");
                    if(fault==10 || fault==11)
                        CHECK(cjgui_internal_renderer_commit_installed_selection_command_menu(token,
                            raw.originalCommandKey.completedB.candidate.nonce,ctx.sessionGeneration,
                            ctx.ownedTextSessionBindingEpoch,10,2)==0,"raw_actual_installation_menu_commit");
                    else CHECK(CjguiCommitComposableCommandMenuOnMain(token)==0,"raw_unattested_token_replacement_commit");
                } else if(fault==12) {
                    raw.originalCommandKey.actionSequence++;
                } else if(fault==13) {
                    CjguiInternalCommandSource changed=raw.originalCommandKey.origin;changed.declarationToken=9002;
                    raw.originalCommandKey.origin=changed; // same scalar as a possible new token is not this original
                } else if(fault==14) {
                    NSEvent *same=raw.originalCommandKey.event;
                    NSUInteger before=ctx.pendingInteractions.count;
                    [ctx.window sendEvent:same];[ctx.window sendEvent:same];
                    CHECK(ctx.pendingInteractions.count==before,"raw_exact_same_event_object_before_interpretation_is_held_once");
                    CjguiCancelOriginalCommandKeys(ctx,command,"same_event_negative_finished");
                } else if(fault==15 || fault==16) {
                    originalCallbackFault=fault==15 ? 2 : 3;
                }
            }
        }
    } else if(fault==0) {
        CHECK(cjgui_internal_renderer_finish_command_text_context_admission(token,
            ButtonActualCommandSequence(ctx,activation),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,0)==0,
            "raw_common_refusal_ends_exact_original_wait_without_interpretation");
    } else if(fault==1) {
        CHECK(CjguiConfigureComposableCommandMenuOnMain(token,1,0)==0 &&
            CjguiCommitComposableCommandMenuOnMain(token)==0,"raw_original_declaration_revoked");
    } else if(fault==2) {
        ctx.sessionGeneration++;
    } else if(fault==3) {
        ctx.ownedTextSessionBindingEpoch++;
    } else if(fault==4) {
        [ctx windowDidResignKey:[NSNotification notificationWithName:NSWindowDidResignKeyNotification object:ctx.window]];
    }
    CjguiInternalRendererEvent event={0};int contextsBefore=originalContextCalls;
    if(fault==10) {
        CjguiInternalInstalledRangeIntent intent={0};CjguiInstalledRangeState *b=ctx.installedRangeBasis;
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
            cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
                b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0 && intent.rangeStart16==4 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImJ"] &&
            cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0,
            "raw_completed_B_declaration_republication_keeps_exact_original_source");
    } else {
        CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "raw_refusal_never_interprets_or_writes_A_B_or_C");
    }
    if(fault==15) {
        uint64_t metadata[21]={0};uint8_t payload[1]={0},reason[256]={0};
        CHECK(originalCallbackFault==0 && cjgui_internal_renderer_peek_caret_recovery(token,metadata,21)==0 &&
            metadata[12]==1 && metadata[15]==raw.originalCommandKey.completedB.candidate.nonce &&
            metadata[18]>0 && metadata[18]<sizeof(reason) &&
            cjgui_internal_renderer_copy_caret_recovery(token,metadata[1],metadata[0],payload,1,reason,(uint32_t)metadata[18])==0 &&
            payload[0]=='m' && cjgui_internal_renderer_finish_caret_recovery(token,metadata[1],metadata[0],1)==0 &&
            cjgui_internal_renderer_finish_caret_recovery(token,metadata[1],metadata[0],2)==0,
            "raw_invalidated_real_callback_preserves_genuine_payload_at_actual_B_not_raw_A");
    }
    if(fault==16) {
        CHECK(originalCallbackFault==0 && originalContextCalls==contextsBefore+1,
            "raw_system_unhandled_with_zero_callback_interpreted_once");
        for(NSUInteger n=0;n<3;n++)(void)cjgui_internal_renderer_pump_event(token,0,&event);
        CHECK(originalContextCalls==contextsBefore+1,"raw_unhandled_system_event_is_never_interpreted_again");
    }
    if(fault==2)ctx.sessionGeneration--;
    if(fault==3)ctx.ownedTextSessionBindingEpoch--;
    CHECK(ctx.pendingInteractions.count==0 && ctx.retainedAfterCaretInputBytes==0 &&
        !ctx.interpretingOriginalCommandKey,"raw_negative_terminal_releases_original_once");
    CjguiReleaseSession(token);
}

static void OriginalCommandCapacityAndClose(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&receipt);if(!ctx)return;
    (void)ActualButtonPress(ctx,NO);
    for(NSUInteger n=0;n<kCjguiPendingInteractionCapacity+1;n++)
        [ctx.window sendEvent:OriginalCommandKey(ctx,@"m",46)];
    CHECK(ctx.pendingInputQueueFullNotice && CjguiPendingInteractionOccupancy(ctx)<=kCjguiPendingInteractionCapacity &&
        ctx.retainedAfterCaretInputBytes<=kCjguiAfterCaretByteCapacity &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
        "raw_capacity_is_bounded_and_refuses_without_falling_back_to_wrong_A");
    CjguiReleaseSession(ctx.rendererSessionToken);
    CHECK(ctx.retainedAfterCaretInputBytes==0,"raw_close_releases_all_original_event_charges");
}

static void ExplicitInstallationPublicationBoundary(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt first={0},installed={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&first);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken;
    CHECK(InstallButtonContextA(ctx,&installed) && installed.transferId!=first.transferId &&
        ctx.selectionReceiptOwnerRevision==-1,"raw_explicit_actual_B_precedes_owner_choice_paint_publication");
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,ctx.composableSceneVersion,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(token,0,"mode","Mode","","",0,0,1,0,0)==0 &&
        cjgui_internal_renderer_set_composable_command_identity(token,0,9100,403,1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON)==0,"raw_explicit_B_new_binding_declaration_staged");
    int before=cjgui_internal_renderer_commit_installed_selection_command_menu(token,installed.transferId,
        ctx.sessionGeneration,installed.bindingEpoch,10,2);
    int64_t unpublished=ctx.selectionReceiptOwnerRevision;
    CjguiInternalSelectionTransferReceipt wrong=installed;wrong.nodeId++;
    CHECK(cjgui_internal_renderer_publish_installed_selection_owner(token,ctx.sessionGeneration,
        ctx.installedRangeBasis.candidate.windowInstanceToken,ctx.installedRangeBasis.candidate.contextEpoch,
        &wrong,10,2)==CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.selectionReceiptOwnerRevision==-1,
        "raw_metadata_wrong_receipt_cannot_publish_owner_revision");
    CHECK(cjgui_internal_renderer_publish_installed_selection_owner(token,ctx.sessionGeneration,
        ctx.installedRangeBasis.candidate.windowInstanceToken,ctx.installedRangeBasis.candidate.contextEpoch,
        &installed,10,2)==0 && ctx.selectionPaintTransferId==installed.transferId &&
        ctx.selectionPaintStagedScene==0 &&
        cjgui_internal_renderer_commit_installed_selection_command_menu(token,installed.transferId,
            ctx.sessionGeneration,installed.bindingEpoch,10,2)==0,
        "raw_metadata_exact_receipt_unlocks_command_publication_before_paint_without_discharging_paint");
    CHECK(cjgui_internal_renderer_publish_installed_selection_owner(token,ctx.sessionGeneration,
        ctx.installedRangeBasis.candidate.windowInstanceToken,ctx.installedRangeBasis.candidate.contextEpoch,
        &installed,10,2)==0 &&
        cjgui_internal_renderer_publish_installed_selection_owner(token,ctx.sessionGeneration,
        ctx.installedRangeBasis.candidate.windowInstanceToken,ctx.installedRangeBasis.candidate.contextEpoch,
        &installed,10,3)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "raw_metadata_idempotent_same_choice_never_overwrites_different_revision");
    uint8_t needs=0;
    int publication=cjgui_internal_renderer_finish_selection_paint_publication(token,installed.transferId,
        ctx.sessionGeneration,installed.bindingEpoch,installed.proxyGeneration,installed.selectionRevision,10,2,1,&needs);
    int after=cjgui_internal_renderer_commit_installed_selection_command_menu(token,installed.transferId,
        ctx.sessionGeneration,installed.bindingEpoch,10,2);
    fprintf(stderr,"raw_explicit_B_same_receipt_boundary before=%d unpublished_owner_revision=%lld paint=%d after=%d actual_owner_revision=%lld binding=%llu proxy=%llu native_revision=%llu\n",
        before,(long long)unpublished,publication,after,(long long)ctx.selectionReceiptOwnerRevision,
        (unsigned long long)installed.bindingEpoch,(unsigned long long)installed.proxyGeneration,
        (unsigned long long)installed.selectionRevision);
    CHECK(before==CJGUI_INTERNAL_RENDERER_SCENE_STALE && publication==0 && after==0,
        "raw_explicit_B_private_menu_owner_gate_is_preserved_and_paint_reuses_metadata");
    CjguiReleaseSession(token);
}

static void MultipleRawTerminalBoundary(id<MTLDevice> device,int variant) {
    BOOL unhandled=variant!=0;
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&receipt);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken,identity=0;
    CjguiInternalRendererEvent activation=ActualButtonPress(ctx,NO);
    CjguiCommandTextContext *command=ctx.commandTextContext;CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"m",46)];
    if(variant==2) {
        NSEvent *up=[NSEvent keyEventWithType:NSEventTypeKeyUp location:NSZeroPoint modifierFlags:0
            timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber context:nil
            characters:@"m" charactersIgnoringModifiers:@"m" isARepeat:NO keyCode:46];
        [ctx.window sendEvent:up];
    }
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"n",45)];
    CjguiOriginalCommandKey *second=ctx.pendingInteractions.lastObject.originalCommandKey;
    CHECK(ctx.pendingInteractions.count==(variant==2 ? 3 : 2),"raw_multiple_terminal_has_each_distinct_original_event");
    if(unhandled) {
        CHECK(cjgui_internal_renderer_admit_command_text_context(token,command.origin.originSerial,
            command.origin.declarationToken,ButtonActualCommandSequence(ctx,activation),403,1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,a.candidate.bindingEpoch,10,0)==0 &&
            cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"raw-terminal",1,
                a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
                CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&identity)==0 &&
            cjgui_internal_renderer_owner_handoff_seal(token,identity,10,2,4,4,-1)==0,
            "raw_multiple_unhandled_has_original_root");
        CompleteOriginalSelectionB(ctx,a,identity,&receipt);originalCallbackFault=(variant==3 ? 6 : (variant==2 ? 4 : 3));
    } else {
        CHECK(cjgui_internal_renderer_finish_command_text_context_admission(token,
            ButtonActualCommandSequence(ctx,activation),403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,0)==0,
            "raw_multiple_terminal_original_command_refused");
    }
    CjguiInternalRendererEvent event={0};
    (void)cjgui_internal_renderer_pump_event(token,0,&event);
    if(variant==3) {
        CHECK(event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION && second.phase==0 &&
            ctx.composableSceneOverlay.inputProxy.hasMarkedText,
            "raw_genuine_marked_callback_dispatches_before_later_raw_key_not_its_terminal");
        CHECK(ctx.pendingInteractions.firstObject.originalCommandKey==second &&
            ctx.retainedAfterCaretInputBytes==257,
            "raw_marked_callback_keeps_following_original_key_custody_until_its_own_turn");
        originalCallbackFault=0;CjguiReleaseSession(token);return;
    } else if(unhandled) {
        CHECK(event.kind==51 && second.phase==2 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHInJ"],
            "raw_unhandled_first_original_does_not_drop_next_distinct_original");
    } else {
        CHECK(event.kind==0 && second.phase==2 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHIJ"],
            "raw_refused_first_original_cannot_silently_dequeue_next_NONE_payload");
    }
    fprintf(stderr,"raw_multiple_terminal_boundary unhandled=%d next_phase=%u remaining=%lu charge=%llu event=%u\n",
        unhandled,second.phase,(unsigned long)ctx.pendingInteractions.count,
        (unsigned long long)ctx.retainedAfterCaretInputBytes,event.kind);
    CHECK(ctx.retainedAfterCaretInputBytes==0,"raw_multiple_terminal_all_raw_charges_released");
    originalCallbackFault=0;CjguiReleaseSession(token);
}

// The normal owner creates a real next selection handoff while acknowledging
// the first range. Merely ACKing in place does not cover this installation.
static void OriginalRangeAckInstallationPrefix(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt source={0},rootB={0};
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&source);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken,root=0,next=0,transfer=0;
    CjguiInternalRendererEvent action=ActualButtonPress(ctx,NO),event={0};
    CjguiCommandTextContext *command=ctx.commandTextContext;CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"m",46)];
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"n",45)];
    CjguiOriginalCommandKey *second=ctx.pendingInteractions.lastObject.originalCommandKey;
    CHECK(cjgui_internal_renderer_admit_command_text_context(token,command.origin.originSerial,
        command.origin.declarationToken,ButtonActualCommandSequence(ctx,action),403,1,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,a.candidate.bindingEpoch,10,0)==0 &&
        cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"raw-range-prefix",1,
            a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
            CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&root)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,root,10,2,4,4,-1)==0,
        "raw_range_prefix_original_command_root");
    uint64_t firstTransfer=CompleteOriginalSelectionB(ctx,a,root,&source);
    CHECK(cjgui_internal_renderer_candidate_selection_receipt(token,2,firstTransfer,&rootB)==0,
        "raw_range_prefix_keeps_original_actual_root_receipt");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,firstTransfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,firstTransfer)==0,
        "raw_range_prefix_prior_actual_completion_resources_retired_before_next_transfer");
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;CjguiInternalInstalledRangeIntent intent={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,b.candidate.nodeId,b.candidate.resourceId,
            b.candidate.bindingEpoch,ctx.composableSceneVersion,&intent)==0,
        "raw_range_prefix_first_original_real_callback_claimed");
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"raw-range-prefix",1,
        b.candidate.windowInstanceToken,b.candidate.contextEpoch,b.candidate.bindingEpoch,10,
        intent.nonce,intent.seq,&next)==0,"raw_range_prefix_real_owner_begin_before_ACK");
    CjguiInternalInstalledRangeIntent wrongAck=intent;wrongAck.previousSeq++;
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&wrongAck,1,11)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        !second.waitingHandoff && ctx.installedRangeObservedAckVersion==10,
        "raw_wrong_ACK_cannot_enrol_raw_into_new_owner_installation");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,next,11,3,5,5,1)==0,
        "raw_range_prefix_real_owner_handoff_and_exact_range_ACK");
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];ctx.stagedComposableSceneVersion=3;
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[1],1,3);
    CjguiInternalRendererComposableNode raw=target.node;raw.projectionVersion=3;target.node=raw;
    target.value=@"FGHImJ";ctx.stagedComposableNodes[1]=target;ctx.stagedComposableDataTransferVersion=3;
    int background=cjgui_internal_renderer_stage_window_background(token,3,0,1);
    int menu=CjguiConfigureComposableCommandMenuOnMain(token,3,1);
    int item=CjguiSetComposableCommandMenuItemOnMain(token,0,"mode","Mode","","",0,0,1,0,0);
    int declaration=cjgui_internal_renderer_set_composable_command_identity(token,0,9200,403,1,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON);
    int text=CjguiPrepareComposableTextResources(ctx);
    int created=cjgui_internal_renderer_selection_transfer_create(token,&transfer);
    fprintf(stderr,"raw_range_prefix_staging_first background=%d menu=%d item=%d identity=%d text=%d create=%d transfer=%llu\n",
        background,menu,item,declaration,text,created,(unsigned long long)transfer);
    CHECK(background==0 && menu==0 && item==0 && declaration==0 && text==0 && created==0,
        "raw_range_prefix_next_real_scene_and_declarations_staged");
    NSData *body=[target.value dataUsingEncoding:NSUTF8StringEncoding];uint8_t actual[65536]={0};
    CjguiInternalSelectionTransferCandidate c={0};c.transferId=transfer;
    c.sourceWindowInstanceToken=b.candidate.windowInstanceToken;c.sourceOwnerVersion=11;
    c.sourceContextEpoch=b.candidate.contextEpoch;c.targetNodeId=402;c.targetResourceId=1;
    c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;c.targetSceneVersion=3;
    c.targetAnchor16=5;c.targetFocus16=5;c.targetBodyUtf8=body.bytes;c.targetBodyUtf8Length=(uint32_t)body.length;
    int captured=cjgui_internal_renderer_capture_candidate_selection(token,&c,&rootB,actual,sizeof(actual),
        b.candidate.contextEpoch,4,3,0);
    int bound=captured==0 ? cjgui_internal_renderer_owner_handoff_bind(token,next,transfer) : -1;
    int published=bound==0 ? cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer) : -1;
    uint8_t ready=0;int prepared=published==0 ? cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready) : -1;
    if(prepared==0 && ready) {
        CHECK(CjguiOriginalKeyWaitsForB(ctx,ctx.pendingInteractions.firstObject,ctx.selectionTransferCapsule),
            "raw_exact_real_range_ACK_and_waiting_candidate_have_one_shared_successor_proof");
        CjguiInstalledRangeIntentState *state=second.waitingRange;
        CjguiInternalInstalledRangeIntent original=state.value;
        for(int fault=0;fault<4;fault++) {
            CjguiInternalInstalledRangeIntent bad=original;
            if(fault==0)bad.nonce++;else if(fault==1)bad.proxyGeneration++;
            else if(fault==2)bad.previousSeq++;else bad.windowInstanceToken++;
            state.value=bad;
            CHECK(!CjguiOriginalKeyWaitsForB(ctx,ctx.pendingInteractions.firstObject,ctx.selectionTransferCapsule),
                "raw_same_branch_wrong_nonce_proxy_previous_or_window_cannot_borrow_actual_ACK");
            state.value=original;
        }
    }
    CjguiInternalRendererFrameObservation frame={0};int presented=prepared==0 && ready ? CjguiPresentComposableSceneOnMain(token,&frame) : -1;
    fprintf(stderr,"raw_range_prefix_install_first_status capture=%d bind=%d publish=%d prepare=%d ready=%u present=%d actual_transfer=%llu waiting_phase=%u\n",
        captured,bound,published,prepared,ready,presented,(unsigned long long)ctx.installedRangeBasis.selectionTransferId,second.phase);
    CHECK(captured==0 && bound==0 && published==0 && prepared==0 && ready &&
        (presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==transfer && second.phase==0,
        "raw_real_ACK_successor_does_not_block_its_own_next_actual_B_installation");
    if(ctx.installedRangeBasis.selectionTransferId==transfer) {
        CHECK(cjgui_internal_renderer_owner_handoff_complete(token,next,transfer,11,3,5,5)==0 &&
            cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
            cjgui_internal_renderer_claim_last_pumped_range(token,402,1,ctx.ownedTextSessionBindingEpoch,
                ctx.composableSceneVersion,&intent)==0 && intent.rangeStart16==5 &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImnJ"] &&
            cjgui_internal_renderer_ack_installed_range(token,&intent,1,12)==0,
            "raw_next_original_uses_completed_ACK_successor_B_and_same_declared_semantics");
    }
    CjguiReleaseSession(token);
}

static NSEvent *OriginalCommandKeyUp(CJGuiInternalSession *ctx) {
    return [NSEvent keyEventWithType:NSEventTypeKeyUp location:NSZeroPoint modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:ctx.window.windowNumber context:nil
        characters:@"m" charactersIgnoringModifiers:@"m" isARepeat:NO keyCode:46];
}
static void RetainedKeyUpUsesOriginalDefaultRoute(id<MTLDevice> device) {
    CjguiInternalSelectionTransferReceipt receipt={0};
    CJGuiInternalSession *ordinary=OriginalCommandFixture(device,&receipt);if(!ordinary)return;
    [ordinary.window sendEvent:OriginalCommandKey(ordinary,@"m",46)];
    NSString *body=[ordinary.composableSceneOverlay.inputProxy.string copy];
    int before=originalKeyUpContextCalls;
    [ordinary.window sendEvent:OriginalCommandKeyUp(ordinary)];
    int ordinaryUp=originalKeyUpContextCalls-before;
    CHECK([ordinary.composableSceneOverlay.inputProxy.string isEqualToString:body],
        "raw_KeyUp_unheld_original_window_route_keeps_text");
    CjguiReleaseSession(ordinary.rendererSessionToken);
    CJGuiInternalSession *ctx=OriginalCommandFixture(device,&receipt);if(!ctx)return;
    uint64_t token=ctx.rendererSessionToken,root=0;
    CjguiInternalRendererEvent action=ActualButtonPress(ctx,NO),event={0};
    CjguiCommandTextContext *command=ctx.commandTextContext;CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"m",46)];
    NSEvent *up=OriginalCommandKeyUp(ctx);[ctx.window sendEvent:up];
    CjguiOriginalCommandKey *retained=ctx.pendingInteractions.lastObject.originalCommandKey;
    [ctx.window sendEvent:OriginalCommandKey(ctx,@"n",45)];
    CHECK(cjgui_internal_renderer_admit_command_text_context(token,command.origin.originSerial,
        command.origin.declarationToken,ButtonActualCommandSequence(ctx,action),403,1,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,a.candidate.bindingEpoch,10,0)==0 &&
        cjgui_internal_renderer_owner_handoff_begin_with_purpose(token,"raw-up-default",1,
            a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,
            CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&root)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,root,10,2,4,4,-1)==0,
        "raw_KeyUp_default_real_command_root");
    CompleteOriginalSelectionB(ctx,a,root,&receipt);CjguiInstalledRangeState *b=ctx.installedRangeBasis;
    CjguiInternalInstalledRangeIntent intent={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        cjgui_internal_renderer_claim_last_pumped_range(token,402,1,b.candidate.bindingEpoch,
            ctx.composableSceneVersion,&intent)==0 && cjgui_internal_renderer_ack_installed_range(token,&intent,1,11)==0,
        "raw_KeyUp_default_first_m_real_ACK");
    before=originalKeyUpContextCalls;
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51 &&
        retained.event==up && retained.originalDefaultDispatched && retained.phase==2 &&
        originalKeyUpContextCalls-before==ordinaryUp &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"FGHImnJ"] &&
        cjgui_internal_renderer_claim_last_pumped_range(token,402,1,b.candidate.bindingEpoch,
            ctx.composableSceneVersion,&intent)==0 && cjgui_internal_renderer_ack_installed_range(token,&intent,1,12)==0,
        "raw_KeyUp_default_once_matches_unheld_route_without_invented_inputContext_interpretation");
    for(int i=0;i<3;i++)CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0,
        "raw_KeyUp_duplicate_pumps_never_default_dispatch_again");
    CHECK(originalKeyUpContextCalls-before==ordinaryUp && ctx.retainedAfterCaretInputBytes==0,
        "raw_KeyUp_default_exact_original_released_once_after_real_prefix");
    CjguiReleaseSession(token);
}

#ifndef CJGUI_ORIGINAL_KEY_CUSTODY_NO_MAIN
int main(void) {
    @autoreleasepool {
        setenv("CJGUI_CANDIDATE_FIRST_FAILURE","1",1);
        setenv("CJGUI_COMMAND_ORIGIN_TRACE","1",1);
        [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        CHECK(device!=nil,"raw_command_real_Metal_device");
        Method insert=class_getInstanceMethod(CJGuiInternalComposableInputHost.class,@selector(insertText:replacementRange:));
        Method handle=class_getInstanceMethod(NSTextInputContext.class,@selector(handleEvent:));
        originalHostInsertIMP=method_setImplementation(insert,(IMP)OriginalHostInsert);
        originalContextHandleIMP=method_setImplementation(handle,(IMP)OriginalContextHandle);
        if(device) {
            OriginalKeyBeforeAdmission(device);
            originalQueueBeforePump=YES;OriginalKeyBeforeAdmission(device);originalQueueBeforePump=NO;
            useActualAccessibilityPress=YES;OriginalKeyBeforeAdmission(device);useActualAccessibilityPress=NO;
            originalCallbackFault=1;OriginalKeyBeforeAdmission(device);
            publicationBeforeCompletion=YES;OriginalKeyBeforeAdmission(device);publicationBeforeCompletion=NO;
            reenterThirdOriginal=YES;OriginalKeyBeforeAdmission(device);
            for(int fault=0;fault<=16;fault++)OriginalCommandNegative(device,fault);
            OriginalCommandCapacityAndClose(device);
            ExplicitInstallationPublicationBoundary(device);
            MultipleRawTerminalBoundary(device,NO);
            MultipleRawTerminalBoundary(device,YES);
            MultipleRawTerminalBoundary(device,2);
            MultipleRawTerminalBoundary(device,3);
            OriginalRangeAckInstallationPrefix(device);
            RetainedKeyUpUsesOriginalDefaultRoute(device);
        }
        method_setImplementation(insert,originalHostInsertIMP);
        method_setImplementation(handle,originalContextHandleIMP);
    }
    fprintf(stderr,"raw_command_result failures=%d\n",failures);
    return failures ? 1 : 0;
}

#endif
