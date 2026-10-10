#define CJGUI_INTERNAL_RENDERER_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>

static pthread_mutex_t barrierLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t barrierCondition = PTHREAD_COND_INITIALIZER;
static BOOL borrowed, releaseBorrow, completed, hookUsed;
static int firstIndex;
static CjguiOwnerTraceWatch firstLease;
static uint64_t endTid;

static void borrowHook(int index, uint64_t lease) {
    pthread_mutex_lock(&barrierLock);
    if (!hookUsed) {
        hookUsed = YES;
        firstIndex = index;
        pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
        firstLease = gCjguiOwnerTraceWatches[index];
        pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);
        assert(firstLease.leaseEpoch == lease);
        borrowed = YES;
        pthread_cond_broadcast(&barrierCondition);
        while (!releaseBorrow) pthread_cond_wait(&barrierCondition, &barrierLock);
    }
    pthread_mutex_unlock(&barrierLock);
}

static void completeHook(int index, uint64_t lease) {
    pthread_mutex_lock(&barrierLock);
    if (index == firstIndex && lease == firstLease.leaseEpoch) {
        completed = YES;
        pthread_cond_broadcast(&barrierCondition);
    }
    pthread_mutex_unlock(&barrierLock);
}

static void *endOnAnotherThread(void *unused) {
    (void)unused;
    pthread_threadid_np(NULL, &endTid);
    CjguiOwnerTraceEndWatch(1, 800, UINT64_MAX, 7, 91, 0, 0, 4);
    return NULL;
}

int main(void) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "1", 1);
    thread_t original = mach_thread_self();
    mach_port_urefs_t refsBefore = 0, refsAfter = 0;
    assert(mach_port_get_refs(mach_task_self(), original, MACH_PORT_RIGHT_SEND, &refsBefore) == KERN_SUCCESS);
    gCjguiOwnerTraceBorrowHook = borrowHook;
    gCjguiOwnerTraceCompleteHook = completeHook;
    CjguiOwnerTraceBeginWatch(1, 800, 7, 91, 0, 0, 4, 0, 11);
    pthread_mutex_lock(&barrierLock);
    while (!borrowed) pthread_cond_wait(&barrierCondition, &barrierLock);
    pthread_mutex_unlock(&barrierLock);
    pthread_t ender;
    assert(pthread_create(&ender, NULL, endOnAnotherThread, NULL) == 0);
    pthread_join(ender, NULL);
    // End returned while the actual sampler remains blocked before suspend.
    assert(!releaseBorrow && !completed && endTid != firstLease.ownerThreadId);
    pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
    assert(gCjguiOwnerTraceWatches[firstIndex].state == CjguiTraceWatchRetired);
    assert(gCjguiOwnerTraceWatches[firstIndex].ownerThread == firstLease.ownerThread);
    pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);
    for (uint64_t i = 1; i < CJGUI_OWNER_TRACE_WATCH_CAPACITY; i++)
        CjguiOwnerTraceBeginWatch(1, 800 + i, 7, 91, 0, 0, 4, 0, 11);
    uint64_t dropped = atomic_load(&gCjguiOwnerTraceWatchDropped);
    CjguiOwnerTraceBeginWatch(1, 999, 7, 91, 0, 0, 4, 0, 11);
    assert(atomic_load(&gCjguiOwnerTraceWatchDropped) == dropped + 1);
    CjguiOwnerTraceEndWatch(1, 800, 11, 7, 91, 0, 0, 9); // generation changed, duplicate cannot steal lease
    assert(gCjguiOwnerTraceWatches[firstIndex].leaseEpoch == firstLease.leaseEpoch);
    pthread_mutex_lock(&barrierLock);
    releaseBorrow = YES;
    pthread_cond_broadcast(&barrierCondition);
    while (!completed) pthread_cond_wait(&barrierCondition, &barrierLock);
    pthread_mutex_unlock(&barrierLock);
    CjguiOwnerTraceBeginWatch(1, 900, 7, 92, 0, 0, 5, 0, 11);
    pthread_mutex_lock(&gCjguiOwnerTraceWatchLock);
    uint64_t newLease = gCjguiOwnerTraceWatches[firstIndex].leaseEpoch;
    assert(newLease != firstLease.leaseEpoch && gCjguiOwnerTraceWatches[firstIndex].key == 900);
    pthread_mutex_unlock(&gCjguiOwnerTraceWatchLock);
    CjguiOwnerTraceCompleteWatchSample(firstIndex, &firstLease, YES); // late completion
    CjguiOwnerTraceReleaseWatchSlot(firstIndex, firstLease.leaseEpoch); // stale release
    assert(gCjguiOwnerTraceWatches[firstIndex].leaseEpoch == newLease);
    for (uint64_t i = 1; i < CJGUI_OWNER_TRACE_WATCH_CAPACITY; i++)
        CjguiOwnerTraceEndWatch(1, 800 + i, 11, 7, 91, 0, 0, 4);
    CjguiOwnerTraceEndWatch(1, 900, 11, 7, 92, 0, 0, 5);
    CjguiOwnerTraceStopSampler();
    assert(gCjguiOwnerTraceSamplerState == CjguiTraceSamplerStopped);
    dropped = atomic_load(&gCjguiOwnerTraceWatchDropped);
    CjguiOwnerTraceBeginWatch(1, 1000, 7, 92, 0, 0, 5, 0, 11);
    assert(!gCjguiOwnerTraceSamplerStarted && atomic_load(&gCjguiOwnerTraceWatchDropped) == dropped + 1);
    assert(mach_port_get_refs(mach_task_self(), original, MACH_PORT_RIGHT_SEND, &refsAfter) == KERN_SUCCESS);
    assert(refsBefore == refsAfter);
    assert(atomic_load(&gCjguiOwnerTraceResumeUnresolved) == 0);
    mach_port_deallocate(mach_task_self(), original);
    fprintf(stderr, "fixture retirement_checks=9 end_returned_before_borrow_release=1 capacity=%u send_refs_before=%u send_refs_after=%u registration_tid=%llu end_tid=%llu\n",
        CJGUI_OWNER_TRACE_WATCH_CAPACITY, refsBefore, refsAfter,
        (unsigned long long)firstLease.ownerThreadId, (unsigned long long)endTid);
    assert(cjgui_internal_renderer_finalize_owner_trace() == 2);
    return 0;
}
