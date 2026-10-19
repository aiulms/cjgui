// Small native harness for two session-layer invariants that the window
// consumers cannot observe directly:
//   1. two sessions in one process never write each other's text proxy;
//   2. a full pending queue rejects the new edit before touching the proxy and
//      keeps every already-queued event.
//
// The session keeps these paths static, so the harness compiles the session
// translation unit directly instead of widening the public ABI for tests.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../native/cjgui_linux_session.c"

static int failures = 0;

static void check(int condition, const char *name) {
    printf("HARNESS %s %s\n", condition ? "PASS" : "FAIL", name);
    if (!condition) failures += 1;
}

static void init_proxy(CjguiLinuxSession *session, const char *value, uint64_t nodeId) {
    memset(session, 0, sizeof(*session));
    session->proxy.active = 1;
    session->proxy.nodeId = nodeId;
    session->proxy.resourceId = 102;
    session->proxy.nodeKind = 10;
    session->proxy.sceneVersion = 7;
    session->proxy.value = cjgui_linux_strdup(value);
    uint32_t units = cjgui_linux_utf16_length(value, strlen(value));
    session->proxy.selectionStart16 = units;
    session->proxy.selectionEnd16 = units;
}

static void free_session(CjguiLinuxSession *session) {
    free(session->proxy.value);
    session->proxy.value = NULL;
    for (uint32_t i = 0u; i < CJGUI_LINUX_PENDING_EVENTS; i += 1u) {
        cjgui_linux_strfree(&session->pending[i].rangePreBody);
        cjgui_linux_strfree(&session->pending[i].rangePostBody);
        cjgui_linux_strfree(&session->pending[i].rangeReplacement);
    }
}

