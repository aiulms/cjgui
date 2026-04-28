# P1 Internal Runtime Driver Input Policy Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-driver-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-driver-draft-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W3 internal runtime driver input / policy / decision bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalRuntimeDriverInput`
  - `allowsDriverPass: Bool`
  - `hasExternalDriverWork: Bool`
- `CjguiInternalRuntimeDriverPolicy`
  - `requiresRuntimeReady: Bool`
  - `requiresInputAllowsDriverPass: Bool`
- `CjguiInternalRuntimeDriverDecision`
  - `shouldRunPipeline: Bool`
  - `isBlockedByRuntimeNotReady: Bool`
  - `isBlockedByInput: Bool`

新增默认 internal functions：

- `cjguiInternalDefaultRuntimeDriverInput()`
- `cjguiInternalDefaultRuntimeDriverPolicy()`
- `cjguiInternalDecideRuntimeDriverPass(root, input, policy)`
- `cjguiInternalExecuteRuntimeDriverPassWithInput(request, input, policy)`
- `cjguiInternalRuntimeDriverInputPolicyReadySanity()`
- `cjguiInternalRuntimeDriverInputPolicyRuntimeBlockedSanity()`
- `cjguiInternalRuntimeDriverInputPolicyInputBlockedSanity()`

## Behavior Summary

- default driver input 允许 driver pass，并把 `hasExternalDriverWork` 保持为脱水 marker。
- default driver policy 要求 runtime ready 且 input 允许 driver pass。
- driver decision 先判定 runtime-not-ready blocker，再判定 input blocker，保持 fail-closed 单一原因优先级。
- driver pass with input 在 decision 允许时复用既有 `cjguiInternalExecuteRuntimeDriverPass(request)`。
- blocked path 不执行 pipeline pass，只构造 fail-closed summary：`didCompleteDriverPass=false`、`shouldRequestNextCycle=false`、`shouldReportBlocked=true`、`didObserveProgress=false`。
- 未改变 existing driver pass、command pipeline、cycle、step、decision、step-with-input-policy、bootstrap、projection 或 coordination behavior。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-driver-input-policy-bundle-target --skip-script` 通过，仅 unused warnings。
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
- 未新增 renderer command list、Scene / Widget / Layout / DSL 或 frame/render/layout progress 语义。
- 未把 driver input / policy 宣称为 scheduling policy、threading policy、platform runloop policy 或 queue policy。
- 未把 blocked path 变成真实 error system。

## Next Opening

建议 next opening：

- `P1 internal runtime driver input policy bundle closure / next runtime behavior decision`

下一步应基于 internal driver-level input / policy gate 判断后续 runtime behavior bundle；仍不得自动进入 app run、event loop、queue / drain、window create、renderer command list 或 public surface。
