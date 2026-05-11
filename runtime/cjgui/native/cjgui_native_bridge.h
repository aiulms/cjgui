/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 承载 internal native bridge C ABI、AppKit / QuartzCore class facts、
 * main-thread admission、token-backed NSView first slice、CAMetalLayer allocation
 * / table / create-destroy / NSView attachment first slice、Metal device binding
 * first slice 与内部 status taxonomy，
 * 不是 public runtime API。
 * Stop-line: 不创建窗口、应用、drawable、绘制资源，
 * command buffer first slice 不 commit / present / encoder / render，
 * 不返回指针身份。
 * Same-shape Boundary Brake: callable surface 只是无副作用 native surface，不是 bridge-ready、backend-ready、render-ready 或 public API permission。
 */
#ifndef CJGUI_NATIVE_BRIDGE_H
#define CJGUI_NATIVE_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * 该 enum 固定 production bridge 的内部状态分类词汇。
 * 当前文件未接入仓颉 FFI，未承诺 runtime resource behavior。
 */
typedef enum CjguiNativeBridgeSkeletonStatus {
    CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK = 0,
    CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_NOT_WIRED = 1,
    CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_MAIN_THREAD_REQUIRED = 2,
    CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_TOKEN_UNAVAILABLE = 3,
    CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_RESOURCE_DENIED = 4,
    CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_TEARDOWN_DENIED = 5
} CjguiNativeBridgeSkeletonStatus;

typedef enum CjguiNativeBridgeSkeletonCategory {
    CJGUI_NATIVE_BRIDGE_SKELETON_CATEGORY_NONE = 0,
    CJGUI_NATIVE_BRIDGE_SKELETON_CATEGORY_ADMISSION = 1,
    CJGUI_NATIVE_BRIDGE_SKELETON_CATEGORY_CONFINEMENT = 2,
    CJGUI_NATIVE_BRIDGE_SKELETON_CATEGORY_TOKEN = 3,
    CJGUI_NATIVE_BRIDGE_SKELETON_CATEGORY_TEARDOWN = 4,
    CJGUI_NATIVE_BRIDGE_SKELETON_CATEGORY_RESOURCE = 5
} CjguiNativeBridgeSkeletonCategory;

typedef enum CjguiNativeBridgeSurfaceCapability {
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_VERSION_QUERY = 1u << 0,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_STATUS_QUERY = 1u << 1,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAPABILITY_QUERY = 1u << 2,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NO_RESOURCE_ADMISSION = 1u << 3,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_MAIN_THREAD_QUERY = 1u << 4,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_TOKEN_TABLE_SHELL = 1u << 5,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_TOKEN_ISSUE_REVOKE = 1u << 6,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_TEARDOWN_ADMISSION = 1u << 7,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_APPKIT_IMPORT_BOUNDARY = 1u << 8,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_APPKIT_CLASS_AVAILABILITY = 1u << 9,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_APPKIT_MAIN_THREAD_ADMISSION = 1u << 10,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_PLATFORM_OBJECT_NO_OBJECT_CREATION = 1u << 11,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NSVIEW_OBJECT_TABLE_SHELL = 1u << 12,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NSVIEW_CREATE_DESTROY = 1u << 13,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_NO_ATTACH = 1u << 14,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_ALLOCATION = 1u << 15,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_OBJECT_TABLE = 1u << 16,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_CREATE_DESTROY =
        1u << 17,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_NSVIEW_ATTACHMENT =
        1u << 18,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_METAL_DEVICE_AVAILABILITY =
        1u << 19,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_METAL_DEVICE_CREATE_DESTROY =
        1u << 20,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_METAL_DEVICE_LAYER_BINDING =
        1u << 21,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_COMMAND_QUEUE_CREATE_DESTROY =
        1u << 22,
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_COMMAND_BUFFER_CREATE_DESTROY =
        1u << 23
} CjguiNativeBridgeSurfaceCapability;

enum {
    CJGUI_NATIVE_BRIDGE_SURFACE_VERSION = 1u,
    CJGUI_NATIVE_BRIDGE_TOKEN_INVALID = 0u,
    CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY = 8u,
    CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY = 4u,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_CAPACITY = 4u,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TABLE_CAPACITY = 2u,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TABLE_CAPACITY = 2u,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TABLE_CAPACITY = 2u,
    CJGUI_NATIVE_BRIDGE_TOKEN_SLOT_BITS = 16u,
    CJGUI_NATIVE_BRIDGE_TOKEN_SLOT_MASK = 0xffffu
};

