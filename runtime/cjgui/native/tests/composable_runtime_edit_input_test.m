// Accepted projection reconciliation; ordinary input, no testing renderer mode.
#define main PreviousRuntimeEditFixtureMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

static CJGuiInternalSession *RuntimeEditFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);if(!ctx)return nil;
    ctx.ownedTextSessionEnabled=NO;ctx.rangeTextEditDeltaDeliveryEnabled=NO;
    CJGuiInternalComposableSceneNode *field=ctx.composableNodes[0];
    CjguiInternalRendererComposableNode raw=field.node;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;raw.isInteractive=1;
    field.node=raw;field.value=@"Draft42";
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.composableNodes];
    if(![ctx.composableSceneOverlay focusCommittedNodeId:401])return nil;
    ctx.composableSceneOverlay.inputProxy.selectedRange=NSMakeRange(1,3);
    [ctx.pendingInteractions removeAllObjects];return ctx;
}
static void CheckRuntimeInputRetirement(id<MTLDevice> device,NSUInteger change) {
    CJGuiInternalSession *ctx=RuntimeEditFixture(device);CHECK(ctx!=nil,"runtime_input_fixture");if(!ctx)return;
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    CHECK(o.activeNodeId==401 && o.activeNodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
        NSEqualRanges(o.inputProxy.selectedRange,NSMakeRange(1,3)),"real_input_source_and_selection_established");
    NSMutableArray *next=[NSMutableArray array];
    for(NSUInteger i=0;i<ctx.composableNodes.count;i++) {
        CJGuiInternalComposableSceneNode *node=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[i],(uint32_t)i,2);
        [next addObject:node];
    }
    CJGuiInternalComposableSceneNode *field=next[0];
    CjguiInternalRendererComposableNode raw=field.node;
    if(change==0)raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT;
    if(change==1)raw.isInteractive=0;
    if(change==2)raw.resourceId=2;
    field.node=raw;
    if(change==3)[next removeObjectAtIndex:0];
    ctx.composableNodes=next;ctx.view.composableNodes=next;ctx.composableSceneVersion=2;
    [o setNodesFromProjection:next];
    CHECK(o.activeNodeId!=401,"type_disable_rebind_or_delete_retires_old_input");
    [ctx.pendingInteractions removeAllObjects];
    [o.inputProxy insertText:@"7" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(ctx.pendingInteractions.count==0,"retired_proxy_cannot_emit_successor_for_new_object");
    CHECK(change==3 || [field.value isEqualToString:@"Draft42"],"retirement_never_changes_declared_value");
    if(change<3) {
        raw=field.node;raw.isInteractive=1;field.node=raw;
        [o setNodesFromProjection:next];
        CHECK([o focusCommittedNodeId:401] && o.activeNodeKind==field.node.nodeKind &&
            o.activeNodeResourceId==field.node.resourceId,"explicit_new_selection_can_focus_current_binding");
    }
    fprintf(stderr,"runtime_edit_retirement variant=%lu failures=%d\n",(unsigned long)change,failures);
    CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
}
int main(void) {@autoreleasepool {
    [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 2;
    for(NSUInteger change=0;change<4;change++)CheckRuntimeInputRetirement(device,change);
    return failures?1:0;
}}
