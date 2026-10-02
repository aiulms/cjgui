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
//  - 文本：系统输入代理与窗口拥有的范围会话、实际安装恢复、
//    同一 Paint 对象的命中/caret/选区高亮与焦点 blink。
//  - 不支持（显式失败）：非空 text runs、非空命令菜单、非空数据传输、悬停/按压
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
#include <native_drawing/drawing_point.h>
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
#include <unicode/ubrk.h>
#include <unicode/ustring.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstdlib>
#include <cstring>
#include <cstdio>
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

// wire 端点（UTF-8 显示字节）→ UTF-16 单位。合法标量边界必须**精确**保留：
// 前缀 UTF-16 长度就是该边界的答案（"中" byte 3 → 1，emoji byte 4 → 2）。
// 只有落点自身是延续字节（0x80..0xBF，即落在标量内部）时才回退到该标量的
// 起点——这才是 macOS CjguiComposableUtf16OffsetForByte 的 walk-back 语义；
// 原实现检查的是 `utf8[clamped-1]`，把每一个合法的多字节末边界都误当成内部
// 端点回退，于是 run 的末端被算到上一个字符内部。0 与 EOF 是合法边界。
uint32_t utf8ByteOffsetToUtf16(const std::string &utf8, uint32_t byteOffset)
{
    uint32_t clamped = byteOffset;
    if (clamped > utf8.size()) clamped = static_cast<uint32_t>(utf8.size());
    while (clamped > 0 && clamped < utf8.size() &&
           (static_cast<unsigned char>(utf8[clamped]) & 0xC0) == 0x80) {
        clamped -= 1;
    }
    return static_cast<uint32_t>(utf8ToUtf16(utf8.substr(0, clamped)).size());
}

// Mechanical encoding map around the platform ICU oracle. Text and query are
// one immutable snapshot; no cluster rule or document/selection mutation lives here.
CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *utf8, uint64_t inputBytes, uint64_t containingByte, uint64_t *outStart, uint64_t *outEnd);
bool cjguiOhosGraphemeRange16(const std::u16string &text, uint32_t offset,
                            uint32_t &start, uint32_t &end)
{
    start = end = 0;
    if (offset >= text.size()) return false;
    const uint32_t scalar = clampToCodePointBoundary(text, offset);
    const std::string encoded = utf16ToUtf8(text);
    const uint64_t byte = utf16ToUtf8(text.substr(0, scalar)).size();
    uint64_t lo = 0, hi = 0;
    if (cjgui_internal_renderer_grapheme_cluster_range(encoded.c_str(), encoded.size(), byte,
        &lo, &hi) != CJGUI_INTERNAL_RENDERER_OK) return false;
    start = static_cast<uint32_t>(utf8ToUtf16(encoded.substr(0, lo)).size());
    end = static_cast<uint32_t>(utf8ToUtf16(encoded.substr(0, hi)).size());
    return start <= offset && offset < end && end <= text.size();
}

bool utf16IsHighSurrogate(uint16_t unit) { return unit >= 0xD800 && unit <= 0xDBFF; }
bool utf16IsLowSurrogate(uint16_t unit) { return unit >= 0xDC00 && unit <= 0xDFFF; }

// 该偏移是否落在 UTF-16 的**合法标量边界**上（不切开代理对）。范围差分的两端
// 都必须满足这个条件，否则重放会产生孤立代理并编码成非法 UTF-8。
bool utf16IsScalarBoundary(const std::u16string &text, size_t offset)
{
    if (offset == 0 || offset >= text.size()) return true;
    return !(utf16IsHighSurrogate(static_cast<uint16_t>(text[offset - 1])) &&
             utf16IsLowSurrogate(static_cast<uint16_t>(text[offset])));
}

