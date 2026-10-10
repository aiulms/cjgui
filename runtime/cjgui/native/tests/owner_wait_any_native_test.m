// Native acceptance for the package-private owner wait-any condition. It uses
// two real renderer sessions and the actual bounded text worker completion.
#define CJGUI_ASYNC_MULTILINE_MEASURE_TESTING 1
#define CJGUI_OWNER_NOTIFY_WORK_IMPLEMENTED 1
#import "../cjgui_internal_renderer.m"
#import "../cjgui_async_multiline_measure.m"

#include <stdio.h>
#include <unistd.h>
#include <stdatomic.h>

extern uint64_t cjgui_internal_renderer_owner_work_revision(void);
extern int32_t cjgui_internal_renderer_owner_wait_work(uint64_t observedRevision,
    uint64_t absoluteDeadlineNs, uint64_t *outIdleWaitNs);
extern void cjgui_internal_renderer_owner_notify_work(void);
extern uint64_t cjgui_internal_renderer_owner_clock_ns(void);

static const uint64_t kNoneWaitNs = UINT64_C(8000000);
static const uint64_t kReadyWaitNs = UINT64_C(16000000);
static const uint64_t kStaleWaitNs = UINT64_C(6000000);
static const uint32_t kHostAEvent = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT;
static const uint32_t kHostBEvent = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO;
static _Atomic(bool) gEmptyPumpStarted = false;
static _Atomic(uint32_t) gEmptyPumpFinished = 0;
static _Atomic(bool) gReadyPumpFinished = false;
static _Atomic(bool) gReadyPumpReturnedExpected = false;

@interface CjguiOwnerWaitAnyProbe : NSObject
@property(nonatomic, assign) uint64_t hostA;
@property(nonatomic, assign) uint64_t hostB;
@property(nonatomic, assign) uint64_t observedRevision;
@property(nonatomic, assign) uint64_t staleGeneration;
@property(nonatomic, assign) CjguiAsyncMultilineMeasureHandle measureHandle;
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, strong) dispatch_queue_t waitQueue;
@property(nonatomic, strong) dispatch_queue_t pumpQueue;
@end

@implementation CjguiOwnerWaitAnyProbe

- (void)check:(BOOL)condition message:(const char *)message {
    if (condition) return;
    self.failed = YES;
    fprintf(stderr, "OWNER_WAIT_ANY FAIL: %s\n", message);
}

- (void)waitFrom:(uint64_t)revision durationNs:(uint64_t)durationNs
      completion:(void (^)(int32_t, uint64_t, uint64_t, uint64_t))completion {
    dispatch_async(self.waitQueue, ^{
        uint64_t started = cjgui_internal_renderer_owner_clock_ns();
        uint64_t deadline = started > UINT64_MAX - durationNs
            ? UINT64_MAX : started + durationNs;
        uint64_t idle = 0;
        int32_t status = cjgui_internal_renderer_owner_wait_work(revision, deadline, &idle);
        uint64_t ended = cjgui_internal_renderer_owner_clock_ns();
        uint64_t current = cjgui_internal_renderer_owner_work_revision();
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(status, ended >= started ? ended - started : UINT64_MAX, idle, current);
        });
    });
}

- (void)startNoneBroadcastCase {
    [self check:cjgui_internal_renderer_owner_wait_work(
        cjgui_internal_renderer_owner_work_revision(),
        cjgui_internal_renderer_owner_clock_ns(), NULL) == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD
        message:"main-thread wait-work did not return its named illegal-thread status"];
    atomic_store_explicit(&gEmptyPumpStarted, false, memory_order_release);
    atomic_store_explicit(&gEmptyPumpFinished, 0, memory_order_release);
    self.observedRevision = cjgui_internal_renderer_owner_work_revision();
    [self waitFrom:self.observedRevision durationNs:kNoneWaitNs completion:
        ^(int32_t status, uint64_t elapsed, uint64_t idle, uint64_t revisionAfter) {
            BOOL noneTicketsReady = NO;
            NSUInteger indexA = CjguiOwnerPumpTicketIndex(self.hostA);
            NSUInteger indexB = CjguiOwnerPumpTicketIndex(self.hostB);
            if (indexA != NSNotFound && indexB != NSNotFound) {
                pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
                CjguiOwnerPumpTicket *ticketA = &gCjguiOwnerPumpTickets[indexA];
                CjguiOwnerPumpTicket *ticketB = &gCjguiOwnerPumpTickets[indexB];
                noneTicketsReady = ticketA->state == CjguiOwnerPumpTicketReady &&
                    ticketA->session == self.hostA && ticketA->status == CJGUI_INTERNAL_RENDERER_OK &&
                    ticketA->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE &&
                    ticketB->state == CjguiOwnerPumpTicketReady &&
                    ticketB->session == self.hostB && ticketB->status == CJGUI_INTERNAL_RENDERER_OK &&
                    ticketB->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
                pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
            }
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        revisionAfter == self.observedRevision &&
                        elapsed >= UINT64_C(6000000) && elapsed <= UINT64_C(16000000) &&
                        idle >= UINT64_C(5000000) && noneTicketsReady
                message:"READY_NONE broadcast woke wait-any or refreshed its absolute deadline"];
            [self check:atomic_load_explicit(&gEmptyPumpFinished, memory_order_acquire) == 2
                message:"both real empty host ticket services did not publish READY_NONE"];
            printf("OWNER_WAIT_ANY_NONE status=%d elapsed_ns=%llu idle_ns=%llu revision_unchanged=1 none_broadcasts=2\n",
                status, (unsigned long long)elapsed, (unsigned long long)idle);
            [self retireEmptyHostBTicket];
        }];

    dispatch_async(self.pumpQueue, ^{
        atomic_store_explicit(&gEmptyPumpStarted, true, memory_order_release);
        CjguiInternalRendererEvent eventA = {0}, eventB = {0};
        CjguiInternalRendererStatus statusA = cjgui_internal_renderer_pump_event(
            self.hostA, 0, &eventA);
        CjguiInternalRendererStatus statusB = cjgui_internal_renderer_pump_event(
            self.hostB, 0, &eventB);
        if (statusA == CJGUI_INTERNAL_RENDERER_OK && eventA.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE &&
            statusB == CJGUI_INTERNAL_RENDERER_OK && eventB.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
            atomic_store_explicit(&gEmptyPumpFinished, 2, memory_order_release);
        }
    });
}

