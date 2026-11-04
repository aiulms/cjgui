// Controlled retention/identity test; it does not manufacture a GUI input.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>

static void turn_begin(uint64_t turn) {
    cjgui_internal_renderer_owner_trace_set_turn(turn);
    cjgui_internal_renderer_owner_trace_boundary(0, turn, CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,
        0, 0, 0, UINT64_MAX);
}
static void turn_end(uint64_t turn) {
    cjgui_internal_renderer_owner_trace_boundary(0, turn, CJGUI_OWNER_PHASE_OWNER_OUTER_END,
        0, 0, 0, UINT64_MAX);
}
int main(int argc, const char **argv) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
    BOOL overflow = argc > 1 && strcmp(argv[1], "capacity") == 0;
    BOOL sourceMissing = argc > 1 && strcmp(argv[1], "source") == 0;
    BOOL unbound = argc > 1 && strcmp(argv[1], "close") == 0;
    turn_begin(1);
    uint64_t rawNs = cjgui_internal_renderer_owner_trace_ns();
    uint64_t rawMarker = cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,
        1, 1, 0, 0, 19, CJGUI_OWNER_PHASE_PROJECTION_INPUT_ADMISSION, 0);
    cjgui_internal_renderer_owner_trace_target_begin(1, 19, 2, rawNs);
    assert(atomic_load(&gCjguiOwnerTraceTargetState) == 1);
    cjgui_internal_renderer_owner_trace_target_bind(1, 20, 5);
    assert(atomic_load(&gCjguiOwnerTraceTargetState) == 1);
    if (!unbound) cjgui_internal_renderer_owner_trace_target_bind(1, 19, 5);
    turn_end(1);
    if (unbound) {
        assert(atomic_load(&gCjguiOwnerTraceTargetState) == 1);
        fprintf(stderr, "TARGET_CONTROL unbound_close=1\n");
        return cjgui_internal_renderer_finalize_owner_trace() == 2 ? 0 : 1;
    }
    turn_begin(2);
    uint64_t unknown = CjguiOwnerTraceAppendAtWithOwnerIdentity(CJGUI_OWNER_TRACE_PHASE_BEGIN,
        1, 2, 5, 0, 19, CJGUI_OWNER_PHASE_UNKNOWN, 0, rawNs + 1, 17, 0, 0, NO, UINT64_MAX);
    if (overflow) for (unsigned i = 0; i < 9000; i++)
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,
            1, 2, 5, 0, 19, CJGUI_OWNER_PHASE_UNKNOWN, i);
    if (sourceMissing) for (unsigned i = 0; i < CJGUI_OWNER_TRACE_CAPACITY + 8; i++)
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,
            1, 2, 5, 0, 19, CJGUI_OWNER_PHASE_UNKNOWN, i);
    cjgui_internal_renderer_owner_trace_target_accepted(1, 19, 6, 14, 14);
    assert(atomic_load(&gCjguiOwnerTraceTargetState) == 2);
    cjgui_internal_renderer_owner_trace_target_accepted(1, 19, 5, 14, 14);
    assert(atomic_load(&gCjguiOwnerTraceTargetState) == 3);
    assert(atomic_load(&gCjguiOwnerTraceInteractionNext) == 0);
    turn_end(2);
    assert(atomic_load(&gCjguiOwnerTraceTargetState) == 4);
    assert(gCjguiOwnerTraceTargetFirst <= rawMarker && gCjguiOwnerTraceTargetAcceptedTurn == 2);
    BOOL sawRaw = NO, sawUnknown = NO;
    uint64_t count = MIN(atomic_load(&gCjguiOwnerTraceInteractionNext),
        (uint64_t)CJGUI_OWNER_TRACE_INTERACTION_CAPACITY);
    for (uint64_t i = 0; i < count; i++) {
        CjguiOwnerTraceRecord *r = &gCjguiOwnerTraceInteractionRecords[i];
        if (r->sequence == rawMarker) sawRaw = YES;
        if (r->sequence == unknown && !r->cpuValid && r->threadId == 17) sawUnknown = YES;
    }
    if (sourceMissing) {
        assert(!sawRaw && atomic_load(&gCjguiOwnerTraceInteractionSourceMissing) > 0);
    } else { assert(sawRaw && sawUnknown); }
    if (overflow) assert(count == CJGUI_OWNER_TRACE_INTERACTION_CAPACITY &&
        atomic_load(&gCjguiOwnerTraceInteractionDropped) > 0);
    fprintf(stderr, "TARGET_CONTROL sealed=1 records=%llu overflow=%d source_missing=%d cpu_unknown_preserved=%d\n",
        (unsigned long long)count, overflow, sourceMissing, sawUnknown);
    return cjgui_internal_renderer_finalize_owner_trace() == 2 ? 0 : 1;
}
