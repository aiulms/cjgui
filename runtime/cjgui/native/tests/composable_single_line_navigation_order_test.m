// A bound ordinary field still uses the native adapter's exact edit range.
// Queue no owner work between navigation and insertion: the original fast
// sequence must not depend on an asynchronous selection restoration winning.
#define main previousSelectionPaintMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

static void NativeCommand(CJGuiInternalComposableSceneOverlay *overlay, SEL command) {
    if (![overlay textView:overlay.inputProxy doCommandBySelector:command])
        [overlay.inputProxy tryToPerform:command with:nil];
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"navigation_production_fixture");
    if (!ctx) return 1;
    NSString *original=@"Cycleé👩🏽‍💻A7";
    CHECK(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken,3,1)==0,
        "single_line_scene_configured");
    CJGuiInternalComposableSceneNode *node=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[0],0,3);
    CjguiInternalRendererComposableNode raw=node.node;
    raw.nodeId=401;raw.resourceId=1;raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    raw.projectionVersion=3;raw.x=20;raw.y=20;raw.width=400;raw.height=40;
    raw.clipX=0;raw.clipY=0;raw.clipWidth=680;raw.clipHeight=500;
    node.node=raw;node.value=original;ctx.stagedComposableNodes[0]=node;
    CHECK(CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken)==0,"single_line_scene_accepted");
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    CJGuiInternalComposableSceneOverlay *overlay=ctx.composableSceneOverlay;
    CHECK([overlay focusCommittedNodeId:401],"navigation_original_focus");
    ctx.ownedTextSessionEnabled=YES;
    ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1;
    ctx.ownedTextSessionNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    ctx.ownedTextSessionBindingEpoch=71;
    ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    [ctx.pendingInteractions removeAllObjects];
    [overlay.inputProxy selectAll:nil];
    NativeCommand(overlay,@selector(moveLeft:));
    NativeCommand(overlay,@selector(moveRightAndModifySelection:));
    NativeCommand(overlay,@selector(moveRightAndModifySelection:));
    CHECK(NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(0,2)),
        "bound_single_line_navigation_settled_before_next_native_callback");
    [overlay.inputProxy insertText:@"8" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK([overlay.inputProxy.string isEqualToString:@"8cleé👩🏽‍💻A7"],
        "fast_replace_preserves_unselected_unicode_body");
    NSUInteger edits=0,navigation=0;
    for(CJGuiInternalQueuedInteraction *event in ctx.pendingInteractions) {
        if(event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE)navigation++;
        if(event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED) {
            edits++;
            CHECK(event.selectionStart==0 && event.selectionEnd==2 && [event.formText isEqualToString:@"8"],
                "exact_range_and_payload_enter_original_owner_FIFO");
        }
    }
    CHECK(edits==1 && navigation==0,"one_business_edit_without_unsettled_navigation");
    CHECK(cjgui_internal_renderer_destroy(ctx.rendererSessionToken)==0,"navigation_normal_destroy");
    return failures?1:0;
} }
