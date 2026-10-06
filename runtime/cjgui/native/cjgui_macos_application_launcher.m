// Framework-owned macOS process host for a Cangjie GUI application.
//
// AppKit permanently owns the process main thread. The standard Cangjie entry
// instead runs on a worker attached to its runtime scheduler; the internal
// renderer synchronously marshals its narrow operations back to AppKit. This
// file owns no application state, controller, external authorization or UI
// layout, and exposes no lifecycle foreign function to application code.

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cjgui_internal_renderer.h"
#include "cjgui_native_bridge.h"

extern int InitCJRuntime(const void *parameter);
typedef void (*CjguiRuntimeStart)(void *entry);

// Runtime parameter block, declared EXACTLY as the official open-source runtime
// publishes it (https://github.com/Cangjie-Pub/cangjie_runtime,
// runtime/src/Cangjie.h, struct RuntimeParam; the toolchain does not ship the
// header). Zeroed fields mean "runtime default". The only field this host sets
// is coParam.coStackSize: the launcher comment below explains why a GUI
// application's layout solver needs far more than the 64 KB-class default.
struct CjguiHeapParam {
    size_t regionSize;
    size_t heapSize;
    double exemptionThreshold;
    double heapUtilization;
    double heapGrowth;
    double allocationRate;
    size_t allocationWaitTime;
};
struct CjguiGCParam {
    size_t gcThreshold;
    double garbageThreshold;
    uint64_t gcInterval;
    uint64_t backupGCInterval;
    int32_t gcThreads;
};
struct CjguiLogParam {
    int logLevel;
};
struct CjguiConcurrencyParam {
    size_t thStackSize;
    size_t coStackSize;
    uint32_t processorNum;
};
struct CjguiRuntimeParam {
    struct CjguiHeapParam heapParam;
    struct CjguiGCParam gcParam;
    struct CjguiLogParam logParam;
    struct CjguiConcurrencyParam coParam;
};

static pthread_mutex_t gCjguiRuntimeLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gCjguiRuntimeCondition = PTHREAD_COND_INITIALIZER;
static bool gCjguiRuntimeInitialized = false;
static bool gCjguiRuntimeReady = false;
static bool gCjguiCompilerEntryReady = false;
static void *gCjguiCompilerEntry = NULL;
static CjguiRuntimeStart gCjguiRuntimeStart = NULL;

static CjguiRuntimeStart CjguiResolveRuntimeStart(void) {
    CjguiRuntimeStart start = (CjguiRuntimeStart)dlsym(RTLD_NEXT, "CJ_MRT_CjRuntimeStart");
    if (!start) {
        fprintf(stderr, "cjgui macOS application host: cannot resolve Cangjie runtime start\n");
        abort();
    }
    return start;
}

static void *CjguiRuntimeWorker(void *unused) {
    (void)unused;
    // The only non-default parameter is the CJTHREAD stack size. The layout
    // engine recurses per container level (measured: a 7-level visual body
    // scene overflows the class-default cjthread stack before the scene is
    // ever accepted); 16 MiB is inside the runtime's documented [64KB, 1GB]
    // range and is only virtually reserved per cjthread.
    struct CjguiRuntimeParam runtimeParameter;
    memset(&runtimeParameter, 0, sizeof(runtimeParameter));
    runtimeParameter.coParam.coStackSize = 16ULL * 1024 * 1024 / 1024; /* KB */
    int initializationResult = InitCJRuntime(&runtimeParameter);

    pthread_mutex_lock(&gCjguiRuntimeLock);
    gCjguiRuntimeReady = initializationResult == 0;
    gCjguiRuntimeInitialized = true;
    pthread_cond_broadcast(&gCjguiRuntimeCondition);
    while (gCjguiRuntimeReady && !gCjguiCompilerEntryReady) {
        pthread_cond_wait(&gCjguiRuntimeCondition, &gCjguiRuntimeLock);
    }
    void *entry = gCjguiCompilerEntry;
    CjguiRuntimeStart start = gCjguiRuntimeStart;
    pthread_mutex_unlock(&gCjguiRuntimeLock);

    if (gCjguiRuntimeReady && entry && start) {
        start(entry);
    }
    const char *trace = getenv("CJGUI_OWNER_PHASE_TRACE");
    if (trace && strcmp(trace, "1") == 0) {
        uint64_t tid = 0;
        pthread_threadid_np(NULL, &tid);
        fprintf(stderr, "CJGUI_APPLICATION_RUNTIME_START_RETURN tid=%llu mono_ns=%llu managed_completion=unknown\n",
            (unsigned long long)tid, (unsigned long long)cjgui_internal_renderer_owner_clock_ns());
        fflush(stderr);
    }
    // Runtime start schedules managed work and may return before application
    // `main` completes. The framework host therefore requests AppKit stop
    // only after its actual close/failure cleanup path finishes.
    return NULL;
}

