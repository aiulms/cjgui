// runtime/cjgui/native/cjgui_internal_renderer.m
//
// Runtime-owned internal renderer sidecar. This is the SINGLE real
// Objective-C / Metal renderer implementation for the project. The macOS
// smoke (labs/macos_bridge_smoke) is migrated to consume this via a thin
// cjgui_app_run() shim; it no longer carries a second renderer copy.
//
// INTERNAL / UNSTABLE. Not a public C ABI.

#import "cjgui_internal_renderer.h"

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <mach/mach_time.h>
#import <mach/mach.h>
#import <objc/runtime.h>
#import <simd/simd.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <math.h>
#include <sys/resource.h>

// ---- helpers reused by both runtime probe and smoke shim ----

// The application-level scheduler supports one, two and four windows in the
// same process. This remains a fixed native capacity so create failure is
// deterministic and no AppKit/Metal session table can grow without bound.
static const NSUInteger kCjguiSessionCapacity = 4;
static const NSTimeInterval kCjguiPumpTimeoutMaxSeconds = 0.016; // 16 ms bound

#ifdef CJGUI_INTERNAL_TESTING
static uint64_t CjguiMonotonicMicros(void) {
    static mach_timebase_info_data_t timebase;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ mach_timebase_info(&timebase); });
    uint64_t ticks = mach_continuous_time();
    return (ticks / 1000) * timebase.numer / MAX((uint32_t)1, timebase.denom);
}

static uint64_t CjguiSaturatingAddU64(uint64_t value, uint64_t delta) {
    return delta > UINT64_MAX - value ? UINT64_MAX : value + delta;
}
#endif

@class CJGuiInternalComposableSceneNode;

enum { CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY = 4 };
// Apple documents a 4 KiB upper bound for setVertexBytes. This renderer uses
// it only for short-lived shape data, so split consecutive shape commands at
// that byte boundary rather than retaining a Metal buffer across frames. A
// rectangle contributes six vertices and must remain whole to preserve its
// triangles and painter ordering.
enum {
    CJGUI_INTERNAL_METAL_SET_VERTEX_BYTES_CAPACITY = 4 * 1024,
    CJGUI_INTERNAL_COMPOSABLE_SHAPE_VERTICES_PER_NODE = 6,
};

#ifdef CJGUI_INTERNAL_TESTING
// Bounded attribution for real text bitmap/texture work. Unknown is retained
// as an honest bucket whenever a refresh cannot prove its triggering change.
typedef enum CjguiInternalTextWorkReason {
    CjguiInternalTextWorkReasonUnknown = 0,
    CjguiInternalTextWorkReasonStaticCandidate = 1,
    CjguiInternalTextWorkReasonActiveContent = 2,
    CjguiInternalTextWorkReasonSelectionCaret = 3,
    CjguiInternalTextWorkReasonVisibleTileScroll = 4,
    CjguiInternalTextWorkReasonRetry = 5,
    CjguiInternalTextWorkReasonCount = 6,
} CjguiInternalTextWorkReason;
typedef struct CjguiInternalTextWorkReasonCounters {
    uint64_t raster[CjguiInternalTextWorkReasonCount];
    uint64_t upload[CjguiInternalTextWorkReasonCount];
} CjguiInternalTextWorkReasonCounters;
#endif

typedef struct CJGuiInternalMetalVertex {
    vector_float2 position;
    vector_float2 scenePoint;
    vector_float2 localPoint;
    vector_float2 size;
    vector_float4 clips[CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY];
    vector_float4 clipRadii;
    // Keep the count vector-aligned so the C and Metal layouts stay identical.
    vector_float4 clipCount;
    float cornerRadius;
    float borderWidth;
    vector_float4 fill;
    vector_float4 border;
} CJGuiInternalMetalVertex;

typedef struct CJGuiInternalMetalTextureVertex {
    vector_float2 position;
    vector_float2 texCoord;
    vector_float2 scenePoint;
    vector_float4 clips[CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY];
    vector_float4 clipRadii;
    vector_float4 clipCount;
    vector_float4 nodeRect;
    float nodeCornerRadius;
} CJGuiInternalMetalTextureVertex;

static BOOL CjguiEncodeComposableNodes(id view, id<MTLRenderCommandEncoder> encoder, CGSize drawableSize);
static uint32_t CjguiComposableClipConstraintCount(CjguiInternalRendererComposableNode value);
static void CjguiComposableClipConstraintAt(CjguiInternalRendererComposableNode value, uint32_t index,
                                             CGFloat *x, CGFloat *y, CGFloat *width, CGFloat *height, CGFloat *radius);

static uint8_t CjguiColorChannelToByte(double value) {
    if (value <= 0.0) return 0;
    if (value >= 1.0) return 255;
    return (uint8_t)(value * 255.0 + 0.5);
}

static BOOL CjguiColorByteMatches(uint8_t actual, uint8_t expected) {
    const int tolerance = 3;
    int delta = (int)actual - (int)expected;
    if (delta < 0) delta = -delta;
    return delta <= tolerance;
}

// ---- Metal view ----

@interface CJGuiInternalMetalView : NSView
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) CAMetalLayer *metalLayer;
@property(nonatomic, assign) BOOL invalidated;
@property(nonatomic, assign) BOOL readbackProbeCompleted;
@property(nonatomic, assign) uint64_t frameIndex;
@property(nonatomic, strong) id<MTLRenderPipelineState> composablePipeline;
@property(nonatomic, strong) id<MTLRenderPipelineState> composableImagePipeline;
@property(nonatomic, strong) NSArray<CJGuiInternalComposableSceneNode *> *composableNodes;
#ifdef CJGUI_INTERNAL_TESTING
// A probe may select a controlled backing scale only to exercise the normal
// backing-properties notification route on a single-display machine. The
// production scale always comes from the attached NSWindow/NSScreen.
@property(nonatomic, assign) CGFloat testBackingScaleOverride;
// Scalar encoder work facts for the focused renderer probe.  They expose no
// Metal object and deliberately distinguish shape-node count from contiguous
// batch submissions and texture boundaries.
// 0 = capacity-bounded consecutive rectangles (production path), 1 = one
// complete rectangle per legal setVertexBytes submission (comparison path).
@property(nonatomic, assign) uint8_t testComposableShapeSubmissionMode;
@property(nonatomic, assign) uint32_t testComposableShapeNodeCount;
@property(nonatomic, assign) uint32_t testComposableShapeBatchCount;
@property(nonatomic, assign) uint32_t testComposableTextureDrawCount;
@property(nonatomic, assign) uint64_t testComposableShapeVertexBytes;
@property(nonatomic, assign) uint64_t testComposableMaxShapeBatchVertexBytes;
@property(nonatomic, assign) uint32_t testComposableShapeVertexStride;
// Wall time inside CjguiEncodeComposableNodes for this submitted frame. It is
// CPU encoder work only: it excludes command-buffer completion and display.
@property(nonatomic, assign) uint64_t testComposableEncoderCpuMicros;
// Text preparation is deliberately reported apart from command encoding:
// an AppKit bitmap raster and `replaceRegion` are real work with different
// owners and neither implies a completed/presented Metal frame.
@property(nonatomic, assign) uint64_t testComposableTextRasterCount;
@property(nonatomic, assign) uint64_t testComposableTextRasterBytes;
@property(nonatomic, assign) uint64_t testComposableTextRasterMicros;
@property(nonatomic, assign) uint64_t testComposableTextUploadCount;
@property(nonatomic, assign) uint64_t testComposableTextUploadBytes;
@property(nonatomic, assign) uint64_t testComposableTextUploadMicros;
@property(nonatomic, assign) CjguiInternalTextWorkReasonCounters testComposableTextWorkReasonCounters;
@property(nonatomic, assign) uint64_t testComposableTextLastProjectionVersion;
@property(nonatomic, assign) uint64_t testComposableTextLastContentUtf8Bytes;
#endif
- (instancetype)initWithFrame:(NSRect)frame
                       device:(id<MTLDevice>)device
                 commandQueue:(id<MTLCommandQueue>)commandQueue;
- (void)updateDrawableSize;
- (void)invalidateBridgeResources;
- (BOOL)encodeComposableNodes:(id<MTLRenderCommandEncoder>)encoder drawableSize:(CGSize)drawableSize;
@end

#ifdef CJGUI_INTERNAL_TESTING
// Detailed glyph dumps are useful only when diagnosing text geometry. Keep
// default probe stderr scalar-friendly so concurrent runner output cannot
// corrupt performance samples. The opt-in is process-scoped and test-only.
static BOOL CjguiTestVerboseGlyphDiagnosticsEnabled(void) {
    return [NSProcessInfo.processInfo.environment[@"CJGUI_INTERNAL_VERBOSE_GLYPH_DIAGNOSTICS"] boolValue];
}

static void CjguiRecordTextWork(CJGuiInternalMetalView *metalView,
                                uint64_t projectionVersion,
                                uint64_t contentUtf8Bytes,
                                CjguiInternalTextWorkReason reason) {
    if (!metalView) return;
    if (reason >= CjguiInternalTextWorkReasonCount) reason = CjguiInternalTextWorkReasonUnknown;
    // Objective-C struct properties are returned by value. Mutate a local
    // copy, then assign it back, so attribution is retained across events.
    CjguiInternalTextWorkReasonCounters counters = metalView.testComposableTextWorkReasonCounters;
    counters.raster[reason] = CjguiSaturatingAddU64(counters.raster[reason], 1);
    counters.upload[reason] = CjguiSaturatingAddU64(counters.upload[reason], 1);
    metalView.testComposableTextWorkReasonCounters = counters;
    metalView.testComposableTextLastProjectionVersion = projectionVersion;
    metalView.testComposableTextLastContentUtf8Bytes = contentUtf8Bytes;
}
#endif

@implementation CJGuiInternalMetalView

- (CGFloat)currentBackingScale {
#ifdef CJGUI_INTERNAL_TESTING
    if (self.testBackingScaleOverride > 0.0) return self.testBackingScaleOverride;
#endif
    return self.window ? self.window.backingScaleFactor : NSScreen.mainScreen.backingScaleFactor;
}

- (instancetype)initWithFrame:(NSRect)frame
                       device:(id<MTLDevice>)device
                 commandQueue:(id<MTLCommandQueue>)commandQueue {
    self = [super initWithFrame:frame];
    if (!self || !device || !commandQueue) {
        return nil;
    }

    self.wantsLayer = YES;
    self.device = device;
    self.commandQueue = commandQueue;

    self.metalLayer = [CAMetalLayer layer];
    if (!self.metalLayer) {
        return nil;
    }

    self.metalLayer.device = self.device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    // Readback probe requires a blit-readable drawable.
    self.metalLayer.framebufferOnly = NO;
    self.metalLayer.contentsScale = [self currentBackingScale];
    self.layer = self.metalLayer;
    [self updateDrawableSize];

    return self;
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self updateDrawableSize];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self updateDrawableSize];
}

- (void)updateDrawableSize {
    if (!self.metalLayer || self.invalidated) {
        return;
    }
    CGFloat scale = [self currentBackingScale];
    CGSize pointSize = self.bounds.size;
    self.metalLayer.frame = self.bounds;
    self.metalLayer.contentsScale = scale;
    self.metalLayer.drawableSize = CGSizeMake(pointSize.width * scale,
                                              pointSize.height * scale);
}

- (void)invalidateBridgeResources {
    if (self.invalidated) {
        return;
    }
    self.invalidated = YES;
    self.layer = nil;
    self.metalLayer = nil;
    self.commandQueue = nil;
    self.device = nil;
    self.composableImagePipeline = nil;
}

- (BOOL)encodeComposableNodes:(id<MTLRenderCommandEncoder>)encoder drawableSize:(CGSize)drawableSize {
    return CjguiEncodeComposableNodes(self, encoder, drawableSize);
}

@end

// ---- session context ----

@class CJGuiInternalSharedOperationOverlay;
@class CJGuiInternalSharedEditingFormOverlay;
@class CJGuiInternalComposableSceneOverlay;

// AppKit asks its first responder for this rectangle when positioning an IME
// candidate window. The actual editor surface is self-drawn by the overlay,
// so the normal NSTextView implementation would incorrectly return the
// deliberately off-canvas proxy frame.
@interface CJGuiInternalComposableInputProxy : NSTextView
@property(nonatomic, weak) CJGuiInternalComposableSceneOverlay *composableOverlay;
// TextKit owns the platform composition, while the overlay retains only the
// committed projection. Keep the pre-composition adapter state long enough to
// make Escape/focus loss a genuine cancellation rather than an implicit
// commit of marked text.
@property(nonatomic, copy) NSString *compositionBaseString;
@property(nonatomic, assign) NSRange compositionBaseSelection;
- (void)cancelMarkedText;
@end
@class CJGuiInternalSession;
@class CJGuiInternalComposableImageResource;
static CJGuiInternalSession *CjguiLookupSession(uint64_t token);

static const NSUInteger kCjguiPendingInteractionCapacity = 64;

static BOOL CjguiEnqueueInteraction(CJGuiInternalSession *ctx, uint32_t kind,
                                    uint32_t recordIndex, NSString *text,
                                    uint32_t selectionStart, uint32_t selectionEnd);
static BOOL CjguiEnqueueComposableInteraction(CJGuiInternalSession *session,
                                              uint32_t kind, uint32_t nodeIndex,
                                              NSString *text, NSRange selection);
static BOOL CjguiEnqueueComposablePointerInteraction(CJGuiInternalSession *session,
                                                     uint32_t kind,
                                                     CJGuiInternalComposableSceneNode *node,
                                                     NSPoint point);
static uint64_t CjguiComposableNodeIdAtIndex(CJGuiInternalSession *session, uint32_t nodeIndex);
static int64_t CjguiComposableNodeResourceIdAtIndex(CJGuiInternalSession *session, uint32_t nodeIndex);
static uint32_t CjguiComposableNodeKindAtIndex(CJGuiInternalSession *session, uint32_t nodeIndex);
static NSRange CjguiComposedSelection(NSString *text, NSUInteger start, NSUInteger end);

@interface CJGuiInternalQueuedInteraction : NSObject
@property(nonatomic, assign) uint32_t kind;
@property(nonatomic, assign) uint32_t recordIndex;
@property(nonatomic, assign) uint32_t selectionStart;
@property(nonatomic, assign) uint32_t selectionEnd;
@property(nonatomic, assign) uint64_t nodeId;
@property(nonatomic, assign) uint64_t projectionVersion;
@property(nonatomic, assign) int64_t resourceId;
@property(nonatomic, assign) uint32_t nodeKind;
@property(nonatomic, assign) int64_t pointerX;
@property(nonatomic, assign) int64_t pointerY;
@property(nonatomic, copy) NSString *formText;
- (instancetype)initWithKind:(uint32_t)kind recordIndex:(uint32_t)recordIndex
              selectionStart:(uint32_t)selectionStart selectionEnd:(uint32_t)selectionEnd
                    formText:(NSString *)formText nodeId:(uint64_t)nodeId
           projectionVersion:(uint64_t)projectionVersion resourceId:(int64_t)resourceId
                     nodeKind:(uint32_t)nodeKind;
@end

@implementation CJGuiInternalQueuedInteraction

- (instancetype)initWithKind:(uint32_t)kind recordIndex:(uint32_t)recordIndex
              selectionStart:(uint32_t)selectionStart selectionEnd:(uint32_t)selectionEnd
                    formText:(NSString *)formText nodeId:(uint64_t)nodeId
           projectionVersion:(uint64_t)projectionVersion resourceId:(int64_t)resourceId
                     nodeKind:(uint32_t)nodeKind {
    self = [super init];
    if (!self) return nil;
    self.kind = kind;
    self.recordIndex = recordIndex;
    self.selectionStart = selectionStart;
    self.selectionEnd = selectionEnd;
    self.nodeId = nodeId;
    self.projectionVersion = projectionVersion;
    self.resourceId = resourceId;
    self.nodeKind = nodeKind;
    self.pointerX = 0;
    self.pointerY = 0;
    self.formText = [formText copy] ?: @"";
    return self;
}

@end

// These are concrete macOS accessibility elements, not a parallel data model.
// Pressing one only queues an intent, which the Cangjie state owner consumes on
// the next bounded pump. Values and labels are always read from the current
// projection that Cangjie supplied.
@interface CJGuiInternalSharedOperationAccessibilityAction : NSAccessibilityElement
@property(nonatomic, weak) CJGuiInternalSharedOperationOverlay *overlay;
@property(nonatomic, assign) uint32_t recordIndex;
@property(nonatomic, assign) BOOL marksRecord;
- (instancetype)initWithOverlay:(CJGuiInternalSharedOperationOverlay *)overlay
                     recordIndex:(uint32_t)recordIndex
                     marksRecord:(BOOL)marksRecord;
@end

@interface CJGuiInternalSession : NSObject <NSWindowDelegate>
@property(nonatomic, strong) NSApplication *app;
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) CJGuiInternalMetalView *view;
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) CJGuiInternalSharedOperationOverlay *sharedOperationOverlay;
@property(nonatomic, strong) CJGuiInternalSharedEditingFormOverlay *sharedEditingFormOverlay;
@property(nonatomic, strong) CJGuiInternalComposableSceneOverlay *composableSceneOverlay;
// A scene is assembled off the currently interactive projection.  Only
// present_composable_scene promotes this staging array, so AX, hit testing and
// Metal never observe a partly-filled replacement.
@property(nonatomic, strong) NSMutableArray<CJGuiInternalComposableSceneNode *> *composableNodes;
@property(nonatomic, assign) uint64_t composableSceneVersion;
@property(nonatomic, strong) NSMutableArray<CJGuiInternalComposableSceneNode *> *stagedComposableNodes;
@property(nonatomic, strong) NSMutableDictionary<NSString *, id<MTLTexture>> *composableImageTextureCache;
// Resource records are scalars plus retained Metal textures.  They never
// cross the framework ABI.  Loading itself may finish off-main, but every
// record/cache/queue mutation below is confined to the AppKit main thread.
@property(nonatomic, strong) NSMutableDictionary<NSString *, CJGuiInternalComposableImageResource *> *composableImageResources;
@property(nonatomic, strong) NSMutableDictionary<NSString *, MTKTextureLoader *> *composableImageLoaders;
@property(nonatomic, strong) NSMutableArray<NSString *> *composableImagePendingKeys;
@property(nonatomic, assign) uint64_t composableImageAccessClock;
@property(nonatomic, assign) uint64_t composableImageResourceCompletionVersion;
@property(nonatomic, assign) uint32_t composableImageDecodeCount;
#ifdef CJGUI_INTERNAL_TESTING
// Holds launch only; it never replaces the asynchronous loader.  The probe
// uses it to prove an accepted loading scene still services real FIFO input.
@property(nonatomic, assign) BOOL testComposableImageLaunchGateHeld;
#endif
// Counts actual Cangjie-to-native node writes, not scene frames. It is test
// observability for the staged-node reuse regression and never crosses the
// production/public ABI.
@property(nonatomic, assign) uint64_t composableSceneNodeUpdateCount;
#ifdef CJGUI_INTERNAL_TESTING
// Scalar submission accounting for scale probes.  These counters describe
// native object work only: the Cangjie build/layout timers and Metal submit
// progress remain separate so no nested timing sum is presented as E2E cost.
@property(nonatomic, assign) uint64_t testComposableSceneCloneCount;
@property(nonatomic, assign) uint64_t testComposableSceneNodeAllocationCount;
@property(nonatomic, assign) uint64_t testComposableSceneConfigureMicros;
@property(nonatomic, assign) uint64_t testComposableSceneSetMicros;
@property(nonatomic, assign) uint64_t testComposableSceneCommitMicros;
@property(nonatomic, assign) uint64_t testComposableImagePathResolveMicros;
@property(nonatomic, assign) uint64_t testComposableImageCacheHitCount;
@property(nonatomic, assign) uint64_t testComposableImageAsyncLaunchCount;
@property(nonatomic, assign) uint64_t testComposableImageAsyncTotalMicros;
@property(nonatomic, assign) uint32_t testComposableImagePeakInFlight;
@property(nonatomic, assign) uint32_t testComposableImagePeakPending;
#endif
// Observability for the probe-only measurement-cache check.  It counts the
// real AppKit query, rather than layout calls, so a no-op refresh can prove it
// did not cross the native boundary again.
@property(nonatomic, assign) uint32_t composableTextMeasurementCount;
@property(nonatomic, assign) uint32_t forcedComposableMeasurementFailures;
#ifdef CJGUI_INTERNAL_TESTING
// Test-only one-shot failure seams for a candidate transaction.  They are
// intentionally scalar counters: probes can verify rollback without exposing
// a native scene/object through the public framework boundary.
@property(nonatomic, assign) uint32_t forcedComposableSceneNodeFailures;
@property(nonatomic, assign) uint32_t forcedComposablePresentFailures;
@property(nonatomic, assign) uint32_t forcedComposableTextPreparationFailures;
#endif
@property(nonatomic, assign) uint64_t composableLocalAcknowledgementCount;
@property(nonatomic, assign) uint64_t stagedComposableSceneVersion;
@property(nonatomic, assign) uint64_t resizeVersion;
// These are copied only by the main-thread completion observer after a real
// Metal command buffer finishes.  They never mean that an AppKit overlay drew
// or a person saw pixels.
@property(nonatomic, assign) uint64_t sessionGeneration;
@property(nonatomic, assign) uint64_t observedMetalCompletionFrameIndex;
@property(nonatomic, assign) uint64_t observedMetalFailureFrameIndex;
@property(nonatomic, assign) int64_t observedMetalGpuDurationMicros;
@property(nonatomic, assign) BOOL closeRequested;
@property(nonatomic, assign) BOOL destroyed;
@property(nonatomic, strong) NSMutableArray<CJGuiInternalQueuedInteraction *> *pendingInteractions;
@property(nonatomic, copy) NSString *pumpedFormText;
@property(nonatomic, copy) NSData *pumpedFormTextUtf8;
@property(nonatomic, assign) BOOL pendingInputQueueFullNotice;
#ifdef CJGUI_INTERNAL_TESTING
@property(nonatomic, assign) BOOL testDrawablePixelPending;
@property(nonatomic, assign) BOOL testDrawablePixelCompleted;
@property(nonatomic, assign) uint32_t testDrawablePixelX;
@property(nonatomic, assign) uint32_t testDrawablePixelY;
@property(nonatomic, assign) uint8_t testDrawablePixelBlue;
@property(nonatomic, assign) uint8_t testDrawablePixelGreen;
@property(nonatomic, assign) uint8_t testDrawablePixelRed;
@property(nonatomic, assign) uint8_t testDrawablePixelAlpha;
@property(nonatomic, assign) uint64_t testComposableInputMutationMicros;
@property(nonatomic, assign) uint64_t testComposableTextDelegateMicros;
@property(nonatomic, assign) uint64_t testComposableSelectionDelegateMicros;
@property(nonatomic, assign) uint64_t testComposableEventEnqueueMicros;
@property(nonatomic, assign) uint64_t testComposableAccessibilityMicros;
@property(nonatomic, assign) uint32_t testComposableMaxPendingInteractionCount;
@property(nonatomic, assign) uint64_t testComposableAccessibilityNotificationCount;
@property(nonatomic, assign) uint32_t testComposableLastEnqueuedKind;
@property(nonatomic, assign) uint64_t testComposableLastEnqueuedNodeId;
@property(nonatomic, assign) uint64_t testComposableLastEnqueuedProjectionVersion;
@property(nonatomic, assign) uint32_t testComposableLastPumpedKind;
@property(nonatomic, assign) uint64_t testComposableLastPumpedNodeId;
@property(nonatomic, assign) uint64_t testComposableLastPumpedProjectionVersion;
// A retained AX element is test-only evidence for stale-object rejection.
// It remains an Objective-C object inside the native test binary; no handle
// can cross the Cangjie framework boundary.
@property(nonatomic, strong) id testCapturedComposableAccessibilityAction;
#endif
@end

@implementation CJGuiInternalSession

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    self.pendingInteractions = [NSMutableArray array];
    self.composableNodes = [NSMutableArray array];
    self.stagedComposableNodes = [NSMutableArray array];
    self.composableImageTextureCache = [NSMutableDictionary dictionary];
    self.composableImageResources = [NSMutableDictionary dictionary];
    self.composableImageLoaders = [NSMutableDictionary dictionary];
    self.composableImagePendingKeys = [NSMutableArray array];
    self.pumpedFormText = @"";
    self.pumpedFormTextUtf8 = [NSData dataWithBytes:"" length:1];
    self.observedMetalGpuDurationMicros = -1;
    return self;
}

- (BOOL)windowShouldClose:(id)sender {
    (void)sender;
    if (self.closeRequested) return YES;
    (void)CjguiEnqueueInteraction(self, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE,
                                  0, @"", 0, 0);
    NSLog(@"cjgui: user close deferred to collection domain");
    return NO;
}

- (void)windowWillClose:(NSNotification *)notification {
    (void)notification;
    if (!self.closeRequested) {
        self.closeRequested = YES;
        NSLog(@"cjgui: close requested: window");
    }
    NSLog(@"cjgui: window will close");
}

- (void)windowDidResignKey:(NSNotification *)notification {
    (void)notification;
    id overlay = self.composableSceneOverlay;
    if (overlay && [overlay respondsToSelector:@selector(cancelPointerCaptureForPlatformLoss)]) {
        [overlay performSelector:@selector(cancelPointerCaptureForPlatformLoss)];
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    (void)notification;
    [self windowGeometryDidChange];
}

- (void)windowDidChangeBackingProperties:(NSNotification *)notification {
    if (notification.object != self.window) return;
    [self windowGeometryDidChange];
}

- (void)windowGeometryDidChange {
    self.resizeVersion += 1;
    [self.view updateDrawableSize];
    if (self.composableSceneOverlay) {
        (void)CjguiEnqueueComposableInteraction(self, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED,
                                                0, @"", NSMakeRange(0, 0));
    }
}

@end

// Consecutive text notifications for one field are a single logical input
// stream and may be coalesced. No focus, button, checkbox or cross-field
// boundary is crossed, so an Apply always remains after the text it applies.
// Once full, the queue refuses the new interaction and schedules an explicit
// retry notice instead of overwriting an already accepted event.
static BOOL CjguiEnqueueInteraction(CJGuiInternalSession *session,
                                    uint32_t kind, uint32_t recordIndex,
                                    NSString *formText,
                                    uint32_t selectionStart,
                                    uint32_t selectionEnd) {
    if (!session || session.destroyed) return NO;
    CJGuiInternalQueuedInteraction *last = session.pendingInteractions.lastObject;
    if (kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED &&
        last && last.kind == kind && last.recordIndex == recordIndex) {
        last.selectionStart = selectionStart;
        last.selectionEnd = selectionEnd;
        last.formText = [formText copy] ?: @"";
        return YES;
    }
    if (session.pendingInteractions.count >= kCjguiPendingInteractionCapacity) {
        session.pendingInputQueueFullNotice = YES;
        return NO;
    }
    CJGuiInternalQueuedInteraction *interaction =
        [[CJGuiInternalQueuedInteraction alloc] initWithKind:kind
                                                  recordIndex:recordIndex
                                               selectionStart:selectionStart
                                                 selectionEnd:selectionEnd
                                                     formText:formText nodeId:0 projectionVersion:0 resourceId:-1 nodeKind:0];
    if (!interaction) {
        session.pendingInputQueueFullNotice = YES;
        return NO;
    }
    [session.pendingInteractions addObject:interaction];
    return YES;
}

static BOOL CjguiEnqueueComposableInteraction(CJGuiInternalSession *session,
                                              uint32_t kind, uint32_t nodeIndex,
                                              NSString *text, NSRange selection) {
    if (!session || session.destroyed) return NO;
    uint64_t nodeId = 0;
    int64_t resourceId = -1;
    uint32_t nodeKind = 0;
    if (kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED) {
        if (nodeIndex >= session.composableNodes.count) return NO;
        nodeId = CjguiComposableNodeIdAtIndex(session, nodeIndex);
        resourceId = CjguiComposableNodeResourceIdAtIndex(session, nodeIndex);
        nodeKind = CjguiComposableNodeKindAtIndex(session, nodeIndex);
        if (nodeId == 0) return NO;
    }
    CJGuiInternalQueuedInteraction *last = session.pendingInteractions.lastObject;
    if ((kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED ||
         kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED) &&
        last && last.kind == kind && last.recordIndex == nodeIndex &&
        last.nodeId == nodeId &&
        last.projectionVersion == session.composableSceneVersion &&
        last.resourceId == resourceId && last.nodeKind == nodeKind) {
        last.selectionStart = (uint32_t)MIN(selection.location, UINT32_MAX);
        last.selectionEnd = (uint32_t)MIN(NSMaxRange(selection), UINT32_MAX);
        last.formText = [text copy] ?: @"";
        return YES;
    }
    if (session.pendingInteractions.count >= kCjguiPendingInteractionCapacity) {
        session.pendingInputQueueFullNotice = YES;
        return NO;
    }
    CJGuiInternalQueuedInteraction *interaction =
        [[CJGuiInternalQueuedInteraction alloc] initWithKind:kind recordIndex:nodeIndex
                                               selectionStart:(uint32_t)MIN(selection.location, UINT32_MAX)
                                                 selectionEnd:(uint32_t)MIN(NSMaxRange(selection), UINT32_MAX)
                                                     formText:text nodeId:nodeId projectionVersion:session.composableSceneVersion
                                                   resourceId:resourceId nodeKind:nodeKind];
    if (!interaction) { session.pendingInputQueueFullNotice = YES; return NO; }
    [session.pendingInteractions addObject:interaction];
#ifdef CJGUI_INTERNAL_TESTING
    session.testComposableLastEnqueuedKind = kind;
    session.testComposableLastEnqueuedNodeId = nodeId;
    session.testComposableLastEnqueuedProjectionVersion = session.composableSceneVersion;
    session.testComposableMaxPendingInteractionCount = (uint32_t)MIN(
        UINT32_MAX, MAX((NSUInteger)session.testComposableMaxPendingInteractionCount, session.pendingInteractions.count));
#endif
    return YES;
}

// ---- generic composable-scene data and native projection ----

static const NSUInteger CjguiComposableImageTextureCacheCapacity = 8;
static const NSUInteger CjguiComposableImageTextureCacheByteCapacity = 32u * 1024u * 1024u;
static const NSUInteger CjguiComposableImageInFlightCapacity = 4;
static const NSUInteger CjguiComposableImagePendingCapacity = 16;
static const NSUInteger CjguiComposableImageRecordCapacity = 64;
// Text is derived presentation, not document storage.  Keep a single scene
// bounded even when a malformed projection supplies enormous logical bounds.
// A Retina normal Host can expose several dozen short text rows at once.
// 24 MiB stays explicitly bounded (and below the existing image-cache
// envelope) while admitting that ordinary 256-node viewport during resize.
// A 1000x400pt editor is 6.4 MiB at 2x, so a 4 MiB per-tile limit rejected a
// normal fully visible editor.  Keep one CPU bitmap + one scene texture
// bounded at 8 MiB; the scene admission check still caps all live text at
// 24 MiB rather than letting individual controls grow without limit.
static const NSUInteger CjguiComposableTextTextureByteCapacity = 24u * 1024u * 1024u;
static const NSUInteger CjguiComposableTextTexturePerNodeByteCapacity = 8u * 1024u * 1024u;
static const NSUInteger CjguiComposableTextTextureDimensionCapacity = 4096u;

typedef NS_ENUM(uint32_t, CjguiComposableImageResourceState) {
    CjguiComposableImageResourceUnrequested = 0,
    CjguiComposableImageResourceLoading = 1,
    CjguiComposableImageResourceReady = 2,
    CjguiComposableImageResourceFailed = 3,
    // Admission is temporarily full. This is not a file/decode failure;
    // visible scene references are promoted fairly by the next completion.
    CjguiComposableImageResourceBusy = 4,
};

@interface CJGuiInternalComposableSceneNode : NSObject
@property(nonatomic, assign) CjguiInternalRendererComposableNode node;
@property(nonatomic, copy) NSString *label;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, copy) NSString *imageResourcePath;
@property(nonatomic, copy) NSString *imageResourceId;
@property(nonatomic, assign) uint64_t imageResourceVersion;
// The declared key can advance while an old texture is intentionally retained
// as a loading fallback. Keep the actual texture provenance separate so a
// cache eviction never relabels that old texture as the new declaration.
@property(nonatomic, copy) NSString *imageTextureCacheKey;
@property(nonatomic, copy) NSString *imageTextureContentKey;
@property(nonatomic, strong) id<MTLTexture> imageTexture;
// Raster text is an implementation-local GPU resource.  It contains no
// writable document state: the composable overlay retains the sole TextKit
// input proxy and redraws this immutable projection when content/style/scale
// changes.
@property(nonatomic, copy) NSString *textTextureCacheKey;
@property(nonatomic, strong) id<MTLTexture> textTexture;
@property(nonatomic, assign) uint64_t textTextureByteCount;
// Logical scene rectangle represented by textTexture. It may be a clipped
// tile of the node rather than the whole node bounds.
@property(nonatomic, assign) NSRect textTextureRect;
// Selection, marked-range and caret pixels are presentation-only geometry.
// They stay in the scene node's existing clip chain and sandwich the immutable
// body texture in painter order, so a caret move never allocates/reuploads the
// body tile or adds a second text/layout owner.
@property(nonatomic, copy) NSArray<NSValue *> *textSelectionRects;
@property(nonatomic, copy) NSArray<NSValue *> *textMarkedRects;
@property(nonatomic, assign) NSRect textCaretRect;
@property(nonatomic, assign) uint32_t index;
@end

@implementation CJGuiInternalComposableSceneNode
@end

static BOOL CjguiEnqueueComposablePointerInteraction(CJGuiInternalSession *session,
                                                     uint32_t kind,
                                                     CJGuiInternalComposableSceneNode *node,
                                                     NSPoint point) {
    if (!session || session.destroyed || !node || !isfinite(point.x) || !isfinite(point.y)) return NO;
    uint32_t nodeIndex = node.index;
    uint64_t nodeId = node.node.nodeId;
    int64_t resourceId = node.node.resourceId;
    uint32_t nodeKind = node.node.nodeKind;
    if (nodeId == 0 || nodeIndex >= session.composableNodes.count) return NO;
    CJGuiInternalQueuedInteraction *last = session.pendingInteractions.lastObject;
    // Only adjacent updates for exactly one captured identity can merge. A
    // terminal end/cancel is deliberately never coalesced behind a move.
    if (kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE && last &&
        last.kind == kind && last.nodeId == nodeId && last.resourceId == resourceId &&
        last.nodeKind == nodeKind && last.projectionVersion == session.composableSceneVersion) {
        last.pointerX = (int64_t)llround(point.x);
        last.pointerY = (int64_t)llround(point.y);
        return YES;
    }
    if (session.pendingInteractions.count >= kCjguiPendingInteractionCapacity) {
        session.pendingInputQueueFullNotice = YES;
        return NO;
    }
    CJGuiInternalQueuedInteraction *interaction =
        [[CJGuiInternalQueuedInteraction alloc] initWithKind:kind recordIndex:nodeIndex
                                               selectionStart:0 selectionEnd:0 formText:@""
                                                       nodeId:nodeId projectionVersion:session.composableSceneVersion
                                                   resourceId:resourceId nodeKind:nodeKind];
    if (!interaction) {
        session.pendingInputQueueFullNotice = YES;
        return NO;
    }
    interaction.pointerX = (int64_t)llround(point.x);
    interaction.pointerY = (int64_t)llround(point.y);
    [session.pendingInteractions addObject:interaction];
#ifdef CJGUI_INTERNAL_TESTING
    session.testComposableLastEnqueuedKind = kind;
    session.testComposableLastEnqueuedNodeId = nodeId;
    session.testComposableLastEnqueuedProjectionVersion = session.composableSceneVersion;
    session.testComposableMaxPendingInteractionCount = (uint32_t)MIN(
        UINT32_MAX, MAX((NSUInteger)session.testComposableMaxPendingInteractionCount, session.pendingInteractions.count));
#endif
    return YES;
}

static void CjguiClearComposableTextDecorations(CJGuiInternalComposableSceneNode *node) {
    if (!node) return;
    node.textSelectionRects = @[];
    node.textMarkedRects = @[];
    node.textCaretRect = NSZeroRect;
}

@interface CJGuiInternalComposableImageResource : NSObject
@property(nonatomic, copy) NSString *cacheKey;
@property(nonatomic, copy) NSString *resolvedPath;
@property(nonatomic, assign) uint32_t state;
@property(nonatomic, assign) uint64_t lastAccess;
@property(nonatomic, strong) id<MTLTexture> texture;
#ifdef CJGUI_INTERNAL_TESTING
@property(nonatomic, assign) uint64_t launchMicros;
#endif
@end

@implementation CJGuiInternalComposableImageResource
@end

static NSString *CjguiComposableImageResolvedPath(NSString *resourcePath) {
    if (resourcePath.length == 0) return nil;
    NSString *resolved = resourcePath;
    if (![resolved isAbsolutePath]) {
        NSString *fromWorkingDirectory = [NSFileManager.defaultManager.currentDirectoryPath stringByAppendingPathComponent:resolved];
        if ([NSFileManager.defaultManager fileExistsAtPath:fromWorkingDirectory]) {
            resolved = fromWorkingDirectory;
        } else if (NSBundle.mainBundle.resourcePath.length > 0) {
            resolved = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resolved];
        } else {
            resolved = fromWorkingDirectory;
        }
    }
    return resolved.stringByStandardizingPath;
}

static NSString *CjguiComposableImageCacheKey(NSString *resourcePath, NSString *resourceId,
                                              uint64_t resourceVersion, NSString **outResolved) {
    if (outResolved) *outResolved = nil;
    NSString *resolved = CjguiComposableImageResolvedPath(resourcePath);
    if (!resolved) return nil;
    NSString *logicalId = resourceId.length > 0 ? resourceId : resolved;
    NSString *cacheKey = [NSString stringWithFormat:@"%@\n%llu\n%@", logicalId, resourceVersion, resolved];
    if (outResolved) *outResolved = resolved;
    return cacheKey;
}

// A committed/staged node owns its texture independently of the reusable
// cache. This is the only internal path that may reuse that strong reference;
// callers still receive only scalar resource states across the ABI.
static id<MTLTexture> CjguiComposableImageBoundTexture(CJGuiInternalSession *session, NSString *cacheKey) {
    if (!session || cacheKey.length == 0) return nil;
    for (CJGuiInternalComposableSceneNode *node in session.stagedComposableNodes) {
        if ([node.imageTextureContentKey isEqualToString:cacheKey] && node.imageTexture) return node.imageTexture;
    }
    for (CJGuiInternalComposableSceneNode *node in session.composableNodes) {
        if ([node.imageTextureContentKey isEqualToString:cacheKey] && node.imageTexture) return node.imageTexture;
    }
    return nil;
}

static uint64_t CjguiComposableImageNextAccess(CJGuiInternalSession *session) {
    if (!session) return 0;
    if (session.composableImageAccessClock < UINT64_MAX) session.composableImageAccessClock += 1;
    return session.composableImageAccessClock;
}

static NSUInteger CjguiComposableImageTextureBytes(id<MTLTexture> texture) {
    if (!texture) return 0;
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    if (width == 0 || height == 0 || width > NSUIntegerMax / height) return NSUIntegerMax;
    NSUInteger pixels = width * height;
    return pixels > NSUIntegerMax / 4 ? NSUIntegerMax : pixels * 4;
}

static NSMutableSet<NSString *> *CjguiComposableImageProtectedKeys(CJGuiInternalSession *session,
                                                                     BOOL preserveSceneReferences) {
    NSMutableSet<NSString *> *keys = [NSMutableSet set];
    // Before the next scene commit, referenced loading nodes have only a key
    // and still need the completion cache entry to obtain their texture. Once
    // commit has copied the texture directly into its nodes, those keys must
    // no longer pin a duplicate cache reference forever.
    if (preserveSceneReferences) {
        for (CJGuiInternalComposableSceneNode *node in session.composableNodes) {
            if (node.imageTextureCacheKey.length > 0) [keys addObject:node.imageTextureCacheKey];
        }
        for (CJGuiInternalComposableSceneNode *node in session.stagedComposableNodes) {
            if (node.imageTextureCacheKey.length > 0) [keys addObject:node.imageTextureCacheKey];
        }
    }
    [keys addObjectsFromArray:session.composableImageLoaders.allKeys];
    [keys addObjectsFromArray:session.composableImagePendingKeys];
    return keys;
}

static void CjguiPruneComposableImageTextureCache(CJGuiInternalSession *session, BOOL preserveSceneReferences) {
    if (!session) return;
    NSMutableSet<NSString *> *protectedKeys = CjguiComposableImageProtectedKeys(session, preserveSceneReferences);
    NSUInteger totalBytes = 0;
    for (id<MTLTexture> texture in session.composableImageTextureCache.allValues) {
        NSUInteger bytes = CjguiComposableImageTextureBytes(texture);
        totalBytes = bytes > NSUIntegerMax - totalBytes ? NSUIntegerMax : totalBytes + bytes;
    }
    while (session.composableImageTextureCache.count > CjguiComposableImageTextureCacheCapacity ||
           totalBytes > CjguiComposableImageTextureCacheByteCapacity) {
        NSString *victim = nil;
        uint64_t oldest = UINT64_MAX;
        for (NSString *key in session.composableImageTextureCache) {
            if ([protectedKeys containsObject:key]) continue;
            CJGuiInternalComposableImageResource *resource = session.composableImageResources[key];
            uint64_t access = resource ? resource.lastAccess : 0;
            if (!victim || access < oldest) { victim = key; oldest = access; }
        }
        // All remaining keys are in-flight/pending and cannot safely lose the
        // cache entry before their completion path has resolved.
        if (!victim) break;
        id<MTLTexture> texture = session.composableImageTextureCache[victim];
        NSUInteger bytes = CjguiComposableImageTextureBytes(texture);
        [session.composableImageTextureCache removeObjectForKey:victim];
        CJGuiInternalComposableImageResource *resource = session.composableImageResources[victim];
        if (resource) { resource.texture = nil; resource.state = CjguiComposableImageResourceUnrequested; }
        totalBytes = bytes > totalBytes ? 0 : totalBytes - bytes;
    }
    while (session.composableImageResources.count > CjguiComposableImageRecordCapacity) {
        NSString *victim = nil;
        uint64_t oldest = UINT64_MAX;
        for (NSString *key in session.composableImageResources) {
            if ([protectedKeys containsObject:key] || session.composableImageTextureCache[key]) continue;
            CJGuiInternalComposableImageResource *resource = session.composableImageResources[key];
            if (!victim || resource.lastAccess < oldest) { victim = key; oldest = resource.lastAccess; }
        }
        if (!victim) break;
        [session.composableImageResources removeObjectForKey:victim];
    }
}

static void CjguiStartNextComposableImageLoads(CJGuiInternalSession *session, uint64_t sessionToken);

// Busy records consume no pending slot. A loader completion revisits visible
// declarations in their stable scene order and admits as many as the bounded
// queue can hold. Explicit preloads that are not referenced stay visibly
// `busy` for their caller to retry; no timer or unbounded side queue exists.
static void CjguiPromoteReferencedBusyImageResources(CJGuiInternalSession *session) {
    if (!session || session.composableImagePendingKeys.count >= CjguiComposableImagePendingCapacity) return;
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    NSArray<NSArray<CJGuiInternalComposableSceneNode *> *> *nodeSets = @[
        session.stagedComposableNodes ?: @[], session.composableNodes ?: @[]
    ];
    for (NSArray<CJGuiInternalComposableSceneNode *> *nodes in nodeSets) {
        for (CJGuiInternalComposableSceneNode *node in nodes) {
            NSString *cacheKey = node.imageTextureCacheKey;
            if (cacheKey.length == 0 || [seen containsObject:cacheKey]) continue;
            [seen addObject:cacheKey];
            CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
            if (!resource || resource.state != CjguiComposableImageResourceBusy) continue;
            resource.state = CjguiComposableImageResourceLoading;
            resource.lastAccess = CjguiComposableImageNextAccess(session);
            [session.composableImagePendingKeys addObject:cacheKey];
#ifdef CJGUI_INTERNAL_TESTING
            session.testComposableImagePeakPending = (uint32_t)MIN(
                UINT32_MAX, MAX((NSUInteger)session.testComposableImagePeakPending, session.composableImagePendingKeys.count));
#endif
            if (session.composableImagePendingKeys.count >= CjguiComposableImagePendingCapacity) return;
        }
    }
}

static BOOL CjguiComposableImageKeyIsReferenced(CJGuiInternalSession *session, NSString *cacheKey) {
    if (!session || cacheKey.length == 0) return NO;
    for (CJGuiInternalComposableSceneNode *node in session.composableNodes) {
        if ([node.imageTextureCacheKey isEqualToString:cacheKey]) return YES;
    }
    for (CJGuiInternalComposableSceneNode *node in session.stagedComposableNodes) {
        if ([node.imageTextureCacheKey isEqualToString:cacheKey]) return YES;
    }
    return NO;
}

static void CjguiCompleteComposableImageLoad(uint64_t sessionToken, uint64_t generation, NSString *cacheKey,
                                             id<MTLTexture> texture, NSError *error) {
    CJGuiInternalSession *session = CjguiLookupSession(sessionToken);
    if (!session || session.destroyed || session.sessionGeneration != generation) return;
    [session.composableImageLoaders removeObjectForKey:cacheKey];
    CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
    if (!resource || resource.state != CjguiComposableImageResourceLoading) {
        CjguiStartNextComposableImageLoads(session, sessionToken);
        return;
    }
#ifdef CJGUI_INTERNAL_TESTING
    if (resource.launchMicros > 0 && CjguiMonotonicMicros() >= resource.launchMicros) {
        session.testComposableImageAsyncTotalMicros += CjguiMonotonicMicros() - resource.launchMicros;
    }
#endif
    resource.lastAccess = CjguiComposableImageNextAccess(session);
    if (texture) {
        resource.texture = texture;
        resource.state = CjguiComposableImageResourceReady;
        session.composableImageTextureCache[cacheKey] = texture;
        if (session.composableImageDecodeCount < UINT32_MAX) session.composableImageDecodeCount += 1;
        NSLog(@"cjgui: composable image preparation ready path=%@", resource.resolvedPath);
    } else {
        resource.texture = nil;
        resource.state = CjguiComposableImageResourceFailed;
        NSLog(@"cjgui: composable image texture load failed path=%@ error=%@", resource.resolvedPath, error);
    }
    // A completed preload that no live/candidate scene references is already
    // cached; it must not wake an otherwise-idle normal window. A matching
    // later controller revision will obtain it synchronously from the cache.
    if (CjguiComposableImageKeyIsReferenced(session, cacheKey) &&
        session.composableImageResourceCompletionVersion < UINT64_MAX) {
        session.composableImageResourceCompletionVersion += 1;
    }
    CjguiPruneComposableImageTextureCache(session, YES);
    CjguiStartNextComposableImageLoads(session, sessionToken);
}

static void CjguiStartNextComposableImageLoads(CJGuiInternalSession *session, uint64_t sessionToken) {
    if (!session || session.destroyed || !session.device) return;
#ifdef CJGUI_INTERNAL_TESTING
    if (session.testComposableImageLaunchGateHeld) return;
#endif
    CjguiPromoteReferencedBusyImageResources(session);
    while (session.composableImageLoaders.count < CjguiComposableImageInFlightCapacity &&
           session.composableImagePendingKeys.count > 0) {
        NSString *cacheKey = session.composableImagePendingKeys.firstObject;
        [session.composableImagePendingKeys removeObjectAtIndex:0];
        CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
        if (!resource || resource.state != CjguiComposableImageResourceLoading ||
            session.composableImageLoaders[cacheKey]) continue;
        MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:session.device];
        if (!loader) {
            resource.state = CjguiComposableImageResourceFailed;
            if (session.composableImageResourceCompletionVersion < UINT64_MAX) session.composableImageResourceCompletionVersion += 1;
            continue;
        }
        const uint64_t generation = session.sessionGeneration;
        session.composableImageLoaders[cacheKey] = loader;
#ifdef CJGUI_INTERNAL_TESTING
        resource.launchMicros = CjguiMonotonicMicros();
        if (session.testComposableImageAsyncLaunchCount < UINT64_MAX) session.testComposableImageAsyncLaunchCount += 1;
        session.testComposableImagePeakInFlight = (uint32_t)MIN(
            UINT32_MAX, MAX((NSUInteger)session.testComposableImagePeakInFlight, session.composableImageLoaders.count));
#endif
        NSURL *url = [NSURL fileURLWithPath:resource.resolvedPath];
        NSLog(@"cjgui: composable image preparation started path=%@", resource.resolvedPath);
        [loader newTextureWithContentsOfURL:url
                                    options:@{ MTKTextureLoaderOptionSRGB: @NO,
                                               MTKTextureLoaderOptionGenerateMipmaps: @NO }
                          completionHandler:^(id<MTLTexture> texture, NSError *error) {
            // The existing bounded AppKit pump runs the main run-loop mode;
            // place the completion on that exact mode rather than requiring
            // a second resource loop or a periodic poll.
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
                CjguiCompleteComposableImageLoad(sessionToken, generation, cacheKey, texture, error);
            });
            CFRunLoopWakeUp(CFRunLoopGetMain());
        }];
    }
    CjguiPromoteReferencedBusyImageResources(session);
}

static uint32_t CjguiPrepareComposableImageResourceOnMain(CJGuiInternalSession *session, uint64_t sessionToken,
                                                          NSString *resourcePath, NSString *resourceId,
                                                          uint64_t resourceVersion, BOOL retriesFailed,
                                                          NSString **outCacheKey) {
    if (outCacheKey) *outCacheKey = nil;
    if (!session || session.destroyed || !session.device) return CjguiComposableImageResourceFailed;
    NSString *resolved = nil;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t resolveStarted = CjguiMonotonicMicros();
#endif
    NSString *cacheKey = CjguiComposableImageCacheKey(resourcePath, resourceId, resourceVersion, &resolved);
#ifdef CJGUI_INTERNAL_TESTING
    session.testComposableImagePathResolveMicros += CjguiMonotonicMicros() - resolveStarted;
#endif
    if (!cacheKey) return CjguiComposableImageResourceFailed;
    if (outCacheKey) *outCacheKey = cacheKey;
    CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
    id<MTLTexture> cached = session.composableImageTextureCache[cacheKey];
    if (cached) {
        if (!resource) {
            resource = [[CJGuiInternalComposableImageResource alloc] init];
            resource.cacheKey = cacheKey; resource.resolvedPath = resolved;
            session.composableImageResources[cacheKey] = resource;
        }
        resource.texture = cached;
        resource.state = CjguiComposableImageResourceReady;
        resource.lastAccess = CjguiComposableImageNextAccess(session);
#ifdef CJGUI_INTERNAL_TESTING
        if (session.testComposableImageCacheHitCount < UINT64_MAX) session.testComposableImageCacheHitCount += 1;
#endif
        return resource.state;
    }
    id<MTLTexture> boundTexture = CjguiComposableImageBoundTexture(session, cacheKey);
    if (boundTexture) {
        if (!resource) {
            resource = [[CJGuiInternalComposableImageResource alloc] init];
            resource.cacheKey = cacheKey; resource.resolvedPath = resolved;
            session.composableImageResources[cacheKey] = resource;
        }
        // This texture remains owned by a scene node, not by the reusable
        // cache/record. Its key can therefore be ready without consuming
        // cache budget or triggering a duplicate decode.
        resource.texture = nil;
        resource.state = CjguiComposableImageResourceReady;
        resource.lastAccess = CjguiComposableImageNextAccess(session);
        return resource.state;
    }
    if (!resource) {
        resource = [[CJGuiInternalComposableImageResource alloc] init];
        resource.cacheKey = cacheKey; resource.resolvedPath = resolved;
        resource.state = CjguiComposableImageResourceLoading;
        resource.lastAccess = CjguiComposableImageNextAccess(session);
        session.composableImageResources[cacheKey] = resource;
        if (session.composableImagePendingKeys.count < CjguiComposableImagePendingCapacity) {
            [session.composableImagePendingKeys addObject:cacheKey];
#ifdef CJGUI_INTERNAL_TESTING
            session.testComposableImagePeakPending = (uint32_t)MIN(
                UINT32_MAX, MAX((NSUInteger)session.testComposableImagePeakPending, session.composableImagePendingKeys.count));
#endif
        } else {
            resource.state = CjguiComposableImageResourceBusy;
        }
    } else {
        resource.lastAccess = CjguiComposableImageNextAccess(session);
        if (resource.state == CjguiComposableImageResourceUnrequested ||
            resource.state == CjguiComposableImageResourceBusy ||
            (retriesFailed && resource.state == CjguiComposableImageResourceFailed)) {
            resource.state = CjguiComposableImageResourceLoading;
            if (session.composableImagePendingKeys.count < CjguiComposableImagePendingCapacity) {
                [session.composableImagePendingKeys addObject:cacheKey];
#ifdef CJGUI_INTERNAL_TESTING
                session.testComposableImagePeakPending = (uint32_t)MIN(
                    UINT32_MAX, MAX((NSUInteger)session.testComposableImagePeakPending, session.composableImagePendingKeys.count));
#endif
            } else {
                resource.state = CjguiComposableImageResourceBusy;
            }
        }
    }
    CjguiStartNextComposableImageLoads(session, sessionToken);
    CjguiPruneComposableImageTextureCache(session, NO);
    return resource.state;
}

static id<MTLTexture> CjguiComposableImageTexture(CJGuiInternalSession *session, uint64_t sessionToken,
                                                  NSString *resourcePath, NSString *resourceId,
                                                  uint64_t resourceVersion, NSString **outCacheKey,
                                                  uint32_t *outState) {
    NSString *cacheKey = nil;
    uint32_t state = CjguiPrepareComposableImageResourceOnMain(session, sessionToken, resourcePath, resourceId,
                                                               resourceVersion, NO, &cacheKey);
    if (outState) *outState = state;
    if (outCacheKey) *outCacheKey = cacheKey;
    if (!cacheKey || state != CjguiComposableImageResourceReady) return nil;
    return session.composableImageTextureCache[cacheKey] ?: CjguiComposableImageBoundTexture(session, cacheKey);
}

// A source-verified image frame is useful after a dynamic resource or
// fit/fill change, but forcing a synchronous readback for unrelated text
// edits would make ordinary refreshes unnecessarily expensive.
static BOOL CjguiComposableImageContentChanged(NSArray<CJGuiInternalComposableSceneNode *> *before,
                                               NSArray<CJGuiInternalComposableSceneNode *> *after) {
    NSMutableDictionary<NSNumber *, CJGuiInternalComposableSceneNode *> *oldByNodeId = [NSMutableDictionary dictionary];
    for (CJGuiInternalComposableSceneNode *node in before) {
        if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) oldByNodeId[@(node.node.nodeId)] = node;
    }
    NSUInteger oldImageCount = oldByNodeId.count;
    NSUInteger newImageCount = 0;
    for (CJGuiInternalComposableSceneNode *node in after) {
        if (node.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) continue;
        newImageCount += 1;
        CJGuiInternalComposableSceneNode *previous = oldByNodeId[@(node.node.nodeId)];
        if (!previous || ![previous.imageTextureCacheKey isEqualToString:node.imageTextureCacheKey] ||
            previous.node.imageContentMode != node.node.imageContentMode ||
            previous.node.x != node.node.x || previous.node.y != node.node.y ||
            previous.node.width != node.node.width || previous.node.height != node.node.height ||
            previous.node.clipX != node.node.clipX || previous.node.clipY != node.node.clipY ||
            previous.node.clipWidth != node.node.clipWidth || previous.node.clipHeight != node.node.clipHeight) return YES;
    }
    return oldImageCount != newImageCount;
}

// A generic first-frame readback is intentionally much narrower than the
// renderer: it may only compare a pixel when the final Metal value is fully
// determined by an opaque, unclipped rectangle.  In particular, never clamp
// a centre outside a scroll clip, and never infer an alpha/image result from
// a lower layer.  Exact transparent and image pixels use the testing asset
// path below instead of making this diagnostic guess.
typedef struct {
    // This is the logical centre of the exact drawable texel that the blit
    // will read. It is deliberately not the mathematical centre of a node:
    // at an odd width or non-integral scale those can select different pixels.
    CGFloat logicalX;
    CGFloat logicalY;
    NSUInteger sampleX;
    NSUInteger sampleY;
} CjguiComposableReadbackProbePoint;

static BOOL CjguiComposablePointInInterval(CGFloat point, int64_t start, int64_t length) {
    return length > 0 && point >= (CGFloat)start && point < (CGFloat)start + (CGFloat)length;
}

static BOOL CjguiComposablePointInRoundedComponents(CGFloat pointX, CGFloat pointY,
                                                     CGFloat x, CGFloat y, CGFloat width, CGFloat height,
                                                     CGFloat cornerRadius) {
    if (width <= 0.0 || height <= 0.0 || pointX < x || pointY < y || pointX >= x + width || pointY >= y + height) return NO;
    CGFloat radius = MIN(MAX(0.0, cornerRadius), MIN(width, height) / 2.0);
    if (radius <= 0.0 || (pointX >= x + radius && pointX < x + width - radius) ||
        (pointY >= y + radius && pointY < y + height - radius)) return YES;
    CGFloat centreX = pointX < x + radius ? x + radius : x + width - radius;
    CGFloat centreY = pointY < y + radius ? y + radius : y + height - radius;
    CGFloat dx = pointX - centreX, dy = pointY - centreY;
    return dx * dx + dy * dy <= radius * radius;
}

static BOOL CjguiComposablePointInClipChain(CGFloat pointX, CGFloat pointY,
                                             CjguiInternalRendererComposableNode value) {
    uint32_t count = CjguiComposableClipConstraintCount(value);
    for (uint32_t i = 0; i < count; i++) {
        CGFloat x = 0, y = 0, width = 0, height = 0, radius = 0;
        CjguiComposableClipConstraintAt(value, i, &x, &y, &width, &height, &radius);
        if (!CjguiComposablePointInRoundedComponents(pointX, pointY, x, y, width, height, radius)) return NO;
    }
    return YES;
}

static BOOL CjguiComposableNodeContainsVisiblePoint(CJGuiInternalComposableSceneNode *node,
                                                     CGFloat pointX, CGFloat pointY, NSSize viewSize) {
    if (!node || viewSize.width <= 0.0 || viewSize.height <= 0.0) return NO;
    CjguiInternalRendererComposableNode value = node.node;
    return CjguiComposablePointInInterval(pointX, value.x, value.width) &&
        CjguiComposablePointInInterval(pointY, value.y, value.height) &&
        CjguiComposablePointInClipChain(pointX, pointY, value) &&
        pointX >= 0 && pointY >= 0 &&
        pointX < viewSize.width && pointY < viewSize.height;
}

static BOOL CjguiComposableRectContainsPoint(NSRect rect, CGFloat pointX, CGFloat pointY) {
    return !NSIsEmptyRect(rect) && pointX >= NSMinX(rect) && pointX < NSMaxX(rect) &&
        pointY >= NSMinY(rect) && pointY < NSMaxY(rect);
}

// The text body and its active decorations are ordinary Metal commands in a
// node's resolved clip chain. They do not identify a predictable colour from
// the public scene scalar, so they must make the generic opaque probe decline
// that texel. This is intentionally a bounds-only rejection: the exact glyph
// alpha belongs to the immutable native texture and is verified through the
// explicit testing readback path rather than guessed here.
static BOOL CjguiComposableTextPresentationMayAffectVisiblePoint(CJGuiInternalComposableSceneNode *node,
                                                                 CGFloat pointX, CGFloat pointY,
                                                                 NSSize viewSize) {
    if (!CjguiComposableNodeContainsVisiblePoint(node, pointX, pointY, viewSize)) return NO;
    if (node.textTexture && CjguiComposableRectContainsPoint(node.textTextureRect, pointX, pointY)) return YES;
    for (NSValue *valueRect in node.textSelectionRects) {
        if (CjguiComposableRectContainsPoint(valueRect.rectValue, pointX, pointY)) return YES;
    }
    for (NSValue *valueRect in node.textMarkedRects) {
        if (CjguiComposableRectContainsPoint(valueRect.rectValue, pointX, pointY)) return YES;
    }
    return CjguiComposableRectContainsPoint(node.textCaretRect, pointX, pointY);
}

static BOOL CjguiComposableBorderMayAffectVisiblePoint(CjguiInternalRendererComposableNode value,
                                                        CGFloat pointX, CGFloat pointY) {
    if (value.borderWidth == 0 || value.borderAlpha <= 0.0) return NO;
    int64_t border = MIN((int64_t)value.borderWidth, MIN(value.width / 2, value.height / 2));
    return pointX < (CGFloat)value.x + border || pointX >= (CGFloat)value.x + value.width - border ||
        pointY < (CGFloat)value.y + border || pointY >= (CGFloat)value.y + value.height - border;
}

static BOOL CjguiComposableNodeMayAffectVisiblePoint(CJGuiInternalComposableSceneNode *node,
                                                      CGFloat pointX, CGFloat pointY, NSSize viewSize) {
    if (!CjguiComposableNodeContainsVisiblePoint(node, pointX, pointY, viewSize)) return NO;
    CjguiInternalRendererComposableNode value = node.node;
    if (value.fillAlpha > 0.0 ||
        (value.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE && node.imageTexture)) return YES;
    if (CjguiComposableTextPresentationMayAffectVisiblePoint(node, pointX, pointY, viewSize)) return YES;
    return CjguiComposableBorderMayAffectVisiblePoint(value, pointX, pointY);
}

static BOOL CjguiComposableSceneHasPotentialMetalDraw(NSArray<CJGuiInternalComposableSceneNode *> *nodes) {
    for (CJGuiInternalComposableSceneNode *node in nodes) {
        CjguiInternalRendererComposableNode value = node.node;
        if (value.width <= 0 || value.height <= 0 || value.clipWidth <= 0 || value.clipHeight <= 0) continue;
        if (value.fillAlpha > 0.0 || (value.borderWidth > 0 && value.borderAlpha > 0.0) ||
            (value.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE && node.imageTexture) ||
            (node.textTexture && !NSIsEmptyRect(node.textTextureRect)) ||
            node.textSelectionRects.count > 0 || node.textMarkedRects.count > 0 ||
            !NSIsEmptyRect(node.textCaretRect)) return YES;
    }
    return NO;
}

static BOOL CjguiComposableReadbackProbePointForNode(CjguiInternalRendererComposableNode value,
                                                      NSSize viewSize, CGSize drawableSize,
                                                      CjguiComposableReadbackProbePoint *outPoint) {
    if (!outPoint || viewSize.width <= 0.0 || viewSize.height <= 0.0 ||
        drawableSize.width < 1.0 || drawableSize.height < 1.0) return NO;
    CGFloat scaleX = drawableSize.width / viewSize.width;
    CGFloat scaleY = drawableSize.height / viewSize.height;
    if (!isfinite(scaleX) || !isfinite(scaleY) || scaleX <= 0.0 || scaleY <= 0.0) return NO;
    CGFloat centreX = (CGFloat)value.x + (CGFloat)value.width / 2.0;
    CGFloat centreY = (CGFloat)value.y + (CGFloat)value.height / 2.0;
    NSInteger pixelX = (NSInteger)floor(centreX * scaleX);
    NSInteger pixelY = (NSInteger)floor(centreY * scaleY);
    if (pixelX < 0 || pixelY < 0 || pixelX >= (NSInteger)drawableSize.width || pixelY >= (NSInteger)drawableSize.height) return NO;
    outPoint->sampleX = (NSUInteger)pixelX;
    outPoint->sampleY = (NSUInteger)pixelY;
    outPoint->logicalX = ((CGFloat)pixelX + 0.5) / scaleX;
    outPoint->logicalY = ((CGFloat)pixelY + 0.5) / scaleY;
    return isfinite(outPoint->logicalX) && isfinite(outPoint->logicalY);
}

static CJGuiInternalComposableSceneNode *CjguiComposableSafeOpaqueProbeNode(
    NSArray<CJGuiInternalComposableSceneNode *> *nodes, NSSize viewSize, CGSize drawableSize,
    CjguiComposableReadbackProbePoint *outPoint) {
    // Walk from the top of z order. A later transparent/image/border draw can
    // still change a lower opaque centre, so reject that lower candidate
    // rather than reporting a false colour mismatch.
    for (NSInteger candidateIndex = (NSInteger)nodes.count - 1; candidateIndex >= 0; candidateIndex--) {
        CJGuiInternalComposableSceneNode *candidate = nodes[(NSUInteger)candidateIndex];
        CjguiInternalRendererComposableNode value = candidate.node;
        // An image node first paints its declared fill and then samples an
        // arbitrary (possibly transparent) texture. Its centre is therefore
        // never a generic colour oracle even when the fill itself is opaque.
        if (value.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE ||
            value.fillAlpha < 1.0 || value.width <= 0 || value.height <= 0) continue;
        CjguiComposableReadbackProbePoint point = {0};
        if (!CjguiComposableReadbackProbePointForNode(value, viewSize, drawableSize, &point) ||
            !CjguiComposableNodeContainsVisiblePoint(candidate, point.logicalX, point.logicalY, viewSize) ||
            CjguiComposableTextPresentationMayAffectVisiblePoint(candidate, point.logicalX, point.logicalY, viewSize) ||
            CjguiComposableBorderMayAffectVisiblePoint(value, point.logicalX, point.logicalY)) continue;
        BOOL covered = NO;
        for (NSUInteger upperIndex = (NSUInteger)candidateIndex + 1; upperIndex < nodes.count; upperIndex++) {
            if (CjguiComposableNodeMayAffectVisiblePoint(nodes[upperIndex], point.logicalX, point.logicalY, viewSize)) {
                covered = YES;
                break;
            }
        }
        if (!covered) {
            *outPoint = point;
            return candidate;
        }
    }
    return nil;
}

// A staged replacement must never mutate the live input/overlay snapshot.
// COW callers retain an immutable current node until a Cangjie setter changes
// that index, at which point this copies native-owned scalar/string/texture
// references into one staged node. The texture remains a normal strong
// Objective-C reference and no native handle crosses the ABI.
static CJGuiInternalComposableSceneNode *CjguiCloneComposableSceneNode(
    CJGuiInternalSession *session, CJGuiInternalComposableSceneNode *source, uint32_t index, uint64_t projectionVersion) {
    if (!source) return nil;
    CJGuiInternalComposableSceneNode *copy = [[CJGuiInternalComposableSceneNode alloc] init];
    if (!copy) return nil;
    CjguiInternalRendererComposableNode copiedValue = source.node;
    copiedValue.projectionVersion = projectionVersion;
    copy.node = copiedValue;
    copy.index = index;
    copy.label = [source.label copy] ?: @"";
    copy.value = [source.value copy] ?: @"";
    copy.imageResourcePath = [source.imageResourcePath copy] ?: @"";
    copy.imageResourceId = [source.imageResourceId copy] ?: @"";
    copy.imageResourceVersion = source.imageResourceVersion;
    copy.imageTextureCacheKey = [source.imageTextureCacheKey copy] ?: @"";
    copy.imageTextureContentKey = [source.imageTextureContentKey copy] ?: @"";
    copy.imageTexture = source.imageTexture;
    copy.textTextureCacheKey = [source.textTextureCacheKey copy] ?: @"";
    copy.textTexture = source.textTexture;
    copy.textTextureByteCount = source.textTextureByteCount;
    copy.textTextureRect = source.textTextureRect;
    copy.textSelectionRects = [source.textSelectionRects copy] ?: @[];
    copy.textMarkedRects = [source.textMarkedRects copy] ?: @[];
    copy.textCaretRect = source.textCaretRect;
#ifdef CJGUI_INTERNAL_TESTING
    if (session) {
        if (session.testComposableSceneCloneCount < UINT64_MAX) session.testComposableSceneCloneCount += 1;
        if (session.testComposableSceneNodeAllocationCount < UINT64_MAX) session.testComposableSceneNodeAllocationCount += 1;
    }
#endif
    return copy;
}

static uint64_t CjguiComposableNodeIdAtIndex(CJGuiInternalSession *session, uint32_t nodeIndex) {
    if (!session || nodeIndex >= session.composableNodes.count) return 0;
    return session.composableNodes[nodeIndex].node.nodeId;
}

static int64_t CjguiComposableNodeResourceIdAtIndex(CJGuiInternalSession *session, uint32_t nodeIndex) {
    if (!session || nodeIndex >= session.composableNodes.count) return -1;
    return session.composableNodes[nodeIndex].node.resourceId;
}

static uint32_t CjguiComposableNodeKindAtIndex(CJGuiInternalSession *session, uint32_t nodeIndex) {
    if (!session || nodeIndex >= session.composableNodes.count) return 0;
    return session.composableNodes[nodeIndex].node.nodeKind;
}

static NSFont *CjguiComposableFont(CJGuiInternalComposableSceneNode *node);

static uint32_t CjguiComposableClipConstraintCount(CjguiInternalRendererComposableNode value) {
    if (value.clipConstraintCount > 0 &&
        value.clipConstraintCount <= CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY) return value.clipConstraintCount;
    return 1;
}

static void CjguiComposableClipConstraintAt(CjguiInternalRendererComposableNode value, uint32_t index,
                                             CGFloat *x, CGFloat *y, CGFloat *width, CGFloat *height, CGFloat *radius) {
    if (value.clipConstraintCount == 0 || value.clipConstraintCount > CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY) {
        *x = value.clipX; *y = value.clipY; *width = value.clipWidth; *height = value.clipHeight;
        *radius = value.clipCornerRadius;
        return;
    }
    switch (index) {
        case 0: *x = value.clip0X; *y = value.clip0Y; *width = value.clip0Width; *height = value.clip0Height; *radius = value.clip0CornerRadius; break;
        case 1: *x = value.clip1X; *y = value.clip1Y; *width = value.clip1Width; *height = value.clip1Height; *radius = value.clip1CornerRadius; break;
        case 2: *x = value.clip2X; *y = value.clip2Y; *width = value.clip2Width; *height = value.clip2Height; *radius = value.clip2CornerRadius; break;
        default: *x = value.clip3X; *y = value.clip3Y; *width = value.clip3Width; *height = value.clip3Height; *radius = value.clip3CornerRadius; break;
    }
}

static void CjguiPopulateMetalClipChain(vector_float4 clips[CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY],
                                        vector_float4 *radii, vector_float4 *count,
                                        CjguiInternalRendererComposableNode value) {
    uint32_t clipCount = CjguiComposableClipConstraintCount(value);
    *radii = (vector_float4){ 0, 0, 0, 0 };
    *count = (vector_float4){ (float)clipCount, 0, 0, 0 };
    for (uint32_t i = 0; i < CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY; i++) {
        CGFloat x = 0, y = 0, width = 0, height = 0, radius = 0;
        if (i < clipCount) CjguiComposableClipConstraintAt(value, i, &x, &y, &width, &height, &radius);
        clips[i] = (vector_float4){ (float)x, (float)y, (float)MAX(0.0, width), (float)MAX(0.0, height) };
        if (i < clipCount) (*radii)[i] = (float)MIN(MAX(0.0, radius), MIN(MAX(0.0, width), MAX(0.0, height)) / 2.0);
    }
}

static void CjguiAppendMetalShape(NSMutableData *batch, CGFloat pointWidth, CGFloat pointHeight,
                                  CjguiInternalRendererComposableNode value, vector_float4 fill, vector_float4 border) {
    CGFloat x = value.x, y = value.y, width = value.width, height = value.height;
    if (!batch || width <= 0.0 || height <= 0.0 || (fill.w <= 0.0 && border.w <= 0.0)) return;
    float left = -1.0f + (float)(2.0 * x / pointWidth);
    float right = -1.0f + (float)(2.0 * (x + width) / pointWidth);
    float top = 1.0f - (float)(2.0 * y / pointHeight);
    float bottom = 1.0f - (float)(2.0 * (y + height) / pointHeight);
    float radius = (float)MIN(MAX(0.0, value.cornerRadius), MIN(width, height) / 2.0);
    float stroke = (float)MIN(MAX(0.0, (CGFloat)value.borderWidth), MIN(width, height) / 2.0);
    CJGuiInternalMetalVertex vertices[6] = {0};
    vector_float2 positions[6] = { { left, top }, { right, top }, { left, bottom }, { right, top }, { right, bottom }, { left, bottom } };
    vector_float2 scenePoints[6] = { { (float)x, (float)y }, { (float)(x + width), (float)y }, { (float)x, (float)(y + height) }, { (float)(x + width), (float)y }, { (float)(x + width), (float)(y + height) }, { (float)x, (float)(y + height) } };
    vector_float2 localPoints[6] = { { 0, 0 }, { (float)width, 0 }, { 0, (float)height }, { (float)width, 0 }, { (float)width, (float)height }, { 0, (float)height } };
    for (uint32_t i = 0; i < 6; i++) {
        vertices[i].position = positions[i]; vertices[i].scenePoint = scenePoints[i]; vertices[i].localPoint = localPoints[i];
        vertices[i].size = (vector_float2){ (float)width, (float)height };
        CjguiPopulateMetalClipChain(vertices[i].clips, &vertices[i].clipRadii, &vertices[i].clipCount, value);
        vertices[i].cornerRadius = radius; vertices[i].borderWidth = stroke; vertices[i].fill = fill; vertices[i].border = border;
    }
    [batch appendBytes:vertices length:sizeof(vertices)];
}

// Decorations are regular scene rectangles with the text node's resolved
// clip chain. They deliberately do not become public nodes or textures:
// their sole owner is the active native input projection.
static void CjguiAppendMetalTextDecoration(NSMutableData *batch, CGFloat pointWidth, CGFloat pointHeight,
                                           CjguiInternalRendererComposableNode owner, NSRect rect,
                                           vector_float4 fill) {
    if (NSIsEmptyRect(rect) || fill.w <= 0.0) return;
    CjguiInternalRendererComposableNode decoration = owner;
    decoration.x = (int64_t)floor(NSMinX(rect));
    decoration.y = (int64_t)floor(NSMinY(rect));
    decoration.width = (int64_t)ceil(NSWidth(rect));
    decoration.height = (int64_t)ceil(NSHeight(rect));
    decoration.cornerRadius = 0.0;
    decoration.borderWidth = 0.0;
    decoration.fillAlpha = fill.w;
    decoration.borderAlpha = 0.0;
    CjguiAppendMetalShape(batch, pointWidth, pointHeight, decoration, fill, (vector_float4){ 0, 0, 0, 0 });
}

static vector_float4 CjguiMetalColorFromNSColor(NSColor *color) {
    NSColor *srgb = [color colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    if (!srgb) return (vector_float4){ 0, 0, 0, 0 };
    return (vector_float4){ (float)srgb.redComponent, (float)srgb.greenComponent,
                             (float)srgb.blueComponent, (float)srgb.alphaComponent };
}

static BOOL CjguiEnsureComposableImagePipeline(CJGuiInternalMetalView *metalView) {
    if (metalView.composableImagePipeline) return YES;
    NSError *error = nil;
    NSString *source = @"#include <metal_stdlib>\nusing namespace metal;\n"
        "struct Vertex { float2 position; float2 texCoord; float2 scenePoint; float4 clips[4]; float4 clipRadii; float4 clipCount; float4 nodeRect; float nodeCornerRadius; };\n"
        "struct Out { float4 position [[position]]; float2 texCoord; float2 point; float4 clip0; float4 clip1; float4 clip2; float4 clip3; float4 clipRadii; float4 clipCount; float4 nodeRect; float nodeCornerRadius; };\n"
        "float roundedDistance(float2 point, float2 origin, float2 size, float radius) { float r=min(max(radius,0.0),min(size.x,size.y)*0.5); float2 q=abs((point-origin)-size*0.5)-(size*0.5-r); return length(max(q,float2(0.0)))+min(max(q.x,q.y),0.0)-r; }\n"
        "vertex Out cjgui_image_vertex(uint i [[vertex_id]], const device Vertex *v [[buffer(0)]]) { Out o; o.position=float4(v[i].position,0,1); o.texCoord=v[i].texCoord; o.point=v[i].scenePoint; o.clip0=v[i].clips[0]; o.clip1=v[i].clips[1]; o.clip2=v[i].clips[2]; o.clip3=v[i].clips[3]; o.clipRadii=v[i].clipRadii; o.clipCount=v[i].clipCount; o.nodeRect=v[i].nodeRect; o.nodeCornerRadius=v[i].nodeCornerRadius; return o; }\n"
        "fragment float4 cjgui_image_fragment(Out in [[stage_in]], texture2d<float> image [[texture(0)]]) { for(uint j=0;j<uint(in.clipCount.x);j++) { float4 clip=j==0?in.clip0:(j==1?in.clip1:(j==2?in.clip2:in.clip3)); if (roundedDistance(in.point,clip.xy,clip.zw,in.clipRadii[j])>0.0) discard_fragment(); } if (roundedDistance(in.point,in.nodeRect.xy,in.nodeRect.zw,in.nodeCornerRadius)>0.0) discard_fragment(); constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear); return image.sample(s, in.texCoord); }\n";
    id<MTLLibrary> library = [metalView.device newLibraryWithSource:source options:nil error:&error];
    if (!library) { NSLog(@"cjgui: composable image metal library failed %@", error); return NO; }
    MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    descriptor.vertexFunction = [library newFunctionWithName:@"cjgui_image_vertex"];
    descriptor.fragmentFunction = [library newFunctionWithName:@"cjgui_image_fragment"];
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    descriptor.colorAttachments[0].blendingEnabled = YES;
    descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    metalView.composableImagePipeline = [metalView.device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (!metalView.composableImagePipeline) { NSLog(@"cjgui: composable image pipeline failed %@", error); return NO; }
    return YES;
}

static void CjguiEncodeMetalTexture(id<MTLRenderCommandEncoder> encoder, CGFloat pointWidth, CGFloat pointHeight,
                                    CGFloat x, CGFloat y, CGFloat width, CGFloat height, id<MTLTexture> texture,
                                    CjguiInternalRendererComposableNode value, BOOL appKitBitmapRows) {
    if (!texture || width <= 0.0 || height <= 0.0) return;
    float left = -1.0f + (float)(2.0 * x / pointWidth);
    float right = -1.0f + (float)(2.0 * (x + width) / pointWidth);
    float top = 1.0f - (float)(2.0 * y / pointHeight);
    float bottom = 1.0f - (float)(2.0 * (y + height) / pointHeight);
    CJGuiInternalMetalTextureVertex vertices[6] = {0};
    vector_float2 positions[6] = { { left, top }, { right, top }, { left, bottom }, { right, top }, { right, bottom }, { left, bottom } };
    // CGBitmapContext's first byte row is the opposite vertical origin from
    // the normalized rows consumed by this Metal texture sampler. AppKit text
    // is rasterized into that raw BGRA memory, while decoded image resources
    // already use Metal's expected row orientation. Keep the distinction at
    // the sole texture-encoding boundary so neither TextKit nor image loading
    // gains a second coordinate model.
    float textureTop = appKitBitmapRows ? 1.0f : 0.0f;
    float textureBottom = appKitBitmapRows ? 0.0f : 1.0f;
    vector_float2 texCoords[6] = { { 0, textureTop }, { 1, textureTop }, { 0, textureBottom },
                                   { 1, textureTop }, { 1, textureBottom }, { 0, textureBottom } };
    vector_float2 scenePoints[6] = { { (float)x, (float)y }, { (float)(x + width), (float)y }, { (float)x, (float)(y + height) }, { (float)(x + width), (float)y }, { (float)(x + width), (float)(y + height) }, { (float)x, (float)(y + height) } };
    for (uint32_t i = 0; i < 6; i++) {
        vertices[i].position = positions[i]; vertices[i].texCoord = texCoords[i]; vertices[i].scenePoint = scenePoints[i];
        CjguiPopulateMetalClipChain(vertices[i].clips, &vertices[i].clipRadii, &vertices[i].clipCount, value);
        vertices[i].nodeRect = (vector_float4){ (float)value.x, (float)value.y, (float)value.width, (float)value.height };
        vertices[i].nodeCornerRadius = (float)MIN(MAX(0.0, value.cornerRadius), MIN((CGFloat)value.width, (CGFloat)value.height) / 2.0);
    }
    [encoder setVertexBytes:vertices length:sizeof(vertices) atIndex:0];
    [encoder setFragmentTexture:texture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

static NSString *CjguiComposableGpuTextValueWithActiveValue(CJGuiInternalComposableSceneNode *node,
                                                             NSString *activeValue) {
    if (!node) return @"";
    NSString *value = activeValue ?: node.value ?: @"";
    return node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ||
        node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT ? value :
        (node.label.length > 0 ? [NSString stringWithFormat:@"%@ %@", node.label, value] : value);
}

static NSString *CjguiComposableGpuTextValue(CJGuiInternalComposableSceneNode *node) {
    return CjguiComposableGpuTextValueWithActiveValue(node, nil);
}

static BOOL CjguiComposableNodeUsesGpuText(uint32_t kind) {
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT;
}

// A text texture is only a projection of the pixels that can reach the
// drawable in this scene.  Keep its logical rectangle in scene coordinates:
// the encoder can then place the tile without changing TextKit/NSString
// layout coordinates, while the allocation is bounded by the resolved clip.
static NSRect CjguiComposableTextTextureRectForNode(CJGuiInternalComposableSceneNode *node) {
    if (!node) return NSZeroRect;
    CjguiInternalRendererComposableNode value = node.node;
    NSRect nodeRect = NSMakeRect((CGFloat)value.x, (CGFloat)value.y,
                                 MAX(0.0, (CGFloat)value.width), MAX(0.0, (CGFloat)value.height));
    NSRect clipRect = NSMakeRect((CGFloat)value.clipX, (CGFloat)value.clipY,
                                 MAX(0.0, (CGFloat)value.clipWidth), MAX(0.0, (CGFloat)value.clipHeight));
    return NSIntersectionRect(nodeRect, clipRect);
}

// The rectangular texture allocation is only a conservative intersection;
// its pixels are still rasterized through every rounded ancestor clip. Keep a
// canonical copy of that chain in each text-resource key so a radius-only
// projection update cannot reuse stale pixels from the same rectangle.
static NSString *CjguiComposableTextClipSignature(CJGuiInternalComposableSceneNode *node) {
    if (!node) return @"";
    CjguiInternalRendererComposableNode value = node.node;
    uint32_t count = CjguiComposableClipConstraintCount(value);
    NSMutableString *signature = [NSMutableString stringWithFormat:@"%u", count];
    for (uint32_t index = 0; index < count; index++) {
        CGFloat x = 0, y = 0, width = 0, height = 0, radius = 0;
        CjguiComposableClipConstraintAt(value, index, &x, &y, &width, &height, &radius);
        [signature appendFormat:@":%.3f:%.3f:%.3f:%.3f:%.3f", x, y, width, height, radius];
    }
    return signature;
}

static NSString *CjguiComposableTextTextureKey(CJGuiInternalComposableSceneNode *node, CGFloat scaleX, CGFloat scaleY,
                                               NSString *displayText, NSRect textureRect) {
    if (!node) return @"";
    CjguiInternalRendererComposableNode value = node.node;
    return [NSString stringWithFormat:@"%u:%lld:%lld:%0.3f:%0.3f:%0.3f:%u:%u:%0.4f:%0.4f:%0.4f:%0.4f:%0.3f:%0.3f:%0.3f:%0.3f:%0.3f:%0.3f:%@:%@",
            value.nodeKind, value.width, value.height,
            scaleX, scaleY, value.fontSize, value.fontWeight, value.fontFamily,
            value.textRed, value.textGreen, value.textBlue, value.textAlpha,
            NSMinX(textureRect), NSMinY(textureRect), NSWidth(textureRect), NSHeight(textureRect),
            NSMinX(textureRect) - (CGFloat)value.x, NSMinY(textureRect) - (CGFloat)value.y,
            displayText ?: @"", CjguiComposableTextClipSignature(node)];
}

static BOOL CjguiCheckedComposableTextTextureBytes(CGFloat logicalWidth, CGFloat logicalHeight,
                                                    CGFloat scaleX, CGFloat scaleY,
                                                    NSUInteger *outWidth, NSUInteger *outHeight,
                                                    NSUInteger *outBytesPerRow, uint64_t *outBytes) {
    if (!outWidth || !outHeight || !outBytesPerRow || !outBytes || logicalWidth <= 0.0 || logicalHeight <= 0.0 ||
        !isfinite(scaleX) || !isfinite(scaleY) || scaleX <= 0.0 || scaleY <= 0.0) return NO;
    CGFloat scaledWidth = ceil(logicalWidth * scaleX), scaledHeight = ceil(logicalHeight * scaleY);
    if (!isfinite(scaledWidth) || !isfinite(scaledHeight) || scaledWidth < 1.0 || scaledHeight < 1.0 ||
        scaledWidth > CjguiComposableTextTextureDimensionCapacity || scaledHeight > CjguiComposableTextTextureDimensionCapacity ||
        scaledWidth > (CGFloat)NSUIntegerMax || scaledHeight > (CGFloat)NSUIntegerMax) return NO;
    NSUInteger width = (NSUInteger)scaledWidth, height = (NSUInteger)scaledHeight;
    if (width > NSUIntegerMax / 4u) return NO;
    NSUInteger bytesPerRow = width * 4u;
    if (height > NSUIntegerMax / bytesPerRow) return NO;
    NSUInteger bytes = bytesPerRow * height;
    if (bytes > CjguiComposableTextTexturePerNodeByteCapacity) return NO;
    *outWidth = width; *outHeight = height; *outBytesPerRow = bytesPerRow; *outBytes = bytes;
    return YES;
}

static id<MTLTexture> CjguiRasterComposableTextTexture(CJGuiInternalMetalView *metalView,
                                                        CJGuiInternalComposableSceneNode *node,
                                                        CGFloat scaleX, CGFloat scaleY,
                                                        NSString *displayText,
                                                        NSRect textureRect,
                                                        uint64_t *outByteCount
#ifdef CJGUI_INTERNAL_TESTING
                                                        , CjguiInternalTextWorkReason reason
#endif
                                                        ) {
    if (outByteCount) *outByteCount = 0;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t rasterStarted = CjguiMonotonicMicros();
#endif
    if (!metalView.device || !node || node.node.width <= 0 || node.node.height <= 0) return nil;
    NSString *text = displayText ?: @"";
    if (text.length == 0 || node.node.textAlpha <= 0.0) return nil;
    NSUInteger width = 0, height = 0, bytesPerRow = 0;
    uint64_t byteCount = 0;
    if (NSIsEmptyRect(textureRect)) return nil;
    if (!CjguiCheckedComposableTextTextureBytes(NSWidth(textureRect), NSHeight(textureRect),
                                                scaleX, scaleY, &width, &height, &bytesPerRow, &byteCount)) return nil;
    // The AppKit bitmap and Metal upload share one bounded BGRA allocation.
    // Normalize premultiplied components in place before upload instead of
    // retaining a second full-sized conversion buffer.
    NSMutableData *bgra = [NSMutableData dataWithLength:(NSUInteger)byteCount];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef bitmapContext = colorSpace ? CGBitmapContextCreate(bgra.mutableBytes, width, height, 8, bytesPerRow,
        colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little) : NULL;
    if (colorSpace) CGColorSpaceRelease(colorSpace);
    NSGraphicsContext *context = bitmapContext ? [NSGraphicsContext graphicsContextWithCGContext:bitmapContext flipped:YES] : nil;
    if (!bgra || !bitmapContext || !context) { if (bitmapContext) CGContextRelease(bitmapContext); return nil; }
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT
        ? NSLineBreakByCharWrapping : (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT
            ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail);
    NSColor *textColor = [NSColor colorWithSRGBRed:node.node.textRed green:node.node.textGreen
                                               blue:node.node.textBlue alpha:node.node.textAlpha];
    NSFont *baseFont = CjguiComposableFont(node);
    NSDictionary *attributes = @{ NSFontAttributeName: baseFont,
                                  NSForegroundColorAttributeName: textColor,
                                  NSParagraphStyleAttributeName: paragraph };
    NSGraphicsContext *previousContext = NSGraphicsContext.currentContext;
    [NSGraphicsContext setCurrentContext:context];
    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform scaleXBy:scaleX yBy:scaleY];
    // Keep the original node-local layout width.  Only the backing bitmap is
    // translated to the resolved visible tile, so line wrapping and selection
    // geometry do not reflow when an ancestor clip moves.
    [transform translateXBy:(NSMinX(textureRect) - (CGFloat)node.node.x) * -1.0
                       yBy:(NSMinY(textureRect) - (CGFloat)node.node.y) * -1.0];
    [transform concat];
    NSRect bounds = NSMakeRect(0.0, 0.0, (CGFloat)node.node.width, (CGFloat)node.node.height);
    CGFloat verticalInset = node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ? 2.0 : 6.0;
    NSRect textRect = NSInsetRect(bounds, 7.0, verticalInset);
    [text drawWithRect:textRect
               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
            attributes:attributes];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext setCurrentContext:previousContext];

    uint8_t *pixels = bgra.mutableBytes;
    for (NSUInteger y = 0; y < height; y++) {
        uint8_t *row = pixels + y * bytesPerRow;
        for (NSUInteger x = 0; x < width; x++) {
            uint8_t *pixel = row + x * 4;
            uint8_t alpha = pixel[3];
            // AppKit's drawable bitmap is premultiplied RGBA. The shared
            // texture pipeline consumes ordinary RGBA texels, so normalize
            // it before channel-order conversion rather than blending twice.
            pixel[0] = alpha == 0 ? 0 : (uint8_t)MIN(255, (pixel[0] * 255 + alpha / 2) / alpha);
            pixel[1] = alpha == 0 ? 0 : (uint8_t)MIN(255, (pixel[1] * 255 + alpha / 2) / alpha);
            pixel[2] = alpha == 0 ? 0 : (uint8_t)MIN(255, (pixel[2] * 255 + alpha / 2) / alpha);
        }
    }
    CGContextRelease(bitmapContext);
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                            width:width height:height mipmapped:NO];
    descriptor.usage = MTLTextureUsageShaderRead;
    descriptor.storageMode = MTLStorageModeShared;
    id<MTLTexture> texture = [metalView.device newTextureWithDescriptor:descriptor];
    if (!texture) return nil;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t uploadStarted = CjguiMonotonicMicros();
    CjguiRecordTextWork(metalView, node.node.projectionVersion,
                        [displayText lengthOfBytesUsingEncoding:NSUTF8StringEncoding], reason);
    metalView.testComposableTextRasterCount = CjguiSaturatingAddU64(metalView.testComposableTextRasterCount, 1);
    metalView.testComposableTextRasterBytes = CjguiSaturatingAddU64(metalView.testComposableTextRasterBytes, byteCount);
    metalView.testComposableTextRasterMicros = CjguiSaturatingAddU64(metalView.testComposableTextRasterMicros,
                                                                       uploadStarted - rasterStarted);
#endif
    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:bgra.bytes bytesPerRow:bytesPerRow];
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t uploadEnded = CjguiMonotonicMicros();
    metalView.testComposableTextUploadCount = CjguiSaturatingAddU64(metalView.testComposableTextUploadCount, 1);
    metalView.testComposableTextUploadBytes = CjguiSaturatingAddU64(metalView.testComposableTextUploadBytes, byteCount);
    metalView.testComposableTextUploadMicros = CjguiSaturatingAddU64(metalView.testComposableTextUploadMicros,
                                                                       uploadEnded - uploadStarted);
#endif
    if (outByteCount) *outByteCount = byteCount;
    return texture;
}

static id<MTLTexture> CjguiComposableTextTexture(CJGuiInternalMetalView *metalView,
                                                  CJGuiInternalComposableSceneNode *node,
                                                  CGFloat scaleX, CGFloat scaleY,
                                                  NSString *displayText
#ifdef CJGUI_INTERNAL_TESTING
                                                  , CjguiInternalTextWorkReason reason
#endif
                                                  ) {
    NSRect textureRect = CjguiComposableTextTextureRectForNode(node);
    if (NSIsEmptyRect(textureRect)) return nil;
    NSString *key = CjguiComposableTextTextureKey(node, scaleX, scaleY, displayText, textureRect);
    if (key.length == 0) return nil;
    if (node.textTexture && [node.textTextureCacheKey isEqualToString:key]) return node.textTexture;
    uint64_t byteCount = 0;
    id<MTLTexture> texture = CjguiRasterComposableTextTexture(metalView, node, scaleX, scaleY, displayText,
                                                               textureRect, &byteCount
#ifdef CJGUI_INTERNAL_TESTING
                                                               , reason
#endif
                                                               );
    if (!texture) return nil;
    node.textTexture = texture; node.textTextureByteCount = byteCount; node.textTextureCacheKey = key;
    node.textTextureRect = textureRect;
    return texture;
}

// An owner acknowledgement for the still-focused, same-identity input is not
// a new visual candidate.  The Cangjie bridge deliberately omits its value so
// setNodesFromProjection can retain the already accepted NSTextView value;
// replacing the retained active texture here would rasterize and upload that
// exact text/caret state again immediately afterwards.  Keep the existing
// scene-owned resource through this narrow hand-off. Any identity, kind,
// style, scale, tile, external-value, or retry difference still reaches
// refreshGpuTextForActiveInput and gets its normal body-cache-key check;
// selection, marked ranges and the caret are direct scene geometry.
static BOOL CjguiComposableTextResourceAcknowledgesActiveLocalInput(
    CJGuiInternalComposableSceneNode *node, CJGuiInternalComposableSceneNode *live) {
    if (!node || !live || node.node.preservesActiveLocalText == 0) return NO;
    // `preservesActiveLocalText` is the one-shot transport hint, while an
    // empty staged value is its concrete Cangjie-to-NSString hand-off form.
    // A non-empty value remains a visual candidate (including geometry or
    // tile changes in native scene probes) and must prepare normally.
    if (node.value.length != 0) return NO;
    uint32_t kind = node.node.nodeKind;
    if (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
        kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
        kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) return NO;
    return node.node.nodeId == live.node.nodeId &&
        node.node.resourceId == live.node.resourceId && kind == live.node.nodeKind;
}

static BOOL CjguiPrepareComposableTextResources(CJGuiInternalSession *ctx) {
    if (!ctx || !ctx.view) return NO;
    CJGuiInternalMetalView *metalView = ctx.view;
    CGFloat scale = metalView.window ? metalView.window.backingScaleFactor : NSScreen.mainScreen.backingScaleFactor;
    scale = MAX(1.0, scale);
    uint64_t sceneBytes = 0;
    for (NSUInteger index = 0; index < ctx.stagedComposableNodes.count; index++) {
        CJGuiInternalComposableSceneNode *node = ctx.stagedComposableNodes[index];
        CJGuiInternalComposableSceneNode *live = index < ctx.composableNodes.count ? ctx.composableNodes[index] : nil;
        if (CjguiComposableTextResourceAcknowledgesActiveLocalInput(node, live)) {
            // The staged COW node already retains the last active resource.
            // Count it like every other scene-owned texture so this reuse
            // cannot evade the accepted-scene resource cap.
            uint64_t retainedBytes = node.textTextureByteCount;
            if (retainedBytes > 0) {
                if (retainedBytes > CjguiComposableTextTextureByteCapacity ||
                    sceneBytes > CjguiComposableTextTextureByteCapacity - retainedBytes) return NO;
                sceneBytes += retainedBytes;
            }
            continue;
        }
        // Decorations are meaningful only while the native TextKit proxy is
        // focused. A sparse staged candidate can still share an accepted
        // active-input node. Copy it before clearing presentation geometry so
        // a failed candidate cannot mutate the accepted selection/caret.
        BOOL hasDecorations = node.textSelectionRects.count > 0 ||
            node.textMarkedRects.count > 0 || !NSIsEmptyRect(node.textCaretRect);
        if (node == live && hasDecorations) {
            node = CjguiCloneComposableSceneNode(ctx, live, (uint32_t)index,
                                                  ctx.stagedComposableSceneVersion);
            if (!node) return NO;
            ctx.stagedComposableNodes[index] = node;
        }
        CjguiClearComposableTextDecorations(node);
        BOOL shouldClear = NO;
        if (!CjguiComposableNodeUsesGpuText(node.node.nodeKind)) {
            shouldClear = YES;
        } else if (NSIsEmptyRect(CjguiComposableTextTextureRectForNode(node))) {
            // A fully clipped node cannot contribute pixels this turn. Its
            // immutable Cangjie value remains available for a later retry.
            shouldClear = YES;
        }
        NSString *text = shouldClear ? @"" : CjguiComposableGpuTextValue(node);
        if (text.length == 0 || node.node.textAlpha <= 0.0) shouldClear = YES;
        if (shouldClear) {
            if (node.textTexture || node.textTextureCacheKey.length > 0 || node.textTextureByteCount > 0) {
                if (node == live) {
                    node = CjguiCloneComposableSceneNode(ctx, live, (uint32_t)index, ctx.stagedComposableSceneVersion);
                    if (!node) return NO;
                    ctx.stagedComposableNodes[index] = node;
                }
                node.textTexture = nil; node.textTextureCacheKey = @""; node.textTextureByteCount = 0;
                node.textTextureRect = NSZeroRect;
            }
            continue;
        }
        NSRect textureRect = CjguiComposableTextTextureRectForNode(node);
        NSString *key = CjguiComposableTextTextureKey(node, scale, scale, text, textureRect);
        BOOL needsPreparation = !node.textTexture || ![node.textTextureCacheKey isEqualToString:key];
        uint64_t nodeBytes = node.textTextureByteCount;
        if (needsPreparation) {
            NSUInteger width = 0, height = 0, bytesPerRow = 0;
            if (!CjguiCheckedComposableTextTextureBytes(NSWidth(textureRect), NSHeight(textureRect),
                                                        scale, scale, &width, &height, &bytesPerRow, &nodeBytes)) return NO;
        }
        if (nodeBytes == 0 || sceneBytes > CjguiComposableTextTextureByteCapacity - nodeBytes) return NO;
        sceneBytes += nodeBytes;
        if (!needsPreparation) continue;
        if (node == live) {
            node = CjguiCloneComposableSceneNode(ctx, live, (uint32_t)index, ctx.stagedComposableSceneVersion);
            if (!node) return NO;
            ctx.stagedComposableNodes[index] = node;
        }
#ifdef CJGUI_INTERNAL_TESTING
        if (ctx.forcedComposableTextPreparationFailures > 0) {
            ctx.forcedComposableTextPreparationFailures -= 1;
            return NO;
        }
#endif
        if (!CjguiComposableTextTexture(metalView, node, scale, scale, text
#ifdef CJGUI_INTERNAL_TESTING
                                        , CjguiInternalTextWorkReasonStaticCandidate
#endif
                                        )) return NO;
    }
    return YES;
}

// Active TextKit updates bypass a Cangjie scene transaction, but they still
// replace a scene-owned derived texture. Apply the same accepted-scene budget
// before swapping it so a focused field cannot evade the admission limit.
static BOOL CjguiComposableTextTextureFitsSceneBudget(NSArray<CJGuiInternalComposableSceneNode *> *nodes,
                                                       CJGuiInternalComposableSceneNode *replacing,
                                                       uint64_t candidateBytes) {
    if (candidateBytes == 0 || candidateBytes > CjguiComposableTextTextureByteCapacity) return NO;
    uint64_t total = candidateBytes;
    for (CJGuiInternalComposableSceneNode *node in nodes) {
        if (node == replacing || !CjguiComposableNodeUsesGpuText(node.node.nodeKind)) continue;
        uint64_t bytes = node.textTextureByteCount;
        if (bytes > CjguiComposableTextTextureByteCapacity - total) return NO;
        total += bytes;
    }
    return total <= CjguiComposableTextTextureByteCapacity;
}

static BOOL CjguiEncodeComposableNodes(id view, id<MTLRenderCommandEncoder> encoder, CGSize drawableSize) {
    CJGuiInternalMetalView *metalView = (CJGuiInternalMetalView *)view;
    if (metalView.composableNodes.count == 0) return YES;
#ifdef CJGUI_INTERNAL_TESTING
    metalView.testComposableShapeNodeCount = 0;
    metalView.testComposableShapeBatchCount = 0;
    metalView.testComposableTextureDrawCount = 0;
    metalView.testComposableShapeVertexBytes = 0;
    metalView.testComposableMaxShapeBatchVertexBytes = 0;
    metalView.testComposableShapeVertexStride = (uint32_t)sizeof(CJGuiInternalMetalVertex);
#endif
    if (!metalView.composablePipeline) {
        NSError *error = nil;
        NSString *source = @"#include <metal_stdlib>\nusing namespace metal;\n"
            "struct Vertex { float2 position; float2 scenePoint; float2 localPoint; float2 size; float4 clips[4]; float4 clipRadii; float4 clipCount; float cornerRadius; float borderWidth; float4 fill; float4 border; };\n"
            "struct Out { float4 position [[position]]; float2 scenePoint; float2 localPoint; float2 size; float4 clip0; float4 clip1; float4 clip2; float4 clip3; float4 clipRadii; float4 clipCount; float cornerRadius; float borderWidth; float4 fill; float4 border; };\n"
            "float roundedDistance(float2 point, float2 origin, float2 size, float radius) { float r=min(max(radius,0.0),min(size.x,size.y)*0.5); float2 q=abs((point-origin)-size*0.5)-(size*0.5-r); return length(max(q,float2(0.0)))+min(max(q.x,q.y),0.0)-r; }\n"
            "vertex Out cjgui_scene_vertex(uint i [[vertex_id]], const device Vertex *v [[buffer(0)]]) { Out o; o.position=float4(v[i].position,0,1); o.scenePoint=v[i].scenePoint; o.localPoint=v[i].localPoint; o.size=v[i].size; o.clip0=v[i].clips[0]; o.clip1=v[i].clips[1]; o.clip2=v[i].clips[2]; o.clip3=v[i].clips[3]; o.clipRadii=v[i].clipRadii; o.clipCount=v[i].clipCount; o.cornerRadius=v[i].cornerRadius; o.borderWidth=v[i].borderWidth; o.fill=v[i].fill; o.border=v[i].border; return o; }\n"
            "fragment float4 cjgui_scene_fragment(Out in [[stage_in]]) { for(uint j=0;j<uint(in.clipCount.x);j++) { float4 clip=j==0?in.clip0:(j==1?in.clip1:(j==2?in.clip2:in.clip3)); if (roundedDistance(in.scenePoint,clip.xy,clip.zw,in.clipRadii[j])>0.0) discard_fragment(); } float outer=roundedDistance(in.localPoint,float2(0.0),in.size,in.cornerRadius); if (outer>0.0) discard_fragment(); if (in.borderWidth>0.0 && in.border.a>0.0) { float2 innerSize=max(in.size-float2(in.borderWidth*2.0),float2(0.0)); float innerRadius=max(0.0,in.cornerRadius-in.borderWidth); float inner=roundedDistance(in.localPoint-float2(in.borderWidth),float2(0.0),innerSize,innerRadius); if (inner>0.0) return in.border; } return in.fill; }\n";
        id<MTLLibrary> library = [metalView.device newLibraryWithSource:source options:nil error:&error];
        if (!library) { NSLog(@"cjgui: composable metal library failed %@", error); return NO; }
        MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = [library newFunctionWithName:@"cjgui_scene_vertex"];
        descriptor.fragmentFunction = [library newFunctionWithName:@"cjgui_scene_fragment"];
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        // Scene rectangles carry ordinary, non-premultiplied RGBA values from
        // the public Cangjie style.  They must compose in painter order just
        // like image texels, rather than overwriting the drawable with their
        // raw source alpha.
        descriptor.colorAttachments[0].blendingEnabled = YES;
        descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        metalView.composablePipeline = [metalView.device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        if (!metalView.composablePipeline) { NSLog(@"cjgui: composable metal pipeline failed %@", error); return NO; }
    }
    CGFloat pointWidth = MAX(1.0, metalView.bounds.size.width);
    CGFloat pointHeight = MAX(1.0, metalView.bounds.size.height);
    CGFloat scaleX = drawableSize.width / pointWidth;
    CGFloat scaleY = drawableSize.height / pointHeight;
    [encoder setRenderPipelineState:metalView.composablePipeline];
    // Consecutive shape commands share one pipeline and vertex submission.
    // Texture nodes are explicit painter-order boundaries; we flush before
    // them rather than globally sorting by resource or alpha.
    NSMutableData *shapeBatch = [NSMutableData data];
    const NSUInteger maxShapeVerticesPerUpload =
        ((NSUInteger)CJGUI_INTERNAL_METAL_SET_VERTEX_BYTES_CAPACITY / sizeof(CJGuiInternalMetalVertex) /
         CJGUI_INTERNAL_COMPOSABLE_SHAPE_VERTICES_PER_NODE) * CJGUI_INTERNAL_COMPOSABLE_SHAPE_VERTICES_PER_NODE;
    if (maxShapeVerticesPerUpload < CJGUI_INTERNAL_COMPOSABLE_SHAPE_VERTICES_PER_NODE) {
        NSLog(@"cjgui: composable shape vertex exceeds Metal setVertexBytes capacity");
        return NO;
    }
    BOOL (^flushShapeBatch)(void) = ^BOOL {
        if (shapeBatch.length == 0) return YES;
        const uint8_t *batchBytes = shapeBatch.bytes;
        NSUInteger remainingVertices = shapeBatch.length / sizeof(CJGuiInternalMetalVertex);
        NSUInteger vertexOffset = 0;
        while (remainingVertices > 0) {
            NSUInteger vertexCount = MIN(maxShapeVerticesPerUpload, remainingVertices);
            NSUInteger byteCount = vertexCount * sizeof(CJGuiInternalMetalVertex);
#ifdef CJGUI_INTERNAL_TESTING
            if (metalView.testComposableShapeBatchCount < UINT32_MAX) metalView.testComposableShapeBatchCount += 1;
            uint64_t bytes = byteCount;
            metalView.testComposableShapeVertexBytes = bytes > UINT64_MAX - metalView.testComposableShapeVertexBytes
                ? UINT64_MAX : metalView.testComposableShapeVertexBytes + bytes;
            metalView.testComposableMaxShapeBatchVertexBytes = MAX(metalView.testComposableMaxShapeBatchVertexBytes, bytes);
#endif
            [encoder setRenderPipelineState:metalView.composablePipeline];
            [encoder setVertexBytes:batchBytes + vertexOffset * sizeof(CJGuiInternalMetalVertex) length:byteCount atIndex:0];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertexCount];
            vertexOffset += vertexCount;
            remainingVertices -= vertexCount;
        }
        [shapeBatch setLength:0];
        return YES;
    };
    [encoder setScissorRect:(MTLScissorRect){ 0, 0, (NSUInteger)drawableSize.width, (NSUInteger)drawableSize.height }];
    for (CJGuiInternalComposableSceneNode *node in metalView.composableNodes) {
        CjguiInternalRendererComposableNode value = node.node;
        if (value.width <= 0 || value.height <= 0 || value.clipWidth <= 0 || value.clipHeight <= 0) continue;
        uint64_t sx = (uint64_t)MAX(0, (int64_t)((CGFloat)value.clipX * scaleX));
        uint64_t sy = (uint64_t)MAX(0, (int64_t)((CGFloat)value.clipY * scaleY));
        uint64_t sw = (uint64_t)MAX(0, (int64_t)((CGFloat)value.clipWidth * scaleX));
        uint64_t sh = (uint64_t)MAX(0, (int64_t)((CGFloat)value.clipHeight * scaleY));
        if (sx >= drawableSize.width || sy >= drawableSize.height) continue;
        if (sx + sw > drawableSize.width) sw = drawableSize.width - sx;
        if (sy + sh > drawableSize.height) sh = drawableSize.height - sy;
        if (sw == 0 || sh == 0) continue;
        vector_float4 fill = { (float)value.fillRed, (float)value.fillGreen, (float)value.fillBlue, (float)value.fillAlpha };
        vector_float4 border = { (float)value.borderRed, (float)value.borderGreen, (float)value.borderBlue, (float)value.borderAlpha };
        NSUInteger shapeBytesBefore = shapeBatch.length;
        CjguiAppendMetalShape(shapeBatch, pointWidth, pointHeight, value, fill, border);
#ifdef CJGUI_INTERNAL_TESTING
        if (shapeBatch.length > shapeBytesBefore && metalView.testComposableShapeNodeCount < UINT32_MAX) {
            metalView.testComposableShapeNodeCount += 1;
        }
        // The comparison path is still legal: every complete rectangle is
        // uploaded as six vertices, well below Metal's 4 KiB setVertexBytes
        // ceiling. It differs only in submission granularity; painter order,
        // vertex data and all resource boundaries stay identical.
        if (shapeBatch.length > shapeBytesBefore && metalView.testComposableShapeSubmissionMode == 1) {
            if (!flushShapeBatch()) return NO;
        }
#endif
        if (CjguiComposableNodeUsesGpuText(value.nodeKind)) {
            // Selection backgrounds must paint after this node's fill but
            // before its immutable glyph texture. Foreground decorations are
            // appended after the texture and flushed before the next scene
            // node, preserving the same per-node painter order as a fully
            // rasterized active input.
            NSUInteger decorationsBefore = shapeBatch.length;
            vector_float4 selectionFill = CjguiMetalColorFromNSColor(NSColor.selectedTextBackgroundColor);
            for (NSValue *valueRect in node.textSelectionRects) {
                CjguiAppendMetalTextDecoration(shapeBatch, pointWidth, pointHeight, value, valueRect.rectValue, selectionFill);
            }
            if (node.textTexture && !flushShapeBatch()) return NO;
            if (node.textTexture && !CjguiEnsureComposableImagePipeline(metalView)) return NO;
            if (node.textTexture) [encoder setRenderPipelineState:metalView.composableImagePipeline];
#ifdef CJGUI_INTERNAL_TESTING
            if (node.textTexture && metalView.testComposableTextureDrawCount < UINT32_MAX) metalView.testComposableTextureDrawCount += 1;
#endif
            NSRect textureRect = node.textTextureRect;
            if (node.textTexture && !NSIsEmptyRect(textureRect)) {
                CjguiEncodeMetalTexture(encoder, pointWidth, pointHeight,
                                        NSMinX(textureRect), NSMinY(textureRect),
                                        NSWidth(textureRect), NSHeight(textureRect), node.textTexture, value, YES);
            }
            if (node.textTexture) [encoder setRenderPipelineState:metalView.composablePipeline];
            vector_float4 foregroundFill = CjguiMetalColorFromNSColor(NSColor.keyboardFocusIndicatorColor);
            for (NSValue *valueRect in node.textMarkedRects) {
                CjguiAppendMetalTextDecoration(shapeBatch, pointWidth, pointHeight, value, valueRect.rectValue, foregroundFill);
            }
            CjguiAppendMetalTextDecoration(shapeBatch, pointWidth, pointHeight, value, node.textCaretRect, foregroundFill);
            if (shapeBatch.length > decorationsBefore && !flushShapeBatch()) return NO;
            [encoder setRenderPipelineState:metalView.composablePipeline];
        }
        if (value.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE && node.imageTexture) {
            if (!flushShapeBatch()) return NO;
            if (!CjguiEnsureComposableImagePipeline(metalView)) return NO;
            CGFloat sourceWidth = MAX(1.0, (CGFloat)node.imageTexture.width);
            CGFloat sourceHeight = MAX(1.0, (CGFloat)node.imageTexture.height);
            CGFloat scale = value.imageContentMode == 2 ? MAX((CGFloat)value.width / sourceWidth, (CGFloat)value.height / sourceHeight)
                                                        : MIN((CGFloat)value.width / sourceWidth, (CGFloat)value.height / sourceHeight);
            CGFloat drawWidth = sourceWidth * scale;
            CGFloat drawHeight = sourceHeight * scale;
            [encoder setRenderPipelineState:metalView.composableImagePipeline];
#ifdef CJGUI_INTERNAL_TESTING
            if (metalView.testComposableTextureDrawCount < UINT32_MAX) metalView.testComposableTextureDrawCount += 1;
#endif
            CjguiEncodeMetalTexture(encoder, pointWidth, pointHeight,
                                    value.x + ((CGFloat)value.width - drawWidth) / 2.0,
                                    value.y + ((CGFloat)value.height - drawHeight) / 2.0,
                                    drawWidth, drawHeight, node.imageTexture, value, NO);
            [encoder setRenderPipelineState:metalView.composablePipeline];
        }
    }
    return flushShapeBatch();
}

static NSRect CjguiComposableRect(CJGuiInternalComposableSceneNode *node, NSView *view) {
    CjguiInternalRendererComposableNode value = node.node;
    // The composable overlay is flipped, as is the Cangjie layout space: both
    // start at the window's top-left.  Do not invert here; doing so made text,
    // hit testing and AX frames disagree with the Metal scene.
    return NSMakeRect((CGFloat)value.x, (CGFloat)value.y,
                      MAX(0.0, (CGFloat)value.width), MAX(0.0, (CGFloat)value.height));
}

static NSRect CjguiComposableClipConstraintRect(CJGuiInternalComposableSceneNode *node, uint32_t index) {
    CGFloat x = 0, y = 0, width = 0, height = 0, radius = 0;
    CjguiComposableClipConstraintAt(node.node, index, &x, &y, &width, &height, &radius);
    return NSMakeRect(x, y, MAX(0.0, width), MAX(0.0, height));
}

// The layout projection also supplies this rectangle intersection for cheap
// culling and AX bounds.  It is never used as the final rounded clip: every
// draw and hit test below evaluates the complete ancestor chain.
static NSRect CjguiComposableClipBounds(CJGuiInternalComposableSceneNode *node) {
    CjguiInternalRendererComposableNode value = node.node;
    return NSMakeRect((CGFloat)value.clipX, (CGFloat)value.clipY,
                      MAX(0.0, (CGFloat)value.clipWidth), MAX(0.0, (CGFloat)value.clipHeight));
}

// Scene geometry is expressed in the overlay's flipped coordinate space.  A
// rounded inherited clip must therefore have the same meaning for Metal,
// TextKit's remaining multiline path, and pointer routing.  A decoration
// radius alone is not consulted here: only the resolved clip radius controls
// whether children may draw or receive an event.
static BOOL CjguiPointInRoundedRect(NSPoint point, NSRect rect, CGFloat requestedRadius) {
    if (!NSPointInRect(point, rect)) return NO;
    CGFloat radius = MIN(MAX(0.0, requestedRadius), MIN(NSWidth(rect), NSHeight(rect)) / 2.0);
    if (radius <= 0.0) return YES;
    CGFloat minX = NSMinX(rect), maxX = NSMaxX(rect);
    CGFloat minY = NSMinY(rect), maxY = NSMaxY(rect);
    CGFloat centreX = point.x < minX + radius ? minX + radius :
                      (point.x > maxX - radius ? maxX - radius : point.x);
    CGFloat centreY = point.y < minY + radius ? minY + radius :
                      (point.y > maxY - radius ? maxY - radius : point.y);
    CGFloat dx = point.x - centreX, dy = point.y - centreY;
    return dx * dx + dy * dy <= radius * radius;
}

static BOOL CjguiPointInComposableNodeClip(NSPoint point, CJGuiInternalComposableSceneNode *node, NSView *view) {
    (void)view;
    return node && CjguiComposablePointInClipChain(point.x, point.y, node.node);
}

static void CjguiClipComposableNode(CJGuiInternalComposableSceneNode *node, NSView *view) {
    if (!node) return;
    (void)view;
    uint32_t count = CjguiComposableClipConstraintCount(node.node);
    for (uint32_t i = 0; i < count; i++) {
        NSRect rect = CjguiComposableClipConstraintRect(node, i);
        CGFloat x = 0, y = 0, width = 0, height = 0, radius = 0;
        CjguiComposableClipConstraintAt(node.node, i, &x, &y, &width, &height, &radius);
        radius = MIN(MAX(0.0, radius), MIN(NSWidth(rect), NSHeight(rect)) / 2.0);
        if (radius <= 0.0) {
            NSRectClip(rect);
        } else {
            [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius] addClip];
        }
    }
}

static NSFont *CjguiComposableFontForStyle(double requested, uint32_t fontWeight, uint32_t fontFamily) {
    CGFloat size = MIN(144.0, MAX(6.0, requested));
    if (fontFamily == 1) {
        return [NSFont monospacedSystemFontOfSize:size weight:fontWeight > 0 ? NSFontWeightBold : NSFontWeightRegular];
    }
    return fontWeight > 0 ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size];
}

static NSFont *CjguiComposableFont(CJGuiInternalComposableSceneNode *node) {
    return CjguiComposableFontForStyle(
        node ? node.node.fontSize : 13.0,
        node ? node.node.fontWeight : 0,
        node ? node.node.fontFamily : 0
    );
}

#ifdef CJGUI_INTERNAL_TESTING
static CGRect CjguiMapMultilineDiagnosticRect(CGRect rect, CGAffineTransform transform) {
    CGPoint corners[4] = {
        CGPointApplyAffineTransform(CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)), transform),
        CGPointApplyAffineTransform(CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect)), transform),
        CGPointApplyAffineTransform(CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)), transform),
        CGPointApplyAffineTransform(CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)), transform),
    };
    CGFloat minX = corners[0].x, maxX = corners[0].x, minY = corners[0].y, maxY = corners[0].y;
    for (NSUInteger index = 1; index < 4; index++) {
        minX = MIN(minX, corners[index].x); maxX = MAX(maxX, corners[index].x);
        minY = MIN(minY, corners[index].y); maxY = MAX(maxY, corners[index].y);
    }
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

static void CjguiLogMultilineGlyphDrawingState(uint64_t nodeId, NSLayoutManager *layoutManager,
                                                NSTextContainer *container, NSRange visibleGlyphs,
                                                NSPoint origin, NSString *value) {
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    if (!context || !layoutManager || !container || visibleGlyphs.location == NSNotFound || visibleGlyphs.length == 0) return;
    CGAffineTransform ctm = CGContextGetCTM(context);
    CGAffineTransform textMatrix = CGContextGetTextMatrix(context);
    CGPoint textPosition = CGContextGetTextPosition(context);
    NSRange containerGlyphs = [layoutManager glyphRangeForTextContainer:container];
    NSGlyph glyph = [layoutManager glyphAtIndex:visibleGlyphs.location];
    NSGlyphProperty property = [layoutManager propertyForGlyphAtIndex:visibleGlyphs.location];
    NSRect line = [layoutManager lineFragmentRectForGlyphAtIndex:visibleGlyphs.location effectiveRange:NULL];
    NSRect used = [layoutManager lineFragmentUsedRectForGlyphAtIndex:visibleGlyphs.location effectiveRange:NULL];
    NSPoint glyphLocation = [layoutManager locationForGlyphAtIndex:visibleGlyphs.location];
    NSRect glyphBounds = [layoutManager boundingRectForGlyphRange:NSMakeRange(visibleGlyphs.location, 1)
                                                   inTextContainer:container];
    NSRect glyphUserBounds = NSOffsetRect(glyphBounds, origin.x, origin.y);
    CGRect glyphDeviceBounds = CjguiMapMultilineDiagnosticRect(NSRectToCGRect(glyphUserBounds), ctm);
    CGRect clipUserBounds = CGContextGetClipBoundingBox(context);
    NSMutableString *utf16 = [NSMutableString string];
    for (NSUInteger index = 0; index < value.length; index++) [utf16 appendFormat:@"%04X", [value characterAtIndex:index]];
    NSDictionary *attributes = value.length > 0 ? [layoutManager.textStorage attributesAtIndex:0 effectiveRange:NULL] : @{};
    NSMutableString *fontRuns = [NSMutableString string];
    [layoutManager.textStorage enumerateAttributesInRange:NSMakeRange(0, value.length) options:0
                                               usingBlock:^(NSDictionary<NSAttributedStringKey, id> *runAttributes,
                                                            NSRange range, BOOL *stop) {
        (void)stop;
        NSFont *runFont = runAttributes[NSFontAttributeName];
        [fontRuns appendFormat:@"%lu:%lu=%@;", (unsigned long)range.location, (unsigned long)range.length,
         runFont.fontName ?: @"(none)"];
    }];
    NSMutableString *glyphs = [NSMutableString string];
    NSUInteger glyphEnd = MIN(NSMaxRange(visibleGlyphs), visibleGlyphs.location + 8);
    for (NSUInteger index = visibleGlyphs.location; index < glyphEnd; index++) {
        [glyphs appendFormat:@"%lu:%u/%lu;", (unsigned long)index, [layoutManager glyphAtIndex:index],
         (unsigned long)[layoutManager propertyForGlyphAtIndex:index]];
    }
    NSFont *font = attributes[NSFontAttributeName];
    CGGlyph directGlyph = 0;
    BOOL hasDirectGlyph = NO;
    CTFontRef fallback = NULL;
    if (font && value.length > 0) {
        CTFontRef baseFont = (__bridge CTFontRef)font;
        UniChar firstCharacter = [value characterAtIndex:0];
        hasDirectGlyph = CTFontGetGlyphsForCharacters(baseFont, &firstCharacter, &directGlyph, 1);
        fallback = CTFontCreateForString(baseFont, (__bridge CFStringRef)value, CFRangeMake(0, value.length));
    }
    NSString *fallbackName = fallback ? CFBridgingRelease(CTFontCopyPostScriptName(fallback)) : @"(none)";
    if (fallback) CFRelease(fallback);
    if (CjguiTestVerboseGlyphDiagnosticsEnabled()) NSLog(@"cjgui: multiline glyph-draw node=%llu context=%p flipped=%d ctm=(%.3f,%.3f,%.3f,%.3f,%.3f,%.3f) textMatrix=(%.3f,%.3f,%.3f,%.3f,%.3f,%.3f) textPosition=(%.3f,%.3f) clipUser=%@ origin=%@ value=%@ utf16=%@ font=%@ fontRuns=%@ directGlyph=%u direct=%d cascadeCandidate=%@ containerGlyphs=%lu:%lu visible=%lu:%lu glyphs=%@ glyph0=%u property=%lu line=%@ used=%@ location=%@ glyphBounds=%@ glyphUser=%@ glyphDevice=%@",
          nodeId, context, NSGraphicsContext.currentContext.isFlipped,
          ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty,
          textMatrix.a, textMatrix.b, textMatrix.c, textMatrix.d, textMatrix.tx, textMatrix.ty,
          textPosition.x, textPosition.y, NSStringFromRect(NSRectFromCGRect(clipUserBounds)), NSStringFromPoint(origin),
          value ?: @"", utf16, font, fontRuns, directGlyph, hasDirectGlyph, fallbackName,
          (unsigned long)containerGlyphs.location, (unsigned long)containerGlyphs.length,
          (unsigned long)visibleGlyphs.location, (unsigned long)visibleGlyphs.length, glyphs,
          glyph, (unsigned long)property, NSStringFromRect(line), NSStringFromRect(used),
          NSStringFromPoint(glyphLocation), NSStringFromRect(glyphBounds), NSStringFromRect(glyphUserBounds),
          NSStringFromRect(NSRectFromCGRect(glyphDeviceBounds)));
}
#endif

@class CJGuiInternalComposableSceneOverlay;

// A self-drawn multiline node needs TextKit for exactly the same glyph and
// line-fragment geometry used by input hit testing.  Keep that layout bounded
// and projection-owned rather than allocating a second TextKit graph on every
// display pass.  The current projection version is part of the cache key, so
// a changed projection cannot reuse an older semantic snapshot.
@interface CJGuiInternalComposableMultilineLayoutCacheEntry : NSObject
@property(nonatomic, strong) NSTextStorage *storage;
@property(nonatomic, strong) NSLayoutManager *layoutManager;
@property(nonatomic, strong) NSTextContainer *container;
@property(nonatomic, strong) NSString *value;
@property(nonatomic, assign) CGFloat contentWidth;
@property(nonatomic, assign) CGFloat maximumScroll;
@end

@implementation CJGuiInternalComposableMultilineLayoutCacheEntry
@end

static BOOL CjguiComposableNodeIsTextInput(uint32_t kind) {
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
}

static BOOL CjguiComposableNodeAcceptsPointerCapture(uint32_t kind) {
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER;
}

static BOOL CjguiComposableNodeIsAccessibilityElement(CJGuiInternalComposableSceneNode *node) {
    if (!node) return NO;
    // Disabled controls remain discoverable so an assistive client can tell
    // why the visible action cannot run. Static text is likewise a first
    // class semantic object even though it never receives pointer input.
    uint32_t kind = node.node.nodeKind;
    return node.node.isInteractive != 0 || kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ||
        CjguiComposableNodeIsTextInput(kind) || kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT;
}

@interface CJGuiInternalComposableAccessibilityAction : NSAccessibilityElement
@property(nonatomic, weak) CJGuiInternalComposableSceneOverlay *overlay;
@property(nonatomic, strong) CJGuiInternalComposableSceneNode *node;
- (instancetype)initWithOverlay:(CJGuiInternalComposableSceneOverlay *)overlay node:(CJGuiInternalComposableSceneNode *)node;
@end

#ifdef CJGUI_INTERNAL_TESTING
// This test-only accumulator keeps scalar timings on the existing TextKit
// graph. It never becomes a text-system delegate or content owner.
@interface CJGuiInternalComposableActiveLayoutTrace : NSObject
@property(nonatomic, assign) uint64_t characterEnsureCount;
@property(nonatomic, assign) uint64_t characterEnsureMicros;
@property(nonatomic, assign) uint64_t boundingEnsureCount;
@property(nonatomic, assign) uint64_t boundingEnsureMicros;
@property(nonatomic, assign) uint64_t glyphIndexCount;
@property(nonatomic, assign) uint64_t glyphIndexMicros;
@property(nonatomic, assign) uint64_t lineFragmentCount;
@property(nonatomic, assign) uint64_t lineFragmentMicros;
@property(nonatomic, assign) uint64_t glyphLocationCount;
@property(nonatomic, assign) uint64_t glyphLocationMicros;
@property(nonatomic, assign) uint64_t positionProxyMicros;
@property(nonatomic, assign) uint64_t positionNoopWrites;
@property(nonatomic, assign) uint64_t positionChangedWrites;
@property(nonatomic, assign) uint64_t firstUnlaidBefore;
@property(nonatomic, assign) uint64_t firstUnlaidAfter;
@property(nonatomic, assign) uint64_t invalidatedLocation;
@property(nonatomic, assign) uint64_t invalidatedLength;
@property(nonatomic, assign) uint64_t revealMicros;
@property(nonatomic, assign) uint64_t candidateMicros;
@property(nonatomic, assign) uint64_t positionFirstUnlaidBefore;
@property(nonatomic, assign) uint64_t positionFirstUnlaidAfter;
@property(nonatomic, assign) uint64_t positionChangedMask;
- (void)reset;
@end

@implementation CJGuiInternalComposableActiveLayoutTrace
- (instancetype)init {
    self = [super init];
    if (self) [self reset];
    return self;
}
- (void)reset {
    self.characterEnsureCount = 0; self.characterEnsureMicros = 0;
    self.boundingEnsureCount = 0; self.boundingEnsureMicros = 0;
    self.glyphIndexCount = 0; self.glyphIndexMicros = 0;
    self.lineFragmentCount = 0; self.lineFragmentMicros = 0;
    self.glyphLocationCount = 0; self.glyphLocationMicros = 0;
    self.positionProxyMicros = 0; self.positionNoopWrites = 0; self.positionChangedWrites = 0;
    self.firstUnlaidBefore = UINT64_MAX; self.firstUnlaidAfter = UINT64_MAX;
    self.invalidatedLocation = UINT64_MAX; self.invalidatedLength = 0;
    self.revealMicros = 0; self.candidateMicros = 0;
    self.positionFirstUnlaidBefore = UINT64_MAX; self.positionFirstUnlaidAfter = UINT64_MAX;
    self.positionChangedMask = 0;
}
@end

// This trace is intentionally scoped to one test-driven normal insertion.
// It records nested timing separately from the enclosing NSTextView call, so
// consumers do not add the fields together as an E2E duration.
@interface CJGuiInternalComposableInputCallbackTrace : NSObject
@property(nonatomic, assign) uint64_t superInsertMicros;
@property(nonatomic, assign) uint64_t modeChangeCount;
@property(nonatomic, assign) uint64_t modeChangeMicros;
@property(nonatomic, assign) uint64_t textCallbackCount;
@property(nonatomic, assign) uint64_t textCallbackMicros;
@property(nonatomic, assign) uint64_t selectionCallbackCount;
@property(nonatomic, assign) uint64_t pendingEditSelectionCount;
@property(nonatomic, assign) uint64_t selectionCallbackMicros;
@property(nonatomic, assign) uint64_t selectionRevealMicros;
@property(nonatomic, assign) uint64_t selectionQueueMicros;
@property(nonatomic, assign) uint64_t selectionAccessibilityMicros;
@property(nonatomic, assign) uint64_t refreshMicros;
@property(nonatomic, assign) uint64_t preparationMicros;
@property(nonatomic, assign) uint64_t wholeAttributeWriteCount;
@property(nonatomic, assign) uint64_t wholeAttributeCharacters;
@property(nonatomic, assign) uint64_t fallbackApplyCount;
@property(nonatomic, assign) uint64_t fallbackCharacters;
@property(nonatomic, assign) uint64_t fallbackMicros;
- (void)reset;
@end

@implementation CJGuiInternalComposableInputCallbackTrace
- (instancetype)init {
    self = [super init];
    if (self) [self reset];
    return self;
}
- (void)reset {
    self.superInsertMicros = 0; self.modeChangeCount = 0; self.modeChangeMicros = 0;
    self.textCallbackCount = 0; self.textCallbackMicros = 0;
    self.selectionCallbackCount = 0; self.pendingEditSelectionCount = 0;
    self.selectionCallbackMicros = 0; self.selectionRevealMicros = 0;
    self.selectionQueueMicros = 0; self.selectionAccessibilityMicros = 0;
    self.refreshMicros = 0; self.preparationMicros = 0;
    self.wholeAttributeWriteCount = 0; self.wholeAttributeCharacters = 0;
    self.fallbackApplyCount = 0; self.fallbackCharacters = 0; self.fallbackMicros = 0;
}
@end
#endif

@interface CJGuiInternalComposableSceneOverlay : NSView <NSTextViewDelegate>
@property(nonatomic, weak) CJGuiInternalSession *session;
@property(nonatomic, strong) NSArray<CJGuiInternalComposableSceneNode *> *nodes;
@property(nonatomic, strong) NSMutableArray<CJGuiInternalComposableAccessibilityAction *> *accessibilityActions;
@property(nonatomic, strong) NSTextView *inputProxy;
@property(nonatomic, strong) NSScrollView *inputScrollProxy;
@property(nonatomic, assign) NSInteger activeNodeIndex;
@property(nonatomic, assign) uint64_t activeNodeId;
@property(nonatomic, assign) uint64_t activeProjectionVersion;
@property(nonatomic, assign) int64_t activeNodeResourceId;
@property(nonatomic, assign) uint32_t activeNodeKind;
@property(nonatomic, assign) BOOL applyingProjection;
#ifdef CJGUI_INTERNAL_TESTING
// Test-only receipt counter. It establishes whether an NSEvent dispatched by
// NSApplication reached this production responder; it is never projected or
// exposed through the framework API.
@property(nonatomic, assign) uint64_t testKeyDownReceiptCount;
#endif
// The platform text service remains the input/IME adapter. Its visible
// viewport is never the document surface; this offset belongs to the
// self-drawn composable multiline viewport.
@property(nonatomic, assign) CGFloat multilineScrollOffset;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *multilineScrollOffsets;
@property(nonatomic, strong) NSMutableDictionary<NSString *, CJGuiInternalComposableMultilineLayoutCacheEntry *> *multilineLayoutCache;
@property(nonatomic, strong) NSMutableArray<NSString *> *multilineLayoutCacheOrder;
@property(nonatomic, assign) uint32_t multilineLayoutCacheHighWater;
@property(nonatomic, copy) NSString *activeTextLayoutSignature;
// Fallback fonts are a derived presentation property of the one active
// TextKit graph. They are prepared after an edit transaction, never by a
// second text owner or during the synchronous text-change callback.
@property(nonatomic, assign) BOOL activeTextFallbackRunsDirty;
@property(nonatomic, assign) BOOL activeTextFallbackNeedsFullRefresh;
@property(nonatomic, assign) BOOL activeTextFallbackHasDirtyRange;
@property(nonatomic, assign) NSRange activeTextFallbackDirtyRange;
@property(nonatomic, assign) BOOL activeTextFallbackHasPendingEdit;
@property(nonatomic, assign) NSRange activeTextFallbackPendingEditRange;
// This is the style-owned base, never a font inferred from the currently
// selected fallback run in NSTextStorage.
@property(nonatomic, strong) NSFont *activeTextBaseFont;
// The last base font deliberately assigned through NSTextView.font.  It is
// distinct from `activeTextBaseFont`: preparation may already have adopted a
// new node style before positioning decides whether the global setter is
// required.  Never derive this from NSTextView.font, whose getter can expose
// a character's fallback run.
@property(nonatomic, strong) NSFont *inputProxyAssignedBaseFont;
@property(nonatomic, assign) BOOL activeTextResourcePreparationScheduled;
@property(nonatomic, copy) NSString *activeTextTextureRetryKey;
@property(nonatomic, assign) uint32_t activeTextTextureRetryCount;
@property(nonatomic, assign) BOOL activeTextTexturePreparationFailed;
// Test-only cause supplied by the production event boundary immediately
// before an active refresh. It is consumed only when a key change causes real
// raster/upload; otherwise the bucket stays explicit unknown.
#ifdef CJGUI_INTERNAL_TESTING
@property(nonatomic, assign) uint32_t testActiveTextWorkReason;
#endif
// These values intentionally describe separate facts.  A text mutation can
// need visible glyphs while the total document height is unknown; neither
// fact authorizes a full-container layout on the next selection callback.
@property(nonatomic, assign) BOOL activeTextLayoutNeedsVisibleGlyphs;
@property(nonatomic, assign) BOOL activeTextHasExactContentHeight;
@property(nonatomic, assign) CGFloat activeTextKnownContentHeight;
@property(nonatomic, assign) BOOL activeTextHasScrollAnchor;
@property(nonatomic, assign) NSUInteger activeTextScrollAnchorCharacter;
@property(nonatomic, assign) CGFloat activeTextScrollAnchorViewportOffset;
@property(nonatomic, assign) uint64_t activeTextRangeLayoutCount;
@property(nonatomic, assign) uint64_t activeTextFullLayoutCount;
#ifdef CJGUI_INTERNAL_TESTING
@property(nonatomic, strong) CJGuiInternalComposableActiveLayoutTrace *activeTextLayoutTrace;
@property(nonatomic, strong) CJGuiInternalComposableInputCallbackTrace *testInputCallbackTrace;
@property(nonatomic, assign) BOOL testUsesBoundedInputLayout;
// Test-only one-shot control for the selection A/B probe.  It is armed by the
// selection callback and consumed by the next refresh, so normal production
// selection remains body-cache reuse unless the probe explicitly asks for the
// real full preparation path.
@property(nonatomic, assign) BOOL testForceFullBodyPreparationOnSelection;
#endif
@property(nonatomic, assign) uint64_t multilineLayoutBuildCount;
@property(nonatomic, assign) uint64_t multilineLayoutFullLayoutCount;
@property(nonatomic, assign) uint64_t draggingNodeId;
@property(nonatomic, assign) int64_t draggingNodeResourceId;
@property(nonatomic, assign) uint64_t draggingProjectionVersion;
@property(nonatomic, assign) NSUInteger draggingAnchor;
// Pointer capture is a narrow native routing state only.  It retains stable
// copied scalars, never a Cangjie callback or application value.
@property(nonatomic, assign) BOOL pointerCaptureActive;
@property(nonatomic, assign) uint64_t pointerCaptureNodeId;
@property(nonatomic, assign) int64_t pointerCaptureResourceId;
@property(nonatomic, assign) uint32_t pointerCaptureNodeKind;
@property(nonatomic, assign) CGFloat pointerCaptureX;
@property(nonatomic, assign) CGFloat pointerCaptureY;
// Draw progress is recorded by the self-drawn AppKit overlay itself. It does
// not imply Metal completion or that a human has visually perceived a frame.
@property(nonatomic, assign) uint64_t lastDrawnProjectionVersion;
- (instancetype)initWithFrame:(NSRect)frame session:(CJGuiInternalSession *)session;
- (void)setNodesFromProjection:(NSArray<CJGuiInternalComposableSceneNode *> *)nodes;
- (void)refreshGpuTextForActiveInput;
- (void)prepareInactiveTextResourceForFocusChange:(CJGuiInternalComposableSceneNode *)node;
- (void)prepareActiveMultilineFallbackRunsForNode:(CJGuiInternalComposableSceneNode *)node;
- (void)updateActiveSingleLineTextDecorationsForNode:(CJGuiInternalComposableSceneNode *)node
                                           displayText:(NSString *)displayText
                                             selection:(NSRange)selection
                                           markedRange:(NSRange)markedRange
                                            drawsCaret:(BOOL)drawsCaret;
- (void)updateActiveMultilineTextDecorationsForNode:(CJGuiInternalComposableSceneNode *)node;
- (void)applySystemFallbackRunsToActiveInput;
- (void)markActiveTextFallbackRunsDirtyForRange:(NSRange)range;
- (void)markActiveTextFallbackRunsDirtyForWholeValue;
- (void)remapActiveTextFallbackDirtyRangeForEditRange:(NSRange)range replacementLength:(NSUInteger)replacementLength;
- (NSRange)fallbackAffectedRangeAfterEditAt:(NSUInteger)location replacementLength:(NSUInteger)replacementLength value:(NSString *)value;
- (void)scheduleActiveTextResourcePreparation;
- (BOOL)focusCommittedNodeId:(uint64_t)nodeId;
- (void)focusNode:(CJGuiInternalComposableSceneNode *)node enqueue:(BOOL)enqueue;
- (void)mouseDownForNode:(CJGuiInternalComposableSceneNode *)node;
- (BOOL)beginPointerCaptureForNode:(CJGuiInternalComposableSceneNode *)node atPoint:(NSPoint)point;
- (BOOL)updatePointerCaptureAtPoint:(NSPoint)point;
- (void)endPointerCaptureAtPoint:(NSPoint)point cancelled:(BOOL)cancelled;
- (void)cancelPointerCapture;
- (void)cancelPointerCaptureForPlatformLoss;
- (CJGuiInternalComposableSceneNode *)capturedPointerNode;
- (CJGuiInternalComposableSceneNode *)nodeAtPoint:(NSPoint)point;
- (void)setText:(NSString *)text forNode:(CJGuiInternalComposableSceneNode *)node;
- (void)positionInputProxyForNode:(CJGuiInternalComposableSceneNode *)node;
- (void)ensureActiveLayoutForCharacterRange:(NSRange)range layoutManager:(NSLayoutManager *)layoutManager;
- (void)ensureActiveLayoutForBoundingRect:(NSRect)rect container:(NSTextContainer *)container layoutManager:(NSLayoutManager *)layoutManager;
- (void)ensureActiveFullLayoutForContainer:(NSTextContainer *)container layoutManager:(NSLayoutManager *)layoutManager;
- (NSUInteger)activeGlyphIndexForCharacter:(NSUInteger)character layoutManager:(NSLayoutManager *)layoutManager;
- (NSRect)activeLineFragmentForGlyph:(NSUInteger)glyph layoutManager:(NSLayoutManager *)layoutManager;
- (NSPoint)activeGlyphLocation:(NSUInteger)glyph layoutManager:(NSLayoutManager *)layoutManager;
- (void)revealActiveMultilineCharacterAtLocation:(NSUInteger)location forNode:(CJGuiInternalComposableSceneNode *)node;
- (NSRect)candidateRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange;
- (BOOL)handleWindowCommandKeyDown:(NSEvent *)event;
- (void)cancelActiveComposition;
- (CJGuiInternalComposableSceneNode *)accessibilityLiveNodeForNode:(CJGuiInternalComposableSceneNode *)node;
- (BOOL)accessibilityNodeIsActionable:(CJGuiInternalComposableSceneNode *)node;
- (BOOL)accessibilityNodeIsFocused:(CJGuiInternalComposableSceneNode *)node;
- (NSString *)accessibilityCurrentTextForNode:(CJGuiInternalComposableSceneNode *)node;
- (BOOL)accessibilityPerformPressForNode:(CJGuiInternalComposableSceneNode *)node;
- (void)accessibilitySetValue:(id)value forNode:(CJGuiInternalComposableSceneNode *)node;
- (void)accessibilitySetSelectedTextRange:(NSRange)range forNode:(CJGuiInternalComposableSceneNode *)node;
- (void)postAccessibilityValueChangedForNode:(CJGuiInternalComposableSceneNode *)node;
- (void)postAccessibilitySelectionChangedForNode:(CJGuiInternalComposableSceneNode *)node;
- (void)postAccessibilityFocusChangedForNode:(CJGuiInternalComposableSceneNode *)node;
@end

@implementation CJGuiInternalComposableAccessibilityAction
- (instancetype)initWithOverlay:(CJGuiInternalComposableSceneOverlay *)overlay node:(CJGuiInternalComposableSceneNode *)node {
    self = [super init]; if (!self) return nil; self.overlay = overlay; self.node = node; return self;
}
- (CJGuiInternalComposableSceneNode *)currentNode {
    return [self.overlay accessibilityLiveNodeForNode:self.node];
}
- (id)accessibilityParent { return [self currentNode] ? self.overlay : nil; }
- (id)accessibilityWindow { return [self currentNode] ? self.overlay.window : nil; }
- (id)accessibilityTopLevelUIElement { return [self currentNode] ? self.overlay.window : nil; }
- (BOOL)isAccessibilityElement { return [self currentNode] != nil; }
- (NSAccessibilityRole)accessibilityRole {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    uint32_t kind = node ? node.node.nodeKind : 0;
    if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT) return NSAccessibilityStaticTextRole;
    if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON) return NSAccessibilityButtonRole;
    if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) return NSAccessibilityCheckBoxRole;
    if (CjguiComposableNodeIsTextInput(kind)) return NSAccessibilityTextFieldRole;
    return NSAccessibilityGroupRole;
}
- (NSString *)accessibilityLabel {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    return node ? (node.label.length > 0 ? node.label : node.value) : @"";
}
- (NSString *)accessibilityTitle {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    return node && node.label.length > 0 ? node.label : nil;
}
- (id)accessibilityValue {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    if (!node) return nil;
    if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) {
        return @([node.value isEqualToString:@"true"]);
    }
    return CjguiComposableNodeIsTextInput(node.node.nodeKind) ? [self.overlay accessibilityCurrentTextForNode:node] : node.value;
}
- (BOOL)accessibilityIsAttributeSettable:(NSAccessibilityAttributeName)attribute {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    if (!node) return NO;
    uint32_t kind = node.node.nodeKind;
    if ([attribute isEqualToString:NSAccessibilitySelectedTextRangeAttribute]) {
        return CjguiComposableNodeIsTextInput(kind) && node.node.isInteractive != 0;
    }
    if (![attribute isEqualToString:NSAccessibilityValueAttribute]) return NO;
    if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) return [self.overlay accessibilityNodeIsActionable:node];
    return CjguiComposableNodeIsTextInput(kind) && [self.overlay accessibilityNodeIsActionable:node];
}

- (BOOL)accessibilityIsEnabled {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    return node && (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT || node.node.isInteractive != 0);
}
- (BOOL)isAccessibilityEnabled {
    // AppKit accessibility clients query this legacy selector when deciding
    // whether an exposed self-drawn element can receive an action.
    return [self accessibilityIsEnabled];
}
- (BOOL)accessibilityIsEditable {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    return node && CjguiComposableNodeIsTextInput(node.node.nodeKind) && [self.overlay accessibilityNodeIsActionable:node];
}
- (NSArray<NSAccessibilityActionName> *)accessibilityActionNames {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    if (!node || ![self.overlay accessibilityNodeIsActionable:node]) return @[];
    uint32_t kind = node.node.nodeKind;
    return kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON || kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT
        ? @[ NSAccessibilityPressAction ] : @[];
}
- (NSRect)accessibilityFrame {
    return [self currentNode] ? NSAccessibilityFrameInView(self.overlay, [self accessibilityFrameInParentSpace]) : NSZeroRect;
}
- (NSPoint)accessibilityPosition { return [self accessibilityFrame].origin; }
- (NSSize)accessibilitySize { return [self accessibilityFrame].size; }
- (NSRect)accessibilityFrameInParentSpace {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    if (!node) return NSZeroRect;
    return NSIntersectionRect(CjguiComposableRect(node, self.overlay), CjguiComposableClipBounds(node));
}
- (BOOL)accessibilityFocused { return [self.overlay accessibilityNodeIsFocused:[self currentNode]]; }
- (void)accessibilitySetFocused:(BOOL)focused {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    if (!focused || !node) return;
    if (CjguiComposableNodeIsTextInput(node.node.nodeKind) && node.node.isInteractive != 0) {
        [self.overlay focusNode:node enqueue:YES];
    } else if ([self.overlay accessibilityNodeIsActionable:node]) {
        [self.overlay focusNode:node enqueue:YES];
    }
}
- (NSRange)accessibilitySelectedTextRange {
    CJGuiInternalComposableSceneNode *node = [self currentNode];
    if (!node || !CjguiComposableNodeIsTextInput(node.node.nodeKind) || ![self.overlay accessibilityNodeIsFocused:node]) {
        return NSMakeRange(NSNotFound, 0);
    }
    return self.overlay.inputProxy.selectedRange;
}
- (void)accessibilitySetSelectedTextRange:(NSValue *)value {
    if (![value respondsToSelector:@selector(rangeValue)]) return;
    [self.overlay accessibilitySetSelectedTextRange:value.rangeValue forNode:[self currentNode]];
}
- (NSString *)accessibilitySelectedText {
    NSString *text = [self accessibilityValue];
    NSRange selection = [self accessibilitySelectedTextRange];
    if (!text || selection.location == NSNotFound || NSMaxRange(selection) > text.length) return @"";
    return [text substringWithRange:selection];
}
- (NSRange)accessibilityVisibleCharacterRange {
    NSString *text = [self accessibilityValue];
    return NSMakeRange(0, text.length);
}
- (NSInteger)accessibilityNumberOfCharacters { return [[self accessibilityValue] length]; }
- (BOOL)accessibilityPerformPress { return [self.overlay accessibilityPerformPressForNode:[self currentNode]]; }
- (void)accessibilityPerformAction:(NSAccessibilityActionName)action {
    if ([action isEqualToString:NSAccessibilityPressAction]) [self accessibilityPerformPress];
}
- (void)accessibilitySetValue:(id)value {
    [self.overlay accessibilitySetValue:value forNode:[self currentNode]];
}
@end

@implementation CJGuiInternalComposableSceneOverlay
- (instancetype)initWithFrame:(NSRect)frame session:(CJGuiInternalSession *)session {
    self = [super initWithFrame:frame]; if (!self) return nil;
    self.session = session; self.nodes = @[]; self.accessibilityActions = [NSMutableArray array];
    self.activeNodeIndex = NSNotFound; self.activeNodeId = 0; self.activeProjectionVersion = 0;
    self.activeNodeResourceId = -1; self.activeNodeKind = 0; self.wantsLayer = NO;
    self.multilineScrollOffset = 0.0;
    self.multilineScrollOffsets = [NSMutableDictionary dictionary];
    self.multilineLayoutCache = [NSMutableDictionary dictionary];
    self.multilineLayoutCacheOrder = [NSMutableArray array];
    self.multilineLayoutCacheHighWater = 0;
    self.activeTextLayoutSignature = nil;
    self.activeTextLayoutNeedsVisibleGlyphs = NO;
    self.activeTextHasExactContentHeight = NO;
    self.activeTextKnownContentHeight = 0.0;
    self.activeTextHasScrollAnchor = NO;
    self.activeTextScrollAnchorCharacter = 0;
    self.activeTextScrollAnchorViewportOffset = 0.0;
    self.activeTextRangeLayoutCount = 0;
    self.activeTextFullLayoutCount = 0;
    self.multilineLayoutBuildCount = 0;
    self.multilineLayoutFullLayoutCount = 0;
    self.draggingNodeId = 0; self.draggingNodeResourceId = -1;
    self.draggingProjectionVersion = 0; self.draggingAnchor = 0;
    self.lastDrawnProjectionVersion = 0;
    self.inputScrollProxy = [[NSScrollView alloc] initWithFrame:NSMakeRect(-2, -2, 1, 1)];
    self.inputScrollProxy.drawsBackground = NO;
    self.inputScrollProxy.borderType = NSNoBorder;
    self.inputScrollProxy.hasVerticalScroller = YES;
    self.inputScrollProxy.autohidesScrollers = YES;
    self.inputScrollProxy.alphaValue = 0.01;
    self.inputProxy = [[CJGuiInternalComposableInputProxy alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
    ((CJGuiInternalComposableInputProxy *)self.inputProxy).composableOverlay = self;
    self.inputProxy.delegate = self; self.inputProxy.drawsBackground = NO; self.inputProxy.alphaValue = 0.01;
    self.inputProxy.editable = YES; self.inputProxy.selectable = YES; self.inputProxy.richText = NO; self.inputProxy.usesRuler = NO;
    // This is a plain-text IME adapter, not a document editor surface. The
    // system's whole-document spelling/grammar/substitution passes add work
    // to every insert without contributing to the rendered projection or its
    // owner. Keep NSTextInputClient itself intact for marked text and
    // candidates, but disable those independent analysis features.
    self.inputProxy.continuousSpellCheckingEnabled = NO;
    self.inputProxy.grammarCheckingEnabled = NO;
    // Undo/redo belongs to the Cangjie document owner. Retaining an AppKit
    // undo snapshot as well duplicates a long plain-text document for every
    // keystroke and creates a second, non-authoritative history.
    self.inputProxy.allowsUndo = NO;
    self.inputProxy.automaticSpellingCorrectionEnabled = NO;
    self.inputProxy.automaticTextReplacementEnabled = NO;
    self.inputProxy.automaticQuoteSubstitutionEnabled = NO;
    self.inputProxy.automaticDashSubstitutionEnabled = NO;
    self.inputProxy.textContainer.widthTracksTextView = YES;
    self.inputProxy.textContainer.lineFragmentPadding = 0.0;
    self.inputProxy.textContainer.maximumNumberOfLines = 1;
    self.inputProxy.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    self.inputProxy.layoutManager.allowsNonContiguousLayout = YES;
    // The hidden input adapter has no pixels of its own to keep warm. Its
    // layout is requested explicitly by the composable viewport, candidate
    // and scroll paths; background realization here only competes with the
    // next input transaction.
    self.inputProxy.layoutManager.backgroundLayoutEnabled = NO;
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace = [[CJGuiInternalComposableActiveLayoutTrace alloc] init];
    self.testInputCallbackTrace = [[CJGuiInternalComposableInputCallbackTrace alloc] init];
    self.testUsesBoundedInputLayout = NO;
#endif
    self.inputScrollProxy.documentView = self.inputProxy;
    [self addSubview:self.inputScrollProxy];
    return self;
}
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (NSAccessibilityRole)accessibilityRole { return NSAccessibilityGroupRole; }
- (NSString *)accessibilityLabel { return @"CJGUI composable scene"; }
- (NSArray<id> *)accessibilityChildren { return [self.accessibilityActions copy]; }
- (CJGuiInternalComposableSceneNode *)accessibilityLiveNodeForNode:(CJGuiInternalComposableSceneNode *)node {
    if (!node) return nil;
    for (CJGuiInternalComposableSceneNode *candidate in self.nodes) {
        if (candidate.node.nodeId == node.node.nodeId && candidate.node.resourceId == node.node.resourceId &&
            candidate.node.nodeKind == node.node.nodeKind &&
            candidate.node.projectionVersion == node.node.projectionVersion &&
            CjguiComposableNodeIsAccessibilityElement(candidate)) {
            return candidate;
        }
    }
    return nil;
}
- (BOOL)accessibilityNodeIsActionable:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableSceneNode *live = [self accessibilityLiveNodeForNode:node];
    if (!live || live.node.isInteractive == 0 || live.node.isReadOnly != 0) return NO;
    uint32_t kind = live.node.nodeKind;
    if (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT &&
        !CjguiComposableNodeIsTextInput(kind)) return NO;
    // Modal focus is established by the Cangjie layer owner when its scene is
    // committed. An AX action may not bypass that visible input boundary to
    // operate a covered base-layer control.
    CJGuiInternalComposableSceneNode *active = [self activeFocusableNode];
    if (active && active.node.inputScope != 0 && live.node.inputScope != active.node.inputScope) return NO;
    return YES;
}
- (BOOL)accessibilityNodeIsFocused:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableSceneNode *live = [self accessibilityLiveNodeForNode:node];
    if (!live) return NO;
    BOOL isActive = live.node.nodeId == self.activeNodeId && live.node.resourceId == self.activeNodeResourceId &&
        live.node.nodeKind == self.activeNodeKind && live.node.projectionVersion == self.activeProjectionVersion;
    if (!isActive) return NO;
    if (CjguiComposableNodeIsTextInput(live.node.nodeKind)) return self.window.firstResponder == self.inputProxy;
    return self.window.firstResponder == self;
}
- (NSString *)accessibilityCurrentTextForNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableSceneNode *live = [self accessibilityLiveNodeForNode:node];
    if (!live) return @"";
    if ([self accessibilityNodeIsFocused:live]) return self.inputProxy.string ?: @"";
    return live.value ?: @"";
}
- (BOOL)accessibilityPerformPressForNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableSceneNode *live = [self accessibilityLiveNodeForNode:node];
    if (!live || ![self accessibilityNodeIsActionable:live]) return NO;
    uint32_t kind = live.node.nodeKind;
    if (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) return NO;
    [self mouseDownForNode:live];
    return YES;
}
- (void)accessibilitySetValue:(id)value forNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableSceneNode *live = [self accessibilityLiveNodeForNode:node];
    if (!live || ![self accessibilityNodeIsActionable:live]) return;
    if (live.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) {
        BOOL enabled = [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : [value isEqual:@"true"];
        (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED,
                                                live.index, enabled ? @"true" : @"false", NSMakeRange(0, 0));
        [self postAccessibilityValueChangedForNode:live];
    } else if (CjguiComposableNodeIsTextInput(live.node.nodeKind) && [value isKindOfClass:[NSString class]]) {
        [self setText:(NSString *)value forNode:live];
        [self postAccessibilityValueChangedForNode:live];
        [self postAccessibilitySelectionChangedForNode:live];
    }
}
- (void)accessibilitySetSelectedTextRange:(NSRange)range forNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableSceneNode *live = [self accessibilityLiveNodeForNode:node];
    if (!live || !CjguiComposableNodeIsTextInput(live.node.nodeKind) || live.node.isInteractive == 0) return;
    [self focusNode:live enqueue:NO];
    self.inputProxy.selectedRange = CjguiComposedSelection(self.inputProxy.string, range.location, NSMaxRange(range));
    [self refreshGpuTextForActiveInput];
    (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                            live.index, @"", self.inputProxy.selectedRange);
    [self postAccessibilitySelectionChangedForNode:live];
}
- (CJGuiInternalComposableAccessibilityAction *)accessibilityActionForNode:(CJGuiInternalComposableSceneNode *)node {
    for (CJGuiInternalComposableAccessibilityAction *action in self.accessibilityActions) {
        if ([self accessibilityLiveNodeForNode:action.node] == node) return action;
    }
    return nil;
}
- (void)postAccessibilityValueChangedForNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableAccessibilityAction *action = [self accessibilityActionForNode:node];
    if (action) {
        NSAccessibilityPostNotification(action, NSAccessibilityValueChangedNotification);
#ifdef CJGUI_INTERNAL_TESTING
        self.session.testComposableAccessibilityNotificationCount += 1;
#endif
    }
}
- (void)postAccessibilitySelectionChangedForNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableAccessibilityAction *action = [self accessibilityActionForNode:node];
    if (action) {
        NSAccessibilityPostNotification(action, NSAccessibilitySelectedTextChangedNotification);
#ifdef CJGUI_INTERNAL_TESTING
        self.session.testComposableAccessibilityNotificationCount += 1;
#endif
    }
}
- (void)postAccessibilityFocusChangedForNode:(CJGuiInternalComposableSceneNode *)node {
    CJGuiInternalComposableAccessibilityAction *action = [self accessibilityActionForNode:node];
    if (action) NSAccessibilityPostNotification(action, NSAccessibilityFocusedUIElementChangedNotification);
    else NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
#ifdef CJGUI_INTERNAL_TESTING
    self.session.testComposableAccessibilityNotificationCount += 1;
#endif
}
- (NSString *)multilineLayoutIdentityForNode:(CJGuiInternalComposableSceneNode *)node {
    return [NSString stringWithFormat:@"%llu:%lld:%u",
            node.node.nodeId, node.node.resourceId, node.node.nodeKind];
}
- (NSString *)multilineLayoutCacheKeyForNode:(CJGuiInternalComposableSceneNode *)node
                                        value:(NSString *)value
                                 contentWidth:(CGFloat)contentWidth {
    CjguiInternalRendererComposableNode style = node.node;
    (void)value;
    // Cache ownership follows the stable component identity and layout
    // inputs, not a complete text snapshot. A new projection value is
    // applied to the retained NSTextStorage below; including the full value
    // here used to retain a history of whole documents and rebuild TextKit on
    // every sparse external replacement.
    return [NSString stringWithFormat:@"%@:%.3f:%.3f:%u:%u:%.3f:%.3f:%.3f:%.3f",
            [self multilineLayoutIdentityForNode:node],
            contentWidth, style.fontSize, style.fontWeight, style.fontFamily,
            style.textRed, style.textGreen, style.textBlue, style.textAlpha];
}
- (NSString *)activeTextLayoutSignatureForNode:(CJGuiInternalComposableSceneNode *)node contentWidth:(CGFloat)contentWidth {
    CjguiInternalRendererComposableNode value = node.node;
    return [NSString stringWithFormat:@"%llu:%lld:%u:%.3f:%.3f:%u:%u:%.3f:%.3f:%.3f:%.3f",
            value.nodeId, value.resourceId, value.nodeKind, contentWidth, value.fontSize,
            value.fontWeight, value.fontFamily, value.textRed, value.textGreen, value.textBlue, value.textAlpha];
}
- (void)touchMultilineLayoutCacheKey:(NSString *)key {
    [self.multilineLayoutCacheOrder removeObject:key];
    [self.multilineLayoutCacheOrder addObject:key];
}
- (CJGuiInternalComposableMultilineLayoutCacheEntry *)cachedMultilineLayoutForNode:(CJGuiInternalComposableSceneNode *)node
                                                                               value:(NSString *)value
                                                                          attributes:(NSDictionary *)attributes
                                                                        contentWidth:(CGFloat)contentWidth {
    NSString *key = [self multilineLayoutCacheKeyForNode:node value:value contentWidth:contentWidth];
    CJGuiInternalComposableMultilineLayoutCacheEntry *entry = self.multilineLayoutCache[key];
    if (entry && fabs(entry.contentWidth - contentWidth) < 0.01) {
        if (![entry.value isEqualToString:value]) {
            // The node is inactive, so it has no native text-service state
            // to reconcile. Preserve its TextKit object graph and invalidate
            // only its storage content; visible glyphs are realized lazily by
            // draw, while an explicit focus/scroll query establishes an exact
            // document extent through the active path.
            [entry.storage beginEditing];
            [entry.storage replaceCharactersInRange:NSMakeRange(0, entry.storage.length) withString:value];
            if (value.length > 0) [entry.storage setAttributes:attributes range:NSMakeRange(0, value.length)];
            [entry.storage endEditing];
            entry.value = value;
        }
        [self touchMultilineLayoutCacheKey:key];
        return entry;
    }
    if (entry) {
        [self.multilineLayoutCache removeObjectForKey:key];
        [self.multilineLayoutCacheOrder removeObject:key];
    }
    while (self.multilineLayoutCacheOrder.count >= 16) {
        NSString *oldest = self.multilineLayoutCacheOrder.firstObject;
        [self.multilineLayoutCacheOrder removeObjectAtIndex:0];
        [self.multilineLayoutCache removeObjectForKey:oldest];
    }
    entry = [[CJGuiInternalComposableMultilineLayoutCacheEntry alloc] init];
    entry.value = value;
    entry.contentWidth = contentWidth;
    entry.storage = [[NSTextStorage alloc] initWithString:value attributes:attributes];
    entry.layoutManager = [[NSLayoutManager alloc] init];
    entry.layoutManager.allowsNonContiguousLayout = YES;
    entry.container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(contentWidth, CGFLOAT_MAX)];
    entry.container.lineFragmentPadding = 0.0;
    [entry.layoutManager addTextContainer:entry.container];
    [entry.storage addLayoutManager:entry.layoutManager];
    [entry.layoutManager ensureLayoutForTextContainer:entry.container];
    entry.maximumScroll = MAX(0.0, [entry.layoutManager usedRectForTextContainer:entry.container].size.height);
    self.multilineLayoutBuildCount += 1;
    self.multilineLayoutFullLayoutCount += 1;
    self.multilineLayoutCache[key] = entry;
    [self touchMultilineLayoutCacheKey:key];
    self.multilineLayoutCacheHighWater = (uint32_t)MIN(MAX((NSUInteger)self.multilineLayoutCacheHighWater,
                                                            self.multilineLayoutCache.count), UINT32_MAX);
    return entry;
}
- (void)setNodesFromProjection:(NSArray<CJGuiInternalComposableSceneNode *> *)nodes {
    CJGuiInternalComposableSceneNode *previousActive = nil;
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeId == self.activeNodeId && node.node.resourceId == self.activeNodeResourceId &&
            node.node.nodeKind == self.activeNodeKind) {
            previousActive = node; break;
        }
    }
    NSArray<CJGuiInternalComposableSceneNode *> *nextNodes = [nodes copy] ?: @[];
    // Keep AX element identity when the interactive tree is structurally the
    // same. Values, bounds and versions are refreshed below; allocations and
    // child replacement are reserved for real add/remove/reorder changes.
    NSUInteger expectedActions = 0;
    for (CJGuiInternalComposableSceneNode *node in nextNodes) if (CjguiComposableNodeIsAccessibilityElement(node)) expectedActions += 1;
    BOOL sameAccessibilityStructure = expectedActions == self.accessibilityActions.count;
    if (sameAccessibilityStructure) {
        NSUInteger actionIndex = 0;
        for (CJGuiInternalComposableSceneNode *node in nextNodes) {
            if (!CjguiComposableNodeIsAccessibilityElement(node)) continue;
            CJGuiInternalComposableAccessibilityAction *existing = self.accessibilityActions[actionIndex++];
            if (existing.node.node.nodeId != node.node.nodeId ||
                existing.node.node.resourceId != node.node.resourceId ||
                existing.node.node.nodeKind != node.node.nodeKind) {
                sameAccessibilityStructure = NO; break;
            }
        }
    }
    self.nodes = nextNodes;
    // A replacement projection may delete, disable or rebind the captured
    // target. Native then releases platform routing immediately; Cangjie
    // reconciles and emits the owner-visible cancel from its retained stable
    // capture record, so no raw native object crosses that boundary.
    if (self.pointerCaptureActive && ![self capturedPointerNode]) {
        [self cancelPointerCapture];
    }
    // Scroll offsets are local interaction state. Once a multiline identity
    // leaves the projection it must not keep a stale entry alive, nor be
    // available to a later component that merely reuses its node id.
    NSMutableSet<NSString *> *liveViewportKeys = [NSMutableSet set];
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
            [liveViewportKeys addObject:[self multilineViewportKeyForNode:node]];
        }
    }
    for (NSString *key in [self.multilineScrollOffsets.allKeys copy]) {
        if (![liveViewportKeys containsObject:key]) [self.multilineScrollOffsets removeObjectForKey:key];
    }
    NSMutableSet<NSString *> *liveLayoutIdentities = [NSMutableSet set];
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
            [liveLayoutIdentities addObject:[self multilineLayoutIdentityForNode:node]];
        }
    }
    for (NSString *key in [self.multilineLayoutCache.allKeys copy]) {
        BOOL hasLiveIdentity = NO;
        for (NSString *identity in liveLayoutIdentities) {
            if ([key hasPrefix:[NSString stringWithFormat:@"%@:", identity]]) {
                hasLiveIdentity = YES;
                break;
            }
        }
        if (!hasLiveIdentity) {
            [self.multilineLayoutCache removeObjectForKey:key];
            [self.multilineLayoutCacheOrder removeObject:key];
        }
    }
    if (sameAccessibilityStructure) {
        NSUInteger actionIndex = 0;
        for (CJGuiInternalComposableSceneNode *node in self.nodes) {
            if (!CjguiComposableNodeIsAccessibilityElement(node)) continue;
            CJGuiInternalComposableAccessibilityAction *action = self.accessibilityActions[actionIndex++];
            BOOL changedValue = ![action.node.value isEqualToString:node.value] ||
                action.node.node.isReadOnly != node.node.isReadOnly || action.node.node.isInteractive != node.node.isInteractive;
            action.node = node;
            if (changedValue) {
                NSAccessibilityPostNotification(action, NSAccessibilityValueChangedNotification);
#ifdef CJGUI_INTERNAL_TESTING
                self.session.testComposableAccessibilityNotificationCount += 1;
#endif
            }
        }
    } else {
        [self.accessibilityActions removeAllObjects];
        for (CJGuiInternalComposableSceneNode *node in self.nodes) {
            if (CjguiComposableNodeIsAccessibilityElement(node)) [self.accessibilityActions addObject:[[CJGuiInternalComposableAccessibilityAction alloc] initWithOverlay:self node:node]];
        }
    }
    if (self.activeNodeId != 0) {
        CJGuiInternalComposableSceneNode *replacement = nil;
        for (CJGuiInternalComposableSceneNode *node in self.nodes) {
            if (node.node.nodeId == self.activeNodeId && node.node.resourceId == self.activeNodeResourceId &&
                node.node.nodeKind == self.activeNodeKind) { replacement = node; break; }
        }
        // A disabled projection may retain its identity for layout purposes,
        // but it is no longer a valid TextKit target. Treat it as a focus
        // removal so pending marked text cannot later commit into a disabled
        // owner.
        if (replacement && replacement.node.isInteractive == 0) replacement = nil;
        if (replacement) {
            self.activeNodeIndex = replacement.index;
            self.activeProjectionVersion = replacement.node.projectionVersion;
            self.activeNodeResourceId = replacement.node.resourceId;
            self.activeNodeKind = replacement.node.nodeKind;
            [self positionInputProxyForNode:replacement];
            if (CjguiComposableNodeIsTextInput(replacement.node.nodeKind)) {
                self.inputProxy.editable = replacement.node.isReadOnly == 0;
                self.inputProxy.selectable = YES;
            }
            self.multilineScrollOffset = [self multilineScrollOffsetForNode:replacement];
            NSString *replacementValue = replacement.value ?: @"";
            BOOL preservesActiveLocalText = replacement.node.preservesActiveLocalText != 0 && previousActive &&
                previousActive.node.nodeId == replacement.node.nodeId &&
                previousActive.node.resourceId == replacement.node.resourceId &&
                previousActive.node.nodeKind == replacement.node.nodeKind &&
                replacement.node.nodeId == self.activeNodeId &&
                replacement.node.resourceId == self.activeNodeResourceId &&
                replacement.node.nodeKind == self.activeNodeKind &&
                CjguiComposableNodeIsTextInput(replacement.node.nodeKind);
            if (preservesActiveLocalText) {
                // Record the current proxy value as the new projection
                // baseline. The Cangjie owner already checked that its
                // accepted value matches this local event, so a later
                // external replacement still compares against this text.
                replacement.value = self.inputProxy.string ?: @"";
                replacementValue = replacement.value;
            }
            BOOL hasLocalText = previousActive && ![self.inputProxy.string isEqualToString:previousActive.value ?: @""];
            BOOL externalValueChanged = !preservesActiveLocalText && previousActive &&
                ![replacementValue isEqualToString:previousActive.value ?: @""];
            BOOL compositionMustCancel = self.inputProxy.hasMarkedText &&
                (externalValueChanged || replacement.node.isReadOnly != 0 || replacement.node.isInteractive == 0);
            if (compositionMustCancel) {
                // Marked text belongs to the platform composition, not the
                // Cangjie domain. A newer value for this same identity is an
                // external replacement, so retaining the preedit would let
                // a later commit overwrite truth that the proxy no longer
                // represents. Cancel it under projection suppression, then
                // adopt the owner's value without enqueuing a human edit.
                self.applyingProjection = YES;
                [(CJGuiInternalComposableInputProxy *)self.inputProxy cancelMarkedText];
                self.inputProxy.string = replacementValue;
                NSUInteger start = MIN(self.inputProxy.selectedRange.location, self.inputProxy.string.length);
                NSUInteger end = MIN(NSMaxRange(self.inputProxy.selectedRange), self.inputProxy.string.length);
                self.inputProxy.selectedRange = NSMakeRange(start, end - start);
                self.applyingProjection = NO;
                self.activeTextLayoutSignature = nil;
                if (replacement.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
                    self.activeTextFallbackHasPendingEdit = NO;
                    [self markActiveTextFallbackRunsDirtyForWholeValue];
                }
                self.activeTextLayoutNeedsVisibleGlyphs = YES;
                self.activeTextHasExactContentHeight = NO;
                self.activeTextKnownContentHeight = 0.0;
                [self postAccessibilityValueChangedForNode:replacement];
                [self postAccessibilitySelectionChangedForNode:replacement];
            // A newer owner projection wins even when the proxy has an
            // unpumped local edit. That edit still carries the old rendered
            // version and will be rejected by Cangjie; retaining it here
            // would leave the platform adapter detached from authoritative
            // text until another edit happens.
            } else if ((externalValueChanged || !hasLocalText) && !self.inputProxy.hasMarkedText) {
                self.applyingProjection = YES;
                BOOL textChanged = ![self.inputProxy.string isEqualToString:replacementValue];
                if (textChanged) self.inputProxy.string = replacementValue;
                NSUInteger start = MIN(self.inputProxy.selectedRange.location, self.inputProxy.string.length);
                NSUInteger end = MIN(NSMaxRange(self.inputProxy.selectedRange), self.inputProxy.string.length);
                self.inputProxy.selectedRange = NSMakeRange(start, end - start);
                self.applyingProjection = NO;
                if (textChanged) {
                    self.activeTextLayoutSignature = nil;
                    if (replacement.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
                        self.activeTextFallbackHasPendingEdit = NO;
                        [self markActiveTextFallbackRunsDirtyForWholeValue];
                    }
                    self.activeTextLayoutNeedsVisibleGlyphs = YES;
                    self.activeTextHasExactContentHeight = NO;
                    self.activeTextKnownContentHeight = 0.0;
                }
            }
        } else {
            self.activeNodeIndex = NSNotFound; self.activeNodeId = 0; self.activeProjectionVersion = 0;
            self.activeNodeResourceId = -1; self.activeNodeKind = 0;
            [self clearDraggingSelection];
            self.applyingProjection = YES;
            if (self.inputProxy.hasMarkedText) [(CJGuiInternalComposableInputProxy *)self.inputProxy cancelMarkedText];
            self.inputProxy.string = @""; self.inputProxy.selectedRange = NSMakeRange(0, 0);
            self.applyingProjection = NO;
            self.activeTextLayoutSignature = nil;
            self.activeTextFallbackRunsDirty = NO;
            self.activeTextFallbackNeedsFullRefresh = NO;
            self.activeTextFallbackHasDirtyRange = NO;
            self.activeTextFallbackHasPendingEdit = NO;
            self.activeTextBaseFont = nil;
            self.inputProxyAssignedBaseFont = nil;
            self.activeTextTextureRetryKey = nil;
            self.activeTextTextureRetryCount = 0;
            self.activeTextTexturePreparationFailed = NO;
            self.activeTextLayoutNeedsVisibleGlyphs = NO;
            self.activeTextHasExactContentHeight = NO;
            self.activeTextKnownContentHeight = 0.0;
            [self.window makeFirstResponder:nil];
            [self postAccessibilityFocusChangedForNode:nil];
        }
    }
    [self refreshGpuTextForActiveInput];
    [self setNeedsDisplay:YES];
}
- (CJGuiInternalComposableSceneNode *)nodeAtPoint:(NSPoint)point {
    for (CJGuiInternalComposableSceneNode *node in [self.nodes reverseObjectEnumerator]) {
        if (node.node.isInteractive && NSPointInRect(point, CjguiComposableRect(node, self)) &&
            CjguiPointInComposableNodeClip(point, node, self)) return node;
    }
    return nil;
}
- (BOOL)focusCommittedNodeId:(uint64_t)nodeId {
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeId == nodeId && node.node.isInteractive != 0 &&
            node.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA) {
            [self focusNode:node enqueue:NO];
            return YES;
        }
    }
    return NO;
}
- (CJGuiInternalComposableSceneNode *)scrollNodeContainingPoint:(NSPoint)point {
    // A list row is normally painted above its scroll container.  Mouse
    // target lookup may therefore find the row, while scroll ownership still
    // belongs to the containing scroll region from the same scene snapshot.
    for (CJGuiInternalComposableSceneNode *node in [self.nodes reverseObjectEnumerator]) {
        if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA &&
            NSPointInRect(point, CjguiComposableRect(node, self)) &&
            CjguiPointInComposableNodeClip(point, node, self)) return node;
    }
    return nil;
}
- (void)routeScrollAtPoint:(NSPoint)point deltaY:(CGFloat)deltaY {
    if (deltaY == 0.0) return;
    CJGuiInternalComposableSceneNode *scrollNode = [self scrollNodeContainingPoint:point];
    if (scrollNode) {
        (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL,
                                                scrollNode.index, deltaY < 0.0 ? @"next" : @"previous", NSMakeRange(0, 0));
    }
}
- (void)prepareInactiveTextResourceForFocusChange:(CJGuiInternalComposableSceneNode *)node {
    if (!node || !CjguiComposableNodeUsesGpuText(node.node.nodeKind)) return;
    CjguiClearComposableTextDecorations(node);
    NSString *displayText = CjguiComposableGpuTextValue(node);
    if (displayText.length == 0 || node.node.textAlpha <= 0.0) {
        node.textTexture = nil;
        node.textTextureCacheKey = @"";
        node.textTextureByteCount = 0;
        node.textTextureRect = NSZeroRect;
        return;
    }
    CJGuiInternalMetalView *metalView = self.session.view;
    if (!metalView) return;
    CGFloat scale = metalView.window ? metalView.window.backingScaleFactor : NSScreen.mainScreen.backingScaleFactor;
    scale = MAX(1.0, scale);
    // Focus is a visible-state boundary. Convert the old active resource to
    // its caret-free static form now, rather than charging that work to a
    // later owner acknowledgement for a different input.
    (void)CjguiComposableTextTexture(metalView, node, scale, scale, displayText
#ifdef CJGUI_INTERNAL_TESTING
                                      , CjguiInternalTextWorkReasonStaticCandidate
#endif
                                      );
}
- (void)focusNode:(CJGuiInternalComposableSceneNode *)node enqueue:(BOOL)enqueue {
    BOOL isSameNode = self.activeNodeId == node.node.nodeId && self.activeNodeResourceId == node.node.resourceId &&
        self.activeNodeKind == node.node.nodeKind;
    CJGuiInternalComposableSceneNode *previousActive = nil;
    if (!isSameNode) {
        for (CJGuiInternalComposableSceneNode *candidate in self.nodes) {
            if (candidate.node.nodeId == self.activeNodeId && candidate.node.resourceId == self.activeNodeResourceId &&
                candidate.node.nodeKind == self.activeNodeKind) {
                previousActive = candidate;
                break;
            }
        }
        [self prepareInactiveTextResourceForFocusChange:previousActive];
    }
    uint32_t kind = node.node.nodeKind;
    BOOL isTextInput = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    BOOL isMultiline = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    self.activeNodeIndex = node.index; self.activeNodeId = node.node.nodeId; self.activeProjectionVersion = node.node.projectionVersion;
    self.activeNodeResourceId = node.node.resourceId; self.activeNodeKind = kind;
    if (!isTextInput) {
        if (self.inputProxy.hasMarkedText) {
            self.applyingProjection = YES;
            [(CJGuiInternalComposableInputProxy *)self.inputProxy cancelMarkedText];
            self.applyingProjection = NO;
        }
        [self clearDraggingSelection];
        [self.window makeFirstResponder:self];
        if (enqueue) (void)CjguiEnqueueComposableInteraction(self.session,
                                                              CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS,
                                                              node.index, @"", NSMakeRange(0, 0));
        [self postAccessibilityFocusChangedForNode:node];
        [self setNeedsDisplay:YES];
        return;
    }
    self.applyingProjection = YES;
    self.inputProxy.textContainer.maximumNumberOfLines = isMultiline ? 0 : 1;
    self.inputProxy.textContainer.lineBreakMode = isMultiline ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
    self.inputProxy.verticallyResizable = NO;
    self.inputProxy.horizontallyResizable = NO;
    self.inputProxy.editable = node.node.isReadOnly == 0;
    self.inputProxy.selectable = YES;
    // Never let AppKit's text/scroll controls become an independent visual
    // surface. They remain first-responder/IME adapters only; drawRect owns
    // both inactive and active document rows from the composable snapshot.
    self.inputScrollProxy.alphaValue = 0.01;
    self.inputProxy.alphaValue = 0.01;
    self.inputProxy.textColor = [NSColor colorWithSRGBRed:node.node.textRed
                                                    green:node.node.textGreen
                                                    blue:node.node.textBlue
                                                    alpha:node.node.textAlpha];
    if (!isSameNode) {
        if (self.inputProxy.hasMarkedText) [(CJGuiInternalComposableInputProxy *)self.inputProxy cancelMarkedText];
        self.inputProxy.string = node.value ?: @""; self.inputProxy.selectedRange = NSMakeRange(self.inputProxy.string.length, 0);
        self.activeTextLayoutSignature = nil;
        self.activeTextFallbackHasPendingEdit = NO;
        self.activeTextBaseFont = nil;
        self.inputProxyAssignedBaseFont = nil;
        self.activeTextTextureRetryKey = nil;
        self.activeTextTextureRetryCount = 0;
        self.activeTextTexturePreparationFailed = NO;
        [self markActiveTextFallbackRunsDirtyForWholeValue];
        self.activeTextLayoutNeedsVisibleGlyphs = YES;
        self.activeTextHasExactContentHeight = NO;
        self.activeTextKnownContentHeight = 0.0;
    }
    self.multilineScrollOffset = [self multilineScrollOffsetForNode:node];
    [self positionInputProxyForNode:node];
    [self.window makeFirstResponder:self.inputProxy]; self.applyingProjection = NO;
    if (enqueue) (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, node.index, self.inputProxy.string, self.inputProxy.selectedRange);
    [self postAccessibilityFocusChangedForNode:node];
#ifdef CJGUI_INTERNAL_TESTING
    // A focus hand-off can change only caret/selection pixels. It is neither
    // content admission nor an unknown background refresh.
    self.testActiveTextWorkReason = CjguiInternalTextWorkReasonSelectionCaret;
#endif
    [self refreshGpuTextForActiveInput];
    [self setNeedsDisplay:YES];
}
- (NSString *)multilineViewportKeyForNode:(CJGuiInternalComposableSceneNode *)node {
    return [NSString stringWithFormat:@"%llu:%lld", node.node.nodeId, node.node.resourceId];
}
- (CGFloat)multilineScrollOffsetForNode:(CJGuiInternalComposableSceneNode *)node {
    NSNumber *value = self.multilineScrollOffsets[[self multilineViewportKeyForNode:node]];
    return value ? value.doubleValue : 0.0;
}
- (void)setMultilineScrollOffset:(CGFloat)offset forNode:(CJGuiInternalComposableSceneNode *)node {
    self.multilineScrollOffsets[[self multilineViewportKeyForNode:node]] = @(MAX(0.0, offset));
    if (node.node.nodeId == self.activeNodeId && node.node.resourceId == self.activeNodeResourceId &&
        node.node.nodeKind == self.activeNodeKind) {
        self.multilineScrollOffset = MAX(0.0, offset);
    }
}
- (void)ensureActiveLayoutForCharacterRange:(NSRange)range layoutManager:(NSLayoutManager *)layoutManager {
    if (!layoutManager || range.location == NSNotFound) return;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
    self.activeTextLayoutTrace.firstUnlaidBefore = (uint64_t)layoutManager.firstUnlaidCharacterIndex;
#endif
    [layoutManager ensureLayoutForCharacterRange:range];
    self.activeTextRangeLayoutCount += 1;
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.characterEnsureCount += 1;
    self.activeTextLayoutTrace.characterEnsureMicros += CjguiMonotonicMicros() - started;
    self.activeTextLayoutTrace.firstUnlaidAfter = (uint64_t)layoutManager.firstUnlaidCharacterIndex;
#endif
}
- (void)ensureActiveLayoutForBoundingRect:(NSRect)rect container:(NSTextContainer *)container layoutManager:(NSLayoutManager *)layoutManager {
    if (!layoutManager || !container || NSIsEmptyRect(rect)) return;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    [layoutManager ensureLayoutForBoundingRect:rect inTextContainer:container];
    self.activeTextRangeLayoutCount += 1;
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.boundingEnsureCount += 1;
    self.activeTextLayoutTrace.boundingEnsureMicros += CjguiMonotonicMicros() - started;
#endif
}
- (void)ensureActiveFullLayoutForContainer:(NSTextContainer *)container layoutManager:(NSLayoutManager *)layoutManager {
    if (!layoutManager || !container) return;
    [layoutManager ensureLayoutForTextContainer:container];
    self.activeTextFullLayoutCount += 1;
}
- (NSUInteger)activeGlyphIndexForCharacter:(NSUInteger)character layoutManager:(NSLayoutManager *)layoutManager {
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    NSUInteger glyph = [layoutManager glyphIndexForCharacterAtIndex:character];
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.glyphIndexCount += 1;
    self.activeTextLayoutTrace.glyphIndexMicros += CjguiMonotonicMicros() - started;
#endif
    return glyph;
}
- (NSRect)activeLineFragmentForGlyph:(NSUInteger)glyph layoutManager:(NSLayoutManager *)layoutManager {
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    NSRect line = [layoutManager lineFragmentRectForGlyphAtIndex:glyph effectiveRange:NULL];
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.lineFragmentCount += 1;
    self.activeTextLayoutTrace.lineFragmentMicros += CjguiMonotonicMicros() - started;
#endif
    return line;
}
- (NSPoint)activeGlyphLocation:(NSUInteger)glyph layoutManager:(NSLayoutManager *)layoutManager {
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    NSPoint location = [layoutManager locationForGlyphAtIndex:glyph];
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.glyphLocationCount += 1;
    self.activeTextLayoutTrace.glyphLocationMicros += CjguiMonotonicMicros() - started;
#endif
    return location;
}
- (void)positionInputProxyForNode:(CJGuiInternalComposableSceneNode *)node {
    if (!node) return;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    NSRect textRect = NSInsetRect(CjguiComposableRect(node, self), 7.0, 6.0);
    CGFloat width = MAX(1.0, NSWidth(textRect));
    CGFloat height = MAX(1.0, NSHeight(textRect));
    BOOL isMultiline = node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    NSRect proxyFrame = NSMakeRect(0, 0, width, height);
    NSSize containerSize = NSMakeSize(width, isMultiline ? CGFLOAT_MAX : height);
    NSFont *font = CjguiComposableFont(node);
    NSRect parkedProxyFrame = NSMakeRect(-2.0, -2.0, 1.0, 1.0);
    BOOL sameScrollFrame = NSEqualRects(self.inputScrollProxy.frame, parkedProxyFrame);
    BOOL sameMaximumLines = self.inputProxy.textContainer.maximumNumberOfLines == (isMultiline ? 0 : 1);
    BOOL sameLineBreak = self.inputProxy.textContainer.lineBreakMode == (isMultiline ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail);
    BOOL sameContainerSize = NSEqualSizes(self.inputProxy.textContainer.containerSize, containerSize);
    BOOL sameHeightTracks = self.inputProxy.textContainer.heightTracksTextView == !isMultiline;
    BOOL sameMinSize = NSEqualSizes(self.inputProxy.minSize, NSMakeSize(width, height));
    BOOL sameMaxSize = NSEqualSizes(self.inputProxy.maxSize, NSMakeSize(width, height));
    BOOL sameProxyFrame = NSEqualRects(self.inputProxy.frame, proxyFrame);
    BOOL sameFont = [self.inputProxy.font isEqual:font];
    // NSTextView's font getter can report the first character's resolved
    // fallback (for example PingFang) rather than the style base (system
    // font).  Once the active multiline document has established that base,
    // treating that expected getter difference as a reason to assign `font`
    // again replaces every per-character fallback run just after a local
    // owner acknowledgement.  Preserve those runs only when both the active
    // layout base and the last deliberately assigned proxy base match.  The
    // second condition keeps a real style change visible even if preparation
    // has already adopted its new active base; initial focus, a rebind, an
    // empty field, and a style change still take the normal assignment path.
    BOOL proxyBaseMatches = self.inputProxyAssignedBaseFont && [self.inputProxyAssignedBaseFont isEqual:font];
    BOOL preservesActiveMultilineFontRuns = isMultiline && self.inputProxy.textStorage.length > 0 &&
        self.activeTextBaseFont && [self.activeTextBaseFont isEqual:font] && proxyBaseMatches;
    BOOL needsFontAssignment = !sameFont && !preservesActiveMultilineFontRuns;
    if (isMultiline && !proxyBaseMatches) needsFontAssignment = YES;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t sameWrites = (sameScrollFrame ? 1 : 0) + (sameMaximumLines ? 1 : 0) +
        (sameLineBreak ? 1 : 0) + (sameContainerSize ? 1 : 0) + (sameHeightTracks ? 1 : 0) +
        (sameMinSize ? 1 : 0) + (sameMaxSize ? 1 : 0) + (sameProxyFrame ? 1 : 0) + (needsFontAssignment ? 0 : 1);
    uint64_t changedMask = (sameScrollFrame ? 0 : 1) | (sameMaximumLines ? 0 : 2) |
        (sameLineBreak ? 0 : 4) | (sameContainerSize ? 0 : 8) | (sameHeightTracks ? 0 : 16) |
        (sameMinSize ? 0 : 32) | (sameMaxSize ? 0 : 64) | (sameProxyFrame ? 0 : 128) | (needsFontAssignment ? 256 : 0);
    self.activeTextLayoutTrace.positionFirstUnlaidBefore = (uint64_t)self.inputProxy.layoutManager.firstUnlaidCharacterIndex;
#endif
    // Keep the input view attached (and therefore eligible for the macOS
    // text service) without laying it out as a second, visible editor.
    if (!sameScrollFrame) self.inputScrollProxy.frame = parkedProxyFrame;
    if (!sameMaximumLines) self.inputProxy.textContainer.maximumNumberOfLines = isMultiline ? 0 : 1;
    if (!sameLineBreak) self.inputProxy.textContainer.lineBreakMode = isMultiline ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
    if (!sameContainerSize) self.inputProxy.textContainer.containerSize = containerSize;
    if (!sameHeightTracks) self.inputProxy.textContainer.heightTracksTextView = !isMultiline;
    if (!sameMinSize) self.inputProxy.minSize = NSMakeSize(width, height);
    if (!sameMaxSize) self.inputProxy.maxSize = NSMakeSize(width, height);
    if (!sameProxyFrame) self.inputProxy.frame = proxyFrame;
    if (needsFontAssignment) {
        self.inputProxy.font = font;
        if (isMultiline) self.inputProxyAssignedBaseFont = font;
    }
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.positionProxyMicros += CjguiMonotonicMicros() - started;
    self.activeTextLayoutTrace.positionNoopWrites += sameWrites;
    self.activeTextLayoutTrace.positionChangedWrites += 9 - sameWrites;
    self.activeTextLayoutTrace.positionFirstUnlaidAfter = (uint64_t)self.inputProxy.layoutManager.firstUnlaidCharacterIndex;
    self.activeTextLayoutTrace.positionChangedMask |= changedMask;
#endif
}
- (NSRect)candidateRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
    CJGuiInternalComposableSceneNode *node = [self activeFocusableNode];
    uint32_t kind = node ? node.node.nodeKind : 0;
    BOOL isTextInput = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    if (!node || !isTextInput || !self.window) return NSZeroRect;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    [self positionInputProxyForNode:node];
    NSLayoutManager *layoutManager = self.inputProxy.layoutManager;
    NSTextContainer *container = self.inputProxy.textContainer;
    NSString *text = self.inputProxy.string ?: @"";
    NSUInteger length = text.length;
    NSUInteger location = MIN(range.location, length);
    NSUInteger requestedEnd = MIN(NSMaxRange(range), length);
    if (actualRange) *actualRange = NSMakeRange(location, requestedEnd - location);
    if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        // An IME asks for the composition/caret rectangle, which must share
        // the viewport policy with selection reveal rather than returning an
        // off-screen proxy coordinate after a remote selection.
        [self revealActiveMultilineCharacterAtLocation:location forNode:node];
    }
    NSRect content = NSInsetRect(CjguiComposableRect(node, self), 7.0, 6.0);
    CGFloat scroll = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT
        ? [self multilineScrollOffsetForNode:node] : 0.0;
    CGFloat lineHeight = MAX(1.0, [layoutManager defaultLineHeightForFont:self.inputProxy.font]);
    NSRect line = NSMakeRect(0.0, 0.0, 1.0, lineHeight);
    CGFloat caretX = 0.0;
    if (length > 0) {
        NSUInteger character = location >= length ? length - 1 : location;
        [self ensureActiveLayoutForCharacterRange:NSMakeRange(character, 1) layoutManager:layoutManager];
        if (location == length && layoutManager.extraLineFragmentTextContainer == container &&
            !NSIsEmptyRect(layoutManager.extraLineFragmentRect)) {
            line = layoutManager.extraLineFragmentRect;
            caretX = NSMinX(layoutManager.extraLineFragmentUsedRect);
        } else {
            NSUInteger glyph = [self activeGlyphIndexForCharacter:character layoutManager:layoutManager];
            line = [self activeLineFragmentForGlyph:glyph layoutManager:layoutManager];
            caretX = location >= length ? NSMaxX(line) : [self activeGlyphLocation:glyph layoutManager:layoutManager].x;
        }
    }
    NSRect overlayRect = NSMakeRect(NSMinX(content) + caretX, NSMinY(content) + NSMinY(line) - scroll,
                                    1.0, MAX(1.0, NSHeight(line)));
    NSRect windowRect = [self convertRect:overlayRect toView:nil];
    NSRect result = [self.window convertRectToScreen:windowRect];
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.candidateMicros += CjguiMonotonicMicros() - started;
#endif
    return result;
}
- (NSUInteger)characterIndexAtPoint:(NSPoint)point forNode:(CJGuiInternalComposableSceneNode *)node {
    if (!node) return 0;
    [self positionInputProxyForNode:node];
    NSLayoutManager *layoutManager = self.inputProxy.layoutManager;
    NSTextContainer *container = self.inputProxy.textContainer;
    NSRect content = NSInsetRect(CjguiComposableRect(node, self), 7.0, 6.0);
    CGFloat scroll = node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT
        ? [self multilineScrollOffsetForNode:node] : 0.0;
    NSPoint layoutPoint = NSMakePoint(point.x - NSMinX(content), point.y - NSMinY(content) + scroll);
    [self ensureActiveLayoutForBoundingRect:NSMakeRect(0.0, MAX(0.0, layoutPoint.y - 1.0),
                                                        NSWidth(content), 2.0)
                                      container:container layoutManager:layoutManager];
    CGFloat fraction = 0.0;
    NSUInteger character = [layoutManager characterIndexForPoint:layoutPoint
                                                  inTextContainer:container
                           fractionOfDistanceBetweenInsertionPoints:&fraction];
    NSUInteger length = self.inputProxy.string.length;
    if (character < length && fraction > 0.5) character += 1;
    return MIN(character, length);
}
- (void)clearDraggingSelection {
    self.draggingNodeId = 0; self.draggingNodeResourceId = -1;
    self.draggingProjectionVersion = 0; self.draggingAnchor = 0;
}
- (void)cancelPointerCapture {
    self.pointerCaptureActive = NO;
    self.pointerCaptureNodeId = 0;
    self.pointerCaptureResourceId = -1;
    self.pointerCaptureNodeKind = 0;
    self.pointerCaptureX = 0.0;
    self.pointerCaptureY = 0.0;
}

- (void)cancelPointerCaptureForPlatformLoss {
    if (self.pointerCaptureActive) {
        [self endPointerCaptureAtPoint:NSMakePoint(self.pointerCaptureX, self.pointerCaptureY) cancelled:YES];
    }
}

- (CJGuiInternalComposableSceneNode *)capturedPointerNode {
    if (!self.pointerCaptureActive || self.pointerCaptureNodeId == 0) return nil;
    for (CJGuiInternalComposableSceneNode *candidate in self.nodes) {
        if (candidate.node.nodeId == self.pointerCaptureNodeId &&
            candidate.node.resourceId == self.pointerCaptureResourceId &&
            candidate.node.nodeKind == self.pointerCaptureNodeKind &&
            candidate.node.isInteractive != 0 && candidate.node.isReadOnly == 0 &&
            CjguiComposableNodeAcceptsPointerCapture(candidate.node.nodeKind)) {
            return candidate;
        }
    }
    return nil;
}
- (BOOL)beginPointerCaptureForNode:(CJGuiInternalComposableSceneNode *)node atPoint:(NSPoint)point {
    if (!node || node.node.isInteractive == 0 || node.node.isReadOnly != 0 ||
        !CjguiComposableNodeAcceptsPointerCapture(node.node.nodeKind)) return NO;
    [self cancelPointerCapture];
    // A pointer control is also a keyboard control.  Keep native focus on
    // the exact captured node so the following Arrow key follows the same
    // Cangjie-owned control route as a physical drag.
    [self focusNode:node enqueue:YES];
    self.pointerCaptureActive = YES;
    self.pointerCaptureNodeId = node.node.nodeId;
    self.pointerCaptureResourceId = node.node.resourceId;
    self.pointerCaptureNodeKind = node.node.nodeKind;
    self.pointerCaptureX = point.x;
    self.pointerCaptureY = point.y;
    if (!CjguiEnqueueComposablePointerInteraction(self.session,
                                                   CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN,
                                                   node, point)) {
        [self cancelPointerCapture];
        return NO;
    }
    return YES;
}
- (BOOL)updatePointerCaptureAtPoint:(NSPoint)point {
    CJGuiInternalComposableSceneNode *node = [self capturedPointerNode];
    if (!node) {
        [self cancelPointerCapture];
        return NO;
    }
    self.pointerCaptureX = point.x;
    self.pointerCaptureY = point.y;
    return CjguiEnqueueComposablePointerInteraction(self.session,
                                                     CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,
                                                     node, point);
}
- (void)endPointerCaptureAtPoint:(NSPoint)point cancelled:(BOOL)cancelled {
    CJGuiInternalComposableSceneNode *node = [self capturedPointerNode];
    if (!node) {
        [self cancelPointerCapture];
        return;
    }
    self.pointerCaptureX = point.x;
    self.pointerCaptureY = point.y;
    (void)CjguiEnqueueComposablePointerInteraction(
        self.session,
        cancelled ? CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL :
                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END,
        node,
        point
    );
    [self cancelPointerCapture];
}
- (void)beginTextSelectionForNode:(CJGuiInternalComposableSceneNode *)node atPoint:(NSPoint)point {
    [self focusNode:node enqueue:YES];
    NSUInteger character = [self characterIndexAtPoint:point forNode:node];
    self.draggingNodeId = node.node.nodeId;
    self.draggingNodeResourceId = node.node.resourceId;
    self.draggingProjectionVersion = node.node.projectionVersion;
    self.draggingAnchor = character;
    self.inputProxy.selectedRange = CjguiComposedSelection(self.inputProxy.string, character, character);
    (void)CjguiEnqueueComposableInteraction(self.session,
                                            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                            node.index, @"", self.inputProxy.selectedRange);
    [self setNeedsDisplay:YES];
}
- (void)mouseDownForNode:(CJGuiInternalComposableSceneNode *)node atPoint:(NSPoint)point {
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0) return;
    if (CjguiComposableNodeAcceptsPointerCapture(kind)) {
        (void)[self beginPointerCaptureForNode:node atPoint:point];
        return;
    }
    if (CjguiComposableNodeIsTextInput(kind)) {
        [self beginTextSelectionForNode:node atPoint:point];
        return;
    }
    if (node.node.isReadOnly != 0) return;
    [self mouseDownForNode:node];
}
- (void)mouseDownForNode:(CJGuiInternalComposableSceneNode *)node {
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0) return;
    if (CjguiComposableNodeIsTextInput(kind)) { [self focusNode:node enqueue:YES]; return; }
    if (node.node.isReadOnly != 0) return;
    [self focusNode:node enqueue:YES];
    if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) {
        NSString *next = [node.value isEqualToString:@"true"] ? @"false" : @"true";
        (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED, node.index, next, NSMakeRange(0, 0)); return;
    }
    (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, node.index, @"", NSMakeRange(0, 0));
}
- (void)setText:(NSString *)text forNode:(CJGuiInternalComposableSceneNode *)node {
    [self focusNode:node enqueue:NO]; self.applyingProjection = YES; self.inputProxy.string = text ?: @"";
    self.inputProxy.selectedRange = NSMakeRange(self.inputProxy.string.length, 0); self.applyingProjection = NO;
    if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        self.activeTextFallbackHasPendingEdit = NO;
        [self markActiveTextFallbackRunsDirtyForWholeValue];
#ifdef CJGUI_INTERNAL_TESTING
        self.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
        [self refreshGpuTextForActiveInput];
    }
    (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED, node.index, self.inputProxy.string, self.inputProxy.selectedRange);
}
- (void)mouseDown:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    CJGuiInternalComposableSceneNode *node = [self nodeAtPoint:point];
    if (node) [self mouseDownForNode:node atPoint:point];
    else [self clearDraggingSelection];
}
- (void)mouseDragged:(NSEvent *)event {
    if (self.pointerCaptureActive) {
        NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
        (void)[self updatePointerCaptureAtPoint:point];
        return;
    }
    if (self.draggingNodeId == 0 || self.activeNodeIndex == NSNotFound) return;
    CJGuiInternalComposableSceneNode *node = nil;
    for (CJGuiInternalComposableSceneNode *candidate in self.nodes) {
        if (candidate.node.nodeId == self.draggingNodeId &&
            candidate.node.resourceId == self.draggingNodeResourceId &&
            candidate.node.projectionVersion == self.draggingProjectionVersion) {
            node = candidate; break;
        }
    }
    if (!node || node.node.nodeId != self.activeNodeId || node.node.resourceId != self.activeNodeResourceId ||
        node.node.nodeKind != self.activeNodeKind) {
        [self clearDraggingSelection]; return;
    }
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    NSUInteger character = [self characterIndexAtPoint:point forNode:node];
    NSUInteger start = MIN(self.draggingAnchor, character);
    NSUInteger end = MAX(self.draggingAnchor, character);
    self.inputProxy.selectedRange = CjguiComposedSelection(self.inputProxy.string, start, end);
#ifdef CJGUI_INTERNAL_TESTING
    self.testActiveTextWorkReason = CjguiInternalTextWorkReasonSelectionCaret;
#endif
    [self refreshGpuTextForActiveInput];
    (void)CjguiEnqueueComposableInteraction(self.session,
                                            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                            node.index, @"", self.inputProxy.selectedRange);
    [self setNeedsDisplay:YES];
}
- (void)mouseUp:(NSEvent *)event {
    if (self.pointerCaptureActive) {
        NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
        [self endPointerCaptureAtPoint:point cancelled:NO];
        return;
    }
    [self clearDraggingSelection];
}
- (void)scrollWheel:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    CJGuiInternalComposableSceneNode *active = nil;
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeId == self.activeNodeId && node.index == self.activeNodeIndex &&
            node.node.resourceId == self.activeNodeResourceId && node.node.nodeKind == self.activeNodeKind &&
            node.node.projectionVersion == self.activeProjectionVersion) { active = node; break; }
    }
    CJGuiInternalComposableSceneNode *hit = [self nodeAtPoint:point];
    if (hit && hit.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
        (!active || active.node.nodeId != hit.node.nodeId || active.node.resourceId != hit.node.resourceId)) {
        [self focusNode:hit enqueue:YES];
        active = hit;
    }
    if (active && active.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
        NSPointInRect(point, CjguiComposableRect(active, self)) &&
        CjguiPointInComposableNodeClip(point, active, self)) {
        [self scrollActiveMultiline:active deltaY:event.scrollingDeltaY];
        return;
    }
    [self routeScrollAtPoint:point deltaY:event.scrollingDeltaY];
}
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange
 replacementString:(NSString *)replacementString {
    if (textView == self.inputProxy && !self.applyingProjection &&
        self.activeNodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        // Preserve an already-pending local range across consecutive edits.
        // The range is stored in document coordinates, so an insertion before
        // it must shift it; blindly unioning ranges from different revisions
        // can skip an emoji/combining sequence after a deletion.
        [self remapActiveTextFallbackDirtyRangeForEditRange:affectedCharRange
                                          replacementLength:replacementString.length];
        // Selection notifications can precede textDidChange for a key event.
        // Capture the *new* UTF-16 replacement span; textDidChange expands it
        // to composed-character boundaries once NSTextStorage is current.
        self.activeTextFallbackPendingEditRange = NSMakeRange(affectedCharRange.location, replacementString.length);
        self.activeTextFallbackHasPendingEdit = YES;
    }
    return YES;
}
- (void)textDidChange:(NSNotification *)notification {
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
    self.testInputCallbackTrace.textCallbackCount += 1;
#endif
    (void)notification;
    // Do not request glyphs from NSTextView in its synchronous edit callback.
    // On a long paragraph that query can expand layout all the way to the
    // changed character and turn one keystroke into a document-wide stall.
    // The self-drawn viewport establishes only the needed visible glyphs on
    // its next draw; an explicit scroll/candidate query still asks TextKit
    // for exact geometry when that is actually required.
    self.activeTextLayoutNeedsVisibleGlyphs = YES;
    self.activeTextHasExactContentHeight = NO;
    if (self.activeNodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        if (!self.applyingProjection) {
            if (self.activeTextFallbackHasPendingEdit) {
                NSRange affected = [self fallbackAffectedRangeAfterEditAt:self.activeTextFallbackPendingEditRange.location
                                                         replacementLength:self.activeTextFallbackPendingEditRange.length
                                                                      value:self.inputProxy.textStorage.string ?: @""];
                [self markActiveTextFallbackRunsDirtyForRange:affected];
                self.activeTextFallbackHasPendingEdit = NO;
            } else {
                [self markActiveTextFallbackRunsDirtyForWholeValue];
            }
#ifdef CJGUI_INTERNAL_TESTING
            self.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
            [self scheduleActiveTextResourcePreparation];
        }
    } else {
#ifdef CJGUI_INTERNAL_TESTING
        self.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
        [self refreshGpuTextForActiveInput];
    }
    [self setNeedsDisplay:YES];
    if (!self.applyingProjection && self.activeNodeIndex != NSNotFound && self.activeNodeId != 0 && !self.inputProxy.hasMarkedText) {
        CJGuiInternalComposableSceneNode *active = nil;
        for (CJGuiInternalComposableSceneNode *node in self.nodes) {
            if (node.node.nodeId == self.activeNodeId && node.index == self.activeNodeIndex &&
                node.node.resourceId == self.activeNodeResourceId && node.node.nodeKind == self.activeNodeKind &&
                node.node.projectionVersion == self.activeProjectionVersion) { active = node; break; }
        }
        if (active) {
#ifdef CJGUI_INTERNAL_TESTING
            uint64_t enqueueStarted = CjguiMonotonicMicros();
#endif
            (void)CjguiEnqueueComposableInteraction(self.session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED, active.index,
                                                    self.inputProxy.string, self.inputProxy.selectedRange);
#ifdef CJGUI_INTERNAL_TESTING
            self.session.testComposableEventEnqueueMicros = CjguiMonotonicMicros() - enqueueStarted;
            uint64_t accessibilityStarted = CjguiMonotonicMicros();
#endif
            [self postAccessibilityValueChangedForNode:active];
            [self postAccessibilitySelectionChangedForNode:active];
#ifdef CJGUI_INTERNAL_TESTING
            self.session.testComposableAccessibilityMicros = CjguiMonotonicMicros() - accessibilityStarted;
#endif
        }
    }
#ifdef CJGUI_INTERNAL_TESTING
    self.session.testComposableTextDelegateMicros = CjguiMonotonicMicros() - started;
    self.testInputCallbackTrace.textCallbackMicros += self.session.testComposableTextDelegateMicros;
#endif
}
- (void)textViewDidChangeSelection:(NSNotification *)notification {
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
    self.testInputCallbackTrace.selectionCallbackCount += 1;
    if (self.activeTextFallbackHasPendingEdit) self.testInputCallbackTrace.pendingEditSelectionCount += 1;
#endif
    (void)notification;
    // Selection is owned by the platform text service. Keep it separate from
    // a text edit: Cangjie records it only as window query state, never as a
    // domain write or a reason to rebuild the scene.
    if (self.applyingProjection || self.activeNodeIndex == NSNotFound || self.activeNodeId == 0 || self.inputProxy.hasMarkedText) {
#ifdef CJGUI_INTERNAL_TESTING
        self.session.testComposableSelectionDelegateMicros = CjguiMonotonicMicros() - started;
#endif
        return;
    }
    CJGuiInternalComposableSceneNode *active = nil;
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeId == self.activeNodeId && node.index == self.activeNodeIndex &&
            node.node.resourceId == self.activeNodeResourceId && node.node.nodeKind == self.activeNodeKind &&
            node.node.projectionVersion == self.activeProjectionVersion) {
            active = node; break;
        }
    }
    if (!active) {
#ifdef CJGUI_INTERNAL_TESTING
        self.session.testComposableSelectionDelegateMicros = CjguiMonotonicMicros() - started;
#endif
        return;
    }
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t revealStarted = CjguiMonotonicMicros();
#endif
    [self revealActiveMultilineCaret:active];
#ifdef CJGUI_INTERNAL_TESTING
    self.testInputCallbackTrace.selectionRevealMicros += CjguiMonotonicMicros() - revealStarted;
    uint64_t enqueueStarted = CjguiMonotonicMicros();
#endif
    (void)CjguiEnqueueComposableInteraction(self.session,
                                            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                            active.index, @"", self.inputProxy.selectedRange);
#ifdef CJGUI_INTERNAL_TESTING
    self.testInputCallbackTrace.selectionQueueMicros += CjguiMonotonicMicros() - enqueueStarted;
    uint64_t accessibilityStarted = CjguiMonotonicMicros();
#endif
    [self postAccessibilitySelectionChangedForNode:active];
#ifdef CJGUI_INTERNAL_TESTING
    self.testInputCallbackTrace.selectionAccessibilityMicros += CjguiMonotonicMicros() - accessibilityStarted;
#endif
    if (active.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
        (self.activeTextFallbackRunsDirty || self.activeTextFallbackHasPendingEdit)) {
#ifdef CJGUI_INTERNAL_TESTING
        self.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
        [self scheduleActiveTextResourcePreparation];
    } else {
#ifdef CJGUI_INTERNAL_TESTING
        self.testActiveTextWorkReason = CjguiInternalTextWorkReasonSelectionCaret;
        if (self.testForceFullBodyPreparationOnSelection) {
            self.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
        }
#endif
        [self refreshGpuTextForActiveInput];
    }
    [self setNeedsDisplay:YES];
#ifdef CJGUI_INTERNAL_TESTING
    self.session.testComposableSelectionDelegateMicros = CjguiMonotonicMicros() - started;
    self.testInputCallbackTrace.selectionCallbackMicros += self.session.testComposableSelectionDelegateMicros;
#endif
}
- (CJGuiInternalComposableSceneNode *)nextFocusableNodeFrom:(NSInteger)index backwards:(BOOL)backwards {
    NSInteger cursor = index;
    NSInteger step = backwards ? -1 : 1;
    uint64_t activeScope = 0;
    CJGuiInternalComposableSceneNode *active = [self activeFocusableNode];
    if (active) activeScope = active.node.inputScope;
    NSUInteger attempts = 0;
    while (attempts < self.nodes.count) {
        if (cursor < 0) cursor = (NSInteger)self.nodes.count - 1;
        if (cursor >= (NSInteger)self.nodes.count) cursor = 0;
        CJGuiInternalComposableSceneNode *candidate = self.nodes[(NSUInteger)cursor];
        uint32_t kind = candidate.node.nodeKind;
        if (candidate.node.inputScope == activeScope && candidate.node.isInteractive != 0 &&
            (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
             kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
             kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT ||
             kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ||
             kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT)) return candidate;
        cursor += step;
        attempts += 1;
    }
    return nil;
}

// This bridge deliberately transports only a normalized physical shortcut.
// It has no application command table: Cangjie decides whether the chord is
// declared, enabled, and inside the current focus scope after it enters the
// existing bounded FIFO.
static NSString *CjguiComposableShortcutForEvent(NSEvent *event) {
    if (!event || (event.modifierFlags & NSEventModifierFlagCommand) == 0) return nil;
    NSString *key = event.charactersIgnoringModifiers.lowercaseString;
    if (key.length != 1) return nil;
    unichar scalar = [key characterAtIndex:0];
    if (scalar < 0x21 || scalar > 0x7e) return nil;
    NSMutableString *result = [NSMutableString stringWithString:@"shortcut:"];
    if ((event.modifierFlags & NSEventModifierFlagControl) != 0) [result appendString:@"control+"];
    if ((event.modifierFlags & NSEventModifierFlagOption) != 0) [result appendString:@"option+"];
    if ((event.modifierFlags & NSEventModifierFlagShift) != 0) [result appendString:@"shift+"];
    [result appendFormat:@"command+%@", key];
    return result;
}

static BOOL CjguiEnqueueComposableShortcut(CJGuiInternalSession *session, NSString *shortcut) {
    if (!session || shortcut.length == 0) return NO;
    return CjguiEnqueueComposableInteraction(session,
                                             CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_WINDOW_COMMAND,
                                             0, shortcut, NSMakeRange(0, 0));
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    (void)textView;
    if (selector == @selector(saveDocument:) || selector == @selector(saveDocumentAs:)) {
        return CjguiEnqueueComposableShortcut(self.session, @"shortcut:command+s");
    }
    if (selector == @selector(undo:)) {
        return CjguiEnqueueComposableShortcut(self.session, @"shortcut:command+z");
    }
    if (selector == @selector(redo:)) {
        return CjguiEnqueueComposableShortcut(self.session, @"shortcut:shift+command+z");
    }
    BOOL backwards = selector == @selector(insertBacktab:);
    BOOL forwards = selector == @selector(insertTab:);
    if (!backwards && !forwards) return NO;
    CJGuiInternalComposableSceneNode *active = [self activeFocusableNode];
    if (forwards && active && active.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
        active.node.tabInsertsText != 0) return NO;
    CJGuiInternalComposableSceneNode *next = [self nextFocusableNodeFrom:self.activeNodeIndex + (backwards ? -1 : 1) backwards:backwards];
    if (next) [self focusNode:next enqueue:YES];
    return next != nil;
}
- (CJGuiInternalComposableSceneNode *)activeFocusableNode {
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.index == self.activeNodeIndex && node.node.nodeId == self.activeNodeId &&
            node.node.resourceId == self.activeNodeResourceId && node.node.nodeKind == self.activeNodeKind &&
            node.node.projectionVersion == self.activeProjectionVersion) return node;
    }
    return nil;
}
- (void)activateFocusedNode:(CJGuiInternalComposableSceneNode *)node {
    if (!node || node.node.isInteractive == 0 || node.node.isReadOnly != 0) return;
    if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) {
        NSString *next = [node.value isEqualToString:@"true"] ? @"false" : @"true";
        (void)CjguiEnqueueComposableInteraction(self.session,
                                                CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED,
                                                node.index, next, NSMakeRange(0, 0));
    } else if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON) {
        (void)CjguiEnqueueComposableInteraction(self.session,
                                                CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE,
                                                node.index, @"", NSMakeRange(0, 0));
    }
}
- (BOOL)handleWindowCommandKeyDown:(NSEvent *)event {
    NSString *shortcut = CjguiComposableShortcutForEvent(event);
    return CjguiEnqueueComposableShortcut(self.session, shortcut);
}
- (void)keyDown:(NSEvent *)event {
#ifdef CJGUI_INTERNAL_TESTING
    self.testKeyDownReceiptCount += 1;
#endif
    if (event.keyCode == 53 && self.pointerCaptureActive) {
        [self endPointerCaptureAtPoint:NSMakePoint(self.pointerCaptureX, self.pointerCaptureY) cancelled:YES];
        return;
    }
    if ([self handleWindowCommandKeyDown:event]) {
        return;
    }
    CJGuiInternalComposableSceneNode *active = [self activeFocusableNode];
    uint32_t activeKind = active ? active.node.nodeKind : 0;
    BOOL activeIsText = activeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
        activeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
        activeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    if (event.keyCode == 53 && active && active.node.inputScope != 0) {
        (void)CjguiEnqueueComposableInteraction(self.session,
                                                CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DISMISS_LAYER,
                                                active.index, @"escape", NSMakeRange(0, 0));
        return;
    }
    if (!activeIsText && active) {
        BOOL activeIsPointerControl = CjguiComposableNodeAcceptsPointerCapture(activeKind);
        if (activeIsPointerControl && (event.keyCode == 123 || event.keyCode == 124 ||
                                       event.keyCode == 126 || event.keyCode == 125)) {
            NSString *navigation = event.keyCode == 123 ? @"left" :
                (event.keyCode == 124 ? @"right" : (event.keyCode == 126 ? @"up" : @"down"));
            (void)CjguiEnqueueComposableInteraction(self.session,
                                                    CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
                                                    active.index, navigation, NSMakeRange(0, 0));
            return;
        }
        if (active.node.inputScope != 0 && (event.keyCode == 123 || event.keyCode == 124 ||
                                            event.keyCode == 126 || event.keyCode == 125)) {
            BOOL backwards = event.keyCode == 123 || event.keyCode == 126;
            CJGuiInternalComposableSceneNode *next = [self nextFocusableNodeFrom:self.activeNodeIndex + (backwards ? -1 : 1)
                                                                         backwards:backwards];
            if (next) [self focusNode:next enqueue:YES];
            return;
        }
        NSString *navigation = nil;
        if (event.keyCode == 126) navigation = @"up";
        else if (event.keyCode == 125) navigation = @"down";
        else if (event.keyCode == 116) navigation = @"page_up";
        else if (event.keyCode == 121) navigation = @"page_down";
        else if (event.keyCode == 115) navigation = @"home";
        else if (event.keyCode == 119) navigation = @"end";
        if (navigation) {
            NSRect activeRect = CjguiComposableRect(active, self);
            CJGuiInternalComposableSceneNode *scrollNode = [self scrollNodeContainingPoint:NSMakePoint(NSMidX(activeRect), NSMidY(activeRect))];
            if (scrollNode) {
                (void)CjguiEnqueueComposableInteraction(self.session,
                                                        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,
                                                        scrollNode.index, navigation, NSMakeRange(0, 0));
                return;
            }
        }
    }
    if (event.keyCode == 48) {
        BOOL backwards = (event.modifierFlags & NSEventModifierFlagShift) != 0;
        CJGuiInternalComposableSceneNode *next = [self nextFocusableNodeFrom:self.activeNodeIndex + (backwards ? -1 : 1)
                                                                     backwards:backwards];
        if (next) [self focusNode:next enqueue:YES];
        return;
    }
    if (event.keyCode == 49 || event.keyCode == 36 || event.keyCode == 76) {
        [self activateFocusedNode:[self activeFocusableNode]];
        return;
    }
    [super keyDown:event];
}
- (void)cancelActiveComposition {
    if (!self.inputProxy.hasMarkedText) return;
    // Keep cancellation in the adapter layer. The Cangjie owner receives no
    // edit event for a discarded preedit and therefore cannot accidentally
    // create an undo entry for text the user never committed.
    self.applyingProjection = YES;
    [(CJGuiInternalComposableInputProxy *)self.inputProxy cancelMarkedText];
    self.applyingProjection = NO;
    self.activeTextLayoutSignature = nil;
    self.activeTextLayoutNeedsVisibleGlyphs = YES;
    self.activeTextHasExactContentHeight = NO;
    CJGuiInternalComposableSceneNode *active = [self activeFocusableNode];
    if (active) {
        [self postAccessibilityValueChangedForNode:active];
        [self postAccessibilitySelectionChangedForNode:active];
    }
#ifdef CJGUI_INTERNAL_TESTING
    self.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
    [self refreshGpuTextForActiveInput];
    [self setNeedsDisplay:YES];
}
- (void)scrollActiveMultiline:(CJGuiInternalComposableSceneNode *)node deltaY:(CGFloat)deltaY {
    if (!node || deltaY == 0.0) return;
    [self positionInputProxyForNode:node];
    NSLayoutManager *layoutManager = self.inputProxy.layoutManager;
    NSTextContainer *container = self.inputProxy.textContainer;
    NSRect rect = NSInsetRect(CjguiComposableRect(node, self), 7.0, 6.0);
    CGFloat next = MAX(0.0, [self multilineScrollOffsetForNode:node] - deltaY);
    if (self.activeTextHasExactContentHeight) {
        CGFloat maximum = MAX(0.0, self.activeTextKnownContentHeight - NSHeight(rect));
        next = MIN(maximum, next);
    }
    // Request only the viewport the wheel is moving into. With non-contiguous
    // layout TextKit may expand this range, but it is not a request for the
    // whole text container. An empty result is the explicit "past known end"
    // case where exact extent is required to clamp correctly.
    [self ensureActiveLayoutForBoundingRect:NSMakeRect(0.0, next, NSWidth(rect), NSHeight(rect))
                                  container:container layoutManager:layoutManager];
    NSRange visible = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:
                       NSMakeRect(0.0, next, NSWidth(rect), NSHeight(rect)) inTextContainer:container];
    if (visible.location == NSNotFound || visible.length == 0) {
        [self ensureActiveFullLayoutForContainer:container layoutManager:layoutManager];
        self.activeTextKnownContentHeight = [layoutManager usedRectForTextContainer:container].size.height;
        self.activeTextHasExactContentHeight = YES;
        CGFloat maximum = MAX(0.0, self.activeTextKnownContentHeight - NSHeight(rect));
        next = MIN(maximum, next);
        visible = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:
                   NSMakeRect(0.0, next, NSWidth(rect), NSHeight(rect)) inTextContainer:container];
    }
    [self setMultilineScrollOffset:next forNode:node];
    if (visible.location != NSNotFound && visible.length > 0) {
        NSUInteger character = [layoutManager characterIndexForGlyphAtIndex:visible.location];
        NSRect line = [self activeLineFragmentForGlyph:visible.location layoutManager:layoutManager];
        self.activeTextHasScrollAnchor = YES;
        self.activeTextScrollAnchorCharacter = character;
        self.activeTextScrollAnchorViewportOffset = NSMinY(line) - next;
    }
#ifdef CJGUI_INTERNAL_TESTING
    self.testActiveTextWorkReason = CjguiInternalTextWorkReasonVisibleTileScroll;
#endif
    [self refreshGpuTextForActiveInput];
    [self setNeedsDisplay:YES];
}
- (void)revealActiveMultilineCaret:(CJGuiInternalComposableSceneNode *)node {
    NSUInteger length = self.inputProxy.string.length;
    [self revealActiveMultilineCharacterAtLocation:MIN(self.inputProxy.selectedRange.location, length) forNode:node];
}
- (void)revealActiveMultilineCharacterAtLocation:(NSUInteger)requestedLocation forNode:(CJGuiInternalComposableSceneNode *)node {
    if (!node || node.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) return;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    [self positionInputProxyForNode:node];
    NSLayoutManager *layoutManager = self.inputProxy.layoutManager;
    NSTextContainer *container = self.inputProxy.textContainer;
    NSUInteger length = self.inputProxy.string.length;
    NSUInteger location = MIN(requestedLocation, length);
    if (length == 0) {
        [self setMultilineScrollOffset:0.0 forNode:node];
        self.activeTextHasScrollAnchor = YES;
        self.activeTextScrollAnchorCharacter = 0;
        self.activeTextScrollAnchorViewportOffset = 0.0;
#ifdef CJGUI_INTERNAL_TESTING
        self.activeTextLayoutTrace.revealMicros += CjguiMonotonicMicros() - started;
#endif
        return;
    }
    NSUInteger character = location >= length ? length - 1 : location;
    [self ensureActiveLayoutForCharacterRange:NSMakeRange(character, 1) layoutManager:layoutManager];
    NSUInteger glyph = [self activeGlyphIndexForCharacter:character layoutManager:layoutManager];
    NSRect glyphRect = location == length && layoutManager.extraLineFragmentTextContainer == container &&
        !NSIsEmptyRect(layoutManager.extraLineFragmentRect) ? layoutManager.extraLineFragmentRect :
        [self activeLineFragmentForGlyph:glyph layoutManager:layoutManager];
    NSRect textRect = NSInsetRect(CjguiComposableRect(node, self), 7.0, 6.0);
    CGFloat scroll = [self multilineScrollOffsetForNode:node];
    if (NSMinY(glyphRect) < scroll) scroll = NSMinY(glyphRect);
    if (NSMaxY(glyphRect) > scroll + NSHeight(textRect)) {
        scroll = NSMaxY(glyphRect) - NSHeight(textRect);
    }
    if (self.activeTextHasExactContentHeight) {
        CGFloat maximum = MAX(0.0, self.activeTextKnownContentHeight - NSHeight(textRect));
        scroll = MIN(maximum, scroll);
    }
    scroll = MAX(0.0, scroll);
    [self setMultilineScrollOffset:scroll forNode:node];
    self.activeTextHasScrollAnchor = YES;
    self.activeTextScrollAnchorCharacter = character;
    self.activeTextScrollAnchorViewportOffset = NSMinY(glyphRect) - scroll;
#ifdef CJGUI_INTERNAL_TESTING
    self.activeTextLayoutTrace.revealMicros += CjguiMonotonicMicros() - started;
#endif
}
- (void)updateActiveSingleLineTextDecorationsForNode:(CJGuiInternalComposableSceneNode *)node
                                           displayText:(NSString *)displayText
                                             selection:(NSRange)selection
                                           markedRange:(NSRange)markedRange
                                            drawsCaret:(BOOL)drawsCaret {
    CjguiClearComposableTextDecorations(node);
    if (!node || displayText.length == 0) return;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *attributes = @{ NSFontAttributeName: CjguiComposableFont(node),
                                  NSParagraphStyleAttributeName: paragraph };
    NSRect bounds = CjguiComposableRect(node, self);
    NSRect textRect = NSInsetRect(bounds, 7.0, 6.0);
    NSMutableArray<NSValue *> *selectionRects = [NSMutableArray array];
    if (selection.location != NSNotFound) {
        NSUInteger start = MIN(selection.location, displayText.length);
        NSUInteger end = MIN(NSMaxRange(selection), displayText.length);
        CGFloat before = [[displayText substringToIndex:start] sizeWithAttributes:attributes].width;
        if (end > start) {
            CGFloat selected = [[displayText substringWithRange:NSMakeRange(start, end - start)] sizeWithAttributes:attributes].width;
            [selectionRects addObject:[NSValue valueWithRect:NSMakeRect(NSMinX(textRect) + before, NSMinY(textRect),
                                                                  MAX(1.0, selected), NSHeight(textRect))]];
        } else if (drawsCaret) {
            node.textCaretRect = NSMakeRect(NSMinX(textRect) + before, NSMinY(textRect) + 2.0, 1.0,
                                             MAX(1.0, NSHeight(textRect) - 4.0));
        }
    }
    node.textSelectionRects = selectionRects;
    if (markedRange.location == NSNotFound || markedRange.length == 0) return;
    NSUInteger markedStart = MIN(markedRange.location, displayText.length);
    NSUInteger markedEnd = MIN(NSMaxRange(markedRange), displayText.length);
    if (markedEnd <= markedStart) return;
    CGFloat before = [[displayText substringToIndex:markedStart] sizeWithAttributes:attributes].width;
    CGFloat marked = [[displayText substringWithRange:NSMakeRange(markedStart, markedEnd - markedStart)] sizeWithAttributes:attributes].width;
    node.textMarkedRects = @[ [NSValue valueWithRect:NSMakeRect(NSMinX(textRect) + before, NSMaxY(textRect) - 1.0,
                                                               MAX(1.0, marked), 1.0)] ];
}
- (void)updateActiveMultilineTextDecorationsForNode:(CJGuiInternalComposableSceneNode *)node {
    CjguiClearComposableTextDecorations(node);
    if (!node || node.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) return;
    NSRect rect = CjguiComposableRect(node, self);
    NSRect clip = NSIntersectionRect(rect, CjguiComposableClipBounds(node));
    NSRect contentRect = NSInsetRect(rect, 7.0, 6.0);
    NSRect visibleTextRect = NSIntersectionRect(contentRect, clip);
    if (NSIsEmptyRect(visibleTextRect)) return;
    NSString *value = self.inputProxy.string ?: @"";
    NSColor *textColor = [NSColor colorWithSRGBRed:node.node.textRed green:node.node.textGreen
                                              blue:node.node.textBlue alpha:node.node.textAlpha];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{ NSFontAttributeName: CjguiComposableFont(node),
                                  NSForegroundColorAttributeName: textColor,
                                  NSParagraphStyleAttributeName: paragraph };
    self.inputProxy.textContainer.maximumNumberOfLines = 0;
    self.inputProxy.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    NSString *signature = [self activeTextLayoutSignatureForNode:node contentWidth:NSWidth(contentRect)];
    if (![signature isEqualToString:self.activeTextLayoutSignature]) {
        self.applyingProjection = YES;
        if (self.inputProxy.string.length > 0) {
            [self.inputProxy.textStorage setAttributes:attributes range:NSMakeRange(0, self.inputProxy.string.length)];
#ifdef CJGUI_INTERNAL_TESTING
            self.testInputCallbackTrace.wholeAttributeWriteCount += 1;
            self.testInputCallbackTrace.wholeAttributeCharacters += self.inputProxy.string.length;
#endif
        }
        self.inputProxy.typingAttributes = attributes;
        self.applyingProjection = NO;
        self.activeTextLayoutSignature = signature;
        self.activeTextLayoutNeedsVisibleGlyphs = YES;
        self.activeTextHasExactContentHeight = NO;
        self.activeTextKnownContentHeight = 0.0;
    }
    NSLayoutManager *layoutManager = self.inputProxy.layoutManager;
    NSTextContainer *container = self.inputProxy.textContainer;
    container.containerSize = NSMakeSize(NSWidth(contentRect), CGFLOAT_MAX);
    container.widthTracksTextView = NO;
    if (self.activeTextLayoutNeedsVisibleGlyphs && value.length > 0) {
        NSUInteger location = MIN(self.inputProxy.selectedRange.location, value.length);
        NSUInteger character = location >= value.length ? value.length - 1 : location;
        [layoutManager ensureGlyphsForCharacterRange:NSMakeRange(character, 1)];
        self.activeTextLayoutNeedsVisibleGlyphs = NO;
    }
    if (self.activeTextHasScrollAnchor && value.length > 0) {
        NSUInteger anchor = MIN(self.activeTextScrollAnchorCharacter, value.length - 1);
        [self ensureActiveLayoutForCharacterRange:NSMakeRange(anchor, 1) layoutManager:layoutManager];
        NSUInteger anchorGlyph = [self activeGlyphIndexForCharacter:anchor layoutManager:layoutManager];
        NSRect anchorLine = [self activeLineFragmentForGlyph:anchorGlyph layoutManager:layoutManager];
        [self setMultilineScrollOffset:MAX(0.0, NSMinY(anchorLine) - self.activeTextScrollAnchorViewportOffset)
                              forNode:node];
    }
    CGFloat maximumScroll = self.activeTextHasExactContentHeight
        ? MAX(0.0, self.activeTextKnownContentHeight - NSHeight(contentRect)) : CGFLOAT_MAX;
    CGFloat scroll = MAX(0.0, [self multilineScrollOffsetForNode:node]);
    if (maximumScroll != CGFLOAT_MAX) scroll = MIN(maximumScroll, scroll);
    [self setMultilineScrollOffset:scroll forNode:node];
    NSRect visibleLayoutRect = NSMakeRect(0.0, scroll, NSWidth(contentRect), NSHeight(contentRect));
    [self ensureActiveLayoutForBoundingRect:visibleLayoutRect container:container layoutManager:layoutManager];
    NSRange visibleGlyphs = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:visibleLayoutRect
                                                                      inTextContainer:container];
    if (visibleGlyphs.location == NSNotFound) visibleGlyphs = NSMakeRange(0, 0);
    NSPoint origin = NSMakePoint(NSMinX(contentRect), NSMinY(contentRect) - scroll);
    NSRange selection = self.inputProxy.selectedRange;
    selection.location = MIN(selection.location, value.length);
    selection.length = MIN(selection.length, value.length - selection.location);
    if (selection.length > 0 && visibleGlyphs.length > 0) {
        NSRange visibleCharacters = [layoutManager characterRangeForGlyphRange:visibleGlyphs actualGlyphRange:NULL];
        NSRange selectedCharacters = NSIntersectionRange(selection, visibleCharacters);
        if (selectedCharacters.length > 0) {
            NSRange selectionGlyphs = [layoutManager glyphRangeForCharacterRange:selectedCharacters actualCharacterRange:NULL];
            NSMutableArray<NSValue *> *selectionRects = [NSMutableArray array];
            [layoutManager enumerateLineFragmentsForGlyphRange:selectionGlyphs usingBlock:^(NSRect lineRect, NSRect usedRect,
                                                                                              NSTextContainer *lineContainer,
                                                                                              NSRange lineGlyphRange, BOOL *stop) {
                (void)lineRect; (void)usedRect; (void)lineContainer; (void)stop;
                NSRange intersection = NSIntersectionRange(lineGlyphRange, selectionGlyphs);
                if (intersection.length == 0) return;
                NSRect selected = [layoutManager boundingRectForGlyphRange:intersection inTextContainer:container];
                selected.origin.x += origin.x; selected.origin.y += origin.y;
                selected = NSIntersectionRect(selected, visibleTextRect);
                if (!NSIsEmptyRect(selected)) [selectionRects addObject:[NSValue valueWithRect:selected]];
            }];
            node.textSelectionRects = selectionRects;
        }
    }
    // Marked text is system composition state, not a second text resource.
    // Its underline follows the same visible TextKit fragments as selection
    // geometry, preserving preedit feedback without another body texture.
    NSRange markedRange = self.inputProxy.markedRange;
    if (markedRange.location != NSNotFound && markedRange.length > 0 && visibleGlyphs.length > 0) {
        markedRange.location = MIN(markedRange.location, value.length);
        markedRange.length = MIN(markedRange.length, value.length - markedRange.location);
        NSRange visibleCharacters = [layoutManager characterRangeForGlyphRange:visibleGlyphs actualGlyphRange:NULL];
        NSRange markedCharacters = NSIntersectionRange(markedRange, visibleCharacters);
        if (markedCharacters.length > 0) {
            NSRange markedGlyphs = [layoutManager glyphRangeForCharacterRange:markedCharacters actualCharacterRange:NULL];
            NSMutableArray<NSValue *> *markedRects = [NSMutableArray array];
            [layoutManager enumerateLineFragmentsForGlyphRange:markedGlyphs usingBlock:^(NSRect lineRect, NSRect usedRect,
                                                                                           NSTextContainer *lineContainer,
                                                                                           NSRange lineGlyphRange, BOOL *stop) {
                (void)lineRect; (void)usedRect; (void)lineContainer; (void)stop;
                NSRange intersection = NSIntersectionRange(lineGlyphRange, markedGlyphs);
                if (intersection.length == 0) return;
                NSRect marked = [layoutManager boundingRectForGlyphRange:intersection inTextContainer:container];
                marked.origin.x += origin.x; marked.origin.y += origin.y;
                marked = NSIntersectionRect(marked, visibleTextRect);
                if (NSIsEmptyRect(marked)) return;
                marked.origin.y = NSMaxY(marked) - 1.0;
                marked.size.height = 1.0;
                [markedRects addObject:[NSValue valueWithRect:marked]];
            }];
            node.textMarkedRects = markedRects;
        }
    }
    if (selection.length != 0 || self.window.firstResponder != self.inputProxy || value.length == 0) return;
    NSUInteger location = MIN(selection.location, value.length);
    NSUInteger character = location >= value.length ? value.length - 1 : location;
    [self ensureActiveLayoutForCharacterRange:NSMakeRange(character, 1) layoutManager:layoutManager];
    NSUInteger glyph = [self activeGlyphIndexForCharacter:character layoutManager:layoutManager];
    BOOL usesExtraLine = location == value.length && layoutManager.extraLineFragmentTextContainer == container &&
        !NSIsEmptyRect(layoutManager.extraLineFragmentRect);
    NSRect line = usesExtraLine ? layoutManager.extraLineFragmentRect :
        [self activeLineFragmentForGlyph:glyph layoutManager:layoutManager];
    NSPoint glyphPoint = usesExtraLine ? layoutManager.extraLineFragmentUsedRect.origin :
        [self activeGlyphLocation:glyph layoutManager:layoutManager];
    CGFloat caretX = usesExtraLine ? glyphPoint.x : (location >= value.length ? NSMaxX(line) : glyphPoint.x);
    NSRect caret = NSMakeRect(origin.x + caretX, origin.y + NSMinY(line) + 2.0, 1.0, MAX(1.0, NSHeight(line) - 4.0));
    caret = NSIntersectionRect(caret, visibleTextRect);
    if (!NSIsEmptyRect(caret)) node.textCaretRect = caret;
}
- (void)drawMultilineNode:(CJGuiInternalComposableSceneNode *)node active:(BOOL)active {
    NSRect rect = CjguiComposableRect(node, self);
    NSRect clip = NSIntersectionRect(rect, CjguiComposableClipBounds(node));
    NSRect contentRect = NSInsetRect(rect, 7.0, 6.0);
    NSRect visibleTextRect = NSIntersectionRect(contentRect, clip);
    if (NSIsEmptyRect(visibleTextRect)) return;
    NSString *value = active ? self.inputProxy.string : node.value;
    if (!value) value = @"";
    NSColor *textColor = [NSColor colorWithSRGBRed:node.node.textRed green:node.node.textGreen
                                              blue:node.node.textBlue alpha:node.node.textAlpha];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSFont *font = CjguiComposableFont(node);
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSForegroundColorAttributeName: textColor,
                                  NSParagraphStyleAttributeName: paragraph };
    NSLayoutManager *layoutManager = nil;
    NSTextContainer *container = nil;
    CGFloat maximumScroll = 0.0;
    if (active) {
        self.inputProxy.textContainer.maximumNumberOfLines = 0;
        self.inputProxy.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        NSString *signature = [self activeTextLayoutSignatureForNode:node contentWidth:NSWidth(contentRect)];
        if (![signature isEqualToString:self.activeTextLayoutSignature]) {
            self.applyingProjection = YES;
            if (self.inputProxy.string.length > 0) {
                [self.inputProxy.textStorage setAttributes:attributes range:NSMakeRange(0, self.inputProxy.string.length)];
#ifdef CJGUI_INTERNAL_TESTING
                self.testInputCallbackTrace.wholeAttributeWriteCount += 1;
                self.testInputCallbackTrace.wholeAttributeCharacters += self.inputProxy.string.length;
#endif
            }
            self.inputProxy.typingAttributes = attributes;
            self.applyingProjection = NO;
            self.activeTextLayoutSignature = signature;
            self.activeTextLayoutNeedsVisibleGlyphs = YES;
            self.activeTextHasExactContentHeight = NO;
            self.activeTextKnownContentHeight = 0.0;
        }
        layoutManager = self.inputProxy.layoutManager;
        container = self.inputProxy.textContainer;
        container.containerSize = NSMakeSize(NSWidth(contentRect), CGFLOAT_MAX);
        container.widthTracksTextView = NO;
        if (self.activeTextLayoutNeedsVisibleGlyphs) {
            NSUInteger length = value.length;
            if (length > 0) {
                NSUInteger location = MIN(self.inputProxy.selectedRange.location, length);
                NSUInteger character = location >= length ? length - 1 : location;
                [layoutManager ensureGlyphsForCharacterRange:NSMakeRange(character, 1)];
            }
            self.activeTextLayoutNeedsVisibleGlyphs = NO;
        }
        // A width/style invalidation must not clamp the viewport to zero just
        // because total height has not yet been requested. Re-establish an
        // existing character anchor with a range layout query instead.
        if (self.activeTextHasScrollAnchor && value.length > 0) {
            NSUInteger anchor = MIN(self.activeTextScrollAnchorCharacter, value.length - 1);
            [self ensureActiveLayoutForCharacterRange:NSMakeRange(anchor, 1) layoutManager:layoutManager];
            NSUInteger anchorGlyph = [self activeGlyphIndexForCharacter:anchor layoutManager:layoutManager];
            NSRect anchorLine = [self activeLineFragmentForGlyph:anchorGlyph layoutManager:layoutManager];
            [self setMultilineScrollOffset:MAX(0.0, NSMinY(anchorLine) - self.activeTextScrollAnchorViewportOffset)
                                  forNode:node];
        }
        maximumScroll = self.activeTextHasExactContentHeight
            ? MAX(0.0, self.activeTextKnownContentHeight - NSHeight(contentRect)) : CGFLOAT_MAX;
    } else {
        CJGuiInternalComposableMultilineLayoutCacheEntry *entry = [self cachedMultilineLayoutForNode:node
                                                                                                  value:value
                                                                                             attributes:attributes
                                                                                           contentWidth:NSWidth(contentRect)];
        layoutManager = entry.layoutManager;
        container = entry.container;
        maximumScroll = MAX(0.0, entry.maximumScroll - NSHeight(contentRect));
    }
    CGFloat scroll = MAX(0.0, [self multilineScrollOffsetForNode:node]);
    if (maximumScroll != CGFLOAT_MAX) scroll = MIN(maximumScroll, scroll);
    [self setMultilineScrollOffset:scroll forNode:node];
    NSRect visibleLayoutRect = NSMakeRect(0.0, scroll, NSWidth(contentRect), NSHeight(contentRect));
    if (active) [self ensureActiveLayoutForBoundingRect:visibleLayoutRect container:container layoutManager:layoutManager];
    NSRange visibleGlyphs = active ? [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:visibleLayoutRect
                                                                                   inTextContainer:container] :
        [layoutManager glyphRangeForBoundingRect:visibleLayoutRect inTextContainer:container];
    if (visibleGlyphs.location == NSNotFound) visibleGlyphs = NSMakeRange(0, 0);
#ifdef CJGUI_INTERNAL_TESTING
    if (active && CjguiTestVerboseGlyphDiagnosticsEnabled()) {
        NSDictionary *firstAttributes = value.length > 0 ? [self.inputProxy.textStorage attributesAtIndex:0 effectiveRange:NULL] : @{};
        NSLog(@"cjgui: multiline raster geometry node=%llu value=%lu glyphs=%lu:%lu scroll=%.2f content=%@ visible=%@ container=%@ used=%@",
              node.node.nodeId, (unsigned long)value.length, (unsigned long)visibleGlyphs.location,
              (unsigned long)visibleGlyphs.length, scroll, NSStringFromRect(contentRect),
              NSStringFromRect(visibleTextRect), NSStringFromSize(container.containerSize),
              NSStringFromRect([layoutManager usedRectForTextContainer:container]));
        NSLog(@"cjgui: multiline raster attributes font=%@ color=%@", firstAttributes[NSFontAttributeName], firstAttributes[NSForegroundColorAttributeName]);
    }
#endif
    [NSGraphicsContext saveGraphicsState];
    CjguiClipComposableNode(node, self);
    NSRectClip(visibleTextRect);
    NSPoint origin = NSMakePoint(NSMinX(contentRect), NSMinY(contentRect) - scroll);
#ifdef CJGUI_INTERNAL_TESTING
    if (active) CjguiLogMultilineGlyphDrawingState(node.node.nodeId, layoutManager, container, visibleGlyphs, origin, value);
#endif
    [layoutManager drawGlyphsForGlyphRange:visibleGlyphs atPoint:origin];
    if (active && maximumScroll > 0.0) {
        CGFloat trackHeight = MAX(12.0, NSHeight(contentRect) - 4.0);
        CGFloat thumbHeight = MAX(14.0, trackHeight * NSHeight(contentRect) / (maximumScroll + NSHeight(contentRect)));
        CGFloat thumbY = NSMinY(contentRect) + 2.0 + (trackHeight - thumbHeight) * scroll / maximumScroll;
        [[NSColor colorWithWhite:0.75 alpha:0.48] setFill];
        NSRectFill(NSMakeRect(NSMaxX(contentRect) - 3.0, thumbY, 2.0, thumbHeight));
    }
    [NSGraphicsContext restoreGraphicsState];
}
- (id<MTLTexture>)rasterizeMultilineNode:(CJGuiInternalComposableSceneNode *)node
                                   active:(BOOL)active
                                    scale:(CGFloat)scale
                             outByteCount:(uint64_t *)outByteCount
                           outTextureRect:(NSRect *)outTextureRect
#ifdef CJGUI_INTERNAL_TESTING
                                   reason:(CjguiInternalTextWorkReason)reason
#endif
                                   {
    if (outByteCount) *outByteCount = 0;
    if (outTextureRect) *outTextureRect = NSZeroRect;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t rasterStarted = CjguiMonotonicMicros();
#endif
    CJGuiInternalMetalView *metalView = self.session.view;
    if (!metalView || !node || node.node.width <= 0 || node.node.height <= 0) return nil;
    NSRect textureRect = CjguiComposableTextTextureRectForNode(node);
    if (NSIsEmptyRect(textureRect)) return nil;
    NSUInteger width = 0, height = 0, bytesPerRow = 0;
    uint64_t byteCount = 0;
    if (!CjguiCheckedComposableTextTextureBytes(NSWidth(textureRect), NSHeight(textureRect),
                                                scale, scale, &width, &height, &bytesPerRow, &byteCount)) return nil;
    NSMutableData *bgra = [NSMutableData dataWithLength:(NSUInteger)byteCount];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef bitmap = colorSpace ? CGBitmapContextCreate(bgra.mutableBytes, width, height, 8, bytesPerRow,
        colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little) : NULL;
    if (colorSpace) CGColorSpaceRelease(colorSpace);
    NSGraphicsContext *context = bitmap ? [NSGraphicsContext graphicsContextWithCGContext:bitmap flipped:YES] : nil;
    if (!bgra || !bitmap || !context) { if (bitmap) CGContextRelease(bitmap); return nil; }
    NSGraphicsContext *previousContext = NSGraphicsContext.currentContext;
    [NSGraphicsContext setCurrentContext:context];
#ifdef CJGUI_INTERNAL_TESTING
    if (CjguiTestVerboseGlyphDiagnosticsEnabled()) NSLog(@"cjgui: multiline offscreen target node=%llu bitmap=%p current=%p flipped=%d size=%lux%lu scale=%.3f",
          node.node.nodeId, bitmap, NSGraphicsContext.currentContext.CGContext,
          NSGraphicsContext.currentContext.isFlipped, (unsigned long)width, (unsigned long)height, scale);
#endif
    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform scaleXBy:scale yBy:scale];
    [transform translateXBy:(NSMinX(textureRect) - (CGFloat)node.node.x) * -1.0
                       yBy:(NSMinY(textureRect) - (CGFloat)node.node.y) * -1.0];
    [transform concat];
    CJGuiInternalComposableSceneNode *localNode = [[CJGuiInternalComposableSceneNode alloc] init];
    CjguiInternalRendererComposableNode localValue = node.node;
    localValue.x = 0; localValue.y = 0;
    localValue.clipX -= node.node.x; localValue.clipY -= node.node.y;
    if (localValue.clipConstraintCount > 0 &&
        localValue.clipConstraintCount <= CJGUI_INTERNAL_COMPOSABLE_CLIP_CONSTRAINT_CAPACITY) {
        localValue.clip0X -= node.node.x; localValue.clip0Y -= node.node.y;
        localValue.clip1X -= node.node.x; localValue.clip1Y -= node.node.y;
        localValue.clip2X -= node.node.x; localValue.clip2Y -= node.node.y;
        localValue.clip3X -= node.node.x; localValue.clip3Y -= node.node.y;
    }
    localNode.node = localValue; localNode.label = node.label; localNode.value = node.value;
    // This calls the same active TextKit graph/cache used for input, scroll,
    // selection and candidate geometry.  No second editable body or layout
    // owner is created for the Metal projection.
    [self drawMultilineNode:localNode active:active];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext setCurrentContext:previousContext];
    uint8_t *pixels = bgra.mutableBytes;
#ifdef CJGUI_INTERNAL_TESTING
    NSUInteger firstX = width, firstY = height, lastX = 0, lastY = 0;
    BOOL hasPixels = NO;
#endif
    for (NSUInteger y = 0; y < height; y++) {
        uint8_t *row = pixels + y * bytesPerRow;
        for (NSUInteger x = 0; x < width; x++) {
            uint8_t *pixel = row + x * 4;
            uint8_t alpha = pixel[3];
#ifdef CJGUI_INTERNAL_TESTING
            if (alpha != 0) {
                hasPixels = YES; firstX = MIN(firstX, x); firstY = MIN(firstY, y); lastX = MAX(lastX, x); lastY = MAX(lastY, y);
            }
#endif
            pixel[0] = alpha == 0 ? 0 : (uint8_t)MIN(255, (pixel[0] * 255 + alpha / 2) / alpha);
            pixel[1] = alpha == 0 ? 0 : (uint8_t)MIN(255, (pixel[1] * 255 + alpha / 2) / alpha);
            pixel[2] = alpha == 0 ? 0 : (uint8_t)MIN(255, (pixel[2] * 255 + alpha / 2) / alpha);
        }
    }
#ifdef CJGUI_INTERNAL_TESTING
    if (active && CjguiTestVerboseGlyphDiagnosticsEnabled()) NSLog(@"cjgui: multiline raster bitmap node=%llu hasPixels=%d bounds=%lu,%lu-%lu,%lu size=%lux%lu",
                      node.node.nodeId, hasPixels, (unsigned long)firstX, (unsigned long)firstY,
                      (unsigned long)lastX, (unsigned long)lastY, (unsigned long)width, (unsigned long)height);
#endif
    CGContextRelease(bitmap);
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                            width:width height:height mipmapped:NO];
    descriptor.usage = MTLTextureUsageShaderRead;
    descriptor.storageMode = MTLStorageModeShared;
    id<MTLTexture> texture = [metalView.device newTextureWithDescriptor:descriptor];
    if (!texture) return nil;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t uploadStarted = CjguiMonotonicMicros();
    NSString *recordedText = active ? self.inputProxy.string : node.value;
    CjguiRecordTextWork(metalView, node.node.projectionVersion,
                        [recordedText lengthOfBytesUsingEncoding:NSUTF8StringEncoding], reason);
    metalView.testComposableTextRasterCount = CjguiSaturatingAddU64(metalView.testComposableTextRasterCount, 1);
    metalView.testComposableTextRasterBytes = CjguiSaturatingAddU64(metalView.testComposableTextRasterBytes, byteCount);
    metalView.testComposableTextRasterMicros = CjguiSaturatingAddU64(metalView.testComposableTextRasterMicros,
                                                                       uploadStarted - rasterStarted);
#endif
    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:bgra.bytes bytesPerRow:bytesPerRow];
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t uploadEnded = CjguiMonotonicMicros();
    metalView.testComposableTextUploadCount = CjguiSaturatingAddU64(metalView.testComposableTextUploadCount, 1);
    metalView.testComposableTextUploadBytes = CjguiSaturatingAddU64(metalView.testComposableTextUploadBytes, byteCount);
    metalView.testComposableTextUploadMicros = CjguiSaturatingAddU64(metalView.testComposableTextUploadMicros,
                                                                       uploadEnded - uploadStarted);
#endif
    if (outByteCount) *outByteCount = byteCount;
    if (outTextureRect) *outTextureRect = textureRect;
    return texture;
}
- (void)refreshGpuTextForActiveInput {
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t refreshStarted = CjguiMonotonicMicros();
#endif
    CJGuiInternalMetalView *metalView = self.session.view;
    if (!metalView || self.activeNodeId == 0 || !CjguiComposableNodeUsesGpuText(self.activeNodeKind)) return;
    CJGuiInternalComposableSceneNode *active = nil;
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        if (node.node.nodeId == self.activeNodeId && node.index == self.activeNodeIndex &&
            node.node.resourceId == self.activeNodeResourceId && node.node.nodeKind == self.activeNodeKind &&
            node.node.projectionVersion == self.activeProjectionVersion) {
            active = node;
            break;
        }
    }
    if (!active || active.node.clipWidth <= 0 || active.node.clipHeight <= 0) return;
    NSString *activeValue = self.inputProxy.string ?: @"";
    CGFloat scale = metalView.window ? metalView.window.backingScaleFactor : NSScreen.mainScreen.backingScaleFactor;
    scale = MAX(1.0, scale);
    if (active.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        [self prepareActiveMultilineFallbackRunsForNode:active];
        NSArray<NSValue *> *previousSelectionRects = active.textSelectionRects;
        NSArray<NSValue *> *previousMarkedRects = active.textMarkedRects;
        NSRect previousCaretRect = active.textCaretRect;
        [self updateActiveMultilineTextDecorationsForNode:active];
        NSRect textureRect = CjguiComposableTextTextureRectForNode(active);
        NSString *key = [NSString stringWithFormat:@"multiline:%@:%@:%0.3f:%0.3f:%0.3f:%0.3f:%0.3f:%0.3f:%0.3f:%0.3f:%@", activeValue,
            self.activeTextLayoutSignature ?: @"",
            [self multilineScrollOffsetForNode:active], scale,
            NSMinX(textureRect), NSMinY(textureRect), NSWidth(textureRect), NSHeight(textureRect),
            NSMinX(textureRect) - (CGFloat)active.node.x, NSMinY(textureRect) - (CGFloat)active.node.y,
            CjguiComposableTextClipSignature(active)];
        BOOL forceFullBodyPreparation = NO;
#ifdef CJGUI_INTERNAL_TESTING
        forceFullBodyPreparation = self.testForceFullBodyPreparationOnSelection;
#endif
        if (!active.textTexture || forceFullBodyPreparation || ![active.textTextureCacheKey isEqualToString:key]) {
#ifdef CJGUI_INTERNAL_TESTING
            CjguiInternalTextWorkReason reason = self.testActiveTextWorkReason;
            self.testForceFullBodyPreparationOnSelection = NO;
            if ([self.activeTextTextureRetryKey isEqualToString:key] && self.activeTextTextureRetryCount > 0) {
                reason = CjguiInternalTextWorkReasonRetry;
            }
#endif
            if (![self.activeTextTextureRetryKey isEqualToString:key]) {
                self.activeTextTextureRetryKey = key;
                self.activeTextTextureRetryCount = 0;
                self.activeTextTexturePreparationFailed = NO;
            }
            uint64_t byteCount = 0;
            NSRect preparedRect = NSZeroRect;
            id<MTLTexture> texture = nil;
#ifdef CJGUI_INTERNAL_TESTING
            if (self.session.forcedComposableTextPreparationFailures > 0) {
                self.session.forcedComposableTextPreparationFailures -= 1;
            } else
#endif
            {
                texture = [self rasterizeMultilineNode:active active:YES scale:scale
                                          outByteCount:&byteCount outTextureRect:&preparedRect
#ifdef CJGUI_INTERNAL_TESTING
                                          reason:reason
#endif
                                          ];
            }
            if (texture && CjguiComposableTextTextureFitsSceneBudget(self.nodes, active, byteCount)) {
                active.textTexture = texture; active.textTextureByteCount = byteCount; active.textTextureCacheKey = key;
                active.textTextureRect = preparedRect;
                self.activeTextTextureRetryKey = nil;
                self.activeTextTextureRetryCount = 0;
                self.activeTextTexturePreparationFailed = NO;
#ifdef CJGUI_INTERNAL_TESTING
                self.testActiveTextWorkReason = CjguiInternalTextWorkReasonUnknown;
#endif
            } else {
                // Do not discard the accepted projection while a derived
                // active texture allocation fails. One deferred retry handles
                // transient pressure even when the user types nothing else;
                // a repeated failure remains explicit and bounded.
                // Decorations belong to the same accepted content snapshot:
                // do not let a new caret/selection geometry overlay an old
                // retained body while this candidate is still rejected.
                active.textSelectionRects = previousSelectionRects;
                active.textMarkedRects = previousMarkedRects;
                active.textCaretRect = previousCaretRect;
                self.activeTextTexturePreparationFailed = YES;
                if (self.activeTextTextureRetryCount < 1) {
                    self.activeTextTextureRetryCount += 1;
                    [self scheduleActiveTextResourcePreparation];
                }
            }
        }
        [metalView setNeedsDisplay:YES];
#ifdef CJGUI_INTERNAL_TESTING
        self.testInputCallbackTrace.refreshMicros += CjguiMonotonicMicros() - refreshStarted;
#endif
        return;
    }
    NSString *displayText = CjguiComposableGpuTextValueWithActiveValue(active, activeValue);
    NSUInteger prefixLength = active.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT || active.label.length == 0
        ? 0 : active.label.length + 1;
    NSRange selected = CjguiComposedSelection(activeValue, self.inputProxy.selectedRange.location,
                                              NSMaxRange(self.inputProxy.selectedRange));
    selected.location = MIN(displayText.length, prefixLength + selected.location);
    selected.length = MIN(selected.length, displayText.length - selected.location);
    NSRange marked = self.inputProxy.markedRange;
    if (marked.location != NSNotFound) {
        marked.location = MIN(displayText.length, prefixLength + marked.location);
        marked.length = MIN(marked.length, displayText.length - marked.location);
    }
    BOOL drawsCaret = selected.length == 0 && self.window.firstResponder == self.inputProxy;
    NSArray<NSValue *> *previousSelectionRects = active.textSelectionRects;
    NSArray<NSValue *> *previousMarkedRects = active.textMarkedRects;
    NSRect previousCaretRect = active.textCaretRect;
    [self updateActiveSingleLineTextDecorationsForNode:active displayText:displayText selection:selected
                                            markedRange:marked drawsCaret:drawsCaret];
    NSRect textureRect = CjguiComposableTextTextureRectForNode(active);
    NSString *key = CjguiComposableTextTextureKey(active, scale, scale, displayText, textureRect);
    if (!active.textTexture || ![active.textTextureCacheKey isEqualToString:key]) {
#ifdef CJGUI_INTERNAL_TESTING
        CjguiInternalTextWorkReason reason = self.testActiveTextWorkReason;
        if ([self.activeTextTextureRetryKey isEqualToString:key] && self.activeTextTextureRetryCount > 0) {
            reason = CjguiInternalTextWorkReasonRetry;
        }
#endif
        if (![self.activeTextTextureRetryKey isEqualToString:key]) {
            self.activeTextTextureRetryKey = key;
            self.activeTextTextureRetryCount = 0;
            self.activeTextTexturePreparationFailed = NO;
        }
        uint64_t byteCount = 0;
        id<MTLTexture> texture = nil;
#ifdef CJGUI_INTERNAL_TESTING
        if (self.session.forcedComposableTextPreparationFailures > 0) {
            self.session.forcedComposableTextPreparationFailures -= 1;
        } else
#endif
        {
            texture = CjguiRasterComposableTextTexture(metalView, active, scale, scale, displayText,
                                                        textureRect, &byteCount
#ifdef CJGUI_INTERNAL_TESTING
                                                        , reason
#endif
                                                        );
        }
        if (texture && CjguiComposableTextTextureFitsSceneBudget(self.nodes, active, byteCount)) {
            active.textTexture = texture; active.textTextureByteCount = byteCount; active.textTextureCacheKey = key;
            active.textTextureRect = textureRect;
            self.activeTextTextureRetryKey = nil;
            self.activeTextTextureRetryCount = 0;
            self.activeTextTexturePreparationFailed = NO;
#ifdef CJGUI_INTERNAL_TESTING
            self.testActiveTextWorkReason = CjguiInternalTextWorkReasonUnknown;
#endif
        } else {
            // Focused single-line fields share the same accepted-scene budget
            // and bounded recovery contract as focused multiline fields.  The
            // old texture remains installed until an admitted replacement is
            // ready, so an allocation failure cannot blank live input.
            active.textSelectionRects = previousSelectionRects;
            active.textMarkedRects = previousMarkedRects;
            active.textCaretRect = previousCaretRect;
            self.activeTextTexturePreparationFailed = YES;
            if (self.activeTextTextureRetryCount < 1) {
                self.activeTextTextureRetryCount += 1;
                [self scheduleActiveTextResourcePreparation];
            }
        }
    }
    // The TextKit object remains only the first-responder/IME authority. Its
    // glyph body is the derived texture while its transient decorations are
    // regular Metal geometry, and later scene nodes retain painter order.
    [metalView setNeedsDisplay:YES];
#ifdef CJGUI_INTERNAL_TESTING
    self.testInputCallbackTrace.refreshMicros += CjguiMonotonicMicros() - refreshStarted;
#endif
}
- (void)markActiveTextFallbackRunsDirtyForRange:(NSRange)range {
    self.activeTextFallbackRunsDirty = YES;
    if (self.activeTextFallbackNeedsFullRefresh || range.location == NSNotFound) return;
    if (!self.activeTextFallbackHasDirtyRange) {
        self.activeTextFallbackDirtyRange = range;
        self.activeTextFallbackHasDirtyRange = YES;
        return;
    }
    NSUInteger start = MIN(self.activeTextFallbackDirtyRange.location, range.location);
    NSUInteger leftEnd = NSMaxRange(self.activeTextFallbackDirtyRange);
    NSUInteger rightEnd = NSMaxRange(range);
    if (leftEnd < self.activeTextFallbackDirtyRange.location || rightEnd < range.location) {
        self.activeTextFallbackNeedsFullRefresh = YES;
        self.activeTextFallbackHasDirtyRange = NO;
        return;
    }
    self.activeTextFallbackDirtyRange = NSMakeRange(start, MAX(leftEnd, rightEnd) - start);
}
- (void)markActiveTextFallbackRunsDirtyForWholeValue {
    self.activeTextFallbackRunsDirty = YES;
    self.activeTextFallbackNeedsFullRefresh = YES;
    self.activeTextFallbackHasDirtyRange = NO;
}
- (void)remapActiveTextFallbackDirtyRangeForEditRange:(NSRange)range replacementLength:(NSUInteger)replacementLength {
    if (!self.activeTextFallbackHasDirtyRange || self.activeTextFallbackNeedsFullRefresh ||
        range.location == NSNotFound || range.location > NSUIntegerMax - range.length) return;
    NSRange prior = self.activeTextFallbackDirtyRange;
    if (prior.location == NSNotFound || prior.location > NSUIntegerMax - prior.length) {
        [self markActiveTextFallbackRunsDirtyForWholeValue];
        return;
    }
    NSUInteger editStart = range.location, editEnd = NSMaxRange(range);
    NSUInteger priorStart = prior.location, priorEnd = NSMaxRange(prior);
    if (priorEnd <= editStart) return;
    if (replacementLength > NSUIntegerMax - editStart) {
        [self markActiveTextFallbackRunsDirtyForWholeValue];
        return;
    }
    NSUInteger replacementEnd = editStart + replacementLength;
    NSInteger delta = replacementLength >= range.length
        ? (NSInteger)MIN((NSUInteger)NSIntegerMax, replacementLength - range.length)
        : -(NSInteger)MIN((NSUInteger)NSIntegerMax, range.length - replacementLength);
    NSUInteger mappedStart = priorStart, mappedEnd = priorEnd;
    if (priorStart >= editEnd) {
        if ((delta >= 0 && priorStart > NSUIntegerMax - (NSUInteger)delta) ||
            (delta < 0 && priorStart < (NSUInteger)(-delta)) ||
            (delta >= 0 && priorEnd > NSUIntegerMax - (NSUInteger)delta) ||
            (delta < 0 && priorEnd < (NSUInteger)(-delta))) {
            [self markActiveTextFallbackRunsDirtyForWholeValue];
            return;
        }
        mappedStart = delta >= 0 ? priorStart + (NSUInteger)delta : priorStart - (NSUInteger)(-delta);
        mappedEnd = delta >= 0 ? priorEnd + (NSUInteger)delta : priorEnd - (NSUInteger)(-delta);
    } else {
        // An edit intersects a previously dirty run. Its surviving suffix is
        // shifted into the new document; include both it and replacement.
        mappedStart = MIN(priorStart, editStart);
        if (priorEnd > editEnd) {
            if ((delta >= 0 && priorEnd > NSUIntegerMax - (NSUInteger)delta) ||
                (delta < 0 && priorEnd < (NSUInteger)(-delta))) {
                [self markActiveTextFallbackRunsDirtyForWholeValue];
                return;
            }
            mappedEnd = delta >= 0 ? priorEnd + (NSUInteger)delta : priorEnd - (NSUInteger)(-delta);
        } else {
            mappedEnd = replacementEnd;
        }
        mappedEnd = MAX(mappedEnd, replacementEnd);
    }
    self.activeTextFallbackDirtyRange = NSMakeRange(mappedStart, mappedEnd - mappedStart);
}
- (NSRange)fallbackAffectedRangeAfterEditAt:(NSUInteger)location replacementLength:(NSUInteger)replacementLength
                                      value:(NSString *)value {
    NSUInteger length = value.length;
    if (length == 0) return NSMakeRange(0, 0);
    NSUInteger start = MIN(location, length);
    NSUInteger end = replacementLength > NSUIntegerMax - start ? length : MIN(length, start + replacementLength);
    // Include one adjacent composed sequence on each side: deleting a ZWJ,
    // variation selector or combining mark can join what used to be two runs.
    if (start > 0) start = [value rangeOfComposedCharacterSequenceAtIndex:start - 1].location;
    if (start < length) start = [value rangeOfComposedCharacterSequenceAtIndex:start].location;
    if (end > 0) end = NSMaxRange([value rangeOfComposedCharacterSequenceAtIndex:end - 1]);
    if (end < length) end = NSMaxRange([value rangeOfComposedCharacterSequenceAtIndex:end]);
    return NSMakeRange(start, end - start);
}
- (void)applySystemFallbackRunsToActiveInput {
    if (self.activeNodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT || !self.activeTextBaseFont ||
        self.inputProxy.hasMarkedText) return;
    NSTextStorage *storage = self.inputProxy.textStorage;
    NSString *value = storage.string ?: @"";
    if (value.length == 0) {
        self.activeTextFallbackRunsDirty = NO;
        self.activeTextFallbackNeedsFullRefresh = NO;
        self.activeTextFallbackHasDirtyRange = NO;
        return;
    }
    NSFont *baseFont = self.activeTextBaseFont;
    NSRange requested = self.activeTextFallbackNeedsFullRefresh ? NSMakeRange(0, value.length) :
        (self.activeTextFallbackHasDirtyRange ? self.activeTextFallbackDirtyRange : NSMakeRange(NSNotFound, 0));
    if (requested.location == NSNotFound) {
        self.activeTextFallbackRunsDirty = NO;
        self.activeTextFallbackNeedsFullRefresh = NO;
        self.activeTextFallbackHasDirtyRange = NO;
        return;
    }
    NSUInteger requestedStart = MIN(requested.location, value.length);
    NSUInteger requestedEnd = requested.length > NSUIntegerMax - requestedStart ? value.length :
        MIN(value.length, requestedStart + requested.length);
    // A zero-length deletion still changes the new left/right boundary. The
    // caller normally expands it, but retain a one-cluster fail-safe here.
    if (requestedStart == requestedEnd) {
        if (requestedStart > 0) requestedStart = [value rangeOfComposedCharacterSequenceAtIndex:requestedStart - 1].location;
        if (requestedEnd < value.length) requestedEnd = NSMaxRange([value rangeOfComposedCharacterSequenceAtIndex:requestedEnd]);
    }
    if (requestedStart >= value.length || requestedEnd <= requestedStart) {
        self.activeTextFallbackRunsDirty = NO;
        self.activeTextFallbackNeedsFullRefresh = NO;
        self.activeTextFallbackHasDirtyRange = NO;
        return;
    }
    requested.location = [value rangeOfComposedCharacterSequenceAtIndex:requestedStart].location;
    if (requestedEnd > 0) requestedEnd = NSMaxRange([value rangeOfComposedCharacterSequenceAtIndex:requestedEnd - 1]);
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t fallbackStarted = CjguiMonotonicMicros();
#endif
    BOOL wasApplyingProjection = self.applyingProjection;
    self.applyingProjection = YES;
    [storage beginEditing];
    for (NSUInteger location = requested.location; location < requestedEnd;) {
        NSRange range = [value rangeOfComposedCharacterSequenceAtIndex:location];
        NSDictionary *current = [storage attributesAtIndex:location effectiveRange:NULL] ?: @{};
        CTFontRef resolved = CTFontCreateForString((__bridge CTFontRef)baseFont,
                                                   (__bridge CFStringRef)value,
                                                   CFRangeMake(range.location, range.length));
        if (resolved) {
            NSMutableDictionary *attributes = [current mutableCopy];
            attributes[NSFontAttributeName] = (__bridge NSFont *)resolved;
            [storage setAttributes:attributes range:range];
            CFRelease(resolved);
        }
        location = NSMaxRange(range);
    }
    [storage endEditing];
    self.applyingProjection = wasApplyingProjection;
#ifdef CJGUI_INTERNAL_TESTING
    self.testInputCallbackTrace.fallbackApplyCount += 1;
    self.testInputCallbackTrace.fallbackCharacters += requestedEnd - requested.location;
    self.testInputCallbackTrace.fallbackMicros += CjguiMonotonicMicros() - fallbackStarted;
#endif
    self.activeTextFallbackRunsDirty = NO;
    self.activeTextFallbackNeedsFullRefresh = NO;
    self.activeTextFallbackHasDirtyRange = NO;
}
- (void)prepareActiveMultilineFallbackRunsForNode:(CJGuiInternalComposableSceneNode *)node {
    if (!node || node.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) return;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t preparationStarted = CjguiMonotonicMicros();
#endif
    NSRect contentRect = NSInsetRect(CjguiComposableRect(node, self), 7.0, 6.0);
    NSColor *textColor = [NSColor colorWithSRGBRed:node.node.textRed green:node.node.textGreen
                                              blue:node.node.textBlue alpha:node.node.textAlpha];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSFont *baseFont = CjguiComposableFont(node);
    NSDictionary *attributes = @{ NSFontAttributeName: baseFont,
                                  NSForegroundColorAttributeName: textColor,
                                  NSParagraphStyleAttributeName: paragraph };
    self.inputProxy.textContainer.maximumNumberOfLines = 0;
    self.inputProxy.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    self.inputProxy.textContainer.containerSize = NSMakeSize(NSWidth(contentRect), CGFLOAT_MAX);
    self.inputProxy.textContainer.widthTracksTextView = NO;
    NSString *signature = [self activeTextLayoutSignatureForNode:node contentWidth:NSWidth(contentRect)];
    if (![signature isEqualToString:self.activeTextLayoutSignature]) {
        self.applyingProjection = YES;
        if (self.inputProxy.string.length > 0) {
            [self.inputProxy.textStorage setAttributes:attributes range:NSMakeRange(0, self.inputProxy.string.length)];
#ifdef CJGUI_INTERNAL_TESTING
            self.testInputCallbackTrace.wholeAttributeWriteCount += 1;
            self.testInputCallbackTrace.wholeAttributeCharacters += self.inputProxy.string.length;
#endif
        }
        self.inputProxy.typingAttributes = attributes;
        self.applyingProjection = NO;
        self.activeTextLayoutSignature = signature;
        self.activeTextBaseFont = baseFont;
        self.activeTextLayoutNeedsVisibleGlyphs = YES;
        self.activeTextHasExactContentHeight = NO;
        self.activeTextKnownContentHeight = 0.0;
        [self markActiveTextFallbackRunsDirtyForWholeValue];
    } else if (!self.activeTextBaseFont) {
        // A reused active identity can retain its layout signature across a
        // native focus hand-off; restore the value-owned base deterministically.
        self.activeTextBaseFont = baseFont;
    }
    if (self.activeTextFallbackRunsDirty && !self.inputProxy.hasMarkedText) {
        [self applySystemFallbackRunsToActiveInput];
        self.activeTextFallbackRunsDirty = NO;
    }
#ifdef CJGUI_INTERNAL_TESTING
    self.testInputCallbackTrace.preparationMicros += CjguiMonotonicMicros() - preparationStarted;
#endif
}
- (void)scheduleActiveTextResourcePreparation {
    if (self.activeTextResourcePreparationScheduled ||
        (self.activeNodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         self.activeNodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         self.activeNodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) return;
    self.activeTextResourcePreparationScheduled = YES;
    __weak CJGuiInternalComposableSceneOverlay *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        CJGuiInternalComposableSceneOverlay *overlay = weakSelf;
        if (!overlay) return;
        overlay.activeTextResourcePreparationScheduled = NO;
        [overlay refreshGpuTextForActiveInput];
        [overlay setNeedsDisplay:YES];
    });
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    for (CJGuiInternalComposableSceneNode *node in self.nodes) {
        NSRect rect = CjguiComposableRect(node, self);
        if (NSIsEmptyRect(NSIntersectionRect(rect, CjguiComposableClipBounds(node)))) continue;
        uint32_t kind = node.node.nodeKind;
        if (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT &&
            kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON &&
            kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
            kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
            kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
            kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) continue;
        BOOL isActiveTextNode = (node.node.nodeId == self.activeNodeId &&
            node.node.projectionVersion == self.activeProjectionVersion &&
            node.node.resourceId == self.activeNodeResourceId &&
            node.node.nodeKind == self.activeNodeKind &&
            (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
             kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
             kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT));
        // Single-line text, including the focused TextKit adapter state, is
        // always submitted through the scene texture above.  The overlay
        // retains only multiline drawing, which still reuses the one TextKit
        // layout graph for scroll/candidate geometry.
        if (CjguiComposableNodeUsesGpuText(kind)) continue;
        if (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
            [self drawMultilineNode:node active:isActiveTextNode];
            continue;
        }
        NSString *activeValue = isActiveTextNode ? self.inputProxy.string : node.value;
        NSString *text = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ? node.value :
            (node.label.length > 0 ? [NSString stringWithFormat:@"%@ %@", node.label, activeValue] : activeValue);
        NSRect visibleRect = NSIntersectionRect(rect, CjguiComposableClipBounds(node));
        if (NSIsEmptyRect(visibleRect)) continue;
        NSColor *textColor = [NSColor colorWithSRGBRed:node.node.textRed
                                                  green:node.node.textGreen
                                                   blue:node.node.textBlue
                                                  alpha:node.node.textAlpha];
        [NSGraphicsContext saveGraphicsState];
        CjguiClipComposableNode(node, self);
        NSRectClip(visibleRect);
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.lineBreakMode = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ? NSLineBreakByCharWrapping :
            (kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail);
        NSDictionary *attributes = @{ NSFontAttributeName: CjguiComposableFont(node), NSForegroundColorAttributeName: textColor,
                                      NSParagraphStyleAttributeName: paragraph };
        // Layout reserves four vertical points for text. Keep the actual
        // glyph rect in that declared allowance; inputs retain the larger
        // inset needed for their control chrome.
        CGFloat verticalInset = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ? 2.0 : 6.0;
        // Keep this 7pt horizontal inset aligned with
        // CJGUI_COMPOSABLE_UI_TEXT_HORIZONTAL_INSET in composable_ui.cj.
        // Layout measures against the remaining content width before it
        // decides the node's height, so the two paths cannot disagree about
        // wrapping at a narrow boundary.
        NSRect textRect = NSInsetRect(rect, 7.0, verticalInset);
        if (isActiveTextNode) {
            NSUInteger length = activeValue.length;
            NSUInteger selectionStart = MIN(self.inputProxy.selectedRange.location, length);
            NSUInteger selectionEnd = MIN(NSMaxRange(self.inputProxy.selectedRange), length);
            CGFloat prefix = node.label.length > 0 ? [[NSString stringWithFormat:@"%@ ", node.label] sizeWithAttributes:attributes].width : 0.0;
            CGFloat before = [[activeValue substringToIndex:selectionStart] sizeWithAttributes:attributes].width;
            CGFloat selected = [[activeValue substringWithRange:NSMakeRange(selectionStart, selectionEnd - selectionStart)] sizeWithAttributes:attributes].width;
            if (selectionEnd > selectionStart) {
                [[NSColor selectedTextBackgroundColor] setFill];
                NSRectFill(NSMakeRect(NSMinX(textRect) + prefix + before, NSMinY(textRect), MAX(1.0, selected), NSHeight(textRect)));
            } else if (self.window.firstResponder == self.inputProxy) {
                [[NSColor keyboardFocusIndicatorColor] setFill];
                NSRectFill(NSMakeRect(NSMinX(textRect) + prefix + before, NSMinY(textRect) + 2.0, 1.0, MAX(1.0, NSHeight(textRect) - 4.0)));
            }
        }
        [text drawWithRect:textRect
                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                 attributes:attributes];
        if (node.node.nodeId == self.activeNodeId && node.node.resourceId == self.activeNodeResourceId &&
            node.node.nodeKind == self.activeNodeKind &&
            self.window.firstResponder == self) {
            [[NSColor keyboardFocusIndicatorColor] setStroke];
            NSFrameRectWithWidth(NSInsetRect(rect, 1.0, 1.0), 1.0);
        }
        [NSGraphicsContext restoreGraphicsState];
    }
    // Reused COW nodes retain their original per-node capture generation;
    // draw progress belongs to the committed scene snapshot, not the largest
    // mutable node field. Native FIFO events already use this same session
    // generation and Cangjie validates it against its input scene.
    uint64_t drawnVersion = self.session.composableSceneVersion;
    if (drawnVersion > 0) self.lastDrawnProjectionVersion = drawnVersion;
}
@end

@implementation CJGuiInternalComposableInputProxy
- (void)scrollRangeToVisible:(NSRange)range {
    // NSTextView normally realizes layout through the selection so it can
    // scroll its own document view. This proxy is intentionally off-canvas;
    // the composable overlay owns the visible viewport and performs explicit
    // scroll/caret geometry when needed. Letting the hidden view do that work
    // turns every long-document insertion into a whole-range realization.
    (void)range;
}
- (void)setMarkedText:(id)string selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {
    if (!self.hasMarkedText) {
        self.compositionBaseString = self.string ?: @"";
        self.compositionBaseSelection = self.selectedRange;
    }
    [super setMarkedText:string selectedRange:selectedRange replacementRange:replacementRange];
#ifdef CJGUI_INTERNAL_TESTING
    self.composableOverlay.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
    [(id)self.composableOverlay refreshGpuTextForActiveInput];
}
- (void)unmarkText {
    [super unmarkText];
    self.compositionBaseString = nil;
    self.compositionBaseSelection = NSMakeRange(0, 0);
#ifdef CJGUI_INTERNAL_TESTING
    self.composableOverlay.testActiveTextWorkReason = CjguiInternalTextWorkReasonSelectionCaret;
#endif
    [(id)self.composableOverlay refreshGpuTextForActiveInput];
}
- (void)insertText:(id)string replacementRange:(NSRange)replacementRange {
#ifdef CJGUI_INTERNAL_TESTING
    if (!self.hasMarkedText && self.composableOverlay.testUsesBoundedInputLayout) {
        // Test-only control for the retired bounded-edit experiment. The
        // production multiline adapter keeps one wrapping/container contract
        // through super, caret geometry and its texture refresh.
        uint64_t modeStarted = CjguiMonotonicMicros();
        if (self.textContainer.maximumNumberOfLines != 1) {
            self.textContainer.maximumNumberOfLines = 1;
            self.composableOverlay.testInputCallbackTrace.modeChangeCount += 1;
        }
        if (self.textContainer.lineBreakMode != NSLineBreakByTruncatingTail) {
            self.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
            self.composableOverlay.testInputCallbackTrace.modeChangeCount += 1;
        }
        self.composableOverlay.testInputCallbackTrace.modeChangeMicros += CjguiMonotonicMicros() - modeStarted;
    }
    uint64_t superInsertStarted = CjguiMonotonicMicros();
#endif
    [super insertText:string replacementRange:replacementRange];
#ifdef CJGUI_INTERNAL_TESTING
    self.composableOverlay.testInputCallbackTrace.superInsertMicros += CjguiMonotonicMicros() - superInsertStarted;
#endif
    self.compositionBaseString = nil;
    self.compositionBaseSelection = NSMakeRange(0, 0);
#ifdef CJGUI_INTERNAL_TESTING
    self.composableOverlay.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
    [(id)self.composableOverlay refreshGpuTextForActiveInput];
}
- (void)cancelMarkedText {
    if (!self.hasMarkedText) return;
    NSString *base = self.compositionBaseString ?: @"";
    NSRange selection = CjguiComposedSelection(base, self.compositionBaseSelection.location,
                                                NSMaxRange(self.compositionBaseSelection));
    // Assigning the preserved committed adapter string avoids treating
    // `unmarkText` as cancellation: TextKit's unmark operation makes the
    // current preedit ordinary text on several input sources.
    self.string = base;
    self.selectedRange = selection;
    self.compositionBaseString = nil;
    self.compositionBaseSelection = NSMakeRange(0, 0);
#ifdef CJGUI_INTERNAL_TESTING
    self.composableOverlay.testActiveTextWorkReason = CjguiInternalTextWorkReasonActiveContent;
#endif
    [(id)self.composableOverlay refreshGpuTextForActiveInput];
}
- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
    NSRect rect = [self.composableOverlay candidateRectForCharacterRange:range actualRange:actualRange];
    return NSIsEmptyRect(rect) ? [super firstRectForCharacterRange:range actualRange:actualRange] : rect;
}
- (BOOL)handleStandardTextCommandKeyDown:(NSEvent *)event {
    if ((event.modifierFlags & NSEventModifierFlagCommand) == 0) return NO;
    NSString *characters = event.charactersIgnoringModifiers.lowercaseString;
    if ([characters isEqualToString:@"a"]) {
        [self selectAll:nil];
        return YES;
    }
    if ([characters isEqualToString:@"c"]) {
        [self copy:nil];
        return YES;
    }
    if ([characters isEqualToString:@"x"]) {
        [self cut:nil];
        return YES;
    }
    if ([characters isEqualToString:@"v"]) {
        [self paste:nil];
        return YES;
    }
    return NO;
}
- (void)keyDown:(NSEvent *)event {
    // Marked text belongs to the active system input source. A framework
    // shortcut must not turn a composition/candidate operation into an
    // application action before the text service has resolved it.
    if (self.hasMarkedText) {
        if (event.keyCode == 53) [self.composableOverlay cancelActiveComposition];
        else [super keyDown:event];
        return;
    }
    if (event.keyCode == 53) {
        // Escape belongs to the current modal layer when one is present;
        // otherwise preserve NSTextView's ordinary cancellation route.
        [self.composableOverlay keyDown:event];
        return;
    }
    // These are NSTextView operations, not composable window commands. The
    // hidden input adapter is intentionally still their execution owner.
    if ([self handleStandardTextCommandKeyDown:event]) return;
    // AppKit does not necessarily ask its delegate about Command equivalents,
    // so pass remaining Command chords through the generic Cangjie shortcut
    // resolver. It will either resolve a declared command or do nothing; no
    // native application command table exists here.
    if (self.composableOverlay && [self.composableOverlay handleWindowCommandKeyDown:event]) return;
    [super keyDown:event];
}
@end

// ---- shared-operation text/input overlay ----
//
// The overlay is deliberately a projection. It receives human input and
// displays the latest POD state supplied by Cangjie; it never owns or mutates
// application records. All user intent returns through pumpEvent.

@interface CJGuiInternalSharedOperationOverlay : NSView
@property(nonatomic, weak) CJGuiInternalSession *session;
@property(nonatomic, assign) uint32_t recordCount;
@property(nonatomic, assign) CjguiInternalRendererSharedOperationState state;
@property(nonatomic, strong) NSMutableArray<NSString *> *titles;
@property(nonatomic, strong) NSMutableArray<CJGuiInternalSharedOperationAccessibilityAction *> *accessibilityActions;
- (instancetype)initWithFrame:(NSRect)frame session:(CJGuiInternalSession *)session;
- (void)setRecordCountForProjection:(uint32_t)recordCount;
- (void)setTitle:(NSString *)title atIndex:(uint32_t)recordIndex;
- (void)setProjectionState:(CjguiInternalRendererSharedOperationState)state;
- (void)queueInteraction:(uint32_t)kind index:(uint32_t)index;
- (void)queueViewportInteraction:(uint32_t)kind;
- (NSString *)titleForRecordAtIndex:(uint32_t)recordIndex;
- (BOOL)isRecordMarkedAtIndex:(uint32_t)recordIndex;
@end

@implementation CJGuiInternalSharedOperationAccessibilityAction

- (instancetype)initWithOverlay:(CJGuiInternalSharedOperationOverlay *)overlay
                     recordIndex:(uint32_t)recordIndex
                     marksRecord:(BOOL)marksRecord {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.overlay = overlay;
    self.recordIndex = recordIndex;
    self.marksRecord = marksRecord;
    return self;
}

- (id)accessibilityParent {
    return self.overlay;
}

- (NSAccessibilityRole)accessibilityRole {
    return self.marksRecord ? NSAccessibilityCheckBoxRole : NSAccessibilityButtonRole;
}

- (NSString *)accessibilityLabel {
    NSString *title = [self.overlay titleForRecordAtIndex:self.recordIndex];
    return self.marksRecord
        ? [NSString stringWithFormat:@"Mark %@", title]
        : [NSString stringWithFormat:@"Select %@", title];
}

- (id)accessibilityValue {
    if (self.marksRecord) {
        return @([self.overlay isRecordMarkedAtIndex:self.recordIndex]);
    }
    return nil;
}

- (BOOL)isAccessibilityEnabled {
    // NSAccessibilityElement does not infer enabledness from
    // accessibilityPerformPress. This action is usable exactly while its
    // projection and bounded record slot remain valid.
    return self.overlay != nil && self.recordIndex < self.overlay.recordCount;
}

- (NSRect)accessibilityFrame {
    CJGuiInternalSharedOperationOverlay *overlay = self.overlay;
    if (!overlay) {
        return NSZeroRect;
    }
    CGFloat y = 75.0 + (CGFloat)self.recordIndex * 44.0;
    NSRect localFrame = self.marksRecord
        ? NSMakeRect(20.0, y + 3.0, 33.0, 30.0)
        : NSMakeRect(58.0, y + 3.0, MAX(0.0, overlay.bounds.size.width - 78.0), 30.0);
    return NSAccessibilityFrameInView(overlay, localFrame);
}

- (BOOL)accessibilityPerformPress {
    CJGuiInternalSharedOperationOverlay *overlay = self.overlay;
    if (!overlay) {
        return NO;
    }
    [overlay queueInteraction:self.marksRecord
        ? CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_TOGGLE_RECORD
        : CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_SELECT_RECORD
                         index:self.recordIndex];
    return YES;
}

@end

@implementation CJGuiInternalSharedOperationOverlay

- (instancetype)initWithFrame:(NSRect)frame session:(CJGuiInternalSession *)session {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    self.session = session;
    self.titles = [NSMutableArray array];
    self.accessibilityActions = [NSMutableArray array];
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)setRecordCountForProjection:(uint32_t)recordCount {
    // The C ABI validates this as a bounded visible viewport. Do not silently
    // truncate here: a caller accidentally treating this as total data must
    // fail at the ABI boundary rather than receive a misleading projection.
    self.recordCount = recordCount;
    while (self.titles.count < self.recordCount) {
        [self.titles addObject:@"Untitled record"];
    }
    while (self.accessibilityActions.count < self.recordCount * 2) {
        uint32_t actionIndex = (uint32_t)(self.accessibilityActions.count / 2);
        BOOL marksRecord = (self.accessibilityActions.count % 2) == 1;
        [self.accessibilityActions addObject:
            [[CJGuiInternalSharedOperationAccessibilityAction alloc] initWithOverlay:self
                                                                          recordIndex:actionIndex
                                                                          marksRecord:marksRecord]];
    }
    while (self.accessibilityActions.count > self.recordCount * 2) {
        [self.accessibilityActions removeLastObject];
    }
    [self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)title atIndex:(uint32_t)recordIndex {
    if (recordIndex >= self.recordCount) {
        return;
    }
    self.titles[recordIndex] = title ?: @"Untitled record";
    [self setNeedsDisplay:YES];
}

- (void)setProjectionState:(CjguiInternalRendererSharedOperationState)state {
    self.state = state;
    [self setNeedsDisplay:YES];
}

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSAccessibilityRole)accessibilityRole {
    return NSAccessibilityGroupRole;
}

- (NSString *)accessibilityLabel {
    return @"CJGUI shared operation list";
}

- (NSArray<id> *)accessibilityChildren {
    return [self.accessibilityActions copy];
}

- (NSString *)titleForRecordAtIndex:(uint32_t)recordIndex {
    if (recordIndex >= self.titles.count) {
        return @"Untitled record";
    }
    return self.titles[recordIndex];
}

- (BOOL)isRecordMarkedAtIndex:(uint32_t)recordIndex {
    if (recordIndex >= self.recordCount) {
        return NO;
    }
    return (self.state.markedRecordMask & (UINT64_C(1) << recordIndex)) != 0;
}

- (NSDictionary<NSAttributedStringKey, id> *)bodyAttributes {
    return @{
        NSFontAttributeName: [NSFont systemFontOfSize:15.0],
        NSForegroundColorAttributeName: NSColor.labelColor
    };
}

- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [[NSColor colorWithCalibratedWhite:0.97 alpha:0.94] setFill];
    NSRectFill(self.bounds);

    NSDictionary *headingAttributes = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:19.0],
        NSForegroundColorAttributeName: NSColor.labelColor
    };
    [@"CJGUI shared operation list" drawAtPoint:NSMakePoint(22, 18)
                                   withAttributes:headingAttributes];
    [@"Click a row to select it. Click its box or press Space to mark it. Scroll or use Page Up/Down to browse."
        drawAtPoint:NSMakePoint(22, 45)
     withAttributes:@{
        NSFontAttributeName: [NSFont systemFontOfSize:12.0],
        NSForegroundColorAttributeName: NSColor.secondaryLabelColor
     }];

    for (uint32_t index = 0; index < self.recordCount; index++) {
        CGFloat y = 75.0 + (CGFloat)index * 44.0;
        BOOL selected = self.state.selectedRecordIndex == index;
        BOOL marked = (self.state.markedRecordMask & (UINT64_C(1) << index)) != 0;
        NSRect rowRect = NSMakeRect(14, y, MAX(0, self.bounds.size.width - 28), 36);
        if (selected) {
            [[NSColor selectedContentBackgroundColor] setFill];
            NSBezierPath *selection = [NSBezierPath bezierPathWithRoundedRect:rowRect
                                                                        xRadius:6
                                                                        yRadius:6];
            [selection fill];
        }

        NSString *mark = marked ? @"☑" : @"☐";
        NSDictionary *rowAttributes = [self bodyAttributes];
        if (selected) {
            rowAttributes = @{
                NSFontAttributeName: [NSFont systemFontOfSize:15.0],
                NSForegroundColorAttributeName: NSColor.alternateSelectedControlTextColor
            };
        }
        [mark drawAtPoint:NSMakePoint(25, y + 8) withAttributes:rowAttributes];
        NSString *title = self.titles[index];
        [title drawAtPoint:NSMakePoint(58, y + 9) withAttributes:rowAttributes];
    }

    uint32_t firstVisible = self.state.totalRecordCount == 0
        ? 0
        : self.state.viewportStart + 1;
    uint32_t lastVisible = self.state.viewportStart + self.recordCount;
    NSString *viewportLabel = [NSString stringWithFormat:@"Showing %u-%u of %u",
        firstVisible, lastVisible, self.state.totalRecordCount];
    [viewportLabel drawAtPoint:NSMakePoint(MAX(260, self.bounds.size.width - 190), 21)
                  withAttributes:@{
        NSFontAttributeName: [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: NSColor.secondaryLabelColor
    }];

    NSString *footer = [NSString stringWithFormat:@"Version %llu · selected record %lld",
                         self.state.version, self.state.selectedRecordId];
    [footer drawAtPoint:NSMakePoint(22, MAX(75, self.bounds.size.height - 30))
         withAttributes:@{
            NSFontAttributeName: [NSFont monospacedSystemFontOfSize:12.0 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: NSColor.secondaryLabelColor
         }];
}

- (void)queueInteraction:(uint32_t)kind index:(uint32_t)index {
    CJGuiInternalSession *session = self.session;
    if (!session || index >= self.recordCount) {
        return;
    }
    (void)CjguiEnqueueInteraction(session, kind, index, @"", 0, 0);
}

- (void)queueViewportInteraction:(uint32_t)kind {
    CJGuiInternalSession *session = self.session;
    if (!session) {
        return;
    }
    (void)CjguiEnqueueInteraction(session, kind, 0, @"", 0, 0);
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (point.y < 75.0) {
        return;
    }
    uint32_t index = (uint32_t)((point.y - 75.0) / 44.0);
    if (index >= self.recordCount) {
        return;
    }
    if (point.x < 58.0) {
        [self queueInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_TOGGLE_RECORD index:index];
    } else {
        [self queueInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_SELECT_RECORD index:index];
    }
}

- (void)scrollWheel:(NSEvent *)event {
    if (event.scrollingDeltaY > 0.0) {
        [self queueViewportInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_PREVIOUS];
    } else if (event.scrollingDeltaY < 0.0) {
        [self queueViewportInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_NEXT];
    }
}

- (void)keyDown:(NSEvent *)event {
    if (self.recordCount == 0) {
        return;
    }
    uint32_t selectedIndex = self.state.selectedRecordIndex;
    if (selectedIndex >= self.recordCount) {
        selectedIndex = 0;
    }
    if (event.keyCode == 116) {
        [self queueViewportInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_PREVIOUS];
        return;
    }
    if (event.keyCode == 121) {
        [self queueViewportInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_NEXT];
        return;
    }
    if (event.keyCode == 125 && selectedIndex + 1 < self.recordCount) {
        [self queueInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_SELECT_RECORD
                         index:selectedIndex + 1];
        return;
    }
    if (event.keyCode == 126 && selectedIndex > 0) {
        [self queueInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_SELECT_RECORD
                         index:selectedIndex - 1];
        return;
    }
    if (event.keyCode == 49 || event.keyCode == 36) {
        [self queueInteraction:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_TOGGLE_RECORD
                         index:selectedIndex];
    }
}

@end

// ---- shared-editing self-drawn form overlay ----
//
// The visible surface is rendered by this NSView. NSTextView is retained only
// as an off-canvas macOS text-input proxy: it supplies IME, clipboard,
// deletion and UTF-16 selection services, but never presents a field or owns
// application content. Cangjie remains the sole applied/draft truth owner.

@class CJGuiInternalSharedEditingFormAccessibilityAction;

@interface CJGuiInternalSharedEditingFormOverlay : NSView <NSTextViewDelegate>
@property(nonatomic, weak) CJGuiInternalSession *session;
@property(nonatomic, assign) uint32_t fieldCount;
@property(nonatomic, strong) NSMutableArray<NSString *> *fieldLabels;
@property(nonatomic, strong) NSMutableArray<NSString *> *draftTexts;
@property(nonatomic, strong) NSMutableArray<NSString *> *validationErrors;
@property(nonatomic, strong) NSMutableArray<NSNumber *> *editorKinds;
@property(nonatomic, strong) NSMutableArray<CJGuiInternalSharedEditingFormAccessibilityAction *> *accessibilityActions;
@property(nonatomic, strong) NSTextView *inputProxy;
@property(nonatomic, assign) BOOL collectionEnabled;
@property(nonatomic, assign) uint32_t collectionRowCount;
@property(nonatomic, strong) NSMutableArray<NSString *> *collectionTitles;
@property(nonatomic, assign) uint32_t collectionSelectedRow;
@property(nonatomic, assign) uint32_t collectionViewportStart;
@property(nonatomic, assign) uint32_t collectionTotalCount;
@property(nonatomic, copy) NSString *collectionFilterText;
@property(nonatomic, copy) NSString *statusText;
@property(nonatomic, copy) NSString *inputNotice;
@property(nonatomic, assign) NSInteger activeTextFieldIndex;
@property(nonatomic, assign) BOOL applyingProjection;
- (instancetype)initWithFrame:(NSRect)frame session:(CJGuiInternalSession *)session;
- (void)setFieldCountForProjection:(uint32_t)fieldCount;
- (void)setFieldAtIndex:(uint32_t)index label:(NSString *)label draftText:(NSString *)draftText
                   error:(NSString *)error editorKind:(uint32_t)editorKind focused:(BOOL)focused
          selectionStart:(uint32_t)selectionStart selectionEnd:(uint32_t)selectionEnd;
- (void)setStatus:(NSString *)status;
- (NSRect)fieldRectAtIndex:(uint32_t)index;
- (NSRect)applyRect;
- (NSRect)cancelRect;
- (NSRect)collectionRowRectAtIndex:(uint32_t)index;
- (NSRect)collectionCreateRect;
- (NSRect)collectionCopyRect;
- (NSRect)collectionDeleteRect;
- (NSRect)collectionPreviousRect;
- (NSRect)collectionNextRect;
- (NSRect)collectionUndoRect;
- (NSRect)collectionRedoRect;
- (NSRect)collectionSaveRect;
- (NSRect)collectionSaveAsRect;
- (NSRect)collectionOpenRect;
- (NSRect)collectionNewRect;
- (NSRect)collectionDiscardRect;
- (NSRect)collectionCloseRect;
- (NSRect)collectionFilterRect;
- (NSString *)labelAtIndex:(uint32_t)index;
- (NSString *)draftAtIndex:(uint32_t)index;
- (uint32_t)editorKindAtIndex:(uint32_t)index;
- (void)focusTextFieldAtIndex:(uint32_t)index selection:(NSRange)selection enqueueFocus:(BOOL)enqueueFocus;
- (void)toggleBooleanAtIndex:(uint32_t)index;
- (void)accessibilitySetText:(NSString *)text atIndex:(uint32_t)index;
- (void)queue:(uint32_t)kind index:(uint32_t)index text:(NSString *)text selection:(NSRange)selection;
- (void)setCollectionEnabled:(BOOL)enabled visibleRecordCount:(uint32_t)visibleRecordCount;
- (void)setCollectionRowAtIndex:(uint32_t)index title:(NSString *)title selected:(BOOL)selected viewportStart:(uint32_t)viewportStart totalRecordCount:(uint32_t)totalRecordCount;
- (void)setCollectionFilter:(NSString *)filterText;
- (void)focusCollectionFilterEnqueue:(BOOL)enqueue;
- (void)accessibilitySetCollectionFilter:(NSString *)filterText;
- (void)chooseOpenFile;
- (void)chooseSaveAsFile;
- (void)rebuildAccessibilityActions;
@end

@interface CJGuiInternalSharedEditingFormAccessibilityAction : NSAccessibilityElement
@property(nonatomic, weak) CJGuiInternalSharedEditingFormOverlay *overlay;
@property(nonatomic, assign) uint32_t fieldIndex;
@property(nonatomic, assign) uint32_t actionKind;
- (instancetype)initWithOverlay:(CJGuiInternalSharedEditingFormOverlay *)overlay
                      fieldIndex:(uint32_t)fieldIndex actionKind:(uint32_t)actionKind;
@end

// Keep the document consumer's text summary bounded at the Cangjie/native
// boundary. This bridge intentionally exposes only a scalar byte count; the
// caller owns the source and native retains no pointer after returning.
CjguiInternalRendererStatus
cjgui_internal_renderer_composed_prefix_utf8_length(
    const char *utf8, uint64_t inputBytes, uint64_t maxOutputBytes,
    uint64_t maxClusters, uint8_t inputComplete, uint64_t *outPrefixBytes) {
    if (!outPrefixBytes || (!utf8 && inputBytes > 0)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outPrefixBytes = 0;
    if (inputBytes == 0 || maxOutputBytes == 0 || maxClusters == 0) {
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    const uint64_t scanLimit = 2048;
    // The Cangjie wrapper supplies a scalar-safe window. Do not repair or
    // repeatedly shorten arbitrary bytes here: a native internal caller that
    // violates the bound/encoding contract receives an explicit failure.
    if (inputBytes > scanLimit) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    NSString *value = [[NSString alloc] initWithBytes:utf8 length:(NSUInteger)inputBytes
                                             encoding:NSUTF8StringEncoding];
    if (!value) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    BOOL complete = inputComplete != 0;
    uint64_t prefixBytes = 0;
    uint64_t clusterCount = 0;
    for (NSUInteger location = 0; location < value.length && clusterCount < maxClusters;) {
        NSRange range = [value rangeOfComposedCharacterSequenceAtIndex:location];
        if (!complete && NSMaxRange(range) >= value.length) break;
        NSString *cluster = [value substringWithRange:range];
        NSUInteger clusterBytes = [cluster lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        if ((uint64_t)clusterBytes > maxOutputBytes - MIN(prefixBytes, maxOutputBytes)) break;
        prefixBytes += (uint64_t)clusterBytes;
        clusterCount += 1;
        location = NSMaxRange(range);
    }
    *outPrefixBytes = prefixBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static NSRange CjguiComposedSelection(NSString *text, NSUInteger start, NSUInteger end) {
    NSUInteger length = text.length;
    start = MIN(start, length);
    end = MIN(MAX(end, start), length);
    if (start > 0 && start < length) {
        NSRange composed = [text rangeOfComposedCharacterSequenceAtIndex:start];
        if (start != composed.location && start != NSMaxRange(composed)) start = composed.location;
    }
    if (end > 0 && end < length) {
        NSRange composed = [text rangeOfComposedCharacterSequenceAtIndex:end];
        if (end != composed.location && end != NSMaxRange(composed)) end = NSMaxRange(composed);
    }
    return NSMakeRange(start, end - start);
}

@implementation CJGuiInternalSharedEditingFormAccessibilityAction

- (instancetype)initWithOverlay:(CJGuiInternalSharedEditingFormOverlay *)overlay
                      fieldIndex:(uint32_t)fieldIndex actionKind:(uint32_t)actionKind {
    self = [super init];
    if (!self) return nil;
    self.overlay = overlay;
    self.fieldIndex = fieldIndex;
    self.actionKind = actionKind;
    return self;
}

- (id)accessibilityParent { return self.overlay; }
- (id)accessibilityWindow { return self.overlay.window; }
- (id)accessibilityTopLevelUIElement { return self.overlay.window; }
- (BOOL)isAccessibilityElement { return YES; }
- (NSAccessibilityRole)accessibilityRole {
    if (self.actionKind == 0 && [self.overlay editorKindAtIndex:self.fieldIndex] == 3) return NSAccessibilityCheckBoxRole;
    if (self.actionKind == 18) return NSAccessibilityTextFieldRole;
    if (self.actionKind != 0) return NSAccessibilityButtonRole;
    return NSAccessibilityTextFieldRole;
}
- (NSString *)accessibilityLabel {
    if (self.actionKind == 2) return @"应用草稿";
    if (self.actionKind == 3) return @"取消并重载";
    if (self.actionKind == 4) return self.fieldIndex < self.overlay.collectionTitles.count ? self.overlay.collectionTitles[self.fieldIndex] : @"记录";
    if (self.actionKind == 5) return @"新增记录";
    if (self.actionKind == 6) return @"删除记录";
    if (self.actionKind == 7) return @"上一页";
    if (self.actionKind == 8) return @"下一页";
    if (self.actionKind == 9) return @"撤销";
    if (self.actionKind == 10) return @"重做";
    if (self.actionKind == 11) return @"保存";
    if (self.actionKind == 12) return @"复制记录";
    if (self.actionKind == 13) return @"新建规则集";
    if (self.actionKind == 14) return @"打开规则集";
    if (self.actionKind == 15) return @"另存为";
    if (self.actionKind == 16) return @"放弃未保存内容";
    if (self.actionKind == 17) return @"关闭窗口";
    if (self.actionKind == 18) return @"筛选记录";
    return [self.overlay labelAtIndex:self.fieldIndex];
}
- (id)accessibilityValue {
    if (self.actionKind == 0 && [self.overlay editorKindAtIndex:self.fieldIndex] == 3) return @([[self.overlay draftAtIndex:self.fieldIndex] isEqualToString:@"true"]);
    if (self.actionKind == 4) return @(self.overlay.collectionSelectedRow == self.fieldIndex);
    if (self.actionKind == 18) return self.overlay.collectionFilterText;
    if (self.actionKind == 0) return [self.overlay draftAtIndex:self.fieldIndex];
    return nil;
}
- (BOOL)isAccessibilityEnabled { return self.overlay != nil; }
- (BOOL)accessibilityIsAttributeSettable:(NSAccessibilityAttributeName)attribute {
    if (![attribute isEqualToString:NSAccessibilityValueAttribute]) return NO;
    if (self.actionKind == 18) return YES;
    return self.actionKind == 0 && [self.overlay editorKindAtIndex:self.fieldIndex] != 3;
}
- (NSArray<NSAccessibilityActionName> *)accessibilityActionNames {
    if (self.actionKind != 0 || [self.overlay editorKindAtIndex:self.fieldIndex] == 3) {
        return @[ NSAccessibilityPressAction ];
    }
    return @[];
}
- (void)accessibilityPerformAction:(NSAccessibilityActionName)action {
    if ([action isEqualToString:NSAccessibilityPressAction]) [self accessibilityPerformPress];
}
- (NSRect)accessibilityFrame {
    if (!self.overlay) return NSZeroRect;
    // Use an explicit view-to-window-to-screen conversion. This keeps the
    // self-drawn controls operable by macOS accessibility clients; returning
    // only a parent-space rectangle made them discoverable but unclickable.
    NSRect inWindow = [self.overlay convertRect:[self accessibilityFrameInParentSpace] toView:nil];
    return [self.overlay.window convertRectToScreen:inWindow];
}
- (NSPoint)accessibilityPosition { return [self accessibilityFrame].origin; }
- (NSSize)accessibilitySize { return [self accessibilityFrame].size; }
- (NSRect)accessibilityFrameInParentSpace {
    if (!self.overlay) return NSZeroRect;
    return self.actionKind == 2 ? [self.overlay applyRect] :
        self.actionKind == 3 ? [self.overlay cancelRect] :
        self.actionKind == 4 ? [self.overlay collectionRowRectAtIndex:self.fieldIndex] :
        self.actionKind == 5 ? [self.overlay collectionCreateRect] :
        self.actionKind == 6 ? [self.overlay collectionDeleteRect] :
        self.actionKind == 7 ? [self.overlay collectionPreviousRect] :
        self.actionKind == 8 ? [self.overlay collectionNextRect] :
        self.actionKind == 9 ? [self.overlay collectionUndoRect] :
        self.actionKind == 10 ? [self.overlay collectionRedoRect] :
        self.actionKind == 11 ? [self.overlay collectionSaveRect] :
        self.actionKind == 12 ? [self.overlay collectionCopyRect] :
        self.actionKind == 13 ? [self.overlay collectionNewRect] :
        self.actionKind == 14 ? [self.overlay collectionOpenRect] :
        self.actionKind == 15 ? [self.overlay collectionSaveAsRect] :
        self.actionKind == 16 ? [self.overlay collectionDiscardRect] :
        self.actionKind == 17 ? [self.overlay collectionCloseRect] :
        self.actionKind == 18 ? [self.overlay collectionFilterRect] :
        [self.overlay fieldRectAtIndex:self.fieldIndex];
}
- (BOOL)accessibilityPerformPress {
    if (!self.overlay) return NO;
    if (self.actionKind == 2) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_APPLY index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 3) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_CANCEL index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 4) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT index:self.fieldIndex text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 5) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 6) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_DELETE index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 7) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_PREVIOUS_PAGE index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 8) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEXT_PAGE index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 9) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 10) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_REDO index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 11) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SAVE index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 12) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_COPY index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 13) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEW index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 14) {
        [self.overlay chooseOpenFile];
    } else if (self.actionKind == 15) {
        [self.overlay chooseSaveAsFile];
    } else if (self.actionKind == 16) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_DISCARD index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 17) {
        [self.overlay queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE index:0 text:@"" selection:NSMakeRange(0, 0)];
    } else if (self.actionKind == 18) {
        [self.overlay focusCollectionFilterEnqueue:YES];
    } else if ([self.overlay editorKindAtIndex:self.fieldIndex] == 3) {
        [self.overlay toggleBooleanAtIndex:self.fieldIndex];
    } else {
        [self.overlay focusTextFieldAtIndex:self.fieldIndex selection:NSMakeRange(0, 0) enqueueFocus:YES];
    }
    return YES;
}
- (void)accessibilitySetValue:(id)value {
    if (self.actionKind == 18 && [value isKindOfClass:[NSString class]]) {
        [self.overlay accessibilitySetCollectionFilter:value];
        return;
    }
    if (self.actionKind == 0 && [value isKindOfClass:[NSString class]]) {
        [self.overlay accessibilitySetText:value atIndex:self.fieldIndex];
    } else if (self.actionKind == 0 && [self.overlay editorKindAtIndex:self.fieldIndex] == 3 && [value respondsToSelector:@selector(boolValue)]) {
        BOOL desired = [value boolValue];
        BOOL current = [[self.overlay draftAtIndex:self.fieldIndex] isEqualToString:@"true"];
        if (desired != current) [self.overlay toggleBooleanAtIndex:self.fieldIndex];
    }
}

@end

@implementation CJGuiInternalSharedEditingFormOverlay

- (instancetype)initWithFrame:(NSRect)frame session:(CJGuiInternalSession *)session {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.session = session;
    self.fieldLabels = [NSMutableArray array];
    self.draftTexts = [NSMutableArray array];
    self.validationErrors = [NSMutableArray array];
    self.editorKinds = [NSMutableArray array];
    self.accessibilityActions = [NSMutableArray array];
    self.statusText = @"";
    self.inputNotice = @"";
    self.collectionEnabled = NO;
    self.collectionTitles = [NSMutableArray array];
    self.collectionSelectedRow = UINT32_MAX;
    self.collectionViewportStart = 0;
    self.collectionTotalCount = 0;
    self.collectionFilterText = @"";
    self.activeTextFieldIndex = NSNotFound;
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
    self.inputProxy = [[NSTextView alloc] initWithFrame:NSMakeRect(-2.0, -2.0, 1.0, 1.0)];
    self.inputProxy.delegate = self;
    self.inputProxy.drawsBackground = NO;
    self.inputProxy.alphaValue = 0.01;
    self.inputProxy.editable = YES;
    self.inputProxy.selectable = YES;
    self.inputProxy.richText = NO;
    self.inputProxy.usesRuler = NO;
    [self addSubview:self.inputProxy];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputProxySelectionDidChange:)
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:self.inputProxy];
    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)isAccessibilityElement { return NO; }
- (NSAccessibilityRole)accessibilityRole { return NSAccessibilityGroupRole; }
- (NSString *)accessibilityLabel { return @"CJGUI shared editing form"; }
- (NSArray<id> *)accessibilityChildren { return [self.accessibilityActions copy]; }

- (void)setFieldCountForProjection:(uint32_t)fieldCount {
    self.fieldCount = fieldCount;
    while (self.fieldLabels.count < fieldCount) {
        uint32_t index = (uint32_t)self.fieldLabels.count;
        [self.fieldLabels addObject:@"字段"];
        [self.draftTexts addObject:@""];
        [self.validationErrors addObject:@""];
        [self.editorKinds addObject:@1];
        [self.accessibilityActions addObject:[[CJGuiInternalSharedEditingFormAccessibilityAction alloc] initWithOverlay:self fieldIndex:index actionKind:0]];
    }
    while (self.fieldLabels.count > fieldCount) {
        [self.fieldLabels removeLastObject]; [self.draftTexts removeLastObject];
        [self.validationErrors removeLastObject]; [self.editorKinds removeLastObject];
        [self.accessibilityActions removeLastObject];
    }
    [self rebuildAccessibilityActions];
    [self setNeedsDisplay:YES];
}

- (void)rebuildAccessibilityActions {
    [self.accessibilityActions removeAllObjects];
    for (uint32_t index = 0; index < self.fieldCount; index++) {
        [self.accessibilityActions addObject:[[CJGuiInternalSharedEditingFormAccessibilityAction alloc] initWithOverlay:self fieldIndex:index actionKind:0]];
    }
    [self.accessibilityActions addObject:[[CJGuiInternalSharedEditingFormAccessibilityAction alloc] initWithOverlay:self fieldIndex:0 actionKind:2]];
    [self.accessibilityActions addObject:[[CJGuiInternalSharedEditingFormAccessibilityAction alloc] initWithOverlay:self fieldIndex:0 actionKind:3]];
    if (self.collectionEnabled) {
        for (uint32_t index = 0; index < self.collectionRowCount; index++) {
            [self.accessibilityActions addObject:[[CJGuiInternalSharedEditingFormAccessibilityAction alloc] initWithOverlay:self fieldIndex:index actionKind:4]];
        }
        for (uint32_t kind = 5; kind <= 18; kind++) {
            [self.accessibilityActions addObject:[[CJGuiInternalSharedEditingFormAccessibilityAction alloc] initWithOverlay:self fieldIndex:0 actionKind:kind]];
        }
    }
}

- (void)setCollectionEnabled:(BOOL)enabled visibleRecordCount:(uint32_t)visibleRecordCount {
    self.collectionEnabled = enabled;
    self.collectionRowCount = enabled ? visibleRecordCount : 0;
    while (self.collectionTitles.count < self.collectionRowCount) [self.collectionTitles addObject:@"未命名记录"];
    while (self.collectionTitles.count > self.collectionRowCount) [self.collectionTitles removeLastObject];
    self.collectionSelectedRow = UINT32_MAX;
    self.collectionViewportStart = 0;
    self.collectionTotalCount = 0;
    [self rebuildAccessibilityActions];
    [self setNeedsDisplay:YES];
}

- (void)setCollectionRowAtIndex:(uint32_t)index title:(NSString *)title selected:(BOOL)selected viewportStart:(uint32_t)viewportStart totalRecordCount:(uint32_t)totalRecordCount {
    if (!self.collectionEnabled || index >= self.collectionRowCount) return;
    if (index == 0) self.collectionSelectedRow = UINT32_MAX;
    self.collectionTitles[index] = title ?: @"未命名记录";
    self.collectionViewportStart = viewportStart;
    self.collectionTotalCount = totalRecordCount;
    if (selected) self.collectionSelectedRow = index;
    [self setNeedsDisplay:YES];
}

- (void)setCollectionFilter:(NSString *)filterText {
    NSString *next = filterText ?: @"";
    if ([self.collectionFilterText isEqualToString:next]) return;
    self.collectionFilterText = next;
    if (self.activeTextFieldIndex == -2) {
        BOOL wasApplying = self.applyingProjection;
        self.applyingProjection = YES;
        self.inputProxy.string = next;
        self.inputProxy.selectedRange = CjguiComposedSelection(next, next.length, next.length);
        self.applyingProjection = wasApplying;
    }
    [self setNeedsDisplay:YES];
}

- (NSRect)fieldRectAtIndex:(uint32_t)index {
    CGFloat origin = self.collectionEnabled ? 430.0 : 180.0;
    CGFloat width = MAX(80.0, self.bounds.size.width - origin - 22.0);
    return NSMakeRect(origin, 61.0 + (CGFloat)index * 76.0, width, 28.0);
}
- (CGFloat)bottom { return 64.0 + (CGFloat)self.fieldCount * 76.0; }
- (NSRect)applyRect { return NSMakeRect(self.collectionEnabled ? 270.0 : 22.0, [self bottom] + 32.0, 110.0, 30.0); }
- (NSRect)cancelRect { return NSMakeRect(self.collectionEnabled ? 390.0 : 142.0, [self bottom] + 32.0, 120.0, 30.0); }
- (NSRect)collectionRowRectAtIndex:(uint32_t)index { return NSMakeRect(14.0, 120.0 + (CGFloat)index * 36.0, 236.0, 30.0); }
- (NSRect)collectionFilterRect { return NSMakeRect(14.0, 48.0, 236.0, 26.0); }
- (NSRect)collectionCreateRect { return NSMakeRect(14.0, 82.0, 72.0, 26.0); }
- (NSRect)collectionCopyRect { return NSMakeRect(94.0, 82.0, 72.0, 26.0); }
- (NSRect)collectionDeleteRect { return NSMakeRect(174.0, 82.0, 72.0, 26.0); }
- (NSRect)collectionPreviousRect { return NSMakeRect(14.0, MAX(390.0, self.bounds.size.height - 128.0), 52.0, 26.0); }
- (NSRect)collectionNextRect { return NSMakeRect(74.0, MAX(390.0, self.bounds.size.height - 128.0), 52.0, 26.0); }
- (NSRect)collectionUndoRect { return NSMakeRect(134.0, MAX(390.0, self.bounds.size.height - 128.0), 52.0, 26.0); }
- (NSRect)collectionRedoRect { return NSMakeRect(194.0, MAX(390.0, self.bounds.size.height - 128.0), 52.0, 26.0); }
- (NSRect)collectionSaveRect { return NSMakeRect(14.0, MAX(424.0, self.bounds.size.height - 94.0), 66.0, 26.0); }
- (NSRect)collectionSaveAsRect { return NSMakeRect(88.0, MAX(424.0, self.bounds.size.height - 94.0), 66.0, 26.0); }
- (NSRect)collectionOpenRect { return NSMakeRect(162.0, MAX(424.0, self.bounds.size.height - 94.0), 66.0, 26.0); }
- (NSRect)collectionNewRect { return NSMakeRect(14.0, MAX(458.0, self.bounds.size.height - 60.0), 66.0, 26.0); }
- (NSRect)collectionDiscardRect { return NSMakeRect(88.0, MAX(458.0, self.bounds.size.height - 60.0), 66.0, 26.0); }
- (NSRect)collectionCloseRect { return NSMakeRect(162.0, MAX(458.0, self.bounds.size.height - 60.0), 66.0, 26.0); }
- (NSString *)labelAtIndex:(uint32_t)index { return index < self.fieldLabels.count ? self.fieldLabels[index] : @"字段"; }
- (NSString *)draftAtIndex:(uint32_t)index { return index < self.draftTexts.count ? self.draftTexts[index] : @""; }
- (uint32_t)editorKindAtIndex:(uint32_t)index { return index < self.editorKinds.count ? self.editorKinds[index].unsignedIntValue : 1; }

- (void)setFieldAtIndex:(uint32_t)index label:(NSString *)label draftText:(NSString *)draftText
                   error:(NSString *)error editorKind:(uint32_t)editorKind focused:(BOOL)focused
          selectionStart:(uint32_t)selectionStart selectionEnd:(uint32_t)selectionEnd {
    if (index >= self.fieldCount) return;
    self.applyingProjection = YES;
    self.fieldLabels[index] = label ?: @"字段";
    self.draftTexts[index] = draftText ?: @"";
    self.validationErrors[index] = error ?: @"";
    self.editorKinds[index] = @(editorKind);
    if (focused && editorKind != 3) {
        [self focusTextFieldAtIndex:index
                           selection:CjguiComposedSelection(self.draftTexts[index], selectionStart, selectionEnd)
                        enqueueFocus:NO];
    } else if (self.activeTextFieldIndex == (NSInteger)index && editorKind == 3) {
        self.activeTextFieldIndex = NSNotFound;
    }
    self.applyingProjection = NO;
    [self setNeedsDisplay:YES];
}

- (void)setStatus:(NSString *)status { self.statusText = status ?: @""; [self setNeedsDisplay:YES]; }

- (void)chooseOpenFile {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.prompt = @"打开规则集";
    panel.allowedFileTypes = @[ @"cjgui-rules" ];
    if ([panel runModal] == NSModalResponseOK && panel.URL.path.length > 0) {
        [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_OPEN index:0 text:panel.URL.path selection:NSMakeRange(0, 0)];
    }
}

- (void)chooseSaveAsFile {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.prompt = @"另存为";
    panel.nameFieldStringValue = @"规则集.cjgui-rules";
    panel.allowedFileTypes = @[ @"cjgui-rules" ];
    if ([panel runModal] == NSModalResponseOK && panel.URL.path.length > 0) {
        [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SAVE_AS index:0 text:panel.URL.path selection:NSMakeRange(0, 0)];
    }
}

- (void)queue:(uint32_t)kind index:(uint32_t)index text:(NSString *)text selection:(NSRange)selection {
    if (!self.session || self.applyingProjection) return;
    if (!CjguiEnqueueInteraction(self.session, kind, index, text,
                                 (uint32_t)MIN(selection.location, UINT32_MAX),
                                 (uint32_t)MIN(NSMaxRange(selection), UINT32_MAX))) {
        self.inputNotice = @"输入队列已满；未接收的输入请重试";
        [self setNeedsDisplay:YES];
    }
}

- (void)focusTextFieldAtIndex:(uint32_t)index selection:(NSRange)selection enqueueFocus:(BOOL)enqueueFocus {
    if (index >= self.fieldCount || [self editorKindAtIndex:index] == 3) return;
    self.activeTextFieldIndex = index;
    NSString *draft = [self draftAtIndex:index];
    NSRange clamped = CjguiComposedSelection(draft, selection.location, NSMaxRange(selection));
    BOOL wasApplying = self.applyingProjection;
    self.applyingProjection = YES;
    if (![self.inputProxy.string isEqualToString:draft]) self.inputProxy.string = draft;
    [self.window makeFirstResponder:self.inputProxy];
    self.inputProxy.selectedRange = clamped;
    self.applyingProjection = wasApplying;
    if (enqueueFocus) [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_FOCUS index:index text:draft selection:clamped];
    [self setNeedsDisplay:YES];
}

- (void)focusCollectionFilterEnqueue:(BOOL)enqueue {
    if (!self.collectionEnabled) return;
    self.activeTextFieldIndex = -2;
    BOOL wasApplying = self.applyingProjection;
    self.applyingProjection = YES;
    self.inputProxy.string = self.collectionFilterText ?: @"";
    self.inputProxy.selectedRange = CjguiComposedSelection(self.inputProxy.string, self.inputProxy.string.length, self.inputProxy.string.length);
    [self.window makeFirstResponder:self.inputProxy];
    self.applyingProjection = wasApplying;
    if (enqueue) [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_FILTER_CHANGED index:0 text:self.inputProxy.string selection:self.inputProxy.selectedRange];
    [self setNeedsDisplay:YES];
}

- (void)toggleBooleanAtIndex:(uint32_t)index {
    if (index >= self.fieldCount || [self editorKindAtIndex:index] != 3) return;
    NSString *next = [[self draftAtIndex:index] isEqualToString:@"true"] ? @"false" : @"true";
    [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_BOOLEAN_CHANGED index:index text:next selection:NSMakeRange(0, 0)];
}

- (void)accessibilitySetText:(NSString *)text atIndex:(uint32_t)index {
    if (index >= self.fieldCount || [self editorKindAtIndex:index] == 3) return;
    [self focusTextFieldAtIndex:index selection:NSMakeRange(text.length, 0) enqueueFocus:YES];
    self.applyingProjection = YES;
    self.inputProxy.string = text ?: @"";
    self.inputProxy.selectedRange = CjguiComposedSelection(self.inputProxy.string, self.inputProxy.string.length, self.inputProxy.string.length);
    self.applyingProjection = NO;
    [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED index:index text:self.inputProxy.string selection:self.inputProxy.selectedRange];
}

- (void)accessibilitySetCollectionFilter:(NSString *)filterText {
    [self focusCollectionFilterEnqueue:NO];
    self.applyingProjection = YES;
    self.inputProxy.string = filterText ?: @"";
    self.inputProxy.selectedRange = CjguiComposedSelection(self.inputProxy.string, self.inputProxy.string.length, self.inputProxy.string.length);
    self.applyingProjection = NO;
    [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_FILTER_CHANGED index:0 text:self.inputProxy.string selection:self.inputProxy.selectedRange];
}

- (void)textDidChange:(NSNotification *)notification {
    (void)notification;
    if (self.applyingProjection || self.activeTextFieldIndex == NSNotFound || self.inputProxy.hasMarkedText) return;
    NSRange selection = CjguiComposedSelection(self.inputProxy.string, self.inputProxy.selectedRange.location, NSMaxRange(self.inputProxy.selectedRange));
    if (self.activeTextFieldIndex == -2) {
        [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_FILTER_CHANGED index:0 text:self.inputProxy.string selection:selection];
        return;
    }
    [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED index:(uint32_t)self.activeTextFieldIndex text:self.inputProxy.string selection:selection];
}

- (void)inputProxySelectionDidChange:(NSNotification *)notification {
    (void)notification;
    if (self.applyingProjection || self.activeTextFieldIndex == NSNotFound || self.inputProxy.hasMarkedText) return;
    NSRange selection = CjguiComposedSelection(self.inputProxy.string, self.inputProxy.selectedRange.location, NSMaxRange(self.inputProxy.selectedRange));
    if (self.activeTextFieldIndex == -2) {
        [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_FILTER_CHANGED index:0 text:self.inputProxy.string selection:selection];
        return;
    }
    [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED index:(uint32_t)self.activeTextFieldIndex text:self.inputProxy.string selection:selection];
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (self.collectionEnabled) {
        if (NSPointInRect(point, [self collectionFilterRect])) { [self focusCollectionFilterEnqueue:YES]; return; }
        if (NSPointInRect(point, [self collectionCreateRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CREATE index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionCopyRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_COPY index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionDeleteRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_DELETE index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionPreviousRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_PREVIOUS_PAGE index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionNextRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEXT_PAGE index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionUndoRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_UNDO index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionRedoRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_REDO index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionSaveRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SAVE index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionSaveAsRect])) { [self chooseSaveAsFile]; return; }
        if (NSPointInRect(point, [self collectionOpenRect])) { [self chooseOpenFile]; return; }
        if (NSPointInRect(point, [self collectionNewRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEW index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionDiscardRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_DISCARD index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        if (NSPointInRect(point, [self collectionCloseRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_CLOSE index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
        for (uint32_t index = 0; index < self.collectionRowCount; index++) {
            if (NSPointInRect(point, [self collectionRowRectAtIndex:index])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_SELECT index:index text:@"" selection:NSMakeRange(0, 0)]; return; }
        }
    }
    if (NSPointInRect(point, [self applyRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_APPLY index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
    if (NSPointInRect(point, [self cancelRect])) { [self queue:CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_CANCEL index:0 text:@"" selection:NSMakeRange(0, 0)]; return; }
    for (uint32_t index = 0; index < self.fieldCount; index++) {
        if (!NSPointInRect(point, [self fieldRectAtIndex:index])) continue;
        if ([self editorKindAtIndex:index] == 3) [self toggleBooleanAtIndex:index];
        else [self focusTextFieldAtIndex:index selection:NSMakeRange(0, 0) enqueueFocus:YES];
        return;
    }
}

- (void)scrollWheel:(NSEvent *)event {
    if (!self.collectionEnabled || event.scrollingDeltaY == 0.0) { [super scrollWheel:event]; return; }
    uint32_t kind = event.scrollingDeltaY < 0.0 ? CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_NEXT_PAGE : CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COLLECTION_PREVIOUS_PAGE;
    [self queue:kind index:0 text:@"" selection:NSMakeRange(0, 0)];
}

- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [[NSColor colorWithCalibratedWhite:0.97 alpha:0.96] setFill];
    NSRectFill(self.bounds);
    NSDictionary *heading = @{ NSFontAttributeName: [NSFont boldSystemFontOfSize:19.0], NSForegroundColorAttributeName: NSColor.labelColor };
    CGFloat detailOrigin = self.collectionEnabled ? 270.0 : 22.0;
    [self.collectionEnabled ? @"CJGUI collection editor" : @"CJGUI shared editing form" drawAtPoint:NSMakePoint(detailOrigin, 18.0) withAttributes:heading];
    [@"编辑草稿后应用；输入、选区和校验状态由仓颉领域统一拥有。" drawAtPoint:NSMakePoint(detailOrigin, 43.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:12.0], NSForegroundColorAttributeName: NSColor.secondaryLabelColor }];
    if (self.collectionEnabled) {
        NSDictionary *small = @{ NSFontAttributeName: [NSFont systemFontOfSize:12.0], NSForegroundColorAttributeName: NSColor.secondaryLabelColor };
        [@"记录" drawAtPoint:NSMakePoint(14.0, 18.0) withAttributes:heading];
        NSString *count = [NSString stringWithFormat:@"共 %u 条 · 第 %u 页", self.collectionTotalCount, self.collectionViewportStart / MAX(1u, self.collectionRowCount) + 1];
        [count drawAtPoint:NSMakePoint(14.0, 32.0) withAttributes:small];
        NSRect filterRect = [self collectionFilterRect];
        [[NSColor textBackgroundColor] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:filterRect xRadius:5.0 yRadius:5.0] fill];
        [NSColor.separatorColor setStroke];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(filterRect, 0.5, 0.5) xRadius:5.0 yRadius:5.0] stroke];
        NSString *filterLabel = self.collectionFilterText.length > 0
            ? [NSString stringWithFormat:@"筛选：%@", self.collectionFilterText] : @"筛选记录";
        [filterLabel drawInRect:NSInsetRect(filterRect, 7.0, 6.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:12.0], NSForegroundColorAttributeName: self.collectionFilterText.length > 0 ? NSColor.labelColor : NSColor.placeholderTextColor }];
        for (NSArray *button in @[ @[@"新增", [NSValue valueWithRect:[self collectionCreateRect]]], @[@"复制", [NSValue valueWithRect:[self collectionCopyRect]]], @[@"删除", [NSValue valueWithRect:[self collectionDeleteRect]]], @[@"上一页", [NSValue valueWithRect:[self collectionPreviousRect]]], @[@"下一页", [NSValue valueWithRect:[self collectionNextRect]]], @[@"撤销", [NSValue valueWithRect:[self collectionUndoRect]]], @[@"重做", [NSValue valueWithRect:[self collectionRedoRect]]], @[@"保存", [NSValue valueWithRect:[self collectionSaveRect]]], @[@"另存为", [NSValue valueWithRect:[self collectionSaveAsRect]]], @[@"打开", [NSValue valueWithRect:[self collectionOpenRect]]], @[@"新建", [NSValue valueWithRect:[self collectionNewRect]]], @[@"放弃", [NSValue valueWithRect:[self collectionDiscardRect]]], @[@"关闭", [NSValue valueWithRect:[self collectionCloseRect]]] ]) {
            NSRect rect = [button[1] rectValue];
            [[NSColor controlBackgroundColor] setFill];
            [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0] fill];
            [NSColor.separatorColor setStroke];
            [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:5.0 yRadius:5.0] stroke];
            [button[0] drawInRect:NSInsetRect(rect, 6.0, 6.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:12.0 weight:NSFontWeightMedium], NSForegroundColorAttributeName: NSColor.labelColor }];
        }
        for (uint32_t index = 0; index < self.collectionRowCount; index++) {
            NSRect row = [self collectionRowRectAtIndex:index];
            BOOL selected = self.collectionSelectedRow == index;
            [(selected ? NSColor.selectedContentBackgroundColor : NSColor.controlBackgroundColor) setFill];
            [[NSBezierPath bezierPathWithRoundedRect:row xRadius:5.0 yRadius:5.0] fill];
            [self.collectionTitles[index] drawInRect:NSInsetRect(row, 8.0, 7.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:13.0], NSForegroundColorAttributeName: selected ? NSColor.alternateSelectedControlTextColor : NSColor.labelColor }];
        }
        [NSColor.separatorColor setStroke];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(260.0, 14.0) toPoint:NSMakePoint(260.0, self.bounds.size.height - 14.0)];
    }
    for (uint32_t index = 0; index < self.fieldCount; index++) {
        CGFloat top = 64.0 + (CGFloat)index * 76.0;
        NSString *label = [self labelAtIndex:index];
        [label drawInRect:NSMakeRect(detailOrigin, top, self.collectionEnabled ? 145.0 : 150.0, 20.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:14.0 weight:NSFontWeightMedium], NSForegroundColorAttributeName: NSColor.labelColor }];
        NSRect rect = [self fieldRectAtIndex:index];
        BOOL focused = self.activeTextFieldIndex == (NSInteger)index;
        [[NSColor controlBackgroundColor] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0] fill];
        [(focused ? NSColor.keyboardFocusIndicatorColor : NSColor.separatorColor) setStroke];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:5.0 yRadius:5.0] stroke];
        if ([self editorKindAtIndex:index] == 3) {
            BOOL enabled = [[self draftAtIndex:index] isEqualToString:@"true"];
            NSString *check = enabled ? @"☑" : @"☐";
            [check drawAtPoint:NSMakePoint(rect.origin.x + 8.0, rect.origin.y + 5.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:16.0], NSForegroundColorAttributeName: NSColor.labelColor }];
            [label drawAtPoint:NSMakePoint(rect.origin.x + 31.0, rect.origin.y + 7.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:13.0], NSForegroundColorAttributeName: NSColor.labelColor }];
        } else {
            [[self draftAtIndex:index] drawInRect:NSInsetRect(rect, 8.0, 5.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:14.0], NSForegroundColorAttributeName: NSColor.labelColor }];
        }
        NSString *error = self.validationErrors[index];
        if (error.length > 0) [error drawAtPoint:NSMakePoint(rect.origin.x, top + 27.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:11.0], NSForegroundColorAttributeName: NSColor.systemRedColor }];
    }
    NSString *status = self.inputNotice.length > 0 ? self.inputNotice : self.statusText;
    [status drawInRect:NSMakeRect(22.0, [self bottom] + 5.0, MAX(0.0, self.bounds.size.width - 44.0), 18.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:12.0], NSForegroundColorAttributeName: self.inputNotice.length > 0 ? NSColor.systemRedColor : NSColor.secondaryLabelColor }];
    for (NSArray *button in @[ @[@"应用草稿", [NSValue valueWithRect:[self applyRect]]], @[@"取消并重载", [NSValue valueWithRect:[self cancelRect]]] ]) {
        NSRect rect = [button[1] rectValue];
        [[NSColor controlAccentColor] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:6.0 yRadius:6.0] fill];
        [button[0] drawInRect:NSInsetRect(rect, 10.0, 7.0) withAttributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:13.0 weight:NSFontWeightMedium], NSForegroundColorAttributeName: NSColor.alternateSelectedControlTextColor }];
    }
}

@end

// ---- session table ----

static CJGuiInternalSession *gCjguiSessions[4];
static BOOL gCjguiSessionOccupied[4];
static uint64_t gCjguiNextSessionGeneration = 1;
static char CJGuiSessionWindowAssociationKey;
static BOOL gCjguiMainThreadDispatchEnabled;

static BOOL CjguiIsMainThread(void) {
    return [NSThread isMainThread];
}

void cjgui_internal_renderer_enable_main_thread_dispatch(void) {
    if (CjguiIsMainThread()) {
        gCjguiMainThreadDispatchEnabled = YES;
    }
}

void cjgui_internal_renderer_request_application_stop(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp stop:nil];
        [NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                            location:NSZeroPoint
                                       modifierFlags:0
                                           timestamp:0
                                        windowNumber:0
                                             context:nil
                                             subtype:0
                                               data1:0
                                               data2:0]
                atStart:NO];
    });
}

static CjguiInternalRendererStatus CjguiEnsureApp(NSApplication **outApp) {
    NSApplication *app = [NSApplication sharedApplication];
    if (!app) {
        return CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED;
    }
    if (app.activationPolicy == NSApplicationActivationPolicyProhibited) {
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    }
    *outApp = app;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static uint64_t CjguiAllocateSession(CJGuiInternalSession *session) {
    for (NSUInteger i = 0; i < kCjguiSessionCapacity; i++) {
        if (!gCjguiSessionOccupied[i]) {
            session.sessionGeneration = gCjguiNextSessionGeneration;
            gCjguiNextSessionGeneration += 1;
            if (gCjguiNextSessionGeneration == 0) gCjguiNextSessionGeneration = 1;
            gCjguiSessionOccupied[i] = YES;
            gCjguiSessions[i] = session;
            // Token = (slot index + 1) so 0 stays the invalid sentinel.
            return (uint64_t)(i + 1);
        }
    }
    return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
}

static CJGuiInternalSession *CjguiLookupSession(uint64_t token) {
    if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION || token > kCjguiSessionCapacity) {
        return nil;
    }
    NSUInteger idx = (NSUInteger)(token - 1);
    if (!gCjguiSessionOccupied[idx]) {
        return nil;
    }
    return gCjguiSessions[idx];
}

static void CjguiReleaseSession(uint64_t token) {
    if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION || token > kCjguiSessionCapacity) {
        return;
    }
    NSUInteger idx = (NSUInteger)(token - 1);
    gCjguiSessionOccupied[idx] = NO;
    gCjguiSessions[idx] = nil;
}

// ---- ABI: create ----

uint64_t cjgui_internal_renderer_create(const CjguiInternalRendererConfig *config,
                                        CjguiInternalRendererStatus *outStatus) {
    if (outStatus) {
        *outStatus = CJGUI_INTERNAL_RENDERER_OK;
    }

    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }
        __block uint64_t token = CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            token = cjgui_internal_renderer_create(config, &status);
        });
        if (outStatus) *outStatus = status;
        return token;
    }

    @autoreleasepool {
        NSLog(@"cjgui: bridge init");

        NSApplication *app = nil;
        CjguiInternalRendererStatus appStatus = CjguiEnsureApp(&app);
        if (appStatus != CJGUI_INTERNAL_RENDERER_OK) {
            if (outStatus) *outStatus = appStatus;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }

        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }
        NSLog(@"cjgui: capability check: metal device ok");

        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (!commandQueue) {
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_METAL_COMMAND_QUEUE_UNAVAILABLE;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }
        NSLog(@"cjgui: capability check: command queue ok");

        uint32_t width = config ? config->windowWidth : 0;
        uint32_t height = config ? config->windowHeight : 0;
        if (width == 0) width = 720;
        if (height == 0) height = 420;

        NSRect frame = NSMakeRect(0, 0, (CGFloat)width, (CGFloat)height);
        NSUInteger style = NSWindowStyleMaskTitled |
                           NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable;

        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:style
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        if (!window) {
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }
        [window setReleasedWhenClosed:NO];
        [window center];
        [window setTitle:@"CJGUI Shared Operation"];
        NSLog(@"cjgui: window created");

        CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
            initWithFrame:frame device:device commandQueue:commandQueue];
        if (!view) {
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_METAL_LAYER_UNAVAILABLE;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }

        [window setContentView:view];
        NSLog(@"cjgui: metal setup complete");

        [window makeKeyAndOrderFront:nil];
        [app activateIgnoringOtherApps:YES];

        CJGuiInternalSession *session = [[CJGuiInternalSession alloc] init];
        session.app = app;
        session.window = window;
        session.view = view;
        session.device = device;
        session.commandQueue = commandQueue;
        [window setDelegate:session];
        // A screen move may leave point bounds unchanged while the backing
        // scale changes. That transition needs the same Cangjie scene/derived
        // resource transaction as an ordinary resize; render-time drawable
        // updates alone would retain text rasterized at the former scale.
        [[NSNotificationCenter defaultCenter] addObserver:session
                                                 selector:@selector(windowDidChangeBackingProperties:)
                                                     name:NSWindowDidChangeBackingPropertiesNotification
                                                   object:window];
        objc_setAssociatedObject(window, &CJGuiSessionWindowAssociationKey,
                                 session, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        uint64_t token = CjguiAllocateSession(session);
        if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
            // Table full: tear down the freshly created resources.
            [view invalidateBridgeResources];
            [window setDelegate:nil];
            [window close];
            objc_setAssociatedObject(window, &CJGuiSessionWindowAssociationKey, nil,
                                     OBJC_ASSOCIATION_ASSIGN);
            if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL;
            return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        }

        return token;
    }
}

// ---- ABI: window title ----

static CjguiInternalRendererStatus
CjguiSetWindowTitleOnMain(uint64_t session, const char *title) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.window || !title || title[0] == '\0') {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSString *value = [NSString stringWithUTF8String:title];
    if (!value || value.length == 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    [ctx.window setTitle:value];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_window_title(uint64_t session, const char *title) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = CjguiSetWindowTitleOnMain(session, title);
        });
        return status;
    }
    return CjguiSetWindowTitleOnMain(session, title);
}

// ---- ABI: presentClear ----

CjguiInternalRendererStatus
cjgui_internal_renderer_present_clear(uint64_t session,
                                      const CjguiInternalRendererClearColor *color,
                                      CjguiInternalRendererFrameObservation *outObservation) {
    if (outObservation) {
        memset(outObservation, 0, sizeof(CjguiInternalRendererFrameObservation));
    }
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_present_clear(session, color, outObservation);
        });
        return status;
    }

    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }

    CJGuiInternalMetalView *view = ctx.view;
    if (!view || view.invalidated || !view.metalLayer || !view.commandQueue) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }

    double red = color ? color->red : 0.0;
    double green = color ? color->green : 0.0;
    double blue = color ? color->blue : 0.0;
    double alpha = color ? color->alpha : 1.0;
    MTLClearColor clearColor = MTLClearColorMake(red, green, blue, alpha);

    @autoreleasepool {
        [view updateDrawableSize];

        id<CAMetalDrawable> drawable = [view.metalLayer nextDrawable];
        if (!drawable) {
            return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
        }
        CGSize drawableSize = drawable.texture ? CGSizeMake(drawable.texture.width, drawable.texture.height) : CGSizeZero;

        id<MTLCommandBuffer> commandBuffer = [view.commandQueue commandBuffer];
        if (!commandBuffer) {
            return CJGUI_INTERNAL_RENDERER_METAL_COMMAND_BUFFER_UNAVAILABLE;
        }

        MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
        pass.colorAttachments[0].texture = drawable.texture;
        pass.colorAttachments[0].loadAction = MTLLoadActionClear;
        pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        pass.colorAttachments[0].clearColor = clearColor;

        // Probe only a final, visible opaque colour. The scene can contain a
        // clipped row, alpha overlay or image whose centre does not identify
        // one deterministic output pixel; claiming otherwise produced the
        // resize-time scene_color_mismatch reported by the normal rule app.
        CjguiComposableReadbackProbePoint sceneProbePoint = {0};
        CJGuiInternalComposableSceneNode *sceneProbeNode =
            CjguiComposableSafeOpaqueProbeNode(view.composableNodes, view.bounds.size, drawableSize, &sceneProbePoint);
        BOOL sceneHasPotentialMetalDraw = CjguiComposableSceneHasPotentialMetalDraw(view.composableNodes);
        MTLClearColor expectedReadbackColor = clearColor;
        if (sceneProbeNode) {
            CjguiInternalRendererComposableNode sceneValue = sceneProbeNode.node;
            expectedReadbackColor = MTLClearColorMake(sceneValue.fillRed, sceneValue.fillGreen, sceneValue.fillBlue, sceneValue.fillAlpha);
        }
        // A clear-only scene has a known central pixel. A scene that draws but
        // exposes no deterministic opaque point is rendered normally and
        // reported as a skipped diagnostic, not as either a false success or
        // a false rendering failure.
        BOOL readbackSkippedNoDeterministicScenePixel = !view.readbackProbeCompleted && !sceneProbeNode && sceneHasPotentialMetalDraw;
        // Retain the one-shot completion observation even when colour is not
        // derivable. It preserves the first-frame lifecycle fact without
        // manufacturing a pixel match or adding a repeating GPU wait.
        BOOL shouldProbe = !view.readbackProbeCompleted;
        const NSUInteger readbackBytesPerRow = 256;
        id<MTLBuffer> readbackBuffer = nil;
        BOOL readbackBlitEncoded = NO;
        BOOL readbackCompleted = NO;
        BOOL readbackMatched = NO;
        BOOL readbackFailed = NO;
        const char *readbackDegradedReason = "none";
        BOOL readbackHasDegraded = NO;
        BOOL commandBufferWaited = NO;
        NSUInteger readbackSampleX = 0;
        NSUInteger readbackSampleY = 0;
#ifdef CJGUI_INTERNAL_TESTING
        BOOL testDrawablePixelRequested = ctx.testDrawablePixelPending;
        id<MTLBuffer> testDrawablePixelBuffer = nil;
        BOOL testDrawablePixelBlitEncoded = NO;
#endif

        if (shouldProbe) {
            readbackBuffer = [ctx.device newBufferWithLength:readbackBytesPerRow
                                                     options:MTLResourceStorageModeShared];
            if (!readbackBuffer) {
                readbackDegradedReason = "buffer_unavailable";
                readbackHasDegraded = YES;
                readbackFailed = YES;
            }
        }

        id<MTLRenderCommandEncoder> encoder =
            [commandBuffer renderCommandEncoderWithDescriptor:pass];
        if (!encoder) {
            return CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE;
        }
#ifdef CJGUI_INTERNAL_TESTING
        uint64_t composableEncodeStarted = CjguiMonotonicMicros();
#endif
        BOOL composableEncoded = [view encodeComposableNodes:encoder
            drawableSize:drawableSize];
#ifdef CJGUI_INTERNAL_TESTING
        view.testComposableEncoderCpuMicros = CjguiMonotonicMicros() - composableEncodeStarted;
#endif
        if (!composableEncoded) {
            [encoder endEncoding];
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        [encoder endEncoding];

        if (shouldProbe && readbackBuffer) {
            NSUInteger textureWidth = drawable.texture.width;
            NSUInteger textureHeight = drawable.texture.height;
            if (textureWidth == 0 || textureHeight == 0) {
                readbackDegradedReason = "empty_texture";
                readbackHasDegraded = YES;
                readbackFailed = YES;
            } else {
                id<MTLBlitCommandEncoder> blit = [commandBuffer blitCommandEncoder];
                if (!blit) {
                    readbackDegradedReason = "blit_encoder_unavailable";
                    readbackHasDegraded = YES;
                    readbackFailed = YES;
                } else {
                    NSUInteger sampleX = textureWidth / 2;
                    NSUInteger sampleY = textureHeight / 2;
                    if (sceneProbeNode) {
                        sampleX = MIN(textureWidth - 1, sceneProbePoint.sampleX);
                        sampleY = MIN(textureHeight - 1, sceneProbePoint.sampleY);
                    }
                    readbackSampleX = sampleX;
                    readbackSampleY = sampleY;
                    MTLOrigin origin = MTLOriginMake(sampleX, sampleY, 0);
                    MTLSize size = MTLSizeMake(1, 1, 1);
                    [blit copyFromTexture:drawable.texture
                              sourceSlice:0
                              sourceLevel:0
                             sourceOrigin:origin
                               sourceSize:size
                                 toBuffer:readbackBuffer
                        destinationOffset:0
                   destinationBytesPerRow:readbackBytesPerRow
                 destinationBytesPerImage:readbackBytesPerRow];
                    [blit endEncoding];
                    readbackBlitEncoded = YES;
                }
            }
        }

#ifdef CJGUI_INTERNAL_TESTING
        if (testDrawablePixelRequested) {
            NSUInteger textureWidth = drawable.texture.width;
            NSUInteger textureHeight = drawable.texture.height;
            if (textureWidth > 0 && textureHeight > 0 &&
                view.bounds.size.width > 0.0 && view.bounds.size.height > 0.0) {
                NSUInteger sampleX = MIN(textureWidth - 1, (NSUInteger)((CGFloat)ctx.testDrawablePixelX * (CGFloat)textureWidth / view.bounds.size.width));
                NSUInteger sampleY = MIN(textureHeight - 1, (NSUInteger)((CGFloat)ctx.testDrawablePixelY * (CGFloat)textureHeight / view.bounds.size.height));
                testDrawablePixelBuffer = [ctx.device newBufferWithLength:readbackBytesPerRow options:MTLResourceStorageModeShared];
                id<MTLBlitCommandEncoder> testBlit = testDrawablePixelBuffer ? [commandBuffer blitCommandEncoder] : nil;
                if (testBlit) {
                    [testBlit copyFromTexture:drawable.texture
                                  sourceSlice:0
                                  sourceLevel:0
                                 sourceOrigin:MTLOriginMake(sampleX, sampleY, 0)
                                   sourceSize:MTLSizeMake(1, 1, 1)
                                      toBuffer:testDrawablePixelBuffer
                             destinationOffset:0
                        destinationBytesPerRow:readbackBytesPerRow
                      destinationBytesPerImage:readbackBytesPerRow];
                    [testBlit endEncoding];
                    testDrawablePixelBlitEncoded = YES;
                }
            }
        }
#endif

        // Hold the exact scene resources through this command buffer's
        // completion. A subsequent Cangjie scene may remove or rebind an
        // image immediately, but the in-flight encoder still owns this
        // generation's texture until Metal signals completion. The captured
        // array contains only native copies, never a Cangjie pointer/handle.
        NSArray<CJGuiInternalComposableSceneNode *> *submittedComposableResources = [view.composableNodes copy];
        // Frame identity becomes a submission fact before commit.  The
        // completion block carries only scalars and returns to the main
        // thread before it looks up the session again; it never captures or
        // mutates a domain/controller object.  A slot token alone may be
        // reused after close, so the session generation rejects a late
        // completion from the retired instance.
        const uint64_t submittedFrameIndex = view.frameIndex + 1;
        const uint64_t submissionGeneration = ctx.sessionGeneration;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> completedBuffer) {
            (void)submittedComposableResources;
            const MTLCommandBufferStatus completionStatus = completedBuffer.status;
            int64_t gpuDurationMicros = -1;
            if (completionStatus == MTLCommandBufferStatusCompleted) {
                if (@available(macOS 10.15, *)) {
                    const CFTimeInterval gpuStart = completedBuffer.GPUStartTime;
                    const CFTimeInterval gpuEnd = completedBuffer.GPUEndTime;
                    const double duration = (gpuEnd - gpuStart) * 1000000.0;
                    if (isfinite(gpuStart) && isfinite(gpuEnd) && gpuStart > 0.0 && gpuEnd >= gpuStart &&
                        isfinite(duration) && duration >= 0.0 && duration <= (double)LLONG_MAX) {
                        gpuDurationMicros = (int64_t)llround(duration);
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                CJGuiInternalSession *live = CjguiLookupSession(session);
                if (!live || live.destroyed || live.sessionGeneration != submissionGeneration) return;
                if (completionStatus == MTLCommandBufferStatusCompleted) {
                    if (submittedFrameIndex >= live.observedMetalCompletionFrameIndex) {
                        live.observedMetalCompletionFrameIndex = submittedFrameIndex;
                        live.observedMetalGpuDurationMicros = gpuDurationMicros;
                    }
                } else if (submittedFrameIndex >= live.observedMetalFailureFrameIndex) {
                    live.observedMetalFailureFrameIndex = submittedFrameIndex;
                }
            });
        }];

        [commandBuffer presentDrawable:drawable];
        view.frameIndex = submittedFrameIndex;
        [commandBuffer commit];

        if (shouldProbe) {
            if (readbackBlitEncoded && readbackBuffer) {
                [commandBuffer waitUntilCompleted];
                commandBufferWaited = YES;
                readbackCompleted = commandBuffer.status == MTLCommandBufferStatusCompleted;
                if (readbackCompleted) {
                    const uint8_t *sample = (const uint8_t *)[readbackBuffer contents];
                    if (sample) {
                        uint8_t expectedBlue = CjguiColorChannelToByte(expectedReadbackColor.blue);
                        uint8_t expectedGreen = CjguiColorChannelToByte(expectedReadbackColor.green);
                        uint8_t expectedRed = CjguiColorChannelToByte(expectedReadbackColor.red);
                        uint8_t expectedAlpha = CjguiColorChannelToByte(expectedReadbackColor.alpha);
                        if (readbackSkippedNoDeterministicScenePixel) {
                            readbackDegradedReason = "no_deterministic_scene_pixel";
                            readbackHasDegraded = YES;
                        } else {
                            readbackMatched = CjguiColorByteMatches(sample[0], expectedBlue) &&
                                              CjguiColorByteMatches(sample[1], expectedGreen) &&
                                              CjguiColorByteMatches(sample[2], expectedRed) &&
                                              CjguiColorByteMatches(sample[3], expectedAlpha);
                        }
                        if (!readbackMatched && !readbackHasDegraded) {
                            readbackDegradedReason = sceneProbeNode ? "scene_color_mismatch" : "clear_color_mismatch";
                            readbackHasDegraded = YES;
                            readbackFailed = YES;
                            if (sceneProbeNode) {
                                CjguiInternalRendererComposableNode sceneValue = sceneProbeNode.node;
                                NSLog(@"cjgui: scene readback mismatch: node_index=%u node_id=%llu kind=%u logical=%.3f,%.3f drawable=%lux%lu sample=%lu,%lu node=%.0f,%.0f,%.0f,%.0f clip=%.0f,%.0f,%.0f,%.0f expected_bgra=%u,%u,%u,%u actual_bgra=%u,%u,%u,%u",
                                      sceneProbeNode.index, (unsigned long long)sceneValue.nodeId, sceneValue.nodeKind,
                                      (double)sceneProbePoint.logicalX, (double)sceneProbePoint.logicalY,
                                      (unsigned long)drawable.texture.width, (unsigned long)drawable.texture.height,
                                      (unsigned long)readbackSampleX, (unsigned long)readbackSampleY,
                                      (double)sceneValue.x, (double)sceneValue.y, (double)sceneValue.width, (double)sceneValue.height,
                                      (double)sceneValue.clipX, (double)sceneValue.clipY,
                                      (double)sceneValue.clipWidth, (double)sceneValue.clipHeight,
                                      expectedBlue, expectedGreen, expectedRed, expectedAlpha,
                                      sample[0], sample[1], sample[2], sample[3]);
                            }
                        }
                    } else {
                        readbackDegradedReason = "buffer_contents_unavailable";
                        readbackHasDegraded = YES;
                        readbackFailed = YES;
                    }
                } else {
                    readbackDegradedReason = "command_buffer_not_completed";
                    readbackHasDegraded = YES;
                    readbackFailed = YES;
                }
            } else if (!readbackHasDegraded) {
                readbackDegradedReason = "blit_not_encoded";
                readbackHasDegraded = YES;
                readbackFailed = YES;
            }

            NSLog(@"cjgui: metal readback: requested=true");
            NSLog(@"cjgui: metal readback: command_buffer_completed=%s",
                  readbackCompleted ? "true" : "false");
            NSLog(@"cjgui: metal readback: source=%s", readbackSkippedNoDeterministicScenePixel ? "none" :
                  (sceneProbeNode ? "composable_opaque_scene_probe" : "clear_color_probe"));
            NSLog(@"cjgui: metal readback: pixel_match=%s", readbackSkippedNoDeterministicScenePixel ? "unavailable" :
                  (readbackMatched ? "true" : "false"));
            NSLog(@"cjgui: metal readback: success=%s degraded=%s",
                  readbackMatched ? "true" : "false",
                  readbackHasDegraded ? readbackDegradedReason : "none");
            view.readbackProbeCompleted = YES;
        }

#ifdef CJGUI_INTERNAL_TESTING
        if (testDrawablePixelRequested) {
            if (!commandBufferWaited) {
                [commandBuffer waitUntilCompleted];
                commandBufferWaited = YES;
            }
            ctx.testDrawablePixelPending = NO;
            ctx.testDrawablePixelCompleted = NO;
            if (testDrawablePixelBlitEncoded && commandBuffer.status == MTLCommandBufferStatusCompleted) {
                const uint8_t *sample = (const uint8_t *)[testDrawablePixelBuffer contents];
                if (sample) {
                    ctx.testDrawablePixelBlue = sample[0];
                    ctx.testDrawablePixelGreen = sample[1];
                    ctx.testDrawablePixelRed = sample[2];
                    ctx.testDrawablePixelAlpha = sample[3];
                    ctx.testDrawablePixelCompleted = YES;
                }
            }
        }
#endif

        if (readbackCompleted) {
            ctx.observedMetalCompletionFrameIndex = view.frameIndex;
        }
        CGFloat scale = view.metalLayer.contentsScale;
        NSLog(@"cjgui: frame metadata: index=%llu drawable=%.0fx%.0f scale=%.2f pixel_format=%s clear_color=%.2f,%.2f,%.2f,%.2f submitted=true committed=unknown attempts=%llu success=true degraded=%s",
              (unsigned long long)view.frameIndex,
              (double)drawableSize.width,
              (double)drawableSize.height,
              (double)scale,
              "BGRA8Unorm",
              clearColor.red, clearColor.green, clearColor.blue, clearColor.alpha,
              (unsigned long long)view.frameIndex,
              readbackSkippedNoDeterministicScenePixel ? "no_deterministic_scene_pixel" :
              ((readbackFailed && readbackHasDegraded) ? readbackDegradedReason : "none"));

        if (view.frameIndex == 1) {
            NSLog(@"cjgui: first frame rendered");
        }

        if (outObservation) {
            outObservation->frameIndex = view.frameIndex;
            outObservation->drawableWidthPixels = (uint32_t)drawableSize.width;
            outObservation->drawableHeightPixels = (uint32_t)drawableSize.height;
            outObservation->contentsScale = scale;
            outObservation->readbackAttempted = shouldProbe ? 1 : 0;
            outObservation->readbackCompleted = readbackCompleted ? 1 : 0;
            outObservation->readbackColorMatched = readbackMatched ? 1 : 0;
        }

        if (shouldProbe && readbackFailed) {
            return CJGUI_INTERNAL_RENDERER_READBACK_FAILED;
        }
        return CJGUI_INTERNAL_RENDERER_OK;
    }
}

// ---- ABI: generic composable scene ----

static CjguiInternalRendererStatus CjguiConfigureComposableSceneOnMain(uint64_t session, uint64_t projectionVersion, uint32_t nodeCount) {
    if (nodeCount == 0 || nodeCount > 1024) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.view.invalidated) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (!overlay) {
        overlay = [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
        if (!overlay) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        overlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [ctx.view addSubview:overlay];
        ctx.composableSceneOverlay = overlay;
    }
    ctx.stagedComposableSceneVersion = projectionVersion;
    // Copy only the container. The immutable current node objects are shared
    // with staging until `set_composable_scene_node` writes a changed index.
    // This preserves the all-or-nothing live snapshot while removing the
    // former per-node allocation/string-copy pass for sparse updates.
    NSArray<CJGuiInternalComposableSceneNode *> *currentNodes = ctx.composableNodes;
    NSMutableArray<CJGuiInternalComposableSceneNode *> *nextStaging = [NSMutableArray arrayWithCapacity:nodeCount];
    for (uint32_t index = 0; index < nodeCount; index++) {
        CJGuiInternalComposableSceneNode *node = index < currentNodes.count
            ? currentNodes[index] : nil;
        if (!node) {
            node = [[CJGuiInternalComposableSceneNode alloc] init];
            if (!node) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
#ifdef CJGUI_INTERNAL_TESTING
            if (ctx.testComposableSceneNodeAllocationCount < UINT64_MAX) {
                ctx.testComposableSceneNodeAllocationCount += 1;
            }
#endif
            node.index = index; node.label = @""; node.value = @""; node.imageResourcePath = @"";
            node.imageResourceId = @""; node.imageResourceVersion = 0; node.imageTextureCacheKey = @"";
            node.imageTextureContentKey = @""; node.textTextureCacheKey = @"";
            node.textTextureByteCount = 0; node.textTextureRect = NSZeroRect;
        }
        [nextStaging addObject:node];
    }
    ctx.stagedComposableNodes = nextStaging;
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableSceneConfigureMicros += CjguiMonotonicMicros() - started;
#endif
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_composable_scene(uint64_t session, uint64_t projectionVersion, uint32_t nodeCount) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = CjguiConfigureComposableSceneOnMain(session, projectionVersion, nodeCount); });
        return status;
    }
    return CjguiConfigureComposableSceneOnMain(session, projectionVersion, nodeCount);
}

static CjguiInternalRendererStatus CjguiSetComposableSceneNodeOnMain(
    uint64_t session, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    if (!node || nodeIndex >= ctx.stagedComposableNodes.count || node->projectionVersion != ctx.stagedComposableSceneVersion ||
        node->width < 0 || node->height < 0 || node->clipWidth < 0 || node->clipHeight < 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
#ifdef CJGUI_INTERNAL_TESTING
    if (ctx.forcedComposableSceneNodeFailures > 0) {
        ctx.forcedComposableSceneNodeFailures -= 1;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
#endif
    CJGuiInternalComposableSceneNode *copy = ctx.stagedComposableNodes[nodeIndex];
    // A setter is the COW boundary. It runs only for Cangjie nodes whose
    // rendered/input state changed, so untouched staged entries still point
    // to the accepted live snapshot and cannot be mutated by this candidate.
    CJGuiInternalComposableSceneNode *live = nodeIndex < ctx.composableNodes.count
        ? ctx.composableNodes[nodeIndex] : nil;
    if (copy == live) {
        copy = CjguiCloneComposableSceneNode(ctx, live, nodeIndex, node->projectionVersion);
        if (!copy) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        ctx.stagedComposableNodes[nodeIndex] = copy;
    }
    copy.node = *node; copy.index = nodeIndex;
    if (ctx.composableSceneNodeUpdateCount < UINT64_MAX) ctx.composableSceneNodeUpdateCount += 1;
    if (copy.node.preservesActiveLocalText != 0 && copy.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        ctx.composableLocalAcknowledgementCount += 1;
    }
    copy.label = label ? [NSString stringWithUTF8String:label] : @"";
    copy.value = value ? [NSString stringWithUTF8String:value] : @"";
    copy.imageResourcePath = imageResourcePath ? [NSString stringWithUTF8String:imageResourcePath] : @"";
    copy.imageResourceId = imageResourceId ? [NSString stringWithUTF8String:imageResourceId] : copy.imageResourcePath;
    copy.imageResourceVersion = imageResourceVersion;
    if (copy.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) {
        NSString *resolved = nil;
        NSString *declaredCacheKey = CjguiComposableImageCacheKey(copy.imageResourcePath, copy.imageResourceId,
                                                                   copy.imageResourceVersion, &resolved);
        id<MTLTexture> previousTexture = copy.imageTexture;
        if (declaredCacheKey && previousTexture && [copy.imageTextureContentKey isEqualToString:declaredCacheKey]) {
            // A cache eviction drops only reuse ownership. The live/staged
            // node already has the exact declared texture, so a completion
            // for some other resource must not start it again.
            copy.imageTextureCacheKey = declaredCacheKey;
        } else {
        NSString *cacheKey = nil;
        uint32_t resourceState = CjguiComposableImageResourceFailed;
        id<MTLTexture> texture = CjguiComposableImageTexture(ctx, session, copy.imageResourcePath,
            copy.imageResourceId, copy.imageResourceVersion, &cacheKey, &resourceState);
        copy.imageTextureCacheKey = cacheKey ?: @"";
        // Loading/failed resources are accepted projection states, never a
        // reason to reject a user action. Preserve a prior texture as a
        // visible fallback until the keyed completion causes one normal
        // refresh; a first load renders its declared fill/placeholder only.
            if (texture) {
                copy.imageTexture = texture;
                copy.imageTextureContentKey = cacheKey ?: @"";
            } else if (!previousTexture) {
                copy.imageTexture = nil;
                copy.imageTextureContentKey = @"";
            }
        }
    } else {
        copy.imageTexture = nil; copy.imageTextureCacheKey = @""; copy.imageTextureContentKey = @"";
    }
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableSceneSetMicros += CjguiMonotonicMicros() - started;
#endif
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_scene_node(
    uint64_t session, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath,
    const char *imageResourceId, uint64_t imageResourceVersion) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = CjguiSetComposableSceneNodeOnMain(session, nodeIndex, node, label, value, imageResourcePath,
                                                        imageResourceId, imageResourceVersion);
        });
        return status;
    }
    return CjguiSetComposableSceneNodeOnMain(session, nodeIndex, node, label, value, imageResourcePath,
                                              imageResourceId, imageResourceVersion);
}

CjguiInternalRendererStatus
cjgui_internal_renderer_focus_composable_node(uint64_t session, uint64_t nodeId) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_focus_composable_node(session, nodeId);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return [ctx.composableSceneOverlay focusCommittedNodeId:nodeId]
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_cancel_composable_pointer_capture(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_cancel_composable_pointer_capture(session);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    [ctx.composableSceneOverlay cancelPointerCapture];
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus CjguiCommitComposableSceneOnMain(uint64_t session) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || !ctx.composableSceneOverlay || ctx.stagedComposableNodes.count == 0) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t started = CjguiMonotonicMicros();
#endif
    for (CJGuiInternalComposableSceneNode *node in ctx.stagedComposableNodes) {
        // Reused COW entries intentionally keep their original capture
        // version. Only a never-initialized slot is invalid; native FIFO
        // provenance comes from the committed session version below.
        if (node.node.projectionVersion == 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    // Text resources are prepared while admitting the immutable scene, never
    // from the Metal encoder.  This keeps AppKit text shaping out of the
    // frame-critical command-buffer path and lets the encoder only reuse a
    // committed texture.
    if (!CjguiPrepareComposableTextResources(ctx)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    BOOL imageContentChanged = CjguiComposableImageContentChanged(ctx.composableNodes, ctx.stagedComposableNodes);
    ctx.composableSceneVersion = ctx.stagedComposableSceneVersion;
    ctx.composableNodes = [ctx.stagedComposableNodes mutableCopy];
    CjguiPruneComposableImageTextureCache(ctx, NO);
    ctx.view.composableNodes = [ctx.composableNodes copy];
    if (imageContentChanged) {
        ctx.view.readbackProbeCompleted = NO;
    }
    // A readback is a first-frame rendering diagnostic, not normal editing
    // work. Scene updates still submit Metal commands, but do not force a
    // synchronous GPU readback after every keystroke or lightweight refresh.
    ctx.sharedOperationOverlay.hidden = YES;
    ctx.sharedEditingFormOverlay.hidden = YES;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    // Title ownership is the application-host configuration. A scene commit
    // may refresh business content but must not overwrite that declaration.
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableSceneCommitMicros += CjguiMonotonicMicros() - started;
#endif
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_present_composable_scene(uint64_t session, CjguiInternalRendererFrameObservation *outObservation) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_present_composable_scene(session, outObservation);
        });
        return status;
    }
#ifdef CJGUI_INTERNAL_TESTING
    CJGuiInternalSession *candidate = CjguiLookupSession(session);
    if (candidate && candidate.forcedComposablePresentFailures > 0) {
        candidate.forcedComposablePresentFailures -= 1;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
#endif
    CJGuiInternalSession *beforeCommit = CjguiLookupSession(session);
    NSArray<CJGuiInternalComposableSceneNode *> *previousNodes = [beforeCommit.composableNodes copy];
    uint64_t previousSceneVersion = beforeCommit.composableSceneVersion;
    CjguiInternalRendererStatus committed = CjguiCommitComposableSceneOnMain(session);
    if (committed != CJGUI_INTERNAL_RENDERER_OK) return committed;
    CjguiInternalRendererClearColor clear = { 0.08, 0.16, 0.20, 1.0 };
    CjguiInternalRendererStatus status = cjgui_internal_renderer_present_clear(session, &clear, outObservation);
    // A missing drawable/encoder means there was no usable replacement
    // frame. Restore the old native input and overlay snapshot before the
    // caller retries; otherwise Cangjie would honestly retain the old scene
    // while AppKit had already started dispatching the staged one.
    if (status != CJGUI_INTERNAL_RENDERER_OK && status != CJGUI_INTERNAL_RENDERER_READBACK_FAILED) {
        CJGuiInternalSession *ctx = CjguiLookupSession(session);
        if (ctx && !ctx.destroyed) {
            ctx.composableSceneVersion = previousSceneVersion;
            ctx.composableNodes = [previousNodes mutableCopy] ?: [NSMutableArray array];
            ctx.view.composableNodes = [ctx.composableNodes copy];
            [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
        }
    }
    return status;
}

static CjguiInternalRendererStatus CjguiPrepareComposableImageResourceAbiOnMain(
    uint64_t sessionToken, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState = CjguiComposableImageResourceUnrequested;
    CJGuiInternalSession *session = CjguiLookupSession(sessionToken);
    if (!session || session.destroyed || !session.view) {
        return session ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSString *path = resourcePath ? [NSString stringWithUTF8String:resourcePath] : @"";
    NSString *identifier = resourceId ? [NSString stringWithUTF8String:resourceId] : @"";
    if (!path || !identifier) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState = CjguiPrepareComposableImageResourceOnMain(session, sessionToken, path, identifier,
                                                           resourceVersion, YES, NULL);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_prepare_composable_image_resource(
    uint64_t session, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = CjguiPrepareComposableImageResourceAbiOnMain(session, resourcePath, resourceId,
                                                                    resourceVersion, outState);
        });
        return status;
    }
    return CjguiPrepareComposableImageResourceAbiOnMain(session, resourcePath, resourceId, resourceVersion, outState);
}

static CjguiInternalRendererStatus CjguiComposableImageResourceStateOnMain(
    uint64_t sessionToken, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState = CjguiComposableImageResourceUnrequested;
    CJGuiInternalSession *session = CjguiLookupSession(sessionToken);
    if (!session || session.destroyed || !session.view) {
        return session ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSString *path = resourcePath ? [NSString stringWithUTF8String:resourcePath] : @"";
    NSString *identifier = resourceId ? [NSString stringWithUTF8String:resourceId] : @"";
    NSString *cacheKey = CjguiComposableImageCacheKey(path, identifier, resourceVersion, NULL);
    if (!path || !identifier || !cacheKey) {
        *outState = CjguiComposableImageResourceFailed;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (session.composableImageTextureCache[cacheKey]) {
        CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
        if (resource) resource.lastAccess = CjguiComposableImageNextAccess(session);
        *outState = CjguiComposableImageResourceReady;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (CjguiComposableImageBoundTexture(session, cacheKey)) {
        CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
        if (resource) resource.lastAccess = CjguiComposableImageNextAccess(session);
        *outState = CjguiComposableImageResourceReady;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    CJGuiInternalComposableImageResource *resource = session.composableImageResources[cacheKey];
    if (resource) {
        resource.lastAccess = CjguiComposableImageNextAccess(session);
        *outState = resource.state;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_composable_image_resource_state(
    uint64_t session, const char *resourcePath, const char *resourceId,
    uint64_t resourceVersion, uint32_t *outState) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = CjguiComposableImageResourceStateOnMain(session, resourcePath, resourceId,
                                                               resourceVersion, outState);
        });
        return status;
    }
    return CjguiComposableImageResourceStateOnMain(session, resourcePath, resourceId, resourceVersion, outState);
}

CjguiInternalRendererStatus
cjgui_internal_renderer_composable_viewport(uint64_t session, CjguiInternalRendererViewport *outViewport) {
    if (!outViewport) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = cjgui_internal_renderer_composable_viewport(session, outViewport); });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    [ctx.view updateDrawableSize];
    outViewport->width = (uint32_t)MAX(0.0, ctx.view.bounds.size.width);
    outViewport->height = (uint32_t)MAX(0.0, ctx.view.bounds.size.height);
    outViewport->resizeVersion = ctx.resizeVersion;
    outViewport->resourceCompletionVersion = ctx.composableImageResourceCompletionVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_composable_display_progress(
    uint64_t session, CjguiInternalRendererComposableDisplayProgress *outProgress) {
    if (!outProgress) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outProgress, 0, sizeof(*outProgress));
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_composable_display_progress(session, outProgress);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || ctx.destroyed || !ctx.view || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    outProgress->submittedFrameIndex = ctx.view.frameIndex;
    outProgress->observedMetalCompletionFrameIndex = ctx.observedMetalCompletionFrameIndex;
    outProgress->observedMetalFailureFrameIndex = ctx.observedMetalFailureFrameIndex;
    outProgress->observedMetalGpuDurationMicros = ctx.observedMetalGpuDurationMicros;
    outProgress->overlayDrawnProjectionVersion = ctx.composableSceneOverlay.lastDrawnProjectionVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus CjguiMeasureComposableTextOnMain(
    uint64_t session, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t maximumWidth, CjguiInternalRendererTextMeasurement *outMeasurement) {
    if (!outMeasurement) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outMeasurement, 0, sizeof(*outMeasurement));
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (ctx.forcedComposableMeasurementFailures > 0) {
        ctx.forcedComposableMeasurementFailures -= 1;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (ctx.composableTextMeasurementCount < UINT32_MAX) ctx.composableTextMeasurementCount += 1;
    NSFont *font = CjguiComposableFontForStyle(fontSize, fontWeight, fontFamily);
    if (!font) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSString *value = text ? [NSString stringWithUTF8String:text] : @"";
    if (!value) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attributes = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraph };
    CGFloat constrainedWidth = maximumWidth > 0 ? (CGFloat)maximumWidth : CGFLOAT_MAX / 4.0;
    NSRect bounds = [value boundingRectWithSize:NSMakeSize(constrainedWidth, CGFLOAT_MAX / 4.0)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:attributes];
    CGFloat lineHeight = MAX(1.0, font.ascender - font.descender + font.leading);
    CGFloat height = MAX(lineHeight, ceil(bounds.size.height));
    outMeasurement->width = (uint32_t)MIN(UINT32_MAX, MAX(0.0, ceil(bounds.size.width)));
    outMeasurement->height = (uint32_t)MIN(UINT32_MAX, height);
    outMeasurement->lineHeight = (uint32_t)MIN(UINT32_MAX, ceil(lineHeight));
    outMeasurement->baseline = (uint32_t)MIN(UINT32_MAX, MAX(0.0, ceil(font.ascender)));
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_measure_composable_text(uint64_t session, const char *text,
                                                double fontSize, uint32_t fontWeight,
                                                uint32_t fontFamily, uint32_t maximumWidth,
                                                CjguiInternalRendererTextMeasurement *outMeasurement) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = CjguiMeasureComposableTextOnMain(session, text, fontSize, fontWeight, fontFamily, maximumWidth, outMeasurement);
        });
        return status;
    }
    return CjguiMeasureComposableTextOnMain(session, text, fontSize, fontWeight, fontFamily, maximumWidth, outMeasurement);
}

#ifdef CJGUI_INTERNAL_TESTING
// Test-only seams. They intentionally drive the same production overlay and
// NSTextView delegate used by an ordinary window, but are not part of the
// shipped renderer ABI.
CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_image_launch_gate(uint64_t session, uint8_t held) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_set_composable_image_launch_gate(session, held);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    ctx.testComposableImageLaunchGateHeld = held != 0;
    if (!ctx.testComposableImageLaunchGateHeld) {
        CjguiStartNextComposableImageLoads(ctx, session);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_image_pipeline_stats(
    uint64_t session, uint64_t *outPathResolveMicros, uint64_t *outCacheHitCount,
    uint64_t *outAsyncLaunchCount, uint64_t *outAsyncTotalMicros,
    uint32_t *outPeakInFlight, uint32_t *outPeakPending,
    uint64_t *outCacheBytes, uint64_t *outResourceCompletionVersion) {
    if (!outPathResolveMicros || !outCacheHitCount || !outAsyncLaunchCount || !outAsyncTotalMicros ||
        !outPeakInFlight || !outPeakPending || !outCacheBytes || !outResourceCompletionVersion) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outPathResolveMicros = 0; *outCacheHitCount = 0; *outAsyncLaunchCount = 0; *outAsyncTotalMicros = 0;
    *outPeakInFlight = 0; *outPeakPending = 0; *outCacheBytes = 0; *outResourceCompletionVersion = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    uint64_t cacheBytes = 0;
    for (id<MTLTexture> texture in ctx.composableImageTextureCache.allValues) {
        NSUInteger bytes = CjguiComposableImageTextureBytes(texture);
        cacheBytes = bytes > UINT64_MAX - cacheBytes ? UINT64_MAX : cacheBytes + bytes;
    }
    *outPathResolveMicros = ctx.testComposableImagePathResolveMicros;
    *outCacheHitCount = ctx.testComposableImageCacheHitCount;
    *outAsyncLaunchCount = ctx.testComposableImageAsyncLaunchCount;
    *outAsyncTotalMicros = ctx.testComposableImageAsyncTotalMicros;
    *outPeakInFlight = ctx.testComposableImagePeakInFlight;
    *outPeakPending = ctx.testComposableImagePeakPending;
    *outCacheBytes = cacheBytes;
    *outResourceCompletionVersion = ctx.composableImageResourceCompletionVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_image_stats(uint64_t session, uint32_t *outLoadedTextureCount,
                                                    uint32_t *outCacheEntryCount, uint32_t *outDecodeCount) {
    if (!outLoadedTextureCount || !outCacheEntryCount || !outDecodeCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outLoadedTextureCount = 0; *outCacheEntryCount = 0; *outDecodeCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    uint32_t loaded = 0;
    for (CJGuiInternalComposableSceneNode *node in ctx.composableNodes) {
        if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE && node.imageTexture) loaded += 1;
    }
    *outLoadedTextureCount = loaded;
    *outCacheEntryCount = (uint32_t)MIN(UINT32_MAX, ctx.composableImageTextureCache.count);
    *outDecodeCount = ctx.composableImageDecodeCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scene_update_stats(uint64_t session, uint32_t *outCommittedNodeCount,
                                                            uint64_t *outNodeUpdateCount) {
    if (!outCommittedNodeCount || !outNodeUpdateCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outCommittedNodeCount = 0; *outNodeUpdateCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outCommittedNodeCount = (uint32_t)MIN(UINT32_MAX, ctx.composableNodes.count);
    *outNodeUpdateCount = ctx.composableSceneNodeUpdateCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scene_submission_stats(
    uint64_t session,
    uint64_t *outCloneCount,
    uint64_t *outNodeAllocationCount,
    uint64_t *outConfigureMicros,
    uint64_t *outSetMicros,
    uint64_t *outCommitMicros) {
    if (!outCloneCount || !outNodeAllocationCount || !outConfigureMicros || !outSetMicros || !outCommitMicros) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outCloneCount = 0; *outNodeAllocationCount = 0; *outConfigureMicros = 0;
    *outSetMicros = 0; *outCommitMicros = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outCloneCount = ctx.testComposableSceneCloneCount;
    *outNodeAllocationCount = ctx.testComposableSceneNodeAllocationCount;
    *outConfigureMicros = ctx.testComposableSceneConfigureMicros;
    *outSetMicros = ctx.testComposableSceneSetMicros;
    *outCommitMicros = ctx.testComposableSceneCommitMicros;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_interaction_stats(uint64_t session,
                                                           uint32_t *outPendingInteractionCount,
                                                           uint32_t *outMaxPendingInteractionCount,
                                                           uint64_t *outAccessibilityNotificationCount) {
    if (!outPendingInteractionCount || !outMaxPendingInteractionCount || !outAccessibilityNotificationCount) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outPendingInteractionCount = 0; *outMaxPendingInteractionCount = 0; *outAccessibilityNotificationCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outPendingInteractionCount = (uint32_t)MIN(UINT32_MAX, ctx.pendingInteractions.count);
    *outMaxPendingInteractionCount = ctx.testComposableMaxPendingInteractionCount;
    *outAccessibilityNotificationCount = ctx.testComposableAccessibilityNotificationCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_interaction_trace(uint64_t session,
                                                           uint32_t *outPendingInteractionCount,
                                                           uint32_t *outLastEnqueuedKind,
                                                           uint64_t *outLastEnqueuedNodeId,
                                                           uint64_t *outLastEnqueuedProjectionVersion,
                                                           uint32_t *outLastPumpedKind,
                                                           uint64_t *outLastPumpedNodeId,
                                                           uint64_t *outLastPumpedProjectionVersion) {
    if (!outPendingInteractionCount || !outLastEnqueuedKind || !outLastEnqueuedNodeId ||
        !outLastEnqueuedProjectionVersion || !outLastPumpedKind || !outLastPumpedNodeId || !outLastPumpedProjectionVersion) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outPendingInteractionCount = 0; *outLastEnqueuedKind = 0; *outLastEnqueuedNodeId = 0;
    *outLastEnqueuedProjectionVersion = 0; *outLastPumpedKind = 0; *outLastPumpedNodeId = 0; *outLastPumpedProjectionVersion = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outPendingInteractionCount = (uint32_t)MIN(UINT32_MAX, ctx.pendingInteractions.count);
    *outLastEnqueuedKind = ctx.testComposableLastEnqueuedKind;
    *outLastEnqueuedNodeId = ctx.testComposableLastEnqueuedNodeId;
    *outLastEnqueuedProjectionVersion = ctx.testComposableLastEnqueuedProjectionVersion;
    *outLastPumpedKind = ctx.testComposableLastPumpedKind;
    *outLastPumpedNodeId = ctx.testComposableLastPumpedNodeId;
    *outLastPumpedProjectionVersion = ctx.testComposableLastPumpedProjectionVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_process_resource_stats(uint64_t session,
                                                     uint64_t *outResidentBytes,
                                                     uint64_t *outUserMicros,
                                                     uint64_t *outSystemMicros) {
    if (!outResidentBytes || !outUserMicros || !outSystemMicros) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outResidentBytes = 0; *outUserMicros = 0; *outSystemMicros = 0;
    if (!CjguiLookupSession(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    mach_task_basic_info_data_t taskInfo;
    mach_msg_type_number_t taskInfoCount = MACH_TASK_BASIC_INFO_COUNT;
    if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&taskInfo, &taskInfoCount) != KERN_SUCCESS) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    struct rusage usage;
    if (getrusage(RUSAGE_SELF, &usage) != 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outResidentBytes = (uint64_t)taskInfo.resident_size;
    *outUserMicros = (uint64_t)usage.ru_utime.tv_sec * 1000000ULL + (uint64_t)usage.ru_utime.tv_usec;
    *outSystemMicros = (uint64_t)usage.ru_stime.tv_sec * 1000000ULL + (uint64_t)usage.ru_stime.tv_usec;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_measurement_count(uint64_t session, uint32_t *outMeasurementCount) {
    if (!outMeasurementCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outMeasurementCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outMeasurementCount = ctx.composableTextMeasurementCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_local_acknowledgement_count(uint64_t session, uint64_t *outCount) {
    if (!outCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outCount = ctx.composableLocalAcknowledgementCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_input_timing(uint64_t session,
                                                      uint64_t *outMutationMicros,
                                                      uint64_t *outTextDelegateMicros,
                                                      uint64_t *outSelectionDelegateMicros,
                                                      uint64_t *outEventEnqueueMicros,
                                                      uint64_t *outAccessibilityMicros) {
    if (!outMutationMicros || !outTextDelegateMicros || !outSelectionDelegateMicros || !outEventEnqueueMicros || !outAccessibilityMicros) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outMutationMicros = 0; *outTextDelegateMicros = 0; *outSelectionDelegateMicros = 0;
    *outEventEnqueueMicros = 0; *outAccessibilityMicros = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outMutationMicros = ctx.testComposableInputMutationMicros;
    *outTextDelegateMicros = ctx.testComposableTextDelegateMicros;
    *outSelectionDelegateMicros = ctx.testComposableSelectionDelegateMicros;
    *outEventEnqueueMicros = ctx.testComposableEventEnqueueMicros;
    *outAccessibilityMicros = ctx.testComposableAccessibilityMicros;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_bounded_input_layout(uint64_t session, uint8_t enabled) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalComposableSceneOverlay *overlay = ctx ? ctx.composableSceneOverlay : nil;
    if (!overlay || !overlay.inputProxy) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    overlay.testUsesBoundedInputLayout = enabled != 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_selection_body_preparation_mode(uint64_t session, uint8_t mode) {
    if (mode > 1) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalComposableSceneOverlay *overlay = ctx ? ctx.composableSceneOverlay : nil;
    if (!overlay || !overlay.inputProxy) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    overlay.testForceFullBodyPreparationOnSelection = mode == 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_reset_composable_input_callback_trace(uint64_t session) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalComposableInputCallbackTrace *trace = ctx ? ctx.composableSceneOverlay.testInputCallbackTrace : nil;
    if (!trace) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    [trace reset];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_input_callback_trace(
    uint64_t session,
    uint64_t *outSuperInsertMicros, uint64_t *outModeChangeCount,
    uint64_t *outModeChangeMicros, uint64_t *outTextCallbackCount,
    uint64_t *outTextCallbackMicros, uint64_t *outSelectionCallbackCount,
    uint64_t *outPendingEditSelectionCount, uint64_t *outSelectionCallbackMicros,
    uint64_t *outSelectionRevealMicros, uint64_t *outSelectionQueueMicros,
    uint64_t *outSelectionAccessibilityMicros, uint64_t *outRefreshMicros,
    uint64_t *outPreparationMicros, uint64_t *outWholeAttributeWriteCount,
    uint64_t *outWholeAttributeCharacters, uint64_t *outFallbackApplyCount,
    uint64_t *outFallbackCharacters, uint64_t *outFallbackMicros) {
    if (!outSuperInsertMicros || !outModeChangeCount || !outModeChangeMicros || !outTextCallbackCount ||
        !outTextCallbackMicros || !outSelectionCallbackCount || !outPendingEditSelectionCount ||
        !outSelectionCallbackMicros || !outSelectionRevealMicros || !outSelectionQueueMicros ||
        !outSelectionAccessibilityMicros || !outRefreshMicros || !outPreparationMicros ||
        !outWholeAttributeWriteCount || !outWholeAttributeCharacters || !outFallbackApplyCount ||
        !outFallbackCharacters || !outFallbackMicros) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSuperInsertMicros = 0; *outModeChangeCount = 0; *outModeChangeMicros = 0;
    *outTextCallbackCount = 0; *outTextCallbackMicros = 0; *outSelectionCallbackCount = 0;
    *outPendingEditSelectionCount = 0; *outSelectionCallbackMicros = 0; *outSelectionRevealMicros = 0;
    *outSelectionQueueMicros = 0; *outSelectionAccessibilityMicros = 0; *outRefreshMicros = 0;
    *outPreparationMicros = 0; *outWholeAttributeWriteCount = 0; *outWholeAttributeCharacters = 0;
    *outFallbackApplyCount = 0; *outFallbackCharacters = 0; *outFallbackMicros = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalComposableInputCallbackTrace *trace = ctx ? ctx.composableSceneOverlay.testInputCallbackTrace : nil;
    if (!trace) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outSuperInsertMicros = trace.superInsertMicros; *outModeChangeCount = trace.modeChangeCount;
    *outModeChangeMicros = trace.modeChangeMicros; *outTextCallbackCount = trace.textCallbackCount;
    *outTextCallbackMicros = trace.textCallbackMicros; *outSelectionCallbackCount = trace.selectionCallbackCount;
    *outPendingEditSelectionCount = trace.pendingEditSelectionCount; *outSelectionCallbackMicros = trace.selectionCallbackMicros;
    *outSelectionRevealMicros = trace.selectionRevealMicros; *outSelectionQueueMicros = trace.selectionQueueMicros;
    *outSelectionAccessibilityMicros = trace.selectionAccessibilityMicros; *outRefreshMicros = trace.refreshMicros;
    *outPreparationMicros = trace.preparationMicros; *outWholeAttributeWriteCount = trace.wholeAttributeWriteCount;
    *outWholeAttributeCharacters = trace.wholeAttributeCharacters; *outFallbackApplyCount = trace.fallbackApplyCount;
    *outFallbackCharacters = trace.fallbackCharacters; *outFallbackMicros = trace.fallbackMicros;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_layout_work_counts(uint64_t session,
                                                                   uint64_t *outRangeLayoutCount,
                                                                   uint64_t *outFullLayoutCount) {
    if (!outRangeLayoutCount || !outFullLayoutCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outRangeLayoutCount = 0; *outFullLayoutCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outRangeLayoutCount = ctx.composableSceneOverlay.activeTextRangeLayoutCount;
    *outFullLayoutCount = ctx.composableSceneOverlay.activeTextFullLayoutCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_reset_composable_active_layout_trace(uint64_t session) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || !ctx.composableSceneOverlay.activeTextLayoutTrace) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    [ctx.composableSceneOverlay.activeTextLayoutTrace reset];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_layout_trace(
    uint64_t session,
    uint64_t *outCharacterEnsureCount, uint64_t *outCharacterEnsureMicros,
    uint64_t *outBoundingEnsureCount, uint64_t *outBoundingEnsureMicros,
    uint64_t *outGlyphIndexCount, uint64_t *outGlyphIndexMicros,
    uint64_t *outLineFragmentCount, uint64_t *outLineFragmentMicros,
    uint64_t *outGlyphLocationCount, uint64_t *outGlyphLocationMicros,
    uint64_t *outPositionProxyMicros, uint64_t *outPositionNoopWrites,
    uint64_t *outPositionChangedWrites, uint64_t *outFirstUnlaidBefore,
    uint64_t *outFirstUnlaidAfter, uint64_t *outInvalidatedLocation,
    uint64_t *outInvalidatedLength, uint64_t *outRevealMicros,
    uint64_t *outCandidateMicros, uint64_t *outPositionFirstUnlaidBefore,
    uint64_t *outPositionFirstUnlaidAfter, uint64_t *outPositionChangedMask) {
    if (!outCharacterEnsureCount || !outCharacterEnsureMicros || !outBoundingEnsureCount || !outBoundingEnsureMicros ||
        !outGlyphIndexCount || !outGlyphIndexMicros || !outLineFragmentCount || !outLineFragmentMicros ||
        !outGlyphLocationCount || !outGlyphLocationMicros || !outPositionProxyMicros || !outPositionNoopWrites ||
        !outPositionChangedWrites || !outFirstUnlaidBefore || !outFirstUnlaidAfter || !outInvalidatedLocation ||
        !outInvalidatedLength || !outRevealMicros || !outCandidateMicros || !outPositionFirstUnlaidBefore ||
        !outPositionFirstUnlaidAfter || !outPositionChangedMask) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outCharacterEnsureCount = 0; *outCharacterEnsureMicros = 0; *outBoundingEnsureCount = 0; *outBoundingEnsureMicros = 0;
    *outGlyphIndexCount = 0; *outGlyphIndexMicros = 0; *outLineFragmentCount = 0; *outLineFragmentMicros = 0;
    *outGlyphLocationCount = 0; *outGlyphLocationMicros = 0; *outPositionProxyMicros = 0; *outPositionNoopWrites = 0;
    *outPositionChangedWrites = 0; *outFirstUnlaidBefore = UINT64_MAX; *outFirstUnlaidAfter = UINT64_MAX;
    *outInvalidatedLocation = UINT64_MAX; *outInvalidatedLength = 0; *outRevealMicros = 0; *outCandidateMicros = 0;
    *outPositionFirstUnlaidBefore = UINT64_MAX; *outPositionFirstUnlaidAfter = UINT64_MAX; *outPositionChangedMask = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalComposableActiveLayoutTrace *trace = ctx ? ctx.composableSceneOverlay.activeTextLayoutTrace : nil;
    if (!trace) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outCharacterEnsureCount = trace.characterEnsureCount; *outCharacterEnsureMicros = trace.characterEnsureMicros;
    *outBoundingEnsureCount = trace.boundingEnsureCount; *outBoundingEnsureMicros = trace.boundingEnsureMicros;
    *outGlyphIndexCount = trace.glyphIndexCount; *outGlyphIndexMicros = trace.glyphIndexMicros;
    *outLineFragmentCount = trace.lineFragmentCount; *outLineFragmentMicros = trace.lineFragmentMicros;
    *outGlyphLocationCount = trace.glyphLocationCount; *outGlyphLocationMicros = trace.glyphLocationMicros;
    *outPositionProxyMicros = trace.positionProxyMicros; *outPositionNoopWrites = trace.positionNoopWrites;
    *outPositionChangedWrites = trace.positionChangedWrites; *outFirstUnlaidBefore = trace.firstUnlaidBefore;
    *outFirstUnlaidAfter = trace.firstUnlaidAfter; *outInvalidatedLocation = trace.invalidatedLocation;
    *outInvalidatedLength = trace.invalidatedLength; *outRevealMicros = trace.revealMicros; *outCandidateMicros = trace.candidateMicros;
    *outPositionFirstUnlaidBefore = trace.positionFirstUnlaidBefore;
    *outPositionFirstUnlaidAfter = trace.positionFirstUnlaidAfter;
    *outPositionChangedMask = trace.positionChangedMask;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_nstextview_insert_baseline(const char *text,
                                                         uint32_t selectionLocation,
                                                         float contentWidth,
                                                         uint64_t *outMutationMicros) {
    if (!outMutationMicros || !CjguiIsMainThread()) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
    *outMutationMicros = 0;
    NSString *value = text ? [NSString stringWithUTF8String:text] : @"";
    if (!value || !(contentWidth > 0.0f)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, contentWidth, 96.0)];
    textView.drawsBackground = NO; textView.editable = YES; textView.selectable = YES;
    textView.richText = NO; textView.usesRuler = NO; textView.allowsUndo = NO;
    textView.continuousSpellCheckingEnabled = NO; textView.grammarCheckingEnabled = NO;
    textView.automaticSpellingCorrectionEnabled = NO; textView.automaticTextReplacementEnabled = NO;
    textView.automaticQuoteSubstitutionEnabled = NO; textView.automaticDashSubstitutionEnabled = NO;
    textView.textContainer.lineFragmentPadding = 0.0;
    textView.textContainer.maximumNumberOfLines = 0;
    textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    textView.textContainer.containerSize = NSMakeSize(contentWidth, CGFLOAT_MAX);
    textView.textContainer.widthTracksTextView = NO;
    textView.layoutManager.allowsNonContiguousLayout = YES;
    textView.layoutManager.backgroundLayoutEnabled = NO;
    textView.font = [NSFont systemFontOfSize:13.0];
    textView.string = value;
    NSUInteger selection = MIN((NSUInteger)selectionLocation, textView.string.length);
    textView.selectedRange = NSMakeRange(selection, 0);
    [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];
    uint64_t started = CjguiMonotonicMicros();
    [textView insertText:@"X" replacementRange:NSMakeRange(NSNotFound, 0)];
    *outMutationMicros = CjguiMonotonicMicros() - started;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void CjguiEnsureNativeTextViewCaretLayout(NSTextView *textView) {
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSTextContainer *container = textView.textContainer;
    NSUInteger length = textView.string.length;
    if (!layoutManager || !container || length == 0) return;
    NSUInteger location = MIN(textView.selectedRange.location, length);
    NSUInteger character = location >= length ? length - 1 : location;
    [layoutManager ensureLayoutForCharacterRange:NSMakeRange(character, 1)];
    NSUInteger glyph = [layoutManager glyphIndexForCharacterAtIndex:character];
    // These are the same concrete geometry queries used by the composable
    // caret reveal path. The return values are intentionally discarded: the
    // test seam measures their completed TextKit work, not a parallel result.
    if (!(location == length && layoutManager.extraLineFragmentTextContainer == container &&
          !NSIsEmptyRect(layoutManager.extraLineFragmentRect))) {
        (void)[layoutManager lineFragmentRectForGlyphAtIndex:glyph effectiveRange:NULL];
        (void)[layoutManager locationForGlyphAtIndex:glyph];
    }
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_nstextview_insert_visible_layout_baseline(
    const char *text, uint32_t selectionLocation, float contentWidth,
    uint64_t *outMutationMicros, uint64_t *outSelectionLayoutMicros) {
    if (!outMutationMicros || !outSelectionLayoutMicros || !CjguiIsMainThread()) {
        return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
    }
    *outMutationMicros = 0;
    *outSelectionLayoutMicros = 0;
    NSString *value = text ? [NSString stringWithUTF8String:text] : @"";
    if (!value || !(contentWidth > 0.0f)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, contentWidth, 96.0)];
    textView.drawsBackground = NO; textView.editable = YES; textView.selectable = YES;
    textView.richText = NO; textView.usesRuler = NO; textView.allowsUndo = NO;
    textView.continuousSpellCheckingEnabled = NO; textView.grammarCheckingEnabled = NO;
    textView.automaticSpellingCorrectionEnabled = NO; textView.automaticTextReplacementEnabled = NO;
    textView.automaticQuoteSubstitutionEnabled = NO; textView.automaticDashSubstitutionEnabled = NO;
    textView.verticallyResizable = NO; textView.horizontallyResizable = NO;
    textView.minSize = NSMakeSize(contentWidth, 96.0);
    textView.maxSize = NSMakeSize(contentWidth, 96.0);
    textView.textContainer.lineFragmentPadding = 0.0;
    textView.textContainer.maximumNumberOfLines = 0;
    textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    textView.textContainer.containerSize = NSMakeSize(contentWidth, CGFLOAT_MAX);
    textView.textContainer.widthTracksTextView = NO;
    textView.layoutManager.allowsNonContiguousLayout = YES;
    textView.layoutManager.backgroundLayoutEnabled = NO;
    textView.font = [NSFont systemFontOfSize:13.0];
    textView.string = value;
    // Match the self-drawn active control's normal first-frame need: only
    // the viewport is realized before selection and insertion, not the
    // document's full text container.
    [textView.layoutManager ensureLayoutForBoundingRect:NSMakeRect(0.0, 0.0, contentWidth, 96.0)
                                         inTextContainer:textView.textContainer];
    NSUInteger selection = MIN((NSUInteger)selectionLocation, textView.string.length);
    textView.selectedRange = NSMakeRange(selection, 0);
    uint64_t mutationStarted = CjguiMonotonicMicros();
    [textView insertText:@"X" replacementRange:NSMakeRange(NSNotFound, 0)];
    *outMutationMicros = CjguiMonotonicMicros() - mutationStarted;
    uint64_t selectionStarted = CjguiMonotonicMicros();
    CjguiEnsureNativeTextViewCaretLayout(textView);
    *outSelectionLayoutMicros = CjguiMonotonicMicros() - selectionStarted;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_measurement_failures(uint64_t session, uint32_t failureCount) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    ctx.forcedComposableMeasurementFailures = failureCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_scene_node_failures(uint64_t session, uint32_t failureCount) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    ctx.forcedComposableSceneNodeFailures = failureCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_present_failures(uint64_t session, uint32_t failureCount) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    ctx.forcedComposablePresentFailures = failureCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_text_preparation_failures(uint64_t session, uint32_t failureCount) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    ctx.forcedComposableTextPreparationFailures = failureCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_preparation_failures_remaining(uint64_t session,
                                                                             uint32_t *outFailureCount) {
    if (!outFailureCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outFailureCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outFailureCount = ctx.forcedComposableTextPreparationFailures;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_scene_version(uint64_t session, uint64_t *outSceneVersion) {
    if (!outSceneVersion) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSceneVersion = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outSceneVersion = ctx.composableSceneVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_resource_stats(uint64_t session, uint32_t nodeIndex,
                                                             uint64_t *outByteCount, float *outX, float *outY,
                                                             float *outWidth, float *outHeight) {
    if (!outByteCount || !outX || !outY || !outWidth || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outByteCount = 0; *outX = 0.0f; *outY = 0.0f; *outWidth = 0.0f; *outHeight = 0.0f;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || nodeIndex >= ctx.composableNodes.count) return ctx ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    NSRect rect = node.textTextureRect;
    *outByteCount = node.textTextureByteCount;
    *outX = (float)NSMinX(rect); *outY = (float)NSMinY(rect);
    *outWidth = (float)NSWidth(rect); *outHeight = (float)NSHeight(rect);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_text_resource_state(uint64_t session,
                                                                    uint8_t *outFailed,
                                                                    uint32_t *outRetryCount) {
    if (!outFailed || !outRetryCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outFailed = 0; *outRetryCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    *outFailed = overlay.activeTextTexturePreparationFailed ? 1 : 0;
    *outRetryCount = overlay.activeTextTextureRetryCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_invalidate_composable_drawable(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_invalidate_composable_drawable(session);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    [ctx.view invalidateBridgeResources];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_request_composable_drawable_pixel(uint64_t session, uint32_t pointX, uint32_t pointY) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed || pointX >= (uint32_t)MAX(0.0, ctx.view.bounds.size.width) ||
        pointY >= (uint32_t)MAX(0.0, ctx.view.bounds.size.height)) {
        return ctx ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    ctx.testDrawablePixelX = pointX;
    ctx.testDrawablePixelY = pointY;
    ctx.testDrawablePixelCompleted = NO;
    ctx.testDrawablePixelPending = YES;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_drawable_pixel(uint64_t session, uint8_t *outBlue, uint8_t *outGreen,
                                                        uint8_t *outRed, uint8_t *outAlpha) {
    if (!outBlue || !outGreen || !outRed || !outAlpha) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outBlue = 0; *outGreen = 0; *outRed = 0; *outAlpha = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.testDrawablePixelCompleted) {
        return ctx ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    *outBlue = ctx.testDrawablePixelBlue;
    *outGreen = ctx.testDrawablePixelGreen;
    *outRed = ctx.testDrawablePixelRed;
    *outAlpha = ctx.testDrawablePixelAlpha;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_encoder_stats(uint64_t session,
                                                       uint32_t *outShapeNodeCount,
                                                       uint32_t *outShapeBatchCount,
                                                       uint32_t *outTextureDrawCount,
                                                       uint64_t *outShapeVertexBytes) {
    if (!outShapeNodeCount || !outShapeBatchCount || !outTextureDrawCount || !outShapeVertexBytes) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outShapeNodeCount = 0; *outShapeBatchCount = 0; *outTextureDrawCount = 0; *outShapeVertexBytes = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outShapeNodeCount = ctx.view.testComposableShapeNodeCount;
    *outShapeBatchCount = ctx.view.testComposableShapeBatchCount;
    *outTextureDrawCount = ctx.view.testComposableTextureDrawCount;
    *outShapeVertexBytes = ctx.view.testComposableShapeVertexBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_encoder_batch_stats(uint64_t session,
                                                             uint32_t *outVertexStride,
                                                             uint64_t *outMaxShapeBatchVertexBytes) {
    if (!outVertexStride || !outMaxShapeBatchVertexBytes) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outVertexStride = 0;
    *outMaxShapeBatchVertexBytes = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outVertexStride = ctx.view.testComposableShapeVertexStride;
    *outMaxShapeBatchVertexBytes = ctx.view.testComposableMaxShapeBatchVertexBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_encoder_cpu_stats(uint64_t session,
                                                           uint64_t *outEncodeMicros) {
    if (!outEncodeMicros) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outEncodeMicros = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outEncodeMicros = ctx.view.testComposableEncoderCpuMicros;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_shape_submission_mode(uint64_t session,
                                                                    uint8_t mode) {
    if (mode > 1) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    ctx.view.testComposableShapeSubmissionMode = mode;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_active_text_resource_preparation_state(uint64_t session,
                                                                                 uint8_t *outScheduled,
                                                                                 uint8_t *outFailed,
                                                                                 uint32_t *outRetryCount) {
    if (!outScheduled || !outFailed || !outRetryCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outScheduled = 0; *outFailed = 0; *outRetryCount = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    *outScheduled = overlay.activeTextResourcePreparationScheduled ? 1 : 0;
    *outFailed = overlay.activeTextTexturePreparationFailed ? 1 : 0;
    *outRetryCount = overlay.activeTextTextureRetryCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_work_stats(uint64_t session,
                                                         uint64_t *outRasterCount, uint64_t *outRasterBytes,
                                                         uint64_t *outRasterMicros, uint64_t *outUploadCount,
                                                         uint64_t *outUploadBytes, uint64_t *outUploadMicros) {
    if (!outRasterCount || !outRasterBytes || !outRasterMicros || !outUploadCount || !outUploadBytes || !outUploadMicros) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outRasterCount = 0; *outRasterBytes = 0; *outRasterMicros = 0;
    *outUploadCount = 0; *outUploadBytes = 0; *outUploadMicros = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    *outRasterCount = ctx.view.testComposableTextRasterCount;
    *outRasterBytes = ctx.view.testComposableTextRasterBytes;
    *outRasterMicros = ctx.view.testComposableTextRasterMicros;
    *outUploadCount = ctx.view.testComposableTextUploadCount;
    *outUploadBytes = ctx.view.testComposableTextUploadBytes;
    *outUploadMicros = ctx.view.testComposableTextUploadMicros;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_work_reason_stats(
    uint64_t session,
    uint64_t *outUnknownRaster, uint64_t *outStaticCandidateRaster,
    uint64_t *outActiveContentRaster, uint64_t *outSelectionCaretRaster,
    uint64_t *outVisibleTileScrollRaster, uint64_t *outRetryRaster,
    uint64_t *outUnknownUpload, uint64_t *outStaticCandidateUpload,
    uint64_t *outActiveContentUpload, uint64_t *outSelectionCaretUpload,
    uint64_t *outVisibleTileScrollUpload, uint64_t *outRetryUpload,
    uint64_t *outLastProjectionVersion, uint64_t *outLastContentUtf8Bytes) {
    uint64_t *raster[] = { outUnknownRaster, outStaticCandidateRaster, outActiveContentRaster,
                           outSelectionCaretRaster, outVisibleTileScrollRaster, outRetryRaster };
    uint64_t *upload[] = { outUnknownUpload, outStaticCandidateUpload, outActiveContentUpload,
                           outSelectionCaretUpload, outVisibleTileScrollUpload, outRetryUpload };
    for (uint32_t index = 0; index < CjguiInternalTextWorkReasonCount; index++) {
        if (!raster[index] || !upload[index]) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        *raster[index] = 0; *upload[index] = 0;
    }
    if (!outLastProjectionVersion || !outLastContentUtf8Bytes) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outLastProjectionVersion = 0; *outLastContentUtf8Bytes = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.destroyed) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    for (uint32_t index = 0; index < CjguiInternalTextWorkReasonCount; index++) {
        *raster[index] = ctx.view.testComposableTextWorkReasonCounters.raster[index];
        *upload[index] = ctx.view.testComposableTextWorkReasonCounters.upload[index];
    }
    *outLastProjectionVersion = ctx.view.testComposableTextLastProjectionVersion;
    *outLastContentUtf8Bytes = ctx.view.testComposableTextLastContentUtf8Bytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_proxy_opacity(uint64_t session,
                                                                 float *outScrollAlpha,
                                                                 float *outTextAlpha) {
    if (!outScrollAlpha || !outTextAlpha) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outScrollAlpha = 0.0f; *outTextAlpha = 0.0f;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_composable_multiline_proxy_opacity(session, outScrollAlpha, outTextAlpha);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *active = nil;
    for (CJGuiInternalComposableSceneNode *node in ctx.composableNodes) {
        if (node.node.nodeId == overlay.activeNodeId && node.index == overlay.activeNodeIndex &&
            node.node.resourceId == overlay.activeNodeResourceId && node.node.nodeKind == overlay.activeNodeKind &&
            node.node.projectionVersion == overlay.activeProjectionVersion) {
            active = node; break;
        }
    }
    if (!active || active.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outScrollAlpha = overlay.inputScrollProxy.alphaValue;
    *outTextAlpha = overlay.inputProxy.alphaValue;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_scroll_composable_multiline(uint64_t session,
                                                          float deltaY,
                                                          float *outScrollOffset,
                                                          uint32_t *outVisibleGlyphCount) {
    if (!outScrollOffset || !outVisibleGlyphCount) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outScrollOffset = 0.0f; *outVisibleGlyphCount = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_scroll_composable_multiline(
                session, deltaY, outScrollOffset, outVisibleGlyphCount);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *active = nil;
    for (CJGuiInternalComposableSceneNode *node in ctx.composableNodes) {
        if (node.node.nodeId == overlay.activeNodeId && node.index == overlay.activeNodeIndex &&
            node.node.resourceId == overlay.activeNodeResourceId && node.node.nodeKind == overlay.activeNodeKind &&
            node.node.projectionVersion == overlay.activeProjectionVersion) {
            active = node; break;
        }
    }
    if (!active || active.node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    [overlay scrollActiveMultiline:active deltaY:deltaY];
    [overlay positionInputProxyForNode:active];
    NSLayoutManager *layoutManager = overlay.inputProxy.layoutManager;
    NSTextContainer *container = overlay.inputProxy.textContainer;
    NSRect contentRect = NSInsetRect(CjguiComposableRect(active, overlay), 7.0, 6.0);
    NSRect visibleRect = NSMakeRect(0.0, overlay.multilineScrollOffset, NSWidth(contentRect), NSHeight(contentRect));
    [overlay ensureActiveLayoutForBoundingRect:visibleRect container:container layoutManager:layoutManager];
    NSRange visible = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:visibleRect inTextContainer:container];
    *outScrollOffset = (float)overlay.multilineScrollOffset;
    *outVisibleGlyphCount = visible.location == NSNotFound ? 0u : (uint32_t)MIN(UINT32_MAX, visible.length);
    return *outVisibleGlyphCount > 0 ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_enqueue_composable_event(uint64_t session, uint32_t nodeIndex, uint32_t eventKind, const char *text) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || nodeIndex >= ctx.composableNodes.count) return ctx ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (eventKind < CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE || eventKind > CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return CjguiEnqueueComposableInteraction(ctx, eventKind, nodeIndex,
                                             text ? [NSString stringWithUTF8String:text] : @"", NSMakeRange(0, 0))
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_send_composable_pointer(uint64_t session, uint32_t phase, float pointX, float pointY) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (!isfinite(pointX) || !isfinite(pointY)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    NSPoint point = NSMakePoint(pointX, pointY);
    if (phase == 1) {
        CJGuiInternalComposableSceneNode *node = [overlay nodeAtPoint:point];
        return node && [overlay beginPointerCaptureForNode:node atPoint:point]
            ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (phase == 2) {
        return [overlay updatePointerCaptureAtPoint:point]
            ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (phase == 3 || phase == 4) {
        if (!overlay.pointerCaptureActive) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        [overlay endPointerCaptureAtPoint:point cancelled:phase == 4];
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_edit_composable_text(uint64_t session, uint32_t nodeIndex, const char *text) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0 || node.node.isReadOnly != 0 ||
        (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    NSString *committed = text ? [NSString stringWithUTF8String:text] : @"";
    if (!committed) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (overlay.activeNodeId != node.node.nodeId || overlay.activeNodeResourceId != node.node.resourceId ||
        overlay.activeNodeKind != node.node.nodeKind) {
        [overlay mouseDownForNode:node];
    }
    overlay.inputProxy.selectedRange = NSMakeRange(0, overlay.inputProxy.string.length);
    [overlay.inputProxy insertText:committed replacementRange:NSMakeRange(NSNotFound, 0)];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_text_matches(uint64_t session, const char *expected) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSString *expectedValue = expected ? [NSString stringWithUTF8String:expected] : @"";
    if (!expectedValue || !ctx.composableSceneOverlay.inputProxy) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return [ctx.composableSceneOverlay.inputProxy.string isEqualToString:expectedValue]
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_fallback_runs(uint64_t session,
                                                                 uint32_t *outExpectedFallbackRuns,
                                                                 uint32_t *outMismatchedRuns) {
    if (!outExpectedFallbackRuns || !outMismatchedRuns) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outExpectedFallbackRuns = 0;
    *outMismatchedRuns = 0;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalComposableSceneOverlay *overlay = ctx ? ctx.composableSceneOverlay : nil;
    if (!overlay || overlay.activeNodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT ||
        !overlay.activeTextBaseFont || !overlay.inputProxy) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSTextStorage *storage = overlay.inputProxy.textStorage;
    NSString *value = storage.string ?: @"";
    if (value.length == 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSFont *baseFont = overlay.activeTextBaseFont;
    uint64_t expectedFallbackRuns = 0;
    uint64_t mismatchedRuns = 0;
    for (NSUInteger location = 0; location < value.length;) {
        NSRange range = [value rangeOfComposedCharacterSequenceAtIndex:location];
        CTFontRef expected = CTFontCreateForString((__bridge CTFontRef)baseFont,
                                                   (__bridge CFStringRef)value,
                                                   CFRangeMake(range.location, range.length));
        NSFont *actual = [storage attribute:NSFontAttributeName atIndex:range.location effectiveRange:NULL];
        if (!expected || !actual) {
            mismatchedRuns += 1;
        } else {
            NSFont *resolved = (__bridge NSFont *)expected;
            if (![resolved isEqual:baseFont]) expectedFallbackRuns += 1;
            if (![resolved isEqual:actual]) mismatchedRuns += 1;
        }
        if (expected) CFRelease(expected);
        location = NSMaxRange(range);
    }
    *outExpectedFallbackRuns = (uint32_t)MIN(expectedFallbackRuns, UINT32_MAX);
    *outMismatchedRuns = (uint32_t)MIN(mismatchedRuns, UINT32_MAX);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_insert_composable_text(uint64_t session, uint32_t nodeIndex, const char *text) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0 || node.node.isReadOnly != 0 ||
        (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    NSString *committed = text ? [NSString stringWithUTF8String:text] : @"";
    if (!committed) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (overlay.activeNodeId != node.node.nodeId || overlay.activeNodeResourceId != node.node.resourceId ||
        overlay.activeNodeKind != node.node.nodeKind) {
        [overlay mouseDownForNode:node];
    }
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableTextDelegateMicros = 0;
    ctx.testComposableSelectionDelegateMicros = 0;
    ctx.testComposableEventEnqueueMicros = 0;
    ctx.testComposableAccessibilityMicros = 0;
    uint64_t started = CjguiMonotonicMicros();
#endif
    [overlay.inputProxy insertText:committed replacementRange:NSMakeRange(NSNotFound, 0)];
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableInputMutationMicros = CjguiMonotonicMicros() - started;
#endif
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_delete_composable_text(uint64_t session, uint32_t nodeIndex) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0 || node.node.isReadOnly != 0 ||
        (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (overlay.activeNodeId != node.node.nodeId || overlay.activeNodeResourceId != node.node.resourceId ||
        overlay.activeNodeKind != node.node.nodeKind) {
        [overlay mouseDownForNode:node];
    }
    if (overlay.inputProxy.selectedRange.location == 0 && overlay.inputProxy.selectedRange.length == 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableTextDelegateMicros = 0;
    ctx.testComposableSelectionDelegateMicros = 0;
    ctx.testComposableEventEnqueueMicros = 0;
    ctx.testComposableAccessibilityMicros = 0;
    uint64_t started = CjguiMonotonicMicros();
#endif
    [overlay.inputProxy deleteBackward:nil];
#ifdef CJGUI_INTERNAL_TESTING
    ctx.testComposableInputMutationMicros = CjguiMonotonicMicros() - started;
#endif
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_marked_text(uint64_t session, uint32_t nodeIndex, const char *text) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0 || node.node.isReadOnly != 0 ||
        (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    NSString *marked = text ? [NSString stringWithUTF8String:text] : @"";
    if (!marked) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    [overlay mouseDownForNode:node];
    [overlay.inputProxy setMarkedText:marked
                        selectedRange:NSMakeRange(marked.length, 0)
                     replacementRange:NSMakeRange(NSNotFound, 0)];
    return overlay.inputProxy.hasMarkedText ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_commit_composable_marked_text(uint64_t session, const char *text) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSString *committed = text ? [NSString stringWithUTF8String:text] : @"";
    if (!committed || !ctx.composableSceneOverlay.inputProxy.hasMarkedText) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    [ctx.composableSceneOverlay.inputProxy insertText:committed replacementRange:NSMakeRange(NSNotFound, 0)];
    return ctx.composableSceneOverlay.inputProxy.hasMarkedText ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_press_composable_node(uint64_t session, uint32_t nodeIndex) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    if (node.node.isInteractive == 0 || node.node.isReadOnly != 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    [ctx.composableSceneOverlay mouseDownForNode:node];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_set_composable_selection(uint64_t session, uint32_t nodeIndex,
                                                       uint32_t selectionStart, uint32_t selectionEnd) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0 ||
        (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    if (overlay.activeNodeId != node.node.nodeId || overlay.activeNodeIndex != node.index ||
        overlay.activeNodeResourceId != node.node.resourceId || overlay.activeNodeKind != node.node.nodeKind ||
        overlay.activeProjectionVersion != node.node.projectionVersion) {
        [overlay mouseDownForNode:node];
    }
    overlay.inputProxy.selectedRange = CjguiComposedSelection(overlay.inputProxy.string,
                                                                selectionStart, selectionEnd);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_drag_composable_text_selection(uint64_t session, uint32_t nodeIndex,
                                                             float startX, float startY, float endX, float endY,
                                                             uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    if (!outSelectionStart || !outSelectionEnd) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outSelectionStart = 0; *outSelectionEnd = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_drag_composable_text_selection(
                session, nodeIndex, startX, startY, endX, endY, outSelectionStart, outSelectionEnd);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || !ctx.window || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneNode *node = ctx.composableNodes[nodeIndex];
    uint32_t kind = node.node.nodeKind;
    if (node.node.isInteractive == 0 || node.node.isReadOnly != 0 ||
        (kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT &&
         kind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    NSEvent *down = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                        location:NSMakePoint(startX, startY)
                                   modifierFlags:0 timestamp:0.0 windowNumber:ctx.window.windowNumber
                                        context:nil eventNumber:1 clickCount:1 pressure:1.0];
    NSEvent *drag = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDragged
                                        location:NSMakePoint(endX, endY)
                                   modifierFlags:0 timestamp:0.01 windowNumber:ctx.window.windowNumber
                                        context:nil eventNumber:1 clickCount:1 pressure:1.0];
    NSEvent *up = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
                                      location:NSMakePoint(endX, endY)
                                 modifierFlags:0 timestamp:0.02 windowNumber:ctx.window.windowNumber
                                      context:nil eventNumber:1 clickCount:1 pressure:0.0];
    if (!down || !drag || !up) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    [overlay mouseDown:down]; [overlay mouseDragged:drag]; [overlay mouseUp:up];
    *outSelectionStart = (uint32_t)MIN(overlay.inputProxy.selectedRange.location, UINT32_MAX);
    *outSelectionEnd = (uint32_t)MIN(NSMaxRange(overlay.inputProxy.selectedRange), UINT32_MAX);
    return *outSelectionEnd > *outSelectionStart ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_send_composable_key(uint64_t session, uint16_t keyCode,
                                                  uint64_t modifiers, uint64_t *outFocusedNodeId) {
    if (!outFocusedNodeId) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outFocusedNodeId = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_send_composable_key(session, keyCode, modifiers, outFocusedNodeId);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || !ctx.window) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    NSString *characters = keyCode == 48 ? @"\t" : (keyCode == 49 ? @" " : (keyCode == 1 ? @"s" :
        (keyCode == 40 ? @"k" : (keyCode == 0 ? @"a" : (keyCode == 51 ? @"\b" :
        (keyCode == 53 ? @"\033" : @"\r"))))));
    NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
                                 modifierFlags:(NSEventModifierFlags)modifiers timestamp:0.0
                                      windowNumber:ctx.window.windowNumber context:nil characters:characters
                         charactersIgnoringModifiers:characters isARepeat:NO keyCode:keyCode];
    if (!event) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSResponder *responder = ctx.window.firstResponder;
    if (responder == ctx.composableSceneOverlay.inputProxy) [ctx.composableSceneOverlay.inputProxy keyDown:event];
    else [ctx.composableSceneOverlay keyDown:event];
    *outFocusedNodeId = ctx.composableSceneOverlay.activeNodeId;
    return *outFocusedNodeId == 0 ? CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR : CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_dispatch_composable_key_through_application(
    uint64_t session, uint16_t keyCode, uint64_t modifiers, uint64_t *outFocusedNodeId,
    uint32_t *outRouteFlags) {
    if (!outFocusedNodeId || !outRouteFlags) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outFocusedNodeId = 0;
    *outRouteFlags = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_dispatch_composable_key_through_application(
                session, keyCode, modifiers, outFocusedNodeId, outRouteFlags);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || !ctx.window || !ctx.app) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    // Bit 0: session application exists; 1: target is key; 2: app key window
    // is target; 3: target responder is the composable overlay; 4: that
    // overlay received the event from NSApplication dispatch.
    *outRouteFlags |= 1u;
    if (ctx.window.isKeyWindow) *outRouteFlags |= 2u;
    if (ctx.app.keyWindow == ctx.window) *outRouteFlags |= 4u;
    if (ctx.window.firstResponder == ctx.composableSceneOverlay) *outRouteFlags |= 8u;
    unichar arrow = keyCode == 123 ? NSLeftArrowFunctionKey :
        (keyCode == 124 ? NSRightArrowFunctionKey :
         (keyCode == 126 ? NSUpArrowFunctionKey : NSDownArrowFunctionKey));
    NSString *characters = [NSString stringWithCharacters:&arrow length:1];
    NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
                                 modifierFlags:(NSEventModifierFlags)modifiers timestamp:0.0
                                      windowNumber:ctx.window.windowNumber context:nil characters:characters
                         charactersIgnoringModifiers:characters isARepeat:NO keyCode:keyCode];
    if (!event) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
#ifdef CJGUI_INTERNAL_TESTING
    uint64_t receiptsBefore = ctx.composableSceneOverlay.testKeyDownReceiptCount;
#endif
    [ctx.app sendEvent:event];
#ifdef CJGUI_INTERNAL_TESTING
    if (ctx.composableSceneOverlay.testKeyDownReceiptCount > receiptsBefore) *outRouteFlags |= 16u;
#endif
    *outFocusedNodeId = ctx.composableSceneOverlay.activeNodeId;
    return (*outRouteFlags & 16u) != 0 && *outFocusedNodeId != 0 ?
        CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_capture_composable_accessibility_action(uint64_t session, uint32_t nodeIndex) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_capture_composable_accessibility_action(session, nodeIndex);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || nodeIndex >= ctx.composableNodes.count) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
#ifdef CJGUI_INTERNAL_TESTING
    CJGuiInternalComposableAccessibilityAction *action =
        [ctx.composableSceneOverlay accessibilityActionForNode:ctx.composableNodes[nodeIndex]];
    if (!action) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    ctx.testCapturedComposableAccessibilityAction = action;
    return CJGUI_INTERNAL_RENDERER_OK;
#else
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
#endif
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
#ifdef CJGUI_INTERNAL_TESTING
    CJGuiInternalComposableAccessibilityAction *action = ctx.testCapturedComposableAccessibilityAction;
    if (!action) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return [action accessibilityPerformPress] ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
#else
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
#endif
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_click_composable_point(uint64_t session, float pointX, float pointY) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_click_composable_point(session, pointX, pointY);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    NSPoint point = NSMakePoint(pointX, pointY);
    CJGuiInternalComposableSceneNode *node = [overlay nodeAtPoint:point];
    if (!node) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    [overlay mouseDownForNode:node atPoint:point];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_resize_composable_window(uint64_t session, uint64_t *outResizeVersion) {
    if (!outResizeVersion) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outResizeVersion = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_resize_composable_window(session, outResizeVersion);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.window || !ctx.view) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    const uint64_t before = ctx.resizeVersion;
    NSSize current = ctx.window.contentView.bounds.size;
    // NSWindow delivers its normal did-resize delegate notification
    // synchronously for this AppKit content-size change. Do not manufacture a
    // revision here: the test must fail if the ordinary callback did not run.
    [ctx.window setContentSize:NSMakeSize(MAX(200.0, current.width + 17.0),
                                          MAX(160.0, current.height + 11.0))];
    if (ctx.resizeVersion <= before) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outResizeVersion = ctx.resizeVersion;
    return CJGUI_INTERNAL_RENDERER_OK;
}

#ifdef CJGUI_INTERNAL_TESTING
CjguiInternalRendererStatus
cjgui_internal_renderer_test_toggle_composable_backing_scale(
    uint64_t session, uint64_t *outResizeVersion,
    double *outBeforeScale, double *outAfterScale,
    uint32_t *outDrawableWidth, uint32_t *outDrawableHeight) {
    if (!outResizeVersion || !outBeforeScale || !outAfterScale || !outDrawableWidth || !outDrawableHeight) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outResizeVersion = 0; *outBeforeScale = 0.0; *outAfterScale = 0.0;
    *outDrawableWidth = 0; *outDrawableHeight = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_toggle_composable_backing_scale(
                session, outResizeVersion, outBeforeScale, outAfterScale, outDrawableWidth, outDrawableHeight);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.window || !ctx.view || ctx.destroyed) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    const uint64_t beforeRevision = ctx.resizeVersion;
    const NSSize beforePointSize = ctx.view.bounds.size;
    const CGFloat beforeScale = [ctx.view currentBackingScale];
    ctx.view.testBackingScaleOverride = beforeScale > 1.5 ? 1.0 : 2.0;
    // Do not call the session handler directly: this posts the same AppKit
    // notification production receives after a backing-properties change.
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidChangeBackingPropertiesNotification
                                                        object:ctx.window];
    const CGFloat afterScale = [ctx.view currentBackingScale];
    const CGSize drawable = ctx.view.metalLayer.drawableSize;
    const NSSize afterPointSize = ctx.view.bounds.size;
    if (ctx.resizeVersion <= beforeRevision || beforeScale <= 0.0 || afterScale <= 0.0 ||
        beforeScale == afterScale || !NSEqualSizes(beforePointSize, afterPointSize) ||
        drawable.width <= 0.0 || drawable.height <= 0.0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outResizeVersion = ctx.resizeVersion;
    *outBeforeScale = beforeScale;
    *outAfterScale = afterScale;
    *outDrawableWidth = (uint32_t)drawable.width;
    *outDrawableHeight = (uint32_t)drawable.height;
    return CJGUI_INTERNAL_RENDERER_OK;
}
#endif

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_standard_editing_commands(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_composable_standard_editing_commands(session);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || !ctx.window) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableInputProxy *input = (CJGuiInternalComposableInputProxy *)ctx.composableSceneOverlay.inputProxy;
    if (!input || ctx.window.firstResponder != input || input.selectedRange.length == 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    NSMutableArray<NSPasteboardItem *> *savedItems = [NSMutableArray array];
    for (NSPasteboardItem *item in pasteboard.pasteboardItems ?: @[]) {
        NSPasteboardItem *copy = [[NSPasteboardItem alloc] init];
        for (NSPasteboardType type in item.types) {
            NSData *data = [item dataForType:type];
            if (data) [copy setData:data forType:type];
        }
        [savedItems addObject:copy];
    }
    NSString *before = [input.string copy] ?: @"";
    CjguiInternalRendererStatus result = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSInteger expectedPasteboardChangeCount = pasteboard.changeCount;
    @try {
        NSEvent *(^commandEvent)(uint16_t, NSString *) = ^NSEvent *(uint16_t keyCode, NSString *characters) {
            return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
                                modifierFlags:NSEventModifierFlagCommand timestamp:0.0
                                 windowNumber:ctx.window.windowNumber context:nil characters:characters
                    charactersIgnoringModifiers:characters isARepeat:NO keyCode:keyCode];
        };
        NSEvent *copyEvent = commandEvent(8, @"c");
        if (!copyEvent) return result;
        [input keyDown:copyEvent];
        expectedPasteboardChangeCount = pasteboard.changeCount;
        NSString *copied = [pasteboard stringForType:NSPasteboardTypeString];
        if (![copied isEqualToString:before]) return result;
        NSEvent *cutEvent = commandEvent(7, @"x");
        if (!cutEvent) return result;
        [input keyDown:cutEvent];
        expectedPasteboardChangeCount = pasteboard.changeCount;
        if (input.string.length != 0) return result;
        NSString *temporaryPaste = @"cjgui-standard-editing-probe";
        [pasteboard clearContents];
        [pasteboard setString:temporaryPaste forType:NSPasteboardTypeString];
        expectedPasteboardChangeCount = pasteboard.changeCount;
        NSEvent *pasteEvent = commandEvent(9, @"v");
        if (!pasteEvent) return result;
        [input keyDown:pasteEvent];
        if (![input.string isEqualToString:temporaryPaste]) return result;
        // Command navigation is not a window command either. This must take
        // NSTextView's normal key-binding path after the explicit A/C/X/V
        // handling above, rather than being swallowed by the scene overlay.
        input.selectedRange = NSMakeRange(input.string.length, 0);
        unichar leftCharacter = NSLeftArrowFunctionKey;
        NSEvent *commandLeft = commandEvent(123, [NSString stringWithCharacters:&leftCharacter length:1]);
        if (!commandLeft) return result;
        [input keyDown:commandLeft];
        if (input.selectedRange.location != 0 || input.selectedRange.length != 0) return result;
        result = CJGUI_INTERNAL_RENDERER_OK;
    } @finally {
        // Do not overwrite a newer clipboard update made outside this short,
        // synchronous probe. The usual path restores every prior item/type.
        if (pasteboard.changeCount == expectedPasteboardChangeCount) {
            [pasteboard clearContents];
            if (savedItems.count > 0) [pasteboard writeObjects:savedItems];
        }
    }
    return result;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_candidate_rect(uint64_t session, uint32_t location, uint32_t length,
                                                        float *outX, float *outY, float *outWidth, float *outHeight) {
    if (!outX || !outY || !outWidth || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outX = 0.0f; *outY = 0.0f; *outWidth = 0.0f; *outHeight = 0.0f;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_composable_candidate_rect(
                session, location, length, outX, outY, outWidth, outHeight);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay || !ctx.window) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *active = [overlay activeFocusableNode];
    if (!active) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    NSRange actual = NSMakeRange(0, 0);
    NSRect candidate = [overlay.inputProxy firstRectForCharacterRange:NSMakeRange(location, length) actualRange:&actual];
    NSRect nodeInWindow = [overlay convertRect:CjguiComposableRect(active, overlay) toView:nil];
    NSRect nodeOnScreen = [ctx.window convertRectToScreen:nodeInWindow];
    if (NSIsEmptyRect(candidate) || !NSIntersectsRect(candidate, nodeOnScreen)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outX = (float)NSMinX(candidate); *outY = (float)NSMinY(candidate);
    *outWidth = (float)NSWidth(candidate); *outHeight = (float)NSHeight(candidate);
    return actual.location <= location ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_test_composable_multiline_layout_ownership(uint64_t session,
                                                                     uint32_t *outInactiveCacheEntries,
                                                                     uint32_t *outInactiveCacheHighWater,
                                                                     uint64_t *outBuildsAfterFirstPass,
                                                                     uint64_t *outBuildsAfterSecondPass) {
    if (!outInactiveCacheEntries || !outInactiveCacheHighWater || !outBuildsAfterFirstPass || !outBuildsAfterSecondPass) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outInactiveCacheEntries = 0; *outInactiveCacheHighWater = 0; *outBuildsAfterFirstPass = 0; *outBuildsAfterSecondPass = 0;
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_test_composable_multiline_layout_ownership(
                session, outInactiveCacheEntries, outInactiveCacheHighWater, outBuildsAfterFirstPass, outBuildsAfterSecondPass);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.composableSceneOverlay) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
    BOOL hasInactiveMultiline = NO;
    for (CJGuiInternalComposableSceneNode *node in overlay.nodes) {
        if (node.node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT &&
            !(node.node.nodeId == overlay.activeNodeId && node.node.resourceId == overlay.activeNodeResourceId &&
              node.node.nodeKind == overlay.activeNodeKind)) {
            hasInactiveMultiline = YES; break;
        }
    }
    if (!hasInactiveMultiline) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    [overlay setNeedsDisplay:YES];
    [overlay displayIfNeeded];
    *outBuildsAfterFirstPass = overlay.multilineLayoutBuildCount;
    [overlay setNeedsDisplay:YES];
    [overlay displayIfNeeded];
    *outBuildsAfterSecondPass = overlay.multilineLayoutBuildCount;
    *outInactiveCacheEntries = (uint32_t)MIN(overlay.multilineLayoutCache.count, UINT32_MAX);
    *outInactiveCacheHighWater = overlay.multilineLayoutCacheHighWater;
    return *outInactiveCacheEntries == 0 && *outInactiveCacheHighWater == 0 &&
        *outBuildsAfterSecondPass == *outBuildsAfterFirstPass
        ? CJGUI_INTERNAL_RENDERER_OK : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}
#endif

// ---- ABI: legacy shared-operation projection ----

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_operation(uint64_t session,
                                                   uint32_t visibleRecordCount) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_configure_shared_operation(session, visibleRecordCount);
        });
        return status;
    }
    if (visibleRecordCount == 0 || visibleRecordCount > 8) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }

    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.view.invalidated) {
        return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED
                   : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }

    CJGuiInternalSharedOperationOverlay *overlay = ctx.sharedOperationOverlay;
    if (!overlay) {
        overlay = [[CJGuiInternalSharedOperationOverlay alloc] initWithFrame:ctx.view.bounds
                                                                       session:ctx];
        if (!overlay) {
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        overlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [ctx.view addSubview:overlay];
        ctx.sharedOperationOverlay = overlay;
        [ctx.window makeFirstResponder:overlay];
    }
    [overlay setRecordCountForProjection:visibleRecordCount];
    CjguiInternalRendererSharedOperationState initialState = {0};
    initialState.selectedRecordIndex = UINT32_MAX;
    initialState.recordCount = visibleRecordCount;
    initialState.viewportStart = 0;
    initialState.totalRecordCount = visibleRecordCount;
    [overlay setProjectionState:initialState];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_operation_title(uint64_t session,
                                                    uint32_t recordIndex,
                                                    const char *title) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_set_shared_operation_title(session, recordIndex, title);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (!ctx.sharedOperationOverlay || recordIndex >= ctx.sharedOperationOverlay.recordCount) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    NSString *copiedTitle = title ? [NSString stringWithUTF8String:title] : nil;
    [ctx.sharedOperationOverlay setTitle:copiedTitle atIndex:recordIndex];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_operation_state(
    uint64_t session,
    const CjguiInternalRendererSharedOperationState *state) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_set_shared_operation_state(session, state);
        });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (!ctx.sharedOperationOverlay || !state ||
        state->recordCount != ctx.sharedOperationOverlay.recordCount ||
        state->totalRecordCount < state->recordCount ||
        state->totalRecordCount == 0 ||
        state->viewportStart > state->totalRecordCount - state->recordCount ||
        state->selectedRecordIndex != UINT32_MAX &&
            state->selectedRecordIndex >= state->recordCount) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    [ctx.sharedOperationOverlay setProjectionState:*state];
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus CjguiConfigureSharedFormOnMain(uint64_t session, uint32_t fieldCount) {
    if (fieldCount == 0 || fieldCount > 8) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || ctx.view.invalidated) return ctx ? CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED : CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalSharedEditingFormOverlay *overlay = ctx.sharedEditingFormOverlay;
    if (!overlay) {
        overlay = [[CJGuiInternalSharedEditingFormOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
        if (!overlay) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        overlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [ctx.view addSubview:overlay];
        ctx.sharedEditingFormOverlay = overlay;
    }
    [ctx.window setTitle:@"CJGUI Shared Editing Form"];
    [overlay setFieldCountForProjection:fieldCount];
    [overlay setCollectionEnabled:NO visibleRecordCount:0];
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus CjguiConfigureSharedCollectionFormOnMain(uint64_t session, uint32_t fieldCount, uint32_t visibleRecordCount) {
    if (visibleRecordCount > 8) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererStatus status = CjguiConfigureSharedFormOnMain(session, fieldCount);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    CJGuiInternalSharedEditingFormOverlay *overlay = ctx.sharedEditingFormOverlay;
    [ctx.window setTitle:@"CJGUI Collection Editor"];
    [overlay setCollectionEnabled:YES visibleRecordCount:visibleRecordCount];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_form(uint64_t session, uint32_t fieldCount) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = CjguiConfigureSharedFormOnMain(session, fieldCount); });
        return status;
    }
    return CjguiConfigureSharedFormOnMain(session, fieldCount);
}

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_collection_form(
    uint64_t session, uint32_t fieldCount, uint32_t visibleRecordCount) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = CjguiConfigureSharedCollectionFormOnMain(session, fieldCount, visibleRecordCount); });
        return status;
    }
    return CjguiConfigureSharedCollectionFormOnMain(session, fieldCount, visibleRecordCount);
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_collection_row(
    uint64_t session, uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = cjgui_internal_renderer_set_shared_collection_row(session, rowIndex, title, isSelected, viewportStart, totalRecordCount); });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalSharedEditingFormOverlay *overlay = ctx.sharedEditingFormOverlay;
    if (!overlay || !overlay.collectionEnabled || rowIndex >= overlay.collectionRowCount || totalRecordCount < overlay.collectionRowCount || viewportStart > totalRecordCount - overlay.collectionRowCount) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    NSString *copiedTitle = title ? [NSString stringWithUTF8String:title] : @"未命名记录";
    [overlay setCollectionRowAtIndex:rowIndex title:copiedTitle selected:isSelected != 0 viewportStart:viewportStart totalRecordCount:totalRecordCount];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_collection_filter(uint64_t session, const char *filterText) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = cjgui_internal_renderer_set_shared_collection_filter(session, filterText); });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalSharedEditingFormOverlay *overlay = ctx.sharedEditingFormOverlay;
    if (!overlay || !overlay.collectionEnabled) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    [overlay setCollectionFilter:(filterText ? [NSString stringWithUTF8String:filterText] : @"")];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_form_field(
    uint64_t session, uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = cjgui_internal_renderer_set_shared_form_field(session, fieldIndex, label, draftText, validationError, editorKind, isFocused, selectionStart, selectionEnd); });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CJGuiInternalSharedEditingFormOverlay *overlay = ctx.sharedEditingFormOverlay;
    if (!overlay || fieldIndex >= overlay.fieldCount) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    NSString *copiedLabel = label ? [NSString stringWithUTF8String:label] : @"字段";
    NSString *copiedDraft = draftText ? [NSString stringWithUTF8String:draftText] : @"";
    NSString *copiedError = validationError ? [NSString stringWithUTF8String:validationError] : @"";
    [overlay setFieldAtIndex:fieldIndex label:copiedLabel draftText:copiedDraft error:copiedError editorKind:editorKind focused:isFocused != 0 selectionStart:selectionStart selectionEnd:selectionEnd];
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_form_status(uint64_t session, const char *statusText) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{ status = cjgui_internal_renderer_set_shared_form_status(session, statusText); });
        return status;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!ctx.sharedEditingFormOverlay) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    [ctx.sharedEditingFormOverlay setStatus:(statusText ? [NSString stringWithUTF8String:statusText] : @"")];
    return CJGUI_INTERNAL_RENDERER_OK;
}

// Cangjie converts the returned CString after a cross-thread foreign call
// returns. NSString.UTF8String is not a suitable borrowed ABI value across
// that boundary, so retain a NUL-terminated byte copy on the session instead.
static NSData *CjguiStableUtf8CString(NSString *text) {
    NSData *encoded = [(text ?: @"") dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *stable = [NSMutableData dataWithCapacity:encoded.length + 1];
    [stable appendData:encoded];
    const uint8_t terminator = 0;
    [stable appendBytes:&terminator length:1];
    return [stable copy];
}

const char *cjgui_internal_renderer_form_event_text(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) return "";
        __block const char *text = "";
        dispatch_sync(dispatch_get_main_queue(), ^{ text = cjgui_internal_renderer_form_event_text(session); });
        return text;
    }
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    NSData *stable = ctx.pumpedFormTextUtf8;
    return stable.length > 0 ? stable.bytes : "";
}

#ifdef CJGUI_INTERNAL_TESTING
// Kept out of the production header/ABI. The focused probe uses this seam to
// prove ordering independently of accessibility or desktop automation.
int cjgui_internal_renderer_test_enqueue_form_event(
    uint64_t session, uint32_t kind, uint32_t fieldIndex, const char *text,
    uint32_t selectionStart, uint32_t selectionEnd) {
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.sharedEditingFormOverlay ||
        fieldIndex >= ctx.sharedEditingFormOverlay.fieldCount) {
        return 0;
    }
    return CjguiEnqueueInteraction(
        ctx, kind, fieldIndex, text ? [NSString stringWithUTF8String:text] : @"",
        selectionStart, selectionEnd) ? 1 : 0;
}
#endif

CjguiInternalRendererStatus
cjgui_internal_renderer_pump_event(uint64_t session,
                                   uint32_t timeoutMs,
                                   CjguiInternalRendererEvent *outEvent) {
    if (outEvent) {
        memset(outEvent, 0, sizeof(CjguiInternalRendererEvent));
        outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_NONE;
    }
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_pump_event(session, timeoutMs, outEvent);
        });
        return status;
    }

    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }

    NSTimeInterval timeoutSeconds = (NSTimeInterval)timeoutMs / 1000.0;
    if (timeoutSeconds > kCjguiPumpTimeoutMaxSeconds) {
        timeoutSeconds = kCjguiPumpTimeoutMaxSeconds;
    }
    if (timeoutSeconds < 0) {
        timeoutSeconds = 0;
    }

    // A Cangjie UI task can run directly on the macOS process main thread.
    // Return an already-queued owner event first: waiting for a new AppKit
    // event here would add the full idle interval to input that the native
    // bridge has already accepted.  Keep the FIFO itself below so this does
    // not alter target identity or close semantics.  With no owner-visible
    // event, this remains the single bounded AppKit acquisition point.
    BOOL hasImmediateOwnerEvent = outEvent &&
        (ctx.pendingInteractions.count > 0 || ctx.pendingInputQueueFullNotice || ctx.closeRequested);
    if (CjguiIsMainThread() && !hasImmediateOwnerEvent) {
        NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSeconds];
        // Do not use an unbounded AppKit loop here: the Cangjie owner must
        // regain control after at most the requested pump interval to apply
        // intent and project the real shared state.
        NSEvent *event = [ctx.app nextEventMatchingMask:NSEventMaskAny
                                              untilDate:untilDate
                                                 inMode:NSDefaultRunLoopMode
                                                dequeue:YES];
        if (event) {
            [ctx.app sendEvent:event];
        }
    }

    // Refresh window content if size changed during the pump.
    if (ctx.window) {
        [ctx.view updateDrawableSize];
    }

    if (outEvent && ctx.pendingInteractions.count > 0) {
        CJGuiInternalQueuedInteraction *interaction = ctx.pendingInteractions.firstObject;
        [ctx.pendingInteractions removeObjectAtIndex:0];
        outEvent->kind = interaction.kind;
        outEvent->recordIndex = interaction.recordIndex;
        outEvent->selectionStart = interaction.selectionStart;
        outEvent->selectionEnd = interaction.selectionEnd;
        outEvent->nodeId = interaction.nodeId;
        outEvent->projectionVersion = interaction.projectionVersion;
        outEvent->resourceId = interaction.resourceId;
        outEvent->nodeKind = interaction.nodeKind;
        outEvent->pointerX = interaction.pointerX;
        outEvent->pointerY = interaction.pointerY;
#ifdef CJGUI_INTERNAL_TESTING
        ctx.testComposableLastPumpedKind = interaction.kind;
        ctx.testComposableLastPumpedNodeId = interaction.nodeId;
        ctx.testComposableLastPumpedProjectionVersion = interaction.projectionVersion;
#endif
        ctx.pumpedFormText = interaction.formText ?: @"";
        ctx.pumpedFormTextUtf8 = CjguiStableUtf8CString(ctx.pumpedFormText);
    } else if (outEvent && ctx.pendingInputQueueFullNotice) {
        ctx.pendingInputQueueFullNotice = NO;
        ctx.pumpedFormText = @"";
        ctx.pumpedFormTextUtf8 = CjguiStableUtf8CString(@"");
        outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_INPUT_QUEUE_FULL;
    } else if (outEvent && ctx.closeRequested) {
        ctx.pumpedFormText = @"";
        ctx.pumpedFormTextUtf8 = CjguiStableUtf8CString(@"");
        outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_CLOSE_REQUESTED;
    }

    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---- ABI: requestClose ----

CjguiInternalRendererStatus
cjgui_internal_renderer_request_close(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_request_close(session);
        });
        return status;
    }

    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }

    NSLog(@"cjgui: post close request: probe");
    if (!ctx.closeRequested) {
        ctx.closeRequested = YES;
        NSLog(@"cjgui: close requested: probe");
    }
    NSLog(@"cjgui: main-thread drain");

    if (ctx.window) {
        [ctx.window close];
    }

    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---- ABI: destroy ----

CjguiInternalRendererStatus
cjgui_internal_renderer_destroy(uint64_t session) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        }
        __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD;
        dispatch_sync(dispatch_get_main_queue(), ^{
            status = cjgui_internal_renderer_destroy(session);
        });
        return status;
    }

    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx) {
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    if (ctx.destroyed) {
        // Double destroy: release the slot but signal invalid.
        CjguiReleaseSession(session);
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }

    ctx.destroyed = YES;

    if (ctx.view) {
        [ctx.sharedOperationOverlay removeFromSuperview];
        ctx.sharedOperationOverlay = nil;
        [ctx.sharedEditingFormOverlay removeFromSuperview];
        ctx.sharedEditingFormOverlay = nil;
        [ctx.view invalidateBridgeResources];
    }
    if (ctx.window) {
        [[NSNotificationCenter defaultCenter] removeObserver:ctx
                                                        name:NSWindowDidChangeBackingPropertiesNotification
                                                      object:ctx.window];
        [ctx.window setDelegate:nil];
        objc_setAssociatedObject(ctx.window, &CJGuiSessionWindowAssociationKey, nil,
                                 OBJC_ASSOCIATION_ASSIGN);
        if (ctx.window.isVisible) {
            [ctx.window close];
        }
        [ctx.window setContentView:nil];
    }

    ctx.view = nil;
    [ctx.composableNodes removeAllObjects];
    [ctx.stagedComposableNodes removeAllObjects];
    [ctx.composableImageTextureCache removeAllObjects];
    [ctx.composableImageResources removeAllObjects];
    [ctx.composableImageLoaders removeAllObjects];
    [ctx.composableImagePendingKeys removeAllObjects];
    ctx.window = nil;
    ctx.commandQueue = nil;
    ctx.device = nil;
    ctx.app = nil;

    CjguiReleaseSession(session);
    NSLog(@"cjgui: destroy complete");
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---- ABI: occupiedSessionCount ----

uint32_t cjgui_internal_renderer_occupied_session_count(void) {
    if (!CjguiIsMainThread()) {
        if (!gCjguiMainThreadDispatchEnabled) {
            return 0;
        }
        __block uint32_t count = 0;
        dispatch_sync(dispatch_get_main_queue(), ^{
            count = cjgui_internal_renderer_occupied_session_count();
        });
        return count;
    }
    uint32_t count = 0;
    for (NSUInteger i = 0; i < kCjguiSessionCapacity; i++) {
        if (gCjguiSessionOccupied[i]) {
            count++;
        }
    }
    return count;
}
