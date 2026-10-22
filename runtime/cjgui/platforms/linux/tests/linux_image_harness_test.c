// Focused native harness for the Linux local-PNG resource domain:
// real libpng decode, bounded cache, version replacement, failure states,
// duplicate-request suppression and worker teardown. GPU upload is stubbed:
// texture upload/draw is covered by the real application chain.
#include <errno.h>
#include <png.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

// 线程创建/join 注入点：只在 harness 内替换 image.c 的调用，生产代码不变。
static int g_createAttempts = 0;
static int g_failCreateAt = -1;
static int g_joinCalls = 0;

static int test_pthread_create(pthread_t *thread, const pthread_attr_t *attr,
                               void *(*start)(void *), void *arg) {
    int attempt = g_createAttempts;
    g_createAttempts += 1;
    if (attempt == g_failCreateAt) return EAGAIN;
    return pthread_create(thread, attr, start, arg);
}

static int test_pthread_join(pthread_t thread, void **retval) {
    g_joinCalls += 1;
    return pthread_join(thread, retval);
}

#define pthread_create test_pthread_create
#define pthread_join test_pthread_join
#define CJGUI_LINUX_IMAGE_TEST_HOOKS 1

struct CjguiLinuxImageDomain;
static void test_hold_after_decode(struct CjguiLinuxImageDomain *domain);

#include "../native/cjgui_linux_image.c"

#undef pthread_create
#undef pthread_join

// 受控同步：worker 已解码完成、尚未把 request/pixels 移交完成队列时停在这里。
static pthread_mutex_t g_gateMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t g_gateCond = PTHREAD_COND_INITIALIZER;
static int g_gateEntered = 0;
static int g_gateRelease = 0;

static void test_hold_after_decode(struct CjguiLinuxImageDomain *domain) {
    (void)domain;
    pthread_mutex_lock(&g_gateMutex);
    g_gateEntered = 1;
    pthread_cond_broadcast(&g_gateCond);
    while (!g_gateRelease) pthread_cond_wait(&g_gateCond, &g_gateMutex);
    pthread_mutex_unlock(&g_gateMutex);
}

static int wait_gate_entered(int timeoutMs) {
    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += timeoutMs / 1000;
    deadline.tv_nsec += (long)(timeoutMs % 1000) * 1000000L;
    if (deadline.tv_nsec >= 1000000000L) {
        deadline.tv_sec += 1;
        deadline.tv_nsec -= 1000000000L;
    }
    pthread_mutex_lock(&g_gateMutex);
    while (!g_gateEntered) {
        if (pthread_cond_timedwait(&g_gateCond, &g_gateMutex, &deadline) == ETIMEDOUT) break;
    }
    int entered = g_gateEntered;
    pthread_mutex_unlock(&g_gateMutex);
    return entered;
}

static int failures = 0;

static void check(int condition, const char *name) {
    printf("IMAGE HARNESS %s %s\n", condition ? "PASS" : "FAIL", name);
    if (!condition) failures += 1;
}

// image.c references these when a GPU is present. The harness supplies a
// domain without GPU, so only link-time stubs are needed.
int cjgui_linux_gpu_upload_image(CjguiLinuxGpu *gpu, uint32_t slot, uint32_t width, uint32_t height,
                                 const uint8_t *rgba) {
    (void)gpu; (void)slot; (void)width; (void)height; (void)rgba;
    return CJGUI_LINUX_GPU_OK;
}
void cjgui_linux_gpu_release_image(CjguiLinuxGpu *gpu, uint32_t slot) {
    (void)gpu; (void)slot;
}
void cjgui_linux_window_wake(CjguiLinuxWindow *window) {
    (void)window;
}
uint64_t cjgui_linux_gpu_image_texture_bytes(CjguiLinuxGpu *gpu) {
    (void)gpu;
    return 0u;
}
void cjgui_linux_gpu_pump_image_resources(CjguiLinuxGpu *gpu) {
    (void)gpu;
}

