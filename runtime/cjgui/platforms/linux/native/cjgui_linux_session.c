// runtime/cjgui/platforms/linux/native/cjgui_linux_session.c
//
// Linux 平台的 C ABI 会话层：把仓颉共同层已有的场景/文字/输入契约接到
// X11 + Vulkan + Fontconfig/HarfBuzz/FreeType 三个窄实现上。
//
// 分工（见 cjgui_linux_{window,vulkan,text}.h）：
//   linux_window.c  —— 系统窗口与系统输入
//   linux_vulkan.c  —— 三角形到像素与 present
//   linux_text.c    —— 测量/整形/字形图集
//   本文件          —— 会话状态、场景暂存、命中路由、事件翻译、退出握手
//
// 共同层仍是权威：本文件不复制布局、选择、撤销、正文版本任何一条规则，只回答
// "这一帧画什么""这个点落在哪个节点""这次按键在该节点上替换了哪一段"。
//
// 刻意不做的事（如实拒绝而不是静默成功）：
//   * no owner handoff / installed range / selection transfer / source range：
//     相应入口返回具名状态或空结果，且不写入任何"已完成"的假状态。
//   * 无 macOS Metal 桥：本文件是唯一 ABI 实现点，不做假的 native_bridge。
//   * IME（XIM/XIC）属第二阶段；本阶段只做 ASCII 直输，占位在 window 模块。
//   * 消费者经 set_composable_text_runs 声明的预览选区**本阶段不解析**：选区底色
//     只画 native 自己拥有的那份选区（正在编辑的文本代理）。所以"所有选区都会上色"
//     不成立，最终报告按此口径记录。

#define _POSIX_C_SOURCE 200809L

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <pthread.h>

#include "cjgui_internal_renderer.h"
#include "cjgui_linux_window.h"
#include "cjgui_linux_vulkan.h"
#include "cjgui_linux_text.h"
#include "cjgui_linux_aux.h"
#include "cjgui_linux_services.h"
#include "cjgui_linux_installed_range.h"

#define CJGUI_LINUX_MAX_SESSIONS 2u
#define CJGUI_LINUX_MAX_NODES 1024u
// 剪贴板和组合提交共用的整值载荷。超限在修改代理前具名拒绝，绝不截断。
#define CJGUI_LINUX_FORM_TEXT_CAPACITY 65536u
#define CJGUI_LINUX_STRING_CAPACITY 2048u

// ---------------------------------------------------------------- 工具

static char *cjgui_linux_strdup(const char *value) {
    if (!value) return NULL;
    size_t length = strlen(value);
    char *copy = (char *)malloc(length + 1u);
    if (!copy) return NULL;
    memcpy(copy, value, length + 1u);
    return copy;
}

static void cjgui_linux_strfree(char **slot) {
    if (slot && *slot) {
        free(*slot);
        *slot = NULL;
    }
}

static void cjgui_linux_replace(char **slot, const char *value) {
    char *copy = cjgui_linux_strdup(value);
    cjgui_linux_strfree(slot);
    *slot = copy;
}

static uint64_t cjgui_linux_now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

// UTF-8 <-> UTF-16 换算（BMP 之外按代理对计 2 个 UTF-16 单元）。事件里的
// selectionStart/End 与 replacement*16 都是 UTF-16 单位，与共同层一致。

static uint32_t cjgui_linux_utf8_scalar(const char *text, size_t length, size_t *index) {
    const unsigned char *p = (const unsigned char *)text + *index;
    size_t remaining = length - *index;
    if (remaining == 0u) return 0u;
    unsigned char first = p[0];
    if (first < 0x80u) { *index += 1u; return first; }
    uint32_t value = 0u; size_t need = 0u;
    if ((first & 0xE0u) == 0xC0u) { value = first & 0x1Fu; need = 1u; }
    else if ((first & 0xF0u) == 0xE0u) { value = first & 0x0Fu; need = 2u; }
    else if ((first & 0xF8u) == 0xF0u) { value = first & 0x07u; need = 3u; }
    else { *index += 1u; return 0xFFFDu; }
    if (remaining < need + 1u) { *index = length; return 0xFFFDu; }
    for (size_t i = 1u; i <= need; i += 1u) {
        if ((p[i] & 0xC0u) != 0x80u) { *index += 1u; return 0xFFFDu; }
        value = (value << 6) | (uint32_t)(p[i] & 0x3Fu);
    }
    *index += need + 1u;
    return value;
}

static uint32_t cjgui_linux_utf16_length(const char *text, size_t length) {
    uint32_t units = 0u; size_t index = 0u;
    while (index < length) {
        uint32_t scalar = cjgui_linux_utf8_scalar(text, length, &index);
        units += (scalar > 0xFFFFu) ? 2u : 1u;
    }
    return units;
}

// UTF-16 单位数 -> 字节偏移；越界时返回长度。
static size_t cjgui_linux_byte_offset_for_utf16(const char *text, size_t length, uint32_t units) {
    uint32_t seen = 0u; size_t index = 0u;
    while (index < length && seen < units) {
        size_t start = index;
        uint32_t scalar = cjgui_linux_utf8_scalar(text, length, &index);
        seen += (scalar > 0xFFFFu) ? 2u : 1u;
        if (seen > units) return start;   // 落在代理对中间：不切开
    }
    return index;
}

static uint32_t cjgui_linux_utf16_for_byte_offset(const char *text, size_t length, size_t offset) {
    if (offset > length) offset = length;
    return cjgui_linux_utf16_length(text, offset);
}

// ---------------------------------------------------------------- 会话状态

typedef struct CjguiLinuxNodeSlot {
    CjguiInternalRendererComposableNode node;
    CjguiInternalRendererComposableGeometry geometry;
    int geometryPresent;
    char *label;
    char *value;
    char *imageResourcePath;
    char *imageResourceId;
    uint64_t imageResourceVersion;
    char *semanticId;
    char *bindingKey;
    char *rowKey;
    char *parentRowKey;
    char *semanticLabel;
    char *encodedRuns;
} CjguiLinuxNodeSlot;

typedef struct CjguiLinuxScene {
    int valid;
    uint64_t projectionVersion;
    uint32_t nodeCount;
    uint32_t capacity;
    CjguiLinuxNodeSlot *slots;
} CjguiLinuxScene;

typedef struct CjguiLinuxActiveTextProxy {
    int active;
    uint64_t nodeId;
    int64_t resourceId;
    uint32_t nodeKind;
    uint64_t sceneVersion;
    // set_composable_owned_text_session 声明的绑定代。共同层用它在
    // composable_ui_window.cj:5087 判定一条 51 号范围意图是否属于当前窗口文本会话；
    // 事件不带这个代就不会被路由给会话，只会落到控制器并被当成"泄漏"。
    uint64_t bindingEpoch;
    char *value;
    uint32_t selectionStart16;
    uint32_t selectionEnd16;
} CjguiLinuxActiveTextProxy;

