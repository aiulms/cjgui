// Small normal-macro native bridge consumer. It creates a real renderer
// session and exercises the production pump/trace path; it is not a Cangjie
// application or natural-performance acceptance run.
#import "../cjgui_internal_renderer.m"

#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static uint64_t gSession;
static uint64_t gGeneration;
static const uint64_t kTurn = 1;
static dispatch_semaphore_t gBlockerEntered;

static uint64_t traceEvent(uint32_t kind, uint64_t request, uint32_t phase, uint64_t span) {
    return cjgui_internal_renderer_owner_trace_record(kind, gSession, kTurn, request,
        0, gGeneration, phase, span);
}

static uint64_t traceEventForTurn(uint32_t kind, uint64_t turn, uint64_t span) {
    return cjgui_internal_renderer_owner_trace_record(kind, gSession, turn, 0,
        0, gGeneration, CJGUI_OWNER_PHASE_UNKNOWN, span);
}

static uint64_t beginTurn(void) {
    return traceEvent(CJGUI_OWNER_TRACE_TURN_BEGIN, 0, CJGUI_OWNER_PHASE_UNKNOWN, 0);
}

static void endTurn(uint64_t span) {
    traceEvent(CJGUI_OWNER_TRACE_TURN_END, 0, CJGUI_OWNER_PHASE_UNKNOWN, span);
}

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
    if (gSession == 0 || gGeneration == 0) return 3;
    [session.window setTitle:@"CJGUI E Trace · 受控归因"];
    [session.window orderOut:nil];
    cjgui_internal_renderer_enable_main_thread_dispatch();
    return 0;
}

static void *mainQueueWorker(void *unused) {
    (void)unused;
    dispatch_semaphore_wait(gBlockerEntered, DISPATCH_TIME_FOREVER);
    uint64_t turn = beginTurn();
    cjgui_internal_renderer_owner_trace_set_turn(kTurn);
    CjguiInternalRendererEvent event = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(gSession, 0, &event);
    endTurn(turn);
    cjgui_internal_renderer_owner_trace_set_turn(0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "fixture_pump_status=%d\n", status);
        exit(7);
    }
    CjguiInternalRendererStatus destroyed = cjgui_internal_renderer_destroy(gSession);
    if (destroyed != CJGUI_INTERNAL_RENDERER_OK) exit(8);
    cjgui_internal_renderer_owner_trace_export();
    exit(0);
}

static void *idlePumpWorker(void *unused) {
    (void)unused;
    uint64_t turn = beginTurn();
    cjgui_internal_renderer_owner_trace_set_turn(kTurn);
    CjguiInternalRendererEvent event = {0};
    CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event_measured(
        gSession, 0, &event, NULL);
    uint64_t idleNs = 0;
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_pump_event_measured(gSession, 10, &event, &idleNs);
    fprintf(stderr, "fixture_out_idle_wait_ns=%llu\n", (unsigned long long)idleNs);
    endTurn(turn);
    cjgui_internal_renderer_owner_trace_set_turn(0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "fixture_pump_status=%d\n", status);
        exit(16);
    }
    CjguiInternalRendererStatus destroyed = cjgui_internal_renderer_destroy(gSession);
    if (destroyed != CJGUI_INTERNAL_RENDERER_OK) exit(17);
    cjgui_internal_renderer_owner_trace_export();
    exit(0);
}

static void *incompleteCloseWorker(void *unused) {
    (void)unused;
    CjguiInternalRendererEvent event = {0};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
    for (uint32_t warmup = 0; warmup < 4; warmup++) {
        status = cjgui_internal_renderer_pump_event_measured(gSession, 0, &event, NULL);
        if (status != CJGUI_INTERNAL_RENDERER_OK) exit(20);
    }
    cjgui_internal_renderer_owner_trace_set_turn(1);
    uint64_t completed = traceEventForTurn(CJGUI_OWNER_TRACE_TURN_BEGIN, 1, 0);
    usleep(22000);
    traceEventForTurn(CJGUI_OWNER_TRACE_TURN_END, 1, completed);
    cjgui_internal_renderer_owner_trace_set_turn(0);

    cjgui_internal_renderer_owner_trace_set_turn(2);
    (void)traceEventForTurn(CJGUI_OWNER_TRACE_TURN_BEGIN, 2, 0);
    usleep(22000);
    uint64_t idleNs = 0;
    status = cjgui_internal_renderer_pump_event_measured(
        gSession, 0, &event, NULL);
    for (uint32_t attempt = 0; status == CJGUI_INTERNAL_RENDERER_OK &&
         idleNs < 40000000 && attempt < 8; attempt++) {
        uint64_t oneIdleNs = 0;
        status = cjgui_internal_renderer_pump_event_measured(gSession, 16, &event, &oneIdleNs);
        idleNs += oneIdleNs;
    }
    fprintf(stderr, "fixture_incomplete_idle_wait_ns=%llu\n", (unsigned long long)idleNs);
    if (status != CJGUI_INTERNAL_RENDERER_OK || idleNs < 35000000) exit(21);

    // Force the live sampler ring to wrap after turn 1. The separately bounded
    // slow-turn sample snapshot must keep the real samples captured during 1.
    for (uint64_t index = 0; index < CJGUI_OWNER_TRACE_SAMPLE_CAPACITY + 16; index++) {
        CjguiOwnerTraceStackSample sample = {0};
        sample.pid = (uint64_t)getpid();
        sample.turn = 2;
        sample.startedNs = index + 1;
        sample.finishedNs = index + 2;
        sample.role = 1;
        CjguiOwnerTracePublishStackSample(&sample);
    }
    CjguiInternalRendererStatus destroyed = cjgui_internal_renderer_destroy(gSession);
    if (destroyed != CJGUI_INTERNAL_RENDERER_OK) exit(22);
    cjgui_internal_renderer_owner_trace_export();
    exit(0);
}

