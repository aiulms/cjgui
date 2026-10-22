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
#include <stdatomic.h>

#include "cjgui_internal_renderer.h"
#include "cjgui_linux_window.h"
#include "cjgui_linux_vulkan.h"
#include "cjgui_linux_text.h"
#include "cjgui_linux_aux.h"
#include "cjgui_linux_services.h"
#include "cjgui_linux_installed_range.h"
#include "cjgui_linux_image.h"

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

// A process-wide set of windows served by the serialized owner loop. Every
// window opened by this process registers here, so one owner wait covers all
// of them instead of pinning the last window created. notify may run on the
// transport thread, so both the list and the wake calls are serialized by the
// same lock that guards unbind-before-destroy.
#define CJGUI_LINUX_OWNER_WAKE_WINDOW_CAP 8u
static CjguiLinuxWindow *g_ownerWakeWindows[CJGUI_LINUX_OWNER_WAKE_WINDOW_CAP];
static uint32_t g_ownerWakeWindowCount = 0u;
static _Atomic uint64_t g_ownerWorkRevision = 0u;
static pthread_mutex_t g_ownerWakeLock = PTHREAD_MUTEX_INITIALIZER;

static void cjgui_linux_owner_bind_window(CjguiLinuxWindow *window) {
    if (window == NULL) return;
    pthread_mutex_lock(&g_ownerWakeLock);
    for (uint32_t i = 0u; i < g_ownerWakeWindowCount; i += 1u) {
        if (g_ownerWakeWindows[i] == window) {
            pthread_mutex_unlock(&g_ownerWakeLock);
            return;
        }
    }
    if (g_ownerWakeWindowCount < CJGUI_LINUX_OWNER_WAKE_WINDOW_CAP) {
        g_ownerWakeWindows[g_ownerWakeWindowCount] = window;
        g_ownerWakeWindowCount += 1u;
    }
    pthread_mutex_unlock(&g_ownerWakeLock);
}

static void cjgui_linux_owner_unbind_window(CjguiLinuxWindow *window) {
    if (window == NULL) return;
    pthread_mutex_lock(&g_ownerWakeLock);
    for (uint32_t i = 0u; i < g_ownerWakeWindowCount; i += 1u) {
        if (g_ownerWakeWindows[i] == window) {
            for (uint32_t j = i + 1u; j < g_ownerWakeWindowCount; j += 1u) {
                g_ownerWakeWindows[j - 1u] = g_ownerWakeWindows[j];
            }
            g_ownerWakeWindowCount -= 1u;
            g_ownerWakeWindows[g_ownerWakeWindowCount] = NULL;
            break;
        }
    }
    pthread_mutex_unlock(&g_ownerWakeLock);
}

uint64_t cjgui_internal_renderer_owner_work_revision_linux(void) {
    return atomic_load_explicit(&g_ownerWorkRevision, memory_order_acquire);
}

void cjgui_internal_renderer_owner_notify_work_linux(void) {
    atomic_fetch_add_explicit(&g_ownerWorkRevision, 1u, memory_order_acq_rel);
    pthread_mutex_lock(&g_ownerWakeLock);
    for (uint32_t i = 0u; i < g_ownerWakeWindowCount; i += 1u) {
        cjgui_linux_window_wake(g_ownerWakeWindows[i]);
    }
    pthread_mutex_unlock(&g_ownerWakeLock);
}

static int cjgui_linux_owner_wait(uint64_t observedRevision, uint64_t absoluteDeadlineNs,
                                  uint64_t *outIdleWaitNs) {
    const uint64_t started = cjgui_linux_now_ns();
    if (outIdleWaitNs != NULL) *outIdleWaitNs = 0u;
    for (;;) {
        if (atomic_load_explicit(&g_ownerWorkRevision, memory_order_acquire) != observedRevision) break;
        if (cjgui_linux_now_ns() >= absoluteDeadlineNs) break;
        // Snapshot under the lock, wait outside it: notify must never block on
        // poll, and bind/unbind only happen on the owner thread.
        CjguiLinuxWindow *windows[CJGUI_LINUX_OWNER_WAKE_WINDOW_CAP];
        uint32_t count = 0u;
        pthread_mutex_lock(&g_ownerWakeLock);
        for (uint32_t i = 0u; i < g_ownerWakeWindowCount; i += 1u) {
            windows[count] = g_ownerWakeWindows[i];
            count += 1u;
        }
        pthread_mutex_unlock(&g_ownerWakeLock);
        if (count == 0u) break;
        uint64_t idle = 0u;
        (void)cjgui_linux_window_wait_ready_multi(windows, count, absoluteDeadlineNs, &idle);
        // Any readiness (X11, owner notify, or image completion) returns to the
        // caller. The next turn pumps events/refresh; sleeping through an image
        // wake would otherwise add a full idle interval to the frame.
        break;
    }
    if (outIdleWaitNs != NULL) *outIdleWaitNs = cjgui_linux_now_ns() - started;
    return 0;
}

int32_t cjgui_internal_renderer_owner_wait_idle_work_linux(uint64_t observedRevision, uint64_t absoluteDeadlineNs,
                                                           uint64_t *outIdleWaitNs) {
    return cjgui_linux_owner_wait(observedRevision, absoluteDeadlineNs, outIdleWaitNs);
}

