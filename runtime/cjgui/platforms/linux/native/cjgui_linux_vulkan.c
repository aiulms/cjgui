// runtime/cjgui/platforms/linux/native/cjgui_linux_vulkan.c
//
// Linux/Vulkan 绘制后端（窄平台实现）。契约见 cjgui_linux_vulkan.h。
//
// 本层只做"三角形 -> 像素 -> 屏幕"：instance / physical device / device / surface /
// swapchain / render pass / 管线 / 顶点缓冲 / 字形图集纹理 / present。不认识场景树，
// 不做布局、命中测试、文字整形。
//
// 与探针代码的关键区别（正式实现的前提）：
//
//  1. 在途帧固定 2，每个 slot 各自持有 command buffer / VkFence / image-available
//     信号量：这三者都在"该 slot 的 fence 收到信号并被重新武装"的同一时点回收。
//     present 等待的 render-finished 信号量按"交换链图像"分配（环长 = imageCount，
//     随交换链重建一起回收）：presentation engine 对它的 wait 要到该图像被重新
//     acquire 才算结束，若也按帧号复用，就可能在一个仍被交换链引用的 VkSemaphore
//     上再次 signal（VUID-vkQueueSubmit-pSignalSemaphores-00067 一类约束）。按图像
//     分配是唯一既复用又不与 present 生命期冲突的环形方案。
//
//  2. 图集上传：持久映射 staging + 每 slot 一个 fence 回收，fence 未回收才由 CPU
//     等待；上传自己提交并自带 pipeline barrier，帧中途不做 vkQueueWaitIdle /
//     vkDeviceWaitIdle。
//
//  3. 交换链生命周期显式：OUT_OF_DATE / SUBOPTIMAL 都触发以 oldSwapchain 重建；
//     新链（swapchain / imageView / framebuffer / present 信号量）建成后才销毁旧对象；
//     render pass 与管线在图集和 format 不变时跨重建存活（viewport/scissor 走
//     dynamic state，所以尺寸变化不需要新管线）。
//
//  4. 重建前只"排空队列"，不 vkDeviceWaitIdle：先等全部在途帧 fence，再提交一个空
//     command buffer 并用自持 fence 等它返回——队列序上早于它的 present 至此都已
//     执行完，旧链不再被引用。vkDeviceWaitIdle 只在销毁序列里调用一次。
//
// 线程约定：所有函数只在渲染会话所属线程调用，内部不加锁。
//
// 依赖：libvulkan + X11/xcb（含 VK_KHR_xcb_surface / VK_KHR_xlib_surface），
// 不引入任何外部 GUI 框架。

#define VK_USE_PLATFORM_XCB_KHR 1
#define VK_USE_PLATFORM_XLIB_KHR 1

#include "cjgui_linux_vulkan.h"

#include <vulkan/vulkan.h>
#include <X11/Xlib.h>
#include <xcb/xcb.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ---------------------------------------------------------------------------
// 编译期常量
// ---------------------------------------------------------------------------

#define CJGUI_VK_IN_FLIGHT 2u        // 在途帧数（契约要求固定 2）
#define CJGUI_VK_UPLOAD_SLOTS 3u     // 图集上传 staging 环长
#define CJGUI_VK_VERTEX_MIN_BYTES (256u * 1024u)
#define CJGUI_VK_PUSH_BYTES 16u      // vec2 viewport + float textured + float pad

// 图集里保留给"实心几何白色纹素"的左上角方块（与 cjgui_linux_text.h 一致）。
#define CJGUI_VK_WHITE_TEXEL_SIDE 2

// ---------------------------------------------------------------------------
// 内嵌 SPIR-V（由 ui.vert / ui.frag 用 glslangValidator -V 现场编译后内嵌，
// 运行时不读文件）
// ---------------------------------------------------------------------------

// ui.vert.spv  (2064 bytes, 516 words)
static const uint32_t kVertexShaderSpirv[] = {
    0x07230203u, 0x00010000u, 0x0008000bu, 0x00000049u, 0x00000000u, 0x00020011u, 0x00000001u, 0x0006000bu,
    0x00000001u, 0x4c534c47u, 0x6474732eu, 0x3035342eu, 0x00000000u, 0x0003000eu, 0x00000000u, 0x00000001u,
    0x000b000fu, 0x00000000u, 0x00000004u, 0x6e69616du, 0x00000000u, 0x0000001cu, 0x0000003au, 0x00000042u,
    0x00000043u, 0x00000045u, 0x00000047u, 0x00030003u, 0x00000002u, 0x000001c2u, 0x00040005u, 0x00000004u,
    0x6e69616du, 0x00000000u, 0x00030005u, 0x00000009u, 0x0063646eu, 0x00050005u, 0x0000000cu, 0x75676a43u,
    0x73755069u, 0x00000068u, 0x00060006u, 0x0000000cu, 0x00000000u, 0x77656976u, 0x74726f70u, 0x00000000u,
    0x00060006u, 0x0000000cu, 0x00000001u, 0x74786574u, 0x64657275u, 0x00000000u, 0x00050006u, 0x0000000cu,
    0x00000002u, 0x6461705fu, 0x00000000u, 0x00030005u, 0x0000000eu, 0x00006370u, 0x00050005u, 0x0000001cu,
    0x6f506e69u, 0x69746973u, 0x00006e6fu, 0x00060005u, 0x00000038u, 0x505f6c67u, 0x65567265u, 0x78657472u,
    0x00000000u, 0x00060006u, 0x00000038u, 0x00000000u, 0x505f6c67u, 0x7469736fu, 0x006e6f69u, 0x00070006u,
    0x00000038u, 0x00000001u, 0x505f6c67u, 0x746e696fu, 0x657a6953u, 0x00000000u, 0x00070006u, 0x00000038u,
    0x00000002u, 0x435f6c67u, 0x4470696cu, 0x61747369u, 0x0065636eu, 0x00070006u, 0x00000038u, 0x00000003u,
    0x435f6c67u, 0x446c6c75u, 0x61747369u, 0x0065636eu, 0x00030005u, 0x0000003au, 0x00000000u, 0x00030005u,
    0x00000042u, 0x00765576u, 0x00040005u, 0x00000043u, 0x76556e69u, 0x00000000u, 0x00040005u, 0x00000045u,
    0x6c6f4376u, 0x0000726fu, 0x00040005u, 0x00000047u, 0x6f436e69u, 0x00726f6cu, 0x00030047u, 0x0000000cu,
    0x00000002u, 0x00050048u, 0x0000000cu, 0x00000000u, 0x00000023u, 0x00000000u, 0x00050048u, 0x0000000cu,
    0x00000001u, 0x00000023u, 0x00000008u, 0x00050048u, 0x0000000cu, 0x00000002u, 0x00000023u, 0x0000000cu,
    0x00040047u, 0x0000001cu, 0x0000001eu, 0x00000000u, 0x00030047u, 0x00000038u, 0x00000002u, 0x00050048u,
    0x00000038u, 0x00000000u, 0x0000000bu, 0x00000000u, 0x00050048u, 0x00000038u, 0x00000001u, 0x0000000bu,
    0x00000001u, 0x00050048u, 0x00000038u, 0x00000002u, 0x0000000bu, 0x00000003u, 0x00050048u, 0x00000038u,
    0x00000003u, 0x0000000bu, 0x00000004u, 0x00040047u, 0x00000042u, 0x0000001eu, 0x00000000u, 0x00040047u,
    0x00000043u, 0x0000001eu, 0x00000001u, 0x00040047u, 0x00000045u, 0x0000001eu, 0x00000001u, 0x00040047u,
    0x00000047u, 0x0000001eu, 0x00000002u, 0x00020013u, 0x00000002u, 0x00030021u, 0x00000003u, 0x00000002u,
    0x00030016u, 0x00000006u, 0x00000020u, 0x00040017u, 0x00000007u, 0x00000006u, 0x00000002u, 0x00040020u,
    0x00000008u, 0x00000007u, 0x00000007u, 0x0004002bu, 0x00000006u, 0x0000000au, 0x00000000u, 0x0005002cu,
    0x00000007u, 0x0000000bu, 0x0000000au, 0x0000000au, 0x0005001eu, 0x0000000cu, 0x00000007u, 0x00000006u,
    0x00000006u, 0x00040020u, 0x0000000du, 0x00000009u, 0x0000000cu, 0x0004003bu, 0x0000000du, 0x0000000eu,
    0x00000009u, 0x00040015u, 0x0000000fu, 0x00000020u, 0x00000001u, 0x0004002bu, 0x0000000fu, 0x00000010u,
    0x00000000u, 0x00040015u, 0x00000011u, 0x00000020u, 0x00000000u, 0x0004002bu, 0x00000011u, 0x00000012u,
    0x00000000u, 0x00040020u, 0x00000013u, 0x00000009u, 0x00000006u, 0x00020014u, 0x00000016u, 0x0004002bu,
    0x00000006u, 0x0000001au, 0x40000000u, 0x00040020u, 0x0000001bu, 0x00000001u, 0x00000007u, 0x0004003bu,
    0x0000001bu, 0x0000001cu, 0x00000001u, 0x00040020u, 0x0000001du, 0x00000001u, 0x00000006u, 0x0004002bu,
    0x00000006u, 0x00000024u, 0x3f800000u, 0x00040020u, 0x00000026u, 0x00000007u, 0x00000006u, 0x0004002bu,
    0x00000011u, 0x00000028u, 0x00000001u, 0x00040017u, 0x00000036u, 0x00000006u, 0x00000004u, 0x0004001cu,
    0x00000037u, 0x00000006u, 0x00000028u, 0x0006001eu, 0x00000038u, 0x00000036u, 0x00000006u, 0x00000037u,
    0x00000037u, 0x00040020u, 0x00000039u, 0x00000003u, 0x00000038u, 0x0004003bu, 0x00000039u, 0x0000003au,
    0x00000003u, 0x00040020u, 0x0000003fu, 0x00000003u, 0x00000036u, 0x00040020u, 0x00000041u, 0x00000003u,
    0x00000007u, 0x0004003bu, 0x00000041u, 0x00000042u, 0x00000003u, 0x0004003bu, 0x0000001bu, 0x00000043u,
    0x00000001u, 0x0004003bu, 0x0000003fu, 0x00000045u, 0x00000003u, 0x00040020u, 0x00000046u, 0x00000001u,
    0x00000036u, 0x0004003bu, 0x00000046u, 0x00000047u, 0x00000001u, 0x00050036u, 0x00000002u, 0x00000004u,
    0x00000000u, 0x00000003u, 0x000200f8u, 0x00000005u, 0x0004003bu, 0x00000008u, 0x00000009u, 0x00000007u,
    0x0003003eu, 0x00000009u, 0x0000000bu, 0x00060041u, 0x00000013u, 0x00000014u, 0x0000000eu, 0x00000010u,
    0x00000012u, 0x0004003du, 0x00000006u, 0x00000015u, 0x00000014u, 0x000500bau, 0x00000016u, 0x00000017u,
    0x00000015u, 0x0000000au, 0x000300f7u, 0x00000019u, 0x00000000u, 0x000400fau, 0x00000017u, 0x00000018u,
    0x00000019u, 0x000200f8u, 0x00000018u, 0x00050041u, 0x0000001du, 0x0000001eu, 0x0000001cu, 0x00000012u,
    0x0004003du, 0x00000006u, 0x0000001fu, 0x0000001eu, 0x00050085u, 0x00000006u, 0x00000020u, 0x0000001au,
    0x0000001fu, 0x00060041u, 0x00000013u, 0x00000021u, 0x0000000eu, 0x00000010u, 0x00000012u, 0x0004003du,
    0x00000006u, 0x00000022u, 0x00000021u, 0x00050088u, 0x00000006u, 0x00000023u, 0x00000020u, 0x00000022u,
    0x00050083u, 0x00000006u, 0x00000025u, 0x00000023u, 0x00000024u, 0x00050041u, 0x00000026u, 0x00000027u,
    0x00000009u, 0x00000012u, 0x0003003eu, 0x00000027u, 0x00000025u, 0x000200f9u, 0x00000019u, 0x000200f8u,
    0x00000019u, 0x00060041u, 0x00000013u, 0x00000029u, 0x0000000eu, 0x00000010u, 0x00000028u, 0x0004003du,
    0x00000006u, 0x0000002au, 0x00000029u, 0x000500bau, 0x00000016u, 0x0000002bu, 0x0000002au, 0x0000000au,
    0x000300f7u, 0x0000002du, 0x00000000u, 0x000400fau, 0x0000002bu, 0x0000002cu, 0x0000002du, 0x000200f8u,
    0x0000002cu, 0x00050041u, 0x0000001du, 0x0000002eu, 0x0000001cu, 0x00000028u, 0x0004003du, 0x00000006u,
    0x0000002fu, 0x0000002eu, 0x00050085u, 0x00000006u, 0x00000030u, 0x0000001au, 0x0000002fu, 0x00060041u,
    0x00000013u, 0x00000031u, 0x0000000eu, 0x00000010u, 0x00000028u, 0x0004003du, 0x00000006u, 0x00000032u,
    0x00000031u, 0x00050088u, 0x00000006u, 0x00000033u, 0x00000030u, 0x00000032u, 0x00050083u, 0x00000006u,
    0x00000034u, 0x00000033u, 0x00000024u, 0x00050041u, 0x00000026u, 0x00000035u, 0x00000009u, 0x00000028u,
    0x0003003eu, 0x00000035u, 0x00000034u, 0x000200f9u, 0x0000002du, 0x000200f8u, 0x0000002du, 0x0004003du,
    0x00000007u, 0x0000003bu, 0x00000009u, 0x00050051u, 0x00000006u, 0x0000003cu, 0x0000003bu, 0x00000000u,
    0x00050051u, 0x00000006u, 0x0000003du, 0x0000003bu, 0x00000001u, 0x00070050u, 0x00000036u, 0x0000003eu,
    0x0000003cu, 0x0000003du, 0x0000000au, 0x00000024u, 0x00050041u, 0x0000003fu, 0x00000040u, 0x0000003au,
    0x00000010u, 0x0003003eu, 0x00000040u, 0x0000003eu, 0x0004003du, 0x00000007u, 0x00000044u, 0x00000043u,
    0x0003003eu, 0x00000042u, 0x00000044u, 0x0004003du, 0x00000036u, 0x00000048u, 0x00000047u, 0x0003003eu,
    0x00000045u, 0x00000048u, 0x000100fdu, 0x00010038u,
};

