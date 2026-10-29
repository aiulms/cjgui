// Real staged/present/AppKit input path; only the existing pending seam is controlled.
#define CJGUI_INTERNAL_TESTING 1
#define main previousSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main
#undef CHECK
#define CHECK(c,n) do { BOOL ok=(c); fprintf(stderr,"modal_return case=%s result=%s\n",n,ok?"PASS":"FAIL"); if(!ok) failures++; } while(0)

// Allocate a real AppKit window number even while hidden. The reused Metal
// fixture normally defers its backing window; an NSEvent for window -1 has no
// destination and is not evidence about the application's input route.
@interface ModalReturnWindow : NSWindow
@end
@interface ExitGapWindow : CJGuiInternalWindow
@end
@implementation ExitGapWindow
- (instancetype)initWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style
    backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    return [super initWithContentRect:rect styleMask:style backing:backing defer:NO];
}
- (BOOL)canBecomeKeyWindow { return YES; }
@end
static Class ModalOriginalWindowClass;
@implementation ModalReturnWindow
- (instancetype)initWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style
    backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    return [super initWithContentRect:rect styleMask:style backing:backing defer:NO];
}
- (BOOL)canBecomeKeyWindow { return YES; }
@end
static CJGuiInternalComposableSceneNode *Field(CJGuiInternalSession *ctx,NSUInteger index,uint64_t id,
    uint64_t version,NSString *body) {
    CJGuiInternalComposableSceneNode *n=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[index],(uint32_t)index,version);
    CjguiInternalRendererComposableNode raw=n.node;raw.nodeId=id;raw.resourceId=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;raw.projectionVersion=version;
    raw.x=20;raw.y=20+index*100;raw.width=400;raw.height=40;
    raw.clipX=0;raw.clipY=0;raw.clipWidth=680;raw.clipHeight=500;raw.semanticIncarnation=0;
    n.node=raw;n.value=body;return n;
}
static CJGuiInternalSession *ModalFixture(id<MTLDevice> device) {
    ProductionFixtureWindowClass=ModalOriginalWindowClass ?: ModalReturnWindow.class;
    CJGuiInternalSession *ctx=ProductionFixture(device);if(!ctx)return nil;
    if([ctx.window isKindOfClass:CJGuiInternalWindow.class])((CJGuiInternalWindow *)ctx.window).cjguiSession=ctx;
    [ctx.window makeKeyWindow];
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    uint64_t token=ctx.rendererSessionToken;
    if(cjgui_internal_renderer_configure_composable_scene(token,2,2)!=0)return nil;
    ctx.stagedComposableNodes[0]=Field(ctx,0,401,2,@"邮件");
    ctx.stagedComposableNodes[1]=Field(ctx,1,402,2,@"");
    if(CjguiCommitComposableSceneOnMain(token)!=0)return nil;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionNodeId=401;ctx.ownedTextSessionNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    ctx.ownedTextSessionResourceId=1;ctx.ownedTextSessionBindingEpoch=81;
    if(![ctx.composableSceneOverlay focusCommittedNodeId:402])return nil;
    [ctx.pendingInteractions removeAllObjects];return ctx;
}
static void CloseCandidate(CJGuiInternalSession *ctx,uint64_t version,BOOL keepQuery) {
    uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,version,keepQuery?2:1)==0,"candidate_configured");
    ctx.stagedComposableNodes[0]=Field(ctx,0,401,version,@"邮件");
    if(keepQuery)ctx.stagedComposableNodes[1]=Field(ctx,1,402,version,@"");
    CHECK(cjgui_internal_renderer_stage_window_background(token,version,0,1)==0,"candidate_background");
}
static CjguiInternalRendererStatus StageAt(CJGuiInternalSession *ctx,uint64_t id,uint64_t scene,uint64_t preparation) {
    uint64_t w[16]={id,scene,2,81,401,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,0,2,1,0,1,1,1,0,preparation};
    return cjgui_internal_renderer_stage_modal_return(ctx.rendererSessionToken,w,"邮件");
}
static CjguiInternalRendererStatus Stage(CJGuiInternalSession *ctx,uint64_t id) {
    return StageAt(ctx,id,3,73);
}
static void OneKey(CJGuiInternalSession *ctx,uint64_t scene) {
    CHECK(CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay) &&
        ctx.composableSceneOverlay.activeNodeId==401 &&
        NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange,NSMakeRange(0,2)),
        "actual_host_and_original_selection_before_any_owner_setter");
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagShift timestamp:1 windowNumber:ctx.window.windowNumber context:nil
        characters:@"Z" charactersIgnoringModifiers:@"z" isARepeat:NO keyCode:6];
    [ctx.window sendEvent:key];
    NSUInteger edits=0;CJGuiInternalQueuedInteraction *edit=nil;
    for(CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
        if(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED){edits++;edit=q;}
    fprintf(stderr,"modal_key_facts key_window=%d event_window=%d actual_host=%d active=%llu edits=%lu queue=%lu range=%u:%u binding=%llu text=%s proxy=%s\n",
        ctx.app.keyWindow==ctx.window,key.window==ctx.window,CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),
        (unsigned long long)ctx.composableSceneOverlay.activeNodeId,(unsigned long)edits,(unsigned long)ctx.pendingInteractions.count,
        edit.selectionStart,edit.selectionEnd,(unsigned long long)edit.bindingEpoch,edit.formText.UTF8String ?: "nil",
        ctx.composableSceneOverlay.inputProxy.string.UTF8String ?: "nil");
    CHECK(edits==1 && edit.nodeId==401 && edit.resourceId==1 && edit.projectionVersion==scene && edit.bindingEpoch==0 &&
        edit.selectionStart==0 && edit.selectionEnd==2 && [edit.formText isEqualToString:@"Z"] &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"Z"],
        "one_original_NSWindow_key_produces_one_exact_kind51");
}
static void Success(id<MTLDevice> device,BOOL pending) {
    CJGuiInternalSession *ctx=ModalFixture(device);CHECK(ctx!=nil,"normal_AppKit_fixture");if(!ctx)return;
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,7)==0,"return_staged_without_touching_query");
    CHECK(ctx.composableSceneVersion==2 && ctx.composableSceneOverlay.activeNodeId==402 &&
        CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),"prepare_keeps_accepted_query_and_host");
    CjguiInternalRendererFrameObservation frame={0};
    if(pending)CHECK(cjgui_internal_renderer_test_hold_next_composable_present(ctx.rendererSessionToken)==0,"hold_present_once");
    CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    if(pending){
        CHECK(st==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING && ctx.composableSceneVersion==2 &&
            ctx.composableSceneOverlay.activeNodeId==402 && ctx.stagedModalReturn!=nil,"pending_keeps_same_intent_and_old_proxy");
        st=cjgui_internal_renderer_test_resolve_pending_composable_present(ctx.rendererSessionToken);
    }
    CHECK((st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.composableSceneVersion==3,"same_present_accepted");
    OneKey(ctx,3); // no Cangjie acceptance, focus or selection call intervenes
    uint64_t fact[19]={0};CHECK(cjgui_internal_renderer_modal_return_receipt(ctx.rendererSessionToken,3,7,fact)==0 &&
        fact[0]==7 && fact[4]==401 && fact[7]==0 && fact[8]==2 && fact[16]==0 && fact[17]==1,
        "immutable_receipt_still_matches_original_request_after_native_edit");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static void RebuildSameRequest(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ModalFixture(device);CHECK(ctx!=nil,"rebuild_fixture");if(!ctx)return;
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,17)==0,"first_carrier_staged");
    NSEvent *query=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagShift timestamp:1 windowNumber:ctx.window.windowNumber context:nil
        characters:@"R" charactersIgnoringModifiers:@"r" isARepeat:NO keyCode:15];
    [ctx.window sendEvent:query];
    CHECK(ctx.pendingInteractions.count>0 && ctx.composableSceneVersion==2 &&
        ctx.composableSceneOverlay.activeNodeId==402,"native_input_arrives_before_close_commit");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(ctx.rendererSessionToken)==0 &&
        !ctx.stagedModalReturn && ctx.composableSceneOverlay.activeNodeId==402,"only_unsubmitted_carrier_retired");
    [ctx.pendingInteractions removeAllObjects]; // owner consumed the original query event
    CloseCandidate(ctx,4,NO);CHECK(StageAt(ctx,17,4,74)==0,"same_logical_request_new_scene_and_preparation");
    uint64_t fact[19]={0};
    CHECK(cjgui_internal_renderer_modal_return_receipt(ctx.rendererSessionToken,3,17,fact)!=0,
        "rolled_back_carrier_has_no_receipt");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    CHECK((st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.composableSceneVersion==4,
        "rebuilt_carrier_accepted");
    OneKey(ctx,4);
    CHECK(cjgui_internal_renderer_modal_return_receipt(ctx.rendererSessionToken,4,17,fact)==0 &&
        fact[15]==74 && fact[16]==0 && fact[17]==1,"new_carrier_receipt_after_original_key");
    (void)cjgui_internal_renderer_cancel_composable_preparation(ctx.rendererSessionToken,73);
    CHECK(cjgui_internal_renderer_modal_return_receipt(ctx.rendererSessionToken,4,17,fact)==0 && fact[17]==1,
        "late_old_cancel_cannot_overwrite_installed");
    CjguiReleaseSession(ctx.rendererSessionToken);

    ctx=ModalFixture(device);CHECK(ctx!=nil,"rebind_fixture");if(!ctx)return;
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,18)==0,"before_rebind_staged");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(ctx.rendererSessionToken)==0,"before_rebind_cancelled");
    ctx.ownedTextSessionBindingEpoch=82;
    CloseCandidate(ctx,4,NO);
    CHECK(StageAt(ctx,18,4,74)!=0 && ctx.composableSceneVersion==2 &&
        ctx.composableSceneOverlay.activeNodeId==402,"rebind_refuses_same_request_and_preserves_accepted");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static void RefuseAndCancel(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ModalFixture(device);CHECK(ctx!=nil,"refusal_fixture");if(!ctx)return;
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,9)==0,"refusal_candidate_has_return");
    ctx.stagedComposableNodes[0].value=@"different";
    CjguiInternalRendererFrameObservation frame={0};
    CHECK(CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame)!=0 &&
        ctx.composableSceneVersion==2 && ctx.composableSceneOverlay.activeNodeId==402 &&
        CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay) && !ctx.stagedModalReturn,
        "invalid_body_rejects_before_publish_and_preserves_old_query");
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,10)==0,"cancel_candidate_has_return");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(ctx.rendererSessionToken)==0 &&
        !ctx.stagedModalReturn,"cancel_retires_return_intent");
    CloseCandidate(ctx,4,YES);CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    CHECK((st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.composableSceneOverlay.activeNodeId==402,
        "unrelated_accepted_scene_does_not_execute_cancelled_return");
    uint64_t fact[19]={0};CHECK(cjgui_internal_renderer_modal_return_receipt(ctx.rendererSessionToken,3,10,fact)!=0,
        "cancel_has_no_installation_receipt");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static void InstallFailure(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ModalFixture(device);CHECK(ctx!=nil,"install_failure_fixture");if(!ctx)return;
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,12)==0,"OS_failure_return_staged");
    setenv("CJGUI_SELECTION_RESTORE_REFUSE_ONCE","1",1);
    CjguiInternalRendererFrameObservation frame={0};CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    unsetenv("CJGUI_SELECTION_RESTORE_REFUSE_ONCE");uint64_t fact[19]={0};
    CHECK((st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.composableSceneVersion==3 &&
        cjgui_internal_renderer_modal_return_receipt(ctx.rendererSessionToken,3,12,fact)==0 &&
        fact[16]!=0 && fact[17]==0 && !CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay),
        "accepted_frame_and_failed_OS_install_are_distinct_without_wrong_input_owner");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static void OrdinaryFieldCaret(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ModalFixture(device);CHECK(ctx!=nil,"ordinary_field_fixture");if(!ctx)return;
    ctx.ownedTextSessionEnabled=YES;
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:401],"ordinary_field_focused");
    [ctx.pendingInteractions removeAllObjects];
    [ctx.composableSceneOverlay.inputProxy selectAll:nil];
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:1 windowNumber:ctx.window.windowNumber context:nil
        characters:@"\177" charactersIgnoringModifiers:@"\177" isARepeat:NO keyCode:51];
    [ctx.window sendEvent:key];
    NSUInteger deletes=0;CJGuiInternalQueuedInteraction *deletion=nil;
    for(CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
        if(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED){deletes++;deletion=q;}
    CHECK(deletes==1 && deletion.nodeId==401 && deletion.resourceId==1 &&
        deletion.projectionVersion==2 && deletion.inputSequence==0 && !deletion.caretInputBranch &&
        deletion.selectionStart==0 && deletion.selectionEnd==2 && !deletion.formText.length &&
        !ctx.composableSceneOverlay.inputProxy.string.length,
        "ordinary_single_line_delete_uses_exact_TextKit_range_without_installed_source_claim");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static NSEvent *ExitKey(CJGuiInternalSession *ctx,unsigned short code,NSString *text) {
    return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:1 windowNumber:ctx.window.windowNumber context:nil
        characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:code];
}
static CJGuiInternalSession *ExitFixtureMode(id<MTLDevice> device,BOOL buttonSource) {
    ModalOriginalWindowClass=ExitGapWindow.class;
    CJGuiInternalSession *ctx=ModalFixture(device);CHECK(ctx!=nil,"exit_gap_fixture");if(!ctx)return nil;
    ModalOriginalWindowClass=Nil;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];[NSApp activateIgnoringOtherApps:YES];
    [ctx.window makeKeyAndOrderFront:nil];[ctx.window makeKeyWindow];
    NSDate *keyDeadline=[NSDate dateWithTimeIntervalSinceNow:3];
    while(NSApp.keyWindow!=ctx.window && keyDeadline.timeIntervalSinceNow>0) {
        NSEvent *startup=[NSApp nextEventMatchingMask:NSEventMaskAny
            untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01] inMode:NSDefaultRunLoopMode dequeue:YES];
        if(startup)[NSApp sendEvent:startup];
    }
    CHECK(NSApp.keyWindow==ctx.window,"actual_modal_exit_key_window");
    CJGuiInternalComposableSceneNode *query=ctx.composableNodes[1];
    CjguiInternalRendererComposableNode raw=query.node;raw.inputScope=42;
    if(buttonSource)raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    query.node=raw;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.composableNodes];
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:402],"exit_query_focused");
    [ctx.composableSceneOverlay.inputProxy setString:@"11"];
    [ctx.composableSceneOverlay.inputProxy setSelectedRange:NSMakeRange(2,0)];
    [ctx.pendingInteractions removeAllObjects];
    CJGuiInternalComposableCommandMenuItem *command=[CJGuiInternalComposableCommandMenuItem new];
    command.commandId=@"exit-fixture";command.shortcut=@"shortcut:escape";command.enabled=YES;
    command.focusScope=42;command.declarationToken=91;command.targetNodeId=402;
    command.targetResourceId=1;command.targetNodeKind=query.node.nodeKind;
    ctx.composableCommandMenuItems=[NSMutableArray arrayWithObject:command];ctx.composableCommandMenuVersion=2;
    return ctx;
}
static CJGuiInternalSession *ExitFixture(id<MTLDevice> device) {return ExitFixtureMode(device,NO);}
static uint64_t DequeueExit(CJGuiInternalSession *ctx) {
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event)==0 && event.kind==34,
        "original_escape_dequeued_once");
    uint64_t identity=0;
    CHECK(cjgui_internal_renderer_modal_exit_interaction(ctx.rendererSessionToken,&identity)==0 && identity,
        "exit_identity_comes_from_actual_dequeue");return identity;
}
static void ExitInputGaps(id<MTLDevice> device,BOOL afterStage,BOOL buttonSource) {
    CJGuiInternalSession *ctx=ExitFixtureMode(device,buttonSource);if(!ctx)return;
    CHECK(CjguiInputProxyIsFirstResponder(ctx.composableSceneOverlay)!=buttonSource,
        "fixture_actual_modal_responder_matches_query_or_return_button");
    [ctx.window sendEvent:ExitKey(ctx,53,@"\033")];
    CHECK(ctx.pendingInteractions.firstObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_WINDOW_COMMAND,
        "original_escape_enqueued_as_declared_kind34");
    uint64_t identity=0;
    CjguiInternalRendererFrameObservation frame={0};
    if(afterStage){
        identity=DequeueExit(ctx);
        CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,29,"accepted")==0,"exit_accepted_before_key");
        CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,29)==0,"exit_gap_stage");
        CHECK(cjgui_internal_renderer_test_hold_next_composable_present(ctx.rendererSessionToken)==0 &&
            CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame)==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING,
            "actual_install_pending_before_original_key");
    }
    NSEvent *original=ExitKey(ctx,7,@"x");[ctx.window sendEvent:original];
    CHECK(ctx.pendingInteractions.lastObject.originalCommandKey.event==original,
        "original_key_is_really_retained_before_old_query_or_return_button_interprets_it");
    CHECK([ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"],afterStage ?
        "accepted_exit_pending_install_keeps_query_11" : "enqueued_exit_before_owner_keeps_query_11");
    if(!afterStage){identity=DequeueExit(ctx);
        CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,29,"accepted")==0,"exit_accepted_after_queued_key");
        CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,29)==0,"exit_gap_stage");}
    CjguiInternalRendererStatus st=afterStage ? cjgui_internal_renderer_test_resolve_pending_composable_present(ctx.rendererSessionToken)
        : CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    CHECK((st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.composableSceneVersion==3,
        "this_exit_successors_do_not_block_own_installation");
    CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,3,29,"installed")==0,
        "common_confirmation_names_actual_return_install");
    CHECK(CjguiMaterializeOriginalCommandKeyAtHead(ctx),"original_key_first_system_interpretation");
    NSUInteger edits=0;
    for(CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
        if(q.kind==51 && q.nodeId==401 && [q.formText isEqualToString:@"x"])edits++;
    CHECK(edits==1 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"x"] &&
        ctx.retainedAfterCaretInputBytes==0 && !ctx.modalExitInput,"one_original_x_to_returned_owner_and_no_custody_leak");
    CjguiReleaseSession(ctx.rendererSessionToken);
    [ctx.window orderOut:nil];[ctx.window close];
}
static void ExitTextBeforeFollowingSave(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ExitFixture(device);if(!ctx)return;
    [ctx.window sendEvent:ExitKey(ctx,53,@"\033")];
    [ctx.window sendEvent:ExitKey(ctx,25,@"9")];
    NSEvent *save=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand timestamp:3 windowNumber:ctx.window.windowNumber context:nil
        characters:@"s" charactersIgnoringModifiers:@"s" isARepeat:NO keyCode:1];
    [ctx.window sendEvent:save];
    uint64_t identity=DequeueExit(ctx);
    CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,79,"accepted")==0,
        "batch_exit_accepted_with_original_text_and_save_waiting");
    CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,79)==0,"batch_exit_return_stage");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    CHECK(st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED,"batch_exit_return_installed");
    CJGuiInternalComposableCommandMenuItem *command=[CJGuiInternalComposableCommandMenuItem new];
    command.commandId=@"save-fixture";command.shortcut=@"shortcut:command+s";command.enabled=YES;
    command.focusScope=0;command.declarationToken=92;command.targetNodeId=401;
    command.targetResourceId=1;command.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    ctx.composableCommandMenuItems=[NSMutableArray arrayWithObject:command];ctx.composableCommandMenuVersion=3;
    CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,3,79,"installed")==0,
        "batch_exit_actual_return_confirmed");
    NSString *owner=@"邮件",*applied=nil;NSUInteger edits=0,saves=0;
    for(unsigned i=0;ctx.pendingInteractions.count && i<16;i++) {
        CJGuiInternalQueuedInteraction *q=ctx.pendingInteractions.firstObject;
        if(q.originalCommandKey) {
            BOOL advanced=CjguiMaterializeOriginalCommandKeyAtHead(ctx);
            CHECK(advanced,"batch_next_original_materializes_once");if(!advanced)break;
        } else {
            if(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED) {
                NSRange range=NSMakeRange(q.selectionStart,q.selectionEnd-q.selectionStart);
                CHECK(NSMaxRange(range)<=owner.length,"batch_delta_addresses_original_owner");
                if(NSMaxRange(range)<=owner.length)owner=[owner stringByReplacingCharactersInRange:range withString:q.formText];
                edits++;
            } else if(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_WINDOW_COMMAND &&
                [q.formText isEqualToString:@"shortcut:command+s"]) {applied=[owner copy];saves++;}
            [ctx.pendingInteractions removeObjectAtIndex:0];
        }
    }
    CHECK(edits==1 && saves==1 && [owner isEqualToString:@"9"] && [applied isEqualToString:@"9"],
        "original_text_owner_edit_precedes_following_save_without_replay_or_wait");
    CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
}
static void CoalescingKeepsProducerIdentity(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ExitFixture(device);if(!ctx)return;
    CjguiOriginalCommandKey *producer=[CjguiOriginalCommandKey new];
    producer.dependency=CjguiOriginalKeyModalExit;producer.phase=1;
    id invocation=[NSObject new];ctx.interpretingOriginalCommandKey=producer;
    ctx.materializationInvocation=invocation;ctx.callbackProductionInvocation=invocation;
    CHECK(CjguiEnqueueComposableInteraction(ctx,33,0,@"邮件",NSMakeRange(0,0)),"producer_selection_admitted");
    CJGuiInternalQueuedInteraction *first=ctx.pendingInteractions.lastObject;
    ctx.callbackProductionInvocation=nil;
    CHECK(CjguiEnqueueComposableInteraction(ctx,33,0,@"邮件",NSMakeRange(1,0)),"independent_selection_admitted");
    CHECK(ctx.pendingInteractions.count==2 && first.inputProductionInvocation==invocation &&
        first.selectionStart==0 && !ctx.pendingInteractions.lastObject.inputProductionInvocation,
        "independent_notification_cannot_coalesce_into_an_original_key_product");
    ctx.interpretingOriginalCommandKey=nil;ctx.materializationInvocation=nil;
    CHECK(CjguiEnqueueComposableInteraction(ctx,33,0,@"邮件",NSMakeRange(2,0)) &&
        ctx.pendingInteractions.count==2 && ctx.pendingInteractions.lastObject.selectionStart==2,
        "ordinary_same_producer_notifications_keep_existing_coalescing");
    CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
}
static void OpeningInputGap(id<MTLDevice> device,BOOL menuRoute,BOOL equivalentInput) {
    CJGuiInternalSession *ctx=ExitFixture(device);if(!ctx)return;
    CJGuiInternalComposableCommandMenuItem *command=ctx.composableCommandMenuItems.firstObject;
    command.commandId=@"open-fixture";command.shortcut=@"shortcut:command+k";
    NSEvent *open=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand timestamp:2 windowNumber:ctx.window.windowNumber context:nil
        characters:@"k" charactersIgnoringModifiers:@"k" isARepeat:NO keyCode:40];
    if(menuRoute) {
        command.menuGroup=@"File";command.title=@"Open fixture";
        objc_setAssociatedObject(ctx.window,&CJGuiSessionWindowAssociationKey,ctx,OBJC_ASSOCIATION_ASSIGN);
        NSMenu *menu=[[NSMenu alloc] initWithTitle:@"File"];
        NSMenuItem *item=[[NSMenuItem alloc] initWithTitle:@"Open" action:@selector(invokeComposableCommand:) keyEquivalent:@"k"];
        item.target=[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher];item.representedObject=@"open-fixture";
        [menu addItem:item];CjguiCaptureComposableMenuCommandSources(menu,open);
        [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher] invokeComposableCommand:item];
    } else [ctx.window sendEvent:open];
    if(equivalentInput) {
        NSEvent *first=ExitKey(ctx,18,@"1"),*second=ExitKey(ctx,18,@"1");
        CHECK([ctx.composableSceneOverlay performKeyEquivalent:first] &&
            ctx.pendingInteractions.lastObject.originalCommandKey.event==first,
            "AppKit_key_equivalent_entry_retains_first_original_before_default_responder");
        CHECK([ctx.composableSceneOverlay performKeyEquivalent:second] &&
            ctx.pendingInteractions.lastObject.originalCommandKey.event==second,
            "AppKit_key_equivalent_entry_retains_second_original_in_same_FIFO");
    } else { [ctx.window sendEvent:ExitKey(ctx,18,@"1")];[ctx.window sendEvent:ExitKey(ctx,18,@"1")]; }
    CHECK(ctx.modalExitInput && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"],
        menuRoute?"accepted_native_menu_open_keeps_successors_out_of_old_field":"accepted_open_keeps_successor_keys_out_of_old_field");
    if(ctx.modalExitInput) {
        uint64_t identity=0;
        if(menuRoute) {
            CjguiInternalRendererEvent e={0};
            CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&e)==0 &&
                e.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_MENU_COMMAND &&
                cjgui_internal_renderer_modal_exit_interaction(ctx.rendererSessionToken,&identity)==0 && identity,
                "native_menu_layer_identity_comes_from_actual_dequeue");
        } else identity=DequeueExit(ctx);
        CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,69,"opening")==0,
            "opening_owner_decides_actual_scope_switch");
        CloseCandidate(ctx,3,YES);
        CJGuiInternalComposableSceneNode *query=ctx.stagedComposableNodes[1];
        CjguiInternalRendererComposableNode raw=query.node;raw.nodeId=403;raw.inputScope=43;
        query.node=raw;query.value=@"";
        uint64_t w[16]={69,3,2,81,403,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,
            UINT64_MAX,UINT64_MAX,3,0,0,0,0,0,73};
        CHECK(cjgui_internal_renderer_stage_modal_return(ctx.rendererSessionToken,w,"")==0,
            "opening_has_initial_text_focus_fact_without_invented_selection");
        CjguiInternalRendererFrameObservation frame={0};CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
        CHECK((st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,3,69,"installed")==0,
            "opening_initial_focus_really_installed_before_successors");
        unsigned edits=0;
        for(unsigned i=0;i<6 && edits<2;i++) {
            CjguiInternalRendererEvent e={0};
            if(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&e)==0 && e.kind==51 && e.nodeId==403)edits++;
            fprintf(stderr,"opening_original_event kind=%u node=%llu edits=%u\n",e.kind,(unsigned long long)e.nodeId,edits);
        }
        CHECK(edits==2 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"] &&
            ctx.composableSceneOverlay.activeNodeId==403 && !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes,
            "both_original_ones_reach_new_query_once_and_release_custody");
    }
    CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
}
static void FocusOnlyReturn(id<MTLDevice> device,BOOL tab) {
    CJGuiInternalSession *ctx=ExitFixture(device);if(!ctx)return;
    [ctx.window sendEvent:ExitKey(ctx,53,@"\033")];
    uint64_t identity=DequeueExit(ctx);
    NSEvent *original=ExitKey(ctx,tab?48:36,tab?@"\t":@"\r");[ctx.window sendEvent:original];
    CHECK(ctx.pendingInteractions.lastObject.originalCommandKey.event==original,"focus_only_holds_original_first_action");
    NSEvent *followingTab=nil;
    if(!tab) {followingTab=ExitKey(ctx,48,@"\t");[ctx.window sendEvent:followingTab];}
    CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,59,"accepted")==0,
        "focus_only_exit_decided");
    CloseCandidate(ctx,3,NO);
    CJGuiInternalComposableSceneNode *button=ctx.stagedComposableNodes[0];
    CjguiInternalRendererComposableNode raw=button.node;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    button.node=raw;
    // mode 2 is a focus-only completion. There is no selection range or
    // owner text ticket; UINT64_MAX must never be interpreted as 0:0.
    uint64_t w[16]={59,3,2,81,401,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        UINT64_MAX,UINT64_MAX,2,0,0,0,0,0,73};
    CjguiInternalRendererStatus stage=cjgui_internal_renderer_stage_modal_return(ctx.rendererSessionToken,w,"");
    CHECK(stage==0,"nontext_candidate_accepts_focus_only_without_fake_text_range");
    if(stage==0) {
        CjguiInternalRendererFrameObservation frame={0};CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
        CHECK(st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED,"focus_only_present_accepted");
        CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,3,59,"installed")==0,
            "focus_only_confirmation_requires_actual_nontext_install");
        CHECK(CjguiMaterializeOriginalCommandKeyAtHead(ctx),"focus_only_original_action_interpreted_once");
        NSUInteger count=0;
        for(CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
            if(tab ? q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS :
                (q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE && q.nodeId==401))count++;
        if(!tab && count==1 && ctx.modalExitInput) {
            // Enter itself is a new actual activation. Its independent layer
            // decision must be settled by the owner before judging leakage.
            CjguiInternalRendererEvent e={0};uint64_t next=0;
            for(unsigned i=0;i<4;i++) {
                CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&e)==0,"returned_button_ordered_native_event");
                if(e.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE)break;
            }
            CHECK(e.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE && e.nodeId==401 &&
                cjgui_internal_renderer_modal_exit_interaction(ctx.rendererSessionToken,&next)==0 && next &&
                cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,next,0,0,"activation_keeps_scope")==0,
                "returned_button_Enter_has_its_own_real_owner_decision");
            CHECK(ctx.pendingInteractions.firstObject.originalCommandKey.event==followingTab &&
                CjguiMaterializeOriginalCommandKeyAtHead(ctx),
                "Enter_boundary_preserves_following_original_Tab_until_next_owner_decision");
        }
        CHECK(count==1 && !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes,
            tab?"returned_button_first_Tab_is_not_retired":"returned_button_first_Enter_activates_once");
    }
    CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
}
static void ExitBoundaries(id<MTLDevice> device) {
    for(unsigned boundary=0;boundary<9;boundary++) {
        // The existing refusal injection is once per numeric native token.
        // Keep token 1 occupied so this case gets a genuinely unused token.
        CJGuiInternalSession *guard=boundary==3 ? ModalFixture(device) : nil;
        CJGuiInternalSession *ctx=ExitFixture(device);if(!ctx)continue;
        if(boundary==0) {
            [ctx.composableSceneOverlay.inputProxy setMarkedText:@"ni" selectedRange:NSMakeRange(2,0)
                replacementRange:NSMakeRange(NSNotFound,0)];
            [ctx.window sendEvent:ExitKey(ctx,53,@"\033")];
            CHECK(!ctx.modalExitInput,"marked_escape_stays_with_system_composition_and_does_not_arm_exit");
        } else {
            [ctx.window sendEvent:ExitKey(ctx,53,@"\033")];uint64_t identity=DequeueExit(ctx);
            NSEvent *x=ExitKey(ctx,7,@"x");[ctx.window sendEvent:x];
            CjguiModalExitInput *exit=ctx.modalExitInput;
            if(boundary==1) {
                CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,0,0,"declined")==0 &&
                    CjguiMaterializeOriginalCommandKeyAtHead(ctx) &&
                    [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11x"] &&
                    !ctx.modalExitInput && ctx.retainedAfterCaretInputBytes==0,
                    "declined_exit_first_interprets_original_key_once_in_same_query");
            } else if(boundary==2 || boundary==3) {
                CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,39,"accepted")==0,"boundary_exit_accepted");
                CloseCandidate(ctx,3,NO);CHECK(Stage(ctx,39)==0,"boundary_first_carrier");
                if(boundary==2) {
                    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(ctx.rendererSessionToken)==0 &&
                        ctx.modalExitInput==exit && exit.request==39,"carrier_cancel_preserves_same_logical_exit_and_original_key");
                    CloseCandidate(ctx,4,NO);CHECK(StageAt(ctx,39,4,74)==0,"boundary_rebuilt_carrier");
                } else setenv("CJGUI_SELECTION_RESTORE_REFUSE_ONCE","1",1);
                CjguiInternalRendererFrameObservation frame={0};CjguiInternalRendererStatus st=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
                unsetenv("CJGUI_SELECTION_RESTORE_REFUSE_ONCE");
                CHECK(st==0||st==CJGUI_INTERNAL_RENDERER_READBACK_FAILED,"boundary_candidate_accepted");
                if(boundary==2) {
                    (void)cjgui_internal_renderer_cancel_composable_preparation(ctx.rendererSessionToken,73);
                    CHECK(ctx.modalExitInput==exit && cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,3,39,"installed")==0 &&
                        CjguiMaterializeOriginalCommandKeyAtHead(ctx) && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"x"] &&
                        ctx.retainedAfterCaretInputBytes==0,"same_request_rebuild_and_late_old_cancel_keep_one_original_key");
                } else {
                    CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,3,39,"installed")!=0 &&
                        !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes &&
                        ![ctx.composableSceneOverlay.inputProxy.string containsString:@"x"],
                        "failed_install_has_named_zero_write_terminal_and_releases_original");
                }
            } else if(boundary==4) {
                ctx.ownedTextSessionBindingEpoch++;
                CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,1,39,"accepted")!=0 &&
                    !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes &&
                    [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"],
                    "rebound_target_cannot_receive_retained_original");
            } else if(boundary==5) {
                for(NSUInteger i=0;i<kCjguiPendingInteractionCapacity && !ctx.pendingInputQueueFullNotice;i++)
                    [ctx.window sendEvent:ExitKey(ctx,7,@"x")];
                CHECK(ctx.pendingInputQueueFullNotice && !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes &&
                    [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"],
                    "existing_FIFO_capacity_retires_uninterpreted_originals_without_leak_or_query_edit");
            } else if(boundary==6) {
                CjguiReleaseSession(ctx.rendererSessionToken);
                CHECK(!exit.chargedBytes && !ctx.retainedAfterCaretInputBytes &&
                    [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"],
                    "session_close_retires_original_dependency_without_wrong_owner_write");
            } else if(boundary==7) {
                [ctx.window sendEvent:x]; // Reentry of the same object is not another physical event.
                NSEvent *up=[NSEvent keyEventWithType:NSEventTypeKeyUp location:NSZeroPoint modifierFlags:0
                    timestamp:2 windowNumber:ctx.window.windowNumber context:nil characters:@"x"
                    charactersIgnoringModifiers:@"x" isARepeat:NO keyCode:7];
                NSEvent *repeat=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0
                    timestamp:3 windowNumber:ctx.window.windowNumber context:nil characters:@"x"
                    charactersIgnoringModifiers:@"x" isARepeat:YES keyCode:7];
                [ctx.window sendEvent:up];[ctx.window sendEvent:repeat];
                CHECK(ctx.pendingInteractions.count==3,"same_object_reentry_keyUp_and_repeat_keep_original_FIFO_identity");
                CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,0,0,"declined")==0,"repeat_scope_continues");
                NSUInteger edits=0;
                while(ctx.pendingInteractions.count) {
                    CJGuiInternalQueuedInteraction *q=ctx.pendingInteractions.firstObject;
                    if(q.originalCommandKey) {CHECK(CjguiMaterializeOriginalCommandKeyAtHead(ctx),"next_original_materializes_once");}
                    else {if(q.kind==51)edits++;[ctx.pendingInteractions removeObjectAtIndex:0];}
                }
                CHECK(edits==2 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11xx"] &&
                    !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes,"keyUp_has_no_edit_and_each_distinct_repeat_writes_once");
            } else {
                CHECK([ctx.composableSceneOverlay focusCommittedNodeId:401] &&
                    [ctx.composableSceneOverlay focusCommittedNodeId:402],"independent_focus_leaves_and_reselects_same_query");
                [ctx.composableSceneOverlay.inputProxy setString:@"11"];
                [ctx.composableSceneOverlay.inputProxy setSelectedRange:NSMakeRange(2,0)];
                CHECK(cjgui_internal_renderer_settle_modal_exit(ctx.rendererSessionToken,identity,0,0,"declined")!=0 &&
                    !ctx.modalExitInput && !ctx.retainedAfterCaretInputBytes &&
                    [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"11"],
                    "same_value_and_identity_after_independent_focus_cannot_inherit_original_key");
            }
        }
        CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
        if(guard)CjguiReleaseSession(guard.rendererSessionToken);
    }
}
int main(void){@autoreleasepool{[NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(!device)return 2;Success(device,NO);Success(device,YES);RebuildSameRequest(device);RefuseAndCancel(device);InstallFailure(device);
    OrdinaryFieldCaret(device);
    ExitInputGaps(device,NO,NO);ExitInputGaps(device,YES,NO);
    ExitInputGaps(device,NO,YES);ExitInputGaps(device,YES,YES);
    ExitTextBeforeFollowingSave(device);CoalescingKeepsProducerIdentity(device);
    FocusOnlyReturn(device,NO);FocusOnlyReturn(device,YES);
    OpeningInputGap(device,NO,NO);OpeningInputGap(device,YES,NO);OpeningInputGap(device,NO,YES);
    ExitBoundaries(device);
    fprintf(stderr,"modal_return failures=%d\n",failures);return failures?1:0;}}
