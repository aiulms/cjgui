// Small normal-macro native bridge consumer for owner-trace dispatch coverage.
// It uses a real AppKit main loop and renderer session; it is not a Pharos app.
#import "../cjgui_internal_renderer.m"

#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static uint64_t gSession;
static uint64_t gGeneration;
static NSWindow *gFixtureWindow;
static id gFixtureCloseObserver;
static NSUInteger gFixtureCloseNotifications;
static dispatch_semaphore_t gReady;
static const uint64_t kTurn = 4101;

static int createFixtureSession(void) {
    CjguiInternalRendererConfig config = {
        .windowWidth = 360, .windowHeight = 240,
        .clearColorRed = 0.08, .clearColorGreen = 0.09,
        .clearColorBlue = 0.12, .clearColorAlpha = 1.0,
    };
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    gSession = cjgui_internal_renderer_create(&config, &status);
    CJGuiInternalSession *session = CjguiLookupSession(gSession);
    if (status != CJGUI_INTERNAL_RENDERER_OK || !session || session.destroyed) return 2;
    gGeneration = session.sessionGeneration;
    gFixtureWindow = session.window;
    gFixtureCloseObserver = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification
        object:gFixtureWindow queue:nil usingBlock:^(NSNotification *notification) {
            (void)notification;
            gFixtureCloseNotifications += 1;
        }];
    if (!gSession || !gGeneration) return 3;
    [session.window setTitle:@"CJGUI E Trace · Dispatch Matrix"];
    [session.window orderOut:nil];
    cjgui_internal_renderer_enable_main_thread_dispatch();
    status = cjgui_internal_renderer_set_diagnostic_timing(gSession, 1);
    return status == CJGUI_INTERNAL_RENDERER_OK ? 0 : 4;
}

static void stopAppKitRunLoop(void) {
    NSApplication *application = NSApplication.sharedApplication;
    [application stop:nil];
    NSEvent *wake = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
        location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil
        subtype:0 data1:0 data2:0];
    if (wake) [application postEvent:wake atStart:YES];
}

