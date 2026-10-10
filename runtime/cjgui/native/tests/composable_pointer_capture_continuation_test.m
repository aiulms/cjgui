// Native-only integration gate for a bounded text-drag capture continuation.
// The offer is tied to a real A-to-B native selection install receipt; scene
// identities are accepted through the same renderer transaction used by the
// normal composable presenter.
#define main prior_selection_transfer_paint_test_main
#import "composable_selection_transfer_paint_production_test.m"
#undef main

static CJGuiInternalComposableSceneNode *ContinuationNode(CJGuiInternalComposableSceneOverlay *overlay,
    uint64_t nodeId) {
    for (CJGuiInternalComposableSceneNode *node in overlay.nodes)
        if (node.node.nodeId == nodeId) return node;
    return nil;
}

static BOOL ContinuationStageRouteScene(CJGuiInternalSession *ctx, uint64_t version,
    uint64_t culledRouteNode, BOOL includeThirdFocus) {
    NSMutableArray<CJGuiInternalComposableSceneNode *> *nodes = [NSMutableArray array];
    CJGuiInternalComposableSceneNode *scroll = nil;
    CjguiInternalRendererComposableNode scrollRaw = {0};
    scrollRaw.nodeId = 900; scrollRaw.resourceId = 2; scrollRaw.projectionVersion = version;
    scrollRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
    scrollRaw.x = 0; scrollRaw.y = 0; scrollRaw.width = 680; scrollRaw.height = 500;
    // A normal ScrollArea owns wheel/edge scrolling through its node kind.
    // The explicit wheelScrollable flag also admits ordinary containers, but
    // ScrollArea's default style leaves it zero.
    scrollRaw.clipWidth = 680; scrollRaw.clipHeight = 500; scrollRaw.wheelScrollable = 0;
    scroll = [CJGuiInternalComposableSceneNode new]; scroll.node = scrollRaw; scroll.index = 0;
    scroll.value = @""; scroll.semanticId = @"editor-scroll"; scroll.semanticBindingKey = @"doc-scroll";
    scroll.styleRunsSignature = @""; scroll.textTextureCacheKey = @"";
    [nodes addObject:scroll];
    for (CJGuiInternalComposableSceneNode *source in ctx.composableSceneOverlay.nodes) {
        if (source.node.nodeId == culledRouteNode) continue;
        uint32_t index = (uint32_t)nodes.count;
        CJGuiInternalComposableSceneNode *copy = CjguiCloneComposableSceneNode(ctx, source, index, version);
        if (!copy) return NO;
        [nodes addObject:copy];
        if (includeThirdFocus && source.node.nodeId == 402) {
            CJGuiInternalComposableSceneNode *third = CjguiCloneComposableSceneNode(
                ctx, source, (uint32_t)nodes.count, version);
            if (!third) return NO;
            CjguiInternalRendererComposableNode thirdRaw = third.node;
            thirdRaw.nodeId = 404;
            third.node = thirdRaw;
            third.semanticId = @"body-404";
            third.semanticBindingKey = @"document-404";
            [nodes addObject:third];
        }
    }
    uint64_t token = ctx.rendererSessionToken;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(
        token, version, (uint32_t)nodes.count);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return NO;
    status = cjgui_internal_renderer_configure_composable_data_transfer(token, version, 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return NO;
    for (uint32_t index = 0; index < nodes.count; index++) {
        CJGuiInternalComposableSceneNode *entry = nodes[index];
        CjguiInternalRendererComposableNode raw = entry.node;
        raw.projectionVersion = version;
        NSData *labelData = [entry.label dataUsingEncoding:NSUTF8StringEncoding];
        NSData *valueData = [entry.value dataUsingEncoding:NSUTF8StringEncoding];
        const char *label = labelData ? labelData.bytes : "";
        const char *value = valueData ? valueData.bytes : "";
        status = cjgui_internal_renderer_set_composable_scene_node(token, index, &raw,
            label, value, "", "", 0);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return NO;
        NSData *semanticData = [entry.semanticId dataUsingEncoding:NSUTF8StringEncoding];
        NSData *bindingData = [entry.semanticBindingKey dataUsingEncoding:NSUTF8StringEncoding];
        status = cjgui_internal_renderer_set_composable_node_semantic_identity(token, index,
            semanticData ? semanticData.bytes : "");
        if (status != CJGUI_INTERNAL_RENDERER_OK) return NO;
        status = cjgui_internal_renderer_set_composable_node_semantic_metadata(token, index,
            bindingData ? bindingData.bytes : "", "", "", "");
        if (status != CJGUI_INTERNAL_RENDERER_OK) return NO;
    }
    return YES;
}

static BOOL ContinuationStageScene(CJGuiInternalSession *ctx, uint64_t version, BOOL cullOrigin) {
    return ContinuationStageRouteScene(ctx, version, cullOrigin ? 401 : UINT64_MAX, NO);
}

static CjguiInternalRendererStatus ContinuationPresent(CJGuiInternalSession *ctx, uint64_t scene) {
    CjguiInternalRendererStatus staged = cjgui_internal_renderer_stage_window_background(
        ctx.rendererSessionToken, scene, 0, 1);
    if (staged != CJGUI_INTERNAL_RENDERER_OK) return staged;
    CjguiInternalRendererFrameObservation observation = {0};
    CjguiInternalRendererStatus presented = cjgui_internal_renderer_present_composable_scene(
        ctx.rendererSessionToken, &observation);
    if (presented != CJGUI_INTERNAL_RENDERER_OK && presented != CJGUI_INTERNAL_RENDERER_READBACK_FAILED)
        fprintf(stderr, "continuation_present_status=%u scene=%llu accepted=%llu staged=%llu\n", (unsigned)presented,
            (unsigned long long)scene, (unsigned long long)ctx.composableSceneVersion,
            (unsigned long long)ctx.stagedComposableSceneVersion);
    if ((presented == CJGUI_INTERNAL_RENDERER_OK || presented == CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion != scene) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    return presented;
}

static BOOL ContinuationPresentedStatus(CjguiInternalRendererStatus status) {
    return status == CJGUI_INTERNAL_RENDERER_OK || status == CJGUI_INTERNAL_RENDERER_READBACK_FAILED;
}

static CjguiInternalRendererStatus ContinuationInstallRealReceiptForTarget(CJGuiInternalSession *ctx,
    uint64_t targetNodeId, int64_t ownerRevision,
    uint64_t *outTransfer, int64_t *outOwnerVersion, int64_t *outOwnerRevision) {
    uint64_t transfer = 0;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_selection_transfer_create(
        ctx.rendererSessionToken, &transfer);
    if (status != CJGUI_INTERNAL_RENDERER_OK || !transfer) return status;
    CJGuiInternalComposableSceneNode *target = ContinuationNode(ctx.composableSceneOverlay, targetNodeId);
    if (!target) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    NSData *body = [target.value dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    CjguiInternalSelectionTransferCandidate candidate = {0};
    candidate.transferId = transfer;
    candidate.sourceWindowInstanceToken = 9101;
    candidate.sourceOwnerVersion = 10;
    candidate.sourceContextEpoch = 4;
    candidate.sourceMirrorRevision = 2;
    candidate.targetNodeId = target.node.nodeId;
    candidate.targetProjectionVersion = 0;
    candidate.targetResourceId = target.node.resourceId;
    candidate.targetNodeKind = target.node.nodeKind;
    candidate.targetSceneVersion = ctx.composableSceneVersion;
    candidate.targetAnchor16 = 1; candidate.targetFocus16 = 3;
    candidate.targetBodyUtf8 = body.bytes; candidate.targetBodyUtf8Length = (uint32_t)body.length;
    uint8_t actual[65536] = {0};
    status = cjgui_internal_renderer_selection_transfer_capture_current(ctx.rendererSessionToken,
        &candidate, actual, sizeof(actual));
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_selection_transfer_publish_pending(ctx.rendererSessionToken, transfer);
    CjguiInternalSelectionTransferReceipt receipt = {0};
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_selection_transfer_install_b(ctx.rendererSessionToken, transfer, &receipt);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInstalledRangeState *basis = ctx.installedRangeBasis;
    uint8_t needsProjection = 0;
    status = cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken, transfer,
        ctx.sessionGeneration, basis.candidate.bindingEpoch, basis.proxyGeneration, basis.selectionRevision,
        basis.candidate.ownerVersion, ownerRevision, 0, &needsProjection);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    *outTransfer = transfer;
    *outOwnerVersion = basis.candidate.ownerVersion;
    *outOwnerRevision = ownerRevision;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus ContinuationInstallRealReceipt(CJGuiInternalSession *ctx,
    uint64_t *outTransfer, int64_t *outOwnerVersion, int64_t *outOwnerRevision) {
    return ContinuationInstallRealReceiptForTarget(ctx, 402, 22,
        outTransfer, outOwnerVersion, outOwnerRevision);
}

static BOOL ContinuationBeginAtPhaseThree(CJGuiInternalSession *ctx, uint64_t *outGesture) {
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *origin = ContinuationNode(overlay, 401);
    if (!origin) return NO;
    overlay.dragEdgeViewportIdentity = 19;
    overlay.dragEdgeViewportBinding = 71;
    overlay.dragEdgeScrollOwnerNode = 900;
    overlay.dragEdgeScrollOwnerResource = 2;
    if (![overlay beginPointerCaptureForNode:origin atPoint:NSMakePoint(300, 200)]) return NO;
    uint64_t gesture = overlay.pointerCaptureGestureEpoch;
    (void)[overlay updatePointerCaptureAtPoint:NSMakePoint(300, 560)];
    if (overlay.dragEdgeScrollPhase != 1) return NO;
    CjguiInternalRendererStatus requested = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, 1, 100, 0,
        ctx.composableSceneVersion, 1);
    if (requested != CJGUI_INTERNAL_RENDERER_OK || overlay.dragEdgeScrollPhase != 2) return NO;
    CjguiInternalRendererStatus accepted = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, 1, 100, 100,
        ctx.composableSceneVersion, 2);
    if (accepted != CJGUI_INTERNAL_RENDERER_OK || overlay.dragEdgeScrollPhase != 3) return NO;
    *outGesture = gesture;
    return YES;
}

static BOOL ContinuationOffer(CJGuiInternalSession *ctx, uint64_t gesture, uint64_t scene,
    uint64_t transfer, int64_t ownerVersion, int64_t ownerRevision,
    CjguiInternalPointerCaptureContinuationOffer *outOffer) {
    CjguiInternalPointerCaptureContinuationOffer offer = {0};
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    offer.gestureEpoch = gesture; offer.sessionGeneration = ctx.sessionGeneration;
    offer.windowInstanceToken = ctx.selectionReceiptTransferId == transfer
        ? ctx.selectionPaintWindowToken : ctx.installedRangeBasis.candidate.windowInstanceToken;
    offer.coordinateGeneration = ctx.coordinateLifetimeGeneration;
    offer.originNodeId = overlay.pointerCaptureNodeId;
    offer.originResourceId = overlay.pointerCaptureResourceId;
    offer.originNodeKind = overlay.pointerCaptureNodeKind;
    offer.originProjectionVersion = ContinuationNode(overlay, overlay.pointerCaptureNodeId).node.projectionVersion;
    offer.candidateSceneVersion = scene;
    offer.viewportNodeId = 900; offer.viewportResourceId = 2;
    offer.viewportNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
    offer.viewportBindingEpoch = 71; offer.viewportIdentity = 19;
    offer.requestGeneration = overlay.dragEdgeScrollRequestGeneration;
    offer.requestedOffset = overlay.dragEdgeScrollExpectedOffset;
    offer.acceptedOffset = overlay.dragEdgeScrollExpectedOffset;
    offer.selectionTransferId = transfer;
    offer.selectionReceiptSceneVersion = ctx.selectionReceiptSceneVersion;
    offer.selectionBindingEpoch = ctx.selectionReceiptBindingEpoch;
    offer.proxyGeneration = ctx.selectionReceiptProxyGeneration;
    offer.nativeSelectionRevision = ctx.selectionReceiptNativeRevision;
    offer.ownerVersion = ownerVersion; offer.ownerRevision = ownerRevision;
    offer.focusNodeId = ctx.selectionReceiptFocusNodeId;
    offer.focusResourceId = ctx.selectionReceiptFocusResourceId;
    offer.focusNodeKind = ctx.selectionReceiptFocusNodeKind;
    offer.focusSemanticIncarnation = ContinuationNode(overlay, offer.focusNodeId).node.semanticIncarnation;
    *outOffer = offer;
    return YES;
}

static void CheckContinuationOfferRejected(CJGuiInternalSession *ctx,
    CjguiInternalPointerCaptureContinuationOffer offer, const char *name) {
    CjguiInternalRendererStatus rejected = cjgui_internal_renderer_offer_pointer_capture_continuation(
        ctx.rendererSessionToken, &offer);
    CHECK(rejected == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.composableSceneOverlay.pointerCaptureActive &&
        ctx.composableSceneOverlay.pointerCaptureContinuation == nil, name);
}

static void ContinuationFixtureWithRealReceipt(id<MTLDevice> device, CJGuiInternalSession **outContext,
    uint64_t *outGesture, uint64_t *outTransfer, int64_t *outOwnerVersion, int64_t *outOwnerRevision) {
    CJGuiInternalSession *ctx = ProductionFixture(device);
    CHECK(ctx != nil, "continuation_fixture_created");
    if (!ctx) return;
    ctx.windowContentHost = ctx.window.contentView;
    ctx.windowOpaqueFallbackView = [[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer = YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    for (CJGuiInternalComposableSceneNode *node in ctx.composableSceneOverlay.nodes) {
        node.semanticId = [NSString stringWithFormat:@"body-%llu", (unsigned long long)node.node.nodeId];
        node.semanticBindingKey = [NSString stringWithFormat:@"document-%llu", (unsigned long long)node.node.nodeId];
        CjguiInternalRendererComposableNode raw = node.node;
        raw.semanticIncarnation = 1;
        node.node = raw;
    }
    CHECK(ContinuationStageScene(ctx, 2, NO), "continuation_scroll_scene_staged");
    CjguiInternalRendererStatus initialPresent = ContinuationPresent(ctx, 2);
    CHECK(ContinuationPresentedStatus(initialPresent) && ctx.composableSceneVersion == 2,
        "continuation_scroll_scene_accepted");
    uint64_t gesture = 0;
    CHECK(ContinuationBeginAtPhaseThree(ctx, &gesture), "continuation_capture_reaches_phase_three");
    uint64_t transfer = 0; int64_t ownerVersion = -1, ownerRevision = -1;
    CjguiInternalRendererStatus receipt = ContinuationInstallRealReceipt(ctx, &transfer,
        &ownerVersion, &ownerRevision);
    CHECK(receipt == CJGUI_INTERNAL_RENDERER_OK && ctx.installedRangeBasis.hasReceipt &&
        ctx.installedRangeBasis.selectionTransferId == transfer &&
        ctx.selectionReceiptTransferId == transfer && ctx.selectionReceiptFocusNodeId == 402,
        "continuation_receipt_is_actual_native_selection_install");
    CHECK(ctx.selectionReceiptOwnerRevision == ownerRevision,
        "continuation_receipt_has_terminal_owner_revision");
    *outContext = ctx; *outGesture = gesture; *outTransfer = transfer;
    *outOwnerVersion = ownerVersion; *outOwnerRevision = ownerRevision;
}

static BOOL ContinuationAdvanceActiveCaptureToPhaseThree(CJGuiInternalSession *ctx, uint64_t gesture,
    uint64_t scene) {
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (!overlay.pointerCaptureActive || overlay.pointerCaptureGestureEpoch != gesture) return NO;
    (void)[overlay updatePointerCaptureAtPoint:NSMakePoint(300, 560)];
    if (overlay.dragEdgeScrollPhase != 1) return NO;
    uint64_t generation = overlay.dragEdgeScrollRequestGeneration;
    CjguiInternalRendererStatus requested = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, (int64_t)generation, 100, 0, scene, 1);
    if (requested != CJGUI_INTERNAL_RENDERER_OK || overlay.dragEdgeScrollPhase != 2) return NO;
    CjguiInternalRendererStatus accepted = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, (int64_t)generation, 100, 100, scene, 2);
    return accepted == CJGUI_INTERNAL_RENDERER_OK && overlay.dragEdgeScrollPhase == 3;
}

static BOOL ContinuationClampAtCurrentScene(CJGuiInternalSession *ctx, uint64_t gesture,
    uint64_t scene) {
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (!overlay.pointerCaptureActive || overlay.pointerCaptureGestureEpoch != gesture) return NO;
    (void)[overlay updatePointerCaptureAtPoint:NSMakePoint(300, 560)];
    if (overlay.dragEdgeScrollPhase != 1 || !overlay.dragEdgeScrollActive) return NO;
    uint64_t generation = overlay.dragEdgeScrollRequestGeneration;
    int64_t accepted = overlay.dragEdgeScrollExpectedOffset;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, (int64_t)generation,
        accepted, accepted, scene, 1);
    return status == CJGUI_INTERNAL_RENDERER_OK && !overlay.dragEdgeScrollActive &&
        overlay.pointerCaptureBoundaryStopped && overlay.pointerCaptureBoundaryGestureEpoch == gesture;
}

