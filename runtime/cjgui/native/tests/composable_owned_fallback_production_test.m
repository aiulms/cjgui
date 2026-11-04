// Real owned BEGIN, live fallback and same-candidate drawable operation.
// This fixture is compiled against the normal renderer, without TESTING.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static CjguiInternalRendererPreparationOperationResult ownedFallbackOperation(
    uint64_t session,uint64_t preparation,uint32_t kind,uint64_t *values) {
    CjguiInternalRendererPreparationOperation operation={.kind=kind,.values32=values};
    CjguiInternalRendererPreparationOperationResult result={0};
    uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(5000000000);
    CjguiInternalRendererStatus status=cjgui_internal_renderer_preparation_operation_admit(
        session,preparation,deadline,&operation,&result);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) { result.status=status; return result; }
    uint64_t nonce=result.nonce;
    while(result.state==CJGUI_PREPARATION_OPERATION_PENDING &&
          cjgui_internal_renderer_owner_clock_ns()<deadline) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.002,true);
        status=cjgui_internal_renderer_preparation_operation_poll(session,preparation,nonce,1,&result);
        if(status!=CJGUI_INTERNAL_RENDERER_OK) { result.status=status; break; }
    }
    fprintf(stderr,"OWNED_FALLBACK_OPERATION kind=%u state=%u stop=%u status=%d prefix=%u nonce=%llu\n",
        kind,result.state,result.stop,result.status,result.prefix,(unsigned long long)nonce);
    return result;
}

static BOOL installMultilineA(CJGuiInternalSession *ctx,CjguiInternalSelectionTransferReceipt *receipt) {
    uint64_t transfer=0,token=ctx.rendererSessionToken;
    if(cjgui_internal_renderer_selection_transfer_create(token,&transfer)!=0)return NO;
    NSData *body=[ctx.composableSceneOverlay.nodes[1].value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c=CaptureCandidateForTarget(ctx,transfer,1,0,body);
    c.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    c.targetAnchor16=1;c.targetFocus16=4;uint8_t actual[65536]={0};
    CjguiInternalRendererStatus status=cjgui_internal_renderer_selection_transfer_capture_current(token,&c,actual,sizeof(actual));
    if(status==0)status=cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer);
    if(status==0)status=cjgui_internal_renderer_selection_transfer_install_b(token,transfer,receipt);
    (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token,transfer);
    return status==0;
}

