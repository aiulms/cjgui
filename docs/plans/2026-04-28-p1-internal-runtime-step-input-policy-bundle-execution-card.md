# P1 Internal Runtime Step Input Policy Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W2 internal behavior bundle

authority：

- [2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md) 中 helper 链封账后提高实现粒度规则
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md) 中 W2 internal behavior bundle 规则

## Goal

授权下一轮一次完成 `P1 internal runtime step input policy bundle implementation`。

本 bundle 不再拆成多个 one-helper slices，而是一次覆盖完整 internal runtime step input / policy / decision 概念切片。

目标：

- 在 `runtime_state.cj` 内新增 internal step input、policy、decision 类型。
- 新增 default input / policy builders。
- 新增 step decision function。
- 新增 step-with-input-policy function。
- 新增最多 2-3 个与本 bundle 行为直接相关的 sanity / parity helpers。
- 同步更新 README、tracker、plans README，并新增 bundled closure。

## Context Loading Budget

本卡创建时读取 8 个最小上下文文件，原因是本轮是 W2 authorization，需要同时确认当前 closure、runtime owner、治理规则、执行卡模板和上下文装载策略：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md)
- [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)

下一轮 implementation 默认只需读取 tracker、本执行卡、`runtime_state.cj`、`runtime/cjgui/README.md` 与必要前置 closure；除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不应继续扩展为新的 docs-only 卡。

## Authorized Implementation Scope

### 1. Internal Step Input Type

在 `runtime_state.cj` 新增默认 internal `CjguiInternalRuntimeStepInput`。

允许字段：

- `allowsAdvance: Bool`
- `hasExternalWork: Bool`

要求：

- 提供默认构造。
- 提供带参构造。
- 该 input 只表达 internal step 输入事实，不代表 event loop、queue / drain 或 platform callback。

### 2. Internal Step Policy Type

新增默认 internal `CjguiInternalRuntimeStepPolicy`。

允许字段：

- `requiresRuntimeReady: Bool`
- `requiresInputAllowsAdvance: Bool`

要求：

- 提供默认构造。
- 提供带参构造。
- policy 只表达 internal step 决策规则，不代表 public runtime contract。

### 3. Internal Step Decision Type

新增默认 internal `CjguiInternalRuntimeStepDecision`。

允许字段：

- `shouldAdvance: Bool`
- `isBlockedByRuntimeNotReady: Bool`
- `isBlockedByInput: Bool`

要求：

- 提供 constructor shape。
- decision 只表达脱水 decision summary，不改变 runtime state。

### 4. Default Builders

新增默认 internal builders：

- `cjguiInternalDefaultRuntimeStepInput()`
- `cjguiInternalDefaultRuntimeStepPolicy()`

默认值应服务于现有 ready sanity path：默认 root state + 默认 input + 默认 policy 应允许 advance。

### 5. Decision Function

新增默认 internal function：

```cj
func cjguiInternalDecideRuntimeStep(
    state: CjguiInternalRuntimeRootState,
    input: CjguiInternalRuntimeStepInput,
    policy: CjguiInternalRuntimeStepPolicy
): CjguiInternalRuntimeStepDecision
```

行为建议：

- 如果 `policy.requiresRuntimeReady == true` 且 `state.isRuntimeReady == false`，标记 `isBlockedByRuntimeNotReady = true`。
- 如果 `policy.requiresInputAllowsAdvance == true` 且 `input.allowsAdvance == false`，标记 `isBlockedByInput = true`。
- 只有未被阻塞时 `shouldAdvance = true`。
- 如果 runtime not ready 和 input disallow 同时成立，可以同时标记两个 blocker，且 `shouldAdvance = false`。
- 不改变 state。
- 不运行 event loop。
- 不消费真实 queue。

### 6. Step With Input / Policy

新增默认 internal function：

```cj
func cjguiInternalRuntimeStepWithInput(
    state: CjguiInternalRuntimeRootState,
    input: CjguiInternalRuntimeStepInput,
    policy: CjguiInternalRuntimeStepPolicy
): CjguiInternalRuntimeStepResult
```

行为建议：

- 调用 `cjguiInternalDecideRuntimeStep(state, input, policy)`。
- 返回原 state。
- `didAdvance = decision.shouldAdvance`。

保留既有 `cjguiInternalRuntimeStep(state)` 行为不变；如需说明，可在 README 中称它是 legacy / simple internal step。

### 7. Sanity / Parity Checks

允许新增少量默认 internal sanity helpers，最多 2-3 个，且必须直接服务于本 bundle 行为：

- default root state + default input + default policy 会 advance。
- not-ready state 会 fail closed。
- disallow input 会 fail closed。

不要继续扩成 helper-by-helper 链。

### 8. Docs / Tracker / Closure

下一轮 implementation 允许更新：

- [runtime/cjgui/src/runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md)

## Forbidden

- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不实现 event loop / callback binding / queue / drain。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不新增 public runtime API。
- 不新增 public C ABI。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`。
- 不改变 existing root / bootstrap / readiness / platform / app / window state shape。
- 不改变 existing `cjguiInternalRuntimeStep(state)` 行为，除非只是在 README 中说明它是 legacy / simple internal step。

## Verification

implementation 完成后必须运行：

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
cjpm build --target-dir /tmp/cjgui-runtime-step-input-policy-bundle-target --skip-script
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
git diff --check
```

还必须检查 forbidden 文件未改：

- `runtime/cjgui/cjpm.toml`
- `labs/macos_bridge_smoke`
- harness
- native bridge
- 仓颉入口

closure 必须能从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。

## Next Implementation Expectation

下一轮默认进入：

- `P1 internal runtime step input policy bundle implementation`

下一轮必须一次完成上述完整 W2 internal behavior concept slice，不再拆成多个 one-helper slices。

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，下一轮不得继续创建新的 preflight / execution card 替代实现。
