// Real AppKit menu-DOWN source capture, callback, pure-paint, and pump seam.
// This does not synthesize CGEvent or run native menu tracking.
#define CJGUI_COMMAND_SOURCE_NO_MAIN 1
#import "composable_command_source_production_test.m"

#ifndef CJGUI_INTERNAL_MENU_SOURCE_CAPTURE
static void CjguiCaptureComposableMenuCommandSources(NSMenu *menu, NSEvent *event) {
    (void)menu;
    (void)event;
}
#endif

static NSMenu *EditCommandMenu(void) {
    for (NSMenuItem *group in NSApp.mainMenu.itemArray) {
        if ([group.title isEqualToString:@"Edit"]) return group.submenu;
    }
    return nil;
}

static NSMenuItem *SourceShiftItem(NSMenu *menu) {
    for (NSMenuItem *item in menu.itemArray) {
        if ([item.representedObject isEqual:@"source-shift"]) return item;
    }
    return nil;
}

static BOOL WaitForActualKeyWindow(CJGuiInternalSession *ctx) {
    __block BOOL appBecameActive=NSApp.isActive;
    __block BOOL windowBecameKey=ctx.window.isKeyWindow;
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    id activeObserver=[center addObserverForName:NSApplicationDidBecomeActiveNotification
        object:ctx.app queue:nil usingBlock:^(NSNotification *note) {
            (void)note;
            appBecameActive=YES;
        }];
    id keyObserver=[center addObserverForName:NSWindowDidBecomeKeyNotification
        object:ctx.window queue:nil usingBlock:^(NSNotification *note) {
            (void)note;
            windowBecameKey=YES;
        }];

    // Match the normal native host's real AppKit activation request. The
    // bounded nested runloop below is test-only: unlike the application host,
    // this executable does not own NSApplication's long-running run loop.
    [NSApp activateIgnoringOtherApps:YES];
    [ctx.window makeKeyAndOrderFront:nil];
    [ctx.window makeKeyWindow];
    [NSApp updateWindows];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:1.0];
    while ((!appBecameActive || !windowBecameKey || NSApp.keyWindow!=ctx.window) &&
        deadline.timeIntervalSinceNow>0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:deadline];
    }
    [center removeObserver:activeObserver];
    [center removeObserver:keyObserver];
    return appBecameActive && windowBecameKey && NSApp.isActive &&
        ctx.window.isKeyWindow && NSApp.keyWindow==ctx.window;
}

static void PrepareRealKeyWindow(CJGuiInternalSession *ctx) {
    ctx.window.styleMask = NSWindowStyleMaskTitled;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp finishLaunching];
    objc_setAssociatedObject(ctx.window, &CJGuiSessionWindowAssociationKey,
        ctx, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    BOOL keyReady=WaitForActualKeyWindow(ctx);
    CjguiRebuildComposableCommandMenuForKeyWindow();
    fprintf(stderr,"menu_source_key_actual key=%u active=%u canKey=%u associated=%u focus=%llu kind=%u menuItems=%ld runloop_ready=%u\n",
        NSApp.keyWindow==ctx.window,NSApp.isActive,ctx.window.canBecomeKeyWindow,
        objc_getAssociatedObject(NSApp.keyWindow,&CJGuiSessionWindowAssociationKey)==ctx,
        (unsigned long long)ctx.composableSceneOverlay.activeNodeId,ctx.composableSceneOverlay.activeNodeKind,
        (long)NSApp.mainMenu.numberOfItems,keyReady);
    CHECK(keyReady && objc_getAssociatedObject(NSApp.keyWindow,
        &CJGuiSessionWindowAssociationKey)==ctx,
        "menu_source_fixture_really_owns_key_window_after_main_runloop");
}

static NSEvent *RealMenuDown(CJGuiInternalSession *ctx) {
    return [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
        location:NSMakePoint(12, 12) modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime
        windowNumber:ctx.window.windowNumber context:nil eventNumber:1
        clickCount:1 pressure:1.0];
}

static NSMenuItem *CaptureSourceShift(CJGuiInternalSession *ctx) {
    NSMenu *menu=EditCommandMenu();
    NSEvent *down=RealMenuDown(ctx);
    CHECK(menu!=nil && down!=nil && down.type==NSEventTypeLeftMouseDown &&
        down.windowNumber==ctx.window.windowNumber,"menu_source_real_owned_window_DOWN_fixture");
    NSMenuItem *sender=SourceShiftItem(menu);
    CHECK(sender!=nil && sender.enabled,"menu_source_actual_declared_sender_available");
    CjguiCaptureComposableMenuCommandSources(menu,down);
    return sender;
}

