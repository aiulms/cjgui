// CJGUI OHOS renderer — implements the runtime-owned internal renderer C ABI
// (cjgui_internal_renderer_*) for the HarmonyOS backend, phase 1.
//
// 分工（固定路线）：
//  - 仓颉核心持有组件/布局/场景/业务 owner；本文件只是平台渲染与输入转换，
//    不持有业务真相。
//  - 结构定义直接包含 runtime/cjgui/native/cjgui_internal_renderer.h
//    （与仓颉 @C struct 同源的权威 ABI 头，快照同步）。
//  - 渲染线程：单个固定原生线程拥有 OH_Drawing GPU context、on-screen surface
//    与全部 OH_Drawing 排版/绘制调用（仓颉 M:N 线程不保证 OS 亲和，
//    GPU/排版对象不跨线程共享）。
//  - present/measure 经事务投递到渲染线程并等待明确结果；超时或无 surface
//    时 present 返回可恢复的 DRAWABLE_UNAVAILABLE，不推进帧号、不接受候选。
//  - 同尺寸 surface 重建同样递增 resizeVersion（核心靠它识别资源代际）。
//  - 触摸：ingress 队列的原始事件在 pump_event 内按"已接受场景"命中，
//    合成带完整身份（nodeId/resourceId/nodeKind/projectionVersion）的
//    ACTIVATE/BOOLEAN_CHANGED/指针相位意图，语义对齐 macOS mouseDownForNode。
//
// 能力边界（未支持能力显式失败，不做空成功）：
//  - 支持：容器/文本/按钮/整数与布尔输入的场景提交与自绘、文字四指标测量、
//    空命令菜单与空数据传输、viewport/进度/生命周期诊断。
//  - 图片资源：应用沙箱 PNG 有界异步解码、fit/fill 与圆角裁剪；
//    key/version/path 由应用声明，已接受场景保持精确资源绑定。
//  - 不支持（显式失败）：可编辑文本与选区恢复/文本命中、
//    非空 text runs、非空命令菜单、非空数据传输、IME caret、悬停/按压
//    视觉层（不影响业务正确性，视觉反馈后续阶段接回）。

#include "cjgui_internal_renderer.h"
#include "cjgui_ohos_ingress.h"

#include <hilog/log.h>

#include <native_drawing/drawing_brush.h>
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_canvas.h>
#include <native_drawing/drawing_font_collection.h>
#include <native_drawing/drawing_gpu_context.h>
#include <native_drawing/drawing_pen.h>
#include <native_drawing/drawing_rect.h>
#include <native_drawing/drawing_round_rect.h>
#include <native_drawing/drawing_sampling_options.h>
#include <native_drawing/drawing_surface.h>
#include <native_drawing/drawing_text_typography.h>
#include <native_drawing/drawing_types.h>

#include <inputmethod/inputmethod_controller_capi.h>
#include <inputmethod/inputmethod_text_editor_proxy_capi.h>
#include <inputmethod/inputmethod_text_config_capi.h>
#include <inputmethod/inputmethod_attach_options_capi.h>
#include <inputmethod/inputmethod_text_avoid_info_capi.h>
#include <native_window/external_window.h>
#include <multimedia/image_framework/image/image_source_native.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <dlfcn.h>
#include <fcntl.h>
#include <map>
#include <memory>
#include <limits>
#include <mutex>
#include <string>
#include <thread>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <utility>
#include <vector>

#define RLOG(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, "CjguiRenderer", __VA_ARGS__)
#define RLOGE(...) OH_LOG_Print(LOG_APP, LOG_ERROR, 0x0000, "CjguiRenderer", __VA_ARGS__)
#define RLOGW(...) OH_LOG_Print(LOG_APP, LOG_WARN, 0x0000, "CjguiRenderer", __VA_ARGS__)
#define RLOGI(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, "CjguiRenderer", __VA_ARGS__)

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// Ingress（由 entry 桥在 cjgui_ohos_app_main 注册；函数指针非空才可用）
// ---------------------------------------------------------------------------

static CjguiOhosIngress g_ingress{};

// ---------------------------------------------------------------------------
// UTF-8 ⇄ UTF-16 转换（自包含；偏移单位 = UTF-16 码元，与 IME/仓颉 String 一致）
// ---------------------------------------------------------------------------

namespace {

std::u16string utf8ToUtf16(const std::string &utf8)
{
    std::u16string out;
    size_t i = 0;
    while (i < utf8.size()) {
        unsigned char c = static_cast<unsigned char>(utf8[i]);
        uint32_t cp = 0;
        size_t len = 1;
        if (c < 0x80) cp = c;
        else if ((c & 0xE0) == 0xC0) { cp = c & 0x1F; len = 2; }
        else if ((c & 0xF0) == 0xE0) { cp = c & 0x0F; len = 3; }
        else if ((c & 0xF8) == 0xF0) { cp = c & 0x07; len = 4; }
        else { i += 1; continue; }  // 非法首字节：跳过
        if (i + len > utf8.size()) break;
        bool valid = true;
        for (size_t k = 1; k < len; ++k) {
            unsigned char cc = static_cast<unsigned char>(utf8[i + k]);
            if ((cc & 0xC0) != 0x80) { valid = false; break; }
            cp = (cp << 6) | (cc & 0x3F);
        }
        if (!valid) { i += len; continue; }
        i += len;
        if (cp >= 0x10000) {
            cp -= 0x10000;
            out.push_back(static_cast<char16_t>(0xD800 + (cp >> 10)));
            out.push_back(static_cast<char16_t>(0xDC00 + (cp & 0x3FF)));
        } else {
            out.push_back(static_cast<char16_t>(cp));
        }
    }
    return out;
}

std::string utf16ToUtf8(const std::u16string &utf16)
{
    std::string out;
    for (size_t i = 0; i < utf16.size(); ++i) {
        uint32_t cp = static_cast<uint16_t>(utf16[i]);
        if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < utf16.size()) {
            uint32_t lo = static_cast<uint16_t>(utf16[i + 1]);
            if (lo >= 0xDC00 && lo <= 0xDFFF) {
                cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                i += 1;
            }
        }
        if (cp < 0x80) out.push_back(static_cast<char>(cp));
        else if (cp < 0x800) {
            out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
            out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        } else if (cp < 0x10000) {
            out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
            out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        } else {
            out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
            out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        }
    }
    return out;
}

// 把 UTF-16 偏移收敛到完整码点边界（不拆代理对）。
uint32_t clampToCodePointBoundary(const std::u16string &text, uint32_t offset)
{
    if (offset > text.size()) return static_cast<uint32_t>(text.size());
    if (offset > 0 && offset < text.size()) {
        uint16_t prev = static_cast<uint16_t>(text[offset - 1]);
        uint16_t cur = static_cast<uint16_t>(text[offset]);
        if (prev >= 0xD800 && prev <= 0xDBFF && cur >= 0xDC00 && cur <= 0xDFFF) {
            return offset - 1;  // 落在代理对中间：回退到码点起点
        }
    }
    return offset;
}

}  // namespace

// ArkTS TextInput 代理路径入口（bridge 经 C ABI 调用；定义在文件尾）
void ohos_renderer_ime_commit_text(const char *text, size_t length);
void (*g_focusRequestSink)(const char *fieldName) = nullptr;
void ohos_renderer_ime_preview_text(const char *text, size_t length);
void ohos_renderer_ime_finish_editing();
// JSON 字符串转义（定义在文件末的通用文字代理段；pump 的焦点请求先用）。
static void appendJsonEscaped(std::string &out, const std::string &value);
void ohos_renderer_set_focus_sink(void (*sink)(const char *fieldName));

// ---------------------------------------------------------------------------
// 会话与场景
// ---------------------------------------------------------------------------

namespace {

constexpr size_t kMaxSessions = 4;
constexpr uint32_t kKindVertical = 1;
constexpr uint32_t kKindHorizontal = 2;
constexpr uint32_t kKindText = 3;
constexpr uint32_t kKindButton = 4;
constexpr uint32_t kKindTextInput = 5;
constexpr uint32_t kKindIntegerInput = 6;
constexpr uint32_t kKindBooleanInput = 7;
constexpr uint32_t kKindScrollArea = 8;
constexpr uint32_t kKindImage = 9;
constexpr uint32_t kKindMultiline = 10;

// BEGIN CJGUI OHOS IMAGE GEOMETRY
struct OhosImageGeometry {
    float sourceLeft = 0, sourceTop = 0, sourceRight = 0, sourceBottom = 0;
    float destLeft = 0, destTop = 0, destRight = 0, destBottom = 0;
};

// Source crop and destination are computed together, so fit/fill and node
// clipping cannot disagree about the part of the image that is presented.
static bool cjguiOhosImageGeometry(uint32_t sourceWidth, uint32_t sourceHeight,
                                   int64_t boxX, int64_t boxY, int64_t boxWidth,
                                   int64_t boxHeight, uint32_t contentMode,
                                   OhosImageGeometry *out)
{
    if (!out || sourceWidth == 0 || sourceHeight == 0 || boxWidth <= 0 || boxHeight <= 0) return false;
    const double sx = static_cast<double>(boxWidth) / sourceWidth;
    const double sy = static_cast<double>(boxHeight) / sourceHeight;
    const double scale = contentMode == 2 ? std::max(sx, sy) : std::min(sx, sy);
    if (!std::isfinite(scale) || scale <= 0) return false;
    double srcL = 0, srcT = 0, srcR = sourceWidth, srcB = sourceHeight;
    double dstL = boxX, dstT = boxY, dstR = static_cast<double>(boxX) + boxWidth;
    double dstB = static_cast<double>(boxY) + boxHeight;
    if (contentMode == 2) {
        const double croppedW = static_cast<double>(boxWidth) / scale;
        const double croppedH = static_cast<double>(boxHeight) / scale;
        srcL = (sourceWidth - croppedW) / 2.0;
        srcT = (sourceHeight - croppedH) / 2.0;
        srcR = srcL + croppedW;
        srcB = srcT + croppedH;
    } else {
        const double drawnW = sourceWidth * scale;
        const double drawnH = sourceHeight * scale;
        dstL += (boxWidth - drawnW) / 2.0;
        dstT += (boxHeight - drawnH) / 2.0;
        dstR = dstL + drawnW;
        dstB = dstT + drawnH;
    }
    if (!std::isfinite(dstL) || !std::isfinite(dstT) || !std::isfinite(dstR) ||
        !std::isfinite(dstB)) return false;
    *out = {static_cast<float>(srcL), static_cast<float>(srcT),
            static_cast<float>(srcR), static_cast<float>(srcB),
            static_cast<float>(dstL), static_cast<float>(dstT),
            static_cast<float>(dstR), static_cast<float>(dstB)};
    return true;
}
// END CJGUI OHOS IMAGE GEOMETRY

// 提交未定状态（Sol 协议；核心 isRecoverable 白名单不含它 → 保留 accepted 不重试）
constexpr int32_t CJGUI_INTERNAL_RENDERER_PENDING = 20;

// 应用停止协议（Sol 关闭链）：Ability onDestroy → requestApplicationStop()；
// pump_event 生成 CLOSE_REQUESTED(1) → 核心 discardSession → owner 循环退出。
static std::atomic<bool> g_applicationStopRequested{false};
static std::atomic<bool> g_rendererShutdownDone{false};
// A3：owner 是否已声明就绪（由 cjgui_ohos_notify_app_ready 置位）。
// 这是「应用真的起来了」的唯一声明来源；宿主不从时间或入口返回来推断。
static std::atomic<bool> g_ownerAppReady{false};
// 测量失败窗口计数（诊断：caret 命中测量失败时不改光标，计数用于区分反例）。
static std::atomic<int64_t> kCaretHitTestFailureWindow{0};
// 结算计数（PENDING 票据的一次性 commit/rollback 判决），供取证与测试断言。
static std::atomic<int64_t> g_committedSettlements{0};
static std::atomic<int64_t> g_abortedSettlements{0};
static std::atomic<int32_t> g_lastSettlementVerdict{0};
// 渲染器启动代际：每次应用停止协议完成后递增，重开必须使用新身份。
static std::atomic<int32_t> g_rendererEpoch{0};



constexpr uint32_t kEvActivate = 27;
constexpr uint32_t kEvTextChanged = 28;
constexpr uint32_t kEvBooleanChanged = 29;
constexpr uint32_t kEvScroll = 30;
constexpr uint32_t kEvFocus = 31;
constexpr uint32_t kEvSelectionChanged = 33;
constexpr uint32_t kEvPointerBegin = 37;
constexpr uint32_t kEvPointerUpdate = 38;
constexpr uint32_t kEvPointerEnd = 39;
constexpr uint32_t kEvPointerCancel = 40;

// 渲染等待上限：present/measure 事务超时后不得再推进任何已接受状态。
constexpr auto kRenderWaitTimeout = std::chrono::milliseconds{2000};
// pump_event 的等待上限与 macOS 侧一致（16ms 量级），保证仓颉 owner 及时拿回控制权。
constexpr auto kPumpWaitMax = std::chrono::milliseconds{16};

// 第七次复核链2（Astra Q4）：平台调用生命周期计数——Create/Draw/Flush/
// Destroy 的 enter/exit 按代际记录，供「回调返回边界后零悬空使用」验收。
// enter 在调用前递增，exit 在调用返回后递增；enter!=exit 即在途访问。
// 计数本身无条件编译（使用点在生产路径上）；packed 导出仅在测试变体。
struct PlatformCallCounters {
    std::atomic<int64_t> createEnter{0}, createExit{0};
    std::atomic<int64_t> drawEnter{0}, drawExit{0};
    std::atomic<int64_t> flushEnter{0}, flushExit{0};
    std::atomic<int64_t> destroyEnter{0}, destroyExit{0};
    std::atomic<uint64_t> lastAccessGen{0};
    std::atomic<int64_t> postBoundaryAttempts{0};  // 返回边界后访问尝试
};
PlatformCallCounters g_pcCalls;

// 第九次复核 A1：backend 类型固定在资源句柄上——创建时决定、销毁前不变；
// ARM/DISARM 只影响后续准入，模式切换不改变既有对象的释放器。
enum class SurfaceBackend : int32_t { None = 0, Real = 1, Stub = 2 };

#ifdef CJGUI_OHOS_TEST_GATES
// ---------------------------------------------------------------------------
// 链2（Astra Q4）：可注入平台调用替身适配器。
// 替身拥有自身对象（OhosStubSurface，由替身表管理生命周期），**不接收真实
// XComponent/window 裸指针**（present 入参 window 在替身路径中原样丢弃）；
// Create/Draw/Flush/Destroy 按**身份（generation）** enter/exit 计数，并可按
// (阶段, 身份) 阻塞——制造 retire-during-held 确定性交错。替身租约
// （g_stubLeaseGen）只 feed 生产 leaseValid 检查点（绘制前/Flush 前/许可后
// 复核），不进宿主 surface 表、不发布 degradedActive。仅测试变体编入。
struct OhosStubSurface {
    uint64_t generation;
    int32_t width;
    int32_t height;
    bool flushed;
};
struct OhosStubCounts {
    std::atomic<int64_t> createEnter{0}, createExit{0};
    std::atomic<int64_t> drawEnter{0}, drawExit{0};
    std::atomic<int64_t> flushEnter{0}, flushExit{0};
    std::atomic<int64_t> destroyEnter{0}, destroyExit{0};
};
constexpr int kOhosStubGenSlots = 8;   // 测试身份取 gen%8；探针用小代号
OhosStubCounts g_stubCounts[kOhosStubGenSlots];
std::mutex g_stubMutex;
std::vector<OhosStubSurface *> g_stubLive;   // 替身拥有的活对象
std::atomic<bool> g_stubArmed{false};
std::atomic<uint64_t> g_stubLeaseGen{0};
// 身份阻塞：命中 (stage, gen) 的调用在渲染线程 park（超时自动放行只作清理，
// 语义由调用点后续的生产检查仲裁）。阶段：0=create(许可后/复核前)
// 1=create_return(返回后) 2=draw 3=flush。
std::mutex g_stubHoldMutex;
std::condition_variable g_stubHoldCv;
std::atomic<int> g_stubHoldStage{-1};
std::atomic<uint64_t> g_stubHoldGen{0};
std::atomic<int32_t> g_stubHoldMs{0};
std::atomic<bool> g_stubHoldActive{false};
std::atomic<bool> g_stubHoldRelease{false};

inline int ohosStubSlot(uint64_t gen) { return static_cast<int>(gen % kOhosStubGenSlots); }

void cjguiOhosStubHold(int stage, uint64_t gen)
{
    if (!g_stubArmed.load()) return;
    if (g_stubHoldStage.load() != stage || g_stubHoldGen.load() != gen) return;
    g_stubHoldActive.store(true);
    auto deadline = std::chrono::steady_clock::now() +
                    std::chrono::milliseconds(g_stubHoldMs.load());
    std::unique_lock<std::mutex> lk(g_stubHoldMutex);
    while (!g_stubHoldRelease.load() && std::chrono::steady_clock::now() < deadline) {
        g_stubHoldCv.wait_for(lk, std::chrono::milliseconds(20));
    }
    g_stubHoldActive.store(false);
    // 一次性：命中即解除配置，防止后续代误停。
    g_stubHoldStage.store(-1);
    g_stubHoldGen.store(0);
    g_stubHoldRelease.store(false);
}

// ---------------------------------------------------------------------------
// 受控测试闸门（仅 -DCJGUI_OHOS_TEST_GATES 的测试构建变体编译）。
// 目的：用生产路径 + 可控时序制造超时/取消交错/退役竞态，不必等待模拟器
// 提供 graceful-destroy 之类的新命令。闸门只影响时序，不改变提交语义。
// ---------------------------------------------------------------------------
std::mutex g_gateMutex;
std::condition_variable g_gateCv;
int g_gateFlushHoldMs = 0;         // Committing 内阻塞时长（制造 committing 超时）
int g_gateFlushHoldRemaining = 0;  // 还要按住几次 Flush；-1 = 每次按住（默认 0 = 不按）
int g_gateDequeueHoldMs = 0;       // 出队后执行前阻塞（制造 queued 超时）
bool g_gateStopCancelled = false;  // 本 renderer 实例停止后，旧代闸门不得再持有任务
int32_t g_gateFlushCount = 0;      // 统计真实进入 Flush 的次数
int32_t g_gateFlushHeldCount = 0;  // 统计闸门**实际按住**的次数（取证用）
// A1 矩阵注入：fail-next 在提交执行早期强制该票以非 OK 终态结束（生产结算
// 路径据此裁决 Rejected）；fail-next-ack 让接下来 N 次 ACK 返回错误（核心
// 保留已结算事务并重试原 ACK）。计数器只做取证，不改变生产语义。
int g_gateFailNextJob = 0;
int g_gateFailNextAck = 0;
// A3：首帧强制失败（启动失败反例）。首个 present 消费一次。
int g_gateFailFirstFrame = 0;
int32_t g_gateJobFailCount = 0;
int32_t g_gateAckFailCount = 0;
// A2 八类闸门：按阶段持有（ms×次数，按住 N 次后自动解除），制造
// 「许可后/创建前/创建后/绘制中/提交准入前」与销毁重建的交错。
// holdRemaining == -1 表示每次都按住（探针显式 CLEAR 解除）。
int g_gateHoldPermitMs = 0;        // 取得使用许可后、创建 surface 前
int g_gateHoldPermitRemaining = 0;
int g_gateHoldCreateMs = 0;        // SurfaceCreateOnScreen 调用前
int g_gateHoldCreateRemaining = 0;
int g_gateHoldCreateReturnMs = 0;  // 创建调用返回后（成功与否皆算）
int g_gateHoldCreateReturnRemaining = 0;
int g_gateHoldDrawMs = 0;          // 取得 canvas、绘制中段
int g_gateHoldDrawRemaining = 0;
int g_gateHoldAdmissionMs = 0;     // 最终提交准入（acquireCommitPermission）前
int g_gateHoldAdmissionRemaining = 0;
// A2 取证：各阶段真实到达次数（与 held 区分——held 只统计实际按住的）。
int32_t g_gatePermitCount = 0;
int32_t g_gateCreateCount = 0;
int32_t g_gateCreateOkCount = 0;
int32_t g_gateDrawCount = 0;
int32_t g_gateAdmissionCount = 0;

// 第七次复核 A4：各阶段「真实 held」计数——只有闸门**实际按住**时才递增
// （到达但未武装不计入）。绑定本实例生命周期，经 packed 导出供探针断言，
// 替代易被轮转丢失的 hilog 见证。
// 槽位：0=permit 1=create 2=create_return 3=draw 4=admission 5=flush 6=dequeue
int32_t g_gateStageHeld[7] = {0, 0, 0, 0, 0, 0, 0};
void gateStageHeldBump(int slot)
{
    if (slot >= 0 && slot < 7) {
        g_gateStageHeld[slot] += 1;
    }
}
int gateStageHeldSlot(const char *what)
{
    // strcmp 链（避免引入 <cstring> 之外的依赖；what 来自本文件字面量）。
    if (std::strcmp(what, "permit") == 0) return 0;
    if (std::strcmp(what, "create_before") == 0) return 1;
    if (std::strcmp(what, "create_return") == 0) return 2;
    if (std::strcmp(what, "draw") == 0) return 3;
    if (std::strcmp(what, "admission") == 0) return 4;
    if (std::strcmp(what, "flush") == 0) return 5;
    if (std::strcmp(what, "dequeue") == 0) return 6;
    return -1;
}

// 闸门必须在被按住的那一次 Flush 前生效、并在按住次数用尽后自动解除：
// 否则首帧超时后每一帧都会继续超时，窗口永远到不了 Ready，矩阵只剩
// 「停在 Pending」一个观测点，无法验证 Pending→Accepted 的推进。
void cjguiOhosTestGateBeforeFlush()
{
    std::unique_lock<std::mutex> g(g_gateMutex);
    g_gateFlushCount += 1;
    if (g_gateStopCancelled || g_gateFlushHoldMs <= 0 || g_gateFlushHoldRemaining == 0) {
        return;
    }
    if (g_gateFlushHoldRemaining > 0) {
        g_gateFlushHoldRemaining -= 1;
    }
    g_gateFlushHeldCount += 1;
    // 直接留证：闸门**确实**按住了这一次 Flush（而不是仅仅被请求过）。
    RLOGW("test gate holding flush ms=%{public}d remaining=%{public}d held=%{public}d",
          g_gateFlushHoldMs, g_gateFlushHoldRemaining, g_gateFlushHeldCount);
    gateStageHeldBump(5);
    // 第七次复核 A4：deadline 循环等待——共享 cv 的提前通知/伪唤醒不得
    // 提前放行；release（holdMs→0）才允许提前结束。
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(g_gateFlushHoldMs);
    while (!g_gateStopCancelled && g_gateFlushHoldMs > 0 && std::chrono::steady_clock::now() < deadline) {
        g_gateCv.wait_until(g, deadline);
    }
}

void cjguiOhosTestGateBeforeExecute(uint64_t session, uint64_t ticketId, uint64_t generation)
{
    std::unique_lock<std::mutex> g(g_gateMutex);
    if (!g_gateStopCancelled && g_gateDequeueHoldMs > 0) {
        gateStageHeldBump(6);
        RLOGW("test gate holding dequeue session=%{public}llu ticket=%{public}llu gen=%{public}llu",
              static_cast<unsigned long long>(session), static_cast<unsigned long long>(ticketId),
              static_cast<unsigned long long>(generation));
        auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(g_gateDequeueHoldMs);
        while (!g_gateStopCancelled && g_gateDequeueHoldMs > 0 && std::chrono::steady_clock::now() < deadline) {
            g_gateCv.wait_until(g, deadline);
        }
        RLOGW("test gate dequeue released session=%{public}llu ticket=%{public}llu gen=%{public}llu",
              static_cast<unsigned long long>(session), static_cast<unsigned long long>(ticketId),
              static_cast<unsigned long long>(generation));
    }
}

// A1 注入：下一次 present 执行早期强制失败（→ 生产结算裁决 Rejected）。
// 返回 true 表示本次注入已生效（闸门消耗一次并计数）。
bool cjguiOhosTestGateConsumeFailNextJob()
{
    std::lock_guard<std::mutex> g(g_gateMutex);
    if (g_gateFailNextJob <= 0) {
        return false;
    }
    g_gateFailNextJob -= 1;
    g_gateJobFailCount += 1;
    RLOGW("test gate injecting job failure remaining=%{public}d total=%{public}d",
          g_gateFailNextJob, g_gateJobFailCount);
    return true;
}

bool cjguiOhosTestGateConsumeFailNextAck()
{
    std::lock_guard<std::mutex> g(g_gateMutex);
    if (g_gateFailNextAck <= 0) {
        return false;
    }
    g_gateFailNextAck -= 1;
    g_gateAckFailCount += 1;
    RLOGW("test gate injecting ack failure remaining=%{public}d total=%{public}d",
          g_gateFailNextAck, g_gateAckFailCount);
    return true;
}

// A2 阶段持有：按住 ms 毫秒后按剩余次数自动解除（-1 = 常驻，CLEAR 解除）。
void cjguiOhosTestGateHold(const char *what, int &holdMs, int &remaining)
{
    std::unique_lock<std::mutex> g(g_gateMutex);
    if (g_gateStopCancelled || holdMs <= 0 || remaining == 0) {
        return;
    }
    RLOGW("test gate holding %{public}s ms=%{public}d remaining=%{public}d",
          what, holdMs, remaining);
    if (remaining > 0) {
        remaining -= 1;
    }
    gateStageHeldBump(gateStageHeldSlot(what));
    // 第七次复核 A4：deadline 循环——共享 cv 的提前通知/伪唤醒不可提前
    // 放行；release（holdMs→0，gateSetHold 通知）才允许提前结束。
    auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(holdMs);
    while (!g_gateStopCancelled && holdMs > 0 && std::chrono::steady_clock::now() < deadline) {
        g_gateCv.wait_until(g, deadline);
    }
}

void cjguiOhosTestGateBeginRendererEpoch()
{
    std::lock_guard<std::mutex> g(g_gateMutex);
    g_gateStopCancelled = false;
}

void cjguiOhosTestGateCancelRendererEpoch()
{
    {
        std::lock_guard<std::mutex> g(g_gateMutex);
        g_gateStopCancelled = true;
    }
    g_gateCv.notify_all();
}

int32_t cjguiOhosTestFlushCount()
{
    std::lock_guard<std::mutex> g(g_gateMutex);
    return g_gateFlushCount;
}
#else
#define cjguiOhosTestGateBeforeFlush() ((void)0)
#define cjguiOhosTestGateBeforeExecute(session, ticketId, generation) ((void)0)
#define cjguiOhosTestGateBeginRendererEpoch() ((void)0)
#define cjguiOhosTestGateCancelRendererEpoch() ((void)0)
static int32_t cjguiOhosTestFlushCount() { return 0; }
#endif

// 测试闸门控制入口（A1 反例注入点：卡住首帧与正常 Flush 制造 PENDING）。
//
// 通道：应用内 **不发生**任何控制路径。命令由启动参数（`aa start --pi`）带进
// ArkTS，EntryAbility 在 onCreate 里经宿主桥 NAPI 转发到本函数；仓颉应用循环
// 与渲染线程都不读任何外部控制帧。这样闸门只影响时序，不新增生产入口。
//
// 两个变体都导出同名符号，因此调用方不必按变体分叉；但**生产产物返回 -1
// 表示闸门不可用**，不提供任何时序影响——闸门只在 ohos_renderer.cpp 以
// -DCJGUI_OHOS_TEST_GATES 编译的测试产物里才真正生效。`count` 为还要按住
// 的 Flush 次数（1 = 只卡首帧，负数 = 每次按住），使矩阵能观察到
// Pending→Accepted 的完整推进而不是停在 Pending。
extern "C" int32_t cjgui_ohos_test_gate_set_flush_hold_ms(int32_t ms, int32_t count)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    g_gateFlushHoldMs = ms < 0 ? 0 : ms;
    g_gateFlushHoldRemaining = (ms <= 0) ? 0 : (count == 0 ? 1 : count);
    return 0;
#else
    (void)ms;
    (void)count;
    return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_flush_count(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return cjguiOhosTestFlushCount();
#else
    return -1;
#endif
}

// 闸门实际按住次数（只读取证）。测试产物返回 >=0；普通产物返回 -1，
// 使「普通产物没有闸门行为」可以被断言而不是靠推断。
extern "C" int32_t cjgui_ohos_test_gate_flush_held_count(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    return g_gateFlushHeldCount;
#else
    return -1;
#endif
}

// A1 矩阵注入：设置「接下来 N 次 present 执行强制失败」与「接下来 N 次 ACK
// 失败」。普通产物返回 -1（无闸门行为）。
extern "C" int32_t cjgui_ohos_test_gate_set_fail_next(int32_t jobs, int32_t acks)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    g_gateFailNextJob = jobs < 0 ? 0 : jobs;
    g_gateFailNextAck = acks < 0 ? 0 : acks;
    g_gateCv.notify_all();
    return 0;
#else
    (void)jobs;
    (void)acks;
    return -1;
#endif
}

// 出队闸门时长设置（GATE_CLEAR 置 0 并唤醒等待中的出队）。
extern "C" int32_t cjgui_ohos_test_gate_set_dequeue_hold_ms(int32_t ms)
{
#ifdef CJGUI_OHOS_TEST_GATES
    {
        std::lock_guard<std::mutex> g(g_gateMutex);
        g_gateDequeueHoldMs = ms < 0 ? 0 : ms;
    }
    g_gateCv.notify_all();
    return 0;
#else
    (void)ms;
    return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_set_flush_hold_release(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    {
        std::lock_guard<std::mutex> g(g_gateMutex);
        g_gateFlushHoldMs = 0;
        g_gateFlushHoldRemaining = 0;
    }
    g_gateCv.notify_all();
    return 0;
#else
    return -1;
#endif
}

// A2 八类闸门设置器：ms<=0 解除；hold_n=按住次数（0 按 1 次，-1 常驻）。
#ifdef CJGUI_OHOS_TEST_GATES
static int32_t gateSetHold(int &ms, int &remaining, int32_t a, int32_t b)
{
    std::lock_guard<std::mutex> g(g_gateMutex);
    ms = a < 0 ? 0 : a;
    remaining = (a <= 0) ? 0 : (b == 0 ? 1 : b);
    g_gateCv.notify_all();
    return 0;
}
#else
static int32_t gateSetHold(int &ms, int &remaining, int32_t a, int32_t b)
{
    (void)ms; (void)remaining; (void)a; (void)b;
    return -1;
}
#endif

extern "C" int32_t cjgui_ohos_test_gate_set_hold_permit(int32_t ms, int32_t hold_n)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return gateSetHold(g_gateHoldPermitMs, g_gateHoldPermitRemaining, ms, hold_n);
#else
    (void)ms; (void)hold_n; return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_set_hold_create(int32_t ms, int32_t hold_n)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return gateSetHold(g_gateHoldCreateMs, g_gateHoldCreateRemaining, ms, hold_n);
#else
    (void)ms; (void)hold_n; return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_set_hold_create_return(int32_t ms, int32_t hold_n)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return gateSetHold(g_gateHoldCreateReturnMs, g_gateHoldCreateReturnRemaining, ms, hold_n);
#else
    (void)ms; (void)hold_n; return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_set_hold_draw(int32_t ms, int32_t hold_n)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return gateSetHold(g_gateHoldDrawMs, g_gateHoldDrawRemaining, ms, hold_n);
#else
    (void)ms; (void)hold_n; return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_set_hold_admission(int32_t ms, int32_t hold_n)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return gateSetHold(g_gateHoldAdmissionMs, g_gateHoldAdmissionRemaining, ms, hold_n);
#else
    (void)ms; (void)hold_n; return -1;
#endif
}

// A2 取证：把 6 个到达计数打包进调用方缓冲（顺序固定，普通产物全 -1）。
extern "C" int32_t cjgui_ohos_test_gate_a2_counts(int32_t *out6)
{
#ifdef CJGUI_OHOS_TEST_GATES
    if (out6 == nullptr) return -1;
    std::lock_guard<std::mutex> g(g_gateMutex);
    out6[0] = g_gatePermitCount;
    out6[1] = g_gateCreateCount;
    out6[2] = g_gateCreateOkCount;
    out6[3] = g_gateDrawCount;
    out6[4] = g_gateAdmissionCount;
    out6[5] = g_gateFlushCount;
    return 0;
#else
    (void)out6; return -1;
#endif
}

// 第七次复核 A4：各阶段真实 held 计数的 packed 读数（每槽 9 位饱和，
// 槽位见 gateStageHeldSlot；顺序 permit/create/create_return/draw/
// admission/flush/dequeue）。探针据此断言「该阶段确实被按住」，不再
// 依赖可被轮转丢弃的 hilog 见证。
extern "C" int64_t cjgui_ohos_test_gate_stage_held_packed(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    int64_t packed = 0;
    for (int i = 0; i < 7; ++i) {
        int32_t v = g_gateStageHeld[i] > 511 ? 511 : g_gateStageHeld[i];
        packed |= (static_cast<int64_t>(v) & 0x1FF) << (i * 9);
    }
    return packed;
#else
    return -1;
#endif
}

// 第七次复核链2（Astra Q4）：平台调用生命周期计数 packed 读数——
// 每 8 位饱和：createE/createX/drawE/drawX/flushE/flushX/destroyE/destroyX。
// 验收断言：destroy 后 createE==createX（无在途）、返回边界后访问尝试为 0。
extern "C" int64_t cjgui_ohos_test_platform_call_packed(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    int64_t packed = 0;
    int64_t vals[8] = {
        g_pcCalls.createEnter.load(), g_pcCalls.createExit.load(),
        g_pcCalls.drawEnter.load(), g_pcCalls.drawExit.load(),
        g_pcCalls.flushEnter.load(), g_pcCalls.flushExit.load(),
        g_pcCalls.destroyEnter.load(), g_pcCalls.destroyExit.load()};
    for (int i = 0; i < 8; ++i) {
        int64_t v = vals[i] > 254 ? 254 : vals[i];
        packed |= (v & 0xFF) << (i * 8);
    }
    return packed;
#else
    return -1;
#endif
}
// M3 诊断：当前仍处于武装态的 fail-next 计数（区分「setter 未写入/状态副本
// 分裂」与「消费点未命中」——派发后读到 1 而消费未发生即消费点问题）。
extern "C" int32_t cjgui_ohos_test_gate_fail_armed(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    return g_gateFailNextJob;
#else
    return -1;
#endif
}