typedef struct CjguiLinuxSession {
    int alive;
    uint64_t token;
    CjguiLinuxWindow *window;
    CjguiLinuxGpu *gpu;
    CjguiLinuxText *text;

    uint32_t requestedWidth;
    uint32_t requestedHeight;
    double clear[4];
    uint64_t frameIndex;

    CjguiLinuxScene accepted;
    CjguiLinuxScene candidate;
    int preparationActive;
    uint64_t preparationId;

    CjguiLinuxActiveTextProxy proxy;
    int rangeEditDeltaEnabled;

    // 最近一次产生的事件所需的值载荷（在这些 getter 的契约里"借用到下一次
    // 事件泵或下一次表单更新"）。
    char formText[CJGUI_LINUX_FORM_TEXT_CAPACITY];
    char transferFormat[CJGUI_LINUX_STRING_CAPACITY];
    char transferSourceKind[CJGUI_LINUX_STRING_CAPACITY];
    char transferSourceIdentity[CJGUI_LINUX_STRING_CAPACITY];
    int64_t transferSourceId;
    int64_t transferExpectedOwnerVersion;
    uint64_t transferDeliveryOrdinal;
    uint8_t transferBytes[4096];
    uint32_t transferByteLength;
    uint64_t transferEventId;

    // 指针路由：按下时认定的目标，抬起时只有同一目标才算激活。
    int pointerDown;
    uint64_t pointerNodeId;
    int64_t pointerResourceId;
    uint32_t pointerNodeKind;
    CjguiInternalRendererPointerEventGeometry lastGeometry;

    // 窗口背景（stage + 快照读回）。
    int backgroundStaged;
    uint32_t backgroundMode;
    uint32_t backgroundColorScheme;
    uint64_t backgroundVersion;
    double backgroundRed;
    double backgroundGreen;
    double backgroundBlue;
    double backgroundAlpha;

    // 输入光标条（declare_input_caret）。
    int64_t caretNodeId;
    double caretX;
    double caretY;
    double caretWidth;
    double caretHeight;

    // XIM 组合态到共同层 kind 52 的映射。起点/长度在组合开始时冻结；每次 update
    // 携带上一份 preedit 的 UTF-16 长度，提交时替换同一段。
    int compositionActive;
    uint32_t compositionIdCounter;
    uint32_t compositionId;
    uint32_t compositionStart16;
    uint32_t compositionLength16;          // 上一份 preedit 的 UTF-16 长度
    uint32_t compositionReplaceLength16;   // 组合开始时被替换的选区长度（投影用）
    char compositionText[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
    size_t compositionTextLength;

    // 异步粘贴：请求发出后普通泵继续跑，结果到达再走一次范围编辑。
    int pastePending;
    uint64_t pasteDeadlineMs;

    // Platform-level source install gate（本阶段只有门状态，不做数据搬运）。
    int sourceGatePending;
    uint64_t sourceGateEpoch;
    uint64_t sourceGateRequest;

    // 窗口激活状态。
    int windowKey;
    int windowMain;
    int windowAppActive;

    int ownsExitLifecycleOwner;

    // 诊断用的真实计数（消费方把它们当基线数字用，不能是编出来的）。
    uint64_t nodeWriteCount;
    uint64_t nodeCloneCount;
    uint64_t nodeAllocationCount;
    uint64_t textLayoutPreparationCount;
    uint64_t textRasterCount;
    uint64_t textUploadCount;
    uint64_t textUploadBytes;
    int diagnosticTimingEnabled;

    // 最近一次范围意图的三段正文（installed-range 生产者读它）。借用到下一次泵。
    CjguiLinuxRangeIntentView rangeIntent;
    char *rangePreBody;
    char *rangePostBody;
    char *rangeReplacement;

    // 文字样式 run 声明表：共同层在 configure 之后、节点入库之前就安装声明
    // （见 composable_ui_window.cj:10678 的 S1 顺序），所以它必须独立于场景槽位
    // 按 nodeId 保存，并在该节点真正入库时挂上去。按"先查已入库节点"实现会
    // 在第一次安装就返回 NODE_NOT_FOUND，导致候选被拒、窗口永远出不来。
#define CJGUI_LINUX_MAX_RUN_DECLARATIONS 64u
    struct {
        uint64_t nodeId;
        char *encoded;
    } runs[CJGUI_LINUX_MAX_RUN_DECLARATIONS];
    uint32_t runCount;

    // 一次 X11 事件可能产生多条 CJGUI 意图（例如抬起同时是 POINTER_END /
    // PRESS_END / ACTIVATE），而 pump_event 每次只返回一条，所以这里有一个
    // 会话内的小队列：不合并、不重排，按产生顺序逐条交出。
#define CJGUI_LINUX_PENDING_EVENTS 16u
// 逐事件文本载荷与整值/剪贴板容量一致：一次提交或粘贴是一笔逻辑编辑，
// 不能按单字符假设，也不能只搬运前缀。
#define CJGUI_LINUX_PENDING_TEXT CJGUI_LINUX_FORM_TEXT_CAPACITY
    // 单个 X11 事件最多产生 3 条意图（抬起：POINTER_END / PRESS_END / ACTIVATE）。
    // 泵在读取每个 X11 事件之前按这个上界预留槽位；没有槽位就不读，事件仍留在
    // X11 队列里。这样"容量不足"发生在修改代理之前，既不丢已接收事件，也不清队列。
#define CJGUI_LINUX_PENDING_PER_EVENT 3u
    struct {
        CjguiInternalRendererEvent event;
        char text[CJGUI_LINUX_PENDING_TEXT];
        int hasText;
        // 命中几何与事件在同一次捕获里产生，并随这条事件一起出队；
        // pumped_pointer_geometry 只交出刚被消费的那一条（同 Windows pointerGeometries）。
        CjguiInternalRendererPointerEventGeometry geometry;
        int hasGeometry;
        // range 意图的三段正文只属于产生它的那条事件，不再共用会话单槽，
        // 否则快速连续输入时后一笔会覆盖前一笔而事件仍指向旧载荷。
        CjguiLinuxRangeIntentView rangeIntent;
        int hasRangeIntent;
        char *rangePreBody;
        char *rangePostBody;
        char *rangeReplacement;
    } pending[CJGUI_LINUX_PENDING_EVENTS];
    uint32_t pendingCount;
    uint32_t pendingHead;
    uint64_t pendingOverflowCount;
    uint64_t rangeIntentProduced;
    int exitRequested;
} CjguiLinuxSession;

static CjguiLinuxSession g_sessions[CJGUI_LINUX_MAX_SESSIONS];
static uint64_t g_nextToken = 1u;
static int g_stopRequested = 0;
static int g_exitLifecycleRetainCount = 0;
static int g_exitLifecycleOwnerHeld = 0;

static CjguiLinuxSession *cjgui_linux_lookup(uint64_t token) {
    for (uint32_t i = 0u; i < CJGUI_LINUX_MAX_SESSIONS; i += 1u) {
        CjguiLinuxSession *session = &g_sessions[i];
        if (session->alive && session->token == token) return session;
    }
    return NULL;
}

// ---------------------------------------------------------------- 文字 run 声明

static const char *cjgui_linux_run_lookup(CjguiLinuxSession *session, uint64_t nodeId) {
    for (uint32_t i = 0u; i < session->runCount; i += 1u) {
        if (session->runs[i].nodeId == nodeId) return session->runs[i].encoded;
    }
    return NULL;
}

static void cjgui_linux_run_apply(CjguiLinuxSession *session, CjguiLinuxNodeSlot *slot) {
    if (!session || !slot) return;
    const char *encoded = cjgui_linux_run_lookup(session, slot->node.nodeId);
    cjgui_linux_replace(&slot->encodedRuns, encoded ? encoded : "");
}

// ---------------------------------------------------------------- 场景槽位

// 深拷贝一个槽位（含全部字符串）。共同层的直接路径只发**变化过的**节点，跳过的
// 索引必须由 native 从上一代已接受场景克隆，所以 configure 要能整槽复制。
static void cjgui_linux_slot_copy(CjguiLinuxNodeSlot *dst, const CjguiLinuxNodeSlot *src) {
    if (!dst || !src) return;
    cjgui_linux_replace(&dst->label, src->label ? src->label : "");
    cjgui_linux_replace(&dst->value, src->value ? src->value : "");
    cjgui_linux_replace(&dst->imageResourcePath, src->imageResourcePath ? src->imageResourcePath : "");
    cjgui_linux_replace(&dst->imageResourceId, src->imageResourceId ? src->imageResourceId : "");
    cjgui_linux_replace(&dst->semanticId, src->semanticId ? src->semanticId : "");
    cjgui_linux_replace(&dst->bindingKey, src->bindingKey ? src->bindingKey : "");
    cjgui_linux_replace(&dst->rowKey, src->rowKey ? src->rowKey : "");
    cjgui_linux_replace(&dst->parentRowKey, src->parentRowKey ? src->parentRowKey : "");
    cjgui_linux_replace(&dst->semanticLabel, src->semanticLabel ? src->semanticLabel : "");
    cjgui_linux_replace(&dst->encodedRuns, src->encodedRuns ? src->encodedRuns : "");
    dst->node = src->node;
    dst->geometry = src->geometry;
    dst->geometryPresent = src->geometryPresent;
    dst->imageResourceVersion = src->imageResourceVersion;
}

static void cjgui_linux_slot_clear(CjguiLinuxNodeSlot *slot) {
    if (!slot) return;
    cjgui_linux_strfree(&slot->label);
    cjgui_linux_strfree(&slot->value);
    cjgui_linux_strfree(&slot->imageResourcePath);
    cjgui_linux_strfree(&slot->imageResourceId);
    cjgui_linux_strfree(&slot->semanticId);
    cjgui_linux_strfree(&slot->bindingKey);
    cjgui_linux_strfree(&slot->rowKey);
    cjgui_linux_strfree(&slot->parentRowKey);
    cjgui_linux_strfree(&slot->semanticLabel);
    cjgui_linux_strfree(&slot->encodedRuns);
    memset(&slot->node, 0, sizeof(slot->node));
    memset(&slot->geometry, 0, sizeof(slot->geometry));
    slot->geometryPresent = 0;
    slot->imageResourceVersion = 0u;
}

static void cjgui_linux_scene_reset(CjguiLinuxScene *scene) {
    if (!scene) return;
    for (uint32_t i = 0u; i < scene->capacity; i += 1u) {
        cjgui_linux_slot_clear(&scene->slots[i]);
    }
    free(scene->slots);
    scene->slots = NULL;
    scene->capacity = 0u;
    scene->nodeCount = 0u;
    scene->projectionVersion = 0u;
    scene->valid = 0;
}

static int cjgui_linux_scene_reserve(CjguiLinuxScene *scene, uint32_t count) {
    if (count > CJGUI_LINUX_MAX_NODES) return 0;
    if (scene->capacity < count) {
        uint32_t next = scene->capacity ? scene->capacity : 16u;
        while (next < count) next *= 2u;
        CjguiLinuxNodeSlot *grown = (CjguiLinuxNodeSlot *)realloc(scene->slots, sizeof(CjguiLinuxNodeSlot) * next);
        if (!grown) return 0;
        memset(grown + scene->capacity, 0, sizeof(CjguiLinuxNodeSlot) * (next - scene->capacity));
        scene->slots = grown;
        scene->capacity = next;
    }
    return 1;
}

static void cjgui_linux_scene_move(CjguiLinuxScene *destination, CjguiLinuxScene *source) {
    cjgui_linux_scene_reset(destination);
    *destination = *source;
    memset(source, 0, sizeof(*source));
}

// ---------------------------------------------------------------- 绘制

// 往顶点缓冲追加一个矩形（两个三角形）。坐标为设备像素。
typedef struct CjguiLinuxVertexBuilder {
    CjguiLinuxGpuVertex *vertices;
    uint32_t count;
    uint32_t capacity;
    int failed;
} CjguiLinuxVertexBuilder;

static int cjgui_linux_builder_reserve(CjguiLinuxVertexBuilder *builder, uint32_t extra) {
    if (builder->failed) return 0;
    if (builder->count + extra <= builder->capacity) return 1;
    uint32_t next = builder->capacity ? builder->capacity : 4096u;
    while (next < builder->count + extra) next *= 2u;
    CjguiLinuxGpuVertex *grown = (CjguiLinuxGpuVertex *)realloc(builder->vertices, sizeof(CjguiLinuxGpuVertex) * next);
    if (!grown) { builder->failed = 1; return 0; }
    builder->vertices = grown;
    builder->capacity = next;
    return 1;
}

static void cjgui_linux_builder_rect(CjguiLinuxVertexBuilder *builder, double x, double y, double width,
                                     double height, double r, double g, double b, double a) {
    if (width <= 0.0 || height <= 0.0 || builder->failed) return;
    if (!cjgui_linux_builder_reserve(builder, 6u)) return;
    // 实心几何统一取图集左上保留的白色纹素：0.5/1024 落在 2x2 白色区中心。
    const float u = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    const float v = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    float x0 = (float)x, y0 = (float)y;
    float x1 = (float)(x + width), y1 = (float)(y + height);
    float fr = (float)r, fg = (float)g, fb = (float)b, fa = (float)a;
    CjguiLinuxGpuVertex quad[6] = {
        { x0, y0, u, v, fr, fg, fb, fa },
        { x1, y0, u, v, fr, fg, fb, fa },
        { x1, y1, u, v, fr, fg, fb, fa },
        { x0, y0, u, v, fr, fg, fb, fa },
        { x1, y1, u, v, fr, fg, fb, fa },
        { x0, y1, u, v, fr, fg, fb, fa },
    };
    memcpy(builder->vertices + builder->count, quad, sizeof(quad));
    builder->count += 6u;
}

// ---------------------------------------------------------------- paint transform
//
// `rotateDegrees` (ABI 5) and the geometry sidecar's `scaleX/scaleY` are
// paint-only: layout (`node.x/y`, `node.width/height`), ancestor clipping and
// hit testing keep the unrotated rectangle; only this node's own vertices move,
// around the centre of its own visual rect. Order matches macOS
// (`CjguiComposableMetalRotation`): scale first, then rotate, both about the
// same centre. Identity (angle 0, scale 1/1) leaves `active` at 0, which is the
// exact legacy path: no new arithmetic touches the vertex stream.
typedef struct CjguiLinuxPaintTransform {
    int active;
    double centerX;   // device pixels, visual-rect centre
    double centerY;
    double scaleX;
    double scaleY;
    double cosValue;
    double sinValue;
} CjguiLinuxPaintTransform;

typedef struct CjguiLinuxPaintPoint {
    double x;
    double y;
    double u;
    double v;
} CjguiLinuxPaintPoint;

// A quad clipped against four axis-aligned half-planes gains at most one vertex
// per plane, so 16 slots cover the worst case with headroom.
#define CJGUI_LINUX_PAINT_POLYGON_CAPACITY 16u

static void cjgui_linux_paint_transform_point(const CjguiLinuxPaintTransform *transform, double x, double y,
                                              double *outX, double *outY) {
    if (!transform || !transform->active) { *outX = x; *outY = y; return; }
    double dx = (x - transform->centerX) * transform->scaleX;
    double dy = (y - transform->centerY) * transform->scaleY;
    *outX = transform->centerX + dx * transform->cosValue - dy * transform->sinValue;
    *outY = transform->centerY + dx * transform->sinValue + dy * transform->cosValue;
}

// Sutherland–Hodgman against one half-plane. UVs interpolate with the same
// parameter as the position, so a clipped glyph keeps its atlas mapping.
static uint32_t cjgui_linux_clip_polygon_axis(const CjguiLinuxPaintPoint *input, uint32_t count,
                                              CjguiLinuxPaintPoint *output, int axis, double boundary,
                                              int keepAtLeast) {
    if (count == 0u || count > CJGUI_LINUX_PAINT_POLYGON_CAPACITY) return 0u;
    uint32_t outCount = 0u;
    for (uint32_t i = 0u; i < count; i += 1u) {
        const CjguiLinuxPaintPoint *current = &input[i];
        const CjguiLinuxPaintPoint *next = &input[(i + 1u) % count];
        double currentValue = axis == 0 ? current->x : current->y;
        double nextValue = axis == 0 ? next->x : next->y;
        int currentInside = keepAtLeast ? (currentValue >= boundary) : (currentValue <= boundary);
        int nextInside = keepAtLeast ? (nextValue >= boundary) : (nextValue <= boundary);
        if (currentInside) {
            if (outCount >= CJGUI_LINUX_PAINT_POLYGON_CAPACITY) return 0u;
            output[outCount++] = *current;
        }
        if (currentInside == nextInside) continue;
        double delta = nextValue - currentValue;
        if (delta == 0.0) continue;
        double t = (boundary - currentValue) / delta;
        if (t < 0.0) t = 0.0;
        if (t > 1.0) t = 1.0;
        if (outCount >= CJGUI_LINUX_PAINT_POLYGON_CAPACITY) return 0u;
        CjguiLinuxPaintPoint clipped;
        clipped.x = current->x + (next->x - current->x) * t;
        clipped.y = current->y + (next->y - current->y) * t;
        clipped.u = current->u + (next->u - current->u) * t;
        clipped.v = current->v + (next->v - current->v) * t;
        output[outCount++] = clipped;
    }
    return outCount;
}

// Submit one quad of this node after the paint-only transform, clipped to the
// device-space clip rectangle (the unrotated ancestor aperture stays
// axis-aligned, matching macOS where the shader clips scene points).
static void cjgui_linux_builder_painted_quad(CjguiLinuxVertexBuilder *builder,
                                             const CjguiLinuxPaintTransform *transform,
                                             double x0, double y0, double x1, double y1,
                                             double u0, double v0, double u1, double v1,
                                             double clipLeft, double clipTop, double clipRight,
                                             double clipBottom, double r, double g, double b, double a) {
    if (!builder || builder->failed || !transform || !transform->active) return;
    if (!(x1 > x0) || !(y1 > y0)) return;
    CjguiLinuxPaintPoint quad[4];
    double corners[4][2] = { { x0, y0 }, { x1, y0 }, { x1, y1 }, { x0, y1 } };
    double minX = 0.0, minY = 0.0, maxX = 0.0, maxY = 0.0;
    for (uint32_t i = 0u; i < 4u; i += 1u) {
        cjgui_linux_paint_transform_point(transform, corners[i][0], corners[i][1], &quad[i].x, &quad[i].y);
        if (i == 0u) { minX = maxX = quad[i].x; minY = maxY = quad[i].y; }
        if (quad[i].x < minX) minX = quad[i].x;
        if (quad[i].x > maxX) maxX = quad[i].x;
        if (quad[i].y < minY) minY = quad[i].y;
        if (quad[i].y > maxY) maxY = quad[i].y;
    }
    if (maxX <= clipLeft || minX >= clipRight || maxY <= clipTop || minY >= clipBottom) return;
    quad[0].u = u0; quad[0].v = v0;
    quad[1].u = u1; quad[1].v = v0;
    quad[2].u = u1; quad[2].v = v1;
    quad[3].u = u0; quad[3].v = v1;
    CjguiLinuxPaintPoint scratch[CJGUI_LINUX_PAINT_POLYGON_CAPACITY];
    uint32_t count = 4u;
    count = cjgui_linux_clip_polygon_axis(quad, count, scratch, 0, clipLeft, 1);
    if (count < 3u) return;
    count = cjgui_linux_clip_polygon_axis(scratch, count, quad, 0, clipRight, 0);
    if (count < 3u) return;
    count = cjgui_linux_clip_polygon_axis(quad, count, scratch, 1, clipTop, 1);
    if (count < 3u) return;
    count = cjgui_linux_clip_polygon_axis(scratch, count, quad, 1, clipBottom, 0);
    if (count < 3u) return;
    uint32_t triangleCount = count - 2u;
    if (!cjgui_linux_builder_reserve(builder, triangleCount * 3u)) return;
    float fr = (float)r, fg = (float)g, fb = (float)b, fa = (float)a;
    for (uint32_t i = 1u; i + 1u < count; i += 1u) {
        CjguiLinuxGpuVertex triangle[3] = {
            { (float)quad[0].x, (float)quad[0].y, (float)quad[0].u, (float)quad[0].v, fr, fg, fb, fa },
            { (float)quad[i].x, (float)quad[i].y, (float)quad[i].u, (float)quad[i].v, fr, fg, fb, fa },
            { (float)quad[i + 1u].x, (float)quad[i + 1u].y, (float)quad[i + 1u].u, (float)quad[i + 1u].v,
              fr, fg, fb, fa },
        };
        memcpy(builder->vertices + builder->count, triangle, sizeof(triangle));
        builder->count += 3u;
    }
}

// Rect-shaped paint. An inactive transform calls the untouched legacy builder,
// so every absent/default node keeps its historical vertex bytes.
static void cjgui_linux_builder_rect_painted(CjguiLinuxVertexBuilder *builder,
                                             const CjguiLinuxPaintTransform *transform,
                                             double x, double y, double width, double height,
                                             double clipLeft, double clipTop, double clipRight,
                                             double clipBottom, double r, double g, double b, double a) {
    if (!transform || !transform->active) {
        cjgui_linux_builder_rect(builder, x, y, width, height, r, g, b, a);
        return;
    }
    if (width <= 0.0 || height <= 0.0) return;
    const float u = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    const float v = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    cjgui_linux_builder_painted_quad(builder, transform, x, y, x + width, y + height,
                                     (double)u, (double)v, (double)u, (double)v,
                                     clipLeft, clipTop, clipRight, clipBottom, r, g, b, a);
}

static void cjgui_linux_builder_text(CjguiLinuxVertexBuilder *builder, CjguiLinuxText *text,
                                     const char *value, double fontSize, uint32_t fontWeight,
                                     uint32_t fontFamily, double maxWidth, double originX, double originY,
                                     double clipX, double clipY, double clipRight, double clipBottom,
                                     double r, double g, double b, double a,
                                     const CjguiLinuxPaintTransform *transform) {
    if (!text || !value || !value[0] || builder->failed) return;
    CjguiLinuxTextQuad quads[1024];
    uint32_t quadCount = 0u;
    double width = 0.0, height = 0.0, ascent = 0.0;
    int status = cjgui_linux_text_layout(text, value, strlen(value), fontSize, fontWeight, fontFamily,
                                         maxWidth, 0.0, 0.0, 1, quads, 1024u, &quadCount, &width, &height,
                                         &ascent);
    if (status != CJGUI_LINUX_TEXT_OK && status != CJGUI_LINUX_TEXT_BUDGET_EXCEEDED) return;
    if (quadCount > 1024u) quadCount = 1024u;
    for (uint32_t i = 0u; i < quadCount; i += 1u) {
        CjguiLinuxTextQuad *quad = &quads[i];
        double qx = originX + quad->x;
        double qy = originY + quad->y;
        double qw = quad->width;
        double qh = quad->height;
        if (qw <= 0.0 || qh <= 0.0) continue;
        if (transform && transform->active) {
            // 旋转/缩放只改这一节点自己的顶点；字形 UV 保持不变，裁剪交给
            // 多边形裁剪，字形仍随节点整体转动。
            cjgui_linux_builder_painted_quad(builder, transform, qx, qy, qx + qw, qy + qh,
                                             quad->u0, quad->v0, quad->u1, quad->v1,
                                             clipX, clipY, clipRight, clipBottom, r, g, b, a);
            continue;
        }
        if (qx + qw <= clipX || qy + qh <= clipY || qx >= clipRight || qy >= clipBottom) continue;
        if (!cjgui_linux_builder_reserve(builder, 6u)) return;
        float x0 = (float)qx, y0 = (float)qy;
        float x1 = (float)(qx + qw), y1 = (float)(qy + qh);
        float fr = (float)r, fg = (float)g, fb = (float)b, fa = (float)a;
        CjguiLinuxGpuVertex glyphs[6] = {
            { x0, y0, quad->u0, quad->v0, fr, fg, fb, fa },
            { x1, y0, quad->u1, quad->v0, fr, fg, fb, fa },
            { x1, y1, quad->u1, quad->v1, fr, fg, fb, fa },
            { x0, y0, quad->u0, quad->v0, fr, fg, fb, fa },
            { x1, y1, quad->u1, quad->v1, fr, fg, fb, fa },
            { x0, y1, quad->u0, quad->v1, fr, fg, fb, fa },
        };
        memcpy(builder->vertices + builder->count, glyphs, sizeof(glyphs));
        builder->count += 6u;
    }
}

static const char *cjgui_linux_node_body(const CjguiLinuxNodeSlot *slot) {
    if (slot->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && slot->label && slot->label[0]) {
        return slot->label;
    }
    return slot->value ? slot->value : "";
}

// ---------------------------------------------------------------- 帧呈现

static void cjgui_linux_upload_atlas(CjguiLinuxSession *session) {
    if (!session->gpu || !session->text) return;
    int x = 0, y = 0, width = 0, height = 0;
    if (!cjgui_linux_text_take_atlas_dirty(session->text, &x, &y, &width, &height)) return;
    if (width <= 0 || height <= 0) return;
    const uint8_t *pixels = cjgui_linux_text_atlas_pixels(session->text);
    if (!pixels) return;
    int side = cjgui_linux_text_atlas_side(session->text);
    if (x < 0) { width += x; x = 0; }
    if (y < 0) { height += y; y = 0; }
    if (x + width > side) width = side - x;
    if (y + height > side) height = side - y;
    if (width <= 0 || height <= 0) return;
    uint8_t *staging = (uint8_t *)malloc((size_t)width * (size_t)height * 4u);
    if (!staging) return;
    for (int row = 0; row < height; row += 1) {
        const uint8_t *source = pixels + (((size_t)(y + row) * (size_t)side) + (size_t)x) * 4u;
        memcpy(staging + (size_t)row * (size_t)width * 4u, source, (size_t)width * 4u);
    }
    (void)cjgui_linux_gpu_upload_atlas(session->gpu, x, y, width, height, staging);
    session->textUploadCount += 1u;
    session->textUploadBytes += (uint64_t)width * (uint64_t)height * 4u;
    free(staging);
}

static void cjgui_linux_append_background(CjguiLinuxSession *session, CjguiLinuxVertexBuilder *builder) {
    uint32_t drawableWidth = cjgui_linux_gpu_drawable_width(session->gpu);
    uint32_t drawableHeight = cjgui_linux_gpu_drawable_height(session->gpu);
    double red = session->backgroundStaged ? session->backgroundRed : session->clear[0];
    double green = session->backgroundStaged ? session->backgroundGreen : session->clear[1];
    double blue = session->backgroundStaged ? session->backgroundBlue : session->clear[2];
    double alpha = session->backgroundStaged ? session->backgroundAlpha : session->clear[3];
    if (alpha <= 0.0) alpha = 1.0;
    cjgui_linux_builder_rect(builder, 0.0, 0.0, (double)drawableWidth, (double)drawableHeight,
                             red, green, blue, alpha);
}

// The second geometry channel is paint-only: layout (`node.x/y`) and the clip
// chain stay in layout space, while the visual rect is offset by the staged
// translate. Callers that route real input or report output bounds must use
// the visual origin, matching macOS/Windows; layout queries keep node.x/y.
static double cjgui_linux_slot_translate_x(const CjguiLinuxNodeSlot *slot) {
    return slot->geometryPresent ? slot->geometry.translateX : 0.0;
}

static double cjgui_linux_slot_translate_y(const CjguiLinuxNodeSlot *slot) {
    return slot->geometryPresent ? slot->geometry.translateY : 0.0;
}

// Per-node paint transform from `rotateDegrees` + the geometry sidecar's
// `scaleX/scaleY`. Non-finite or non-positive sidecar scales fall back to
// identity (macOS does the same); the shared packing already normalizes
// anything outside (0, 16] to 1.0. A node with angle 0 and scale 1/1 returns
// `active == 0`, which is the exact pre-existing paint path.
static CjguiLinuxPaintTransform cjgui_linux_slot_paint_transform(const CjguiLinuxNodeSlot *slot,
                                                                 double deviceScale) {
    CjguiLinuxPaintTransform transform;
    memset(&transform, 0, sizeof(transform));
    transform.scaleX = 1.0;
    transform.scaleY = 1.0;
    transform.cosValue = 1.0;
    if (!slot || !(deviceScale > 0.0)) return transform;
    double sidecarScaleX = 1.0;
    double sidecarScaleY = 1.0;
    if (slot->geometryPresent) {
        if (isfinite(slot->geometry.scaleX) && slot->geometry.scaleX > 0.0) sidecarScaleX = slot->geometry.scaleX;
        if (isfinite(slot->geometry.scaleY) && slot->geometry.scaleY > 0.0) sidecarScaleY = slot->geometry.scaleY;
    }
    double degrees = slot->node.rotateDegrees;
    int rotates = isfinite(degrees) && degrees != 0.0;
    if (!rotates && sidecarScaleX == 1.0 && sidecarScaleY == 1.0) return transform;
    transform.active = 1;
    transform.centerX = ((double)slot->node.x + cjgui_linux_slot_translate_x(slot) +
                         (double)slot->node.width * 0.5) * deviceScale;
    transform.centerY = ((double)slot->node.y + cjgui_linux_slot_translate_y(slot) +
                         (double)slot->node.height * 0.5) * deviceScale;
    transform.scaleX = sidecarScaleX;
    transform.scaleY = sidecarScaleY;
    if (rotates) {
        double radians = degrees * 3.14159265358979323846 / 180.0;
        transform.cosValue = cos(radians);
        transform.sinValue = sin(radians);
    }
    return transform;
}

// Conservative visibility gate for a transformed node: the rotated/scaled
// content stays inside the circle around the visual centre with radius
// halfDiagonal * max(scale). Only used when the plain rect test already said
// "outside", so an unrotated node keeps the legacy early-out.
static int cjgui_linux_slot_transform_reaches_clip(const CjguiLinuxPaintTransform *transform,
                                                   double width, double height,
                                                   double clipLeft, double clipTop,
                                                   double clipRight, double clipBottom) {
    if (!transform || !transform->active) return 0;
    double halfWidth = width * 0.5;
    double halfHeight = height * 0.5;
    double reach = sqrt(halfWidth * halfWidth + halfHeight * halfHeight);
    double maxScale = transform->scaleX > transform->scaleY ? transform->scaleX : transform->scaleY;
    reach *= maxScale;
    double nearestX = transform->centerX < clipLeft ? clipLeft
                     : (transform->centerX > clipRight ? clipRight : transform->centerX);
    double nearestY = transform->centerY < clipTop ? clipTop
                     : (transform->centerY > clipBottom ? clipBottom : transform->centerY);
    double dx = transform->centerX - nearestX;
    double dy = transform->centerY - nearestY;
    return (dx * dx + dy * dy) <= reach * reach;
}

// Rectangular clip chain in device pixels. The accepted node carries up to four
// ancestor apertures (`clipConstraintCount` 1..4, each translated by the owner
// offset mirrored in the geometry sidecar); count 0 falls back to the legacy
// single clip rect. A constraint with a non-positive size means "no
// constraint" (same as Windows' containment test), so it intersects with the
// full drawable instead of clipping everything away. Corner radii stay
// unpainted: the pipeline only has a scissor, see the TODO below.
static int cjgui_linux_slot_clip_bounds(const CjguiLinuxNodeSlot *slot, double deviceScale,
                                        double drawableWidth, double drawableHeight,
                                        double *outLeft, double *outTop,
                                        double *outRight, double *outBottom) {
    if (!slot || !(deviceScale > 0.0)) return 0;
    const CjguiInternalRendererComposableNode *node = &slot->node;
    double left = 0.0, top = 0.0, right = drawableWidth, bottom = drawableHeight;
    uint32_t count = node->clipConstraintCount;
    if (count > 4u) count = 0u;  // the ABI caps the chain at four slots
    if (count == 0u) {
        if (node->clipWidth > 0 && node->clipHeight > 0) {
            left = (double)node->clipX * deviceScale;
            top = (double)node->clipY * deviceScale;
            right = left + (double)node->clipWidth * deviceScale;
            bottom = top + (double)node->clipHeight * deviceScale;
        }
    } else {
        for (uint32_t index = 0u; index < count; index += 1u) {
            double clipX = 0.0, clipY = 0.0, clipWidth = 0.0, clipHeight = 0.0;
            double ownerX = 0.0, ownerY = 0.0;
            switch (index) {
                case 0u:
                    clipX = (double)node->clip0X; clipY = (double)node->clip0Y;
                    clipWidth = (double)node->clip0Width; clipHeight = (double)node->clip0Height;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip0X; ownerY = slot->geometry.clip0Y; }
                    break;
                case 1u:
                    clipX = (double)node->clip1X; clipY = (double)node->clip1Y;
                    clipWidth = (double)node->clip1Width; clipHeight = (double)node->clip1Height;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip1X; ownerY = slot->geometry.clip1Y; }
                    break;
                case 2u:
                    clipX = (double)node->clip2X; clipY = (double)node->clip2Y;
                    clipWidth = (double)node->clip2Width; clipHeight = (double)node->clip2Height;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip2X; ownerY = slot->geometry.clip2Y; }
                    break;
                default:
                    clipX = (double)node->clip3X; clipY = (double)node->clip3Y;
                    clipWidth = (double)node->clip3Width; clipHeight = (double)node->clip3Height;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip3X; ownerY = slot->geometry.clip3Y; }
                    break;
            }
            if (!(clipWidth > 0.0) || !(clipHeight > 0.0)) continue;
            double constraintLeft = (clipX + ownerX) * deviceScale;
            double constraintTop = (clipY + ownerY) * deviceScale;
            double constraintRight = constraintLeft + clipWidth * deviceScale;
            double constraintBottom = constraintTop + clipHeight * deviceScale;
            if (constraintLeft > left) left = constraintLeft;
            if (constraintTop > top) top = constraintTop;
            if (constraintRight < right) right = constraintRight;
            if (constraintBottom < bottom) bottom = constraintBottom;
            if (right <= left || bottom <= top) return 0;
        }
    }
    if (outLeft) *outLeft = left;
    if (outTop) *outTop = top;
    if (outRight) *outRight = right;
    if (outBottom) *outBottom = bottom;
    return right > left && bottom > top;
}

