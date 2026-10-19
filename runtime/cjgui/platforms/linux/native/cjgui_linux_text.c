// runtime/cjgui/platforms/linux/native/cjgui_linux_text.c
//
// Linux 文字测量 / 整形 / 字形图集（窄平台实现）。
//
// 依赖只有 fontconfig / harfbuzz / freetype（系统中文栈）。不引入任何 GUI 框架，
// 也不用自带的光栅化引擎替代系统字体栈。
//
// 数据流：
//   UTF-8 → Fontconfig 选族 + 回退链 → HarfBuzz 整形（glyph/advance/cluster）
//         → cluster/glyph 列表 → 换行 → 测量 + 方块 → FreeType 光栅化 → 单页 RGBA 图集
//
// 关键约定：
//  1. 测量与 layout 走同一条 lt_build/lt_wrap 计算路径，wantQuads 只在最后多一步
//     光栅化，所以两次调用的 outWidth/outHeight/outAscent 必然一致；
//  2. 缺字不静默：选字阶段用 FT_Get_Char_Index 判定覆盖，缺字就沿 fontconfig 的
//     排序列表换族重整形；整形后落到 .notdef 的 cluster 也会记录。每一次回退都会
//     写进 cjgui_linux_text_take_fallback_log 的待取队列；
//  3. 图集是单页 1024x1024 RGBA8，左上 2x2 是给实心几何用的白色纹素（RGBA 全 255），
//     字形槽位从 (2,2) 开始按货架（shelf）分配，槽间留 1px 防采样串色；字形按
//     (face, pixelSize, glyphId) 缓存，命中不重复光栅化；图集满时返回
//     CJGUI_LINUX_TEXT_ATLAS_FULL 并保留已缓存内容；
//  4. 所有可变状态都在 CjguiLinuxText 里，多实例互不影响（fontconfig / freetype 自己的
//     进程级缓存属于库，不属于本模块的可变状态）；
//  5. 像素与逻辑点在本阶段是 1:1（C ABI 传进来的 fontSize 就是像素尺寸）。
//
// 本阶段限制（用到时再补，已在报告里如实说明）：
//  * 只做 LTR：复杂文种的双向排序属于共同层，这里不做 bidi 重排；
//  * 不跑完整 UAX#14：换行点只取空格 / CJK / emoji 边界，长拉丁词超宽时整体溢出；
//  * 不使用 OpenType 特性选择与可变字体轴（走默认特性）。
//
// 调试钩子（只影响本模块选族，不改变任何 ABI）：
//  * CJGUI_LINUX_TEXT_FAMILY_SYSTEM：替换 fontFamily=0 的族名（默认 sans-serif）
//  * CJGUI_LINUX_TEXT_FAMILY_MONO  ：替换 fontFamily=1 的族名（默认 monospace）
//  在 create 时读入并记在句柄里，用于验证回退链（例如指定一个不含中日韩的族）。
//
// 线程约定：所有函数都只允许在渲染会话所属的那一个线程上调用。

#include "cjgui_linux_text.h"

#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb.h>
#include <hb-ft.h>

#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LT_FACE_CAP 96        // 一个实例最多打开的 FT_Face 数
#define LT_CHAIN_CAP 64       // 每个族集最多参与回退的 fontconfig 候选项
#define LT_GLYPH_CAP 4096     // 图集字形槽上限
#define LT_HASH_CAP 8192      // 字形缓存哈希表（2 的幂）
#define LT_CP_CACHE_CAP 512   // 单字符回退结果缓存（2 的幂）
#define LT_FALLBACK_CAP 512   // 待取回退记录环形队列
#define LT_FONT_PAD 1         // 字形槽之间的留白

#define LT_SLOT_UNSET (-2)    // 缓存项：还没尝试光栅化
#define LT_SLOT_FAILED (-1)   // 缓存项：尝试过但失败（或无槽位）

#define LT_ATLAS_SIDE CJGUI_LINUX_TEXT_ATLAS_SIDE
#define LT_ATLAS_ORIGIN CJGUI_LINUX_TEXT_ATLAS_ORIGIN

#define LT_NO_FONT_MARKER "<no-font>"   // 回退链里没有任何字体覆盖这个 cluster
#define LT_NOTDEF_MARKER "<notdef>"     // 整形结果落到了 .notdef（不静默画豆腐块）

// ---------------------------------------------------------------- 数据结构

typedef struct LtFace {
    FT_Face ft;
    hb_font_t *hb;
    char *path;          // 自有
    int index;           // 字体集合内的 face 序号
    char family[128];
    int32_t size26_6;    // 当前已设置的 26.6 像素尺寸；0 = 未设置
    double ascent;
    double descent;
    double line_height;
} LtFace;

typedef struct LtFamilySet {
    int state;                    // 0=未解析 1=已解析 -1=失败
    int family_kind;              // 0=system 1=monospaced
    int weight;                   // 0..3
    char requested[128];          // 请求的族名（枚举解析结果 / 调试钩子）
    char primary_family[128];     // fontconfig 实际排第一的族名
    FcFontSet *fonts;             // 自有，按匹配度排序
    int *face_ids;                // 每个候选项对应的 LtFace 下标；-2=未尝试 -1=失败
    uint8_t alias_logged;
} LtFamilySet;

typedef struct LtGlyphEntry {
    uint32_t face;
    uint32_t gid;
    int32_t size26_6;
    int32_t slot;        // >=0 槽位下标；LT_SLOT_UNSET / LT_SLOT_FAILED
    uint8_t used;
} LtGlyphEntry;

typedef struct LtSlot {
    int16_t x, y, w, h;  // 图集像素矩形
    int16_t bx, by;      // FreeType bitmap_left / bitmap_top（像素）
} LtSlot;

typedef struct LtCpEntry {
    uint32_t cp;
    int32_t face;        // -1 = 查过但没有字体覆盖
    uint8_t used;
} LtCpEntry;

typedef struct LtCluster {
    uint32_t byte_start;
    uint32_t byte_len;
    uint32_t glyph_start;
    uint32_t glyph_count;
    double advance;
    uint32_t cp;         // 该 cluster 的首个码点
    uint8_t hard_break;  // 来自 '\n'
    uint8_t break_before;
    uint8_t is_space;
} LtCluster;

typedef struct LtGlyph {
    uint32_t face;
    uint32_t gid;
    uint32_t cluster;
    double advance;
    double x_offset;
    double y_offset;
} LtGlyph;

typedef struct LtLine {
    uint32_t cluster_start;
    uint32_t cluster_count;
    double width;
} LtLine;

struct CjguiLinuxText {
    FT_Library ft;
    LtFace faces[LT_FACE_CAP];
    int face_count;

    LtFamilySet families[8];  // [family_kind * 4 + weight]

    LtGlyphEntry hash[LT_HASH_CAP];
    LtSlot slots[LT_GLYPH_CAP];
    uint32_t slot_count;

    LtCpEntry cp_cache[LT_CP_CACHE_CAP];

    hb_buffer_t *buf;

    uint8_t atlas[LT_ATLAS_SIDE * LT_ATLAS_SIDE * 4];
    int shelf_x, shelf_y, shelf_h;
    int dirty_x0, dirty_y0, dirty_x1, dirty_y1;  // [x0,x1) x [y0,y1)；空时 x0>=x1

    CjguiLinuxTextFallback pend[LT_FALLBACK_CAP];
    uint32_t pend_head, pend_count;
    uint64_t last_fb_hash;
    uint32_t last_fb_count;

    // 每次 layout 复用，避免反复分配
    LtCluster *clusters;
    uint32_t cluster_count, cluster_cap;
    LtGlyph *glyphs;
    uint32_t glyph_count, glyph_cap;
    LtLine *lines;
    uint32_t line_count, line_cap;
    uint32_t *cps;
    uint32_t *cp_offs;
    int32_t *cp_face;
    uint8_t *cp_nofont;  // 该码点整条回退链都没有字体覆盖
    uint32_t cp_count, cp_cap;