static int write_png(const char *path, uint32_t width, uint32_t height, uint8_t seed) {
    size_t bytes = (size_t)width * (size_t)height * 4u;
    uint8_t *pixels = (uint8_t *)malloc(bytes);
    if (pixels == NULL) return 0;
    for (size_t i = 0u; i < bytes; i += 4u) {
        pixels[i + 0u] = (uint8_t)(seed + (i / 4u) % 251u);
        pixels[i + 1u] = (uint8_t)(seed * 3u);
        pixels[i + 2u] = (uint8_t)(255u - seed);
        pixels[i + 3u] = (uint8_t)((i / 4u) % 2u == 0u ? 255u : 96u);
    }
    png_image image;
    memset(&image, 0, sizeof(image));
    image.version = PNG_IMAGE_VERSION;
    image.width = width;
    image.height = height;
    image.format = PNG_FORMAT_RGBA;
    int ok = png_image_write_to_file(&image, path, 0, pixels, 0, NULL);
    png_image_free(&image);
    free(pixels);
    return ok;
}

static uint32_t wait_settled(CjguiLinuxImageDomain *domain, const char *path, const char *id,
                             uint64_t version) {
    uint32_t state = CJGUI_LINUX_IMAGE_UNREQUESTED;
    for (int i = 0; i < 5000; i += 1) {
        cjgui_linux_image_pump(domain);
        state = cjgui_linux_image_state(domain, path, id, version);
        if (state == CJGUI_LINUX_IMAGE_READY || state == CJGUI_LINUX_IMAGE_FAILED) return state;
        usleep(1000);
    }
    return state;
}

