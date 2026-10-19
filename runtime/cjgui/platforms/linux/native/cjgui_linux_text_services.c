// runtime/cjgui/platforms/linux/native/cjgui_linux_text_services.c
//
// Linux C ABI 的「文字几何 / 字素查询」入口（窄平台实现）。
//
// 拥有者：本文件。只读地消费会话层投影（cjgui_linux_services.h 的三个访问器）与
// 文字模块（cjgui_linux_text.h），不持有任何排版对象、不写图集、不改会话状态。
//
// 覆盖的 ABI 入口（签名以 runtime/cjgui/src/runtime_renderer_text_geometry_query.cj
// 与 runtime/cjgui/src/text_grapheme.cj 的 foreign 块为准）：
//   cjgui_internal_renderer_text_geometry_caret          光标矩形（兼容几何）
//   cjgui_internal_renderer_text_line_rect_count/_value  范围 ⇒ 逐行选择框
//   cjgui_internal_renderer_grapheme_cluster_range       字素簇区间（纯文本）
//   cjgui_internal_renderer_composed_prefix_utf8_length  字素前缀字节数（纯文本）
//   cjgui_internal_renderer_text_position_v1/_stats_v1   版本化停靠点查询
//   cjgui_internal_renderer_text_stop_resolve/_neighbor  停靠点解析 / 视觉邻位
//   cjgui_internal_renderer_text_visual_neighbor         视觉邻位（平台插入点几何）
//
// 铁律（调用方 runtime_renderer_text_geometry_query.cj 的
// cjguiTextGeometryReasonForStatus 依赖这些具名状态）：
//  * **绝不静默返回零矩形**。任何不能证明的查询都返回具名状态码：
//      17 NODE_NOT_FOUND       节点不在已接受场景（→ out_of_coverage）
//      18 GEOMETRY_EMPTY       节点在但这一版文字无法完成测量/整形（→ pending）
//      11 INVALID_SESSION      会话令牌无效（→ unavailable）
//      14 INVALID_UTF8         节点正文不是合法 UTF-8（→ unavailable）
//      33 SCENE_STALE          调用方携带的 accepted 场景版本/排版租约已过期（→ scene_stale）
//      34 TEXT_RANGE_INVALID   越界、劈开 UTF-8 标量、或不是字素簇边界（→ invalid_utf8_boundary）
//      35 VISUAL_NAV_UNSUPPORTED 视觉邻位扫描超出有界预算（→ unavailable）
//  * **不吸附洗白**：点在簇内部（标量边界但不是字素簇边界）时具名 34，不悄悄挪到簇首
//    （与 macOS 侧 CjguiPositionIsBoundary 的拒绝一致；文案契约见
//    runtime_renderer_text_geometry_query.cj 的「不钳制洗白」）。
//  * **零矩形只出现在"范围本身为空"**：line_rect 的 [x,x) 与空文本的 0 号退化行，
//    其余路径要么给真矩形，要么给具名状态。
//  * **行几何与 cjgui_linux_text_layout 同一套换行结果**：caret/行矩形全部经
//    cjgui_linux_text_caret_position / _line_rect / _line_count 取得，它们与 layout
//    共用 lt_prepare（同样的整形、断点、advance）。
//
// 与绘制路径的坐标约定（必须与 session.c 的 cjgui_linux_builder_text 同步）：
//  * 几何按**逻辑点**返回（调用方要的就是窗口内容逻辑点；绘制侧按 scale 放大到设备
//    像素，两者线性等比，断点因此一致）。
//  * 文字块原点 = 节点左上角 + 6pt 内缩（绘制侧 deviceInset = 6.0 * scale）。
//  * 行内宽度 = 节点宽 - 12pt（<=0 时按"不限宽"处理）。
//  * 纵向：单行按行高在节点内垂直居中；换行成多行时从 节点 y + 3pt 起排。
//    已知偏差（契约缺口，见汇报）：CjguiLinuxTextNodeView 不含 nodeKind，而绘制侧
//    用 nodeKind==MULTILINE 决定纵向起点；多行输入节点只有一行内容时本实现按单行
//    居中，差 (height-lineHeight)/2。消除它需要 session 侧在视图里补 nodeKind。
//
// 线程约定：与会话层一致，只允许在渲染会话所属线程调用。

#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cjgui_internal_renderer.h"
#include "cjgui_linux_services.h"
#include "cjgui_linux_text.h"

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------- 本地 ABI 声明
//
// caret / line_rect_count / line_rect_value / grapheme_cluster_range / visual_neighbor
// 的 Cangjie foreign 声明只存在于 .cj 侧，native/cjgui_internal_renderer.h 里没有（那份头
// 不在本次写集内），这里按 macOS 同款实现类型声明：
//   caret / line_rect_count → int32_t（macOS 侧同为 int32_t）
//   line_rect_value        → double
//   grapheme_cluster_range / visual_neighbor → CjguiInternalRendererStatus（macOS 侧同款）
// 返回类型与 .cj 的 Int32 在 ABI 上一致（enum 就是 int）。其余入口（position_v1 /
// stats_v1 / stop_resolve / stop_neighbor / composed_prefix）**已由 ABI 头声明**，
// 本文件按头文件的 CjguiInternalRendererStatus 定义，不重复声明。
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

// ---------------------------------------------------------------- 常量

// 与 session.c 绘制路径的 6pt 文字内缩一致（见文件头坐标约定）。
#define CJGUI_LINUX_TS_INSET_PT 6.0

// composed_prefix：与 macOS 侧一致的扫描窗口上限（超过即 INVALID_UTF8，不自行修补）。
#define CJGUI_LINUX_TS_CP_SCAN_LIMIT 2048u

// 单行停靠点枚举上限（超限具名 VISUAL_NAV_UNSUPPORTED，不做半行扫描）。
#define CJGUI_LINUX_TS_MAX_LINE_STOPS 1024u

// line_rect 的记忆容量（value() 的 4 次分量读取不再各自重算整段；超容量直接重算）。
#define CJGUI_LINUX_TS_RECT_MEMO 512u

// affinity（= v1 的 renderSide）：0=Upstream 1=Downstream 2=AUTO。
// 与 runtime_renderer_text_geometry_query.cj 的
// CJGUI_TEXT_AFFINITY_UPSTREAM/DOWNSTREAM/AUTO 常量一致（任务说明里 0/1/2 的名字写反了，
// 以 .cj 常量与 native/cjgui_internal_renderer.h 的 renderSide 注释为准）。
#define CJGUI_LINUX_TS_AFFINITY_UPSTREAM 0u
#define CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM 1u
#define CJGUI_LINUX_TS_AFFINITY_AUTO 2u

// v1 operation：0 resolve 1 hit 2 horizontal 3 vertical；direction：0=left/up 1=right/down。
#define CJGUI_LINUX_TS_OP_RESOLVE 0u
#define CJGUI_LINUX_TS_OP_HIT 1u
#define CJGUI_LINUX_TS_OP_HORIZONTAL 2u
#define CJGUI_LINUX_TS_OP_VERTICAL 3u

#define CJGUI_LINUX_TS_STATUS_OK ((CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_OK)

// ---------------------------------------------------------------- 进程内统计 / 记忆
//
// 会话层没有暴露计数器槽位（不改 session.c），因此 position_stats_v1 报的是**进程内**
// 累计值：同一进程的所有会话相加。语义在头文件与汇报里写明，不假装是每会话数字。

typedef struct CjguiLinuxTsCounters {
    uint64_t prepares;    // 成功解析出的节点排版上下文数
    uint64_t queries;     // 停靠点查询（position_v1）次数
    uint64_t lineBuilds;  // 行停靠点枚举次数
    uint64_t cacheHits;   // line_rect 记忆命中次数
} CjguiLinuxTsCounters;

static CjguiLinuxTsCounters g_ts_counters;

typedef struct CjguiLinuxTsRectMemo {
    int valid;
    uint64_t session;
    uint64_t nodeId;
    uint64_t sceneVersion;
    uint64_t lease;
    int64_t startByte;
    int64_t endByte;
    int32_t maxRects;
    uint32_t count;
    double rects[CJGUI_LINUX_TS_RECT_MEMO * 4u];
} CjguiLinuxTsRectMemo;

static CjguiLinuxTsRectMemo g_ts_rect_memo;

// ---------------------------------------------------------------- 杂项

static uint64_t cjgui_linux_ts_hash_bytes(uint64_t h, const void *data, size_t length) {
    const uint8_t *bytes = (const uint8_t *)data;
    size_t i = 0u;
    for (; i < length; i += 1u) {
        h ^= (uint64_t)bytes[i];
        h *= 1099511628211ull;
    }
    return h;
}

static uint64_t cjgui_linux_ts_hash_u64(uint64_t h, uint64_t value) {
    return cjgui_linux_ts_hash_bytes(h, &value, sizeof(value));
}

static uint64_t cjgui_linux_ts_hash_double(uint64_t h, double value) {
    uint64_t bits = 0u;
    memcpy(&bits, &value, sizeof(bits));
    return cjgui_linux_ts_hash_u64(h, bits);
}

static int cjgui_linux_ts_i64_fits_u32(int64_t value) {
    return value >= 0 && value <= (int64_t)UINT32_MAX;
}

// ---------------------------------------------------------------- UTF-8

// 严格解码：拒绝过长编码、代理区、> U+10FFFF、截断与孤立续字节。成功返回 1。
static int cjgui_linux_ts_utf8_decode(const char *utf8, size_t length, size_t pos,
                                      uint32_t *outCodepoint, size_t *outBytes) {
    uint8_t lead = (uint8_t)utf8[pos];
    uint32_t cp = 0u;
    size_t n = 0u;
    if (lead < 0x80u) {
        cp = lead;
        n = 1u;
    } else if ((lead & 0xE0u) == 0xC0u) {
        cp = (uint32_t)(lead & 0x1Fu);
        n = 2u;
    } else if ((lead & 0xF0u) == 0xE0u) {
        cp = (uint32_t)(lead & 0x0Fu);
        n = 3u;
    } else if ((lead & 0xF8u) == 0xF0u) {
        cp = (uint32_t)(lead & 0x07u);
        n = 4u;
    } else {
        return 0;
    }
    if (pos + n > length) return 0;
    size_t i = 1u;
    for (; i < n; i += 1u) {
        uint8_t cont = (uint8_t)utf8[pos + i];
        if ((cont & 0xC0u) != 0x80u) return 0;
        cp = (cp << 6) | (uint32_t)(cont & 0x3Fu);
    }
    if (n == 2u && cp < 0x80u) return 0;
    if (n == 3u && cp < 0x800u) return 0;
    if (n == 4u && cp < 0x10000u) return 0;
    if (cp > 0x10FFFFu) return 0;
    if (cp >= 0xD800u && cp <= 0xDFFFu) return 0;
    *outCodepoint = cp;
    *outBytes = n;
    return 1;
}

