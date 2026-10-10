// 撤回声明后的 caret 几何。
//
// 产品的正文是 presentation TEXT 节点（`CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT`），这类节点
// 可以换行成多条视觉行。声明被撤回时（`CjguiDeclareInputCaretOnOverlay(nodeId<0)` →
// `withdrawDeclaredInputCaret`）框架回退到 single-line 装饰，而那条路径把 caret 高度取成
// **整个节点框**（`NSHeight(textRect) - 4`）。用户视频里"删除时 caret 异常变长"就是这个形状。
//
// 本夹具只用真实 session/overlay/TextKit 路径回答一个问题：撤回声明之后，最终 caret 矩形
// 的高度是一条视觉行，还是整个节点高度。不显示窗口、不合成输入、不投递事件。
//
// 同时保留一个单行节点作为负控：真正只有一条视觉行的节点，修复前后都必须给出行高级别的高度。
#define CJGUI_CARET_AFTER_INPUT_FIXTURE 1
#import "composable_installed_range_prefix_test.m"

static CJGuiInternalComposableSceneNode *WithdrawnCaretFindNode(SourceInstallOverlay *overlay,
    uint64_t nodeId) {
    for (CJGuiInternalComposableSceneNode *node in overlay.nodes) {
        if (node.node.nodeId == nodeId) return node;
    }
    return nil;
}

