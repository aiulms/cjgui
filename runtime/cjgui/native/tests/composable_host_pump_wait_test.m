// Production pump wait/lifecycle probe. FIFO insertion below is a private
// boundary seam; it is not evidence of a physical or synthesized click.
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

static const uint32_t kProbePumpTimeoutMs = 16; // production bound
static const uint64_t kProbeMinimumWaitMicros = 12000;
static const uint64_t kProbeMaximumReadbackMicros = 100000;
static const uint64_t kProbeTimerDelayMicros = 4000;

@interface CjguiHostPumpWaitProbe : NSObject
@property(nonatomic, assign) uint64_t session;
@property(nonatomic, assign) uint64_t replacementSession;
@property(nonatomic, assign) NSInteger phase;
@property(nonatomic, assign) NSUInteger hostCount;
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL emptyWaitMainTurnRan;
@property(nonatomic, assign) BOOL timerEntered;
@property(nonatomic, assign) uint64_t timerEnteredOffsetMicros;
@property(nonatomic, assign) uint64_t callStartMicros;
@property(nonatomic, assign) uint64_t callDeadlineMicros;
@property(nonatomic, assign) uint64_t nextRunId;
@property(nonatomic, assign) uint64_t activeRunId;
@property(nonatomic, assign) uint64_t timerRunId;
@property(nonatomic, assign) NSInteger timerPhase;
@property(nonatomic, assign) uint64_t pendingTimerDelayMicros;
@property(nonatomic, copy) dispatch_block_t pendingTimerAction;
@property(nonatomic, assign) BOOL timerActionRan;
@property(nonatomic, assign) BOOL arrivalQueued;
@property(nonatomic, assign) BOOL abaTimerActionRan;
@property(nonatomic, assign) NSUInteger incompleteCases;
@property(nonatomic, assign) BOOL watchdogFired;
@property(nonatomic, strong) NSMutableArray<NSNumber *> *sessions;
@property(nonatomic, strong) dispatch_queue_t workerQueue;
@end

@implementation CjguiHostPumpWaitProbe

- (void)check:(BOOL)condition message:(const char *)message {
    if (condition) return;
    self.failed = YES;
    fprintf(stderr, "NATIVE_PUMP_WAIT FAIL: %s\n", message);
}

// Session-table state and its FIFO are main-thread-owned in production. Keep
// this explicit private injection here so the probe measures only acquisition
// and handoff, with no claim that a real input device generated the event.
- (BOOL)queuePrivateKind:(uint32_t)kind forSession:(uint64_t)token {
    CJGuiInternalSession *ctx = CjguiLookupSession(token);
    if (!ctx || ctx.destroyed) return NO;
    CJGuiInternalQueuedInteraction *interaction =
        [[CJGuiInternalQueuedInteraction alloc] initWithKind:kind
                                                recordIndex:0
                                             selectionStart:0
                                               selectionEnd:0
                                                   formText:@""
                                                     nodeId:0
                                         projectionVersion:0
                                                resourceId:-1
                                                   nodeKind:0];
    if (!interaction) return NO;
    [ctx.pendingInteractions addObject:interaction];
    return YES;
}

- (uint64_t)createSession {
    CjguiInternalRendererConfig config = { .windowWidth = 360, .windowHeight = 240 };
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t token = cjgui_internal_renderer_create(&config, &status);
    [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
               token != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        message:"could not create a host session for the requested host-count case"];
    if (status == CJGUI_INTERNAL_RENDERER_OK &&
        token != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        [self.sessions addObject:@(token)];
    }
    return token;
}

- (void)removeAdditionalSessions {
    while (self.sessions.count > 1) {
        uint64_t token = self.sessions.lastObject.unsignedLongLongValue;
        CjguiInternalRendererStatus status = cjgui_internal_renderer_destroy(token);
        [self check:status == CJGUI_INTERNAL_RENDERER_OK
            message:"could not destroy an additional host after its isolation case"];
        [self.sessions removeLastObject];
    }
}