int32_t cjgui_internal_renderer_owner_wait_work_linux(uint64_t observedRevision, uint64_t absoluteDeadlineNs,
                                                      uint64_t *outIdleWaitNs) {
    return cjgui_linux_owner_wait(observedRevision, absoluteDeadlineNs, outIdleWaitNs);
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
    // 1 = installed by ordinary focus from the accepted scene; 0 = owned/range
    // session. Ordinary proxies follow focus/accept reconciliation; owned
    // proxies keep their existing source/recovery contract and are never
    // downgraded or retired by that reconciliation.
    int ordinary;
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
    CjguiLinuxImageDomain *image;

    uint32_t requestedWidth;
    uint32_t requestedHeight;
    double clear[4];
    uint64_t frameIndex;
    // 视口几何推进代：只随真实尺寸变化推进。frameIndex 是提交帧号，不能
    // 当 resize 版本使用，否则共同层每帧都会误判"窗口已缩放"并重建整棵树。
    uint64_t resizeVersion;

    CjguiLinuxScene accepted;
    CjguiLinuxScene candidate;
    int preparationActive;
    uint64_t preparationId;

    CjguiLinuxActiveTextProxy proxy;
    // Keyboard focus identity. It survives a cleared text proxy so Tab can
    // leave a field for a button and Esc still knows which layer owns focus.
    int focusActive;
    uint64_t focusNodeId;
    int64_t focusResourceId;
    uint32_t focusNodeKind;
    // Real owned-binding declaration. Proxy ownership is derived from this
    // declaration, not from the restore path that happens to run: ordinary
    // modal returns and tab bookmarks also restore a selection.
    int ownedTextSessionEnabled;
    uint64_t ownedTextSessionNodeId;
    int64_t ownedTextSessionResourceId;
    uint32_t ownedTextSessionNodeKind;
    uint64_t ownedTextSessionBindingEpoch;
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
    // Left-press on an editable text node installs focus/caret directly
    // (Windows parity); the matching release must not become ACTIVATE.
    int pointerTextTarget;
    // Identity frozen at press time. A drag may only continue while the proxy
    // is still the same node/resource/kind and the same binding epoch; focus
    // switching, rebinding or removing the node must not reuse A's anchor on B.
    uint64_t pointerTextNodeId;
    int64_t pointerTextResourceId;
    uint32_t pointerTextNodeKind;
    uint64_t pointerTextBindingEpoch;
    int pointerTextAborted;
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
    // Body the preedit started on. An external owner write during composition
    // changes the accepted body; the commit must not insert its old caret into
    // that newer value.
    uint64_t compositionBaseHash;
    size_t compositionTextLength;
    // Identity frozen when the preedit starts. A terminal phase may only end
    // this target; focus/rebind/removal must never re-route it to the current
    // proxy, even when both fields carry the same body text.
    uint64_t compositionNodeId;
    int64_t compositionResourceId;
    uint32_t compositionNodeKind;
    uint64_t compositionBindingEpoch;
    uint32_t compositionCaret16;
    int compositionOwned;

    // 异步粘贴：请求发出后普通泵继续跑，结果到达再走一次范围编辑。
    int pastePending;
    uint64_t pasteDeadlineMs;

    // Platform-level source install gate（本阶段只有门状态，不做数据搬运）。
    int sourceGatePending;
    uint64_t sourceGateEpoch;
    uint64_t sourceGateRequest;

    // 输入类文本的原生拖选锚点（UTF-16）。owned 输入与普通输入同一条路径；
    // 预览类 TEXT 节点仍由共同层收 BEGIN/MOVE/END。
    uint32_t textSelectionAnchor16;

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
    // 共同层对整棵树逐节点发布（含空声明），容量必须覆盖一个完整场景；
    // 取 2 倍上界是为了容纳"已接受场景 + 准备中的候选"同时存在的两代 id。
#define CJGUI_LINUX_MAX_RUN_DECLARATIONS (CJGUI_LINUX_MAX_NODES * 2u)
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
typedef struct CjguiLinuxPaintPoint CjguiLinuxPaintPoint;

typedef struct CjguiLinuxDrawSegment {
    uint32_t firstVertex;
    uint32_t vertexCount;
    uint32_t imageSlot;   // UINT32_MAX = 字形图集
} CjguiLinuxDrawSegment;

typedef struct CjguiLinuxVertexBuilder {
    CjguiLinuxGpuVertex *vertices;
    uint32_t count;
    uint32_t capacity;
    int failed;
    // 一次绘制可能交替使用字形图集和多个图片纹理；按产生顺序分段，
    // 结算时逐段选择 draw_triangles / draw_image_triangles。分段表与字形
    // 结果缓冲都放在堆上：native 帧函数运行在共同层调用栈上，不能把
    // 几十 KB 的临时数组压进该栈。
    uint32_t desiredSlot;
    CjguiLinuxDrawSegment *segments;
    uint32_t segmentCount;
    uint32_t segmentCapacity;
    CjguiLinuxTextQuad *textQuads;
    CjguiLinuxStyledQuad *styledQuads;
    CjguiLinuxStyledSpan *styledSpans;
    // Heap-resident ping-pong buffers for plane clipping. They are reused by
    // every primitive in the frame and deliberately kept off the Cangjie
    // call stack (the same reason textQuads lives here).
    CjguiLinuxPaintPoint *clipA;
    CjguiLinuxPaintPoint *clipB;
} CjguiLinuxVertexBuilder;

static void cjgui_linux_builder_release(CjguiLinuxVertexBuilder *builder) {
    free(builder->vertices);
    free(builder->segments);
    free(builder->textQuads);
    free(builder->styledQuads);
    free(builder->styledSpans);
    free(builder->clipA);
    free(builder->clipB);
    memset(builder, 0, sizeof(*builder));
}

static int cjgui_linux_builder_touch(CjguiLinuxVertexBuilder *builder) {
    if (builder->failed) return 0;
    uint32_t last = builder->segmentCount;
    if (last > 0u && builder->segments[last - 1u].imageSlot == builder->desiredSlot) return 1;
    if (last >= builder->segmentCapacity) {
        uint32_t next = builder->segmentCapacity ? builder->segmentCapacity * 2u : 64u;
        CjguiLinuxDrawSegment *grown = (CjguiLinuxDrawSegment *)realloc(
            builder->segments, sizeof(CjguiLinuxDrawSegment) * (size_t)next);
        if (grown == NULL) {
            builder->failed = 1;
            return 0;
        }
        builder->segments = grown;
        builder->segmentCapacity = next;
    }
    builder->segments[last].firstVertex = builder->count;
    builder->segments[last].vertexCount = 0u;
    builder->segments[last].imageSlot = builder->desiredSlot;
    builder->segmentCount += 1u;
    return 1;
}

static int cjgui_linux_builder_reserve(CjguiLinuxVertexBuilder *builder, uint32_t extra) {
    if (builder->failed) return 0;
    if (!cjgui_linux_builder_touch(builder)) return 0;
    if (builder->count + extra <= builder->capacity) {
        builder->segments[builder->segmentCount - 1u].vertexCount += extra;
        return 1;
    }
    uint32_t next = builder->capacity ? builder->capacity : 4096u;
    while (next < builder->count + extra) next *= 2u;
    CjguiLinuxGpuVertex *grown = (CjguiLinuxGpuVertex *)realloc(builder->vertices, sizeof(CjguiLinuxGpuVertex) * next);
    if (!grown) { builder->failed = 1; return 0; }
    builder->vertices = grown;
    builder->capacity = next;
    builder->segments[builder->segmentCount - 1u].vertexCount += extra;
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
    double r;
    double g;
    double b;
    double a;
} CjguiLinuxPaintPoint;

// A rounded ancestor clip is an intersection of convex rounded rectangles.
// The intersection is clipped down to one convex aperture polygon and then
// applied as inward half-planes (`n·p >= d`) to every primitive of the node:
// backgrounds, glyph quads and image quads share the same aperture, so a
// rectangle can never stand in for a rounded clip.
#define CJGUI_LINUX_CLIP_POINT_CAPACITY 256u
#define CJGUI_LINUX_CLIP_PLANE_CAPACITY 192u
#define CJGUI_LINUX_RADIUS_SEGMENTS 8u

typedef struct CjguiLinuxPoint2D {
    double x;
    double y;
} CjguiLinuxPoint2D;

typedef struct CjguiLinuxClipPlane {
    double nx;
    double ny;
    double d;
} CjguiLinuxClipPlane;

typedef struct CjguiLinuxClipAperture {
    CjguiLinuxClipPlane planes[CJGUI_LINUX_CLIP_PLANE_CAPACITY];
    uint32_t count;
    int active;
    // active == 0 can mean "no rounded ancestor" or "rounded ancestors do not
    // intersect". The latter must paint nothing; callers use this bit instead
    // of treating the empty aperture as an absent clip.
    int empty;
} CjguiLinuxClipAperture;

// One convex rounded-rectangle outline. Every corner always contributes
// CJGUI_LINUX_RADIUS_SEGMENTS points, including zero-radius corners where the
// points coincide; that keeps outer/inner border rings pairable and makes the
// zero-radius case a plain rectangle.
static uint32_t cjgui_linux_rounded_outline(double x, double y, double width, double height,
                                            double topLeft, double topRight,
                                            double bottomRight, double bottomLeft,
                                            CjguiLinuxPoint2D *out, uint32_t capacity) {
    if (!(width > 0.0) || !(height > 0.0) || out == NULL) return 0u;
    double limit = fmin(width, height) * 0.5;
    double radii[4] = { topLeft, topRight, bottomRight, bottomLeft };
    for (uint32_t i = 0u; i < 4u; i += 1u) {
        if (!isfinite(radii[i]) || radii[i] < 0.0) radii[i] = 0.0;
        if (radii[i] > limit) radii[i] = limit;
    }
    int anyRadius = 0;
    for (uint32_t i = 0u; i < 4u; i += 1u) {
        if (radii[i] > 0.0) anyRadius = 1;
    }
    if (!anyRadius) {
        if (capacity < 4u) return 0u;
        out[0].x = x;           out[0].y = y;
        out[1].x = x + width;   out[1].y = y;
        out[2].x = x + width;   out[2].y = y + height;
        out[3].x = x;           out[3].y = y + height;
        return 4u;
    }
    if (capacity < 4u * CJGUI_LINUX_RADIUS_SEGMENTS) return 0u;
    // Clockwise in device coordinates (y grows down): TL 180→270, TR 270→360,
    // BR 0→90, BL 90→180. Straight edges connect consecutive arcs.
    const double centres[4][2] = {
        { x + radii[0], y + radii[0] },
        { x + width - radii[1], y + radii[1] },
        { x + width - radii[2], y + height - radii[2] },
        { x + radii[3], y + height - radii[3] },
    };
    const double starts[4] = { 180.0, 270.0, 0.0, 90.0 };
    uint32_t count = 0u;
    for (uint32_t corner = 0u; corner < 4u; corner += 1u) {
        for (uint32_t step = 0u; step < CJGUI_LINUX_RADIUS_SEGMENTS; step += 1u) {
            double degrees = starts[corner] +
                90.0 * (double)step / (double)CJGUI_LINUX_RADIUS_SEGMENTS;
            double radians = degrees * 3.14159265358979323846 / 180.0;
            out[count].x = centres[corner][0] + radii[corner] * cos(radians);
            out[count].y = centres[corner][1] + radii[corner] * sin(radians);
            count += 1u;
        }
    }
    return count;
}

// A zero-radius inner ring takes the rectangle shortcut (four points) while a
// rounded outer ring always carries eight points per corner. Expand the inner
// rectangle to the same corner phase so the two rings stay pairable; this is
// the exact inset geometry when radius < stroke width, not a dropped border.
static uint32_t cjgui_linux_expand_rectangle_ring(const CjguiLinuxPoint2D rect[4],
                                                  CjguiLinuxPoint2D *out, uint32_t capacity) {
    if (rect == NULL || out == NULL || capacity < 4u * CJGUI_LINUX_RADIUS_SEGMENTS) return 0u;
    for (uint32_t corner = 0u; corner < 4u; corner += 1u) {
        for (uint32_t step = 0u; step < CJGUI_LINUX_RADIUS_SEGMENTS; step += 1u) {
            out[corner * CJGUI_LINUX_RADIUS_SEGMENTS + step] = rect[corner];
        }
    }
    return 4u * CJGUI_LINUX_RADIUS_SEGMENTS;
}

static void cjgui_linux_paint_transform_point(const CjguiLinuxPaintTransform *transform, double x, double y,
                                              double *outX, double *outY) {
    if (!transform || !transform->active) { *outX = x; *outY = y; return; }
    double dx = (x - transform->centerX) * transform->scaleX;
    double dy = (y - transform->centerY) * transform->scaleY;
    *outX = transform->centerX + dx * transform->cosValue - dy * transform->sinValue;
    *outY = transform->centerY + dx * transform->sinValue + dy * transform->cosValue;
}

// Sutherland–Hodgman against one half-plane (`n·p >= d`). UVs and vertex
// colours interpolate with the same parameter as the position, so a clipped
// glyph keeps its atlas mapping and a clipped gradient keeps its ramp.
static uint32_t cjgui_linux_clip_polygon_plane(const CjguiLinuxPaintPoint *input, uint32_t count,
                                               CjguiLinuxPaintPoint *output,
                                               const CjguiLinuxClipPlane *plane) {
    if (count == 0u || count > CJGUI_LINUX_CLIP_POINT_CAPACITY || plane == NULL) return 0u;
    uint32_t outCount = 0u;
    for (uint32_t i = 0u; i < count; i += 1u) {
        const CjguiLinuxPaintPoint *current = &input[i];
        const CjguiLinuxPaintPoint *next = &input[(i + 1u) % count];
        double currentValue = plane->nx * current->x + plane->ny * current->y - plane->d;
        double nextValue = plane->nx * next->x + plane->ny * next->y - plane->d;
        int currentInside = currentValue >= 0.0;
        int nextInside = nextValue >= 0.0;
        if (currentInside) {
            if (outCount >= CJGUI_LINUX_CLIP_POINT_CAPACITY) return 0u;
            output[outCount++] = *current;
        }
        if (currentInside == nextInside) continue;
        double delta = nextValue - currentValue;
        if (delta == 0.0) continue;
        double t = -currentValue / delta;
        if (t < 0.0) t = 0.0;
        if (t > 1.0) t = 1.0;
        if (outCount >= CJGUI_LINUX_CLIP_POINT_CAPACITY) return 0u;
        CjguiLinuxPaintPoint clipped;
        clipped.x = current->x + (next->x - current->x) * t;
        clipped.y = current->y + (next->y - current->y) * t;
        clipped.u = current->u + (next->u - current->u) * t;
        clipped.v = current->v + (next->v - current->v) * t;
        clipped.r = current->r + (next->r - current->r) * t;
        clipped.g = current->g + (next->g - current->g) * t;
        clipped.b = current->b + (next->b - current->b) * t;
        clipped.a = current->a + (next->a - current->a) * t;
        output[outCount++] = clipped;
    }
    return outCount;
}

static int cjgui_linux_builder_ensure_clip_scratch(CjguiLinuxVertexBuilder *builder) {
    if (builder->clipA != NULL && builder->clipB != NULL) return 1;
    builder->clipA = (CjguiLinuxPaintPoint *)malloc(
        sizeof(CjguiLinuxPaintPoint) * CJGUI_LINUX_CLIP_POINT_CAPACITY);
    builder->clipB = (CjguiLinuxPaintPoint *)malloc(
        sizeof(CjguiLinuxPaintPoint) * CJGUI_LINUX_CLIP_POINT_CAPACITY);
    if (builder->clipA == NULL || builder->clipB == NULL) {
        builder->failed = 1;
        return 0;
    }
    return 1;
}

static void cjgui_linux_builder_append_fan(CjguiLinuxVertexBuilder *builder,
                                           const CjguiLinuxPaintPoint *points, uint32_t count) {
    if (count < 3u) return;
    uint32_t triangleCount = count - 2u;
    if (!cjgui_linux_builder_reserve(builder, triangleCount * 3u)) return;
    for (uint32_t i = 1u; i + 1u < count; i += 1u) {
        CjguiLinuxGpuVertex triangle[3] = {
            { (float)points[0].x, (float)points[0].y, (float)points[0].u, (float)points[0].v,
              (float)points[0].r, (float)points[0].g, (float)points[0].b, (float)points[0].a },
            { (float)points[i].x, (float)points[i].y, (float)points[i].u, (float)points[i].v,
              (float)points[i].r, (float)points[i].g, (float)points[i].b, (float)points[i].a },
            { (float)points[i + 1u].x, (float)points[i + 1u].y, (float)points[i + 1u].u,
              (float)points[i + 1u].v, (float)points[i + 1u].r, (float)points[i + 1u].g,
              (float)points[i + 1u].b, (float)points[i + 1u].a },
        };
        memcpy(builder->vertices + builder->count, triangle, sizeof(triangle));
        builder->count += 3u;
    }
}

// Clip one convex point list to the axis aperture and then to the rounded
// aperture shared by the whole node, then fan-triangulate it. Every painted
// primitive (shape, glyph, image) goes through this one function.
static void cjgui_linux_builder_emit_clipped_points(CjguiLinuxVertexBuilder *builder,
                                                    const CjguiLinuxPaintPoint *points, uint32_t count,
                                                    double clipLeft, double clipTop,
                                                    double clipRight, double clipBottom,
                                                    const CjguiLinuxClipAperture *aperture) {
    if (!builder || builder->failed || points == NULL || count < 3u) return;
    if (!(clipRight > clipLeft) || !(clipBottom > clipTop)) return;
    if (count > CJGUI_LINUX_CLIP_POINT_CAPACITY) return;
    if (!cjgui_linux_builder_ensure_clip_scratch(builder)) return;
    CjguiLinuxPaintPoint *current = builder->clipA;
    CjguiLinuxPaintPoint *next = builder->clipB;
    memcpy(current, points, sizeof(CjguiLinuxPaintPoint) * count);
    uint32_t currentCount = count;
    CjguiLinuxClipPlane axis[4] = {
        { 1.0, 0.0, clipLeft },
        { -1.0, 0.0, -clipRight },
        { 0.0, 1.0, clipTop },
        { 0.0, -1.0, -clipBottom },
    };
    for (uint32_t plane = 0u; plane < 4u; plane += 1u) {
        currentCount = cjgui_linux_clip_polygon_plane(current, currentCount, next, &axis[plane]);
        if (currentCount < 3u) return;
        CjguiLinuxPaintPoint *swap = current;
        current = next;
        next = swap;
    }
    if (aperture != NULL && aperture->active) {
        for (uint32_t plane = 0u; plane < aperture->count; plane += 1u) {
            currentCount = cjgui_linux_clip_polygon_plane(
                current, currentCount, next, &aperture->planes[plane]);
            if (currentCount < 3u) return;
            CjguiLinuxPaintPoint *swap = current;
            current = next;
            next = swap;
        }
    }
    cjgui_linux_builder_append_fan(builder, current, currentCount);
}

// Submit one quad of this node after the paint-only transform, clipped to the
// device-space clip rectangle and the node's rounded aperture. The unrotated
// ancestor aperture stays axis-aligned, matching macOS where the shader clips
// scene points.
static void cjgui_linux_builder_painted_quad(CjguiLinuxVertexBuilder *builder,
                                             const CjguiLinuxPaintTransform *transform,
                                             double x0, double y0, double x1, double y1,
                                             double u0, double v0, double u1, double v1,
                                             double clipLeft, double clipTop, double clipRight,
                                             double clipBottom, const CjguiLinuxClipAperture *aperture,
                                             double r, double g, double b, double a) {
    if (!builder || builder->failed) return;
    if (!(x1 > x0) || !(y1 > y0)) return;
    CjguiLinuxPaintPoint quad[4];
    double corners[4][2] = { { x0, y0 }, { x1, y0 }, { x1, y1 }, { x0, y1 } };
    for (uint32_t i = 0u; i < 4u; i += 1u) {
        cjgui_linux_paint_transform_point(transform, corners[i][0], corners[i][1], &quad[i].x, &quad[i].y);
        quad[i].r = r; quad[i].g = g; quad[i].b = b; quad[i].a = a;
    }
    quad[0].u = u0; quad[0].v = v0;
    quad[1].u = u1; quad[1].v = v0;
    quad[2].u = u1; quad[2].v = v1;
    quad[3].u = u0; quad[3].v = v1;
    cjgui_linux_builder_emit_clipped_points(builder, quad, 4u, clipLeft, clipTop,
                                            clipRight, clipBottom, aperture);
}

// Rect-shaped paint. An inactive transform keeps the historical geometry path;
// rounded apertures still trim the resulting triangles identically.
static void cjgui_linux_builder_rect_painted(CjguiLinuxVertexBuilder *builder,
                                             const CjguiLinuxPaintTransform *transform,
                                             double x, double y, double width, double height,
                                             double clipLeft, double clipTop, double clipRight,
                                             double clipBottom, const CjguiLinuxClipAperture *aperture,
                                             double r, double g, double b, double a) {
    if (width <= 0.0 || height <= 0.0) return;
    const float u = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    const float v = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    cjgui_linux_builder_painted_quad(builder, transform, x, y, x + width, y + height,
                                     (double)u, (double)v, (double)u, (double)v,
                                     clipLeft, clipTop, clipRight, clipBottom, aperture, r, g, b, a);
}

static void cjgui_linux_builder_rect_clipped(CjguiLinuxVertexBuilder *builder,
                                             double x, double y, double width, double height,
                                             double clipLeft, double clipTop, double clipRight,
                                             double clipBottom, const CjguiLinuxClipAperture *aperture,
                                             double r, double g, double b, double a) {
    const float u = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    const float v = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    cjgui_linux_builder_painted_quad(builder, NULL, x, y, x + width, y + height,
                                     (double)u, (double)v, (double)u, (double)v,
                                     clipLeft, clipTop, clipRight, clipBottom, aperture, r, g, b, a);
}

static void cjgui_linux_builder_text(CjguiLinuxVertexBuilder *builder, CjguiLinuxText *text,
                                     const char *value, double fontSize, uint32_t fontWeight,
                                     uint32_t fontFamily, double maxWidth, double originX, double originY,
                                     double clipX, double clipY, double clipRight, double clipBottom,
                                     const CjguiLinuxClipAperture *aperture,
                                     double r, double g, double b, double a,
                                     const CjguiLinuxPaintTransform *transform,
                                     uint32_t maxLines, int ellipsis) {
    if (!text || !value || !value[0] || builder->failed) return;
    if (builder->textQuads == NULL) {
        builder->textQuads = (CjguiLinuxTextQuad *)malloc(sizeof(CjguiLinuxTextQuad) * 1024u);
        if (builder->textQuads == NULL) {
            builder->failed = 1;
            return;
        }
    }
    CjguiLinuxTextQuad *quads = builder->textQuads;
    uint32_t quadCount = 0u;
    double width = 0.0, height = 0.0, ascent = 0.0;
    int status = cjgui_linux_text_layout_limited(text, value, strlen(value), fontSize, fontWeight,
                                                 fontFamily, maxWidth, maxLines, ellipsis, 0.0, 0.0, 1,
                                                 quads, 1024u, &quadCount, &width, &height, &ascent);
    if (status != CJGUI_LINUX_TEXT_OK && status != CJGUI_LINUX_TEXT_BUDGET_EXCEEDED) return;
    if (quadCount > 1024u) quadCount = 1024u;
    for (uint32_t i = 0u; i < quadCount; i += 1u) {
        CjguiLinuxTextQuad *quad = &quads[i];
        double qx = originX + quad->x;
        double qy = originY + quad->y;
        double qw = quad->width;
        double qh = quad->height;
        if (qw <= 0.0 || qh <= 0.0) continue;
        // Both the transformed and the axis-aligned path use the same
        // polygon aperture. A partially visible glyph is trimmed instead of
        // being dropped or allowed to escape a rounded corner.
        cjgui_linux_builder_painted_quad(builder, transform, qx, qy, qx + qw, qy + qh,
                                         quad->u0, quad->v0, quad->u1, quad->v1,
                                         clipX, clipY, clipRight, clipBottom, aperture, r, g, b, a);
    }
}

// ---------------------------------------------------------------- 多样式文字
//
// The common layer already validated ranges, budget and UTF-8 boundaries.
// This parser is the platform's bounded transport onto the SAME declaration:
// 14 colon fields per run, later items overriding earlier ones. A 15/16-field
// item is a selection decoration and is skipped here (Linux paints the native
// editor selection itself). Malformed input never reaches the accepted scene,
// so the safe reaction is the plain single-style path.
#define CJGUI_LINUX_RUN_PARSE_CAP 128u

typedef struct CjguiLinuxParsedRuns {
    CjguiLinuxTextStyleRun runs[CJGUI_LINUX_RUN_PARSE_CAP];
    uint32_t count;
} CjguiLinuxParsedRuns;

static int lx_field_u32(const char *s, size_t n, uint32_t *out) {
    if (n == 0u) return 0;
    char *end = NULL;
    unsigned long v = strtoul(s, &end, 10);
    if (end != s + n || v > 0xFFFFFFFFul) return 0;
    *out = (uint32_t)v;
    return 1;
}

static int lx_field_f64(const char *s, size_t n, double *out) {
    if (n == 0u) return 0;
    char *end = NULL;
    double v = strtod(s, &end);
    if (end != s + n || !isfinite(v)) return 0;
    *out = v;
    return 1;
}

static int lx_field_color(const char *s, size_t n, float *out) {
    double v = 0.0;
    if (!lx_field_f64(s, n, &v) || v < 0.0 || v > 1.0) return 0;
    *out = (float)v;
    return 1;
}

static int cjgui_linux_parse_runs(const char *encoded, const char *value, size_t textLength,
                                  CjguiLinuxParsedRuns *out) {
    out->count = 0u;
    if (!encoded || !encoded[0]) return 1;
    const char *p = encoded;
    while (*p) {
        const char *itemEnd = strchr(p, ';');
        if (!itemEnd) itemEnd = p + strlen(p);
        const char *fields[16];
        size_t lengths[16];
        uint32_t fieldCount = 0u;
        const char *q = p;
        int overflow = 0;
        while (q < itemEnd) {
            const char *c = (const char *)memchr(q, ':', (size_t)(itemEnd - q));
            if (!c) c = itemEnd;
            if (fieldCount < 16u) {
                fields[fieldCount] = q;
                lengths[fieldCount] = (size_t)(c - q);
            } else {
                overflow = 1;
            }
            fieldCount++;
            q = c + 1;
        }
        if (overflow) return 0;
        if (fieldCount == 15u || fieldCount == 16u) {
            const char *last = fields[fieldCount - 1u];
            size_t lastLen = lengths[fieldCount - 1u];
            if ((lastLen == 1u && (last[0] == '1' || last[0] == '2'))) {
                p = (*itemEnd == ';') ? itemEnd + 1 : itemEnd;
                continue;
            }
            return 0;
        }
        if (fieldCount != 14u) return 0;
        if (out->count >= CJGUI_LINUX_RUN_PARSE_CAP) return 0;

        CjguiLinuxTextStyleRun run;
        memset(&run, 0, sizeof(run));
        uint32_t weight = 0u, family = 0u, background = 0u;
        double size = 0.0;
        if (!lx_field_u32(fields[0], lengths[0], &run.start) ||
            !lx_field_u32(fields[1], lengths[1], &run.end) ||
            !lx_field_f64(fields[2], lengths[2], &size) ||
            !lx_field_u32(fields[3], lengths[3], &weight) ||
            !lx_field_u32(fields[4], lengths[4], &family) ||
            !lx_field_color(fields[5], lengths[5], &run.red) ||
            !lx_field_color(fields[6], lengths[6], &run.green) ||
            !lx_field_color(fields[7], lengths[7], &run.blue) ||
            !lx_field_color(fields[8], lengths[8], &run.alpha) ||
            !lx_field_u32(fields[9], lengths[9], &background) ||
            !lx_field_color(fields[10], lengths[10], &run.backgroundRed) ||
            !lx_field_color(fields[11], lengths[11], &run.backgroundGreen) ||
            !lx_field_color(fields[12], lengths[12], &run.backgroundBlue) ||
            !lx_field_color(fields[13], lengths[13], &run.backgroundAlpha)) {
            return 0;
        }
        if (!(size > 0.0) || size > 144.0 || weight > 1000u) return 0;
        if (run.end <= run.start || run.end > textLength) return 0;
        const unsigned char *bytes = (const unsigned char *)value;
        if ((run.start < textLength && (bytes[run.start] & 0xC0u) == 0x80u) ||
            (run.end < textLength && (bytes[run.end] & 0xC0u) == 0x80u)) {
            return 0;
        }
        run.fontSize = size;
        run.fontWeight = weight;
        run.fontFamily = family;
        run.hasBackground = (uint8_t)(background != 0u ? 1u : 0u);
        out->runs[out->count++] = run;
        p = (*itemEnd == ';') ? itemEnd + 1 : itemEnd;
    }
    return 1;
}

static void cjgui_linux_builder_styled_text(CjguiLinuxVertexBuilder *builder, CjguiLinuxText *text,
                                            const char *value, const char *encodedRuns,
                                            double fontSize, uint32_t fontWeight,
                                            uint32_t fontFamily, double maxWidth, double originX,
                                            double originY, double clipX, double clipY,
                                            double clipRight, double clipBottom,
                                            const CjguiLinuxClipAperture *aperture, double r,
                                            double g, double b, double a,
                                            const CjguiLinuxPaintTransform *transform,
                                            uint32_t maxLines, int ellipsis) {
    if (!text || !value || !value[0] || builder->failed) return;
    CjguiLinuxParsedRuns parsed;
    size_t textLength = strlen(value);
    if (!cjgui_linux_parse_runs(encodedRuns, value, textLength, &parsed) || parsed.count == 0u) {
        cjgui_linux_builder_text(builder, text, value, fontSize, fontWeight, fontFamily, maxWidth,
                                 originX, originY, clipX, clipY, clipRight, clipBottom, aperture,
                                 r, g, b, a, transform, maxLines, ellipsis);
        return;
    }
    if (builder->styledQuads == NULL) {
        builder->styledQuads = (CjguiLinuxStyledQuad *)malloc(
            sizeof(CjguiLinuxStyledQuad) * 2048u);
        if (builder->styledQuads == NULL) {
            builder->failed = 1;
            return;
        }
    }
    if (builder->styledSpans == NULL) {
        builder->styledSpans = (CjguiLinuxStyledSpan *)malloc(
            sizeof(CjguiLinuxStyledSpan) * 512u);
        if (builder->styledSpans == NULL) {
            builder->failed = 1;
            return;
        }
    }
    uint32_t quadCount = 0u, spanCount = 0u;
    double width = 0.0, height = 0.0, ascent = 0.0, lineHeight = 0.0;
    int status = cjgui_linux_text_styled_layout(
        text, value, textLength, fontSize, fontWeight, fontFamily, maxWidth, maxLines, ellipsis,
        parsed.runs, parsed.count, 0.0, 0.0, 0, NULL, 0u, NULL, 0u, &quadCount, &spanCount,
        &width, &height, &ascent, &lineHeight);
    if (status != CJGUI_LINUX_TEXT_OK) {
        cjgui_linux_builder_text(builder, text, value, fontSize, fontWeight, fontFamily, maxWidth,
                                 originX, originY, clipX, clipY, clipRight, clipBottom, aperture,
                                 r, g, b, a, transform, maxLines, ellipsis);
        return;
    }
    // Emitted quad/span coordinates are already node-relative; the paint loop
    // below applies originX/originY exactly once, matching the plain path.
    status = cjgui_linux_text_styled_layout(
        text, value, textLength, fontSize, fontWeight, fontFamily, maxWidth, maxLines, ellipsis,
        parsed.runs, parsed.count, 0.0, 0.0, 1, builder->styledQuads, 2048u,
        builder->styledSpans, 512u, &quadCount, &spanCount, &width, &height, &ascent,
        &lineHeight);
    if (status != CJGUI_LINUX_TEXT_OK && status != CJGUI_LINUX_TEXT_BUDGET_EXCEEDED) {
        cjgui_linux_builder_text(builder, text, value, fontSize, fontWeight, fontFamily, maxWidth,
                                 originX, originY, clipX, clipY, clipRight, clipBottom, aperture,
                                 r, g, b, a, transform, maxLines, ellipsis);
        return;
    }
    if (spanCount > 512u) spanCount = 512u;
    for (uint32_t i = 0u; i < spanCount; i += 1u) {
        const CjguiLinuxStyledSpan *span = &builder->styledSpans[i];
        if (span->runIndex >= parsed.count) continue;
        const CjguiLinuxTextStyleRun *run = &parsed.runs[span->runIndex];
        if (!run->hasBackground || run->backgroundAlpha <= 0.0f) continue;
        if (span->x1 <= span->x0 || span->height <= 0.0) continue;
        cjgui_linux_builder_rect_painted(builder, transform, originX + span->x0,
                                         originY + span->top, span->x1 - span->x0,
                                         span->height, clipX, clipY,
                                         clipRight, clipBottom, aperture,
                                         run->backgroundRed, run->backgroundGreen,
                                         run->backgroundBlue,
                                         run->backgroundAlpha * a);
    }
    if (quadCount > 2048u) quadCount = 2048u;
    for (uint32_t i = 0u; i < quadCount; i += 1u) {
        const CjguiLinuxStyledQuad *sq = &builder->styledQuads[i];
        const CjguiLinuxTextQuad *quad = &sq->glyph;
        double qx = originX + quad->x;
        double qy = originY + quad->y;
        double qw = quad->width;
        double qh = quad->height;
        if (qw <= 0.0 || qh <= 0.0) continue;
        double cr = r, cg = g, cb = b, ca = a;
        if (sq->runIndex < parsed.count) {
            const CjguiLinuxTextStyleRun *run = &parsed.runs[sq->runIndex];
            cr = run->red;
            cg = run->green;
            cb = run->blue;
            ca = run->alpha * a;
        }
        if (ca <= 0.0) continue;
        cjgui_linux_builder_painted_quad(builder, transform, qx, qy, qx + qw, qy + qh,
                                         quad->u0, quad->v0, quad->u1, quad->v1,
                                         clipX, clipY, clipRight, clipBottom, aperture, cr, cg,
                                         cb, ca);
    }
}

static int cjgui_linux_node_has_gradient(const CjguiInternalRendererComposableNode *node) {
    return node->gradientPresent != 0u && node->gradientStopCount >= 2u &&
           node->gradientStopCount <= 4u;
}

static void cjgui_linux_node_corner_radii(const CjguiInternalRendererComposableNode *node,
                                          double *topLeft, double *topRight,
                                          double *bottomRight, double *bottomLeft) {
    if (node->cornerRadiiPresent != 0u) {
        *topLeft = node->cornerTopLeft;
        *topRight = node->cornerTopRight;
        *bottomRight = node->cornerBottomRight;
        *bottomLeft = node->cornerBottomLeft;
    } else {
        *topLeft = node->cornerRadius;
        *topRight = node->cornerRadius;
        *bottomRight = node->cornerRadius;
        *bottomLeft = node->cornerRadius;
    }
    if (!isfinite(*topLeft) || *topLeft < 0.0) *topLeft = 0.0;
    if (!isfinite(*topRight) || *topRight < 0.0) *topRight = 0.0;
    if (!isfinite(*bottomRight) || *bottomRight < 0.0) *bottomRight = 0.0;
    if (!isfinite(*bottomLeft) || *bottomLeft < 0.0) *bottomLeft = 0.0;
}

// Node-local gradient parameter. localX/localY are device pixels in the same
// space as the node origin; ABI start/end are normalized against the node box.
// Subtracting the origin here is what makes a moved node keep the same ramp.
static double cjgui_linux_node_gradient_parameter(const CjguiInternalRendererComposableNode *node,
                                                  double localX, double localY,
                                                  double originX, double originY,
                                                  double width, double height) {
    double px = (localX - originX) / (width > 1e-6 ? width : 1e-6);
    double py = (localY - originY) / (height > 1e-6 ? height : 1e-6);
    double dx = node->gradientEndX - node->gradientStartX;
    double dy = node->gradientEndY - node->gradientStartY;
    double denominator = dx * dx + dy * dy;
    if (denominator < 1e-6) denominator = 1e-6;
    double t = ((px - node->gradientStartX) * dx + (py - node->gradientStartY) * dy) / denominator;
    if (!isfinite(t)) t = 0.0;
    // Keep the raw spatial parameter. Clamping here would move the real 0/1
    // boundaries to the triangle vertices and lose the flat end sections.
    return t;
}

// Same piecewise ramp as the macOS fragment shader: four stop positions and
// colours, sRGB channels mixed independently. A triangle only reproduces this
// exactly when it does not span a stop boundary, so the splitter below cuts at
// every interior stop instead of evaluating just the three corners.
static void cjgui_linux_node_gradient_color_at(const CjguiInternalRendererComposableNode *node,
                                               double t,
                                               double *outR, double *outG, double *outB, double *outA) {
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    double colours[4][4] = {
        { node->gradientStop0Red, node->gradientStop0Green, node->gradientStop0Blue, node->gradientStop0Alpha },
        { node->gradientStop1Red, node->gradientStop1Green, node->gradientStop1Blue, node->gradientStop1Alpha },
        { node->gradientStop2Red, node->gradientStop2Green, node->gradientStop2Blue, node->gradientStop2Alpha },
        { node->gradientStop3Red, node->gradientStop3Green, node->gradientStop3Blue, node->gradientStop3Alpha },
    };
    double positions[4] = {
        node->gradientStop0Position, node->gradientStop1Position,
        node->gradientStop2Position, node->gradientStop3Position,
    };
    double step = positions[1] - positions[0];
    if (step < 1e-6) step = 1e-6;
    double mix = (t - positions[0]) / step;
    if (mix < 0.0) mix = 0.0;
    if (mix > 1.0) mix = 1.0;
    double result[4];
    for (uint32_t channel = 0u; channel < 4u; channel += 1u) {
        result[channel] = colours[0][channel] + (colours[1][channel] - colours[0][channel]) * mix;
    }
    if (node->gradientStopCount > 2u && t >= positions[1]) {
        step = positions[2] - positions[1];
        if (step < 1e-6) step = 1e-6;
        mix = (t - positions[1]) / step;
        if (mix < 0.0) mix = 0.0;
        if (mix > 1.0) mix = 1.0;
        for (uint32_t channel = 0u; channel < 4u; channel += 1u) {
            result[channel] = colours[1][channel] + (colours[2][channel] - colours[1][channel]) * mix;
        }
    }
    if (node->gradientStopCount > 3u && t >= positions[2]) {
        step = positions[3] - positions[2];
        if (step < 1e-6) step = 1e-6;
        mix = (t - positions[2]) / step;
        if (mix < 0.0) mix = 0.0;
        if (mix > 1.0) mix = 1.0;
        for (uint32_t channel = 0u; channel < 4u; channel += 1u) {
            result[channel] = colours[2][channel] + (colours[3][channel] - colours[2][channel]) * mix;
        }
    }
    *outR = result[0]; *outG = result[1]; *outB = result[2]; *outA = result[3];
}

// A gradient triangle may span several stop segments. Split it at every
// interior stop with an exact half-plane clip in parameter space; each piece
// then has a color that is affine in its three vertex colors. This is exact
// piecewise evaluation, not a denser approximation of the ramp.
#define CJGUI_LINUX_GRADIENT_POLYGON_CAPACITY 16u
typedef struct CjguiLinuxGradientPoint {
    CjguiLinuxPaintPoint point;
    double t;
} CjguiLinuxGradientPoint;

static uint32_t cjgui_linux_clip_gradient_parameter(const CjguiLinuxGradientPoint *input,
                                                    uint32_t count, CjguiLinuxGradientPoint *output,
                                                    double value, int keepAbove) {
    if (input == NULL || output == NULL || count > CJGUI_LINUX_GRADIENT_POLYGON_CAPACITY) return 0u;
    uint32_t outCount = 0u;
    for (uint32_t i = 0u; i < count; i += 1u) {
        const CjguiLinuxGradientPoint *current = &input[i];
        const CjguiLinuxGradientPoint *next = &input[(i + 1u) % count];
        int currentInside = keepAbove ? current->t >= value : current->t <= value;
        int nextInside = keepAbove ? next->t >= value : next->t <= value;
        if (currentInside) {
            if (outCount >= CJGUI_LINUX_GRADIENT_POLYGON_CAPACITY) return 0u;
            output[outCount++] = *current;
        }
        if (currentInside == nextInside) continue;
        double delta = next->t - current->t;
        if (fabs(delta) < 1e-12) continue;
        double alpha = (value - current->t) / delta;
        if (alpha < 0.0) alpha = 0.0;
        if (alpha > 1.0) alpha = 1.0;
        CjguiLinuxGradientPoint *cross = &output[outCount++];
        cross->point.x = current->point.x + (next->point.x - current->point.x) * alpha;
        cross->point.y = current->point.y + (next->point.y - current->point.y) * alpha;
        cross->point.u = current->point.u + (next->point.u - current->point.u) * alpha;
        cross->point.v = current->point.v + (next->point.v - current->point.v) * alpha;
        cross->point.r = current->point.r + (next->point.r - current->point.r) * alpha;
        cross->point.g = current->point.g + (next->point.g - current->point.g) * alpha;
        cross->point.b = current->point.b + (next->point.b - current->point.b) * alpha;
        cross->point.a = current->point.a + (next->point.a - current->point.a) * alpha;
        cross->t = value;
    }
    return outCount;
}

static void cjgui_linux_emit_gradient_triangle(CjguiLinuxVertexBuilder *builder,
                                               const CjguiInternalRendererComposableNode *node,
                                               const CjguiLinuxPaintPoint points[3],
                                               const double parameters[3],
                                               double clipLeft, double clipTop,
                                               double clipRight, double clipBottom,
                                               const CjguiLinuxClipAperture *aperture) {
    double low = parameters[0], high = parameters[0];
    for (uint32_t i = 1u; i < 3u; i += 1u) {
        if (parameters[i] < low) low = parameters[i];
        if (parameters[i] > high) high = parameters[i];
    }
    if (high - low < 1e-12) {
        double r = 0.0, g = 0.0, b = 0.0, a = 0.0;
        cjgui_linux_node_gradient_color_at(node, low, &r, &g, &b, &a);
        CjguiLinuxPaintPoint flat[3] = { points[0], points[1], points[2] };
        for (uint32_t i = 0u; i < 3u; i += 1u) {
            flat[i].r = r; flat[i].g = g; flat[i].b = b; flat[i].a = a;
        }
        cjgui_linux_builder_emit_clipped_points(builder, flat, 3u, clipLeft, clipTop,
                                                clipRight, clipBottom, aperture);
        return;
    }
    double cuts[8] = { low, high, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
    uint32_t cutCount = 2u;
    // The raw parameter may run past both ends. Split at the real 0/1 bounds
    // and at every interior stop; color sampling clamps t inside the flat
    // end sections, so each remaining piece is still affine and exact.
    double bounds[2] = { 0.0, 1.0 };
    for (uint32_t b = 0u; b < 2u; b += 1u) {
        double bound = bounds[b];
        if (!(bound > low + 1e-9) || !(bound < high - 1e-9)) continue;
        cuts[cutCount++] = bound;
    }
    for (uint32_t i = 0u; i < node->gradientStopCount && i < 4u; i += 1u) {
        double stop = i == 0u ? node->gradientStop0Position :
                      (i == 1u ? node->gradientStop1Position :
                       (i == 2u ? node->gradientStop2Position : node->gradientStop3Position));
        if (!(stop > low + 1e-9) || !(stop < high - 1e-9)) continue;
        int duplicate = 0;
        for (uint32_t j = 0u; j < cutCount; j += 1u) {
            if (fabs(cuts[j] - stop) < 1e-9) { duplicate = 1; break; }
        }
        if (!duplicate) cuts[cutCount++] = stop;
    }
    for (uint32_t i = 1u; i < cutCount; i += 1u) {
        double value = cuts[i];
        uint32_t j = i;
        while (j > 0u && cuts[j - 1u] > value) { cuts[j] = cuts[j - 1u]; j -= 1u; }
        cuts[j] = value;
    }
    CjguiLinuxGradientPoint base[3];
    for (uint32_t i = 0u; i < 3u; i += 1u) {
        base[i].point = points[i];
        base[i].t = parameters[i];
    }
    CjguiLinuxGradientPoint lower[CJGUI_LINUX_GRADIENT_POLYGON_CAPACITY];
    CjguiLinuxGradientPoint upper[CJGUI_LINUX_GRADIENT_POLYGON_CAPACITY];
    for (uint32_t interval = 0u; interval + 1u < cutCount; interval += 1u) {
        uint32_t count = cjgui_linux_clip_gradient_parameter(base, 3u, lower,
                                                             cuts[interval], 1);
        if (count < 3u) continue;
        count = cjgui_linux_clip_gradient_parameter(lower, count, upper,
                                                    cuts[interval + 1u], 0);
        if (count < 3u) continue;
        for (uint32_t i = 0u; i < count; i += 1u) {
            cjgui_linux_node_gradient_color_at(node, upper[i].t, &upper[i].point.r,
                                               &upper[i].point.g, &upper[i].point.b,
                                               &upper[i].point.a);
        }
        for (uint32_t i = 1u; i + 1u < count; i += 1u) {
            CjguiLinuxPaintPoint triangle[3] = {
                upper[0].point, upper[i].point, upper[i + 1u].point
            };
            cjgui_linux_builder_emit_clipped_points(builder, triangle, 3u, clipLeft, clipTop,
                                                    clipRight, clipBottom, aperture);
        }
    }
}

static void cjgui_linux_builder_shape_triangle(CjguiLinuxVertexBuilder *builder,
                                               const CjguiInternalRendererComposableNode *node,
                                               const CjguiLinuxPaintTransform *transform,
                                               const CjguiLinuxPoint2D local[3],
                                               int gradient, double originX, double originY,
                                               double width, double height,
                                               double r, double g, double b, double a,
                                               double clipLeft, double clipTop,
                                               double clipRight, double clipBottom,
                                               const CjguiLinuxClipAperture *aperture) {
    CjguiLinuxPaintPoint points[3];
    double parameters[3] = { 0.0, 0.0, 0.0 };
    const float white = 0.5f / (float)CJGUI_LINUX_TEXT_ATLAS_SIDE;
    for (uint32_t i = 0u; i < 3u; i += 1u) {
        cjgui_linux_paint_transform_point(transform, local[i].x, local[i].y,
                                          &points[i].x, &points[i].y);
        points[i].u = (double)white;
        points[i].v = (double)white;
        if (gradient) {
            parameters[i] = cjgui_linux_node_gradient_parameter(node, local[i].x, local[i].y,
                                                                originX, originY, width, height);
        } else {
            points[i].r = r; points[i].g = g; points[i].b = b; points[i].a = a;
        }
    }
    if (gradient) {
        cjgui_linux_emit_gradient_triangle(builder, node, points, parameters,
                                           clipLeft, clipTop, clipRight, clipBottom, aperture);
        return;
    }
    cjgui_linux_builder_emit_clipped_points(builder, points, 3u, clipLeft, clipTop,
                                            clipRight, clipBottom, aperture);
}

static void cjgui_linux_builder_rounded_fill(CjguiLinuxVertexBuilder *builder,
                                             const CjguiInternalRendererComposableNode *node,
                                             const CjguiLinuxPaintTransform *transform,
                                             double x, double y, double width, double height,
                                             double clipLeft, double clipTop,
                                             double clipRight, double clipBottom,
                                             const CjguiLinuxClipAperture *aperture) {
    double topLeft = 0.0, topRight = 0.0, bottomRight = 0.0, bottomLeft = 0.0;
    cjgui_linux_node_corner_radii(node, &topLeft, &topRight, &bottomRight, &bottomLeft);
    CjguiLinuxPoint2D outline[4u * CJGUI_LINUX_RADIUS_SEGMENTS];
    uint32_t count = cjgui_linux_rounded_outline(x, y, width, height, topLeft, topRight,
                                                 bottomRight, bottomLeft, outline,
                                                 (uint32_t)(sizeof(outline) / sizeof(outline[0])));
    if (count < 3u) return;
    int gradient = cjgui_linux_node_has_gradient(node);
    if (count == 4u) {
        CjguiLinuxPoint2D triangle[3];
        triangle[0] = outline[0]; triangle[1] = outline[1]; triangle[2] = outline[2];
        cjgui_linux_builder_shape_triangle(builder, node, transform, triangle, gradient,
                                           x, y, width, height, node->fillRed, node->fillGreen,
                                           node->fillBlue, node->fillAlpha,
                                           clipLeft, clipTop, clipRight, clipBottom, aperture);
        triangle[0] = outline[0]; triangle[1] = outline[2]; triangle[2] = outline[3];
        cjgui_linux_builder_shape_triangle(builder, node, transform, triangle, gradient,
                                           x, y, width, height, node->fillRed, node->fillGreen,
                                           node->fillBlue, node->fillAlpha,
                                           clipLeft, clipTop, clipRight, clipBottom, aperture);
        return;
    }
    CjguiLinuxPoint2D centre = { x + width * 0.5, y + height * 0.5 };
    for (uint32_t i = 0u; i < count; i += 1u) {
        CjguiLinuxPoint2D triangle[3] = { centre, outline[i], outline[(i + 1u) % count] };
        cjgui_linux_builder_shape_triangle(builder, node, transform, triangle, gradient,
                                           x, y, width, height, node->fillRed, node->fillGreen,
                                           node->fillBlue, node->fillAlpha,
                                           clipLeft, clipTop, clipRight, clipBottom, aperture);
    }
}

static void cjgui_linux_builder_rounded_border(CjguiLinuxVertexBuilder *builder,
                                               const CjguiInternalRendererComposableNode *node,
                                               const CjguiLinuxPaintTransform *transform,
                                               double x, double y, double width, double height,
                                               double thickness,
                                               double clipLeft, double clipTop,
                                               double clipRight, double clipBottom,
                                               const CjguiLinuxClipAperture *aperture) {
    double topLeft = 0.0, topRight = 0.0, bottomRight = 0.0, bottomLeft = 0.0;
    cjgui_linux_node_corner_radii(node, &topLeft, &topRight, &bottomRight, &bottomLeft);
    CjguiLinuxPoint2D outer[4u * CJGUI_LINUX_RADIUS_SEGMENTS];
    uint32_t outerCount = cjgui_linux_rounded_outline(x, y, width, height, topLeft, topRight,
                                                      bottomRight, bottomLeft, outer,
                                                      (uint32_t)(sizeof(outer) / sizeof(outer[0])));
    if (outerCount < 3u) return;
    double innerX = x + thickness;
    double innerY = y + thickness;
    double innerWidth = width - thickness * 2.0;
    double innerHeight = height - thickness * 2.0;
    if (!(innerWidth > 0.0) || !(innerHeight > 0.0)) {
        CjguiLinuxPoint2D centre = { x + width * 0.5, y + height * 0.5 };
        for (uint32_t i = 0u; i < outerCount; i += 1u) {
            CjguiLinuxPoint2D triangle[3] = { centre, outer[i], outer[(i + 1u) % outerCount] };
            cjgui_linux_builder_shape_triangle(builder, node, transform, triangle, 0,
                                               0.0, 0.0, width, height, node->borderRed, node->borderGreen,
                                               node->borderBlue, node->borderAlpha,
                                               clipLeft, clipTop, clipRight, clipBottom, aperture);
        }
        return;
    }
    double innerRadii[4] = {
        topLeft - thickness > 0.0 ? topLeft - thickness : 0.0,
        topRight - thickness > 0.0 ? topRight - thickness : 0.0,
        bottomRight - thickness > 0.0 ? bottomRight - thickness : 0.0,
        bottomLeft - thickness > 0.0 ? bottomLeft - thickness : 0.0,
    };
    CjguiLinuxPoint2D inner[4u * CJGUI_LINUX_RADIUS_SEGMENTS];
    uint32_t innerCount = cjgui_linux_rounded_outline(innerX, innerY, innerWidth, innerHeight,
                                                      innerRadii[0], innerRadii[1],
                                                      innerRadii[2], innerRadii[3], inner,
                                                      (uint32_t)(sizeof(inner) / sizeof(inner[0])));
    if (innerCount != outerCount && innerCount == 4u && outerCount == 4u * CJGUI_LINUX_RADIUS_SEGMENTS) {
        CjguiLinuxPoint2D rectangle[4] = { inner[0], inner[1], inner[2], inner[3] };
        innerCount = cjgui_linux_expand_rectangle_ring(rectangle, inner,
                                                       (uint32_t)(sizeof(inner) / sizeof(inner[0])));
    }
    if (innerCount != outerCount) return;
    for (uint32_t i = 0u; i < outerCount; i += 1u) {
        uint32_t next = (i + 1u) % outerCount;
        CjguiLinuxPoint2D triangle[3] = { outer[i], outer[next], inner[next] };
        cjgui_linux_builder_shape_triangle(builder, node, transform, triangle, 0,
                                           0.0, 0.0, width, height, node->borderRed, node->borderGreen,
                                           node->borderBlue, node->borderAlpha,
                                           clipLeft, clipTop, clipRight, clipBottom, aperture);
        triangle[0] = outer[i]; triangle[1] = inner[next]; triangle[2] = inner[i];
        cjgui_linux_builder_shape_triangle(builder, node, transform, triangle, 0,
                                           0.0, 0.0, width, height, node->borderRed, node->borderGreen,
                                           node->borderBlue, node->borderAlpha,
                                           clipLeft, clipTop, clipRight, clipBottom, aperture);
    }
}

static const char *cjgui_linux_node_body(const CjguiLinuxNodeSlot *slot) {
    if (slot->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON && slot->label && slot->label[0]) {
        return slot->label;
    }
    // Boolean inputs show their label beside the native checkbox; the value is
    // interaction state, not a caption.
    if (slot->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT &&
        slot->label && slot->label[0]) {
        return slot->label;
    }
    return slot->value ? slot->value : "";
}

static int cjgui_linux_node_boolean_checked(const CjguiLinuxNodeSlot *slot) {
    return slot->value != NULL &&
           (strcmp(slot->value, "true") == 0 || strcmp(slot->value, "1") == 0);
}

// Native checkbox: square border from the node's own text colour, filled when
// checked, tick in a contrasting channel, plus a focus ring on the session's
// focused node. Disabled/read-only only mutes the paint; routing stays on the
// existing interactive owner.
static void cjgui_linux_paint_boolean(CjguiLinuxSession *session, CjguiLinuxVertexBuilder *builder,
                                      const CjguiLinuxNodeSlot *slot,
                                      const CjguiLinuxPaintTransform *transform,
                                      double nodeLeft, double nodeTop, double nodeRight,
                                      double nodeBottom, double scale,
                                      double clipLeft, double clipTop, double clipRight,
                                      double clipBottom, const CjguiLinuxClipAperture *aperture,
                                      double *outTextLeft) {
    const CjguiInternalRendererComposableNode *node = &slot->node;
    double height = nodeBottom - nodeTop;
    if (!(height > 0.0)) return;
    double side = height - 6.0 * scale;
    if (side > 18.0 * scale) side = 18.0 * scale;
    if (side < 8.0 * scale) side = 8.0 * scale;
    if (side > height) side = height;
    double boxX = nodeLeft + 6.0 * scale;
    double boxY = nodeTop + (height - side) * 0.5;
    int checked = cjgui_linux_node_boolean_checked(slot);
    int disabled = node->isInteractive == 0u || node->isReadOnly != 0u;
    double accentR = node->textRed, accentG = node->textGreen, accentB = node->textBlue;
    double accentA = disabled ? 0.45 : 0.95;
    double border = 1.5 * scale > side * 0.12 ? side * 0.12 : 1.5 * scale;
    if (border < 1.0 * scale) border = 1.0 * scale;
    // Interior stays light so the box reads on the form's panel fill.
    cjgui_linux_builder_rect_painted(builder, transform, boxX, boxY, side, side,
                                     clipLeft, clipTop, clipRight, clipBottom, aperture,
                                     0.98, 0.98, 0.99, disabled ? 0.45 : 0.95);
    if (checked) {
        cjgui_linux_builder_rect_painted(builder, transform, boxX + border, boxY + border,
                                         side - border * 2.0, side - border * 2.0,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         accentR, accentG, accentB, accentA);
        double luma = 0.2126 * accentR + 0.7152 * accentG + 0.0722 * accentB;
        double tickR = luma > 0.62 ? 0.12 : 0.98;
        double tickG = luma > 0.62 ? 0.12 : 0.98;
        double tickB = luma > 0.62 ? 0.12 : 0.99;
        CjguiLinuxPoint2D p1 = { boxX + side * 0.22, boxY + side * 0.52 };
        CjguiLinuxPoint2D p2 = { boxX + side * 0.43, boxY + side * 0.73 };
        CjguiLinuxPoint2D p3 = { boxX + side * 0.80, boxY + side * 0.29 };
        double thickness = side * 0.14;
        CjguiLinuxPoint2D segments[2][2] = { { p1, p2 }, { p2, p3 } };
        for (uint32_t s = 0u; s < 2u; s += 1u) {
            double dx = segments[s][1].x - segments[s][0].x;
            double dy = segments[s][1].y - segments[s][0].y;
            double length = sqrt(dx * dx + dy * dy);
            if (length < 1e-6) continue;
            double nx = -dy / length * thickness * 0.5;
            double ny = dx / length * thickness * 0.5;
            CjguiLinuxPoint2D quad[4] = {
                { segments[s][0].x + nx, segments[s][0].y + ny },
                { segments[s][1].x + nx, segments[s][1].y + ny },
                { segments[s][1].x - nx, segments[s][1].y - ny },
                { segments[s][0].x - nx, segments[s][0].y - ny },
            };
            CjguiLinuxPoint2D quadA[3] = { quad[0], quad[1], quad[2] };
            CjguiLinuxPoint2D quadB[3] = { quad[0], quad[2], quad[3] };
            cjgui_linux_builder_shape_triangle(builder, node, transform, quadA, 0,
                                               0.0, 0.0, side, side, tickR, tickG, tickB, 0.98,
                                               clipLeft, clipTop, clipRight, clipBottom, aperture);
            cjgui_linux_builder_shape_triangle(builder, node, transform, quadB, 0,
                                               0.0, 0.0, side, side, tickR, tickG, tickB, 0.98,
                                               clipLeft, clipTop, clipRight, clipBottom, aperture);
        }
    } else {
        cjgui_linux_builder_rect_painted(builder, transform, boxX, boxY, side, border,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         accentR, accentG, accentB, accentA);
        cjgui_linux_builder_rect_painted(builder, transform, boxX, boxY + side - border,
                                         side, border,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         accentR, accentG, accentB, accentA);
        cjgui_linux_builder_rect_painted(builder, transform, boxX, boxY + border, border,
                                         side - border * 2.0,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         accentR, accentG, accentB, accentA);
        cjgui_linux_builder_rect_painted(builder, transform, boxX + side - border,
                                         boxY + border, border, side - border * 2.0,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         accentR, accentG, accentB, accentA);
    }
    if (session->focusNodeId >= 0 && (uint64_t)session->focusNodeId == node->nodeId &&
        session->focusNodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT) {
        double ring = 2.0 * scale;
        double rx = boxX - 2.0 * scale, ry = boxY - 2.0 * scale;
        double rs = side + 4.0 * scale;
        double ringA = 0.85;
        cjgui_linux_builder_rect_painted(builder, transform, rx, ry, rs, ring,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         0.25, 0.50, 0.85, ringA);
        cjgui_linux_builder_rect_painted(builder, transform, rx, ry + rs - ring, rs, ring,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         0.25, 0.50, 0.85, ringA);
        cjgui_linux_builder_rect_painted(builder, transform, rx, ry + ring, ring, rs - ring * 2.0,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         0.25, 0.50, 0.85, ringA);
        cjgui_linux_builder_rect_painted(builder, transform, rx + rs - ring, ry + ring, ring,
                                         rs - ring * 2.0,
                                         clipLeft, clipTop, clipRight, clipBottom, aperture,
                                         0.25, 0.50, 0.85, ringA);
    }
    if (outTextLeft) *outTextLeft = boxX + side + 8.0 * scale;
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

// Convert a convex outline to inward half-planes. Orientation is derived from
// the centroid instead of assuming a winding, so either outline direction is
// accepted.
static uint32_t cjgui_linux_point_polygon_planes(const CjguiLinuxPoint2D *points, uint32_t count,
                                                 CjguiLinuxClipPlane *planes, uint32_t capacity) {
    if (points == NULL || planes == NULL || count < 3u) return 0u;
    double centroidX = 0.0, centroidY = 0.0;
    for (uint32_t i = 0u; i < count; i += 1u) {
        centroidX += points[i].x;
        centroidY += points[i].y;
    }
    centroidX /= (double)count;
    centroidY /= (double)count;
    uint32_t planeCount = 0u;
    for (uint32_t i = 0u; i < count; i += 1u) {
        const CjguiLinuxPoint2D *a = &points[i];
        const CjguiLinuxPoint2D *b = &points[(i + 1u) % count];
        double nx = -(b->y - a->y);
        double ny = b->x - a->x;
        double length = sqrt(nx * nx + ny * ny);
        if (length < 1e-9) continue;
        nx /= length;
        ny /= length;
        double d = nx * a->x + ny * a->y;
        if (nx * centroidX + ny * centroidY < d) {
            nx = -nx; ny = -ny; d = -d;
        }
        if (planeCount >= capacity) return 0u;
        planes[planeCount].nx = nx;
        planes[planeCount].ny = ny;
        planes[planeCount].d = d;
        planeCount += 1u;
    }
    return planeCount;
}

static uint32_t cjgui_linux_clip_point_polygon_plane(const CjguiLinuxPoint2D *input, uint32_t count,
                                                     CjguiLinuxPoint2D *output,
                                                     const CjguiLinuxClipPlane *plane) {
    if (input == NULL || output == NULL || plane == NULL || count == 0u) return 0u;
    uint32_t outCount = 0u;
    for (uint32_t i = 0u; i < count; i += 1u) {
        const CjguiLinuxPoint2D *current = &input[i];
        const CjguiLinuxPoint2D *next = &input[(i + 1u) % count];
        double currentValue = plane->nx * current->x + plane->ny * current->y - plane->d;
        double nextValue = plane->nx * next->x + plane->ny * next->y - plane->d;
        int currentInside = currentValue >= 0.0;
        int nextInside = nextValue >= 0.0;
        if (currentInside) {
            if (outCount >= CJGUI_LINUX_CLIP_POINT_CAPACITY) return 0u;
            output[outCount++] = *current;
        }
        if (currentInside == nextInside) continue;
        double delta = nextValue - currentValue;
        if (delta == 0.0) continue;
        double t = -currentValue / delta;
        if (t < 0.0) t = 0.0;
        if (t > 1.0) t = 1.0;
        if (outCount >= CJGUI_LINUX_CLIP_POINT_CAPACITY) return 0u;
        output[outCount].x = current->x + (next->x - current->x) * t;
        output[outCount].y = current->y + (next->y - current->y) * t;
        outCount += 1u;
    }
    return outCount;
}

// The accepted layout already carries every clipping ancestor's full rounded
// rectangle. Intersect those rounded rectangles with the conservative axis
// bounds and expose the result as one convex aperture for all node paint.
static int cjgui_linux_slot_clip_aperture(const CjguiLinuxNodeSlot *slot, double deviceScale,
                                          double left, double top, double right, double bottom,
                                          CjguiLinuxClipAperture *out) {
    if (out == NULL) return 0;
    memset(out, 0, sizeof(*out));
    if (slot == NULL || !(deviceScale > 0.0)) return 0;
    if (!(right > left) || !(bottom > top)) return 0;
    const CjguiInternalRendererComposableNode *node = &slot->node;
    uint32_t count = node->clipConstraintCount;
    if (count > 4u) count = 0u;
    int hasRounded = 0;
    if (count == 0u) {
        if (node->clipWidth > 0 && node->clipHeight > 0 && node->clipCornerRadius > 0.0) {
            hasRounded = 1;
        }
    } else {
        for (uint32_t index = 0u; index < count; index += 1u) {
            double radius = 0.0;
            switch (index) {
                case 0u: radius = node->clip0CornerRadius; break;
                case 1u: radius = node->clip1CornerRadius; break;
                case 2u: radius = node->clip2CornerRadius; break;
                default: radius = node->clip3CornerRadius; break;
            }
            if (radius > 0.0) hasRounded = 1;
        }
    }
    if (!hasRounded) return 0;
    CjguiLinuxPoint2D polygonA[CJGUI_LINUX_CLIP_POINT_CAPACITY];
    CjguiLinuxPoint2D polygonB[CJGUI_LINUX_CLIP_POINT_CAPACITY];
    CjguiLinuxPoint2D *current = polygonA;
    CjguiLinuxPoint2D *next = polygonB;
    current[0].x = left;  current[0].y = top;
    current[1].x = right; current[1].y = top;
    current[2].x = right; current[2].y = bottom;
    current[3].x = left;  current[3].y = bottom;
    uint32_t currentCount = 4u;
    for (uint32_t index = 0u; index < (count == 0u ? 1u : count); index += 1u) {
        double clipX = 0.0, clipY = 0.0, clipWidth = 0.0, clipHeight = 0.0;
        double radius = 0.0;
        double ownerX = 0.0, ownerY = 0.0;
        if (count == 0u) {
            clipX = (double)node->clipX; clipY = (double)node->clipY;
            clipWidth = (double)node->clipWidth; clipHeight = (double)node->clipHeight;
            radius = node->clipCornerRadius;
        } else {
            switch (index) {
                case 0u:
                    clipX = (double)node->clip0X; clipY = (double)node->clip0Y;
                    clipWidth = (double)node->clip0Width; clipHeight = (double)node->clip0Height;
                    radius = node->clip0CornerRadius;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip0X; ownerY = slot->geometry.clip0Y; }
                    break;
                case 1u:
                    clipX = (double)node->clip1X; clipY = (double)node->clip1Y;
                    clipWidth = (double)node->clip1Width; clipHeight = (double)node->clip1Height;
                    radius = node->clip1CornerRadius;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip1X; ownerY = slot->geometry.clip1Y; }
                    break;
                case 2u:
                    clipX = (double)node->clip2X; clipY = (double)node->clip2Y;
                    clipWidth = (double)node->clip2Width; clipHeight = (double)node->clip2Height;
                    radius = node->clip2CornerRadius;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip2X; ownerY = slot->geometry.clip2Y; }
                    break;
                default:
                    clipX = (double)node->clip3X; clipY = (double)node->clip3Y;
                    clipWidth = (double)node->clip3Width; clipHeight = (double)node->clip3Height;
                    radius = node->clip3CornerRadius;
                    if (slot->geometryPresent) { ownerX = slot->geometry.clip3X; ownerY = slot->geometry.clip3Y; }
                    break;
            }
        }
        if (!(clipWidth > 0.0) || !(clipHeight > 0.0) || !(radius > 0.0)) continue;
        CjguiLinuxPoint2D outline[4u * CJGUI_LINUX_RADIUS_SEGMENTS];
        uint32_t outlineCount = cjgui_linux_rounded_outline(
            (clipX + ownerX) * deviceScale, (clipY + ownerY) * deviceScale,
            clipWidth * deviceScale, clipHeight * deviceScale,
            radius * deviceScale, radius * deviceScale, radius * deviceScale, radius * deviceScale,
            outline, (uint32_t)(sizeof(outline) / sizeof(outline[0])));
        CjguiLinuxClipPlane planes[4u * CJGUI_LINUX_RADIUS_SEGMENTS + 4u];
        uint32_t planeCount = cjgui_linux_point_polygon_planes(
            outline, outlineCount, planes, (uint32_t)(sizeof(planes) / sizeof(planes[0])));
        if (planeCount == 0u) continue;
        for (uint32_t plane = 0u; plane < planeCount; plane += 1u) {
            currentCount = cjgui_linux_clip_point_polygon_plane(current, currentCount, next,
                                                                &planes[plane]);
            if (currentCount < 3u) {
                memset(out, 0, sizeof(*out));
                out->empty = 1;
                return 0;
            }
            CjguiLinuxPoint2D *swap = current;
            current = next;
            next = swap;
        }
    }
    out->count = cjgui_linux_point_polygon_planes(current, currentCount, out->planes,
                                                  CJGUI_LINUX_CLIP_PLANE_CAPACITY);
    if (out->count == 0u) {
        out->empty = 1;
        return 0;
    }
    out->active = 1;
    return 1;
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
        // Rounded fill/stroke, corner radii and the rounded ancestor aperture
        // are painted by the CPU geometry below; the triangle pipeline itself
        // stays unchanged and samples the same atlas.
        CjguiLinuxPaintTransform transform = cjgui_linux_slot_paint_transform(slot, scale);
        CjguiLinuxClipAperture aperture;
        (void)cjgui_linux_slot_clip_aperture(slot, scale, clipX, clipY, clipRight, clipBottom,
                                             &aperture);
        if (aperture.empty) continue;
        double cornerTopLeft = 0.0, cornerTopRight = 0.0, cornerBottomRight = 0.0, cornerBottomLeft = 0.0;
        cjgui_linux_node_corner_radii(node, &cornerTopLeft, &cornerTopRight,
                                      &cornerBottomRight, &cornerBottomLeft);
        int roundedShape = cornerTopLeft > 0.0 || cornerTopRight > 0.0 ||
                           cornerBottomRight > 0.0 || cornerBottomLeft > 0.0;
        int hasGradient = cjgui_linux_node_has_gradient(node);
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
        if (roundedShape || hasGradient) {
            // The rounded outline carries both the shape and the gradient
            // ramp; gradient replaces the flat fill exactly as on macOS.
            if (node->fillAlpha > 0.0 || hasGradient) {
                cjgui_linux_builder_rounded_fill(builder, node, &transform, x, y, width, height,
                                                 clipX, clipY, clipRight, clipBottom, &aperture);
            }
        } else if (node->fillAlpha > 0.0) {
            if (transform.active) {
                // 旋转/缩放下的填充按整块四边形提交，再对设备像素 clip 做凸多边形
                // 裁剪；未旋转节点仍走原来的"先相交再画"路径，字节不变。
                cjgui_linux_builder_rect_painted(builder, &transform, x, y, width, height,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->fillRed, node->fillGreen, node->fillBlue, node->fillAlpha);
            } else if (fillRight > fillLeft && fillBottom > fillTop) {
                if (aperture.active) {
                    cjgui_linux_builder_rect_clipped(builder, fillLeft, fillTop,
                                                     fillRight - fillLeft, fillBottom - fillTop,
                                                     clipX, clipY, clipRight, clipBottom, &aperture,
                                                     node->fillRed, node->fillGreen,
                                                     node->fillBlue, node->fillAlpha);
                } else {
                    cjgui_linux_builder_rect(builder, fillLeft, fillTop, fillRight - fillLeft,
                                             fillBottom - fillTop,
                                             node->fillRed, node->fillGreen, node->fillBlue, node->fillAlpha);
                }
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
            if (roundedShape) {
                cjgui_linux_builder_rounded_border(builder, node, &transform, x, y, width, height,
                                                   thickness, clipX, clipY, clipRight, clipBottom,
                                                   &aperture);
            } else if (transform.active) {
                // 边框四条边同样按节点自己的变换提交，并由多边形裁剪收口。
                double tx0 = x, ty0 = y, tx1 = x + width, ty1 = y + height;
                cjgui_linux_builder_rect_painted(builder, &transform, tx0, ty0, tx1 - tx0, thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_painted(builder, &transform, tx0, ty1 - thickness, tx1 - tx0, thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_painted(builder, &transform, tx0, ty0 + thickness, thickness,
                                                 (ty1 - ty0) - 2.0 * thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_painted(builder, &transform, tx1 - thickness, ty0 + thickness,
                                                 thickness, (ty1 - ty0) - 2.0 * thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
            } else if (bx1 > bx0 && by1 > by0) {
                cjgui_linux_builder_rect_clipped(builder, bx0, by0, bx1 - bx0, thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_clipped(builder, bx0, by1 - thickness, bx1 - bx0, thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_clipped(builder, bx0, by0 + thickness, thickness,
                                                 (by1 - by0) - 2.0 * thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
                cjgui_linux_builder_rect_clipped(builder, bx1 - thickness, by0 + thickness, thickness,
                                                 (by1 - by0) - 2.0 * thickness,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 node->borderRed, node->borderGreen, node->borderBlue, node->borderAlpha);
            }
        }
        if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE &&
            slot->imageResourcePath != NULL && slot->imageResourcePath[0] != '\0') {
            uint32_t sourceWidth = 0u, sourceHeight = 0u, imageSlot = UINT32_MAX;
            if (cjgui_linux_image_texture(session->image, slot->imageResourcePath,
                                          slot->imageResourceId, slot->imageResourceVersion,
                                          &sourceWidth, &sourceHeight, &imageSlot) &&
                imageSlot != UINT32_MAX && sourceWidth > 0u && sourceHeight > 0u) {
                double sourceW = (double)sourceWidth;
                double sourceH = (double)sourceHeight;
                double fit = node->imageContentMode == 2u
                                 ? fmax(width / sourceW, height / sourceH)
                                 : fmin(width / sourceW, height / sourceH);
                double drawWidth = sourceW * fit;
                double drawHeight = sourceH * fit;
                double drawX = x + (width - drawWidth) * 0.5;
                double drawY = y + (height - drawHeight) * 0.5;
                double tintRed = node->iconTintAlpha > 0.0 ? node->iconTintRed : 1.0;
                double tintGreen = node->iconTintAlpha > 0.0 ? node->iconTintGreen : 1.0;
                double tintBlue = node->iconTintAlpha > 0.0 ? node->iconTintBlue : 1.0;
                double tintAlpha = node->iconTintAlpha > 0.0 ? node->iconTintAlpha : 1.0;
                builder->desiredSlot = imageSlot;
                cjgui_linux_builder_painted_quad(builder, &transform, drawX, drawY,
                                                 drawX + drawWidth, drawY + drawHeight,
                                                 0.0, 0.0, 1.0, 1.0,
                                                 clipX, clipY, clipRight, clipBottom, &aperture,
                                                 tintRed, tintGreen, tintBlue, tintAlpha);
                builder->desiredSlot = UINT32_MAX;
                // 图像纹理已覆盖节点内容；文字字段对图片节点没有正文，继续
                // 走原有文字路径只会是空串。
            }
        }
        int isBoolean = node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT;
        double booleanTextLeft = 0.0;
        if (isBoolean) {
            cjgui_linux_paint_boolean(session, builder, slot, &transform, boxLeft, boxTop,
                                      boxRight, boxBottom, scale, clipX, clipY, clipRight,
                                      clipBottom, &aperture, &booleanTextLeft);
        }
        const char *body = cjgui_linux_node_body(slot);
        double textAlpha = node->textAlpha;
        if (isBoolean && (node->isInteractive == 0u || node->isReadOnly != 0u)) {
            textAlpha *= 0.55;
        }
        if (!body || !body[0] || textAlpha <= 0.0) continue;
        // 全部按设备像素做，避免逻辑/设备两套坐标混算：文字模块只把 fontSize 当
        // 像素尺寸用，所以这里直接传 scale 后的值，clip 与 maxWidth 也用设备像素。
        int multiline = node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        double deviceInset = 6.0 * scale;
        double textLeft = isBoolean ? booleanTextLeft : (boxLeft + deviceInset);
        double textRight = boxRight - deviceInset;
        if (textRight <= textLeft) continue;
        // maxLines/textOverflow are real paint limits here: the layout prefix is
        // cut at line maxLines and an enabled ellipsis replaces the visible tail
        // with U+2026. The semantic node value stays the full original string.
        uint32_t lineLimit = node->maxLines;
        int ellipsis = node->ellipsisEnabled != 0u;
        if (lineLimit == 0u && ellipsis) lineLimit = 1u;
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
                                                     clipX, clipY, clipRight, clipBottom, &aperture,
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
        if (composed == NULL && slot->encodedRuns != NULL && slot->encodedRuns[0] != '\0') {
            cjgui_linux_builder_styled_text(builder, session->text, drawBody, slot->encodedRuns,
                                            fontSizeDevice, node->fontWeight, node->fontFamily,
                                            textRight - textLeft, textLeft, originY, clipX, clipY,
                                            clipRight, clipBottom, &aperture,
                                            node->textRed, node->textGreen, node->textBlue,
                                            textAlpha, transform.active ? &transform : NULL,
                                            lineLimit, ellipsis);
        } else {
            cjgui_linux_builder_text(builder, session->text, drawBody, fontSizeDevice,
                                     node->fontWeight, node->fontFamily, textRight - textLeft,
                                     textLeft, originY, clipX, clipY, clipRight, clipBottom,
                                     &aperture, node->textRed, node->textGreen, node->textBlue,
                                     textAlpha, transform.active ? &transform : NULL, lineLimit,
                                     ellipsis);
        }
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
                                                     clipX, clipY, clipRight, clipBottom, &aperture,
                                                     0.15, 0.35, 0.90, 1.0);
                }
                // The preedit caret is a character index inside the preedit,
                // not "the end of the string". Map it through UTF-16 to the
                // composed body and use the same layout position for both the
                // visible bar and the system candidate spot.
                uint32_t preeditUnits = cjgui_linux_utf16_length(
                    session->compositionText, session->compositionTextLength);
                uint32_t caret16 = session->compositionCaret16 > preeditUnits
                                       ? preeditUnits
                                       : session->compositionCaret16;
                uint32_t caretAbsolute16 = session->compositionStart16 + caret16;
                size_t caretByte = cjgui_linux_byte_offset_for_utf16(
                    drawBody, drawLength, caretAbsolute16);
                double xc = x1, topc = top1, lineHeightC = lineHeight;
                uint32_t lineIndexC = 0u;
                size_t lineStartC = 0u, lineEndC = 0u;
                int caretMapped =
                    cjgui_linux_text_caret_position(session->text, drawBody, drawLength, fontSizePoints,
                                                    node->fontWeight, node->fontFamily,
                                                    node->width - 12.0, caretByte, &xc, &topc,
                                                    &lineHeightC, &lineIndexC, &lineStartC,
                                                    &lineEndC) == CJGUI_LINUX_TEXT_OK;
                if (caretMapped) {
                    double caretHeightDevice = lineHeightC * scale;
                    if (caretHeightDevice <= 0.0) caretHeightDevice = lineHeightDevice;
                    cjgui_linux_builder_rect_painted(builder, &transform,
                                                     textLeft + xc * scale,
                                                     originY + topc * scale,
                                                     1.5 * scale, caretHeightDevice,
                                                     clipX, clipY, clipRight, clipBottom, &aperture,
                                                     0.10, 0.10, 0.10, 1.0);
                }
                // 候选窗定位消费同一份光标几何：使用真实 preedit caret 所在行，
                // 而不是把整个预编辑串的末尾当光标。绘制坐标是设备像素，
                // set_ime_spot 收窗口逻辑点（内部再乘 scale）。
                // 旋转/缩放节点的候选位置仍按未变换的光标几何上报（输入法定位不随
                // 旋转，和 macOS 一致；这里不作为已验证能力宣传）。
                if (scale > 0.0) {
                    double spotX = textLeft / scale + xc;
                    double spotY = (originY + topc * scale + lineHeightC * scale) / scale;
                    cjgui_linux_window_set_ime_spot(session->window, spotX, spotY, lineHeightC);
                }
            }
            free(composed);
        }
    }
    // 输入光标条：由共同层每轮用已接受布局重新声明；nodeId<0 表示撤回。
    // 组合期间由 preedit caret 条接管，避免在替换段起点再画一条旧 caret，
    // 让用户误以为组合光标在那里。
    if (!session->compositionActive && session->caretNodeId >= 0 &&
        session->caretWidth > 0.0 && session->caretHeight > 0.0) {
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
    session->image = cjgui_linux_image_domain_create(session->gpu, session->window);
    if (!session->image) {
        cjgui_linux_gpu_destroy(session->gpu);
        cjgui_linux_text_destroy(session->text);
        cjgui_linux_window_destroy(session->window);
        memset(session, 0, sizeof(*session));
        if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_APP_INIT_FAILED;
        return token;
    }
    session->token = g_nextToken++;
    session->alive = 1;
    cjgui_linux_aux_on_create(slot);
    cjgui_linux_installed_range_on_create(slot);
    cjgui_linux_owner_bind_window(session->window);
    if (outStatus) *outStatus = CJGUI_INTERNAL_RENDERER_OK;
    return session->token;
}

CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t sessionToken) {
    int slot = cjgui_linux_session_slot(sessionToken);
    if (slot < 0) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiLinuxSession *session = &g_sessions[slot];
    // 顺序固定：停止图片 worker 并回收其纹理 → 停止提交 → 等待设备空闲 →
    // 销毁交换链与图像 → 管线/图集 → device → surface → instance；窗口在
    // GPU 之后释放（surface 依赖 X 连接）。图片域必须在 GPU/窗口之前销毁，
    // 否则 worker 完成唤醒会触碰已释放的窗口。
    // Unbind before the image workers and window go away: a transport notify
    // on another thread must never write into a freed wake pipe.
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_RENDERER_DESTROY slot=%d token=%llu gpu=%p window=%p\n",
                slot, (unsigned long long)session->token, (void *)session->gpu,
                (void *)session->window);
        fflush(stderr);
    }
    if (session->window) cjgui_linux_owner_unbind_window(session->window);
    if (session->image) cjgui_linux_image_domain_destroy(session->image);
    if (session->gpu) {
        cjgui_linux_gpu_destroy(session->gpu);
        // Ownership is released exactly once: a stale pointer must never make a
        // second close look like a valid teardown.
        session->gpu = NULL;
    }
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
    // requestClose 是会话级关闭：只给本窗口立闩锁。进程级 application-stop
    // 只属于 stopApplicationLoop；在这里置位会把另一个窗口的泵变成
    // APPLICATION_EXIT_REQUESTED，多窗口下表现为关掉预览后主窗不再处理输入。
    cjgui_linux_window_request_close(session->window);
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
static CjguiLinuxNodeSlot *cjgui_linux_focused_slot(CjguiLinuxSession *session);
static CjguiInternalRendererStatus cjgui_linux_hit_test_text_body(CjguiLinuxSession *session,
                                                                  const CjguiLinuxNodeSlot *slot,
                                                                  const char *body, double x, double y,
                                                                  uint32_t *outByteOffset,
                                                                  uint32_t *outAffinity);

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

// Shared paint path for the public present and the composition-only repaint.
// The latter must not turn a styled menu or a pending scene candidate into an
// accepted state just because a preedit update needs a frame.
static CjguiInternalRendererStatus cjgui_linux_present_scene(
    CjguiLinuxSession *session, CjguiInternalRendererFrameObservation *outObservation,
    int promotePending) {
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 提交点。共同层有两条场景路径：
    //   * 私有准备：begin → prepare×N → advance → configure → **promote**（promote 里已提交，
    //     提交后 candidate 被移走、invalid，所以这里不会再提交一次）；
    //   * 直接路径：**configure → set_node×N → present**，没有 promote。
    // 直接路径的提交点就是 present。漏掉它时 accepted 永远为空——实测症状：
    // 通知阈值窗口 configure_scene nodes=24、measure 3185 次，但
    // `CJGUI_LINUX_PRESENT frame=0 nodes=0 vertices=6 accepted=0 candidate=1`，
    // 窗口只画出背景。任何不走私有准备的消费者都会这样。
    // 命令菜单在本代场景提交时一起提升。此前只有语义接受路径会 commit，
    // 普通 present 只把菜单留在 staging：首帧后、下一次刷新前的真实快捷键
    // 会被误判为未声明。先提升菜单再接受场景；两者在这里是同一接受点，
    // 菜单失败时场景尚未接受，仍可整体拒绝。
    if (promotePending) {
        if (cjgui_linux_aux_command_menu_staged(session->token)) {
            CjguiInternalRendererStatus menuStatus =
                cjgui_internal_renderer_commit_composable_command_menu(session->token);
            if (menuStatus != CJGUI_INTERNAL_RENDERER_OK) return menuStatus;
        }
        if (session->candidate.valid && !session->preparationActive) {
            (void)cjgui_linux_commit_candidate(session);
        }
    }
    if (getenv("CJGUI_LINUX_PRESENT_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_PRESENT_ENTER frame=%llu nodes=%u\n", (unsigned long long)session->frameIndex,
                session->accepted.nodeCount);
    }

    // 先把 worker 已完成的结果上传为纹理；上传发生在 begin_frame 之外，
    // 不与在途帧争用命令缓冲。
    cjgui_linux_image_pump(session->image);

    CjguiLinuxVertexBuilder builder;
    memset(&builder, 0, sizeof(builder));
    builder.desiredSlot = UINT32_MAX;
    cjgui_linux_append_background(session, &builder);
    cjgui_linux_append_scene(session, &builder);
    // 文本整形会在 append_scene 中把本帧首次出现的字形写进图集。上传必须在
    // 整形之后：否则本轮新增字形要等下一次 present 才进纹理，而外部 owner
    // 更新等一次性刷新之后窗口会静置，新正文就一直显示为空，直到下一次输入。
    cjgui_linux_upload_atlas(session);
    if (builder.failed) {
        cjgui_linux_builder_release(&builder);
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
        cjgui_linux_builder_release(&builder);
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    if (status != CJGUI_LINUX_GPU_OK) {
        cjgui_linux_builder_release(&builder);
        cjgui_linux_fill_observation(session, outObservation);
        return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
    }
    if (getenv("CJGUI_LINUX_PRESENT_TRACE") && (session->frameIndex % 600u) == 0u) {
        fprintf(stderr, "CJGUI_LINUX_PRESENT frame=%llu nodes=%u vertices=%u accepted=%d candidate=%d\n",
                (unsigned long long)session->frameIndex, session->accepted.nodeCount, builder.count,
                session->accepted.valid, session->candidate.valid);
    }
    if (builder.count > 0u) {
        int drawStatus = CJGUI_LINUX_GPU_OK;
        for (uint32_t i = 0u; i < builder.segmentCount; i += 1u) {
            CjguiLinuxDrawSegment *segment = &builder.segments[i];
            if (segment->vertexCount == 0u) continue;
            const CjguiLinuxGpuVertex *vertices = builder.vertices + segment->firstVertex;
            if (segment->imageSlot == UINT32_MAX) {
                drawStatus = cjgui_linux_gpu_draw_triangles(session->gpu, vertices, segment->vertexCount);
            } else {
                drawStatus = cjgui_linux_gpu_draw_image_triangles(session->gpu, segment->imageSlot,
                                                                  vertices, segment->vertexCount);
            }
            if (drawStatus != CJGUI_LINUX_GPU_OK) break;
        }
        if (drawStatus != CJGUI_LINUX_GPU_OK) {
            cjgui_linux_builder_release(&builder);
            cjgui_linux_fill_observation(session, outObservation);
            return CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE;
        }
    }
    cjgui_linux_builder_release(&builder);
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
    return cjgui_linux_present_scene(session, outObservation, 1);
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

static CjguiLinuxNodeSlot *cjgui_linux_accepted_slot(CjguiLinuxSession *session, uint64_t nodeId) {
    if (!session || !session->accepted.valid) return NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        if (session->accepted.slots[i].node.nodeId == nodeId) return &session->accepted.slots[i];
    }
    return NULL;
}

static int cjgui_linux_is_editable_text_kind(uint32_t nodeKind) {
    return nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
}

// The same tab-stop vocabulary the macOS overlay uses. Native only carries
// accepted identity/scope/geometry; Cangjie remains the focus semantics owner.
static int cjgui_linux_is_keyboard_focus_kind(uint32_t nodeKind) {
    return cjgui_linux_is_editable_text_kind(nodeKind) ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER ||
           nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER;
}

static int cjgui_linux_slot_keyboard_focusable(const CjguiLinuxNodeSlot *slot) {
    if (!slot || !slot->node.isInteractive || slot->node.isReadOnly) return 0;
    if (slot->node.width <= 0 || slot->node.height <= 0) return 0;
    return cjgui_linux_is_keyboard_focus_kind(slot->node.nodeKind);
}

static void cjgui_linux_focus_clear(CjguiLinuxSession *session) {
    session->focusActive = 0;
    session->focusNodeId = 0u;
    session->focusResourceId = -1;
    session->focusNodeKind = 0u;
}

static void cjgui_linux_focus_set(CjguiLinuxSession *session, const CjguiLinuxNodeSlot *slot) {
    session->focusActive = 1;
    session->focusNodeId = slot->node.nodeId;
    session->focusResourceId = slot->node.resourceId;
    session->focusNodeKind = slot->node.nodeKind;
}

static void cjgui_linux_repaint_composition_frame(CjguiLinuxSession *session);

// End the preedit identity. A stale terminal must still clear the visible
// preedit; it may not attach the old start/length to whichever proxy is
// current now.
static int cjgui_linux_composition_clear(CjguiLinuxSession *session) {
    if (session == NULL) return 0;
    int wasActive = session->compositionActive;
    session->compositionActive = 0;
    session->compositionId = 0u;
    session->compositionStart16 = 0u;
    session->compositionLength16 = 0u;
    session->compositionReplaceLength16 = 0u;
    session->compositionTextLength = 0u;
    session->compositionText[0] = '\0';
    session->compositionBaseHash = 0u;
    session->compositionNodeId = 0u;
    session->compositionResourceId = -1;
    session->compositionNodeKind = 0u;
    session->compositionBindingEpoch = 0u;
    session->compositionCaret16 = 0u;
    session->compositionOwned = 0;
    return wasActive;
}

// The frozen target must still be the live proxy, the same declaration epoch,
// and the same accepted node. A style-only scene refresh keeps all of these;
// focus switching, rebinding or removal does not.
static int cjgui_linux_composition_target_matches(CjguiLinuxSession *session) {
    if (session == NULL || !session->compositionActive || !session->proxy.active) return 0;
    if (session->proxy.nodeId != session->compositionNodeId ||
        session->proxy.resourceId != session->compositionResourceId ||
        session->proxy.nodeKind != session->compositionNodeKind ||
        session->proxy.bindingEpoch != session->compositionBindingEpoch) {
        return 0;
    }
    const CjguiLinuxNodeSlot *slot = cjgui_linux_accepted_slot(session, session->compositionNodeId);
    if (slot == NULL || slot->node.resourceId != session->compositionResourceId ||
        slot->node.nodeKind != session->compositionNodeKind) {
        return 0;
    }
    if (session->compositionOwned) {
        if (!session->ownedTextSessionEnabled ||
            session->ownedTextSessionNodeId != session->compositionNodeId ||
            session->ownedTextSessionResourceId != session->compositionResourceId ||
            session->ownedTextSessionNodeKind != session->compositionNodeKind ||
            session->ownedTextSessionBindingEpoch != session->compositionBindingEpoch) {
            return 0;
        }
    }
    return 1;
}

static void cjgui_linux_proxy_release(CjguiLinuxSession *session) {
    if (!session) return;
    cjgui_linux_composition_clear(session);
    cjgui_linux_strfree(&session->proxy.value);
    memset(&session->proxy, 0, sizeof(session->proxy));
}

// A binding declaration can change without the proxy being released. End a
// preedit whose frozen target no longer matches the live declaration; a
// same-target declaration refresh (style/layout only) keeps it alive.
// Returns 1 when an active preedit was dropped and needs an erase frame.
static int cjgui_linux_composition_revalidate(CjguiLinuxSession *session) {
    if (session == NULL || !session->compositionActive) return 0;
    if (cjgui_linux_composition_target_matches(session)) return 0;
    (void)cjgui_linux_composition_clear(session);
    return 1;
}

// Ordinary focus installs the same native edit proxy an owned text session gets.
// Identity and body come from the accepted scene; edits still flow through the
// existing TEXT_CHANGED / RANGE_CHANGED channel. A retired, disabled, read-only
// or identity-changed node clears the proxy so keys never reach a dead target.
static void cjgui_linux_sync_ordinary_proxy(CjguiLinuxSession *session) {
    if (!session || !session->proxy.active || !session->proxy.ordinary) return;
    CjguiLinuxNodeSlot *slot = cjgui_linux_accepted_slot(session, session->proxy.nodeId);
    if (!slot || slot->node.resourceId != session->proxy.resourceId ||
        slot->node.nodeKind != session->proxy.nodeKind || !slot->node.isInteractive ||
        slot->node.isReadOnly || !cjgui_linux_is_editable_text_kind(slot->node.nodeKind)) {
        uint64_t nodeId = session->proxy.nodeId;
        int64_t resourceId = session->proxy.resourceId;
        uint32_t nodeKind = session->proxy.nodeKind;
        cjgui_linux_proxy_release(session);
        if (session->focusActive && session->focusNodeId == nodeId &&
            session->focusResourceId == resourceId && session->focusNodeKind == nodeKind) {
            cjgui_linux_focus_clear(session);
        }
        return;
    }
    if (slot->node.preservesActiveLocalText) {
        // The owner just accepted this proxy's edit and intentionally did not
        // echo the complete body; the proxy's newer text stays authoritative.
        session->proxy.sceneVersion = session->accepted.projectionVersion;
        return;
    }
    const char *accepted = slot->value ? slot->value : "";
    if (!session->proxy.value || strcmp(session->proxy.value, accepted) != 0) {
        cjgui_linux_replace(&session->proxy.value, accepted);
        uint32_t units = cjgui_linux_utf16_length(accepted, strlen(accepted));
        if (session->proxy.selectionStart16 > units) session->proxy.selectionStart16 = units;
        if (session->proxy.selectionEnd16 > units) session->proxy.selectionEnd16 = units;
        if (session->proxy.selectionEnd16 < session->proxy.selectionStart16)
            session->proxy.selectionEnd16 = session->proxy.selectionStart16;
    }
    session->proxy.sceneVersion = session->accepted.projectionVersion;
}

static void cjgui_linux_request_slot_image(CjguiLinuxSession *session, const CjguiLinuxNodeSlot *slot) {
    if (session == NULL || session->image == NULL || slot == NULL) return;
    if (slot->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) return;
    if (slot->imageResourcePath == NULL || slot->imageResourcePath[0] == '\0') return;
    (void)cjgui_linux_image_prepare(session->image, slot->imageResourcePath, slot->imageResourceId,
                                    slot->imageResourceVersion);
}

// Accepted 场景是缓存引用的唯一权威：候选提交后按整棵已接受场景重建引用，
// 旧版本资源因此可以安全淘汰，而当前显示的资源不会被忙碌/超限淘汰。
static void cjgui_linux_refresh_image_references(CjguiLinuxSession *session) {
    if (session == NULL || session->image == NULL) return;
    cjgui_linux_image_clear_references(session->image);
    if (!session->accepted.valid) return;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        if (slot->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) continue;
        if (slot->imageResourcePath == NULL || slot->imageResourcePath[0] == '\0') continue;
        cjgui_linux_image_add_reference(session->image, slot->imageResourcePath, slot->imageResourceId,
                                        slot->imageResourceVersion);
    }
}

// 场景提交后，声明表只保留仍在新已接受场景里的节点：被移除或换代的节点声明
// 不回收，长会话里 runCount 会随场景代数增长，最终把有效节点挤出容量。
static void cjgui_linux_prune_run_declarations(CjguiLinuxSession *session) {
    if (session == NULL || session->runCount == 0u) return;
    uint32_t kept = 0u;
    for (uint32_t i = 0u; i < session->runCount; i += 1u) {
        int present = 0;
        for (uint32_t n = 0u; n < session->accepted.nodeCount; n += 1u) {
            if (session->accepted.slots[n].node.nodeId == session->runs[i].nodeId) {
                present = 1;
                break;
            }
        }
        if (!present) {
            cjgui_linux_strfree(&session->runs[i].encoded);
            continue;
        }
        if (kept != i) session->runs[kept] = session->runs[i];
        kept += 1u;
    }
    for (uint32_t i = kept; i < session->runCount; i += 1u) {
        session->runs[i].nodeId = 0u;
        session->runs[i].encoded = NULL;
    }
    session->runCount = kept;
}

static int cjgui_linux_commit_candidate(CjguiLinuxSession *session) {
    if (!session->candidate.valid) return 0;
    cjgui_linux_scene_move(&session->accepted, &session->candidate);
    session->accepted.valid = 1;
    if (getenv("CJGUI_LINUX_SCENE_TRACE")) {
        // Bounded geometry record for the exact rects the native hit test uses.
        // Node bounds are layout space; translate is the paint-alignment sidecar.
        uint32_t shown = 0u;
        for (uint32_t i = 0u; i < session->accepted.nodeCount && shown < 80u; i += 1u) {
            CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
            const CjguiInternalRendererComposableNode *node = &slot->node;
            if (node->nodeId == 0u) continue;
            fprintf(stderr,
                    "CJGUI_LINUX_SCENE node=%llu kind=%u x=%lld y=%lld w=%lld h=%lld "
                    "tx=%.1f ty=%.1f clip=%lld,%lld,%lld,%lld interactive=%d\n",
                    (unsigned long long)node->nodeId, node->nodeKind, (long long)node->x,
                    (long long)node->y, (long long)node->width, (long long)node->height,
                    cjgui_linux_slot_translate_x(slot), cjgui_linux_slot_translate_y(slot),
                    (long long)node->clipX, (long long)node->clipY, (long long)node->clipWidth,
                    (long long)node->clipHeight, node->isInteractive);
            shown += 1u;
        }
        fflush(stderr);
    }
    cjgui_linux_prune_run_declarations(session);
    session->preparationActive = 0;
    session->preparationId = 0u;
    cjgui_linux_refresh_image_references(session);
    cjgui_linux_sync_ordinary_proxy(session);
    if (session->focusActive) {
        CjguiLinuxNodeSlot *focus = cjgui_linux_focused_slot(session);
        if (!focus) cjgui_linux_focus_clear(session);
    }
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
    cjgui_linux_request_slot_image(session, slot);
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
    cjgui_linux_prune_run_declarations(session);
    session->preparationActive = 0;
    session->preparationId = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_discard_composable_scene_candidate(uint64_t sessionToken) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI discard_candidate\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    cjgui_linux_scene_reset(&session->candidate);
    cjgui_linux_prune_run_declarations(session);
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
    cjgui_linux_request_slot_image(session, slot);
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
    // 主线程先结算图片完成；若解码在 pump 期间完成，窗口自唤醒管道
    // 会让本轮泵立即返回，下一次 viewport 查询看到推进后的完成版本。
    cjgui_linux_image_pump(session->image);
    uint32_t width = 0u, height = 0u; int resized = 0;
    (void)cjgui_linux_window_size(session->window, &width, &height, &resized);
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI viewport w=%u h=%u\n", width, height);
    memset(outViewport, 0, sizeof(*outViewport));
    outViewport->width = width;
    outViewport->height = height;
    outViewport->resizeVersion = session->resizeVersion;
    // 契约：只有图片请求到达 ready/failed 才推进；帧号不是资源完成。
    outViewport->resourceCompletionVersion = cjgui_linux_image_completion_version(session->image);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_prepare_composable_image_resource(uint64_t sessionToken, const char *resourcePath,
                                                          const char *resourceId, uint64_t resourceVersion,
                                                          uint32_t *outState) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    cjgui_linux_image_pump(session->image);
    *outState = cjgui_linux_image_prepare(session->image, resourcePath, resourceId, resourceVersion);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_composable_image_resource_state(uint64_t sessionToken, const char *resourcePath,
                                                        const char *resourceId, uint64_t resourceVersion,
                                                        uint32_t *outState) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outState = cjgui_linux_image_state(session->image, resourcePath, resourceId, resourceVersion);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_probe_image_texture(uint64_t sessionToken, uint64_t nodeId, int32_t *outFound,
                                            int32_t *outHasTexture, int32_t *outCacheKeyLength,
                                            int32_t *outFailed) {
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outFound || !outHasTexture || !outCacheKeyLength || !outFailed) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    *outFound = 0;
    *outHasTexture = 0;
    *outCacheKeyLength = 0;
    *outFailed = 0;
    if (!session->accepted.valid) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        if (slot->node.nodeId != nodeId) continue;
        if (slot->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE) continue;
        uint32_t state = cjgui_linux_image_state(session->image, slot->imageResourcePath,
                                                 slot->imageResourceId, slot->imageResourceVersion);
        uint32_t width = 0u, height = 0u, gpuSlot = UINT32_MAX;
        int ready = state == CJGUI_LINUX_IMAGE_READY
                        ? cjgui_linux_image_texture(session->image, slot->imageResourcePath,
                                                    slot->imageResourceId, slot->imageResourceVersion,
                                                    &width, &height, &gpuSlot)
                        : 0;
        char key[8192];
        int keyLength = cjgui_linux_image_cache_key(slot->imageResourcePath, slot->imageResourceId,
                                                    slot->imageResourceVersion, key, sizeof(key))
                            ? (int)strlen(key)
                            : 0;
        *outFound = 1;
        *outHasTexture = (ready && gpuSlot != UINT32_MAX) ? 1 : 0;
        *outCacheKeyLength = keyLength;
        *outFailed = state == CJGUI_LINUX_IMAGE_FAILED ? 1 : 0;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
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

// Shared styled measurement for handwritten textStyleRuns and generated label
// textRuns. Both arrive as the same 14-field declaration; the result comes from
// the exact layout the paint path uses, so wrap/baseline/max-lines agree.
CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_styled_text(
    uint64_t sessionToken, const char *text, double fontSize, uint32_t fontWeight,
    uint32_t fontFamily, uint32_t maximumWidth, double letterSpacing, double lineHeight,
    uint32_t maximumLines, uint32_t overflow, const char *runs,
    CjguiInternalRendererTextMeasurement *outMeasurement) {
    (void)letterSpacing;
    (void)lineHeight;
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!text) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    CjguiLinuxParsedRuns parsed;
    size_t textLength = strlen(text);
    if (!cjgui_linux_parse_runs(runs, text, textLength, &parsed)) {
        return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    uint32_t quadCount = 0u, spanCount = 0u;
    double width = 0.0, height = 0.0, ascent = 0.0, resultLineHeight = 0.0;
    int status = cjgui_linux_text_styled_layout(
        session->text, text, textLength, fontSize, fontWeight, fontFamily, (double)maximumWidth,
        maximumLines, overflow != 0u ? 1 : 0, parsed.runs, parsed.count, 0.0, 0.0, 0, NULL, 0u,
        NULL, 0u, &quadCount, &spanCount, &width, &height, &ascent, &resultLineHeight);
    if (status != CJGUI_LINUX_TEXT_OK && status != CJGUI_LINUX_TEXT_BUDGET_EXCEEDED) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_ABI measure_styled FAIL status=%d bytes=%zu runs=%u\n",
                    status, textLength, parsed.count);
        }
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    session->textLayoutPreparationCount += 1u;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI measure_styled ok bytes=%zu runs=%u w=%.1f h=%.1f lh=%.1f\n",
                textLength, parsed.count, width, height, resultLineHeight);
    }
    if (outMeasurement) {
        memset(outMeasurement, 0, sizeof(*outMeasurement));
        outMeasurement->width = (uint32_t)(width + 0.5);
        outMeasurement->height = (uint32_t)(height + 0.5);
        outMeasurement->baseline = (uint32_t)(ascent + 0.5);
        outMeasurement->lineHeight = (uint32_t)(resultLineHeight + 0.5);
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
#define CJGUI_LINUX_XK_TAB       0xFF09u
#define CJGUI_LINUX_XK_ISO_LEFT_TAB 0xFE20u
#define CJGUI_LINUX_XK_RETURN    0xFF0Du
#define CJGUI_LINUX_XK_ESCAPE    0xFF1Bu
#define CJGUI_LINUX_XK_SPACE     0x0020u
#define CJGUI_LINUX_XK_HOME      0xFF50u
#define CJGUI_LINUX_XK_LEFT      0xFF51u
#define CJGUI_LINUX_XK_UP        0xFF52u
#define CJGUI_LINUX_XK_RIGHT     0xFF53u
#define CJGUI_LINUX_XK_DOWN      0xFF54u
#define CJGUI_LINUX_XK_END       0xFF57u
#define CJGUI_LINUX_XK_DELETE    0xFFFFu
#define CJGUI_LINUX_XK_MENU      0xFF67u
#define CJGUI_LINUX_XK_F10       0xFFC7u

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

static uint64_t cjgui_linux_text_hash(const char *text) {
    uint64_t hash = 1469598103934665603ull;
    if (text) {
        for (const unsigned char *cursor = (const unsigned char *)text; *cursor; cursor += 1) {
            hash ^= (uint64_t)*cursor;
            hash *= 1099511628211ull;
        }
    }
    return hash;
}

// IME 相位 -> 共同层 kind 52。首份 update 用选择起点冻结替换范围；后续 update
// 报告同一 marked 起点与上一份 preedit 长度；提交/取消终结同一身份。
static int cjgui_linux_emit_composition(CjguiLinuxSession *session, uint32_t phase,
                                        const char *text, uint32_t innerCaret16) {
    if (!session->proxy.active) {
        fprintf(stderr, "CJGUI_LINUX_COMPOSITION_REJECTED reason=no_text_proxy phase=%u\n", phase);
        if (phase != CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE) {
            (void)cjgui_linux_composition_clear(session);
            return 1;
        }
        return 0;
    }
    uint32_t text16 = text ? cjgui_linux_utf16_length(text, strlen(text)) : 0u;
    // Only a node with a real owned-session declaration consumes the kind-52
    // composition phase (the common window routes 52 through that session).
    // An ordinary proxy has no such consumer: its commit was silently dropped
    // while the native proxy already held the text, so the owner never saw the
    // edit. Fold ordinary commits into the same whole-value edit channel used
    // by typed text; cancel stays zero-write.
    const int ownedSession = session->ownedTextSessionEnabled &&
        session->ownedTextSessionNodeId == session->proxy.nodeId &&
        session->ownedTextSessionResourceId == session->proxy.resourceId &&
        session->ownedTextSessionNodeKind == session->proxy.nodeKind;
    if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE) {
        if (session->compositionActive) {
            if (!cjgui_linux_composition_target_matches(session)) {
                // Focus/rebind/removal happened while the preedit was open.
                // The next update belongs to a different target; do not
                // reinterpret the frozen range on it.
                if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
                    fprintf(stderr,
                            "CJGUI_LINUX_COMPOSITION_TARGET_CHANGED phase=update node=%llu action=drop\n",
                            (unsigned long long)session->compositionNodeId);
                }
                (void)cjgui_linux_composition_clear(session);
                return 0;
            }
        } else {
            session->compositionIdCounter += 1u;
            if (session->compositionIdCounter == 0u) session->compositionIdCounter = 1u;
            session->compositionId = session->compositionIdCounter;
            uint32_t a = session->proxy.selectionStart16;
            uint32_t b = session->proxy.selectionEnd16;
            if (a > b) { uint32_t swap = a; a = b; b = swap; }
            session->compositionStart16 = a;
            session->compositionLength16 = b - a;
            session->compositionReplaceLength16 = b - a;
            session->compositionBaseHash =
                cjgui_linux_text_hash(session->proxy.value ? session->proxy.value : "");
            session->compositionNodeId = session->proxy.nodeId;
            session->compositionResourceId = session->proxy.resourceId;
            session->compositionNodeKind = session->proxy.nodeKind;
            session->compositionBindingEpoch = session->proxy.bindingEpoch;
            session->compositionOwned = ownedSession;
            session->compositionCaret16 = 0u;
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
        session->compositionCaret16 = innerCaret16;
    } else {
        if (!session->compositionActive) {
            // 迟到的终态：共同层同样会按身份判重；这里不产生第二条意图。
            return 0;
        }
        if (!cjgui_linux_composition_target_matches(session)) {
            // The terminal belongs to the target frozen at composition start.
            // After a focus switch, rebind or removal it ends only that old
            // composition; it must not write the current proxy even when both
            // fields carry the same body text.
            if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
                fprintf(stderr,
                        "CJGUI_LINUX_COMPOSITION_STALE_TARGET phase=%u node=%llu action=drop\n",
                        phase, (unsigned long long)session->compositionNodeId);
            }
            (void)cjgui_linux_composition_clear(session);
            return 1;
        }
        if (!session->compositionOwned) {
            uint32_t start16 = session->compositionStart16;
            uint32_t replace16 = session->compositionReplaceLength16;
            if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT) {
                const CjguiLinuxNodeSlot *accepted =
                    cjgui_linux_accepted_slot(session, session->compositionNodeId);
                const char *acceptedValue = (accepted && accepted->value) ? accepted->value : "";
                if (accepted && cjgui_linux_text_hash(acceptedValue) != session->compositionBaseHash) {
                    // The owner moved while the preedit was open (measured:
                    // 外部写入 -> 外部你好写入 when the old caret was reused).
                    // Refuse the stale commit and re-anchor to the accepted body;
                    // the next legal keystroke continues from the current value.
                    free(session->proxy.value);
                    session->proxy.value = cjgui_linux_strdup(acceptedValue);
                    uint32_t units = cjgui_linux_utf16_length(acceptedValue, strlen(acceptedValue));
                    session->proxy.selectionStart16 = units;
                    session->proxy.selectionEnd16 = units;
                    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
                        fprintf(stderr, "CJGUI_LINUX_COMPOSITION_STALE node=%llu action=refuse_reanchor\n",
                                (unsigned long long)session->compositionNodeId);
                    }
                } else if (accepted) {
                    (void)cjgui_linux_emit_text_edit(session, start16, replace16, text ? text : "");
                }
            }
            (void)cjgui_linux_composition_clear(session);
            return 1;
        }
    }

    CjguiLinuxNodeSlot routing;
    memset(&routing, 0, sizeof(routing));
    routing.node.nodeId = session->compositionNodeId;
    routing.node.projectionVersion = session->accepted.valid ? session->accepted.projectionVersion
                                                            : session->proxy.sceneVersion;
    routing.node.resourceId = session->compositionResourceId;
    routing.node.nodeKind = session->compositionNodeKind;
    if (!cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION,
                                  &routing, 0, 0, 0, text ? text : "")) {
        if (phase != CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE) {
            (void)cjgui_linux_composition_clear(session);
        }
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
    out->bindingEpoch = session->compositionBindingEpoch;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr,
                "CJGUI_LINUX_COMPOSITION_PUSH phase=%u id=%u node=%llu start=%u len=%u text16=%u caret16=%u\n",
                phase, session->compositionId, (unsigned long long)session->compositionNodeId,
                session->compositionStart16, session->compositionLength16, text16, innerCaret16);
    }
    if (phase == CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE) {
        session->compositionLength16 = text16;
    } else {
        (void)cjgui_linux_composition_clear(session);
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

static CjguiLinuxNodeSlot *cjgui_linux_focused_slot(CjguiLinuxSession *session) {
    if (!session->focusActive || !session->accepted.valid) return NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        if (slot->node.nodeId == session->focusNodeId &&
            slot->node.resourceId == session->focusResourceId &&
            slot->node.nodeKind == session->focusNodeKind) return slot;
    }
    return NULL;
}

