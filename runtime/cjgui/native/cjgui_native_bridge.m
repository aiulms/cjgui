/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 仅实现 no-resource callable C ABI、AppKit import / class availability /
 * main-thread admission / no-object creation boundary、CAMetalLayer allocation /
 * table / create-destroy / NSView attachment first slice、Metal device binding
 * first slice、MTLCommandQueue create/destroy first slice、
 * MTLCommandBuffer create/destroy first slice、
 * MTLRenderPassDescriptor create/destroy first slice、
 * MTLRenderPipelineDescriptor no-draw create/config/destroy first slice、
 * shader library / function no-draw create/lookup/destroy first slice、
 * MTLRenderPipelineState no-draw create/destroy first slice、
 * MTLBuffer no-submit create/destroy/data-upload first slice、draw call
 * no-submit still-blocked facts、token-backed NSWindow harness create/destroy
 * first slice、NSWindow content-view attachment first slice、
 * visible-order native guard no-side-effect facts、NSApplication native guard
 * no-side-effect facts、shared-application accessor call containment facts
 * 与确定性整数事实，
 * 不是运行时 bridge truth。
 * Stop-line: 只允许 pthread 当前线程分类、bridge-local token facts、AppKit import /
 * class lookup / main-thread admission / no-object creation facts、fixed-capacity
 * NSView token table first slice、token-backed NSWindow harness create/destroy
 * first slice、NSWindow content-view token wiring、visible-order guard facts、
 * NSApplication guard facts、accessor call containment facts，
 * 以及 QuartzCore / CAMetalLayer no-attach /
 * allocation / table / create-destroy / controlled NSView attachment facts、
 * Metal device availability / table / layer binding facts、fixed-capacity
 * command queue token facts、command buffer token facts、render pass descriptor
 * token facts、pipeline descriptor token/config facts、shader library /
 * function token facts、pipeline state token facts、vertex buffer token facts 与
 * draw call still-blocked facts；
 * NSWindow harness 只创建 / 销毁不可见窗口对象并允许 contentView token wiring，
 * 不 order front，不创建
 * NSApplication，不获取 drawable，
 * command buffer / render pass descriptor / pipeline descriptor / shader /
 * pipeline state / vertex buffer / draw call no-submit first slice 不创建或绑定 encoder，不调用
 * setVertexBuffer，不 commit / present / draw / render，
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
#include <stdatomic.h>
#include <math.h>
#include <string.h>

