// The real Metal command buffer is gated before encoding. This discriminator
// identifies a GPU-completion wait without attributing unknown wall time to GC.
// Warm raster/pipeline resources do not remove the first diagnostic's wait.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

@interface CjguiReadbackGateQueue : NSObject
@property(nonatomic,strong) id<MTLCommandQueue> queue;
@property(nonatomic,strong) id<MTLSharedEvent> gate;
@property(nonatomic,assign) uint64_t nextValue;
@end
@implementation CjguiReadbackGateQueue
- (id<MTLCommandBuffer>)commandBuffer {
    id<MTLCommandBuffer> buffer=[self.queue commandBuffer];
    const uint64_t value=++self.nextValue;
    [buffer encodeWaitForEvent:self.gate value:value];
    id<MTLSharedEvent> gate=self.gate;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,50000000),
        dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            @synchronized(gate) { gate.signaledValue=MAX(gate.signaledValue,value); }
        });
    return buffer;
}
@end

static int failures;
#define CHECK(c,label) do { BOOL ok=(c); fprintf(stderr,"readback_nonblocking case=%s result=%s\n",label,ok?"PASS":"FAIL"); if(!ok)++failures; } while(0)

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    CHECK(device!=nil,"metal_device_available");
    if(!device)return 1;
    id<MTLCommandQueue> queue=[device newCommandQueue];
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.app=NSApp;ctx.device=device;
    ctx.window=[[NSWindow alloc] initWithContentRect:NSMakeRect(60,90,320,220)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    ctx.window.title=@"CJGUI E · 首帧归因";
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,320,220)
        device:device commandQueue:queue];
    ctx.window.contentView=ctx.view;
    uint64_t session=CjguiAllocateSession(ctx);
    [ctx.window orderFront:nil];
    CjguiInternalRendererClearColor clear={.red=0.2,.green=0.4,.blue=0.6,.alpha=1};
    CjguiInternalRendererFrameObservation warm={0};
    CHECK(cjgui_internal_renderer_present_clear(session,&clear,&warm)==0,
        "actual_renderer_warm_submission");
    for(NSUInteger i=0;i<1000 && (!ctx.view.readbackProbeCompleted || ctx.observedMetalCompletionFrameIndex<warm.frameIndex);++i)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    ctx.view.readbackProbeCompleted=NO;
    CjguiReadbackGateQueue *gate=[CjguiReadbackGateQueue new];
    gate.queue=queue;gate.gate=[device newSharedEvent];
    ctx.view.commandQueue=(id<MTLCommandQueue>)gate;
    CjguiInternalRendererFrameObservation observed={0};
    uint64_t started=cjgui_internal_renderer_owner_clock_ns();
    CjguiInternalRendererStatus status=cjgui_internal_renderer_present_clear(session,&clear,&observed);
    uint64_t elapsed=cjgui_internal_renderer_owner_clock_ns()-started;
    fprintf(stderr,"READBACK_GATE wall_ns=%llu injected_gpu_gate_ns=50000000 frame=%llu attempted=%u completed=%u matched=%u\n",
        (unsigned long long)elapsed,(unsigned long long)observed.frameIndex,
        observed.readbackAttempted,observed.readbackCompleted,observed.readbackColorMatched);
    CHECK(status==0,"submission_status_does_not_claim_gpu_completion");
    CHECK(elapsed<16000000,"owner_not_blocked_by_gpu_completion");
    CHECK(observed.readbackAttempted==1 && observed.readbackCompleted==0 &&
        observed.readbackColorMatched==0,"return_does_not_forge_pixel_or_completion");
    id pending=ctx.view.readbackProbeTask;
    CjguiInternalRendererFrameObservation concurrent={0};
    CHECK(cjgui_internal_renderer_present_clear(session,&clear,&concurrent)==0 &&
        concurrent.readbackAttempted==0 && ctx.view.readbackProbeTask==pending,
        "one_probe_while_previous_gpu_submission_pending");
    for(NSUInteger i=0;i<1000 && (!ctx.view.readbackProbeCompleted ||
        ctx.observedMetalCompletionFrameIndex<observed.frameIndex);++i)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    CHECK(ctx.view.readbackProbeCompleted && ctx.observedMetalCompletionFrameIndex>=observed.frameIndex,
        "actual_delayed_completion_remains_observed");
    CHECK(ctx.view.readbackProbeColorMatched,"actual_delayed_pixel_matches_frozen_clear");

    // Invalidate the actual publication identity while its real Metal work
    // is still pending. Its own retirement must not certify the new image.
    ctx.view.readbackProbeCompleted=NO;
    ctx.view.readbackProbeColorMatched=NO;
    CjguiInternalRendererFrameObservation stale={0};
    CHECK(cjgui_internal_renderer_present_clear(session,&clear,&stale)==0,
        "stale_probe_actual_submission");
    ctx.view.readbackProbeImageTag=[NSObject new];
    for(NSUInteger i=0;i<1000 && ctx.view.readbackProbeTask;++i)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    CHECK(!ctx.view.readbackProbeTask && !ctx.view.readbackProbeCompleted &&
        !ctx.view.readbackProbeColorMatched,"stale_image_cannot_publish_new_pixel_identity");
    CjguiInternalRendererFrameObservation closing={0};
    CHECK(cjgui_internal_renderer_present_clear(session,&clear,&closing)==0,
        "closing_probe_actual_submission");
    const uint64_t retiredGeneration=ctx.sessionGeneration;
    [ctx.window orderOut:nil];
    CjguiReleaseSession(session);
    CJGuiInternalSession *replacement=[CJGuiInternalSession new];
    replacement.app=NSApp;replacement.device=device;
    replacement.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,320,220)
        device:device commandQueue:queue];
    uint64_t replacementToken=CjguiAllocateSession(replacement);
    CHECK(replacementToken==session && replacement.sessionGeneration!=retiredGeneration,
        "actual_slot_reuse_has_new_session_identity");
    for(NSUInteger i=0;i<1000 && gate.gate.signaledValue<gate.nextValue;++i)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
            beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
        beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    CHECK(!replacement.view.readbackProbeCompleted && !replacement.view.readbackProbeTask &&
        !replacement.view.readbackProbeColorMatched && replacement.observedMetalCompletionFrameIndex==0,
        "retired_completion_cannot_mutate_reused_session");
    CjguiReleaseSession(replacementToken);
    fprintf(stderr,"readback_nonblocking failures=%d\n",failures);
    return failures?1:0;
} }
