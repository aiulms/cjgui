// Regression for the macOS pump's owner/main-queue handoff. This is a native
// controlled probe: it uses a real NSApplication main run loop and private FIFO
// sentinels; it does not claim physical input or normal-app behavior.
#define CJGUI_OWNER_PUMP_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <unistd.h>
#include <stdatomic.h>

static const uint64_t kPromptReturnLimitMicros = 12000;
static const uint64_t kMainQueueBlockMicros = 60000;
static const uint64_t kWatchdogMicros = 4000000;
static const uint64_t kGeometryQueryReturnLimitMicros = 12000;
static const uint32_t kFirstKind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT;
static const uint32_t kSecondKind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO;
static const uint32_t kReplacementKind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE;
static _Atomic(bool) gPumpProbeOwnerCallStarted = false;
static _Atomic(bool) gPumpProbeGeometryBlockStarted = false;

static uint64_t ProbeMicros(void) {
    return CjguiCaretBlinkClockMicros();
}

static BOOL ProbePointerGeometryIsZero(CjguiInternalRendererPointerEventGeometry geometry) {
    return geometry.present == 0 && geometry.kind == 0 && geometry.nodeId == 0 &&
        geometry.projectionVersion == 0 && geometry.resourceId == 0 && geometry.nodeKind == 0 &&
        geometry.reserved == 0 && geometry.x == 0.0 && geometry.y == 0.0 &&
        geometry.translateX == 0.0 && geometry.translateY == 0.0;
}

@interface CjguiOwnerPumpAsyncTicketProbe : NSObject
@property(nonatomic, assign) uint64_t session;
@property(nonatomic, assign) uint64_t staleSession;
@property(nonatomic, assign) uint64_t replacementSession;
@property(nonatomic, assign) BOOL failed;
@property(nonatomic, assign) BOOL watchdogFired;
@property(nonatomic, assign) BOOL firstCallFinished;
@property(nonatomic, assign) uint64_t firstCallElapsedMicros;
@property(nonatomic, assign) uint32_t firstCallKind;
@property(nonatomic, assign) BOOL pendingPollsEmpty;
@property(nonatomic, assign) uint64_t pendingPollsElapsedMicros;
@property(nonatomic, assign) BOOL staleCallFinished;
@property(nonatomic, assign) uint32_t staleCallKind;
@property(nonatomic, assign) uint64_t guardLifecycleCompletedNs;
@property(nonatomic, assign) uint64_t guardMainThreadId;
@property(nonatomic, assign) uint64_t guardNewGeneration;
@property(nonatomic, assign) uint64_t readyNoneWakeNonce;
@property(nonatomic, assign) uint64_t readyNoneWakeNextNonce;
@property(nonatomic, assign) uint64_t readyNoneWakeStartedMicros;
@property(nonatomic, assign) uint64_t readyNoneWakeEnqueuedMicros;
@property(nonatomic, assign) BOOL readyNoneWakeEnqueueStarted;
@property(nonatomic, assign) uint64_t readyNoneNullNonce;
@property(nonatomic, assign) uint64_t readyNoneNullNextNonce;
@property(nonatomic, assign) BOOL readyNoneNullWaitFinished;
@property(nonatomic, assign) BOOL readyNoneFollowupFinished;
@property(nonatomic, strong) dispatch_queue_t workerQueue;
@property(nonatomic, strong) NSMutableArray<NSNumber *> *receivedKinds;
@property(nonatomic, assign) uint64_t receivedEventCount;
@end

@implementation CjguiOwnerPumpAsyncTicketProbe

- (void)check:(BOOL)condition message:(const char *)message {
    if (condition) return;
    self.failed = YES;
    fprintf(stderr, "OWNER_PUMP_TICKET FAIL: %s\n", message);
}

- (BOOL)queueKind:(uint32_t)kind session:(uint64_t)token {
    CJGuiInternalSession *ctx = CjguiLookupSession(token);
    if (!ctx || ctx.destroyed) return NO;
    return CjguiEnqueueInteraction(ctx, kind, 0, @"", 0, 0);
}

- (void)startQueueDelayCase {
    [self check:[self queueKind:kFirstKind session:self.session] &&
                [self queueKind:kSecondKind session:self.session]
        message:"could not queue ordered sentinels before the delayed main-queue service"];
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        uint64_t started = ProbeMicros();
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(self.session, 0, &event);
        uint64_t ended = ProbeMicros();
        [self check:cjgui_internal_renderer_owner_pump_has_unconsumed_input(self.session) == 1
            message:"pending AppKit acquisition did not retain its original input scene"];
        BOOL pendingPollsEmpty = YES;
        uint64_t pendingPollsStarted = ProbeMicros();
        for (NSUInteger index = 0; index < 3; index++) {
            CjguiInternalRendererEvent repeated = {0};
            CjguiInternalRendererStatus repeatedStatus =
                cjgui_internal_renderer_pump_event(self.session, 0, &repeated);
            if (repeatedStatus != CJGUI_INTERNAL_RENDERER_OK ||
                repeated.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                pendingPollsEmpty = NO;
            }
        }
        uint64_t pendingPollsEnded = ProbeMicros();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.firstCallElapsedMicros = ended >= started ? ended - started : UINT64_MAX;
            self.firstCallKind = event.kind;
            self.pendingPollsEmpty = pendingPollsEmpty;
            self.pendingPollsElapsedMicros = pendingPollsEnded >= pendingPollsStarted
                ? pendingPollsEnded - pendingPollsStarted : UINT64_MAX;
            self.firstCallFinished = status == CJGUI_INTERNAL_RENDERER_OK;
            printf("OWNER_PUMP_TICKET_SAMPLE phase=main_queue_delay elapsed_us=%llu event_kind=%u status=%u\n",
                (unsigned long long)self.firstCallElapsedMicros, self.firstCallKind, (unsigned)status);
            [self check:self.firstCallFinished
                message:"pump did not return a valid status during the delayed-main-queue case"];
            [self check:self.firstCallElapsedMicros < kPromptReturnLimitMicros
                message:"owner pump call waited for the deliberately blocked main queue"];
            [self check:self.firstCallKind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"first owner poll returned data before its asynchronous main service completed"];
            [self check:self.pendingPollsEmpty &&
                        self.pendingPollsElapsedMicros < kPromptReturnLimitMicros
                message:"repeated polls while one ticket was pending blocked or returned an event"];
            [self.receivedKinds removeAllObjects];
            if (self.firstCallKind != CJGUI_INTERNAL_RENDERER_EVENT_NONE)
                [self.receivedKinds addObject:@(self.firstCallKind)];
            [self pollUntilTwoOrderedEvents];
        });
    });
    // Keep the actual AppKit main queue unavailable while the worker submits
    // its request. dispatch_sync-based production code returns only after this
    // block exits; the async ticket path returns before the delay elapses.
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"owner worker did not start the delayed-main-queue request"];
    usleep((useconds_t)kMainQueueBlockMicros);
}

- (void)pollUntilTwoOrderedEvents {
    [self check:cjgui_internal_renderer_owner_pump_has_unconsumed_input(self.session) == 1
        message:"READY event lost its original input scene before owner consumption"];
    dispatch_async(self.workerQueue, ^{
        NSMutableArray<NSNumber *> *kinds = [NSMutableArray array];
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(
                self.session, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                [kinds addObject:@(event.kind)];
                if (kinds.count == 2) break;
            }
            usleep(1000);
        }
        [self check:cjgui_internal_renderer_owner_pump_has_unconsumed_input(self.session) == 0
            message:"consuming the exact READY event did not release scene publication"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.receivedKinds addObjectsFromArray:kinds];
            NSArray<NSNumber *> *expected = @[@(kFirstKind), @(kSecondKind)];
            [self check:[self.receivedKinds isEqualToArray:expected]
                message:"ordered FIFO events were lost, duplicated, or returned out of order"];
            [self verifyNoDuplicatePollsThenRetire];
        });
    });
}