/*
 * 当前 callable 只暴露 no-resource status / capability / thread-classification /
 * token / import / class lookup / main-thread admission / no-object creation / NSView
 * token-backed first-slice facts / NSWindow harness token-backed facts /
 * CAMetalLayer no-attach / allocation /
 * table / create-destroy / NSView attachment facts / Metal device binding facts /
 * command queue create-destroy facts / command buffer create-destroy facts /
 * render pass descriptor create-destroy facts。
 * pthread_main_np 只分类当前线程；token table 只保存 active flag 与 generation。
 * teardown admission 只做 fail-closed 分类，不执行真实 native 生命周期。
 * AppKit import / class availability / main-thread admission boundary 只证明 no-object facts 可观察。
 * NSView first slice 只在 main thread 创建 / 清空固定容量 table entry，不创建 window / layer / Metal。
 * NSWindow harness first slice 只创建不可见 NSWindow token 并销毁，不 order front、
 * 不创建 NSApplication，不接入 layer / drawable / command buffer / encoder / present。
 * QuartzCore / CAMetalLayer no-attach boundary 只做 class lookup；allocation /
 * create-destroy first slice 只创建未绑定 drawable 的 fixed-capacity layer token。
 * Metal device first slice 只绑定 default device 到 CAMetalLayer；command queue
 * first slice 只创建 / 销毁 MTLCommandQueue；command buffer first slice
 * 只创建 / 清空 MTLCommandBuffer token、MTLRenderPassDescriptor token、
 * no-draw MTLRenderPipelineDescriptor token、shader library / function token、
 * no-draw MTLRenderPipelineState token 与 no-submit MTLBuffer token，
 * 不创建 encoder，不绑定 vertex buffer，不 commit / present / draw / render，
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

typedef struct CjguiNativeBridgeNsWindowHarnessTableEntry {
    uint64_t token;
    uint64_t attached_content_view_token;
#if defined(__APPLE__)
    __strong NSWindow *window;
#endif
    uint8_t active;
    uint8_t content_view_attached;
} CjguiNativeBridgeNsWindowHarnessTableEntry;

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

typedef struct CjguiNativeBridgeRenderPassDescriptorTableEntry {
    uint64_t token;
#if defined(__APPLE__)
    __strong MTLRenderPassDescriptor *descriptor;
#endif
    uint8_t active;
} CjguiNativeBridgeRenderPassDescriptorTableEntry;

typedef struct CjguiNativeBridgePipelineDescriptorTableEntry {
    uint64_t token;
#if defined(__APPLE__)
    __strong MTLRenderPipelineDescriptor *descriptor;
#endif
    uint8_t active;
    uint8_t configured;
} CjguiNativeBridgePipelineDescriptorTableEntry;

typedef struct CjguiNativeBridgeShaderLibraryTableEntry {
    uint64_t token;
    uint64_t device_token;
#if defined(__APPLE__)
    __strong id<MTLLibrary> library;
#endif
    uint8_t active;
} CjguiNativeBridgeShaderLibraryTableEntry;

typedef struct CjguiNativeBridgeShaderFunctionTableEntry {
    uint64_t token;
    uint64_t library_token;
    uint8_t function_kind;
#if defined(__APPLE__)
    __strong id<MTLFunction> function;
#endif
    uint8_t active;
} CjguiNativeBridgeShaderFunctionTableEntry;

typedef struct CjguiNativeBridgePipelineStateTableEntry {
    uint64_t token;
    uint64_t device_token;
    uint64_t descriptor_token;
    uint64_t vertex_function_token;
    uint64_t fragment_function_token;
#if defined(__APPLE__)
    __strong id<MTLRenderPipelineState> pipeline_state;
#endif
    uint8_t active;
} CjguiNativeBridgePipelineStateTableEntry;

typedef struct CjguiNativeBridgeVertexBufferTableEntry {
    uint64_t token;
    uint64_t device_token;
#if defined(__APPLE__)
    __strong id<MTLBuffer> buffer;
#endif
    uint8_t active;
    uint8_t data_uploaded;
} CjguiNativeBridgeVertexBufferTableEntry;

static pthread_mutex_t g_cjgui_native_bridge_token_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeTokenTableEntry
    g_cjgui_native_bridge_token_table[CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_nsview_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeNsViewTableEntry
    g_cjgui_native_bridge_nsview_table[CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_nswindow_harness_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeNsWindowHarnessTableEntry
    g_cjgui_native_bridge_nswindow_harness_table
        [CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TABLE_CAPACITY];
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
static pthread_mutex_t
    g_cjgui_native_bridge_render_pass_descriptor_table_mutex =
        PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeRenderPassDescriptorTableEntry
    g_cjgui_native_bridge_render_pass_descriptor_table
        [CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_pipeline_descriptor_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgePipelineDescriptorTableEntry
    g_cjgui_native_bridge_pipeline_descriptor_table
        [CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_shader_library_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeShaderLibraryTableEntry
    g_cjgui_native_bridge_shader_library_table
        [CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_shader_function_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeShaderFunctionTableEntry
    g_cjgui_native_bridge_shader_function_table
        [CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_pipeline_state_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgePipelineStateTableEntry
    g_cjgui_native_bridge_pipeline_state_table
        [CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY];
static pthread_mutex_t g_cjgui_native_bridge_vertex_buffer_table_mutex =
    PTHREAD_MUTEX_INITIALIZER;
static CjguiNativeBridgeVertexBufferTableEntry
    g_cjgui_native_bridge_vertex_buffer_table
        [CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TABLE_CAPACITY];

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

static uint32_t nswindow_harness_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nswindow_harness_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t nswindow_harness_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nswindow_harness_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_nswindow_harness_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t nswindow_harness_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nswindow_harness_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t nswindow_harness_table_find_content_view_locked(
    uint64_t view_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_nswindow_harness_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_nswindow_harness_table[slot_index]
                    .content_view_attached == 1u &&
            g_cjgui_native_bridge_nswindow_harness_table[slot_index]
                    .attached_content_view_token == view_token) {
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

static uint32_t render_pass_descriptor_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_render_pass_descriptor_table[slot_index]
                .active == 1u) {
            count++;
        }
    }
    return count;
}

static int32_t render_pass_descriptor_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_render_pass_descriptor_table[slot_index]
                    .active == 1u &&
            g_cjgui_native_bridge_render_pass_descriptor_table[slot_index]
                    .token == token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t render_pass_descriptor_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_render_pass_descriptor_table[slot_index]
                .active == 0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t pipeline_descriptor_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t pipeline_descriptor_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t pipeline_descriptor_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t shader_library_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_library_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t shader_library_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_library_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_shader_library_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t shader_library_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_library_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t shader_function_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_function_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t shader_function_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_function_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_shader_function_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t shader_function_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_function_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t shader_function_table_find_bound_library_locked(
    uint64_t library_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_shader_function_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_shader_function_table[slot_index]
                    .library_token == library_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t pipeline_state_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_state_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t pipeline_state_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_state_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_pipeline_state_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t pipeline_state_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_state_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t pipeline_state_table_find_bound_device_locked(
    uint64_t device_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_state_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_pipeline_state_table[slot_index]
                    .device_token == device_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t pipeline_state_table_find_bound_descriptor_locked(
    uint64_t descriptor_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_state_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_pipeline_state_table[slot_index]
                    .descriptor_token == descriptor_token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t pipeline_state_table_find_bound_function_locked(
    uint64_t function_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_pipeline_state_table[slot_index].active ==
                1u &&
            (g_cjgui_native_bridge_pipeline_state_table[slot_index]
                     .vertex_function_token == function_token ||
             g_cjgui_native_bridge_pipeline_state_table[slot_index]
                     .fragment_function_token == function_token)) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static uint32_t vertex_buffer_table_occupied_count_locked(void) {
    uint32_t count = 0u;
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_vertex_buffer_table[slot_index].active ==
            1u) {
            count++;
        }
    }
    return count;
}

static int32_t vertex_buffer_table_find_token_locked(uint64_t token) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_vertex_buffer_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_vertex_buffer_table[slot_index].token ==
                token) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t vertex_buffer_table_first_free_slot_locked(void) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_vertex_buffer_table[slot_index].active ==
            0u) {
            return (int32_t)slot_index;
        }
    }
    return -1;
}

static int32_t vertex_buffer_table_find_bound_device_locked(
    uint64_t device_token
) {
    for (uint32_t slot_index = 0u;
         slot_index < CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TABLE_CAPACITY;
         slot_index++) {
        if (g_cjgui_native_bridge_vertex_buffer_table[slot_index].active ==
                1u &&
            g_cjgui_native_bridge_vertex_buffer_table[slot_index].device_token ==
                device_token) {
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

static int32_t render_pass_descriptor_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t pipeline_descriptor_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t shader_library_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t shader_library_device_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_INVALID_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_STALE_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_DEVICE_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t shader_function_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t shader_function_library_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_INVALID_LIBRARY_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_STALE_LIBRARY_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_LIBRARY_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t pipeline_state_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t pipeline_state_device_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_INVALID_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_STALE_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DEVICE_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t pipeline_state_descriptor_status_from_classification(
    int32_t classification
) {
    if (classification ==
        CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_INVALID_DESCRIPTOR_TOKEN;
    }
    if (classification ==
        CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_STALE_DESCRIPTOR_TOKEN;
    }
    if (classification ==
        CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DESCRIPTOR_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t pipeline_state_vertex_function_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_INVALID_VERTEX_FUNCTION_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_STALE_VERTEX_FUNCTION_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_VERTEX_FUNCTION_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t pipeline_state_fragment_function_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_INVALID_FRAGMENT_FUNCTION_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_STALE_FRAGMENT_FUNCTION_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TOKEN_NOT_BOUND) {
        return
            CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_FRAGMENT_FUNCTION_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t vertex_buffer_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t nswindow_harness_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_INVALID_TOKEN_DENIED;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_STALE_TOKEN_DENIED;
    }
    return classification;
}

static int32_t nswindow_content_view_window_status_from_classification(
    int32_t classification
) {
    if (classification ==
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_INVALID_TOKEN_DENIED) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_INVALID_WINDOW_TOKEN;
    }
    if (classification ==
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_STALE_TOKEN_DENIED) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_STALE_WINDOW_TOKEN;
    }
    if (classification ==
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_NOT_BOUND) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_WINDOW_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t nswindow_content_view_view_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_INVALID_TOKEN_DENIED) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_INVALID_VIEW_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_STALE_TOKEN_DENIED) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_STALE_VIEW_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_NOT_BOUND) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_VIEW_TOKEN_NOT_BOUND;
    }
    return classification;
}

static int32_t vertex_buffer_device_status_from_classification(
    int32_t classification
) {
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_INVALID_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_STALE_DEVICE_TOKEN;
    }
    if (classification == CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DEVICE_TOKEN_NOT_BOUND;
    }
    return classification;
}

#if defined(__APPLE__)
static NSString *shader_library_minimal_source_contract(void) {
    return @"#include <metal_stdlib>\n"
           "using namespace metal;\n"
           "struct CjguiVertexOut { float4 position [[position]]; };\n"
           "vertex CjguiVertexOut cjgui_vertex_main(uint vertexID [[vertex_id]]) {\n"
           "  float2 positions[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };\n"
           "  CjguiVertexOut out;\n"
           "  out.position = float4(positions[vertexID], 0.0, 1.0);\n"
           "  return out;\n"
           "}\n"
           "fragment float4 cjgui_fragment_main() {\n"
           "  return float4(0.08, 0.16, 0.20, 1.0);\n"
           "}\n";
}
#endif

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
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_COMMAND_BUFFER_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_RENDER_PASS_DESCRIPTOR_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_PIPELINE_DESCRIPTOR_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_SHADER_LIBRARY_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_SHADER_FUNCTION_LOOKUP |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_PIPELINE_STATE_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_VERTEX_BUFFER_CREATE_DESTROY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_VERTEX_BUFFER_DATA_UPLOAD |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NSWINDOW_HARNESS_CREATE_DESTROY;
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

    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t attached_window_slot =
        nswindow_harness_table_find_content_view_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    if (attached_window_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DETACH_BEFORE_VIEW_DESTROY_REQUIRED;
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

uint32_t cjgui_native_bridge_nswindow_harness_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_nswindow_harness_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_nswindow_harness_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    uint32_t count = nswindow_harness_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_nswindow_harness_token_classify(
    uint64_t window_token
) {
    int32_t token_classification =
        cjgui_native_bridge_token_classify(window_token);
    int32_t status =
        nswindow_harness_status_from_classification(token_classification);
    if (status != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return status;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t slot_index =
        nswindow_harness_table_find_token_locked(window_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_nswindow_harness_create(
    uint64_t* out_window_token
) {
    if (out_window_token == 0) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_OUT_TOKEN_REQUIRED;
    }
    *out_window_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CREATE_MAIN_THREAD_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t free_slot = nswindow_harness_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CAPACITY_EXHAUSTED;
    }

    uint64_t token = cjgui_native_bridge_token_issue();
    if (token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CAPACITY_EXHAUSTED;
    }

    NSRect content_rect = NSMakeRect(0.0, 0.0, 160.0, 120.0);
    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:content_rect
                  styleMask:NSWindowStyleMaskTitled
                    backing:NSBackingStoreBuffered
                      defer:YES];
    if (window == nil) {
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CREATION_FAILED;
    }
    [window setReleasedWhenClosed:NO];

    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    if (g_cjgui_native_bridge_nswindow_harness_table[free_slot].active != 0u) {
        free_slot = nswindow_harness_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
        [window close];
        (void)cjgui_native_bridge_token_revoke(token);
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_nswindow_harness_table[free_slot].token = token;
    g_cjgui_native_bridge_nswindow_harness_table[free_slot]
        .attached_content_view_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_nswindow_harness_table[free_slot].window = window;
    g_cjgui_native_bridge_nswindow_harness_table[free_slot].active = 1u;
    g_cjgui_native_bridge_nswindow_harness_table[free_slot]
        .content_view_attached = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    *out_window_token = token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_nswindow_harness_destroy(uint64_t window_token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification =
        cjgui_native_bridge_token_classify(window_token);
    int32_t status =
        nswindow_harness_status_from_classification(token_classification);
    if (status == CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DOUBLE_DESTROY_DENIED;
    }
    if (status != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return status;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t slot_index =
        nswindow_harness_table_find_token_locked(window_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_nswindow_harness_table[slot_index]
            .content_view_attached == 1u) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DETACH_BEFORE_WINDOW_DESTROY_REQUIRED;
    }

    NSWindow *window =
        g_cjgui_native_bridge_nswindow_harness_table[slot_index].window;
    g_cjgui_native_bridge_nswindow_harness_table[slot_index]
        .attached_content_view_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_nswindow_harness_table[slot_index].window = nil;
    g_cjgui_native_bridge_nswindow_harness_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_nswindow_harness_table[slot_index].active = 0u;
    g_cjgui_native_bridge_nswindow_harness_table[slot_index]
        .content_view_attached = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);

    if (window != nil) {
        [window orderOut:nil];
        [window close];
    }

    int32_t revoke_status = cjgui_native_bridge_token_revoke(window_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)window_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_nswindow_harness_double_destroy_classify(
    uint64_t window_token
) {
    int32_t classification =
        cjgui_native_bridge_nswindow_harness_token_classify(window_token);
    if (classification ==
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_nswindow_harness_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_NEXT_DRAWABLE_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_COMMAND_BUFFER_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_RENDER_ENCODER_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nswindow_harness_present_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_PRESENT_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nswindow_harness_content_view_attach(
    uint64_t window_token,
    uint64_t view_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_ATTACH_MAIN_THREAD_REQUIRED;
    }

    int32_t window_classification =
        cjgui_native_bridge_nswindow_harness_token_classify(window_token);
    if (window_classification !=
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_BOUND) {
        return nswindow_content_view_window_status_from_classification(
            window_classification
        );
    }

    int32_t view_classification =
        cjgui_native_bridge_nsview_token_classify(view_token);
    if (view_classification != CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND) {
        return nswindow_content_view_view_status_from_classification(
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
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_VIEW_TOKEN_NOT_BOUND;
    }

    __strong NSWindow *window = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t window_slot =
        nswindow_harness_table_find_token_locked(window_token);
    int32_t attached_view_slot =
        nswindow_harness_table_find_content_view_locked(view_token);
    if (window_slot >= 0) {
        if (g_cjgui_native_bridge_nswindow_harness_table[window_slot]
                    .content_view_attached == 1u ||
            (attached_view_slot >= 0 && attached_view_slot != window_slot)) {
            pthread_mutex_unlock(
                &g_cjgui_native_bridge_nswindow_harness_table_mutex
            );
            return
                CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DOUBLE_ATTACH_DENIED;
        }
        window =
            g_cjgui_native_bridge_nswindow_harness_table[window_slot].window;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    if (window == nil) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_WINDOW_TOKEN_NOT_BOUND;
    }

    window.contentView = view;

    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    window_slot = nswindow_harness_table_find_token_locked(window_token);
    if (window_slot < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_nswindow_harness_table_mutex
        );
        if (window.contentView == view) {
            window.contentView = nil;
        }
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_WINDOW_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_nswindow_harness_table[window_slot]
            .content_view_attached == 1u) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_nswindow_harness_table_mutex
        );
        if (window.contentView == view) {
            window.contentView = nil;
        }
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DOUBLE_ATTACH_DENIED;
    }

    g_cjgui_native_bridge_nswindow_harness_table[window_slot]
        .attached_content_view_token = view_token;
    g_cjgui_native_bridge_nswindow_harness_table[window_slot]
        .content_view_attached = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)window_token;
    (void)view_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_nswindow_harness_content_view_detach(
    uint64_t window_token,
    uint64_t view_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_ATTACH_MAIN_THREAD_REQUIRED;
    }

    int32_t window_classification =
        cjgui_native_bridge_nswindow_harness_token_classify(window_token);
    if (window_classification !=
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_BOUND) {
        return nswindow_content_view_window_status_from_classification(
            window_classification
        );
    }

    int32_t view_classification =
        cjgui_native_bridge_nsview_token_classify(view_token);
    if (view_classification != CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND) {
        return nswindow_content_view_view_status_from_classification(
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
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_VIEW_TOKEN_NOT_BOUND;
    }

    __strong NSWindow *window = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t window_slot =
        nswindow_harness_table_find_token_locked(window_token);
    if (window_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_WINDOW_TOKEN_NOT_BOUND;
    }
    if (g_cjgui_native_bridge_nswindow_harness_table[window_slot]
                .content_view_attached != 1u ||
        g_cjgui_native_bridge_nswindow_harness_table[window_slot]
                .attached_content_view_token != view_token) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DOUBLE_DETACH_DENIED;
    }
    window = g_cjgui_native_bridge_nswindow_harness_table[window_slot].window;
    g_cjgui_native_bridge_nswindow_harness_table[window_slot]
        .attached_content_view_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_nswindow_harness_table[window_slot]
        .content_view_attached = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);

    if (window != nil && window.contentView == view) {
        window.contentView = nil;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)window_token;
    (void)view_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t
cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
    uint64_t window_token,
    uint64_t view_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_ATTACH_MAIN_THREAD_REQUIRED;
    }

    int32_t window_classification =
        cjgui_native_bridge_nswindow_harness_token_classify(window_token);
    if (window_classification !=
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_BOUND) {
        return nswindow_content_view_window_status_from_classification(
            window_classification
        );
    }

    int32_t view_classification =
        cjgui_native_bridge_nsview_token_classify(view_token);
    if (view_classification != CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND) {
        return nswindow_content_view_view_status_from_classification(
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
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_VIEW_TOKEN_NOT_BOUND;
    }

    __strong NSWindow *window = nil;
    uint8_t content_view_attached = 0u;
    uint64_t attached_content_view_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    pthread_mutex_lock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    int32_t window_slot =
        nswindow_harness_table_find_token_locked(window_token);
    if (window_slot >= 0) {
        window =
            g_cjgui_native_bridge_nswindow_harness_table[window_slot].window;
        content_view_attached =
            g_cjgui_native_bridge_nswindow_harness_table[window_slot]
                .content_view_attached;
        attached_content_view_token =
            g_cjgui_native_bridge_nswindow_harness_table[window_slot]
                .attached_content_view_token;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_nswindow_harness_table_mutex);
    if (window == nil) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_WINDOW_TOKEN_NOT_BOUND;
    }

    if (content_view_attached == 1u &&
        attached_content_view_token == view_token &&
        window.contentView == view) {
        return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_ATTACHED;
    }
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_NOT_ATTACHED;
#else
    (void)window_token;
    (void)view_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t
cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify(
    uint64_t window_token,
    uint64_t view_token
) {
    int32_t classification =
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            window_token,
            view_token
        );
    if (classification ==
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_ATTACHED) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DOUBLE_ATTACH_DENIED;
    }
    return classification;
}

int32_t
cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify(
    uint64_t window_token,
    uint64_t view_token
) {
    int32_t classification =
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            window_token,
            view_token
        );
    if (classification ==
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_NOT_ATTACHED) {
        return
            CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_DOUBLE_DETACH_DENIED;
    }
    return classification;
}

int32_t
cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_ATTACH_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CONTENT_VIEW_VISIBLE_ORDER_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_nswindow_visible_order_application_ownership_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_APPLICATION_OWNERSHIP_REQUIRED;
}

int32_t
cjgui_native_bridge_nswindow_visible_order_application_creation_deferred(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_APPLICATION_CREATION_DEFERRED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_activation_deferred(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_ACTIVATION_DEFERRED;
}

int32_t
cjgui_native_bridge_nswindow_visible_order_bounded_run_loop_required(void) {
    return
        CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_BOUNDED_RUN_LOOP_REQUIRED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_auto_close_required(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_AUTO_CLOSE_REQUIRED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_headless_fail_closed(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_HEADLESS_FAIL_CLOSED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_content_view_required(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_CONTENT_VIEW_REQUIRED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_drawable_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_DRAWABLE_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nswindow_visible_order_render_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSWINDOW_VISIBLE_ORDER_RENDER_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nsapplication_guard_ownership_required(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_OWNERSHIP_REQUIRED;
}

int32_t cjgui_native_bridge_nsapplication_guard_main_thread_required(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_nsapplication_guard_creation_deferred(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_CREATION_DEFERRED;
}

int32_t cjgui_native_bridge_nsapplication_guard_activation_deferred(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_ACTIVATION_DEFERRED;
}

int32_t
cjgui_native_bridge_nsapplication_guard_activation_policy_deferred(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_ACTIVATION_POLICY_DEFERRED;
}

int32_t cjgui_native_bridge_nsapplication_guard_event_loop_deferred(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_EVENT_LOOP_DEFERRED;
}

int32_t
cjgui_native_bridge_nsapplication_guard_bounded_run_loop_required(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_BOUNDED_RUN_LOOP_REQUIRED;
}

int32_t cjgui_native_bridge_nsapplication_guard_auto_close_required(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_AUTO_CLOSE_REQUIRED;
}

int32_t cjgui_native_bridge_nsapplication_guard_headless_fail_closed(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_HEADLESS_FAIL_CLOSED;
}

int32_t
cjgui_native_bridge_nsapplication_guard_visible_order_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_VISIBLE_ORDER_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nsapplication_guard_drawable_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_DRAWABLE_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_nsapplication_guard_render_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_RENDER_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_ACCESSOR_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_singleton_creation_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_SINGLETON_CREATION_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_main_thread_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_bounded_run_loop_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_BOUNDED_RUN_LOOP_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_auto_close_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_AUTO_CLOSE_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_headless_fail_closed(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_HEADLESS_FAIL_CLOSED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_teardown_before_visible_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_TEARDOWN_BEFORE_VISIBLE_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_non_user_visible_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_NON_USER_VISIBLE_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_activation_policy_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_ACTIVATION_POLICY_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_activation_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_ACTIVATION_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_event_loop_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_EVENT_LOOP_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_visible_order_still_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_VISIBLE_ORDER_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_drawable_still_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_DRAWABLE_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_guard_render_still_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_GUARD_RENDER_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_ACCESSOR_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_no_singleton_accessor_call(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_NO_SINGLETON_ACCESSOR_CALL;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_singleton_creation_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_SINGLETON_CREATION_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_main_thread_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_bounded_run_loop_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_BOUNDED_RUN_LOOP_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_auto_close_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_AUTO_CLOSE_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_teardown_before_visible_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_TEARDOWN_BEFORE_VISIBLE_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_non_user_visible_required(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_NON_USER_VISIBLE_REQUIRED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_application_side_effect_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_APPLICATION_SIDE_EFFECT_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_policy_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_ACTIVATION_POLICY_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_ACTIVATION_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_event_loop_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_EVENT_LOOP_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_visible_order_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_VISIBLE_ORDER_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_drawable_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_DRAWABLE_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_render_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_RENDER_BLOCKED;
}

int32_t
cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_backend_ready_truth_blocked(
    void
) {
    return
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_BACKEND_READY_TRUTH_BLOCKED;
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

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    int32_t bound_pipeline_state_slot =
        pipeline_state_table_find_bound_device_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    if (bound_pipeline_state_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_METAL_DEVICE_PIPELINE_STATE_DESTROY_BEFORE_DEVICE_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    int32_t bound_vertex_buffer_slot =
        vertex_buffer_table_find_bound_device_locked(token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    if (bound_vertex_buffer_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_METAL_DEVICE_VERTEX_BUFFER_DESTROY_BEFORE_DEVICE_REQUIRED;
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

uint32_t cjgui_native_bridge_render_pass_descriptor_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_render_pass_descriptor_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_render_pass_descriptor_table_occupied_count(void) {
    pthread_mutex_lock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    uint32_t count = render_pass_descriptor_table_occupied_count_locked();
    pthread_mutex_unlock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    return count;
}

int32_t cjgui_native_bridge_render_pass_descriptor_token_classify(
    uint64_t descriptor_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return render_pass_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    int32_t slot_index =
        render_pass_descriptor_table_find_token_locked(descriptor_token);
    pthread_mutex_unlock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_render_pass_descriptor_create(
    uint64_t* out_descriptor_token
) {
    if (out_descriptor_token == 0) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_OUT_TOKEN_REQUIRED;
    }
    *out_descriptor_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_CREATE_MAIN_THREAD_REQUIRED;
    }

    pthread_mutex_lock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    int32_t free_slot =
        render_pass_descriptor_table_first_free_slot_locked();
    pthread_mutex_unlock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_CAPACITY_EXHAUSTED;
    }

    uint64_t descriptor_token = cjgui_native_bridge_token_issue();
    if (descriptor_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_CAPACITY_EXHAUSTED;
    }

    __strong MTLRenderPassDescriptor *descriptor =
        [MTLRenderPassDescriptor renderPassDescriptor];
    if (descriptor == nil) {
        (void)cjgui_native_bridge_token_revoke(descriptor_token);
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_CREATION_FAILED;
    }

    pthread_mutex_lock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    if (g_cjgui_native_bridge_render_pass_descriptor_table[free_slot].active !=
        0u) {
        free_slot = render_pass_descriptor_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
        );
        (void)cjgui_native_bridge_token_revoke(descriptor_token);
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_render_pass_descriptor_table[free_slot].token =
        descriptor_token;
    g_cjgui_native_bridge_render_pass_descriptor_table[free_slot].descriptor =
        descriptor;
    g_cjgui_native_bridge_render_pass_descriptor_table[free_slot].active = 1u;
    pthread_mutex_unlock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    *out_descriptor_token = descriptor_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_render_pass_descriptor_destroy(
    uint64_t descriptor_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return render_pass_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );
    int32_t slot_index =
        render_pass_descriptor_table_find_token_locked(descriptor_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
        );
        return CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_render_pass_descriptor_table[slot_index].descriptor =
        nil;
    g_cjgui_native_bridge_render_pass_descriptor_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_render_pass_descriptor_table[slot_index].active = 0u;
    pthread_mutex_unlock(
        &g_cjgui_native_bridge_render_pass_descriptor_table_mutex
    );

    int32_t revoke_status = cjgui_native_bridge_token_revoke(descriptor_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_render_pass_descriptor_double_destroy_classify(
    uint64_t descriptor_token
) {
    int32_t classification =
        cjgui_native_bridge_render_pass_descriptor_token_classify(
            descriptor_token
        );
    if (classification ==
        CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_STALE_TOKEN_DENIED) {
        return
            CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t
cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread(void) {
    return
        CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread(void) {
    return
        CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked(void) {
    return
        CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_COLOR_ATTACHMENT_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked(void) {
    return
        CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_ENCODER_CREATION_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked(void) {
    return
        CJGUI_NATIVE_BRIDGE_RENDER_PASS_DESCRIPTOR_DRAWABLE_TEXTURE_STILL_BLOCKED;
}

uint32_t cjgui_native_bridge_pipeline_descriptor_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_pipeline_descriptor_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_pipeline_descriptor_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    uint32_t count = pipeline_descriptor_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_pipeline_descriptor_token_classify(
    uint64_t descriptor_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t slot_index =
        pipeline_descriptor_table_find_token_locked(descriptor_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_pipeline_descriptor_create(
    uint64_t* out_descriptor_token
) {
    if (out_descriptor_token == 0) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_OUT_TOKEN_REQUIRED;
    }
    *out_descriptor_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CREATE_MAIN_THREAD_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t free_slot = pipeline_descriptor_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CAPACITY_EXHAUSTED;
    }

    uint64_t descriptor_token = cjgui_native_bridge_token_issue();
    if (descriptor_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CAPACITY_EXHAUSTED;
    }

    __strong MTLRenderPipelineDescriptor *descriptor =
        [[MTLRenderPipelineDescriptor alloc] init];
    if (descriptor == nil) {
        (void)cjgui_native_bridge_token_revoke(descriptor_token);
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    if (g_cjgui_native_bridge_pipeline_descriptor_table[free_slot].active !=
        0u) {
        free_slot = pipeline_descriptor_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_pipeline_descriptor_table_mutex
        );
        (void)cjgui_native_bridge_token_revoke(descriptor_token);
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_pipeline_descriptor_table[free_slot].token =
        descriptor_token;
    g_cjgui_native_bridge_pipeline_descriptor_table[free_slot].descriptor =
        descriptor;
    g_cjgui_native_bridge_pipeline_descriptor_table[free_slot].active = 1u;
    g_cjgui_native_bridge_pipeline_descriptor_table[free_slot].configured = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    *out_descriptor_token = descriptor_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_pipeline_descriptor_destroy(
    uint64_t descriptor_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    int32_t bound_pipeline_state_slot =
        pipeline_state_table_find_bound_descriptor_locked(descriptor_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    if (bound_pipeline_state_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_PIPELINE_STATE_DESTROY_BEFORE_DESCRIPTOR_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t slot_index =
        pipeline_descriptor_table_find_token_locked(descriptor_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_pipeline_descriptor_table_mutex
        );
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].descriptor = nil;
    g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].active = 0u;
    g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].configured = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(descriptor_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(
    uint64_t descriptor_token
) {
    int32_t classification =
        cjgui_native_bridge_pipeline_descriptor_token_classify(
            descriptor_token
        );
    if (classification ==
        CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t
cjgui_native_bridge_pipeline_descriptor_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_pipeline_descriptor_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t
cjgui_native_bridge_pipeline_descriptor_configure_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CONFIGURE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
    uint64_t descriptor_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return
            CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_CONFIGURE_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t slot_index =
        pipeline_descriptor_table_find_token_locked(descriptor_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_pipeline_descriptor_table_mutex
        );
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_NOT_BOUND;
    }

    MTLRenderPipelineDescriptor *descriptor =
        g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].descriptor;
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    descriptor.rasterSampleCount = 1u;
    descriptor.vertexFunction = nil;
    descriptor.fragmentFunction = nil;
    descriptor.colorAttachments[0].blendingEnabled = NO;
    g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].configured = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
    uint64_t descriptor_token
) {
#if defined(__APPLE__)
    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t slot_index =
        pipeline_descriptor_table_find_token_locked(descriptor_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_pipeline_descriptor_table_mutex
        );
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_NOT_BOUND;
    }
    MTLRenderPipelineDescriptor *descriptor =
        g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].descriptor;
    int32_t result =
        descriptor.colorAttachments[0].pixelFormat == MTLPixelFormatBGRA8Unorm
        ? CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_COLOR_PIXEL_FORMAT_CONFIGURED
        : CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_COLOR_PIXEL_FORMAT_NOT_CONFIGURED;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    return result;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
    uint64_t descriptor_token
) {
#if defined(__APPLE__)
    int32_t token_classification = cjgui_native_bridge_token_classify(
        descriptor_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_descriptor_status_from_classification(
            token_classification
        );
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t slot_index =
        pipeline_descriptor_table_find_token_locked(descriptor_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(
            &g_cjgui_native_bridge_pipeline_descriptor_table_mutex
        );
        return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_NOT_BOUND;
    }
    MTLRenderPipelineDescriptor *descriptor =
        g_cjgui_native_bridge_pipeline_descriptor_table[slot_index].descriptor;
    int32_t result =
        descriptor.rasterSampleCount == 1u
        ? CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_SAMPLE_COUNT_CONFIGURED
        : CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_SAMPLE_COUNT_NOT_CONFIGURED;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    return result;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t
cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_SHADER_LIBRARY_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_VERTEX_FUNCTION_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked(void) {
    return
        CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_FRAGMENT_FUNCTION_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_pipeline_descriptor_blending_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_BLENDING_STILL_BLOCKED;
}

int32_t
cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_ENCODER_BINDING_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_pipeline_state_creation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CREATION_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_shader_source_contract_available(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_SOURCE_CONTRACT_AVAILABLE;
}

uint32_t cjgui_native_bridge_shader_library_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_shader_library_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_shader_library_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_shader_library_table_mutex);
    uint32_t count = shader_library_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_shader_library_token_classify(
    uint64_t library_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        library_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return shader_library_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_library_table_mutex);
    int32_t slot_index =
        shader_library_table_find_token_locked(library_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_shader_library_create(
    uint64_t device_token,
    uint64_t* out_library_token
) {
    if (out_library_token == 0) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_OUT_TOKEN_REQUIRED;
    }
    *out_library_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_CREATE_MAIN_THREAD_REQUIRED;
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return shader_library_device_status_from_classification(
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
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_DEVICE_TOKEN_NOT_BOUND;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_library_table_mutex);
    int32_t free_slot = shader_library_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_CAPACITY_EXHAUSTED;
    }

    uint64_t library_token = cjgui_native_bridge_token_issue();
    if (library_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_CAPACITY_EXHAUSTED;
    }

    __strong id<MTLLibrary> library = nil;
    @autoreleasepool {
        NSError *error = nil;
        library = [device newLibraryWithSource:shader_library_minimal_source_contract()
                                       options:nil
                                         error:&error];
        (void)error;
    }
    if (library == nil) {
        (void)cjgui_native_bridge_token_revoke(library_token);
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_library_table_mutex);
    if (g_cjgui_native_bridge_shader_library_table[free_slot].active != 0u) {
        free_slot = shader_library_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
        (void)cjgui_native_bridge_token_revoke(library_token);
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_shader_library_table[free_slot].token = library_token;
    g_cjgui_native_bridge_shader_library_table[free_slot].device_token =
        device_token;
    g_cjgui_native_bridge_shader_library_table[free_slot].library = library;
    g_cjgui_native_bridge_shader_library_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
    *out_library_token = library_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_shader_library_destroy(uint64_t library_token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        library_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return shader_library_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    int32_t bound_function_slot =
        shader_function_table_find_bound_library_locked(library_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
    if (bound_function_slot >= 0) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_DESTROY_BEFORE_LIBRARY_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_library_table_mutex);
    int32_t slot_index =
        shader_library_table_find_token_locked(library_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_shader_library_table[slot_index].library = nil;
    g_cjgui_native_bridge_shader_library_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_shader_library_table[slot_index].device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_shader_library_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(library_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_shader_library_double_destroy_classify(
    uint64_t library_token
) {
    int32_t classification =
        cjgui_native_bridge_shader_library_token_classify(library_token);
    if (classification ==
        CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_shader_library_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_shader_library_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_DESTROY_MAIN_THREAD_REQUIRED;
}

uint32_t cjgui_native_bridge_shader_function_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_shader_function_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_shader_function_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    uint32_t count = shader_function_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
    return count;
}

static int32_t shader_function_lookup_with_name(
    uint64_t library_token,
    NSString *function_name,
    uint8_t function_kind,
    uint64_t* out_function_token
) {
    if (out_function_token == 0) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_OUT_TOKEN_REQUIRED;
    }
    *out_function_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_LOOKUP_MAIN_THREAD_REQUIRED;
    }

    int32_t library_classification =
        cjgui_native_bridge_shader_library_token_classify(library_token);
    if (library_classification !=
        CJGUI_NATIVE_BRIDGE_SHADER_LIBRARY_TOKEN_BOUND) {
        return shader_function_library_status_from_classification(
            library_classification
        );
    }

    __strong id<MTLLibrary> library = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_shader_library_table_mutex);
    int32_t library_slot =
        shader_library_table_find_token_locked(library_token);
    if (library_slot >= 0) {
        library =
            g_cjgui_native_bridge_shader_library_table[library_slot].library;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_library_table_mutex);
    if (library == nil) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_LIBRARY_TOKEN_NOT_BOUND;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    int32_t free_slot = shader_function_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY_EXHAUSTED;
    }

    uint64_t function_token = cjgui_native_bridge_token_issue();
    if (function_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY_EXHAUSTED;
    }

    __strong id<MTLFunction> function = [library newFunctionWithName:function_name];
    if (function == nil) {
        (void)cjgui_native_bridge_token_revoke(function_token);
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_MISSING;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    if (g_cjgui_native_bridge_shader_function_table[free_slot].active != 0u) {
        free_slot = shader_function_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
        (void)cjgui_native_bridge_token_revoke(function_token);
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TABLE_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_shader_function_table[free_slot].token =
        function_token;
    g_cjgui_native_bridge_shader_function_table[free_slot].library_token =
        library_token;
    g_cjgui_native_bridge_shader_function_table[free_slot].function_kind =
        function_kind;
    g_cjgui_native_bridge_shader_function_table[free_slot].function = function;
    g_cjgui_native_bridge_shader_function_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
    *out_function_token = function_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_shader_function_lookup_vertex(
    uint64_t library_token,
    uint64_t* out_function_token
) {
#if defined(__APPLE__)
    return shader_function_lookup_with_name(
        library_token,
        @"cjgui_vertex_main",
        1u,
        out_function_token
    );
#else
    (void)library_token;
    (void)out_function_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_shader_function_lookup_fragment(
    uint64_t library_token,
    uint64_t* out_function_token
) {
#if defined(__APPLE__)
    return shader_function_lookup_with_name(
        library_token,
        @"cjgui_fragment_main",
        2u,
        out_function_token
    );
#else
    (void)library_token;
    (void)out_function_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_shader_function_token_classify(
    uint64_t function_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        function_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return shader_function_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    int32_t slot_index =
        shader_function_table_find_token_locked(function_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TOKEN_NOT_BOUND;
    }
    uint8_t function_kind =
        g_cjgui_native_bridge_shader_function_table[slot_index].function_kind;
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
    if (function_kind == 1u) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_VERTEX_BOUND;
    }
    if (function_kind == 2u) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_FRAGMENT_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_shader_function_destroy(uint64_t function_token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        function_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return shader_function_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    int32_t bound_pipeline_state_slot =
        pipeline_state_table_find_bound_function_locked(function_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    if (bound_pipeline_state_slot >= 0) {
        return
            CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_PIPELINE_STATE_DESTROY_BEFORE_FUNCTION_REQUIRED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    int32_t slot_index =
        shader_function_table_find_token_locked(function_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_shader_function_table[slot_index].function = nil;
    g_cjgui_native_bridge_shader_function_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_shader_function_table[slot_index].library_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_shader_function_table[slot_index].function_kind = 0u;
    g_cjgui_native_bridge_shader_function_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(function_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_shader_function_double_destroy_classify(
    uint64_t function_token
) {
    int32_t classification =
        cjgui_native_bridge_shader_function_token_classify(function_token);
    if (classification ==
        CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_shader_function_lookup_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_LOOKUP_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_shader_function_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_shader_function_missing_classify(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_MISSING;
}

int32_t cjgui_native_bridge_shader_pipeline_state_creation_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_PIPELINE_STATE_CREATION_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_shader_encoder_binding_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_ENCODER_BINDING_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_shader_draw_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_SHADER_DRAW_STILL_BLOCKED;
}

uint32_t cjgui_native_bridge_pipeline_state_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_pipeline_state_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_pipeline_state_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    uint32_t count = pipeline_state_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_pipeline_state_token_classify(
    uint64_t pipeline_state_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        pipeline_state_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_state_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    int32_t slot_index =
        pipeline_state_table_find_token_locked(pipeline_state_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_pipeline_state_create(
    uint64_t device_token,
    uint64_t descriptor_token,
    uint64_t vertex_function_token,
    uint64_t fragment_function_token,
    uint64_t* out_pipeline_state_token
) {
    if (out_pipeline_state_token == 0) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_OUT_TOKEN_REQUIRED;
    }
    *out_pipeline_state_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CREATE_MAIN_THREAD_REQUIRED;
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return pipeline_state_device_status_from_classification(
            device_classification
        );
    }

    int32_t descriptor_classification =
        cjgui_native_bridge_pipeline_descriptor_token_classify(
            descriptor_token
        );
    if (descriptor_classification !=
        CJGUI_NATIVE_BRIDGE_PIPELINE_DESCRIPTOR_TOKEN_BOUND) {
        return pipeline_state_descriptor_status_from_classification(
            descriptor_classification
        );
    }

    int32_t vertex_classification =
        cjgui_native_bridge_shader_function_token_classify(
            vertex_function_token
        );
    if (vertex_classification !=
        CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_VERTEX_BOUND) {
        int32_t mapped =
            pipeline_state_vertex_function_status_from_classification(
                vertex_classification
            );
        if (mapped == vertex_classification) {
            return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_VERTEX_FUNCTION_KIND_REQUIRED;
        }
        return mapped;
    }

    int32_t fragment_classification =
        cjgui_native_bridge_shader_function_token_classify(
            fragment_function_token
        );
    if (fragment_classification !=
        CJGUI_NATIVE_BRIDGE_SHADER_FUNCTION_FRAGMENT_BOUND) {
        int32_t mapped =
            pipeline_state_fragment_function_status_from_classification(
                fragment_classification
            );
        if (mapped == fragment_classification) {
            return
                CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_FRAGMENT_FUNCTION_KIND_REQUIRED;
        }
        return mapped;
    }

    __strong id<MTLDevice> device = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_metal_device_table_mutex);
    int32_t device_slot = metal_device_table_find_token_locked(device_token);
    if (device_slot >= 0) {
        device = g_cjgui_native_bridge_metal_device_table[device_slot].device;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_metal_device_table_mutex);
    if (device == nil) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DEVICE_TOKEN_NOT_BOUND;
    }

    __strong MTLRenderPipelineDescriptor *descriptor = nil;
    uint8_t descriptor_configured = 0u;
    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    int32_t descriptor_slot =
        pipeline_descriptor_table_find_token_locked(descriptor_token);
    if (descriptor_slot >= 0) {
        descriptor =
            g_cjgui_native_bridge_pipeline_descriptor_table[descriptor_slot]
                .descriptor;
        descriptor_configured =
            g_cjgui_native_bridge_pipeline_descriptor_table[descriptor_slot]
                .configured;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_descriptor_table_mutex);
    if (descriptor == nil) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DESCRIPTOR_TOKEN_NOT_BOUND;
    }
    if (descriptor_configured != 1u) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DESCRIPTOR_NOT_CONFIGURED;
    }

    __strong id<MTLFunction> vertex_function = nil;
    __strong id<MTLFunction> fragment_function = nil;
    pthread_mutex_lock(&g_cjgui_native_bridge_shader_function_table_mutex);
    int32_t vertex_slot =
        shader_function_table_find_token_locked(vertex_function_token);
    if (vertex_slot >= 0) {
        vertex_function =
            g_cjgui_native_bridge_shader_function_table[vertex_slot].function;
    }
    int32_t fragment_slot =
        shader_function_table_find_token_locked(fragment_function_token);
    if (fragment_slot >= 0) {
        fragment_function =
            g_cjgui_native_bridge_shader_function_table[fragment_slot].function;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_shader_function_table_mutex);
    if (vertex_function == nil) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_VERTEX_FUNCTION_TOKEN_NOT_BOUND;
    }
    if (fragment_function == nil) {
        return
            CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_FRAGMENT_FUNCTION_TOKEN_NOT_BOUND;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    int32_t free_slot = pipeline_state_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CAPACITY_EXHAUSTED;
    }

    uint64_t pipeline_state_token = cjgui_native_bridge_token_issue();
    if (pipeline_state_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CAPACITY_EXHAUSTED;
    }

    __strong id<MTLRenderPipelineState> pipeline_state = nil;
    @autoreleasepool {
        NSError *error = nil;
        descriptor.vertexFunction = vertex_function;
        descriptor.fragmentFunction = fragment_function;
        pipeline_state =
            [device newRenderPipelineStateWithDescriptor:descriptor
                                                   error:&error];
        (void)error;
    }
    if (pipeline_state == nil) {
        (void)cjgui_native_bridge_token_revoke(pipeline_state_token);
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    if (g_cjgui_native_bridge_pipeline_state_table[free_slot].active != 0u) {
        free_slot = pipeline_state_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
        (void)cjgui_native_bridge_token_revoke(pipeline_state_token);
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_pipeline_state_table[free_slot].token =
        pipeline_state_token;
    g_cjgui_native_bridge_pipeline_state_table[free_slot].device_token =
        device_token;
    g_cjgui_native_bridge_pipeline_state_table[free_slot].descriptor_token =
        descriptor_token;
    g_cjgui_native_bridge_pipeline_state_table[free_slot].vertex_function_token =
        vertex_function_token;
    g_cjgui_native_bridge_pipeline_state_table[free_slot]
        .fragment_function_token = fragment_function_token;
    g_cjgui_native_bridge_pipeline_state_table[free_slot].pipeline_state =
        pipeline_state;
    g_cjgui_native_bridge_pipeline_state_table[free_slot].active = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    *out_pipeline_state_token = pipeline_state_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)device_token;
    (void)descriptor_token;
    (void)vertex_function_token;
    (void)fragment_function_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_pipeline_state_destroy(
    uint64_t pipeline_state_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        pipeline_state_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return pipeline_state_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
    int32_t slot_index =
        pipeline_state_table_find_token_locked(pipeline_state_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_pipeline_state_table[slot_index].pipeline_state = nil;
    g_cjgui_native_bridge_pipeline_state_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_pipeline_state_table[slot_index].device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_pipeline_state_table[slot_index].descriptor_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_pipeline_state_table[slot_index].vertex_function_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_pipeline_state_table[slot_index]
        .fragment_function_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_pipeline_state_table[slot_index].active = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_pipeline_state_table_mutex);

    int32_t revoke_status =
        cjgui_native_bridge_token_revoke(pipeline_state_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)pipeline_state_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_pipeline_state_double_destroy_classify(
    uint64_t pipeline_state_token
) {
    int32_t classification =
        cjgui_native_bridge_pipeline_state_token_classify(pipeline_state_token);
    if (classification ==
        CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_pipeline_state_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_pipeline_state_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_ENCODER_BINDING_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_pipeline_state_draw_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_PIPELINE_STATE_DRAW_STILL_BLOCKED;
}

uint32_t cjgui_native_bridge_vertex_buffer_table_capacity(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TABLE_CAPACITY;
}

uint32_t cjgui_native_bridge_vertex_buffer_table_enabled(void) {
    return 1u;
}

uint32_t cjgui_native_bridge_vertex_buffer_table_occupied_count(void) {
    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    uint32_t count = vertex_buffer_table_occupied_count_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    return count;
}

int32_t cjgui_native_bridge_vertex_buffer_token_classify(
    uint64_t buffer_token
) {
    int32_t token_classification = cjgui_native_bridge_token_classify(
        buffer_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return vertex_buffer_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    int32_t slot_index = vertex_buffer_table_find_token_locked(buffer_token);
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    if (slot_index >= 0) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TOKEN_BOUND;
    }
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TOKEN_NOT_BOUND;
}

int32_t cjgui_native_bridge_vertex_buffer_create(
    uint64_t device_token,
    uint64_t* out_buffer_token
) {
    if (out_buffer_token == 0) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_OUT_TOKEN_REQUIRED;
    }
    *out_buffer_token = CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;

#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_CREATE_MAIN_THREAD_REQUIRED;
    }

    int32_t device_classification =
        cjgui_native_bridge_metal_device_token_classify(device_token);
    if (device_classification != CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND) {
        return vertex_buffer_device_status_from_classification(
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
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DEVICE_TOKEN_NOT_BOUND;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    int32_t free_slot = vertex_buffer_table_first_free_slot_locked();
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    if (free_slot < 0) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_CAPACITY_EXHAUSTED;
    }

    uint64_t buffer_token = cjgui_native_bridge_token_issue();
    if (buffer_token == CJGUI_NATIVE_BRIDGE_TOKEN_INVALID) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_CAPACITY_EXHAUSTED;
    }

    const NSUInteger vertex_buffer_length = (NSUInteger)(sizeof(float) * 18u);
    __strong id<MTLBuffer> buffer =
        [device newBufferWithLength:vertex_buffer_length
                            options:MTLResourceStorageModeShared];
    if (buffer == nil) {
        (void)cjgui_native_bridge_token_revoke(buffer_token);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_CREATION_FAILED;
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    if (g_cjgui_native_bridge_vertex_buffer_table[free_slot].active != 0u) {
        free_slot = vertex_buffer_table_first_free_slot_locked();
    }
    if (free_slot < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
        (void)cjgui_native_bridge_token_revoke(buffer_token);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_CAPACITY_EXHAUSTED;
    }

    g_cjgui_native_bridge_vertex_buffer_table[free_slot].token = buffer_token;
    g_cjgui_native_bridge_vertex_buffer_table[free_slot].device_token =
        device_token;
    g_cjgui_native_bridge_vertex_buffer_table[free_slot].buffer = buffer;
    g_cjgui_native_bridge_vertex_buffer_table[free_slot].active = 1u;
    g_cjgui_native_bridge_vertex_buffer_table[free_slot].data_uploaded = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    *out_buffer_token = buffer_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)device_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_vertex_buffer_destroy(uint64_t buffer_token) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DESTROY_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        buffer_token
    );
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_INVALID_TOKEN_DENIED;
    }
    if (token_classification == CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DOUBLE_DESTROY_DENIED;
    }
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return vertex_buffer_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    int32_t slot_index = vertex_buffer_table_find_token_locked(buffer_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TOKEN_NOT_BOUND;
    }

    g_cjgui_native_bridge_vertex_buffer_table[slot_index].buffer = nil;
    g_cjgui_native_bridge_vertex_buffer_table[slot_index].token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_vertex_buffer_table[slot_index].device_token =
        CJGUI_NATIVE_BRIDGE_TOKEN_INVALID;
    g_cjgui_native_bridge_vertex_buffer_table[slot_index].active = 0u;
    g_cjgui_native_bridge_vertex_buffer_table[slot_index].data_uploaded = 0u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);

    int32_t revoke_status = cjgui_native_bridge_token_revoke(buffer_token);
    if (revoke_status != CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK) {
        return revoke_status;
    }
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)buffer_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_vertex_buffer_double_destroy_classify(
    uint64_t buffer_token
) {
    int32_t classification =
        cjgui_native_bridge_vertex_buffer_token_classify(buffer_token);
    if (classification == CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_STALE_TOKEN_DENIED) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DOUBLE_DESTROY_DENIED;
    }
    return classification;
}

int32_t cjgui_native_bridge_vertex_buffer_upload_static_triangle(
    uint64_t buffer_token
) {
#if defined(__APPLE__)
    if (pthread_main_np() != 1) {
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_UPLOAD_MAIN_THREAD_REQUIRED;
    }

    int32_t token_classification = cjgui_native_bridge_token_classify(
        buffer_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return vertex_buffer_status_from_classification(token_classification);
    }

    static const float vertices[18] = {
        -0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f,
         0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 0.0f,
         0.0f,  0.5f, 0.0f, 0.0f, 0.0f, 1.0f
    };

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    int32_t slot_index = vertex_buffer_table_find_token_locked(buffer_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TOKEN_NOT_BOUND;
    }
    id<MTLBuffer> buffer =
        g_cjgui_native_bridge_vertex_buffer_table[slot_index].buffer;
    if (buffer == nil || [buffer length] < sizeof(vertices)) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DATA_UPLOAD_FAILED;
    }

    /*
     * 中文维护注释：contents 只用于本地瞬时写入固定三角形数据；
     * 不保存 raw pointer，不返回 pointer，也不绑定 encoder。
     */
    void *contents = [buffer contents];
    if (contents == NULL) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DATA_UPLOAD_FAILED;
    }
    memcpy(contents, vertices, sizeof(vertices));
    g_cjgui_native_bridge_vertex_buffer_table[slot_index].data_uploaded = 1u;
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK;
#else
    (void)buffer_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_vertex_buffer_data_classify(
    uint64_t buffer_token
) {
#if defined(__APPLE__)
    int32_t token_classification = cjgui_native_bridge_token_classify(
        buffer_token
    );
    if (token_classification != CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID) {
        return vertex_buffer_status_from_classification(token_classification);
    }

    pthread_mutex_lock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    int32_t slot_index = vertex_buffer_table_find_token_locked(buffer_token);
    if (slot_index < 0) {
        pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
        return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_TOKEN_NOT_BOUND;
    }
    uint8_t data_uploaded =
        g_cjgui_native_bridge_vertex_buffer_table[slot_index].data_uploaded;
    pthread_mutex_unlock(&g_cjgui_native_bridge_vertex_buffer_table_mutex);
    return data_uploaded == 1u ?
        CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DATA_UPLOADED :
        CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DATA_NOT_UPLOADED;
#else
    (void)buffer_token;
    return CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED;
#endif
}