// With no remembered focus, start in the topmost scoped layer rather than in
// the base form behind it. Layers are appended after their base in scene order.
static uint64_t cjgui_linux_default_focus_scope(CjguiLinuxSession *session) {
    uint64_t scope = 0u;
    if (!session->accepted.valid) return 0u;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        const CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        if (slot->node.inputScope != 0u && cjgui_linux_slot_keyboard_focusable(slot)) {
            scope = slot->node.inputScope;
        }
    }
    return scope;
}

static int cjgui_linux_push_focus_event(CjguiLinuxSession *session, const CjguiLinuxNodeSlot *slot,
                                        int64_t modifiers) {
    const char *text = NULL;
    int64_t start = 0, end = 0;
    uint64_t binding = 0u;
    if (cjgui_linux_is_editable_text_kind(slot->node.nodeKind) && session->proxy.active &&
        session->proxy.nodeId == slot->node.nodeId && session->proxy.resourceId == slot->node.resourceId &&
        session->proxy.nodeKind == slot->node.nodeKind) {
        text = session->proxy.value;
        start = (int64_t)session->proxy.selectionStart16;
        end = (int64_t)session->proxy.selectionEnd16;
        binding = session->proxy.bindingEpoch;
    }
    if (!cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS, slot, 0, 0,
                                  modifiers, text)) return 0;
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pending[index].event.selectionStart = start;
    session->pending[index].event.selectionEnd = end;
    session->pending[index].event.bindingEpoch = binding;
    return 1;
}

