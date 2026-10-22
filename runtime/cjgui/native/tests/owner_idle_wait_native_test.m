// Only the global wake/absolute-deadline seam. No UI or event injection.
#define CJGUI_OWNER_PUMP_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

static uint64_t elapsedNs;
static int32_t waitStatus;
static uint64_t observedBeforeSignal;
static BOOL usePreSignal;
static BOOL useFiniteDeadline;
static BOOL useInfiniteDeadline;
static void *waitForActualWork(void *unused) {
    (void)unused;
    uint64_t revision = usePreSignal ? observedBeforeSignal : cjgui_internal_renderer_owner_work_revision();
    uint64_t start = cjgui_internal_renderer_owner_clock_ns();
    uint64_t idle = 0;
#ifdef CJGUI_OWNER_IDLE_WAIT_VERSION
    waitStatus = cjgui_internal_renderer_owner_wait_idle_work(revision,
        useInfiniteDeadline ? UINT64_MAX : start + (useFiniteDeadline ?
            UINT64_C(20000000) : UINT64_C(1000000000)), &idle);
#else
    waitStatus = cjgui_internal_renderer_owner_wait_work(revision,
        start + UINT64_C(1000000000), &idle);
#endif
    elapsedNs = cjgui_internal_renderer_owner_clock_ns() - start;
    return NULL;
}

int main(void) {
    @autoreleasepool {
        pthread_t worker;
        if (pthread_create(&worker, NULL, waitForActualWork, NULL)) return 2;
        usleep(60000);
        cjgui_internal_renderer_owner_notify_work();
        pthread_join(worker, NULL);
        BOOL actualWork = waitStatus == CJGUI_INTERNAL_RENDERER_OK &&
            elapsedNs >= UINT64_C(35000000) && elapsedNs < UINT64_C(500000000);
        fprintf(stdout, "owner_idle waits_for_actual_signal=%d elapsed_ns=%llu status=%d\n",
            actualWork, (unsigned long long)elapsedNs, waitStatus);
        BOOL allPassed=actualWork;
#ifdef CJGUI_OWNER_IDLE_WAIT_VERSION
        observedBeforeSignal=cjgui_internal_renderer_owner_work_revision();
        cjgui_internal_renderer_owner_notify_work();
        usePreSignal=YES;
        if(pthread_create(&worker,NULL,waitForActualWork,NULL))return 2;
        pthread_join(worker,NULL);
        BOOL beforeWait=waitStatus==CJGUI_INTERNAL_RENDERER_OK && elapsedNs<UINT64_C(100000000);
        fprintf(stdout,"owner_idle signal_before_wait_not_lost=%d elapsed_ns=%llu\n",
            beforeWait,(unsigned long long)elapsedNs);
        allPassed &= beforeWait;
        usePreSignal=NO;useFiniteDeadline=YES;
        if(pthread_create(&worker,NULL,waitForActualWork,NULL))return 2;
        pthread_join(worker,NULL);
        BOOL deadline=waitStatus==CJGUI_INTERNAL_RENDERER_OK && elapsedNs>=UINT64_C(15000000) &&
            elapsedNs<UINT64_C(250000000);
        fprintf(stdout,"owner_idle finite_deadline=%d elapsed_ns=%llu\n",deadline,(unsigned long long)elapsedNs);
        allPassed &= deadline;
        useFiniteDeadline=NO;useInfiniteDeadline=YES;
        if(pthread_create(&worker,NULL,waitForActualWork,NULL))return 2;
        usleep(60000);cjgui_internal_renderer_owner_notify_work();pthread_join(worker,NULL);
        BOOL infinite=waitStatus==CJGUI_INTERNAL_RENDERER_OK && elapsedNs>=UINT64_C(35000000) &&
            elapsedNs<UINT64_C(500000000);
        fprintf(stdout,"owner_idle no_deadline_cancellable_by_work=%d elapsed_ns=%llu\n",
            infinite,(unsigned long long)elapsedNs);
        allPassed &= infinite;
#endif
        return allPassed ? 0 : 1;
    }
}