static void *dispatchWorker(void *unused) {
    (void)unused;
    dispatch_semaphore_wait(gReady, DISPATCH_TIME_FOREVER);
    uint64_t turnSpan = cjgui_internal_renderer_owner_trace_record(
        CJGUI_OWNER_TRACE_TURN_BEGIN, gSession, kTurn, 0, 0, gGeneration,
        CJGUI_OWNER_PHASE_UNKNOWN, 0);
    cjgui_internal_renderer_owner_trace_set_turn(kTurn);

    if (getenv("CJGUI_TRACE_POSITION_SYNC_FIRST")) {
        uint64_t meta[8] = {0}; double rect[4] = {0};
        (void)cjgui_internal_renderer_text_position_v1(gSession, 1, 1,
            1, 0, 2, 0, 0, 0, 0, 0, meta, rect);
        fprintf(stderr, "fixture_position_sync named=1\n");
    }

    if (getenv("CJGUI_TRACE_DIAGNOSTIC_GETTER_FIRST")) {
        CjguiInternalRendererComposableDisplayProgress progress = {0};
        CjguiInternalRendererDiagnosticResources resources = {0};
        CjguiInternalRendererDiagnosticNodeGeometry geometry = {0};
        // A missing accepted overlay may return a named error. It must still
        // expose the same real main hop; this fixture tests observation, not
        // inventing an accepted scene or diagnostic value.
        CjguiInternalRendererStatus displayStatus =
            cjgui_internal_renderer_composable_display_progress(gSession, &progress);
        CjguiInternalRendererStatus resourceStatus =
            cjgui_internal_renderer_diagnostic_resources(gSession, &resources);
        CjguiInternalRendererStatus geometryStatus =
            cjgui_internal_renderer_diagnostic_node_geometry(gSession, 0, &geometry);
        fprintf(stderr, "fixture_diagnostic_getters display=%d resources=%d geometry=%d\n",
            displayStatus, resourceStatus, geometryStatus);
    }

    if (getenv("CJGUI_TRACE_INPUT_SYNC_FIRST")) {
        uint32_t start = 0, end = 0;
        (void)cjgui_internal_renderer_focus_composable_node(gSession, 1);
        (void)cjgui_internal_renderer_restore_composable_selection(gSession, 1, 1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 1, "", 0, 0, &start, &end);
        (void)cjgui_internal_renderer_read_composable_selection(gSession, 1, 1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 1, "", &start, &end);
        (void)cjgui_internal_renderer_recover_active_text_proxy(gSession, 1, 1,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "", &start, &end);
        (void)cjgui_internal_renderer_form_event_text(gSession);
        fprintf(stderr, "fixture_input_sync named=5\n");
    }

    CjguiInternalRendererDiagnosticWorkload workload = {0};
    CjguiInternalRendererStatus workloadStatus =
        cjgui_internal_renderer_diagnostic_workload(gSession, &workload);
    CjguiInternalRendererDiagnosticTiming timing = {0};
    CjguiInternalRendererStatus timingStatus =
        cjgui_internal_renderer_diagnostic_timing(gSession, &timing);
    CjguiInternalRendererTextMeasurement measurement = {0};
    CjguiInternalRendererStatus measureStatus =
        cjgui_internal_renderer_measure_composable_text(gSession, "trace", 13.0, 0, 0, 240,
            &measurement);
    uint32_t naturalHeight = 0;
    CjguiInternalRendererStatus multilineStatus =
        cjgui_internal_renderer_measure_composable_multiline_natural_height(
            gSession, "trace\nmeasurement", 13.0, 0, 0, 240, &naturalHeight);

    // Exercise the named native families through their production entry
    // points. Invalid candidate payloads are intentional: their purpose is
    // to prove submit/enter/exit/return attribution still surrounds the
    // synchronous main hop before validation returns.
    uint32_t ready = 0;
    (void)cjgui_internal_renderer_begin_composable_preparation(gSession, 777, 0, 777, 1);
    (void)cjgui_internal_renderer_prepare_composable_node(gSession, 777, 0, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    (void)cjgui_internal_renderer_advance_composable_preparation(gSession, 778, 0, &ready);
    (void)cjgui_internal_renderer_promote_composable_preparation(gSession, 778);
    (void)cjgui_internal_renderer_cancel_composable_preparation(gSession, 777);
    (void)cjgui_internal_renderer_configure_composable_scene(gSession, 778, 1);
    (void)cjgui_internal_renderer_set_composable_scene_node(gSession, 0, NULL,
        NULL, NULL, NULL, NULL, 0);
    (void)cjgui_internal_renderer_set_composable_scene_geometry(gSession, 778, 0, NULL);
    (void)cjgui_internal_renderer_discard_composable_scene_candidate(gSession);
    (void)cjgui_internal_renderer_set_composable_node_semantic_identity(gSession, 0, "trace-node");
    (void)cjgui_internal_renderer_set_composable_node_semantic_metadata(gSession, 0,
        "binding", "row", "parent", "label");
    (void)cjgui_internal_renderer_configure_composable_command_menu(gSession, 778, 1);
    (void)cjgui_internal_renderer_set_composable_command_menu_item(gSession, 0,
        "trace.command", "Trace", "trace", "", 0, 0, 1, 0);
    (void)cjgui_internal_renderer_commit_composable_command_menu(gSession);
    (void)cjgui_internal_renderer_configure_composable_data_transfer(gSession, 778, 1);
    (void)cjgui_internal_renderer_set_composable_data_transfer_item(gSession, 0,
        NULL, NULL, NULL, NULL, NULL);
    const uint8_t oneByte = 0;
    (void)cjgui_internal_renderer_set_composable_data_transfer_item_bytes(gSession, 0, &oneByte, 1);
    (void)cjgui_internal_renderer_stage_window_background(gSession, 778,
        CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, 1);

    uint64_t tid = 0;
    (void)pthread_threadid_np(NULL, &tid);
    fprintf(stderr, "fixture_status workload=%d timing=%d measure=%d multiline=%d matrix=complete tid=%llu gen=%llu\n",
        workloadStatus, timingStatus, measureStatus, multilineStatus,
        (unsigned long long)tid, (unsigned long long)gGeneration);
    cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_TURN_END, gSession, kTurn,
        0, 0, gGeneration, CJGUI_OWNER_PHASE_UNKNOWN, turnSpan);
    cjgui_internal_renderer_owner_trace_set_turn(0);

    // A rejected target still crosses the real owner-to-main call. It must
    // expose that wait without changing the live fixture's close lifecycle.
    CjguiInternalRendererStatus closeStatus = cjgui_internal_renderer_request_close(UINT64_MAX - 1);
    if (closeStatus != CJGUI_INTERNAL_RENDERER_INVALID_SESSION) exit(9);
    CjguiInternalRendererStatus destroyed = cjgui_internal_renderer_destroy(gSession);
    if (destroyed != CJGUI_INTERNAL_RENDERER_OK) exit(5);
    __block BOOL hiddenWindowRetired = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        // NSApp.windows includes retained invisible/closed windows, so its
        // membership is not a close receipt. Observe the actual close instead.
        hiddenWindowRetired = gFixtureCloseNotifications == 1 &&
            gFixtureWindow.delegate == nil && gFixtureWindow.contentView == nil;
        fprintf(stderr, "fixture_hidden_close_notifications=%lu\n", (unsigned long)gFixtureCloseNotifications);
        [NSNotificationCenter.defaultCenter removeObserver:gFixtureCloseObserver];
        gFixtureCloseObserver = nil;
        gFixtureWindow = nil;
    });
    fprintf(stderr, "fixture_hidden_window_retired=%d\n", hiddenWindowRetired);
    if (!hiddenWindowRetired) exit(10);
    cjgui_internal_renderer_owner_trace_export();
    dispatch_async(dispatch_get_main_queue(), ^{ stopAppKitRunLoop(); });
    intptr_t result = workloadStatus == CJGUI_INTERNAL_RENDERER_OK &&
        timingStatus == CJGUI_INTERNAL_RENDERER_OK && measureStatus == CJGUI_INTERNAL_RENDERER_OK &&
        multilineStatus == CJGUI_INTERNAL_RENDERER_OK ? 0 : 6;
    return (void *)result;
}

static int runMode(BOOL blockMain) {
    NSApplication *application = NSApplication.sharedApplication;
    [application setActivationPolicy:NSApplicationActivationPolicyProhibited];
    if (createFixtureSession() != 0) return 7;
    CjguiOwnerTraceRememberMainThread();
    gReady = dispatch_semaphore_create(0);
    pthread_t worker;
    if (pthread_create(&worker, NULL, dispatchWorker, NULL) != 0) return 8;
    if (blockMain) {
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_semaphore_signal(gReady);
            usleep(50000);
        });
    } else {
        // Use the same live-main-queue readiness boundary in both modes.
        // A pre-run signal would measure AppKit startup as the idle dispatch.
        dispatch_async(dispatch_get_main_queue(), ^{ dispatch_semaphore_signal(gReady); });
    }
    [application run];
    void *result = NULL;
    pthread_join(worker, &result);
    return (int)(intptr_t)result;
}

int main(int argc, const char **argv) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
    if (argc != 2) return 1;
    if (strcmp(argv[1], "blocked") == 0) return runMode(YES);
    if (strcmp(argv[1], "idle") == 0) return runMode(NO);
    return 1;
}
