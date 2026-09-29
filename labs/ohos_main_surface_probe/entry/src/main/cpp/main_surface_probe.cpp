/*
 * 主窗口 Surface 探针（独立实验，不参与生产后端）。
 *
 * 目的：验证普通 normal HAP 在不创建 XComponent 的前提下，能否取得本应用
 * 主窗口的可提交 Surface / NativeWindow，并直接向缓冲区提交画面。
 *
 * 分层：
 *   L0 身份 + SDK 公开接口（windowId→属性、surfaceId→NativeWindow、主窗口触摸/按键过滤）
 *   L1 dlopen / dlsym 系统内部库（libwm.z.so / librender_service_client.z.so）
 *   L2 候选入口拿到 Window*，vtable 定位 GetSurfaceNode，再 GetSurface
 *   L3 公开 NDK 把 Surface* 包成 OHNativeWindow，RequestBuffer/FlushBuffer 提交帧
 *   L4（可选）对 RSSurfaceNode 开硬件合成开关后再提交
 *
 * 每一步先写日志再执行：进程若在该步崩溃，日志里最后一条就是它的上一步。
 *
 * 分类标注：
 *   PUBLIC  = SDK 公开 NDK 头文件中的接口
 *   PRIVATE = 设备系统库导出、SDK 未提供头文件的内部 ABI
 *   INFER   = 依赖 ABI 布局 / 虚表槽位的推断调用
 */
#include <napi/native_api.h>
#include <hilog/log.h>
#include <native_window/external_window.h>
#include <window_manager/oh_window.h>
#include <window_manager/oh_window_comm.h>
#include <window_manager/oh_window_event_filter.h>
#include <multimodalinput/oh_input_manager.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <cstdio>
#include <cstdarg>
#include <cstring>
#include <cstdlib>
#include <cerrno>
#include <string>
#include <mutex>

#define PROBE_DOMAIN 0x1234
#define PROBE_TAG "MainSurfaceProbe"

#define PLOG(fmt, ...) OH_LOG_Print(LOG_APP, LOG_INFO, PROBE_DOMAIN, PROBE_TAG, fmt, ##__VA_ARGS__)

namespace {

std::mutex g_mutex;
std::string g_report;

// 记录一行：既进内存报告，也立刻落 hilog。崩溃前最后一条即最后完成的步骤。
void Rec(const std::string &line)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    g_report += line;
    g_report += "\n";
    PLOG("%{public}s", line.c_str());
}

void Recf(const char *fmt, ...)
{
    char buf[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    Rec(std::string(buf));
}

std::string TakeReport()
{
    std::lock_guard<std::mutex> lock(g_mutex);
    return g_report;
}

// ---- 运行时状态 -------------------------------------------------------
// ABI 关键点（实测，见报告「ABI 纠正」一节）：
//   sptr<T> / std::shared_ptr<T> 都有非平凡析构函数，按 Itanium C++ ABI 属于
//   "non-trivial for the purposes of calls"，**返回值经 x8 隐藏指针（sret）返回**，
//   而不是放在 x0。反汇编 Window::GetWindowWithId / RSSurfaceNode::GetSurface 的
//   序言均可看到 `mov x19, x8`。
//   因此这里用带非平凡析构的 16 字节载体承接返回值（同时容纳 8/16 字节两种布局；
//   载体析构不做任何事 → 最坏只是多持一个引用，不会提前释放）。
struct Sret16 {
    void *a;
    void *b;
    ~Sret16() {}
};

typedef Sret16 (*FnU32)(uint32_t);
typedef Sret16 (*FnThis)(const void *);

struct ProbeState {
    int32_t windowId = -1;
    int32_t winW = 0;
    int32_t winH = 0;

    void *libWm = nullptr;
    void *libRsClient = nullptr;

    FnU32 fnWindowGetWindowWithId = nullptr;            // Window::GetWindowWithId
    FnU32 fnWindowImplGetWindowWithId = nullptr;        // WindowImpl::GetWindowWithId
    FnU32 fnWindowSessionGetWindowWithId = nullptr;     // WindowSessionImpl::GetWindowWithId
    FnU32 fnSceneSessionGetMainWindowWithId = nullptr;  // WindowSceneSessionImpl::GetMainWindowWithId
    void *symWindowImplGetSurfaceNode = nullptr;
    void *symWindowSessionImplGetSurfaceNode = nullptr;
    void *symRsSurfaceNodeGetSurface = nullptr;
    void *symSetContainerWindow = nullptr;
    void *symSetHardwareEnabled = nullptr;

    void *winHandle = nullptr;
    void *surfaceNode = nullptr;
    void *surface = nullptr;

    OHNativeWindow *nativeWindow = nullptr;
    uint64_t nativeWindowSurfaceId = 0;

    int32_t touchFilterRc = INT32_MIN;
    int32_t keyFilterRc = INT32_MIN;
    int32_t touchEventsSeen = 0;
    int32_t keyEventsSeen = 0;
    int32_t lastRequestRc = INT32_MIN;
    int32_t lastFlushRc = INT32_MIN;
    int32_t framesFlushed = 0;
};

ProbeState g_state;

napi_value MakeString(napi_env env, const std::string &s)
{
    napi_value v = nullptr;
    napi_create_string_utf8(env, s.c_str(), s.size(), &v);
    return v;
}

napi_value MakeInt(napi_env env, int64_t i)
{
    napi_value v = nullptr;
    napi_create_int64(env, i, &v);
    return v;
}

// ---- /proc/self/maps --------------------------------------------------
bool ReadFileToString(const char *path, std::string &out)
{
    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        return false;
    }
    char buf[4096];
    ssize_t n = 0;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        out.append(buf, static_cast<size_t>(n));
    }
    close(fd);
    return true;
}