- (BOOL)targetFIFOAndTicketAreEmptyForSession:(uint64_t)token {
    CJGuiInternalSession *ctx = CjguiLookupSession(token);
    NSUInteger index = CjguiOwnerPumpTicketIndex(token);
    if (!ctx || ctx.destroyed || index == NSNotFound) return NO;
    pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
    uint32_t ticketState = gCjguiOwnerPumpTickets[index].state;
    uint64_t ticketNonce = gCjguiOwnerPumpTickets[index].nonce;
    pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    BOOL empty = ctx.pendingInteractions.count == 0 &&
        ctx.pendingTransferTerminalFacts.count == 0 && !ctx.pendingInputQueueFullNotice &&
        !ctx.closeRequested && ticketState == CjguiOwnerPumpTicketEmpty;
    if (!empty) {
        printf("NATIVE_PUMP_WAIT_NONEMPTY session=%llu interactions=%lu transfer_facts=%lu input_notice=%u close=%u ticket_state=%u ticket_nonce=%llu\n",
            (unsigned long long)token, (unsigned long)ctx.pendingInteractions.count,
            (unsigned long)ctx.pendingTransferTerminalFacts.count,
            ctx.pendingInputQueueFullNotice ? 1u : 0u, ctx.closeRequested ? 1u : 0u,
            ticketState, (unsigned long long)ticketNonce);
    }
    return empty;
}

- (void)preparePhase:(NSInteger)phase hostCount:(NSUInteger)count arrival:(BOOL)arrival {
    uint64_t token = self.session;
    dispatch_async(self.workerQueue, ^{
        uint64_t started = CjguiCaretBlinkClockMicros();
        uint64_t idleNs = 0;
        NSUInteger calls = 0;
        BOOL empty = NO;
        for (NSUInteger attempt = 0; attempt < 32; attempt++) {
            CjguiInternalRendererEvent event = {0};
            uint64_t callIdleNs = 0;
            CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event_measured(
                token, kProbePumpTimeoutMs, &event, &callIdleNs);
            calls += 1;
            idleNs += callIdleNs;
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) { empty = YES; break; }
            printf("NATIVE_PUMP_WAIT_SETUP_DRAIN phase=%ld event_kind=%u\n", (long)phase, event.kind);
        }
        uint64_t finished = CjguiCaretBlinkClockMicros();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:empty message:"could not reach a measured empty FIFO boundary before the next phase"];
            printf("NATIVE_PUMP_WAIT_PREP phase=%ld full_wall_us=%llu actual_idle_ns=%llu owner_calls=%lu\n",
                (long)phase, (unsigned long long)(finished >= started ? finished - started : 0),
                (unsigned long long)idleNs, (unsigned long)calls);
            [self check:[self targetFIFOAndTicketAreEmptyForSession:token]
                message:"pump ticket or FIFO was not empty after the preparation poll completed"];
            if (arrival) [self startArrivalWaitForHostCount:count phase:phase];
            else [self startEmptyWaitForHostCount:count phase:phase];
        });
    });
}

- (void)verifyEventDeliveredOnce:(uint32_t)kind forSession:(uint64_t)token
                      phase:(NSInteger)phase started:(uint64_t)phaseStarted
                      idleNs:(uint64_t)phaseIdleNs ownerCalls:(NSUInteger)phaseOwnerCalls
                  completion:(dispatch_block_t)completion {
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent duplicate = {0};
        uint64_t duplicateIdleNs = 0;
        CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event_measured(
            token, kProbePumpTimeoutMs, &duplicate, &duplicateIdleNs);
        uint64_t finished = CjguiCaretBlinkClockMicros();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        duplicate.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"FIFO event was not exactly-once across the next independent owner poll"];
            printf("NATIVE_PUMP_WAIT_PHASE_TOTAL phase=%ld session=%llu delivered_kind=%u duplicate_kind=%u full_wall_us=%llu actual_idle_ns=%llu owner_calls=%lu deadline_us=%llu\n",
                (long)phase, (unsigned long long)token, kind, duplicate.kind,
                (unsigned long long)(finished >= phaseStarted ? finished - phaseStarted : 0),
                (unsigned long long)(phaseIdleNs + duplicateIdleNs),
                (unsigned long)(phaseOwnerCalls + 1),
                (unsigned long long)(phaseStarted + (uint64_t)kProbePumpTimeoutMs * 1000u));
            if (completion) completion();
        });
    });
}

