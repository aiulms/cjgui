// Exact-once boundary for the refresh-demand wake. The production gate used to
// query the ticket and record demand under two separate locks. This test fixes
// the interleaving with real tickets and an asynchronous main service:
//   gate 1 records demand on a PENDING acquisition;
//   gate 2 observes PENDING, main publishes READY_NONE, gate 2 records late.
// The late record must not add a second wake for the same completion.
//
// GREEN uses the atomic claim entry. RED compiles the same test against the
// pre-change renderer snapshot and the exact two-call production sequence.
#define CJGUI_OWNER_PUMP_TESTING 1
#define CJGUI_OWNER_NOTIFY_WORK_IMPLEMENTED 1
#define CJGUI_ASYNC_MULTILINE_MEASURE_TESTING 1
#if defined(CJGUI_REFRESH_DEMAND_BOUNDARY_RED)
#import CJGUI_REFRESH_DEMAND_BOUNDARY_RED_SOURCE
#else
#import "../cjgui_internal_renderer.m"
#endif
#import "../cjgui_async_multiline_measure.m"

#include <stdio.h>
#include <unistd.h>
#include <stdatomic.h>

static const uint32_t kRealEvent = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT;
static const uint64_t kStateTimeoutUs = 2000000;
static _Atomic(int) gGateReady = 0;
static _Atomic(int) gSecondObserved = 0;
static _Atomic(int) gPublished = 0;
static _Atomic(int) gRetired = 0;
static _Atomic(int) gStaleServiceDone = 0;

static uint32_t BoundaryGate(uint64_t session, uint32_t demanded) {
#if defined(CJGUI_REFRESH_DEMAND_BOUNDARY_RED)
    // Exact pre-change production sequence: read-only query, then record.
    if (!cjgui_internal_renderer_owner_pump_has_unconsumed_input(session)) return 0;
    if (demanded)
        (void)cjgui_internal_renderer_owner_pump_note_refresh_demand(session);
    return 1;
#else
    return cjgui_internal_renderer_owner_pump_claim_refresh_demand(session, demanded);
#endif
}

@interface CjguiRefreshDemandBoundaryProbe : NSObject
@property(nonatomic, assign) uint64_t hostA;
@property(nonatomic, assign) uint64_t hostB;
@property(nonatomic, assign) uint64_t hostC;
@property(nonatomic, assign) uint64_t hostD;
@property(nonatomic, assign) uint64_t hostDGeneration;
@property(nonatomic, assign) uint64_t replacement;
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL watchdogFired;
@property(nonatomic, strong) dispatch_queue_t ownerQueue;
@property(nonatomic) CjguiInternalRendererConfig config;
@end

@implementation CjguiRefreshDemandBoundaryProbe

- (void)check:(BOOL)condition message:(const char *)message {
    if (condition) return;
    self.failed = YES;
    fprintf(stderr, "OWNER_REFRESH_BOUNDARY FAIL: %s\n", message);
}

- (BOOL)ticketState:(uint64_t)host is:(CjguiOwnerPumpTicketState)wanted
    none:(BOOL *)outNone generation:(uint64_t *)outGeneration {
    NSUInteger index = CjguiOwnerPumpTicketIndex(host);
    if (index == NSNotFound) return NO;
    BOOL match = NO;
    pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
    CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
    if (outNone) *outNone = ticket->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
    if (outGeneration) *outGeneration = ticket->sessionGeneration;
    match = ticket->session == host && ticket->state == wanted;
    pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    return match;
}

- (BOOL)waitTicket:(uint64_t)host is:(CjguiOwnerPumpTicketState)wanted {
    uint64_t started = cjgui_internal_renderer_owner_clock_ns();
    while (cjgui_internal_renderer_owner_clock_ns() - started <
        kStateTimeoutUs * UINT64_C(1000)) {
        if ([self ticketState:host is:wanted none:NULL generation:NULL]) return YES;
        usleep(200);
    }
    return NO;
}

- (void)startDuplicateCase {
    atomic_store_explicit(&gGateReady, 0, memory_order_release);
    atomic_store_explicit(&gSecondObserved, 0, memory_order_release);
    atomic_store_explicit(&gPublished, 0, memory_order_release);
    dispatch_async(self.ownerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus created = cjgui_internal_renderer_pump_event(
            self.hostA, 0, &event);
        // The marker is queued behind the main service so publication is
        // observable without polling the ticket from this owner thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            atomic_store_explicit(&gPublished, 1, memory_order_release);
        });
        uint32_t first = BoundaryGate(self.hostA, 1);
        uint64_t revisionBefore = cjgui_internal_renderer_owner_work_revision();
        atomic_store_explicit(&gGateReady, 1, memory_order_release);
        uint32_t second = 0;