std::string MapsFindPath(const std::string &maps, const char *soname)
{
    size_t pos = 0;
    while (pos < maps.size()) {
        size_t eol = maps.find('\n', pos);
        if (eol == std::string::npos) {
            eol = maps.size();
        }
        std::string line = maps.substr(pos, eol - pos);
        size_t slash = line.find('/');
        if (slash != std::string::npos) {
            std::string path = line.substr(slash);
            size_t sp = path.find(' ');
            if (sp != std::string::npos) {
                path = path.substr(0, sp);
            }
            size_t need = strlen(soname);
            if (path.size() >= need && path.compare(path.size() - need, need, soname) == 0) {
                return path;
            }
        }
        pos = eol + 1;
    }
    return std::string();
}

// ---- L0：身份与公开接口 -------------------------------------------------
bool g_touchFilterRegistered = false;
bool g_keyFilterRegistered = false;

bool TouchFilterCb(Input_TouchEvent *ev)
{
    if (ev == nullptr) {
        return false;
    }
    int32_t action = OH_Input_GetTouchEventAction(ev);
    int32_t finger = OH_Input_GetTouchEventFingerId(ev);
    int32_t x = OH_Input_GetTouchEventDisplayX(ev);
    int32_t y = OH_Input_GetTouchEventDisplayY(ev);
    int32_t wid = OH_Input_GetTouchEventWindowId(ev);
    int64_t t = OH_Input_GetTouchEventActionTime(ev);
    g_state.touchEventsSeen += 1;
    Recf("TOUCH PUBLIC filter#%d action=%d finger=%d xy=%d,%d windowId=%d time=%lld",
         static_cast<int>(g_state.touchEventsSeen), static_cast<int>(action), static_cast<int>(finger),
         static_cast<int>(x), static_cast<int>(y), static_cast<int>(wid), static_cast<long long>(t));
    return false;  // 放行，不改变 ArkUI 行为
}

bool KeyFilterCb(Input_KeyEvent *ev)
{
    if (ev == nullptr) {
        return false;
    }
    int32_t code = OH_Input_GetKeyEventKeyCode(ev);
    int32_t action = OH_Input_GetKeyEventAction(ev);
    g_state.keyEventsSeen += 1;
    Recf("KEY PUBLIC filter#%d keyCode=%d action=%d", static_cast<int>(g_state.keyEventsSeen),
         static_cast<int>(code), static_cast<int>(action));
    return false;
}

void ProbeIdentity()
{
    Recf("L0 identity pid=%d uid=%d tid=%d", static_cast<int>(getpid()), static_cast<int>(getuid()),
         static_cast<int>(gettid()));
}

void ProbePublicWindowProperties()
{
    if (g_state.windowId < 0) {
        Rec("L0 PUBLIC OH_WindowManager_GetWindowProperties skip: windowId 未由 ArkTS 传入");
        return;
    }
    WindowManager_WindowProperties props;
    memset(&props, 0, sizeof(props));
    int32_t rc = OH_WindowManager_GetWindowProperties(g_state.windowId, &props);
    Recf("L0 PUBLIC OH_WindowManager_GetWindowProperties(windowId=%d) rc=%d",
         static_cast<int>(g_state.windowId), static_cast<int>(rc));
    if (rc == 0) {
        Recf("L0 PUBLIC props id=%u displayId=%u rect=%d,%d %dx%d drawable=%d,%d %dx%d fullscreen=%d",
             props.id, props.displayId,
             props.windowRect.posX, props.windowRect.posY,
             props.windowRect.width, props.windowRect.height,
             props.drawableRect.posX, props.drawableRect.posY,
             props.drawableRect.width, props.drawableRect.height,
             static_cast<int>(props.isFullScreen));
    }
    Recf("L0 PUBLIC WindowManager_WindowProperties sizeof=%d 字段: windowRect/drawableRect/isFullScreen/"
         "isLayoutFullScreen/focusable/touchable/brightness/isKeepScreenOn/isPrivacyMode/isTransparent/"
         "id/displayId —— 无 surface/surfaceId",
         static_cast<int>(sizeof(WindowManager_WindowProperties)));
}

void ProbePublicSurfaceIdApi()
{
    OHNativeWindow *probeWin = nullptr;
    int32_t rc = OH_NativeWindow_CreateNativeWindowFromSurfaceId(0, &probeWin);
    Recf("L0 PUBLIC OH_NativeWindow_CreateNativeWindowFromSurfaceId(0) rc=%d win=%p",
         static_cast<int>(rc), probeWin);
    if (probeWin != nullptr) {
        OH_NativeWindow_DestroyNativeWindow(probeWin);
    }
    Rec("L0 PUBLIC 说明: SDK 公开头文件（@ohos.window.d.ts 与 window_manager/oh_window.h）中不存在"
        "任何返回主窗口 surface/surfaceId 的接口；surfaceId 的公开来源只有 XComponent");
}