static int cjgui_linux_ts_utf8_valid(const char *utf8, size_t length) {
    size_t pos = 0u;
    while (pos < length) {
        uint32_t cp = 0u;
        size_t n = 0u;
        if (!cjgui_linux_ts_utf8_decode(utf8, length, pos, &cp, &n)) return 0;
        pos += n;
    }
    return 1;
}

// 该字节偏移是不是"标量边界"（0、length、或非续字节）。与 macOS 的
// CjguiStrictUtf8Boundary 同一口径：劈开标量的偏移在这里被拒。
static int cjgui_linux_ts_utf8_scalar_boundary(const char *utf8, size_t length, size_t offset) {
    if (offset > length) return 0;
    if (offset == 0u || offset == length) return 1;
    return ((uint8_t)utf8[offset] & 0xC0u) != 0x80u;
}

// 字节偏移 ⇒ UTF-16 码元下标（meta[6] 的口径）。要求 offset 是标量边界。
static uint64_t cjgui_linux_ts_utf16_units_before(const char *utf8, size_t length, size_t offset) {
    uint64_t units = 0u;
    size_t pos = 0u;
    while (pos < offset && pos < length) {
        uint32_t cp = 0u;
        size_t n = 0u;
        if (!cjgui_linux_ts_utf8_decode(utf8, length, pos, &cp, &n)) break;
        units += (cp >= 0x10000u) ? 2u : 1u;
        pos += n;
    }
    return units;
}

// ---------------------------------------------------------------- UAX#29 字素簇（简化实现）
//
// 覆盖 GB3/GB4/GB5（CRLF 与 Control 断）、GB6-GB8（Hangul 音节）、GB9（× Extend/ZWJ）、
// GB9a（× SpacingMark）、GB9b（Prepend ×）、GB11（ExtPict Extend* ZWJ × ExtPict）、
// GB12/GB13（区域指示符成对）、GB999（其余断）。
//
// 简化点（记录在案，不假装完整）：
//  * Extend 与 SpacingMark 合并成"组合记号"一张表（两者在 UAX#29 里都表示"不断"，
//    差别只在 GB11 的 Extend* 回溯；合并后只会更倾向于合并，不会误拆）；
//  * Extended_Pictographic 用主要 emoji 区段近似；
//  * 未实现 GB9c（Unicode 15.1 的 Indic 连字簇）；表外冷门区段按 Other 处理。

typedef enum CjguiLinuxTsGcb {
    CJGUI_LINUX_TS_GCB_OTHER = 0,
    CJGUI_LINUX_TS_GCB_CR,
    CJGUI_LINUX_TS_GCB_LF,
    CJGUI_LINUX_TS_GCB_CONTROL,
    CJGUI_LINUX_TS_GCB_EXTEND,
    CJGUI_LINUX_TS_GCB_ZWJ,
    CJGUI_LINUX_TS_GCB_RI,
    CJGUI_LINUX_TS_GCB_PREPEND,
    CJGUI_LINUX_TS_GCB_L,
    CJGUI_LINUX_TS_GCB_V,
    CJGUI_LINUX_TS_GCB_T,
    CJGUI_LINUX_TS_GCB_LV,
    CJGUI_LINUX_TS_GCB_LVT
} CjguiLinuxTsGcb;

typedef struct CjguiLinuxTsRange {
    uint32_t lo;
    uint32_t hi;
} CjguiLinuxTsRange;

// 组合记号（Grapheme_Extend=Yes 的常用区段 + SpacingMark=Yes 的主要区段 + Emoji_Modifier
// + 变体选择符）。线性扫描并利用升序提前退出；表有序是维护要求。
static const CjguiLinuxTsRange k_ts_combining_ranges[] = {
    { 0x0300u, 0x036Fu },   { 0x0483u, 0x0489u },   { 0x0591u, 0x05BDu },   { 0x05BFu, 0x05BFu },
    { 0x05C1u, 0x05C2u },   { 0x05C4u, 0x05C5u },   { 0x05C7u, 0x05C7u },   { 0x0610u, 0x061Au },
    { 0x064Bu, 0x065Fu },   { 0x0670u, 0x0670u },   { 0x06D6u, 0x06DCu },   { 0x06DFu, 0x06E4u },
    { 0x06E7u, 0x06E8u },   { 0x06EAu, 0x06EDu },   { 0x0711u, 0x0711u },   { 0x0730u, 0x074Au },
    { 0x07A6u, 0x07B0u },   { 0x07EBu, 0x07F3u },   { 0x0816u, 0x0819u },   { 0x081Bu, 0x0823u },
    { 0x0825u, 0x0827u },   { 0x0829u, 0x082Du },   { 0x0859u, 0x085Bu },   { 0x08D3u, 0x08E1u },
    { 0x08E3u, 0x0903u },   { 0x093Au, 0x093Cu },   { 0x093Eu, 0x094Fu },   { 0x0951u, 0x0957u },
    { 0x0962u, 0x0963u },   { 0x0981u, 0x0983u },   { 0x09BCu, 0x09BCu },   { 0x09BEu, 0x09C4u },
    { 0x09C7u, 0x09C8u },   { 0x09CBu, 0x09CDu },   { 0x09D7u, 0x09D7u },   { 0x09E2u, 0x09E3u },
    { 0x0A01u, 0x0A03u },   { 0x0A3Cu, 0x0A3Cu },   { 0x0A3Eu, 0x0A42u },   { 0x0A47u, 0x0A48u },
    { 0x0A4Bu, 0x0A4Du },   { 0x0A51u, 0x0A51u },   { 0x0A70u, 0x0A71u },   { 0x0A75u, 0x0A75u },
    { 0x0A81u, 0x0A83u },   { 0x0ABCu, 0x0ABCu },   { 0x0ABEu, 0x0AC5u },   { 0x0AC7u, 0x0AC9u },
    { 0x0ACBu, 0x0ACDu },   { 0x0AE2u, 0x0AE3u },   { 0x0B01u, 0x0B03u },   { 0x0B3Cu, 0x0B3Cu },
    { 0x0B3Eu, 0x0B44u },   { 0x0B47u, 0x0B48u },   { 0x0B4Bu, 0x0B4Du },   { 0x0B55u, 0x0B57u },
    { 0x0B62u, 0x0B63u },   { 0x0B82u, 0x0B82u },   { 0x0BBEu, 0x0BC2u },   { 0x0BC6u, 0x0BC8u },
    { 0x0BCAu, 0x0BCDu },   { 0x0BD7u, 0x0BD7u },   { 0x0C00u, 0x0C04u },   { 0x0C3Eu, 0x0C44u },
    { 0x0C46u, 0x0C48u },   { 0x0C4Au, 0x0C4Du },   { 0x0C55u, 0x0C56u },   { 0x0C62u, 0x0C63u },
    { 0x0C81u, 0x0C83u },   { 0x0CBCu, 0x0CBCu },   { 0x0CBEu, 0x0CC4u },   { 0x0CC6u, 0x0CC8u },
    { 0x0CCAu, 0x0CCDu },   { 0x0CD5u, 0x0CD6u },   { 0x0CE2u, 0x0CE3u },   { 0x0D00u, 0x0D03u },
    { 0x0D3Bu, 0x0D3Cu },   { 0x0D3Eu, 0x0D44u },   { 0x0D46u, 0x0D48u },   { 0x0D4Au, 0x0D4Du },
    { 0x0D57u, 0x0D57u },   { 0x0D62u, 0x0D63u },   { 0x0D81u, 0x0D83u },   { 0x0DCAu, 0x0DCAu },
    { 0x0DCFu, 0x0DD4u },   { 0x0DD6u, 0x0DD6u },   { 0x0DD8u, 0x0DDFu },   { 0x0DF2u, 0x0DF3u },
    { 0x0E31u, 0x0E31u },   { 0x0E34u, 0x0E3Au },   { 0x0E47u, 0x0E4Eu },   { 0x0EB1u, 0x0EB1u },
    { 0x0EB4u, 0x0EBCu },   { 0x0EC8u, 0x0ECDu },   { 0x0F18u, 0x0F19u },   { 0x0F35u, 0x0F35u },
    { 0x0F37u, 0x0F37u },   { 0x0F39u, 0x0F39u },   { 0x0F3Eu, 0x0F3Fu },   { 0x0F71u, 0x0F84u },
    { 0x0F86u, 0x0F87u },   { 0x0F8Du, 0x0F97u },   { 0x0F99u, 0x0FBCu },   { 0x0FC6u, 0x0FC6u },
    { 0x102Bu, 0x103Eu },   { 0x1056u, 0x1059u },   { 0x105Eu, 0x1060u },   { 0x1062u, 0x1064u },
    { 0x1067u, 0x106Du },   { 0x1071u, 0x1074u },   { 0x1082u, 0x108Du },   { 0x108Fu, 0x108Fu },
    { 0x109Au, 0x109Du },   { 0x135Du, 0x135Fu },   { 0x1712u, 0x1715u },   { 0x1732u, 0x1734u },
    { 0x1752u, 0x1753u },   { 0x1772u, 0x1773u },   { 0x17B4u, 0x17D3u },   { 0x17DDu, 0x17DDu },
    { 0x180Bu, 0x180Du },   { 0x1885u, 0x1886u },   { 0x18A9u, 0x18A9u },   { 0x1920u, 0x192Bu },
    { 0x1930u, 0x193Bu },   { 0x1A17u, 0x1A1Bu },   { 0x1A55u, 0x1A5Eu },   { 0x1A60u, 0x1A7Cu },
    { 0x1A7Fu, 0x1A7Fu },   { 0x1AB0u, 0x1ACEu },   { 0x1B00u, 0x1B04u },   { 0x1B34u, 0x1B44u },
    { 0x1B6Bu, 0x1B73u },   { 0x1B80u, 0x1B82u },   { 0x1BA1u, 0x1BADu },   { 0x1BE6u, 0x1BF3u },
    { 0x1C24u, 0x1C37u },   { 0x1CD0u, 0x1CD2u },   { 0x1CD4u, 0x1CE8u },   { 0x1CEDu, 0x1CEDu },
    { 0x1CF4u, 0x1CF4u },   { 0x1CF7u, 0x1CF9u },   { 0x1DC0u, 0x1DFFu },   { 0x20D0u, 0x20F0u },
    { 0x2CEFu, 0x2CF1u },   { 0x2D7Fu, 0x2D7Fu },   { 0x2DE0u, 0x2DFFu },   { 0x302Au, 0x302Fu },
    { 0x3099u, 0x309Au },   { 0xA66Fu, 0xA672u },   { 0xA674u, 0xA67Du },   { 0xA69Eu, 0xA69Fu },
    { 0xA6F0u, 0xA6F1u },   { 0xA802u, 0xA802u },   { 0xA806u, 0xA806u },   { 0xA80Bu, 0xA80Bu },
    { 0xA823u, 0xA827u },   { 0xA880u, 0xA881u },   { 0xA8B4u, 0xA8C5u },   { 0xA8E0u, 0xA8F1u },
    { 0xA926u, 0xA92Du },   { 0xA947u, 0xA953u },   { 0xA980u, 0xA983u },   { 0xA9B3u, 0xA9C0u },
    { 0xA9E5u, 0xA9E5u },   { 0xAA29u, 0xAA36u },   { 0xAA43u, 0xAA43u },   { 0xAA4Cu, 0xAA4Du },
    { 0xAA7Bu, 0xAA7Du },   { 0xAAB0u, 0xAAB0u },   { 0xAAB2u, 0xAAB4u },   { 0xAAB7u, 0xAAB8u },
    { 0xAABEu, 0xAABFu },   { 0xAAC1u, 0xAAC1u },   { 0xAAEBu, 0xAAEFu },   { 0xAAF5u, 0xAAF6u },
    { 0xABE3u, 0xABEAu },   { 0xABECu, 0xABEDu },   { 0xFB1Eu, 0xFB1Eu },   { 0xFE00u, 0xFE0Fu },
    { 0xFE20u, 0xFE2Fu },   { 0x101FDu, 0x101FDu }, { 0x102E0u, 0x102E0u }, { 0x10376u, 0x1037Au },
    { 0x10A01u, 0x10A03u }, { 0x10A05u, 0x10A06u }, { 0x10A0Cu, 0x10A0Fu }, { 0x10A38u, 0x10A3Au },
    { 0x10A3Fu, 0x10A3Fu }, { 0x10AE5u, 0x10AE6u }, { 0x10D24u, 0x10D27u }, { 0x10EABu, 0x10EACu },
    { 0x10F46u, 0x10F50u }, { 0x11000u, 0x11002u }, { 0x11038u, 0x11046u }, { 0x1107Fu, 0x11082u },
    { 0x110B0u, 0x110BAu }, { 0x11100u, 0x11102u }, { 0x11127u, 0x11134u }, { 0x11145u, 0x11146u },
    { 0x11173u, 0x11173u }, { 0x11180u, 0x11182u }, { 0x111B3u, 0x111C0u }, { 0x111C9u, 0x111CCu },
    { 0x1122Cu, 0x11237u }, { 0x1123Eu, 0x1123Eu }, { 0x112DFu, 0x112EAu }, { 0x11300u, 0x11303u },
    { 0x1133Bu, 0x1133Cu }, { 0x1133Eu, 0x11344u }, { 0x11347u, 0x11348u }, { 0x1134Bu, 0x1134Du },
    { 0x11357u, 0x11357u }, { 0x11362u, 0x11363u }, { 0x11435u, 0x11446u }, { 0x1145Eu, 0x1145Eu },
    { 0x114B0u, 0x114C3u }, { 0x115AFu, 0x115B5u }, { 0x115B8u, 0x115C0u }, { 0x115DCu, 0x115DDu },
    { 0x11630u, 0x11640u }, { 0x116ABu, 0x116B7u }, { 0x1171Du, 0x1172Bu }, { 0x1182Cu, 0x1183Au },
    { 0x11930u, 0x11935u }, { 0x11937u, 0x11938u }, { 0x1193Bu, 0x1193Eu }, { 0x11940u, 0x11940u },
    { 0x11942u, 0x11943u }, { 0x119D1u, 0x119D7u }, { 0x119DAu, 0x119E0u }, { 0x119E4u, 0x119E4u },
    { 0x11A01u, 0x11A0Au }, { 0x11A33u, 0x11A39u }, { 0x11A3Bu, 0x11A3Eu }, { 0x11A47u, 0x11A47u },
    { 0x11A51u, 0x11A5Bu }, { 0x11A8Au, 0x11A99u }, { 0x11C2Fu, 0x11C36u }, { 0x11C38u, 0x11C3Fu },
    { 0x11C92u, 0x11CA7u }, { 0x11CA9u, 0x11CB6u }, { 0x11D31u, 0x11D36u }, { 0x11D3Au, 0x11D3Au },
    { 0x11D3Cu, 0x11D3Du }, { 0x11D3Fu, 0x11D45u }, { 0x11D47u, 0x11D47u }, { 0x11D8Au, 0x11D97u },
    { 0x11EF3u, 0x11EF6u }, { 0x16AF0u, 0x16AF4u }, { 0x16B30u, 0x16B36u }, { 0x16F4Fu, 0x16F4Fu },
    { 0x16F51u, 0x16F87u }, { 0x16F8Fu, 0x16F92u }, { 0x16FE4u, 0x16FE4u }, { 0x1BC9Du, 0x1BC9Eu },
    { 0x1D165u, 0x1D169u }, { 0x1D16Du, 0x1D172u }, { 0x1D17Bu, 0x1D182u }, { 0x1D185u, 0x1D18Bu },
    { 0x1D1AAu, 0x1D1ADu }, { 0x1D242u, 0x1D244u }, { 0x1DA00u, 0x1DA36u }, { 0x1DA3Bu, 0x1DA6Cu },
    { 0x1DA75u, 0x1DA75u }, { 0x1DA84u, 0x1DA84u }, { 0x1DA9Bu, 0x1DA9Fu }, { 0x1DAA1u, 0x1DAAFu },
    { 0x1E000u, 0x1E006u }, { 0x1E008u, 0x1E018u }, { 0x1E01Bu, 0x1E021u }, { 0x1E023u, 0x1E024u },
    { 0x1E026u, 0x1E02Au }, { 0x1E130u, 0x1E136u }, { 0x1E2AEu, 0x1E2AEu }, { 0x1E2ECu, 0x1E2EFu },
    { 0x1E8D0u, 0x1E8D6u }, { 0x1E944u, 0x1E94Au }, { 0x1F3FBu, 0x1F3FFu }, { 0xE0100u, 0xE01EFu }
};

