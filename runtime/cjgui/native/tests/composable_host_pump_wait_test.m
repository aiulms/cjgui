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

- (void)startPumpPhase:(NSInteger)phase hostCount:(NSUInteger)hostCount session:(uint64_t)token {
    self.phase = phase;
    self.hostCount = hostCount;
    self.timerEntered = NO;
    self.timerEnteredOffsetMicros = 0;
    self.callStartMicros = CjguiCaretBlinkClockMicros();
    self.callDeadlineMicros = self.callStartMicros + (uint64_t)kProbePumpTimeoutMs * 1000u;
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        uint64_t started = CjguiCaretBlinkClockMicros();
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(token, kProbePumpTimeoutMs, &event);
        uint64_t finished = CjguiCaretBlinkClockMicros();
        uint64_t elapsed = finished >= started ? finished - started : 0;
        uint64_t deadline = started + (uint64_t)kProbePumpTimeoutMs * 1000u;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self pumpPhase:phase hostCount:hostCount session:token status:status
                     event:event started:started deadline:deadline elapsed:elapsed];
        });
    });
}

- (void)startTimerAfterMicros:(uint64_t)delay phase:(NSInteger)phase action:(dispatch_block_t)action {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)delay * NSEC_PER_USEC),
                   dispatch_get_main_queue(), ^{
        uint64_t now = CjguiCaretBlinkClockMicros();
        self.timerEntered = YES;
        self.timerEnteredOffsetMicros = now >= self.callStartMicros ? now - self.callStartMicros : 0;
        BOOL enteredDuringExpectedWait = self.phase == phase &&
            self.timerEnteredOffsetMicros >= 2000 && self.timerEnteredOffsetMicros <
                (uint64_t)kProbePumpTimeoutMs * 1000u;
        [self check:enteredDuringExpectedWait
            message:"timer did not enter during the intended wait; setup is invalid or exceeded the pump deadline"];
        if (!enteredDuringExpectedWait) return;
        action();
    });
}

- (void)startEmptyWaitForHostCount:(NSUInteger)count phase:(NSInteger)phase {
    self.emptyWaitMainTurnRan = NO;
    [self startPumpPhase:phase hostCount:count session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:phase action:^{
        self.emptyWaitMainTurnRan = YES;
    }];
}

