# P1 Error Strategy Boundary Execution Card

日期：2026-04-26

性质：docs-only execution card / no implementation

状态：完成；创建本卡本身不等于实现；不自动开启 runtime implementation

## 0. Authority

本卡唯一 authority：

- [2026-04-26-p1-error-strategy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)

本卡只把上述 preflight 收束成受限 execution card。它不批准真实 runtime 行为，不批准 public API，不批准 error type，也不批准迁移 smoke `last_error`。

## 1. Goal

未来 first slice 最多只能做：

> error strategy surface 的 comment-only / documentation-level refinement

目标只能是把 error strategy 的 owner、边界、failure category、fail-closed policy、diagnostics 与 state truth 的关系写得更清楚。

未来 first slice 不得实现 error strategy，不得定义 concrete type，不得改变 runtime behavior。

## 2. Scope

未来 first slice 只允许：

- 细化 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj) 中的 comment-only boundary。
- 或轻量补充 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 中的 error strategy section。
- 新建对应 future closure review。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。

未来 first slice 不允许：

- 实现 error strategy。
- 定义 error enum / Result type / exception-like mechanism。
- 定义 public runtime API。
- 定义 public C ABI。
- 新增 package / build config。
- 迁移 smoke `last_error`。
- 复用 smoke C ABI。
- 把 diagnostics 当成第二状态真相源。

## 3. Future Write Set

未来 first slice 最大允许 write set：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- future closure review
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 first slice 不得修改其他 runtime 文件，除非另开新的 execution card。

## 4. Forbidden Write Set

未来 first slice 禁止修改：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [labs/macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- native bridge
- harness
- 仓颉 smoke 入口
- public runtime API
- public C ABI
- Renderer / Scene / Widget / Layout / DSL
- Dirty Rect / global tick / frame scheduler
- Text / Input / IME / Accessibility
- semantic tree / Action Router
- command-list hash / pixel diff / baseline / offscreen renderer
- `CJGUI_TRUTH_MANIFEST.md`

## 5. Future Surface Slots

未来 first slice 只能强化以下 comment-only slots。

### 5.1 Error Strategy Owner

future owner 属于：

> `runtime/cjgui` error strategy module

该 owner 只负责错误语义、分类、operation association、diagnostics 边界和 fail-closed policy。它不是 app state owner、window state owner、platform object owner、public API owner 或 logging framework owner。

### 5.2 App Lifecycle Relation

app lifecycle owns app state and policy.

error strategy 只能描述 app-level operation 的 failure / degraded diagnostics，例如 invalid app call order、platform readiness failure、shutdown 后 late message 或 queue drain failure。

error strategy 不得推进 app state，也不得成为 app lifecycle 的第二状态真相。

### 5.3 Window Lifecycle Relation

window lifecycle owns target state.

error strategy 只能描述 create / request close / destroy / release / stale target 相关 failure。destroyed target、stale close、stale message 或 future generation mismatch 的状态裁决属于 window lifecycle / future handle owner。

error strategy 不得复活 destroyed target，也不得自行改变 window target state。

### 5.4 Platform Adapter Relation

platform adapter owns native failure details.

adapter 可以在内部持有 native error object、platform object identity、OS-specific error code、AppKit / Metal / Objective-C callback context。

core / error strategy 只能消费脱水 summary，例如 category、severity、operation、recoverability、degraded status、sanitized message 或 future approved diagnostics code。

### 5.5 Smoke `last_error` Non-migration

smoke `last_error` 只能迁移这些经验：

- bridge / adapter 需要可观察错误边界。
- platform readiness / failure 不能静默吞掉。
- fatal / recoverable / degraded 需要区分。
- 错误要能被 smoke guard / harness 记录。

不能迁移：

- global mutable `last_error`。
- smoke C ABI 的 `last_error` 函数形态。
- 单实例 smoke state 绑定语义。
- 无调用关联的最近一次错误模型。
- 无并发安全的共享错误槽。
- 错误字符串作为 runtime state truth。

### 5.6 Future Error Shape

future runtime errors 应倾向：

- structured。
- call-associated。
- non-global。
- concurrency-safe。
- dehydrated for diagnostics。
- 不泄露平台对象。
- 不成为第二状态真相源。

本卡不授权定义 concrete shape、enum、Result type、exception-like mechanism、serialization 或 stable diagnostics field。

### 5.7 Minimal Categories

未来只允许作为 comment-only semantic categories 继续描述：

- fatal
- recoverable
- degraded
- invalid usage / contract violation
- platform capability missing
- stale handle / stale message

这些不是 enum，不是 API，不是 Result variant。

### 5.8 Fail-Closed Policy

未来 first slice 只能以注释强化 fail-closed policy。

以下类型必须继续被描述为 fail closed 倾向：

- platform object ownership 不清。
- native handle / platform object identity mismatch。
- destroyed target 被再次操作。
- stale handle / stale message 无法安全归属。
- required capability missing。
- operation 违反 lifecycle contract。
- 非主线程直接操作 platform UI resource。
- native error detail 无法可靠脱水。
- failure category unknown 且可能影响 state truth 或资源生命周期。

fail closed 不等于进程一定崩溃；它表示该 operation 不能伪装成成功，也不能默默推进正常 state。

### 5.9 Diagnostics Are Evidence, Not State Truth

future diagnostics 可以服务：

- human debugging。
- smoke guard / harness assertions。
- AI execution evidence。
- closure review。
- degraded / capability observation。

diagnostics 不能成为：

- app lifecycle state owner。
- window lifecycle state owner。
- platform adapter truth。
- public runtime API。
- 第二状态真相源。
- AI Action Router 绕过 owner 的入口。

正确边界：

```text
owner state is truth
error diagnostics describe failed operations
logs and harness consume diagnostics
diagnostics do not mutate state by themselves
```

## 6. Future Verification Requirements

如果未来 first slice 修改 `.cj` 文件，必须验证：

- `.cj` 仍为 comment-only。
- 没有非注释仓颉语法。
- 没有新增 package / build config。
- 没有 smoke C ABI reference。
- 没有 `last_error` API migration。
- 没有 public enum / Result type / function signature。
- diagnostics 没有被写成 state truth。
- 没有 platform object / raw pointer public surface。
- `git diff --check` 通过。
- closure review 可从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。

如果 future slice 仍是 comment-only，应在 closure review 记录：

```text
Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.
```

如可行，future slice 应运行旧 smoke guard：

```sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

该 smoke guard 只能证明旧 smoke 链路未退化，不是正式 runtime test framework。

## 7. Stop-Line For This Card Creation

本轮创建 execution card 已守住：

- 不修改 [runtime](/Users/jiangxuanyang/Desktop/cangjie/runtime)。
- 不修改 [labs/macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error strategy。
- 不定义 error enum / Result type / exception-like mechanism。
- 不迁移 smoke `last_error`。
- 不复用 smoke C ABI。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
- 不实现 platform adapter。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 8. Current Next Opening

当前 next opening 建议更新为：

> `P1 error strategy surface comment-only refinement first slice`

它不自动开启实现。

若用户明确批准，下一刀也只能按本卡做 `runtime/cjgui/src/error.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level refinement，不得写真实 error behavior、public API、enum、Result type、package / build config 或 smoke `last_error` migration。