    double layout_ascent;
    double layout_line_height;
};

// ---------------------------------------------------------------- 小工具

static char *lt_strdup(const char *s) {
    size_t n = strlen(s) + 1;
    char *p = (char *)malloc(n);
    if (p) memcpy(p, s, n);
    return p;
}

static int lt_reserve(void **buf, uint32_t *cap, uint32_t need, size_t elem) {
    if (need <= *cap) return 1;
    uint32_t nc = *cap ? *cap : 64;
    while (nc < need) {
        if (nc > (1u << 30)) return 0;
        nc *= 2;
    }
    void *np = realloc(*buf, (size_t)nc * elem);
    if (!np) return 0;
    *buf = np;
    *cap = nc;
    return 1;
}

// cps / cp_offs / cp_face 三个数组一一对应，共用 t->cp_cap 一起扩容。
static int lt_reserve_cps(CjguiLinuxText *t, uint32_t need) {
    if (need <= t->cp_cap) return 1;
    uint32_t nc = t->cp_cap ? t->cp_cap : 64;
    while (nc < need) {
        if (nc > (1u << 30)) return 0;
        nc *= 2;
    }
    uint32_t *a = (uint32_t *)realloc(t->cps, (size_t)nc * sizeof(uint32_t));
    if (!a) return 0;
    t->cps = a;
    uint32_t *b = (uint32_t *)realloc(t->cp_offs, (size_t)nc * sizeof(uint32_t));
    if (!b) return 0;
    t->cp_offs = b;
    int32_t *c = (int32_t *)realloc(t->cp_face, (size_t)nc * sizeof(int32_t));
    if (!c) return 0;
    t->cp_face = c;
    uint8_t *d = (uint8_t *)realloc(t->cp_nofont, (size_t)nc * sizeof(uint8_t));
    if (!d) return 0;
    t->cp_nofont = d;
    t->cp_cap = nc;
    return 1;
}

static int32_t lt_pixel_size(double fontSize) {
    double v = fontSize * 64.0;
    if (!(v > 64.0)) v = 64.0;                 // 同时挡掉 NaN / <=0：至少 1px
    if (v > 64.0 * 1024.0) v = 64.0 * 1024.0;  // 上限 1024px，防呆
    return (int32_t)floor(v + 0.5);
}

static uint32_t lt_utf8_next(const uint8_t *s, size_t len, size_t *io) {
    size_t i = *io;
    uint8_t b = s[i];
    uint32_t cp = 0xFFFD;
    size_t adv = 1;
    if (b < 0x80) {
        cp = b;
    } else if ((b & 0xE0) == 0xC0) {
        if (i + 1 < len && (s[i + 1] & 0xC0) == 0x80) {
            cp = ((uint32_t)(b & 0x1Fu) << 6) | (uint32_t)(s[i + 1] & 0x3Fu);
            adv = 2;
            if (cp < 0x80) cp = 0xFFFD;
        }
    } else if ((b & 0xF0) == 0xE0) {
        if (i + 2 < len && (s[i + 1] & 0xC0) == 0x80 && (s[i + 2] & 0xC0) == 0x80) {
            cp = ((uint32_t)(b & 0x0Fu) << 12) | ((uint32_t)(s[i + 1] & 0x3Fu) << 6) |
                 (uint32_t)(s[i + 2] & 0x3Fu);
            adv = 3;
            if (cp < 0x800) cp = 0xFFFD;
        }
    } else if ((b & 0xF8) == 0xF0) {
        if (i + 3 < len && (s[i + 1] & 0xC0) == 0x80 && (s[i + 2] & 0xC0) == 0x80 &&
            (s[i + 3] & 0xC0) == 0x80) {
            cp = ((uint32_t)(b & 0x07u) << 18) | ((uint32_t)(s[i + 1] & 0x3Fu) << 12) |
                 ((uint32_t)(s[i + 2] & 0x3Fu) << 6) | (uint32_t)(s[i + 3] & 0x3Fu);
            adv = 4;
            if (cp < 0x10000 || cp > 0x10FFFF) cp = 0xFFFD;
        }
    }
    *io = i + adv;
    return cp;
}

static int lt_cp_is_space(uint32_t cp) {
    if (cp == 0x20 || cp == 0x09 || cp == 0xA0) return 1;
    if (cp >= 0x2000 && cp <= 0x200A) return 1;
    if (cp == 0x202F || cp == 0x205F || cp == 0x3000) return 1;
    return 0;
}

// CJK / 假名 / 谚文 / 全角 / emoji：可以逐字断行。
static int lt_cp_is_breakable(uint32_t cp) {
    if (cp >= 0x1100 && cp <= 0x11FF) return 1;
    if (cp >= 0x2E80 && cp <= 0x303F) return 1;
    if (cp >= 0x3040 && cp <= 0x33FF) return 1;
    if (cp >= 0x3400 && cp <= 0x4DBF) return 1;
    if (cp >= 0x4E00 && cp <= 0x9FFF) return 1;
    if (cp >= 0xA960 && cp <= 0xA97F) return 1;
    if (cp >= 0xAC00 && cp <= 0xD7AF) return 1;
    if (cp >= 0xF900 && cp <= 0xFAFF) return 1;
    if (cp >= 0xFE30 && cp <= 0xFE4F) return 1;
    if (cp >= 0xFF00 && cp <= 0xFF60) return 1;
    if (cp >= 0xFFE0 && cp <= 0xFFE6) return 1;
    if (cp >= 0x1F300 && cp <= 0x1FAFF) return 1;
    if (cp >= 0x20000 && cp <= 0x3134F) return 1;
    return 0;
}

// 组合记号：换族时不要把它和基字拆到两个 run 里。
static int lt_cp_is_combining(uint32_t cp) {
    if (cp >= 0x0300 && cp <= 0x036F) return 1;
    if (cp >= 0x1AB0 && cp <= 0x1AFF) return 1;
    if (cp >= 0x1DC0 && cp <= 0x1DFF) return 1;
    if (cp >= 0x20D0 && cp <= 0x20FF) return 1;
    if (cp >= 0xFE00 && cp <= 0xFE0F) return 1;  // 变体选择符
    if (cp >= 0xFE20 && cp <= 0xFE2F) return 1;
    return 0;
}

// ---------------------------------------------------------------- 图集脏区

static int lt_dirty_is_empty(const CjguiLinuxText *t) {
    return t->dirty_x1 <= t->dirty_x0 || t->dirty_y1 <= t->dirty_y0;
}

static void lt_dirty_clear(CjguiLinuxText *t) {
    t->dirty_x0 = 0;
    t->dirty_y0 = 0;
    t->dirty_x1 = 0;
    t->dirty_y1 = 0;
}

static void lt_dirty_add(CjguiLinuxText *t, int x, int y, int w, int h) {
    if (w <= 0 || h <= 0) return;
    if (lt_dirty_is_empty(t)) {
        t->dirty_x0 = x;
        t->dirty_y0 = y;
        t->dirty_x1 = x + w;
        t->dirty_y1 = y + h;
        return;
    }
    if (x < t->dirty_x0) t->dirty_x0 = x;
    if (y < t->dirty_y0) t->dirty_y0 = y;
    if (x + w > t->dirty_x1) t->dirty_x1 = x + w;
    if (y + h > t->dirty_y1) t->dirty_y1 = y + h;
}

// ---------------------------------------------------------------- 回退日志