- (void)verifyNoDuplicatePollsThenRetire {
    uint64_t token = self.session;
    dispatch_async(self.workerQueue, ^{
        BOOL allEmpty = YES;
        for (NSUInteger index = 0; index < 6; index++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererStatus status =
                cjgui_internal_renderer_pump_event(token, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK ||
                event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                allEmpty = NO;
                break;
            }
            usleep(1000);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:allEmpty
                message:"repeated owner polls returned an already-consumed FIFO event"];
            [self startRetiredTicketCase];
        });
    });
}

- (void)startRetiredTicketCase {
    self.staleSession = [self createReplacementSession];
    uint64_t oldSession = self.staleSession;
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(oldSession, 0, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.staleCallKind = event.kind;
            self.staleCallFinished = status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION ||
                status == CJGUI_INTERNAL_RENDERER_OK;
        });
    });
    // This method runs on main. Keep that queue inside this callback until the
    // owner request is pending, then retire/reuse its slot before its block can
    // run. Synchronous production code waits here and then sees the replacement
    // FIFO; a generation-bound ticket must leave it untouched.
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"retired-session owner request did not start"];
    usleep(5000);
    CjguiInternalRendererStatus retired = cjgui_internal_renderer_destroy(oldSession);
    [self check:retired == CJGUI_INTERNAL_RENDERER_OK
        message:"destroying the session with one pending pump ticket failed"];
    self.replacementSession = [self createReplacementSession];
    [self check:self.replacementSession == oldSession
        message:"ticket lifecycle fixture did not reuse the retired session slot"];
    [self check:[self queueKind:kReplacementKind session:self.replacementSession]
        message:"could not queue the replacement-session sentinel"];
    usleep((useconds_t)kMainQueueBlockMicros);
    [self consumeReplacementSentinel];
}

- (uint64_t)createReplacementSession {
    CjguiInternalRendererConfig config = { .windowWidth = 360, .windowHeight = 240 };
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t token = cjgui_internal_renderer_create(&config, &status);
    [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                token != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        message:"replacement session creation failed"];
    return token;
}

- (void)consumeReplacementSentinel {
    uint64_t token = self.replacementSession;
    dispatch_async(self.workerQueue, ^{
        uint32_t eventKind = CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererStatus status =
                cjgui_internal_renderer_pump_event(token, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) {
                eventKind = event.kind;
                break;
            }
            usleep(1000);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:eventKind == kReplacementKind
                message:"a retired session ticket consumed the replacement session FIFO"];
            [self check:self.staleCallFinished
                message:"the retired owner request did not reach a terminal state"];
            [self startCoordinateEpochCases];
        });
    });
}

- (void)startCoordinateEpochCases {
    uint64_t generation = 0;
    uint64_t sourceEpoch = cjgui_internal_renderer_coordinate_lifetime(self.session, &generation);
    CJGuiInternalSession *ctx = CjguiLookupSession(self.session);
    [self check:ctx != nil && sourceEpoch != 0 && generation != 0
        message:"coordinate ticket fixture could not read the live session tuple"];
    if (!ctx || sourceEpoch == 0 || generation == 0) { [self finish]; return; }
    CJGuiInternalQueuedInteraction *range = [[CJGuiInternalQueuedInteraction alloc]
        initWithKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED
        recordIndex:0 selectionStart:0 selectionEnd:0 formText:@"" nodeId:501
        projectionVersion:1 resourceId:7 nodeKind:1];
    range.bindingEpoch = 9;
    range.installedRangeNonce = 701;
    [ctx.pendingInteractions addObject:range];
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            status = cjgui_internal_renderer_pump_event(self.session, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK ||
                event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
            usleep(1000);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            uint64_t currentGeneration = 0;
            uint64_t currentEpoch = cjgui_internal_renderer_coordinate_lifetime(
                self.session, &currentGeneration);
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED
                message:"coordinate epoch change discarded an already queued kind-51 ticket"];
            [self check:currentGeneration == generation && currentEpoch > sourceEpoch
                message:"controlled geometry epoch did not advance within the live session generation"];
            [self startPointerCoordinateEpochCase:generation];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"kind-51 owner ticket did not start"];
    usleep(5000);
    CjguiBumpCoordinateLifetimeForIdentity(self.session, generation);
}

- (void)startPointerCoordinateEpochCase:(uint64_t)generation {
    uint64_t capturedGeneration = 0;
    uint64_t capturedEpoch = cjgui_internal_renderer_coordinate_lifetime(
        self.session, &capturedGeneration);
    CJGuiInternalSession *ctx = CjguiLookupSession(self.session);
    [self check:ctx != nil && capturedGeneration == generation && capturedEpoch != 0
        message:"pointer tuple fixture could not capture a live coordinate origin"];
    if (!ctx || capturedGeneration != generation || capturedEpoch == 0) { [self finish]; return; }
    CJGuiInternalQueuedInteraction *pointer = [[CJGuiInternalQueuedInteraction alloc]
        initWithKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE
        recordIndex:0 selectionStart:0 selectionEnd:0 formText:@"" nodeId:502
        projectionVersion:1 resourceId:8 nodeKind:1];
    pointer.coordinateSessionGeneration = capturedGeneration;
    pointer.coordinateEpoch = capturedEpoch;
    pointer.hasPrecisePointer = YES;
    pointer.precisePointerX = 14.5;
    pointer.precisePointerY = 22.5;
    [ctx.pendingInteractions addObject:pointer];
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
        uint64_t ownerGeneration = 0;
        uint64_t ownerEpoch = 0;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            status = cjgui_internal_renderer_pump_event(self.session, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK ||
                event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
            usleep(1000);
        }
        int hasOwnerTuple = cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
            self.session, &ownerGeneration, &ownerEpoch);
        dispatch_async(dispatch_get_main_queue(), ^{
            uint64_t currentGeneration = 0;
            uint64_t currentEpoch = cjgui_internal_renderer_coordinate_lifetime(
                self.session, &currentGeneration);
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE
                message:"queued pointer event was lost across a coordinate epoch change"];
            [self check:hasOwnerTuple == 1 && ownerGeneration == capturedGeneration &&
                        ownerEpoch == capturedEpoch && currentGeneration == capturedGeneration &&
                        currentEpoch > capturedEpoch
                message:"READY pointer ticket did not preserve its original coordinate tuple"];
            printf("OWNER_PUMP_TICKET_COORDINATE kind51_preserved=1 pointer_origin_preserved=1 epoch_advanced=1\n");
            [self startPointerStreamSequenceCases];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"pointer owner ticket did not start"];
    usleep(5000);
    CjguiBumpCoordinateLifetimeForIdentity(self.session, generation);
}

- (CJGuiInternalComposableSceneNode *)pointerStreamTestNodeForSession:(CJGuiInternalSession *)ctx {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    node.node = (CjguiInternalRendererComposableNode){
        .nodeId = 502, .resourceId = 8, .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER,
        .isInteractive = 1, .isReadOnly = 0, .width = 100, .height = 24,
    };
    node.index = 0;
    node.geometry = (CjguiInternalRendererComposableGeometry){0};
    ctx.composableNodes = [NSMutableArray arrayWithObject:node];
    ctx.composableSceneVersion = 1;
    return node;
}

