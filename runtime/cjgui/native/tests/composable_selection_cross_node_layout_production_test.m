// Normal (non-testing) native path: a source click on one TEXT node followed
// by a whole-fragment selection on a different TEXT node. The selected node is
// deliberately the last accepted fragment, matching the production route.
#import "../cjgui_internal_renderer.m"

static int failures = 0;
#define CHECK(condition, name) do { BOOL ok = (condition); \
    fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name); if (!ok) failures++; } while (0)

static CJGuiInternalSession *CrossNodeFixture(id<MTLDevice> device, double targetClipHeight) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.app = [NSApplication sharedApplication];
    [ctx.app finishLaunching];
    [ctx.app activateIgnoringOtherApps:YES];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 720)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 680, 720)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window.releasedWhenClosed = NO;
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 680, 720) session:ctx];
    ctx.composableSceneOverlay = overlay;
    ctx.window.contentView = overlay;
    NSArray<NSString *> *bodies = @[
        @"SOURCE-A: a short body used for the initial source click.",
        @"FRAGMENT-1: a different payload from the clicked node.",
        @"FRAGMENT-2: another independently laid out text body.",
        @"FRAGMENT-3: unique text ensures layout storage cannot alias by content.",
        @"TARGET-Z: whole select this last fragment, not the active source node."
    ];
    for (NSUInteger index = 0; index < bodies.count; index++) {
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 1000 + index; raw.resourceId = 1; raw.projectionVersion = 1;
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x = 0; raw.y = index * 130; raw.width = 680; raw.height = 120;
        // The last accepted TEXT fragment is beyond the scene clip while
        // retaining a nonempty semantic body, matching global Select All on
        // a source whose tail fragment is currently offscreen.
        raw.clipWidth = 680; raw.clipHeight = index == 4 ? targetClipHeight : 720; raw.fontSize = 13;
        raw.textAlpha = 1; raw.isInteractive = 1;
        node.node = raw; node.index = (uint32_t)index;
        node.value = bodies[index];
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
    ctx.ownedTextSessionNodeId = 1000;
    ctx.ownedTextSessionResourceId = 1;
    ctx.ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    ctx.ownedTextSessionBindingEpoch = 81;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    [ctx.window makeKeyAndOrderFront:nil];
    if (![overlay focusCommittedNodeId:1000]) return nil;
    [ctx.pendingInteractions removeAllObjects];
    return ctx;
}

