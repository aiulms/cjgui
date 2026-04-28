# CJGUI Minimal Runtime Skeleton

日期：2026-04-26

状态：minimal package skeleton / internal lifecycle boundary surface

本目录当前记录的是 `runtime/cjgui` 的默认 internal 运行时骨架。它用于承载未来 app lifecycle、window lifecycle、platform adapter 和 error strategy 的最小边界，不是正式 runtime implementation，不提供稳定 public runtime API，也不提供 public C ABI。

## First Compilable Source Boundary

当前四个 `src/*.cj` 文件都使用同一个 `package cjgui` declaration，并且只承载默认 internal 的最小骨架符号：

- `src/app_lifecycle.cj`
  - `CjguiInternalAppLifecycleState`
  - `CjguiInternalAppLifecycleTransitionMarker`
  - `CjguiInternalAppLifecyclePhaseTaxonomyMarker`
  - `cjguiInternalNoOpAppLifecycleTransition`
  - `cjguiInternalAppLifecyclePhaseMarkerTransition`
- `src/window_lifecycle.cj`
  - `CjguiInternalWindowLifecycleState`
  - `cjguiInternalNoOpWindowLifecycleTransition`
  - `cjguiInternalWindowLifecycleStateMarkerTransition`
- `src/platform_adapter.cj`
  - `CjguiInternalPlatformAdapterFact`
  - `cjguiInternalNoOpPlatformAdapterFactIngestion`
  - `cjguiInternalProjectPlatformFactToAppLifecycleState`
  - `cjguiInternalProjectPlatformFactToWindowLifecycleState`
  - `CjguiInternalLifecycleCoordinationResult`
  - `cjguiInternalCoordinateLifecycleFromPlatformFact`
  - `cjguiInternalLifecycleCoordinationSanity`
- `src/error.cj`
  - `CjguiInternalCompileSanityMarker`
  - `CjguiInternalErrorFact`
  - `CjguiInternalErrorTaxonomyMarker`

当前已落地的最小脱水形状如下：

- app lifecycle state: `isStateMachineActive: Bool`、`hasLifecyclePhase: Bool`
- window lifecycle state: `hasWindowState: Bool`
- platform adapter fact: `hasPlatformFact: Bool`
- error fact: `hasNativePayload: Bool = false`

当前边界如下：

- 所有非 `package cjgui` 声明均保持默认 `internal`。
- 允许最小 `struct`、最小构造初始化、最小 no-op / marker transition 和最小 coordination 函数形状。
- 不提供 public runtime API。
- 不提供 public C ABI。
- 不实现真实 app run / request quit / shutdown / queue / drain。
- 不实现真实 window create / request close / destroy / release。
- 不实现真实 platform adapter / event loop / callback binding。
- 不实现完整 error strategy、error enum、`Result` type 或 exception-like mechanism。
- 不暴露 platform object、native handle、raw pointer 或 platform truth public surface。

## App Lifecycle Owner

未来 app lifecycle owner 属于正式 runtime core 的 app lifecycle 模块。当前 `src/app_lifecycle.cj` 只定义内部 state、transition marker、phase taxonomy marker，以及两个最小 transition 函数。

边界如下：

- app lifecycle 是未来 app-level state、request quit、shutdown、queue acceptance 和 main-thread queue / drain policy 的概念 owner。
- platform adapter 未来可以发送脱水 lifecycle facts 驱动 app lifecycle，但不得把 runloop truth、callback ownership 或 native handle 编码成 core truth。
- `run`、`request quit`、`shutdown`、queue / drain 仍只是 future slot；当前没有真实行为。
- app lifecycle 不默认引入 global tick、blind redraw、Dirty Rect 或 frame scheduler。
- app lifecycle 不打开 Text / Input / IME / Accessibility、semantic tree 或 Action Router。

## Window Lifecycle Owner

未来 window lifecycle owner 属于正式 runtime core 的 window lifecycle 模块。当前 `src/window_lifecycle.cj` 只定义内部 state、最小 no-op transition 和最小 state marker transition。

边界如下：

