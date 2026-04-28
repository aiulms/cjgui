# P1 Internal Runtime Cycle Request Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-step-outcome-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-outcome-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W2 internal runtime cycle request concept slice，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalRuntimeCycleRequest`
- `CjguiInternalRuntimeCycleResult`

新增默认 internal functions：

- `cjguiInternalDefaultRuntimeCycleRequest()`
- `cjguiInternalExecuteRuntimeCycle(request)`
- `cjguiInternalRuntimeCycleReadySanity()`
- `cjguiInternalRuntimeCycleNotReadyBlockedSanity()`
- `cjguiInternalRuntimeCycleInputBlockedSanity()`

## Behavior Summary

- cycle request 只组合 `state`、`input` 与 `policy`。
- cycle result 只聚合 request、step result 与 decision。
- default cycle request 只使用 root state builder、default step input 与 default step policy。
- cycle executor 只对 request 执行一次 decision 与 step-with-input-policy，并返回脱水 summary。
- cycle executor 不改变 request state，不循环，不消费 queue，不绑定 platform callback。
- 三条 cycle sanity 覆盖 default ready、runtime-not-ready blocked 与 input-blocked paths。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-cycle-request-bundle-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

## Stop-Line

- 未改变 `CjguiInternalRuntimeRootState` shape。
- 未改变 `CjguiInternalRuntimeStepResult` shape。
- 未改变 `CjguiInternalRuntimeStepInput` / `CjguiInternalRuntimeStepPolicy` / `CjguiInternalRuntimeStepDecision` shape。
- 未改变 existing step / decision / step-with-input-policy behavior。
- 未改变 bootstrap / readiness / platform / app / window type shape。
- 未改变 projection / coordination / bootstrap builder behavior。
- 未新增 public runtime API 或 public C ABI。
- 未接入 AppKit / Metal / Objective-C。
- 未暴露 platform object / native handle / raw pointer。
- 未实现 event loop / callback binding / queue / drain。
- 未实现 app run / shutdown。
- 未实现 window create / close / destroy / release。
- 未新增 handle table / generation。
- 未修改 `cjpm.toml`、`labs/macos_bridge_smoke`、harness、native bridge、仓颉入口、`src/main.cj` 或 `package_anchor.cj`。

## Next Opening

建议 next opening：

- `P1 internal runtime cycle request bundle closure / next runtime behavior bundle decision`

下一步应基于已落地的 cycle request / result 决定下一张更大的 internal runtime behavior bundle；不继续 helper-by-helper。
