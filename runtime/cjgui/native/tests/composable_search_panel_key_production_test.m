// Scoped picker keys use the existing command FIFO; marked text owns its keys.
#define CJGUI_COMMAND_SOURCE_NO_MAIN 1
#import "composable_command_source_production_test.m"

static NSEvent *PanelKey(unsigned short code, NSString *text) {
    return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:1 windowNumber:0 context:nil characters:text
        charactersIgnoringModifiers:text isARepeat:NO keyCode:code];
}

int main(void) {
    @autoreleasepool {
        CHECK([CjguiComposableShortcutForEvent(PanelKey(36,@"\r")) isEqualToString:@"shortcut:enter"],
            "search_panel_plain_enter_normalized");
        CHECK([CjguiComposableShortcutForEvent(PanelKey(53,@"\033")) isEqualToString:@"shortcut:escape"],
            "search_panel_plain_escape_normalized");
        CHECK([CjguiComposableShortcutForEvent(PanelKey(126,@"\uf700")) isEqualToString:@"shortcut:up"],
            "search_panel_plain_up_normalized");
        CHECK([CjguiComposableShortcutForEvent(PanelKey(125,@"\uf701")) isEqualToString:@"shortcut:down"],
            "search_panel_plain_down_normalized");
        CHECK(CjguiComposableShortcutForEvent(PanelKey(0,@"a"))==nil,
            "search_panel_printable_input_not_a_shortcut");
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        if(!device)return 77;
        CJGuiInternalSession *ctx=ProductionFixture(device);
        CHECK(ctx!=nil,"search_panel_real_input_proxy_created");
        if(ctx) {
            for(CJGuiInternalComposableSceneNode *node in ctx.composableSceneOverlay.nodes) {
                CjguiInternalRendererComposableNode raw=node.node;raw.inputScope=7;node.node=raw;
            }
            CHECK(CjguiConfigureComposableCommandMenuOnMain(ctx.rendererSessionToken,1,2)==0 &&
                CjguiSetComposableCommandMenuItemOnMain(ctx.rendererSessionToken,0,"panel-enter","Confirm",
                    "","shortcut:enter",0,7,1,0)==0 &&
                CjguiSetComposableCommandMenuItemOnMain(ctx.rendererSessionToken,1,"panel-escape","Cancel",
                    "","shortcut:escape",0,7,1,0)==0 &&
                CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,
                "search_panel_scoped_commands_committed");
            CHECK(CjguiComposableActiveScopeDeclaresShortcut(ctx,@"shortcut:enter"),
                "search_panel_key_matches_actual_focused_scope");
            [ctx.composableSceneOverlay.inputHost setMarkedText:@"候" selectedRange:NSMakeRange(1,0)
                replacementRange:NSMakeRange(NSNotFound,0)];
            CHECK(ctx.composableSceneOverlay.inputProxy.hasMarkedText,"search_panel_real_marked_text_active");
            NSUInteger before=ctx.pendingInteractions.count;
            CHECK(![ctx.composableSceneOverlay handleWindowCommandKeyDown:PanelKey(36,@"\r")] &&
                ![ctx.composableSceneOverlay handleWindowCommandKeyDown:PanelKey(53,@"\033")] &&
                ctx.pendingInteractions.count==before,"search_panel_marked_enter_escape_stay_with_system_input");
            CjguiReleaseSession(ctx.rendererSessionToken);
        }
        fprintf(stderr,"search_panel_keys failures=%d\n",failures);
        return failures?1:0;
    }
}