static void cjgui_linux_append_scene(CjguiLinuxSession *session, CjguiLinuxVertexBuilder *builder) {
    double scale = cjgui_linux_gpu_scale(session->gpu);
    if (scale <= 0.0) scale = 1.0;
    double drawableWidth = (double)cjgui_linux_gpu_drawable_width(session->gpu);
    double drawableHeight = (double)cjgui_linux_gpu_drawable_height(session->gpu);
    CjguiLinuxScene *scene = &session->accepted;
    if (!scene->valid) return;
    for (uint32_t i = 0u; i < scene->nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &scene->slots[i];
        const CjguiInternalRendererComposableNode *node = &slot->node;
        if (node->nodeKind == 0u) continue;
        if (node->width <= 0 || node->height <= 0) continue;
        double x = ((double)node->x + cjgui_linux_slot_translate_x(slot)) * scale;
        double y = ((double)node->y + cjgui_linux_slot_translate_y(slot)) * scale;
        double width = (double)node->width * scale;
        double height = (double)node->height * scale;
        double clipX = 0.0, clipY = 0.0, clipRight = drawableWidth, clipBottom = drawableHeight;
        if (!cjgui_linux_slot_clip_bounds(slot, scale, drawableWidth, drawableHeight,
                                          &clipX, &clipY, &clipRight, &clipBottom)) continue;
        // ---- Carried-but-unpainted fields (localized TODO, NOT claimed) ----
        // iconTint*: this backend never decodes or samples an image resource
        //   (image decode/upload has no implementation, see the workload
        //   report's imageDecodeStartCount == 0), so there is no sampled
        //   RGB/alpha to multiply. A tint gate here would colour nothing;
        //   implementing it needs an image texture path in
        //   cjgui_linux_vulkan.c, which is outside this file's write set.
        //   iconTintAlpha == 0 (the default) therefore stays byte-identical.
        // effectGroupPresent/effectGroupSubtreeCount/effectGroupOpacity: group
        //   opacity is a composite, not a paint: the contiguous subtree must be
        //   rendered into its own target and blended once. This pipeline draws
        //   every triangle straight into the swapchain image; multiplying each
        //   vertex alpha would double-blend overlapping group content, so it is
        //   left unpainted instead of approximated. Needs an offscreen target
        //   plus a composite pass in cjgui_linux_vulkan.c.
        // effectBackdropBlurRadiusPoints: needs to sample the already-painted
        //   backdrop (a framebuffer copy or history target). The only texture
        //   this pipeline samples is the glyph atlas, so no correct blur exists
        //   here yet.
        // clip0CornerRadius..clip3CornerRadius: the shader has no rounded-clip
        //   primitive (no SDF, scissor is the only clip), and even the uniform
        //   cornerRadius is not painted; per-corner clip radii would need a
        //   shader/geometry redesign, so they stay unpainted.
        CjguiLinuxPaintTransform transform = cjgui_linux_slot_paint_transform(slot, scale);
        double left = x < clipX ? clipX : x;
        double top = y < clipY ? clipY : y;
        double right = (x + width) > clipRight ? clipRight : (x + width);
        double bottom = (y + height) > clipBottom ? clipBottom : (y + height);
        if (right <= left || bottom <= top) {
            if (!cjgui_linux_slot_transform_reaches_clip(&transform, width, height,
                                                         clipX, clipY, clipRight, clipBottom)) continue;
        }
        // Paint-only transform: layout stays authoritative. A turned/scaled node
        // lays its text out on the whole visual rect and lets the polygon
        // clipper trim what leaves the ancestor aperture; the untransformed path
        // keeps the historical pre-clip intersection.
        double boxLeft = transform.active ? x : left;
        double boxTop = transform.active ? y : top;
        double boxRight = transform.active ? (x + width) : right;
        double boxBottom = transform.active ? (y + height) : bottom;
        double fillLeft = x > clipX ? x : clipX;
        double fillTop = y > clipY ? y : clipY;
        double fillRight = (x + width) < clipRight ? (x + width) : clipRight;
        double fillBottom = (y + height) < clipBottom ? (y + height) : clipBottom;
        if (node->fillAlpha > 0.0) {
            if (transform.active) {
                // 旋转/缩放下的填充按整块四边形提交，再对设备像素 clip 做凸多边形
                // 裁剪；未旋转节点仍走原来的"先相交再画"路径，字节不变。
                cjgui_linux_builder_rect_painted(builder, &transform, x, y, width, height,
                                                 clipX, clipY, clipRight, clipBottom,
                                                 node->fillRed, node->fillGreen, node->fillBlue, node->fillAlpha);
            } else if (fillRight > fillLeft && fillBottom > fillTop) {
                cjgui_linux_builder_rect(builder, fillLeft, fillTop, fillRight - fillLeft, fillBottom - fillTop,
                                         node->fillRed, node->fillGreen, node->fillBlue, node->fillAlpha);
            }
        }
        if (node->borderWidth > 0u && node->borderAlpha > 0.0 && width > 0.0 && height > 0.0) {
            double thickness = (double)node->borderWidth * scale;
            if (thickness > width * 0.5) thickness = width * 0.5;
            if (thickness > height * 0.5) thickness = height * 0.5;
            double bx0 = x > clipX ? x : clipX;
            double by0 = y > clipY ? y : clipY;
            double bx1 = (x + width) < clipRight ? (x + width) : clipRight;
            double by1 = (y + height) < clipBottom ? (y + height) : clipBottom;
            if (transform.active) {
                // 边框四条边同样按节点自己的变换提交，并由多边形裁剪收口。
                double tx0 = x, ty0 = y, tx1 = x + width, ty1 = y + height;
                cjgui_linux_builder_rect_painted(builder, &transform, tx0, ty0, tx1 - tx0, thickness,
                                                 clipX, clipY, clipRight, clipBottom,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_painted(builder, &transform, tx0, ty1 - thickness, tx1 - tx0, thickness,
                                                 clipX, clipY, clipRight, clipBottom,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_painted(builder, &transform, tx0, ty0 + thickness, thickness,
                                                 (ty1 - ty0) - 2.0 * thickness,
                                                 clipX, clipY, clipRight, clipBottom,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_painted(builder, &transform, tx1 - thickness, ty0 + thickness,
                                                 thickness, (ty1 - ty0) - 2.0 * thickness,
                                                 clipX, clipY, clipRight, clipBottom,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
            } else if (bx1 > bx0 && by1 > by0) {
                cjgui_linux_builder_rect(builder, bx0, by0, bx1 - bx0, thickness,
                                         node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect(builder, bx0, by1 - thickness, bx1 - bx0, thickness,
                                         node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect(builder, bx0, by0 + thickness, thickness, (by1 - by0) - 2.0 * thickness,
                                         node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect(builder, bx1 - thickness, by0 + thickness, thickness,
                                         (by1 - by0) - 2.0 * thickness,
                                         node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
            }
        }
        const char *body = cjgui_linux_node_body(slot);
        if (!body || !body[0] || node->textAlpha <= 0.0) continue;
        // 全部按设备像素做，避免逻辑/设备两套坐标混算：文字模块只把 fontSize 当
        // 像素尺寸用，所以这里直接传 scale 后的值，clip 与 maxWidth 也用设备像素。
        int multiline = node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        double deviceInset = 6.0 * scale;
        double textLeft = boxLeft + deviceInset;
        double textRight = boxRight - deviceInset;
        if (textRight <= textLeft) continue;
        // ABI 5 adds letterSpacing / lineHeightPoints / maxLines /
        // ellipsisEnabled / cornerRadii* to the node POD. Linux currently
        // CARRIES these fields WITHOUT painting them: the text module keeps
        // natural tracking and line height, overflow stays on the legacy
        // textMaxLines/textOverflow path, and corners stay uniform. Implement
        // them here before claiming support.
        double fontSizePoints = node->fontSize > 0.0 ? node->fontSize : 14.0;
        double fontSizeDevice = fontSizePoints * scale;
        double lineHeightDevice = cjgui_linux_text_line_height(session->text, fontSizePoints,
                                                               node->fontWeight, node->fontFamily) * scale;
        if (lineHeightDevice <= 0.0) lineHeightDevice = fontSizeDevice * 1.2;
        double originY = multiline ? (boxTop + deviceInset * 0.5)
                                   : (boxTop + ((boxBottom - boxTop) - lineHeightDevice) * 0.5);
        if (originY < boxTop) originY = boxTop;
        // 选区底色：本阶段画的是"native 自己拥有的那份选区"（正在编辑的文本代理）。
        // 消费者经 encodedRuns 声明的预览选区本阶段不解析（见文件头"刻意不做的事"），
        // 所以这里不冒充"所有选区都画了"。
        CjguiLinuxActiveTextProxy *proxy = &session->proxy;
        if (proxy->active && proxy->nodeId == node->nodeId && proxy->value &&
            proxy->selectionEnd16 > proxy->selectionStart16) {
            double x0 = 0.0, x1 = 0.0, top0 = 0.0, top1 = 0.0, lineHeight = 0.0;
            size_t lineStart = 0u, lineEnd = 0u;
            uint32_t lineIndex = 0u;
            size_t startByte = cjgui_linux_byte_offset_for_utf16(proxy->value, strlen(proxy->value),
                                                                proxy->selectionStart16);
            size_t endByte = cjgui_linux_byte_offset_for_utf16(proxy->value, strlen(proxy->value),
                                                              proxy->selectionEnd16);
            if (cjgui_linux_text_caret_position(session->text, proxy->value, strlen(proxy->value),
                                                fontSizePoints, node->fontWeight, node->fontFamily,
                                                node->width - 12.0, startByte, &x0, &top0, &lineHeight,
                                                &lineIndex, &lineStart, &lineEnd) == CJGUI_LINUX_TEXT_OK &&
                cjgui_linux_text_caret_position(session->text, proxy->value, strlen(proxy->value),
                                                fontSizePoints, node->fontWeight, node->fontFamily,
                                                node->width - 12.0, endByte, &x1, &top1, &lineHeight,
                                                &lineIndex, &lineStart, &lineEnd) == CJGUI_LINUX_TEXT_OK) {
                double selectionTop = originY + top0 * scale;
                double selectionHeight = lineHeightDevice;
                double selectionLeft = textLeft + x0 * scale;
                double selectionRight = textLeft + x1 * scale;
                if (selectionRight > selectionLeft && selectionHeight > 0.0) {
                    cjgui_linux_builder_rect_painted(builder, &transform, selectionLeft, selectionTop,
                                                     selectionRight - selectionLeft, selectionHeight,
                                                     clipX, clipY, clipRight, clipBottom,
                                                     0.25, 0.50, 0.85, 0.42);
                }
            }
        }
        // 组合态投影：Linux 没有系统文本视图替我们画 preedit，所以在代理节点的
        // 已接受几何上把 draft 插进原来被替换的区间。只改这一帧的绘制串；
        // owner 正文和镜像都不提前写入。
        char *composed = NULL;
        const char *drawBody = body;
        if (proxy->active && proxy->nodeId == node->nodeId && session->compositionActive &&
            session->compositionTextLength > 0u) {
            const char *source = proxy->value ? proxy->value : "";
            size_t sourceLength = strlen(source);
            size_t startByte = cjgui_linux_byte_offset_for_utf16(source, sourceLength,
                                                                session->compositionStart16);
            size_t endByte = cjgui_linux_byte_offset_for_utf16(
                source, sourceLength,
                session->compositionStart16 + session->compositionReplaceLength16);
            if (endByte < startByte) endByte = startByte;
            size_t composedLength = startByte + session->compositionTextLength + (sourceLength - endByte);
            if (composedLength < CJGUI_LINUX_FORM_TEXT_CAPACITY) {
                composed = (char *)malloc(composedLength + 1u);
                if (composed != NULL) {
                    memcpy(composed, source, startByte);
                    memcpy(composed + startByte, session->compositionText,
                           session->compositionTextLength);
                    memcpy(composed + startByte + session->compositionTextLength,
                           source + endByte, sourceLength - endByte);
                    composed[composedLength] = '\0';
                    drawBody = composed;
                }
            }
        }
        cjgui_linux_builder_text(builder, session->text, drawBody, fontSizeDevice, node->fontWeight,
                                 node->fontFamily, textRight - textLeft, textLeft, originY,
                                 clipX, clipY, clipRight, clipBottom,
                                 node->textRed, node->textGreen, node->textBlue, node->textAlpha,
                                 transform.active ? &transform : NULL);
        if (composed != NULL) {
            // preedit 下划线：让用户看得到组合段（系统 IME 的候选窗另有定位）。
            double x0 = 0.0, x1 = 0.0, top0 = 0.0, top1 = 0.0, lineHeight = 0.0;
            size_t lineStart = 0u, lineEnd = 0u;
            uint32_t lineIndex = 0u;
            size_t drawLength = strlen(drawBody);
            size_t startByte = cjgui_linux_byte_offset_for_utf16(
                drawBody, drawLength, session->compositionStart16);
            size_t endByte = cjgui_linux_byte_offset_for_utf16(
                drawBody, drawLength,
                session->compositionStart16 +
                    cjgui_linux_utf16_length(session->compositionText,
                                             session->compositionTextLength));
            if (cjgui_linux_text_caret_position(session->text, drawBody, drawLength, fontSizePoints,
                                                node->fontWeight, node->fontFamily,
                                                node->width - 12.0, startByte, &x0, &top0,
                                                &lineHeight, &lineIndex, &lineStart, &lineEnd) ==
                    CJGUI_LINUX_TEXT_OK &&
                cjgui_linux_text_caret_position(session->text, drawBody, drawLength, fontSizePoints,
                                                node->fontWeight, node->fontFamily,
                                                node->width - 12.0, endByte, &x1, &top1,
                                                &lineHeight, &lineIndex, &lineStart, &lineEnd) ==
                    CJGUI_LINUX_TEXT_OK) {
                double underlineLeft = textLeft + x0 * scale;
                double underlineRight = textLeft + x1 * scale;
                if (underlineRight > underlineLeft) {
                    cjgui_linux_builder_rect_painted(builder, &transform, underlineLeft,
                                                     originY + top0 * scale + lineHeightDevice - 2.0 * scale,
                                                     underlineRight - underlineLeft, 2.0 * scale,
                                                     clipX, clipY, clipRight, clipBottom,
                                                     0.15, 0.35, 0.90, 1.0);
                }
                // 候选窗定位消费同一份光标几何：光标在 preedit 末尾、下一行基线。
                // 绘制坐标是设备像素，set_ime_spot 收窗口逻辑点（内部再乘 scale）。
                // 旋转/缩放节点的候选位置仍按未变换的光标几何上报（输入法定位不随
                // 旋转，和 macOS 一致；这里不作为已验证能力宣传）。
                if (scale > 0.0) {
                    double spotX = textLeft / scale + x1;
                    double spotY = (originY + top1 * scale + lineHeightDevice) / scale;
                    cjgui_linux_window_set_ime_spot(session->window, spotX, spotY, lineHeight);
                }
            }
            free(composed);
        }
    }
    // 输入光标条：由共同层每轮用已接受布局重新声明；nodeId<0 表示撤回。
    if (session->caretNodeId >= 0 && session->caretWidth > 0.0 && session->caretHeight > 0.0) {
        cjgui_linux_builder_rect(builder, session->caretX * scale, session->caretY * scale,
                                 session->caretWidth * scale, session->caretHeight * scale,
                                 0.10, 0.10, 0.10, 1.0);
    }
}

static void cjgui_linux_fill_observation(CjguiLinuxSession *session, CjguiInternalRendererFrameObservation *out) {
    if (!out) return;
    memset(out, 0, sizeof(*out));
    out->frameIndex = session->frameIndex;
    out->drawableWidthPixels = cjgui_linux_gpu_drawable_width(session->gpu);
    out->drawableHeightPixels = cjgui_linux_gpu_drawable_height(session->gpu);
    out->contentsScale = cjgui_linux_gpu_scale(session->gpu);
    out->readbackAttempted = 0u;
    out->readbackCompleted = 0u;
    out->readbackColorMatched = 0u;
    out->ticketId = 0u;   // 同步结算：不登记票据，调用方无需 query/acknowledge
}

// ---------------------------------------------------------------- 槽位查询（aux 契约）

int cjgui_linux_session_slot(uint64_t token) {
    for (uint32_t i = 0u; i < CJGUI_LINUX_MAX_SESSIONS; i += 1u) {
        if (g_sessions[i].alive && g_sessions[i].token == token) return (int)i;
    }
    return -1;
}

// ---------------------------------------------------------------- 文字几何服务访问器

CjguiLinuxText *cjgui_linux_session_text(uint64_t token) {
    CjguiLinuxSession *session = cjgui_linux_lookup(token);
    return session ? session->text : NULL;
}

uint64_t cjgui_linux_session_scene_version(uint64_t token) {
    CjguiLinuxSession *session = cjgui_linux_lookup(token);
    return session ? session->accepted.projectionVersion : 0u;
}

void cjgui_linux_session_text_node_view(uint64_t token, uint64_t nodeId, CjguiLinuxTextNodeView *outView) {
    if (!outView) return;
    memset(outView, 0, sizeof(*outView));
    CjguiLinuxSession *session = cjgui_linux_lookup(token);
    if (!session || !session->accepted.valid) return;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        if (slot->node.nodeId != nodeId) continue;
        outView->found = 1;
        outView->text = cjgui_linux_node_body(slot);
        outView->fontSize = slot->node.fontSize > 0.0 ? slot->node.fontSize : 14.0;
        outView->fontWeight = slot->node.fontWeight;
        outView->fontFamily = slot->node.fontFamily;
        outView->x = slot->node.x;
        outView->y = slot->node.y;
        outView->width = slot->node.width;
        outView->height = slot->node.height;
        outView->sceneVersion = session->accepted.projectionVersion;
        outView->nodeId = nodeId;
        return;
    }
}

// ---------------------------------------------------------------- 生命周期

uint64_t cjgui_internal_renderer_create(const CjguiInternalRendererConfig *config,
                                        CjguiInternalRendererStatus *outStatus) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t token = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    if (!config || config->windowWidth == 0u || config->windowHeight == 0u ||
        config->windowWidth > 8192u || config->windowHeight > 8192u) {
        status = CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED;
        if (outStatus) *outStatus = status;
        return token;
    }
    CjguiLinuxSession *session = NULL;
    int slot = -1;
    for (uint32_t i = 0u; i < CJGUI_LINUX_MAX_SESSIONS; i += 1u) {
        if (!g_sessions[i].alive) { session = &g_sessions[i]; slot = (int)i; break; }
    }
    if (!session) {
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL;
        return token;
    }
    memset(session, 0, sizeof(*session));
    session->requestedWidth = config->windowWidth;
    session->requestedHeight = config->windowHeight;
    session->clear[0] = config->clearColorRed;
    session->clear[1] = config->clearColorGreen;
    session->clear[2] = config->clearColorBlue;
    session->clear[3] = config->clearColorAlpha;
    session->backgroundRed = config->clearColorRed;
    session->backgroundGreen = config->clearColorGreen;
    session->backgroundBlue = config->clearColorBlue;
    session->backgroundAlpha = config->clearColorAlpha;
    session->windowKey = 1;
    session->windowMain = 1;
    session->windowAppActive = 1;

    int windowStatus = 0;
    session->window = cjgui_linux_window_create(config->windowWidth, config->windowHeight,
                                                "CJGUI Linux", &windowStatus);
    if (!session->window) {
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
        memset(session, 0, sizeof(*session));
        return token;
    }
    int textStatus = 0;
    session->text = cjgui_linux_text_create(&textStatus);
    if (!session->text) {
        cjgui_linux_window_destroy(session->window);
        memset(session, 0, sizeof(*session));
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED;
        return token;
    }
    int gpuStatus = 0;
    session->gpu = cjgui_linux_gpu_create(session->window, &gpuStatus);
    if (!session->gpu) {
        cjgui_linux_text_destroy(session->text);
        cjgui_linux_window_destroy(session->window);
        memset(session, 0, sizeof(*session));
        // Vulkan 不可用时用最接近的具名状态：设备/交换链建不起来。
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_METAL_DEVICE_UNAVAILABLE;
        return token;
    }
    session->token = g_nextToken++;
    session->alive = 1;
    cjgui_linux_aux_on_create(slot);
    cjgui_linux_installed_range_on_create(slot);
    if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_OK;
    return session->token;
}

CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t sessionToken) {
    int slot = cjgui_linux_session_slot(sessionToken);
    if (slot < 0) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiLinuxSession *session = &g_sessions[slot];
    // 顺序固定：停止提交 → 等待设备空闲 → 销毁交换链与图像 → 管线/图集 →
    // device → surface → instance；窗口在 GPU 之后释放（surface 依赖 X 连接）。
    if (session->gpu) cjgui_linux_gpu_destroy(session->gpu);
    if (session->text) cjgui_linux_text_destroy(session->text);
    if (session->window) cjgui_linux_window_destroy(session->window);
    cjgui_linux_scene_reset(&session->accepted);
    cjgui_linux_scene_reset(&session->candidate);
    for (uint32_t i = 0u; i < CJGUI_LINUX_MAX_RUN_DECLARATIONS; i += 1u) {
        cjgui_linux_strfree(&session->runs[i].encoded);
    }
    session->runCount = 0u;
    cjgui_linux_strfree(&session->rangePreBody);
    cjgui_linux_strfree(&session->rangePostBody);
    cjgui_linux_strfree(&session->rangeReplacement);
    // 尚未出队的逐事件 range 载荷也归本会话所有，销毁时一并释放。
    for (uint32_t i = 0u; i < CJGUI_LINUX_PENDING_EVENTS; i += 1u) {
        cjgui_linux_strfree(&session->pending[i].rangePreBody);
        cjgui_linux_strfree(&session->pending[i].rangePostBody);
        cjgui_linux_strfree(&session->pending[i].rangeReplacement);
    }
    cjgui_linux_installed_range_on_destroy(slot);
    cjgui_linux_strfree(&session->proxy.value);
    cjgui_linux_aux_on_destroy(slot);
    memset(session, 0, sizeof(*session));
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_window_title(uint64_t sessionToken,
                                                                    const char *title) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!title) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (cjgui_linux_window_set_title(session->window, title) != 0) {
        return CJGUI_INTERNAL_RENDERER_WINDOW_CREATE_FAILED;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

void cjgui_internal_renderer_request_application_stop(void) {
    g_stopRequested = 1;
}

void cjgui_internal_renderer_complete_application_exit_request(void) {
    g_stopRequested = 0;
}

void cjgui_internal_renderer_retain_application_exit_lifecycle_owner(void) {
    g_exitLifecycleRetainCount += 1;
    g_exitLifecycleOwnerHeld = 1;
}

void cjgui_internal_renderer_release_application_exit_lifecycle_owner(void) {
    if (g_exitLifecycleRetainCount > 0) g_exitLifecycleRetainCount -= 1;
    if (g_exitLifecycleRetainCount == 0) g_exitLifecycleOwnerHeld = 0;
}

uint8_t cjgui_internal_renderer_has_unkeyed_application_exit_request(void) {
    // "无键"退出请求：进程级 stop 未被任何会话的窗口关闭事件配对。
    return (uint8_t)(g_stopRequested ? 1u : 0u);
}

uint32_t cjgui_internal_renderer_occupied_session_count(void) {
    uint32_t count = 0u;
    for (uint32_t i = 0u; i < CJGUI_LINUX_MAX_SESSIONS; i += 1u) {
        if (g_sessions[i].alive) count += 1u;
    }
    return count;
}

uint64_t cjgui_internal_renderer_coordinate_lifetime(uint64_t sessionToken, uint64_t *outSessionGeneration) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (outSessionGeneration) *outSessionGeneration = session ? session->token : 0u;
    return session ? session->token : 0u;
}

int cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(uint64_t sessionToken,
                                                                      uint64_t *outSessionGeneration,
                                                                      uint64_t *outCoordinateEpoch) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return (int)CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outSessionGeneration) *outSessionGeneration = session->token;
    if (outCoordinateEpoch) *outCoordinateEpoch = session->frameIndex;
    return (int)CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_activate_window(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    session->windowAppActive = 1;
    session->windowKey = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_request_close(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    g_stopRequested = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_activation_state(uint64_t sessionToken,
                                                                           int32_t *outKey, int32_t *outMain,
                                                                           int32_t *outAppActive) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outKey) *outKey = session->windowKey;
    if (outMain) *outMain = session->windowMain;
    if (outAppActive) *outAppActive = session->windowAppActive;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_number(uint64_t sessionToken, int64_t *outNumber) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // X11 没有"窗口编号"这一 AppKit 概念；给出会话内稳定的单调序号（>0），
    // 表示"这个问题在本平台有确定答案"，不冒充 NSWindow.windowNumber。
    if (outNumber) *outNumber = (int64_t)session->token;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_frame(uint64_t sessionToken, int64_t *outX,
                                                                int64_t *outY, int64_t *outWidth,
                                                                int64_t *outHeight) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    uint32_t width = 0u, height = 0u;
    int resized = 0;
    (void)cjgui_linux_window_size(session->window, &width, &height, &resized);
    if (outX) *outX = 0;
    if (outY) *outY = 0;
    if (outWidth) *outWidth = (int64_t)width;
    if (outHeight) *outHeight = (int64_t)height;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_stage_window_background(uint64_t sessionToken,
                                                                           uint64_t projectionVersion,
                                                                           uint32_t mode, uint32_t colorScheme) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI stage_window_background\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    session->backgroundStaged = 1;
    session->backgroundVersion = projectionVersion;
    session->backgroundMode = mode;
    session->backgroundColorScheme = colorScheme;
    // 背景色由模式决定：system/standard 用 clear color 基线；这是本平台自己的
    // 主题基线，不冒充 macOS 的实际窗口材质。
    if (mode == CJGUI_INTERNAL_WINDOW_BACKGROUND_OPAQUE) {
        session->backgroundRed = session->clear[0];
        session->backgroundGreen = session->clear[1];
        session->backgroundBlue = session->clear[2];
        session->backgroundAlpha = session->clear[3];
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_background_snapshot(
    uint64_t sessionToken, CjguiInternalRendererWindowBackgroundSnapshot *outSnapshot) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outSnapshot) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outSnapshot, 0, sizeof(*outSnapshot));
    // Linux 没有"系统窗口材质"这一层：请求 opaque 时 actualMode=opaque_fallback，
    // 因为窗口背景是渲染器自己画的，不是宿主系统在窗口后面装的。
    outSnapshot->acceptedSceneVersion = session->accepted.projectionVersion;
    outSnapshot->frameIndex = session->frameIndex;
    outSnapshot->requestRevision = session->backgroundVersion;
    outSnapshot->environmentRevision = 1u;
    outSnapshot->observationRevision = session->frameIndex;
    outSnapshot->requestedMode = session->backgroundMode;
    outSnapshot->backend = 0u;                 // 无 appkit_behind_window 等价物
    outSnapshot->actualMode = 2u;              // opaque_fallback
    outSnapshot->fallbackReason = session->backgroundStaged ? 1u : 0u;
    outSnapshot->completion = 1u;              // 同步完成，不是异步承诺
    outSnapshot->reduceTransparency = 0u;
    outSnapshot->windowActive = (uint32_t)(session->windowAppActive ? 1u : 0u);
    outSnapshot->colorScheme = session->backgroundColorScheme
        ? session->backgroundColorScheme : CJGUI_INTERNAL_WINDOW_COLOR_SCHEME_LIGHT;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 时钟

uint64_t cjgui_internal_renderer_owner_clock_ns(void) { return cjgui_linux_now_ns(); }

uint64_t cjgui_internal_renderer_owner_thread_cpu_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

uint64_t cjgui_internal_renderer_owner_trace_ns(void) { return cjgui_linux_now_ns(); }

uint32_t cjgui_internal_renderer_selection_background_version(void) {
    // 1 = 选区背景由共同层的 text runs 画（与 Windows 同）；版本 0 会让
    // composable_ui_window.cj 直接拒绝整个候选场景，2 才表示平台自绘。
    return 1u;
}

// 定义在场景暂存段，present 的提交点要用到，先声明。
static int cjgui_linux_commit_candidate(CjguiLinuxSession *session);

// ---------------------------------------------------------------- 呈现

CjguiInternalRendererStatus cjgui_internal_renderer_present_clear(uint64_t sessionToken,
                                                                 const CjguiInternalRendererClearColor *color,
                                                                 CjguiInternalRendererFrameObservation *outObservation) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI present_clear\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (color) {
        session->clear[0] = color->red;
        session->clear[1] = color->green;
        session->clear[2] = color->blue;
        session->clear[3] = color->alpha;
    }
    float clear[4] = { (float)session->clear[0], (float)session->clear[1], (float)session->clear[2],
                       (float)session->clear[3] };
    int status = cjgui_linux_gpu_begin_frame(session->gpu, clear);
    if (status == CJGUI_LINUX_GPU_OUT_OF_DATE) {
        uint32_t width = 0u, height = 0u; int resized = 0;
        (void)cjgui_linux_window_size(session->window, &width, &height, &resized);
        (void)cjgui_linux_gpu_resize(session->gpu, width, height);
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    if (status != CJGUI_LINUX_GPU_OK) {
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    int endStatus = cjgui_linux_gpu_end_frame(session->gpu);
    if (endStatus == CJGUI_LINUX_GPU_OUT_OF_DATE) {
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    session->frameIndex += 1u;
    cjgui_linux_fill_observation(session, outObservation);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(
    uint64_t sessionToken, CjguiInternalRendererFrameObservation *outObservation) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 提交点。共同层有两条场景路径：
    //   * 私有准备：begin → prepare×N → advance → configure → **promote**（promote 里已提交，
    //     提交后 candidate 被移走、invalid，所以这里不会再提交一次）；
    //   * 直接路径：**configure → set_node×N → present**，没有 promote。
    // 直接路径的提交点就是 present。漏掉它时 accepted 永远为空——实测症状：
    // 通知阈值窗口 configure_scene nodes=24、measure 3185 次，但
    // `CJGUI_LINUX_PRESENT frame=0 nodes=0 vertices=6 accepted=0 candidate=1`，
    // 窗口只画出背景。任何不走私有准备的消费者都会这样。
    if (session->candidate.valid && !session->preparationActive) {
        (void)cjgui_linux_commit_candidate(session);
    }
    if (getenv("CJGUI_LINUX_PRESENT_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_PRESENT_ENTER frame=%llu nodes=%u\n", (unsigned long long)session->frameIndex,
                session->accepted.nodeCount);
    }

    cjgui_linux_upload_atlas(session);

    CjguiLinuxVertexBuilder builder;
    memset(&builder, 0, sizeof(builder));
    cjgui_linux_append_background(session, &builder);
    cjgui_linux_append_scene(session, &builder);
    if (builder.failed) {
        free(builder.vertices);
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_READBACK_FAILED;
    }

    float clear[4] = { (float)session->clear[0], (float)session->clear[1], (float)session->clear[2],
                       (float)session->clear[3] };
    int status = cjgui_linux_gpu_begin_frame(session->gpu, clear);
    if (status == CJGUI_LINUX_GPU_OUT_OF_DATE) {
        uint32_t width = 0u, height = 0u; int resized = 0;
        (void)cjgui_linux_window_size(session->window, &width, &height, &resized);
        (void)cjgui_linux_gpu_resize(session->gpu, width, height);
        free(builder.vertices);
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    if (status != CJGUI_LINUX_GPU_OK) {
        free(builder.vertices);
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    if (getenv("CJGUI_LINUX_PRESENT_TRACE") && (session->frameIndex % 600u) == 0u) {
        fprintf(stderr, "CJGUI_LINUX_PRESENT frame=%llu nodes=%u vertices=%u accepted=%d candidate=%d\n",
                (unsigned long long)session->frameIndex, session->accepted.nodeCount, builder.count,
                session->accepted.valid, session->candidate.valid);
    }
    if (builder.count > 0u) {
        int drawStatus = cjgui_linux_gpu_draw_triangles(session->gpu, builder.vertices, builder.count);
        if (drawStatus != CJGUI_LINUX_GPU_OK) {
            free(builder.vertices);
            cjgui_linux_fill_observation(session, outObservation);
            return CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE;
        }
    }
    free(builder.vertices);
    int endStatus = cjgui_linux_gpu_end_frame(session->gpu);
    if (endStatus == CJGUI_LINUX_GPU_OUT_OF_DATE) {
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    session->frameIndex += 1u;
    cjgui_linux_fill_observation(session, outObservation);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_query_present(uint64_t sessionToken, uint64_t ticketId,
                                                                 CjguiInternalRendererPresentReceipt *outReceipt) {
    (void)ticketId;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outReceipt) memset(outReceipt, 0, sizeof(*outReceipt));
    // 本实现同步结算（present 返回即已接受/已拒绝），从不登记票据，
    // 所以任何 ticket 查询的终态都是 NONE，而不是"仍在途"。
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_acknowledge_present(uint64_t sessionToken, uint64_t ticketId) {
    (void)ticketId;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return CJGUI_INTERNAL_RENDERER_OK;   // 幂等；没有票据可回收
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_ticket_stats(
    uint64_t sessionToken, CjguiInternalRendererPresentTicketStats *outStats) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outStats) {
        memset(outStats, 0, sizeof(*outStats));
        // 同步结算：从不分配票据，因此所有计数保持 0；available=1 表示本平台
        // 确实实现了这个协议（而非返回无意义结构）。
        outStats->available = 1u;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_test_hold_next_composable_present(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 同步结算实现里没有"挂起的提交"，如实拒绝而不是假装已挂起。
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_test_resolve_pending_composable_present(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_display_progress(
    uint64_t sessionToken, CjguiInternalRendererComposableDisplayProgress *outProgress) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (outProgress) {
        memset(outProgress, 0, sizeof(*outProgress));
        outProgress->submittedFrameIndex = session->frameIndex;
        outProgress->submittedSceneVersion = session->accepted.projectionVersion;
        outProgress->currentPointWidth = (double)session->requestedWidth;
        outProgress->currentPointHeight = (double)session->requestedHeight;
        outProgress->currentBackingScale = cjgui_linux_gpu_scale(session->gpu);
        outProgress->currentDrawableWidthPixels = cjgui_linux_gpu_drawable_width(session->gpu);
        outProgress->currentDrawableHeightPixels = cjgui_linux_gpu_drawable_height(session->gpu);
        outProgress->submittedPointWidth = outProgress->currentPointWidth;
        outProgress->submittedPointHeight = outProgress->currentPointHeight;
        outProgress->submittedBackingScale = outProgress->currentBackingScale;
        outProgress->submittedDrawableWidthPixels = outProgress->currentDrawableWidthPixels;
        outProgress->submittedDrawableHeightPixels = outProgress->currentDrawableHeightPixels;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 场景暂存

static int cjgui_linux_commit_candidate(CjguiLinuxSession *session) {
    if (!session->candidate.valid) return 0;
    cjgui_linux_scene_move(&session->accepted, &session->candidate);
    session->accepted.valid = 1;
    session->preparationActive = 0;
    session->preparationId = 0u;
    return 1;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(uint64_t sessionToken,
                                                                              uint64_t projectionVersion,
                                                                              uint32_t nodeCount) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI configure_scene nodes=%u prep=%d\n", nodeCount, session ? session->preparationActive : -1);
    if (nodeCount == 0u || nodeCount > CJGUI_LINUX_MAX_NODES) {
        return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
    }
    // 共同层的私有准备顺序是 begin → prepare×N → advance → **configure** → promote：
    // 提交阶段会再用同一代重发一次 configure。此时进行中的准备已经写好这些槽位，
    // configure 必须只更新投影版本，**不能清空槽位、也不能清掉准备句柄**，
    // 否则 promote 会被判 SCENE_STALE（实测症状：窗口永远不出第一帧）。
    if (session->preparationActive && session->candidate.valid &&
        session->candidate.nodeCount == nodeCount) {
        session->candidate.projectionVersion = projectionVersion;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (!cjgui_linux_scene_reserve(&session->candidate, nodeCount)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    // 直接路径的 COW 语义：共同层只为**变化过的**节点发 set_node，跳过的索引表示
    // "沿用上一代"。所以新事务必须从已接受场景克隆，而不是清空——清空会让这些索引
    // 变成空节点，实测症状是首帧正常（24 节点/1050 顶点）之后掉回只剩背景。
    uint32_t carried = (session->accepted.valid && session->accepted.nodeCount < nodeCount)
        ? session->accepted.nodeCount
        : (session->accepted.valid ? nodeCount : 0u);
    for (uint32_t i = 0u; i < session->candidate.capacity; i += 1u) {
        if (i < carried) {
            cjgui_linux_slot_copy(&session->candidate.slots[i], &session->accepted.slots[i]);
        } else {
            cjgui_linux_slot_clear(&session->candidate.slots[i]);
        }
    }
    session->candidate.valid = 1;
    session->candidate.projectionVersion = projectionVersion;
    session->candidate.nodeCount = nodeCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_begin_composable_preparation(uint64_t sessionToken,
                                                                                uint64_t preparationId,
                                                                                uint64_t baseSceneVersion,
                                                                                uint64_t projectionVersion,
                                                                                uint32_t nodeCount) {
    (void)baseSceneVersion;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiInternalRendererStatus status =
        cjgui_internal_renderer_configure_composable_scene(sessionToken, projectionVersion, nodeCount);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    session->preparationActive = 1;
    session->preparationId = preparationId;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI begin_prep id=%llu nodes=%u\n", (unsigned long long)preparationId, nodeCount);
    return CJGUI_INTERNAL_RENDERER_OK;
}

static void cjgui_linux_slot_store_strings(CjguiLinuxNodeSlot *slot, const char *label, const char *value,
                                           const char *semanticId, const char *bindingKey, const char *rowKey,
                                           const char *parentRowKey, const char *semanticLabel,
                                           const char *encodedRuns) {
    cjgui_linux_replace(&slot->label, label ? label : "");
    cjgui_linux_replace(&slot->value, value ? value : "");
    if (semanticId) cjgui_linux_replace(&slot->semanticId, semanticId);
    if (bindingKey) cjgui_linux_replace(&slot->bindingKey, bindingKey);
    if (rowKey) cjgui_linux_replace(&slot->rowKey, rowKey);
    if (parentRowKey) cjgui_linux_replace(&slot->parentRowKey, parentRowKey);
    if (semanticLabel) cjgui_linux_replace(&slot->semanticLabel, semanticLabel);
    if (encodedRuns) cjgui_linux_replace(&slot->encodedRuns, encodedRuns);
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_node(
    uint64_t sessionToken, uint64_t preparationId, uint32_t index,
    const CjguiInternalRendererComposableNode *node, const CjguiInternalRendererComposableGeometry *geometry,
    const char *label, const char *value, const char *semanticId, const char *bindingKey, const char *rowKey,
    const char *parentRowKey, const char *semanticLabel, const char *encodedRuns) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->candidate.valid || !node) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI prepare idx=%u NOT_STAGED\n", index);
        return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    }
    if (session->preparationActive && preparationId != session->preparationId) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI prepare idx=%u STALE prep=%llu have=%llu\n", index, (unsigned long long)preparationId, (unsigned long long)session->preparationId);
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (index >= session->candidate.nodeCount) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI prepare idx=%u NOT_FOUND count=%u\n", index, session->candidate.nodeCount);
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    CjguiLinuxNodeSlot *slot = &session->candidate.slots[index];
    cjgui_linux_slot_clear(slot);
    slot->node = *node;
    if (geometry) { slot->geometry = *geometry; slot->geometryPresent = 1; }
    cjgui_linux_slot_store_strings(slot, label, value, semanticId, bindingKey, rowKey, parentRowKey,
                                   semanticLabel, encodedRuns);
    cjgui_linux_run_apply(session, slot);
    session->nodeWriteCount += 1u;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI prepare_ok idx=%u\n", index);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_advance_composable_preparation(uint64_t sessionToken,
                                                                                  uint64_t preparationId,
                                                                                  uint64_t deadlineNs,
                                                                                  uint32_t *outReady) {
    (void)deadlineNs;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->preparationActive || preparationId != session->preparationId) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    // 本实现的准备是同步写入内存，没有独立的 native worker，所以"就绪"就是
    // "候选已完整声明"。不伪报一个后台进度。
    if (outReady) *outReady = session->candidate.valid ? 1u : 0u;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI advance id=%llu ready=%u\n", (unsigned long long)preparationId, outReady ? *outReady : 0u);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_promote_composable_preparation(uint64_t sessionToken,
                                                                                  uint64_t preparationId) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI promote_enter prep=%llu active=%d have=%llu\n", (unsigned long long)preparationId, session ? session->preparationActive : -1, session ? (unsigned long long)session->preparationId : 0ull);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->preparationActive || preparationId != session->preparationId) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (!cjgui_linux_commit_candidate(session)) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI promote NOT_STAGED\n");
        return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_preparation(uint64_t sessionToken,
                                                                                 uint64_t preparationId) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI cancel_prep id=%llu\n", (unsigned long long)preparationId);
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->preparationActive || preparationId != session->preparationId) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    cjgui_linux_scene_reset(&session->candidate);
    session->preparationActive = 0;
    session->preparationId = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_discard_composable_scene_candidate(uint64_t sessionToken) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI discard_candidate\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    cjgui_linux_scene_reset(&session->candidate);
    session->preparationActive = 0;
    session->preparationId = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_geometry(
    uint64_t sessionToken, uint64_t projectionVersion, uint32_t nodeIndex,
    const CjguiInternalRendererComposableGeometry *geometry) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!geometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiLinuxScene *scene = session->candidate.valid ? &session->candidate : &session->accepted;
    if (!scene->valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (scene->projectionVersion != projectionVersion) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (nodeIndex >= scene->nodeCount) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    scene->slots[nodeIndex].geometry = *geometry;
    scene->slots[nodeIndex].geometryPresent = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cjgui_linux_store_scene_node(
    uint64_t sessionToken, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath, const char *imageResourceId,
    uint64_t imageResourceVersion) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!node) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!session->candidate.valid) {
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_configure_composable_scene(sessionToken, session->accepted.projectionVersion,
                                                              session->accepted.nodeCount);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    if (nodeIndex >= session->candidate.nodeCount) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CjguiLinuxNodeSlot *slot = &session->candidate.slots[nodeIndex];
    cjgui_linux_slot_clear(slot);
    slot->node = *node;
    slot->imageResourceVersion = imageResourceVersion;
    cjgui_linux_replace(&slot->label, label ? label : "");
    cjgui_linux_replace(&slot->value, value ? value : "");
    cjgui_linux_replace(&slot->imageResourcePath, imageResourcePath ? imageResourcePath : "");
    cjgui_linux_replace(&slot->imageResourceId, imageResourceId ? imageResourceId : "");
    cjgui_linux_run_apply(session, slot);
    session->nodeWriteCount += 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node(
    uint64_t sessionToken, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath, const char *imageResourceId,
    uint64_t imageResourceVersion) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_node_call idx=%u\n", nodeIndex);
    return cjgui_linux_store_scene_node(sessionToken, nodeIndex, node, label, value, imageResourcePath,
                                        imageResourceId, imageResourceVersion);
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node_bytes(
    uint64_t sessionToken, uint32_t nodeIndex, const CjguiInternalRendererComposableNode *node,
    const char *label, const char *value, const char *imageResourcePath, const char *imageResourceId,
    uint64_t imageResourceVersion, const uint8_t *bytes, uint32_t length) {
    // 本阶段不做图片解码与上传：节点照常入库，字节被显式拒绝而不是静默丢弃。
    CjguiInternalRendererStatus status = cjgui_linux_store_scene_node(
        sessionToken, nodeIndex, node, label, value, imageResourcePath, imageResourceId, imageResourceVersion);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (!bytes || length == 0u) return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_identity(
    uint64_t sessionToken, uint32_t nodeIndex, const char *semanticId) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_composable_node_semantic_identity\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->candidate.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (nodeIndex >= session->candidate.nodeCount) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    cjgui_linux_replace(&session->candidate.slots[nodeIndex].semanticId, semanticId ? semanticId : "");
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_metadata(
    uint64_t sessionToken, uint32_t nodeIndex, const char *bindingKey, const char *rowKey,
    const char *parentRowKey, const char *semanticLabel) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_composable_node_semantic_metadata\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->candidate.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (nodeIndex >= session->candidate.nodeCount) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CjguiLinuxNodeSlot *slot = &session->candidate.slots[nodeIndex];
    cjgui_linux_replace(&slot->bindingKey, bindingKey ? bindingKey : "");
    cjgui_linux_replace(&slot->rowKey, rowKey ? rowKey : "");
    cjgui_linux_replace(&slot->parentRowKey, parentRowKey ? parentRowKey : "");
    cjgui_linux_replace(&slot->semanticLabel, semanticLabel ? semanticLabel : "");
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_text_runs(uint64_t sessionToken,
                                                                            uint64_t nodeId,
                                                                            const char *encoded) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_composable_text_runs\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 声明按 nodeId 保存，**不要求该节点此刻已在候选/已接受场景里**：共同层在
    // configure 之后、节点入库之前安装 run 声明（S1 顺序）。声明在该节点入库时
    // 挂到槽位上；已入库的同 id 节点立即更新。
    uint32_t slotIndex = CJGUI_LINUX_MAX_RUN_DECLARATIONS;
    for (uint32_t i = 0u; i < session->runCount; i += 1u) {
        if (session->runs[i].nodeId == nodeId) { slotIndex = i; break; }
    }
    if (slotIndex == CJGUI_LINUX_MAX_RUN_DECLARATIONS) {
        if (session->runCount >= CJGUI_LINUX_MAX_RUN_DECLARATIONS) {
            return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
        }
        slotIndex = session->runCount;
        session->runs[slotIndex].nodeId = nodeId;
        session->runs[slotIndex].encoded = NULL;
        session->runCount += 1u;
    }
    cjgui_linux_replace(&session->runs[slotIndex].encoded, encoded ? encoded : "");
    CjguiLinuxScene *scene = session->candidate.valid ? &session->candidate : &session->accepted;
    if (scene->valid) {
        for (uint32_t i = 0u; i < scene->nodeCount; i += 1u) {
            if (scene->slots[i].node.nodeId == nodeId) {
                cjgui_linux_replace(&scene->slots[i].encodedRuns, encoded ? encoded : "");
                break;
            }
        }
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_viewport(uint64_t sessionToken,
                                                                      CjguiInternalRendererViewport *outViewport) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outViewport) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint32_t width = 0u, height = 0u; int resized = 0;
    (void)cjgui_linux_window_size(session->window, &width, &height, &resized);
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI viewport w=%u h=%u\n", width, height);
    memset(outViewport, 0, sizeof(*outViewport));
    outViewport->width = width;
    outViewport->height = height;
    outViewport->resizeVersion = session->frameIndex;
    outViewport->resourceCompletionVersion = session->frameIndex;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_node_rect(uint64_t sessionToken, uint64_t nodeId,
                                                             int64_t *outX, int64_t *outY, int64_t *outWidth,
                                                             int64_t *outHeight) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->accepted.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        const CjguiInternalRendererComposableNode *node = &session->accepted.slots[i].node;
        if (node->nodeId != nodeId) continue;
        if (outX) *outX = node->x;
        if (outY) *outY = node->y;
        if (outWidth) *outWidth = node->width;
        if (outHeight) *outHeight = node->height;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
}

// 命中路由：返回最上层（preorder 最后）包含该点的节点。优先可交互节点；
// 没有可交互节点命中时退回最后一个几何命中节点（容器也要能收到事件）。
static CjguiLinuxNodeSlot *cjgui_linux_hit_test(CjguiLinuxSession *session, double x, double y) {
    if (!session->accepted.valid) return NULL;
    CjguiLinuxNodeSlot *fallback = NULL;
    CjguiLinuxNodeSlot *interactive = NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        const CjguiInternalRendererComposableNode *node = &slot->node;
        if (node->width <= 0 || node->height <= 0) continue;
        double left = (double)node->x + cjgui_linux_slot_translate_x(slot);
        double top = (double)node->y + cjgui_linux_slot_translate_y(slot);
        double right = left + (double)node->width, bottom = top + (double)node->height;
        if (node->clipWidth > 0 && node->clipHeight > 0) {
            double clipLeft = (double)node->clipX, clipTop = (double)node->clipY;
            double clipRight = clipLeft + (double)node->clipWidth, clipBottom = clipTop + (double)node->clipHeight;
            if (left < clipLeft) left = clipLeft;
            if (top < clipTop) top = clipTop;
            if (right > clipRight) right = clipRight;
            if (bottom > clipBottom) bottom = clipBottom;
        }
        if (x < left || x >= right || y < top || y >= bottom) continue;
        fallback = slot;
        if (node->isInteractive) interactive = slot;
    }
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI hit x=%.1f y=%.1f -> node=%llu kind=%u interactive=%d\n", x, y,
                interactive ? (unsigned long long)interactive->node.nodeId : (fallback ? (unsigned long long)fallback->node.nodeId : 0ull),
                interactive ? interactive->node.nodeKind : (fallback ? fallback->node.nodeKind : 0u),
                interactive ? 1 : 0);
    }
    return interactive ? interactive : fallback;
}

// 滚轮目标：与 Windows 同判据（cjgui_windows_renderer.c:3097-3099）——必须投给
// **包含该点的 SCROLL_AREA 或 wheelScrollable 节点**，而不是叶子。投给叶子时共同层
// 的滚轮路由拿不到可滚动目标，表现为滚动区 offset 永不变化。
static CjguiLinuxNodeSlot *cjgui_linux_wheel_target(CjguiLinuxSession *session, double x, double y) {
    if (!session->accepted.valid) return NULL;
    CjguiLinuxNodeSlot *scrollable = NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        const CjguiInternalRendererComposableNode *node = &slot->node;
        if (node->nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA && node->wheelScrollable == 0u) {
            continue;
        }
        if (node->width <= 0 || node->height <= 0) continue;
        double left = (double)node->x + cjgui_linux_slot_translate_x(slot);
        double top = (double)node->y + cjgui_linux_slot_translate_y(slot);
        double right = left + (double)node->width, bottom = top + (double)node->height;
        if (node->clipWidth > 0 && node->clipHeight > 0) {
            double clipLeft = (double)node->clipX, clipTop = (double)node->clipY;
            double clipRight = clipLeft + (double)node->clipWidth, clipBottom = clipTop + (double)node->clipHeight;
            if (left < clipLeft) left = clipLeft;
            if (top < clipTop) top = clipTop;
            if (right > clipRight) right = clipRight;
            if (bottom > clipBottom) bottom = clipBottom;
        }
        if (x < left || x >= right || y < top || y >= bottom) continue;
        scrollable = slot;
    }
    return scrollable ? scrollable : cjgui_linux_hit_test(session, x, y);
}

// ---------------------------------------------------------------- 文字测量

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_text(
    uint64_t sessionToken, const char *text, double fontSize, uint32_t fontWeight, uint32_t fontFamily,
    uint32_t maximumWidth, CjguiInternalRendererTextMeasurement *outMeasurement) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!text) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    uint32_t quadCount = 0u;
    double width = 0.0, height = 0.0, ascent = 0.0;
    int status = cjgui_linux_text_layout(session->text, text, strlen(text), fontSize, fontWeight, fontFamily,
                                         (double)maximumWidth, 0.0, 0.0, 0, NULL, 0u, &quadCount, &width,
                                         &height, &ascent);
    if (status != CJGUI_LINUX_TEXT_OK && status != CJGUI_LINUX_TEXT_BUDGET_EXCEEDED) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_ABI measure_text FAIL status=%d bytes=%zu maxW=%u font=%.1f family=%u\n",
                    status, strlen(text), maximumWidth, fontSize, fontFamily);
        }
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    session->textLayoutPreparationCount += 1u;
    // lineHeight 是**一行的行高**，不是文本块高度：共同层把 lineHeight == 0 判为
    // 测量失败（runtime_renderer_session.cj:4234），而且那个状态是粘性的——空文本
    // 标签一次就会毒化整轮布局，表现为 CJGUI_STATIC_LAYOUT_REFUSED
    // reason=layout_native_measurement_failed。所以这里必须给真实行高。
    double lineHeight = cjgui_linux_text_line_height(session->text, fontSize, fontWeight, fontFamily);
    if (lineHeight <= 0.0) lineHeight = fontSize * 1.2;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI measure_text ok bytes=%zu w=%.1f h=%.1f lh=%.1f\n", strlen(text), width,
                height, lineHeight);
    }
    if (outMeasurement) {
        memset(outMeasurement, 0, sizeof(*outMeasurement));
        outMeasurement->width = (uint32_t)(width + 0.5);
        outMeasurement->height = (uint32_t)(height + 0.5);
        outMeasurement->baseline = (uint32_t)(ascent + 0.5);
        outMeasurement->lineHeight = (uint32_t)(lineHeight + 0.5);
        if (outMeasurement->lineHeight == 0u) outMeasurement->lineHeight = 1u;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_multiline_natural_height(
    uint64_t sessionToken, const char *text, double fontSize, uint32_t fontWeight, uint32_t fontFamily,
    uint32_t contentWidth, uint32_t *outHeight) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!text) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    uint32_t quadCount = 0u;
    double width = 0.0, height = 0.0, ascent = 0.0;
    int status = cjgui_linux_text_layout(session->text, text, strlen(text), fontSize, fontWeight, fontFamily,
                                         (double)contentWidth, 0.0, 0.0, 0, NULL, 0u, &quadCount, &width,
                                         &height, &ascent);
    if (status != CJGUI_LINUX_TEXT_OK && status != CJGUI_LINUX_TEXT_BUDGET_EXCEEDED) {
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    session->textLayoutPreparationCount += 1u;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI multiline_h ok bytes=%zu h=%.1f\n", strlen(text), height);
    }
    if (outHeight) {
        double lineHeight = cjgui_linux_text_line_height(session->text, fontSize, fontWeight, fontFamily);
        if (lineHeight <= 0.0) lineHeight = fontSize * 1.2;
        uint32_t computed = (uint32_t)(height + 0.5);
        if (computed == 0u) computed = (uint32_t)(lineHeight + 0.5);
        if (computed == 0u) computed = 1u;
        *outHeight = computed;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_declare_input_caret(uint64_t sessionToken, int64_t nodeId, double x, double y,
                                                   double width, double height) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI declare_input_caret\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return (int32_t)CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    session->caretNodeId = nodeId;
    session->caretX = x;
    session->caretY = y;
    session->caretWidth = width;
    session->caretHeight = height;
    // 候选窗位置消费当前已接受场景里的光标几何（跟节点/滚动一起移动）。
    cjgui_linux_window_set_ime_spot(session->window, x, y, height);
    return (int32_t)CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 输入翻译

// X11 keysym 常量（只取本阶段用到的，避免在会话层引入 X11 头）。
#define CJGUI_LINUX_XK_BACKSPACE 0xFF08u
#define CJGUI_LINUX_XK_RETURN    0xFF0Du
#define CJGUI_LINUX_XK_ESCAPE    0xFF1Bu
#define CJGUI_LINUX_XK_HOME      0xFF50u
#define CJGUI_LINUX_XK_LEFT      0xFF51u
#define CJGUI_LINUX_XK_UP        0xFF52u
#define CJGUI_LINUX_XK_RIGHT     0xFF53u
#define CJGUI_LINUX_XK_DOWN      0xFF54u
#define CJGUI_LINUX_XK_END       0xFF57u
#define CJGUI_LINUX_XK_DELETE    0xFFFFu

static uint32_t cjgui_linux_pending_free(const CjguiLinuxSession *session) {
    return CJGUI_LINUX_PENDING_EVENTS - session->pendingCount;
}

static int cjgui_linux_pending_push(CjguiLinuxSession *session, uint32_t kind, const CjguiLinuxNodeSlot *slot,
                                    int64_t pointerX, int64_t pointerY, int64_t modifiers,
                                    const char *text) {
    if (session->pendingCount >= CJGUI_LINUX_PENDING_EVENTS) {
        // 不变式：泵在每个 X11 事件之前按 PER_EVENT 上界预留槽位，这里不该满。
        // 万一满了也绝不清 pendingCount/pendingHead：那会把已经接收、尚未被共同层
        // 消费的事件整批丢掉。只记具名计数并拒绝这一条，让调用方先在下一轮消费。
        session->pendingOverflowCount += 1u;
        if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_QUEUE_OVERFLOW kind=%u queued=%u\n", kind, session->pendingCount);
        }
        return 0;
    }
    uint32_t index = (session->pendingHead + session->pendingCount) % CJGUI_LINUX_PENDING_EVENTS;
    CjguiInternalRendererEvent *event = &session->pending[index].event;
    memset(event, 0, sizeof(*event));
    event->kind = kind;
    event->modifierFlags = modifiers;
    event->pointerX = pointerX;
    event->pointerY = pointerY;
    // 投影版本必须取**已接受场景版本**，不是节点自带的那个字段：共同层用它与
    // nativeInputScene.version 做严格相等判定（activation prefix gate / 输入解析），
    // 节点字段实测恒为 1，会让每一条真实输入都被判"原控件已刷新或移除"而拒绝。
    // Windows 侧同样用 s->acceptedScene.version（cjgui_windows_renderer.c）。
    event->projectionVersion = session->accepted.projectionVersion;
    if (slot) {
        event->nodeId = slot->node.nodeId;
        event->resourceId = slot->node.resourceId;
        event->nodeKind = slot->node.nodeKind;
        event->acceptedBindingEpoch = slot->node.acceptedBindingEpoch;
    }
    session->pending[index].hasText = (text && text[0]) ? 1 : 0;
    session->pending[index].text[0] = '\0';
    if (session->pending[index].hasText) {
        size_t length = strlen(text);
        if (length >= CJGUI_LINUX_PENDING_TEXT) length = CJGUI_LINUX_PENDING_TEXT - 1u;
        memcpy(session->pending[index].text, text, length);
        session->pending[index].text[length] = '\0';
    }
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_QUEUE kind=%u node=%llu epoch=%llu\n", kind,
                (unsigned long long)event->nodeId, (unsigned long long)event->bindingEpoch);
    }
    session->pendingCount += 1u;
    return 1;
}

static void cjgui_linux_capture_pointer_geometry(const CjguiLinuxSession *session,
                                                 const CjguiLinuxNodeSlot *slot, double x, double y,
                                                 CjguiInternalRendererPointerEventGeometry *out) {
    memset(out, 0, sizeof(*out));
    if (!slot) return;
    out->present = 1u;
    out->kind = 0u;
    out->nodeId = slot->node.nodeId;
    // 与事件的 projectionVersion 同源捕获：共同层要求 geometry 与 event 的
    // node/version/resource/kind 完全相等，节点自带字段实测恒为 1，会让每次命中
    // 都被判成不精确。
    out->projectionVersion = session->accepted.projectionVersion;
    out->resourceId = slot->node.resourceId;
    out->nodeKind = slot->node.nodeKind;
    out->x = x;
    out->y = y;
    out->translateX = cjgui_linux_slot_translate_x(slot);
    out->translateY = cjgui_linux_slot_translate_y(slot);
}

static int cjgui_linux_pending_push_geometry(CjguiLinuxSession *session, uint32_t kind,
                                             const CjguiLinuxNodeSlot *slot, int64_t pointerX, int64_t pointerY,
                                             int64_t modifiers, const char *text,
                                             const CjguiInternalRendererPointerEventGeometry *geometry) {
    if (!cjgui_linux_pending_push(session, kind, slot, pointerX, pointerY, modifiers, text)) return 0;
    if (!geometry) return 1;
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pending[index].geometry = *geometry;
    session->pending[index].geometry.kind = kind;
    session->pending[index].hasGeometry = 1;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_QUEUE_GEOM kind=%u ev_node=%llu ev_proj=%llu geom_node=%llu geom_proj=%llu\n",
                kind, (unsigned long long)session->pending[index].event.nodeId,
                (unsigned long long)session->pending[index].event.projectionVersion,
                (unsigned long long)geometry->nodeId, (unsigned long long)geometry->projectionVersion);
    }
    return 1;
}

