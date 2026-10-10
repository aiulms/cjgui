// Bounded snapshot-cache probe. The legacy helper is an explicit control for
// the former dispatch_sync getter; the production call below must return the
// exact already-published scalar snapshot while AppKit's main queue is held.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdatomic.h>
#include <unistd.h>

static const uint64_t kWindowBackgroundBlockMicros = 60000;
static const uint64_t kWindowBackgroundFastLimitMicros = 12000;
static const uint64_t kWindowBackgroundWatchdogMicros = 3000000;

static _Atomic(bool) gWindowBackgroundBlockStarted = false;
static CJGuiInternalSession *ctx = nil;

// This control preserves the old getter's dispatch_sync semantics while using
// the same current scalar snapshot builder as the production main-thread path.
static CjguiInternalRendererStatus LegacyDispatchSyncSnapshot(
    uint64_t session, CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot) {
    if (!outSnapshot) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outSnapshot, 0, sizeof(*outSnapshot));
    if (CjguiIsMainThread()) {
        CJGuiInternalSession *live = CjguiLookupSession(session);
        if (!live || live.destroyed) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        CjguiFillWindowBackgroundSnapshot(live, outSnapshot);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
    dispatch_sync(dispatch_get_main_queue(), ^{
        CJGuiInternalSession *live = CjguiLookupSession(session);
        if (!live || live.destroyed) {
            status = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        } else {
            CjguiFillWindowBackgroundSnapshot(live, outSnapshot);
            status = CJGUI_INTERNAL_RENDERER_OK;
        }
    });
    return status;
}

@interface CjguiWindowBackgroundSnapshotCacheProbe : NSObject
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL watchdogFired;
@property(nonatomic, assign) uint64_t legacyBlockedNs;
@property(nonatomic, assign) uint64_t cachedReadNs;
@property(nonatomic, strong) dispatch_queue_t worker;
- (void)startCachedGetterDelayCase;
- (void)testMissingAndReusedGeneration;
- (void)testReusedGenerationRead;
- (void)testPublishedReusedGenerationRead;
- (void)finish;
@end

@implementation CjguiWindowBackgroundSnapshotCacheProbe

- (void)check:(BOOL)condition message:(const char *)message {
    if (condition) return;
    self.failed = YES;
    fprintf(stderr, "WINDOW_BACKGROUND_CACHE FAIL: %s\n", message);
}

- (void)startLegacyControl {
    dispatch_async(dispatch_get_main_queue(), ^{
        atomic_store_explicit(&gWindowBackgroundBlockStarted, true, memory_order_release);
        usleep((useconds_t)kWindowBackgroundBlockMicros);
    });
    dispatch_async(self.worker, ^{
        while (!atomic_load_explicit(&gWindowBackgroundBlockStarted, memory_order_acquire)) usleep(100);
        CjguiInternalRendererWindowBackgroundSnapshot value = {0};
        uint64_t started = CjguiOwnerTraceNanoseconds();
        CjguiInternalRendererStatus status = LegacyDispatchSyncSnapshot(1, &value);
        uint64_t ended = CjguiOwnerTraceNanoseconds();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.legacyBlockedNs = ended >= started ? ended - started : UINT64_MAX;
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        value.acceptedSceneVersion == 503 && value.environmentRevision == 17 &&
                        value.observationRevision == 29 && value.colorScheme == 2 &&
                        value.windowActive == 1
                message:"legacy synchronous control did not copy its actual published session scalars"];
            [self check:self.legacyBlockedNs >= kWindowBackgroundBlockMicros * 800
                message:"legacy dispatch_sync control did not reproduce main-queue blocking"];
            atomic_store_explicit(&gWindowBackgroundBlockStarted, false, memory_order_release);
            [self startCachedGetterDelayCase];
        });
    });
}

- (void)startCachedGetterDelayCase {
    dispatch_async(dispatch_get_main_queue(), ^{
        atomic_store_explicit(&gWindowBackgroundBlockStarted, true, memory_order_release);
        usleep((useconds_t)kWindowBackgroundBlockMicros);
    });
    dispatch_async(self.worker, ^{
        while (!atomic_load_explicit(&gWindowBackgroundBlockStarted, memory_order_acquire)) usleep(100);
        CjguiInternalRendererWindowBackgroundSnapshot value = {0};
        uint64_t started = CjguiOwnerTraceNanoseconds();
        CjguiInternalRendererStatus status = cjgui_internal_renderer_window_background_snapshot(1, &value);
        uint64_t ended = CjguiOwnerTraceNanoseconds();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cachedReadNs = ended >= started ? ended - started : UINT64_MAX;
            [self check:status == CJGUI_INTERNAL_RENDERER_OK
                message:"published background snapshot was unavailable while main queue was blocked"];
            [self check:self.cachedReadNs < kWindowBackgroundFastLimitMicros * 1000
                message:"off-main background getter waited on AppKit's main queue"];
            [self check:value.acceptedSceneVersion == 503 && value.frameIndex == 0 &&
                        value.requestRevision == 41 && value.environmentRevision == 17 &&
                        value.observationRevision == 29 && value.requestedMode == 1 &&
                        value.backend == 1 && value.actualMode == 1 && value.fallbackReason == 1 &&
                        value.completion == 1 && value.reduceTransparency == 0 &&
                        value.windowActive == 1 && value.colorScheme == 2
                message:"cached getter returned an incomplete or different-generation snapshot"];
            [self testMissingAndReusedGeneration];
        });
    });
}

