# P1 Internal Runtime Command Draft Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-cycle-state-progress-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-cycle-state-progress-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W2 internal runtime command draft concept slice，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal type：

- `CjguiInternalRuntimeCommandDraft`
  - `shouldRequestNextCycle: Bool`
  - `shouldReportBlocked: Bool`
  - `didObserveProgress: Bool`

新增默认 internal functions：

- `cjguiInternalBuildRuntimeCommandDraft(cycle)`
- `cjguiInternalExecuteRuntimeCycleDraftCommand(request)`
- `cjguiInternalRuntimeCommandDraftReadySanity()`
- `cjguiInternalRuntimeCommandDraftNotReadyBlockedSanity()`
- `cjguiInternalRuntimeCommandDraftInputBlockedSanity()`

## Behavior Summary

- command draft 只表达一次 internal cycle 后的 runtime intent summary。
- `didObserveProgress` 来自 `cycle.didProduceProgress`。
- `shouldReportBlocked` 来自 `cycle.step.isBlocked`。
- `shouldRequestNextCycle` 来自 `cycle.didProduceProgress`。
- ready path 下 progress observed、request-next-cycle 为 true，report-blocked 为 false。
- runtime-not-ready blocked 与 input-blocked path 下 progress observed、request-next-cycle 为 false，report-blocked 为 true。
- 未改变 cycle、step、decision、step-with-input-policy 或 cycle executor behavior。
- 未创建外部 command，未消费 queue，未触发 callback。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-command-draft-bundle-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

## Stop-Line

- 未改变 `CjguiInternalRuntimeRootState` shape。
- 未改变 `CjguiInternalRuntimeStepResult` shape。
- 未改变 `CjguiInternalRuntimeCycleResult` shape。
- 未改变 `CjguiInternalRuntimeStepInput` / `CjguiInternalRuntimeStepPolicy` / `CjguiInternalRuntimeStepDecision` shape。
- 未改变 existing step / decision / step-with-input-policy behavior。
- 未改变 cycle request / cycle executor behavior。
- 未改变 bootstrap / readiness / platform / app / window type shape。
- 未改变 projection / coordination / bootstrap builder behavior。
- 未新增 public runtime API 或 public C ABI。
- 未新增 renderer command list。
- 未新增 Scene / Widget / Layout / DSL。
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

- `P1 internal runtime command draft bundle closure / next runtime behavior bundle decision`

下一步应基于已落地的 command draft / intent summary 决定下一张更大的 internal runtime behavior bundle；不继续 helper-by-helper。
