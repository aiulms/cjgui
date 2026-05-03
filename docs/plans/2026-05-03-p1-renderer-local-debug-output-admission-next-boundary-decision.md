# P1 Renderer local debug output admission next-boundary decision

日期：2026-05-03

状态：docs-only decision

## Context

上一轮 `P1 internal Renderer local debug output admission value boundary bundle implementation` 已完成，closure 见：

- [2026-05-03-p1-internal-renderer-local-debug-output-admission-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-local-debug-output-admission-boundary-closure-review.md)

当前 canonical endpoint：

- `CjguiInternalRendererNoWriteLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft()`

该 endpoint 只表达 local debug output intent / output target policy / opt-in admission / redaction readiness / no-write output readiness value facts。它不是 local-output receipt / record / publication、真实 local debug output、logging subsystem、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

本轮问题：`CjguiInternalRendererNoWriteLocalOutputReadiness` 是否已经足够作为当前 local debug output admission endpoint，以及下一步是否应先做 manifest stabilization。

## Endpoint Assessment

`CjguiInternalRendererNoWriteLocalOutputReadiness` 已经足够作为当前 no-write local output admission endpoint。

理由：

- owner truth 已清楚：`runtime_renderer_diagnostics_local_output.cj` 只承载 local debug output intent / target policy / opt-in admission / redaction readiness / no-write readiness。
- 输入边界已清楚：只消费 `CjguiInternalRendererNoOutputDebugReadiness`。
- stop-line 已清楚：不写文件、不打 stdout / stderr、不发 telemetry、不触发 observer / event bus / public diagnostics，也不接 backend / command buffer / renderer state。
- 当前没有发现 output target / opt-in / redaction / no-write 表达不足的 blocker。

因此下一步应先固定 manifest，而不是继续新增 local-output receipt / record / publication，也不是直接评估真实输出实现。

## Candidate Comparison

### A. P1 internal Renderer local debug output admission manifest stabilization bundle implementation

选择。

理由：

- 当前 no-write endpoint 已足够作为 local debug output admission closure 的 canonical endpoint。
- 下一轮应固定 owner / truth / canonical endpoint / stop-line，避免后续把 no-write readiness 误读成真实 debug output permission。
- Manifest stabilization 可以把 local-output receipt / record / publication thin wrapper 明确挡在门外。

### B. Local debug real output preflight

暂缓。

真实 local debug output runway 如果未来要靠近，必须先经过 docs-only preflight。但当前 endpoint 还未 manifest 封账，先做 real output preflight 会让 no-write admission 的 owner / truth / stop-line 不够稳定。

### C. Local output hardening

暂缓。

只有发现 output target policy、opt-in admission、redaction readiness 或 no-write readiness 表达不足时才选择。当前 closure 与 runtime README 未显示该 blocker。

### D. Local-output receipt / record / publication

拒绝。

这是 Same-shape Boundary Brake 明确要阻止的 thin wrapper 路径。它不会新增 owner truth、consumer、gate、integration 或风险证据。

### E. Real logging / telemetry / observer callback / event bus / public diagnostics

拒绝。

当前 endpoint 不代表 logging readiness、telemetry readiness、observer readiness、event bus readiness 或 public diagnostics readiness。

### F. File / stdout / stderr / artifact sink

拒绝。

当前 no-write readiness 明确不允许文件写入、stdout / stderr 输出或 external artifact retention。

### G. Backend / command buffer / render failure callback / renderer state write

拒绝。

Local debug output admission 不接 backend handler、command buffer、renderer state write 或 render failure callback，也不是 render permission。

### H. Consolidation

暂缓。

只有发现明确 duplicate、low-value helper 或 self-wrapping evidence 时才选择。当前本轮没有发现必须先 consolidation 的证据。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些不是 diagnostics local debug output admission 的当前 downstream。

### J. Public surface expansion

拒绝。

public allowlist 不变，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮继续生效：

- `CjguiInternalRendererNoWriteLocalOutputReadiness` 已经是当前 no-write local output admission endpoint。
- 不批准新增 local-output receipt / record / publication。
- 不把 no-write readiness 解释成 real output sink、debug logging、telemetry、observer callback、event bus、public diagnostics、file sink 或 artifact retention readiness。
- 若未来靠近真实 local debug output，必须先 docs-only preflight；不得直接实现 logging / telemetry / observer callback / event bus / public diagnostics / file sink / stdout / stderr。

## Decision

最终选择：

`P1 internal Renderer local debug output admission manifest stabilization bundle implementation`

下一轮默认 docs-only write set：

- 新增 `docs/plans/2026-05-03-p1-renderer-local-debug-output-admission-manifest.md`
- 新增 manifest stabilization closure。
- 更新 `README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md` 与 relevant diagnostics manifest downstream。
- 不修改 `.cj`。
- 不运行 build / smoke。

Manifest 必须固定：

- owner file：`runtime/cjgui/src/runtime_renderer_diagnostics_local_output.cj`
- canonical endpoint：`CjguiInternalRendererNoWriteLocalOutputReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft()`
- current truth：local debug output intent / output target policy / opt-in admission / redaction readiness / no-write output readiness value facts。
- stop-line：不是真实 debug output、logging、telemetry、observer callback、event bus、public diagnostics、file / stdout / stderr sink、artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

## Final Next Opening

`P1 internal Renderer local debug output admission manifest stabilization bundle implementation`
