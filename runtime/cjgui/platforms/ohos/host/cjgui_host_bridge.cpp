// CJGUI HarmonyOS host bridge (entry module side).
//
// Responsibilities (platform only, no business truth):
//  - napi module + XComponent surface/touch callbacks (UI thread)
//  - surface lease with generations (mirrors labs/ohos_gui_smoke pattern)
//  - touch/lifecycle ingress queue for the Cangjie app thread
//  - dlopen the Cangjie app library and start its app loop via the
//    registered entry points
//
// The renderer ABI (cjgui_internal_renderer_*) is implemented inside the
// Cangjie app library (statically linked ohos renderer). The two sides talk
// through explicitly registered function pointers, so no cross-library
// symbol resolution is required.

#include <ace/xcomponent/native_interface_xcomponent.h>
#include <arkui/native_node_napi.h>
#include <hilog/log.h>
#include <napi/native_api.h>
// A2：surface 真实存活许可。OH_NativeWindow_NativeObjectReference / Unreference
// 用于在租约存续期间把底层 NativeWindow 的引用计数加一，使渲染线程在
// 创建/使用/Flush/teardown 全过程中持有的是**有引用保护**的对象；
// 该接口自 8.0.0 起可用，文档明确标注为非线程安全，因此只在 UI 线程回调里
// 成对调用（reference 在 onSurfaceCreated，unreference 在 onSurfaceDestroyed）。
#include <native_window/external_window.h>

#include "cjgui_ohos_ingress.h"

#include <dlfcn.h>
#include <algorithm>
#include <cmath>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <deque>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace cjgui_host {

constexpr uint32_t CJGUI_LOG_DOMAIN = 0x0000;
constexpr const char *CJGUI_LOG_TAG = "CjguiHost";

#define HLOGI(...) OH_LOG_Print(LOG_APP, LOG_INFO, CJGUI_LOG_DOMAIN, CJGUI_LOG_TAG, __VA_ARGS__)
#define HLOGE(...) OH_LOG_Print(LOG_APP, LOG_ERROR, CJGUI_LOG_DOMAIN, CJGUI_LOG_TAG, __VA_ARGS__)
#define HLOGW(...) OH_LOG_Print(LOG_APP, LOG_WARN, CJGUI_LOG_DOMAIN, CJGUI_LOG_TAG, __VA_ARGS__)

// ---------------------------------------------------------------------------
// Ingress record shared with the Cangjie side through an explicit pointer.
// Kept as a plain C struct so both sides agree on the layout.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Surface lease + queues (owned by this module; UI thread writes, the
// renderer side reads through the ingress pointers).
// ---------------------------------------------------------------------------
namespace {

// A2（Sol 复核后返工）：每代 surface 的**独立记录**。
//
// 旧实现只有一个 `g_lease` 快照（generation/window/size/active），并把它当作
// 「当前 surface」；被 Sol 指出四点不足：
//   1) UI 回调里 400ms 静默等待后归还引用——等待时长不能推导资源安全；
//   2) 引用失败仍然发布 active；
//   3) 同尺寸/同组件 ID/同指针地址被当成同一代（缺少完整身份）；
//   4) `busyGeneration` 只盖住闸门之后到 Flush 之前，redraw 的 Flush 不在其内，
//      不能充当创建/绘制/teardown 的静默判据。
//
// 现在：每次 surface 创建分配**不复用**的 componentInstance + surfaceGeneration，
// 记录完整五元身份（appInstance/sessionToken 由渲染器侧持有并回传核对/
// componentInstance/surfaceGeneration/geometryRevision），并在宿主持有
// NativeWindow 引用期间允许渲染线程按身份取得使用许可。旧代在拆除完成前
// 一直留在表里——同尺寸、同 ID、同地址都不能合并两代。
struct SurfaceRecord {
    // 五元身份（都不复用）
    uint64_t appInstance = 0;
    uint64_t componentInstance = 0;
    uint64_t generation = 0;
    uint64_t geometryRevision = 0;
    std::string componentId;
    // 平台对象与几何
// 第九次复核 A3：backend 0=真实 XComponent window；1=测试后端替身会话
    // （身份/准入/许可/退役规则与真实记录完全同一套；window 为非空哨兵，
    //  绝不发布真实 XComponent 裸指针，真实引用路径一律跳过）。
    int32_t backend = 0;
    void *window = nullptr;
    int32_t width = 0;
    int32_t height = 0;
    double density = 1.0;
    // 状态
    bool active = false;            // 允许取得新许可
    bool retired = false;           // 已退役（不再允许新许可）
    bool nativeRefHeld = false;     // 本代是否持有一次成功的 NativeObjectReference
    bool nativeRefReleased = false; // 引用是否已归还（严格配对，不重复归还）
    bool nativeRefReleasePending = false;  // 归还已投递到 UI 线程、尚未执行
    bool nativeRefFailed = false;   // 引用从未取到（refRc != 0），无引用可归还
    bool nativeRefUnavailable = false; // KnownShimNoRef：本运行时引用能力不可用
                                       // （degradedActive：可发布但不持有、不归还）
    bool teardownAcked = false;     // destroyed fence：渲染线程拆除确认已收到
    int64_t teardownAckedAtMs = 0;
    bool admissionClosed = false;   // 第七次复核 Q1：fence 超时后该代准入永久关闭
    // 审计指针存根：window 在 fence ACK/归还后被清除；仅受控模拟重建路径
    // （真实 XComponent 仍在、对象确定存活）允许读取，真实运行路径禁止触碰。
    // 审计存根：window 清除时的最后指针身份，仅诊断读数；
    // 复核8 §2.4 后**没有**任何路径从 auditWindow 取指针做 Reference/Create。
    void *auditWindow = nullptr;
    bool tornDown = false;          // 渲染线程已确认拆除该代（SurfaceDestroy + GPU 释放）
    int32_t inFlight = 0;           // 渲染线程当前持有的使用许可数
    uint64_t grantedPermits = 0;
    uint64_t releasedPermits = 0;
    // 退役观察（只读取证）
    int64_t retireRequestedAtMs = 0;
    int64_t refReleasedAtMs = 0;
};

    // 第九次复核 B：UI 线程维护的**当前挂载事实**（与退休记录分离）。
// onSurfaceCreated 登记、onSurfaceDestroyed 使失效——即使对应记录未获
// 渲染准入也照样失效；退休记录只用于结算与诊断，不再是资源来源。
struct MountFact {
    void *window = nullptr;
    uint64_t mountEpoch = 0;      // 每次登记递增（带身份）
    uint64_t appInstance = 0;
    std::string componentId;
    int32_t width = 0;
    int32_t height = 0;
    bool valid = false;
};
MountFact g_mountFact;            // g_leaseMutex 同锁保护

std::mutex g_leaseMutex;
std::vector<SurfaceRecord> g_surfaces;
uint64_t g_currentGeneration = 0;  // 当前 active 代（0 = 无）
uint64_t g_nextGeneration = 1;
uint64_t g_nextComponentInstance = 1;
uint64_t g_nextGeometryRevision = 1;
// A3：每次获准启动分配一个不复用的应用实例编号。旧实例回调不得读写
// 「当前实例」槽，停止判据也必须对同一个 appInstance 成立。
std::atomic<uint64_t> g_appInstance{0};
uint64_t g_nextAppInstance = 1;
// A3：本实例的 owner 声明（只由 owner 线程写；停止监控线程与 HostState 读）。
std::atomic<bool> g_ownerReady{false};
std::atomic<bool> g_ownerExited{false};

int64_t nowMs() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(
               std::chrono::system_clock::now().time_since_epoch())
        .count();
}

// 按 window 找**仍可用**的记录：从最新往回找，跳过已退役/已拆除。
// 同尺寸/同组件 ID/同指针地址都不允许把两代合并成一代（Sol 第 3 点）。
SurfaceRecord *findSurfaceLocked(void *window) {
    if (window == nullptr) return nullptr;
    for (auto it = g_surfaces.rbegin(); it != g_surfaces.rend(); ++it) {
        if (it->window == window && !it->retired && !it->tornDown) return &*it;
    }
    return nullptr;
}

SurfaceRecord *findSurfaceByGenerationLocked(uint64_t generation) {
    if (generation == 0) return nullptr;
    for (SurfaceRecord &rec : g_surfaces) {
        if (rec.generation == generation) return &rec;
    }
    return nullptr;
}

// A2 取证计数：reference/unreference 的配对与次数。
std::atomic<int64_t> g_nativeRefCount{0};
std::atomic<int64_t> g_nativeUnrefCount{0};
// 未能归还的引用数（超时/未收敛时保留，用于「不谎称已释放」的取证）。
std::atomic<int64_t> g_nativeRefPendingCount{0};
// verify-transport 测试接缝在场（HostState/闸门命令通道可用）——
// 同时作为 KnownShimNoRef 替身模式的门控条件（仅测试变体发布）。
static bool g_transportVerifyPresent = false;
// 跨接缝解析完成标志：surface 回调（UI 线程）可能早于独立准备过程，
// 分类前不得凭空调用 provider 符号；未解析时挂起事实，解析完成后补分类。
static std::atomic<bool> g_entryPointsResolved{false};
// 第八次复核链1：独立启动准备过程——库装载+入口解析由 napi Init 启动的
// 准备线程执行，不依赖 XComponent onLoad→startHost。实测 OnSurfaceCreated
// 先于 onLoad 到达时，回调内等待解析会与 startHost 形成互等死锁
// （appfreeze THREAD_BLOCK_6S：vsync→SyncGeometryNode→libentry sleep_for）。
static std::mutex g_prepareMutex;
static std::condition_variable g_prepareCv;
static std::atomic<bool> g_prepareStarted{false};
static bool g_prepareDone = false;
static std::thread g_prepareThread;
// 链1：surface 先于解析到达时的挂起事实。UI 线程写，补分类在 UI 线程
//（TSFN call_js_cb）消费；destroyed 到来即取消——窗口保活由 destroyed 界定。
struct DeferredSurface {
    bool valid = false;
    OH_NativeXComponent *component = nullptr;
    void *window = nullptr;
    char id[128] = {0};
    uint64_t width = 0;
    uint64_t height = 0;
};
static std::mutex g_deferredSurfaceMutex;
static DeferredSurface g_deferredSurface;
static napi_threadsafe_function g_surfaceClassifyFn = nullptr;
// 第六次复核第 1 项（Sol Q1/Q4）：引用能力三态与生命周期收敛计数。
enum class RefCapability {
    kUndetermined,       // 尚未判定（首代创建时判定一次）
    kVerifiedNativeRef,  // Reference==0 且符号来自非应用私有目录：真实引用可用
    kKnownShimNoRef,     // 已知 shim（应用私有库 + rc==对象低32位非零）：degradedActive
    kRefUnavailable      // 其他一切：失败关闭，不发布 surface
};
RefCapability g_refCapability = RefCapability::kUndetermined;
std::string g_refProviderLib;                 // 首次判定的装载库路径
std::atomic<int64_t> g_surfaceCreatedCount{0};
std::atomic<int64_t> g_surfaceDestroyedCount{0};
std::atomic<int64_t> g_destroyFenceTimeouts{0};
std::atomic<int64_t> g_oldGenEventsRejected{0};   // 退役代触摸/许可被拒次数
std::condition_variable g_teardownCv;             // destroyed fence 的 ACK 通知
// destroyed fence 上限：正常拆除毫秒级；超时即该代失败（不得宣称可用）。
constexpr int64_t kDestroyFenceTimeoutMs = 2000;

// 首次调用时的能力判定（Sol Q1 三态）。判据缺一不可：
//  - kVerifiedNativeRef：rc==0 且符号不在应用私有库（真机平台实现）。
//  - kKnownShimNoRef：rc!=0、符号来自应用私有目录、且 rc==对象指针低 32 位
//    （HAP 内 sysroot shim 的 bare-ret 语义，实测证据见
//    run/ref_abi_probe/ref_contract_analysis.md）。
//  - 其他一切：kRefUnavailable（失败关闭）。
RefCapability classifyRefCall(void *window, int32_t rc) {
    Dl_info info;
    std::memset(&info, 0, sizeof(info));
    const char *lib = "unresolved";
    const bool haveLib = dladdr(reinterpret_cast<void *>(&OH_NativeWindow_NativeObjectReference), &info) &&
                         info.dli_fname != nullptr;
    if (haveLib) {
        lib = info.dli_fname;
    }
    g_refProviderLib = lib;
    // 第七次复核 B：无法核验符号来源（dladdr 失败）时，即使 rc==0 也不得
    // 判定 VerifiedNativeRef——来源未知的能力必须失败关闭。
    if (!haveLib) {
        return RefCapability::kRefUnavailable;
    }
    const bool fromAppPrivate =
        std::strstr(lib, "/data/storage/el1/bundle/libs/") != nullptr ||
        std::strstr(lib, "/data/app/") != nullptr;
    if (rc == 0 && !fromAppPrivate) {
        return RefCapability::kVerifiedNativeRef;
    }
    const uint32_t rcLow = static_cast<uint32_t>(static_cast<uint32_t>(rc));
    const uint32_t objLow = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(window) & 0xffffffffu);
    if (rc != 0 && fromAppPrivate && rcLow == objLow) {
        return RefCapability::kKnownShimNoRef;
    }
    return RefCapability::kRefUnavailable;
}

// 统一的引用获取：三态裁决 → {held, degradedActive, failed}。
// 已知 shim 档只调用一次 Reference（取证），从不配对 Unreference；
// 失败关闭档不发布 active。每代原始返回值/身份照记（Sol Q4 逐代证据）。
struct RefOutcome {
    int32_t rc = -1;
    bool held = false;        // 真实持有一次成功引用（仅 Verified 档）
    bool degradedActive = false; // KnownShimNoRef：可发布 active 但不持有
    bool failed = false;      // 引用未取得（含 shim 档语义上的「未持有」）
};
// 第九次复核 B：夹具拦截器（TEST_GATES 变体定义；普通构建裁剪）。
#ifdef CJGUI_OHOS_TEST_GATES
static std::atomic<bool> g_refFixtureArmed{false};
static std::atomic<int64_t> g_refFixtureReferenceCalls{0};
#endif
RefOutcome acquireNativeRef(void *window) {
    RefOutcome o;
    if (window == nullptr) {
        o.failed = true;
        g_refCapability = RefCapability::kRefUnavailable;
        return o;
    }
#ifdef CJGUI_OHOS_TEST_GATES
    if (g_refFixtureArmed.load()) {
        // The negative fixture must count attempted references without ever
        // passing its poison pointer to the platform implementation.
        g_refFixtureReferenceCalls.fetch_add(1);
        o.failed = true;
        return o;
    }
#endif
    o.rc = OH_NativeWindow_NativeObjectReference(window);
    if (g_refCapability == RefCapability::kUndetermined) {
        g_refCapability = classifyRefCall(window, o.rc);
        HLOGI("ref capability decided: resolved=%{public}d transportPresent=%{public}d capability=%{public}s provider=%{public}s rc=%{public}d",
          g_entryPointsResolved.load() ? 1 : 0,
          g_transportVerifyPresent ? 1 : 0,
          g_refCapability == RefCapability::kVerifiedNativeRef ? "VerifiedNativeRef"
              : g_refCapability == RefCapability::kKnownShimNoRef ? "KnownShimNoRef"
                                                                  : "RefUnavailable",
          g_refProviderLib.c_str(),
          static_cast<int>(o.rc));
    }
    switch (g_refCapability) {
        case RefCapability::kVerifiedNativeRef:
            o.held = (o.rc == 0);
            o.failed = !o.held;
            break;
        case RefCapability::kKnownShimNoRef:
            // 第七次复核 Q3（Astra 裁决）：非测试构建拒绝发布 degradedActive
            // ——无真实引用时无法证明 destroyed 回调返回后零悬空使用（已
            // 实测 SIGSEGV 复现）。verify-transport 测试构建允许替身模式
            // （fence + 恢复即中止 + 零引用账目），账目/识别保留。
            if (g_transportVerifyPresent) {
                o.degradedActive = true;
            }
            o.failed = true;
            break;
        default:
            o.failed = true;
            break;
    }
    return o;
}
// 退役静默读数（渲染器实现，`cjgui_ohos_renderer_lease_quiesced`）。
// **只作取证读数，不作归还判据**：Sol 第 4 点指出 busyGeneration 只盖住
// 闸门之后到 Flush 之前、redraw 的 Flush 不在其内；等待时长也不能推导资源安全。
using LeaseQuiescedFn = int32_t (*)(uint64_t);
LeaseQuiescedFn leaseQuiescedFn = nullptr;
// 渲染器提供的「请求拆除某一代」入口（UI 线程调用，立即返回）。
using RequestSurfaceTeardownFn = int32_t (*)(uint64_t);
RequestSurfaceTeardownFn g_requestSurfaceTeardownFn = nullptr;
// A2/A3 取证与复位入口。
using ResetInstanceObservationsFn = int32_t (*)();
using OwnerAppReadyFn = int32_t (*)();
using SurfacePermitCountersFn = int32_t (*)(int64_t *, int64_t *, uint64_t *);
using SettlementReadoutFn = int32_t (*)(int32_t *, int64_t *, int64_t *);
ResetInstanceObservationsFn g_resetInstanceObservationsFn = nullptr;
OwnerAppReadyFn g_ownerAppReadyFn = nullptr;
SurfacePermitCountersFn g_surfacePermitCountersFn = nullptr;
SettlementReadoutFn g_settlementReadoutFn = nullptr;

// A3 停止判据：本实例的 surface 账目。
// 返回「未闭合条目数」——仍在途的使用许可，或尚未归还的 native 引用。
// 判据要求它是 0；正在被使用（active）的 surface 单列在 outActiveSurfaces，
// 因为「停止后仍有 surface 在服役」是另一个事实，不能混进同一个数里。
int64_t surfaceAccountingForInstance(uint64_t instance, int32_t *outActiveSurfaces) {
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    int64_t unclosed = 0;
    int32_t activeCount = 0;
    for (const SurfaceRecord &rec : g_surfaces) {
        if (rec.appInstance != instance) continue;
        if (rec.inFlight != 0) unclosed += 1;
        if (rec.nativeRefHeld && !rec.nativeRefReleased) unclosed += 1;
        if (!rec.tornDown && !rec.retired) activeCount += 1;
    }
    if (outActiveSurfaces) *outActiveSurfaces = activeCount;
    return unclosed;
}

// A3 停止接单（surface 侧）：把本实例所有 surface 立即退役并投递拆除。
// 必须在渲染线程真实结束使用后，引用才会经 surfaceTornDown 回传归还。
// 返回投递的拆除请求数。
static void retireTouchSurfaceLocked(uint64_t appInstance, uint64_t componentInstance,
                                     uint64_t generation, float cancelX, float cancelY);
