# P1 Internal Runtime Step Input Policy Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-step-input-policy-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-execution-card.md)

## Closed Scope

本轮一次完成 W2 internal behavior concept slice，没有拆成 one-helper slices。

已新增默认 internal types：

- `CjguiInternalRuntimeStepInput`
- `CjguiInternalRuntimeStepPolicy`
- `CjguiInternalRuntimeStepDecision`

已新增默认 internal functions：

- `cjguiInternalDefaultRuntimeStepInput()`
- `cjguiInternalDefaultRuntimeStepPolicy()`
- `cjguiInternalDecideRuntimeStep(state, input, policy)`
- `cjguiInternalRuntimeStepWithInput(state, input, policy)`

已新增直接相关 sanity helpers：

- `cjguiInternalRuntimeStepInputPolicyReadySanity()`
- `cjguiInternalRuntimeStepInputPolicyNotReadyBlockedSanity()`
- `cjguiInternalRuntimeStepInputPolicyInputBlockedSanity()`

## Behavior Summary

- default input 为 `allowsAdvance=true`、`hasExternalWork=false`。
- default policy 要求 runtime ready，也要求 input allows advance。
- decision function 先检查 runtime readiness blocker，再检查 input blocker。
- step-with-input-policy 原样返回输入 root state，并用 `decision.shouldAdvance` 作为 `didAdvance`。
- 既有 `cjguiInternalRuntimeStep(state)` 行为保持不变。
- `hasExternalWork` 仍只是脱水 marker，不代表真实 queue、event loop 或 platform callback。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-step-input-policy-bundle-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

## Forbidden Boundary

- 未改变 existing root / bootstrap / readiness / platform / app / window state shape。
- 未改变 constructor shape、projection behavior、coordination behavior、bootstrap behavior 或既有 `cjguiInternalRuntimeStep(state)` behavior。
- 未新增 public runtime API 或 public C ABI。
- 未接入 AppKit / Metal / Objective-C。
- 未暴露 platform object / native handle / raw pointer。
- 未实现 event loop / callback binding / queue / drain。
- 未实现 app run / shutdown。
- 未实现 window create / close / destroy / release。
- 未新增 handle table / generation。
- 未修改 `cjpm.toml`、`labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。

## Next Opening

建议 next opening：

- `P1 internal runtime step input policy closure / next runtime behavior bundle decision`

下一步不应继续 helper-by-helper；应基于已落地的 input / policy / decision / step-with-input-policy，决定下一张更大的 internal runtime behavior bundle。
