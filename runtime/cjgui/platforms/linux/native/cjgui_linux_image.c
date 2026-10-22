// runtime/cjgui/platforms/linux/native/cjgui_linux_image.c
//
// Linux 本地 PNG 资源域。共同层只声明资源路径/身份/版本与状态语义；本文件
// 负责真实解码、缓存、版本更新、失败结算和主线程纹理上传，不复制场景或
// 应用状态机。
//
// 边界：
//   * 只支持本地静态 PNG（libpng 简化 API 解码为 8-bit RGBA）；传输来源、
//     动画和其他格式返回 failed，不静默降级。
//   * 编码文件 <= 8 MiB，边长 <= 2048，解码 <= 16 MiB；缓存最多 8 个 ready
//     资源、32 MiB 解码字节，另有 16 条记录上限。超过预算的候选进入 BUSY
//     或在主线程结算时具名失败，不无限增长。
//   * 解码在 2 个有界 worker 上执行；完成只写入线程安全队列并唤醒窗口，
//     纹理上传、状态发布与 completionVersion 推进都发生在主线程 pump。
//   * 纹理销毁不在 worker 或上传中途发生：GPU 侧旧代进入 retire 链，由
//     begin_frame 在覆盖它的 fence 完成后回收。

#define _XOPEN_SOURCE 700
#define _POSIX_C_SOURCE 200809L

#include "cjgui_linux_image.h"

#include <errno.h>
#include <limits.h>
#include <png.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define CJGUI_LINUX_IMAGE_MAX_RESOURCES 16u
#define CJGUI_LINUX_IMAGE_READY_CAPACITY 8u
#define CJGUI_LINUX_IMAGE_CACHE_BYTES (32u * 1024u * 1024u)
#define CJGUI_LINUX_IMAGE_PENDING_CAPACITY 4u
#define CJGUI_LINUX_IMAGE_WORKERS 2u
#define CJGUI_LINUX_IMAGE_MAX_DIMENSION 2048u
#define CJGUI_LINUX_IMAGE_MAX_PIXELS (2048u * 2048u)
#define CJGUI_LINUX_IMAGE_MAX_DECODED_BYTES (16u * 1024u * 1024u)
#define CJGUI_LINUX_IMAGE_MAX_ENCODED_BYTES (8u * 1024u * 1024u)
#define CJGUI_LINUX_IMAGE_INFLIGHT_BYTES (64u * 1024u * 1024u)
#define CJGUI_LINUX_IMAGE_REQUEST_BYTES CJGUI_LINUX_IMAGE_MAX_DECODED_BYTES
#define CJGUI_LINUX_IMAGE_KEY_CAPACITY 8192u

typedef struct CjguiLinuxImageResource {
    char *key;
    char *resolvedPath;
    uint64_t version;
    uint32_t state;
    uint32_t width;
    uint32_t height;
    uint8_t *rgba;
    size_t bytes;
    int gpuSlot;
    int referenced;
    int retryable;   // 仅容量失败置位；预算释放后可由 pump 重试
    uint64_t lastAccess;
    uint64_t generation;
    uint64_t decodeMicros;
} CjguiLinuxImageResource;

// 所有权链：prepare 创建资源；enqueue 把 key/path 复制进 request；worker 出队后
// 拥有 request；完成后 key/rgba 移交给 completion；pump 取出后 key 随结算释放，
// rgba 在成功结算时移交资源。任何停止/丢弃路径都释放自己持有的那份。
typedef struct CjguiLinuxImageRequest {
    char *key;
    char *path;
    uint64_t generation;
    uint32_t reserved;   // 在途字节预留，结算或丢弃时归还
} CjguiLinuxImageRequest;

typedef struct CjguiLinuxImageCompletion {
    char *key;
    uint64_t generation;
    uint8_t *rgba;
    uint32_t width;
    uint32_t height;
    uint32_t reserved;
    uint64_t decodeMicros;
} CjguiLinuxImageCompletion;

struct CjguiLinuxImageDomain {
    CjguiLinuxGpu *gpu;
    CjguiLinuxWindow *window;

    pthread_mutex_t mutex;
    pthread_cond_t cond;
    pthread_t workers[CJGUI_LINUX_IMAGE_WORKERS];
    uint32_t workerCount;
    int started;
    int stop;

    CjguiLinuxImageRequest pending[CJGUI_LINUX_IMAGE_PENDING_CAPACITY];
    uint32_t pendingHead;
    uint32_t pendingCount;

    CjguiLinuxImageCompletion completions[CJGUI_LINUX_IMAGE_PENDING_CAPACITY];
    uint32_t completionCount;

    CjguiLinuxImageResource resources[CJGUI_LINUX_IMAGE_MAX_RESOURCES];
    uint32_t resourceCount;

