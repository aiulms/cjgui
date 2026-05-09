/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 仅承载 no-resource callable C ABI 与内部 status taxonomy，不是仓颉 runtime FFI 接口。
 * Stop-line: 不接 FFI，不创建平台对象、图层、设备、队列、绘制资源或指针身份。
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
    CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_MAIN_THREAD_QUERY = 1u << 4
} CjguiNativeBridgeSurfaceCapability;

enum {
    CJGUI_NATIVE_BRIDGE_SURFACE_VERSION = 1u
};

/*
 * 第一批 callable 只返回 dehydrated integer facts。
 * 它们不创建 native object，不返回 pointer，不接仓颉 FFI，也不表示 backend ready。
 */
uint32_t cjgui_native_bridge_surface_version(void);
uint32_t cjgui_native_bridge_surface_capabilities(void);
uint32_t cjgui_native_bridge_status_ok(void);
uint32_t cjgui_native_bridge_no_resource_admission(void);
int32_t cjgui_native_bridge_is_main_thread(void);

#ifdef __cplusplus
}
#endif

#endif