static int cjgui_linux_focus_slot(CjguiLinuxSession *session, CjguiLinuxNodeSlot *slot, int announce,
                                  int64_t modifiers) {
    if (!cjgui_linux_slot_keyboard_focusable(slot)) return 0;
    if (cjgui_linux_is_editable_text_kind(slot->node.nodeKind)) {
        if (cjgui_internal_renderer_focus_composable_node(session->token, slot->node.nodeId) !=
            CJGUI_INTERNAL_RENDERER_OK) return 0;
    } else {
        int hadComposition = session->compositionActive;
        cjgui_linux_proxy_release(session);
        cjgui_linux_focus_set(session, slot);
        if (hadComposition) cjgui_linux_repaint_composition_frame(session);
    }
    if (announce && !cjgui_linux_push_focus_event(session, slot, modifiers)) return 0;
    return 1;
}

static int cjgui_linux_tab_title_is_stop(const CjguiLinuxSession *session, const CjguiLinuxNodeSlot *slot,
                                         uint64_t activeGroup, uint64_t scope) {
    uint64_t group = slot->node.tabGroupId;
    if (slot->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE || group == 0u) return 1;
    if (group == activeGroup) return 0;   // Tab exits a group even after arrow navigation
    const CjguiLinuxNodeSlot *first = NULL;
    const CjguiLinuxNodeSlot *selected = NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        const CjguiLinuxNodeSlot *peer = &session->accepted.slots[i];
        if (peer->node.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ||
            peer->node.tabGroupId != group || peer->node.inputScope != scope ||
            !cjgui_linux_slot_keyboard_focusable(peer)) continue;
        if (!first) first = peer;
        if (peer->node.tabSelected) selected = peer;
    }
    return slot == (selected ? selected : first);
}

