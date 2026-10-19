// Production receipt query. Fixture capture fields are explicit test inputs;
// actual proxy installation/readback still uses the real transfer route.
#define CJGUI_PREFIX_NO_MAIN 1
#import "composable_prefix_present_handoff_test.m"

static void UnchangedCaptureReceipt(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CjguiInternalSelectionTransferReceipt installed={0};
    CHECK(ctx && InstallPrefixSelectionA(ctx,&installed),"unchanged_actual_install");
    if(!ctx || !ctx.installedRangeBasis.hasReceipt)return;
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    uint64_t token=ctx.rendererSessionToken;uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,basis.selectionTransferId,
        ctx.sessionGeneration,basis.candidate.bindingEpoch,basis.proxyGeneration,basis.selectionRevision,
        10,1,1,&needs)==0,"unchanged_actual_publication");
    CJGuiInternalComposableSceneNode *target=o.nodes[1];
    CjguiInternalRendererComposableNode raw=target.node;raw.acceptedBindingEpoch=17;target.node=raw;
    o.pointerCaptureActive=YES;o.pointerCaptureGestureEpoch=9;
    o.pointerCaptureNodeId=402;o.pointerCaptureResourceId=1;
    o.pointerCaptureNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    CjguiInternalInstalledRangeReceipt receipt={0};
#define READ(scene,gesture,binding) cjgui_internal_renderer_unchanged_capture_receipt( \
    token,basis.candidate.nonce,scene,gesture,402,1,binding,&receipt)
    CHECK(READ(1,9,17)==0 && receipt.nonce==basis.candidate.nonce &&
        receipt.installedSceneVersion==1 && receipt.proxyGeneration==basis.proxyGeneration,
        "unchanged_atomic_current_capture_and_resident_receipt");
    CHECK(READ(2,9,17)!=0 && !receipt.nonce,"unchanged_wrong_accepted_scene_refused");
    CHECK(READ(1,10,17)!=0 && !receipt.nonce,"unchanged_new_gesture_refused");
    CHECK(READ(1,9,18)!=0 && !receipt.nonce,"unchanged_capture_binding_domain_refused");
    raw.semanticIncarnation++;target.node=raw;
    CHECK(READ(1,9,17)!=0,"unchanged_semantic_ABA_refused");
    raw.semanticIncarnation--;target.node=raw;
    NSString *body=target.value;target.value=@"new layout body";
    CHECK(READ(1,9,17)!=0,"unchanged_changed_current_target_refused");target.value=body;
    o.sourceInputParked=YES;
    CHECK(READ(1,9,17)!=0,"unchanged_parked_proxy_refused");o.sourceInputParked=NO;
    ctx.installedRangeLocalTailSequence++;
    CHECK(READ(1,9,17)!=0,"unchanged_unacked_edit_refused");ctx.installedRangeLocalTailSequence--;
    o.compositionTerminalInFlight=YES;
    CHECK(READ(1,9,17)!=0,"unchanged_composition_refused");o.compositionTerminalInFlight=NO;
    ctx.closeRequested=YES;
    CHECK(READ(1,9,17)!=0,"unchanged_close_refused");ctx.closeRequested=NO;
    // Accepted scene changes without changing the installed historical receipt.
    // This is a query boundary test, not proof of Cj capture certification.
    ctx.composableSceneVersion=2;
    CHECK(READ(2,9,17)==0 && receipt.installedSceneVersion==1 &&
        receipt.proxyGeneration==installed.proxyGeneration &&
        receipt.selectionRevision==installed.selectionRevision,
        "unchanged_passive_scene_keeps_historical_install_identity");
    CHECK(READ(1,9,17)!=0,"unchanged_old_current_scene_refused_after_advance");
    [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(READ(2,9,17)!=0,"unchanged_real_pending_text_refused");
#undef READ
    CjguiReleaseSession(token);
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(!device)return 77;UnchangedCaptureReceipt(device);return failures?1:0;
} }
