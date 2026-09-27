#import "../native/cjgui_internal_renderer.h"
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

_Static_assert(sizeof(CjguiInternalRendererWindowBackgroundSnapshot) == 72,
               "window background snapshot ABI must remain 72 bytes");

@interface CJWindowMaterialProbeUnderlayView : NSView
@end
@implementation CJWindowMaterialProbeUnderlayView
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [[NSColor colorWithCalibratedRed:0.95 green:0.08 blue:0.10 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width * 0.5, self.bounds.size.height * 0.5));
    [[NSColor colorWithCalibratedRed:0.05 green:0.85 blue:0.20 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(self.bounds.size.width * 0.5, 0, self.bounds.size.width * 0.5, self.bounds.size.height * 0.5));
    [[NSColor colorWithCalibratedRed:0.05 green:0.18 blue:0.96 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(0, self.bounds.size.height * 0.5, self.bounds.size.width * 0.5, self.bounds.size.height * 0.5));
    [[NSColor colorWithCalibratedRed:0.95 green:0.78 blue:0.05 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5,
                          self.bounds.size.width * 0.5, self.bounds.size.height * 0.5));
}
@end

static void fail(const char *message, int code) {
    fprintf(stderr, "window_material_probe FAIL %s code=%d\n", message, code);
    exit(1);
}

static void requireStatus(const char *name, CjguiInternalRendererStatus status) {
    if (status != CJGUI_INTERNAL_RENDERER_OK) fail(name, (int)status);
}

static NSWindow *windowCreatedSince(NSSet<NSWindow *> *before) {
    for (NSWindow *window in NSApp.windows) if (![before containsObject:window]) return window;
    return nil;
}

static NSUInteger countMaterialViews(NSView *root) {
    NSUInteger count = [root isKindOfClass:NSVisualEffectView.class] ? 1 : 0;
    for (NSView *child in root.subviews) count += countMaterialViews(child);
    return count;
}

static BOOL captureWindow(NSWindow *window, const char *name) {
    CGImageRef image = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow,
        (CGWindowID)window.windowNumber, kCGWindowImageBoundsIgnoreFraming);
    if (!image) {
        printf("desktop_composite_capture %s=unavailable\n", name);
        return NO;
    }
    NSString *directory = [NSString stringWithUTF8String:getenv("CJGUI_WINDOW_MATERIAL_OUT_DIR") ?: "/private/tmp"];
    NSString *path = [directory stringByAppendingPathComponent:
        [NSString stringWithFormat:@"window-material-%@.png", [NSString stringWithUTF8String:name]]];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
    NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    BOOL saved = png && [png writeToFile:path atomically:YES];
    printf("desktop_composite_capture %s=%s path=%s pixel=%zux%zu\n", name,
           saved ? "captured" : "save_failed", path.fileSystemRepresentation,
           CGImageGetWidth(image), CGImageGetHeight(image));
    CGImageRelease(image);
    return saved;
}

static BOOL captureDesktopComposite(NSWindow *window, const char *name) {
    NSScreen *screen = window.screen ?: NSScreen.mainScreen;
    NSRect frame = window.frame;
    CGRect captureRect = CGRectMake(frame.origin.x, screen.frame.size.height - NSMaxY(frame),
                                    frame.size.width, frame.size.height);
    CGImageRef image = CGWindowListCreateImage(captureRect, kCGWindowListOptionOnScreenOnly,
                                                kCGNullWindowID, kCGWindowImageBoundsIgnoreFraming);
    if (!image) {
        printf("desktop_composite_region %s=unavailable\n", name);
        return NO;
    }
    NSString *directory = [NSString stringWithUTF8String:getenv("CJGUI_WINDOW_MATERIAL_OUT_DIR") ?: "/private/tmp"];
    NSString *path = [directory stringByAppendingPathComponent:
        [NSString stringWithFormat:@"desktop-composite-%@.png", [NSString stringWithUTF8String:name]]];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
    NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    BOOL saved = png && [png writeToFile:path atomically:YES];
    printf("desktop_composite_region %s=%s path=%s pixels=%zux%zu\n", name,
           saved ? "captured" : "save_failed", path.fileSystemRepresentation,
           CGImageGetWidth(image), CGImageGetHeight(image));
    CGImageRelease(image);
    return saved;
}

static uint64_t monotonicMicros(void) {
    struct timespec value = {0};
    clock_gettime(CLOCK_MONOTONIC, &value);
    return (uint64_t)value.tv_sec * 1000000u + (uint64_t)value.tv_nsec / 1000u;
}

