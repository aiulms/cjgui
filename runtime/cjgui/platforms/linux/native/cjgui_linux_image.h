// runtime/cjgui/platforms/linux/native/cjgui_linux_image.h
//
// Linux 本地 PNG 资源域：有界异步解码、版本化身份、LRU/字节预算缓存、
// 失败状态与主线程纹理上传。它只拥有图片数据与调度；场景节点、共同身份/
// 版本语义仍由共同层和 session 持有。所有函数除销毁前的 worker 内部外，
// 都在会话所属线程调用；完成通知经窗口自唤醒管道送回主线程。

#ifndef CJGUI_LINUX_IMAGE_H
#define CJGUI_LINUX_IMAGE_H

#include <stddef.h>
#include <stdint.h>

#include "cjgui_linux_vulkan.h"
#include "cjgui_linux_window.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CjguiLinuxImageDomain CjguiLinuxImageDomain;

// 与 cjgui_internal_renderer_image_resource_state 的 outState 约定一致。
#define CJGUI_LINUX_IMAGE_UNREQUESTED 0u
#define CJGUI_LINUX_IMAGE_LOADING 1u
#define CJGUI_LINUX_IMAGE_READY 2u
#define CJGUI_LINUX_IMAGE_FAILED 3u
#define CJGUI_LINUX_IMAGE_BUSY 4u

CjguiLinuxImageDomain *cjgui_linux_image_domain_create(CjguiLinuxGpu *gpu, CjguiLinuxWindow *window);
void cjgui_linux_image_domain_destroy(CjguiLinuxImageDomain *domain);

// 请求或观察一次准备。prepare 可能入队真实解码；state 只读。
uint32_t cjgui_linux_image_prepare(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                   const char *resourceId, uint64_t resourceVersion);
uint32_t cjgui_linux_image_state(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                 const char *resourceId, uint64_t resourceVersion);

// 主线程结算：取出 worker 结果、上传纹理并推进 completionVersion。
void cjgui_linux_image_pump(CjguiLinuxImageDomain *domain);

// ready 时返回 1 并写出源尺寸与 GPU 槽位；否则返回 0 且槽位为 UINT32_MAX。
int cjgui_linux_image_texture(CjguiLinuxImageDomain *domain, const char *resourcePath,
                              const char *resourceId, uint64_t resourceVersion,
                              uint32_t *outWidth, uint32_t *outHeight, uint32_t *outSlot);

// 接受场景当前引用集合；被引用的资源不参与淘汰。session 在提交场景时
// 先 clear，再对每个图片节点 add 一次。
void cjgui_linux_image_clear_references(CjguiLinuxImageDomain *domain);
void cjgui_linux_image_add_reference(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                     const char *resourceId, uint64_t resourceVersion);

// 与 prepare/texture 相同的解析与身份拼接；调用方提供输出缓冲。
int cjgui_linux_image_cache_key(const char *resourcePath, const char *resourceId,
                                uint64_t resourceVersion, char *out, size_t capacity);

uint64_t cjgui_linux_image_completion_version(CjguiLinuxImageDomain *domain);
uint64_t cjgui_linux_image_decode_start_count(CjguiLinuxImageDomain *domain);
uint64_t cjgui_linux_image_cache_bytes(CjguiLinuxImageDomain *domain);
uint32_t cjgui_linux_image_live_count(CjguiLinuxImageDomain *domain);
// 预算/恢复诊断：在途预留字节（pending+解码中+未结算完成）、ready 淘汰次数、
// 因 ready 8 项/32 MiB 引用占满而具名失败的次数。
uint32_t cjgui_linux_image_ready_count(CjguiLinuxImageDomain *domain);
uint64_t cjgui_linux_image_inflight_bytes(CjguiLinuxImageDomain *domain);
uint64_t cjgui_linux_image_cache_eviction_count(CjguiLinuxImageDomain *domain);
uint64_t cjgui_linux_image_capacity_failure_count(CjguiLinuxImageDomain *domain);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_IMAGE_H