static void fallbackHandoffFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"fallback_handoff_session");
    if(!ctx)return;
    for(CJGuiInternalComposableSceneNode *node in ctx.composableNodes) {
        CjguiInternalRendererComposableNode raw=node.node;
        raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;node.node=raw;
    }
    ctx.ownedTextSessionNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.composableNodes];
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:401],"fallback_handoff_initial_focus");
    CjguiInternalSelectionTransferReceipt receipt={0};
    BOOL installed=installMultilineA(ctx,&receipt);
    CHECK(installed && ctx.installedRangeBasis.hasReceipt,"fallback_handoff_real_A_installed");
    if(!installed){CjguiReleaseSession(ctx.rendererSessionToken);return;}
    uint64_t session=ctx.rendererSessionToken,identity=0,preparation=42;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;uint8_t needs=0;
    CjguiInternalRendererStatus published=cjgui_internal_renderer_finish_selection_paint_publication(session,
        a.selectionTransferId,ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,
        10,1,1,&needs);
    CjguiInternalRendererStatus begun=cjgui_internal_renderer_owner_handoff_begin_with_purpose(session,
        "selection-only-fixture",1,a.candidate.windowInstanceToken,a.candidate.contextEpoch,
        a.candidate.bindingEpoch,10,0,0,CJGUI_OWNER_HANDOFF_SELECTION_ONLY,&identity);
    CHECK(published==0 && begun==0 && identity,"fallback_handoff_real_A_and_begin");
    if(published!=0 || begun!=0){CjguiReleaseSession(session);return;}
    CjguiInternalRendererStatus sealed=cjgui_internal_renderer_owner_handoff_seal(session,identity,10,2,4194370,4194370,-1);
    CHECK(sealed==0,"fallback_handoff_real_seal");
    if(sealed!=0){CjguiReleaseSession(session);return;}
    NSString *before=[ctx.composableSceneOverlay.inputProxy.string copy];
    for(NSString *text in @[@"e",@"l",@"l",@"o"])
        [ctx.composableSceneOverlay.inputProxy insertText:text replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(ctx.pendingInteractions.count==4 && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:before],
        "fallback_handoff_original_four_text_events_retained");
    NSTextView *view=ctx.composableSceneOverlay.inputProxy;
    [view.layoutManager addTemporaryAttribute:@"CJGUIFixtureUnknownAttribute" value:[NSObject new]
        forCharacterRange:NSMakeRange(0,1)];
    uint64_t values[32]={0};values[0]=ctx.composableSceneVersion;values[1]=2;values[2]=3;
    CjguiInternalRendererPreparationOperationResult first=ownedFallbackOperation(session,preparation,
        CJGUI_PREPARATION_OPERATION_BEGIN,values);
    CHECK(first.state==CJGUI_PREPARATION_OPERATION_COMPLETED && first.status==CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED,
        "fallback_handoff_begin_preserves_unsupported_source");
    cjgui_internal_renderer_preparation_operation_retire(session,preparation);
    CjguiServiceOwnedPreparationRetirement(session-1);
    PreparePlainCandidate(ctx);
    uint64_t transfer=0;uint8_t source[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_create(session,&transfer)==0,"fallback_handoff_B_created");
    CJGuiInternalComposableSceneNode *target=ctx.stagedComposableNodes[1];
    NSData *body=[target.value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;
    c.sourceOwnerVersion=10;c.sourceAcceptedVersion=10;c.targetNodeId=target.node.nodeId;c.targetResourceId=1;
    c.targetNodeKind=target.node.nodeKind;c.targetSceneVersion=2;c.targetAnchor16=1;c.targetFocus16=4;
    c.targetBodyUtf8=body.bytes;c.targetBodyUtf8Length=(uint32_t)body.length;
    CjguiInternalRendererStatus capture=cjgui_internal_renderer_capture_candidate_selection(session,&c,&receipt,source,
        sizeof(source),a.candidate.contextEpoch,3,2,0);
    CjguiInternalRendererStatus binding=capture==0 ?
        cjgui_internal_renderer_owner_handoff_bind(session,identity,transfer) : capture;
    CjguiInternalRendererStatus pending=binding==0 ?
        cjgui_internal_renderer_selection_transfer_publish_pending(session,transfer) : binding;
    uint8_t ready=0;
    CjguiInternalRendererStatus selection=pending==0 ?
        cjgui_internal_renderer_prepare_candidate_selection(session,transfer,0,&ready) : pending;
    CHECK(capture==0 && binding==0 && pending==0 && selection==0 && ready,
        "fallback_handoff_B_captured_bound_prepared");
    if(capture==0 && binding==0 && pending==0 && selection==0 && ready) {
        uint64_t drawable[32]={0};drawable[0]=2;
        CjguiInternalRendererPreparationOperationResult reserve=ownedFallbackOperation(session,preparation,
            CJGUI_PREPARATION_OPERATION_DRAWABLE,drawable);
        CHECK(reserve.status==0 && reserve.state==CJGUI_PREPARATION_OPERATION_COMPLETED && reserve.prefix==1,
            "fallback_handoff_real_drawable_ready_with_original_input");
        CHECK(ctx.pendingInteractions.count==4 && ctx.ownerSelectionHandoff.identity==identity,
            "fallback_handoff_original_events_and_identity_still_owned");
    }
    CjguiReleaseSession(session);
}

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        cjgui_internal_renderer_enable_main_thread_dispatch();
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        CHECK(device!=nil,"fallback_metal_device");
        if(!device)return 1;
        CJGuiInternalSession *ctx=ProductionFixture(device);
        CHECK(ctx!=nil,"fallback_real_session");
        if(!ctx)return 1;
        uint64_t session=ctx.rendererSessionToken,preparation=41;
        CJGuiInternalComposableSceneNode *active=ctx.composableNodes[0];
        CjguiInternalRendererComposableNode declaration=active.node;
        declaration.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        active.node=declaration;
        ctx.ownedTextSessionNodeKind=declaration.nodeKind;
        [ctx.composableSceneOverlay setNodesFromProjection:ctx.composableNodes];
        BOOL focused=[ctx.composableSceneOverlay focusCommittedNodeId:declaration.nodeId];
        CHECK(focused && CjguiPreparationLiveActiveNode(ctx)!=nil,"fallback_real_active_multiline");
        NSTextView *view=ctx.composableSceneOverlay.inputProxy;
        [view.layoutManager addTemporaryAttribute:@"CJGUIFixtureUnknownAttribute"
            value:[NSObject new] forCharacterRange:NSMakeRange(0,1)];
        CHECK(CjguiFreezeTemporaryAttributeRuns(view.layoutManager,view.textStorage.length)==nil,
            "fallback_actual_temporary_attribute_unfreezable");
        uint64_t values[32]={0};values[0]=ctx.composableSceneVersion;values[1]=2;values[2]=3;
        CjguiInternalRendererPreparationOperationResult begin=ownedFallbackOperation(session,preparation,
            CJGUI_PREPARATION_OPERATION_BEGIN,values);
        CHECK(begin.state==CJGUI_PREPARATION_OPERATION_COMPLETED &&
            begin.status==CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED,
            "fallback_real_owned_begin_refuses_credential");
        cjgui_internal_renderer_preparation_operation_retire(session,preparation);
        uint64_t drawable[32]={0};drawable[0]=2;
        CjguiInternalRendererPreparationOperation operation={.kind=CJGUI_PREPARATION_OPERATION_DRAWABLE,.values32=drawable};
        CjguiInternalRendererPreparationOperationResult blocked={0};
        CjguiInternalRendererStatus admit=cjgui_internal_renderer_preparation_operation_admit(session,preparation,
            cjgui_internal_renderer_owner_clock_ns()+UINT64_C(5000000000),&operation,&blocked);
        CHECK(admit==0 && blocked.state==CJGUI_PREPARATION_OPERATION_CAPACITY,
            "fallback_retirement_prevents_same_id_admission");
        CjguiServiceOwnedPreparationRetirement(session-1);
        PreparePlainCandidate(ctx);
        CjguiInternalRendererPreparationOperationResult reserve=ownedFallbackOperation(session,preparation,
            CJGUI_PREPARATION_OPERATION_DRAWABLE,drawable);
        CHECK(reserve.status==CJGUI_INTERNAL_RENDERER_OK &&
            reserve.state==CJGUI_PREPARATION_OPERATION_COMPLETED && reserve.prefix==1,
            "fallback_real_drawable_ticket_ready");
        CjguiInternalRendererFrameObservation frame={0};
        CjguiInternalRendererStatus presented=cjgui_internal_renderer_present_composable_scene(session,&frame);
        CHECK(presented==CJGUI_INTERNAL_RENDERER_OK || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED,
            "fallback_live_present_after_real_drawable");
        CjguiReleaseSession(session);
        fallbackHandoffFixture(device);
        fprintf(stderr,"SUMMARY failures=%d\n",failures);
        return failures ? 1 : 0;
    }
}