static CJGuiInternalSession *InstalledMenuFixture(id<MTLDevice> device,uint64_t token) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"menu_source_production_fixture_allocated");
    if (!ctx) return nil;
    CHECK(InstallSelectionOnSameAcceptedScene(ctx,1,4),
        "menu_source_actual_selection_A_installed");
    if (!ctx.installedRangeBasis.hasReceipt) return ctx;
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;
    uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(
        ctx.rendererSessionToken,basis.selectionTransferId,ctx.sessionGeneration,
        basis.candidate.bindingEpoch,basis.proxyGeneration,basis.selectionRevision,
        10,1,1,&needs)==0,"menu_source_installed_A_completion_published");
    PublishCommand(ctx,1,YES,token);
    CHECK(CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,
        "menu_source_original_scene_command_published");
    PrepareRealKeyWindow(ctx);
    return ctx;
}

static void PresentPurePaintScene2(CJGuiInternalSession *ctx) {
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView
        positioned:NSWindowBelow relativeTo:nil];
    ctx.stagedComposableNodes=[ctx.composableNodes mutableCopy];
    ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferVersion=2;
    PublishCommand(ctx,2,YES,7001);
    CHECK(cjgui_internal_renderer_stage_window_background(ctx.rendererSessionToken,2,0,1)==0,
        "menu_source_pure_paint_scene2_staged");
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus status=CjguiPresentComposableSceneOnMain(
        ctx.rendererSessionToken,&frame);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        ctx.composableSceneVersion==2,"menu_source_actual_paint2_published");
}

static void ReleaseMenuFixture(CJGuiInternalSession *ctx) {
    if (!ctx) return;
    objc_setAssociatedObject(ctx.window,&CJGuiSessionWindowAssociationKey,nil,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CjguiReleaseSession(ctx.rendererSessionToken);
    [ctx.window orderOut:nil];
}

static void ValidCapturedMenuSource(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=InstalledMenuFixture(device,7001);
    if (!ctx || !ctx.installedRangeBasis.hasReceipt) return;
    NSMenuItem *sender=CaptureSourceShift(ctx);
    CjguiComposableMenuCommandOrigin *origin=objc_getAssociatedObject(
        sender,&CJGuiMenuCommandOriginAssociationKey);
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;
    PresentPurePaintScene2(ctx);
    CHECK(origin!=nil && origin.valid && origin.interaction.commandSource.isValid &&
        origin.interaction.commandSource.capturedScene==1 &&
        origin.interaction.commandSource.declarationToken==7001 &&
        SourceShiftItem(EditCommandMenu())==sender,
        "menu_source_pure_paint_preserves_original_sender_marker_and_scene1");
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]
        invokeComposableCommand:sender];
    CjguiInternalRendererEvent event={0};
    CjguiInternalRendererStatus pumped=cjgui_internal_renderer_pump_event(
        ctx.rendererSessionToken,0,&event);
    CjguiInternalCommandSource source={0};
    CjguiInternalRendererStatus read=cjgui_internal_renderer_owner_consumed_command_source(
        ctx.rendererSessionToken,&source);
    fprintf(stderr,"menu_source callback pump=%u kind=%u eventScene=%llu sourceStatus=%u "
        "valid=%u serial=%llu capturedScene=%llu token=%llu target=%llu focus=%llu "
        "binding=%llu owner=%lld origin=%u\n",pumped,event.kind,
        (unsigned long long)event.projectionVersion,read,source.isValid,
        (unsigned long long)source.originSerial,(unsigned long long)source.capturedScene,
        (unsigned long long)source.declarationToken,(unsigned long long)source.targetNodeId,
        (unsigned long long)source.focusedNodeId,(unsigned long long)source.bindingEpoch,
        (long long)source.ownerVersion,source.originEventKind);
    CHECK(pumped==0 && event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_MENU_COMMAND &&
        event.projectionVersion==1 && ctx.pendingInteractions.count==0,
        "menu_source_actual_callback_and_FIFO_preserve_origin_event_scene");
    CHECK(read==0 && source.isValid && source.originSerial && source.capturedScene==1 &&
        source.declarationToken==7001 && source.targetNodeId==402 &&
        source.focusedNodeId==402 && source.bindingEpoch==basis.candidate.bindingEpoch &&
        source.ownerVersion==10 &&
        source.originEventKind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_MENU_COMMAND,
        "menu_source_DOWN_identity_survives_paint2_and_real_callback_pump");
    ReleaseMenuFixture(ctx);
}

