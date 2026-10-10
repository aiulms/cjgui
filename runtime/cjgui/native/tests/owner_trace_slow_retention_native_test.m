// Controlled record-retention test, not a natural owner budget result.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>
#include <unistd.h>

static int failures;
#define CHECK(condition, label) do { \
    BOOL ok = (condition); \
    fprintf(stderr, "OWNER_TRACE_BOUNDARY_RETENTION case=%s result=%s\n", \
        label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static CjguiOwnerTraceRecord *retainedBySequence(CjguiOwnerTraceRecord *records,
    uint64_t capacity, uint64_t nextOrdinal, uint64_t sourceSequence) {
    uint64_t first = nextOrdinal > capacity ? nextOrdinal - capacity : 0;
    for (uint64_t ordinal = first; ordinal < nextOrdinal; ++ordinal) {
        CjguiOwnerTraceRecord *record = &records[ordinal % capacity];
        if (atomic_load_explicit(&record->publishedSequence, memory_order_acquire) == ordinal + 1 &&
            record->sequence == sourceSequence) return record;
    }
    return NULL;
}

static CjguiOwnerTraceRecord *criticalBySequence(uint64_t sourceSequence) {
    return retainedBySequence(gCjguiOwnerTraceCriticalRecords, CJGUI_OWNER_TRACE_CRITICAL_CAPACITY,
        atomic_load_explicit(&gCjguiOwnerTraceCriticalNext, memory_order_acquire), sourceSequence);
}

static CjguiOwnerTraceRecord *activityBySequence(uint64_t sourceSequence) {
    return retainedBySequence(gCjguiOwnerTraceActivityRecords, CJGUI_OWNER_TRACE_ACTIVITY_CAPACITY,
        atomic_load_explicit(&gCjguiOwnerTraceActivityNext, memory_order_acquire), sourceSequence);
}

static void turn(uint64_t session, uint64_t identity, useconds_t delay, BOOL end) {
    cjgui_internal_renderer_owner_trace_boundary(session, identity,
        CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0, 0, 0, UINT64_MAX);
    usleep(delay);
    if (end) cjgui_internal_renderer_owner_trace_boundary(session, identity,
        CJGUI_OWNER_PHASE_OWNER_OUTER_END, 0, 0, 0, UINT64_MAX);
}
int main(void) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
    atomic_store_explicit(&gCjguiCoordinateSessionGeneration[0], 19, memory_order_release);
    atomic_store_explicit(&gCjguiCoordinateEpoch[0], 1, memory_order_release);
    turn(1, 1, 22000, YES);
    assert(atomic_load(&gCjguiOwnerTraceSlowTurn) == 1);
    turn(1, 2, 50000, NO);
    assert(atomic_load(&gCjguiOwnerTraceSlowTurn) == 1);
    turn(0, 3, 55000, YES);
    assert(atomic_load(&gCjguiOwnerTraceSlowTurn) == 1);
    turn(1, 4, 36000, YES);
    assert(atomic_load(&gCjguiOwnerTraceSlowTurn) == 4);
    turn(1, 5, 18000, YES);
    assert(atomic_load(&gCjguiOwnerTraceSlowTurn) == 4);
    printf("OWNER_TRACE_SLOW_RETENTION checks=5 retained_turn=4 work_ns=%llu controlled=1\n",
        (unsigned long long)atomic_load(&gCjguiOwnerTraceSlowWorkNs));
    // Boundary and idle facts are needed for full-window work calculation,
    // but by themselves must not activate whole-turn activity copying.
    uint64_t ownThread = 0;
    assert(pthread_threadid_np(NULL, &ownThread) == 0 && ownThread != 0);
    uint64_t activityBeforeBoundaryOnly = atomic_load(&gCjguiOwnerTraceActivityNext);
    uint64_t capturesBeforeBoundaryOnly = atomic_load(&gCjguiOwnerTraceActivityCaptureCount);
    uint64_t beginSequence = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    cjgui_internal_renderer_owner_trace_boundary(1, 6,
        CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0, 0, 0, UINT64_MAX);
    atomic_store(&gCjguiOwnerTraceCurrentTurn, 6);
    uint64_t boundaryIdleStarted = CjguiOwnerTraceNanoseconds();
    usleep(1000);
    uint64_t boundaryIdleEnded = CjguiOwnerTraceNanoseconds();
    uint64_t idleBeginSequence = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    CjguiTraceOwnerIdleWait(2, boundaryIdleStarted, boundaryIdleEnded);
    uint64_t endSequenceBefore = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    cjgui_internal_renderer_owner_trace_boundary(1, 6,
        CJGUI_OWNER_PHASE_OWNER_OUTER_END, 0, 0, 0, UINT64_MAX);
    uint64_t endSequence = 0;
    uint64_t mainLast = atomic_load(&gCjguiOwnerTraceNextSequence);
    for (uint64_t sequence = endSequenceBefore; sequence <= mainLast; ++sequence) {
        CjguiOwnerTraceRecord *record = &gCjguiOwnerTraceRecords[(sequence - 1) % CJGUI_OWNER_TRACE_CAPACITY];
        if (record->sequence == sequence && record->kind == CJGUI_OWNER_TRACE_BOUNDARY &&
            record->phase == CJGUI_OWNER_PHASE_OWNER_OUTER_END && record->turn == 6) {
            endSequence = sequence;
            break;
        }
    }
    uint64_t idleEndSequence = idleBeginSequence + 1;
    CjguiOwnerTraceRecord *retainedBegin = criticalBySequence(beginSequence);
    CjguiOwnerTraceRecord *retainedIdleBegin = criticalBySequence(idleBeginSequence);
    CjguiOwnerTraceRecord *retainedIdleEnd = criticalBySequence(idleEndSequence);
    CjguiOwnerTraceRecord *retainedEnd = criticalBySequence(endSequence);
    BOOL boundaryFactsRetained = retainedBegin && retainedIdleBegin && retainedIdleEnd && retainedEnd &&
        retainedBegin->kind == CJGUI_OWNER_TRACE_BOUNDARY &&
        retainedBegin->phase == CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN && retainedBegin->session == 1 &&
        retainedBegin->turn == 6 && retainedBegin->threadId == ownThread &&
        retainedIdleBegin->kind == CJGUI_OWNER_TRACE_IDLE_BEGIN &&
        retainedIdleEnd->kind == CJGUI_OWNER_TRACE_IDLE_END &&
        retainedIdleBegin->session == 2 && retainedIdleEnd->session == 2 &&
        retainedIdleBegin->turn == 6 && retainedIdleEnd->turn == 6 &&
        retainedIdleBegin->threadId == ownThread && retainedIdleEnd->threadId == ownThread &&
        retainedIdleBegin->span == idleBeginSequence && retainedIdleEnd->span == idleBeginSequence &&
        retainedIdleBegin->monoNs == boundaryIdleStarted && retainedIdleEnd->monoNs == boundaryIdleEnded &&
        retainedEnd->kind == CJGUI_OWNER_TRACE_BOUNDARY &&
        retainedEnd->phase == CJGUI_OWNER_PHASE_OWNER_OUTER_END && retainedEnd->session == 1 &&
        retainedEnd->turn == 6 && retainedEnd->threadId == ownThread;
    CHECK(boundaryFactsRetained,
        "boundary_only_outer_and_cross_session_idle_endpoints_directly_retained_in_critical_ring");
    CHECK(atomic_load(&gCjguiOwnerTraceActivityNext) == activityBeforeBoundaryOnly &&
        atomic_load(&gCjguiOwnerTraceActivityCaptureCount) == capturesBeforeBoundaryOnly,
        "boundary_only_turn_does_not_trigger_activity_copy");

    // One application owner turn can pump more than one native session.
    // Retention must preserve the second session's real idle endpoints and
    // their original OS identity; otherwise later analysis charges that
    // missing idle as work after the rolling source ring wraps.
    cjgui_internal_renderer_owner_trace_boundary(1, 6,
        CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0, 0, 0, UINT64_MAX);
    uint64_t marker = cjgui_internal_renderer_owner_trace_record(
        CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, 1, 6, 3, 1, 19,
        CJGUI_OWNER_PHASE_SELECTION_INSTALLED, 0);
    atomic_store(&gCjguiOwnerTraceCurrentTurn, 6);
    uint64_t started = CjguiOwnerTraceNanoseconds();
    usleep(2000);
    uint64_t ended = CjguiOwnerTraceNanoseconds();
    uint64_t activityBeforeSelection = atomic_load(&gCjguiOwnerTraceActivityNext);
    uint64_t capturesBeforeSelection = atomic_load(&gCjguiOwnerTraceActivityCaptureCount);
    uint64_t idleFirst = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    CjguiTraceOwnerIdleWait(2, started, ended);
    cjgui_internal_renderer_owner_trace_boundary(1, 6,
        CJGUI_OWNER_PHASE_OWNER_OUTER_END, 0, 0, 0, UINT64_MAX);
    NSUInteger retainedIdle = 0;
    for (uint64_t i = 0; i < atomic_load(&gCjguiOwnerTraceActivityNext); i++) {
        CjguiOwnerTraceRecord *r = &gCjguiOwnerTraceActivityRecords[
            i % CJGUI_OWNER_TRACE_ACTIVITY_CAPACITY];
        if (r->sequence != idleFirst && r->sequence != idleFirst + 1) continue;
        assert(r->session == 2 && r->turn == 6 && r->threadId == ownThread);
        assert(r->span == idleFirst);
        assert(r->monoNs == (r->sequence == idleFirst ? started : ended));
        retainedIdle++;
    }
    fprintf(stderr, "OWNER_TRACE_CROSS_SESSION_IDLE retained=%lu expected=2 marker=%llu controlled=1\n",
        (unsigned long)retainedIdle, (unsigned long long)marker);
    assert(retainedIdle == 2);
    BOOL selectionActivityOnce = atomic_load(&gCjguiOwnerTraceActivityCaptureCount) ==
        capturesBeforeSelection + 1 && atomic_load(&gCjguiOwnerTraceActivityNext) > activityBeforeSelection &&
        activityBySequence(marker) != NULL && activityBySequence(idleFirst) != NULL &&
        activityBySequence(idleFirst + 1) != NULL;
    CHECK(selectionActivityOnce,
        "selection_marker_captures_exactly_one_full_turn_with_cross_session_idle");

    // The ordinary input-admission marker remains a separate single activity
    // trigger after adding retention-only boundary endpoints.
    uint64_t inputCapturesBefore = atomic_load(&gCjguiOwnerTraceActivityCaptureCount);
    uint64_t inputActivityBefore = atomic_load(&gCjguiOwnerTraceActivityNext);
    uint64_t inputOuterBegin = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    cjgui_internal_renderer_owner_trace_boundary(1, 7,
        CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0, 0, 0, UINT64_MAX);
    atomic_store(&gCjguiOwnerTraceCurrentTurn, 7);
    uint64_t inputMarker = cjgui_internal_renderer_owner_trace_record(
        CJGUI_OWNER_TRACE_PHASE_BEGIN, 1, 7, 4, 0, 19,
        CJGUI_OWNER_PHASE_PROJECTION_INPUT_ADMISSION, 0);
    uint64_t inputStarted = CjguiOwnerTraceNanoseconds();
    usleep(1000);
    uint64_t inputEnded = CjguiOwnerTraceNanoseconds();
    uint64_t inputIdleFirst = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    CjguiTraceOwnerIdleWait(2, inputStarted, inputEnded);
    cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_PHASE_END, 1, 7, 4, 0, 19,
        CJGUI_OWNER_PHASE_PROJECTION_INPUT_ADMISSION, inputMarker);
    uint64_t inputOuterEndBefore = atomic_load(&gCjguiOwnerTraceNextSequence) + 1;
    cjgui_internal_renderer_owner_trace_boundary(1, 7,
        CJGUI_OWNER_PHASE_OWNER_OUTER_END, 0, 0, 0, UINT64_MAX);
    CHECK(atomic_load(&gCjguiOwnerTraceActivityCaptureCount) == inputCapturesBefore + 1 &&
        atomic_load(&gCjguiOwnerTraceActivityNext) > inputActivityBefore &&
        activityBySequence(inputOuterBegin) != NULL && activityBySequence(inputMarker) != NULL &&
        activityBySequence(inputIdleFirst) != NULL && activityBySequence(inputIdleFirst + 1) != NULL,
        "input_admission_marker_still_captures_one_full_turn_and_idle");
    uint64_t inputOuterEnd = 0;
    mainLast = atomic_load(&gCjguiOwnerTraceNextSequence);
    for (uint64_t sequence = inputOuterEndBefore; sequence <= mainLast; ++sequence) {
        CjguiOwnerTraceRecord *record = &gCjguiOwnerTraceRecords[(sequence - 1) % CJGUI_OWNER_TRACE_CAPACITY];
        if (record->sequence == sequence && record->kind == CJGUI_OWNER_TRACE_BOUNDARY &&
            record->phase == CJGUI_OWNER_PHASE_OWNER_OUTER_END && record->turn == 7) {
            inputOuterEnd = sequence;
            break;
        }
    }
    CHECK(inputOuterEnd != 0 && activityBySequence(inputOuterEnd) != NULL,
        "input_activity_contains_real_outer_end_endpoint");
    fprintf(stderr, "OWNER_TRACE_BOUNDARY_RETENTION summary failures=%d controlled=1\n", failures);
    return failures ? 1 : 0;
}