int32_t cjgui_native_bridge_vertex_buffer_create_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_CREATE_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_vertex_buffer_destroy_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DESTROY_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_vertex_buffer_upload_requires_main_thread(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_UPLOAD_MAIN_THREAD_REQUIRED;
}

int32_t cjgui_native_bridge_vertex_buffer_layout_position_color(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_LAYOUT_POSITION_COLOR;
}

int32_t cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_ENCODER_BINDING_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_vertex_buffer_draw_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_VERTEX_BUFFER_DRAW_STILL_BLOCKED;
}

int32_t cjgui_native_bridge_draw_call_encoder_required(void) {
    return CJGUI_NATIVE_BRIDGE_DRAW_CALL_ENCODER_REQUIRED;
}

int32_t cjgui_native_bridge_draw_call_pipeline_binding_required(void) {
    return CJGUI_NATIVE_BRIDGE_DRAW_CALL_PIPELINE_BINDING_REQUIRED;
}

int32_t cjgui_native_bridge_draw_call_vertex_binding_required(void) {
    return CJGUI_NATIVE_BRIDGE_DRAW_CALL_VERTEX_BINDING_REQUIRED;
}

int32_t cjgui_native_bridge_draw_call_still_blocked(void) {
    return CJGUI_NATIVE_BRIDGE_DRAW_CALL_STILL_BLOCKED;
}

