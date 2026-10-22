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

static void harness_focus_node(CjguiLinuxNodeSlot *slot, uint64_t nodeId, int64_t resourceId,
                               uint32_t nodeKind, const char *value, uint32_t readOnly,
                               uint32_t preservesLocal) {
    cjgui_linux_slot_clear(slot);
    slot->node.nodeId = nodeId;
    slot->node.resourceId = resourceId;
    slot->node.nodeKind = nodeKind;
    slot->node.isInteractive = 1u;
    slot->node.isReadOnly = readOnly;
    slot->node.preservesActiveLocalText = preservesLocal;
    slot->value = cjgui_linux_strdup(value);
}

// Keyboard scenarios need real layout rects and scope identity, which the
// focus/owned scenarios above intentionally leave empty.
static void harness_keyboard_node(CjguiLinuxNodeSlot *slot, uint64_t nodeId, int64_t resourceId,
                                  uint32_t nodeKind, const char *value, uint64_t scope,
                                  double y, uint32_t interactive, uint32_t readOnly) {
    harness_focus_node(slot, nodeId, resourceId, nodeKind, value, readOnly, 0u);
    slot->node.inputScope = scope;
    slot->node.x = 0.0;
    slot->node.y = y;
    slot->node.width = 200.0;
    slot->node.height = 30.0;
    slot->node.isInteractive = interactive;
}

static CjguiLinuxWindowEvent harness_key_event(uint32_t keySym, uint32_t keyCode, uint32_t modifiers,
                                               const char *text) {
    CjguiLinuxWindowEvent event;
    memset(&event, 0, sizeof(event));
    event.kind = CJGUI_LINUX_WINDOW_EVENT_KEY_DOWN;
    event.keySym = keySym;
    event.keyCode = keyCode;
    event.modifiers = modifiers;
    if (text && text[0]) {
        size_t length = strlen(text);
        if (length >= sizeof(event.utf8)) length = sizeof(event.utf8) - 1u;
        memcpy(event.utf8, text, length);
        event.utf8[length] = '\0';
        event.utf8Length = (uint32_t)length;
    }
    return event;
}

static void harness_pending_clear(CjguiLinuxSession *session) {
    for (uint32_t i = 0u; i < CJGUI_LINUX_PENDING_EVENTS; i += 1u) {
        cjgui_linux_strfree(&session->pending[i].rangePreBody);
        cjgui_linux_strfree(&session->pending[i].rangePostBody);
        cjgui_linux_strfree(&session->pending[i].rangeReplacement);
    }
    session->pendingHead = 0u;
    session->pendingCount = 0u;
}

static uint32_t harness_pending_kind_count(const CjguiLinuxSession *session, uint32_t kind) {
    uint32_t count = 0u;
    for (uint32_t i = 0u; i < session->pendingCount; i += 1u) {
        uint32_t index = (session->pendingHead + i) % CJGUI_LINUX_PENDING_EVENTS;
        if (session->pending[index].event.kind == kind) count += 1u;
    }
    return count;
}

static int harness_last_event(const CjguiLinuxSession *session, uint32_t kind, uint64_t nodeId,
                              const char *text) {
    if (session->pendingCount == 0u) return 0;
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    if (session->pending[index].event.kind != kind) return 0;
    if (session->pending[index].event.nodeId != nodeId) return 0;
    if (text) {
        if (!session->pending[index].hasText) return 0;
        if (strcmp(session->pending[index].text, text) != 0) return 0;
    }
    return 1;
}