static int cjgui_linux_focus_next(CjguiLinuxSession *session, int backwards, int64_t modifiers) {
    if (!session->accepted.valid || session->accepted.nodeCount == 0u) return 0;
    CjguiLinuxNodeSlot *current = cjgui_linux_focused_slot(session);
    int64_t index = current ? (int64_t)(current - session->accepted.slots) : -1;
    uint64_t scope = current ? current->node.inputScope : cjgui_linux_default_focus_scope(session);
    uint64_t activeGroup = (current &&
        current->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE)
        ? current->node.tabGroupId : 0u;
    int64_t cursor = index >= 0 ? index + (backwards ? -1 : 1)
                                : (backwards ? (int64_t)session->accepted.nodeCount - 1 : 0);
    for (uint32_t attempts = 0u; attempts < session->accepted.nodeCount; attempts += 1u) {
        if (cursor < 0) cursor = (int64_t)session->accepted.nodeCount - 1;
        if (cursor >= (int64_t)session->accepted.nodeCount) cursor = 0;
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[cursor];
        if (slot->node.inputScope == scope && cjgui_linux_slot_keyboard_focusable(slot) &&
            cjgui_linux_tab_title_is_stop(session, slot, activeGroup, scope)) {
            if (cjgui_linux_focus_slot(session, slot, 1, modifiers)) {
                if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                    fprintf(stderr, "CJGUI_LINUX_ABI focus_tab node=%llu kind=%u scope=%llu back=%d\n",
                            (unsigned long long)slot->node.nodeId, slot->node.nodeKind,
                            (unsigned long long)scope, backwards);
                }
                return 1;
            }
            return 0;
        }
        cursor += backwards ? -1 : 1;
    }
    return 0;
}