std::mutex g_touchMutex;

int32_t retireAllSurfacesOfInstance() {
    struct RetiredTouchSurface {
        uint64_t appInstance;
        uint64_t componentInstance;
        uint64_t generation;
    };
    std::vector<uint64_t> generations;
    std::vector<RetiredTouchSurface> touchSurfaces;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &rec : g_surfaces) {
            if (rec.tornDown) continue;
            if (!rec.active && rec.retired) continue;   // 已退役、拆除在途
            if (!rec.active) continue;                  // 从未发布（引用失败）→ 无需拆除
            rec.retired = true;
            rec.active = false;
            rec.retireRequestedAtMs = nowMs();
            if (g_currentGeneration == rec.generation) {
                g_currentGeneration = 0;
            }
            generations.push_back(rec.generation);
            touchSurfaces.push_back(RetiredTouchSurface{rec.appInstance, rec.componentInstance,
                                                         rec.generation});
        }
    }
    {
        std::lock_guard<std::mutex> lock(g_touchMutex);
        for (const RetiredTouchSurface &surface : touchSurfaces) {
            retireTouchSurfaceLocked(surface.appInstance, surface.componentInstance,
                                     surface.generation, 0.0f, 0.0f);
        }
    }
    if (g_requestSurfaceTeardownFn != nullptr) {
        for (uint64_t generation : generations) {
            g_requestSurfaceTeardownFn(generation);
        }
    }
    return static_cast<int32_t>(generations.size());
}

enum TouchAction : uint32_t {
    kTouchBegin = 37,
    kTouchUpdate = 38,
    kTouchEnd = 39,
    kTouchCancel = 40,
};

struct TouchRecord {
    uint32_t action;
    float x;
    float y;
    uint64_t appInstance;
    uint64_t componentInstance;
    uint64_t generation;
    int64_t pointerId;
    uint64_t epoch;
    // B（惯性包）：采样时间。优先 SDK 的 touch.timeStamp（单调 ns）；取数
    // 失败或字段无效时以入队前捕获的 steady_clock 兜底（来源标记于
    // timeSource，0=平台原时间 1=桥接收时间）。禁止出队时统一补“现在”。
    int64_t timestampNs = 0;
    uint32_t timeSource = 0;
};

struct GestureKey {
    uint64_t appInstance;
    uint64_t componentInstance;
    uint64_t generation;
    int64_t pointerId;
    uint64_t epoch;

    bool operator<(const GestureKey &other) const {
        if (appInstance != other.appInstance) return appInstance < other.appInstance;
        if (componentInstance != other.componentInstance) return componentInstance < other.componentInstance;
        if (generation != other.generation) return generation < other.generation;
        if (pointerId != other.pointerId) return pointerId < other.pointerId;
        return epoch < other.epoch;
    }
    bool operator==(const GestureKey &other) const {
        return appInstance == other.appInstance && componentInstance == other.componentInstance &&
               generation == other.generation && pointerId == other.pointerId && epoch == other.epoch;
    }
};

static GestureKey touchKey(const TouchRecord &record) {
    return GestureKey{record.appInstance, record.componentInstance, record.generation,
                      record.pointerId, record.epoch};
}

std::deque<TouchRecord> g_touchQueue;
constexpr size_t kTouchQueueCapacity = 256;
// The queue and terminal reservations share one hard bound. BEGIN owns a
// terminal reservation from admission until its END/CANCEL is queued.
struct TouchGestureLedger {
    bool beginDelivered;
    bool terminalQueued;
    TouchGestureLedger() : beginDelivered(false), terminalQueued(false) {}
};
static std::map<GestureKey, TouchGestureLedger> g_touchGestureLedger;
static std::set<GestureKey> g_terminalReservations;
static std::set<GestureKey> g_suppressedGestures;
static GestureKey g_activeGesture{};
static bool g_hasActiveGesture = false;
static uint64_t g_nextGestureEpochValue = 1;
static std::atomic<size_t> g_touchQueueHighWater{0};
static std::atomic<uint64_t> g_touchOverloadCancels{0};

static size_t touchQueueOccupancyLocked() {
    return g_touchQueue.size() + g_terminalReservations.size();
}

static void updateTouchQueueHighWaterLocked() {
    const size_t now = g_touchQueue.size();
    size_t previous = g_touchQueueHighWater.load(std::memory_order_relaxed);
    while (now > previous && !g_touchQueueHighWater.compare_exchange_weak(
        previous, now, std::memory_order_relaxed)) {}
}

static bool gestureSuppressedLocked(const GestureKey &key) {
    return g_suppressedGestures.find(key) != g_suppressedGestures.end();
}

static void suppressGestureLocked(const GestureKey &key) {
    g_suppressedGestures.insert(key);
}

static void finishPhysicalGestureLocked(const GestureKey &key) {
    g_suppressedGestures.erase(key);
    if (g_hasActiveGesture && g_activeGesture == key) {
        g_hasActiveGesture = false;
    }
    auto state = g_touchGestureLedger.find(key);
    if (state != g_touchGestureLedger.end() && !state->second.beginDelivered &&
        !state->second.terminalQueued) {
        g_touchGestureLedger.erase(state);
        g_terminalReservations.erase(key);
    }
}

// Only a record returned successfully to the renderer changes delivery state.
static void touchRecordDeliveredLocked(const TouchRecord &record) {
    const GestureKey key = touchKey(record);
    if (record.action == kTouchBegin) {
        auto state = g_touchGestureLedger.find(key);
        if (state != g_touchGestureLedger.end()) state->second.beginDelivered = true;
    } else if (record.action == kTouchEnd || record.action == kTouchCancel) {
        g_touchGestureLedger.erase(key);
        g_terminalReservations.erase(key);
    }
}

static bool touchTerminalMayFinishRetiredLocked(const TouchRecord &record, bool exactSurfaceIdentity) {
    if (!exactSurfaceIdentity || (record.action != kTouchEnd && record.action != kTouchCancel)) return false;
    const auto state = g_touchGestureLedger.find(touchKey(record));
    return state != g_touchGestureLedger.end() && state->second.beginDelivered;
}

static bool touchGestureBeginDeliveredLocked(const TouchRecord &record) {
    const auto state = g_touchGestureLedger.find(touchKey(record));
    return state != g_touchGestureLedger.end() && state->second.beginDelivered;
}

static bool dequeueTouchRecordLocked(TouchRecord *outRecord) {
    if (outRecord == nullptr || g_touchQueue.empty()) return false;
    *outRecord = g_touchQueue.front();
    g_touchQueue.pop_front();
    return true;
}

static void discardRetiredTouchGestureLocked(const GestureKey &key) {
    for (auto it = g_touchQueue.begin(); it != g_touchQueue.end();) {
        if (touchKey(*it) == key) it = g_touchQueue.erase(it);
        else ++it;
    }
    g_touchGestureLedger.erase(key);
    g_terminalReservations.erase(key);
    g_suppressedGestures.erase(key);
    if (g_hasActiveGesture && g_activeGesture == key) g_hasActiveGesture = false;
}

static void retireTouchSurfaceLocked(uint64_t appInstance, uint64_t componentInstance,
                                     uint64_t generation, float cancelX, float cancelY) {
    std::set<GestureKey> keys;
    for (const auto &entry : g_touchGestureLedger) {
        const GestureKey &key = entry.first;
        if (key.appInstance == appInstance && key.componentInstance == componentInstance &&
            key.generation == generation) keys.insert(key);
    }
    for (const GestureKey &key : g_suppressedGestures) {
        if (key.appInstance == appInstance && key.componentInstance == componentInstance &&
            key.generation == generation) keys.insert(key);
    }
    if (g_hasActiveGesture) {
        const GestureKey &key = g_activeGesture;
        if (key.appInstance == appInstance && key.componentInstance == componentInstance &&
            key.generation == generation) keys.insert(key);
    }

    for (const GestureKey &key : keys) {
        auto state = g_touchGestureLedger.find(key);
        const bool beginWasDelivered = state != g_touchGestureLedger.end() && state->second.beginDelivered;
        const bool terminalAlreadyQueued = state != g_touchGestureLedger.end() && state->second.terminalQueued;
        if (!beginWasDelivered) {
            for (auto it = g_touchQueue.begin(); it != g_touchQueue.end();) {
                if (touchKey(*it) == key) it = g_touchQueue.erase(it);
                else ++it;
            }
            g_terminalReservations.erase(key);
            g_touchGestureLedger.erase(key);
        } else if (terminalAlreadyQueued) {
            bool hasTerminal = false;
            TouchRecord terminal{};
            for (auto it = g_touchQueue.begin(); it != g_touchQueue.end();) {
                if (touchKey(*it) == key) {
                    if (it->action == kTouchEnd || it->action == kTouchCancel) {
                        terminal = *it;
                        hasTerminal = true;
                    }
                    it = g_touchQueue.erase(it);
                } else {
                    ++it;
                }
            }
            if (hasTerminal) g_touchQueue.push_front(terminal);
        } else {
            for (auto it = g_touchQueue.begin(); it != g_touchQueue.end();) {
                if (touchKey(*it) == key && it->action != kTouchEnd && it->action != kTouchCancel) {
                    it = g_touchQueue.erase(it);
                } else {
                    ++it;
                }
            }
            const auto reservation = g_terminalReservations.find(key);
            if (reservation != g_terminalReservations.end()) {
                g_terminalReservations.erase(reservation);
                g_touchQueue.push_front(TouchRecord{kTouchCancel, cancelX, cancelY,
                    key.appInstance, key.componentInstance, key.generation, key.pointerId, key.epoch, 0, 1});
                state->second.terminalQueued = true;
            }
        }
        // Surface retirement is the final physical boundary for this key.
        g_suppressedGestures.erase(key);
        if (g_hasActiveGesture && g_activeGesture == key) g_hasActiveGesture = false;
    }
}

static bool makeTouchQueueRoomLocked(size_t additional, float cancelX, float cancelY) {
    while (touchQueueOccupancyLocked() + additional > kTouchQueueCapacity) {
        bool hasVictim = false;
        GestureKey victim{};
        for (const TouchRecord &record : g_touchQueue) {
            if (record.action == kTouchEnd || record.action == kTouchCancel) continue;
            const GestureKey key = touchKey(record); // freeze identity before erase
            const auto state = g_touchGestureLedger.find(key);
            if (state != g_touchGestureLedger.end() && state->second.terminalQueued) continue;
            if (state != g_touchGestureLedger.end() && state->second.beginDelivered &&
                g_terminalReservations.find(key) == g_terminalReservations.end()) continue;
            victim = key;
            hasVictim = true;
            break;
        }
        if (!hasVictim) return false;

        const GestureKey key = victim;
        auto state = g_touchGestureLedger.find(key);
        const bool beginWasDelivered = state != g_touchGestureLedger.end() && state->second.beginDelivered;
        size_t removed = 0;
        for (auto it = g_touchQueue.begin(); it != g_touchQueue.end();) {
            if (touchKey(*it) == key && it->action != kTouchEnd && it->action != kTouchCancel) {
                it = g_touchQueue.erase(it);
                ++removed;
            } else {
                ++it;
            }
        }
        if (removed == 0) return false;
        suppressGestureLocked(key);
        if (beginWasDelivered) {
            // A delivered BEGIN always still owns this reserved terminal slot.
            const auto reservation = g_terminalReservations.find(key);
            if (reservation == g_terminalReservations.end()) return false;
            g_terminalReservations.erase(reservation);
            g_touchQueue.push_front(TouchRecord{kTouchCancel, cancelX, cancelY,
                key.appInstance, key.componentInstance, key.generation, key.pointerId, key.epoch, 0, 1});
            state->second.terminalQueued = true;
            g_touchOverloadCancels.fetch_add(1, std::memory_order_relaxed);
        } else {
            g_terminalReservations.erase(key);
            if (state != g_touchGestureLedger.end()) state->second.terminalQueued = false;
        }
    }
    return true;
}

void enqueueTouchRecordLocked(uint32_t action, float x, float y, uint64_t appInstance,
                              uint64_t componentInstance, uint64_t generation, int64_t pointerId,
                              int64_t timestampNs = 0, uint32_t timeSource = 0) {
    GestureKey key{};
    if (action == kTouchBegin) {
        if (g_hasActiveGesture) {
            const GestureKey &active = g_activeGesture;
            if (active.appInstance == appInstance && active.componentInstance == componentInstance &&
                active.generation == generation && active.pointerId == pointerId) {
                return; // repeated DOWN cannot replace the key before its physical terminal
            }
        }
        key = GestureKey{appInstance, componentInstance, generation, pointerId, g_nextGestureEpochValue++};
        g_activeGesture = key;
        g_hasActiveGesture = true;
        g_touchGestureLedger[key] = TouchGestureLedger{};
        g_terminalReservations.insert(key);
        // BEGIN occupies a queue slot and reserves one future terminal slot.
        if (!makeTouchQueueRoomLocked(1, x, y)) {
            g_terminalReservations.erase(key);
            g_touchGestureLedger.erase(key);
            suppressGestureLocked(key);
            return;
        }
        if (gestureSuppressedLocked(key)) return;
        g_touchQueue.push_back(TouchRecord{action, x, y, appInstance, componentInstance,
                                           generation, pointerId, key.epoch,
                                           timestampNs, timeSource});
    } else {
        if (!g_hasActiveGesture) return;
        key = g_activeGesture;
        if (key.appInstance != appInstance || key.componentInstance != componentInstance ||
            key.generation != generation || key.pointerId != pointerId) return;
        if (gestureSuppressedLocked(key)) {
            if (action == kTouchEnd || action == kTouchCancel) finishPhysicalGestureLocked(key);
            return;
        }
        auto state = g_touchGestureLedger.find(key);
        if (state == g_touchGestureLedger.end()) return;
        if (action == kTouchEnd || action == kTouchCancel) {
            if (g_terminalReservations.erase(key) == 0) {
                finishPhysicalGestureLocked(key);
                return;
            }
            state->second.terminalQueued = true;
            g_touchQueue.push_back(TouchRecord{action, x, y, appInstance, componentInstance,
                                               generation, pointerId, key.epoch,
                                               timestampNs, timeSource});
            finishPhysicalGestureLocked(key);
        } else {
            if (!makeTouchQueueRoomLocked(1, x, y)) {
                // Even an all-terminal queue cannot consume this gesture's
                // reserved CANCEL slot. Drop this UPDATE and close the capture.
                const auto reservation = g_terminalReservations.find(key);
                if (reservation != g_terminalReservations.end()) {
                    g_terminalReservations.erase(reservation);
                    g_touchQueue.push_back(TouchRecord{kTouchCancel, x, y, appInstance,
                        componentInstance, generation, pointerId, key.epoch, 0, 1});
                    state->second.terminalQueued = true;
                    suppressGestureLocked(key);
                }
                return;
            }
            if (gestureSuppressedLocked(key)) return;
            g_touchQueue.push_back(TouchRecord{action, x, y, appInstance, componentInstance,
                                               generation, pointerId, key.epoch,
                                               timestampNs, timeSource});
        }
    }
    updateTouchQueueHighWaterLocked();
}

struct RetiredTouchOrigin {
    uint64_t appInstance;
    uint64_t componentInstance;
    uint64_t generation;
};

static void retireReplacedTouchOrigins(const std::vector<RetiredTouchOrigin> &origins) {
    if (origins.empty()) return;
    // Keep the same touch -> lease lock order as ingressTouchDequeueEx: callers
    // freeze origin identities while holding lease, then release it first.
    std::lock_guard<std::mutex> lock(g_touchMutex);
    for (const RetiredTouchOrigin &origin : origins) {
        retireTouchSurfaceLocked(origin.appInstance, origin.componentInstance, origin.generation, 0.0f, 0.0f);
    }
}

std::atomic<int> g_foreground{0};
// A3（Sol 复核）：`g_appStarted` 被删除——它是与 phase 并存的第二份真相。
// 「是否已启动」由 phase 推导（hostStarted()），停止判据也必须对**同一个
// appInstance**成立，而不是读一个可被任意改写的全局布尔。
//
// owner 线程句柄与它的实例编号一起受 g_ownerThreadMutex 保护：
// StartHost（重开时回收上一线程）与停止监控线程（判定 owner 实退时 join）
// 都要动它，二者必须互斥，且只能在**实例编号一致**时 join。
std::mutex g_ownerThreadMutex;
std::thread g_appThread;            // 可 join 的 owner 线程（Sol 第 3 点）
std::thread::id g_ownerThreadId{};  // 本实例 owner 线程身份（判据的一部分）
uint64_t g_threadOwnerInstance = 0; // g_appThread 所属的 appInstance
void *g_cangjieLib = nullptr;

// 尝试回收 owner 线程。只有「实例编号一致」且「owner 入口已返回」时才 join，
// 因此不会把新实例的线程误当成旧实例的。
// 返回 true = 该实例的 owner 线程已确认退出（含此前已 join）。
bool ownerThreadJoinedForInstance(uint64_t instance) {
    std::lock_guard<std::mutex> lock(g_ownerThreadMutex);
    if (g_threadOwnerInstance != instance) return false;
    // 关键前置：**owner 自己必须已声明退出**。只看 joinable() 会在
    // 「实例已换、线程还没创建」的窗口里返回假 true。
    if (!g_ownerExited.load()) return false;
    if (!g_appThread.joinable()) return true;   // 已 join（或被重开时回收）
    if (g_appThread.get_id() != g_ownerThreadId) return false;
    if (g_appThread.get_id() == std::this_thread::get_id()) return false;
    // join 期间持有本锁是安全的：owner 线程不取 g_ownerThreadMutex。
    g_appThread.join();
    return true;
}

// ---------------------------------------------------------------------------
// A3：宿主生命周期状态机（surface 卸载与应用停止分流）
// ---------------------------------------------------------------------------
//
// 状态：Idle → Starting → Running → Stopping → Stopped（→ Starting 可重开）；
// 启动失败或 owner 未经停止请求自行退出 → Failed（可重开，但**不**声称已停止）。
//（Sol 复核后的返工点）
//   - surface 卸载**只**退役该代 surface 记录并投递拆除，不触碰 host 状态，
//     也不在 UI 回调里等待或归还引用；
//   - Ability 真正退出 / 明确应用 stop 才进入 Stopping：先停止接单，再请求
//     owner 退出；`Starting` 期间收到停止请求允许直接进入 Stopping；
//   - owner 就绪由 owner 自己声明（ingress.appReady），宿主不按时间推断；
//   - 「已停止」对**同一个 appInstance**成立才有效：owner 线程真实退出并被
//     join、窗口 session 与票据收敛、渲染线程 teardown、surface 许可与 native
//     引用全部归还。`g_appThread.detach()` 只能覆盖立即返回的引导线程，
//     因此仓颉入口改为**同步运行 owner**（`cjgui_ohos_app_main_cangjie`
//     阻塞到 owner 退出），使该线程就是 owner、可被 join；
//   - 全局 `shutdownDone == 1` 不能单独作为判据（重开后可能是上一实例的值），
//     它只作为收敛的**观察读数**附在日志里，并在每次启动前复位。
enum HostPhase : int {
    kHostIdle = 0,
    kHostStarting = 1,
    kHostRunning = 2,
    kHostStopping = 3,
    kHostStopped = 4,
    kHostFailed = 5,   // 启动失败 / owner 未经停止请求退出：可重开，但不是「已停止」
};