// 对当前文本代理应用一次编辑；成功返回 1 并把新值与选区写回代理。
static int cjgui_linux_proxy_insert(CjguiLinuxSession *session, uint32_t replacementStart16,
                                    uint32_t replacementLength16, const char *inserted) {
    // 用产生这笔输入的会话，不扫描全局第一个 active proxy；否则双窗口时
    // A 窗口的按键会写进 B 窗口的代理。
    if (!session || !session->proxy.active) return 0;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_INPUT_SESSION session=%p start=%u len=%u\n", (void *)session,
                replacementStart16, replacementLength16);
    }
    const char *current = session->proxy.value ? session->proxy.value : "";
    size_t length = strlen(current);
    size_t replaceStart = cjgui_linux_byte_offset_for_utf16(current, length, replacementStart16);
    size_t replaceEnd = cjgui_linux_byte_offset_for_utf16(current, length, replacementStart16 + replacementLength16);
    if (replaceEnd < replaceStart) replaceEnd = replaceStart;
    size_t insertLength = inserted ? strlen(inserted) : 0u;
    size_t newLength = length - (replaceEnd - replaceStart) + insertLength;
    char *updated = (char *)malloc(newLength + 1u);
    if (!updated) return 0;
    memcpy(updated, current, replaceStart);
    if (insertLength > 0u) memcpy(updated + replaceStart, inserted, insertLength);
    memcpy(updated + replaceStart + insertLength, current + replaceEnd, length - replaceEnd);
    updated[newLength] = '\0';
    free(session->proxy.value);
    session->proxy.value = updated;
    const char *insertedText = inserted ? inserted : "";
    uint32_t caret16 = replacementStart16 +
        cjgui_linux_utf16_for_byte_offset(insertedText, insertLength, insertLength);
    session->proxy.selectionStart16 = caret16;
    session->proxy.selectionEnd16 = caret16;
    return 1;
}

