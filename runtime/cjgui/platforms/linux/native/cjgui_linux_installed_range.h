// runtime/cjgui/platforms/linux/native/cjgui_linux_installed_range.h
//
// 会话层与"来源范围生产者"（installed-range）之间的唯一共享面。
//
// 共同层的普通来源范围链（installed-range）在 macOS 与 Windows 上由各自的 native
// 实现生产者侧；Linux 本阶段显式关闭（`internalRendererSourceRangeSupported()` =
// false），因此焦点走普通路径、正文编辑意图落到控制器。接通这条链需要本模块。
//
// 本模块只通过下面两个只读访问器取得事实，不触碰会话内部结构：
//   * 已接受场景里某个节点的可见正文与字体参数；
//   * 最近一次泵出的 51 号（TEXT_RANGE_CHANGED）意图的三段正文与替换范围。

#ifndef CJGUI_LINUX_INSTALLED_RANGE_H
#define CJGUI_LINUX_INSTALLED_RANGE_H

#include <stdint.h>

#include "cjgui_internal_renderer.h"
#include "cjgui_linux_services.h"

#ifdef __cplusplus
extern "C" {
#endif

// 最近一次泵出的范围意图载荷。三段正文都是**借用的**，生命周期到下一次事件泵。
typedef struct CjguiLinuxRangeIntentView {
    int present;
    uint64_t nodeId;
    int64_t resourceId;
    uint32_t nodeKind;
    uint64_t bindingEpoch;
    uint64_t sceneVersion;
    uint64_t sequence;                 // 单调序号，claim 用它建立一次性身份
    const char *preBody;               // 编辑前的完整正文（UTF-8）
    const char *replacement;           // 插入的替换串
    const char *postBody;              // 编辑后的完整正文（UTF-8）
    uint32_t replacementStart16;       // 被替换的 UTF-16 起点
    uint32_t replacementLength16;      // 被替换的 UTF-16 长度
} CjguiLinuxRangeIntentView;

// 由 cjgui_linux_session.c 实现。
CjguiLinuxText *cjgui_linux_session_text(uint64_t token);                       // 见 cjgui_linux_services.h
void cjgui_linux_session_text_node_view(uint64_t token, uint64_t nodeId, CjguiLinuxTextNodeView *outView);
uint64_t cjgui_linux_session_scene_version(uint64_t token);

// 最近一次范围意图；没有则 *outView.present = 0。
void cjgui_linux_session_range_intent_view(uint64_t token, CjguiLinuxRangeIntentView *outView);

// 会话创建/销毁钩子，由 cjgui_linux_session.c 调用；本模块只实现函数体。
void cjgui_linux_installed_range_on_create(int slot);
void cjgui_linux_installed_range_on_destroy(int slot);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_INSTALLED_RANGE_H
