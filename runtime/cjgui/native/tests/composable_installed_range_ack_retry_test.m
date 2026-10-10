// Production ACK counterexample: an owner accepts one captured body edit,
// native ACK fails once without consuming its claim, and retry confirms only
// that exact ACK. The managed memo idempotence companion is
// crossFragmentAcceptedInputConfirmationIsIdempotentForSameIdentity in
// text_session_test.cj.
#define main prior_source_install_suite_main
#import "composable_source_selection_install_test.m"
#undef main

typedef struct {
    NSData *body;
    int64_t version;
    uint32_t writes;
} AckRetryOwner;

static SourceInstallOverlay *AckRetryCreateActivatedFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay = [[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 680, 500) session:ctx];
    overlay.testWindow = [[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0, 0, 680, 500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window = (NSWindow *)overlay.testWindow;
    ctx.composableSceneOverlay = overlay;
    overlay.inputProxy.delegate = nil;
    SourceInstallProxy *proxy = [[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    proxy.composableOverlay = overlay;
    proxy.delegate = overlay;
    proxy.layoutManager.allowsNonContiguousLayout = YES;
    proxy.layoutManager.backgroundLayoutEnabled = NO;
    overlay.inputProxy = proxy;
    overlay.inputScrollProxy.documentView = proxy;
    overlay.testWindow.contentView = overlay;

    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 401;
    raw.resourceId = 1;
    raw.projectionVersion = 1;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width = 680;
    raw.height = 1200;
    raw.clipWidth = 680;
    raw.clipHeight = 500;
    raw.fontSize = 13;
    raw.textAlpha = 1;
    raw.isInteractive = 1;
    node.node = raw;
    node.index = 0;
    node.value = @"AB";
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    ctx.stagedComposableNodes = [NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token) == CJGUI_INTERNAL_RENDERER_OK,
        "ack_retry_fixture_scene_accepted");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled = YES;
    ctx.ownedTextSessionNodeId = 401;
    ctx.ownedTextSessionResourceId = 1;
    ctx.ownedTextSessionNodeKind = raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch = 91;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    NSData *bytes = [node.value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate basis = {
        .nonce = 1501,
        .rendererSessionGeneration = ctx.sessionGeneration,
        .windowInstanceToken = 9501,
        .bindingEpoch = 91,
        .contextEpoch = 4,
        .mirrorRevision = 2,
        .ownerVersion = 10,
        .installedSceneVersion = ctx.composableSceneVersion,
        .nodeId = 401,
        .resourceId = 1,
        .sourceStartByte = 0,
        .sourceEndByte = bytes.length,
        .sourceTextUtf8 = bytes.bytes,
        .sourceTextUtf8Length = (uint32_t)bytes.length,
    };
    CHECK(cjgui_internal_renderer_installed_range_arm(token, &basis) == CJGUI_INTERNAL_RENDERER_OK,
        "ack_retry_fixture_range_basis_armed");
    CHECK([overlay focusCommittedNodeId:401], "ack_retry_fixture_proxy_matches_scene");
    CjguiInternalInstalledRangeReceipt receipt = {0};
    CHECK(cjgui_internal_renderer_installed_range_receipt(token, basis.nonce, &receipt) ==
            CJGUI_INTERNAL_RENDERER_OK &&
        cjgui_internal_renderer_installed_range_activate(token, basis.nonce, receipt.proxyGeneration,
            receipt.selectionRevision) == CJGUI_INTERNAL_RENDERER_OK,
        "ack_retry_fixture_range_receipt_activated");
    overlay.testWindow.testResponder = overlay.inputHost;
    return overlay;
}

static BOOL AckRetryOwnerSubmitOnce(AckRetryOwner *owner,
    const CjguiInternalInstalledRangeIntent *intent, int64_t *versionAfter) {
    if (!owner || !intent || !versionAfter || owner->writes != 0 ||
        owner->version != intent->ownerVersion ||
        owner->body.length != intent->preBodyUtf8Length ||
        (owner->body.length && memcmp(owner->body.bytes, intent->preBodyUtf8,
            owner->body.length) != 0) || !intent->postBodyUtf8 || !intent->postBodyUtf8Length)
        return NO;
    owner->body = [NSData dataWithBytes:intent->postBodyUtf8 length:intent->postBodyUtf8Length];
    owner->version += 1;
    owner->writes += 1;
    *versionAfter = owner->version;
    return YES;
}

static void InstalledRangeAckRetryAfterOwnerAccept(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = AckRetryCreateActivatedFixture(device);
    CHECK(overlay != nil, "ack_retry_actual_installed_proxy_fixture");
    if (!overlay) return;
    CJGuiInternalSession *ctx = overlay.session;
    uint64_t token = ctx.rendererSessionToken;

    // This is a real NSTextView edit which creates the native kind-51 claim.
    [overlay.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound, 0)];
    CjguiInternalRendererEvent event = {0};
    CjguiInternalRendererStatus pumpStatus = cjgui_internal_renderer_pump_event(token, 0, &event);
    CHECK(pumpStatus == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED,
        "ack_retry_real_textkit_event_reaches_native_fifo");
    CjguiInternalInstalledRangeIntent claim = {0};
    CjguiInternalRendererStatus claimStatus = cjgui_internal_renderer_claim_last_pumped_range(
        token, 401, 1, 91, 1, &claim);
    CHECK(claimStatus == CJGUI_INTERNAL_RENDERER_OK && claim.seq == 1 &&
        claim.preBodyUtf8Length == 2 && claim.postBodyUtf8Length == 3,
        "ack_retry_claims_exact_real_native_intent_once");
    if (claimStatus != CJGUI_INTERNAL_RENDERER_OK) {
        cjgui_internal_renderer_destroy(token);
        return;
    }

    AckRetryOwner owner = {
        .body = [NSData dataWithBytes:"AB" length:2],
        .version = claim.ownerVersion,
        .writes = 0,
    };
    int64_t versionAfter = -1;
    CHECK(AckRetryOwnerSubmitOnce(&owner, &claim, &versionAfter) && versionAfter > claim.ownerVersion &&
        owner.writes == 1 && owner.body.length == claim.postBodyUtf8Length &&
        memcmp(owner.body.bytes, claim.postBodyUtf8, owner.body.length) == 0,
        "ack_retry_owner_accepts_and_writes_claim_body_once");

    char seqText[32] = {0};
    char sessionText[32] = {0};
    snprintf(seqText, sizeof(seqText), "%llu", (unsigned long long)claim.seq);
    snprintf(sessionText, sizeof(sessionText), "%llu", (unsigned long long)token);
    setenv("CJGUI_TEST_INSTALLED_RANGE_ACK_FAIL_SEQ", seqText, 1);
    setenv("CJGUI_TEST_INSTALLED_RANGE_ACK_FAIL_SESSION", sessionText, 1);
    CjguiInternalRendererStatus firstAck = cjgui_internal_renderer_ack_installed_range(
        token, &claim, 1, versionAfter);
    CHECK(firstAck == CJGUI_INTERNAL_RENDERER_READBACK_FAILED && owner.writes == 1 &&
        owner.body.length == claim.postBodyUtf8Length &&
        ctx.claimedInstalledRangeIntent && !ctx.claimedInstalledRangeIntent.settled &&
        ctx.installedRangeObservedAckSequence == claim.previousSeq,
        "ack_retry_injected_failure_keeps_claim_and_accepted_owner_decision");

    // Preserve this assertion as the production RED counterexample: before
    // destroy refuses an unACKed claim, this returns OK and retires the very
    // session that still owns the accepted decision's native confirmation.
    CjguiInternalRendererStatus destroyWithHeldClaim = cjgui_internal_renderer_destroy(token);
    CHECK(destroyWithHeldClaim == CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED,
        "ack_retry_destroy_refuses_unsettled_claim");
    if (destroyWithHeldClaim != CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED) {
        fprintf(stderr,
            "ACK_RETRY_DESTROY_RED status=%d expected=%d writes=%u seq=%llu session=%llu\n",
            destroyWithHeldClaim, CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED,
            owner.writes, (unsigned long long)claim.seq, (unsigned long long)token);
        unsetenv("CJGUI_TEST_INSTALLED_RANGE_ACK_FAIL_SEQ");
        unsetenv("CJGUI_TEST_INSTALLED_RANGE_ACK_FAIL_SESSION");
        return;
    }

    // Retry passes the same captured identity to the real native ACK entrypoint.
    // No owner submission is reachable from this call.
    CjguiInternalRendererStatus retryAck = cjgui_internal_renderer_ack_installed_range(
        token, &claim, 1, versionAfter);
    CHECK(retryAck == CJGUI_INTERNAL_RENDERER_OK && owner.writes == 1 &&
        ctx.claimedInstalledRangeIntent == nil &&
        ctx.installedRangeObservedAckSequence == claim.seq &&
        [ctx.installedRangeBasis.sourceUtf8 isEqualToData:owner.body],
        "ack_retry_same_native_claim_confirms_without_resubmitting_owner_body");

    CjguiInternalRendererStatus duplicateNativeAck = cjgui_internal_renderer_ack_installed_range(
        token, &claim, 1, versionAfter);
    CHECK(duplicateNativeAck == CJGUI_INTERNAL_RENDERER_SCENE_STALE && owner.writes == 1,
        "ack_retry_settled_native_claim_cannot_mutate_twice");
    unsetenv("CJGUI_TEST_INSTALLED_RANGE_ACK_FAIL_SEQ");
    unsetenv("CJGUI_TEST_INSTALLED_RANGE_ACK_FAIL_SESSION");
    fprintf(stderr, "ACK_RETRY_PROBE writes=%u first=%d retry=%d duplicate=%d seq=%llu session=%llu\n",
        owner.writes, firstAck, retryAck, duplicateNativeAck,
        (unsigned long long)claim.seq, (unsigned long long)token);
    cjgui_internal_renderer_destroy(token);
}

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "Metal unavailable\n"); return 2; }
        InstalledRangeAckRetryAfterOwnerAccept(device);
        fprintf(stderr, "installed_range_ack_retry failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}
