// Controlled AppKit queue discriminator. The blocked queue is deliberate;
// its duration is not a natural consumer performance result.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>
#include <stdatomic.h>
#include <unistd.h>

static _Atomic(bool) mainHeld;
static BOOL expectCache;
static BOOL failed;
static CJGuiInternalSession *testSession;
static void check(BOOL value, const char *reason);

static CjguiInternalRendererStatus scalarRead(uint64_t generation, uint64_t scene,
    CjguiInternalRendererComposableDisplayProgress *progress) {
    CjguiInternalRendererDiagnosticWorkload workload = {0};
    CjguiInternalRendererDiagnosticTiming timing = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_diagnostic_scalar_snapshot(
        1, generation, scene, progress, &workload, &timing);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        check(workload.sceneVersion == scene && timing.sceneVersion == scene &&
            workload.frameIndex == progress->submittedFrameIndex &&
            timing.frameIndex == progress->submittedFrameIndex &&
            workload.reusableResourceBytes == UINT64_MAX && workload.textTextureLiveBytes == UINT64_MAX,
            "scalar read fabricated traversed resource totals or mismatched frames");
    }
    return status;
}

static void finish(void) {
    [NSApp stop:nil];
    NSEvent *wake = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
        location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil
        subtype:0 data1:0 data2:0];
    if (wake) [NSApp postEvent:wake atStart:YES];
}

static void check(BOOL value, const char *reason) {
    if (value) return;
    failed = YES;
    fprintf(stderr, "DISPLAY_PROGRESS_CACHE FAIL %s\n", reason);
}

