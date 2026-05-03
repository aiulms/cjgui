# P1 internal Renderer local debug output admission manifest stabilization closure review

日期：2026-05-03

状态：docs-only closure

## Scope

本轮执行：

`P1 internal Renderer local debug output admission manifest stabilization bundle implementation`

本轮只修改文档，不修改 `.cj`，不运行 build / smoke，不实现真实 logging / telemetry / observer callback / event bus / public diagnostics / file sink。

新增 manifest：

- [2026-05-03-p1-renderer-local-debug-output-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-debug-output-admission-manifest.md)

同步入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-03-p1-renderer-local-debug-sink-policy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-debug-sink-policy-manifest.md)

本轮没有修改 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有触碰 smoke / harness / native bridge / entry / AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Manifest Conclusion

Manifest 固定 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`

Canonical endpoint：

- `CjguiInternalRendererNoWriteLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft()`

Current truth：

- internal local debug output intent facts。
- internal output target policy facts。
- internal opt-in admission facts。
- internal redaction readiness facts。
- no-write local output readiness value facts。

`CjguiInternalRendererNoWriteLocalOutputReadiness` 已封账为当前 no-write local debug output admission endpoint。它只表示 future real local debug output runway 可以在后续 docs-only preflight 中继续评估。

它不是：

- local-output receipt / record / publication。
- real logging。
- real debug output。
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

当前只允许 dehydrated diagnostic facts / severity / retention hint，不收集 raw payload，不输出 serialized payload，不承诺 external artifact retention，不执行 local file output。

## Same-shape Boundary Brake

本轮 Same-shape Boundary Brake 通过 manifest 封账生效。

选择 manifest stabilization 的原因：

- `CjguiInternalRendererNoWriteLocalOutputReadiness` 已经足够表达当前 no-write endpoint。
- 继续新增 local-output receipt / record / publication 会变成 same-shape thin wrapper。
- 当前没有发现 output target policy、opt-in admission、redaction readiness 或 no-write readiness 表达不足的 blocker。
- 下一步若靠近真实 local debug output，必须先做 docs-only preflight，不得直接 implementation。

明确拒绝：

- local-output receipt。
- local-output record。
- local-output publication。
- logging readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- event bus readiness wrapper。
- public diagnostics readiness wrapper。
- file / stdout / stderr sink readiness wrapper。
- artifact export readiness wrapper。

## Candidate Comparison

### A. P1 internal Renderer real local debug output preflight decision

选择为唯一 next opening。

原因：no-write local output admission endpoint 已封账。若未来要靠近真实 local debug output，下一步必须先 docs-only 评估 opt-in / redaction / privacy / lifecycle / thread-safety / artifact / debug-only / local-only / backpressure / retention / failure rollback 边界。

### B. Local output hardening

暂缓。

仅在发现 output target / opt-in / redaction / no-write 表达不足时选择。当前 manifest 没有记录该 blocker。

### C. Consolidation

暂缓。

仅在发现明确 duplicate、low-value helper 或 self-wrapping evidence 时选择。本轮没有新增 runtime code，也没有发现需要先清理的 local-output tail。

### D. Local-output receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

当前 endpoint 不是真实 output permission，不允许直接实现这些输出或发布路径。

### F. File / stdout / stderr / artifact sink implementation

拒绝。

当前 no-write readiness 明确不写文件、不打 stdout / stderr、不保留 external artifact。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Local debug output admission 不接 backend handler、command buffer、renderer state write 或 render failure callback，也不是 render permission。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些不属于 diagnostics local debug output admission manifest closure。

### I. Public surface expansion

拒绝。

public allowlist 不变，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Verification

本轮按 docs-only 规则未运行 `cjpm build` / smoke guard。

已执行并通过：

- `git diff --check`
- Markdown absolute link missing target check
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check
- forbidden check
- public declaration scan
- GitNexus `detect_changes(scope=unstaged)`

验证结论：

- 本轮没有 tracked `.cj` diff。
- 未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus risk low，affected processes 为空。

## Next Opening

唯一 next opening：

`P1 internal Renderer real local debug output preflight decision`

下一轮必须是 docs-only preflight。它只评估是否可以打开真实 local debug output runway；不得直接实现真实 logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、external artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。