// 2026-09-26(B2):极薄**非 static** 访问器 —— 供渲染器侧导出包装把 view token 解成视图。
// 内部完全照既有模式(锁内取值 ⇒ 立即解锁 ⇒ 不持锁跨调用),**不改动既有 static 符号**。
void *CjguiNativeBridgeViewForToken(uint64_t viewToken) {
    void *result = NULL;
    pthread_mutex_lock(&g_cjgui_native_bridge_nsview_table_mutex);
    int32_t slot = nsview_table_find_token_locked(viewToken);
    if (slot >= 0) {
        result = (__bridge void *)g_cjgui_native_bridge_nsview_table[slot].view;
    }
    pthread_mutex_unlock(&g_cjgui_native_bridge_nsview_table_mutex);
    return result;
}
// 2026-09-26(B2):系统“减少动态效果”偏好查询。只读一个 AppKit 布尔事实，
// 不创建对象、不改窗口、不返回 pointer。NSWorkspace.sharedWorkspace 与
// accessibilityDisplayShouldReduceMotion 都是只读访问；在非 Apple 平台或
// AppKit import 不可用时返回确定的默认值 0（关闭），不静默当作开启。
int32_t cjgui_macos_reduce_motion_enabled(void) {
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
    if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion) {
        return 1;
    }
    return 0;