    uint64_t completionVersion;
    uint64_t decodeStartCount;
    uint64_t inflightBytes;
    uint64_t cacheEvictionCount;
    uint64_t capacityFailureCount;
    uint64_t accessClock;
    uint64_t nextGeneration;
#ifdef CJGUI_LINUX_IMAGE_TEST_HOOKS
    // 仅 harness 编译：worker 解码完成、尚未把 request/pixels 移交完成队列时调用。
    void (*testAfterDecode)(struct CjguiLinuxImageDomain *domain);
#endif
};

static uint64_t cjgui_linux_image_now_micros(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000ull + (uint64_t)ts.tv_nsec / 1000ull;
}

static int cjgui_linux_image_trace_enabled(void)
{
    return getenv("CJGUI_LINUX_IMAGE_TRACE") != NULL;
}

static void cjgui_linux_image_release_reservation(CjguiLinuxImageDomain *domain, uint32_t reserved)
{
    if (reserved == 0u) return;
    if (domain->inflightBytes >= reserved) {
        domain->inflightBytes -= reserved;
    } else {
        domain->inflightBytes = 0u;
    }
}

static int cjgui_linux_image_resolve_path(const char *resourcePath, char *out, size_t capacity)
{
    if (resourcePath == NULL || resourcePath[0] == '\0' || capacity == 0u) return 0;
    if (strncmp(resourcePath, "cjgui-transfer:", 15) == 0) return 0;
    char candidate[PATH_MAX * 2u];
    if (resourcePath[0] == '/') {
        snprintf(candidate, sizeof(candidate), "%s", resourcePath);
    } else {
        char cwd[PATH_MAX];
        if (getcwd(cwd, sizeof(cwd)) == NULL) cwd[0] = '\0';
        snprintf(candidate, sizeof(candidate), "%s/%s", cwd, resourcePath);
    }
    char resolved[PATH_MAX];
    if (realpath(candidate, resolved) != NULL) {
        snprintf(out, capacity, "%s", resolved);
        return 1;
    }
    // 相对路径在 exec 目录旁再找一次（应用可能从构建输出目录启动）。
    char exe[PATH_MAX];
    ssize_t length = readlink("/proc/self/exe", exe, sizeof(exe) - 1u);
    if (length > 0) {
        exe[length] = '\0';
        char *slash = strrchr(exe, '/');
        if (slash != NULL) {
            *slash = '\0';
            if (resourcePath[0] == '/') {
                snprintf(candidate, sizeof(candidate), "%s", resourcePath);
            } else {
                snprintf(candidate, sizeof(candidate), "%s/%s", exe, resourcePath);
            }
            if (realpath(candidate, resolved) != NULL) {
                snprintf(out, capacity, "%s", resolved);
                return 1;
            }
        }
    }
    const char *resourceDir = getenv("CJGUI_LINUX_RESOURCE_DIR");
    if (resourceDir != NULL && resourceDir[0] != '\0' && resourcePath[0] != '/') {
        snprintf(candidate, sizeof(candidate), "%s/%s", resourceDir, resourcePath);
        if (realpath(candidate, resolved) != NULL) {
            snprintf(out, capacity, "%s", resolved);
            return 1;
        }
    }
    // 文件不存在时仍给出稳定的绝对身份；解码阶段会具名失败。
    size_t copyLength = strlen(candidate);
    if (copyLength >= capacity) copyLength = capacity - 1u;
    memcpy(out, candidate, copyLength);
    out[copyLength] = '\0';
    return 1;
}

int cjgui_linux_image_cache_key(const char *resourcePath, const char *resourceId,
                                uint64_t resourceVersion, char *out, size_t capacity)
{
    if (out == NULL || capacity == 0u) return 0;
    char resolved[PATH_MAX];
    if (!cjgui_linux_image_resolve_path(resourcePath, resolved, sizeof(resolved))) return 0;
    const char *logical = (resourceId != NULL && resourceId[0] != '\0') ? resourceId : resolved;
    int written = snprintf(out, capacity, "%s\n%llu\n%s", logical,
                           (unsigned long long)resourceVersion, resolved);
    return written > 0 && (size_t)written < capacity;
}