static void lt_push_fallback(CjguiLinuxText *t, uint32_t off, const char *requested,
                             const char *selected, uint64_t *hash, uint32_t *hash_count) {
    uint32_t idx;
    if (t->pend_count == LT_FALLBACK_CAP) {  // 队列满：丢最旧的一条
        idx = t->pend_head;
        t->pend_head = (t->pend_head + 1) % LT_FALLBACK_CAP;
    } else {
        idx = (t->pend_head + t->pend_count) % LT_FALLBACK_CAP;
        t->pend_count++;
    }
    CjguiLinuxTextFallback *e = &t->pend[idx];
    memset(e, 0, sizeof(*e));
    e->byteOffset = off;
    snprintf(e->requested, sizeof(e->requested), "%s", requested ? requested : "");
    snprintf(e->selected, sizeof(e->selected), "%s", selected ? selected : "");

    if (hash && hash_count) {
        uint64_t h = *hash ? *hash : 1469598103934665603ull;
        h = (h ^ (uint64_t)off) * 1099511628211ull;
        for (const char *p = e->requested; *p; p++) h = (h ^ (uint8_t)*p) * 1099511628211ull;
        for (const char *p = e->selected; *p; p++) h = (h ^ (uint8_t)*p) * 1099511628211ull;
        *hash = h ? h : 1u;
        (*hash_count)++;
    }
}

static void lt_pop_fallback(CjguiLinuxText *t, uint32_t n) {
    if (n > t->pend_count) n = t->pend_count;
    t->pend_count -= n;
    if (t->pend_count == 0) t->pend_head = 0;
}

// ---------------------------------------------------------------- 字体加载

static int lt_face_find(CjguiLinuxText *t, const char *path, int index) {
    for (int i = 0; i < t->face_count; i++) {
        if (t->faces[i].index == index && strcmp(t->faces[i].path, path) == 0) return i;
    }
    return -1;
}

static int lt_face_open(CjguiLinuxText *t, const char *path, int index, const char *family) {
    int found = lt_face_find(t, path, index);
    if (found >= 0) return found;
    if (t->face_count >= LT_FACE_CAP) return -1;

    FT_Face ft = NULL;
    if (FT_New_Face(t->ft, path, index, &ft) != 0 || !ft) return -1;
    hb_font_t *hb = hb_ft_font_create_referenced(ft);
    if (!hb) {
        FT_Done_Face(ft);
        return -1;
    }
    hb_ft_font_set_load_flags(hb, FT_LOAD_DEFAULT | FT_LOAD_TARGET_NORMAL);

    char *copy = lt_strdup(path);
    if (!copy) {
        hb_font_destroy(hb);
        FT_Done_Face(ft);
        return -1;
    }
    LtFace *f = &t->faces[t->face_count];
    memset(f, 0, sizeof(*f));
    f->ft = ft;
    f->hb = hb;
    f->path = copy;
    f->index = index;
    f->size26_6 = 0;
    snprintf(f->family, sizeof(f->family), "%s", (family && *family) ? family : "?");
    return t->face_count++;
}

static void lt_face_set_size(CjguiLinuxText *t, int face_id, int32_t size26_6) {
    LtFace *f = &t->faces[face_id];
    if (f->size26_6 == size26_6) return;
    FT_Error err = FT_Set_Char_Size(f->ft, 0, (FT_F26Dot6)size26_6, 72, 72);
    if (err != 0) {
        int px = (int)((size26_6 + 32) / 64);
        if (px < 1) px = 1;
        (void)FT_Set_Pixel_Sizes(f->ft, 0, (FT_UInt)px);
    }
    hb_font_set_scale(f->hb, size26_6, size26_6);
    f->size26_6 = size26_6;

    if (f->ft->size) {
        f->ascent = (double)f->ft->size->metrics.ascender / 64.0;
        f->descent = -(double)f->ft->size->metrics.descender / 64.0;
        f->line_height = (double)f->ft->size->metrics.height / 64.0;
    } else {
        f->ascent = 0.0;
        f->descent = 0.0;
        f->line_height = 0.0;
    }
    if (f->ascent < 0.0) f->ascent = 0.0;
    if (f->descent < 0.0) f->descent = 0.0;
    if (!(f->line_height > 0.0)) f->line_height = f->ascent + f->descent;
    if (!(f->line_height > 0.0)) f->line_height = (double)size26_6 / 64.0;
}

static int lt_face_covers(CjguiLinuxText *t, int face_id, uint32_t cp) {
    if (face_id < 0) return 0;
    return FT_Get_Char_Index(t->faces[face_id].ft, cp) != 0;
}

// ---------------------------------------------------------------- 选族与回退链

static int lt_fc_weight(uint32_t weight) {
    switch (weight) {
        case 0: return FC_WEIGHT_REGULAR;
        case 1: return FC_WEIGHT_MEDIUM;
        case 2: return FC_WEIGHT_DEMIBOLD;
        case 3: return FC_WEIGHT_BOLD;
        default: return FC_WEIGHT_REGULAR;
    }
}

static LtFamilySet *lt_family_set(CjguiLinuxText *t, uint32_t family, uint32_t weight) {
    int kind = (family == 1) ? 1 : 0;  // 其余取值按 system 处理
    if (weight > 3) weight = 3;
    return &t->families[kind * 4 + (int)weight];
}

static void lt_family_name(const LtFamilySet *set, char *out, size_t out_len) {
    const char *env_name =
        (set->family_kind == 1) ? "CJGUI_LINUX_TEXT_FAMILY_MONO" : "CJGUI_LINUX_TEXT_FAMILY_SYSTEM";
    const char *fallback = (set->family_kind == 1) ? "monospace" : "sans-serif";
    const char *env = getenv(env_name);
    const char *name = (env && *env) ? env : fallback;
    snprintf(out, out_len, "%s", name);
}

static int lt_family_resolve(CjguiLinuxText *t, LtFamilySet *set) {
    (void)t;  // 解析只用 fontconfig 的全局配置，实例状态由 set 自己持有
    if (set->state != 0) return set->state > 0;
    set->state = -1;

    char name[128];
    lt_family_name(set, name, sizeof(name));
    snprintf(set->requested, sizeof(set->requested), "%s", name);

    FcPattern *pat = FcPatternCreate();
    if (!pat) return 0;
    FcPatternAddString(pat, FC_FAMILY, (const FcChar8 *)name);
    FcPatternAddInteger(pat, FC_WEIGHT, lt_fc_weight((uint32_t)set->weight));
    FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_ROMAN);
    FcConfigSubstitute(NULL, pat, FcMatchPattern);
    FcDefaultSubstitute(pat);

    FcResult res = FcResultNoMatch;
    FcFontSet *fs = FcFontSort(NULL, pat, FcTrue, NULL, &res);
    FcPatternDestroy(pat);
    if (!fs || fs->nfont == 0) {
        if (fs) FcFontSetDestroy(fs);
        return 0;
    }

    set->fonts = fs;
    set->face_ids = (int *)malloc((size_t)fs->nfont * sizeof(int));
    if (!set->face_ids) {
        FcFontSetDestroy(fs);
        set->fonts = NULL;
        return 0;
    }
    for (int i = 0; i < fs->nfont; i++) set->face_ids[i] = -2;

    FcChar8 *fam = NULL;
    if (FcPatternGetString(fs->fonts[0], FC_FAMILY, 0, &fam) == FcResultMatch && fam) {
        snprintf(set->primary_family, sizeof(set->primary_family), "%s", (const char *)fam);
    } else {
        snprintf(set->primary_family, sizeof(set->primary_family), "%s", name);
    }

    // fontconfig 的族名是别名/多语言族名，跟请求的通用名不同是正常解析，不算缺字回退；
    // 但仍然记一条，让共同层能看到"请求的族 vs 实际选中的族"。
    set->state = 1;
    return 1;
}

static void lt_family_alias_note(CjguiLinuxText *t, LtFamilySet *set) {
    if (set->alias_logged) return;
    set->alias_logged = 1;
    if (strcmp(set->primary_family, set->requested) != 0) {
        lt_push_fallback(t, 0, set->requested, set->primary_family, NULL, NULL);
    }
}

static int lt_chain_face(CjguiLinuxText *t, LtFamilySet *set, int i) {
    if (!set->fonts || i < 0 || i >= set->fonts->nfont) return -1;
    if (set->face_ids[i] != -2) return set->face_ids[i];

    FcPattern *p = set->fonts->fonts[i];
    FcChar8 *file = NULL;
    FcChar8 *fam = NULL;
    int index = 0;
    if (FcPatternGetString(p, FC_FILE, 0, &file) != FcResultMatch || !file) {
        set->face_ids[i] = -1;
        return -1;
    }
    (void)FcPatternGetInteger(p, FC_INDEX, 0, &index);
    (void)FcPatternGetString(p, FC_FAMILY, 0, &fam);

    int id = lt_face_open(t, (const char *)file, index, fam ? (const char *)fam : "?");
    set->face_ids[i] = id;
    return id;
}