#else
    return 0;
#endif
}
// 2026-09-27(C):系统外观（浅色/深色）查询。只读 NSApp.effectiveAppearance；
// NSApp 尚未创建时退化为 NSAppearance.currentAppearance；两者都不可用或非
// Apple 平台返回确定的默认值 0（浅色）。不创建对象、不改变外观、不返回
// pointer。bestMatchFromAppearancesWithNames: 是 macOS 10.14+ 的只读匹配，
// 不触发任何界面重建。
int32_t cjgui_macos_effective_dark_mode(void) {
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
    NSAppearance *appearance = nil;
    if (NSApp != nil) {
        appearance = NSApp.effectiveAppearance;
    }
    if (appearance == nil) {
        appearance = NSAppearance.currentAppearance;
    }
    if (appearance == nil) {
        return 0;
    }
    NSString *best = [appearance bestMatchFromAppearancesWithNames:@[
        NSAppearanceNameAqua, NSAppearanceNameDarkAqua
    ]];
    return [best isEqualToString:NSAppearanceNameDarkAqua] ? 1 : 0;
#else
    return 0;
#endif
}
// The Cangjie application entry runs on its runtime worker while AppKit owns
// the process main thread. One global sample is sufficient for the system
// accent fact; windows retain independent follow/fixed policies and receipts.
// A worker never waits for the main queue (which may synchronously call into
// the renderer during a scene transaction).
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
static _Atomic bool cjguiAccentSamplingEnabled = false;
static _Atomic bool cjguiAccentSamplePending = false;
static _Atomic int64_t cjguiAccentLastSample = -1;

