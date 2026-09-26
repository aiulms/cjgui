// labs/macos_bridge_smoke/native/cjgui_macos.m
//
// Backward-compatibility shim. The real renderer implementation now lives in
// the runtime-owned sidecar at
//   runtime/cjgui/native/cjgui_internal_renderer.{h,m}
// This file no longer carries a second renderer copy. It only exposes the
// legacy `cjgui_app_run()` symbol, implemented as a thin driver over the new
// session API:
//   create
//   presentClear x2
//   bounded pump loop (driven here, never [NSApplication run])
//   requestClose
//   destroy
//
// last_error_* helpers are retained because the historical smoke header
// declared them; they stay minimal and compatible.

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "cjgui_macos.h"
#import "cjgui_internal_renderer.h"

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

static int32_t gLastErrorCode = 0;
static int32_t gLastErrorCategory = CJGUI_ERROR_NONE;
static const char *gLastErrorMessage = "ok";

static void CJGuiSetLastError(int32_t code, CjguiErrorCategory category, const char *message) {
    gLastErrorCode = code;
    gLastErrorCategory = category;
    gLastErrorMessage = message ? message : "unknown error";
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

// Legacy compatibility shim implemented over the runtime-owned session API.
int32_t cjgui_app_run(void) {
    @autoreleasepool {
        NSLog(@"cjgui: starting macOS bridge smoke");

        if (![NSThread isMainThread]) {
            CJGuiSetLastError(2, CJGUI_ERROR_FATAL, "cjgui_app_run must be called on the main thread");
            return 2;
        }

        CjguiInternalRendererConfig config;
        memset(&config, 0, sizeof(config));
        config.windowWidth = 720;
        config.windowHeight = 420;
        config.clearColorRed = 0.08;
        config.clearColorGreen = 0.16;
        config.clearColorBlue = 0.20;
        config.clearColorAlpha = 1.0;

        CjguiInternalRendererStatus createStatus = CJGUI_INTERNAL_RENDERER_OK;
        uint64_t session = cjgui_internal_renderer_create(&config, &createStatus);
        if (session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            return (int32_t)createStatus;
        }

        CjguiInternalRendererClearColor color;
        color.red = 0.08;
        color.green = 0.16;
        color.blue = 0.20;
        color.alpha = 1.0;

        CjguiInternalRendererFrameObservation obs1;
        CjguiInternalRendererStatus s1 =
            cjgui_internal_renderer_present_clear(session, &color, &obs1);
        if (s1 != CJGUI_INTERNAL_RENDERER_OK) {
            cjgui_internal_renderer_destroy(session);
            return (int32_t)s1;
        }

        CjguiInternalRendererFrameObservation obs2;
        CjguiInternalRendererStatus s2 =
            cjgui_internal_renderer_present_clear(session, &color, &obs2);
        if (s2 != CJGUI_INTERNAL_RENDERER_OK) {
            cjgui_internal_renderer_destroy(session);
            return (int32_t)s2;
        }

        // Optional auto-close via env var, mirroring the historical smoke.
        const char *autoCloseSeconds = getenv("CJGUI_AUTOCLOSE_SECONDS");
        if (autoCloseSeconds && autoCloseSeconds[0] != '\0') {
            double seconds = atof(autoCloseSeconds);
            if (seconds > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    NSLog(@"cjgui: auto-closing after %.2f seconds", seconds);
                    cjgui_internal_renderer_request_close(session);
                });
            }
        }

        // Bounded pump loop. This shim drives the loop instead of calling
        // [NSApplication run], so control stays with the caller. The loop
        // exits once close has been requested.
        NSLog(@"cjgui: entering event loop");
        for (int i = 0; i < 60000; i++) {
            CjguiInternalRendererEvent event;
            cjgui_internal_renderer_pump_event(session, 16, &event);
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_CLOSE_REQUESTED) {
                break;
            }
        }
        NSLog(@"cjgui: event loop exited");

        cjgui_internal_renderer_request_close(session);
        cjgui_internal_renderer_destroy(session);

        CJGuiSetLastError(0, CJGUI_ERROR_NONE, "ok");
        return 0;
    }
}
