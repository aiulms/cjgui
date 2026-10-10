// Standing harness stub for the two production FFIs used by the extracted
// freeze path. Mirrors the r23-review native-hit-stub pattern: controllable
// accepted-scene generation, fixed-offset OK hit, SCENE_STALE (33) on mismatch.
#include <stdint.h>

static uint64_t g_scene_gen = 7;
static uint32_t g_offset = 2;

void stub_set_scene_gen(uint64_t v) { g_scene_gen = v; }

int32_t cjgui_internal_renderer_accepted_scene_version(uint64_t session, uint64_t *out) {
    (void)session;
    if (!out) return 2;
    *out = g_scene_gen;
    return 0;
}

int32_t cjgui_internal_renderer_hit_test_composable_text(uint64_t session, uint64_t nodeId,
    double x, double y, uint64_t expectedSceneVersion, uint32_t *outByte, uint32_t *outAff) {
    (void)session; (void)nodeId; (void)x; (void)y;
    if (!outByte || !outAff) return 2;
    *outByte = 0;
    *outAff = 0;
    if (expectedSceneVersion != g_scene_gen) return 33;
    *outByte = g_offset;
    return 0;
}