// 该串是否只含合法标量（没有不成对的代理）。平台回调可能送来畸形 UTF-16；
// 那类输入不能被表达成一个合法的 UTF-8 范围增量，必须具名拒绝。
bool utf16IsWellFormed(const std::u16string &text)
{
    for (size_t i = 0; i < text.size(); ++i) {
        uint16_t unit = static_cast<uint16_t>(text[i]);
        if (utf16IsHighSurrogate(unit)) {
            if (i + 1 >= text.size() ||
                !utf16IsLowSurrogate(static_cast<uint16_t>(text[i + 1]))) {
                return false;
            }
            i += 1;
        } else if (utf16IsLowSurrogate(unit)) {
            return false;
        }
    }
    return true;
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

// 文本盒内缩进：绘制、光标、选区高亮与触摸命中必须用同一个常量。此前绘制用
// 6.0（多行）/2.0（单行）而命中用硬编码 7.0，高亮又用 7.0，三者原点互不相同，
// 于是"点中的位置"和"看到的字符"差 1px，且高亮与字形在纵向不共线。
constexpr double kTextInsetSingleLine = 2.0;
constexpr double kTextInsetMultiline = 6.0;

// 可编辑文本节点集合，与 macOS 的 `CjguiComposableNodeIsTextInput` 同集：
// 单行 / 整数 / 多行。多行是连续写作面（真实 Pharos 源码正文）的实际类型；
// 漏掉它，点击永远不会激活编辑上下文——触摸与程序化聚焦都被拒。
bool isEditableTextKind(uint32_t kind)
{
    return kind == kKindTextInput || kind == kKindIntegerInput || kind == kKindMultiline;
}

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
// H1-C：窗口拥有的正文会话。声明后该节点的提交以**精确 UTF-16 范围增量**
// 交付（selectionStart/End 是被替换的区间，text 是替换文本），整值事件被
// 抑制：消费方只经会话 Sink 写一次正文。
constexpr uint32_t kEvTextRangeChanged = 51;
// 平台隐藏代理**实际安装**完一次冻结的恢复请求后的回执。排队成功不等于已安装：
// 窗口要等到这张带原请求身份（bindingEpoch=请求号）与实际安装区间的回执才解锁。
constexpr uint32_t kEvTextProxyRestored = 55;

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

// 已接受的文字样式 run（C，h-source-preview-next）：与 macOS/框架同一 wire 编码
// （start:end:fontSize:weight:family:r:g:b:a[:bgFlag:br:bg:bb:ba]，';' 分隔）。
// wire 端点是节点显示文本的 **UTF-8 显示字节偏移**（SourceMap/网格 caret run/
// macOS CjguiComposableUtf16OffsetForByte 都按字节说这条协议）；安装时按节点
// 当前文本换成 UTF-16 单位（TypographyAddText 吃 UTF-8，切段按 UTF-16 边界），
// 两平台的可见行为因此一致。
struct OhosTextStyleRun {
    uint32_t start = 0, end = 0;  // parse 后 = wire 字节；install 后 = UTF-16 单位
    double fontSize = 13.0;
    uint32_t fontWeight = 0;
    uint32_t fontFamily = 0;  // 0 系统 1 等宽 2 斜体 3 等宽斜体
    float red = 0, green = 0, blue = 0, alpha = 1;
    bool hasBackground = false;
    float bgRed = 0, bgGreen = 0, bgBlue = 0, bgAlpha = 1;
};

static std::atomic<uint64_t> textStyleRunsInstalled{0};

// 每节点样式 run 数量上限：分配前准入，超出整批具名拒绝（保旧）。
static constexpr size_t kMaxTextStyleRunsPerNode = 64;

static bool parseTextStyleRuns(const char *encoded, std::vector<OhosTextStyleRun> &out)
{
    out.clear();
    if (!encoded) return true;  // 空 = 清除
    std::string src(encoded);
    if (src.empty()) return true;
    size_t pos = 0;
    while (pos <= src.size()) {
        size_t semi = src.find(';', pos);
        std::string item = src.substr(pos, semi == std::string::npos ? std::string::npos : semi - pos);
        pos = (semi == std::string::npos) ? src.size() + 1 : semi + 1;
        if (item.empty()) continue;
        std::vector<std::string> f;
        size_t fp = 0;
        while (fp <= item.size()) {
            size_t colon = item.find(':', fp);
            f.push_back(item.substr(fp, colon == std::string::npos ? std::string::npos : colon - fp));
            fp = (colon == std::string::npos) ? item.size() + 1 : colon + 1;
        }
        if (f.size() < 9) return false;
        OhosTextStyleRun run = {};
        run.start = static_cast<uint32_t>(strtoul(f[0].c_str(), nullptr, 10));
        run.end = static_cast<uint32_t>(strtoul(f[1].c_str(), nullptr, 10));
        run.fontSize = strtod(f[2].c_str(), nullptr);
        run.fontWeight = static_cast<uint32_t>(strtoul(f[3].c_str(), nullptr, 10));
        run.fontFamily = static_cast<uint32_t>(strtoul(f[4].c_str(), nullptr, 10));
        run.red = strtof(f[5].c_str(), nullptr);
        run.green = strtof(f[6].c_str(), nullptr);
        run.blue = strtof(f[7].c_str(), nullptr);
        run.alpha = strtof(f[8].c_str(), nullptr);
        if (f.size() >= 14) {
            run.hasBackground = strtoul(f[9].c_str(), nullptr, 10) != 0;
            run.bgRed = strtof(f[10].c_str(), nullptr);
            run.bgGreen = strtof(f[11].c_str(), nullptr);
            run.bgBlue = strtof(f[12].c_str(), nullptr);
            run.bgAlpha = strtof(f[13].c_str(), nullptr);
        }
        if (run.start >= run.end) return false;  // 空/倒置范围整批拒绝
        out.push_back(run);
        if (out.size() > kMaxTextStyleRunsPerNode) return false;
    }
    // 排序并拒绝重叠：重叠语义（后胜）在 Typography 分段里无法表达为
    // 单一区间集合，具名拒绝比静默合并诚实。字节域与 UTF-16 域单调同序，
    // 这里在 wire 字节域检查即可。
    std::sort(out.begin(), out.end(), [](const OhosTextStyleRun &a, const OhosTextStyleRun &b) {
        return a.start < b.start;
    });
    for (size_t i = 1; i < out.size(); ++i) {
        if (out[i].start < out[i - 1].end) return false;
    }
    return true;
}

struct SceneNode {
    CjguiInternalRendererComposableNode pod{};
    std::string label;
    std::string value;
    std::string semanticId;
    OhosImageRef image;
    std::vector<OhosTextStyleRun> textStyleRuns;
    // R2：本候选事务是否**实际写入**过这个槽位。configure 从 accepted 播种时为
    // false（此刻 candidate.value 仍是上一代文本，不能作为 run 准入基准）；
    // set_composable_scene_node 写入后为 true（candidate.value 才是本候选文本）。
    bool stagedThisCandidate = false;
};

// Pure geometry from the exact Paint/Flush, never a text owner or an input protocol.
struct PaintedSelectionHandles {
    bool valid = false;
    bool startVisible = false, endVisible = false;
    uint64_t session = 0, nodeId = 0, binding = 0, ticket = 0, projection = 0;
    uint64_t generation = 0, geometryRevision = 0;
    int64_t context = 0, resource = -1;
    uint32_t kind = 0, start = 0, end = 0;
    std::u16string text;
    double startX = 0, startY = 0, startLineY = 0;
    double endX = 0, endY = 0, endLineY = 0;
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
    // H1-C：正文会话的绑定代次（只有窗口声明过的节点才有非零值）。事件 POD
    // 的同名字段原样回传，窗口据此拒绝换绑前入队的旧增量。
    uint64_t bindingEpoch = 0;
    // Private provenance for a platform selection observation. A refocus can
    // reuse the same node, scene and binding while creating a new proxy.
    int64_t editingContextId = 0;
    uint64_t editingContextGeneration = 0;
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
    // C：run 表是渲染器的真理源（与 macOS composableTextStyleRunsRaw 同一
    // 语义）。窗口在每个候选事务构建的早期安装 runs（configure 重置候选
    // 之前）；把 runs 只挂在候选/已接受对象上会在事务换代时被丢弃，因此
    // 经会话级表存放，节点 stage 时按 nodeId 应用到当帧对象。
    // R2 判别 4（删除后同 id 复用）：表的键是 nodeId，但**声明必须绑定身份**。
    // 同一 session 内某 id 被删除后复用为另一个对象时，只按 nodeId 查表会把旧
    // run 沿用到新对象上（旧端点可能越界或指向错误文本）。这里随表记录首次
    // stage 时的身份三元组；身份不符即视为无声明，新对象不得沿用。
    struct TextRunBinding {
        std::vector<OhosTextStyleRun> runs;
        int64_t resourceId = -1;
        uint32_t nodeKind = 0;
        uint64_t bindingEpoch = 0;
        bool identityKnown = false;
    };
    // S1（Astra 裁决的快照事务）：发布快照与候选声明分离。acceptedRunTable 是
    // 与 accepted 场景**同一次提交**晋升的字节域声明（A.rawRuns）；buildingRunTable
    // 是当前 Building 候选的声明集（configure 从发布快照播种，抛弃即丢弃）。
    // 成功 present 才把 building 冻结晋升为发布快照；候选丢弃/失败不泄漏。
    std::map<uint64_t, TextRunBinding> acceptedRunTable;
    std::map<uint64_t, TextRunBinding> buildingRunTable;
    double clearR = 0.08, clearG = 0.16, clearB = 0.20, clearA = 1.0;
    bool rangeEditDeltaRequested = false;
    // H1-C：窗口声明的正文会话节点。声明生效时该节点的提交走精确范围增量，
    // 未声明的节点一律不产生 kind 51——消费方不会在没有绑定的节点上 fail-closed。
    bool ownedTextSessionEnabled = false;
    uint64_t ownedTextSessionNodeId = 0;
    int64_t ownedTextSessionResourceId = -1;
    uint32_t ownedTextSessionNodeKind = 0;
    uint64_t ownedTextSessionBindingEpoch = 0;
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
    uint64_t acceptedPaintTicketId = 0;
    bool candidateOpen = false;
    // S1（Astra）：候选进入 Failed 后禁止 present——run 准入失败必须终止本次
    // 窗口尝试，防止调用方忽略错误后发布「旧样式 + 新文本」的混合结果。
    bool candidateFailed = false;
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
            kGestureSelectionDrag = 4,
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
        uint32_t tapCount = 1, timeSource = 0;
        int64_t beginNs = 0, endNs = 0;
        bool shortTapCompleted = false, longPressRecognized = false;
        bool caretMenuTap = false, caretMenuShow = false;
    };
    TouchGesture gesture;
    // C/S2（R1，Astra s2-identity-handoff）：待发 end 通知队列。每个收场入口
    // （点击空白、跨字段切换、平台 finish、回车、场景撤销 kill）都在**冻结
    // 旧身份的同一临界区**压入自己那条 (contextId, fieldName, settle)；pump 按
    // FIFO 逐条投递。单槽会被后续收场覆盖（finish(A)→bind(B) 后 A 的 end 丢失
    // 或误寄新身份），队列保证每条退役通知只携带它自己的将死身份。
    struct PendingEnd {
        int64_t contextId = 0;
        std::string fieldName;
        bool settleOnDelivery = false;  // 投递前按失焦语义结算组合缓冲（恰好一次）
    };
    std::deque<PendingEnd> pendingEnds;
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
    // 绑定代次（S2/Astra）：节点级 acceptedBindingEpoch 属于绑定身份——同 id
    // 换代次（换绑/重声明）不是同一对象，sync 失配判定必须比较它，否则
    // 旧上下文借复用的节点 id 存活（ABA 缺口，咨询 s2-identity-handoff-astra）。
    uint64_t editingAcceptedBindingEpoch = 0;
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
    // 框架主动结束编辑（点到别处/空白）时的失焦语义由 pendingEnds 条目自己的
    // settleOnDelivery 携带；不再用单布尔位（会被后续收场/新焦点覆盖）。
    // 逻辑编辑已结束（上下文失效、平台代理释放、延迟回调被拒），但原生编辑器
    // 仍是该节点的绘制方。核心的「本地文字延续」窗口会把 native 值置空并约定
    // 由 native 编辑器绘制可见文本（macOS 用输入代理的字符串做同一件事）；若在
    // 结算前就停止绘制，那一次投影就会把字段画成空白。因此 retirement 只结束
    // 上下文与代理，不结束绘制；下一次聚焦按 accepted 值重新初始化缓冲。
    bool editorRetired = false;
    double editingTapX = 0.0;
    double editingTapY = 0.0;
    bool editingTapPending = false;
    uint32_t editingHitMode = 0;  // 0=caret, 1=platform word, 2=drag extent, 3=logical paragraph
    uint64_t selectionOperationGeneration = 0;
    PaintedSelectionHandles selectionHandles;
    // Transient user request, separate from usable Paint coordinates.
    uint32_t textMenuIntent = 0;  // 0=hidden, 1=selected text, 2=explicit caret menu
    struct TextTapChain {
        bool armed = false;
        uint32_t count = 0, timeSource = 0, kind = 0;
        int64_t endNs = 0, context = 0, resource = -1;
        uint64_t app = 0, component = 0, surface = 0, geometry = 0, node = 0, binding = 0, base = 0;
        float x = 0, y = 0;
        std::u16string text;
    } textTapChain;
    struct SelectionDrag {
        bool active = false, anchorReady = false, terminal = false;
        bool wordHold = false, moved = false;
        uint64_t operation = 0, nodeId = 0, binding = 0, projection = 0;
        uint64_t generation = 0, geometryRevision = 0, app = 0, component = 0, epoch = 0;
        int64_t context = 0, resource = -1, pointer = -1;
        uint32_t kind = 0, anchor = 0;
        std::u16string text;
        double offsetX = 0, offsetY = 0;
        double lastX = 0, lastY = 0;
    } selectionDrag;
    bool focusNotifyPending = false;
    bool reconcileNotifyPending = false;
    int64_t reconcileOldContextId = 0;
    // 平台代理已知的落点（native→平台 差分推送用）。命中/编辑命令/外部换版把 caret
    // 挪走后，已挂载的代理仍停在自己的旧落点，人的下一次键入就落错位置（实测：
    // 命中 caret=8，代理仍在 1，键入插到正文开头）。因此按差分把 native 落点推给
    // 平台；平台回声（ime_set_selection_ctx）与恢复 ACK 同步这两个字段，避免自激。
    uint32_t selPlatformStart = 0;
    uint32_t selPlatformEnd = 0;
    // 新的人类锚需要锚之后的一次实际平台观测，即使落点与两本去重账相同。
    // 只在成功投递 caret 通知时消费，换绑/退役随锚一起撤回。
    bool humanCaretNotificationPending = false;
    // pump owns the clock/phase; input only requests reset. Rendering reads one
    // frozen phase, including pending reset so the first input frame is bright.
    bool caretBlinkVisible = false;
    bool caretBlinkActive = false;
    bool caretBlinkResetPending = false;
    int64_t caretBlinkNextMs = 0;
    // 已经转发给窗口的平台落点观测（kind-33）。与 selPlatform* 不是一回事：后者是
    // "native 推给平台的目标"，用于差分去重；这里是"窗口收到过哪个观测"。判重必须
    // 按后者——人点击正文时 native 先算出命中落点，平台装好后回声的就是同一个值，
    // 按 selPlatform*/caret 判重会把这次回声吞掉，窗口于是永远不知道"平台已安装人的
    // 落点"，人类锚只 recorded 不 taken，紧随的键入被 selection_native_alignment_required
    // 拒掉（实测 09-30 03:49:28.822 `ime select [24,24) rc=0` 之后无任何窗口侧记录）。
    uint32_t selForwardedStart = 0;
    uint32_t selForwardedEnd = 0;
    bool selForwardedValid = false;
    int32_t caretAffinity = 0;  // native-only visual affinity; UTF16 protocol is unchanged
    // 人类锚（H1-R.a）：人在 native 表面上亲手放置的落点（命中测试/原生全选）。
    // 与平台回声不同类——回声只证明"组件报告过某区间"，锚证明"人把光标放到了哪里"。
    // 外部换版后窗口置 selectionNeedsNativeRestore 挡住一切输入，而它既有的两条解除
    // 路径都要求框架焦点 + accepted 对齐，人第一次点击之前不可能触发（实测：Agent
    // 替换后点击正文，键入被 selection_native_alignment_required 静默丢弃，owner 停在
    // 44 字节）。锚冻结身份与序号，由窗口一次性核验采纳；回声仍按安装观测处理。
    struct HumanSelectionAnchor {
        uint64_t seq = 0;          // 0 = 无锚；单调递增，窗口按序号防重放
        uint64_t nodeId = 0;
        int64_t resourceId = -1;
        uint32_t nodeKind = 0;
        uint64_t projectionVersion = 0;
        uint64_t acceptedBindingEpoch = 0;
        uint32_t start16 = 0;
        uint32_t end16 = 0;
        bool consumed = false;     // 窗口已取走：同一锚不得二次采纳
    };
    HumanSelectionAnchor humanAnchor;
    uint64_t humanAnchorSeq = 0;
    // 平台代理恢复请求（**冻结身份**）。owner 拒绝人的范围编辑、或窗口在外部换版后
    // 重设落点时签发；创建时把上下文/代际/节点/字段/accepted 版本与绑定/正文/选区
    // 全部冻结，发送与回执都只读这份冻结值——绝不重读当前 context/field/base。
    // 原因：pump 先 drainTouches 再发通知，"A 排恢复 → 点击 B 换焦 → 发送" 会带出
    // A 的正文配 B 的身份，越过平台的当前身份检查。换绑/退役/结束/外部换版 reconcile
    // 一律取消旧请求：旧恢复串不得贴到新节点，迟到的旧回执也不得解任何锁。
    // H1-R（Astra 裁决）：请求状态、恢复意图、安装事实三本账分开。
    // state 是互斥的进行中相位；terminal 一旦写入就是该请求的终态，
    // 终态不得抹掉已经发生的事实（transportReceived/platformInstalled）。
    struct ProxyRestoreRequest {
        uint64_t requestId = 0;
        bool armed = false;         // 已冻结、等待发送
        bool awaitingAck = false;   // 已发送、等待平台实际安装回执
        bool sent = false;          // 事实：已交付 sink（transportAccepted）
        bool received = false;      // 事实：平台就本请求回报过（不论裁决）
        bool platformInstalled = false;  // 事实：平台观测确认安装（落点等于规范目标）
        bool reported = false;      // 事实：终态事件已投递给窗口
        int64_t deadlineMonoMs = 0; // 覆盖排队→发送→安装→窗口裁决
        uint64_t nodeId = 0;
        int64_t resourceId = -1;
        uint32_t nodeKind = 0;
        uint64_t acceptedProjectionVersion = 0;
        uint64_t acceptedBindingEpoch = 0;
        int64_t contextId = 0;
        uint64_t contextGeneration = 0;
        std::string fieldName;
        std::u16string text;
        uint32_t selStart = 0;      // 规范目标（签发前确定，ACK 时不迁就结果）
        uint32_t selEnd = 0;
        uint32_t observedStart = 0; // 观测账本：平台报告的实际落点
        uint32_t observedEnd = 0;
        std::string terminalReason;
    };
    // 票据终局账本（有界）：迟到/重复回执按 requestId 返回既有裁决，不重复计终态；
    // 窗口查询票据时也读它，事件丢失时仍能终结自己的待办。
    struct ProxyRestoreTerminal {
        uint64_t requestId = 0;
        // 1=未安装即终结 2=安装未确认终结 3=平台已安装待窗口采纳 4=窗口已采纳
        int32_t code = 0;
        std::string reason;
        bool platformInstalled = false;
        uint32_t observedStart = 0;
        uint32_t observedEnd = 0;
    };
    std::deque<ProxyRestoreTerminal> proxyRestoreTerminals;
    ProxyRestoreRequest proxyRestore;
    uint64_t proxyRestoreRequestSeq = 0;
    // 通用文字代理上下文（不透明）：关联 session、节点/绑定、编辑代际与基版本。
    // 平台代理的每次延迟回调必须携带并校验它；不匹配的回调不得改写编辑状态。
    int64_t editingContextId = 0;
    std::string editingFieldName;
    uint64_t editingContextGeneration = 0;     // 分配上下文时的 surface 代际
    uint64_t editingContextBaseVersion = 0;    // 分配上下文时的场景投影版本
    // R1补轮：曾以此记录"绑定出生票据"做 sync 容忍；票号大小不能证明来源
    // 关系，来源判定已前移到结算入口的来源上下文比较（PendingSettlement），本
    // 字段退役。
    bool editingContextLive = false;
    // D2（S3 抖动修复）：新上下文对「过渡 accepted 帧」的宽限计数。rebind 后
    // 最早一两帧可能是模式切换的过渡场景（编辑节点缺席/旗标退化）；编辑缓冲
    // 同步在此宽限期内不 kill 上下文，稳定后才按原判据收场。
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

// Pump-only phase decision. Rendering reads the decision and pending reset;
// it never reads the clock or advances application/scene/selection state.
bool advanceCaretBlinkLocked(Session &s, int64_t nowMs, bool eligible)
{
    if (!eligible) {
        const bool erase = s.caretBlinkActive || s.caretBlinkVisible || s.caretBlinkResetPending;
        s.caretBlinkActive = false;
        s.caretBlinkVisible = false;
        s.caretBlinkResetPending = false;
        s.caretBlinkNextMs = 0;
        return erase;
    }
    if (!s.caretBlinkActive || s.caretBlinkResetPending) {
        s.caretBlinkActive = true;
        s.caretBlinkVisible = true;
        s.caretBlinkResetPending = false;
        s.caretBlinkNextMs = nowMs + 500;
        return true;
    }
    if (nowMs >= s.caretBlinkNextMs) {
        s.caretBlinkVisible = !s.caretBlinkVisible;
        s.caretBlinkNextMs = nowMs + 500;  // late pump toggles once, never a catch-up burst
        return true;
    }
    return false;
}
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

// Logical source paragraphs; visual wrapping never introduces a separator.
void sourceParagraphRange16(const std::u16string &text, uint32_t caret, uint32_t &lo, uint32_t &hi)
{
    lo = hi = std::min(caret, static_cast<uint32_t>(text.size()));
    if (text.empty()) return;
    const auto separator = [](char16_t c) { return c == u'\n' || c == u'\r' || c == u'\u2029'; };
    const uint32_t at = lo == text.size() ? lo - 1 : lo;
    if (separator(text[at])) return; // an empty line retains its collapsed caret
    lo = hi = at;
    while (lo > 0 && !separator(text[lo - 1])) --lo;
    while (hi < text.size() && !separator(text[hi])) ++hi;
}

struct CaretHitTestJob : WaitableJob {
    CaretHitTestJob() : WaitableJob(JobKind::CaretHitTest) {}
    std::u16string text;   // 组合缓冲（UTF-16）
    double fontSize = 13.0;
    uint32_t fontWeight = 400;
    double nodeWidth = 0.0;
    double nodeHeight = 0.0;
    uint32_t nodeKind = 0;
    double tapX = 0.0;     // 节点内相对坐标
    double tapY = 0.0;     // 节点内相对坐标（多行正文靠它定位行）
    uint32_t caretUtf16 = 0;
    int32_t caretAffinity = 0;
    uint64_t session = 0, nodeId = 0, bindingEpoch = 0, projectionVersion = 0;
    int64_t resourceId = -1, contextId = 0, nodeX = 0, nodeY = 0;
    uint64_t paintSerial = 0, sourcePaintTicket = 0;
    uint32_t mode = 0, wordStart = 0, wordEnd = 0;
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
    bool caretBlinkWake = false;
    uint64_t renderEpoch = 0;
};

// Render-thread-only ownership of the Typography actually passed to Paint.
// Jobs and Sessions carry value identities only, never this native object.
struct PaintedTextLayout {
    std::unique_ptr<OH_Drawing_Typography, decltype(&OH_Drawing_DestroyTypography)> typography
        {nullptr, &OH_Drawing_DestroyTypography};
    CjguiInternalRendererComposableNode node{};
    std::u16string text;
    uint64_t session = 0, renderEpoch = 0, basePresentTicket = 0, projectionVersion = 0, serial = 0;
    uint64_t generation = 0, geometryRevision = 0;
    void *window = nullptr;
    int32_t width = 0, height = 0;
    int64_t paintContext = 0;
    double density = 1.0, relativeOriginX = 0.0, relativeOriginY = 0.0;
    PaintedSelectionHandles handles;
};
struct TextPaintFrame {
    uint64_t session = 0, ticket = 0, projectionVersion = 0;
    std::unique_ptr<PaintedTextLayout> candidate;
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
struct Session;
struct PendingSettlement {
    JobRef job;
    std::vector<SceneNode> nodes;
    // S1（Astra）：提交票据冻结整个候选快照（含字节域声明表）。延迟成功结算
    // 晋升的是这份冻结表，绝不回读提交后可能已被下一候选改写的 working 表。
    std::map<uint64_t, Session::TextRunBinding> runTable;
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
    // R1补轮（2026-10-02 指导复核）：候选冻结（present 锁内登记票据）时的编辑
    // 上下文来源快照。结算时若存在**另一个**活上下文（编号不同），说明该候选
    // 是旧来源的模式结果——它对编辑节点的缺席/退化不代表当前绑定的真实撤销，
    // 必须在不可逆晋升（accepted 树交换/绘制提交）**之前**整票拒绝，不得先
    // 发布删除节点的旧树再靠跳过 sync 保活（票号大小不构成来源关系证明）。
    int64_t sourceEditingContextId = 0;
    bool sourceEditingLive = false;
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
    // 绑定代次的逻辑密度：surface 尺寸是物理 px，节点几何是 vp，绘制按它放大。
    double surfaceDensity = 1.0;

    // 末帧副本（渲染线程自有）：预览态重绘的数据来源
    std::vector<SceneNode> lastNodes;
    uint64_t lastProjectionVersion = 0;
    uint64_t lastFrameSession = 0;
    uint64_t lastFrameGeneration = 0;
    void *lastFrameWindow = nullptr;
    double lastClearR = 0, lastClearG = 0, lastClearB = 0, lastClearA = 1;
    bool hasLastFrame = false;
    // Queue lock owns both fields. Only a wake from this run can enter, and
    // only its dequeue clears the queued bit (one executing + one queued).
    uint64_t renderEpoch = 0;
    bool caretBlinkRedrawQueued = false;
    uint64_t submittedFrames = 0;
    uint64_t redrawFrames = 0;
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
        renderEpoch += 1;
        caretBlinkRedrawQueued = false;
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

    uint64_t currentRunEpoch()
    {
        std::lock_guard<std::mutex> g(lock);
        return running && !stopping ? renderEpoch : 0;
    }

    std::unique_ptr<PaintedTextLayout> lastPaintLayout;
    bool paintedLayoutUsable = false;
    uint64_t textPaintSerial = 0;
    uint64_t textLayoutsBuilt = 0, textLayoutInputBytes = 0;
    uint64_t lastFrameTicket = 0;

    void invalidatePaintedLayout(uint64_t session)
    {
        paintedLayoutUsable = false;
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (s) s->selectionHandles = PaintedSelectionHandles{};
    }

    void publishPaintedLayout(TextPaintFrame &frame)
    {
        // A successful frame with no painted editing node revokes old geometry.
        lastPaintLayout = std::move(frame.candidate);
        paintedLayoutUsable = true;
        {
            // Pure value geometry is published only after this frame's Flush.
            // The native Typography remains owned by the render thread.
            std::lock_guard<std::mutex> g(g_sessions.lock);
            Session *s = lookupSessionLocked(frame.session);
            if (s) {
                s->selectionHandles = PaintedSelectionHandles{};
                if (lastPaintLayout && lastPaintLayout->handles.valid && s->editing &&
                    s->editingContextLive && !s->editorRetired && !s->previewActive &&
                    s->editingContextId == lastPaintLayout->paintContext &&
                    composedBuffer(*s) == lastPaintLayout->text &&
                    std::min(s->selStartUtf16, s->selEndUtf16) == lastPaintLayout->handles.start &&
                    std::max(s->selStartUtf16, s->selEndUtf16) == lastPaintLayout->handles.end) {
                    s->selectionHandles = lastPaintLayout->handles;
                }
            }
        }
        if (lastPaintLayout) {
            RLOGI("text layout flushed serial=%{public}llu session=%{public}llu ticket=%{public}llu projection=%{public}llu",
                static_cast<unsigned long long>(lastPaintLayout->serial),
                static_cast<unsigned long long>(lastPaintLayout->session),
                static_cast<unsigned long long>(lastPaintLayout->basePresentTicket),
                static_cast<unsigned long long>(lastPaintLayout->projectionVersion));
        }
    }

    bool postCaretBlink(uint64_t expectedEpoch)
    {
        {
            std::lock_guard<std::mutex> g(lock);
            if (!running || stopping || expectedEpoch == 0 || expectedEpoch != renderEpoch) return false;
            if (caretBlinkRedrawQueued) return true;  // queued wake renders the latest phase
            auto job = std::make_shared<RedrawJob>();
            job->caretBlinkWake = true;
            job->renderEpoch = expectedEpoch;
            caretBlinkRedrawQueued = true;
            jobs.push_back(job);
        }
        cv.notify_all();
        return true;
    }

    bool postCaretHitAfterRedraw(const JobRef &hit, uint64_t expectedEpoch)
    {
        {
            std::lock_guard<std::mutex> g(lock);
            if (!running || stopping || expectedEpoch == 0 || expectedEpoch != renderEpoch) return false;
            // First focus/preview can precede its ordinary redraw. The real
            // Paint+Flush goes first; the hit itself never creates a layout.
            jobs.push_back(std::make_shared<RedrawJob>());
            jobs.push_back(hit);
        }
        cv.notify_all();
        return true;
    }

    void consumeCaretBlinkWakeLocked(const JobRef &job)
    {
        if (job->kind == JobKind::Redraw) {
            const auto *redraw = static_cast<const RedrawJob *>(job.get());
            if (redraw->caretBlinkWake && redraw->renderEpoch == renderEpoch) {
                caretBlinkRedrawQueued = false;
            }
        }
    }

    bool cachedFrameMatchesSurface() const
    {
        return hasLastFrame && surface && lastFrameSession != 0 &&
            lastFrameGeneration == boundGeneration && lastFrameWindow == boundWindow;
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
            consumeCaretBlinkWakeLocked(job);
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
            caretBlinkRedrawQueued = false;
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
        if (!cachedFrameMatchesSurface()) return;
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
        // 与 present 同一 canvas、同一换算：vp 几何整帧放大一次 density，并用
        // Save/Restore 配对归还（矩阵跨帧保留，见 present 处说明）。
        OH_Drawing_CanvasSave(canvas);
        if (surfaceDensity > 0.0 && surfaceDensity != 1.0) {
            OH_Drawing_CanvasScale(canvas, static_cast<float>(surfaceDensity),
                                   static_cast<float>(surfaceDensity));
        }
        TextPaintFrame paintFrame{lastFrameSession, lastFrameTicket, lastProjectionVersion, nullptr};
        for (const SceneNode &n : lastNodes) {
            if (n.pod.width <= 0 || n.pod.height <= 0) continue;
            OH_Drawing_CanvasSave(canvas);
            if (applyClipChain(canvas, n.pod)) {   // 空裁剪：不可见
                drawFill(canvas, n.pod);
                drawNodeImage(canvas, n);
                drawBorder(canvas, n.pod);
                drawNodeText(canvas, n, paintFrame);
            }
            OH_Drawing_CanvasRestore(canvas);
        }
        OH_Drawing_CanvasRestore(canvas);
        if (!leaseValid(boundGeneration) ||
            !geometryMatches(boundWindow, boundGeneration, surfaceW, surfaceH,
                             permitGeometryRevision)) {
            teardownSurface(!leaseValid(boundGeneration));
            return;
        }
        const uint64_t generation = boundGeneration;
        const uint64_t revision = permitGeometryRevision;
        const OH_Drawing_ErrorCode flush = OH_Drawing_SurfaceFlush(surface);
        if (!leaseValid(generation) || !geometryMatches(boundWindow, generation, surfaceW, surfaceH, revision)) {
            RLOGW("redraw flush lost lease/geometry gen=%{public}llu", static_cast<unsigned long long>(generation));
            teardownSurface(!leaseValid(generation));
            return;
        }
        if (flush != OH_DRAWING_SUCCESS) {
            invalidatePaintedLayout(lastFrameSession);
            RLOGW("redraw SurfaceFlush error=%{public}d", static_cast<int>(flush));
            return;
        }
        publishPaintedLayout(paintFrame);
        redrawFrames += 1;
        RLOGI("redraw frame ok session=%{public}llu gen=%{public}llu geometry=%{public}llu seq=%{public}llu layouts=%{public}llu layoutBytes=%{public}llu",
            static_cast<unsigned long long>(lastFrameSession), static_cast<unsigned long long>(generation),
            static_cast<unsigned long long>(revision), static_cast<unsigned long long>(redrawFrames),
            static_cast<unsigned long long>(textLayoutsBuilt), static_cast<unsigned long long>(textLayoutInputBytes));
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
        const auto *painted = lastPaintLayout.get();
        if (!paintedLayoutUsable || !painted || !painted->typography) {
            RLOGW("caret hit refused: painted_layout_unavailable");
            job->finish(CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY);
            return;
        }
        if (painted->renderEpoch != renderEpoch || painted->window != boundWindow ||
            painted->generation != boundGeneration || !leaseValid(painted->generation) ||
            !geometryMatches(painted->window, painted->generation, painted->width,
                             painted->height, painted->geometryRevision)) {
            RLOGW("caret hit refused: painted_surface_stale serial=%{public}llu", static_cast<unsigned long long>(painted->serial));
            job->finish(CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED);
            return;
        }
        {
            std::lock_guard<std::mutex> g(g_sessions.lock);
            const Session *s = lookupSessionLocked(job->session);
            if (!s || !s->editing || !s->editingContextLive || s->editorRetired ||
                s->editingContextId != job->contextId || s->editingNodeId != job->nodeId ||
                s->editingResourceId != job->resourceId || s->editingNodeKind != job->nodeKind ||
                s->editingProjectionVersion != job->projectionVersion || composedBuffer(*s) != job->text) {
                RLOGW("caret hit refused: editing_snapshot_stale");
                job->finish(CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED);
                return;
            }
            if (s->acceptedPaintTicketId != painted->basePresentTicket) {
                RLOGW("caret hit refused: paint_pending_acceptance serial=%{public}llu ticket=%{public}llu accepted=%{public}llu",
                    static_cast<unsigned long long>(painted->serial), static_cast<unsigned long long>(painted->basePresentTicket),
                    static_cast<unsigned long long>(s->acceptedPaintTicketId));
                job->finish(CJGUI_INTERNAL_RENDERER_PRESENT_PENDING);
                return;
            }
        }
        const auto &node = painted->node;
        if (painted->session != job->session || painted->text != job->text ||
            node.nodeId != job->nodeId || node.resourceId != job->resourceId || node.nodeKind != job->nodeKind ||
            node.acceptedBindingEpoch != job->bindingEpoch || painted->projectionVersion != job->projectionVersion ||
            node.x != job->nodeX || node.y != job->nodeY || node.width != job->nodeWidth ||
            node.height != job->nodeHeight || node.fontSize != job->fontSize || node.fontWeight != job->fontWeight) {
            RLOGW("caret hit refused: painted_layout_stale serial=%{public}llu", static_cast<unsigned long long>(painted->serial));
            job->finish(CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED);
            return;
        }
        OH_Drawing_PositionAndAffinity *hit = OH_Drawing_TypographyGetGlyphPositionAtCoordinateWithCluster(
            painted->typography.get(), job->tapX - painted->relativeOriginX, job->tapY - painted->relativeOriginY);
        if (!hit) {
            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
            return;
        }
        const size_t position = OH_Drawing_GetPositionFromPositionAndAffinity(hit);
        const int affinity = OH_Drawing_GetAffinityFromPositionAndAffinity(hit);
        OH_Drawing_DestroyPositionAndAffinity(hit);
        job->caretUtf16 = static_cast<uint32_t>(std::min<size_t>(position, painted->text.size()));
        if (job->caretUtf16 < painted->text.size()) {
            uint32_t lo = 0, hi = 0;
            if (!cjguiOhosGraphemeRange16(painted->text, job->caretUtf16, lo, hi)) {
                job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
                return;
            }
            if (job->caretUtf16 != lo) job->caretUtf16 = affinity == 1 ? lo : hi;
        }
        if (job->mode == 1 && !painted->text.empty()) {
            // GetWordBoundary uses UTF-16 in this SDK. Query the actual painted
            // paragraph, then verify/expand both edges with the platform ICU oracle.
            uint32_t at = job->caretUtf16;
            if (at == painted->text.size() || (affinity == 0 && at > 0)) --at;
            OH_Drawing_Range *word = OH_Drawing_TypographyGetWordBoundary(painted->typography.get(), at);
            if (!word) {
                RLOGW("word_boundary_failed: platform range unavailable");
                job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
                return;
            }
            const size_t start = OH_Drawing_GetStartFromRange(word);
            const size_t end = OH_Drawing_GetEndFromRange(word);
            OH_Drawing_ReleaseRangeBuffer(word);
            uint32_t lo = 0, hi = 0, lastLo = 0, lastHi = 0;
            if (start >= end || end > painted->text.size() ||
                !cjguiOhosGraphemeRange16(painted->text, static_cast<uint32_t>(start), lo, hi) ||
                !cjguiOhosGraphemeRange16(painted->text, static_cast<uint32_t>(end - 1), lastLo, lastHi)) {
                RLOGW("word_boundary_failed: invalid or unverified edges");
                job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
                return;
            }
            job->wordStart = lo;
            job->wordEnd = lastHi;
            RLOGI("word hit painted serial=%{public}llu range=%{public}u:%{public}u",
                static_cast<unsigned long long>(painted->serial), lo, lastHi);
        }
        if (job->mode == 3) {
            uint32_t lo = 0, hi = 0;
            sourceParagraphRange16(painted->text, job->caretUtf16, lo, hi);
            if (lo < hi) {
                uint32_t firstLo = 0, firstHi = 0, lastLo = 0, lastHi = 0;
                if (!cjguiOhosGraphemeRange16(painted->text, lo, firstLo, firstHi) ||
                    !cjguiOhosGraphemeRange16(painted->text, hi - 1, lastLo, lastHi)) {
                    job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
                    return;
                }
                lo = firstLo; hi = lastHi;
            }
            job->wordStart = lo; job->wordEnd = hi;
            RLOGI("paragraph hit painted serial=%{public}llu range=%{public}u:%{public}u",
                  static_cast<unsigned long long>(painted->serial), lo, hi);
        }
        job->caretAffinity = affinity;
        job->paintSerial = painted->serial;
        job->sourcePaintTicket = painted->basePresentTicket;
        RLOGI("caret hit painted serial=%{public}llu session=%{public}llu ticket=%{public}llu context=%{public}lld caret=%{public}u affinity=%{public}d",
            static_cast<unsigned long long>(painted->serial), static_cast<unsigned long long>(painted->session),
            static_cast<unsigned long long>(painted->basePresentTicket), static_cast<long long>(job->contextId),
            job->caretUtf16, affinity);
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
        TextPaintFrame paintFrame{job->session, job->ticketId, job->projectionVersion, nullptr};
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
        // 节点几何是布局 vp、surface 缓冲是物理 px，所以整帧放大一次 density。
        // SurfaceGetCanvas 返回的是 surface 自己的 canvas，矩阵跨帧保留：不配对
        // Save/Restore 的话每次 present/redraw 都会再乘一次，两帧后整帧按 density²
        // 绘制（实测 3.5 密度下 18vp 正文行距 257px、超出右边界被裁掉）。
        OH_Drawing_CanvasSave(canvas);
        if (surfaceDensity > 0.0 && surfaceDensity != 1.0) {
            OH_Drawing_CanvasScale(canvas, static_cast<float>(surfaceDensity),
                                   static_cast<float>(surfaceDensity));
        }
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
                drawNodeText(canvas, n, paintFrame);
            }
            OH_Drawing_CanvasRestore(canvas);
        }
        g_pcCalls.drawExit.fetch_add(1);
        OH_Drawing_CanvasRestore(canvas);   // 归还本帧的 density 变换（矩阵跨帧保留）
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
            invalidatePaintedLayout(job->session);
            RLOGW("SurfaceFlush error=%{public}d", static_cast<int>(flush));
            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);
            return;
        }
        RLOGI("present frame ok (nodes=%{public}zu) layouts=%{public}llu layoutBytes=%{public}llu", job->nodes.size(),
            static_cast<unsigned long long>(textLayoutsBuilt), static_cast<unsigned long long>(textLayoutInputBytes));
        publishPaintedLayout(paintFrame);
        lastNodes = job->nodes;
        lastFrameTicket = job->ticketId;
        lastProjectionVersion = job->projectionVersion;
        lastFrameSession = job->session;
        lastFrameGeneration = job->generation;
        lastFrameWindow = job->window;
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
        invalidatePaintedLayout(lastPaintLayout ? lastPaintLayout->session : lastFrameSession);
        lastPaintLayout.reset();  // including same-generation surface rebuild/resize
        const uint64_t tornGeneration = boundGeneration;
        if (terminalGeneration) {
            hasLastFrame = false;
            lastNodes.clear();
            lastFrameSession = 0;
            lastFrameGeneration = 0;
            lastFrameWindow = nullptr;
            lastFrameTicket = 0;
        }
        if (surface) {
            destroyBoundHandle(surface, surfaceBackend, tornGeneration);
            surface = nullptr;
            surfaceBackend = SurfaceBackend::None;
        }
        boundWindow = nullptr;
        boundGeneration = 0;
        surfaceW = 0;
        surfaceH = 0;
        surfaceDensity = 1.0;
        // A2 顺序不可颠倒：先归还使用许可（证明本线程已不再使用该代），
        // 再回传拆除确认；宿主收到确认后才归还 NativeWindow 引用。
        // 先归还引用会让「确认到达之前的任何平台访问」失去引用保护。
        releaseSurfacePermit();
        if (terminalGeneration) notifyTornDown(tornGeneration);
    }

    // 绑定 surface 时冻结同一代次的逻辑密度：ingress 租约是 surface 事实的唯一
    // 来源，代次或窗口对不上就保持 1.0（旧行为），绝不拿别的代次的密度绘制。
    double liveSurfaceDensity(void *window, uint64_t generation) {
        if (g_ingress.surfaceActive == nullptr) return 1.0;
        void *liveWindow = nullptr;
        uint64_t liveGeneration = 0, liveRevision = 0;
        int32_t liveW = 0, liveH = 0;
        double liveDensity = 1.0;
        if (g_ingress.surfaceActive(&liveWindow, &liveGeneration, &liveW, &liveH,
                                    &liveDensity, &liveRevision) != 1 ||
            liveWindow != window || liveGeneration != generation ||
            !std::isfinite(liveDensity) || liveDensity <= 0.0) {
            return 1.0;
        }
        return liveDensity;
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
        surfaceDensity = liveSurfaceDensity(window, generation);
#ifdef CJGUI_OHOS_TEST_GATES
        g_gateCreateOkCount += 1;
#endif
        RLOGI("surface bound gen=%{public}llu %{public}dx%{public}d density=%{public}.3f backend=%{public}d",
              static_cast<unsigned long long>(generation), w, h, surfaceDensity,
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

    void drawNodeText(OH_Drawing_Canvas *canvas, const SceneNode &node, TextPaintFrame &frame)
    {
        const uint64_t frameSession = frame.session;
        uint32_t kind = node.pod.nodeKind;
        bool hasText = kind == kKindText || kind == kKindButton || kind == kKindTextInput ||
            kind == kKindIntegerInput || kind == kKindBooleanInput || kind == kKindMultiline;
        if (!hasText) return;
        uint32_t textColor = packColor(node.pod.textRed, node.pod.textGreen, node.pod.textBlue,
                                       node.pod.textAlpha);
        std::string text = displayTextForNode(node);
        bool isEditingNode = false;
        bool showCaret = false;
        bool showHandles = false;
        int64_t caretContext = 0;
        int32_t caretAffinity = 0;
        const bool foreground = !g_ingress.foregroundLevel || g_ingress.foregroundLevel() == 1;
        std::u16string editComposed;
        uint32_t selStartUtf16 = 0;
        uint32_t selEndUtf16 = 0;
        uint32_t caretUtf16 = 0;
        {
            std::lock_guard<std::mutex> g(g_sessions.lock);
            // 绘制当前会话的编辑视图：渲染线程是编辑缓冲绘制归属方；
            // 只有绑定本节点的活跃编辑覆盖静态 value。
            for (size_t i = 0; i < kMaxSessions; ++i) {
                Session &sess = g_sessions.sessions[i];
                if (sess.inUse && sess.token == frameSession && sess.editing &&
                    sess.editingNodeId == node.pod.nodeId && sess.editingResourceId == node.pod.resourceId &&
                    sess.editingNodeKind == node.pod.nodeKind) {
                    // Match binding continuity across the legal Flush→accepted
                    // interval, without borrowing another Session or requiring
                    // equality with a projection not yet settled by the owner.
                    bool sameBinding = false;
                    for (const SceneNode &accepted : sess.accepted) {
                        if (accepted.pod.nodeId == node.pod.nodeId && accepted.pod.resourceId == node.pod.resourceId &&
                            accepted.pod.nodeKind == node.pod.nodeKind && node.pod.acceptedBindingEpoch != 0 &&
                            accepted.pod.acceptedBindingEpoch == node.pod.acceptedBindingEpoch) {
                            sameBinding = true;
                            break;
                        }
                    }
                    if (!sameBinding) break;
                    // 逻辑编辑已结束（retired）时本地缓冲只用来补核心「本地文字延续」
                    // 窗口内的空投影（约定由原生编辑器绘制该节点）。一旦 accepted 已经
                    // 给出这个节点的值，那就是 owner 的裁决——包括本地编辑被拒、owner
                    // 保留外部值的情形——不得再被本地缓冲遮盖，否则一次被拒的提交会
                    // 让字段持续显示那个草稿。
                    // C：本地文字延续窗口由显式旗标（preservesActiveLocalText）
                    // 判定——accepted 值为空只是业务空值，不得推断为延续窗口。
                    if (sess.editorRetired && node.pod.preservesActiveLocalText == 0) break;
                    isEditingNode = true;
                    editComposed = composedBuffer(sess);
                    text = utf16ToUtf8(editComposed);
                    if (text.empty()) text = " ";  // 空缓冲也绘制光标
                    // 选区只取事实；高亮在字形排版（同一原点/行高）之后绘制，
                    // 否则框与字符来自两个不同的 y 基线。
                    selStartUtf16 = std::min(sess.selStartUtf16, sess.selEndUtf16);
                    selEndUtf16 = std::max(sess.selStartUtf16, sess.selEndUtf16);
                    caretUtf16 = std::min(sess.caretUtf16, static_cast<uint32_t>(editComposed.size()));
                    caretAffinity = sess.caretAffinity;
                    caretContext = sess.editingContextId;
                    showCaret = foreground && !sess.editorRetired && sess.editingContextLive &&
                        selStartUtf16 == selEndUtf16 && (sess.caretBlinkResetPending || sess.caretBlinkVisible);
                    showHandles = foreground && !sess.editorRetired && sess.editingContextLive &&
                        !sess.previewActive && selStartUtf16 < selEndUtf16;
                    break;
                }
            }
        }
        if (text.empty()) return;
        if (isEditingNode) frame.candidate.reset();
        Measured m = layoutTextStyled(text, node.pod.fontSize, node.pod.fontWeight,
                                       static_cast<double>(node.pod.width), false, textColor,
                                       node.textStyleRuns.data(), node.textStyleRuns.size());
        if (!m.typography) return;
        TextGeometry geom = computeTextGeometry(static_cast<double>(node.pod.x),
                                                static_cast<double>(node.pod.y),
                                                static_cast<double>(node.pod.height), kind, m,
                                                node.pod.fontSize);
        // 选区高亮先画（字形压在上面），矩形与字形出自同一排版对象。
        if (isEditingNode && selEndUtf16 > selStartUtf16) {
            drawSelectionBoxes(canvas, m.typography, selStartUtf16, selEndUtf16, geom);
        }
        OH_Drawing_TypographyPaint(m.typography, canvas, geom.originX, geom.originY);
        if (isEditingNode) {
            auto painted = std::make_unique<PaintedTextLayout>();
            painted->typography.reset(m.typography);
            painted->node = node.pod;
            painted->text = editComposed;
            painted->session = frame.session;
            painted->basePresentTicket = frame.ticket;
            painted->projectionVersion = frame.projectionVersion;
            painted->renderEpoch = renderEpoch;
            painted->serial = ++textPaintSerial;
            painted->paintContext = caretContext;
            painted->window = boundWindow;
            painted->generation = boundGeneration;
            painted->geometryRevision = permitGeometryRevision;
            painted->width = surfaceW;
            painted->height = surfaceH;
            painted->density = surfaceDensity;
            painted->relativeOriginX = geom.originX - static_cast<double>(node.pod.x);
            painted->relativeOriginY = geom.originY - static_cast<double>(node.pod.y);
            {
                double sx = 0, st = 0, sb = 0, ex = 0, et = 0, eb = 0;
                if (caretRectFor(m.typography, selStartUtf16, editComposed, 1, sx, st, sb) &&
                    caretRectFor(m.typography, selEndUtf16, editComposed, 0, ex, et, eb)) {
                    auto &h = painted->handles;
                    h.session = frame.session; h.nodeId = node.pod.nodeId;
                    h.resource = node.pod.resourceId; h.kind = node.pod.nodeKind;
                    h.binding = node.pod.acceptedBindingEpoch; h.ticket = frame.ticket;
                    h.projection = frame.projectionVersion; h.context = caretContext;
                    h.generation = boundGeneration; h.geometryRevision = permitGeometryRevision;
                    h.start = selStartUtf16; h.end = selEndUtf16; h.text = editComposed;
                    h.startX = geom.originX + sx; h.startY = geom.originY + st - 8;
                    h.endX = geom.originX + ex; h.endY = geom.originY + eb + 8;
                    h.startLineY = geom.originY + (st + sb) / 2;
                    h.endLineY = geom.originY + (et + eb) / 2;
                    h.startVisible = pointInsideClips(node.pod, h.startX, h.startY);
                    h.endVisible = pointInsideClips(node.pod, h.endX, h.endY);
                    h.valid = h.startVisible || h.endVisible;
                    if (showHandles) {
                    OH_Drawing_Brush *brush = OH_Drawing_BrushCreate();
                    OH_Drawing_BrushSetAntiAlias(brush, true);
                    OH_Drawing_BrushSetColor(brush, packColor(0.0, 0.45, 1.0, 1.0));
                    OH_Drawing_CanvasAttachBrush(canvas, brush);
                    for (int edge = 0; edge < 2; ++edge) {
                        const double cx = edge == 0 ? h.startX : h.endX;
                        const double cy = edge == 0 ? h.startY : h.endY;
                        const double top = geom.originY + (edge == 0 ? st : et);
                        const double bottom = geom.originY + (edge == 0 ? sb : eb);
                        OH_Drawing_Rect *stem = OH_Drawing_RectCreate(cx - 1, std::min(cy, top),
                            cx + 1, std::max(cy, bottom));
                        OH_Drawing_CanvasDrawRect(canvas, stem);
                        OH_Drawing_RectDestroy(stem);
                        OH_Drawing_Point *centre = OH_Drawing_PointCreate(cx, cy);
                        OH_Drawing_CanvasDrawCircle(canvas, centre, 6);
                        OH_Drawing_PointDestroy(centre);
                    }
                    OH_Drawing_CanvasDetachBrush(canvas);
                    OH_Drawing_BrushDestroy(brush);
                    RLOGI("selection handles painted ctx=%{public}lld range=%{public}u:%{public}u start=(%{public}.3f,%{public}.3f) end=(%{public}.3f,%{public}.3f)",
                        static_cast<long long>(caretContext), h.start, h.end, h.startX, h.startY, h.endX, h.endY);
                    }
                }
            }
            frame.candidate = std::move(painted);
            RLOGI("text layout painted serial=%{public}llu ctx=%{public}lld ticket=%{public}llu node=%{public}llu units=%{public}zu",
                static_cast<unsigned long long>(frame.candidate->serial), static_cast<long long>(caretContext),
                static_cast<unsigned long long>(frame.ticket), static_cast<unsigned long long>(node.pod.nodeId), editComposed.size());
        }
        // 光标（仅编辑节点；矩形由排版给出，落在真正被命中的那一行）
        if (isEditingNode && showCaret) {
            const uint32_t caret = caretUtf16;
            double caretX = 0.0;
            double caretTop = 0.0;
            double caretBottom = geom.lineHeight;
            if (!caretRectFor(m.typography, caret, editComposed, caretAffinity,
                              caretX, caretTop, caretBottom)) {
                // 拒答不能变成首行 longestLine 的假落点；正文仍照常绘制。
                RLOGW("caret geometry unavailable caret=%{public}u units=%{public}zu", caret, editComposed.size());
                if (!isEditingNode) OH_Drawing_DestroyTypography(m.typography);
                return;
            }
            RLOGI("caret geometry session=%{public}llu ctx=%{public}lld caret=%{public}u affinity=%{public}d "
                "x=%{public}.3f top=%{public}.3f bottom=%{public}.3f",
                static_cast<unsigned long long>(frameSession), static_cast<long long>(caretContext), caret,
                caretAffinity, geom.originX + caretX, geom.originY + caretTop, geom.originY + caretBottom);
            OH_Drawing_Brush *cb = OH_Drawing_BrushCreate();
            OH_Drawing_BrushSetColor(cb, packColor(0.65, 0.85, 1.0, 1.0));
            OH_Drawing_CanvasAttachBrush(canvas, cb);
            OH_Drawing_Rect *caretRect = OH_Drawing_RectCreate(
                static_cast<float>(geom.originX + caretX - 1.0),
                static_cast<float>(geom.originY + caretTop),
                static_cast<float>(geom.originX + caretX + 1.0),
                static_cast<float>(geom.originY + caretBottom));
            OH_Drawing_CanvasDrawRect(canvas, caretRect);
            OH_Drawing_RectDestroy(caretRect);
            OH_Drawing_CanvasDetachBrush(canvas);
            OH_Drawing_BrushDestroy(cb);
        }
        if (!isEditingNode) OH_Drawing_DestroyTypography(m.typography);
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
        return layoutTextStyled(text, fontSize, fontWeight, constraintWidth, unlimitedWidth,
                                textColor, nullptr, 0);
    }

    Measured layoutTextStyled(const std::string &text, double fontSize, uint32_t fontWeight,
                              double constraintWidth, bool unlimitedWidth, uint32_t textColor,
                              const OhosTextStyleRun *runs, size_t runCount)
    {
        Measured result;
        OH_Drawing_TypographyStyle *style = OH_Drawing_CreateTypographyStyle();
        OH_Drawing_TypographyCreate *handler =
            OH_Drawing_CreateTypographyHandler(style, OH_Drawing_GetFontCollectionGlobalInstance());
        OH_Drawing_DestroyTypographyStyle(style);
        if (!handler) return result;
        const char *family = "HarmonyOS Sans";
        auto pushBase = [&]() {
            OH_Drawing_TextStyle *st = OH_Drawing_CreateTextStyle();
            OH_Drawing_SetTextStyleFontSize(st, fontSize);
            OH_Drawing_SetTextStyleFontWeight(st, mapWeight(fontWeight));
            // 共同定义的前景色由节点携带，后端不重新指定颜色。
            OH_Drawing_SetTextStyleColor(st, textColor);
            OH_Drawing_SetTextStyleFontFamilies(st, 1, &family);
            OH_Drawing_TypographyHandlerPushTextStyle(handler, st);
            return st;
        };
        auto pushRun = [&](const OhosTextStyleRun &run) {
            OH_Drawing_TextStyle *st = OH_Drawing_CreateTextStyle();
            OH_Drawing_SetTextStyleFontSize(st, run.fontSize > 0 ? run.fontSize : fontSize);
            OH_Drawing_SetTextStyleFontWeight(st, mapWeight(run.fontWeight));
            OH_Drawing_SetTextStyleColor(st, packColor(run.red, run.green, run.blue, run.alpha));
            OH_Drawing_SetTextStyleFontFamilies(st, 1, &family);
            if (run.fontFamily == 2 || run.fontFamily == 3) {
                // 斜体（system-italic / monospaced-italic）；等宽族见下方回退注记。
                OH_Drawing_SetTextStyleFontStyle(st, FONT_STYLE_ITALIC);
            }
            if (run.hasBackground) {
                OH_Drawing_Brush *bg = OH_Drawing_BrushCreate();
                OH_Drawing_BrushSetColor(bg, packColor(run.bgRed, run.bgGreen, run.bgBlue, run.bgAlpha));
                OH_Drawing_SetTextStyleBackgroundBrush(st, bg);
                OH_Drawing_BrushDestroy(bg);
            }
            OH_Drawing_TypographyHandlerPushTextStyle(handler, st);
            return st;
        };
        // 按 UTF-16 边界切段（runs 已排序且不重叠）；间隙用基础样式。
        if (runs == nullptr || runCount == 0) {
            OH_Drawing_TextStyle *st = pushBase();
            OH_Drawing_TypographyHandlerAddText(handler, text.c_str());
            OH_Drawing_TypographyHandlerPopTextStyle(handler);
            OH_Drawing_DestroyTextStyle(st);
        } else {
            const std::u16string u16 = utf8ToUtf16(text);
            uint32_t cursor = 0;
            for (size_t i = 0; i < runCount; ++i) {
                const uint32_t rs = std::min(runs[i].start, static_cast<uint32_t>(u16.size()));
                const uint32_t re = std::min(runs[i].end, static_cast<uint32_t>(u16.size()));
                if (re <= rs) continue;
                if (rs > cursor) {
                    OH_Drawing_TextStyle *st = pushBase();
                    OH_Drawing_TypographyHandlerAddText(handler,
                        utf16ToUtf8(u16.substr(cursor, rs - cursor)).c_str());
                    OH_Drawing_TypographyHandlerPopTextStyle(handler);
                    OH_Drawing_DestroyTextStyle(st);
                }
                OH_Drawing_TextStyle *st = pushRun(runs[i]);
                OH_Drawing_TypographyHandlerAddText(handler,
                    utf16ToUtf8(u16.substr(rs, re - rs)).c_str());
                OH_Drawing_TypographyHandlerPopTextStyle(handler);
                OH_Drawing_DestroyTextStyle(st);
                cursor = re;
            }
            if (cursor < u16.size()) {
                OH_Drawing_TextStyle *st = pushBase();
                OH_Drawing_TypographyHandlerAddText(handler,
                    utf16ToUtf8(u16.substr(cursor)).c_str());
                OH_Drawing_TypographyHandlerPopTextStyle(handler);
                OH_Drawing_DestroyTextStyle(st);
            }
        }
        result.typography = OH_Drawing_CreateTypography(handler);
        OH_Drawing_DestroyTypographyHandler(handler);
        if (!result.typography) return result;
        double layoutWidth = unlimitedWidth ? 1000000.0 : constraintWidth;
        if (layoutWidth < 1.0) layoutWidth = 1.0;
        OH_Drawing_TypographyLayout(result.typography, layoutWidth);
        textLayoutsBuilt += 1;
        textLayoutInputBytes += text.size();
        result.height = OH_Drawing_TypographyGetHeight(result.typography);
        result.longestLine = OH_Drawing_TypographyGetLongestLine(result.typography);
        result.maxWidth = OH_Drawing_TypographyGetMaxWidth(result.typography);
        result.lineCount = OH_Drawing_TypographyGetLineCount(result.typography);
        result.alphabeticBaseline = OH_Drawing_TypographyGetAlphabeticBaseline(result.typography);
        return result;
    }

    /// 文本盒几何的唯一来源：字形绘制、光标矩形、选区高亮与触摸命中都按这里
    /// 算出的原点定位。此前每处各算一次（高亮按 pod.y、字形按盒内居中、命中只有 x），
    /// 结果是多行正文里"点中的行"和"看到的行"不是同一行。
    struct TextGeometry {
        double originX = 0.0;
        double originY = 0.0;
        double lineHeight = 0.0;
        double textHeight = 0.0;
    };

    TextGeometry computeTextGeometry(double nodeX, double nodeY, double nodeHeight, uint32_t kind,
                                     const Measured &m, double fontSize)
    {
        const double inset = (kind == kKindText) ? kTextInsetSingleLine : kTextInsetMultiline;
        TextGeometry g;
        g.textHeight = m.height;
        g.lineHeight = m.lineCount > 0 ? m.height / static_cast<double>(m.lineCount) : fontSize * 1.2;
        g.originX = nodeX + inset;
        g.originY = nodeY + inset;
        // 正文（多行编辑节点）从节点上沿开始排版；只有单行 label/button 才在盒内垂直居中，
        // 居中会把一段短文档推到画面正中。
        if (kind != kKindMultiline && m.height < nodeHeight) {
            g.originY = nodeY + (nodeHeight - m.height) / 2.0;
        }
        return g;
    }

    /// 某个码元位置的光标矩形（排版给出的 x 与该行上下沿）；排版答不出时返回 false。
    bool caretRectFor(OH_Drawing_Typography *typography, uint32_t caret, const std::u16string &text, int32_t affinity,
                      double &x, double &top, double &bottom)
    {
        if (text.empty()) {
            x = top = 0.0;
            bottom = OH_Drawing_TypographyGetHeight(typography);
            return std::isfinite(bottom) && bottom > top;
        }
        caret = std::min(caret, static_cast<uint32_t>(text.size()));
        const bool afterNewline = caret > 0 && (text[caret - 1] == u'\n' || text[caret - 1] == u'\r');
        // 尾部硬换行的盒属于上一行。实际 API24 对照证明最后一条行指标
        // 保留了新空行的 y/height；这里仅消费同一个排版对象，最低构建 API24。
        if (afterNewline && caret == text.size()) {
            const size_t lines = OH_Drawing_TypographyGetLineCount(typography);
            OH_Drawing_LineMetrics line{};
            if (lines == 0 || !OH_Drawing_TypographyGetLineMetricsAt(typography,
                static_cast<int>(lines - 1), &line) || !std::isfinite(line.x) ||
                !std::isfinite(line.y) || !std::isfinite(line.height) || line.height <= 0) return false;
            x = line.x;
            top = line.y;
            bottom = line.y + line.height;
            return true;
        }
        const bool leading = caret == 0 || afterNewline || (affinity == 1 && caret < text.size());
        const uint32_t offset = leading ? caret : caret - 1;
        uint32_t start = 0, end = 0;
        if (!cjguiOhosGraphemeRange16(text, offset, start, end)) return false;
        if ((leading && start != caret) || (!leading && end != caret)) return false;
        // GetRectsForRange 的单位是 UTF16，但半 surrogate/combining/ZWJ 不给
        // 文本框。查询完整平台字素，而不是 [caret-1,caret) 的单一码元。
        OH_Drawing_TextBox *box = OH_Drawing_TypographyGetRectsForRange(typography, start, end,
            RECT_HEIGHT_STYLE_TIGHT, RECT_WIDTH_STYLE_TIGHT);
        if (!box) return false;
        size_t count = OH_Drawing_GetSizeOfTextBox(box);
        if (count != 1) {
            OH_Drawing_TypographyDestroyTextBox(box);
            return false;
        }
        const int index = 0;
        const bool rtl = OH_Drawing_GetTextDirectionFromTextBox(box, index) == 0;
        x = (leading != rtl) ? OH_Drawing_GetLeftFromTextBox(box, index)
                             : OH_Drawing_GetRightFromTextBox(box, index);
        top = OH_Drawing_GetTopFromTextBox(box, index);
        bottom = OH_Drawing_GetBottomFromTextBox(box, index);
        OH_Drawing_TypographyDestroyTextBox(box);
        return std::isfinite(x) && std::isfinite(top) && std::isfinite(bottom) && bottom > top;
    }

    /// 选区高亮：逐段矩形直接取自 accepted 排版，因此跨行选区是每行一段，
    /// 而不是从选区起点宽度到终点宽度的一条整宽横杠。
    void drawSelectionBoxes(OH_Drawing_Canvas *canvas, OH_Drawing_Typography *typography,
                            uint32_t selStart, uint32_t selEnd, const TextGeometry &geom)
    {
        OH_Drawing_TextBox *boxes = OH_Drawing_TypographyGetRectsForRange(typography, selStart, selEnd,
            RECT_HEIGHT_STYLE_INCLUDELINESPACEMIDDLE, RECT_WIDTH_STYLE_TIGHT);
        if (!boxes) return;
        size_t count = OH_Drawing_GetSizeOfTextBox(boxes);
        if (count > 0) {
            OH_Drawing_Brush *hl = OH_Drawing_BrushCreate();
            OH_Drawing_BrushSetColor(hl, packColor(0.30, 0.50, 0.85, 0.35));
            OH_Drawing_CanvasAttachBrush(canvas, hl);
            for (size_t i = 0; i < count; ++i) {
                int index = static_cast<int>(i);
                float left = OH_Drawing_GetLeftFromTextBox(boxes, index);
                float right = OH_Drawing_GetRightFromTextBox(boxes, index);
                float top = OH_Drawing_GetTopFromTextBox(boxes, index);
                float bottom = OH_Drawing_GetBottomFromTextBox(boxes, index);
                if (right <= left) continue;   // 行尾空白等零宽段不画块
                OH_Drawing_Rect *rect = OH_Drawing_RectCreate(
                    static_cast<float>(geom.originX + left), static_cast<float>(geom.originY + top),
                    static_cast<float>(geom.originX + right), static_cast<float>(geom.originY + bottom));
                OH_Drawing_CanvasDrawRect(canvas, rect);
                OH_Drawing_RectDestroy(rect);
            }
            OH_Drawing_CanvasDetachBrush(canvas);
            OH_Drawing_BrushDestroy(hl);
        }
        OH_Drawing_TypographyDestroyTextBox(boxes);
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

bool selectionDragMatchesLocked(Session &s, const Session::SelectionDrag &drag);
static void recordHumanSelectionAnchorLocked(Session &, const char *);

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
    if (!s.gesture.shortTapCompleted) s.textTapChain.armed = false;
    s.gesture = Session::TouchGesture{};
    s.textPressBeginMs = 0;
    // END keeps its final coordinate alive until the single pending hit job
    // resolves. Every other cancellation releases the platform-notify gate.
    if (!s.selectionDrag.terminal) {
        if (s.selectionDrag.anchorReady && selectionDragMatchesLocked(s, s.selectionDrag))
            recordHumanSelectionAnchorLocked(s, "selection_drag_cancel");
        if (s.editingHitMode != 0) s.editingTapPending = false;
        s.selectionDrag = Session::SelectionDrag{};
    }
}

// 取消未完成的平台恢复请求（换绑/退役/结束/外部换版/截止到期/被新请求取代）。
// 取消后旧请求号不再被 ACK 接受：旧恢复串与旧落点都不得贴到新上下文或新节点上。
//
// recordIndex 的语义按 Astra 裁决收窄——终态只声明"本请求不得采纳"，不声明平台
// 没有发生安装：
//   1 = 尚未发送即终结：平台安装从未被执行；
//   2 = 已发送后超时/取消：安装未确认，禁止采纳（平台可能已发生部分安装）。
// 取消也必须回到窗口：窗口只在收到回执时才清掉待安装请求。若不通知，窗口会
// 一直以为"平台安装中"，同身份的后续恢复全部被去重跳过，输入门永久关闭
// （实测：代理尚未挂载时的 platform_install_failed 取消就是这样卡死的）。
static void terminateProxyRestoreRequestLocked(Session &s, const char *reason)
{
    // 已安装但窗口迟迟未采纳的票据同样受截止约束：不能留一张永远悬着的已安装票。
    if (!s.proxyRestore.armed && !s.proxyRestore.awaitingAck && !s.proxyRestore.platformInstalled) {
        return;
    }
    const Session::ProxyRestoreRequest cancelled = s.proxyRestore;
    // 事件侧窄口径：1=未执行平台安装，2=安装未确认（禁止采纳，不否认平台可能已装）。
    const uint32_t code = cancelled.sent ? 2u : 1u;
    const int32_t ticketState = cancelled.sent
        ? CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED
        : CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED;
    RLOGI("proxy restore terminated reason=%{public}s request=%{public}llu ctx=%{public}lld code=%{public}u",
          reason, static_cast<unsigned long long>(cancelled.requestId),
          static_cast<long long>(cancelled.contextId), code);
    s.proxyRestore = Session::ProxyRestoreRequest{};
    if (cancelled.requestId != 0 && !cancelled.reported) {
        Session::ProxyRestoreTerminal terminal;
        terminal.requestId = cancelled.requestId;
        terminal.code = ticketState;
        terminal.reason = reason;
        terminal.platformInstalled = cancelled.platformInstalled;
        terminal.observedStart = cancelled.observedStart;
        terminal.observedEnd = cancelled.observedEnd;
        s.proxyRestoreTerminals.push_back(terminal);
        if (s.proxyRestoreTerminals.size() > 8) {
            s.proxyRestoreTerminals.pop_front();
        }
        QueuedEvent ev;
        ev.kind = kEvTextProxyRestored;
        ev.recordIndex = code;
        ev.nodeId = cancelled.nodeId;
        ev.resourceId = cancelled.resourceId;
        ev.nodeKind = cancelled.nodeKind;
        ev.projectionVersion = cancelled.acceptedProjectionVersion;
        ev.acceptedBindingEpoch = cancelled.acceptedBindingEpoch;
        ev.bindingEpoch = cancelled.requestId;
        ev.text = reason;
        s.events.push_back(ev);
    }
}

// 旧调用点沿用同名入口。
static void cancelProxyRestoreRequest(Session &s, const char *reason)
{
    terminateProxyRestoreRequestLocked(s, reason);
}

// 冻结"人在 native 表面上亲手放置的落点"（命中测试 / 原生长按全选）。与平台回声
// 分开记账：回声属于安装观测流，锚属于人的导航事实。记录的同时在**同一临界区**
// 终结进行中的平台恢复票据——人的导航优先于恢复目标（Astra 人类优先表第 2 行），
// 否则窗口会一直等一张不可能装上的票据，人的输入被门禁挡住。
// 只冻结，不投递事件：窗口消费 kind-33 时按身份 + 值核验并一次性取走。
static void recordHumanSelectionAnchorLocked(Session &s, const char *origin)
{
    const SceneNode *acceptedNode = nullptr;
    for (const SceneNode &node : s.accepted) {
        if (node.pod.nodeId == s.editingNodeId &&
            node.pod.resourceId == s.editingResourceId &&
            node.pod.nodeKind == s.editingNodeKind &&
            node.pod.projectionVersion == s.editingProjectionVersion &&
            node.pod.acceptedBindingEpoch != 0) {
            acceptedNode = &node;
            break;
        }
    }
    if (!acceptedNode) {
        // 没有 accepted 绑定就没有可核验的身份：不伪造锚（窗口继续按既有门禁拒绝）。
        RLOGW("human anchor skipped: no accepted binding origin=%{public}s node=%{public}llu",
              origin, static_cast<unsigned long long>(s.editingNodeId));
        return;
    }
    s.humanAnchorSeq += 1;
    s.humanAnchor = Session::HumanSelectionAnchor{};
    s.humanAnchor.seq = s.humanAnchorSeq;
    s.humanAnchor.nodeId = acceptedNode->pod.nodeId;
    s.humanAnchor.resourceId = acceptedNode->pod.resourceId;
    s.humanAnchor.nodeKind = acceptedNode->pod.nodeKind;
    s.humanAnchor.projectionVersion = acceptedNode->pod.projectionVersion;
    s.humanAnchor.acceptedBindingEpoch = acceptedNode->pod.acceptedBindingEpoch;
    s.humanAnchor.start16 = std::min(s.selStartUtf16, s.selEndUtf16);
    s.humanAnchor.end16 = std::max(s.selStartUtf16, s.selEndUtf16);
    s.humanCaretNotificationPending = true;
    s.selForwardedValid = false;
    s.caretBlinkResetPending = true;
    RLOGI("human anchor recorded origin=%{public}s seq=%{public}llu node=%{public}llu "
          "sel=%{public}u:%{public}u",
          origin, static_cast<unsigned long long>(s.humanAnchor.seq),
          static_cast<unsigned long long>(s.humanAnchor.nodeId),
          s.humanAnchor.start16, s.humanAnchor.end16);
    terminateProxyRestoreRequestLocked(s, "human_anchor_supersedes");
}

// 换绑/换焦/退役：旧锚连同旧恢复票据一起退场，迟到的旧落点不得贴到新节点。
static void clearHumanSelectionAnchorLocked(Session &s)
{
    s.textMenuIntent = 0;
    s.humanAnchor = Session::HumanSelectionAnchor{};
    s.humanCaretNotificationPending = false;
    s.selectionOperationGeneration += 1;
    s.selectionHandles = PaintedSelectionHandles{};
    s.selectionDrag = Session::SelectionDrag{};
    if (s.editingHitMode != 0) s.editingTapPending = false;
}

// R1（Astra s2-identity-handoff）：统一收场出口。每个退役/结束入口都在冻结
// 旧身份的同一临界区调用；pump 按 FIFO 投递，旧身份之间互不覆盖。
static void pushPendingEndLocked(Session &s, int64_t contextId, const std::string &fieldName,
                                  bool settleOnDelivery)
{
    // 同一上下文的重复收场（多入口先后到达）只保留首条：结算语义恰好一次，
    // end 通知也只发一次。
    for (const Session::PendingEnd &e : s.pendingEnds) {
        if (e.contextId == contextId) return;
    }
    Session::PendingEnd entry;
    entry.contextId = contextId;
    entry.fieldName = fieldName;
    entry.settleOnDelivery = settleOnDelivery;
    s.pendingEnds.push_back(std::move(entry));
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
        pushPendingEndLocked(s, s.editingContextId, s.editingFieldName, true);
        // 上下文退役：未完成的恢复请求一并作废（旧回执不得再解任何锁）。
        cancelProxyRestoreRequest(s, "retired");
        clearHumanSelectionAnchorLocked(s);
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
    // R1（Astra s2-identity-handoff）：幂等与换绑都按**完整绑定身份**判定
    // （node/resource/kind/semantic/acceptedBindingEpoch）。只比 node/resource
    // 会让「同 id 换 epoch（对象重声明）」复用旧上下文与旧绑定（离线反例：
    // epoch 7→99 仍 context15/binding7）——同值同号不是同一对象。
    const bool sameBindingAsBefore = s.editingNodeId == node.pod.nodeId &&
        s.editingResourceId == node.pod.resourceId &&
        s.editingNodeKind == node.pod.nodeKind &&
        s.editingFieldName == node.semanticId &&
        s.editingAcceptedBindingEpoch == node.pod.acceptedBindingEpoch;
    // 仅 node/resource 相等（不含 epoch/kind/semantic）的历史语义：局部缓冲延续
    // 与选区保持只在**同一对象**上允许，换 epoch 后不再沿用。
    const bool sameNodeAsBefore = s.editingNodeId == node.pod.nodeId &&
        s.editingResourceId == node.pod.resourceId && sameBindingAsBefore;
    // C：同一有效绑定重复聚焦幂等——不换上下文编号，系统代理继续持旧编号，
    // 后续输入不会因换号被 stale 拒绝；caret 重定位由调用方按需触发。
    if (wasEditing && sameBindingAsBefore && s.editingContextLive) {
        return;
    }
    // 换绑/换焦：旧上下文号、旧字段与旧节点identity都要退场，旧恢复请求连同其
    // 待发正文/选区一并作废——否则"A 的恢复"会被贴到 B 的身份上。
    cancelProxyRestoreRequest(s, "rebind");
    clearHumanSelectionAnchorLocked(s);
    // C：跨字段/跨绑定切换——先按旧身份落实失焦语义（组合草稿折进缓冲并以旧
    // 身份交付 owner 恰好一次），再发布新上下文；旧编号从此失效（stale 拒绝），
    // 旧回调不可写入新字段。end 通知的身份在切换时冻结进待发队列，pump 不得
    // 读新字段。
    if (s.editing && !s.editorRetired && s.editingContextLive && !sameBindingAsBefore) {
        settleComposedBufferOnBlurLocked(s);
        pushPendingEndLocked(s, s.editingContextId, s.editingFieldName, false);
    }
    s.editing = true;
    s.editorRetired = false;          // 新交互：重新成为绘制方与回调接收方
    s.editingNodeId = node.pod.nodeId;
    s.editingResourceId = node.pod.resourceId;
    s.editingNodeKind = kind;
    s.editingProjectionVersion = node.pod.projectionVersion;
    s.editingAcceptedBindingEpoch = node.pod.acceptedBindingEpoch;
    // 通用编辑上下文：每次绑定新节点/同一节点重新聚焦都分配新编号，
    // 旧上下文的延迟回调（提交/预览/失焦）从此失效，不得改写新焦点。
    s.editingContextId = g_nextEditingContextId.fetch_add(1);
    s.caretBlinkResetPending = true;
    s.caretAffinity = 0;
    s.editingFieldName = node.semanticId;
    s.editingContextGeneration = s.surfaceGeneration;
    s.editingContextBaseVersion = node.pod.projectionVersion;
    s.editingContextLive = true;
    s.editingContextRevealRequested = false;  // 新上下文重置 reveal 请求
    s.reconcileNotifyPending = false;
    s.reconcileOldContextId = 0;
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
        // R3：**同一节点**重新聚焦时不得把选区重置成末尾 caret。切回源码、
        // 重新点正文、页面往返都会走这里；无条件重置正是"中段非空选区在双切换
        // 后折叠"的最根上来源（2026-10-01 实测：拖选后 ctx=1 为 [101,104)，
        // 重建会话后变 [104,104)）。按新正文长度收敛原选区并保持非空；只有
        // 换到**不同节点**、或新区间无法表达时才退化为末尾 caret。
        const uint32_t focusSize = static_cast<uint32_t>(s.editingText.size());
        bool keptSelection = false;
        if (sameNodeAsBefore && s.selEndUtf16 > s.selStartUtf16) {
            uint32_t keepStart = clampToCodePointBoundary(s.editingText,
                std::min(s.selStartUtf16, s.selEndUtf16));
            uint32_t keepEnd = clampToCodePointBoundary(s.editingText,
                std::max(s.selStartUtf16, s.selEndUtf16));
            if (keepStart > focusSize) keepStart = focusSize;
            if (keepEnd > focusSize) keepEnd = focusSize;
            if (keepEnd > keepStart) {
                s.caretUtf16 = keepEnd;
                s.selStartUtf16 = keepStart;
                s.selEndUtf16 = keepEnd;
                keptSelection = true;
                RLOGI("ime refocus keeps non-empty selection node=%{public}llu sel=%{public}u:%{public}u",
                      static_cast<long long>(node.pod.nodeId), keepStart, keepEnd);
            }
        }
        if (!keptSelection) {
            s.caretUtf16 = focusSize;
            s.selStartUtf16 = s.caretUtf16;
            s.selEndUtf16 = s.caretUtf16;
        }
        // 挂载时平台按上下文快照取初值，落点账本随之对齐：不给刚挂载的代理
        // 再推一条与快照重复的 caret 通知。
        s.selPlatformStart = s.selStartUtf16;
        s.selPlatformEnd = s.selEndUtf16;
        // 新上下文的第一条落点观测必须转发给窗口，即使它的值与旧上下文最后一次
        // 转发值相同：窗口需要"这个上下文已经装好落点"这条事实本身。
        s.selForwardedValid = false;
        s.previewActive = false;
        s.previewText.clear();
        s.focusNotifyPending = true;   // ArkTS TextInput 代理路径
    }
}

// Private visual gesture state. No document owner or editing protocol is added.
bool selectionDragMatchesLocked(Session &s, const Session::SelectionDrag &drag)
{
    if (!drag.active || drag.operation != s.selectionOperationGeneration ||
        !s.editing || !s.editingContextLive || s.editorRetired || s.previewActive ||
        drag.context != s.editingContextId || drag.nodeId != s.editingNodeId ||
        drag.resource != s.editingResourceId || drag.kind != s.editingNodeKind ||
        drag.projection != s.editingProjectionVersion || drag.generation != s.surfaceGeneration ||
        drag.geometryRevision != s.surfaceGeometryRevision || drag.text != composedBuffer(s)) return false;
    size_t index = 0;
    return sceneIndexByIdentityLocked(s, drag.nodeId, drag.resource, drag.kind, &index) &&
        drag.binding != 0 && s.accepted[index].pod.acceptedBindingEpoch == drag.binding;
}

void initializeSelectionDragLocked(Session &s, const SceneNode &node)
{
    s.selectionDrag = Session::SelectionDrag{};
    auto &d = s.selectionDrag;
    d.active = true; d.operation = ++s.selectionOperationGeneration;
    d.nodeId = node.pod.nodeId; d.resource = node.pod.resourceId; d.kind = node.pod.nodeKind;
    d.binding = node.pod.acceptedBindingEpoch; d.projection = s.editingProjectionVersion;
    d.context = s.editingContextId; d.text = composedBuffer(s);
    d.generation = s.surfaceGeneration; d.geometryRevision = s.surfaceGeometryRevision;
    d.app = s.gesture.appInstance; d.component = s.gesture.componentInstance;
    d.epoch = s.gesture.gestureEpoch; d.pointer = s.gesture.pointerId;
    d.lastX = s.gesture.startX; d.lastY = s.gesture.startY;
}

bool beginSelectionHandleDragLocked(Session &s, float x, float y)
{
    const auto &h = s.selectionHandles;
    if (!h.valid || h.session != s.token || h.ticket == 0 || h.ticket != s.acceptedPaintTicketId ||
        !s.editing || !s.editingContextLive || s.editorRetired || s.previewActive ||
        h.context != s.editingContextId || h.nodeId != s.editingNodeId ||
        h.resource != s.editingResourceId || h.kind != s.editingNodeKind ||
        h.projection != s.editingProjectionVersion || h.generation != s.surfaceGeneration ||
        h.geometryRevision != s.surfaceGeometryRevision || h.text != composedBuffer(s) ||
        h.start != std::min(s.selStartUtf16, s.selEndUtf16) ||
        h.end != std::max(s.selStartUtf16, s.selEndUtf16) || h.start >= h.end) return false;
    size_t index = 0;
    if (!sceneIndexByIdentityLocked(s, h.nodeId, h.resource, h.kind, &index) ||
        h.binding == 0 || s.accepted[index].pod.acceptedBindingEpoch != h.binding ||
        !RenderThread::pointInsideClips(s.accepted[index].pod, x, y)) return false;
    const double sd = std::hypot(x - h.startX, y - h.startY);
    const double ed = std::hypot(x - h.endX, y - h.endY);
    const bool start = h.startVisible && sd <= 14 && (!h.endVisible || ed > 14 || sd < ed);
    if (!start && !(h.endVisible && ed <= 14)) return false;
    const SceneNode &node = s.accepted[index];
    initializeSelectionDragLocked(s, node);
    auto &d = s.selectionDrag;
    d.anchorReady = true; d.anchor = start ? h.end : h.start;
    // Finger stays on the grip; the paragraph hit query follows its line centre.
    d.offsetX = (start ? h.startX : h.endX) - x;
    d.offsetY = (start ? h.startLineY : h.endLineY) - y;
    s.editingTapPending = false;
    s.gesture.phase = Session::TouchGesture::kGestureSelectionDrag;
    s.gesture.hasTarget = s.gesture.targetEditableText = true;
    s.gesture.targetNodeId = node.pod.nodeId; s.gesture.targetResourceId = node.pod.resourceId;
    s.gesture.targetNodeKind = node.pod.nodeKind; s.gesture.targetBindingEpoch = node.pod.acceptedBindingEpoch;
    s.gesture.targetProjectionVersion = node.pod.projectionVersion; s.gesture.targetSemanticId = node.semanticId;
    RLOGI("selection handle begin edge=%{public}s anchor=%{public}u epoch=%{public}llu",
        start ? "start" : "end", d.anchor, static_cast<unsigned long long>(d.epoch));
    return true;
}

bool queueSelectionExtentLocked(Session &s, float x, float y, bool terminal)
{
    if (!selectionDragMatchesLocked(s, s.selectionDrag)) return false;
    size_t index = 0;
    if (!sceneIndexByIdentityLocked(s, s.editingNodeId, s.editingResourceId, s.editingNodeKind, &index)) return false;
    const auto &node = s.accepted[index].pod;
    s.editingTapX = x + s.selectionDrag.offsetX - node.x;
    s.editingTapY = y + s.selectionDrag.offsetY - node.y;
    s.editingHitMode = 2; s.editingTapPending = true;
    s.selectionDrag.moved = true; s.selectionDrag.terminal = terminal;
    s.selectionDrag.lastX = x; s.selectionDrag.lastY = y;
    return true;
}

bool requestLongPressWordLocked(Session &s, int64_t nowMs)
{
    if (!s.gesture.active || !s.gesture.targetEditableText || s.gesture.thresholdLatch ||
        s.gesture.pressBeginMs <= 0 || nowMs - s.gesture.pressBeginMs < 400 ||
        s.previewActive || s.selectionDrag.active) return false;
    size_t index = 0;
    if (!sceneIndexByIdentityLocked(s, s.gesture.targetNodeId, s.gesture.targetResourceId,
        s.gesture.targetNodeKind, &index) || s.gesture.targetBindingEpoch == 0 ||
        s.accepted[index].pod.acceptedBindingEpoch != s.gesture.targetBindingEpoch) return false;
    const SceneNode &node = s.accepted[index];
    const bool focused = s.editing && s.editingContextLive && !s.editorRetired &&
        s.editingNodeId == node.pod.nodeId && s.editingResourceId == node.pod.resourceId;
    beginEditingOnNodeLocked(s, node);
    s.textTapChain.armed = false;
    s.gesture.longPressRecognized = true;
    if (s.editingText.empty()) {
        s.textMenuIntent = 2;
        s.editingTapPending = false;
        s.gesture.pressBeginMs = s.textPressBeginMs = 0;
        recordHumanSelectionAnchorLocked(s, "empty_hold");
        if (!focused) {
            QueuedEvent focus; focus.kind = kEvFocus; focus.recordIndex = static_cast<uint32_t>(index);
            focus.nodeId = node.pod.nodeId; focus.resourceId = node.pod.resourceId;
            focus.nodeKind = node.pod.nodeKind; focus.projectionVersion = node.pod.projectionVersion;
            focus.acceptedBindingEpoch = node.pod.acceptedBindingEpoch;
            stampTouchEvent(s, focus); s.events.push_back(focus);
        }
        g_render.post(std::make_shared<RedrawJob>());
        return true;
    }
    initializeSelectionDragLocked(s, node);
    s.selectionDrag.wordHold = true;
    s.gesture.phase = Session::TouchGesture::kGestureEditorHold;
    s.gesture.pressBeginMs = s.textPressBeginMs = 0; // trigger once
    s.editingTapX = s.gesture.startX - node.pod.x;
    s.editingTapY = s.gesture.startY - node.pod.y;
    s.editingHitMode = 1; s.editingTapPending = true; // replaces BEGIN's caret job
    if (!focused) {
        QueuedEvent focus;
        focus.kind = kEvFocus; focus.recordIndex = static_cast<uint32_t>(index);
        focus.nodeId = node.pod.nodeId; focus.resourceId = node.pod.resourceId;
        focus.nodeKind = node.pod.nodeKind; focus.projectionVersion = node.pod.projectionVersion;
        focus.acceptedBindingEpoch = node.pod.acceptedBindingEpoch;
        stampTouchEvent(s, focus); s.events.push_back(focus);
    }
    return true;
}

bool applySelectionHitLocked(Session &s, uint64_t operation, uint32_t mode, uint32_t caret,
                             int32_t affinity, uint32_t wordStart, uint32_t wordEnd)
{
    if (operation != s.selectionOperationGeneration) return false;
    if (mode != 0 && !selectionDragMatchesLocked(s, s.selectionDrag)) return false;
    caret = std::min(caret, static_cast<uint32_t>(s.editingText.size()));
    s.caretAffinity = affinity;
    if (mode == 1 || mode == 3) {
        if (wordStart > wordEnd || (mode == 1 && wordStart == wordEnd) || wordEnd > s.editingText.size()) return false;
        s.selStartUtf16 = wordStart; s.selEndUtf16 = wordEnd; s.caretUtf16 = wordEnd;
        s.selectionDrag.anchorReady = true; s.selectionDrag.anchor = wordStart;
        s.textMenuIntent = wordStart < wordEnd ? 1 : 0;
        recordHumanSelectionAnchorLocked(s, mode == 3 ? "triple_tap_paragraph" : "word_select");
        // 三击段落与长按选词是两种手势：日志标签按实际 mode 区分，修正此前把
        // 段落选择也标成 word/长按的误标（h-source-preview-next A）。
        RLOGI("selection applied mode=%{public}u gesture=%{public}s range=%{public}u:%{public}u",
              mode, mode == 3 ? "triple_tap_paragraph" : "long_press_word", wordStart, wordEnd);
        const bool terminal = s.selectionDrag.terminal;
        if (s.selectionDrag.moved) {
            queueSelectionExtentLocked(s, s.selectionDrag.lastX, s.selectionDrag.lastY, terminal);
        } else if (terminal) {
            s.selectionDrag = Session::SelectionDrag{};
        } else if (s.gesture.active && s.gesture.gestureEpoch == s.selectionDrag.epoch &&
                   s.gesture.pointerId == s.selectionDrag.pointer && s.gesture.appInstance == s.selectionDrag.app &&
                   s.gesture.componentInstance == s.selectionDrag.component) {
            s.gesture.phase = Session::TouchGesture::kGestureSelectionDrag;
        }
    } else if (mode == 2) {
        const uint32_t anchor = s.selectionDrag.anchor;
        s.selStartUtf16 = std::min(anchor, caret); s.selEndUtf16 = std::max(anchor, caret);
        s.caretUtf16 = caret;
        if (s.selectionDrag.terminal) {
            s.textMenuIntent = s.selStartUtf16 < s.selEndUtf16 ? 1 : 0;
            recordHumanSelectionAnchorLocked(s, "selection_drag_end");
            s.selectionDrag = Session::SelectionDrag{};
            // 拖选已经终结：同一手势**不得**再以 caret_hit（mode 0）结算一次
            // `editingTapPending`，否则紧随其后的那次落点处理会把刚确立的非空选区
            // 折成 caret（实测 `human anchor recorded origin=caret_hit sel=104:104`
            // 紧跟在 `selection_drag_end sel=101:104` 之后），推送与安装随之为折叠，
            // 会话源选区无锚可映射，外部改版后首笔输入退化为插入。
            s.editingTapPending = false;
            s.editingHitMode = 0;
        }
    } else {
        s.caretUtf16 = s.selStartUtf16 = s.selEndUtf16 = caret;
        recordHumanSelectionAnchorLocked(s, "caret_hit");
    }
    g_render.post(std::make_shared<RedrawJob>());
    return true;
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
    // B（复核修）：冻结绑定校验先于零尾差提前返回——同 node/resource 的
    // 换绑/ABA 即使尾差不足 1px（含 END 零尾差）也必须终结手势，旧 END
    // 不得借新绑定身份继续到 fling。视图/身份变化先于一切位移交付。
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
    int64_t whole = static_cast<int64_t>(s.gesture.scrollAccumY);  // 截断保余量
    if (whole == 0) return 0;
    s.gesture.scrollAccumY -= static_cast<float>(whole);
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
        // takeover 意图不是位移：不得被同手势的首段拖动合并覆盖（否则窗口
        // 收不到接管通知，空白按住的惯性停不下来）。
        if (sameSign && tail.text != "takeover:" && tail.kind == kEvScroll && tail.nodeId == nodeId &&
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
uint32_t consecutiveTextTapCountLocked(Session &s, const RawTouchSample &sample)
{
    const auto previous = std::move(s.textTapChain);
    s.textTapChain = Session::TextTapChain{}; // consume once, even if this press is later cancelled
    size_t index = 0;
    if (!previous.armed || !hitTestAccepted(s, sample.x, sample.y, &index) ||
        !s.editingContextLive || s.editorRetired || s.previewActive || s.markedActive) return 1;
    const auto &node = s.accepted[index].pod;
    const int64_t dt = sample.timestampNs - previous.endNs;
    if (sample.timestampNs <= 0 || previous.endNs <= 0 || dt < 0 || dt > 300000000 ||
        sample.timeSource != previous.timeSource ||
        std::hypot(sample.x - previous.x, sample.y - previous.y) > 60.0f ||
        previous.app != sample.appInstance || previous.component != sample.componentInstance ||
        previous.surface != sample.surfaceGeneration || previous.geometry != s.surfaceGeometryRevision ||
        previous.node != node.nodeId || previous.resource != node.resourceId || previous.kind != node.nodeKind ||
        previous.binding == 0 || previous.binding != node.acceptedBindingEpoch ||
        previous.context != s.editingContextId || previous.base != s.editingContextBaseVersion ||
        previous.text != s.editingText) return 1;
    return previous.count == 3 ? 1 : previous.count + 1;
}

void rememberTextTapLocked(Session &s, float x, float y)
{
    auto &g = s.gesture;
    if (!s.editingContextLive || s.editorRetired || s.previewActive || s.markedActive ||
        g.endNs <= g.beginNs || g.beginNs <= 0 || g.endNs - g.beginNs >= 400000000) return;
    auto &t = s.textTapChain;
    t.armed = true; t.count = g.tapCount; t.timeSource = g.timeSource; t.endNs = g.endNs;
    t.x = x; t.y = y; t.app = g.appInstance; t.component = g.componentInstance;
    t.surface = g.surfaceGeneration; t.geometry = s.surfaceGeometryRevision;
    t.node = g.targetNodeId; t.resource = g.targetResourceId; t.kind = g.targetNodeKind;
    t.binding = g.targetBindingEpoch; t.context = s.editingContextId;
    t.base = s.editingContextBaseVersion; t.text = s.editingText;
    g.shortTapCompleted = true;
}

bool collapsedCaretMenuHitLocked(const Session &s, float x, float y)
{
    const auto &h = s.selectionHandles;
    return s.editingContextLive && !s.editorRetired && !s.previewActive && !s.markedActive &&
        h.valid && h.startVisible && h.start == h.end && h.ticket != 0 &&
        h.ticket == s.acceptedPaintTicketId && h.context == s.editingContextId &&
        h.text == s.editingText && h.start == s.selStartUtf16 && h.end == s.selEndUtf16 &&
        h.generation == s.surfaceGeneration && h.geometryRevision == s.surfaceGeometryRevision &&
        h.projection == s.editingProjectionVersion &&
        std::fabs(x - h.startX) <= 10 && std::fabs(y - h.startLineY) <= 10;
}

bool requestConsecutiveTapSelectLocked(Session &s, const SceneNode &node)
{
    if (s.gesture.tapCount < 2 || s.previewActive || s.markedActive || s.editorRetired ||
        !s.editingContextLive || s.selectionDrag.active) return false;
    initializeSelectionDragLocked(s, node);
    s.selectionDrag.terminal = true;
    s.selectionDrag.wordHold = s.gesture.tapCount == 2;
    s.editingHitMode = s.gesture.tapCount == 2 ? 1 : 3;
    s.editingTapPending = true;
    RLOGI("text consecutive tap count=%{public}u mode=%{public}u context=%{public}lld",
          s.gesture.tapCount, s.editingHitMode, static_cast<long long>(s.editingContextId));
    return true;
}

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
        // S3（ACTIVATE 分发延迟追因）：入队侧行径——与出队行配对，缺出队行
        // 即队列未消费（pump 停摆），缺入队行即命中没走到按钮分支。
        RLOGI("activate enqueue node=%{public}llu projection=%{public}llu tap=(%{public}.0f,%{public}.0f) queue=%{public}zu",
              static_cast<unsigned long long>(ev.nodeId),
              static_cast<unsigned long long>(ev.projectionVersion), x, y, s.events.size());
        s.events.push_back(ev);
        return;
    }
    if (s.gesture.targetEditableText) {
        if (longPress && requestLongPressWordLocked(s, nowMs)) return;
        // 点击编辑器：直接激活本节点的平台编辑上下文并回发 FOCUS。不在此
        // 结束旧编辑上下文——pump 的 detach/end 通知按当前编辑状态取上下文，
        // 先 end 后 begin 会把旧字段的收场报成新字段（编辑器间切换维持
        // 既有语义：旧缓冲随新焦点初始化被替换，不经失焦结算）。
        const bool wasActive = s.editingContextLive && !s.editorRetired &&
            s.editingNodeId == node.pod.nodeId && s.editingResourceId == node.pod.resourceId;
        beginEditingOnNodeLocked(s, node);
        s.editingTapX = x - static_cast<double>(node.pod.x);   // 节点内相对坐标
        s.editingTapY = y - static_cast<double>(node.pod.y);
        s.editingTapPending = true;
        s.editingHitMode = 0;
        if (s.gesture.tapCount >= 2) {
            if (!requestConsecutiveTapSelectLocked(s, node)) return;
        } else if (s.gesture.caretMenuTap) {
            s.textMenuIntent = s.gesture.caretMenuShow ? 2 : 0;
        }
        rememberTextTapLocked(s, x, y);
        if (wasActive) return;
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
        // New BEGIN revokes an older in-flight visual hit, including a terminal
        // operation whose caller has not yet observed completion.
        const uint32_t tapCount = consecutiveTextTapCountLocked(s, sample);
        const bool caretMenuTap = tapCount == 1 && collapsedCaretMenuHitLocked(s, x, y);
        const bool caretMenuShow = s.textMenuIntent != 2;
        s.textMenuIntent = 0;
        s.selectionDrag = Session::SelectionDrag{};
        s.selectionOperationGeneration += 1;
        s.editingTapPending = false;
        s.gesture = Session::TouchGesture{};
        s.gesture.active = true;
        s.gesture.startX = s.gesture.lastX = x;
        s.gesture.startY = s.gesture.lastY = y;
        s.gesture.surfaceGeneration = sample.surfaceGeneration;
        s.gesture.gestureEpoch = sample.gestureEpoch;
        s.gesture.appInstance = sample.appInstance;
        s.gesture.componentInstance = sample.componentInstance;
        s.gesture.pointerId = sample.pointerId;
        s.gesture.tapCount = tapCount; s.gesture.beginNs = sample.timestampNs;
        s.gesture.timeSource = sample.timeSource;
        s.gesture.caretMenuTap = caretMenuTap; s.gesture.caretMenuShow = caretMenuShow;
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
            // H2（astra 空白接管）：新触摸落在视口内就要终结该视口的惯性活动——
            // 空白/只读内容根本不产生指针事件，窗口收不到 BEGIN。复用共同 scroll
            // 通道发 takeover 意图（无位移、携完整 GestureKey 与冻结绑定），核心按
            // 严格门校验后终结活动并发放释放票据；不伪造控件的 POINTER_BEGIN。
            QueuedEvent ev;
            ev.kind = kEvScroll;
            ev.nodeId = s.gesture.viewportNodeId;
            ev.resourceId = s.gesture.viewportResourceId;
            ev.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
            ev.projectionVersion = s.accepted[viewportIndex].pod.projectionVersion;
            ev.acceptedBindingEpoch = s.gesture.viewportBindingEpoch;
            ev.text = "takeover:";
            stampTouchEvent(s, ev);
            s.events.push_back(ev);
        }
        if (tapCount == 1 && beginSelectionHandleDragLocked(s, x, y)) return;
        size_t index = 0;
        if (!hitTestAccepted(s, x, y, &index)) {
            return;  // 空白/非交互内容：无点击目标；滚动仍由包含视口接管。
        }
        const SceneNode &node = s.accepted[index];
        if (node.pod.isReadOnly != 0) return;  // 只读内容可滚动，不可激活
        const uint32_t kind = node.pod.nodeKind;
        const bool isEditableText = isEditableTextKind(kind);
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
        if (isEditableText) s.gesture.pressBeginMs = nowMs;
        if (isEditableText && s.editing && !s.editorRetired &&
            s.editingNodeId == node.pod.nodeId && s.editingResourceId == node.pod.resourceId) {
            // Handle BEGIN was tested first. Ordinary touch places the caret;
            // a fast drag can still be taken by the existing viewport.
            s.gesture.phase = Session::TouchGesture::kGestureEditorHold;
            s.gesture.pressBeginMs = nowMs;
            s.textPressBeginMs = nowMs;
            s.editingTapX = x - static_cast<double>(node.pod.x);
            s.editingTapY = y - static_cast<double>(node.pod.y);
            s.editingTapPending = true;
            s.editingHitMode = 0;
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
        if (s.gesture.phase == Session::TouchGesture::kGestureSelectionDrag) {
            s.gesture.lastX = x; s.gesture.lastY = y;
            if (s.selectionDrag.wordHold && !s.selectionDrag.moved &&
                std::fabs(dx) < kTouchScrollThresholdPx && std::fabs(dy) < kTouchScrollThresholdPx) return;
            if (!queueSelectionExtentLocked(s, x, y, false)) cancelTouchGestureLocked(s);
            return;
        }
        if (s.gesture.phase == Session::TouchGesture::kGestureEditorHold ||
            (s.gesture.phase == Session::TouchGesture::kGesturePending && s.gesture.targetEditableText)) {
            requestLongPressWordLocked(s, nowMs);
            if (s.selectionDrag.active && s.selectionDrag.wordHold) {
                s.gesture.lastX = x; s.gesture.lastY = y;
                s.selectionDrag.lastX = x; s.selectionDrag.lastY = y;
                if (std::fabs(dx) >= kTouchScrollThresholdPx || std::fabs(dy) >= kTouchScrollThresholdPx)
                    s.selectionDrag.moved = true;
                return; // word job is still in the bounded pending slot
            }
            if (s.gesture.phase == Session::TouchGesture::kGestureEditorHold &&
                (std::fabs(dx) >= kTouchScrollThresholdPx || std::fabs(dy) >= kTouchScrollThresholdPx)) {
                s.gesture.phase = Session::TouchGesture::kGesturePending;
                s.editingTapPending = false;
                s.selectionOperationGeneration += 1;
                s.gesture.pressBeginMs = s.textPressBeginMs = 0;
            }
        }
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
            s.selectionDrag.terminal = false;
            cancelTouchGestureLocked(s);
            return;
        }
        const uint32_t phase = s.gesture.phase;
        s.gesture.endNs = sample.timestampNs;
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
                if (s.selectionDrag.active) s.selectionDrag.terminal = true;
                break;
            }
            case Session::TouchGesture::kGestureScroll: {
                // A：END 消费最后坐标差 + 浮点余量（同一采样入口，尾段不丢）。
                // B（复核修）：零尾差也先校验冻结绑定；换绑/ABA 已在入口取消
                // （gesture 复位），下列速度/发射必须只针对仍存活的手势。
                consumeScrollSampleLocked(s, y - s.gesture.lastY);
                if (!s.gesture.active) break;  // 绑定丢失：不估算、不发射活动
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
                                                    CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, &index) &&
                        s.gesture.viewportBindingEpoch != 0 &&
                        s.accepted[index].pod.acceptedBindingEpoch == s.gesture.viewportBindingEpoch) {
                        // B（复核修）：fling 携 BEGIN 时冻结的 viewport 绑定身份
                        // （不是当前节点重贴的版本）——同 node/resource 的旧 END
                        // 对换绑/ABA 后的新绑定不启动活动；核心以同一严格门比对。
                        char buf[48];
                        std::snprintf(buf, sizeof(buf), "fling:%.3f", velocity);
                        QueuedEvent ev;
                        ev.kind = kEvScroll;
                        ev.nodeId = s.gesture.viewportNodeId;
                        ev.resourceId = s.gesture.viewportResourceId;
                        ev.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
                        ev.projectionVersion = s.accepted[index].pod.projectionVersion;
                        ev.acceptedBindingEpoch = s.gesture.viewportBindingEpoch;
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
                requestLongPressWordLocked(s, nowMs);
                if (s.selectionDrag.active) {
                    s.gesture.lastX = x; s.gesture.lastY = y;
                    s.selectionDrag.lastX = x; s.selectionDrag.lastY = y;
                    s.selectionDrag.terminal = true;
                } else if (s.gesture.hasViewport &&
                    (std::fabs(x - s.gesture.startX) >= kTouchScrollThresholdPx ||
                     std::fabs(y - s.gesture.startY) >= kTouchScrollThresholdPx)) {
                    s.editingTapPending = false;
                    s.selectionOperationGeneration += 1;
                    consumeScrollSampleLocked(s, y - s.gesture.lastY);
                } else if (!s.gesture.longPressRecognized &&
                    std::fabs(x - s.gesture.startX) < kTouchScrollThresholdPx &&
                    std::fabs(y - s.gesture.startY) < kTouchScrollThresholdPx) {
                    executePendingTapLocked(s, x, y, nowMs);
                }
                break;
            case Session::TouchGesture::kGestureSelectionDrag:
                if (s.selectionDrag.wordHold && !s.selectionDrag.moved) {
                    s.textMenuIntent = s.selStartUtf16 < s.selEndUtf16 ? 1 : 0;
                    s.selectionDrag = Session::SelectionDrag{}; // retain the selected word
                } else if (!queueSelectionExtentLocked(s, x, y, true)) {
                    s.selectionDrag.terminal = false;
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

// 窗口声明拥有该节点的范围会话，且开启范围增量投递：只有这时整值事件被抑制、
// 精确范围增量成为权威通道。未声明的节点行为完全不变。
bool editorOwnsTextSession(const Session &s)
{
    return s.ownedTextSessionEnabled && s.rangeEditDeltaRequested &&
        s.editingNodeId == s.ownedTextSessionNodeId &&
        s.editingResourceId == s.ownedTextSessionResourceId &&
        s.editingNodeKind == s.ownedTextSessionNodeKind;
}

// H1-C：编辑缓冲的一次提交。窗口声明拥有该节点时，**精确范围增量**（kind 51）
// 是权威通道，整值事件（kind 28）被抑制：消费方只经会话的 Sink 写一次正文，
// 不会出现第二个写入者。未声明（或未开启范围增量）时行为完全不变。
// 系统 TextInput 代理只回调显示全文，所以增量由「已接受的编辑缓冲 → 新文本」
// 复算最小公共前后缀得到：结果文本逐字节等价，区间是它的一个合法表达。
//
// 代理对边界（复核反例）：逐码元取公共前后缀会在代理对中间切分——`😀→😁`
// 得到 `[1,2)` 加一个孤立低代理，`utf16ToUtf8` 又会把它编码成非法 UTF-8。
// 因此两端各自退/扩到**合法标量边界**后才生成替换；重放逐字节等于 next。
// 平台送来畸形 UTF-16（不成对代理）时无法表达成合法增量：具名拒绝、
// 恢复编辑缓冲、owner 零变化。返回 true 表示已交付一次 kind-51。
bool editorEnqueueTextCommit(Session &s, const std::u16string &previous, const std::u16string &next)
{
    if (previous != next) s.textMenuIntent = 0;
    const bool ownsNode = editorOwnsTextSession(s);
    if (!ownsNode || previous == next) {
        editorEnqueueTextChanged(s);
        return true;
    }
    size_t prefix = 0;
    const size_t shortest = std::min(previous.size(), next.size());
    while (prefix < shortest && previous[prefix] == next[prefix]) prefix += 1;
    // 前缀必须停在两串的标量边界上（两串前缀段相同，故两串判断同值）。
    if (prefix > 0 && !utf16IsScalarBoundary(previous, prefix)) prefix -= 1;
    size_t suffix = 0;
    const size_t remaining = shortest - prefix;
    while (suffix < remaining &&
           previous[previous.size() - 1 - suffix] == next[next.size() - 1 - suffix]) {
        suffix += 1;
    }
    size_t previousEnd = previous.size() - suffix;
    size_t nextEnd = next.size() - suffix;
    // 后缀起点同样必须合法；不合法就缩短后缀（扩大替换区，保持逐字节等价）。
    while (suffix > 0 &&
           (!utf16IsScalarBoundary(previous, previousEnd) || !utf16IsScalarBoundary(next, nextEnd))) {
        suffix -= 1;
        previousEnd = previous.size() - suffix;
        nextEnd = next.size() - suffix;
    }
    if (previousEnd < prefix) previousEnd = prefix;
    if (nextEnd < prefix) nextEnd = prefix;
    const std::u16string removed = previous.substr(prefix, previousEnd - prefix);
    const std::u16string inserted = next.substr(prefix, nextEnd - prefix);
    if (!utf16IsWellFormed(removed) || !utf16IsWellFormed(inserted)) {
        // 畸形输入：不制造非法增量，恢复编辑缓冲，owner 与本帧提交都保持原状。
        RLOGW("ime range delta refused: malformed_surrogate node=%{public}lld",
              static_cast<long long>(s.editingNodeId));
        s.editingText = previous;
        if (s.caretUtf16 > previous.size()) s.caretUtf16 = static_cast<uint32_t>(previous.size());
        s.caretUtf16 = clampToCodePointBoundary(previous, s.caretUtf16);
        s.selStartUtf16 = s.caretUtf16;
        s.selEndUtf16 = s.caretUtf16;
        return false;
    }
    if (previous != next) {
        s.caretBlinkResetPending = true;
        s.caretAffinity = 0;
    }
    QueuedEvent ev;
    ev.kind = kEvTextRangeChanged;  // 51
    ev.nodeId = s.editingNodeId;
    ev.projectionVersion = s.editingProjectionVersion;
    ev.resourceId = s.editingResourceId;
    ev.nodeKind = s.editingNodeKind;
    ev.selectionStart = static_cast<uint32_t>(prefix);
    ev.selectionEnd = static_cast<uint32_t>(previousEnd);
    ev.text = utf16ToUtf8(inserted);
    ev.bindingEpoch = s.ownedTextSessionBindingEpoch;
    s.events.push_back(ev);
    RLOGI("ime range delta node=%{public}lld range=%{public}u:%{public}u bytes=%{public}zu",
          static_cast<long long>(s.editingNodeId), ev.selectionStart, ev.selectionEnd, ev.text.size());
    return true;
}

// 平台落点观测要不要转发给窗口。判重只看"窗口已经收到过哪个观测"，绝不看 native
// 自己的 caret/推送目标：人点击正文时命中测试先把 native 落点写成命中值，平台装好
// 之后回声的正是同一个值，按 caret 判重会把这次回声整个吞掉（窗口收不到 kind-33，
// 人类锚只在 native 侧 recorded、永不 taken）。同一值不重复入队，避免自激。
static bool selectionObservationNeedsForwarding(const Session &s, uint32_t start, uint32_t end)
{
    return !s.selForwardedValid || s.selForwardedStart != start || s.selForwardedEnd != end;
}

static void rememberForwardedSelectionLocked(Session &s, uint32_t start, uint32_t end)
{
    s.selForwardedValid = true;
    s.selForwardedStart = start;
    s.selForwardedEnd = end;
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
    ev.editingContextId = s.editingContextId;
    ev.editingContextGeneration = s.editingContextGeneration;
    // Freeze the coordinate system of this actual observation, rather than
    // interpreting an earlier selection against a later accepted postimage.
    ev.text = utf16ToUtf8(composedBuffer(s));
    s.events.push_back(ev);
    return true;
}

static bool queuedSelectionContextIsCurrent(const Session &s, const QueuedEvent &ev)
{
    return ev.editingContextId != 0 && s.editingContextLive && !s.editorRetired &&
        ev.editingContextId == s.editingContextId &&
        ev.editingContextGeneration == s.editingContextGeneration;
}

// 失焦结算（框架主动结束编辑，恰好一次）：把当前未提交的组合预览折进编辑
// 缓冲并作为普通编辑变化交付 owner。语义与「点到别处即失焦提交」一致，且与
// 平台的提交路径互斥——tear 掉活上下文后平台再提交必然被拒，不会二次写。
// 无组合预览（预览未激活）时不产生任何事件：owner 里的值已经是最新的。
// 返回 true = 确实结算了一次（调用方用于留证）。
bool settleComposedBufferOnBlurLocked(Session &s)
{
    if (!s.previewActive) return false;
    const std::u16string previous = s.editingText;
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
    editorEnqueueTextCommit(s, previous, s.editingText);
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
    const std::u16string previous = s->editingText;
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
    editorEnqueueTextCommit(*s, previous, s->editingText);
}

void ImeDeleteForward(InputMethod_TextEditorProxy *proxy, int32_t length)
{
    (void)proxy;
    if (length <= 0) return;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    const std::u16string previous = s->editingText;
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
    editorEnqueueTextCommit(*s, previous, s->editingText);
}

void ImeDeleteBackward(InputMethod_TextEditorProxy *proxy, int32_t length)
{
    (void)proxy;
    if (length <= 0) return;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s) return;
    const std::u16string previous = s->editingText;
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
    editorEnqueueTextCommit(*s, previous, s->editingText);
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
    // R1：回车也是收场入口——冻结将死身份进待发队列，不得让 pump 回读
    // （此时可能已换绑的）当前上下文字段。
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (s && s->editing && !s->editorRetired) {
        pushPendingEndLocked(*s, s->editingContextId, s->editingFieldName, false);
    }
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
        s.ownedTextSessionEnabled = false;
        s.ownedTextSessionNodeId = 0;
        s.ownedTextSessionResourceId = -1;
        s.ownedTextSessionNodeKind = 0;
        s.ownedTextSessionBindingEpoch = 0;
        s.accepted.clear();
        s.acceptedProjectionVersion = 0;
        s.candidate.clear();
        s.acceptedRunTable.clear();
        s.buildingRunTable.clear();
        s.imageCompletionVersion = 0;
        s.imageObservedSerial.clear();
        s.candidateOpen = false;
        s.events.clear();
        s.gesture = Session::TouchGesture{};  // B：新实例不得继承旧手势状态
        s.editorRetired = false;
        s.pendingEnds.clear();
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
    s->rangeEditDeltaRequested = enabled != 0;
    RLOGI("range edit delta requested=%{public}d", s->rangeEditDeltaRequested ? 1 : 0);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// H1-C：窗口声明它拥有某个正文节点的范围会话。声明生效后，该节点的提交以
// **精确 UTF-16 范围增量**（kind 51）交付并带上绑定的代次；整值事件被抑制。
// 未声明的节点永不产生 kind 51——消费方不会在没有绑定的表面上 fail-closed。
// `bindingEpoch` 原样回传，供窗口拒绝换绑前入队的旧增量；`enabled` 为 false
// 时撤回声明（代次仍然记录：撤回本身也是一次绑定变化）。
extern "C" CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_owned_text_session(
    uint64_t session, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
    uint64_t bindingEpoch, uint32_t enabled)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (enabled != 0 && nodeId == 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    s->ownedTextSessionEnabled = enabled != 0;
    s->ownedTextSessionNodeId = enabled != 0 ? nodeId : 0;
    s->ownedTextSessionResourceId = enabled != 0 ? resourceId : -1;
    s->ownedTextSessionNodeKind = enabled != 0 ? nodeKind : 0;
    s->ownedTextSessionBindingEpoch = bindingEpoch;
    RLOGI("owned text session enabled=%{public}d node=%{public}llu epoch=%{public}llu",
          enabled != 0 ? 1 : 0, static_cast<unsigned long long>(s->ownedTextSessionNodeId),
          static_cast<unsigned long long>(bindingEpoch));
    return CJGUI_INTERNAL_RENDERER_OK;
}

// OHOS_GRAPHEME_SERVICE_BEGIN
// System ICU is the platform boundary oracle. Each call owns its library handle,
// immutable UTF-16 buffer and iterator; destruction closes the iterator before
// releasing the buffer/library. Missing symbols/rule data is a named refusal.
// UTF-8/UTF-16 mapping below maps scalars only, never implements UAX#29.
#ifndef CJGUI_OHOS_ICU_LIBRARY
#define CJGUI_OHOS_ICU_LIBRARY "libicu.so"
#endif
struct CjguiOhosIcuApi {
    void *handle = nullptr;
    decltype(&u_strFromUTF8) fromUtf8 = nullptr;
    decltype(&ubrk_open) open = nullptr;
    decltype(&ubrk_close) close = nullptr;
    decltype(&ubrk_isBoundary) isBoundary = nullptr;
    decltype(&ubrk_preceding) preceding = nullptr;
    decltype(&ubrk_following) following = nullptr;
    CjguiOhosIcuApi() {
        handle = dlopen(CJGUI_OHOS_ICU_LIBRARY, RTLD_NOW | RTLD_LOCAL);
        if (!handle) return;
        fromUtf8 = reinterpret_cast<decltype(fromUtf8)>(dlsym(handle, "u_strFromUTF8"));
        open = reinterpret_cast<decltype(open)>(dlsym(handle, "ubrk_open"));
        close = reinterpret_cast<decltype(close)>(dlsym(handle, "ubrk_close"));
        isBoundary = reinterpret_cast<decltype(isBoundary)>(dlsym(handle, "ubrk_isBoundary"));
        preceding = reinterpret_cast<decltype(preceding)>(dlsym(handle, "ubrk_preceding"));
        following = reinterpret_cast<decltype(following)>(dlsym(handle, "ubrk_following"));
    }
    ~CjguiOhosIcuApi() { if (handle) dlclose(handle); }
    bool ready() const { return fromUtf8 && open && close && isBoundary && preceding && following; }
    CjguiOhosIcuApi(const CjguiOhosIcuApi&) = delete;
    CjguiOhosIcuApi& operator=(const CjguiOhosIcuApi&) = delete;
};

extern "C" CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *utf8, uint64_t declaredLength, uint64_t offsetByte,
    uint64_t *outStartByte, uint64_t *outEndByte)
{
    if (outStartByte) *outStartByte = 0;
    if (outEndByte) *outEndByte = 0;
    if (!utf8 || !outStartByte || !outEndByte) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (declaredLength > static_cast<uint64_t>(INT32_MAX - 1)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    // The FFI caller owns a CString allocation. A NUL before the declared end,
    // or a different CString length, cannot stand in for the original bytes.
    if (strnlen(utf8, static_cast<size_t>(declaredLength + 1)) != declaredLength) {
        return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
    }
    if (offsetByte >= declaredLength) return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
    CjguiOhosIcuApi api;
    if (!api.ready()) return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
    try {
        UErrorCode error = U_ZERO_ERROR;
        int32_t units = 0;
        api.fromUtf8(nullptr, 0, &units, utf8, static_cast<int32_t>(declaredLength), &error);
        if (error != U_BUFFER_OVERFLOW_ERROR && U_FAILURE(error)) {
            return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
        }
        error = U_ZERO_ERROR;
        std::vector<UChar> text(static_cast<size_t>(units) + 1);
        api.fromUtf8(text.data(), static_cast<int32_t>(text.size()), &units, utf8,
                     static_cast<int32_t>(declaredLength), &error);
        if (U_FAILURE(error)) return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
        struct ScalarBoundary { uint64_t byte; int32_t unit; };
        std::vector<ScalarBoundary> boundaries;
        uint64_t byte = 0;
        int32_t unit = 0, targetUnit = -1;
        // ICU already strictly decoded these bytes; this only records each
        // scalar's byte/unit position, including a query inside its bytes.
        while (byte < declaredLength) {
            boundaries.push_back({byte, unit});
            const auto lead = static_cast<unsigned char>(utf8[byte]);
            const uint64_t size = lead < 0x80 ? 1 : (lead < 0xe0 ? 2 : (lead < 0xf0 ? 3 : 4));
            if (byte <= offsetByte && offsetByte < byte + size) targetUnit = unit;
            byte += size;
            unit += size == 4 ? 2 : 1;
        }
        boundaries.push_back({byte, unit});
        if (byte != declaredLength || unit != units || targetUnit < 0) {
            return CJGUI_INTERNAL_RENDERER_INVALID_UTF8;
        }
        error = U_ZERO_ERROR;
        std::unique_ptr<UBreakIterator, decltype(api.close)> iterator(
            api.open(UBRK_CHARACTER, "root", text.data(), units, &error), api.close);
        if (!iterator || U_FAILURE(error)) return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
        const int32_t start = api.isBoundary(iterator.get(), targetUnit) ? targetUnit :
                              api.preceding(iterator.get(), targetUnit);
        const int32_t end = api.following(iterator.get(), targetUnit);
        uint64_t startByte = UINT64_MAX, endByte = UINT64_MAX;
        for (const auto& boundary : boundaries) {
            if (boundary.unit == start) startByte = boundary.byte;
            if (boundary.unit == end) endByte = boundary.byte;
        }
        if (startByte > offsetByte || endByte <= offsetByte || endByte > declaredLength) {
            return CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID;
        }
        *outStartByte = startByte;
        *outEndByte = endByte;
        return CJGUI_INTERNAL_RENDERER_OK;
    } catch (...) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
}
// OHOS_GRAPHEME_SERVICE_END

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
    s->acceptedRunTable.clear();
    s->buildingRunTable.clear();
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

// surface 尺寸是物理 px，布局/命中/滚动都在 vp：对外视口与窗框只报 vp。
static int32_t physicalToLayout(int32_t physicalPixels, double density) {
    if (physicalPixels <= 0) return 0;
    if (!std::isfinite(density) || density <= 0.0) density = 1.0;
    return static_cast<int32_t>(std::llround(static_cast<double>(physicalPixels) / density));
}

CjguiInternalRendererStatus cjgui_internal_renderer_composable_viewport(uint64_t session, CjguiInternalRendererViewport *outViewport)
{
    if (!outViewport) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 以 ingress 的实时租约为准；无 surface 时保留最后已知尺寸与版本。
    cjguiOhosRefreshSurfaceLocked(s);
    outViewport->width = static_cast<uint32_t>(physicalToLayout(s->surfaceWidth, s->surfaceDensity));
    outViewport->height = static_cast<uint32_t>(physicalToLayout(s->surfaceHeight, s->surfaceDensity));
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
    *outWidth = physicalToLayout(s->surfaceWidth, s->surfaceDensity);
    *outHeight = physicalToLayout(s->surfaceHeight, s->surfaceDensity);
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
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
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
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
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
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
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
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
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

// C：把一批 wire（UTF-8 字节域）runs 应用到给定文本上。准入 = 末点不越
// 文本末尾；通过后换算 UTF-16（塌缩为空的 run 丢弃，与 macOS 同语义）。
// 返回 false = 整批拒绝（越界），调用方保旧；outEmpty = 整批塌缩（清除）。
static bool admitTextRunsAgainstValue(const std::vector<OhosTextStyleRun> &byteRuns,
                                      const std::string &value,
                                      std::vector<OhosTextStyleRun> &outConverted)
{
    outConverted.clear();
    const size_t byteLen = value.size();
    for (const OhosTextStyleRun &run : byteRuns) {
        if (run.end > byteLen) return false;
    }
    for (OhosTextStyleRun run : byteRuns) {
        const uint32_t s16 = utf8ByteOffsetToUtf16(value, run.start);
        const uint32_t e16 = utf8ByteOffsetToUtf16(value, run.end);
        if (e16 <= s16) continue;
        run.start = s16;
        run.end = e16;
        outConverted.push_back(run);
    }
    return true;
}

CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_text_runs(uint64_t session, uint64_t nodeId,
                                                         const char *encoded)
{
    std::vector<OhosTextStyleRun> parsed;
    if (!parseTextStyleRuns(encoded, parsed)) {
        // 非法 wire/倒置或重叠范围/超预算：整批拒绝，保留节点旧样式。
        RLOGW("text runs refused: invalid/overlapping/over-budget node=%{public}llu",
              static_cast<unsigned long long>(nodeId));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // S1（Astra）：setter 只属于当前 Building 候选。无打开的候选（尚未 configure
    // 或候选已投递/关闭）时具名拒绝——"configure 之前预装给下一轮"的歧义从此
    // 不存在，窗口顺序已改为 configure → install → stage。
    if (!s->candidateOpen) {
        RLOGW("text runs refused: no open candidate node=%{public}llu",
              static_cast<unsigned long long>(nodeId));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (parsed.empty()) {
        // 空 = 清除：候选声明（building 表）删除 + 清候选对象；发布快照
        // （acceptedRunTable 与 accepted 场景）只能随 present 成功晋升改变。
        s->buildingRunTable.erase(nodeId);
        for (SceneNode &n : s->candidate) {
            if (n.pod.nodeId == nodeId) n.textStyleRuns.clear();
        }
        RLOGI("text runs cleared node=%{public}llu", static_cast<unsigned long long>(nodeId));
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    // 会话表始终存 wire 字节域批次（真理源）。准入按**本次候选的文本**进行：
    // 候选已经 configure 并 stage 过该节点时，候选文本就是权威基准；候选里还
    // 没有该节点（事务尚未开始，或该节点本事务尚未 stage）时先入表，由 stage
    // 用其真实文本完成同一准入——绝不拿旧 accepted 文本去拒绝新候选的声明，
    // 那正是“旧 A → 新 ABC 的合法 [2,3) 被先拒”的成因。
    const SceneNode *candidateNode = nullptr;
    for (const SceneNode &n : s->candidate) {
        // 只认**本候选事务实际写入过**的槽位：configure 从 accepted 播种的槽位
        // 仍带着上一代文本，拿它准入就是按旧正文判定（R2 反例第二条）。
        if (n.pod.nodeId == nodeId && n.stagedThisCandidate) { candidateNode = &n; break; }
    }
    if (!candidateNode) {
        // 身份未知（本事务尚未 stage 该节点）：先只记 runs 于 building 表，身份
        // 由随后的 stage 首次写入时补齐并校验。deferred 的含义固定为"归属本候选、
        // 文本尚待验证"，不再是"可能属于下一轮"。
        Session::TextRunBinding entry;
        entry.runs = std::move(parsed);
        s->buildingRunTable[nodeId] = std::move(entry);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    std::vector<OhosTextStyleRun> converted;
    if (!admitTextRunsAgainstValue(parsed, candidateNode->value, converted)) {
        // 越界声明整批拒绝：候选对象保持旧样式，已接受场景一字不改。
        RLOGW("text runs refused: range past candidate text endBytes node=%{public}llu",
              static_cast<unsigned long long>(nodeId));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (converted.empty()) {
        // 整批塌缩成空：语义等价于清除，同样只作用于 building 表与候选。
        s->buildingRunTable.erase(nodeId);
        for (SceneNode &n : s->candidate) {
            if (n.pod.nodeId == nodeId) n.textStyleRuns.clear();
        }
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    {
        Session::TextRunBinding entry;
        entry.runs = std::move(parsed);
        entry.resourceId = candidateNode->pod.resourceId;
        entry.nodeKind = candidateNode->pod.nodeKind;
        entry.bindingEpoch = candidateNode->pod.acceptedBindingEpoch;
        entry.identityKnown = true;
        s->buildingRunTable[nodeId] = std::move(entry);
    }
    // 只刷新候选对象：本事务后续 raster 与 present 晋升都以它为准；
    // 已接受对象等 present 成功后再随候选整体生效。
    for (SceneNode &n : s->candidate) {
        if (n.pod.nodeId == nodeId) n.textStyleRuns = converted;
    }
    textStyleRunsInstalled += converted.size();
    RLOGI("text runs applied node=%{public}llu runs=%{public}zu",
          static_cast<unsigned long long>(nodeId), converted.size());
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_hit_test_composable_text(uint64_t session, uint64_t nodeId,
                                                         double x, double y, uint32_t *outByteOffset,
                                                         uint32_t *outAffinity)
{
    if (!outByteOffset || !outAffinity || !std::isfinite(x) || !std::isfinite(y)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outByteOffset = 0;
    *outAffinity = 0;
    auto job = std::make_shared<CaretHitTestJob>();
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        const Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        if (!s->editing || !s->editingContextLive || s->editorRetired || s->editingNodeId != nodeId)
            return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
        const SceneNode *node = nullptr;
        for (const SceneNode &n : s->accepted) {
            if (n.pod.nodeId == nodeId && n.pod.resourceId == s->editingResourceId &&
                n.pod.nodeKind == s->editingNodeKind) { node = &n; break; }
        }
        if (!node) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
        job->session = session;
        job->contextId = s->editingContextId;
        job->nodeId = nodeId;
        job->resourceId = node->pod.resourceId;
        job->bindingEpoch = node->pod.acceptedBindingEpoch;
        job->projectionVersion = node->pod.projectionVersion;
        job->nodeKind = node->pod.nodeKind;
        job->fontSize = node->pod.fontSize;
        job->fontWeight = node->pod.fontWeight;
        job->nodeWidth = node->pod.width;
        job->nodeHeight = node->pod.height;
        job->nodeX = node->pod.x;
        job->nodeY = node->pod.y;
        job->tapX = x - node->pod.x;
        job->tapY = y - node->pod.y;
        job->text = composedBuffer(*s);
    }
    // This observation never requests a redraw or a new layout.
    if (!g_render.postIfRunning(job)) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    const auto status = job->waitFor();
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        const Session *s = lookupSessionLocked(session);
        if (!s || s->editingContextId != job->contextId || !s->editingContextLive ||
            s->acceptedPaintTicketId != job->sourcePaintTicket || s->editingProjectionVersion != job->projectionVersion ||
            composedBuffer(*s) != job->text) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    *outByteOffset = static_cast<uint32_t>(utf16ToUtf8(job->text.substr(0, job->caretUtf16)).size());
    *outAffinity = static_cast<uint32_t>(job->caretAffinity);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 冻结一次平台恢复请求。只在身份/版本/值/边界全部核对通过后调用；请求号单调递增，
// 使迟到的旧回执按号被拒（ACK 只读冻结值，不再重读当前编辑状态）。
//
// 单调截止覆盖"排队→发送→平台安装→窗口裁决"：终结不依赖下一次重绘，也不依赖
// 新的输入到达（pump 自带限时等待，到期即检查）。
static constexpr int64_t kProxyRestoreDeadlineMs = 2500;

static int64_t proxyRestoreNowMs()
{
    return std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

static void armProxyRestoreRequestLocked(Session &s, const SceneNode &accepted,
    uint32_t selStart, uint32_t selEnd)
{
    s.proxyRestoreRequestSeq += 1;
    Session::ProxyRestoreRequest &req = s.proxyRestore;
    req = Session::ProxyRestoreRequest{};
    req.requestId = s.proxyRestoreRequestSeq;
    req.armed = true;
    req.nodeId = accepted.pod.nodeId;
    req.resourceId = accepted.pod.resourceId;
    req.nodeKind = accepted.pod.nodeKind;
    req.acceptedProjectionVersion = accepted.pod.projectionVersion;
    req.acceptedBindingEpoch = accepted.pod.acceptedBindingEpoch;
    req.contextId = s.editingContextId;
    req.contextGeneration = s.editingContextGeneration;
    req.fieldName = s.editingFieldName;
    req.text = utf8ToUtf16(accepted.value);
    req.selStart = selStart;
    req.selEnd = selEnd;
    req.deadlineMonoMs = proxyRestoreNowMs() + kProxyRestoreDeadlineMs;
    // units 是 UTF-16 码元数，不是正文 UTF-8 字节数（Astra 复核：日志不得混用单位）。
    RLOGI("proxy restore armed request=%{public}llu ctx=%{public}lld node=%{public}llu "
          "v=%{public}llu sel=%{public}u:%{public}u units=%{public}zu deadline=%{public}lld",
          static_cast<unsigned long long>(req.requestId), static_cast<long long>(req.contextId),
          static_cast<unsigned long long>(req.nodeId),
          static_cast<unsigned long long>(req.acceptedProjectionVersion), selStart, selEnd,
          req.text.size(), static_cast<long long>(req.deadlineMonoMs));
}

// 在 accepted 场景里按编辑身份找目标节点（回滚值必须来自本地已接受事实）。
static const SceneNode *acceptedEditingNodeLocked(const Session &s, uint64_t nodeId,
    int64_t resourceId, uint32_t nodeKind)
{
    for (const SceneNode &n : s.accepted) {
        if (n.pod.nodeId == nodeId && n.pod.resourceId == resourceId &&
            n.pod.nodeKind == nodeKind && n.semanticId == s.editingFieldName &&
            n.pod.isInteractive != 0 && n.pod.isReadOnly == 0) {
            return &n;
        }
    }
    return nullptr;
}

// 规范落点哨兵：调用方请求"accepted 正文的字素安全末位"。规范目标必须在**签发前**
// 确定并由票据返回，ACK 时不得迁就平台实际给出的合法落点（Astra：目标 4:9 装成
// 13:13 即使合法也应失败）。
static constexpr uint32_t kProxyRestoreEndOfText = 0xFFFFFFFFu;

static void fillProxyRestoreTicketLocked(const Session &s, uint64_t requestId,
    CjguiInternalRendererProxyRestoreTicket *outTicket);

// 一次逻辑恢复的唯一签发入口：验证 accepted 正文、场景版本与目标范围，然后一次性
// 重置 native 编辑缓冲并只签发一张票据。任一校验不通过都零状态改动、零票据。
//
// 旧实现分两次调用（先回滚正文、再恢复选区），第一段成功已签发票据而窗口尚未登记、
// 第二段失败时留下窗口不知道的孤儿请求。合并成一次之后不存在该交错。
static CjguiInternalRendererStatus recoverTextProxyTicketLocked(Session &s, uint64_t nodeId, int64_t resourceId,
    uint32_t nodeKind, uint64_t sceneVersion, const char *expectedValue,
    uint32_t selectionStart, uint32_t selectionEnd, CjguiInternalRendererProxyRestoreTicket *outTicket)
{
    if (!expectedValue || !outTicket) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (!s.editing || s.editorRetired || !s.editingContextLive) {
        RLOGW("proxy restore ticket rejected: no live context node=%{public}llu",
              static_cast<unsigned long long>(nodeId));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (s.editingNodeId != nodeId || s.editingResourceId != resourceId ||
        s.editingNodeKind != nodeKind) {
        RLOGW("proxy restore ticket rejected: identity mismatch node=%{public}llu native=%{public}llu",
              static_cast<unsigned long long>(nodeId), static_cast<unsigned long long>(s.editingNodeId));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (sceneVersion != s.editingProjectionVersion) {
        RLOGW("proxy restore ticket rejected: scene version mismatch asked=%{public}llu native=%{public}llu",
              static_cast<unsigned long long>(sceneVersion),
              static_cast<unsigned long long>(s.editingProjectionVersion));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    const SceneNode *accepted = acceptedEditingNodeLocked(s, nodeId, resourceId, nodeKind);
    if (!accepted) {
        RLOGW("proxy restore ticket rejected: node missing from accepted node=%{public}llu accepted=%{public}zu",
              static_cast<unsigned long long>(nodeId), s.accepted.size());
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    // 调用方的值必须就是本地 accepted 事实；不等说明调用方描述的是另一份正文。
    if (accepted->value != std::string(expectedValue)) {
        RLOGW("proxy restore ticket rejected: accepted value mismatch accepted_units=%{public}zu asked_units=%{public}zu",
              accepted->value.size(), std::strlen(expectedValue));
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    const std::u16string text = utf8ToUtf16(accepted->value);
    const uint32_t size = static_cast<uint32_t>(text.size());
    uint32_t start = selectionStart;
    uint32_t end = selectionEnd;
    if (start == kProxyRestoreEndOfText) {
        start = clampToCodePointBoundary(text, size);
    }
    if (end == kProxyRestoreEndOfText) {
        end = clampToCodePointBoundary(text, size);
    }
    if (end > size || start > end) {
        RLOGW("proxy restore ticket rejected: range out of bounds range=%{public}u:%{public}u size=%{public}u",
              start, end, size);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (clampToCodePointBoundary(text, start) != start ||
        clampToCodePointBoundary(text, end) != end) {
        RLOGW("proxy restore ticket rejected: non_scalar_boundary range=%{public}u:%{public}u", start, end);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    const Session::ProxyRestoreRequest &active = s.proxyRestore;
    if ((active.armed || active.awaitingAck || active.platformInstalled) && active.requestId != 0 &&
        active.nodeId == nodeId && active.resourceId == resourceId && active.nodeKind == nodeKind &&
        active.acceptedProjectionVersion == sceneVersion && active.selStart == start &&
        active.selEnd == end && active.text == text && proxyRestoreNowMs() < active.deadlineMonoMs) {
        // 完全相同且仍有效的请求：返回原票据，不重复签发、不消耗预算。
        fillProxyRestoreTicketLocked(s, active.requestId, outTicket);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    // 目标已改变或旧票据已失效：先给旧票据确定终态，禁止直接覆写活跃槽。
    terminateProxyRestoreRequestLocked(s, "superseded_by_new_request");
    // 全部核对通过，此刻起才允许改状态。
    s.editingText = text;
    s.previewActive = false;
    s.previewText.clear();
    s.markedActive = false;
    s.markedStart = 0;
    s.markedEnd = 0;
    s.editingContextBaseVersion = sceneVersion;
    s.selStartUtf16 = start;
    s.selEndUtf16 = end;
    s.caretUtf16 = end;
    armProxyRestoreRequestLocked(s, *accepted, start, end);
    fillProxyRestoreTicketLocked(s, s.proxyRestore.requestId, outTicket);
    // 可见正文以编辑缓冲为准：回滚后必须重绘，否则画面仍是被拒草稿。
    g_render.post(std::make_shared<RedrawJob>());
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 票据填充：窗口只信它**调用前**冻结的会话/镜像身份 + 这里返回的 native 身份。
// 因此 deadline、规范落点与代次必须由 native 一次给出，不能在签发后再读当前状态。
static void fillProxyRestoreTicketLocked(const Session &s, uint64_t requestId,
    CjguiInternalRendererProxyRestoreTicket *outTicket)
{
    std::memset(outTicket, 0, sizeof(*outTicket));
    outTicket->requestId = requestId;
    outTicket->deadlineMonoMs = proxyRestoreNowMs();
    if (requestId == 0) {
        outTicket->state = CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NONE;
        return;
    }
    const Session::ProxyRestoreRequest &req = s.proxyRestore;
    // 已安装待采纳的票仍在活动槽里，必须查得到（窗口的事件可能丢失，它要按票对账）。
    if (req.requestId == requestId && (req.armed || req.awaitingAck || req.platformInstalled)) {
        outTicket->contextId = req.contextId;
        outTicket->contextGeneration = req.contextGeneration;
        outTicket->acceptedBindingEpoch = req.acceptedBindingEpoch;
        outTicket->acceptedProjectionVersion = req.acceptedProjectionVersion;
        outTicket->deadlineMonoMs = req.deadlineMonoMs;
        outTicket->canonicalStart = req.selStart;
        outTicket->canonicalEnd = req.selEnd;
        outTicket->state = req.armed ? CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_QUEUED
                                     : CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_SENT;
        if (req.platformInstalled) {
            outTicket->state = CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_INSTALLED;
            outTicket->canonicalStart = req.observedStart;
            outTicket->canonicalEnd = req.observedEnd;
        }
        return;
    }
    for (const Session::ProxyRestoreTerminal &t : s.proxyRestoreTerminals) {
        if (t.requestId != requestId) {
            continue;
        }
        outTicket->state = t.code;
        outTicket->canonicalStart = t.observedStart;
        outTicket->canonicalEnd = t.observedEnd;
        return;
    }
    outTicket->requestId = 0;
    outTicket->state = CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NONE;
}

CjguiInternalRendererStatus cjgui_internal_renderer_recover_text_proxy_ticket(uint64_t session, uint64_t nodeId,
    int64_t resourceId, uint32_t nodeKind, uint64_t sceneVersion, const char *acceptedValue,
    uint32_t selectionStart, uint32_t selectionEnd, CjguiInternalRendererProxyRestoreTicket *outTicket)
{
    if (!outTicket) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::memset(outTicket, 0, sizeof(*outTicket));
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    return recoverTextProxyTicketLocked(*s, nodeId, resourceId, nodeKind, sceneVersion, acceptedValue,
        selectionStart, selectionEnd, outTicket);
}

// 按票据号查询终态：窗口自己的截止检查用它，事件丢失时也能终结待办。
// 未知/已滚出的请求返回 NONE（窗口据此清账并按有界重试重新签发）。
CjguiInternalRendererStatus cjgui_internal_renderer_query_proxy_restore_ticket(uint64_t session, uint64_t requestId,
    CjguiInternalRendererProxyRestoreTicket *outTicket)
{
    if (!outTicket) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    std::memset(outTicket, 0, sizeof(*outTicket));
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    fillProxyRestoreTicketLocked(*s, requestId, outTicket);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 窗口采纳的唯一消费点（唯一胜者）：只有"平台已安装且尚未被消费"的票据能翻成
// ADOPTED；采纳失败或已终结的票据一律返回失败，窗口保留恢复意图重新签发。
// 消费不执行任何平台操作，只做短小状态比较与转换（锁序 owner→native）。
CjguiInternalRendererStatus cjgui_internal_renderer_consume_proxy_restore_ticket(uint64_t session,
    uint64_t requestId, uint32_t adoptedStart, uint32_t adoptedEnd, int32_t *outConsumed)
{
    if (!outConsumed) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outConsumed = 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    Session::ProxyRestoreRequest &req = s->proxyRestore;
    if (requestId == 0 || req.requestId != requestId || !req.platformInstalled ||
        req.observedStart != adoptedStart || req.observedEnd != adoptedEnd) {
        RLOGW("proxy restore consume refused request=%{public}llu active=%{public}llu installed=%{public}d",
              static_cast<unsigned long long>(requestId),
              static_cast<unsigned long long>(req.requestId), req.platformInstalled ? 1 : 0);
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    Session::ProxyRestoreTerminal terminal;
    terminal.requestId = requestId;
    terminal.code = CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED;
    terminal.reason = "window_adopted";
    terminal.platformInstalled = true;
    terminal.observedStart = adoptedStart;
    terminal.observedEnd = adoptedEnd;
    s->proxyRestoreTerminals.push_back(terminal);
    if (s->proxyRestoreTerminals.size() > 8) {
        s->proxyRestoreTerminals.pop_front();
    }
    *outConsumed = 1;
    // 票据已结清：清空活动槽，使后续输入不再被这张旧恢复去重跳过。
    s->proxyRestore = Session::ProxyRestoreRequest{};
    return CJGUI_INTERNAL_RENDERER_OK;
}

// 代理回滚（owner 拒绝人的范围编辑后）。共享 ABI 的鸿蒙实现：正文取本地 accepted
// 事实、落点取字素安全末位，签发走唯一入口。本调用只冻结并排队，不代表平台已安装。
CjguiInternalRendererStatus cjgui_internal_renderer_recover_active_text_proxy(uint64_t session, uint64_t nodeId,
                                                          int64_t resourceId, uint32_t nodeKind,
                                                          const char *acceptedValue,
                                                          uint32_t *outSelectionStart,
                                                          uint32_t *outSelectionEnd)
{
    if (!acceptedValue || !outSelectionStart || !outSelectionEnd) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiInternalRendererProxyRestoreTicket ticket{};
    const CjguiInternalRendererStatus st = recoverTextProxyTicketLocked(*s, nodeId, resourceId, nodeKind,
        s->editingProjectionVersion, acceptedValue, kProxyRestoreEndOfText, kProxyRestoreEndOfText, &ticket);
    *outSelectionStart = ticket.canonicalStart;
    *outSelectionEnd = ticket.canonicalEnd;
    return st;
}

// 光标声明：macOS 用它把插入点矩形交给 AppKit 定位候选窗。鸿蒙的候选取向由平台
// 输入法随聚焦的 TextInput 自行处理，无需框架再声明；保持 ABI 槽位与仓颉声明
// 六参一致（session,nodeId,x,y,width,height）并显式失败，不伪造已声明。
CjguiInternalRendererStatus cjgui_internal_renderer_declare_input_caret(uint64_t session, uint64_t nodeId, double x,
                                                    double y, double width, double height)
{
    (void)session; (void)nodeId; (void)x; (void)y; (void)width; (void)height;
    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}

// 选区恢复：坐标属于它们被测量时的那份正文。版本与值必须同时命中活动编辑绑定，
// 两点必须落在标量边界上；任何不符都零改动拒绝，绝不把旧坐标贴到新文本或
// 把非标量落点交给系统选择手柄。签发与状态改动全部走唯一入口。
//
// 与回滚同一事务：本调用只冻结并排队，窗口等 kind-55 回执带实际安装区间后才确认
// （校准锁与 `confirmNativeSelectionRestored` 都不在这里解锁）。
CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(uint64_t session, uint64_t nodeId,
                                                             int64_t resourceId, uint32_t nodeKind,
                                                             uint64_t sceneVersion, const char *expectedValue,
                                                             uint32_t selectionStart, uint32_t selectionEnd,
                                                             uint32_t *outSelectionStart, uint32_t *outSelectionEnd)
{
    if (!expectedValue || !outSelectionStart || !outSelectionEnd) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiInternalRendererProxyRestoreTicket ticket{};
    const CjguiInternalRendererStatus st = recoverTextProxyTicketLocked(*s, nodeId, resourceId, nodeKind,
        sceneVersion, expectedValue, selectionStart, selectionEnd, &ticket);
    *outSelectionStart = ticket.canonicalStart;
    *outSelectionEnd = ticket.canonicalEnd;
    return st;
}

// 人类锚一次性取走（H1-R.a）：窗口消费 kind-33 时用它区分"人在 native 表面上亲手
// 放置的落点"与"平台代理的安装回声"。只有冻结身份与本次事件的身份、值**全部**命中
// 一枚未消费的锚才返回 1，并当场置 consumed（同一锚不得二次采纳）；任何不符都零改动
// 返回 0——尤其是值不符：把 caret 甩到正文末尾的瞬时回声属于安装观测，不是人的意图。
// 返回 -1 表示参数/会话无效。
int32_t cjgui_internal_renderer_take_human_selection_anchor(uint64_t session, uint64_t nodeId,
                                                            int64_t resourceId, uint32_t nodeKind,
                                                            uint64_t projectionVersion,
                                                            uint64_t acceptedBindingEpoch,
                                                            uint32_t selectionStart,
                                                            uint32_t selectionEnd,
                                                            uint64_t *outAnchorSeq)
{
    if (!outAnchorSeq) return -1;
    *outAnchorSeq = 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return -1;
    const Session::HumanSelectionAnchor anchor = s->humanAnchor;
    if (anchor.seq == 0 || anchor.consumed) return 0;
    if (acceptedBindingEpoch == 0 || anchor.nodeId != nodeId || anchor.resourceId != resourceId ||
        anchor.nodeKind != nodeKind || anchor.projectionVersion != projectionVersion ||
        anchor.acceptedBindingEpoch != acceptedBindingEpoch) {
        RLOGI("human anchor mismatch: identity seq=%{public}llu anchorNode=%{public}llu eventNode=%{public}llu",
              static_cast<unsigned long long>(anchor.seq),
              static_cast<unsigned long long>(anchor.nodeId),
              static_cast<unsigned long long>(nodeId));
        return 0;
    }
    if (anchor.start16 != selectionStart || anchor.end16 != selectionEnd) {
        RLOGI("human anchor mismatch: value seq=%{public}llu anchor=%{public}u:%{public}u "
              "event=%{public}u:%{public}u",
              static_cast<unsigned long long>(anchor.seq), anchor.start16, anchor.end16,
              selectionStart, selectionEnd);
        return 0;
    }
    s->humanAnchor.consumed = true;
    *outAnchorSeq = anchor.seq;
    RLOGI("human anchor taken seq=%{public}llu node=%{public}llu sel=%{public}u:%{public}u",
          static_cast<unsigned long long>(anchor.seq), static_cast<unsigned long long>(nodeId),
          selectionStart, selectionEnd);
    return 1;
}

// 日志用值渲染：只转义控制字符（0x00–0x1F、0x7F），可打印 UTF-8 原样保留。
// 多行正文因此落在**一条** hilog 记录里：原来的裸值输出会把 "\n" 变成记录边界，
// 读回端只能看到被日志头切开的两段（实测：accepted 正文的值被误读成旧草稿）。
// 单行值不受影响，既有读回脚本的 `value=<文本>` 形状保持不变。
static std::string cjguiOhosLogValue(const std::string &value)
{
    std::string out;
    out.reserve(value.size() + 8);
    for (unsigned char c : value) {
        if (c == '\n') {
            out += "\\n";
        } else if (c == '\r') {
            out += "\\r";
        } else if (c == '\t') {
            out += "\\t";
        } else if (c < 0x20 || c == 0x7F) {
            char buf[8];
            std::snprintf(buf, sizeof(buf), "\\x%02X", static_cast<unsigned>(c));
            out += buf;
        } else {
            out += static_cast<char>(c);
        }
    }
    return out;
}

// accepted 帧诊断：几何行与 label/value 行**成对**输出。
// 手写树几何没有任何公共查询面（instances() 只暴露 agent 生成投影），这两行因此
// 是探针判定「导航前编辑器被裁掉 / IME 聚焦后完整可见」的唯一权威来源，属正常
// 产物的一等诊断，不是测试闸门专属。两条 settle 路径（同步成功与票据结算）必须
// 发同一对：只发几何不发 label，延迟提交的帧就无法按语义标签定位节点。
// 两行按 nodeId 配对，与批次内先后无关；坐标为 vp（见 N2-V 密度换算）。
static void cjguiOhosLogAcceptedFrame(const std::vector<SceneNode> &accepted)
{
    for (const SceneNode &n : accepted) {
        RLOGI("node-rect id=%{public}lld x=%{public}lld y=%{public}lld w=%{public}lld h=%{public}lld "
              "clip=(%{public}lld,%{public}lld,%{public}lld,%{public}lld)",
              static_cast<long long>(n.pod.nodeId),
              static_cast<long long>(n.pod.x), static_cast<long long>(n.pod.y),
              static_cast<long long>(n.pod.width), static_cast<long long>(n.pod.height),
              static_cast<long long>(n.pod.clipX), static_cast<long long>(n.pod.clipY),
              static_cast<long long>(n.pod.clipWidth), static_cast<long long>(n.pod.clipHeight));
    }
    for (const SceneNode &n : accepted) {
        // semantic 排在 value 之前：正文可以很长而 hilog 单条记录有上限，截断只
        // 能丢掉值尾，不能丢掉定位节点用的身份。label 是可见文字（按钮=标题、
        // 编辑器=占位文字），两个节点可以同名，因此不能作为几何解析键。
        RLOGI("accepted node=%{public}lld semantic=%{public}s kind=%{public}u label=%{public}s "
              "value=%{public}s v=%{public}llu",
              static_cast<long long>(n.pod.nodeId), n.semanticId.c_str(), n.pod.nodeKind,
              n.label.c_str(), cjguiOhosLogValue(n.value).c_str(),
              static_cast<unsigned long long>(n.pod.projectionVersion));
    }
}

// ---------------------------------------------------------------------------
// ABI：场景事务（configure → set → present）
// ---------------------------------------------------------------------------


// S1（Astra）：present 前的候选终验与快照冻结（g_sessions.lock 内调用）。
// 1) 对"有 run 声明变化但本候选未重新 stage"的保留节点，按其最终候选文本完成
//    deferred 准入——`configure → setter(newStyle) → present`（不 stage）也必须
//    应用声明；准入失败返回 false（候选 Failed，present 拒绝）。
// 2) 裁剪声明集合：只保留最终候选场景中存在且身份匹配的声明（删除节点/未入
//    场的声明不得潜伏到未来候选）。
// 3) 返回冻结后的 building 表副本（提交票据持有；延迟成功结算晋升这份冻结，
//    不回读提交后可能已被下一候选改写的 working 表）。
static bool freezeCandidateRunTableLocked(Session *s, std::map<uint64_t, Session::TextRunBinding> &outFrozen)
{
    std::map<uint64_t, Session::TextRunBinding> frozen;
    for (const SceneNode &n : s->candidate) {
        auto it = s->buildingRunTable.find(n.pod.nodeId);
        if (it == s->buildingRunTable.end()) continue;
        if (it->second.runs.empty()) continue;  // 空声明不占快照（无声明=无样式）
        // 身份匹配：声明绑定的身份必须与最终场景节点一致（换绑/槽位重排淘汰）。
        if (it->second.identityKnown &&
            (it->second.resourceId != n.pod.resourceId ||
             it->second.nodeKind != n.pod.nodeKind)) {
            continue;
        }
        if (!n.stagedThisCandidate) {
            // 保留节点：按其最终候选文本（=播种自 accepted 的当前值）完成准入。
            std::vector<OhosTextStyleRun> converted;
            if (!admitTextRunsAgainstValue(it->second.runs, n.value, converted)) {
                RLOGW("text runs refused at present: retained node=%{public}llu",
                      static_cast<unsigned long long>(n.pod.nodeId));
                return false;
            }
        }
        frozen[n.pod.nodeId] = it->second;
    }
    outFrozen = std::move(frozen);
    return true;
}

CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(uint64_t session, uint64_t projectionVersion,
                                                           uint32_t nodeCount)
{
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        // S1（Astra）：在途票据保护——已投递未结算、或已结算未 ACK 的票仍在时，
        // configure 具名拒绝并保留原票。快照事务里节点与声明表一起属于那张票，
        // 不得在结算前开新候选。
        int slot = sessionSlotLocked(session);
        if (slot >= 0 && g_pending[slot].valid) {
            RLOGW("configure refused: pending ticket=%{public}llu settled=%{public}d",
                  static_cast<unsigned long long>(g_pending[slot].ticketId),
                  g_pending[slot].settled ? 1 : 0);
            return static_cast<CjguiInternalRendererStatus>(CJGUI_INTERNAL_RENDERER_PENDING);
        }
        s->candidateOpen = true;
        s->candidateFailed = false;
        s->candidateProjectionVersion = projectionVersion;
        // 增量事务语义：候选从"已接受场景"播种（保留未重新 stage 的节点内容/
        // 身份/文字），随后核心只覆盖变化的槽位；present 成功才整体晋升。
        // 播种节点统一采用本事务的 projectionVersion：整个场景共享一个版本，
        // 未变化节点同样要跟随推进，否则合成事件带旧版本会被核心拒绝。
        s->candidate.assign(nodeCount, SceneNode{});
        for (size_t i = 0; i < nodeCount && i < s->accepted.size(); ++i) {
            s->candidate[i] = s->accepted[i];
            s->candidate[i].pod.projectionVersion = projectionVersion;
            // 播种只是复制上一代状态；run 准入不能把它当本候选文本（R2）。
            s->candidate[i].stagedThisCandidate = false;
        }
        // S1（Astra）：声明表同样从**发布快照**播种。上一个未提交候选的声明
        // （含 clear）随之丢弃——候选抛弃不泄漏到本候选（RED-A/B 的语义）。
        s->buildingRunTable = s->acceptedRunTable;
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
    // S1（Astra）：stage 先准备、后写入——用新节点身份和新文本解析 building 表
    // 的有效声明，全部成功后一次替换节点与绑定元数据。准入失败把候选标记
    // Failed（present 拒绝），不"只写警告然后照常接受"。
    const std::string nextValue = value ? value : "";
    std::vector<OhosTextStyleRun> stagedRuns;
    bool hasStagedRuns = false;
    {
        auto it = s->buildingRunTable.find(node->nodeId);
        if (it != s->buildingRunTable.end() && !it->second.runs.empty()) {
            // R2 判别 4：**同 id 换绑**不得沿用旧声明。表按 nodeId 存放，而同一
            // session 内该 id 可能被删除后复用为另一个对象——只按 id 查表会把旧
            // run 套到新文本上（旧端点可能越界或指向错误位置）。这里把声明绑定到
            // **首次 stage 时的身份三元组**：身份不符即视为"本对象从未声明过"，
            // 丢弃旧声明，绝不静默沿用。
            const bool identityMismatch = it->second.identityKnown &&
                (it->second.resourceId != node->resourceId ||
                 it->second.nodeKind != node->nodeKind ||
                 (node->acceptedBindingEpoch != 0 &&
                  it->second.bindingEpoch != node->acceptedBindingEpoch));
            if (identityMismatch) {
                RLOGW("text runs dropped: node id rebound node=%{public}llu "
                      "was=%{public}lld/%{public}u now=%{public}lld/%{public}u",
                      static_cast<unsigned long long>(node->nodeId),
                      static_cast<long long>(it->second.resourceId), it->second.nodeKind,
                      static_cast<long long>(node->resourceId), node->nodeKind);
                s->buildingRunTable.erase(it);
                stagedRuns.clear();
                hasStagedRuns = true;
            } else {
                it->second.resourceId = node->resourceId;
                it->second.nodeKind = node->nodeKind;
                it->second.bindingEpoch = node->acceptedBindingEpoch;
                it->second.identityKnown = true;
                std::vector<OhosTextStyleRun> converted;
                if (!admitTextRunsAgainstValue(it->second.runs, nextValue, converted)) {
                    RLOGW("text runs refused at stage: range past candidate text endBytes node=%{public}llu",
                          static_cast<unsigned long long>(node->nodeId));
                    // S1（Astra）：run 准入失败终止本次窗口尝试——候选标 Failed，
                    // present 拒绝；节点、building 表项与发布快照均保持失败前内容。
                    s->candidateFailed = true;
                    return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
                }
                stagedRuns = std::move(converted);
                hasStagedRuns = true;
            }
        } else {
            // S1（Astra）：没有有效声明时**明确写入空 runs**——"查表无项就不碰
            // 槽位"会让 configure 播种进候选的上一代样式残留进本候选画面
            // （RED-B 的直接成因）。声明表是唯一真理源：无声明 = 无样式。
            stagedRuns.clear();
            hasStagedRuns = true;
        }
    }
    dst.pod = *node;
    dst.label = label ? label : "";
    dst.value = nextValue;
    dst.semanticId = "";
    // 本槽位已被本候选事务实际写入：此后 candidate.value 才是 run 准入的基准。
    dst.stagedThisCandidate = true;
    if (hasStagedRuns) {
        // 塌缩成空 = 清除（与 setter 同一语义）；否则安装本候选的 run 表。
        if (stagedRuns.empty()) {
            dst.textStyleRuns.clear();
        } else {
            dst.textStyleRuns = stagedRuns;
            textStyleRunsInstalled += stagedRuns.size();
        }
    }
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
    // R1补轮（2026-10-02 指导复核）：本函数只在**当前来源**的提交上运行——
    // 旧来源候选已在 settlePendingTicketLocked 的不可逆晋升前被整票拒绝
    //（pendingSettlementSourceStaleLocked），票号大小不构成来源关系证明，
    // 也不存在任何「先发布旧树再跳过退役判定」的宽限。因此到达这里的每一棵
    // accepted 树都是绑定建立后由其来源提交的：缺席/失配/只读化即真实撤销，
    // 首次发布立即退役（Astra 协议 e/case-b），删除后旧输入由 takeEditing
    // ContextLocked 的活上下文守卫拒绝。
    // 历史：曾以 acceptedPaintTicketId < editingBornTicketId 容忍"绑定前结算"，
    // 该比较既非来源关系证明，又先交换了 accepted 树（旧树删除节点的画面已
    // 发布）才决定跳过 sync——正是 Astra 否定的反模式，已随结算前拒绝移除。
    bool found = false;
    for (const SceneNode &n : s->accepted) {
        if (n.pod.nodeId != s->editingNodeId || n.pod.resourceId != s->editingResourceId) continue;
        found = true;
        if (n.pod.nodeKind != s->editingNodeKind ||
            n.pod.acceptedBindingEpoch != s->editingAcceptedBindingEpoch ||
            n.semanticId != s->editingFieldName ||
            n.pod.isReadOnly != 0 || n.pod.isInteractive == 0) {
            // S2（Astra 2026-10-02，consultations/s2-identity-handoff-astra）：
            // 生效绑定在**首张真实撤销提交**立即失效。到达这里的提交版本必
            // >= 绑定基线（更早的票据结算在函数顶部按版本容忍），失配即真
            // 实撤销/换绑，不再数帧。绑定随其提交成功才激活（platform focus
            // 只跟随已发布树）+ acceptedBindingEpoch 全量身份比较收 ABA。
            RLOGW("editing sync kills context node=%{public}llu "
                  "kind=%{public}u/%{public}u epoch=%{public}llu/%{public}llu "
                  "semantic=%{public}s/%{public}s ro=%{public}u live=%{public}u",
                  static_cast<unsigned long long>(n.pod.nodeId),
                  s->editingNodeKind, n.pod.nodeKind,
                  static_cast<unsigned long long>(s->editingAcceptedBindingEpoch),
                  static_cast<unsigned long long>(n.pod.acceptedBindingEpoch),
                  s->editingFieldName.c_str(),
                  n.semanticId.c_str(), n.pod.isReadOnly, n.pod.isInteractive);
            // S2（r18 实测）：kill 排队的 end 通知必须携带**将死上下文**的身份。
            // 不捕获时投递端回退读"当前"上下文——rebind 已把编号换成新的，
            // end 会误杀刚挂载的新代理（"end 贴着 mount"，旧两帧宽限靠时序
            // 侥幸掩盖了这一误寄）。R1：统一走待发队列，身份在冻结点入队。
            pushPendingEndLocked(*s, s->editingContextId, s->editingFieldName, false);
            s->editing = false;          // 节点不可编辑：连同绘制一起结束
            s->editorRetired = true;
            s->editingContextLive = false;
            s->textMenuIntent = 0;
            s->previewActive = false;
            s->previewText.clear();
            s->markedActive = false;
            s->reconcileNotifyPending = false;
            cancelProxyRestoreRequest(*s, "rebound_kind_or_field");
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
        // H1-C：本地编辑被 owner 接受后，accepted 投影带回的就是屏幕上这段文本
        // （ownerValue == 编辑缓冲）。这是同一段本地连续的准入版本推进，不是外部
        // 换版：只推进版本并保留平台光标/组合态。否则每敲一个字都要重建编辑
        // 上下文并让页面重挂系统输入代理，光标与 preedit 全部丢失。
        if (s->editingContextLive && !s->previewActive && !editorOwnsTextSession(*s) &&
            n.pod.projectionVersion != s->editingContextBaseVersion &&
            ownerValue == s->editingText) {
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
            // 外部换版：新上下文编号即新身份，旧恢复请求（连同待发正文/选区）作废，
            // 否则旧恢复串会带着旧上下文号落到新上下文上。
            cancelProxyRestoreRequest(*s, "external_version");
            s->textMenuIntent = 0;
            s->editingContextId = g_nextEditingContextId.fetch_add(1);
            s->caretBlinkResetPending = true;
            s->caretAffinity = 0;
            s->editingContextBaseVersion = n.pod.projectionVersion;
            s->editingProjectionVersion = n.pod.projectionVersion;
            s->editingFieldName = n.semanticId;
            s->editingText = ownerValue;
            s->previewActive = false;
            s->previewText.clear();
            s->markedActive = false;
            s->markedStart = 0;
            s->markedEnd = 0;
            // R3：上下文重建是**视图/会话**事件，不是"人的落点被丢弃"的理由。
            // 原实现无条件把选区重置为正文末尾的折叠 caret，于是"中段非空选区
            // → 双切换 → 切回"之后只剩末尾 caret，首笔系统输入变成插入而不是
            // 替换（2026-10-01 实测：ctx=1 已是 [101,104)，重建后变 [104,104)）。
            // 这里按新正文长度收敛原选区：两端 clamp 到合法标量边界，保持非空
            // 区间；只有在新正文里确实无法表达时才退化为 caret。
            const uint32_t newSize = static_cast<uint32_t>(ownerValue.size());
            uint32_t keepStart = clampToCodePointBoundary(ownerValue,
                std::min(s->selStartUtf16, s->selEndUtf16));
            uint32_t keepEnd = clampToCodePointBoundary(ownerValue,
                std::max(s->selStartUtf16, s->selEndUtf16));
            if (keepStart > newSize) keepStart = newSize;
            if (keepEnd > newSize) keepEnd = newSize;
            if (keepEnd < keepStart) keepEnd = keepStart;
            if (keepEnd > keepStart) {
                s->selStartUtf16 = keepStart;
                s->selEndUtf16 = keepEnd;
                s->caretUtf16 = keepEnd;
            } else {
                s->caretUtf16 = newSize;
                s->selStartUtf16 = s->caretUtf16;
                s->selEndUtf16 = s->caretUtf16;
            }
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
        // S2：同上——出生票据之后的提交仍缺席即真实移除，立即收场；出生票据
        // 之前的结算已在函数顶部按票据 lineage 容忍（旧模式结果不得杀新绑定）。
        // R1：将死身份随通知冻结进待发队列。
        RLOGW("editing sync kills context (node absent) node=%{public}llu",
              static_cast<unsigned long long>(s->editingNodeId));
        pushPendingEndLocked(*s, s->editingContextId, s->editingFieldName, false);
        s->editing = false;
        s->editorRetired = true;
        s->editingContextLive = false;
        s->textMenuIntent = 0;
        s->previewActive = false;
        s->previewText.clear();
        s->markedActive = false;
        s->reconcileNotifyPending = false;
        cancelProxyRestoreRequest(*s, "node_removed");
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
// R1补轮（Astra s2-identity-handoff 落地）：候选来源是否已过期。present 锁内
// 冻结的来源上下文与结算时仍活着的上下文编号不同 = 该候选由旧来源生成（旧模式
// 结果/旧树），对编辑节点的缺席/退化不是当前绑定的退役证据。必须在不可逆晋升
// 前整票拒绝——而不是先发布它再在 sync 里按任何阈值/票号宽限跳过退役判定。
// 同一锁内冻结与比较，上下文编号在每次完整身份变化时单调轮换（R1 完整绑定
// 幂等），因此编号相等即同一绑定，无需再比节点字段。
static bool pendingSettlementSourceStaleLocked(const Session &s, const PendingSettlement &p)
{
    return s.editingContextLive && p.sourceEditingLive &&
        s.editingContextId != p.sourceEditingContextId;
}

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
    if (phase == JobPhase::Done && pendingSettlementSourceStaleLocked(*s, p)) {
        // 旧来源候选：不可逆晋升前整票拒绝。旧 accepted 保留（画面继续呈现
        // 当前绑定可见的树），票据终态 REJECTED，owner 按失败结算后提交新候选。
        RLOGW("pending settlement rejected stale_source ticket=%{public}llu "
              "sourceCtx=%{public}lld liveCtx=%{public}lld",
              static_cast<unsigned long long>(p.ticketId),
              static_cast<long long>(p.sourceEditingContextId),
              static_cast<long long>(s->editingContextId));
        p.job = nullptr;
        p.nodes.clear();
        p.terminalStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;
        p.settled = true;
        s->ticketRejectedCount += 1;
        g_abortedSettlements.fetch_add(1);
        g_lastSettlementVerdict.store(kSettlementAborted);
        return p.decision;
    }
    CjguiInternalRendererStatus status =
        p.job ? p.job->statusSnapshot() : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (phase == JobPhase::Done && status == CJGUI_INTERNAL_RENDERER_OK) {
        // 唯一一次 commit：native accepted 与命中同时切到该候选。
        const uint64_t oldProjection = s->acceptedProjectionVersion;
        s->accepted.swap(p.nodes);
        s->acceptedProjectionVersion = p.projectionVersion;
        s->acceptedPaintTicketId = p.ticketId;
        // S1（Astra）：晋升**票据冻结的**声明快照——延迟成功绝不回读提交后
        // 可能已被下一候选改写的 working 表。
        s->acceptedRunTable = p.runTable;
        cjguiOhosLogAcceptedImageSwap(*s, p.nodes, oldProjection, p.ticketId, "commit");
        bool imageChanged = reconcileAcceptedImagesLocked(s);
        cjguiOhosLogAcceptedFrame(s->accepted);
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
    // S1（Astra）：提交前冻结的候选声明快照（提交票据持有；成功晋升为发布态）。
    std::map<uint64_t, Session::TextRunBinding> frozenRunTable;
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
        // S1（Astra）：Failed 候选禁止 present——run 准入失败必须终止本次窗口
        // 尝试，防止发布「旧样式 + 新文本」的混合结果。
        if (s->candidateFailed) {
            RLOGW("present refused: candidate failed (run admission)");
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        }
        // S1（Astra）：present 前完成候选终验（保留节点的 deferred 准入）并
        // 冻结声明快照——投递票据持有这份冻结，结算晋升它而非 working 表。
        if (!freezeCandidateRunTableLocked(s, frozenRunTable)) {
            s->candidateFailed = true;
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
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
            p.runTable = frozenRunTable;
            p.projectionVersion = projectionVersion;
            p.ticketId = ticketId;
            p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING;
            p.terminalStatus = 0;
            p.frameIndex = 0;
            p.settled = false;
            p.valid = true;
            p.sourceEditingContextId = s->editingContextId;
            p.sourceEditingLive = s->editingContextLive;
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
        s->acceptedPaintTicketId = ticketId;
        // S1（Astra）：声明快照与节点同一次提交晋升（发布快照 = 冻结表）。
        s->acceptedRunTable = frozenRunTable;
        cjguiOhosLogAcceptedImageSwap(*s, nodes, oldProjection, ticketId, "commit");
        imageChanged = reconcileAcceptedImagesLocked(s);
        // 与 PENDING-settle 路径同一对诊断，resize 后几何采样两条路径都能取到。
        cjguiOhosLogAcceptedFrame(s->accepted);
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
        const bool editable = isEditableTextKind(kind);
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
    const uint64_t pumpRenderEpoch = g_render.currentRunEpoch();

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
            // Resolve END's last coordinate before taking the next BEGIN from
            // ingress. MOVE remains coalesced in one Session slot.
            if (s->selectionDrag.terminal && s->editingTapPending) break;
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
    if (s->selectionDrag.active && !selectionDragMatchesLocked(*s, s->selectionDrag)) {
        // External text/context changes and surface retirement revoke a held
        // visual gesture even when no further MOVE/END arrives.
        s->selectionDrag.terminal = false;
        cancelTouchGestureLocked(*s);
    }
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
    if (s->gesture.active && (s->gesture.phase == Session::TouchGesture::kGestureEditorHold ||
        s->gesture.phase == Session::TouchGesture::kGesturePending)) {
        const int64_t nowMs = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();
        requestLongPressWordLocked(*s, nowMs);
    }
    // 锁外处理：caret 命中（渲染线程测量）与 IME attach/detach（服务调用）。
    if (s->editingTapPending) {
        s->editingTapPending = false;
        const uint32_t hitMode = s->editingHitMode;
        const uint64_t hitOperation = s->selectionOperationGeneration;
        uint64_t nodeId = s->editingNodeId;
        const int64_t hitContext = s->editingContextId;
        const uint64_t hitContextGeneration = s->editingContextGeneration;
        const int64_t hitResource = s->editingResourceId;
        const uint64_t hitProjection = s->editingProjectionVersion;
        const uint64_t hitSurfaceRevision = s->surfaceGeometryRevision;
        double tapX = s->editingTapX;
        double tapY = s->editingTapY;
        std::u16string composed;
        double fontSize = 13.0;
        uint32_t fontWeight = 400;
        double nodeWidth = 0.0;
        double nodeHeight = 0.0;
        int64_t nodeX = 0, nodeY = 0;
        uint64_t bindingEpoch = 0;
        uint32_t nodeKind = 0;
        for (const SceneNode &n : s->accepted) {
            if (n.pod.nodeId == nodeId && n.pod.resourceId == hitResource &&
                n.pod.nodeKind == s->editingNodeKind) {
                composed = composedBuffer(*s);
                fontSize = n.pod.fontSize;
                fontWeight = n.pod.fontWeight;
                nodeWidth = static_cast<double>(n.pod.width);
                nodeHeight = static_cast<double>(n.pod.height);
                nodeKind = n.pod.nodeKind;
                nodeX = n.pod.x;
                nodeY = n.pod.y;
                bindingEpoch = n.pod.acceptedBindingEpoch;
                break;
            }
        }
        if (nodeWidth > 0.0) {
            g.unlock();
            CaretHitTestJob *job = new CaretHitTestJob();
            job->text = composed;
            job->fontSize = fontSize;
            job->fontWeight = fontWeight;
            job->nodeWidth = nodeWidth;
            job->nodeHeight = nodeHeight;
            job->nodeKind = nodeKind;
            job->session = session;
            job->contextId = hitContext;
            job->nodeId = nodeId;
            job->resourceId = hitResource;
            job->bindingEpoch = bindingEpoch;
            job->projectionVersion = hitProjection;
            job->nodeX = nodeX;
            job->nodeY = nodeY;
            job->mode = hitMode;
            // 节点内相对坐标原样传入；文本原点由渲染线程按绘制同一套几何换算。
            job->tapX = tapX;
            job->tapY = tapY;
            JobRef jobRef(job);
            const bool posted = g_render.postCaretHitAfterRedraw(jobRef, pumpRenderEpoch);
            uint32_t caret = 0;
            CjguiInternalRendererStatus waited = posted ? job->waitFor() : CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
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
            // 命中输入与结果同条落日志：多行命中错行时，没有这条就只能靠屏幕猜
            // 坐标单位与几何原点的组合（实测 tap→caret 错行就是这么定位的）。
            RLOGI("caret hit applied tap=(%{public}.1f,%{public}.1f) node=(%{public}.1f,%{public}.1f) "
                  "kind=%{public}u composed=%{public}zu caret=%{public}u ok=%{public}d",
                  tapX, tapY, nodeWidth, nodeHeight, nodeKind, composed.size(),
                  caret, static_cast<int>(caretOk));
            // 复核：等待期间编辑目标未被替换
            s = lookupSessionLocked(session);
            if (caretOk && s && s->editing && s->editingContextLive && !s->editorRetired && s->editingNodeId == nodeId &&
                s->selectionOperationGeneration == hitOperation && (hitMode == 0 || !s->previewActive) &&
                s->editingResourceId == hitResource && s->editingNodeKind == nodeKind &&
                s->editingContextId == hitContext && s->editingContextGeneration == hitContextGeneration &&
                s->editingProjectionVersion == hitProjection && s->surfaceGeometryRevision == hitSurfaceRevision &&
                bindingEpoch != 0 && s->acceptedPaintTicketId == job->sourcePaintTicket && composedBuffer(*s) == composed) {
                bool sameGeometry = false;
                for (const SceneNode &current : s->accepted) {
                    if (current.pod.nodeId == nodeId && current.pod.resourceId == hitResource &&
                        current.pod.nodeKind == nodeKind && current.pod.width == nodeWidth &&
                        current.pod.x == nodeX && current.pod.y == nodeY &&
                        current.pod.acceptedBindingEpoch == bindingEpoch &&
                        current.pod.height == nodeHeight && current.pod.fontSize == fontSize &&
                        current.pod.fontWeight == fontWeight) { sameGeometry = true; break; }
                }
                if (!sameGeometry) {
                    RLOGW("caret hit discarded after geometry change ctx=%{public}lld", static_cast<long long>(hitContext));
                } else {
                applySelectionHitLocked(*s, hitOperation, hitMode, caret, job->caretAffinity,
                    job->wordStart, job->wordEnd);
                }
            }
            if (s && hitMode != 0 && s->selectionOperationGeneration == hitOperation &&
                !s->editingTapPending && (!caretOk || !selectionDragMatchesLocked(*s, s->selectionDrag))) {
                // A refused/stale visual job cannot leave notification suppression
                // armed forever. Never manufacture a word or replay the gesture.
                s->selectionDrag = Session::SelectionDrag{};
            }
            if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
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
        // 平台挂载时按上下文快照取正文与落点：账本对齐到当前值，不再补一条
        // 与快照重复的 caret 通知。
        s->selPlatformStart = std::min(s->selStartUtf16, s->selEndUtf16);
        s->selPlatformEnd = std::max(s->selStartUtf16, s->selEndUtf16);
        s->selForwardedValid = false;   // 平台重新取初值后的首条观测对窗口是新事实
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
            // 重挂同样按新上下文快照取初值：账本对齐，不补重复通知。
            s->selPlatformStart = std::min(s->selStartUtf16, s->selEndUtf16);
            s->selPlatformEnd = std::max(s->selStartUtf16, s->selEndUtf16);
            s->selForwardedValid = false;
            RLOGI("ime reconcile notification old=%{public}lld new=%{public}lld",
                  static_cast<long long>(oldContext), static_cast<long long>(newContext));
            g.unlock();
            sink(payload.c_str());
            g.lock();
        }
    }
    // native 落点 → 平台代理（H1-3）：命中、编辑命令与外部换版都会移动 caret/选区，
    // 而代理只按自己的事件更新落点。不推送时"点正文后继续打字"会落在代理的旧偏移
    // （实测命中 caret=8、代理仍在 1，键入插到正文开头）。差分推送 + 回声同步账本，
    // 因此不会自激；恢复事务进行中由该事务自己装落点，这里让路。
    if (s->editing && s->editingContextLive) {
        const Session::ProxyRestoreRequest &live = s->proxyRestore;
        const bool restoreLive = live.requestId != 0 &&
            (live.armed || live.awaitingAck || live.platformInstalled);
        const uint32_t a = std::min(s->selStartUtf16, s->selEndUtf16);
        const uint32_t b = std::max(s->selStartUtf16, s->selEndUtf16);
        const bool movingSelection = s->selectionDrag.active && s->selectionDrag.anchorReady &&
            !s->selectionDrag.terminal;
        if (!restoreLive && (!movingSelection || s->humanCaretNotificationPending) && (s->humanCaretNotificationPending ||
            a != s->selPlatformStart || b != s->selPlatformEnd)) {
            s->selPlatformStart = a;
            s->selPlatformEnd = b;
            void (*sink)(const char *) = g_focusRequestSink;
            if (sink) {
                s->humanCaretNotificationPending = false;
                std::string payload = "{\"action\":\"caret\",\"context\":" +
                    std::to_string(s->editingContextId) +
                    ",\"selStart\":" + std::to_string(a) +
                    ",\"selEnd\":" + std::to_string(b) + "}";
                RLOGI("ime caret notification ctx=%{public}lld sel=%{public}u:%{public}u caret=%{public}u",
                      static_cast<long long>(s->editingContextId), a, b, s->caretUtf16);
                g.unlock();
                sink(payload.c_str());
                g.lock();
            }
        }
    }
    // Blink is visual work on the existing render queue. Decide under the
    // Session lock and post only after releasing it, against the captured run.
    bool blinkTarget = false;
    for (const SceneNode &node : s->accepted) {
        if (node.pod.nodeId == s->editingNodeId && node.pod.resourceId == s->editingResourceId &&
            node.pod.nodeKind == s->editingNodeKind && node.pod.acceptedBindingEpoch != 0) {
            blinkTarget = true;
            break;
        }
    }
    const bool blinkForeground = !g_ingress.foregroundLevel || g_ingress.foregroundLevel() == 1;
    const bool blinkEligible = blinkTarget && blinkForeground && s->editing && s->editingContextLive &&
        !s->editorRetired && s->selStartUtf16 == s->selEndUtf16;
    if (advanceCaretBlinkLocked(*s, proxyRestoreNowMs(), blinkEligible)) {
        RLOGI("caret phase session=%{public}llu ctx=%{public}lld visible=%{public}d active=%{public}d nextMs=%{public}lld",
            static_cast<unsigned long long>(session), static_cast<long long>(s->editingContextId),
            s->caretBlinkVisible ? 1 : 0, s->caretBlinkActive ? 1 : 0, static_cast<long long>(s->caretBlinkNextMs));
        g.unlock();
        g_render.postCaretBlink(pumpRenderEpoch);
        g.lock();
        s = lookupSessionLocked(session);
        if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
    // 截止到期：native 独立裁决，不依赖 ArkTS 回调也不依赖下一次输入。
    // 已发送→"安装未确认"（code 2）；尚未发送→"未执行平台安装"（code 1）。
    if ((s->proxyRestore.armed || s->proxyRestore.awaitingAck || s->proxyRestore.platformInstalled) &&
        s->proxyRestore.deadlineMonoMs > 0 && proxyRestoreNowMs() >= s->proxyRestore.deadlineMonoMs) {
        terminateProxyRestoreRequestLocked(*s, s->proxyRestore.platformInstalled
            ? "window_adoption_deadline" : "platform_ack_deadline");
    }
    if (s->proxyRestore.armed) {
        // 只读冻结值：绝不在此重读当前 context/field/base——pump 先 drainTouches，
        // 重读会把"A 排恢复→点击 B 换焦"变成 A 的正文配 B 的身份。
        s->proxyRestore.armed = false;
        s->proxyRestore.awaitingAck = true;
        void (*sink)(const char *) = g_focusRequestSink;
        if (!sink) {
            // 无出口：平台不可能安装，不伪造等待，直接取消（窗口按有界重试记账）。
            cancelProxyRestoreRequest(*s, "no_sink");
        } else {
            const Session::ProxyRestoreRequest &req = s->proxyRestore;
            std::string payload = "{\"action\":\"restore\",\"request\":" + std::to_string(req.requestId);
            payload += ",\"context\":" + std::to_string(req.contextId);
            payload += ",\"field\":\"";
            appendJsonEscaped(payload, req.fieldName);
            payload += "\",\"nodeId\":" + std::to_string(req.nodeId);
            payload += ",\"baseVersion\":" + std::to_string(req.acceptedProjectionVersion);
            payload += ",\"selStart\":" + std::to_string(req.selStart);
            payload += ",\"selEnd\":" + std::to_string(req.selEnd);
            payload += ",\"text\":\"";
            appendJsonEscaped(payload, utf16ToUtf8(req.text));
            payload += "\"}";
            RLOGI("ime proxy restore notification request=%{public}llu ctx=%{public}lld units=%{public}zu sel=%{public}u:%{public}u",
                  static_cast<unsigned long long>(req.requestId), static_cast<long long>(req.contextId),
                  req.text.size(), req.selStart, req.selEnd);
            g.unlock();
            sink(payload.c_str());
            g.lock();
            // sink 是 void 出口：只声明"已交付出口"，不声明平台已入队（Astra 第 6 点）。
            // 真正终态由平台 ACK 或 native 截止裁决。
            s->proxyRestore.sent = true;
        }
    }
    // R1：待发 end 队列逐条投递。每条自带冻结身份与结算意图；多条（如
    // begin(A)→begin(B)→finish(B) 在同一次 pump 前）按 FIFO 全部送达，互不
    // 覆盖。身份在各自收场入口已冻结，这里绝不回读"当前"上下文字段。
    while (!s->pendingEnds.empty()) {
        const Session::PendingEnd end = s->pendingEnds.front();
        s->pendingEnds.pop_front();
        // 框架主动结束编辑（点到别处/空白）先做一次失焦结算：把用户已看见的
        // 组合预览折进编辑缓冲并交付 owner。平台 finish / 跨字段同步结算 /
        // kill 触发的条目 settle=false（值已交付或已结算，再结算就是重复写）。
        if (end.settleOnDelivery) {
            bool settled = settleComposedBufferOnBlurLocked(*s);
            std::string settledText = utf16ToUtf8(s->editingText);
            RLOGI("ime blur settle ctx=%{public}lld settled=%{public}d node=%{public}lld text=%{public}s",
                  static_cast<long long>(end.contextId), settled ? 1 : 0,
                  static_cast<long long>(s->editingNodeId), settledText.c_str());
        }
        void (*sink)(const char *) = g_focusRequestSink;
        // 结束通知（与 focus 成对）：框架侧结束编辑（点到别的控件/换绑/节点移除）
        // 时，平台代理必须同步收场，否则代理会带着已被回收的上下文继续持有
        // 焦点与系统键盘（实测：点空白处结束编辑后键盘不收起）。
        std::string payload = "{\"action\":\"end\",\"context\":" + std::to_string(end.contextId);
        payload += ",\"field\":\"";
        appendJsonEscaped(payload, end.fieldName);
        payload += "\"}";
        // R1：底层 imeDetach 只在会话没有更新的活上下文时执行——旧 A 的 end
        // 不得拆掉后来建立的 B 的会话（当前 native 代理从未 attach，此处为
        // 语义正确性守卫）。
        const bool newerContextLive = s->editingContextLive;
        g.unlock();
        if (!newerContextLive) imeDetach();
        if (sink) sink(payload.c_str());
        g.lock();
    }
    if (s->events.empty()) {
        outEvent->kind = CJGUI_INTERNAL_RENDERER_EVENT_NONE;
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    QueuedEvent ev = s->events.front();
    s->events.pop_front();
    if (ev.kind == kEvSelectionChanged) {
        ev.recordIndex = queuedSelectionContextIsCurrent(*s, ev) ? 0u : 1u;
        if (ev.recordIndex != 0) {
            RLOGI("ime selection event refused reason=selection_context_stale captured=%{public}lld current=%{public}lld",
                  static_cast<long long>(ev.editingContextId), static_cast<long long>(s->editingContextId));
        }
    }
    if (ev.kind == kEvTextRangeChanged) {
        RLOGI("ime range delta dequeue node=%{public}llu projection=%{public}llu binding=%{public}llu range=%{public}u:%{public}u bytes=%{public}zu",
              static_cast<unsigned long long>(ev.nodeId), static_cast<unsigned long long>(ev.projectionVersion),
              static_cast<unsigned long long>(ev.bindingEpoch), ev.selectionStart, ev.selectionEnd, ev.text.size());
    }
    if (ev.kind == kEvActivate) {
        // S3（ACTIVATE 分发延迟追因）：按钮激活出队时留一行事实——若此行缺席
        // 而触摸已到（end/blur-settle 已打印），问题在命中/入队侧；若此行在而
        // 预览面迟迟不出现，问题在窗口路由/owner 拒绝侧。
        RLOGI("activate dequeue node=%{public}llu projection=%{public}llu binding=%{public}llu lift=%{public}u",
              static_cast<unsigned long long>(ev.nodeId), static_cast<unsigned long long>(ev.projectionVersion),
              static_cast<unsigned long long>(ev.acceptedBindingEpoch), ev.recordIndex);
    }
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
    outEvent->bindingEpoch = ev.bindingEpoch;
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

// 菜单有界元数据（h-source-preview-next B）：与整文上下文同一 menuValid 判定，
// 但**不含正文/预览文本**——体积 O(1)，供 ArkUI 菜单周期消费；正文只在真正
// 复制/剪切动作时按冻结身份经整文查询取一次（imeMenuCommand 仍原子复验）。
// 返回 0 = 无有效上下文；1 = 已写入元数据 JSON。
extern "C" int32_t ohos_renderer_ime_menu_meta_json(char *out, int32_t capacity)
{
    if (!out || capacity <= 0) return 0;
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findEditingSessionLocked();
    if (!s || !s->editingContextLive) return 0;
    const auto &menu = s->selectionHandles;
    const bool menuRequested = menu.start < menu.end ? s->textMenuIntent != 0 : s->textMenuIntent == 2;
    const bool menuValid = menuRequested && menu.valid && menu.ticket != 0 &&
        menu.ticket == s->acceptedPaintTicketId && menu.context == s->editingContextId &&
        menu.text == s->editingText && menu.start == s->selStartUtf16 && menu.end == s->selEndUtf16 &&
        menu.generation == s->surfaceGeneration && menu.geometryRevision == s->surfaceGeometryRevision &&
        menu.projection == s->editingProjectionVersion && !s->previewActive && !s->markedActive &&
        !s->proxyRestore.armed && !s->proxyRestore.awaitingAck && !s->proxyRestore.platformInstalled &&
        !(s->selectionDrag.active && !s->selectionDrag.terminal);
    std::string json = "{\"context\":";
    json += std::to_string(s->editingContextId);
    json += ",\"generation\":" + std::to_string(s->editingContextGeneration);
    json += ",\"baseVersion\":" + std::to_string(s->editingContextBaseVersion);
    json += ",\"selStart\":" + std::to_string(s->selStartUtf16);
    json += ",\"selEnd\":" + std::to_string(s->selEndUtf16);
    json += ",\"menuAvailable\":";
    json += menuValid ? "true" : "false";
    if (menuValid) {
        const bool first = menu.startVisible;
        json += ",\"menuX\":" + std::to_string(first ? menu.startX : menu.endX);
        json += ",\"menuTop\":" + std::to_string(first ? menu.startLineY - 10 : menu.endLineY - 10);
        json += ",\"menuBottom\":" + std::to_string(first ? menu.startLineY + 10 : menu.endLineY + 10);
    }
    json += "}";
    if (static_cast<int32_t>(json.size()) + 1 > capacity) return 0;
    std::memcpy(out, json.c_str(), json.size() + 1);
    return 1;
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
    const auto &menu = s->selectionHandles;
    const bool menuRequested = menu.start < menu.end ? s->textMenuIntent != 0 : s->textMenuIntent == 2;
    const bool menuValid = menuRequested && menu.valid && menu.ticket != 0 && menu.ticket == s->acceptedPaintTicketId &&
        menu.context == s->editingContextId && menu.text == s->editingText &&
        menu.start == s->selStartUtf16 && menu.end == s->selEndUtf16 &&
        menu.generation == s->surfaceGeneration && menu.geometryRevision == s->surfaceGeometryRevision &&
        menu.projection == s->editingProjectionVersion && !s->previewActive && !s->markedActive &&
        !s->proxyRestore.armed && !s->proxyRestore.awaitingAck && !s->proxyRestore.platformInstalled &&
        !(s->selectionDrag.active && !s->selectionDrag.terminal);
    json += ",\"menuAvailable\":";
    json += menuValid ? "true" : "false";
    if (menuValid) {
        // Coordinates are logical vp from the actual Paint/Flush. Do not apply
        // surface density again in ArkUI. Prefer the visible selected endpoint.
        const bool first = menu.startVisible;
        json += ",\"menuX\":" + std::to_string(first ? menu.startX : menu.endX);
        json += ",\"menuTop\":" + std::to_string(first ? menu.startLineY - 10 : menu.endLineY - 10);
        json += ",\"menuBottom\":" + std::to_string(first ? menu.startLineY + 10 : menu.endLineY + 10);
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

// Pure platform query: verifies the captured proxy baseline under the native
// context lock. It neither locks nor edits the Cangjie owner; kind51 retains
// its original owner arbitration after the REAL platform change.
extern "C" int32_t ohos_renderer_ime_grapheme_range_ctx(const char *text, size_t length,
    int32_t offset16, int64_t contextId, int32_t *outStart, int32_t *outEnd)
{
    if (outStart) *outStart = 0;
    if (outEnd) *outEnd = 0;
    if (!text || !outStart || !outEnd || length > 65536) return 16;
    const std::string input(text, length);
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = takeEditingContextLocked(contextId);
    if (!s || s->previewActive || s->markedActive || s->proxyRestore.armed ||
        s->proxyRestore.awaitingAck || s->proxyRestore.platformInstalled ||
        utf16ToUtf8(s->editingText) != input) return 1;
    if (offset16 < 0 || static_cast<size_t>(offset16) >= s->editingText.size()) return 24;
    uint32_t scalar = static_cast<uint32_t>(offset16);
    if (scalar > 0 && s->editingText[scalar] >= 0xdc00 && s->editingText[scalar] <= 0xdfff &&
        s->editingText[scalar - 1] >= 0xd800 && s->editingText[scalar - 1] <= 0xdbff) --scalar;
    const uint64_t byte = utf16ToUtf8(s->editingText.substr(0, scalar)).size();
    uint64_t start = 0, end = 0;
    const auto status = cjgui_internal_renderer_grapheme_cluster_range(input.c_str(), input.size(), byte, &start, &end);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    *outStart = static_cast<int32_t>(utf8ToUtf16(input.substr(0, start)).size());
    *outEnd = static_cast<int32_t>(utf8ToUtf16(input.substr(0, end)).size());
    return 0;
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
    // 人的新提交取代未完成的恢复：显示已经往前走，旧恢复的落点不再适用。
    cancelProxyRestoreRequest(*s, "human_commit_supersedes");
    const std::u16string previous = s->editingText;
    s->editingText = utf8ToUtf16(input);
    s->caretUtf16 = static_cast<uint32_t>(s->editingText.size());
    s->selStartUtf16 = s->caretUtf16;
    s->selEndUtf16 = s->caretUtf16;
    s->previewActive = false;
    s->previewText.clear();
    s->markedActive = false;
    editorEnqueueTextCommit(*s, previous, s->editingText);
    return 0;
}

// 无 marked 区间的整值变化 = 一次普通编辑（插入/删除/选区替换）。窗口声明
// 拥有该节点时它就是真实提交，不是视觉预览：系统代理的全文回调在这里转成
// **同版本精确范围增量**交付 owner，视图不被本地草稿遮盖，也不是"提交后才
// 落地"。组字中的变化走 preview_range_ctx（有 marked 区间），仍是预览。
// 返回 true 表示已按提交处理，或确认没有变化。
bool editorCommitPlainChangeLocked(Session &s, const std::u16string &next)
{
    // A freshly mounted TextInput can echo the already accepted text before
    // installing its selection. Text alone carries no new caret intention:
    // preserve the placed word/range and any in-flight restoration. A live
    // composition still goes through its original path. This applies equally
    // to generic explicit-submit fields: an echo must not create a false draft
    // that blocks their word hit testing and selection handles.
    if (next == s.editingText && !s.previewActive && !s.markedActive) return true;
    s.textMenuIntent = 0;
    if (!editorOwnsTextSession(s)) {
        // 具名定位：整值提交被降级为视觉预览的**唯一**原因是这一组会话声明不齐。
        // 不打印就无法区分「窗口没声明 owned text session」「声明了但没开范围增量」
        // 与「声明的节点身份与当前编辑节点不一致」——三者修法完全不同。
        static std::atomic<uint64_t> notOwnedReports{0};
        if (notOwnedReports.fetch_add(1) < 8) {
            RLOGW("ime plain change NOT owner: enabled=%{public}d deltaReq=%{public}d "
                  "declaredNode=%{public}llu editingNode=%{public}llu declaredKind=%{public}llu editingKind=%{public}llu "
                  "declaredRes=%{public}llu editingRes=%{public}llu",
                  s.ownedTextSessionEnabled ? 1 : 0, s.rangeEditDeltaRequested ? 1 : 0,
                  static_cast<unsigned long long>(s.ownedTextSessionNodeId),
                  static_cast<unsigned long long>(s.editingNodeId),
                  static_cast<unsigned long long>(s.ownedTextSessionNodeKind),
                  static_cast<unsigned long long>(s.editingNodeKind),
                  static_cast<unsigned long long>(s.ownedTextSessionResourceId),
                  static_cast<unsigned long long>(s.editingResourceId));
        }
        return false;
    }
    // 真实提交共同经过这里（onChange 整值变化与无 marked 的预览折入都走本入口）：
    // 人的编辑取代未完成的恢复，取消必须放在共同入口而不是某一个 ABI 外壳里。
    cancelProxyRestoreRequest(s, "human_commit_supersedes");
    const std::u16string previous = s.editingText;
    s.editingText = next;
    s.caretUtf16 = static_cast<uint32_t>(s.editingText.size());
    s.selStartUtf16 = s.caretUtf16;
    s.selEndUtf16 = s.caretUtf16;
    s.previewActive = false;
    s.previewText.clear();
    s.markedActive = false;
    // 畸形输入被具名拒绝时编辑缓冲已由 `editorEnqueueTextCommit` 恢复为
    // previous：这里仍返回 true（该变化由提交路径处理完毕），否则调用方会把
    // 同一段畸形文本当成视觉预览再贴回来。
    const bool committed = editorEnqueueTextCommit(s, previous, s.editingText);
    static_cast<void>(committed);
    return true;
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
        const std::u16string visibleBefore = composedBuffer(*s);
        const bool ownsEntry = editorOwnsTextSession(*s);
        const bool deliveredEntry = editorCommitPlainChangeLocked(*s, utf8ToUtf16(input));
        {
            // 入口归属诊断：区分「整值提交被降级成预览」与「组合/带 marked 区间
            // 只做视觉预览」。两者在外部都表现为 owner 不动，修法完全不同。
            static std::atomic<uint64_t> previewTextReports{0};
            if (previewTextReports.fetch_add(1) < 6) {
                RLOGI("ime preview_text entry: owns=%{public}d delivered=%{public}d bytes=%{public}zu",
                      ownsEntry ? 1 : 0, deliveredEntry ? 1 : 0, input.size());
            }
        }
        if (deliveredEntry) {
            // 提交已交付：本轮仍需要重绘（下一帧 accepted 会接管可见文本）。
        } else {
            s->previewText = utf8ToUtf16(input);
            s->previewStart = 0;
            s->previewEnd = static_cast<uint32_t>(s->editingText.size());
            s->previewActive = true;
            s->markedActive = false;
            s->caretUtf16 = static_cast<uint32_t>(s->previewText.size());
        }
        if (visibleBefore != composedBuffer(*s)) s->caretBlinkResetPending = true;
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
        const std::u16string visibleBefore = composedBuffer(*s);
        s->textMenuIntent = 0;
        {
            // 本入口**只做视觉预览**（没有 commit 分支）。记录它被普通系统输入
            // 命中的事实，才能区分「owner 不动」是设计（组合中）还是缺提交路径。
            static std::atomic<uint64_t> previewRangeReports{0};
            if (previewRangeReports.fetch_add(1) < 6) {
                RLOGI("ime preview_range entry: bytes=%{public}zu marked=%{public}d:%{public}d "
                      "owns=%{public}d",
                      input.size(), start, end, editorOwnsTextSession(*s) ? 1 : 0);
            }
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
        if (visibleBefore != composedBuffer(*s)) s->caretBlinkResetPending = true;
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
    // R1（生产反例 finish(A=13)→bind(B=14)）：finish 也是收场入口，必须在此
    // 冻结将死身份。此前不冻结，pump 回读"当前"上下文——finish 后再绑定 B 时
    // end 会误寄 14/B，A 的代理永远收不到收场通知。
    // 平台已提交，不再重复结算（settle=false）。
    pushPendingEndLocked(*s, contextId, s->editingFieldName, false);
    cancelProxyRestoreRequest(*s, "finished");
    return 0;
}

// 通用窗口诊断出口（框架可观测性，不承载任何业务语义）：Cangjie 侧的
// `println` 在 OHOS **不进 hilog**，窗口内部的判定（是否重建编辑会话、身份是否
// 命中、被哪条具名分支拒绝）在设备上完全不可见——2026-10-01 的模式切换排查正是
// 卡在这一步。这个出口只把调用方给的字符串原样记进渲染器日志，不读写会话状态，
// 因此任何窗口代码都能用它留证，而无需为每处判定新增专用 ABI。
extern "C" int32_t ohos_renderer_window_log(const char *message)
{
    if (!message) return -1;
    RLOGI("window-diag: %{public}s", message);
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
        // 转发判据与 changed 分开：平台装好人的落点之后回声的值常常正好等于命中测试
        // 写下的 native 值（changed=false），而窗口恰恰需要这条"平台已安装"的观测才能
        // 核验人类锚、解除外部换版留下的输入门禁。按 changed 判重就是首字丢失的根因。
        const bool forward = selectionObservationNeedsForwarding(*s, a, b);
        if (forward && !editorEnqueueSelectionChanged(*s, a, b)) {
            RLOGW("ime selection rejected: no matching accepted binding ctx=%{public}lld node=%{public}llu",
                  static_cast<long long>(contextId), static_cast<unsigned long long>(s->editingNodeId));
            return 1;
        }
        if (forward) {
            rememberForwardedSelectionLocked(*s, a, b);
            if (!changed) {
                RLOGI("ime selection observation forwarded ctx=%{public}lld sel=%{public}u:%{public}u native_changed=0",
                      static_cast<long long>(contextId), a, b);
            }
        }
        // An initial word installation may echo while the finger has already
        // moved. It is still an installation fact, not the latest visual extent.
        const bool movingSelection = s->selectionDrag.active && s->selectionDrag.anchorReady &&
            !s->selectionDrag.terminal;
        if (!movingSelection) {
            s->selStartUtf16 = a;
            s->selEndUtf16 = b;
            s->caretUtf16 = b;
        } else {
            changed = false;
        }
        if (changed) {
            if (a == b) s->textMenuIntent = 0;
            s->caretBlinkResetPending = true;
            s->caretAffinity = 0;
        }
        // 回声就是平台的当前落点：账本同步，pump 的差分推送不会再把它推回去
        // （否则"平台装 → native 推 → 平台装"会自激）。
        s->selPlatformStart = a;
        s->selPlatformEnd = b;
    }
    // 选区/光标是纯视觉投影：不 bump 场景版本，必须显式请求重绘，否则拖动
    // 系统选择手柄期间没有新帧，高亮停留在上一次绘制的状态（实测手动拖选
    // 无高亮的根因）。与预览路径（ime_preview_text_ctx）同一重绘机制。
    if (changed) {
        g_render.post(std::make_shared<RedrawJob>());
    }
    return 0;
}

// Toolbar commands retain the original whole text and selection across the
// system pasteboard await. A stale result cannot be rebound to another owner.
// This is a private platform adapter; business edits still use the same FIFO.
bool editorApplyMenuCommandLocked(Session &s, const std::string &action,
    const std::u16string &expected, const std::u16string &inserted,
    uint64_t generation, uint64_t base, int32_t start, int32_t end)
{
    if (!s.editingContextLive || s.editorRetired || s.previewActive || s.markedActive ||
        s.proxyRestore.armed || s.proxyRestore.awaitingAck || s.proxyRestore.platformInstalled ||
        (s.selectionDrag.active && !s.selectionDrag.terminal) ||
        generation != s.editingContextGeneration || base != s.editingContextBaseVersion ||
        expected != s.editingText || start < 0 || end < start ||
        static_cast<uint32_t>(start) != s.selStartUtf16 ||
        static_cast<uint32_t>(end) != s.selEndUtf16 ||
        static_cast<size_t>(end) > expected.size() ||
        !utf16IsScalarBoundary(expected, static_cast<size_t>(start)) ||
        !utf16IsScalarBoundary(expected, static_cast<size_t>(end)) ||
        !utf16IsWellFormed(inserted)) return false;
    if (action == "validate") return true;
    if (action == "selectAll") {
        s.textMenuIntent = 1;
        s.selStartUtf16 = 0;
        s.selEndUtf16 = s.caretUtf16 = static_cast<uint32_t>(expected.size());
    } else if (action == "replace") {
        s.textMenuIntent = 0;
        const std::u16string next = expected.substr(0, start) + inserted + expected.substr(end);
        const uint32_t caret = static_cast<uint32_t>(start + inserted.size());
        if (editorOwnsTextSession(s)) {
            cancelProxyRestoreRequest(s, "human_menu_supersedes");
            s.editingText = next;
            s.selStartUtf16 = s.selEndUtf16 = s.caretUtf16 = caret;
            if (next != expected && !editorEnqueueTextCommit(s, expected, s.editingText)) return false;
        } else {
            // Preserve generic fields' explicit-submit contract. Enter/blur
            // performs their existing settlement, not the platform toolbar.
            s.previewText = next;
            s.previewStart = 0;
            s.previewEnd = static_cast<uint32_t>(expected.size());
            s.previewActive = next != expected;
            s.selStartUtf16 = s.selEndUtf16 = s.caretUtf16 = caret;
        }
    } else return false;
    s.caretBlinkResetPending = true;
    s.caretAffinity = 0;
    s.humanCaretNotificationPending = true;
    return true;
}

extern "C" int32_t ohos_renderer_ime_menu_command_ctx(const char *action,
    const char *expected, size_t expectedLength, const char *inserted, size_t insertedLength,
    int64_t context, uint64_t generation, uint64_t base, int32_t start, int32_t end)
{
    bool ok = false;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        Session *s = takeEditingContextLocked(context);
        if (s && action && expected && inserted) {
            ok = editorApplyMenuCommandLocked(*s, action,
                utf8ToUtf16(std::string(expected, expectedLength)),
                utf8ToUtf16(std::string(inserted, insertedLength)), generation, base, start, end);
        }
        RLOGI("ime menu command ctx=%{public}lld action=%{public}s range=%{public}d:%{public}d accepted=%{public}d",
            static_cast<long long>(context), action ? action : "", start, end, ok ? 1 : 0);
    }
    if (ok && std::strcmp(action, "validate") != 0) g_render.post(std::make_shared<RedrawJob>());
    return ok ? 0 : 1;
}

// ACK 的会话定位按 contextId→票据归属查找：请求属于哪个编辑上下文，回执就只能落到
// 那个会话的票据上（Astra 复核第 5 点：不得取"第一个仍在编辑的会话"）。槽位已结清
// 时没有任何会话匹配，迟到的重复回执一律被拒，不会改写当前票据。
static Session *findSessionByRestoreContextLocked(int64_t contextId, uint64_t requestId)
{
    if (contextId == 0) return nullptr;
    for (size_t i = 0; i < kMaxSessions; ++i) {
        Session &candidate = g_sessions.sessions[i];
        const Session::ProxyRestoreRequest &req = candidate.proxyRestore;
        if (!candidate.inUse || req.requestId == 0 || req.contextId != contextId) {
            continue;
        }
        if (req.requestId == requestId || req.armed || req.awaitingAck || req.platformInstalled) {
            return &candidate;
        }
    }
    return nullptr;
}

// 平台安装回执。语义（H1-R/Astra 裁决）：
//   * 按 contextId 定位请求所属会话，不取"第一个仍在编辑的会话"；
//   * 同一 requestId 的迟到/重复回执返回既有裁决，不重复计终态；
//   * ok=0（平台明确失败）终结请求，让窗口的有界重试重新签发，绝不记成功；
//   * ok=1 只有在**观测落点精确等于签发前的规范目标**时才算平台安装：合法的错误
//     落点（目标 4:9、平台 13:13）一律具名失败，不以"落点合法"迁就采纳；
//   * 成功后投递 kind-55（recordIndex=0，带实际区间与请求号），窗口核验并原子
//     采纳之后调用 consume 票据；native 不在此解除任何会话锁。
// 返回 0 = 回执被接受；1 = 被拒绝（无请求、请求号不符、身份已变、区间非法）。
extern "C" int32_t ohos_renderer_ime_restore_ack_ctx(int64_t contextId, uint64_t requestId,
                                                     int32_t selStart, int32_t selEnd, int32_t ok)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = findSessionByRestoreContextLocked(contextId, requestId);
    if (!s) {
        RLOGW("proxy restore ack rejected: no session owns ctx=%{public}lld req=%{public}llu",
              static_cast<long long>(contextId), static_cast<unsigned long long>(requestId));
        return 1;
    }
    Session::ProxyRestoreRequest &req = s->proxyRestore;
    if (requestId == 0 || req.requestId != requestId) {
        // 不是当前票据号：先查既有终局并原样返回，绝不改写当前票据；没有终局记录
        // 就是陌生/串号回执——即使此刻有一张别的票在等，也不能替它签收。
        for (const Session::ProxyRestoreTerminal &t : s->proxyRestoreTerminals) {
            if (t.requestId == requestId) {
                RLOGI("proxy restore ack late request=%{public}llu code=%{public}d reason=%{public}s",
                      static_cast<unsigned long long>(requestId), t.code, t.reason.c_str());
                return t.code == CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED ||
                       t.platformInstalled ? 0 : 1;
            }
        }
        RLOGW("proxy restore ack rejected: unknown/stale request ctx=%{public}lld req=%{public}llu "
              "active=%{public}llu awaiting=%{public}d armed=%{public}d",
              static_cast<long long>(contextId), static_cast<unsigned long long>(requestId),
              static_cast<unsigned long long>(req.requestId),
              req.awaitingAck ? 1 : 0, req.armed ? 1 : 0);
        return 1;
    }
    if (req.platformInstalled) {
        // 重复成功回执：返回已有结果，不重复投递终态。
        return 0;
    }
    if (!req.awaitingAck) {
        RLOGW("proxy restore ack rejected: not awaiting ctx=%{public}lld req=%{public}llu",
              static_cast<long long>(contextId), static_cast<unsigned long long>(requestId));
        return 1;
    }
    if (ok == 0) {
        terminateProxyRestoreRequestLocked(*s, "platform_install_failed");
        return 0;
    }
    // 冻结身份必须仍等于当前身份：换焦/换绑/结束/外部换版之后到达的旧回执不解锁。
    if (s->editingContextId != req.contextId ||
        s->editingContextGeneration != req.contextGeneration ||
        s->editingNodeId != req.nodeId || s->editingResourceId != req.resourceId ||
        s->editingNodeKind != req.nodeKind || s->editingFieldName != req.fieldName) {
        RLOGW("proxy restore ack rejected: identity changed ctx=%{public}lld native=%{public}lld "
              "req=%{public}llu node=%{public}llu nativeNode=%{public}llu",
              static_cast<long long>(req.contextId), static_cast<long long>(s->editingContextId),
              static_cast<unsigned long long>(requestId),
              static_cast<unsigned long long>(req.nodeId),
              static_cast<unsigned long long>(s->editingNodeId));
        terminateProxyRestoreRequestLocked(*s, "identity_changed");
        return 1;
    }
    const uint32_t size = static_cast<uint32_t>(req.text.size());
    if (selStart < 0 || selEnd < static_cast<int32_t>(selStart) ||
        static_cast<uint32_t>(selEnd) > size) {
        RLOGW("proxy restore ack rejected: range out of bounds req=%{public}llu range=%{public}d:%{public}d size=%{public}u",
              static_cast<unsigned long long>(requestId), selStart, selEnd, size);
        terminateProxyRestoreRequestLocked(*s, "range_out_of_bounds");
        return 1;
    }
    if (clampToCodePointBoundary(req.text, static_cast<uint32_t>(selStart)) !=
            static_cast<uint32_t>(selStart) ||
        clampToCodePointBoundary(req.text, static_cast<uint32_t>(selEnd)) !=
            static_cast<uint32_t>(selEnd)) {
        RLOGW("proxy restore ack rejected: non_scalar_boundary req=%{public}llu range=%{public}d:%{public}d",
              static_cast<unsigned long long>(requestId), selStart, selEnd);
        terminateProxyRestoreRequestLocked(*s, "non_scalar_boundary");
        return 1;
    }
    // 规范目标等式：观测落点必须精确等于签发前冻结的目标。合法的错误落点不采纳。
    if (static_cast<uint32_t>(selStart) != req.selStart || static_cast<uint32_t>(selEnd) != req.selEnd) {
        RLOGW("proxy restore ack rejected: installed_range_mismatch req=%{public}llu "
              "target=%{public}u:%{public}u observed=%{public}d:%{public}d",
              static_cast<unsigned long long>(requestId), req.selStart, req.selEnd, selStart, selEnd);
        req.received = true;
        req.observedStart = static_cast<uint32_t>(selStart);
        req.observedEnd = static_cast<uint32_t>(selEnd);
        terminateProxyRestoreRequestLocked(*s, "installed_range_mismatch");
        return 1;
    }
    req.received = true;
    req.platformInstalled = true;
    req.observedStart = static_cast<uint32_t>(selStart);
    req.observedEnd = static_cast<uint32_t>(selEnd);
    req.awaitingAck = false;
    req.reported = false;
    s->selStartUtf16 = static_cast<uint32_t>(selStart);
    s->selEndUtf16 = static_cast<uint32_t>(selEnd);
    s->caretUtf16 = static_cast<uint32_t>(selEnd);
    // 平台已按观测装上这份落点：账本同步，差分推送不再重复通知。
    s->selPlatformStart = static_cast<uint32_t>(selStart);
    s->selPlatformEnd = static_cast<uint32_t>(selEnd);
    QueuedEvent ev;
    ev.kind = kEvTextProxyRestored;  // 55
    ev.recordIndex = 0;              // 平台已安装（观测确认），窗口可尝试原子采纳
    ev.nodeId = req.nodeId;
    ev.resourceId = req.resourceId;
    ev.nodeKind = req.nodeKind;
    ev.projectionVersion = req.acceptedProjectionVersion;
    ev.acceptedBindingEpoch = req.acceptedBindingEpoch;
    ev.bindingEpoch = req.requestId;  // 请求身份：窗口据此拒绝与自己待办不符的回执
    ev.selectionStart = static_cast<uint32_t>(selStart);
    ev.selectionEnd = static_cast<uint32_t>(selEnd);
    ev.text = "platform_installed";
    s->events.push_back(ev);
    RLOGI("proxy restore ack accepted request=%{public}llu ctx=%{public}lld node=%{public}llu "
          "installed=%{public}d:%{public}d v=%{public}llu",
          static_cast<unsigned long long>(req.requestId), static_cast<long long>(req.contextId),
          static_cast<unsigned long long>(req.nodeId), selStart, selEnd,
          static_cast<unsigned long long>(req.acceptedProjectionVersion));
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