- (void)retireEmptyHostBTicket {
    dispatch_async(self.pumpQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(
            self.hostB, 0, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"empty READY_NONE host-B ticket did not retire before the real-event case"];
            [self startSecondHostReadyCase];
        });
    });
}

- (void)startSecondHostReadyCase {
    CJGuiInternalSession *ctxB = CjguiLookupSession(self.hostB);
    [self check:ctxB && CjguiEnqueueInteraction(ctxB, kHostBEvent, 0, @"", 0, 0)
        message:"could not enqueue a real event for the second live host"];
    self.observedRevision = cjgui_internal_renderer_owner_work_revision();
    atomic_store_explicit(&gReadyPumpFinished, false, memory_order_release);
    atomic_store_explicit(&gReadyPumpReturnedExpected, false, memory_order_release);
    dispatch_async(self.pumpQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(
            self.hostB, 0, &event);
        atomic_store_explicit(&gReadyPumpReturnedExpected,
            status == CJGUI_INTERNAL_RENDERER_OK &&
            event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE, memory_order_release);
        atomic_store_explicit(&gReadyPumpFinished, true, memory_order_release);
    });
    while (!atomic_load_explicit(&gReadyPumpFinished, memory_order_acquire)) usleep(100);
    [self check:atomic_load_explicit(&gReadyPumpReturnedExpected, memory_order_acquire)
        message:"host-B zero-timeout setup did not leave its real owner ticket pending"];
    [self waitFrom:self.observedRevision durationNs:kReadyWaitNs completion:
        ^(int32_t status, uint64_t elapsed, uint64_t idle, uint64_t revisionAfter) {
            NSUInteger index = CjguiOwnerPumpTicketIndex(self.hostB);
            BOOL liveReady = NO;
            if (index != NSNotFound) {
                pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
                CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
                liveReady = ticket->state == CjguiOwnerPumpTicketReady &&
                    ticket->session == self.hostB &&
                    ticket->sessionGeneration == CjguiOwnerPumpLiveSessionGeneration(self.hostB) &&
                    ticket->event.kind == kHostBEvent;
                pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
            }
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        revisionAfter != self.observedRevision && elapsed < kReadyWaitNs && liveReady &&
                        cjgui_internal_renderer_owner_pump_has_unconsumed_input(self.hostB) == 1
                message:"second-host READY event did not wake one shared wait while remaining unconsumed"];
            printf("OWNER_WAIT_ANY_SECOND_HOST status=%d elapsed_ns=%llu revision_changed=1 host_b_ready=1 host_a_ready=0\n",
                status, (unsigned long long)elapsed);
            [self startStaleGenerationCase];
        }];
}

- (void)startStaleGenerationCase {
    self.staleGeneration = CjguiOwnerPumpLiveSessionGeneration(self.hostB);
    [self check:self.staleGeneration != 0 &&
                cjgui_internal_renderer_destroy(self.hostB) == CJGUI_INTERNAL_RENDERER_OK
        message:"could not retire the live second host while preserving its old READY ticket"];
    NSUInteger index = CjguiOwnerPumpTicketIndex(self.hostB);
    BOOL oldReadyRetained = NO;
    if (index != NSNotFound) {
        pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
        CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
        oldReadyRetained = ticket->state == CjguiOwnerPumpTicketReady &&
            ticket->sessionGeneration == self.staleGeneration && ticket->event.kind == kHostBEvent;
        pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    }
    [self check:oldReadyRetained &&
                CjguiOwnerPumpLiveSessionGeneration(self.hostB) == 0
        message:"stale-generation fixture did not retain only the retired READY ticket"];
    self.observedRevision = cjgui_internal_renderer_owner_work_revision();
    [self waitFrom:self.observedRevision durationNs:kStaleWaitNs completion:
        ^(int32_t status, uint64_t elapsed, uint64_t idle, uint64_t revisionAfter) {
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        revisionAfter == self.observedRevision &&
                        elapsed >= UINT64_C(4500000) && oldReadyRetained
                message:"old-generation READY ticket incorrectly satisfied wait-any"];
            printf("OWNER_WAIT_ANY_STALE status=%d elapsed_ns=%llu old_generation=%llu ignored=1\n",
                status, (unsigned long long)elapsed,
                (unsigned long long)self.staleGeneration);
            [self startWorkerCompletionCase];
        }];
}