// 一次编辑（打字/删除/粘贴）的完整承载：先按定长上界确认队列有空位，再修改代理，
// 然后把整值与增量两条事件连同这一笔自己的前像/后像/替换串一起入队。容量不足时
// 代理保持原值，不产生半截事件；两条事件永远不会指向另一笔编辑的载荷。
static int cjgui_linux_emit_text_edit(CjguiLinuxSession *session, uint32_t replaceStart16,
                                      uint32_t replaceLength16, const char *inserted) {
    if (!session->proxy.active) return 0;
    if (cjgui_linux_pending_free(session) < 2u) {
        session->pendingOverflowCount += 1u;
        if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_EDIT_DEFERRED queued=%u\n", session->pendingCount);
        }
        return 0;
    }
    char *preBody = cjgui_linux_strdup(session->proxy.value ? session->proxy.value : "");
    if (!cjgui_linux_proxy_insert(session, replaceStart16, replaceLength16, inserted)) {
        cjgui_linux_strfree(&preBody);
        return 0;
    }
    CjguiLinuxNodeSlot routing;
    memset(&routing, 0, sizeof(routing));
    routing.node.nodeId = session->proxy.nodeId;
    // 事件的投影版本取当前已接受场景；节点自带字段实测恒为 1，会被判 stale。
    routing.node.projectionVersion = session->accepted.valid ? session->accepted.projectionVersion
                                                            : session->proxy.sceneVersion;
    routing.node.resourceId = session->proxy.resourceId;
    routing.node.nodeKind = session->proxy.nodeKind;
    CjguiLinuxRangeIntentView intent;
    memset(&intent, 0, sizeof(intent));
    intent.present = 1;
    intent.nodeId = session->proxy.nodeId;
    intent.resourceId = session->proxy.resourceId;
    intent.nodeKind = session->proxy.nodeKind;
    intent.bindingEpoch = session->proxy.bindingEpoch;
    intent.replacementStart16 = replaceStart16;
    intent.replacementLength16 = replaceLength16;
    session->rangeIntentProduced += 1u;
    intent.sequence = session->rangeIntentProduced;
    const char *newValue = session->proxy.value ? session->proxy.value : "";
    // 整值事件保持既有含义；增量事件只描述被替换的 UTF-16 范围与插入串，
    // 两者都交给共同层决定用哪一条（不在这里替它合并）。
    if (!cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED, &routing,
                                  0, 0, 0, newValue)) {
        cjgui_linux_strfree(&preBody);
        return 0;
    }
    {
        uint32_t last = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
        session->pending[last].event.bindingEpoch = session->proxy.bindingEpoch;
        if (session->rangeEditDeltaEnabled) {
            session->pending[last].event.replacementStart16 = (int64_t)replaceStart16;
            session->pending[last].event.replacementLength16 = (int64_t)replaceLength16;
        }
    }
    if (!cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED, &routing,
                                  0, 0, 0, inserted)) {
        cjgui_linux_strfree(&preBody);
        return 0;
    }
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pending[index].event.bindingEpoch = session->proxy.bindingEpoch;
    // 普通（非 claimed）范围消费方把 selectionStart/End 当作**被替换的**
    // UTF-16 范围；插入后的光标只属于代理自身。写光标会让窗口会话把插入点
    // 当成替换范围（实测：outside_materialized_window，owner 收不到编辑）。
    session->pending[index].event.selectionStart = (int64_t)replaceStart16;
    session->pending[index].event.selectionEnd = (int64_t)(replaceStart16 + replaceLength16);
    session->pending[index].event.replacementStart16 = (int64_t)replaceStart16;
    session->pending[index].event.replacementLength16 = (int64_t)replaceLength16;
    session->pending[index].hasRangeIntent = 1;
    session->pending[index].rangeIntent = intent;
    // 所有权转交这笔事件；出队时再移到会话槽供 getter 借用。
    session->pending[index].rangePreBody = preBody;
    session->pending[index].rangePostBody = cjgui_linux_strdup(newValue);
    session->pending[index].rangeReplacement = cjgui_linux_strdup(inserted ? inserted : "");
    return 1;
}

