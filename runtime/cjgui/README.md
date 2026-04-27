# CJGUI Minimal Runtime Skeleton

日期：2026-04-26

状态：minimal package skeleton / app lifecycle state shape surface

本目录只记录未来 app/window lifecycle runtime first slice 的最小 owner 边界。它不是正式 runtime implementation，不提供稳定 public API，也不迁移 smoke 代码。

## First Compilable Source Boundary

当前四个 `src/*.cj` 文件都包含同一个 `package cjgui` declaration。`src/app_lifecycle.cj` 包含一个默认 internal 的 app lifecycle state marker / placeholder type，并只包含一个不可变脱水 Bool 字段 `isStateMachineActive: Bool = false`，用来表达 app lifecycle state boundary exists but lifecycle state machine is not yet defined。`src/error.cj` 额外包含一个默认 internal 的 compile sanity marker，用来验证 runtime package 可以承载非 public symbol；并包含一个默认 internal 的 first internal error fact type。该 type 当前只有一个不可变脱水 Bool 字段，用来验证 runtime package 可以承载第一枚有最小 shape、但仍无行为的 internal domain type。`src/error.cj` 还包含一个默认 internal 的 taxonomy marker / placeholder type，用来表达 taxonomy boundary exists but taxonomy is not yet defined。

边界如下：

- `strict_comment_only=false`，因为 `.cj` 文件已经具有 package declaration。
- `package_declaration_only=false`，因为 `src/error.cj` 已包含 internal marker / type declarations。
- `internal_symbol_only=true`，当前非 package declaration symbols 均为默认 internal：`CjguiInternalCompileSanityMarker`、`CjguiInternalErrorFact` 与 `CjguiInternalErrorTaxonomyMarker`。
- `app_lifecycle_state_marker_added=true`，`CjguiInternalAppLifecycleState` 只标记 future app lifecycle state boundary exists but lifecycle state machine is not yet defined。
- `app_lifecycle_state_shape_refined=true`，`CjguiInternalAppLifecycleState` 只新增 `isStateMachineActive: Bool = false`，表示当前 state machine 不处于 active 状态。
- `first_internal_error_fact_type_present=true`，`CjguiInternalErrorFact` 只标记 future internal error facts boundary。
- `error_fact_shape_refined=true`，`CjguiInternalErrorFact` 只新增 `hasNativePayload: Bool = false`，表示当前 error fact 不携带 native payload。
- `taxonomy_marker_added=true`，`CjguiInternalErrorTaxonomyMarker` 只标记 future taxonomy boundary exists but taxonomy is not yet defined。
- `taxonomy_defined=false`，当前不定义完整 taxonomy、error enum、`Result` type、severity / category / code 字段或 exception-like mechanism。
- `behavior_code_present=false`，没有 app/window/platform/error runtime behavior。
- `public_api_present=false`，没有 public runtime API 或 public C ABI。
- `public_c_abi_present=false`，没有 public C ABI。
- `function_present=false`，没有函数。
- `method_present=false`，没有方法。
- `explicit_init_present=false`，没有显式 init 或构造逻辑。
- `import_present=false`，没有 import。
- 当前不定义 stable signature、package anchor、`main` entry 或 runtime dependency。

`CjguiInternalCompileSanityMarker` 只是 internal compile sanity marker，不是 error enum、Result type、lifecycle type、handle type、public API 或 runtime behavior。仓颉 struct 文档说明没有自定义构造函数且实例成员满足条件时编译器可能生成无参构造能力；本项目不把该 marker 或任何编译器生成能力解释为 public runtime API。后续若要保留、移动或替换该 marker，必须另开 first internal type boundary。

`CjguiInternalErrorFact` 是默认 internal 的最小 error facts boundary type。它不是 error strategy implementation、error enum、Result type、exception-like mechanism、public runtime API、public C ABI、handle type、platform object wrapper 或 runtime behavior。它当前只包含 `hasNativePayload: Bool = false` 这一枚不可变、脱水、无平台对象字段；该字段不定义 error taxonomy、message ownership、source module、correlation id、lifetime、threading、serialization 或 privacy。它没有函数、方法、显式 init、import 或平台 / smoke / FFI 引用。

`CjguiInternalErrorTaxonomyMarker` 是默认 internal 的 taxonomy marker / placeholder type。它只表达 taxonomy boundary exists but taxonomy is not yet defined。它不是完整 taxonomy、error enum、Result type、exception-like mechanism、public runtime API、public C ABI、diagnostics truth system 或 smoke `last_error` migration。它没有字段、函数、方法、显式 init、import、platform object、raw pointer、native payload、severity / category / code 或 runtime behavior。

`CjguiInternalAppLifecycleState` 是默认 internal 的 app lifecycle state marker / placeholder type。它只表达 app lifecycle state boundary exists but lifecycle state machine is not yet defined。它当前只包含 `isStateMachineActive: Bool = false` 这一枚不可变、脱水、无平台对象字段；该字段不定义 state machine、run / shutdown / request quit / queue / drain behavior、platform callback binding、window lifecycle behavior、error strategy behavior、public runtime API 或 public C ABI。它没有其他字段、函数、方法、显式 init、import 或 runtime behavior。

