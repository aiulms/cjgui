# P1 Internal Runtime Cycle State Progress Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-cycle-request-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-cycle-request-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W2 internal runtime cycle progress concept slice，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

修改默认 internal type：

- `CjguiInternalRuntimeCycleResult`
  - 新增 `didProduceProgress: Bool`

更新默认 internal function：

- `cjguiInternalExecuteRuntimeCycle(request)`
  - 保持原有 decision + step-with-input-policy 流程。
  - 使用 `step.didAdvance` 派生 `didProduceProgress`。

更新默认 internal sanity helpers：

- `cjguiInternalRuntimeCycleReadySanity()`
- `cjguiInternalRuntimeCycleNotReadyBlockedSanity()`
- `cjguiInternalRuntimeCycleInputBlockedSanity()`

新增默认 internal sanity helpers：

- `cjguiInternalRuntimeCycleProgressReadySanity()`
- `cjguiInternalRuntimeCycleProgressBlockedSanity()`

## Behavior Summary

- `didProduceProgress` 只是 internal cycle outcome marker。
- ready path 下 `decision.shouldAdvance`、`step.didAdvance` 与 `didProduceProgress` 同为 true，且 step 不 blocked。
- runtime-not-ready blocked 与 input-blocked path 下 `didProduceProgress=false`、`step.didAdvance=false`、`step.isBlocked=true`。
- 未改变 request state。
- 未改变 existing step / decision / step-with-input-policy behavior。
- 未引入 frame/render/layout progress、event loop tick、queue drain、platform callback 或 app run。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-cycle-state-progress-bundle-target --skip-script` 通过，仅 unused warnings。
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
- 未新增 frame/render/layout progress 语义。
- 未修改 `cjpm.toml`、`labs/macos_bridge_smoke`、harness、native bridge、仓颉入口、`src/main.cj` 或 `package_anchor.cj`。

## Next Opening

建议 next opening：

- `P1 internal runtime cycle state progress bundle closure / next runtime behavior bundle decision`

下一步应基于已落地的 cycle progress marker 决定下一张更大的 internal runtime behavior bundle；不继续 helper-by-helper。
