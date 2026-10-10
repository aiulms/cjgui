// Controlled waits classify a call boundary, not a production performance pass.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

@interface CjguiDelayedDrawableLayer : CAMetalLayer
@end
@implementation CjguiDelayedDrawableLayer
- (id<CAMetalDrawable>)nextDrawable { usleep(40000); return nil; }
@end
@interface CjguiDelayedBufferQueue : NSObject
@property(nonatomic,strong) id<MTLCommandQueue> queue;
@end
@implementation CjguiDelayedBufferQueue
- (id<MTLCommandBuffer>)commandBuffer { usleep(20000); return [self.queue commandBuffer]; }
@end

static int failures;
#define CHECK(c,label) do { BOOL ok=(c); fprintf(stderr,"frame_attribution case=%s result=%s\n",label,ok?"PASS":"FAIL"); if(!ok)++failures; } while(0)

static uint64_t CompleteCall(uint64_t session,uint64_t turn,uint32_t phase,uint64_t tid) {
    uint64_t tail=atomic_load(&gCjguiOwnerTraceNextSequence);
    CjguiOwnerTraceRecord *begin=NULL,*end=NULL;
    for(uint64_t i=1;i<=tail;i++) {
        CjguiOwnerTraceRecord *r=&gCjguiOwnerTraceRecords[(i-1)%CJGUI_OWNER_TRACE_CAPACITY];
        if(r->sequence!=i || r->session!=session || r->turn!=turn || r->phase!=phase)continue;
        if(r->kind==CJGUI_OWNER_TRACE_PHASE_BEGIN)begin=r;
        if(r->kind==CJGUI_OWNER_TRACE_PHASE_END)end=r;
    }
    if(!begin || !end || end->span!=begin->sequence || begin->threadId!=tid || end->threadId!=tid ||
       begin->generation!=end->generation || !begin->generation || end->monoNs<begin->monoNs) return 0;
    fprintf(stderr,"FRAME_CALL phase=%s turn=%llu tid=%llu wall_ns=%llu\n",CjguiOwnerTracePhaseName(phase),
        (unsigned long long)turn,(unsigned long long)tid,(unsigned long long)(end->monoNs-begin->monoNs));
    return end->monoNs-begin->monoNs;
}

int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE","1",1);
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(!device)return 1;
    id<MTLCommandQueue> queue=[device newCommandQueue];
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];ctx.app=NSApp;ctx.device=device;
    ctx.window=[[NSWindow alloc] initWithContentRect:NSMakeRect(40,80,320,220)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,320,220) device:device commandQueue:queue];
    ctx.window.contentView=ctx.view;
    uint64_t session=CjguiAllocateSession(ctx),tid=CjguiCurrentNativeThreadId();
    CjguiInternalRendererClearColor clear={.red=.2,.green=.3,.blue=.4,.alpha=1};
    CAMetalLayer *actual=ctx.view.metalLayer;
    ctx.view.metalLayer=[CjguiDelayedDrawableLayer layer];ctx.view.metalLayer.device=device;
    cjgui_internal_renderer_owner_trace_set_turn(777);
    CHECK(cjgui_internal_renderer_present_clear(session,&clear,NULL)==CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE,
        "controlled_drawable_refusal_is_not_success");
    CHECK(CompleteCall(session,777,371,tid)>=40000000,"drawable_wait_has_exact_os_thread_and_call_pair");
    CHECK(CompleteCall(session,777,372,tid)==0,"unreached_buffer_is_unknown_not_zero_cost");
    ctx.view.metalLayer=actual;
    [ctx.window orderFront:nil];
    CjguiDelayedBufferQueue *delayed=[CjguiDelayedBufferQueue new];delayed.queue=queue;
    ctx.view.commandQueue=(id<MTLCommandQueue>)delayed;
    cjgui_internal_renderer_owner_trace_set_turn(778);
    CHECK(cjgui_internal_renderer_present_clear(session,&clear,NULL)==0,"controlled_buffer_delay_real_submission");
    CHECK(CompleteCall(session,778,372,tid)>=20000000,"buffer_wait_distinct_from_drawable_wait");
    CHECK(CompleteCall(session,778,371,tid)>0 && CompleteCall(session,778,377,tid)>0 &&
        CompleteCall(session,778,378,tid)>0,"actual_acquire_commit_publication_separate_and_complete");
    [ctx.window orderOut:nil];CjguiReleaseSession(session);
    fprintf(stderr,"frame_attribution failures=%d\n",failures);
    return failures?1:0;
} }
