// Temporary guest probe (NOT in the repository): drives the real Linux C ABI
// sidecar with a multi-slot rectangular clip chain. The expected rectangles are
// stated independently below and checked against a root-window screenshot, so
// this measures painted pixels rather than a value read back from the code.
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "cjgui_internal_renderer.h"

static int set_node(uint64_t session, uint32_t index, CjguiInternalRendererComposableNode *node,
                    const CjguiInternalRendererComposableGeometry *geometry) {
    int status = (int)cjgui_internal_renderer_set_composable_scene_node(
        session, index, node, "", "", "", "", 0u);
    if (status != 0) { fprintf(stderr, "set_node %u status=%d\n", index, status); return 0; }
    status = (int)cjgui_internal_renderer_set_composable_scene_geometry(
        session, 101u, index, geometry);
    if (status != 0) { fprintf(stderr, "set_geometry %u status=%d\n", index, status); return 0; }
    return 1;
}

static void base_node(CjguiInternalRendererComposableNode *node, uint64_t id,
                      double x, double y, double w, double h) {
    memset(node, 0, sizeof(*node));
    node->nodeId = id;
    node->nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    node->x = x; node->y = y; node->width = w; node->height = h;
    node->fillAlpha = 1.0;
}

int main(void) {
    CjguiInternalRendererConfig config;
    memset(&config, 0, sizeof(config));
    config.windowWidth = 640u;
    config.windowHeight = 480u;
    config.clearColorRed = 0.06;
    config.clearColorGreen = 0.06;
    config.clearColorBlue = 0.09;
    config.clearColorAlpha = 1.0;
    CjguiInternalRendererStatus createStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session = cjgui_internal_renderer_create(&config, &createStatus);
    if (session == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        fprintf(stderr, "create failed status=%d\n", (int)createStatus);
        return 2;
    }
    int status = (int)cjgui_internal_renderer_configure_composable_scene(session, 101u, 5u);
    if (status != 0) { fprintf(stderr, "configure status=%d\n", status); return 3; }

    CjguiInternalRendererComposableGeometry geometry;

    // 1. Two-slot chain: node rect (40,40,200,140), clip0 = node rect,
    //    clip1 (100,70,120,80) => painted red only in (100..220, 70..150).
    CjguiInternalRendererComposableNode chain;
    base_node(&chain, 1u, 40, 40, 200, 140);
    chain.fillRed = 0.90; chain.fillGreen = 0.20; chain.fillBlue = 0.20;
    chain.clipConstraintCount = 2u;
    chain.clip0X = 40; chain.clip0Y = 40; chain.clip0Width = 200; chain.clip0Height = 140;
    chain.clip1X = 100; chain.clip1Y = 70; chain.clip1Width = 120; chain.clip1Height = 80;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = chain.nodeId; geometry.clipCount = 2u;
    geometry.scaleX = 1.0; geometry.scaleY = 1.0;
    if (!set_node(session, 0u, &chain, &geometry)) return 4;

    // 2. Owner translation: node rect (300,40,200,140), clip0 = node rect,
    //    clip1 (0,0,140,80) shifted by the sidecar to (340,120) =>
    //    painted green only in (340..480, 120..180).
    CjguiInternalRendererComposableNode shifted;
    base_node(&shifted, 2u, 300, 40, 200, 140);
    shifted.fillRed = 0.20; shifted.fillGreen = 0.85; shifted.fillBlue = 0.35;
    shifted.clipConstraintCount = 2u;
    shifted.clip0X = 300; shifted.clip0Y = 40; shifted.clip0Width = 200; shifted.clip0Height = 140;
    shifted.clip1X = 0; shifted.clip1Y = 0; shifted.clip1Width = 140; shifted.clip1Height = 80;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = shifted.nodeId; geometry.clipCount = 2u;
    geometry.clip1X = 340; geometry.clip1Y = 120;
    geometry.scaleX = 1.0; geometry.scaleY = 1.0;
    if (!set_node(session, 1u, &shifted, &geometry)) return 5;

    // 3. Disjoint chain: node rect (40,240,200,140) with clip0 (40,240,80,80)
    //    and clip1 (150,300,80,80) never overlap => no blue pixel at all.
    CjguiInternalRendererComposableNode disjoint;
    base_node(&disjoint, 3u, 40, 240, 200, 140);
    disjoint.fillRed = 0.25; disjoint.fillGreen = 0.45; disjoint.fillBlue = 0.95;
    disjoint.clipConstraintCount = 2u;
    disjoint.clip0X = 40; disjoint.clip0Y = 240; disjoint.clip0Width = 80; disjoint.clip0Height = 80;
    disjoint.clip1X = 150; disjoint.clip1Y = 300; disjoint.clip1Width = 80; disjoint.clip1Height = 80;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = disjoint.nodeId; geometry.clipCount = 2u;
    geometry.scaleX = 1.0; geometry.scaleY = 1.0;
    if (!set_node(session, 2u, &disjoint, &geometry)) return 6;

    // 4. Legacy single clip (clipConstraintCount 0): node rect (300,240,200,140),
    //    legacy clip (360,280,80,60) => yellow only in (360..440, 280..340).
    CjguiInternalRendererComposableNode legacy;
    base_node(&legacy, 4u, 300, 240, 200, 140);
    legacy.fillRed = 0.95; legacy.fillGreen = 0.85; legacy.fillBlue = 0.25;
    legacy.clipX = 360; legacy.clipY = 280; legacy.clipWidth = 80; legacy.clipHeight = 60;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = legacy.nodeId; geometry.clipCount = 0u;
    geometry.scaleX = 1.0; geometry.scaleY = 1.0;
    if (!set_node(session, 3u, &legacy, &geometry)) return 7;

    // 5. Control: unclipped white strip must paint.
    CjguiInternalRendererComposableNode control;
    base_node(&control, 5u, 40, 400, 200, 40);
    control.fillRed = 0.95; control.fillGreen = 0.95; control.fillBlue = 0.95;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = control.nodeId; geometry.clipCount = 0u;
    geometry.scaleX = 1.0; geometry.scaleY = 1.0;
    if (!set_node(session, 4u, &control, &geometry)) return 8;

    uint64_t frames = 0u;
    for (int i = 0; i < 150; i += 1) {
        CjguiInternalRendererFrameObservation observation;
        memset(&observation, 0, sizeof(observation));
        int present = (int)cjgui_internal_renderer_present_composable_scene(session, &observation);
        if (present != 0) { fprintf(stderr, "present status=%d\n", present); break; }
        frames += 1u;
        usleep(30000);
    }
    printf("PROBE frames=%llu\n", (unsigned long long)frames);
    fflush(stdout);
    cjgui_internal_renderer_destroy(session);
    return 0;
}
