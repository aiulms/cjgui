// The visible shared-form surface is renderer-owned drawing. Cocoa text and
// button controls may be an invisible input/accessibility bridge, but may not
// be the visible form itself.

#import <Cocoa/Cocoa.h>
#include <stdio.h>

#include "../native/cjgui_internal_renderer.h"

static int fail(uint64_t session, const char *message) {
    fprintf(stderr, "cjgui shared form self-draw probe: %s\n", message);
    if (session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
        (void)cjgui_internal_renderer_destroy(session);
    }
    return 1;
}

static BOOL has_visible_cocoa_form_control(NSView *view) {
    if (!view.hidden && ([view isKindOfClass:[NSTextField class]] ||
                         [view isKindOfClass:[NSButton class]])) {
        return YES;
    }
    for (NSView *child in view.subviews) {
        if (has_visible_cocoa_form_control(child)) {
            return YES;
        }
    }
    return NO;
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {
            .windowWidth = 640,
            .windowHeight = 420,
            .clearColorRed = 0.94,
            .clearColorGreen = 0.95,
            .clearColorBlue = 0.97,
            .clearColorAlpha = 1.0,
        };
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK ||
            session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
            return fail(session, "cannot create session");
        }
        if (cjgui_internal_renderer_configure_shared_form(session, 2) !=
            CJGUI_INTERNAL_RENDERER_OK) {
            return fail(session, "cannot configure form");
        }
        if (has_visible_cocoa_form_control(NSApp.windows.lastObject.contentView)) {
            return fail(session, "visible form still delegates drawing to Cocoa controls");
        }
        NSView *overlay = NSApp.windows.lastObject.contentView.subviews.lastObject;
        NSArray<id> *actions = [overlay accessibilityChildren];
        if (actions.count != 4) {
            return fail(session, "self-drawn form did not expose all accessibility actions");
        }
        for (id action in actions) {
            NSRect frame = [action accessibilityFrame];
            if (![action isAccessibilityElement] || NSIsEmptyRect(frame)) {
                return fail(session, "self-drawn form accessibility action has no usable frame");
            }
        }
        if (cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail(CJGUI_INTERNAL_RENDERER_INVALID_SESSION, "cannot destroy session");
        }
    printf("cjgui shared form self-draw probe: visible_cocoa_controls=false\n");
        printf("cjgui shared form self-draw probe: accessibility_frames=true\n");
        printf("cjgui shared form self-draw probe: success=true\n");
        return 0;
    }
}