static void VerifyVisibleEmptyLayoutNegative(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = CrossNodeFixture(device, 720);
    if (!ctx) { CHECK(NO, "visible_mismatch_fixture"); return; }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *target = overlay.nodes[4];
    target.preparedTextLayout = CjguiPrepareTextNodeLayout(target, @"", 1.0, nil, ctx);
    CHECK(target.node.y < target.node.clipHeight && target.value.length > 0 &&
          target.preparedTextLayout && target.preparedTextLayout.storage.length == 0,
          "visible_target_fixture_has_deliberately_empty_layout");

    uint64_t token = ctx.rendererSessionToken, transfer = 0;
    CjguiInternalRendererStatus create = cjgui_internal_renderer_selection_transfer_create(token, &transfer);
    NSData *body = [target.value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate basis = ctx.installedRangeBasis.candidate;
    CjguiInternalSelectionTransferCandidate candidate = {0};
    candidate.transferId = transfer;
    candidate.sourceWindowInstanceToken = basis.windowInstanceToken ? basis.windowInstanceToken : 9101;
    candidate.sourceOwnerVersion = basis.ownerVersion;
    candidate.sourceContextEpoch = basis.contextEpoch ? basis.contextEpoch : 4;
    candidate.sourceMirrorRevision = basis.mirrorRevision ? basis.mirrorRevision : 2;
    candidate.targetNodeId = target.node.nodeId;
    candidate.targetProjectionVersion = target.node.projectionVersion;
    candidate.targetResourceId = target.node.resourceId;
    candidate.targetNodeKind = target.node.nodeKind;
    candidate.targetSceneVersion = ctx.composableSceneVersion;
    candidate.targetFocus16 = (uint32_t)target.value.length;
    candidate.targetBodyUtf8 = body.bytes;
    candidate.targetBodyUtf8Length = (uint32_t)body.length;
    uint8_t actual[65536] = {0};
    CjguiInternalRendererStatus captured = create == CJGUI_INTERNAL_RENDERER_OK && transfer
        ? cjgui_internal_renderer_selection_transfer_capture_current(token, &candidate, actual, sizeof(actual))
        : create;
    CjguiInternalRendererStatus published = captured == CJGUI_INTERNAL_RENDERER_OK
        ? cjgui_internal_renderer_selection_transfer_publish_pending(token, transfer) : captured;
    CjguiInternalSelectionTransferReceipt receipt = {0};
    CjguiInternalRendererStatus installed = published == CJGUI_INTERNAL_RENDERER_OK
        ? cjgui_internal_renderer_selection_transfer_install_b(token, transfer, &receipt) : published;
    CHECK(installed == CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED && overlay.activeNodeId == 1000,
          "visible_empty_layout_rejects_without_installing_B");
    if (installed != CJGUI_INTERNAL_RENDERER_OK)
        (void)cjgui_internal_renderer_selection_transfer_restore_a(token, transfer);
    if (transfer) {
        (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token, transfer);
        (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
    }
    cjgui_internal_renderer_destroy(token);
}

int main(void) {
    @autoreleasepool {
        unsetenv("CJGUI_OWNER_PHASE_TRACE");
        unsetenv("CJGUI_OWNER_TURN_TRACE");
        unsetenv("CJGUI_TEXT_PREPARE_TRACE");
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "SKIP no Metal device\n"); return 77; }
        CJGuiInternalSession *ctx = CrossNodeFixture(device, 500);
        if (!ctx) { fprintf(stderr, "FAIL cross-node fixture\n"); return 1; }

        CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
        CJGuiInternalComposableSceneNode *source = overlay.nodes[0];
        CJGuiInternalComposableSceneNode *target = overlay.nodes[4];
        CjguiPreparedTextNodeLayout *sourceLayout = source.preparedTextLayout;
        CjguiPreparedTextNodeLayout *targetLayout = target.preparedTextLayout;
        fprintf(stderr, "CROSS_NODE_PREPARE active=%llu target=%llu source_body=%lu source_layout=%p source_layout_body=%lu target_body=%lu target_layout=%p target_layout_body=%lu alias=%u\n",
            (unsigned long long)overlay.activeNodeId,
            (unsigned long long)target.node.nodeId,
            (unsigned long)source.value.length, sourceLayout,
            (unsigned long)(sourceLayout ? sourceLayout.storage.string.length : 0),
            (unsigned long)target.value.length, targetLayout,
            (unsigned long)(targetLayout ? targetLayout.storage.string.length : 0),
            sourceLayout == targetLayout);
        CHECK(overlay.activeNodeId == 1000 && target.node.nodeId == 1004,
              "source_click_keeps_A_active_and_whole_select_targets_last_fragment");
        CHECK(sourceLayout && targetLayout && sourceLayout != targetLayout &&
              [sourceLayout.storage.string isEqualToString:source.value] &&
              targetLayout.storage.string.length == 0 &&
              ![source.value isEqualToString:target.value],
              "offscreen_nonempty_target_has_expected_empty_paint_layout");
        CHECK(target.node.y >= target.node.clipHeight && targetLayout.textRect.size.width > 0 &&
              targetLayout.textRect.size.height > 0 && target.value.length > 0,
              "offscreen_target_has_valid_layout_box_but_empty_visual_coverage");

        uint64_t token = ctx.rendererSessionToken, transfer = 0;
        CjguiInternalRendererStatus create = cjgui_internal_renderer_selection_transfer_create(token, &transfer);
        NSData *body = [target.value dataUsingEncoding:NSUTF8StringEncoding];
        CjguiInternalInstalledRangeCandidate basis = ctx.installedRangeBasis.candidate;
        CjguiInternalSelectionTransferCandidate candidate = {0};
        candidate.transferId = transfer;
        candidate.sourceWindowInstanceToken = basis.windowInstanceToken ? basis.windowInstanceToken : 9101;
        candidate.sourceOwnerVersion = basis.ownerVersion;
        candidate.sourceContextEpoch = basis.contextEpoch ? basis.contextEpoch : 4;
        candidate.sourceMirrorRevision = basis.mirrorRevision ? basis.mirrorRevision : 2;
        candidate.targetNodeId = target.node.nodeId;
        candidate.targetProjectionVersion = target.node.projectionVersion;
        candidate.targetResourceId = target.node.resourceId;
        candidate.targetNodeKind = target.node.nodeKind;
        candidate.targetSceneVersion = ctx.composableSceneVersion;
        candidate.targetAnchor16 = 0;
        candidate.targetFocus16 = (uint32_t)target.value.length;
        candidate.targetBodyUtf8 = body.bytes;
        candidate.targetBodyUtf8Length = (uint32_t)body.length;
        uint8_t actual[65536] = {0};
        CjguiInternalRendererStatus captured = create == CJGUI_INTERNAL_RENDERER_OK && transfer
            ? cjgui_internal_renderer_selection_transfer_capture_current(token, &candidate, actual, sizeof(actual))
            : create;
        CjguiInternalRendererStatus published = captured == CJGUI_INTERNAL_RENDERER_OK
            ? cjgui_internal_renderer_selection_transfer_publish_pending(token, transfer) : captured;
        fprintf(stderr, "CROSS_NODE_PRE_INSTALL key=%u proxy_first=%u host_window=%u responder=%@ host=%@\n",
            ctx.window.isKeyWindow, CjguiInputProxyIsFirstResponder(overlay),
            overlay.inputHost.window == ctx.window, NSStringFromClass(ctx.window.firstResponder.class),
            NSStringFromClass(overlay.inputHost.class));
        CjguiInternalSelectionTransferReceipt receipt = {0};
        CjguiInternalRendererStatus installed = published == CJGUI_INTERNAL_RENDERER_OK
            ? cjgui_internal_renderer_selection_transfer_install_b(token, transfer, &receipt) : published;
        fprintf(stderr, "CROSS_NODE_INSTALL create=%u capture=%u publish=%u install=%u target=%llu active_after=%llu target_layout_body=%lu proxy_body=%lu\n",
            create, captured, published, installed,
            (unsigned long long)candidate.targetNodeId,
            (unsigned long long)overlay.activeNodeId,
            (unsigned long)(target.preparedTextLayout ? target.preparedTextLayout.storage.string.length : 0),
            (unsigned long)overlay.inputProxy.string.length);
        CHECK(installed == CJGUI_INTERNAL_RENDERER_OK,
              "normal_native_b_install_accepts_whole_select_on_other_text_fragment");
        CHECK(installed != CJGUI_INTERNAL_RENDERER_OK ||
              (overlay.activeNodeId == 1004 && overlay.inputProxy.selectedRange.location == 0 &&
               overlay.inputProxy.selectedRange.length == target.value.length),
              "accepted_native_proxy_targets_last_fragment_whole_range");
        NSArray<NSValue *> *nilLayoutRects = nil;
        NSRect nilLayoutCaret = NSMakeRect(9, 9, 9, 9);
        BOOL nilLayoutGeometry = installed == CJGUI_INTERNAL_RENDERER_OK &&
            [overlay prepareSourceSelectionGeometryForNode:target layout:nil proxy:overlay.inputProxy
                selection:overlay.inputProxy.selectedRange selectionRects:&nilLayoutRects caret:&nilLayoutCaret];
        CHECK(nilLayoutGeometry && nilLayoutRects.count == 0 && NSEqualRects(nilLayoutCaret, NSZeroRect),
              "fully_clipped_exact_target_allows_nil_layout_with_zero_geometry");
        if (installed == CJGUI_INTERNAL_RENDERER_OK) {
            (void)cjgui_internal_renderer_selection_transfer_discard_capsule(token, transfer);
        }

        // Move the accepted scene so the same node returns to the viewport.
        // Its newly prepared layout must not revive transfer-only geometry
        // from the previous accepted scene/receipt.
        CjguiInternalRendererStatus viewportConfigured =
            cjgui_internal_renderer_configure_composable_scene(token, 2, 5);
        CjguiInternalRendererStatus viewportGeometry = viewportConfigured;
        for (uint32_t index = 0; viewportConfigured == CJGUI_INTERNAL_RENDERER_OK && index < 5; index++) {
            CjguiInternalRendererComposableGeometry geometry = ctx.view.composableNodes[index].geometry;
            geometry.nodeId = ctx.view.composableNodes[index].node.nodeId;
            geometry.translateY = index == 4 ? -400.0 : 0.0;
            CjguiInternalRendererStatus one = cjgui_internal_renderer_set_composable_scene_geometry(
                token, 2, index, &geometry);
            if (one != CJGUI_INTERNAL_RENDERER_OK) viewportGeometry = one;
        }
        CjguiInternalRendererStatus viewportCommit = viewportGeometry == CJGUI_INTERNAL_RENDERER_OK
            ? CjguiCommitComposableSceneOnMain(token) : viewportGeometry;
        if (viewportCommit == CJGUI_INTERNAL_RENDERER_OK)
            [overlay setNodesFromProjection:ctx.view.composableNodes];
        CJGuiInternalComposableSceneNode *returnedTarget = overlay.nodes.count > 4 ? overlay.nodes[4] : nil;
        NSArray<NSValue *> *returnedEffectiveRects = returnedTarget
            ? CjguiEffectiveTransferTextSelectionRects(ctx, returnedTarget) : @[];
        CHECK(viewportCommit == CJGUI_INTERNAL_RENDERER_OK && returnedTarget &&
              returnedTarget.node.y + returnedTarget.geometry.translateY < returnedTarget.node.clipHeight &&
              returnedTarget.preparedTextLayout.storage.string.length == returnedTarget.value.length &&
              returnedEffectiveRects.count == 0 && returnedTarget.textSelectionTransferId == 0,
              "returned_viewport_regenerates_layout_without_reviving_old_transfer_decorations");
        if (transfer) (void)cjgui_internal_renderer_selection_transfer_release(token, transfer);
        cjgui_internal_renderer_destroy(token);
        VerifyVisibleEmptyLayoutNegative(device);
        fprintf(stderr, "cross-node layout production failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}