static int cjgui_linux_ts_cp_is_combining(uint32_t cp) {
    size_t i = 0u;
    size_t n = sizeof(k_ts_combining_ranges) / sizeof(k_ts_combining_ranges[0]);
    for (; i < n; i += 1u) {
        if (cp < k_ts_combining_ranges[i].lo) return 0;   // 表按 lo 升序 ⇒ 提前退出
        if (cp <= k_ts_combining_ranges[i].hi) return 1;
    }
    return 0;
}

// Prepend（GB9b 的左操作数）。
static int cjgui_linux_ts_cp_is_prepend(uint32_t cp) {
    if (cp >= 0x0600u && cp <= 0x0605u) return 1;
    if (cp == 0x06DDu || cp == 0x070Fu) return 1;
    if (cp >= 0x0890u && cp <= 0x0891u) return 1;
    if (cp == 0x08E2u || cp == 0x0D4Eu) return 1;
    if (cp == 0x110BDu || cp == 0x110CDu) return 1;
    if (cp >= 0x111C2u && cp <= 0x111C3u) return 1;
    if (cp == 0x1193Fu || cp == 0x11941u || cp == 0x11A3Au || cp == 0x11D46u) return 1;
    if (cp >= 0x11A84u && cp <= 0x11A89u) return 1;
    if (cp == 0x11F02u) return 1;
    return 0;
}

// Control（GB4/GB5 的 Cc/Cf/Zl/Zp；ZWJ 与 ZWNJ 除外，各有自己的类别）。
static int cjgui_linux_ts_cp_is_control(uint32_t cp) {
    if (cp <= 0x001Fu) return 1;
    if (cp >= 0x007Fu && cp <= 0x009Fu) return 1;
    if (cp == 0x00ADu || cp == 0x061Cu || cp == 0x180Eu) return 1;
    if (cp >= 0x200Bu && cp <= 0x200Fu && cp != 0x200Cu && cp != 0x200Du) return 1;
    if (cp >= 0x2028u && cp <= 0x202Eu) return 1;
    if (cp >= 0x2060u && cp <= 0x2064u) return 1;
    if (cp >= 0x2066u && cp <= 0x206Fu) return 1;
    if (cp == 0xFEFFu) return 1;
    if (cp >= 0xFFF9u && cp <= 0xFFFBu) return 1;
    if (cp >= 0x1BCA0u && cp <= 0x1BCA3u) return 1;
    if (cp >= 0x1D173u && cp <= 0x1D17Au) return 1;
    if (cp == 0xE0001u) return 1;
    if (cp >= 0xE0020u && cp <= 0xE007Fu) return 1;
    return 0;
}