static void drain_one_event(CjguiLinuxSession *session) {
    uint32_t index = session->pendingHead;
    cjgui_linux_strfree(&session->pending[index].rangePreBody);
    cjgui_linux_strfree(&session->pending[index].rangePostBody);
    cjgui_linux_strfree(&session->pending[index].rangeReplacement);
    session->pendingHead = (session->pendingHead + 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pendingCount -= 1u;
}

int main(void) {
    // Static, like the production g_sessions table: two 1024-slot scenes per
    // session no longer fit comfortably on the default stack.
    static CjguiLinuxSession a;
    static CjguiLinuxSession b;
    init_proxy(&a, "A", 4u);
    init_proxy(&b, "B", 5u);

    // Same-process isolation: each edit lands on the session that produced it.
    check(cjgui_linux_emit_text_edit(&a, 1u, 0u, "1") == 1, "dual_edit_a_applies");
    check(cjgui_linux_emit_text_edit(&b, 1u, 0u, "2") == 1, "dual_edit_b_applies");
    check(strcmp(a.proxy.value, "A1") == 0, "dual_a_value");
    check(strcmp(b.proxy.value, "B2") == 0, "dual_b_value");
    check(a.pendingCount == 2u && b.pendingCount == 2u, "dual_queue_counts");
    check(a.rangeIntentProduced == 1u && b.rangeIntentProduced == 1u, "dual_intent_counts");

    // Fill A to the 16-event ceiling (8 edits x 2 events). B must stay untouched.
    for (int i = 0; i < 7; i += 1u) {
        uint32_t caret = (uint32_t)strlen(a.proxy.value);
        check(cjgui_linux_emit_text_edit(&a, caret, 0u, "x") == 1, "fill_a_applies");
    }
    check(a.pendingCount == 16u, "fill_a_reaches_capacity");
    char *before = cjgui_linux_strdup(a.proxy.value);
    uint32_t queuedBefore = a.pendingCount;
    uint64_t overflowBefore = a.pendingOverflowCount;
    int applied = cjgui_linux_emit_text_edit(&a, (uint32_t)strlen(a.proxy.value), 0u, "Z");
    check(applied == 0, "full_queue_rejects_new_edit");
    check(strcmp(a.proxy.value, before) == 0, "full_queue_keeps_proxy_value");
    check(a.pendingCount == queuedBefore, "full_queue_keeps_queued_count");
    check(a.pendingOverflowCount == overflowBefore + 1u, "full_queue_counts_overflow");
    check(strcmp(b.proxy.value, "B2") == 0 && b.pendingCount == 2u, "full_queue_leaves_b_alone");

    // One drained slot is still short of the two events one edit needs.
    drain_one_event(&a);
    check(cjgui_linux_emit_text_edit(&a, (uint32_t)strlen(a.proxy.value), 0u, "Q") == 0,
          "one_free_slot_still_rejects");
    check(strcmp(a.proxy.value, before) == 0, "deferred_edit_keeps_proxy_value");
    // Two drained slots let the same edit through.
    drain_one_event(&a);
    check(cjgui_linux_emit_text_edit(&a, (uint32_t)strlen(a.proxy.value), 0u, "Q") == 1,
          "two_free_slots_apply");
    check(strcmp(a.proxy.value, "A1xxxxxxxQ") == 0, "drained_edit_value");

    free(before);
    free_session(&a);
    free_session(&b);

    // Translate is a second, paint-only geometry channel: hit routing and
    // pointer geometry use the visual origin, while layout coordinates stay
    // untouched.
    CjguiLinuxSession *t = (CjguiLinuxSession *)calloc(1u, sizeof(CjguiLinuxSession));
    if (!t || !cjgui_linux_scene_reserve(&t->accepted, 1u)) {
        free(t);
        return 1;
    }
    t->accepted.valid = 1;
    t->accepted.nodeCount = 1;
    CjguiLinuxNodeSlot *slot = &t->accepted.slots[0];
    memset(slot, 0, sizeof(*slot));
    slot->node.nodeId = 77u;
    slot->node.nodeKind = 1u;
    slot->node.x = 10.0;
    slot->node.y = 10.0;
    slot->node.width = 100.0;
    slot->node.height = 50.0;
    slot->node.isInteractive = 1u;
    slot->geometryPresent = 1;
    slot->geometry.translateX = 40.0;
    slot->geometry.translateY = 20.0;
    check(cjgui_linux_hit_test(t, 60.0, 40.0) == slot, "translate_hit_visual_rect");
    check(cjgui_linux_hit_test(t, 15.0, 15.0) == NULL, "translate_misses_layout_origin");
    CjguiInternalRendererPointerEventGeometry pg;
    cjgui_linux_capture_pointer_geometry(t, slot, 60.0, 40.0, &pg);
    check(pg.present == 1u && pg.translateX == 40.0 && pg.translateY == 20.0,
          "translate_pointer_geometry");
    cjgui_linux_scene_reset(&t->accepted);
    free(t);

    // Rectangular clip chain: every ancestor aperture intersects in device
    // pixels; the sidecar's owner translation shifts each constraint; an empty
    // constraint means "no constraint"; a disjoint chain paints nothing; the
    // legacy single clip survives when clipConstraintCount is 0.
    CjguiLinuxNodeSlot clipSlot;
    double left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
    memset(&clipSlot, 0, sizeof(clipSlot));
    clipSlot.node.clip0X = 10; clipSlot.node.clip0Y = 10;
    clipSlot.node.clip0Width = 100; clipSlot.node.clip0Height = 100;
    clipSlot.node.clip1X = 50; clipSlot.node.clip1Y = 50;
    clipSlot.node.clip1Width = 200; clipSlot.node.clip1Height = 200;
    clipSlot.node.clipConstraintCount = 2u;
    check(cjgui_linux_slot_clip_bounds(&clipSlot, 1.0, 640.0, 480.0,
                                       &left, &top, &right, &bottom) == 1 &&
          left == 50.0 && top == 50.0 && right == 110.0 && bottom == 110.0,
          "clip_chain_intersection");
    clipSlot.geometryPresent = 1;
    clipSlot.geometry.clip1X = 5.0;
    clipSlot.geometry.clip1Y = 5.0;
    check(cjgui_linux_slot_clip_bounds(&clipSlot, 1.0, 640.0, 480.0,
                                       &left, &top, &right, &bottom) == 1 &&
          left == 55.0 && top == 55.0 && right == 110.0 && bottom == 110.0,
          "clip_chain_owner_translation");
    clipSlot.geometry.clip1X = 0.0;
    clipSlot.geometry.clip1Y = 0.0;
    clipSlot.node.clip1Width = 0.0;
    check(cjgui_linux_slot_clip_bounds(&clipSlot, 1.0, 640.0, 480.0,
                                       &left, &top, &right, &bottom) == 1 &&
          left == 10.0 && top == 10.0 && right == 110.0 && bottom == 110.0,
          "clip_chain_skips_empty_constraint");
    clipSlot.node.clip1X = 300; clipSlot.node.clip1Y = 300;
    clipSlot.node.clip1Width = 20; clipSlot.node.clip1Height = 20;
    check(cjgui_linux_slot_clip_bounds(&clipSlot, 1.0, 640.0, 480.0,
                                       &left, &top, &right, &bottom) == 0,
          "clip_chain_disjoint_paints_nothing");
    memset(&clipSlot, 0, sizeof(clipSlot));
    clipSlot.node.width = 80; clipSlot.node.height = 40;
    check(cjgui_linux_slot_clip_bounds(&clipSlot, 1.0, 640.0, 480.0,
                                       &left, &top, &right, &bottom) == 1 &&
          left == 0.0 && top == 0.0 && right == 640.0 && bottom == 480.0,
          "clip_legacy_absent_is_drawable");
    clipSlot.node.clipX = 10; clipSlot.node.clipY = 10;
    clipSlot.node.clipWidth = 100; clipSlot.node.clipHeight = 100;
    check(cjgui_linux_slot_clip_bounds(&clipSlot, 2.0, 640.0, 480.0,
                                       &left, &top, &right, &bottom) == 1 &&
          left == 20.0 && top == 20.0 && right == 220.0 && bottom == 220.0,
          "clip_legacy_device_scale");

    printf("HARNESS RESULT %s failures=%d\n", failures == 0 ? "PASS" : "FAIL", failures);
    return failures == 0 ? 0 : 1;
}
