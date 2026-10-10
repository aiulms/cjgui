// Normal native transfer route; intentionally built without
// CJGUI_INTERNAL_TESTING and with owner phase tracing disabled.
#import "../cjgui_internal_renderer.m"

static int failures = 0;
#define CHECK(condition, name) do { BOOL ok = (condition); \
    fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name); if (!ok) failures++; } while (0)

static CJGuiInternalSession *ProductionFixture(id<MTLDevice> device) {
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
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x = 0; raw.y = index * 130; raw.width = 680; raw.height = 120;
        raw.clipWidth = 680; raw.clipHeight = 500; raw.fontSize = 13;
        raw.textAlpha = 1; raw.isInteractive = 1;
        node.node = raw; node.index = (uint32_t)index;
        node.value = index == 0 ? @"abcde" : (index == 1 ? @"FGHIJ" : @"KLMNO");
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
    ctx.ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    ctx.ownedTextSessionBindingEpoch = 81;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    if (![overlay focusCommittedNodeId:401]) return nil;
    [ctx.pendingInteractions removeAllObjects];
    return ctx;
}

static BOOL InstallSelectionOnSameAcceptedScene(CJGuiInternalSession *ctx,
                                                uint32_t anchor, uint32_t focus) {
    uint64_t token = ctx.rendererSessionToken, transfer = 0;
    CjguiInternalRendererStatus create = cjgui_internal_renderer_selection_transfer_create(token, &transfer);
    if (create != CJGUI_INTERNAL_RENDERER_OK || transfer == 0) {
        fprintf(stderr, "selection transfer create failed status=%u id=%llu\n", create,
            (unsigned long long)transfer);
        return NO;
    }
    CJGuiInternalComposableSceneNode *target = ctx.composableSceneOverlay.nodes[1];
    NSData *targetBody = [target.value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate = {0};
    candidate.transferId = transfer;
    candidate.sourceWindowInstanceToken = ctx.installedRangeBasis.candidate.windowInstanceToken
        ? ctx.installedRangeBasis.candidate.windowInstanceToken : 9101;
    candidate.sourceOwnerVersion = ctx.installedRangeBasis.candidate.ownerVersion != 0
        ? ctx.installedRangeBasis.candidate.ownerVersion : 10;
    candidate.sourceContextEpoch = ctx.installedRangeBasis.candidate.contextEpoch
        ? ctx.installedRangeBasis.candidate.contextEpoch : 4;
    candidate.sourceMirrorRevision = ctx.installedRangeBasis.candidate.mirrorRevision
        ? ctx.installedRangeBasis.candidate.mirrorRevision : 2;
    candidate.targetNodeId = 402;
    // Zero asks capture_current to resolve the COW payload in the exact
    // accepted scene. The returned candidate must carry the real payload
    // projection before any later phase consumes it.
    candidate.targetProjectionVersion = 0;
    candidate.targetResourceId = 1;
    candidate.targetNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion = ctx.composableSceneVersion;
    candidate.targetAnchor16 = anchor;
    candidate.targetFocus16 = focus;
    candidate.targetBodyUtf8 = targetBody.bytes;
    candidate.targetBodyUtf8Length = (uint32_t)targetBody.length;
    uint8_t actual[65536] = {0};
    CjguiInternalRendererStatus captured = cjgui_internal_renderer_selection_transfer_capture_current(
        token, &candidate, actual, sizeof(actual));
    CjguiInternalRendererStatus published = captured == CJGUI_INTERNAL_RENDERER_OK
        ? cjgui_internal_renderer_selection_transfer_publish_pending(token, transfer)
        : captured;
    if (captured != CJGUI_INTERNAL_RENDERER_OK || published != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "selection transfer capture/publish failed capture=%u publish=%u scene=%llu targetScene=%llu targetProjection=%llu payload=%llu active=%llu\n",
            captured, published, (unsigned long long)ctx.composableSceneVersion,
            (unsigned long long)candidate.targetSceneVersion,
            (unsigned long long)candidate.targetProjectionVersion,
            (unsigned long long)target.node.projectionVersion,
            (unsigned long long)ctx.composableSceneOverlay.activeProjectionVersion);
        return NO;
    }
    if (candidate.targetProjectionVersion != target.node.projectionVersion) {
        fprintf(stderr, "capture did not freeze actual COW projection resolved=%llu actual=%llu\n",
            (unsigned long long)candidate.targetProjectionVersion,
            (unsigned long long)target.node.projectionVersion);
        (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
        (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
        return NO;
    }
    CjguiInternalSelectionTransferReceipt receipt = {0};
    CjguiInternalRendererStatus installed =
        cjgui_internal_renderer_selection_transfer_install_b(token, transfer, &receipt);
    fprintf(stderr, "install selection status=%u scene=%llu target_payload=%llu active_payload=%llu range=%u:%u\n",
        installed, (unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)target.node.projectionVersion,
        (unsigned long long)ctx.composableSceneOverlay.activeProjectionVersion, anchor, focus);
    (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token, transfer);
    (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
    return installed == CJGUI_INTERNAL_RENDERER_OK &&
        ctx.composableSceneVersion == candidate.targetSceneVersion && ctx.installedRangeBasis.hasReceipt &&
        ctx.installedRangeBasis.selectionTransferId == transfer &&
        receipt.sceneVersion == candidate.targetSceneVersion &&
        receipt.projectionVersion == target.node.projectionVersion &&
        ctx.composableSceneOverlay.inputProxy.selectedRange.location == MIN(anchor, focus) &&
        ctx.composableSceneOverlay.inputProxy.selectedRange.length == (NSUInteger)llabs((int64_t)focus - (int64_t)anchor);
}

static CjguiInternalSelectionTransferCandidate CaptureCandidateForTarget(
    CJGuiInternalSession *ctx, uint64_t transfer, uint64_t sceneVersion,
    uint64_t projectionVersion, NSData *body) {
    CjguiInternalSelectionTransferCandidate candidate = {0};
    candidate.transferId = transfer;
    candidate.sourceWindowInstanceToken = 9101;
    candidate.sourceOwnerVersion = 10;
    candidate.sourceContextEpoch = 4;
    candidate.sourceMirrorRevision = 2;
    candidate.targetNodeId = 402;
    candidate.targetProjectionVersion = projectionVersion;
    candidate.targetResourceId = 1;
    candidate.targetNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion = sceneVersion;
    candidate.targetAnchor16 = 2;
    candidate.targetFocus16 = 4;
    candidate.targetBodyUtf8 = body.bytes;
    candidate.targetBodyUtf8Length = (uint32_t)body.length;
    (void)ctx;
    return candidate;
}

static void VerifyCaptureCurrentRejectsWrongIdentity(id<MTLDevice> device,
                                                      const char *name,
                                                      uint64_t targetScene,
                                                      uint64_t targetProjection,
                                                      BOOL wrongBody) {
    CJGuiInternalSession *ctx = ProductionFixture(device);
    if (!ctx) {
        CHECK(NO, name);
        return;
    }
    uint64_t token = ctx.rendererSessionToken, transfer = 0;
    NSData *body = [ctx.composableSceneOverlay.nodes[1].value dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *badBody = [body mutableCopy];
    if (wrongBody && badBody.length) ((uint8_t *)badBody.mutableBytes)[0] ^= 1;
    uint32_t initialState = 0, initialRefs = 0;
    uint8_t initialCancelled = 0;
    NSAttributedString *initialProxyBody = [ctx.composableSceneOverlay.inputProxy.attributedString copy];
    NSRange initialSelection = ctx.composableSceneOverlay.inputProxy.selectedRange;
    uint64_t initialNode = ctx.composableSceneOverlay.activeNodeId;
    uint64_t initialProjection = ctx.composableSceneOverlay.activeProjectionVersion;
    int64_t initialResource = ctx.composableSceneOverlay.activeNodeResourceId;
    uint32_t initialKind = ctx.composableSceneOverlay.activeNodeKind;
    uint64_t initialTail = ctx.installedRangeLocalTailSequence;
    uint64_t initialAck = ctx.installedRangeObservedAckSequence;
    uint64_t initialBytes = ctx.installedRangeBytesUsed;
    uint64_t initialReserved = ctx.installedRangeBytesReserved;
    CjguiInstalledRangeState *initialBasis = ctx.installedRangeBasis;
    CjguiInternalRendererStatus created = cjgui_internal_renderer_selection_transfer_create(token, &transfer);
    CHECK(created == CJGUI_INTERNAL_RENDERER_OK && transfer != 0, "negative_capture_creates_native_transfer");
    CjguiInternalSelectionTransferCandidate candidate = CaptureCandidateForTarget(ctx, transfer,
        targetScene, targetProjection, wrongBody ? badBody : body);
    uint8_t actual[65536] = {0};
    CjguiInternalRendererStatus captured = cjgui_internal_renderer_selection_transfer_capture_current(
        token, &candidate, actual, sizeof(actual));
    CjguiInternalRendererStatus stateStatus = cjgui_internal_renderer_selection_transfer_state(
        token, transfer, &initialState, &initialCancelled, &initialRefs);
    BOOL rejectedWithoutMutation = captured == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        stateStatus == CJGUI_INTERNAL_RENDERER_OK && initialState == CJGUI_SELECTION_TRANSFER_PREPARING &&
        !initialCancelled && initialRefs == 2 && ctx.selectionTransferCapsule == nil &&
        ctx.selectionTransferId == 0 && ctx.composableSceneOverlay.inputProxy.selectedRange.location == initialSelection.location &&
        ctx.composableSceneOverlay.inputProxy.selectedRange.length == initialSelection.length &&
        [ctx.composableSceneOverlay.inputProxy.attributedString isEqualToAttributedString:initialProxyBody] &&
        ctx.composableSceneOverlay.activeNodeId == initialNode &&
        ctx.composableSceneOverlay.activeProjectionVersion == initialProjection &&
        ctx.composableSceneOverlay.activeNodeResourceId == initialResource &&
        ctx.composableSceneOverlay.activeNodeKind == initialKind &&
        ctx.installedRangeBasis == initialBasis &&
        ctx.installedRangeLocalTailSequence == initialTail && ctx.installedRangeObservedAckSequence == initialAck &&
        ctx.installedRangeBytesUsed == initialBytes && ctx.installedRangeBytesReserved == initialReserved;
    fprintf(stderr, "capture negative %s status=%u state=%u refs=%u scene=%llu request_scene=%llu request_projection=%llu actual_projection=%llu native_tail_delta=%llu native_ack_delta=%llu owner_transactions=not-present-in-native-fixture\n",
        name, captured, initialState, initialRefs, (unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)targetScene, (unsigned long long)targetProjection,
        (unsigned long long)ctx.composableSceneOverlay.nodes[1].node.projectionVersion,
        (unsigned long long)(ctx.installedRangeLocalTailSequence - initialTail),
        (unsigned long long)(ctx.installedRangeObservedAckSequence - initialAck));
    CHECK(rejectedWithoutMutation, name);
    if (stateStatus == CJGUI_INTERNAL_RENDERER_OK) {
        (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
        (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
    }
    cjgui_internal_renderer_destroy(token);
}

static void VerifySparseCowTransfer(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = ProductionFixture(device);
    if (!ctx) {
        CHECK(NO, "sparse_production_fixture");
        return;
    }
    uint64_t token = ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_configure_composable_scene(token, 2, 3) ==
              CJGUI_INTERNAL_RENDERER_OK,
          "sparse_fixture_configures_next_scene");
    CjguiInternalRendererComposableGeometry geometry = {0};
    CjguiInternalRendererStatus geometryStatus = CJGUI_INTERNAL_RENDERER_OK;
    for (uint32_t index = 0; index < 3; index++) {
        geometry = (CjguiInternalRendererComposableGeometry){0};
        geometry.nodeId = 401 + index;
        CjguiInternalRendererStatus one = cjgui_internal_renderer_set_composable_scene_geometry(
            token, 2, index, &geometry);
        if (one != CJGUI_INTERNAL_RENDERER_OK) geometryStatus = one;
    }
    CHECK(geometryStatus == CJGUI_INTERNAL_RENDERER_OK,
          "sparse_fixture_establishes_explicit_identity_geometry");
    CjguiInternalRendererStatus sparseStatus = CjguiCommitComposableSceneOnMain(token);
    fprintf(stderr, "sparse scene commit status=%u staged=%llu live=%llu\n", sparseStatus,
        (unsigned long long)ctx.stagedComposableSceneVersion,
        (unsigned long long)ctx.composableSceneVersion);
    CHECK(sparseStatus == CJGUI_INTERNAL_RENDERER_OK,
          "sparse_fixture_commits_next_scene");
    if (sparseStatus == CJGUI_INTERNAL_RENDERER_OK)
        [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    fprintf(stderr, "sparse versions scene=%llu p0=%llu p1=%llu p2=%llu active=%llu\n",
        (unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)ctx.view.composableNodes[0].node.projectionVersion,
        (unsigned long long)ctx.view.composableNodes[1].node.projectionVersion,
        (unsigned long long)ctx.view.composableNodes[2].node.projectionVersion,
        (unsigned long long)ctx.composableSceneOverlay.activeProjectionVersion);
    CHECK(ctx.composableSceneVersion == 2 && ctx.view.composableNodes[0].node.projectionVersion == 2 &&
          ctx.view.composableNodes[1].node.projectionVersion == 2 &&
          ctx.view.composableNodes[2].node.projectionVersion == 2,
          "sparse_fixture_identity_geometry_scene_committed");
    CHECK(cjgui_internal_renderer_configure_composable_scene(token, 3, 3) ==
              CJGUI_INTERNAL_RENDERER_OK,
          "sparse_fixture_configures_following_scene");
    geometryStatus = CJGUI_INTERNAL_RENDERER_OK;
    for (uint32_t index = 0; index < 3; index++) {
        geometry = ctx.view.composableNodes[index].geometry;
        geometry.nodeId = 401 + index;
        if (index == 0) geometry.translateX += 1.0;
        CjguiInternalRendererStatus one = cjgui_internal_renderer_set_composable_scene_geometry(
            token, 3, index, &geometry);
        if (one != CJGUI_INTERNAL_RENDERER_OK) geometryStatus = one;
    }
    CHECK(geometryStatus == CJGUI_INTERNAL_RENDERER_OK,
          "sparse_fixture_changes_only_non_target_node");
    sparseStatus = CjguiCommitComposableSceneOnMain(token);
    fprintf(stderr, "sparse second commit status=%u staged=%llu live=%llu\n", sparseStatus,
        (unsigned long long)ctx.stagedComposableSceneVersion,
        (unsigned long long)ctx.composableSceneVersion);
    CHECK(sparseStatus == CJGUI_INTERNAL_RENDERER_OK,
          "sparse_fixture_commits_scene_with_older_target_payload");
    if (sparseStatus == CJGUI_INTERNAL_RENDERER_OK)
        [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    fprintf(stderr, "sparse versions scene=%llu p0=%llu p1=%llu p2=%llu active=%llu\n",
        (unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)ctx.view.composableNodes[0].node.projectionVersion,
        (unsigned long long)ctx.view.composableNodes[1].node.projectionVersion,
        (unsigned long long)ctx.view.composableNodes[2].node.projectionVersion,
        (unsigned long long)ctx.composableSceneOverlay.activeProjectionVersion);
    CHECK(ctx.composableSceneVersion == 3 && ctx.view.composableNodes[0].node.projectionVersion == 3 &&
          ctx.view.composableNodes[1].node.projectionVersion == 2 &&
          ctx.view.composableNodes[2].node.projectionVersion == 2,
          "sparse_scene_has_distinct_payload_versions");
    if (ctx.composableSceneVersion == 3 && ctx.view.composableNodes.count == 3) {
        // Seed an accepted declaration on an unchanged COW node to exercise
        // cross-fragment suppression when its payload version is older than
        // the current scene and active target.
        ctx.view.composableNodes[2].textDeclaredSelectionDecorations = @[@{
            @"rect": [NSValue valueWithRect:NSMakeRect(0, 260, 30, 20)],
            @"color": NSColor.selectedTextBackgroundColor }];
        CHECK(InstallSelectionOnSameAcceptedScene(ctx, 0, 5),
              "sparse_scene_real_native_install_b_uses_reused_target");
        CJGuiInternalComposableSceneNode *target = ctx.composableSceneOverlay.nodes[1];
        NSArray<NSValue *> *effectiveRects = CjguiEffectiveTransferTextSelectionRects(ctx, target);
        CHECK(ctx.composableSceneVersion == 3 && target.node.projectionVersion == 2 &&
              ctx.composableSceneOverlay.activeProjectionVersion == 2 && effectiveRects.count > 0 &&
              CjguiEffectiveDeclaredSelectionDecorations(ctx, ctx.view.composableNodes[2]).count == 1 &&
              ctx.view.composableNodes[2].textDeclaredSelectionDecorations.count == 1,
              "sparse_scene_keeps_other_declarations_until_coherent_publication");
    }
    cjgui_internal_renderer_destroy(token);

    // Exercise the native capture gate directly. Each malformed request must
    // be rejected before any capsule/proxy/A mutation or owner transaction.
    CJGuiInternalSession *negative = ProductionFixture(device);
    if (negative) {
        uint64_t scene = negative.composableSceneVersion;
        uint64_t payloadProjection = negative.composableSceneOverlay.nodes[1].node.projectionVersion;
        NSData *body = [negative.composableSceneOverlay.nodes[1].value dataUsingEncoding:NSUTF8StringEncoding];
        cjgui_internal_renderer_destroy(negative.rendererSessionToken);
        VerifyCaptureCurrentRejectsWrongIdentity(device, "wrong_target_scene_rejected_before_native_mutation",
            scene + 1, 0, NO);
        VerifyCaptureCurrentRejectsWrongIdentity(device, "wrong_nonzero_projection_rejected_before_native_mutation",
            scene, payloadProjection + 1, NO);
        VerifyCaptureCurrentRejectsWrongIdentity(device, "wrong_complete_body_rejected_before_native_mutation",
            scene, 0, YES);
        (void)body;
    }
}

int main(void) {
    @autoreleasepool {
        unsetenv("CJGUI_OWNER_PHASE_TRACE");
        unsetenv("CJGUI_OWNER_TURN_TRACE");
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "SKIP no Metal device\n");
            return 77;
        }
        CJGuiInternalSession *ctx = ProductionFixture(device);
        if (!ctx) {
            fprintf(stderr, "FAIL production fixture\n");
            return 1;
        }
        uint64_t token = ctx.rendererSessionToken;
        NSString *runs = @"0:5:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1";
        // This is ordinary owner-declared caret geometry in the accepted
        // scene; the collapsed proxy transfer must keep it visible while old
        // owner selection declarations are filtered from effective paint.
        ctx.composableSceneOverlay.hasDeclaredInputCaret = YES;
        ctx.composableSceneOverlay.declaredInputCaretNodeId = 402;
        ctx.composableSceneOverlay.declaredInputCaretRect = NSMakeRect(34, 4, 1.5, 18);
        (void)cjgui_internal_renderer_configure_composable_scene(token, 2, 3);
        ctx.stagedComposableDataTransferVersion = 2;
        (void)cjgui_internal_renderer_set_composable_text_runs(token, 401, runs.UTF8String);
        NSString *targetRuns = @"0:2:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1";
        (void)cjgui_internal_renderer_set_composable_text_runs(token, 402, targetRuns.UTF8String);
        CHECK(CjguiCommitComposableSceneOnMain(token) == CJGUI_INTERNAL_RENDERER_OK,
              "accepted_scene_with_two_owner_selection_fragments");
        [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
        CHECK(ctx.view.composableNodes.count == 3 &&
              ctx.view.composableNodes[0].textDeclaredSelectionDecorations.count > 0 &&
              ctx.view.composableNodes[1].textDeclaredSelectionDecorations.count > 0 &&
              !NSIsEmptyRect(ctx.view.composableNodes[1].textCaretRect),
              "accepted_scene_contains_real_declared_fragment_selection_geometry");
        NSDictionary *oldTargetDecoration = ctx.view.composableNodes[1].textDeclaredSelectionDecorations.firstObject;
        NSRect oldTargetSelection = [oldTargetDecoration[@"rect"] rectValue];

        uint64_t transfer = 0;
        CHECK(cjgui_internal_renderer_selection_transfer_create(token, &transfer) ==
                  CJGUI_INTERNAL_RENDERER_OK && transfer != 0,
              "normal_build_creates_selection_transfer");
        CJGuiInternalComposableSceneNode *target = ctx.composableSceneOverlay.nodes[1];
        NSData *targetBody = [target.value dataUsingEncoding:NSUTF8StringEncoding];
        CjguiInternalSelectionTransferCandidate candidate = {0};
        candidate.transferId = transfer; candidate.sourceWindowInstanceToken = 9101;
        candidate.sourceOwnerVersion = 10; candidate.sourceContextEpoch = 4;
        candidate.sourceMirrorRevision = 2;
        candidate.targetNodeId = 402; candidate.targetProjectionVersion = 2;
        candidate.targetResourceId = 1;
        candidate.targetNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        candidate.targetSceneVersion = 2;
        candidate.targetAnchor16 = 4; candidate.targetFocus16 = 4;
        candidate.targetBodyUtf8 = targetBody.bytes;
        candidate.targetBodyUtf8Length = (uint32_t)targetBody.length;
        uint8_t actual[65536] = {0};
        CHECK(cjgui_internal_renderer_selection_transfer_capture_current(
                  token, &candidate, actual, sizeof(actual)) == CJGUI_INTERNAL_RENDERER_OK,
              "capture_current_A_and_B_from_accepted_scene");
        CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token, transfer) ==
                  CJGUI_INTERNAL_RENDERER_OK,
              "publish_real_pending_transfer");
        CjguiInternalSelectionTransferReceipt receipt = {0};
        CHECK(cjgui_internal_renderer_selection_transfer_install_b(token, transfer, &receipt) ==
                  CJGUI_INTERNAL_RENDERER_OK,
              "real_native_install_b_commits_collapsed_selection");

        NSArray<CJGuiInternalComposableSceneNode *> *nodes = ctx.view.composableNodes;
        target = nodes[1];
        CHECK(ctx.selectionTraceTransferId == 0,
              "owner_phase_trace_is_disabled_in_normal_build_fixture");
        fprintf(stderr, "receipt scene=%llu basis_receipt=%d basis_transfer=%llu expected=%llu proxy_range=%lu:%lu proxy_rects=%lu caret=%.1f,%.1f,%.1f,%.1f node_projection=%llu overlay_projection=%llu\n",
            (unsigned long long)ctx.composableSceneVersion, ctx.installedRangeBasis.hasReceipt,
            (unsigned long long)ctx.installedRangeBasis.selectionTransferId,
            (unsigned long long)transfer,
            (unsigned long)ctx.composableSceneOverlay.inputProxy.selectedRange.location,
            (unsigned long)ctx.composableSceneOverlay.inputProxy.selectedRange.length,
            (unsigned long)target.textSelectionRects.count,
            NSMinX(target.textCaretRect), NSMinY(target.textCaretRect),
            NSWidth(target.textCaretRect), NSHeight(target.textCaretRect),
            (unsigned long long)target.node.projectionVersion,
            (unsigned long long)ctx.composableSceneOverlay.activeProjectionVersion);
        CHECK(ctx.composableSceneVersion == 2 && ctx.installedRangeBasis.hasReceipt &&
              ctx.installedRangeBasis.selectionTransferId == transfer &&
              ctx.composableSceneOverlay.inputProxy.selectedRange.length == 0,
              "actual_receipt_proves_collapsed_proxy_same_scene");
        CHECK(target.textSelectionRects.count == 0 && !NSIsEmptyRect(target.textCaretRect),
              "collapsed_proxy_has_empty_native_selection_rects_and_visible_caret");
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, nodes[1]).count == 0 &&
              CjguiEffectiveDeclaredSelectionDecorations(ctx, nodes[0]).count == 1 &&
              ctx.selectionPaintTransferId == transfer,
              "other_fragment_declaration_retained_behind_actual_receipt_fence");
        CHECK(nodes[0].textDeclaredSelectionDecorations.count > 0 &&
              nodes[1].textDeclaredSelectionDecorations.count > 0,
              "accepted_immutable_declarations_remain_unchanged_after_paint_override");
        (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token, transfer);
        (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);

        // Exercise the same normal owner/native choice path in both directions.
        // TEXT's existing GPU-input refresh intentionally excludes this node
        // kind, so each accepted B needs geometry projected from its retained
        // accepted TextKit layout before the old declaration is suppressed.
        CHECK(InstallSelectionOnSameAcceptedScene(ctx, 0, 5),
              "same_scene_forward_selection_installs_through_native_route");
        target = ctx.composableSceneOverlay.nodes[1];
        NSRect forwardBounds = NSZeroRect;
        for (NSValue *rect in target.textSelectionRects)
            forwardBounds = NSIsEmptyRect(forwardBounds) ? rect.rectValue : NSUnionRect(forwardBounds, rect.rectValue);
        CHECK(ctx.composableSceneOverlay.inputProxy.selectedRange.length == 5 &&
              target.textSelectionRects.count > 0 &&
              NSWidth(forwardBounds) > NSWidth(oldTargetSelection) + 1.0 &&
              CjguiEffectiveDeclaredSelectionDecorations(ctx, target).count == 0,
              "forward_range_has_current_wider_geometry_after_old_declaration_retirement");
        CHECK(InstallSelectionOnSameAcceptedScene(ctx, 5, 0),
              "same_scene_reverse_selection_installs_through_native_route");
        target = ctx.composableSceneOverlay.nodes[1];
        NSRect reverseBounds = NSZeroRect;
        for (NSValue *rect in target.textSelectionRects)
            reverseBounds = NSIsEmptyRect(reverseBounds) ? rect.rectValue : NSUnionRect(reverseBounds, rect.rectValue);
        CHECK(ctx.composableSceneOverlay.inputProxy.selectedRange.length == 5 &&
              target.textSelectionRects.count > 0 &&
              NSEqualRects(reverseBounds, forwardBounds) &&
              CjguiEffectiveDeclaredSelectionDecorations(ctx, target).count == 0,
              "reverse_range_has_same_current_geometry_without_resurrecting_old_declaration");
        CHECK(InstallSelectionOnSameAcceptedScene(ctx, 4, 4),
              "same_scene_collapsed_selection_installs_after_reverse_range");
        target = ctx.composableSceneOverlay.nodes[1];
        CHECK(ctx.composableSceneOverlay.inputProxy.selectedRange.length == 0 &&
              target.textSelectionRects.count == 0 && !NSIsEmptyRect(target.textCaretRect),
              "collapsed_range_clears_selection_and_keeps_caret_after_nonempty_ranges");

        cjgui_internal_renderer_destroy(token);
    }
    id<MTLDevice> sparseDevice = MTLCreateSystemDefaultDevice();
    if (sparseDevice) VerifySparseCowTransfer(sparseDevice);
    fprintf(stderr, "selection transfer paint production failures=%d\n", failures);
    return failures ? 1 : 0;
}