本 section 只记录 internal symbol sanity，不实现 runtime。

## App Lifecycle Owner

未来 app lifecycle owner 属于正式 runtime core 的 app lifecycle module。它未来需要冻结：

- init。
- run。
- request quit。
- shutdown。
- main-thread queue / drain。

当前文件只记录 future slots，不实现 event loop，也不调用 AppKit / smoke C ABI。

### App Lifecycle Surface Boundary

当前 app lifecycle surface 仍是 comment-only / documentation-level 占位，不是 public runtime API。

边界如下：

- app lifecycle 是 future app-level lifecycle state 和 main-thread queue / drain policy 的概念 owner。
- platform adapter 是 platform event loop、callback、runloop 和 main-thread execution fact 的 owner。
- core app lifecycle 只应消费脱水 lifecycle facts、queue drain request、quit request、platform readiness / failure summary。
- `run` / `shutdown` / `request quit` / `drain main-thread queue` 仍只是 future slot；当前不定义函数签名，不实现行为，不创建 build / package entry。
- core 不得把 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth 当成 API、字段、实现或长期 runtime truth；这些词只能作为禁止事项出现。
- app lifecycle 不拥有 window target identity；stale target、destroyed window、future handle table / generation 属于 window lifecycle / future handle boundary。
- app lifecycle 不引入 default global tick、blind redraw、Dirty Rect、frame scheduler 或 render loop。
- app lifecycle 不暗中打开 Text / Input / IME / Accessibility，也不进入 semantic tree / Action Router。

本 section 只补清边界，不实现 runtime。

## Window Lifecycle Owner

未来 window lifecycle owner 属于正式 runtime core 的 window lifecycle module。它未来需要冻结：

- create window。
- request close。
- destroy / release。
- stale token guard。
- single-window first slice。

当前不实现真实 window create / close / destroy，不实现 handle table / generation，不暴露平台对象。

### Window Lifecycle Surface Boundary

当前 window lifecycle surface 仍是 comment-only / documentation-level 占位，不是 public runtime API。

边界如下：

- window lifecycle 是 future window-target state、request close、destroyed / stale target classification 的概念 owner。
- app lifecycle 是 app-level queue acceptance、shutdown policy、main-thread queue / drain policy 的概念 owner。
- platform adapter 是 AppKit / Metal / Objective-C 平台对象、平台 callback 和平台 release 事实的 owner。
- core window lifecycle 只应消费脱水 window facts，例如 create requested、created / failed、close requested、closing、destroyed、release completed、stale window message。
- `create window` / `request close` / `destroy` / `release` 仍只是 future slot；当前不定义函数签名，不实现行为，不创建 build / package entry。
- `request close` 未来应经过 app lifecycle queue acceptance 和 platform-adapter main-thread drain；当前不实现 queue / drain。
- auto-close、manual close、future async close 未来必须汇入同一 request-close path，避免 lifecycle 竞态。
- destroyed window state 必须是 terminal；stale close / stale message 不得复活窗口。
- 第一阶段可以继续 single-window，但 single-window 不能成为长期 runtime 限制。
- handle table / generation 现在不做；只有出现 public handle、多窗口、target update、async UI message targeting、destroyed-target identity reuse 或跨线程 target validation 时才另开边界。
- core 不得暴露 `NSWindow`、`NSView`、`CAMetalLayer`、`MTLDevice`、`CAMetalDrawable`、`CGImageRef`、Objective-C `id`、native handle 或 raw pointer；这些词只能作为禁止事项或 platform adapter 内部边界出现。
- window lifecycle 不引入 default global tick、blind redraw、Dirty Rect、frame scheduler 或 render loop。
- window lifecycle 不暗中打开 Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router。

本 section 只补清边界，不实现 runtime。

## Platform Adapter / Core Boundary

platform adapter 未来负责平台 event loop、platform callback、平台对象生命周期和平台 readiness / failure 事实。core runtime 只消费脱水 facts，不消费平台对象、raw event object、runloop truth 或 callback ownership。

当前 platform adapter surface 仍是 comment-only / documentation-level 占位，不是 public runtime API，也不是 public C ABI。

边界如下：

