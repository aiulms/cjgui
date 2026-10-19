// runtime/cjgui/platforms/linux/native/cjgui_linux_async_measure.c
//
// Linux 上的有界异步文字测量桥（`cjgui_async_composable_multiline_begin` /
// `CjguiAsyncMultilineMeasurePoll` / `..._Release` / `cjgui_async_composable_text_metrics_begin` /
// `CjguiAsyncTextMetricsPoll`）。
//
// 为什么需要真异步而不是"下一次泵时再算"：这几个入口存在的唯一理由就是**不把
// 大文档的多行测量压在调用 turn 上**。同步伪装的实现会让最坏情况回到主线程，
// 属于"看起来接通了但没有"。所以这里给 worker 线程一个**自己的** text 实例
// （cjgui_linux_text 的契约要求"只在所属线程调用"，因此实例不跨线程共享），
// 主线程只做拷贝与取结果。
//
// 线程与生命周期：
//   * 作业表固定容量（4）。满了返回 CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY。
//   * worker 在第一个作业时惰性创建，进程退出时不强制回收（进程级单例）。
//   * Release(consumed) 后 handle 立即失效；Release(abandoned) 抛掉结果。
//   * 文本在 begin 时复制进作业，调用方指针不被保留。

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#include "cjgui_internal_renderer.h"
#include "cjgui_linux_text.h"

#define CJGUI_ASYNC_MEASURE_STARTED 0
#define CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY 1
#define CJGUI_ASYNC_MEASURE_PENDING 2
#define CJGUI_ASYNC_MEASURE_READY 3
#define CJGUI_ASYNC_MEASURE_FAILED 4
#define CJGUI_ASYNC_MEASURE_CANCELLED 5
#define CJGUI_ASYNC_MEASURE_STALE_HANDLE 6
#define CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT 7
#define CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED 0
#define CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED 1
#define CJGUI_ASYNC_MEASURE_MAX_JOB_BYTES 131072

typedef enum CjguiLinuxAsyncKind {
    CJGUI_LINUX_ASYNC_MULTILINE_HEIGHT = 1,
    CJGUI_LINUX_ASYNC_TEXT_METRICS = 2
} CjguiLinuxAsyncKind;

typedef struct CjguiLinuxAsyncJob {
    int occupied;
    uint64_t handle;
    uint32_t state;
    CjguiLinuxAsyncKind kind;
    char *text;
    size_t textLength;
    double fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;
    uint32_t width;
    // 结果
    uint32_t height;
    CjguiInternalRendererTextMeasurement metrics;
    int32_t failure;
} CjguiLinuxAsyncJob;

#define CJGUI_LINUX_ASYNC_JOBS 4u

static CjguiLinuxAsyncJob g_jobs[CJGUI_LINUX_ASYNC_JOBS];
static pthread_mutex_t g_jobMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t g_jobAvailable = PTHREAD_COND_INITIALIZER;
static pthread_t g_worker;
static int g_workerStarted = 0;
static uint64_t g_nextHandle = 1u;
static int g_workerShutdown = 0;

