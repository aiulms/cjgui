#include "xcomp_bridge.h"

#include <ace/xcomponent/native_interface_xcomponent.h>
#include <hilog/log.h>
#include <napi/native_api.h>

#include <cstring>
#include <mutex>

namespace ohos_gui_smoke {

CardsOwner g_owner;
std::atomic<bool> g_dirty{true};
std::atomic<uint64_t> g_generation{0};

namespace {
constexpr uint32_t LOG_DOMAIN = kLogDomain;
constexpr const char *LOG_TAG = kLogTag;

CardsRenderer g_renderer;
StateServer g_server;

// The surface lease is the only lifecycle authority. Captured state is
// checked against the lease at execution time; Destroyed retires the lease
// so late Frame/Touch callbacks carrying a retired lease are dropped.
struct SurfaceLease {
    uint64_t generation = 0;
    void *window = nullptr;
    bool active = false;
};

std::mutex g_leaseMutex;
SurfaceLease g_lease;
uint64_t g_nextGeneration = 1;

// The callback struct is registered by pointer and must outlive the
// component: static storage, never a stack local.
OH_NativeXComponent_Callback g_xcomponentCallback;

// Touch bookkeeping: a press inside a card selects it and begins a move.
bool g_moving = false;
int g_pressedCard = -1;
float g_pressOffsetX = 0.0f;
float g_pressOffsetY = 0.0f;

CardState g_snapshot[2];

void refreshSnapshot() {
    int64_t version = 0;
    int selected = 0;
    g_owner.snapshot(g_snapshot, &version, &selected);
}

int64_t currentVersion() {
    int64_t version = 0;
    int selected = 0;
    CardState scratch[2];
    g_owner.snapshot(scratch, &version, &selected);
    return version;
}

int hitCard(float x, float y) {
    refreshSnapshot();
    constexpr float kHalfW = 80.0f;
    constexpr float kHalfH = 60.0f;
    for (int i = 0; i < 2; ++i) {
        if (x >= g_snapshot[i].x - kHalfW && x <= g_snapshot[i].x + kHalfW &&
            y >= g_snapshot[i].y - kHalfH && y <= g_snapshot[i].y + kHalfH) {
            return i;
        }
    }
    return -1;
}

bool hitToggleZone(float x, float y, int *cardId) {
    refreshSnapshot();
    for (int i = 0; i < 2; ++i) {
        float zoneLeft = g_snapshot[i].x + 80.0f - 34.0f;
        float zoneTop = g_snapshot[i].y - 60.0f;
        if (x >= zoneLeft && x <= zoneLeft + 28.0f && y >= zoneTop && y <= zoneTop + 28.0f) {
            *cardId = i;
            return true;
        }
    }
    return false;
}

void applyHuman(const std::string &op, int cardId, float x, float y) {
    OperationRequest request;
    request.principal = "HumanTouch";
    request.expectedVersion = currentVersion();
    request.op = op;
    request.cardId = cardId;
    request.x = x;
    request.y = y;
    OperationResult result = g_owner.applyOperation(request);
    if (!result.applied) {
        OH_LOG_Print(LOG_APP, LOG_WARN, LOG_DOMAIN, LOG_TAG, "human op %s rejected: %s",
                     op.c_str(), result.reason.c_str());
    }
    g_dirty.store(true);
}

void onSurfaceCreatedImpl(OH_NativeXComponent *component, void *window) {
    char id[128] = {0};
    uint64_t idSize = sizeof(id);
    OH_NativeXComponent_GetXComponentId(component, id, &idSize);
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        g_lease.generation = g_nextGeneration++;
        g_lease.window = window;
        g_lease.active = true;
        g_generation.store(g_lease.generation);
    }
    // Initial layout happens exactly once; a recreated surface redraws the
    // existing business snapshot instead of resetting it.
    const bool firstLayout = g_owner.ensureInitialLayout(static_cast<float>(width),
                                                         static_cast<float>(height));
    if (!g_renderer.surfaceCreated(window, reinterpret_cast<uint64_t>(window),
                                   static_cast<int>(width), static_cast<int>(height))) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, "surface init failed for %s", id);
        return;
    }
    g_dirty.store(true);
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG,
                 "surface created id=%s %llux%llu gen=%llu firstLayout=%d", id,
                 static_cast<unsigned long long>(width), static_cast<unsigned long long>(height),
                 static_cast<unsigned long long>(g_lease.generation), firstLayout ? 1 : 0);
}

void onSurfaceChangedImpl(OH_NativeXComponent *component, void *window) {
    (void)component;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (!g_lease.active || g_lease.window != window) return;  // stale surface
    }
    uint64_t width = 0;
    uint64_t height = 0;
    OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
    g_renderer.surfaceChanged(static_cast<int>(width), static_cast<int>(height));
    g_dirty.store(true);
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, "surface changed %llux%llu",
                 static_cast<unsigned long long>(width), static_cast<unsigned long long>(height));
}

