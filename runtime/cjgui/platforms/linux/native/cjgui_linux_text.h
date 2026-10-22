// runtime/cjgui/platforms/linux/native/cjgui_linux_text.h
//
// Linux 文字测量 / 整形 / 字形图集（窄平台实现）。
//
// C ABI 的 measure_composable_text 收的是原始 UTF-8 + fontSize/fontWeight/
// fontFamily 枚举 + maxWidth，回测量值——整形必须在 native 侧完成。本模块用
// Fontconfig（选族与回退链）+ HarfBuzz（glyph/advance/cluster）+ FreeType（位图）
// 实现这条路，并把字形按 (face, pixelSize, glyphId) 缓存进单页 RGBA 图集。
//
// 与共同层的分工：
//  - 共同层决定"这段文字画在哪个节点、什么颜色、什么裁剪"，并负责选择/命中；
//  - 本模块只回答"这段文字有多宽多高、每个字形贴在图集哪一格、字形方块在哪"。
//
// 中文正确显示与字体回退是本阶段验收的一部分：缺字时必须走 Fontconfig 回退链，
// 并且把每一次回退记录下来（cjgui_linux_text_take_fallback_log），不允许静默画
// 豆腐块。
//
// 实现约定（与 .c 一致，供共同层理解测量值的来源）：
//  * 选族：fontFamily=0 → fontconfig 的 sans-serif，=1 → monospace；fontWeight
//    0/1/2/3 → fc 的 regular/medium/demibold/bold。缺字时按 Fontconfig 的排序候选
//    列表逐个换族重整形，候选都不覆盖时再做一次"按字符集"的兜底查询。
//  * 回退记录：requested 是枚举解析出的族名（sans-serif/monospace），selected 是
//    实际供字的族名；两个特殊值表示没有可用字形——"<notdef>"（整形落到 .notdef）
//    与 "<no-font>"（整条链都没有字体覆盖该码点）。每个整形 run 至多一条记录，
//    byteOffset 指向该 run 里第一次需要回退的 cluster。
//  * 测量与 layout 走同一条计算路径：wantQuads=0 不会光栅化、不会写图集，因此
//    先测量再 layout 是零副作用的；两次调用的宽度/高度/基线完全一致。
//  * 图集按 (face, pixelSize, glyphId) 缓存，命中不重复光栅化；槽间留 1px 防采样
//    串色；页满返回 ATLAS_FULL 且保留已缓存内容（不整页重建）。
//  * 本阶段只做 LTR，不跑完整 UAX#14：换行点取空格 / CJK / emoji 边界。
//
// 调试钩子（只影响本模块选族，不改 ABI，create 之后首次解析族时生效）：
//   CJGUI_LINUX_TEXT_FAMILY_SYSTEM  替换 fontFamily=0 的族名（默认 sans-serif）
//   CJGUI_LINUX_TEXT_FAMILY_MONO    替换 fontFamily=1 的族名（默认 monospace）
//
// 线程约定：所有函数都只允许在渲染会话所属的那一个线程上调用。

#ifndef CJGUI_LINUX_TEXT_H
#define CJGUI_LINUX_TEXT_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CjguiLinuxText CjguiLinuxText;

// 字形方块：位置与尺寸为逻辑点，UV 为图集归一化坐标。
typedef struct CjguiLinuxTextQuad {
    float x;
    float y;
    float width;
    float height;
    float u0;
    float v0;
    float u1;
    float v1;
} CjguiLinuxTextQuad;

typedef enum CjguiLinuxTextStatus {
    CJGUI_LINUX_TEXT_OK = 0,
    CJGUI_LINUX_TEXT_NO_FONT = 1,
    CJGUI_LINUX_TEXT_SHAPE_FAILED = 2,
    CJGUI_LINUX_TEXT_BUDGET_EXCEEDED = 3,   // 字形方块数超过调用方容量
    CJGUI_LINUX_TEXT_ATLAS_FULL = 4,        // 图集页已满，本段未能全部光栅化
    CJGUI_LINUX_TEXT_INVALID = 5
} CjguiLinuxTextStatus;

// 图集页尺寸必须与 cjgui_linux_vulkan.h 的 CJGUI_LINUX_ATLAS_SIDE 一致。
#define CJGUI_LINUX_TEXT_ATLAS_SIDE 1024
// 图集左上角 2x2 保留给"实心几何使用的白色纹素"，字形槽位从 (2,2) 开始分配。
#define CJGUI_LINUX_TEXT_ATLAS_ORIGIN 2

