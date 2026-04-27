# P1 Error Strategy Boundary Preflight

日期：2026-04-26

性质：docs-only / error strategy boundary preflight / no implementation

状态：完成；不批准直接实现

范围：复核 platform adapter surface comment-only refinement 已完成之后，冻结 future runtime error strategy 的 owner、边界、`last_error` 迁移口径、最小错误分类、diagnostics 与 state truth 的关系。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不新增 package / build config，不定义 public runtime API 或 public C ABI。

## 1. 背景

本轮依据：

- [P1 platform adapter surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)
- [P1 platform adapter boundary execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)
- [P1 platform adapter boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)
- [P1 window lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 app lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 AppKit / Metal bridge boundary cleanup closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [P1 main-thread UI message queue closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

当前 runtime skeleton 中 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj) 仍是 comment-only placeholder。它只记录 smoke `last_error` 不能直接迁移，future runtime errors 必须调用关联、结构化、非全局、并发安全。

本轮只冻结 error strategy boundary，不定义 concrete type，不写行为。

## 2. Future Error Strategy 的 Owner

future error strategy 的 owner 应属于：

> `runtime/cjgui` error strategy module

当前对应 comment-only placeholder：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

该 owner 未来负责冻结：

- 错误分类语义。
- 错误与调用 / operation 的关联方式。
- 错误与 app lifecycle / window lifecycle / platform adapter 的交界。
- 哪些错误可返回给 core policy。
- 哪些错误必须 fail closed。
- 哪些 degraded 状态允许继续，但必须暴露 diagnostics。
- logs / harness / AI diagnostics 如何消费错误，而不成为第二状态真相源。

该 owner 不应成为：

- app lifecycle state owner。
- window lifecycle state owner。
- platform object owner。
- public C ABI owner。
- Renderer / Scene / Widget / Layout owner。
- logging framework owner。

本轮只冻结 owner 倾向，不实现 owner。

## 3. Error Strategy 与 App Lifecycle 的边界

app lifecycle 未来拥有 app-level policy 和 state transition，例如 init、run、request quit、shutdown、queue acceptance 和 shutdown 后 late message policy。

error strategy 未来不拥有这些 state transition。它只应为 app lifecycle 提供结构化错误 / diagnostics 边界，例如：

- platform readiness failure。
- repeated run request。
- run while shutting down。
- shutdown transition failure。
- late message after shutdown。
- queue drain failure。
- invalid app lifecycle call order。
- wrong-thread request summary。

app lifecycle 应决定：

- 某个错误是否推进 app state。
- 某个错误是否导致 request quit / shutdown。
- degraded app state 是否仍能继续接受请求。

error strategy 应决定：

- 错误如何分类。
- 错误是否可恢复、降级或必须 fail closed。
- 错误如何与调用或 operation 关联。
- diagnostics 如何被 harness / AI 读取。

边界：

```text
app lifecycle owns app state and policy
error strategy classifies failures and diagnostics
error strategy does not become app state truth
```

## 4. Error Strategy 与 Window Lifecycle 的边界

window lifecycle 未来拥有 window-target state，例如 create requested、created / failed、close requested、closing、destroyed、release completed 和 stale target classification。

error strategy 不拥有 window state。它只应为 window lifecycle 提供错误分类和 call-associated failure summary，例如：

- create window failed。
- close after destroyed。
- duplicate close request。
- destroy before create。
- release failed。
- stale close request。
- stale window message。
- invalid target identity。
- future generation mismatch。

window lifecycle 应决定：

- destroyed 是否 terminal。
- stale message 是否 discard、classify 或 escalate。
- failed create 是否留下 target state。
- release failed 是否允许 retry 或必须 fail closed。

error strategy 应决定：

- stale handle / stale message 如何被分类。
- invalid usage / contract violation 与 platform failure 如何区分。
- 哪些 target-related failure 可以返回给调用方，哪些只能写入 diagnostics。

边界：

```text
window lifecycle owns target state
error strategy classifies target-related failures
error strategy does not resurrect or mutate window state by itself
```

## 5. Error Strategy 与 Platform Adapter 的边界

platform adapter 未来可以在 adapter / bridge 内部持有 AppKit / Metal / CoreGraphics / Objective-C 平台对象，也可以持有 native error objects 或 platform-specific failure details。

error strategy 不应把这些 native details 泄露到 core public surface。platform adapter 应向 core 输出脱水 failure summary，例如：

- platform capability missing。
- platform initialization failed。
- platform object create failed。
- platform callback rejected。
- platform release failed。
- platform permission unavailable。
- platform main-thread execution failed。
- degraded platform mode。

platform adapter 内部边界可以保留：

- native error object。
- platform object identity。
- OS-specific error code。
- AppKit / Metal / Objective-C callback context。
- runloop / delegate / dispatch details。

core / error strategy 可消费：

- category。
- severity。
- operation。
- target summary if approved。
- recoverability / degraded status。
- sanitized message。
- diagnostics key / code after future policy approval。

边界：

```text
platform adapter owns native failure details
error strategy owns dehydrated classification
core does not own platform error objects
```

## 6. Smoke `last_error` 可以迁移什么

smoke bridge 的 `last_error` 经验可以迁移为这些原则：

- bridge / adapter 需要可观察错误边界。
- platform readiness / failure 不能静默吞掉。
- capability missing、recoverable、degraded 和 fatal 需要区分。
- 错误要能被 smoke guard / harness 记录。
- C / Objective-C 边界需要参数、状态和 capability 检查。
- 错误消息需要脱水，不能泄露平台对象。

可以迁移的是“需要结构化错误边界”的经验，不是 `last_error` 的具体形态。

## 7. Smoke `last_error` 不能迁移什么

不能迁移：

- 全局 mutable `last_error`。
- smoke C ABI 的 `last_error` 函数形态。
- 与单实例 smoke state 绑定的错误语义。
- 无调用关联的“最近一次错误”模型。
- 无并发安全的共享错误槽。
- 无 window target / app operation / generation 关联的错误模型。
- 把错误字符串当成 runtime state truth。
- 把 smoke diagnostics 字段当成 public runtime API。

`last_error` 不能直接升格为长期并发错误系统，因为：

- 多线程 / async request 下，global last-error 会被后续调用覆盖。
- 多窗口 / future handle 下，global last-error 无法表达 target identity。
- queue / drain 下，错误产生点和消费点可能不在同一调用栈。
- platform adapter 内部错误与 app / window policy failure 需要区分。
- global string slot 容易成为第二真相源。
- AI / harness 读取 last-error 时可能误把 diagnostics 当 state。

## 8. Future Runtime Error 的基本形态

结论：future runtime error 应该是：

- 结构化。
- 调用关联。
- 非全局。
- 并发安全。
- 可脱水给 logs / harness / AI。
- 不泄露平台对象。
- 不成为第二状态真相源。

但本轮不定义：

- error enum。
- Result type。
- exception-like mechanism。
- public runtime API。
- public C ABI。
- concrete serialization format。

原因：

- app lifecycle / window lifecycle / platform adapter 仍未实现。
- package / build boundary 未打开。
- public handle / generation 未冻结。
- concrete language-level API 会过早固化。
- 本轮只需要冻结语义边界。

## 9. 最小错误分类语义

以下分类是 future semantic categories，不是 enum，不是 API。

### fatal

含义：

- 当前 operation 或 runtime state 已无法可信继续。
- ownership、platform object identity、memory safety、thread ownership 或 required capability 出现不可恢复问题。

处理倾向：

- fail closed。
- 不尝试伪恢复。
- 不让错误后的状态继续被当成正常 state truth。

### recoverable

含义：

- operation 失败，但 runtime / app / window owner 仍能保持一致状态。
- 调用方可以得到结构化失败并决定下一步。

处理倾向：

- 返回调用关联错误。
- 保持 state owner 不被错误对象替代。
- 不静默吞掉。

### degraded

含义：

- 能力下降或路径降级，但 runtime 仍可继续。
- 例如 capability 不完整、非关键 diagnostics 缺失、某个 optional path 不可用。

处理倾向：

- 必须暴露 degraded diagnostics。
- 不得伪装成 full success。
- degraded 不等于 silent ignore。

### invalid usage / contract violation

含义：

- 调用顺序、线程、target、生命周期状态或 future API contract 被违反。
- 例如 destroyed 后操作、shutdown 后 enqueue、非主线程直接 UI 操作、重复 run、未 init 就 run。

处理倾向：

- 默认 fail closed。
- 不因错误调用推进正常 state。
- 不自动修正调用方错误。

### platform capability missing

含义：

- 平台或设备缺少必需能力。
- 例如窗口系统、Metal device、command queue、screen capture permission、display capability 或 future backend capability 不满足。

处理倾向：

- 若是 required capability，fail closed。
- 若是 optional capability，进入 degraded，并明确 diagnostics。
- 不把 capability missing 写成 render / app logic failure。

### stale handle / stale message

含义：

- 操作指向已销毁、过期、generation mismatch 或已关闭的 target。
- 当前还没有 handle table / generation，本分类只作为 future trigger。

处理倾向：

- 默认 fail closed 或 discard-with-diagnostics。
- 不复活 destroyed target。
- 不把 stale message 当成当前有效请求。

## 10. 哪些错误属于 Platform Adapter 内部边界

以下错误首先属于 platform adapter / bridge 内部边界：

- native object create / retain / release failure。
- AppKit / Metal / CoreGraphics / Objective-C callback conversion failure。
- platform runloop / delegate / callback ordering failure。
- platform main-thread execution failure。
- platform capability probing failure。
- display / scale / visibility observation failure。
- platform permission / environment unavailable。
- native error object mapping failure。

这些错误可以被 adapter 脱水后交给 core，但 native details 不应进入 core public surface。

## 11. 哪些错误应返回给 App / Window Lifecycle

app lifecycle 应接收：

- platform readiness failed。
- app init / run / shutdown operation failed。
- quit request rejected / failed。
- queue drain requested / failed / stale。
- late message after shutdown。
- invalid app-level call order。

window lifecycle 应接收：

- create window failed。
- close requested but target invalid。
- close after destroyed。
- destroy / release failed。
- stale window message。
- platform window state observation failed。
- future handle / generation mismatch。

返回给 lifecycle 的应是脱水 summary，不是 platform object、native error object、raw event 或 callback identity。

## 12. 哪些错误必须 Fail Closed

以下情况必须 fail closed：

- platform object ownership 不清。
- native handle / platform object identity mismatch。
- destroyed target 被再次操作。
- stale handle / stale message 无法安全归属。
- required capability missing。
- operation 违反生命周期 contract。
- 非主线程直接操作 platform UI resource。
- native error detail 无法可靠脱水。
- failure category unknown 且可能影响 state truth 或资源生命周期。
- FFI / native boundary 返回不可信状态。

fail closed 不等于进程一定崩溃。它表示不能继续把该 operation 当作成功，也不能默默推进正常 state。

## 13. 是否允许静默吞错

默认不允许。

例外只能是明确的 degraded diagnostics，且必须满足：

- degraded 不改变 state truth。
- degraded 不隐藏 required capability failure。
- degraded 不影响资源生命周期。
- degraded 会被记录为 diagnostics。
- degraded 不伪装成 full success。

任何影响 app state、window state、platform object lifecycle、main-thread ownership、future handle identity 的错误都不能静默吞掉。

## 14. Error Diagnostics 与 AI / Harness / Logs 的关系

future diagnostics 可以服务：

- human debugging。
- smoke guard / harness assertions。
- AI execution evidence。
- closure review。
- capability / degraded 状态观察。

但 diagnostics 不能成为：

- app lifecycle state owner。
- window lifecycle state owner。
- platform adapter truth。
- public runtime API。
- 第二状态真相源。
- AI Action Router 绕过 owner 的入口。

正确口径：

```text
owner state is truth
error diagnostics describe failed operations
logs and harness consume diagnostics
diagnostics do not mutate state by themselves
```

AI 可以读取错误 diagnostics 来汇总 evidence、提出风险和建议，但不能用日志字符串代替 runtime owner 的真实状态。

## 15. 如何避免 Error Strategy 成为第二状态真相源

必须保持：

- error 只描述一个 operation 的失败或降级，不拥有系统状态。
- error 需要关联 operation / call / future target summary，而不是全局“当前错误”。
- app / window / adapter owner 决定状态推进。
- diagnostics 是 observation，不是 truth。
- failure summary 不应缓存并驱动后续行为，除非 owner 明确接收并更新 state。
- 错误分类不能反向发明 runtime 能力。

如果未来引入 error history / telemetry，也必须另开 preflight，避免 error log 变成隐藏状态机。

## 16. 是否现在定义 Public API / C ABI / Enum / Result

答案：不定义。

本轮不定义：

- public runtime API。
- public C ABI。
- error enum。
- Result type。
- exception-like mechanism。
- error serialization。
- stable diagnostics field。

原因：

- current runtime skeleton 仍是 comment-only。
- app / window lifecycle 还没有真实 behavior。
- platform adapter 还没有真实 behavior。
- handle table / generation 还没有打开。
- package / build boundary 未打开。
- 过早定义类型会反向固化 runtime 入口层。

下一张 execution card 也只能授权 comment-only / documentation-level surface refinement。

## 17. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error type / error enum / Result type。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
- 不实现 platform adapter。
- 不实现 handle table / generation。
- 不迁移 smoke `last_error`。
- 不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 18. 是否应该创建 Execution Card

结论：下一步可以创建 docs-only execution card，但不能自动进入实现。

推荐下一篇：

> `P1 error strategy boundary execution card`

范围只能是：

- 将本 preflight 收束为受限 execution card。
- 未来 first slice 最多只能做 comment-only / documentation-level error strategy surface refinement。
- 未来 first slice 最多只能修改 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj) 和 / 或 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 的 error strategy section。
- future closure review。
- plans README。
- GUI task tracker。

不得授权：

- concrete error type。
- error enum。
- Result type。
- exception-like mechanism。
- public runtime API。
- public C ABI。
- package / build config。
- real error behavior。
- app lifecycle implementation。
- window lifecycle implementation。
- platform adapter implementation。
- handle table / generation。
- smoke `last_error` migration。
- smoke C ABI reuse。
- Renderer / Scene / Widget / Layout / DSL。
- global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 19. 结论

error strategy boundary 应先冻结，但仍不实现。

当前结论：

- future owner 属于 `runtime/cjgui` error strategy module。
- smoke `last_error` 只能作为经验，不能迁移为 runtime 并发错误系统。
- future runtime errors 应调用关联、结构化、非全局、并发安全。
- error strategy 应服务 app lifecycle、window lifecycle 和 platform adapter，但不能成为第二状态真相源。
- fatal、recoverable、degraded、invalid usage / contract violation、platform capability missing、stale handle / stale message 是需要保留的最小语义分类。
- 默认不允许静默吞错；只有明确 degraded diagnostics 才能继续。
- 当前不定义 public API，不定义 enum / Result type，不写任何行为。

当前没有自动开启的 runtime implementation。

下一步推荐 docs-only：

> `P1 error strategy boundary execution card`
