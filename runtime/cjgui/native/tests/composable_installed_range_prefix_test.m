// Small E fixture. Uses real TextKit callback and FIFO, no foreground window.
#define main prior_source_install_suite_main
#import "composable_source_selection_install_test.m"
#undef main

static void InstalledRangeLargeClaimRejectFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes=[NSMutableArray array]; ctx.stagedComposableNodes=[NSMutableArray array];
    ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay=[[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    overlay.testWindow=[[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window=(NSWindow *)overlay.testWindow; ctx.composableSceneOverlay=overlay;
    overlay.inputProxy.delegate=nil;
    SourceInstallProxy *proxy=[[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    proxy.composableOverlay=overlay; proxy.delegate=overlay;
    proxy.layoutManager.allowsNonContiguousLayout=YES; proxy.layoutManager.backgroundLayoutEnabled=NO;
    overlay.inputProxy=proxy; overlay.inputScrollProxy.documentView=proxy;
    overlay.testWindow.contentView=overlay;

    NSMutableString *longText=[NSMutableString stringWithCapacity:70000];
    for (NSUInteger i=0;i<70000;i++) [longText appendString:@"a"];
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0; node.value=longText;
    node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=1; ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_large_fixture_scene_accepted");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=71; ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    NSData *largeBytes=[longText dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate basis={
        .nonce=910, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7002, .bindingEpoch=71, .contextEpoch=4,
        .mirrorRevision=2, .ownerVersion=10, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=largeBytes.length,
        .sourceTextUtf8=largeBytes.bytes, .sourceTextUtf8Length=(uint32_t)largeBytes.length,
    };
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&basis)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_large_basis_armed");
    CHECK([overlay focusCommittedNodeId:401],"installed_range_large_actual_proxy_installed");
    CjguiInternalInstalledRangeReceipt receipt={0};
    CHECK(cjgui_internal_renderer_installed_range_receipt(token,910,&receipt)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_installed_range_activate(token,910,receipt.proxyGeneration,
            receipt.selectionRevision)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_large_actual_receipt_activated");
    overlay.testWindow.testResponder=overlay.inputHost;
    CHECK(SourceInstallPerformNativeAppend(overlay,@"X",NULL,NULL,NULL) &&
        SourceInstallPerformNativeAppend(overlay,@"Y",NULL,NULL,NULL) && ctx.pendingInteractions.count==2,
        "installed_range_large_prefix_x_y_queued_once");

    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "installed_range_large_first_sideband_pumped");
    CjguiInternalInstalledRangeIntent claimed={0};
    CjguiInternalRendererStatus claimStatus=cjgui_internal_renderer_claim_last_pumped_range(token,
        401,1,71,ctx.composableSceneVersion,&claimed);
    CHECK(claimStatus==CJGUI_INTERNAL_RENDERER_OK && claimed.preBodyUtf8Length>65536u &&
        claimed.postBodyUtf8Length>65536u,
        "installed_range_large_valid_claim_exceeds_cj_window");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&claimed,0u,-1)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBasis.chainClosed,
        "installed_range_large_explicit_consumer_ack_rejection_closes_prefix");
    event=(CjguiInternalRendererEvent){0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "installed_range_large_suffix_remains_owned_kind51");
    CjguiInternalInstalledRangeIntent stale={0};
    CjguiInternalRendererStatus staleStatus=cjgui_internal_renderer_claim_last_pumped_range(token,
        401,1,71,ctx.composableSceneVersion,&stale);
    CHECK(staleStatus==CJGUI_INTERNAL_RENDERER_SCENE_STALE && stale.nonce==910 &&
        ctx.pendingInteractions.count==0 && ctx.installedRangeBytesUsed==largeBytes.length,
        "installed_range_large_suffix_stale_and_sideband_budget_released");
    ctx.ownedTextSessionBindingEpoch=72;
    cjgui_internal_renderer_set_source_install_gate(token,72,906,1);
    BOOL reboundOldBasisAllowed=[overlay textView:overlay.inputProxy
        shouldChangeTextInRange:NSMakeRange(overlay.inputProxy.string.length,0) replacementString:@"Z"];
    CHECK(!reboundOldBasisAllowed,
        "installed_range_rebound_binding_cannot_reuse_old_actual_basis");
    CHECK(cjgui_internal_renderer_release_installed_range(token,7002,71)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBasis==nil,
        "installed_range_old_binding_release_retires_basis");
    cjgui_internal_renderer_destroy(token);
}

static SourceInstallOverlay *InstalledRangeCreateActivatedFixtureAt(id<MTLDevice> device,
    NSString *text, uint64_t binding, uint64_t nonce, uint64_t windowToken, uint64_t sourceStart) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes=[NSMutableArray array]; ctx.stagedComposableNodes=[NSMutableArray array];
    ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay=[[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    overlay.testWindow=[[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window=(NSWindow *)overlay.testWindow; ctx.composableSceneOverlay=overlay;
    overlay.inputProxy.delegate=nil;
    SourceInstallProxy *proxy=[[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    proxy.composableOverlay=overlay; proxy.delegate=overlay;
    proxy.layoutManager.allowsNonContiguousLayout=YES; proxy.layoutManager.backgroundLayoutEnabled=NO;
    overlay.inputProxy=proxy; overlay.inputScrollProxy.documentView=proxy;
    overlay.testWindow.contentView=overlay;
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0; node.value=text; node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=1; ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    if(CjguiCommitComposableSceneOnMain(token)!=CJGUI_INTERNAL_RENDERER_OK) return nil;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=binding; ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate basis={
        .nonce=nonce, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=windowToken, .bindingEpoch=binding, .contextEpoch=4,
        .mirrorRevision=2, .ownerVersion=10, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=sourceStart, .sourceEndByte=sourceStart+bytes.length,
        .sourceTextUtf8=bytes.bytes, .sourceTextUtf8Length=(uint32_t)bytes.length,
    };
    if(cjgui_internal_renderer_installed_range_arm(token,&basis)!=CJGUI_INTERNAL_RENDERER_OK ||
        ![overlay focusCommittedNodeId:401]) return nil;
    CjguiInternalInstalledRangeReceipt receipt={0};
    if(cjgui_internal_renderer_installed_range_receipt(token,nonce,&receipt)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_installed_range_activate(token,nonce,receipt.proxyGeneration,
            receipt.selectionRevision)!=CJGUI_INTERNAL_RENDERER_OK) return nil;
    overlay.testWindow.testResponder=overlay.inputHost;
    [ctx.pendingInteractions removeAllObjects];
    return overlay;
}

static SourceInstallOverlay *InstalledRangeCreateActivatedFixture(id<MTLDevice> device,
    NSString *text, uint64_t binding, uint64_t nonce, uint64_t windowToken) {
    return InstalledRangeCreateActivatedFixtureAt(device,text,binding,nonce,windowToken,0);
}

static void InstalledRangeWholeChoiceFixture(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixtureAt(device,@"abc",71,990,9000,100);
    CHECK(o!=nil,"whole_choice_actual_remote_proxy_activated"); if(!o)return;
    CJGuiInternalSession *ctx=o.session; uint64_t token=ctx.rendererSessionToken;
    [o.inputProxy selectAll:nil];
    uint64_t choice=ctx.installedWholeChoiceNonce;
    CHECK(choice>0 && o.inputProxy.selectedRange.length==3 && ctx.pendingInteractions.count==0,
        "whole_choice_CmdA_feedback_has_no_partial_semantic_selection");
    [o.inputProxy insertText:@"x" replacementRange:NSMakeRange(NSNotFound,0)];
    [o.inputProxy insertText:@"y" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK([o.inputProxy.string isEqualToString:@"xy"] && ctx.pendingInteractions.count==2,
        "whole_choice_actual_TextKit_xy_two_inputs_once");
    CjguiInternalRendererEvent e={0}; CjguiInternalInstalledRangeIntent first={0},second={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,ctx.composableSceneVersion,&first)==CJGUI_INTERNAL_RENDERER_OK &&
        first.wholeChoiceNonce==choice && first.wholeChoicePreviousSeq==0 && first.sourceStartByte==100 &&
        first.seq==1 && first.previousSeq==0,"whole_choice_first_receipt_names_actual_choice_and_remote_root");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&first,1,11)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBasis.candidate.sourceStartByte==0 && ctx.installedRangeBasis.candidate.sourceEndByte==1,
        "whole_choice_real_first_ack_changes_source_origin_once");
    e=(CjguiInternalRendererEvent){0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,ctx.composableSceneVersion,&second)==CJGUI_INTERNAL_RENDERER_OK &&
        second.wholeChoiceNonce==0 && second.sourceStartByte==100 && second.observedAckSeq==0 &&
        second.seq==2 && second.previousSeq==1,
        "whole_choice_queued_suffix_preserves_true_pre_ack_installation");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&second,1,12)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBasis.candidate.sourceStartByte==0 && ctx.installedRangeBasis.candidate.sourceEndByte==2,
        "whole_choice_suffix_ack_grows_replacement_instead_of_redeleting");
    [o.inputProxy selectAll:nil]; uint64_t old=ctx.installedWholeChoiceNonce;
    NSRange same=o.inputProxy.selectedRange;
    [o.inputProxy setSelectedRange:same affinity:NSSelectionAffinityDownstream stillSelecting:NO];
    CHECK(old>choice && ctx.installedWholeChoiceNonce==0,
        "whole_choice_same_value_new_native_selection_revokes_choice");
    [ctx.pendingInteractions removeAllObjects];
    [o.inputProxy insertText:@"r" replacementRange:NSMakeRange(NSNotFound,0)];
    e=(CjguiInternalRendererEvent){0}; CjguiInternalInstalledRangeIntent local={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,ctx.composableSceneVersion,&local)==CJGUI_INTERNAL_RENDERER_OK &&
        local.wholeChoiceNonce==0 && local.sourceStartByte==0 && local.observedAckSeq==2,
        "whole_choice_new_selection_input_remains_local_with_real_ack_prefix");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&local,1,13)==CJGUI_INTERNAL_RENDERER_OK,
        "whole_choice_local_tail_ack_once");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeCoordinateLifetimeFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,640,480)
        device:device commandQueue:[device newCommandQueue]];
    ctx.view.wantsLayer=YES;
    SourceInstallOverlay *overlay=[[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,640,480) session:ctx];
    ctx.composableSceneOverlay=overlay;
    [ctx.view addSubview:overlay];
    SourceInstallWindow *window=[[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(40,50,640,480)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window=(NSWindow *)window; window.delegate=ctx; window.contentView=ctx.view;
    uint64_t token=CjguiAllocateSession(ctx),generation=0;
    uint64_t initial=cjgui_internal_renderer_coordinate_lifetime(token,&generation);
    CHECK(token!=0 && initial==1 && generation==ctx.sessionGeneration &&
        ctx.view.coordinateSessionGeneration==generation &&
        cjgui_internal_renderer_coordinate_lifetime(0,&generation)==0 && generation==0,
        "coordinate_lifetime_initial_atomic_session_tuple");

    NSPoint home=window.frame.origin;
    [window setFrameOrigin:NSMakePoint(home.x+19.0,home.y+13.0)];
    uint64_t movedAway=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    [window setFrameOrigin:home];
    uint64_t movedBack=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(movedAway>initial && movedBack>movedAway,
        "coordinate_lifetime_window_move_away_and_back_is_sticky");

    // Coordinate provenance belongs to the private FIFO entry. A later
    // move-away/back must not let dequeue-time state rewrite BEGIN's origin.
    CJGuiInternalComposableSceneNode *pointerNode=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode pointerRaw={0};
    pointerRaw.nodeId=811; pointerRaw.resourceId=3; pointerRaw.nodeKind=1;
    pointerNode.node=pointerRaw; pointerNode.index=0;
    ctx.composableNodes=[NSMutableArray arrayWithObject:pointerNode];
    ctx.composableSceneVersion=5;
    uint64_t beginEpoch=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN,pointerNode,NSMakePoint(2,3),44),
        "coordinate_queue_begin_enqueued");
    CJGuiInternalQueuedInteraction *queuedBegin=ctx.pendingInteractions.lastObject;
    CHECK(queuedBegin.coordinateSessionGeneration==ctx.sessionGeneration &&
        queuedBegin.coordinateEpoch==beginEpoch,
        "coordinate_queue_begin_captures_actual_enqueue_tuple");
    [window setFrameOrigin:NSMakePoint(home.x+7.0,home.y+9.0)];
    [window setFrameOrigin:home];
    uint64_t afterBeginABA=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(afterBeginABA>beginEpoch && queuedBegin.coordinateEpoch==beginEpoch,
        "coordinate_queue_begin_tuple_survives_move_away_back");
    CjguiInternalRendererEvent beginEvent={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&beginEvent)==CJGUI_INTERNAL_RENDERER_OK &&
        beginEvent.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN,
        "coordinate_queue_begin_pumps_after_coordinate_aba");
    uint64_t pumpedGeneration=0,pumpedEpoch=0;
    int pumpedTuple=cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(token,
        &pumpedGeneration,&pumpedEpoch);
    CHECK(pumpedTuple && pumpedGeneration==ctx.sessionGeneration && pumpedEpoch==beginEpoch,
        "coordinate_queue_pump_reports_original_begin_tuple_not_current_epoch");

    [ctx.pendingInteractions removeAllObjects];
    uint64_t queuedUpdateEpoch=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,pointerNode,
        NSMakePoint(4,5),44),"coordinate_queue_update_before_move_enqueued");
    CHECK(CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,pointerNode,
        NSMakePoint(6,7),44) && ctx.pendingInteractions.count==1,
        "coordinate_queue_same_epoch_updates_coalesce");
    CJGuiInternalQueuedInteraction *beforeMoveUpdate=ctx.pendingInteractions.firstObject;
    [window setFrameOrigin:NSMakePoint(home.x+11.0,home.y+3.0)];
    uint64_t afterQueuedUpdateMove=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,pointerNode,
        NSMakePoint(8,9),44) && ctx.pendingInteractions.count==2 &&
        beforeMoveUpdate.coordinateEpoch==queuedUpdateEpoch &&
        ctx.pendingInteractions.lastObject.coordinateEpoch==afterQueuedUpdateMove,
        "coordinate_queue_update_before_move_cannot_coalesce_across_epoch");

    uint64_t resizeBefore=cjgui_internal_renderer_coordinate_lifetime(token,NULL),resizeVersion=0;
    BOOL resized=cjgui_internal_renderer_test_resize_composable_window(token,&resizeVersion)==
        CJGUI_INTERNAL_RENDERER_OK;
    uint64_t resizeAfter=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(resized && resizeVersion>0 && resizeAfter>resizeBefore,
        "coordinate_lifetime_appkit_window_resize_callback_advances");

    uint64_t backingBefore=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    uint64_t ignoredResize=0; double beforeScale=0,afterScale=0; uint32_t drawableWidth=0,drawableHeight=0;
    BOOL backing=cjgui_internal_renderer_test_toggle_composable_backing_scale(token,&ignoredResize,
        &beforeScale,&afterScale,&drawableWidth,&drawableHeight)==CJGUI_INTERNAL_RENDERER_OK;
    uint64_t backingAfter=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(backing && beforeScale!=afterScale && drawableWidth>0 && drawableHeight>0 &&
        backingAfter>backingBefore,
        "coordinate_lifetime_appkit_backing_notification_advances");

    uint64_t viewBefore=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    [ctx.view setBoundsOrigin:NSMakePoint(0.5,0.75)];
    uint64_t metalViewAfter=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    [overlay setBoundsOrigin:NSMakePoint(1.25,2.5)];
    uint64_t viewAfter=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CJGuiInternalComposableSceneNode *scrollNode=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0}; raw.nodeId=401; raw.resourceId=1;
    scrollNode.node=raw;
    [overlay setMultilineScrollOffset:4.5 forNode:scrollNode];
    uint64_t scrollAfter=cjgui_internal_renderer_coordinate_lifetime(token,NULL);
    CHECK(metalViewAfter>viewBefore && viewAfter>metalViewAfter && scrollAfter>viewAfter,
        "coordinate_lifetime_view_transform_and_scroll_advance");

    CjguiReleaseSession(token);
    uint64_t closedGeneration=99;
    CHECK(cjgui_internal_renderer_coordinate_lifetime(token,&closedGeneration)==0 && closedGeneration==0,
        "coordinate_lifetime_close_invalidates_atomic_snapshot");
    CJGuiInternalSession *replacement=[CJGuiInternalSession new];
    uint64_t replacementToken=CjguiAllocateSession(replacement),replacementGeneration=0;
    uint64_t replacementEpoch=cjgui_internal_renderer_coordinate_lifetime(replacementToken,&replacementGeneration);
    CjguiBumpCoordinateLifetimeForIdentity(replacementToken,generation);
    uint64_t afterStaleBump=cjgui_internal_renderer_coordinate_lifetime(replacementToken,NULL);
    CHECK(replacementToken==token && replacementGeneration!=generation && replacementEpoch==1 &&
        afterStaleBump==replacementEpoch,
        "coordinate_lifetime_old_session_generation_cannot_bump_reused_slot");
    CjguiPublishMainPumpedPointerCoordinateLifetime(replacement,queuedBegin);
    uint64_t stalePumpedGeneration=99,stalePumpedEpoch=99;
    CHECK(!cjgui_internal_renderer_main_pumped_pointer_coordinate_lifetime(replacementToken,
        &stalePumpedGeneration,&stalePumpedEpoch) && stalePumpedGeneration==0 && stalePumpedEpoch==0,
        "coordinate_queue_old_session_tuple_fails_closed_after_slot_reuse");
    NSUInteger slot=(NSUInteger)(replacementToken-1);
    replacement.coordinateLifetimeGeneration=UINT64_MAX;
    atomic_store_explicit(&gCjguiCoordinateEpoch[slot],UINT64_MAX,memory_order_release);
    CjguiBumpCoordinateLifetimeForIdentity(replacementToken,replacementGeneration);
    uint64_t exhaustedGeneration=99;
    CHECK(cjgui_internal_renderer_coordinate_lifetime(replacementToken,&exhaustedGeneration)==0 &&
        exhaustedGeneration==0,
        "coordinate_lifetime_counter_overflow_fails_closed_without_wrap");
    CjguiReleaseSession(replacementToken);

    CJGuiInternalSession *invalidated=[CJGuiInternalSession new];
    invalidated.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,80,60)
        device:device commandQueue:[device newCommandQueue]];
    uint64_t invalidatedToken=CjguiAllocateSession(invalidated),invalidatedGeneration=0;
    uint64_t beforeInvalidation=cjgui_internal_renderer_coordinate_lifetime(invalidatedToken,
        &invalidatedGeneration);
    [invalidated.view invalidateBridgeResources];
    uint64_t afterInvalidation=cjgui_internal_renderer_coordinate_lifetime(invalidatedToken,
        &invalidatedGeneration);
    CHECK(beforeInvalidation==1 && afterInvalidation==0 && invalidatedGeneration==0,
        "coordinate_lifetime_view_invalidation_closes_snapshot");
    CjguiReleaseSession(invalidatedToken);
}

