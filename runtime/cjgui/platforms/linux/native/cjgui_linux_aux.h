// runtime/cjgui/platforms/linux/native/cjgui_linux_aux.h
//
// Linux ABI 会话层与"长尾"ABI 入口之间的唯一共享面。
//
// 会话状态（窗口/GPU/文字/场景）由 cjgui_linux_session.c 独占；长尾入口
// （共享操作投影、诊断、命令菜单、数据搬运、图片资源、组合输入等）由
// cjgui_linux_aux.c 独占它自己的静态状态表，只通过下面这个极小接口确认
// "这个 token 还活着"以及"它在哪一格"，不触碰会话内部结构。

#ifndef CJGUI_LINUX_AUX_H
#define CJGUI_LINUX_AUX_H

#include <stdint.h>

#include "cjgui_internal_renderer.h"

#ifdef __cplusplus
extern "C" {
#endif

#define CJGUI_LINUX_MAX_SESSIONS 2u

// token 活着返回 0..CJGUI_LINUX_MAX_SESSIONS-1 的槽位号，否则返回 -1。
// 由 cjgui_linux_session.c 实现。
int cjgui_linux_session_slot(uint64_t token);

// 长尾状态表的初始化/清理钩子，由 cjgui_linux_session.c 在 create/destroy 时调用。
void cjgui_linux_aux_on_create(int slot);
void cjgui_linux_aux_on_destroy(int slot);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_AUX_H
