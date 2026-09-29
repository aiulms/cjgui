// Native event-path probe: one accepted PNG source press followed by multiple
// drag callbacks must never begin more than one AppKit dragging session.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>

#include <stdio.h>

@interface CjguiCountingDragOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, assign) NSUInteger beginCount;
@property(nonatomic, assign) NSEventType beginEventType;
@property(nonatomic, strong) NSEvent *reentrantDragEvent;
@end

@implementation CjguiCountingDragOverlay
- (NSDraggingSession *)beginDraggingSessionWithItems:(NSArray<NSDraggingItem *> *)items
                                               event:(NSEvent *)event
                                              source:(id<NSDraggingSource>)source {
    (void)items;
    self.beginEventType = event.type;
    (void)source;
    self.beginCount += 1;
    // AppKit may synchronously re-enter a responder while it hands off the
    // native drag. Exercise that boundary without creating a system drag or
    // moving the user's pointer.
    if (self.reentrantDragEvent) {
        NSEvent *nested = self.reentrantDragEvent;
        self.reentrantDragEvent = nil;
        [self mouseDragged:nested];
    }
    return (NSDraggingSession *)self; // non-nil test double; never dereferenced
}
@end

static int fail(const char *message, int code) {
    fprintf(stderr, "png drag single-session test: FAIL %s\n", message);
    return code;
}

