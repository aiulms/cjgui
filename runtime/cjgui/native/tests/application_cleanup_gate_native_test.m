// An actual AppKit loop with a parent-controlled cleanup barrier. This is a
// lifecycle discriminator, not an owner-byte or normal GUI acceptance fixture.
#import "../cjgui_internal_renderer.m"
#include <assert.h>
#include <unistd.h>

static uint64_t ticket;
static BOOL failOutput;
static BOOL priorSnapshot;

static void *cleanupWorker(void *unused) {
    (void)unused;
    cjgui_internal_renderer_request_application_stop();
    dispatch_sync(dispatch_get_main_queue(), ^{
        assert(gCjguiApplicationStopPending && !gCjguiApplicationStopDelivered);
        assert([gCjguiApplicationTerminationDelegate applicationShouldTerminate:NSApp] == NSTerminateCancel);
        assert(!gCjguiApplicationStopDelivered);
    });
    printf("BARRIER_READY pid=%d ticket=%llu main_queue_serviced=1 stop_deferred=1\n", getpid(), (unsigned long long)ticket);
    fflush(stdout);
    char release;
    assert(read(STDIN_FILENO, &release, 1) == 1 && release == 'x');
    (void)cjgui_internal_renderer_owner_trace_managed_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,
        7, 91, 0, 0, 4, CJGUI_OWNER_PHASE_OWNER_FINALLY_ENTRY, 0, 123, 0);
    if (failOutput) {
        int readOnly = open("/dev/null", O_RDONLY);
        assert(readOnly >= 0 && dup2(readOnly, STDERR_FILENO) >= 0);
        close(readOnly);
    }
    if (priorSnapshot) cjgui_internal_renderer_owner_trace_export();
    uint8_t exported = cjgui_internal_renderer_finalize_owner_trace();
    assert(exported == ((failOutput || priorSnapshot) ? 3 : 2));
    assert(atomic_load(&gCjguiOwnerTraceExportState) == exported);
    printf("CLEANUP_TAIL_DONE pid=%d export_state=%u\n", getpid(), exported);
    fflush(stdout);
    assert(cjgui_internal_renderer_complete_application_cleanup(ticket) == 1);
    assert(cjgui_internal_renderer_complete_application_cleanup(ticket) == 0);
    return NULL;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        failOutput = argc > 1 && strcmp(argv[1], "fail-output") == 0;
        priorSnapshot = argc > 1 && strcmp(argv[1], "prior-snapshot") == 0;
        setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
        setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
        NSApplication *app = NSApplication.sharedApplication;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        CjguiInstallApplicationTerminationDelegate(app);
        ticket = cjgui_internal_renderer_acquire_application_cleanup();
        assert(ticket != 0);
        assert(cjgui_internal_renderer_complete_application_cleanup(ticket + 1) == 0);
        pthread_t worker;
        assert(pthread_create(&worker, NULL, cleanupWorker, NULL) == 0);
        [app run];
        assert(gCjguiApplicationCleanupCount == 0 && gCjguiApplicationStopDelivered);
        pthread_join(worker, NULL);
        printf("APPKIT_RETURNED pid=%d cleanup_gate_checks=5 failure_injected=%u\n", getpid(), failOutput);
        fflush(stdout);
        return 0;
    }
}