// 二级回退：候选列表里没人覆盖这个码点，就直接向 fontconfig 要"含这个字符"的字体。
static int lt_fc_query_char(CjguiLinuxText *t, LtFamilySet *set, uint32_t cp) {
    FcPattern *pat = FcPatternCreate();
    FcCharSet *cs = FcCharSetCreate();
    if (!pat || !cs) {
        if (pat) FcPatternDestroy(pat);
        if (cs) FcCharSetDestroy(cs);
        return -1;
    }
    FcCharSetAddChar(cs, cp);
    FcPatternAddCharSet(pat, FC_CHARSET, cs);
    FcPatternAddInteger(pat, FC_WEIGHT, lt_fc_weight((uint32_t)set->weight));
    FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_ROMAN);
    FcConfigSubstitute(NULL, pat, FcMatchPattern);
    FcDefaultSubstitute(pat);

    FcResult res = FcResultNoMatch;
    FcPattern *m = FcFontMatch(NULL, pat, &res);
    FcCharSetDestroy(cs);
    FcPatternDestroy(pat);
    if (!m) return -1;

    int id = -1;
    FcChar8 *file = NULL;
    FcChar8 *fam = NULL;
    int index = 0;
    if (FcPatternGetString(m, FC_FILE, 0, &file) == FcResultMatch && file) {
        (void)FcPatternGetInteger(m, FC_INDEX, 0, &index);
        (void)FcPatternGetString(m, FC_FAMILY, 0, &fam);
        id = lt_face_open(t, (const char *)file, index, fam ? (const char *)fam : "?");
    }
    FcPatternDestroy(m);
    return id;
}

static int lt_find_fallback_face(CjguiLinuxText *t, LtFamilySet *set, uint32_t cp) {
    uint32_t h = (cp * 2654435761u) & (uint32_t)(LT_CP_CACHE_CAP - 1);
    for (uint32_t probe = 0; probe < LT_CP_CACHE_CAP; probe++) {
        LtCpEntry *e = &t->cp_cache[(h + probe) & (uint32_t)(LT_CP_CACHE_CAP - 1)];
        if (!e->used) break;
        if (e->cp == cp) return e->face;
    }

    int result = -1;
    int n = set->fonts ? set->fonts->nfont : 0;
    if (n > LT_CHAIN_CAP) n = LT_CHAIN_CAP;
    for (int i = 0; i < n; i++) {
        FcCharSet *cs = NULL;
        if (FcPatternGetCharSet(set->fonts->fonts[i], FC_CHARSET, 0, &cs) == FcResultMatch && cs &&
            !FcCharSetHasChar(cs, cp)) {
            continue;  // 字符集里都没有，跳过（省一次开字体）
        }
        int id = lt_chain_face(t, set, i);
        if (id < 0) continue;
        if (lt_face_covers(t, id, cp)) {
            result = id;
            break;
        }
    }
    if (result < 0) result = lt_fc_query_char(t, set, cp);

    for (uint32_t probe = 0; probe < LT_CP_CACHE_CAP; probe++) {
        LtCpEntry *e = &t->cp_cache[(h + probe) & (uint32_t)(LT_CP_CACHE_CAP - 1)];
        if (!e->used || e->cp == cp) {
            e->used = 1;
            e->cp = cp;
            e->face = result;
            break;
        }
    }
    return result;
}

// ---------------------------------------------------------------- 字形缓存 / 图集

static uint32_t lt_glyph_hash(uint32_t face, uint32_t gid, int32_t size26_6) {
    uint32_t h = 2166136261u;
    h = (h ^ face) * 16777619u;
    h = (h ^ gid) * 16777619u;
    h = (h ^ (uint32_t)size26_6) * 16777619u;
    return h;
}

// insert=0 时只查不建。表满返回 NULL。
static LtGlyphEntry *lt_cache_lookup(CjguiLinuxText *t, uint32_t face, uint32_t gid, int32_t size26_6,
                                     int insert) {
    uint32_t h = lt_glyph_hash(face, gid, size26_6) & (uint32_t)(LT_HASH_CAP - 1);
    for (uint32_t probe = 0; probe < (uint32_t)LT_HASH_CAP; probe++) {
        LtGlyphEntry *e = &t->hash[(h + probe) & (uint32_t)(LT_HASH_CAP - 1)];
        if (!e->used) {
            if (!insert) return NULL;
            e->used = 1;
            e->face = face;
            e->gid = gid;
            e->size26_6 = size26_6;
            e->slot = LT_SLOT_UNSET;
            return e;
        }
        if (e->face == face && e->gid == gid && e->size26_6 == size26_6) return e;
    }
    return NULL;
}

// 货架式分配：左上 2x2 保留给白色纹素，槽位从 (2,2) 起，槽间留 LT_FONT_PAD。
static int lt_atlas_alloc(CjguiLinuxText *t, int w, int h, int *out_x, int *out_y) {
    if (w <= 0 || h <= 0) return 0;
    if (LT_ATLAS_ORIGIN + w + LT_FONT_PAD > LT_ATLAS_SIDE) return 0;
    if (LT_ATLAS_ORIGIN + h > LT_ATLAS_SIDE) return 0;
    if (t->shelf_x + w + LT_FONT_PAD > LT_ATLAS_SIDE) {
        t->shelf_y += t->shelf_h + LT_FONT_PAD;
        t->shelf_x = LT_ATLAS_ORIGIN;
        t->shelf_h = 0;
    }
    if (t->shelf_y + h > LT_ATLAS_SIDE) return 0;  // 页满；调用方按 ATLAS_FULL 如实上报
    *out_x = t->shelf_x;
    *out_y = t->shelf_y;
    t->shelf_x += w + LT_FONT_PAD;
    if (h > t->shelf_h) t->shelf_h = h;
    return 1;
}

// 光栅化到 8bit 灰度，再转成预乘白：R=G=B=A=coverage（着色由顶点色相乘完成）。
// 返回 1 成功；0 = 图集/槽位已满；-1 = 字形加载失败。
static int lt_rasterize(CjguiLinuxText *t, LtFace *f, uint32_t gid, LtSlot *out) {
    if (FT_Load_Glyph(f->ft, gid, FT_LOAD_DEFAULT | FT_LOAD_TARGET_NORMAL) != 0) return -1;
    FT_GlyphSlot g = f->ft->glyph;
    if (!g) return -1;
    if (g->format != FT_GLYPH_FORMAT_BITMAP) {
        if (FT_Render_Glyph(g, FT_RENDER_MODE_NORMAL) != 0) return -1;
    }

    int w = (int)g->bitmap.width;
    int h = (int)g->bitmap.rows;
    out->bx = (int16_t)g->bitmap_left;
    out->by = (int16_t)g->bitmap_top;
    if (w <= 0 || h <= 0) {  // 空格等无墨迹字形：不占槽位
        out->x = 0;
        out->y = 0;
        out->w = 0;
        out->h = 0;
        return 1;
    }
    if (t->slot_count >= LT_GLYPH_CAP) return 0;

    int x = 0, y = 0;
    if (!lt_atlas_alloc(t, w, h, &x, &y)) return 0;

    for (int row = 0; row < h; row++) {
        const uint8_t *src = (const uint8_t *)g->bitmap.buffer + (ptrdiff_t)row * g->bitmap.pitch;
        uint8_t *dst = t->atlas + ((size_t)(y + row) * LT_ATLAS_SIDE + (size_t)x) * 4u;
        for (int col = 0; col < w; col++) {
            uint8_t a = src[col];
            dst[0] = a;
            dst[1] = a;
            dst[2] = a;
            dst[3] = a;
            dst += 4;
        }
    }
    out->x = (int16_t)x;
    out->y = (int16_t)y;
    out->w = (int16_t)w;
    out->h = (int16_t)h;
    lt_dirty_add(t, x, y, w, h);
    return 1;
}