typedef enum CjguiNativeBridgeTokenClassification {
    CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_INVALID = 0,
    CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_VALID = 1,
    CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_STALE = -2,
    CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_MAIN_THREAD_REQUIRED = -3,
    CJGUI_NATIVE_BRIDGE_TOKEN_CLASS_CAPACITY_EXHAUSTED = -4
} CjguiNativeBridgeTokenClassification;

typedef enum CjguiNativeBridgeTeardownClassification {
    CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DESTROY_NOT_SUPPORTED = -10,
    CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_REVOKE_BEFORE_DESTROY_REQUIRED = -11,
    CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DOUBLE_DESTROY_DENIED = -12,
    CJGUI_NATIVE_BRIDGE_TEARDOWN_CLASS_DANGLING_TOKEN_DENIED = -13
} CjguiNativeBridgeTeardownClassification;

typedef enum CjguiNativeBridgeAppKitImportClassification {
    CJGUI_NATIVE_BRIDGE_APPKIT_IMPORT_AVAILABLE = 20,
    CJGUI_NATIVE_BRIDGE_APPKIT_NO_OBJECT_ADMISSION = 21,
    CJGUI_NATIVE_BRIDGE_APPKIT_NSWINDOW_CLASS_AVAILABLE = 22,
    CJGUI_NATIVE_BRIDGE_APPKIT_NSVIEW_CLASS_AVAILABLE = 23,
    CJGUI_NATIVE_BRIDGE_APPKIT_CLASS_LOOKUP_NO_OBJECT_ADMISSION = 24,
    CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_MAIN_THREAD_REQUIRED = 25,
    CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_MAIN_THREAD_ADMITTED = 26,
    CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_NO_OBJECT_ADMISSION = 27,
    CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_REQUIRES_MAIN_THREAD = 28,
    CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_REQUIRES_TOKEN_CONTRACT = 29,
    CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_STILL_BLOCKED = -20,
    CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_ALLOCATION_STILL_BLOCKED = -21,
    CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_BACKGROUND_THREAD_DENIED = -22,
    CJGUI_NATIVE_BRIDGE_APPKIT_PLATFORM_OBJECT_CREATION_STILL_BLOCKED = -23,
    CJGUI_NATIVE_BRIDGE_PLATFORM_OBJECT_CREATE_ALLOCATION_BLOCKED = -24
} CjguiNativeBridgeAppKitImportClassification;

typedef enum CjguiNativeBridgeNsViewTableClassification {
    CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_EMPTY = 30,
    CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_TOKEN_NOT_BOUND = -30,
    CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_ALLOCATION_BLOCKED = -31,
    CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_DESTROY_BLOCKED = -32
} CjguiNativeBridgeNsViewTableClassification;

typedef enum CjguiNativeBridgeNsViewLifecycleClassification {
    CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_BOUND = 40,
    CJGUI_NATIVE_BRIDGE_NSVIEW_CREATE_MAIN_THREAD_REQUIRED = -40,
    CJGUI_NATIVE_BRIDGE_NSVIEW_DESTROY_MAIN_THREAD_REQUIRED = -41,
    CJGUI_NATIVE_BRIDGE_NSVIEW_INVALID_TOKEN_DENIED = -42,
    CJGUI_NATIVE_BRIDGE_NSVIEW_STALE_TOKEN_DENIED = -43,
    CJGUI_NATIVE_BRIDGE_NSVIEW_TOKEN_NOT_BOUND = -44,
    CJGUI_NATIVE_BRIDGE_NSVIEW_CAPACITY_EXHAUSTED = -45,
    CJGUI_NATIVE_BRIDGE_NSVIEW_DOUBLE_DESTROY_DENIED = -46,
    CJGUI_NATIVE_BRIDGE_NSVIEW_ALLOCATION_FAILED = -47,
    CJGUI_NATIVE_BRIDGE_NSVIEW_OUT_TOKEN_REQUIRED = -48
} CjguiNativeBridgeNsViewLifecycleClassification;

