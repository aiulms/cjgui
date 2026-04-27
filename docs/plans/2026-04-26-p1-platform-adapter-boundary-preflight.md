# P1 Platform Adapter Boundary Preflight

日期：2026-04-26

性质：docs-only / platform adapter boundary preflight / no implementation

状态：完成；不批准直接实现

范围：复核 app lifecycle surface 和 window lifecycle surface 已完成 comment-only refinement 之后，冻结 future platform adapter 与 core runtime 的边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不新增 package / build config，不定义 public runtime API 或 public C ABI。

## 1. 背景

本轮依据：

- [P1 window lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 window lifecycle surface execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)
- [P1 window lifecycle surface boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)
- [P1 app lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 app lifecycle surface boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)
- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 minimal app/window lifecycle runtime execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- 当前 runtime skeleton：
  - [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
  - [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
  - [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

当前 reality：

- app lifecycle surface 已完成 comment-only refinement。
- window lifecycle surface 已完成 comment-only refinement。
- platform adapter 仍只是 comment-only skeleton。
- 当前没有真实 platform adapter implementation。
- 当前没有 public runtime API、public C ABI、package / build config。
- 当前不允许迁移 smoke code 或 smoke C ABI。

本轮只回答 platform adapter 边界，不实现 adapter。

## 2. Future Platform Adapter 的 Owner

future platform adapter 的 owner 应属于：

> `runtime/cjgui` platform adapter module

当前对应 comment-only skeleton：

- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)

该 owner 未来可以持有：

- platform event loop truth。
- platform callback truth。
- platform main-thread execution truth。
- platform object ownership。
- platform readiness / failure observation。
- platform-specific translation from native events to dehydrated facts。

该 owner 不应成为：

- core app lifecycle owner。
- core window lifecycle owner。
- public runtime API owner。
- Renderer / Scene / Widget / Layout owner。
- Text / Input / IME / Accessibility owner。
- cross-platform backend abstraction。

本轮只冻结 owner 倾向，不实现 owner。

## 3. Platform Adapter 与 App Lifecycle 的边界

app lifecycle 是 core 侧的 app-level policy owner。它未来负责：

- 脱水 app lifecycle state。
- `init` / `run` / `request quit` / `shutdown` 的 policy。
- main-thread queue / drain 的 conceptual policy owner。
- shutdown 后 late message 的 app-level acceptance policy。
- platform readiness / failure summary 的 core-level consumption。

platform adapter 是平台执行 owner。它未来负责：

- 平台 event loop / callback 的接入。
- 在平台主线程上触发 queue drain。
- 将 platform readiness / failure 翻译成脱水 facts。
- 将 platform quit request / close request 翻译成 core 可消费的 lifecycle facts。
- 持有 AppKit / Metal / Objective-C 对象，并在内部管理其生命周期。

边界应表达为：

```text
platform adapter owns platform runloop / callbacks / main-thread execution
platform adapter emits dehydrated lifecycle facts
core app lifecycle consumes dehydrated facts and owns policy
core app lifecycle never owns platform runloop truth
```

这意味着：

- platform adapter 可以驱动 core app lifecycle。
- core app lifecycle 不能直接持有 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth。
- queue / drain 的 policy 和 execution 必须分开：policy 属于 app lifecycle，平台主线程执行属于 adapter。

本轮不实现 app lifecycle，也不实现 platform adapter。

## 4. Platform Adapter 与 Window Lifecycle 的边界

window lifecycle 是 core 侧的 window-target state owner。它未来负责：

- 脱水 window lifecycle state。
- create requested / created / failed。
- close requested / closing。
- destroyed / release completed。
- stale window message classification。
- future handle table / generation 触发条件。

platform adapter 未来负责：

- 创建、持有、释放平台窗口对象。
- 接收平台 close / resize / expose / visibility / scale 等 callback。
- 将平台 callback 翻译成脱水 window facts。
- 在平台主线程上执行平台对象 create / close / release。
- 将平台失败翻译成结构化、脱水 failure summary。

边界应表达为：

```text
platform adapter owns platform window objects
platform adapter emits dehydrated window facts
core window lifecycle owns target state and stale / destroyed classification
core window lifecycle never owns platform object identity
```

这意味着：

- window lifecycle 可以接收 `window_created` / `window_failed` / `close_requested` / `destroyed` / `release_completed` 等脱水事实。
- window lifecycle 不持有 `NSWindow`、`NSView`、`CAMetalLayer`、`MTLDevice`、Objective-C `id`、`CGImageRef` 或 raw pointer。
- platform object identity 不能成为 core public surface。

## 5. 是否可以持有 AppKit / Metal / Objective-C 平台对象

答案：可以，但只能在 platform adapter / bridge 内部持有。

允许的内部职责：

- 持有 AppKit window / view / delegate 等对象。
- 持有 Metal layer / device / queue 等对象。
- 持有 CoreGraphics / Objective-C callback 相关内部对象。
- 负责 retain / release / delegate / callback / platform teardown。
- 负责将平台对象生命周期转成脱水 lifecycle facts。

禁止：

- 将平台对象泄露到 core public surface。
- 让 core app lifecycle 或 core window lifecycle 持有平台对象。
- 让 public runtime API 暴露平台对象或 raw pointer。
- 让平台对象 identity 成为 stable window identity。
- 让 native handle 变成 future public handle。

正确口径：

> platform adapter can own platform objects internally; core runtime can only consume dehydrated facts.

## 6. Core Runtime 是否允许持有 Runloop / Callback Truth

答案：不允许。

core runtime 不允许持有或暴露：

- `NSRunLoop`
- `NSEvent`
- `dispatch_main`
- Objective-C callback truth
- AppKit delegate identity
- platform event object
- platform object pointer
- native handle

原因：

- 这些属于 macOS adapter / bridge 内部事实。
- core runtime 若持有这些 truth，会把 AppKit event model 写入 core。
- 后续 Windows / Wayland / Linux 等平台会被 macOS 语义污染。
- 这会违反“platform adapter / core event-loop 隔离”的 red-team guardrail。

本轮不因为防过拟合而提前做跨平台抽象。当前只冻结隔离边界。

## 7. Platform Adapter 可以交给 Core 的脱水 Facts

platform adapter 未来可以把以下脱水 facts 交给 core。以下都是候选事实类别，不是 API，不是实现。

### Lifecycle facts

- app initialized / ready。
- app run requested。
- app quit requested。
- app shutdown requested / completed。
- lifecycle failure / degraded summary。

### Platform readiness / failure

- platform ready。
- platform capability missing。
- platform initialization failed。
- platform object create failed。
- platform release failed。
- degraded platform mode。

### Queue drain request

- main-thread queue drain requested。
- queue drain started / completed / failed。
- late message after shutdown。

### Quit request / close request facts

- platform quit requested。
- platform window close requested。
- app close-all requested。
- close request source summary。

### Window state facts

- window create requested / created / failed。
- window visible / hidden / minimized candidate。
- window close requested / closing / destroyed。
- window release completed / failed。
- stale window message.
- resize / scale / visibility candidate facts.

### Future input facts

- future input event summary。
- focus change summary。
- text / IME facts only after separate Text / Input / IME preflight。

### Future frame / redraw facts

- expose / surface invalidated / resize redraw needed candidate。
- frame step request candidate。
- redraw request candidate。

这些 future frame / redraw facts 不能自动变成 global tick、blind redraw 或 frame scheduler。任何 redraw / Dirty Rect / frame scheduling 仍必须另开 preflight。

## 8. Platform Adapter 不应该交给 Core 什么

platform adapter 不应交给 core：

- platform object pointer。
- AppKit object ownership。
- Metal object ownership。
- CoreGraphics object ownership。
- raw event objects。
- raw `NSEvent`。
- raw Objective-C callback。
- runloop truth。
- callback ownership。
- delegate identity。
- dispatch queue identity。
- native handle。
- screenshot / frame hash artifact truth。
- smoke diagnostics fields as runtime truth。

这些可以在 adapter / bridge 内部存在，但不能成为 core truth、public runtime API 或 stable C ABI。

## 9. Main-thread Ownership 边界

main-thread ownership 应拆成两个层次：

### Platform execution owner

platform adapter 拥有：

- 哪个线程是 platform main thread 的事实。
- 如何在 platform main thread 上执行 drain。
- 如何接收 platform callback。
- 如何与 AppKit / Metal 的主线程要求对齐。

### Core policy owner

app lifecycle 拥有：

- queue message 是否被 app-level policy 接受。
- shutdown 后 late message 如何处理。
- drain 成功 / 失败事实如何推进 app state。
- quit / shutdown policy。

window lifecycle 拥有：

- window-targeted lifecycle facts 的 target state transition。
- stale / destroyed window message 的分类。

边界：

```text
adapter executes on platform main thread
app lifecycle decides app-level acceptance
window lifecycle decides window-target state
error strategy classifies failures
```

本轮不实现 queue，也不实现 drain。

## 10. `last_error` Smoke 经验如何迁移

smoke `last_error` 提供的可迁移经验是：

- platform adapter / bridge 需要可观察错误边界。
- platform readiness / failure 应能脱水输出。
- recoverable / degraded / fatal 需要区分。
- 错误不能静默吞掉。

不能迁移的是：

- 全局 mutable `last_error` 形态。
- smoke C ABI 的 `last_error` 函数。
- 与单实例 smoke state 绑定的错误语义。
- 无调用关联、无并发安全、无 window target 关联的错误系统。

future adapter error boundary 应倾向：

- call-associated。
- structured。
- non-global。
- concurrency-safe。
- 能表达 platform readiness / failure。
- 能表达 adapter 内部平台对象创建 / release failure。
- 能向 app lifecycle / window lifecycle 输出脱水 failure summary。

本轮不定义 concrete error type，不修改 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)。

## 11. Platform Adapter 与 Smoke Bridge 的关系

smoke bridge 提供经验，不提供直接可迁移 API。

可迁移为约束的经验：

- macOS UI / AppKit / Metal 相关工作必须有主线程 owner。
- 平台对象必须留在 bridge / adapter 内部。
- core / 仓颉公共层不能暴露平台对象裸指针。
- close / destroy 应受控，避免 auto-close、manual-close、future async message 竞态。
- platform failures 需要可观察、可分类。
- smoke guard 可以继续保护旧链路不退化。

不能迁移为 runtime 的内容：

- `labs/macos_bridge_smoke` 目录结构。
- smoke build script。
- smoke C ABI 形态。
- smoke `cjgui_app_run()`。
- smoke `last_error` global shape。
- smoke single-instance global state。
- smoke auto-close behavior。
- smoke clear-color render path。
- smoke diagnostics 字段。
- screenshot / frame hash harness。

正确关系：

> smoke bridge is evidence; platform adapter is future runtime boundary.

## 12. 是否现在定义 Public C ABI 或 Runtime API

答案：不定义。

原因：

- platform adapter owner / fact boundary 仍在 preflight 阶段。
- app lifecycle 和 window lifecycle 仍为 comment-only surface。
- package / build boundary 未打开。
- error strategy 未定义 concrete type。
- public handle / handle table / generation 未打开。
- 任何 API 都会被示例、测试和外部调用反向固化。

下一张 execution card 也只能授权 comment-only / documentation-level surface refinement，不应定义 stable function signature、public C ABI 或 runtime API。

## 13. 是否现在进入 Implementation

答案：不进入。

原因：

- 当前 platform adapter skeleton 仍是 comment-only。
- 当前没有 adapter state machine。
- 当前没有 package / build config。
- 当前没有 app lifecycle / window lifecycle behavior。
- 当前没有 error strategy implementation。
- 当前没有 handle / target identity。
- 当前不允许迁移 smoke code。

因此下一步仍应是 docs-only execution card，而不是 implementation。

## 14. Red-team Guardrails 吸收

本轮吸收 macOS overfitting guardrail：

- AppKit event loop 只能属于 macOS platform adapter / bridge。
- core runtime 不得持有 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth。
- core runtime 未来只能消费脱水 lifecycle / input / frame step / queue drain 等抽象 facts。
- `tick` / `step` / input buffer 只能是 future candidate，本轮不承诺游戏引擎式 API。
- 防过拟合不等于提前做跨平台抽象。

本轮不创建 `CJGUI_TRUTH_MANIFEST.md`，不扩大每轮必读历史文档集，不打开 governance manifest 实现。

## 15. Self-drawn Guardrails 吸收

本轮吸收 self-drawn guardrails：

- 自绘降低的是 public widget 行为对平台原生控件系统的耦合，不是免除 platform adapter 对真实系统边界的责任。
- platform adapter 可以接收 expose / resize / visibility / scale / surface invalidation 等平台事实，并脱水后交给 core。
- future frame / redraw facts 不能变成默认 global tick。
- 不得默认 blind redraw。
- 不得暗中打开 Dirty Rect / invalidation system。
- 不得暗中打开 Renderer / Scene / Widget / Layout / DSL。
- 不得暗中打开 Text / Input / IME / Accessibility。
- 不得因为自绘而忽略 IME cursor rect sync 或 accessibility semantic bridge future slots。

如果未来需要 redraw / render scheduling，应另开：

- `P1 redraw invalidation / dirty rect policy preflight`

## 16. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 platform adapter。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
- 不实现 handle table / generation。
- 不迁移 smoke code。
- 不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 17. 是否应该创建 Execution Card

结论：下一步可以创建 docs-only execution card，但不能自动进入实现。

推荐下一篇：

> `P1 platform adapter boundary execution card`

范围只能是：

- 将本 preflight 收束为受限 execution card。
- 未来 first slice 最多只能做 comment-only / documentation-level platform adapter surface refinement。
- 未来 first slice 最多只能修改 [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj) 和 / 或 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 的 platform adapter boundary section。
- future closure review。
- plans README。
- GUI task tracker。

不得授权：

- 真实 platform adapter behavior。
- platform event loop implementation。
- AppKit / Metal / Objective-C binding。
- public C ABI。
- public runtime API。
- package / build config。
- smoke code migration。
- app lifecycle / window lifecycle implementation。
- handle table / generation。
- Renderer / Scene / Widget / Layout / DSL。
- global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 18. 结论

platform adapter boundary 应先冻结，但仍不实现。

当前结论：

- future platform adapter owner 属于 `runtime/cjgui` platform adapter module。
- platform adapter 可以拥有平台 event loop / callback / object truth。
- platform adapter 可以在 adapter / bridge 内部持有 AppKit / Metal / Objective-C 平台对象。
- core runtime 不能拥有 platform runloop truth、callback truth 或 platform object identity。
- core 只接收脱水 lifecycle / readiness / failure / queue drain / quit / close / window state / future input / future frame facts。
- smoke bridge 只提供经验，不提供直接可迁移 API。
- smoke `last_error` 只能迁移为“需要 adapter error boundary”的经验，不能直接升格为长期并发错误系统。
- 当前不定义 public C ABI 或 runtime API。
- 当前不进入 implementation。

当前没有自动开启的 runtime implementation。

下一步推荐 docs-only：

> `P1 platform adapter boundary execution card`
