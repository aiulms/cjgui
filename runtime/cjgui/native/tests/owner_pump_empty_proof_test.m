// Real Main run loop/FIFO. Repeated zero-timeout reads of an unchanged empty
// queue must not manufacture Main requests; real work and retirement invalidate
// that fact. No hardware-input or latency claim is made by this probe.
#define CJGUI_OWNER_PUMP_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

static int failures;
static void check(BOOL ok,const char *message) {
    if (!ok) { failures++; fprintf(stderr,"EMPTY_PROOF FAIL: %s\n",message); }
}
static void mainBarrier(void (^work)(void)) {
    dispatch_sync(dispatch_get_main_queue(),work ?: ^{});
}
static uint64_t nextNonce(void) {
    pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
    uint64_t n=gCjguiOwnerPumpTicketNextNonce;
    pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    return n;
}
static void settleEmpty(uint64_t token) {
    CjguiInternalRendererEvent e={0};
    check(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK,
        "empty admission status");
    mainBarrier(nil);
    check(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK &&
        e.kind==CJGUI_INTERNAL_RENDERER_EVENT_NONE,"empty completion status");
}

int main(void) {
    @autoreleasepool {
        NSApplication *app=[NSApplication sharedApplication];
        CjguiInternalRendererConfig config={.windowWidth=360,.windowHeight=240};
        __block CjguiInternalRendererStatus status;
        __block uint64_t token=cjgui_internal_renderer_create(&config,&status);
        if(status!=CJGUI_INTERNAL_RENDERER_OK)return 2;
        cjgui_internal_renderer_enable_main_thread_dispatch();
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
            settleEmpty(token);
            uint64_t before=nextNonce();
            for(int i=0;i<20;i++) {
                CjguiInternalRendererEvent e={0};
                check(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK &&
                    e.kind==CJGUI_INTERNAL_RENDERER_EVENT_NONE,"unchanged empty result");
            }
            check(nextNonce()==before,"unchanged empty FIFO admitted another Main ticket");
            mainBarrier(^{
                CjguiEnqueueInteraction(CjguiLookupSession(token),
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT,71,@"fresh",0,0);
            });
            BOOL gotEvent=NO;
            for(int i=0;i<80 && !gotEvent;i++) {
                CjguiInternalRendererEvent e={0};
                check(cjgui_internal_renderer_pump_event(token,0,&e)==CJGUI_INTERNAL_RENDERER_OK,
                    "fresh enqueue status");
                gotEvent=e.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT;
                mainBarrier(nil);
            }
            check(gotEvent,"cached NONE hid a real same-generation FIFO event");
            settleEmpty(token);
            mainBarrier(^{
                CJGuiInternalSession *ctx=CjguiLookupSession(token);
                CjguiComposablePreparation *p=[CjguiComposablePreparation new];
                p.preparationId=17;
                p.nodes=[NSMutableArray array];
                for(int i=0;i<4;i++)[p.nodes addObject:[CJGuiInternalComposableSceneNode new]];
                ctx.composablePreparation=p;
                check(cjgui_internal_renderer_cancel_composable_preparation(token,17)==
                    CJGUI_INTERNAL_RENDERER_OK,"normal cancellation admission");
            });
            settleEmpty(token);
            before=nextNonce();
            CjguiInternalRendererEvent e={0};
            (void)cjgui_internal_renderer_pump_event(token,0,&e);
            check(nextNonce()>before,"cached NONE starved actual preparation retirement");
            mainBarrier(nil);
            mainBarrier(^{
                uint64_t old=token;
                check(cjgui_internal_renderer_destroy(old)==CJGUI_INTERNAL_RENDERER_OK,"retire old session");
                token=cjgui_internal_renderer_create(&config,&status);
                check(status==CJGUI_INTERNAL_RENDERER_OK && token==old,"reuse exact slot");
            });
            before=nextNonce();
            (void)cjgui_internal_renderer_pump_event(token,0,&e);
            check(nextNonce()>before,"new generation inherited an old empty proof");
            mainBarrier(^{
                check(cjgui_internal_renderer_destroy(token)==CJGUI_INTERNAL_RENDERER_OK,"normal final destroy");
                printf("EMPTY_PROOF failures=%d occupied=%u\n",failures,
                    cjgui_internal_renderer_occupied_session_count());
                cjgui_internal_renderer_request_application_stop();
            });
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(), ^{
            check(NO,"bounded run-loop watchdog");cjgui_internal_renderer_request_application_stop();
        });
        [app run];
        return failures?1:0;
    }
}
