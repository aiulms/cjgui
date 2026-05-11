/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 仅实现 no-resource callable C ABI、AppKit import / class availability /
 * main-thread admission / no-object creation boundary、CAMetalLayer allocation /
 * table / create-destroy / NSView attachment first slice、Metal device binding
 * first slice、MTLCommandQueue create/destroy first slice、
 * MTLCommandBuffer create/destroy first slice 与确定性整数事实，
 * 不是运行时 bridge truth。
 * Stop-line: 只允许 pthread 当前线程分类、bridge-local token facts、AppKit import /
 * class lookup / main-thread admission / no-object creation facts、fixed-capacity
 * NSView token table first slice，以及 QuartzCore / CAMetalLayer no-attach /
 * allocation / table / create-destroy / controlled NSView attachment facts、
 * Metal device availability / table / layer binding facts、fixed-capacity
 * command queue token facts、command buffer token facts；不获取 drawable，
 * command buffer first slice 不 commit / present / encoder / render，
 * 不返回 pointer。
 * Same-shape Boundary Brake: callable surface 不得被包装成 native bridge、Metal、backend、GPU、render 或 public API permission。
 */
#import "cjgui_native_bridge.h"
#if defined(__APPLE__)
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#define CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT 1
#define CJGUI_NATIVE_BRIDGE_HAS_METAL_IMPORT 1
#define CJGUI_NATIVE_BRIDGE_HAS_QUARTZCORE_IMPORT 1
#else
#define CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT 0
#define CJGUI_NATIVE_BRIDGE_HAS_METAL_IMPORT 0
#define CJGUI_NATIVE_BRIDGE_HAS_QUARTZCORE_IMPORT 0
#endif
#include <pthread.h>

