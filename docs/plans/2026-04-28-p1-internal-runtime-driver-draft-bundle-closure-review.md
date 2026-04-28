# P1 Internal Runtime Driver Draft Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-command-pipeline-subsystem-draft-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-command-pipeline-subsystem-draft-closure-review.md)

## Closed Scope

本轮一次完成 W3 internal runtime driver draft bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalRuntimeDriverRequest`
  - `pipelineRequest: CjguiInternalRuntimeCommandPipelineRequest`
- `CjguiInternalRuntimeDriverResult`
  - `request: CjguiInternalRuntimeDriverRequest`
  - `pipeline: CjguiInternalRuntimeCommandPipelineResult`
  - `didCompleteDriverPass: Bool`
  - `shouldRequestNextCycle: Bool`
  - `shouldReportBlocked: Bool`
  - `didObserveProgress: Bool`

新增默认 internal functions：

- `cjguiInternalDefaultRuntimeDriverRequest()`
- `cjguiInternalExecuteRuntimeDriverPass(request)`
- `cjguiInternalExecuteDefaultRuntimeDriverPass()`
- `cjguiInternalRuntimeDriverReadySanity()`
- `cjguiInternalRuntimeDriverNotReadyBlockedSanity()`
- `cjguiInternalRuntimeDriverInputBlockedSanity()`

## Behavior Summary

- driver draft 只组织一次 internal command pipeline pass 并生成 driver-level summary。
- driver pass executor 只调用 `cjguiInternalExecuteRuntimeCommandPipeline(request.pipelineRequest)`。
- driver result 从 `pipeline.draft` 投影 `shouldRequestNextCycle`、`shouldReportBlocked` 与 `didObserveProgress`。
- `didCompleteDriverPass` 来自 `pipeline.didCompletePipeline`，只表示 internal summary pass 已完成，不代表真实 runtime driver。
- ready path 下 driver pass complete、pipeline complete、cycle advances、progress observed、request-next-cycle 且不 report blocked。
- runtime-not-ready blocked 与 input-blocked path 下 driver pass complete、cycle blocked、无 progress、不 request-next-cycle 且 report blocked。
- 未改变 existing command pipeline、cycle、step、decision、step-with-input-policy、bootstrap、projection 或 coordination behavior。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-driver-draft-bundle-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

## Stop-Line

- 未新增 public runtime API 或 public C ABI。
- 未修改 `cjpm.toml`。
- 未新增 `src/main.cj` 或 `package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 未接入 AppKit / Metal / Objective-C。
- 未暴露 platform object、native handle 或 raw pointer。
- 未实现 event loop、callback binding、queue / drain。
- 未实现 app run / shutdown。
- 未实现 window create / close / destroy / release。
- 未新增 handle table / generation。
- 未改变现有 root / bootstrap / readiness / platform / app / window type shape。
- 未改变现有 constructor shape。
- 未改变现有 projection / coordination / bootstrap / cycle / command pipeline behavior。
- 未把 driver draft 宣称为真实 runtime driver。
- 未把 command draft 宣称为 renderer command list 或 event loop command。

## Next Opening

建议 next opening：

- `P1 internal runtime driver draft bundle closure / next runtime behavior decision`

下一步应基于 internal driver-level summary 判断后续 runtime behavior bundle；仍不得自动进入 app run、event loop、queue / drain、window create、renderer command list 或 public surface。