void ProbeRegisterInputFilters()
{
    if (g_state.windowId < 0) {
        Rec("L0 PUBLIC 输入过滤注册 skip: windowId 未由 ArkTS 传入");
        return;
    }
    WindowManager_ErrorCode rcT =
        OH_NativeWindowManager_RegisterTouchEventFilter(g_state.windowId, TouchFilterCb);
    g_state.touchFilterRc = static_cast<int32_t>(rcT);
    g_touchFilterRegistered = (rcT == WindowManager_ErrorCode::OK);
    Recf("L0 PUBLIC OH_NativeWindowManager_RegisterTouchEventFilter(windowId=%d) rc=%d(%s)",
         static_cast<int>(g_state.windowId), static_cast<int>(rcT), g_touchFilterRegistered ? "OK" : "not-ok");

    WindowManager_ErrorCode rcK = OH_NativeWindowManager_RegisterKeyEventFilter(g_state.windowId, KeyFilterCb);
    g_state.keyFilterRc = static_cast<int32_t>(rcK);
    g_keyFilterRegistered = (rcK == WindowManager_ErrorCode::OK);
    Recf("L0 PUBLIC OH_NativeWindowManager_RegisterKeyEventFilter(windowId=%d) rc=%d(%s)",
         static_cast<int>(g_state.windowId), static_cast<int>(rcK), g_keyFilterRegistered ? "OK" : "not-ok");

    // Get*EventFilter 声明为 @since 26.0.0，本机镜像(api=24)不导出；直接链接会让
    // libentry.so 重定位失败，因此改为运行时 dlsym 可选探测。
    void *libWinMgr = dlopen("libnative_window_manager.so", RTLD_NOW);
    if (libWinMgr == nullptr) {
        Rec("L0 PUBLIC GetTouchEventFilter 探测 skip: dlopen 失败");
        return;
    }
    typedef WindowManager_ErrorCode (*GetTouchFilterFn)(int32_t, OH_NativeWindowManager_TouchEventFilter *);
    auto getTouch = reinterpret_cast<GetTouchFilterFn>(
        dlsym(libWinMgr, "OH_NativeWindowManager_GetTouchEventFilter"));
    if (getTouch == nullptr) {
        Rec("L0 PUBLIC OH_NativeWindowManager_GetTouchEventFilter 在本镜像不存在（@since 26.0.0，"
            "镜像 api=24）→ 版本边界");
        return;
    }
    OH_NativeWindowManager_TouchEventFilter outTouch = nullptr;
    WindowManager_ErrorCode rcGT = getTouch(g_state.windowId, &outTouch);
    Recf("L0 PUBLIC GetTouchEventFilter rc=%d cb=%p expect=%p match=%d", static_cast<int>(rcGT),
         reinterpret_cast<void *>(outTouch), reinterpret_cast<void *>(&TouchFilterCb),
         outTouch == &TouchFilterCb ? 1 : 0);
}

// ---- L1：私有库装载 -----------------------------------------------------
void *TryDlopen(const char *soname, const std::string &absPath, const char *label)
{
    dlerror();
    void *h = dlopen(soname, RTLD_NOW | RTLD_GLOBAL);
    const char *err = dlerror();
    if (h != nullptr) {
        Recf("L1 PRIVATE dlopen(\"%s\") OK handle=%p (%s)", soname, h, label);
        return h;
    }
    Recf("L1 PRIVATE dlopen(\"%s\") FAIL err=%s (%s)", soname, err != nullptr ? err : "(null)", label);
    if (!absPath.empty()) {
        dlerror();
        void *h2 = dlopen(absPath.c_str(), RTLD_NOW | RTLD_GLOBAL);
        const char *err2 = dlerror();
        if (h2 != nullptr) {
            Recf("L1 PRIVATE dlopen(\"%s\") OK handle=%p", absPath.c_str(), h2);
            return h2;
        }
        Recf("L1 PRIVATE dlopen(\"%s\") FAIL err=%s", absPath.c_str(), err2 != nullptr ? err2 : "(null)");
    }
    return nullptr;
}

void *TryDlsym(void *handle, const char *mangled, const char *label)
{
    if (handle == nullptr) {
        Recf("L1 PRIVATE dlsym %s skip: 库句柄为空", label);
        return nullptr;
    }
    dlerror();
    void *sym = dlsym(handle, mangled);
    const char *err = dlerror();
    if (sym != nullptr) {
        Recf("L1 PRIVATE dlsym OK %s -> %p", label, sym);
    } else {
        Recf("L1 PRIVATE dlsym FAIL %s err=%s", label, err != nullptr ? err : "(null)");
    }
    return sym;
}

