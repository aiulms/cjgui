package cjgui

// P1 minimal app/window lifecycle runtime skeleton.
// 日期: 2026-04-26
//
// 本文件当前只承载 package declaration, 文档边界与默认 internal fact sanity symbols.
// 它不是 platform adapter implementation.
// 它不是 public runtime API.
// 它不是 public C ABI.
// 它不绑定 AppKit、Metal、CoreGraphics、Objective-C callbacks 或任何 native framework.
// 它不迁移 smoke code, 也不复用 smoke C ABI.
// 它不向 core 暴露 platform objects、native handles、raw pointers 或 platform ownership。
//
// 平台适配 owner (Platform adapter owner):
// - 未来 owner 属于 runtime/cjgui platform adapter 模块。
// - adapter 只在自身边界内拥有 platform event loop facts、callback facts、
//   platform readiness、platform failure 与 platform object lifetime。
// - adapter 未来可以在内部持有 AppKit / Metal / Objective-C objects, 但这些对象
//   绝不能成为 core runtime truth 或 public surface。
//
// 与 app lifecycle 的关系:
// - app lifecycle 在相关 surface 经单独执行卡批准后, 拥有 app-level state、quit policy
//   与概念上的 main-thread queue / drain contract。
// - platform adapter 未来可以发送脱水 app facts 驱动 app lifecycle, 例如
//   platform ready、platform failed、queue drain requested、quit requested 与
//   shutdown observed。
// - platform adapter 不得强迫 core app lifecycle 把 NSRunLoop、NSEvent、
//   dispatch_main、Objective-C delegate 或 callback ownership 编码成 core facts。
//
// 与 window lifecycle 的关系:
// - window lifecycle 在相关 surface 获批后, 拥有脱水 window state 与 classification。
// - platform adapter 未来可以发送 window create observed、close requested、
//   visible / hidden、destroyed、release completed、stale target observed 或
//   platform-window failure 等 facts。
// - platform adapter 不得向 core 发送 native window objects、native view objects、
//   Metal layer objects、drawables、command queues、image handles 或
//   Objective-C object identity。
//
// 平台对象 ownership 保持 adapter-internal:
// - AppKit / Metal / CoreGraphics / Objective-C object ownership 只属于 adapter 内部。
// - core modules 未来只能在相关策略存在后接收 opaque dehydrated booleans、enums、
//   来自 runtime-owned tables 的 ids, 以及 structured summaries。
// - core modules 不得拥有 platform pointers、retain / release platform objects、
//   也不得依赖 platform callback identity。
//
// 允许发送给 core 的脱水 facts:
// - lifecycle facts: platform ready、platform failed、app quit requested、
//   app shutdown observed。
// - queue facts: main-thread drain requested、drain completed、stale drain ignored。
// - window facts: create requested / observed、close requested、closing、destroyed、
//   release completed、stale window message、visibility summary、display / scale
//   summary。
// - future input facts: 只在 Text / Input / IME 边界打开后发送脱水 input summaries。
// - future frame facts: 只在 render scheduling 边界打开后发送 invalidation / redraw
//   summaries。
//
// 禁止发送给 core 的 facts:
// - platform object pointers 或 native handles。
// - AppKit / Metal / CoreGraphics object ownership。
// - raw platform event objects。
// - NSRunLoop、NSEvent、dispatch_main 或 Objective-C callback truth。
// - callback ownership、delegate identity、runloop mode 或 native thread-affinity
//   details as API。
// - smoke C ABI names、smoke global state 或 smoke last_error semantics。
//
// 主线程 ownership 边界:
// - macOS UI work 必须由 platform adapter / platform bridge 保持 main-thread owned。
// - core app lifecycle 未来可以在概念上拥有 queue / drain policy, 但 core 只能看到
//   脱水 queue facts, 不能直接操作 platform runloop。
// - background 或 async UI requests 未来必须作为 queued intent 进入 core, 并且只能
//   通过获批 bridge boundary 回到 platform adapter 执行 main-thread work。
//
// 与 smoke bridge 的关系:
// - labs/macos_bridge_smoke 仍然只是 smoke / lab evidence, 不是 runtime source。
// - smoke bridge 的经验可以用于约束: main-thread ownership、controlled lifecycle、
//   platform object hiding 与 narrow diagnostics。
// - smoke directory layout、smoke build scripts、smoke C ABI shape、single-instance
//   globals、auto-close behavior、clear-color render path、screenshot / frame hash diagnostics 与
//   global last_error semantics 不迁移到本模块。
//
// Error boundary / last_error 不迁移:
// - smoke last_error 是有用 evidence, 但不得成为未来 runtime error system。
// - future adapter errors 必须是 call-associated、structured、non-global、
//   concurrency-safe, 并且可与 app lifecycle / window lifecycle failures 分离。
// - platform adapter 可以报告脱水 readiness / failure summaries, 但不得把 native
//   error objects 或 platform callback state 泄漏到 core public surface。
//
// core 中不保存 platform runloop truth:
// - NSRunLoop、NSEvent、dispatch_main、AppKit delegate truth、
//   Objective-C callback truth 与 native runloop modes 只是 adapter-internal 实现细节。
// - core runtime 不得把这些词建模为 owner、field、stable API、public enum 或 behavior。
//
// 不提供默认 frame scheduler / global tick:
// - platform adapter boundary 不意味着默认 global tick、blind redraw、frame scheduler、
//   Dirty Rect system、Display List、Command Buffer API、command-list hash、pixel diff、
//   baseline、offscreen renderer、Renderer、Scene、Widget、Layout、Text、Input、IME、
//   Accessibility、semantic tree 或 Action Router。
// - future frame / redraw facts 如被批准, 必须是 invalidation-driven 且单独划界。
//
// 当前 stop-line:
// - 不实现 platform adapter。
// - 不绑定 event loop。
// - 不绑定 callback。
// - 不创建 package / build config。
// - 不提供 public runtime API 或 public C ABI。
// - 不迁移 smoke。
// - 不暴露 platform object。