// A3 启动失败注入设置入口（首帧强制失败）。
extern "C" int32_t cjgui_ohos_test_gate_set_fail_first(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    g_gateFailFirstFrame = 1;
    return 0;
#else
    return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_job_fail_count(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    return g_gateJobFailCount;
#else
    return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_gate_ack_fail_count(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::lock_guard<std::mutex> g(g_gateMutex);
    return g_gateAckFailCount;
#else
    return -1;
#endif
}

// One application incarnation owns one immutable mapping from key/version to
// its sandbox asset. The decoder never holds a Surface permit. The only data
// crossing into the fixed drawing thread is ordinary owned pixel storage.
constexpr size_t kImageMaxEncoded = 4u * 1024u * 1024u;
constexpr size_t kImageMaxPixels = 4194304u;
constexpr size_t kImageMaxDecoded = 16u * 1024u * 1024u;
constexpr size_t kImageMaxOutstanding = 8u;
constexpr size_t kImageMaxRecords = 64u;
constexpr size_t kImageMaxBindings = 256u;
constexpr size_t kImageIdleBytes = 16u * 1024u * 1024u;
constexpr size_t kImageProcessBytes = 128u * 1024u * 1024u;
std::atomic<size_t> g_imageLiveBytes{0};
std::atomic<size_t> g_imageDecoderActiveBytes{0};
std::atomic<size_t> g_imageDecoderPeakBytes{0};

static void cjguiOhosRecordDecoderBytes(size_t bytes)
{
    g_imageDecoderActiveBytes.store(bytes);
    size_t peak = g_imageDecoderPeakBytes.load();
    while (peak < bytes && !g_imageDecoderPeakBytes.compare_exchange_weak(peak, bytes)) {}
}

struct OhosDecodedImage {
    uint32_t width = 0, height = 0, stride = 0;
    OH_Drawing_ColorFormat colorFormat = COLOR_FORMAT_BGRA_8888;
    OH_Drawing_AlphaFormat alphaFormat = ALPHA_FORMAT_PREMUL;
    std::vector<uint8_t> pixels;
    size_t accountedBytes = 0;
    ~OhosDecodedImage() { if (accountedBytes) g_imageLiveBytes.fetch_sub(accountedBytes); }
};

struct OhosImageEntry {
    const uint64_t id;
    const uint64_t epoch;
    const std::string key;
    const uint64_t version;
    const std::string path;
    uint64_t attempt = 0;
    uint64_t completionSerial = 0;
    uint64_t lastUse = 0;
    uint32_t state = 0;  // ABI: unrequested/loading/ready/failed/busy
    size_t reservation = 0;
    std::string failure;
    std::shared_ptr<OhosDecodedImage> decoded;
    std::shared_ptr<OhosDecodedImage> awaiting;
    bool realizationPosted = false;
    bool decoding = false;
#ifdef CJGUI_OHOS_TEST_GATES
    bool completionHeld = false;
#endif
    OhosImageEntry(uint64_t entryId, uint64_t domainEpoch, std::string resourceKey,
                   uint64_t resourceVersion, std::string assetPath)
        : id(entryId), epoch(domainEpoch), key(std::move(resourceKey)),
          version(resourceVersion), path(std::move(assetPath)) {}
};

using OhosImageRef = std::shared_ptr<OhosImageEntry>;

struct OhosImageDomain {
    std::mutex lock;
    std::condition_variable cv;
    std::thread decoder;
    bool decoderStarted = false;
    bool quitting = false;
    uint64_t epoch = 1;
    uint64_t nextEntryId = 1;
    uint64_t accessClock = 0;
    std::map<std::pair<std::string, uint64_t>, std::string> bindings;
    std::map<std::pair<std::string, uint64_t>, OhosImageRef> entries;
    std::deque<OhosImageRef> pending;
    size_t outstanding = 0;
    size_t reservedBytes = 0;
    uint64_t decodeStarts = 0, encodedReadBytes = 0, decodeMicros = 0, cacheHits = 0;
    uint64_t encodedReadMicros = 0;
    uint64_t staleDiscards = 0;
    size_t peakTrackedBytes = 0;
    size_t queued = 0;
    size_t inFlight = 0;
#ifdef CJGUI_OHOS_TEST_GATES
    uint64_t heldVersion = 0;
    bool holdEnabled = false;
#endif
    ~OhosImageDomain();
    CjguiInternalRendererStatus access(const char *path, const char *key, uint64_t version,
                                        bool request, bool explicitRetry, OhosImageRef *outEntry,
                                        uint32_t *outState);
    void invalidate();
    void decoderLoop();
    void releaseReservationLocked(const OhosImageRef &entry);
    bool validLocked(const OhosImageRef &entry) const;
    void trimIdleLocked(std::vector<OhosImageRef> *retired, bool reserveAdmissionSlot);
    bool pruneReleasedIdle();
};

OhosImageDomain g_images;
void cjguiOhosPostImageRealization(const OhosImageRef &entry);
void cjguiOhosNotifyImageCompletion(const OhosImageRef &entry);
void cjguiOhosPruneReleasedImages();
void cjguiOhosRequestImageBitmapPrune();

struct OhosImageRetirementWake {
    std::vector<OhosImageRef> retired;
    ~OhosImageRetirementWake() noexcept
    {
        if (retired.empty()) return;
        // Admission can evict an old entry without any subsequent render job
        // (including on a capacity return). Drop all refs before waking the
        // renderer, otherwise its weak-entry bitmap pass can run too early.
        retired.clear();
        cjguiOhosRequestImageBitmapPrune();
    }
};

struct SceneNode {
    CjguiInternalRendererComposableNode pod{};
    std::string label;
    std::string value;
    std::string semanticId;
    OhosImageRef image;
};



struct QueuedEvent {
    uint32_t kind = 0;
    uint32_t recordIndex = 0;
    uint32_t selectionStart = 0;
    uint32_t selectionEnd = 0;
    uint64_t nodeId = 0;
    uint64_t projectionVersion = 0;
    int64_t resourceId = -1;
    uint32_t nodeKind = 0;
    int64_t pointerX = 0;
    int64_t pointerY = 0;
    int64_t scrollDelta = 0;  // B：滚动意图的累计逻辑位移（text = "by:<delta>"）
    uint64_t gestureEpoch = 0; // B：GestureKey 贯穿事件到核心捕获
    uint64_t appInstance = 0;
    uint64_t componentInstance = 0;
    uint64_t surfaceGeneration = 0;
    int64_t pointerId = -1;
    uint64_t acceptedBindingEpoch = 0;
    std::string text;
};

struct RawTouchSample {
    uint32_t action;
    float x;
    float y;
    uint64_t appInstance;
    uint64_t componentInstance;
    uint64_t surfaceGeneration;
    int64_t pointerId;
    uint64_t gestureEpoch;
    // B（惯性包）：原始采样时间（随记录传递，与 key 绑定）。
    int64_t timestampNs = 0;
    uint32_t timeSource = 0;  // 0=平台单调 ns 1=桥接收时间
};

struct Session {
    bool inUse = false;
    uint64_t token = 0;

    std::string title;
    uint32_t windowWidth = 0;
    uint32_t windowHeight = 0;
    double clearR = 0.08, clearG = 0.16, clearB = 0.20, clearA = 1.0;
    bool rangeEditDeltaRequested = false;
    bool closeRequested = false;

    // 最近一次观察到的 surface 事实（viewport 与 resizeVersion 的来源）
    uint64_t surfaceGeneration = 0;
    uint64_t surfaceGeometryRevision = 0;
    uint64_t surfaceResizeVersion = 0;
    int32_t surfaceWidth = 0;
    int32_t surfaceHeight = 0;
    double surfaceDensity = 1.0;
    bool surfaceSeen = false;

    // 已接受场景（present 成功后晋升）与候选事务
    std::vector<SceneNode> accepted;
    uint64_t acceptedProjectionVersion = 0;
    bool candidateOpen = false;
    uint64_t candidateProjectionVersion = 0;
    std::vector<SceneNode> candidate;
    uint64_t imageCompletionVersion = 0;
    std::map<uint64_t, uint64_t> imageObservedSerial;

    // 事件 FIFO 与最近一次 pump 出的事件文本（form_event_text 的生命周期）
    std::deque<QueuedEvent> events;
    std::string lastEventText;

    uint64_t submittedFrameIndex = 0;
    // A1 票据协议（Astra pending-transaction/answer.md 第 1/2 点）：本会话
    // 单调递增的提交票据编号，以及当前尚未 ACK 的票据。每会话最多一张未确认
    // 票据；未 ACK 之前 present 不再投递新候选，也不代替 owner 结算旧票据。
    uint64_t nextTicketId = 1;
    uint64_t unackedTicketId = 0;
    // 票据取证计数（断言“仅结算一次”、无重复结算，见 present_ticket_stats）。
    int64_t ticketAcceptedCount = 0;
    int64_t ticketRejectedCount = 0;
    int64_t ticketQueryCount = 0;
    int64_t ticketAckCount = 0;
    int64_t ticketDuplicateSettlementCount = 0;
    int64_t ticketDestroyRefusedCount = 0;
    // B：单指触摸手势（待定点击 / 视口滚动 / 指针拖动 / 已激活编辑器长按）。
    // 起始绑定 accepted 目标身份、包含视口身份与 surface 代次；阈值前待定，
    // 超阈值由视口接管并取消子控件点击；有效抬起才执行一次点击，移出、
    // 取消、退役或换代都不激活。纯滚动不修改业务 owner、不结算焦点。
    struct TouchGesture {
        // 0=pending 1=scroll 2=pointer-drag 3=editor-hold（已激活编辑器优先）
        enum Phase : uint32_t {
            kGesturePending = 0,
            kGestureScroll = 1,
            kGesturePointerDrag = 2,
            kGestureEditorHold = 3,
        };
        bool active = false;
        uint32_t phase = kGesturePending;
        float startX = 0.0f, startY = 0.0f;
        float lastX = 0.0f, lastY = 0.0f;
        bool hasTarget = false;          // BEGIN 命中的子控件（滚动接管后取消）
        bool targetEditableText = false; // 单行/整数编辑器（与既有激活语义同集）
        uint64_t targetNodeId = 0;
        uint64_t targetBindingEpoch = 0;
        int64_t targetResourceId = -1;
        uint32_t targetNodeKind = 0;
        bool hasViewport = false;        // 包含视口（SCROLL_AREA 身份，与命中分开）
        uint64_t viewportNodeId = 0;
        uint64_t viewportBindingEpoch = 0;
        int64_t viewportResourceId = -1;
        uint64_t surfaceGeneration = 0;  // 手势起始的 surface 代次
        int64_t pressBeginMs = 0;        // 可编辑文本长按计时
        // B：起始绑定冻结与位移/捕获簿记。
        uint64_t targetProjectionVersion = 0; // 按下时场景版本（记录用；绑定以 accepted epoch 判定）
        std::string targetSemanticId;         // 语义快照（诊断用）
        bool thresholdLatch = false;          // A：跨阈值不可逆闰（回起点不恢复点击）
        float scrollAccumY = 0.0f;            // 浮点位移余量（整数交付后保留小数）
        double scrollRawSumY = 0.0;           // 当前 GestureKey 消费的原始逻辑位移
        int64_t scrollWholeDeliveredY = 0;    // 已送入共享 viewport 的整数位移
        uint64_t scrollSampleCount = 0;       // UPDATE/END 共用采样入口次数
        bool scrollEndConfirmed = false;       // 真实 END；其他终结按取消记录
        bool pointerStreamOpen = false;       // 指针相位流已开（37 已入队）
        bool pointerStreamEnded = false;      // 终结恰好一次（END/CANCEL 任一）
        uint64_t gestureEpoch = 0;             // B：GestureKey 贯穿全链
        // B（惯性包）：近期样本窗（固定容量，Flutter velocity_tracker 思路），
        // 用于 END 后估计释放速度。样本为 (timestampNs, y) 对。
        static constexpr size_t kVelocityWindow = 8;
        float velWindowY[kVelocityWindow] = {0};
        int64_t velWindowT[kVelocityWindow] = {0};
        size_t velWindowCount = 0;
        uint64_t appInstance = 0;
        uint64_t componentInstance = 0;
        int64_t pointerId = -1;
    };
    TouchGesture gesture;
    // C：字段切换时旧编辑上下文的收场身份（pump 的 end 通知按此取值，
    // 不得读新上下文字段）。
    int64_t detachContextId = 0;
    std::string detachFieldName;
    // C：本编辑上下文是否已经公共通道请求过屏外 reveal（核心 flush 一次到
    // 位后按当前几何聚焦；超出夹紧上限时按可见部分聚焦，不重复请求）。
    bool editingContextRevealRequested = false;
    uint64_t loggedResizeVersion = 0;

    // 平台编辑缓冲：交互投影（非业务 owner）。偏移单位 = UTF-16 码元。
    // 编辑值以本缓冲为准；owner 的新场景必须先与活上下文对账，即使有预览。
    bool editing = false;
    uint64_t editingNodeId = 0;
    int64_t editingResourceId = -1;
    uint32_t editingNodeKind = 0;
    uint64_t editingProjectionVersion = 0;
    std::u16string editingText;
    uint32_t caretUtf16 = 0;
    uint32_t selStartUtf16 = 0;
    uint32_t selEndUtf16 = 0;
    // C selection：长按计时（文本节点 BEGIN 落账，END 判时长）；0 = 无按下。
    int64_t textPressBeginMs = 0;
    std::u16string previewText;   // 完整可见草稿（纯视觉，不进 owner）
    uint32_t previewStart = 0;
    uint32_t previewEnd = 0;
    bool previewActive = false;
    // ArkUI PreviewText 的区间属于完整可见草稿，不是 editingText 的替换区间。
    bool markedActive = false;
    uint32_t markedStart = 0;
    uint32_t markedEnd = 0;
    bool markedCallbackObserved = false;
    bool pendingImeAttach = false;
    bool pendingImeDetach = false;
    // 框架主动结束编辑（点到别处/空白）时的失焦语义：未提交的组合预览必须
    // 按当前可见值结算给 owner，恰好一次。平台侧 finish 触发的 detach 不置此位
    // （值已由平台提交路径写入，再结算就是重复写）。
    bool pendingSettleOnDetach = false;
    // 逻辑编辑已结束（上下文失效、平台代理释放、延迟回调被拒），但原生编辑器
    // 仍是该节点的绘制方。核心的「本地文字延续」窗口会把 native 值置空并约定
    // 由 native 编辑器绘制可见文本（macOS 用输入代理的字符串做同一件事）；若在
    // 结算前就停止绘制，那一次投影就会把字段画成空白。因此 retirement 只结束
    // 上下文与代理，不结束绘制；下一次聚焦按 accepted 值重新初始化缓冲。
    bool editorRetired = false;
    double editingTapX = 0.0;
    bool editingTapPending = false;
    bool focusNotifyPending = false;
    bool reconcileNotifyPending = false;
    int64_t reconcileOldContextId = 0;
    // 通用文字代理上下文（不透明）：关联 session、节点/绑定、编辑代际与基版本。
    // 平台代理的每次延迟回调必须携带并校验它；不匹配的回调不得改写编辑状态。
    int64_t editingContextId = 0;
    std::string editingFieldName;
    uint64_t editingContextGeneration = 0;     // 分配上下文时的 surface 代际
    uint64_t editingContextBaseVersion = 0;    // 分配上下文时的场景投影版本
    bool editingContextLive = false;
};

// BEGIN CJGUI OHOS IMAGE LEASE DIAGNOSTICS
// A normal-HAP, identity-scoped account of accepted scene ownership. This
// reads only immutable entry identity and SceneNode refs while sessions.lock is
// held; it neither takes the image-domain lock nor extends a resource lifetime.
constexpr size_t kImageLeaseKeyHexCapacity = 321;  // admitted key <= 160 bytes
std::atomic<uint64_t> g_imageLeaseSwapSeq{0};

static bool cjguiOhosImageKeyHex(const std::string &key,
                                 std::array<char, kImageLeaseKeyHexCapacity> *out)
{
    static constexpr char digits[] = "0123456789abcdef";
    const size_t count = std::min(key.size(), (out->size() - 1) / 2);
    for (size_t i = 0; i < count; ++i) {
        const unsigned char byte = static_cast<unsigned char>(key[i]);
        (*out)[2 * i] = digits[byte >> 4];
        (*out)[2 * i + 1] = digits[byte & 0xf];
    }
    (*out)[2 * count] = '\0';
    return count == key.size();
}

struct OhosImageLeaseRow {
    const OhosImageEntry *entry = nullptr;
    size_t oldCount = 0;
    size_t newCount = 0;
};

static void cjguiOhosLogAcceptedImageSwap(const Session &session,
    const std::vector<SceneNode> &previous, uint64_t previousProjection,
    uint64_t ticket, const char *cause)
{
    // At most the old and new domain's admitted 64 identities can be present.
    // If an unusual retired-domain overlap exceeds this bound, the summary
    // exposes omitted node rows rather than silently claiming exact coverage.
    std::array<OhosImageLeaseRow, 2 * kImageMaxRecords> rows{};
    size_t used = 0;
    size_t omitted = 0;
    auto count = [&](const std::vector<SceneNode> &nodes, bool old) {
        for (const SceneNode &node : nodes) {
            const OhosImageEntry *entry = node.image.get();
            if (!entry) continue;
            size_t index = 0;
            while (index < used && rows[index].entry != entry) ++index;
            if (index == used) {
                if (used == rows.size()) { ++omitted; continue; }
                rows[used++].entry = entry;
            }
            if (old) ++rows[index].oldCount; else ++rows[index].newCount;
        }
    };
    count(previous, true);
    count(session.accepted, false);
    const uint64_t seq = g_imageLeaseSwapSeq.fetch_add(1, std::memory_order_relaxed) + 1;
    RLOGI("image-lease stage=accepted-swap seq=%{public}llu session=%{public}llu ticket=%{public}llu cause=%{public}s oldProjection=%{public}llu newProjection=%{public}llu rows=%{public}zu omitted=%{public}zu wrapped=%{public}d",
          static_cast<unsigned long long>(seq),
          static_cast<unsigned long long>(session.token),
          static_cast<unsigned long long>(ticket), cause,
          static_cast<unsigned long long>(previousProjection),
          static_cast<unsigned long long>(session.acceptedProjectionVersion), used, omitted,
          seq == 0 ? 1 : 0);
    for (size_t i = 0; i < used; ++i) {
        const OhosImageEntry &entry = *rows[i].entry;
        std::array<char, kImageLeaseKeyHexCapacity> keyHex{};
        const bool keyComplete = cjguiOhosImageKeyHex(entry.key, &keyHex);
        RLOGI("image-lease stage=accepted-entry seq=%{public}llu epoch=%{public}llu entry=%{public}llu keyHex=%{public}s version=%{public}llu oldCount=%{public}zu newCount=%{public}zu session=%{public}llu ticket=%{public}llu oldProjection=%{public}llu newProjection=%{public}llu keyBytes=%{public}zu keyTruncated=%{public}d",
              static_cast<unsigned long long>(seq),
              static_cast<unsigned long long>(entry.epoch),
              static_cast<unsigned long long>(entry.id), keyHex.data(),
              static_cast<unsigned long long>(entry.version),
              rows[i].oldCount, rows[i].newCount,
              static_cast<unsigned long long>(session.token),
              static_cast<unsigned long long>(ticket),
              static_cast<unsigned long long>(previousProjection),
              static_cast<unsigned long long>(session.acceptedProjectionVersion),
              entry.key.size(), keyComplete ? 0 : 1);
    }
}
// END CJGUI OHOS IMAGE LEASE DIAGNOSTICS

struct SessionTable {
    std::mutex lock;
    Session sessions[kMaxSessions];
    int occupied = 0;
};

SessionTable g_sessions;
// 同一进程的 host STOP/RESTART 会重用 Session 槽；context 不可随槽重置而
// 复用，否则旧 ArkTS end/submit 可以撞中新实例的相同数字。
std::atomic<int64_t> g_nextEditingContextId{1};

Session *lookupSessionLocked(uint64_t token)
{
    if (token == 0) return nullptr;
    for (size_t i = 0; i < kMaxSessions; ++i) {
        if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].token == token) {
            return &g_sessions.sessions[i];
        }
    }
    return nullptr;
}

static void cjguiOhosObserveSurfaceLocked(Session *s, uint64_t generation,
    uint64_t geometryRevision, int32_t width, int32_t height, double density)
{
    if (!std::isfinite(density) || density <= 0.0) density = 1.0;
    if (!s->surfaceSeen || s->surfaceGeneration != generation ||
        s->surfaceGeometryRevision != geometryRevision || s->surfaceWidth != width ||
        s->surfaceHeight != height || s->surfaceDensity != density) {
        // The host geometry revision is unique across same-generation resize
        // and Surface replacement. Keep a local monotonic fallback if density
        // changes without a new host revision.
        s->surfaceResizeVersion = std::max(s->surfaceResizeVersion + 1, geometryRevision);
    }
    s->surfaceGeneration = generation;
    s->surfaceGeometryRevision = geometryRevision;
    s->surfaceWidth = width;
    s->surfaceHeight = height;
    s->surfaceDensity = density;
    s->surfaceSeen = true;
}

static void cjguiOhosRefreshSurfaceLocked(Session *s)
{
    if (!g_ingress.surfaceActive) return;
    void *window = nullptr;
    uint64_t generation = 0, geometryRevision = 0;
    int32_t width = 0, height = 0;
    double density = 1.0;
    if (g_ingress.surfaceActive(&window, &generation, &width, &height,
                                &density, &geometryRevision) == 1) {
        cjguiOhosObserveSurfaceLocked(s, generation, geometryRevision, width, height, density);
    }
}

// 会话槽位（结算记录 g_pending 与 session 同索引）。
int sessionSlotLocked(uint64_t token)
{
    if (token == 0) return -1;
    for (size_t i = 0; i < kMaxSessions; ++i) {
        if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].token == token) {
            return static_cast<int>(i);
        }
    }
    return -1;
}

static bool cjguiOhosImagePathAllowed(const char *path)
{
    // startHost publishes the OS-provided filesDir before starting the owner.
    // On some devices it is .../haps/entry/files rather than the short alias
    // .../base/files. Match that one bound directory exactly; never accept an
    // arbitrary caller-supplied path or an old app instance's directory.
    constexpr char sandboxPrefix[] = "/data/storage/el2/base/";
    constexpr char filesSuffix[] = "/files";
    const char *root = std::getenv("CJGUI_IMAGE_FIXTURE_DIR");
    if (!root || !path) return false;
    const size_t rootLength = std::strlen(root);
    const size_t length = std::strlen(path);
    if (rootLength < 28 || rootLength > 255 || length <= rootLength + 1 || length > 512 ||
        std::strncmp(root, sandboxPrefix, sizeof(sandboxPrefix) - 1) != 0 ||
        std::strcmp(root + rootLength - (sizeof(filesSuffix) - 1), filesSuffix) != 0 ||
        std::strncmp(path, root, rootLength) != 0 || path[rootLength] != '/') return false;
    for (const char *p = root; *p; ++p) {
        if ((*p == '.' && p[1] == '.') || (*p == '/' && p[1] == '/') ||
            !( (*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') ||
               (*p >= '0' && *p <= '9') || *p == '/' || *p == '_' || *p == '-' || *p == '.')) {
            return false;
        }
    }
    const char *name = path + rootLength + 1;
    const size_t nameLength = length - rootLength - 1;
    if (nameLength < 5 || nameLength > 255 || name[0] == '.' ||
        std::strcmp(name + nameLength - 4, ".png") != 0) return false;
    for (const char *p = name; *p; ++p) {
        if ((*p == '.' && p[1] == '.') ||
            !( (*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') ||
               (*p >= '0' && *p <= '9') || *p == '_' || *p == '-' || *p == '.')) {
            return false;
        }
    }
    return true;
}

static uint32_t cjguiOhosPngWord(const uint8_t *bytes)
{
    return (static_cast<uint32_t>(bytes[0]) << 24) | (static_cast<uint32_t>(bytes[1]) << 16) |
           (static_cast<uint32_t>(bytes[2]) << 8) | bytes[3];
}

static bool cjguiOhosUnknownAlphaNeedsPremultiply(const uint8_t *pixels, uint32_t width,
    uint32_t height, uint32_t stride, uint32_t *witnessX, uint32_t *witnessY)
{
    for (uint32_t y = 0; y < height; ++y) {
        const uint8_t *row = pixels + static_cast<size_t>(y) * stride;
        for (uint32_t x = 0; x < width; ++x) {
            const uint8_t *p = row + x * 4u;
            if (p[0] > p[3] || p[1] > p[3] || p[2] > p[3]) {
                if (witnessX) *witnessX = x;
                if (witnessY) *witnessY = y;
                return true;
            }
        }
    }
    return false;
}

static void cjguiOhosPremultiplyBgra(uint8_t *pixels, uint32_t width,
    uint32_t height, uint32_t stride)
{
    for (uint32_t y = 0; y < height; ++y) {
        uint8_t *row = pixels + static_cast<size_t>(y) * stride;
        for (uint32_t x = 0; x < width; ++x) {
            uint8_t *p = row + x * 4u;
            for (int c = 0; c < 3; ++c) {
                p[c] = static_cast<uint8_t>((p[c] * p[3] + 127) / 255);
            }
        }
    }
}

struct OhosDecodeResult {
    std::shared_ptr<OhosDecodedImage> image;
    std::string failure;
    uint64_t readBytes = 0;
    uint64_t readMicros = 0;
    uint64_t decodeMicros = 0;
};

static OhosDecodeResult cjguiOhosDecodePng(const std::string &path)
{
    // One runtime check per process: the NDK libraries are link-only inputs,
    // so this records the libraries that actually provide the image symbols on
    // device without packaging SDK stubs into the HAP.
    static std::atomic<bool> providerReported{false};
    bool expected = false;
    if (providerReported.compare_exchange_strong(expected, true)) {
        Dl_info sourceInfo{};
        Dl_info bitmapInfo{};
        const bool sourceResolved =
            dladdr(reinterpret_cast<void *>(&OH_ImageSourceNative_CreateFromData), &sourceInfo) &&
            sourceInfo.dli_fname != nullptr;
        const bool bitmapResolved =
            dladdr(reinterpret_cast<void *>(&OH_Drawing_BitmapCreateFromPixels), &bitmapInfo) &&
            bitmapInfo.dli_fname != nullptr;
        RLOGI("image-provider imageSource=%{public}s drawingBitmap=%{public}s",
              sourceResolved ? sourceInfo.dli_fname : "unresolved",
              bitmapResolved ? bitmapInfo.dli_fname : "unresolved");
    }
    OhosDecodeResult result;
    struct ResetActiveBytes { ~ResetActiveBytes() { cjguiOhosRecordDecoderBytes(0); } } resetBytes;
    const auto readStart = std::chrono::steady_clock::now();
    int fd = open(path.c_str(), O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) { result.failure = "open"; return result; }
    struct stat fileInfo{};
    if (fstat(fd, &fileInfo) != 0 || !S_ISREG(fileInfo.st_mode) || fileInfo.st_size < 24 ||
        static_cast<uint64_t>(fileInfo.st_size) > kImageMaxEncoded) {
        close(fd); result.failure = "encoded-limit"; return result;
    }
    std::vector<uint8_t> encoded(static_cast<size_t>(fileInfo.st_size));
    cjguiOhosRecordDecoderBytes(encoded.size());
    size_t offset = 0;
    while (offset < encoded.size()) {
        ssize_t count = read(fd, encoded.data() + offset, encoded.size() - offset);
        if (count <= 0) { close(fd); result.failure = "read"; return result; }
        offset += static_cast<size_t>(count);
    }
    close(fd);
    result.readBytes = encoded.size();
    result.readMicros = static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now() - readStart).count());
    static constexpr uint8_t signature[] = {137, 80, 78, 71, 13, 10, 26, 10};
    if (std::memcmp(encoded.data(), signature, sizeof(signature)) != 0 ||
        cjguiOhosPngWord(encoded.data() + 8) != 13 ||
        std::memcmp(encoded.data() + 12, "IHDR", 4) != 0) {
        result.failure = "png-header"; return result;
    }
    uint32_t headerW = cjguiOhosPngWord(encoded.data() + 16);
    uint32_t headerH = cjguiOhosPngWord(encoded.data() + 20);
    if (!headerW || !headerH || headerW > 4096 || headerH > 4096 ||
        static_cast<uint64_t>(headerW) * headerH > kImageMaxPixels) {
        result.failure = "dimension-limit"; return result;
    }
    const auto decodeStart = std::chrono::steady_clock::now();
    OH_ImageSourceNative *source = nullptr;
    OH_ImageSource_Info *sourceInfo = nullptr;
    OH_DecodingOptions *options = nullptr;
    OH_PixelmapNative *pixelmap = nullptr;
    OH_Pixelmap_ImageInfo *pixelInfo = nullptr;
    struct SdkHandles {
        OH_ImageSourceNative *&source;
        OH_ImageSource_Info *&sourceInfo;
        OH_DecodingOptions *&options;
        OH_PixelmapNative *&pixelmap;
        OH_Pixelmap_ImageInfo *&pixelInfo;
        void release() {
            if (pixelInfo) { OH_PixelmapImageInfo_Release(pixelInfo); pixelInfo = nullptr; }
            if (pixelmap) { OH_PixelmapNative_Release(pixelmap); pixelmap = nullptr; }
            if (options) { OH_DecodingOptions_Release(options); options = nullptr; }
            if (sourceInfo) { OH_ImageSourceInfo_Release(sourceInfo); sourceInfo = nullptr; }
            if (source) { OH_ImageSourceNative_Release(source); source = nullptr; }
        }
        ~SdkHandles() { release(); }
    } sdk{source, sourceInfo, options, pixelmap, pixelInfo};
    auto imageApiOk = [&](const char *stage, Image_ErrorCode code) {
        if (code == IMAGE_SUCCESS) return true;
        result.failure = stage;
        RLOGE("image-decode-failure stage=%{public}s rc=%{public}d", stage, static_cast<int>(code));
        return false;
    };
    do {
        if (!imageApiOk("source-create", OH_ImageSourceNative_CreateFromData(
                encoded.data(), encoded.size(), &source))) break;
        if (!source) { result.failure = "source-null"; break; }
        if (!imageApiOk("source-info-create", OH_ImageSourceInfo_Create(&sourceInfo))) break;
        if (!sourceInfo) { result.failure = "source-info-null"; break; }
        if (!imageApiOk("source-info-read", OH_ImageSourceNative_GetImageInfo(
                source, 0, sourceInfo))) break;
        uint32_t sourceW = 0, sourceH = 0;
        if (!imageApiOk("source-width", OH_ImageSourceInfo_GetWidth(sourceInfo, &sourceW)) ||
            !imageApiOk("source-height", OH_ImageSourceInfo_GetHeight(sourceInfo, &sourceH))) break;
        if (sourceW != headerW || sourceH != headerH) {
            result.failure = "source-dimension";
            RLOGE("image-decode-failure stage=source-dimension header=%{public}ux%{public}u sdk=%{public}ux%{public}u",
                  headerW, headerH, sourceW, sourceH);
            break;
        }
        if (!imageApiOk("options-create", OH_DecodingOptions_Create(&options))) break;
        if (!options) { result.failure = "options-null"; break; }
        if (!imageApiOk("options-format", OH_DecodingOptions_SetPixelFormat(
                options, PIXEL_FORMAT_BGRA_8888))) break;
        if (!imageApiOk("options-range", OH_DecodingOptions_SetDesiredDynamicRange(
                options, IMAGE_DYNAMIC_RANGE_SDR))) break;
        if (!imageApiOk("pixelmap-create", OH_ImageSourceNative_CreatePixelmap(
                source, options, &pixelmap))) break;
        if (!pixelmap) { result.failure = "pixelmap-null"; break; }
        if (!imageApiOk("pixelmap-info-create", OH_PixelmapImageInfo_Create(&pixelInfo))) break;
        if (!pixelInfo) { result.failure = "pixelmap-info-null"; break; }
        if (!imageApiOk("pixelmap-info-read", OH_PixelmapNative_GetImageInfo(
                pixelmap, pixelInfo))) break;
        uint32_t width = 0, height = 0, stride = 0;
        int32_t format = 0, alpha = 0;
        if (!imageApiOk("pixelmap-width", OH_PixelmapImageInfo_GetWidth(pixelInfo, &width)) ||
            !imageApiOk("pixelmap-height", OH_PixelmapImageInfo_GetHeight(pixelInfo, &height)) ||
            !imageApiOk("pixelmap-stride", OH_PixelmapImageInfo_GetRowStride(pixelInfo, &stride)) ||
            !imageApiOk("pixelmap-format-read", OH_PixelmapImageInfo_GetPixelFormat(pixelInfo, &format)) ||
            !imageApiOk("pixelmap-alpha-read", OH_PixelmapImageInfo_GetAlphaType(pixelInfo, &alpha))) break;
        if (width != headerW || height != headerH || stride < width * 4u ||
            static_cast<uint64_t>(stride) * height > kImageMaxDecoded ||
            format != PIXEL_FORMAT_BGRA_8888) {
            result.failure = "pixelmap-format";
            RLOGE("image-decode-failure stage=pixelmap-format header=%{public}ux%{public}u sdk=%{public}ux%{public}u stride=%{public}u format=%{public}d alpha=%{public}d",
                  headerW, headerH, width, height, stride, format, alpha);
            break;
        }
        std::shared_ptr<OhosDecodedImage> decoded = std::make_shared<OhosDecodedImage>();
        decoded->width = width;
        decoded->height = height;
        decoded->stride = stride;
        if (alpha != PIXELMAP_ALPHA_TYPE_UNKNOWN && alpha != PIXELMAP_ALPHA_TYPE_OPAQUE &&
            alpha != PIXELMAP_ALPHA_TYPE_PREMULTIPLIED &&
            alpha != PIXELMAP_ALPHA_TYPE_UNPREMULTIPLIED) {
            result.failure = "alpha-format";
            RLOGE("image-decode-failure stage=alpha-format alpha=%{public}d", alpha);
            break;
        }
        decoded->pixels.resize(static_cast<size_t>(stride) * height);
        cjguiOhosRecordDecoderBytes(encoded.size() + decoded->pixels.size());
        size_t bytes = decoded->pixels.size();
        if (!imageApiOk("pixel-read", OH_PixelmapNative_ReadPixels(
                pixelmap, decoded->pixels.data(), &bytes))) break;
        if (bytes > decoded->pixels.size() || bytes < static_cast<size_t>(stride) * height) {
            result.failure = "pixel-read-size";
            RLOGE("image-decode-failure stage=pixel-read-size bytes=%{public}zu allocated=%{public}zu stride=%{public}u height=%{public}u",
                  bytes, decoded->pixels.size(), stride, height);
            break;
        }
        if (alpha == PIXELMAP_ALPHA_TYPE_UNKNOWN) {
            // UNKNOWN is a documented PixelMap alpha value, but it does not
            // promise a byte representation. A color channel above alpha is
            // impossible in premultiplied data and proves straight alpha.
            // Otherwise we follow this SDK path's measured behavior: the H
            // normal HAP read BGRA=(81,62,8,120) from a PNG source pixel
            // RGBA=(17,132,173,120). This does not prove the representation
            // of every other PNG; keep the inference visible in hilog.
            bool sampled = false;
            for (uint32_t y = 0; y < height && !sampled; ++y) {
                const uint8_t *row = decoded->pixels.data() + static_cast<size_t>(y) * stride;
                for (uint32_t x = 0; x < width; ++x) {
                    const uint8_t *p = row + x * 4u;
                    if (p[3] == 0 || p[3] == 255) continue;
                    RLOGI("image-alpha-sample x=%{public}u y=%{public}u b=%{public}u g=%{public}u r=%{public}u a=%{public}u",
                          x, y, p[0], p[1], p[2], p[3]);
                    sampled = true;
                    break;
                }
            }
            uint32_t witnessX = 0, witnessY = 0;
            const bool straight = cjguiOhosUnknownAlphaNeedsPremultiply(decoded->pixels.data(),
                width, height, stride, &witnessX, &witnessY);
            RLOGI("image-alpha-inference mode=%{public}s witnessX=%{public}u witnessY=%{public}u translucentSample=%{public}d",
                  straight ? "proven-unpremul" : "sdk-observed-premul", witnessX, witnessY,
                  sampled ? 1 : 0);
            if (straight) cjguiOhosPremultiplyBgra(decoded->pixels.data(), width, height, stride);
        }
        if (alpha == PIXELMAP_ALPHA_TYPE_OPAQUE) decoded->alphaFormat = ALPHA_FORMAT_OPAQUE;
        if (alpha == PIXELMAP_ALPHA_TYPE_UNPREMULTIPLIED) {
            cjguiOhosPremultiplyBgra(decoded->pixels.data(), width, height, stride);
        }
        decoded->accountedBytes = decoded->pixels.size();
        g_imageLiveBytes.fetch_add(decoded->accountedBytes);
        result.image = std::move(decoded);
    } while (false);
    sdk.release();
    result.decodeMicros = static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now() - decodeStart).count());
    return result;
}

OhosImageDomain::~OhosImageDomain()
{
    {
        std::lock_guard<std::mutex> g(lock);
        quitting = true;
    }
    cv.notify_all();
    if (decoder.joinable()) decoder.join();
}

bool OhosImageDomain::validLocked(const OhosImageRef &entry) const
{
    auto it = entries.find({entry->key, entry->version});
    return entry->epoch == epoch && it != entries.end() && it->second == entry;
}

void OhosImageDomain::releaseReservationLocked(const OhosImageRef &entry)
{
    if (entry->reservation == 0) return;
    reservedBytes -= entry->reservation;
    entry->reservation = 0;
    outstanding -= 1;
}

void OhosImageDomain::trimIdleLocked(std::vector<OhosImageRef> *retired, bool reserveAdmissionSlot)
{
    size_t idleBytes = 0;
    for (const auto &pair : entries) {
        if (pair.second.use_count() == 1 && pair.second->decoded) {
            idleBytes += pair.second->decoded->pixels.size();
        }
    }
    // Admission reserves one slot; release maintenance only enforces the idle
    // budget. An accepted scene may legitimately keep all 64 slots active.
    while ((reserveAdmissionSlot && entries.size() >= kImageMaxRecords) ||
           idleBytes > kImageIdleBytes) {
        auto victim = entries.end();
        for (auto it = entries.begin(); it != entries.end(); ++it) {
            if (it->second.use_count() != 1 || it->second->reservation != 0) continue;
            if (victim == entries.end() || it->second->lastUse < victim->second->lastUse) victim = it;
        }
        if (victim == entries.end()) break;
        if (victim->second->decoded) idleBytes -= victim->second->decoded->pixels.size();
        retired->push_back(std::move(victim->second));
        // The immutable path binding lives exactly as long as this entry's
        // ownership. use_count()==1 proves no candidate, accepted scene,
        // queued job, decoder, or drawing snapshot can still refer to it.
        bindings.erase(victim->first);
        entries.erase(victim);
    }
}

bool OhosImageDomain::pruneReleasedIdle()
{
    std::vector<OhosImageRef> retired;
    {
        std::lock_guard<std::mutex> g(lock);
        trimIdleLocked(&retired, false);
    }
    // Release decoded bytes after unlocking the domain; the renderer's weak
    // bitmap entry is pruned separately on its owning thread.
    return !retired.empty();
}

