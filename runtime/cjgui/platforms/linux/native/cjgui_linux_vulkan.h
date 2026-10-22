// runtime/cjgui/platforms/linux/native/cjgui_linux_vulkan.h
//
// Linux/Vulkan 绘制后端（窄平台实现）。
//
// 这一层只负责"把三角形变成像素并送到屏幕"：instance / physical device / device /
// surface / swapchain / render pass / 管线 / 顶点缓冲 / 字形图集纹理 / present。
// 它不认识 CJGUI 的场景树、不做布局、不做命中测试、不做文字整形。
//
// 与探针代码的关键区别（正式实现必须做到，不能照搬探针）：
//  1. present 信号量与交换链图像同寿命（每张图像一个，随交换链重建一起回收）：
//     present 等待的那个信号量必须活到该图像再次被 acquire，按在途帧复用会对仍在途的
//     信号量二次 signal；image-available 信号量 / VkFence / command buffer 才按在途帧 2
//     环形复用，并在该 slot 的 fence 被回收的同一时点一起回收；
//  2. 上传走持久映射的 staging buffer + fence 回收，不在帧中途 vkQueueWaitIdle；
//  3. swapchain 生命周期显式：out-of-date / suboptimal 都触发以 oldSwapchain 重建，
//     旧 imageView/framebuffer/旧链在重建成功后销毁；图集与管线跨重建存活；
//  4. 日常同步不用 vkDeviceWaitIdle，只在销毁序列里用一次。
//
// 线程约定：所有函数都只允许在渲染会话所属的那一个线程上调用。

#ifndef CJGUI_LINUX_VULKAN_H
#define CJGUI_LINUX_VULKAN_H

#include <stdint.h>
#include <stddef.h>

#include "cjgui_linux_window.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CjguiLinuxGpu CjguiLinuxGpu;

typedef enum CjguiLinuxGpuStatus {
    CJGUI_LINUX_GPU_OK = 0,
    CJGUI_LINUX_GPU_INSTANCE_FAILED = 1,
    CJGUI_LINUX_GPU_NO_DEVICE = 2,
    CJGUI_LINUX_GPU_SURFACE_FAILED = 3,
    CJGUI_LINUX_GPU_DEVICE_FAILED = 4,
    CJGUI_LINUX_GPU_SWAPCHAIN_FAILED = 5,
    CJGUI_LINUX_GPU_PIPELINE_FAILED = 6,
    CJGUI_LINUX_GPU_OUT_OF_DATE = 7,   // 本帧没有提交；上层应先用新尺寸重建后再试
    CJGUI_LINUX_GPU_SUBOPTIMAL = 8,    // 本帧已提交，但交换链需要在随后重建
    CJGUI_LINUX_GPU_INVALID = 9
} CjguiLinuxGpuStatus;

// 一个顶点：屏幕像素坐标 + 图集 UV + 顶点色。
// 所有几何（实心矩形、边框、文字、渐变近似）在 CPU 侧展开为这种三角形顶点。
typedef struct CjguiLinuxGpuVertex {
    float x;   // 像素，左上原点，+y 向下
    float y;
    float u;   // 图集归一化 UV；实心几何指向图集内保留的白色纹素
    float v;
    float r;   // 顶点色（与图集纹素相乘）
    float g;
    float b;
    float a;
} CjguiLinuxGpuVertex;

// 字形图集页尺寸。文本模块与 GPU 模块必须一致。
#define CJGUI_LINUX_ATLAS_SIDE 1024

// 建立 Vulkan 设备与交换链。window 必须已经创建。
// 失败返回 NULL 并把原因写入 *outStatus。
CjguiLinuxGpu *cjgui_linux_gpu_create(CjguiLinuxWindow *window, int *outStatus);

// 销毁顺序固定：等待设备空闲 → 销毁交换链与图像视图 → 销毁管线/描述符/图集 →
// 销毁 device → 销毁 surface → 销毁 instance。允许传 NULL。
void cjgui_linux_gpu_destroy(CjguiLinuxGpu *gpu);