#if defined(CJGUI_REFRESH_DEMAND_BOUNDARY_RED)
        uint32_t observedPending =
            cjgui_internal_renderer_owner_pump_has_unconsumed_input(self.hostA);
        atomic_store_explicit(&gSecondObserved, 1, memory_order_release);
        while (!atomic_load_explicit(&gPublished, memory_order_acquire)) usleep(100);
        (void)cjgui_internal_renderer_owner_pump_note_refresh_demand(self.hostA);
        // The two-call gate already returned blocked on the pending read.
        second = observedPending == 1 ? 1 : 0;
#else
        while (!atomic_load_explicit(&gPublished, memory_order_acquire)) usleep(100);
        second = BoundaryGate(self.hostA, 1);
#endif
        uint64_t revisionAfter = cjgui_internal_renderer_owner_work_revision();
        BOOL none = NO;
        BOOL ready = [self ticketState:self.hostA is:CjguiOwnerPumpTicketReady
            none:&none generation:NULL];
        BOOL gateOpen = cjgui_internal_renderer_owner_pump_has_unconsumed_input(self.hostA) == 0;
        uint64_t delta = revisionAfter - revisionBefore;
        CjguiInternalRendererEvent consumed = {0};
        CjguiInternalRendererStatus consumeStatus = cjgui_internal_renderer_pump_event(
            self.hostA, 0, &consumed);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:created == CJGUI_INTERNAL_RENDERER_OK && event.kind ==
                CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"duplicate case did not create a pending acquisition"];
            [self check:first == 1
                message:"first gate did not record demand on the pending acquisition"];
            [self check:second == 3
                message:"second gate did not open on the already-published empty completion"];
            [self check:ready && none
                message:"empty completion was not a consumable READY_NONE"];
            [self check:gateOpen
                message:"empty completion did not release the refresh gate"];
            [self check:delta == 1
                message:"one empty completion produced more than one shared-wait notification"];
            [self check:consumeStatus == CJGUI_INTERNAL_RENDERER_OK &&
                consumed.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"ordinary poll could not consume the empty completion"];
            printf("OWNER_REFRESH_BOUNDARY_DUPLICATE first=%u second=%u revision_delta=%llu "
                "ready_none=%d gate_open=%d consumed=%d exact_once=%d\n",
                first, second, (unsigned long long)delta, ready && none ? 1 : 0,
                gateOpen ? 1 : 0, consumeStatus == CJGUI_INTERNAL_RENDERER_OK ? 1 : 0,
                delta == 1 ? 1 : 0);
            [self startRealEventCase];
        });
    });
    while (!atomic_load_explicit(&gGateReady, memory_order_acquire)) usleep(100);
#if defined(CJGUI_REFRESH_DEMAND_BOUNDARY_RED)
    while (!atomic_load_explicit(&gSecondObserved, memory_order_acquire)) usleep(100);
#endif
}

- (void)startRealEventCase {
    CJGuiInternalSession *ctx = CjguiLookupSession(self.hostB);
    [self check:ctx && CjguiEnqueueInteraction(ctx, kRealEvent, 0, @"", 0, 0)
        message:"could not enqueue the real owner event"];
    atomic_store_explicit(&gGateReady, 0, memory_order_release);
    atomic_store_explicit(&gPublished, 0, memory_order_release);
    dispatch_async(self.ownerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus created = cjgui_internal_renderer_pump_event(
            self.hostB, 0, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            atomic_store_explicit(&gPublished, 1, memory_order_release);
        });
        uint32_t first = BoundaryGate(self.hostB, 1);
        atomic_store_explicit(&gGateReady, 1, memory_order_release);
        while (!atomic_load_explicit(&gPublished, memory_order_acquire)) usleep(100);
        uint64_t revisionPublished = cjgui_internal_renderer_owner_work_revision();
        uint32_t second = BoundaryGate(self.hostB, 1);
        uint64_t revisionAfterGate = cjgui_internal_renderer_owner_work_revision();
        CjguiInternalRendererEvent consumed = {0};
        CjguiInternalRendererStatus consumeStatus = cjgui_internal_renderer_pump_event(
            self.hostB, 0, &consumed);
        uint32_t afterConsume = BoundaryGate(self.hostB, 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:created == CJGUI_INTERNAL_RENDERER_OK &&
                event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"real-event case did not create a pending acquisition"];
            [self check:first == 1 && second != 0
                message:"real Ready event did not stay blocked at the refresh gate"];
            [self check:revisionAfterGate == revisionPublished
                message:"gate observation added a notification after the real-event publication"];
            [self check:consumeStatus == CJGUI_INTERNAL_RENDERER_OK &&
                consumed.kind == kRealEvent
                message:"owner poll did not consume the original real event"];
            [self check:afterConsume == 0
                message:"consumed ticket still blocked the refresh gate"];
            printf("OWNER_REFRESH_BOUNDARY_REAL first=%u second=%u event=%u "
                "gate_extra=0 consumed=1\n", first, second, consumed.kind);
            [self startQuietCase];
        });
    });
    while (!atomic_load_explicit(&gGateReady, memory_order_acquire)) usleep(100);
}

