// A user close is only a request. The domain must choose whether a document
// with unsaved state is saved, explicitly discarded, or kept open.

#import <Cocoa/Cocoa.h>
#include <stdio.h>

#include "../native/cjgui_internal_renderer.h"

enum { CJGUI_EXPECTED_HUMAN_COLLECTION_CLOSE = 24 };

static int fail(uint64_t session, const char *message) {
    fprintf(stderr, "cjgui collection close probe: %s\n", message);
    if (session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        (void)cjgui_internal_renderer_destroy(session);
    }
    return 1;
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {
            .windowWidth = 640, .windowHeight = 420,
            .clearColorRed = 0.94, .clearColorGreen = 0.95,
            .clearColorBlue = 0.97, .clearColorAlpha = 1.0,
        };
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &status);
        if (status != CJGUI_INTERNAL_RENDERER_OK || session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            return fail(session, "cannot create session");
        }
        if (cjgui_internal_renderer_configure_shared_collection_form(session, 2, 0) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail(session, "cannot configure collection editor");
        }
        NSWindow *window = NSApp.windows.lastObject;
        [window performClose:nil];
        if (!window.isVisible) {
            return fail(session, "window closed before the Cangjie domain decided the unsaved-content outcome");
        }
        CjguiInternalRendererEvent event = {0};
        if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK ||
            event.kind != CJGUI_EXPECTED_HUMAN_COLLECTION_CLOSE) {
            return fail(session, "user close did not become a collection close-request intent");
        }
        if (cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail(CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN, "cannot destroy session");
        }
        printf("cjgui collection close probe: deferred_domain_decision=true\n");
        printf("cjgui collection close probe: success=true\n");
        return 0;
    }
}