- (void)testMissingAndReusedGeneration {
    // Slot 2 represents a live native generation with no published state.
    // Do the actual getter on the worker: its AppKit-main branch is not the
    // unknown case this check intends to cover.
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[1], 77, memory_order_release);
    dispatch_async(self.worker, ^{
        CjguiInternalRendererWindowBackgroundSnapshot missing = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_window_background_snapshot(2, &missing);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
                        missing.acceptedSceneVersion == 0 && missing.environmentRevision == 0
                message:"off-main unpublished snapshot did not return named failure with cleared output"];
            [self testReusedGenerationRead];
        });
    });
}

- (void)testReusedGenerationRead {
    // Keep generation 41's entry in the cache while changing the live slot
    // generation. The next off-main read must reject and clear that old entry.
    ctx.sessionGeneration = 42;
    ctx.windowBackgroundAcceptedSceneVersion = 504;
    ctx.windowBackgroundEnvironmentRevision = 18;
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 42, memory_order_release);
    dispatch_async(self.worker, ^{
        CjguiInternalRendererWindowBackgroundSnapshot reused = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_window_background_snapshot(1, &reused);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
                        reused.acceptedSceneVersion == 0 && reused.environmentRevision == 0
                message:"slot reuse leaked a snapshot from the prior session generation"];
            CjguiPublishWindowBackgroundSnapshot(ctx);
            [self testPublishedReusedGenerationRead];
        });
    });
}

- (void)testPublishedReusedGenerationRead {
    dispatch_async(self.worker, ^{
        CjguiInternalRendererWindowBackgroundSnapshot reused = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_window_background_snapshot(1, &reused);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        reused.acceptedSceneVersion == 504 && reused.environmentRevision == 18
                message:"new generation did not publish its own actual snapshot"];
            printf("WINDOW_BACKGROUND_CACHE control=legacy_sync blocked_ns=%llu cached_read_ns=%llu same_generation=1 slot_reuse=1\n",
                (unsigned long long)self.legacyBlockedNs,
                (unsigned long long)self.cachedReadNs);
            [self finish];
        });
    });
}

- (void)finish {
    CjguiClearWindowBackgroundSnapshotForSlot(0, 42);
    CjguiClearWindowBackgroundSnapshotForSlot(1, 77);
    gCjguiSessionOccupied[0] = NO;
    gCjguiSessions[0] = nil;
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 0, memory_order_release);
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[1], 0, memory_order_release);
    if (self.failed || self.watchdogFired) {
        NSEvent *wake = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
            location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil
            subtype:0 data1:0 data2:0];
        [NSApp stop:nil];
        if (wake) [NSApp postEvent:wake atStart:YES];
        return;
    }
    fprintf(stdout, "WINDOW_BACKGROUND_CACHE PASS legacy_block_ns=%llu cached_read_ns=%llu generation_and_reuse=1 source=private_snapshot_probe\n",
        (unsigned long long)self.legacyBlockedNs, (unsigned long long)self.cachedReadNs);
    NSEvent *wake = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
        location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil
        subtype:0 data1:0 data2:0];
    [NSApp stop:nil];
    if (wake) [NSApp postEvent:wake atStart:YES];
}

@end

int main(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        cjgui_internal_renderer_enable_main_thread_dispatch();
        ctx = [CJGuiInternalSession new];
        ctx.rendererSessionToken = 1;
        ctx.sessionGeneration = 41;
        ctx.windowBackgroundAcceptedSceneVersion = 503;
        ctx.windowBackgroundSubmittedFrameIndex = 211;
        ctx.windowBackgroundRequestRevision = 41;
        ctx.windowBackgroundEnvironmentRevision = 17;
        ctx.windowBackgroundObservationRevision = 29;
        ctx.windowBackgroundRequestedMode = 1;
        ctx.windowBackgroundBackend = 1;
        ctx.windowBackgroundActualMode = 1;
        ctx.windowBackgroundFallbackReason = 1;
        ctx.windowBackgroundCompletion = 1;
        ctx.windowBackgroundReduceTransparency = NO;
        ctx.windowBackgroundWindowActive = YES;
        ctx.windowBackgroundColorScheme = 2;
        gCjguiSessions[0] = ctx;
        gCjguiSessionOccupied[0] = YES;
        atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 41, memory_order_release);
        CjguiPublishWindowBackgroundSnapshot(ctx);

        CjguiWindowBackgroundSnapshotCacheProbe *probe = [CjguiWindowBackgroundSnapshotCacheProbe new];
        probe.worker = dispatch_queue_create("cjgui.window-background-snapshot.worker", DISPATCH_QUEUE_SERIAL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [probe startLegacyControl];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)kWindowBackgroundWatchdogMicros * NSEC_PER_USEC), dispatch_get_main_queue(), ^{
                probe.watchdogFired = YES;
                probe.failed = YES;
                fprintf(stderr, "WINDOW_BACKGROUND_CACHE FAIL: watchdog fired\n");
                [probe finish];
            });
        [app run];
        return probe.failed || probe.watchdogFired ? 1 : 0;
    }
}