static void InstalledRangeAckDoesNotProveCappedMirrorEqualityFixture(id<MTLDevice> device) {
    NSMutableString *initial=[NSMutableString stringWithCapacity:2048];
    for(NSUInteger i=0;i<2048;i++) [initial appendString:@"a"];
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,initial,79,970,7009);
    CHECK(overlay!=nil,"installed_range_cap_ack_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=NSMakeRange(1,0); overlay.applyingProjection=NO;
    BOOL changed=[overlay textView:overlay.inputProxy shouldChangeTextInRange:NSMakeRange(1,0)
        replacementString:@"J"];
    if(changed) {
        [overlay.inputProxy.textStorage replaceCharactersInRange:NSMakeRange(1,0) withString:@"J"];
        overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=NSMakeRange(2,0); overlay.applyingProjection=NO;
        [overlay.inputProxy didChangeText];
    }
    CHECK(changed && overlay.inputProxy.string.length==2049 && ctx.pendingInteractions.count==1,
        "installed_range_cap_actual_proxy_mutation_reserved_once");
    CjguiInternalRendererEvent event={0};
    BOOL pumped=cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
    CjguiInternalInstalledRangeIntent intent={0};
    BOOL claimed=pumped && cjgui_internal_renderer_claim_last_pumped_range(token,401,1,79,
        ctx.composableSceneVersion,&intent)==CJGUI_INTERNAL_RENDERER_OK &&
        intent.preBodyUtf8Length==2048 && intent.postBodyUtf8Length==2049;
    CHECK(claimed,"installed_range_cap_claim_proves_exact_2049_post_body");
    CHECK(claimed && cjgui_internal_renderer_ack_installed_range(token,&intent,1u,11)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeObservedAckSequence==intent.seq && ctx.installedRangeObservedAckVersion==11,
        "installed_range_cap_owner_ack_records_real_version");

    NSMutableString *acceptedMirror=[NSMutableString stringWithString:@"aJ"];
    for(NSUInteger i=0;i<2046;i++) [acceptedMirror appendString:@"a"];
    NSData *mirrorBytes=[acceptedMirror dataUsingEncoding:NSUTF8StringEncoding];
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=2;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0; node.value=acceptedMirror;
    node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=2; ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion+=1;
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_cap_owner_projection_accepts_2048_mirror");
    cjgui_internal_renderer_set_source_install_gate(token,79,972,1);
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    CHECK([overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding].length==2049 &&
        ![overlay activeLocalEditNeedsOwnerSettlement],
        "installed_range_cap_exact_ack_settles_generation_without_mirror_equality");
    CjguiInternalInstalledRangeCandidate next={
        .nonce=971, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7009, .bindingEpoch=79, .contextEpoch=4,
        .mirrorRevision=3, .ownerVersion=11, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=mirrorBytes.length,
        .sourceTextUtf8=mirrorBytes.bytes, .sourceTextUtf8Length=(uint32_t)mirrorBytes.length,
    };
    BOOL armed=cjgui_internal_renderer_installed_range_arm(token,&next)==CJGUI_INTERNAL_RENDERER_OK;
    BOOL resourceReady=SourceInstallPumpActiveResourcePreparation(overlay);
    uint32_t start=0,end=0; uint8_t deferred=0;
    CjguiInternalRendererStatus installStatus=armed&&resourceReady?SourceInstall(token,972,ctx.composableSceneVersion,79,
        acceptedMirror,2,2,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &start,&end,&deferred):CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CHECK(armed && resourceReady && installStatus==CJGUI_INTERNAL_RENDERER_SCENE_STALE && deferred==1 &&
        ctx.sourceProxyPreparation!=nil && ![overlay activeLocalEditNeedsOwnerSettlement],
        "installed_range_cap_real_ack_unblocks_ticketed_mirror_preparation");
    if(armed && ![overlay activeLocalEditNeedsOwnerSettlement]) {
        CHECK(SourceInstallPrepareToReady(ctx,token,972,ctx.composableSceneVersion,79,acceptedMirror,2,2,
            &start,&end),"installed_range_cap_ticketed_mirror_preparation_reaches_ready");
        deferred=0;
        CjguiInternalRendererStatus adopted=SourceInstall(token,972,ctx.composableSceneVersion,79,
            acceptedMirror,2,2,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
            &start,&end,&deferred);
        CjguiInternalInstalledRangeReceipt restored={0};
        BOOL hasReceipt=cjgui_internal_renderer_installed_range_receipt(token,971,&restored)==
            CJGUI_INTERNAL_RENDERER_OK;
        CHECK(adopted==CJGUI_INTERNAL_RENDERER_OK && hasReceipt && start==2 && end==2 &&
            [overlay.inputProxy.string isEqualToString:acceptedMirror],
            "installed_range_cap_ticketed_mirror_actual_install_readback");
        CHECK(hasReceipt && cjgui_internal_renderer_installed_range_activate(token,971,
            restored.proxyGeneration,restored.selectionRevision)==CJGUI_INTERNAL_RENDERER_OK,
            "installed_range_cap_owner_selection_ticket_receipt_activates_restored_basis");
    }
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeAckSettlesOnlyCurrentTailFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device, @"prefix",80,980,7010);
    CHECK(overlay!=nil,"installed_range_ack_tail_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    BOOL first=SourceInstallPerformNativeAppend(overlay,@"X",NULL,NULL,NULL);
    BOOL second=SourceInstallPerformNativeAppend(overlay,@"Y",NULL,NULL,NULL);
    CHECK(first && second && overlay.activeLocalEditGeneration==2 &&
        ctx.installedRangeLocalTailSequence==2,
        "installed_range_ack_tail_xy_each_records_one_generation");
    CjguiInternalRendererEvent event={0};
    BOOL pumped=cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
    CjguiInternalInstalledRangeIntent x={0};
    BOOL claimed=pumped && cjgui_internal_renderer_claim_last_pumped_range(token,401,1,80,
        ctx.composableSceneVersion,&x)==CJGUI_INTERNAL_RENDERER_OK;
    CHECK(claimed,"installed_range_ack_tail_x_claimed_before_y");
    CHECK(claimed && cjgui_internal_renderer_ack_installed_range(token,&x,1u,10)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.installedRangeObservedAckSequence==0,
        "installed_range_ack_tail_rejects_nonadvancing_old_owner_version");
    CHECK(claimed && cjgui_internal_renderer_ack_installed_range(token,&x,1u,11)==
        CJGUI_INTERNAL_RENDERER_OK && overlay.activeLocalEditSettledGeneration!=
            overlay.activeLocalEditGeneration && [overlay activeLocalEditNeedsOwnerSettlement],
        "installed_range_ack_x_cannot_settle_queued_y_generation");
    event=(CjguiInternalRendererEvent){0};
    pumped=cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
    CjguiInternalInstalledRangeIntent y={0};
    CjguiInternalRendererStatus yStatus=pumped?cjgui_internal_renderer_claim_last_pumped_range(token,401,1,80,
        ctx.composableSceneVersion,&y):CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    claimed=yStatus==CJGUI_INTERNAL_RENDERER_OK &&
        y.previousSeq==x.seq;
    CHECK(claimed,"installed_range_ack_tail_y_claim_chains_after_real_x_ack");
    uint64_t originalSelectionRevision=y.selectionRevision;
    overlay.inputProxy.selectedRange=NSMakeRange(0,0);
    CHECK(overlay.installedRangeSelectionRevision>originalSelectionRevision,
        "installed_range_ack_tail_same_value_selection_revision_advances_independently");
    CHECK(claimed && cjgui_internal_renderer_ack_installed_range(token,&y,1u,12)==
        CJGUI_INTERNAL_RENDERER_OK && overlay.activeLocalEditSettledGeneration==
            overlay.activeLocalEditGeneration && ![overlay activeLocalEditNeedsOwnerSettlement],
        "installed_range_ack_tail_body_settlement_survives_new_selection_ticket");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&y,1u,13)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "installed_range_ack_tail_late_duplicate_ack_is_stale");
    cjgui_internal_renderer_destroy(token);
}

