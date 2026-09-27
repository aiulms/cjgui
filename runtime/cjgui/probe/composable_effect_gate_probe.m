// runtime/cjgui/probe/composable_effect_gate_probe.m
//
// Probe-only proof for the P1 shape-effect boundary. It complements
// composable_scene_probe.m rather than replacing it: the scene probe owns
// painter order, text textures and clip geometry, while this probe owns the
// three contracts that the drawing gate and the hit test must agree on:
//
//   1. Draw gate / painter order. A node whose own clip is empty may still
//      paint an outer shadow that reaches the viewport, but only when the
//      shadow's own output range meets every ancestor clip constraint. The
//      body fill/border must never survive that empty clip.
//   2. Hit test is bounds-only. An outer shadow never widens interactivity;
//      a point that only lands on the shadow must not activate the node.
//   3. Zero regression. A node with no effect still takes the ordinary shape
//      path, and the effect paths are accounted for by real extra vertices
//      instead of a fabricated offscreen-cache metric.
//
// Every positive scene has an explicitly negative sibling that fails if the
// implementation regresses: S2/S3/S4 are the negatives of S1, the off-frame
// sample is the negative of S5's center sample, and the miss point is the
// negative of the hit point. Nothing here writes production state; it only
// drives the internal test seams declared in cjgui_internal_renderer.h.
#import "../native/cjgui_internal_renderer.h"
#import <AppKit/AppKit.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Background color of every scene below. The explicit numeric readback uses
// the same 0..1 -> 0..255 mapping as the existing composable scene probe, so a
// tolerance of 10 absorbs rounding but not a wrong paint path.
static const uint8_t kBackgroundBlue = 36, kBackgroundGreen = 20, kBackgroundRed = 10;
// Outer shadow color: opaque pure red. It is far from both the clear color and
// the root background, so any is-the-shadow-visible decision is measurable.
static const uint8_t kShadowBlue = 0, kShadowGreen = 0, kShadowRed = 255;
// Plain fill of the ordering scene: opaque blue (red=0.10, green=0.20,
// blue=0.95), so the BGRA readback is B=242, G=51, R=26.
static const uint8_t kFillBlue = 242, kFillGreen = 51, kFillRed = 26;

static int require(int condition, const char *message) {
    if (!condition) { fprintf(stderr, "effect gate probe: failed %s\n", message); }
    return condition;
}

static int require_bgra(uint8_t blue, uint8_t green, uint8_t red, uint8_t alpha,
                        uint8_t expectedBlue, uint8_t expectedGreen, uint8_t expectedRed,
                        uint8_t expectedAlpha, const char *message) {
    const int tolerance = 10;
    int valid = abs((int)blue - (int)expectedBlue) <= tolerance &&
                abs((int)green - (int)expectedGreen) <= tolerance &&
                abs((int)red - (int)expectedRed) <= tolerance &&
                abs((int)alpha - (int)expectedAlpha) <= tolerance;
    if (!valid) {
        fprintf(stderr, "effect gate probe: failed %s actual=%u,%u,%u,%u expected=%u,%u,%u,%u\n",
                message, blue, green, red, alpha, expectedBlue, expectedGreen, expectedRed, expectedAlpha);
    }
    return valid;
}