static int cjgui_linux_activate_focused(CjguiLinuxSession *session, int64_t modifiers) {
    CjguiLinuxNodeSlot *slot = cjgui_linux_focused_slot(session);
    if (!slot || !slot->node.isInteractive || slot->node.isReadOnly) return 0;
    switch (slot->node.nodeKind) {
        case CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON:
        case CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE:
        case CJGUI_INTERNAL_RENDERER_COMPOSABLE_VECTOR_GRAPHIC:
            return cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE,
                                            slot, 0, 0, modifiers, NULL);
        case CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT: {
            const char *next = (slot->value && strcmp(slot->value, "true") == 0) ? "false" : "true";
            return cjgui_linux_pending_push(session,
                                            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED,
                                            slot, 0, 0, modifiers, next);
        }
        default:
            return 0;
    }
}

static int cjgui_linux_dismiss_layer(CjguiLinuxSession *session, int64_t modifiers) {
    CjguiLinuxNodeSlot *slot = cjgui_linux_focused_slot(session);
    if (!slot || slot->node.inputScope == 0u) {
        slot = NULL;
        if (session->accepted.valid) {
            for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
                CjguiLinuxNodeSlot *candidate = &session->accepted.slots[i];
                if (candidate->node.inputScope != 0u && cjgui_linux_slot_keyboard_focusable(candidate)) {
                    slot = candidate;
                }
            }
        }
    }
    if (!slot || slot->node.inputScope == 0u) return 0;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI dismiss_escape node=%llu scope=%llu\n",
                (unsigned long long)slot->node.nodeId, (unsigned long long)slot->node.inputScope);
    }
    // 上下文菜单的结束事件必须携带请求 id：共同层按 `escape:<requestId>`
    // 只结束这个请求，迟到的旧 Escape 不能撤销新菜单。普通模态层保持
    // 裸 "escape"，沿用既有共同契约。
    char text[48];
    uint64_t request = cjgui_linux_aux_context_menu_request(session->token);
    if (request != 0u) {
        snprintf(text, sizeof(text), "escape:%llu", (unsigned long long)request);
    } else {
        snprintf(text, sizeof(text), "escape");
    }
    return cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_DISMISS_LAYER,
                                    slot, 0, 0, modifiers, text);
}

