# P1 Internal Runtime Step Outcome Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-step-outcome-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-outcome-bundle-execution-card.md)

## Closed Scope

本轮一次完成 W2 internal outcome concept slice，没有拆成 one-helper slices。

已扩展默认 internal `CjguiInternalRuntimeStepResult`：

- 保留 `state: CjguiInternalRuntimeRootState`
- 保留 `didAdvance: Bool`
- 新增 `isBlocked: Bool`
- 新增 `isBlockedByRuntimeNotReady: Bool`
- 新增 `isBlockedByInput: Bool`

已更新默认 internal functions：

- `cjguiInternalRuntimeStep(state)`
- `cjguiInternalRuntimeStepWithInput(state, input, policy)`

已新增 outcome 直接相关 sanity helpers：

- `cjguiInternalRuntimeStepReadyOutcomeSanity()`
- `cjguiInternalRuntimeStepBlockedOutcomeSanity()`

## Behavior Summary

- simple step 仍只根据 `state.isRuntimeReady` 决定 `didAdvance`。
- simple step 在 runtime not ready 时返回 runtime-not-ready blocked outcome。
- step-with-input-policy 继续复用 `cjguiInternalDecideRuntimeStep(state, input, policy)`。
- step-with-input-policy 将 decision blocker facts 投影到 result outcome。
- decision function 的 blocker priority 未改变。
- step input / policy shape 未改变。
- `hasExternalWork` 仍只是脱水 marker，不代表真实 queue、event loop 或 platform callback。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-step-outcome-bundle-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

## Forbidden Boundary

- 未改变 root / bootstrap / readiness / platform / app / window state shape。
- 未改变 projection behavior、coordination behavior、bootstrap behavior 或 decision blocker priority。
- 未改变 step input / policy shape。
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

- `P1 internal runtime step outcome closure / next runtime behavior bundle decision`

下一步不应继续 helper-by-helper；应基于已落地的 step result outcome / status 决定下一张更大的 internal runtime behavior bundle。