static int cjgui_linux_image_decode_png(const char *path, uint8_t **outPixels,
                                        uint32_t *outWidth, uint32_t *outHeight,
                                        uint64_t *outMicros)
{
    *outPixels = NULL;
    *outWidth = 0u;
    *outHeight = 0u;
    *outMicros = 0u;
    struct stat info;
    if (stat(path, &info) != 0 || !S_ISREG(info.st_mode) || info.st_size <= 0) return 0;
    if ((uint64_t)info.st_size > CJGUI_LINUX_IMAGE_MAX_ENCODED_BYTES) return 0;

    uint64_t started = cjgui_linux_image_now_micros();
    png_image image;
    memset(&image, 0, sizeof(image));
    image.version = PNG_IMAGE_VERSION;
    if (!png_image_begin_read_from_file(&image, path)) return 0;
    if (image.width == 0u || image.height == 0u ||
        image.width > CJGUI_LINUX_IMAGE_MAX_DIMENSION || image.height > CJGUI_LINUX_IMAGE_MAX_DIMENSION ||
        (uint64_t)image.width * (uint64_t)image.height > CJGUI_LINUX_IMAGE_MAX_PIXELS) {
        png_image_free(&image);
        return 0;
    }
    image.format = PNG_FORMAT_RGBA;
    size_t bytes = PNG_IMAGE_SIZE(image);
    if (bytes == 0u || bytes > CJGUI_LINUX_IMAGE_MAX_DECODED_BYTES) {
        png_image_free(&image);
        return 0;
    }
    uint8_t *pixels = (uint8_t *)malloc(bytes);
    if (pixels == NULL) {
        png_image_free(&image);
        return 0;
    }
    if (!png_image_finish_read(&image, NULL, pixels, 0, NULL)) {
        free(pixels);
        png_image_free(&image);
        return 0;
    }
    *outPixels = pixels;
    *outWidth = image.width;
    *outHeight = image.height;
    *outMicros = cjgui_linux_image_now_micros() - started;
    png_image_free(&image);
    return 1;
}

static CjguiLinuxImageResource *cjgui_linux_image_find(CjguiLinuxImageDomain *domain, const char *key)
{
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        if (strcmp(domain->resources[i].key, key) == 0) return &domain->resources[i];
    }
    return NULL;
}

static void cjgui_linux_image_release_resource_gpu(CjguiLinuxImageDomain *domain,
                                                   CjguiLinuxImageResource *resource)
{
    if (domain->gpu != NULL && resource->gpuSlot >= 0) {
        cjgui_linux_gpu_release_image(domain->gpu, (uint32_t)resource->gpuSlot);
    }
    resource->gpuSlot = -1;
}

static void cjgui_linux_image_remove_at(CjguiLinuxImageDomain *domain, uint32_t index)
{
    CjguiLinuxImageResource *resource = &domain->resources[index];
    cjgui_linux_image_release_resource_gpu(domain, resource);
    free(resource->key);
    free(resource->resolvedPath);
    free(resource->rgba);
    if (index + 1u < domain->resourceCount) {
        memmove(&domain->resources[index], &domain->resources[index + 1u],
                sizeof(CjguiLinuxImageResource) * (domain->resourceCount - index - 1u));
    }
    domain->resourceCount -= 1u;
    memset(&domain->resources[domain->resourceCount], 0, sizeof(CjguiLinuxImageResource));
    domain->resources[domain->resourceCount].gpuSlot = -1;
}

// 只淘汰没有场景引用、也不是正在解码/排队的资源。返回 1 表示淘汰了一项。
static int cjgui_linux_image_evict_one(CjguiLinuxImageDomain *domain, const char *protectKey)
{
    int victim = -1;
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        CjguiLinuxImageResource *resource = &domain->resources[i];
        if (resource->referenced || resource->state == CJGUI_LINUX_IMAGE_LOADING ||
            resource->state == CJGUI_LINUX_IMAGE_BUSY) continue;
        if (protectKey != NULL && strcmp(resource->key, protectKey) == 0) continue;
        if (victim < 0) {
            victim = (int)i;
            continue;
        }
        CjguiLinuxImageResource *best = &domain->resources[victim];
        if (resource->state == CJGUI_LINUX_IMAGE_FAILED && best->state != CJGUI_LINUX_IMAGE_FAILED) {
            victim = (int)i;
        } else if (resource->state == best->state && resource->lastAccess < best->lastAccess) {
            victim = (int)i;
        }
    }
    if (victim < 0) return 0;
    CjguiLinuxImageResource *resource = &domain->resources[victim];
    if (resource->state == CJGUI_LINUX_IMAGE_READY) domain->cacheEvictionCount += 1u;
    if (cjgui_linux_image_trace_enabled()) {
        fprintf(stderr, "CJGUI_LINUX_IMAGE evict key=%s state=%u bytes=%llu slot=%d\n",
                resource->key, resource->state, (unsigned long long)resource->bytes,
                resource->gpuSlot);
    }
    cjgui_linux_image_remove_at(domain, (uint32_t)victim);
    return 1;
}

