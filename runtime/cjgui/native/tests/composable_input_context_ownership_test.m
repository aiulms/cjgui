// Exercise the real production selection-transfer graph and stable responder.
// The parked NSTextViews are backing adapters, never independent IME clients.
#define main CjguiSelectionPaintFixtureMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

// Runtime-only constructor hooks keep the production renderer free of test
// counters. Count only while B preparation is being advanced.
static BOOL gCountSelectionBConstructions;
static NSUInteger gDefaultProxyInitCount;
static NSUInteger gSourceProxyInitCount;
static NSUInteger gInputHostInitCount;
static NSUInteger gOverlayDraggedRegistrationCount;
static NSTextContainer *gLastSourceProxyContainer;
static IMP gOriginalProxyFrameInit;
static IMP gOriginalProxySourceInit;
static IMP gOriginalHostFrameInit;
static IMP gOriginalDraggedRegistration;

static id CountProxyFrameInit(id self, SEL command, NSRect frame) {
    if (gCountSelectionBConstructions) gDefaultProxyInitCount += 1;
    return ((id (*)(id, SEL, NSRect))gOriginalProxyFrameInit)(self, command, frame);
}

static id CountProxySourceInit(id self, SEL command, NSRect frame, NSTextContainer *container) {
    if (gCountSelectionBConstructions) {
        gSourceProxyInitCount += 1;
        gLastSourceProxyContainer = container;
    }
    return ((id (*)(id, SEL, NSRect, NSTextContainer *))gOriginalProxySourceInit)(
        self, command, frame, container);
}

static id CountHostFrameInit(id self, SEL command, NSRect frame) {
    if (gCountSelectionBConstructions) gInputHostInitCount += 1;
    return ((id (*)(id, SEL, NSRect))gOriginalHostFrameInit)(self, command, frame);
}

static void CountDraggedRegistration(id self, SEL command, NSArray *types) {
    if (gCountSelectionBConstructions) gOverlayDraggedRegistrationCount += 1;
    ((void (*)(id, SEL, NSArray *))gOriginalDraggedRegistration)(self, command, types);
}

static void InstallSelectionBConstructorHooks(void) {
    Class proxy = CJGuiInternalComposableInputProxy.class;
    Class host = CJGuiInternalComposableInputHost.class;
    Class overlay = CJGuiInternalComposableSceneOverlay.class;
    Method method = class_getInstanceMethod(proxy, @selector(initWithFrame:));
    gOriginalProxyFrameInit = method_getImplementation(method);
    class_addMethod(proxy, @selector(initWithFrame:), (IMP)CountProxyFrameInit,
        method_getTypeEncoding(method));
    method = class_getInstanceMethod(proxy, @selector(initWithFrame:textContainer:));
    gOriginalProxySourceInit = method_getImplementation(method);
    class_addMethod(proxy, @selector(initWithFrame:textContainer:), (IMP)CountProxySourceInit,
        method_getTypeEncoding(method));
    method = class_getInstanceMethod(host, @selector(initWithFrame:));
    gOriginalHostFrameInit = method_getImplementation(method);
    class_addMethod(host, @selector(initWithFrame:), (IMP)CountHostFrameInit,
        method_getTypeEncoding(method));
    method = class_getInstanceMethod(overlay, @selector(registerForDraggedTypes:));
    gOriginalDraggedRegistration = method_getImplementation(method);
    class_addMethod(overlay, @selector(registerForDraggedTypes:), (IMP)CountDraggedRegistration,
        method_getTypeEncoding(method));
}

static void ResetSelectionBConstructorCounts(void) {
    gDefaultProxyInitCount = 0;
    gSourceProxyInitCount = 0;
    gInputHostInitCount = 0;
    gOverlayDraggedRegistrationCount = 0;
    gLastSourceProxyContainer = nil;
}

