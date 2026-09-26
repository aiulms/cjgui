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
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstring>
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
    // 审计指针存根：window 在 fence ACK/归还后被清除；仅受控模拟重建路径
    // （真实 XComponent 仍在、对象确定存活）允许读取，真实运行路径禁止触碰。
    void *auditWindow = nullptr;
    bool tornDown = false;          // 渲染线程已确认拆除该代（SurfaceDestroy + GPU 释放）
    int32_t inFlight = 0;           // 渲染线程当前持有的使用许可数
    uint64_t grantedPermits = 0;
    uint64_t releasedPermits = 0;
    // 退役观察（只读取证）
    int64_t retireRequestedAtMs = 0;
    int64_t refReleasedAtMs = 0;
};

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
    if (dladdr(reinterpret_cast<void *>(&OH_NativeWindow_NativeObjectReference), &info) &&
        info.dli_fname != nullptr) {
        lib = info.dli_fname;
    }
    g_refProviderLib = lib;
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
RefOutcome acquireNativeRef(void *window) {
    RefOutcome o;
    if (window == nullptr) {
        o.failed = true;
        g_refCapability = RefCapability::kRefUnavailable;
        return o;
    }
    o.rc = OH_NativeWindow_NativeObjectReference(window);
    if (g_refCapability == RefCapability::kUndetermined) {
        g_refCapability = classifyRefCall(window, o.rc);
        HLOGI("ref capability decided: %{public}s provider=%{public}s rc=%{public}d",
              g_refCapability == RefCapability::kVerifiedNativeRef ? "VerifiedNativeRef"
              : g_refCapability == RefCapability::kKnownShimNoRef ? "KnownShimNoRef"
                                                                  : "RefUnavailable",
              g_refProviderLib.c_str(), static_cast<int>(o.rc));
    }
    switch (g_refCapability) {
        case RefCapability::kVerifiedNativeRef:
            o.held = (o.rc == 0);
            o.failed = !o.held;
            break;
        case RefCapability::kKnownShimNoRef:
            o.degradedActive = true;
            o.failed = true;   // 语义上「未持有」；绝不记 nativeRefHeld
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
int32_t retireAllSurfacesOfInstance() {
    std::vector<uint64_t> generations;
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
    uint64_t generation;
};

std::mutex g_touchMutex;
std::deque<TouchRecord> g_touchQueue;

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
                         int32_t *outHeight, double *outDensity) {
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
    return 1;
}

int ingressTouchDequeue(uint32_t *outAction, float *outX, float *outY, uint64_t *outGeneration) {
    std::lock_guard<std::mutex> lock(g_touchMutex);
    if (g_touchQueue.empty()) {
        return 0;
    }
    TouchRecord record = g_touchQueue.front();
    g_touchQueue.pop_front();
    {
        std::lock_guard<std::mutex> leaseLock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceByGenerationLocked(g_currentGeneration);
        bool stillCurrent = (rec != nullptr) && rec->active && rec->generation == record.generation;
        if (!stillCurrent) {
            // Controlled drop of a stale-generation input; the caller sees a
            // distinct result and the owner is never touched.
            g_oldGenEventsRejected.fetch_add(1);
            return -1;
        }
    }
    if (outAction) *outAction = record.action;
    if (outX) *outX = record.x;
    if (outY) *outY = record.y;
    if (outGeneration) *outGeneration = record.generation;
    return 1;
}

int ingressForegroundLevel() { return g_foreground.load() ? 1 : 0; }

// 代际复核：渲染器在绘制前与 Flush 后各调用一次。只有「宿主当前
// **仍允许使用**的这一代」返回 1；退役后旧代立即返回 0。
// 注意：这里只回答「是否还允许继续使用」，它**不是**资源安全判据——
// 真正的安全由「宿主持有 native 引用 + 渲染线程持有一份使用许可」共同保证。
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
    if (rec == nullptr || !rec->active || rec->retired ||
        (!rec->nativeRefHeld && !rec->nativeRefUnavailable)) {
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
                rec->auditWindow = rec->window;  // 审计存根（仅受控模拟重建可用）
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
        if (rec->inFlight != 0) {
            // 渲染线程声称已拆除却仍有在途许可：如实记录为未完成，**不归还**。
            HLOGW("torn down gen=%{public}llu but inFlight=%{public}d: reference retained",
                  static_cast<unsigned long long>(generation), rec->inFlight);
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
static int32_t bridgeSimulateSurfaceCreatedImpl(void);

// D 夹具：探针注入触摸（与 XComponent dispatchTouchImpl 进入同一条
// g_touchQueue，带当前代际）。仅供测试链路调用；普通产物无调用者。
static int32_t bridgeInjectTouchImpl(uint32_t action, float x, float y)
{
    uint64_t generation = 0;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &rec : g_surfaces) {
            if (rec.active && !rec.retired) {
                generation = rec.generation;
                break;
            }
        }
    }
    if (generation == 0) {
        return -2;
    }
    std::lock_guard<std::mutex> lock(g_touchMutex);
    if (g_touchQueue.size() >= 256) {
        g_touchQueue.pop_front();
    }
    g_touchQueue.push_back(TouchRecord{action, x, y, generation});
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
    void *win = nullptr;
    int32_t w = 0;
    int32_t h = 0;
    std::string id;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (auto it = g_surfaces.rbegin(); it != g_surfaces.rend(); ++it) {
            if (it->retired) {
                // 受控模拟重建：真实 XComponent 仍在，window（或清除后的审计
                // 存根）确定存活；这是显式测试路径，真实运行路径禁止触碰存根。
                win = it->window != nullptr ? it->window : it->auditWindow;
                w = it->width;
                h = it->height;
                id = it->componentId;
                if (win != nullptr) {
                    break;
                }
            }
        }
    }
    if (win == nullptr) {
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
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        for (SurfaceRecord &old : g_surfaces) {
            if (old.window == win && !old.retired && !old.tornDown) {
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
        rec.nativeRefUnavailable = refDegraded;
        rec.nativeRefFailed = !refHeld;
        rec.active = refHeld || refDegraded;
        rec.retired = !(refHeld || refDegraded);
        g_surfaces.push_back(rec);
        g_currentGeneration = rec.active ? rec.generation : 0;
        HLOGI("simulate surface created gen=%{public}llu %dx%d refs=%{public}lld",
              static_cast<unsigned long long>(rec.generation), w, h,
              static_cast<long long>(g_nativeRefCount.load()));
    }
    return 0;
}

CjguiOhosIngress g_ingress = {
    ingressSurfaceActive,
    ingressTouchDequeue,
    ingressForegroundLevel,
    ingressLeaseValid,
    ingressSurfacePermitAcquire,
    ingressSurfacePermitRelease,
    ingressSurfaceTornDown,
    ingressAppReady,
};

// 把模拟入口挂进 ingress（渲染器 export 经此转回宿主真实逻辑）。
static struct IngressSimulateRegistrar {
    IngressSimulateRegistrar() {
        g_ingress.simulateSurfaceRetired = &bridgeSimulateSurfaceRetiredImpl;
        g_ingress.simulateSurfaceCreated = &bridgeSimulateSurfaceCreatedImpl;
        g_ingress.injectTouch = &bridgeInjectTouchImpl;
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

void onSurfaceCreatedImpl(OH_NativeXComponent *component, void *window) {
    char id[128] = {0};
    uint64_t idSize = sizeof(id);
    OH_NativeXComponent_GetXComponentId(component, id, &idSize);
    id[sizeof(id) - 1] = '\0';
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    // A2 第 ① 步：先在 UI 线程串行取得原生对象引用（非线程安全接口，
    // 只在 UI 回调里成对调用）。引用成功是发布 active 的**前提**。
    // 顺序重要：记录一旦 active，渲染线程就可能立刻用这个 window 去创建
    // surface；若此时引用还没加上，组件销毁会让引用计数归零。
    int32_t refRc = -1;
    bool refHeld = false;
    bool refDegraded = false;
    if (window != nullptr) {
        // 单次 Reference 取证 + 三态判定（不用带副作用的多次调用实验——Sol Q1）。
        // 证据归档：run/ref_abi_probe/ref_contract_analysis.md。
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
    g_surfaceCreatedCount.fetch_add(1);
    uint64_t generation = 0;
    uint64_t componentInstance = 0;
    bool published = false;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        // 同一指针地址可能被系统复用（组件重建）：先把仍在表中、未退役的旧记录
        // 退役，绝不让两代共用一条记录（同地址/同尺寸都不能合并代）。
        for (SurfaceRecord &old : g_surfaces) {
            if (old.window == window && !old.retired && !old.tornDown) {
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
        rec.nativeRefUnavailable = refDegraded;
        rec.nativeRefFailed = !refHeld;
        rec.active = refHeld || refDegraded;
        rec.retired = !(refHeld || refDegraded);
        generation = rec.generation;
        componentInstance = rec.componentInstance;
        published = rec.active;
        g_surfaces.push_back(rec);
        g_currentGeneration = rec.active ? rec.generation : 0;
    }
    HLOGI("surface created id=%{public}s %{public}llux%{public}llu gen=%{public}llu comp=%{public}llu app=%{public}llu nativeref rc=%{public}d published=%{public}d refs=%{public}lld",
          id, static_cast<unsigned long long>(width), static_cast<unsigned long long>(height),
          static_cast<unsigned long long>(generation),
          static_cast<unsigned long long>(componentInstance),
          static_cast<unsigned long long>(g_appInstance),
          static_cast<int>(refRc), published ? 1 : 0,
          static_cast<long long>(g_nativeRefCount.load()));
}

void onSurfaceChangedImpl(OH_NativeXComponent *component, void *window) {
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    uint64_t generation = 0;
    uint64_t geometryRevision = 0;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
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
                    old.retired = true;
                    old.active = false;
                    old.retireRequestedAtMs = nowMs();
                }
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
            nrec.active = refHeld || refDegraded;
            nrec.retired = !(refHeld || refDegraded);
            g_surfaces.push_back(nrec);
            g_currentGeneration = nrec.active ? nrec.generation : 0;
            generation = nrec.generation;
            geometryRevision = nrec.geometryRevision;
            HLOGI("surface changed: window re-registered as new gen=%{public}llu "
                  "%{public}llux%{public}llu (resize recreate path)",
                  static_cast<unsigned long long>(generation),
                  static_cast<unsigned long long>(width),
                  static_cast<unsigned long long>(height));
            return;
        }
        rec->width = static_cast<int32_t>(width);
        rec->height = static_cast<int32_t>(height);
        // 几何变更必须分配**不复用**的 geometryRevision：同尺寸重建也要能被
        // 识别为一次新的几何（旧代用旧版本，渲染线程据此拒绝混用）。
        rec->geometryRevision = g_nextGeometryRevision++;
        generation = rec->generation;
        geometryRevision = rec->geometryRevision;
    }
    HLOGI("surface changed gen=%{public}llu geo=%{public}llu %{public}llux%{public}llu",
          static_cast<unsigned long long>(generation),
          static_cast<unsigned long long>(geometryRevision),
          static_cast<unsigned long long>(width), static_cast<unsigned long long>(height));
}

void onSurfaceDestroyedImpl(OH_NativeXComponent *component, void *window) {
    (void)component;
    uint64_t generation = 0;
    bool needFence = false;
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
            rec->auditWindow = rec->window;   // 审计存根（仅受控模拟重建可用）
            rec->window = nullptr;            // 指针清除：退休记录只留身份/几何/审计
            HLOGI("destroy fence gen=%{public}llu: renderer ACK in callback; window pointer cleared",
                  static_cast<unsigned long long>(generation));
        } else {
            g_destroyFenceTimeouts.fetch_add(1);
            HLOGE("destroy fence gen=%{public}llu TIMEOUT: generation FAILED (renderer not converged "
                  "within %{public}lld ms); not available for reuse",
                  static_cast<unsigned long long>(generation),
                  static_cast<long long>(kDestroyFenceTimeoutMs));
        }
    }
}

void dispatchTouchImpl(OH_NativeXComponent *component, void *window) {
    uint64_t generation = 0;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        SurfaceRecord *rec = findSurfaceLocked(window);
        if (rec == nullptr || !rec->active) {
            return;  // 未知/已退役 surface 的触摸受控丢弃，不触碰 owner
        }
        generation = rec->generation;
    }
    OH_NativeXComponent_TouchEvent touch{};
    OH_NativeXComponent_GetTouchEvent(component, window, &touch);
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
    std::lock_guard<std::mutex> lock(g_touchMutex);
    if (g_touchQueue.size() >= 256) {
        g_touchQueue.pop_front();  // bounded queue: drop oldest
    }
    g_touchQueue.push_back(TouchRecord{action, touch.x, touch.y, generation});
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
// 本进程是否解析到验证接缝（普通产物为 false）。这个值只用于「可否显示测试入口」
// 与取证读数，不能改变任何生产行为。
static bool g_transportVerifyPresent = false;
static TestGateSetHoldFn g_testGateSetHoldFn = nullptr;
static TestGateFailFirstFn g_testGateFailFirstFn = nullptr;
static bool g_testGateFailFirstRequested = false;
static TestGateCountFn g_testGateFlushCountFn = nullptr;
static TestGateCountFn g_testGateFlushHeldCountFn = nullptr;
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
static ImeContextEndFn imeContextEndFn = nullptr;
static ImeContextQueryFn imeContextQueryFn = nullptr;
static ImeSetSelectionFn imeSetSelectionFn = nullptr;
// 通用文字代理上下文：ArkTS 侧聚焦时得到的编辑上下文编号，回调必须原样带回。
static std::atomic<int64_t> g_editingContext{0};

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

static napi_value StartHost(napi_env env, napi_callback_info info) {
    (void)env;
    (void)info;
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
    g_stopRequested.store(false);
    g_ownerReady.store(false);
    g_ownerExited.store(false);
    uint64_t startAppInstance = 0;
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
        // A3：本次启动分配一个**不复用**的 appInstance。surface 身份、停止判据
        // 都挂在它上面；重开后不能继承上一实例的任何身份。
        g_appInstance.store(g_nextAppInstance++);
        startAppInstance = g_appInstance.load();
        g_threadOwnerInstance = startAppInstance;
        g_ownerThreadId = std::thread::id{};
    }
    if (!g_hostPhase.compare_exchange_strong(phase, kHostStarting)) {
        HLOGW("startHost rejected: phase changed concurrently to %{public}s", hostPhaseName(phase));
        return nullptr;
    }
    HLOGI("startHost accepted: phase=starting appInstance=%{public}llu",
          static_cast<unsigned long long>(startAppInstance));
    g_appThread = std::thread([startAppInstance]() {
        {
            std::lock_guard<std::mutex> lock(g_ownerThreadMutex);
            g_ownerThreadId = std::this_thread::get_id();
        }
        HLOGI("owner thread started (appInstance=%{public}llu)",
              static_cast<unsigned long long>(startAppInstance));
        bool loaded = false;
        for (const std::string &candidate : libraryCandidates()) {
            g_cangjieLib = dlopen(candidate.c_str(), RTLD_NOW);
            if (g_cangjieLib != nullptr) {
                HLOGI("cangjie library loaded: %{public}s", candidate.c_str());
                loaded = true;
                break;
            }
            HLOGW("dlopen %{public}s failed: %{public}s", candidate.c_str(), dlerror());
        }
        if (!loaded) {
            // 启动失败必须可重试：进入 failed（可重开），而不是卡在 starting。
            HLOGE("cangjie library not loadable; host phase=failed");
            g_ownerExited.store(true);
            g_hostPhase.store(kHostFailed);
            return;
        }
        // 一次性解析全部跨库入口（含文字代理的 5 个符号）。任何缺失都会
        // 在日志里点名，不再依赖各回调各自的惰性解析。
        resolvePlatformEntryPoints(g_cangjieLib);
        // A3：复位**上一实例遗留**的观察位（就绪/停止完成/停止请求），
        // 使它们不会被新实例误当作自己的事实。
        if (g_resetInstanceObservationsFn != nullptr) {
            g_resetInstanceObservationsFn();
        }
        if (setFocusSinkFn) setFocusSinkFn(FocusRequestSink);
        auto appMain = reinterpret_cast<AppMainFn>(dlsym(g_cangjieLib, "cjgui_ohos_app_main"));
        if (appMain == nullptr) {
            HLOGE("cjgui_ohos_app_main missing: %s", dlerror());
            g_ownerExited.store(true);
            g_hostPhase.store(kHostFailed);
            return;
        }
        HLOGI("calling cjgui_ohos_app_main (appInstance=%{public}llu; entry blocks until owner exits)",
              static_cast<unsigned long long>(startAppInstance));
        int rc = appMain(&g_ingress);
        HLOGI("cjgui_ohos_app_main returned rc=%{public}d (appInstance=%{public}llu): owner really exited",
              rc, static_cast<unsigned long long>(startAppInstance));
        g_ownerExited.store(true);
        int after = g_hostPhase.load();
        if (after == kHostStopping) {
            // 停止路径：由停止监控线程按同一 appInstance 判定收口（判据见下）。
            HLOGI("owner exited during stop; stop monitor owns the settlement");
        } else if (after == kHostStarting) {
            // 启动阶段就退出（surface 60s 未就绪 / host.start 失败 / appMain 失败）：
            // 进 failed，保留可重试性，**不**冒充 running、也不冒充 stopped。
            int expected = kHostStarting;
            if (g_hostPhase.compare_exchange_strong(expected, kHostFailed)) {
                HLOGE("owner exited before becoming ready (rc=%{public}d): host phase=failed", rc);
            }
        } else if (after == kHostRunning) {
            // running 下 owner 未经停止请求自行退出：owner 已不在，但传输收敛、
            // 渲染线程 teardown、surface 引用归还**都未验证**，因此报 failed
            // 而不是 stopped——不能用一个未经核实的终态冒充「已停止」。
            int expected = kHostRunning;
            if (g_hostPhase.compare_exchange_strong(expected, kHostFailed)) {
                HLOGW("owner exited while running without stop request: host phase=failed (settlement unverified)");
            }
        } else {
            HLOGI("owner exited while phase=%{public}s: recorded only", hostPhaseName(after));
        }
    });
    return nullptr;
}