static int runMainQueueWait(void) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyProhibited];
    gBlockerEntered = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_semaphore_signal(gBlockerEntered);
        usleep(50000);
    });
    pthread_t worker;
    if (pthread_create(&worker, NULL, mainQueueWorker, NULL) != 0) return 4;
    // dispatch_main() owns libdispatch's main queue without entering AppKit's
    // main-thread run loop. The production bridge then fails its main-thread
    // check and recursively dispatch_syncs to the queue it already owns.
    // NSApplication.run keeps the pump on the real AppKit main thread.
    [application run];
    return 5;
}

static int runIdlePump(void) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyProhibited];
    pthread_t worker;
    if (pthread_create(&worker, NULL, idlePumpWorker, NULL) != 0) return 18;
    [application run];
    return 19;
}

static int runIncompleteClose(void) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyProhibited];
    pthread_t worker;
    if (pthread_create(&worker, NULL, incompleteCloseWorker, NULL) != 0) return 23;
    [application run];
    return 24;
}

static void *delayedPipeReader(void *opaque) {
    int fd = *(int *)opaque;
    usleep(50000);
    char buffer[16384];
    while (read(fd, buffer, sizeof(buffer)) > 0) { }
    close(fd);
    return NULL;
}

static int runOutputStall(void) {
    int pipeFds[2];
    if (pipe(pipeFds) != 0) return 9;
    int savedStderr = dup(STDERR_FILENO);
    if (savedStderr < 0 || dup2(pipeFds[1], STDERR_FILENO) < 0) return 10;
    pthread_t reader;
    if (pthread_create(&reader, NULL, delayedPipeReader, &pipeFds[0]) != 0) return 11;
    close(pipeFds[1]);
    setvbuf(stderr, NULL, _IONBF, 0);

    uint64_t turn = beginTurn();
    cjgui_internal_renderer_owner_trace_set_turn(kTurn);
    uint64_t span = traceEvent(CJGUI_OWNER_TRACE_OBSERVER_WRITE_BEGIN, 2,
        CJGUI_OWNER_PHASE_OBSERVER_WRITE, 0);
    size_t remaining = 4u * 1024u * 1024u;
    char block[16384];
    memset(block, 'x', sizeof(block));
    while (remaining > 0) {
        size_t count = MIN(sizeof(block), remaining);
        if (fprintf(stderr, "%.*s", (int)count, block) < 0) return 12;
        remaining -= count;
    }
    traceEvent(CJGUI_OWNER_TRACE_OBSERVER_WRITE_END, 2,
        CJGUI_OWNER_PHASE_OBSERVER_WRITE, span);
    uint64_t flush = traceEvent(CJGUI_OWNER_TRACE_OBSERVER_FLUSH_BEGIN, 3,
        CJGUI_OWNER_PHASE_OBSERVER_FLUSH, 0);
    if (fflush(stderr) != 0) return 13;
    traceEvent(CJGUI_OWNER_TRACE_OBSERVER_FLUSH_END, 3,
        CJGUI_OWNER_PHASE_OBSERVER_FLUSH, flush);
    if (dup2(savedStderr, STDERR_FILENO) < 0) return 14;
    close(savedStderr);
    pthread_join(reader, NULL);
    endTurn(turn);
    cjgui_internal_renderer_owner_trace_set_turn(0);
    CjguiInternalRendererStatus destroyed = cjgui_internal_renderer_destroy(gSession);
    if (destroyed != CJGUI_INTERNAL_RENDERER_OK) return 15;
    cjgui_internal_renderer_owner_trace_export();
    return 0;
}

int main(int argc, const char **argv) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "1", 1);
    if (argc != 2) return 1;
    if (strcmp(argv[1], "exit-no-explicit-export") == 0) {
        setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
        CjguiOwnerTraceRememberMainThread();
        uint64_t span = cjgui_internal_renderer_owner_trace_record(
            CJGUI_OWNER_TRACE_TURN_BEGIN, 0, kTurn, 0, 0, 0,
            CJGUI_OWNER_PHASE_UNKNOWN, 0);
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_TURN_END,
            0, kTurn, 0, 0, 0, CJGUI_OWNER_PHASE_UNKNOWN, span);
        return 0;
    }
    if (createFixtureSession() != 0) return 2;
    CjguiOwnerTraceRememberMainThread();
    if (strcmp(argv[1], "mainqueue") == 0) return runMainQueueWait();
    if (strcmp(argv[1], "output") == 0) return runOutputStall();
    if (strcmp(argv[1], "idle") == 0) return runIdlePump();
    if (strcmp(argv[1], "incomplete-close") == 0) return runIncompleteClose();
    return 1;
}
