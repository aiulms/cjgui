// Controlled native NSEvent/CGEvent ingress; no event is posted to a GUI.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>

static NSEvent *event_with_nonce(BOOL wheel, int64_t nonce) {
    CGEventRef cg = wheel ? CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, -120) :
        CGEventCreateKeyboardEvent(NULL, 0, true);
    assert(cg);
    CGEventSetIntegerValueField(cg, kCGEventSourceUserData, nonce);
    NSEvent *event = [NSEvent eventWithCGEvent:cg];
    CFRelease(cg);
    assert(event);
    return event;
}
int main(int argc, const char **argv) {
    @autoreleasepool {
        setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
        setenv("CJGUI_INPUT_LINK_TRACE", "1", 1);
        setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
        setenv("CJGUI_OWNER_TRACE_TARGET_RAW", "0", 1);
        setenv("CJGUI_OWNER_TRACE_TARGET_SESSION", "1", 1);
        setenv("CJGUI_OWNER_TRACE_TARGET_GENERATION", "19", 1);
        setenv("CJGUI_OWNER_TRACE_TARGET_EVENT_USERDATA", "1464355889", 1);
        cjgui_internal_renderer_owner_trace_set_turn(1);
        cjgui_internal_renderer_owner_trace_boundary(0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0, 0, 0, UINT64_MAX);
        BOOL noMatch = argc > 1 && strcmp(argv[1], "no-match") == 0;
        CJGuiInternalSession *ctx = [CJGuiInternalSession new];
        ctx.rendererSessionToken = 1; ctx.sessionGeneration = 19;
        for (unsigned i = 0; i < 94; i++) {
            CjguiInternalInputTrace t = CjguiInputTraceEvent(ctx, event_with_nonce(YES, 1), 3);
            assert(t.rawId == i + 1 && !cjgui_internal_renderer_owner_trace_target_selected_raw(1, 19));
        }
        ctx.rendererSessionToken = 2;
        assert(CjguiInputTraceEvent(ctx, event_with_nonce(YES, 1464355889), 3).rawId == 95);
        ctx.rendererSessionToken = 1; ctx.sessionGeneration = 20;
        assert(CjguiInputTraceEvent(ctx, event_with_nonce(YES, 1464355889), 3).rawId == 96);
        ctx.sessionGeneration = 19;
        assert(CjguiInputTraceEvent(ctx, event_with_nonce(NO, 1464355889), 1).rawId == 97);
        assert(!cjgui_internal_renderer_owner_trace_target_selected_raw(1, 19));
        if (noMatch) {
            fprintf(stderr, "TARGET_NONCE no_match=1 preceding_raws=97 selected=0\n");
            return cjgui_internal_renderer_finalize_owner_trace() == 2 ? 0 : 1;
        }
        NSEvent *event = event_with_nonce(YES, 1464355889);
        CjguiInternalInputTrace selected = CjguiInputTraceEvent(ctx, event, 3);
        assert(selected.rawId == 98 && selected.receivedNs != 0);
        assert(cjgui_internal_renderer_owner_trace_target_selected_raw(1, 19) == 98);
        assert(!cjgui_internal_renderer_owner_trace_target_selected_raw(1, 20));
        assert(CjguiInputTraceEvent(ctx, event, 3).rawId == 0); // same NSEvent replay
        CjguiInternalInputTrace duplicate = CjguiInputTraceEvent(ctx, event_with_nonce(YES, 1464355889), 3);
        assert(duplicate.rawId == 99 && cjgui_internal_renderer_owner_trace_target_selected_raw(1, 19) == 98);
        cjgui_internal_renderer_owner_trace_set_turn(1);
        cjgui_internal_renderer_owner_trace_boundary(0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN, 0, 0, 0, UINT64_MAX);
        cjgui_internal_renderer_owner_trace_target_begin(1, 19, 99, duplicate.receivedNs);
        assert(atomic_load(&gCjguiOwnerTraceTargetState) == 0);
        cjgui_internal_renderer_owner_trace_target_begin(1, 19, 98, selected.receivedNs);
        assert(atomic_load(&gCjguiOwnerTraceTargetState) == 1);
        cjgui_internal_renderer_owner_trace_target_bind(1, 19, 5);
        cjgui_internal_renderer_owner_trace_target_accepted(1, 19, 5, 14, 14);
        cjgui_internal_renderer_owner_trace_boundary(0, 1, CJGUI_OWNER_PHASE_OWNER_OUTER_END, 0, 0, 0, UINT64_MAX);
        assert(atomic_load(&gCjguiOwnerTraceTargetState) == 4);
        fprintf(stderr, "TARGET_NONCE matched_raw=98 duplicate_raw=99 selected_once=1\n");
        return cjgui_internal_renderer_finalize_owner_trace() == 2 ? 0 : 1;
    }
}
