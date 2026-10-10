// Bounded trace sideband and EndWatch retirement probe. Supplied managed
// IDs are transport probes only; normal Cangjie must verify its own ID.
#import "../cjgui_internal_renderer.m"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static const uint64_t kWaitSession = 77;
static const uint64_t kWaitTurn = 123;
static const uint64_t kWaitRequest = 456;
static const uint64_t kWaitKey = 700;
static const uint64_t kManagedProbeId = 424242;
static pthread_mutex_t gSignalLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gSignalCondition = PTHREAD_COND_INITIALIZER;
static BOOL gWaitStarted;
static BOOL gRegistrationLockHeld;
static BOOL gEndReturned;

static NSUInteger activeWatchCount(void) {
    NSUInteger count = 0;
    pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
    for (NSUInteger i = 0; i < CJGUI_OWNER_TRACE_WATCH_CAPACITY; i++)
        if (gCjguiOwnerTraceWatches[i].active) count++;
    pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);
    return count;
}

static void *releaseSamplingWatch(void *unused) {
    (void)unused;
    pthread_mutex_lock(&gSignalLock);
    gWaitStarted = YES;
    pthread_cond_signal(&gSignalCondition);
    while (!gEndReturned) pthread_cond_wait(&gSignalCondition, &gSignalLock);
    pthread_mutex_unlock(&gSignalLock);
    CjguiOwnerTraceWatch captured = {0};
    int selected = -1;
    pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
    for (NSUInteger i = 0; i < CJGUI_OWNER_TRACE_WATCH_CAPACITY; i++) {
        CjguiOwnerTraceWatch *watch = &gCjguiOwnerTraceWatches[i];
        if (watch->state == CjguiTraceWatchRetired && watch->kind == 1 && watch->key == kWaitKey) {
            captured = *watch;
            selected = (int)i;
            break;
        }
    }
    pthread_cond_broadcast(&gCjguiOwnerTraceWatchCondition);
    pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);
    if (selected >= 0) CjguiOwnerTraceCompleteWatchSample(selected, &captured, YES);
    return NULL;
}

static void *holdRegistrationLock(void *unused) {
    (void)unused;
    pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
    pthread_mutex_lock(&gSignalLock);
    gRegistrationLockHeld = YES;
    pthread_cond_signal(&gSignalCondition);
    pthread_mutex_unlock(&gSignalLock);
    struct timespec delay = {.tv_sec = 0, .tv_nsec = 20000000};
    nanosleep(&delay, NULL);
    pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);
    return NULL;
}

int main(void) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);

    NSUInteger before = activeWatchCount();
    uint64_t start = cjgui_internal_renderer_owner_trace_managed_record(
        CJGUI_OWNER_TRACE_PHASE_BEGIN, 9, 10, 0, 0, 2,
        CJGUI_OWNER_PHASE_BUILD_DIAG_FORMAT, 0, kManagedProbeId, 0);
    cjgui_internal_renderer_owner_trace_managed_record(
        CJGUI_OWNER_TRACE_PHASE_END, 9, 10, 0, 0, 2,
        CJGUI_OWNER_PHASE_BUILD_DIAG_FORMAT, start, kManagedProbeId, 0);
    (void)cjgui_internal_renderer_owner_trace_managed_record(
        CJGUI_OWNER_TRACE_OBSERVATION_SCALAR, 9, 10, 0, 0, 2,
        CJGUI_OWNER_PHASE_BUILD_DIAG_FORMAT, 2, 0, 0);
    NSUInteger after = activeWatchCount();

    // Legacy/native-only callers remain explicitly unknown.
    (void)cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,
        9, 10, 0, 0, 2, CJGUI_OWNER_PHASE_BUILD_DIAG_WRITE, 1);

    setenv("CJGUI_OWNER_THREAD_SAMPLES", "1", 1);
    pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
    int freeIndex = -1;
    for (int i = 0; i < CJGUI_OWNER_TRACE_WATCH_CAPACITY; i++) {
        if (!gCjguiOwnerTraceWatches[i].active) { freeIndex = i; break; }
    }
    if (freeIndex < 0) return 2;
    gCjguiOwnerTraceWatches[freeIndex] = (CjguiOwnerTraceWatch){
        .active = YES, .sampling = YES, .state = CjguiTraceWatchSampling,
        .leaseEpoch = UINT64_MAX - 2, .kind = 1, .key = kWaitKey,
        .session = kWaitSession, .turn = kWaitTurn, .request = kWaitRequest,
        .dispatch = 900, .generation = 8,
        .phase = CJGUI_OWNER_PHASE_BUILD_DIAG_FORMAT,
        .ownerThread = MACH_PORT_NULL, .ownerThreadId = 0,
    };
    pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);

    pthread_t signaler;
    if (pthread_create(&signaler, NULL, releaseSamplingWatch, NULL) != 0) return 3;
    pthread_mutex_lock(&gSignalLock);
    while (!gWaitStarted) pthread_cond_wait(&gSignalCondition, &gSignalLock);
    pthread_mutex_unlock(&gSignalLock);

    (void)cjgui_internal_renderer_owner_trace_managed_record(
        CJGUI_OWNER_TRACE_TURN_END, kWaitSession, kWaitTurn, kWaitRequest, 0, 8,
        CJGUI_OWNER_PHASE_UNKNOWN, kWaitKey, kManagedProbeId, 1);
    pthread_mutex_lock(&gSignalLock);
    gEndReturned = YES;
    pthread_cond_broadcast(&gSignalCondition);
    pthread_mutex_unlock(&gSignalLock);
    pthread_join(signaler, NULL);

    // A distinct injected wait precedes any watched operation. Registration
    // must be attributable separately from the operation and EndWatch wait.
    pthread_t registrationHolder;
    if (pthread_create(&registrationHolder, NULL, holdRegistrationLock, NULL) != 0) return 5;
    pthread_mutex_lock(&gSignalLock);
    while (!gRegistrationLockHeld) pthread_cond_wait(&gSignalCondition, &gSignalLock);
    pthread_mutex_unlock(&gSignalLock);
    uint64_t preparation = cjgui_internal_renderer_owner_trace_managed_record(
        CJGUI_OWNER_TRACE_PHASE_BEGIN, kWaitSession, kWaitTurn, kWaitRequest, 0, 8,
        CJGUI_OWNER_PHASE_REFRESH_PREPARE_PACKET, 0, kManagedProbeId, 1);
    cjgui_internal_renderer_owner_trace_managed_record(
        CJGUI_OWNER_TRACE_PHASE_END, kWaitSession, kWaitTurn, kWaitRequest, 0, 8,
        CJGUI_OWNER_PHASE_REFRESH_PREPARE_PACKET, preparation, kManagedProbeId, 1);
    pthread_join(registrationHolder, NULL);
    CjguiOwnerTraceStopSampler();

    fprintf(stderr, "fixture managed_sideband_id=%llu watch_count_before=%lu watch_count_after=%lu end_returned_before_sampling_release=1\n",
        (unsigned long long)kManagedProbeId, (unsigned long)before, (unsigned long)after);
    fprintf(stderr, "fixture registration_wait_injected_ns=20000000\n");
    (void)cjgui_internal_renderer_finalize_owner_trace();
    return before == after && after == 0 && activeWatchCount() == 0 ? 0 : 4;
}
