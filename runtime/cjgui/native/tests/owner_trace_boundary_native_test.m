// Controlled boundary discrimination, not a normal-performance measurement.
#import "../cjgui_internal_renderer.m"
#include <assert.h>
#include <stdio.h>
#include <time.h>

static void delay(void) {
    struct timespec wait = {.tv_sec = 0, .tv_nsec = 12000000};
    nanosleep(&wait, NULL);
}

int main(void) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
    uint64_t tid = 0;
    assert(pthread_threadid_np(NULL, &tid) == 0 && tid != 0);
    cjgui_internal_renderer_owner_trace_boundary(7, 91, CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 1, 0, 0, UINT64_MAX);
    uint64_t span = cjgui_internal_renderer_owner_trace_managed_record(CJGUI_OWNER_TRACE_TURN_BEGIN,
        7, 91, 0, 0, UINT64_MAX, 0, 0, 123, 0);
    cjgui_internal_renderer_owner_trace_boundary(7, 91, CJGUI_OWNER_PHASE_TRACE_MANAGED_ID_BEFORE, 2, 0, 0, UINT64_MAX);
    delay();
    cjgui_internal_renderer_owner_trace_boundary(7, 91, CJGUI_OWNER_PHASE_TRACE_MANAGED_ID_AFTER, 2, 0, 12000000, 123);
    cjgui_internal_renderer_owner_trace_boundary(7, 91, CJGUI_OWNER_PHASE_DISPLAY_NATIVE_RETURN, 0, 75, 0, UINT64_MAX);
    delay();
    cjgui_internal_renderer_owner_trace_boundary(7, 91, CJGUI_OWNER_PHASE_DISPLAY_CJ_RETURN, 0, 75, 0, UINT64_MAX);
    cjgui_internal_renderer_owner_trace_managed_record(CJGUI_OWNER_TRACE_TURN_END,
        7, 91, 0, 0, UINT64_MAX, 0, span, 123, 0);
    cjgui_internal_renderer_owner_trace_boundary(7, 91, CJGUI_OWNER_PHASE_OWNER_OUTER_END, 2, 0, 0, UINT64_MAX);
    // The exact outer endpoints and no-watch boundaries use the calling OS
    // identity; an unavailable CPU identity is not silently substituted.
    uint64_t last = atomic_load(&gCjguiOwnerTraceNextSequence);
    NSUInteger boundaries = 0;
    for (uint64_t seq = 1; seq <= last; seq++) {
        CjguiOwnerTraceRecord *r = &gCjguiOwnerTraceRecords[(seq - 1) % CJGUI_OWNER_TRACE_CAPACITY];
        if (r->kind == CJGUI_OWNER_TRACE_BOUNDARY) {
            assert(r->threadId == tid);
            assert(!r->cpuValid);
            boundaries++;
        }
    }
    assert(boundaries == 7);
    assert(!gCjguiOwnerTraceSamplerStarted);
    fprintf(stderr, "fixture boundary_count=%lu actual_tid=%llu injected_segment_delays=2\n",
        (unsigned long)boundaries, (unsigned long long)tid);
    cjgui_internal_renderer_owner_trace_export();
    return 0;
}