// Extended_Pictographic（GB11 的近似：BMP 图形字符 + 主要 emoji 区段）。
static int cjgui_linux_ts_cp_is_extended_pictographic(uint32_t cp) {
    if (cp == 0x00A9u || cp == 0x00AEu || cp == 0x203Cu || cp == 0x2049u) return 1;
    if (cp == 0x2122u || cp == 0x2139u) return 1;
    if (cp >= 0x2194u && cp <= 0x2199u) return 1;
    if (cp >= 0x21A9u && cp <= 0x21AAu) return 1;
    if (cp >= 0x231Au && cp <= 0x231Bu) return 1;
    if (cp == 0x2328u || cp == 0x2388u || cp == 0x23CFu) return 1;
    if (cp >= 0x23E9u && cp <= 0x23F3u) return 1;
    if (cp >= 0x23F8u && cp <= 0x23FAu) return 1;
    if (cp == 0x24C2u) return 1;
    if (cp >= 0x25AAu && cp <= 0x25ABu) return 1;
    if (cp == 0x25B6u || cp == 0x25C0u) return 1;
    if (cp >= 0x25FBu && cp <= 0x25FEu) return 1;
    if (cp >= 0x2600u && cp <= 0x2605u) return 1;
    if (cp >= 0x2607u && cp <= 0x2612u) return 1;
    if (cp >= 0x2614u && cp <= 0x2685u) return 1;
    if (cp >= 0x2690u && cp <= 0x2705u) return 1;
    if (cp >= 0x2708u && cp <= 0x2712u) return 1;
    if (cp == 0x2714u || cp == 0x2716u || cp == 0x271Du || cp == 0x2721u || cp == 0x2728u) return 1;
    if (cp >= 0x2733u && cp <= 0x2734u) return 1;
    if (cp == 0x2744u || cp == 0x2747u || cp == 0x274Cu || cp == 0x274Eu) return 1;
    if (cp >= 0x2753u && cp <= 0x2755u) return 1;
    if (cp == 0x2757u) return 1;
    if (cp >= 0x2763u && cp <= 0x2767u) return 1;
    if (cp >= 0x2795u && cp <= 0x2797u) return 1;
    if (cp == 0x27A1u || cp == 0x27B0u || cp == 0x27BFu) return 1;
    if (cp >= 0x2934u && cp <= 0x2935u) return 1;
    if (cp >= 0x2B05u && cp <= 0x2B07u) return 1;
    if (cp >= 0x2B1Bu && cp <= 0x2B1Cu) return 1;
    if (cp == 0x2B50u || cp == 0x2B55u || cp == 0x3030u || cp == 0x303Du) return 1;
    if (cp == 0x3297u || cp == 0x3299u) return 1;
    if (cp >= 0x1F000u && cp <= 0x1F0FFu) return 1;
    if (cp >= 0x1F10Du && cp <= 0x1F10Fu) return 1;
    if (cp == 0x1F12Fu) return 1;
    if (cp >= 0x1F16Cu && cp <= 0x1F171u) return 1;
    if (cp >= 0x1F17Eu && cp <= 0x1F17Fu) return 1;
    if (cp == 0x1F18Eu) return 1;
    if (cp >= 0x1F191u && cp <= 0x1F19Au) return 1;
    if (cp >= 0x1F1ADu && cp <= 0x1F1E5u) return 1;
    if (cp >= 0x1F201u && cp <= 0x1F20Fu) return 1;
    if (cp == 0x1F21Au || cp == 0x1F22Fu) return 1;
    if (cp >= 0x1F232u && cp <= 0x1F23Au) return 1;
    if (cp >= 0x1F23Cu && cp <= 0x1F23Fu) return 1;
    if (cp >= 0x1F249u && cp <= 0x1F3FAu) return 1;
    if (cp >= 0x1F400u && cp <= 0x1F53Du) return 1;
    if (cp >= 0x1F546u && cp <= 0x1F64Fu) return 1;
    if (cp >= 0x1F680u && cp <= 0x1F6FFu) return 1;
    if (cp >= 0x1F774u && cp <= 0x1F77Fu) return 1;
    if (cp >= 0x1F7D5u && cp <= 0x1F7FFu) return 1;
    if (cp >= 0x1F80Cu && cp <= 0x1F80Fu) return 1;
    if (cp >= 0x1F848u && cp <= 0x1F84Fu) return 1;
    if (cp >= 0x1F85Au && cp <= 0x1F85Fu) return 1;
    if (cp >= 0x1F888u && cp <= 0x1F88Fu) return 1;
    if (cp >= 0x1F8AEu && cp <= 0x1F8FFu) return 1;
    if (cp >= 0x1F90Cu && cp <= 0x1F93Au) return 1;
    if (cp >= 0x1F93Cu && cp <= 0x1F945u) return 1;
    if (cp >= 0x1F947u && cp <= 0x1FAFFu) return 1;
    if (cp >= 0x1FC00u && cp <= 0x1FFFDu) return 1;
    return 0;
}

static CjguiLinuxTsGcb cjgui_linux_ts_gcb_class(uint32_t cp) {
    if (cp == 0x000Du) return CJGUI_LINUX_TS_GCB_CR;
    if (cp == 0x000Au) return CJGUI_LINUX_TS_GCB_LF;
    if (cp == 0x200Du) return CJGUI_LINUX_TS_GCB_ZWJ;
    if (cjgui_linux_ts_cp_is_control(cp)) return CJGUI_LINUX_TS_GCB_CONTROL;
    if (cjgui_linux_ts_cp_is_combining(cp)) return CJGUI_LINUX_TS_GCB_EXTEND;
    if (cp >= 0x1F1E6u && cp <= 0x1F1FFu) return CJGUI_LINUX_TS_GCB_RI;
    if (cjgui_linux_ts_cp_is_prepend(cp)) return CJGUI_LINUX_TS_GCB_PREPEND;
    // Hangul
    if ((cp >= 0x1100u && cp <= 0x115Fu) || (cp >= 0xA960u && cp <= 0xA97Cu)) return CJGUI_LINUX_TS_GCB_L;
    if ((cp >= 0x1160u && cp <= 0x11A7u) || (cp >= 0xD7B0u && cp <= 0xD7C6u)) return CJGUI_LINUX_TS_GCB_V;
    if ((cp >= 0x11A8u && cp <= 0x11FFu) || (cp >= 0xD7CBu && cp <= 0xD7FBu)) return CJGUI_LINUX_TS_GCB_T;
    if (cp >= 0xAC00u && cp <= 0xD7A3u) {
        return ((cp - 0xAC00u) % 28u == 0u) ? CJGUI_LINUX_TS_GCB_LV : CJGUI_LINUX_TS_GCB_LVT;
    }
    return CJGUI_LINUX_TS_GCB_OTHER;
}

typedef struct CjguiLinuxTsCluster {
    size_t start;
    size_t end;
} CjguiLinuxTsCluster;

// 从 pos（必须是簇起点）出发求该簇的结尾字节。utf8 必须已通过合法性检查。
static size_t cjgui_linux_ts_cluster_end_from(const char *utf8, size_t length, size_t pos) {
    uint32_t prev_cp = 0u;
    size_t prev_bytes = 0u;
    if (!cjgui_linux_ts_utf8_decode(utf8, length, pos, &prev_cp, &prev_bytes)) return pos + 1u;
    CjguiLinuxTsGcb prev = cjgui_linux_ts_gcb_class(prev_cp);
    uint32_t ri_run = (prev == CJGUI_LINUX_TS_GCB_RI) ? 1u : 0u;
    // pict_mod: 0=无 1=ExtPict Extend* 2=ExtPict Extend* ZWJ（GB11 的回溯状态）
    uint32_t pict_mod = cjgui_linux_ts_cp_is_extended_pictographic(prev_cp) ? 1u : 0u;
    size_t at = pos + prev_bytes;
    while (at < length) {
        uint32_t cp = 0u;
        size_t n = 0u;
        if (!cjgui_linux_ts_utf8_decode(utf8, length, at, &cp, &n)) break;
        CjguiLinuxTsGcb cur = cjgui_linux_ts_gcb_class(cp);
        int join = 0;
        if (prev == CJGUI_LINUX_TS_GCB_CR && cur == CJGUI_LINUX_TS_GCB_LF) {
            join = 1;                                              // GB3
        } else if (prev == CJGUI_LINUX_TS_GCB_CONTROL || prev == CJGUI_LINUX_TS_GCB_CR ||
                   prev == CJGUI_LINUX_TS_GCB_LF) {
            join = 0;                                              // GB4
        } else if (cur == CJGUI_LINUX_TS_GCB_CONTROL || cur == CJGUI_LINUX_TS_GCB_CR ||
                   cur == CJGUI_LINUX_TS_GCB_LF) {
            join = 0;                                              // GB5
        } else if (prev == CJGUI_LINUX_TS_GCB_L &&
                   (cur == CJGUI_LINUX_TS_GCB_L || cur == CJGUI_LINUX_TS_GCB_V ||
                    cur == CJGUI_LINUX_TS_GCB_LV || cur == CJGUI_LINUX_TS_GCB_LVT)) {
            join = 1;                                              // GB6
        } else if ((prev == CJGUI_LINUX_TS_GCB_LV || prev == CJGUI_LINUX_TS_GCB_V) &&
                   (cur == CJGUI_LINUX_TS_GCB_V || cur == CJGUI_LINUX_TS_GCB_T)) {
            join = 1;                                              // GB7
        } else if ((prev == CJGUI_LINUX_TS_GCB_LVT || prev == CJGUI_LINUX_TS_GCB_T) &&
                   cur == CJGUI_LINUX_TS_GCB_T) {
            join = 1;                                              // GB8
        } else if (cur == CJGUI_LINUX_TS_GCB_EXTEND || cur == CJGUI_LINUX_TS_GCB_ZWJ) {
            join = 1;                                              // GB9（含 GB9a 合并的 SpacingMark）
        } else if (prev == CJGUI_LINUX_TS_GCB_PREPEND) {
            join = 1;                                              // GB9b
        } else if (pict_mod == 2u && cjgui_linux_ts_cp_is_extended_pictographic(cp)) {
            join = 1;                                              // GB11
        } else if (prev == CJGUI_LINUX_TS_GCB_RI && cur == CJGUI_LINUX_TS_GCB_RI &&
                   (ri_run % 2u) == 1u) {
            join = 1;                                              // GB12/GB13
        }
        if (!join) break;
        // 更新回溯状态
        if (cur == CJGUI_LINUX_TS_GCB_RI) {
            ri_run += 1u;
        } else {
            ri_run = 0u;
        }
        if (cjgui_linux_ts_cp_is_extended_pictographic(cp)) {
            pict_mod = 1u;
        } else if (cur == CJGUI_LINUX_TS_GCB_EXTEND) {
            /* 保持 pict_mod：ExtPict Extend* 仍然成立 */
        } else if (cur == CJGUI_LINUX_TS_GCB_ZWJ) {
            pict_mod = (pict_mod == 1u) ? 2u : 0u;
        } else {
            pict_mod = 0u;
        }
        prev = cur;
        at += n;
    }
    return at;
}

// 求包含 offset 的簇 [start,end)。offset 必须落在 [0,length)。utf8 必须合法。
static void cjgui_linux_ts_cluster_containing(const char *utf8, size_t length, size_t offset,
                                             CjguiLinuxTsCluster *out) {
    size_t start = 0u;
    for (;;) {
        size_t end = cjgui_linux_ts_cluster_end_from(utf8, length, start);
        if (end <= start) end = (start < length) ? (start + 1u) : length;  // 防御：绝不空转
        if (offset < end || end >= length) {
            out->start = start;
            out->end = end;
            return;
        }
        start = end;
    }
}

// offset 是否恰是字素簇边界。length==0 时只有 0 是边界（文本尾）。
static int cjgui_linux_ts_is_cluster_boundary(const char *utf8, size_t length, size_t offset) {
    if (offset > length) return 0;
    if (offset == 0u || offset == length) return 1;
    CjguiLinuxTsCluster cluster;
    cjgui_linux_ts_cluster_containing(utf8, length, offset, &cluster);
    return cluster.start == offset;
}

// ---------------------------------------------------------------- 会话 / 节点 / 排版上下文

typedef struct CjguiLinuxTsContext {
    CjguiLinuxText *text;
    const char *utf8;
    size_t length;
    double fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;
    double maxWidth;     // <=0 ⇒ 不限宽（只有显式 '\n' 换行）
    double originX;      // 文字块原点（窗口内容逻辑点）
    double originY;
    double lineHeight;
    uint32_t lineCount;  // 有效行数：空文本按 1 行退化处理
    uint64_t lease;      // 该 accepted 排版的确定性身份（不是指针）
} CjguiLinuxTsContext;