- (void)startQuietCase {
    atomic_store_explicit(&gGateReady, 0, memory_order_release);
    atomic_store_explicit(&gPublished, 0, memory_order_release);
    dispatch_async(self.ownerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus created = cjgui_internal_renderer_pump_event(
            self.hostC, 0, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            atomic_store_explicit(&gPublished, 1, memory_order_release);
        });
        uint32_t pending = BoundaryGate(self.hostC, 0);
        uint64_t revisionBefore = cjgui_internal_renderer_owner_work_revision();
        atomic_store_explicit(&gGateReady, 1, memory_order_release);
        while (!atomic_load_explicit(&gPublished, memory_order_acquire)) usleep(100);
        uint64_t revisionPublished = cjgui_internal_renderer_owner_work_revision();
        uint32_t empty = BoundaryGate(self.hostC, 0);
        CjguiInternalRendererEvent firstPoll = {0};
        CjguiInternalRendererStatus firstStatus = cjgui_internal_renderer_pump_event(
            self.hostC, 0, &firstPoll);
        uint64_t revisionAfterConsume = cjgui_internal_renderer_owner_work_revision();
        CjguiInternalRendererEvent reusedEvent = {0};
        CjguiInternalRendererStatus reused = cjgui_internal_renderer_pump_event(
            self.hostC, 0, &reusedEvent);
        uint64_t liveGeneration = CjguiOwnerPumpLiveSessionGeneration(self.hostC);
        NSUInteger index = CjguiOwnerPumpTicketIndex(self.hostC);
        BOOL emptyTicket = NO, retainedProof = NO;
        if (index != NSNotFound) {
            pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
            emptyTicket = gCjguiOwnerPumpTickets[index].state == CjguiOwnerPumpTicketEmpty;
            retainedProof = liveGeneration != 0 &&
                gCjguiOwnerPumpEmptyProofGeneration[index] == liveGeneration;
            pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:created == CJGUI_INTERNAL_RENDERER_OK &&
                event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"quiet case did not create a pending acquisition"];
            [self check:pending == 1
                message:"quiet pending acquisition did not block the gate"];
            [self check:empty == 0 || empty == 3
                message:"quiet empty completion did not leave the gate open"];
            [self check:revisionPublished == revisionBefore &&
                revisionAfterConsume == revisionBefore
                message:"an unrecorded demand advanced the shared revision"];
            [self check:firstStatus == CJGUI_INTERNAL_RENDERER_OK &&
                firstPoll.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"quiet poll did not consume the empty completion"];
            [self check:reused == CJGUI_INTERNAL_RENDERER_OK &&
                reusedEvent.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE &&
                emptyTicket && retainedProof
                message:"retained empty proof did not answer the immediate repoll"];
            printf("OWNER_REFRESH_BOUNDARY_QUIET pending=%u empty=%u revision_unchanged=%d "
                "reuse=%d empty_ticket=%d\n", pending, empty,
                revisionAfterConsume == revisionBefore ? 1 : 0,
                reused == CJGUI_INTERNAL_RENDERER_OK ? 1 : 0, emptyTicket ? 1 : 0);            [self startRetireCase];
        });
    });
    while (!atomic_load_explicit(&gGateReady, memory_order_acquire)) usleep(100);
}