static void VerifyPresentedFrameRetiresPaintThenContinuesReceipt(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = nil; uint64_t gesture = 0, transfer = 0;
    int64_t ownerVersion = -1, ownerRevision = -1;
    ContinuationFixtureWithRealReceipt(device, &ctx, &gesture, &transfer, &ownerVersion, &ownerRevision);
    if (!ctx) { CHECK(NO, "continuation_paint_retirement_fixture_ready"); return; }

    // The transfer's independently recorded receipt survives a real accepted
    // frame, while the frame-paint obligation is retired by that same present.
    CHECK(ContinuationStageScene(ctx, 3, NO), "continuation_paint_retirement_same_target_staged");
    CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, ctx.selectionReceiptBindingEpoch, ownerVersion,
        ownerRevision, 3) == CJGUI_INTERNAL_RENDERER_OK,
        "continuation_paint_retirement_publication_staged");
    CjguiInternalRendererStatus presented = ContinuationPresent(ctx, 3);
    CHECK(ContinuationPresentedStatus(presented) && ctx.composableSceneVersion == 3,
        "continuation_paint_retirement_real_frame_accepted");
    CHECK(ctx.selectionPaintTransferId == 0 && ctx.selectionPaintStagedScene == 0 &&
        ctx.selectionPaintOwnerVersion == ownerVersion && ctx.selectionPaintOwnerRevision == ownerRevision &&
        ctx.selectionReceiptTransferId == transfer && ctx.selectionReceiptOwnerVersion == ownerVersion &&
        ctx.selectionReceiptOwnerRevision == ownerRevision &&
        ctx.selectionReceiptSceneVersion == 2,
        "continuation_paint_obligation_retires_receipt_remains_durable");

    // After the real scene3 present, preserve the old receipt through a real
    // phase-1 local-bound stop. This is the production 216->217->218 shape:
    // no new selection is installed to make the receipt appear current.
    CHECK(ContinuationClampAtCurrentScene(ctx, gesture, 3),
        "continuation_paint_retirement_real_post_present_boundary_ack");
    CHECK(ContinuationStageScene(ctx, 4, YES), "continuation_paint_retirement_next_cull_staged");
    CjguiInternalPointerCaptureContinuationOffer offer = {0};
    CHECK(ContinuationOffer(ctx, gesture, 4, transfer, ownerVersion, ownerRevision, &offer),
        "continuation_paint_retirement_old_real_receipt_tuple_frozen");
    CjguiInternalRendererStatus offered = cjgui_internal_renderer_offer_pointer_capture_continuation(
        ctx.rendererSessionToken, &offer);
    CHECK(offered == CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneOverlay.pointerCaptureActive &&
        ctx.composableSceneOverlay.pointerCaptureContinuation != nil,
        "continuation_later_cull_offers_from_durable_real_receipt");
    CHECK(ContinuationPresentedStatus(ContinuationPresent(ctx, 4)) && ctx.composableSceneVersion == 4,
        "continuation_later_cull_scene_really_presented");
    CHECK(ctx.composableSceneOverlay.pointerCaptureContinuation.acceptedSceneInstalled,
        "continuation_later_cull_waits_for_complete");
    CHECK(cjgui_internal_renderer_complete_pointer_capture_continuation(ctx.rendererSessionToken,
        gesture, 4, transfer, ownerVersion, ownerRevision) == CJGUI_INTERNAL_RENDERER_OK &&
        ctx.composableSceneOverlay.pointerCaptureActive &&
        ctx.composableSceneOverlay.pointerCaptureNodeId == 402 &&
        ctx.composableSceneOverlay.pointerCaptureOriginNodeId == 401,
        "continuation_later_cull_completes_same_gesture_from_frozen_receipt");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void VerifyNoOfferStillCancels(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = ProductionFixture(device);
    if (!ctx) { CHECK(NO, "continuation_no_offer_fixture"); return; }
    ctx.windowContentHost = ctx.window.contentView;
    ctx.windowOpaqueFallbackView = [[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer = YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *origin = ContinuationNode(overlay, 401);
    CHECK([overlay beginPointerCaptureForNode:origin atPoint:NSMakePoint(100, 40)],
        "continuation_no_offer_capture_begins");
    CHECK(ContinuationStageScene(ctx, 2, YES), "continuation_no_offer_cull_staged");
    CjguiInternalRendererStatus presented = ContinuationPresent(ctx, 2);
    CHECK(ContinuationPresentedStatus(presented) &&
        !overlay.pointerCaptureActive && overlay.pointerCaptureContinuation == nil,
        "continuation_missing_origin_without_offer_still_cancels");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void VerifyRealOfferContinuesToNewFocus(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = nil; uint64_t gesture = 0, transfer = 0;
    int64_t ownerVersion = -1, ownerRevision = -1;
    ContinuationFixtureWithRealReceipt(device, &ctx, &gesture, &transfer, &ownerVersion, &ownerRevision);
    if (!ctx) { CHECK(NO, "continuation_real_fixture_ready"); return; }
    CjguiInternalPointerCaptureContinuationOffer offer = {0};
    CHECK(ContinuationStageScene(ctx, 3, YES), "continuation_cull_candidate_staged");
    CHECK(ContinuationOffer(ctx, gesture, 3, transfer, ownerVersion, ownerRevision, &offer),
        "continuation_offer_tuple_frozen");
    CjguiInternalPointerCaptureContinuationOffer invalid = offer;
    invalid.selectionTransferId += 1;
    CheckContinuationOfferRejected(ctx, invalid, "continuation_rejects_uninstalled_transfer_receipt");
    invalid = offer; invalid.gestureEpoch += 1;
    CheckContinuationOfferRejected(ctx, invalid, "continuation_rejects_wrong_gesture_epoch");
    invalid = offer; invalid.ownerVersion += 1;
    CheckContinuationOfferRejected(ctx, invalid, "continuation_rejects_wrong_owner_version");
    invalid = offer; invalid.ownerRevision += 1;
    CheckContinuationOfferRejected(ctx, invalid, "continuation_rejects_wrong_owner_revision");
    invalid = offer; invalid.focusNodeId = 403;
    CheckContinuationOfferRejected(ctx, invalid, "continuation_rejects_wrong_receipted_focus_target");
    invalid = offer; invalid.viewportIdentity += 1;
    CheckContinuationOfferRejected(ctx, invalid, "continuation_rejects_wrong_viewport_identity");
    CJGuiInternalComposableSceneNode *stagedFocus = CjguiPointerContinuationFindNode(
        ctx.stagedComposableNodes, 402, 1, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT);
    NSString *savedBinding = [stagedFocus.semanticBindingKey copy];
    stagedFocus.semanticBindingKey = [savedBinding stringByAppendingString:@"-aba"];
    CheckContinuationOfferRejected(ctx, offer, "continuation_rejects_staged_target_aba");
    stagedFocus.semanticBindingKey = savedBinding;
    // Product may already have requested the next windowed source range while
    // the native scene still reports the prior accepted viewport offset.
    // The offer is based on the last accepted acknowledgement; do not require
    // requestedOffset to equal acceptedOffset here.
    offer.requestedOffset = offer.acceptedOffset + 40;
    CjguiInternalRendererStatus offered = cjgui_internal_renderer_offer_pointer_capture_continuation(
        ctx.rendererSessionToken, &offer);
    CHECK(offered == CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneOverlay.pointerCaptureActive &&
        ctx.composableSceneOverlay.pointerCaptureContinuation != nil,
        "continuation_offer_requires_real_receipt_and_active_gesture");
    CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, ctx.selectionReceiptBindingEpoch, ownerVersion,
        ownerRevision, 3) == CJGUI_INTERNAL_RENDERER_OK,
        "continuation_scene_carries_real_selection_publication");
    CjguiInternalRendererStatus presented = ContinuationPresent(ctx, 3);
    CHECK(presented == CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 3,
        "continuation_cull_candidate_really_accepted");
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    BOOL oldQueuedAUnchanged = NO;
    for (CJGuiInternalQueuedInteraction *item in ctx.pendingInteractions) {
        if (item.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE &&
            item.nodeId == offer.originNodeId && item.projectionVersion == 2) oldQueuedAUnchanged = YES;
    }
    CHECK(oldQueuedAUnchanged, "continuation_does_not_reticket_old_queued_pointer_update");
    CHECK(overlay.pointerCaptureActive && overlay.pointerCaptureNodeId == offer.originNodeId &&
        overlay.pointerCaptureContinuation.acceptedSceneInstalled,
        "continuation_scene_accept_pauses_before_retarget");
    NSUInteger interactionsBeforeComplete = ctx.pendingInteractions.count;
    CjguiInternalRendererStatus completed = cjgui_internal_renderer_complete_pointer_capture_continuation(
        ctx.rendererSessionToken, gesture, 3, transfer, ownerVersion, ownerRevision);
    CHECK(completed == CJGUI_INTERNAL_RENDERER_OK && overlay.pointerCaptureActive &&
        overlay.pointerCaptureNodeId == 402 && overlay.pointerCaptureOriginNodeId == 401 &&
        overlay.pointerCaptureHasContinued && overlay.pointerCaptureContinuation == nil,
        "continuation_complete_moves_only_current_target_to_receipted_focus");
    CHECK(ctx.pendingInteractions.count == interactionsBeforeComplete,
        "continuation_complete_emits_no_move_or_scroll");
    [overlay advanceDragEdgeScrollAtMicros:UINT64_MAX];
    CHECK(overlay.dragEdgeScrollPhase == 1 && ctx.pendingInteractions.count == interactionsBeforeComplete + 1,
        "continuation_next_residence_tick_uses_current_focus");
    CjguiInternalRendererStatus request = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, 2, 120, 100, 3, 1);
    CjguiInternalRendererStatus accept = request == CJGUI_INTERNAL_RENDERER_OK
        ? cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken, gesture,
            900, 2, 71, 19, 2, 120, 120, 3, 2) : request;
    CJGuiInternalQueuedInteraction *latestUpdate = nil;
    for (CJGuiInternalQueuedInteraction *item in [ctx.pendingInteractions reverseObjectEnumerator]) {
        if (item.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE) {
            latestUpdate = item; break;
        }
    }
    CHECK(accept == CJGUI_INTERNAL_RENDERER_OK && latestUpdate && latestUpdate.nodeId == 402 &&
        latestUpdate.projectionVersion == 3,
        "continuation_phase_two_rehit_is_new_focus_and_new_accepted_scene");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void VerifyTwoWindowedContinuationsAdvanceCurrentSegment(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = nil; uint64_t gesture = 0, transferB = 0;
    int64_t ownerVersion = -1, ownerRevision = -1;
    ContinuationFixtureWithRealReceipt(device, &ctx, &gesture, &transferB, &ownerVersion, &ownerRevision);
    if (!ctx) { CHECK(NO, "continuation_chain_fixture_ready"); return; }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;

    // First accepted window keeps B as the new focus and includes C so a real
    // second selection receipt can be installed while B remains current.
    CHECK(ContinuationStageRouteScene(ctx, 3, 401, YES),
        "continuation_chain_first_candidate_culls_A_and_keeps_C_available");
    CjguiInternalPointerCaptureContinuationOffer offerB = {0};
    CHECK(ContinuationOffer(ctx, gesture, 3, transferB, ownerVersion, ownerRevision, &offerB),
        "continuation_chain_first_offer_uses_A_segment");
    CHECK(cjgui_internal_renderer_offer_pointer_capture_continuation(ctx.rendererSessionToken, &offerB) ==
        CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
            transferB, ctx.sessionGeneration, offerB.selectionBindingEpoch, ownerVersion,
            ownerRevision, 3) == CJGUI_INTERNAL_RENDERER_OK &&
        ContinuationPresentedStatus(ContinuationPresent(ctx, 3)),
        "continuation_chain_first_scene_accepted_with_actual_receipt");
    CHECK(cjgui_internal_renderer_complete_pointer_capture_continuation(ctx.rendererSessionToken,
        gesture, 3, transferB, ownerVersion, ownerRevision) == CJGUI_INTERNAL_RENDERER_OK &&
        overlay.pointerCaptureOriginNodeId == 401 && overlay.pointerCaptureNodeId == 402,
        "continuation_chain_first_complete_preserves_logical_A_and_routes_B");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(ctx.rendererSessionToken, transferB) ==
        CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_release(ctx.rendererSessionToken, transferB) ==
        CJGUI_INTERNAL_RENDERER_OK,
        "continuation_chain_first_real_receipt_retires_through_normal_transfer_lifecycle");

    // Drive B through a real acknowledged phase-3 viewport cycle. Its queued
    // update keeps B's original node and scene identity across the next rebase.
    [overlay stopDragEdgeScroll];
    overlay.dragEdgeViewportIdentity = 19;
    overlay.dragEdgeViewportBinding = 71;
    overlay.dragEdgeScrollOwnerNode = 900;
    overlay.dragEdgeScrollOwnerResource = 2;
    [overlay applyPointerCaptureEdgeScrollForNode:ContinuationNode(overlay, 402)
        atPoint:NSMakePoint(300, 560)];
    CHECK(overlay.dragEdgeScrollPhase == 1, "continuation_chain_B_starts_new_scroll_cycle");
    CjguiInternalRendererStatus requestB = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, 8, 180, 160, 3, 1);
    CjguiInternalRendererStatus acceptB = requestB == CJGUI_INTERNAL_RENDERER_OK
        ? cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
            gesture, 900, 2, 71, 19, 8, 180, 180, 3, 2) : requestB;
    CHECK(acceptB == CJGUI_INTERNAL_RENDERER_OK && overlay.dragEdgeScrollPhase == 3,
        "continuation_chain_B_reaches_acknowledged_phase_three");
    uint64_t transferC = 0; int64_t ownerVersionC = -1, ownerRevisionC = -1;
    CjguiInternalRendererStatus receiptC = ContinuationInstallRealReceiptForTarget(ctx, 404, 23, &transferC,
        &ownerVersionC, &ownerRevisionC);
    CHECK(receiptC == CJGUI_INTERNAL_RENDERER_OK && ctx.selectionReceiptFocusNodeId == 404,
        "continuation_chain_C_has_new_real_installed_selection_receipt");
    CJGuiInternalQueuedInteraction *queuedB = nil;
    for (CJGuiInternalQueuedInteraction *item in [ctx.pendingInteractions reverseObjectEnumerator]) {
        if (item.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE) {
            queuedB = item; break;
        }
    }
    CHECK(queuedB && queuedB.nodeId == 402 && queuedB.projectionVersion == 3,
        "continuation_chain_B_update_keeps_B_scene_identity");

    // The next offer describes B as the current segment origin while A remains
    // the immutable logical origin of the same physical gesture.
    CHECK(ContinuationStageRouteScene(ctx, 4, 402, NO),
        "continuation_chain_second_candidate_culls_B");
    CjguiInternalPointerCaptureContinuationOffer offerC = {0};
    CHECK(ContinuationOffer(ctx, gesture, 4, transferC, ownerVersionC, ownerRevisionC, &offerC) &&
        offerC.originNodeId == 402 && offerC.originProjectionVersion == 3 && offerC.focusNodeId == 404,
        "continuation_chain_second_offer_is_B_to_C_not_A_to_C");
    CjguiInternalRendererStatus offeredC = cjgui_internal_renderer_offer_pointer_capture_continuation(
        ctx.rendererSessionToken, &offerC);
    CHECK(offeredC == CJGUI_INTERNAL_RENDERER_OK,
        "continuation_chain_second_offer_accepts_same_gesture_current_segment");
    CjguiInternalRendererStatus stagePaintC = cjgui_internal_renderer_stage_selection_paint_publication(
        ctx.rendererSessionToken, transferC, ctx.sessionGeneration, offerC.selectionBindingEpoch,
        ownerVersionC, ownerRevisionC, 4);
    CjguiInternalRendererStatus presentC = ContinuationPresent(ctx, 4);
    CHECK(stagePaintC == CJGUI_INTERNAL_RENDERER_OK && ContinuationPresentedStatus(presentC),
        "continuation_chain_second_scene_accepted_with_C_receipt");
    NSUInteger beforeComplete = ctx.pendingInteractions.count;
    CjguiInternalRendererStatus completedC = cjgui_internal_renderer_complete_pointer_capture_continuation(
        ctx.rendererSessionToken, gesture, 4, transferC, ownerVersionC, ownerRevisionC);
    CHECK(completedC == CJGUI_INTERNAL_RENDERER_OK && overlay.pointerCaptureActive &&
        overlay.pointerCaptureOriginNodeId == 401 && overlay.pointerCaptureNodeId == 404 &&
        overlay.pointerCaptureContinuation == nil,
        "continuation_chain_second_complete_preserves_A_and_routes_C");
    CHECK(ctx.pendingInteractions.count == beforeComplete && queuedB.nodeId == 402 &&
        queuedB.projectionVersion == 3,
        "continuation_chain_never_retickets_queued_B_update_as_C");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void VerifyRejectedCandidateDiscards(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = nil; uint64_t gesture = 0, transfer = 0;
    int64_t ownerVersion = -1, ownerRevision = -1;
    ContinuationFixtureWithRealReceipt(device, &ctx, &gesture, &transfer, &ownerVersion, &ownerRevision);
    if (!ctx) { CHECK(NO, "continuation_rejected_fixture_ready"); return; }
    CHECK(ContinuationStageScene(ctx, 3, YES), "continuation_rejected_candidate_staged");
    CjguiInternalPointerCaptureContinuationOffer offer = {0};
    CHECK(ContinuationOffer(ctx, gesture, 3, transfer, ownerVersion, ownerRevision, &offer),
        "continuation_rejected_offer_frozen");
    CHECK(cjgui_internal_renderer_offer_pointer_capture_continuation(ctx.rendererSessionToken, &offer) ==
        CJGUI_INTERNAL_RENDERER_OK, "continuation_rejected_offer_accepted");
    CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, offer.selectionBindingEpoch, ownerVersion,
        ownerRevision, 3) == CJGUI_INTERNAL_RENDERER_OK,
        "continuation_rejected_scene_has_real_selection_publication");
    // Existing scene admission must reject an incomplete staged menu. This
    // exercises the production rollback path without a synthetic test hook.
    ctx.stagedComposableCommandMenuVersion = 3;
    CJGuiInternalComposableCommandMenuItem *invalidMenuItem = [CJGuiInternalComposableCommandMenuItem new];
    invalidMenuItem.commandId = @"";
    invalidMenuItem.title = @"Invalid staged command";
    [ctx.stagedComposableCommandMenuItems addObject:invalidMenuItem];
    CjguiInternalRendererStatus refused = ContinuationPresent(ctx, 3);
    CHECK(refused == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR && ctx.composableSceneVersion == 2,
        "continuation_candidate_rejected_before_acceptance");
    CjguiInternalRendererStatus discarded = cjgui_internal_renderer_discard_pointer_capture_continuation(
        ctx.rendererSessionToken, gesture, 3);
    CHECK(discarded == CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneOverlay.pointerCaptureActive &&
        ctx.composableSceneOverlay.pointerCaptureContinuation == nil &&
        ctx.composableSceneOverlay.pointerCaptureNodeId == offer.originNodeId,
        "continuation_discard_rearms_only_old_accepted_target");
    CjguiInternalRendererStatus late = cjgui_internal_renderer_complete_pointer_capture_continuation(
        ctx.rendererSessionToken, gesture, 3, transfer, ownerVersion, ownerRevision);
    CHECK(late == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.composableSceneOverlay.pointerCaptureNodeId == offer.originNodeId,
        "continuation_rejected_scene_cannot_complete_late");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void VerifyClampedViewportLeaseCanContinue(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = nil; uint64_t gesture = 0, transfer = 0;
    int64_t ownerVersion = -1, ownerRevision = -1;
    ContinuationFixtureWithRealReceipt(device, &ctx, &gesture, &transfer, &ownerVersion, &ownerRevision);
    if (!ctx) { CHECK(NO, "continuation_clamped_fixture_ready"); return; }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *origin = ContinuationNode(overlay, 401);
    [overlay stopDragEdgeScroll];
    overlay.dragEdgeViewportIdentity = 19;
    overlay.dragEdgeViewportBinding = 71;
    overlay.dragEdgeScrollOwnerNode = 900;
    overlay.dragEdgeScrollOwnerResource = 2;
    [overlay applyPointerCaptureEdgeScrollForNode:origin atPoint:NSMakePoint(300, 560)];
    CHECK(overlay.pointerCaptureActive && overlay.dragEdgeScrollActive &&
        overlay.dragEdgeScrollPhase == 1, "continuation_clamped_fixture_queues_real_capture_scroll");
    CjguiInternalRendererStatus clamped = cjgui_internal_renderer_ack_drag_edge_viewport(
        ctx.rendererSessionToken, gesture, 900, 2, 71, 19, 2, 100, 100,
        ctx.composableSceneVersion, 1);
    CHECK(clamped == CJGUI_INTERNAL_RENDERER_OK && overlay.pointerCaptureActive &&
        !overlay.dragEdgeScrollActive && overlay.pointerCaptureBoundaryStopped &&
        overlay.pointerCaptureBoundaryGestureEpoch == gesture,
        "continuation_real_clamped_ack_stops_driver_but_retains_pressed_lease");
    CHECK(ContinuationStageScene(ctx, 3, YES), "continuation_clamped_candidate_staged");
    CjguiInternalPointerCaptureContinuationOffer offer = {0};
    CHECK(ContinuationOffer(ctx, gesture, 3, transfer, ownerVersion, ownerRevision, &offer),
        "continuation_clamped_offer_frozen");
    // The candidate reveal has a newer requested generation/offset. The native
    // lease check is against the old clamped ACK's accepted owner geometry.
    offer.requestGeneration = 9;
    offer.requestedOffset = 140;
    offer.acceptedOffset = 100;
    CHECK(cjgui_internal_renderer_offer_pointer_capture_continuation(ctx.rendererSessionToken, &offer) ==
        CJGUI_INTERNAL_RENDERER_OK, "continuation_clamped_offer_ignores_pending_request_generation");
    CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, offer.selectionBindingEpoch, ownerVersion,
        ownerRevision, 3) == CJGUI_INTERNAL_RENDERER_OK &&
        ContinuationPresentedStatus(ContinuationPresent(ctx, 3)) && ctx.composableSceneVersion == 3,
        "continuation_clamped_candidate_is_really_accepted");
    CHECK(overlay.pointerCaptureActive && overlay.pointerCaptureContinuation.acceptedSceneInstalled,
        "continuation_clamped_scene_waits_for_owner_completion");
    CHECK(cjgui_internal_renderer_complete_pointer_capture_continuation(ctx.rendererSessionToken,
        gesture, 3, transfer, ownerVersion, ownerRevision) == CJGUI_INTERNAL_RENDERER_OK &&
        overlay.pointerCaptureActive && overlay.pointerCaptureNodeId == 402 &&
        !overlay.pointerCaptureBoundaryStopped && overlay.dragEdgeScrollActive,
        "continuation_clamped_lease_rearms_only_after_current_scene_completion");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void VerifyUpAndInvalidOfferCannotRevive(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = nil; uint64_t gesture = 0, transfer = 0;
    int64_t ownerVersion = -1, ownerRevision = -1;
    ContinuationFixtureWithRealReceipt(device, &ctx, &gesture, &transfer, &ownerVersion, &ownerRevision);
    if (!ctx) { CHECK(NO, "continuation_up_fixture_ready"); return; }
    CjguiInternalPointerCaptureContinuationOffer offer = {0};
    CHECK(ContinuationStageScene(ctx, 3, YES), "continuation_up_candidate_staged");
    CHECK(ContinuationOffer(ctx, gesture, 3, transfer, ownerVersion, ownerRevision, &offer),
        "continuation_up_offer_tuple");
    offer.coordinateGeneration += 1;
    CHECK(cjgui_internal_renderer_offer_pointer_capture_continuation(ctx.rendererSessionToken, &offer) ==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.composableSceneOverlay.pointerCaptureActive,
        "continuation_wrong_coordinate_offer_rejected_without_capture_mutation");
    offer.coordinateGeneration -= 1;
    CHECK(cjgui_internal_renderer_offer_pointer_capture_continuation(ctx.rendererSessionToken, &offer) ==
        CJGUI_INTERNAL_RENDERER_OK, "continuation_valid_offer_after_negative_control");
    CHECK(cjgui_internal_renderer_stage_selection_paint_publication(ctx.rendererSessionToken,
        transfer, ctx.sessionGeneration, ctx.selectionReceiptBindingEpoch, ownerVersion,
        ownerRevision, 3) == CJGUI_INTERNAL_RENDERER_OK && ContinuationPresent(ctx, 3) ==
        CJGUI_INTERNAL_RENDERER_OK, "continuation_up_candidate_accepts");
    [ctx.composableSceneOverlay endPointerCaptureAtPoint:NSMakePoint(300, 560) cancelled:NO];
    CjguiInternalRendererStatus late = cjgui_internal_renderer_complete_pointer_capture_continuation(
        ctx.rendererSessionToken, gesture, 3, transfer, ownerVersion, ownerRevision);
    CHECK(late == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        !ctx.composableSceneOverlay.pointerCaptureActive &&
        !ctx.composableSceneOverlay.dragEdgeScrollActive,
        "continuation_up_before_complete_is_terminal_and_late_complete_cannot_revive");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 77;
    VerifyNoOfferStillCancels(device);
    VerifyPresentedFrameRetiresPaintThenContinuesReceipt(device);
    VerifyRealOfferContinuesToNewFocus(device);
    VerifyTwoWindowedContinuationsAdvanceCurrentSegment(device);
    VerifyUpAndInvalidOfferCannotRevive(device);
    VerifyRejectedCandidateDiscards(device);
    VerifyClampedViewportLeaseCanContinue(device);
    fprintf(stderr, "pointer_capture_continuation failures=%d\n", failures);
    return failures ? 1 : 0;
} }