// Barycentric sample of the emitted triangle list at a device point. Returns
// 0 when no emitted triangle covers the point.
static int harness_sample_triangle_color(const CjguiLinuxVertexBuilder *builder,
                                         double x, double y,
                                         double *r, double *g, double *b) {
    for (uint32_t i = 0u; i + 2u < builder->count; i += 3u) {
        const CjguiLinuxGpuVertex *v0 = &builder->vertices[i];
        const CjguiLinuxGpuVertex *v1 = &builder->vertices[i + 1u];
        const CjguiLinuxGpuVertex *v2 = &builder->vertices[i + 2u];
        double denominator = (v1->y - v2->y) * (v0->x - v2->x) +
                             (v2->x - v1->x) * (v0->y - v2->y);
        if (fabs(denominator) < 1e-9) continue;
        double w0 = ((v1->y - v2->y) * (x - v2->x) + (v2->x - v1->x) * (y - v2->y)) / denominator;
        double w1 = ((v2->y - v0->y) * (x - v2->x) + (v0->x - v2->x) * (y - v2->y)) / denominator;
        double w2 = 1.0 - w0 - w1;
        if (w0 < -1e-6 || w1 < -1e-6 || w2 < -1e-6) continue;
        *r = w0 * v0->r + w1 * v1->r + w2 * v2->r;
        *g = w0 * v0->g + w1 * v1->g + w2 * v2->g;
        *b = w0 * v0->b + w1 * v1->b + w2 * v2->b;
        return 1;
    }
    return 0;
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

    // Ordinary focus installs a proxy from the accepted node; switching focus
    // never carries one field's draft into another; accepted commits sync the
    // ordinary proxy and retire it, while owned proxies keep their contract.
    CjguiLinuxSession *f = &g_sessions[0];
    memset(f, 0, sizeof(*f));
    f->alive = 1;
    f->token = 7701u;
    check(cjgui_linux_scene_reserve(&f->accepted, 4u) == 1, "focus_scene_reserve");
    f->accepted.valid = 1;
    f->accepted.nodeCount = 4u;
    f->accepted.projectionVersion = 5u;
    harness_focus_node(&f->accepted.slots[0], 6u, 102,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "left", 0u, 0u);
    harness_focus_node(&f->accepted.slots[1], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "right", 0u, 0u);
    harness_focus_node(&f->accepted.slots[2], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->accepted.slots[3], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    f->accepted.slots[3].node.isInteractive = 0u;

    check(cjgui_internal_renderer_focus_composable_node(f->token, 6u) == CJGUI_INTERNAL_RENDERER_OK,
          "focus_single_line_installs");
    check(f->proxy.active && f->proxy.ordinary && f->proxy.nodeId == 6u &&
          strcmp(f->proxy.value, "left") == 0 && f->proxy.selectionStart16 == 4u,
          "focus_install_reads_accepted_body");
    check(cjgui_internal_renderer_focus_composable_node(f->token, 7u) == CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.ordinary && f->proxy.nodeId == 7u && strcmp(f->proxy.value, "right") == 0 &&
          f->proxy.selectionStart16 == 5u,
          "focus_multiline_installs");
    check(cjgui_internal_renderer_focus_composable_node(f->token, 8u) != CJGUI_INTERNAL_RENDERER_OK,
          "focus_readonly_refused");
    check(cjgui_internal_renderer_focus_composable_node(f->token, 9u) != CJGUI_INTERNAL_RENDERER_OK,
          "focus_noninteractive_refused");
    check(f->proxy.nodeId == 7u && strcmp(f->proxy.value, "right") == 0,
          "focus_refusal_keeps_existing_proxy");

    check(cjgui_internal_renderer_focus_composable_node(f->token, 6u) == CJGUI_INTERNAL_RENDERER_OK &&
          strcmp(f->proxy.value, "left") == 0,
          "focus_switch_restores_accepted_body");
    check(cjgui_linux_emit_text_edit(f, 4u, 0u, "a") == 1, "focus_switch_edit_left_applies");
    check(cjgui_internal_renderer_focus_composable_node(f->token, 7u) == CJGUI_INTERNAL_RENDERER_OK &&
          strcmp(f->proxy.value, "right") == 0,
          "focus_switch_does_not_carry_left_draft");
    check(cjgui_linux_emit_text_edit(f, 5u, 0u, "b") == 1, "focus_switch_edit_right_applies");
    check(strcmp(f->proxy.value, "rightb") == 0, "focus_switch_right_value");
    {
        uint32_t last = (f->pendingHead + f->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
        uint32_t previous = (f->pendingHead + f->pendingCount - 2u) % CJGUI_LINUX_PENDING_EVENTS;
        check(f->pending[last].event.nodeId == 7u && f->pending[previous].event.nodeId == 7u,
              "focus_switch_queues_second_owner");
        check(f->pending[previous].hasText && strcmp(f->pending[previous].text, "rightb") == 0,
              "focus_switch_queues_right_body");
    }

    // Owner commits "L": the ordinary proxy adopts the accepted body and the
    // old caret is clamped. A one-shot local-preservation hint keeps the local
    // body; a commit that drops the node retires the proxy.
    check(cjgui_internal_renderer_focus_composable_node(f->token, 6u) == CJGUI_INTERNAL_RENDERER_OK,
          "focus_commit_target_selected");
    check(cjgui_linux_scene_reserve(&f->candidate, 4u) == 1, "focus_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 4u;
    f->candidate.projectionVersion = 6u;
    harness_focus_node(&f->candidate.slots[0], 6u, 102,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "L", 0u, 0u);
    harness_focus_node(&f->candidate.slots[1], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "right", 0u, 0u);
    harness_focus_node(&f->candidate.slots[2], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[3], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "focus_commit_applies");
    check(f->proxy.active && f->proxy.nodeId == 6u && strcmp(f->proxy.value, "L") == 0 &&
          f->proxy.selectionStart16 == 1u && f->proxy.selectionEnd16 == 1u,
          "focus_commit_syncs_accepted_value");

    check(cjgui_linux_scene_reserve(&f->candidate, 4u) == 1, "preserve_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 4u;
    f->candidate.projectionVersion = 7u;
    harness_focus_node(&f->candidate.slots[0], 6u, 102,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "server-body", 0u, 1u);
    harness_focus_node(&f->candidate.slots[1], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "right", 0u, 0u);
    harness_focus_node(&f->candidate.slots[2], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[3], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "preserve_commit_applies");
    check(f->proxy.active && strcmp(f->proxy.value, "L") == 0,
          "focus_commit_preserves_local_text_hint");

    check(cjgui_linux_scene_reserve(&f->candidate, 3u) == 1, "retire_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 3u;
    f->candidate.projectionVersion = 8u;
    harness_focus_node(&f->candidate.slots[0], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "right", 0u, 0u);
    harness_focus_node(&f->candidate.slots[1], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[2], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "retire_commit_applies");
    check(!f->proxy.active, "focus_commit_retires_missing_node");

    // Ordinary modal-return restore: without an owned declaration restore must
    // stay ordinary, and the next accepted commit syncs its body.
    check(cjgui_internal_renderer_focus_composable_node(f->token, 7u) == CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.ordinary,
          "focus_after_retire_installs");
    {
        uint32_t start = 0u, end = 0u;
        check(cjgui_internal_renderer_restore_composable_selection(
                  f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 8u,
                  "modal-body", 2u, 4u, &start, &end) == CJGUI_INTERNAL_RENDERER_OK &&
              f->proxy.ordinary && strcmp(f->proxy.value, "modal-body") == 0 &&
              start == 2u && end == 4u && f->proxy.bindingEpoch == 0u,
              "ordinary_restore_keeps_ordinary_proxy");
    }
    check(cjgui_linux_scene_reserve(&f->candidate, 3u) == 1, "ordinary_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 3u;
    f->candidate.projectionVersion = 9u;
    harness_focus_node(&f->candidate.slots[0], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "modal-accepted", 0u, 0u);
    harness_focus_node(&f->candidate.slots[1], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[2], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "ordinary_commit_applies");
    check(f->proxy.ordinary && strcmp(f->proxy.value, "modal-accepted") == 0,
          "ordinary_restore_syncs_accepted_body");

    // Same-node refocus must keep a legitimate local body when the accepted
    // packet carries the preserve hint, instead of swapping in a stale scene
    // value.
    check(cjgui_linux_scene_reserve(&f->candidate, 3u) == 1, "refocus_preserve_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 3u;
    f->candidate.projectionVersion = 10u;
    harness_focus_node(&f->candidate.slots[0], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "stale-body", 0u, 1u);
    harness_focus_node(&f->candidate.slots[1], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[2], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "refocus_preserve_commit_applies");
    check(cjgui_internal_renderer_focus_composable_node(f->token, 7u) == CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.ordinary && strcmp(f->proxy.value, "modal-accepted") == 0 &&
          f->proxy.selectionStart16 == 2u && f->proxy.selectionEnd16 == 4u,
          "refocus_respects_preserves_active_local_text");

    // A real owned declaration makes restore owned; disabling it downgrades
    // the live proxy without dropping the body, and a later retire releases it.
    check(cjgui_internal_renderer_set_composable_owned_text_session(
              f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 11u, 1u) ==
              CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.ordinary && strcmp(f->proxy.value, "modal-accepted") == 0,
          "owned_declaration_does_not_clobber_proxy");
    {
        uint32_t start = 0u, end = 0u;
        check(cjgui_internal_renderer_restore_composable_selection(
                  f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 10u,
                  "owned-body", 1u, 3u, &start, &end) == CJGUI_INTERNAL_RENDERER_OK &&
              !f->proxy.ordinary && strcmp(f->proxy.value, "owned-body") == 0 &&
              start == 1u && end == 3u && f->proxy.bindingEpoch == 11u,
              "owned_restore_uses_real_declaration");
    }
    check(cjgui_internal_renderer_focus_composable_node(f->token, 7u) == CJGUI_INTERNAL_RENDERER_OK &&
          !f->proxy.ordinary && strcmp(f->proxy.value, "owned-body") == 0 &&
          f->proxy.selectionStart16 == 1u && f->proxy.selectionEnd16 == 3u,
          "focus_preserves_owned_range_proxy");
    check(cjgui_internal_renderer_set_composable_owned_text_session(
              f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 11u, 0u) ==
              CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.active && f->proxy.ordinary && f->proxy.bindingEpoch == 0u &&
          strcmp(f->proxy.value, "owned-body") == 0,
          "owned_disable_downgrades_without_losing_body");
    {
        uint32_t start = 0u, end = 0u;
        check(cjgui_internal_renderer_restore_composable_selection(
                  f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 10u,
                  "after-disable", 0u, 0u, &start, &end) == CJGUI_INTERNAL_RENDERER_OK &&
              f->proxy.ordinary && strcmp(f->proxy.value, "after-disable") == 0,
              "ordinary_restore_after_disable");
    }
    check(cjgui_linux_scene_reserve(&f->candidate, 3u) == 1, "disabled_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 3u;
    f->candidate.projectionVersion = 12u;
    harness_focus_node(&f->candidate.slots[0], 7u, 103,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "disabled-sync", 0u, 0u);
    harness_focus_node(&f->candidate.slots[1], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[2], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "disabled_commit_applies");
    check(f->proxy.ordinary && strcmp(f->proxy.value, "disabled-sync") == 0,
          "disabled_commit_syncs_ordinary_body");
    check(cjgui_linux_scene_reserve(&f->candidate, 2u) == 1, "declaration_retire_candidate_reserve");
    f->candidate.valid = 1;
    f->candidate.nodeCount = 2u;
    f->candidate.projectionVersion = 13u;
    harness_focus_node(&f->candidate.slots[0], 8u, 104,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 1u, 0u);
    harness_focus_node(&f->candidate.slots[1], 9u, 105,
                       CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "label", 0u, 0u);
    check(cjgui_linux_commit_candidate(f) == 1, "declaration_retire_commit_applies");
    check(!f->proxy.active, "declaration_retire_releases_proxy");

    free_session(f);
    cjgui_linux_scene_reset(&f->accepted);
    cjgui_linux_scene_reset(&f->candidate);
    memset(f, 0, sizeof(*f));

    // Regression for the real owned install entry: the caller passes nodeKind 0,
    // the proxy starts empty, and identity must come from the matching binding
    // declaration. Reading proxy.nodeKind alone installed kind 0, so recover
    // with the declared kind could never match.
    f->alive = 1;
    f->token = 7703u;
    check(cjgui_linux_scene_reserve(&f->accepted, 1u) == 1, "owned_install_scene_reserve");
    f->accepted.valid = 1;
    f->accepted.nodeCount = 1u;
    f->accepted.projectionVersion = 20u;
    harness_keyboard_node(&f->accepted.slots[0], 6u, 102,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "seed", 0u, 0.0, 1u, 0u);
    check(!f->proxy.active && !f->ownedTextSessionEnabled, "owned_install_starts_empty");
    check(cjgui_internal_renderer_set_composable_owned_text_session(
              f->token, 6u, 102, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 5u, 1u) ==
              CJGUI_INTERNAL_RENDERER_OK,
          "owned_install_declares");
    {
        uint32_t start = 0u, end = 0u;
        uint8_t deferred = 1u;
        check(cjgui_internal_renderer_install_owned_source_selection(
                  f->token, 6u, 102, 20u, 5u, 1u, UINT64_MAX, "owned", 1u, 3u,
                  &start, &end, &deferred) == CJGUI_INTERNAL_RENDERER_OK &&
              f->proxy.active && !f->proxy.ordinary &&
              f->proxy.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT &&
              f->proxy.bindingEpoch == 5u && strcmp(f->proxy.value, "owned") == 0 &&
              start == 1u && end == 3u && deferred == 0u,
              "owned_install_resolves_declaration_kind");
    }
    {
        uint32_t start = 0u, end = 0u;
        check(cjgui_internal_renderer_recover_active_text_proxy(
                  f->token, 6u, 102, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "owned",
                  &start, &end) == CJGUI_INTERNAL_RENDERER_OK && start == 1u && end == 3u,
              "owned_recover_matches_declared_kind");
    }
    // Editable owned inputs take the native focus/caret path (the same path
    // that made the 0450 range chain work); the capture must keep the owned
    // proxy identity and must not publish a common-layer pointer transaction.
    harness_pending_clear(f);
    {
        CjguiLinuxWindowEvent pointer;
        memset(&pointer, 0, sizeof(pointer));
        pointer.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN;
        pointer.button = CJGUI_LINUX_BUTTON_LEFT;
        pointer.x = 20.0;
        pointer.y = 10.0;
        cjgui_linux_handle_window_event(f, &pointer);
        check(f->pointerDown && f->pointerTextTarget &&
              harness_pending_kind_count(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS) == 1u &&
              harness_pending_kind_count(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN) == 0u,
              "owned_input_native_focus_path");
        pointer.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE;
        pointer.x = 80.0;
        cjgui_linux_handle_window_event(f, &pointer);
        check(harness_pending_kind_count(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE) == 0u,
              "owned_input_native_move_path");
        pointer.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_UP;
        cjgui_linux_handle_window_event(f, &pointer);
        check(harness_pending_kind_count(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END) == 0u &&
              harness_pending_kind_count(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) == 0u &&
              !f->proxy.ordinary && f->proxy.bindingEpoch == 5u &&
              strcmp(f->proxy.value, "owned") == 0,
              "owned_input_native_keeps_owned_identity");
        check(f->proxy.selectionStart16 == f->proxy.selectionEnd16 &&
              f->proxy.selectionStart16 <= cjgui_linux_utf16_length("owned", 5u),
              "owned_input_native_caret_collapsed");
    }
    // A restore whose identity does not match the live owned proxy is rejected
    // without damaging it; the owner can recover by the declared kind and
    // immediately continue typing.
    {
        uint32_t start = 0u, end = 0u;
        uint32_t beforeStart = f->proxy.selectionStart16;
        uint32_t beforeEnd = f->proxy.selectionEnd16;
        check(cjgui_internal_renderer_restore_composable_selection(
                  f->token, 6u, 999, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 20u,
                  "intruder", 0u, 0u, &start, &end) != CJGUI_INTERNAL_RENDERER_OK,
              "owned_restore_wrong_resource_rejected");
        check(cjgui_internal_renderer_restore_composable_selection(
                  f->token, 6u, 102, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 20u,
                  "intruder", 0u, 0u, &start, &end) != CJGUI_INTERNAL_RENDERER_OK,
              "owned_restore_wrong_kind_rejected");
        check(strcmp(f->proxy.value, "owned") == 0 &&
              f->proxy.selectionStart16 == beforeStart &&
              f->proxy.selectionEnd16 == beforeEnd && !f->proxy.ordinary &&
              f->proxy.bindingEpoch == 5u,
              "owned_rejected_restore_keeps_proxy");
        check(cjgui_internal_renderer_recover_active_text_proxy(
                  f->token, 6u, 102, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "owned",
                  &start, &end) == CJGUI_INTERNAL_RENDERER_OK,
              "owned_recover_after_reject");
        check(cjgui_linux_emit_text_edit(f, 3u, 0u, "!") == 1 &&
              strcmp(f->proxy.value, "own!ed") == 0 && !f->proxy.ordinary,
              "owned_continue_after_reject");
    }
    free_session(f);
    cjgui_linux_scene_reset(&f->accepted);
    memset(f, 0, sizeof(*f));

    // A preserved local body and the accepted packet may differ. The click
    // path must hit-test and convert against the same (proxy) body; otherwise
    // the caret lands at a position from a different string.
    {
        CjguiLinuxSession *h = &g_sessions[1];
        memset(h, 0, sizeof(*h));
        h->alive = 1;
        h->token = 7704u;
        check(cjgui_linux_scene_reserve(&h->accepted, 1u) == 1, "body_hit_scene_reserve");
        h->accepted.valid = 1;
        h->accepted.nodeCount = 1u;
        h->accepted.projectionVersion = 21u;
        harness_keyboard_node(&h->accepted.slots[0], 40u, 140,
                              CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "accepted", 0u, 0.0, 1u, 0u);
        h->accepted.slots[0].node.width = 400.0;
        h->accepted.slots[0].node.fontSize = 14.0;
        h->accepted.slots[0].node.fontFamily = 1u;
        h->accepted.slots[0].node.preservesActiveLocalText = 1u;
        int textStatus = -1;
        h->text = cjgui_linux_text_create(&textStatus);
        check(h->text != NULL, "body_hit_text_service");
        h->proxy.active = 1;
        h->proxy.ordinary = 1;
        h->proxy.nodeId = 40u;
        h->proxy.resourceId = 140;
        h->proxy.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        h->proxy.sceneVersion = 21u;
        h->proxy.value = cjgui_linux_strdup("WWWWWWWWWWWW");
        h->proxy.selectionStart16 = 12u;
        h->proxy.selectionEnd16 = 12u;
        check(cjgui_internal_renderer_focus_composable_node(h->token, 40u) == CJGUI_INTERNAL_RENDERER_OK &&
              strcmp(h->proxy.value, "WWWWWWWWWWWW") == 0,
              "body_hit_keeps_preserved_proxy");
        double proxyX = 0.0, acceptedX = 0.0, top = 0.0, height = 0.0;
        uint32_t lineIndex = 0u;
        size_t lineStart = 0u, lineEnd = 0u;
        // The proxy has 12 characters and the accepted body 8. A click at the
        // proxy's caret 10 lies past the accepted body's end, so a mixed-body
        // path would clamp to 8 instead of landing on 10.
        check(cjgui_linux_text_caret_position(h->text, "WWWWWWWWWWWW", 12u, 14.0, 0u, 1u, 388.0,
                                              10u, &proxyX, &top, &height, &lineIndex,
                                              &lineStart, &lineEnd) == CJGUI_LINUX_TEXT_OK &&
              cjgui_linux_text_caret_position(h->text, "accepted", 8u, 14.0, 0u, 1u, 388.0,
                                              8u, &acceptedX, &top, &height, &lineIndex,
                                              &lineStart, &lineEnd) == CJGUI_LINUX_TEXT_OK,
              "body_hit_metrics");
        check(fabs(proxyX - acceptedX) > 4.0, "body_hit_bodies_differ");
        harness_pending_clear(h);
        {
            CjguiLinuxWindowEvent click;
            memset(&click, 0, sizeof(click));
            click.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN;
            click.button = CJGUI_LINUX_BUTTON_LEFT;
            click.x = proxyX + 1.0;
            click.y = 5.0;
            check(cjgui_linux_pointer_focus_text(h, &h->accepted.slots[0], &click) == 1 &&
                  h->proxy.selectionStart16 == 10u && h->proxy.selectionEnd16 == 10u,
                  "body_hit_uses_proxy_body");
            if (h->pendingCount >= 2u) {
                uint32_t focusIndex = (h->pendingHead + h->pendingCount - 2u) % CJGUI_LINUX_PENDING_EVENTS;
                uint32_t selectionIndex =
                    (h->pendingHead + h->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
                check(h->pending[focusIndex].event.kind ==
                          CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS &&
                      h->pending[focusIndex].hasText &&
                      strcmp(h->pending[focusIndex].text, "WWWWWWWWWWWW") == 0,
                      "body_hit_focus_carries_same_body");
                check(h->pending[selectionIndex].event.kind ==
                          CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
                      h->pending[selectionIndex].event.selectionStart == 10 &&
                      h->pending[selectionIndex].event.selectionEnd == 10,
                      "body_hit_selection_uses_same_body");
            } else {
                check(0, "body_hit_focus_and_selection_queued");
            }
        }
        cjgui_linux_text_destroy(h->text);
        h->text = NULL;
        free_session(h);
        cjgui_linux_scene_reset(&h->accepted);
        memset(h, 0, sizeof(*h));
    }

    // Keyboard form path: Tab/ShiftTab over accepted order and scope, disabled
    // and read-only skipped, Enter/Space activation, Esc dismissal, and the
    // proxy released as soon as focus lands on a non-text control.
    f->alive = 1;
    f->token = 7705u;
    check(cjgui_linux_scene_reserve(&f->accepted, 7u) == 1, "keyboard_scene_reserve");
    f->accepted.valid = 1;
    f->accepted.nodeCount = 7u;
    f->accepted.projectionVersion = 22u;
    harness_keyboard_node(&f->accepted.slots[0], 6u, 102,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "alpha", 0u, 0.0, 1u, 0u);
    harness_keyboard_node(&f->accepted.slots[1], 7u, 103,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, "beta", 0u, 40.0, 1u, 0u);
    harness_keyboard_node(&f->accepted.slots[2], 8u, 104,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, "", 0u, 80.0, 1u, 0u);
    harness_keyboard_node(&f->accepted.slots[3], 9u, 105,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, "", 0u, 120.0, 0u, 0u);
    harness_keyboard_node(&f->accepted.slots[4], 10u, 106,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "locked", 0u, 160.0, 1u, 1u);
    harness_keyboard_node(&f->accepted.slots[5], 23u, 107,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, "", 7u, 200.0, 1u, 0u);
    harness_keyboard_node(&f->accepted.slots[6], 24u, 108,
                          CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, "hint", 7u, 240.0, 0u, 0u);

    check(cjgui_internal_renderer_focus_composable_node(f->token, 6u) == CJGUI_INTERNAL_RENDERER_OK &&
          f->focusActive && f->focusNodeId == 6u && f->proxy.active,
          "keyboard_initial_focus");
    harness_pending_clear(f);
    {
        CjguiLinuxWindowEvent tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 7u && f->proxy.nodeId == 7u &&
              strcmp(f->proxy.value, "beta") == 0 &&
              harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, 7u, "beta"),
              "keyboard_tab_forward");
        harness_pending_clear(f);
        tab = harness_key_event(CJGUI_LINUX_XK_ISO_LEFT_TAB, 23u, CJGUI_LINUX_MOD_SHIFT, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 6u && f->proxy.nodeId == 6u &&
              harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, 6u, "alpha"),
              "keyboard_shift_tab_backward");
        harness_pending_clear(f);
        tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 8u && !f->proxy.active &&
              harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, 8u, NULL),
              "keyboard_tab_reaches_button_and_releases_proxy");
    }
    {
        uint32_t queued = f->pendingCount;
        CjguiLinuxWindowEvent typing = harness_key_event(0x0078u, 53u, 0u, "x");
        cjgui_linux_handle_window_event(f, &typing);
        check(f->pendingCount == queued && !f->proxy.active &&
              strcmp(f->accepted.slots[0].value, "alpha") == 0 &&
              strcmp(f->accepted.slots[1].value, "beta") == 0,
              "keyboard_button_typing_does_not_reach_old_field");
        harness_pending_clear(f);
        CjguiLinuxWindowEvent space = harness_key_event(CJGUI_LINUX_XK_SPACE, 65u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &space);
        check(harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, 8u, NULL),
              "keyboard_space_activates_button");
        harness_pending_clear(f);
        CjguiLinuxWindowEvent enter = harness_key_event(CJGUI_LINUX_XK_RETURN, 36u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &enter);
        check(harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, 8u, NULL),
              "keyboard_enter_activates_button");
        harness_pending_clear(f);
        CjguiLinuxWindowEvent tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 6u && f->proxy.active && strcmp(f->proxy.value, "alpha") == 0,
              "keyboard_tab_skips_disabled_and_readonly");
    }
    // Esc with base focus targets the topmost scoped layer, without pushing focus
    // into the base form. Programmatic modal focus then keeps Tab inside scope 7.
    check(cjgui_internal_renderer_focus_composable_node(f->token, 8u) == CJGUI_INTERNAL_RENDERER_OK &&
          !f->proxy.active,
          "keyboard_button_focus_releases_text");
    harness_pending_clear(f);
    {
        CjguiLinuxWindowEvent escape = harness_key_event(CJGUI_LINUX_XK_ESCAPE, 9u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &escape);
        check(harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DISMISS_LAYER,
                                 23u, "escape"),
              "keyboard_escape_dismisses_scoped_layer");
        harness_pending_clear(f);
        check(cjgui_internal_renderer_focus_composable_node(f->token, 23u) == CJGUI_INTERNAL_RENDERER_OK &&
              f->focusNodeId == 23u && !f->proxy.active,
              "keyboard_modal_initial_focus");
        CjguiLinuxWindowEvent tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 23u &&
              harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, 23u, NULL),
              "keyboard_tab_stays_in_modal_scope");
        harness_pending_clear(f);
        tab = harness_key_event(CJGUI_LINUX_XK_ISO_LEFT_TAB, 23u, CJGUI_LINUX_MOD_SHIFT, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 23u, "keyboard_shift_tab_stays_in_modal_scope");
        harness_pending_clear(f);
        escape = harness_key_event(CJGUI_LINUX_XK_ESCAPE, 9u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &escape);
        check(harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DISMISS_LAYER,
                                 23u, "escape"),
              "keyboard_modal_escape_targets_focused_scope");
    }
    // Escape/Tab must not fight system composition or command shortcuts; a
    // multiline field that inserts tabs keeps doing so instead of traversing.
    harness_pending_clear(f);
    check(cjgui_internal_renderer_focus_composable_node(f->token, 6u) == CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.active,
          "keyboard_composition_refocus");
    {
        f->compositionActive = 1;
        CjguiLinuxWindowEvent tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 6u && f->pendingCount == 0u,
              "keyboard_composition_keeps_tab");
        f->compositionActive = 0;
        tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, CJGUI_LINUX_MOD_CONTROL, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 6u && f->pendingCount == 0u,
              "keyboard_command_tab_does_not_traverse");
    }
    harness_pending_clear(f);
    f->accepted.slots[1].node.tabInsertsText = 1u;
    check(cjgui_internal_renderer_focus_composable_node(f->token, 7u) == CJGUI_INTERNAL_RENDERER_OK &&
          f->proxy.active,
          "keyboard_multiline_focus");
    {
        CjguiLinuxWindowEvent tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, "\t");
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 7u && f->proxy.active && strcmp(f->proxy.value, "beta\t") == 0,
              "keyboard_multiline_tab_inserts_instead_of_traverse");
        f->accepted.slots[1].node.tabInsertsText = 0u;
    }
    // Owned/range sessions keep their existing key contract: Tab is not turned
    // into focus traversal, and it is not inserted into a single-line owner.
    harness_pending_clear(f);
    check(cjgui_internal_renderer_set_composable_owned_text_session(
              f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 9u, 1u) ==
              CJGUI_INTERNAL_RENDERER_OK,
          "keyboard_owned_tab_declare");
    {
        uint32_t start = 0u, end = 0u;
        uint8_t deferred = 0u;
        check(cjgui_internal_renderer_install_owned_source_selection(
                  f->token, 7u, 103, 22u, 9u, 2u, UINT64_MAX, "beta", 2u, 2u,
                  &start, &end, &deferred) == CJGUI_INTERNAL_RENDERER_OK &&
              !f->proxy.ordinary,
              "keyboard_owned_tab_install");
        CjguiLinuxWindowEvent tab = harness_key_event(CJGUI_LINUX_XK_TAB, 23u, 0u, NULL);
        cjgui_linux_handle_window_event(f, &tab);
        check(f->focusNodeId == 7u && f->pendingCount == 0u &&
              strcmp(f->proxy.value, "beta") == 0,
              "keyboard_owned_tab_preserves_contract");
        check(cjgui_internal_renderer_set_composable_owned_text_session(
                  f->token, 7u, 103, CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 9u, 0u) ==
                  CJGUI_INTERNAL_RENDERER_OK,
              "keyboard_owned_tab_withdraw");
    }
    // Pointer press on a button also publishes FOCUS immediately (macOS
    // mouse-down parity), not only on release; a cancelled click still leaves
    // the ring on the real native focus.
    harness_pending_clear(f);
    {
        CjguiLinuxWindowEvent pointer;
        memset(&pointer, 0, sizeof(pointer));
        pointer.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN;
        pointer.button = CJGUI_LINUX_BUTTON_LEFT;
        pointer.x = 100.0;
        pointer.y = 90.0;
        cjgui_linux_handle_window_event(f, &pointer);
        check(!f->proxy.active && f->focusNodeId == 8u &&
              harness_pending_kind_count(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS) == 1u,
              "keyboard_pointer_button_focus_published");
        pointer.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_UP;
        cjgui_linux_handle_window_event(f, &pointer);
        check(harness_last_event(f, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, 8u, NULL),
              "keyboard_pointer_button_activate");
    }
    // Gradient: normalized coordinates must subtract the node origin, and the
    // piecewise ramp must be evaluated at non-midpoint stops. The same moved
    // gradient is checked at a local point whose old absolute normalization
    // would land on the last stop.
    {
        CjguiInternalRendererComposableNode gradient;
        memset(&gradient, 0, sizeof(gradient));
        gradient.gradientPresent = 1u;
        gradient.gradientStopCount = 3u;
        gradient.gradientStartX = 0.1;
        gradient.gradientStartY = 0.1;
        gradient.gradientEndX = 0.9;
        gradient.gradientEndY = 0.9;
        gradient.gradientStop0Position = 0.2;
        gradient.gradientStop0Red = 1.0;
        gradient.gradientStop0Alpha = 1.0;
        gradient.gradientStop1Position = 0.55;
        gradient.gradientStop1Green = 1.0;
        gradient.gradientStop1Alpha = 1.0;
        gradient.gradientStop2Position = 0.85;
        gradient.gradientStop2Blue = 1.0;
        gradient.gradientStop2Alpha = 1.0;
        double t = cjgui_linux_node_gradient_parameter(&gradient, 200.0, 100.0,
                                                       100.0, 50.0, 200.0, 100.0);
        check(fabs(t - 0.5) < 1e-9, "gradient_local_origin_parameter");
        double r = 0.0, g = 0.0, b = 0.0, a = 0.0;
        cjgui_linux_node_gradient_color_at(&gradient, 0.5, &r, &g, &b, &a);
        check(fabs(r - 0.142857142857) < 1e-6 && fabs(g - 0.857142857143) < 1e-6 &&
              fabs(b) < 1e-9 && fabs(a - 1.0) < 1e-9,
              "gradient_non_midpoint_three_stop");
        gradient.gradientStopCount = 4u;
        gradient.gradientStop0Position = 0.15;
        gradient.gradientStop1Position = 0.4;
        gradient.gradientStop1Green = 1.0;
        gradient.gradientStop2Position = 0.7;
        gradient.gradientStop2Blue = 1.0;
        gradient.gradientStop3Position = 0.95;
        gradient.gradientStop3Red = 1.0;
        gradient.gradientStop3Green = 1.0;
        gradient.gradientStop3Blue = 1.0;
        cjgui_linux_node_gradient_color_at(&gradient, 0.3, &r, &g, &b, &a);
        check(fabs(r - 0.4) < 1e-6 && fabs(g - 0.6) < 1e-6 && fabs(b) < 1e-6,
              "gradient_three_of_four_stops");
        cjgui_linux_node_gradient_color_at(&gradient, 0.8, &r, &g, &b, &a);
        check(fabs(r - 0.4) < 1e-6 && fabs(g - 0.4) < 1e-6 && fabs(b - 1.0) < 1e-6,
              "gradient_fourth_stop");
    }

    // A emitted gradient triangle must be split at every interior stop; the
    // sample at x=0.35 then interpolates exactly between the 0.2 and 0.5
    // stops, unlike a single corner-coloured triangle (which would be red).
    {
        CjguiInternalRendererComposableNode node;
        memset(&node, 0, sizeof(node));
        node.width = 100;
        node.height = 100;
        node.gradientPresent = 1u;
        node.gradientStopCount = 3u;
        node.gradientStartX = 0.0;
        node.gradientStartY = 0.0;
        node.gradientEndX = 1.0;
        node.gradientEndY = 0.0;
        node.gradientStop0Position = 0.2;
        node.gradientStop0Red = 1.0;
        node.gradientStop0Alpha = 1.0;
        node.gradientStop1Position = 0.5;
        node.gradientStop1Green = 1.0;
        node.gradientStop1Alpha = 1.0;
        node.gradientStop2Position = 0.8;
        node.gradientStop2Blue = 1.0;
        node.gradientStop2Alpha = 1.0;
        CjguiLinuxPaintTransform identity;
        memset(&identity, 0, sizeof(identity));
        CjguiLinuxPoint2D triangle[3] = { { 0.0, 0.0 }, { 100.0, 0.0 }, { 0.0, 100.0 } };
        CjguiLinuxClipAperture noClip;
        memset(&noClip, 0, sizeof(noClip));
        CjguiLinuxVertexBuilder builder;
        memset(&builder, 0, sizeof(builder));
        builder.desiredSlot = UINT32_MAX;
        cjgui_linux_builder_shape_triangle(&builder, &node, &identity, triangle, 1,
                                           0.0, 0.0, 100.0, 100.0, 0.0, 0.0, 0.0, 0.0,
                                           0.0, 0.0, 100.0, 100.0, &noClip);
        check(builder.count > 0u && builder.count % 3u == 0u, "gradient_triangle_emitted");
        int spansStop = 0;
        for (uint32_t i = 0u; i + 2u < builder.count; i += 3u) {
            double minT = 1e9, maxT = -1e9;
            for (uint32_t j = 0u; j < 3u; j += 1u) {
                double value = builder.vertices[i + j].x / 100.0;
                if (value < minT) minT = value;
                if (value > maxT) maxT = value;
            }
            const double stops[3] = { 0.2, 0.5, 0.8 };
            for (uint32_t j = 0u; j < 3u; j += 1u) {
                if (minT < stops[j] - 1e-6 && maxT > stops[j] + 1e-6) spansStop = 1;
            }
        }
        check(!spansStop, "gradient_triangles_split_at_stops");
        int found = 0;
        double interpolatedRed = 0.0, interpolatedGreen = 0.0, interpolatedBlue = 0.0;
        for (uint32_t i = 0u; i + 2u < builder.count; i += 3u) {
            const CjguiLinuxGpuVertex *v0 = &builder.vertices[i];
            const CjguiLinuxGpuVertex *v1 = &builder.vertices[i + 1u];
            const CjguiLinuxGpuVertex *v2 = &builder.vertices[i + 2u];
            double denominator = (v1->y - v2->y) * (v0->x - v2->x) +
                                 (v2->x - v1->x) * (v0->y - v2->y);
            if (fabs(denominator) < 1e-9) continue;
            double w0 = ((v1->y - v2->y) * (35.0 - v2->x) + (v2->x - v1->x) * (10.0 - v2->y)) /
                        denominator;
            double w1 = ((v2->y - v0->y) * (35.0 - v2->x) + (v0->x - v2->x) * (10.0 - v2->y)) /
                        denominator;
            double w2 = 1.0 - w0 - w1;
            if (w0 < -1e-6 || w1 < -1e-6 || w2 < -1e-6) continue;
            interpolatedRed = w0 * v0->r + w1 * v1->r + w2 * v2->r;
            interpolatedGreen = w0 * v0->g + w1 * v1->g + w2 * v2->g;
            interpolatedBlue = w0 * v0->b + w1 * v1->b + w2 * v2->b;
            found = 1;
            break;
        }
        check(found && fabs(interpolatedRed - 0.5) < 1e-4 &&
              fabs(interpolatedGreen - 0.5) < 1e-4 && fabs(interpolatedBlue) < 1e-4,
              "gradient_piecewise_interpolation_exact");
        cjgui_linux_builder_release(&builder);
    }

    // Starts/ends inside the node: the raw spatial parameter must stay
    // unclamped so the flat end sections survive, and only the middle ramps.
    {
        CjguiInternalRendererComposableNode node;
        memset(&node, 0, sizeof(node));
        node.width = 100;
        node.height = 100;
        node.gradientPresent = 1u;
        node.gradientStopCount = 2u;
        node.gradientStartX = 0.25;
        node.gradientStartY = 0.0;
        node.gradientEndX = 0.75;
        node.gradientEndY = 0.0;
        node.gradientStop0Position = 0.0;
        node.gradientStop0Red = 1.0;
        node.gradientStop0Alpha = 1.0;
        node.gradientStop1Position = 1.0;
        node.gradientStop1Green = 1.0;
        node.gradientStop1Alpha = 1.0;
        double tStart = cjgui_linux_node_gradient_parameter(&node, 0.0, 50.0, 0.0, 0.0, 100.0, 100.0);
        double tEnd = cjgui_linux_node_gradient_parameter(&node, 100.0, 50.0, 0.0, 0.0, 100.0, 100.0);
        check(fabs(tStart + 0.5) < 1e-9 && fabs(tEnd - 1.5) < 1e-9,
              "gradient_parameter_not_clamped");
        CjguiLinuxPaintTransform identity;
        memset(&identity, 0, sizeof(identity));
        CjguiLinuxClipAperture noClip;
        memset(&noClip, 0, sizeof(noClip));
        CjguiLinuxVertexBuilder builder;
        memset(&builder, 0, sizeof(builder));
        builder.desiredSlot = UINT32_MAX;
        CjguiLinuxPoint2D triA[3] = { { 0.0, 0.0 }, { 100.0, 0.0 }, { 0.0, 100.0 } };
        CjguiLinuxPoint2D triB[3] = { { 100.0, 0.0 }, { 100.0, 100.0 }, { 0.0, 100.0 } };
        cjgui_linux_builder_shape_triangle(&builder, &node, &identity, triA, 1,
                                           0.0, 0.0, 100.0, 100.0, 0.0, 0.0, 0.0, 0.0,
                                           0.0, 0.0, 100.0, 100.0, &noClip);
        cjgui_linux_builder_shape_triangle(&builder, &node, &identity, triB, 1,
                                           0.0, 0.0, 100.0, 100.0, 0.0, 0.0, 0.0, 0.0,
                                           0.0, 0.0, 100.0, 100.0, &noClip);
        double r = -1.0, g = -1.0, b = -1.0;
        int gotStart = harness_sample_triangle_color(&builder, 5.0, 1.0, &r, &g, &b);
        check(gotStart && fabs(r - 1.0) < 1e-5 && fabs(g) < 1e-5,
              "gradient_left_end_flat");
        int gotBoundary = harness_sample_triangle_color(&builder, 25.0, 1.0, &r, &g, &b);
        check(gotBoundary && fabs(r - 1.0) < 1e-5 && fabs(g) < 1e-5,
              "gradient_left_boundary_flat");
        int gotMiddle = harness_sample_triangle_color(&builder, 50.0, 1.0, &r, &g, &b);
        check(gotMiddle && fabs(r - 0.5) < 1e-5 && fabs(g - 0.5) < 1e-5,
              "gradient_middle_ramp");
        int gotEndBoundary = harness_sample_triangle_color(&builder, 75.0, 1.0, &r, &g, &b);
        check(gotEndBoundary && fabs(r) < 1e-5 && fabs(g - 1.0) < 1e-5,
              "gradient_right_boundary_flat");
        int gotEnd = harness_sample_triangle_color(&builder, 95.0, 1.0, &r, &g, &b);
        check(gotEnd && fabs(r) < 1e-5 && fabs(g - 1.0) < 1e-5,
              "gradient_right_end_flat");
        cjgui_linux_builder_release(&builder);
    }

    // Radius smaller than stroke width: the inner rectangle (four points) must
    // be expanded to the outer ring's 32 phases, or the whole border vanishes.
    {
        CjguiInternalRendererComposableNode border;
        memset(&border, 0, sizeof(border));
        border.width = 100;
        border.height = 100;
        border.cornerRadius = 2.0;
        border.borderWidth = 8u;
        border.borderAlpha = 1.0;
        CjguiLinuxPaintTransform identity;
        memset(&identity, 0, sizeof(identity));
        CjguiLinuxClipAperture noClip;
        memset(&noClip, 0, sizeof(noClip));
        CjguiLinuxVertexBuilder builder;
        memset(&builder, 0, sizeof(builder));
        builder.desiredSlot = UINT32_MAX;
        cjgui_linux_builder_rounded_border(&builder, &border, &identity, 0.0, 0.0,
                                           100.0, 100.0, 8.0, 0.0, 0.0, 100.0, 100.0,
                                           &noClip);
        check(builder.count == 4u * CJGUI_LINUX_RADIUS_SEGMENTS * 2u * 3u,
              "rounded_border_thick_radius_ring_kept");
        cjgui_linux_builder_release(&builder);
    }

    // Empty rounded intersection is not an absent clip: it must stop paint,
    // while a node with no rounded ancestor stays drawable.
    {
        CjguiLinuxNodeSlot clip;
        memset(&clip, 0, sizeof(clip));
        clip.node.clipX = 0;
        clip.node.clipY = 0;
        clip.node.clipWidth = 10;
        clip.node.clipHeight = 10;
        clip.node.clipCornerRadius = 5.0;
        CjguiLinuxClipAperture aperture;
        int painted = cjgui_linux_slot_clip_aperture(&clip, 1.0, 20.0, 20.0, 30.0, 30.0,
                                                     &aperture);
        check(painted == 0 && aperture.empty == 1 && aperture.active == 0,
              "rounded_clip_empty_is_terminal");
        clip.node.clipCornerRadius = 0.0;
        painted = cjgui_linux_slot_clip_aperture(&clip, 1.0, 20.0, 20.0, 30.0, 30.0,
                                                 &aperture);
        check(painted == 0 && aperture.empty == 0 && aperture.active == 0,
              "rounded_clip_absent_is_not_empty");
    }

    // Drag capture is keyed to the press-time node/resource/kind and binding
    // epoch. Switching focus to another editable field must terminate the old
    // gesture, not feed A's anchor into B; refocusing A makes the same guard
    // pass again.
    {
        CjguiLinuxSession *d = &g_sessions[1];
        memset(d, 0, sizeof(*d));
        d->alive = 1;
        d->token = 8801u;
        check(cjgui_linux_scene_reserve(&d->accepted, 2u) == 1, "drag_scene_reserve");
        d->accepted.valid = 1;
        d->accepted.nodeCount = 2u;
        d->accepted.projectionVersion = 3u;
        harness_focus_node(&d->accepted.slots[0], 21u, 201,
                           CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "alpha", 0u, 0u);
        harness_focus_node(&d->accepted.slots[1], 22u, 202,
                           CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, "beta", 0u, 0u);
        check(cjgui_internal_renderer_focus_composable_node(d->token, 21u) ==
              CJGUI_INTERNAL_RENDERER_OK, "drag_focus_a");
        d->pointerTextTarget = 1;
        d->pointerTextNodeId = 21u;
        d->pointerTextResourceId = 201;
        d->pointerTextNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        d->pointerTextBindingEpoch = d->proxy.bindingEpoch;
        check(cjgui_linux_pointer_text_slot(d) == &d->accepted.slots[0], "drag_capture_a");
        check(cjgui_internal_renderer_focus_composable_node(d->token, 22u) ==
              CJGUI_INTERNAL_RENDERER_OK, "drag_focus_switch_b");
        uint32_t bStart = d->proxy.selectionStart16;
        uint32_t bEnd = d->proxy.selectionEnd16;
        check(cjgui_linux_pointer_text_slot(d) == NULL, "drag_capture_switch_invalid");
        CjguiLinuxWindowEvent move;
        memset(&move, 0, sizeof(move));
        move.kind = CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE;
        move.x = 20.0;
        move.y = 20.0;
        cjgui_linux_pointer_drag_text(d, &move);
        check(!d->pointerTextTarget && d->pointerTextAborted,
              "drag_capture_aborted_on_switch");
        check(d->proxy.nodeId == 22u && d->proxy.selectionStart16 == bStart &&
              d->proxy.selectionEnd16 == bEnd, "drag_switch_keeps_b_selection");
        check(cjgui_internal_renderer_focus_composable_node(d->token, 21u) ==
              CJGUI_INTERNAL_RENDERER_OK, "drag_refocus_a");
        d->pointerTextTarget = 1;
        d->pointerTextAborted = 0;
        d->pointerTextNodeId = 21u;
        d->pointerTextResourceId = 201;
        d->pointerTextNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        d->pointerTextBindingEpoch = d->proxy.bindingEpoch;
        check(cjgui_linux_pointer_text_slot(d) == &d->accepted.slots[0],
              "drag_capture_resumes_after_refocus");
        d->proxy.bindingEpoch = 7u;
        d->pointerTextBindingEpoch = 6u;
        check(cjgui_linux_pointer_text_slot(d) == NULL, "drag_capture_binding_epoch");
        free_session(d);
        cjgui_linux_scene_reset(&d->accepted);
        memset(d, 0, sizeof(*d));
    }

    free_session(f);
    cjgui_linux_scene_reset(&f->accepted);
    memset(f, 0, sizeof(*f));

    printf("HARNESS RESULT %s failures=%d\n", failures == 0 ? "PASS" : "FAIL", failures);
    return failures == 0 ? 0 : 1;
}