std::atomic<int> g_hostPhase{kHostIdle};
std::atomic<bool> g_stopRequested{false};
// 相位、实例编号、owner 终态和 monitor 归属一起切换；不跨调用、等待或 join 持锁。
std::mutex g_hostTransitionMutex;
uint64_t g_ownerOutcomeInstance = 0;
int32_t g_ownerOutcome = -1;  // -1=未返回，0=有序退出，1=失败

// 「是否已启动」由 phase 推导（唯一真相）。
bool hostStarted() {
    int phase = g_hostPhase.load();
    return phase == kHostStarting || phase == kHostRunning || phase == kHostStopping;
}

const char *hostPhaseName(int phase) {
    switch (phase) {
        case kHostIdle: return "idle";
        case kHostStarting: return "starting";
        case kHostRunning: return "running";
        case kHostStopping: return "stopping";
        case kHostStopped: return "stopped";
        case kHostFailed: return "failed";
        default: return "unknown";
    }
}

// A3：owner 就绪声明（由 owner 线程经渲染器转发调用）。
// 只有处于 starting 时才推进到 running；其他状态下只如实记录，不覆盖真相。
void ingressAppReady() {
    g_ownerReady.store(true);
    std::lock_guard<std::mutex> lock(g_hostTransitionMutex);
    int phase = g_hostPhase.load();
    if (phase == kHostStarting) {
        int expected = kHostStarting;
        if (g_hostPhase.compare_exchange_strong(expected, kHostRunning)) {
            HLOGI("owner declared ready: host phase=running (appInstance=%{public}llu)",
                  static_cast<unsigned long long>(g_appInstance));
            return;
        }
        phase = expected;
    }
    HLOGI("owner declared ready while phase=%{public}s: recorded without phase change",
          hostPhaseName(phase));
}

using AppMainFn = int (*)(const CjguiOhosIngress *);
using ProbeMagicFn = uint64_t (*)();
using ProbeHeapFn = uint64_t (*)();

// --- ingress implementations (called from the Cangjie app thread) ---------

int ingressSurfaceActive(void **outWindow, uint64_t *outGeneration, int32_t *outWidth,
                         int32_t *outHeight, double *outDensity,
                         uint64_t *outGeometryRevision) {
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    SurfaceRecord *rec = findSurfaceByGenerationLocked(g_currentGeneration);
    if (rec == nullptr || !rec->active) {
        return 0;
    }
    if (outWindow) *outWindow = rec->window;
    if (outGeneration) *outGeneration = rec->generation;
    if (outWidth) *outWidth = rec->width;
    if (outHeight) *outHeight = rec->height;
    if (outDensity) *outDensity = rec->density;
    if (outGeometryRevision) *outGeometryRevision = rec->geometryRevision;
    return 1;
}

int ingressTouchDequeueEx(uint32_t *outAction, float *outX, float *outY,
                          uint64_t *outAppInstance, uint64_t *outComponentInstance,
                          uint64_t *outGeneration, int64_t *outPointerId,
                          uint64_t *outGestureEpoch, int64_t *outTimestampNs,
                          uint32_t *outTimeSource) {
    std::lock_guard<std::mutex> lock(g_touchMutex);
    TouchRecord record{};
    if (!dequeueTouchRecordLocked(&record)) return 0;
    {
        std::lock_guard<std::mutex> leaseLock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceByGenerationLocked(g_currentGeneration);
        bool stillCurrent = (rec != nullptr) && rec->active && rec->generation == record.generation &&
            rec->appInstance == record.appInstance && rec->componentInstance == record.componentInstance;
        if (!stillCurrent) {
            SurfaceRecord *origin = findSurfaceByGenerationLocked(record.generation);
            const bool exactOrigin = origin != nullptr && origin->generation == record.generation &&
                origin->appInstance == record.appInstance &&
                origin->componentInstance == record.componentInstance &&
                origin->retired;
            if (!touchTerminalMayFinishRetiredLocked(record, exactOrigin)) {
                const bool deliveredCapture = exactOrigin && touchGestureBeginDeliveredLocked(record);
                if (deliveredCapture) {
                    // Close the destroy/dequeue race: retire every key for this
                    // exact surface, reserving a CANCEL before dropping this
                    // stale nonterminal sample.
                    retireTouchSurfaceLocked(record.appInstance, record.componentInstance,
                                             record.generation, record.x, record.y);
                } else {
                    discardRetiredTouchGestureLocked(touchKey(record));
                }
                g_oldGenEventsRejected.fetch_add(1);
                return -1;
            }
        }
    }
    touchRecordDeliveredLocked(record);
    if (outAction) *outAction = record.action;
    if (outX) *outX = record.x;
    if (outY) *outY = record.y;
    if (outAppInstance) *outAppInstance = record.appInstance;
    if (outComponentInstance) *outComponentInstance = record.componentInstance;
    if (outGeneration) *outGeneration = record.generation;
    if (outPointerId) *outPointerId = record.pointerId;
    if (outGestureEpoch) *outGestureEpoch = record.epoch;
    if (outTimestampNs) *outTimestampNs = record.timestampNs;
    if (outTimeSource) *outTimeSource = record.timeSource;
    return 1;
}

int ingressTouchDequeue(uint32_t *outAction, float *outX, float *outY, uint64_t *outGeneration) {
    uint64_t appInstance = 0;
    uint64_t componentInstance = 0;
    int64_t pointerId = 0;
    uint64_t epoch = 0;
    int rc = ingressTouchDequeueEx(outAction, outX, outY, &appInstance, &componentInstance,
                                   outGeneration, &pointerId, &epoch, nullptr, nullptr);
    return rc;
}

int ingressForegroundLevel() { return g_foreground.load() ? 1 : 0; }

// 代际复核：渲染器在绘制前与 Flush 后各调用一次。只有「宿主当前
// **仍允许使用**的这一代」返回 1；退役后旧代立即返回 0。
// 注意：这里只回答「是否还允许继续使用」，它**不是**资源安全判据——
// 真正的安全由「宿主持有 native 引用 + 渲染线程持有一份使用许可」共同保证。
int ingressSessionBackend(uint64_t generation) {
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    for (const SurfaceRecord &rec : g_surfaces) {
        if (rec.generation == generation) return rec.backend;
    }
    return 0;
}

int ingressLeaseValid(uint64_t generation) {
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
    if (rec == nullptr) return 0;
    return (rec->active && !rec->retired) ? 1 : 0;
}

// A2：取得一份 surface 使用许可。与 onSurfaceCreated/Destroyed 处在**同一把**
// 宿主锁内，因此「核对身份 + 增加在途」与「退休 + 投递拆除」不会交错。
// 身份不符、已退役、或 native 引用未成功持有时一律拒绝（返回 0）。
int ingressSurfacePermitAcquire(uint64_t generation, uint64_t *outAppInstance,
                               uint64_t *outComponentInstance, uint64_t *outGeometryRevision) {
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
    // KnownShimNoRef 档（nativeRefUnavailable）发布 degradedActive：许可照常
    // 发放（生命周期安全由 destroyed fence 保证），但绝不虚记 nativeRefHeld。
    // 第九次复核 A3：替身会话（backend=1）不持真实引用，准入照常发放——
    // 身份/准入/退役规则与真实记录同一套（nativeRefFailed 不构成拒绝）。
    const bool stubSession = rec != nullptr && rec->backend == 1;
    if (rec == nullptr || !rec->active || rec->retired || rec->admissionClosed ||
        (!stubSession && !rec->nativeRefHeld && !rec->nativeRefUnavailable)) {
        // admissionClosed（fence 超时）永久拒绝：恢复后的访问尝试一并计数
        g_oldGenEventsRejected.fetch_add(1);
        return 0;
    }
    rec->inFlight += 1;
    rec->grantedPermits += 1;
    if (outAppInstance) *outAppInstance = rec->appInstance;
    if (outComponentInstance) *outComponentInstance = rec->componentInstance;
    if (outGeometryRevision) *outGeometryRevision = rec->geometryRevision;
    return 1;
}

int ingressSurfacePermitRelease(uint64_t generation) {
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
    if (rec == nullptr) return 0;
    if (rec->inFlight > 0) {
        rec->inFlight -= 1;
        rec->releasedPermits += 1;
    }
    return rec->inFlight;
}

// --- A2：native 引用归还的线程归属 -------------------------------------------
//
// OH_NativeWindow_NativeObjectReference/Unreference 明确标注**非线程安全**，
// 官方指导要求成对且在 UI 线程串行执行。但归还的**时机**不能由 UI 回调决定：
//   - UI 回调里等待（静默/超时）不能用等待时长推导资源安全（Sol 第 1 点）；
//   - 引用归还必须晚于「渲染线程真实结束使用该代」。
// 因此：渲染线程拆除完成后回传 surfaceTornDown，宿主据此把归还任务投递回
// UI 线程执行；投递失败或超时都保持**未完成**状态，绝不谎称已释放。
struct RefReleaseRequest {
    uint64_t generation;
    void *window;
};

napi_threadsafe_function g_refReleaseFn = nullptr;

// 在 UI 线程执行真实的引用归还（只由 RefReleaseCall 调用）。
// 仅 Verified 档可达（shim/失败档在 tornDown 处已被 nativeRefFailed 拦下）。
void performRefRelease(uint64_t generation, void *window) {
    int32_t rc = -1;
    if (window != nullptr) {
        rc = OH_NativeWindow_NativeObjectUnreference(window);
    }
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
        if (rec != nullptr) {
            rec->nativeRefReleasePending = false;
            if (rc == 0) {
                rec->nativeRefReleased = true;
                rec->nativeRefHeld = false;
                rec->refReleasedAtMs = nowMs();
                rec->auditWindow = rec->window;  // 审计存根（仅诊断读数，不复用）
                rec->window = nullptr;           // 引用已归还：退休记录清除平台指针
            }
        }
    }
    if (rc == 0) {
        g_nativeUnrefCount.fetch_add(1);
    } else {
        // 归还失败：保持未归还状态并单独计数，绝不当成已释放。
        g_nativeRefPendingCount.fetch_add(1);
    }
    HLOGI("surface ref released on UI thread gen=%{public}llu rc=%{public}d unrefs=%{public}lld pending=%{public}lld",
          static_cast<unsigned long long>(generation), static_cast<int>(rc),
          static_cast<long long>(g_nativeUnrefCount.load()),
          static_cast<long long>(g_nativeRefPendingCount.load()));
}

void RefReleaseCall(napi_env env, napi_value js_cb, void *context, void *data) {
    (void)env;
    (void)js_cb;
    (void)context;
    RefReleaseRequest *req = static_cast<RefReleaseRequest *>(data);
    if (req == nullptr) return;
    performRefRelease(req->generation, req->window);
    delete req;
}

// 把归还任务投递回 UI 线程。投递失败时**不**就地归还（那样就回到
// 「在非 UI 线程碰非线程安全接口」的老问题），而是撤销 pending 标记并计数，
// 使状态如实保持为未归还。
void scheduleRefRelease(uint64_t generation, void *window) {
    if (g_refReleaseFn == nullptr) {
        g_nativeRefPendingCount.fetch_add(1);
        {
            std::lock_guard<std::mutex> lock(g_leaseMutex);
            SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
            if (rec != nullptr) rec->nativeRefReleasePending = false;
        }
        HLOGW("ref release unscheduled (no UI-thread channel): reference retained gen=%{public}llu",
              static_cast<unsigned long long>(generation));
        return;
    }
    RefReleaseRequest *req = new RefReleaseRequest{generation, window};
    napi_status status = napi_call_threadsafe_function(g_refReleaseFn, req, napi_tsfn_nonblocking);
    if (status != napi_ok) {
        delete req;
        g_nativeRefPendingCount.fetch_add(1);
        {
            std::lock_guard<std::mutex> lock(g_leaseMutex);
            SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
            if (rec != nullptr) rec->nativeRefReleasePending = false;
        }
        HLOGW("ref release post failed status=%{public}d: reference retained gen=%{public}llu",
              static_cast<int>(status), static_cast<unsigned long long>(generation));
    }
}

// 渲染线程 → 宿主的拆除确认（**由渲染线程调用**）。
// 这是引用归还的唯一判据：只有该代已在渲染线程真实拆除、许可已归零，
// 才会把归还任务投递到 UI 线程。重复/迟到的通知按代际去重。
void ingressSurfaceTornDown(uint64_t generation) {
    void *window = nullptr;
    bool schedule = false;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
        if (rec == nullptr) {
            HLOGW("torn down notify for unknown generation ignored gen=%{public}llu",
                  static_cast<unsigned long long>(generation));
            g_teardownCv.notify_all();  // fence 等待方需要被唤醒以重新检查
            return;
        }
        // A drawing-handle replacement inside an active generation is not the
        // end of the XComponent window. Only destroy/stop/supersession closes
        // permit admission and permits the sole native reference to be returned.
        if (!rec->retired || rec->active) {
            HLOGW("torn down notify ignored for live generation=%{public}llu",
                  static_cast<unsigned long long>(generation));
            return;
        }
        if (rec->inFlight != 0) {
            HLOGW("torn down gen=%{public}llu but inFlight=%{public}d: reference retained",
                  static_cast<unsigned long long>(generation), rec->inFlight);
            return;
        }
        rec->tornDown = true;
        if (rec->nativeRefFailed) {
            // 引用从未取到（含 KnownShimNoRef 档）：无引用可归还，账目闭合
            // （不虚增 unrefs；shim 档 destroy fence 靠这里的 tornDown 唤醒）。
            rec->nativeRefReleased = true;
            HLOGI("torn down gen=%{public}llu: no native reference was held",
                  static_cast<unsigned long long>(generation));
            g_teardownCv.notify_all();
            return;
        }
        if (rec->nativeRefReleased || rec->nativeRefReleasePending) {
            HLOGI("torn down gen=%{public}llu: reference already released/queued (dedup)",
                  static_cast<unsigned long long>(generation));
            g_teardownCv.notify_all();
            return;
        }
        rec->nativeRefReleasePending = true;
        window = rec->window;
        schedule = true;
    }
    g_teardownCv.notify_all();  // destroyed fence 等待方（Verified 档无 fence，无害）
    if (schedule) {
        scheduleRefRelease(generation, window);
    }
}

// 前置声明：定义在宿主生命周期状态机之后（依赖 g_hostPhase）。
void ingressAppReady();

// A1/A2 受控模拟实现（宿主侧，无 XComponent 依赖）：
// retired 复用 onSurfaceDestroyedImpl（component 参数被忽略，安全传 nullptr）；
// created 复用最近一条退役记录的 window/尺寸重新发布为新代（重新引用 + 新
// generation/geometryRevision），与平台「销毁后同尺寸重建」语义一致。
static int32_t bridgeSimulateSurfaceRetiredImpl(void);

// 第八次复核 §2.4 负例：伪造「已退休、window 已清除、auditWindow=毒指针」
// 记录后调 SIM_CREATED——必须拒绝复活（-2），且 created/nativeRef 计数零增
// （auditWindow 指针不得触发任何平台调用）。仅测试变体导出。
static int32_t bridgeSimulateSurfaceCreatedImpl(void);

static std::atomic<bool> g_auditSelfCheckRunning{false};

static void auditStubNegativeSelfCheck(void)
{
    if (g_auditSelfCheckRunning.exchange(true)) return;   // 防重入
    {
    const int64_t createdBefore = g_surfaceCreatedCount.load();
    const int64_t refsBefore = g_nativeRefCount.load();
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        SurfaceRecord bad;
        bad.appInstance = g_appInstance;
        bad.componentInstance = 0;
        bad.generation = 0xDEAD;      // 显式假身份（不与真实代混淆）
        bad.geometryRevision = 0;
        bad.componentId = "audit_stub_negative";
        bad.window = nullptr;          // fence 后已清除的事实
        bad.auditWindow = reinterpret_cast<void *>(0xBADBAD);  // 毒指针存根
        bad.width = 10;
        bad.height = 10;
        bad.density = 1.0;
        bad.retired = true;
        bad.active = false;
        g_surfaces.push_back(bad);
    }
    const int32_t rc = bridgeSimulateSurfaceCreatedImpl();
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (auto it = g_surfaces.begin(); it != g_surfaces.end(); ++it) {
            if (it->generation == 0xDEAD && it->componentId == "audit_stub_negative") {
                g_surfaces.erase(it);
                break;
            }
        }
    }
    const int64_t createdAfter = g_surfaceCreatedCount.load();
    const int64_t refsAfter = g_nativeRefCount.load();
    HLOGI("audit stub negative: rc=%{public}d created %{public}lld->%{public}lld refs %{public}lld->%{public}lld",
          rc, static_cast<long long>(createdBefore), static_cast<long long>(createdAfter),
          static_cast<long long>(refsBefore), static_cast<long long>(refsAfter));
    // 判定：auditWindow 毒指针**从未**被消费为新记录/平台调用。
    //  - badUsed：表中出现 window==0xBADBAD 或假身份的新记录 → 毒指针被用（FAIL）；
    //  - rc==0：扫描跳过毒记录（window==nullptr 永不提供指针）、改用真实存活
    //    window 合法重建——auditWindow 未参与；
    //  - rc==-2：无任何真实存活 window（毒记录不算）——拒绝复活。
    bool badUsed = false;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (const SurfaceRecord &rec : g_surfaces) {
            if (rec.window == reinterpret_cast<void *>(0xBADBAD) ||
                rec.componentInstance == 0xDEADDEAD) {
                badUsed = true;
            }
        }
    }
    if (badUsed || (rc != 0 && rc != -2)) {
        HLOGE("audit stub negative: FAIL rc=%{public}d badUsed=%{public}d created %{public}lld->%{public}lld refs %{public}lld->%{public}lld",
              rc, badUsed ? 1 : 0,
              static_cast<long long>(createdBefore), static_cast<long long>(createdAfter),
              static_cast<long long>(refsBefore), static_cast<long long>(refsAfter));
        return;
    }
    HLOGI("audit stub negative: PASS rc=%{public}d (auditWindow pointer triggered no platform call)", rc);
    }
    g_auditSelfCheckRunning.store(false);
}