// Normalize one command chord into the shared `shortcut:...` wire value. X11
// reports Shift-modified letters as uppercase keysyms, so the shift bit is
// derived from both the mask and the keysym.
static int cjgui_linux_shortcut_character(const CjguiLinuxWindowEvent *event, char *out) {
    uint32_t key = event->keySym;
    if (key >= 'A' && key <= 'Z') { *out = (char)(key - 'A' + 'a'); return 1; }
    if (key >= 'a' && key <= 'z') { *out = (char)key; return 1; }
    if (key >= '0' && key <= '9') { *out = (char)key; return 1; }
    if (key == ',' || key == '.' || key == '/' || key == '-' || key == '=' ||
        key == '[' || key == ']' || key == ';' || key == '\'') {
        *out = (char)key;
        return 1;
    }
    return 0;
}

static void cjgui_linux_build_shortcut(char *out, size_t capacity, char key,
                                       int control, int option, int shift, int command) {
    snprintf(out, capacity, "shortcut:%s%s%s%s%c",
             control ? "control+" : "", option ? "option+" : "",
             shift ? "shift+" : "", command ? "command+" : "", key);
}

// Returns 1 when the chord belongs to an accepted command declaration. The
// actual run still goes through Cangjie invokeCommand: this only forwards the
// normalized shortcut in a WINDOW_COMMAND event, exactly like the macOS route.
static int cjgui_linux_try_command_shortcut(CjguiLinuxSession *session,
                                            const CjguiLinuxWindowEvent *event) {
    uint32_t mods = event->modifiers;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_CHORD sym=0x%x mods=%u proxy=%d composing=%d\n",
                event->keySym, mods, session->proxy.active, session->compositionActive);
    }
    int control = (mods & CJGUI_LINUX_MOD_CONTROL) != 0u;
    int option = (mods & CJGUI_LINUX_MOD_ALT) != 0u;
    int command = (mods & CJGUI_LINUX_MOD_SUPER) != 0u;
    int shift = (mods & CJGUI_LINUX_MOD_SHIFT) != 0u ||
                (event->keySym >= 'A' && event->keySym <= 'Z');
    char shortcut[64];
    char key = '\0';
    int plain = 0;
    if (!control && !option && !command && !shift) {
        // A layer may declare plain navigation as scoped commands (search
        // panel / command palette). Native only forwards the key; the shared
        // window still resolves the declaration, target and scope. With no
        // such declaration the ordinary text/list/activation path owns it.
        const char *name = NULL;
        if (event->keySym == CJGUI_LINUX_XK_UP) name = "up";
        else if (event->keySym == CJGUI_LINUX_XK_DOWN) name = "down";
        else if (event->keySym == CJGUI_LINUX_XK_RETURN) name = "enter";
        else if (event->keySym == CJGUI_LINUX_XK_ESCAPE) name = "escape";
        if (!name) return 0;
        snprintf(shortcut, sizeof(shortcut), "shortcut:%s", name);
        plain = 1;
    } else {
        if (!control && !option && !command) return 0;
        if (!cjgui_linux_shortcut_character(event, &key)) return 0;
        // Copy/cut/paste/select-all stay with the text service while a field owns
        // the keyboard; a command must not shadow the platform editing contract.
        if (session->proxy.active && control && !option && !command && !shift &&
            (key == 'c' || key == 'x' || key == 'v' || key == 'a')) return 0;
        cjgui_linux_build_shortcut(shortcut, sizeof(shortcut), key, control, option, shift, command);
    }
    CjguiLinuxNodeSlot *focused = cjgui_linux_focused_slot(session);
    uint64_t scope = focused ? focused->node.inputScope : cjgui_linux_default_focus_scope(session);
    int declared = cjgui_linux_aux_shortcut_declared(session->token, shortcut, scope);
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_DECL shortcut=%s scope=%llu declared=%d plain=%d\n", shortcut,
                (unsigned long long)scope, declared, plain);
    }
    // Linux has no Command key. A Control chord also addresses declarations
    // written for macOS-style `command+` shortcuts, after the exact spelling.
    if (!declared && !plain && control && !command && !option) {
        cjgui_linux_build_shortcut(shortcut, sizeof(shortcut), key, 0, option, shift, 1);
        declared = cjgui_linux_aux_shortcut_declared(session->token, shortcut, scope);
    }
    if (!declared) return 0;
    if (!cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_WINDOW_COMMAND,
                                  NULL, 0, 0, (int64_t)mods, shortcut)) return 0;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_COMMAND shortcut=%s scope=%llu\n", shortcut,
                (unsigned long long)scope);
    }
    return 1;
}

// 处理一次按键：命中已声明的文本代理时产生一次编辑意图（整值 + 增量）。
static void cjgui_linux_handle_key(CjguiLinuxSession *session, const CjguiLinuxWindowEvent *event) {
    int composing = session->compositionActive;
    int commandModifier = (event->modifiers & (CJGUI_LINUX_MOD_CONTROL | CJGUI_LINUX_MOD_ALT |
                                               CJGUI_LINUX_MOD_SUPER)) != 0u;
    // Composition keeps XIM priority: no command shortcut runs while the IME
    // owns the keystroke.
    if (!composing && cjgui_linux_try_command_shortcut(session, event)) return;
    if (!composing && !commandModifier && !session->proxy.active &&
        (event->keySym == CJGUI_LINUX_XK_UP || event->keySym == CJGUI_LINUX_XK_DOWN)) {
        // Focus order is scene order inside the current scope; Up/Down move it
        // and the FOCUS event lets the shared layer reveal a clipped row.
        (void)cjgui_linux_focus_next(session, event->keySym == CJGUI_LINUX_XK_UP,
                                     (int64_t)event->modifiers);
        return;
    }
    if (!composing && !commandModifier &&
        (event->keySym == CJGUI_LINUX_XK_MENU ||
         (event->keySym == CJGUI_LINUX_XK_F10 && (event->modifiers & CJGUI_LINUX_MOD_SHIFT) != 0u))) {
        CjguiLinuxNodeSlot *focused = cjgui_linux_focused_slot(session);
        if (focused) {
            double pointX = (double)focused->node.x + cjgui_linux_slot_translate_x(focused) +
                            (double)focused->node.width * 0.5;
            double pointY = (double)focused->node.y + cjgui_linux_slot_translate_y(focused) +
                            (double)focused->node.height * 0.5;
            CjguiInternalRendererPointerEventGeometry geometry;
            cjgui_linux_capture_pointer_geometry(session, focused, pointX, pointY, &geometry);
            (void)cjgui_linux_pending_push_geometry(
                session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_CONTEXT_MENU_REQUEST,
                focused, (int64_t)pointX, (int64_t)pointY, (int64_t)event->modifiers, NULL, &geometry);
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_CONTEXT_KEY node=%llu\n",
                        (unsigned long long)focused->node.nodeId);
            }
        }
        return;
    }
    if (!composing && !commandModifier && event->keySym == CJGUI_LINUX_XK_ESCAPE) {
        // A composing IME owns Escape: the first press may only cancel the
        // candidate list, so native must not dismiss the layer behind it.
        // Either way Escape is a control key and must never fall through to
        // text insertion: XIM reports it with utf8Length 1, and inserting
        // U+001B corrupted the owned value ("邮件80\u001b").
        (void)cjgui_linux_dismiss_layer(session, (int64_t)event->modifiers);
        return;
    }
    // X11 delivers Shift+Tab as ISO_Left_Tab rather than Tab+ShiftMask; both
    // spellings must reach the same traversal decision.
    if (!composing && !commandModifier &&
        (event->keySym == CJGUI_LINUX_XK_TAB || event->keySym == CJGUI_LINUX_XK_ISO_LEFT_TAB)) {
        int backwards = event->keySym == CJGUI_LINUX_XK_ISO_LEFT_TAB ||
                        (event->modifiers & CJGUI_LINUX_MOD_SHIFT) != 0u;
        int insertsTab = 0;
        if (session->proxy.active &&
            session->proxy.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT) {
            CjguiLinuxNodeSlot *proxySlot = cjgui_linux_accepted_slot(session, session->proxy.nodeId);
            insertsTab = proxySlot && proxySlot->node.tabInsertsText;
        }
        if (!insertsTab) {
            // A single-line field (owned or ordinary) must never insert a
            // literal tab, but Tab still belongs to focus traversal. Swallowing
            // it here made long forms unreachable by keyboard from an owned
            // field; only an explicit multiline tabInsertsText consumes it.
            (void)cjgui_linux_focus_next(session, backwards, (int64_t)event->modifiers);
            return;
        }
    }
    if (!session->proxy.active) {
        if (!composing && !commandModifier &&
            (event->keySym == CJGUI_LINUX_XK_RETURN || event->keySym == CJGUI_LINUX_XK_SPACE)) {
            if (cjgui_linux_activate_focused(session, (int64_t)event->modifiers)) return;
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

static int cjgui_linux_pointer_focus_text(CjguiLinuxSession *session, CjguiLinuxNodeSlot *slot,
                                          const CjguiLinuxWindowEvent *event);

// 输入类文本的原生拖选：锚点在按下时冻结，移动时对同一代理正文重新命中并发布
// SELECTION_CHANGED（UTF-16）。owned 与普通输入同一条路径；预览 TEXT 节点不走
// 这里，它们仍需共同层收 BEGIN/MOVE/END。
static CjguiLinuxNodeSlot *cjgui_linux_pointer_text_slot(CjguiLinuxSession *session) {
    if (!session->pointerTextTarget || !session->proxy.active || !session->accepted.valid) return NULL;
    if (session->proxy.nodeId != session->pointerTextNodeId ||
        session->proxy.resourceId != session->pointerTextResourceId ||
        session->proxy.nodeKind != session->pointerTextNodeKind ||
        session->proxy.bindingEpoch != session->pointerTextBindingEpoch) return NULL;
    for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
        CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
        if (slot->node.nodeId == session->pointerTextNodeId &&
            slot->node.resourceId == session->pointerTextResourceId &&
            slot->node.nodeKind == session->pointerTextNodeKind) return slot;
    }
    return NULL;
}

static void cjgui_linux_pointer_drag_text(CjguiLinuxSession *session, const CjguiLinuxWindowEvent *event) {
    if (!session || !event) return;
    CjguiLinuxNodeSlot *slot = cjgui_linux_pointer_text_slot(session);
    if (!slot) {
        // Focus switched, the binding epoch advanced, or the node left the
        // accepted scene. End the old gesture instead of applying A's anchor
        // to whatever is focused now.
        if (session->pointerTextTarget) {
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_ABI text_drag_aborted node=%llu focus=%llu proxy=%d\n",
                        (unsigned long long)session->pointerTextNodeId,
                        (unsigned long long)session->focusNodeId, session->proxy.active);
            }
            session->pointerTextTarget = 0;
            session->pointerTextAborted = 1;
        }
        return;
    }
    const char *value = session->proxy.value ? session->proxy.value : "";
    size_t length = strlen(value);
    uint32_t byteOffset = 0u, affinity = 0u;
    CjguiInternalRendererStatus hitStatus = cjgui_linux_hit_test_text_body(session, slot, value, event->x,
                                                                           event->y, &byteOffset, &affinity);
    if (hitStatus != CJGUI_INTERNAL_RENDERER_OK) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_ABI text_drag_hit_failed status=%d x=%.1f y=%.1f\n",
                    (int)hitStatus, event->x, event->y);
        }
        return;
    }
    uint32_t units = cjgui_linux_utf16_length(value, length);
    uint32_t caret = cjgui_linux_utf16_for_byte_offset(value, length, byteOffset);
    if (caret > units) caret = units;
    uint32_t anchor = session->textSelectionAnchor16;
    if (anchor > units) anchor = units;
    uint32_t start = anchor < caret ? anchor : caret;
    uint32_t end = anchor < caret ? caret : anchor;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI text_drag x=%.1f y=%.1f byte=%u anchor=%u sel=%u:%u\n",
                event->x, event->y, byteOffset, anchor, start, end);
    }
    if (start == session->proxy.selectionStart16 && end == session->proxy.selectionEnd16) return;
    session->proxy.selectionStart16 = start;
    session->proxy.selectionEnd16 = end;
    CjguiInternalRendererPointerEventGeometry geometry;
    cjgui_linux_capture_pointer_geometry(session, slot, event->x, event->y, &geometry);
    if (!cjgui_linux_pending_push_geometry(session,
                                           CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                           slot, (int64_t)event->x, (int64_t)event->y,
                                           (int64_t)event->modifiers, NULL, &geometry)) return;
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pending[index].event.selectionStart = (int64_t)start;
    session->pending[index].event.selectionEnd = (int64_t)end;
    session->pending[index].event.bindingEpoch = session->proxy.bindingEpoch;
}

// 预编辑是 Linux 本地的可见态，不改变已接受场景；共同层对组字相位发起的
// 刷新在场景完全相同时走语义接受、不提交新帧（preedit 已到共同层却不上屏）。
// 组字态变化后直接重绘最后一帧已接受场景：不重建投影、不写 owner。
static void cjgui_linux_repaint_composition_frame(CjguiLinuxSession *session) {
    if (session == NULL || !session->accepted.valid || session->gpu == NULL) return;
    CjguiInternalRendererFrameObservation observation;
    memset(&observation, 0, sizeof(observation));
    // Accepted-only paint: a preedit update must not commit a staged command
    // menu or promote a pending scene candidate as a side effect.
    (void)cjgui_linux_present_scene(session, &observation, 0);
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
            session->resizeVersion += 1u;
            (void)cjgui_linux_gpu_resize(session->gpu, width, height);
            cjgui_linux_pending_push(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED, NULL,
                                     (int64_t)width, (int64_t)height, 0, NULL);
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN: {
            CjguiLinuxNodeSlot *slot = cjgui_linux_hit_test(session, event->x, event->y);
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_ABI pointer_down x=%.1f y=%.1f node=%llu kind=%u\n",
                        event->x, event->y,
                        (unsigned long long)(slot ? slot->node.nodeId : 0u),
                        (unsigned int)(slot ? slot->node.nodeKind : 0u));
            }
            session->pointerDown = 1;
            session->pointerTextTarget = 0;
            session->pointerTextAborted = 0;
            session->pointerTextNodeId = 0u;
            session->pointerTextResourceId = -1;
            session->pointerTextNodeKind = 0u;
            session->pointerTextBindingEpoch = 0u;
            session->pointerNodeId = slot ? slot->node.nodeId : 0u;
            session->pointerResourceId = slot ? slot->node.resourceId : 0;
            session->pointerNodeKind = slot ? slot->node.nodeKind : 0u;
            if (event->button == CJGUI_LINUX_BUTTON_LEFT &&
                cjgui_linux_pointer_focus_text(session, slot, event)) {
                session->pointerTextTarget = 1;
                session->pointerTextNodeId = slot->node.nodeId;
                session->pointerTextResourceId = slot->node.resourceId;
                session->pointerTextNodeKind = slot->node.nodeKind;
                session->pointerTextBindingEpoch = session->proxy.bindingEpoch;
                break;
            }
            if (event->button == CJGUI_LINUX_BUTTON_LEFT && slot &&
                !cjgui_linux_is_editable_text_kind(slot->node.nodeKind) &&
                cjgui_linux_slot_keyboard_focusable(slot)) {
                // A click on a button moves real keyboard focus off the old
                // field. Publish FOCUS on press like the macOS mouse-down path,
                // so the ring follows the press even when the release leaves
                // the node; the press event still tells Cangjie where
                // activation happened.
                int hadComposition = session->compositionActive;
                cjgui_linux_proxy_release(session);
                cjgui_linux_focus_set(session, slot);
                (void)cjgui_linux_push_focus_event(session, slot, (int64_t)event->modifiers);
                if (hadComposition) cjgui_linux_repaint_composition_frame(session);
            }
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
            if (session->pointerTextAborted) {
                session->pointerDown = 0;
                session->pointerTextTarget = 0;
                session->pointerTextAborted = 0;
                break;
            }
            if (session->pointerTextTarget) {
                // 抬起位置可能是拖选的终点：先按同一点收口，再结束声明；
                // 纯点击时锚点/焦点相同，不会重复发布。
                cjgui_linux_pointer_drag_text(session, event);
                session->pointerDown = 0;
                session->pointerTextTarget = 0;
                break;
            }
            CjguiLinuxNodeSlot *slot = cjgui_linux_hit_test(session, event->x, event->y);
            int sameNode = slot && session->pointerDown && slot->node.nodeId == session->pointerNodeId;
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_ABI pointer_up x=%.1f y=%.1f node=%llu kind=%u text_target=%d\n",
                        event->x, event->y,
                        (unsigned long long)(slot ? slot->node.nodeId : 0u),
                        (unsigned int)(slot ? slot->node.nodeKind : 0u), session->pointerTextTarget);
            }
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
                // 语义判决仍归共同层。布尔控件与键盘路径发送同一 owner 变更事件；
                // ACTIVATE 只属于按钮/页签等动作契约。
                if (sameNode && event->button == CJGUI_LINUX_BUTTON_LEFT) {
                    if (slot->node.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT &&
                        slot->node.isInteractive != 0u && slot->node.isReadOnly == 0u) {
                        const char *next =
                            (slot->value && strcmp(slot->value, "true") == 0) ? "false" : "true";
                        cjgui_linux_pending_push_geometry(
                            session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_BOOLEAN_CHANGED,
                            slot, (int64_t)event->x, (int64_t)event->y,
                            (int64_t)event->modifiers, next, &geometry);
                    } else {
                        cjgui_linux_pending_push_geometry(
                            session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE,
                            slot, (int64_t)event->x, (int64_t)event->y,
                            (int64_t)event->modifiers, NULL, &geometry);
                    }
                }
            }
            session->pointerDown = 0;
            break;
        }
        case CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE: {
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_ABI pointer_move x=%.1f y=%.1f down=%d text_target=%d\n",
                        event->x, event->y, session->pointerDown, session->pointerTextTarget);
            }
            if (!session->pointerDown) break;   // 悬停阶段本阶段不产生共同层意图
            if (session->pointerTextAborted) break;
            if (session->pointerTextTarget) {
                cjgui_linux_pointer_drag_text(session, event);
                break;
            }
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
            session->pointerTextTarget = 0;
            session->pointerTextAborted = 0;
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
            if (cjgui_linux_emit_composition(session, CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_UPDATE,
                                             event->utf8, event->compositionCaret16)) {
                cjgui_linux_repaint_composition_frame(session);
            }
            break;
        case CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_COMMIT:
            // 提交文本一次进入既有 owner 路径；被 IME 消费的按键本身没有普通事件。
            // The preedit must disappear on this frame, not on the next keystroke.
            if (cjgui_linux_emit_composition(session, CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT,
                                             event->utf8, 0u)) {
                cjgui_linux_repaint_composition_frame(session);
            }
            break;
        case CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_CANCEL:
            if (cjgui_linux_emit_composition(session, CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_CANCEL,
                                             NULL, 0u)) {
                cjgui_linux_repaint_composition_frame(session);
            }
            break;
        default:
            break;
    }
}

