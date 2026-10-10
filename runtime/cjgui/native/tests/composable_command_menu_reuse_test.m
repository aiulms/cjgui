// Headless normal menu projection/dispatch counterexamples. No foreground input.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
@interface MenuProjectionApp : NSApplication
@property(nonatomic,strong) NSWindow *fixtureKey;
@end
@implementation MenuProjectionApp
- (NSWindow *)keyWindow { return self.fixtureKey; }
@end
@interface MenuProjectionOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic,strong) CJGuiInternalComposableSceneNode *fixtureActive;
@end
@implementation MenuProjectionOverlay
- (CJGuiInternalComposableSceneNode *)activeFocusableNode { return self.fixtureActive; }
@end
static int failures=0, checks=0;
#define CHECK(x,n) do { checks++; if(!(x)) { failures++; fprintf(stderr,"FAIL %s\n",n); } } while(0)
static NSMenuItem *command(void) {
    for(NSMenuItem *group in NSApp.mainMenu.itemArray)
        for(NSMenuItem *item in group.submenu.itemArray)
            if([item.representedObject isEqual:@"fixture-command"]) return item;
    return nil;
}
int main(void) { @autoreleasepool {
    MenuProjectionApp *app=[MenuProjectionApp sharedApplication];
    NSWindow *window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,400,300)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.window=window; ctx.pendingInteractions=[NSMutableArray array];
    ctx.composableSceneVersion=1; ctx.sessionGeneration=7;
    CJGuiInternalComposableSceneNode *root=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode rootRaw={0};rootRaw.nodeId=1;rootRaw.nodeKind=4;
    root.node=rootRaw;ctx.composableNodes=[NSMutableArray arrayWithObject:root];
    ctx.composableCommandMenuItems=[NSMutableArray array];
    CJGuiInternalComposableCommandMenuItem *entry=[CJGuiInternalComposableCommandMenuItem new];
    entry.commandId=@"fixture-command";entry.title=@"Fixture";entry.menuGroup=@"File";
    entry.shortcut=@"shortcut:command+s";entry.enabled=YES;
    [ctx.composableCommandMenuItems addObject:entry];
    objc_setAssociatedObject(window,&CJGuiSessionWindowAssociationKey,ctx,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    app.fixtureKey=window;
    CjguiRebuildComposableCommandMenuForKeyWindow();
    NSMenu *first=app.mainMenu; NSMenuItem *old=command();
    CHECK(old && old.enabled,"real_menu_built");
    ctx.composableSceneVersion=2;
    CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu==first,"unchanged_projection_reuses_actual_menu_across_body_version");
    entry.enabled=NO; CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu!=first && !command().enabled,"enabled_change_installs_new_projection");
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]invokeComposableCommand:old];
    CHECK(ctx.pendingInteractions.count==0,"old_item_cannot_invoke_disabled_current_command");
    entry.enabled=YES;ctx.composableSceneVersion=3;CjguiRebuildComposableCommandMenuForKeyWindow();
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]invokeComposableCommand:old];
    CHECK(ctx.pendingInteractions.count==1 && ctx.pendingInteractions[0].projectionVersion==3 &&
        [ctx.pendingInteractions[0].formText isEqual:@"fixture-command"],"cached_item_dispatch_uses_actual_current_owner_projection");
    NSMenu *before=app.mainMenu;entry.checked=YES;CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu!=before && command().state==NSControlStateValueOn,"checked_change_visible");
    before=app.mainMenu;entry.title=@"Changed";entry.menuSection=2;entry.shortcut=@"shortcut:command+r";
    CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu!=before && [command().title isEqual:@"Changed"] && [command().keyEquivalent isEqual:@"r"],"presentation_fields_change_visible");
    MenuProjectionOverlay *overlay=[[MenuProjectionOverlay alloc]initWithFrame:NSMakeRect(0,0,400,300)session:ctx];
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};raw.nodeId=100;raw.nodeKind=4;raw.inputScope=9;
    node.node=raw;overlay.fixtureActive=node;ctx.composableSceneOverlay=overlay;
    before=app.mainMenu;CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu!=before && !command().enabled,"actual_focused_scope_change_invalidates_projection");
    NSUInteger queued=ctx.pendingInteractions.count;
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]invokeComposableCommand:old];
    CHECK(ctx.pendingInteractions.count==queued,"old_menu_item_refused_in_new_scope");
    before=app.mainMenu;ctx.sessionGeneration++;CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu!=before,"session_generation_change_invalidates_menu_owner");
    NSMenu *foreign=[[NSMenu alloc]initWithTitle:@"foreign"];[app setMainMenu:foreign];
    CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(app.mainMenu!=foreign && command()!=nil,"external_main_menu_replacement_cannot_hit_cache");
    entry.shortcut=@"shortcut:command+z";
    overlay.fixtureActive=nil;
    ctx.composableSceneVersion=4;
    NSEvent *undo=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:NSEventModifierFlagCommand timestamp:0 windowNumber:window.windowNumber
        context:nil characters:@"z" charactersIgnoringModifiers:@"z" isARepeat:NO keyCode:6];
    [ctx.pendingInteractions removeAllObjects];
    CHECK([overlay performKeyEquivalent:undo],"declared_undo_owns_chord_without_text_focus");
    CHECK(ctx.pendingInteractions.count==1 && ctx.pendingInteractions[0].kind==34 &&
        ctx.pendingInteractions[0].projectionVersion==4 &&
        [ctx.pendingInteractions[0].formText isEqual:@"shortcut:command+z"],
        "declared_undo_reaches_current_command_once_after_body_disappears");
    [ctx.pendingInteractions removeAllObjects];
    entry.enabled=NO;
    CHECK([overlay performKeyEquivalent:undo] && ctx.pendingInteractions.count==1 &&
        ctx.pendingInteractions[0].kind==34,"disabled_undo_keeps_owner_chord_for_cangjie_refusal");
    [ctx.pendingInteractions removeAllObjects];
    overlay.fixtureActive=node;
    CHECK(![overlay handleWindowCommandKeyDown:undo] && ctx.pendingInteractions.count==0,
        "different_focused_scope_cannot_bypass_declared_command");
    app.fixtureKey=nil;CjguiRebuildComposableCommandMenuForKeyWindow();
    CHECK(command()==nil,"no_key_owner_drops_its_commands");
    printf("COMMAND_MENU_REUSE checks=%d failures=%d physical_input=false\n",checks,failures);
    return failures ? 1 : 0;
} }
