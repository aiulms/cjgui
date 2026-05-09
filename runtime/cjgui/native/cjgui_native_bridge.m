/*
 * Owner: production native bridge skeleton 写集。
 * Truth: 仅实现 no-resource callable C ABI 的确定性整数事实，不是运行时 bridge truth。
 * Stop-line: 只允许 pthread 当前线程分类；不导入平台框架，不创建 native 对象，不接仓颉 FFI，不返回 pointer。
 * Same-shape Boundary Brake: callable surface 不得被包装成 native bridge、Metal、backend、GPU、render 或 public API permission。
 */
#import "cjgui_native_bridge.h"
#include <pthread.h>

/*
 * 当前 callable 只暴露 no-resource status / capability / thread-classification facts。
 * pthread_main_np 只分类当前线程，不创建 AppKit / Metal / Foundation 对象。
 */
uint32_t cjgui_native_bridge_surface_version(void) {
    return CJGUI_NATIVE_BRIDGE_SURFACE_VERSION;
}

uint32_t cjgui_native_bridge_surface_capabilities(void) {
    return CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_VERSION_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_STATUS_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_CAPABILITY_QUERY |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_NO_RESOURCE_ADMISSION |
        CJGUI_NATIVE_BRIDGE_SURFACE_CAPABILITY_MAIN_THREAD_QUERY;
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