/// Real session + overlay + input proxy, one interactive presentation TEXT node. No window is
/// shown and no input is synthesized; the node is activated through the same focus entry the
/// pointer path uses.
static SourceInstallOverlay *WithdrawnCaretFixture(id<MTLDevice> device, NSString *body,
    CGFloat nodeWidth, CGFloat nodeHeight, uint32_t nodeKind) {
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
    raw.nodeKind = nodeKind;
    raw.width = nodeWidth;
    raw.height = nodeHeight;
    raw.clipWidth = 680;
    raw.clipHeight = 500;
    raw.fontSize = 13;
    raw.textAlpha = 1;
    raw.isInteractive = 1;
    node.node = raw;
    node.index = 0;
    node.value = body;
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    ctx.stagedComposableNodes = [NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;

    uint64_t token = CjguiAllocateSession(ctx);
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return nil;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    if (![overlay focusCommittedNodeId:401]) return nil;
    [overlay.inputProxy setString:body];
    [overlay.inputProxy setSelectedRange:NSMakeRange(20, 0)];
    // Same preparation entry the paint path uses; the decoration pass below is the production one.
    [overlay refreshGpuTextForActiveInput];
    return overlay;
}

static void WithdrawnCaretGeometryFixture(id<MTLDevice> device) {
    NSMutableString *body = [NSMutableString string];
    for (NSUInteger i = 0; i < 40; i++) [body appendString:@"word "];

    SourceInstallOverlay *wrapped = WithdrawnCaretFixture(device, body, 180.0, 160.0,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT);
    CHECK(wrapped != nil, "withdrawn_caret_wrapped_fixture");
    if (wrapped) {
        CJGuiInternalComposableSceneNode *node = WithdrawnCaretFindNode(wrapped, 401);
        CHECK(node != nil, "withdrawn_caret_wrapped_node_present");
        CjguiPreparedTextNodeLayout *prepared = node.preparedTextLayout;
        // Count the visual lines the accepted layout actually produced. This is the observable
        // that decides whether the single-line fallback is even structurally valid for this node.
        NSUInteger lines = 0;
        if (prepared && prepared.layoutManager && prepared.container && prepared.storage.length > 0) {
            NSLayoutManager *layout = prepared.layoutManager;
            NSUInteger glyph = 0;
            NSUInteger glyphCount = layout.numberOfGlyphs;
            while (glyph < glyphCount) {
                NSRange lineRange = NSMakeRange(NSNotFound, 0);
                (void)[layout lineFragmentRectForGlyphAtIndex:glyph effectiveRange:&lineRange];
                if (lineRange.location == NSNotFound || lineRange.length == 0) break;
                glyph = NSMaxRange(lineRange);
                lines += 1;
            }
        }
        // The declared caret is the product's own answer and must be honoured verbatim.
        // x must sit inside the 7pt text inset, otherwise the declared rect clips to empty and
        // the declaration is silently dropped (that is a fixture mistake, not a framework defect).
        CjguiDeclareInputCaretOnOverlay(wrapped, 401, 8.0, 2.0, 1.5, 14.0);
        NSRect declared = node.textCaretRect;
        CHECK(node.textCaretIsDeclared && fabs(declared.size.height - 14.0) < 0.001,
            "withdrawn_caret_declared_rect_is_honoured");
        // Withdraw exactly the way the product does: nodeId < 0.
        CjguiDeclareInputCaretOnOverlay(wrapped, -1, 0.0, 0.0, 0.0, 0.0);
        NSRect withdrawn = node.textCaretRect;
        fprintf(stderr, "WITHDRAWN_CARET kind=%u node=%.1fx%.1f visual_lines=%lu declared=%.2f,%.2f,%.2f,%.2f "
            "withdrawn=%.2f,%.2f,%.2f,%.2f declared_flag=%d\n",
            node.node.nodeKind, (double)node.node.width, (double)node.node.height, (unsigned long)lines,
            declared.origin.x, declared.origin.y, declared.size.width, declared.size.height,
            withdrawn.origin.x, withdrawn.origin.y, withdrawn.size.width, withdrawn.size.height,
            (int)node.textCaretIsDeclared);
        CHECK(lines >= 2, "withdrawn_caret_fixture_actually_wraps");
        // The consumer withdrew its drawn bar (its own surface). The framework must not invent a
        // caret for it: neither the whole-node-box bar (the defect) nor a shortened guess.
        CHECK(NSIsEmptyRect(withdrawn),
            "withdrawn_declaration_hides_the_consumer_bar_instead_of_inventing_one");
        CHECK(withdrawn.size.height < node.node.height * 0.5,
            "withdrawn_caret_is_not_the_whole_node_box_height");
        cjgui_internal_renderer_destroy(wrapped.session.rendererSessionToken);
    }

    // Negative control: the framework still owns the caret for a REAL text input. Withdrawing a
    // declaration there must hand the caret back to the proxy-derived single-line decoration --
    // otherwise this fix would just have disabled the fallback for everyone.
    SourceInstallOverlay *input = WithdrawnCaretFixture(device, @"single line", 180.0, 28.0,
        CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT);
    CHECK(input != nil, "withdrawn_caret_text_input_fixture");
    if (input) {
        CJGuiInternalComposableSceneNode *node = WithdrawnCaretFindNode(input, 401);
        CHECK(node != nil, "withdrawn_caret_text_input_node_present");
        CjguiDeclareInputCaretOnOverlay(input, 401, 8.0, 2.0, 1.5, 14.0);
        NSRect declared = node.textCaretRect;
        // The declared bar is honoured at the declared place; its height is the intersection with
        // the node's own text inset, so assert placement and existence rather than the raw 14pt.
        CHECK(node.textCaretIsDeclared && !NSIsEmptyRect(declared) && declared.size.height > 0.0 &&
            fabs(declared.origin.x - 8.0) < 0.001,
            "withdrawn_caret_text_input_declared_rect_is_honoured");
        CjguiDeclareInputCaretOnOverlay(input, -1, 0.0, 0.0, 0.0, 0.0);
        NSRect withdrawn = node.textCaretRect;
        fprintf(stderr, "WITHDRAWN_CARET_TEXT_INPUT node=%.1fx%.1f withdrawn=%.2f,%.2f,%.2f,%.2f\n",
            (double)node.node.width, (double)node.node.height,
            withdrawn.origin.x, withdrawn.origin.y, withdrawn.size.width, withdrawn.size.height);
        CHECK(withdrawn.size.height > 0.0 && withdrawn.size.height <= node.node.height,
            "withdrawn_caret_text_input_keeps_the_framework_single_line_caret");
        cjgui_internal_renderer_destroy(input.session.rendererSessionToken);
    }
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 2;
    WithdrawnCaretGeometryFixture(device);
    fprintf(stderr, "withdrawn_caret_geometry failures=%d\n", failures);
    return failures ? 1 : 0;
} }