// 一次字体回退记录：请求的族与最终选中的族不同，或某个 cluster 走了回退族。
typedef struct CjguiLinuxTextFallback {
    uint32_t byteOffset;     // 该 cluster 在 UTF-8 中的字节偏移
    char requested[64];      // 请求的族名（fontFamily 枚举解析结果）
    char selected[128];      // Fontconfig/回退链实际选中的族名
} CjguiLinuxTextFallback;

CjguiLinuxText *cjgui_linux_text_create(int *outStatus);
void cjgui_linux_text_destroy(CjguiLinuxText *text);

// 图集 CPU 侧像素（RGBA8，side*side*4）。生命周期与本模块一致。
const uint8_t *cjgui_linux_text_atlas_pixels(CjguiLinuxText *text);
int cjgui_linux_text_atlas_side(CjguiLinuxText *text);

// 取走"自上次调用以来被写脏"的矩形并清零。返回 1 表示有脏区。
// 一个矩形不够表达时返回并集；调用方按并集上传是安全的。
int cjgui_linux_text_take_atlas_dirty(CjguiLinuxText *text, int *x, int *y, int *width, int *height);

// 单行行高（逻辑点）。用于共同层估算多行高度。
double cjgui_linux_text_line_height(CjguiLinuxText *text, double fontSize, uint32_t fontWeight,
                                    uint32_t fontFamily);

// 排版一段文本。wantQuads=0 时只测量。
//
//   utf8/len        原始 UTF-8（可含中文、emoji），非 NUL 终止，按 len 解释
//   fontSize        逻辑点
//   fontWeight      0=regular 1=medium 2=semibold 3=bold（与 C ABI 一致；映射到族）
//   fontFamily      0=system 1=monospaced（与 C ABI 一致）
//   maxWidth        <=0 表示不限宽（单行不换行）；>0 表示按逻辑点换行
//   originX/originY 文本块左上角，逻辑点；quad 坐标据此生成
//   outQuads        调用方提供的缓冲，容量 quadCapacity；wantQuads=0 时可为 NULL
//   outQuadCount    写回实际需要的方块总数（可能大于容量，表示被截断）
//   outWidth/outHeight/outAscent  测量值（逻辑点）；outAscent 指首行基线到顶部
//
// 返回 CJGUI_LINUX_TEXT_OK，或 BUDGET_EXCEEDED（方块被截断）、ATLAS_FULL。
int cjgui_linux_text_layout(CjguiLinuxText *text, const char *utf8, size_t len, double fontSize,
                            uint32_t fontWeight, uint32_t fontFamily, double maxWidth, double originX,
                            double originY, int wantQuads, CjguiLinuxTextQuad *outQuads,
                            uint32_t quadCapacity, uint32_t *outQuadCount, double *outWidth,
                            double *outHeight, double *outAscent);

// 行数受限的排版：maxLines=0 等价于上面的不限行入口。超出时只排前 maxLines 行；
// ellipsis!=0 时用 U+2026 替换可见尾部并缩短前缀，仍走同一整形/换行路径。
// 只影响绘制串，调用方保留完整语义原文。
int cjgui_linux_text_layout_limited(CjguiLinuxText *text, const char *utf8, size_t len,
                                    double fontSize, uint32_t fontWeight, uint32_t fontFamily,
                                    double maxWidth, uint32_t maxLines, int ellipsis,
                                    double originX, double originY, int wantQuads,
                                    CjguiLinuxTextQuad *outQuads, uint32_t quadCapacity,
                                    uint32_t *outQuadCount, double *outWidth, double *outHeight,
                                    double *outAscent);

// ------------------------------------------------------------ 多样式只读排版
//
// 与共同层的 textStyleRuns / 生成 label 的 textRuns 共享同一份声明：每个 run 按
// UTF-8 字节范围覆盖 start/end，后声明的 run 覆盖先声明的（与共同层"普通 run
// 保持原顺序"一致）。测量、换行、基线、限行省略与绘制全部走这一条路径。
//
// fontSize/fontWeight/fontFamily 是未被任何 run 覆盖时使用的基线样式。
// 字形方块按 run 输出颜色归属索引（runIndex，UINT32_MAX 表示基线样式），背景
// span 只在 wantQuads!=0 时输出。语义原文不在这里改写：省略只影响绘制串。

