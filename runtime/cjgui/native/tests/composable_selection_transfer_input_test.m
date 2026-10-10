// Independent TextKit regression: a real native text callback must be held
// while the A/B transfer is Finalizing, then replayed only after A is restored.
#define main prior_source_install_suite_main
#import "composable_source_selection_install_test.m"
#undef main

static SourceInstallOverlay *InstalledRangeCreateActivatedFixtureAt(id<MTLDevice> device,
    NSString *text, uint64_t binding, uint64_t nonce, uint64_t windowToken, uint64_t sourceStart,
    NSString *targetText) {
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
    NSMutableArray<CJGuiInternalComposableSceneNode *> *staged=[NSMutableArray arrayWithObject:node];
    if (targetText) {
        CJGuiInternalComposableSceneNode *target=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode targetRaw={0};
        targetRaw.nodeId=402; targetRaw.resourceId=1; targetRaw.projectionVersion=1;
        targetRaw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        targetRaw.x=0; targetRaw.y=150; targetRaw.width=680; targetRaw.height=120;
        targetRaw.clipWidth=680; targetRaw.clipHeight=120; targetRaw.fontSize=13;
        targetRaw.textAlpha=1; targetRaw.isInteractive=1;
        target.node=targetRaw; target.index=1; target.value=targetText;
        target.styleRunsSignature=@""; target.textTextureCacheKey=@"";
        [staged addObject:target];
    }
    ctx.stagedComposableNodes=staged;
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
    // The installed responder is the input host. TextKit remains its private
    // adapter; replacing the host with that adapter invalidates the receipt.
    overlay.testWindow.testResponder=overlay.inputHost;
    [ctx.pendingInteractions removeAllObjects];
    return overlay;
}

static BOOL SelectionTransferFillSourceReceipt(uint64_t token, uint64_t nonce,
    CjguiInternalSelectionTransferCandidate *candidate) {
    CjguiInternalInstalledRangeReceipt receipt = {0};
    if (cjgui_internal_renderer_installed_range_active_receipt(token, nonce, &receipt) !=
        CJGUI_INTERNAL_RENDERER_OK) return NO;
    candidate->sourceInstalledNonce = receipt.nonce;
    candidate->sourceRendererSessionGeneration = receipt.rendererSessionGeneration;
    candidate->sourceWindowInstanceToken = receipt.windowInstanceToken;
    candidate->sourceBindingEpoch = receipt.bindingEpoch;
    candidate->sourceContextEpoch = receipt.contextEpoch;
    candidate->sourceMirrorRevision = receipt.mirrorRevision;
    candidate->sourceOwnerVersion = receipt.ownerVersion;
    candidate->sourceAcceptedVersion = receipt.acceptedVersion;
    candidate->sourceAcceptedSequence = receipt.acceptedSequence;
    candidate->sourceStartByte = receipt.sourceStartByte;
    candidate->sourceEndByte = receipt.sourceEndByte;
    candidate->sourceProxyGeneration = receipt.proxyGeneration;
    candidate->sourceSelectionRevision = receipt.selectionRevision;
    candidate->sourceNodeId = receipt.nodeId;
    candidate->sourceResourceId = receipt.resourceId;
    candidate->sourceSceneVersion = receipt.installedSceneVersion;
    candidate->sourceSelectionStart16 = receipt.actualSelectionStart16;
    candidate->sourceSelectionEnd16 = receipt.actualSelectionEnd16;
    return YES;
}