static NSView *firstLayerView(NSView *root, Class cls) {
    if ([root isKindOfClass:cls]) return root;
    for (NSView *child in root.subviews) {
        NSView *found = firstLayerView(child, cls);
        if (found) return found;
    }
    return nil;
}

static NSView *firstMetalLayerView(NSView *root) {
    if ([root.layer isKindOfClass:CAMetalLayer.class]) return root;
    for (NSView *child in root.subviews) {
        NSView *found = firstMetalLayerView(child);
        if (found) return found;
    }
    return nil;
}

static void configureScene(uint64_t session, uint64_t version) {
    requireStatus("configure_scene", cjgui_internal_renderer_configure_composable_scene(session, version, 1));
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = version;
    node.projectionVersion = version;
    node.x = 10; node.y = 10; node.width = 48; node.height = 28;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 320; node.clipHeight = 220;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.fillRed = 0.2; node.fillGreen = 0.4; node.fillBlue = 0.7; node.fillAlpha = 1.0;
    node.textRed = 0.95; node.textGreen = 0.95; node.textBlue = 0.95; node.textAlpha = 1.0;
    node.fontSize = 14.0;
    requireStatus("set_scene_node", cjgui_internal_renderer_set_composable_scene_node(
        session, 0, &node, "material probe", "material probe", "", "", 0));
}

static CjguiInternalRendererWindowBackgroundSnapshot snapshot(uint64_t session) {
    CjguiInternalRendererWindowBackgroundSnapshot value = {0};
    requireStatus("snapshot", cjgui_internal_renderer_window_background_snapshot(session, &value));
    return value;
}

static BOOL appearanceMatches(NSView *view, uint32_t scheme) {
    NSAppearanceName names[] = { NSAppearanceNameAqua, NSAppearanceNameDarkAqua };
    NSAppearanceName match = [view.effectiveAppearance bestMatchFromAppearancesWithNames:
        @[ names[0], names[1] ]];
    return [match isEqualToString:scheme == 1 ? names[0] : names[1]];
}

static uint32_t resolvedScheme(NSAppearance *appearance) {
    NSAppearanceName match = [appearance bestMatchFromAppearancesWithNames:
        @[ NSAppearanceNameAqua, NSAppearanceNameDarkAqua ]];
    return [match isEqualToString:NSAppearanceNameDarkAqua] ? 2u : 1u;
}

static BOOL fallbackMatches(NSView *view, uint32_t scheme) {
    CGColorRef color = view.layer.backgroundColor;
    if (!color || CGColorGetNumberOfComponents(color) < 3) return NO;
    const CGFloat *components = CGColorGetComponents(color);
    CGFloat expected[3] = { scheme == 1 ? 0.94 : 0.08,
                            scheme == 1 ? 0.95 : 0.16,
                            scheme == 1 ? 0.97 : 0.20 };
    for (NSUInteger i = 0; i < 3; ++i) if (fabs(components[i] - expected[i]) > 0.015) return NO;
    return CGColorGetAlpha(color) > 0.99;
}