// UTF-8 完整性检查：粘贴只接受完整字符序列，不把半个字符写进正文。
static int cjgui_linux_utf8_complete(const char *text, size_t length) {
    size_t index = 0u;
    while (index < length) {
        unsigned char c = (unsigned char)text[index];
        size_t need = 0u;
        if (c < 0x80u) need = 0u;
        else if ((c & 0xE0u) == 0xC0u) need = 1u;
        else if ((c & 0xF0u) == 0xE0u) need = 2u;
        else if ((c & 0xF8u) == 0xF0u) need = 3u;
        else return 0;
        if (index + need >= length) return 0;
        for (size_t i = 1u; i <= need; i++) {
            if (index + i >= length) return 0;
            if (((unsigned char)text[index + i] & 0xC0u) != 0x80u) return 0;
        }
        index += need + 1u;
    }
    return 1;
}

// 一次粘贴 = 一笔逻辑编辑，复用既有范围编辑入口；不改另一套剪贴板状态。
static int cjgui_linux_apply_paste(CjguiLinuxSession *session, const char *text, size_t length) {
    if (!session->proxy.active) {
        fprintf(stderr, "CJGUI_LINUX_PASTE_REJECTED reason=no_text_proxy bytes=%zu\n", length);
        return 0;
    }
    if (length >= CJGUI_LINUX_FORM_TEXT_CAPACITY) {
        fprintf(stderr, "CJGUI_LINUX_PASTE_REJECTED reason=too_large bytes=%zu capacity=%u\n",
                length, CJGUI_LINUX_FORM_TEXT_CAPACITY - 1u);
        fflush(stderr);
        return 0;
    }
    if (length == 0u) return 1;
    const char *current = session->proxy.value ? session->proxy.value : "";
    size_t currentLength = strlen(current);
    uint32_t start16 = session->proxy.selectionStart16;
    uint32_t end16 = session->proxy.selectionEnd16;
    if (start16 > end16) { uint32_t swap = start16; start16 = end16; end16 = swap; }
    // 容量判据看这笔编辑**之后**的正文：替换非空选区时旧字节会被换掉，
    // 不能用"旧全文 + 插入串"把其实放得下的替换误拒。
    size_t replaceFrom = cjgui_linux_byte_offset_for_utf16(current, currentLength, start16);
    size_t replaceTo = cjgui_linux_byte_offset_for_utf16(current, currentLength, end16);
    if (replaceTo < replaceFrom) replaceTo = replaceFrom;
    size_t resulting = currentLength - (replaceTo - replaceFrom) + length;
    if (resulting >= CJGUI_LINUX_PENDING_TEXT) {
        // 代理本值也必须完整进入逐事件载荷；放不下时整笔拒绝而不是留半截。
        fprintf(stderr, "CJGUI_LINUX_PASTE_REJECTED reason=document_too_large bytes=%zu resulting=%zu\n",
                length, resulting);
        fflush(stderr);
        return 0;
    }
    if (memchr(text, '\0', length) != NULL || !cjgui_linux_utf8_complete(text, length)) {
        fprintf(stderr, "CJGUI_LINUX_PASTE_REJECTED reason=invalid_utf8 bytes=%zu\n", length);
        fflush(stderr);
        return 0;
    }
    memcpy(session->formText, text, length);
    session->formText[length] = '\0';
    int applied = cjgui_linux_emit_text_edit(session, start16, end16 - start16, session->formText);
    if (applied) {
        fprintf(stderr, "CJGUI_LINUX_PASTE bytes=%zu replace=%u:%u\n", length, start16,
                end16 - start16);
    }
    return applied;
}

// IME 相位 -> 共同层 kind 52。首份 update 用选择起点冻结替换范围；后续 update
// 报告同一 marked 起点与上一份 preedit 长度；提交/取消终结同一身份。
static int cjgui_linux_emit_composition(CjguiLinuxSession *session, uint32_t phase,
                                        const char *text, uint32_t innerCaret16) {
    if (!session->proxy.active) {
        fprintf(stderr, "CJGUI_LINUX_COMPOSITION_REJECTED reason=no_text_proxy phase=%u\n", phase);
        return 0;
    }
    uint32_t text16 = text ? cjgui_linux_utf16_length(text, strlen(text)) : 0u;
    if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE) {
        if (!session->compositionActive) {
            session->compositionIdCounter += 1u;
            if (session->compositionIdCounter == 0u) session->compositionIdCounter = 1u;
            session->compositionId = session->compositionIdCounter;
            uint32_t a = session->proxy.selectionStart16;
            uint32_t b = session->proxy.selectionEnd16;
            if (a > b) { uint32_t swap = a; a = b; b = swap; }
            session->compositionStart16 = a;
            session->compositionLength16 = b - a;
            session->compositionReplaceLength16 = b - a;
            session->compositionActive = 1;
        }
        if (innerCaret16 > text16) innerCaret16 = text16;
        size_t copyLength = text ? strlen(text) : 0u;
        if (copyLength >= sizeof(session->compositionText)) {
            copyLength = sizeof(session->compositionText) - 1u;
        }
        if (copyLength > 0u) memcpy(session->compositionText, text, copyLength);
        session->compositionText[copyLength] = '\0';
        session->compositionTextLength = copyLength;
    } else if (!session->compositionActive) {
        // 迟到的终态：共同层同样会按身份判重；这里不产生第二条意图。
        return 0;
    }

    CjguiLinuxNodeSlot routing;
    memset(&routing, 0, sizeof(routing));
    routing.node.nodeId = session->proxy.nodeId;
    routing.node.projectionVersion = session->accepted.valid ? session->accepted.projectionVersion
                                                            : session->proxy.sceneVersion;
    routing.node.resourceId = session->proxy.resourceId;
    routing.node.nodeKind = session->proxy.nodeKind;
    if (!cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION,
                                  &routing, 0, 0, 0, text ? text : "")) {
        return 0;
    }
    if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT) {
        // 提交在代理上立即落字并推进光标；正文写入仍只经这一条提交事件。
        // 不这样做的话，代理会停留在组合前的旧值，下一次组合从旧光标起算，
        // 把刚提交的文本当成待替换范围。
        (void)cjgui_linux_proxy_insert(session, session->compositionStart16,
                                       session->compositionReplaceLength16, text);
    }
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    CjguiInternalRendererEvent *out = &session->pending[index].event;
    out->compositionPhase = phase;
    out->compositionId = session->compositionId;
    out->replacementStart16 = (int64_t)session->compositionStart16;
    out->replacementLength16 = (int64_t)session->compositionLength16;
    out->markedStart16 = (int64_t)session->compositionStart16;
    out->markedLength16 = (int64_t)(phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE
                                        ? text16
                                        : 0);
    out->selectionStart = innerCaret16;
    out->selectionEnd = innerCaret16;
    out->bindingEpoch = session->proxy.bindingEpoch;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr,
                "CJGUI_LINUX_COMPOSITION_PUSH phase=%u id=%u start=%u len=%u text16=%u caret16=%u\n",
                phase, session->compositionId, session->compositionStart16,
                session->compositionLength16, text16, innerCaret16);
    }
    if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE) {
        session->compositionLength16 = text16;
    } else {
        session->compositionActive = 0;
        session->compositionLength16 = 0u;
        session->compositionReplaceLength16 = 0u;
        session->compositionTextLength = 0u;
        session->compositionText[0] = '\0';
    }
    return 1;
}