int main(void) {
    @autoreleasepool {
        (void)[NSApplication sharedApplication];
        CJGuiInternalSession *session = [[CJGuiInternalSession alloc] init];
        CjguiCountingDragOverlay *overlay = [[CjguiCountingDragOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 160, 100)];
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CJGuiInternalComposableDataTransferItem *transfer = [CJGuiInternalComposableDataTransferItem new];
        if (!session || !overlay || !node || !transfer) return fail("test object initialization failed", 2);

        CjguiInternalRendererComposableNode rawNode = {0};
        rawNode.nodeId = 51;
        rawNode.projectionVersion = 1;
        rawNode.resourceId = 7001;
        rawNode.x = 10; rawNode.y = 10; rawNode.width = 80; rawNode.height = 40;
        rawNode.clipX = 0; rawNode.clipY = 0; rawNode.clipWidth = 160; rawNode.clipHeight = 100;
        rawNode.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
        rawNode.isInteractive = 1;
        rawNode.fillAlpha = 1.0; rawNode.textAlpha = 1.0;
        node.node = rawNode;
        node.index = 0;

        session.composableSceneVersion = 1;
        session.composableDataTransferVersion = 1;
        session.app = NSApp;
        session.rendererSessionToken = 1;
        session.sessionGeneration = 1;
        gCjguiSessions[0] = session;
        gCjguiSessionOccupied[0] = YES;
        session.composableNodes = [NSMutableArray arrayWithObject:node];
        session.pendingInteractions = [NSMutableArray array];
        session.composableDataTransferItems = [NSMutableArray arrayWithObject:transfer];
        CjguiInternalRendererComposableDataTransferItem rawTransfer = {0};
        rawTransfer.nodeId = rawNode.nodeId;
        rawTransfer.projectionVersion = rawNode.projectionVersion;
        rawTransfer.resourceId = rawNode.resourceId;
        rawTransfer.nodeKind = rawNode.nodeKind;
        rawTransfer.role = CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_SOURCE;
        rawTransfer.maximumPayloadBytes = 128;
        rawTransfer.sourceId = 9;
        rawTransfer.bindingEpoch = 1;
        transfer.item = rawTransfer;
        transfer.format = @"image/png";
        const uint8_t payload[] = { 137, 80, 78, 71, 13, 10, 26, 10, 0 };
        transfer.binaryPayload = [NSData dataWithBytes:payload length:sizeof(payload)];

        overlay.session = session;
        overlay.nodes = @[node];
        overlay.reentrantDragEvent = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDragged
            location:NSMakePoint(20, 20) modifierFlags:0 timestamp:0.02 windowNumber:0
            context:nil eventNumber:1 clickCount:1 pressure:1.0];
        // The detached view has no window transform, so the harness calls
        // the production press router below and supplies the initiating
        // mouse-down that its normal NSView mouseDown: entry would retain.
        NSEvent *drag = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDragged
            location:NSMakePoint(20, 20) modifierFlags:0 timestamp:0.01 windowNumber:0
            context:nil eventNumber:1 clickCount:1 pressure:1.0];
        if (!drag || !overlay.reentrantDragEvent) return fail("could not construct deterministic NSEvents", 3);

        if (![overlay nodeAtPoint:NSMakePoint(12, 12)]) {
            return fail("test source node did not pass production hit testing", 6);
        }
        // Use the production down router directly because this detached view
        // has no window coordinate transform. It is the same production
        // method called after `mouseDown:` resolves its hit-tested node.
        [overlay mouseDownForNode:node atPoint:NSMakePoint(12, 12)];
        if (overlay.pressedNodeId != rawNode.nodeId) return fail("single mouseDown did not capture PNG source", 4);
        overlay.dataTransferSourceMouseDownEvent = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
            location:NSMakePoint(12, 12) modifierFlags:0 timestamp:0.0 windowNumber:0
            context:nil eventNumber:1 clickCount:1 pressure:1.0];
        [overlay mouseDragged:drag];
        // The first event starts a drag. Re-send callbacks (including one
        // synchronous re-entrant callback at AppKit handoff) for the same
        // press; the expected invariant is exactly one source session.
        [overlay mouseDragged:drag];
        [overlay mouseDragged:drag];
        fprintf(stdout, "png_drag press_events=1 drag_callbacks=4 appkit_begin_calls=%lu\n",
                (unsigned long)overlay.beginCount);
        if (overlay.beginCount != 1) return fail("one press began multiple AppKit dragging sessions", 5);
        if (overlay.beginEventType != NSEventTypeLeftMouseDown)
            return fail("AppKit drag did not receive the initiating mouse-down", 10);

        // A running AppKit drag owns its mouse-up. The CJGUI owner pump may
        // still drain already-queued business events, but must not take the
        // next AppKit event from the same process while tracking is active.
        [session.pendingInteractions removeAllObjects];
        NSEvent *up = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
            location:NSMakePoint(20, 20) modifierFlags:0 timestamp:0.03 windowNumber:0
            context:nil eventNumber:2 clickCount:1 pressure:0.0];
        if (!up) return fail("could not construct mouse-up counterexample", 7);
        [NSApp postEvent:up atStart:YES];
        NSEvent *posted = [NSApp nextEventMatchingMask:NSEventMaskLeftMouseUp
            untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO];
        if (!posted || !overlay.dataTransferDragSessionActive ||
            gCjguiActiveDataTransferDragSessions != 1)
            return fail("mouse-up was not posted under one active drag", 11);
        CjguiInternalRendererEvent ownerEvent = {0};
        if (cjgui_internal_renderer_pump_event(1, 0, &ownerEvent) != CJGUI_INTERNAL_RENDERER_OK)
            return fail("owner pump failed during active drag", 8);
        NSEvent *remaining = [NSApp nextEventMatchingMask:NSEventMaskLeftMouseUp
            untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
        if (!remaining || remaining.type != NSEventTypeLeftMouseUp ||
            remaining.eventNumber != up.eventNumber) return fail("owner pump stole AppKit drag mouse-up", 9);
        fprintf(stdout, "png_drag active_session_mouse_up=reserved_for_appkit\n");

        [overlay draggingSession:(NSDraggingSession *)overlay endedAtPoint:NSZeroPoint
                      operation:NSDragOperationNone];
        if (overlay.dataTransferDragSessionActive || gCjguiActiveDataTransferDragSessions != 0)
            return fail("cancelled drag did not release event ownership", 12);
        NSEvent *afterEnd = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
            location:NSMakePoint(20, 20) modifierFlags:0 timestamp:0.04 windowNumber:0
            context:nil eventNumber:3 clickCount:1 pressure:0.0];
        [NSApp postEvent:afterEnd atStart:YES];
        if (cjgui_internal_renderer_pump_event(1, 0, &ownerEvent) != CJGUI_INTERNAL_RENDERER_OK)
            return fail("owner pump failed after drag cancellation", 13);
        NSEvent *unclaimed = [NSApp nextEventMatchingMask:NSEventMaskLeftMouseUp
            untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
        if (unclaimed) return fail("owner pump stayed suspended after drag cancellation", 14);
        fprintf(stdout, "png_drag ended_event_ownership=released\n");
    }
    return 0;
}