// 会话 + 场景版本门：11（令牌无效）/ 33（调用方携带的 accepted 版本已过期）。
// 与 macOS 的 CjguiTextPositionImpl 一致，先于 op/节点检查。
static CjguiInternalRendererStatus cjgui_linux_ts_session_gate(uint64_t session,
                                                              uint64_t expectedSceneVersion) {
    if (!cjgui_linux_session_text(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    uint64_t scene = cjgui_linux_session_scene_version(session);
    if (expectedSceneVersion != 0u && scene != expectedSceneVersion) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 解析会话/场景/节点，并算出与绘制路径同一套的排版参数。失败返回具名状态。
static CjguiInternalRendererStatus cjgui_linux_ts_context(uint64_t session, uint64_t nodeId,
                                                          uint64_t expectedSceneVersion,
                                                          CjguiLinuxTsContext *out) {
    memset(out, 0, sizeof(*out));
    CjguiInternalRendererStatus gate = cjgui_linux_ts_session_gate(session, expectedSceneVersion);
    if (gate != CJGUI_INTERNAL_RENDERER_OK) return gate;
    CjguiLinuxText *text = cjgui_linux_session_text(session);
    uint64_t scene = cjgui_linux_session_scene_version(session);
    CjguiLinuxTextNodeView view;
    memset(&view, 0, sizeof(view));
    cjgui_linux_session_text_node_view(session, nodeId, &view);
    if (!view.found) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    const char *utf8 = view.text ? view.text : "";
    size_t length = strlen(utf8);
    if (!cjgui_linux_ts_utf8_valid(utf8, length)) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;

    double fontSize = (view.fontSize > 0.0) ? view.fontSize : 14.0;
    double innerWidth = (double)view.width - 2.0 * CJGUI_LINUX_TS_INSET_PT;
    if (innerWidth < 0.0) innerWidth = 0.0;
    double lineHeight =
        cjgui_linux_text_line_height(text, fontSize, view.fontWeight, view.fontFamily);
    if (!(lineHeight > 0.0)) lineHeight = fontSize * 1.2;
    uint32_t lines = 0u;
    if (cjgui_linux_text_line_count(text, utf8, length, fontSize, view.fontWeight, view.fontFamily,
                                    innerWidth, &lines) != CJGUI_LINUX_TEXT_OK) {
        return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    }
    // 与绘制路径一致：单行在节点内垂直居中，多行从节点顶部 +3pt 起排。
    double localY = (lines <= 1u) ? (((double)view.height - lineHeight) * 0.5)
                                  : (CJGUI_LINUX_TS_INSET_PT * 0.5);
    if (localY < 0.0) localY = 0.0;

    out->text = text;
    out->utf8 = utf8;
    out->length = length;
    out->fontSize = fontSize;
    out->fontWeight = view.fontWeight;
    out->fontFamily = view.fontFamily;
    out->maxWidth = innerWidth;
    out->originX = (double)view.x + CJGUI_LINUX_TS_INSET_PT;
    out->originY = (double)view.y + localY;
    out->lineHeight = lineHeight;
    out->lineCount = (lines == 0u) ? 1u : lines;

    uint64_t lease = 1469598103934665603ull;
    lease = cjgui_linux_ts_hash_u64(lease, (uint64_t)view.nodeId);
    lease = cjgui_linux_ts_hash_u64(lease, scene);
    lease = cjgui_linux_ts_hash_bytes(lease, utf8, length);
    lease = cjgui_linux_ts_hash_double(lease, fontSize);
    lease = cjgui_linux_ts_hash_u64(lease, (uint64_t)view.fontWeight);
    lease = cjgui_linux_ts_hash_u64(lease, (uint64_t)view.fontFamily);
    lease = cjgui_linux_ts_hash_double(lease, innerWidth);
    lease = cjgui_linux_ts_hash_u64(lease, (uint64_t)view.width);
    lease = cjgui_linux_ts_hash_u64(lease, (uint64_t)view.height);
    out->lease = lease | 1ull;   // 0 留作"无租约"，身份一律非零

    g_ts_counters.prepares += 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 停靠点解析

typedef struct CjguiLinuxTsCaret {
    double x;             // 文本块局部
    double top;           // 文本块局部
    double lineHeight;
    uint32_t lineIndex;
    size_t lineStartByte;
    size_t lineEndByte;
    uint32_t renderSide;  // 0=Upstream（软折行的上一行行末别名）1=Downstream
} CjguiLinuxTsCaret;

// 点查询的字节校验：越界/劈开标量/不是字素簇边界 ⇒ 34（不吸附洗白）。
static CjguiInternalRendererStatus cjgui_linux_ts_validate_point(const CjguiLinuxTsContext *ctx,
                                                                 int64_t displayByte,
                                                                 size_t *outByte) {
    if (displayByte < 0) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    size_t byte = (size_t)displayByte;
    if (byte > ctx->length) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    if (!cjgui_linux_ts_utf8_scalar_boundary(ctx->utf8, ctx->length, byte)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    if (!cjgui_linux_ts_is_cluster_boundary(ctx->utf8, ctx->length, byte)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    *outByte = byte;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 解析一个插入点。affinity：0=Upstream 1=Downstream 2=AUTO。
// Upstream 只在"软折行边界"上存在别名（上一行的行末，x=上一行行宽）；其余位置
// 两端是同一个停靠点，就地下沉为 Downstream（本平台没有 bidi 的独立分支）。
static CjguiInternalRendererStatus cjgui_linux_ts_caret_resolve(const CjguiLinuxTsContext *ctx,
                                                               size_t byte, uint32_t affinity,
                                                               CjguiLinuxTsCaret *out) {
    double x = 0.0, top = 0.0, lineHeight = 0.0;
    uint32_t lineIndex = 0u;
    size_t lineStart = 0u, lineEnd = 0u;
    int status = cjgui_linux_text_caret_position(
        ctx->text, ctx->utf8, ctx->length, ctx->fontSize, ctx->fontWeight, ctx->fontFamily,
        ctx->maxWidth, byte, &x, &top, &lineHeight, &lineIndex, &lineStart, &lineEnd);
    if (status != CJGUI_LINUX_TEXT_OK) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    out->x = x;
    out->top = top;
    out->lineHeight = (lineHeight > 0.0) ? lineHeight : ctx->lineHeight;
    out->lineIndex = lineIndex;
    out->lineStartByte = lineStart;
    out->lineEndByte = lineEnd;
    out->renderSide = CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM;

    if (affinity != CJGUI_LINUX_TS_AFFINITY_UPSTREAM) return CJGUI_INTERNAL_RENDERER_OK;
    if (byte == 0u || lineIndex == 0u || byte != lineStart) return CJGUI_INTERNAL_RENDERER_OK;
    double prevX = 0.0, prevY = 0.0, prevWidth = 0.0, prevHeight = 0.0;
    size_t prevStart = 0u, prevEnd = 0u;
    status = cjgui_linux_text_line_rect(ctx->text, ctx->utf8, ctx->length, ctx->fontSize,
                                        ctx->fontWeight, ctx->fontFamily, ctx->maxWidth,
                                        lineIndex - 1u, &prevX, &prevY, &prevWidth, &prevHeight,
                                        &prevStart, &prevEnd);
    if (status != CJGUI_LINUX_TEXT_OK) return CJGUI_INTERNAL_RENDERER_OK;   // 保持 Downstream
    // 软折行：上一行恰在同一個字节上结束（中间没有消耗任何换行字节）。
    if (prevEnd != byte) return CJGUI_INTERNAL_RENDERER_OK;
    out->x = prevX + prevWidth;
    out->top = prevY;
    out->lineHeight = (prevHeight > 0.0) ? prevHeight : out->lineHeight;
    out->lineIndex = lineIndex - 1u;
    out->lineStartByte = prevStart;
    out->lineEndByte = prevEnd;
    out->renderSide = CJGUI_LINUX_TS_AFFINITY_UPSTREAM;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 取行的字节范围与宽度；失败返回具名状态。
static CjguiInternalRendererStatus cjgui_linux_ts_line_box(const CjguiLinuxTsContext *ctx,
                                                           uint32_t lineIndex, double *outY,
                                                           double *outWidth, double *outHeight,
                                                           size_t *outStart, size_t *outEnd) {
    double x = 0.0, y = 0.0, w = 0.0, h = 0.0;
    size_t start = 0u, end = 0u;
    int status = cjgui_linux_text_line_rect(ctx->text, ctx->utf8, ctx->length, ctx->fontSize,
                                            ctx->fontWeight, ctx->fontFamily, ctx->maxWidth,
                                            lineIndex, &x, &y, &w, &h, &start, &end);
    if (status != CJGUI_LINUX_TEXT_OK) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    if (outY) *outY = y;
    if (outWidth) *outWidth = w;
    if (outHeight) *outHeight = (h > 0.0) ? h : ctx->lineHeight;
    if (outStart) *outStart = start;
    if (outEnd) *outEnd = end;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 行内某个停靠点的局部 x。byte 必须落在 [lineStart, lineEnd] 内且是簇边界。
static CjguiInternalRendererStatus cjgui_linux_ts_stop_x(const CjguiLinuxTsContext *ctx,
                                                         uint32_t lineIndex, size_t lineStart,
                                                         size_t lineEnd, double lineWidth,
                                                         size_t byte, double *outX) {
    if (byte <= lineStart) {
        *outX = 0.0;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (byte >= lineEnd) {
        *outX = lineWidth;   // 含软折行边界：行末就是行宽
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    double x = 0.0, top = 0.0, lineHeight = 0.0;
    uint32_t resolvedLine = 0u;
    size_t resolvedStart = 0u, resolvedEnd = 0u;
    int status = cjgui_linux_text_caret_position(
        ctx->text, ctx->utf8, ctx->length, ctx->fontSize, ctx->fontWeight, ctx->fontFamily,
        ctx->maxWidth, byte, &x, &top, &lineHeight, &resolvedLine, &resolvedStart, &resolvedEnd);
    if (status != CJGUI_LINUX_TEXT_OK) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    if (resolvedLine != lineIndex) {
        // 只可能发生在软折行边界被解析成"下一行行首"；本次枚举按行尾口径取值。
        x = lineWidth;
    }
    if (x > lineWidth) x = lineWidth;
    if (x < 0.0) x = 0.0;
    *outX = x;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 行内候选停靠点字节（升序去重）：行首 + 行内 UAX#29 簇边界 + 行尾。
static CjguiInternalRendererStatus cjgui_linux_ts_line_stop_bytes(const CjguiLinuxTsContext *ctx,
                                                                  uint32_t lineIndex, size_t *out,
                                                                  uint32_t capacity,
                                                                  uint32_t *outCount) {
    size_t lineStart = 0u, lineEnd = 0u;
    if (lineIndex >= ctx->lineCount) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_line_box(ctx, lineIndex, NULL, NULL, NULL, &lineStart, &lineEnd);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    uint32_t count = 0u;
    if (count >= capacity) return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
    out[count] = lineStart;
    count += 1u;
    size_t at = lineStart;
    while (at < lineEnd) {
        size_t end = cjgui_linux_ts_cluster_end_from(ctx->utf8, ctx->length, at);
        if (end <= at) break;
        if (end >= lineEnd) break;   // 行尾由 lineEnd 兜底（含切割落在簇内部的情形）
        if (end != out[count - 1u]) {
            if (count >= capacity) return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
            out[count] = end;
            count += 1u;
        }
        at = end;
    }
    if (out[count - 1u] != lineEnd) {
        if (count >= capacity) return CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
        out[count] = lineEnd;
        count += 1u;
    }
    *outCount = count;
    g_ts_counters.lineBuilds += 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 行内按 x 找最近停靠点（x 行内单调不减 ⇒ 二分）。并列取较小字节。
static CjguiInternalRendererStatus cjgui_linux_ts_nearest_stop(const CjguiLinuxTsContext *ctx,
                                                               uint32_t lineIndex,
                                                               const size_t *stops, uint32_t count,
                                                               size_t lineStart, size_t lineEnd,
                                                               double lineWidth, double target,
                                                               uint32_t *outIndex, double *outX) {
    uint32_t lo = 0u, hi = count;
    while (lo < hi) {
        uint32_t mid = lo + (hi - lo) / 2u;
        double x = 0.0;
        CjguiInternalRendererStatus status =
            cjgui_linux_ts_stop_x(ctx, lineIndex, lineStart, lineEnd, lineWidth, stops[mid], &x);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (x < target) {
            lo = mid + 1u;
        } else {
            hi = mid;
        }
    }
    uint32_t best = (lo < count) ? lo : (count - 1u);
    double bestX = 0.0;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_stop_x(ctx, lineIndex, lineStart, lineEnd, lineWidth, stops[best], &bestX);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (lo > 0u) {
        double prevX = 0.0;
        status = cjgui_linux_ts_stop_x(ctx, lineIndex, lineStart, lineEnd, lineWidth, stops[lo - 1u],
                                      &prevX);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (target - prevX <= bestX - target) {
            best = lo - 1u;
            bestX = prevX;
        }
    }
    *outIndex = best;
    *outX = bestX;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 行内某个字节的下标（停靠点枚举）。找不到返回 0 并把 *found 置 0。
static void cjgui_linux_ts_find_stop_index(const size_t *stops, uint32_t count, size_t byte,
                                          uint32_t *outIndex, int *found) {
    uint32_t i = 0u;
    for (; i < count; i += 1u) {
        if (stops[i] == byte) {
            *outIndex = i;
            *found = 1;
            return;
        }
    }
    *outIndex = 0u;
    *found = 0;
}

// ---------------------------------------------------------------- 选择框（逐行）

// 计算 [startByte,endByte) 的逐行选择框（每行至多一条，本阶段 LTR 无 bidi 多矩形）。
// 结果按行序平铺为 x,y,w,h。capacity 为调用方容量；实际写入 min(needed,capacity)。
static CjguiInternalRendererStatus cjgui_linux_ts_line_rects_core(const CjguiLinuxTsContext *ctx,
                                                                  int64_t startByte,
                                                                  int64_t endByte,
                                                                  int32_t maxRects, double *out,
                                                                  uint32_t *outCount) {
    *outCount = 0u;
    if (maxRects <= 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (startByte < 0 || endByte < startByte) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    size_t start = (size_t)startByte;
    size_t end = (size_t)endByte;
    if (start > ctx->length || end > ctx->length) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    // 范围端点必须同时是标量边界与字素簇边界：不吸附、不钳制。
    if (!cjgui_linux_ts_utf8_scalar_boundary(ctx->utf8, ctx->length, start) ||
        !cjgui_linux_ts_utf8_scalar_boundary(ctx->utf8, ctx->length, end) ||
        !cjgui_linux_ts_is_cluster_boundary(ctx->utf8, ctx->length, start) ||
        !cjgui_linux_ts_is_cluster_boundary(ctx->utf8, ctx->length, end)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    if (start == end) return CJGUI_INTERNAL_RENDERER_OK;   // 半开空范围：合法的零矩形

    uint32_t written = 0u;
    uint32_t lineIndex = 0u;
    for (; lineIndex < ctx->lineCount; lineIndex += 1u) {
        double lineY = 0.0, lineWidth = 0.0, lineHeight = 0.0;
        size_t lineStart = 0u, lineEnd = 0u;
        CjguiInternalRendererStatus status =
            cjgui_linux_ts_line_box(ctx, lineIndex, &lineY, &lineWidth, &lineHeight, &lineStart,
                                    &lineEnd);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        size_t clipStart = (start > lineStart) ? start : lineStart;
        size_t clipEnd = (end < lineEnd) ? end : lineEnd;
        if (clipEnd <= clipStart) continue;
        double x0 = 0.0, x1 = 0.0;
        status = cjgui_linux_ts_stop_x(ctx, lineIndex, lineStart, lineEnd, lineWidth, clipStart, &x0);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        status = cjgui_linux_ts_stop_x(ctx, lineIndex, lineStart, lineEnd, lineWidth, clipEnd, &x1);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (x1 < x0) x1 = x0;
        if (written >= (uint32_t)maxRects) break;   // 容量截断：调用方按 count==maxRects 读 partial
        if (out) {
            out[(size_t)written * 4u + 0u] = ctx->originX + x0;
            out[(size_t)written * 4u + 1u] = ctx->originY + lineY;
            out[(size_t)written * 4u + 2u] = x1 - x0;
            out[(size_t)written * 4u + 3u] = lineHeight;
        }
        written += 1u;
    }
    *outCount = written;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- ABI：光标矩形

int32_t cjgui_internal_renderer_text_geometry_caret(uint64_t session, int64_t nodeId,
                                                    int64_t displayByte, double caretWidthPt,
                                                    uint64_t expectedSceneVersion, uint32_t affinity,
                                                    double *outX, double *outY, double *outWidth,
                                                    double *outHeight) {
    if (!outX || !outY || !outWidth || !outHeight) {
        return (int32_t)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (!isfinite(caretWidthPt)) return (int32_t)CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    CjguiLinuxTsContext ctx;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_context(session, (uint64_t)nodeId, expectedSceneVersion, &ctx);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    size_t byte = 0u;
    status = cjgui_linux_ts_validate_point(&ctx, displayByte, &byte);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    CjguiLinuxTsCaret caret;
    memset(&caret, 0, sizeof(caret));
    status = cjgui_linux_ts_caret_resolve(&ctx, byte, affinity, &caret);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    *outX = ctx.originX + caret.x;
    *outY = ctx.originY + caret.top;
    *outWidth = caretWidthPt;
    *outHeight = caret.lineHeight;
    return CJGUI_LINUX_TS_STATUS_OK;
}

// ---------------------------------------------------------------- ABI：范围 ⇒ 逐行选择框

int32_t cjgui_internal_renderer_text_line_rect_count(uint64_t session, uint64_t nodeId,
                                                     int64_t startByte, int64_t endByte,
                                                     int32_t maxRects,
                                                     uint64_t expectedSceneVersion) {
    if (maxRects <= 0) return -((int32_t)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
    CjguiLinuxTsContext ctx;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_context(session, nodeId, expectedSceneVersion, &ctx);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return -(int32_t)status;
    uint32_t count = 0u;
    status = cjgui_linux_ts_line_rects_core(&ctx, startByte, endByte, maxRects, NULL, &count);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return -(int32_t)status;
    return (int32_t)count;
}

double cjgui_internal_renderer_text_line_rect_value(uint64_t session, uint64_t nodeId,
                                                    int64_t startByte, int64_t endByte,
                                                    int32_t maxRects, int32_t index,
                                                    int32_t component,
                                                    uint64_t expectedSceneVersion) {
    // 既有 ABI 约定：value() 只在 count() 成功之后按 index < count 读取；越界取 0.0。
    if (index < 0 || maxRects <= 0 || index >= maxRects) return 0.0;
    if (component < 0 || component > 3) return 0.0;
    CjguiLinuxTsContext ctx;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_context(session, nodeId, expectedSceneVersion, &ctx);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return 0.0;

    uint32_t row = (uint32_t)index;
    // 记忆：同一 (会话,节点,场景,租约,范围,容量) 的连续分量读取不重算整段。
    if (maxRects <= (int32_t)CJGUI_LINUX_TS_RECT_MEMO) {
        CjguiLinuxTsRectMemo *memo = &g_ts_rect_memo;
        if (memo->valid && memo->session == session && memo->nodeId == nodeId &&
            memo->sceneVersion == cjgui_linux_session_scene_version(session) &&
            memo->lease == ctx.lease && memo->startByte == startByte &&
            memo->endByte == endByte && memo->maxRects == maxRects) {
            g_ts_counters.cacheHits += 1u;
            if (row >= memo->count) return 0.0;
            return memo->rects[(size_t)row * 4u + (size_t)component];
        }
        uint32_t count = 0u;
        status = cjgui_linux_ts_line_rects_core(&ctx, startByte, endByte, maxRects, memo->rects,
                                                &count);
        if (status != CJGUI_INTERNAL_RENDERER_OK) {
            memo->valid = 0;
            return 0.0;
        }
        memo->valid = 1;
        memo->session = session;
        memo->nodeId = nodeId;
        memo->sceneVersion = cjgui_linux_session_scene_version(session);
        memo->lease = ctx.lease;
        memo->startByte = startByte;
        memo->endByte = endByte;
        memo->maxRects = maxRects;
        memo->count = count;
        if (row >= count) return 0.0;
        return memo->rects[(size_t)row * 4u + (size_t)component];
    }
    // 超出记忆容量的超大选择：按索引行数开一块临时缓冲（与 macOS 的 calloc 同构），
    // 只在 index < maxRects 时读到有意义的一行；失败/越界返回 0.0（既有 ABI 约定）。
    size_t needed = (size_t)row + 1u;
    double *scratch = (double *)calloc(needed * 4u, sizeof(double));
    if (!scratch) return 0.0;
    uint32_t count = 0u;
    status = cjgui_linux_ts_line_rects_core(&ctx, startByte, endByte, (int32_t)needed, scratch,
                                            &count);
    double result = 0.0;
    if (status == CJGUI_INTERNAL_RENDERER_OK && row < count) {
        result = scratch[(size_t)row * 4u + (size_t)component];
    }
    free(scratch);
    return result;
}

// ---------------------------------------------------------------- ABI：字素簇区间（纯文本）

CjguiInternalRendererStatus
cjgui_internal_renderer_grapheme_cluster_range(const char *utf8, uint64_t declaredLength,
                                               uint64_t offsetByte, uint64_t *outStartByte,
                                               uint64_t *outEndByte) {
    if (!utf8 || !outStartByte || !outEndByte) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outStartByte = 0u;
    *outEndByte = 0u;
    if (offsetByte >= declaredLength) {
        // 一过文本尾（或更远）没有"包含它的簇"：调用方在消费侧用 t-1 探测。
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
    }
    size_t length = (size_t)declaredLength;
    if (strlen(utf8) != length) {
        // 内嵌 NUL 截断了 C 串：缓冲与声明长度不一致，无法证明任何边界。
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    if (!cjgui_linux_ts_utf8_valid(utf8, length)) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    CjguiLinuxTsCluster cluster;
    cjgui_linux_ts_cluster_containing(utf8, length, (size_t)offsetByte, &cluster);
    if (cluster.end <= cluster.start || cluster.end > length) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outStartByte = (uint64_t)cluster.start;
    *outEndByte = (uint64_t)cluster.end;
    return CJGUI_LINUX_TS_STATUS_OK;
}

// ---------------------------------------------------------------- ABI：字素前缀（纯文本）

// 返回状态（与 ABI 头一致）；前缀字节数经 *outPrefixBytes 输出 —— 这是既有的
// 出参契约，不是返回值（Cangjie 消费方 runtime_renderer_session.cj 用返回状态区分
// INVALID_UTF8 / OK，再把 outPrefixBytes 当作截断长度）。
CjguiInternalRendererStatus cjgui_internal_renderer_composed_prefix_utf8_length(
    const char *utf8, uint64_t inputBytes, uint64_t maxOutputBytes, uint64_t maxClusters,
    uint8_t inputComplete, uint64_t *outPrefixBytes) {
    if (!outPrefixBytes || (!utf8 && inputBytes > 0u)) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outPrefixBytes = 0u;
    if (inputBytes == 0u || maxOutputBytes == 0u || maxClusters == 0u) return CJGUI_LINUX_TS_STATUS_OK;
    if (inputBytes > (uint64_t)CJGUI_LINUX_TS_CP_SCAN_LIMIT) {
        // 与 macOS 侧一致：调用方给的是"标量安全的扫描窗口"，超限不修补、不反复缩短。
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    size_t length = (size_t)inputBytes;
    if (!cjgui_linux_ts_utf8_valid(utf8, length)) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    uint64_t prefixBytes = 0u;
    uint64_t clusters = 0u;
    size_t at = 0u;
    while (at < length && clusters < maxClusters) {
        size_t end = cjgui_linux_ts_cluster_end_from(utf8, length, at);
        if (end <= at) break;
        if (!inputComplete && end >= length) break;   // 窗口尾可能切断了更长的簇：丢弃
        uint64_t clusterBytes = (uint64_t)(end - at);
        if (clusterBytes > maxOutputBytes - ((prefixBytes < maxOutputBytes) ? prefixBytes
                                                                           : maxOutputBytes)) {
            break;
        }
        prefixBytes += clusterBytes;
        clusters += 1u;
        at = end;
    }
    *outPrefixBytes = prefixBytes;
    return CJGUI_LINUX_TS_STATUS_OK;
}

// ---------------------------------------------------------------- ABI：版本化停靠点查询

// 组装 meta/rect（v1 的 POD 口径：meta[8] lease,stop,byte,renderSide,platformBranch,
// lineGlyphStart(→本平台=行首字节),UTF-16 boundary,provedBoundary；rect[4] x,y,w,h）。
static void cjgui_linux_ts_fill_stop(const CjguiLinuxTsContext *ctx, const CjguiLinuxTsCaret *caret,
                                     size_t byte, uint64_t stopId, uint32_t provedBoundary,
                                     uint64_t *meta, double *rect) {
    meta[0] = ctx->lease;
    meta[1] = stopId;
    meta[2] = (uint64_t)byte;
    meta[3] = (uint64_t)caret->renderSide;
    meta[4] = 0u;   // platformBranch：本平台单分支（0），无 bidi alternate
    meta[5] = (uint64_t)caret->lineStartByte;
    meta[6] = cjgui_linux_ts_utf16_units_before(ctx->utf8, ctx->length, byte);
    meta[7] = (uint64_t)provedBoundary;
    rect[0] = ctx->originX + caret->x;
    rect[1] = ctx->originY + caret->top;
    rect[2] = 1.0;
    rect[3] = caret->lineHeight;
}

static uint64_t cjgui_linux_ts_stop_id(const CjguiLinuxTsContext *ctx, const CjguiLinuxTsCaret *caret,
                                       size_t byte) {
    uint64_t id = cjgui_linux_ts_hash_u64(1469598103934665603ull, ctx->lease);
    id = cjgui_linux_ts_hash_u64(id, (uint64_t)caret->lineIndex);
    id = cjgui_linux_ts_hash_u64(id, (uint64_t)byte);
    id = cjgui_linux_ts_hash_u64(id, (uint64_t)caret->renderSide);
    return id | 1ull;   // 0 留作"无停靠点票据"，身份一律非零
}

// 视觉左/右邻位：同行按字节序取相邻停靠点；行端跨行；软折行两侧同字节的别名
// 按编辑器习惯跳过一次；排版边缘（首/尾）透传原位置并把 provedBoundary 置 1。
static CjguiInternalRendererStatus cjgui_linux_ts_step_stop(const CjguiLinuxTsContext *ctx,
                                                           uint32_t lineIndex, size_t byte,
                                                           uint32_t left, size_t *outByte,
                                                           uint32_t *outLineIndex, int *outEdge) {
    size_t stops[CJGUI_LINUX_TS_MAX_LINE_STOPS];
    uint32_t count = 0u;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_line_stop_bytes(ctx, lineIndex, stops, CJGUI_LINUX_TS_MAX_LINE_STOPS, &count);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    uint32_t index = 0u;
    int found = 0;
    cjgui_linux_ts_find_stop_index(stops, count, byte, &index, &found);
    if (!found) return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;

    for (uint32_t attempt = 0u; attempt < 2u; attempt += 1u) {
        size_t candidate = byte;
        uint32_t candidateLine = lineIndex;
        if (left) {
            if (index > 0u) {
                candidate = stops[index - 1u];
                index = index - 1u;
            } else if (lineIndex > 0u) {
                candidateLine = lineIndex - 1u;
                uint32_t prevCount = 0u;
                status = cjgui_linux_ts_line_stop_bytes(ctx, candidateLine, stops,
                                                        CJGUI_LINUX_TS_MAX_LINE_STOPS, &prevCount);
                if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
                if (prevCount == 0u) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
                candidate = stops[prevCount - 1u];
                index = prevCount - 1u;
                count = prevCount;
            } else {
                *outEdge = 1;
                *outByte = byte;
                *outLineIndex = lineIndex;
                return CJGUI_INTERNAL_RENDERER_OK;
            }
        } else {
            if (index + 1u < count) {
                candidate = stops[index + 1u];
                index = index + 1u;
            } else if (lineIndex + 1u < ctx->lineCount) {
                candidateLine = lineIndex + 1u;
                uint32_t nextCount = 0u;
                status = cjgui_linux_ts_line_stop_bytes(ctx, candidateLine, stops,
                                                        CJGUI_LINUX_TS_MAX_LINE_STOPS, &nextCount);
                if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
                if (nextCount == 0u) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
                candidate = stops[0];
                index = 0u;
                count = nextCount;
            } else {
                *outEdge = 1;
                *outByte = byte;
                *outLineIndex = lineIndex;
                return CJGUI_INTERNAL_RENDERER_OK;
            }
        }
        if (candidate != byte) {
            *outEdge = 0;
            *outByte = candidate;
            *outLineIndex = candidateLine;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        // 同一字节的软折行别名：按编辑器习惯再走一步（至多一次）。
        lineIndex = candidateLine;
    }
    // 别名之后仍在同一字节（例如文本尾只剩悬挂空白）：透传。
    *outEdge = 1;
    *outByte = byte;
    *outLineIndex = lineIndex;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 返回类型以 ABI 头为准（CjguiInternalRendererStatus）；内部以 int32_t 值计算，
// 返回时按 C 的整数→枚举隐式转换回同一 32 位表示（无截断、无符号歧义）。
CjguiInternalRendererStatus cjgui_internal_renderer_text_position_v1(
    uint64_t session, uint64_t nodeId, uint64_t expectedSceneVersion, uint32_t op,
    int64_t displayByte, uint32_t renderSide, uint64_t layoutLease, uint64_t stopId,
    uint32_t direction, double x, double y, uint64_t *meta, double *rect) {
    if (!meta || !rect) return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(meta, 0, 8u * sizeof(uint64_t));
    memset(rect, 0, 4u * sizeof(double));
    // 顺序与 macOS 的 CjguiTextPositionImpl 一致：会话/视图 → 场景版本 → op 参数 → 节点。
    CjguiInternalRendererStatus gate = cjgui_linux_ts_session_gate(session, expectedSceneVersion);
    if (gate != CJGUI_INTERNAL_RENDERER_OK) return gate;
    if (op > CJGUI_LINUX_TS_OP_VERTICAL || direction > 1u || !isfinite(x) || !isfinite(y)) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    CjguiLinuxTsContext ctx;
    CjguiInternalRendererStatus status = cjgui_linux_ts_context(session, nodeId, 0u, &ctx);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    g_ts_counters.queries += 1u;

    CjguiLinuxTsCaret caret;
    memset(&caret, 0, sizeof(caret));
    size_t byte = 0u;
    uint64_t proved = 0u;

    if (op == CJGUI_LINUX_TS_OP_RESOLVE) {
        status = cjgui_linux_ts_validate_point(&ctx, displayByte, &byte);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        status = cjgui_linux_ts_caret_resolve(&ctx, byte, renderSide, &caret);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    } else if (op == CJGUI_LINUX_TS_OP_HIT) {
        // 命中测试：把窗口点换算到文字块局部，落在块下方 ⇒ 文本尾（与 macOS 一致）。
        double localX = x - ctx.originX;
        double localY = y - ctx.originY;
        double blockHeight = (double)ctx.lineCount * ctx.lineHeight;
        uint32_t lineIndex = 0u;
        int belowText = 0;
        if (ctx.lineCount > 0u && localY >= blockHeight) {
            lineIndex = ctx.lineCount - 1u;
            belowText = (localY > blockHeight);
        } else if (localY > 0.0) {
            double quotient = floor(localY / ctx.lineHeight);
            if (quotient < 0.0) quotient = 0.0;
            if (quotient > (double)(ctx.lineCount - 1u)) quotient = (double)(ctx.lineCount - 1u);
            lineIndex = (uint32_t)quotient;
        }
        size_t stops[CJGUI_LINUX_TS_MAX_LINE_STOPS];
        uint32_t count = 0u;
        status = cjgui_linux_ts_line_stop_bytes(&ctx, lineIndex, stops, CJGUI_LINUX_TS_MAX_LINE_STOPS,
                                                &count);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        uint32_t index = 0u;
        if (belowText) {
            // 落在排版块下方 ⇒ 文本尾（与 macOS 的 extra-line 一致）。行尾悬挂空白
            // 可能让最后一行的字节范围早于 length，这里显式取 length，由 caret 解析
            // 回该行行末，不会少给一个可命名的插入点。
            byte = ctx.length;
            status = cjgui_linux_ts_caret_resolve(&ctx, byte, CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM,
                                                  &caret);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        } else {
            double lineY = 0.0, lineWidth = 0.0, lineHeight = 0.0;
            size_t lineStart = 0u, lineEnd = 0u;
            status = cjgui_linux_ts_line_box(&ctx, lineIndex, &lineY, &lineWidth, &lineHeight,
                                             &lineStart, &lineEnd);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
            double stopX = 0.0;
            status = cjgui_linux_ts_nearest_stop(&ctx, lineIndex, stops, count, lineStart, lineEnd,
                                                 lineWidth, localX, &index, &stopX);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
            byte = stops[index];
            status = cjgui_linux_ts_caret_resolve(&ctx, byte, CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM,
                                                  &caret);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        }
    } else if (op == CJGUI_LINUX_TS_OP_HORIZONTAL) {
        status = cjgui_linux_ts_validate_point(&ctx, displayByte, &byte);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        status = cjgui_linux_ts_caret_resolve(&ctx, byte, renderSide, &caret);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        size_t neighborByte = byte;
        uint32_t neighborLine = caret.lineIndex;
        int edge = 0;
        status = cjgui_linux_ts_step_stop(&ctx, caret.lineIndex, byte, direction == 0u ? 1u : 0u,
                                          &neighborByte, &neighborLine, &edge);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        if (edge || neighborByte == byte) {
            proved = 1u;   // 已证实的排版边缘：透传原位置
            byte = (size_t)displayByte;
            status = cjgui_linux_ts_caret_resolve(&ctx, byte, renderSide, &caret);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        } else {
            byte = neighborByte;
            status = cjgui_linux_ts_caret_resolve(&ctx, byte, CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM,
                                                  &caret);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        }
    } else {   // CJGUI_LINUX_TS_OP_VERTICAL
        status = cjgui_linux_ts_validate_point(&ctx, displayByte, &byte);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        status = cjgui_linux_ts_caret_resolve(&ctx, byte, renderSide, &caret);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        uint32_t targetLine = 0u;
        int haveTarget = 0;
        if (direction == 0u) {
            if (caret.lineIndex > 0u) {
                targetLine = caret.lineIndex - 1u;
                haveTarget = 1;
            }
        } else if (caret.lineIndex + 1u < ctx.lineCount) {
            targetLine = caret.lineIndex + 1u;
            haveTarget = 1;
        }
        if (!haveTarget) {
            proved = 1u;
        } else {
            size_t stops[CJGUI_LINUX_TS_MAX_LINE_STOPS];
            uint32_t count = 0u;
            status = cjgui_linux_ts_line_stop_bytes(&ctx, targetLine, stops,
                                                    CJGUI_LINUX_TS_MAX_LINE_STOPS, &count);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
            double lineY = 0.0, lineWidth = 0.0, lineHeight = 0.0;
            size_t lineStart = 0u, lineEnd = 0u;
            status = cjgui_linux_ts_line_box(&ctx, targetLine, &lineY, &lineWidth, &lineHeight,
                                             &lineStart, &lineEnd);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
            // 纵向移动保持列：目标 x 取调用方给的窗口 x（与 macOS 一致，不做额外发明）。
            double targetX = x - ctx.originX;
            if (targetX < 0.0) targetX = 0.0;
            uint32_t index = 0u;
            double stopX = 0.0;
            status = cjgui_linux_ts_nearest_stop(&ctx, targetLine, stops, count, lineStart, lineEnd,
                                                 lineWidth, targetX, &index, &stopX);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
            byte = stops[index];
            status = cjgui_linux_ts_caret_resolve(&ctx, byte, CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM,
                                                  &caret);
            if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
        }
    }

    // 票据校验：调用方携带的租约/停靠点身份必须仍指向当前 accepted 排版。
    if (layoutLease != 0u && layoutLease != ctx.lease) {
        return (int32_t)CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    uint64_t currentStopId = cjgui_linux_ts_stop_id(&ctx, &caret, byte);
    if (stopId != 0u && stopId != currentStopId) {
        return (int32_t)CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    cjgui_linux_ts_fill_stop(&ctx, &caret, byte, currentStopId, (uint32_t)proved, meta, rect);
    return CJGUI_LINUX_TS_STATUS_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_position_stats_v1(uint64_t session,
                                                                          uint64_t *counts) {
    if (!counts) return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!cjgui_linux_session_text(session)) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    // 本平台没有持留排版对象，计数器是**进程内**累计（会话层不暴露计数槽位）。
    counts[0] = g_ts_counters.prepares;
    counts[1] = g_ts_counters.queries;
    counts[2] = g_ts_counters.lineBuilds;
    counts[3] = g_ts_counters.cacheHits;
    return CJGUI_LINUX_TS_STATUS_OK;
}

// ---------------------------------------------------------------- ABI：停靠点解析 / 视觉邻位

CjguiInternalRendererStatus
cjgui_internal_renderer_text_stop_resolve(uint64_t session, uint64_t nodeId, int64_t displayByte,
                                          uint32_t branchIn, uint64_t expectedSceneVersion,
                                          uint32_t *outByte, uint32_t *outBranch,
                                          uint32_t *outLineFirstChar, uint32_t *outLineLength,
                                          double *outX) {
    if (!outByte || !outBranch || !outLineFirstChar || !outLineLength || !outX) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outByte = 0u;
    *outBranch = CJGUI_LINUX_TS_AFFINITY_AUTO;
    *outLineFirstChar = 0u;
    *outLineLength = 0u;
    *outX = 0.0;
    CjguiLinuxTsContext ctx;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_context(session, nodeId, expectedSceneVersion, &ctx);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    size_t byte = 0u;
    status = cjgui_linux_ts_validate_point(&ctx, displayByte, &byte);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    CjguiLinuxTsCaret caret;
    memset(&caret, 0, sizeof(caret));
    status = cjgui_linux_ts_caret_resolve(&ctx, byte, branchIn, &caret);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    if (!cjgui_linux_ts_i64_fits_u32((int64_t)byte) || !cjgui_linux_ts_i64_fits_u32((int64_t)caret.lineStartByte) ||
        !cjgui_linux_ts_i64_fits_u32((int64_t)(caret.lineEndByte - caret.lineStartByte))) {
        return (int32_t)CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    *outByte = (uint32_t)byte;
    *outBranch = caret.renderSide;
    // 本平台没有 UTF-16 存储；lineFirstChar/lineLength 用 display byte 口径，
    // 与调用方唯一编辑域一致（macOS 侧是 UTF-16 字符下标）。
    *outLineFirstChar = (uint32_t)caret.lineStartByte;
    *outLineLength = (uint32_t)(caret.lineEndByte - caret.lineStartByte);
    *outX = ctx.originX + caret.x;
    return CJGUI_LINUX_TS_STATUS_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_text_stop_neighbor(uint64_t session, uint64_t nodeId, int64_t displayByte,
                                           uint32_t branchIn, uint32_t left,
                                           uint64_t expectedSceneVersion, uint32_t *outByte,
                                           uint32_t *outBranch) {
    if (!outByte || !outBranch) return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outByte = 0u;
    *outBranch = CJGUI_LINUX_TS_AFFINITY_AUTO;
    CjguiLinuxTsContext ctx;
    CjguiInternalRendererStatus status =
        cjgui_linux_ts_context(session, nodeId, expectedSceneVersion, &ctx);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    size_t byte = 0u;
    status = cjgui_linux_ts_validate_point(&ctx, displayByte, &byte);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    CjguiLinuxTsCaret caret;
    memset(&caret, 0, sizeof(caret));
    status = cjgui_linux_ts_caret_resolve(&ctx, byte, branchIn, &caret);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    size_t neighborByte = byte;
    uint32_t neighborLine = caret.lineIndex;
    int edge = 0;
    status = cjgui_linux_ts_step_stop(&ctx, caret.lineIndex, byte, left, &neighborByte,
                                      &neighborLine, &edge);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    if (edge || neighborByte == byte) {
        *outByte = (uint32_t)byte;
        *outBranch = caret.renderSide;   // 已证实的排版边缘：透传原 (byte, branch)
        return CJGUI_LINUX_TS_STATUS_OK;
    }
    CjguiLinuxTsCaret neighbor;
    memset(&neighbor, 0, sizeof(neighbor));
    status = cjgui_linux_ts_caret_resolve(&ctx, neighborByte, CJGUI_LINUX_TS_AFFINITY_DOWNSTREAM,
                                          &neighbor);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return (int32_t)status;
    if (!cjgui_linux_ts_i64_fits_u32((int64_t)neighborByte)) {
        return (int32_t)CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    *outByte = (uint32_t)neighborByte;
    *outBranch = neighbor.renderSide;
    return CJGUI_LINUX_TS_STATUS_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_text_visual_neighbor(
    uint64_t session, uint64_t nodeId, int64_t displayByte, uint32_t left,
    uint64_t expectedSceneVersion, uint32_t caretAffinity, uint32_t *outNeighborByte,
    uint32_t *outAffinity) {
    if (!outNeighborByte || !outAffinity) {
        return (CjguiInternalRendererStatus)CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    uint32_t byte = 0u;
    uint32_t affinity = CJGUI_LINUX_TS_AFFINITY_AUTO;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_text_stop_neighbor(
        session, nodeId, displayByte, caretAffinity, left, expectedSceneVersion, &byte, &affinity);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    *outNeighborByte = byte;
    *outAffinity = affinity;
    return CJGUI_LINUX_TS_STATUS_OK;
}

#ifdef __cplusplus
}
#endif