static const char *cjgui_linux_clipboard_status_name(int status) {
    switch (status) {
        case CJGUI_LINUX_CLIPBOARD_READ_EMPTY: return "empty";
        case CJGUI_LINUX_CLIPBOARD_READ_UNSUPPORTED: return "unsupported";
        case CJGUI_LINUX_CLIPBOARD_READ_TOO_LARGE: return "too_large";
        case CJGUI_LINUX_CLIPBOARD_READ_TIMEOUT: return "timeout";
        case CJGUI_LINUX_CLIPBOARD_READ_ERROR: return "error";
        default: return "unknown";
    }
}

static void cjgui_linux_clipboard_poll(CjguiLinuxSession *session) {
    if (!session->pastePending) return;
    char *buffer = (char *)malloc(CJGUI_LINUX_FORM_TEXT_CAPACITY);
    if (!buffer) {
        session->pastePending = 0;
        return;
    }
    size_t length = 0u;
    int status = cjgui_linux_window_take_clipboard(session->window, buffer,
                                                   CJGUI_LINUX_FORM_TEXT_CAPACITY, &length);
    if (status == CJGUI_LINUX_CLIPBOARD_READ_PENDING) {
        free(buffer);
        return;
    }
    session->pastePending = 0;
    if (status == CJGUI_LINUX_CLIPBOARD_READ_READY) {
        (void)cjgui_linux_apply_paste(session, buffer, length);
    } else {
        fprintf(stderr, "CJGUI_LINUX_PASTE_REJECTED reason=clipboard_%s status=%d\n",
                cjgui_linux_clipboard_status_name(status), status);
        fflush(stderr);
    }
    free(buffer);
}

// 处理一次按键：命中已声明的文本代理时产生一次编辑意图（整值 + 增量）。
static void cjgui_linux_handle_key(CjguiLinuxSession *session, const CjguiLinuxWindowEvent *event) {
    if (!session->proxy.active) {
        if (event->keySym == CJGUI_LINUX_XK_ESCAPE) {
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DISMISS_LAYER,
                                     NULL, 0, 0, (int64_t)event->modifiers, NULL);
        }
        return;
    }
    uint32_t start16 = session->proxy.selectionStart16;
    uint32_t end16 = session->proxy.selectionEnd16;
    if (start16 > end16) { uint32_t swap = start16; start16 = end16; end16 = swap; }
    const char *current = session->proxy.value ? session->proxy.value : "";
    size_t length = strlen(current);
    // 系统剪贴板：复制/粘贴走与打字同一条编辑路径（同一份 TEXT_RANGE_CHANGED），
    // 不另造一套 Linux 剪贴板状态。选区的字节范围由代理的 UTF-16 选区换算。
    if ((event->modifiers & CJGUI_LINUX_MOD_CONTROL) && !(event->modifiers & CJGUI_LINUX_MOD_SHIFT)) {
        if (event->keySym == 0x0063u /* c */) {
            size_t from = cjgui_linux_byte_offset_for_utf16(current, length, start16);
            size_t to = cjgui_linux_byte_offset_for_utf16(current, length, end16);
            if (to > from) {
                char *selected = (char *)malloc(to - from + 1u);
                if (selected) {
                    memcpy(selected, current + from, to - from);
                    selected[to - from] = '\0';
                    (void)cjgui_linux_window_set_clipboard(session->window, selected, to - from);
                    free(selected);
                }
            }
            return;
        }
        if (event->keySym == 0x0061u /* a */) {
            uint32_t units = cjgui_linux_utf16_length(current, length);
            session->proxy.selectionStart16 = 0u;
            session->proxy.selectionEnd16 = units;
            // 选区变化本身也要上报，否则共同层不知道代理选区已经改了。
            CjguiLinuxNodeSlot routing;
            memset(&routing, 0, sizeof(routing));
            routing.node.nodeId = session->proxy.nodeId;
            routing.node.projectionVersion = session->accepted.valid ? session->accepted.projectionVersion
                                                                    : session->proxy.sceneVersion;
            routing.node.resourceId = session->proxy.resourceId;
            routing.node.nodeKind = session->proxy.nodeKind;
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                     &routing, 0, 0, (int64_t)event->modifiers, NULL);
            uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
            session->pending[index].event.selectionStart = 0u;
            session->pending[index].event.selectionEnd = units;
            session->pending[index].event.bindingEpoch = session->proxy.bindingEpoch;
            return;
        }
        if (event->keySym == 0x0076u /* v */) {
            // 异步：只发起请求，继续泵键鼠/关闭；SelectionNotify 到达后由
            // clipboard_poll 以一笔范围编辑落字。超限/不支持在代理前具名拒绝。
            if (session->pastePending) return;
            int status = cjgui_linux_window_request_clipboard(session->window);
            if (status != CJGUI_LINUX_WINDOW_OK) {
                fprintf(stderr, "CJGUI_LINUX_PASTE_REJECTED reason=request_status_%d\n", status);
                return;
            }
            session->pastePending = 1;
            session->pasteDeadlineMs = cjgui_linux_now_ns() / 1000000u + 2000u;
            cjgui_linux_clipboard_poll(session);   // 自己是 owner 或没有 owner 时立即完成
            return;
        }
        if (event->keySym == 0x0078u /* x */) {
            // Cut = 复制选区 + 同一笔范围编辑删除；不是两套剪贴板/编辑状态。
            size_t from = cjgui_linux_byte_offset_for_utf16(current, length, start16);
            size_t to = cjgui_linux_byte_offset_for_utf16(current, length, end16);
            if (to > from) {
                (void)cjgui_linux_window_set_clipboard(session->window, current + from, to - from);
                (void)cjgui_linux_emit_text_edit(session, start16, end16 - start16, "");
            }
            return;
        }
    }
    const char *inserted = NULL;
    switch (event->keySym) {
        case CJGUI_LINUX_XK_BACKSPACE:
            if (start16 == end16) {
                if (start16 == 0u) return;
                start16 -= 1u;
            }
            inserted = "";
            break;
        case CJGUI_LINUX_XK_DELETE:
            if (start16 == end16) {
                if (end16 >= cjgui_linux_utf16_length(current, length)) return;
                end16 += 1u;
            }
            inserted = "";
            break;
        case CJGUI_LINUX_XK_RETURN:
            if (session->proxy.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) return;
            inserted = "\n";
            break;
        // 带 Shift 的方向/首尾键扩展选区（锚点留在原处），不带 Shift 时移动插入点。
        // 选择与替换走同一条代理路径：选中后打字就是替换，不另造一套状态。
        case CJGUI_LINUX_XK_LEFT:
            if (event->modifiers & CJGUI_LINUX_MOD_SHIFT) {
                session->proxy.selectionEnd16 = start16 > 0u ? start16 - 1u : 0u;
            } else if (start16 > 0u) {
                session->proxy.selectionStart16 = start16 - 1u;
                session->proxy.selectionEnd16 = start16 - 1u;
            }
            return;
        case CJGUI_LINUX_XK_RIGHT: {
            uint32_t units = cjgui_linux_utf16_length(current, length);
            if (event->modifiers & CJGUI_LINUX_MOD_SHIFT) {
                session->proxy.selectionEnd16 = end16 < units ? end16 + 1u : units;
            } else if (end16 < units) {
                session->proxy.selectionStart16 = end16 + 1u;
                session->proxy.selectionEnd16 = end16 + 1u;
            }
            return;
        }
        case CJGUI_LINUX_XK_HOME:
            if (event->modifiers & CJGUI_LINUX_MOD_SHIFT) {
                session->proxy.selectionEnd16 = 0u;
            } else {
                session->proxy.selectionStart16 = 0u;
                session->proxy.selectionEnd16 = 0u;
            }
            return;
        case CJGUI_LINUX_XK_END: {
            uint32_t units = cjgui_linux_utf16_length(current, length);
            if (event->modifiers & CJGUI_LINUX_MOD_SHIFT) {
                session->proxy.selectionEnd16 = units;
            } else {
                session->proxy.selectionStart16 = units;
                session->proxy.selectionEnd16 = units;
            }
            return;
        }
        default:
            if (event->utf8Length == 0u) return;
            // 一次按键查找可以带多个字符（输入法无预编辑提交、组合/死键）；
            // 直接借用事件自己的定长载荷，不再用单字符缓冲截断。
            inserted = event->utf8;
            break;
    }
    uint32_t replaceStart16 = start16;
    uint32_t replaceLength16 = end16 - start16;
    (void)cjgui_linux_emit_text_edit(session, replaceStart16, replaceLength16, inserted);
}

static void cjgui_linux_handle_window_event(CjguiLinuxSession *session, const CjguiLinuxWindowEvent *event) {
    switch (event->kind) {
        case CJGUI_LINUX_WINDOW_EVENT_CLOSE:
            session->exitRequested = 1;
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_CLOSE_REQUESTED, NULL, 0, 0, 0, NULL);
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_APPLICATION_EXIT_REQUESTED, NULL, 0, 0, 0, NULL);
            break;
        case CJGUI_LINUX_WINDOW_EVENT_RESIZE: {
            uint32_t width = (uint32_t)(event->x > 0.0 ? event->x : 0.0);
            uint32_t height = (uint32_t)(event->y > 0.0 ? event->y : 0.0);
            session->requestedWidth = width;
            session->requestedHeight = height;
            (void)cjgui_linux_gpu_resize(session->gpu, width, height);
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED, NULL,
                                     (int64_t)width, (int64_t)height, 0, NULL);
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN: {
            CjguiLinuxNodeSlot *slot = cjgui_linux_hit_test(session, event->x, event->y);
            session->pointerDown = 1;
            session->pointerNodeId = slot ? slot->node.nodeId : 0u;
            session->pointerResourceId = slot ? slot->node.resourceId : 0;
            session->pointerNodeKind = slot ? slot->node.nodeKind : 0u;
            CjguiInternalRendererPointerEventGeometry geometry;
            cjgui_linux_capture_pointer_geometry(session, slot, event->x, event->y, &geometry);
            if (slot) {
                cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN,
                                                  slot, (int64_t)event->x, (int64_t)event->y,
                                                  (int64_t)event->modifiers, NULL, &geometry);
                if (event->button == CJGUI_LINUX_BUTTON_RIGHT) {
                    cjgui_linux_pending_push_geometry(
                        session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_CONTEXT_MENU_REQUEST, slot,
                        (int64_t)event->x, (int64_t)event->y, (int64_t)event->modifiers, NULL, &geometry);
                } else {
                    cjgui_linux_pending_push_geometry(session,
                                                      CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_BEGIN, slot,
                                                      (int64_t)event->x, (int64_t)event->y,
                                                      (int64_t)event->modifiers, NULL, &geometry);
                }
            }
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_POINTER_UP: {
            CjguiLinuxNodeSlot *slot = cjgui_linux_hit_test(session, event->x, event->y);
            int sameNode = slot && session->pointerDown && slot->node.nodeId == session->pointerNodeId;
            CjguiInternalRendererPointerEventGeometry geometry;
            cjgui_linux_capture_pointer_geometry(session, slot, event->x, event->y, &geometry);
            if (slot) {
                cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END,
                                                  slot, (int64_t)event->x, (int64_t)event->y,
                                                  (int64_t)event->modifiers, NULL, &geometry);
                cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_END,
                                                  slot, (int64_t)event->x, (int64_t)event->y,
                                                  (int64_t)event->modifiers, NULL, &geometry);
                // 只有"按下与抬起落在同一节点"才算激活：短命的鼠标路由留在 native，
                // 语义判决仍归共同层。
                if (sameNode && event->button == CJGUI_LINUX_BUTTON_LEFT) {
                    cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE,
                                                      slot, (int64_t)event->x, (int64_t)event->y,
                                                      (int64_t)event->modifiers, NULL, &geometry);
                }
            }
            session->pointerDown = 0;
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE: {
            if (!session->pointerDown) break;   // 悬停阶段本阶段不产生共同层意图
            CjguiLinuxNodeSlot *slot = cjgui_linux_hit_test(session, event->x, event->y);
            CjguiInternalRendererPointerEventGeometry geometry;
            cjgui_linux_capture_pointer_geometry(session, slot, event->x, event->y, &geometry);
            cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE,
                                              slot, (int64_t)event->x, (int64_t)event->y,
                                              (int64_t)event->modifiers, NULL, &geometry);
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_POINTER_LEAVE:
            if (session->pointerDown) {
                cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL, NULL,
                                         (int64_t)event->x, (int64_t)event->y, (int64_t)event->modifiers, NULL);
                session->pointerDown = 0;
            }
            break;
        case CJGUI_LINUX_WINDOW_EVENT_WHEEL: {
            CjguiLinuxNodeSlot *slot = cjgui_linux_wheel_target(session, event->x, event->y);
            CjguiInternalRendererPointerEventGeometry geometry;
            cjgui_linux_capture_pointer_geometry(session, slot, event->x, event->y, &geometry);
            // 滚轮增量必须走 form_event_text 的**可解析载体**：共同层用
            // cjguiParseWheelDelta 解析它（composable_ui_wheel.cj:82），格式是
            //   cjgui-wheel-v1|<x>|<y>|<precise 0|1>|<phase>|<momentum>
            // 6 段、≤96 字符，phase/momentum 是 0..63 的十进制。
            // 放在 pointerX/Y 里不会被解析（那是历史遗留的误传位置）。
            char carrier[96];
            snprintf(carrier, sizeof(carrier), "cjgui-wheel-v1|%.3f|%.3f|0|0|0", event->scrollX, event->scrollY);
            cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL, slot,
                                              0, 0, (int64_t)event->modifiers, carrier, &geometry);
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_KEY_DOWN:
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_ABI key_down sym=0x%x utf8=%u proxy=%d\n", event->keySym,
                        event->utf8Length, session->proxy.active);
            }
            if (event->keyCode != 0u || event->utf8Length > 0u) cjgui_linux_handle_key(session, event);
            break;
        case CJGUI_LINUX_WINDOW_EVENT_FOCUS_IN:
            session->windowAppActive = 1;
            session->windowKey = 1;
            break;
        case CJGUI_LINUX_WINDOW_EVENT_FOCUS_OUT:
            session->windowKey = 0;
            break;
        case CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_UPDATE:
            (void)cjgui_linux_emit_composition(session, CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE,
                                               event->utf8, event->compositionCaret16);
            break;
        case CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_COMMIT:
            // 提交文本一次进入既有 owner 路径；被 IME 消费的按键本身没有普通事件。
            (void)cjgui_linux_emit_composition(session, CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT,
                                               event->utf8, 0u);
            break;
        case CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_CANCEL:
            (void)cjgui_linux_emit_composition(session, CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_CANCEL,
                                               NULL, 0u);
            break;
        default:
            break;
    }
}

static CjguiInternalRendererStatus cjgui_linux_pump_translated(CjguiLinuxSession *session, uint32_t timeoutMs,
                                                              CjguiInternalRendererEvent *outEvent,
                                                              uint64_t *outIdleWaitNs) {
    uint64_t started = cjgui_linux_now_ns();
    uint64_t idle = 0u;
    while (session->pendingCount == 0u) {
        if (g_stopRequested) {
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_APPLICATION_EXIT_REQUESTED, NULL, 0, 0, 0, NULL);
            break;
        }
        // 有界承载：每个 X11 事件最多产生 PER_EVENT 条意图，先按上界预留槽位
        // 再读事件；没有空位就停在这里，事件仍留在 X11 队列里，不清队列、不丢。
        if (cjgui_linux_pending_free(session) < CJGUI_LINUX_PENDING_PER_EVENT) break;
        CjguiLinuxWindowEvent event;
        uint32_t count = 0u;
        uint64_t waitStart = cjgui_linux_now_ns();
        int status = cjgui_linux_window_pump(session->window, &event, 1u, timeoutMs, &count);
        idle += cjgui_linux_now_ns() - waitStart;
        if (status != 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        // 剪贴板结果沿同一个泵结算；没结果时继续正常等待键鼠/关闭事件。
        cjgui_linux_clipboard_poll(session);
        if (count == 0u) {
            if (outIdleWaitNs) *outIdleWaitNs = idle;
            if (outEvent) memset(outEvent, 0, sizeof(*outEvent));
            return CJGUI_INTERNAL_RENDERER_OK;   // READY NONE：超时，无事件
        }
        cjgui_linux_handle_window_event(session, &event);
        timeoutMs = 0u;   // 已经拿到过事件，后续不再阻塞
    }
    if (outEvent) {
        uint32_t index = session->pendingHead;
        if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_PUMP kind=%u queued=%u\n",
                    session->pending[index].event.kind, session->pendingCount);
        }
        *outEvent = session->pending[index].event;
        // 逐事件载荷：命中几何与 range 三段正文随这条事件一起出队，
        // 之后的 getter 交出的就是这条事件自己的捕获，而不是"最近一次生产"。
        if (session->pending[index].hasGeometry) {
            session->lastGeometry = session->pending[index].geometry;
        } else {
            memset(&session->lastGeometry, 0, sizeof(session->lastGeometry));
        }
        if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_PUMP_GEOM kind=%u ev_node=%llu ev_proj=%llu geom_present=%u geom_node=%llu geom_proj=%llu\n",
                    session->pending[index].event.kind,
                    (unsigned long long)session->pending[index].event.nodeId,
                    (unsigned long long)session->pending[index].event.projectionVersion,
                    session->pending[index].hasGeometry,
                    (unsigned long long)session->lastGeometry.nodeId,
                    (unsigned long long)session->lastGeometry.projectionVersion);
        }
        session->pending[index].hasGeometry = 0;
        if (session->pending[index].hasRangeIntent) {
            cjgui_linux_strfree(&session->rangePreBody);
            cjgui_linux_strfree(&session->rangePostBody);
            cjgui_linux_strfree(&session->rangeReplacement);
            session->rangeIntent = session->pending[index].rangeIntent;
            session->rangePreBody = session->pending[index].rangePreBody;
            session->rangePostBody = session->pending[index].rangePostBody;
            session->rangeReplacement = session->pending[index].rangeReplacement;
            session->pending[index].rangePreBody = NULL;
            session->pending[index].rangePostBody = NULL;
            session->pending[index].rangeReplacement = NULL;
            session->pending[index].hasRangeIntent = 0;
        }
        if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_RETURN kind=%u node=%llu epoch=%llu proj=%llu\n", outEvent->kind,
                    (unsigned long long)outEvent->nodeId, (unsigned long long)outEvent->bindingEpoch,
                    (unsigned long long)outEvent->projectionVersion);
        }
        session->formText[0] = '\0';
        if (session->pending[index].hasText) {
            snprintf(session->formText, sizeof(session->formText), "%s", session->pending[index].text);
        }
        session->pendingHead = (session->pendingHead + 1u) % CJGUI_LINUX_PENDING_EVENTS;
        session->pendingCount -= 1u;
    }
    if (outIdleWaitNs) *outIdleWaitNs = idle;
    (void)started;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_pump_event(uint64_t sessionToken, uint32_t timeoutMs,
                                                              CjguiInternalRendererEvent *outEvent) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return cjgui_linux_pump_translated(session, timeoutMs, outEvent, NULL);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pump_event_measured(uint64_t sessionToken, uint32_t timeoutMs,
                                                                       CjguiInternalRendererEvent *outEvent,
                                                                       uint64_t *outIdleWaitNs) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return cjgui_linux_pump_translated(session, timeoutMs, outEvent, outIdleWaitNs);
}