static int64_t CjguiControlAccentSampleOnMain(void) {
    if (![NSThread isMainThread]) return -1;
    NSColor *color = [[NSColor controlAccentColor] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    if (!color) return -1;
    double r = color.redComponent, g = color.greenComponent, b = color.blueComponent;
    if (!isfinite(r) || !isfinite(g) || !isfinite(b)) return -1;
    uint64_t red = (uint64_t)llround(fmin(1.0, fmax(0.0, r)) * 255.0);
    uint64_t green = (uint64_t)llround(fmin(1.0, fmax(0.0, g)) * 255.0);
    uint64_t blue = (uint64_t)llround(fmin(1.0, fmax(0.0, b)) * 255.0);
    return (int64_t)(0x1000000u | (red << 16) | (green << 8) | blue);
}
#endif

void cjgui_macos_enable_accent_sampling(void) {
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
    if ([NSThread isMainThread]) atomic_store_explicit(&cjguiAccentSamplingEnabled, true, memory_order_release);
#endif
}

int64_t cjgui_macos_control_accent_srgb8(void) {
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
    if ([NSThread isMainThread]) return CjguiControlAccentSampleOnMain();
    if (!atomic_load_explicit(&cjguiAccentSamplingEnabled, memory_order_acquire)) return -1;
    bool expected = false;
    if (atomic_compare_exchange_strong_explicit(&cjguiAccentSamplePending, &expected, true,
            memory_order_acq_rel, memory_order_acquire)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                atomic_store_explicit(&cjguiAccentLastSample, CjguiControlAccentSampleOnMain(),
                    memory_order_release);
                atomic_store_explicit(&cjguiAccentSamplePending, false, memory_order_release);
            }
        });
    }
    return atomic_load_explicit(&cjguiAccentLastSample, memory_order_acquire);