// 预算为“再加一张 bytes 后仍满足 ready 8 项 / 32 MiB”。只有在存在可淘汰的
// 未引用项时才腾位；全部被场景引用时返回 0，由调用方具名失败而不是静默超额。
static int cjgui_linux_image_reserve_ready_room(CjguiLinuxImageDomain *domain,
                                                const char *protectKey, size_t bytes)
{
    for (;;) {
        uint32_t readyCount = 0u;
        uint64_t readyBytes = 0u;
        for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
            if (domain->resources[i].state == CJGUI_LINUX_IMAGE_READY) {
                readyCount += 1u;
                readyBytes += domain->resources[i].bytes;
            }
        }
        if (readyCount < CJGUI_LINUX_IMAGE_READY_CAPACITY &&
            readyBytes + bytes <= CJGUI_LINUX_IMAGE_CACHE_BYTES) {
            return 1;
        }
        if (!cjgui_linux_image_evict_one(domain, protectKey)) return 0;
    }
}

static void cjgui_linux_image_enforce_cache(CjguiLinuxImageDomain *domain, const char *protectKey)
{
    for (;;) {
        uint32_t readyCount = 0u;
        uint64_t bytes = 0u;
        for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
            if (domain->resources[i].state == CJGUI_LINUX_IMAGE_READY) {
                readyCount += 1u;
                bytes += domain->resources[i].bytes;
            }
        }
        if (domain->resourceCount > CJGUI_LINUX_IMAGE_MAX_RESOURCES ||
            readyCount > CJGUI_LINUX_IMAGE_READY_CAPACITY || bytes > CJGUI_LINUX_IMAGE_CACHE_BYTES) {
            if (!cjgui_linux_image_evict_one(domain, protectKey)) return;
            continue;
        }
        return;
    }
}

static int cjgui_linux_image_allocate_slot(CjguiLinuxImageDomain *domain)
{
    int used[CJGUI_LINUX_IMAGE_MAX_RESOURCES];
    memset(used, 0, sizeof(used));
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        int slot = domain->resources[i].gpuSlot;
        if (slot >= 0 && (uint32_t)slot < CJGUI_LINUX_GPU_IMAGE_SLOTS) used[slot] = 1;
    }
    for (uint32_t slot = 0u; slot < CJGUI_LINUX_GPU_IMAGE_SLOTS; slot += 1u) {
        if (!used[slot]) return (int)slot;
    }
    return -1;
}

static void *cjgui_linux_image_worker(void *argument)
{
    CjguiLinuxImageDomain *domain = (CjguiLinuxImageDomain *)argument;
    for (;;) {
        pthread_mutex_lock(&domain->mutex);
        while (!domain->stop && domain->pendingCount == 0u) {
            pthread_cond_wait(&domain->cond, &domain->mutex);
        }
        if (domain->stop) {
            pthread_mutex_unlock(&domain->mutex);
            break;
        }
        CjguiLinuxImageRequest request = domain->pending[domain->pendingHead];
        memset(&domain->pending[domain->pendingHead], 0, sizeof(CjguiLinuxImageRequest));
        domain->pendingHead = (domain->pendingHead + 1u) % CJGUI_LINUX_IMAGE_PENDING_CAPACITY;
        domain->pendingCount -= 1u;
        if (domain->decodeStartCount < UINT64_MAX) domain->decodeStartCount += 1u;
        pthread_mutex_unlock(&domain->mutex);

        uint8_t *pixels = NULL;
        uint32_t width = 0u, height = 0u;
        uint64_t micros = 0u;
        int decoded = cjgui_linux_image_decode_png(request.path, &pixels, &width, &height, &micros);
#ifdef CJGUI_LINUX_IMAGE_TEST_HOOKS
        if (domain->testAfterDecode != NULL) domain->testAfterDecode(domain);
#endif

        // 完成队列满时在此等待，而不是丢弃结果：pump 每取走一项都会广播。
        // stop 时释放本 worker 持有的 request/像素并归还预留，不把结果带进销毁。
        pthread_mutex_lock(&domain->mutex);
        while (!domain->stop &&
               domain->completionCount >= CJGUI_LINUX_IMAGE_PENDING_CAPACITY) {
            pthread_cond_wait(&domain->cond, &domain->mutex);
        }
        int wake = 0;
        if (!domain->stop) {
            CjguiLinuxImageCompletion *completion = &domain->completions[domain->completionCount];
            completion->key = request.key;
            completion->generation = request.generation;
            completion->rgba = decoded ? pixels : NULL;
            completion->width = decoded ? width : 0u;
            completion->height = decoded ? height : 0u;
            completion->reserved = request.reserved;
            completion->decodeMicros = decoded ? micros : 0u;
            domain->completionCount += 1u;
            request.key = NULL;
            request.reserved = 0u;
            pixels = NULL;
            wake = 1;
        } else {
            cjgui_linux_image_release_reservation(domain, request.reserved);
        }
        pthread_mutex_unlock(&domain->mutex);
        free(request.key);
        free(request.path);
        free(pixels);
        if (wake && domain->window != NULL) cjgui_linux_window_wake(domain->window);
    }
    return NULL;
}

