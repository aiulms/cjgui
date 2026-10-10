// Exercise the production dequeue and CString entry point. The reader must
// not need AppKit main to reinterpret an already frozen owner event payload.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

static int failures;
#define CHECK(c, label) do { BOOL ok=(c); fprintf(stderr,"form_text_snapshot case=%s result=%s\n",label,ok?"PASS":"FAIL"); if(!ok)++failures; } while(0)

static void PumpText(CJGuiInternalSession *ctx, NSString *text) {
    CJGuiInternalQueuedInteraction *event=[CJGuiInternalQueuedInteraction new];
    event.kind=CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE;
    event.formText=text;
    [ctx.pendingInteractions addObject:event];
    CjguiInternalRendererEvent out={0};
    CHECK(cjgui_internal_renderer_pump_event(ctx.rendererSessionToken,0,&out)==0 &&
        out.kind==event.kind,"actual_dequeue_publishes_this_event");
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    gCjguiMainThreadDispatchEnabled=YES;
    atomic_store_explicit(&gCjguiLauncherOwnsEventLoop,true,memory_order_release);
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.app=NSApp;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(token!=0,"fixture_has_real_session_generation");
    PumpText(ctx,@"down:仓颉🙂");
    dispatch_semaphore_t finished=dispatch_semaphore_create(0);
    __block NSString *read=nil;
    __block uint64_t elapsed=0;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        @autoreleasepool {
            uint64_t start=cjgui_internal_renderer_owner_clock_ns();
            read=[NSString stringWithUTF8String:cjgui_internal_renderer_form_event_text(token)];
            elapsed=cjgui_internal_renderer_owner_clock_ns()-start;
            dispatch_semaphore_signal(finished);
        }
    });
    // A deliberate main-unavailable discriminator, not an owner acceptance
    // budget. The old synchronous getter cannot complete during this gate.
    long waited=dispatch_semaphore_wait(finished,dispatch_time(DISPATCH_TIME_NOW,20000000));
    CHECK(waited==0,"frozen_payload_read_does_not_wait_for_main");
    if(waited!=0) {
        for(NSUInteger i=0;i<100 && !read;++i)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
        (void)dispatch_semaphore_wait(finished,dispatch_time(DISPATCH_TIME_NOW,1000000000));
    }
    CHECK([read isEqualToString:@"down:仓颉🙂"],"read_is_exact_dequeued_utf8");
    fprintf(stderr,"FORM_TEXT_READ wall_ns=%llu main_was_unavailable=1\n",(unsigned long long)elapsed);
    const char *borrowed=cjgui_internal_renderer_form_event_text(token);
    PumpText(ctx,@"up:B");
    CHECK(strcmp(borrowed,"down:仓颉🙂")==0,"borrow_survives_next_main_publication_until_next_getter");
    CHECK(strcmp(cjgui_internal_renderer_form_event_text(token),"up:B")==0,"next_getter_reads_next_pumped_event");
    uint64_t generation=ctx.sessionGeneration;
    CjguiReleaseSession(token);
    CHECK(strcmp(cjgui_internal_renderer_form_event_text(token),"")==0,"closed_session_never_returns_old_payload");
    CJGuiInternalSession *next=[CJGuiInternalSession new]; next.app=NSApp;
    uint64_t replacement=CjguiAllocateSession(next);
    CHECK(replacement==token && next.sessionGeneration!=generation &&
        strcmp(cjgui_internal_renderer_form_event_text(replacement),"")==0,"reused_slot_cannot_publish_old_generation");
    PumpText(next,@"fresh:C");
    CHECK(strcmp(cjgui_internal_renderer_form_event_text(replacement),"fresh:C")==0,"fresh_session_payload_reads_exactly");
    CjguiReleaseSession(replacement);
    fprintf(stderr,"form_text_snapshot failures=%d\n",failures);
    return failures?1:0;
} }
