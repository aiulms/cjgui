# P1 internal Renderer local debug sink policy manifest stabilization closure review

日期：2026-05-03

状态：docs-only manifest stabilization closure

## Scope

本轮新增 manifest：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-debug-sink-policy-manifest.md`

该 manifest 固定 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_debug.cj`

当前 canonical endpoint：

- `CjguiInternalRendererNoOutputDebugReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft()`

本轮只更新 docs / indexes / upstream manifest。未修改 `.cj`，未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。

## Manifest Conclusion

`CjguiInternalRendererNoOutputDebugReadiness` 已封账为当前 no-output local debug endpoint。

Current truth：

- local debug sink intent value facts。
- debug channel policy value facts。
- opt-in guard value facts。
- redaction policy value facts。
- no-output debug readiness value facts。

该 endpoint 只允许 dehydrated diagnostic facts / severity / retention hint 作为 value facts 继续被描述。它不收集 raw payload，不输出 serialized payload，不承诺 external artifact retention，不执行 local file output。

## Stop-line

`CjguiInternalRendererNoOutputDebugReadiness` 不是：

- local-debug receipt / record / publication。
- real logging。
- real local debug output。
- file / stdout / stderr sink。
- telemetry。
- observer callback。
- event bus。
- public diagnostics。
- artifact retention。
- external diagnostics export。
- backend handler。
- command buffer。
- renderer state write。
- render failure callback。
- render permission。

## Same-shape Boundary Brake

本轮选择 manifest 封账，而不是继续新增 local-debug tail。

Brake 生效点：

- `CjguiInternalRendererNoOutputDebugReadiness` 已经是 canonical endpoint。
- 不批准 local-debug receipt / record / publication。
- 不批准 logging readiness、file sink readiness、stdout / stderr readiness、telemetry readiness、observer readiness、event bus readiness 或 public diagnostics readiness wrapper。
- 若未来靠近真实 local debug output，必须先 docs-only preflight，不能直接实现。

## Next-stage Candidate Summary

- A. `P1 internal Renderer local debug output preflight decision`：选择。manifest 已固定 endpoint 后，下一步若靠近真实 local debug output，必须先 docs-only preflight，评估 opt-in / redaction / privacy / lifecycle / thread-safety / artifact / debug-only / local-only / backpressure / retention 边界。
- B. local debug hardening：暂缓，仅在 opt-in / redaction / no-output 表达不足时选择。
- C. consolidation：暂缓，仅在发现 duplicate / low-value helper / self-wrapping evidence 时选择。
- D. local-debug receipt / record / publication：拒绝，thin wrapper 风险高。
- E. real logging / telemetry / observer callback / event bus / public diagnostics implementation：拒绝，过早。
- F. file / stdout / stderr / artifact sink implementation：拒绝，过早。
- G. backend / command buffer / render failure callback / renderer state write：拒绝。
- H. dirty-region / Widget / Layout / Text / IME / Accessibility：暂缓。
- I. public surface expansion：拒绝。

## Verification

本 closure 已完成验证：

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README 可找到 manifest、closure 与 next opening。
- forbidden check：tracked `.cj` diff 为空，protected paths 无变更。
- public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，affected processes `0`。
- 本轮 docs-only，未运行 `cjpm build` / smoke。

## Next Opening

唯一 next opening：

`P1 internal Renderer local debug output preflight decision`

下一轮必须仍是 docs-only preflight：只评估是否可以打开真实 local debug output runway，不得直接实现 logging、telemetry、observer callback、event bus、public diagnostics、file sink、stdout / stderr、artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。