static void present(uint64_t session, uint64_t version, uint32_t mode, uint32_t scheme,
                    BOOL checkPixel, uint8_t expectedAlpha) {
    requireStatus("stage", cjgui_internal_renderer_stage_window_background(session, version, mode, scheme));
    configureScene(session, version);
    if (checkPixel) requireStatus("pixel_request",
        cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 280, 190));
    CjguiInternalRendererFrameObservation observation = {0};
    uint64_t started = monotonicMicros();
    CjguiInternalRendererStatus status = cjgui_internal_renderer_present_composable_scene(session, &observation);
    if (status != CJGUI_INTERNAL_RENDERER_OK && status != CJGUI_INTERNAL_RENDERER_READBACK_FAILED)
        fail("present", status);
    if (observation.frameIndex == 0) fail("present_frame_missing", 0);
    printf("scene_present mode=%u frame=%llu elapsed_us=%llu\n", mode,
           observation.frameIndex, (unsigned long long)(monotonicMicros() - started));
    if (checkPixel) {
        uint8_t blue = 0, green = 0, red = 0, alpha = 0;
        requireStatus("pixel_read", cjgui_internal_renderer_test_composable_drawable_pixel(
            session, &blue, &green, &red, &alpha));
        if (alpha != expectedAlpha) {
            fprintf(stderr, "window_material_probe pixel BGRA=%u,%u,%u,%u expected_alpha=%u\n",
                    blue, green, red, alpha, expectedAlpha);
            fail("clear_alpha", alpha);
        }
        if (expectedAlpha == 255) {
            uint8_t expectedRed = (uint8_t)lrint((scheme == 1 ? 0.94 : 0.08) * 255.0);
            uint8_t expectedGreen = (uint8_t)lrint((scheme == 1 ? 0.95 : 0.16) * 255.0);
            uint8_t expectedBlue = (uint8_t)lrint((scheme == 1 ? 0.97 : 0.20) * 255.0);
            if (abs((int)red - expectedRed) > 2 || abs((int)green - expectedGreen) > 2 ||
                abs((int)blue - expectedBlue) > 2) {
                fprintf(stderr, "opaque pixel BGRA=%u,%u,%u,%u expected=%u,%u,%u,255\n",
                        blue, green, red, alpha, expectedBlue, expectedGreen, expectedRed);
                fail("clear_scheme_pixel", scheme);
            }
        }
    }
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {0};
        config.windowWidth = 320; config.windowHeight = 220;
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        NSSet<NSWindow *> *beforeA = [NSSet setWithArray:NSApp.windows];
        uint64_t a = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK || !a) fail("create_a", status);
        NSWindow *windowA = windowCreatedSince(beforeA);
        if (!windowA) fail("window_a_missing", 0);
        NSView *fallbackA = windowA.contentView.subviews.firstObject;
        NSView *metalViewA = firstMetalLayerView(windowA.contentView);
        CAMetalLayer *layerA = (CAMetalLayer *)metalViewA.layer;
        if (windowA.isOpaque || !layerA || layerA.opaque || CGColorGetAlpha(layerA.backgroundColor) != 0.0 ||
            !fallbackA.layer.opaque || CGColorGetAlpha(fallbackA.layer.backgroundColor) != 1.0)
            fail("transparent_window_setup", 0);
        if (countMaterialViews(windowA.contentView) != 1 || !fallbackA)
            fail("fixed_host_tree", 0);

        NSWindow *underlayWindow = [[NSWindow alloc] initWithContentRect:windowA.frame
            styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        CJWindowMaterialProbeUnderlayView *underlayView = [[CJWindowMaterialProbeUnderlayView alloc]
            initWithFrame:underlayWindow.contentView.bounds];
        underlayView.wantsLayer = YES;
        underlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        underlayWindow.contentView = underlayView;
        [underlayWindow setFrame:windowA.frame display:YES];
        [underlayWindow orderWindow:NSWindowBelow relativeTo:windowA.windowNumber];
        [windowA makeKeyAndOrderFront:nil];

        CjguiInternalRendererWindowBackgroundSnapshot beforeStage = snapshot(a);
        uint32_t osScheme = resolvedScheme(NSApp.effectiveAppearance);
        uint32_t fixedScheme = osScheme == 1 ? 2 : 1;
        if (cjgui_internal_renderer_stage_window_background(a, 1,
                CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, 0) == CJGUI_INTERNAL_RENDERER_OK)
            fail("invalid_scheme_accepted", 0);
        requireStatus("stage_only", cjgui_internal_renderer_stage_window_background(
            a, 1, CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, fixedScheme));
        CjguiInternalRendererWindowBackgroundSnapshot afterStage = snapshot(a);
        if (memcmp(&beforeStage, &afterStage, sizeof(beforeStage)) != 0 ||
            !((NSVisualEffectView *)firstLayerView(windowA.contentView, NSVisualEffectView.class)).hidden)
            fail("stage_changed_live_host_or_snapshot", 0);
        printf("stage_is_projection_only ok\n");

        requireStatus("set_reduce_false", cjgui_internal_renderer_test_set_window_background_environment(a, 0));
        // The environment setter above only installs a probe override; it must
        // not change the accepted scene or window host before a scene present.
        if (snapshot(a).acceptedSceneVersion != 0) fail("environment_changed_acceptance", 0);
        present(a, 1, CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, fixedScheme, YES, 0);
        CjguiInternalRendererWindowBackgroundSnapshot systemA = snapshot(a);
        NSVisualEffectView *materialA = (NSVisualEffectView *)firstLayerView(windowA.contentView, NSVisualEffectView.class);
        if (systemA.acceptedSceneVersion != 1 || systemA.requestedMode != 1 || systemA.backend != 1 ||
            systemA.actualMode != 1 || systemA.fallbackReason != 1 || systemA.colorScheme != fixedScheme ||
            materialA.hidden || !appearanceMatches(materialA, fixedScheme) || !fallbackMatches(fallbackA, fixedScheme) ||
            materialA.blendingMode != NSVisualEffectBlendingModeBehindWindow ||
            materialA.material != NSVisualEffectMaterialUnderWindowBackground ||
            materialA.state != NSVisualEffectStateFollowsWindowActiveState)
            fail("system_host_installation", systemA.actualMode);
        printf("system_host_and_transparent_clear accepted=%llu frame=%llu\n",
               systemA.acceptedSceneVersion, systemA.frameIndex);
        NSDate *idleDeadline = [NSDate dateWithTimeIntervalSinceNow:0.12];
        [[NSRunLoop mainRunLoop] runUntilDate:idleDeadline];
        uint64_t idleFrameFirst = snapshot(a).frameIndex;
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.12]];
        uint64_t idleFrameSecond = snapshot(a).frameIndex;
        printf("idle_frame_convergence first=%llu second=%llu stable=%u\n",
               idleFrameFirst, idleFrameSecond, idleFrameFirst == idleFrameSecond ? 1u : 0u);
        (void)captureDesktopComposite(windowA, "system_initial");

        NSSize originalContentSize = windowA.contentView.bounds.size;
        [windowA setContentSize:NSMakeSize(originalContentSize.width + 24, originalContentSize.height + 16)];
        [underlayWindow setFrame:windowA.frame display:YES];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        BOOL resizedHost = NSEqualSizes(windowA.contentView.bounds.size, windowA.contentView.subviews.firstObject.frame.size);
        printf("resize_host_autosize=%u content=%0.0fx%0.0f\n", resizedHost ? 1u : 0u,
               windowA.contentView.bounds.size.width, windowA.contentView.bounds.size.height);
        if (!resizedHost) fail("resize_host_autosize", 0);
        CjguiInternalRendererWindowBackgroundSnapshot beforeThemeOnly = snapshot(a);
        present(a, 1, CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, osScheme, YES, 0);
        CjguiInternalRendererWindowBackgroundSnapshot afterThemeOnly = snapshot(a);
        if (afterThemeOnly.acceptedSceneVersion != beforeThemeOnly.acceptedSceneVersion ||
            afterThemeOnly.frameIndex <= beforeThemeOnly.frameIndex ||
            afterThemeOnly.requestRevision != beforeThemeOnly.requestRevision + 1 ||
            afterThemeOnly.colorScheme != osScheme || !appearanceMatches(materialA, osScheme) ||
            !fallbackMatches(fallbackA, osScheme)) fail("theme_only_present", 0);
        (void)captureWindow(windowA, "system_fixed_scheme");
        [NSApp activateIgnoringOtherApps:YES];
        [windowA makeKeyAndOrderFront:nil];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        CjguiInternalRendererWindowBackgroundSnapshot focusedA = snapshot(a);
        printf("focus_theme_state active=%u key=%u app_active=%u env_revision=%llu appearance_follows=%u\n",
               focusedA.windowActive, windowA.isKeyWindow ? 1u : 0u,
               NSApp.isActive ? 1u : 0u, (unsigned long long)focusedA.environmentRevision,
               materialA.state == NSVisualEffectStateFollowsWindowActiveState ? 1u : 0u);
        (void)captureWindow(windowA, "system_default_appearance");
        (void)captureDesktopComposite(windowA, "system_default_appearance");

        requireStatus("stage_failed_candidate", cjgui_internal_renderer_stage_window_background(
            a, 2, CJGUI_INTERNAL_WINDOW_BACKGROUND_OPAQUE, fixedScheme));
        configureScene(a, 2);
        requireStatus("inject_precommit_failure", cjgui_internal_renderer_test_set_composable_present_failures(a, 1));
        CjguiInternalRendererFrameObservation rejectedObservation = {0};
        status = cjgui_internal_renderer_present_composable_scene(a, &rejectedObservation);
        CjguiInternalRendererWindowBackgroundSnapshot afterReject = snapshot(a);
        if (status == CJGUI_INTERNAL_RENDERER_OK || afterReject.acceptedSceneVersion != systemA.acceptedSceneVersion ||
            afterReject.requestedMode != systemA.requestedMode || afterReject.actualMode != systemA.actualMode ||
            afterReject.colorScheme != osScheme || !appearanceMatches(materialA, osScheme) ||
            !fallbackMatches(fallbackA, osScheme) || materialA.hidden || rejectedObservation.frameIndex != 0 ||
            afterReject.frameIndex != afterThemeOnly.frameIndex ||
            afterReject.requestRevision != afterThemeOnly.requestRevision)
            fail("precommit_failure_rollback", status);
        printf("precommit_failure_preserved_scene_and_host ok\n");
        present(a, 2, CJGUI_INTERNAL_WINDOW_BACKGROUND_OPAQUE, fixedScheme, YES, 255);
        CjguiInternalRendererWindowBackgroundSnapshot opaqueA = snapshot(a);
        if (opaqueA.acceptedSceneVersion != 2 || opaqueA.actualMode != 0 || opaqueA.requestedMode != 0 ||
            !materialA.hidden) fail("opaque_transition", opaqueA.actualMode);

        present(a, 3, CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, fixedScheme, YES, 0);
        requireStatus("simulate_reduce_transparency",
            cjgui_internal_renderer_test_set_window_background_environment(a, 1));
        CjguiInternalRendererWindowBackgroundSnapshot reducedA = snapshot(a);
        if (reducedA.reduceTransparency != 1 || reducedA.actualMode != 2 || reducedA.fallbackReason != 2 ||
            !materialA.hidden) fail("reduce_transparency_fallback", reducedA.fallbackReason);
        present(a, 4, CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, osScheme, YES, 255);
        reducedA = snapshot(a);
        if (reducedA.actualMode != 2 || reducedA.fallbackReason != 2 || reducedA.backend != 1 ||
            reducedA.colorScheme != osScheme || !fallbackMatches(fallbackA, osScheme))
            fail("reduce_transparency_represented", reducedA.fallbackReason);
        printf("reduce_transparency_fallback actual=%u reason=%u backend=%u\n",
               reducedA.actualMode, reducedA.fallbackReason, reducedA.backend);
        (void)captureWindow(windowA, "opaque_fallback");
        (void)captureDesktopComposite(windowA, "opaque_fallback");
        uint64_t reducedFrame = reducedA.frameIndex;
        uint64_t reducedEnvironmentRevision = reducedA.environmentRevision;
        requireStatus("simulate_reduce_transparency_recovery",
            cjgui_internal_renderer_test_set_window_background_environment(a, 0));
        CjguiInternalRendererWindowBackgroundSnapshot recoveryRequested = snapshot(a);
        if (recoveryRequested.environmentRevision <= reducedEnvironmentRevision ||
            recoveryRequested.frameIndex != reducedFrame || recoveryRequested.actualMode != 2)
            fail("environment_recovery_did_not_wait_for_present", 0);
        present(a, 4, CJGUI_INTERNAL_WINDOW_BACKGROUND_SYSTEM_CONTENT_AREA, osScheme, YES, 0);
        CjguiInternalRendererWindowBackgroundSnapshot recoveredA = snapshot(a);
        if (recoveredA.acceptedSceneVersion != reducedA.acceptedSceneVersion ||
            recoveredA.frameIndex <= reducedFrame || recoveredA.actualMode != 1 ||
            recoveredA.fallbackReason != 1 || recoveredA.reduceTransparency != 0 ||
            recoveredA.colorScheme != osScheme || !appearanceMatches(materialA, osScheme))
            fail("same_scene_material_recovery", recoveredA.actualMode);
        printf("environment_recovery same_scene=%llu frame=%llu->%llu\n",
               recoveredA.acceptedSceneVersion, reducedFrame, recoveredA.frameIndex);

        NSSet<NSWindow *> *beforeB = [NSSet setWithArray:NSApp.windows];
        uint64_t b = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK || !b || a == b) fail("create_b", status);
        NSWindow *windowB = windowCreatedSince(beforeB);
        if (!windowB || windowB == windowA || countMaterialViews(windowB.contentView) != 1)
            fail("window_b_host", 0);
        CjguiInternalRendererWindowBackgroundSnapshot beforeBPresent = snapshot(b);
        present(b, 1, CJGUI_INTERNAL_WINDOW_BACKGROUND_OPAQUE, osScheme, NO, 255);
        CjguiInternalRendererWindowBackgroundSnapshot afterBPresent = snapshot(b);
        CjguiInternalRendererWindowBackgroundSnapshot stillA = snapshot(a);
        if (afterBPresent.acceptedSceneVersion != 1 || afterBPresent.requestRevision != beforeBPresent.requestRevision ||
            stillA.acceptedSceneVersion != 4 || stillA.actualMode != 1 || stillA.fallbackReason != 1)
            fail("two_window_state_isolation", 0);
        printf("two_window_state_isolation ok\n");

        requireStatus("destroy_a", cjgui_internal_renderer_destroy(a));
        requireStatus("destroy_b", cjgui_internal_renderer_destroy(b));
        [underlayWindow close];
        if (windowA.contentView != nil || windowB.contentView != nil)
            fail("close_cleanup_content_host", 0);
        CjguiInternalRendererWindowBackgroundSnapshot closed = {0};
        status = cjgui_internal_renderer_window_background_snapshot(a, &closed);
        if (status == CJGUI_INTERNAL_RENDERER_OK) fail("closed_session_still_readable", 0);
        printf("close_cleanup ok\nwindow_material_probe PASS\n");
    }
    return 0;
}
