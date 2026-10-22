// Start at the real NSWindow responder, rather than calling overlay keyDown
// directly. No CJGUI_INTERNAL_TESTING shortcut or field-focus setup is used.
#import "../cjgui_internal_renderer.m"

static int failures;
#define CHECK(condition, name) do { BOOL ok = (condition); \
    fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name); \
    if (!ok) failures++; } while (0)

static CJGuiInternalSession *KeyboardFixture(id<MTLDevice> device, BOOL scrollScope) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.app = [NSApplication sharedApplication];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 400, 240)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window = [[CJGuiInternalWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 240)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:YES];
    ctx.window.releasedWhenClosed = NO;
    ((CJGuiInternalWindow *)ctx.window).cjguiSession = ctx;
    ctx.windowContentHost = [[NSView alloc] initWithFrame:ctx.view.bounds];
    ctx.window.contentView = ctx.windowContentHost;
    [ctx.windowContentHost addSubview:ctx.view];
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token || CjguiConfigureComposableSceneOnMain(token, 1, 3) != 0) return nil;
    for (NSUInteger index = 0; index < 3; index++) {
        CJGuiInternalComposableSceneNode *node = ctx.stagedComposableNodes[index];
        CjguiInternalRendererComposableNode raw = {0};
        raw.nodeId = 101 + index; raw.projectionVersion = 1;
        raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
        raw.resourceId = 1; raw.isInteractive = index != 1;
        if (scrollScope && index == 1) {
            raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
            raw.isInteractive = 1;
        }
        raw.x = 10; raw.y = index * 50; raw.width = 160; raw.height = 36;
        raw.clipWidth = 400; raw.clipHeight = 240; raw.fontSize = 13;
        raw.textAlpha = 1;
        node.node = raw; node.index = (uint32_t)index;
        node.label = @"Keyboard action"; node.value = @"";
    }
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    if (CjguiCommitComposableSceneOnMain(token) != 0) return nil;
    // This is the same input publication called after a successful Present.
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    return ctx;
}

static void WindowKey(CJGuiInternalSession *ctx, unsigned short code,
                      NSEventModifierFlags flags, NSString *text) {
    NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:flags timestamp:1 windowNumber:ctx.window.windowNumber context:nil
        characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:code];
    [ctx.window sendEvent:event];
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) return 77;
        CJGuiInternalSession *ctx = KeyboardFixture(device, NO);
        CHECK(ctx != nil, "initial_keyboard_real_window_fixture");
        if (ctx) {
            CHECK(ctx.composableSceneOverlay.activeNodeId == 0,
                "initial_keyboard_no_forced_control_focus");
            WindowKey(ctx, 48, 0, @"\t");
            CHECK(ctx.composableSceneOverlay.activeNodeId == 101,
                "initial_tab_reaches_first_declared_enabled_control");
            WindowKey(ctx, 48, 0, @"\t");
            CHECK(ctx.composableSceneOverlay.activeNodeId == 103,
                "tab_skips_disabled_control");
            WindowKey(ctx, 48, NSEventModifierFlagShift, @"\t");
            CHECK(ctx.composableSceneOverlay.activeNodeId == 101,
                "backtab_uses_same_declared_order");
            NSUInteger queued = ctx.pendingInteractions.count;
            WindowKey(ctx, 49, NSEventModifierFlagControl | NSEventModifierFlagOption, @" ");
            CHECK(ctx.pendingInteractions.count == queued,
                "voiceover_chord_is_not_ordinary_button_space");
            WindowKey(ctx, 49, 0, @" ");
            CHECK(ctx.pendingInteractions.count > queued,
                "ordinary_button_space_keeps_existing_action_route");
            CjguiReleaseSession(ctx.rendererSessionToken);
        }
        ctx = KeyboardFixture(device, NO);
        if (ctx) {
            WindowKey(ctx, 48, NSEventModifierFlagShift, @"\t");
            CHECK(ctx.composableSceneOverlay.activeNodeId == 103,
                "initial_backtab_reaches_last_enabled_control");
            CjguiReleaseSession(ctx.rendererSessionToken);
        }
        ctx = KeyboardFixture(device, YES);
        if (ctx) {
            CHECK(cjgui_internal_renderer_focus_composable_node(ctx.rendererSessionToken, 102) == 0 &&
                ctx.composableSceneOverlay.activeNodeId == 102 &&
                ctx.window.firstResponder == ctx.composableSceneOverlay,
                "accepted_scroll_scope_uses_existing_programmatic_focus");
            CjguiReleaseSession(ctx.rendererSessionToken);
        }
        fprintf(stderr, "initial_keyboard failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}