// A3：一次性停止请求。starting/running 都可进入 stopping——「启动中关闭」
// 必须能被接住，否则这次关闭没有归属方，owner 会一直留在 starting。
static void requestHostStopOnce(const char *origin) {
    int phase = g_hostPhase.load();
    if (phase != kHostRunning && phase != kHostStarting) {
        HLOGW("%{public}s ignored: host phase=%{public}s (only starting/running can stop)", origin, hostPhaseName(phase));
        return;
    }
    int expected = phase;
    if (!g_hostPhase.compare_exchange_strong(expected, kHostStopping)) {
        HLOGW("%{public}s ignored: phase raced to %{public}s", origin, hostPhaseName(expected));
        return;
    }
    const uint64_t stopAppInstance = g_appInstance.load();
    g_stopRequested.store(true);
    HLOGI("%{public}s: host phase=stopping appInstance=%{public}llu; requesting application stop",
          origin, static_cast<unsigned long long>(stopAppInstance));
    // 停止接单（surface 侧）：本实例的 surface 立即退役并投递拆除，
    // 使其使用许可与 native 引用走正常路径闭合。这不阻塞 UI 线程。
    int32_t retiredRequests = retireAllSurfacesOfInstance();
    HLOGI("stop: %{public}d surface(s) retired for appInstance=%{public}llu",
          retiredRequests, static_cast<unsigned long long>(stopAppInstance));
    if (requestAppStopFn != nullptr) {
        int32_t epoch = requestAppStopFn();
        HLOGI("application stop requested (renderer epoch=%{public}d)", epoch);
    } else {
        HLOGW("stop symbol missing; owner keeps running (start identity retained)");
    }
    // 收敛监控：只观察与判定，不代替 owner/渲染线程做它们自己的收尾。
    // 判据（对**同一个 appInstance**）：
    //   ① owner 线程真实退出并被 join；
    //   ② 渲染线程 teardown 完成（不是只看一个可能过期的全局值——该值已在
    //      本次启动时复位过，且这里与①②③④同时成立才算数）；
    //   ③ 窗口会话/票据收敛（occupied=0、unacked=0、pending=0）；
    //   ④ 本实例 surface 使用许可与 native 引用全部归还。
    // 传输侧的收敛（listener/连接/队列/票据）由 owner 的关闭链在②之前完成，
    // 并以其自己的 `transport closing: closed=...` 行留证：②成立即说明该链已跑完。
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
        for (int i = 0; i < maxRounds; ++i) {
            if (!ownerJoined) {
                ownerJoined = ownerThreadJoinedForInstance(stopAppInstance);
            }
            rendererDone = (shutdownDoneFn != nullptr) && (shutdownDoneFn() == 1);
            if (g_settlementReadoutFn != nullptr) {
                g_settlementReadoutFn(&occupied, &unacked, &pending);
            }
            refsUnclosed = surfaceAccountingForInstance(stopAppInstance, &activeSurfaces);
            if (ownerJoined && rendererDone && occupied == 0 && unacked == 0 && pending == 0 &&
                refsUnclosed == 0 && activeSurfaces == 0) {
                converged = true;
                break;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        int after = g_hostPhase.load();
        if (converged && after == kHostStopping) {
            int expectedPhase = kHostStopping;
            if (g_hostPhase.compare_exchange_strong(expectedPhase, kHostStopped)) {
                HLOGI("stop settled appInstance=%{public}llu ownerJoined=1 rendererDone=1 sessions=0 unacked=0 pending=0 refsUnclosed=0 activeSurfaces=0 (phase=stopped)",
                      static_cast<unsigned long long>(stopAppInstance));
                return;
            }
            after = expectedPhase;
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
    char buffer[1024];
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
        {"stopHost", nullptr, StopHost, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"appForeground", nullptr, AppForeground, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"appShutdown", nullptr, AppShutdown, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"registerFocusRequest", nullptr, RegisterFocusRequest, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"shutdownState", nullptr, ShutdownState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"hostState", nullptr, HostState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTestGate", nullptr, SetTestGate, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTestGateFailFirst", nullptr, SetTestGateFailFirst, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTestGateFailFirst", nullptr, SetTestGateFailFirst, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"testGateState", nullptr, TestGateState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imeEditingContext", nullptr, ImeEditingContext, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imeCommitText", nullptr, ImeCommitText, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"imePreviewText", nullptr, ImePreviewText, nullptr, nullptr, nullptr, napi_default, nullptr},
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