// 取字形槽位（需要时先光栅化）。1 = 可用，0 = 图集满，-1 = 字形加载失败。
static int lt_slot_get(CjguiLinuxText *t, uint32_t face_id, uint32_t gid, int32_t size26_6,
                       LtSlot *out) {
    LtGlyphEntry *e = lt_cache_lookup(t, face_id, gid, size26_6, 1);
    if (!e) return 0;
    if (e->slot != LT_SLOT_UNSET) {
        if (e->slot < 0) return -1;
        *out = t->slots[e->slot];
        return 1;
    }

    lt_face_set_size(t, (int)face_id, size26_6);
    LtSlot s;
    memset(&s, 0, sizeof(s));
    int rc = lt_rasterize(t, &t->faces[face_id], gid, &s);
    if (rc <= 0) {
        e->slot = LT_SLOT_FAILED;
        return rc;
    }
    e->slot = (int32_t)t->slot_count;
    t->slots[t->slot_count] = s;
    t->slot_count++;
    *out = s;
    return 1;
}

// 只测量时的轻量判定：不渲染、不写图集。与 lt_slot_get 对"有没有墨迹"的判断一致
// （缓存命中直接用槽位尺寸）。
static int lt_glyph_has_ink(CjguiLinuxText *t, uint32_t face_id, uint32_t gid, int32_t size26_6) {
    LtGlyphEntry *e = lt_cache_lookup(t, face_id, gid, size26_6, 0);
    if (e && e->slot >= 0) return t->slots[e->slot].w > 0 && t->slots[e->slot].h > 0;
    lt_face_set_size(t, (int)face_id, size26_6);
    if (FT_Load_Glyph(t->faces[face_id].ft, gid, FT_LOAD_DEFAULT | FT_LOAD_TARGET_NORMAL) != 0) {
        return 0;
    }
    FT_GlyphSlot g = t->faces[face_id].ft->glyph;
    return g && g->metrics.width > 0 && g->metrics.height > 0;
}

// ---------------------------------------------------------------- 整形

static int lt_append_cluster(CjguiLinuxText *t, uint32_t byte_start, uint32_t byte_len,
                             uint32_t glyph_start, uint32_t glyph_count, double advance, uint32_t cp,
                             int hard_break) {
    if (!lt_reserve((void **)&t->clusters, &t->cluster_cap, t->cluster_count + 1,
                    sizeof(LtCluster))) {
        return 0;
    }
    LtCluster *c = &t->clusters[t->cluster_count];
    memset(c, 0, sizeof(*c));
    c->byte_start = byte_start;
    c->byte_len = byte_len;
    c->glyph_start = glyph_start;
    c->glyph_count = glyph_count;
    c->advance = advance;
    c->cp = cp;
    c->hard_break = hard_break ? 1u : 0u;
    t->cluster_count++;
    return 1;
}

// 用某个 face 整形 [byte_start, byte_start+byte_len)，把 cluster/glyph 追加到 scratch。
// primary 用于判断"这个 cluster 是不是走了回退族"。
static int lt_shape_run(CjguiLinuxText *t, LtFamilySet *set, int primary, const char *utf8,
                        uint32_t byte_start, uint32_t byte_len, int face_id, uint32_t cp_from,
                        uint32_t cp_to, int32_t size26_6, uint64_t *fb_hash, uint32_t *fb_count) {
    if (byte_len == 0) return 1;
    if (byte_len > (uint32_t)INT_MAX) return 0;

    lt_face_set_size(t, face_id, size26_6);
    LtFace *f = &t->faces[face_id];

    hb_buffer_t *b = t->buf;
    hb_buffer_reset(b);
    hb_buffer_set_cluster_level(b, HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS);
    hb_buffer_add_utf8(b, utf8 + byte_start, (int)byte_len, 0, (int)byte_len);
    hb_buffer_set_direction(b, HB_DIRECTION_LTR);
    hb_buffer_guess_segment_properties(b);
    hb_buffer_set_direction(b, HB_DIRECTION_LTR);  // 本阶段只做 LTR
    hb_shape(f->hb, b, NULL, 0);

    unsigned int n = 0;
    hb_glyph_info_t *info = hb_buffer_get_glyph_infos(b, &n);
    hb_glyph_position_t *pos = hb_buffer_get_glyph_positions(b, &n);
    if (!info || !pos) return 0;

    uint32_t cp_cursor = cp_from;
    const char *run_selected = NULL;  // 本 run 第一个需要回退的地方
    uint32_t run_off = 0;
    for (unsigned int gi = 0; gi < n;) {
        unsigned int cl = info[gi].cluster;
        unsigned int gj = gi;
        while (gj < n && info[gj].cluster == cl) gj++;

        uint32_t abs_off = byte_start + cl;
        while (cp_cursor < cp_to && t->cp_offs[cp_cursor] < abs_off) cp_cursor++;
        uint32_t cp = (cp_cursor < cp_to) ? t->cps[cp_cursor] : 0;

        uint32_t gstart = t->glyph_count;
        double advance = 0.0;
        int notdef = 0;
        for (unsigned int gg = gi; gg < gj; gg++) {
            if (!lt_reserve((void **)&t->glyphs, &t->glyph_cap, t->glyph_count + 1,
                            sizeof(LtGlyph))) {
                return 0;
            }
            LtGlyph *g = &t->glyphs[t->glyph_count++];
            g->face = (uint32_t)face_id;
            g->gid = info[gg].codepoint;
            g->cluster = t->cluster_count;
            g->advance = (double)pos[gg].x_advance / 64.0;
            g->x_offset = (double)pos[gg].x_offset / 64.0;
            g->y_offset = (double)pos[gg].y_offset / 64.0;
            advance += g->advance;
            if (info[gg].codepoint == 0) notdef = 1;
        }

        unsigned int next_cl = (gj < n) ? info[gj].cluster : (unsigned int)byte_len;
        uint32_t cblen = next_cl - cl;
        if (!lt_append_cluster(t, abs_off, cblen, gstart, (uint32_t)(gj - gi), advance, cp, 0)) {
            return 0;
        }

        // 缺字不静默：整形结果落到 .notdef、整条链没人覆盖、或这个 run 走了回退族，
        // 都要留下记录。每个 run 只记第一条（长段落不会把日志刷满），byteOffset 指向
        // 第一次需要回退的那个 cluster。
        if (!run_selected) {
            if (notdef) {
                run_selected = LT_NOTDEF_MARKER;
            } else if (cp_cursor < cp_to && t->cp_nofont[cp_cursor]) {
                run_selected = LT_NO_FONT_MARKER;
            } else if (face_id != primary) {
                run_selected = t->faces[face_id].family;
            }
            if (run_selected) run_off = abs_off;
        }
        gi = gj;
    }
    if (run_selected) {
        lt_push_fallback(t, run_off, set->requested, run_selected, fb_hash, fb_count);
    }
    return 1;
}

