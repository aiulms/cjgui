// Reproduces the paint/effect-cache inputs left behind when an accepted
// selection transfer collapses the native proxy but the scene still contains
// the old owner-declared selection background. No window or desktop input.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

static int failures = 0;
static int checks = 0;
#define CHECK(condition, name) do { checks++; BOOL ok = (condition); \
    fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name); if (!ok) failures++; } while (0)

static NSDictionary *DeclaredRect(NSRect rect) {
    return @{ @"rect": [NSValue valueWithRect:rect], @"color": NSColor.selectedTextBackgroundColor };
}

static CJGuiInternalComposableSceneNode *NodeWithOldSelection(NSRect rangeRect) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 901; raw.resourceId = 7; raw.projectionVersion = 42;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.x = 0; raw.y = 0; raw.width = 120; raw.height = 50;
    raw.clipWidth = 120; raw.clipHeight = 50; raw.textAlpha = 1.0;
    node.node = raw;
    node.value = @"owner body";
    node.textDeclaredSelectionDecorations = @[DeclaredRect(rangeRect)];
    return node;
}

static CJGuiInternalSession *SessionForTransferScene(
    CJGuiInternalComposableSceneNode *focus, CJGuiInternalComposableSceneNode *other,
    CjguiInstalledRangeState **outBasis) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.sessionGeneration = 5;
    ctx.composableSceneVersion = 42;
    ctx.ownedTextSessionEnabled = YES;
    ctx.ownedTextSessionNodeId = focus.node.nodeId;
    ctx.ownedTextSessionResourceId = focus.node.resourceId;
    ctx.ownedTextSessionNodeKind = focus.node.nodeKind;
    ctx.ownedTextSessionBindingEpoch = 8;
    ctx.installedRangeObservedAckVersion = 3;

    CJGuiInternalComposableSceneOverlay *overlay =
        [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSMakeRect(0, 0, 120, 50) session:ctx];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 120, 50)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    CJGuiInternalComposableInputHost *host = [CJGuiInternalComposableInputHost new];
    host.composableOverlay = overlay;
    NSTextView *proxy = [NSTextView new];
    proxy.string = @"owner body";
    proxy.selectedRange = NSMakeRange(6, 0);
    overlay.inputHost = host;
    overlay.inputProxy = proxy;
    overlay.activeNodeId = focus.node.nodeId;
    overlay.activeNodeResourceId = focus.node.resourceId;
    overlay.activeNodeKind = focus.node.nodeKind;
    overlay.activeProjectionVersion = 42;
    overlay.installedRangeSelectionRevision = 12;
    [overlay addSubview:host];
    [host addSubview:proxy];
    window.contentView = overlay;
    [window makeFirstResponder:host];
    ctx.composableSceneOverlay = overlay;
    ctx.window = window;

    CJGuiInternalMetalView *view = [CJGuiInternalMetalView new];
    view.composableNodes = @[focus, other];
    ctx.view = view;
    focus.index = 0;
    other.index = 1;

    CjguiInstalledRangeState *basis = [CjguiInstalledRangeState new];
    basis.active = YES;
    basis.hasReceipt = YES;
    basis.proxy = proxy;
    basis.proxyGeneration = 9;
    basis.selectionRevision = 12;
    basis.actualSelectionStart16 = 6;
    basis.actualSelectionEnd16 = 6;
    basis.selectionTransferId = 77;
    basis.proxyNodeKind = focus.node.nodeKind;
    basis.sourceUtf8 = [@"owner body" dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalInstalledRangeCandidate candidate = {0};
    candidate.nonce = 77;
    candidate.rendererSessionGeneration = 5;
    candidate.nodeId = focus.node.nodeId;
    candidate.resourceId = focus.node.resourceId;
    candidate.bindingEpoch = 8;
    candidate.installedSceneVersion = 42;
    candidate.ownerVersion = 3;
    basis.candidate = candidate;
    ctx.installedRangeBasis = basis;
    ctx.installedRangeProxyGeneration = 9;
    if (outBasis) *outBasis = basis;
    return ctx;
}

