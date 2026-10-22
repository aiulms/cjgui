// Focused real-Vulkan probe for image upload staging and texture retirement:
//  * staging is released once its own upload submission is fence-proven;
//  * a never-drawn retired texture is reclaimed without any draw frame;
//  * a drawn retired texture is reclaimed by polling the exact frame submission
//    that used it, without submitting an extra frame;
//  * upload-slot reuse does not let a new fence free/keep the wrong generation;
//  * frame-slot reuse still proves the old draw submission by its serial.
// It uses a real X11 window and the production GPU backend (llvmpipe on the
// guest), so ordering is checked against real fences rather than stubs.
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "../native/cjgui_linux_window.h"
#include "../native/cjgui_linux_vulkan.h"

static int failures = 0;

static void check(int condition, const char *name) {
    printf("GPU LIFECYCLE %s %s\n", condition ? "PASS" : "FAIL", name);
    if (!condition) failures += 1;
}

// 只轮询真实 fence 维护点，不提交额外帧；usleep 仅作为等待 fence 的轮询间隔。
static int wait_reclaimed(CjguiLinuxGpu *gpu, uint64_t reclaims, int stagingZero, int timeoutMs) {
    for (int i = 0; i < timeoutMs; i += 1) {
        cjgui_linux_gpu_pump_image_resources(gpu);
        int reused = cjgui_linux_gpu_image_reclaim_count(gpu) >= reclaims;
        int staging = !stagingZero || cjgui_linux_gpu_image_staging_bytes(gpu) == 0u;
        if (reused && staging) return 1;
        usleep(1000);
    }
    cjgui_linux_gpu_pump_image_resources(gpu);
    return cjgui_linux_gpu_image_reclaim_count(gpu) >= reclaims &&
           (!stagingZero || cjgui_linux_gpu_image_staging_bytes(gpu) == 0u);
}

static int wait_staging_zero(CjguiLinuxGpu *gpu, int timeoutMs) {
    for (int i = 0; i < timeoutMs; i += 1) {
        cjgui_linux_gpu_pump_image_resources(gpu);
        if (cjgui_linux_gpu_image_staging_bytes(gpu) == 0u) return 1;
        usleep(1000);
    }
    cjgui_linux_gpu_pump_image_resources(gpu);
    return cjgui_linux_gpu_image_staging_bytes(gpu) == 0u;
}

static int run_frame(CjguiLinuxGpu *gpu) {
    float clear[4] = {0.02f, 0.03f, 0.06f, 1.0f};
    int status = cjgui_linux_gpu_begin_frame(gpu, clear);
    if (status != CJGUI_LINUX_GPU_OK) return status;
    int end = cjgui_linux_gpu_end_frame(gpu);
    // SUBOPTIMAL 表示本帧已提交并呈现，只是交换链需要随后重建；对生命周期
    // 检查而言仍是一次真实提交。
    return (end == CJGUI_LINUX_GPU_OK || end == CJGUI_LINUX_GPU_SUBOPTIMAL) ? CJGUI_LINUX_GPU_OK
                                                                            : end;
}

static int draw_image_frame(CjguiLinuxGpu *gpu, uint32_t slot) {
    float clear[4] = {0.02f, 0.03f, 0.06f, 1.0f};
    if (cjgui_linux_gpu_begin_frame(gpu, clear) != CJGUI_LINUX_GPU_OK) return CJGUI_LINUX_GPU_INVALID;
    CjguiLinuxGpuVertex vertices[6] = {
        {20.0f, 20.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f},
        {120.0f, 20.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f},
        {20.0f, 120.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f},
        {120.0f, 20.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f},
        {120.0f, 120.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f},
        {20.0f, 120.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f},
    };
    int status = cjgui_linux_gpu_draw_image_triangles(gpu, slot, vertices, 6u);
    if (status != CJGUI_LINUX_GPU_OK) return status;
    int end = cjgui_linux_gpu_end_frame(gpu);
    return (end == CJGUI_LINUX_GPU_OK || end == CJGUI_LINUX_GPU_SUBOPTIMAL) ? CJGUI_LINUX_GPU_OK : end;
}