// 解码 → 逐码点选字（主字体优先，其次 fontconfig 回退链）→ 逐 run 整形。
static int lt_build(CjguiLinuxText *t, LtFamilySet *set, int primary, const char *utf8, size_t len,
                    int32_t size26_6, uint64_t *fb_hash, uint32_t *fb_count) {
    t->cp_count = 0;
    size_t i = 0;
    while (i < len) {
        if (!lt_reserve_cps(t, t->cp_count + 1)) return 0;
        uint32_t off = (uint32_t)i;
        uint32_t cp = lt_utf8_next((const uint8_t *)utf8, len, &i);
        t->cps[t->cp_count] = cp;
        t->cp_offs[t->cp_count] = off;
        t->cp_face[t->cp_count] = -1;
        t->cp_nofont[t->cp_count] = 0;
        t->cp_count++;
    }

    int cur = primary;
    for (uint32_t k = 0; k < t->cp_count; k++) {
        uint32_t cp = t->cps[k];
        if (cp == '\n') {
            t->cp_face[k] = -1;
            cur = primary;
            continue;
        }
        if (lt_face_covers(t, cur, cp) || lt_cp_is_combining(cp)) {
            t->cp_face[k] = cur;
            continue;
        }
        int fb = lt_find_fallback_face(t, set, cp);
        if (fb >= 0) {
            t->cp_face[k] = fb;
            cur = fb;
        } else {
            // 整条链都没覆盖：仍用主字体（会落到 .notdef），由整形后的检查记录。
            t->cp_face[k] = primary;
            t->cp_nofont[k] = 1;
            cur = primary;
        }
    }

    uint32_t k = 0;
    while (k < t->cp_count) {
        if (t->cps[k] == '\n') {
            if (!lt_append_cluster(t, t->cp_offs[k], 1, t->glyph_count, 0, 0.0, '\n', 1)) return 0;
            k++;
            continue;
        }
        int face = t->cp_face[k];
        uint32_t j = k + 1;
        while (j < t->cp_count && t->cps[j] != '\n' && t->cp_face[j] == face) j++;
        uint32_t b0 = t->cp_offs[k];
        uint32_t b1 = (j < t->cp_count) ? t->cp_offs[j] : (uint32_t)len;
        if (!lt_shape_run(t, set, primary, utf8, b0, b1 - b0, face, k, j, size26_6, fb_hash,
                          fb_count)) {
            return 0;
        }
        k = j;
    }

    for (uint32_t c = 0; c < t->cluster_count; c++) {
        LtCluster *cc = &t->clusters[c];
        cc->is_space = lt_cp_is_space(cc->cp) ? 1u : 0u;
        cc->break_before = ((c > 0) && !cc->hard_break &&
                            (lt_cp_is_breakable(cc->cp) || cc->is_space ||
                             lt_cp_is_space(t->clusters[c - 1].cp)))
                               ? 1u
                               : 0u;
    }
    return 1;
}

// ---------------------------------------------------------------- 换行 / 测量

static void lt_emit_line(CjguiLinuxText *t, uint32_t start, uint32_t end, double pen) {
    // 行尾空白不计入行宽（换行点上的空格是"悬挂"的）。
    double w = pen;
    uint32_t e = end;
    while (e > start && t->clusters[e - 1].is_space) {
        w -= t->clusters[e - 1].advance;
        e--;
    }
    if (!(w > 0.0)) w = 0.0;
    if (!lt_reserve((void **)&t->lines, &t->line_cap, t->line_count + 1, sizeof(LtLine))) return;
    LtLine *l = &t->lines[t->line_count++];
    l->cluster_start = start;
    l->cluster_count = end - start;
    l->width = w;
}

// maxWidth > 0：逻辑点换行；CJK/emoji 逐字断，拉丁词只在空格处断（不需要完整 UAX#14，
// 但不会把词切碎）。maxWidth <= 0：只有显式 '\n' 才换行。
static void lt_wrap(CjguiLinuxText *t, double maxWidth) {
    t->line_count = 0;
    uint32_t i = 0;
    while (i < t->cluster_count) {
        uint32_t line_start = i;
        uint32_t last_break = 0;
        double pen = 0.0;
        double pen_at_break = 0.0;
        int soft_wrapped = 0;
        for (;;) {
            if (i >= t->cluster_count) {
                lt_emit_line(t, line_start, i, pen);
                break;
            }
            const LtCluster *c = &t->clusters[i];
            if (c->hard_break) {
                lt_emit_line(t, line_start, i, pen);
                i++;
                break;
            }
            if (maxWidth > 0.0 && i > line_start && pen + c->advance > maxWidth) {
                // 溢出：优先在当前位置断开（前提是这里本身允许起新行，例如 CJK 逐字断行），
                // 否则退回上一个可断点（保证拉丁词不被切碎）。
                uint32_t cut = 0;
                if (c->break_before) {
                    cut = i;
                } else if (last_break > line_start) {
                    cut = last_break;
                }
                if (cut > line_start) {
                    lt_emit_line(t, line_start, cut, cut == i ? pen : pen_at_break);
                    i = cut;
                } else {
                    // 没有任何断点（超宽的长词/单字）：整体放不下也得断开，否则死循环。
                    lt_emit_line(t, line_start, i, pen);
                }
                soft_wrapped = 1;
                break;
            }
            if (i > line_start && c->break_before) {
                last_break = i;
                pen_at_break = pen;
            }
            pen += c->advance;
            i++;
        }
        if (soft_wrapped) {
            // 软换行后的行首空白不算进新行。
            while (i < t->cluster_count && !t->clusters[i].hard_break && t->clusters[i].is_space) i++;
        }
    }
}

static uint32_t lt_count_quads(CjguiLinuxText *t, int32_t size26_6) {
    uint32_t q = 0;
    for (uint32_t c = 0; c < t->cluster_count; c++) {
        const LtCluster *cl = &t->clusters[c];
        for (uint32_t k = 0; k < cl->glyph_count; k++) {
            const LtGlyph *g = &t->glyphs[cl->glyph_start + k];
            if (lt_glyph_has_ink(t, g->face, g->gid, size26_6)) q++;
        }
    }
    return q;
}

// 只发形状：需要光栅化的地方才动图集。位置按整像素吸附，避免亚像素模糊。
static void lt_emit_quads(CjguiLinuxText *t, int32_t size26_6, double originX, double originY,
                          CjguiLinuxTextQuad *out, uint32_t capacity, uint32_t *out_needed,
                          int *out_atlas_full) {
    const double side = (double)LT_ATLAS_SIDE;
    uint32_t q = 0;
    int full = 0;
    for (uint32_t li = 0; li < t->line_count; li++) {
        const LtLine *line = &t->lines[li];
        double baseline = originY + (double)li * t->layout_line_height + t->layout_ascent;
        double pen = 0.0;
        uint32_t cend = line->cluster_start + line->cluster_count;
        if (cend > t->cluster_count) cend = t->cluster_count;
        for (uint32_t ci = line->cluster_start; ci < cend; ci++) {
            const LtCluster *cl = &t->clusters[ci];
            if (cl->hard_break) continue;
            for (uint32_t k = 0; k < cl->glyph_count; k++) {
                const LtGlyph *g = &t->glyphs[cl->glyph_start + k];
                LtSlot s;
                int rc = lt_slot_get(t, g->face, g->gid, size26_6, &s);
                if (rc == 0) {
                    full = 1;
                    pen += g->advance;
                    continue;
                }
                if (rc < 0) {
                    pen += g->advance;
                    continue;
                }
                if (s.w > 0 && s.h > 0) {
                    if (q < capacity) {
                        CjguiLinuxTextQuad *qd = &out[q];
                        double gx = floor(originX + pen + g->x_offset + 0.5);
                        double gy = floor(baseline - g->y_offset + 0.5);
                        qd->x = (float)(gx + (double)s.bx);
                        qd->y = (float)(gy - (double)s.by);
                        qd->width = (float)s.w;
                        qd->height = (float)s.h;
                        qd->u0 = (float)((double)s.x / side);
                        qd->v0 = (float)((double)s.y / side);
                        qd->u1 = (float)((double)(s.x + s.w) / side);
                        qd->v1 = (float)((double)(s.y + s.h) / side);
                    }
                    q++;
                }
                pen += g->advance;
            }
        }
    }
    *out_needed = q;
    *out_atlas_full = full;
}

// ---------------------------------------------------------------- 查询前奏
//
// 解析族 → 设尺寸 → 整形 → 换行。layout 与 caret/line 查询都只走这一条路径，
// 因此三者的行断点、cluster 划分、advance 必然一致（这是光标/选区对得上字的唯一
// 判据）。不写图集、不光栅化。