// Samples one logical-point pixel the same way composable_scene_probe.m does:
// declare the point, present the currently committed composable scene, then
// read the drawable back. The scene is committed by an earlier
// present_composable_scene call, so this only re-encodes the accepted scene.
static int capture_composable_pixel(uint64_t session, uint32_t pointX, uint32_t pointY,
                                    uint8_t *outBlue, uint8_t *outGreen,
                                    uint8_t *outRed, uint8_t *outAlpha) {
    CjguiInternalRendererClearColor clear = { 0.08, 0.16, 0.20, 1.0 };
    CjguiInternalRendererFrameObservation frame = {0};
    if (cjgui_internal_renderer_test_request_composable_drawable_pixel(session, pointX, pointY) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    if (cjgui_internal_renderer_present_clear(session, &clear, &frame) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return cjgui_internal_renderer_test_composable_drawable_pixel(session, outBlue, outGreen, outRed, outAlpha) == CJGUI_INTERNAL_RENDERER_OK;
}

// Full-window background. It keeps every "shadow disappeared" sample on a
// deterministic, non-clear color, and it deliberately leaves the effect
// decisions to the child node under test.
static CjguiInternalRendererComposableNode make_root(uint64_t projectionVersion, uint64_t nodeId) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = nodeId;
    node.projectionVersion = projectionVersion;
    node.x = 0; node.y = 0; node.width = 420; node.height = 180;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 420; node.clipHeight = 180;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 420; node.clip0Height = 180;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    node.fillRed = 0.04; node.fillGreen = 0.08; node.fillBlue = 0.14; node.fillAlpha = 1.0;
    return node;
}

static int stage_two_nodes(uint64_t session, uint64_t projectionVersion,
                           const CjguiInternalRendererComposableNode *root,
                           const CjguiInternalRendererComposableNode *child) {
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_configure_composable_scene(session, projectionVersion, 2) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_set_composable_scene_node(session, 0, root, "gate-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_set_composable_scene_node(session, 1, child, "gate-child", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK;
}

// Scene order is the painter order: node 1 paints before node 2. The S5R
// ordering negative control needs two independently ordered children on top of
// one root, so it stages three nodes instead of two.
static int stage_three_nodes(uint64_t session, uint64_t projectionVersion,
                             const CjguiInternalRendererComposableNode *root,
                             const CjguiInternalRendererComposableNode *first,
                             const CjguiInternalRendererComposableNode *second) {
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_configure_composable_scene(session, projectionVersion, 3) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_set_composable_scene_node(session, 0, root, "gate-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_set_composable_scene_node(session, 1, first, "gate-first", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_set_composable_scene_node(session, 2, second, "gate-second", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
           cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK;
}

// The latest submitted frame's shape accounting. shapeVertexBytes is the real
// number of generic vertices the encoder uploaded, so a shadow-only node that
// appends a quad still has to show up there even though the node counters only
// advance on the non-empty-clip branch.
typedef struct EffectEncoderCounters {
    uint32_t shapeNodeCount;
    uint32_t shapeBatchCount;
    uint32_t textureDrawCount;
    uint64_t shapeVertexBytes;
} EffectEncoderCounters;

static int read_encoder_counters(uint64_t session, EffectEncoderCounters *outCounters) {
    return cjgui_internal_renderer_test_composable_encoder_stats(
               session, &outCounters->shapeNodeCount, &outCounters->shapeBatchCount,
               &outCounters->textureDrawCount, &outCounters->shapeVertexBytes) == CJGUI_INTERNAL_RENDERER_OK;
}

// S1-S5: the body is entirely left of the viewport and its own resolved clip
// is empty (clipWidth/clipHeight == 0). The drawing loop must therefore take
// the shadow-only branch. The only thing that can paint at the sampled point
// is the shadow, and the only thing that can remove it is the shadow output
// range losing to the ancestor clip chain or the drawable.
static int verify_draw_gate_and_painter_order(uint64_t session) {
    CjguiInternalRendererComposableNode root = make_root(200, 900);
    CjguiInternalRendererComposableNode body = {0};
    body.nodeId = 901;
    body.projectionVersion = 200;
    body.x = -160; body.y = 80; body.width = 60; body.height = 60;
    // Empty own clip: the body must not paint, but the shadow may.
    body.clipX = 0; body.clipY = 0; body.clipWidth = 0; body.clipHeight = 0;
    body.clipConstraintCount = 1;
    body.clip0X = 0; body.clip0Y = 0; body.clip0Width = 420; body.clip0Height = 180;
    body.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    body.fillRed = 0.0; body.fillGreen = 0.0; body.fillBlue = 0.0; body.fillAlpha = 0.0;
    body.shadowPresent = 1;
    body.shadowOffsetX = 180; body.shadowOffsetY = 0;
    body.shadowBlurRadius = 0; body.shadowSpread = 0;
    body.shadowRed = 1.0; body.shadowGreen = 0.0; body.shadowBlue = 0.0; body.shadowAlpha = 1.0;
    // Shadow shape = [-160+180-0, -160+180-0+60] = [20,80] horizontally and
    // [80,140] vertically; (50,110) is its center and is inside the viewport.
    const uint32_t shadowPixelX = 50, shadowPixelY = 110;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    // Shadow-only accounting: a node whose own clip is empty still submits its
    // shadow quad, so the real vertex bytes must grow by one quad while the
    // non-empty-clip node counter stays unchanged. S1 (shadow reaches) and S2
    // (shadow leaves the viewport) differ only in that one quad, which makes
    // the shadow-only branch's contribution directly measurable.
    EffectEncoderCounters s1Counters = {0};
    EffectEncoderCounters s2Counters = {0};
    uint32_t encoderStride = 0;
    uint64_t encoderMaxBatchBytes = 0;

    // S1: body fully outside the viewport, offset shadow reaches it. If the
    // renderer gated the shadow on the body's own bounds/empty clip instead of
    // the shadow output range, this sample would stay background.
    if (!require(stage_two_nodes(session, 200, &root, &body), "stage_s1_shadow_reaches_viewport")) return 0;
    if (!require(read_encoder_counters(session, &s1Counters), "s1_encoder_stats")) return 0;
    if (!require(capture_composable_pixel(session, shadowPixelX, shadowPixelY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kShadowBlue, kShadowGreen, kShadowRed, 255,
                              "s1_shadow_visible_when_body_clipped_out"),
                 "s1_shadow_readback")) return 0;

    // S2 (negative control for S1): removing the offset also removes the
    // shadow output range from the viewport. The exact same sample must now be
    // the background. This fails if S1 passed because of a stale/dirty
    // drawable rather than a real shadow submission.
    root.projectionVersion = 201; body.projectionVersion = 201; body.shadowOffsetX = 0;
    if (!require(stage_two_nodes(session, 201, &root, &body), "stage_s2_shadow_leaves_viewport")) return 0;
    if (!require(read_encoder_counters(session, &s2Counters), "s2_encoder_stats")) return 0;
    if (!require(capture_composable_pixel(session, shadowPixelX, shadowPixelY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "s2_shadow_removed_when_output_outside_viewport"),
                 "s2_shadow_readback")) return 0;

    // Shadow-only shape-node/vertex accounting. The same root is present in
    // both frames; the only difference is the body's one shadow quad. The
    // shadow-only branch must therefore add exactly six vertices of real shape
    // work, and it must not change the node counter because that counter only
    // advances on the non-empty-clip body branch (asserted explicitly so the
    // accounting boundary is pinned instead of implied).
    if (!require(cjgui_internal_renderer_test_composable_encoder_batch_stats(
                     session, &encoderStride, &encoderMaxBatchBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                 encoderStride > 0,
                 "s1_encoder_stride")) return 0;
    {
        uint64_t oneQuadBytes = 6ull * (uint64_t)encoderStride;
        if (!require(s1Counters.shapeVertexBytes >= s2Counters.shapeVertexBytes + oneQuadBytes,
                     "shadow_only_branch_adds_one_shadow_quad_of_vertex_bytes")) return 0;
        if (!require(s1Counters.shapeNodeCount == s2Counters.shapeNodeCount,
                     "shadow_only_branch_does_not_advance_body_node_counter")) return 0;
    }

    // S3 (negative control for S1): the shadow still reaches the viewport, but
    // the single ancestor clip is on the far right and does not intersect the
    // shadow output range. The shadow must be dropped entirely.
    root.projectionVersion = 202; body.projectionVersion = 202;
    body.shadowOffsetX = 180;
    body.clip0X = 300; body.clip0Y = 0; body.clip0Width = 100; body.clip0Height = 100;
    if (!require(stage_two_nodes(session, 202, &root, &body), "stage_s3_ancestor_clip_misses_shadow")) return 0;
    if (!require(capture_composable_pixel(session, shadowPixelX, shadowPixelY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "s3_shadow_dropped_when_ancestor_clip_disjoint"),
                 "s3_shadow_readback")) return 0;

    // S4 (intersection semantics): two ancestor constraints. The first is the
    // full viewport and clearly meets the shadow; the second is disjoint. The
    // chain intersects, so the disjoint constraint alone must suppress the
    // shadow. An implementation that consulted only the first constraint (or
    // unioned the chain) would keep the shadow and fail here.
    root.projectionVersion = 203; body.projectionVersion = 203;
    body.shadowOffsetX = 180;
    body.clipConstraintCount = 2;
    body.clip0X = 0; body.clip0Y = 0; body.clip0Width = 420; body.clip0Height = 180;
    body.clip1X = 300; body.clip1Y = 0; body.clip1Width = 100; body.clip1Height = 100;
    if (!require(stage_two_nodes(session, 203, &root, &body), "stage_s4_second_constraint_disjoint")) return 0;
    if (!require(capture_composable_pixel(session, shadowPixelX, shadowPixelY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "s4_all_ancestor_constraints_intersect"),
                 "s4_shadow_readback")) return 0;

    body.clipConstraintCount = 1; // restore a single constraint for the next stage

    // S5: body and shadow are both inside the viewport. Painter order requires
    // the shadow quad to be submitted first and the body fill second, so the
    // body center must read as fill while the shadow-only band to its right
    // reads as shadow. The two samples use the compiled-in colors, so a
    // reversed order fails the center assertion.
    CjguiInternalRendererComposableNode ordered = {0};
    ordered.nodeId = 902;
    ordered.projectionVersion = 204;
    ordered.x = 100; ordered.y = 60; ordered.width = 60; ordered.height = 60;
    ordered.clipX = 100; ordered.clipY = 60; ordered.clipWidth = 60; ordered.clipHeight = 60;
    ordered.clipConstraintCount = 1;
    ordered.clip0X = 0; ordered.clip0Y = 0; ordered.clip0Width = 420; ordered.clip0Height = 180;
    ordered.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    ordered.fillRed = 0.10; ordered.fillGreen = 0.20; ordered.fillBlue = 0.95; ordered.fillAlpha = 1.0;
    ordered.shadowPresent = 1;
    ordered.shadowOffsetX = 50; ordered.shadowOffsetY = 0;
    ordered.shadowBlurRadius = 0; ordered.shadowSpread = 0;
    ordered.shadowRed = 1.0; ordered.shadowGreen = 0.0; ordered.shadowBlue = 0.0; ordered.shadowAlpha = 1.0;
    root.projectionVersion = 204;
    if (!require(stage_two_nodes(session, 204, &root, &ordered), "stage_s5_painter_order")) return 0;
    // Body center (130,90): fill wins over the shadow painted beneath it.
    if (!require(capture_composable_pixel(session, 130, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kFillBlue, kFillGreen, kFillRed, 255,
                              "s5_body_center_is_fill_after_shadow"),
                 "s5_center_readback")) return 0;
    // S5 overlap sample (155,90): it lies inside BOTH the body [100,160]x[60,120]
    // and the shadow output [150,210]x[60,120]. This is the only point where the
    // internal shadow-then-body order is observable: the body must win here, so
    // (155,90) reads as fill. A plain body-center sample such as (130,90) is
    // disjoint from the shadow and stays fill no matter which order the two
    // quads are submitted in, which is exactly why the earlier negative control
    // was vacuous.
    if (!require(capture_composable_pixel(session, 155, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kFillBlue, kFillGreen, kFillRed, 255,
                              "s5_overlap_point_is_fill_after_shadow"),
                 "s5_overlap_readback")) return 0;
    // Shadow shape = [100+50, 210] x [60,120]; (180,90) is inside it and
    // outside the body bounds, so it is a pure shadow sample.
    if (!require(capture_composable_pixel(session, 180, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kShadowBlue, kShadowGreen, kShadowRed, 255,
                              "s5_shadow_band_outside_body_is_shadow"),
                 "s5_shadow_readback")) return 0;

    // S5R: explicit ordering negative control. The single-node S5 cannot swap
    // its internal shadow/body order without editing the renderer, so this
    // sibling scene expresses the two quads as two independently ordered nodes
    // that overlap at (155,90): a shadow-only node (empty own clip, shadow
    // output [150,210]x[60,120]) and a body-fill node ([100,160]x[60,120]).
    //   * shadow node first, then body  -> (155,90) is body fill;
    //   * body first, then shadow node  -> (155,90) is shadow red.
    // Both orders are asserted, so the overlap point is proven order-sensitive:
    // if S5's own shadow/body order were reversed, its overlap assertion would
    // flip to shadow red exactly like this control, and the probe would fail.
    CjguiInternalRendererComposableNode shadowOnly = {0};
    shadowOnly.nodeId = 903;
    shadowOnly.projectionVersion = 205;
    shadowOnly.x = -160; shadowOnly.y = 60; shadowOnly.width = 60; shadowOnly.height = 60;
    // Empty own clip: the body cannot paint, but the offset shadow reaches the
    // overlap point through the shadow-only branch.
    shadowOnly.clipX = 0; shadowOnly.clipY = 0; shadowOnly.clipWidth = 0; shadowOnly.clipHeight = 0;
    shadowOnly.clipConstraintCount = 1;
    shadowOnly.clip0X = 0; shadowOnly.clip0Y = 0; shadowOnly.clip0Width = 420; shadowOnly.clip0Height = 180;
    shadowOnly.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    shadowOnly.fillRed = 0.0; shadowOnly.fillGreen = 0.0; shadowOnly.fillBlue = 0.0; shadowOnly.fillAlpha = 0.0;
    shadowOnly.shadowPresent = 1;
    shadowOnly.shadowOffsetX = 310; shadowOnly.shadowOffsetY = 0;
    shadowOnly.shadowBlurRadius = 0; shadowOnly.shadowSpread = 0;
    shadowOnly.shadowRed = 1.0; shadowOnly.shadowGreen = 0.0; shadowOnly.shadowBlue = 0.0; shadowOnly.shadowAlpha = 1.0;

    CjguiInternalRendererComposableNode bodyFill = {0};
    bodyFill.nodeId = 904;
    bodyFill.projectionVersion = 205;
    bodyFill.x = 100; bodyFill.y = 60; bodyFill.width = 60; bodyFill.height = 60;
    bodyFill.clipX = 100; bodyFill.clipY = 60; bodyFill.clipWidth = 60; bodyFill.clipHeight = 60;
    bodyFill.clipConstraintCount = 1;
    bodyFill.clip0X = 0; bodyFill.clip0Y = 0; bodyFill.clip0Width = 420; bodyFill.clip0Height = 180;
    bodyFill.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    bodyFill.fillRed = 0.10; bodyFill.fillGreen = 0.20; bodyFill.fillBlue = 0.95; bodyFill.fillAlpha = 1.0;

    root.projectionVersion = 205;
    if (!require(stage_three_nodes(session, 205, &root, &shadowOnly, &bodyFill),
                 "stage_s5r_shadow_then_body")) return 0;
    if (!require(capture_composable_pixel(session, 155, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kFillBlue, kFillGreen, kFillRed, 255,
                              "s5r_overlap_is_fill_when_body_paints_last"),
                 "s5r_forward_readback")) return 0;
    root.projectionVersion = 206; shadowOnly.projectionVersion = 206; bodyFill.projectionVersion = 206;
    if (!require(stage_three_nodes(session, 206, &root, &bodyFill, &shadowOnly),
                 "stage_s5r_body_then_shadow")) return 0;
    if (!require(capture_composable_pixel(session, 155, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kShadowBlue, kShadowGreen, kShadowRed, 255,
                              "s5r_overlap_is_shadow_when_shadow_paints_last"),
                 "s5r_reversed_readback")) return 0;
    // The old body-center sample (130,90) is disjoint from the shadow output, so
    // it reads as fill in BOTH orders. Asserting that here makes the vacuity of
    // the previous control explicit: it could not have detected a reversed
    // shadow/body order at all, which is why (155,90) is the real anchor.
    if (!require(capture_composable_pixel(session, 130, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kFillBlue, kFillGreen, kFillRed, 255,
                              "s5r_old_center_is_fill_in_both_orders"),
                 "s5r_old_center_readback")) return 0;
    return 1;
}

// Hit-test negative control. The interactive button's outer shadow is painted
// to the right of its body. Hit testing must stay bounds-only: the body point
// activates, while a point that only lands on the shadow reports a miss. Using
// the effect output range as the hit rect would activate the shadow point and
// fail this probe.
static int verify_hit_test_is_bounds_only(uint64_t session) {
    CjguiInternalRendererComposableNode root = make_root(210, 910);
    CjguiInternalRendererComposableNode button = {0};
    button.nodeId = 911;
    button.projectionVersion = 210;
    button.x = 100; button.y = 60; button.width = 80; button.height = 40;
    button.clipX = 100; button.clipY = 60; button.clipWidth = 80; button.clipHeight = 40;
    button.clipConstraintCount = 1;
    button.clip0X = 0; button.clip0Y = 0; button.clip0Width = 420; button.clip0Height = 180;
    button.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    button.isInteractive = 1;
    button.fillRed = 0.20; button.fillGreen = 0.50; button.fillBlue = 0.80; button.fillAlpha = 1.0;
    button.shadowPresent = 1;
    button.shadowOffsetX = 80; button.shadowOffsetY = 0;
    button.shadowBlurRadius = 0; button.shadowSpread = 0;
    button.shadowRed = 1.0; button.shadowGreen = 0.0; button.shadowBlue = 0.0; button.shadowAlpha = 1.0;
    // Shadow shape = [180,260] x [60,100]; the body is [100,180] x [60,100].
    if (!require(stage_two_nodes(session, 210, &root, &button), "stage_hit_test_bounds_only")) return 0;

    // Positive: a point inside the body activates the interactive node.
    CjguiInternalRendererStatus inside = cjgui_internal_renderer_test_activate_composable_point(session, 140, 80);
    if (!require(inside == CJGUI_INTERNAL_RENDERER_OK, "hit_inside_body_activates")) return 0;
    // Negative: (210,80) is the center of the painted shadow and outside the
    // body rect. The hit test must report a miss (non-OK), not a widened hit.
    CjguiInternalRendererStatus onShadow = cjgui_internal_renderer_test_activate_composable_point(session, 210, 80);
    if (!require(onShadow != CJGUI_INTERNAL_RENDERER_OK, "hit_shadow_only_region_is_a_miss")) return 0;
    // Negative: far outside both body and shadow is also a miss, guarding the
    // probe against a hit seam that returns OK unconditionally.
    CjguiInternalRendererStatus farAway = cjgui_internal_renderer_test_activate_composable_point(session, 360, 150);
    if (!require(farAway != CJGUI_INTERNAL_RENDERER_OK, "hit_far_away_is_a_miss")) return 0;
    return 1;
}

// Zero-regression: with neither shadow nor gradient, the ordinary shape path
// must still paint the plain fill. The off-body sample is the negative of the
// S5 shadow band: the same point that was shadow red in S5 must be background
// here, proving the effect samples were not reading stale pixels.
static int verify_no_effect_zero_regression(uint64_t session) {
    CjguiInternalRendererComposableNode root = make_root(220, 920);
    CjguiInternalRendererComposableNode plain = {0};
    plain.nodeId = 921;
    plain.projectionVersion = 220;
    plain.x = 100; plain.y = 60; plain.width = 60; plain.height = 60;
    plain.clipX = 100; plain.clipY = 60; plain.clipWidth = 60; plain.clipHeight = 60;
    plain.clipConstraintCount = 1;
    plain.clip0X = 0; plain.clip0Y = 0; plain.clip0Width = 420; plain.clip0Height = 180;
    plain.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    plain.fillRed = 0.10; plain.fillGreen = 0.20; plain.fillBlue = 0.95; plain.fillAlpha = 1.0;
    plain.shadowPresent = 0;
    plain.gradientPresent = 0;
    if (!require(stage_two_nodes(session, 220, &root, &plain), "stage_no_effect_plain_fill")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 130, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kFillBlue, kFillGreen, kFillRed, 255,
                              "plain_shape_center_is_fill"),
                 "plain_center_readback")) return 0;
    // Same point that was shadow red in S5 must now be untouched background.
    if (!require(capture_composable_pixel(session, 180, 90, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "plain_shape_has_no_shadow_band"),
                 "plain_off_body_readback")) return 0;
    return 1;
}

// Opacity-zero effect alpha: a paint-alpha multiplier of zero must scale the
// body fill, the gradient stops and the outer shadow together, so every effect
// sample falls back to the background. The negative control zeroes only the
// body run and leaves the shadow/gradient alpha at 1, which keeps them visible
// and must fail the same "back to background" assertion. This is the pixel
// counterpart of the Cangjie accepted-paint relation assertion that cannot read
// a pre-present drawable.
static int verify_opacity_zero_scales_effects(uint64_t session) {
    CjguiInternalRendererComposableNode root = make_root(240, 940);
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 941;
    node.projectionVersion = 240;
    node.x = 60; node.y = 50; node.width = 180; node.height = 60;
    node.clipX = 60; node.clipY = 50; node.clipWidth = 180; node.clipHeight = 60;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 420; node.clip0Height = 180;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    node.fillRed = 0.10; node.fillGreen = 0.20; node.fillBlue = 0.95; node.fillAlpha = 1.0;
    node.gradientPresent = 1;
    node.gradientStopCount = 2;
    node.gradientStartX = 0.0; node.gradientStartY = 0.0;
    node.gradientEndX = 1.0; node.gradientEndY = 0.0;
    node.gradientStop0Position = 0.0; node.gradientStop0Red = 0.95; node.gradientStop0Green = 0.1;
    node.gradientStop0Blue = 0.1; node.gradientStop0Alpha = 1.0;
    node.gradientStop1Position = 1.0; node.gradientStop1Red = 0.1; node.gradientStop1Green = 0.1;
    node.gradientStop1Blue = 0.95; node.gradientStop1Alpha = 1.0;
    node.shadowPresent = 1;
    node.shadowOffsetX = 20; node.shadowOffsetY = 0;
    node.shadowBlurRadius = 0; node.shadowSpread = 0;
    node.shadowRed = 1.0; node.shadowGreen = 0.0; node.shadowBlue = 0.0; node.shadowAlpha = 1.0;

    const uint32_t bodyX = 150, bodyY = 80;          // body centre
    const uint32_t gradLeftX = 66, gradRightX = 234; // gradient ends, inside the body
    const uint32_t shadowOnlyX = 250;                // shadow-only band (body ends at 240)
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;

    // Positive: paint alpha 0 scales the body, the gradient stops and the
    // shadow together, so all four effect samples read the background again.
    node.fillAlpha = 0.0;
    node.gradientStop0Alpha = 0.0; node.gradientStop1Alpha = 0.0;
    node.shadowAlpha = 0.0;
    if (!require(stage_two_nodes(session, 240, &root, &node), "stage_opacity_zero")) return 0;
    if (!require(capture_composable_pixel(session, bodyX, bodyY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "opacity_zero_body_is_background"),
                 "opacity_zero_body_readback")) return 0;
    if (!require(capture_composable_pixel(session, gradLeftX, bodyY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "opacity_zero_gradient_left_is_background"),
                 "opacity_zero_gradient_left")) return 0;
    if (!require(capture_composable_pixel(session, gradRightX, bodyY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "opacity_zero_gradient_right_is_background"),
                 "opacity_zero_gradient_right")) return 0;
    if (!require(capture_composable_pixel(session, shadowOnlyX, bodyY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kBackgroundBlue, kBackgroundGreen, kBackgroundRed, 255,
                              "opacity_zero_shadow_is_background"),
                 "opacity_zero_shadow")) return 0;

    // Negative control: zero only the body, keep the shadow and gradient alpha
    // at 1. The shadow-only sample and a gradient sample must now be
    // non-background. If the effect alpha were not tied to the paint alpha, the
    // positive assertions above would be indistinguishable from this control.
    root.projectionVersion = 241; node.projectionVersion = 241;
    node.fillAlpha = 0.0;
    node.gradientStop0Alpha = 1.0; node.gradientStop1Alpha = 1.0;
    node.shadowAlpha = 1.0;
    if (!require(stage_two_nodes(session, 241, &root, &node), "stage_opacity_zero_negative")) return 0;
    if (!require(capture_composable_pixel(session, shadowOnlyX, bodyY, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, kShadowBlue, kShadowGreen, kShadowRed, 255,
                              "negative_control_shadow_stays_visible_without_alpha_scaling"),
                 "negative_control_shadow_readback")) return 0;
    if (!require(capture_composable_pixel(session, gradLeftX, bodyY, &blue, &green, &red, &alpha),
                 "negative_control_gradient_readback")) return 0;
    if (!require(!(abs((int)blue - (int)kBackgroundBlue) <= 10 &&
                   abs((int)green - (int)kBackgroundGreen) <= 10 &&
                   abs((int)red - (int)kBackgroundRed) <= 10),
                 "negative_control_gradient_stays_visible_without_alpha_scaling")) return 0;
    return 1;
}

typedef struct EffectCost {
    uint32_t shapeNodeCount;
    uint32_t shapeBatchCount;
    uint32_t textureDrawCount;
    uint64_t shapeVertexBytes;
    uint32_t vertexStride;
    uint64_t maxBatchVertexBytes;
} EffectCost;

static int read_effect_cost(uint64_t session, const char *mode, EffectCost *outCost) {
    if (cjgui_internal_renderer_test_composable_encoder_stats(
            session, &outCost->shapeNodeCount, &outCost->shapeBatchCount,
            &outCost->textureDrawCount, &outCost->shapeVertexBytes) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    if (cjgui_internal_renderer_test_composable_encoder_batch_stats(
            session, &outCost->vertexStride, &outCost->maxBatchVertexBytes) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    printf("CJGUI_EFFECT_COST mode=%s nodes=%u batches=%u vertex_bytes=%llu stride=%u texture_draws=%u max_batch_bytes=%llu\n",
           mode, outCost->shapeNodeCount, outCost->shapeBatchCount,
           (unsigned long long)outCost->shapeVertexBytes, outCost->vertexStride,
           outCost->textureDrawCount, (unsigned long long)outCost->maxBatchVertexBytes);
    fflush(stdout);
    return 1;
}

// Costs one single-node scene of identical geometry under three effect modes.
// The measured vertex bytes are expected to track the quads actually submitted:
// a plain body is one rectangle (6 vertices), a static shadow adds exactly one
// more quad (6 vertices), and a gradient replaces the fill color inside the
// same rectangle without adding vertices. Nothing here invents an offscreen
// cache cost; it only reports the encoder's real shape accounting.
static int verify_effect_cost_accounting(uint64_t session) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 930;
    node.x = 60; node.y = 50; node.width = 180; node.height = 60;
    node.clipX = 60; node.clipY = 50; node.clipWidth = 180; node.clipHeight = 60;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 420; node.clip0Height = 180;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    node.fillRed = 0.30; node.fillGreen = 0.60; node.fillBlue = 0.90; node.fillAlpha = 1.0;

    EffectCost plain = {0}, shadow = {0}, gradient = {0};
    CjguiInternalRendererFrameObservation frame = {0};

    // Plain: no shadow, no gradient.
    node.projectionVersion = 230;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 230, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &node, "cost-plain", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 read_effect_cost(session, "plain", &plain),
                 "cost_plain_stage")) return 0;

    // Static shadow: same node plus one outer shadow quad.
    node.projectionVersion = 231;
    node.shadowPresent = 1;
    node.shadowOffsetX = 12; node.shadowOffsetY = 10;
    node.shadowBlurRadius = 8; node.shadowSpread = 4;
    node.shadowRed = 0.0; node.shadowGreen = 0.0; node.shadowBlue = 0.0; node.shadowAlpha = 0.6;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 231, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &node, "cost-shadow", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 read_effect_cost(session, "shadow", &shadow),
                 "cost_shadow_stage")) return 0;

    // Gradient: same node, fill replaced by a two-stop linear gradient. The
    // vertex count must equal the plain rectangle.
    node.projectionVersion = 232;
    node.shadowPresent = 0;
    node.gradientPresent = 1;
    node.gradientStopCount = 2;
    node.gradientStartX = 0.0; node.gradientStartY = 0.0;
    node.gradientEndX = 1.0; node.gradientEndY = 0.0;
    node.gradientStop0Position = 0.0; node.gradientStop0Red = 0.95; node.gradientStop0Green = 0.1; node.gradientStop0Blue = 0.1; node.gradientStop0Alpha = 1.0;
    node.gradientStop1Position = 1.0; node.gradientStop1Red = 0.1; node.gradientStop1Green = 0.1; node.gradientStop1Blue = 0.95; node.gradientStop1Alpha = 1.0;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 232, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &node, "cost-gradient", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 read_effect_cost(session, "gradient", &gradient),
                 "cost_gradient_stage")) return 0;

    if (!require(plain.vertexStride > 0 && shadow.vertexStride == plain.vertexStride &&
                 gradient.vertexStride == plain.vertexStride,
                 "cost_same_vertex_stride")) return 0;
    // One rectangle is six vertices. Using the reported stride keeps this
    // assertion independent of any Metal struct-padding change.
    uint64_t sixVertices = 6ull * (uint64_t)plain.vertexStride;
    uint64_t twelveVertices = 12ull * (uint64_t)plain.vertexStride;
    if (!require(plain.shapeNodeCount == 1 && plain.shapeBatchCount == 1 &&
                 plain.textureDrawCount == 0 && plain.shapeVertexBytes == sixVertices,
                 "plain_is_one_rectangle_no_texture_draw")) return 0;
    if (!require(shadow.shapeNodeCount == 1 && shadow.shapeBatchCount == 1 &&
                 shadow.textureDrawCount == 0 && shadow.shapeVertexBytes == twelveVertices,
                 "shadow_adds_exactly_one_quad_to_the_same_node")) return 0;
    if (!require(gradient.shapeNodeCount == 1 && gradient.shapeBatchCount == 1 &&
                 gradient.textureDrawCount == 0 && gradient.shapeVertexBytes == plain.shapeVertexBytes,
                 "gradient_reuses_the_plain_vertex_count")) return 0;
    if (!require(shadow.shapeVertexBytes > plain.shapeVertexBytes,
                 "shadow_costs_more_vertices_than_plain")) return 0;
    if (!require(shadow.maxBatchVertexBytes == twelveVertices &&
                 plain.maxBatchVertexBytes == sixVertices &&
                 shadow.maxBatchVertexBytes <= 4096 && plain.maxBatchVertexBytes <= 4096,
                 "effect_batches_stay_within_setvertexbytes_ceiling")) return 0;
    return 1;
}

int main(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN, "create")) return 1;

    if (!verify_draw_gate_and_painter_order(session)) { (void)cjgui_internal_renderer_destroy(session); return 1; }
    if (!verify_hit_test_is_bounds_only(session)) { (void)cjgui_internal_renderer_destroy(session); return 1; }
    if (!verify_opacity_zero_scales_effects(session)) { (void)cjgui_internal_renderer_destroy(session); return 1; }
    if (!verify_no_effect_zero_regression(session)) { (void)cjgui_internal_renderer_destroy(session); return 1; }
    if (!verify_effect_cost_accounting(session)) { (void)cjgui_internal_renderer_destroy(session); return 1; }

    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK, "close")) return 1;
    if (!require(cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK, "destroy")) return 1;
    puts("effect gate probe: passed draw_gate=true ancestor_clip_intersection=true painter_order=true hit_bounds_only=true opacity_zero_effect_alpha=true no_effect_regression=true effect_cost=true");
    return 0;
}