static CjguiInternalRendererStatus cjgui_linux_pump_translated(CjguiLinuxSession *session, uint32_t timeoutMs,
                                                              CjguiInternalRendererEvent *outEvent,
                                                              uint64_t *outIdleWaitNs) {
    // 每轮泵都先结算已完成的图片准备；worker 的窗口唤醒只负责把阻塞的
    // window_pump 叫醒，真正的纹理上传/状态发布仍在主线程发生。
    cjgui_linux_image_pump(session->image);
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

static int cjgui_linux_declared_owned_target(CjguiLinuxSession *session, uint64_t nodeId, int64_t resourceId,
                                              uint32_t nodeKind);

CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(uint64_t sessionToken, uint64_t nodeId) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI focus_composable_node node=%llu\n",
                (unsigned long long)nodeId);
    }
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!session->accepted.valid) return CJGUI_INTERNAL_RENDERER_SCENE_NOT_STAGED;
    CjguiLinuxNodeSlot *slot = cjgui_linux_accepted_slot(session, nodeId);
    if (!slot) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    const CjguiInternalRendererComposableNode *node = &slot->node;
    if (!node->isInteractive || node->isReadOnly) {
        if (getenv("CJGUI_LINUX_ABI_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_ABI focus_refused node=%llu kind=%u interactive=%u readonly=%u\n",
                    (unsigned long long)nodeId, node->nodeKind, node->isInteractive, node->isReadOnly);
        }
        return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    }
    if (!cjgui_linux_is_editable_text_kind(node->nodeKind)) {
        if (!cjgui_linux_is_keyboard_focus_kind(node->nodeKind)) {
            if (getenv("CJGUI_LINUX_ABI_TRACE")) {
                fprintf(stderr, "CJGUI_LINUX_ABI focus_refused node=%llu kind=%u not_focusable=1\n",
                        (unsigned long long)nodeId, node->nodeKind);
            }
            return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
        }
        // A button/tab/boolean takes real keyboard focus but owns no text proxy.
        // Clearing the proxy is what stops later keystrokes from writing the
        // previously focused field.
        int hadComposition = session->compositionActive;
        cjgui_linux_proxy_release(session);
        cjgui_linux_focus_set(session, slot);
        if (hadComposition) cjgui_linux_repaint_composition_frame(session);
        if (getenv("CJGUI_LINUX_ABI_TRACE")) {
            fprintf(stderr, "CJGUI_LINUX_ABI focus_non_text node=%llu kind=%u scope=%llu\n",
                    (unsigned long long)nodeId, node->nodeKind, (unsigned long long)node->inputScope);
        }
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    const char *value = slot->value ? slot->value : "";
    uint32_t units = cjgui_linux_utf16_length(value, strlen(value));
    // Same accepted identity keeps the existing proxy. A real owned binding
    // declaration decides the class; ordinary refocus keeps a legitimate local
    // body when the accepted packet carries the preserve hint, or when the
    // accepted body and the current caret range are unchanged.
    if (session->proxy.active &&
        session->proxy.nodeId == nodeId && session->proxy.resourceId == node->resourceId &&
        session->proxy.nodeKind == node->nodeKind) {
        if (!session->proxy.ordinary) {
            if (cjgui_linux_declared_owned_target(session, nodeId, node->resourceId, node->nodeKind)) {
                session->pointerNodeId = nodeId;
                cjgui_linux_focus_set(session, slot);
                session->proxy.sceneVersion = session->accepted.projectionVersion;
                return CJGUI_INTERNAL_RENDERER_OK;
            }
            // Declaration was withdrawn or replaced: this is an ordinary proxy
            // now; do not keep claiming an owned binding epoch.
            session->proxy.ordinary = 1;
            session->proxy.bindingEpoch = 0u;
        }
        if (node->preservesActiveLocalText) {
            session->pointerNodeId = nodeId;
            cjgui_linux_focus_set(session, slot);
            session->proxy.sceneVersion = session->accepted.projectionVersion;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        if (session->proxy.value && strcmp(session->proxy.value, value) == 0 &&
            session->proxy.selectionStart16 <= session->proxy.selectionEnd16 &&
            session->proxy.selectionEnd16 <= units) {
            session->pointerNodeId = nodeId;
            cjgui_linux_focus_set(session, slot);
            session->proxy.sceneVersion = session->accepted.projectionVersion;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    char *copy = cjgui_linux_strdup(value);
    if (!copy) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    int hadComposition = session->compositionActive;
    cjgui_linux_proxy_release(session);
    session->proxy.active = 1;
    session->proxy.ordinary = 1;
    session->proxy.nodeId = nodeId;
    session->proxy.resourceId = node->resourceId;
    session->proxy.nodeKind = node->nodeKind;
    session->proxy.sceneVersion = session->accepted.projectionVersion;
    session->proxy.value = copy;
    session->proxy.selectionStart16 = units;
    session->proxy.selectionEnd16 = units;
    session->pointerNodeId = nodeId;
    cjgui_linux_focus_set(session, slot);
    if (hadComposition) cjgui_linux_repaint_composition_frame(session);
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI focus_install node=%llu kind=%u bytes=%zu\n",
                (unsigned long long)nodeId, node->nodeKind, strlen(value));
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int cjgui_linux_declared_owned_target(CjguiLinuxSession *session, uint64_t nodeId, int64_t resourceId,
                                              uint32_t nodeKind) {
    if (!session->ownedTextSessionEnabled) return 0;
    if (session->ownedTextSessionNodeId != nodeId) return 0;
    if (resourceId >= 0 && session->ownedTextSessionResourceId != resourceId) return 0;
    if (nodeKind != 0u && session->ownedTextSessionNodeKind != nodeKind) return 0;
    return 1;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_owned_text_session(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t bindingEpoch,
    uint32_t enabled) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI set_composable_owned_text_session\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (enabled > 1u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_DECLARE_TEXT enabled=%u node=%llu epoch=%llu\n", enabled,
                (unsigned long long)nodeId, (unsigned long long)bindingEpoch);
    }
    if (!enabled) {
        // 撤回只清真实声明；活动代理若属于该声明，降为普通代理而不是丢弃
        // 正文/选区。普通模态返回的 restore 随后按 ordinary 路径同步。
        if (bindingEpoch < session->ownedTextSessionBindingEpoch)
            return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
        if (session->proxy.active && !session->proxy.ordinary &&
            session->proxy.nodeId == session->ownedTextSessionNodeId &&
            session->proxy.resourceId == session->ownedTextSessionResourceId &&
            session->proxy.nodeKind == session->ownedTextSessionNodeKind) {
            session->proxy.ordinary = 1;
            session->proxy.bindingEpoch = 0u;
        }
        session->ownedTextSessionEnabled = 0;
        session->ownedTextSessionNodeId = 0u;
        session->ownedTextSessionResourceId = -1;
        session->ownedTextSessionNodeKind = 0u;
        if (cjgui_linux_composition_revalidate(session))
            cjgui_linux_repaint_composition_frame(session);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (nodeId == 0u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (session->ownedTextSessionEnabled && session->ownedTextSessionNodeId == nodeId &&
        session->ownedTextSessionResourceId == resourceId && session->ownedTextSessionNodeKind == nodeKind &&
        session->ownedTextSessionBindingEpoch == bindingEpoch) {
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (bindingEpoch < session->ownedTextSessionBindingEpoch)
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    // 声明本身不携带值：真正的值/选区由 restore_composable_selection 每轮推来，
    // 这里只记住真实绑定，不覆盖已有代理的身份。
    session->ownedTextSessionEnabled = 1;
    session->ownedTextSessionNodeId = nodeId;
    session->ownedTextSessionResourceId = resourceId;
    session->ownedTextSessionNodeKind = nodeKind;
    session->ownedTextSessionBindingEpoch = bindingEpoch;
    // A declaration replacing the identity a preedit was frozen on ends that
    // preedit here, before the next restore can install the new binding.
    if (cjgui_linux_composition_revalidate(session))
        cjgui_linux_repaint_composition_frame(session);
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

// nodeKind == 0 means the caller has no such parameter (install_owned_source_selection
// and recover paths). Resolve the kind from the matching real declaration first:
// an empty proxy has kind 0, so reading proxy.nodeKind alone installs an owned
// proxy the recover identity check can never match.
static uint32_t cjgui_linux_resolve_restore_kind(const CjguiLinuxSession *session, uint64_t nodeId,
                                                  int64_t resourceId) {
    if (session->ownedTextSessionEnabled && session->ownedTextSessionNodeId == nodeId &&
        (resourceId < 0 || session->ownedTextSessionResourceId == resourceId)) {
        return session->ownedTextSessionNodeKind;
    }
    if (session->proxy.active && session->proxy.nodeId == nodeId &&
        (resourceId < 0 || session->proxy.resourceId == resourceId)) {
        return session->proxy.nodeKind;
    }
    if (session->accepted.valid) {
        for (uint32_t i = 0u; i < session->accepted.nodeCount; i += 1u) {
            const CjguiLinuxNodeSlot *slot = &session->accepted.slots[i];
            if (slot->node.nodeId == nodeId && (resourceId < 0 || slot->node.resourceId == resourceId)) {
                return slot->node.nodeKind;
            }
        }
    }
    return 0u;
}

CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(
    uint64_t sessionToken, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion,
    const char *expectedValue, uint32_t selectionStart, uint32_t selectionEnd, uint32_t *outSelectionStart,
    uint32_t *outSelectionEnd) {
    if (getenv("CJGUI_LINUX_ABI_TRACE")) fprintf(stderr, "CJGUI_LINUX_ABI restore_composable_selection\n");
    CjguiLinuxSession *session = cjgui_linux_lookup(sessionToken);
    if (!session) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!expectedValue) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    uint32_t effectiveKind = nodeKind != 0u ? nodeKind
                                           : cjgui_linux_resolve_restore_kind(session, nodeId, resourceId);
    // Restore serves both real owned sessions and ordinary modal-return/tab
    // bookmarks. Only the current binding declaration makes this proxy owned.
    int owned = cjgui_linux_declared_owned_target(session, nodeId, resourceId, effectiveKind);
    uint64_t binding = owned ? session->ownedTextSessionBindingEpoch : 0u;
    if (!session->proxy.active || session->proxy.nodeId != nodeId) {
        cjgui_linux_proxy_release(session);
        session->proxy.active = 1;
        session->proxy.ordinary = owned ? 0 : 1;
        session->proxy.nodeId = nodeId;
        session->proxy.resourceId = resourceId;
        session->proxy.nodeKind = effectiveKind;
        session->proxy.bindingEpoch = binding;
        session->proxy.value = cjgui_linux_strdup(expectedValue);
    } else if (!cjgui_linux_proxy_matches(session, nodeId, resourceId, effectiveKind, NULL)) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    } else {
        session->proxy.ordinary = owned ? 0 : 1;
        session->proxy.bindingEpoch = binding;
        cjgui_linux_replace(&session->proxy.value, expectedValue);
    }
    session->proxy.sceneVersion = sceneVersion;
    uint32_t units = cjgui_linux_utf16_length(expectedValue, strlen(expectedValue));
    if (selectionStart > units) selectionStart = units;
    if (selectionEnd > units) selectionEnd = units;
    if (selectionEnd < selectionStart) selectionEnd = selectionStart;
    session->proxy.selectionStart16 = selectionStart;
    session->proxy.selectionEnd16 = selectionEnd;
    {
        CjguiLinuxNodeSlot *restored = cjgui_linux_accepted_slot(session, nodeId);
        if (restored && (resourceId < 0 || restored->node.resourceId == resourceId) &&
            (effectiveKind == 0u || restored->node.nodeKind == effectiveKind)) {
            cjgui_linux_focus_set(session, restored);
        }
    }
    // Restore also runs for style-only refreshes of the same binding. Only an
    // identity or binding-epoch change may end the live preedit; the body hash
    // is not the target identity.
    if (cjgui_linux_composition_revalidate(session))
        cjgui_linux_repaint_composition_frame(session);
    if (getenv("CJGUI_LINUX_PUMP_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_RESTORE_SEL node=%llu epoch=%llu sel=%u:%u kind=%u\n",
                (unsigned long long)nodeId, (unsigned long long)session->proxy.bindingEpoch,
                selectionStart, selectionEnd, effectiveKind);
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
    outWorkload->imageDecodeStartCount = cjgui_linux_image_decode_start_count(session->image);
    uint32_t glyphs = 0u, atlasBytes = 0u;
    cjgui_linux_text_stats(session->text, &glyphs, &atlasBytes);
    outWorkload->reusableResourceBytes = (uint64_t)atlasBytes + cjgui_linux_image_cache_bytes(session->image);
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
// Hit-test one explicit body. A preserved local proxy can differ from the
// accepted packet, so the caller must pass the same body it will convert the
// byte offset against.
static CjguiInternalRendererStatus cjgui_linux_hit_test_text_body(CjguiLinuxSession *session,
                                                                  const CjguiLinuxNodeSlot *slot,
                                                                  const char *body, double x, double y,
                                                                  uint32_t *outByteOffset,
                                                                  uint32_t *outAffinity) {
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
    return cjgui_linux_hit_test_text_body(session, slot, cjgui_linux_node_body(slot), x, y,
                                          outByteOffset, outAffinity);
}

// Left-press on editable text focuses that node and reports the caret under the
// pointer, matching the Windows mouse path (FOCUS + SELECTION_CHANGED, no
// button ACTIVATE). The text model stays in the proxy installed by focus.
static int cjgui_linux_pointer_focus_text(CjguiLinuxSession *session, CjguiLinuxNodeSlot *slot,
                                          const CjguiLinuxWindowEvent *event) {
    if (!session || !slot || event->button != CJGUI_LINUX_BUTTON_LEFT) return 0;
    const CjguiInternalRendererComposableNode *node = &slot->node;
    if (!node->isInteractive || node->isReadOnly || !cjgui_linux_is_editable_text_kind(node->nodeKind)) return 0;
    // 预览类 TEXT 的 owned 目标由共同层收 BEGIN/MOVE/END（应用自己做源范围映射）；
    // 输入类节点与 Windows 一致走原生焦点+选区，owned 与非 owned 同一条路径。
    if (node->nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT &&
        (cjgui_linux_declared_owned_target(session, node->nodeId, node->resourceId, node->nodeKind) ||
         (session->proxy.active && !session->proxy.ordinary && session->proxy.nodeId == node->nodeId &&
          session->proxy.resourceId == node->resourceId && session->proxy.nodeKind == node->nodeKind))) {
        return 0;
    }
    if (cjgui_internal_renderer_focus_composable_node(session->token, node->nodeId) !=
        CJGUI_INTERNAL_RENDERER_OK) return 0;
    const char *value = session->proxy.value ? session->proxy.value : "";
    size_t length = strlen(value);
    uint32_t units = cjgui_linux_utf16_length(value, length);
    uint32_t caret = units;
    uint32_t byteOffset = 0u, affinity = 0u;
    // Use the proxy body for BOTH the hit test and the byte->UTF-16 conversion.
    // Under preservesActiveLocalText the accepted packet can lag the local body;
    // mixing the two would place the caret in a different string.
    if (cjgui_linux_hit_test_text_body(session, slot, value, event->x, event->y,
                                       &byteOffset, &affinity) == CJGUI_INTERNAL_RENDERER_OK) {
        caret = cjgui_linux_utf16_for_byte_offset(value, length, byteOffset);
        if (caret > units) caret = units;
    }
    session->proxy.selectionStart16 = caret;
    session->proxy.selectionEnd16 = caret;
    session->textSelectionAnchor16 = caret;
    CjguiInternalRendererPointerEventGeometry geometry;
    cjgui_linux_capture_pointer_geometry(session, slot, event->x, event->y, &geometry);
    if (!cjgui_linux_pending_push_geometry(session, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS,
                                           slot, (int64_t)event->x, (int64_t)event->y,
                                           (int64_t)event->modifiers, value, &geometry)) return 1;
    uint32_t index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pending[index].event.selectionStart = (int64_t)caret;
    session->pending[index].event.selectionEnd = (int64_t)caret;
    session->pending[index].event.bindingEpoch = session->proxy.bindingEpoch;
    if (!cjgui_linux_pending_push_geometry(session,
                                           CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
                                           slot, (int64_t)event->x, (int64_t)event->y,
                                           (int64_t)event->modifiers, NULL, &geometry)) return 1;
    index = (session->pendingHead + session->pendingCount - 1u) % CJGUI_LINUX_PENDING_EVENTS;
    session->pending[index].event.selectionStart = (int64_t)caret;
    session->pending[index].event.selectionEnd = (int64_t)caret;
    session->pending[index].event.bindingEpoch = session->proxy.bindingEpoch;
    if (getenv("CJGUI_LINUX_ABI_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_ABI pointer_focus node=%llu kind=%u caret=%u proxy=%d\n",
                (unsigned long long)node->nodeId, node->nodeKind, caret, session->proxy.active);
    }
    return 1;
}