// D 夹具：探针注入触摸（与 XComponent dispatchTouchImpl 进入同一条
// g_touchQueue，带当前代际）。仅供测试链路调用；普通产物无调用者。
static int32_t bridgeInjectTouchImpl(uint32_t action, float x, float y)
{
    uint64_t appInstance = 0;
    uint64_t componentInstance = 0;
    uint64_t generation = 0;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &rec : g_surfaces) {
            if (rec.active && !rec.retired) {
                appInstance = rec.appInstance;
                componentInstance = rec.componentInstance;
                generation = rec.generation;
                break;
            }
        }
    }
    if (generation == 0) {
        return -2;
    }
    // B（惯性包）：注入通道无 SDK 事件结构——steady_clock 兜底（来源 1）。
    int64_t timestampNs = std::chrono::duration_cast<std::chrono::nanoseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
    uint32_t timeSource = 1;
    std::lock_guard<std::mutex> lock(g_touchMutex);
    enqueueTouchRecordLocked(action, x, y, appInstance, componentInstance, generation, 0,
                             timestampNs, timeSource);;
    return 0;
}
void onSurfaceDestroyedImpl(OH_NativeXComponent *component, void *window);

static int32_t bridgeSimulateSurfaceRetiredImpl(void)
{
    void *win = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &rec : g_surfaces) {
            if (rec.active && !rec.retired) {
                win = rec.window;
                break;
            }
        }
    }
    if (win == nullptr) {
        return -2;
    }
    onSurfaceDestroyedImpl(nullptr, win);
    return 0;
}

static int32_t bridgeSimulateSurfaceCreatedImpl(void)
{
    // 第九次复核 B：NEG4 已独立为隔离夹具命令（拦截 Reference/Create 逐
    // 命令断言调用次数）——生产模拟命令一次只做一次明确转换，不夹带自检。
    // 第八次复核 §2.4 + 第九次复核 B：模拟重建只取当前挂载事实（带身份）；
    // 退休记录/auditWindow 不复活。
    // 模拟重建的唯一来源是**当前挂载事实**（UI 线程维护、
    // 带身份；destroyed 已使其失效）——不再扫描退休记录（退休记录的
    // window 非空不证明仍挂载；auditWindow 只诊断）。实例不符（重开后
    // 旧实例事实）同样拒绝。
    void *win = nullptr;
    int32_t w = 0;
    int32_t h = 0;
    std::string id;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (g_mountFact.valid && g_mountFact.window != nullptr &&
            g_mountFact.appInstance == g_appInstance) {
            win = g_mountFact.window;
            w = g_mountFact.width;
            h = g_mountFact.height;
            id = g_mountFact.componentId;
        }
    }
    if (win == nullptr) {
        HLOGW("simulate created rejected: no live mount fact (destroyed or wrong instance)");
        return -2;
    }
    int32_t refRc = -1;
    bool refHeld = false;
    bool refDegraded = false;
    if (win != nullptr) {
        RefOutcome ro = acquireNativeRef(win);
        refRc = ro.rc;
        refHeld = ro.held;
        refDegraded = ro.degradedActive;
        if (ro.held) {
            g_nativeRefCount.fetch_add(1);
        }
    }
    g_surfaceCreatedCount.fetch_add(1);
    std::vector<RetiredTouchOrigin> retiredTouchOrigins;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &old : g_surfaces) {
            if (old.window == win && !old.retired && !old.tornDown) {
                retiredTouchOrigins.push_back(RetiredTouchOrigin{
                    old.appInstance, old.componentInstance, old.generation});
                old.retired = true;
                old.active = false;
                old.retireRequestedAtMs = nowMs();
            }
        }
        SurfaceRecord rec;
        rec.appInstance = g_appInstance;
        rec.componentInstance = g_nextComponentInstance++;
        rec.generation = g_nextGeneration++;
        rec.geometryRevision = g_nextGeometryRevision++;
        rec.componentId = id;
        rec.window = win;
        rec.width = w;
        rec.height = h;
        rec.density = 1.0;
        rec.nativeRefHeld = refHeld;
        rec.nativeRefUnavailable = refDegraded;   // Q3 后恒 false（拒绝发布）
        rec.nativeRefFailed = !refHeld;
        rec.active = refHeld;
        rec.retired = !refHeld;
        g_surfaces.push_back(rec);
        g_currentGeneration = rec.active ? rec.generation : 0;
        HLOGI("simulate surface created gen=%{public}llu %dx%d refs=%{public}lld",
              static_cast<unsigned long long>(rec.generation), w, h,
              static_cast<long long>(g_nativeRefCount.load()));
    }
    retireReplacedTouchOrigins(retiredTouchOrigins);
    return 0;
}

CjguiOhosIngress g_ingress = {
    ingressSurfaceActive,
    ingressTouchDequeue,
    nullptr,   // touchDequeueEx（A：由 IngressSimulateRegistrar 填入）
    ingressForegroundLevel,
    ingressLeaseValid,
    ingressSurfacePermitAcquire,
    nullptr,   // stubSessionRegister（第九次复核 A3，静态注册器填入）
    nullptr,   // stubSessionRetire
    nullptr,   // stubSessionActive
    nullptr,   // auditNegativeFixture（第九次复核 B）
    ingressSessionBackend,
    ingressSurfacePermitRelease,
    ingressSurfaceTornDown,
    ingressAppReady,
    nullptr,   // simulateSurfaceRetired（IngressSimulateRegistrar 填入）
    nullptr,   // simulateSurfaceCreated
    nullptr,   // injectTouch
};


extern "C" int32_t cjgui_ohos_test_stub_session_register(int64_t generation,
                                                         int64_t width, int64_t height);
static int32_t stubSessionRetireImpl(int64_t generation);
static int32_t stubSessionActiveImpl(void);
extern "C" int32_t cjgui_ohos_test_audit_negative_fixture(void);

// 把模拟入口挂进 ingress（渲染器 export 经此转回宿主真实逻辑）。
static struct IngressSimulateRegistrar {
    IngressSimulateRegistrar() {
        g_ingress.simulateSurfaceRetired = &bridgeSimulateSurfaceRetiredImpl;
        g_ingress.simulateSurfaceCreated = &bridgeSimulateSurfaceCreatedImpl;
        g_ingress.injectTouch = &bridgeInjectTouchImpl;
        g_ingress.touchDequeueEx = &ingressTouchDequeueEx;
        // 第九次复核 A3：替身会话表经 ingress 提供给渲染器（同进程跨 so
        // 函数指针，无跨库符号依赖）。
        g_ingress.stubSessionRegister = &cjgui_ohos_test_stub_session_register;
        g_ingress.stubSessionRetire = &stubSessionRetireImpl;
        g_ingress.stubSessionActive = &stubSessionActiveImpl;
        // 静态注册器与 RunAuditNegativeFixture（同 TU static）可见性一致；
        // 该指针由 ingress 注册器填入（同 libentry 内部，无跨库符号）。
    }
} g_ingressSimulateRegistrar;

// --- library location -------------------------------------------------------

// Candidate directories are probed at runtime because the final packaging
// location of the Cangjie HAR library inside the HAP is part of what this
// phase verifies.
std::vector<std::string> libraryCandidates() {
    return {
        "libcjgui_app.so",
        "/data/storage/el1/bundle/libs/arm64/libcjgui_app.so",
        "/data/storage/el1/bundle/libs/arm64/cjbins/cjgui_app/libcjgui_app.so",
    };
}

// --- XComponent callbacks (UI thread) ---------------------------------------

OH_NativeXComponent_Callback g_xcomponentCallback;

// 链1：surface 分类与发布（引用取证 + 三态准入 + 记录创建）。只在 UI 线程
// 调用——同步路径（回调内）与补分类路径（TSFN call_js_cb）都是 UI 线程。
static void classifyAndPublishSurface(OH_NativeXComponent *component, void *window,
                                      const char *id, uint64_t width, uint64_t height) {
    (void)component;
    // A2 第 ① 步：先在 UI 线程串行取得原生对象引用（非线程安全接口，
    // 只在 UI 回调里成对调用）。引用成功是发布 active 的**前提**。
    // 顺序重要：记录一旦 active，渲染线程就可能立刻用这个 window 去创建
    // surface；若此时引用还没加上，组件销毁会让引用计数归零。
    int32_t refRc = -1;
    bool refHeld = false;
    bool refDegraded = false;
    if (window != nullptr) {
        RefOutcome ro = acquireNativeRef(window);
        refRc = ro.rc;
        refHeld = ro.held;
        refDegraded = ro.degradedActive;
        const uint32_t rcLow = static_cast<uint32_t>(static_cast<uint32_t>(refRc));
        const uint32_t objLow = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(window) & 0xffffffffu);
        HLOGI("ref abi probe obj=%{public}llu rc=%{public}d rcIsObjLow32=%{public}d "
              "provider=%{public}s held=%{public}d degradedActive=%{public}d",
              static_cast<unsigned long long>(reinterpret_cast<uintptr_t>(window)),
              static_cast<int>(refRc),
              static_cast<int>((refRc != 0 && rcLow == objLow) ? 1 : 0),
              g_refProviderLib.c_str(), refHeld ? 1 : 0, refDegraded ? 1 : 0);
        if (ro.held) {
            g_nativeRefCount.fetch_add(1);
        }
    }
    uint64_t generation = 0;
    uint64_t componentInstance = 0;
    bool published = false;
    std::vector<RetiredTouchOrigin> retiredTouchOrigins;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        // 同一指针地址可能被系统复用（组件重建）：先把仍在表中、未退役的旧记录
        // 退役，绝不让两代共用一条记录（同地址/同尺寸都不能合并代）。
        for (SurfaceRecord &old : g_surfaces) {
            if (old.window == window && !old.retired && !old.tornDown) {
                retiredTouchOrigins.push_back(RetiredTouchOrigin{
                    old.appInstance, old.componentInstance, old.generation});
                old.retired = true;
                old.active = false;
                old.retireRequestedAtMs = nowMs();
            }
        }
        SurfaceRecord rec;
        rec.appInstance = g_appInstance;
        rec.componentInstance = g_nextComponentInstance++;
        rec.generation = g_nextGeneration++;
        rec.geometryRevision = g_nextGeometryRevision++;
        rec.componentId = std::string(id);
        rec.window = window;
        rec.width = static_cast<int32_t>(width);
        rec.height = static_cast<int32_t>(height);
        rec.density = 1.0;  // real density follows with the render probe
        // 三态准入（Sol Q1）：Verified 档持有引用才发布；KnownShimNoRef 档发布
        // degradedActive（nativeRefUnavailable，绝不虚记 held）；其余失败关闭。
        rec.nativeRefHeld = refHeld;
        rec.nativeRefUnavailable = refDegraded;   // Q3 后恒 false（拒绝发布）
        rec.nativeRefFailed = !refHeld;
        rec.active = refHeld;
        rec.retired = !refHeld;
        generation = rec.generation;
        componentInstance = rec.componentInstance;
        published = rec.active;
        g_surfaces.push_back(rec);
        g_currentGeneration = rec.active ? rec.generation : 0;
    }
    retireReplacedTouchOrigins(retiredTouchOrigins);
    // 第九次复核 B：登记当前挂载事实（UI 线程；无论是否获渲染准入）。
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        g_mountFact.window = window;
        g_mountFact.mountEpoch += 1;
        g_mountFact.appInstance = g_appInstance;
        g_mountFact.componentId = std::string(id);
        g_mountFact.width = static_cast<int32_t>(width);
        g_mountFact.height = static_cast<int32_t>(height);
        g_mountFact.valid = true;
    }
    HLOGI("surface created id=%{public}s %{public}llux%{public}llu gen=%{public}llu comp=%{public}llu app=%{public}llu nativeref rc=%{public}d published=%{public}d refs=%{public}lld",
          id, static_cast<unsigned long long>(width), static_cast<unsigned long long>(height),
          static_cast<unsigned long long>(generation),
          static_cast<unsigned long long>(componentInstance),
          static_cast<unsigned long long>(g_appInstance),
          static_cast<int>(refRc), published ? 1 : 0,
          static_cast<long long>(g_nativeRefCount.load()));
}

void onSurfaceCreatedImpl(OH_NativeXComponent *component, void *window) {
    char id[128] = {0};
    uint64_t idSize = sizeof(id);
    OH_NativeXComponent_GetXComponentId(component, id, &idSize);
    id[sizeof(id) - 1] = '\0';
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    g_surfaceCreatedCount.fetch_add(1);
    if (!g_entryPointsResolved.load()) {
        // 链1：surface 回调只发布事实并立即返回，绝不在 UI 线程等待必须由
        // 后续 UI 事件（onLoad→startHost）启动的解析。挂起事实，解析完成后
        // 经 TSFN 回 UI 线程补分类；destroyed 到来即取消（窗口保活由
        // destroyed 界定，不缓存无保活指针）。
        std::lock_guard<std::mutex> lk(g_deferredSurfaceMutex);
        g_deferredSurface.valid = true;
        g_deferredSurface.component = component;
        g_deferredSurface.window = window;
        memset(g_deferredSurface.id, 0, sizeof(g_deferredSurface.id));
        memcpy(g_deferredSurface.id, id, sizeof(g_deferredSurface.id) - 1);
        g_deferredSurface.width = width;
        g_deferredSurface.height = height;
        HLOGI("surface created before entry points resolved; classification deferred "
              "id=%{public}s %{public}llux%{public}llu",
              id, static_cast<unsigned long long>(width), static_cast<unsigned long long>(height));
        return;
    }
    classifyAndPublishSurface(component, window, id, width, height);
}

void onSurfaceChangedImpl(OH_NativeXComponent *component, void *window) {
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    uint64_t generation = 0;
    uint64_t geometryRevision = 0;
    std::vector<RetiredTouchOrigin> retiredTouchOrigins;
    {
        std::unique_lock<std::mutex> lock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceLocked(window);
        if (rec == nullptr) {
            // D：resize 可能重建 native window（指针更换，实测 60% 宽度切换）。
            // 旧记录按 componentId 退役；新 window 走 created 同路径注册
            // （引用成功才发布，新 generation/geometryRevision）。
            char id[128] = {0};
            uint64_t idSize = sizeof(id);
            OH_NativeXComponent_GetXComponentId(component, id, &idSize);
            id[sizeof(id) - 1] = '\0';
            for (SurfaceRecord &old : g_surfaces) {
                if (old.componentId == std::string(id) && !old.retired) {
                    retiredTouchOrigins.push_back(RetiredTouchOrigin{
                        old.appInstance, old.componentInstance, old.generation});
                    old.retired = true;
                    old.active = false;
                    old.retireRequestedAtMs = nowMs();
                }
            }
            if (window != nullptr && !g_entryPointsResolved.load()) {
                // 链1：解析未完成时不做引用/分类；更新挂起事实的几何，
                // 由解析完成后的补分类统一处理。
                {
                    std::lock_guard<std::mutex> lk(g_deferredSurfaceMutex);
                    g_deferredSurface.valid = true;
                    g_deferredSurface.component = component;
                    g_deferredSurface.window = window;
                    memset(g_deferredSurface.id, 0, sizeof(g_deferredSurface.id));
                    memcpy(g_deferredSurface.id, id, sizeof(g_deferredSurface.id) - 1);
                    g_deferredSurface.width = width;
                    g_deferredSurface.height = height;
                }
                HLOGI("surface changed before resolution; deferred geometry updated "
                      "%{public}llux%{public}llu",
                      static_cast<unsigned long long>(width),
                      static_cast<unsigned long long>(height));
                lock.unlock();
                retireReplacedTouchOrigins(retiredTouchOrigins);
                return;
            }
            int32_t refRc = -1;
            bool refHeld = false;
            bool refDegraded = false;
            if (window != nullptr) {
                RefOutcome ro = acquireNativeRef(window);
                refRc = ro.rc;
                refHeld = ro.held;
                refDegraded = ro.degradedActive;
                if (ro.held) {
                    g_nativeRefCount.fetch_add(1);
                }
            }
            g_surfaceCreatedCount.fetch_add(1);
            SurfaceRecord nrec;
            nrec.appInstance = g_appInstance;
            nrec.componentInstance = g_nextComponentInstance++;
            nrec.generation = g_nextGeneration++;
            nrec.geometryRevision = g_nextGeometryRevision++;
            nrec.componentId = std::string(id);
            nrec.window = window;
            nrec.width = static_cast<int32_t>(width);
            nrec.height = static_cast<int32_t>(height);
            nrec.density = 1.0;
            nrec.nativeRefHeld = refHeld;
            nrec.nativeRefUnavailable = refDegraded;
            nrec.nativeRefFailed = !refHeld;
            nrec.active = refHeld;
            nrec.retired = !refHeld;
            g_surfaces.push_back(nrec);
            g_currentGeneration = nrec.active ? nrec.generation : 0;
            // The native callback, not a retired SurfaceRecord, is the
            // authority for which physical window remains mounted.
            g_mountFact.window = window;
            g_mountFact.mountEpoch += 1;
            g_mountFact.appInstance = g_appInstance;
            g_mountFact.componentId = std::string(id);
            g_mountFact.width = static_cast<int32_t>(width);
            g_mountFact.height = static_cast<int32_t>(height);
            g_mountFact.valid = true;
            generation = nrec.generation;
            geometryRevision = nrec.geometryRevision;
            HLOGI("surface changed: window re-registered as new gen=%{public}llu "
                  "%{public}llux%{public}llu (resize recreate path)",
                  static_cast<unsigned long long>(generation),
                  static_cast<unsigned long long>(width),
                  static_cast<unsigned long long>(height));
            lock.unlock();
            retireReplacedTouchOrigins(retiredTouchOrigins);
            return;
        }
        rec->width = static_cast<int32_t>(width);
        rec->height = static_cast<int32_t>(height);
        // 几何变更必须分配**不复用**的 geometryRevision：同尺寸重建也要能被
        // 识别为一次新的几何（旧代用旧版本，渲染线程据此拒绝混用）。
        rec->geometryRevision = g_nextGeometryRevision++;
        if (g_mountFact.valid && g_mountFact.window == window) {
            g_mountFact.width = static_cast<int32_t>(width);
            g_mountFact.height = static_cast<int32_t>(height);
        }
        generation = rec->generation;
        geometryRevision = rec->geometryRevision;
    }
    HLOGI("surface changed gen=%{public}llu geo=%{public}llu %{public}llux%{public}llu",
          static_cast<unsigned long long>(generation),
          static_cast<unsigned long long>(geometryRevision),
          static_cast<unsigned long long>(width), static_cast<unsigned long long>(height));
}