- (void)startPointerStreamSequenceCases {
    CJGuiInternalSession *ctx = CjguiLookupSession(self.session);
    [self check:ctx != nil message:"legacy pointer stream fixture lost its session"];
    if (!ctx) { [self finish]; return; }
    [ctx.pendingInteractions removeAllObjects];
    CJGuiInternalComposableSceneNode *node = [self pointerStreamTestNodeForSession:ctx];
    ctx.nextPointerGestureEpoch = 20;
    BOOL begin = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN, node, NSMakePoint(1, 2), 21);
    BOOL update2 = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(2, 3), 21);
    BOOL update3 = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(3, 4), 21);
    [self check:begin && update2 && update3 && ctx.pendingInteractions.count == 2
        message:"legacy pointer stream did not admit BEGIN and coalesce adjacent UPDATEs"];
    CJGuiInternalQueuedInteraction *queuedBegin = ctx.pendingInteractions.firstObject;
    CJGuiInternalQueuedInteraction *coalesced = ctx.pendingInteractions.lastObject;
    [self check:queuedBegin.pointerStreamBindingEpoch == 21 &&
                queuedBegin.pointerStreamFirstSequence == 1 &&
                queuedBegin.pointerStreamLastSequence == 1 &&
                queuedBegin.pointerStreamPreviousSequence == 0 &&
                coalesced.pointerStreamBindingEpoch == 21 &&
                coalesced.pointerStreamFirstSequence == 2 &&
                coalesced.pointerStreamPreviousSequence == 1 &&
                coalesced.pointerStreamLastSequence == 3
        message:"coalesced updates lost first/previous/last FIFO coverage"];

    [self check:CjguiEnqueueComposableInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, 0, @"", NSMakeRange(0, 0))
        message:"could not enqueue an unrelated interaction between stream samples"];
    BOOL update4 = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(4, 5), 21);
    BOOL end5 = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END, node, NSMakePoint(5, 6), 21);
    CJGuiInternalQueuedInteraction *afterOtherEvent = ctx.pendingInteractions[3];
    CJGuiInternalQueuedInteraction *terminal = ctx.pendingInteractions[4];
    [self check:update4 && end5 &&
                afterOtherEvent.pointerStreamFirstSequence == 4 &&
                afterOtherEvent.pointerStreamPreviousSequence == 3 &&
                afterOtherEvent.pointerStreamLastSequence == 4 &&
                terminal.pointerStreamFirstSequence == 5 &&
                terminal.pointerStreamPreviousSequence == 4 &&
                terminal.pointerStreamLastSequence == 5
        message:"non-pointer FIFO item created a pointer stream sequence gap"];

    BOOL oldEpochUpdate = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(6, 7), 21);
    ctx.nextPointerGestureEpoch = 21;
    BOOL nextBegin = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN, node, NSMakePoint(7, 8), 22);
    CJGuiInternalQueuedInteraction *newStream = ctx.pendingInteractions.lastObject;
    [self check:!oldEpochUpdate && nextBegin &&
                newStream.pointerStreamBindingEpoch == 22 &&
                newStream.pointerStreamFirstSequence == 1 &&
                newStream.pointerStreamPreviousSequence == 0 &&
                newStream.pointerStreamLastSequence == 1
        message:"new BEGIN did not start an independent stream or old epoch was accepted"];
    BOOL cancel2 = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL, node, NSMakePoint(8, 9), 22);
    CJGuiInternalQueuedInteraction *cancelled = ctx.pendingInteractions.lastObject;
    [self check:cancel2 && cancelled.pointerStreamBindingEpoch == 22 &&
                cancelled.pointerStreamFirstSequence == 2 &&
                cancelled.pointerStreamPreviousSequence == 1 &&
                cancelled.pointerStreamLastSequence == 2 &&
                cancelled.pointerStreamPhase == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL
        message:"CANCEL did not close exactly the current pointer stream sequence"];
    BOOL updateAfterCancel = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(9, 10), 22);
    [self check:!updateAfterCancel message:"a terminal CANCEL left its pointer stream open"];

    [ctx.pendingInteractions removeAllObjects];
    ctx.nextPointerGestureEpoch = 22;
    BOOL capacityBegin = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN, node, NSMakePoint(1, 2), 23);
    BOOL capacityUpdate = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(2, 3), 23);
    while (ctx.pendingInteractions.count < kCjguiPendingInteractionCapacity) {
        CJGuiInternalQueuedInteraction *filler = [[CJGuiInternalQueuedInteraction alloc]
            initWithKind:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT
            recordIndex:0 selectionStart:0 selectionEnd:0 formText:@"" nodeId:0
            projectionVersion:0 resourceId:-1 nodeKind:0];
        if (!filler) break;
        [ctx.pendingInteractions addObject:filler];
    }
    BOOL fullRejected = !CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(3, 4), 23);
    while (ctx.pendingInteractions.count > 2) [ctx.pendingInteractions removeLastObject];
    BOOL retrySequence = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(4, 5), 23);
    CJGuiInternalQueuedInteraction *afterRejected = ctx.pendingInteractions.lastObject;
    [self check:capacityBegin && capacityUpdate && fullRejected && retrySequence &&
                afterRejected.pointerStreamFirstSequence == 2 &&
                afterRejected.pointerStreamPreviousSequence == 1 &&
                afterRejected.pointerStreamLastSequence == 3
        message:"failed FIFO admission advanced the legacy pointer stream counter"];

    [ctx.pendingInteractions removeAllObjects];
    ctx.pendingInputQueueFullNotice = NO;
    ctx.nextPointerGestureEpoch = 23;
    BOOL asyncBegin = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN, node, NSMakePoint(9, 10), 24);
    CjguiInternalRendererComposableGeometry nextGeometry = node.geometry;
    nextGeometry.translateX = 17.0;
    node.geometry = nextGeometry;
    BOOL queuedFollowingUpdate = CjguiEnqueueComposableCapturedPointerInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE, node, NSMakePoint(29, 31), 24);
    [self check:asyncBegin && queuedFollowingUpdate
        message:"could not enqueue distinct pointer geometries for the READY ticket probe"];
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
        int hasStream = 0;
        uint64_t streamGeneration = 0, bindingEpoch = 0, first = 0, last = 0, previous = 0;
        uint32_t phase = 0;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            status = cjgui_internal_renderer_pump_event(self.session, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK || event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
            usleep(1000);
        }
        hasStream = cjgui_internal_renderer_owner_consumed_pointer_fifo(self.session,
            &streamGeneration, &bindingEpoch, &first, &last, &previous, &phase);
        dispatch_semaphore_t wrongOwnerDone = dispatch_semaphore_create(0);
        __block CjguiInternalRendererStatus wrongOwnerGeometryStatus =
            CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        __block CjguiInternalRendererPointerEventGeometry wrongOwnerGeometry = {
            .present = UINT32_MAX, .kind = UINT32_MAX, .nodeId = UINT64_MAX,
            .projectionVersion = UINT64_MAX, .resourceId = INT64_MAX,
            .nodeKind = UINT32_MAX, .reserved = UINT32_MAX,
            .x = 1.0, .y = 1.0, .translateX = 1.0, .translateY = 1.0,
        };
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            wrongOwnerGeometryStatus =
                cjgui_internal_renderer_pumped_pointer_geometry(self.session, &wrongOwnerGeometry);
            dispatch_semaphore_signal(wrongOwnerDone);
        });
        BOOL wrongOwnerReadCompleted = dispatch_semaphore_wait(wrongOwnerDone,
            dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0;
        BOOL wrongOwnerReadWasUnknown = wrongOwnerReadCompleted &&
            wrongOwnerGeometryStatus == CJGUI_INTERNAL_RENDERER_OK &&
            ProbePointerGeometryIsZero(wrongOwnerGeometry);
        dispatch_semaphore_t releaseMainQueue = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            // This is an actual second dequeue on AppKit's main thread. It
            // changes the live ctx geometry after ticket A was consumed, then
            // holds the main queue while the owner asks for A's geometry.
            gCjguiOwnerPumpServicingAsyncTicket = YES;
            CjguiInternalRendererEvent following = {0};
            CjguiInternalRendererStatus followingStatus =
                cjgui_internal_renderer_pump_event(self.session, 0, &following);
            gCjguiOwnerPumpServicingAsyncTicket = NO;
            [self check:followingStatus == CJGUI_INTERNAL_RENDERER_OK &&
                        following.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE
                message:"controlled second pointer dequeue did not produce the following event"];
            atomic_store_explicit(&gPumpProbeGeometryBlockStarted, true, memory_order_release);
            dispatch_semaphore_wait(releaseMainQueue, DISPATCH_TIME_FOREVER);
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60000 * NSEC_PER_USEC),
            dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                dispatch_semaphore_signal(releaseMainQueue);
            });
        for (NSUInteger attempt = 0; attempt < 1000 &&
             !atomic_load_explicit(&gPumpProbeGeometryBlockStarted, memory_order_acquire); attempt++)
            usleep(100);
        uint64_t geometryStarted = ProbeMicros();
        CjguiInternalRendererPointerEventGeometry geometry = {0};
        CjguiInternalRendererStatus geometryStatus =
            cjgui_internal_renderer_pumped_pointer_geometry(self.session, &geometry);
        uint64_t geometryEnded = ProbeMicros();
        uint64_t geometryElapsed = geometryEnded >= geometryStarted
            ? geometryEnded - geometryStarted : UINT64_MAX;
        CjguiInternalRendererEvent noneEvent = {0};
        CjguiInternalRendererStatus noneStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            noneStatus = cjgui_internal_renderer_pump_event(self.session, 0, &noneEvent);
            if (noneStatus != CJGUI_INTERNAL_RENDERER_OK ||
                noneEvent.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
            usleep(1000);
        }
        CjguiInternalRendererPointerEventGeometry noneGeometry = {
            .present = UINT32_MAX, .kind = UINT32_MAX, .nodeId = UINT64_MAX,
            .projectionVersion = UINT64_MAX, .resourceId = INT64_MAX,
            .nodeKind = UINT32_MAX, .reserved = UINT32_MAX,
            .x = 1.0, .y = 1.0, .translateX = 1.0, .translateY = 1.0,
        };
        CjguiInternalRendererStatus noneGeometryStatus =
            cjgui_internal_renderer_pumped_pointer_geometry(self.session, &noneGeometry);
        printf("OWNER_PUMP_TICKET_GEOMETRY_NONE status=%u kind=%u geometry_status=%u present=%u x=%.3f y=%.3f\n",
            (unsigned)noneStatus, noneEvent.kind, (unsigned)noneGeometryStatus,
            noneGeometry.present, noneGeometry.x, noneGeometry.y);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN &&
                        hasStream == 1 && streamGeneration == ctx.sessionGeneration &&
                        bindingEpoch == 24 && first == 1 && last == 1 && previous == 0 &&
                        phase == event.kind
                message:"async READY owner consume did not preserve the exact legacy stream sideband"];
            [self check:atomic_load_explicit(&gPumpProbeGeometryBlockStarted, memory_order_acquire)
                message:"main queue geometry blocker did not reach its controlled wait"];
            [self check:wrongOwnerReadWasUnknown
                message:"a different OS thread stole or cleared the owner-consumed geometry snapshot"];
            [self check:geometryStatus == CJGUI_INTERNAL_RENDERER_OK && geometry.present == 1 &&
                        geometry.kind == event.kind && geometry.nodeId == event.nodeId &&
                        geometry.projectionVersion == event.projectionVersion &&
                        geometry.resourceId == event.resourceId && geometry.nodeKind == event.nodeKind &&
                        geometry.x == 9.0 && geometry.y == 10.0 && geometry.translateX == 0.0
                message:"owner geometry lookup returned the later dequeue's geometry instead of its ticket copy"];
            [self check:geometryElapsed < kGeometryQueryReturnLimitMicros
                message:"off-main owner geometry lookup waited for the deliberately blocked main queue"];
            [self check:noneStatus == CJGUI_INTERNAL_RENDERER_OK &&
                        noneEvent.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE &&
                        noneGeometryStatus == CJGUI_INTERNAL_RENDERER_OK &&
                        ProbePointerGeometryIsZero(noneGeometry)
                message:"NONE poll retained geometry from the previous consumed ticket"];
            printf("OWNER_PUMP_TICKET_GEOMETRY first_kind=%u following_kind=%u query_us=%llu exact_ticket=1 main_blocked=1\n",
                event.kind, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,
                (unsigned long long)geometryElapsed);
            printf("OWNER_PUMP_TICKET_GEOMETRY_NONSTEAL wrong_thread_unknown=%u owner_retained=1\n",
                wrongOwnerReadWasUnknown ? 1 : 0);
            uint64_t unknownGeneration = UINT64_MAX, unknownBinding = UINT64_MAX;
            uint64_t unknownFirst = UINT64_MAX, unknownLast = UINT64_MAX, unknownPrevious = UINT64_MAX;
            uint32_t unknownPhase = UINT32_MAX;
            cjgui_internal_renderer_publish_owner_consumed_pointer_fifo(self.session,
                0, 0, 0, 0, 0, 0);
            [self check:cjgui_internal_renderer_owner_consumed_pointer_fifo(self.session,
                &unknownGeneration, &unknownBinding, &unknownFirst, &unknownLast,
                &unknownPrevious, &unknownPhase) == 0 && unknownGeneration == 0 &&
                unknownBinding == 0 && unknownFirst == 0 && unknownLast == 0 &&
                unknownPrevious == 0 && unknownPhase == 0
                message:"NONE/unknown pointer stream getter leaked a prior READY tuple"];
            printf("OWNER_PUMP_TICKET_POINTER_STREAM seq=1 binding=24 ticket_copy=1 unknown_zeroed=1\n");
            [self startGeometryCloseAndReuseCases];
        });
    });
}

