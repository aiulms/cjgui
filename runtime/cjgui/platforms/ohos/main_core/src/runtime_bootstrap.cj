package cjgui

// 内部 runtime bootstrap owner:
// - 本文件承载 runtime readiness aggregate 与 bootstrap snapshot 相关默认
//   internal symbols。
// - 这些 symbols 从 platform_adapter.cj 切出, 避免 platform adapter 长期拥有
//   runtime bootstrap summary owner。
// - 它只组合既有 platform readiness coordination summary。
// - 它不拥有 app lifecycle state truth、window lifecycle state truth 或
//   platform object truth。
// - 它不实现 app run、event loop、queue / drain、window create 或 shutdown。
// - 它不改变 projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

// 内部 runtime readiness aggregate:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 coordination sanity 产出的 app/window state 与 readiness parity Bool。
// - 它不拥有 app lifecycle state truth 或 window lifecycle state truth。
// - 它不改变 projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

struct CjguiInternalRuntimeReadinessAggregate {
    let appState: CjguiInternalAppLifecycleState
    let windowState: CjguiInternalWindowLifecycleState
    let isReadinessParityClean: Bool

    init(
        appState: CjguiInternalAppLifecycleState,
        windowState: CjguiInternalWindowLifecycleState,
        isReadinessParityClean: Bool
    ) {
        this.appState = appState
        this.windowState = windowState
        this.isReadinessParityClean = isReadinessParityClean
    }
}

// 内部 runtime bootstrap snapshot:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 readiness aggregate 与 bootstrap readiness Bool。
// - 它不拥有 app lifecycle state truth 或 window lifecycle state truth。
// - 它不实现 app run、event loop、queue / drain、window create 或 shutdown。
// - 它不改变 projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

struct CjguiInternalRuntimeBootstrapSnapshot {
    let readiness: CjguiInternalRuntimeReadinessAggregate
    let isBootstrapReady: Bool

    init(
        readiness: CjguiInternalRuntimeReadinessAggregate,
        isBootstrapReady: Bool
    ) {
        this.readiness = readiness
        this.isBootstrapReady = isBootstrapReady
    }
}

// 内部 runtime readiness aggregate builder:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只复用既有 coordination sanity 与 readiness parity sanity。
// - 它返回脱水 aggregate summary, 不新增 runtime behavior。
// - 它不改变 projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

func cjguiInternalBuildRuntimeReadinessAggregate(): CjguiInternalRuntimeReadinessAggregate {
    let result = cjguiInternalLifecycleCoordinationSanity()
    let parity = cjguiInternalLifecycleCoordinationReadinessSanityParity()
    return CjguiInternalRuntimeReadinessAggregate(
        result.appState,
        result.windowState,
        parity
    )
}

// 内部 runtime bootstrap snapshot builder:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只复用既有 readiness aggregate builder。
// - 它用 readiness parity Bool 形成 bootstrap readiness marker。
// - 它不实现 app run、event loop、queue / drain、window create 或 shutdown。
// - 它不改变 projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

func cjguiInternalBuildRuntimeBootstrapSnapshot(): CjguiInternalRuntimeBootstrapSnapshot {
    let readiness = cjguiInternalBuildRuntimeReadinessAggregate()
    return CjguiInternalRuntimeBootstrapSnapshot(
        readiness,
        readiness.isReadinessParityClean
    )
}
