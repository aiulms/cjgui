# P1 Internal Runtime Step Outcome Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W2 internal behavior bundle

authority：

- [2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md) 中 helper 链封账后提高实现粒度规则
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md) 中 W2 internal behavior bundle 规则

## Goal

授权下一轮一次完成 `P1 internal runtime step outcome bundle implementation`。

本 bundle 不再拆成 one-helper slices，而是一次完成 internal runtime step outcome / status 概念切片。

目标：

- 扩展 `CjguiInternalRuntimeStepResult` 的 internal-only outcome shape。
- 让 existing simple step 和 step-with-input-policy 都返回 didAdvance 与 blocked outcome。
- 保留当前 root / bootstrap / readiness / platform / app / window state shape。
- 不新增 public runtime API 或 public C ABI。
- 不实现 event loop、queue / drain、app run 或 window create。

## Context Loading Budget

本卡创建时读取 7 个最小上下文文件，原因是本轮是 W2 authorization，需要同时确认当前 closure、runtime owner、README surface 和治理规则：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md)
- [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)

下一轮 implementation 默认只需读取 tracker、本执行卡、`runtime_state.cj`、`runtime/cjgui/README.md` 与必要前置 closure；除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不应继续扩展为新的 docs-only 卡。

## Owner / Truth

owner：

- `runtime/cjgui/src/runtime_state.cj`

truth：

- `CjguiInternalRuntimeStepResult` 作为 internal runtime step outcome summary。
- `CjguiInternalRuntimeStepDecision` 仍是 step-with-input-policy 的 decision summary。

本 bundle 不改变 root state truth、bootstrap truth、app/window lifecycle truth 或 platform adapter truth。

## Authorized Implementation Scope

### 1. Extend Internal Step Result Shape

在 `CjguiInternalRuntimeStepResult` 中增加：

- `isBlocked: Bool`
- `isBlockedByRuntimeNotReady: Bool`
- `isBlockedByInput: Bool`

要求：

- 保留 `state: CjguiInternalRuntimeRootState`。
- 保留 `didAdvance: Bool`。
- 更新 constructor shape。
- 更新所有现有 internal call sites。
- 这仍是 internal-only shape，不构成 public API 或 public C ABI。

### 2. Update Existing Simple Step

更新 `cjguiInternalRuntimeStep(state: CjguiInternalRuntimeRootState): CjguiInternalRuntimeStepResult` 调用新 constructor。

行为保持等价：

- `didAdvance = state.isRuntimeReady`
- `isBlocked = !state.isRuntimeReady`
- 如果 blocked，`isBlockedByRuntimeNotReady = true`
- `isBlockedByInput = false`

不得改变该函数的 existing simple step 语义。

### 3. Update Step With Input / Policy

更新 `cjguiInternalRuntimeStepWithInput(state, input, policy): CjguiInternalRuntimeStepResult`。

要求：

- 调用现有 `cjguiInternalDecideRuntimeStep(state, input, policy)`。
- `didAdvance = decision.shouldAdvance`。
- `isBlocked = !decision.shouldAdvance`。
- `isBlockedByRuntimeNotReady = decision.isBlockedByRuntimeNotReady`。
- `isBlockedByInput = decision.isBlockedByInput`。
- 返回原 state。

### 4. Update Sanity Checks

现有 sanity helpers 应继续通过：

- ready/default path sanity
- not-ready blocked sanity
- input-blocked sanity

允许新增最多 2 个 outcome 直接相关 sanity helpers，例如：

- simple step not-ready outcome sanity
- step-with-input-policy blocked outcome parity sanity

不得继续扩成 helper-by-helper 链。

### 5. Docs / Tracker / Closure

下一轮 implementation 允许更新：

- [runtime/cjgui/src/runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [2026-04-28-p1-internal-runtime-step-outcome-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-outcome-bundle-closure-review.md)

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
- 不改变 root / bootstrap / readiness / platform / app / window state shape。
- 不改变 projection / coordination / bootstrap behavior。
- 不把 `hasExternalWork` 解释为真实 queue 或 platform event。

## Verification

implementation 完成后必须运行：

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
cjpm build --target-dir /tmp/cjgui-runtime-step-outcome-bundle-target --skip-script
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

- `P1 internal runtime step outcome bundle implementation`

下一轮必须一次完成完整 W2 internal outcome concept slice，不拆成 one-helper slices。

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，下一轮不得继续创建新的 preflight / execution card 替代实现。