static void *cjgui_linux_async_worker(void *argument) {
    int textStatus = 0;
    CjguiLinuxText *text = cjgui_linux_text_create(&textStatus);
    for (;;) {
        pthread_mutex_lock(&g_jobMutex);
        int jobIndex = -1;
        while (jobIndex < 0 && !g_workerShutdown) {
            for (uint32_t i = 0u; i < CJGUI_LINUX_ASYNC_JOBS; i += 1u) {
                if (g_jobs[i].occupied && g_jobs[i].state == CJGUI_ASYNC_MEASURE_STARTED) { jobIndex = (int)i; break; }
            }
            if (jobIndex < 0) pthread_cond_wait(&g_jobAvailable, &g_jobMutex);
        }
        if (g_workerShutdown) { pthread_mutex_unlock(&g_jobMutex); break; }
        CjguiLinuxAsyncJob *job = &g_jobs[jobIndex];
        // 在锁外计算：先把作业标记为 PENDING 并复制出参数。
        job->state = CJGUI_ASYNC_MEASURE_PENDING;
        char *jobText = job->text;
        size_t length = job->textLength;
        CjguiLinuxAsyncKind kind = job->kind;
        double fontSize = job->fontSize;
        uint32_t fontWeight = job->fontWeight;
        uint32_t fontFamily = job->fontFamily;
        uint32_t width = job->width;
        pthread_mutex_unlock(&g_jobMutex);

        uint32_t quadCount = 0u;
        double measuredWidth = 0.0, measuredHeight = 0.0, ascent = 0.0;
        int status = CJGUI_LINUX_TEXT_INVALID;
        if (text) {
            status = cjgui_linux_text_layout(text, jobText, length, fontSize, fontWeight, fontFamily,
                                             (double)width, 0.0, 0.0, 0, NULL, 0u, &quadCount, &measuredWidth,
                                             &measuredHeight, &ascent);
        }
        int ok = (status == CJGUI_LINUX_TEXT_OK || status == CJGUI_LINUX_TEXT_BUDGET_EXCEEDED);

        pthread_mutex_lock(&g_jobMutex);
        if (g_jobs[jobIndex].occupied && g_jobs[jobIndex].handle == job->handle) {
            if (g_jobs[jobIndex].state == CJGUI_ASYNC_MEASURE_CANCELLED) {
                // 已被取消：保留取消终态，不再覆盖。
            } else if (ok) {
                g_jobs[jobIndex].state = CJGUI_ASYNC_MEASURE_READY;
                g_jobs[jobIndex].height = (uint32_t)(measuredHeight + 0.5);
                memset(&g_jobs[jobIndex].metrics, 0, sizeof(g_jobs[jobIndex].metrics));
                g_jobs[jobIndex].metrics.width = (uint32_t)(measuredWidth + 0.5);
                g_jobs[jobIndex].metrics.height = (uint32_t)(measuredHeight + 0.5);
                g_jobs[jobIndex].metrics.baseline = (uint32_t)(ascent + 0.5);
                g_jobs[jobIndex].metrics.lineHeight = g_jobs[jobIndex].metrics.height;
                g_jobs[jobIndex].failure = 0;
            } else {
                g_jobs[jobIndex].state = CJGUI_ASYNC_MEASURE_FAILED;
                g_jobs[jobIndex].failure = (int32_t)status;
                if (getenv("CJGUI_LINUX_ASYNC_TRACE")) {
                    fprintf(stderr, "CJGUI_LINUX_ASYNC worker FAIL status=%d\n", (int)status);
                }
            }
        }
        (void)kind;
        pthread_mutex_unlock(&g_jobMutex);
    }
    // worker 自己的 text 实例随线程结束释放；进程退出路径不强制走这里。
    if (text) cjgui_linux_text_destroy(text);
    return NULL;
}

static int32_t cjgui_linux_async_begin(const char *text, uint64_t byteLength, double fontSize,
                                       uint32_t fontWeight, uint32_t fontFamily, uint32_t width,
                                       CjguiLinuxAsyncKind kind, uint64_t *outHandle) {
    if (outHandle) *outHandle = 0u;
    if (!text || !outHandle || fontSize <= 0.0 || width == 0u) return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    if (byteLength == 0u || byteLength > CJGUI_ASYNC_MEASURE_MAX_JOB_BYTES) {
        return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    }
    char *copy = (char *)malloc((size_t)byteLength + 1u);
    if (!copy) return CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY;
    memcpy(copy, text, (size_t)byteLength);
    copy[byteLength] = '\0';

    pthread_mutex_lock(&g_jobMutex);
    int slot = -1;
    for (uint32_t i = 0u; i < CJGUI_LINUX_ASYNC_JOBS; i += 1u) {
        if (!g_jobs[i].occupied) { slot = (int)i; break; }
    }
    if (slot < 0) {
        pthread_mutex_unlock(&g_jobMutex);
        free(copy);
        return CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY;
    }
    CjguiLinuxAsyncJob *job = &g_jobs[slot];
    job->occupied = 1;
    job->handle = g_nextHandle++;
    job->kind = kind;
    job->text = copy;
    job->textLength = (size_t)byteLength;
    job->fontSize = fontSize;
    job->fontWeight = fontWeight;
    job->fontFamily = fontFamily;
    job->width = width;
    job->height = 0u;
    job->failure = 0;
    memset(&job->metrics, 0, sizeof(job->metrics));
    job->state = CJGUI_ASYNC_MEASURE_STARTED;
    if (!g_workerStarted) {
        if (pthread_create(&g_worker, NULL, cjgui_linux_async_worker, NULL) == 0) {
            g_workerStarted = 1;
        } else {
            job->state = CJGUI_ASYNC_MEASURE_FAILED;
            job->failure = CJGUI_ASYNC_MEASURE_FAILED;
        }
    }
    if (outHandle) *outHandle = job->handle;
    if (getenv("CJGUI_LINUX_ASYNC_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ASYNC begin kind=%d bytes=%llu w=%u\n", (int)kind,
                (unsigned long long)byteLength, width);
    }
    pthread_cond_broadcast(&g_jobAvailable);
    pthread_mutex_unlock(&g_jobMutex);
    // 作业已入队；worker 存在与否决定它会不会进入 READY。这里不伪报 READY。
    return CJGUI_ASYNC_MEASURE_STARTED;
}

