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

typedef struct CjguiLinuxImageDomain CjguiLinuxImageDomain;

// 会话所属图片域；PNG 传输受理前的真实解码/预算准入借用它。
CjguiLinuxImageDomain *cjgui_linux_session_image_domain(uint64_t token);

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

// 已接受命令菜单中是否存在该快捷键声明。focusScope=0 表示不限定作用域；
// 非 0 时只接受同一作用域的条目（条目自身 scope 为 0 视为全局）。
// 只回答"声明存在"，执行仍由共同层 invokeCommand 校验。
int cjgui_linux_aux_shortcut_declared(uint64_t token, const char *shortcut, uint64_t focusScope);

// 是否存在等待与场景一起提交的完整菜单 staging。present 在真正接受场景时
// 用它决定是否提升菜单；没有 staging 的普通帧不触碰已接受菜单。
int cjgui_linux_aux_command_menu_staged(uint64_t token);

// 提升 staging 为已接受菜单（定义在 aux.c，同时是 Cangjie FFI 入口）。
CjguiInternalRendererStatus cjgui_internal_renderer_commit_composable_command_menu(uint64_t session);

// 当前已接受上下文菜单请求的 id；无守卫时为 0。native 把它拼进
// `escape:<requestId>`，共同层据此只结束这个请求。
uint64_t cjgui_linux_aux_context_menu_request(uint64_t token);

// 数据交换声明读取。共同层在每次投影前重写 staging；这里只把与
// acceptedVersion 相同的整代条目交给会话，不保存第二份应用状态。
// wantFormat: 1 = text/plain, 2 = image/png。
// 命中返回 1，outPayload 是声明的文本载荷（image/png 的 SOURCE 为空串），
// outBytes/outByteLength 只对 SOURCE image/png 有效。返回的指针在下次
// configure/set 之前有效，会话必须在下一次投影前用完。
int cjgui_linux_aux_transfer_find(uint64_t token, uint64_t acceptedVersion,
                                  uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
                                  uint32_t role, uint32_t wantFormat,
                                  CjguiInternalRendererComposableDataTransferItem *outItem,
                                  const char **outPayload,
                                  const uint8_t **outBytes, uint32_t *outByteLength);
// 已接受代中，某一 role 是否声明了该类型；用于 Xdnd 的 Enter/Position 答复。
int cjgui_linux_aux_transfer_declared(uint64_t token, uint64_t acceptedVersion,
                                      uint32_t role, uint32_t wantFormat,
                                      int *outLocalPngFileAllowed);

// 场景事务：候选提交时把同代 staging 提升为已接受声明；候选取消/丢弃只撤
// staging，已接受声明保持不变。由 session.c 的场景提交/取消路径调用。
void cjgui_linux_aux_commit_transfer(uint64_t token, uint64_t acceptedVersion);
void cjgui_linux_aux_discard_transfer(uint64_t token);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_AUX_H
