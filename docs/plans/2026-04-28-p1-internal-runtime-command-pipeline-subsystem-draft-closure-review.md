# P1 Internal Runtime Command Pipeline Subsystem Draft Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-command-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-command-draft-bundle-closure-review.md)
- [GUI_GOVERNANCE.md W3 internal subsystem draft rule](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)

## Closed Scope

本轮一次完成 W3 internal runtime command pipeline subsystem draft，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalRuntimeCommandPipelineRequest`
  - `cycleRequest: CjguiInternalRuntimeCycleRequest`
- `CjguiInternalRuntimeCommandPipelineResult`
  - `request: CjguiInternalRuntimeCommandPipelineRequest`
  - `cycle: CjguiInternalRuntimeCycleResult`
  - `draft: CjguiInternalRuntimeCommandDraft`
  - `didCompletePipeline: Bool`

新增默认 internal functions：

- `cjguiInternalDefaultRuntimeCommandPipelineRequest()`
- `cjguiInternalExecuteRuntimeCommandPipeline(request)`
- `cjguiInternalExecuteDefaultRuntimeCommandPipeline()`
- `cjguiInternalRuntimeCommandPipelineReadySanity()`
- `cjguiInternalRuntimeCommandPipelineNotReadyBlockedSanity()`
- `cjguiInternalRuntimeCommandPipelineInputBlockedSanity()`

## Behavior Summary

- command pipeline 只把 existing cycle request、cycle result 与 command draft 串成 internal summary pipeline。
- pipeline executor 只调用一次 `cjguiInternalExecuteRuntimeCycle(request.cycleRequest)` 与 `cjguiInternalBuildRuntimeCommandDraft(cycle)`。
- `didCompletePipeline=true` 只表示 internal summary 已生成，不代表 runtime 真实运行。
- ready path 下 pipeline complete、cycle advances、progress observed、draft request-next-cycle 且不 report blocked。
- runtime-not-ready blocked 与 input-blocked path 下 pipeline complete、cycle blocked、无 progress、draft 不 request-next-cycle 且 report blocked。
- 未改变 existing cycle request / executor behavior、command draft builder behavior、step / decision / step-with-input-policy behavior 或任何 state shape。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-command-pipeline-subsystem-draft-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

## Stop-Line

- 未改变 `CjguiInternalRuntimeRootState` shape。
- 未改变 `CjguiInternalRuntimeStepResult` shape。
- 未改变 `CjguiInternalRuntimeCycleResult` shape。
- 未改变 `CjguiInternalRuntimeCommandDraft` shape。
- 未改变 `CjguiInternalRuntimeStepInput` / `CjguiInternalRuntimeStepPolicy` / `CjguiInternalRuntimeStepDecision` shape。
- 未改变 existing step / decision / step-with-input-policy behavior。
- 未改变 cycle request / cycle executor behavior。
- 未改变 command draft builder behavior。
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

- `P1 internal runtime command pipeline subsystem draft closure / next runtime behavior decision`

下一步应基于已落地的 internal summary pipeline 判断后续 runtime behavior bundle；仍不得自动进入 app run、event loop、queue / drain、window create、renderer command list 或 public surface。
