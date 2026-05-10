/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 承载 internal native bridge C ABI、AppKit import / class availability /
 * main-thread admission / no-object creation boundary、token-backed NSView first slice
 * 与内部 status taxonomy，不是 public runtime API。
 * Stop-line: 不创建窗口、应用、图层对象、设备、队列、绘制资源，不返回指针身份。
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
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAMETALLAYER_NO_ATTACH = 1u << 14
} CjguiNativeBridgeSurfaceCapability;

enum {
    CJGUI_NATIVE_BRIDGE_SURFACE_VERSION = 1u,
    CJGUI_NATIVE_BRIDGE_TOKEN_INVALID = 0u,
    CJGUI_NATIVE_BRIDGE_TOKEN_TABLE_CAPACITY = 8u,
    CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY = 4u,
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

#ifdef __cplusplus
}
#endif

#endif