- platform adapter owner 属于 `runtime/cjgui` platform adapter module。
- app lifecycle 可以在未来消费 adapter 发出的脱水 app facts，例如 platform ready / failed、queue drain requested、quit requested、shutdown observed。
- window lifecycle 可以在未来消费 adapter 发出的脱水 window facts，例如 create observed、close requested、visibility summary、destroyed、release completed、stale window message。
- AppKit / Metal / CoreGraphics / Objective-C 平台对象未来只能在 adapter / bridge 内部持有，不能泄露到 core public surface。
- core 不能持有 `NSRunLoop`、`NSEvent`、`dispatch_main`、AppKit delegate truth、Objective-C callback truth、runloop mode、native handle 或 raw platform event object。
- core 不能接收平台对象 ownership、平台 callback ownership、smoke global state、smoke C ABI shape 或 smoke `last_error` 语义。
- adapter 可以把 lifecycle、readiness / failure、queue drain request、quit request、close request、window state、future input summary 和 future invalidation / redraw summary 作为脱水 facts 交给 core；这些 future facts 仍需单独 preflight / execution card 才能实现。
- macOS UI main-thread work 属于 platform adapter / platform bridge；core app lifecycle 未来最多拥有 queue / drain policy 的概念边界，不能直接操作平台 runloop。
- smoke bridge 只提供经验：主线程 owner、受控 lifecycle、平台对象隐藏、窄 diagnostics；不迁移 smoke 目录、build script、C ABI、单实例全局状态、auto-close、clear-color render path、screenshot / frame hash diagnostics 或全局 `last_error`。
- platform adapter 不暗中打开 default global tick、blind redraw、Dirty Rect、frame scheduler、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash、pixel diff、baseline 或 offscreen renderer。

本 section 只补清边界，不实现 adapter、event loop、callback binding、package / build config、public runtime API 或 public C ABI。

## Error Strategy Surface Boundary

当前 error strategy surface 仍是 comment-only / documentation-level 占位，不是 public runtime API，也不是 public C ABI。

边界如下：

- error strategy owner 属于 `runtime/cjgui` error strategy module；它只负责 future failure / degraded diagnostics 的分类边界，不拥有 app state、window state 或 platform truth。
- app lifecycle 负责 app-level policy，例如 run、quit、shutdown、main-thread queue acceptance；error strategy 只能分类 app lifecycle 汇报的 fatal、recoverable 或 degraded outcome，不实现 event loop、queue 或 drain。
- window lifecycle 负责 window target state，例如 created、closing、destroyed、stale target 和 future identity；error strategy 只能分类 create、request-close、destroy、release、stale handle / stale message 相关 failure，不实现 window lifecycle 或 handle table / generation。
- platform adapter 负责 native failure detail 和 platform capability fact；core error strategy 只能接收脱水 failure summary，不接收 platform object pointer、native handle、raw event、runloop truth 或 callback ownership。
- smoke `last_error` 只能作为实验期经验，不能迁移为长期 runtime error system；future runtime error 必须是调用关联、结构化、非全局、并发安全的。
- future minimum vocabulary 倾向包含 fatal、recoverable、degraded、invalid usage / contract violation、platform capability missing、stale handle / stale message，但当前不定义 enum、Result type、exception-like mechanism 或稳定函数签名。
- unknown ownership、stale target、invalid lifecycle ordering、denied capability 和 ambiguous native failure 应 fail closed；除非明确写成 degraded diagnostics，错误不应静默吞掉。
- diagnostics 只能作为 evidence / closure review 的辅助材料，不能成为第二状态真相源。

本 section 只补清边界，不实现 error strategy、public API、public C ABI、package / build config、error enum、Result type、exception-like mechanism 或 smoke C ABI migration。

## Package / Build Metadata Boundary

当前 `cjpm.toml` 只建立 minimal runtime package metadata boundary，不代表 runtime behavior、public runtime API 或 public C ABI 已经存在。

边界如下：

- package owner 候选是 `runtime/cjgui`，不属于 `labs/macos_bridge_smoke`、smoke build script、smoke C ABI、smoke `last_error` 或 verification harness。
- metadata 采用经本地 `cjpm` 文档查证的 root `cjpm.toml` + `src/` package layout。
- `output-type` 当前选择 `static`，只表达 future library package skeleton 倾向；它不是 executable smoke，也不定义可调用 runtime surface。
- 当前 app / window / platform / error 四个 `.cj` source 只允许 `package cjgui` declaration 加 comment-only surface；除 package declaration 外不得新增非注释仓颉语法。
- 当前不新增 public runtime API、public C ABI、稳定函数签名、package dependency、runtime behavior 或 build script。
- runtime package 不依赖 `labs/macos_bridge_smoke`，也不迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- build / check 命令必须按本地 setup 文档显式处理 `CJ_GUI_SDKROOT` / `SDKROOT`，并优先使用临时 target dir，避免把 build artifact 当作 source evidence。
- 如果 metadata-only skeleton 因 comment-only source 或 no entry 无法通过 build check，应记录真实 blocked reason，不能临时写非注释仓颉 runtime code 绕过。

本 section 只补清 package / build metadata 边界，不实现 runtime、platform adapter、event loop、window lifecycle、error strategy、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash、pixel diff、baseline 或 offscreen renderer。

## Smoke Guard Relationship

`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 继续作为旧链路 guard。它不是正式 runtime test framework，也不定义本目录的 public API。

## Red-team Guardrails

当前 skeleton 必须继续遵守：

- 不扩大每轮必读历史文档集。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 不进入 pixel diff / baseline。
- 不保存或输出 hash value。
- 不实现 command-list hash。
- 不定义 Display List / Command Buffer API。
- 不让 core runtime 持有 AppKit runloop truth。
- 不实现 semantic tree / Action Router。
- render hot path 不维护完整 semantic tree。