void onSurfaceDestroyedImpl(OH_NativeXComponent *component, void *window) {
    (void)component;
    uint64_t generation = 0;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (g_lease.active && g_lease.window == window) {
            generation = g_lease.generation;
            g_lease.active = false;  // retire first: later touches/frames drop
        }
    }
    g_renderer.surfaceDestroyed();
    g_moving = false;
    g_pressedCard = -1;
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, "surface destroyed gen=%llu",
                 static_cast<unsigned long long>(generation));
}

void dispatchTouchImpl(OH_NativeXComponent *component, void *window) {
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (!g_lease.active || g_lease.window != window) return;  // stale surface
    }
    OH_NativeXComponent_TouchEvent touch{};
    OH_NativeXComponent_GetTouchEvent(component, window, &touch);
    float x = touch.touchX;
    float y = touch.touchY;
    if (touch.type == OH_NATIVEXCOMPONENT_DOWN) {
        int toggleCard = -1;
        if (hitToggleZone(x, y, &toggleCard)) {
            applyHuman("TOGGLE", toggleCard + 1, 0.0f, 0.0f);
            g_pressedCard = -1;
            g_moving = false;
            return;
        }
        int card = hitCard(x, y);
        if (card >= 0) {
            applyHuman("SELECT", card + 1, 0.0f, 0.0f);
            refreshSnapshot();
            g_pressedCard = card;
            g_pressOffsetX = g_snapshot[card].x - x;
            g_pressOffsetY = g_snapshot[card].y - y;
            g_moving = true;
        } else {
            g_pressedCard = -1;
            g_moving = false;
        }
    } else if (touch.type == OH_NATIVEXCOMPONENT_MOVE && g_moving && g_pressedCard >= 0) {
        applyHuman("MOVE", g_pressedCard + 1, x + g_pressOffsetX, y + g_pressOffsetY);
    } else if (touch.type == OH_NATIVEXCOMPONENT_UP) {
        g_moving = false;
        g_pressedCard = -1;
    }
}

}  // namespace

namespace ohos_gui_smoke {
void onSurfaceCreatedCb(OH_NativeXComponent *component, void *window) { onSurfaceCreatedImpl(component, window); }
void onSurfaceChangedCb(OH_NativeXComponent *component, void *window) { onSurfaceChangedImpl(component, window); }
void onSurfaceDestroyedCb(OH_NativeXComponent *component, void *window) { onSurfaceDestroyedImpl(component, window); }
void dispatchTouchCb(OH_NativeXComponent *component, void *window) { dispatchTouchImpl(component, window); }
}  // namespace ohos_gui_smoke

bool pumpFrame() {
    void *window = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        if (!g_lease.active) return false;
        window = g_lease.window;
    }
    return g_renderer.drawIfDirty(g_owner, reinterpret_cast<uint64_t>(window));
}

void shutdownNative() {
    {
        std::lock_guard<std::mutex> lock(g_leaseMutex);
        g_lease.active = false;
    }
    g_renderer.surfaceDestroyed();
    g_server.stop();
    CardsRenderer::teardownDisplay();
}

}  // namespace ohos_gui_smoke

#include "napi/native_api.h"

static napi_value PumpFrame(napi_env env, napi_callback_info info) {
    (void)info;
    bool drew = ohos_gui_smoke::pumpFrame();
    napi_value result;
    napi_get_boolean(env, drew, &result);
    return result;
}

static napi_value Shutdown(napi_env env, napi_callback_info info) {
    (void)env;
    (void)info;
    ohos_gui_smoke::shutdownNative();
    return nullptr;
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor descriptors[] = {
        {"pumpFrame", nullptr, PumpFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"shutdown", nullptr, Shutdown, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);

    napi_value exportedNativeXComponent = nullptr;
    if (napi_get_named_property(env, exports, NATIVE_XCOMPONENT_OBJ, &exportedNativeXComponent) == napi_ok &&
        exportedNativeXComponent != nullptr) {
        OH_NativeXComponent *nativeXComponent = nullptr;
        if (OH_NativeXComponent_GetNativeXComponent(exportedNativeXComponent, &nativeXComponent) == napi_ok &&
            nativeXComponent != nullptr) {
            // Static storage: the component keeps this callback pointer past
            // Init, so the struct must never be a stack local.
            OH_NativeXComponent_Callback *callback = &ohos_gui_smoke::g_xcomponentCallback;
            memset(callback, 0, sizeof(*callback));
            callback->OnSurfaceCreated = ohos_gui_smoke::onSurfaceCreatedCb;
            callback->OnSurfaceChanged = ohos_gui_smoke::onSurfaceChangedCb;
            callback->OnSurfaceDestroyed = ohos_gui_smoke::onSurfaceDestroyedCb;
            callback->DispatchTouchEvent = ohos_gui_smoke::dispatchTouchCb;
            OH_NativeXComponent_RegisterCallback(nativeXComponent, callback);
            ohos_gui_smoke::g_server.start(&ohos_gui_smoke::g_owner, &ohos_gui_smoke::g_dirty, 7856);
            OH_LOG_Print(LOG_APP, LOG_INFO, ohos_gui_smoke::kLogDomain, ohos_gui_smoke::kLogTag,
                         "cross-drag native module ready");
        }
    }
    return exports;
}

static napi_module crossDragModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterCrossDragModule(void) {
    napi_module_register(&crossDragModule);
}