// --- 第九次复核 A3：替身会话复用 SurfaceRecord（宿主表生产语义）------------


extern "C" int32_t cjgui_ohos_test_stub_session_register(int64_t generation,
                                                         int64_t width, int64_t height)
{
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    for (const SurfaceRecord &old : g_surfaces) {
        if (old.generation == static_cast<uint64_t>(generation)) {
            HLOGW("stub session register: generation %{public}lld already exists",
                  static_cast<long long>(generation));
            return -2;
        }
    }
    SurfaceRecord rec;
    rec.appInstance = g_appInstance;
    rec.componentInstance = g_nextComponentInstance++;
    rec.generation = static_cast<uint64_t>(generation);
    rec.geometryRevision = g_nextGeometryRevision++;
    rec.componentId = "cjgui_stub_session";
    rec.backend = 1;
    rec.window = reinterpret_cast<void *>(static_cast<uintptr_t>(0x577B0000ULL |
                                                                     static_cast<uint64_t>(generation)));
    rec.width = static_cast<int32_t>(width);
    rec.height = static_cast<int32_t>(height);
    rec.density = 1.0;
    // 替身会话不持真实原生引用：三态字段如实记录（不虚记 held）。
    rec.nativeRefHeld = false;
    rec.nativeRefUnavailable = false;
    rec.nativeRefFailed = true;
    rec.active = true;     // 租约承载：active 即渲染准入有效（发布模式由能力决定）
    rec.retired = false;
    g_surfaces.push_back(rec);
    // 当前代指向替身会话：owner 的 surfaceReady 轮询与渲染准入都经
    // g_currentGeneration 查询——不置位则 owner 永远停在替身档 Phase A。
    g_currentGeneration = rec.generation;
    g_surfaceCreatedCount.fetch_add(1);
    HLOGI("stub session registered gen=%{public}lld %{public}lldx%{public}lld active=1 (backend=stub)",
          static_cast<long long>(generation), static_cast<long long>(width),
          static_cast<long long>(height));
    return 0;
}

// 只读取数：当前 active 替身会话数（探针断言租约状态用）。
static int32_t stubSessionActiveImpl(void)
{
    std::lock_guard<std::mutex> lock(g_leaseMutex);
    int32_t n = 0;
    for (const SurfaceRecord &rec : g_surfaces) {
        if (rec.backend == 1 && rec.active && !rec.retired) n += 1;
    }
    return n;
}

// 生产退役路径：与真实 destroyed 同一实现（退役记录、失效租约、向渲染器
// 请求该代拆除），不经任何替身专用关闭协议。
static int32_t stubSessionRetireImpl(int64_t generation)
{
    void *sentinel = nullptr;
    bool found = false;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &rec : g_surfaces) {
            if (rec.generation == static_cast<uint64_t>(generation) && rec.backend == 1) {
                sentinel = rec.window;
                found = true;
                break;
            }
        }
    }
    if (!found || sentinel == nullptr) {
        HLOGW("stub session retire: active session gen=%{public}lld not found",
              static_cast<long long>(generation));
        return -2;
    }
    // 复用真实 destroyed 实现：退役 + 失效 + （无真实引用，无 fence 需求）
    // + 向渲染器请求该代拆除（renderer 收尾生产路径）。
    onSurfaceDestroyedImpl(nullptr, sentinel);
    HLOGI("stub session retired gen=%{public}lld via production destroy path",
          static_cast<long long>(generation));
    return 0;
}

void onSurfaceDestroyedImpl(OH_NativeXComponent *component, void *window) {
    (void)component;
    uint64_t appInstance = 0;
    uint64_t componentInstance = 0;
    uint64_t generation = 0;
    bool needFence = false;
    // 第九次复核 B：destroyed **无条件**失效挂载事实——即使该记录从未获
    // 渲染准入（active=false）也照样失效；退休记录不再承载挂载语义。
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (g_mountFact.valid && g_mountFact.window == window) {
            g_mountFact.valid = false;
            HLOGI("mount fact invalidated by destroy (unconditional)");
        }
    }
    {
        // 链1：挂起中的补分类请求随 destroyed 取消——窗口保活由 destroyed
        // 界定，销毁后不得再对挂起指针做引用/分类。
        std::lock_guard<std::mutex> lk(g_deferredSurfaceMutex);
        if (g_deferredSurface.valid && g_deferredSurface.window == window) {
            g_deferredSurface.valid = false;
            HLOGI("deferred surface classification cancelled by destroy");
        }
    }
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceLocked(window);
        if (rec == nullptr) {
            HLOGW("surface destroyed on unknown/retired window ignored");
            return;
        }
        // A2 第 ③ 步：**立即退役**——此后不再发放新许可，也不再接受该代触摸。
        rec->retired = true;
        rec->active = false;
        appInstance = rec->appInstance;
        componentInstance = rec->componentInstance;
        rec->retireRequestedAtMs = nowMs();
        if (g_currentGeneration == rec->generation) {
            g_currentGeneration = 0;
        }
        generation = rec->generation;
        g_surfaceDestroyedCount.fetch_add(1);
        // KnownShimNoRef 档：无引用保护 window，destroyed 回调返回前必须拿到
        // 渲染线程拆除 ACK（确定性 fence，Sol Q2），否则系统可能在返回后销毁
        // 对象而 renderer 仍在使用。Verified 档保持异步归还（引用仍在手）。
        needFence = rec->nativeRefUnavailable;
    }
    {
        std::lock_guard<std::mutex> lock(g_touchMutex);
        retireTouchSurfaceLocked(appInstance, componentInstance, generation, 0.0f, 0.0f);
    }
    // A2 第 ④ 步：投递拆除请求。
    if (generation != 0 && g_requestSurfaceTeardownFn != nullptr) {
        int32_t rc = g_requestSurfaceTeardownFn(generation);
        HLOGI("surface destroyed gen=%{public}llu: teardown requested rc=%{public}d",
              static_cast<unsigned long long>(generation), static_cast<int>(rc));
    } else {
        // 没有拆除入口：引用保持未归还并如实计数，绝不谎称已释放。
        HLOGW("surface destroyed gen=%{public}llu: no teardown entry; reference retained",
              static_cast<unsigned long long>(generation));
    }
    if (needFence) {
        // 确定性 fence：等渲染线程真实拆除完成（tornDown），非按等待时长推导。
        // 超时 = 该代失败（ERROR 记账），不虚报可用；指针保留仅作审计。
        std::unique_lock<std::mutex> waitLock(g_leaseMutex);
        const bool acked = g_teardownCv.wait_for(waitLock, std::chrono::milliseconds(kDestroyFenceTimeoutMs),
                                                 [&] {
                                                     SurfaceRecord *r = findSurfaceByGenerationLocked(generation);
                                                     return r != nullptr && r->tornDown;
                                                 });
        SurfaceRecord *rec = findSurfaceByGenerationLocked(generation);
        if (acked && rec != nullptr) {
            rec->teardownAcked = true;
            rec->teardownAckedAtMs = nowMs();
            rec->auditWindow = rec->window;   // 审计存根（仅诊断读数，不复用）
            rec->window = nullptr;            // 指针清除：退休记录只留身份/几何/审计
            HLOGI("destroy fence gen=%{public}llu: renderer ACK in callback; window pointer cleared",
                  static_cast<unsigned long long>(generation));
        } else {
            g_destroyFenceTimeouts.fetch_add(1);
            if (rec != nullptr) rec->admissionClosed = true;  // 永久关闭该代准入
            HLOGE("destroy fence gen=%{public}llu TIMEOUT: generation FAILED (renderer not converged "
                  "within %{public}lld ms); admission permanently closed",
                  static_cast<unsigned long long>(generation),
                  static_cast<long long>(kDestroyFenceTimeoutMs));
        }
    }
}

// A（触摸包指导接续）：活动手指身份（单指策略）。首根按下的手指持有手势；
// 副指 BEGIN 受控忽略，副指 MOVE/UP 不得终结或移动主指手势；主指抬起即
// 释放身份。surface 换代时活动手指作废（旧代事件在 dequeue 侧另有代次拒绝）。
std::mutex g_activePointerMutex;
int32_t g_activePointerId = -1;    // -1 = 无活动手指
uint64_t g_activePointerGeneration = 0;

void dispatchTouchImpl(OH_NativeXComponent *component, void *window) {
    uint64_t appInstance = 0;
    uint64_t componentInstance = 0;
    uint64_t generation = 0;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceLocked(window);
        if (rec == nullptr || !rec->active) {
            return;  // 未知/已退役 surface 的触摸受控丢弃，不触碰 owner
        }
        appInstance = rec->appInstance;
        componentInstance = rec->componentInstance;
        generation = rec->generation;
    }
    OH_NativeXComponent_TouchEvent touch{};
    // A：取数失败零输入——零结构 type==DOWN 只是枚举值 0，不是合法读取。
    if (OH_NativeXComponent_GetTouchEvent(component, window, &touch) !=
        OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        HLOGW("touch read failed: dropped (no synthetic input)");
        return;
    }
    uint32_t action = 0;
    switch (touch.type) {
        case OH_NATIVEXCOMPONENT_DOWN:
            action = kTouchBegin;
            break;
        case OH_NATIVEXCOMPONENT_MOVE:
            action = kTouchUpdate;
            break;
        case OH_NATIVEXCOMPONENT_UP:
            action = kTouchEnd;
            break;
        case OH_NATIVEXCOMPONENT_CANCEL:
            action = kTouchCancel;
            break;
        default:
            return;
    }
    // A：数值必须有限；驱动层异常样本不成合法触摸。坐标保持平台原值
    // （surface 像素域，与已接受场景节点同一坐标域），不做第二次转换。
    if (!std::isfinite(touch.x) || !std::isfinite(touch.y)) {
        HLOGW("touch with non-finite coordinates dropped id=%{public}d", touch.id);
        return;
    }
    {
        std::lock_guard<std::mutex> lock(g_activePointerMutex);
        if (g_activePointerGeneration != generation) {
            g_activePointerId = -1;
            g_activePointerGeneration = generation;
        }
        if (action == kTouchBegin) {
            if (g_activePointerId >= 0 && g_activePointerId != touch.id) {
                HLOGW("secondary finger ignored id=%{public}d active=%{public}d",
                      touch.id, g_activePointerId);
                return;
            }
            g_activePointerId = touch.id;
        } else {
            if (g_activePointerId < 0 || touch.id != g_activePointerId) {
                return;  // 副指的 MOVE/UP/CANCEL 不终结、不移动主指手势
            }
            if (action == kTouchEnd || action == kTouchCancel) {
                g_activePointerId = -1;
            }
        }
    }
    // B（惯性包）：采样时间。优先 SDK touch.timeStamp（相对系统启动单调 ns）；
    // 无效时以入队前 steady_clock 兜底并标记来源（1=桥接收时间）。
    int64_t timestampNs = touch.timeStamp;
    uint32_t timeSource = 0;
    if (timestampNs <= 0) {
        timestampNs = std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();
        timeSource = 1;
    }
    std::lock_guard<std::mutex> lock(g_touchMutex);
    enqueueTouchRecordLocked(action, touch.x, touch.y, appInstance, componentInstance,
                             generation, static_cast<int64_t>(touch.id),
                             timestampNs, timeSource);
}

}  // namespace

// --- napi exports ------------------------------------------------------------

static napi_value ProbeCangjie(napi_env env, napi_callback_info info) {
    (void)info;
    if (g_cangjieLib == nullptr) {
        HLOGE("probe called before cangjie library load");
        return nullptr;
    }
    auto magic = reinterpret_cast<ProbeMagicFn>(dlsym(g_cangjieLib, "cjgui_ohos_probe_magic"));
    auto heap = reinterpret_cast<ProbeHeapFn>(dlsym(g_cangjieLib, "cjgui_ohos_probe_heap"));
    if (magic == nullptr || heap == nullptr) {
        HLOGE("probe symbols missing: magic=%p heap=%p (%s)", reinterpret_cast<void *>(magic),
              reinterpret_cast<void *>(heap), dlerror());
        return nullptr;
    }
    uint64_t magicValue = magic();
    uint64_t heapValue = heap();
    HLOGI("cangjie probe magic=%llu heap=%llu",
          static_cast<unsigned long long>(magicValue), static_cast<unsigned long long>(heapValue));
    char text[96];
    snprintf(text, sizeof(text), "%llu:%llu", static_cast<unsigned long long>(magicValue),
             static_cast<unsigned long long>(heapValue));
    napi_value result;
    napi_create_string_utf8(env, text, NAPI_AUTO_LENGTH, &result);
    return result;
}

using SetFocusSinkFn = void (*)(void (*)(const char *fieldName));
using RequestAppStopFn = int32_t (*)();
using ShutdownRenderFn = int32_t (*)();
using ShutdownDoneFn = int32_t (*)();
using ImeContextCommitFn = int32_t (*)(const char *, size_t, int64_t);
using ImeContextPreviewFn = int32_t (*)(const char *, size_t, int64_t);
using ImeContextEndFn = int32_t (*)(int64_t);
using ImeContextQueryFn = int32_t (*)(char *, int32_t);
using ImeSetSelectionFn = int32_t (*)(int32_t, int32_t, int64_t);
// 显式测试接缝（B1）：**普通产物没有**这个符号，这是预期状态、不是缺陷。
// 只有把 transport/verify/ohos_transport_verify.cj 一起编入的测试构建才有。
using TransportVerifyInstallFn = int32_t (*)();
// A1 §5 受控闸门（时序注入）：**两个变体都导出同名符号**，因此符号存在与否
// 不能区分产物；真正的判别是返回值——测试产物返回 0，普通产物返回 -1。
// 这两个入口只由宿主桥 NAPI 调用，仓颉核心与渲染线程都不查询它们。
using TestGateFailFirstFn = int32_t (*)();
using TestGateSetHoldFn = int32_t (*)(int32_t, int32_t);
using TestGateCountFn = int32_t (*)();
using TestGateI64Fn = int64_t (*)();
// 本进程是否解析到验证接缝（普通产物为 false）。这个值只用于「可否显示测试入口」
// 与取证读数，不能改变任何生产行为。
static TestGateSetHoldFn g_testGateSetHoldFn = nullptr;
static TestGateFailFirstFn g_testGateFailFirstFn = nullptr;
static bool g_testGateFailFirstRequested = false;
static TestGateCountFn g_testGateFlushCountFn = nullptr;
static TestGateCountFn g_testGateFlushHeldCountFn = nullptr;
static TestGateI64Fn g_testGatePlatformCallPackedFn = nullptr;
// 最近一次闸门请求的原始事实（-2 = 从未请求，-1 = 产物不支持/普通产物）。
static std::atomic<int32_t> g_testGateLastRc{-2};
static std::atomic<int32_t> g_testGateLastMs{-1};
static std::atomic<int32_t> g_testGateLastCount{-1};
static SetFocusSinkFn setFocusSinkFn = nullptr;
static RequestAppStopFn requestAppStopFn = nullptr;
static ShutdownRenderFn shutdownRenderFn = nullptr;
static ShutdownDoneFn shutdownDoneFn = nullptr;
static ImeContextCommitFn imeContextCommitFn = nullptr;
static ImeContextPreviewFn imeContextPreviewFn = nullptr;
// 第九次复核 §E：组合预览（text + marked 范围）；缺符号时能力不可用（如实）。
using ImeContextPreviewRangeFn = int32_t (*)(const char *, size_t, int32_t, int32_t, int64_t);
static ImeContextPreviewRangeFn imeContextPreviewRangeFn = nullptr;
static ImeContextEndFn imeContextEndFn = nullptr;
static ImeContextQueryFn imeContextQueryFn = nullptr;
static ImeSetSelectionFn imeSetSelectionFn = nullptr;
// 通用文字代理上下文：ArkTS 侧聚焦时得到的编辑上下文编号，回调必须原样带回。
static std::atomic<int64_t> g_editingContext{0};

// --- 链1：独立启动准备过程 + 挂起 surface 补分类 -----------------------------

// TSFN call_js_cb：UI（JS）线程执行。消费挂起事实，走与回调内同步路径完全
// 相同的分类函数；挂起已被 destroyed 取消时无事可做。
static void SurfaceClassifyCall(napi_env env, napi_value js_cb, void *context, void *data)
{
    (void)env; (void)js_cb; (void)context; (void)data;
    OH_NativeXComponent *component = nullptr;
    void *window = nullptr;
    char id[128] = {0};
    uint64_t width = 0;
    uint64_t height = 0;
    {
        std::lock_guard<std::mutex> lk(g_deferredSurfaceMutex);
        if (!g_deferredSurface.valid) return;
        component = g_deferredSurface.component;
        window = g_deferredSurface.window;
        memcpy(id, g_deferredSurface.id, sizeof(id));
        width = g_deferredSurface.width;
        height = g_deferredSurface.height;
        g_deferredSurface.valid = false;
    }
    if (window == nullptr) return;
    classifyAndPublishSurface(component, window, id, width, height);
}

// 解析完成（或 napi 兜底路径）后检查挂起事实；有则投递 UI 线程补分类。
static void maybeDispatchDeferredSurfaceClassify()
{
    bool need = false;
    {
        std::lock_guard<std::mutex> lk(g_deferredSurfaceMutex);
        need = g_deferredSurface.valid;
    }
    if (!need) return;
    if (g_surfaceClassifyFn == nullptr) {
        // 通道尚未建立（TSFN 在 napi Init 创建）：如实记录，不静默丢弃。
        HLOGW("deferred surface classification pending but classify channel unavailable");
        return;
    }
    HLOGI("dispatching deferred surface classification on UI thread");
    napi_call_threadsafe_function(g_surfaceClassifyFn, nullptr, napi_tsfn_nonblocking);
}

// 独立启动准备线程：库装载 + 全量入口解析，不依赖 XComponent onLoad/startHost。
// startHost 的 owner 线程只等待本过程结果；准备先行、start 先行两种顺序都合法。
static void resolvePlatformEntryPoints(void *handle);

static void entryPrepareProc()
{
    std::lock_guard<std::mutex> lock(g_prepareMutex);
    if (g_cangjieLib == nullptr) {
        for (const std::string &candidate : libraryCandidates()) {
            g_cangjieLib = dlopen(candidate.c_str(), RTLD_NOW);
            if (g_cangjieLib != nullptr) {
                HLOGI("prepare: cangjie library loaded: %{public}s", candidate.c_str());
                break;
            }
            HLOGW("prepare: dlopen %{public}s failed: %{public}s", candidate.c_str(), dlerror());
        }
    }
    if (g_cangjieLib != nullptr) {
        resolvePlatformEntryPoints(g_cangjieLib);
    }
    if (!g_entryPointsResolved.load()) {
        HLOGE("prepare: entry points unresolved (library load failed?); startHost will retry inline");
    }
    g_prepareDone = true;
    g_prepareCv.notify_all();
}