void ProbeLibraryLoading()
{
    std::string maps;
    if (!ReadFileToString("/proc/self/maps", maps)) {
        Rec("L1 maps 读取失败");
        return;
    }
    const char *interesting[] = {
        "libwm.z.so", "librender_service_client.z.so", "libsurface", "libnative_window",
        "libace_compatible.z.so", "libark_jsruntime.so", "libohinput.so", "libmmi-client.z.so",
        "libipc_single.z.so", "libimage_source", "libdrawing"
    };
    for (const char *name : interesting) {
        if (maps.find(name) != std::string::npos) {
            Recf("L1 maps 已加载: %s -> %s", name, MapsFindPath(maps, name).c_str());
        } else {
            Recf("L1 maps 未加载: %s", name);
        }
    }

    g_state.libWm = TryDlopen("libwm.z.so", MapsFindPath(maps, "libwm.z.so"), "window manager innerkit");
    g_state.libRsClient = TryDlopen("librender_service_client.z.so",
                                    MapsFindPath(maps, "librender_service_client.z.so"), "render service client");

    g_state.fnWindowGetWindowWithId = reinterpret_cast<FnU32>(
        TryDlsym(g_state.libWm, "_ZN4OHOS5Rosen6Window15GetWindowWithIdEj", "Window::GetWindowWithId"));
    g_state.fnWindowImplGetWindowWithId = reinterpret_cast<FnU32>(
        TryDlsym(g_state.libWm, "_ZN4OHOS5Rosen10WindowImpl15GetWindowWithIdEj", "WindowImpl::GetWindowWithId"));
    g_state.fnWindowSessionGetWindowWithId = reinterpret_cast<FnU32>(
        TryDlsym(g_state.libWm, "_ZN4OHOS5Rosen17WindowSessionImpl15GetWindowWithIdEj",
                 "WindowSessionImpl::GetWindowWithId"));
    g_state.fnSceneSessionGetMainWindowWithId = reinterpret_cast<FnU32>(
        TryDlsym(g_state.libWm, "_ZN4OHOS5Rosen22WindowSceneSessionImpl19GetMainWindowWithIdEj",
                 "WindowSceneSessionImpl::GetMainWindowWithId"));
    g_state.symWindowImplGetSurfaceNode =
        TryDlsym(g_state.libWm, "_ZNK4OHOS5Rosen10WindowImpl14GetSurfaceNodeEv", "WindowImpl::GetSurfaceNode()");
    g_state.symWindowSessionImplGetSurfaceNode =
        TryDlsym(g_state.libWm, "_ZNK4OHOS5Rosen17WindowSessionImpl14GetSurfaceNodeEv",
                 "WindowSessionImpl::GetSurfaceNode()");
    g_state.symRsSurfaceNodeGetSurface =
        TryDlsym(g_state.libRsClient, "_ZNK4OHOS5Rosen13RSSurfaceNode10GetSurfaceEv", "RSSurfaceNode::GetSurface()");
    g_state.symSetContainerWindow =
        TryDlsym(g_state.libRsClient, "_ZN4OHOS5Rosen13RSSurfaceNode18SetContainerWindowEbNS0_6RRectTIfEE",
                 "RSSurfaceNode::SetContainerWindow(bool,RRectT<float>)");
    g_state.symSetHardwareEnabled = TryDlsym(
        g_state.libRsClient,
        "_ZN4OHOS5Rosen13RSSurfaceNode18SetHardwareEnabledEbNS0_19SelfDrawingNodeTypeEb",
        "RSSurfaceNode::SetHardwareEnabled(bool,SelfDrawingNodeType,bool)");
}

// ---- L2：候选入口 → Window* → RSSurfaceNode -----------------------------
struct Candidate {
    int id;
    const char *label;
    FnU32 fn;
};

const Candidate *FindCandidate(int id)
{
    static const Candidate kCandidates[] = {
        {1, "Window::GetWindowWithId", g_state.fnWindowGetWindowWithId},
        {2, "WindowSessionImpl::GetWindowWithId", g_state.fnWindowSessionGetWindowWithId},
        {3, "WindowSceneSessionImpl::GetMainWindowWithId", g_state.fnSceneSessionGetMainWindowWithId},
        {4, "WindowImpl::GetWindowWithId", g_state.fnWindowImplGetWindowWithId},
    };
    for (const Candidate &c : kCandidates) {
        if (c.id == id) {
            return &c;
        }
    }
    return nullptr;
}

// 返回 true 表示拿到了 RSSurfaceNode。
bool ProbeAcquireWindow(int candidateId)
{
    const Candidate *cand = FindCandidate(candidateId);
    if (cand == nullptr) {
        Recf("L2 未知候选 %d", candidateId);
        return false;
    }
    if (cand->fn == nullptr) {
        Recf("L2 PRIVATE 跳过候选 %s: 符号未解析", cand->label);
        return false;
    }
    if (g_state.windowId < 0) {
        Rec("L2 跳过: windowId 未由 ArkTS 传入");
        return false;
    }
    // INFER: sptr<Window> 单指针返回，按 x0 取回对象；不调用 sptr 析构只多持引用（安全方向）。
    Recf("L2 INFER [候选%d] 调用 %s(%d) …", cand->id, cand->label, static_cast<int>(g_state.windowId));
    Sret16 ret{nullptr, nullptr};
    ret = cand->fn(static_cast<uint32_t>(g_state.windowId));
    void *win = ret.a;
    Recf("L2 INFER [候选%d] 返回 Window* = %p (sret slot2=%p)", cand->id, win, ret.b);
    if (win == nullptr) {
        return false;
    }
    g_state.winHandle = win;

    // vtable 扫描：不猜槽位号，直接找等于已知 GetSurfaceNode 符号地址的槽。
    void **vtbl = *reinterpret_cast<void ***>(win);
    Recf("L2 PRIVATE vtable=%p", reinterpret_cast<void *>(vtbl));
    int foundSlot = -1;
    const char *foundKind = "none";
    for (int i = 0; i < 512; ++i) {
        void *slot = vtbl[i];
        if (slot == g_state.symWindowImplGetSurfaceNode) {
            foundSlot = i;
            foundKind = "WindowImpl::GetSurfaceNode";
            break;
        }
        if (slot == g_state.symWindowSessionImplGetSurfaceNode) {
            foundSlot = i;
            foundKind = "WindowSessionImpl::GetSurfaceNode";
            break;
        }
    }
    if (foundSlot < 0) {
        Rec("L2 PRIVATE vtable 前 512 槽内未找到 GetSurfaceNode（可能非虚或不在该 vtable）");
        return false;
    }
    Recf("L2 INFER vtable[%d] == %s", foundSlot, foundKind);

    // INFER: shared_ptr<RSSurfaceNode> 返回，x0 即对象指针；不析构 shared_ptr 只泄漏引用。
    FnThis gsn = reinterpret_cast<FnThis>(vtbl[foundSlot]);
    Sret16 nodeRet{nullptr, nullptr};
    nodeRet = gsn(win);
    void *node = nodeRet.a;
    Recf("L2 INFER GetSurfaceNode() -> RSSurfaceNode* = %p (sret slot2=%p)", node, nodeRet.b);
    g_state.surfaceNode = node;
    return node != nullptr;
}

