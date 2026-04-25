#import "cjgui_macos.h"

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>
#include <stdlib.h>

typedef enum CJGuiErrorCode {
    CJGUI_STATUS_OK = 0,
    CJGUI_ERROR_NOT_MAIN_THREAD = 2,
    CJGUI_ERROR_APP_INIT_FAILED = 10,
    CJGUI_ERROR_WINDOW_CREATE_FAILED = 11,
    CJGUI_ERROR_METAL_DEVICE_UNAVAILABLE = 20,
    CJGUI_ERROR_METAL_COMMAND_QUEUE_UNAVAILABLE = 21,
    CJGUI_ERROR_METAL_LAYER_UNAVAILABLE = 22,
    CJGUI_ERROR_METAL_DRAWABLE_UNAVAILABLE = 23,
    CJGUI_ERROR_METAL_COMMAND_BUFFER_UNAVAILABLE = 24,
    CJGUI_ERROR_METAL_ENCODER_UNAVAILABLE = 25,
    CJGUI_ERROR_VIEW_INVALIDATED = 30
} CJGuiErrorCode;

static int32_t gLastErrorCode = CJGUI_STATUS_OK;
static int32_t gLastErrorCategory = CJGUI_ERROR_NONE;
static const char *gLastErrorMessage = "ok";
static char CJGuiBridgeContextAssociationKey;

static void CJGuiSetLastError(int32_t code, CjguiErrorCategory category, const char *message) {
    gLastErrorCode = code;
    gLastErrorCategory = category;
    gLastErrorMessage = message ? message : "unknown error";
}

static int32_t CJGuiFail(int32_t code, CjguiErrorCategory category, const char *message) {
    CJGuiSetLastError(code, category, message);
    fprintf(stderr, "cjgui: error[%d/%d]: %s\n", category, code, gLastErrorMessage);
    return code;
}

int32_t cjgui_last_error_code(void) {
    return gLastErrorCode;
}

int32_t cjgui_last_error_category(void) {
    return gLastErrorCategory;
}

const char *cjgui_last_error_message(void) {
    return gLastErrorMessage;
}

@interface CJGuiMetalView : NSView
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) CAMetalLayer *metalLayer;
@property(nonatomic, assign) BOOL invalidated;
- (instancetype)initWithFrame:(NSRect)frame
                       device:(id<MTLDevice>)device
                 commandQueue:(id<MTLCommandQueue>)commandQueue;
- (BOOL)render;
- (void)invalidateBridgeResources;
@end

@implementation CJGuiMetalView

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
    self.metalLayer.framebufferOnly = YES;
    self.metalLayer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
    self.layer = self.metalLayer;
    [self updateDrawableSize];

    return self;
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self updateDrawableSize];
    [self render];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self updateDrawableSize];

    __weak CJGuiMetalView *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        CJGuiMetalView *view = weakSelf;
        if (view && !view.invalidated) {
            [view render];
        }
    });
}

- (void)updateDrawableSize {
    if (!self.metalLayer || self.invalidated) {
        return;
    }

    CGFloat scale = self.window ? self.window.backingScaleFactor : NSScreen.mainScreen.backingScaleFactor;
    CGSize pointSize = self.bounds.size;
    self.metalLayer.frame = self.bounds;
    self.metalLayer.contentsScale = scale;
    self.metalLayer.drawableSize = CGSizeMake(pointSize.width * scale, pointSize.height * scale);
}

- (BOOL)render {
    if (self.invalidated) {
        CJGuiSetLastError(CJGUI_ERROR_VIEW_INVALIDATED, CJGUI_ERROR_RECOVERABLE, "view is already invalidated");
        return NO;
    }

    if (!self.device || !self.commandQueue || !self.metalLayer) {
        CJGuiSetLastError(CJGUI_ERROR_METAL_LAYER_UNAVAILABLE, CJGUI_ERROR_RECOVERABLE, "metal layer is unavailable");
        return NO;
    }

    [self updateDrawableSize];
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    if (!drawable) {
        CJGuiSetLastError(CJGUI_ERROR_METAL_DRAWABLE_UNAVAILABLE, CJGUI_ERROR_DEGRADED, "metal drawable is temporarily unavailable");
        return NO;
    }

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    if (!commandBuffer) {
        CJGuiSetLastError(CJGUI_ERROR_METAL_COMMAND_BUFFER_UNAVAILABLE, CJGUI_ERROR_RECOVERABLE, "metal command buffer creation failed");
        return NO;
    }

    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = drawable.texture;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0.08, 0.16, 0.20, 1.0);

    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];
    if (!encoder) {
        CJGuiSetLastError(CJGUI_ERROR_METAL_ENCODER_UNAVAILABLE, CJGUI_ERROR_RECOVERABLE, "metal render encoder creation failed");
        return NO;
    }

    [encoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    CJGuiSetLastError(CJGUI_STATUS_OK, CJGUI_ERROR_NONE, "ok");
    return YES;
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
}

@end

@interface CJGuiBridgeContext : NSObject <NSWindowDelegate>
@property(nonatomic, strong) NSApplication *app;
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) CJGuiMetalView *view;
@property(nonatomic, assign) BOOL closeRequested;
@property(nonatomic, assign) BOOL destroyed;
- (int32_t)startWithApp:(NSApplication *)app;
- (void)requestCloseWithReason:(const char *)reason;
- (void)destroyIfNeeded;
@end