- (void)startRetireCase {
    atomic_store_explicit(&gGateReady, 0, memory_order_release);
    atomic_store_explicit(&gRetired, 0, memory_order_release);
    atomic_store_explicit(&gStaleServiceDone, 0, memory_order_release);
    dispatch_async(self.ownerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus created = cjgui_internal_renderer_pump_event(
            self.hostD, 0, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            atomic_store_explicit(&gRetired, 1, memory_order_release);
        });
        uint32_t first = BoundaryGate(self.hostD, 1);
        atomic_store_explicit(&gGateReady, 1, memory_order_release);
        while (!atomic_load_explicit(&gRetired, memory_order_acquire)) usleep(100);
        uint64_t revisionRetired = cjgui_internal_renderer_owner_work_revision();
        uint32_t staleClaim = BoundaryGate(self.hostD, 0);
        while (!atomic_load_explicit(&gStaleServiceDone, memory_order_acquire)) usleep(100);
        uint64_t revisionAfterStale = cjgui_internal_renderer_owner_work_revision();
        NSUInteger replacementIndex = CjguiOwnerPumpTicketIndex(self.replacement);
        uint64_t staleGeneration = 0;
        BOOL staleBoundToOldSession = NO;
        if (replacementIndex != NSNotFound) {
            pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
            CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[replacementIndex];
            staleGeneration = ticket->sessionGeneration;
            staleBoundToOldSession = ticket->session == self.hostD &&
                ticket->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
            pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
        }
        uint64_t replacementGeneration = CjguiOwnerPumpLiveSessionGeneration(self.replacement);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:created == CJGUI_INTERNAL_RENDERER_OK &&
                event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"retire case did not create a pending acquisition"];
            [self check:first == 1
                message:"retire case did not record demand before closing"];
            [self check:staleClaim == 0
                message:"closed session still answered the refresh gate"];
            [self check:revisionAfterStale == revisionRetired
                message:"late service for the retired ticket manufactured owner progress"];
            [self check:staleBoundToOldSession && staleGeneration == self.hostDGeneration &&
                replacementGeneration != 0 && replacementGeneration != self.hostDGeneration
                message:"late service rebound the retired ticket to the replacement session"];
            printf("OWNER_REFRESH_BOUNDARY_RETIRE first=%u stale_claim=%u stale_bump=0 "
                "stale_generation=%llu replacement_generation=%llu bound_old=%d\n",
                first, staleClaim, (unsigned long long)staleGeneration,
                (unsigned long long)replacementGeneration, staleBoundToOldSession ? 1 : 0);
            [self startErrorCase];
        });
    });
    while (!atomic_load_explicit(&gGateReady, memory_order_acquire)) usleep(100);
    // Destroy while the acquisition is Pending: the legal close path. The
    // queued service must retire without publishing or notifying.
    self.hostDGeneration = CjguiOwnerPumpLiveSessionGeneration(self.hostD);
    [self check:self.hostDGeneration != 0 &&
        cjgui_internal_renderer_destroy(self.hostD) == CJGUI_INTERNAL_RENDERER_OK
        message:"destroy was rejected or lost the generation for a Pending acquisition"];
    CjguiInternalRendererStatus createStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    self.replacement = cjgui_internal_renderer_create(&_config, &createStatus);
    [self check:createStatus == CJGUI_INTERNAL_RENDERER_OK &&
        self.replacement != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        message:"could not create the replacement session after legal retire"];
    dispatch_async(dispatch_get_main_queue(), ^{
        atomic_store_explicit(&gStaleServiceDone, 1, memory_order_release);
    });
}

- (void)startErrorCase {
    // The replacement session created after the legal retire is clean: no
    // event, no retained ticket. It carries the error-terminal case.
    uint64_t hostE = self.replacement;
    atomic_store_explicit(&gGateReady, 0, memory_order_release);
    atomic_store_explicit(&gPublished, 0, memory_order_release);
    dispatch_async(self.ownerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus created = cjgui_internal_renderer_pump_event(
            hostE, 0, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            atomic_store_explicit(&gPublished, 1, memory_order_release);
        });
        uint32_t first = BoundaryGate(hostE, 1);
        uint64_t revisionBefore = cjgui_internal_renderer_owner_work_revision();
        atomic_store_explicit(&gGateReady, 1, memory_order_release);
        while (!atomic_load_explicit(&gPublished, memory_order_acquire)) usleep(100);
        uint64_t revisionPublished = cjgui_internal_renderer_owner_work_revision();
        uint32_t emptyReady = BoundaryGate(hostE, 1);
        CjguiInternalRendererEvent errorEvent = {0};
        CjguiInternalRendererStatus errorStatus = cjgui_internal_renderer_pump_event(
            hostE, 0, &errorEvent);
        uint32_t afterConsume = BoundaryGate(hostE, 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:created == CJGUI_INTERNAL_RENDERER_OK &&
                event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"error case did not create a pending acquisition"];
            [self check:first == 1
                message:"error case did not record demand before service"];
            [self check:emptyReady == 0 || emptyReady == 3
                message:"error terminal did not release the refresh gate"];
            [self check:revisionPublished - revisionBefore == 1
                message:"demanded error terminal did not notify exactly once"];
            [self check:errorStatus == CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD &&
                errorEvent.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"owner poll did not receive the original error terminal"];
            [self check:afterConsume == 0
                message:"consumed error ticket still blocked the refresh gate"];
            printf("OWNER_REFRESH_BOUNDARY_ERROR first=%u empty_ready=%u error_status=%u "
                "one_notify=1 consumed=1\n", first, emptyReady, errorStatus);
            [self finish];
        });
    });
    while (!atomic_load_explicit(&gGateReady, memory_order_acquire)) usleep(100);
    gCjguiMainThreadDispatchEnabled = NO;
    // The queued service runs after this method returns, publishes the named
    // error terminal with one demanded notification, then the marker restores
    // dispatch for the owner's ordinary poll.
    dispatch_async(dispatch_get_main_queue(), ^{
        gCjguiMainThreadDispatchEnabled = YES;
        atomic_store_explicit(&gPublished, 1, memory_order_release);
    });
}