static int lt_prepare(CjguiLinuxText *t, const char *utf8, size_t len, double fontSize,
                      uint32_t fontWeight, uint32_t fontFamily, double maxWidth, int32_t *out_ps) {
    if (!t) return CJGUI_LINUX_TEXT_INVALID;
    if (!utf8 && len) return CJGUI_LINUX_TEXT_INVALID;

    int32_t ps = lt_pixel_size(fontSize);
    LtFamilySet *set = lt_family_set(t, fontFamily, fontWeight);
    if (!lt_family_resolve(t, set)) return CJGUI_LINUX_TEXT_NO_FONT;
    int primary = lt_chain_face(t, set, 0);
    if (primary < 0) return CJGUI_LINUX_TEXT_NO_FONT;
    lt_face_set_size(t, primary, ps);
    t->layout_ascent = t->faces[primary].ascent;
    t->layout_line_height = t->faces[primary].line_height;

    lt_family_alias_note(t, set);

    t->cluster_count = 0;
    t->glyph_count = 0;
    t->line_count = 0;

    uint64_t fb_hash = 0;
    uint32_t fb_count = 0;
    if (!lt_build(t, set, primary, utf8, len, ps, &fb_hash, &fb_count)) {
        return CJGUI_LINUX_TEXT_SHAPE_FAILED;
    }
    lt_wrap(t, maxWidth);

    if (fb_count > 0 && fb_count == t->last_fb_count && fb_hash == t->last_fb_hash) {
        lt_pop_fallback(t, fb_count);
    } else {
        t->last_fb_count = fb_count;
        t->last_fb_hash = fb_hash;
    }
    if (out_ps) *out_ps = ps;
    return CJGUI_LINUX_TEXT_OK;
}

// byteOffset 落在哪个 cluster：取最后一个起点 <= offset 的（不在字符边界上就吸附到
// 前一个边界）。没有 cluster 时返回 0。
static uint32_t lt_cluster_for_offset(const CjguiLinuxText *t, size_t byteOffset) {
    uint32_t c = 0;
    for (uint32_t i = 0; i < t->cluster_count; i++) {
        if ((size_t)t->clusters[i].byte_start <= byteOffset) {
            c = i;
        } else {
            break;
        }
    }
    return c;
}

// 该 cluster 属于哪一行：取最后一个 cluster_start <= c 的行。这样软换行边界归下一行
// 起点、'\n'（不属于任何行的 hard break cluster）归上一行末尾、连续 '\n' 之间的空行
// 也各自有归属。
static uint32_t lt_line_for_cluster(const CjguiLinuxText *t, uint32_t c) {
    uint32_t li = 0;
    for (uint32_t i = 0; i < t->line_count; i++) {
        if (t->lines[i].cluster_start <= c) {
            li = i;
        } else {
            break;
        }
    }
    return li;
}

// 行的字节范围 [start, end)。空行退化到它所在的位置。
static void lt_line_bytes(const CjguiLinuxText *t, uint32_t li, size_t len, size_t *out_start,
                          size_t *out_end) {
    const LtLine *line = &t->lines[li];
    uint32_t cs = line->cluster_start;
    uint32_t ce = cs + line->cluster_count;
    if (ce > t->cluster_count) ce = t->cluster_count;
    uint32_t start = 0;
    uint32_t end = 0;
    if (ce > cs) {
        start = t->clusters[cs].byte_start;
        end = t->clusters[ce - 1].byte_start + t->clusters[ce - 1].byte_len;
    } else {
        end = (cs < t->cluster_count) ? t->clusters[cs].byte_start : (uint32_t)len;
        start = end;
    }
    if (out_start) *out_start = (size_t)start;
    if (out_end) *out_end = (size_t)end;
}

// ---------------------------------------------------------------- 公开接口

CjguiLinuxText *cjgui_linux_text_create(int *outStatus) {
    if (outStatus) *outStatus = CJGUI_LINUX_TEXT_OK;
    if (!FcInit()) {
        if (outStatus) *outStatus = CJGUI_LINUX_TEXT_NO_FONT;
        return NULL;
    }
    CjguiLinuxText *t = (CjguiLinuxText *)calloc(1, sizeof(*t));
    if (!t) {
        if (outStatus) *outStatus = CJGUI_LINUX_TEXT_INVALID;
        return NULL;
    }
    if (FT_Init_FreeType(&t->ft) != 0) {
        free(t);
        if (outStatus) *outStatus = CJGUI_LINUX_TEXT_NO_FONT;
        return NULL;
    }
    t->buf = hb_buffer_create();
    if (!t->buf) {
        FT_Done_FreeType(t->ft);
        free(t);
        if (outStatus) *outStatus = CJGUI_LINUX_TEXT_INVALID;
        return NULL;
    }
    for (int fi = 0; fi < 8; fi++) {
        t->families[fi].family_kind = (fi >= 4) ? 1 : 0;
        t->families[fi].weight = fi & 3;
        t->families[fi].state = 0;
    }
    t->shelf_x = LT_ATLAS_ORIGIN;
    t->shelf_y = LT_ATLAS_ORIGIN;
    t->shelf_h = 0;
    // 左上 2x2：实心几何用的白色纹素（RGBA 全 255），也是第一块脏区。
    for (int y = 0; y < LT_ATLAS_ORIGIN; y++) {
        for (int x = 0; x < LT_ATLAS_ORIGIN; x++) {
            uint8_t *p = t->atlas + ((size_t)y * LT_ATLAS_SIDE + (size_t)x) * 4u;
            p[0] = 255;
            p[1] = 255;
            p[2] = 255;
            p[3] = 255;
        }
    }
    lt_dirty_add(t, 0, 0, LT_ATLAS_ORIGIN, LT_ATLAS_ORIGIN);
    return t;
}

void cjgui_linux_text_destroy(CjguiLinuxText *text) {
    if (!text) return;
    if (text->buf) hb_buffer_destroy(text->buf);
    for (int i = 0; i < text->face_count; i++) {
        if (text->faces[i].hb) hb_font_destroy(text->faces[i].hb);
        if (text->faces[i].ft) FT_Done_Face(text->faces[i].ft);
        free(text->faces[i].path);
    }
    for (int i = 0; i < 8; i++) {
        if (text->families[i].fonts) FcFontSetDestroy(text->families[i].fonts);
        free(text->families[i].face_ids);
    }
    free(text->clusters);
    free(text->glyphs);
    free(text->lines);
    free(text->cps);
    free(text->cp_offs);
    free(text->cp_face);
    free(text->cp_nofont);
    if (text->ft) FT_Done_FreeType(text->ft);
    free(text);
    // 不调用 FcFini()：fontconfig 的全局状态可能被其它实例共用。
}

const uint8_t *cjgui_linux_text_atlas_pixels(CjguiLinuxText *text) {
    return text ? text->atlas : NULL;
}

int cjgui_linux_text_atlas_side(CjguiLinuxText *text) {
    (void)text;
    return LT_ATLAS_SIDE;
}

int cjgui_linux_text_take_atlas_dirty(CjguiLinuxText *text, int *x, int *y, int *width,
                                      int *height) {
    if (!text || lt_dirty_is_empty(text)) return 0;
    if (x) *x = text->dirty_x0;
    if (y) *y = text->dirty_y0;
    if (width) *width = text->dirty_x1 - text->dirty_x0;
    if (height) *height = text->dirty_y1 - text->dirty_y0;
    lt_dirty_clear(text);
    return 1;
}

double cjgui_linux_text_line_height(CjguiLinuxText *text, double fontSize, uint32_t fontWeight,
                                    uint32_t fontFamily) {
    if (!text) return 0.0;
    int32_t ps = lt_pixel_size(fontSize);
    LtFamilySet *set = lt_family_set(text, fontFamily, fontWeight);
    if (!lt_family_resolve(text, set)) return 0.0;
    int primary = lt_chain_face(text, set, 0);
    if (primary < 0) return 0.0;
    lt_face_set_size(text, primary, ps);
    return text->faces[primary].line_height;
}

