// 跨片段高亮的覆盖交接。
//
// 现状：一次拖选在原生侧安装 transfer 时，`CjguiEffectiveDeclaredSelectionDecorations` 会在
// "当前场景仍是 transfer 安装时的那一版"期间，把**整场景**的 owner 声明选区一起隐藏。可是
// transfer 只证明**目标片段**的选区正在被代理改写：它对该片段之外的可见片段什么都没有证明，
// 而那些片段的声明正是**当前 accepted 场景**自己接受的。整场隐藏于是让所有非目标片段在这段
// 窗口里一起变空 —— 用户视频里的"跨片段高亮部分反复消失"。
//
// 本夹具用真实 session/overlay/installed-range 路径（不显示窗口、不合成系统输入）断言交接责任：
//   1. 目标片段：声明让位给 transfer/proxy（必须为空，不得恢复旧选区）；
//   2. 非目标片段：保留 owner 最后被接受的那份声明（可见选区连续覆盖）；
//   3. 更新的 accepted 场景到达后：两个片段都回到各自的声明（整场景权威，不记忆被取代的区间）。
#define CJGUI_CARET_AFTER_INPUT_FIXTURE 1
#import "composable_installed_range_prefix_test.m"

static NSDictionary *CoverageDecoration(NSRect rect) {
    return @{ @"rect": [NSValue valueWithRect:rect], @"color": [NSColor redColor] };
}

static CJGuiInternalComposableSceneNode *CoverageFindNode(CJGuiInternalSession *ctx, uint64_t nodeId) {
    for (CJGuiInternalComposableSceneNode *node in ctx.view.composableNodes) {
        if (node.node.nodeId == nodeId) return node;
    }
    return nil;
}

static void CoverageSetDeclarations(CJGuiInternalSession *ctx) {
    for (uint64_t nodeId = 401; nodeId <= 402; nodeId++) {
        CJGuiInternalComposableSceneNode *node = CoverageFindNode(ctx, nodeId);
        if (!node) continue;
        node.textDeclaredSelectionDecorations = @[ CoverageDecoration(NSMakeRect(10.0, 20.0, 120.0, 16.0)) ];
    }
}

/// Two interactive presentation TEXT fragments (the product's source-mode blocks). The transfer is
/// built directly on the overlay/session state the paint view actually consults: the installed-range
/// ARM entry point is multiline-only, while a TEXT target is admitted through the selection-transfer
/// identity (`selectionTransferId` + `proxyNodeKind`), which is the branch this fixture exercises.
static CJGuiInternalSession *CoverageFixture(id<MTLDevice> device) {
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

    NSString *targetBody = @"target fragment body";
    NSString *siblingBody = @"sibling fragment body";
    CJGuiInternalComposableSceneNode *target = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode targetRaw = {0};
    targetRaw.nodeId = 401; targetRaw.resourceId = 1; targetRaw.projectionVersion = 1;
    targetRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    targetRaw.width = 660; targetRaw.height = 120; targetRaw.clipWidth = 680; targetRaw.clipHeight = 500;
    targetRaw.fontSize = 13; targetRaw.textAlpha = 1; targetRaw.isInteractive = 1;
    target.node = targetRaw; target.index = 0; target.value = targetBody;
    target.styleRunsSignature = @""; target.textTextureCacheKey = @"";

    CJGuiInternalComposableSceneNode *sibling = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode siblingRaw = {0};
    siblingRaw.nodeId = 402; siblingRaw.resourceId = 3; siblingRaw.projectionVersion = 1;
    siblingRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    siblingRaw.width = 660; siblingRaw.height = 120; siblingRaw.clipWidth = 680; siblingRaw.clipHeight = 500;
    siblingRaw.fontSize = 13; siblingRaw.textAlpha = 1; siblingRaw.isInteractive = 1;
    sibling.node = siblingRaw; sibling.index = 1; sibling.value = siblingBody;
    sibling.styleRunsSignature = @""; sibling.textTextureCacheKey = @"";

    ctx.stagedComposableNodes = [NSMutableArray arrayWithObjects:target, sibling, nil];
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;

    uint64_t token = CjguiAllocateSession(ctx);
    CjguiInternalRendererStatus commitStatus = CjguiCommitComposableSceneOnMain(token);
    if (commitStatus != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "COVERAGE_FIXTURE_STEP commit=%d\n", (int)commitStatus);
        return nil;
    }
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    [overlay.inputProxy setString:targetBody];
    [overlay.inputProxy setSelectedRange:NSMakeRange(0, targetBody.length)];
    overlay.testWindow.testResponder = overlay.inputHost;

    uint64_t binding = 71;
    uint64_t transferId = 4242;
    NSData *bytes = [targetBody dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInstalledRangeState *basis = [CjguiInstalledRangeState new];
    basis.active = YES;
    basis.chainClosed = NO;
    basis.hasReceipt = YES;
    basis.selectionTransferId = transferId;
    basis.proxy = overlay.inputProxy;
    basis.proxyGeneration = 7;
    basis.selectionRevision = 9;
    basis.proxyNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    basis.actualSelectionStart16 = 0;
    basis.actualSelectionEnd16 = (uint32_t)targetBody.length;
    basis.sourceUtf8 = bytes;
    basis.candidate = (CjguiInternalInstalledRangeCandidate){
        .nonce = transferId, .rendererSessionGeneration = ctx.sessionGeneration,
        .windowInstanceToken = 910, .bindingEpoch = binding, .contextEpoch = 4,
        .mirrorRevision = 2, .ownerVersion = 10, .installedSceneVersion = ctx.composableSceneVersion,
        .nodeId = 401, .resourceId = 1, .sourceStartByte = 0, .sourceEndByte = bytes.length,
    };
    ctx.installedRangeBasis = basis;
    ctx.installedRangeProxyGeneration = 7;
    ctx.installedRangeObservedAckVersion = 10;
    ctx.ownedTextSessionEnabled = YES;
    ctx.ownedTextSessionNodeId = 401;
    ctx.ownedTextSessionResourceId = 1;
    ctx.ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    ctx.ownedTextSessionBindingEpoch = binding;
    ctx.rangeTextEditDeltaDeliveryEnabled = YES;
    overlay.activeNodeId = 401;
    overlay.activeNodeResourceId = 1;
    overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    overlay.activeProjectionVersion = 1;
    overlay.installedRangeSelectionRevision = 9;
    [ctx.pendingInteractions removeAllObjects];
    return ctx;
}

