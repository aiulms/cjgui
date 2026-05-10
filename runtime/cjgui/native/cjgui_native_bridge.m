/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 仅实现 no-resource callable C ABI、AppKit import / class availability /
 * main-thread admission / no-object creation boundary 与确定性整数事实，不是运行时 bridge truth。
 * Stop-line: 只允许 pthread 当前线程分类、bridge-local token facts、AppKit import /
 * class lookup / main-thread admission / no-object creation facts、fixed-capacity
 * NSView token table first slice，以及 QuartzCore / CAMetalLayer no-attach facts；
 * 不创建 layer，不返回 pointer。
 * Same-shape Boundary Brake: callable surface 不得被包装成 native bridge、Metal、backend、GPU、render 或 public API permission。
 */
#import "cjgui_native_bridge.h"
#if defined(__APPLE__)
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#define CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT 1
#define CJGUI_NATIVE_BRIDGE_HAS_QUARTZCORE_IMPORT 1
#else
#define CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT 0
#define CJGUI_NATIVE_BRIDGE_HAS_QUARTZCORE_IMPORT 0
#endif
#include <pthread.h>

/*
 * 当前 callable 只暴露 no-resource status / capability / thread-classification /
 * token / import / class lookup / main-thread admission / no-object creation / NSView
 * token-backed first-slice facts / CAMetalLayer no-attach class facts。
 * pthread_main_np 只分类当前线程；token table 只保存 active flag 与 generation。
 * teardown admission 只做 fail-closed 分类，不执行真实 native 生命周期。
 * AppKit import / class availability / main-thread admission boundary 只证明 no-object facts 可观察。
 * NSView first slice 只在 main thread 创建 / 清空固定容量 table entry，不创建 window / layer / Metal。
 * QuartzCore / CAMetalLayer no-attach boundary 只做 class lookup，不创建或 attach layer。
 */
typedef struct CjguiNativeBridgeTokenTableEntry {
    uint32_t generation;
    uint8_t active;
} CjguiNativeBridgeTokenTableEntry;

typedef struct CjguiNativeBridgeDecodedToken {
    uint32_t slot_index;
    uint32_t generation;
    int32_t classification;
} CjguiNativeBridgeDecodedToken;

typedef struct CjguiNativeBridgeNsViewTableEntry {
    uint64_t token;
#if defined(__APPLE__)
    __strong NSView *view;
#endif
    uint8_t active;
} CjguiNativeBridgeNsViewTableEntry;

static pthread_mutex_t g_cjgui_native_bridge_token_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeTokenTableEntry
    g_cjgui_native_bridge_token_table[CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_nsview_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeNsViewTableEntry
    g_cjgui_native_bridge_nsview_table[CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY];

static uint64_t token_table_make_token(
    uint32_t slot_index,
    uint32_t generation
) {
    return ((uint64_t)generation << CJGUI_NATIVE_BRIDGE_TOKEN_SLOT_BITS) |
        (uint64_t)(slot_index + 1u);
}

static CjguiNativeBridgeDecodedToken token_table_decode_token(
    uint64_t token
) {
    if (token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return (CjguiNativeBridgeDecodedToken){
            0u,
            0u,
            CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID
        };
    }

    uint64_t encoded_slot = token & CJGUI_NATIVE_BRIDGE_TOKEN_SLOT_MASK;
    uint64_t encoded_generation =
        token >> CJGUI_NATIVE_BRIDGE_TOKEN_SLOT_BITS;
    if (encoded_slot == 0u ||
        encoded_slot > CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY ||
        encoded_generation == 0u ||
        encoded_generation > UINT32_MAX) {
        return (CjguiNativeBridgeDecodedToken){
            0u,
            0u,
            CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE
        };
    }

    return (CjguiNativeBridgeDecodedToken){
        (uint32_t)(encoded_slot - 1u),
        (uint32_t)encoded_generation,
        CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID
    };
}

static uint32_t token_table_next_generation(uint32_t generation) {
    uint32_t next_generation = generation + 1u;
    return next_generation == 0u ? 1u : next_generation;
}

static uint32_t nsview_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nsview_table[slot_index].active == 1u) {
            count++;
        }
    }
    return count;
}

static int32_t nsview_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nsview_table[slot_index].active == 1u &&
            g_cjgui_native_bridge_nsview_table[slot_index].token == token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t nsview_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nsview_table[slot_index].active == 0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

uint32_t cjgui_native_bridge_surface_version(void) {
    return CJGUI_NATIVE_BRIDGE_SURFACE_VERSION;
}

