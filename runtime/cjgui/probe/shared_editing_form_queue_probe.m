// Focused regression probe for native shared-form intent ordering.
// It is compiled with CJGUI_INTERNAL_TESTING only; no test entry point is
// part of the production internal renderer ABI.

#import <Cocoa/Cocoa.h>
#include <stdio.h>

#include "../native/cjgui_internal_renderer.h"

#ifndef CJGUI_INTERNAL_TESTING
#error "shared editing form queue probe must be built with CJGUI_INTERNAL_TESTING"
#endif

extern int cjgui_internal_renderer_test_enqueue_form_event(
    uint64_t session,
    uint32_t kind,
    uint32_t field_index,
    const char *text,
    uint32_t selection_start,
    uint32_t selection_end);

static int fail(uint64_t session, const char *message) {
    fprintf(stderr, "cjgui shared form queue probe: %s\n", message);
    if (session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        (void)cjgui_internal_renderer_destroy(session);
    }
    return 1;
}

static int expect_event(uint64_t session, uint32_t kind, uint32_t field_index,
                        const char *text) {
    CjguiInternalRendererEvent event = {0};
    if (cjgui_internal_renderer_pump_event(session, 0, &event) !=
            CJGUI_INTERNAL_RENDERER_OK ||
        event.kind != kind || event.recordIndex != field_index) {
        return 0;
    }
    return strcmp(cjgui_internal_renderer_form_event_text(session), text) == 0;
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
            session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            return fail(session, "cannot create session");
        }
        if (cjgui_internal_renderer_configure_shared_form(session, 2) !=
            CJGUI_INTERNAL_RENDERER_OK) {
            return fail(session, "cannot configure form");
        }

        if (!cjgui_internal_renderer_test_enqueue_form_event(
                session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_FOCUS,
                0, "规则甲", 0, 3) ||
            !cjgui_internal_renderer_test_enqueue_form_event(
                session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED,
                0, "规则甲-已编辑", 3, 7) ||
            !cjgui_internal_renderer_test_enqueue_form_event(
                session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_APPLY,
                0, "", 0, 0)) {
            return fail(session, "cannot enqueue test interactions");
        }

        if (!expect_event(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_FOCUS,
                          0, "规则甲") ||
            !expect_event(session,
                          CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_TEXT_CHANGED,
                          0, "规则甲-已编辑") ||
            !expect_event(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_FORM_APPLY,
                          0, "")) {
            return fail(session, "form intent order or UTF-8 payload was lost");
        }
        if (cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) {
            return fail(CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN, "cannot destroy session");
        }
        printf("cjgui shared form queue probe: focus-text-apply ordering=true\n");
        printf("cjgui shared form queue probe: utf8_payload=true\n");
        printf("cjgui shared form queue probe: success=true\n");
        return 0;
    }
}
