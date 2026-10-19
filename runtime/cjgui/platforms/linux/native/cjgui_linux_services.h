// runtime/cjgui/platforms/linux/native/cjgui_linux_services.h
//
// 会话层与"文字几何服务"之间的唯一共享面。
//
// cjgui_linux_session.c 拥有会话与已接受场景；cjgui_linux_text_services.c 拥有
// ABI 的文字几何/字素查询入口（caret 矩形、行矩形、位置查询、视觉邻接、字素簇），
// 只通过下面这几个只读访问器取得"某个节点当前投影了什么文字与字体"。

#ifndef CJGUI_LINUX_SERVICES_H
#define CJGUI_LINUX_SERVICES_H

#include <stdint.h>

#include "cjgui_linux_text.h"
// 下面「文字几何服务入口」的追加声明用到 CjguiInternalRendererStatus，
// 因此本头文件自带 ABI 头依赖（两个头都在同一套 -I 下可见）。
#include "cjgui_internal_renderer.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CjguiLinuxTextNodeView {
    int found;
    const char *text;      // 借用的 UTF-8，生命周期到下一次场景提交
    double fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;
    int64_t x;
    int64_t y;
    int64_t width;
    int64_t height;
    uint64_t sceneVersion;
    uint64_t nodeId;
} CjguiLinuxTextNodeView;

// 会话的文字模块句柄；token 无效返回 NULL。
CjguiLinuxText *cjgui_linux_session_text(uint64_t token);

// 在已接受场景里按 nodeId 找节点，取出它的可见正文与字体参数。
// 找不到（或会话无效）时 *outView.found = 0，其余字段保持未定义。
void cjgui_linux_session_text_node_view(uint64_t token, uint64_t nodeId, CjguiLinuxTextNodeView *outView);

// 已接受场景的投影版本；会话无效返回 0。
uint64_t cjgui_linux_session_scene_version(uint64_t token);

// ---------------------------------------------------------------- 文字几何服务入口（追加）
//
// 由 cjgui_linux_text_services.c 拥有。下面这五个入口的 Cangjie foreign 声明只存在于
// runtime/cjgui/src/*.cj，native/cjgui_internal_renderer.h 里没有；为了让同一 native
// 目录下的消费者看到同一份原型（也为了让本模块在 -Wall -Wextra 下得到真实类型检查），
// 在这里声明。类型与 macOS 侧同款实现一致：
//   caret / line_rect_count → int32_t；line_rect_value → double；
//   grapheme_cluster_range / visual_neighbor → CjguiInternalRendererStatus。
// 若要把它们并入 native/cjgui_internal_renderer.h，请沿用这组类型，否则会出现
// conflicting types。
//
// 其余入口（text_position_v1 / _stats_v1 / text_stop_resolve / _stop_neighbor /
// composed_prefix_utf8_length）已由 native/cjgui_internal_renderer.h 声明，此处不重复。
//
// 语义要点（完整说明见 .c 文件头）：
//  * 绝不静默返回零矩形：17=节点不在、18=无几何、11=会话无效、14=正文非法 UTF-8、
//    33=场景/租约过期、34=越界/劈开标量/非字素簇边界、35=视觉邻位超预算。
//  * line_rect 的返回值是**行数**，负值 = 具名错误（-17/-18/-11/-33/-34/-99）；
//    line_rect_value(index, component) 只在 count 成功后按 index < count 读取。
//  * 坐标一律为窗口内容逻辑点；文字块原点与绘制路径同一套（节点左上角 + 6pt 内缩）。
int32_t cjgui_internal_renderer_text_geometry_caret(uint64_t session, int64_t nodeId,
                                                    int64_t displayByte, double caretWidthPt,
                                                    uint64_t expectedSceneVersion, uint32_t affinity,
                                                    double *outX, double *outY, double *outWidth,
                                                    double *outHeight);

int32_t cjgui_internal_renderer_text_line_rect_count(uint64_t session, uint64_t nodeId,
                                                     int64_t startByte, int64_t endByte,
                                                     int32_t maxRects,
                                                     uint64_t expectedSceneVersion);

double cjgui_internal_renderer_text_line_rect_value(uint64_t session, uint64_t nodeId,
                                                    int64_t startByte, int64_t endByte,
                                                    int32_t maxRects, int32_t index,
                                                    int32_t component,
                                                    uint64_t expectedSceneVersion);

CjguiInternalRendererStatus
cjgui_internal_renderer_grapheme_cluster_range(const char *utf8, uint64_t declaredLength,
                                               uint64_t offsetByte, uint64_t *outStartByte,
                                               uint64_t *outEndByte);

CjguiInternalRendererStatus cjgui_internal_renderer_text_visual_neighbor(
    uint64_t session, uint64_t nodeId, int64_t displayByte, uint32_t left,
    uint64_t expectedSceneVersion, uint32_t caretAffinity, uint32_t *outNeighborByte,
    uint32_t *outAffinity);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_SERVICES_H