typedef enum CjguiNativeBridgeCAMetalLayerNoAttachClassification {
    CJGUI_NATIVE_BRIDGE_QUARTZCORE_IMPORT_AVAILABLE = 50,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CLASS_AVAILABLE = 51,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_NO_ATTACH_ADMISSION = 52,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_STILL_BLOCKED = -50,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DEVICE_BINDING_STILL_BLOCKED = -51
} CjguiNativeBridgeCAMetalLayerNoAttachClassification;

typedef enum CjguiNativeBridgeCAMetalLayerAllocationClassification {
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_FEASIBLE = 60,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_NO_ATTACH_ADMISSION = 61,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_FEASIBILITY_OBSERVED = 62,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_MAIN_THREAD_REQUIRED = -60,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_FAILED = -61,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_DEVICE_BINDING_BLOCKED = -62
} CjguiNativeBridgeCAMetalLayerAllocationClassification;

typedef enum CjguiNativeBridgeCAMetalLayerTableClassification {
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_EMPTY = 70,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_TOKEN_NOT_BOUND = -70,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_ALLOCATION_BLOCKED = -71,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_DESTROY_BLOCKED = -72
} CjguiNativeBridgeCAMetalLayerTableClassification;

typedef enum CjguiNativeBridgeCAMetalLayerLifecycleClassification {
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_BOUND = 80,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CREATE_MAIN_THREAD_REQUIRED = -80,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DESTROY_MAIN_THREAD_REQUIRED = -81,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_INVALID_TOKEN_DENIED = -82,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_STALE_TOKEN_DENIED = -83,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TOKEN_NOT_BOUND = -84,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CAPACITY_EXHAUSTED = -85,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_DOUBLE_DESTROY_DENIED = -86,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_LIFECYCLE_FAILED = -87,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_OUT_TOKEN_REQUIRED = -88
} CjguiNativeBridgeCAMetalLayerLifecycleClassification;

typedef enum CjguiNativeBridgeCAMetalLayerAttachmentClassification {
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_ATTACHED = 90,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_NOT_ATTACHED = -90,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_MAIN_THREAD_REQUIRED = -91,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_INVALID_LAYER_TOKEN = -92,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_INVALID_VIEW_TOKEN = -93,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_STALE_LAYER_TOKEN = -94,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_STALE_VIEW_TOKEN = -95,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DOUBLE_DETACH_DENIED = -96,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DOUBLE_ATTACH_DENIED = -97,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_LAYER_TOKEN_NOT_BOUND = -98,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_VIEW_TOKEN_NOT_BOUND = -99,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DEVICE_BINDING_BLOCKED = -100,
    CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_DETACH_BEFORE_DESTROY_REQUIRED =
        -101
} CjguiNativeBridgeCAMetalLayerAttachmentClassification;

typedef enum CjguiNativeBridgeMetalDeviceAvailabilityClassification {
    CJGUI_NATIVE_BRIDGE_METAL_IMPORT_AVAILABLE = 100,
    CJGUI_NATIVE_BRIDGE_METAL_DEFAULT_DEVICE_AVAILABLE = 101,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_NO_COMMAND_QUEUE_ADMISSION = -110,
    CJGUI_NATIVE_BRIDGE_METAL_DEFAULT_DEVICE_UNAVAILABLE = -111,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATION_STILL_BLOCKED = -112
} CjguiNativeBridgeMetalDeviceAvailabilityClassification;

typedef enum CjguiNativeBridgeMetalDeviceLifecycleClassification {
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_BOUND = 120,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATE_MAIN_THREAD_REQUIRED = -120,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_DESTROY_MAIN_THREAD_REQUIRED = -121,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_INVALID_TOKEN_DENIED = -122,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_STALE_TOKEN_DENIED = -123,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_TOKEN_NOT_BOUND = -124,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CAPACITY_EXHAUSTED = -125,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_DOUBLE_DESTROY_DENIED = -126,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_CREATION_FAILED = -127,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_OUT_TOKEN_REQUIRED = -128,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_COMMAND_QUEUE_STILL_BLOCKED = -129,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_COMMAND_QUEUE_DESTROY_BEFORE_DEVICE_REQUIRED =
        -130
} CjguiNativeBridgeMetalDeviceLifecycleClassification;