- (void)startPumpPhase:(NSInteger)phase hostCount:(NSUInteger)hostCount session:(uint64_t)token {
    self.phase = phase;
    self.hostCount = hostCount;
    uint64_t runId = ++self.nextRunId;
    self.activeRunId = runId;
    self.callStartMicros = 0;
    self.callDeadlineMicros = 0;
    self.timerRunId = 0;
    self.pendingTimerAction = nil;
    self.pendingTimerDelayMicros = 0;
    self.timerActionRan = NO;
    self.timerEntered = NO;
    self.timerEnteredOffsetMicros = 0;
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        uint64_t started = CjguiCaretBlinkClockMicros();
        uint64_t idleNs = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.activeRunId != runId || self.phase != phase) return;
            self.callStartMicros = started;
            self.callDeadlineMicros = started + (uint64_t)kProbePumpTimeoutMs * 1000u;
            [self scheduleConfiguredTimerForRun:runId];
        });
        CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event_measured(
            token, kProbePumpTimeoutMs, &event, &idleNs);
        uint64_t finished = CjguiCaretBlinkClockMicros();
        uint64_t elapsed = finished >= started ? finished - started : 0;
        uint64_t deadline = started + (uint64_t)kProbePumpTimeoutMs * 1000u;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.activeRunId != runId || self.phase != phase) return;
            [self pumpPhase:phase hostCount:hostCount session:token status:status
                     event:event started:started deadline:deadline elapsed:elapsed
                    idleNs:idleNs ownerCalls:1];
        });
    });
}

- (void)startTimerAfterMicros:(uint64_t)delay phase:(NSInteger)phase action:(dispatch_block_t)action {
    self.timerPhase = phase;
    self.timerRunId = self.activeRunId;
    self.pendingTimerDelayMicros = delay;
    self.pendingTimerAction = action;
    if (self.callStartMicros != 0) [self scheduleConfiguredTimerForRun:self.activeRunId];
}

- (void)scheduleConfiguredTimerForRun:(uint64_t)runId {
    if (!self.pendingTimerAction || self.timerRunId != runId || self.phase != self.timerPhase ||
        self.activeRunId != runId || self.callStartMicros == 0) return;
    dispatch_block_t action = self.pendingTimerAction;
    NSInteger phase = self.timerPhase;
    uint64_t delay = self.pendingTimerDelayMicros;
    uint64_t started = self.callStartMicros;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)delay * NSEC_PER_USEC),
        dispatch_get_main_queue(), ^{
            if (self.activeRunId != runId || self.phase != phase || self.timerRunId != runId) return;
            uint64_t now = CjguiCaretBlinkClockMicros();
            self.timerEntered = YES;
            self.timerEnteredOffsetMicros = now >= started ? now - started : 0;
            BOOL enteredDuringExpectedWait = self.timerEnteredOffsetMicros >= 2000 &&
                self.timerEnteredOffsetMicros < (uint64_t)kProbePumpTimeoutMs * 1000u;
            if (!enteredDuringExpectedWait) {
                self.timerActionRan = NO;
                return;
            }
            self.timerActionRan = YES;
            action();
        });
}

- (void)startEmptyWaitForHostCount:(NSUInteger)count phase:(NSInteger)phase {
    self.emptyWaitMainTurnRan = NO;
    [self check:[self targetFIFOAndTicketAreEmptyForSession:self.session]
        message:"empty-wait phase started with a non-empty target FIFO or stale ticket"];
    [self startPumpPhase:phase hostCount:count session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:phase action:^{
        self.emptyWaitMainTurnRan = YES;
    }];
}

- (void)startArrivalWaitForHostCount:(NSUInteger)count phase:(NSInteger)phase {
    [self check:[self targetFIFOAndTicketAreEmptyForSession:self.session]
        message:"arrival phase started with a non-empty target FIFO or stale ticket"];
    self.arrivalQueued = NO;
    [self startPumpPhase:phase hostCount:count session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:phase action:^{
        BOOL targetQueued = [self queuePrivateKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE
                                         forSession:self.session];
        self.arrivalQueued = targetQueued;
        [self check:targetQueued message:"could not inject the delayed target FIFO event"];
        // Every other live host receives a distinct sentinel. The selected
        // target pump must not read any of these per-session FIFOs.
        for (NSNumber *number in self.sessions) {
            uint64_t other = number.unsignedLongLongValue;
            if (other == self.session) continue;
            [self check:[self queuePrivateKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO
                                     forSession:other]
                message:"could not inject a non-target session sentinel"];
        }
    }];
}

- (void)startHostCountOne {
    [self preparePhase:2 hostCount:1 arrival:NO];
}