- (void)startGeometryCloseAndReuseCases {
    CjguiInternalRendererStatus closeStatus =
        cjgui_internal_renderer_request_close(self.session);
    [self check:closeStatus == CJGUI_INTERNAL_RENDERER_OK
        message:"could not request close for the geometry unknown-state probe"];
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            status = cjgui_internal_renderer_pump_event(self.session, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK ||
                event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
            usleep(1000);
        }
        CjguiInternalRendererPointerEventGeometry geometry = {
            .present = UINT32_MAX, .kind = UINT32_MAX, .nodeId = UINT64_MAX,
            .projectionVersion = UINT64_MAX, .resourceId = INT64_MAX,
            .nodeKind = UINT32_MAX, .reserved = UINT32_MAX,
            .x = 1.0, .y = 1.0, .translateX = 1.0, .translateY = 1.0,
        };
        CjguiInternalRendererStatus geometryStatus =
            cjgui_internal_renderer_pumped_pointer_geometry(self.session, &geometry);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_CLOSE_REQUESTED
                message:"close intent was not delivered to the owner"];
            [self check:geometryStatus == CJGUI_INTERNAL_RENDERER_OK &&
                        ProbePointerGeometryIsZero(geometry)
                message:"close event retained a prior pointer geometry snapshot"];
            uint64_t retiredSession = self.session;
            uint64_t retiredGeneration = CjguiOwnerPumpLiveSessionGeneration(retiredSession);
            CjguiInternalRendererStatus retired =
                cjgui_internal_renderer_destroy(retiredSession);
            uint64_t replacement = [self createReplacementSession];
            uint64_t replacementGeneration = CjguiOwnerPumpLiveSessionGeneration(replacement);
            [self check:retired == CJGUI_INTERNAL_RENDERER_OK &&
                        replacement == retiredSession && replacementGeneration != 0 &&
                        replacementGeneration != retiredGeneration
                message:"geometry snapshot lifecycle probe did not reuse the session with a new generation"];
            self.session = replacement;
            dispatch_async(self.workerQueue, ^{
                CjguiInternalRendererPointerEventGeometry recycled = {
                    .present = UINT32_MAX, .kind = UINT32_MAX, .nodeId = UINT64_MAX,
                    .projectionVersion = UINT64_MAX, .resourceId = INT64_MAX,
                    .nodeKind = UINT32_MAX, .reserved = UINT32_MAX,
                    .x = 1.0, .y = 1.0, .translateX = 1.0, .translateY = 1.0,
                };
                CjguiInternalRendererStatus recycledStatus =
                    cjgui_internal_renderer_pumped_pointer_geometry(replacement, &recycled);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self check:recycledStatus == CJGUI_INTERNAL_RENDERER_OK &&
                                ProbePointerGeometryIsZero(recycled)
                        message:"reused session slot exposed a previous generation's geometry"];
                    [self startGuardBarrierCase:CJGUI_OWNER_PUMP_TEST_BEFORE_GUARD];
                });
            });
        });
    });
}

