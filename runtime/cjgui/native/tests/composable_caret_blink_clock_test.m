// Deterministic phase/lifecycle test for the production accepted-caret paint
// path. The overlay target is overridden so no desktop window is activated.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

@interface CjguiCaretBlinkTestOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) CJGuiInternalComposableSceneNode *testTarget;
@property(nonatomic, assign) BOOL testFocused;
@property(nonatomic, assign) int presents;
@end

@implementation CjguiCaretBlinkTestOverlay
- (CJGuiInternalComposableSceneNode *)caretBlinkTarget {
    return self.testFocused ? self.testTarget : nil;
}
- (void)scheduleAcceptedScenePresent {
    self.presents += 1;
}
@end

static int fail(const char *message) {
    fprintf(stderr, "caret blink: %s\n", message);
    return 1;
}

int main(void) {
    @autoreleasepool {
        int regressionFailures = 0;
        setenv("CJGUI_TEST_CARET_BLINK_HALF_PERIOD_MS", "10", 1);
        CJGuiInternalSession *bindingSession = [CJGuiInternalSession new];
        bindingSession.ownedTextSessionBindingEpoch = 1;
        CjguiCaretBlinkTestOverlay *overlay =
            [[CjguiCaretBlinkTestOverlay alloc] initWithFrame:NSZeroRect session:bindingSession];
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        node.textCaretRect = NSMakeRect(10, 20, 1.5, 18);
        overlay.nodes = @[node];
        overlay.testTarget = node;
        overlay.testFocused = YES;
        overlay.testCaretBlinkClockActive = YES;
        overlay.testCaretBlinkNowMicros = 1000000;
        uint64_t bodyGeneration = overlay.activeTextBodyGeneration;

        [overlay resetCaretBlink];
        if (!overlay.caretBlinkVisible || node.textCaretHidden ||
            overlay.caretBlinkDeadlineMicros != 1010000) return fail("initial visible/deadline");
        uint64_t visiblePaintHash = CjguiEffectHashPaintNode(1469598103934665603ULL,
            node, node.node);
        [overlay advanceCaretBlinkAtMicros:1009999];
        if (node.textCaretHidden || overlay.presents != 0) return fail("early tick changed paint");
        [overlay scheduleCaretBlink];  // unchanged declaration/geometry cannot reset the clock
        if (overlay.caretBlinkDeadlineMicros != 1010000) return fail("same target reset deadline");
        [overlay advanceCaretBlinkAtMicros:1010000];
        if (!node.textCaretHidden || overlay.presents != 1 ||
            NSIsEmptyRect(node.textCaretRect)) return fail("visible to hidden lost geometry");
        if (CjguiEffectHashPaintNode(1469598103934665603ULL, node, node.node) == visiblePaintHash)
            return fail("hidden phase reused visible effect cache");
        [overlay advanceCaretBlinkAtMicros:1020000];
        if (node.textCaretHidden || overlay.presents != 2) return fail("hidden to visible");
        if (CjguiEffectHashPaintNode(1469598103934665603ULL, node, node.node) != visiblePaintHash)
            return fail("visible phase paint hash not restored");

        overlay.testCaretBlinkNowMicros = 1030000;
        [overlay advanceCaretBlinkAtMicros:1030000];
        overlay.testCaretBlinkNowMicros = 1035000;
        [overlay resetCaretBlink]; // actual input or selection move
        if (node.textCaretHidden || overlay.caretBlinkDeadlineMicros != 1045000)
            return fail("input did not reset to visible");
        // A presentation surface can take ownership after a source timer was
        // queued. The old callback must be invalidated and a fresh phase
        // scheduled for the new binding, even while `scheduled` is still true.
        uint64_t beforeRebind = overlay.caretBlinkGeneration;
        overlay.caretBlinkScheduled = YES;
        bindingSession.ownedTextSessionBindingEpoch = 2;
        [overlay scheduleCaretBlink];
        if (overlay.caretBlinkGeneration == beforeRebind || overlay.caretBlinkBindingEpoch != 2 ||
            overlay.caretBlinkScheduled || node.textCaretHidden ||
            overlay.caretBlinkDeadlineMicros != 1045000)
            return fail("binding change stranded queued blink timer");
        // Exercise the public native ownership setter too: presentation
        // adoption need not be followed by another caret declaration.
        bindingSession.composableSceneOverlay = overlay;
        uint64_t bindingToken = CjguiAllocateSession(bindingSession);
        if (bindingToken == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN)
            return fail("could not register binding test session");
        uint64_t beforeSetter = overlay.caretBlinkGeneration;
        overlay.caretBlinkScheduled = YES;
        CjguiInternalRendererStatus bindingStatus =
            cjgui_internal_renderer_set_composable_owned_text_session(
                bindingToken, 42, -1, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, 3, 1);
        if (bindingStatus != CJGUI_INTERNAL_RENDERER_OK ||
            overlay.caretBlinkGeneration == beforeSetter || overlay.caretBlinkBindingEpoch != 3 ||
            overlay.caretBlinkScheduled || node.textCaretHidden)
            return fail("native rebind did not retire old caret timer");
        uint64_t retired = overlay.caretBlinkGeneration;
        overlay.testFocused = NO;
        [overlay stopCaretBlink];
        if (!node.textCaretHidden || overlay.caretBlinkScheduled ||
            overlay.caretBlinkGeneration == retired) return fail("defocus did not stop");
        [overlay advanceCaretBlinkAtMicros:2000000];
        if (!node.textCaretHidden || overlay.activeTextBodyGeneration != bodyGeneration)
            return fail("stopped tick changed paint or text raster generation");

        // A no-visual-caret declaration is common in source mode. It must
        // withdraw an owner-declared bar without cancelling a still-eligible
        // native TextInput caret clock.
        CjguiInternalRendererComposableNode sourceData = {0};
        sourceData.nodeId = 32;
        sourceData.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        sourceData.isInteractive = 1;
        sourceData.width = 300;
        sourceData.height = 48;
        sourceData.clipWidth = 600;
        sourceData.clipHeight = 400;
        CJGuiInternalComposableSceneNode *sourceNode = [CJGuiInternalComposableSceneNode new];
        sourceNode.node = sourceData;
        sourceNode.textCaretRect = NSMakeRect(24, 12, 1.5, 18);
        sourceNode.textCaretHidden = NO;
        CjguiCaretBlinkTestOverlay *sourceOverlay =
            [[CjguiCaretBlinkTestOverlay alloc] initWithFrame:NSZeroRect session:nil];
        sourceOverlay.nodes = @[sourceNode];
        sourceOverlay.testTarget = sourceNode;
        sourceOverlay.testFocused = YES;
        sourceOverlay.testCaretBlinkClockActive = YES;
        sourceOverlay.testCaretBlinkNowMicros = 3000000;
        [sourceOverlay resetCaretBlink];
        uint64_t sourceGeneration = sourceOverlay.caretBlinkGeneration;
        uint64_t sourceDeadline = sourceOverlay.caretBlinkDeadlineMicros;
        CjguiInternalRendererStatus absentStatus = CjguiDeclareInputCaretOnOverlay(sourceOverlay, -1, 0, 0, 0, 0);
        if (absentStatus != CJGUI_INTERNAL_RENDERER_OK || sourceOverlay.caretBlinkVisible != YES ||
            sourceNode.textCaretHidden ||
            sourceOverlay.caretBlinkGeneration != sourceGeneration ||
            sourceOverlay.caretBlinkDeadlineMicros != sourceDeadline ||
            NSIsEmptyRect(sourceNode.textCaretRect)) {
            fprintf(stderr, "caret blink: withdrawing absent visual caret stopped active source blink\n");
            regressionFailures++;
        }
        [sourceOverlay advanceCaretBlinkAtMicros:sourceDeadline];
        if (!sourceNode.textCaretHidden || NSIsEmptyRect(sourceNode.textCaretRect) ||
            sourceOverlay.presents != 1 || sourceOverlay.activeTextBodyGeneration != 0) {
            fprintf(stderr, "caret blink: source blink phase did not preserve geometry and paint-only work\n");
            regressionFailures++;
        }

        // Simulate a presentation TEXT caret declared after the accepted scene
        // has already been published. Installation must mutate that accepted
        // node and schedule one paint-only present without changing its scene
        // owner version or text-body generation.
        CjguiInternalRendererComposableNode visualData = {0};
        visualData.nodeId = 41;
        visualData.projectionVersion = 7;
        visualData.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        visualData.isInteractive = 1;
        visualData.width = 300;
        visualData.height = 48;
        visualData.x = 210;
        visualData.y = 85;
        visualData.clipWidth = 600;
        visualData.clipHeight = 400;
        CJGuiInternalComposableSceneNode *visualNode = [CJGuiInternalComposableSceneNode new];
        visualNode.node = visualData;
        visualNode.index = 3;
        CjguiCaretBlinkTestOverlay *visualOverlay =
            [[CjguiCaretBlinkTestOverlay alloc] initWithFrame:NSZeroRect session:nil];
        visualOverlay.nodes = @[visualNode];
        visualOverlay.testTarget = visualNode;
        visualOverlay.testFocused = YES;
        visualOverlay.testCaretBlinkClockActive = YES;
        visualOverlay.testCaretBlinkNowMicros = 4000000;
        uint64_t acceptedVersion = visualNode.node.projectionVersion;
        uint64_t visualBodyGeneration = visualOverlay.activeTextBodyGeneration;
        CjguiInternalRendererStatus declarationStatus =
            CjguiDeclareInputCaretOnOverlay(visualOverlay, 41, 42.7, 2, 1, 21);
        NSRect installedCaret = visualNode.textCaretRect;
        if (declarationStatus != CJGUI_INTERNAL_RENDERER_OK ||
            !visualOverlay.hasDeclaredInputCaret || !visualNode.textCaretIsDeclared ||
            fabs(NSMinX(installedCaret) - 252.7) > 0.01 ||
            fabs(NSMinY(installedCaret) - 87.0) > 0.01 ||
            fabs(NSWidth(installedCaret) - 1.5) > 0.01 ||
            fabs(NSHeight(installedCaret) - 21.0) > 0.01 ||
            visualOverlay.presents != 1 || visualNode.node.projectionVersion != acceptedVersion ||
            visualOverlay.activeTextBodyGeneration != visualBodyGeneration) {
            fprintf(stderr, "caret blink: late accepted-node caret declaration did not install and schedule paint-only present "
                    "rect=%.2f,%.2f,%.2f,%.2f declared=%d presents=%d accepted=%llu body=%llu\n",
                    NSMinX(installedCaret), NSMinY(installedCaret), NSWidth(installedCaret), NSHeight(installedCaret),
                    visualNode.textCaretIsDeclared, visualOverlay.presents,
                    (unsigned long long)visualNode.node.projectionVersion,
                    (unsigned long long)visualOverlay.activeTextBodyGeneration);
            regressionFailures++;
        }
        unsetenv("CJGUI_TEST_CARET_BLINK_HALF_PERIOD_MS");
        if (regressionFailures != 0) return 1;
    }
    return 0;
}