#else
    return -1;
#endif
}
// 2026-09-27(C):按窗口号查询可见性。NSApp windowWithWindowNumber: 只解析已存在
// 的窗口；窗口号无效、窗口不存在、NSApp 尚未创建或非 Apple 平台返回确定的
// 默认值 0。只读、不创建/不改变窗口、不返回 pointer。
int32_t cjgui_macos_window_visible(int64_t window_number) {
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
    if (window_number <= 0 || NSApp == nil) {
        return 0;
    }
    NSWindow *window = [NSApp windowWithWindowNumber:(NSInteger)window_number];
    if (window == nil) {
        return 0;
    }
    return window.isVisible ? 1 : 0;
#else
    (void)window_number;
    return 0;
#endif
}
// 2026-09-27(C):按窗口号查询最小化状态。语义与 cjgui_macos_window_visible 相同：
// 不可用返回确定的 0，且不创建/不改变窗口。
int32_t cjgui_macos_window_minimized(int64_t window_number) {
#if defined(__APPLE__) && CJGUI_NATIVE_BRIDGE_HAS_APPKIT_IMPORT
    if (window_number <= 0 || NSApp == nil) {
        return 0;
    }
    NSWindow *window = [NSApp windowWithWindowNumber:(NSInteger)window_number];
    if (window == nil) {
        return 0;
    }
    return window.isMiniaturized ? 1 : 0;
#else
    (void)window_number;
    return 0;
#endif
}