- (void)startReadyNoneRetirementCase {
    uint64_t oldSession = self.session;
    uint64_t oldGeneration = CjguiOwnerPumpLiveSessionGeneration(oldSession);
    [self check:oldGeneration != 0
        message:"READY-NONE retirement fixture lost its live renderer generation"];
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(
            oldSession, 16, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"READY-NONE old owner poll returned OK after session slot reuse"];
            [self consumeReadyNoneReplacementSentinel];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"READY-NONE retirement owner poll did not start"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneTicketForSession:oldSession
            generation:oldGeneration attempt:0]; });
}

- (void)startReadyNoneEnqueueWakeCase {
    uint64_t token = self.session;
    self.readyNoneWakeNonce = 0;
    self.readyNoneWakeEnqueueStarted = NO;
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        uint64_t started = ProbeMicros();
        self.readyNoneWakeStartedMicros = started;
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(token, 16, &event);
        uint64_t ended = ProbeMicros();
        dispatch_async(dispatch_get_main_queue(), ^{
            uint64_t nextNonce = 0;
            pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
            nextNonce = gCjguiOwnerPumpTicketNextNonce;
            pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
            uint64_t fromEnqueue = ended >= self.readyNoneWakeEnqueuedMicros
                ? ended - self.readyNoneWakeEnqueuedMicros : UINT64_MAX;
            printf("OWNER_PUMP_READY_NONE_WAKE status=%u kind=%u nonce=%llu next_nonce_before=%llu next_nonce_after=%llu enqueue_to_return_us=%llu full_wall_us=%llu\n",
                (unsigned)status, event.kind,
                (unsigned long long)self.readyNoneWakeNonce,
                (unsigned long long)self.readyNoneWakeNextNonce,
                (unsigned long long)nextNonce,
                (unsigned long long)fromEnqueue,
                (unsigned long long)(ended >= started ? ended - started : UINT64_MAX));
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && event.kind == kReplacementKind
                message:"a real FIFO enqueue after READY_NONE was left until the original timeout/next ticket"];
            [self check:self.readyNoneWakeNonce != 0 &&
                        nextNonce == self.readyNoneWakeNextNonce
                message:"READY_NONE arrival replaced the original session/generation/nonce ticket"];
            [self check:self.readyNoneWakeEnqueueStarted && fromEnqueue < 12000
                message:"READY_NONE arrival did not reservice promptly inside the original wait"];
            [self startReadyNonePublishRaceCase];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"READY_NONE wake owner call did not start"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneEnqueueWakeForSession:token attempt:0]; });
}

- (void)startReadyNonePublishRaceCase {
    uint64_t token = self.session;
    atomic_store_explicit(&gCjguiOwnerPumpTestPublishRaceNonce, 0, memory_order_relaxed);
    atomic_store_explicit(&gCjguiOwnerPumpTestPublishRaceNextNonce, 0, memory_order_relaxed);
    atomic_store_explicit(&gCjguiOwnerPumpTestEnqueueSession, token, memory_order_relaxed);
    atomic_store_explicit(&gCjguiOwnerPumpTestEnqueueKind, kSecondKind, memory_order_relaxed);
    atomic_store_explicit(&gCjguiOwnerPumpTestEnqueueBeforeReadyNonePublish, true,
        memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        uint64_t started = ProbeMicros();
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(token, 16, &event);
        uint64_t ended = ProbeMicros();
        dispatch_async(dispatch_get_main_queue(), ^{
            uint64_t nextNonceAfter = 0;
            uint64_t raceNonce = atomic_load_explicit(&gCjguiOwnerPumpTestPublishRaceNonce,
                memory_order_relaxed);
            uint64_t nextNonceBefore = atomic_load_explicit(&gCjguiOwnerPumpTestPublishRaceNextNonce,
                memory_order_relaxed);
            pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
            nextNonceAfter = gCjguiOwnerPumpTicketNextNonce;
            pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && event.kind == kSecondKind
                message:"work arriving between empty check and READY_NONE publish was lost"];
            [self check:raceNonce != 0 && raceNonce + 1 == nextNonceBefore &&
                        nextNonceAfter == nextNonceBefore
                message:"publish-race recovery allocated a new nonce instead of reusing the ticket"];
            [self check:ended >= started && ended - started < 16000
                message:"publish-race reservice extended the original owner deadline"];
            printf("OWNER_PUMP_READY_NONE_PUBLISH_RACE kind=%u ticket_nonce=%llu next_nonce_before=%llu next_nonce_after=%llu full_wall_us=%llu same_ticket=1\n",
                event.kind, (unsigned long long)raceNonce,
                (unsigned long long)nextNonceBefore,
                (unsigned long long)nextNonceAfter,
                (unsigned long long)(ended >= started ? ended - started : UINT64_MAX));
            [self startReadyNoneBatchMergeCase];
        });
    });
}

- (void)startNullOutEventNoStealCase {
    uint64_t token = self.session;
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(token, 16, NULL);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK
                message:"NULL outEvent owner poll did not finish within its original positive wait"];
            self.readyNoneNullWaitFinished = YES;
            printf("OWNER_PUMP_NULL_OUT_EVENT status=%u output_buffer=NULL\n", (unsigned)status);
            [self finishNullFollowupIfReady];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"NULL outEvent owner call did not start"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneForNullOutEvent:token attempt:0]; });
}