uint32_t cjgui_native_bridge_surface_capabilities(void) {
    return CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_VERSION_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_STATUS_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAPABILITY_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NO_RESOURCE_ADMISSION |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_MAIN_THREAD_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_TOKEN_TABLE_SHELL |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_TOKEN_ISSUE_REVOKE |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_TEARDOWN_ADMISSION |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_APPKIT_IMPORT_BOUNDARY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_APPKIT_CLASS_AVAILABILITY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_APPKIT_MAIN_THREAD_ADMISSION |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_PLATFORM_OBJECT_NO_OBJECT_CREATION |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NSVIEW_OBJECT_TABLE_SHELL |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NSVIEW_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_NO_ATTACH;
}

uint32_t cjgui_native_bridge_status_ok(void) {
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
}

uint32_t cjgui_native_bridge_no_resource_admission(void) {
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
}

int32_t cjgui_native_bridge_is_main_thread(void) {
#if defined(__APPLE__)
    return pthread_main_np() == 1 ? 1 : 0;
#else
    return -1;
#endif
}

uint64_t cjgui_native_bridge_token_invalid(void) {
    return CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
}

uint32_t cjgui_native_bridge_token_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_token_table_enabled(void) {
    return 1u;
}

int32_t cjgui_native_bridge_token_classify(uint64_t token) {
    CjguiNativeBridgeDecodedToken decoded =
        token_table_decode_token(token);
    if (decoded.classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return decoded.classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_token_table_mutex);
    CjguiNativeBridgeTokenTableEntry entry =
        g_cjgui_native_bridge_token_table[decoded.slot_index];
    pthread_mutex_unlock(&g_cjgui_native_bridge_token_table_mutex);

    if (entry.active == 1u && entry.generation == decoded.generation) {
        return CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID;
    }
    return CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE;
}

uint64_t cjgui_native_bridge_token_issue(void) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    }
#endif

    pthread_mutex_lock(&g_cjgui_native_bridge_token_table_mutex);
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_token_table[slot_index].active == 0u) {
            g_cjgui_native_bridge_token_table[slot_index].generation =
                token_table_next_generation(
                    g_cjgui_native_bridge_token_table[slot_index].generation
                );
            g_cjgui_native_bridge_token_table[slot_index].active = 1u;
            uint64_t token =
                token_table_make_token(
                    slot_index,
                    g_cjgui_native_bridge_token_table[slot_index].generation
                );
            pthread_mutex_unlock(&g_cjgui_native_bridge_token_table_mutex);
            return token;
        }
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_token_table_mutex);
    return CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
}

int32_t cjgui_native_bridge_token_revoke(uint64_t token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_MAIN_THREAD_REQUIRED;
    }
#endif

    CjguiNativeBridgeDecodedToken decoded =
        token_table_decode_token(token);
    if (decoded.classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return decoded.classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_token_table_mutex);
    if (g_cjgui_native_bridge_token_table[decoded.slot_index].active != 1u ||
        g_cjgui_native_bridge_token_table[decoded.slot_index].generation !=
            decoded.generation) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_token_table_mutex);
        return CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE;
    }

    g_cjgui_native_bridge_token_table[decoded.slot_index].active = 0u;
    g_cjgui_native_bridge_token_table[decoded.slot_index].generation =
        token_table_next_generation(
            g_cjgui_native_bridge_token_table[decoded.slot_index].generation
        );
    pthread_mutex_unlock(&g_cjgui_native_bridge_token_table_mutex);
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
}

int32_t cjgui_native_bridge_teardown_admission(uint64_t token) {
    int32_t classification = cjgui_native_bridge_token_classify(token);
    if (classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DANGLING_TOKEN_DENIED;
    }
    return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_REVOKE_BEFORE_DESTROY_REQUIRED;
}

int32_t cjgui_native_bridge_destroy_not_supported(void) {
    return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DESTROY_NOT_SUPPORTED;
}

int32_t cjgui_native_bridge_revoke_before_destroy_required(void) {
    return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_REVOKE_BEFORE_DESTROY_REQUIRED;
}

int32_t cjgui_native_bridge_double_destroy_classify(uint64_t token) {
    int32_t classification = cjgui_native_bridge_token_classify(token);
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DOUBLE_DESTROY_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_REVOKE_BEFORE_DESTROY_REQUIRED;
    }
    return CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DANGLING_TOKEN_DENIED;
}

int32_t cjgui_native_bridge_appkit_import_available(void) {
    return CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT == 1 ?
        CJGUI_NATIVE_BRIDGE_APPKIT_IMPORT_AVAILABLE :
        CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
}

int32_t cjgui_native_bridge_appkit_no_object_admission(void) {
    return CJGUI_NATIVE_BRIDGE_APPKIT_NO_OBJECT_ADMISSION;
}