- (void)startHostCountTwo {
    [self check:[self createSession] != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        message:"host_count=2 setup failed"];
    [self preparePhase:4 hostCount:2 arrival:NO];
}

- (void)startHostCountFour {
    while (self.sessions.count < 4) {
        if ([self createSession] == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) break;
    }
    [self check:self.sessions.count == 4 message:"host_count=4 setup failed"];
    [self preparePhase:6 hostCount:4 arrival:NO];
}

- (void)startABAWait {
    [self check:[self targetFIFOAndTicketAreEmptyForSession:self.session]
        message:"generation-reuse phase started with a non-empty target FIFO or stale ticket"];
    self.abaTimerActionRan = NO;
    [self startPumpPhase:10 hostCount:1 session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:10 action:^{
        self.abaTimerActionRan = YES;
        CjguiInternalRendererStatus retired = cjgui_internal_renderer_destroy(self.session);
        [self check:retired == CJGUI_INTERNAL_RENDERER_OK
            message:"destroy old session during wait failed"];
        [self.sessions removeObject:@(self.session)];
        self.replacementSession = [self createSession];
        [self check:self.replacementSession == self.session
            message:"same-slot session recreation did not occur during the old wait"];
        if (self.replacementSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            [self check:[self queuePrivateKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO
                                     forSession:self.replacementSession]
                message:"could not queue the replacement-session sentinel"];
        }
    }];
}

- (void)startCloseWait {
    [self check:[self targetFIFOAndTicketAreEmptyForSession:self.session]
        message:"close phase started with a non-empty target FIFO or stale ticket"];
    [self startPumpPhase:12 hostCount:1 session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:12 action:^{
        CJGuiInternalSession *ctx = CjguiLookupSession(self.session);
        [self check:ctx != nil && ctx.window != nil
            message:"replacement session lost its last window before close phase"];
        [ctx.window performClose:nil];
    }];
}

- (void)drainAsyncArrivalForPhase:(NSInteger)phase hostCount:(NSUInteger)hostCount
                          session:(uint64_t)token started:(uint64_t)started
                         deadline:(uint64_t)deadline elapsed:(uint64_t)elapsed
                           idleNs:(uint64_t)idleNs ownerCalls:(NSUInteger)ownerCalls {
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
        BOOL received = NO;
        uint64_t totalIdleNs = idleNs;
        NSUInteger totalOwnerCalls = ownerCalls;
        for (NSUInteger attempt = 0; attempt < 3; attempt++) {
            uint64_t nextIdleNs = 0;
            status = cjgui_internal_renderer_pump_event_measured(
                token, kProbePumpTimeoutMs, &event, &nextIdleNs);
            totalIdleNs += nextIdleNs;
            totalOwnerCalls += 1;
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) { received = YES; break; }
        }
        uint64_t finished = CjguiCaretBlinkClockMicros();
        uint64_t fullElapsed = finished >= started ? finished - started : 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!received) {
                [self check:NO message:"injected arrival was not consumed by subsequent owner polls"];
                cjgui_internal_renderer_request_application_stop();
                return;
            }
            [self pumpPhase:phase hostCount:hostCount session:token status:status
                      event:event started:started deadline:deadline elapsed:fullElapsed
                     idleNs:totalIdleNs ownerCalls:totalOwnerCalls];
        });
    });
}