- (void)startWorkerCompletionCase {
    CjguiAsyncMultilineMeasureTestCloseWorkerGate();
    static const uint8_t text[] = "controlled worker completion notification";
    CjguiAsyncMultilineMeasureStatus beginStatus = CjguiAsyncMultilineMeasureBegin(
        text, sizeof(text) - 1, [NSFont systemFontOfSize:12], 120, &self->_measureHandle);
    BOOL reachedGate = beginStatus == CJGUI_ASYNC_MEASURE_STARTED &&
        CjguiAsyncMultilineMeasureTestWaitForWorkerGate(1000);
    [self check:reachedGate
        message:"real async multiline worker did not reach its completion gate"];
    self.observedRevision = cjgui_internal_renderer_owner_work_revision();
    [self waitFrom:self.observedRevision durationNs:kReadyWaitNs completion:
        ^(int32_t status, uint64_t elapsed, uint64_t idle, uint64_t revisionAfter) {
            uint32_t height = 0;
            CjguiAsyncMultilineMeasureFailure failure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
            CjguiAsyncMultilineMeasureStatus pollStatus = CjguiAsyncMultilineMeasurePoll(
                self.measureHandle, &height, &failure);
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        revisionAfter != self.observedRevision && elapsed < kReadyWaitNs &&
                        pollStatus == CJGUI_ASYNC_MEASURE_READY && height > 0
                message:"async worker completion did not notify the shared owner condition"];
            (void)CjguiAsyncMultilineMeasureRelease(self.measureHandle,
                CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED);
            printf("OWNER_WAIT_ANY_WORKER status=%d elapsed_ns=%llu measure_ready=%u revision_changed=1\n",
                status, (unsigned long long)elapsed,
                pollStatus == CJGUI_ASYNC_MEASURE_READY ? 1u : 0u);
            [self finish];
        }];
    CjguiAsyncMultilineMeasureTestOpenWorkerGate();
}

- (void)finish {
    if (self.hostB && CjguiLookupSession(self.hostB))
        (void)cjgui_internal_renderer_destroy(self.hostB);
    if (self.hostA && CjguiLookupSession(self.hostA))
        (void)cjgui_internal_renderer_destroy(self.hostA);
    if (self.failed) {
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    printf("OWNER_WAIT_ANY PASS two_sessions=1 ready_none_no_revision=1 stale_generation_ignored=1 worker_completion=1\n");
    cjgui_internal_renderer_request_application_stop();
}

@end

int main(void) {
    @autoreleasepool {
        (void)[NSApplication sharedApplication];
        CjguiInternalRendererConfig config = { .windowWidth = 320, .windowHeight = 220 };
        CjguiInternalRendererStatus statusA = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        CjguiInternalRendererStatus statusB = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t hostA = cjgui_internal_renderer_create(&config, &statusA);
        uint64_t hostB = cjgui_internal_renderer_create(&config, &statusB);
        if (statusA != CJGUI_INTERNAL_RENDERER_OK || statusB != CJGUI_INTERNAL_RENDERER_OK ||
            hostA == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN ||
            hostB == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            fprintf(stderr, "OWNER_WAIT_ANY FAIL: two-session setup failed (%u,%u)\n",
                (unsigned)statusA, (unsigned)statusB);
            return 1;
        }
        cjgui_internal_renderer_enable_main_thread_dispatch();
        CjguiOwnerWaitAnyProbe *probe = [CjguiOwnerWaitAnyProbe new];
        probe.hostA = hostA;
        probe.hostB = hostB;
        probe.waitQueue = dispatch_queue_create("cjgui.owner-wait-any.wait", DISPATCH_QUEUE_CONCURRENT);
        probe.pumpQueue = dispatch_queue_create("cjgui.owner-wait-any.pump", DISPATCH_QUEUE_SERIAL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
            dispatch_get_main_queue(), ^{ [probe startNoneBroadcastCase]; });
        [NSApplication.sharedApplication run];
        if (CjguiLookupSession(hostB)) (void)cjgui_internal_renderer_destroy(hostB);
        if (CjguiLookupSession(hostA)) (void)cjgui_internal_renderer_destroy(hostA);
        return probe.failed ? 1 : 0;
    }
}