- (void)startReadyNoneNullFollowupCase {
    uint64_t token = self.session;
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(token, 16, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            uint64_t nextNonce = 0;
            pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
            nextNonce = gCjguiOwnerPumpTicketNextNonce;
            pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
            CJGuiInternalSession *ctx = CjguiLookupSession(token);
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && event.kind == kFirstKind &&
                        self.readyNoneNullNonce != 0 &&
                        nextNonce == self.readyNoneNullNextNonce && ctx &&
                        ctx.pendingInteractions.count == 0
                message:"a later non-NULL owner call did not service real work on the retained NULL ticket"];
            printf("OWNER_PUMP_NULL_FOLLOWUP status=%u kind=%u nonce=%llu next_nonce_before=%llu next_nonce_after=%llu fifo_empty=%u\n",
                (unsigned)status, event.kind,
                (unsigned long long)self.readyNoneNullNonce,
                (unsigned long long)self.readyNoneNullNextNonce,
                (unsigned long long)nextNonce,
                ctx.pendingInteractions.count == 0 ? 1u : 0u);
            self.readyNoneFollowupFinished = YES;
            [self finishNullFollowupIfReady];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"NULL follow-up non-NULL owner call did not start"];
}

- (void)finishNullFollowupIfReady {
    if (self.readyNoneNullWaitFinished && self.readyNoneFollowupFinished) [self finish];
}

- (void)startReadyNoneBatchMergeCase {
    uint64_t token = self.session;
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(token, 16, &event);
        dispatch_async(dispatch_get_main_queue(), ^{
            CJGuiInternalSession *ctx = CjguiLookupSession(token);
            [self check:status == CJGUI_INTERNAL_RENDERER_OK &&
                        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED &&
                        ctx && [ctx.pumpedFormText isEqualToString:@"latest"] &&
                        ctx.pendingInteractions.count == 0
                message:"legal form-text batch merge did not wake and deliver the newest value"];
            printf("OWNER_PUMP_READY_NONE_BATCH_MERGE status=%u kind=%u latest=%u fifo_empty=%u\n",
                (unsigned)status, event.kind,
                [ctx.pumpedFormText isEqualToString:@"latest"] ? 1u : 0u,
                ctx.pendingInteractions.count == 0 ? 1u : 0u);
            [self startReadyEventPreserveCase];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"READY_NONE batch merge owner call did not start"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneBatchMergeForSession:token attempt:0]; });
}

- (void)startReadyEventPreserveCase {
    uint64_t token = self.session;
    [self check:[self queueKind:kFirstKind session:token]
        message:"could not queue first event for READY preservation case"];
    atomic_store_explicit(&gCjguiOwnerPumpTestAfterEventSession, token, memory_order_relaxed);
    atomic_store_explicit(&gCjguiOwnerPumpTestAfterEventKind, kSecondKind, memory_order_relaxed);
    atomic_store_explicit(&gCjguiOwnerPumpTestEnqueueAfterEvent, true, memory_order_release);
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent first = {0};
        atomic_store_explicit(&gPumpProbeOwnerCallStarted, true, memory_order_release);
        CjguiInternalRendererStatus firstStatus =
            cjgui_internal_renderer_pump_event(token, 16, &first);
        dispatch_async(dispatch_get_main_queue(), ^{
            CjguiInternalRendererEvent second = {0};
            CjguiInternalRendererStatus secondStatus =
                cjgui_internal_renderer_pump_event(token, 0, &second);
            CJGuiInternalSession *ctx = CjguiLookupSession(token);
            [self check:firstStatus == CJGUI_INTERNAL_RENDERER_OK && first.kind == kFirstKind &&
                        !atomic_load_explicit(&gCjguiOwnerPumpTestEnqueueAfterEvent,
                            memory_order_acquire) &&
                        secondStatus == CJGUI_INTERNAL_RENDERER_OK && second.kind == kSecondKind &&
                        ctx && ctx.pendingInteractions.count == 0
                message:"new FIFO work overwrote the READY event or disturbed its next FIFO item"];
            printf("OWNER_PUMP_READY_EVENT_PRESERVE first=%u second=%u injected_after_service=1 fifo_empty=%u\n",
                first.kind, second.kind,
                ctx.pendingInteractions.count == 0 ? 1u : 0u);
            [self startNullOutEventNoStealCase];
        });
    });
    for (NSUInteger attempt = 0; attempt < 1000 &&
         !atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire); attempt++)
        usleep(100);
    [self check:atomic_load_explicit(&gPumpProbeOwnerCallStarted, memory_order_acquire)
        message:"READY-event preservation owner call did not start"];
}

- (void)pollReadyNoneBatchMergeForSession:(uint64_t)token attempt:(NSUInteger)attempt {
    NSUInteger index = CjguiOwnerPumpTicketIndex(token);
    BOOL readyNone = NO;
    if (index != NSNotFound) {
        pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
        CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
        readyNone = ticket->state == CjguiOwnerPumpTicketReady &&
            ticket->session == token &&
            ticket->sessionGeneration == CjguiOwnerPumpLiveSessionGeneration(token) &&
            ticket->status == CJGUI_INTERNAL_RENDERER_OK &&
            ticket->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    }
    if (readyNone) {
        CJGuiInternalSession *ctx = CjguiLookupSession(token);
        BOOL first = ctx && CjguiEnqueueInteraction(ctx,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED, 0, @"first", 1, 1);
        BOOL merged = first && CjguiEnqueueInteraction(ctx,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED, 0, @"latest", 6, 6);
        [self check:first && merged && ctx.pendingInteractions.count == 1 &&
                    ctx.pendingInteractions.firstObject.kind ==
                        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED &&
                    [ctx.pendingInteractions.firstObject.formText isEqualToString:@"latest"]
            message:"could not create a real private FIFO form-text batch merge after READY_NONE"];
        return;
    }
    if (attempt >= 100) {
        [self check:NO message:"batch merge owner ticket did not publish READY_NONE"];
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneBatchMergeForSession:token attempt:attempt + 1]; });
}

- (void)pollReadyNoneForNullOutEvent:(uint64_t)token attempt:(NSUInteger)attempt {
    NSUInteger index = CjguiOwnerPumpTicketIndex(token);
    BOOL readyNone = NO;
    if (index != NSNotFound) {
        pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
        CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
        readyNone = ticket->state == CjguiOwnerPumpTicketReady &&
            ticket->session == token &&
            ticket->sessionGeneration == CjguiOwnerPumpLiveSessionGeneration(token) &&
            ticket->status == CJGUI_INTERNAL_RENDERER_OK &&
            ticket->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    }
    if (readyNone) {
        CJGuiInternalSession *ctx = CjguiLookupSession(token);
        pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
        CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
        self.readyNoneNullNonce = ticket->nonce;
        self.readyNoneNullNextNonce = gCjguiOwnerPumpTicketNextNonce;
        pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
        BOOL enqueued = ctx && CjguiEnqueueInteraction(ctx, kFirstKind, 0, @"", 0, 0);
        [self check:enqueued && ctx.pendingInteractions.count == 1 &&
                    ctx.pendingInteractions.firstObject.kind == kFirstKind
            message:"could not enqueue the real FIFO sentinel for the NULL outEvent case"];
        printf("OWNER_PUMP_NULL_OUT_EVENT_RETAINED nonce=%llu fifo_count=%lu\n",
            (unsigned long long)self.readyNoneNullNonce,
            (unsigned long)(ctx ? ctx.pendingInteractions.count : 0));
        [self startReadyNoneNullFollowupCase];
        return;
    }
    if (attempt >= 100) {
        [self check:NO message:"NULL outEvent ticket did not publish READY_NONE"];
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneForNullOutEvent:token attempt:attempt + 1]; });
}