- (void)pumpPhase:(NSInteger)phase hostCount:(NSUInteger)hostCount session:(uint64_t)token
           status:(CjguiInternalRendererStatus)status event:(CjguiInternalRendererEvent)event
          started:(uint64_t)started deadline:(uint64_t)deadline elapsed:(uint64_t)elapsed
           idleNs:(uint64_t)idleNs ownerCalls:(NSUInteger)ownerCalls {
    printf("NATIVE_PUMP_WAIT_PHASE_RETURN phase=%ld host_count=%lu session=%llu start_us=%llu deadline_us=%llu full_wall_us=%llu actual_idle_ns=%llu owner_calls=%lu status=%u event_kind=%u\n",
        (long)phase, (unsigned long)hostCount, (unsigned long long)token,
        (unsigned long long)started, (unsigned long long)deadline,
        (unsigned long long)elapsed, (unsigned long long)idleNs,
        (unsigned long)ownerCalls, (unsigned)status, event.kind);
    [self check:idleNs <= elapsed * 1000ULL
        message:"measured real idle exceeds the full phase wall interval"];
    [self check:status == CJGUI_INTERNAL_RENDERER_OK ||
               (phase == 10 && status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION)
        message:"production pump returned an unexpected status"];
    if (phase >= 2 && phase <= 9) {
        const char *caseName = (phase % 2 == 0) ? "empty" : "delayed_arrival";
        uint64_t timerOffset = self.timerEnteredOffsetMicros;
        printf("NATIVE_PUMP_WAIT_SAMPLE host_count=%lu case=%s start_us=%llu deadline_us=%llu full_readback_us=%llu actual_idle_ns=%llu owner_calls=%lu timer_entered_us=%llu\n",
               (unsigned long)hostCount, caseName, (unsigned long long)started,
               (unsigned long long)deadline, (unsigned long long)elapsed,
               (unsigned long long)idleNs, (unsigned long)ownerCalls,
               (unsigned long long)timerOffset);
        [self check:self.timerEntered && timerOffset >= 2000 && timerOffset <
                   (uint64_t)kProbePumpTimeoutMs * 1000u
            message:"timer was absent, too early, or entered after the production deadline"];
        [self check:elapsed >= kProbeMinimumWaitMicros && elapsed <= kProbeMaximumReadbackMicros
            message:"pump did not observe its bounded positive wait"];
    }

    switch (phase) {
        case 1: {
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                [self drainAsyncArrivalForPhase:phase hostCount:hostCount session:token
                    started:started deadline:deadline elapsed:elapsed idleNs:idleNs ownerCalls:ownerCalls];
                break;
            }
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT
                message:"prequeued FIFO phase returned an unexpected event"];
            [self verifyEventDeliveredOnce:event.kind forSession:token phase:phase
                started:started idleNs:idleNs ownerCalls:ownerCalls completion:^{
                [self startHostCountOne];
            }];
            break;
        }
        case 2: {
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"empty positive-timeout pump unexpectedly returned an event"];
            if (!self.timerActionRan) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN phase=2 case=empty reason=main_timer_outside_16ms_window\n");
                self.incompleteCases += 1;
            } else [self check:self.emptyWaitMainTurnRan
                message:"main run loop could not execute while the worker waited"];
            [self preparePhase:3 hostCount:1 arrival:YES];
            break;
        }
        case 3: {
            if (!self.timerActionRan || !self.arrivalQueued) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN host_count=1 case=delayed_arrival reason=%s event_enqueued=%u\n",
                    self.timerActionRan ? "target_fifo_enqueue_failed" : "arrival_timer_outside_16ms_window",
                    self.arrivalQueued ? 1u : 0u);
                self.incompleteCases += 1;
                [self startHostCountTwo];
                break;
            }
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                [self drainAsyncArrivalForPhase:phase hostCount:hostCount session:token
                    started:started deadline:deadline elapsed:elapsed idleNs:idleNs ownerCalls:ownerCalls];
                break;
            }
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE
                message:"host_count=1 second drain did not deliver the delayed event"];
            [self verifyEventDeliveredOnce:event.kind forSession:token phase:phase
                started:started idleNs:idleNs ownerCalls:ownerCalls completion:^{
                [self startHostCountTwo];
            }];
            break;
        }
        case 4: {
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"host_count=2 empty pump unexpectedly returned an event"];
            if (!self.timerActionRan) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN phase=4 case=empty reason=main_timer_outside_16ms_window\n");
                self.incompleteCases += 1;
            } else [self check:self.emptyWaitMainTurnRan
                message:"main run loop could not progress during host_count=2 empty wait"];
            [self preparePhase:5 hostCount:2 arrival:YES];
            break;
        }
        case 5: {
            if (!self.timerActionRan || !self.arrivalQueued) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN host_count=2 case=delayed_arrival reason=%s event_enqueued=%u\n",
                    self.timerActionRan ? "target_fifo_enqueue_failed" : "arrival_timer_outside_16ms_window",
                    self.arrivalQueued ? 1u : 0u);
                self.incompleteCases += 1;
                [self removeAdditionalSessions];
                [self startHostCountFour];
                break;
            }
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                [self drainAsyncArrivalForPhase:phase hostCount:hostCount session:token
                    started:started deadline:deadline elapsed:elapsed idleNs:idleNs ownerCalls:ownerCalls];
                break;
            }
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE
                message:"host_count=2 second drain did not deliver the delayed event"];
            for (NSNumber *number in self.sessions) {
                uint64_t other = number.unsignedLongLongValue;
                if (other == self.session) continue;
                CJGuiInternalSession *ctx = CjguiLookupSession(other);
                [self check:ctx != nil && ctx.pendingInteractions.count == 1 &&
                           ctx.pendingInteractions.firstObject.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO
                    message:"host_count=2 target pump touched the other session FIFO"];
            }
            [self verifyEventDeliveredOnce:event.kind forSession:token phase:phase
                started:started idleNs:idleNs ownerCalls:ownerCalls completion:^{
                [self removeAdditionalSessions];
                [self startHostCountFour];
            }];
            break;
        }
        case 6: {
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"host_count=4 empty pump unexpectedly returned an event"];
            if (!self.timerActionRan) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN phase=6 case=empty reason=main_timer_outside_16ms_window\n");
                self.incompleteCases += 1;
            } else [self check:self.emptyWaitMainTurnRan
                message:"main run loop could not progress during host_count=4 empty wait"];
            [self preparePhase:7 hostCount:4 arrival:YES];
            break;
        }
        case 7: {
            if (!self.timerActionRan || !self.arrivalQueued) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN host_count=4 case=delayed_arrival reason=%s event_enqueued=%u\n",
                    self.timerActionRan ? "target_fifo_enqueue_failed" : "arrival_timer_outside_16ms_window",
                    self.arrivalQueued ? 1u : 0u);
                self.incompleteCases += 1;
                [self removeAdditionalSessions];
                [self startABAWait];
                break;
            }
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                [self drainAsyncArrivalForPhase:phase hostCount:hostCount session:token
                    started:started deadline:deadline elapsed:elapsed idleNs:idleNs ownerCalls:ownerCalls];
                break;
            }
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE
                message:"host_count=4 second drain did not deliver the delayed event"];
            for (NSNumber *number in self.sessions) {
                uint64_t other = number.unsignedLongLongValue;
                if (other == self.session) continue;
                CJGuiInternalSession *ctx = CjguiLookupSession(other);
                [self check:ctx != nil && ctx.pendingInteractions.count == 1 &&
                           ctx.pendingInteractions.firstObject.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO
                    message:"host_count=4 target pump touched another session FIFO"];
            }
            [self verifyEventDeliveredOnce:event.kind forSession:token phase:phase
                started:started idleNs:idleNs ownerCalls:ownerCalls completion:^{
                [self removeAdditionalSessions];
                [self startABAWait];
            }];
            break;
        }
        case 10: {
            [self check:elapsed <= kProbeMaximumReadbackMicros
                message:"stale async ticket exceeded the original bounded owner readback limit"];
            if (!self.abaTimerActionRan) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN case=session_generation_aba reason=retirement_timer_outside_16ms_window destruction_and_reuse=not_run\n");
                self.incompleteCases += 1;
                [self startCloseWait];
                break;
            }
            if (status == CJGUI_INTERNAL_RENDERER_OK) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN case=session_generation_aba reason=owner_guard_order_unobserved timer_entered_us=%llu owner_full_wall_us=%llu\n",
                    (unsigned long long)self.timerEnteredOffsetMicros,
                    (unsigned long long)elapsed);
                self.incompleteCases += 1;
                CJGuiInternalSession *replacement = CjguiLookupSession(self.replacementSession);
                [self check:replacement != nil && replacement.pendingInteractions.count == 1
                    message:"pre-retirement OK return consumed the replacement FIFO sentinel"];
                [self startPumpPhase:11 hostCount:1 session:self.replacementSession];
                break;
            }
            [self check:status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION
                message:"stale wait did not reject the retired session generation"];
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"stale wait returned an event from the replacement session"];
            CJGuiInternalSession *replacement = CjguiLookupSession(self.replacementSession);
            [self check:replacement != nil && replacement.pendingInteractions.count == 1
                message:"stale wait consumed the replacement-session FIFO sentinel"];
            [self startPumpPhase:11 hostCount:1 session:self.replacementSession];
            break;
        }
        case 11: {
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO
                message:"replacement session could not consume its untouched FIFO sentinel"];
            [self check:elapsed < kProbeMinimumWaitMicros
                message:"replacement-session FIFO sentinel did not return promptly"];
            [self verifyEventDeliveredOnce:event.kind forSession:token phase:phase
                started:started idleNs:idleNs ownerCalls:ownerCalls completion:^{
                [self startCloseWait];
            }];
            break;
        }
        case 12: {
            if (!self.timerActionRan) {
                printf("NATIVE_PUMP_WAIT_UNKNOWN case=close_intent reason=close_timer_outside_16ms_window close_event_enqueued=0\n");
                self.incompleteCases += 1;
                cjgui_internal_renderer_request_application_stop();
                break;
            }
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                [self drainAsyncArrivalForPhase:phase hostCount:hostCount session:token
                    started:started deadline:deadline elapsed:elapsed idleNs:idleNs ownerCalls:ownerCalls];
                break;
            }
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE
                message:"normal window close intent was not delivered through the pump"];
            [self check:elapsed >= kProbeMinimumWaitMicros && elapsed <= kProbeMaximumReadbackMicros
                message:"close-intent pump did not complete within its bounded wait"];
            [self verifyEventDeliveredOnce:event.kind forSession:token phase:phase
                started:started idleNs:idleNs ownerCalls:ownerCalls completion:^{
                [self check:cjgui_internal_renderer_request_close(token) == CJGUI_INTERNAL_RENDERER_OK
                    message:"normal close decision failed to close the final window"];
                // The framework owner normally decides whether to exit after
                // processing close. Stop the test-owned NSApplication loop after
                // that decision so an app-policy difference cannot hang this probe.
                cjgui_internal_renderer_request_application_stop();
            }];
            break;
        }
        default:
            [self check:NO message:"unexpected pump phase"];
            cjgui_internal_renderer_request_application_stop();
            break;
    }
}