typedef enum CjguiNativeBridgeMetalDeviceLayerBindingClassification {
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BOUND = 140,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_NOT_BOUND = -140,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_BIND_MAIN_THREAD_REQUIRED = -141,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_INVALID_LAYER_TOKEN = -142,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_INVALID_DEVICE_TOKEN = -143,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_STALE_LAYER_TOKEN = -144,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_STALE_DEVICE_TOKEN = -145,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DOUBLE_UNBIND_DENIED = -146,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DOUBLE_BIND_DENIED = -147,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_TOKEN_NOT_BOUND = -148,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DEVICE_TOKEN_NOT_BOUND = -149,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DRAWABLE_STILL_BLOCKED = -150,
    CJGUI_NATIVE_BRIDGE_METAL_DEVICE_LAYER_DETACH_BEFORE_DESTROY_REQUIRED =
        -151
} CjguiNativeBridgeMetalDeviceLayerBindingClassification;

typedef enum CjguiNativeBridgeCommandQueueLifecycleClassification {
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_BOUND = 160,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CREATE_MAIN_THREAD_REQUIRED = -160,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DESTROY_MAIN_THREAD_REQUIRED = -161,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_INVALID_TOKEN_DENIED = -162,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_STALE_TOKEN_DENIED = -163,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_TOKEN_NOT_BOUND = -164,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CAPACITY_EXHAUSTED = -165,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DOUBLE_DESTROY_DENIED = -166,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_CREATION_FAILED = -167,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_OUT_TOKEN_REQUIRED = -168,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_COMMAND_BUFFER_STILL_BLOCKED = -169,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_INVALID_DEVICE_TOKEN = -170,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_STALE_DEVICE_TOKEN = -171,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_DEVICE_TOKEN_NOT_BOUND = -172,
    CJGUI_NATIVE_BRIDGE_COMMAND_QUEUE_COMMAND_BUFFER_DESTROY_BEFORE_QUEUE_REQUIRED =
        -173
} CjguiNativeBridgeCommandQueueLifecycleClassification;

typedef enum CjguiNativeBridgeCommandBufferLifecycleClassification {
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TOKEN_BOUND = 180,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CREATE_MAIN_THREAD_REQUIRED = -180,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_DESTROY_MAIN_THREAD_REQUIRED = -181,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_INVALID_TOKEN_DENIED = -182,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_STALE_TOKEN_DENIED = -183,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_TOKEN_NOT_BOUND = -184,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CAPACITY_EXHAUSTED = -185,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_DOUBLE_DESTROY_DENIED = -186,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_CREATION_FAILED = -187,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_OUT_TOKEN_REQUIRED = -188,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_COMMIT_STILL_BLOCKED = -189,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_ENCODER_CREATION_STILL_BLOCKED = -190,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_INVALID_QUEUE_TOKEN = -191,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_STALE_QUEUE_TOKEN = -192,
    CJGUI_NATIVE_BRIDGE_COMMAND_BUFFER_QUEUE_TOKEN_NOT_BOUND = -193
} CjguiNativeBridgeCommandBufferLifecycleClassification;

/*
 * callable 只返回 dehydrated integer facts，或通过 out-token 返回 opaque token。
 * 它们不返回 pointer，不扩 public runtime API，也不表示 backend ready。
 */