- window lifecycle 是未来 window-target state、request close、destroyed / stale target classification 的概念 owner。
- app lifecycle 仍是 app-level queue acceptance、shutdown policy 和 main-thread queue / drain policy 的概念 owner。
- platform adapter 仍是平台对象、平台 close event、平台 release 事实和平台 runloop callback 的 owner。
- `create window`、`request close`、`destroy`、`release` 仍只是 future slot；当前不实现。
- request close 未来应经过 app lifecycle queue acceptance 与 platform-adapter main-thread drain 后再推进 window state。
- handle table / generation 现在保持关闭；只有出现 public handle、多窗口、target update、async UI message targeting、destroyed-target identity reuse 或跨线程 target validation 时才应另开边界。
- destroyed window state 必须是 terminal；stale close / stale message 不得复活窗口。

## Platform Adapter / Core Boundary

当前 `src/platform_adapter.cj` 已经承载默认 internal 的 fact shape、最小 no-op ingestion、platform fact 到 app/window lifecycle 的投影、最小 lifecycle coordination 结果与入口，以及默认 internal sanity 调用。它仍不是正式 platform adapter implementation。

边界如下：

- platform adapter 未来负责平台 event loop、platform callback、平台对象生命周期以及 platform readiness / failure 事实。
- core runtime 只应消费脱水 facts，不应消费平台对象、raw event object、runloop truth 或 callback ownership。
- app lifecycle 可在未来消费 adapter 发出的脱水 app facts，例如 readiness、failure、queue drain request、quit request、shutdown observed。
- window lifecycle 可在未来消费 adapter 发出的脱水 window facts，例如 create observed、close requested、visibility summary、destroyed、release completed、stale message。
- `NSRunLoop`、`NSEvent`、`dispatch_main`、AppKit / Metal / CoreGraphics / Objective-C 对象、native handle、raw pointer 只能作为 adapter-internal truth 或 README 中的禁止事项出现。
- platform adapter boundary 不意味着默认 global tick、blind redraw、frame scheduler、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、Action Router、command-list hash、pixel diff、baseline 或 offscreen renderer 已打开。

## Error Strategy Surface Boundary

当前 `src/error.cj` 已经承载默认 internal 的 compile sanity marker、最小 error fact 和 taxonomy marker，但仍不是正式 error strategy implementation。

边界如下：

- error strategy future owner 属于 `runtime/cjgui` error strategy 模块；它只分类 future failure / degraded diagnostics，不拥有 app state、window state 或 platform truth。
- app lifecycle 汇报 app-level outcome，window lifecycle 汇报 window-target outcome，platform adapter 汇报 native capability / failure summary；error strategy 只接收脱水 summary。
- smoke `last_error` 不迁移为正式 runtime error system。
- future runtime error 必须是 call-associated、structured、non-global 且 concurrency-safe。
- 当前不定义 error enum、`Result` type、exception-like mechanism、稳定函数签名或 diagnostics 第二状态真相源。

## Package / Build Metadata Boundary

当前 `cjpm.toml` 只建立 minimal runtime package metadata boundary，不代表 runtime behavior、public runtime API 或 public C ABI 已经存在。

边界如下：

- package owner 候选是 `runtime/cjgui`，不属于 `labs/macos_bridge_smoke`。
- 当前四个 `.cj` source 允许已经落地的默认 internal marker / fact / transition / coordination skeleton。
- 除已封账的 internal skeleton 外，不应顺手新增 public API、public C ABI、真实 runtime behavior、`main` entry、额外 build script 或 smoke 迁移。
- build / check 结果只能作为工具链证据，不能替代 source truth。

## Smoke Guard Relationship

`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 继续作为旧链路 guard。它不是正式 runtime test framework，也不定义本目录的 public API。

## Red-team Guardrails

当前 skeleton 继续遵守：

- 不扩大每轮必读历史文档集。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 不进入 pixel diff / baseline。
- 不保存或输出 hash value。
- 不实现 command-list hash。
- 不定义 Display List / Command Buffer API。
- 不让 core runtime 持有 AppKit runloop truth。
- 不实现 semantic tree / Action Router。
- render hot path 不维护完整 semantic tree。
