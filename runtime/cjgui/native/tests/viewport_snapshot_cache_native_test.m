// Controlled regression for the private composable viewport scalar snapshot.
// The RED invocation uses the current synchronous production getter while a
// real AppKit run loop has its main queue held. The GREEN invocation expects
// the published-cache getter to return the same session facts without waiting.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdatomic.h>
#include <unistd.h>

@interface CJGuiInternalSession (ViewportSnapshotCacheTest)
- (void)windowGeometryDidChange;
@end

static const uint64_t kViewportMainBlockMicros = 60000;
static const uint64_t kViewportFastLimitNs = 12000000;
static const uint64_t kViewportRedMinimumNs = 48000000;
static const uint64_t kViewportWatchdogNs = 3000000000;

static _Atomic(bool) gViewportMainBlockStarted = false;
static CJGuiInternalSession *gViewportTestSession = nil;

@interface CjguiViewportSnapshotCacheProbe : NSObject
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL watchdogFired;
@property(nonatomic, assign) BOOL expectCache;
@property(nonatomic, assign) uint64_t getterWallNs;
@property(nonatomic, strong) dispatch_queue_t worker;
- (void)startGetterCase;
- (void)verifyUnpublishedCase;
- (void)verifyResizeCase;
- (void)verifyImageCompletionCase;
- (void)verifyReusedGenerationCase;
- (void)verifyPublishedReplacementCase;
- (void)finish;
@end

@implementation CjguiViewportSnapshotCacheProbe

- (void)check:(BOOL)condition message:(const char *)message {
    if (condition) return;
    self.failed = YES;
    fprintf(stderr, "VIEWPORT_SNAPSHOT_CACHE FAIL: %s\n", message);
}

- (void)startGetterCase {
    dispatch_async(dispatch_get_main_queue(), ^{
        atomic_store_explicit(&gViewportMainBlockStarted, true, memory_order_release);
        usleep((useconds_t)kViewportMainBlockMicros);
    });
    dispatch_async(self.worker, ^{
        while (!atomic_load_explicit(&gViewportMainBlockStarted, memory_order_acquire)) usleep(100);
        CjguiInternalRendererViewport viewport = {0};
        uint64_t started = CjguiOwnerTraceNanoseconds();
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_composable_viewport(1, &viewport);
        uint64_t ended = CjguiOwnerTraceNanoseconds();
        uint64_t getterWallNs = ended >= started ? ended - started : UINT64_MAX;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.getterWallNs = getterWallNs;
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && viewport.width == 640 &&
                        viewport.height == 360 && viewport.resizeVersion == 7 &&
                        viewport.resourceCompletionVersion == 11
                message:"viewport getter did not return the actual same-session scalar facts"];
            if (self.expectCache) {
                [self check:getterWallNs < kViewportFastLimitNs
                    message:"published viewport getter waited for the blocked AppKit main queue"];
            } else {
                [self check:getterWallNs >= kViewportRedMinimumNs
                    message:"synchronous production getter RED did not include the main-queue block"];
            }
            fprintf(stdout,
                "VIEWPORT_SNAPSHOT_CACHE mode=%s getter_wall_ns=%llu width=%u height=%u resize=%llu resource=%llu\n",
                self.expectCache ? "green" : "production_sync_red",
                (unsigned long long)getterWallNs,
                viewport.width, viewport.height,
                (unsigned long long)viewport.resizeVersion,
                (unsigned long long)viewport.resourceCompletionVersion);
            if (self.expectCache) [self verifyUnpublishedCase];
            else [self finish];
        });
    });
}

- (void)verifyUnpublishedCase {
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[1], 77, memory_order_release);
    dispatch_async(self.worker, ^{
        CjguiInternalRendererViewport viewport = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_composable_viewport(2, &viewport);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
                        viewport.width == 0 && viewport.height == 0 &&
                        viewport.resizeVersion == 0 && viewport.resourceCompletionVersion == 0
                message:"off-main unpublished viewport did not fail closed with zero output"];
            [self verifyResizeCase];
        });
    });
}

- (void)verifyResizeCase {
    [gViewportTestSession.view setFrameSize:NSMakeSize(800, 450)];
    [gViewportTestSession windowGeometryDidChange];
    dispatch_async(self.worker, ^{
        CjguiInternalRendererViewport viewport = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_composable_viewport(1, &viewport);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && viewport.width == 800 &&
                        viewport.height == 450 && viewport.resizeVersion == 8 &&
                        viewport.resourceCompletionVersion == 11
                message:"actual geometry publisher did not advance the cached viewport snapshot"];
            [self verifyImageCompletionCase];
        });
    });
}