@end

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = { .windowWidth = 360, .windowHeight = 240 };
        CjguiInternalRendererStatus createStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &createStatus);
        if (createStatus != CJGUI_INTERNAL_RENDERER_OK ||
            session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            fprintf(stderr, "NATIVE_PUMP_WAIT FAIL: create session status=%u token=%llu\n",
                    (unsigned)createStatus, (unsigned long long)session);
            return 1;
        }

        CjguiHostPumpWaitProbe *probe = [CjguiHostPumpWaitProbe new];
        probe.session = session;
        probe.replacementSession = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
        probe.sessions = [NSMutableArray arrayWithObject:@(session)];
        probe.workerQueue = dispatch_queue_create("cjgui.native-pump-wait.worker", DISPATCH_QUEUE_SERIAL);
        if (![probe queuePrivateKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT
                          forSession:session]) {
            (void)cjgui_internal_renderer_destroy(session);
            fprintf(stderr, "NATIVE_PUMP_WAIT FAIL: could not queue initial private FIFO event\n");
            return 1;
        }

        NSApplication *app = NSApp;
        cjgui_internal_renderer_enable_main_thread_dispatch();
        if (!atomic_load_explicit(&gCjguiLauncherOwnsEventLoop, memory_order_acquire) ||
            !atomic_load_explicit(&gCjguiMainThreadDispatchEnabled, memory_order_acquire)) {
            (void)cjgui_internal_renderer_destroy(session);
            fprintf(stderr, "NATIVE_PUMP_WAIT FAIL: NSApplication loop ownership was not enabled\n");
            return 1;
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC),
                       dispatch_get_main_queue(), ^{
            [probe startPumpPhase:1 hostCount:1 session:session];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            probe.watchdogFired = YES;
            fprintf(stderr, "NATIVE_PUMP_WAIT FAIL: 2s bounded run-loop watchdog fired\n");
            probe.failed = YES;
            cjgui_internal_renderer_request_application_stop();
        });

        [app run];

        [probe removeAdditionalSessions];
        uint64_t liveSession = probe.replacementSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
            ? probe.replacementSession : session;
        if (CjguiLookupSession(liveSession)) (void)cjgui_internal_renderer_destroy(liveSession);
        if (probe.watchdogFired || probe.failed) return 1;
        if (probe.incompleteCases != 0) {
            printf("NATIVE_PUMP_WAIT INCOMPLETE unknown_cases=%lu source=private_fifo_boundary_probe\n",
                (unsigned long)probe.incompleteCases);
            return 2;
        }
        printf("NATIVE_PUMP_WAIT PASS immediate_fifo=1 host_counts=1,2,4 empty_and_delayed=1 main_progress=1 target_fifo_isolation=1 session_generation_aba=1 replacement_fifo_preserved=1 close_intent=1 final_window_loop_exit=1 source=private_fifo_boundary_probe\n");
    }
    return 0;
}