// ui.frag.spv  (1260 bytes, 315 words)
static const uint32_t kFragmentShaderSpirv[] = {
    0x07230203u, 0x00010000u, 0x0008000bu, 0x0000002du, 0x00000000u, 0x00020011u, 0x00000001u, 0x0006000bu,
    0x00000001u, 0x4c534c47u, 0x6474732eu, 0x3035342eu, 0x00000000u, 0x0003000eu, 0x00000000u, 0x00000001u,
    0x0008000fu, 0x00000004u, 0x00000004u, 0x6e69616du, 0x00000000u, 0x0000001fu, 0x00000027u, 0x0000002au,
    0x00030010u, 0x00000004u, 0x00000007u, 0x00030003u, 0x00000002u, 0x000001c2u, 0x00040005u, 0x00000004u,
    0x6e69616du, 0x00000000u, 0x00040005u, 0x00000009u, 0x65786574u, 0x0000006cu, 0x00050005u, 0x0000000bu,
    0x75676a43u, 0x73755069u, 0x00000068u, 0x00060006u, 0x0000000bu, 0x00000000u, 0x77656976u, 0x74726f70u,
    0x00000000u, 0x00060006u, 0x0000000bu, 0x00000001u, 0x74786574u, 0x64657275u, 0x00000000u, 0x00050006u,
    0x0000000bu, 0x00000002u, 0x6461705fu, 0x00000000u, 0x00030005u, 0x0000000du, 0x00006370u, 0x00060005u,
    0x0000001cu, 0x616c7461u, 0x78655473u, 0x65727574u, 0x00000000u, 0x00030005u, 0x0000001fu, 0x00765576u,
    0x00050005u, 0x00000027u, 0x4374756fu, 0x726f6c6fu, 0x00000000u, 0x00040005u, 0x0000002au, 0x6c6f4376u,
    0x0000726fu, 0x00030047u, 0x0000000bu, 0x00000002u, 0x00050048u, 0x0000000bu, 0x00000000u, 0x00000023u,
    0x00000000u, 0x00050048u, 0x0000000bu, 0x00000001u, 0x00000023u, 0x00000008u, 0x00050048u, 0x0000000bu,
    0x00000002u, 0x00000023u, 0x0000000cu, 0x00040047u, 0x0000001cu, 0x00000021u, 0x00000000u, 0x00040047u,
    0x0000001cu, 0x00000022u, 0x00000000u, 0x00040047u, 0x0000001fu, 0x0000001eu, 0x00000000u, 0x00040047u,
    0x00000027u, 0x0000001eu, 0x00000000u, 0x00040047u, 0x0000002au, 0x0000001eu, 0x00000001u, 0x00020013u,
    0x00000002u, 0x00030021u, 0x00000003u, 0x00000002u, 0x00030016u, 0x00000006u, 0x00000020u, 0x00040017u,
    0x00000007u, 0x00000006u, 0x00000004u, 0x00040020u, 0x00000008u, 0x00000007u, 0x00000007u, 0x00040017u,
    0x0000000au, 0x00000006u, 0x00000002u, 0x0005001eu, 0x0000000bu, 0x0000000au, 0x00000006u, 0x00000006u,
    0x00040020u, 0x0000000cu, 0x00000009u, 0x0000000bu, 0x0004003bu, 0x0000000cu, 0x0000000du, 0x00000009u,
    0x00040015u, 0x0000000eu, 0x00000020u, 0x00000001u, 0x0004002bu, 0x0000000eu, 0x0000000fu, 0x00000001u,
    0x00040020u, 0x00000010u, 0x00000009u, 0x00000006u, 0x0004002bu, 0x00000006u, 0x00000013u, 0x3f000000u,
    0x00020014u, 0x00000014u, 0x00090019u, 0x00000019u, 0x00000006u, 0x00000001u, 0x00000000u, 0x00000000u,
    0x00000000u, 0x00000001u, 0x00000000u, 0x0003001bu, 0x0000001au, 0x00000019u, 0x00040020u, 0x0000001bu,
    0x00000000u, 0x0000001au, 0x0004003bu, 0x0000001bu, 0x0000001cu, 0x00000000u, 0x00040020u, 0x0000001eu,
    0x00000001u, 0x0000000au, 0x0004003bu, 0x0000001eu, 0x0000001fu, 0x00000001u, 0x0004002bu, 0x00000006u,
    0x00000023u, 0x3f800000u, 0x0007002cu, 0x00000007u, 0x00000024u, 0x00000023u, 0x00000023u, 0x00000023u,
    0x00000023u, 0x00040020u, 0x00000026u, 0x00000003u, 0x00000007u, 0x0004003bu, 0x00000026u, 0x00000027u,
    0x00000003u, 0x00040020u, 0x00000029u, 0x00000001u, 0x00000007u, 0x0004003bu, 0x00000029u, 0x0000002au,
    0x00000001u, 0x00050036u, 0x00000002u, 0x00000004u, 0x00000000u, 0x00000003u, 0x000200f8u, 0x00000005u,
    0x0004003bu, 0x00000008u, 0x00000009u, 0x00000007u, 0x0004003bu, 0x00000008u, 0x00000016u, 0x00000007u,
    0x00050041u, 0x00000010u, 0x00000011u, 0x0000000du, 0x0000000fu, 0x0004003du, 0x00000006u, 0x00000012u,
    0x00000011u, 0x000500bau, 0x00000014u, 0x00000015u, 0x00000012u, 0x00000013u, 0x000300f7u, 0x00000018u,
    0x00000000u, 0x000400fau, 0x00000015u, 0x00000017u, 0x00000022u, 0x000200f8u, 0x00000017u, 0x0004003du,
    0x0000001au, 0x0000001du, 0x0000001cu, 0x0004003du, 0x0000000au, 0x00000020u, 0x0000001fu, 0x00050057u,
    0x00000007u, 0x00000021u, 0x0000001du, 0x00000020u, 0x0003003eu, 0x00000016u, 0x00000021u, 0x000200f9u,
    0x00000018u, 0x000200f8u, 0x00000022u, 0x0003003eu, 0x00000016u, 0x00000024u, 0x000200f9u, 0x00000018u,
    0x000200f8u, 0x00000018u, 0x0004003du, 0x00000007u, 0x00000025u, 0x00000016u, 0x0003003eu, 0x00000009u,
    0x00000025u, 0x0004003du, 0x00000007u, 0x00000028u, 0x00000009u, 0x0004003du, 0x00000007u, 0x0000002bu,
    0x0000002au, 0x00050085u, 0x00000007u, 0x0000002cu, 0x00000028u, 0x0000002bu, 0x0003003eu, 0x00000027u,
    0x0000002cu, 0x000100fdu, 0x00010038u,
};

// ---------------------------------------------------------------------------
// 类型
// ---------------------------------------------------------------------------

typedef struct CjguiVkPushConstants {
    float viewportWidth;   // 绘制区像素宽
    float viewportHeight;  // 绘制区像素高
    float textured;        // 1 = 采样图集，0 = 只用顶点色
    float pad;
} CjguiVkPushConstants;

typedef struct CjguiVkDrawRange {
    uint32_t firstVertex;
    uint32_t vertexCount;
    float textured;
} CjguiVkDrawRange;

// 一个在途帧 slot：命令缓冲 / fence / image-available 信号量同一时点回收。
typedef struct CjguiVkFrame {
    VkCommandBuffer cmd;
    VkFence fence;
    VkSemaphore imageAvailable;
    int fencePending;              // 已提交且 fence 尚未回收

    VkBuffer vertexBuffer;         // host-visible，持久映射，按需增长
    VkDeviceMemory vertexMemory;
    void *vertexMapped;
    int vertexCoherent;
    VkDeviceSize vertexBytes;

    CjguiLinuxGpuVertex *cpuVerts; // 本帧 CPU 侧顶点（end_frame 时一次性写入）
    uint32_t cpuCapacity;
    uint32_t vertexCount;

    CjguiVkDrawRange *draws;       // 本帧绘制序列（按调用顺序）
    uint32_t drawCapacity;
    uint32_t drawCount;
} CjguiVkFrame;

// 图集上传 staging slot：持久映射 + 自己的 fence。
typedef struct CjguiVkUpload {
    VkCommandBuffer cmd;
    VkFence fence;
    VkBuffer staging;
    VkDeviceMemory stagingMemory;
    void *mapped;
    VkDeviceSize bytes;
    int coherent;
    int fencePending;
} CjguiVkUpload;

typedef struct CjguiVkSwapchain {
    VkSwapchainKHR handle;
    VkFormat format;
    VkColorSpaceKHR colorSpace;
    VkPresentModeKHR presentMode;
    VkExtent2D extent;
    uint32_t imageCount;
    VkImage *images;
    VkImageView *views;
    VkFramebuffer *framebuffers;
    VkSemaphore *renderFinished;   // 每张图像一个（present 等待的那个）
} CjguiVkSwapchain;

struct CjguiLinuxGpu {
    CjguiLinuxWindow *window;

    VkInstance instance;
    VkSurfaceKHR surface;
    const char *surfaceKind;       // "xcb" / "xlib"（诊断用）

    VkPhysicalDevice physicalDevice;
    VkDevice device;
    VkQueue queue;
    uint32_t queueFamily;

    CjguiVkSwapchain swapchain;
    int swapchainUsable;

    VkRenderPass renderPass;
    VkFormat renderPassFormat;
    VkPipelineLayout pipelineLayout;
    VkPipeline pipeline;
    int pipelineFormatValid;

    VkDescriptorSetLayout descriptorSetLayout;
    VkDescriptorPool descriptorPool;
    VkDescriptorSet descriptorSets[CJGUI_VK_IN_FLIGHT];

    VkSampler sampler;
    VkImage atlasImage;
    VkDeviceMemory atlasMemory;
    VkImageView atlasView;
    // 图集当前布局。所有上传都在同一条队列上按提交顺序转换，因此软件跟踪即可；
    // 第一次上传必须从 UNDEFINED 起转（不能假设它已经是 SHADER_READ_ONLY）。
    VkImageLayout atlasLayout;

    VkCommandPool commandPool;
    CjguiVkFrame frames[CJGUI_VK_IN_FLIGHT];
    CjguiVkUpload uploads[CJGUI_VK_UPLOAD_SLOTS];
    uint32_t uploadNext;

    VkCommandBuffer drainCmd;
    VkFence drainFence;

    uint32_t logicalWidth;
    uint32_t logicalHeight;
    double windowScale;

    uint64_t frameSerial;          // begin_frame 次数（用于 slot 轮转）
    uint64_t frameIndex;           // 成功 present 的次数
    int frameActive;
    uint32_t currentSlot;
    uint32_t currentImage;
    float clearColor[4];
};

// ---------------------------------------------------------------------------
// 诊断 / 错误
// ---------------------------------------------------------------------------

static const char *cjgui_vk_result_name(VkResult r)
{
    switch (r) {
        case VK_SUCCESS: return "VK_SUCCESS";
        case VK_NOT_READY: return "VK_NOT_READY";
        case VK_TIMEOUT: return "VK_TIMEOUT";
        case VK_EVENT_SET: return "VK_EVENT_SET";
        case VK_EVENT_RESET: return "VK_EVENT_RESET";
        case VK_INCOMPLETE: return "VK_INCOMPLETE";
        case VK_ERROR_OUT_OF_HOST_MEMORY: return "VK_ERROR_OUT_OF_HOST_MEMORY";
        case VK_ERROR_OUT_OF_DEVICE_MEMORY: return "VK_ERROR_OUT_OF_DEVICE_MEMORY";
        case VK_ERROR_INITIALIZATION_FAILED: return "VK_ERROR_INITIALIZATION_FAILED";
        case VK_ERROR_DEVICE_LOST: return "VK_ERROR_DEVICE_LOST";
        case VK_ERROR_MEMORY_MAP_FAILED: return "VK_ERROR_MEMORY_MAP_FAILED";
        case VK_ERROR_LAYER_NOT_PRESENT: return "VK_ERROR_LAYER_NOT_PRESENT";
        case VK_ERROR_EXTENSION_NOT_PRESENT: return "VK_ERROR_EXTENSION_NOT_PRESENT";
        case VK_ERROR_FEATURE_NOT_PRESENT: return "VK_ERROR_FEATURE_NOT_PRESENT";
        case VK_ERROR_INCOMPATIBLE_DRIVER: return "VK_ERROR_INCOMPATIBLE_DRIVER";
        case VK_ERROR_TOO_MANY_OBJECTS: return "VK_ERROR_TOO_MANY_OBJECTS";
        case VK_ERROR_FORMAT_NOT_SUPPORTED: return "VK_ERROR_FORMAT_NOT_SUPPORTED";
        case VK_ERROR_SURFACE_LOST_KHR: return "VK_ERROR_SURFACE_LOST_KHR";
        case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: return "VK_ERROR_NATIVE_WINDOW_IN_USE_KHR";
        case VK_SUBOPTIMAL_KHR: return "VK_SUBOPTIMAL_KHR";
        case VK_ERROR_OUT_OF_DATE_KHR: return "VK_ERROR_OUT_OF_DATE_KHR";
        case VK_ERROR_INCOMPATIBLE_DISPLAY_KHR: return "VK_ERROR_INCOMPATIBLE_DISPLAY_KHR";
        case VK_ERROR_VALIDATION_FAILED_EXT: return "VK_ERROR_VALIDATION_FAILED_EXT";
        case VK_ERROR_UNKNOWN: return "VK_ERROR_UNKNOWN";
        default: return "VK_RESULT_OTHER";
    }
}

static const char *cjgui_vk_present_mode_name(VkPresentModeKHR m)
{
    switch (m) {
        case VK_PRESENT_MODE_IMMEDIATE_KHR: return "IMMEDIATE";
        case VK_PRESENT_MODE_MAILBOX_KHR: return "MAILBOX";
        case VK_PRESENT_MODE_FIFO_KHR: return "FIFO";
        case VK_PRESENT_MODE_FIFO_RELAXED_KHR: return "FIFO_RELAXED";
        case VK_PRESENT_MODE_SHARED_DEMAND_REFRESH_KHR: return "SHARED_DEMAND_REFRESH";
        case VK_PRESENT_MODE_SHARED_CONTINUOUS_REFRESH_KHR: return "SHARED_CONTINUOUS_REFRESH";
        default: return "UNKNOWN";
    }
}

static int cjgui_vk_fail(const char *what, VkResult r, int status)
{
    fprintf(stderr, "cjgui_linux_vulkan: %s failed: %s (%d)\n", what, cjgui_vk_result_name(r), (int)r);
    return status;
}

static void cjgui_vk_note(const char *what, const char *detail)
{
    fprintf(stderr, "cjgui_linux_vulkan: %s: %s\n", what, detail);
}

// ---------------------------------------------------------------------------
// 小工具
// ---------------------------------------------------------------------------