- (void)finish {
    if (self.replacement && CjguiLookupSession(self.replacement))
        (void)cjgui_internal_renderer_destroy(self.replacement);
    if (self.hostC && CjguiLookupSession(self.hostC))
        (void)cjgui_internal_renderer_destroy(self.hostC);
    if (self.hostB && CjguiLookupSession(self.hostB))
        (void)cjgui_internal_renderer_destroy(self.hostB);
    if (self.hostA && CjguiLookupSession(self.hostA))
        (void)cjgui_internal_renderer_destroy(self.hostA);
    if (self.failed) {
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    printf("OWNER_REFRESH_BOUNDARY PASS duplicate_exact_once=1 real_event_owned=1 "
        "quiet_silent=1 retire_no_late_effect=1 error_handback=1\n");
    cjgui_internal_renderer_request_application_stop();
}

@end

int main(void) {
    @autoreleasepool {
        (void)[NSApplication sharedApplication];
        CjguiInternalRendererConfig config = { .windowWidth = 320, .windowHeight = 220 };
        CjguiInternalRendererStatus statusA = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        CjguiInternalRendererStatus statusB = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        CjguiInternalRendererStatus statusC = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        CjguiInternalRendererStatus statusD = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t hostA = cjgui_internal_renderer_create(&config, &statusA);
        uint64_t hostB = cjgui_internal_renderer_create(&config, &statusB);
        uint64_t hostC = cjgui_internal_renderer_create(&config, &statusC);
        uint64_t hostD = cjgui_internal_renderer_create(&config, &statusD);
        if (statusA != CJGUI_INTERNAL_RENDERER_OK || statusB != CJGUI_INTERNAL_RENDERER_OK ||
            statusC != CJGUI_INTERNAL_RENDERER_OK || statusD != CJGUI_INTERNAL_RENDERER_OK ||
            hostA == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN ||
            hostB == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN ||
            hostC == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN ||
            hostD == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            fprintf(stderr, "OWNER_REFRESH_BOUNDARY FAIL: session setup failed (%u,%u,%u,%u)\n",
                (unsigned)statusA, (unsigned)statusB, (unsigned)statusC, (unsigned)statusD);
            return 1;
        }
        cjgui_internal_renderer_enable_main_thread_dispatch();
        CjguiRefreshDemandBoundaryProbe *probe = [CjguiRefreshDemandBoundaryProbe new];
        probe.hostA = hostA;
        probe.hostB = hostB;
        probe.hostC = hostC;
        probe.hostD = hostD;
        probe.config = config;
        probe.ownerQueue = dispatch_queue_create("cjgui.owner-refresh-boundary.owner",
            DISPATCH_QUEUE_SERIAL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
            dispatch_get_main_queue(), ^{ [probe startDuplicateCase]; });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
                if (probe.watchdogFired) return;
                probe.watchdogFired = YES;
                probe.failed = YES;
                fprintf(stderr, "OWNER_REFRESH_BOUNDARY FAIL: watchdog\n");
                cjgui_internal_renderer_request_application_stop();
            });
        [NSApplication.sharedApplication run];
        if (CjguiLookupSession(hostD)) (void)cjgui_internal_renderer_destroy(hostD);
        if (CjguiLookupSession(hostC)) (void)cjgui_internal_renderer_destroy(hostC);
        if (CjguiLookupSession(hostB)) (void)cjgui_internal_renderer_destroy(hostB);
        if (CjguiLookupSession(hostA)) (void)cjgui_internal_renderer_destroy(hostA);
        return probe.failed ? 1 : 0;
    }
}
