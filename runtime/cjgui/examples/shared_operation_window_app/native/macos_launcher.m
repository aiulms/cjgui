// macOS runtime-start interposer for the shared-operation sample.
//
// AppKit owns the macOS process main thread. The compiler-generated Cangjie
// entry runs through the normal Cangjie runtime start path on a dedicated
// worker, so native UI calls can marshal to AppKit without the default
// scheduler consuming the process main thread. This launcher owns no records
// or action decisions.

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "../../../native/cjgui_internal_renderer.h"

// `InitCJRuntime` is the runtime's public C bootstrap. It attaches the
// caller to its scheduler before the normal `CJ_MRT_CjRuntimeStart` path is
// entered. The all-zero parameter block selects its documented defaults. It
// stays private to this example launcher; no runtime object crosses CJGUI's
// public Cangjie boundary.
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
    CjguiRuntimeStart start = (CjguiRuntimeStart)dlsym(
        RTLD_NEXT, "CJ_MRT_CjRuntimeStart");
    if (!start) {
        fprintf(stderr, "cjgui macOS launcher: cannot resolve Cangjie runtime start\n");
        abort();
    }
    return start;
}

static void *CjguiRuntimeWorker(void *unused) {
    (void)unused;
    // The runtime currently accepts a 128-byte RuntimeParam. Reserve more
    // than that with natural 64-bit alignment so this launcher does not copy
    // private runtime declarations into the product source.
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
        // This is the unmodified runtime entry path: it prepares the managed
        // task and mutator state before invoking compiler-generated code.
        start(entry);
    }
    return NULL;
}

// Called by the Cangjie app after it closes its own renderer session. This is
// a narrow lifecycle boundary, not a state mutation path.
void cjgui_shared_operation_window_app_finish(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp stop:nil];
        [NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                            location:NSZeroPoint
                                       modifierFlags:0
                                           timestamp:0
                                        windowNumber:0
                                             context:nil
                                             subtype:0
                                               data1:0
                                               data2:0]
                atStart:NO];
    });
}

// The compiler first initializes the runtime from the process main thread.
// Move that initialization to the worker so the default scheduler is attached
// there; the main thread remains exclusively available to AppKit.
void CJ_MRT_CjRuntimeInit(void) {
    if (![NSThread isMainThread]) {
        fprintf(stderr, "cjgui macOS launcher: runtime init was not on main thread\n");
        abort();
    }

    gCjguiRuntimeStart = CjguiResolveRuntimeStart();
    pthread_t worker;
    if (pthread_create(&worker, NULL, CjguiRuntimeWorker, NULL) != 0) {
        fprintf(stderr, "cjgui macOS launcher: cannot create Cangjie runtime worker\n");
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
        fprintf(stderr, "cjgui macOS launcher: cannot initialize Cangjie runtime worker\n");
        abort();
    }
}

// The compiler treats this runtime-start entry as a no-result call, but its
// generated C `main` returns immediately afterward without assigning the
// platform return register.  Returning an explicit integer is ABI-compatible
// with that caller (which ignores it), and ensures the macOS C runtime sees a
// deterministic success result after the AppKit loop stops.
//
// The compiler entry is handed to the initialized worker, then the actual
// macOS main loop owns the process main thread.
int CJ_MRT_CjRuntimeStart(void *entry) {
    if (![NSThread isMainThread]) {
        fprintf(stderr, "cjgui macOS launcher: runtime start was not on main thread\n");
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