static uint32_t cjgui_vk_clamp_u32(uint32_t v, uint32_t lo, uint32_t hi)
{
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

static int cjgui_vk_find_memory_type(CjguiLinuxGpu *gpu, uint32_t typeBits,
                                     VkMemoryPropertyFlags required,
                                     VkMemoryPropertyFlags preferred,
                                     uint32_t *outIndex)
{
    VkPhysicalDeviceMemoryProperties props;
    vkGetPhysicalDeviceMemoryProperties(gpu->physicalDevice, &props);
    for (uint32_t pass = 0; pass < 2; ++pass) {
        for (uint32_t i = 0; i < props.memoryTypeCount; ++i) {
            if ((typeBits & (1u << i)) == 0u) continue;
            VkMemoryPropertyFlags f = props.memoryTypes[i].propertyFlags;
            if ((f & required) != required) continue;
            if (pass == 0 && preferred != 0u && (f & preferred) != preferred) continue;
            *outIndex = i;
            return 0;
        }
    }
    fprintf(stderr,
            "cjgui_linux_vulkan: no usable memory type (bits=0x%x required=0x%x preferred=0x%x)\n",
            typeBits, (unsigned)required, (unsigned)preferred);
    return -1;
}

static void cjgui_vk_flush_range(CjguiLinuxGpu *gpu, VkDeviceMemory memory, VkDeviceSize offset,
                                 VkDeviceSize size, int coherent)
{
    if (coherent) return;
    VkMappedMemoryRange range;
    memset(&range, 0, sizeof range);
    range.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
    range.memory = memory;
    range.offset = offset;
    range.size = size;
    VkResult r = vkFlushMappedMemoryRanges(gpu->device, 1, &range);
    if (r != VK_SUCCESS) {
        cjgui_vk_fail("vkFlushMappedMemoryRanges", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }
}

// 创建持久映射的 host-visible buffer。返回 status。
static int cjgui_vk_create_mapped_buffer(CjguiLinuxGpu *gpu, VkDeviceSize size, VkBufferUsageFlags usage,
                                         const char *what, VkBuffer *outBuffer, VkDeviceMemory *outMemory,
                                         void **outMapped, int *outCoherent)
{
    VkBufferCreateInfo bci;
    memset(&bci, 0, sizeof bci);
    bci.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bci.size = size;
    bci.usage = usage;
    bci.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    VkResult r = vkCreateBuffer(gpu->device, &bci, NULL, outBuffer);
    if (r != VK_SUCCESS) return cjgui_vk_fail(what, r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkMemoryRequirements req;
    vkGetBufferMemoryRequirements(gpu->device, *outBuffer, &req);

    uint32_t typeIndex = 0;
    if (cjgui_vk_find_memory_type(gpu, req.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                                  VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &typeIndex) != 0) {
        vkDestroyBuffer(gpu->device, *outBuffer, NULL);
        *outBuffer = VK_NULL_HANDLE;
        return CJGUI_LINUX_GPU_DEVICE_FAILED;
    }

    VkPhysicalDeviceMemoryProperties props;
    vkGetPhysicalDeviceMemoryProperties(gpu->physicalDevice, &props);
    *outCoherent = (props.memoryTypes[typeIndex].propertyFlags & VK_MEMORY_PROPERTY_HOST_COHERENT_BIT) != 0u;

    VkMemoryAllocateInfo mai;
    memset(&mai, 0, sizeof mai);
    mai.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    mai.allocationSize = req.size;
    mai.memoryTypeIndex = typeIndex;
    r = vkAllocateMemory(gpu->device, &mai, NULL, outMemory);
    if (r != VK_SUCCESS) {
        vkDestroyBuffer(gpu->device, *outBuffer, NULL);
        *outBuffer = VK_NULL_HANDLE;
        return cjgui_vk_fail("vkAllocateMemory(buffer)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }

    r = vkBindBufferMemory(gpu->device, *outBuffer, *outMemory, 0);
    if (r != VK_SUCCESS) {
        vkDestroyBuffer(gpu->device, *outBuffer, NULL);
        vkFreeMemory(gpu->device, *outMemory, NULL);
        *outBuffer = VK_NULL_HANDLE;
        *outMemory = VK_NULL_HANDLE;
        return cjgui_vk_fail("vkBindBufferMemory", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }

    r = vkMapMemory(gpu->device, *outMemory, 0, VK_WHOLE_SIZE, 0, outMapped);
    if (r != VK_SUCCESS) {
        vkDestroyBuffer(gpu->device, *outBuffer, NULL);
        vkFreeMemory(gpu->device, *outMemory, NULL);
        *outBuffer = VK_NULL_HANDLE;
        *outMemory = VK_NULL_HANDLE;
        return cjgui_vk_fail("vkMapMemory", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }
    return CJGUI_LINUX_GPU_OK;
}

static void cjgui_vk_destroy_mapped_buffer(CjguiLinuxGpu *gpu, VkBuffer *buffer,
                                           VkDeviceMemory *memory, void **mapped)
{
    if (*mapped != NULL && *memory != VK_NULL_HANDLE) {
        vkUnmapMemory(gpu->device, *memory);
        *mapped = NULL;
    }
    if (*buffer != VK_NULL_HANDLE) {
        vkDestroyBuffer(gpu->device, *buffer, NULL);
        *buffer = VK_NULL_HANDLE;
    }
    if (*memory != VK_NULL_HANDLE) {
        vkFreeMemory(gpu->device, *memory, NULL);
        *memory = VK_NULL_HANDLE;
    }
}

static int cjgui_vk_alloc_command_buffer(CjguiLinuxGpu *gpu, VkCommandBuffer *out)
{
    VkCommandBufferAllocateInfo ai;
    memset(&ai, 0, sizeof ai);
    ai.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    ai.commandPool = gpu->commandPool;
    ai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    ai.commandBufferCount = 1;
    VkResult r = vkAllocateCommandBuffers(gpu->device, &ai, out);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkAllocateCommandBuffers", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    return CJGUI_LINUX_GPU_OK;
}

// ---------------------------------------------------------------------------
// 交换链
// ---------------------------------------------------------------------------

static uint32_t cjgui_vk_format_score(VkFormat f)
{
    switch (f) {
        case VK_FORMAT_B8G8R8A8_UNORM: return 1;   // 首选：无隐式 sRGB 转换
        case VK_FORMAT_B8G8R8A8_SRGB: return 2;
        case VK_FORMAT_R8G8B8A8_UNORM: return 3;
        case VK_FORMAT_R8G8B8A8_SRGB: return 4;
        case VK_FORMAT_A8B8G8R8_UNORM_PACK32: return 5;
        case VK_FORMAT_A8B8G8R8_SRGB_PACK32: return 6;
        default: return 100;
    }
}

static int cjgui_vk_pick_surface_format(CjguiLinuxGpu *gpu, VkSurfaceFormatKHR *out)
{
    uint32_t count = 0;
    VkResult r = vkGetPhysicalDeviceSurfaceFormatsKHR(gpu->physicalDevice, gpu->surface, &count, NULL);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkGetPhysicalDeviceSurfaceFormatsKHR(count)", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
    if (count == 0u) {
        fprintf(stderr, "cjgui_linux_vulkan: surface reports no formats\n");
        return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
    }
    VkSurfaceFormatKHR *list = (VkSurfaceFormatKHR *)malloc(sizeof(VkSurfaceFormatKHR) * count);
    if (list == NULL) {
        fprintf(stderr, "cjgui_linux_vulkan: out of memory reading surface formats\n");
        return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
    }
    r = vkGetPhysicalDeviceSurfaceFormatsKHR(gpu->physicalDevice, gpu->surface, &count, list);
    if (r != VK_SUCCESS) {
        free(list);
        return cjgui_vk_fail("vkGetPhysicalDeviceSurfaceFormatsKHR(list)", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
    }

    // 规范：只返回一个 VK_FORMAT_UNDEFINED 表示实现无偏好，按 B8G8R8A8_UNORM 处理。
    if (count == 1u && list[0].format == VK_FORMAT_UNDEFINED) {
        out->format = VK_FORMAT_B8G8R8A8_UNORM;
        out->colorSpace = list[0].colorSpace;
        free(list);
        return CJGUI_LINUX_GPU_OK;
    }

    uint32_t best = UINT32_MAX;
    uint32_t bestScore = UINT32_MAX;
    for (uint32_t i = 0; i < count; ++i) {
        if (list[i].format == VK_FORMAT_UNDEFINED) continue;
        uint32_t score = cjgui_vk_format_score(list[i].format);
        if (score < bestScore) {
            bestScore = score;
            best = i;
        }
    }
    if (best == UINT32_MAX) {
        free(list);
        fprintf(stderr, "cjgui_linux_vulkan: surface offers no usable format (all UNDEFINED)\n");
        return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
    }
    *out = list[best];
    free(list);
    return CJGUI_LINUX_GPU_OK;
}

static VkPresentModeKHR cjgui_vk_pick_present_mode(const VkPresentModeKHR *modes, uint32_t count)
{
    // 偏好顺序：MAILBOX（无撕裂且不依赖 vblank 节流）→ IMMEDIATE（X11 上可用，
    // 不能假设 FIFO 的 vblank 节流）→ FIFO_RELAXED → FIFO（规范保证恒存在）。
    static const VkPresentModeKHR preference[] = {
        VK_PRESENT_MODE_MAILBOX_KHR,
        VK_PRESENT_MODE_IMMEDIATE_KHR,
        VK_PRESENT_MODE_FIFO_RELAXED_KHR,
        VK_PRESENT_MODE_FIFO_KHR
    };
    for (size_t p = 0; p < sizeof(preference) / sizeof(preference[0]); ++p) {
        for (uint32_t i = 0; i < count; ++i) {
            if (modes[i] == preference[p]) return modes[i];
        }
    }
    return VK_PRESENT_MODE_FIFO_KHR;
}

static VkCompositeAlphaFlagBitsKHR cjgui_vk_pick_composite_alpha(VkCompositeAlphaFlagsKHR supported)
{
    static const VkCompositeAlphaFlagBitsKHR preference[] = {
        VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
        VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
        VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR
    };
    for (size_t p = 0; p < sizeof(preference) / sizeof(preference[0]); ++p) {
        if ((supported & preference[p]) != 0u) return preference[p];
    }
    return VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
}

static void cjgui_vk_swapchain_dispose(CjguiLinuxGpu *gpu, CjguiVkSwapchain *sc)
{
    if (sc->framebuffers != NULL) {
        for (uint32_t i = 0; i < sc->imageCount; ++i) {
            if (sc->framebuffers[i] != VK_NULL_HANDLE) {
                vkDestroyFramebuffer(gpu->device, sc->framebuffers[i], NULL);
            }
        }
    }
    if (sc->views != NULL) {
        for (uint32_t i = 0; i < sc->imageCount; ++i) {
            if (sc->views[i] != VK_NULL_HANDLE) {
                vkDestroyImageView(gpu->device, sc->views[i], NULL);
            }
        }
    }
    if (sc->renderFinished != NULL) {
        for (uint32_t i = 0; i < sc->imageCount; ++i) {
            if (sc->renderFinished[i] != VK_NULL_HANDLE) {
                vkDestroySemaphore(gpu->device, sc->renderFinished[i], NULL);
            }
        }
    }
    if (sc->handle != VK_NULL_HANDLE) {
        vkDestroySwapchainKHR(gpu->device, sc->handle, NULL);
    }
    free(sc->framebuffers);
    free(sc->views);
    free(sc->images);
    free(sc->renderFinished);
    memset(sc, 0, sizeof *sc);
}

// 建立新链（含 imageView / framebuffer / present 信号量），不触碰旧对象。
// oldHandle 仅作为 VK_KHR_swapchain 的 oldSwapchain 传入。
static int cjgui_vk_swapchain_build(CjguiLinuxGpu *gpu, VkSwapchainKHR oldHandle,
                                    const CjguiVkSwapchain *previous, CjguiVkSwapchain *out,
                                    uint32_t wantWidth, uint32_t wantHeight)
{
    VkSurfaceCapabilitiesKHR caps;
    VkResult r = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(gpu->physicalDevice, gpu->surface, &caps);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkGetPhysicalDeviceSurfaceCapabilitiesKHR", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);

    VkSurfaceFormatKHR format;
    memset(&format, 0, sizeof format);
    format.format = VK_FORMAT_UNDEFINED;
    format.colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    int st = cjgui_vk_pick_surface_format(gpu, &format);
    if (st != CJGUI_LINUX_GPU_OK) return st;
    // 重建时优先沿用已选 format，避免 render pass / 管线跟着重建。
    if (previous != NULL && previous->format != VK_FORMAT_UNDEFINED) {
        uint32_t count = 0;
        if (vkGetPhysicalDeviceSurfaceFormatsKHR(gpu->physicalDevice, gpu->surface, &count, NULL) == VK_SUCCESS && count > 0u) {
            VkSurfaceFormatKHR *list = (VkSurfaceFormatKHR *)malloc(sizeof(VkSurfaceFormatKHR) * count);
            if (list != NULL) {
                if (vkGetPhysicalDeviceSurfaceFormatsKHR(gpu->physicalDevice, gpu->surface, &count, list) == VK_SUCCESS) {
                    for (uint32_t i = 0; i < count; ++i) {
                        if (list[i].format == previous->format && list[i].colorSpace == previous->colorSpace) {
                            format = list[i];
                            break;
                        }
                    }
                }
                free(list);
            }
        }
    }

    uint32_t modeCount = 0;
    if (vkGetPhysicalDeviceSurfacePresentModesKHR(gpu->physicalDevice, gpu->surface, &modeCount, NULL) != VK_SUCCESS) {
        fprintf(stderr, "cjgui_linux_vulkan: vkGetPhysicalDeviceSurfacePresentModesKHR(count) failed\n");
        return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
    }
    VkPresentModeKHR presentMode = VK_PRESENT_MODE_FIFO_KHR;
    if (modeCount > 0u) {
        VkPresentModeKHR *modes = (VkPresentModeKHR *)malloc(sizeof(VkPresentModeKHR) * modeCount);
        if (modes == NULL) {
            fprintf(stderr, "cjgui_linux_vulkan: out of memory reading present modes\n");
            return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
        }
        if (vkGetPhysicalDeviceSurfacePresentModesKHR(gpu->physicalDevice, gpu->surface, &modeCount, modes) == VK_SUCCESS) {
            presentMode = cjgui_vk_pick_present_mode(modes, modeCount);
        }
        free(modes);
    }

    // X11 下 currentExtent 有定义，必须采用；未定义（0xFFFFFFFF）时才按请求尺寸夹取。
    VkExtent2D extent;
    if (caps.currentExtent.width != 0xFFFFFFFFu) {
        extent = caps.currentExtent;
    } else {
        extent.width = cjgui_vk_clamp_u32(wantWidth, caps.minImageExtent.width, caps.maxImageExtent.width);
        extent.height = cjgui_vk_clamp_u32(wantHeight, caps.minImageExtent.height, caps.maxImageExtent.height);
    }
    if (extent.width == 0u || extent.height == 0u) {
        fprintf(stderr, "cjgui_linux_vulkan: surface extent is %ux%u (window not drawable yet)\n",
                extent.width, extent.height);
        return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
    }

    // render pass / 管线：format 不变则复用，跨重建存活。
    if (gpu->renderPass != VK_NULL_HANDLE && gpu->renderPassFormat != format.format) {
        if (gpu->pipeline != VK_NULL_HANDLE) {
            vkDestroyPipeline(gpu->device, gpu->pipeline, NULL);
            gpu->pipeline = VK_NULL_HANDLE;
        }
        vkDestroyRenderPass(gpu->device, gpu->renderPass, NULL);
        gpu->renderPass = VK_NULL_HANDLE;
    }
    if (gpu->renderPass == VK_NULL_HANDLE) {
        VkAttachmentDescription attachment;
        memset(&attachment, 0, sizeof attachment);
        attachment.format = format.format;
        attachment.samples = VK_SAMPLE_COUNT_1_BIT;
        attachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
        attachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        attachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        attachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        attachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        attachment.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

        VkAttachmentReference colorRef;
        memset(&colorRef, 0, sizeof colorRef);
        colorRef.attachment = 0;
        colorRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

        VkSubpassDescription subpass;
        memset(&subpass, 0, sizeof subpass);
        subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
        subpass.colorAttachmentCount = 1;
        subpass.pColorAttachments = &colorRef;

        VkRenderPassCreateInfo rpci;
        memset(&rpci, 0, sizeof rpci);
        rpci.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
        rpci.attachmentCount = 1;
        rpci.pAttachments = &attachment;
        rpci.subpassCount = 1;
        rpci.pSubpasses = &subpass;
        r = vkCreateRenderPass(gpu->device, &rpci, NULL, &gpu->renderPass);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateRenderPass", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);
        gpu->renderPassFormat = format.format;
    }

    uint32_t imageCount = caps.minImageCount + 1u;
    if (caps.maxImageCount > 0u && imageCount > caps.maxImageCount) imageCount = caps.maxImageCount;

    VkSwapchainCreateInfoKHR sci;
    memset(&sci, 0, sizeof sci);
    sci.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    sci.surface = gpu->surface;
    sci.minImageCount = imageCount;
    sci.imageFormat = format.format;
    sci.imageColorSpace = format.colorSpace;
    sci.imageExtent = extent;
    sci.imageArrayLayers = 1;
    sci.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    sci.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    sci.queueFamilyIndexCount = 0;
    sci.pQueueFamilyIndices = NULL;
    sci.preTransform = caps.currentTransform;
    sci.compositeAlpha = cjgui_vk_pick_composite_alpha(caps.supportedCompositeAlpha);
    sci.presentMode = presentMode;
    sci.clipped = VK_TRUE;
    sci.oldSwapchain = oldHandle;

    VkSwapchainKHR handle = VK_NULL_HANDLE;
    r = vkCreateSwapchainKHR(gpu->device, &sci, NULL, &handle);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateSwapchainKHR", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);

    uint32_t actualCount = 0;
    r = vkGetSwapchainImagesKHR(gpu->device, handle, &actualCount, NULL);
    if (r != VK_SUCCESS || actualCount == 0u) {
        if (r == VK_SUCCESS) r = VK_ERROR_INITIALIZATION_FAILED;
        vkDestroySwapchainKHR(gpu->device, handle, NULL);
        return cjgui_vk_fail("vkGetSwapchainImagesKHR(count)", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
    }

    VkImage *images = (VkImage *)calloc(actualCount, sizeof(VkImage));
    VkImageView *views = (VkImageView *)calloc(actualCount, sizeof(VkImageView));
    VkFramebuffer *framebuffers = (VkFramebuffer *)calloc(actualCount, sizeof(VkFramebuffer));
    VkSemaphore *renderFinished = (VkSemaphore *)calloc(actualCount, sizeof(VkSemaphore));
    if (images == NULL || views == NULL || framebuffers == NULL || renderFinished == NULL) {
        free(images); free(views); free(framebuffers); free(renderFinished);
        vkDestroySwapchainKHR(gpu->device, handle, NULL);
        fprintf(stderr, "cjgui_linux_vulkan: out of memory allocating swapchain arrays\n");
        return CJGUI_LINUX_GPU_SWAPCHAIN_FAILED;
    }

    r = vkGetSwapchainImagesKHR(gpu->device, handle, &actualCount, images);
    if (r != VK_SUCCESS) {
        free(images); free(views); free(framebuffers); free(renderFinished);
        vkDestroySwapchainKHR(gpu->device, handle, NULL);
        return cjgui_vk_fail("vkGetSwapchainImagesKHR(list)", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
    }

    for (uint32_t i = 0; i < actualCount; ++i) {
        VkImageViewCreateInfo vci;
        memset(&vci, 0, sizeof vci);
        vci.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        vci.image = images[i];
        vci.viewType = VK_IMAGE_VIEW_TYPE_2D;
        vci.format = format.format;
        vci.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
        vci.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
        vci.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
        vci.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
        vci.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        vci.subresourceRange.baseMipLevel = 0;
        vci.subresourceRange.levelCount = 1;
        vci.subresourceRange.baseArrayLayer = 0;
        vci.subresourceRange.layerCount = 1;
        r = vkCreateImageView(gpu->device, &vci, NULL, &views[i]);
        if (r != VK_SUCCESS) {
            out->handle = handle; out->imageCount = actualCount; out->images = images; out->views = views;
            out->framebuffers = framebuffers; out->renderFinished = renderFinished;
            cjgui_vk_swapchain_dispose(gpu, out);
            return cjgui_vk_fail("vkCreateImageView(swapchain)", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
        }

        VkFramebufferCreateInfo fci;
        memset(&fci, 0, sizeof fci);
        fci.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
        fci.renderPass = gpu->renderPass;
        fci.attachmentCount = 1;
        fci.pAttachments = &views[i];
        fci.width = extent.width;
        fci.height = extent.height;
        fci.layers = 1;
        r = vkCreateFramebuffer(gpu->device, &fci, NULL, &framebuffers[i]);
        if (r != VK_SUCCESS) {
            out->handle = handle; out->imageCount = actualCount; out->images = images; out->views = views;
            out->framebuffers = framebuffers; out->renderFinished = renderFinished;
            cjgui_vk_swapchain_dispose(gpu, out);
            return cjgui_vk_fail("vkCreateFramebuffer", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
        }

        VkSemaphoreCreateInfo semci;
        memset(&semci, 0, sizeof semci);
        semci.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
        r = vkCreateSemaphore(gpu->device, &semci, NULL, &renderFinished[i]);
        if (r != VK_SUCCESS) {
            out->handle = handle; out->imageCount = actualCount; out->images = images; out->views = views;
            out->framebuffers = framebuffers; out->renderFinished = renderFinished;
            cjgui_vk_swapchain_dispose(gpu, out);
            return cjgui_vk_fail("vkCreateSemaphore(renderFinished)", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
        }
    }

    out->handle = handle;
    out->format = format.format;
    out->colorSpace = format.colorSpace;
    out->presentMode = presentMode;
    out->extent = extent;
    out->imageCount = actualCount;
    out->images = images;
    out->views = views;
    out->framebuffers = framebuffers;
    out->renderFinished = renderFinished;
    return CJGUI_LINUX_GPU_OK;
}

// 等待全部在途帧，再提交一个空 command buffer 并等它返回：队列序上早于它的
// present 至此都已执行完，旧链不再被引用。不使用 vkDeviceWaitIdle。
static int cjgui_vk_drain_queue(CjguiLinuxGpu *gpu)
{
    for (uint32_t i = 0; i < CJGUI_VK_IN_FLIGHT; ++i) {
        CjguiVkFrame *f = &gpu->frames[i];
        if (!f->fencePending) continue;
        VkResult r = vkWaitForFences(gpu->device, 1, &f->fence, VK_TRUE, UINT64_MAX);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkWaitForFences(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
        r = vkResetFences(gpu->device, 1, &f->fence);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkResetFences(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
        f->fencePending = 0;
    }

    if (gpu->drainCmd == VK_NULL_HANDLE || gpu->drainFence == VK_NULL_HANDLE) {
        return CJGUI_LINUX_GPU_OK;
    }

    VkResult r = vkResetCommandBuffer(gpu->drainCmd, 0);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkResetCommandBuffer(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    VkCommandBufferBeginInfo bi;
    memset(&bi, 0, sizeof bi);
    bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    r = vkBeginCommandBuffer(gpu->drainCmd, &bi);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkBeginCommandBuffer(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    r = vkEndCommandBuffer(gpu->drainCmd);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkEndCommandBuffer(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkSubmitInfo si;
    memset(&si, 0, sizeof si);
    si.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    si.commandBufferCount = 1;
    si.pCommandBuffers = &gpu->drainCmd;

    r = vkResetFences(gpu->device, 1, &gpu->drainFence);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkResetFences(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    r = vkQueueSubmit(gpu->queue, 1, &si, gpu->drainFence);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkQueueSubmit(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    r = vkWaitForFences(gpu->device, 1, &gpu->drainFence, VK_TRUE, UINT64_MAX);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkWaitForFences(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_rebuild_swapchain(CjguiLinuxGpu *gpu, uint32_t wantWidth, uint32_t wantHeight)
{
    if (gpu->device == VK_NULL_HANDLE || gpu->surface == VK_NULL_HANDLE) {
        return CJGUI_LINUX_GPU_INVALID;
    }
    int st = cjgui_vk_drain_queue(gpu);
    if (st != CJGUI_LINUX_GPU_OK) {
        gpu->swapchainUsable = 0;
        return st;
    }

    CjguiVkSwapchain fresh;
    memset(&fresh, 0, sizeof fresh);
    VkSwapchainKHR oldHandle = gpu->swapchainUsable ? gpu->swapchain.handle : VK_NULL_HANDLE;
    st = cjgui_vk_swapchain_build(gpu, oldHandle, &gpu->swapchain, &fresh, wantWidth, wantHeight);
    if (st != CJGUI_LINUX_GPU_OK) {
        // 旧链已 retired：保留句柄（销毁时统一释放），但标记为不可用，允许再次重建。
        gpu->swapchainUsable = 0;
        return st;
    }

    // 新链（含 imageView / framebuffer / present 信号量）已建成，才销毁旧对象。
    cjgui_vk_swapchain_dispose(gpu, &gpu->swapchain);
    gpu->swapchain = fresh;
    gpu->swapchainUsable = 1;
    return CJGUI_LINUX_GPU_OK;
}

// ---------------------------------------------------------------------------
// 管线资源
// ---------------------------------------------------------------------------

static int cjgui_vk_create_descriptor_layout(CjguiLinuxGpu *gpu)
{
    VkDescriptorSetLayoutBinding binding;
    memset(&binding, 0, sizeof binding);
    binding.binding = 0;
    binding.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    binding.descriptorCount = 1;
    binding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
    binding.pImmutableSamplers = NULL;

    VkDescriptorSetLayoutCreateInfo ci;
    memset(&ci, 0, sizeof ci);
    ci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    ci.bindingCount = 1;
    ci.pBindings = &binding;
    VkResult r = vkCreateDescriptorSetLayout(gpu->device, &ci, NULL, &gpu->descriptorSetLayout);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateDescriptorSetLayout", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);

    VkPushConstantRange pushRange;
    memset(&pushRange, 0, sizeof pushRange);
    pushRange.stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT;
    pushRange.offset = 0;
    pushRange.size = CJGUI_VK_PUSH_BYTES;

    VkPipelineLayoutCreateInfo plci;
    memset(&plci, 0, sizeof plci);
    plci.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    plci.setLayoutCount = 1;
    plci.pSetLayouts = &gpu->descriptorSetLayout;
    plci.pushConstantRangeCount = 1;
    plci.pPushConstantRanges = &pushRange;
    r = vkCreatePipelineLayout(gpu->device, &plci, NULL, &gpu->pipelineLayout);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreatePipelineLayout", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_create_pipeline(CjguiLinuxGpu *gpu)
{
    if (gpu->renderPass == VK_NULL_HANDLE || gpu->pipelineLayout == VK_NULL_HANDLE) {
        return CJGUI_LINUX_GPU_PIPELINE_FAILED;
    }

    VkShaderModule vertModule = VK_NULL_HANDLE;
    VkShaderModule fragModule = VK_NULL_HANDLE;
    VkShaderModuleCreateInfo smci;
    memset(&smci, 0, sizeof smci);
    smci.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    smci.codeSize = sizeof(kVertexShaderSpirv);
    smci.pCode = kVertexShaderSpirv;
    VkResult r = vkCreateShaderModule(gpu->device, &smci, NULL, &vertModule);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateShaderModule(vertex)", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);
    smci.codeSize = sizeof(kFragmentShaderSpirv);
    smci.pCode = kFragmentShaderSpirv;
    r = vkCreateShaderModule(gpu->device, &smci, NULL, &fragModule);
    if (r != VK_SUCCESS) {
        vkDestroyShaderModule(gpu->device, vertModule, NULL);
        return cjgui_vk_fail("vkCreateShaderModule(fragment)", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);
    }

    VkPipelineShaderStageCreateInfo stages[2];
    memset(stages, 0, sizeof stages);
    stages[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stages[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
    stages[0].module = vertModule;
    stages[0].pName = "main";
    stages[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stages[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    stages[1].module = fragModule;
    stages[1].pName = "main";

    VkVertexInputBindingDescription binding;
    memset(&binding, 0, sizeof binding);
    binding.binding = 0;
    binding.stride = (uint32_t)sizeof(CjguiLinuxGpuVertex);
    binding.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    VkVertexInputAttributeDescription attrs[3];
    memset(attrs, 0, sizeof attrs);
    attrs[0].location = 0;
    attrs[0].binding = 0;
    attrs[0].format = VK_FORMAT_R32G32_SFLOAT;
    attrs[0].offset = (uint32_t)offsetof(CjguiLinuxGpuVertex, x);
    attrs[1].location = 1;
    attrs[1].binding = 0;
    attrs[1].format = VK_FORMAT_R32G32_SFLOAT;
    attrs[1].offset = (uint32_t)offsetof(CjguiLinuxGpuVertex, u);
    attrs[2].location = 2;
    attrs[2].binding = 0;
    attrs[2].format = VK_FORMAT_R32G32B32A32_SFLOAT;
    attrs[2].offset = (uint32_t)offsetof(CjguiLinuxGpuVertex, r);

    VkPipelineVertexInputStateCreateInfo vertexInput;
    memset(&vertexInput, 0, sizeof vertexInput);
    vertexInput.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    vertexInput.vertexBindingDescriptionCount = 1;
    vertexInput.pVertexBindingDescriptions = &binding;
    vertexInput.vertexAttributeDescriptionCount = 3;
    vertexInput.pVertexAttributeDescriptions = attrs;

    VkPipelineInputAssemblyStateCreateInfo inputAssembly;
    memset(&inputAssembly, 0, sizeof inputAssembly);
    inputAssembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    inputAssembly.primitiveRestartEnable = VK_FALSE;

    // viewport/scissor 走 dynamic state：交换链尺寸变化不需要新管线。
    VkPipelineViewportStateCreateInfo viewportState;
    memset(&viewportState, 0, sizeof viewportState);
    viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    viewportState.viewportCount = 1;
    viewportState.scissorCount = 1;

    VkPipelineRasterizationStateCreateInfo raster;
    memset(&raster, 0, sizeof raster);
    raster.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    raster.depthClampEnable = VK_FALSE;
    raster.rasterizerDiscardEnable = VK_FALSE;
    raster.polygonMode = VK_POLYGON_MODE_FILL;
    raster.cullMode = VK_CULL_MODE_NONE;
    raster.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    raster.depthBiasEnable = VK_FALSE;
    raster.lineWidth = 1.0f;

    VkPipelineMultisampleStateCreateInfo multisample;
    memset(&multisample, 0, sizeof multisample);
    multisample.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    multisample.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
    multisample.sampleShadingEnable = VK_FALSE;

    // 标准 source-over：文字图集是"白色 + alpha 覆盖率"，必须混合。
    VkPipelineColorBlendAttachmentState blendAttachment;
    memset(&blendAttachment, 0, sizeof blendAttachment);
    blendAttachment.blendEnable = VK_TRUE;
    blendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
    blendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    blendAttachment.colorBlendOp = VK_BLEND_OP_ADD;
    blendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
    blendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    blendAttachment.alphaBlendOp = VK_BLEND_OP_ADD;
    blendAttachment.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT |
                                     VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;

    VkPipelineColorBlendStateCreateInfo blend;
    memset(&blend, 0, sizeof blend);
    blend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    blend.logicOpEnable = VK_FALSE;
    blend.attachmentCount = 1;
    blend.pAttachments = &blendAttachment;

    VkDynamicState dynamicStates[2] = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
    VkPipelineDynamicStateCreateInfo dynamic;
    memset(&dynamic, 0, sizeof dynamic);
    dynamic.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    dynamic.dynamicStateCount = 2;
    dynamic.pDynamicStates = dynamicStates;

    VkGraphicsPipelineCreateInfo gpci;
    memset(&gpci, 0, sizeof gpci);
    gpci.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    gpci.stageCount = 2;
    gpci.pStages = stages;
    gpci.pVertexInputState = &vertexInput;
    gpci.pInputAssemblyState = &inputAssembly;
    gpci.pViewportState = &viewportState;
    gpci.pRasterizationState = &raster;
    gpci.pMultisampleState = &multisample;
    gpci.pDepthStencilState = NULL;
    gpci.pColorBlendState = &blend;
    gpci.pDynamicState = &dynamic;
    gpci.layout = gpu->pipelineLayout;
    gpci.renderPass = gpu->renderPass;
    gpci.subpass = 0;

    VkPipeline pipeline = VK_NULL_HANDLE;
    r = vkCreateGraphicsPipelines(gpu->device, VK_NULL_HANDLE, 1, &gpci, NULL, &pipeline);
    vkDestroyShaderModule(gpu->device, vertModule, NULL);
    vkDestroyShaderModule(gpu->device, fragModule, NULL);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateGraphicsPipelines", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);

    gpu->pipeline = pipeline;
    gpu->pipelineFormatValid = 1;
    return CJGUI_LINUX_GPU_OK;
}

// ---------------------------------------------------------------------------
// 图集
// ---------------------------------------------------------------------------

static int cjgui_vk_create_atlas(CjguiLinuxGpu *gpu)
{
    VkImageCreateInfo ici;
    memset(&ici, 0, sizeof ici);
    ici.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    ici.imageType = VK_IMAGE_TYPE_2D;
    ici.format = VK_FORMAT_R8G8B8A8_UNORM;
    ici.extent.width = CJGUI_LINUX_ATLAS_SIDE;
    ici.extent.height = CJGUI_LINUX_ATLAS_SIDE;
    ici.extent.depth = 1;
    ici.mipLevels = 1;
    ici.arrayLayers = 1;
    ici.samples = VK_SAMPLE_COUNT_1_BIT;
    ici.tiling = VK_IMAGE_TILING_OPTIMAL;
    ici.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
    ici.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    ici.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    VkResult r = vkCreateImage(gpu->device, &ici, NULL, &gpu->atlasImage);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateImage(atlas)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    gpu->atlasLayout = VK_IMAGE_LAYOUT_UNDEFINED;

    VkMemoryRequirements req;
    vkGetImageMemoryRequirements(gpu->device, gpu->atlasImage, &req);
    uint32_t typeIndex = 0;
    if (cjgui_vk_find_memory_type(gpu, req.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, 0u, &typeIndex) != 0) {
        if (cjgui_vk_find_memory_type(gpu, req.memoryTypeBits, 0u, 0u, &typeIndex) != 0) {
            return CJGUI_LINUX_GPU_DEVICE_FAILED;
        }
    }
    VkMemoryAllocateInfo mai;
    memset(&mai, 0, sizeof mai);
    mai.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    mai.allocationSize = req.size;
    mai.memoryTypeIndex = typeIndex;
    r = vkAllocateMemory(gpu->device, &mai, NULL, &gpu->atlasMemory);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkAllocateMemory(atlas)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    r = vkBindImageMemory(gpu->device, gpu->atlasImage, gpu->atlasMemory, 0);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkBindImageMemory(atlas)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkImageViewCreateInfo vci;
    memset(&vci, 0, sizeof vci);
    vci.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    vci.image = gpu->atlasImage;
    vci.viewType = VK_IMAGE_VIEW_TYPE_2D;
    vci.format = VK_FORMAT_R8G8B8A8_UNORM;
    vci.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    vci.subresourceRange.levelCount = 1;
    vci.subresourceRange.layerCount = 1;
    r = vkCreateImageView(gpu->device, &vci, NULL, &gpu->atlasView);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateImageView(atlas)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkSamplerCreateInfo sci;
    memset(&sci, 0, sizeof sci);
    sci.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
    sci.magFilter = VK_FILTER_LINEAR;
    sci.minFilter = VK_FILTER_LINEAR;
    sci.mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST;
    sci.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    sci.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    sci.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
    sci.mipLodBias = 0.0f;
    sci.anisotropyEnable = VK_FALSE;
    sci.compareEnable = VK_FALSE;
    sci.minLod = 0.0f;
    sci.maxLod = 0.0f;
    sci.borderColor = VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
    sci.unnormalizedCoordinates = VK_FALSE;
    r = vkCreateSampler(gpu->device, &sci, NULL, &gpu->sampler);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateSampler", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    return CJGUI_LINUX_GPU_OK;
}

// 上传一段 RGBA 到图集。内部给 upload slot 用，也可被 upload 2x2 白纹素调用。
static int cjgui_vk_atlas_upload(CjguiLinuxGpu *gpu, int x, int y, int width, int height,
                                 const uint8_t *rgba);

// ---------------------------------------------------------------------------
// 顶点缓冲
// ---------------------------------------------------------------------------

static int cjgui_vk_ensure_vertex_capacity(CjguiLinuxGpu *gpu, CjguiVkFrame *f, VkDeviceSize needBytes)
{
    if (f->vertexBuffer != VK_NULL_HANDLE && f->vertexBytes >= needBytes) return CJGUI_LINUX_GPU_OK;

    VkDeviceSize want = f->vertexBytes > 0 ? f->vertexBytes : CJGUI_VK_VERTEX_MIN_BYTES;
    while (want < needBytes) want *= 2u;

    cjgui_vk_destroy_mapped_buffer(gpu, &f->vertexBuffer, &f->vertexMemory, &f->vertexMapped);
    f->vertexBytes = 0;
    int st = cjgui_vk_create_mapped_buffer(gpu, want, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, "vkCreateBuffer(vertex)",
                                           &f->vertexBuffer, &f->vertexMemory, &f->vertexMapped,
                                           &f->vertexCoherent);
    if (st != CJGUI_LINUX_GPU_OK) return st;
    f->vertexBytes = want;
    return CJGUI_LINUX_GPU_OK;
}

// ---------------------------------------------------------------------------
// create / destroy
// ---------------------------------------------------------------------------

static int cjgui_vk_create_instance(CjguiLinuxGpu *gpu, int useXcb)
{
    uint32_t extCount = 0;
    VkResult r = vkEnumerateInstanceExtensionProperties(NULL, &extCount, NULL);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkEnumerateInstanceExtensionProperties(count)", r, CJGUI_LINUX_GPU_INSTANCE_FAILED);
    VkExtensionProperties *exts = NULL;
    if (extCount > 0u) {
        exts = (VkExtensionProperties *)malloc(sizeof(VkExtensionProperties) * extCount);
        if (exts == NULL) {
            fprintf(stderr, "cjgui_linux_vulkan: out of memory reading instance extensions\n");
            return CJGUI_LINUX_GPU_INSTANCE_FAILED;
        }
        r = vkEnumerateInstanceExtensionProperties(NULL, &extCount, exts);
        if (r != VK_SUCCESS) {
            free(exts);
            return cjgui_vk_fail("vkEnumerateInstanceExtensionProperties(list)", r, CJGUI_LINUX_GPU_INSTANCE_FAILED);
        }
    }

    int haveSurface = 0;
    int haveXcb = 0;
    int haveXlib = 0;
    for (uint32_t i = 0; i < extCount; ++i) {
        if (strcmp(exts[i].extensionName, VK_KHR_SURFACE_EXTENSION_NAME) == 0) haveSurface = 1;
        if (strcmp(exts[i].extensionName, VK_KHR_XCB_SURFACE_EXTENSION_NAME) == 0) haveXcb = 1;
        if (strcmp(exts[i].extensionName, VK_KHR_XLIB_SURFACE_EXTENSION_NAME) == 0) haveXlib = 1;
    }
    free(exts);

    if (!haveSurface) {
        fprintf(stderr, "cjgui_linux_vulkan: VK_KHR_surface is not available\n");
        return CJGUI_LINUX_GPU_INSTANCE_FAILED;
    }
    if (useXcb && !haveXcb) {
        fprintf(stderr, "cjgui_linux_vulkan: VK_KHR_xcb_surface is not available (window connection given)\n");
        return CJGUI_LINUX_GPU_INSTANCE_FAILED;
    }
    if (!useXcb && !haveXlib) {
        fprintf(stderr, "cjgui_linux_vulkan: VK_KHR_xlib_surface is not available\n");
        return CJGUI_LINUX_GPU_INSTANCE_FAILED;
    }

    const char *extensions[2];
    extensions[0] = VK_KHR_SURFACE_EXTENSION_NAME;
    extensions[1] = useXcb ? VK_KHR_XCB_SURFACE_EXTENSION_NAME : VK_KHR_XLIB_SURFACE_EXTENSION_NAME;

    VkApplicationInfo app;
    memset(&app, 0, sizeof app);
    app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app.pApplicationName = "cjgui-linux";
    app.applicationVersion = VK_MAKE_VERSION(0, 1, 0);
    app.pEngineName = "cjgui";
    app.engineVersion = VK_MAKE_VERSION(0, 1, 0);
    // 1.0 即可：VK_KHR_swapchain 作为设备扩展显式启用，兼容面最大。
    app.apiVersion = VK_API_VERSION_1_0;

    VkInstanceCreateInfo ci;
    memset(&ci, 0, sizeof ci);
    ci.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ci.pApplicationInfo = &app;
    ci.enabledExtensionCount = 2;
    ci.ppEnabledExtensionNames = extensions;
    ci.enabledLayerCount = 0;
    ci.ppEnabledLayerNames = NULL;

    r = vkCreateInstance(&ci, NULL, &gpu->instance);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateInstance", r, CJGUI_LINUX_GPU_INSTANCE_FAILED);
    gpu->surfaceKind = useXcb ? "xcb" : "xlib";
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_create_surface(CjguiLinuxGpu *gpu, void *display, unsigned long windowId, void *connection)
{
    if (strcmp(gpu->surfaceKind, "xcb") == 0) {
        PFN_vkCreateXcbSurfaceKHR create = (PFN_vkCreateXcbSurfaceKHR)vkGetInstanceProcAddr(gpu->instance, "vkCreateXcbSurfaceKHR");
        if (create == NULL) {
            fprintf(stderr, "cjgui_linux_vulkan: vkGetInstanceProcAddr(vkCreateXcbSurfaceKHR) failed\n");
            return CJGUI_LINUX_GPU_SURFACE_FAILED;
        }
        VkXcbSurfaceCreateInfoKHR ci;
        memset(&ci, 0, sizeof ci);
        ci.sType = VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
        ci.connection = (xcb_connection_t *)connection;
        ci.window = (xcb_window_t)windowId;
        VkResult r = create(gpu->instance, &ci, NULL, &gpu->surface);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateXcbSurfaceKHR", r, CJGUI_LINUX_GPU_SURFACE_FAILED);
        return CJGUI_LINUX_GPU_OK;
    }

    PFN_vkCreateXlibSurfaceKHR create = (PFN_vkCreateXlibSurfaceKHR)vkGetInstanceProcAddr(gpu->instance, "vkCreateXlibSurfaceKHR");
    if (create == NULL) {
        fprintf(stderr, "cjgui_linux_vulkan: vkGetInstanceProcAddr(vkCreateXlibSurfaceKHR) failed\n");
        return CJGUI_LINUX_GPU_SURFACE_FAILED;
    }
    VkXlibSurfaceCreateInfoKHR ci;
    memset(&ci, 0, sizeof ci);
    ci.sType = VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR;
    ci.dpy = (Display *)display;
    ci.window = (Window)windowId;
    VkResult r = create(gpu->instance, &ci, NULL, &gpu->surface);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateXlibSurfaceKHR", r, CJGUI_LINUX_GPU_SURFACE_FAILED);
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_device_score(VkPhysicalDeviceType type)
{
    switch (type) {
        case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: return 1000;
        case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: return 800;
        case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU: return 600;
        case VK_PHYSICAL_DEVICE_TYPE_OTHER: return 400;
        case VK_PHYSICAL_DEVICE_TYPE_CPU: return 200;
        default: return 100;
    }
}

static int cjgui_vk_pick_physical_device(CjguiLinuxGpu *gpu)
{
    uint32_t count = 0;
    VkResult r = vkEnumeratePhysicalDevices(gpu->instance, &count, NULL);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkEnumeratePhysicalDevices(count)", r, CJGUI_LINUX_GPU_NO_DEVICE);
    if (count == 0u) {
        fprintf(stderr, "cjgui_linux_vulkan: no Vulkan physical device\n");
        return CJGUI_LINUX_GPU_NO_DEVICE;
    }
    VkPhysicalDevice *devices = (VkPhysicalDevice *)malloc(sizeof(VkPhysicalDevice) * count);
    if (devices == NULL) {
        fprintf(stderr, "cjgui_linux_vulkan: out of memory enumerating devices\n");
        return CJGUI_LINUX_GPU_NO_DEVICE;
    }
    r = vkEnumeratePhysicalDevices(gpu->instance, &count, devices);
    if (r != VK_SUCCESS) {
        free(devices);
        return cjgui_vk_fail("vkEnumeratePhysicalDevices(list)", r, CJGUI_LINUX_GPU_NO_DEVICE);
    }

    VkPhysicalDevice best = VK_NULL_HANDLE;
    int bestScore = -1;
    uint32_t bestQueue = 0;

    for (uint32_t i = 0; i < count; ++i) {
        uint32_t extCount = 0;
        if (vkEnumerateDeviceExtensionProperties(devices[i], NULL, &extCount, NULL) != VK_SUCCESS || extCount == 0u) continue;
        VkExtensionProperties *exts = (VkExtensionProperties *)malloc(sizeof(VkExtensionProperties) * extCount);
        if (exts == NULL) continue;
        int hasSwapchain = 0;
        if (vkEnumerateDeviceExtensionProperties(devices[i], NULL, &extCount, exts) == VK_SUCCESS) {
            for (uint32_t k = 0; k < extCount; ++k) {
                if (strcmp(exts[k].extensionName, VK_KHR_SWAPCHAIN_EXTENSION_NAME) == 0) {
                    hasSwapchain = 1;
                    break;
                }
            }
        }
        free(exts);
        if (!hasSwapchain) continue;

        uint32_t queueCount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(devices[i], &queueCount, NULL);
        if (queueCount == 0u) continue;
        if (queueCount > 64u) queueCount = 64u;
        VkQueueFamilyProperties families[64];
        vkGetPhysicalDeviceQueueFamilyProperties(devices[i], &queueCount, families);

        int queueIndex = -1;
        for (uint32_t q = 0; q < queueCount; ++q) {
            if ((families[q].queueFlags & VK_QUEUE_GRAPHICS_BIT) == 0u) continue;
            if (families[q].queueCount == 0u) continue;
            VkBool32 supported = VK_FALSE;
            VkResult sr = vkGetPhysicalDeviceSurfaceSupportKHR(devices[i], q, gpu->surface, &supported);
            if (sr == VK_SUCCESS && supported == VK_TRUE) {
                queueIndex = (int)q;
                break;
            }
        }
        if (queueIndex < 0) continue;

        // 交换链可用性：format 与 present mode 至少各有一个。
        uint32_t formatCount = 0;
        VkResult fr = vkGetPhysicalDeviceSurfaceFormatsKHR(devices[i], gpu->surface, &formatCount, NULL);
        if (fr != VK_SUCCESS || formatCount == 0u) continue;
        uint32_t modeCount = 0;
        VkResult mr = vkGetPhysicalDeviceSurfacePresentModesKHR(devices[i], gpu->surface, &modeCount, NULL);
        if (mr != VK_SUCCESS || modeCount == 0u) continue;

        VkPhysicalDeviceProperties props;
        vkGetPhysicalDeviceProperties(devices[i], &props);
        int score = cjgui_vk_device_score(props.deviceType);
        if (score > bestScore) {
            bestScore = score;
            best = devices[i];
            bestQueue = (uint32_t)queueIndex;
        }
    }
    free(devices);

    if (best == VK_NULL_HANDLE) {
        fprintf(stderr, "cjgui_linux_vulkan: no device supports a presentable swapchain on this surface\n");
        return CJGUI_LINUX_GPU_NO_DEVICE;
    }
    gpu->physicalDevice = best;
    gpu->queueFamily = bestQueue;
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_create_device(CjguiLinuxGpu *gpu)
{
    float priority = 1.0f;
    VkDeviceQueueCreateInfo qci;
    memset(&qci, 0, sizeof qci);
    qci.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    qci.queueFamilyIndex = gpu->queueFamily;
    qci.queueCount = 1;
    qci.pQueuePriorities = &priority;

    const char *deviceExtensions[1] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };
    VkDeviceCreateInfo ci;
    memset(&ci, 0, sizeof ci);
    ci.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    ci.queueCreateInfoCount = 1;
    ci.pQueueCreateInfos = &qci;
    ci.enabledExtensionCount = 1;
    ci.ppEnabledExtensionNames = deviceExtensions;
    ci.pEnabledFeatures = NULL;

    VkResult r = vkCreateDevice(gpu->physicalDevice, &ci, NULL, &gpu->device);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateDevice", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    vkGetDeviceQueue(gpu->device, gpu->queueFamily, 0, &gpu->queue);
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_create_frame_resources(CjguiLinuxGpu *gpu)
{
    VkCommandPoolCreateInfo pci;
    memset(&pci, 0, sizeof pci);
    pci.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pci.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    pci.queueFamilyIndex = gpu->queueFamily;
    VkResult r = vkCreateCommandPool(gpu->device, &pci, NULL, &gpu->commandPool);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateCommandPool", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    if (cjgui_vk_alloc_command_buffer(gpu, &gpu->drainCmd) != CJGUI_LINUX_GPU_OK) return CJGUI_LINUX_GPU_DEVICE_FAILED;
    VkFenceCreateInfo fci;
    memset(&fci, 0, sizeof fci);
    fci.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    r = vkCreateFence(gpu->device, &fci, NULL, &gpu->drainFence);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateFence(drain)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    for (uint32_t i = 0; i < CJGUI_VK_IN_FLIGHT; ++i) {
        CjguiVkFrame *f = &gpu->frames[i];
        if (cjgui_vk_alloc_command_buffer(gpu, &f->cmd) != CJGUI_LINUX_GPU_OK) return CJGUI_LINUX_GPU_DEVICE_FAILED;
        // fence 创建为已触发态：第一次 begin_frame 不必区分"从未提交"。
        VkFenceCreateInfo efci;
        memset(&efci, 0, sizeof efci);
        efci.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
        efci.flags = VK_FENCE_CREATE_SIGNALED_BIT;
        r = vkCreateFence(gpu->device, &efci, NULL, &f->fence);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateFence(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
        f->fencePending = 0;

        VkSemaphoreCreateInfo sci;
        memset(&sci, 0, sizeof sci);
        sci.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
        r = vkCreateSemaphore(gpu->device, &sci, NULL, &f->imageAvailable);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateSemaphore(imageAvailable)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }

    for (uint32_t i = 0; i < CJGUI_VK_UPLOAD_SLOTS; ++i) {
        CjguiVkUpload *u = &gpu->uploads[i];
        if (cjgui_vk_alloc_command_buffer(gpu, &u->cmd) != CJGUI_LINUX_GPU_OK) return CJGUI_LINUX_GPU_DEVICE_FAILED;
        VkFenceCreateInfo efci;
        memset(&efci, 0, sizeof efci);
        efci.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
        efci.flags = VK_FENCE_CREATE_SIGNALED_BIT;
        r = vkCreateFence(gpu->device, &efci, NULL, &u->fence);
        if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateFence(upload)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
        u->fencePending = 0;

        VkDeviceSize bytes = (VkDeviceSize)CJGUI_LINUX_ATLAS_SIDE * CJGUI_LINUX_ATLAS_SIDE * 4u;
        int st = cjgui_vk_create_mapped_buffer(gpu, bytes, VK_BUFFER_USAGE_TRANSFER_SRC_BIT, "vkCreateBuffer(staging)",
                                               &u->staging, &u->stagingMemory, &u->mapped, &u->coherent);
        if (st != CJGUI_LINUX_GPU_OK) return st;
        u->bytes = bytes;
    }
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_create_descriptor_sets(CjguiLinuxGpu *gpu)
{
    VkDescriptorPoolSize size;
    memset(&size, 0, sizeof size);
    size.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    size.descriptorCount = CJGUI_VK_IN_FLIGHT;

    VkDescriptorPoolCreateInfo pci;
    memset(&pci, 0, sizeof pci);
    pci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    pci.maxSets = CJGUI_VK_IN_FLIGHT;
    pci.poolSizeCount = 1;
    pci.pPoolSizes = &size;
    VkResult r = vkCreateDescriptorPool(gpu->device, &pci, NULL, &gpu->descriptorPool);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkCreateDescriptorPool", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);

    VkDescriptorSetLayout layouts[CJGUI_VK_IN_FLIGHT];
    for (uint32_t i = 0; i < CJGUI_VK_IN_FLIGHT; ++i) layouts[i] = gpu->descriptorSetLayout;

    VkDescriptorSetAllocateInfo ai;
    memset(&ai, 0, sizeof ai);
    ai.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    ai.descriptorPool = gpu->descriptorPool;
    ai.descriptorSetCount = CJGUI_VK_IN_FLIGHT;
    ai.pSetLayouts = layouts;
    r = vkAllocateDescriptorSets(gpu->device, &ai, gpu->descriptorSets);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkAllocateDescriptorSets", r, CJGUI_LINUX_GPU_PIPELINE_FAILED);

    for (uint32_t i = 0; i < CJGUI_VK_IN_FLIGHT; ++i) {
        VkDescriptorImageInfo image;
        memset(&image, 0, sizeof image);
        image.sampler = gpu->sampler;
        image.imageView = gpu->atlasView;
        image.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;

        VkWriteDescriptorSet write;
        memset(&write, 0, sizeof write);
        write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
        write.dstSet = gpu->descriptorSets[i];
        write.dstBinding = 0;
        write.dstArrayElement = 0;
        write.descriptorCount = 1;
        write.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
        write.pImageInfo = &image;
        vkUpdateDescriptorSets(gpu->device, 1, &write, 0, NULL);
    }
    return CJGUI_LINUX_GPU_OK;
}

// 销毁已经建立的全部对象。可安全用于半成品（调用方保证 device 可能为 NULL）。
static void cjgui_vk_teardown(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return;

    if (gpu->device != VK_NULL_HANDLE) {
        // 契约：vkDeviceWaitIdle 只在销毁序列里调用一次。
        VkResult r = vkDeviceWaitIdle(gpu->device);
        if (r != VK_SUCCESS) cjgui_vk_fail("vkDeviceWaitIdle", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }

    if (gpu->device != VK_NULL_HANDLE) {
        cjgui_vk_swapchain_dispose(gpu, &gpu->swapchain);

        for (uint32_t i = 0; i < CJGUI_VK_IN_FLIGHT; ++i) {
            CjguiVkFrame *f = &gpu->frames[i];
            cjgui_vk_destroy_mapped_buffer(gpu, &f->vertexBuffer, &f->vertexMemory, &f->vertexMapped);
            if (f->imageAvailable != VK_NULL_HANDLE) vkDestroySemaphore(gpu->device, f->imageAvailable, NULL);
            if (f->fence != VK_NULL_HANDLE) vkDestroyFence(gpu->device, f->fence, NULL);
            free(f->cpuVerts);
            free(f->draws);
        }
        for (uint32_t i = 0; i < CJGUI_VK_UPLOAD_SLOTS; ++i) {
            CjguiVkUpload *u = &gpu->uploads[i];
            cjgui_vk_destroy_mapped_buffer(gpu, &u->staging, &u->stagingMemory, &u->mapped);
            if (u->fence != VK_NULL_HANDLE) vkDestroyFence(gpu->device, u->fence, NULL);
        }
        if (gpu->drainFence != VK_NULL_HANDLE) vkDestroyFence(gpu->device, gpu->drainFence, NULL);
        if (gpu->pipeline != VK_NULL_HANDLE) vkDestroyPipeline(gpu->device, gpu->pipeline, NULL);
        if (gpu->pipelineLayout != VK_NULL_HANDLE) vkDestroyPipelineLayout(gpu->device, gpu->pipelineLayout, NULL);
        if (gpu->descriptorPool != VK_NULL_HANDLE) vkDestroyDescriptorPool(gpu->device, gpu->descriptorPool, NULL);
        if (gpu->descriptorSetLayout != VK_NULL_HANDLE) vkDestroyDescriptorSetLayout(gpu->device, gpu->descriptorSetLayout, NULL);
        if (gpu->sampler != VK_NULL_HANDLE) vkDestroySampler(gpu->device, gpu->sampler, NULL);
        if (gpu->atlasView != VK_NULL_HANDLE) vkDestroyImageView(gpu->device, gpu->atlasView, NULL);
        if (gpu->atlasImage != VK_NULL_HANDLE) vkDestroyImage(gpu->device, gpu->atlasImage, NULL);
        if (gpu->atlasMemory != VK_NULL_HANDLE) vkFreeMemory(gpu->device, gpu->atlasMemory, NULL);
        if (gpu->renderPass != VK_NULL_HANDLE) vkDestroyRenderPass(gpu->device, gpu->renderPass, NULL);
        if (gpu->commandPool != VK_NULL_HANDLE) vkDestroyCommandPool(gpu->device, gpu->commandPool, NULL);
        vkDestroyDevice(gpu->device, NULL);
        gpu->device = VK_NULL_HANDLE;
    }
    if (gpu->surface != VK_NULL_HANDLE && gpu->instance != VK_NULL_HANDLE) {
        vkDestroySurfaceKHR(gpu->instance, gpu->surface, NULL);
        gpu->surface = VK_NULL_HANDLE;
    }
    if (gpu->instance != VK_NULL_HANDLE) {
        vkDestroyInstance(gpu->instance, NULL);
        gpu->instance = VK_NULL_HANDLE;
    }
}

CjguiLinuxGpu *cjgui_linux_gpu_create(CjguiLinuxWindow *window, int *outStatus)
{
    if (outStatus != NULL) *outStatus = CJGUI_LINUX_GPU_INVALID;
    if (window == NULL) {
        fprintf(stderr, "cjgui_linux_vulkan: create called without a window\n");
        return NULL;
    }

    CjguiLinuxGpu *gpu = (CjguiLinuxGpu *)calloc(1, sizeof(CjguiLinuxGpu));
    if (gpu == NULL) {
        fprintf(stderr, "cjgui_linux_vulkan: out of memory allocating backend state\n");
        if (outStatus != NULL) *outStatus = CJGUI_LINUX_GPU_INVALID;
        return NULL;
    }
    gpu->window = window;
    gpu->windowScale = 1.0;

    void *display = NULL;
    void *connection = NULL;
    unsigned long windowId = 0;
    int screen = 0;
    int nativeStatus = cjgui_linux_window_native(window, &display, &windowId, &screen, &connection);
    if (nativeStatus != 0 || display == NULL || windowId == 0ul) {
        fprintf(stderr, "cjgui_linux_vulkan: cjgui_linux_window_native failed (status=%d)\n", nativeStatus);
        if (outStatus != NULL) *outStatus = CJGUI_LINUX_GPU_SURFACE_FAILED;
        free(gpu);
        return NULL;
    }

    // 优先 xcb（窗口模块给了连接句柄就用它），否则退回 xlib——两者都只需要
    // Display*/XID，扩展缺失时自动降级，不做静默失败。
    int useXcb = connection != NULL;
    (void)screen;

    int status = cjgui_vk_create_instance(gpu, useXcb);
    if (status != CJGUI_LINUX_GPU_OK && useXcb) {
        cjgui_vk_note("surface", "xcb connection present but VK_KHR_xcb_surface unavailable; falling back to xlib");
        cjgui_vk_teardown(gpu);
        memset(&gpu->swapchain, 0, sizeof gpu->swapchain);
        status = cjgui_vk_create_instance(gpu, 0);
    }
    if (status != CJGUI_LINUX_GPU_OK) {
        cjgui_vk_teardown(gpu);
        free(gpu);
        if (outStatus != NULL) *outStatus = status;
        return NULL;
    }

    status = cjgui_vk_create_surface(gpu, display, windowId, connection);
    if (status != CJGUI_LINUX_GPU_OK) {
        cjgui_vk_teardown(gpu);
        free(gpu);
        if (outStatus != NULL) *outStatus = status;
        return NULL;
    }

    status = cjgui_vk_pick_physical_device(gpu);
    if (status != CJGUI_LINUX_GPU_OK) {
        cjgui_vk_teardown(gpu);
        free(gpu);
        if (outStatus != NULL) *outStatus = status;
        return NULL;
    }
    status = cjgui_vk_create_device(gpu);
    if (status != CJGUI_LINUX_GPU_OK) {
        cjgui_vk_teardown(gpu);
        free(gpu);
        if (outStatus != NULL) *outStatus = status;
        return NULL;
    }

    // 逻辑尺寸 / 缩放：窗口模块是唯一权威。
    uint32_t logicalWidth = 0;
    uint32_t logicalHeight = 0;
    int resized = 0;
    if (cjgui_linux_window_size(window, &logicalWidth, &logicalHeight, &resized) != 0 || logicalWidth == 0u ||
        logicalHeight == 0u) {
        logicalWidth = 1u;
        logicalHeight = 1u;
    }
    double scale = cjgui_linux_window_scale(window);
    gpu->windowScale = scale > 0.0 ? scale : 1.0;
    gpu->logicalWidth = logicalWidth;
    gpu->logicalHeight = logicalHeight;

    status = cjgui_vk_create_frame_resources(gpu);
    if (status != CJGUI_LINUX_GPU_OK) goto fail;
    status = cjgui_vk_create_atlas(gpu);
    if (status != CJGUI_LINUX_GPU_OK) goto fail;
    status = cjgui_vk_create_descriptor_layout(gpu);
    if (status != CJGUI_LINUX_GPU_OK) goto fail;
    status = cjgui_vk_create_descriptor_sets(gpu);
    if (status != CJGUI_LINUX_GPU_OK) goto fail;

    {
        uint32_t wantWidth = (uint32_t)((double)gpu->logicalWidth * gpu->windowScale);
        uint32_t wantHeight = (uint32_t)((double)gpu->logicalHeight * gpu->windowScale);
        status = cjgui_vk_rebuild_swapchain(gpu, wantWidth, wantHeight);
        if (status != CJGUI_LINUX_GPU_OK) goto fail;
    }

    status = cjgui_vk_create_pipeline(gpu);
    if (status != CJGUI_LINUX_GPU_OK) goto fail;

    // 图集初始化：清零 + 写左上角保留的 2x2 白色纹素（实心几何依赖它）。
    {
        uint32_t side = CJGUI_LINUX_ATLAS_SIDE;
        uint8_t *blank = (uint8_t *)calloc((size_t)side * side * 4u, 1u);
        if (blank == NULL) {
            fprintf(stderr, "cjgui_linux_vulkan: out of memory initializing atlas\n");
            status = CJGUI_LINUX_GPU_DEVICE_FAILED;
            goto fail;
        }
        status = cjgui_vk_atlas_upload(gpu, 0, 0, (int)side, (int)side, blank);
        free(blank);
        if (status != CJGUI_LINUX_GPU_OK) goto fail;

        uint8_t white[CJGUI_VK_WHITE_TEXEL_SIDE * CJGUI_VK_WHITE_TEXEL_SIDE * 4];
        for (size_t i = 0; i < sizeof white; ++i) white[i] = 0xFFu;
        status = cjgui_vk_atlas_upload(gpu, 0, 0, CJGUI_VK_WHITE_TEXEL_SIDE, CJGUI_VK_WHITE_TEXEL_SIDE, white);
        if (status != CJGUI_LINUX_GPU_OK) goto fail;
    }

    {
        VkPhysicalDeviceProperties props;
        vkGetPhysicalDeviceProperties(gpu->physicalDevice, &props);
        fprintf(stderr,
                "cjgui_linux_vulkan: device=\"%s\" type=%d api=%u.%u.%u surface=%s format=%d(%s) present=%s(%d) "
                "extent=%ux%u images=%u inFlight=%u logical=%ux%u scale=%.2f\n",
                props.deviceName, (int)props.deviceType, VK_VERSION_MAJOR(props.apiVersion),
                VK_VERSION_MINOR(props.apiVersion), VK_VERSION_PATCH(props.apiVersion), gpu->surfaceKind,
                (int)gpu->swapchain.format,
                gpu->swapchain.format == VK_FORMAT_B8G8R8A8_UNORM ? "B8G8R8A8_UNORM" :
                gpu->swapchain.format == VK_FORMAT_B8G8R8A8_SRGB ? "B8G8R8A8_SRGB" :
                gpu->swapchain.format == VK_FORMAT_R8G8B8A8_UNORM ? "R8G8B8A8_UNORM" :
                gpu->swapchain.format == VK_FORMAT_R8G8B8A8_SRGB ? "R8G8B8A8_SRGB" : "other",
                cjgui_vk_present_mode_name(gpu->swapchain.presentMode), (int)gpu->swapchain.presentMode,
                gpu->swapchain.extent.width, gpu->swapchain.extent.height, gpu->swapchain.imageCount,
                CJGUI_VK_IN_FLIGHT, gpu->logicalWidth, gpu->logicalHeight, gpu->windowScale);
    }

    if (outStatus != NULL) *outStatus = CJGUI_LINUX_GPU_OK;
    return gpu;

fail:
    cjgui_vk_teardown(gpu);
    free(gpu);
    if (outStatus != NULL) *outStatus = status;
    return NULL;
}

void cjgui_linux_gpu_destroy(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return;
    cjgui_vk_teardown(gpu);
    free(gpu);
}

int cjgui_linux_gpu_resize(CjguiLinuxGpu *gpu, uint32_t logicalWidth, uint32_t logicalHeight)
{
    if (gpu == NULL) return CJGUI_LINUX_GPU_INVALID;
    if (gpu->device == VK_NULL_HANDLE || gpu->surface == VK_NULL_HANDLE) return CJGUI_LINUX_GPU_INVALID;

    if (logicalWidth > 0u) gpu->logicalWidth = logicalWidth;
    if (logicalHeight > 0u) gpu->logicalHeight = logicalHeight;
    double scale = cjgui_linux_window_scale(gpu->window);
    if (scale > 0.0) gpu->windowScale = scale;

    uint32_t wantWidth = (uint32_t)((double)gpu->logicalWidth * gpu->windowScale);
    uint32_t wantHeight = (uint32_t)((double)gpu->logicalHeight * gpu->windowScale);
    return cjgui_vk_rebuild_swapchain(gpu, wantWidth, wantHeight);
}

// ---------------------------------------------------------------------------
// 帧
// ---------------------------------------------------------------------------

static void cjgui_vk_frame_reset_cpu_state(CjguiVkFrame *f)
{
    f->vertexCount = 0;
    f->drawCount = 0;
}

int cjgui_linux_gpu_begin_frame(CjguiLinuxGpu *gpu, const float clear[4])
{
    if (gpu == NULL || clear == NULL) return CJGUI_LINUX_GPU_INVALID;
    if (gpu->frameActive) {
        fprintf(stderr, "cjgui_linux_vulkan: begin_frame called while a frame is active\n");
        return CJGUI_LINUX_GPU_INVALID;
    }
    if (!gpu->swapchainUsable || gpu->swapchain.handle == VK_NULL_HANDLE) return CJGUI_LINUX_GPU_OUT_OF_DATE;

    uint32_t slot = (uint32_t)(gpu->frameSerial % CJGUI_VK_IN_FLIGHT);
    CjguiVkFrame *f = &gpu->frames[slot];

    // 该 slot 上一次提交的 fence 在这里回收：命令缓冲 / 信号量 / 顶点缓冲同一时点可用。
    if (f->fencePending) {
        VkResult wr = vkWaitForFences(gpu->device, 1, &f->fence, VK_TRUE, UINT64_MAX);
        if (wr != VK_SUCCESS) {
            gpu->swapchainUsable = 0;
            return cjgui_vk_fail("vkWaitForFences(slot)", wr, CJGUI_LINUX_GPU_DEVICE_FAILED);
        }
        VkResult rr = vkResetFences(gpu->device, 1, &f->fence);
        if (rr != VK_SUCCESS) {
            gpu->swapchainUsable = 0;
            return cjgui_vk_fail("vkResetFences(slot)", rr, CJGUI_LINUX_GPU_DEVICE_FAILED);
        }
        f->fencePending = 0;
    }

    cjgui_vk_frame_reset_cpu_state(f);

    uint32_t imageIndex = 0;
    VkResult r = vkAcquireNextImageKHR(gpu->device, gpu->swapchain.handle, UINT64_MAX, f->imageAvailable,
                                       VK_NULL_HANDLE, &imageIndex);
    if (r == VK_ERROR_OUT_OF_DATE_KHR) return CJGUI_LINUX_GPU_OUT_OF_DATE;
    if (r == VK_ERROR_SURFACE_LOST_KHR) {
        gpu->swapchainUsable = 0;
        return cjgui_vk_fail("vkAcquireNextImageKHR", r, CJGUI_LINUX_GPU_SURFACE_FAILED);
    }
    if (r != VK_SUCCESS && r != VK_SUBOPTIMAL_KHR) {
        gpu->swapchainUsable = 0;
        return cjgui_vk_fail("vkAcquireNextImageKHR", r, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
    }
    if (imageIndex >= gpu->swapchain.imageCount) {
        fprintf(stderr, "cjgui_linux_vulkan: acquired image index %u out of range (%u)\n", imageIndex,
                gpu->swapchain.imageCount);
        gpu->swapchainUsable = 0;
        return CJGUI_LINUX_GPU_INVALID;
    }

    gpu->currentSlot = slot;
    gpu->currentImage = imageIndex;
    gpu->clearColor[0] = clear[0];
    gpu->clearColor[1] = clear[1];
    gpu->clearColor[2] = clear[2];
    gpu->clearColor[3] = clear[3];
    gpu->frameActive = 1;
    return CJGUI_LINUX_GPU_OK;
}

int cjgui_linux_gpu_draw_triangles(CjguiLinuxGpu *gpu, const CjguiLinuxGpuVertex *vertices,
                                   uint32_t vertexCount)
{
    if (gpu == NULL || vertices == NULL) return CJGUI_LINUX_GPU_INVALID;
    if (vertexCount == 0u) return CJGUI_LINUX_GPU_OK;
    if (!gpu->frameActive) {
        fprintf(stderr, "cjgui_linux_vulkan: draw_triangles outside a frame\n");
        return CJGUI_LINUX_GPU_INVALID;
    }

    CjguiVkFrame *f = &gpu->frames[gpu->currentSlot];

    if (f->vertexCount + vertexCount > f->cpuCapacity) {
        uint32_t want = f->cpuCapacity > 0u ? f->cpuCapacity : 4096u;
        while (want < f->vertexCount + vertexCount) want *= 2u;
        CjguiLinuxGpuVertex *grown =
            (CjguiLinuxGpuVertex *)realloc(f->cpuVerts, sizeof(CjguiLinuxGpuVertex) * (size_t)want);
        if (grown == NULL) {
            fprintf(stderr, "cjgui_linux_vulkan: out of memory growing CPU vertex array (%u -> %u)\n",
                    f->cpuCapacity, want);
            gpu->swapchainUsable = 0;
            return CJGUI_LINUX_GPU_DEVICE_FAILED;
        }
        f->cpuVerts = grown;
        f->cpuCapacity = want;
    }
    memcpy(f->cpuVerts + f->vertexCount, vertices, sizeof(CjguiLinuxGpuVertex) * (size_t)vertexCount);

    // 纹理开关：几何整体指向左上角保留白色纹素时等价于"纯顶点色"，可跳过采样；
    // 契约的 draw_triangles 没有 textured 形参，所以这里按 UV 判定。
    const float whiteBound = (float)CJGUI_VK_WHITE_TEXEL_SIDE / (float)CJGUI_LINUX_ATLAS_SIDE;
    float textured = 0.0f;
    for (uint32_t i = 0; i < vertexCount; ++i) {
        const CjguiLinuxGpuVertex *v = &vertices[i];
        if (v->u > whiteBound || v->v > whiteBound) {
            textured = 1.0f;
            break;
        }
    }

    if (f->drawCount > 0u) {
        CjguiVkDrawRange *last = &f->draws[f->drawCount - 1u];
        if (last->firstVertex + last->vertexCount == f->vertexCount &&
            ((last->textured > 0.5f) == (textured > 0.5f))) {
            last->vertexCount += vertexCount;
            f->vertexCount += vertexCount;
            return CJGUI_LINUX_GPU_OK;
        }
    }

    if (f->drawCount + 1u > f->drawCapacity) {
        uint32_t want = f->drawCapacity > 0u ? f->drawCapacity * 2u : 64u;
        CjguiVkDrawRange *grown = (CjguiVkDrawRange *)realloc(f->draws, sizeof(CjguiVkDrawRange) * (size_t)want);
        if (grown == NULL) {
            fprintf(stderr, "cjgui_linux_vulkan: out of memory growing draw list\n");
            gpu->swapchainUsable = 0;
            return CJGUI_LINUX_GPU_DEVICE_FAILED;
        }
        f->draws = grown;
        f->drawCapacity = want;
    }
    f->draws[f->drawCount].firstVertex = f->vertexCount;
    f->draws[f->drawCount].vertexCount = vertexCount;
    f->draws[f->drawCount].textured = textured;
    f->drawCount += 1u;
    f->vertexCount += vertexCount;
    return CJGUI_LINUX_GPU_OK;
}

static int cjgui_vk_record_frame(CjguiLinuxGpu *gpu, CjguiVkFrame *f)
{
    VkResult r = vkResetCommandBuffer(f->cmd, 0);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkResetCommandBuffer(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkCommandBufferBeginInfo bi;
    memset(&bi, 0, sizeof bi);
    bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    r = vkBeginCommandBuffer(f->cmd, &bi);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkBeginCommandBuffer(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkClearValue clear;
    memset(&clear, 0, sizeof clear);
    clear.color.float32[0] = gpu->clearColor[0];
    clear.color.float32[1] = gpu->clearColor[1];
    clear.color.float32[2] = gpu->clearColor[2];
    clear.color.float32[3] = gpu->clearColor[3];

    VkRenderPassBeginInfo rbi;
    memset(&rbi, 0, sizeof rbi);
    rbi.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    rbi.renderPass = gpu->renderPass;
    rbi.framebuffer = gpu->swapchain.framebuffers[gpu->currentImage];
    rbi.renderArea.offset.x = 0;
    rbi.renderArea.offset.y = 0;
    rbi.renderArea.extent = gpu->swapchain.extent;
    rbi.clearValueCount = 1;
    rbi.pClearValues = &clear;
    vkCmdBeginRenderPass(f->cmd, &rbi, VK_SUBPASS_CONTENTS_INLINE);

    if (f->drawCount > 0u && f->vertexCount > 0u) {
        VkViewport viewport;
        memset(&viewport, 0, sizeof viewport);
        viewport.x = 0.0f;
        viewport.y = 0.0f;
        viewport.width = (float)gpu->swapchain.extent.width;
        viewport.height = (float)gpu->swapchain.extent.height;
        viewport.minDepth = 0.0f;
        viewport.maxDepth = 1.0f;
        vkCmdSetViewport(f->cmd, 0, 1, &viewport);

        VkRect2D scissor;
        memset(&scissor, 0, sizeof scissor);
        scissor.offset.x = 0;
        scissor.offset.y = 0;
        scissor.extent = gpu->swapchain.extent;
        vkCmdSetScissor(f->cmd, 0, 1, &scissor);

        vkCmdBindPipeline(f->cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, gpu->pipeline);
        vkCmdBindDescriptorSets(f->cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, gpu->pipelineLayout, 0, 1,
                                &gpu->descriptorSets[gpu->currentSlot], 0, NULL);
        VkDeviceSize offset = 0;
        vkCmdBindVertexBuffers(f->cmd, 0, 1, &f->vertexBuffer, &offset);

        CjguiVkPushConstants push;
        memset(&push, 0, sizeof push);
        push.viewportWidth = (float)gpu->swapchain.extent.width;
        push.viewportHeight = (float)gpu->swapchain.extent.height;
        for (uint32_t i = 0; i < f->drawCount; ++i) {
            push.textured = f->draws[i].textured;
            vkCmdPushConstants(f->cmd, gpu->pipelineLayout,
                               VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 0,
                               CJGUI_VK_PUSH_BYTES, &push);
            vkCmdDraw(f->cmd, f->draws[i].vertexCount, 1, f->draws[i].firstVertex, 0);
        }
    }

    vkCmdEndRenderPass(f->cmd);
    r = vkEndCommandBuffer(f->cmd);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkEndCommandBuffer(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    return CJGUI_LINUX_GPU_OK;
}

int cjgui_linux_gpu_end_frame(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return CJGUI_LINUX_GPU_INVALID;
    if (!gpu->frameActive) {
        fprintf(stderr, "cjgui_linux_vulkan: end_frame without begin_frame\n");
        return CJGUI_LINUX_GPU_INVALID;
    }

    CjguiVkFrame *f = &gpu->frames[gpu->currentSlot];
    uint32_t imageIndex = gpu->currentImage;
    gpu->frameActive = 0;

    // 顶点数据写入本 slot 的持久映射缓冲：begin_frame 已回收该 slot 的 fence，
    // 这里不会有任何在途提交还在读它。
    if (f->vertexCount > 0u) {
        VkDeviceSize need = (VkDeviceSize)f->vertexCount * sizeof(CjguiLinuxGpuVertex);
        int st = cjgui_vk_ensure_vertex_capacity(gpu, f, need);
        if (st != CJGUI_LINUX_GPU_OK) {
            gpu->swapchainUsable = 0;
            return st;
        }
        memcpy(f->vertexMapped, f->cpuVerts, (size_t)need);
        cjgui_vk_flush_range(gpu, f->vertexMemory, 0, need, f->vertexCoherent);
    }

    int st = cjgui_vk_record_frame(gpu, f);
    if (st != CJGUI_LINUX_GPU_OK) {
        gpu->swapchainUsable = 0;
        return st;
    }

    VkPipelineStageFlags waitStage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    VkSubmitInfo si;
    memset(&si, 0, sizeof si);
    si.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    si.waitSemaphoreCount = 1;
    si.pWaitSemaphores = &f->imageAvailable;
    si.pWaitDstStageMask = &waitStage;
    si.commandBufferCount = 1;
    si.pCommandBuffers = &f->cmd;
    si.signalSemaphoreCount = 1;
    si.pSignalSemaphores = &gpu->swapchain.renderFinished[imageIndex];

    VkResult r = vkResetFences(gpu->device, 1, &f->fence);
    if (r != VK_SUCCESS) {
        gpu->swapchainUsable = 0;
        return cjgui_vk_fail("vkResetFences(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }
    r = vkQueueSubmit(gpu->queue, 1, &si, f->fence);
    if (r != VK_SUCCESS) {
        gpu->swapchainUsable = 0;
        return cjgui_vk_fail("vkQueueSubmit(frame)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    }
    f->fencePending = 1;

    VkPresentInfoKHR pi;
    memset(&pi, 0, sizeof pi);
    pi.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    pi.waitSemaphoreCount = 1;
    pi.pWaitSemaphores = &gpu->swapchain.renderFinished[imageIndex];
    pi.swapchainCount = 1;
    pi.pSwapchains = &gpu->swapchain.handle;
    pi.pImageIndices = &imageIndex;

    VkResult pr = vkQueuePresentKHR(gpu->queue, &pi);
    gpu->frameSerial += 1u;

    if (pr == VK_SUCCESS) {
        gpu->frameIndex += 1u;
        return CJGUI_LINUX_GPU_OK;
    }
    if (pr == VK_SUBOPTIMAL_KHR) {
        // 本帧已经呈现，交换链需要在随后重建。
        gpu->frameIndex += 1u;
        return CJGUI_LINUX_GPU_SUBOPTIMAL;
    }
    if (pr == VK_ERROR_OUT_OF_DATE_KHR) {
        gpu->swapchainUsable = 0;
        return CJGUI_LINUX_GPU_OUT_OF_DATE;
    }
    gpu->swapchainUsable = 0;
    return cjgui_vk_fail("vkQueuePresentKHR", pr, CJGUI_LINUX_GPU_SWAPCHAIN_FAILED);
}

// ---------------------------------------------------------------------------
// 图集上传
// ---------------------------------------------------------------------------

static int cjgui_vk_atlas_upload(CjguiLinuxGpu *gpu, int x, int y, int width, int height,
                                 const uint8_t *rgba)
{
    if (gpu == NULL || rgba == NULL) return CJGUI_LINUX_GPU_INVALID;
    if (width <= 0 || height <= 0) return CJGUI_LINUX_GPU_OK;

    uint32_t side = CJGUI_LINUX_ATLAS_SIDE;
    if (x < 0 || y < 0 || (uint32_t)x >= side || (uint32_t)y >= side) {
        fprintf(stderr, "cjgui_linux_vulkan: atlas upload origin (%d,%d) outside %ux%u\n", x, y, side, side);
        return CJGUI_LINUX_GPU_INVALID;
    }
    if ((uint32_t)x + (uint32_t)width > side) width = (int)(side - (uint32_t)x);
    if ((uint32_t)y + (uint32_t)height > side) height = (int)(side - (uint32_t)y);
    if (width <= 0 || height <= 0) return CJGUI_LINUX_GPU_OK;

    // 选一个 staging slot：优先已回收的，全在途时只等最老的那个（不 vkQueueWaitIdle）。
    CjguiVkUpload *u = NULL;
    for (uint32_t i = 0; i < CJGUI_VK_UPLOAD_SLOTS; ++i) {
        CjguiVkUpload *cand = &gpu->uploads[gpu->uploadNext];
        gpu->uploadNext = (gpu->uploadNext + 1u) % CJGUI_VK_UPLOAD_SLOTS;
        if (!cand->fencePending) {
            u = cand;
            break;
        }
        VkResult sr = vkGetFenceStatus(gpu->device, cand->fence);
        if (sr == VK_SUCCESS) {
            cand->fencePending = 0;
            u = cand;
            break;
        }
        if (sr != VK_NOT_READY) {
            return cjgui_vk_fail("vkGetFenceStatus(upload)", sr, CJGUI_LINUX_GPU_DEVICE_FAILED);
        }
        u = cand;   // 兜底：全部都还在途时用最后看过的那个，下面会等待
    }
    if (u == NULL) u = &gpu->uploads[0];

    if (u->fencePending) {
        VkResult wr = vkWaitForFences(gpu->device, 1, &u->fence, VK_TRUE, UINT64_MAX);
        if (wr != VK_SUCCESS) return cjgui_vk_fail("vkWaitForFences(upload)", wr, CJGUI_LINUX_GPU_DEVICE_FAILED);
        VkResult rr = vkResetFences(gpu->device, 1, &u->fence);
        if (rr != VK_SUCCESS) return cjgui_vk_fail("vkResetFences(upload)", rr, CJGUI_LINUX_GPU_DEVICE_FAILED);
        u->fencePending = 0;
    }

    // 持久映射内存：整块写进 staging，再由 GPU 拷进图集。
    uint8_t *dst = (uint8_t *)u->mapped;
    size_t rowBytes = (size_t)width * 4u;
    for (int row = 0; row < height; ++row) {
        memcpy(dst + (size_t)row * rowBytes, rgba + (size_t)row * rowBytes, rowBytes);
    }
    cjgui_vk_flush_range(gpu, u->stagingMemory, 0, (VkDeviceSize)rowBytes * (VkDeviceSize)height, u->coherent);

    VkResult r = vkResetCommandBuffer(u->cmd, 0);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkResetCommandBuffer(upload)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    VkCommandBufferBeginInfo bi;
    memset(&bi, 0, sizeof bi);
    bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    r = vkBeginCommandBuffer(u->cmd, &bi);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkBeginCommandBuffer(upload)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    // 先转 TRANSFER_DST：srcStage 覆盖此前已提交到本队列的全部工作（含上一帧的
    // 片元采样与颜色写入），队列提交顺序保证 barrier 能看到它们。
    VkImageMemoryBarrier barrier;
    memset(&barrier, 0, sizeof barrier);
    barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    // 首次上传时图集仍是 UNDEFINED（创建时的 initialLayout），必须从 UNDEFINED 起转，
    // 且此时 srcAccessMask 必须为 0（没有需要可见的既有写入）。
    barrier.srcAccessMask = gpu->atlasLayout == VK_IMAGE_LAYOUT_UNDEFINED
                                ? 0
                                : (VK_ACCESS_MEMORY_WRITE_BIT | VK_ACCESS_MEMORY_READ_BIT);
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.oldLayout = gpu->atlasLayout;
    barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = gpu->atlasImage;
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier.subresourceRange.baseMipLevel = 0;
    barrier.subresourceRange.levelCount = 1;
    barrier.subresourceRange.baseArrayLayer = 0;
    barrier.subresourceRange.layerCount = 1;
    vkCmdPipelineBarrier(u->cmd, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, NULL,
                         0, NULL, 1, &barrier);

    VkBufferImageCopy region;
    memset(&region, 0, sizeof region);
    region.bufferOffset = 0;
    region.bufferRowLength = 0;
    region.bufferImageHeight = 0;
    region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    region.imageSubresource.mipLevel = 0;
    region.imageSubresource.baseArrayLayer = 0;
    region.imageSubresource.layerCount = 1;
    region.imageOffset.x = x;
    region.imageOffset.y = y;
    region.imageOffset.z = 0;
    region.imageExtent.width = (uint32_t)width;
    region.imageExtent.height = (uint32_t)height;
    region.imageExtent.depth = 1;
    vkCmdCopyBufferToImage(u->cmd, u->staging, gpu->atlasImage, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    vkCmdPipelineBarrier(u->cmd, VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, NULL,
                         0, NULL, 1, &barrier);

    r = vkEndCommandBuffer(u->cmd);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkEndCommandBuffer(upload)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);

    VkSubmitInfo si;
    memset(&si, 0, sizeof si);
    si.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    si.commandBufferCount = 1;
    si.pCommandBuffers = &u->cmd;

    r = vkResetFences(gpu->device, 1, &u->fence);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkResetFences(upload)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    r = vkQueueSubmit(gpu->queue, 1, &si, u->fence);
    if (r != VK_SUCCESS) return cjgui_vk_fail("vkQueueSubmit(upload)", r, CJGUI_LINUX_GPU_DEVICE_FAILED);
    // 该命令缓冲已在同一队列上排在后续提交之前，布局跟踪随之更新。
    gpu->atlasLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    u->fencePending = 1;
    return CJGUI_LINUX_GPU_OK;
}

int cjgui_linux_gpu_upload_atlas(CjguiLinuxGpu *gpu, int x, int y, int width, int height,
                                 const uint8_t *rgba)
{
    if (gpu == NULL) return CJGUI_LINUX_GPU_INVALID;
    if (gpu->device == VK_NULL_HANDLE || gpu->atlasImage == VK_NULL_HANDLE) return CJGUI_LINUX_GPU_INVALID;
    return cjgui_vk_atlas_upload(gpu, x, y, width, height, rgba);
}

// ---------------------------------------------------------------------------
// 查询
// ---------------------------------------------------------------------------

uint32_t cjgui_linux_gpu_drawable_width(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return 0u;
    return gpu->swapchain.extent.width;
}

uint32_t cjgui_linux_gpu_drawable_height(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return 0u;
    return gpu->swapchain.extent.height;
}

double cjgui_linux_gpu_scale(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return 1.0;
    if (gpu->logicalWidth > 0u && gpu->swapchain.extent.width > 0u) {
        return (double)gpu->swapchain.extent.width / (double)gpu->logicalWidth;
    }
    return gpu->windowScale > 0.0 ? gpu->windowScale : 1.0;
}

uint64_t cjgui_linux_gpu_frame_index(CjguiLinuxGpu *gpu)
{
    if (gpu == NULL) return 0u;
    return gpu->frameIndex;
}