static void CJGuiStopApp(void) {
    [NSApp stop:nil];
    NSEvent *event = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                        location:NSZeroPoint
                                   modifierFlags:0
                                       timestamp:0
                                    windowNumber:0
                                         context:nil
                                         subtype:0
                                           data1:0
                                           data2:0];
    [NSApp postEvent:event atStart:NO];
}

@implementation CJGuiBridgeContext

- (int32_t)startWithApp:(NSApplication *)app {
    self.app = app;
    NSLog(@"cjgui: bridge init");

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        return CJGuiFail(CJGUI_ERROR_METAL_DEVICE_UNAVAILABLE, CJGUI_ERROR_RECOVERABLE, "default Metal device is unavailable");
    }
    NSLog(@"cjgui: capability check: metal device ok");

    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    if (!commandQueue) {
        return CJGuiFail(CJGUI_ERROR_METAL_COMMAND_QUEUE_UNAVAILABLE, CJGUI_ERROR_RECOVERABLE, "Metal command queue creation failed");
    }
    NSLog(@"cjgui: capability check: command queue ok");

    NSRect frame = NSMakeRect(0, 0, 720, 420);
    NSUInteger style = NSWindowStyleMaskTitled |
                       NSWindowStyleMaskClosable |
                       NSWindowStyleMaskMiniaturizable |
                       NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    if (!self.window) {
        return CJGuiFail(CJGUI_ERROR_WINDOW_CREATE_FAILED, CJGUI_ERROR_RECOVERABLE, "NSWindow creation failed");
    }

    [self.window setReleasedWhenClosed:NO];
    [self.window center];
    [self.window setTitle:@"Cangjie macOS Bridge Smoke"];
    [self.window setDelegate:self];
    objc_setAssociatedObject(self.window, &CJGuiBridgeContextAssociationKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSLog(@"cjgui: window created");

    self.view = [[CJGuiMetalView alloc] initWithFrame:frame device:device commandQueue:commandQueue];
    if (!self.view) {
        return CJGuiFail(CJGUI_ERROR_METAL_LAYER_UNAVAILABLE, CJGUI_ERROR_RECOVERABLE, "CAMetalLayer setup failed");
    }

    [self.window setContentView:self.view];
    NSLog(@"cjgui: metal setup complete");

    [self.window makeKeyAndOrderFront:nil];
    [self.app activateIgnoringOtherApps:YES];

    if (![self.view render]) {
        return CJGuiFail(cjgui_last_error_code(), (CjguiErrorCategory)cjgui_last_error_category(), cjgui_last_error_message());
    }
    NSLog(@"cjgui: first frame rendered");
    return CJGUI_STATUS_OK;
}

- (void)requestCloseWithReason:(const char *)reason {
    if (!self.closeRequested) {
        self.closeRequested = YES;
        NSLog(@"cjgui: close requested: %s", reason ? reason : "unknown");
    }

    if (self.window) {
        [self.window close];
    } else {
        CJGuiStopApp();
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    (void)notification;
    if (!self.closeRequested) {
        self.closeRequested = YES;
        NSLog(@"cjgui: close requested: window");
    }
    NSLog(@"cjgui: window will close");
    CJGuiStopApp();
}

- (void)destroyIfNeeded {
    if (self.destroyed) {
        return;
    }

    self.destroyed = YES;

    if (self.view) {
        [self.view invalidateBridgeResources];
    }

    if (self.window) {
        [self.window setDelegate:nil];
        objc_setAssociatedObject(self.window, &CJGuiBridgeContextAssociationKey, nil, OBJC_ASSOCIATION_ASSIGN);
        if (self.window.isVisible) {
            [self.window close];
        }
        [self.window setContentView:nil];
    }

    self.view = nil;
    self.window = nil;
    self.app = nil;
    NSLog(@"cjgui: destroy complete");
}

@end

int32_t cjgui_app_run(void) {
    @autoreleasepool {
        CJGuiSetLastError(CJGUI_STATUS_OK, CJGUI_ERROR_NONE, "ok");

        if (![NSThread isMainThread]) {
            return CJGuiFail(CJGUI_ERROR_NOT_MAIN_THREAD, CJGUI_ERROR_FATAL, "cjgui_app_run must be called on the main thread");
        }

        NSLog(@"cjgui: starting macOS bridge smoke");

        NSApplication *app = [NSApplication sharedApplication];
        if (!app) {
            return CJGuiFail(CJGUI_ERROR_APP_INIT_FAILED, CJGUI_ERROR_FATAL, "NSApplication sharedApplication failed");
        }
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        CJGuiBridgeContext *context = [[CJGuiBridgeContext alloc] init];
        int32_t startCode = [context startWithApp:app];
        if (startCode != CJGUI_STATUS_OK) {
            [context destroyIfNeeded];
            return startCode;
        }

        const char *autoCloseSeconds = getenv("CJGUI_AUTOCLOSE_SECONDS");
        if (autoCloseSeconds && autoCloseSeconds[0] != '\0') {
            double seconds = atof(autoCloseSeconds);
            if (seconds > 0) {
                __weak CJGuiBridgeContext *weakContext = context;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    CJGuiBridgeContext *strongContext = weakContext;
                    if (!strongContext || strongContext.destroyed) {
                        return;
                    }
                    NSLog(@"cjgui: auto-closing after %.2f seconds", seconds);
                    [strongContext requestCloseWithReason:"auto-close"];
                });
            }
        }

        NSLog(@"cjgui: entering event loop");
        [app run];
        [context destroyIfNeeded];
        NSLog(@"cjgui: event loop exited");
        return CJGUI_STATUS_OK;
    }
}
