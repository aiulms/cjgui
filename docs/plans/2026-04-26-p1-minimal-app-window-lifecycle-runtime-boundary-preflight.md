# P1 Minimal App / Window Lifecycle Runtime Boundary Preflight

日期：2026-04-26

性质：docs-only / runtime boundary preflight / no implementation

状态：完成；不批准直接实现

范围：冻结未来正式 runtime 的最小 app / window lifecycle 边界，只定义第一条 runtime opening 应该如何收窄。本轮不写 runtime 代码，不创建 runtime 目录，不修改 `labs/macos_bridge_smoke`，不新增 public C ABI / public runtime API。

## 1. 背景

本轮依据：

- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 frame hash verification evidence line closure / runtime pivot preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)
- [P1 main-thread UI message queue closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
- [P1 AppKit / Metal bridge boundary cleanup closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [P0 macOS bridge smoke closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [GUI thinking framework](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)

上一轮已经冻结：`labs/macos_bridge_smoke` 继续只是实验室 smoke，不是正式 runtime。smoke 的经验可以迁移为约束，但目录、C ABI、全局状态、auto-close、clear-color render path、diagnostics 和 harness 不能直接升格。

本轮进一步冻结：如果要进入正式 runtime 线，第一条 opening 只能讨论 minimal app / window lifecycle，不能顺手进入 Renderer / Scene / Widget / Layout / DSL。

## 2. Future Runtime App Owner

future runtime app owner 应是未来正式 runtime 的 app lifecycle module，而不是 `labs/macos_bridge_smoke`、不是 smoke bridge context，也不是仓颉示例入口。

该 owner 未来需要负责：

- runtime init。
- macOS main-thread event loop ownership。
- app run / request quit / shutdown 的状态机。
- app-level error boundary。
- app-level shutdown 后资源释放顺序。

当前不实现该 owner，也不创建目录。下一步 execution card 必须先冻结 owner 名称、模块位置和 public / internal 边界。

## 3. Future Runtime Window Lifecycle Owner

future runtime window lifecycle owner 应是未来正式 runtime 的 window lifecycle module。它可以调用平台 bridge，但不能把平台 bridge 自身当成 owner。

该 owner 未来需要负责：

- create window。
- request close。
- destroy / release。
- destroyed / stale handle guard。
- close / destroy 幂等。
- window lifecycle 与 app shutdown 的关系。

平台 bridge 可以持有 `NSWindow`、`NSView`、`CAMetalLayer` 等对象，但这些对象只属于 internal platform layer，不能成为仓颉公共层的 owner。

## 4. Main-thread Event Loop / Queue Owner

main-thread event loop / queue 的 owner 应归 future app lifecycle runtime。原因：

- macOS AppKit event loop 必须在主线程拥有。
- window lifecycle 操作必须经主线程 owner 调度。
- 后台任务、async runtime、Agent action 未来更新 UI 必须进入主线程 queue / drain。

当前 smoke 的 main-thread lifecycle queue 只证明了单实例 `RequestClose` 可以经由 post / drain 进入 close / destroy。它不能直接成为正式 runtime queue，也不能支持通用 UI update、target update、多窗口或 handle generation。

## 5. 是否允许复用 Smoke C ABI

不允许直接复用 smoke 的 C ABI 作为 future runtime public API。

原因：

- `cjgui_app_run()` 当前绑定单窗口、单实例、AppKit event loop、clear-color render path 和 smoke diagnostics。
- `cjgui_last_error_*()` 当前只是实验期全局 last-error 观察口，不适合多窗口、异步调用或并发 runtime。
- 当前 bridge context 持有平台对象和单实例全局状态，不是长期 public API 形态。
- 当前 screenshot / frame hash / readback diagnostics 都是 smoke evidence，不是 runtime contract。

future runtime 可以学习 smoke C ABI 的经验，但必须另行冻结新的 API 边界。

## 6. 是否允许复用 Smoke 目录

不允许直接复用 `labs/macos_bridge_smoke` 作为 runtime 目录。

`labs/macos_bridge_smoke` 应继续作为 smoke guard 和 lab evidence。future runtime 如果要创建目录，必须另开 execution card 明确：

- 新目录路径。
- module owner。
- public API 边界。
- internal bridge 边界。
- tests / examples / smoke guard 的关系。

本轮不创建目录。

## 7. 是否允许直接暴露平台对象

不允许。

future runtime public layer 不应暴露：

- `NSWindow*`
- `NSView*`
- `CAMetalLayer*`
- `MTLDevice*`
- `MTLCommandQueue*`
- Objective-C `id`
- `CGImageRef`
- `NSEvent*`
- 任何 AppKit / Metal / CoreGraphics 平台对象裸指针

平台对象只能留在 internal bridge / platform layer。仓颉公共层未来最多接触脱水 handle、结构化结果、状态枚举和错误对象。

## 8. Create / Close / Destroy 最小 Contract

future runtime 最小 contract 倾向如下。

App lifecycle：

- `init`：创建 runtime app state，确认主线程 owner。
- `run`：进入或驱动 event loop。
- `request quit`：请求 app 退出，不直接硬销毁平台对象。
- `shutdown`：释放 app-level 资源，拒绝后续 stale message。

Window lifecycle：

- `create window`：返回受控 runtime handle，不暴露平台对象。
- `request close`：只提交 close request，必须由主线程 owner drain。
- `destroy / release`：进入单一销毁路径，必须幂等。
- `stale handle guard`：destroyed 后消息必须丢弃或返回分类错误，不能复活窗口。

第一刀不应把 app run、event loop、window create 全部糊成一个 smoke-style API。它们应先被拆成 future slots，再由 execution card 决定第一刀实现哪些。

## 9. Window Handle / Generation

future runtime 需要 handle table / generation，但第一刀可以不实现，前提是保持 single-window 且不暴露长期 public handle。

为什么未来需要：

- destroyed window 需要 stale guard。
- 多窗口需要 target validation。
- async message 需要确认目标仍然有效。
- 旧 handle 不能命中新创建的窗口。

为什么第一刀可以暂不实现：

- 当前下一步仍只是 boundary preflight / execution card。
- future implementation first slice 应继续极窄，最多创建最小 skeleton / app-window lifecycle surface。
- 如果 first slice 仍是 single-window internal runtime skeleton，且没有 public handle、没有 target update、没有多窗口，则可先记录 handle table / generation 为 future slot。

如果任何 future card 允许 public window handle、多窗口、target update 或 async UI message，则必须同步实现最小 handle / generation validation。

## 10. Destroyed / Stale Handle 处理

destroyed / stale handle 的原则：

- close / destroy 后，window state 必须进入 terminal state。
- 已销毁 window 不能被 stale message 复活。
- 对 destroyed handle 的操作应返回结构化错误或被安全丢弃，具体策略由 future execution card 冻结。
- close request、manual close、app quit、future async close 必须汇入同一 lifecycle 状态机。
- stale message 不能直接访问平台对象。

当前只能冻结原则，不实现 handle table、generation 或 runtime error object。

## 11. Single-window / Multi-window 边界

第一刀应继续 single-window。

原因：

- 当前 smoke 只验证单窗口。
- 多窗口会立即要求 handle table / generation、target routing、window owner map、event dispatch 和 resource ownership。
- 在 app/window lifecycle owner 未冻结前打开多窗口，会让 runtime skeleton 扩面。

multi-window 应作为 future slot。它不能被单窗口 first slice 暗中承诺，也不能让单窗口 smoke 假设升级为长期 runtime 事实。

## 12. App Run / Event Loop / Window Create 的 API 形态

不应先把它们定义成一个 public API。

当前应拆成 future slots：

- app init / runtime context。
- event loop ownership / run。
- window create。
- window request close。
- window destroy / release。
- app request quit / shutdown。

下一张 execution card 可以授权最小 runtime skeleton / app-window lifecycle surface，但必须明确哪些 slot 只是文档化占位，哪些允许实现。

## 13. Error Return Strategy

smoke `last_error` 只能迁移为经验，不能直接扩展成 runtime 错误系统。

原因：

- 全局 last-error 无法可靠表达并发、异步、多窗口、多调用方的错误关联。
- last-error 容易被后续调用覆盖。
- async message 的失败需要绑定 request / target / generation / state。
- recoverable、degraded、fatal 需要结构化分类，而不是裸字符串。

future runtime error strategy 应倾向：

- 调用关联的结构化结果。
- 明确错误 category / code / message / recoverability。
- 非全局、并发安全。
- 对 stale handle、destroyed target、wrong thread、capability missing、platform failure 有明确分类。

本轮不设计具体错误类型，不新增 public API。

## 14. Smoke Guard 的定位

smoke guard 继续用于验证旧链路不退化。

它可以继续证明：

- build / run 仍可执行。
- bridge init / Metal capability / first frame / lifecycle / auto-close 仍成立。
- main-thread `RequestClose` smoke path 仍可用。
- screenshot / frame hash 线仍作为 smoke evidence 和 negative guard。

它不能成为正式 runtime test framework。future runtime tests 必须另开 preflight，回答测试 owner、source truth、CI / headless、artifact、baseline 和 API coverage。

## 15. First Runtime Slice 是否包含 Renderer / Scene / Widget / Layout

不包含。

future runtime 第一刀不应包含：

- Renderer。
- Scene。
- Widget。
- Layout。
- DSL。
- Text / Input / IME / Accessibility。
- pixel diff / baseline / offscreen renderer。
- cross-platform abstraction。
- AI semantic tree / Action Router。

原因：app/window lifecycle 是这些能力的底座。先做高层会让入口层反逼执行层。

## 16. 是否需要 Execution Card 才能创建 Runtime 目录

需要。

创建 runtime 目录本身就是架构动作，因为它会定义：

- 目录 owner。
- public / internal 边界。
- build entry。
- module naming。
- tests 和 examples 位置。
- smoke guard 与正式 runtime 的关系。

因此必须先创建 docs-only execution card，再允许创建 runtime directory 或任何 skeleton。

## 17. 下一步应该是 Execution Card 还是继续 Preflight

结论：下一步可以创建 docs-only execution card。

推荐下一篇：

> `P1 minimal app/window lifecycle runtime execution card`

该 execution card 必须极窄。未来 implementation first slice 最多只能创建最小 runtime skeleton / app-window lifecycle surface，并且仍不得进入 Renderer / Scene / Widget / Layout / DSL。

如果 execution card 发现新 runtime 目录、API 命名、handle strategy 或 error strategy仍无法收束，则必须停止在 docs-only，不得自动进入实现。

## 18. 本轮 Stop-line

本轮强制保持：

- 不写 runtime 代码。
- 不创建 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 harness。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现 app lifecycle。
- 不实现 window lifecycle。
- 不实现 handle table / generation。
- 不实现 renderer / scene / widget / layout / DSL。
- 不做跨平台抽象。
- 不做文本 / 输入法 / 无障碍。
- 不做 pixel diff / baseline / offscreen renderer。
- 不引入 AI semantic tree / Action Router。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 19. 结论

第一条正式 runtime opening 应只聚焦：

> `minimal app/window lifecycle runtime slice`

当前结论：

- future runtime app owner 应属于未来正式 runtime app lifecycle module。
- future runtime window owner 应属于未来正式 runtime window lifecycle module。
- main-thread event loop / queue owner 应归 future app lifecycle runtime。
- smoke C ABI 不能直接升格为 public runtime API。
- smoke 目录不能直接复用为 runtime 目录。
- 平台对象不能直接暴露给仓颉公共层。
- 第一刀倾向 single-window，并把 multi-window、handle table / generation、target update 作为 future slot。
- smoke `last_error` 只能迁移为错误策略经验，不能直接扩展。
- smoke guard 继续作为旧链路防退化证据，不是正式 runtime test framework。
- Renderer / Scene / Widget / Layout / DSL 不属于第一刀。
- 创建 runtime 目录前必须先有 execution card。

当前没有自动开启的 runtime implementation。

下一步推荐 docs-only：

> `P1 minimal app/window lifecycle runtime execution card`