/*
 * 当前 callable 只暴露 no-resource status / capability / thread-classification /
 * token / import / class lookup / main-thread admission / no-object creation / NSView
 * token-backed first-slice facts / CAMetalLayer no-attach / allocation /
 * table / create-destroy / NSView attachment facts / Metal device binding facts /
 * command queue create-destroy facts / command buffer create-destroy facts。
 * pthread_main_np 只分类当前线程；token table 只保存 active flag 与 generation。
 * teardown admission 只做 fail-closed 分类，不执行真实 native 生命周期。
 * AppKit import / class availability / main-thread admission boundary 只证明 no-object facts 可观察。
 * NSView first slice 只在 main thread 创建 / 清空固定容量 table entry，不创建 window / layer / Metal。
 * QuartzCore / CAMetalLayer no-attach boundary 只做 class lookup；allocation /
 * create-destroy first slice 只创建未绑定 drawable 的 fixed-capacity layer token。
 * Metal device first slice 只绑定 default device 到 CAMetalLayer；command queue
 * first slice 只创建 / 销毁 MTLCommandQueue；command buffer first slice
 * 只创建 / 清空 MTLCommandBuffer token，不 commit / present / encoder / render，
 * 不提交 GPU work。
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

typedef struct CjguiNativeBridgeCAMetalLayerTableEntry {
    uint64_t token;
    uint64_t attached_view_token;
    uint64_t bound_device_token;
#if defined(__APPLE__)
    __strong CAMetalLayer *layer;
#endif
    uint8_t active;
    uint8_t attached;
    uint8_t device_bound;
} CjguiNativeBridgeCAMetalLayerTableEntry;

typedef struct CjguiNativeBridgeMetalDeviceTableEntry {
    uint64_t token;
#if defined(__APPLE__)
    __strong id<MTLDevice> device;
#endif
    uint8_t active;
} CjguiNativeBridgeMetalDeviceTableEntry;

typedef struct CjguiNativeBridgeCommandQueueTableEntry {
    uint64_t token;
    uint64_t device_token;
#if defined(__APPLE__)
    __strong id<MTLCommandQueue> queue;
#endif
    uint8_t active;
} CjguiNativeBridgeCommandQueueTableEntry;

typedef struct CjguiNativeBridgeCommandBufferTableEntry {
    uint64_t token;
    uint64_t queue_token;
#if defined(__APPLE__)
    __strong id<MTLCommandBuffer> buffer;
#endif
    uint8_t active;
} CjguiNativeBridgeCommandBufferTableEntry;

static pthread_mutex_t g_cjgui_native_bridge_token_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeTokenTableEntry
    g_cjgui_native_bridge_token_table[CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_nsview_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeNsViewTableEntry
    g_cjgui_native_bridge_nsview_table[CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_cametallayer_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeCAMetalLayerTableEntry
    g_cjgui_native_bridge_cametallayer_table
        [CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_metal_device_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeMetalDeviceTableEntry
    g_cjgui_native_bridge_metal_device_table
        [CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_command_queue_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeCommandQueueTableEntry
    g_cjgui_native_bridge_command_queue_table
        [CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_command_buffer_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeCommandBufferTableEntry
    g_cjgui_native_bridge_command_buffer_table
        [CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY];

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

static uint32_t cametallayer_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_cametallayer_table[slot_index].active == 1u) {
            count++;
        }
    }
    return count;
}

static int32_t cametallayer_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_cametallayer_table[slot_index].active == 1u &&
            g_cjgui_native_bridge_cametallayer_table[slot_index].token == token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t cametallayer_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_cametallayer_table[slot_index].active == 0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t cametallayer_table_find_attached_view_locked(
    uint64_t view_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_cametallayer_table[slot_index].active == 1u &&
            g_cjgui_native_bridge_cametallayer_table[slot_index].attached == 1u &&
            g_cjgui_native_bridge_cametallayer_table[slot_index]
                .attached_view_token == view_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t cametallayer_table_find_bound_device_locked(
    uint64_t device_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_cametallayer_table[slot_index].active == 1u &&
            g_cjgui_native_bridge_cametallayer_table[slot_index].device_bound ==
                1u &&
            g_cjgui_native_bridge_cametallayer_table[slot_index]
                .bound_device_token == device_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t metal_device_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_metal_device_table[slot_index].active == 1u) {
            count++;
        }
    }
    return count;
}

static int32_t metal_device_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_metal_device_table[slot_index].active == 1u &&
            g_cjgui_native_bridge_metal_device_table[slot_index].token == token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t metal_device_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_metal_device_table[slot_index].active == 0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t command_queue_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_queue_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t command_queue_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_queue_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_command_queue_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t command_queue_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_queue_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t command_queue_table_find_bound_device_locked(
    uint64_t device_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_queue_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_command_queue_table[slot_index].device_token ==
                device_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t command_buffer_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_buffer_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t command_buffer_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_buffer_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_command_buffer_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t command_buffer_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_buffer_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t command_buffer_table_find_bound_queue_locked(
    uint64_t queue_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_command_buffer_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_command_buffer_table[slot_index].queue_token ==
                queue_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t cametallayer_attachment_layer_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_INVALID_LAYER_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_STALE_LAYER_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_LAYER_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t cametallayer_attachment_view_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_INVALID_VIEW_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_STALE_VIEW_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_VIEW_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t metal_device_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t metal_device_binding_layer_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_INVALID_LAYER_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_STALE_LAYER_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t metal_device_binding_device_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_INVALID_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_STALE_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DEVICE_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t command_queue_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t command_queue_device_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_INVALID_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_STALE_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DEVICE_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t command_buffer_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t command_buffer_queue_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_INVALID_QUEUE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_STALE_QUEUE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_QUEUE_TOKEN_NOT_BOUND;
    }
    return classification;
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
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_NO_ATTACH |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_ALLOCATION |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_OBJECT_TABLE |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_NSVIEW_ATTACHMENT |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_METAL_DEVICE_AVAILABILITY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_METAL_DEVICE_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_METAL_DEVICE_LAYER_BINDING |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_COMMAND_QUEUE_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_COMMAND_BUFFER_CREATE_DESTROY;
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

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t attached_layer_slot =
        cametallayer_table_find_attached_view_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (attached_layer_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DETACH_BEFORE_DESTROY_REQUIRED;
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

int32_t cjgui_native_bridge_cametallayer_allocation_feasible(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_FEASIBLE;
}

int32_t cjgui_native_bridge_cametallayer_allocation_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_cametallayer_allocation_no_attach_admission(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_NO_ATTACH_ADMISSION;
}

int32_t cjgui_native_bridge_cametallayer_allocation_device_binding_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_DEVICE_BINDING_BLOCKED;
}

int32_t cjgui_native_bridge_cametallayer_allocation_feasibility_probe(void) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_MAIN_THREAD_REQUIRED;
    }

    @autoreleasepool {
        CAMetalLayer *layer = [CAMetalLayer layer];
        if (layer == nil) {
            return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_FAILED;
        }
    }
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_FEASIBILITY_OBSERVED;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

uint32_t cjgui_native_bridge_cametallayer_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_cametallayer_table_enabled(void) {
    return 1u;
}

int32_t cjgui_native_bridge_cametallayer_table_empty(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_EMPTY;
}

int32_t cjgui_native_bridge_cametallayer_table_token_classify(uint64_t token) {
    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return token_classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t slot_index = cametallayer_table_find_token_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_cametallayer_table_allocation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_ALLOCATION_BLOCKED;
}

int32_t cjgui_native_bridge_cametallayer_table_destroy_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_DESTROY_BLOCKED;
}

uint32_t cjgui_native_bridge_cametallayer_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    uint32_t count = cametallayer_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_cametallayer_token_classify(uint64_t token) {
    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_STALE_TOKEN_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return token_classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t slot_index = cametallayer_table_find_token_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_cametallayer_create(uint64_t* out_token) {
    if (out_token == 0) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_OUT_TOKEN_REQUIRED;
    }
    *out_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CREATE_MAIN_THREAD_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t free_slot = cametallayer_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CAPACITY_EXHAUSTED;
    }

    uint64_t token = cjgui_native_bridge_token_issue();
    if (token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CAPACITY_EXHAUSTED;
    }

    CAMetalLayer *layer = [CAMetalLayer layer];
    if (layer == nil) {
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_LIFECYCLE_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (g_cjgui_native_bridge_cametallayer_table[free_slot].active != 0u) {
        free_slot = cametallayer_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_cametallayer_table[free_slot].token = token;
    g_cjgui_native_bridge_cametallayer_table[free_slot].attached_view_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[free_slot].bound_device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[free_slot].layer = layer;
    g_cjgui_native_bridge_cametallayer_table[free_slot].active = 1u;
    g_cjgui_native_bridge_cametallayer_table[free_slot].attached = 0u;
    g_cjgui_native_bridge_cametallayer_table[free_slot].device_bound = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    *out_token = token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_destroy(uint64_t token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return token_classification;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t slot_index = cametallayer_table_find_token_locked(token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_cametallayer_table[slot_index].attached == 1u) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DETACH_BEFORE_DESTROY_REQUIRED;
    }
    if (g_cjgui_native_bridge_cametallayer_table[slot_index].device_bound == 1u) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DETACH_BEFORE_DESTROY_REQUIRED;
    }

    g_cjgui_native_bridge_cametallayer_table[slot_index].attached_view_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[slot_index].bound_device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[slot_index].layer = nil;
    g_cjgui_native_bridge_cametallayer_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[slot_index].active = 0u;
    g_cjgui_native_bridge_cametallayer_table[slot_index].attached = 0u;
    g_cjgui_native_bridge_cametallayer_table[slot_index].device_bound = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_double_destroy_classify(
    uint64_t token
) {
    int32_t classification =
        cjgui_native_bridge_cametallayer_token_classify(token);
    if (classification == CJGUI_NATIVE_BRIDGE_CAMETALLAYER_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_cametallayer_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_cametallayer_attach_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DEVICE_BINDING_BLOCKED;
}

int32_t cjgui_native_bridge_cametallayer_attach_to_nsview(
    uint64_t layer_token,
    uint64_t view_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_MAIN_THREAD_REQUIRED;
    }

    int32_t layer_classification =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    if (layer_classification != CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND) {
        return cametallayer_attachment_layer_status_from_classification(
            layer_classification
        );
    }

    int32_t view_classification =
        cjgui_native_bridge_nsview_token_classify(view_token);
    if (view_classification != CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND) {
        return cametallayer_attachment_view_status_from_classification(
            view_classification
        );
    }

    __strong NSView *view = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t view_slot = nsview_table_find_token_locked(view_token);
    if (view_slot >= 0) {
        view = g_cjgui_native_bridge_nsview_table[view_slot].view;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (view == nil) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_VIEW_TOKEN_NOT_BOUND;
    }

    __strong CAMetalLayer *layer = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t layer_slot = cametallayer_table_find_token_locked(layer_token);
    int32_t view_attached_slot =
        cametallayer_table_find_attached_view_locked(view_token);
    if (layer_slot >= 0) {
        if (g_cjgui_native_bridge_cametallayer_table[layer_slot].attached == 1u ||
            (view_attached_slot >= 0 && view_attached_slot != layer_slot)) {
            pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
            return
                CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DOUBLE_ATTACH_DENIED;
        }
        layer = g_cjgui_native_bridge_cametallayer_table[layer_slot].layer;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (layer == nil) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_LAYER_TOKEN_NOT_BOUND;
    }

    view.wantsLayer = YES;
    view.layer = layer;

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        view.layer = nil;
        view.wantsLayer = NO;
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_LAYER_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_cametallayer_table[layer_slot].attached == 1u) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        view.layer = nil;
        view.wantsLayer = NO;
        return
            CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DOUBLE_ATTACH_DENIED;
    }

    g_cjgui_native_bridge_cametallayer_table[layer_slot].attached_view_token =
        view_token;
    g_cjgui_native_bridge_cametallayer_table[layer_slot].attached = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_detach_from_nsview(
    uint64_t layer_token,
    uint64_t view_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_MAIN_THREAD_REQUIRED;
    }

    int32_t layer_classification =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    if (layer_classification != CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND) {
        return cametallayer_attachment_layer_status_from_classification(
            layer_classification
        );
    }

    int32_t view_classification =
        cjgui_native_bridge_nsview_token_classify(view_token);
    if (view_classification != CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND) {
        return cametallayer_attachment_view_status_from_classification(
            view_classification
        );
    }

    __strong NSView *view = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t view_slot = nsview_table_find_token_locked(view_token);
    if (view_slot >= 0) {
        view = g_cjgui_native_bridge_nsview_table[view_slot].view;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (view == nil) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_VIEW_TOKEN_NOT_BOUND;
    }

    __strong CAMetalLayer *layer = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_LAYER_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_cametallayer_table[layer_slot].attached != 1u ||
        g_cjgui_native_bridge_cametallayer_table[layer_slot]
            .attached_view_token != view_token) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DOUBLE_DETACH_DENIED;
    }
    layer = g_cjgui_native_bridge_cametallayer_table[layer_slot].layer;
    g_cjgui_native_bridge_cametallayer_table[layer_slot].attached_view_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[layer_slot].attached = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);

    if (view.layer == layer) {
        view.layer = nil;
        view.wantsLayer = NO;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_attachment_classify(
    uint64_t layer_token,
    uint64_t view_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_MAIN_THREAD_REQUIRED;
    }

    int32_t layer_classification =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    if (layer_classification != CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND) {
        return cametallayer_attachment_layer_status_from_classification(
            layer_classification
        );
    }

    int32_t view_classification =
        cjgui_native_bridge_nsview_token_classify(view_token);
    if (view_classification != CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND) {
        return cametallayer_attachment_view_status_from_classification(
            view_classification
        );
    }

    __strong NSView *view = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t view_slot = nsview_table_find_token_locked(view_token);
    if (view_slot >= 0) {
        view = g_cjgui_native_bridge_nsview_table[view_slot].view;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    if (view == nil) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_VIEW_TOKEN_NOT_BOUND;
    }

    __strong CAMetalLayer *layer = nil;
    uint8_t attached = 0u;
    uint64_t attached_view_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot >= 0) {
        layer = g_cjgui_native_bridge_cametallayer_table[layer_slot].layer;
        attached = g_cjgui_native_bridge_cametallayer_table[layer_slot].attached;
        attached_view_token =
            g_cjgui_native_bridge_cametallayer_table[layer_slot]
                .attached_view_token;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (layer == nil) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_LAYER_TOKEN_NOT_BOUND;
    }

    if (attached == 1u &&
        attached_view_token == view_token &&
        view.layer == layer) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_ATTACHED;
    }
    return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_NOT_ATTACHED;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_double_detach_classify(
    uint64_t layer_token,
    uint64_t view_token
) {
    int32_t classification =
        cjgui_native_bridge_cametallayer_attachment_classify(
            layer_token,
            view_token
        );
    if (classification ==
        CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_NOT_ATTACHED) {
        return CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DOUBLE_DETACH_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_metal_import_available(void) {
    return CJGUI_NATIVE_BRIDGE_HAS_METAL_IMPORT == 1 ?
        CJGUI_NATIVE_BRIDGE_METAL_IMPORT_AVAILABLE :
        CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
}

int32_t cjgui_native_bridge_metal_default_device_available(void) {
#if defined(__APPLE__)
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        return device != nil ?
            CJGUI_NATIVE_BRIDGE_METAL_DEFAULT_DEVICE_AVAILABLE :
            CJGUI_NATIVE_BRIDGE_METAL_DEFAULT_DEVICE_UNAVAILABLE;
    }
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_metal_device_no_command_queue_admission(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_NO_COMMAND_QUEUE_ADMISSION;
}

int32_t cjgui_native_bridge_metal_device_creation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATION_STILL_BLOCKED;
}

uint32_t cjgui_native_bridge_metal_device_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_metal_device_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_metal_device_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    uint32_t count = metal_device_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_metal_device_token_classify(uint64_t token) {
    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return metal_device_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t slot_index = metal_device_table_find_token_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_metal_default_device_create(uint64_t* out_token) {
    if (out_token == 0) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_OUT_TOKEN_REQUIRED;
    }
    *out_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATE_MAIN_THREAD_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t free_slot = metal_device_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CAPACITY_EXHAUSTED;
    }

    uint64_t token = cjgui_native_bridge_token_issue();
    if (token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CAPACITY_EXHAUSTED;
    }

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (g_cjgui_native_bridge_metal_device_table[free_slot].active != 0u) {
        free_slot = metal_device_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_metal_device_table[free_slot].token = token;
    g_cjgui_native_bridge_metal_device_table[free_slot].device = device;
    g_cjgui_native_bridge_metal_device_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    *out_token = token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_metal_device_destroy(uint64_t token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(token);
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return metal_device_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t bound_layer_slot = cametallayer_table_find_bound_device_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (bound_layer_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DETACH_BEFORE_DESTROY_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    int32_t bound_queue_slot =
        command_queue_table_find_bound_device_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
    if (bound_queue_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_METAL_DEVICE_COMMAND_QUEUE_DESTROY_BEFORE_DEVICE_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t slot_index = metal_device_table_find_token_locked(token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_metal_device_table[slot_index].device = nil;
    g_cjgui_native_bridge_metal_device_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_metal_device_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_metal_device_double_destroy_classify(
    uint64_t token
) {
    int32_t classification = cjgui_native_bridge_metal_device_token_classify(
        token
    );
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_metal_device_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_metal_device_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_metal_device_command_queue_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_COMMAND_QUEUE_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_cametallayer_bind_metal_device(
    uint64_t layer_token,
    uint64_t device_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BIND_MAIN_THREAD_REQUIRED;
    }

    int32_t layer_classification =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    if (layer_classification != CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND) {
        return metal_device_binding_layer_status_from_classification(
            layer_classification
        );
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return metal_device_binding_device_status_from_classification(
            device_classification
        );
    }

    __strong id<MTLDevice> device = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t device_slot = metal_device_table_find_token_locked(device_token);
    if (device_slot >= 0) {
        device = g_cjgui_native_bridge_metal_device_table[device_slot].device;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (device == nil) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DEVICE_TOKEN_NOT_BOUND;
    }

    __strong CAMetalLayer *layer = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot >= 0) {
        if (g_cjgui_native_bridge_cametallayer_table[layer_slot].device_bound ==
            1u) {
            pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
            return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DOUBLE_BIND_DENIED;
        }
        layer = g_cjgui_native_bridge_cametallayer_table[layer_slot].layer;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (layer == nil) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_TOKEN_NOT_BOUND;
    }

    layer.device = device;

    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        layer.device = nil;
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_cametallayer_table[layer_slot].device_bound ==
        1u) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        layer.device = nil;
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DOUBLE_BIND_DENIED;
    }

    g_cjgui_native_bridge_cametallayer_table[layer_slot].bound_device_token =
        device_token;
    g_cjgui_native_bridge_cametallayer_table[layer_slot].device_bound = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_unbind_metal_device(
    uint64_t layer_token,
    uint64_t device_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BIND_MAIN_THREAD_REQUIRED;
    }

    int32_t layer_classification =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    if (layer_classification != CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND) {
        return metal_device_binding_layer_status_from_classification(
            layer_classification
        );
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return metal_device_binding_device_status_from_classification(
            device_classification
        );
    }

    __strong CAMetalLayer *layer = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_cametallayer_table[layer_slot].device_bound != 1u ||
        g_cjgui_native_bridge_cametallayer_table[layer_slot]
            .bound_device_token != device_token) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DOUBLE_UNBIND_DENIED;
    }
    layer = g_cjgui_native_bridge_cametallayer_table[layer_slot].layer;
    g_cjgui_native_bridge_cametallayer_table[layer_slot].bound_device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_cametallayer_table[layer_slot].device_bound = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);

    if (layer != nil) {
        layer.device = nil;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_device_binding_classify(
    uint64_t layer_token,
    uint64_t device_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BIND_MAIN_THREAD_REQUIRED;
    }

    int32_t layer_classification =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    if (layer_classification != CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND) {
        return metal_device_binding_layer_status_from_classification(
            layer_classification
        );
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return metal_device_binding_device_status_from_classification(
            device_classification
        );
    }

    __strong id<MTLDevice> device = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t device_slot = metal_device_table_find_token_locked(device_token);
    if (device_slot >= 0) {
        device = g_cjgui_native_bridge_metal_device_table[device_slot].device;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (device == nil) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DEVICE_TOKEN_NOT_BOUND;
    }

    __strong CAMetalLayer *layer = nil;
    uint8_t device_bound = 0u;
    uint64_t bound_device_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    pthread_mutex_lock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    int32_t layer_slot = cametallayer_table_find_token_locked(layer_token);
    if (layer_slot >= 0) {
        layer = g_cjgui_native_bridge_cametallayer_table[layer_slot].layer;
        device_bound =
            g_cjgui_native_bridge_cametallayer_table[layer_slot].device_bound;
        bound_device_token =
            g_cjgui_native_bridge_cametallayer_table[layer_slot]
                .bound_device_token;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_cametallayer_table_mutex);
    if (layer == nil) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_TOKEN_NOT_BOUND;
    }

    if (device_bound == 1u &&
        bound_device_token == device_token &&
        layer.device == device) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_NOT_BOUND;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_cametallayer_double_unbind_device_classify(
    uint64_t layer_token,
    uint64_t device_token
) {
    int32_t classification =
        cjgui_native_bridge_cametallayer_device_binding_classify(
            layer_token,
            device_token
        );
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DOUBLE_UNBIND_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_cametallayer_device_binding_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BIND_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DRAWABLE_STILL_BLOCKED;
}

uint32_t cjgui_native_bridge_command_queue_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_command_queue_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_command_queue_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    uint32_t count = command_queue_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_command_queue_token_classify(
    uint64_t queue_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        queue_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return command_queue_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    int32_t slot_index = command_queue_table_find_token_locked(queue_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_command_queue_create(
    uint64_t device_token,
    uint64_t* out_queue_token
) {
    if (out_queue_token == 0) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_OUT_TOKEN_REQUIRED;
    }
    *out_queue_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CREATE_MAIN_THREAD_REQUIRED;
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return command_queue_device_status_from_classification(
            device_classification
        );
    }

    __strong id<MTLDevice> device = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t device_slot = metal_device_table_find_token_locked(device_token);
    if (device_slot >= 0) {
        device = g_cjgui_native_bridge_metal_device_table[device_slot].device;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (device == nil) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DEVICE_TOKEN_NOT_BOUND;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    int32_t free_slot = command_queue_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CAPACITY_EXHAUSTED;
    }

    uint64_t queue_token = cjgui_native_bridge_token_issue();
    if (queue_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CAPACITY_EXHAUSTED;
    }

    __strong id<MTLCommandQueue> queue = [device newCommandQueue];
    if (queue == nil) {
        (void)cjgui_native_bridge_token_revoke(queue_token);
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    if (g_cjgui_native_bridge_command_queue_table[free_slot].active != 0u) {
        free_slot = command_queue_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
        (void)cjgui_native_bridge_token_revoke(queue_token);
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_command_queue_table[free_slot].token = queue_token;
    g_cjgui_native_bridge_command_queue_table[free_slot].device_token =
        device_token;
    g_cjgui_native_bridge_command_queue_table[free_slot].queue = queue;
    g_cjgui_native_bridge_command_queue_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
    *out_queue_token = queue_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_command_queue_destroy(uint64_t queue_token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        queue_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return command_queue_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    int32_t slot_index = command_queue_table_find_token_locked(queue_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_NOT_BOUND;
    }
    pthread_mutex_lock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    int32_t buffer_slot =
        command_buffer_table_find_bound_queue_locked(queue_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    if (buffer_slot >= 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_COMMAND_BUFFER_DESTROY_BEFORE_QUEUE_REQUIRED;
    }

    g_cjgui_native_bridge_command_queue_table[slot_index].queue = nil;
    g_cjgui_native_bridge_command_queue_table[slot_index].device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_command_queue_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_command_queue_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(queue_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_command_queue_double_destroy_classify(
    uint64_t queue_token
) {
    int32_t classification =
        cjgui_native_bridge_command_queue_token_classify(queue_token);
    if (classification == CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_command_queue_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_command_queue_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_command_buffer_creation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_COMMAND_BUFFER_STILL_BLOCKED;
}

uint32_t cjgui_native_bridge_command_buffer_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_command_buffer_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_command_buffer_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    uint32_t count = command_buffer_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_command_buffer_token_classify(
    uint64_t buffer_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        buffer_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return command_buffer_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    int32_t slot_index = command_buffer_table_find_token_locked(buffer_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_command_buffer_create(
    uint64_t queue_token,
    uint64_t* out_buffer_token
) {
    if (out_buffer_token == 0) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_OUT_TOKEN_REQUIRED;
    }
    *out_buffer_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CREATE_MAIN_THREAD_REQUIRED;
    }

    int32_t queue_classification =
        cjgui_native_bridge_command_queue_token_classify(queue_token);
    if (queue_classification != CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_BOUND) {
        return command_buffer_queue_status_from_classification(
            queue_classification
        );
    }

    __strong id<MTLCommandQueue> queue = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_command_queue_table_mutex);
    int32_t queue_slot = command_queue_table_find_token_locked(queue_token);
    if (queue_slot >= 0) {
        queue = g_cjgui_native_bridge_command_queue_table[queue_slot].queue;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_queue_table_mutex);
    if (queue == nil) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_QUEUE_TOKEN_NOT_BOUND;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    int32_t free_slot = command_buffer_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CAPACITY_EXHAUSTED;
    }

    uint64_t buffer_token = cjgui_native_bridge_token_issue();
    if (buffer_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CAPACITY_EXHAUSTED;
    }

    __strong id<MTLCommandBuffer> buffer = [queue commandBuffer];
    if (buffer == nil) {
        (void)cjgui_native_bridge_token_revoke(buffer_token);
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    if (g_cjgui_native_bridge_command_buffer_table[free_slot].active != 0u) {
        free_slot = command_buffer_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
        (void)cjgui_native_bridge_token_revoke(buffer_token);
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_command_buffer_table[free_slot].token = buffer_token;
    g_cjgui_native_bridge_command_buffer_table[free_slot].queue_token =
        queue_token;
    g_cjgui_native_bridge_command_buffer_table[free_slot].buffer = buffer;
    g_cjgui_native_bridge_command_buffer_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    *out_buffer_token = buffer_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_command_buffer_destroy(uint64_t buffer_token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        buffer_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return command_buffer_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_command_buffer_table_mutex);
    int32_t slot_index = command_buffer_table_find_token_locked(buffer_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_command_buffer_table[slot_index].buffer = nil;
    g_cjgui_native_bridge_command_buffer_table[slot_index].queue_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_command_buffer_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_command_buffer_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_command_buffer_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(buffer_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_command_buffer_double_destroy_classify(
    uint64_t buffer_token
) {
    int32_t classification =
        cjgui_native_bridge_command_buffer_token_classify(buffer_token);
    if (classification == CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_command_buffer_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_command_buffer_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_command_buffer_commit_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_COMMIT_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_command_buffer_encoder_creation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_ENCODER_CREATION_STILL_BLOCKED;
}