// ---- 附：窗口底色（透明前提）能否完全走公开 NDK ----------------------------
// ArkTS 侧用的是 window.setWindowBackgroundColor('#00000000')；本实验发现
// 「窗口底色必须透明，自绘 buffer 才可见」是硬前提，因此这里核 NDK 是否有等价公开入口。
void ProbeSetWindowBackgroundTransparent()
{
    if (g_state.windowId < 0) {
        Rec("BGND 跳过: windowId 未由 ArkTS 传入");
        return;
    }
    int32_t rc = OH_WindowManager_SetWindowBackgroundColor(g_state.windowId, "#00000000");
    Recf("BGND PUBLIC OH_WindowManager_SetWindowBackgroundColor(windowId=%d, \"#00000000\") rc=%d",
         static_cast<int>(g_state.windowId), static_cast<int>(rc));
}

// ---- 附：不靠 ArkTS 传 windowId，能否自己找到本进程的主窗口 ------------------
// 只对私有入口 WindowSessionImpl::GetWindowWithId(id) 做有界扫描；每个 id 先记日志再调用，
// 若某个 id 触发崩溃，日志里最后一条即它。找到的窗口再走一遍 vtable → GetSurfaceNode。
void ProbeEnumerateWindows(int32_t knownId)
{
    if (g_state.fnWindowSessionGetWindowWithId == nullptr) {
        Rec("ENUM 跳过: WindowSessionImpl::GetWindowWithId 未解析");
        return;
    }
    Recf("ENUM 有界扫描 WindowSessionImpl::GetWindowWithId(id)（已知 ArkTS 给出的 id=%d）",
         static_cast<int>(knownId));
    int found = 0;
    static const int ranges[2][2] = {{1, 16}, {60, 140}};
    for (const auto &r : ranges) {
        for (int id = r[0]; id <= r[1]; ++id) {
            Sret16 ret{nullptr, nullptr};
            ret = g_state.fnWindowSessionGetWindowWithId(static_cast<uint32_t>(id));
            if (ret.a != nullptr) {
                found += 1;
                Recf("ENUM 命中 id=%d Window*=%p%s", id, ret.a, id == knownId ? "  <= 与 ArkTS 给出的相同" : "");
                if (id == knownId) {
                    void **vtbl = *reinterpret_cast<void ***>(ret.a);
                    int slot = -1;
                    for (int i = 0; i < 512; ++i) {
                        if (vtbl[i] == g_state.symWindowSessionImplGetSurfaceNode ||
                            vtbl[i] == g_state.symWindowImplGetSurfaceNode) {
                            slot = i;
                            break;
                        }
                    }
                    if (slot >= 0 && g_state.symRsSurfaceNodeGetSurface != nullptr) {
                        FnThis gsn = reinterpret_cast<FnThis>(vtbl[slot]);
                        Sret16 nodeRet{nullptr, nullptr};
                        nodeRet = gsn(ret.a);
                        Recf("ENUM 该窗口 GetSurfaceNode() -> %p（与 L2 结果比对）", nodeRet.a);
                    }
                }
            }
        }
    }
    Recf("ENUM 扫描结束: 命中 %d 个窗口", found);
}