- (void)pollReadyNoneEnqueueWakeForSession:(uint64_t)token attempt:(NSUInteger)attempt {
    NSUInteger index = CjguiOwnerPumpTicketIndex(token);
    BOOL readyNone = NO;
    if (index != NSNotFound) {
        pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
        CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
        readyNone = ticket->state == CjguiOwnerPumpTicketReady &&
            ticket->session == token &&
            ticket->sessionGeneration == CjguiOwnerPumpLiveSessionGeneration(token) &&
            ticket->status == CJGUI_INTERNAL_RENDERER_OK &&
            ticket->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        if (readyNone) {
            self.readyNoneWakeNonce = ticket->nonce;
            self.readyNoneWakeNextNonce = gCjguiOwnerPumpTicketNextNonce;
        }
        pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    }
    if (readyNone) {
        CJGuiInternalSession *ctx = CjguiLookupSession(token);
        self.readyNoneWakeEnqueueStarted = ctx && CjguiEnqueueInteraction(ctx,
            kReplacementKind, 0, @"", 0, 0);
        self.readyNoneWakeEnqueuedMicros = ProbeMicros();
        [self check:self.readyNoneWakeEnqueueStarted
            message:"real private owner FIFO enqueue failed after READY_NONE"];
        printf("OWNER_PUMP_READY_NONE_WAKE enqueue nonce=%llu next_nonce=%llu fifo_count=%lu\n",
            (unsigned long long)self.readyNoneWakeNonce,
            (unsigned long long)self.readyNoneWakeNextNonce,
            (unsigned long)(ctx ? ctx.pendingInteractions.count : 0));
        return;
    }
    if (attempt >= 100) {
        [self check:NO message:"owner ticket did not publish READY_NONE before its deadline"];
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneEnqueueWakeForSession:token attempt:attempt + 1]; });
}

- (void)pollReadyNoneTicketForSession:(uint64_t)oldSession generation:(uint64_t)oldGeneration
                              attempt:(NSUInteger)attempt {
    NSUInteger index = CjguiOwnerPumpTicketIndex(oldSession);
    BOOL readyNone = NO;
    if (index != NSNotFound) {
        pthread_mutex_lock(&gCjguiOwnerPumpTicketLock);
        CjguiOwnerPumpTicket *ticket = &gCjguiOwnerPumpTickets[index];
        readyNone = ticket->state == CjguiOwnerPumpTicketReady &&
            ticket->session == oldSession && ticket->sessionGeneration == oldGeneration &&
            ticket->status == CJGUI_INTERNAL_RENDERER_OK &&
            ticket->event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        pthread_mutex_unlock(&gCjguiOwnerPumpTicketLock);
    }
    if (readyNone) {
        if (self.replacementSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN &&
            CjguiLookupSession(self.replacementSession))
            (void)cjgui_internal_renderer_destroy(self.replacementSession);
        CjguiInternalRendererStatus retired = cjgui_internal_renderer_destroy(oldSession);
        [self check:retired == CJGUI_INTERNAL_RENDERER_OK
            message:"could not retire the session after main published READY-NONE"];
        uint64_t replacement = [self createReplacementSession];
        [self check:replacement == oldSession
            message:"READY-NONE fixture did not reuse the retired session slot"];
        self.session = replacement;
        self.replacementSession = replacement;
        [self check:[self queueKind:kReplacementKind session:replacement]
            message:"could not queue the READY-NONE replacement sentinel"];
        printf("OWNER_PUMP_TICKET_READY_NONE observed=1 destroy_before_owner_return=1 slot_reuse=1\n");
        return;
    }
    if (attempt >= 100) {
        [self check:NO message:"owner ticket did not reach READY-NONE before the bounded deadline"];
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollReadyNoneTicketForSession:oldSession
            generation:oldGeneration attempt:attempt + 1]; });
}

- (void)consumeReadyNoneReplacementSentinel {
    uint64_t token = self.replacementSession;
    dispatch_async(self.workerQueue, ^{
        uint32_t kind = CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event(token, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) { kind = event.kind; break; }
            usleep(1000);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:kind == kReplacementKind
                message:"stale READY-NONE cleanup removed or consumed the replacement ticket/FIFO"];
            printf("OWNER_PUMP_TICKET_READY_NONE PASS stale_return_invalid=1 replacement_fifo_preserved=1\n");
            [self finish];
        });
    });
}

- (void)startGuardBarrierCase:(uint32_t)mode {
    uint64_t token = self.session;
    uint64_t generation = CjguiOwnerPumpLiveSessionGeneration(token);
    [self check:generation != 0 message:"guard barrier case has no live session generation"];
    CjguiOwnerPumpTestArmBarrier(mode);
    atomic_store_explicit(&gPumpProbeOwnerCallStarted, false, memory_order_release);
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        uint64_t ownerTid = CjguiOwnerPumpTestThreadId();
        uint64_t started = CjguiOwnerPumpTestMonotonicNs();
        uint64_t idleNs = 0;
        CjguiInternalRendererStatus status = cjgui_internal_renderer_pump_event_measured(
            token, 16, &event, &idleNs);
        uint64_t finished = CjguiOwnerPumpTestMonotonicNs();
        uint64_t returnTid = CjguiOwnerPumpTestThreadId();
        dispatch_async(dispatch_get_main_queue(), ^{
            CjguiOwnerPumpTestBarrier snapshot = {0};
            BOOL reached = CjguiOwnerPumpTestBarrierSnapshot(&snapshot);
            BOOL beforeGuard = mode == CJGUI_OWNER_PUMP_TEST_BEFORE_GUARD;
            [self check:reached && snapshot.mode == mode && snapshot.guardRecorded
                message:"owner did not record the requested guard linearization barrier"];
            [self check:event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"guard barrier case returned an event instead of NONE"];
            [self check:ownerTid != 0 && returnTid == ownerTid &&
                        snapshot.guardThreadId == ownerTid && self.guardMainThreadId != 0 &&
                        self.guardMainThreadId != ownerTid
                message:"guard barrier did not record distinct actual owner/main OS thread IDs"];
            [self check:beforeGuard
                    ? status == CJGUI_INTERNAL_RENDERER_INVALID_SESSION && snapshot.wouldRetire &&
                      snapshot.guardMonotonicNs >= self.guardLifecycleCompletedNs &&
                      snapshot.liveGeneration == self.guardNewGeneration
                    : status == CJGUI_INTERNAL_RENDERER_OK && !snapshot.wouldRetire &&
                      snapshot.liveGeneration == generation &&
                      snapshot.guardMonotonicNs < self.guardLifecycleCompletedNs
                message:"guard decision did not match the forced lifecycle ordering"];
            printf("OWNER_PUMP_GUARD owner mode=%u point_ns=%llu point_tid=%llu live_at_R=%llu expected=%llu would_retire=%u call_start_ns=%llu return_ns=%llu owner_tid=%llu return_tid=%llu full_wall_ns=%llu actual_idle_ns=%llu\n",
                mode, (unsigned long long)snapshot.guardMonotonicNs,
                (unsigned long long)snapshot.guardThreadId,
                (unsigned long long)snapshot.liveGeneration,
                (unsigned long long)snapshot.expectedGeneration,
                snapshot.wouldRetire ? 1 : 0, (unsigned long long)started,
                (unsigned long long)finished, (unsigned long long)ownerTid,
                (unsigned long long)returnTid,
                (unsigned long long)(finished >= started ? finished - started : 0),
                (unsigned long long)idleNs);
            [self consumeGuardBarrierSentinelAfterMode:mode];
        });
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self pollGuardBarrierForMode:mode session:token
            generation:generation attempt:0]; });
}