struct CjguiInternalPlatformAdapterFact {
    let hasPlatformFact: Bool

    init() {
        this.hasPlatformFact = false
    }

    init(hasPlatformFact: Bool) {
        this.hasPlatformFact = hasPlatformFact
    }
}

func cjguiInternalNoOpPlatformAdapterFactIngestion(
    fact: CjguiInternalPlatformAdapterFact
): CjguiInternalPlatformAdapterFact {
    return fact
}

// 内部 platform fact -> lifecycle marker projection 函数:
// - 仅消费脱水 Bool fact。
// - 它们只推进已有 app/window internal marker state。
// - 它们不绑定平台对象、callback、event loop、public runtime API 或 public C ABI。

func cjguiInternalProjectPlatformFactToAppLifecycleState(
    fact: CjguiInternalPlatformAdapterFact,
    state: CjguiInternalAppLifecycleState
): CjguiInternalAppLifecycleState {
    if (fact.hasPlatformFact) {
        return CjguiInternalAppLifecycleState(state.isStateMachineActive, true)
    }
    return state
}

func cjguiInternalProjectPlatformFactToWindowLifecycleState(
    fact: CjguiInternalPlatformAdapterFact,
    state: CjguiInternalWindowLifecycleState
): CjguiInternalWindowLifecycleState {
    if (fact.hasPlatformFact) {
        return CjguiInternalWindowLifecycleState(true)
    }
    return state
}

struct CjguiInternalLifecycleCoordinationResult {
    let appState: CjguiInternalAppLifecycleState
    let windowState: CjguiInternalWindowLifecycleState

    init(
        appState: CjguiInternalAppLifecycleState,
        windowState: CjguiInternalWindowLifecycleState
    ) {
        this.appState = appState
        this.windowState = windowState
    }
}

// 内部 lifecycle coordination 入口:
// - 只组合已有 platform fact -> app/window marker projection。
// - 不创建 event loop、queue / drain、platform object、public runtime API 或 public C
//   ABI。

func cjguiInternalCoordinateLifecycleFromPlatformFact(
    fact: CjguiInternalPlatformAdapterFact,
    appState: CjguiInternalAppLifecycleState,
    windowState: CjguiInternalWindowLifecycleState
): CjguiInternalLifecycleCoordinationResult {
    return CjguiInternalLifecycleCoordinationResult(
        cjguiInternalProjectPlatformFactToAppLifecycleState(fact, appState),
        cjguiInternalProjectPlatformFactToWindowLifecycleState(fact, windowState)
    )
}

// 内部 lifecycle coordination sanity 函数:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只构造最小 internal platform fact 与默认 app/window state。
// - 它只调用既有 coordination 入口, 不新增 behavior、owner、public runtime API
//   或 public C ABI。

func cjguiInternalLifecycleCoordinationSanity(): CjguiInternalLifecycleCoordinationResult {
    return cjguiInternalCoordinateLifecycleFromPlatformFact(
        CjguiInternalPlatformAdapterFact(true),
        CjguiInternalAppLifecycleState(),
        CjguiInternalWindowLifecycleState()
    )
}