static int cjgui_linux_image_ensure_workers_locked(CjguiLinuxImageDomain *domain)
{
    if (domain->started) return 1;
    // 从实际创建数量补齐：部分失败后已成功的句柄仍在 workers[0..workerCount)，
    // 不能从 0 重来覆盖它们，否则旧线程失去句柄、销毁也无法 join。
    for (uint32_t i = domain->workerCount; i < CJGUI_LINUX_IMAGE_WORKERS; i += 1u) {
        if (pthread_create(&domain->workers[i], NULL, cjgui_linux_image_worker, domain) != 0) {
            return 0;
        }
        domain->workerCount = i + 1u;
    }
    domain->started = 1;
    return 1;
}

static int cjgui_linux_image_enqueue_locked(CjguiLinuxImageDomain *domain,
                                            CjguiLinuxImageResource *resource)
{
    if (domain->pendingCount >= CJGUI_LINUX_IMAGE_PENDING_CAPACITY) return 0;
    // 在途预算按最坏解码尺寸预留；完成后按实际尺寸转入 ready 预算。这样
    // pending + 解码中 + 未结算完成的总像素内存有确定上界，而不是只限条数。
    if (domain->inflightBytes + CJGUI_LINUX_IMAGE_REQUEST_BYTES > CJGUI_LINUX_IMAGE_INFLIGHT_BYTES) {
        return 0;
    }
    if (!cjgui_linux_image_ensure_workers_locked(domain)) return 0;
    uint32_t index = (domain->pendingHead + domain->pendingCount) % CJGUI_LINUX_IMAGE_PENDING_CAPACITY;
    domain->pending[index].key = strdup(resource->key);
    domain->pending[index].path = strdup(resource->resolvedPath);
    domain->pending[index].generation = resource->generation;
    if (domain->pending[index].key == NULL || domain->pending[index].path == NULL) {
        free(domain->pending[index].key);
        free(domain->pending[index].path);
        memset(&domain->pending[index], 0, sizeof(CjguiLinuxImageRequest));
        return 0;
    }
    domain->pending[index].reserved = CJGUI_LINUX_IMAGE_REQUEST_BYTES;
    domain->inflightBytes += CJGUI_LINUX_IMAGE_REQUEST_BYTES;
    domain->pendingCount += 1u;
    resource->state = CJGUI_LINUX_IMAGE_LOADING;
    pthread_cond_signal(&domain->cond);
    return 1;
}

// 容量失败不是终点：一旦引用集合释放了 ready 预算（通常来自移除/淘汰），
// 下一轮 pump 重新入队。每次最多放行一张，避免为多个候选同时超额腾位。
static void cjgui_linux_image_retry_capacity_locked(CjguiLinuxImageDomain *domain)
{
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        CjguiLinuxImageResource *resource = &domain->resources[i];
        if (resource->state != CJGUI_LINUX_IMAGE_FAILED || !resource->retryable ||
            resource->bytes == 0u) {
            continue;
        }
        char *key = strdup(resource->key);
        if (key == NULL) return;
        int room = cjgui_linux_image_reserve_ready_room(domain, key, resource->bytes);
        CjguiLinuxImageResource *target = room ? cjgui_linux_image_find(domain, key) : NULL;
        free(key);
        if (target == NULL || target->state != CJGUI_LINUX_IMAGE_FAILED || !target->retryable) {
            continue;
        }
        target->retryable = 0;
        target->generation = domain->nextGeneration + 1u;
        domain->nextGeneration = target->generation;
        if (!cjgui_linux_image_enqueue_locked(domain, target)) {
            target->state = CJGUI_LINUX_IMAGE_BUSY;
            target->retryable = 1;
            return;
        }
        return;
    }
}

static void cjgui_linux_image_start_busy_locked(CjguiLinuxImageDomain *domain)
{
    cjgui_linux_image_retry_capacity_locked(domain);
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        CjguiLinuxImageResource *resource = &domain->resources[i];
        if (resource->state != CJGUI_LINUX_IMAGE_BUSY) continue;
        if (domain->pendingCount >= CJGUI_LINUX_IMAGE_PENDING_CAPACITY) return;
        if (!cjgui_linux_image_enqueue_locked(domain, resource)) return;
    }
}

CjguiLinuxImageDomain *cjgui_linux_image_domain_create(CjguiLinuxGpu *gpu, CjguiLinuxWindow *window)
{
    CjguiLinuxImageDomain *domain =
        (CjguiLinuxImageDomain *)calloc(1, sizeof(CjguiLinuxImageDomain));
    if (domain == NULL) return NULL;
    domain->gpu = gpu;
    domain->window = window;
    if (pthread_mutex_init(&domain->mutex, NULL) != 0) {
        free(domain);
        return NULL;
    }
    if (pthread_cond_init(&domain->cond, NULL) != 0) {
        pthread_mutex_destroy(&domain->mutex);
        free(domain);
        return NULL;
    }
    for (uint32_t i = 0u; i < CJGUI_LINUX_IMAGE_MAX_RESOURCES; i += 1u) {
        domain->resources[i].gpuSlot = -1;
    }
    return domain;
}