- (void)pollGuardBarrierForMode:(uint32_t)mode session:(uint64_t)oldSession
                     generation:(uint64_t)oldGeneration attempt:(NSUInteger)attempt {
    CjguiOwnerPumpTestBarrier snapshot = {0};
    if (!CjguiOwnerPumpTestBarrierSnapshot(&snapshot)) {
        if (attempt >= 1000) {
            [self check:NO message:"owner did not reach the guard barrier before watchdog"];
            cjgui_internal_renderer_request_application_stop();
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC),
            dispatch_get_main_queue(), ^{ [self pollGuardBarrierForMode:mode
                session:oldSession generation:oldGeneration attempt:attempt + 1]; });
        return;
    }

    uint64_t mainTid = CjguiOwnerPumpTestThreadId();
    uint64_t mainStartNs = CjguiOwnerPumpTestMonotonicNs();
    uint64_t pointNs = mode == CJGUI_OWNER_PUMP_TEST_BEFORE_GUARD
        ? snapshot.pauseMonotonicNs : snapshot.guardMonotonicNs;
    uint64_t pointTid = mode == CJGUI_OWNER_PUMP_TEST_BEFORE_GUARD
        ? snapshot.pauseThreadId : snapshot.guardThreadId;
    printf("OWNER_PUMP_GUARD main mode=%u owner_point_ns=%llu owner_tid=%llu lifecycle_start_ns=%llu main_tid=%llu old_generation=%llu\n",
        mode, (unsigned long long)pointNs,
        (unsigned long long)pointTid, (unsigned long long)mainStartNs,
        (unsigned long long)mainTid, (unsigned long long)oldGeneration);

    if (self.replacementSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN &&
        self.replacementSession != oldSession && CjguiLookupSession(self.replacementSession))
        (void)cjgui_internal_renderer_destroy(self.replacementSession);
    CjguiInternalRendererStatus retired = cjgui_internal_renderer_destroy(oldSession);
    [self check:retired == CJGUI_INTERNAL_RENDERER_OK
        message:"guard barrier could not retire the session before the selected guard edge"];
    uint64_t retiredNs = CjguiOwnerPumpTestMonotonicNs();
    uint64_t replacement = [self createReplacementSession];
    uint64_t allocatedNs = CjguiOwnerPumpTestMonotonicNs();
    [self check:replacement == oldSession
        message:"guard barrier did not reuse the retired session slot"];
    self.session = replacement;
    self.replacementSession = replacement;
    uint64_t newGeneration = CjguiOwnerPumpLiveSessionGeneration(replacement);
    [self check:newGeneration != 0 && newGeneration != oldGeneration
        message:"guard barrier replacement did not publish a distinct generation"];
    [self check:[self queueKind:kReplacementKind session:replacement]
        message:"guard barrier could not queue replacement FIFO sentinel"];
    uint64_t readyNs = CjguiOwnerPumpTestMonotonicNs();
    self.guardLifecycleCompletedNs = readyNs;
    self.guardMainThreadId = mainTid;
    self.guardNewGeneration = newGeneration;
    printf("OWNER_PUMP_GUARD lifecycle mode=%u main_tid=%llu retired_ns=%llu allocated_ns=%llu sentinel_ns=%llu old_generation=%llu new_generation=%llu replacement_token=%llu injected_pause_ns=%llu\n",
        mode, (unsigned long long)mainTid, (unsigned long long)retiredNs,
        (unsigned long long)allocatedNs,
        (unsigned long long)readyNs, (unsigned long long)oldGeneration,
        (unsigned long long)newGeneration, (unsigned long long)replacement,
        (unsigned long long)(allocatedNs >= pointNs ? allocatedNs - pointNs : 0));
    CjguiOwnerPumpTestReleaseBarrier(mode);
}

- (void)consumeGuardBarrierSentinelAfterMode:(uint32_t)mode {
    uint64_t token = self.replacementSession;
    dispatch_async(self.workerQueue, ^{
        CjguiInternalRendererEvent event = {0};
        uint64_t started = CjguiOwnerPumpTestMonotonicNs();
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            status = cjgui_internal_renderer_pump_event(token, 0, &event);
            if (status != CJGUI_INTERNAL_RENDERER_OK ||
                event.kind != CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
            usleep(1000);
        }
        uint64_t finished = CjguiOwnerPumpTestMonotonicNs();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self check:status == CJGUI_INTERNAL_RENDERER_OK && event.kind == kReplacementKind
                message:"old ticket altered or consumed replacement FIFO sentinel"];
            CjguiInternalRendererEvent duplicate = {0};
            CjguiInternalRendererStatus duplicateStatus = cjgui_internal_renderer_pump_event(
                token, 0, &duplicate);
            [self check:duplicateStatus == CJGUI_INTERNAL_RENDERER_OK &&
                        duplicate.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE
                message:"replacement FIFO sentinel was delivered more than once"];
            printf("OWNER_PUMP_GUARD sentinel mode=%u status=%u kind=%u duplicate_kind=%u full_wall_ns=%llu\n",
                mode, (unsigned)status, event.kind, duplicate.kind,
                (unsigned long long)(finished >= started ? finished - started : 0));
            if (mode == CJGUI_OWNER_PUMP_TEST_BEFORE_GUARD) {
                [self startGuardBarrierCase:CJGUI_OWNER_PUMP_TEST_AFTER_GUARD_READ];
            } else {
                [self startReadyNoneEnqueueWakeCase];
            }
        });
    });
}

- (void)finish {
    if (self.replacementSession != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN &&
        CjguiLookupSession(self.replacementSession)) {
        (void)cjgui_internal_renderer_destroy(self.replacementSession);
    }
    if (self.failed) {
        cjgui_internal_renderer_request_application_stop();
        return;
    }
    printf("OWNER_PUMP_TICKET PASS main_delay_us=%llu ordered_fifo=1 duplicate_poll=1 retired_ticket=1 slot_reuse=1 replacement_fifo_preserved=1 coordinate_epoch=1 source=private_native_fifo_probe\n",
        (unsigned long long)self.firstCallElapsedMicros);
    cjgui_internal_renderer_request_application_stop();
}

@end

int main(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        CjguiInternalRendererConfig config = { .windowWidth = 360, .windowHeight = 240 };
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK ||
            session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            fprintf(stderr, "OWNER_PUMP_TICKET FAIL: setup session create status=%u\n", (unsigned)status);
            return 1;
        }
        CjguiOwnerPumpAsyncTicketProbe *probe = [CjguiOwnerPumpAsyncTicketProbe new];
        probe.session = session;
        probe.replacementSession = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
        probe.workerQueue = dispatch_queue_create("cjgui.owner-pump-ticket.worker", DISPATCH_QUEUE_SERIAL);
        probe.receivedKinds = [NSMutableArray array];
        cjgui_internal_renderer_enable_main_thread_dispatch();
        if (!atomic_load_explicit(&gCjguiLauncherOwnsEventLoop, memory_order_acquire) ||
            !atomic_load_explicit(&gCjguiMainThreadDispatchEnabled, memory_order_acquire)) {
            (void)cjgui_internal_renderer_destroy(session);
            fprintf(stderr, "OWNER_PUMP_TICKET FAIL: main-thread dispatch not enabled\n");
            return 1;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC),
                       dispatch_get_main_queue(), ^{ [probe startQueueDelayCase]; });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)kWatchdogMicros * NSEC_PER_USEC),
                       dispatch_get_main_queue(), ^{
            probe.watchdogFired = YES;
            probe.failed = YES;
            fprintf(stderr, "OWNER_PUMP_TICKET FAIL: bounded run-loop watchdog fired\n");
            cjgui_internal_renderer_request_application_stop();
        });
        [app run];
        if (CjguiLookupSession(session)) (void)cjgui_internal_renderer_destroy(session);
        return probe.failed || probe.watchdogFired ? 1 : 0;
    }
}
