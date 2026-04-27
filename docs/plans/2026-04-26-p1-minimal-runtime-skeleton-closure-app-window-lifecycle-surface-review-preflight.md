# P1 Minimal Runtime Skeleton Closure / App-window Lifecycle Surface Review Preflight

日期：2026-04-26

性质：docs-only / runtime skeleton closure review preflight / no implementation

状态：完成；不批准直接实现

范围：复核已落地的 comment-only runtime skeleton 是否足以封账，并判断下一条 runtime surface 边界应优先冻结哪一项。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不新增 package / build config，不定义 public runtime API。

## 1. 背景

本轮依据：

- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 minimal app/window lifecycle runtime execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
- [P1 minimal app/window lifecycle runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- 当前 runtime skeleton：
  - [runtime/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md)
  - [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
  - [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
  - [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

上一轮已经创建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/`，但只写入 README 和 comment-only `.cj` skeleton。没有 package / build config，没有非注释仓颉语法，没有 public API，没有 runtime behavior。

## 2. 当前 Skeleton 是否足以封账

结论：足以封账，但只能封账为 comment-only architectural placeholder。

当前 skeleton 已经完成的事情：

- 给正式 runtime 从 `labs/` 独立出来提供了最小目录落点。
- 明确 `runtime/` 不是 `labs/macos_bridge_smoke` 的扩写。
- 明确 `runtime/cjgui` 不是正式 public runtime。
- 记录了 app lifecycle、window lifecycle、platform adapter boundary、error strategy placeholder 四个 future surface。
- 保持 `.cj` 文件 comment-only，未制造未验证的仓颉语法事实。

它没有完成的事情：

- 没有 app lifecycle implementation。
- 没有 window lifecycle implementation。
- 没有 event loop。
- 没有 window create / close / destroy。
- 没有 handle table / generation。
- 没有 structured runtime error type。
- 没有 package / build boundary。
- 没有 public API。

因此，当前 skeleton 可以作为 runtime surface 讨论的占位基础，但不能被解读为 runtime capability。

## 3. 是否仍符合 Execution Card

结论：符合。

当前 skeleton 仍符合 execution card 的原因：

- 不实现 runtime。
- 不定义稳定 public API。
- 不新增 public C ABI。
- 不迁移 smoke 代码。
- 不调用 smoke `cjgui_app_run()` 或 `cjgui_last_error_*()`。
- 不暴露 `NSWindow*`、`NSView*`、`CAMetalLayer*`、`MTLDevice*`、`NSEvent*`、`CGImageRef`、Objective-C `id` 或平台对象裸指针。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 command-list hash、pixel diff、baseline、offscreen renderer。
- 不实现 semantic tree / Action Router。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

需要继续提醒的是：`platform_adapter.cj` 中出现 `NSRunLoop` / `NSEvent` / `dispatch_main` 只是在注释中表达“core runtime 不得持有这些 truth”，不是 API、binding 或实现。

## 4. 下一条边界应优先冻结哪一项

候选项：

- app lifecycle surface。
- window lifecycle surface。
- platform adapter boundary。
- error strategy。
- runtime build / package boundary。

推荐下一条优先冻结：

> `P1 app lifecycle surface boundary preflight`

原因：

- app lifecycle 先决定 runtime owner。
- app lifecycle 先决定 main-thread queue / drain 的归属。
- app lifecycle 先决定 `init` / `run` / `request quit` / `shutdown` 的边界。
- app lifecycle 先决定 platform adapter 如何被驱动，而不是让 AppKit runloop 反向定义 core runtime。
- app lifecycle 先决定是否允许 blocking run、step / pump、explicit shutdown、late message discard 等基础语义。
- window lifecycle、platform adapter、error strategy 都会受 app lifecycle 的 run / shutdown / main-thread owner 影响。
- build / package boundary 现在打开过早，因为还没有任何非注释 surface 需要编译或发布。

不建议优先打开：

- window lifecycle implementation：它依赖 app lifecycle 的 main-thread owner 和 shutdown 边界。
- platform adapter implementation：它容易把 AppKit runloop 语义提前带进 core。
- error implementation：错误类型应服务于 lifecycle surface，而不是先发明公共错误 API。
- build / package：当前 skeleton 没有非注释代码，先建 package 会制造假成熟感。
- Renderer / Scene / Widget / Layout：它们依赖 app/window lifecycle 的底座。

## 5. 是否应该先进入真实 Runtime Implementation

结论：不应该。

原因：

- 当前只有 comment-only skeleton，还没有 app lifecycle surface boundary。
- `init` / `run` / `request quit` / `shutdown` 的 owner 和 contract 未冻结。
- main-thread queue / drain 与 platform adapter 的驱动关系未冻结。
- `run` 是 blocking、polling、step-driven 还是 adapter-driven 仍未冻结。
- window lifecycle 和 stale handle 的 error route 仍未冻结。
- build / package boundary 仍未冻结。
- 直接实现会很容易把 AppKit runloop、smoke 经验或占位命名误写成 core truth。

因此下一步仍应 docs-only。

## 6. 为什么下一步仍应 Docs-only

下一步需要回答的是 owner、truth、surface 和 stop-line，不是代码。

docs-only 的价值：

- 防止 comment-only skeleton 立刻变成未验证 API。
- 防止 app lifecycle 和 platform adapter 互相反向污染。
- 防止为了“让 skeleton 能编译”而创建 build config / package。
- 防止 `tick` / `step` / frame loop 被误当成 GUI runtime 默认模型。
- 防止把 self-drawn 路线误解为可以跳过 IME / accessibility / platform adapter 责任。

在 app lifecycle surface 冻结前，不应写真实 runtime code。

## 7. App Lifecycle Surface 未来至少要回答什么

下一篇 app lifecycle surface boundary preflight 至少应回答：

- app lifecycle owner 的模块名、职责和真相层。
- `init` 是否创建 runtime state，是否必须在主线程。
- `run` 是否 blocking，是否允许 nested run，是否允许重复 run。
- `request quit` 是同步还是异步 request。
- `shutdown` 是谁触发，是否幂等，shutdown 后 late message 如何处理。
- main-thread queue / drain owner 是 app lifecycle 还是 platform adapter。
- platform adapter 如何驱动 core：callback、pump、step、queue drain 还是 future abstraction。
- 是否允许 `tick` / `step` / input buffer 作为候选名；若允许，如何避免承诺游戏引擎式 API。
- idle 时是否允许重绘；默认应为不允许 blind redraw。
- app lifecycle 如何处理 capability missing、wrong thread、platform failure、stale message。
- smoke guard 如何继续验证旧链路，但不成为 runtime tests。
- 是否允许任何 public API；默认应继续不允许稳定 public API。

## 8. Window Lifecycle Surface 未来至少要回答什么

window lifecycle surface boundary 未来至少应回答：

- window lifecycle owner 的模块名、职责和真相层。
- `create window` 是否只是 request，还是同步创建。
- window token / handle 是否 public；如果 public，是否必须 handle table / generation。
- 第一刀是否继续 single-window。
- `request close` 和 `destroy / release` 的关系。
- manual close、app quit、future async close 是否汇入同一状态机。
- destroyed / stale token 后消息是丢弃、返回错误，还是进入 diagnostics。
- window lifecycle 如何依赖 app lifecycle main-thread queue / drain。
- platform object hiding 如何表达。
- window visibility / resize / expose / scale 是否进入 lifecycle surface，还是保留给 platform adapter / invalidation future slot。
- 是否允许 target update message；默认不允许。

本轮不打开 window lifecycle implementation。

## 9. Platform Adapter Boundary 未来至少要回答什么

platform adapter boundary 未来至少应回答：

- AppKit event loop 的 owner 是谁。
- core runtime 看到的是哪些脱水事实。
- 平台 callback 如何被翻译为 lifecycle / input / frame step / queue drain facts。
- `NSRunLoop`、`NSEvent`、`dispatch_main`、Objective-C callback truth 如何被隔离在 adapter 内。
- platform adapter 是否可以持有 `NSWindow`、`NSView`、`CAMetalLayer`、Metal / CoreGraphics 对象。
- 平台对象生命周期如何与 app/window lifecycle 对齐。
- resize / expose / visibility / focus / scale / display change 如何进入 future invalidation 或 geometry pipeline。
- IME cursor rect / candidate window 坐标同步未来由谁负责。
- accessibility semantic bridge 未来从哪里接入。
- 是否允许 cross-platform abstraction；当前仍不允许。

本轮不实现 platform adapter。

## 10. Error Strategy 未来至少要回答什么

error strategy boundary 未来至少应回答：

- 是否定义 `fatal` / `recoverable` / `degraded` 分类。
- 错误是否调用关联，如何避免全局 mutable `last_error`。
- 错误是否绑定 app lifecycle / window lifecycle state。
- wrong thread、stale handle、destroyed target、capability missing、platform failure 如何分类。
- shutdown 后 late message 是错误、丢弃还是 diagnostics。
- 多窗口和 future generation 如何影响错误结构。
- 错误如何跨 platform adapter / core boundary 脱水。
- 哪些错误可以向 public API 暴露，哪些只属于 internal diagnostics。

本轮不定义 concrete error type。

## 11. Runtime Build / Package Boundary 是否现在打开

结论：现在不打开。

原因：

- 当前 `.cj` 文件全部为 comment-only skeleton。
- 没有非注释仓颉语法。
- 没有 module / package owner。
- 没有 app lifecycle surface。
- 没有 public / internal API 边界。
- 现在创建 build config 会让 skeleton 看起来像可编译 runtime，从而制造假成熟感。

只有当 app lifecycle surface 至少冻结 owner、入口、internal/public 边界后，才应另开：

> `P1 runtime build / package boundary preflight`

该 future preflight 需要回答 `cjpm` package、module layout、build entry、test entry、smoke guard 与 runtime tests 的关系。

## 12. Self-drawn Guardrails 吸收

本轮必须吸收 self-drawn guardrails：

- 自绘降低的是公共 API 对平台原生控件系统的耦合，不是免除 platform adapter 对真实系统边界的责任。
- 不得默认 global tick / blind redraw。
- redraw 未来应 event / invalidation / dirty region / explicit animation request driven。
- app/window lifecycle surface 不得暗中打开 Dirty Rect / frame scheduler。
- app/window lifecycle surface 不得暗中打开 Text / Input / IME / Accessibility。
- `final committed string only` 只能是 future early IME isolation candidate，不是完整输入系统 contract。
- platform adapter 未来必须保留 IME cursor rect / screen coordinate sync 的设计位。
- accessibility semantic bridge 是 future slot；自绘 UI 不能把 OS accessibility 视为不存在。
- semantic projection 必须 lazy / on-demand，不能进入 render hot path。

因此下一篇 app lifecycle surface boundary preflight 不应把 `tick`、`frame loop`、`requestAnimationFrame` 或类似机制写成默认事实。

## 13. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle / window lifecycle / event loop / window create / close / destroy。
- 不实现 handle table / generation。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 14. 结论

当前 comment-only runtime skeleton 可以封账，但它只是 architectural placeholder。

下一步不应直接进入 implementation，也不应先开 window lifecycle implementation、build / package、Renderer、Scene、Widget 或 Layout。

推荐下一条 docs-only opening：

> `P1 app lifecycle surface boundary preflight`

该 opening 只冻结 future app lifecycle surface，不实现 app lifecycle，不创建 build config，不定义 public runtime API。
