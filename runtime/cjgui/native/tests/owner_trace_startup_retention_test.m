// The first owner call starts without a native token and ends on that original
// identity. Trace children may use the newly created token. Their transport
// identities must survive general-ring wrap; retention must not re-label them.
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <string.h>

static int failures;
static void check(const char *name, BOOL passed) {
    printf("%s %s\n", passed ? "PASS" : "FAIL", name);
    if (!passed) failures++;
}

static CjguiOwnerTraceRecord *retained(uint64_t sequence) {
    uint64_t count = MIN(atomic_load(&gCjguiOwnerTraceStartupCount),
        (uint64_t)CJGUI_OWNER_TRACE_STARTUP_CAPACITY);
    for (uint64_t i = 0; i < count; i++) {
        CjguiOwnerTraceRecord *record = &gCjguiOwnerTraceStartupRecords[i];
        if (atomic_load(&record->publishedSequence) == i + 1 &&
            record->sequence == sequence) return record;
    }
    return NULL;
}

static uint64_t boundary(uint64_t session, uint64_t turn, uint32_t phase) {
    return cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_BOUNDARY,
        session, turn, 0, 0, UINT64_MAX, phase, 0);
}

int main(int argc, const char **argv) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
    uint64_t begin = boundary(0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN);
    if (argc > 1 && strcmp(argv[1], "capacity") == 0) {
        for (uint64_t i = 0; i <= CJGUI_OWNER_TRACE_STARTUP_CAPACITY; i++)
            (void)cjgui_internal_renderer_owner_trace_record(
                CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, 7, 1, 23, 0, 4,
                CJGUI_OWNER_PHASE_UNKNOWN, i);
        (void)boundary(0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_END);
        check("fixed_capacity_is_bounded",
            MIN(atomic_load(&gCjguiOwnerTraceStartupCount),
                (uint64_t)CJGUI_OWNER_TRACE_STARTUP_CAPACITY) == CJGUI_OWNER_TRACE_STARTUP_CAPACITY);
        check("capacity_loss_is_reported",
            atomic_load(&gCjguiOwnerTraceStartupDropped) > 0);
        check("matching_end_closes_even_when_full",
            atomic_load(&gCjguiOwnerTraceStartupState) == 2);
        check("original_begin_identity_retained", retained(begin) && retained(begin)->session == 0);
    } else {
        uint64_t child = cjgui_internal_renderer_owner_trace_managed_record(
            CJGUI_OWNER_TRACE_PHASE_BEGIN, 7, 1, 23, 31, 4,
            CJGUI_OWNER_PHASE_WORKLOAD_DIAGNOSTIC_FINALIZE, 0, 424242, 0);
        uint64_t foreignEnd = boundary(8, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_END);
        check("other_window_end_does_not_close_bootstrap",
            atomic_load(&gCjguiOwnerTraceStartupState) == 1);
        uint64_t childEnd = cjgui_internal_renderer_owner_trace_managed_record(
            CJGUI_OWNER_TRACE_PHASE_END, 7, 1, 23, 31, 4,
            CJGUI_OWNER_PHASE_WORKLOAD_DIAGNOSTIC_FINALIZE, child, 424242, 0);
        uint64_t end = boundary(0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_END);
        uint64_t late = cjgui_internal_renderer_owner_trace_record(
            CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, 7, 1, 23, 31, 4,
            CJGUI_OWNER_PHASE_UNKNOWN, 99);
        for (uint64_t i = 0; i < CJGUI_OWNER_TRACE_CAPACITY + 1; i++)
            (void)cjgui_internal_renderer_owner_trace_record(
                CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, 9, 2, 0, 0, 5,
                CJGUI_OWNER_PHASE_UNKNOWN, i);
        check("general_ring_actually_wrapped",
            atomic_load(&gCjguiOwnerTraceNextSequence) > CJGUI_OWNER_TRACE_CAPACITY);
        CjguiOwnerTraceRecord *first = retained(child), *last = retained(childEnd);
        check("new_native_token_child_retained", first != NULL && last != NULL);
        check("child_transport_identity_unchanged", first && last &&
            first->session == 7 && last->session == 7 && first->turn == 1 &&
            first->generation == 4 && first->request == 23 && first->dispatch == 31 &&
            first->managedThreadId == 424242 && last->span == child);
        check("concurrent_fact_retains_its_own_identity",
            retained(foreignEnd) && retained(foreignEnd)->session == 8);
        check("bootstrap_end_retains_original_identity",
            retained(begin) && retained(end) && retained(begin)->session == 0 && retained(end)->session == 0);
        check("late_child_not_part_of_startup", retained(late) == NULL);
        check("lossless_short_scope_reports_no_drop",
            atomic_load(&gCjguiOwnerTraceStartupDropped) == 0);
    }
    (void)cjgui_internal_renderer_finalize_owner_trace();
    return failures == 0 ? 0 : 1;
}