CjguiInternalRendererStatus OhosImageDomain::access(const char *path, const char *key,
    uint64_t version, bool request, bool explicitRetry, OhosImageRef *outEntry, uint32_t *outState)
{
    if (outEntry) outEntry->reset();
    if (outState) *outState = 0;
    if (!key || !key[0] || std::strlen(key) > 160 || !cjguiOhosImagePathAllowed(path)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    const std::pair<std::string, uint64_t> identity{key, version};
    OhosImageRetirementWake retirement;
    OhosImageRef entry;
    bool notify = false;
    {
        std::lock_guard<std::mutex> g(lock);
        auto binding = bindings.find(identity);
        if (binding != bindings.end() && binding->second != path) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        auto found = entries.find(identity);
        if (found == entries.end() && request) {
            trimIdleLocked(&retirement.retired, true);
            // trimIdleLocked can erase a binding; do not use a pre-trim map
            // iterator for the capacity check or registration below.
            binding = bindings.find(identity);
            if (entries.size() >= kImageMaxRecords ||
                (binding == bindings.end() && bindings.size() >= kImageMaxBindings)) {
                if (outState) *outState = 4;
                return CJGUI_INTERNAL_RENDERER_OK;
            }
            if (binding == bindings.end()) bindings.emplace(identity, path);
            entry = std::make_shared<OhosImageEntry>(nextEntryId++, epoch, identity.first, version, path);
            entries.emplace(identity, entry);
        } else if (found != entries.end()) {
            entry = found->second;
        }
        if (entry) {
            if (request) {
                entry->lastUse = ++accessClock;
                if (entry->state == 2) cacheHits += 1;
            }
            if (request && (entry->state == 0 || (explicitRetry && (entry->state == 3 || entry->state == 4)))) {
                constexpr size_t reservation = kImageMaxEncoded + 2 * kImageMaxDecoded;
                if (outstanding >= kImageMaxOutstanding ||
                    reservedBytes + g_imageLiveBytes.load() + reservation > kImageProcessBytes) {
                    entry->state = 4;
                } else {
                    pending.push_back(entry);  // may allocate; all accounting still unchanged
                    entry->attempt += 1;
                    entry->state = 1;
                    entry->failure.clear();
                    entry->reservation = reservation;
                    reservedBytes += reservation;
                    peakTrackedBytes = std::max(peakTrackedBytes,
                        reservedBytes + g_imageLiveBytes.load());
                    outstanding += 1;
                    queued += 1;
                    if (!decoderStarted) {
                        try {
                            decoder = std::thread([this]() { decoderLoop(); });
                            decoderStarted = true;
                        } catch (...) {
                            pending.pop_back();
                            queued -= 1;
                            releaseReservationLocked(entry);
                            entry->state = 3;
                            entry->failure = "decoder-start";
                            entry->completionSerial += 1;
                        }
                    }
                    notify = entry->state == 1;
                }
            }
            if (outEntry) *outEntry = entry;
            if (outState) *outState = entry->state;
        }
    }
    if (notify) cv.notify_one();
    return CJGUI_INTERNAL_RENDERER_OK;
}

static CjguiInternalRendererStatus cjguiOhosImageAccessNoThrow(const char *path,
    const char *key, uint64_t version, bool request, bool explicitRetry,
    OhosImageRef *outEntry, uint32_t *outState) noexcept
{
    try {
        CjguiInternalRendererStatus status =
            g_images.access(path, key, version, request, explicitRetry, outEntry, outState);
        cjguiOhosPruneReleasedImages();  // access() has released its local entry
        return status;
    } catch (...) {
        RLOGE("image resource admission allocation failed");
        if (outEntry) outEntry->reset();
        if (outState) *outState = 3;
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
}

void OhosImageDomain::invalidate()
{
    std::map<std::pair<std::string, uint64_t>, OhosImageRef> retired;
    std::map<std::pair<std::string, uint64_t>, std::string> retiredBindings;
    {
        std::lock_guard<std::mutex> g(lock);
        epoch += 1;
        retiredBindings.swap(bindings);
#ifdef CJGUI_OHOS_TEST_GATES
        heldVersion = 0;
        holdEnabled = false;
#endif
        for (OhosImageRef &entry : pending) {
            releaseReservationLocked(entry);
            queued -= 1;
        }
        pending.clear();
        for (auto &pair : entries) {
            if (!pair.second->decoding) releaseReservationLocked(pair.second);
        }
        retired.swap(entries);
    }
}

void OhosImageDomain::decoderLoop()
{
    for (;;) {
        OhosImageRef entry;
        uint64_t attempt = 0;
        {
            std::unique_lock<std::mutex> g(lock);
            cv.wait(g, [this]() { return quitting || !pending.empty(); });
            if (quitting) return;
            entry = std::move(pending.front());
            pending.pop_front();
            queued -= 1;
            inFlight += 1;
            entry->decoding = true;
            attempt = entry->attempt;
            decodeStarts += 1;
        }
        OhosDecodeResult result;
        try {
            result = cjguiOhosDecodePng(entry->path);
        } catch (...) {
            // A bounded request can still fail allocation. It is a terminal
            // resource failure, not an exception crossing the worker entry.
            result.failure = "decode-allocation";
            cjguiOhosRecordDecoderBytes(0);
        }
        const size_t ownedBytes = result.image ? result.image->pixels.size() : 0;
        const bool decoded = result.image != nullptr;
        const std::string failure = result.failure;
        bool publishFailure = false, postRealization = false;
        {
            std::lock_guard<std::mutex> g(lock);
            inFlight -= 1;
            entry->decoding = false;
            encodedReadBytes += result.readBytes;
            encodedReadMicros += result.readMicros;
            decodeMicros += result.decodeMicros;
            if (!validLocked(entry) || entry->attempt != attempt || entry->state != 1) {
                staleDiscards += 1;
                releaseReservationLocked(entry);
            } else if (!result.image) {
                entry->failure = std::move(result.failure);
                entry->state = 3;
                entry->completionSerial += 1;
                releaseReservationLocked(entry);
                publishFailure = true;
            } else {
                entry->awaiting = std::move(result.image);
                bool shouldPost = true;
#ifdef CJGUI_OHOS_TEST_GATES
                entry->completionHeld = holdEnabled && heldVersion == entry->version;
                shouldPost = !entry->completionHeld;
#endif
                if (shouldPost) {
                    entry->realizationPosted = true;
                    postRealization = true;
                }
            }
        }
        RLOGI("image-cost stage=decode entry=%{public}llu version=%{public}llu encoded=%{public}llu readUs=%{public}llu decodeUs=%{public}llu owned=%{public}zu ok=%{public}d failure=%{public}s resident=%{public}zu",
              static_cast<unsigned long long>(entry->id),
              static_cast<unsigned long long>(entry->version),
              static_cast<unsigned long long>(result.readBytes),
              static_cast<unsigned long long>(result.readMicros),
              static_cast<unsigned long long>(result.decodeMicros),
              ownedBytes, decoded ? 1 : 0, decoded ? "none" : failure.c_str(),
              g_imageLiveBytes.load());
        if (postRealization) cjguiOhosPostImageRealization(entry);
        if (publishFailure) cjguiOhosNotifyImageCompletion(entry);
        result.image.reset();
        entry.reset();
        cjguiOhosPruneReleasedImages();
    }
}

// 场景逐项相等：用于确认「结算已提交的帧就是本轮候选」而不二次绘制。
bool sameSceneNodes(const std::vector<SceneNode> &a, const std::vector<SceneNode> &b)
{
    if (a.size() != b.size()) return false;
    for (size_t i = 0; i < a.size(); ++i) {
        if (a[i].pod.nodeId != b[i].pod.nodeId) return false;
        if (a[i].pod.resourceId != b[i].pod.resourceId) return false;
        if (a[i].pod.projectionVersion != b[i].pod.projectionVersion) return false;
        if (a[i].image != b[i].image) return false;
    }
    return true;
}

// 前置声明：IME 段定义（编辑组合缓冲）；渲染线程绘制编辑视图时使用。
std::u16string composedBuffer(const Session &s);

// ---------------------------------------------------------------------------
// 渲染线程：单一固定线程拥有全部 OH_Drawing 状态
// ---------------------------------------------------------------------------

enum class JobKind {
    Measure,
    CaretHitTest,
    Present,
    Redraw,      // 用末帧节点副本重绘（预览态视觉更新），不晋升任何状态
    ImageRealize, // plain pixels → renderer-owned Drawing bitmap; no Surface lease
    Teardown,    // A2：宿主请求拆除某一代 surface（含许可归还与拆除确认回传）
    Shutdown,
};

// 票据阶段（Sol 提交边界设计）：queued/running 可取消；committing 不可取消。
enum class JobPhase {
    Queued,
    Running,
    Committing,   // SurfaceFlush 调用中：结果未定期
    Done,
    Cancelled,
};

struct WaitableJob {
    JobKind kind;
    explicit WaitableJob(JobKind k) : kind(k) {}
    virtual ~WaitableJob() = default;
    std::mutex mutex;
    std::condition_variable cv;
    JobPhase phase = JobPhase::Queued;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;

    void finish(CjguiInternalRendererStatus result)
    {
        {
            std::lock_guard<std::mutex> g(mutex);
            if (phase != JobPhase::Cancelled && phase != JobPhase::Done) {
                phase = JobPhase::Done;
                status = result;
            }
        }
        cv.notify_all();
    }

    bool cancelBeforeCommit()
    {
        bool cancelled = false;
        {
            std::lock_guard<std::mutex> g(mutex);
            if (phase == JobPhase::Queued || phase == JobPhase::Running) {
                phase = JobPhase::Cancelled;
                status = CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
                cancelled = true;
            }
        }
        if (cancelled) cv.notify_all();
        return cancelled;
    }

    // 阶段快照（跨线程只读观察；不改变阶段）。
    JobPhase phaseSnapshot()
    {
        std::lock_guard<std::mutex> g(mutex);
        return phase;
    }
    CjguiInternalRendererStatus statusSnapshot()
    {
        std::lock_guard<std::mutex> g(mutex);
        return status;
    }

    // 渲染线程进入执行前调用：仅 queued/running → running。
    void markRunning()
    {
        std::lock_guard<std::mutex> g(mutex);
        if (phase == JobPhase::Queued || phase == JobPhase::Running) {
            phase = JobPhase::Running;
        }
    }

    // 等待结果（Sol 裁决语义）：
    //  - 终态 → 返回该状态；
    //  - queued/running 超时 → 确认取消（phase=Cancelled），返回
    //    DRAWABLE_UNAVAILABLE（确定不会 Flush）；对象不在此释放。
    //  - committing 超时 → PENDING(20)：结果未定，不声称拒绝也不声称提交；
    //    调用方保留票据并走结算查询。
    CjguiInternalRendererStatus waitFor()
    {
        std::unique_lock<std::mutex> g(mutex);
        bool completed = cv.wait_for(g, kRenderWaitTimeout, [this]() {
            return phase == JobPhase::Done || phase == JobPhase::Cancelled;
        });
        if (completed) {
            return status;
        }
        if (phase == JobPhase::Queued || phase == JobPhase::Running) {
            phase = JobPhase::Cancelled;
            status = CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
            cv.notify_all();
            return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
        }
        // committing：平台提交已不可撤销
        return static_cast<CjguiInternalRendererStatus>(CJGUI_INTERNAL_RENDERER_PENDING);
    }

    // 渲染线程在取消检查点调用：返回 true=已被取消（不得继续用平台资源）。
    bool consumeCancelIfRequested()
    {
        std::lock_guard<std::mutex> g(mutex);
        if (phase == JobPhase::Cancelled) return true;
        return false;
    }

    // 提交许可（Sol：取消确认与进入 Committing 必须在同一临界区完成）。
    // 返回 true = 调用方取得唯一一次平台提交许可，phase 已是 Committing，
    // 之后 waitFor 不再改写阶段（超时返回 PENDING）。
    // 返回 false = 已被取消或已终态：不得 Flush。
    // 「准备可取消」与「平台提交不可取消」由此处分界；多加一次 if cancelled
    // 无法消除检查与 Flush 之间的竞态。
    bool acquireCommitPermission()
    {
        std::lock_guard<std::mutex> g(mutex);
        if (phase != JobPhase::Queued && phase != JobPhase::Running) return false;
        phase = JobPhase::Committing;
        return true;
    }
};

// 任务所有权（返工：消除超时后 UAF 与无界遗留）：
// 队列、渲染线程、等待者共用 std::shared_ptr<WaitableJob>。调用方超时只结束
// 等待，不释放工作线程仍访问的对象；渲染线程执行完释放自己那份引用，最后一个
// 引用消失时对象自然回收。终态与回收各有唯一责任方，队列/在途/终态都有界。
using JobRef = std::shared_ptr<WaitableJob>;

struct MeasureJob : WaitableJob {
    MeasureJob() : WaitableJob(JobKind::Measure) {}
    std::string text;
    double fontSize = 13.0;
    uint32_t fontWeight = 400;
    double constraintWidth = 0.0;
    bool unlimitedWidth = false;
    CjguiInternalRendererTextMeasurement measurement{};
};

struct CaretHitTestJob : WaitableJob {
    CaretHitTestJob() : WaitableJob(JobKind::CaretHitTest) {}
    std::u16string text;   // 组合缓冲（UTF-16）
    double fontSize = 13.0;
    uint32_t fontWeight = 400;
    double nodeWidth = 0.0;
    double tapX = 0.0;     // 节点内相对坐标
    uint32_t caretUtf16 = 0;
};

struct PresentJob : WaitableJob {
    PresentJob() : WaitableJob(JobKind::Present) {}
    uint64_t session = 0;
    uint64_t ticketId = 0;
    std::vector<SceneNode> nodes;
    uint64_t projectionVersion = 0;
    void *window = nullptr;
    uint64_t generation = 0;
    uint64_t geometryRevision = 0;
    int32_t width = 0;
    int32_t height = 0;
    double clearR = 0, clearG = 0, clearB = 0, clearA = 1;
    uint64_t frameIndexAfter = 0;
};

struct ShutdownJob : WaitableJob {
    ShutdownJob() : WaitableJob(JobKind::Shutdown) {}
};

// 末帧重绘任务：非等待式（fire-and-forget），渲染线程自持有副本。
struct RedrawJob : WaitableJob {
    RedrawJob() : WaitableJob(JobKind::Redraw) {}
};

struct ImageRealizeJob : WaitableJob {
    explicit ImageRealizeJob(OhosImageRef resource)
        : WaitableJob(JobKind::ImageRealize), entry(std::move(resource)) {}
    OhosImageRef entry;
};

// A2 拆除任务：宿主 surface 退役时投递。渲染线程据此结束该代的真实使用
// （SurfaceDestroy + GPU 资源释放 + 许可归还），然后回传拆除确认。
// 非等待式：宿主 UI 回调只投递即返回，不阻塞 UI 线程。
struct TeardownJob : WaitableJob {
    explicit TeardownJob(uint64_t gen) : WaitableJob(JobKind::Teardown), generation(gen) {}
    uint64_t generation = 0;
};

// 提交未定结算记录：PENDING 返回后由 native 持有原票据与候选身份，
// 由 owner 正常循环查询并做一次性 commit/rollback，使 accepted 与命中
// 不会与「可能已 Flush 的画面」分离。索引与 session 槽位一致。
//
// A1：记录在 ACK 之前一直保留（终态保持不变，重复查询返回同一结果）。
// 这是“查询原提交”与“提交新候选”拆成两个入口的前提。
struct PendingSettlement {
    JobRef job;
    std::vector<SceneNode> nodes;
    uint64_t projectionVersion = 0;
    bool valid = false;
    // 票据身份与终态。settled 后 decision/terminalStatus/frameIndex 不再改变。
    uint64_t ticketId = 0;
    uint32_t decision = 0;          // CjguiInternalRendererPresentDecision
    int32_t terminalStatus = 0;     // 原生终态（Accepted 时 0）
    uint64_t frameIndex = 0;        // Accepted 时推进后的帧号
    int32_t drawableWidth = 0;
    int32_t drawableHeight = 0;
    double density = 1.0;
    bool settled = false;
};
PendingSettlement g_pending[kMaxSessions];

// 结算查询结果（对 owner 暴露；不新增公共 ABI 符号，随 present 返回值复用）。
constexpr int32_t kSettlementNone = 0;
constexpr int32_t kSettlementCommitted = 1;
constexpr int32_t kSettlementAborted = 2;
constexpr int32_t kSettlementStillCommitting = 3;

struct RenderThread {
    std::thread thread;
    std::mutex lock;
    std::mutex shutdownJoinLock;
    std::condition_variable cv;
    std::deque<JobRef> jobs;
    JobRef activeJob;
    bool running = false;
    bool stopping = false;
    bool imagePruneRequested = false;  // coalesced, allocation-free cleanup wakeup
    std::atomic<int32_t> lastShutdownStatus{0};

    struct ImageBitmap {
        uint64_t id = 0;
        uint64_t epoch = 0;
        uint64_t version = 0;
        std::array<char, kImageLeaseKeyHexCapacity> keyHex{};
        bool published = false;
        OH_Drawing_Bitmap *bitmap = nullptr;
        std::shared_ptr<OhosDecodedImage> backing;
        std::weak_ptr<OhosImageEntry> entry;
    };
    std::map<uint64_t, ImageBitmap> imageBitmaps;
    std::atomic<uint64_t> bitmapCreates{0}, bitmapDestroys{0};
    std::atomic<uint64_t> bitmapCreateMicros{0}, bitmapDestroyMicros{0};

    OH_Drawing_GpuContext *gpuContext = nullptr;
    void *boundWindow = nullptr;
    uint64_t boundGeneration = 0;
    OH_Drawing_Surface *surface = nullptr;
    // 第九次复核 A1：句柄的 backend 与句柄同生共死；释放器由它决定。
    SurfaceBackend surfaceBackend = SurfaceBackend::None;
    int32_t surfaceW = 0;
    int32_t surfaceH = 0;

    // 末帧副本（渲染线程自有）：预览态重绘的数据来源
    std::vector<SceneNode> lastNodes;
    uint64_t lastProjectionVersion = 0;
    double lastClearR = 0, lastClearG = 0, lastClearB = 0, lastClearA = 1;
    bool hasLastFrame = false;
    uint64_t submittedFrames = 0;
    int64_t rejectedFlushes = 0;
    // 退役屏障：当前正处于「已取得提交许可、Flush 尚未完成」的代际。
    // **只作取证读数**：Sol 复核指出它只盖住闸门之后到 Flush 之前，redraw 的
    // Flush 不在其内，因此不能当作创建/绘制/teardown 的静默判据。
    std::atomic<uint64_t> busyGeneration{0};

    // --- A2：surface 使用许可（覆盖创建/绘制/Flush/缓存/redraw/teardown）---
    // 渲染线程在绑定某代 surface 时取得一份不可复制许可，直到该代真正拆除
    // 才归还。宿主侧据此知道「还有没有人在用这个 native window」。
    uint64_t permitGeneration = 0;
    uint64_t permitAppInstance = 0;
    uint64_t permitComponentInstance = 0;
    uint64_t permitGeometryRevision = 0;
    std::atomic<int64_t> permitsAcquired{0};   // 跨线程只读取证
    std::atomic<int64_t> permitsReleased{0};   // 跨线程只读取证

    // 第九次复核 A1：许可记账 backend 以**取得时**的准入模式为准（ARM/DISARM
    // 切换不改变既有许可的记账路径）。
    SurfaceBackend permitBackend = SurfaceBackend::None;
    bool acquireSurfacePermit(uint64_t generation)
    {
        if (generation == 0) return false;
        // 第九次复核 A3：替身与真实路径共用同一套本地记账许可
        //（宿主无 permit 入口时 renderer 记账；backend 随句柄记录）。
#ifdef CJGUI_OHOS_TEST_GATES
        permitBackend = g_stubArmed.load() ? SurfaceBackend::Stub : SurfaceBackend::Real;
#else
        permitBackend = SurfaceBackend::Real;
#endif
        if (!g_ingress.surfacePermitAcquire) {
            permitGeneration = generation;   // 无宿主（测试环境）：只做本地记账
            return true;
        }
        uint64_t app = 0, comp = 0, geo = 0;
        if (g_ingress.surfacePermitAcquire(generation, &app, &comp, &geo) != 1) {
            RLOGW("surface permit denied gen=%{public}llu", static_cast<unsigned long long>(generation));
            return false;
        }
        permitGeneration = generation;
        permitAppInstance = app;
        permitComponentInstance = comp;
        permitGeometryRevision = geo;
        permitsAcquired.fetch_add(1);
        RLOGI("surface permit acquired gen=%{public}llu app=%{public}llu comp=%{public}llu geo=%{public}llu",
              static_cast<unsigned long long>(generation), static_cast<unsigned long long>(app),
              static_cast<unsigned long long>(comp), static_cast<unsigned long long>(geo));
        return true;
    }

    // 归还许可。返回归还后该代仍持有的许可数（无宿主时返回 0 表示已归零）。
    int32_t releaseSurfacePermit()
    {
        int32_t remaining = 0;
#ifdef CJGUI_OHOS_TEST_GATES
        // 链2 替身许可归还：只清本地记账（与替身取得对称；按取得时 backend）。
        if (permitBackend == SurfaceBackend::Stub && permitGeneration != 0) {
            permitGeneration = 0;
            permitsReleased.fetch_add(1);
            return 0;
        }
#endif
        if (permitGeneration != 0) {
            if (g_ingress.surfacePermitRelease) {
                remaining = g_ingress.surfacePermitRelease(permitGeneration);
            }
            permitsReleased.fetch_add(1);
            RLOGI("surface permit released gen=%{public}llu remaining=%{public}d",
                  static_cast<unsigned long long>(permitGeneration), remaining);
        }
        permitGeneration = 0;
        permitAppInstance = 0;
        permitComponentInstance = 0;
        permitGeometryRevision = 0;
        permitBackend = SurfaceBackend::None;
        return remaining;
    }

    // 拆除确认回传：只有真正结束使用之后才通知宿主归还 native 引用。
    void notifyTornDown(uint64_t generation)
    {
        if (generation == 0) return;
        if (g_ingress.surfaceTornDown) {
            RLOGI("surface torn down notify gen=%{public}llu", static_cast<unsigned long long>(generation));
            g_ingress.surfaceTornDown(generation);
        }
    }

    bool leaseQuiesced(uint64_t generation)
    {
        return busyGeneration.load() != generation;
    }

    void ensureStarted()
    {
        std::lock_guard<std::mutex> g(lock);
        if (running || stopping) return;
        running = true;
        // 上一轮已退出的线程必须先 join，避免 std::thread 赋值时 terminate。
        if (thread.joinable()) thread.join();
        cjguiOhosTestGateBeginRendererEpoch();
        thread = std::thread([this]() { run(); });
    }

    void post(const JobRef &job)
    {
        ensureStarted();
        bool rejected = false;
        {
            std::lock_guard<std::mutex> g(lock);
            if (stopping) {
                // 停机中：拒收并立即以取消终态结算，调用方不会等待超时。
                rejected = true;
            } else {
                jobs.push_back(job);
            }
        }
        if (rejected) {
            job->cancelBeforeCommit();
            return;
        }
        cv.notify_all();
    }

    bool postIfRunning(const JobRef &job)
    {
        {
            std::lock_guard<std::mutex> g(lock);
            if (!running || stopping) return false;
            jobs.push_back(job);
        }
        cv.notify_all();
        return true;
    }

    void requestImagePrune()
    {
        {
            std::lock_guard<std::mutex> g(lock);
            if (!running || stopping) return;  // shutdown destroys every bitmap
            imagePruneRequested = true;
        }
        cv.notify_one();
    }

    void destroyImageBitmap(ImageBitmap &image)
    {
        if (!image.bitmap) return;
        const auto start = std::chrono::steady_clock::now();
        OH_Drawing_BitmapDestroy(image.bitmap);
        const uint64_t elapsed = static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now() - start).count());
        bitmapDestroyMicros.fetch_add(elapsed);
        bitmapDestroys.fetch_add(1);
        RLOGI("image-lease stage=bitmap-destroy epoch=%{public}llu entry=%{public}llu keyHex=%{public}s version=%{public}llu published=%{public}d",
              static_cast<unsigned long long>(image.epoch),
              static_cast<unsigned long long>(image.id), image.keyHex.data(),
              static_cast<unsigned long long>(image.version), image.published ? 1 : 0);
        RLOGI("image-cost stage=bitmap-destroy entry=%{public}llu version=%{public}llu us=%{public}llu resident=%{public}zu",
              static_cast<unsigned long long>(image.id),
              static_cast<unsigned long long>(image.version),
              static_cast<unsigned long long>(elapsed), g_imageLiveBytes.load());
        image.bitmap = nullptr;
        image.backing.reset();
    }

    void pruneImageBitmaps()
    {
        for (auto it = imageBitmaps.begin(); it != imageBitmaps.end();) {
            if (it->second.entry.expired()) {
                destroyImageBitmap(it->second);
                it = imageBitmaps.erase(it);
            } else ++it;
        }
    }

    void run()
    {
        std::unique_lock<std::mutex> g(lock);
        for (;;) {
            cv.wait(g, [this]() { return !jobs.empty() || imagePruneRequested; });
            if (jobs.empty()) {
                imagePruneRequested = false;
                g.unlock();
                pruneImageBitmaps();  // no Surface access, draw, or Flush
                g.lock();
                continue;
            }
            const bool pruneAfterJob = imagePruneRequested;
            imagePruneRequested = false;
            JobRef job = jobs.front();
            jobs.pop_front();
            activeJob = job;
            g.unlock();
            // 出队闸门只作用于真实 PresentJob；停机和 teardown 不能再次被
            // 测试闸门阻塞。票号由投递点绑定，便于核对同一票的阶段和终态。
            if (job->kind == JobKind::Present) {
                PresentJob *present = static_cast<PresentJob *>(job.get());
                cjguiOhosTestGateBeforeExecute(present->session, present->ticketId,
                                               present->generation);
            }
            if (job->kind == JobKind::Shutdown) {
                teardownSurface();
                busyGeneration.store(0);
                for (auto &pair : imageBitmaps) destroyImageBitmap(pair.second);
                imageBitmaps.clear();
                if (gpuContext) {
                    OH_Drawing_GpuContextDestroy(gpuContext);
                    gpuContext = nullptr;
                }
                // 在途任务全部以取消终态收敛（不遗留未结算票据）。
                g.lock();
                for (JobRef &pendingJob : jobs) {
                    pendingJob->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
                }
                jobs.clear();
                activeJob.reset();
                running = false;
                g.unlock();
                job->finish(CJGUI_INTERNAL_RENDERER_OK);
                g.lock();
                return;
            }
            execute(job.get());   // 共享所有权：本函数返回即释放本线程这一份引用
            g.lock();
            activeJob.reset();
            g.unlock();
            job.reset();
            // finish() can wake the owner before this thread releases its own
            // Present/ImageRealize reference. This is the renderer-side release
            // opportunity; the owner has its separate settlement hook.
            try {
                const bool evicted = g_images.pruneReleasedIdle();
                if (pruneAfterJob || evicted) pruneImageBitmaps();
            } catch (...) {
                RLOGE("image idle prune failed after renderer job");
            }
            g.lock();
        }
    }

    // 停机：投递唯一 ShutdownJob、等待渲染线程 teardown 并退出、join 线程、
    // 复位启动身份。非渲染线程调用；返回真实终态而不是 Bool。
    CjguiInternalRendererStatus shutdownAndJoin()
    {
        std::lock_guard<std::mutex> serial(shutdownJoinLock);
        JobRef job = std::make_shared<ShutdownJob>();
        std::vector<JobRef> cancelJobs;
        {
            std::lock_guard<std::mutex> g(lock);
            // 重复关闭只复用上一次真实结果，不为它启动一个新工作线程。
            if (!running && !thread.joinable()) {
                return static_cast<CjguiInternalRendererStatus>(lastShutdownStatus.load());
            }
            stopping = true;
            if (activeJob && activeJob->kind == JobKind::Present) cancelJobs.push_back(activeJob);
            for (const JobRef &pendingJob : jobs) {
                if (pendingJob->kind == JobKind::Present) cancelJobs.push_back(pendingJob);
            }
            // 不走 post：接单已经关闭，Shutdown 仍须作为本实例唯一终止任务入队。
            jobs.push_back(job);
        }
        // 票据临界区独立于队列锁：Committing 不可撤销；其余任务有确定取消终态。
        for (const JobRef &pendingJob : cancelJobs) pendingJob->cancelBeforeCommit();
        // 本 renderer 实例的测试等待由停止所有者直接唤醒；不依赖已关闭的 owner 控制通道。
        cjguiOhosTestGateCancelRendererEpoch();
        cv.notify_all();
        std::unique_lock<std::mutex> g(job->mutex);
        bool withinDeadline = job->cv.wait_for(g, std::chrono::seconds{5}, [&job]() {
            return job->phase == JobPhase::Done || job->phase == JobPhase::Cancelled;
        });
        g.unlock();
        if (thread.joinable()) thread.join();
        CjguiInternalRendererStatus result = job->phaseSnapshot() == JobPhase::Done
            ? job->statusSnapshot() : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        if (!withinDeadline) {
            RLOGW("renderer stop exceeded five-second settlement deadline; joined status=%{public}d",
                  static_cast<int>(result));
        }
        {
            std::lock_guard<std::mutex> gl(lock);
            jobs.clear();
            activeJob.reset();
            running = false;
            stopping = false;
            hasLastFrame = false;
            lastNodes.clear();
        }
        lastShutdownStatus.store(static_cast<int32_t>(result));
        return result;
    }

    // 租约有效性：以宿主当前 lease 为准（不是本线程自行绑定的编号）。
    // 渲染线程在绘制前、Flush 前、Flush 后各核对一次；退役后旧代任务
    // 既不再绘制也不再晋升 accepted。
    bool leaseValid(uint64_t generation)
    {
        if (generation == 0) return false;
        // 第九次复核 A3：替身会话复用宿主 SurfaceRecord——租约由宿主表
        // active 状态承载，本检查点直接走生产查询；退役仲裁点不变。
        if (!g_ingress.leaseValid) return true;   // 无租约观察（测试/无宿主）
        return g_ingress.leaseValid(generation) == 1;
    }

    // A geometry callback may reuse both the NativeWindow pointer and its
    // dimensions. Compare the host's atomic surface snapshot as well as the
    // generation; a stale frame must never become accepted for a new revision.
    bool geometryMatches(void *window, uint64_t generation, int w, int h,
                         uint64_t revision)
    {
        if (!g_ingress.surfaceActive) return true;
        void *liveWindow = nullptr;
        uint64_t liveGeneration = 0, liveRevision = 0;
        int32_t liveW = 0, liveH = 0;
        double liveDensity = 1.0;
        return g_ingress.surfaceActive(&liveWindow, &liveGeneration, &liveW,
                                       &liveH, &liveDensity, &liveRevision) == 1 &&
            liveWindow == window && liveGeneration == generation &&
            liveW == w && liveH == h && liveRevision == revision;
    }

    void execute(WaitableJob *job)
    {
        // 无 RTTI dynamic_cast：cangjie std-ast 与 libc++ 的 __dynamic_cast
        // 符号冲突曾导致段错误；用枚举标签分发。
        if (job->kind == JobKind::Measure) {
            executeMeasure(static_cast<MeasureJob *>(job));
        } else if (job->kind == JobKind::CaretHitTest) {
            executeCaretHitTest(static_cast<CaretHitTestJob *>(job));
        } else if (job->kind == JobKind::Present) {
            executePresent(static_cast<PresentJob *>(job));
        } else if (job->kind == JobKind::Redraw) {
            executeRedraw();
        } else if (job->kind == JobKind::ImageRealize) {
            executeImageRealize(static_cast<ImageRealizeJob *>(job));
        } else if (job->kind == JobKind::Teardown) {
            executeTeardown(static_cast<TeardownJob *>(job));
        }
    }

    void executeImageRealize(ImageRealizeJob *job)
    {
        OhosImageRef entry = job->entry;
        std::shared_ptr<OhosDecodedImage> pixels;
        uint64_t attempt = 0;
        {
            std::lock_guard<std::mutex> g(g_images.lock);
            if (!g_images.validLocked(entry) || entry->state != 1 || !entry->awaiting) {
                job->finish(CJGUI_INTERNAL_RENDERER_OK);
                return;
            }
#ifdef CJGUI_OHOS_TEST_GATES
            if (entry->completionHeld) {
                entry->realizationPosted = false;
                job->finish(CJGUI_INTERNAL_RENDERER_OK);
                return;
            }
#endif
            pixels = entry->awaiting;
            attempt = entry->attempt;
        }
        OH_Drawing_Image_Info imageInfo{static_cast<int32_t>(pixels->width),
            static_cast<int32_t>(pixels->height), pixels->colorFormat, pixels->alphaFormat};
        const auto start = std::chrono::steady_clock::now();
        OH_Drawing_Bitmap *bitmap = OH_Drawing_BitmapCreateFromPixels(&imageInfo,
            pixels->pixels.data(), pixels->stride);
        const bool bitmapCreated = bitmap != nullptr;
        const uint64_t createUs = static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now() - start).count());
        bitmapCreateMicros.fetch_add(createUs);
        if (bitmap) bitmapCreates.fetch_add(1);
        RLOGI("image-cost stage=bitmap-create entry=%{public}llu version=%{public}llu us=%{public}llu ok=%{public}d resident=%{public}zu",
              static_cast<unsigned long long>(entry->id),
              static_cast<unsigned long long>(entry->version),
              static_cast<unsigned long long>(createUs), bitmap ? 1 : 0,
              g_imageLiveBytes.load());
        bool publish = false;
        bool bitmapPublished = false;
        {
            std::lock_guard<std::mutex> g(g_images.lock);
            if (g_images.validLocked(entry) && entry->state == 1 &&
                entry->attempt == attempt && entry->awaiting == pixels) {
                if (bitmap) {
                    ImageBitmap image;
                    image.id = entry->id;
                    image.epoch = entry->epoch;
                    image.version = entry->version;
                    cjguiOhosImageKeyHex(entry->key, &image.keyHex);
                    image.published = true;
                    image.bitmap = bitmap;
                    image.backing = pixels;
                    image.entry = entry;
                    imageBitmaps.emplace(entry->id, std::move(image));
                    bitmapPublished = true;
                    entry->decoded = pixels;
                    entry->state = 2;
                } else {
                    entry->failure = "bitmap";
                    entry->state = 3;
                }
                entry->awaiting.reset();
                entry->completionSerial += 1;
                g_images.releaseReservationLocked(entry);
                publish = true;
                bitmap = nullptr;  // render-thread map now owns it
            } else {
                g_images.staleDiscards += 1;
            }
        }
        std::array<char, kImageLeaseKeyHexCapacity> keyHex{};
        const bool keyComplete = cjguiOhosImageKeyHex(entry->key, &keyHex);
        RLOGI("image-lease stage=bitmap-create epoch=%{public}llu entry=%{public}llu keyHex=%{public}s version=%{public}llu ok=%{public}d published=%{public}d keyBytes=%{public}zu keyTruncated=%{public}d",
              static_cast<unsigned long long>(entry->epoch),
              static_cast<unsigned long long>(entry->id), keyHex.data(),
              static_cast<unsigned long long>(entry->version),
              bitmapCreated ? 1 : 0, bitmapPublished ? 1 : 0,
              entry->key.size(), keyComplete ? 0 : 1);
        if (bitmap) {
            ImageBitmap unused;
            unused.id = entry->id;
            unused.epoch = entry->epoch;
            unused.version = entry->version;
            unused.keyHex = keyHex;
            unused.bitmap = bitmap;
            destroyImageBitmap(unused);
        }
        pruneImageBitmaps();
        if (publish) cjguiOhosNotifyImageCompletion(entry);
        job->finish(CJGUI_INTERNAL_RENDERER_OK);
    }

    // A2 拆除：宿主已退役该代 surface，渲染线程结束真实使用。
    void executeTeardown(TeardownJob *job)
    {
        if (boundGeneration == job->generation) {
            // 仍绑定该代：真正拆除（销毁 surface + 归还许可 + 回传拆除确认）。
            teardownSurface();
        } else {
            // 该代从未创建过 surface，或已被后续代替换：仍必须回传确认，
            // 否则宿主会无限期等一个不会到来的通知（引用永不归还）。
            notifyTornDown(job->generation);
        }
        job->finish(CJGUI_INTERNAL_RENDERER_OK);
    }

    // 预览态重绘：以末帧节点副本走同一绘制路径（编辑视图读取最新编辑缓冲）。
    // 不 Flush 前不查取消（无票据）；Flush 后不推进任何会话状态。
    void executeRedraw()
    {
        pruneImageBitmaps();
        if (!hasLastFrame || !surface) return;
        // 第七次复核 B：无引用档下退役代的重绘同样不得触碰平台资源
        // （SurfaceGetCanvas/SurfaceFlush 都作用在该代的 window 上）。
        if (!leaseValid(boundGeneration)) {
            RLOGW("redraw skipped on retired lease gen=%{public}llu",
                  static_cast<unsigned long long>(boundGeneration));
            return;
        }
        if (surfaceBackend == SurfaceBackend::Stub) {
            // 第九次复核 A1：替身句柄的重绘由替身分派（身份计数），绝不把
            // 替身假地址传入真实 GetCanvas/Flush——含 DISARM 后的旧句柄。
#ifdef CJGUI_OHOS_TEST_GATES
            g_stubCounts[ohosStubSlot(boundGeneration)].drawEnter.fetch_add(1);
            g_stubCounts[ohosStubSlot(boundGeneration)].flushEnter.fetch_add(1);
            g_stubCounts[ohosStubSlot(boundGeneration)].flushExit.fetch_add(1);
            reinterpret_cast<OhosStubSurface *>(surface)->flushed = true;
#endif
            return;
        }
        if (surfaceBackend == SurfaceBackend::None) {
            g_pcCalls.postBoundaryAttempts.fetch_add(1);
            return;
        }
        if (!geometryMatches(boundWindow, boundGeneration, surfaceW, surfaceH,
                             permitGeometryRevision)) {
            // The keyboard can resize a live XComponent before the next owner
            // scene is submitted. A preview redraw must rebind that same
            // generation to its latest geometry; otherwise every draft frame
            // is skipped until the eventual owner commit forces a PresentJob.
            void *liveWindow = nullptr;
            uint64_t liveGeneration = 0, liveRevision = 0;
            int32_t liveW = 0, liveH = 0;
            double liveDensity = 1.0;
            if (!g_ingress.surfaceActive ||
                g_ingress.surfaceActive(&liveWindow, &liveGeneration, &liveW,
                                        &liveH, &liveDensity, &liveRevision) != 1 ||
                liveWindow != boundWindow || liveGeneration != boundGeneration ||
                !leaseValid(liveGeneration) ||
                !ensureSurface(liveWindow, liveGeneration, liveW, liveH, liveRevision)) {
                RLOGW("redraw skipped after geometry change gen=%{public}llu",
                      static_cast<unsigned long long>(boundGeneration));
                return;
            }
        }
        OH_Drawing_Canvas *canvas = OH_Drawing_SurfaceGetCanvas(surface);
        if (!canvas) return;
        OH_Drawing_Brush *bg = OH_Drawing_BrushCreate();
        OH_Drawing_BrushSetAntiAlias(bg, true);
        OH_Drawing_BrushSetColor(bg, packColor(lastClearR, lastClearG, lastClearB, lastClearA));
        OH_Drawing_CanvasDrawBackground(canvas, bg);
        OH_Drawing_BrushDestroy(bg);
        for (const SceneNode &n : lastNodes) {
            if (n.pod.width <= 0 || n.pod.height <= 0) continue;
            OH_Drawing_CanvasSave(canvas);
            if (applyClipChain(canvas, n.pod)) {   // 空裁剪：不可见
                drawFill(canvas, n.pod);
                drawNodeImage(canvas, n);
                drawBorder(canvas, n.pod);
                drawNodeText(canvas, n);
            }
            OH_Drawing_CanvasRestore(canvas);
        }
        if (!leaseValid(boundGeneration) ||
            !geometryMatches(boundWindow, boundGeneration, surfaceW, surfaceH,
                             permitGeometryRevision)) {
            teardownSurface(!leaseValid(boundGeneration));
            return;
        }
        OH_Drawing_SurfaceFlush(surface);
    }

    // 前缀宽度（UTF-16 码元前缀 → 渲染宽度）；测量与绘制同一排版引擎。
    double prefixWidthUtf16(const std::u16string &text, uint32_t prefixUnits, double fontSize,
                            uint32_t fontWeight, double constraintWidth)
    {
        if (prefixUnits == 0) return 0.0;
        uint32_t units = std::min(prefixUnits, static_cast<uint32_t>(text.size()));
        std::u16string prefix = text.substr(0, units);
        Measured m = layoutText(utf16ToUtf8(prefix), fontSize, fontWeight, constraintWidth, false, 0xFF000000u);
        if (!m.typography) return 0.0;
        double w = m.longestLine;
        OH_Drawing_DestroyTypography(m.typography);
        return w;
    }

    void executeCaretHitTest(CaretHitTestJob *job)
    {
        // 二分：找使前缀宽度最接近 tapX 的码点边界（不拆代理对）。
        std::u16string text = job->text;
        uint32_t lo = 0, hi = static_cast<uint32_t>(text.size());
        while (lo < hi) {
            uint32_t mid = clampToCodePointBoundary(text, (lo + hi) / 2 + 1);
            if (mid <= lo) { lo = std::min(lo + 1, hi); continue; }
            double w = prefixWidthUtf16(text, mid, job->fontSize, job->fontWeight, job->nodeWidth);
            if (w < job->tapX) {
                lo = mid;
            } else {
                hi = mid - (mid > 0 ? 1 : 0);
                if ((lo + hi) / 2 + 1 > mid) break;
            }
        }
        job->caretUtf16 = clampToCodePointBoundary(text, lo);
        job->finish(CJGUI_INTERNAL_RENDERER_OK);
    }

    void executeMeasure(MeasureJob *job)
    {
        Measured m = layoutText(job->text, job->fontSize, job->fontWeight,
                                job->constraintWidth, job->unlimitedWidth, 0xFF000000u);
        if (!m.typography) {
            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
            return;
        }
        double lineHeight = m.lineCount > 0 ? m.height / static_cast<double>(m.lineCount) : 0;
        if (lineHeight < 1.0) lineHeight = job->fontSize * 1.2;
        job->measurement.width = static_cast<uint32_t>(m.longestLine + 0.5);
        job->measurement.height = static_cast<uint32_t>(m.height + 0.5);
        job->measurement.lineHeight = static_cast<uint32_t>(lineHeight + 0.5);
        double baseline = m.alphabeticBaseline;
        if (baseline <= 0.0) baseline = lineHeight * 0.8;
        job->measurement.baseline = static_cast<uint32_t>(baseline + 0.5);
        OH_Drawing_DestroyTypography(m.typography);
        RLOGI("measure ok w=%{public}u h=%{public}u lineH=%{public}u base=%{public}u",
              job->measurement.width, job->measurement.height,
              job->measurement.lineHeight, job->measurement.baseline);
        job->finish(CJGUI_INTERNAL_RENDERER_OK);
    }

    void executePresent(PresentJob *job)
    {
        pruneImageBitmaps();
        job->markRunning();
        // 取消检查点 1（出队后；准备阶段可取消）
        if (job->consumeCancelIfRequested()) {
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
#ifdef CJGUI_OHOS_TEST_GATES
        // A3 启动失败注入：首个 present 以非 OK 终态结束 → 核心启动失败路径
        // （StartFailed→discard→owner 退出→清理），验证重试。
        if (g_gateFailFirstFrame == 1) {
            g_gateFailFirstFrame = 0;
            RLOGW("test gate: injecting FIRST-frame failure (startup failure path)");
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
        // A1 注入：非 OK 终态 → 生产结算裁决 Rejected（回滚原候选、保留 accepted）。
        if (cjguiOhosTestGateConsumeFailNextJob()) {
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
#endif
        // 退役屏障：租约已不在宿主当前 lease 中 → 不绘制、不碰平台资源。
        if (!leaseValid(job->generation)) {
            RLOGW("present rejected on retired lease gen=%{public}llu",
                  static_cast<unsigned long long>(job->generation));
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
        // 第七次复核 B/Astra Q2：permit 闸门与 retire 仲裁已移入 ensureSurface
        // （真 acquire 之后、SurfaceCreateOnScreen 之前），此处不再重复。
        if (!geometryMatches(job->window, job->generation, job->width,
                             job->height, job->geometryRevision) ||
            !ensureSurface(job->window, job->generation, job->width,
                           job->height, job->geometryRevision)) {
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
        // 取消检查点 2（平台资源就绪、绘制前）
        if (job->consumeCancelIfRequested()) {
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
        if (surfaceBackend == SurfaceBackend::Stub) {
            // 第九次复核 A1：替身句柄上的绘制由替身分派（身份计数；
            // 身份阻塞制造「绘制窗口内退役」交错）——与 ARM 状态无关。
#ifdef CJGUI_OHOS_TEST_GATES
            cjguiOhosStubHold(2, job->generation);
            g_stubCounts[ohosStubSlot(job->generation)].drawEnter.fetch_add(1);
            g_stubCounts[ohosStubSlot(job->generation)].drawExit.fetch_add(1);
#endif
        } else if (surfaceBackend == SurfaceBackend::None) {
            // 拦截器：无 backend 句柄不得触碰任何平台库。
            g_pcCalls.postBoundaryAttempts.fetch_add(1);
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        } else {
        OH_Drawing_Canvas *canvas = OH_Drawing_SurfaceGetCanvas(surface);
        if (!canvas) {
            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
            return;
        }
        OH_Drawing_Brush *bg = OH_Drawing_BrushCreate();
        OH_Drawing_BrushSetAntiAlias(bg, true);
        OH_Drawing_BrushSetColor(bg, packColor(job->clearR, job->clearG, job->clearB, job->clearA));
        OH_Drawing_CanvasDrawBackground(canvas, bg);
        OH_Drawing_BrushDestroy(bg);
#ifdef CJGUI_OHOS_TEST_GATES
        // A2 闸门：canvas 已取得、绘制中段按住（反例 3：销毁重建落在绘制窗口）。
        g_gateDrawCount += 1;
        cjguiOhosTestGateHold("draw", g_gateHoldDrawMs, g_gateHoldDrawRemaining);
#endif
        g_pcCalls.drawEnter.fetch_add(1);
        for (const SceneNode &n : job->nodes) {
            if (n.pod.width <= 0 || n.pod.height <= 0) continue;
            OH_Drawing_CanvasSave(canvas);
            if (applyClipChain(canvas, n.pod)) {   // 空裁剪：不可见
                drawFill(canvas, n.pod);
                drawNodeImage(canvas, n);
                drawBorder(canvas, n.pod);
                drawNodeText(canvas, n);
            }
            OH_Drawing_CanvasRestore(canvas);
        }
        g_pcCalls.drawExit.fetch_add(1);
        }   // 结束真实绘制 else 分支（替身分支已在上方计数返回同一汇合点）
#ifdef CJGUI_OHOS_TEST_GATES
        // A2 闸门：最终提交准入前按住（反例 4：准入前销毁重建——旧代取消不得 Flush）。
        g_gateAdmissionCount += 1;
        cjguiOhosTestGateHold("admission", g_gateHoldAdmissionMs, g_gateHoldAdmissionRemaining);
        // 链2：替身身份阻塞——提交准入前窗口（确定性 retire-during-held）。
        cjguiOhosStubHold(4, job->generation);
#endif
        // 提交许可：取消确认与进入 Committing 在同一临界区完成。未取得许可
        // 不得 Flush；取得许可后等待方超时也只返回 PENDING(20)，不改阶段。
        if (!job->acquireCommitPermission()) {
            RLOGW("present cancelled before flush");
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
#ifdef CJGUI_OHOS_TEST_GATES
        // 在 Committing 内阻塞：制造真实 committing 超时（调用方拿 PENDING）。
        RLOGW("flush hold enter gen=%{public}llu session=%{public}llu ticket=%{public}llu",
              static_cast<unsigned long long>(job->generation),
              static_cast<unsigned long long>(job->session),
              static_cast<unsigned long long>(job->ticketId));
        cjguiOhosTestGateBeforeFlush();
        RLOGW("flush hold exit gen=%{public}llu session=%{public}llu ticket=%{public}llu",
              static_cast<unsigned long long>(job->generation),
              static_cast<unsigned long long>(job->session),
              static_cast<unsigned long long>(job->ticketId));
        // A1 注入第二落点：提交准入后的失败（核心已持 PENDING+票据 → 放行后
        // 生产结算裁决 Rejected）。两个落点共用同一计数器，先到先消耗。
        if (cjguiOhosTestGateConsumeFailNextJob()) {
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
#endif
        // 第七次复核 B（无引用退役安全）：committing 持有放行后、SurfaceFlush
        // **前**必须复核租约——持有期间该代可能已被退役且（无引用档）系统
        // 对象可能随 destroyed 回调返回而失效，Flush 前不查就是悬空使用。
        // 命中则不触碰平台资源直接以 UNAVAILABLE 结算（票据按 Rejected 收口）。
        if (!leaseValid(job->generation) ||
            !geometryMatches(job->window, job->generation, job->width,
                             job->height, job->geometryRevision)) {
            RLOGW("present flush aborted on retired lease gen=%{public}llu "
                  "(retired during committing hold)",
                  static_cast<unsigned long long>(job->generation));
            teardownSurface(!leaseValid(job->generation));
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
        // 退役屏障起点：宿主在 surface 卸载时等该代际静默。
        OH_Drawing_ErrorCode flush = OH_DRAWING_SUCCESS;
        if (surfaceBackend == SurfaceBackend::Stub) {
            // 第九次复核 A1/A4：替身 Flush 由句柄 backend 分派。S3 身份阻塞
            // 位于「enter 已增、exit 未增、在途数>0」的调用内部窗口。
#ifdef CJGUI_OHOS_TEST_GATES
            g_stubCounts[ohosStubSlot(job->generation)].flushEnter.fetch_add(1);
            busyGeneration.store(job->generation);
            cjguiOhosStubHold(3, job->generation);
            g_stubCounts[ohosStubSlot(job->generation)].flushExit.fetch_add(1);
            busyGeneration.store(0);
#endif
        } else if (surfaceBackend == SurfaceBackend::None) {
            // 拦截器：无 backend 句柄不得触碰任何平台库。
            g_pcCalls.postBoundaryAttempts.fetch_add(1);
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        } else {
        g_pcCalls.flushEnter.fetch_add(1);
        busyGeneration.store(job->generation);
        flush = OH_Drawing_SurfaceFlush(surface);
        g_pcCalls.flushExit.fetch_add(1);
        }
        // Flush 后复核：① 租约仍有效 ② 仍是本任务绑定的那一代。
        if (!leaseValid(job->generation) || job->generation != boundGeneration ||
            !geometryMatches(job->window, job->generation, job->width,
                             job->height, job->geometryRevision)) {
            RLOGW("present flush on retired surface gen=%{public}llu bound=%{public}llu",
                  static_cast<unsigned long long>(job->generation),
                  static_cast<unsigned long long>(boundGeneration));
            teardownSurface(!leaseValid(job->generation) ||
                            job->generation != boundGeneration);
            rejectedFlushes += 1;
            busyGeneration.store(0);
            job->finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);
            return;
        }
        busyGeneration.store(0);
        if (flush != OH_DRAWING_SUCCESS) {
            RLOGW("SurfaceFlush error=%{public}d", static_cast<int>(flush));
            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
            return;
        }
        RLOGI("present frame ok (nodes=%{public}zu)", job->nodes.size());
        lastNodes = job->nodes;
        lastProjectionVersion = job->projectionVersion;
        lastClearR = job->clearR;
        lastClearG = job->clearG;
        lastClearB = job->clearB;
        lastClearA = job->clearA;
        hasLastFrame = true;
        submittedFrames += 1;
        job->finish(CJGUI_INTERNAL_RENDERER_OK);
    }

    // 第九次复核 A1：统一释放器——由**句柄自身**的 backend 决定，与当前
    // ARM/DISARM 状态无关（DISARM 后仍存活的替身对象仍由替身释放；
    // 模式切换不改变旧对象的释放器）。
    void destroyBoundHandle(void *handle, SurfaceBackend backend, uint64_t generation)
    {
        if (handle == nullptr) return;
#ifdef CJGUI_OHOS_TEST_GATES
        if (backend == SurfaceBackend::Stub) {
            g_stubCounts[ohosStubSlot(generation)].destroyEnter.fetch_add(1);
            g_pcCalls.lastAccessGen.store(generation);
            OhosStubSurface *st = reinterpret_cast<OhosStubSurface *>(handle);
            {
                std::lock_guard<std::mutex> g(g_stubMutex);
                for (size_t i = 0; i < g_stubLive.size(); ++i) {
                    if (g_stubLive[i] == st) {
                        g_stubLive.erase(g_stubLive.begin() + static_cast<long>(i));
                        break;
                    }
                }
            }
            delete st;
            g_stubCounts[ohosStubSlot(generation)].destroyExit.fetch_add(1);
            return;
        }
        if (backend == SurfaceBackend::None) {
            // None：无合法释放器——拦截记录，绝不传给真实平台库。
            RLOGE("destroy on backend=None handle=%{public}p gen=%{public}llu (illegal, intercepted)",
                  handle, static_cast<unsigned long long>(generation));
            return;
        }
#endif
        g_pcCalls.destroyEnter.fetch_add(1);
        g_pcCalls.lastAccessGen.store(generation);
        OH_Drawing_SurfaceDestroy(reinterpret_cast<OH_Drawing_Surface *>(handle));
        g_pcCalls.destroyExit.fetch_add(1);
    }

    void teardownSurface(bool terminalGeneration = true)
    {
        const uint64_t tornGeneration = boundGeneration;
        if (surface) {
            destroyBoundHandle(surface, surfaceBackend, tornGeneration);
            surface = nullptr;
            surfaceBackend = SurfaceBackend::None;
        }
        boundWindow = nullptr;
        boundGeneration = 0;
        surfaceW = 0;
        surfaceH = 0;
        // A2 顺序不可颠倒：先归还使用许可（证明本线程已不再使用该代），
        // 再回传拆除确认；宿主收到确认后才归还 NativeWindow 引用。
        // 先归还引用会让「确认到达之前的任何平台访问」失去引用保护。
        releaseSurfacePermit();
        if (terminalGeneration) notifyTornDown(tornGeneration);
    }

    bool ensureSurface(void *window, uint64_t generation, int w, int h,
                       uint64_t expectedGeometryRevision)
    {
        // 第九次复核 A1：backend 属于句柄——ARM/DISARM 切换后即使参数相同
        // 也必须重建（旧句柄由其自身 backend 的释放器拆除）。
        // 第九次复核 A（零错类型调用）：**会话/句柄类型**决定分派——替身
        // 会话（宿主表 backend=1）且已 ARM → 替身；替身会话但已 DISARM →
        // None（拒绝创建，假地址绝不进真实库）；其余 → 真实。ARM/DISARM
        // 只影响后续准入，不改变既有句柄释放器。
        SurfaceBackend wantBackend = SurfaceBackend::Real;
        if (g_ingress.sessionBackend != nullptr &&
            g_ingress.sessionBackend(generation) == 1) {
#ifdef CJGUI_OHOS_TEST_GATES
            wantBackend = g_stubArmed.load() ? SurfaceBackend::Stub
                                             : SurfaceBackend::None;
#else
            wantBackend = SurfaceBackend::None;   // 普通产物：替身会话不可用
#endif
        }
        RLOGI("ensureSurface dispatch gen=%{public}llu sessBackend=%{public}d armed=%{public}d want=%{public}d",
              static_cast<unsigned long long>(generation),
              g_ingress.sessionBackend ? g_ingress.sessionBackend(generation) : -1,
#ifdef CJGUI_OHOS_TEST_GATES
              g_stubArmed.load() ? 1 : 0,
#else
              0,
#endif
              static_cast<int>(wantBackend));
        if (surface && surfaceBackend == wantBackend && boundWindow == window &&
            boundGeneration == generation && surfaceW == w && surfaceH == h &&
            permitGeometryRevision == expectedGeometryRevision) {
            return true;
        }
        // A live geometry/backend rebind discards this drawing handle, not the
        // host's reference to the same NativeWindow generation. A true retired
        // lease or a different generation still needs its terminal ACK.
        const bool sameLiveGeneration = boundGeneration == generation &&
            boundWindow == window && leaseValid(generation);
        teardownSurface(!sameLiveGeneration);
        if (!gpuContext) {
            gpuContext = OH_Drawing_GpuContextCreate();
            if (!gpuContext) {
                RLOGE("OH_Drawing_GpuContextCreate failed");
                return false;
            }
        }
#ifdef CJGUI_OHOS_TEST_GATES
        // A2 闸门：创建调用前按住（销毁重建可与创建交错到任意点）。
        RLOGW("create_before hold enter gen=%{public}llu",
              static_cast<unsigned long long>(generation));
        cjguiOhosTestGateHold("create_before", g_gateHoldCreateMs, g_gateHoldCreateRemaining);
        RLOGW("create_before hold exit gen=%{public}llu",
              static_cast<unsigned long long>(generation));
        g_gateCreateCount += 1;
#endif
        // 第七次复核 B/Astra Q2：**创建前先取得该代使用许可**（retire 仲裁
        // 前移）——许可失败即不创建、不触碰 window；创建失败路径也必须
        // 归还许可（不能漏还）。
        if (!acquireSurfacePermit(generation)) {
            RLOGW("surface create skipped: permit denied before create gen=%{public}llu",
                  static_cast<unsigned long long>(generation));
            return false;
        }
        if (permitGeometryRevision != expectedGeometryRevision) {
            RLOGW("surface geometry changed before create gen=%{public}llu expected=%{public}llu actual=%{public}llu",
                  static_cast<unsigned long long>(generation),
                  static_cast<unsigned long long>(expectedGeometryRevision),
                  static_cast<unsigned long long>(permitGeometryRevision));
            releaseSurfacePermit();
            return false;
        }
#ifdef CJGUI_OHOS_TEST_GATES
        // permit 闸门（取得许可后、创建前）随仲裁前移：语义为
        // 「已真实取得许可、尚未创建」窗口的销毁重建反例。
        cjguiOhosTestGateHold("permit", g_gateHoldPermitMs, g_gateHoldPermitRemaining);
        // 链2：替身身份阻塞——「已持许可、尚未创建」窗口的确定性 park
        //（retire 可与创建交错到任意点；放行后由下方生产复核仲裁）。
        cjguiOhosStubHold(0, generation);
        if (!leaseValid(generation) ||
            !geometryMatches(window, generation, w, h, expectedGeometryRevision)) {
            releaseSurfacePermit();
            RLOGW("present rejected after permit hold (retired during hold) gen=%{public}llu",
                  static_cast<unsigned long long>(generation));
            return false;
        }
#endif
        // 第九次复核 A1/A2：创建分派由**本次准入**的 backend 决定；产物为
        // **局部 owned resource**（未发布 bound）。真实/替身共用同一套
        // 「创建 → 返回闸门 → retire 仲裁 → 发布 bound」生产逻辑。
        void *localHandle = nullptr;
        if (wantBackend == SurfaceBackend::None) {
            // 第九次复核 A（零错类型调用）：替身会话未获准入（DISARM）→
            // **拒绝创建**——席位/哨兵地址绝不进真实平台库；许可恰好归还一次。
            RLOGW("create refused: backend=None (stub session without admission) gen=%{public}llu",
                  static_cast<unsigned long long>(generation));
            releaseSurfacePermit();
            return false;
        }
        if (wantBackend == SurfaceBackend::Stub) {
#ifdef CJGUI_OHOS_TEST_GATES
            // 替身创建：替身自有对象，window 参数原样丢弃（不接收真实裸指针）；
            // 按身份计数 enter/exit。
            g_stubCounts[ohosStubSlot(generation)].createEnter.fetch_add(1);
            g_pcCalls.lastAccessGen.store(generation);
            OhosStubSurface *st = new OhosStubSurface{generation, static_cast<int32_t>(w),
                                                      static_cast<int32_t>(h), false};
            {
                std::lock_guard<std::mutex> g(g_stubMutex);
                g_stubLive.push_back(st);
            }
            g_stubCounts[ohosStubSlot(generation)].createExit.fetch_add(1);
            localHandle = st;
#endif
        } else {
            OH_Drawing_Image_Info info{};
            info.width = w;
            info.height = h;
            info.colorType = COLOR_FORMAT_RGBA_8888;
            info.alphaType = ALPHA_FORMAT_PREMUL;
            g_pcCalls.createEnter.fetch_add(1);
            g_pcCalls.lastAccessGen.store(generation);
            localHandle = OH_Drawing_SurfaceCreateOnScreen(gpuContext, info, window);
            g_pcCalls.createExit.fetch_add(1);
            if (localHandle == nullptr) {
                uint32_t err = OH_Drawing_ErrorCodeGet();
                RLOGE("SurfaceCreateOnScreen failed w=%{public}d h=%{public}d window=%{public}p err=%{public}u",
                      w, h, window, err);
                // 创建失败：许可同步归还（不漏还，Astra Q2 失败路径要求）。
                releaseSurfacePermit();
                return false;
            }
        }

        // 第九次复核 A4：S2 闸门位置——**对象已创建返回、bound 尚未发布**的窗口。
#ifdef CJGUI_OHOS_TEST_GATES
        cjguiOhosStubHold(1, generation);
        // A2 闸门：创建返回后立即按住（返回值已定、效果未观察的窗口）。
        cjguiOhosTestGateHold("create_return", g_gateHoldCreateReturnMs,
                              g_gateHoldCreateReturnRemaining);
#endif
        // 第九次复核 A2：创建返回**与 retire 仲裁后**才发布 bound。已退役 →
        // 局部资源按其 backend 自动拆除（destroy 恰好一次）、许可恰好归还一次；
        // draw/flush/accepted 均不前进。
        if (!leaseValid(generation) ||
            !geometryMatches(window, generation, w, h, expectedGeometryRevision)) {
            destroyBoundHandle(localHandle, wantBackend, generation);
            releaseSurfacePermit();
            RLOGW("create returned after retire: local resource destroyed, permit returned "
                  "once, bound not published gen=%{public}llu",
                  static_cast<unsigned long long>(generation));
            return false;
        }

        surface = reinterpret_cast<OH_Drawing_Surface *>(localHandle);
        surfaceBackend = wantBackend;
        boundWindow = (wantBackend == SurfaceBackend::Real) ? window : nullptr;
        boundGeneration = generation;
        surfaceW = w;
        surfaceH = h;
#ifdef CJGUI_OHOS_TEST_GATES
        g_gateCreateOkCount += 1;
#endif
        RLOGI("surface bound gen=%{public}llu %dx%d backend=%{public}d",
              static_cast<unsigned long long>(generation), w, h,
              static_cast<int>(wantBackend));
        return true;
    }

    // --- drawing helpers ---

    // 裁剪链解析与 macOS 渲染器一致（CjguiComposableClipConstraintAt）：
    //  - clipConstraintCount 1..4 → 用 clip0..N-1（每个裁剪祖先的原始几何）；
    //  - 否则 → 用单 clip 字段 clipX/Y/Width/Height（+ clipCornerRadius），
    //    不是 clip0（旧实现读错槽位，导致回退路径裁剪错位）。
    // 坐标为场景绝对坐标；核心保证 clip ⊆ bounds。
    static void clipConstraintAt(const CjguiInternalRendererComposableNode &n, uint32_t index,
                                 float *x, float *y, float *w, float *h, float *radius)
    {
        if (n.clipConstraintCount == 0u || n.clipConstraintCount > 4u) {
            *x = static_cast<float>(n.clipX);
            *y = static_cast<float>(n.clipY);
            *w = static_cast<float>(n.clipWidth);
            *h = static_cast<float>(n.clipHeight);
            *radius = static_cast<float>(n.clipCornerRadius);
            return;
        }
        switch (index) {
            case 0: *x = static_cast<float>(n.clip0X); *y = static_cast<float>(n.clip0Y);
                    *w = static_cast<float>(n.clip0Width); *h = static_cast<float>(n.clip0Height);
                    *radius = static_cast<float>(n.clip0CornerRadius); break;
            case 1: *x = static_cast<float>(n.clip1X); *y = static_cast<float>(n.clip1Y);
                    *w = static_cast<float>(n.clip1Width); *h = static_cast<float>(n.clip1Height);
                    *radius = static_cast<float>(n.clip1CornerRadius); break;
            case 2: *x = static_cast<float>(n.clip2X); *y = static_cast<float>(n.clip2Y);
                    *w = static_cast<float>(n.clip2Width); *h = static_cast<float>(n.clip2Height);
                    *radius = static_cast<float>(n.clip2CornerRadius); break;
            default: *x = static_cast<float>(n.clip3X); *y = static_cast<float>(n.clip3Y);
                     *w = static_cast<float>(n.clip3Width); *h = static_cast<float>(n.clip3Height);
                     *radius = static_cast<float>(n.clip3CornerRadius); break;
        }
    }

    // 有效裁剪链。返回 false = 有效裁剪为空（零尺寸约束）：该节点必须既不可见
    // 也不可命中（旧实现把零尺寸约束 `continue` 掉，等于放行全部内容）。
    static bool effectiveClips(const CjguiInternalRendererComposableNode &n, float *xs, float *ys,
                               float *ws, float *hs, float *rs, uint32_t *count)
    {
        uint32_t c = 1;
        if (n.clipConstraintCount >= 1u && n.clipConstraintCount <= 4u) {
            c = n.clipConstraintCount;
        }
        if (c > 4u) c = 4u;
        *count = c;
        for (uint32_t i = 0; i < c; ++i) {
            clipConstraintAt(n, i, &xs[i], &ys[i], &ws[i], &hs[i], &rs[i]);
            if (ws[i] <= 0.0f || hs[i] <= 0.0f) return false;
        }
        return true;
    }

    // 命中：点必须落在节点 bounds 内，且在每一条有效裁剪约束内
    // （圆角按核心语义：角区用半径判定）。空裁剪 → 不可命中。
    static bool pointInsideClips(const CjguiInternalRendererComposableNode &n, float x, float y)
    {
        float xs[4], ys[4], ws[4], hs[4], rs[4];
        uint32_t count = 0;
        if (!effectiveClips(n, xs, ys, ws, hs, rs, &count)) return false;
        for (uint32_t i = 0; i < count; ++i) {
            if (x < xs[i] || x >= xs[i] + ws[i] || y < ys[i] || y >= ys[i] + hs[i]) return false;
            if (rs[i] > 0.0f) {
                float r = std::min(rs[i], std::min(ws[i], hs[i]) / 2.0f);
                float cx = std::min(std::max(x, xs[i] + r), xs[i] + ws[i] - r);
                float cy = std::min(std::max(y, ys[i] + r), ys[i] + hs[i] - r);
                float dx = x - cx;
                float dy = y - cy;
                if (dx * dx + dy * dy > r * r) return false;
            }
        }
        return true;
    }

    // 绘制：返回 false = 该节点有效裁剪为空，跳过绘制。
    bool applyClipChain(OH_Drawing_Canvas *canvas, const CjguiInternalRendererComposableNode &n)
    {
        float xs[4], ys[4], ws[4], hs[4], rs[4];
        uint32_t count = 0;
        if (!effectiveClips(n, xs, ys, ws, hs, rs, &count)) {
            return false;
        }
        for (uint32_t i = 0; i < count; ++i) {
            if (rs[i] > 0.0f) {
                float r = std::min(rs[i], std::min(ws[i], hs[i]) / 2.0f);
                OH_Drawing_Rect *rect = OH_Drawing_RectCreate(xs[i], ys[i], xs[i] + ws[i], ys[i] + hs[i]);
                OH_Drawing_RoundRect *rr = OH_Drawing_RoundRectCreate(rect, r, r);
                OH_Drawing_CanvasClipRoundRect(canvas, rr, INTERSECT, true);
                OH_Drawing_RoundRectDestroy(rr);
                OH_Drawing_RectDestroy(rect);
            } else {
                OH_Drawing_Rect *rect = OH_Drawing_RectCreate(xs[i], ys[i], xs[i] + ws[i], ys[i] + hs[i]);
                OH_Drawing_CanvasClipRect(canvas, rect, INTERSECT, true);
                OH_Drawing_RectDestroy(rect);
            }
        }
        return true;
    }

    void drawFill(OH_Drawing_Canvas *canvas, const CjguiInternalRendererComposableNode &n)
    {
        float x = static_cast<float>(n.x);
        float y = static_cast<float>(n.y);
        float w = static_cast<float>(n.width);
        float h = static_cast<float>(n.height);
        if (n.fillAlpha > 0.0) {
            OH_Drawing_Brush *brush = OH_Drawing_BrushCreate();
            OH_Drawing_BrushSetAntiAlias(brush, true);
            OH_Drawing_BrushSetColor(brush, packColor(n.fillRed, n.fillGreen, n.fillBlue, n.fillAlpha));
            OH_Drawing_CanvasAttachBrush(canvas, brush);
            if (n.cornerRadius > 0.0) {
                drawRoundRect(canvas, x, y, w, h, static_cast<float>(n.cornerRadius));
            } else {
                OH_Drawing_Rect *rect = OH_Drawing_RectCreate(x, y, x + w, y + h);
                OH_Drawing_CanvasDrawRect(canvas, rect);
                OH_Drawing_RectDestroy(rect);
            }
            OH_Drawing_CanvasDetachBrush(canvas);
            OH_Drawing_BrushDestroy(brush);
        }
    }

    void drawBorder(OH_Drawing_Canvas *canvas, const CjguiInternalRendererComposableNode &n)
    {
        float x = static_cast<float>(n.x);
        float y = static_cast<float>(n.y);
        float w = static_cast<float>(n.width);
        float h = static_cast<float>(n.height);
        if (n.borderWidth > 0 && n.borderAlpha > 0.0) {
            OH_Drawing_Pen *pen = OH_Drawing_PenCreate();
            OH_Drawing_PenSetAntiAlias(pen, true);
            OH_Drawing_PenSetColor(pen, packColor(n.borderRed, n.borderGreen, n.borderBlue, n.borderAlpha));
            OH_Drawing_PenSetWidth(pen, static_cast<float>(n.borderWidth));
            OH_Drawing_CanvasAttachPen(canvas, pen);
            float inset = static_cast<float>(n.borderWidth) * 0.5f;
            OH_Drawing_Rect *rect = OH_Drawing_RectCreate(x + inset, y + inset, x + w - inset, y + h - inset);
            if (n.cornerRadius > 0.0) {
                // 简化：带圆角描边用 round rect 路径（阶段1视觉对齐可接受）
                drawRoundRect(canvas, x + inset, y + inset, w - 2 * inset, h - 2 * inset,
                              static_cast<float>(n.cornerRadius) - inset);
            } else {
                OH_Drawing_CanvasDrawRect(canvas, rect);
            }
            OH_Drawing_RectDestroy(rect);
            OH_Drawing_CanvasDetachPen(canvas);
            OH_Drawing_PenDestroy(pen);
        }
    }

    void drawNodeImage(OH_Drawing_Canvas *canvas, const SceneNode &node)
    {
        if (node.pod.nodeKind != kKindImage || !node.image) return;
        // The same native bounds clip applies to both fitting modes. Round
        // corners are additional to the inherited clip chain, not a replacement.
        OH_Drawing_CanvasSave(canvas);
        const float x = static_cast<float>(node.pod.x);
        const float y = static_cast<float>(node.pod.y);
        const float w = static_cast<float>(node.pod.width);
        const float h = static_cast<float>(node.pod.height);
        OH_Drawing_Rect *bounds = OH_Drawing_RectCreate(x, y, x + w, y + h);
        if (node.pod.cornerRadius > 0) {
            const float radius = std::min(static_cast<float>(node.pod.cornerRadius),
                                          std::min(w, h) / 2.0f);
            OH_Drawing_RoundRect *rounded = OH_Drawing_RoundRectCreate(bounds, radius, radius);
            OH_Drawing_CanvasClipRoundRect(canvas, rounded, INTERSECT, true);
            OH_Drawing_RoundRectDestroy(rounded);
        } else {
            OH_Drawing_CanvasClipRect(canvas, bounds, INTERSECT, true);
        }
        auto found = imageBitmaps.find(node.image->id);
        if (found != imageBitmaps.end() && found->second.bitmap && found->second.backing) {
#ifdef CJGUI_OHOS_TEST_GATES
            RLOGI("image-draw entry=%{public}llu version=%{public}llu state=ready",
                  static_cast<unsigned long long>(node.image->id),
                  static_cast<unsigned long long>(node.image->version));
#endif
            const OhosDecodedImage &pixels = *found->second.backing;
            OhosImageGeometry geometry;
            if (cjguiOhosImageGeometry(pixels.width, pixels.height, node.pod.x, node.pod.y,
                                       node.pod.width, node.pod.height,
                                       node.pod.imageContentMode, &geometry)) {
                OH_Drawing_Rect *source = OH_Drawing_RectCreate(geometry.sourceLeft,
                    geometry.sourceTop, geometry.sourceRight, geometry.sourceBottom);
                OH_Drawing_Rect *destination = OH_Drawing_RectCreate(geometry.destLeft,
                    geometry.destTop, geometry.destRight, geometry.destBottom);
                OH_Drawing_SamplingOptions *sampling = OH_Drawing_SamplingOptionsCreate(
                    FILTER_MODE_LINEAR, MIPMAP_MODE_NONE);
                OH_Drawing_CanvasDrawBitmapRect(canvas, found->second.bitmap, source, destination, sampling);
                std::array<char, kImageLeaseKeyHexCapacity> keyHex{};
                const bool keyComplete = cjguiOhosImageKeyHex(node.image->key, &keyHex);
                RLOGI("image-lease stage=draw epoch=%{public}llu entry=%{public}llu keyHex=%{public}s version=%{public}llu projection=%{public}llu node=%{public}llu keyBytes=%{public}zu keyTruncated=%{public}d",
                      static_cast<unsigned long long>(node.image->epoch),
                      static_cast<unsigned long long>(node.image->id), keyHex.data(),
                      static_cast<unsigned long long>(node.image->version),
                      static_cast<unsigned long long>(node.pod.projectionVersion),
                      static_cast<unsigned long long>(node.pod.nodeId),
                      node.image->key.size(), keyComplete ? 0 : 1);
                if (sampling) OH_Drawing_SamplingOptionsDestroy(sampling);
                OH_Drawing_RectDestroy(source);
                OH_Drawing_RectDestroy(destination);
            }
        } else if (node.pod.fillAlpha <= 0.0) {
#ifdef CJGUI_OHOS_TEST_GATES
            RLOGI("image-draw entry=%{public}llu version=%{public}llu state=placeholder",
                  static_cast<unsigned long long>(node.image->id),
                  static_cast<unsigned long long>(node.image->version));
#endif
            // Loading/failed is visibly neutral even when the node is clear.
            OH_Drawing_Brush *placeholder = OH_Drawing_BrushCreate();
            OH_Drawing_BrushSetColor(placeholder, packColor(0.42, 0.45, 0.48, 0.24));
            OH_Drawing_CanvasAttachBrush(canvas, placeholder);
            OH_Drawing_CanvasDrawRect(canvas, bounds);
            OH_Drawing_CanvasDetachBrush(canvas);
            OH_Drawing_BrushDestroy(placeholder);
        }
        OH_Drawing_RectDestroy(bounds);
        OH_Drawing_CanvasRestore(canvas);
    }

    void drawRoundRect(OH_Drawing_Canvas *canvas, float x, float y, float w, float h, float radius)
    {
        if (w <= 0 || h <= 0) return;
        OH_Drawing_Rect *rect = OH_Drawing_RectCreate(x, y, x + w, y + h);
        float r = radius > 0 ? radius : 0.0f;
        OH_Drawing_RoundRect *rr = OH_Drawing_RoundRectCreate(rect, r, r);
        OH_Drawing_CanvasDrawRoundRect(canvas, rr);
        OH_Drawing_RoundRectDestroy(rr);
        OH_Drawing_RectDestroy(rect);
    }

    void drawNodeText(OH_Drawing_Canvas *canvas, const SceneNode &node)
    {
        uint32_t kind = node.pod.nodeKind;
        bool hasText = kind == kKindText || kind == kKindButton || kind == kKindTextInput ||
            kind == kKindIntegerInput || kind == kKindBooleanInput || kind == kKindMultiline;
        if (!hasText) return;
        uint32_t textColor = packColor(node.pod.textRed, node.pod.textGreen, node.pod.textBlue,
                                       node.pod.textAlpha);
        std::string text = displayTextForNode(node);
        bool isEditingNode = false;
        {
            std::lock_guard<std::mutex> g(g_sessions.lock);
            // 绘制当前会话的编辑视图：渲染线程是编辑缓冲绘制归属方；
            // 只有绑定本节点的活跃编辑覆盖静态 value。
            for (size_t i = 0; i < kMaxSessions; ++i) {
                Session &sess = g_sessions.sessions[i];
                if (sess.inUse && sess.editing && sess.editingNodeId == node.pod.nodeId &&
                    sess.editingResourceId == node.pod.resourceId) {
                    // 逻辑编辑已结束（retired）时本地缓冲只用来补核心「本地文字延续」
                    // 窗口内的空投影（约定由原生编辑器绘制该节点）。一旦 accepted 已经
                    // 给出这个节点的值，那就是 owner 的裁决——包括本地编辑被拒、owner
                    // 保留外部值的情形——不得再被本地缓冲遮盖，否则一次被拒的提交会
                    // 让字段持续显示那个草稿。
                    // C：本地文字延续窗口由显式旗标（preservesActiveLocalText）
                    // 判定——accepted 值为空只是业务空值，不得推断为延续窗口。
                    if (sess.editorRetired && node.pod.preservesActiveLocalText == 0) break;
                    isEditingNode = true;
                    std::u16string composed = composedBuffer(sess);
                    text = utf16ToUtf8(composed);
                    if (text.empty()) text = " ";  // 空缓冲也绘制光标
                    // 选区高亮（简单背景块）
                    if (sess.selStartUtf16 != sess.selEndUtf16) {
                        uint32_t a = std::min(sess.selStartUtf16, sess.selEndUtf16);
                        uint32_t b = std::max(sess.selStartUtf16, sess.selEndUtf16);
                        double x0 = prefixWidthUtf16(composed, a, node.pod.fontSize, node.pod.fontWeight,
                                                     static_cast<double>(node.pod.width));
                        double x1 = prefixWidthUtf16(composed, b, node.pod.fontSize, node.pod.fontWeight,
                                                     static_cast<double>(node.pod.width));
                        double insetY2 = (kind == kKindText) ? 2.0 : 6.0;
                        double lineH = node.pod.fontSize * 1.2;
                        OH_Drawing_Brush *hl = OH_Drawing_BrushCreate();
                        OH_Drawing_BrushSetColor(hl, packColor(0.30, 0.50, 0.85, 0.35));
                        OH_Drawing_CanvasAttachBrush(canvas, hl);
                        OH_Drawing_Rect *rect = OH_Drawing_RectCreate(
                            static_cast<float>(node.pod.x + 7.0 + x0),
                            static_cast<float>(node.pod.y + insetY2),
                            static_cast<float>(node.pod.x + 7.0 + x1),
                            static_cast<float>(node.pod.y + insetY2 + lineH));
                        OH_Drawing_CanvasDrawRect(canvas, rect);
                        OH_Drawing_RectDestroy(rect);
                        OH_Drawing_CanvasDetachBrush(canvas);
                        OH_Drawing_BrushDestroy(hl);
                    }
                    break;
                }
            }
        }
        if (text.empty()) return;
        Measured m = layoutText(text, node.pod.fontSize, node.pod.fontWeight,
                                static_cast<double>(node.pod.width), false, textColor);
        if (!m.typography) return;
        double lineHeight = m.lineCount > 0 ? m.height / static_cast<double>(m.lineCount) : node.pod.fontSize * 1.2;
        double insetY = (kind == kKindText) ? 2.0 : 6.0;
        double drawY = static_cast<double>(node.pod.y);
        if (m.height < static_cast<double>(node.pod.height)) {
            drawY += (static_cast<double>(node.pod.height) - m.height) / 2.0;
        } else {
            drawY += insetY;
        }
        double drawX = static_cast<double>(node.pod.x) + insetY;
        OH_Drawing_TypographyPaint(m.typography, canvas, drawX, drawY);
        OH_Drawing_DestroyTypography(m.typography);
        // 光标（仅编辑节点；渲染线程内测量前缀宽度，与绘制同引擎）
        if (isEditingNode) {
            std::u16string composed;
            uint32_t caret = 0;
            {
                std::lock_guard<std::mutex> g(g_sessions.lock);
                for (size_t i = 0; i < kMaxSessions; ++i) {
                    Session &sess = g_sessions.sessions[i];
                    if (sess.inUse && sess.editing && sess.editingNodeId == node.pod.nodeId &&
                        sess.editingResourceId == node.pod.resourceId) {
                        composed = composedBuffer(sess);
                        caret = std::min(sess.caretUtf16, static_cast<uint32_t>(composed.size()));
                        break;
                    }
                }
            }
            double caretX = prefixWidthUtf16(composed, caret, node.pod.fontSize, node.pod.fontWeight,
                                             static_cast<double>(node.pod.width));
            OH_Drawing_Brush *cb = OH_Drawing_BrushCreate();
            OH_Drawing_BrushSetColor(cb, packColor(0.65, 0.85, 1.0, 1.0));
            OH_Drawing_CanvasAttachBrush(canvas, cb);
            OH_Drawing_Rect *caretRect = OH_Drawing_RectCreate(
                static_cast<float>(drawX + caretX - 1.0), static_cast<float>(drawY),
                static_cast<float>(drawX + caretX + 1.0),
                static_cast<float>(drawY + lineHeight));
            OH_Drawing_CanvasDrawRect(canvas, caretRect);
            OH_Drawing_RectDestroy(caretRect);
            OH_Drawing_CanvasDetachBrush(canvas);
            OH_Drawing_BrushDestroy(cb);
        }
    }

    struct Measured {
        OH_Drawing_Typography *typography = nullptr;
        double height = 0;
        double longestLine = 0;
        double maxWidth = 0;
        size_t lineCount = 0;
        double alphabeticBaseline = 0;
    };

    Measured layoutText(const std::string &text, double fontSize, uint32_t fontWeight,
                        double constraintWidth, bool unlimitedWidth, uint32_t textColor)
    {
        Measured result;
        OH_Drawing_TypographyStyle *style = OH_Drawing_CreateTypographyStyle();
        OH_Drawing_TextStyle *textStyle = OH_Drawing_CreateTextStyle();
        OH_Drawing_SetTextStyleFontSize(textStyle, fontSize);
        OH_Drawing_SetTextStyleFontWeight(textStyle, mapWeight(fontWeight));
        // 共同定义的前景色由节点携带，后端不重新指定颜色。
        OH_Drawing_SetTextStyleColor(textStyle, textColor);
        const char *family = "HarmonyOS Sans";
        OH_Drawing_SetTextStyleFontFamilies(textStyle, 1, &family);
        OH_Drawing_TypographyCreate *handler =
            OH_Drawing_CreateTypographyHandler(style, OH_Drawing_GetFontCollectionGlobalInstance());
        OH_Drawing_TypographyHandlerPushTextStyle(handler, textStyle);
        OH_Drawing_TypographyHandlerAddText(handler, text.c_str());
        OH_Drawing_TypographyHandlerPopTextStyle(handler);
        result.typography = OH_Drawing_CreateTypography(handler);
        OH_Drawing_DestroyTypographyHandler(handler);
        OH_Drawing_DestroyTextStyle(textStyle);
        OH_Drawing_DestroyTypographyStyle(style);
        if (!result.typography) return result;
        double layoutWidth = unlimitedWidth ? 1000000.0 : constraintWidth;
        if (layoutWidth < 1.0) layoutWidth = 1.0;
        OH_Drawing_TypographyLayout(result.typography, layoutWidth);
        result.height = OH_Drawing_TypographyGetHeight(result.typography);
        result.longestLine = OH_Drawing_TypographyGetLongestLine(result.typography);
        result.maxWidth = OH_Drawing_TypographyGetMaxWidth(result.typography);
        result.lineCount = OH_Drawing_TypographyGetLineCount(result.typography);
        result.alphabeticBaseline = OH_Drawing_TypographyGetAlphabeticBaseline(result.typography);
        return result;
    }

    static int mapWeight(uint32_t weight)
    {
        if (weight < 100) return FONT_WEIGHT_400;
        int step = (static_cast<int>(weight) + 50) / 100 * 100;
        if (step < 100) step = 100;
        if (step > 900) step = 900;
        return step;
    }

    static uint32_t packColor(double r, double g, double b, double a)
    {
        uint32_t alpha = static_cast<uint32_t>(a * 255.0 + 0.5) << 24;
        uint32_t red = static_cast<uint32_t>(r * 255.0 + 0.5) << 16;
        uint32_t green = static_cast<uint32_t>(g * 255.0 + 0.5) << 8;
        uint32_t blue = static_cast<uint32_t>(b * 255.0 + 0.5);
        return alpha | red | green | blue;
    }

    static std::string displayTextForNode(const SceneNode &node)
    {
        uint32_t kind = node.pod.nodeKind;
        if (kind == kKindText || kind == kKindMultiline) return node.value;
        if (kind == kKindButton && !node.label.empty() && node.label == node.value) return node.value;
        if (!node.label.empty()) return node.label + " " + node.value;
        return node.value;
    }
};

RenderThread g_render;

void cjguiOhosRequestImageBitmapPrune()
{
    g_render.requestImagePrune();
}

void cjguiOhosPruneReleasedImages()
{
    try {
        // This may be called after an owner-side scene/candidate release or
        // after a decoder-local reference disappears. Never post while holding
        // the domain lock, and never destroy OH_Drawing objects off-thread.
        if (g_images.pruneReleasedIdle()) cjguiOhosRequestImageBitmapPrune();
    } catch (...) {
        RLOGE("image idle prune failed after owner release");
    }
}

void cjguiOhosLogImageSnapshot(const char *stage)
{
    uint64_t starts, encoded, readUs, decodeUs, hits;
    size_t reserved, peak, idle = 0, running, queued;
    {
        std::lock_guard<std::mutex> g(g_images.lock);
        starts = g_images.decodeStarts;
        encoded = g_images.encodedReadBytes;
        readUs = g_images.encodedReadMicros;
        decodeUs = g_images.decodeMicros;
        hits = g_images.cacheHits;
        reserved = g_images.reservedBytes;
        peak = g_images.peakTrackedBytes;
        running = g_images.inFlight;
        queued = g_images.queued;
        for (const auto &pair : g_images.entries) {
            if (pair.second.use_count() == 1 && pair.second->decoded) {
                idle += pair.second->decoded->pixels.size();
            }
        }
    }
    RLOGI("image-cost stage=%{public}s starts=%{public}llu encoded=%{public}llu readUs=%{public}llu decodeUs=%{public}llu hits=%{public}llu",
          stage, static_cast<unsigned long long>(starts),
          static_cast<unsigned long long>(encoded), static_cast<unsigned long long>(readUs),
          static_cast<unsigned long long>(decodeUs), static_cast<unsigned long long>(hits));
    RLOGI("image-cost stage=%{public}s resident=%{public}zu idle=%{public}zu activeBytes=%{public}zu peakActiveBytes=%{public}zu reservations=%{public}zu peakTracked=%{public}zu running=%{public}zu queued=%{public}zu bitmapCreates=%{public}llu bitmapDestroys=%{public}llu bitmapCreateUs=%{public}llu bitmapDestroyUs=%{public}llu",
          stage, g_imageLiveBytes.load(), idle, g_imageDecoderActiveBytes.load(),
          g_imageDecoderPeakBytes.load(), reserved, peak, running, queued,
          static_cast<unsigned long long>(g_render.bitmapCreates.load()),
          static_cast<unsigned long long>(g_render.bitmapDestroys.load()),
          static_cast<unsigned long long>(g_render.bitmapCreateMicros.load()),
          static_cast<unsigned long long>(g_render.bitmapDestroyMicros.load()));
}

void cjguiOhosPostImageRealization(const OhosImageRef &entry)
{
    try {
        if (g_render.postIfRunning(std::make_shared<ImageRealizeJob>(entry))) return;
    } catch (...) {
        RLOGE("image realization queue allocation failed entry=%{public}llu",
              static_cast<unsigned long long>(entry->id));
    }
    std::lock_guard<std::mutex> g(g_images.lock);
    if (g_images.validLocked(entry) && entry->state == 1) entry->realizationPosted = false;
}

void cjguiOhosScheduleUnpostedImages()
{
    std::array<OhosImageRef, kImageMaxRecords> ready{};
    size_t count = 0;
    {
        std::lock_guard<std::mutex> g(g_images.lock);
        for (auto &pair : g_images.entries) {
            OhosImageRef &entry = pair.second;
            if (entry->state != 1 || !entry->awaiting || entry->realizationPosted) continue;
#ifdef CJGUI_OHOS_TEST_GATES
            if (entry->completionHeld) continue;
#endif
            if (count >= ready.size()) break;
            entry->realizationPosted = true;
            ready[count++] = entry;
        }
    }
    for (size_t i = 0; i < count; ++i) cjguiOhosPostImageRealization(ready[i]);
    for (size_t i = 0; i < count; ++i) ready[i].reset();
    cjguiOhosPruneReleasedImages();
}

static bool reconcileAcceptedImagesLocked(Session *session)
{
    bool changed = false;
    std::lock_guard<std::mutex> resource(g_images.lock);  // sole nested order: S -> D
    // 观察记录随实际持有收敛：entry 被 trimIdleLocked 退役后其 ID 单调递增
    // 不复用，记录永远不会再被 reconcile 观察到；accepted 场景与在途解码都
    // 以引用/预留把 entry 钉在表内，因此“不在表内”等价于“无人持有”。只回
    // 收已退役身份，存活 entry 的记录保留，缓存中的图再次入场景不会因补记
    // 而重复完成通知；表规模随图片表上限收敛，不靠清空整表或扩大容量。
    for (auto it = session->imageObservedSerial.begin();
         it != session->imageObservedSerial.end();) {
        bool live = false;
        for (const auto &pair : g_images.entries) {
            if (pair.second->id == it->first) { live = true; break; }
        }
        if (live) ++it; else it = session->imageObservedSerial.erase(it);
    }
    for (const SceneNode &node : session->accepted) {
        const OhosImageRef &entry = node.image;
        if (!entry || !g_images.validLocked(entry) ||
            (entry->state != 2 && entry->state != 3) || entry->completionSerial == 0) continue;
        uint64_t &seen = session->imageObservedSerial[entry->id];
        if (seen < entry->completionSerial) {
            seen = entry->completionSerial;
            session->imageCompletionVersion += 1;
            changed = true;
        }
    }
    return changed;
}

void cjguiOhosNotifyImageCompletion(const OhosImageRef &entry)
{
    try {
        bool acceptedChanged = false;
        {
            std::lock_guard<std::mutex> sessions(g_sessions.lock);
            for (Session &session : g_sessions.sessions) {
                if (!session.inUse) continue;
                bool holdsEntry = false;
                for (const SceneNode &node : session.accepted) {
                    if (node.image == entry) { holdsEntry = true; break; }
                }
                if (holdsEntry && reconcileAcceptedImagesLocked(&session)) acceptedChanged = true;
            }
        }
        if (acceptedChanged) g_render.postIfRunning(std::make_shared<RedrawJob>());
    } catch (...) {
        RLOGE("image completion notification allocation failed entry=%{public}llu",
              static_cast<unsigned long long>(entry->id));
    }
}

// ---------------------------------------------------------------------------
// 事件合成（已接受场景命中 → 带身份的意图），对齐 macOS mouseDownForNode
// ---------------------------------------------------------------------------

bool hitTestAccepted(Session &s, float x, float y, size_t *outIndex)
{
    // 自后向前：场景列表后段绘制在上层。
    // 命中必须与绘制使用同一有效裁剪：越界内容不可见也不可命中，
    // 空裁剪（零尺寸约束）同理。圆角按钮（cornerRadius>0）四分圆外的
    // 点不可命中——命中几何与绘制几何一致（第六次复核第 4 项：圆角命中
    // 按已声明契约断言，D4 圆角外点必须不推进 owner）。
    for (size_t i = s.accepted.size(); i-- > 0;) {
        const CjguiInternalRendererComposableNode &n = s.accepted[i].pod;
        if (x >= static_cast<float>(n.x) && x < static_cast<float>(n.x + n.width) &&
            y >= static_cast<float>(n.y) && y < static_cast<float>(n.y + n.height)) {
            if (n.isInteractive == 0) continue;
            if (!RenderThread::pointInsideClips(n, x, y)) continue;
            if (n.cornerRadius > 0.0) {
                const float r = static_cast<float>(n.cornerRadius);
                const float right = static_cast<float>(n.x) + static_cast<float>(n.width);
                const float bottom = static_cast<float>(n.y) + static_cast<float>(n.height);
                // 就近角心：只有落在四个角方框内时才需要圆弧判别。
                const float cx = x < static_cast<float>(n.x) + r ? static_cast<float>(n.x) + r
                                                                 : (x > right - r ? right - r : x);
                const float cy = y < static_cast<float>(n.y) + r ? static_cast<float>(n.y) + r
                                                                 : (y > bottom - r ? bottom - r : y);
                const float dx = x - cx;
                const float dy = y - cy;
                if (dx * dx + dy * dy > r * r) continue;  // 圆弧外：不命中
            }
            *outIndex = i;
            return true;
        }
    }
    return false;
}

// B：滚动归属与子控件命中分开（macOS scrollNodeContainingPoint 的 H 对应）。
// 自后向前取最上层包含触点且完整落在裁剪内的 SCROLL_AREA；嵌套时后绘制
// （更内层）者先命中。几何与绘制同域：越界内容不命中。
bool scrollAreaIndexContainingPoint(Session &s, float x, float y, size_t *outIndex)
{
    for (size_t i = s.accepted.size(); i-- > 0;) {
        const CjguiInternalRendererComposableNode &n = s.accepted[i].pod;
        if (n.nodeKind != CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA) continue;
        RLOGI("scroll hit test: touch=(%{public}.0f,%{public}.0f) viewport=(%{public}lld,%{public}lld,%{public}lld,%{public}lld) density=%{public}.2f",
              x, y, static_cast<long long>(n.x), static_cast<long long>(n.y),
              static_cast<long long>(n.width), static_cast<long long>(n.height), s.surfaceDensity);
        if (x < static_cast<float>(n.x) || x >= static_cast<float>(n.x + n.width) ||
            y < static_cast<float>(n.y) || y >= static_cast<float>(n.y + n.height)) continue;
        if (!RenderThread::pointInsideClips(n, x, y)) continue;
        *outIndex = i;
        return true;
    }
    return false;
}

// B：按身份（nodeId+resourceId+kind）在当前 accepted 里重验节点。返回当前
// 下标；场景更新后同一节点以新版本继续手势，节点移除/换绑则找不到。
bool sceneIndexByIdentityLocked(Session &s, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
                                size_t *outIndex)
{
    for (size_t i = s.accepted.size(); i-- > 0;) {
        const CjguiInternalRendererComposableNode &n = s.accepted[i].pod;
        if (n.nodeId == nodeId && n.resourceId == resourceId && n.nodeKind == nodeKind) {
            *outIndex = i;
            return true;
        }
    }
    return false;
}

bool settleComposedBufferOnBlurLocked(Session &s);  // C：跨字段切换同步结算（定义在编辑缓冲区）
void stampTouchEvent(const Session &s, QueuedEvent &ev)
{
    ev.appInstance = s.gesture.appInstance;
    ev.componentInstance = s.gesture.componentInstance;
    ev.surfaceGeneration = s.gesture.surfaceGeneration;
    ev.pointerId = s.gesture.pointerId;
    ev.gestureEpoch = s.gesture.gestureEpoch;
}
// B（惯性包）：由近期样本窗估计释放速度（px/ms）。取窗口内首尾有效样本
// 差分；样本不足 2 个、时间重复/倒退、间隔过长（停顿后松手）返回 0。
double estimateReleaseVelocityPxPerMs(const Session::TouchGesture &g)
{
    if (g.velWindowCount < 2) return 0.0;
    // 取最近的连续单调样本；从尾部向前找最近一段（≤100ms 窗口）。
    const size_t last = g.velWindowCount - 1;
    size_t first = last;
    for (size_t i = last; i > 0; --i) {
        if (g.velWindowT[last] - g.velWindowT[i - 1] > 100'000'000LL) break;  // 100ms
        first = i - 1;
    }
    if (first >= last) return 0.0;
    // 逐对单调性校验（复核反例：t=10,30,20 不得被接受）。
    for (size_t i = first + 1; i <= last; ++i) {
        if (g.velWindowT[i] <= g.velWindowT[i - 1]) return 0.0;
    }
    const double dtNs = static_cast<double>(g.velWindowT[last] - g.velWindowT[first]);
    if (dtNs <= 0.0) return 0.0;  // 重复/倒退时间
    const double dy = static_cast<double>(g.velWindowY[last] - g.velWindowY[first]);
    // 返回 px/ms（y 减小 = 内容上滚 = 正方向）。
    return -dy / (dtNs / 1'000'000.0);
}

void cancelTouchGestureLocked(Session &s)
{
    if (s.gesture.active && s.gesture.scrollSampleCount > 0) {
        RLOGI("gesture-scroll-terminal terminal=%{public}s app=%{public}llu comp=%{public}llu surface=%{public}llu pointer=%{public}lld epoch=%{public}llu samples=%{public}llu rawDy=%{public}.6f whole=%{public}lld remainder=%{public}.6f",
              s.gesture.scrollEndConfirmed ? "END" : "CANCEL",
              static_cast<unsigned long long>(s.gesture.appInstance),
              static_cast<unsigned long long>(s.gesture.componentInstance),
              static_cast<unsigned long long>(s.gesture.surfaceGeneration),
              static_cast<long long>(s.gesture.pointerId),
              static_cast<unsigned long long>(s.gesture.gestureEpoch),
              static_cast<unsigned long long>(s.gesture.scrollSampleCount),
              s.gesture.scrollRawSumY,
              static_cast<long long>(s.gesture.scrollWholeDeliveredY),
              static_cast<double>(s.gesture.scrollAccumY));
    }
    // 捕获恰好一次终结：指针相位流已被核心消费（37 已入队）而尚未终结时，
    // 系统取消/退役/移除必须沿旧捕获身份送达恰好一条指针取消；核心按
    // 完整 GestureKey 匹配后清理。此后迟到的 END 不再补发。
    if (s.gesture.active && s.gesture.pointerStreamOpen && !s.gesture.pointerStreamEnded) {
        QueuedEvent ev;
        ev.kind = kEvPointerCancel;
        ev.nodeId = s.gesture.targetNodeId;
        ev.resourceId = s.gesture.targetResourceId;
        ev.nodeKind = s.gesture.targetNodeKind;
        ev.projectionVersion = s.gesture.targetProjectionVersion;
        ev.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
        stampTouchEvent(s, ev);
        ev.pointerX = static_cast<int64_t>(s.gesture.lastX);
        ev.pointerY = static_cast<int64_t>(s.gesture.lastY);
        s.events.push_back(ev);
        s.gesture.pointerStreamEnded = true;
    }
    // 有效取消：终结手势，不激活、不结算、不改 owner。长按计时一并清除
    // （系统夺走事件流后不再补发全选）。
    s.gesture = Session::TouchGesture{};
    s.textPressBeginMs = 0;
}

void enqueueEndEditingForTapLocked(Session &s)
{
    // 点击落到其他控件/空白：结束编辑（IME detach 在 pump 锁外执行）。
    // 旧上下文立即失效：晚到的提交/预览/失焦回调不得改写新焦点。
    // 组合预览不在此丢弃——pump 的 detach 分支按失焦语义把它结算给 owner
    // （恰好一次）。绘制不停：本轮投影仍由原生编辑器提供可见文本。
    if (s.editing && !s.editorRetired) {
        s.editorRetired = true;
        s.editingContextLive = false;
        s.pendingSettleOnDetach = true;
        s.pendingImeDetach = true;
    }
}

// 文本编辑器的平台编辑上下文激活（触摸点击与 focus API 共用一条路径）。
// 编辑缓冲从已接受场景值起步；每次激活分配新编辑上下文编号，旧上下文的
// 延迟回调从此失效。调用方负责 FOCUS 事件是否回发（核心发起的焦点不回发，
// 避免事件环；触摸点击回发，由核心按 accepted 场景判决并驱动 reveal）。
void beginEditingOnNodeLocked(Session &s, const SceneNode &node)
{
    const uint32_t kind = node.pod.nodeKind;
    const bool wasEditing = s.editing && !s.editorRetired && s.editingNodeId == node.pod.nodeId;
    const bool sameNodeAsBefore = s.editingNodeId == node.pod.nodeId &&
        s.editingResourceId == node.pod.resourceId;
    // C：同一有效绑定重复聚焦幂等——不换上下文编号，系统代理继续持旧编号，
    // 后续输入不会因换号被 stale 拒绝；caret 重定位由调用方按需触发。
    if (wasEditing && sameNodeAsBefore && s.editingContextLive) {
        return;
    }
    // C：跨字段切换——先按旧身份落实失焦语义（组合草稿折进缓冲并以旧身份
    // 交付 owner 恰好一次），再发布新上下文；旧编号从此失效（stale 拒绝），
    // 旧回调不可写入新字段。end 通知的身份在切换时捕获，pump 不得读新字段。
    if (s.editing && !s.editorRetired && s.editingContextLive && !sameNodeAsBefore) {
        s.detachContextId = s.editingContextId;
        s.detachFieldName = s.editingFieldName;
        settleComposedBufferOnBlurLocked(s);
        s.pendingSettleOnDetach = false;  // 已同步结算，pump 不再重复
        s.pendingImeDetach = true;        // 旧代理收场通知
    }
    s.editing = true;
    s.editorRetired = false;          // 新交互：重新成为绘制方与回调接收方
    s.editingNodeId = node.pod.nodeId;
    s.editingResourceId = node.pod.resourceId;
    s.editingNodeKind = kind;
    s.editingProjectionVersion = node.pod.projectionVersion;
    // 通用编辑上下文：每次绑定新节点/同一节点重新聚焦都分配新编号，
    // 旧上下文的延迟回调（提交/预览/失焦）从此失效，不得改写新焦点。
    s.editingContextId = g_nextEditingContextId.fetch_add(1);
    s.editingFieldName = node.semanticId;
    s.editingContextGeneration = s.surfaceGeneration;
    s.editingContextBaseVersion = node.pod.projectionVersion;
    s.editingContextLive = true;
    s.editingContextRevealRequested = false;  // 新上下文重置 reveal 请求
    s.reconcileNotifyPending = false;
    s.reconcileOldContextId = 0;
    s.pendingSettleOnDetach = false;  // 新焦点继承旧 detach 意图会重复结算
    if (!wasEditing) {
        // 编辑缓冲从已接受场景值起步（外部值即起点）。
        // 例外：核心的「本地文字延续」窗口会把 native 值置空，并约定由
        // 原生编辑器绘制该节点的可见文本。此时 accepted 里的空值不是
        // 业务空值；同一节点刚提交过的本地缓冲仍然权威，用空值重置会
        // 让重新聚焦得到一个空字段。
        std::u16string ownerValue = utf8ToUtf16(node.value);
        // C：重新聚焦只从 accepted 规范值初始化——空就是空。保留本地
        // 缓冲的唯一条件是节点带延续旗标（owner 接受了本地编辑且处于
        // 延续窗口），不得由空值推断。
        if (sameNodeAsBefore && ownerValue.empty() && !s.editingText.empty()
            && node.pod.preservesActiveLocalText != 0) {
            RLOGW("ime refocus keeps local buffer: continuation window node=%{public}llu",
                  static_cast<long long>(node.pod.nodeId));
        } else {
            s.editingText = ownerValue;
        }
        s.caretUtf16 = static_cast<uint32_t>(s.editingText.size());
        s.selStartUtf16 = s.caretUtf16;
        s.selEndUtf16 = s.caretUtf16;
        s.previewActive = false;
        s.previewText.clear();
        s.focusNotifyPending = true;   // ArkTS TextInput 代理路径
    }
}

// A：MOVE/END 共用的位移采样入口。差分由调用方以（y − lastY）传入（last
// 的推进在调用点统一负责），浮点余量保留，只有整数部分按序交付共享整数
// viewport（逐段由核心夹紧）；END 经同一入口消费最后坐标差，尾段不再丢失。
void appendScrollIntentLocked(Session &s, uint64_t nodeId, int64_t resourceId, uint64_t version,
                              int64_t delta);  // A：采样入口交付整数段（定义见下）
int64_t consumeScrollSampleLocked(Session &s, float dySample)
{
    s.gesture.scrollRawSumY += static_cast<double>(dySample);
    ++s.gesture.scrollSampleCount;
    s.gesture.scrollAccumY += dySample;
    int64_t whole = static_cast<int64_t>(s.gesture.scrollAccumY);  // 截断保余量
    if (whole == 0) return 0;
    s.gesture.scrollAccumY -= static_cast<float>(whole);
    size_t index = 0;
    if (!sceneIndexByIdentityLocked(s, s.gesture.viewportNodeId, s.gesture.viewportResourceId,
                                    CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, &index)) {
        cancelTouchGestureLocked(s);  // 视口移除/换绑：手势取消
        return 0;
    }
    if (s.gesture.viewportBindingEpoch == 0 ||
        s.accepted[index].pod.acceptedBindingEpoch != s.gesture.viewportBindingEpoch) {
        cancelTouchGestureLocked(s);
        return 0;
    }
    appendScrollIntentLocked(s, s.gesture.viewportNodeId, s.gesture.viewportResourceId,
                             s.accepted[index].pod.projectionVersion, -whole);
    s.gesture.scrollWholeDeliveredY += whole;
    return -whole;
}

// B：滚动意图进入共同 scroll 事件通道。位移按存活样本差分累计，同手势
// 且同场景版本的连续位移并入队尾事件（保留累计位移、约束队列长度）。
// 版本随当前 accepted 重验刷新：offset 更新产生新 accepted 场景后，
// 同一手势以新版本继续；视口移除/换绑由调用方取消手势。
void appendScrollIntentLocked(Session &s, uint64_t nodeId, int64_t resourceId, uint64_t version,
                              int64_t delta)
{
    if (!s.events.empty()) {
        QueuedEvent &tail = s.events.back();
        // A：只合并连续同号整数段——反号段按序交付，共享 viewport 逐段按
        // requestedOffset 夹紧（offset=0 时 -30,+30 的净效果是 30 而非 0）。
        const bool sameSign = (tail.scrollDelta >= 0) == (delta >= 0);
        if (sameSign && tail.kind == kEvScroll && tail.nodeId == nodeId &&
            tail.resourceId == resourceId && tail.projectionVersion == version &&
            tail.appInstance == s.gesture.appInstance &&
            tail.componentInstance == s.gesture.componentInstance &&
            tail.surfaceGeneration == s.gesture.surfaceGeneration &&
            tail.pointerId == s.gesture.pointerId &&
            tail.gestureEpoch == s.gesture.gestureEpoch &&
            tail.acceptedBindingEpoch == s.gesture.viewportBindingEpoch) {
            tail.scrollDelta += delta;
            tail.text = "by:" + std::to_string(tail.scrollDelta);
            return;
        }
    }
    QueuedEvent ev;
    ev.kind = kEvScroll;
    ev.nodeId = nodeId;
    ev.resourceId = resourceId;
    ev.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
    ev.projectionVersion = version;
    ev.scrollDelta = delta;
    ev.acceptedBindingEpoch = s.gesture.viewportBindingEpoch;
    ev.text = "by:" + std::to_string(delta);
    stampTouchEvent(s, ev);
    s.events.push_back(ev);
}

// B：待定手势在有效抬起时执行一次点击。移出目标、目标退役/换绑、
// surface 换代都不激活；命中目标以当前 accepted 场景重验身份。
void executePendingTapLocked(Session &s, float x, float y, int64_t nowMs)
{
    if (!s.gesture.hasTarget) {
        // 空白点击：语义与「点到其他控件」一致，结束当前编辑（否则系统
        // 键盘不会收起）。未命中不产生指针事件：没有可上报的目标节点。
        enqueueEndEditingForTapLocked(s);
        return;
    }
    size_t liftIndex = 0;
    if (!hitTestAccepted(s, x, y, &liftIndex) ||
        s.accepted[liftIndex].pod.nodeId != s.gesture.targetNodeId ||
        s.accepted[liftIndex].pod.resourceId != s.gesture.targetResourceId ||
        s.accepted[liftIndex].pod.nodeKind != s.gesture.targetNodeKind) {
        // 移出目标：不激活（不改 owner、不结算焦点）。
        return;
    }
    // B：绑定语义冻结——语义名变化即真换绑（同槽换动作/字段），在副作用
    // （结束/启动编辑上下文）发生前拒绝；同绑定换帧以当前 accepted 事实交付。
    if (s.gesture.targetBindingEpoch == 0 ||
        s.accepted[liftIndex].pod.acceptedBindingEpoch != s.gesture.targetBindingEpoch) {
        return;
    }
    const SceneNode &node = s.accepted[liftIndex];
    const uint32_t kind = node.pod.nodeKind;
    const bool longPress = s.gesture.pressBeginMs > 0 &&
        (nowMs - s.gesture.pressBeginMs) >= 400;
    if (kind == kKindBooleanInput) {
        enqueueEndEditingForTapLocked(s);  // 点击布尔：结束其他编辑（键盘收起）
        QueuedEvent ev;
        ev.kind = kEvBooleanChanged;
        ev.recordIndex = static_cast<uint32_t>(liftIndex);
        ev.nodeId = node.pod.nodeId;
        // B：同绑定换帧存活——版本取当前 accepted 事实（真换绑已被语义
        // 冻结拒绝，不会走到这里）。
        ev.projectionVersion = node.pod.projectionVersion;
        ev.resourceId = node.pod.resourceId;
        ev.nodeKind = kind;
        ev.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
        ev.text = (node.value == "true") ? "false" : "true";
        stampTouchEvent(s, ev);
        s.events.push_back(ev);
        return;
    }
    if (kind == kKindButton) {
        enqueueEndEditingForTapLocked(s);  // 点击按钮：结束其他编辑（键盘收起）
        QueuedEvent ev;
        ev.kind = kEvActivate;
        ev.recordIndex = static_cast<uint32_t>(liftIndex);
        ev.nodeId = node.pod.nodeId;
        // B：同绑定换帧存活——版本取当前 accepted 事实（真换绑已被语义
        // 冻结拒绝，不会走到这里）。
        ev.projectionVersion = node.pod.projectionVersion;
        ev.resourceId = node.pod.resourceId;
        ev.nodeKind = kind;
        ev.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
        ev.pointerX = static_cast<int64_t>(x);
        ev.pointerY = static_cast<int64_t>(y);
        stampTouchEvent(s, ev);
        s.events.push_back(ev);
        return;
    }
    if (s.gesture.targetEditableText) {
        // 点击编辑器：直接激活本节点的平台编辑上下文并回发 FOCUS。不在此
        // 结束旧编辑上下文——pump 的 detach/end 通知按当前编辑状态取上下文，
        // 先 end 后 begin 会把旧字段的收场报成新字段（编辑器间切换维持
        // 既有语义：旧缓冲随新焦点初始化被替换，不经失焦结算）。
        beginEditingOnNodeLocked(s, node);
        s.editingTapX = x - static_cast<double>(node.pod.x);   // 节点内相对坐标
        s.editingTapPending = true;
        QueuedEvent focus;
        focus.kind = kEvFocus;
        focus.recordIndex = static_cast<uint32_t>(liftIndex);
        focus.nodeId = node.pod.nodeId;
        focus.projectionVersion = node.pod.projectionVersion;
        focus.resourceId = node.pod.resourceId;
        focus.nodeKind = kind;
        focus.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
        stampTouchEvent(s, focus);
        s.events.push_back(focus);
        if (longPress) {
            // 长按 ≥400ms → 全选（移动端长按选择的最小实现），与既有
            // 语义一致：caret 点击先入队，全选在其后落账并触发重绘。
            s.selStartUtf16 = 0;
            s.selEndUtf16 = static_cast<uint32_t>(s.editingText.size());
            RLOGI("long-press selection: select-all len=%{public}u",
                  static_cast<unsigned>(s.selEndUtf16));
            g_render.post(std::make_shared<RedrawJob>());
        }
        return;
    }
    // 其他交互节点（展示文本/背景层等）：点击 = 完整指针相位对，
    // 身份取当前 accepted 场景的该节点。指针相位同样结束其他编辑。
    enqueueEndEditingForTapLocked(s);
    QueuedEvent begin;
    begin.kind = kEvPointerBegin;
    begin.recordIndex = static_cast<uint32_t>(liftIndex);
    begin.nodeId = node.pod.nodeId;
    begin.projectionVersion = node.pod.projectionVersion;
    stampTouchEvent(s, begin);
    begin.resourceId = node.pod.resourceId;
    begin.nodeKind = kind;
    begin.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
    begin.pointerX = static_cast<int64_t>(x);
    begin.pointerY = static_cast<int64_t>(y);
    s.events.push_back(begin);
    QueuedEvent end = begin;
    end.kind = kEvPointerEnd;
    end.pointerX = static_cast<int64_t>(x);
    end.pointerY = static_cast<int64_t>(y);
    s.events.push_back(end);
}

void synthesizeEventsFromRawTouch(Session &s, const RawTouchSample &sample)
{
    const uint32_t action = sample.action;
    const float x = sample.x, y = sample.y;
    // Validate the immutable record before changing gesture, editing or owner
    // state. An old A terminal must never be relabelled using B's latest BEGIN.
    if (sample.appInstance == 0 || sample.componentInstance == 0 ||
        sample.surfaceGeneration == 0 || sample.gestureEpoch == 0 || sample.pointerId < 0) return;
    if (action == CJGUI_OHOS_TOUCH_BEGIN) {
        if (sample.surfaceGeneration != s.surfaceGeneration) return;
    } else if (!s.gesture.active ||
               s.gesture.appInstance != sample.appInstance ||
               s.gesture.componentInstance != sample.componentInstance ||
               s.gesture.surfaceGeneration != sample.surfaceGeneration ||
               s.gesture.pointerId != sample.pointerId ||
               s.gesture.gestureEpoch != sample.gestureEpoch) {
        return;
    }
    // B 合成策略：单指手势，阈值前待定、超阈值由包含视口接管为连续滚动；
    // 有效抬起才执行一次点击。已激活编辑器保持长按/系统代理优先级，位移
    // 不强制当滚动。平台回调读取失败（queue 空/旧代拒绝）不会到达这里，
    // 也不合成合法触摸；坐标域与已接受场景节点一致。
    const int64_t nowMs = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
    constexpr float kTouchScrollThresholdPx = 12.0f;

    if (action == CJGUI_OHOS_TOUCH_BEGIN) {
        // A newer primary BEGIN replaces the old primary only after its own
        // immutable identity has been validated. Queue A's terminal before B.
        if (s.gesture.active) {
            if (s.gesture.appInstance == sample.appInstance &&
                s.gesture.componentInstance == sample.componentInstance &&
                s.gesture.surfaceGeneration == sample.surfaceGeneration &&
                s.gesture.pointerId == sample.pointerId &&
                s.gesture.gestureEpoch == sample.gestureEpoch) return;
            cancelTouchGestureLocked(s);
        }
        s.gesture = Session::TouchGesture{};
        s.gesture.active = true;
        s.gesture.startX = s.gesture.lastX = x;
        s.gesture.startY = s.gesture.lastY = y;
        s.gesture.surfaceGeneration = sample.surfaceGeneration;
        s.gesture.gestureEpoch = sample.gestureEpoch;
        s.gesture.appInstance = sample.appInstance;
        s.gesture.componentInstance = sample.componentInstance;
        s.gesture.pointerId = sample.pointerId;
        size_t viewportIndex = 0;
        s.gesture.hasViewport = scrollAreaIndexContainingPoint(s, x, y, &viewportIndex);
        RLOGI("touch begin: viewport=%{public}d acceptedCount=%{public}zu",
              s.gesture.hasViewport ? 1 : 0, s.accepted.size());
        {
            uint64_t vpEpoch = 0;
            for (const SceneNode &n : s.accepted) {
                if (n.pod.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA) {
                    vpEpoch = n.pod.acceptedBindingEpoch;
                    break;
                }
            }
            RLOGI("viewport pod acceptedBindingEpoch=%{public}llu",
                  static_cast<unsigned long long>(vpEpoch));
        }
        for (size_t i = 0; i < s.accepted.size(); ++i) {
            if (s.accepted[i].pod.nodeKind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA) {
                const auto &n = s.accepted[i].pod;
                RLOGI("scroll viewport node=%{public}lld rect=(%{public}lld,%{public}lld,%{public}lld,%{public}lld)",
                      static_cast<long long>(n.nodeId),
                      static_cast<long long>(n.x), static_cast<long long>(n.y),
                      static_cast<long long>(n.width), static_cast<long long>(n.height));
            }
        }
        if (s.gesture.hasViewport) {
            s.gesture.viewportNodeId = s.accepted[viewportIndex].pod.nodeId;
            s.gesture.viewportResourceId = s.accepted[viewportIndex].pod.resourceId;
            s.gesture.viewportBindingEpoch = s.accepted[viewportIndex].pod.acceptedBindingEpoch;
        }
        size_t index = 0;
        if (!hitTestAccepted(s, x, y, &index)) {
            return;  // 空白/非交互内容：无点击目标；滚动仍由包含视口接管。
        }
        const SceneNode &node = s.accepted[index];
        if (node.pod.isReadOnly != 0) return;  // 只读内容可滚动，不可激活
        const uint32_t kind = node.pod.nodeKind;
        const bool isEditableText = kind == kKindTextInput || kind == kKindIntegerInput;
        s.gesture.hasTarget = true;
        s.gesture.targetEditableText = isEditableText;
        s.gesture.targetNodeId = node.pod.nodeId;
        s.gesture.targetBindingEpoch = node.pod.acceptedBindingEpoch;
        s.gesture.targetResourceId = node.pod.resourceId;
        s.gesture.targetNodeKind = kind;
        // B：起始绑定冻结——绑定身份取 semanticId（同一控制器把动作/字段
        // 绑定在同 nodeId 的语义名上；语义名变化即真换绑）。projectionVersion
        // 只是场景版本：同绑定换帧存活（激活以当前版本发出，核心按当前场景
        // 解析），真换绑在副作用发生前拒绝。
        s.gesture.targetSemanticId = node.semanticId;
        s.gesture.targetProjectionVersion = node.pod.projectionVersion;
        if (isEditableText && s.editing && !s.editorRetired &&
            s.editingNodeId == node.pod.nodeId && s.editingResourceId == node.pod.resourceId) {
            // 已激活编辑器优先：caret 点击立即落账，长按计时开始；位移不
            // 接管为滚动（选区拖动/系统代理按明确优先级保留）。
            s.gesture.phase = Session::TouchGesture::kGestureEditorHold;
            s.gesture.pressBeginMs = nowMs;
            s.textPressBeginMs = nowMs;
            s.editingTapX = x - static_cast<double>(node.pod.x);
            s.editingTapPending = true;
        }
        return;
    }
    if (action == CJGUI_OHOS_TOUCH_UPDATE) {
        if (!s.gesture.active) return;  // 无手势的孤立位移不成合法触摸
        if (s.gesture.surfaceGeneration != s.surfaceGeneration) {
            // Surface 换代/退役：旧代手势不得延续到新挂载。
            cancelTouchGestureLocked(s);
            return;
        }
        const float dx = x - s.gesture.startX;
        const float dy = y - s.gesture.startY;
        // 差分样本必须在 last 更新前计算。待定期间样本不推进 last；
        // 视口接管后的首个差分即从起始点累计的全部位移，总量不丢。
        const float dySample = y - s.gesture.lastY;
        if (s.gesture.phase == Session::TouchGesture::kGesturePending) {
            if (std::fabs(dx) >= kTouchScrollThresholdPx || std::fabs(dy) >= kTouchScrollThresholdPx) {
                // A：跨阈值不可逆闰（Flutter monodrag 的
                // _hasDragThresholdBeenMet 同型）——回到起点不恢复点击资格。
                s.gesture.thresholdLatch = true;
            }
            if (!s.gesture.thresholdLatch &&
                std::fabs(dx) < kTouchScrollThresholdPx && std::fabs(dy) < kTouchScrollThresholdPx) {
                return;
            }
            if (s.gesture.hasViewport) {
                // 视口接管：取消子控件点击。纯滚动不结束编辑、不触发焦点
                // 切换结算，业务 owner 与草稿保持不动。
                s.gesture.phase = Session::TouchGesture::kGestureScroll;
                RLOGI("gesture scroll takeover viewport=%{public}llu target=%{public}llu",
                      static_cast<unsigned long long>(s.gesture.viewportNodeId),
                      static_cast<unsigned long long>(s.gesture.targetNodeId));
            } else if (s.gesture.hasTarget && !s.gesture.targetEditableText) {
                // 无包含视口：维持指针相位流（BEGIN 立即补发，保持序列）。
                s.gesture.phase = Session::TouchGesture::kGesturePointerDrag;
                size_t index = 0;
                if (sceneIndexByIdentityLocked(s, s.gesture.targetNodeId, s.gesture.targetResourceId,
                                               s.gesture.targetNodeKind, &index)) {
                    const SceneNode &node = s.accepted[index];
                    QueuedEvent ev;
                    ev.kind = kEvPointerBegin;
                    ev.recordIndex = static_cast<uint32_t>(index);
                    ev.nodeId = node.pod.nodeId;
                    ev.projectionVersion = node.pod.projectionVersion;
                    ev.resourceId = node.pod.resourceId;
                    ev.nodeKind = node.pod.nodeKind;
                    ev.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
                    ev.pointerX = static_cast<int64_t>(x);
                    ev.pointerY = static_cast<int64_t>(y);
                    stampTouchEvent(s, ev);
                    s.events.push_back(ev);
                    s.gesture.pointerStreamOpen = true;
                } else {
                    cancelTouchGestureLocked(s);  // 目标退役：无流可续
                    return;
                }
            } else {
                // 可编辑文本上起手且无包含视口：不滚动不拖动，待定到抬起。
                return;
            }
        }
        s.gesture.lastX = x;
        s.gesture.lastY = y;
        // B（惯性包）：UPDATE 记录速度窗样本（固定容量 FIFO 覆盖）。
        {
            auto &g = s.gesture;
            if (g.velWindowCount < Session::TouchGesture::kVelocityWindow) {
                g.velWindowY[g.velWindowCount] = y;
                g.velWindowT[g.velWindowCount] = sample.timestampNs;
                g.velWindowCount += 1;
            } else {
                for (size_t i = 1; i < Session::TouchGesture::kVelocityWindow; ++i) {
                    g.velWindowY[i - 1] = g.velWindowY[i];
                    g.velWindowT[i - 1] = g.velWindowT[i];
                }
                g.velWindowY[Session::TouchGesture::kVelocityWindow - 1] = y;
                g.velWindowT[Session::TouchGesture::kVelocityWindow - 1] = sample.timestampNs;
            }
        }
        if (s.gesture.phase == Session::TouchGesture::kGestureScroll) {
            // 连续逻辑位移：共同 scroll 意图，不做半页跳转、不写布局坐标。
            // 手指下拖（dySample>0）露出上方内容 → offset 减小（delta 取负）。
            if (dySample == 0.0f) return;
            consumeScrollSampleLocked(s, dySample);
            return;
        }
        if (s.gesture.phase == Session::TouchGesture::kGesturePointerDrag) {
            size_t index = 0;
            if (!sceneIndexByIdentityLocked(s, s.gesture.targetNodeId, s.gesture.targetResourceId,
                                            s.gesture.targetNodeKind, &index)) {
                cancelTouchGestureLocked(s);
                return;
            }
            const SceneNode &node = s.accepted[index];
            QueuedEvent ev;
            ev.kind = kEvPointerUpdate;
            ev.recordIndex = static_cast<uint32_t>(index);
            ev.nodeId = node.pod.nodeId;
            ev.projectionVersion = node.pod.projectionVersion;
            ev.resourceId = node.pod.resourceId;
            ev.nodeKind = node.pod.nodeKind;
            ev.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
            ev.pointerX = static_cast<int64_t>(x);
            ev.pointerY = static_cast<int64_t>(y);
            stampTouchEvent(s, ev);
            if (!s.events.empty()) {
                QueuedEvent &tail = s.events.back();
                if (tail.kind == kEvPointerUpdate && tail.nodeId == ev.nodeId &&
                    tail.appInstance == ev.appInstance &&
                    tail.componentInstance == ev.componentInstance &&
                    tail.surfaceGeneration == ev.surfaceGeneration &&
                    tail.pointerId == ev.pointerId && tail.gestureEpoch == ev.gestureEpoch) {
                    tail.pointerX = ev.pointerX;
                    tail.pointerY = ev.pointerY;
                    return;
                }
            }
            s.events.push_back(ev);
            return;
        }
        return;
    }
    if (action == CJGUI_OHOS_TOUCH_END || action == CJGUI_OHOS_TOUCH_CANCEL) {
        if (!s.gesture.active) return;
        // Surface 换代：旧代相位不得影响新挂载，等价取消。
        if (s.gesture.surfaceGeneration != s.surfaceGeneration) {
            cancelTouchGestureLocked(s);
            return;
        }
        if (action == CJGUI_OHOS_TOUCH_CANCEL) {
            cancelTouchGestureLocked(s);
            return;
        }
        const uint32_t phase = s.gesture.phase;
        switch (phase) {
            case Session::TouchGesture::kGesturePending: {
                // B：END 重判阈值——快速轻扫（BEGIN 后无 UPDATE）的全部位移在
                // 抬起结算为一次滚动，不得当作点击激活；仅有界视口接管。
                const float endDx = x - s.gesture.startX;
                const float endDy = y - s.gesture.startY;
                if (s.gesture.hasViewport &&
                    (std::fabs(endDx) >= kTouchScrollThresholdPx ||
                     std::fabs(endDy) >= kTouchScrollThresholdPx)) {
                    // A：无 MOVE 快扫（含中途回落的轻扫）——全部位移经同一
                    // 采样入口在抬起结算，不得当点击激活。
                    consumeScrollSampleLocked(s, y - s.gesture.lastY);
                    break;
                }
                executePendingTapLocked(s, x, y, nowMs);
                break;
            }
            case Session::TouchGesture::kGestureScroll: {
                // A：END 消费最后坐标差 + 浮点余量（同一采样入口，尾段不丢）。
                consumeScrollSampleLocked(s, y - s.gesture.lastY);
                // B（复核修）：END (t,y) 也入速度窗——快拖后停住再松手时，
                // END 样本刷新窗口尾部，不沿用停顿前的旧速度。
                {
                    auto &g = s.gesture;
                    if (g.velWindowCount > 0) {
                        g.velWindowY[g.velWindowCount - 1] = y;
                        g.velWindowT[g.velWindowCount - 1] = sample.timestampNs;
                    }
                }
                // B（惯性包）：END 后估计释放速度，若有效则发惯性启动意图
                // （kind 30 滚动通道附带速度文本 "fling:<pxPerMs>"）。
                const double velocity = estimateReleaseVelocityPxPerMs(s.gesture);
                RLOGI("fling velocity=%{public}.3f samples=%{public}zu", velocity,
                      static_cast<size_t>(s.gesture.velWindowCount));
                if (velocity != 0.0 && velocity == velocity &&
                    velocity > -1.0e300 && velocity < 1.0e300) {
                    size_t index = 0;
                    if (sceneIndexByIdentityLocked(s, s.gesture.viewportNodeId,
                                                    s.gesture.viewportResourceId,
                                                    CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, &index)) {
                        // B（复核修）：fling 携带完整身份——GestureKey + 当前
                        // accepted 事实的 acceptedBindingEpoch（同 node/resource
                        // 的旧 END 不给新绑定启动活动，核心执行前比对）。
                        char buf[48];
                        std::snprintf(buf, sizeof(buf), "fling:%.3f", velocity);
                        QueuedEvent ev;
                        ev.kind = kEvScroll;
                        ev.nodeId = s.gesture.viewportNodeId;
                        ev.resourceId = s.gesture.viewportResourceId;
                        ev.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
                        ev.projectionVersion = s.accepted[index].pod.projectionVersion;
                        ev.acceptedBindingEpoch = s.accepted[index].pod.acceptedBindingEpoch;
                        stampTouchEvent(s, ev);  // 完整 GestureKey（appInstance 等）
                        ev.text = buf;
                        s.events.push_back(ev);
                    }
                }
                break;
            }
            case Session::TouchGesture::kGesturePointerDrag: {
                size_t index = 0;
                if (sceneIndexByIdentityLocked(s, s.gesture.targetNodeId, s.gesture.targetResourceId,
                                               s.gesture.targetNodeKind, &index)) {
                    const SceneNode &node = s.accepted[index];
                    QueuedEvent ev;
                    ev.kind = kEvPointerEnd;
                    ev.recordIndex = static_cast<uint32_t>(index);
                    ev.nodeId = node.pod.nodeId;
                    ev.projectionVersion = node.pod.projectionVersion;
                    ev.resourceId = node.pod.resourceId;
                    ev.nodeKind = node.pod.nodeKind;
                    ev.acceptedBindingEpoch = s.gesture.targetBindingEpoch;
                    ev.pointerX = static_cast<int64_t>(x);
                    ev.pointerY = static_cast<int64_t>(y);
                    stampTouchEvent(s, ev);
                    s.events.push_back(ev);
                    if (s.gesture.pointerStreamOpen) s.gesture.pointerStreamEnded = true;
                }
                break;
            }
            case Session::TouchGesture::kGestureEditorHold:
                // 已激活编辑器长按 ≥400ms → 全选（既有语义保持）。
                if (s.editing && !s.editorRetired && s.textPressBeginMs > 0 &&
                    nowMs - s.textPressBeginMs >= 400) {
                    s.selStartUtf16 = 0;
                    s.selEndUtf16 = static_cast<uint32_t>(s.editingText.size());
                    RLOGI("long-press selection: select-all len=%{public}u",
                          static_cast<unsigned>(s.selEndUtf16));
                    g_render.post(std::make_shared<RedrawJob>());
                }
                break;
        }
        if (s.gesture.active) s.gesture.scrollEndConfirmed = true;
        cancelTouchGestureLocked(s);
        return;
    }
}

}  // namespace

// ---------------------------------------------------------------------------
// 平台编辑缓冲与系统输入法（OHOS IME：全 UTF-16 码元；预览=组合态）
// ---------------------------------------------------------------------------

namespace {

InputMethod_TextEditorProxy *g_imeEditorProxy = nullptr;
InputMethod_InputMethodProxy *g_imeProxy = nullptr;
bool g_imeAttached = false;

Session *findEditingSessionLocked()
{
    // 只返回「逻辑上仍在编辑」的会话：已 retirement 的会话仍由渲染器绘制
    // （见 Session::editorRetired），但不再接受平台代理的上下文查询与延迟回调。
    for (size_t i = 0; i < kMaxSessions; ++i) {
        if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].editing &&
            !g_sessions.sessions[i].editorRetired) {
            return &g_sessions.sessions[i];
        }
    }
    return nullptr;
}

// IME 视角的缓冲：基础文本 + 组合预览内联。
std::u16string composedBuffer(const Session &s)
{
    if (!s.previewActive) return s.editingText;
    uint32_t start = std::min(s.previewStart, static_cast<uint32_t>(s.editingText.size()));
    uint32_t end = std::min(std::max(s.previewEnd, start), static_cast<uint32_t>(s.editingText.size()));
    std::u16string out = s.editingText.substr(0, start);
    out += s.previewText;
    out += s.editingText.substr(end);
    return out;
}

void editorEnqueueTextChanged(Session &s)
{
    QueuedEvent ev;
    ev.kind = kEvTextChanged;  // 28
    // 身份取聚焦时的已接受场景节点（核心 resolveInput 校验）
    ev.nodeId = s.editingNodeId;
    ev.projectionVersion = s.editingProjectionVersion;
    ev.resourceId = s.editingResourceId;
    ev.nodeKind = s.editingNodeKind;
    ev.text = utf16ToUtf8(composedBuffer(s));
    s.events.push_back(ev);
}

// The system IME reports selection changes independently from text commits.
// Forward that view state through the same event FIFO as other native input so
// the Cangjie window can update its focused-selection ledger. Stamp the event
// with the exact accepted editor binding; a callback that races a rebind must
// not be able to update a new node that happens to reuse its semantic identity.
bool editorEnqueueSelectionChanged(Session &s, uint32_t start, uint32_t end)
{
    const SceneNode *acceptedNode = nullptr;
    for (const SceneNode &node : s.accepted) {
        if (node.pod.nodeId == s.editingNodeId &&
            node.pod.resourceId == s.editingResourceId &&
            node.pod.nodeKind == s.editingNodeKind &&
            node.pod.projectionVersion == s.editingProjectionVersion &&
            node.pod.isInteractive != 0 && node.pod.isReadOnly == 0 &&
            node.pod.acceptedBindingEpoch != 0) {
            acceptedNode = &node;
            break;
        }
    }
    if (!acceptedNode) return false;

    QueuedEvent ev;
    ev.kind = kEvSelectionChanged;
    ev.nodeId = acceptedNode->pod.nodeId;
    ev.resourceId = acceptedNode->pod.resourceId;
    ev.nodeKind = acceptedNode->pod.nodeKind;
    ev.projectionVersion = acceptedNode->pod.projectionVersion;
    ev.acceptedBindingEpoch = acceptedNode->pod.acceptedBindingEpoch;
    ev.selectionStart = start;
    ev.selectionEnd = end;
    s.events.push_back(ev);
    return true;
}

// 失焦结算（框架主动结束编辑，恰好一次）：把当前未提交的组合预览折进编辑
// 缓冲并作为普通编辑变化交付 owner。语义与「点到别处即失焦提交」一致，且与
// 平台的提交路径互斥——tear 掉活上下文后平台再提交必然被拒，不会二次写。
// 无组合预览（预览未激活）时不产生任何事件：owner 里的值已经是最新的。
// 返回 true = 确实结算了一次（调用方用于留证）。
bool settleComposedBufferOnBlurLocked(Session &s)
{
    if (!s.previewActive) return false;
    uint32_t start = std::min(s.previewStart, static_cast<uint32_t>(s.editingText.size()));
    uint32_t end = std::min(std::max(s.previewEnd, start), static_cast<uint32_t>(s.editingText.size()));
    std::u16string settled = s.editingText.substr(0, start);
    settled += s.previewText;
    settled += s.editingText.substr(end);
    s.editingText = settled;
    s.caretUtf16 = start + static_cast<uint32_t>(s.previewText.size());
    s.selStartUtf16 = s.caretUtf16;
    s.selEndUtf16 = s.caretUtf16;
    s.previewActive = false;
    s.previewText.clear();
    s.markedActive = false;
    if (s.caretUtf16 > s.editingText.size()) s.caretUtf16 = static_cast<uint32_t>(s.editingText.size());
    s.selStartUtf16 = s.caretUtf16;
    s.selEndUtf16 = s.caretUtf16;
    editorEnqueueTextChanged(s);
    return true;
}

void editorDeleteSelection(Session *s)
{
    uint32_t start = std::min(s->selStartUtf16, s->selEndUtf16);
    uint32_t end = std::max(s->selStartUtf16, s->selEndUtf16);
    uint32_t size = static_cast<uint32_t>(s->editingText.size());
    if (end > size) end = size;
    if (start < end) {
        s->editingText.erase(start, end - start);
    }
    s->selStartUtf16 = start;
    s->selEndUtf16 = start;
}


// ---- IME 回调（未知线程：全部经 g_sessions.lock 进入） ----

void ImeGetTextConfig(InputMethod_TextEditorProxy *proxy, InputMethod_TextConfig *config)
{
    (void)proxy;
    if (!config) return;
    // C-API IME 已弃用（本镜像 OH_TextConfig_Set* 符号缺失，历史 SEGV/relocation
    // 留证）；唯一 IME 路径是 ArkTS TextInput 代理。此回调仅在 Attach 时被走到，
    // 不再调用任何 OH_TextConfig_Set*（dlopen relocation 会失败）。
    RLOGI("ime gettextconfig: c-api path deprecated; arkts proxy is authoritative");
}

void ImeInsertText(InputMethod_TextEditorProxy *proxy, const char16_t *text, size_t length)
{
    (void)proxy;
    RLOGI("ime insert len=%{public}zu", length);
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    // 提交通常先 FinishTextPreview；防御：仍处预览时先落盘预览段。
    if (s->previewActive) {
        uint32_t start = std::min(s->previewStart, static_cast<uint32_t>(s->editingText.size()));
        uint32_t end = std::min(std::max(s->previewEnd, start), static_cast<uint32_t>(s->editingText.size()));
        s->editingText.replace(start, end - start, s->previewText);
        s->caretUtf16 = start + static_cast<uint32_t>(s->previewText.size());
        s->previewActive = false;
        s->previewText.clear();
        s->markedActive = false;
    }
    uint32_t caret = s->caretUtf16;
    editorDeleteSelection(s);
    caret = s->selStartUtf16;
    caret = std::min(caret, static_cast<uint32_t>(s->editingText.size()));
    std::u16string inserted;
    for (size_t i = 0; i < length; ++i) inserted.push_back(text[i]);
    s->editingText.insert(caret, inserted);
    s->caretUtf16 = caret + static_cast<uint32_t>(inserted.size());
    s->selStartUtf16 = s->caretUtf16;
    s->selEndUtf16 = s->caretUtf16;
    editorEnqueueTextChanged(*s);
}

void ImeDeleteForward(InputMethod_TextEditorProxy *proxy, int32_t length)
{
    (void)proxy;
    if (length <= 0) return;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    uint32_t caret = s->caretUtf16;
    if (s->selStartUtf16 != s->selEndUtf16) {
        editorDeleteSelection(s);
        caret = s->selStartUtf16;
    } else {
        uint32_t size = static_cast<uint32_t>(s->editingText.size());
        uint32_t end = std::min(caret + static_cast<uint32_t>(length), size);
        if (caret < end) s->editingText.erase(caret, end - caret);
    }
    s->caretUtf16 = caret;
    s->selStartUtf16 = caret;
    s->selEndUtf16 = caret;
    editorEnqueueTextChanged(*s);
}

void ImeDeleteBackward(InputMethod_TextEditorProxy *proxy, int32_t length)
{
    (void)proxy;
    if (length <= 0) return;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    uint32_t caret = s->caretUtf16;
    if (s->selStartUtf16 != s->selEndUtf16) {
        editorDeleteSelection(s);
        caret = s->selStartUtf16;
    } else {
        uint32_t begin = (caret >= static_cast<uint32_t>(length)) ? caret - static_cast<uint32_t>(length) : 0;
        begin = clampToCodePointBoundary(s->editingText, begin);
        if (begin < caret) s->editingText.erase(begin, caret - begin);
        caret = begin;
    }
    s->caretUtf16 = caret;
    s->selStartUtf16 = caret;
    s->selEndUtf16 = caret;
    editorEnqueueTextChanged(*s);
}

void ImeSendKeyboardStatus(InputMethod_TextEditorProxy *proxy, InputMethod_KeyboardStatus status)
{
    (void)proxy;
    RLOGI("ime keyboard status=%{public}d", static_cast<int>(status));
}

void ImeSendEnterKey(InputMethod_TextEditorProxy *proxy, InputMethod_EnterKeyType keyType)
{
    (void)proxy; (void)keyType;
    // 单行字段：回车=结束编辑（值已经由 InsertText 交付 owner）。
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (s) s->pendingImeDetach = true;
}

void ImeMoveCursor(InputMethod_TextEditorProxy *proxy, InputMethod_Direction direction)
{
    (void)proxy;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    uint32_t caret = s->caretUtf16;
    if (direction == IME_DIRECTION_UP || direction == IME_DIRECTION_LEFT) {
        if (caret > 0) caret = clampToCodePointBoundary(s->editingText, caret - 1);
    } else {
        if (caret < s->editingText.size()) {
            caret = clampToCodePointBoundary(s->editingText, caret + 1);
        }
    }
    s->caretUtf16 = caret;
    s->selStartUtf16 = caret;
    s->selEndUtf16 = caret;
}

void ImeHandleSetSelection(InputMethod_TextEditorProxy *proxy, int32_t start, int32_t end)
{
    (void)proxy;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    uint32_t size = static_cast<uint32_t>(s->editingText.size());
    uint32_t a = clampToCodePointBoundary(s->editingText, static_cast<uint32_t>(std::max(0, start)));
    uint32_t b = clampToCodePointBoundary(s->editingText, static_cast<uint32_t>(std::max(0, end)));
    a = std::min(a, size);
    b = std::min(b, size);
    s->selStartUtf16 = a;
    s->selEndUtf16 = b;
    s->caretUtf16 = b;
}

void ImeHandleExtendAction(InputMethod_TextEditorProxy *proxy, InputMethod_ExtendAction action)
{
    (void)proxy; (void)action;  // 阶段2不处理扩展动作
}

void ImeGetLeftTextOfCursor(InputMethod_TextEditorProxy *proxy, int32_t number, char16_t text[], size_t *outLength)
{
    (void)proxy;
    if (!outLength) return;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s || !text) { *outLength = 0; return; }
    std::u16string composed = composedBuffer(*s);
    uint32_t caret = std::min(s->caretUtf16, static_cast<uint32_t>(composed.size()));
    uint32_t want = static_cast<uint32_t>(std::max(0, number));
    uint32_t start = (caret > want) ? caret - want : 0;
    std::u16string left = composed.substr(start, caret - start);
    size_t copyLen = std::min(left.size(), static_cast<size_t>(number > 0 ? number : 0));
    for (size_t i = 0; i < copyLen; ++i) text[i] = left[i];
    *outLength = copyLen;
}

void ImeGetRightTextOfCursor(InputMethod_TextEditorProxy *proxy, int32_t number, char16_t text[], size_t *outLength)
{
    (void)proxy;
    if (!outLength) return;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s || !text) { *outLength = 0; return; }
    std::u16string composed = composedBuffer(*s);
    uint32_t caret = std::min(s->caretUtf16, static_cast<uint32_t>(composed.size()));
    uint32_t want = static_cast<uint32_t>(std::max(0, number));
    uint32_t avail = static_cast<uint32_t>(composed.size()) - caret;
    uint32_t take = std::min(want, avail);
    for (uint32_t i = 0; i < take; ++i) text[i] = composed[caret + i];
    *outLength = take;
}

int32_t ImeGetTextIndexAtCursor(InputMethod_TextEditorProxy *proxy)
{
    (void)proxy;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return 0;
    return static_cast<int32_t>(s->caretUtf16);
}

int32_t ImeReceivePrivateCommand(InputMethod_TextEditorProxy *proxy,
                                 InputMethod_PrivateCommand *commands[], size_t size)
{
    (void)proxy; (void)commands; (void)size;
    return 0;  // 阶段2不处理私有命令
}

int32_t ImeSetPreviewText(InputMethod_TextEditorProxy *proxy, const char16_t text[], size_t length,
                          int32_t start, int32_t end)
{
    (void)proxy;
    RLOGI("ime preview len=%{public}zu start=%{public}d end=%{public}d", length, start, end);
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return 0;
    // 组合态：预览文本替换 [start,end) 段（纯视觉；FinishTextPreview 或
    // InsertText 落盘）。不向 owner 发事件，业务值保持已应用值。
    s->previewText.clear();
    for (size_t i = 0; i < length; ++i) s->previewText.push_back(text[i]);
    uint32_t size = static_cast<uint32_t>(s->editingText.size());
    s->previewStart = clampToCodePointBoundary(s->editingText, static_cast<uint32_t>(std::max(0, start)));
    s->previewStart = std::min(s->previewStart, size);
    s->previewEnd = clampToCodePointBoundary(s->editingText, static_cast<uint32_t>(std::max(0, end)));
    s->previewEnd = std::min(std::max(s->previewEnd, s->previewStart), size);
    s->previewActive = true;
    s->markedActive = true;
    s->markedStart = s->previewStart;
    s->markedEnd = s->previewStart + static_cast<uint32_t>(s->previewText.size());
    s->markedCallbackObserved = true;
    return 0;
}

void ImeFinishTextPreview(InputMethod_TextEditorProxy *proxy)
{
    (void)proxy;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    s->previewActive = false;
    s->previewText.clear();
    s->markedActive = false;
}

bool imeAttach()
{
    if (g_imeAttached) return true;
    if (!g_imeEditorProxy) {
        g_imeEditorProxy = OH_TextEditorProxy_Create();
        if (!g_imeEditorProxy) return false;
        OH_TextEditorProxy_SetGetTextConfigFunc(g_imeEditorProxy, ImeGetTextConfig);
        OH_TextEditorProxy_SetInsertTextFunc(g_imeEditorProxy, ImeInsertText);
        OH_TextEditorProxy_SetDeleteForwardFunc(g_imeEditorProxy, ImeDeleteForward);
        OH_TextEditorProxy_SetDeleteBackwardFunc(g_imeEditorProxy, ImeDeleteBackward);
        OH_TextEditorProxy_SetSendKeyboardStatusFunc(g_imeEditorProxy, ImeSendKeyboardStatus);
        OH_TextEditorProxy_SetSendEnterKeyFunc(g_imeEditorProxy, ImeSendEnterKey);
        OH_TextEditorProxy_SetMoveCursorFunc(g_imeEditorProxy, ImeMoveCursor);
        OH_TextEditorProxy_SetHandleSetSelectionFunc(g_imeEditorProxy, ImeHandleSetSelection);
        OH_TextEditorProxy_SetHandleExtendActionFunc(g_imeEditorProxy, ImeHandleExtendAction);
        OH_TextEditorProxy_SetGetLeftTextOfCursorFunc(g_imeEditorProxy, ImeGetLeftTextOfCursor);
        OH_TextEditorProxy_SetGetRightTextOfCursorFunc(g_imeEditorProxy, ImeGetRightTextOfCursor);
        OH_TextEditorProxy_SetGetTextIndexAtCursorFunc(g_imeEditorProxy, ImeGetTextIndexAtCursor);
        OH_TextEditorProxy_SetReceivePrivateCommandFunc(g_imeEditorProxy, ImeReceivePrivateCommand);
        OH_TextEditorProxy_SetSetPreviewTextFunc(g_imeEditorProxy, ImeSetPreviewText);
        OH_TextEditorProxy_SetFinishTextPreviewFunc(g_imeEditorProxy, ImeFinishTextPreview);
    }
    InputMethod_AttachOptions *options = OH_AttachOptions_Create(true);
    InputMethod_ErrorCode rc = OH_InputMethodController_Attach(g_imeEditorProxy, options, &g_imeProxy);
    if (options) OH_AttachOptions_Destroy(options);
    if (rc != IME_ERR_OK || !g_imeProxy) {
        RLOGE("ime attach failed rc=%{public}d", static_cast<int>(rc));
        g_imeProxy = nullptr;
        return false;
    }
    g_imeAttached = true;
    OH_InputMethodProxy_ShowKeyboard(g_imeProxy);
    RLOGI("ime attached; keyboard shown");
    return true;
}

void imeDetach()
{
    if (!g_imeAttached) return;
    if (g_imeProxy) {
        OH_InputMethodProxy_HideKeyboard(g_imeProxy);
        OH_InputMethodController_Detach(g_imeProxy);
        g_imeProxy = nullptr;
    }
    g_imeAttached = false;
    RLOGI("ime detached; keyboard hidden");
}

}  // namespace

// ---------------------------------------------------------------------------
// ABI：生命周期与诊断
// ---------------------------------------------------------------------------

uint64_t cjgui_internal_renderer_create(const CjguiInternalRendererConfig *config,
                                        CjguiInternalRendererStatus *outStatus)
{
    if (!config || !outStatus) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    *outStatus = CJGUI_INTERNAL_RENDERER_OK;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    if (g_sessions.occupied >= static_cast<int>(kMaxSessions)) {
        *outStatus = CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL;
        return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
    }
    for (size_t i = 0; i < kMaxSessions; ++i) {
        Session &s = g_sessions.sessions[i];
        if (s.inUse) continue;
        s.inUse = true;
        g_sessions.occupied += 1;
        // token 从 1 起（0 是非法值）；简单递增在 64 位下不会耗尽。
        static uint64_t nextToken = 0;
        nextToken += 1;
        s.token = nextToken;
        s.title = "";
        s.windowWidth = config->windowWidth;
        s.windowHeight = config->windowHeight;
        s.clearR = config->clearColorRed;
        s.clearG = config->clearColorGreen;
        s.clearB = config->clearColorBlue;
        s.clearA = config->clearColorAlpha;
        s.rangeEditDeltaRequested = false;
        s.accepted.clear();
        s.acceptedProjectionVersion = 0;
        s.candidate.clear();
        s.imageCompletionVersion = 0;
        s.imageObservedSerial.clear();
        s.candidateOpen = false;
        s.events.clear();
        s.gesture = Session::TouchGesture{};  // B：新实例不得继承旧手势状态
        s.editorRetired = false;
        s.pendingSettleOnDetach = false;
        s.submittedFrameIndex = 0;
        s.surfaceSeen = false;
        // A1：票据身份与取证计数按新实例重置；结算槽必须干净（防 ABA）。
        s.nextTicketId = 1;
        s.unackedTicketId = 0;
        s.ticketAcceptedCount = 0;
        s.ticketRejectedCount = 0;
        s.ticketQueryCount = 0;
        s.ticketAckCount = 0;
        s.ticketDuplicateSettlementCount = 0;
        s.ticketDestroyRefusedCount = 0;
        {
            PendingSettlement &p = g_pending[i];
            p.job = nullptr;
            p.nodes.clear();
            p.projectionVersion = 0;
            p.valid = false;
            p.ticketId = 0;
            p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING;
            p.terminalStatus = 0;
            p.frameIndex = 0;
            p.settled = false;
        }
        return s.token;
    }
    *outStatus = CJGUI_INTERNAL_RENDERER_SESSION_TABLE_FULL;
    return CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_window_title(uint64_t session, const char *title)
{
    if (!title) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->title = title;
    return CJGUI_INTERNAL_RENDERER_OK;
}

int32_t cjgui_internal_renderer_set_composable_range_edit_delta(uint64_t session, int32_t enabled)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (enabled != 0) {
        // 阶段1不支持范围编辑增量投递。
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->rangeEditDeltaRequested = false;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 共享仓颉运行时会链接该 ABI；当前 OHOS 文本链使用系统 IME 代理及既有
// range/preview 入口，尚无 macOS 的窗口拥有文本会话事件桥。显式拒绝启用，
// 避免缺符号使整个 HAP 无法加载，也不把未接通的组合态冒称为成功。
extern "C" CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_owned_text_session(
    uint64_t session, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t bindingEpoch, uint32_t enabled)
{
    (void)nodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)bindingEpoch;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (enabled != 0) {
        RLOGW("window-owned text session unavailable on OHOS backend");
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 关闭链第 5 步：投递唯一 ShutdownJob、等待渲染线程 teardown surface/GPU
// 并退出、join 线程、复位启动身份。非渲染线程调用。
// 返回真实终态（OK=0 成功），调用方据此断言，不再用 Bool 误判。
int32_t ohos_renderer_shutdown_render_thread()
{
    // STOP invalidates queued work and makes the running decode discard-only.
    // It never waits for image SDK work while retiring the Surface.
    g_images.invalidate();
    CjguiInternalRendererStatus result = g_render.shutdownAndJoin();
    cjguiOhosLogImageSnapshot("stop");
    if (result == CJGUI_INTERNAL_RENDERER_OK) {
        g_rendererShutdownDone.store(true);
        RLOGI("render thread shutdown confirmed (frames=%{public}llu rejected=%{public}lld)",
              static_cast<unsigned long long>(g_render.submittedFrames),
              static_cast<long long>(g_render.rejectedFlushes));
    } else {
        RLOGE("render thread shutdown failed status=%{public}d", static_cast<int>(result));
    }
    return static_cast<int32_t>(result);
}

// ohos 专有诊断（不在共享 ABI 头中；供测试入口与取证查询结算计数）。
// 共享核心不依赖此符号，macOS 渲染器无需实现。
extern "C" int32_t cjgui_ohos_settlement_counters(int64_t *committed, int64_t *aborted,
                                                  int32_t *lastVerdict, int64_t *rejectedFlushes)
{
    if (committed) *committed = g_committedSettlements.load();
    if (aborted) *aborted = g_abortedSettlements.load();
    if (lastVerdict) *lastVerdict = g_lastSettlementVerdict.load();
    if (rejectedFlushes) *rejectedFlushes = g_render.rejectedFlushes;
    return 0;
}

// 应用停止请求后的启动身份复位：宿主在重开前调用，确保新实例拿到新代。
extern "C" int32_t cjgui_ohos_renderer_epoch()
{
    return static_cast<int32_t>(g_rendererEpoch.load());
}

// Device acceptance seam. Both symbols also exist in normal HAPs so the
// shared CJ file can link unchanged; normal calls explicitly report disabled.
extern "C" int32_t cjgui_ohos_test_image_hold_completion(uint64_t resourceVersion, int32_t held)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::vector<OhosImageRef> toPost;
    {
        std::lock_guard<std::mutex> g(g_images.lock);
        if (held) {
            g_images.heldVersion = resourceVersion;
            g_images.holdEnabled = true;
            return 1;
        }
        if (g_images.holdEnabled && g_images.heldVersion == resourceVersion) {
            g_images.heldVersion = 0;
            g_images.holdEnabled = false;
        }
        for (auto &pair : g_images.entries) {
            OhosImageRef &entry = pair.second;
            if (entry->version != resourceVersion || !entry->completionHeld) continue;
            entry->completionHeld = false;
            if (entry->state == 1 && entry->awaiting && !entry->realizationPosted) {
                entry->realizationPosted = true;
                toPost.push_back(entry);
            }
        }
    }
    for (const OhosImageRef &entry : toPost) cjguiOhosPostImageRealization(entry);
    return 1;
#else
    (void)resourceVersion; (void)held;
    return -1;
#endif
}

extern "C" int32_t cjgui_ohos_test_image_forget(uint64_t resourceVersion)
{
#ifdef CJGUI_OHOS_TEST_GATES
    std::vector<OhosImageRef> retired;
    {
        std::lock_guard<std::mutex> g(g_images.lock);
        for (auto it = g_images.entries.begin(); it != g_images.entries.end();) {
            if (it->second->version == resourceVersion && it->second.use_count() == 1 &&
                it->second->reservation == 0) {
                retired.push_back(std::move(it->second));
                g_images.bindings.erase(it->first);
                it = g_images.entries.erase(it);
            } else ++it;
        }
    }
    if (!retired.empty()) g_render.postIfRunning(std::make_shared<RedrawJob>());
    return retired.empty() ? 0 : 1;
#else
    (void)resourceVersion;
    return -1;
#endif
}

// Slots: starts, encoded bytes, SDK decode us, ready cache hits, decoder
// running, queued, awaiting bitmap, ready entries, resident owned pixel bytes,
// bitmap creates, bitmap destroys, stale completion discards.
extern "C" int32_t cjgui_ohos_test_image_stats(int64_t *out12)
{
#ifdef CJGUI_OHOS_TEST_GATES
    if (!out12) return -2;
    std::lock_guard<std::mutex> g(g_images.lock);
    size_t awaiting = 0, ready = 0;
    for (const auto &pair : g_images.entries) {
        if (pair.second->awaiting) awaiting += 1;
        if (pair.second->state == 2) ready += 1;
    }
    out12[0] = static_cast<int64_t>(g_images.decodeStarts);
    out12[1] = static_cast<int64_t>(g_images.encodedReadBytes);
    out12[2] = static_cast<int64_t>(g_images.decodeMicros);
    out12[3] = static_cast<int64_t>(g_images.cacheHits);
    out12[4] = static_cast<int64_t>(g_images.inFlight);
    out12[5] = static_cast<int64_t>(g_images.queued);
    out12[6] = static_cast<int64_t>(awaiting);
    out12[7] = static_cast<int64_t>(ready);
    out12[8] = static_cast<int64_t>(g_imageLiveBytes.load());
    out12[9] = static_cast<int64_t>(g_render.bitmapCreates.load());
    out12[10] = static_cast<int64_t>(g_render.bitmapDestroys.load());
    out12[11] = static_cast<int64_t>(g_images.staleDiscards);
    return 0;
#else
    (void)out12;
    return -1;
#endif
}

// Extended raw costs: file read us, decoder-owned in-flight bytes/current
// peak, admission reservations/current peak, bitmap create/destroy us, and
// bounded idle-cache pixel bytes. SDK-private temporary storage is excluded.
extern "C" int32_t cjgui_ohos_test_image_stats_ext(int64_t *out8)
{
#ifdef CJGUI_OHOS_TEST_GATES
    if (!out8) return -2;
    std::lock_guard<std::mutex> g(g_images.lock);
    size_t idleBytes = 0;
    for (const auto &pair : g_images.entries) {
        if (pair.second.use_count() == 1 && pair.second->decoded) {
            idleBytes += pair.second->decoded->pixels.size();
        }
    }
    out8[0] = static_cast<int64_t>(g_images.encodedReadMicros);
    out8[1] = static_cast<int64_t>(g_imageDecoderActiveBytes.load());
    out8[2] = static_cast<int64_t>(g_imageDecoderPeakBytes.load());
    out8[3] = static_cast<int64_t>(g_images.reservedBytes);
    out8[4] = static_cast<int64_t>(g_images.peakTrackedBytes);
    out8[5] = static_cast<int64_t>(g_render.bitmapCreateMicros.load());
    out8[6] = static_cast<int64_t>(g_render.bitmapDestroyMicros.load());
    out8[7] = static_cast<int64_t>(idleBytes);
    return 0;
#else
    (void)out8;
    return -1;
#endif
}

// 退役屏障查询（**仅取证读数**）：返回 1 = 该代际当前没有处于 Flush 在途。
// Sol 复核明确指出 `busyGeneration` 只盖住「闸门之后到 Flush 之前」，
// redraw 的 Flush 不在其内，因此它**不能**作为创建/绘制/teardown 的静默判据，
// 也不能用来推导「可以归还引用了」。引用归还的唯一判据是 surfaceTornDown 回传。
extern "C" int32_t cjgui_ohos_renderer_lease_quiesced(uint64_t generation)
{
    return g_render.leaseQuiesced(generation) ? 1 : 0;
}

// A2：宿主请求拆除某一代 surface（UI 线程调用，**立即返回**）。
// 只投递任务，不等待、不阻塞 UI 回调。渲染线程结束该代真实使用后，
// 经 ingress.surfaceTornDown 回传确认，宿主才在 UI 线程归还 native 引用。
// A1/A2 受控模拟：转回宿主 ingress 执行真实 retire/重发布逻辑。
// 渲染器自身不维护宿主租约表——退役判定与租约账目都在宿主。
// D 夹具：触摸注入（转回宿主触摸队列；渲染器不拥有队列）。
extern "C" int32_t cjgui_ohos_test_inject_touch(uint32_t action, float x, float y)
{
    if (g_ingress.injectTouch == nullptr) return -1;
    return g_ingress.injectTouch(action, x, y);
}

extern "C" int32_t cjgui_ohos_test_simulate_surface_retired(void)
{
    if (g_ingress.simulateSurfaceRetired == nullptr) return -1;
    return g_ingress.simulateSurfaceRetired();
}

extern "C" int32_t cjgui_ohos_test_simulate_surface_created(void)
{
    if (g_ingress.simulateSurfaceCreated == nullptr) return -1;
    return g_ingress.simulateSurfaceCreated();
}

extern "C" int32_t cjgui_ohos_request_surface_teardown(uint64_t generation)
{
    if (generation == 0) return -1;
    JobRef job = std::make_shared<TeardownJob>(generation);
    g_render.post(job);
    RLOGI("surface teardown requested gen=%{public}llu", static_cast<unsigned long long>(generation));
    return 0;
}

// A3 取证：许可配对打包读数（高 32 位 acquired，低 32 位 released）。
// 重建循环收敛判据：acquired == released（每次取得许可恰好一次归还）。
// --- 链2 替身适配器导出（仅测试变体）-------------------------------------

// 武装替身：设置替身租约与一次性身份阻塞配置（stage: 0=create 1=create_return
// 2=draw 3=flush 4=admission；holdGen<0 表示不阻塞）。
// 第九次复核 A：ARM 只影响**后续准入**（新资源的 backend），不注册会话、
// 不配置阻塞——会话经 STUB_SESSION（宿主表）、阻塞经 STUB_HOLD（直连，
// 可在 owner 阻塞于 host.start 时任意设置）。
extern "C" int32_t cjgui_ohos_test_stub_arm(int64_t enable)
{
#ifdef CJGUI_OHOS_TEST_GATES
    g_render.ensureStarted();
    if (!g_render.running) return -1;
    g_stubArmed.store(enable != 0);
    RLOGI("stub armed=%{public}d (admission only)", enable != 0 ? 1 : 0);
    return 0;
#else
    (void)enable;
    return -1;
#endif
}

// 第九次复核 C：渲染线程运行事实——owner 清理尾部据此判断是否需要
// shutdown（真正未启动的部件才记 not_started，不伪造成功 shutdown）。
extern "C" int32_t cjgui_ohos_renderer_running(void)
{
    return g_render.running ? 1 : 0;
}

// 第九次复核 A3：会话注册转发（cangjie foreign → 同库 → ingress → 宿主表；
// 不直接 UND 引用 libentry 符号——该模拟器跨库解析不可靠，实测）。
extern "C" int32_t cjgui_ohos_test_stub_session_register_cj(int64_t gen, int64_t w, int64_t h)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return (g_ingress.stubSessionRegister != nullptr)
        ? g_ingress.stubSessionRegister(gen, w, h) : -1;
#else
    (void)gen; (void)w; (void)h;
    return -1;
#endif
}

// 第九次复核 C：owner 退出原因声明（0=按请求停止，1=启动失败/异常退出）。
// 宿主 dlsym 本库查询，按事实区分 stopped/failed。
static std::atomic<int32_t> g_ownerExitReason{-1};
extern "C" void cjgui_ohos_notify_owner_exit(int32_t reason)
{
    g_ownerExitReason.store(reason);
}
extern "C" int32_t cjgui_ohos_owner_exit_reason(void)
{
    return g_ownerExitReason.load();
}

// 第九次复核 A 验收：redraw 触发出入口（测试变体；普通产物拒 -1）。
extern "C" int32_t cjgui_ohos_test_trigger_redraw(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    if (!g_render.running) return -1;
    g_render.post(std::make_shared<RedrawJob>());
    return 0;
#else
    return -1;
#endif
}

// 第九次复核 B：NEG4 隔离夹具转发（cangjie foreign → ingress → 宿主）。
extern "C" int32_t cjgui_ohos_test_audit_negative_fixture_cj(void)
{
    return (g_ingress.auditNegativeFixture != nullptr)
        ? g_ingress.auditNegativeFixture() : -1;
}

// 阻塞配置（宿主直连通道，任意时刻可设；一次性命中后自动清除）。
extern "C" int32_t cjgui_ohos_test_stub_hold_set(int32_t stage, int64_t gen, int32_t ms)
{
#ifdef CJGUI_OHOS_TEST_GATES
    g_stubHoldStage.store(gen < 0 ? -1 : stage);
    g_stubHoldGen.store(gen < 0 ? 0 : static_cast<uint64_t>(gen));
    g_stubHoldMs.store(ms);
    g_stubHoldRelease.store(false);
    RLOGI("stub hold set stage=%{public}d gen=%{public}lld ms=%{public}d",
          stage, static_cast<long long>(gen), ms);
    return 0;
#else
    (void)stage; (void)gen; (void)ms;
    return -1;
#endif
}

// 解除替身：清武装标志/租约/阻塞配置（对象回收由 teardown 路径负责）。
extern "C" int32_t cjgui_ohos_test_stub_disarm(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    g_stubArmed.store(false);
    g_stubHoldStage.store(-1);
    g_stubHoldGen.store(0);
    g_stubHoldRelease.store(false);
    return 0;
#else
    return -1;
#endif
}

// 退役仲裁点：清替身租约——生产 leaseValid 检查点立即翻转。
// 第九次复核 A3：退役走宿主表生产 destroyed 路径（带目标 generation）。
extern "C" int32_t cjgui_ohos_test_stub_lease_retire(int64_t generation)
{
#ifdef CJGUI_OHOS_TEST_GATES
    return (g_ingress.stubSessionRetire != nullptr)
        ? g_ingress.stubSessionRetire(generation) : -1;
#else
    (void)generation;
    return -1;
#endif
}

// 放行身份阻塞。
extern "C" int32_t cjgui_ohos_test_stub_release(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    g_stubHoldRelease.store(true);
    std::lock_guard<std::mutex> lk(g_stubHoldMutex);
    g_stubHoldCv.notify_all();
    return 0;
#else
    return -1;
#endif
}

// 第九次复核 A3：STUB_PRESENT 的「直接 post PresentJob」已删除——替身帧
// 一律经**正常 session 提交**驱动（业务变更 → owner pump → 原票
// queued/committing → present → ACK/结算），复用既有状态机，不另造替身
// 提交协议。替身会话注册/退役见 cjgui_ohos_test_stub_session_*。

// 第九次复核 A3：STUB_TEARDOWN 直接 post 已删除——退役走生产 destroyed
// 路径（STUB_RETIRE → cjgui_ohos_test_stub_session_retire → 宿主表退役 +
// 渲染器拆除请求），不另造替身关闭协议。

extern "C" int64_t cjgui_ohos_test_stub_counts(int64_t gen)
{
#ifdef CJGUI_OHOS_TEST_GATES
    const OhosStubCounts &c = g_stubCounts[ohosStubSlot(static_cast<uint64_t>(gen))];
    auto sat = [](int64_t v) { return v > 200 ? 200 : v; };
    int64_t packed = 0;
    packed |= sat(c.createEnter.load());
    packed |= sat(c.createExit.load()) << 8;
    packed |= sat(c.drawEnter.load()) << 16;
    packed |= sat(c.drawExit.load()) << 24;
    packed |= sat(c.flushEnter.load()) << 32;
    packed |= sat(c.flushExit.load()) << 40;
    packed |= sat(c.destroyEnter.load()) << 48;
    packed |= sat(c.destroyExit.load()) << 56;
    return packed;
#else
    (void)gen;
    return -1;
#endif
}

// 替身状态 packed：bit0 armed | bit1 holdActive | bit2 leaseSet | bit8.. 活对象数。
extern "C" int64_t cjgui_ohos_test_stub_state(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    int64_t st = 0;
    if (g_stubArmed.load()) st |= 1;
    if (g_stubHoldActive.load()) st |= 2;
    if (g_ingress.stubSessionActive != nullptr && g_ingress.stubSessionActive() > 0) st |= 4;
    {
        std::lock_guard<std::mutex> g(g_stubMutex);
        st |= (static_cast<int64_t>(g_stubLive.size()) & 0xFF) << 8;
    }
    return st;
#else
    return -1;
#endif
}

extern "C" int64_t cjgui_ohos_permit_pair_packed(void)
{
    int64_t a = static_cast<int64_t>(g_render.permitsAcquired.load());
    int64_t r = static_cast<int64_t>(g_render.permitsReleased.load());
    return (a << 32) | (r & 0xFFFFFFFFLL);
}

// A2 取证：许可与拆除计数（供宿主 hostState 与反例断言读取）。
extern "C" int32_t cjgui_ohos_surface_permit_counters(int64_t *acquired, int64_t *released,
                                                      uint64_t *boundGeneration)
{
    if (acquired) *acquired = g_render.permitsAcquired.load();
    if (released) *released = g_render.permitsReleased.load();
    if (boundGeneration) *boundGeneration = g_render.boundGeneration;
    return 0;
}

// A3 停止判据读数：窗口会话与票据是否收敛（宿主在收口前逐个断言）。
//   occupiedSessions   仍被占用的窗口会话数（收敛时应为 0）
//   unackedTickets     仍未被 ACK 的票据数（收敛时应为 0）
//   pendingSettlements 仍登记在 g_pending 未回收的票据数（收敛时应为 0）
// 这三个读数只读，不改变任何状态；宿主拿它与自己的 surface 引用账目一起
// 构成「完整判据」，而不是只看全局 shutdownDone。
extern "C" int32_t cjgui_ohos_settlement_readout(int32_t *occupiedSessions, int64_t *unackedTickets,
                                                 int64_t *pendingSettlements)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    int32_t occupied = g_sessions.occupied;
    int64_t unacked = 0;
    int64_t pending = 0;
    for (size_t i = 0; i < kMaxSessions; ++i) {
        if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].unackedTicketId != 0) {
            unacked += 1;
        }
        if (g_pending[i].valid) {
            pending += 1;
        }
    }
    if (occupiedSessions) *occupiedSessions = occupied;
    if (unackedTickets) *unackedTickets = unacked;
    if (pendingSettlements) *pendingSettlements = pending;
    return 0;
}