CjguiInternalRendererStatus cjgui_internal_renderer_pumped_pointer_geometry(
    uint64_t sessionToken, CjguiInternalRendererPointerEventGeometry *outGeometry) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outGeometry = session->lastGeometry;
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint32_t cjgui_internal_renderer_owner_pump_has_unconsumed_input(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return 0u;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_HAS_INPUT queued=%u\n", session->pendingCount);
    }
    return session->pendingCount > 0u ? 1u : 0u;
}

const char *cjgui_internal_renderer_form_event_text(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return "";
    return session->formText;
}

CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(uint64_t sessionToken, uint64_t nodeId) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI focus_composable_node\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->accepted.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        if (session->accepted.slots[i].node.nodeId == nodeId) {
            session->pointerNodeId = nodeId;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_owned_text_session(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t bindingEpoch,
    uint32_t enabled) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_composable_owned_text_session\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_DECLARE_TEXT enabled=%u node=%llu epoch=%llu\n", enabled,
                (unsigned long long)nodeId, (unsigned long long)bindingEpoch);
    }
    if (!enabled) {
        memset(&session->proxy, 0, sizeof(session->proxy));
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    // 声明本身不携带值：真正的值/选区由 restore_composable_selection 每轮推来，
    // 这里只记住身份与绑定代。
    session->proxy.nodeId = nodeId;
    session->proxy.resourceId = resourceId;
    session->proxy.nodeKind = nodeKind;
    session->proxy.bindingEpoch = bindingEpoch;
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_set_composable_range_edit_delta(uint64_t sessionToken, int32_t enabled) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_composable_range_edit_delta\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return (int32_t)CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    session->rangeEditDeltaEnabled = enabled ? 1 : 0;
    return (int32_t)CJGUI_INTERNAL_RENDERER_OK;
}

static int cjgui_linux_proxy_matches(CjguiLinuxSession *session, uint64_t nodeId, int64_t resourceId,
                                     uint32_t nodeKind, const char *expectedValue) {
    if (!session->proxy.active) return 0;
    if (session->proxy.nodeId != nodeId) return 0;
    if (resourceId >= 0 && session->proxy.resourceId != resourceId) return 0;
    if (nodeKind != 0u && session->proxy.nodeKind != nodeKind) return 0;
    if (expectedValue) {
        const char *current = session->proxy.value ? session->proxy.value : "";
        if (strcmp(current, expectedValue) != 0) return 0;
    }
    return 1;
}

CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *expectedValue, uint32_t selectionStart, uint32_t selectionEnd, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI restore_composable_selection\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!expectedValue) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    // nodeKind == 0 表示调用方没有这个形参（install_owned_source_selection 就没有），
    // 此时必须沿用 set_composable_owned_text_session 已声明的种类，**不能用 0 覆盖**：
    // 覆盖后 recover_active_text_proxy 的身份判据永远不匹配，owner 拒绝后的回滚
    // 会静默失效（实测症状：CJGUI_LINUX_RECOVER want kind=10 | have kind=0）。
    uint32_t effectiveKind = nodeKind != 0u ? nodeKind : session->proxy.nodeKind;
    if (!session->proxy.active || session->proxy.nodeId != nodeId) {
        uint64_t retainedEpoch = session->proxy.bindingEpoch;
        memset(&session->proxy, 0, sizeof(session->proxy));
        session->proxy.bindingEpoch = retainedEpoch;
        session->proxy.active = 1;
        session->proxy.nodeId = nodeId;
        session->proxy.resourceId = resourceId;
        session->proxy.nodeKind = effectiveKind;
        session->proxy.value = cjgui_linux_strdup(expectedValue);
    } else if (!cjgui_linux_proxy_matches(session, nodeId, resourceId, effectiveKind, NULL)) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    } else {
        cjgui_linux_replace(&session->proxy.value, expectedValue);
    }
    session->proxy.sceneVersion = sceneVersion;
    uint32_t units = cjgui_linux_utf16_length(expectedValue, strlen(expectedValue));
    if (selectionStart > units) selectionStart = units;
    if (selectionEnd > units) selectionEnd = units;
    if (selectionEnd < selectionStart) selectionEnd = selectionStart;
    session->proxy.selectionStart16 = selectionStart;
    session->proxy.selectionEnd16 = selectionEnd;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_RESTORE_SEL node=%llu epoch=%llu sel=%u:%u\n", (unsigned long long)nodeId,
                (unsigned long long)session->proxy.bindingEpoch, selectionStart, selectionEnd);
    }
    if (outSelectionStart) *outSelectionStart = selectionStart;
    if (outSelectionEnd) *outSelectionEnd = selectionEnd;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_read_composable_selection(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *expectedValue, uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI read_composable_selection\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!cjgui_linux_proxy_matches(session, nodeId, resourceId, nodeKind, expectedValue)) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    if (sceneVersion != 0u && session->proxy.sceneVersion != sceneVersion) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (outSelectionStart) *outSelectionStart = session->proxy.selectionStart16;
    if (outSelectionEnd) *outSelectionEnd = session->proxy.selectionEnd16;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_recover_active_text_proxy(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, const char *acceptedValue,
    uint32_t *outSelectionStart, uint32_t *outSelectionEnd) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!acceptedValue) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr,
                "CJGUI_LINUX_RECOVER want node=%llu res=%lld kind=%u | have active=%d node=%llu res=%lld kind=%u\n",
                (unsigned long long)nodeId, (long long)resourceId, nodeKind, session->proxy.active,
                (unsigned long long)session->proxy.nodeId, (long long)session->proxy.resourceId,
                session->proxy.nodeKind);
    }
    if (!cjgui_linux_proxy_matches(session, nodeId, resourceId, nodeKind, NULL)) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    cjgui_linux_replace(&session->proxy.value, acceptedValue);
    uint32_t units = cjgui_linux_utf16_length(acceptedValue, strlen(acceptedValue));
    if (session->proxy.selectionStart16 > units) session->proxy.selectionStart16 = units;
    if (session->proxy.selectionEnd16 > units) session->proxy.selectionEnd16 = units;
    if (outSelectionStart) *outSelectionStart = session->proxy.selectionStart16;
    if (outSelectionEnd) *outSelectionEnd = session->proxy.selectionEnd16;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_install_owned_source_selection(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint64_t sceneVersion, uint64_t bindingEpoch,
    uint64_t requestId, uint64_t deadlineNs, const char *expectedValue, uint32_t selectionStart,
    uint32_t selectionEnd, uint32_t *outSelectionStart, uint32_t *outSelectionEnd, uint8_t *outDeferred) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI install_owned_source_selection\n");
    (void)bindingEpoch;
    (void)requestId;
    (void)deadlineNs;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_restore_composable_selection(
        sessionToken, nodeId, resourceId, 0u, sceneVersion, expectedValue, selectionStart, selectionEnd,
        outSelectionStart, outSelectionEnd);
    if (outDeferred) *outDeferred = 0u;   // 同步完成，不推迟
    return status;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_source_install_gate(uint64_t sessionToken,
                                                                           uint64_t bindingEpoch,
                                                                           uint64_t requestId, uint8_t pending) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_source_install_gate\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    session->sourceGatePending = pending ? 1 : 0;
    session->sourceGateEpoch = bindingEpoch;
    session->sourceGateRequest = requestId;
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint8_t cjgui_internal_renderer_source_install_pending_scalar(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return 0u;
    return (uint8_t)(session->sourceGatePending ? 1u : 0u);
}

void cjgui_linux_session_range_intent_view(uint64_t token, CjguiLinuxRangeIntentView *outView) {
    if (!outView) return;
    CjguiLinuxSession *session = cjgui_linux_lookup(token);
    if (!session) { memset(outView, 0, sizeof(*outView)); return; }
    *outView = session->rangeIntent;
    outView->preBody = session->rangePreBody ? session->rangePreBody : "";
    outView->replacement = session->rangeReplacement ? session->rangeReplacement : "";
    outView->postBody = session->rangePostBody ? session->rangePostBody : "";
    outView->sceneVersion = session->accepted.valid ? session->accepted.projectionVersion : 0u;
    if (!outView->preBody || !outView->postBody) outView->present = 0;
}

// ---------------------------------------------------------------- 数据搬运事件载荷

// 这几个 getter 读的是"最近一次事件携带的值载荷"，契约是"借用到下一次事件泵"。
// 本阶段 Linux 不从 X11 selection 产生框架级 transfer 事件，所以它们返回的是
// "没有事件"的真实答案（空串 / 0 / 空字节），而不是对某个真实事件的假否定。
const char *cjgui_internal_renderer_data_transfer_event_format(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return "";
    return session->transferFormat;
}

const char *cjgui_internal_renderer_data_transfer_event_source_kind(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return "";
    return session->transferSourceKind;
}

const char *cjgui_internal_renderer_data_transfer_event_source_identity(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return "";
    return session->transferSourceIdentity;
}

int64_t cjgui_internal_renderer_data_transfer_event_source_id(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return 0;
    return session->transferSourceId;
}

int64_t cjgui_internal_renderer_data_transfer_event_expected_owner_version(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return 0;
    return session->transferExpectedOwnerVersion;
}

uint64_t cjgui_internal_renderer_data_transfer_event_delivery_ordinal(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return 0u;
    return session->transferDeliveryOrdinal;
}

uint32_t cjgui_internal_renderer_data_transfer_event_binary_size(uint64_t sessionToken, uint64_t eventId) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session || eventId == 0u || eventId != session->transferEventId) return 0u;
    return session->transferByteLength;
}

CjguiInternalRendererStatus cjgui_internal_renderer_copy_data_transfer_event_binary(
    uint64_t sessionToken, uint64_t eventId, uint8_t *outBytes, uint32_t capacity) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outBytes) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (eventId == 0u || eventId != session->transferEventId) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    if (capacity < session->transferByteLength) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    memcpy(outBytes, session->transferBytes, session->transferByteLength);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 指针捕获取消

// 三个取消入口都作用在同一份短命路由状态上：忘掉按下目标并产生一条 CANCEL，
// 让后续 ButtonRelease 不可能再激活。这是真状态转换，不是具名拒绝。
static CjguiInternalRendererStatus cjgui_linux_cancel_pointer_capture(CjguiLinuxSession *session) {
    if (!session->pointerDown) return CJGUI_INTERNAL_RENDERER_OK;
    session->pointerDown = 0;
    session->pointerNodeId = 0u;
    session->pointerResourceId = 0;
    session->pointerNodeKind = 0u;
    cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL, NULL, 0, 0, 0, NULL);
    cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_PRESS_CANCEL, NULL, 0, 0, 0, NULL);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture(uint64_t sessionToken) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return cjgui_linux_cancel_pointer_capture(session);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(uint64_t sessionToken,
                                                                                            uint64_t gestureEpoch) {
    (void)gestureEpoch;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return cjgui_linux_cancel_pointer_capture(session);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
    uint64_t sessionToken, uint64_t appInstance, uint64_t componentInstance, uint64_t surfaceGeneration,
    int64_t pointerId, uint64_t gestureEpoch) {
    (void)appInstance;
    (void)componentInstance;
    (void)surfaceGeneration;
    (void)pointerId;
    (void)gestureEpoch;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return cjgui_linux_cancel_pointer_capture(session);
}

// ---------------------------------------------------------------- 诊断读取器

// 这四个读取器的消费方把它们当**真实数字**用（例如 composable_ui_window.cj 的
// readWorkloadAttemptCounts 用 nodeWriteCount 之类算"做功增量基线"），所以它们
// 必须由持有场景/帧/计数事实的会话层实现，而不是让长尾层返回全 0 冒充。
CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_workload(
    uint64_t sessionToken, CjguiInternalRendererDiagnosticWorkload *outWorkload) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outWorkload) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outWorkload, 0, sizeof(*outWorkload));
    outWorkload->sceneVersion = session->accepted.projectionVersion;
    outWorkload->frameIndex = session->frameIndex;
    outWorkload->nodeWriteCount = session->nodeWriteCount;
    outWorkload->nodeCloneCount = session->nodeCloneCount;
    outWorkload->nodeAllocationCount = session->nodeAllocationCount;
    outWorkload->textLayoutPreparationCount = session->textLayoutPreparationCount;
    outWorkload->imageDecodeStartCount = 0u;   // 本阶段不做图片解码
    uint32_t glyphs = 0u, atlasBytes = 0u;
    cjgui_linux_text_stats(session->text, &glyphs, &atlasBytes);
    outWorkload->reusableResourceBytes = atlasBytes;
    outWorkload->textRasterCount = session->textRasterCount;
    outWorkload->textRasterBytes = atlasBytes;
    outWorkload->textUploadCount = session->textUploadCount;
    outWorkload->textUploadBytes = session->textUploadBytes;
    outWorkload->textTextureLiveBytes = atlasBytes;
    outWorkload->textCandidatePeakBytes = atlasBytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_resources(
    uint64_t sessionToken, CjguiInternalRendererDiagnosticResources *outResources) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outResources) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outResources, 0, sizeof(*outResources));
    outResources->sceneVersion = session->accepted.projectionVersion;
    outResources->frameIndex = session->frameIndex;
    // 本阶段没有独立 effect 资源与 overlay 上屏，这两项保持 0 就是真实值。
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_timing(
    uint64_t sessionToken, CjguiInternalRendererDiagnosticTiming *outTiming) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outTiming) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    memset(outTiming, 0, sizeof(*outTiming));
    outTiming->sceneVersion = session->accepted.projectionVersion;
    outTiming->frameIndex = session->frameIndex;
    outTiming->enabled = session->diagnosticTimingEnabled ? 1u : 0u;
    outTiming->clockAvailable = 1u;   // CLOCK_MONOTONIC 一直可用
    outTiming->positionQueryCount = session->textLayoutPreparationCount;
    outTiming->readCount = session->frameIndex;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_diagnostic_node_geometry(
    uint64_t sessionToken, uint32_t nodeIndex, CjguiInternalRendererDiagnosticNodeGeometry *outGeometry) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outGeometry) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!session->accepted.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (nodeIndex >= session->accepted.nodeCount) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CjguiLinuxNodeSlot *slot = &session->accepted.slots[nodeIndex];
    memset(outGeometry, 0, sizeof(*outGeometry));
    outGeometry->sceneVersion = session->accepted.projectionVersion;
    outGeometry->frameIndex = session->frameIndex;
    outGeometry->outputX = (double)slot->node.x + cjgui_linux_slot_translate_x(slot);
    outGeometry->outputY = (double)slot->node.y + cjgui_linux_slot_translate_y(slot);
    outGeometry->outputWidth = (double)slot->node.width;
    outGeometry->outputHeight = (double)slot->node.height;
    // 采样矩形与输出矩形同源：本平台没有独立的采样缓冲，不编造第二组数字。
    outGeometry->sampleX = outGeometry->outputX;
    outGeometry->sampleY = outGeometry->outputY;
    outGeometry->sampleWidth = outGeometry->outputWidth;
    outGeometry->sampleHeight = outGeometry->outputHeight;
    outGeometry->flags = 1u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 文字命中

// 点 -> 字节偏移。x/y 是窗口内容逻辑点，与布局同一坐标系；返回的偏移是
// **显示字节**（UTF-8 字节偏移），affinity 0=auto（本实现落点即自动吸附结果）。
// 版本不符或节点不在都必须具名拒绝，绝不静默给 0。
CjguiInternalRendererStatus cjgui_internal_renderer_hit_test_composable_text(
    uint64_t sessionToken, uint64_t nodeId, double x, double y, uint64_t expectedSceneVersion,
    uint32_t *outByteOffset, uint32_t *outAffinity) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->accepted.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    if (expectedSceneVersion != 0u && expectedSceneVersion != session->accepted.projectionVersion) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    CjguiLinuxNodeSlot *slot = NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        if (session->accepted.slots[i].node.nodeId == nodeId) { slot = &session->accepted.slots[i]; break; }
    }
    if (!slot) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    const char *body = cjgui_linux_node_body(slot);
    if (!body || !body[0]) return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;

    double localX = x - (double)slot->node.x - cjgui_linux_slot_translate_x(slot);
    double localY = y - (double)slot->node.y - cjgui_linux_slot_translate_y(slot);
    double fontSize = slot->node.fontSize > 0.0 ? slot->node.fontSize : 14.0;
    double maxWidth = (double)slot->node.width - 12.0;
    if (maxWidth <= 0.0) maxWidth = 0.0;
    size_t length = strlen(body);

    uint32_t lineCount = 0u;
    if (cjgui_linux_text_line_count(session->text, body, length, fontSize, slot->node.fontWeight,
                                    slot->node.fontFamily, maxWidth, &lineCount) != CJGUI_LINUX_TEXT_OK ||
        lineCount == 0u) {
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    uint32_t lineIndex = 0u;
    double lineTop = 0.0, lineHeight = 0.0, lineWidth = 0.0, lineX = 0.0;
    size_t lineStart = 0u, lineEnd = 0u;
    for (uint32_t index = 0u; index < lineCount; index += 1u) {
        double originX = 0.0, originY = 0.0, width = 0.0, height = 0.0;
        size_t startByte = 0u, endByte = 0u;
        if (cjgui_linux_text_line_rect(session->text, body, length, fontSize, slot->node.fontWeight,
                                       slot->node.fontFamily, maxWidth, index, &originX, &originY, &width,
                                       &height, &startByte, &endByte) != CJGUI_LINUX_TEXT_OK) {
            return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
        }
        lineIndex = index;
        lineTop = originY;
        lineHeight = height;
        lineWidth = width;
        lineX = originX;
        lineStart = startByte;
        lineEnd = endByte;
        if (localY < originY + height) break;
    }
    (void)lineTop;
    (void)lineHeight;
    (void)lineX;
    // 在行内按插入点二分：最后一个 x <= 目标 x 的簇边界。
    size_t best = lineStart;
    size_t cursor = lineStart;
    while (cursor <= lineEnd) {
        double caretX = 0.0, top = 0.0, height = 0.0;
        uint32_t index = 0u;
        size_t startByte = 0u, endByte = 0u;
        if (cjgui_linux_text_caret_position(session->text, body, length, fontSize, slot->node.fontWeight,
                                            slot->node.fontFamily, maxWidth, cursor, &caretX, &top, &height,
                                            &index, &startByte, &endByte) != CJGUI_LINUX_TEXT_OK) {
            break;
        }
        if (caretX <= localX) {
            best = cursor;
        } else {
            break;
        }
        if (cursor >= lineEnd) break;
        cursor += 1u;
        while (cursor < lineEnd && ((unsigned char)body[cursor] & 0xC0u) == 0x80u) cursor += 1u;
    }
    (void)lineWidth;
    (void)lineIndex;
    if (outByteOffset) *outByteOffset = (uint32_t)best;
    if (outAffinity) *outAffinity = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}
