// Focused native regression probe for the custom shared-operation
// accessibility children. This is deliberately outside the public Cangjie
// surface: it verifies the actual AppKit elements exported by the renderer.

#import <Cocoa/Cocoa.h>
#include <stdio.h>

#include "../native/cjgui_internal_renderer.h"

static int fail(uint64_t session, const char *message) {
    fprintf(stderr, "cjgui accessibility probe: %s\n", message);
    if (session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        (void)cjgui_internal_renderer_destroy(session);
    }
    return 1;
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {
            .windowWidth = 720,
            .windowHeight = 420,
            .clearColorRed = 0.94,
            .clearColorGreen = 0.95,
            .clearColorBlue = 0.97,
            .clearColorAlpha = 1.0,
        };
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK ||
            session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            return fail(session, "cannot create session");
        }
        if (cjgui_internal_renderer_configure_shared_operation(session, 3) !=
            CJGUI_INTERNAL_RENDERER_OK) {
            return fail(session, "cannot configure shared operation");
        }

        NSWindow *window = NSApp.windows.lastObject;
        NSView *overlay = window.contentView.subviews.lastObject;
        NSArray<id> *actions = [overlay accessibilityChildren];
        if (actions.count != 6) {
            return fail(session, "shared-operation accessibility child count is not six");
        }
        for (id action in actions) {
            BOOL enabled = [action isAccessibilityEnabled];
            printf("cjgui accessibility probe: enabled=%s\n", enabled ? "true" : "false");
            if (!enabled) {
                return fail(session, "shared-operation action is disabled");
            }
        }

        if (cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail(CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN, "cannot destroy session");
        }
        printf("cjgui accessibility probe: success=true\n");
        return 0;
    }
}