void cjgui_linux_image_domain_destroy(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return;
    pthread_mutex_lock(&domain->mutex);
    domain->stop = 1;
    pthread_cond_broadcast(&domain->cond);
    pthread_mutex_unlock(&domain->mutex);
    for (uint32_t i = 0u; i < domain->workerCount; i += 1u) {
        pthread_join(domain->workers[i], NULL);
    }
    for (uint32_t i = 0u; i < CJGUI_LINUX_IMAGE_PENDING_CAPACITY; i += 1u) {
        cjgui_linux_image_release_reservation(domain, domain->pending[i].reserved);
        if (domain->pending[i].key != NULL) free(domain->pending[i].key);
        if (domain->pending[i].path != NULL) free(domain->pending[i].path);
        memset(&domain->pending[i], 0, sizeof(CjguiLinuxImageRequest));
        cjgui_linux_image_release_reservation(domain, domain->completions[i].reserved);
        if (domain->completions[i].key != NULL) free(domain->completions[i].key);
        if (domain->completions[i].rgba != NULL) free(domain->completions[i].rgba);
        memset(&domain->completions[i], 0, sizeof(CjguiLinuxImageCompletion));
    }
    while (domain->resourceCount > 0u) {
        cjgui_linux_image_remove_at(domain, domain->resourceCount - 1u);
    }
    pthread_cond_destroy(&domain->cond);
    pthread_mutex_destroy(&domain->mutex);
    free(domain);
}

uint32_t cjgui_linux_image_prepare(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                   const char *resourceId, uint64_t resourceVersion)
{
    if (domain == NULL) return CJGUI_LINUX_IMAGE_FAILED;
    char key[CJGUI_LINUX_IMAGE_KEY_CAPACITY];
    if (!cjgui_linux_image_cache_key(resourcePath, resourceId, resourceVersion, key, sizeof(key))) {
        return CJGUI_LINUX_IMAGE_FAILED;
    }
    char resolved[PATH_MAX];
    if (!cjgui_linux_image_resolve_path(resourcePath, resolved, sizeof(resolved))) {
        return CJGUI_LINUX_IMAGE_FAILED;
    }

    pthread_mutex_lock(&domain->mutex);
    CjguiLinuxImageResource *resource = cjgui_linux_image_find(domain, key);
    if (resource == NULL) {
        if (domain->resourceCount >= CJGUI_LINUX_IMAGE_MAX_RESOURCES) {
            if (!cjgui_linux_image_evict_one(domain, key)) {
                pthread_mutex_unlock(&domain->mutex);
                return CJGUI_LINUX_IMAGE_BUSY;
            }
        }
        resource = &domain->resources[domain->resourceCount];
        memset(resource, 0, sizeof(*resource));
        resource->gpuSlot = -1;
        resource->key = strdup(key);
        resource->resolvedPath = strdup(resolved);
        resource->version = resourceVersion;
        resource->state = CJGUI_LINUX_IMAGE_UNREQUESTED;
        if (resource->key == NULL || resource->resolvedPath == NULL) {
            free(resource->key);
            free(resource->resolvedPath);
            memset(resource, 0, sizeof(*resource));
            resource->gpuSlot = -1;
            pthread_mutex_unlock(&domain->mutex);
            return CJGUI_LINUX_IMAGE_FAILED;
        }
        domain->resourceCount += 1u;
        if (cjgui_linux_image_trace_enabled()) {
            fprintf(stderr, "CJGUI_LINUX_IMAGE create key=%s\n", key);
        }
    }
    domain->accessClock += 1u;
    resource->lastAccess = domain->accessClock;

    uint32_t state = resource->state;
    if (state == CJGUI_LINUX_IMAGE_UNREQUESTED) {
        resource->generation = domain->nextGeneration + 1u;
        domain->nextGeneration = resource->generation;
        if (!cjgui_linux_image_enqueue_locked(domain, resource)) {
            resource->state = CJGUI_LINUX_IMAGE_BUSY;
        }
        state = resource->state;
    }
    pthread_mutex_unlock(&domain->mutex);
    return state;
}

uint32_t cjgui_linux_image_state(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                 const char *resourceId, uint64_t resourceVersion)
{
    if (domain == NULL) return CJGUI_LINUX_IMAGE_UNREQUESTED;
    char key[CJGUI_LINUX_IMAGE_KEY_CAPACITY];
    if (!cjgui_linux_image_cache_key(resourcePath, resourceId, resourceVersion, key, sizeof(key))) {
        return CJGUI_LINUX_IMAGE_UNREQUESTED;
    }
    pthread_mutex_lock(&domain->mutex);
    CjguiLinuxImageResource *resource = cjgui_linux_image_find(domain, key);
    uint32_t state = resource != NULL ? resource->state : CJGUI_LINUX_IMAGE_UNREQUESTED;
    pthread_mutex_unlock(&domain->mutex);
    return state;
}