// 所有跨库入口的解析集中在唯一一处。
//
// 教训（实测）：曾把 IME 的 commit/preview/end 三个符号放在装载路径急切解析，
// 而 context_json / set_selection 只在惰性解析里取；惰性解析又用
// 「commit 非空就返回」做短路，于是装载一完成，context_json 永远拿不到，
// 表现为 ArkTS 聚焦回查快照恒为空、文字代理整条链路静默失效。
// 现在改为一次性全量解析 + 缺失逐个告警，不允许再出现「部分解析」。
static void resolvePlatformEntryPoints(void *handle)
{
    if (handle == nullptr) {
        HLOGW("resolvePlatformEntryPoints: no library handle");
        return;
    }
    setFocusSinkFn = reinterpret_cast<SetFocusSinkFn>(
        dlsym(handle, "ohos_renderer_set_focus_sink"));
    requestAppStopFn = reinterpret_cast<RequestAppStopFn>(
        dlsym(handle, "cjgui_ohos_request_application_stop"));
    if (requestAppStopFn == nullptr) {
        requestAppStopFn = reinterpret_cast<RequestAppStopFn>(
            dlsym(handle, "cjgui_internal_renderer_request_application_stop"));
    }
    shutdownRenderFn = reinterpret_cast<ShutdownRenderFn>(
        dlsym(handle, "ohos_renderer_shutdown_render_thread"));
    shutdownDoneFn = reinterpret_cast<ShutdownDoneFn>(
        dlsym(handle, "cjgui_ohos_renderer_shutdown_done"));
    // A2：拆除请求入口（UI 线程调用，立即返回）。引用归还由渲染线程经
    // ingress.surfaceTornDown 回传确认后，宿主在 UI 线程串行执行；
    // `cjgui_ohos_renderer_lease_quiesced` 只是取证读数，**不作归还判据**。
    g_requestSurfaceTeardownFn = reinterpret_cast<RequestSurfaceTeardownFn>(
        dlsym(handle, "cjgui_ohos_request_surface_teardown"));
    leaseQuiescedFn = reinterpret_cast<LeaseQuiescedFn>(
        dlsym(handle, "cjgui_ohos_renderer_lease_quiesced"));
    g_resetInstanceObservationsFn = reinterpret_cast<ResetInstanceObservationsFn>(
        dlsym(handle, "cjgui_ohos_renderer_reset_instance_observations"));
    g_ownerAppReadyFn = reinterpret_cast<OwnerAppReadyFn>(
        dlsym(handle, "cjgui_ohos_owner_app_ready"));
    g_surfacePermitCountersFn = reinterpret_cast<SurfacePermitCountersFn>(
        dlsym(handle, "cjgui_ohos_surface_permit_counters"));
    g_settlementReadoutFn = reinterpret_cast<SettlementReadoutFn>(
        dlsym(handle, "cjgui_ohos_settlement_readout"));
    imeContextCommitFn = reinterpret_cast<ImeContextCommitFn>(
        dlsym(handle, "ohos_renderer_ime_commit_text_ctx"));
    imeContextPreviewFn = reinterpret_cast<ImeContextPreviewFn>(
        dlsym(handle, "ohos_renderer_ime_preview_text_ctx"));
    imeContextPreviewRangeFn = reinterpret_cast<ImeContextPreviewRangeFn>(
        dlsym(handle, "ohos_renderer_ime_preview_range_ctx"));
    imeContextEndFn = reinterpret_cast<ImeContextEndFn>(
        dlsym(handle, "ohos_renderer_ime_finish_editing_ctx"));
    imeContextQueryFn = reinterpret_cast<ImeContextQueryFn>(
        dlsym(handle, "ohos_renderer_ime_context_json"));
    imeSetSelectionFn = reinterpret_cast<ImeSetSelectionFn>(
        dlsym(handle, "ohos_renderer_ime_set_selection_ctx"));

    // 逐个点名缺失项：文字代理的任一环节缺失都应显式可见，不能静默降级。
    if (setFocusSinkFn == nullptr) HLOGW("symbol missing: ohos_renderer_set_focus_sink");
    if (requestAppStopFn == nullptr) HLOGW("symbol missing: request_application_stop");
    if (shutdownRenderFn == nullptr) HLOGW("symbol missing: shutdown_render_thread");
    if (shutdownDoneFn == nullptr) HLOGW("symbol missing: renderer_shutdown_done");
    if (g_requestSurfaceTeardownFn == nullptr) HLOGW("symbol missing: request_surface_teardown");
    if (leaseQuiescedFn == nullptr) HLOGW("symbol missing: renderer_lease_quiesced (diagnostic only)");
    if (g_resetInstanceObservationsFn == nullptr) HLOGW("symbol missing: reset_instance_observations");
    if (g_ownerAppReadyFn == nullptr) HLOGW("symbol missing: owner_app_ready (diagnostic only)");
    if (g_surfacePermitCountersFn == nullptr) HLOGW("symbol missing: surface_permit_counters (diagnostic only)");
    if (g_settlementReadoutFn == nullptr) HLOGW("symbol missing: settlement_readout (stop convergence criterion)");
    if (imeContextCommitFn == nullptr) HLOGW("symbol missing: ime_commit_text_ctx");
    if (imeContextPreviewFn == nullptr) HLOGW("symbol missing: ime_preview_text_ctx");
    if (imeContextPreviewRangeFn == nullptr) HLOGW("symbol missing: ime_preview_range_ctx (composition)");
    if (imeContextEndFn == nullptr) HLOGW("symbol missing: ime_finish_editing_ctx");
    if (imeContextQueryFn == nullptr) HLOGW("symbol missing: ime_context_json");
    if (imeSetSelectionFn == nullptr) HLOGW("symbol missing: ime_set_selection_ctx");

    // 验证接缝（B1）：普通产物缺符号是**预期**，只记状态不告警；测试构建在此注册，
    // 注册后仓颉侧才会解析控制帧并允许切换认领闸门。
    TransportVerifyInstallFn transportVerifyInstallFn = reinterpret_cast<TransportVerifyInstallFn>(
        dlsym(handle, "cjgui_ohos_transport_verify_install"));
    if (transportVerifyInstallFn != nullptr) {
        g_transportVerifyPresent = true;
        int32_t armed = transportVerifyInstallFn();
        HLOGI("transport verify seam: present, install rc=%{public}d", armed);
    } else {
        g_transportVerifyPresent = false;
        HLOGI("transport verify seam: absent (normal product)");
    }
    // 全部跨接缝解析（含 transport verify install）完成，分类可安全进行。
    // 第七次复核 Q1/A4：仅当 handle 非空（owner 已 dlopen cangjie 库，解析
    // 真实发生）才置位——兜底路径以空 handle 调入时置位会虚假放行 surface
    // 回调的分类等待（实测 1ms 竞态根因）。
    if (handle != nullptr) {
        g_entryPointsResolved.store(true);
    }
    // 链1：解析完成时若有挂起 surface 事实（surface 先于解析到达），经 TSFN
    // 回 UI 线程补分类——两种先后顺序都汇入同一条分类路径。
    maybeDispatchDeferredSurfaceClassify();
    // A1 §5 受控闸门入口：两个变体都有符号，用**返回值**区分产物身份。
    // 这里只解析指针并记一行状态；真正是否生效由 setTestGate 的返回码判定。
    g_testGateSetHoldFn = reinterpret_cast<TestGateSetHoldFn>(
        dlsym(handle, "cjgui_ohos_test_gate_set_flush_hold_ms"));
    // A3：首帧强制失败注入（启动失败反例）。
    g_testGateFailFirstFn = reinterpret_cast<TestGateFailFirstFn>(
        dlsym(handle, "cjgui_ohos_test_gate_set_fail_first"));
    g_testGateFlushCountFn = reinterpret_cast<TestGateCountFn>(
        dlsym(handle, "cjgui_ohos_test_gate_flush_count"));
    g_testGateFlushHeldCountFn = reinterpret_cast<TestGateCountFn>(
        dlsym(handle, "cjgui_ohos_test_gate_flush_held_count"));
    g_testGatePlatformCallPackedFn = reinterpret_cast<TestGateI64Fn>(
        dlsym(handle, "cjgui_ohos_test_platform_call_packed"));
    HLOGI("renderer test gate entry: %{public}s (rc 语义: 0=测试产物生效, -1=普通产物不可用)",
          g_testGateSetHoldFn != nullptr ? "symbol present" : "symbol absent");
    HLOGI("platform entry points resolved (ime_context_json=%d)",
          imeContextQueryFn != nullptr ? 1 : 0);
    // A1 §5：启动参数转发发生在 dlopen 之前（EntryAbility onCreate），彼时
    // 渲染器符号尚不可达（rc=-1，如实记录）。入口点已全部解析后**重放一次**
    // 闸门请求——测试产物 rc=0 真实可达；普通产物重放仍返回 -1（行为负控）。
    // A3：fail-first 请求同样在符号解析后重放（onCreate 转发早于 dlopen）。
    if (g_testGateFailFirstRequested && g_testGateFailFirstFn != nullptr) {
        int32_t rc = g_testGateFailFirstFn();
        HLOGI("test gate fail-first-frame re-applied rc=%{public}d", rc);
    }
    if (g_testGateSetHoldFn != nullptr && g_testGateLastRc.load() != 0 &&
        g_testGateLastMs.load() > 0) {
        int32_t rc = g_testGateSetHoldFn(g_testGateLastMs.load(), g_testGateLastCount.load());
        g_testGateLastRc.store(rc);
        HLOGI("test gate set request ms=%{public}d count=%{public}d rc=%{public}d (re-applied)",
              g_testGateLastMs.load(), g_testGateLastCount.load(), rc);
    }

}

// 前置声明：定义在 RegisterFocusRequest 之后（依赖 g_focusRequestFn）。
static void RequestFocusFromRenderer(const std::string &payload);

// 渲染器焦点请求：payload 是带不透明上下文编号的 JSON（{"context":N,"field":"..."}）。
// 宿主只做透明转发，不解释字段名与几何。
static void FocusRequestSink(const char *payload)
{
    if (payload == nullptr) return;
    RequestFocusFromRenderer(payload);
}

// 同进程重开（第七次复核 A3/B）：stopped→startHost 后 owner 阻塞在 surface
// 等待，而 XComponent 仍存活、不会再发 created 回调，surface 重发布命令又
// 依赖 owner pump（鸡生蛋）。此入口让重开流程在 UI 线程直接把现存 window
// 以新代重新发布（与 SIM_CREATED 同一宿主路径，不经过控制通道/owner）。
static napi_value RepublishSurface(napi_env env, napi_callback_info info) {
    (void)env;
    (void)info;
    int32_t rc = -1;
    if (g_ingress.simulateSurfaceCreated != nullptr) {
        rc = g_ingress.simulateSurfaceCreated();
    }
    HLOGI("republish surface requested rc=%{public}d", static_cast<int>(rc));
    napi_value result;
    napi_create_int32(env, static_cast<int32_t>(rc), &result);
    return result;
}

static void startStopMonitorOnce(uint64_t stopAppInstance);

static napi_value StartHost(napi_env env, napi_callback_info info) {
    // The actual private filesDir is supplied by the ArkTS ability that
    // installed its rawfile assets. Some images use a HAP-specific directory
    // (…/haps/entry/files), so a compiled-in sandbox alias is not reliable.
    size_t argc = 1;
    napi_value argv[1] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr) != napi_ok || argc != 1) {
        napi_throw_error(env, nullptr, "startHost requires the current filesDir");
        return nullptr;
    }
    size_t pathLength = 0;
    if (napi_get_value_string_utf8(env, argv[0], nullptr, 0, &pathLength) != napi_ok ||
        pathLength < 28 || pathLength > 255) {
        napi_throw_error(env, nullptr, "invalid image filesDir length");
        return nullptr;
    }
    std::vector<char> pathBuffer(pathLength + 1, '\0');
    size_t copied = 0;
    if (napi_get_value_string_utf8(env, argv[0], pathBuffer.data(), pathBuffer.size(),
                                   &copied) != napi_ok || copied != pathLength) {
        napi_throw_error(env, nullptr, "invalid image filesDir value");
        return nullptr;
    }
    std::string imageDir(pathBuffer.data(), copied);
    constexpr const char *sandboxPrefix = "/data/storage/el2/base/";
    if (imageDir.compare(0, std::strlen(sandboxPrefix), sandboxPrefix) != 0 ||
        imageDir.compare(imageDir.size() - 6, 6, "/files") != 0 ||
        imageDir.find("..") != std::string::npos) {
        napi_throw_error(env, nullptr, "image filesDir is outside the application sandbox");
        return nullptr;
    }
    for (char c : imageDir) {
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '/' || c == '_' || c == '-' || c == '.')) {
            napi_throw_error(env, nullptr, "image filesDir contains an invalid character");
            return nullptr;
        }
    }
    // A3：只有 idle/stopped/failed 才允许进入 starting。stopping（停止中）必须被
    // 拒绝，否则会出现「上一次停止还没收敛就重开」的窗口，旧票据/旧回调会落到
    // 新实例上。failed 允许重开（启动失败与 owner 异常退出都应可重试），但
    // 必须先把上一实例的 owner 线程回收干净。
    int phase = g_hostPhase.load();
    if (phase != kHostIdle && phase != kHostStopped && phase != kHostFailed) {
        HLOGW("startHost rejected: host phase=%{public}s (must be idle/stopped/failed)", hostPhaseName(phase));
        return nullptr;
    }
    // 顺序（A3）：先在**尚未进入 starting** 时完成线程记账与实例分配，
    // 再 CAS 到 starting。这样一旦 phase 变成 starting，owner 线程句柄、
    // 线程身份与本实例编号都已经是最终值，停止路径不会看到半成品状态。
    uint64_t startAppInstance = 0;
    uint64_t previousAppInstance = 0;
    bool restartFromSettledStop = false;
    {
        std::lock_guard<std::mutex> lock(g_ownerThreadMutex);
        // 上一实例的 owner 线程必须先真实回收，才允许开新实例：否则两个 owner
        // 可能同时在跑，旧 owner 的票据/回调会落到新实例上。此处 join 是安全的——
        // 只有 idle/stopped/failed 才走到这里，owner 入口已经返回或即将返回。
        if (g_appThread.joinable()) {
            HLOGI("startHost: reclaiming previous owner thread (appInstance=%{public}llu)",
                  static_cast<unsigned long long>(g_threadOwnerInstance));
            g_appThread.join();
        }
        std::lock_guard<std::mutex> stateLock(g_hostTransitionMutex);
        phase = g_hostPhase.load();
        if (phase != kHostIdle && phase != kHostStopped && phase != kHostFailed) {
            HLOGW("startHost rejected: phase changed to %{public}s", hostPhaseName(phase));
            return nullptr;
        }
        // No previous owner remains past this point. Publish this launch's
        // actual asset directory before the new owner reads the declarations.
        if (setenv("CJGUI_IMAGE_FIXTURE_DIR", imageDir.c_str(), 1) != 0) {
            napi_throw_error(env, nullptr, "failed to publish image filesDir");
            return nullptr;
        }
        HLOGI("image asset directory bound: %{public}s", imageDir.c_str());
        restartFromSettledStop = phase == kHostStopped;
        previousAppInstance = g_appInstance.load();
        // A3：本次启动分配一个**不复用**的 appInstance。surface 身份、停止判据
        // 都挂在它上面；重开后不能继承上一实例的任何身份。
        g_appInstance.store(g_nextAppInstance++);
        startAppInstance = g_appInstance.load();
        g_threadOwnerInstance = startAppInstance;
        g_ownerThreadId = std::thread::id{};
        g_ownerOutcomeInstance = startAppInstance;
        g_ownerOutcome = -1;
        g_stopRequested.store(false);
        g_ownerReady.store(false);
        g_ownerExited.store(false);
        g_hostPhase.store(kHostStarting);
    }
    HLOGI("startHost accepted: phase=starting appInstance=%{public}llu",
          static_cast<unsigned long long>(startAppInstance));
    if (restartFromSettledStop) {
        // The owner of the previous instance has exited and its renderer,
        // permits and native reference have all reached zero. The XComponent
        // may still be physically mounted, so it need not send another
        // OnSurfaceCreated. This NAPI call runs on the same UI thread as the
        // native mount/destroy callbacks: only its current mount fact may be
        // rebound, and classifyAndPublishSurface takes a fresh system ref and
        // allocates a new record/generation for this appInstance.
        MountFact mounted;
        {
            std::lock_guard<std::mutex> lock(g_leaseMutex);
            if (g_mountFact.valid && g_mountFact.window != nullptr &&
                g_mountFact.appInstance == previousAppInstance) {
                mounted = g_mountFact;
            }
        }
        if (mounted.valid) {
            HLOGI("restart live mount rebind oldApp=%{public}llu newApp=%{public}llu epoch=%{public}llu",
                  static_cast<unsigned long long>(previousAppInstance),
                  static_cast<unsigned long long>(startAppInstance),
                  static_cast<unsigned long long>(mounted.mountEpoch));
            classifyAndPublishSurface(nullptr, mounted.window, mounted.componentId.c_str(),
                                      static_cast<uint64_t>(mounted.width),
                                      static_cast<uint64_t>(mounted.height));
        } else {
            HLOGI("restart awaits native mount: no live previous-instance mount fact");
        }
        // The verify seam belongs to an owner instance, not the process. A
        // fresh token makes old control frames invalid after full-zero STOP.
        if (g_transportVerifyPresent && g_cangjieLib != nullptr) {
            auto install = reinterpret_cast<TransportVerifyInstallFn>(
                dlsym(g_cangjieLib, "cjgui_ohos_transport_verify_install"));
            int32_t rc = install != nullptr ? install() : -1;
            HLOGI("restart verify seam install appInstance=%{public}llu rc=%{public}d",
                  static_cast<unsigned long long>(startAppInstance), rc);
        }
    }
    g_appThread = std::thread([startAppInstance]() {
        {
            std::lock_guard<std::mutex> lock(g_ownerThreadMutex);
            g_ownerThreadId = std::this_thread::get_id();
        }
        auto failBeforeOwnerEntry = [startAppInstance]() {
            {
                std::lock_guard<std::mutex> stateLock(g_hostTransitionMutex);
                if (g_appInstance.load() == startAppInstance &&
                    g_ownerOutcomeInstance == startAppInstance) {
                    g_ownerOutcome = 1;
                    g_hostPhase.store(kHostFailed);
                }
            }
            g_ownerExited.store(true);
        };
        HLOGI("owner thread started (appInstance=%{public}llu)",
              static_cast<unsigned long long>(startAppInstance));
        // 链1：库装载与入口解析已由独立准备过程执行（napi Init 启动的准备
        // 线程）。owner 只等待其完成；准备失败/未跑时在本线程兜底重试一次
        // ——准备先行与 start 先行两种顺序都合法，最终都汇入同一解析结果。
        {
            std::unique_lock<std::mutex> lock(g_prepareMutex);
            if (!g_prepareCv.wait_for(lock, std::chrono::seconds(30),
                                      [] { return g_prepareDone; })) {
                HLOGW("startHost: entry preparation wait timed out; retrying inline");
            }
        }
        if (!g_entryPointsResolved.load()) {
            std::lock_guard<std::mutex> lock(g_prepareMutex);
            bool loaded = false;
            for (const std::string &candidate : libraryCandidates()) {
                g_cangjieLib = dlopen(candidate.c_str(), RTLD_NOW);
                if (g_cangjieLib != nullptr) {
                    HLOGI("cangjie library loaded (owner retry): %{public}s", candidate.c_str());
                    loaded = true;
                    break;
                }
                HLOGW("dlopen %{public}s failed: %{public}s", candidate.c_str(), dlerror());
            }
            if (!loaded) {
                // 启动失败必须可重试：进入 failed（可重开），而不是卡在 starting。
                HLOGE("cangjie library not loadable; host phase=failed");
                failBeforeOwnerEntry();
                return;
            }
            resolvePlatformEntryPoints(g_cangjieLib);
        }
        if (!g_entryPointsResolved.load()) {
            HLOGE("entry points unresolved after prepare+retry; host phase=failed");
            failBeforeOwnerEntry();
            return;
        }
        // A3：复位**上一实例遗留**的观察位（就绪/停止完成/停止请求），
        // 使它们不会被新实例误当作自己的事实。
        if (g_resetInstanceObservationsFn != nullptr) {
            g_resetInstanceObservationsFn();
        }
        if (setFocusSinkFn) setFocusSinkFn(FocusRequestSink);
        auto appMain = reinterpret_cast<AppMainFn>(dlsym(g_cangjieLib, "cjgui_ohos_app_main"));
        if (appMain == nullptr) {
            HLOGE("cjgui_ohos_app_main missing: %s", dlerror());
            failBeforeOwnerEntry();
            return;
        }
        HLOGI("calling cjgui_ohos_app_main (appInstance=%{public}llu; entry blocks until owner exits)",
              static_cast<unsigned long long>(startAppInstance));
        int rc = appMain(&g_ingress);
        // 第九次复核 C：owner 是否**声明过停止**（同一 cangjie 库导出，dlsym 取）。
        // rc==0 且声明过停止 → 真实 stopped；否则（启动失败/异常退出）→ failed。
        using OwnerExitReasonFn = int32_t (*)();
        static OwnerExitReasonFn ownerExitReasonFn = nullptr;
        if (ownerExitReasonFn == nullptr) {
            ownerExitReasonFn = reinterpret_cast<OwnerExitReasonFn>(
                dlsym(g_cangjieLib, "cjgui_ohos_owner_exit_reason"));
        }
        const int32_t ownerExitReason = (ownerExitReasonFn != nullptr) ? ownerExitReasonFn() : -1;
        const bool ownerStopDeclared = (ownerExitReason == 0);
        const bool orderly = rc == 0 && ownerStopDeclared;
        HLOGI("cjgui_ohos_app_main returned rc=%{public}d (appInstance=%{public}llu): owner really exited"
              " stop_declared=%{public}d",
              rc, static_cast<unsigned long long>(startAppInstance), ownerStopDeclared ? 1 : 0);
        bool startMonitor = false;
        int after = kHostFailed;
        {
            std::lock_guard<std::mutex> stateLock(g_hostTransitionMutex);
            if (g_appInstance.load() != startAppInstance ||
                g_ownerOutcomeInstance != startAppInstance) {
                HLOGE("stale owner exit ignored appInstance=%{public}llu",
                      static_cast<unsigned long long>(startAppInstance));
                return;
            }
            g_ownerOutcome = orderly ? 0 : 1;
            after = g_hostPhase.load();
            if (!orderly && (after == kHostStarting || after == kHostRunning || after == kHostStopping)) {
                g_hostPhase.store(kHostFailed);
                HLOGE("owner exited without orderly cleanup: host phase=failed rc=%{public}d reason=%{public}d",
                      rc, ownerExitReason);
            } else if (orderly && (after == kHostStarting || after == kHostRunning)) {
                // 正常窗口关闭只认领观察，不重发应用停止、surface 退役或 renderer teardown。
                g_hostPhase.store(kHostStopping);
                startMonitor = true;
                HLOGI("orderly owner exit adopted: host phase=stopping appInstance=%{public}llu",
                      static_cast<unsigned long long>(startAppInstance));
            } else {
                HLOGI("owner exited while phase=%{public}s: recorded outcome only", hostPhaseName(after));
            }
        }
        // 先发布本实例结果，再发布退出位；之后不得再取 owner 线程句柄锁。
        g_ownerExited.store(true);
        if (startMonitor) startStopMonitorOnce(startAppInstance);
    });
    return nullptr;
}

