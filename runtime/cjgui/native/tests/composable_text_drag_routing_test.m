// Native routing probe: which owner takes a press on a TEXT-content node.
// GPUI dispatches mouse events along the hit path and the editor element handles
// its own drag, so a text node must have exactly ONE owner. Today the native side
// captures the gesture by KIND while the framework only delivers pointer phases
// to a node the product declared pointer-interactive; a TEXT node that did NOT
// opt in is therefore owned by nobody (measured on the product: caret appears,
// drag selects nothing). This probe pins the decision table so a fix flips it.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>

#include <stdio.h>

static int failures = 0;
#define CHECK(cond, name) do { \
    printf("case=%s result=%s\n", name, (cond) ? "PASS" : "FAIL"); \
    if (!(cond)) failures++; } while (0)

static void BuildTextNode(CjguiInternalRendererComposableNode *raw, uint64_t nodeId, BOOL interactive) {
    memset(raw, 0, sizeof(*raw));
    raw->nodeId = nodeId;
    raw->projectionVersion = 1;
    raw->resourceId = 7001;
    raw->x = 10; raw->y = 10; raw->width = 120; raw->height = 40;
    raw->clipX = 0; raw->clipY = 0; raw->clipWidth = 200; raw->clipHeight = 120;
    raw->nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw->isInteractive = interactive ? 1 : 0;
    raw->isReadOnly = 0;
    raw->fillAlpha = 1.0; raw->textAlpha = 1.0;
}

int main(void) {
    @autoreleasepool {
        (void)[NSApplication sharedApplication];
        CJGuiInternalSession *session = [[CJGuiInternalSession alloc] init];
        CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 200, 120)];
        if (!session || !overlay) { printf("init failed\n"); return 2; }
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw = {0};
        BuildTextNode(&raw, 1000, NO);
        node.node = raw; node.index = 0;
        session.composableSceneVersion = 1;
        session.app = NSApp;
        session.rendererSessionToken = 1;
        session.sessionGeneration = 1;
        gCjguiSessions[0] = session;
        gCjguiSessionOccupied[0] = YES;
        session.composableNodes = [NSMutableArray arrayWithObject:node];
        session.pendingInteractions = [NSMutableArray array];
        overlay.session = session;
        overlay.nodes = @[node];

        // Case 1: a TEXT node the product did NOT make pointer-interactive.
        // The framework must own its drag (text selection), because nothing else
        // can: the framework will not deliver pointer phases without the opt-in.
        [overlay mouseDownForNode:node atPoint:NSMakePoint(12, 12)];
        CHECK(overlay.draggingNodeId != 0 && !overlay.pointerCaptureActive,
              "unopted_text_press_is_owned_by_the_framework_text_drag");
        [overlay clearDraggingSelection];

        // Case 2: a pointer-interactive TEXT node keeps native pointer capture;
        // Pharos visual mode drives its own selection from those phases.
        BuildTextNode(&raw, 1000, YES);
        node.node = raw;
        [overlay mouseDownForNode:node atPoint:NSMakePoint(12, 12)];
        CHECK(overlay.pointerCaptureActive && overlay.draggingNodeId == 0,
              "pointer_interactive_text_press_keeps_native_pointer_capture");
        [overlay cancelPointerCapture];

        // Case 3: the framework drag must actually continue. A press that is
        // merely routed is not enough: the drag has to be admitted and produce a
        // selection, which is what "caret but no selection" failed to do.
        BuildTextNode(&raw, 1000, NO);
        node.node = raw;
        node.value = @"alpha\nbravo\ncharlie\ndelta\n";
        [overlay mouseDownForNode:node atPoint:NSMakePoint(12, 12)];
        BOOL routed = overlay.draggingNodeId != 0;
        NSEvent *drag = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDragged
            location:NSMakePoint(100, 12) modifierFlags:0 timestamp:0.01 windowNumber:0
            context:nil eventNumber:1 clickCount:1 pressure:1.0];
        BOOL continued = NO;
        if (routed && drag) {
            [overlay mouseDragged:drag];
            continued = overlay.draggingNodeId != 0;
        }
        NSRange sel = overlay.inputProxy ? overlay.inputProxy.selectedRange : NSMakeRange(0, 0);
        printf("case=framework_drag_continues routed=%d continued=%d sel_len=%lu\n",
               (int)routed, (int)continued, (unsigned long)sel.length);
        CHECK(routed && continued, "unopted_text_drag_continues_after_the_press");
        [overlay clearDraggingSelection];

        printf("text_drag_routing failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}