static BOOL PrepareSelectionOnSameAcceptedScene(CJGuiInternalSession *ctx,
                                                uint32_t anchor, uint32_t focus,
                                                uint64_t *outTransfer) {
    uint64_t token = ctx.rendererSessionToken, transfer = 0;
    if (cjgui_internal_renderer_selection_transfer_create(token, &transfer) != CJGUI_INTERNAL_RENDERER_OK ||
        transfer == 0) return NO;
    CJGuiInternalComposableSceneNode *target = ctx.composableSceneOverlay.nodes[1];
    NSData *body = [target.value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate = {0};
    candidate.transferId = transfer;
    candidate.sourceWindowInstanceToken = ctx.installedRangeBasis.candidate.windowInstanceToken ?: 9101;
    candidate.sourceOwnerVersion = ctx.installedRangeBasis.candidate.ownerVersion ?: 10;
    candidate.sourceContextEpoch = ctx.installedRangeBasis.candidate.contextEpoch ?: 4;
    candidate.sourceMirrorRevision = ctx.installedRangeBasis.candidate.mirrorRevision ?: 2;
    candidate.targetNodeId = 402;
    candidate.targetResourceId = 1;
    candidate.targetNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion = ctx.composableSceneVersion;
    candidate.targetAnchor16 = anchor;
    candidate.targetFocus16 = focus;
    candidate.targetBodyUtf8 = body.bytes;
    candidate.targetBodyUtf8Length = (uint32_t)body.length;
    uint8_t actual[65536] = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_selection_transfer_capture_current(
        token, &candidate, actual, sizeof(actual));
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_selection_transfer_publish_pending(token, transfer);
    if (status != CJGUI_INTERNAL_RENDERER_OK || candidate.targetProjectionVersion != target.node.projectionVersion)
        return NO;
    uint8_t ready = 0;
    status = cjgui_internal_renderer_selection_transfer_prepare_b(token, transfer,
        cjgui_internal_renderer_owner_clock_ns() + UINT64_C(16000000), &ready);
    if (status != CJGUI_INTERNAL_RENDERER_OK || !ready) return NO;
    if (outTransfer) *outTransfer = transfer;
    return YES;
}

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        CHECK(device != nil, "input_context_metal_device");
        CJGuiInternalSession *ctx = ProductionFixture(device);
        CHECK(ctx != nil, "input_context_real_production_fixture");
        if (!ctx) return 1;
        CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
        CJGuiInternalComposableInputProxy *old = (id)overlay.inputProxy;
        NSTextInputContext *owned = overlay.inputHost.inputContext;
        CHECK(owned != nil && old.inputContext == owned,
              "active_adapter_uses_stable_host_context");

        CJGuiInternalComposableInputProxy *oracle =
            [[CJGuiInternalComposableInputProxy alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
        CjguiConfigurePlainTextInputProxy(oracle);
        NSDictionary *oracleTyping = [oracle.typingAttributes copy] ?: @{};
        NSParagraphStyle *oracleParagraph = oracleTyping[NSParagraphStyleAttributeName];
        NSFont *oracleFont = oracleTyping[NSFontAttributeName];
        NSColor *oracleColor = oracleTyping[NSForegroundColorAttributeName];
        fprintf(stderr, "typing_oracle keys=%lu paragraph=%s font=%s/%.2f foreground=%s\n",
            (unsigned long)oracleTyping.count, oracleParagraph ? "yes" : "no",
            oracleFont.fontName.UTF8String ?: "none", oracleFont.pointSize,
            oracleColor ? "yes" : "no");

        InstallSelectionBConstructorHooks();
        NSRange oldSelection = old.selectedRange;
        NSResponder *oldResponder = ctx.window.firstResponder;
        uint64_t transfer = 0;
        ResetSelectionBConstructorCounts();
        gCountSelectionBConstructions = YES;
        BOOL preparedOK = PrepareSelectionOnSameAcceptedScene(ctx, 1, 3, &transfer);
        gCountSelectionBConstructions = NO;
        fprintf(stderr, "selection_B_constructors default_proxy=%lu source_proxy=%lu unused_host=%lu drag_registration=%lu\n",
            (unsigned long)gDefaultProxyInitCount, (unsigned long)gSourceProxyInitCount,
            (unsigned long)gInputHostInitCount, (unsigned long)gOverlayDraggedRegistrationCount);
        CjguiSelectionTransferCapsule *capsule = ctx.selectionTransferCapsule;
        CJGuiInternalComposableSceneOverlay *prepared = capsule.preparedOverlay;
        CjguiSelectionTransferBPreparation *bPreparation = capsule.bPreparation;
        CHECK(preparedOK && prepared != nil && bPreparation.sourceLayout != nil,
              "real_candidate_B_preparation_is_available_before_install");
        CHECK(gDefaultProxyInitCount == 0 && gSourceProxyInitCount == 1,
              "candidate_B_constructs_only_its_source_backed_proxy");
        CHECK(gInputHostInitCount == 0 && gOverlayDraggedRegistrationCount == 0 &&
              prepared.inputHost == nil,
              "private_B_has_no_unused_input_host_or_window_drag_registration");
        CHECK(prepared.inputProxy.textContainer == bPreparation.sourceLayout.container &&
              prepared.inputProxy.layoutManager == bPreparation.sourceLayout.layoutManager &&
              prepared.inputProxy.textStorage == bPreparation.sourceLayout.storage &&
              gLastSourceProxyContainer == bPreparation.sourceLayout.container,
              "candidate_proxy_uses_the_exact_prepared_source_graph");
        fprintf(stderr, "candidate_geometry source=%.2fx%.2f proxy=%.2fx%.2f min=%.2fx%.2f max=%.2fx%.2f inset=%.2f,%.2f\n",
            bPreparation.sourceLayout.textRect.size.width, bPreparation.sourceLayout.textRect.size.height,
            prepared.inputProxy.frame.size.width, prepared.inputProxy.frame.size.height,
            prepared.inputProxy.minSize.width, prepared.inputProxy.minSize.height,
            prepared.inputProxy.maxSize.width, prepared.inputProxy.maxSize.height,
            prepared.inputProxy.textContainerInset.width, prepared.inputProxy.textContainerInset.height);
        CHECK(NSEqualSizes(prepared.inputProxy.frame.size, bPreparation.sourceLayout.textRect.size) &&
              NSEqualSizes(prepared.inputProxy.minSize, bPreparation.sourceLayout.textRect.size) &&
              NSEqualSizes(prepared.inputProxy.maxSize, bPreparation.sourceLayout.textRect.size) &&
              NSEqualSizes(prepared.inputProxy.textContainerInset, NSZeroSize),
              "candidate_proxy_keeps_prepared_target_geometry_without_default_container_overrides");
        NSMutableDictionary *expectedTyping = [oracleTyping mutableCopy];
        CJGuiInternalComposableSceneNode *target = ctx.composableSceneOverlay.nodes[1];
        NSColor *targetColor = [NSColor colorWithSRGBRed:target.node.textRed
            green:target.node.textGreen blue:target.node.textBlue alpha:1.0];
        NSFont *targetFont = CjguiComposableFont(target);
        if (targetFont) expectedTyping[NSFontAttributeName] = targetFont;
        if (targetColor) expectedTyping[NSForegroundColorAttributeName] = targetColor;
        CHECK([prepared.inputProxy.typingAttributes isEqualToDictionary:expectedTyping] &&
              ((!oracleParagraph && !prepared.inputProxy.typingAttributes[NSParagraphStyleAttributeName]) ||
               [oracleParagraph isEqual:prepared.inputProxy.typingAttributes[NSParagraphStyleAttributeName]]) &&
              ((!oracleFont && !prepared.inputProxy.typingAttributes[NSFontAttributeName]) ||
               [targetFont isEqual:prepared.inputProxy.typingAttributes[NSFontAttributeName]]) &&
              ((!oracleColor && !prepared.inputProxy.typingAttributes[NSForegroundColorAttributeName]) ||
               [targetColor isEqual:prepared.inputProxy.typingAttributes[NSForegroundColorAttributeName]]),
              "candidate_typing_defaults_and_declared_font_color_are_preserved");
        CHECK(ctx.composableSceneOverlay == overlay && overlay.inputProxy == old &&
              overlay.inputHost.inputContext == owned && old.inputContext == owned &&
              NSEqualRanges(old.selectedRange, oldSelection) && ctx.window.firstResponder == oldResponder &&
              CjguiInputProxyIsFirstResponder(overlay),
              "private_preparation_does_not_change_A_context_selection_or_responder");
        CjguiInternalRendererStatus cancelRequested =
            cjgui_internal_renderer_selection_transfer_request_cancel(ctx.rendererSessionToken, transfer);
        CjguiInternalRendererStatus abortFinished = cancelRequested == CJGUI_INTERNAL_RENDERER_OK
            ? cjgui_internal_renderer_selection_transfer_finish_abort(ctx.rendererSessionToken, transfer)
            : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        CjguiInternalRendererStatus cancelled = abortFinished == CJGUI_INTERNAL_RENDERER_OK
            ? cjgui_internal_renderer_selection_transfer_replay_input(ctx.rendererSessionToken, transfer)
            : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        CjguiInternalRendererStatus ownerReleased = cancelled == CJGUI_INTERNAL_RENDERER_OK
            ? cjgui_internal_renderer_selection_transfer_release(ctx.rendererSessionToken, transfer)
            : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        CHECK(cancelRequested == CJGUI_INTERNAL_RENDERER_OK &&
              abortFinished == CJGUI_INTERNAL_RENDERER_OK && cancelled == CJGUI_INTERNAL_RENDERER_OK &&
              ownerReleased == CJGUI_INTERNAL_RENDERER_OK &&
              overlay.inputProxy == old &&
              overlay.inputHost.inputContext == owned && CjguiInputProxyIsFirstResponder(overlay) &&
              NSEqualRanges(old.selectedRange, oldSelection),
              "actual_B_cancel_keeps_A_input_graph_and_context");

        ResetSelectionBConstructorCounts();
        gCountSelectionBConstructions = YES;
        CHECK(InstallSelectionOnSameAcceptedScene(ctx, 1, 3),
              "input_context_actual_selection_transfer_installs_B");
        gCountSelectionBConstructions = NO;
        CHECK(gDefaultProxyInitCount == 0 && gSourceProxyInitCount == 1 &&
              gInputHostInitCount == 0 && gOverlayDraggedRegistrationCount == 0,
              "committed_B_avoids_discarded_default_graph_and_unused_host");
        CHECK(overlay.inputProxy != old && overlay.inputHost.inputContext == owned &&
              overlay.inputProxy.inputContext == owned && CjguiInputProxyIsFirstResponder(overlay),
              "committed_B_keeps_the_same_host_context_and_responder");
        CHECK(old.inputContext == nil,
              "retired_A_does_not_create_an_independent_ime_context");
        CHECK(cjgui_internal_renderer_destroy(ctx.rendererSessionToken) == 0,
              "input_context_normal_destroy");
        (void)oracle;
    }
    return failures ? 1 : 0;
}
