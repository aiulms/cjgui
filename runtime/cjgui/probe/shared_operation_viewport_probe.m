// Focused native regression for bounded shared-operation viewports. The
// renderer receives only eight visible rows while projection metadata records
// the application total and stable viewport offset. It must emit browsing
// intent instead of treating scrolling as a list mutation.

#import <Cocoa/Cocoa.h>
#include <stdio.h>

#include "../native/cjgui_internal_renderer.h"

static int fail(uint64_t session, const char *message) {
    fprintf(stderr, "cjgui viewport probe: %s\n", message);
    if (session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
        (void)cjgui_internal_renderer_destroy(session);
    }
    return 1;
}

static NSEvent *key_event(unsigned short keyCode) {
    return [NSEvent keyEventWithType:NSEventTypeKeyDown
                            location:NSZeroPoint
                       modifierFlags:0
                           timestamp:0
                        windowNumber:NSApp.windows.lastObject.windowNumber
                             context:nil
                          characters:@""
         charactersIgnoringModifiers:@""
                           isARepeat:NO
                             keyCode:keyCode];
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
            session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION) {
            return fail(session, "cannot create session");
        }
        if (cjgui_internal_renderer_configure_shared_operation(session, 8) !=
            CJGUI_INTERNAL_RENDERER_OK) {
            return fail(session, "cannot configure eight visible rows");
        }

        CjguiInternalRendererSharedOperationState state = {0};
        state.selectedRecordId = -1;
        state.selectedRecordIndex = UINT32_MAX;
        state.recordCount = 8;
        state.viewportStart = 93;
        state.totalRecordCount = 101;
        if (cjgui_internal_renderer_set_shared_operation_state(session, &state) !=
            CJGUI_INTERNAL_RENDERER_OK) {
            return fail(session, "cannot project final viewport of a 101-record list");
        }

        state.viewportStart = 94;
        if (cjgui_internal_renderer_set_shared_operation_state(session, &state) !=
            CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED) {
            return fail(session, "accepted a viewport beyond the application record count");
        }

        NSWindow *window = NSApp.windows.lastObject;
        NSView *overlay = window.contentView.subviews.lastObject;
        NSEvent *pageDown = key_event(121);
        if (!overlay || !pageDown) {
            return fail(session, "cannot create viewport input event");
        }
        [overlay keyDown:pageDown];

        CjguiInternalRendererEvent event = {0};
        if (cjgui_internal_renderer_pump_event(session, 0, &event) !=
            CJGUI_INTERNAL_RENDERER_OK ||
            event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_NEXT) {
            return fail(session, "page-down did not return a viewport-next intent");
        }

        NSEvent *pageUp = key_event(116);
        [overlay keyDown:pageUp];
        if (cjgui_internal_renderer_pump_event(session, 0, &event) !=
            CJGUI_INTERNAL_RENDERER_OK ||
            event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_VIEWPORT_PREVIOUS) {
            return fail(session, "page-up did not return a viewport-previous intent");
        }

        if (cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail(CJGUI_INTERNAL_RENDERER_INVALID_SESSION, "cannot destroy session");
        }
        printf("cjgui viewport probe: total=101 visible=8 final_start=93\n");
        printf("cjgui viewport probe: scroll_intents=true\n");
        printf("cjgui viewport probe: success=true\n");
        return 0;
    }
}
