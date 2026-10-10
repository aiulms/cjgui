#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

// Never shown. Exercises the SDK's setters on the actual accepted AX element,
// rather than calling CJGUI's similarly named private helpers directly.
@interface AxProtocolWindow : NSWindow
@property(nonatomic, strong) NSResponder *recordedResponder;
@end
@implementation AxProtocolWindow
- (NSResponder *)firstResponder { return self.recordedResponder; }
- (BOOL)makeFirstResponder:(NSResponder *)responder { self.recordedResponder = responder; return YES; }
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (CGFloat)backingScaleFactor { return 1; }
@end
@interface AxProtocolOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) AxProtocolWindow *recordedWindow;
@end
@implementation AxProtocolOverlay
- (NSWindow *)window { return self.recordedWindow; }
@end

static int failures;
#define CHECK(condition,label) do { BOOL ok = (condition); fprintf(stderr,"ax_protocol_setter case=%s result=%s\n",label,ok?"PASS":"FAIL"); if(!ok) failures++; } while(0)

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,240,60)
        device:device commandQueue:[device newCommandQueue]];
    AxProtocolOverlay *overlay = [[AxProtocolOverlay alloc] initWithFrame:NSMakeRect(0,0,240,60) session:ctx];
    overlay.recordedWindow = [[AxProtocolWindow alloc] initWithContentRect:NSMakeRect(0,0,240,60)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    overlay.recordedWindow.releasedWhenClosed = NO;
    overlay.recordedWindow.contentView = overlay;
    ctx.window = overlay.recordedWindow; ctx.composableSceneOverlay = overlay;
    ctx.composableSceneVersion = 1;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    raw.width=240; raw.height=40; raw.clipWidth=240; raw.clipHeight=40;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0; node.semanticId=@"ordinary-input";
    node.value=@"A🙂B"; node.textTextureCacheKey=@"";
    overlay.nodes=@[node]; ctx.composableNodes=[NSMutableArray arrayWithObject:node];
    [overlay reconcileAccessibilityActions];
    CJGuiInternalComposableAccessibilityAction *action = overlay.accessibilityActions.firstObject;
    NSUInteger before = ctx.pendingInteractions.count;
    [(id<NSAccessibility>)action setAccessibilityValue:@"A🙂BC"];
    CHECK([overlay.inputProxy.string isEqualToString:@"A🙂BC"] &&
          ctx.pendingInteractions.count == before+1 &&
          ((CJGuiInternalQueuedInteraction *)ctx.pendingInteractions.lastObject).kind ==
              CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED,
          "SDK_value_setter_reaches_real_FIFO_once");
    [ctx.pendingInteractions removeAllObjects];
    [(id<NSAccessibility>)action setAccessibilitySelectedTextRange:NSMakeRange(1,2)];
    CHECK(NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(1,2)) &&
          ctx.pendingInteractions.count == 1 &&
          ((CJGuiInternalQueuedInteraction *)ctx.pendingInteractions.lastObject).kind ==
              CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
          "SDK_range_setter_reaches_real_selection");
    [ctx.pendingInteractions removeAllObjects];
    [(id<NSAccessibility>)action setAccessibilityFocused:YES];
    CHECK([(id<NSAccessibility>)action isAccessibilityFocused] &&
          ctx.pendingInteractions.count == 1 &&
          ((CJGuiInternalQueuedInteraction *)ctx.pendingInteractions.lastObject).kind ==
              CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS,
          "SDK_focus_setter_and_getter_match_installed_focus");
    [ctx.pendingInteractions removeAllObjects];
    ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    [(id<NSAccessibility>)action setAccessibilityValue:@"A🙂BCX"];
    NSUInteger edits=0;
    for(CJGuiInternalQueuedInteraction *event in ctx.pendingInteractions) {
        if(event.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED) {
            edits++;
            CHECK(event.selectionStart==5 && event.selectionEnd==5 && [event.formText isEqualToString:@"X"],
                "SDK_bounded_value_has_exact_local_delta");
        }
    }
    CHECK(edits==1 && [overlay.inputProxy.string isEqualToString:@"A🙂BCX"],
          "SDK_bounded_value_reaches_owned_range_seam_once");
    [ctx.pendingInteractions removeAllObjects];
    overlay.nodes=@[];
    NSString *kept = [overlay.inputProxy.string copy]; NSRange keptRange=overlay.inputProxy.selectedRange;
    [(id<NSAccessibility>)action setAccessibilityValue:@"stale"];
    [(id<NSAccessibility>)action setAccessibilitySelectedTextRange:NSMakeRange(0,0)];
    [(id<NSAccessibility>)action setAccessibilityFocused:YES];
    CHECK(ctx.pendingInteractions.count == 0 && [overlay.inputProxy.string isEqualToString:kept] &&
          NSEqualRanges(overlay.inputProxy.selectedRange,keptRange) &&
          ![(id<NSAccessibility>)action isAccessibilityFocused],"retired_AX_cannot_modify_or_focus");
    [overlay.recordedWindow close];
    return failures ? 1 : 0;
} }