int main(void) {
    int status = 0;
    CjguiLinuxWindow *window =
        cjgui_linux_window_create(320, 240, "CJGUI Image GPU Lifecycle", &status);
    check(window != NULL, "window_create");
    if (window == NULL) return 1;
    for (int i = 0; i < 20; i += 1) {
        (void)cjgui_linux_window_pump(window, NULL, 0, 10, NULL);
    }
    cjgui_linux_window_sync(window);

    CjguiLinuxGpu *gpu = cjgui_linux_gpu_create(window, &status);
    check(gpu != NULL, "gpu_create");
    if (gpu == NULL) {
        cjgui_linux_window_destroy(window);
        return 1;
    }

    uint8_t rgba[4u * 4u * 4u];
    for (uint32_t i = 0u; i < sizeof(rgba); i += 4u) {
        rgba[i + 0u] = (uint8_t)(40u + i);
        rgba[i + 1u] = 160u;
        rgba[i + 2u] = 90u;
        rgba[i + 3u] = 255u;
    }
    const uint64_t imageBytes = 4u * 4u * 4u;

    // A: upload + retire before any frame. Reclaim needs upload proof only;
    // no draw frame is submitted.
    check(cjgui_linux_gpu_upload_image(gpu, 0u, 4u, 4u, rgba) == CJGUI_LINUX_GPU_OK,
          "preframe_upload");
    cjgui_linux_gpu_release_image(gpu, 0u);
    check(cjgui_linux_gpu_image_retire_count(gpu) == 1u, "preframe_retired");
    check(cjgui_linux_gpu_image_reclaim_count(gpu) == 0u, "preframe_not_reclaimed_before_proof");
    check(wait_reclaimed(gpu, 1u, 1, 5000), "preframe_reclaimed_without_draw_frame");
    check(cjgui_linux_gpu_image_staging_bytes(gpu) == 0u, "preframe_staging_released");
    check(cjgui_linux_gpu_image_texture_bytes(gpu) == 0u, "preframe_no_live_image_textures");
    check(cjgui_linux_gpu_image_retired_bytes(gpu) == 0u, "preframe_no_retired_bytes");
    check(run_frame(gpu) == CJGUI_LINUX_GPU_OK, "baseline_frame");

    // B: upload, draw in one frame (serial 1), retire. Reclaim by polling that
    // exact frame fence; do not submit another frame.
    check(cjgui_linux_gpu_upload_image(gpu, 1u, 4u, 4u, rgba) == CJGUI_LINUX_GPU_OK,
          "draw_upload");
    check(draw_image_frame(gpu, 1u) == CJGUI_LINUX_GPU_OK, "draw_image_frame");
    check(cjgui_linux_gpu_image_staging_bytes(gpu) == imageBytes,
          "draw_staging_retained_until_upload_fence");
    cjgui_linux_gpu_release_image(gpu, 1u);
    check(cjgui_linux_gpu_image_retire_count(gpu) == 2u, "draw_texture_retired");
    check(wait_reclaimed(gpu, 2u, 1, 5000), "draw_reclaimed_without_extra_frame");
    check(cjgui_linux_gpu_image_last_reclaim_serial(gpu) == 1u,
          "draw_reclaim_uses_submitted_serial");
    check(cjgui_linux_gpu_image_texture_bytes(gpu) == 0u, "draw_no_live_image_textures");

    // C: upload-slot reuse. Four uploads into five image slots cycle the three
    // upload slots; a fifth upload must keep its own staging until its own
    // fence completes, not inherit the reused slot's old completion.
    for (uint32_t slot = 0u; slot < 4u; slot += 1u) {
        check(cjgui_linux_gpu_upload_image(gpu, slot, 4u, 4u, rgba) == CJGUI_LINUX_GPU_OK,
              "reuse_upload");
    }
    check(wait_staging_zero(gpu, 5000), "reuse_initial_staging_released");
    check(cjgui_linux_gpu_image_texture_bytes(gpu) == 4u * imageBytes,
          "reuse_four_live_textures");
    check(cjgui_linux_gpu_upload_image(gpu, 4u, 4u, 4u, rgba) == CJGUI_LINUX_GPU_OK,
          "reuse_fifth_upload");
    check(cjgui_linux_gpu_image_staging_bytes(gpu) == imageBytes,
          "reuse_new_generation_staging_not_freed_by_old_fence");
    check(wait_staging_zero(gpu, 5000), "reuse_new_generation_staging_released");
    check(cjgui_linux_gpu_image_texture_bytes(gpu) == 5u * imageBytes,
          "reuse_five_live_textures");
    cjgui_linux_gpu_release_image(gpu, 0u);
    check(wait_reclaimed(gpu, 3u, 1, 5000), "reuse_never_drawn_reclaimed_without_frame");
    check(cjgui_linux_gpu_image_texture_bytes(gpu) == 4u * imageBytes,
          "reuse_after_unused_reclaim");

    // D: frame-slot reuse. The texture is used by submission serial 2 in slot 0;
    // later frames reuse slot 0. Reclaim must cite serial 2, not the new one.
    check(cjgui_linux_gpu_upload_image(gpu, 5u, 4u, 4u, rgba) == CJGUI_LINUX_GPU_OK,
          "generation_upload");
    check(draw_image_frame(gpu, 5u) == CJGUI_LINUX_GPU_OK, "generation_draw_frame2");
    cjgui_linux_gpu_release_image(gpu, 5u);
    check(cjgui_linux_gpu_image_reclaim_count(gpu) == 3u, "generation_not_reclaimed_early");
    check(run_frame(gpu) == CJGUI_LINUX_GPU_OK, "generation_frame3");
    check(run_frame(gpu) == CJGUI_LINUX_GPU_OK, "generation_frame4_reuses_slot");
    check(cjgui_linux_gpu_image_reclaim_count(gpu) == 4u,
          "generation_reclaimed_after_reused_slot_wait");
    check(cjgui_linux_gpu_image_last_reclaim_serial(gpu) == 2u,
          "generation_reclaim_uses_old_serial");
    check(cjgui_linux_gpu_image_staging_bytes(gpu) == 0u, "generation_staging_released");
    check(cjgui_linux_gpu_image_texture_bytes(gpu) == 4u * imageBytes,
          "generation_live_textures_unchanged");

    cjgui_linux_gpu_destroy(gpu);
    cjgui_linux_window_destroy(window);
    printf("GPU LIFECYCLE RESULT %s failures=%d\n", failures == 0 ? "PASS" : "FAIL", failures);
    return failures == 0 ? 0 : 1;
}