void cjgui_linux_image_pump(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return;
    // 图片域本身不持有 fence：把已完成的上传 staging 与可回收纹理代交给 GPU
    // 维护点处理。此处只轮询真实提交，不等待设备，也不触发重绘。
    cjgui_linux_gpu_pump_image_resources(domain->gpu);
    for (;;) {
        pthread_mutex_lock(&domain->mutex);
        if (domain->completionCount == 0u) {
            cjgui_linux_image_start_busy_locked(domain);
            pthread_mutex_unlock(&domain->mutex);
            return;
        }
        CjguiLinuxImageCompletion completion = domain->completions[0];
        memset(&domain->completions[0], 0, sizeof(CjguiLinuxImageCompletion));
        if (domain->completionCount > 1u) {
            memmove(&domain->completions[0], &domain->completions[1],
                    sizeof(CjguiLinuxImageCompletion) * (domain->completionCount - 1u));
            // 搬移后清空尾槽：否则尾槽仍指向已随本次结算释放/移交的 key/rgba，
            // 销毁时会二次释放。
            memset(&domain->completions[domain->completionCount - 1u], 0,
                   sizeof(CjguiLinuxImageCompletion));
        }
        domain->completionCount -= 1u;
        cjgui_linux_image_release_reservation(domain, completion.reserved);
        pthread_cond_broadcast(&domain->cond);   // 唤醒等待完成队列空位的 worker

        CjguiLinuxImageResource *resource =
            completion.key != NULL ? cjgui_linux_image_find(domain, completion.key) : NULL;
        if (resource != NULL && resource->generation == completion.generation &&
            resource->state == CJGUI_LINUX_IMAGE_LOADING) {
            int uploaded = 0;
            int capacityFailed = 0;
            uint32_t width = completion.width;
            uint32_t height = completion.height;
            size_t bytes = (size_t)width * (size_t)height * 4u;
            if (completion.rgba != NULL && width > 0u && height > 0u) {
                // 先确认 ready 预算（必要时淘汰未引用项）；腾不出空间就具名失败，
                // 不把 9 张引用图静默塞进 8 项/32 MiB 缓存。
                int room = cjgui_linux_image_reserve_ready_room(domain, completion.key, bytes);
                resource = cjgui_linux_image_find(domain, completion.key);
                if (resource == NULL || resource->generation != completion.generation ||
                    resource->state != CJGUI_LINUX_IMAGE_LOADING) {
                    resource = NULL;
                } else if (!room) {
                    capacityFailed = 1;
                    domain->capacityFailureCount += 1u;
                } else if (domain->gpu == NULL) {
                    uploaded = 1;
                    resource->gpuSlot = -1;
                } else {
                    int slot = cjgui_linux_image_allocate_slot(domain);
                    if (slot >= 0 &&
                        cjgui_linux_gpu_upload_image(domain->gpu, (uint32_t)slot, width, height,
                                                     completion.rgba) == CJGUI_LINUX_GPU_OK) {
                        uploaded = 1;
                        resource->gpuSlot = slot;
                    }
                }
            }
            if (resource != NULL) {
                if (uploaded) {
                    resource->rgba = completion.rgba;
                    completion.rgba = NULL;
                    resource->bytes = bytes;
                    resource->width = width;
                    resource->height = height;
                    resource->state = CJGUI_LINUX_IMAGE_READY;
                    resource->retryable = 0;
                } else {
                    resource->state = CJGUI_LINUX_IMAGE_FAILED;
                    resource->retryable = capacityFailed ? 1 : 0;
                    if (capacityFailed) {
                        // 保留尺寸/字节，供预算释放后重试；像素本轮回给 completion 释放。
                        resource->width = width;
                        resource->height = height;
                        resource->bytes = bytes;
                    }
                    if (cjgui_linux_image_trace_enabled()) {
                        fprintf(stderr,
                                "CJGUI_LINUX_IMAGE failed key=%s reason=%s retryable=%d\n",
                                completion.key,
                                capacityFailed ? "ready_capacity" : "decode_or_upload",
                                resource->retryable);
                    }
                }
                resource->decodeMicros = completion.decodeMicros;
                domain->completionVersion += 1u;
                if (cjgui_linux_image_trace_enabled()) {
                    fprintf(stderr,
                            "CJGUI_LINUX_IMAGE settle key=%s state=%u size=%ux%u slot=%d "
                            "decode_us=%llu gpu_tex_bytes=%llu completion=%llu\n",
                            completion.key, resource->state, resource->width, resource->height,
                            resource->gpuSlot, (unsigned long long)resource->decodeMicros,
                            domain->gpu != NULL
                                ? (unsigned long long)cjgui_linux_gpu_image_texture_bytes(domain->gpu)
                                : 0ull,
                            (unsigned long long)domain->completionVersion);
                }
                cjgui_linux_image_enforce_cache(domain, completion.key);
            }
        }
        free(completion.key);
        free(completion.rgba);
        cjgui_linux_image_start_busy_locked(domain);
        pthread_mutex_unlock(&domain->mutex);
    }
}