typedef struct CjguiLinuxTextStyleRun {
    uint32_t start;
    uint32_t end;
    double fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;
    float red;
    float green;
    float blue;
    float alpha;
    uint8_t hasBackground;
    float backgroundRed;
    float backgroundGreen;
    float backgroundBlue;
    float backgroundAlpha;
} CjguiLinuxTextStyleRun;

typedef struct CjguiLinuxStyledQuad {
    CjguiLinuxTextQuad glyph;
    uint32_t runIndex;
} CjguiLinuxStyledQuad;

typedef struct CjguiLinuxStyledSpan {
    uint32_t runIndex;
    double x0;
    double x1;
    double top;
    double height;
} CjguiLinuxStyledSpan;

#define CJGUI_LINUX_TEXT_STYLE_RUN_CAP 4096u

int cjgui_linux_text_styled_layout(CjguiLinuxText *text, const char *utf8, size_t len,
                                   double fontSize, uint32_t fontWeight, uint32_t fontFamily,
                                   double maxWidth, uint32_t maxLines, int ellipsis,
                                   const CjguiLinuxTextStyleRun *runs, uint32_t runCount,
                                   double originX, double originY, int wantQuads,
                                   CjguiLinuxStyledQuad *outQuads, uint32_t quadCapacity,
                                   CjguiLinuxStyledSpan *outSpans, uint32_t spanCapacity,
                                   uint32_t *outQuadCount, uint32_t *outSpanCount,
                                   double *outWidth, double *outHeight, double *outAscent,
                                   double *outLineHeight);

// 取走自上次调用以来的回退记录。返回写入条数；0 表示没有新的回退。
// 共同层据此产生可见的 fallback 诊断，不静默画豆腐块。
uint32_t cjgui_linux_text_take_fallback_log(CjguiLinuxText *text, CjguiLinuxTextFallback *outEntries,
                                            uint32_t capacity);

// 统计：已光栅化的字形槽数、图集使用字节数（诊断用）。
void cjgui_linux_text_stats(CjguiLinuxText *text, uint32_t *outGlyphCount, uint32_t *outAtlasBytes);

// ---------------------------------------------------------------- 光标 / 行几何
//
// 下面三个查询与 cjgui_linux_text_layout 共用同一条整形 + 换行路径（同样的行断点、
// 同样的 advance），因此光标条与选区矩形必然落在画出来的字形之间；它们只测量，
// 不光栅化、不写图集、不改变图集缓存。多实例依旧各自独立。
//
// 约定：
//  * 行号从 0 起；行 i 的行盒是 (0, i*lineHeight, 行宽, lineHeight)，行宽与 layout
//    的 outWidth 同一口径（行尾空白按悬挂处理，不计入行宽）。
//  * 字节偏移落在字符内部（非边界）时吸附到它所在 cluster 的起点。
//  * 软换行处的那个偏移同时是上一行的行尾与下一行的行首，这里归**下一行行首**
//    （与常见文本编辑器一致）；需要另一种亲和性时再单独加参数。

// 给定 UTF-8 字节偏移处的插入点。byteOffset 不在字符边界时取前一个边界。
// 输出相对文本块左上角（origin 为 0），单位与 fontSize 同一像素尺度。
// outTop 是该行顶部，outLineHeight 是该行行高。
int cjgui_linux_text_caret_position(CjguiLinuxText *text, const char *utf8, size_t len,
                                    double fontSize, uint32_t fontWeight, uint32_t fontFamily,
                                    double maxWidth, size_t byteOffset, double *outX, double *outTop,
                                    double *outLineHeight, uint32_t *outLineIndex,
                                    size_t *outLineStartByte, size_t *outLineEndByte);

// 第 lineIndex 行的包围盒（相对文本块左上角）与该行的字节范围。
// lineIndex 越界返回 CJGUI_LINUX_TEXT_INVALID（空串的 0 号退化空行除外）。
int cjgui_linux_text_line_rect(CjguiLinuxText *text, const char *utf8, size_t len, double fontSize,
                               uint32_t fontWeight, uint32_t fontFamily, double maxWidth,
                               uint32_t lineIndex, double *outX, double *outY, double *outWidth,
                               double *outHeight, size_t *outStartByte, size_t *outEndByte);

// 换行后的行数。与 layout 一致：显式 '\n' 也算一行，空串为 0。
// maxWidth <= 0（不限宽）时，不含 '\n' 的文本恒为 1。
int cjgui_linux_text_line_count(CjguiLinuxText *text, const char *utf8, size_t len, double fontSize,
                                uint32_t fontWeight, uint32_t fontFamily, double maxWidth,
                                uint32_t *outLines);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_TEXT_H