// A3：owner 就绪声明转发（仓颉 owner 循环 → 渲染器 → 宿主 ingress）。
// 仓颉侧无法直接链接 entry 模块的宿主桥，因此经渲染器这层静态链入的
// 符号转交；这与 cjgui_ohos_application_stop_requested 是同一通道方向。
extern "C" int32_t cjgui_ohos_notify_app_ready()
{
    g_ownerAppReady.store(true);
    RLOGI("owner app ready declared");
    if (g_ingress.appReady) {
        g_ingress.appReady();
    }
    return 0;
}

// 请求应用停止（Ability onDestroy 路径 → owner 退出 → 传输收敛 → GPU teardown）。
// 幂等：重复调用只需一次。递增渲染器代际，重开必须用新身份。
extern "C" int32_t cjgui_ohos_request_application_stop()
{
    cjgui_internal_renderer_request_application_stop();
    g_rendererEpoch.fetch_add(1);
    return g_rendererEpoch.load();
}

// 观测：应用停止请求是否已被消费（owner 退出后由宿主断言）。
extern "C" int32_t cjgui_ohos_renderer_shutdown_done()
{
    return g_rendererShutdownDone.load() ? 1 : 0;
}

// 停止请求观察：仓颉 owner 循环在每轮 pump 之间查询，据此退出循环并走
// 停止协议（停止接单 → 退出 → 传输收敛 → GPU teardown → 身份复位）。
// 这是 surface 卸载（只退役租约、保留 owner）与真正 Ability 关闭的分界。
extern "C" int32_t cjgui_ohos_application_stop_requested()
{
    return g_applicationStopRequested.load() ? 1 : 0;
}

