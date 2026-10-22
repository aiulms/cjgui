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
    ProductionFixtureWindowClass=ModalReturnWindow.class;
    CJGuiInternalSession *ctx=ProductionFixture(device);if(!ctx)return nil;
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
        if(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            [q.formText isEqualToString:@"deleteBackward"]){deletes++;deletion=q;}
    CHECK(deletes==1 && deletion.nodeId==401 && deletion.resourceId==1 &&
        deletion.projectionVersion==2 && deletion.inputSequence==0 && !deletion.caretInputBranch &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"邮件"],
        "ordinary_owned_field_delete_uses_existing_plain_intent_without_installed_source_claim");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
int main(void){@autoreleasepool{[NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(!device)return 2;Success(device,NO);Success(device,YES);RebuildSameRequest(device);RefuseAndCancel(device);InstallFailure(device);
    OrdinaryFieldCaret(device);
    fprintf(stderr,"modal_return failures=%d\n",failures);return failures?1:0;}}
