// Actual empty input -> sealed public-owner result -> original Cmd+A/Delete
// before B capture. No TESTING renderer, synthetic receipt, or input resend.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static CJGuiInternalSession *EmptyOwnerProductionFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.app = [NSApplication sharedApplication];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 680, 500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window.releasedWhenClosed = NO;
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 680, 500) session:ctx];
    ctx.composableSceneOverlay = overlay;
    ctx.window.contentView = overlay;
    for (NSUInteger index = 0; index < 3; index++) {
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 401 + index; raw.resourceId = 1; raw.projectionVersion = 1;
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        raw.x = 0; raw.y = index * 130; raw.width = 680; raw.height = 120;
        raw.clipWidth = 680; raw.clipHeight = 500; raw.fontSize = 13;
        raw.textAlpha = 1; raw.isInteractive = 1;
        node.node = raw; node.index = (uint32_t)index;
        node.value = @"";
        node.styleRunsSignature = @""; node.textTextureCacheKey = @"";
        [ctx.stagedComposableNodes addObject:node];
    }
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token || CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return nil;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled = YES;
    ctx.ownedTextSessionNodeId = 401;
    ctx.ownedTextSessionResourceId = 1;
    ctx.ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    ctx.ownedTextSessionBindingEpoch = 81;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    [ctx.pendingInteractions removeAllObjects];
    return ctx;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    CJGuiInternalSession *ctx=EmptyOwnerProductionFixture(MTLCreateSystemDefaultDevice());
    CHECK(ctx!=nil,"empty_owner_gap_actual_declared_window");if(!ctx)return 1;
    uint64_t token=ctx.rendererSessionToken,transfer=0;
    CjguiInternalInstalledRangeCandidate initial={.nonce=1501,
        .rendererSessionGeneration=ctx.sessionGeneration,.windowInstanceToken=9101,
        .bindingEpoch=81,.contextEpoch=4,.mirrorRevision=2,.ownerVersion=10,
        .installedSceneVersion=ctx.composableSceneVersion,.nodeId=401,.resourceId=1,
        .sourceStartByte=0,.sourceEndByte=0,.sourceTextUtf8=NULL,.sourceTextUtf8Length=0};
    CjguiInternalInstalledRangeReceipt first={0};
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&initial)==0 &&
        [ctx.composableSceneOverlay focusCommittedNodeId:401] &&
        cjgui_internal_renderer_installed_range_receipt(token,initial.nonce,&first)==0 &&
        cjgui_internal_renderer_installed_range_activate(token,initial.nonce,first.proxyGeneration,first.selectionRevision)==0,
        "empty_owner_gap_normal_initial_adapter_installed_and_activated");

    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0,"empty_owner_gap_initial_transfer");
    CjguiInternalSelectionTransferCandidate candidate={0};
    candidate.transferId=transfer;candidate.sourceWindowInstanceToken=9101;
    candidate.sourceOwnerVersion=10;candidate.sourceContextEpoch=4;candidate.sourceMirrorRevision=2;
    candidate.targetNodeId=401;candidate.targetResourceId=1;candidate.targetNodeKind=10;
    candidate.targetSceneVersion=ctx.composableSceneVersion;candidate.targetAnchor16=0;candidate.targetFocus16=0;
    candidate.targetBodyUtf8=(const uint8_t *)"";candidate.targetBodyUtf8Length=0;
    uint8_t bytes[65536]={0};CjguiInternalSelectionTransferReceipt receipt={0};
    uint32_t captured=cjgui_internal_renderer_selection_transfer_capture_current(token,&candidate,bytes,sizeof(bytes));
    uint32_t published=captured==0 ? cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer) : captured;
    uint32_t installed=published==0 ? cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt) : published;
    fprintf(stderr,"EMPTY_OWNER_GAP_SETUP capture=%u publish=%u install=%u actual_kind=%u basis=%u\n",
        captured,published,installed,ctx.composableSceneOverlay.activeNodeKind,ctx.installedRangeBasis!=nil);
    CHECK(installed==0,"empty_owner_gap_actual_empty_A_installed");
    if(!ctx.installedRangeBasis.hasReceipt){CjguiReleaseSession(token);return 1;}
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,"empty_owner_gap_initial_capsule_released");
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,transfer,ctx.sessionGeneration,
        a.candidate.bindingEpoch,a.proxyGeneration,a.selectionRevision,10,1,1,&needs)==0,
        "empty_owner_gap_real_A_common_publication");
    uint64_t root=0;
    CHECK(cjgui_internal_renderer_owner_handoff_begin(token,"empty-public-undo",1,
        a.candidate.windowInstanceToken,a.candidate.contextEpoch,a.candidate.bindingEpoch,10,0,0,&root)==0 &&
        cjgui_internal_renderer_owner_handoff_seal(token,root,11,2,0,4465,99)==0,
        "empty_owner_gap_public_owner_result_sealed_before_B");
    CjguiOwnerSelectionHandoff *h=ctx.ownerSelectionHandoff;
    uint64_t beforeRevision=ctx.composableSceneOverlay.installedRangeSelectionRevision;
    const char *reason="none";
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,h,&reason)==CjguiOwnerProducerOriginalA,
        "empty_owner_gap_original_A_valid_before_CmdA");
    [ctx.composableSceneOverlay.inputProxy selectAll:nil];
    fprintf(stderr,"EMPTY_OWNER_GAP_AFTER_SELECT_ALL revision_before=%llu revision_after=%llu pending=%lu root_valid=%u actual_range=%lu:%lu actual_body=%lu\n",
        (unsigned long long)beforeRevision,(unsigned long long)ctx.composableSceneOverlay.installedRangeSelectionRevision,
        (unsigned long)ctx.pendingInteractions.count,h.valid,(unsigned long)ctx.composableSceneOverlay.inputProxy.selectedRange.location,
        (unsigned long)ctx.composableSceneOverlay.inputProxy.selectedRange.length,(unsigned long)ctx.composableSceneOverlay.inputProxy.string.length);
    CHECK(h.valid && ctx.composableSceneOverlay.installedRangeSelectionRevision==beforeRevision &&
        ctx.pendingInteractions.count==1,"empty_owner_gap_original_CmdA_retained_without_local_selection_mutation");
    CHECK(CjguiOwnerHandoffProducerPhase(ctx,h,&reason)==CjguiOwnerProducerOriginalA,
        "empty_owner_gap_original_A_proof_survives_CmdA_before_B");
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:1 windowNumber:ctx.window.windowNumber context:nil
        characters:@"\x7f" charactersIgnoringModifiers:@"\x7f" isARepeat:NO keyCode:51];
    [ctx.composableSceneOverlay.inputProxy keyDown:key];
    CHECK(h.valid && ctx.ownerSelectionHandoff==h && ctx.pendingInteractions.count==2,
        "empty_owner_gap_original_Delete_keeps_same_root_and_CmdA_FIFO");
    CHECK(ctx.pendingInteractions.firstObject.inputSequence==1 &&
        ctx.pendingInteractions.lastObject.inputSequence==2 &&
        ctx.pendingInteractions.lastObject.inputPreviousSequence==1,
        "empty_owner_gap_original_two_sequences_are_contiguous");
    PreparePlainCandidate(ctx);
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node;raw.nodeId=1013;raw.nodeKind=3;raw.projectionVersion=2;
    target.node=raw;target.value=@"first\nsecond\n";ctx.stagedComposableNodes[2]=target;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"empty_owner_gap_actual_bounded_B_layout");
    uint64_t bTransfer=0;CHECK(cjgui_internal_renderer_selection_transfer_create(token,&bTransfer)==0,
        "empty_owner_gap_bound_B_created");
    CjguiInternalSelectionTransferCandidate b={0};b.transferId=bTransfer;
    b.sourceWindowInstanceToken=a.candidate.windowInstanceToken;b.sourceOwnerVersion=11;b.sourceAcceptedVersion=11;
    b.targetNodeId=1013;b.targetResourceId=1;b.targetNodeKind=3;b.targetSceneVersion=2;
    b.targetAnchor16=0;b.targetFocus16=(uint32_t)target.value.length;
    NSData *bounded=[target.value dataUsingEncoding:NSUTF8StringEncoding];
    b.targetBodyUtf8=bounded.bytes;b.targetBodyUtf8Length=(uint32_t)bounded.length;
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&b,&receipt,bytes,sizeof(bytes),
        a.candidate.contextEpoch,3,2,0)==0 &&
        cjgui_internal_renderer_owner_handoff_bind(token,root,bTransfer)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(token,bTransfer)==0,
        "empty_owner_gap_B_capture_preserves_original_root_and_A");
    uint8_t ready=0;CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,bTransfer,0,&ready)==0 && ready,
        "empty_owner_gap_B_prepares_with_both_original_selectors_held");
    CjguiInternalRendererFrameObservation frame={0};uint32_t presented=CjguiPresentComposableSceneOnMain(token,&frame);
    CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.installedRangeBasis.selectionTransferId==bTransfer && h.installedBCommitted &&
        ctx.pendingInteractions.count==2,"empty_owner_gap_real_B_commits_without_dequeuing_successors");
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==0,
        "empty_owner_gap_original_CmdA_waits_for_common_completion");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,bTransfer)==0 &&
        cjgui_internal_renderer_selection_transfer_release(token,bTransfer)==0 &&
        cjgui_internal_renderer_owner_handoff_complete(token,root,bTransfer,11,2,0,4465)==0,
        "empty_owner_gap_same_B_common_completion_after_capsule_retirement");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
        [ctx.activeCaretNavigation.formText isEqualToString:@"select_all"] && ctx.activeCaretNavigation.inputSequence==1,
        "empty_owner_gap_original_CmdA_dequeues_once_after_B");
    CjguiInstalledRangeState *actualB=ctx.installedRangeBasis;
    CHECK(cjgui_internal_renderer_finish_caret_input(token,ctx.sessionGeneration,1,0,2,
        actualB.candidate.nonce,actualB.proxyGeneration,actualB.selectionRevision,11,
        actualB.candidate.contextEpoch,actualB.candidate.windowInstanceToken)==0,
        "empty_owner_gap_original_CmdA_unchanged_boundary_confirms_once");
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==35 &&
        [ctx.activeCaretNavigation.formText isEqualToString:@"deleteBackward"] &&
        ctx.activeCaretNavigation.inputSequence==2 && ctx.activeCaretNavigation.inputPreviousSequence==1,
        "empty_owner_gap_original_Delete_dequeues_after_CmdA_without_resend");
    CjguiReleaseSession(token);return failures?1:0;
} }