static CjguiLinuxAsyncJob *cjgui_linux_async_find(uint64_t handle) {
    for (uint32_t i = 0u; i < CJGUI_LINUX_ASYNC_JOBS; i += 1u) {
        if (g_jobs[i].occupied && g_jobs[i].handle == handle) return &g_jobs[i];
    }
    return NULL;
}

int32_t cjgui_async_composable_multiline_begin(const char *text, uint64_t byteLength, double fontSize,
                                               uint32_t fontWeight, uint32_t fontFamily, uint32_t contentWidth,
                                               uint64_t *outHandle) {
    return cjgui_linux_async_begin(text, byteLength, fontSize, fontWeight, fontFamily, contentWidth,
                                   CJGUI_LINUX_ASYNC_MULTILINE_HEIGHT, outHandle);
}

int32_t CjguiAsyncMultilineMeasurePoll(uint64_t handle, uint32_t *outHeight, int32_t *outFailure) {
    pthread_mutex_lock(&g_jobMutex);
    CjguiLinuxAsyncJob *job = cjgui_linux_async_find(handle);
    if (!job) { pthread_mutex_unlock(&g_jobMutex); return CJGUI_ASYNC_MEASURE_STALE_HANDLE; }
    int32_t state = (int32_t)job->state;
    if (state == CJGUI_ASYNC_MEASURE_READY && outHeight) *outHeight = job->height;
    if ((state == CJGUI_ASYNC_MEASURE_FAILED || state == CJGUI_ASYNC_MEASURE_CANCELLED) && outFailure) {
        *outFailure = job->failure;
    }
    pthread_mutex_unlock(&g_jobMutex);
    return state;
}

int32_t CjguiAsyncMultilineMeasureRelease(uint64_t handle, int32_t disposition) {
    pthread_mutex_lock(&g_jobMutex);
    CjguiLinuxAsyncJob *job = cjgui_linux_async_find(handle);
    if (!job) { pthread_mutex_unlock(&g_jobMutex); return CJGUI_ASYNC_MEASURE_STALE_HANDLE; }
    if (disposition == CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) {
        if (job->state == CJGUI_ASYNC_MEASURE_STARTED || job->state == CJGUI_ASYNC_MEASURE_PENDING) {
            job->state = CJGUI_ASYNC_MEASURE_CANCELLED;
            pthread_mutex_unlock(&g_jobMutex);
            return CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED;
        }
    }
    free(job->text);
    memset(job, 0, sizeof(*job));
    pthread_mutex_unlock(&g_jobMutex);
    return CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED;
}

int32_t cjgui_async_composable_text_metrics_begin(const char *text, uint64_t byteLength, double fontSize,
                                                  uint32_t fontWeight, uint32_t fontFamily,
                                                  uint32_t maximumWidth, uint64_t *outHandle) {
    return cjgui_linux_async_begin(text, byteLength, fontSize, fontWeight, fontFamily, maximumWidth,
                                   CJGUI_LINUX_ASYNC_TEXT_METRICS, outHandle);
}

int32_t CjguiAsyncTextMetricsPoll(uint64_t handle, CjguiInternalRendererTextMeasurement *outMetrics,
                                  int32_t *outFailure) {
    pthread_mutex_lock(&g_jobMutex);
    CjguiLinuxAsyncJob *job = cjgui_linux_async_find(handle);
    if (!job) { pthread_mutex_unlock(&g_jobMutex); return CJGUI_ASYNC_MEASURE_STALE_HANDLE; }
    int32_t state = (int32_t)job->state;
    if (state == CJGUI_ASYNC_MEASURE_READY && outMetrics) *outMetrics = job->metrics;
    if ((state == CJGUI_ASYNC_MEASURE_FAILED || state == CJGUI_ASYNC_MEASURE_CANCELLED) && outFailure) {
        *outFailure = job->failure;
    }
    pthread_mutex_unlock(&g_jobMutex);
    return state;
}