// 收敛监控只观察与判定；由外部停止请求或有序 owner 退出中的唯一相位
// Stopping 转换者启动。绝不在 owner 线程里 join 自己。
static void startStopMonitorOnce(uint64_t stopAppInstance) {
    // 判据（对**同一个 appInstance**）：
    //   ① owner 线程真实退出并被 join；
    //   ② 渲染线程 teardown 完成（不是只看一个可能过期的全局值——该值已在
    //      本次启动时复位过，且这里与①②③④同时成立才算数）；
    //   ③ 窗口会话/票据收敛（occupied=0、unacked=0、pending=0）；
    //   ④ 本实例 surface 使用许可与 native 引用全部归还。
    // 传输侧的结果由 owner 清理后声明，失败不会发布有序 owner 结果。
    std::thread([stopAppInstance]() {
        const int maxRounds = 1000;   // ≤10s 有界观察
        bool ownerJoined = false;
        bool rendererDone = false;
        int32_t occupied = -1;
        int64_t unacked = -1;
        int64_t pending = -1;
        int32_t activeSurfaces = -1;
        int64_t refsUnclosed = -1;
        bool converged = false;
        bool rendererNotStarted = false;
        for (int i = 0; i < maxRounds; ++i) {
            int32_t ownerOutcome = -1;
            int phase = kHostFailed;
            {
                std::lock_guard<std::mutex> stateLock(g_hostTransitionMutex);
                if (g_appInstance.load() != stopAppInstance ||
                    g_ownerOutcomeInstance != stopAppInstance) {
                    HLOGW("stop monitor abandoned stale appInstance=%{public}llu",
                          static_cast<unsigned long long>(stopAppInstance));
                    return;
                }
                ownerOutcome = g_ownerOutcome;
                phase = g_hostPhase.load();
            }
            if (phase == kHostFailed) break;
            if (!ownerJoined) {
                ownerJoined = ownerThreadJoinedForInstance(stopAppInstance);
            }
            rendererDone = (shutdownDoneFn != nullptr) && (shutdownDoneFn() == 1);
            rendererNotStarted = !g_ownerReady.load() && ownerOutcome == 0 && !rendererDone;
            if (g_settlementReadoutFn != nullptr) {
                g_settlementReadoutFn(&occupied, &unacked, &pending);
            }
            refsUnclosed = surfaceAccountingForInstance(stopAppInstance, &activeSurfaces);
            if (ownerJoined && ownerOutcome == 0 && (rendererDone || rendererNotStarted) &&
                occupied == 0 && unacked == 0 && pending == 0 &&
                refsUnclosed == 0 && activeSurfaces == 0) {
                converged = true;
                break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        int after = kHostFailed;
        bool settled = false;
        {
            std::lock_guard<std::mutex> stateLock(g_hostTransitionMutex);
            if (g_appInstance.load() != stopAppInstance ||
                g_ownerOutcomeInstance != stopAppInstance) {
                HLOGW("stop monitor finalization abandoned stale appInstance=%{public}llu",
                      static_cast<unsigned long long>(stopAppInstance));
                return;
            }
            after = g_hostPhase.load();
            if (converged && g_ownerOutcome == 0 && after == kHostStopping) {
                g_hostPhase.store(kHostStopped);
                settled = true;
            }
        }
        if (settled) {
            HLOGI("stop settled appInstance=%{public}llu ownerJoined=1 rendererDone=%{public}d rendererNotStarted=%{public}d sessions=0 unacked=0 pending=0 refsUnclosed=0 activeSurfaces=0 (phase=stopped)",
                  static_cast<unsigned long long>(stopAppInstance), rendererDone ? 1 : 0,
                  rendererNotStarted ? 1 : 0);
            return;
        }
        if (after == kHostFailed) {
            HLOGW("stop monitor: host phase=failed; settlement not claimed appInstance=%{public}llu",
                  static_cast<unsigned long long>(stopAppInstance));
            return;
        }
        // 未收敛：保留 stopping 与启动身份，如实报告未完成——不谎称已停止。
        HLOGW("stop NOT settled within 10s appInstance=%{public}llu ownerJoined=%{public}d rendererDone=%{public}d sessions=%{public}d unacked=%{public}lld pending=%{public}lld refsUnclosed=%{public}lld activeSurfaces=%{public}d phase=%{public}s (start identity retained)",
              static_cast<unsigned long long>(stopAppInstance), ownerJoined ? 1 : 0, rendererDone ? 1 : 0,
              occupied, static_cast<long long>(unacked), static_cast<long long>(pending),
              static_cast<long long>(refsUnclosed), activeSurfaces, hostPhaseName(g_hostPhase.load()));
    }).detach();
}

// A3：外部停止只负责下发一次停止请求；正常 owner 窗口关闭仅复用上面的观察者。
static void requestHostStopOnce(const char *origin) {
    uint64_t stopAppInstance = 0;
    {
        std::lock_guard<std::mutex> stateLock(g_hostTransitionMutex);
        int phase = g_hostPhase.load();
        if (phase != kHostRunning && phase != kHostStarting) {
            HLOGW("%{public}s ignored: host phase=%{public}s (only starting/running can stop)",
                  origin, hostPhaseName(phase));
            return;
        }
        stopAppInstance = g_appInstance.load();
        g_stopRequested.store(true);
        g_hostPhase.store(kHostStopping);
    }
    HLOGI("%{public}s: host phase=stopping appInstance=%{public}llu; requesting application stop",
          origin, static_cast<unsigned long long>(stopAppInstance));
    int32_t retiredRequests = retireAllSurfacesOfInstance();
    HLOGI("stop: %{public}d surface(s) retired for appInstance=%{public}llu",
          retiredRequests, static_cast<unsigned long long>(stopAppInstance));
    if (requestAppStopFn != nullptr) {
        int32_t epoch = requestAppStopFn();
        HLOGI("application stop requested (renderer epoch=%{public}d)", epoch);
    } else {
        HLOGW("stop symbol missing; owner keeps running (start identity retained)");
    }
    startStopMonitorOnce(stopAppInstance);
}

// 关闭完成观察：owner 退出 + 渲染线程 shutdown 后由宿主断言。
// 返回 "1" 表示渲染线程已确认退出；"0" 表示仍在收敛（未定，不谎称成功）。
static napi_value ShutdownState(napi_env env, napi_callback_info info) {
    (void)info;
    int32_t done = shutdownDoneFn != nullptr ? shutdownDoneFn() : 0;
    napi_value result;
    napi_create_string_utf8(env, done == 1 ? "1" : "0", NAPI_AUTO_LENGTH, &result);
    return result;
}

// A3/取证读数：phase|appInstance|ownerReady|ownerExited|rendererDone|seam|
//                refs|unrefs|pending|unclosed|active
static napi_value HostState(napi_env env, napi_callback_info info) {
    (void)info;
    const uint64_t instance = g_appInstance.load();
    int32_t activeSurfaces = -1;
    int64_t refsUnclosed = surfaceAccountingForInstance(instance, &activeSurfaces);
    int64_t permitsAcquired = -1, permitsReleased = -1;
    uint64_t boundGeneration = 0;
    if (g_surfacePermitCountersFn != nullptr) {
        g_surfacePermitCountersFn(&permitsAcquired, &permitsReleased, &boundGeneration);
    }
    int32_t occupied = -1;
    int64_t unacked = -1, pendingSettlements = -1;
    if (g_settlementReadoutFn != nullptr) {
        g_settlementReadoutFn(&occupied, &unacked, &pendingSettlements);
    }
    char buf[768];
    snprintf(buf, sizeof(buf),
             "phase=%s appInstance=%llu ownerReady=%d ownerExited=%d rendererDone=%d seam=%d "
             "refs=%lld unrefs=%lld refsPending=%lld surfacesUnclosed=%lld surfacesActive=%d "
             "permits=%lld/%lld boundGen=%llu sessions=%d unacked=%lld pendingTickets=%lld "
             "refCap=%s created=%lld destroyed=%lld fenceTimeouts=%lld oldGenRejected=%lld",
             hostPhaseName(g_hostPhase.load()),
             static_cast<unsigned long long>(instance),
             g_ownerReady.load() ? 1 : 0,
             g_ownerExited.load() ? 1 : 0,
             shutdownDoneFn != nullptr ? shutdownDoneFn() : -1,
             g_transportVerifyPresent ? 1 : 0,
             static_cast<long long>(g_nativeRefCount.load()),
             static_cast<long long>(g_nativeUnrefCount.load()),
             static_cast<long long>(g_nativeRefPendingCount.load()),
             static_cast<long long>(refsUnclosed), activeSurfaces,
             static_cast<long long>(permitsAcquired), static_cast<long long>(permitsReleased),
             static_cast<unsigned long long>(boundGeneration),
             occupied, static_cast<long long>(unacked), static_cast<long long>(pendingSettlements),
             g_refCapability == RefCapability::kVerifiedNativeRef ? "verified"
                 : g_refCapability == RefCapability::kKnownShimNoRef ? "knownShimNoRef"
                 : g_refCapability == RefCapability::kRefUnavailable ? "unavailable" : "undetermined",
             static_cast<long long>(g_surfaceCreatedCount.load()),
             static_cast<long long>(g_surfaceDestroyedCount.load()),
             static_cast<long long>(g_destroyFenceTimeouts.load()),
             static_cast<long long>(g_oldGenEventsRejected.load()));
    napi_value result;
    napi_create_string_utf8(env, buf, NAPI_AUTO_LENGTH, &result);
    return result;
}

// A1 §5：受控闸门控制入口（**应用内唯一的测试控制路径**）。
// 命令来自启动参数（`aa start --pi cjguiTestGateFlushHoldMs <n>`），EntryAbility
// 在 onCreate 里转发到这里，再落到渲染器的时序闸门。返回值即产物身份判别：
// 0 = 测试产物（闸门已生效）；-1 = 普通产物（无闸门，请求被如实拒绝）。
// A3：首帧强制失败注入入口（启动参数 cjguiTestGateFailFirstFrame 转发）。
// A3：首帧强制失败注入入口（启动参数 cjguiTestGateFailFirstFrame 转发）。
static napi_value SetTestGateFailFirst(napi_env env, napi_callback_info info) {
    int32_t rc = -1;
    g_testGateFailFirstRequested = true;
    if (g_testGateFailFirstFn != nullptr) {
        rc = g_testGateFailFirstFn();
    }
    HLOGI("test gate fail-first-frame request rc=%{public}d", rc);
    napi_value result;
    napi_create_int32(env, rc, &result);
    return result;
}

// 第九次复核 B：NEG4 隔离夹具 napi 入口（libentry 内部直调，无跨库解析）。
static int32_t RunAuditNegativeFixture(void);
// 测试后端的合法资源记录：注册 active 替身会话（window 为非空哨兵，不发布
// 真实 XComponent 裸指针；backend=1）。身份/准入/许可/退役规则与真实记录
// 完全同一套——租约由本表 active 状态承载，渲染器经正常 session 提交驱动
// 原票结算与 ACK，不再另造替身关闭协议。
// 第九次复核 A3：cangjie foreign 直调导出（经 renderer ingress 双通道：
// 渲染线程侧同签名转发；本导出供 owner 线程直接注册）。
// 第九次复核 B：NEG4 隔离测试夹具——拦截 Reference（零真实平台调用），
// 逐场景构造表状态并断言 SIM_CREATED 的调用次数：
//   a) 拒准入后真实 destroyed（mount 失效、退休 window 非空）→ 0 次
//   b) 只剩 audit 存根（window=nullptr）→ 0 次
//   c) 错实例挂载事实（appInstance 不符）→ 0 次
static int32_t RunAuditNegativeFixture(void)
{
#ifdef CJGUI_OHOS_TEST_GATES
    // NAPI invokes this synchronously on the UI thread, where native mount
    // callbacks are serialized. Restore the live mount after the isolated
    // negative states; the fixture must not erase production restart truth.
    MountFact liveMount;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        liveMount = g_mountFact;
    }
    g_refFixtureArmed.store(true);
    const int64_t base = g_refFixtureReferenceCalls.load();
    int32_t verdict = 0;
    const void *kPoison = reinterpret_cast<void *>(0xBAD0BAD0);

    // 场景 a：拒准入后真实 destroyed——mount 事实已失效，退休 window 非空。
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        g_mountFact.valid = false;   // destroyed 已失效
        SurfaceRecord bad;
        bad.appInstance = g_appInstance;
        bad.generation = 0xAA01;
        bad.componentId = "neg_a";
        bad.window = const_cast<void *>(kPoison);   // 退休记录 window 非空（不证明挂载）
        bad.width = 10; bad.height = 10; bad.density = 1.0;
        bad.retired = true; bad.active = false;
        g_surfaces.push_back(bad);
    }
    if (bridgeSimulateSurfaceCreatedImpl() != -2) verdict = 1;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (auto it = g_surfaces.begin(); it != g_surfaces.end(); ++it)
            if (it->generation == 0xAA01) { g_surfaces.erase(it); break; }
    }

    // 场景 b：只剩 audit 存根。
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        g_mountFact.valid = false;
        SurfaceRecord bad;
        bad.appInstance = g_appInstance;
        bad.generation = 0xAA02;
        bad.componentId = "neg_b";
        bad.window = nullptr;
        bad.auditWindow = const_cast<void *>(kPoison);
        bad.width = 10; bad.height = 10; bad.density = 1.0;
        bad.retired = true; bad.active = false;
        g_surfaces.push_back(bad);
    }
    if (bridgeSimulateSurfaceCreatedImpl() != -2) verdict = 2;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (auto it = g_surfaces.begin(); it != g_surfaces.end(); ++it)
            if (it->generation == 0xAA02) { g_surfaces.erase(it); break; }
    }

    // 场景 c：错实例/错挂载代——mount 事实属旧实例（appInstance 不符）。
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        g_mountFact.window = const_cast<void *>(kPoison);
        g_mountFact.mountEpoch += 1;
        g_mountFact.appInstance = g_appInstance + 1;   // 错实例
        g_mountFact.valid = true;
    }
    if (bridgeSimulateSurfaceCreatedImpl() != -2) verdict = 3;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (g_mountFact.window != kPoison ||
            g_mountFact.appInstance != g_appInstance + 1 || !g_mountFact.valid) {
            verdict = 4;  // another writer changed the mount; never resurrect it
        } else {
            const uint64_t nextEpoch = g_mountFact.mountEpoch + 1;
            g_mountFact = liveMount;
            g_mountFact.mountEpoch = nextEpoch;
        }
    }

    const int64_t calls = g_refFixtureReferenceCalls.load() - base;
    g_refFixtureArmed.store(false);   // 判定后立即解除：并发首帧 Reference 不入窗
    HLOGI("audit negative fixture: calls=%{public}lld verdict=%{public}d (0=all rejected)",
          static_cast<long long>(calls), verdict);
    if (calls != 0 || verdict != 0) {
        HLOGE("audit negative fixture FAILED: Reference attempted in NEG scenario");
        return -1;
    }
    return 0;