// 用新的逻辑尺寸重建交换链。上层在 RESIZE 事件后调用。
// 返回 CJGUI_LINUX_GPU_OK 或错误码；重建失败时保留旧链不可用但可再次调用。
int cjgui_linux_gpu_resize(CjguiLinuxGpu *gpu, uint32_t logicalWidth, uint32_t logicalHeight);

// 开始一帧：取下一张图像、开始 render pass、清屏为 clear[4]（线性 0..1）。
// 返回 OK / OUT_OF_DATE。
int cjgui_linux_gpu_begin_frame(CjguiLinuxGpu *gpu, const float clear[4]);

// 提交一批已展开的三角形顶点。textured=1 时采样字形图集，0 时把 UV 置为白色纹素。
// 允许一帧内多次调用，按调用顺序绘制。
int cjgui_linux_gpu_draw_triangles(CjguiLinuxGpu *gpu, const CjguiLinuxGpuVertex *vertices,
                                   uint32_t vertexCount);

// 结束本帧：结束 render pass、提交命令缓冲、present。
// 返回 OK / OUT_OF_DATE / SUBOPTIMAL。
int cjgui_linux_gpu_end_frame(CjguiLinuxGpu *gpu);

// 把文本模块产生的图集脏矩形上传到 GPU 纹理（staging + copy，不阻塞设备）。
int cjgui_linux_gpu_upload_atlas(CjguiLinuxGpu *gpu, int x, int y, int width, int height,
                                 const uint8_t *rgba);

// 有界图片纹理槽。上传/释放只能在帧外调用；同一槽位的新内容替换旧内容时，
// 旧纹理进入 retire 队列。上传提交完成后即可单独释放 staging；image/view/
// descriptor 要等最后一次实际绘制提交完成。两者都由维护点轮询真实 fence
// 证明，不依赖额外绘制帧，也不等待设备。
#define CJGUI_LINUX_GPU_IMAGE_SLOTS 16u
int cjgui_linux_gpu_upload_image(CjguiLinuxGpu *gpu, uint32_t slot, uint32_t width, uint32_t height,
                                 const uint8_t *rgba);
void cjgui_linux_gpu_release_image(CjguiLinuxGpu *gpu, uint32_t slot);
int cjgui_linux_gpu_draw_image_triangles(CjguiLinuxGpu *gpu, uint32_t slot,
                                         const CjguiLinuxGpuVertex *vertices, uint32_t vertexCount);
uint64_t cjgui_linux_gpu_image_texture_bytes(CjguiLinuxGpu *gpu);
uint64_t cjgui_linux_gpu_image_retired_bytes(CjguiLinuxGpu *gpu);
uint64_t cjgui_linux_gpu_image_staging_bytes(CjguiLinuxGpu *gpu);
// 图片纹理代的生命周期诊断：进入 retire 链的次数、经真实 fence 完成回收的
// 次数、staging 释放次数，以及最近一次回收所依据的提交序号。
uint64_t cjgui_linux_gpu_image_retire_count(CjguiLinuxGpu *gpu);
uint64_t cjgui_linux_gpu_image_reclaim_count(CjguiLinuxGpu *gpu);
uint64_t cjgui_linux_gpu_image_staging_release_count(CjguiLinuxGpu *gpu);
uint64_t cjgui_linux_gpu_image_last_reclaim_serial(CjguiLinuxGpu *gpu);

// 图片上传/纹理代维护点：只轮询真实 fence，不等待设备；由图片 pump 与
// begin_frame 调用。释放已证明完成的上传 staging，并回收上传与最后使用
// 都有具体提交证明的退休代。
void cjgui_linux_gpu_pump_image_resources(CjguiLinuxGpu *gpu);

// 当前交换链的可绘制像素尺寸（设备像素，非逻辑点）。
uint32_t cjgui_linux_gpu_drawable_width(CjguiLinuxGpu *gpu);
uint32_t cjgui_linux_gpu_drawable_height(CjguiLinuxGpu *gpu);

// 设备像素比：drawable / logical。
double cjgui_linux_gpu_scale(CjguiLinuxGpu *gpu);

// 已完成的帧数（成功 present 的次数）；用于 present observation 与诊断。
uint64_t cjgui_linux_gpu_frame_index(CjguiLinuxGpu *gpu);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_VULKAN_H
