# P1 App Lifecycle Surface Boundary Preflight

日期：2026-04-26

性质：docs-only / app lifecycle surface boundary preflight / no implementation

状态：完成；不批准直接实现

范围：冻结 future app lifecycle surface 的 owner、truth、`init` / `run` / `request quit` / `shutdown`、main-thread queue / drain、platform adapter 驱动关系、shutdown 后 late message 处理和 no-global-tick 边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不新增 package / build config，不定义 public runtime API。

## 1. 背景

本轮依据：

- [P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)
- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 minimal app/window lifecycle runtime execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
- [P1 minimal app/window lifecycle runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- [P1 main-thread UI message queue closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
- 当前 runtime skeleton：
  - [runtime/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md)
  - [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
  - [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

上一轮已经确认：当前 runtime skeleton 可以封账，但它只是 comment-only architectural placeholder，不实现 runtime，不定义 public API，不迁移 smoke，不暴露平台对象。

本轮继续向内收窄：只冻结 app lifecycle surface 未来要回答的边界，不实现 app lifecycle，也不改当前 skeleton。

## 2. Future App Lifecycle Surface 的 Owner

future app lifecycle surface 的 owner 应属于：

> `runtime/cjgui` core app lifecycle module

也就是当前 comment-only skeleton 中 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 记录的 future owner 方向。

该 owner 未来应持有：

- 脱水 app lifecycle state。
- app-level init / run / request quit / shutdown 状态。
- app-level main-thread queue / drain policy。
- app shutdown 后 late message 的处理策略。
- app-level platform readiness / failure 的脱水结果。

它不应持有：

- AppKit runloop truth。
- Objective-C callback truth。
- `NSWindow` / `NSView` / `CAMetalLayer` 等平台对象。
- Renderer / Scene / Widget / Layout 状态。
- Text / Input / IME / Accessibility 状态。

本轮只冻结 owner 倾向，不写任何 owner 实现。

## 3. App Lifecycle 与 Platform Adapter 的关系

platform adapter 负责平台事实：

- AppKit event loop。
- 平台 callback。
- 平台 main-thread entry。
- 平台窗口对象和平台对象生命周期。
- 平台 readiness / failure 的原始观察。

app lifecycle core 负责脱水事实：

- app init / running / quit requested / shutting down / shutdown 状态。
- queue drain request。
- quit request。
- platform readiness / failure summary。
- app-level late message policy。

关系应表达为：

> platform adapter 可以驱动 core app lifecycle，但 core app lifecycle 不持有平台 runloop truth。

换句话说，platform adapter 可以把 AppKit callback 翻译成脱水的 lifecycle fact 或 queue drain request；core app lifecycle 只消费这些脱水事实，不把 AppKit 的 callback、runloop 或 dispatch 形态写成自己的 truth。

## 4. App Lifecycle 是否拥有 Main-thread Queue / Drain

结论：概念 owner 可以归 app lifecycle，但实际平台执行必须留在 platform adapter / bridge 内。

更精确地说：

- app lifecycle future surface 应拥有 main-thread queue / drain 的 policy owner。
- platform adapter future surface 应拥有“如何在平台主线程上触发 drain”的 execution owner。
- queue message payload 必须保持脱水，不允许携带平台对象。
- drain 必须发生在 platform main thread 上，但 core app lifecycle 只看到 `drain requested` / `drain executed` / `drain failed` 等脱水事实。

这避免两种错误：

- 把 main-thread queue 完全写成 AppKit runloop 细节。
- 让后台任务、async runtime 或 Agent action 直接触碰 UI / platform objects。

当前不实现 queue，不实现 drain，也不修改 smoke 中已封账的单实例 `RequestClose` queue。

## 5. Future Slot 的最小语义

以下只是 future slot 的最小语义，不是 API，不是实现。

### `init`

`init` 倾向表示：

- 创建或准备 app lifecycle state。
- 检查是否位于合法主线程或是否可以绑定主线程 owner。
- 接收 platform adapter 的 readiness / capability summary。
- 初始化 queue / shutdown policy 的内部状态。

`init` 不应：

- 创建 AppKit event loop。
- 创建 window。
- 创建 Renderer / Scene。
- 暴露平台对象。
- 直接调用 smoke C ABI。

### `run`

`run` 倾向表示：

- 进入或委托 platform adapter 驱动 app lifecycle。
- 将 app lifecycle 状态从 initialized 推进到 running。
- 定义 run 是否阻塞、是否可重复、是否允许 nested run 的 future question。

当前不决定 `run` 是 blocking、pump、step-driven 还是 adapter-driven。

`run` 不应被写成：

- AppKit `NSRunLoop` 的别名。
- `dispatch_main` 的封装。
- game-loop / global tick 的默认事实。
- window create 的隐式入口。

### `request quit`

`request quit` 倾向表示：

- 提交 app-level quit request。
- 幂等地把 app lifecycle 推向 quitting / shutting down。
- 让 manual quit、future async quit、platform close-all request 汇入同一 app-level path。

它不应：

- 直接释放 platform objects。
- 直接销毁 window。
- 直接绕过 main-thread queue / drain。

### `shutdown`

`shutdown` 倾向表示：

- app lifecycle 的 terminal transition。
- 拒绝或丢弃 shutdown 后 late message。
- 触发 app-level resource release policy。
- 与 window lifecycle 的 destroy / release path 对齐。

它必须是 future 幂等 contract 的候选项，但本轮不定义具体状态机。

### `drain main-thread queue`

`drain main-thread queue` 倾向表示：

- 在主线程上处理已提交的脱水 lifecycle message。
- 只允许处理经过 app lifecycle policy 接受的消息。
- 与 window lifecycle 协作处理 close / destroy / stale target。

它不应：

- 处理通用 UI update。
- 处理 target update。
- 携带平台对象。
- 在后台线程执行。
- 伪装成 Renderer frame loop。

## 6. App Lifecycle 是否允许持有 AppKit Runloop Truth

不允许。

app lifecycle core 不允许直接持有或暴露：

- `NSRunLoop`
- `NSEvent`
- `dispatch_main`
- Objective-C callback truth
- AppKit delegate callback identity
- 平台 object pointer 或 native handle

原因：

- 这些属于 macOS platform adapter / bridge 的内部事实。
- core runtime 如果持有它们，会把 AppKit event model 写进 runtime truth。
- 后续 Windows / Wayland / Linux backend 会被 macOS 语义污染。
- 这会违反“平台桥接向上接口极窄、脱水、可测试”的治理规则。

## 7. Platform Adapter 驱动 Core 的表达方式

推荐表达：

```text
platform adapter owns platform runloop / callbacks
platform adapter emits dehydrated lifecycle facts
core app lifecycle consumes dehydrated lifecycle facts
core app lifecycle never owns platform runloop truth
```

未来可讨论的脱水 fact 候选：

- `platform_ready`
- `platform_failed`
- `run_requested`
- `quit_requested`
- `queue_drain_requested`
- `queue_drain_completed`
- `shutdown_requested`
- `shutdown_completed`

这些候选不构成 API。若要进入代码，必须另开 execution card。

## 8. 是否在第一刀定义 Public Runtime API

默认不定义。

原因：

- 当前 skeleton 仍是 comment-only。
- app lifecycle owner、truth、slot 语义尚未经过 execution card 收束。
- build / package boundary 未冻结。
- window lifecycle 和 error strategy 仍未冻结。
- 任何 public API 都会很快被示例、测试和外部调用反向固化。

下一张 execution card 如果允许修改 runtime skeleton，也应优先保持 documentation-level / comment-only refinement，不应定义稳定 public runtime API。

## 9. 是否现在定义 Package / Build Boundary

不需要。

原因：

- 当前 `.cj` skeleton 没有非注释仓颉语法。
- app lifecycle surface 还不是 API。
- runtime module / package owner 未冻结。
- 没有 build entry、test entry 或 example entry。
- 过早创建 package / build config 会让 skeleton 看起来像可编译 runtime，从而制造假成熟感。

package / build boundary 应另开 future preflight，例如：

> `P1 runtime build / package boundary preflight`

前提应是 app lifecycle surface 至少已经由 execution card 明确允许写入何种非注释 skeleton 或 internal API。

## 10. App Lifecycle 与 Window Lifecycle 的边界

app lifecycle 应负责：

- app-level state。
- main-thread queue / drain policy。
- run / quit / shutdown。
- shutdown 后 late message policy。
- platform adapter readiness / failure 的 app-level接收。

window lifecycle 应负责：

- window create request。
- window request close。
- window destroy / release。
- window state。
- stale window token / destroyed target 判断。
- single-window / multi-window / handle generation 的 future boundary。

二者关系：

- app lifecycle 可以拥有 queue policy。
- window lifecycle 可以消费 queue drain 中的 window-targeted message。
- app shutdown 可以要求 window lifecycle 进入 close / destroy path。
- window destroyed / stale target 的细节不应塞进 app lifecycle；应由 window lifecycle 或 future handle table 返回脱水结果。

本轮不实现 window lifecycle，也不改 [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)。

## 11. App Lifecycle 与 Error Strategy 的边界

app lifecycle 应定义何处需要错误或 diagnostics：

- `init` 不合法。
- wrong thread。
- platform readiness failure。
- repeated / nested `run`。
- shutdown 后 late message。
- queue drain failure。
- quit request during invalid state。

error strategy 应定义错误的结构：

- 调用关联。
- 非全局。
- 并发安全。
- `fatal` / `recoverable` / `degraded` 或等价分类。
- 是否向 public surface 暴露。

app lifecycle 不应直接迁移 smoke `last_error`。`last_error` 只能作为实验期经验：它提醒我们需要可观察错误，但不能扩展成长期并发错误系统。

本轮不定义 concrete error type，也不修改 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)。

## 12. Auto-close / Manual-close / Future Async Message 竞态

future 原则：

- auto-close、manual-close、future async close / quit 都必须进入同一 app-level queue / lifecycle policy。
- 所有 UI-affecting lifecycle request 必须回到 main-thread queue / drain。
- close / quit request 只能推进状态机，不能直接释放平台对象。
- destroy / release 必须有单一路径和幂等约束。
- shutdown 后 late message 必须丢弃或分类，不能复活窗口。

app lifecycle 负责：

- 接收或拒绝 app-level request。
- 决定是否进入 draining / quitting / shutdown。
- 在 shutdown 后拒绝 late message。

window lifecycle 负责：

- 针对 window target 的 close / destroy / stale 判断。
- destroyed window 不能被 message 复活。

该原则来自已封账的 smoke main-thread queue，但不能直接复用 smoke queue 实现或 ABI。

## 13. Stale Message / Destroyed Window 的边界

stale message / destroyed window 不应完全放进 app lifecycle。

合理边界：

- app lifecycle 处理 app-level terminal state 和 queue acceptance。
- window lifecycle 处理 target window state。
- future handle table / generation 处理 target identity validation。
- error strategy 处理 stale / destroyed / wrong generation 的分类。

当前 app lifecycle surface 只应记录：

- shutdown 后 late message 不得执行。
- message payload 不得携带平台对象。
- app lifecycle 不负责复活或查找 destroyed window。

如果未来打开 multi-window、target update 或 public handle，就必须另开 handle table / generation execution card。

## 14. Handle Table / Generation 是否进入 App Lifecycle

默认不进入。

原因：

- handle table / generation 是 window target identity 问题，不是 app lifecycle 的第一责任。
- 当前 runtime skeleton 仍无 public handle。
- 当前不支持 multi-window。
- 当前不支持 target update message。
- 当前不支持 async target UI update。

何时需要：

- 出现 public window handle。
- 出现 multi-window routing。
- 出现 async target message。
- 出现 destroyed target 与新 target 复用 identity 的风险。
- 出现 target update / lifecycle message 需要精确投递。

届时应由 window lifecycle / handle table preflight 定义 owner，并与 app lifecycle queue policy 对齐。

## 15. Self-drawn Guardrails 吸收

app lifecycle surface 必须吸收 self-drawn guardrails：

- 不得默认 global tick。
- 不得默认 blind redraw。
- 不得把 frame loop 当成 app lifecycle 默认事实。
- 不得把 `run` 写成 render loop。
- 不得暗中打开 Dirty Rect / invalidation system。
- 不得暗中打开 Text / Input / IME / Accessibility。
- 不得把自绘解释为忽略 platform adapter、IME 坐标同步或 accessibility semantic bridge。

如果未来需要 redraw scheduling，应另开：

- `P1 redraw invalidation / dirty rect policy preflight`

如果未来需要 Text / Input / IME / Accessibility，应分别另开对应 preflight，不得混进 app lifecycle surface。

## 16. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle / event loop / run / shutdown。
- 不实现 main-thread queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
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

> `P1 app lifecycle surface execution card`

该 execution card 只能授权极窄的 comment-only / documentation-level surface refinement，例如：

- 在现有 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 中补充 future slot 注释。
- 在 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 中补充 app lifecycle owner / adapter boundary 文档。
- 新建 closure review。
- 更新 plans README 和 tracker。

它不得授权：

- 真实 runtime behavior。
- `init` / `run` / `shutdown` 实现。
- main-thread queue / drain 实现。
- package / build config。
- public runtime API。
- window lifecycle implementation。
- platform adapter implementation。
- Renderer / Scene / Widget / Layout / DSL。
- global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 18. 结论

app lifecycle surface 应该先冻结，但仍不实现。

当前结论：

- future app lifecycle owner 属于 `runtime/cjgui` core app lifecycle module。
- platform adapter 负责平台 event loop / callback / runloop truth。
- core app lifecycle 只接收脱水 lifecycle facts、queue drain request、quit request、platform readiness / failure。
- main-thread queue / drain 的 conceptual owner 可以归 app lifecycle，但实际平台主线程执行必须留在 platform adapter / bridge。
- 第一刀不定义 public runtime API。
- 当前不创建 package / build config。
- app lifecycle 不拥有 window target identity、stale handle validation 或 handle generation；这些属于 window lifecycle / future handle table。
- self-drawn 不等于 global tick，也不等于可以跳过 IME / Accessibility future slots。

当前没有自动开启的 runtime implementation。

下一步推荐 docs-only：

> `P1 app lifecycle surface execution card`