int main(void) {
    const char *root = "/tmp/cjgui-image-harness";
    char command[512];
    snprintf(command, sizeof(command), "rm -rf %s && mkdir -p %s", root, root);
    if (system(command) != 0) return 2;

    char good[256], bad[256], oversized[256];
    snprintf(good, sizeof(good), "%s/good.png", root);
    snprintf(bad, sizeof(bad), "%s/bad.png", root);
    snprintf(oversized, sizeof(oversized), "%s/oversized.png", root);

    write_png(good, 8, 8, 10);
    write_png(oversized, 2049, 1, 7);
    FILE *bad_file = fopen(bad, "wb");
    if (bad_file != NULL) {
        fputs("this is not a png payload\n", bad_file);
        fclose(bad_file);
    }

    CjguiLinuxImageDomain *domain = cjgui_linux_image_domain_create(NULL, NULL);
    check(domain != NULL, "domain_create");
    if (domain == NULL) return 1;

    check(cjgui_linux_image_state(domain, good, "beacon", 1) == CJGUI_LINUX_IMAGE_UNREQUESTED,
          "unrequested_read_is_passive");
    uint32_t state = cjgui_linux_image_prepare(domain, good, "beacon", 1);
    check(state == CJGUI_LINUX_IMAGE_LOADING || state == CJGUI_LINUX_IMAGE_BUSY,
          "prepare_starts_loading");
    state = wait_settled(domain, good, "beacon", 1);
    check(state == CJGUI_LINUX_IMAGE_READY, "good_png_ready");
    uint32_t width = 0u, height = 0u, slot = UINT32_MAX;
    check(cjgui_linux_image_texture(domain, good, "beacon", 1, &width, &height, &slot) == 1 &&
              width == 8u && height == 8u && slot == UINT32_MAX,
          "good_png_dimensions_no_gpu_slot");
    uint64_t decodeAfterFirst = cjgui_linux_image_decode_start_count(domain);
    for (int i = 0; i < 4; i += 1) {
        (void)cjgui_linux_image_prepare(domain, good, "beacon", 1);
        cjgui_linux_image_pump(domain);
    }
    check(cjgui_linux_image_decode_start_count(domain) == decodeAfterFirst,
          "duplicate_prepare_does_not_redecode");
    check(cjgui_linux_image_completion_version(domain) == 1u,
          "single_completion_after_duplicate_prepare");

    // Same path, next version: the file content is replaced but identity is
    // unchanged; the new version must decode once and report the new size.
    write_png(good, 16, 16, 40);
    check(cjgui_linux_image_prepare(domain, good, "beacon", 2) == CJGUI_LINUX_IMAGE_LOADING,
          "version_two_loading");
    check(wait_settled(domain, good, "beacon", 2) == CJGUI_LINUX_IMAGE_READY,
          "version_two_ready");
    check(cjgui_linux_image_texture(domain, good, "beacon", 2, &width, &height, &slot) == 1 &&
              width == 16u && height == 16u,
          "version_two_new_dimensions");
    check(cjgui_linux_image_decode_start_count(domain) == decodeAfterFirst + 1u,
          "version_two_decoded_once");

    // Failure stays a named failed state and is not retried behind the owner's
    // back; a decode-start count never grows from repeated reads/pumps.
    check(cjgui_linux_image_prepare(domain, bad, "bad", 1) == CJGUI_LINUX_IMAGE_LOADING,
          "bad_png_loading");
    check(wait_settled(domain, bad, "bad", 1) == CJGUI_LINUX_IMAGE_FAILED,
          "bad_png_failed");
    uint64_t decodeAfterBad = cjgui_linux_image_decode_start_count(domain);
    check(cjgui_linux_image_prepare(domain, bad, "bad", 1) == CJGUI_LINUX_IMAGE_FAILED,
          "failed_state_not_retried");
    (void)cjgui_linux_image_prepare(domain, bad, "bad", 1);
    cjgui_linux_image_pump(domain);
    check(cjgui_linux_image_decode_start_count(domain) == decodeAfterBad,
          "failed_read_does_not_start_decode");

    check(cjgui_linux_image_prepare(domain, oversized, "oversized", 1) == CJGUI_LINUX_IMAGE_LOADING,
          "oversized_loading");
    check(wait_settled(domain, oversized, "oversized", 1) == CJGUI_LINUX_IMAGE_FAILED,
          "oversized_failed");

    // Bounded ready cache: path0 is referenced by the accepted scene and must
    // survive; the other small versions are evicted under the 8-entry cap.
    char paths[10][256];
    char ids[10][32];
    for (int i = 0; i < 10; i += 1) {
        snprintf(paths[i], sizeof(paths[i]), "%s/cache-%d.png", root, i);
        snprintf(ids[i], sizeof(ids[i]), "cache-%d", i);
        write_png(paths[i], 8, 8, (uint8_t)(50 + i));
    }
    check(cjgui_linux_image_prepare(domain, paths[0], ids[0], 1) == CJGUI_LINUX_IMAGE_LOADING,
          "cache_reference_loading");
    check(wait_settled(domain, paths[0], ids[0], 1) == CJGUI_LINUX_IMAGE_READY,
          "cache_reference_ready");
    cjgui_linux_image_clear_references(domain);
    cjgui_linux_image_add_reference(domain, paths[0], ids[0], 1);
    for (int i = 1; i < 10; i += 1) {
        (void)cjgui_linux_image_prepare(domain, paths[i], ids[i], 1);
        (void)wait_settled(domain, paths[i], ids[i], 1);
    }
    check(cjgui_linux_image_state(domain, paths[0], ids[0], 1) == CJGUI_LINUX_IMAGE_READY,
          "referenced_cache_entry_survives");
    check(cjgui_linux_image_live_count(domain) <= CJGUI_LINUX_IMAGE_MAX_RESOURCES,
          "cache_record_bound");
    check(cjgui_linux_image_cache_bytes(domain) <= CJGUI_LINUX_IMAGE_CACHE_BYTES,
          "cache_byte_bound");
    check(cjgui_linux_image_state(domain, paths[1], ids[1], 1) == CJGUI_LINUX_IMAGE_UNREQUESTED ||
              cjgui_linux_image_state(domain, paths[1], ids[1], 1) == CJGUI_LINUX_IMAGE_READY,
          "evicted_or_live_cache_entry_is_consistent");

    // ---- 受控积压：6 个请求同时准备。2 个 worker、4 项在途预算、4 项完成队列。
    // 先不 pump，让完成队列填满；随后统一结算必须全部 ready，不得丢结果或永久 loading。
    {
        CjguiLinuxImageDomain *backlog = cjgui_linux_image_domain_create(NULL, NULL);
        check(backlog != NULL, "backlog_domain_create");
        char bpaths[6][256];
        char bids[6][32];
        uint32_t firstState[6];
        for (int i = 0; i < 6; i += 1) {
            snprintf(bpaths[i], sizeof(bpaths[i]), "%s/backlog-%d.png", root, i);
            snprintf(bids[i], sizeof(bids[i]), "backlog-%d", i);
            write_png(bpaths[i], 8, 8, (uint8_t)(70 + i));
            firstState[i] = cjgui_linux_image_prepare(backlog, bpaths[i], bids[i], 1);
        }
        const uint64_t fourReservations = 4ull * 16ull * 1024ull * 1024ull;
        check(cjgui_linux_image_live_count(backlog) == 6u, "backlog_all_records_created");
        check(firstState[4] == CJGUI_LINUX_IMAGE_BUSY && firstState[5] == CJGUI_LINUX_IMAGE_BUSY,
              "backlog_excess_requests_busy_not_dropped");
        check(cjgui_linux_image_inflight_bytes(backlog) == fourReservations,
              "backlog_inflight_budget_four_requests");
        // 4×16 MiB 预算只放行 4 个请求，第 5 个在准入处 BUSY；这里证明的是
        // 准入/在途预算有界与 4 项完成队列容量，不声称 worker 已进入满队列等待。
        usleep(150000);
        check(cjgui_linux_image_inflight_bytes(backlog) == fourReservations,
              "backlog_inflight_stays_bounded_when_queue_full");
        int allReady = 0;
        for (int round = 0; round < 400 && !allReady; round += 1) {
            cjgui_linux_image_pump(backlog);
            allReady = 1;
            for (int i = 0; i < 6; i += 1) {
                if (cjgui_linux_image_state(backlog, bpaths[i], bids[i], 1) !=
                    CJGUI_LINUX_IMAGE_READY) {
                    allReady = 0;
                    break;
                }
            }
            if (!allReady) usleep(1000);
        }
        check(allReady, "backlog_all_ready_after_backpressure");
        check(cjgui_linux_image_decode_start_count(backlog) == 6u, "backlog_each_decoded_once");
        check(cjgui_linux_image_inflight_bytes(backlog) == 0u, "backlog_inflight_released");
        cjgui_linux_image_domain_destroy(backlog);
    }

    // ---- 线程部分创建：第 2 次 pthread_create 失败后，第 1 个句柄必须保留；
    // 再次 prepare 从实际数量补齐，销毁 join 所有实际创建的线程。
    {
        CjguiLinuxImageDomain *threads = cjgui_linux_image_domain_create(NULL, NULL);
        check(threads != NULL, "thread_retry_domain_create");
        char tp1[256], tp2[256];
        snprintf(tp1, sizeof(tp1), "%s/thread-a.png", root);
        snprintf(tp2, sizeof(tp2), "%s/thread-b.png", root);
        write_png(tp1, 8, 8, 150);
        write_png(tp2, 8, 8, 151);
        g_createAttempts = 0;
        g_failCreateAt = 1;   // 第 1 个成功、第 2 个失败
        uint32_t st = cjgui_linux_image_prepare(threads, tp1, "thread-a", 1);
        check(st == CJGUI_LINUX_IMAGE_BUSY, "thread_partial_create_busy");
        check(threads->workerCount == 1u, "thread_partial_keeps_first");
        pthread_t firstHandle = threads->workers[0];
        g_failCreateAt = -1;
        st = cjgui_linux_image_prepare(threads, tp2, "thread-b", 1);
        check(st == CJGUI_LINUX_IMAGE_LOADING, "thread_retry_loading");
        check(threads->workerCount == 2u, "thread_retry_fills_second");
        check(pthread_equal(firstHandle, threads->workers[0]) != 0,
              "thread_retry_keeps_first_handle");
        int joinsBefore = g_joinCalls;
        cjgui_linux_image_domain_destroy(threads);
        check(g_joinCalls - joinsBefore == 2, "thread_retry_destroy_joins_two");
    }

    // ---- 完成队列满时销毁（worker 空闲、队列有 4 项）：先轮询实际队列状态，
    // 不用固定 sleep 猜完成时机；ASan 检查队列/像素归属。
    {
        CjguiLinuxImageDomain *closing = cjgui_linux_image_domain_create(NULL, NULL);
        check(closing != NULL, "close_domain_create");
        char cpaths[5][256];
        char cids[5][32];
        for (int i = 0; i < 5; i += 1) {
            snprintf(cpaths[i], sizeof(cpaths[i]), "%s/closing-%d.png", root, i);
            snprintf(cids[i], sizeof(cids[i]), "closing-%d", i);
            write_png(cpaths[i], 8, 8, (uint8_t)(90 + i));
            (void)cjgui_linux_image_prepare(closing, cpaths[i], cids[i], 1);
        }
        int queueFull = 0;
        for (int round = 0; round < 5000 && !queueFull; round += 1) {
            pthread_mutex_lock(&closing->mutex);
            queueFull = closing->completionCount == CJGUI_LINUX_IMAGE_PENDING_CAPACITY;
            pthread_mutex_unlock(&closing->mutex);
            if (!queueFull) usleep(1000);
        }
        check(queueFull, "close_completion_queue_full");
        cjgui_linux_image_domain_destroy(closing);
        check(1, "destroy_with_full_completion_queue");
    }

    // ---- 解码在途关闭（受控同步）：worker 已在 gate 内完成解码并持有
    // request/pixels，尚未移交完成队列；此时置 stop 再放行，ASan 检查释放与退出。
    {
        CjguiLinuxImageDomain *held = cjgui_linux_image_domain_create(NULL, NULL);
        check(held != NULL, "close_gate_domain_create");
        char hpath[256];
        snprintf(hpath, sizeof(hpath), "%s/close-held.png", root);
        write_png(hpath, 64, 64, 170);
        g_gateEntered = 0;
        g_gateRelease = 0;
        held->testAfterDecode = test_hold_after_decode;
        uint32_t st = cjgui_linux_image_prepare(held, hpath, "close-held", 1);
        check(st == CJGUI_LINUX_IMAGE_LOADING, "close_gate_loading");
        check(wait_gate_entered(5000), "close_gate_worker_holds_decoded");
        pthread_mutex_lock(&held->mutex);
        int pending = (int)held->pendingCount;
        int completions = (int)held->completionCount;
        uint64_t inflight = held->inflightBytes;
        held->stop = 1;
        pthread_cond_broadcast(&held->cond);
        pthread_mutex_unlock(&held->mutex);
        check(pending == 0 && completions == 0, "close_gate_not_yet_transferred");
        check(inflight == CJGUI_LINUX_IMAGE_REQUEST_BYTES,
              "close_gate_worker_owns_reservation");
        pthread_mutex_lock(&g_gateMutex);
        g_gateRelease = 1;
        pthread_cond_broadcast(&g_gateCond);
        pthread_mutex_unlock(&g_gateMutex);
        int joinsBefore = g_joinCalls;
        cjgui_linux_image_domain_destroy(held);
        check(g_joinCalls - joinsBefore == 2, "close_gate_all_workers_joined");
    }

    // ---- 出队搬移清空尾槽：一次性结算两个完成后再销毁，ASan 不应出现二次释放。
    {
        CjguiLinuxImageDomain *drain = cjgui_linux_image_domain_create(NULL, NULL);
        check(drain != NULL, "drain_domain_create");
        char dpaths[2][256];
        char dids[2][32];
        for (int i = 0; i < 2; i += 1) {
            snprintf(dpaths[i], sizeof(dpaths[i]), "%s/drain-%d.png", root, i);
            snprintf(dids[i], sizeof(dids[i]), "drain-%d", i);
            write_png(dpaths[i], 8, 8, (uint8_t)(110 + i));
            (void)cjgui_linux_image_prepare(drain, dpaths[i], dids[i], 1);
        }
        usleep(150000);
        cjgui_linux_image_pump(drain);
        check(cjgui_linux_image_ready_count(drain) == 2u, "drain_two_completions_ready");
        cjgui_linux_image_domain_destroy(drain);
        check(1, "destroy_after_multi_completion_drain");
    }

    // ---- 引用占满预算：8 张被引用时第 9 张必须具名失败而不是静默超过 8 项；
    // 释放一个引用后，失败项应自动重试并在上限内 ready。
    {
        CjguiLinuxImageDomain *budget = cjgui_linux_image_domain_create(NULL, NULL);
        check(budget != NULL, "budget_domain_create");
        char upaths[9][256];
        char uids[9][32];
        uint32_t ready = 0u;
        for (int i = 0; i < 8; i += 1) {
            snprintf(upaths[i], sizeof(upaths[i]), "%s/budget-%d.png", root, i);
            snprintf(uids[i], sizeof(uids[i]), "budget-%d", i);
            write_png(upaths[i], 8, 8, (uint8_t)(130 + i));
            (void)cjgui_linux_image_prepare(budget, upaths[i], uids[i], 1);
            if (wait_settled(budget, upaths[i], uids[i], 1) == CJGUI_LINUX_IMAGE_READY) ready += 1u;
            cjgui_linux_image_add_reference(budget, upaths[i], uids[i], 1);
        }
        check(ready == 8u && cjgui_linux_image_ready_count(budget) == 8u,
              "budget_eight_referenced_ready");
        snprintf(upaths[8], sizeof(upaths[8]), "%s/budget-8.png", root);
        snprintf(uids[8], sizeof(uids[8]), "budget-8");
        write_png(upaths[8], 8, 8, 138);
        uint32_t ninth = cjgui_linux_image_prepare(budget, upaths[8], uids[8], 1);
        if (ninth != CJGUI_LINUX_IMAGE_FAILED) ninth = wait_settled(budget, upaths[8], uids[8], 1);
        check(ninth == CJGUI_LINUX_IMAGE_FAILED, "budget_ninth_named_failed_when_all_referenced");
        check(cjgui_linux_image_capacity_failure_count(budget) == 1u,
              "budget_capacity_failure_counted");
        check(cjgui_linux_image_ready_count(budget) <= 8u, "budget_never_silently_exceeds_eight");
        check(cjgui_linux_image_cache_bytes(budget) <= CJGUI_LINUX_IMAGE_CACHE_BYTES,
              "budget_never_silently_exceeds_bytes");
        // 只保留 1..7 的引用：0 变为可淘汰，pump 应重试第 9 张并成功。
        cjgui_linux_image_clear_references(budget);
        for (int i = 1; i < 8; i += 1) {
            cjgui_linux_image_add_reference(budget, upaths[i], uids[i], 1);
        }
        uint32_t recovered = wait_settled(budget, upaths[8], uids[8], 1);
        check(recovered == CJGUI_LINUX_IMAGE_READY, "budget_failure_recovers_after_release");
        check(cjgui_linux_image_ready_count(budget) <= 8u, "budget_recovery_within_bound");
        check(cjgui_linux_image_cache_eviction_count(budget) >= 1u,
              "budget_recovery_evicted_unreferenced");
        cjgui_linux_image_domain_destroy(budget);
    }

    // Teardown with a load possibly still in flight must join workers and
    // release all records without touching a destroyed window.
    (void)cjgui_linux_image_prepare(domain, good, "beacon", 3);
    cjgui_linux_image_domain_destroy(domain);

    printf("IMAGE HARNESS RESULT %s failures=%d\n", failures == 0 ? "PASS" : "FAIL", failures);
    return failures == 0 ? 0 : 1;
}