static void SelectionTransferInputGateFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = InstalledRangeCreateActivatedFixtureAt(
        device, @"AB", 71, 1201, 9001, 0, nil);
    CHECK(overlay != nil, "selection_transfer_input_fixture_has_actual_installed_source");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;
    NSRange sourceSelection = overlay.inputProxy.selectedRange;
    NSData *sourceBytes = [overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate = {0};
    CHECK(SelectionTransferFillSourceReceipt(token, 1201, &candidate),
        "selection_transfer_input_source_is_active_receipt");
    candidate.sourceProjectionVersion = overlay.activeProjectionVersion;
    candidate.sourceNodeKind = overlay.activeNodeKind;
    candidate.sourceBodyUtf8 = sourceBytes.bytes;
    candidate.sourceBodyUtf8Length = (uint32_t)sourceBytes.length;
    candidate.targetNodeId = candidate.sourceNodeId;
    candidate.targetProjectionVersion = candidate.sourceProjectionVersion;
    candidate.targetResourceId = candidate.sourceResourceId;
    candidate.targetNodeKind = candidate.sourceNodeKind;
    candidate.targetSceneVersion = candidate.sourceSceneVersion;
    candidate.targetAnchor16 = (uint32_t)sourceSelection.location;
    candidate.targetFocus16 = (uint32_t)NSMaxRange(sourceSelection);
    candidate.targetBodyUtf8 = sourceBytes.bytes;
    candidate.targetBodyUtf8Length = (uint32_t)sourceBytes.length;

    uint64_t transferId = 0;
    CjguiInternalRendererStatus created = cjgui_internal_renderer_selection_transfer_create(token, &transferId);
    candidate.transferId = transferId;
    CHECK(created == CJGUI_INTERNAL_RENDERER_OK && transferId != 0 &&
        cjgui_internal_renderer_selection_transfer_capture_a(token, &candidate) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_captures_exact_current_A_proxy_and_body");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token, transferId) ==
        CJGUI_INTERNAL_RENDERER_OK && cjgui_internal_renderer_selection_transfer_begin_finalizing(token, transferId) ==
        CJGUI_INTERNAL_RENDERER_OK, "selection_transfer_enters_finalizing_after_empty_source_fifo");
    CjguiInternalSelectionTransferReceipt bReceipt = {0};
    CHECK(cjgui_internal_renderer_selection_transfer_verify_b(token, transferId, &bReceipt) ==
        CJGUI_INTERNAL_RENDERER_OK && bReceipt.transferId == transferId &&
        bReceipt.nodeId == candidate.targetNodeId && bReceipt.selectionStart16 == candidate.targetAnchor16 &&
        bReceipt.selectionEnd16 == candidate.targetFocus16 && bReceipt.firstResponder,
        "selection_transfer_B_requires_actual_proxy_body_selection_and_responder_readback");

    NSString *oldBody = [overlay.inputProxy.string copy];
    NSRange oldSelection = overlay.inputProxy.selectedRange;
    [overlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound, 0)];
    uint32_t state = 0; uint8_t cancelled = 0; uint32_t refs = 0;
    (void)cjgui_internal_renderer_selection_transfer_state(token, transferId, &state, &cancelled, &refs);
    CHECK([overlay.inputProxy.string isEqualToString:oldBody] && state == CJGUI_SELECTION_TRANSFER_FINALIZING &&
        cancelled == 1 && ctx.selectionTransferCapsule.retainedInputs.count == 1,
        "selection_transfer_RED_textkit_insert_is_retained_without_mutating_finalizing_proxy");

    CHECK(cjgui_internal_renderer_selection_transfer_restore_a(token, transferId) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_finish_abort(token, transferId) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_replay_input(token, transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_restores_A_then_replays_retained_textkit_insert_once");
    NSString *expected = [oldBody stringByReplacingCharactersInRange:oldSelection withString:@"X"];
    BOOL queuedText = NO;
    for (CJGuiInternalQueuedInteraction *interaction in ctx.pendingInteractions) {
        if (interaction.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED ||
            interaction.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED) queuedText = YES;
    }
    CHECK([overlay.inputProxy.string isEqualToString:expected] && queuedText && !ctx.selectionTransferCapsule &&
        ctx.selectionTransferId == 0, "selection_transfer_replay_reaches_original_owner_path_once");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token, transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_owner_reference_released_after_native_replay");
    cjgui_internal_renderer_destroy(token);
}

// This helper deliberately uses the CJGUI_INTERNAL_TESTING split-state seam.
// It holds FINALIZING across calls even though production begin_finalizing is
// disabled and install_b now keeps the whole decision on one main-thread stack.
static uint64_t SelectionTransferPrepareFinalizing(SourceInstallOverlay *overlay,
    uint64_t nonce, uint64_t windowToken) {
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;
    CjguiInternalSelectionTransferCandidate candidate = {0};
    NSData *body = [overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    if (!SelectionTransferFillSourceReceipt(token, nonce, &candidate)) return 0;
    candidate.sourceProjectionVersion = overlay.activeProjectionVersion;
    candidate.sourceNodeKind = overlay.activeNodeKind;
    candidate.sourceBodyUtf8 = body.bytes;
    candidate.sourceBodyUtf8Length = (uint32_t)body.length;
    candidate.targetNodeId = candidate.sourceNodeId;
    candidate.targetProjectionVersion = candidate.sourceProjectionVersion;
    candidate.targetResourceId = candidate.sourceResourceId;
    candidate.targetNodeKind = candidate.sourceNodeKind;
    candidate.targetSceneVersion = candidate.sourceSceneVersion;
    candidate.targetAnchor16 = (uint32_t)overlay.inputProxy.selectedRange.location;
    candidate.targetFocus16 = (uint32_t)NSMaxRange(overlay.inputProxy.selectedRange);
    candidate.targetBodyUtf8 = body.bytes;
    candidate.targetBodyUtf8Length = (uint32_t)body.length;
    uint64_t transferId = 0;
    if (cjgui_internal_renderer_selection_transfer_create(token, &transferId) != CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    candidate.transferId = transferId;
    if (cjgui_internal_renderer_selection_transfer_capture_a(token, &candidate) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_selection_transfer_publish_pending(token, transferId) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_selection_transfer_begin_finalizing(token, transferId) != CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    return transferId;
}

// Test-only cross-turn RED: 66 real TextKit insertText callbacks exercise a
// forced FINALIZING state. This is not evidence that production reaches this
// state; it preserves the finite-capacity counterexample without relaxing it.
static void SelectionTransferRetainedInputCapacityOverflowFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = InstalledRangeCreateActivatedFixtureAt(
        device, @"AB", 121, 1221, 9021, 0, nil);
    CHECK(overlay != nil, "selection_transfer_capacity_fixture_has_actual_source");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;
    [overlay.inputProxy setSelectedRange:NSMakeRange(overlay.inputProxy.string.length, 0)];
    [ctx.pendingInteractions removeAllObjects];
    NSString *before = [overlay.inputProxy.string copy];
    uint64_t transferId = SelectionTransferPrepareFinalizing(overlay, 1221, 9021);
    CHECK(transferId != 0, "selection_transfer_capacity_enters_real_finalizing");
    if (!transferId) { cjgui_internal_renderer_destroy(token); return; }
    for (NSUInteger index = 0; index < 66; ++index)
        [overlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound, 0)];
    NSString *after = overlay.inputProxy.string;
    NSUInteger xCount = 0;
    for (NSUInteger index = 0; index < after.length; ++index)
        if ([after characterAtIndex:index] == 'X') ++xCount;
    uint32_t state = 0, refs = 0;
    uint8_t cancelled = 0;
    (void)cjgui_internal_renderer_selection_transfer_state(token, transferId, &state, &cancelled, &refs);
    fprintf(stderr, "selection_transfer capacity diagnostic x=%lu body=%lu capsule=%d id=%llu state=%u refs=%u queued=%lu\n",
        (unsigned long)xCount, (unsigned long)after.length, ctx.selectionTransferCapsule != nil,
        (unsigned long long)ctx.selectionTransferId, state, refs, (unsigned long)ctx.pendingInteractions.count);
    CHECK(xCount == 66 && [after hasPrefix:before] && !ctx.selectionTransferCapsule &&
        ctx.selectionTransferId == 0 && state == CJGUI_SELECTION_TRANSFER_ABORTED,
        "selection_transfer_capacity_overflow_restores_A_and_delivers_65th_and_66th_text_inputs_once");
    BOOL queuedText = NO;
    for (CJGuiInternalQueuedInteraction *interaction in ctx.pendingInteractions) {
        if (interaction.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED ||
            interaction.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED) queuedText = YES;
    }
    CHECK(queuedText && refs == 1,
        "selection_transfer_capacity_overflow_keeps_owner_until_normal_terminal_retirement");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token, transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_capacity_overflow_owner_reference_released");
    cjgui_internal_renderer_destroy(token);
}

// Test-only cross-turn RED for the byte limit. The oversize void callback must
// remain visible as a counterexample; production reachability is assessed
// separately from this forced FINALIZING fixture.
static void SelectionTransferRetainedInputByteOverflowFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = InstalledRangeCreateActivatedFixtureAt(
        device, @"AB", 122, 1222, 9022, 0, nil);
    CHECK(overlay != nil, "selection_transfer_byte_capacity_fixture_has_actual_source");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;
    [overlay.inputProxy setSelectedRange:NSMakeRange(overlay.inputProxy.string.length, 0)];
    [ctx.pendingInteractions removeAllObjects];
    uint64_t transferId = SelectionTransferPrepareFinalizing(overlay, 1222, 9022);
    CHECK(transferId != 0, "selection_transfer_byte_capacity_enters_real_finalizing");
    if (!transferId) { cjgui_internal_renderer_destroy(token); return; }
    NSMutableString *oversize = [NSMutableString stringWithCapacity:4 * 1024 * 1024 + 1];
    for (NSUInteger index = 0; index < 4 * 1024 * 1024 + 1; ++index) [oversize appendString:@"Y"];
    [overlay.inputProxy insertText:oversize replacementRange:NSMakeRange(NSNotFound, 0)];
    [overlay.inputProxy insertText:@"Z" replacementRange:NSMakeRange(NSNotFound, 0)];
    NSString *after = overlay.inputProxy.string;
    uint32_t state = 0, refs = 0;
    uint8_t cancelled = 0;
    (void)cjgui_internal_renderer_selection_transfer_state(token, transferId, &state, &cancelled, &refs);
    fprintf(stderr, "selection_transfer byte diagnostic length=%lu expected=%lu suffix=%d capsule=%d id=%llu state=%u refs=%u\n",
        (unsigned long)after.length, (unsigned long)(3 + oversize.length), [after hasSuffix:@"YYYYYYYZ"],
        ctx.selectionTransferCapsule != nil, (unsigned long long)ctx.selectionTransferId, state, refs);
    CHECK(after.length == 3 + oversize.length && [after hasSuffix:@"YYYYYYYZ"] &&
        !ctx.selectionTransferCapsule &&
        ctx.selectionTransferId == 0 && state == CJGUI_SELECTION_TRANSFER_ABORTED,
        "selection_transfer_byte_overflow_restores_A_and_delivers_full_payload_then_next_input");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token, transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_byte_overflow_owner_reference_released");
    cjgui_internal_renderer_destroy(token);
}

static void SelectionTransferCrossFragmentLocalReceiptFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = InstalledRangeCreateActivatedFixtureAt(
        device, @"ABCDE", 72, 1202, 9002, 0, @"FGHIJ");
    CHECK(overlay != nil, "selection_transfer_cross_fragment_two_text_nodes_installed");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;
    overlay.inputProxy.selectedRange = NSMakeRange(3, 2); // A slice of owner span [3, 7).
    [ctx.pendingInteractions removeAllObjects];
    NSData *sourceBytes = [overlay.inputProxy.string dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate = {0};
    CHECK(SelectionTransferFillSourceReceipt(token, 1202, &candidate),
        "selection_transfer_cross_fragment_source_is_active_receipt");
    candidate.sourceProjectionVersion = 1;
    candidate.sourceNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    candidate.sourceBodyUtf8 = sourceBytes.bytes; candidate.sourceBodyUtf8Length = (uint32_t)sourceBytes.length;
    candidate.targetNodeId = 402; candidate.targetProjectionVersion = 1;
    candidate.targetResourceId = 1; candidate.targetNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion = ctx.composableSceneVersion;
    // Owner-global selection [3,7) intersects target B's source span [5,10)
    // as local TextKit UTF-16 [0,2). The native receipt proves only [0,2).
    candidate.targetAnchor16 = 0; candidate.targetFocus16 = 2;
    NSData *targetBytes = [@"FGHIJ" dataUsingEncoding:NSUTF8StringEncoding];
    candidate.targetBodyUtf8 = targetBytes.bytes; candidate.targetBodyUtf8Length = (uint32_t)targetBytes.length;

    uint64_t transferId = 0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token, &transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_cross_fragment_create");
    candidate.transferId = transferId;
    CHECK(cjgui_internal_renderer_selection_transfer_capture_a(token, &candidate) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_cross_fragment_freezes_actual_A_slice");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token, transferId) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_begin_finalizing(token, transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_cross_fragment_finalizing");
    CHECK([overlay focusCommittedNodeId:402], "selection_transfer_cross_fragment_installs_B_text_proxy");
    [overlay.inputProxy setSelectedRange:NSMakeRange(0, 2)];
    CjguiInternalSelectionTransferReceipt receipt = {0};
    CjguiInternalRendererStatus verified = cjgui_internal_renderer_selection_transfer_verify_b(
        token, transferId, &receipt);
    CHECK(verified == CJGUI_INTERNAL_RENDERER_OK && receipt.nodeId == 402 &&
        receipt.selectionStart16 == 0 && receipt.selectionEnd16 == 2 &&
        [overlay.inputProxy.string isEqualToString:@"FGHIJ"],
        "selection_transfer_cross_fragment_B_receipt_is_only_local_intersection");
    CHECK(cjgui_internal_renderer_selection_transfer_commit(token, transferId) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_discard_capsule(token, transferId) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_release(token, transferId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_cross_fragment_commit_and_release");

    // Passing owner-global [3,7) as if it were B-local is invalid for B's
    // five-code-unit body. This is deliberately a negative native-local proof.
    uint64_t invalidId = 0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token, &invalidId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_cross_fragment_invalid_candidate_create");
    candidate.transferId = invalidId;
    candidate.targetAnchor16 = 3; candidate.targetFocus16 = 7;
    CHECK(cjgui_internal_renderer_selection_transfer_capture_a(token, &candidate) ==
        CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID,
        "selection_transfer_cross_fragment_global_range_rejected_as_B_local");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token, invalidId) == CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_selection_transfer_release(token, invalidId) == CJGUI_INTERNAL_RENDERER_OK,
        "selection_transfer_cross_fragment_invalid_candidate_released");
    cjgui_internal_renderer_destroy(token);
}

static void SelectionTransferNativeVerticalInputProvenanceFixture(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = InstalledRangeCreateActivatedFixtureAt(
        device, @"first row\nsecond row", 73, 1203, 9003, 0, nil);
    CHECK(overlay != nil, "vertical_input_fixture_has_actual_activated_source");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;
    [ctx.pendingInteractions removeAllObjects];
    void (^sendArrow)(uint16_t, NSEventModifierFlags) = ^(uint16_t keyCode, NSEventModifierFlags flags) {
        unichar arrow = keyCode == 126 ? NSUpArrowFunctionKey : NSDownArrowFunctionKey;
        NSString *characters = [NSString stringWithCharacters:&arrow length:1];
        NSEvent *key = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
            modifierFlags:flags timestamp:0.0 windowNumber:ctx.window.windowNumber context:nil
            characters:characters charactersIgnoringModifiers:characters isARepeat:NO keyCode:keyCode];
        [overlay.inputProxy keyDown:key];
    };
    uint64_t focusedNode = 0;
    sendArrow(126, 0);
    CHECK(overlay.activeNodeId == 401,
        "vertical_input_up_enters_real_proxy_keydown_path");
    sendArrow(125, NSEventModifierFlagShift);
    CHECK(overlay.activeNodeId == 401,
        "vertical_input_down_enters_real_proxy_keydown_path_before_pump");
    CjguiInternalRendererEvent event = {0};
    CHECK(cjgui_internal_renderer_pump_event(token, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        "vertical_input_first_actual_fifo_item_is_navigation");
    uint64_t generation = 0, sequence = 0, previous = 0;
    uint32_t kind = 0;
    CHECK(cjgui_internal_renderer_owner_consumed_input_provenance(token,
        &generation, &sequence, &previous, &kind) == 1 && generation == ctx.sessionGeneration &&
        sequence == 1 && previous == 0 && kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        "vertical_input_first_pump_carries_exact_generation_and_zero_predecessor");
    memset(&event, 0, sizeof(event));
    CHECK(cjgui_internal_renderer_pump_event(token, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        "vertical_input_second_actual_fifo_item_is_navigation");
    generation = sequence = previous = 0; kind = 0;
    CHECK(cjgui_internal_renderer_owner_consumed_input_provenance(token,
        &generation, &sequence, &previous, &kind) == 1 && generation == ctx.sessionGeneration &&
        sequence == 2 && previous == 1 && kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        "vertical_input_second_pump_preserves_after_predecessor_order");

    // Accessibility/programmatic enqueues share the Event POD but cannot claim
    // the physical-key provenance chain.
    CHECK(CjguiEnqueueComposableInteraction(ctx, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        0, @"down", NSMakeRange(0, 0)), "vertical_input_programmatic_navigation_queues_normally");
    memset(&event, 0, sizeof(event));
    CHECK(cjgui_internal_renderer_pump_event(token, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
        "vertical_input_programmatic_navigation_keeps_legacy_event_delivery");
    generation = sequence = previous = 0; kind = 0;
    CHECK(cjgui_internal_renderer_owner_consumed_input_provenance(token,
        &generation, &sequence, &previous, &kind) == 0 && generation == 0 && sequence == 0 &&
        previous == 0 && kind == 0,
        "vertical_input_programmatic_event_has_no_physical_provenance");

    ctx.lastVerticalInputSequence = UINT64_MAX;
    sendArrow(126, 0);
    CHECK(overlay.activeNodeId == 401, "vertical_input_overflow_key_reaches_native_producer");
    memset(&event, 0, sizeof(event));
    CHECK(cjgui_internal_renderer_pump_event(token, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_INPUT_QUEUE_FULL,
        "vertical_input_sequence_overflow_fails_closed_without_wrapping");
    generation = sequence = previous = 0; kind = 0;
    CHECK(cjgui_internal_renderer_owner_consumed_input_provenance(token,
        &generation, &sequence, &previous, &kind) == 0 && generation == 0 && sequence == 0,
        "vertical_input_overflow_cannot_publish_an_unsequenced_key");
    cjgui_internal_renderer_destroy(token);
}


#ifndef CJGUI_SELECTION_TRANSFER_NO_MAIN
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "Metal unavailable\n"); return 2; }
        SelectionTransferInputGateFixture(device);
        SelectionTransferRetainedInputCapacityOverflowFixture(device);
        SelectionTransferRetainedInputByteOverflowFixture(device);
        SelectionTransferCrossFragmentLocalReceiptFixture(device);
        SelectionTransferNativeVerticalInputProvenanceFixture(device);
        fprintf(stderr, "selection_transfer_input_fixture failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}

#endif