uint32_t cjgui_native_bridge_surface_version(void);
uint32_t cjgui_native_bridge_surface_capabilities(void);
uint32_t cjgui_native_bridge_status_ok(void);
uint32_t cjgui_native_bridge_no_resource_admission(void);
int32_t cjgui_native_bridge_is_main_thread(void);
uint64_t cjgui_native_bridge_token_invalid(void);
uint32_t cjgui_native_bridge_token_table_capacity(void);
uint32_t cjgui_native_bridge_token_table_enabled(void);
int32_t cjgui_native_bridge_token_classify(uint64_t token);
uint64_t cjgui_native_bridge_token_issue(void);
int32_t cjgui_native_bridge_token_revoke(uint64_t token);
int32_t cjgui_native_bridge_teardown_admission(uint64_t token);
int32_t cjgui_native_bridge_destroy_not_supported(void);
int32_t cjgui_native_bridge_revoke_before_destroy_required(void);
int32_t cjgui_native_bridge_double_destroy_classify(uint64_t token);
int32_t cjgui_native_bridge_appkit_import_available(void);
int32_t cjgui_native_bridge_appkit_no_object_admission(void);
int32_t cjgui_native_bridge_platform_object_create_still_blocked(void);
int32_t cjgui_native_bridge_appkit_nswindow_class_available(void);
int32_t cjgui_native_bridge_appkit_nsview_class_available(void);
int32_t cjgui_native_bridge_appkit_class_lookup_no_object_admission(void);
int32_t cjgui_native_bridge_platform_object_allocation_still_blocked(void);
int32_t cjgui_native_bridge_appkit_platform_object_main_thread_required(void);
int32_t cjgui_native_bridge_appkit_platform_object_main_thread_admitted(void);
int32_t cjgui_native_bridge_appkit_platform_object_background_thread_denied(void);
int32_t cjgui_native_bridge_appkit_platform_object_creation_still_blocked(void);
int32_t cjgui_native_bridge_platform_object_create_no_object_admission(void);
int32_t cjgui_native_bridge_platform_object_create_requires_main_thread(void);
int32_t cjgui_native_bridge_platform_object_create_requires_token_contract(void);
int32_t cjgui_native_bridge_platform_object_create_allocation_blocked(void);
uint32_t cjgui_native_bridge_nsview_table_capacity(void);
uint32_t cjgui_native_bridge_nsview_table_enabled(void);
int32_t cjgui_native_bridge_nsview_table_empty(void);
int32_t cjgui_native_bridge_nsview_table_token_classify(uint64_t token);
int32_t cjgui_native_bridge_nsview_table_allocation_still_blocked(void);
int32_t cjgui_native_bridge_nsview_table_destroy_still_blocked(void);
int32_t cjgui_native_bridge_nsview_create(uint64_t* out_token);
int32_t cjgui_native_bridge_nsview_destroy(uint64_t token);
int32_t cjgui_native_bridge_nsview_token_classify(uint64_t token);
uint32_t cjgui_native_bridge_nsview_table_occupied_count(void);
int32_t cjgui_native_bridge_nsview_double_destroy_classify(uint64_t token);
int32_t cjgui_native_bridge_nsview_destroy_requires_main_thread(void);
int32_t cjgui_native_bridge_quartzcore_import_available(void);
int32_t cjgui_native_bridge_cametallayer_class_available(void);
int32_t cjgui_native_bridge_cametallayer_no_attach_admission(void);
int32_t cjgui_native_bridge_cametallayer_allocation_still_blocked(void);
int32_t cjgui_native_bridge_cametallayer_device_binding_still_blocked(void);
int32_t cjgui_native_bridge_cametallayer_allocation_feasible(void);
int32_t cjgui_native_bridge_cametallayer_allocation_requires_main_thread(void);
int32_t cjgui_native_bridge_cametallayer_allocation_no_attach_admission(void);
int32_t cjgui_native_bridge_cametallayer_allocation_device_binding_blocked(void);
int32_t cjgui_native_bridge_cametallayer_allocation_feasibility_probe(void);
uint32_t cjgui_native_bridge_cametallayer_table_capacity(void);
uint32_t cjgui_native_bridge_cametallayer_table_enabled(void);
int32_t cjgui_native_bridge_cametallayer_table_empty(void);
int32_t cjgui_native_bridge_cametallayer_table_token_classify(uint64_t token);
int32_t cjgui_native_bridge_cametallayer_table_allocation_still_blocked(void);
int32_t cjgui_native_bridge_cametallayer_table_destroy_still_blocked(void);
int32_t cjgui_native_bridge_cametallayer_create(uint64_t* out_token);
int32_t cjgui_native_bridge_cametallayer_destroy(uint64_t token);
int32_t cjgui_native_bridge_cametallayer_token_classify(uint64_t token);
uint32_t cjgui_native_bridge_cametallayer_table_occupied_count(void);
int32_t cjgui_native_bridge_cametallayer_double_destroy_classify(uint64_t token);
int32_t cjgui_native_bridge_cametallayer_destroy_requires_main_thread(void);
int32_t cjgui_native_bridge_cametallayer_attach_to_nsview(
    uint64_t layer_token,
    uint64_t view_token
);
int32_t cjgui_native_bridge_cametallayer_detach_from_nsview(
    uint64_t layer_token,
    uint64_t view_token
);
int32_t cjgui_native_bridge_cametallayer_attachment_classify(
    uint64_t layer_token,
    uint64_t view_token
);
int32_t cjgui_native_bridge_cametallayer_double_detach_classify(
    uint64_t layer_token,
    uint64_t view_token
);
int32_t cjgui_native_bridge_cametallayer_attach_requires_main_thread(void);
int32_t
cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked(void);
int32_t cjgui_native_bridge_metal_import_available(void);
int32_t cjgui_native_bridge_metal_default_device_available(void);
int32_t cjgui_native_bridge_metal_device_no_command_queue_admission(void);
int32_t cjgui_native_bridge_metal_device_creation_still_blocked(void);
uint32_t cjgui_native_bridge_metal_device_table_capacity(void);
uint32_t cjgui_native_bridge_metal_device_table_enabled(void);
uint32_t cjgui_native_bridge_metal_device_table_occupied_count(void);
int32_t cjgui_native_bridge_metal_default_device_create(uint64_t* out_token);
int32_t cjgui_native_bridge_metal_device_destroy(uint64_t token);
int32_t cjgui_native_bridge_metal_device_token_classify(uint64_t token);
int32_t cjgui_native_bridge_metal_device_double_destroy_classify(uint64_t token);
int32_t cjgui_native_bridge_metal_device_create_requires_main_thread(void);
int32_t cjgui_native_bridge_metal_device_destroy_requires_main_thread(void);
int32_t cjgui_native_bridge_metal_device_command_queue_still_blocked(void);
int32_t cjgui_native_bridge_cametallayer_bind_metal_device(
    uint64_t layer_token,
    uint64_t device_token
);
int32_t cjgui_native_bridge_cametallayer_unbind_metal_device(
    uint64_t layer_token,
    uint64_t device_token
);
int32_t cjgui_native_bridge_cametallayer_device_binding_classify(
    uint64_t layer_token,
    uint64_t device_token
);
int32_t cjgui_native_bridge_cametallayer_double_unbind_device_classify(
    uint64_t layer_token,
    uint64_t device_token
);
int32_t cjgui_native_bridge_cametallayer_device_binding_requires_main_thread(void);
int32_t cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked(void);
uint32_t cjgui_native_bridge_command_queue_table_capacity(void);
uint32_t cjgui_native_bridge_command_queue_table_enabled(void);
uint32_t cjgui_native_bridge_command_queue_table_occupied_count(void);
int32_t cjgui_native_bridge_command_queue_create(
    uint64_t device_token,
    uint64_t* out_queue_token
);
int32_t cjgui_native_bridge_command_queue_destroy(uint64_t queue_token);
int32_t cjgui_native_bridge_command_queue_token_classify(uint64_t queue_token);
int32_t
cjgui_native_bridge_command_queue_double_destroy_classify(uint64_t queue_token);
int32_t cjgui_native_bridge_command_queue_create_requires_main_thread(void);
int32_t cjgui_native_bridge_command_queue_destroy_requires_main_thread(void);
int32_t cjgui_native_bridge_command_buffer_creation_still_blocked(void);
uint32_t cjgui_native_bridge_command_buffer_table_capacity(void);
uint32_t cjgui_native_bridge_command_buffer_table_enabled(void);
uint32_t cjgui_native_bridge_command_buffer_table_occupied_count(void);
int32_t cjgui_native_bridge_command_buffer_create(
    uint64_t queue_token,
    uint64_t* out_buffer_token
);
int32_t cjgui_native_bridge_command_buffer_destroy(uint64_t buffer_token);
int32_t cjgui_native_bridge_command_buffer_token_classify(
    uint64_t buffer_token
);
int32_t
cjgui_native_bridge_command_buffer_double_destroy_classify(uint64_t buffer_token);
int32_t cjgui_native_bridge_command_buffer_create_requires_main_thread(void);
int32_t cjgui_native_bridge_command_buffer_destroy_requires_main_thread(void);
int32_t cjgui_native_bridge_command_buffer_commit_still_blocked(void);
int32_t cjgui_native_bridge_command_buffer_encoder_creation_still_blocked(void);

#ifdef __cplusplus
}
#endif

#endif