// A3 观察：owner 是否已声明就绪（宿主 hostState 取证读数）。
extern "C" int32_t cjgui_ohos_owner_app_ready()
{
    return g_ownerAppReady.load() ? 1 : 0;
}

// A3：每次获准启动前复位「就绪/停止完成」两个**上一实例遗留**的观察位，
// 使它们不会被新实例误当作自己的事实（Sol：全局 shutdownDone 重开后
// 可能是上一实例的值，因此必须按实例复位，且它只作读数、不作判据）。
extern "C" int32_t cjgui_ohos_renderer_reset_instance_observations()
{
    g_ownerAppReady.store(false);
    g_rendererShutdownDone.store(false);
    g_applicationStopRequested.store(false);
    g_ownerExitReason.store(-1);
    RLOGI("renderer instance observations reset for new owner start");
    return 0;
}

CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t session)
{
    std::unique_lock<std::mutex> g(g_sessions.lock);
    int slot = sessionSlotLocked(session);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // A1：仍有未确认（未 ACK）票据时拒绝销毁。直接清 g_pending 只能阻止槽位
    // 误认领，不能证明原事务已结算；旧实例身份也不得在资源仍存活时被复用。
    // 调用方必须先 query 取得终态、acknowledge 回收，再销毁。
    if (slot >= 0 && g_pending[slot].valid) {
        s->ticketDestroyRefusedCount += 1;
        RLOGW("destroy refused: unacknowledged ticket=%{public}llu",
              static_cast<unsigned long long>(g_pending[slot].ticketId));
        return CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED;
    }
    const uint64_t oldProjection = s->acceptedProjectionVersion;
    std::vector<SceneNode> oldAccepted;
    oldAccepted.swap(s->accepted);
    s->acceptedProjectionVersion = 0;
    cjguiOhosLogAcceptedImageSwap(*s, oldAccepted, oldProjection, 0, "destroy");
    oldAccepted.clear();
    s->inUse = false;
    s->token = 0;
    s->candidate.clear();
    s->imageObservedSerial.clear();
    s->events.clear();
    s->gesture = Session::TouchGesture{};  // B：销毁即取消，旧相位不得延续
    s->editing = false;
    s->editingText.clear();
    s->previewText.clear();
    if (slot >= 0) {
        // 会话销毁不得让待结算票据在下一实例里被当作自己的（防 ABA）；
        // 旧票据只由原共享所有权自然回收，不再参与任何晋升。
        g_pending[slot].job = nullptr;
        g_pending[slot].nodes.clear();
        g_pending[slot].valid = false;
    }
    g_sessions.occupied -= 1;
    g.unlock();
    cjguiOhosPruneReleasedImages();
    return CJGUI_INTERNAL_RENDERER_OK;
}