#else
    return -1;
#endif
}

static napi_value AuditNegativeFixture(napi_env env, napi_callback_info info) {
    (void)env; (void)info;
    int32_t rc = RunAuditNegativeFixture();
    napi_value result;
    napi_create_int32(env, rc, &result);
    return result;
}

static napi_value SetTestGate(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t ms = 0;
    int32_t count = 1;
    if (argc >= 1 && argv[0] != nullptr) {
        napi_get_value_int32(env, argv[0], &ms);
    }
    if (argc >= 2 && argv[1] != nullptr) {
        napi_get_value_int32(env, argv[1], &count);
    }
    int32_t rc = -1;
    if (g_testGateSetHoldFn != nullptr) {
        rc = g_testGateSetHoldFn(ms, count);
    }
    g_testGateLastRc.store(rc);
    g_testGateLastMs.store(ms);
    g_testGateLastCount.store(count);
    HLOGI("test gate set request ms=%{public}d count=%{public}d rc=%{public}d",
          ms, count, rc);

    napi_value result = nullptr;
    napi_create_int32(env, rc, &result);
    return result;
}


// 闸门读数（只读取证）：请求值、返回码、真实进入 Flush 次数、闸门实际按住次数。
// 普通产物上三个计数入口返回 -1，读数里如实体现为不可用，不伪造 0。
static napi_value TestGateState(napi_env env, napi_callback_info info) {
    (void)info;
    int32_t flushCount = g_testGateFlushCountFn != nullptr ? g_testGateFlushCountFn() : -1;
    int32_t heldCount = g_testGateFlushHeldCountFn != nullptr ? g_testGateFlushHeldCountFn() : -1;
    char buf[256];
    snprintf(buf, sizeof(buf), "gate ms=%d count=%d rc=%d flush=%d held=%d",
             g_testGateLastMs.load(), g_testGateLastCount.load(), g_testGateLastRc.load(),
             flushCount, heldCount);
    napi_value result = nullptr;
    napi_create_string_utf8(env, buf, NAPI_AUTO_LENGTH, &result);
    return result;
}

// 应用停止协议（Sol 五步归属 / A3 状态机）：停止接单 → owner 退出 → 传输收敛 →
// 渲染线程 teardown surface/GPU → 复位启动身份，允许同进程重开。
// surface 暂时卸载不进入此路径：onSurfaceDestroyedImpl 只退役该代并投递拆除，
// 引用在该代于渲染线程真实拆除后才由 UI 线程归还。
static napi_value StopHost(napi_env env, napi_callback_info info) {
    (void)env;
    (void)info;
    HLOGI("stopHost requested (started=%{public}d phase=%{public}s appInstance=%{public}llu)",
          hostStarted() ? 1 : 0, hostPhaseName(g_hostPhase.load()),
          static_cast<unsigned long long>(g_appInstance.load()));
    requestHostStopOnce("stopHost");
    return nullptr;
}

// 关闭完成观察：owner 退出 + 渲染线程 shutdown 后由宿主断言。
// 返回 "1" 表示渲染线程已确认退出；"0" 表示仍在收敛（未定，不谎称成功）。
static napi_value AppForeground(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    bool foreground = false;
    if (argc >= 1) {
        napi_get_value_bool(env, argv[0], &foreground);
    }
    g_foreground.store(foreground ? 1 : 0);
    HLOGI("foreground=%d", foreground ? 1 : 0);
    return nullptr;
}

static napi_value AppShutdown(napi_env env, napi_callback_info info) {
    (void)env;
    (void)info;
    g_foreground.store(0);
    // Ability 真正销毁（非 surface 卸载）：进入一次性停止协议。
    // 每步归属明确：本调用只置位与请求，owner/渲染线程各自在自己的线程完成
    // 退出与 teardown，UI 回调不等待需要 UI 自己完成的工作。
    HLOGI("shutdown observed (started=%{public}d phase=%{public}s): requesting application stop",
          hostStarted() ? 1 : 0, hostPhaseName(g_hostPhase.load()));
    requestHostStopOnce("appShutdown");
    return nullptr;
}

static int g_initCalls = 0;

// ---- ArkTS TextInput 代理路径（C-API IME 桩在此镜像不可用，见执行记录） ----
// 焦点请求：渲染器合成焦点后经 threadsafe fn 通知 ArkTS 聚焦隐藏输入框。
static napi_threadsafe_function g_focusRequestFn = nullptr;

static void FocusRequestCall(napi_env env, napi_value js_cb, void *context, void *data)
{
    (void)context;
    std::string *fieldName = static_cast<std::string *>(data);
    napi_value argv[1];
    napi_create_string_utf8(env, fieldName->c_str(), NAPI_AUTO_LENGTH, &argv[0]);
    napi_value undefinedResult;
    napi_call_function(env, js_cb, js_cb, 1, argv, &undefinedResult);
    delete fieldName;
}

static napi_value RegisterFocusRequest(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc < 1) return nullptr;
    napi_value resourceName;
    napi_create_string_utf8(env, "CjguiFocusRequest", NAPI_AUTO_LENGTH, &resourceName);
    napi_create_threadsafe_function(env, argv[0], nullptr, resourceName, 0, 1, nullptr,
                                    nullptr, nullptr, FocusRequestCall, &g_focusRequestFn);
    return nullptr;
}

static void RequestFocusFromRenderer(const std::string &fieldName)
{
    if (g_focusRequestFn == nullptr) return;
    std::string *copy = new std::string(fieldName);
    napi_call_threadsafe_function(g_focusRequestFn, copy, napi_tsfn_nonblocking);
}

// 兜底：napi 回调里若发现入口还没解析（例如宿主在装载前就被调用），
// 再做一次全量解析。这里**不能**用「某一个指针非空就返回」做短路——
// 那正是导致 ime_context_json 永远解析不到的原始缺陷。
static void resolveImeEntryPoints()
{
    if (imeContextCommitFn != nullptr && imeContextPreviewFn != nullptr &&
        imeContextEndFn != nullptr && imeContextQueryFn != nullptr &&
        imeSetSelectionFn != nullptr) {
        return;
    }
    resolvePlatformEntryPoints(g_cangjieLib);
}

// 读第 n 个字符串参数
static bool readStringArg(napi_env env, napi_value value, std::string *out)
{
    if (value == nullptr) return false;
    size_t textLen = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &textLen) != napi_ok) return false;
    std::string text(textLen, '\0');
    napi_get_value_string_utf8(env, value, &text[0], textLen + 1, &textLen);
    text.resize(textLen);
    *out = text;
    return true;
}

static int64_t readInt64Arg(napi_env env, napi_value value)
{
    if (value == nullptr) return 0;
    int64_t v = 0;
    if (napi_get_value_int64(env, value, &v) != napi_ok) {
        // ArkTS number 走 double 通道
        double d = 0;
        if (napi_get_value_double(env, value, &d) == napi_ok) v = static_cast<int64_t>(d);
    }
    return v;
}

// 上下文快照：平台据此初始化代理（值/几何/选区/上下文编号）。
// 返回 JSON 字符串；无有效上下文时返回空串（平台不得凭空造初值）。
static napi_value ImeEditingContext(napi_env env, napi_callback_info info)
{
    (void)info;
    resolveImeEntryPoints();
    // 快照现在同时带能力/marked 元数据；给正常字段全文留出明确上界。
    char buffer[8192];
    buffer[0] = '\0';
    int32_t ok = 0;
    if (imeContextQueryFn != nullptr) {
        ok = imeContextQueryFn(buffer, static_cast<int32_t>(sizeof(buffer)));
        if (ok == 1) {
            // 原始快照留证：平台侧解析出的值与这里必须一致。
            HLOGI("ime context json: %{public}s", buffer);
        }
    } else {
        HLOGW("ime context query symbol unresolved; platform entry resolution incomplete");
    }
    napi_value result;
    napi_create_string_utf8(env, ok == 1 ? buffer : "", NAPI_AUTO_LENGTH, &result);
    return result;
}

// 提交（text, context）→ "0" 已应用 / "1" 上下文失效被拒
static napi_value ImeCommitText(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value argv[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    std::string text;
    int64_t ctx = readInt64Arg(env, argc >= 2 ? argv[1] : nullptr);
    int32_t rc = 1;
    resolveImeEntryPoints();
    if (argc >= 1 && readStringArg(env, argv[0], &text) && imeContextCommitFn != nullptr) {
        rc = imeContextCommitFn(text.c_str(), text.size(), ctx);
    }
    napi_value result;
    napi_create_string_utf8(env, rc == 0 ? "0" : "1", NAPI_AUTO_LENGTH, &result);
    return result;
}

// 预览（text, context）→ 同上；预览只写视觉投影，不进 owner。
// 第九次复核 §E：组合态预览（text + marked 范围）。
static napi_value ImePreviewRange(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value argv[4] = {nullptr, nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    std::string text;
    int64_t ctx = readInt64Arg(env, argc >= 4 ? argv[3] : nullptr);
    int64_t start = readInt64Arg(env, argc >= 2 ? argv[1] : nullptr);
    int64_t end = readInt64Arg(env, argc >= 3 ? argv[2] : nullptr);
    int32_t rc = 1;
    resolveImeEntryPoints();
    if (argc >= 1 && readStringArg(env, argv[0], &text) && imeContextPreviewRangeFn != nullptr) {
        rc = imeContextPreviewRangeFn(text.c_str(), text.size(),
                                      static_cast<int32_t>(start), static_cast<int32_t>(end), ctx);
    }
    napi_value result;
    napi_create_string_utf8(env, rc == 0 ? "0" : "1", NAPI_AUTO_LENGTH, &result);
    return result;
}

static napi_value ImePreviewText(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value argv[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    std::string text;
    int64_t ctx = readInt64Arg(env, argc >= 2 ? argv[1] : nullptr);
    int32_t rc = 1;
    resolveImeEntryPoints();
    if (argc >= 1 && readStringArg(env, argv[0], &text) && imeContextPreviewFn != nullptr) {
        rc = imeContextPreviewFn(text.c_str(), text.size(), ctx);
    }
    napi_value result;
    napi_create_string_utf8(env, rc == 0 ? "0" : "1", NAPI_AUTO_LENGTH, &result);
    return result;
}

// 选区同步（start, end, context）
static napi_value ImeSetSelection(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value argv[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    resolveImeEntryPoints();
    int32_t rc = 1;
    if (imeSetSelectionFn != nullptr && argc >= 2) {
        int64_t ctx = readInt64Arg(env, argc >= 3 ? argv[2] : nullptr);
        rc = imeSetSelectionFn(static_cast<int32_t>(readInt64Arg(env, argv[0])),
                               static_cast<int32_t>(readInt64Arg(env, argv[1])), ctx);
    }
    napi_value result;
    napi_create_string_utf8(env, rc == 0 ? "0" : "1", NAPI_AUTO_LENGTH, &result);
    return result;
}

static napi_value ImeFinishEditing(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value argv[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    resolveImeEntryPoints();
    int32_t rc = 1;
    if (imeContextEndFn != nullptr) {
        rc = imeContextEndFn(readInt64Arg(env, argc >= 1 ? argv[0] : nullptr));
    }
    napi_value result;
    napi_create_string_utf8(env, rc == 0 ? "0" : "1", NAPI_AUTO_LENGTH, &result);
    return result;
}

static napi_value Init(napi_env env, napi_value exports) {
    g_initCalls += 1;
    HLOGI("Init call #%{public}d", g_initCalls);
    napi_value xcompProp = nullptr;
    {
        napi_status rc = napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &xcompProp);
        napi_valuetype t = napi_undefined;
        if (rc == napi_ok && xcompProp != nullptr) {
            napi_typeof(env, xcompProp, &t);
        }
        HLOGI("Init: xcomponent prop rc=%{public}d type=%{public}d", static_cast<int>(rc), static_cast<int>(t));
    }
    napi_property_descriptor descriptors[] = {
        {"probeCangjie", nullptr, ProbeCangjie, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startHost", nullptr, StartHost, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"republishSurface", nullptr, RepublishSurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopHost", nullptr, StopHost, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"appForeground", nullptr, AppForeground, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"appShutdown", nullptr, AppShutdown, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"registerFocusRequest", nullptr, RegisterFocusRequest, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"shutdownState", nullptr, ShutdownState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"hostState", nullptr, HostState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTestGate", nullptr, SetTestGate, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"auditNegativeFixture", nullptr, AuditNegativeFixture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTestGateFailFirst", nullptr, SetTestGateFailFirst, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTestGateFailFirst", nullptr, SetTestGateFailFirst, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"testGateState", nullptr, TestGateState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imeEditingContext", nullptr, ImeEditingContext, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imeCommitText", nullptr, ImeCommitText, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imePreviewText", nullptr, ImePreviewText, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imePreviewRange", nullptr, ImePreviewRange, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imeSetSelection", nullptr, ImeSetSelection, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imeFinishEditing", nullptr, ImeFinishEditing, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);

    // A2：native 引用归还的 UI 线程通道。渲染线程经 ingress.surfaceTornDown
    // 通知后，宿主把归还任务投到这里执行——OH_NativeWindow_NativeObjectUnreference
    // 非线程安全，必须在 UI 线程串行调用。
    // func 传 nullptr + 提供 call_js_cb：不调用 JS 回调，只在 JS 线程执行归还。
    {
        napi_value resourceName = nullptr;
        napi_create_string_utf8(env, "CjguiSurfaceRefRelease", NAPI_AUTO_LENGTH, &resourceName);
        napi_status ts = napi_create_threadsafe_function(env, nullptr, nullptr, resourceName,
                                                        0, 1, nullptr, nullptr, nullptr,
                                                        RefReleaseCall, &g_refReleaseFn);
        HLOGI("ref release threadsafe function: status=%{public}d handle=%{public}s",
              static_cast<int>(ts), g_refReleaseFn != nullptr ? "ready" : "unavailable");
    }
    // 链1：挂起 surface 的补分类通道（同上模式：不调 JS 回调，只在 JS 线程
    // 执行 C++ 分类函数）——surface 先于解析到达时，解析完成后回 UI 线程。
    {
        napi_value resourceName = nullptr;
        napi_create_string_utf8(env, "CjguiSurfaceClassify", NAPI_AUTO_LENGTH, &resourceName);
        napi_status ts = napi_create_threadsafe_function(env, nullptr, nullptr, resourceName,
                                                        0, 1, nullptr, nullptr, nullptr,
                                                        SurfaceClassifyCall, &g_surfaceClassifyFn);
        HLOGI("surface classify threadsafe function: status=%{public}d handle=%{public}s",
              static_cast<int>(ts), g_surfaceClassifyFn != nullptr ? "ready" : "unavailable");
    }
    // 链1：独立启动准备过程（一次性）。库装载+入口解析不再等待 XComponent
    // onLoad→startHost——那是 surface 回调卡死互等的根因。
    {
        bool expected = false;
        if (g_prepareStarted.compare_exchange_strong(expected, true)) {
            g_prepareThread = std::thread(entryPrepareProc);
            g_prepareThread.detach();
            HLOGI("entry preparation thread started");
        }
    }

    napi_value exportedNativeXComponent = nullptr;
    if (napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportedNativeXComponent) == napi_ok &&
        exportedNativeXComponent != nullptr) {
        // 本 SDK 头文件只声明 ArkUI_NodeHandle 变体；系统 libace_ndk.z 同时导出
        // 经典的 (napi_env, napi_value, OH_NativeXComponent**) 变体（ArkTS
        // XComponent + libraryname 装载路径实际注入的对象用它解析）。dlsym 动态取。
        using GetNapiVariantFn = int32_t (*)(napi_env, napi_value, OH_NativeXComponent **);
        static GetNapiVariantFn getNapiVariant =
            reinterpret_cast<GetNapiVariantFn>(dlsym(RTLD_DEFAULT, "OH_NativeXComponent_GetNativeXComponent"));
        OH_NativeXComponent *nativeXComponent = nullptr;
        if (getNapiVariant != nullptr) {
            int32_t rc = getNapiVariant(env, xcompProp, &nativeXComponent);
            HLOGI("napi variant rc=%{public}d component=%{public}p", static_cast<int>(rc),
                  reinterpret_cast<void *>(nativeXComponent));
        } else {
            HLOGW("napi variant symbol missing");
        }
        if (nativeXComponent == nullptr) {
            // 属性可能是 napi_wrap 包装对象：解内部指针。
            void *unwrapped = nullptr;
            if (napi_unwrap(env, xcompProp, &unwrapped) == napi_ok && unwrapped != nullptr) {
                nativeXComponent = static_cast<OH_NativeXComponent *>(unwrapped);
                HLOGI("unwrap path: component=%{public}p", unwrapped);
            }
        }
        if (nativeXComponent != nullptr) {
            OH_NativeXComponent_Callback *callback = &g_xcomponentCallback;
            memset(callback, 0, sizeof(*callback));
            callback->OnSurfaceCreated = onSurfaceCreatedImpl;
            callback->OnSurfaceChanged = onSurfaceChangedImpl;
            callback->OnSurfaceDestroyed = onSurfaceDestroyedImpl;
            callback->DispatchTouchEvent = dispatchTouchImpl;
            OH_NativeXComponent_RegisterCallback(nativeXComponent, callback);
            HLOGI("xcomponent callbacks registered");
        }
    }
    return exports;
}

static napi_module cjguiHostModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterCjguiHostModule(void) {
    napi_module_register(&cjguiHostModule);
}

}  // namespace cjgui_host