void CJ_MRT_CjRuntimeInit(void) {
    if (![NSThread isMainThread]) {
        fprintf(stderr, "cjgui macOS application host: runtime init was not on main thread\n");
        abort();
    }

    gCjguiRuntimeStart = CjguiResolveRuntimeStart();
    // 2026-09-26: the runtime worker MUST carry an explicit large stack. With
    // default attributes macOS gives a pthread only 512 KiB, and the Cangjie
    // `main` runs ON THIS THREAD: the layout solver recurses a few containers
    // deep (a visual body scene nests ~7 layout levels) and dies with
    // StackOverflowError before the scene is ever accepted -- measured with a
    // bounded visit log: 24 legal node visits, then overflow, on a 141-byte
    // document. 64 MiB is lazily committed by macOS, so reserving it is free.
    pthread_attr_t workerAttr;
    pthread_attr_init(&workerAttr);
    pthread_attr_setstacksize(&workerAttr, 64ULL * 1024 * 1024);
    pthread_t worker;
    if (pthread_create(&worker, &workerAttr, CjguiRuntimeWorker, NULL) != 0) {
        fprintf(stderr, "cjgui macOS application host: cannot create Cangjie runtime worker\n");
        abort();
    }
    pthread_attr_destroy(&workerAttr);
    pthread_detach(worker);

    pthread_mutex_lock(&gCjguiRuntimeLock);
    while (!gCjguiRuntimeInitialized) {
        pthread_cond_wait(&gCjguiRuntimeCondition, &gCjguiRuntimeLock);
    }
    bool ready = gCjguiRuntimeReady;
    pthread_mutex_unlock(&gCjguiRuntimeLock);
    if (!ready) {
        fprintf(stderr, "cjgui macOS application host: cannot initialize Cangjie runtime worker\n");
        abort();
    }
}

int CJ_MRT_CjRuntimeStart(void *entry) {
    if (![NSThread isMainThread]) {
        fprintf(stderr, "cjgui macOS application host: runtime start was not on main thread\n");
        abort();
    }

    cjgui_internal_renderer_enable_main_thread_dispatch();
    cjgui_macos_enable_accent_sampling();
    pthread_mutex_lock(&gCjguiRuntimeLock);
    gCjguiCompilerEntry = entry;
    gCjguiCompilerEntryReady = true;
    pthread_cond_signal(&gCjguiRuntimeCondition);
    pthread_mutex_unlock(&gCjguiRuntimeLock);

    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application run];
    const char *trace = getenv("CJGUI_OWNER_PHASE_TRACE");
    if (trace && strcmp(trace, "1") == 0) {
        uint64_t tid = 0;
        pthread_threadid_np(NULL, &tid);
        fprintf(stderr, "CJGUI_APPLICATION_LAUNCHER_RETURN tid=%llu mono_ns=%llu\n",
            (unsigned long long)tid, (unsigned long long)cjgui_internal_renderer_owner_clock_ns());
        fflush(stderr);
    }
    return EXIT_SUCCESS;
}