static void CoverageHandoffFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx = CoverageFixture(device);
    CHECK(ctx != nil, "coverage_fixture");
    if (!ctx) return;
    CJGuiInternalComposableSceneNode *target = CoverageFindNode(ctx, 401);
    CJGuiInternalComposableSceneNode *sibling = CoverageFindNode(ctx, 402);
    CHECK(target != nil && sibling != nil, "coverage_nodes_present");
    CjguiInstalledRangeState *basis = ctx.installedRangeBasis;
    CHECK(basis != nil && basis.active && !basis.chainClosed && basis.hasReceipt &&
        basis.selectionTransferId != 0, "coverage_transfer_active");
    CHECK(ctx.composableSceneVersion == basis.candidate.installedSceneVersion,
        "coverage_transfer_is_on_the_current_scene");

    CoverageSetDeclarations(ctx);
    NSUInteger targetAtInstalled = [CjguiEffectiveDeclaredSelectionDecorations(ctx, target) count];
    NSUInteger siblingAtInstalled = [CjguiEffectiveDeclaredSelectionDecorations(ctx, sibling) count];
    fprintf(stderr, "DECLARED_COVERAGE scene=%llu installed=%llu target=%lu sibling=%lu\n",
        (unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)basis.candidate.installedSceneVersion,
        (unsigned long)targetAtInstalled, (unsigned long)siblingAtInstalled);

    // 1. The target fragment's owner declaration yields to the live proxy range.
    CHECK(targetAtInstalled == 0, "coverage_target_declaration_yields_to_transfer");
    // 2. Every other visible fragment keeps the statement the CURRENT accepted scene accepted.
    CHECK(siblingAtInstalled == 1, "coverage_non_target_fragment_keeps_its_accepted_declaration");

    // 3. A newer accepted scene wins as a whole: each node answers from its own declaration.
    ctx.composableSceneVersion += 1;
    NSUInteger targetAfterAdvance = [CjguiEffectiveDeclaredSelectionDecorations(ctx, target) count];
    NSUInteger siblingAfterAdvance = [CjguiEffectiveDeclaredSelectionDecorations(ctx, sibling) count];
    fprintf(stderr, "DECLARED_COVERAGE_ADVANCED scene=%llu target=%lu sibling=%lu\n",
        (unsigned long long)ctx.composableSceneVersion,
        (unsigned long)targetAfterAdvance, (unsigned long)siblingAfterAdvance);
    CHECK(targetAfterAdvance == 1 && siblingAfterAdvance == 1,
        "coverage_newer_scene_restores_every_fragment_declaration");

    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 2;
    CoverageHandoffFixture(device);
    fprintf(stderr, "declared_selection_coverage failures=%d\n", failures);
    return failures ? 1 : 0;
} }
