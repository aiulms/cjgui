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

// 共同层的场景内联 PNG（cjguiComposableImageFromTransfer）以
// `cjgui-transfer:<offerIdentity>` 作为资源身份，字节在应用内存里而不是文件。
// 这里复制有界编码字节进同一解码/缓存/纹理域；身份前缀不匹配返回 FAILED。
uint32_t cjgui_linux_image_prepare_bytes(CjguiLinuxImageDomain *domain, const char *resourcePath,
                                         const char *resourceId, uint64_t resourceVersion,
                                         const uint8_t *bytes, uint32_t length);

// 传输受理前的有界准入：真实解码整张 PNG 并按解码字节计入图片域预算，
// 成功后保留一条 identity 准入记录，场景节点随后复用同一身份时接管。
// 返回 0 成功；1 参数/签名无效；2 尺寸超限；3 真实解码失败；4 预算不足。
#define CJGUI_LINUX_IMAGE_ADMIT_OK 0
#define CJGUI_LINUX_IMAGE_ADMIT_INVALID 1
#define CJGUI_LINUX_IMAGE_ADMIT_DIMENSION 2
#define CJGUI_LINUX_IMAGE_ADMIT_DECODE 3
#define CJGUI_LINUX_IMAGE_ADMIT_BUDGET 4
int cjgui_linux_image_admit_transfer_png(CjguiLinuxImageDomain *domain, const char *identity,
                                         const uint8_t *bytes, uint32_t length,
                                         uint32_t *outWidth, uint32_t *outHeight,
                                         uint64_t *outDecodeMicros);
// 拒绝/关闭时撤回尚未被场景接管的准入。
void cjgui_linux_image_release_transfer_admission(CjguiLinuxImageDomain *domain, const char *identity);
uint32_t cjgui_linux_image_transfer_admission_count(CjguiLinuxImageDomain *domain);
uint64_t cjgui_linux_image_transfer_admission_bytes(CjguiLinuxImageDomain *domain);

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