static void beginCase(void) {
    dispatch_queue_t worker = dispatch_queue_create("cjgui.display-progress-cache", DISPATCH_QUEUE_SERIAL);
    dispatch_async(dispatch_get_main_queue(), ^{
        atomic_store_explicit(&mainHeld, true, memory_order_release);
        usleep(60000); // only this controlled main-queue discriminator
    });
    dispatch_async(worker, ^{
        while (!atomic_load_explicit(&mainHeld, memory_order_acquire)) usleep(100);
        CjguiInternalRendererComposableDisplayProgress p = {0};
        uint64_t before = CjguiOwnerTraceNanoseconds();
        CjguiInternalRendererStatus status = expectCache ? scalarRead(71, 17, &p) :
            cjgui_internal_renderer_composable_display_progress(1, &p);
        uint64_t elapsed = CjguiOwnerTraceNanoseconds() - before;
        dispatch_async(dispatch_get_main_queue(), ^{
            check(status == CJGUI_INTERNAL_RENDERER_OK && p.submittedFrameIndex == 9 &&
                p.observedMetalCompletionFrameIndex == 8 && p.submittedSceneVersion == 17 &&
                p.currentPointWidth == 640 && p.currentPointHeight == 360 &&
                p.currentGeometryRevision == 7 && p.submittedGeometryRevision == 7 &&
                p.overlayDrawnProjectionVersion == 17, "actual same-session progress mismatch");
            check(expectCache ? elapsed < 12000000 : elapsed >= 48000000,
                "getter did not distinguish blocked main queue from published scalar read");
            printf("DISPLAY_PROGRESS_CACHE mode=%s getter_wall_ns=%llu session_generation=71 frame=%llu scene=%llu\n",
                expectCache ? "cache" : "production_sync_red", (unsigned long long)elapsed,
                (unsigned long long)p.submittedFrameIndex, (unsigned long long)p.submittedSceneVersion);
            fflush(stdout);
            if (!expectCache) { finish(); return; }
            CjguiInternalRendererComposableDisplayProgress wrongScene = {0};
            check(scalarRead(71, 18, &wrongScene) == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
                wrongScene.submittedFrameIndex == 0, "wrong accepted scene escaped");
            // This is the actual existing geometry publication entry point.
            [testSession.view setFrameSize:NSMakeSize(800, 450)];
            [testSession windowGeometryDidChange];
            dispatch_async(worker, ^{
                CjguiInternalRendererComposableDisplayProgress resized = {0};
                CjguiInternalRendererStatus s = scalarRead(71, 17, &resized);
                dispatch_async(dispatch_get_main_queue(), ^{
                    check(s == CJGUI_INTERNAL_RENDERER_OK && resized.currentPointWidth == 800 &&
                        resized.currentPointHeight == 450 && resized.currentGeometryRevision == 8 &&
                        resized.submittedGeometryRevision == 7 && resized.submittedFrameIndex == 9 &&
                        resized.submittedSceneVersion == 17, "resize borrowed old submitted geometry");
                    // A reused renderer slot with no new publication must
                    // never expose the previous session's accepted frame.
                    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 77, memory_order_release);
                    dispatch_async(worker, ^{
                        CjguiInternalRendererComposableDisplayProgress stale = {0};
                        CjguiInternalRendererStatus old = scalarRead(71, 17, &stale);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            check(old != CJGUI_INTERNAL_RENDERER_OK && stale.submittedFrameIndex == 0 &&
                                stale.submittedSceneVersion == 0, "old generation escaped after rebind");
                            testSession.sessionGeneration = 77;
                            testSession.lastSubmittedSceneVersion = 23;
                            testSession.composableSceneVersion = 23;
                            CjguiPublishViewportSnapshot(testSession);
                            CjguiClearDiagnosticScalarSnapshot(0, 71);
                            dispatch_async(worker, ^{
                                CjguiInternalRendererComposableDisplayProgress replacement = {0};
                                CjguiInternalRendererStatus fresh = scalarRead(77, 23, &replacement);
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    check(fresh == CJGUI_INTERNAL_RENDERER_OK && replacement.submittedSceneVersion == 23,
                                        "replacement generation publication was erased");
                                    CjguiInternalRendererComposableDisplayProgress invalidated = {0};
                                    CjguiClearDiagnosticScalarSnapshot(0, 77);
                                    check(scalarRead(77, 23, &invalidated) != CJGUI_INTERNAL_RENDERER_OK &&
                                        invalidated.submittedFrameIndex == 0, "cleared publication escaped");
                                    printf("DISPLAY_PROGRESS_CACHE checks=7 failed=%u fresh_ACK_getter_unchanged=1\n", failed);
                                    fflush(stdout);
                                    finish();
                                });
                            });
                        });
                    });
                });
            });
        });
    });
}

int main(void) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        cjgui_internal_renderer_enable_main_thread_dispatch();
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        id<MTLCommandQueue> queue = [device newCommandQueue];
        assert(device && queue);
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.rendererSessionToken = 1;
        session.sessionGeneration = 71;
        session.resizeVersion = 7;
        session.lastSubmittedResizeVersion = 7;
        session.lastSubmittedSceneVersion = 17;
        session.composableSceneVersion = 17;
        session.observedMetalCompletionFrameIndex = 8;
        session.device = device;
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 640, 360)
            device:device commandQueue:queue];
        session.view.testBackingScaleOverride = 1.0;
        session.view.frameIndex = 9;
        session.view.lastSubmittedPointSize = NSMakeSize(640, 360);
        session.view.lastSubmittedContentsScale = 1.0;
        session.view.lastSubmittedDrawableSize = CGSizeMake(640, 360);
        session.composableSceneOverlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 640, 360)];
        session.composableSceneOverlay.session = session;
        session.composableSceneOverlay.lastDrawnProjectionVersion = 17;
        testSession = session;
        gCjguiSessions[0] = session;
        gCjguiSessionOccupied[0] = YES;
        atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 71, memory_order_release);
        CjguiPublishViewportSnapshot(session);
        expectCache = getenv("CJGUI_DISPLAY_PROGRESS_EXPECT_CACHE") != NULL;
        dispatch_async(dispatch_get_main_queue(), ^{ beginCase(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            failed = YES; finish();
        });
        [app run];
        return failed ? 1 : 0;
    }
}