// ---- L3：Surface* 与公开 OHNativeWindow ---------------------------------
bool ProbeWrapSurface()
{
    if (g_state.surfaceNode == nullptr) {
        Rec("L3 跳过: 无 RSSurfaceNode");
        return false;
    }
    if (g_state.symRsSurfaceNodeGetSurface == nullptr) {
        Rec("L3 跳过: RSSurfaceNode::GetSurface 未解析");
        return false;
    }
    // INFER: sptr<Surface*>/shared_ptr<Surface> 两种布局下 x0 都是对象指针。
    FnThis gs = reinterpret_cast<FnThis>(g_state.symRsSurfaceNodeGetSurface);
    Sret16 surfRet{nullptr, nullptr};
    surfRet = gs(g_state.surfaceNode);
    void *surf = surfRet.a;
    Recf("L3 INFER RSSurfaceNode::GetSurface() -> Surface* = %p (sret slot2=%p)", surf, surfRet.b);
    g_state.surface = surf;
    if (surf == nullptr) {
        Rec("L3 PRIVATE 结论: 主窗口 RSSurfaceNode 没有应用侧 producer Surface");
        return false;
    }
    // 关键：SDK 头文件写明 `@param pSurface Indicates the pointer to a ProduceSurface.
    // The type is a pointer to sptr<OHOS::Surface>` —— 也就是要传「指向 sptr 的指针」，
    // 不是裸 Surface*。实测直接传裸指针会在 CreateNativeWindowFromSurface → RefBase::IncStrongRef
    // 处 SIGSEGV(SEGV_ACCERR)（cppcrash …162920337）。这里传 &surfRet.a：
    // sptr<Surface> 的布局就是单个 Surface*，槽位地址即合法 sptr<Surface>*。
    Recf("L3 PUBLIC 传参修正: CreateNativeWindow(&sptr)（不是裸 Surface*），sptr 槽=%p",
         static_cast<void *>(&surfRet.a));
    OHNativeWindow *nw = OH_NativeWindow_CreateNativeWindow(static_cast<void *>(&surfRet.a));
    Recf("L3 PUBLIC OH_NativeWindow_CreateNativeWindow(&sptr) -> %p", nw);
    g_state.nativeWindow = nw;
    if (nw == nullptr) {
        return false;
    }
    uint64_t sid = 0;
    int32_t rc = OH_NativeWindow_GetSurfaceId(nw, &sid);
    Recf("L3 PUBLIC OH_NativeWindow_GetSurfaceId rc=%d surfaceId=%llu", static_cast<int>(rc),
         static_cast<unsigned long long>(sid));
    g_state.nativeWindowSurfaceId = sid;

    if (rc == 0 && sid != 0) {
        OHNativeWindow *nw2 = nullptr;
        int32_t rc2 = OH_NativeWindow_CreateNativeWindowFromSurfaceId(sid, &nw2);
        Recf("L3 PUBLIC OH_NativeWindow_CreateNativeWindowFromSurfaceId(%llu) rc=%d win=%p",
             static_cast<unsigned long long>(sid), static_cast<int>(rc2), nw2);
        if (nw2 != nullptr) {
            OH_NativeWindow_DestroyNativeWindow(nw2);
        }
    }
    int32_t w = 0;
    int32_t h = 0;
    OH_NativeWindow_NativeWindowHandleOpt(nw, GET_BUFFER_GEOMETRY, &h, &w);
    Recf("L3 PUBLIC buffer geometry = %dx%d (窗口 %dx%d)", static_cast<int>(w), static_cast<int>(h),
         static_cast<int>(g_state.winW), static_cast<int>(g_state.winH));
    return true;
}

// ---- L4：让 RS 把该 surface 当自绘层合成（可选，激进） --------------------
struct RRectF {
    float left;
    float top;
    float width;
    float height;
};

bool ProbeEnableHardwareCompose()
{
    if (g_state.surfaceNode == nullptr) {
        Rec("L4 跳过: 无 RSSurfaceNode");
        return false;
    }
    if (g_state.symSetContainerWindow != nullptr) {
        typedef void (*SetContainerFn)(const void *, bool, RRectF);
        SetContainerFn fn = reinterpret_cast<SetContainerFn>(g_state.symSetContainerWindow);
        RRectF rect{0.0f, 0.0f, static_cast<float>(g_state.winW), static_cast<float>(g_state.winH)};
        Recf("L4 INFER RSSurfaceNode::SetContainerWindow(true, %.0fx%.0f) …", rect.width, rect.height);
        fn(g_state.surfaceNode, true, rect);
        Rec("L4 INFER SetContainerWindow 返回");
    }
    if (g_state.symSetHardwareEnabled != nullptr) {
        // SelfDrawingNodeType: 1=自绘 2=视频；2 让 RS 直接合成 producer buffer。
        typedef void (*SetHwFn)(const void *, bool, int32_t, bool);
        SetHwFn fn = reinterpret_cast<SetHwFn>(g_state.symSetHardwareEnabled);
        Rec("L4 INFER RSSurfaceNode::SetHardwareEnabled(true, 2, false) …");
        fn(g_state.surfaceNode, true, 2, false);
        Rec("L4 INFER SetHardwareEnabled 返回");
        return true;
    }
    return false;
}