static BOOL InstalledRangePrepareLargeSourceToReady(CJGuiInternalSession *ctx,uint64_t token,uint64_t request,
    uint64_t scene,uint64_t binding,NSString *value,uint32_t start,uint32_t end,
    uint32_t *outStart,uint32_t *outEnd) {
    uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+10000000000ull;
    for(NSUInteger i=0;i<512;++i) {
        uint8_t deferred=0;
        CjguiInternalRendererStatus status=SourceInstall(token,request,scene,binding,value,start,end,deadline,
            outStart,outEnd,&deferred);
        if(status!=CJGUI_INTERNAL_RENDERER_SCENE_STALE && status!=CJGUI_INTERNAL_RENDERER_OK) return NO;
        if(ctx.sourceProxyPreparation.ready) return deferred==1;
    }
    return NO;
}

static void InstalledRangeMutationGenerationSurvivesMissingActiveNodeFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"old proxy",81,990,7011);
    CHECK(overlay!=nil,"installed_range_missing_active_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    NSString *before=[overlay.inputProxy.string copy]; NSRange edit=NSMakeRange(before.length,0);
    overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=edit; overlay.applyingProjection=NO;
    BOOL allowed=[overlay textView:overlay.inputProxy shouldChangeTextInRange:edit replacementString:@"Z"];
    if(allowed) {
        [overlay.inputProxy.textStorage replaceCharactersInRange:edit withString:@"Z"];
        overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=NSMakeRange(edit.location+1,0);
        overlay.applyingProjection=NO;
        overlay.nodes=@[]; // old native proxy remains, but no current scene node resolves it
        [overlay.inputProxy didChangeText];
    }
    CHECK(allowed && ctx.pendingInteractions.count==1 && overlay.activeLocalEditGeneration==1 &&
        overlay.activeLocalEditAwaitingOwner,
        "installed_range_missing_active_node_completion_still_records_one_generation");
    CjguiInternalRendererEvent event={0};
    BOOL pumped=cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
    CjguiInternalInstalledRangeIntent intent={0};
    BOOL claimed=pumped && cjgui_internal_renderer_claim_last_pumped_range(token,401,1,81,
        ctx.composableSceneVersion,&intent)==CJGUI_INTERNAL_RENDERER_OK;
    CHECK(claimed && cjgui_internal_renderer_ack_installed_range(token,&intent,1u,11)==
        CJGUI_INTERNAL_RENDERER_OK && ![overlay activeLocalEditNeedsOwnerSettlement],
        "installed_range_missing_active_node_exact_owner_ack_settles_recorded_generation");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeInvalidPostNeverSettlesLocalGenerationFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"invalid post",82,991,7012);
    CHECK(overlay!=nil,"installed_range_invalid_post_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session;
    NSUInteger location=overlay.inputProxy.string.length;
    overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=NSMakeRange(location,0);
    overlay.applyingProjection=NO;
    BOOL allowed=[overlay textView:overlay.inputProxy shouldChangeTextInRange:NSMakeRange(location,0)
        replacementString:@"X"];
    if(allowed) {
        [overlay.inputProxy.textStorage replaceCharactersInRange:NSMakeRange(location,0) withString:@"Y"];
        overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=NSMakeRange(location+1,0);
        overlay.applyingProjection=NO; [overlay.inputProxy didChangeText];
    }
    CJGuiInternalQueuedInteraction *queued=ctx.pendingInteractions.firstObject;
    CHECK(allowed && ctx.installedRangeBasis.chainClosed && overlay.activeLocalEditGeneration==1 &&
        overlay.activeLocalEditSettledGeneration!=overlay.activeLocalEditGeneration && queued &&
        queued.installedRangeOwnedInvalid,
        "installed_range_invalid_post_records_unsettled_generation_and_owned_invalid_event");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void InstalledRangeLateReceiptCannotReplaceNewSelectionFixture(id<MTLDevice> device) {
    NSString *text=@"same body selection";
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,text,83,992,7013);
    CHECK(overlay!=nil,"installed_range_late_selection_fixture_old_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate candidate={
        .nonce=993, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7013, .bindingEpoch=83, .contextEpoch=4,
        .mirrorRevision=2, .ownerVersion=10, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=bytes.length,
        .sourceTextUtf8=bytes.bytes, .sourceTextUtf8Length=(uint32_t)bytes.length,
    };
    BOOL installed=cjgui_internal_renderer_installed_range_arm(token,&candidate)==CJGUI_INTERNAL_RENDERER_OK &&
        [overlay focusCommittedNodeId:401];
    CjguiInternalInstalledRangeReceipt receipt={0};
    BOOL receipted=installed && cjgui_internal_renderer_installed_range_receipt(token,993,&receipt)==
        CJGUI_INTERNAL_RENDERER_OK;
    CHECK(receipted,"installed_range_late_selection_old_restore_receipt_prepared");
    NSRange newChoice=NSMakeRange(0,0);
    overlay.inputProxy.selectedRange=newChoice; // Same body, newer selection revision.
    CHECK(receipted && overlay.installedRangeSelectionRevision>receipt.selectionRevision &&
        cjgui_internal_renderer_installed_range_activate(token,993,receipt.proxyGeneration,
            receipt.selectionRevision)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        NSEqualRanges(overlay.inputProxy.selectedRange,newChoice),
        "installed_range_late_receipt_rejected_without_replacing_same_value_new_selection");
    CHECK(cjgui_internal_renderer_installed_range_cancel(token,993)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBasis && ctx.installedRangeBasis.candidate.nonce==992 &&
        NSEqualRanges(overlay.inputProxy.selectedRange,newChoice),
        "installed_range_late_selection_cancel_keeps_old_basis_and_new_choice");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeRealKeyPathFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,@"key path",76,925,7006);
    CHECK(overlay!=nil,"installed_range_key_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    cjgui_internal_renderer_set_source_install_gate(token,76,926,1);
    overlay.applyingProjection=YES;
    overlay.inputProxy.selectedRange=NSMakeRange(overlay.inputProxy.string.length,0);
    overlay.applyingProjection=NO;
    NSEvent *unprovenNavigation=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:0 windowNumber:overlay.testWindow.windowNumber context:nil
        characters:[NSString stringWithFormat:@"%C",(unichar)NSUpArrowFunctionKey]
        charactersIgnoringModifiers:[NSString stringWithFormat:@"%C",(unichar)NSUpArrowFunctionKey]
        isARepeat:NO keyCode:126];
    [overlay.inputProxy keyDown:unprovenNavigation];
    CHECK([overlay.inputProxy.string isEqualToString:@"key path"] && ctx.pendingInteractions.count==1 &&
        ctx.pendingInteractions.firstObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        "installed_range_source_gate_keeps_unproven_navigation_on_owner_path");
    [ctx.pendingInteractions removeAllObjects];
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:0 windowNumber:overlay.testWindow.windowNumber context:nil
        characters:@"q" charactersIgnoringModifiers:@"q" isARepeat:NO keyCode:12];
    [overlay.inputProxy keyDown:key];
    CHECK([overlay.inputProxy.string isEqualToString:@"key pathq"] && ctx.pendingInteractions.count==1 &&
        ctx.pendingInteractions.firstObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "installed_range_actual_basis_plain_key_crosses_gate_then_textkit_kind51_once");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeCanceledProvisionalRecoveryFixture(id<MTLDevice> device) {
    NSString *text=@"actual installed source";
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,text,74,930,7004);
    CHECK(overlay!=nil,"installed_range_recovery_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate candidate={
        .nonce=931, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7004, .bindingEpoch=74, .contextEpoch=4,
        .mirrorRevision=2, .ownerVersion=10, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=bytes.length,
        .sourceTextUtf8=bytes.bytes, .sourceTextUtf8Length=(uint32_t)bytes.length,
    };
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&candidate)==CJGUI_INTERNAL_RENDERER_OK &&
        [overlay focusCommittedNodeId:401],"installed_range_recovery_provisional_actually_installed");
    CjguiInternalInstalledRangeReceipt receipt={0};
    CHECK(cjgui_internal_renderer_installed_range_receipt(token,931,&receipt)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_recovery_provisional_receipt_real");
    CHECK(cjgui_internal_renderer_installed_range_cancel(token,931)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_recovery_actual_provisional_canceled");
    cjgui_internal_renderer_set_source_install_gate(token,74,932,1);
    cjgui_internal_renderer_set_source_install_gate(token,74,932,0);
    BOOL escapedToLegacy=[overlay textView:overlay.inputProxy
        shouldChangeTextInRange:NSMakeRange(overlay.inputProxy.string.length,0) replacementString:@"x"];
    CHECK(!escapedToLegacy && ctx.pendingInteractions.count==0,
        "installed_range_recovery_gate_clear_still_refuses_stale_owned_source");
    candidate.nonce=933;
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&candidate)==CJGUI_INTERNAL_RENDERER_OK &&
        [overlay focusCommittedNodeId:401],"installed_range_recovery_fresh_root_actual_install");
    receipt=(CjguiInternalInstalledRangeReceipt){0};
    CHECK(cjgui_internal_renderer_installed_range_receipt(token,933,&receipt)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_installed_range_activate(token,933,receipt.proxyGeneration,
            receipt.selectionRevision)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_recovery_fresh_receipt_activates_input");
    CHECK(SourceInstallPerformNativeAppend(overlay,@"x",NULL,NULL,NULL) &&
        ctx.pendingInteractions.count==1 &&
        ctx.pendingInteractions.firstObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "installed_range_recovery_textkit_range_resumes_after_fresh_receipt");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeMissingBasisFailClosedFixture(id<MTLDevice> device) {
    NSString *text=@"owned range needs receipt";
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,text,77,950,7007);
    CHECK(overlay!=nil,"installed_range_missing_basis_fixture_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_release_installed_range(token,7007,77)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBasis==nil,"installed_range_missing_basis_fixture_released_actual_basis");
    NSString *before=[overlay.inputProxy.string copy];
    BOOL allowed=SourceInstallPerformNativeAppend(overlay,@"m",NULL,NULL,NULL);
    CHECK(!allowed && [overlay.inputProxy.string isEqualToString:before] && ctx.pendingInteractions.count==0,
        "installed_range_owned_target_without_confirmed_basis_fails_before_legacy_mutation");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeActivationRejectsLegacyRangeFixture(id<MTLDevice> device) {
    NSString *text=@"unchanged accepted source";
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,text,78,960,7008);
    CHECK(overlay!=nil,"installed_range_activation_legacy_fixture_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_release_installed_range(token,7008,78)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_activation_legacy_fixture_basis_released");
    CHECK(CjguiEnqueueComposableInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,0,@"legacy",NSMakeRange(2,0)) &&
        ctx.pendingInteractions.count==1 && ctx.pendingInteractions.firstObject.installedRangeIntent==nil,
        "installed_range_activation_fixture_has_unconsumed_legacy_range");
    NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate candidate={
        .nonce=961, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7008, .bindingEpoch=78, .contextEpoch=4,
        .mirrorRevision=2, .ownerVersion=10, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=bytes.length,
        .sourceTextUtf8=bytes.bytes, .sourceTextUtf8Length=(uint32_t)bytes.length,
    };
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&candidate)==CJGUI_INTERNAL_RENDERER_OK &&
        [overlay focusCommittedNodeId:401],"installed_range_activation_fixture_actual_root_installed");
    CjguiInternalInstalledRangeReceipt receipt={0};
    CjguiInternalRendererStatus receiptStatus=cjgui_internal_renderer_installed_range_receipt(token,961,&receipt);
    CjguiInternalRendererStatus activation=receiptStatus==CJGUI_INTERNAL_RENDERER_OK
        ? cjgui_internal_renderer_installed_range_activate(token,961,receipt.proxyGeneration,
            receipt.selectionRevision) : receiptStatus;
    CHECK(receiptStatus==CJGUI_INTERNAL_RENDERER_OK && activation==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.installedRangeBasis==nil && ctx.pendingInteractions.count==1,
        "installed_range_activation_does_not_retroclaim_pending_legacy_range");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeUpfrontCopyBudgetFixture(id<MTLDevice> device) {
    NSMutableString *text=[NSMutableString stringWithCapacity:500000];
    for(NSUInteger i=0;i<500000;i++) [text appendString:@"a"];
    SourceInstallOverlay *overlay=InstalledRangeCreateActivatedFixture(device,text,75,940,7005);
    CHECK(overlay!=nil,"installed_range_copy_budget_fixture_actual_basis_ready");
    if(!overlay) return;
    CJGuiInternalSession *ctx=overlay.session; uint64_t token=ctx.rendererSessionToken;
    BOOL first=SourceInstallPerformNativeAppend(overlay,@"x",NULL,NULL,NULL);
    BOOL second=SourceInstallPerformNativeAppend(overlay,@"y",NULL,NULL,NULL);
    CHECK(first && !second && ctx.pendingInteractions.count==1 &&
        ctx.installedRangeBytesUsed+ctx.installedRangeBytesReserved<=4u*1024u*1024u,
        "installed_range_three_copy_cost_reserved_before_second_mutation");
    CjguiInternalRendererEvent event={0};
    CjguiInternalInstalledRangeIntent claim={0};
    CjguiInternalRendererStatus claimStatus=cjgui_internal_renderer_pump_event(token,0,&event)==
        CJGUI_INTERNAL_RENDERER_OK && event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED
        ? cjgui_internal_renderer_claim_last_pumped_range(token,401,1,75,ctx.composableSceneVersion,&claim)
        : CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CHECK(claimStatus==CJGUI_INTERNAL_RENDERER_OK && ctx.installedRangeBytesUsed<=4u*1024u*1024u,
        "installed_range_claim_succeeds_without_post_mutation_copy_budget");
    if(claimStatus==CJGUI_INTERNAL_RENDERER_OK)
        CHECK(cjgui_internal_renderer_ack_installed_range(token,&claim,0u,-1)==CJGUI_INTERNAL_RENDERER_OK &&
            ctx.installedRangeBasis.chainClosed && ctx.installedRangeBytesUsed==
                [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
            "installed_range_budget_fixture_explicit_consumer_reject_releases_reservation");
    CHECK(cjgui_internal_renderer_release_installed_range(token,7005,75)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.installedRangeBytesUsed==0 && ctx.installedRangeBytesReserved==0 && ctx.installedRangeSlotsReserved==0,
        "installed_range_release_returns_exact_budget_and_fifo_reservation");
    cjgui_internal_renderer_destroy(token);
}

static void InstalledRangeDefaultMirrorPlusOneFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes=[NSMutableArray array]; ctx.stagedComposableNodes=[NSMutableArray array];
    ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay=[[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    overlay.testWindow=[[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window=(NSWindow *)overlay.testWindow; ctx.composableSceneOverlay=overlay;
    overlay.inputProxy.delegate=nil;
    SourceInstallProxy *proxy=[[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    proxy.composableOverlay=overlay; proxy.delegate=overlay;
    proxy.layoutManager.allowsNonContiguousLayout=YES; proxy.layoutManager.backgroundLayoutEnabled=NO;
    overlay.inputProxy=proxy; overlay.inputScrollProxy.documentView=proxy;
    overlay.testWindow.contentView=overlay;
    NSMutableString *text=[NSMutableString stringWithCapacity:65536];
    for(NSUInteger i=0;i<65536;i++) [text appendString:@"a"];
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0; node.value=text; node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=1; ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_65536_fixture_scene_accepted");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=73; ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate basis={
        .nonce=920, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7003, .bindingEpoch=73, .contextEpoch=4,
        .mirrorRevision=2, .ownerVersion=10, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=bytes.length,
        .sourceTextUtf8=bytes.bytes, .sourceTextUtf8Length=(uint32_t)bytes.length,
    };
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&basis)==CJGUI_INTERNAL_RENDERER_OK &&
        [overlay focusCommittedNodeId:401], "installed_range_65536_actual_root_activated");
    CjguiInternalInstalledRangeReceipt receipt={0};
    CHECK(cjgui_internal_renderer_installed_range_receipt(token,920,&receipt)==CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_installed_range_activate(token,920,receipt.proxyGeneration,
            receipt.selectionRevision)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_65536_receipt_activated");
    overlay.testWindow.testResponder=overlay.inputHost;
    CHECK(SourceInstallPerformNativeAppend(overlay,@"z",NULL,NULL,NULL) &&
        ctx.installedRangeReservation==nil && ctx.pendingInteractions.count==1 &&
        [overlay.inputProxy.string isEqualToString:[text stringByAppendingString:@"z"]],
        "installed_range_default_65536_mirror_accepts_one_character");
    CjguiInternalRendererEvent event={0};
    BOOL pumped=cjgui_internal_renderer_pump_event(token,0,&event)==CJGUI_INTERNAL_RENDERER_OK &&
        event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED;
    CjguiInternalInstalledRangeIntent intent={0};
    BOOL claimed=pumped && cjgui_internal_renderer_claim_last_pumped_range(token,401,1,73,
        ctx.composableSceneVersion,&intent)==CJGUI_INTERNAL_RENDERER_OK &&
        intent.preBodyUtf8Length==65536 && intent.postBodyUtf8Length==65537;
    CHECK(claimed,"installed_range_default_65536_textkit_claims_65537_post");
    BOOL acked=claimed && cjgui_internal_renderer_ack_installed_range(token,&intent,1u,11)==
        CJGUI_INTERNAL_RENDERER_OK && ctx.installedRangeBasis.candidate.sourceEndByte==65537 &&
        ctx.installedRangeObservedAckSequence==intent.seq;
    CHECK(acked,"installed_range_default_65537_owner_ack_advances_actual_source_scope");

    CJGuiInternalComposableSceneNode *acceptedNode=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode acceptedRaw={0};
    acceptedRaw.nodeId=401; acceptedRaw.resourceId=1; acceptedRaw.projectionVersion=2;
    acceptedRaw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    acceptedRaw.width=680; acceptedRaw.height=1200; acceptedRaw.clipWidth=680; acceptedRaw.clipHeight=500;
    acceptedRaw.fontSize=13; acceptedRaw.textAlpha=1; acceptedRaw.isInteractive=1;
    acceptedNode.node=acceptedRaw; acceptedNode.index=0; acceptedNode.value=text;
    acceptedNode.styleRunsSignature=@""; acceptedNode.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:acceptedNode];
    ctx.stagedComposableSceneVersion=2; ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion+=1;
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_default_owner_accepts_bounded_65536_mirror");
    cjgui_internal_renderer_set_source_install_gate(token,73,921,1);
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    SourceInstallProxy *oldProxy=overlay.inputProxy;
    NSData *mirrorBytes=[text dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate restoredBasis={
        .nonce=921, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7003, .bindingEpoch=73, .contextEpoch=4,
        .mirrorRevision=3, .ownerVersion=11, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0, .sourceEndByte=65537,
        .sourceTextUtf8=mirrorBytes.bytes, .sourceTextUtf8Length=(uint32_t)mirrorBytes.length,
    };
    BOOL armed=cjgui_internal_renderer_installed_range_arm(token,&restoredBasis)==CJGUI_INTERNAL_RENDERER_OK;
    BOOL resourceReady=SourceInstallPumpActiveResourcePreparation(overlay);
    uint32_t start=0,end=0; uint8_t deferred=0;
    CjguiInternalRendererStatus installStatus=armed&&resourceReady?SourceInstall(token,921,
        ctx.composableSceneVersion,73,text,2,2,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &start,&end,&deferred):CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CHECK(acked && armed && resourceReady && installStatus==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        deferred==1 && ctx.sourceProxyPreparation!=nil,
        "installed_range_default_65537_source_allows_ticketed_65536_mirror_preparation");
    BOOL ready=armed && InstalledRangePrepareLargeSourceToReady(ctx,token,921,ctx.composableSceneVersion,73,text,2,2,
        &start,&end);
    deferred=0;
    CjguiInternalRendererStatus adopted=ready?SourceInstall(token,921,ctx.composableSceneVersion,73,text,2,2,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,&start,&end,&deferred):
        CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalInstalledRangeReceipt restoredReceipt={0};
    BOOL hasReceipt=cjgui_internal_renderer_installed_range_receipt(token,921,&restoredReceipt)==
        CJGUI_INTERNAL_RENDERER_OK;
    BOOL activated=hasReceipt && cjgui_internal_renderer_installed_range_activate(token,921,
        restoredReceipt.proxyGeneration,restoredReceipt.selectionRevision)==CJGUI_INTERNAL_RENDERER_OK;
    CHECK(ready && adopted==CJGUI_INTERNAL_RENDERER_OK && activated && overlay.inputProxy!=oldProxy &&
        [overlay.inputProxy.string isEqualToString:text] && start==2 && end==2 &&
        ctx.installedRangeBasis.candidate.sourceEndByte==65537,
        "installed_range_default_ticket_installs_65536_mirror_after_65537_ack");
    SourceInstallProxy *unprovenProxy=overlay.inputProxy;
    BOOL released=cjgui_internal_renderer_release_installed_range(token,7003,73)==
        CJGUI_INTERNAL_RENDERER_OK && ctx.installedRangeBasis==nil;
    NSMutableString *unprovenBody=[NSMutableString stringWithCapacity:65537];
    for(NSUInteger i=0;i<65537;i++) [unprovenBody appendString:@"b"];
    overlay.applyingProjection=YES;
    [unprovenProxy.textStorage replaceCharactersInRange:NSMakeRange(0,unprovenProxy.textStorage.length)
        withString:unprovenBody];
    overlay.applyingProjection=NO;
    cjgui_internal_renderer_set_source_install_gate(token,73,922,1);
    deferred=0;
    CjguiInternalRendererStatus unprovenStatus=SourceInstall(token,922,ctx.composableSceneVersion,73,text,2,2,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,&start,&end,&deferred);
    CHECK(released && unprovenStatus==CJGUI_INTERNAL_RENDERER_SCENE_STALE && deferred==0 &&
        ctx.sourceProxyPreparation==nil && overlay.inputProxy==unprovenProxy &&
        [overlay.inputProxy.string isEqualToString:unprovenBody],
        "installed_range_unproven_65537_old_proxy_is_rejected_and_preserved");
    cjgui_internal_renderer_destroy(token);
}

#ifndef CJGUI_CARET_AFTER_INPUT_FIXTURE
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 2;
    InstalledRangeCoordinateLifetimeFixture(device);
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay = [[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    overlay.testWindow = [[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window = (NSWindow *)overlay.testWindow;
    ctx.composableSceneOverlay = overlay;
    overlay.inputProxy.delegate = nil;
    SourceInstallProxy *controlledProxy = [[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    controlledProxy.composableOverlay = overlay;
    controlledProxy.delegate = overlay;
    controlledProxy.layoutManager.allowsNonContiguousLayout = YES;
    controlledProxy.layoutManager.backgroundLayoutEnabled = NO;
    overlay.inputProxy = controlledProxy;
    overlay.inputScrollProxy.documentView = controlledProxy;
    overlay.testWindow.contentView = overlay;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0;
    node.value=@"A🙂e\u0301\r\nfirst source row\nsecond source row\n";
    node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=1;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,"accepted_static_setup");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    CHECK([overlay.nodes containsObject:node],"accepted_overlay_same_node");
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=71;

    ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    const char *initialBytes=node.value.UTF8String;
    CjguiInternalInstalledRangeCandidate initialBasis={
        .nonce=901, .rendererSessionGeneration=ctx.sessionGeneration,
        .windowInstanceToken=7001, .bindingEpoch=71, .contextEpoch=3,
        .mirrorRevision=1, .ownerVersion=1, .installedSceneVersion=ctx.composableSceneVersion,
        .nodeId=401, .resourceId=1, .sourceStartByte=0,
        .sourceEndByte=strlen(initialBytes), .sourceTextUtf8=(const uint8_t *)initialBytes,
        .sourceTextUtf8Length=(uint32_t)strlen(initialBytes),
    };
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&initialBasis)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_initial_candidate_armed_before_actual_install");
    CHECK([overlay focusCommittedNodeId:401], "installed_range_initial_actual_proxy");
    CjguiInternalInstalledRangeReceipt initialReceipt={0};
    CjguiInternalRendererStatus receiptStatus=cjgui_internal_renderer_installed_range_receipt(token,901,&initialReceipt);
    CHECK(receiptStatus==CJGUI_INTERNAL_RENDERER_OK && initialReceipt.proxyGeneration>0,
        "installed_range_receipt_from_actual_proxy_install_readback");
    CHECK(cjgui_internal_renderer_installed_range_activate(token,901,
        initialReceipt.proxyGeneration,initialReceipt.selectionRevision)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_initial_basis_activation_after_receipt");
    overlay.testWindow.testResponder=overlay.inputHost;
    NSString *initial=[overlay.inputProxy.string copy];
    NSRange initialSelection=overlay.inputProxy.selectedRange;
    CjguiInternalInstalledRangeCandidate sameBodyCandidate=initialBasis;
    sameBodyCandidate.nonce=905;
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&sameBodyCandidate)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_same_body_new_selection_candidate_armed");
    NSRange changedSelection=overlay.inputProxy.selectedRange.location==0
        ? NSMakeRange(overlay.inputProxy.string.length,0) : NSMakeRange(0,0);
    overlay.inputProxy.selectedRange=changedSelection;
    CjguiInternalInstalledRangeReceipt uninstalledReceipt={0};
    CHECK(cjgui_internal_renderer_installed_range_receipt(token,905,&uninstalledReceipt)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "installed_range_same_body_new_selection_needs_actual_install_receipt");
    CHECK(cjgui_internal_renderer_installed_range_cancel(token,905)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_cancel_uninstalled_candidate_preserves_old_basis");
    overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=initialSelection; overlay.applyingProjection=NO;
    BOOL selectionOnly=YES;
    for (CJGuiInternalQueuedInteraction *queued in [ctx.pendingInteractions copy])
        if (queued.kind!=CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED) selectionOnly=NO;
    CHECK(selectionOnly,"installed_range_same_body_selection_is_old_basis_query_only");
    [ctx.pendingInteractions removeAllObjects]; // The fixture settles that old-basis query before source restore.
    cjgui_internal_renderer_set_source_install_gate(token,71,901,1);
    CjguiInternalInstalledRangeCandidate pendingBasis=initialBasis;
    pendingBasis.nonce=902;
    CHECK(cjgui_internal_renderer_installed_range_arm(token,&pendingBasis)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_restore_candidate_armed_before_source_preparation");
    uint32_t a=0,b=0;uint8_t deferred=0;
    CjguiInternalRendererStatus status=SourceInstall(token,901,1,71,node.value,7,7,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,&a,&b,&deferred);
    CHECK(status==CJGUI_INTERNAL_RENDERER_SCENE_STALE && deferred==1 &&
        ctx.sourceProxyPreparation!=nil && [overlay.inputProxy.string isEqualToString:initial],
        "installed_range_new_preparation_keeps_actual_old_proxy");
    CHECK(cjgui_internal_renderer_installed_range_receipt(token,902,&uninstalledReceipt)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE,
        "installed_range_deferred_candidate_has_no_speculative_receipt");
    BOOL first=SourceInstallPerformNativeAppend(overlay,@"X",NULL,NULL,NULL);
    BOOL second=SourceInstallPerformNativeAppend(overlay,@"Y",NULL,NULL,NULL);
    NSUInteger ranges=0;for(CJGuiInternalQueuedInteraction *q in ctx.pendingInteractions)
        if(q.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED)ranges++;
    CHECK(first && second && ranges==2 &&
        [overlay.inputProxy.string isEqualToString:[initial stringByAppendingString:@"XY"]],
        "installed_range_preparing_continuous_XY_each_real_TextKit_range_once");
    fprintf(stderr,"INSTALLED_RANGE_BASELINE allowed_X=%d allowed_Y=%d ranges=%lu body=%s\n",
        first,second,(unsigned long)ranges,overlay.inputProxy.string.UTF8String);
    CjguiInternalRendererEvent prefixEvent={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&prefixEvent)==CJGUI_INTERNAL_RENDERER_OK &&
        prefixEvent.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "installed_range_prefix_first_event_pumped");
    CjguiInternalInstalledRangeIntent prefixClaim={0};
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,
        ctx.composableSceneVersion,&prefixClaim)==CJGUI_INTERNAL_RENDERER_OK,
        "installed_range_prefix_first_claimed_before_ack");
    prefixEvent=(CjguiInternalRendererEvent){0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&prefixEvent)==CJGUI_INTERNAL_RENDERER_OK &&
        prefixEvent.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "installed_range_prefix_second_event_pumped_before_ack");
    CjguiInternalInstalledRangeIntent outOfOrder={0};
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,401,1,71,
        ctx.composableSceneVersion,&outOfOrder)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        outOfOrder.nonce==901,
        "installed_range_out_of_order_prefix_stale_and_owned");
    CHECK(cjgui_internal_renderer_ack_installed_range(token,&prefixClaim,0u,-1)==
        CJGUI_INTERNAL_RENDERER_OK && ctx.installedRangeBasis.chainClosed &&
        ctx.pendingInteractions.count==0,
        "installed_range_external_ack_rejection_closes_unsettled_suffix");
    cjgui_internal_renderer_destroy(token);
    InstalledRangeWholeChoiceFixture(device);
    InstalledRangeLargeClaimRejectFixture(device);
    InstalledRangeDefaultMirrorPlusOneFixture(device);
    InstalledRangeRealKeyPathFixture(device);
    InstalledRangeCanceledProvisionalRecoveryFixture(device);
    InstalledRangeMissingBasisFailClosedFixture(device);
    InstalledRangeActivationRejectsLegacyRangeFixture(device);
    InstalledRangeUpfrontCopyBudgetFixture(device);
    InstalledRangeAckDoesNotProveCappedMirrorEqualityFixture(device);
    InstalledRangeAckSettlesOnlyCurrentTailFixture(device);
    InstalledRangeMutationGenerationSurvivesMissingActiveNodeFixture(device);
    InstalledRangeInvalidPostNeverSettlesLocalGenerationFixture(device);
    InstalledRangeLateReceiptCannotReplaceNewSelectionFixture(device);
    return failures?1:0;
} }
#endif
