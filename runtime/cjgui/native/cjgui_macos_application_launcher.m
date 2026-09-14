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
#include "cjgui_internal_renderer.h"

extern int InitCJRuntime(const void *parameter);
typedef void (*CjguiRuntimeStart)(void *entry);

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
    // The runtime accepts a documented-default parameter block. Reserve more
    // than its current size with 64-bit alignment rather than copying a
    // private runtime declaration into application source.
    uint64_t runtimeParameter[32] = {0};
    int initializationResult = InitCJRuntime(runtimeParameter);

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
    pthread_t worker;
    if (pthread_create(&worker, NULL, CjguiRuntimeWorker, NULL) != 0) {
        fprintf(stderr, "cjgui macOS application host: cannot create Cangjie runtime worker\n");
        abort();
    }
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
    pthread_mutex_lock(&gCjguiRuntimeLock);
    gCjguiCompilerEntry = entry;
    gCjguiCompilerEntryReady = true;
    pthread_cond_signal(&gCjguiRuntimeCondition);
    pthread_mutex_unlock(&gCjguiRuntimeLock);

    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application run];
    return EXIT_SUCCESS;
}