- (void)verifyImageCompletionCase {
    CJGuiInternalComposableImageResourceDomain *domain =
        [[CJGuiInternalComposableImageResourceDomain alloc]
            initWithDevice:gViewportTestSession.device];
    CJGuiInternalComposableImageResource *resource = [CJGuiInternalComposableImageResource new];
    resource.cacheKey = @"viewport-cache-test-resource";
    gViewportTestSession.composableImageDomain = domain;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    node.imageTextureCacheKey = resource.cacheKey;
    [gViewportTestSession.composableNodes addObject:node];
    CJGuiInternalComposableImageSubscription *subscriber =
        [CJGuiInternalComposableImageSubscription new];
    subscriber.sessionToken = 1;
    subscriber.sessionGeneration = 71;
    [resource.subscribers addObject:subscriber];
    // This is the actual shared increment/publish point used by successful
    // and failed image-load completion on the AppKit main run loop.
    CjguiNotifyComposableImageSubscribers(domain, resource);
    dispatch_async(self.worker, ^{
        CjguiInternalRendererViewport viewport = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_composable_viewport(1, &viewport);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && viewport.width == 800 &&
                        viewport.height == 450 && viewport.resizeVersion == 8 &&
                        viewport.resourceCompletionVersion == 12
                message:"image completion increment did not publish its actual viewport version"];
            [self verifyReusedGenerationCase];
        });
    });
}

- (void)verifyReusedGenerationCase {
    gViewportTestSession.sessionGeneration = 72;
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 72, memory_order_release);
    dispatch_async(self.worker, ^{
        CjguiInternalRendererViewport stale = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_composable_viewport(1, &stale);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR && stale.width == 0 &&
                        stale.height == 0 && stale.resizeVersion == 0 &&
                        stale.resourceCompletionVersion == 0
                message:"slot reuse returned the previous generation's viewport snapshot"];
            CjguiPublishViewportSnapshot(gViewportTestSession);
            [self verifyPublishedReplacementCase];
        });
    });
}

- (void)verifyPublishedReplacementCase {
    dispatch_async(self.worker, ^{
        CjguiInternalRendererViewport viewport = {0};
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_composable_viewport(1, &viewport);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && viewport.width == 800 &&
                        viewport.height == 450 && viewport.resizeVersion == 8 &&
                        viewport.resourceCompletionVersion == 12
                message:"replacement generation's own published viewport was not readable"];
            [self finish];
        });
    });
}

- (void)finish {
    CjguiClearViewportSnapshotForSlot(0, 0);
    gCjguiSessionOccupied[0] = NO;
    gCjguiSessions[0] = nil;
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 0, memory_order_release);
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[1], 0, memory_order_release);
    if (!self.failed && !self.watchdogFired) {
        fprintf(stdout, "VIEWPORT_SNAPSHOT_CACHE PASS mode=%s getter_wall_ns=%llu generation=71\n",
            self.expectCache ? "green" : "production_sync_red",
            (unsigned long long)self.getterWallNs);
    }
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
        (void)app;
        cjgui_internal_renderer_enable_main_thread_dispatch();
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (!device || !commandQueue) {
            fprintf(stderr, "VIEWPORT_SNAPSHOT_CACHE FAIL: Metal device or queue unavailable\n");
            return 2;
        }

        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.rendererSessionToken = 1;
        session.sessionGeneration = 71;
        session.resizeVersion = 7;
        session.composableImageResourceCompletionVersion = 11;
        CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
            initWithFrame:NSMakeRect(0, 0, 640, 360) device:device commandQueue:commandQueue];
        if (!view) {
            fprintf(stderr, "VIEWPORT_SNAPSHOT_CACHE FAIL: test Metal view unavailable\n");
            return 2;
        }
        view.testBackingScaleOverride = 1.0;
        session.view = view;
        session.device = device;
        gViewportTestSession = session;
        gCjguiSessions[0] = session;
        gCjguiSessionOccupied[0] = YES;
        atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 71, memory_order_release);

        CjguiViewportSnapshotCacheProbe *probe = [CjguiViewportSnapshotCacheProbe new];
        probe.expectCache = getenv("CJGUI_VIEWPORT_EXPECT_CACHE") != NULL;
        if (probe.expectCache) CjguiPublishViewportSnapshot(session);
        probe.worker = dispatch_queue_create("cjgui.viewport-snapshot.worker", DISPATCH_QUEUE_SERIAL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC),
            dispatch_get_main_queue(), ^{ [probe startGetterCase]; });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)kViewportWatchdogNs),
            dispatch_get_main_queue(), ^{
                probe.watchdogFired = YES;
                probe.failed = YES;
                fprintf(stderr, "VIEWPORT_SNAPSHOT_CACHE FAIL: watchdog fired\n");
                [probe finish];
            });
        [NSApp run];
        return probe.failed || probe.watchdogFired ? 1 : 0;
    }
}