static void DisabledAfterCaptureRejects(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=InstalledMenuFixture(device,7201);
    if (!ctx) return;
    NSMenuItem *sender=CaptureSourceShift(ctx);
    PublishCommand(ctx,1,NO,7201);
    CHECK(CjguiCommitComposableCommandMenuOnMain(ctx.rendererSessionToken)==0,
        "menu_source_disabled_control_published_after_DOWN");
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]
        invokeComposableCommand:sender];
    CHECK(ctx.pendingInteractions.count==0,
        "menu_source_disabled_declaration_invalidates_captured_sender");
    ReleaseMenuFixture(ctx);
}

static void NewFocusAfterCaptureRejects(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=InstalledMenuFixture(device,7301);
    if (!ctx) return;
    NSMenuItem *sender=CaptureSourceShift(ctx);
    CjguiComposableMenuCommandOrigin *origin=objc_getAssociatedObject(
        sender,&CJGuiMenuCommandOriginAssociationKey);
    CHECK(origin!=nil && origin.valid && origin.interaction.commandSource.isValid &&
        origin.interaction.commandSource.focusedNodeId==402,
        "menu_source_original_focus_is_frozen_before_change");
    CHECK([ctx.composableSceneOverlay focusCommittedNodeId:403],
        "menu_source_focus_change_after_DOWN_is_real");
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]
        invokeComposableCommand:sender];
    CHECK(ctx.pendingInteractions.count==0,
        "menu_source_original_focus_proof_is_invalid_after_new_focus");
    ReleaseMenuFixture(ctx);
}

static void AnotherKeyWindowDoesNotReceiveLateSender(id<MTLDevice> device) {
    CJGuiInternalSession *first=InstalledMenuFixture(device,7401);
    if (!first) return;
    NSMenuItem *sender=CaptureSourceShift(first);
    CJGuiInternalSession *second=InstalledMenuFixture(device,7402);
    if (!second) { ReleaseMenuFixture(first); return; }
    // Keep the same declared id in the new owner: the old sender must not be
    // rebound to the new window merely because that window happens to match.
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]
        invokeComposableCommand:sender];
    CjguiInternalCommandSource secondSource={0};
    CHECK(NSApp.keyWindow==second.window && first.pendingInteractions.count==0 &&
        second.pendingInteractions.count==0 &&
        cjgui_internal_renderer_owner_consumed_command_source(
            second.rendererSessionToken,&secondSource)==0 && !secondSource.isValid,
        "menu_source_late_sender_cannot_redirect_to_another_owned_key_window");
    ReleaseMenuFixture(second);
    ReleaseMenuFixture(first);
}

static void CancelledMenuRetiresSourceBeforeLateCallback(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=InstalledMenuFixture(device,7501);
    if (!ctx) return;
    NSMenuItem *sender=CaptureSourceShift(ctx);
    CjguiComposableMenuCommandOrigin *origin=objc_getAssociatedObject(
        sender,&CJGuiMenuCommandOriginAssociationKey);
    NSMenu *menu=EditCommandMenu();
    CHECK(origin!=nil && origin.valid && menu!=nil,
        "menu_source_cancel_fixture_has_real_menu_origin_marker");
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher] menuDidClose:menu];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:0.5];
    while (origin.valid && deadline.timeIntervalSinceNow>0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:deadline];
    }
    CHECK(!origin.valid && origin.interaction==nil,
        "menu_source_cancelled_close_retires_marker_on_main_runloop");
    [[CJGuiInternalComposableCommandMenuDispatcher sharedDispatcher]
        invokeComposableCommand:sender];
    CHECK(ctx.pendingInteractions.count==0,
        "menu_source_callback_after_cancelled_close_is_rejected");
    ReleaseMenuFixture(ctx);
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        if (!device) return 77;
        NSApplication *app=[NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        // These tests require an actual key window, just as a menu callback
        // does in the normal host. Execute within NSApplication's real loop;
        // a bare nested NSRunLoop does not finish the application's startup.
        [NSTimer scheduledTimerWithTimeInterval:0 repeats:NO block:^(NSTimer *timer) {
            (void)timer;
            ValidCapturedMenuSource(device);
            DisabledAfterCaptureRejects(device);
            NewFocusAfterCaptureRejects(device);
            AnotherKeyWindowDoesNotReceiveLateSender(device);
            CancelledMenuRetiresSourceBeforeLateCallback(device);
            [app stop:nil];
            [app postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined
                location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0
                context:nil subtype:0 data1:0 data2:0] atStart:YES];
        }];
        [app run];
        fprintf(stderr,"menu_source_production failures=%d scope=native_DOWN_producer+callback+actualPresent+pump;menu_tracking=false;CGEvent=false\n",
            failures);
        return failures?1:0;
    }
}
