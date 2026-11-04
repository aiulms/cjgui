// Controlled production renderer boundary: no testing renderer or forged receipt.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static void OwnerCustodyFixture(id<MTLDevice> device, unsigned variant) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&receipt),"custody_actual_A_installed");
    if(!ctx || !ctx.installedRangeBasis.hasReceipt)return;
    uint64_t token=ctx.rendererSessionToken, handoff=0, transfer=0;
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,a.selectionTransferId,
        ctx.sessionGeneration,a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,10,1,1,&needs)==0,
        "custody_actual_A_receipt_published");
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"custody-fixture",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,&handoff)==0 && handoff,
        "custody_handoff_begins_before_owner_change");
    CHECK(cjgui_internal_renderer_owner_handoff_seal(token,handoff,11,2,0,0,-1)==0,
        "custody_changed_owner_choice_sealed");
    PreparePlainCandidate(ctx);
    CHECK(CjguiConfigureComposableCommandMenuOnMain(token,2,0)==0,"custody_candidate_menu");
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node; raw.nodeId=1013;raw.projectionVersion=2;
    target.node=raw; target.value=@"body after undo";ctx.stagedComposableNodes[2]=target;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"custody_actual_B_layout_ready");
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,"custody_transfer_created");
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=transfer;c.sourceWindowInstanceToken=a.candidate.windowInstanceToken;
    c.sourceOwnerVersion=11;c.sourceAcceptedVersion=11;c.targetNodeId=1013;c.targetResourceId=1;
    c.targetNodeKind=raw.nodeKind;c.targetSceneVersion=2;c.targetAnchor16=0;c.targetFocus16=0;
    NSData *bytes=[target.value dataUsingEncoding:NSUTF8StringEncoding];c.targetBodyUtf8=bytes.bytes;c.targetBodyUtf8Length=(uint32_t)bytes.length;
    uint8_t source[65536]={0}, ready=0;
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&c,&receipt,source,sizeof(source),
        a.candidate.contextEpoch,3,2,0)==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,handoff,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0 &&
        cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==0 && ready,
        "custody_real_candidate_bound_and_ready");
    // Model already-observed toolbar control identity; original source proxy and host remain real.
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    o.activeNodeId=9001;o.activeNodeResourceId=9001;o.activeNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    CHECK(CjguiInputProxyIsFirstResponder(o) && o.inputProxy==a.proxy && ctx.selectionReceiptOwnerVersion==10 &&
        ctx.ownerSelectionHandoff.valid && ctx.selectionTransferCapsule.candidateInstallReady,
        "custody_changed_control_original_A_and_host_still_owned");
    if(variant==8) {
        CHECK(CjguiSelectionTransferBeginFinalizingWithPrecheck(token,transfer)==0,
            "custody_real_finalizing_lease_acquired");
        CHECK(CjguiCandidateSelectionActualSourceReadbackMatches(ctx,ctx.selectionTransferCapsule),
            "custody_same_original_A_allowed_during_finalizing");
        CjguiReleaseSession(token);return;
    }
    if(variant==1) [o.inputProxy setString:@"tampered body"];
    if(variant==2) o.inputProxy.selectedRange=NSMakeRange(0,0);
    if(variant==3) ctx.installedRangeProxyGeneration++;
    if(variant==4) ctx.selectionReceiptOwnerRevision++;
    if(variant==5) ctx.ownedTextSessionBindingEpoch++;
    if(variant==6) ctx.ownerSelectionHandoff.transferId++;
    uint32_t admission=0;
    if(variant==7) CHECK(cjgui_internal_renderer_selection_transfer_admit_input(token,transfer,&admission)==0,"custody_real_cancel_input_admitted");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(token,&frame);
    fprintf(stderr,"CUSTODY_PRESENT status=%u scene=%llu transfer=%llu installed=%llu\n",status,
        (unsigned long long)ctx.composableSceneVersion,(unsigned long long)transfer,
        (unsigned long long)ctx.installedRangeBasis.selectionTransferId);
    if(variant) {
        CHECK(status!=0 && status!=CJGUI_INTERNAL_RENDERER_READBACK_FAILED && ctx.composableSceneVersion==1 &&
            ctx.installedRangeBasis.selectionTransferId!=transfer,"custody_changed_source_or_transfer_rejected");
    } else {
        CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            ctx.composableSceneVersion==2 && ctx.installedRangeBasis.selectionTransferId==transfer,
            "custody_ready_B_presented_and_installed");
    }
    if(!variant && ctx.installedRangeBasis.selectionTransferId==transfer) {
        CjguiInternalSelectionTransferReceipt bReceipt={0};
        CHECK(cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&bReceipt)==0,
            "custody_native_B_receipt_available");
        CHECK(cjgui_internal_renderer_owner_handoff_complete(token,handoff,transfer,11,2,0,0)==0,
            "custody_actual_handoff_completed");
    }
    CjguiReleaseSession(token);
}
int main(void) { @autoreleasepool {
    cjgui_internal_renderer_enable_main_thread_dispatch();
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 77;
    for(unsigned variant=0;variant<=8;variant++) OwnerCustodyFixture(device,variant);fprintf(stderr,"custody_failures=%d\n",failures);return failures ? 1:0;
} }
