# P1 Window Lifecycle Surface Boundary Preflight

日期：2026-04-26

性质：docs-only / window lifecycle surface boundary preflight / no implementation

状态：完成；不批准直接实现

范围：复核 app lifecycle surface comment-only refinement 已封账后的 runtime surface 下一步，冻结 future window lifecycle surface 的 owner、truth、`create window` / `request close` / `destroy` / `release`、stale message、single-window、handle table / generation、platform adapter 和 error strategy 边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不新增 package / build config，不定义 public runtime API。

## 1. 背景

本轮依据：

- [P1 app lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 app lifecycle surface execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)
- [P1 app lifecycle surface boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)
- [P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)
- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 main-thread UI message queue closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- 当前 runtime skeleton：
  - [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
  - [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
  - [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

上一轮已经完成 app lifecycle surface 的 comment-only refinement。当前仍没有真实 runtime behavior、public API、package / build config 或 window lifecycle implementation。

本轮只冻结 window lifecycle surface 的未来边界。

## 2. Future Window Lifecycle Surface 的 Owner

future window lifecycle surface 的 owner 应属于：

> `runtime/cjgui` core window lifecycle module

也就是当前 comment-only skeleton 中 [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj) 记录的 future owner 方向。

该 owner 未来应持有：

- 脱水 window lifecycle state。
- `create window` / `request close` / `destroy` / `release` 的 state transition policy。
- window destroyed 后 message 的处理规则。
- stale close / stale message 的分类入口。
- single-window first slice 的窗口状态 truth。
- 与 app lifecycle main-thread queue / drain policy 的协作边界。

它不应持有：

- AppKit / Metal / Objective-C 平台对象。
- `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice` / Objective-C `id` / `CGImageRef` 等 native object truth。
- platform callback truth。
- Renderer / Scene / Widget / Layout state。
- Text / Input / IME / Accessibility state。

本轮只冻结 owner 倾向，不实现 owner。

## 3. Window Lifecycle 与 App Lifecycle 的边界

app lifecycle 已冻结为 future app-level owner：

- app-level state。
- app-level `run` / `request quit` / `shutdown`。
- main-thread queue / drain conceptual policy owner。
- shutdown 后 late message 的 app-level acceptance policy。

window lifecycle 应负责：

- window target state。
- window create request 的状态归属。
- request close 的 window-level transition。
- destroy / release 的 terminal state。
- stale target / destroyed target 的 classification。
- future handle table / generation 的 target identity slot。

关系应表达为：

> app lifecycle 接收或拒绝 app-level queue message；window lifecycle 处理 window-targeted lifecycle facts。

换句话说，app lifecycle 可以决定“这类 message 是否还能被 app 接受、是否处于 shutdown 后 late message”，window lifecycle 决定“这个 window target 是否存在、是否正在关闭、是否 destroyed、是否 stale”。

本轮不实现 app lifecycle，也不实现 window lifecycle。

## 4. Window Lifecycle 与 Platform Adapter 的边界

platform adapter 负责平台对象事实：

- `NSWindow` / `NSView`。
- `CAMetalLayer`。
- Metal / CoreGraphics 对象。
- Objective-C delegate / callback。
- 平台 close event。
- 平台 destroy / release 细节。

core window lifecycle 负责脱水事实：

- `window_create_requested`。
- `window_created`。
- `window_close_requested`。
- `window_closing`。
- `window_destroyed`。
- `window_release_completed`。
- `stale_window_message`。
- `platform_window_failure`。

关系应表达为：

> platform adapter 可以持有和释放平台对象，但只能向 core window lifecycle 输出脱水 window lifecycle facts。

core window lifecycle 不得把 AppKit / Metal / Objective-C 对象写成自己的 truth，也不得暴露 platform object / raw pointer public surface。

## 5. Future Slot 的最小语义

以下只是 future slot 的最小语义，不是 API，不是实现。

### `create window`

`create window` 倾向表示：

- 提交或接受一个 window creation request。
- 绑定一个 window lifecycle state。
- 由 platform adapter 在平台主线程上完成平台对象创建。
- 由 core window lifecycle 记录脱水 created / failed fact。

它不应：

- 暴露 `NSWindow*`、`NSView*`、`CAMetalLayer*` 或 native handle。
- 隐式创建 Renderer / Scene / Widget / Layout。
- 隐式启动 app `run`。
- 绕过 app lifecycle main-thread queue / drain policy。
- 直接复用 smoke C ABI。

### `request close`

`request close` 倾向表示：

- 提交 window-level close request。
- 幂等地把 target window 推向 closing / close requested。
- 与 app lifecycle queue acceptance policy 对齐。
- 让 auto-close、manual close、future async close 汇入同一 close path。

它不应：

- 直接释放 platform object。
- 直接 destroy window。
- 在后台线程触碰 UI resource。
- 绕过 app lifecycle / main-thread queue / drain。

### `destroy`

`destroy` 倾向表示：

- window lifecycle 的 terminal transition 候选。
- 将 window state 推向 destroyed。
- 使 destroyed 后 message 被丢弃或分类。
- 与 platform adapter 的 release / cleanup fact 对齐。

它不应：

- 由 core 直接释放 AppKit / Metal 对象。
- 允许 destroyed window 被 stale message 复活。
- 混入 Renderer / Scene / Widget teardown。

### `release`

`release` 倾向表示：

- platform adapter 内部释放平台对象的完成 fact。
- core window lifecycle 只接收脱水 `release_completed` 或 failure summary。
- release 与 destroy 的顺序和幂等性需要 future execution card 冻结。

它不应：

- 暴露平台对象释放 API。
- 暴露 raw pointer lifecycle。
- 变成 public C ABI。

## 6. 是否允许直接持有平台对象

默认不允许。

core window lifecycle 不允许直接持有或暴露：

- `NSWindow`
- `NSView`
- `CAMetalLayer`
- `MTLDevice`
- `CAMetalDrawable`
- Objective-C `id`
- `CGImageRef`
- native handle
- raw pointer

如果 future window 需要平台对象，应由 platform adapter 内部持有：

- core 只保存脱水 window state。
- core 只接收 platform adapter 发出的脱水 lifecycle facts。
- platform adapter 内部负责 retain / release、delegate、layer、drawable、Metal resource 等平台细节。
- platform adapter 不把平台对象 identity 作为 public runtime API 或 core truth。

这条边界来自 smoke-to-runtime preflight 和 GUI governance 的共同约束：平台脏活可以留在 adapter，向上接口必须极窄、脱水、可测试。

## 7. Request Close 如何经过 App Lifecycle / Main-thread Queue / Drain

概念路径应是：

```text
caller / platform close event / future async close
  -> app lifecycle queue acceptance policy
  -> main-thread drain execution by platform adapter
  -> window lifecycle request close transition
  -> platform adapter performs platform close / release work
  -> window lifecycle receives destroyed / release completed fact
```

边界：

- app lifecycle owns app-level queue acceptance and shutdown-late-message policy。
- platform adapter owns execution on platform main thread。
- window lifecycle owns target window state transition。
- error strategy owns stale / invalid / wrong-state classification。

这只是 future conceptual flow，不是 implementation。

## 8. Auto-close / Manual-close / Future Async Message 竞态

未来原则：

- auto-close、manual close、future async close 必须汇入同一 request close path。
- request close 只推进状态，不直接释放平台对象。
- close / destroy / release 必须有单一路径和幂等约束。
- destroyed 后 late message 必须安全丢弃或分类，不能复活窗口。
- main-thread drain 必须是 UI-affecting lifecycle request 的唯一执行入口。

这来自已封账的 smoke main-thread UI message queue first slice：

- smoke 已证明单实例 `RequestClose` 可以经 main-thread post / drain 进入 close / destroy。
- 该实现不能直接迁移为 formal runtime queue。
- 但它提供了 runtime window lifecycle 的约束经验。

## 9. Stale Close / Stale Message / Destroyed Window 后 Message 的 Owner

合理 owner 划分：

- app lifecycle：处理 app-level terminal state 和 queue acceptance。
- window lifecycle：处理 window target state、destroyed state、closing state。
- future handle table / generation：处理 public handle / target identity validation。
- error strategy：处理 stale / destroyed / wrong generation / invalid state 的结构化分类。

当前 window lifecycle surface 应记录：

- destroyed window state 必须 terminal。
- stale close 不得重新进入 create / close happy path。
- stale message 不得复活 destroyed window。
- stale operation 应安全丢弃或被结构化分类。

本轮不实现这些行为。

## 10. 是否需要 Handle Table / Generation

默认现在不做。

原因：

- 当前 runtime skeleton 仍是 comment-only。
- 当前没有 public window handle。
- 当前没有 multi-window。
- 当前没有 target update message。
- 当前没有 async UI message targeting。
- 当前不定义 public runtime API。

何时必须同步打开：

- 出现 public window handle。
- 出现 multi-window routing。
- 出现 target update。
- 出现 async target UI message。
- 出现 destroyed target 与新 target 复用 identity 的风险。
- 出现跨线程 message 需要验证 target still alive。

届时必须另开 `window handle table / generation preflight` 或 execution card，不能混在本轮。

## 11. Single-window First Slice 是否仍成立

结论：仍成立。

原因：

- 第一阶段重点是 owner / truth / lifecycle path，而不是多窗口能力。
- single-window 可以验证 create / request close / destroy / stale policy 的最小边界。
- 不暴露 public handle 时，可以避免过早引入 handle table / generation。
- 多窗口会立即引入 routing、target identity、z-order / focus、destroyed target reuse 等额外复杂度。

但 single-window 不能被写成长期 runtime 限制。

正确表达：

> first slice may stay single-window, but the surface must not prevent future multi-window and handle generation.

## 12. Window Lifecycle 与 Error Strategy 的关系

window lifecycle 应定义哪些场景需要错误或 diagnostics：

- create request during invalid app state。
- request close after destroyed。
- duplicate close request。
- destroy before create。
- platform create failure。
- platform release failure。
- stale message。
- wrong thread。
- invalid target identity。
- future generation mismatch。

error strategy 应定义错误结构：

- 调用关联。
- 非全局。
- 并发安全。
- `fatal` / `recoverable` / `degraded` 或等价分类。
- 是否向 public surface 暴露。
- 是否只是 internal diagnostics。

window lifecycle 不应直接迁移 smoke `last_error`。`last_error` 只能作为实验期经验：它提醒我们需要可观察错误，但不能扩展成长期并发错误系统。

本轮不定义 concrete error type，也不修改 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)。

## 13. 是否现在定义 Public Runtime API

默认不定义。

原因：

- 当前 window lifecycle owner、truth 和 slot 语义仍未由 execution card 收束。
- handle table / generation 未冻结。
- app lifecycle 与 platform adapter 的真实驱动关系未实现。
- build / package boundary 未打开。
- 任何 public API 都会被 example、tests 或外部调用反向固化。

下一张 execution card 如果允许修改 runtime skeleton，也应优先保持 documentation-level / comment-only refinement，不应定义稳定 public runtime API。

## 14. 是否现在进入 Implementation

默认不进入。

原因：

- 当前只有 comment-only skeleton。
- window create / close / destroy 的 state machine 未冻结。
- app lifecycle queue / drain 仍未实现。
- platform adapter 仍未实现。
- platform object ownership 仍只是边界原则。
- handle table / generation 尚未决定。
- error strategy 未冻结。
- package / build boundary 未打开。

因此下一步仍应 docs-only。

## 15. Self-drawn Guardrails 吸收

window lifecycle surface 必须吸收 self-drawn guardrails：

- 不得默认 global tick。
- 不得默认 blind redraw。
- 不得把 frame loop 当成 window lifecycle 默认事实。
- 不得把 window lifecycle 写成 Renderer / Scene / Widget / Layout owner。
- 不得暗中打开 Dirty Rect / invalidation system。
- 不得暗中打开 Text / Input / IME / Accessibility。
- 不得把自绘解释为可以忽略 platform adapter、IME cursor rect sync 或 accessibility semantic bridge。

window lifecycle 可以在未来接收 visibility / resize / expose / scale 等脱水 window facts，但这些不等于 redraw scheduler、layout system 或 renderer。

## 16. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 window lifecycle / window create / request close / destroy / release。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 handle table / generation。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 17. 是否应该创建 Execution Card

结论：下一步可以创建 docs-only execution card，但不能自动进入实现。

推荐下一篇：

> `P1 window lifecycle surface execution card`

该 execution card 只能授权极窄的 comment-only / documentation-level surface refinement，例如：

- 在现有 [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj) 中补充 future slot 注释。
- 在 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 中补充 window lifecycle owner / adapter boundary 文档。
- 新建 closure review。
- 更新 plans README 和 tracker。

它不得授权：

- 真实 runtime behavior。
- `create window` / `request close` / `destroy` / `release` 实现。
- main-thread queue / drain 实现。
- handle table / generation。
- package / build config。
- public runtime API。
- platform adapter implementation。
- Renderer / Scene / Widget / Layout / DSL。
- global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 18. 结论

window lifecycle surface 应该先冻结，但仍不实现。

当前结论：

- future window lifecycle owner 属于 `runtime/cjgui` core window lifecycle module。
- platform adapter 负责 AppKit / Metal / Objective-C 平台对象和平台 callback truth。
- core window lifecycle 只处理脱水 window state、request close / destroyed / stale message facts。
- request close 应经过 app lifecycle / main-thread queue / drain 的 future conceptual path。
- auto-close、manual close、future async close 必须汇入同一 request close path，避免生命周期竞态。
- stale close / destroyed window 后 message 的 target state owner 属于 window lifecycle，target identity validation 属于 future handle table / generation。
- 第一阶段继续 single-window。
- handle table / generation 现在不做；只有进入 public handle、多窗口、target update 或 async UI message targeting 时才必须同步打开。
- 第一刀不定义 public runtime API。
- 当前不创建 package / build config。
- self-drawn 不等于 global tick，也不等于可以跳过 IME / Accessibility future slots。

当前没有自动开启的 runtime implementation。

下一步推荐 docs-only：

> `P1 window lifecycle surface execution card`
