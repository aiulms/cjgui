// Native lifecycle contract; real fullscreen/Spaces is a separate normal-app check.
#define CJGUI_INTERNAL_TESTING 1
#define main previousWindowStateFixtureMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main
#undef CHECK
#define CHECK(c,n) do { BOOL ok=(c);fprintf(stderr,"window_state case=%s result=%s\n",n,ok?"PASS":"FAIL");if(!ok)failures++; } while(0)
@interface StateRestoreWindow : CJGuiInternalWindow
@end
@implementation StateRestoreWindow
- (instancetype)initWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style
    backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    return [super initWithContentRect:rect styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|
        NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable backing:backing defer:NO];
}
- (BOOL)canBecomeKeyWindow { return YES; }
@end
// Controlled transport check: count calls at the AppKit boundary without
// starting Spaces transitions. Real notifications/keyboard remain separate.
@interface StateCountingWindow : StateRestoreWindow
@property(nonatomic) NSUInteger fullScreenToggleCount;
@end
@implementation StateCountingWindow
- (void)toggleFullScreen:(id)sender { (void)sender; self.fullScreenToggleCount += 1; }
@end
static void CheckFullScreenRequestIdempotence(id<MTLDevice> device) {
    ProductionFixtureWindowClass=StateCountingWindow.class;
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"idempotence_fixture");if(!ctx)return;
    StateCountingWindow *window=(StateCountingWindow *)ctx.window;
    uint64_t token=ctx.rendererSessionToken,words[11]={0};
    CHECK(cjgui_internal_renderer_request_full_screen(token,0)==0 && window.fullScreenToggleCount==0,
        "already_windowed_request_has_no_appkit_toggle");
    CHECK(cjgui_internal_renderer_request_full_screen(token,1)==0 && window.fullScreenToggleCount==1,
        "first_enter_request_reaches_appkit_once");
    CHECK(cjgui_internal_renderer_request_full_screen(token,1)==0 && window.fullScreenToggleCount==1,
        "same_pending_request_is_idempotent");
    CHECK(cjgui_internal_renderer_request_full_screen(token,0)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        window.fullScreenToggleCount==1,"opposite_pending_request_cannot_queue_an_extra_toggle");
    [ctx windowWillEnterFullScreen:[NSNotification notificationWithName:NSWindowWillEnterFullScreenNotification object:window]];
    CHECK(cjgui_internal_renderer_request_full_screen(token,1)==0 && window.fullScreenToggleCount==1,
        "same_entering_request_is_idempotent");
    [ctx windowDidFailToEnterFullScreen:window];
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[7]==1 && !words[0] &&
        window.fullScreenToggleCount==1,"failure_is_reported_without_automatic_retry");
    CHECK(cjgui_internal_renderer_request_full_screen(token,0)==0 &&
        cjgui_internal_renderer_window_state(token,words)==0 && words[7]==1 && window.fullScreenToggleCount==1,
        "idempotent_request_does_not_erase_system_failure");
    CHECK(cjgui_internal_renderer_request_full_screen(token,1)==0 && window.fullScreenToggleCount==2,
        "explicit_new_attempt_dispatches_once");
    [ctx windowDidFailToExitFullScreen:window];
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[7]==2 && !words[0] &&
        window.fullScreenToggleCount==2,"exit_failure_keeps_actual_mask_and_never_toggles_again");
    CjguiReleaseSession(token);[window orderOut:nil];[window close];
}
static void CheckActualWindowRestore(id<MTLDevice> device) {
    ProductionFixtureWindowClass=StateRestoreWindow.class;
    CJGuiInternalSession *ctx=ProductionFixture(device);CHECK(ctx!=nil,"restore_fixture");if(!ctx)return;
    ((StateRestoreWindow *)ctx.window).cjguiSession=ctx;ctx.window.delegate=ctx;
    // The paint-only fixture keeps its Metal view detached. Activation is a
    // window operation and must use the real production host/view membership.
    NSView *host=[[NSView alloc] initWithFrame:ctx.composableSceneOverlay.frame];
    ctx.window.contentView=host;ctx.windowContentHost=host;
    [host addSubview:ctx.view];[host addSubview:ctx.composableSceneOverlay];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];[NSApp finishLaunching];
    (void)cjgui_internal_renderer_activate_window(ctx.rendererSessionToken);
    NSResponder *original=ctx.window.firstResponder;
    [ctx.window miniaturize:nil];
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:1.5];
    while(!ctx.window.isMiniaturized && end.timeIntervalSinceNow>0)
    {
        NSEvent *event=[NSApp nextEventMatchingMask:NSEventMaskAny
            untilDate:[NSDate dateWithTimeIntervalSinceNow:.01] inMode:NSDefaultRunLoopMode dequeue:YES];
        if(event)[NSApp sendEvent:event];
    }
    uint64_t words[11]={0};
    CHECK(ctx.window.isMiniaturized && cjgui_internal_renderer_window_state(ctx.rendererSessionToken,words)==0 && words[3],
        "actual_system_minimize_is_published");
    BOOL ax=[ctx.window accessibilityPerformRaise];
    fprintf(stderr,"window_restore observation=ax_raise returned=%d minimized=%d key=%d app_active=%d\n",
        ax,ctx.window.isMiniaturized,ctx.window.isKeyWindow,NSApp.isActive);
    CjguiInternalRendererStatus status=cjgui_internal_renderer_activate_window(ctx.rendererSessionToken);
    end=[NSDate dateWithTimeIntervalSinceNow:1.5];
    while((ctx.window.isMiniaturized || !ctx.window.isKeyWindow || !NSApp.isActive) && end.timeIntervalSinceNow>0)
    {
        NSEvent *event=[NSApp nextEventMatchingMask:NSEventMaskAny
            untilDate:[NSDate dateWithTimeIntervalSinceNow:.01] inMode:NSDefaultRunLoopMode dequeue:YES];
        if(event)[NSApp sendEvent:event];
    }
    CjguiInternalRendererStatus read=cjgui_internal_renderer_window_state(ctx.rendererSessionToken,words);
    fprintf(stderr,"window_restore observation=public_activate status=%d minimized=%d read=%d cached_minimized=%llu key=%d app_active=%d\n",
        status,ctx.window.isMiniaturized,read,(unsigned long long)words[3],ctx.window.isKeyWindow,NSApp.isActive);
    CHECK(status==0 && !ctx.window.isMiniaturized && read==0 && !words[3] &&
        ctx.window.isKeyWindow && NSApp.isActive,
        "existing_public_activation_really_restores_minimized_window");
    CHECK(ctx.window.firstResponder==original,"window_restore_keeps_original_responder_without_field_refocus");
    CjguiReleaseSession(ctx.rendererSessionToken);[ctx.window orderOut:nil];[ctx.window close];
}
int main(void) {@autoreleasepool {
    [NSApplication sharedApplication];id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 2;
#if defined(CJGUI_INTERNAL_RENDERER_WINDOW_STATE_VERSION)
    CJGuiInternalSession *ctx=ProductionFixture(device);CHECK(ctx!=nil,"fixture");if(!ctx)return 3;
    uint64_t words[11]={0};uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[0]==0 && words[1]==0,
        "windowed_actual_state_before_any_request");
    __block CjguiInternalRendererStatus workerStatus=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    __block uint64_t workerActual=UINT64_MAX;
    dispatch_semaphore_t workerDone=dispatch_semaphore_create(0);
    BOOL previousDispatch=gCjguiMainThreadDispatchEnabled;gCjguiMainThreadDispatchEnabled=NO;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        uint64_t copy[11]={0};workerStatus=cjgui_internal_renderer_window_state(token,copy);
        workerActual=copy[0];dispatch_semaphore_signal(workerDone);
    });
    CHECK(dispatch_semaphore_wait(workerDone,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC))==0 &&
        workerStatus==0 && workerActual==0,"owner_reads_published_actual_state_without_dispatching_to_main");
    gCjguiMainThreadDispatchEnabled=previousDispatch;
    uint64_t revision=words[2];
    [ctx windowWillEnterFullScreen:[NSNotification notificationWithName:NSWindowWillEnterFullScreenNotification object:[NSWindow new]]];
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[1]==0 && words[2]==revision,
        "foreign_window_notification_cannot_change_this_identity");
    NSNotification *note=[NSNotification notificationWithName:NSWindowWillEnterFullScreenNotification object:ctx.window];
    [ctx windowWillEnterFullScreen:note];
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[0]==0 && words[1]==1 && words[2]>revision,
        "will_enter_reports_transition_without_claiming_fullscreen");
    CHECK(cjgui_internal_renderer_request_full_screen(token,0)!=0,
        "opposite_request_during_real_transition_rejected");
    [ctx windowDidFailToEnterFullScreen:ctx.window];
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[0]==0 && words[1]==0 && words[7]==1,
        "system_failure_has_actual_windowed_state_and_named_reason");
    // A did notification is not itself proof of the fullscreen bit. This
    // controlled fixture remains windowed and must still read windowed.
    [ctx windowDidEnterFullScreen:note];
    CHECK(cjgui_internal_renderer_window_state(token,words)==0 && words[0]==0,
        "actual_style_mask_is_authority_not_requested_or_notification_name");
    CjguiReleaseSession(token);
    CHECK(cjgui_internal_renderer_window_state(token,words)!=0 &&
        cjgui_internal_renderer_request_full_screen(token,1)!=0,"retired_window_cannot_be_read_or_toggled");
#else
    CHECK(NO,"public_host_has_no_native_fullscreen_actual_state_transport");
#endif
    CheckFullScreenRequestIdempotence(device);
    CheckActualWindowRestore(device);
    fprintf(stderr,"window_state failures=%d\n",failures);return failures?1:0;
}}