uint32_t cjgui_internal_renderer_occupied_session_count(void)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    return static_cast<uint32_t>(g_sessions.occupied);
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_viewport(uint64_t session, CjguiInternalRendererViewport *outViewport)
{
    if (!outViewport) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 以 ingress 的实时租约为准；无 surface 时保留最后已知尺寸与版本。
    cjguiOhosRefreshSurfaceLocked(s);
    outViewport->width = static_cast<uint32_t>(std::max(0, s->surfaceWidth));
    outViewport->height = static_cast<uint32_t>(std::max(0, s->surfaceHeight));
    outViewport->resizeVersion = s->surfaceResizeVersion;
    outViewport->resourceCompletionVersion = s->imageCompletionVersion;
    if (outViewport->resizeVersion != s->loggedResizeVersion) {
        s->loggedResizeVersion = outViewport->resizeVersion;
        RLOGI("viewport %{public}ux%{public}u gen=%{public}llu geo=%{public}llu resize=%{public}llu density=%{public}f",
              outViewport->width, outViewport->height,
              static_cast<unsigned long long>(s->surfaceGeneration),
              static_cast<unsigned long long>(s->surfaceGeometryRevision),
              static_cast<unsigned long long>(outViewport->resizeVersion), s->surfaceDensity);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_frame(uint64_t session, int64_t *outX, int64_t *outY,
                                             int64_t *outWidth, int64_t *outHeight)
{
    if (!outX || !outY || !outWidth || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    cjguiOhosRefreshSurfaceLocked(s);
    *outX = 0;
    *outY = 0;
    *outWidth = s->surfaceWidth;
    *outHeight = s->surfaceHeight;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_activation_state(uint64_t session, int32_t *outKey,
                                                        int32_t *outMain, int32_t *outAppActive)
{
    if (!outKey || !outMain || !outAppActive) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    int active = (g_ingress.foregroundLevel && g_ingress.foregroundLevel() == 1) ? 1 : 0;
    *outKey = active;
    *outMain = active;
    *outAppActive = active;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_activate_window(uint64_t session)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 应用主窗口即宿主窗口；仅在前台时可确认激活。
    if (g_ingress.foregroundLevel && g_ingress.foregroundLevel() == 1) {
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

// 应用退出生命周期：OHOS 宿主没有 unkeyed 菜单退出；retain/release 计数真实。
static int g_exitLifecycleOwners = 0;

void cjgui_internal_renderer_retain_application_exit_lifecycle_owner(void)
{
    g_exitLifecycleOwners += 1;
}

void cjgui_internal_renderer_release_application_exit_lifecycle_owner(void)
{
    if (g_exitLifecycleOwners > 0) g_exitLifecycleOwners -= 1;
}

uint8_t cjgui_internal_renderer_has_unkeyed_application_exit_request(void)
{
    return 0;
}

void cjgui_internal_renderer_request_application_stop(void)
{
    g_applicationStopRequested.store(true);
}

void cjgui_internal_renderer_complete_application_exit_request(void)
{
    g_applicationStopRequested.store(false);
}

CjguiInternalRendererStatus cjgui_internal_renderer_request_close(uint64_t session)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->closeRequested = true;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// ABI：文字测量（经渲染线程事务）
// ---------------------------------------------------------------------------

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_text(uint64_t session, const char *text,
                                                        double fontSize, uint32_t fontWeight,
                                                        uint32_t fontFamily, uint32_t maximumWidth,
                                                        CjguiInternalRendererTextMeasurement *outMeasurement)
{
    (void)fontFamily;
    if (!text || !outMeasurement) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    MeasureJob *job = new MeasureJob();
    job->text = text;
    job->fontSize = fontSize;
    job->fontWeight = fontWeight;
    job->constraintWidth = static_cast<double>(maximumWidth);
    job->unlimitedWidth = maximumWidth == 0;
    JobRef jobRef(job);
    g_render.post(jobRef);
    // 状态码显式判别：OK=0 是成功，不能当 Bool 用。
    CjguiInternalRendererStatus waited = job->waitFor();
    if (waited != CJGUI_INTERNAL_RENDERER_OK) {
        RLOGW("measure_composable_text failed status=%{public}d", static_cast<int>(waited));
        return waited;
    }
    *outMeasurement = job->measurement;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_multiline_natural_height(
    uint64_t session, const char *text, double fontSize, uint32_t fontWeight, uint32_t fontFamily,
    uint32_t contentWidth, uint32_t *outHeight)
{
    (void)fontFamily;
    if (!text || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    MeasureJob *job = new MeasureJob();
    job->text = text;
    job->fontSize = fontSize;
    job->fontWeight = fontWeight;
    job->constraintWidth = static_cast<double>(contentWidth);
    job->unlimitedWidth = false;
    JobRef jobRef(job);
    g_render.post(jobRef);
    CjguiInternalRendererStatus waited = job->waitFor();
    if (waited != CJGUI_INTERNAL_RENDERER_OK) return waited;
    *outHeight = job->measurement.height;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composed_prefix_utf8_length(const char *utf8, uint64_t inputBytes,
                                                            uint64_t maxOutputBytes, uint64_t maxClusters,
                                                            uint8_t inputComplete, uint64_t *outPrefixBytes)
{
    if (!utf8 || !outPrefixBytes) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // 阶段1无文本编辑：仅实现 UTF-8 码点边界分组（无扩展字素簇）。
    uint64_t clusters = 0;
    uint64_t bytes = 0;
    while (bytes < inputBytes && clusters < maxClusters && bytes < maxOutputBytes) {
        unsigned char lead = static_cast<unsigned char>(utf8[bytes]);
        uint64_t len = 1;
        if ((lead & 0x80u) == 0) len = 1;
        else if ((lead & 0xE0u) == 0xC0u) len = 2;
        else if ((lead & 0xF0u) == 0xE0u) len = 3;
        else if ((lead & 0xF8u) == 0xF0u) len = 4;
        if (bytes + len > inputBytes) {
            if (!inputComplete) break;  // 输入不完整：停在边界
            return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
        }
        bytes += len;
        clusters += 1;
    }
    *outPrefixBytes = bytes;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_text_runs(uint64_t session, uint64_t nodeId,
                                                         const char *encoded)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)nodeId;
    // 清空（encoded 为空）必须成功；非空样式 runs 阶段1不支持。
    if (encoded && encoded[0] != '\0') return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_hit_test_composable_text(uint64_t session, uint64_t nodeId,
                                                         double x, double y, uint32_t *outByteOffset,
                                                         uint32_t *outAffinity)
{
    (void)session; (void)nodeId; (void)x; (void)y; (void)outByteOffset; (void)outAffinity;
    return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;  // 阶段1不支持文本级命中
}

CjguiInternalRendererStatus cjgui_internal_renderer_recover_active_text_proxy(uint64_t session, uint64_t nodeId,
                                                          int64_t resourceId, uint32_t nodeKind,
                                                          const char *acceptedValue,
                                                          uint32_t *outSelectionStart,
                                                          uint32_t *outSelectionEnd)
{
    (void)session; (void)nodeId; (void)resourceId; (void)nodeKind; (void)acceptedValue;
    (void)outSelectionStart; (void)outSelectionEnd;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;  // 无 IME/文本代理
}

CjguiInternalRendererStatus cjgui_internal_renderer_declare_input_caret(uint64_t session, uint64_t nodeId, double x,
                                                    double y, double lineHeight)
{
    (void)session; (void)nodeId; (void)x; (void)y; (void)lineHeight;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;  // 无 IME 阶段1
}

CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(uint64_t session, uint64_t nodeId,
                                                             int64_t resourceId, uint32_t nodeKind,
                                                             uint64_t sceneVersion, const char *expectedValue,
                                                             uint32_t selectionStart, uint32_t selectionEnd,
                                                             uint32_t *outSelectionStart, uint32_t *outSelectionEnd)
{
    (void)session; (void)nodeId; (void)resourceId; (void)nodeKind; (void)sceneVersion;
    (void)expectedValue; (void)selectionStart; (void)selectionEnd; (void)outSelectionStart; (void)outSelectionEnd;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;  // 无选区恢复
}

// ---------------------------------------------------------------------------
// ABI：场景事务（configure → set → present）
// ---------------------------------------------------------------------------

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(uint64_t session, uint64_t projectionVersion,
                                                           uint32_t nodeCount)
{
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        s->candidateOpen = true;
        s->candidateProjectionVersion = projectionVersion;
        // 增量事务语义：候选从"已接受场景"播种（保留未重新 stage 的节点内容/
        // 身份/文字），随后核心只覆盖变化的槽位；present 成功才整体晋升。
        // 播种节点统一采用本事务的 projectionVersion：整个场景共享一个版本，
        // 未变化节点同样要跟随推进，否则合成事件带旧版本会被核心拒绝。
        s->candidate.assign(nodeCount, SceneNode{});
        for (size_t i = 0; i < nodeCount && i < s->accepted.size(); ++i) {
            s->candidate[i] = s->accepted[i];
            s->candidate[i].pod.projectionVersion = projectionVersion;
        }
    }
    cjguiOhosPruneReleasedImages();  // a replaced rejected candidate may have been the last owner
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node(uint64_t session, uint32_t nodeIndex,
                                                          const CjguiInternalRendererComposableNode *node,
                                                          const char *label, const char *value,
                                                          const char *imageResourcePath,
                                                          const char *imageResourceId,
                                                          uint64_t imageResourceVersion)
{
    if (!node) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    OhosImageRef image;
    bool replacedImage = false;
    std::unique_lock<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!s->candidateOpen || nodeIndex >= s->candidate.size()) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (node->nodeKind == kKindImage) {
        if (!imageResourcePath || !imageResourceId || !imageResourceId[0] ||
            (node->imageContentMode != 1 && node->imageContentMode != 2)) {
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        uint32_t state = 0;
        CjguiInternalRendererStatus status = cjguiOhosImageAccessNoThrow(imageResourcePath, imageResourceId,
            imageResourceVersion, true, false, &image, &state);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        if (!image) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    } else if (imageResourcePath && imageResourcePath[0] != '\0') {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    SceneNode &dst = s->candidate[nodeIndex];
    dst.pod = *node;
    dst.label = label ? label : "";
    dst.value = value ? value : "";
    dst.semanticId = "";
    replacedImage = static_cast<bool>(dst.image);
    dst.image = std::move(image);
    g.unlock();
    if (replacedImage) cjguiOhosPruneReleasedImages();
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_node_semantic_identity(uint64_t session, uint32_t nodeIndex,
                                                                      const char *semanticId)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!s->candidateOpen || nodeIndex >= s->candidate.size()) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    s->candidate[nodeIndex].semanticId = semanticId ? semanticId : "";
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 编辑缓冲同步：accepted 场景是 owner 的新投影。活上下文绑定的基线版本
// 不可被悄悄更新；外部换版必须先让旧上下文失效，再从 accepted 值建立新
// 上下文。即使预览活跃也必须检查身份/可编辑性/版本，否则旧草稿会遮住
// 已接受的外部值并借旧上下文继续提交。
//
// A1：同步成功路径与延迟成功（票据结算）必须走同一条收尾，否则延迟成功会
// 漏掉编辑缓冲处理（Astra 指出的现有缺陷）。在 g_sessions.lock 内调用。
static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)
{
    if (!s->editing) return;
    bool found = false;
    for (const SceneNode &n : s->accepted) {
        if (n.pod.nodeId != s->editingNodeId || n.pod.resourceId != s->editingResourceId) continue;
        found = true;
        if (n.pod.nodeKind != s->editingNodeKind ||
            n.semanticId != s->editingFieldName ||
            n.pod.isReadOnly != 0 || n.pod.isInteractive == 0) {
            s->pendingImeDetach = true;  // 换绑/禁用：旧上下文失效
            s->pendingSettleOnDetach = false;
            s->editing = false;          // 节点不可编辑：连同绘制一起结束
            s->editorRetired = true;
            s->editingContextLive = false;
            s->previewActive = false;
            s->previewText.clear();
            s->markedActive = false;
            s->reconcileNotifyPending = false;
            break;
        }
        std::u16string ownerValue = utf8ToUtf16(n.value);
        // The core marks a locally accepted text event explicitly and stages an
        // empty native value so the active editor keeps drawing the event text.
        // Its scene version advances too: carry that admission version forward
        // without retiring this context or mistaking the staged empty value for
        // an external replacement (including a legitimate empty local edit).
        if (n.pod.preservesActiveLocalText != 0) {
            s->editingContextBaseVersion = n.pod.projectionVersion;
            s->editingProjectionVersion = n.pod.projectionVersion;
            break;
        }
        if (s->editingContextLive &&
            n.pod.projectionVersion != s->editingContextBaseVersion) {
            // projectionVersion 与 editingContextBaseVersion 均取本节点入场时
            // 的同一 scene.version；它是当前输入事件的准入版本。新 accepted
            // 版本使旧整值草稿失效，不以字符串相等推断事务仍有效。
            int64_t oldContext = s->editingContextId;
            if (!s->reconcileNotifyPending) s->reconcileOldContextId = oldContext;
            s->editingContextId = g_nextEditingContextId.fetch_add(1);
            s->editingContextBaseVersion = n.pod.projectionVersion;
            s->editingProjectionVersion = n.pod.projectionVersion;
            s->editingFieldName = n.semanticId;
            s->editingText = ownerValue;
            s->previewActive = false;
            s->previewText.clear();
            s->markedActive = false;
            s->markedStart = 0;
            s->markedEnd = 0;
            s->pendingSettleOnDetach = false;
            s->caretUtf16 = static_cast<uint32_t>(ownerValue.size());
            s->selStartUtf16 = s->caretUtf16;
            s->selEndUtf16 = s->caretUtf16;
            s->editingTapPending = false;
            // 如果最初的 focus 还未送达，直接发送新 context 的 focus；
            // 否则发送 reconcile，供页面先卸旧 TextInput 再挂新实例。
            if (!s->focusNotifyPending) s->reconcileNotifyPending = true;
            RLOGI("ime context reconcile old=%{public}lld new=%{public}lld base=%{public}llu",
                  static_cast<long long>(oldContext),
                  static_cast<long long>(s->editingContextId),
                  static_cast<unsigned long long>(s->editingContextBaseVersion));
            g_render.post(std::make_shared<RedrawJob>());
            break;
        }
        if (s->previewActive) break;
        // 核心的「本地文字延续」窗口会把 native 值置空，约定由原生编辑器
        // 绘制可见文本（macOS 用输入代理字符串做同一件事）。这里的空值不是
        // 业务空值，用它同步会清掉本地缓冲，使随后任何纯重绘把字段画成空白。
        // C：延续窗口必须由显式旗标判定。owner 值为空且节点未打延续旗标 =
        // 业务空值（外部清空/合法空提交）——必须同步清空本地缓冲，
        // 不得凭「owner 空 + 缓冲非空」推断为延续。
        bool blankedByLocalContinuation = ownerValue.empty() && !s->editingText.empty()
            && n.pod.preservesActiveLocalText != 0;
        if (!blankedByLocalContinuation && ownerValue != s->editingText) {
            s->editingText = ownerValue;
        }
        s->caretUtf16 = std::min(s->caretUtf16, static_cast<uint32_t>(s->editingText.size()));
        s->selStartUtf16 = std::min(s->selStartUtf16, static_cast<uint32_t>(s->editingText.size()));
        s->selEndUtf16 = std::min(s->selEndUtf16, static_cast<uint32_t>(s->editingText.size()));
        s->editingProjectionVersion = n.pod.projectionVersion;
        break;
    }
    if (!found) {
        s->pendingImeDetach = true;  // 节点被移除：结束编辑
        s->pendingSettleOnDetach = false;
        s->editing = false;
        s->editorRetired = true;
        s->editingContextLive = false;
        s->previewActive = false;
        s->previewText.clear();
        s->markedActive = false;
        s->reconcileNotifyPending = false;
    }
}

// 一次性裁决一张未 ACK 的票据（在 g_sessions.lock 内调用）。
//  - 无票据 → DECISION_NONE
//  - 仍在 Committing → DECISION_PENDING（不裁决、不并发提交）
//  - 已 OK → 唯一一次 commit：晋升 accepted/帧号（提交裁决点）→ DECISION_ACCEPTED
//  - 其它终态 → 唯一一次 rollback：丢弃候选、保留旧 accepted → DECISION_REJECTED
//
// A1：终态写入后不再改变（重复调用直接返回同一 decision），记录保留到 ACK。
// 这是“重复查询返回相同结果”“原候选只结算一次”的实现点。
static uint32_t settlePendingTicketLocked(Session *s, int slot, bool *outImageChanged)
{
    PendingSettlement &p = g_pending[slot];
    if (!p.valid) {
        g_lastSettlementVerdict.store(kSettlementNone);
        return CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE;
    }
    if (p.settled) {
        // 重复结算尝试：不得再次 commit/rollback，也不得再次推进帧号。
        s->ticketDuplicateSettlementCount += 1;
        return p.decision;
    }
    JobPhase phase = p.job ? p.job->phaseSnapshot() : JobPhase::Done;
    if (phase == JobPhase::Committing) {
        g_lastSettlementVerdict.store(kSettlementStillCommitting);
        return CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING;
    }
    CjguiInternalRendererStatus status =
        p.job ? p.job->statusSnapshot() : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (phase == JobPhase::Done && status == CJGUI_INTERNAL_RENDERER_OK) {
        // 唯一一次 commit：native accepted 与命中同时切到该候选。
        const uint64_t oldProjection = s->acceptedProjectionVersion;
        s->accepted.swap(p.nodes);
        s->acceptedProjectionVersion = p.projectionVersion;
        cjguiOhosLogAcceptedImageSwap(*s, p.nodes, oldProjection, p.ticketId, "commit");
        bool imageChanged = reconcileAcceptedImagesLocked(s);
#ifdef CJGUI_OHOS_TEST_GATES
        // D 夹具取证：输出 accepted 节点几何与裁剪框（探针据此计算触摸坐标、
        // 核对裁剪边界）。
        for (const SceneNode &n : s->accepted) {
            RLOGI("node-rect id=%{public}lld x=%{public}lld y=%{public}lld w=%{public}lld h=%{public}lld "
                  "clip=(%{public}lld,%{public}lld,%{public}lld,%{public}lld)",
                  static_cast<long long>(n.pod.nodeId),
                  static_cast<long long>(n.pod.x), static_cast<long long>(n.pod.y),
                  static_cast<long long>(n.pod.width), static_cast<long long>(n.pod.height),
                  static_cast<long long>(n.pod.clipX), static_cast<long long>(n.pod.clipY),
                  static_cast<long long>(n.pod.clipWidth), static_cast<long long>(n.pod.clipHeight));
        }
#endif
        s->candidateOpen = false;
        s->submittedFrameIndex += 1;
        p.frameIndex = s->submittedFrameIndex;
        p.drawableWidth = s->surfaceWidth;
        p.drawableHeight = s->surfaceHeight;
        p.density = s->surfaceDensity;
        p.terminalStatus = CJGUI_INTERNAL_RENDERER_OK;
        p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED;
        p.settled = true;
        p.job = nullptr;
        p.nodes.clear();
        s->ticketAcceptedCount += 1;
        g_committedSettlements.fetch_add(1);
        g_lastSettlementVerdict.store(kSettlementCommitted);
        // A1：延迟成功与同步成功共用收尾，避免漏掉编辑缓冲处理。
        syncEditingBufferAfterAcceptedSceneLocked(s);
        if (outImageChanged) *outImageChanged = imageChanged;
        RLOGI("pending settlement committed ticket=%{public}llu frame=%{public}llu",
              static_cast<unsigned long long>(p.ticketId),
              static_cast<unsigned long long>(s->submittedFrameIndex));
        return p.decision;
    }
    // 唯一一次 rollback：候选丢弃，旧 accepted 保留（画面可能仍是旧帧，
    // 但绝不把未确认的候选当成 accepted）。
    RLOGW("pending settlement aborted ticket=%{public}llu status=%{public}d",
          static_cast<unsigned long long>(p.ticketId), static_cast<int>(status));
    p.job = nullptr;
    p.nodes.clear();
    p.terminalStatus = static_cast<int32_t>(status);
    p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;
    p.settled = true;
    s->ticketRejectedCount += 1;
    g_abortedSettlements.fetch_add(1);
    g_lastSettlementVerdict.store(kSettlementAborted);
    return p.decision;
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(uint64_t session,
                                                         CjguiInternalRendererFrameObservation *outObservation)
{
    if (outObservation) {
        std::memset(outObservation, 0, sizeof(*outObservation));
    }
    // 快照候选 → 投递渲染事务 → 等待明确结果 → 成功才晋升为已接受场景。
    std::vector<SceneNode> nodes;
    uint64_t projectionVersion = 0;
    // A1：本次提交的票据编号。0 = 未登记票据（同步成功，已当场接受）。
    uint64_t ticketId = 0;
    double clearR = 0, clearG = 0, clearB = 0, clearA = 1;
    void *window = nullptr;
    uint64_t gen = 0;
    uint64_t geometryRevision = 0;
    int32_t w = 0, h = 0;
    double density = 1.0;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        if (!s->candidateOpen) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        if (!g_ingress.surfaceActive) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        // A1 票据协议：present 只负责投递新候选，不再承担“顺便结算上一张票据
        // 并可能二次提交”的双重职责。只要本会话还有未 ACK 的票据，就既不结算
        // 也不投递：调用方必须先经 query_present 取得终态、acknowledge_present
        // 确认，再提交新候选。这样原候选只会收到一次 commit/rollback。
        int slot = sessionSlotLocked(session);
        if (slot >= 0 && g_pending[slot].valid) {
            RLOGW("present deferred: unacknowledged ticket=%{public}llu",
                  static_cast<unsigned long long>(g_pending[slot].ticketId));
            if (outObservation) outObservation->ticketId = g_pending[slot].ticketId;
            return static_cast<CjguiInternalRendererStatus>(CJGUI_INTERNAL_RENDERER_PENDING);
        }
        if (g_ingress.surfaceActive(&window, &gen, &w, &h, &density,
                                    &geometryRevision) != 1) {
            // 无 surface：可恢复失败，不接受候选、不推进帧号。
            return CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE;
        }
        nodes = s->candidate;
        projectionVersion = s->candidateProjectionVersion;
        // A1：投递前登记票据。票据身份与候选快照在同一次加锁内取得，因此
        // “候选 → 票据”的对应不会与后来 owner 的改动交错。
        ticketId = s->nextTicketId;
        s->nextTicketId += 1;
        clearR = s->clearR;
        clearG = s->clearG;
        clearB = s->clearB;
        clearA = s->clearA;
    }
    std::shared_ptr<PresentJob> presentJob = std::make_shared<PresentJob>();
    presentJob->session = session;
    presentJob->ticketId = ticketId;
    presentJob->nodes = nodes;
    presentJob->projectionVersion = projectionVersion;
    presentJob->window = window;
    presentJob->generation = gen;
    presentJob->geometryRevision = geometryRevision;
    presentJob->width = w;
    presentJob->height = h;
    presentJob->clearR = clearR;
    presentJob->clearG = clearG;
    presentJob->clearB = clearB;
    presentJob->clearA = clearA;
    JobRef job = presentJob;   // 队列/等待者共享同一所有权
    g_render.post(job);
    cjguiOhosScheduleUnpostedImages();
    CjguiInternalRendererStatus result = job->waitFor();
    if (result == static_cast<CjguiInternalRendererStatus>(CJGUI_INTERNAL_RENDERER_PENDING)) {
        // 提交未定：把原票据与候选身份交给 session 的结算槽（共享所有权，
        // 调用方超时不再意味着对象被释放）。owner 在下一次 present 时结算，
        // 或由 pump 的结算查询取得终态，一次性 commit/rollback。
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        int slot = sessionSlotLocked(session);
        if (s && slot >= 0) {
            PendingSettlement &p = g_pending[slot];
            p.job = job;
            p.nodes = nodes;
            p.projectionVersion = projectionVersion;
            p.ticketId = ticketId;
            p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING;
            p.terminalStatus = 0;
            p.frameIndex = 0;
            p.settled = false;
            p.valid = true;
            s->unackedTicketId = ticketId;
        }
        if (outObservation) outObservation->ticketId = ticketId;
        RLOGW("present pending ticket=%{public}llu (committing timeout)",
              static_cast<unsigned long long>(ticketId));
        return result;
    }
    if (result != CJGUI_INTERNAL_RENDERER_OK) {
        RLOGW("present terminal session=%{public}llu ticket=%{public}llu status=%{public}d phase=%{public}d",
              static_cast<unsigned long long>(session), static_cast<unsigned long long>(ticketId),
              static_cast<int>(result), static_cast<int>(job->phaseSnapshot()));
        nodes.clear();
        job.reset();
        presentJob.reset();
        cjguiOhosPruneReleasedImages();
        return result;
    }
    bool imageChanged = false;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        const uint64_t oldProjection = s->acceptedProjectionVersion;
        s->accepted.swap(nodes);
        s->acceptedProjectionVersion = projectionVersion;
        cjguiOhosLogAcceptedImageSwap(*s, nodes, oldProjection, ticketId, "commit");
        imageChanged = reconcileAcceptedImagesLocked(s);
#ifdef CJGUI_OHOS_TEST_GATES
        // D 夹具取证：同步 settle 路径的 accepted 几何（与 PENDING-settle 路径
        // 同格式，resize 后几何采样两条路径都能取到）。
        for (const SceneNode &n : s->accepted) {
            RLOGI("node-rect id=%{public}lld x=%{public}lld y=%{public}lld w=%{public}lld h=%{public}lld "
                  "clip=(%{public}lld,%{public}lld,%{public}lld,%{public}lld)",
                  static_cast<long long>(n.pod.nodeId),
                  static_cast<long long>(n.pod.x), static_cast<long long>(n.pod.y),
                  static_cast<long long>(n.pod.width), static_cast<long long>(n.pod.height),
                  static_cast<long long>(n.pod.clipX), static_cast<long long>(n.pod.clipY),
                  static_cast<long long>(n.pod.clipWidth), static_cast<long long>(n.pod.clipHeight));
        }
#endif
        // 诊断：本帧各节点的投影 label/value（分离打印，便于定位渲染空值）
        for (const SceneNode &n : s->accepted) {
            RLOGI("accepted node=%{public}lld kind=%{public}u label=%{public}s value=%{public}s v=%{public}llu",
                  static_cast<long long>(n.pod.nodeId), n.pod.nodeKind, n.label.c_str(), n.value.c_str(),
                  static_cast<unsigned long long>(n.pod.projectionVersion));
        }
        s->candidateOpen = false;
        s->submittedFrameIndex += 1;
        // A1：同步成功与延迟成功（票据结算）共用同一条收尾，避免两条路径分叉。
        syncEditingBufferAfterAcceptedSceneLocked(s);
        cjguiOhosObserveSurfaceLocked(s, gen, geometryRevision, w, h, density);
        if (outObservation) {
            // flush 成功 = 提交成功；GPU 完成观察在 OHOS 路径不可得，保持 0。
            outObservation->frameIndex = s->submittedFrameIndex;
            outObservation->drawableWidthPixels = static_cast<uint32_t>(w);
            outObservation->drawableHeightPixels = static_cast<uint32_t>(h);
            outObservation->contentsScale = density;
            outObservation->readbackAttempted = 0;
            outObservation->readbackCompleted = 0;
            outObservation->readbackColorMatched = 0;
        }
    }
    const int terminalPhase = static_cast<int>(job->phaseSnapshot());
    // The successful swap leaves the former accepted scene in this local
    // vector. Release it and both waiter aliases before idle-cache pruning;
    // the renderer epilogue covers the opposite waiter/renderer ordering.
    nodes.clear();
    job.reset();
    presentJob.reset();
    cjguiOhosPruneReleasedImages();
    if (imageChanged) g_render.postIfRunning(std::make_shared<RedrawJob>());
    cjguiOhosLogImageSnapshot("frame");
    RLOGI("present terminal session=%{public}llu ticket=%{public}llu status=0 phase=%{public}d",
              static_cast<unsigned long long>(session), static_cast<unsigned long long>(ticketId),
              terminalPhase);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// A1 票据协议：查询原提交。只读终态，不做 configure、不 build、不创建新 job、
// 不 Flush。终态写入后固定，重复查询返回同一结果。
CjguiInternalRendererStatus cjgui_internal_renderer_query_present(
    uint64_t session, uint64_t ticketId, CjguiInternalRendererPresentReceipt *outReceipt)
{
    if (outReceipt) std::memset(outReceipt, 0, sizeof(*outReceipt));
    if (ticketId == 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::unique_lock<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    int slot = sessionSlotLocked(session);
    if (slot < 0) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->ticketQueryCount += 1;
    PendingSettlement &p = g_pending[slot];
    if (!p.valid || p.ticketId != ticketId) {
        // 该会话没有这张票据（已 ACK、从未登记、或身份不符）。调用方本地仍
        // 持有该 ticket 时这是协议缺口，必须按缺口处理，不得当成拒绝。
        if (outReceipt) {
            outReceipt->ticketId = ticketId;
            outReceipt->decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE;
        }
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    bool imageChanged = false;
    uint32_t decision = settlePendingTicketLocked(s, slot, &imageChanged);
    if (outReceipt) {
        outReceipt->ticketId = p.ticketId;
        outReceipt->projectionVersion = p.projectionVersion;
        outReceipt->decision = decision;
        outReceipt->terminalStatus = p.terminalStatus;
        outReceipt->settled = p.settled ? 1 : 0;
        // 画面可能与刚提交的候选分离（Rejected）：核心需要安排一次重新同步。
        outReceipt->resyncRequired =
            (decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED) ? 1 : 0;
        if (decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) {
            outReceipt->observation.frameIndex = p.frameIndex;
            outReceipt->observation.drawableWidthPixels = static_cast<uint32_t>(p.drawableWidth);
            outReceipt->observation.drawableHeightPixels = static_cast<uint32_t>(p.drawableHeight);
            outReceipt->observation.contentsScale = p.density;
            outReceipt->observation.readbackAttempted = 0;
            outReceipt->observation.readbackCompleted = 0;
            outReceipt->observation.readbackColorMatched = 0;
        }
    }
    g.unlock();
    // Terminal pending settlement has released p.job/p.nodes. Rejected
    // candidates still owned by s->candidate remain protected by use_count.
    if (decision != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING) {
        cjguiOhosPruneReleasedImages();
    }
    if (imageChanged) g_render.postIfRunning(std::make_shared<RedrawJob>());
    if (decision == CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) {
        cjguiOhosLogImageSnapshot("frame");
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

// A1 票据协议：确认回执。幂等；只回收回执并开放下一次提交，不再推进帧号，
// 不改变已接受的场景。
CjguiInternalRendererStatus cjgui_internal_renderer_acknowledge_present(uint64_t session,
                                                                        uint64_t ticketId)
{
    if (ticketId == 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    int slot = sessionSlotLocked(session);
    if (slot < 0) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    s->ticketAckCount += 1;
    PendingSettlement &p = g_pending[slot];
    if (!p.valid || p.ticketId != ticketId) {
        // 幂等：重复 ACK（或 ACK 一张已回收的票）成功返回，不推进帧号。
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (!p.settled) {
        // 未结算就 ACK 会丢掉唯一的裁决点：拒绝，要求先 query。
        RLOGW("acknowledge refused: ticket=%{public}llu not settled",
              static_cast<unsigned long long>(ticketId));
        return CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED;
    }
#ifdef CJGUI_OHOS_TEST_GATES
    // A1 注入：ACK 失败——核心保留已结算事务并重试原 ACK（不得开放新候选）。
    if (cjguiOhosTestGateConsumeFailNextAck()) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
#endif
    p.job = nullptr;
    p.nodes.clear();
    p.valid = false;
    p.settled = false;
    p.ticketId = 0;
    p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING;
    p.terminalStatus = 0;
    p.frameIndex = 0;
    if (s->unackedTicketId == ticketId) s->unackedTicketId = 0;
    RLOGI("present ticket acknowledged id=%{public}llu", static_cast<unsigned long long>(ticketId));
    return CJGUI_INTERNAL_RENDERER_OK;
}

// A1 取证：生产结算点的 committed/aborted 计数（全进程累计）。
extern "C" int32_t cjgui_ohos_test_settlement_committed(void)
{
    return static_cast<int32_t>(g_committedSettlements.load());
}

extern "C" int32_t cjgui_ohos_test_settlement_aborted(void)
{
    return static_cast<int32_t>(g_abortedSettlements.load());
}

// A1 取证计数（见 cjgui_internal_renderer.h 的字段说明）。
CjguiInternalRendererStatus cjgui_internal_renderer_present_ticket_stats(
    uint64_t session, CjguiInternalRendererPresentTicketStats *out)
{
    if (!out) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::memset(out, 0, sizeof(*out));
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    out->nextTicketId = static_cast<int64_t>(s->nextTicketId);
    out->unackedTicketId = static_cast<int64_t>(s->unackedTicketId);
    out->acceptedCount = s->ticketAcceptedCount;
    out->rejectedCount = s->ticketRejectedCount;
    out->queryCount = s->ticketQueryCount;
    out->ackCount = s->ticketAckCount;
    out->duplicateSettlementCount = s->ticketDuplicateSettlementCount;
    out->destroyRefusedCount = s->ticketDestroyRefusedCount;
    out->available = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_present_clear(uint64_t session, const CjguiInternalRendererClearColor *color,
                                              CjguiInternalRendererFrameObservation *outObservation)
{
    if (!color) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // 阶段1由 present 路径统一处理清屏色；直接确认可清（无候选状态影响）。
    (void)session;
    if (outObservation) {
        std::memset(outObservation, 0, sizeof(*outObservation));
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_node_rect(uint64_t session, uint64_t nodeId, int64_t *outX, int64_t *outY,
                                          int64_t *outWidth, int64_t *outHeight)
{
    if (!outX || !outY || !outWidth || !outHeight) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    for (const SceneNode &n : s->accepted) {
        if (n.pod.nodeId == nodeId) {
            *outX = n.pod.x;
            *outY = n.pod.y;
            *outWidth = n.pod.width;
            *outHeight = n.pod.height;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
    }
    return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_display_progress(uint64_t session,
                                                            CjguiInternalRendererComposableDisplayProgress *outProgress)
{
    if (!outProgress) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    outProgress->submittedFrameIndex = s->submittedFrameIndex;
    // OHOS 路径无异步 Metal 完成观察：保持 0 / -1，不伪造。
    outProgress->observedMetalCompletionFrameIndex = 0;
    outProgress->observedMetalFailureFrameIndex = 0;
    outProgress->observedMetalGpuDurationMicros = -1;
    outProgress->overlayDrawnProjectionVersion = 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 命令菜单 / 数据传输：空配置成功（清除语义），非空显式不支持。
CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_command_menu(uint64_t session,
                                                                  uint64_t projectionVersion,
                                                                  uint32_t itemCount)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)projectionVersion;
    if (itemCount != 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_command_menu_item(uint64_t session, uint32_t itemIndex,
                                                                 const char *commandId, const char *title,
                                                                 const char *menuGroup, const char *shortcut,
                                                                 uint32_t menuSection, uint64_t focusScope,
                                                                 uint8_t enabled, uint8_t checked)
{
    (void)session; (void)itemIndex; (void)commandId; (void)title; (void)menuGroup; (void)shortcut;
    (void)menuSection; (void)focusScope; (void)enabled; (void)checked;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus cjgui_internal_renderer_commit_composable_command_menu(uint64_t session)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_data_transfer(uint64_t session,
                                                                   uint64_t projectionVersion,
                                                                   uint32_t itemCount)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)projectionVersion;
    if (itemCount != 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_data_transfer_item(uint64_t session, uint32_t itemIndex,
                                                                  const CjguiInternalRendererComposableDataTransferItem *item,
                                                                  const char *format, const char *payload,
                                                                  const char *sourceKind, const char *sourceIdentity)
{
    (void)session; (void)itemIndex; (void)item; (void)format; (void)payload; (void)sourceKind; (void)sourceIdentity;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus cjgui_internal_renderer_prepare_composable_image_resource(uint64_t session, const char *resourcePath,
                                                                  const char *resourceId, uint64_t resourceVersion,
                                                                  uint32_t *outState)
{
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererStatus status;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        status = cjguiOhosImageAccessNoThrow(resourcePath, resourceId, resourceVersion,
                                 true, true, nullptr, outState);
    }
    cjguiOhosScheduleUnpostedImages();
    return status;
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_image_resource_state(uint64_t session, const char *resourcePath,
                                                                const char *resourceId, uint64_t resourceVersion,
                                                                uint32_t *outState)
{
    if (!outState) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return cjguiOhosImageAccessNoThrow(resourcePath, resourceId, resourceVersion,
                           false, false, nullptr, outState);
}

static CjguiInternalRendererStatus focusComposableNodeLocked(Session &s, uint64_t nodeId,
                                                            bool checkBindingEpoch, uint64_t expectedBindingEpoch)
{
    RLOGI("focus api enter node=%{public}llu accepted=%{public}zu",
          static_cast<unsigned long long>(nodeId), s.accepted.size());
    if (nodeId == 0) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    for (const SceneNode &node : s.accepted) {
        if (node.pod.nodeId != nodeId) continue;
        const uint32_t kind = node.pod.nodeKind;
        const bool editable = kind == kKindTextInput || kind == kKindIntegerInput;
        if (!editable || node.pod.isReadOnly != 0 || node.pod.isInteractive == 0) {
            return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
        }
        const auto &n = node.pod;
        // The Cangjie caller names the accepted binding it resolved. An ABA
        // replacement may reuse the numeric node id and every visible string.
        // The legacy two-argument entry remains available to older consumers.
        if (checkBindingEpoch && (expectedBindingEpoch == 0 || n.acceptedBindingEpoch == 0 ||
                                  n.acceptedBindingEpoch != expectedBindingEpoch)) {
            return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
        }
        if (n.width <= 0 || n.height <= 0) {
            return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
        }
        // Match the renderer's active rectangle chain: 1..4 original clips,
        // otherwise the inherited legacy clip. Any empty intersection means
        // no editor may be started, even when core geometry was valid earlier.
        __int128 left = n.x;
        __int128 top = n.y;
        __int128 right = left + n.width;
        __int128 bottom = top + n.height;
        auto intersectClip = [&](int64_t x, int64_t y, int64_t width, int64_t height) {
            if (width <= 0 || height <= 0) return false;
            const __int128 clipLeft = x;
            const __int128 clipTop = y;
            const __int128 clipRight = clipLeft + width;
            const __int128 clipBottom = clipTop + height;
            left = std::max(left, clipLeft);
            top = std::max(top, clipTop);
            right = std::min(right, clipRight);
            bottom = std::min(bottom, clipBottom);
            return left < right && top < bottom;
        };
        bool visible = true;
        if (n.clipConstraintCount >= 1u && n.clipConstraintCount <= 4u) {
            visible = intersectClip(n.clip0X, n.clip0Y, n.clip0Width, n.clip0Height);
            if (visible && n.clipConstraintCount > 1u) {
                visible = intersectClip(n.clip1X, n.clip1Y, n.clip1Width, n.clip1Height);
            }
            if (visible && n.clipConstraintCount > 2u) {
                visible = intersectClip(n.clip2X, n.clip2Y, n.clip2Width, n.clip2Height);
            }
            if (visible && n.clipConstraintCount > 3u) {
                visible = intersectClip(n.clip3X, n.clip3Y, n.clip3Width, n.clip3Height);
            }
        } else {
            visible = intersectClip(n.clipX, n.clipY, n.clipWidth, n.clipHeight);
        }
        if (!visible) {
            return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
        }
        // Core owns reveal and retries after a new accepted scene. No focus
        // event is returned for this programmatic request, preventing a loop.
        beginEditingOnNodeLocked(s, node);
        RLOGI("platform focus node=%{public}llu ctx=%{public}lld field=%{public}s",
              static_cast<unsigned long long>(nodeId),
              static_cast<long long>(s.editingContextId), s.editingFieldName.c_str());
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
}

CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(uint64_t session, uint64_t nodeId)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return focusComposableNodeLocked(*s, nodeId, false, 0);
}

CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node_checked(
    uint64_t session, uint64_t nodeId, uint64_t expectedBindingEpoch)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return focusComposableNodeLocked(*s, nodeId, true, expectedBindingEpoch);
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture(uint64_t session)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // B/C：取消 capture 的实际行为——终结当前触摸手势（不激活、不结算），
    // 长按计时一并清除；正在进行的编辑上下文不受影响。
    cancelTouchGestureLocked(*s);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
    uint64_t session, uint64_t appInstance, uint64_t componentInstance,
    uint64_t surfaceGeneration, int64_t pointerId, uint64_t gestureEpoch)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (appInstance == 0 || componentInstance == 0 || surfaceGeneration == 0 ||
        pointerId < 0 || gestureEpoch == 0) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    const Session::TouchGesture &active = s->gesture;
    if (active.active && active.appInstance == appInstance &&
        active.componentInstance == componentInstance &&
        active.surfaceGeneration == surfaceGeneration &&
        active.pointerId == pointerId && active.gestureEpoch == gestureEpoch) {
        cancelTouchGestureLocked(*s);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

// shared-operation 呈现覆盖层：存储元数据（阶段1无视觉覆盖层）。
CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_operation(uint64_t session, uint32_t visibleRecordCount)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)visibleRecordCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_operation_title(uint64_t session,
                                                                                uint32_t recordIndex,
                                                                                const char *title)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)recordIndex; (void)title;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_operation_state(uint64_t session,
                                                           const CjguiInternalRendererSharedOperationState *state)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)state;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_form(uint64_t session, uint32_t fieldCount)
{
    (void)session; (void)fieldCount;
    return CJGUI_INTERNAL_RENDERER_OK;  // 旧表单呈现入口：本包核心路径不使用
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_shared_collection_form(
    uint64_t session, uint32_t fieldCount, uint32_t visibleRecordCount)
{
    (void)session; (void)fieldCount; (void)visibleRecordCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_collection_row(
    uint64_t session, uint32_t rowIndex, const char *title, uint8_t isSelected,
    uint32_t viewportStart, uint32_t totalRecordCount)
{
    (void)session; (void)rowIndex; (void)title; (void)isSelected;
    (void)viewportStart; (void)totalRecordCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_collection_filter(uint64_t session,
                                                      const char *filterText)
{
    (void)session; (void)filterText;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_form_field(
    uint64_t session, uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd)
{
    (void)session; (void)fieldIndex; (void)label; (void)draftText; (void)validationError;
    (void)editorKind; (void)isFocused; (void)selectionStart; (void)selectionEnd;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_shared_form_status(uint64_t session, const char *status)
{
    (void)session; (void)status;
    return CJGUI_INTERNAL_RENDERER_OK;
}

const char *cjgui_internal_renderer_form_event_text(uint64_t session)
{
    // 生命周期与 macOS 一致：返回最近一次 pump 出的事件文本，下一次 pump 覆盖。
    static std::string storage;  // ABI 返回 const char*；单调用方（仓颉循环）串行访问
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return "";
    storage = s->lastEventText;
    return storage.c_str();
}

const char *cjgui_internal_renderer_data_transfer_event_format(uint64_t session)
{
    (void)session;
    return "";
}

const char *cjgui_internal_renderer_data_transfer_event_source_kind(uint64_t session)
{
    (void)session;
    return "";
}

const char *cjgui_internal_renderer_data_transfer_event_source_identity(uint64_t session)
{
    (void)session;
    return "";
}

int64_t cjgui_internal_renderer_data_transfer_event_source_id(uint64_t session)
{
    (void)session;
    return -1;
}

// ---------------------------------------------------------------------------
// ABI：事件泵
// ---------------------------------------------------------------------------

CjguiInternalRendererStatus cjgui_internal_renderer_pump_event(uint64_t session, uint32_t timeoutMs,
                                           CjguiInternalRendererEvent *outEvent)
{
    if (!outEvent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::memset(outEvent, 0, sizeof(*outEvent));
    outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_NONE;

    // 1) 吸收 ingress 的原始触摸并按已接受场景合成意图（带完整身份）。
    // 2) 队首事件出队；空则等待（condvar 上限 16ms，保证 owner 及时拿回控制）。
    static std::mutex pumpMutex;  // pump 串行化（单一仓颉循环调用方）
    std::lock_guard<std::mutex> pumpGuard(pumpMutex);

    Session *s = nullptr;
    auto drainTouches = [&s]()
    {
        // 调用方必须已持有 g_sessions.lock（合成只触碰会话内状态）。
        if (!g_ingress.touchDequeueEx) return;
        for (int drained = 0; drained < 64; ++drained) {
            RawTouchSample sample{};
            sample.pointerId = -1;
            int rc = g_ingress.touchDequeueEx(&sample.action, &sample.x, &sample.y,
                &sample.appInstance, &sample.componentInstance,
                &sample.surfaceGeneration, &sample.pointerId, &sample.gestureEpoch,
                &sample.timestampNs, &sample.timeSource);
            if (rc != 1) break;  // 0 空 / -1 旧代已丢弃
            RLOGI("raw touch action=%{public}u x=%{public}.0f y=%{public}.0f ep=%{public}llu",
                  sample.action, sample.x, sample.y, static_cast<unsigned long long>(sample.gestureEpoch));
            // B（复核修）：坐标域统一——XComponent 回调给物理 px，核心投影
            // 的 accepted 节点是布局 vp；在此一次性除以 surfaceDensity（只在
            // 此处转换，其余路径不再二次转换）。
            if (s->surfaceDensity > 0.0 && s->surfaceDensity != 1.0) {
                sample.x = static_cast<float>(sample.x / s->surfaceDensity);
                sample.y = static_cast<float>(sample.y / s->surfaceDensity);
            }
            synthesizeEventsFromRawTouch(*s, sample);
        }
    };

    std::unique_lock<std::mutex> g(g_sessions.lock);
    s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 应用停止协议：优先于一切输入/等待（Sol 关闭链第 2 步）
    if (g_applicationStopRequested.load()) {
        outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_CLOSE_REQUESTED;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    drainTouches();
    if (s->events.empty()) {
        uint32_t clamped = std::min(timeoutMs, static_cast<uint32_t>(kPumpWaitMax.count()));
        if (clamped > 0) {
            // bounded sleep（阶段1事件源频率低，16ms 粒度足够）；
            // 睡醒后在锁内吸收可能新到的触摸。
            g.unlock();
            struct timespec ts;
            ts.tv_sec = 0;
            ts.tv_nsec = static_cast<long>(clamped) * 1000000L;
            nanosleep(&ts, nullptr);
            g.lock();
            drainTouches();
        }
    }
    // 锁外处理：caret 命中（渲染线程测量）与 IME attach/detach（服务调用）。
    if (s->editingTapPending) {
        s->editingTapPending = false;
        uint64_t nodeId = s->editingNodeId;
        double tapX = s->editingTapX;
        std::u16string composed;
        double fontSize = 13.0;
        uint32_t fontWeight = 400;
        double nodeWidth = 0.0;
        for (const SceneNode &n : s->accepted) {
            if (n.pod.nodeId == nodeId) {
                composed = composedBuffer(*s);
                fontSize = n.pod.fontSize;
                fontWeight = n.pod.fontWeight;
                nodeWidth = static_cast<double>(n.pod.width);
                break;
            }
        }
        if (!composed.empty() && nodeWidth > 0.0) {
            g.unlock();
            CaretHitTestJob *job = new CaretHitTestJob();
            job->text = composed;
            job->fontSize = fontSize;
            job->fontWeight = fontWeight;
            job->nodeWidth = nodeWidth;
            job->tapX = std::max(0.0, tapX - 7.0);  // 与绘制 inset 一致
            JobRef jobRef(job);
            g_render.post(jobRef);
            uint32_t caret = 0;
            CjguiInternalRendererStatus waited = job->waitFor();
            bool caretOk = waited == CJGUI_INTERNAL_RENDERER_OK;
            if (caretOk) {
                caret = job->caretUtf16;
            } else {
                // 测量失败/超时：不改光标与选区（不把未测出的位置当命中结果）。
                RLOGW("caret hit test failed status=%{public}d window=%{public}d",
                      static_cast<int>(waited), static_cast<int>(kCaretHitTestFailureWindow));
                kCaretHitTestFailureWindow += 1;
            }
            g.lock();
            // 复核：等待期间编辑目标未被替换
            if (caretOk && s->editing && s->editingNodeId == nodeId) {
                s->caretUtf16 = std::min(caret, static_cast<uint32_t>(s->editingText.size()));
                s->selStartUtf16 = s->caretUtf16;
                s->selEndUtf16 = s->caretUtf16;
            }
        }
    }
    if (s->focusNotifyPending) {
        s->focusNotifyPending = false;
        void (*sink)(const char *) = g_focusRequestSink;
        // 焦点请求带不透明上下文编号：平台侧不解释字段名与几何，
        // 只把编号原样带回；几何与初值由平台按上下文快照查询。
        std::string payload = "{\"action\":\"focus\",\"context\":" + std::to_string(s->editingContextId);
        payload += ",\"field\":\"";
        appendJsonEscaped(payload, s->editingFieldName);
        payload += "\"}";
        g.unlock();
        if (sink) sink(payload.c_str());
        g.lock();
    }
    if (s->reconcileNotifyPending) {
        void (*sink)(const char *) = g_focusRequestSink;
        if (sink) {
            int64_t oldContext = s->reconcileOldContextId;
            int64_t newContext = s->editingContextId;
            std::string payload = "{\"action\":\"reconcile\",\"oldContext\":" +
                std::to_string(oldContext) + ",\"context\":" + std::to_string(newContext);
            payload += ",\"field\":\"";
            appendJsonEscaped(payload, s->editingFieldName);
            payload += "\"}";
            s->reconcileNotifyPending = false;
            s->reconcileOldContextId = 0;
            RLOGI("ime reconcile notification old=%{public}lld new=%{public}lld",
                  static_cast<long long>(oldContext), static_cast<long long>(newContext));
            g.unlock();
            sink(payload.c_str());
            g.lock();
        }
    }
    if (s->pendingImeDetach) {
        s->pendingImeDetach = false;
        // 框架主动结束编辑（点到别处/空白）先做一次失焦结算：把用户已看见的
        // 组合预览折进编辑缓冲并交付 owner。平台 finish 触发的 detach 不带此位，
        // 因为值已经由平台的提交路径写入，再结算就是重复写。
        if (s->pendingSettleOnDetach) {
            bool settled = settleComposedBufferOnBlurLocked(*s);
            s->pendingSettleOnDetach = false;
            std::string settledText = utf16ToUtf8(s->editingText);
            RLOGI("ime blur settle ctx=%{public}lld settled=%{public}d node=%{public}lld text=%{public}s",
                  static_cast<long long>(s->editingContextId), settled ? 1 : 0,
                  static_cast<long long>(s->editingNodeId), settledText.c_str());
        }
        void (*sink)(const char *) = g_focusRequestSink;
        // 结束通知（与 focus 成对）：框架侧结束编辑（点到别的控件/换绑/节点移除）
        // 时，平台代理必须同步收场，否则代理会带着已被回收的上下文继续持有
        // 焦点与系统键盘（实测：点空白处结束编辑后键盘不收起）。
        // 跨字段切换时身份在切换点捕获（detachContextId/detachFieldName），
        // 不得读新上下文字段；普通结束（空白/退役）两者为空，取当前值。
        const int64_t endContextId = s->detachContextId != 0
            ? s->detachContextId : s->editingContextId;
        const std::string endFieldName = !s->detachFieldName.empty()
            ? s->detachFieldName : s->editingFieldName;
        s->detachContextId = 0;
        s->detachFieldName.clear();
        std::string payload = "{\"action\":\"end\",\"context\":" + std::to_string(endContextId);
        payload += ",\"field\":\"";
        appendJsonEscaped(payload, endFieldName);
        payload += "\"}";
        g.unlock();
        imeDetach();
        if (sink) sink(payload.c_str());
        g.lock();
    }
    if (s->events.empty()) {
        outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    QueuedEvent ev = s->events.front();
    s->events.pop_front();
    outEvent->kind = ev.kind;
    outEvent->recordIndex = ev.recordIndex;
    outEvent->selectionStart = ev.selectionStart;
    outEvent->selectionEnd = ev.selectionEnd;
    outEvent->nodeId = ev.nodeId;
    outEvent->projectionVersion = ev.projectionVersion;
    outEvent->resourceId = ev.resourceId;
    outEvent->nodeKind = ev.nodeKind;
    outEvent->pointerX = ev.pointerX;
    outEvent->pointerY = ev.pointerY;
    outEvent->modifierFlags = 0;
    outEvent->gestureAppInstance = ev.appInstance;
    outEvent->gestureComponentInstance = ev.componentInstance;
    outEvent->gestureSurfaceGeneration = ev.surfaceGeneration;
    outEvent->gesturePointerId = ev.pointerId;
    outEvent->gestureEpoch = ev.gestureEpoch;
    outEvent->acceptedBindingEpoch = ev.acceptedBindingEpoch;
    s->lastEventText = ev.text;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------------------
// 宿主启动入口：entry 桥经 dlsym 调用（原始 @C）
// ---------------------------------------------------------------------------

int32_t cjgui_ohos_app_main(const CjguiOhosIngress *ingress);

// 由仓颉侧实现（ohos_app.cj 导出）：保存 ingress 并 spawn 仓颉应用循环。
int32_t cjgui_ohos_app_main_cangjie(const CjguiOhosIngress *ingress);

int32_t cjgui_ohos_app_main(const CjguiOhosIngress *ingress)
{
    if (!ingress) return -1;
    g_ingress = *ingress;
    RLOGI("ingress registered; starting cangjie app loop");
    return cjgui_ohos_app_main_cangjie(ingress);
}

// Short-lived owner-entry diagnostic: the Cangjie @C entry can call this
// before println, making its actual execution visible in native hilog.
extern "C" void cjgui_ohos_trace_mark(int32_t code)
{
    RLOGI("owner trace marker code=%{public}d", code);
}

// ingress 观察：仓颉宿主在启动窗口会话前轮询（宿主须等到 surface Ready）。
uint8_t cjgui_ohos_surface_ready(void)
{
    if (!g_ingress.surfaceActive) return 0;
    void *window = nullptr;
    uint64_t generation = 0;
    int32_t w = 0, h = 0;
    double density = 1.0;
    return g_ingress.surfaceActive(&window, &generation, &w, &h, &density,
                                   nullptr) == 1 ? 1u : 0u;
}


// ---------------------------------------------------------------------------
// 通用系统文字代理（ArkTS TextInput 代理路径）
//
// 后端不硬编码字段名与几何：编辑上下文由目标控件的 accepted 节点决定，
// 平台代理经 napi 取回上下文快照（几何/初值/选区/上下文编号），每次
// 回调必须携带该编号；不匹配的回调被拒绝且不改写任何编辑状态。
// ---------------------------------------------------------------------------

// 追加 JSON 字符串转义（上下文里的字段名/初值可能含引号与多字节字符）。
static void appendJsonEscaped(std::string &out, const std::string &value)
{
    for (size_t i = 0; i < value.size(); ++i) {
        unsigned char c = static_cast<unsigned char>(value[i]);
        switch (c) {
            case '"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (c < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out += static_cast<char>(c);
                }
        }
    }
}

// 当前编辑上下文快照。返回 0 = 无有效上下文；非 0 = 已写入 JSON。
// 平台代理据此初始化：值取自 accepted（不是空串）、几何取自 accepted bounds、
// 密度取自 surface 事实。名称/业务字段不进后端硬编码。
extern "C" int32_t ohos_renderer_ime_context_json(char *out, int32_t capacity)
{
    if (!out || capacity <= 0) return 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) {
        RLOGW("ime context query rejected: no editing session");
        return 0;
    }
    if (!s->editingContextLive) {
        RLOGW("ime context query rejected: context not live ctx=%{public}lld editing=%{public}d",
              static_cast<long long>(s->editingContextId), s->editing ? 1 : 0);
        return 0;
    }
    int64_t x = 0, y = 0, w = 0, h = 0;
    double fontSize = 13.0;
    bool found = false;
    for (const SceneNode &n : s->accepted) {
        if (n.pod.nodeId == s->editingNodeId && n.pod.resourceId == s->editingResourceId &&
            n.pod.nodeKind == s->editingNodeKind && n.semanticId == s->editingFieldName &&
            n.pod.isReadOnly == 0 && n.pod.isInteractive != 0) {
            x = n.pod.x;
            y = n.pod.y;
            w = n.pod.width;
            h = n.pod.height;
            fontSize = n.pod.fontSize;
            found = true;
            break;
        }
    }
    if (!found) {
        RLOGW("ime context query: node missing node=%{public}lld res=%{public}u accepted=%{public}zu",
              static_cast<long long>(s->editingNodeId),
              static_cast<unsigned>(s->editingResourceId), s->accepted.size());
        return 0;
    }
    std::string json = "{\"context\":";
    json += std::to_string(s->editingContextId);
    json += ",\"field\":\"";
    appendJsonEscaped(json, s->editingFieldName);
    json += "\",\"nodeId\":" + std::to_string(s->editingNodeId);
    json += ",\"x\":" + std::to_string(x);
    json += ",\"y\":" + std::to_string(y);
    json += ",\"width\":" + std::to_string(w);
    json += ",\"height\":" + std::to_string(h);
    json += ",\"fontSize\":" + std::to_string(static_cast<int>(fontSize + 0.5));
    json += ",\"density\":" + std::to_string(s->surfaceDensity);
    json += ",\"selStart\":" + std::to_string(s->selStartUtf16);
    json += ",\"selEnd\":" + std::to_string(s->selEndUtf16);
    json += ",\"generation\":" + std::to_string(s->editingContextGeneration);
    json += ",\"baseVersion\":" + std::to_string(s->editingContextBaseVersion);
    json += ",\"sessionToken\":" + std::to_string(s->token);
    json += ",\"mode\":\"immediate\"";
    json += ",\"inputCapabilities\":{\"fullDraft\":\"available\",\"selectionUtf16\":\"available\",";
    json += "\"markedRange\":\"callback_conditional\",\"markedRangeObserved\":";
    json += (s->markedCallbackObserved ? "true" : "false");
    json += ",\"cancelEvent\":\"not_observed\"}";
    if (s->previewActive) {
        json += ",\"previewStart\":" + std::to_string(s->previewStart);
        json += ",\"previewEnd\":" + std::to_string(s->previewEnd);
        json += ",\"previewText\":\"";
        appendJsonEscaped(json, utf16ToUtf8(s->previewText));
        json += "\"";
        if (s->markedActive) {
            json += ",\"markedStart\":" + std::to_string(s->markedStart);
            json += ",\"markedEnd\":" + std::to_string(s->markedEnd);
        }
    }
    json += ",\"text\":\"";
    appendJsonEscaped(json, utf16ToUtf8(s->editingText));
    json += "\"}";
    if (static_cast<int32_t>(json.size()) + 1 > capacity) {
        RLOGW("ime context query rejected: json too long size=%{public}zu capacity=%{public}d",
              json.size(), capacity);
        return 0;
    }
    std::memcpy(out, json.c_str(), json.size() + 1);
    return 1;
}

// 校验回调携带的上下文：只接受当前活上下文的编号。
// 返回 nullptr = 上下文已失效（旧焦点/换绑/重建/关闭后的旧回调）。
static Session *takeEditingContextLocked(int64_t contextId)
{
    Session *s = findEditingSessionLocked();
    if (!s || !s->editingContextLive) return nullptr;
    if (contextId != s->editingContextId) return nullptr;
    return s;
}

// 普通编辑变化（提交）：一次结算。返回 0 = 已应用，1 = 上下文失效被拒。
extern "C" int32_t ohos_renderer_ime_commit_text_ctx(const char *text, size_t length, int64_t contextId)
{
    std::string input(text ? text : "", text ? length : 0);
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = takeEditingContextLocked(contextId);
    if (!s) {
        RLOGW("ime commit rejected: stale context=%{public}lld", static_cast<long long>(contextId));
        return 1;
    }
    RLOGI("ime commit len=%{public}zu ctx=%{public}lld", length, static_cast<long long>(contextId));
    s->editingText = utf8ToUtf16(input);
    s->caretUtf16 = static_cast<uint32_t>(s->editingText.size());
    s->selStartUtf16 = s->caretUtf16;
    s->selEndUtf16 = s->caretUtf16;
    s->previewActive = false;
    s->previewText.clear();
    s->markedActive = false;
    editorEnqueueTextChanged(*s);
    return 0;
}

// 组合/编辑预览：仅视觉投影，不进 owner。返回 0 = 已接受，1 = 上下文失效。
extern "C" int32_t ohos_renderer_ime_preview_text_ctx(const char *text, size_t length, int64_t contextId)
{
    std::string input(text ? text : "", text ? length : 0);
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = takeEditingContextLocked(contextId);
        if (!s) {
            RLOGW("ime preview rejected: stale context=%{public}lld", static_cast<long long>(contextId));
            return 1;
        }
        s->previewText = utf8ToUtf16(input);
        s->previewStart = 0;
        s->previewEnd = static_cast<uint32_t>(s->editingText.size());
        s->previewActive = true;
        s->markedActive = false;
        s->caretUtf16 = static_cast<uint32_t>(s->previewText.size());
    }
    g_render.post(std::make_shared<RedrawJob>());
    return 0;
}

// 全文草稿 + 可选 marked 区间。ArkUI 的 offset 属于显示全文的 UTF-16 坐标；
// 它不是旧 owner 正文的替换范围。全文始终只作为视觉预览，marked 元数据
// 单独记录，缺失/无效时仍可保留全文草稿而不推断取消。
extern "C" int32_t ohos_renderer_ime_preview_range_ctx(const char *text, size_t length,
                                                       int32_t start, int32_t end,
                                                       int64_t contextId)
{
    std::string input(text ? text : "", text ? length : 0);
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = takeEditingContextLocked(contextId);
        if (!s) {
            RLOGW("ime composition rejected: stale context=%{public}lld",
                  static_cast<long long>(contextId));
            return 1;
        }
        s->previewText = utf8ToUtf16(input);
        s->previewStart = 0;
        s->previewEnd = static_cast<uint32_t>(s->editingText.size());
        s->previewActive = true;
        const uint32_t size = static_cast<uint32_t>(s->previewText.size());
        bool valid = start >= 0 && end > start && static_cast<uint32_t>(end) <= size;
        if (valid) {
            valid = clampToCodePointBoundary(s->previewText, static_cast<uint32_t>(start)) ==
                static_cast<uint32_t>(start) &&
                clampToCodePointBoundary(s->previewText, static_cast<uint32_t>(end)) ==
                static_cast<uint32_t>(end);
        }
        s->markedActive = valid;
        s->markedStart = valid ? static_cast<uint32_t>(start) : 0;
        s->markedEnd = valid ? static_cast<uint32_t>(end) : 0;
        if (valid) s->markedCallbackObserved = true;
        s->caretUtf16 = valid ? s->markedEnd : size;
        RLOGI("ime composition ctx=%{public}lld marked=%{public}d start=%{public}u end=%{public}u bytes=%{public}zu",
              static_cast<long long>(contextId), valid ? 1 : 0,
              s->markedStart, s->markedEnd, input.size());
    }
    g_render.post(std::make_shared<RedrawJob>());
    return 0;
}

// 结束编辑（失焦/关闭）：旧上下文失效，后续合法输入必须能重新绑定。
extern "C" int32_t ohos_renderer_ime_finish_editing_ctx(int64_t contextId)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = takeEditingContextLocked(contextId);
    if (!s) {
        RLOGW("ime finish rejected: stale context=%{public}lld", static_cast<long long>(contextId));
        return 1;
    }
    RLOGI("ime finish ctx=%{public}lld", static_cast<long long>(contextId));
    s->editingContextLive = false;
    s->editorRetired = true;           // 逻辑结束；绘制与 accepted 同步保留到下次聚焦
    s->previewActive = false;
    s->previewText.clear();
    s->markedActive = false;
    s->pendingSettleOnDetach = false;  // 平台已提交，不再重复结算
    s->pendingImeDetach = true;
    return 0;
}

// 选区同步：平台代理把系统报告的选区写回编辑投影（单位 UTF-16 码元）。
extern "C" int32_t ohos_renderer_ime_set_selection_ctx(int32_t start, int32_t end, int64_t contextId)
{
    bool changed = false;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = takeEditingContextLocked(contextId);
        if (!s) return 1;
        const std::u16string visible = composedBuffer(*s);
        uint32_t size = static_cast<uint32_t>(visible.size());
        uint32_t a = clampToCodePointBoundary(visible, static_cast<uint32_t>(std::max(0, start)));
        uint32_t b = clampToCodePointBoundary(visible, static_cast<uint32_t>(std::max(0, end)));
        a = std::min(a, size);
        b = std::min(b, size);
        changed = (s->selStartUtf16 != a) || (s->selEndUtf16 != b) || (s->caretUtf16 != b);
        if (changed && !editorEnqueueSelectionChanged(*s, a, b)) {
            RLOGW("ime selection rejected: no matching accepted binding ctx=%{public}lld node=%{public}llu",
                  static_cast<long long>(contextId), static_cast<unsigned long long>(s->editingNodeId));
            return 1;
        }
        s->selStartUtf16 = a;
        s->selEndUtf16 = b;
        s->caretUtf16 = b;
    }
    // 选区/光标是纯视觉投影：不 bump 场景版本，必须显式请求重绘，否则拖动
    // 系统选择手柄期间没有新帧，高亮停留在上一次绘制的状态（实测手动拖选
    // 无高亮的根因）。与预览路径（ime_preview_text_ctx）同一重绘机制。
    if (changed) {
        g_render.post(std::make_shared<RedrawJob>());
    }
    return 0;
}

// 焦点请求出口：pump 在锁外调用（bridge 注册的 napi threadsafe fn）。
// payload 是带上下文编号的 JSON，平台侧不解释字段名与几何。
extern "C" void ohos_renderer_set_focus_sink(void (*sink)(const char *payload))
{
    g_focusRequestSink = sink;
}


// macOS 诊断专用 ABI 的鸿蒙显式失败实现（window.cj 诊断方法在共享核心；
// 鸿蒙无 AppKit 窗口号/合成取消/纹理探针语义，返回 INTERNAL_ERROR 不伪造事实）。
CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composition(
    uint64_t session, int32_t *outHadMarked, int32_t *outCancelReturned)
{
    (void)session;
    if (outHadMarked) *outHadMarked = 0;
    if (outCancelReturned) *outCancelReturned = 0;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus cjgui_internal_renderer_window_number(uint64_t session, int64_t *outNumber)
{
    (void)session;
    if (outNumber) *outNumber = 0;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

CjguiInternalRendererStatus cjgui_internal_renderer_probe_image_texture(
    uint64_t session, uint64_t nodeId, int32_t *outFound, int32_t *outHasTexture,
    int32_t *outCacheKeyLength, int32_t *outFailed)
{
    (void)session; (void)nodeId;
    if (outFound) *outFound = 0;
    if (outHasTexture) *outHasTexture = 0;
    if (outCacheKeyLength) *outCacheKeyLength = 0;
    if (outFailed) *outFailed = 1;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

#ifdef __cplusplus
}
#endif