int cjgui_linux_text_layout(CjguiLinuxText *text, const char *utf8, size_t len, double fontSize,
                            uint32_t fontWeight, uint32_t fontFamily, double maxWidth, double originX,
                            double originY, int wantQuads, CjguiLinuxTextQuad *outQuads,
                            uint32_t quadCapacity, uint32_t *outQuadCount, double *outWidth,
                            double *outHeight, double *outAscent) {
    if (!text || !outQuadCount) return CJGUI_LINUX_TEXT_INVALID;
    if (wantQuads && !outQuads) return CJGUI_LINUX_TEXT_INVALID;

    int32_t ps = 0;
    int status = lt_prepare(text, utf8, len, fontSize, fontWeight, fontFamily, maxWidth, &ps);
    if (status != CJGUI_LINUX_TEXT_OK) return status;

    double width = 0.0;
    for (uint32_t i = 0; i < text->line_count; i++) {
        if (text->lines[i].width > width) width = text->lines[i].width;
    }
    double height = (double)text->line_count * text->layout_line_height;

    uint32_t needed = 0;
    int atlas_full = 0;
    if (wantQuads) {
        lt_emit_quads(text, ps, originX, originY, outQuads, quadCapacity, &needed, &atlas_full);
    } else {
        needed = lt_count_quads(text, ps);  // 只测量：不渲染、不写图集
    }

    *outQuadCount = needed;
    if (outWidth) *outWidth = width;
    if (outHeight) *outHeight = height;
    if (outAscent) *outAscent = text->layout_ascent;

    if (atlas_full) return CJGUI_LINUX_TEXT_ATLAS_FULL;
    if (wantQuads && needed > quadCapacity) return CJGUI_LINUX_TEXT_BUDGET_EXCEEDED;
    return CJGUI_LINUX_TEXT_OK;
}

uint32_t cjgui_linux_text_take_fallback_log(CjguiLinuxText *text, CjguiLinuxTextFallback *outEntries,
                                            uint32_t capacity) {
    if (!text || !outEntries || capacity == 0 || text->pend_count == 0) return 0;
    uint32_t n = (text->pend_count < capacity) ? text->pend_count : capacity;
    for (uint32_t i = 0; i < n; i++) {
        outEntries[i] = text->pend[(text->pend_head + i) % LT_FALLBACK_CAP];
    }
    text->pend_head = (text->pend_head + n) % LT_FALLBACK_CAP;
    text->pend_count -= n;
    if (text->pend_count == 0) text->pend_head = 0;
    return n;
}

void cjgui_linux_text_stats(CjguiLinuxText *text, uint32_t *outGlyphCount, uint32_t *outAtlasBytes) {
    if (!text) {
        if (outGlyphCount) *outGlyphCount = 0;
        if (outAtlasBytes) *outAtlasBytes = 0;
        return;
    }
    uint32_t bytes = 0;
    for (uint32_t i = 0; i < text->slot_count; i++) {
        bytes += (uint32_t)text->slots[i].w * (uint32_t)text->slots[i].h * 4u;
    }
    if (outGlyphCount) *outGlyphCount = text->slot_count;
    if (outAtlasBytes) *outAtlasBytes = bytes;
}

// ---------------------------------------------------------------- 光标 / 行几何
//
// 下面三个查询与 layout 共用 lt_prepare（同一套整形 + 换行 + advance），所以断点、
// 行号、x 必然与画出来的字形对得上；它们不写图集。

int cjgui_linux_text_caret_position(CjguiLinuxText *text, const char *utf8, size_t len,
                                    double fontSize, uint32_t fontWeight, uint32_t fontFamily,
                                    double maxWidth, size_t byteOffset, double *outX, double *outTop,
                                    double *outLineHeight, uint32_t *outLineIndex,
                                    size_t *outLineStartByte, size_t *outLineEndByte) {
    int32_t ps = 0;
    int status = lt_prepare(text, utf8, len, fontSize, fontWeight, fontFamily, maxWidth, &ps);
    if (status != CJGUI_LINUX_TEXT_OK) return status;
    (void)ps;

    double line_height = text->layout_line_height;
    if (text->line_count == 0 || text->cluster_count == 0) {
        // 空串：退化成 0 号空行，光标仍然可表达。
        if (outX) *outX = 0.0;
        if (outTop) *outTop = 0.0;
        if (outLineHeight) *outLineHeight = line_height;
        if (outLineIndex) *outLineIndex = 0;
        if (outLineStartByte) *outLineStartByte = 0;
        if (outLineEndByte) *outLineEndByte = 0;
        return CJGUI_LINUX_TEXT_OK;
    }

    uint32_t cluster = lt_cluster_for_offset(text, byteOffset);
    uint32_t li = lt_line_for_cluster(text, cluster);
    const LtLine *line = &text->lines[li];

    // 插入点在"字节边界"上：累加所有完全位于该偏移之前的 cluster 的 advance。
    // 偏移落在 cluster 内部时会吸附到它的起点（即不算它），与"取前一个边界"一致。
    double x = 0.0;
    uint32_t cend = line->cluster_start + line->cluster_count;
    if (cend > text->cluster_count) cend = text->cluster_count;
    for (uint32_t i = line->cluster_start; i < cend; i++) {
        const LtCluster *cl = &text->clusters[i];
        if ((size_t)cl->byte_start + (size_t)cl->byte_len <= byteOffset) x += cl->advance;
    }
    // 行尾空白是悬挂的：光标不越出该行的可视行宽（与 line_rect 的宽度同一口径）。
    if (x > line->width) x = line->width;
    if (x < 0.0) x = 0.0;

    if (outX) *outX = x;
    if (outTop) *outTop = (double)li * line_height;
    if (outLineHeight) *outLineHeight = line_height;
    if (outLineIndex) *outLineIndex = li;
    lt_line_bytes(text, li, len, outLineStartByte, outLineEndByte);
    return CJGUI_LINUX_TEXT_OK;
}

int cjgui_linux_text_line_rect(CjguiLinuxText *text, const char *utf8, size_t len, double fontSize,
                               uint32_t fontWeight, uint32_t fontFamily, double maxWidth,
                               uint32_t lineIndex, double *outX, double *outY, double *outWidth,
                               double *outHeight, size_t *outStartByte, size_t *outEndByte) {
    int32_t ps = 0;
    int status = lt_prepare(text, utf8, len, fontSize, fontWeight, fontFamily, maxWidth, &ps);
    if (status != CJGUI_LINUX_TEXT_OK) return status;
    (void)ps;

    const double line_height = text->layout_line_height;
    if (lineIndex >= text->line_count) {
        if (!(text->line_count == 0 && lineIndex == 0)) return CJGUI_LINUX_TEXT_INVALID;
        // 空串：0 号退化空行，宽 0、高为行高。
        if (outX) *outX = 0.0;
        if (outY) *outY = 0.0;
        if (outWidth) *outWidth = 0.0;
        if (outHeight) *outHeight = line_height;
        if (outStartByte) *outStartByte = 0;
        if (outEndByte) *outEndByte = 0;
        return CJGUI_LINUX_TEXT_OK;
    }

    if (outX) *outX = 0.0;  // 每行都从文本块左边缘开始（本阶段无缩进/居中）
    if (outY) *outY = (double)lineIndex * line_height;
    if (outWidth) *outWidth = text->lines[lineIndex].width;
    if (outHeight) *outHeight = line_height;
    lt_line_bytes(text, lineIndex, len, outStartByte, outEndByte);
    return CJGUI_LINUX_TEXT_OK;
}

int cjgui_linux_text_line_count(CjguiLinuxText *text, const char *utf8, size_t len, double fontSize,
                                uint32_t fontWeight, uint32_t fontFamily, double maxWidth,
                                uint32_t *outLines) {
    if (!outLines) return CJGUI_LINUX_TEXT_INVALID;
    int32_t ps = 0;
    int status = lt_prepare(text, utf8, len, fontSize, fontWeight, fontFamily, maxWidth, &ps);
    if (status != CJGUI_LINUX_TEXT_OK) return status;
    (void)ps;
    *outLines = text->line_count;
    return CJGUI_LINUX_TEXT_OK;
}