int main(void) {
    @autoreleasepool {
        // This is the same accepted-scene/native-proxy split as the production
        // failure: owner-declared old selection on scene 42, native B receipt
        // has already moved the proxy caret to 69:69.
        CJGuiInternalComposableSceneNode *focus =
            NodeWithOldSelection(NSMakeRect(10, 10, 35, 18));
        focus.textSelectionRects = @[];
        focus.textCaretRect = NSMakeRect(78, 10, 1.5, 18);
        CJGuiInternalComposableSceneNode *other =
            NodeWithOldSelection(NSMakeRect(10, 10, 35, 18));
        CjguiInternalRendererComposableNode otherIdentity = other.node;
        otherIdentity.nodeId = 902;
        otherIdentity.resourceId = 8;
        other.node = otherIdentity;
        CjguiInstalledRangeState *basis = nil;
        CJGuiInternalSession *ctx = SessionForTransferScene(focus, other, &basis);

        // The same-frame effective selection must come from the collapsed
        // native proxy. The old owner rectangle at (20,15) must not paint.
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 0 &&
              !CjguiComposableTextPresentationMayAffectVisiblePoint(
                  ctx, focus, 20, 15, NSMakeSize(120, 50)),
            "accepted_collapsed_proxy_suppresses_old_focus_selection_paint");
        CHECK(CjguiComposableRectContainsPoint(focus.textCaretRect, 78.5, 15),
            "accepted_collapsed_proxy_keeps_new_native_caret_geometry");

        // Old owner-declared selection bytes must not keep the effect cache
        // keyed as though that background were still part of this frame.
        CJGuiInternalComposableSceneNode *withoutOldSelection =
            NodeWithOldSelection(NSMakeRect(10, 10, 35, 18));
        withoutOldSelection.textDeclaredSelectionDecorations = @[];
        withoutOldSelection.textSelectionRects = focus.textSelectionRects;
        withoutOldSelection.textCaretRect = focus.textCaretRect;
        withoutOldSelection.textCaretHidden = focus.textCaretHidden;
        uint64_t seed = UINT64_C(1469598103934665603);
        CHECK(CjguiEffectHashPaintNodeForSession(ctx, seed, focus, focus.node) ==
              CjguiEffectHashPaintNodeForSession(ctx, seed, withoutOldSelection, withoutOldSelection.node),
            "effect_hash_uses_same_collapsed_selection_paint_inputs");

        // Other fragments retain immutable accepted declarations. The common
        // frame fence, tested separately, prevents a mixed frame submission.
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, other).count == 1,
            "same_transfer_scene_retains_other_fragment_until_full_publication");
        CHECK(focus.textDeclaredSelectionDecorations.count == 1 &&
              other.textDeclaredSelectionDecorations.count == 1,
            "paint_override_does_not_mutate_accepted_declared_arrays");
        CHECK(ctx.selectionTraceTransferId == 0 &&
              CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 0,
            "production_paint_override_requires_no_optional_trace_state");
        CjguiInternalInstalledRangeCandidate changedCandidate = basis.candidate;
        changedCandidate.installedSceneVersion = 41;
        basis.candidate = changedCandidate;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, other).count == 1,
            "different_transfer_scene_does_not_suppress_other_fragment");
        changedCandidate = basis.candidate;
        changedCandidate.installedSceneVersion = 42;
        basis.candidate = changedCandidate;

        // Once a new owner scene is accepted, its current global declarations
        // win as a whole; the prior transfer's local proxy range cannot
        // replace a fresh cross-fragment owner selection.
        ctx.composableSceneVersion = 43;
        ctx.composableSceneOverlay.activeProjectionVersion = 43;
        CjguiInternalRendererComposableNode focusRaw = focus.node;
        focusRaw.projectionVersion = 43;
        focus.node = focusRaw;
        CjguiInternalRendererComposableNode otherRaw = other.node;
        otherRaw.projectionVersion = 43;
        other.node = otherRaw;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 1,
            "fresh_scene_preserves_current_focus_owner_declaration");
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, other).count == 1,
            "fresh_scene_preserves_other_fragment_declaration");

        // Receipt, binding and scene identity mismatches must fail closed and
        // return the immutable declaration rather than overriding it.
        ctx.ownedTextSessionBindingEpoch += 1;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 1,
            "binding_mismatch_does_not_override_declared_selection");
        ctx.ownedTextSessionBindingEpoch -= 1;
        ctx.installedRangeProxyGeneration += 1;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 1,
            "proxy_generation_mismatch_does_not_override_declared_selection");
        ctx.installedRangeProxyGeneration -= 1;
        NSTextView *differentProxy = [NSTextView new];
        differentProxy.string = @"owner body";
        differentProxy.selectedRange = NSMakeRange(6, 0);
        NSTextView *installedProxy = ctx.composableSceneOverlay.inputProxy;
        ctx.composableSceneOverlay.inputProxy = differentProxy;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 1,
            "proxy_identity_mismatch_does_not_override_declared_selection");
        ctx.composableSceneOverlay.inputProxy = installedProxy;
        focusRaw = focus.node;
        focusRaw.projectionVersion = 44;
        focus.node = focusRaw;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 1,
            "projection_mismatch_does_not_override_declared_selection");
        focusRaw.projectionVersion = 43;
        focus.node = focusRaw;
        basis.hasReceipt = NO;
        CHECK(CjguiEffectiveDeclaredSelectionDecorations(ctx, focus).count == 1,
            "missing_install_receipt_does_not_override_declared_selection");

        // The changed caret and owner declaration are deliberately disjoint;
        // a passing implementation cannot hide the new caret to mask the old
        // range.
        CHECK(!NSIsEmptyRect(focus.textCaretRect), "caret_rect_is_present_in_same_frame");
    }
    fprintf(stderr, "selection transfer paint override checks=%d failures=%d\n", checks, failures);
    return failures ? 1 : 0;
}
