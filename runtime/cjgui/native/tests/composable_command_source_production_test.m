// Real AppKit command enqueue and pump; no TESTING renderer or synthetic source.
#define main existingSelectionPaintCommandSourceMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

#ifndef CJGUI_INTERNAL_COMMAND_SOURCE_ABI
typedef struct CjguiInternalCommandSource {
    uint64_t originSerial, sessionGeneration, capturedScene, declarationToken, targetNodeId;
    int64_t targetResourceId;
    uint32_t targetNodeKind, isValid;
    uint64_t focusedNodeId;
    int64_t focusedResourceId;
    uint32_t focusedNodeKind, originEventKind;
    uint64_t bindingEpoch;
    int64_t ownerVersion;
} CjguiInternalCommandSource;
static CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_command_identity(
    uint64_t session,uint32_t index,uint64_t token,uint64_t node,int64_t resource,uint32_t kind) {
    (void)session;(void)index;(void)token;(void)node;(void)resource;(void)kind;
    return CJGUI_INTERNAL_RENDERER_OK;
}
static CjguiInternalRendererStatus cjgui_internal_renderer_owner_consumed_command_source(
    uint64_t session,CjguiInternalCommandSource *source) {
    (void)session;*source=(CjguiInternalCommandSource){0};return CJGUI_INTERNAL_RENDERER_OK;
}
#endif

static void PublishCommand(CJGuiInternalSession *ctx,uint64_t scene,BOOL enabled,uint64_t token) {
    CHECK(CjguiConfigureComposableCommandMenuOnMain(ctx.rendererSessionToken,scene,1)==0 &&
        CjguiSetComposableCommandMenuItemOnMain(ctx.rendererSessionToken,0,"source-shift","Source shift",
            "Edit","shortcut:shift+command+n",0,0,enabled,0)==0 &&
        cjgui_internal_renderer_set_composable_command_identity(ctx.rendererSessionToken,0,token,
            402,1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT)==0,
        "command_source_declared_identity_staged");
}

static void RealCommand(CJGuiInternalSession *ctx) {
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand|NSEventModifierFlagShift timestamp:1
        windowNumber:ctx.window.windowNumber context:nil characters:@"N"
        charactersIgnoringModifiers:@"n" isARepeat:NO keyCode:45];
    CHECK([ctx.composableSceneOverlay handleWindowCommandKeyDown:key] && ctx.pendingInteractions.count==1,
        "command_source_real_declared_keyboard_once");
}

static void CommandSourceFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx,1,4),"command_source_actual_installed_focus");
    if (!ctx || !ctx.installedRangeBasis.hasReceipt) return;
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
        basis.selectionTransferId,ctx.sessionGeneration,basis.candidate.bindingEpoch,
        basis.proxyGeneration,basis.selectionRevision,10,1,1,&needs)==0,
        "command_source_initial_install_completion_published");
    PublishCommand(ctx,1,YES,7001);
    CHECK(CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,"command_source_A_declared");
    RealCommand(ctx);
    CjguiInternalRendererEvent event={0};
    CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&event)==0 && event.kind==34 &&
        event.projectionVersion==1 && ctx.pendingInteractions.count==0,"command_source_actual_A_pumped_once");
    CjguiInternalCommandSource source={0};
    CjguiInternalRendererStatus read=cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&source);
    fprintf(stderr,"command_source_actual status=%u valid=%u serial=%llu scene=%llu token=%llu target=%llu focus=%llu binding=%llu owner=%lld kind=%u\n",
        read,source.isValid,(unsigned long long)source.originSerial,(unsigned long long)source.capturedScene,
        (unsigned long long)source.declarationToken,(unsigned long long)source.targetNodeId,
        (unsigned long long)source.focusedNodeId,(unsigned long long)source.bindingEpoch,
        (long long)source.ownerVersion,source.originEventKind);
    CHECK(read==0 &&
        source.isValid && source.originSerial && source.capturedScene==1 && source.declarationToken==7001 &&
        source.targetNodeId==402 && source.focusedNodeId==402 && source.bindingEpoch==basis.candidate.bindingEpoch &&
        source.ownerVersion==10 && source.originEventKind==34,
        "command_source_frozen_at_actual_producer_not_current_focus");

    // Submit a paint-only scene using the same real node payloads and command.
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];
    ctx.stagedComposableSceneVersion=2;ctx.stagedComposableDataTransferVersion=2;
    PublishCommand(ctx,2,YES,7001);
    CHECK(cjgui_internal_renderer_stage_window_background(ctx.rendererSessionToken,2,0,1)==0,
        "command_source_pure_paint_background");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(ctx.rendererSessionToken,&frame);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && ctx.composableSceneVersion==2,
        "command_source_pure_redraw_actually_published");
    CjguiInternalCommandSource after={0};
    CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&after)==0 &&
        after.isValid && after.originSerial==source.originSerial && after.capturedScene==1 &&
        event.projectionVersion==1,"command_source_pure_redraw_keeps_original_scene_and_source");

    PublishCommand(ctx,2,NO,7001);
    CHECK(CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0 &&
        cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&after)==0 &&
        !after.isValid,"command_source_disabled_declaration_cannot_reuse_origin");
    PublishCommand(ctx,2,YES,7001);
    CHECK(CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,
        "command_source_enabled_control_restored");
    [ctx.composableSceneOverlay focusCommittedNodeId:401];
    CHECK(cjgui_internal_renderer_owner_consumed_command_source(ctx.rendererSessionToken,&after)==0 &&
        !after.isValid,"command_source_unrelated_focus_cannot_reuse_origin");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

#ifndef CJGUI_COMMAND_SOURCE_NO_MAIN
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 77;
        CommandSourceFixture(device);
        fprintf(stderr,"command_source_production failures=%d\n",failures);
        return failures?1:0;
    }
}
#endif