int cjgui_linux_image_texture(CjguiLinuxImageDomain *domain, const char *resourcePath,
                              const char *resourceId, uint64_t resourceVersion,
                              uint32_t *outWidth, uint32_t *outHeight, uint32_t *outSlot)
{
    if (outWidth != NULL) *outWidth = 0u;
    if (outHeight != NULL) *outHeight = 0u;
    if (outSlot != NULL) *outSlot = UINT32_MAX;
    if (domain == NULL) return 0;
    // 纯读取：纹理上传只在帧外 pump 发生。若在帧内 pump，解码结果会撞上
    // “upload inside a frame”而被误判失败。
    char key[CJGUI_LINUX_IMAGE_KEY_CAPACITY];
    if (!cjgui_linux_image_cache_key(resourcePath, resourceId, resourceVersion, key, sizeof(key))) {
        return 0;
    }
    pthread_mutex_lock(&domain->mutex);
    CjguiLinuxImageResource *resource = cjgui_linux_image_find(domain, key);
    int ready = 0;
    if (resource != NULL && resource->state == CJGUI_LINUX_IMAGE_READY) {
        if (outWidth != NULL) *outWidth = resource->width;
        if (outHeight != NULL) *outHeight = resource->height;
        if (outSlot != NULL) {
            *outSlot = resource->gpuSlot >= 0 ? (uint32_t)resource->gpuSlot : UINT32_MAX;
        }
        ready = 1;
        domain->accessClock += 1u;
        resource->lastAccess = domain->accessClock;
    }
    pthread_mutex_unlock(&domain->mutex);
    return ready;
}

void cjgui_linux_image_clear_references(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return;
    pthread_mutex_lock(&domain->mutex);
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        domain->resources[i].referenced = 0;
    }
    pthread_mutex_unlock(&domain->mutex);
}

void cjgui_linux_image_add_reference(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                     const char *resourceId, uint64_t resourceVersion)
{
    if (domain == NULL) return;
    char key[CJGUI_LINUX_IMAGE_KEY_CAPACITY];
    if (!cjgui_linux_image_cache_key(resourcePath, resourceId, resourceVersion, key, sizeof(key))) return;
    pthread_mutex_lock(&domain->mutex);
    CjguiLinuxImageResource *resource = cjgui_linux_image_find(domain, key);
    if (resource != NULL) resource->referenced = 1;
    pthread_mutex_unlock(&domain->mutex);
}

uint64_t cjgui_linux_image_completion_version(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint64_t version = domain->completionVersion;
    pthread_mutex_unlock(&domain->mutex);
    return version;
}

uint64_t cjgui_linux_image_decode_start_count(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint64_t count = domain->decodeStartCount;
    pthread_mutex_unlock(&domain->mutex);
    return count;
}

uint64_t cjgui_linux_image_cache_bytes(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint64_t total = 0u;
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        if (domain->resources[i].state == CJGUI_LINUX_IMAGE_READY) {
            total += domain->resources[i].bytes;
        }
    }
    pthread_mutex_unlock(&domain->mutex);
    return total;
}

uint32_t cjgui_linux_image_live_count(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint32_t count = domain->resourceCount;
    pthread_mutex_unlock(&domain->mutex);
    return count;
}

uint32_t cjgui_linux_image_ready_count(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint32_t count = 0u;
    for (uint32_t i = 0u; i < domain->resourceCount; i += 1u) {
        if (domain->resources[i].state == CJGUI_LINUX_IMAGE_READY) count += 1u;
    }
    pthread_mutex_unlock(&domain->mutex);
    return count;
}

uint64_t cjgui_linux_image_inflight_bytes(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint64_t bytes = domain->inflightBytes;
    pthread_mutex_unlock(&domain->mutex);
    return bytes;
}

uint64_t cjgui_linux_image_cache_eviction_count(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint64_t count = domain->cacheEvictionCount;
    pthread_mutex_unlock(&domain->mutex);
    return count;
}

uint64_t cjgui_linux_image_capacity_failure_count(CjguiLinuxImageDomain *domain)
{
    if (domain == NULL) return 0u;
    pthread_mutex_lock(&domain->mutex);
    uint64_t count = domain->capacityFailureCount;
    pthread_mutex_unlock(&domain->mutex);
    return count;
}