- (void)startArrivalWaitForHostCount:(NSUInteger)count phase:(NSInteger)phase {
    [self startPumpPhase:phase hostCount:count session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:phase action:^{
        [self check:[self queuePrivateKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE
                                 forSession:self.session]
            message:"could not inject the delayed target FIFO event"];
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
    [self startEmptyWaitForHostCount:1 phase:2];
}

- (void)startHostCountTwo {
    [self check:[self createSession] != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        message:"host_count=2 setup failed"];
    [self startEmptyWaitForHostCount:2 phase:4];
}

- (void)startHostCountFour {
    while (self.sessions.count < 4) {
        if ([self createSession] == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) break;
    }
    [self check:self.sessions.count == 4 message:"host_count=4 setup failed"];
    [self startEmptyWaitForHostCount:4 phase:6];
}

- (void)startABAWait {
    [self startPumpPhase:10 hostCount:1 session:self.session];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:10 action:^{
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
    [self startPumpPhase:12 hostCount:1 session:self.replacementSession];
    [self startTimerAfterMicros:kProbeTimerDelayMicros phase:12 action:^{
        CJGuiInternalSession *ctx = CjguiLookupSession(self.replacementSession);
        [self check:ctx != nil && ctx.window != nil
            message:"replacement session lost its last window before close phase"];
        [ctx.window performClose:nil];
    }];
}

- (void)pumpPhase:(NSInteger)phase hostCount:(NSUInteger)hostCount session:(uint64_t)token
           status:(CjguiInternalRendererStatus)status event:(CjguiInternalRendererEvent)event
          started:(uint64_t)started deadline:(uint64_t)deadline elapsed:(uint64_t)elapsed {
    [self check:status == CJGUI_INTERNAL_RENDERER_OK ||
               (phase == 10 && status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION)
        message:"production pump returned an unexpected status"];
    if (phase >= 2 && phase <= 9) {
        const char *caseName = (phase % 2 == 0) ? "empty" : "delayed_arrival";
        uint64_t timerOffset = self.timerEnteredOffsetMicros;
        printf("NATIVE_PUMP_WAIT_SAMPLE host_count=%lu case=%s start_us=%llu deadline_us=%llu readback_us=%llu timer_entered_us=%llu\n",
               (unsigned long)hostCount, caseName, (unsigned long long)started,
               (unsigned long long)deadline, (unsigned long long)elapsed,
               (unsigned long long)timerOffset);
        [self check:self.timerEntered && timerOffset >= 2000 && timerOffset <
                   (uint64_t)kProbePumpTimeoutMs * 1000u
            message:"timer was absent, too early, or entered after the production deadline"];
        [self check:elapsed >= kProbeMinimumWaitMicros && elapsed <= kProbeMaximumReadbackMicros
            message:"pump did not observe its bounded positive wait"];
    }

    switch (phase) {
        case 1:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT
                message:"prequeued FIFO event was not returned"];
            [self check:elapsed < kProbeMinimumWaitMicros
                message:"prequeued FIFO event waited instead of returning promptly"];
            [self startHostCountOne];
            break;
        case 2:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"empty positive-timeout pump unexpectedly returned an event"];
            [self check:self.emptyWaitMainTurnRan
                message:"main run loop could not execute while the worker waited"];
            [self startArrivalWaitForHostCount:1 phase:3];
            break;
        case 3:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE
                message:"host_count=1 second drain did not deliver the delayed event"];
            [self startHostCountTwo];
            break;
        case 4:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"host_count=2 empty pump unexpectedly returned an event"];
            [self check:self.emptyWaitMainTurnRan
                message:"main run loop could not progress during host_count=2 empty wait"];
            [self startArrivalWaitForHostCount:2 phase:5];
            break;
        case 5: {
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
            [self removeAdditionalSessions];
            [self startHostCountFour];
            break;
        }
        case 6:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"host_count=4 empty pump unexpectedly returned an event"];
            [self check:self.emptyWaitMainTurnRan
                message:"main run loop could not progress during host_count=4 empty wait"];
            [self startArrivalWaitForHostCount:4 phase:7];
            break;
        case 7: {
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
            [self removeAdditionalSessions];
            [self startABAWait];
            break;
        }
        case 10: {
            [self check:status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION
                message:"stale wait did not reject the retired session generation"];
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"stale wait returned an event from the replacement session"];
            [self check:elapsed >= kProbeMinimumWaitMicros && elapsed <= kProbeMaximumReadbackMicros
                message:"ABA wait did not reach its bounded second-drain boundary"];
            CJGuiInternalSession *replacement = CjguiLookupSession(self.replacementSession);
            [self check:replacement != nil && replacement.pendingInteractions.count == 1
                message:"stale wait consumed the replacement-session FIFO sentinel"];
            [self startPumpPhase:11 hostCount:1 session:self.replacementSession];
            break;
        }
        case 11:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO
                message:"replacement session could not consume its untouched FIFO sentinel"];
            [self check:elapsed < kProbeMinimumWaitMicros
                message:"replacement-session FIFO sentinel did not return promptly"];
            [self startCloseWait];
            break;
        case 12:
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE
                message:"normal window close intent was not delivered through the pump"];
            [self check:elapsed >= kProbeMinimumWaitMicros && elapsed <= kProbeMaximumReadbackMicros
                message:"close-intent pump did not complete within its bounded wait"];
            [self check:cjgui_internal_renderer_request_close(token) == CJGUI_INTERNAL_RENDERER_OK
                message:"normal close decision failed to close the final window"];
            // The framework owner normally decides whether to exit after
            // processing close. Stop the test-owned NSApplication loop after
            // that decision so an app-policy difference cannot hang this probe.
            cjgui_internal_renderer_request_application_stop();
            break;
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
        printf("NATIVE_PUMP_WAIT PASS immediate_fifo=1 host_counts=1,2,4 empty_and_delayed=1 main_progress=1 target_fifo_isolation=1 session_generation_aba=1 replacement_fifo_preserved=1 close_intent=1 final_window_loop_exit=1 source=private_fifo_boundary_probe\n");
    }
    return 0;
}