// ---- 提交帧 -------------------------------------------------------------
int32_t SubmitOneFrame(uint32_t rgb, int pattern)
{
    if (g_state.nativeWindow == nullptr) {
        Recf("SUBMIT 跳过 pattern=%d: 无 OHNativeWindow", pattern);
        return -1000;
    }
    OHNativeWindow *nw = g_state.nativeWindow;
    // 不要用缓存的窗口尺寸去 SET_BUFFER_GEOMETRY：旋转后缓存会过期，把 buffer 强行
    // 拉回旧尺寸（实测横屏 2856x1320 的窗口里 RequestBuffer 仍返回 1320x2856，
    // 画面只覆盖左上角一块）。以 surface 自己的 geometry 为准，只做只读核对。
    int32_t curW = 0;
    int32_t curH = 0;
    OH_NativeWindow_NativeWindowHandleOpt(nw, GET_BUFFER_GEOMETRY, &curH, &curW);
    if (curW != g_state.winW || curH != g_state.winH) {
        Recf("SUBMIT surface geometry=%dx%d 与缓存的窗口尺寸 %dx%d 不一致（窗口已变化，"
             "按 surface 为准）", static_cast<int>(curW), static_cast<int>(curH),
             static_cast<int>(g_state.winW), static_cast<int>(g_state.winH));
    }
    OH_NativeWindow_NativeWindowHandleOpt(nw, SET_FORMAT, static_cast<int32_t>(NATIVEBUFFER_PIXEL_FMT_RGBA_8888));
    uint64_t usage = 0;
    OH_NativeWindow_NativeWindowHandleOpt(nw, GET_USAGE, &usage);
    Recf("SUBMIT surface usage=0x%llx", static_cast<unsigned long long>(usage));

    OHNativeWindowBuffer *buf = nullptr;
    int releaseFence = -1;
    int32_t rc = OH_NativeWindow_NativeWindowRequestBuffer(nw, &buf, &releaseFence);
    g_state.lastRequestRc = rc;
    if (rc != 0 || buf == nullptr) {
        Recf("SUBMIT RequestBuffer rc=%d buf=%p", static_cast<int>(rc), buf);
        return rc == 0 ? -1 : rc;
    }
    BufferHandle *handle = OH_NativeWindow_GetBufferHandleFromNative(buf);
    if (handle == nullptr) {
        Rec("SUBMIT GetBufferHandleFromNative 返回空");
        OH_NativeWindow_NativeWindowAbortBuffer(nw, buf);
        return -2;
    }
    Recf("SUBMIT handle %dx%d stride=%d fmt=%d size=%d fd=%d", handle->width, handle->height, handle->stride,
         handle->format, handle->size, handle->fd);
    if (handle->size <= 0 || handle->fd < 0) {
        Recf("SUBMIT handle 不可映射 size=%d fd=%d", handle->size, handle->fd);
        OH_NativeWindow_NativeWindowAbortBuffer(nw, buf);
        return -3;
    }
    // BufferHandle::virAddr 只是 mmap 的地址提示；本 surface 上它为 0（非预映射），
    // 以 nullptr 为提示让内核选地址，用 fd 建立映射才是正确做法。
    void *hint = nullptr;
    if (handle->virAddr != nullptr &&
        (reinterpret_cast<uintptr_t>(handle->virAddr) & 0xFFF) == 0) {
        hint = handle->virAddr;
    }
    void *addr = mmap(hint, static_cast<size_t>(handle->size), PROT_READ | PROT_WRITE, MAP_SHARED,
                      handle->fd, 0);
    if (addr == MAP_FAILED) {
        Recf("SUBMIT mmap 失败 errno=%d (virAddr=%p size=%d fd=%d)", errno, handle->virAddr,
             handle->size, handle->fd);
        OH_NativeWindow_NativeWindowAbortBuffer(nw, buf);
        return -4;
    }
    Recf("SUBMIT mmap OK addr=%p size=%d", addr, handle->size);
    uint8_t r = static_cast<uint8_t>((rgb >> 16) & 0xFF);
    uint8_t g = static_cast<uint8_t>((rgb >> 8) & 0xFF);
    uint8_t b = static_cast<uint8_t>(rgb & 0xFF);
    uint8_t *base = static_cast<uint8_t *>(addr);
    for (int32_t y = 0; y < handle->height; ++y) {
        uint8_t *row = base + static_cast<size_t>(y) * static_cast<size_t>(handle->stride);
        for (int32_t x = 0; x < handle->width; ++x) {
            uint32_t cr = r;
            uint32_t cg = g;
            uint32_t cb = b;
            if (pattern == 1) {
                if (((x / 32) + (y / 32)) & 1) {  // 32px 橙白棋盘
                    cr = 255;
                    cg = 255;
                    cb = 255;
                }
            } else if (pattern == 2) {  // 16px 青/黑竖条
                if (((x / 16) & 1) == 0) {
                    cr = 16;
                    cg = 16;
                    cb = 16;
                }
            }
            uint8_t *px = row + static_cast<size_t>(x) * 4u;
            px[0] = static_cast<uint8_t>(cr);
            px[1] = static_cast<uint8_t>(cg);
            px[2] = static_cast<uint8_t>(cb);
            px[3] = 0xFF;
        }
    }
    munmap(addr, static_cast<size_t>(handle->size));

    Region region;
    region.rects = nullptr;
    region.rectNumber = 0;
    int32_t rcFlush = OH_NativeWindow_NativeWindowFlushBuffer(nw, buf, -1, region);
    g_state.lastFlushRc = rcFlush;
    if (rcFlush == 0) {
        g_state.framesFlushed += 1;
    }
    Recf("SUBMIT FlushBuffer pattern=%d rgb=0x%06x rc=%d frames=%d", pattern, rgb,
         static_cast<int>(rcFlush), static_cast<int>(g_state.framesFlushed));
    return rcFlush;
}