int32_t cjgui_native_bridge_platform_object_create_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_appkit_nswindow_class_available(void) {
#if defined(__APPLE__)
    return NSClassFromString(@"NSWindow") != Nil ?
        CJGUI_NATIVE_BRIDGE_APPKIT_NSWINDOW_CLASS_AVAILABLE :
        CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_appkit_nsview_class_available(void) {
#if defined(__APPLE__)
    return NSClassFromString(@"NSView") != Nil ?
        CJGUI_NATIVE_BRIDGE_APPKIT_NSVIEW_CLASS_AVAILABLE :
        CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_appkit_class_lookup_no_object_admission(void) {
    return CJGUI_NATIVE_BRIDGE_APPKIT_CLASS_LOOKUP_NO_OBJECT_ADMISSION;
}

int32_t cjgui_native_bridge_platform_object_allocation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_ALLOCATION_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_appkit_platform_object_main_thread_required(void) {
    return CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_appkit_platform_object_main_thread_admitted(void) {
#if defined(__APPLE__)
    return pthread_main_np() == 1 ?
        CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_MAIN_THREAD_ADMITTED :
        CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_BACKGROUND_THREAD_DENIED;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_appkit_platform_object_background_thread_denied(void) {
    return CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_BACKGROUND_THREAD_DENIED;
}

int32_t cjgui_native_bridge_appkit_platform_object_creation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_CREATION_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_platform_object_create_no_object_admission(void) {
    return CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_NO_OBJECT_ADMISSION;
}

int32_t cjgui_native_bridge_platform_object_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_REQUIRES_MAIN_THREAD;
}

int32_t cjgui_native_bridge_platform_object_create_requires_token_contract(void) {
    return CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_REQUIRES_TOKEN_CONTRACT;
}

int32_t cjgui_native_bridge_platform_object_create_allocation_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_ALLOCATION_BLOCKED;
}

uint32_t cjgui_native_bridge_nsview_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_nsview_table_enabled(void) {
    return 1u;
}

int32_t cjgui_native_bridge_nsview_table_empty(void) {
    return CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_EMPTY;
}

int32_t cjgui_native_bridge_nsview_table_token_classify(uint64_t token) {
    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return token_classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t slot_index = nsview_table_find_token_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_nsview_table_allocation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_ALLOCATION_BLOCKED;
}

int32_t cjgui_native_bridge_nsview_table_destroy_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_DESTROY_BLOCKED;
}

uint32_t cjgui_native_bridge_nsview_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    uint32_t count = nsview_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_nsview_token_classify(uint64_t token) {
    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_STALE_TOKEN_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return token_classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t slot_index = nsview_table_find_token_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_nsview_create(uint64_t* out_token) {
    if (out_token == 0) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_OUT_TOKEN_REQUIRED;
    }
    *out_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_CREATE_MAIN_THREAD_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t free_slot = nsview_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_CAPACITY_EXHAUSTED;
    }

    uint64_t token = cjgui_native_bridge_token_issue();
    if (token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_CAPACITY_EXHAUSTED;
    }

    NSView *view = [[NSView alloc] initWithFrame:NSZeroRect];
    if (view == nil) {
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_NSVIEW_ALLOCATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (g_cjgui_native_bridge_nsview_table[free_slot].active != 0u) {
        free_slot = nsview_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_NSVIEW_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_nsview_table[free_slot].token = token;
    g_cjgui_native_bridge_nsview_table[free_slot].view = view;
    g_cjgui_native_bridge_nsview_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    *out_token = token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_nsview_destroy(uint64_t token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return token_classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t slot_index = nsview_table_find_token_locked(token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
        return CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_nsview_table[slot_index].view = nil;
    g_cjgui_native_bridge_nsview_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_nsview_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_nsview_double_destroy_classify(uint64_t token) {
    int32_t classification = cjgui_native_bridge_nsview_token_classify(token);
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_NSVIEW_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_nsview_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_NSVIEW_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_quartzcore_import_available(void) {
    return CJGUI_NATIVE_BRIDGE_HAS_QUARTZCORE_IMPORT == 1 ?
        CJGUI_NATIVE_BRIDGE_QUARTZCORE_IMPORT_AVAILABLE :
        CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
}

int32_t cjgui_native_bridge_cametallayer_class_available(void) {
#if defined(__APPLE__)
    return NSClassFromString(@"CAMetalLayer") != Nil ?
        CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CLASS_AVAILABLE :
        CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_no_attach_admission(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_NO_ATTACH_ADMISSION;
}

int32_t cjgui_native_bridge_cametallayer_allocation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_cametallayer_device_binding_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DEVICE_BINDING_STILL_BLOCKED;
}