// ---- NAPI 导出 ----------------------------------------------------------
napi_value NapiSetWindow(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value argv[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    int32_t id = -1;
    int32_t w = 0;
    int32_t h = 0;
    if (argc > 0) { napi_get_value_int32(env, argv[0], &id); }
    if (argc > 1) { napi_get_value_int32(env, argv[1], &w); }
    if (argc > 2) { napi_get_value_int32(env, argv[2], &h); }
    g_state.windowId = id;
    g_state.winW = w;
    g_state.winH = h;
    Recf("NAPI setWindow windowId=%d size=%dx%d", static_cast<int>(id), static_cast<int>(w),
         static_cast<int>(h));
    return MakeInt(env, 0);
}

// level 位掩码: 1=私有库 2=取窗口与Surface 8=硬件合成开关 4=提交两帧（0 只跑公开层）
// candidate: 1=Window 2=WindowSessionImpl 3=WindowSceneSessionImpl 4=WindowImpl
napi_value NapiProbeRun(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value argv[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    int32_t level = 0;
    int32_t candidate = 2;
    if (argc > 0) { napi_get_value_int32(env, argv[0], &level); }
    if (argc > 1) { napi_get_value_int32(env, argv[1], &candidate); }
    Recf("=== probeRun level=%d candidate=%d ===", static_cast<int>(level), static_cast<int>(candidate));

    // level 是位掩码（顺序固定）：1=装载私有库, 2=取窗口与 Surface, 8=硬件合成开关, 4=提交两帧
    ProbeIdentity();
    ProbePublicWindowProperties();
    ProbePublicSurfaceIdApi();
    ProbeRegisterInputFilters();
    if ((level & 32) != 0) {
        // 放到最前：窗口底色是「自绘 buffer 能否被看到」的前提，必须早于任何 Flush。
        ProbeSetWindowBackgroundTransparent();
    }
    if ((level & 1) != 0) {
        ProbeLibraryLoading();
    }
    if ((level & 2) != 0) {
        if (ProbeAcquireWindow(candidate)) {
            ProbeWrapSurface();
        }
    }
    if ((level & 8) != 0) {
        ProbeEnableHardwareCompose();
    }
    if ((level & 16) != 0) {
        ProbeEnumerateWindows(g_state.windowId);
    }
    if ((level & 4) != 0) {
        SubmitOneFrame(0x1E6BFF, 0);   // 帧A 纯蓝
        SubmitOneFrame(0xFF8A00, 1);   // 帧B 橙白棋盘
    }
    Recf("=== probeRun end level=%d ===", static_cast<int>(level));
    return MakeString(env, TakeReport());
}

napi_value NapiSubmitFrame(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value argv[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    uint32_t rgb = 0x3366FF;
    int32_t pattern = 0;
    if (argc > 0) { napi_get_value_uint32(env, argv[0], &rgb); }
    if (argc > 1) { napi_get_value_int32(env, argv[1], &pattern); }
    return MakeInt(env, SubmitOneFrame(rgb, static_cast<int>(pattern)));
}

napi_value NapiMaps(napi_env env, napi_callback_info info)
{
    (void)info;
    std::string maps;
    if (!ReadFileToString("/proc/self/maps", maps)) {
        return MakeString(env, "maps 读取失败\n");
    }
    std::string filtered;
    size_t pos = 0;
    const char *keys[] = {"window", "surface", "ace", "ark", "rosen", "render", "input", "mmi",
                          "entry", "drawing", "chipset"};
    while (pos < maps.size()) {
        size_t eol = maps.find('\n', pos);
        if (eol == std::string::npos) {
            eol = maps.size();
        }
        std::string line = maps.substr(pos, eol - pos);
        for (const char *k : keys) {
            if (line.find(k) != std::string::npos) {
                filtered += line;
                filtered += "\n";
                break;
            }
        }
        pos = eol + 1;
    }
    return MakeString(env, filtered);
}

napi_value NapiStatus(napi_env env, napi_callback_info info)
{
    (void)info;
    char buf[640];
    snprintf(buf, sizeof(buf),
             "windowId=%d window=%p node=%p surface=%p nativeWindow=%p surfaceId=%llu "
             "reqRc=%d flushRc=%d frames=%d touchFilterRc=%d keyFilterRc=%d touchEvents=%d keyEvents=%d",
             static_cast<int>(g_state.windowId), g_state.winHandle, g_state.surfaceNode, g_state.surface,
             g_state.nativeWindow, static_cast<unsigned long long>(g_state.nativeWindowSurfaceId),
             static_cast<int>(g_state.lastRequestRc), static_cast<int>(g_state.lastFlushRc),
             static_cast<int>(g_state.framesFlushed), static_cast<int>(g_state.touchFilterRc),
             static_cast<int>(g_state.keyFilterRc), static_cast<int>(g_state.touchEventsSeen),
             static_cast<int>(g_state.keyEventsSeen));
    return MakeString(env, std::string(buf));
}

napi_value NapiDestroyWindow(napi_env env, napi_callback_info info)
{
    (void)info;
    int32_t rc = -1;
    if (g_state.nativeWindow != nullptr) {
        OH_NativeWindow_DestroyNativeWindow(g_state.nativeWindow);
        g_state.nativeWindow = nullptr;
        rc = 0;
    }
    Recf("NAPI destroyNativeWindow rc=%d", static_cast<int>(rc));
    return MakeInt(env, rc);
}

napi_value NapiUnregisterFilters(napi_env env, napi_callback_info info)
{
    (void)info;
    int32_t rcT = -1;
    int32_t rcK = -1;
    if (g_touchFilterRegistered) {
        rcT = static_cast<int32_t>(OH_NativeWindowManager_UnregisterTouchEventFilter(g_state.windowId));
        g_touchFilterRegistered = false;
    }
    if (g_keyFilterRegistered) {
        rcK = static_cast<int32_t>(OH_NativeWindowManager_UnregisterKeyEventFilter(g_state.windowId));
        g_keyFilterRegistered = false;
    }
    Recf("NAPI unregisterFilters touchRc=%d keyRc=%d", static_cast<int>(rcT), static_cast<int>(rcK));
    return MakeInt(env, rcT);
}

napi_value NapiClearReport(napi_env env, napi_callback_info info)
{
    (void)info;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_report.clear();
    }
    return MakeInt(env, 0);
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"setWindow", nullptr, NapiSetWindow, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"probeRun", nullptr, NapiProbeRun, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"submitFrame", nullptr, NapiSubmitFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"maps", nullptr, NapiMaps, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"status", nullptr, NapiStatus, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"destroyNativeWindow", nullptr, NapiDestroyWindow, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"unregisterFilters", nullptr, NapiUnregisterFilters, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearReport", nullptr, NapiClearReport, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    PLOG("main surface probe module loaded pid=%{public}d", static_cast<int>(getpid()));
    return exports;
}

}  // namespace

static napi_module g_probeModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterProbeModule(void)
{
    napi_module_register(&g_probeModule);
}
