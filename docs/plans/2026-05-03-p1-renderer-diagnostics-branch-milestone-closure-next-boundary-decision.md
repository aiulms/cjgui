# P1 Renderer diagnostics branch milestone closure / next renderer non-diagnostics boundary decision

日期：2026-05-03

状态：docs-only decision

## Purpose

本 decision 正式关闭 Renderer diagnostics no-output / no-op 支线，并选择下一步回到 renderer 非 diagnostics 方向。

Diagnostics branch 已完成：

- local diagnostics pipeline milestone。
- consolidation / low-value duplicate audit manifest。
- diagnostics stop-line hardening。

本轮不新增 runtime boundary，不修改 `.cj`，不实现 logging、telemetry、observer callback、event bus、public diagnostics、file sink、stdout / stderr sink 或 external artifact retention。

## Inputs Reviewed

- [2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-local-diagnostics-pipeline-milestone-manifest.md)
- [2026-05-03-p1-renderer-diagnostics-consolidation-audit-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-consolidation-audit-manifest.md)
- [2026-05-03-p1-renderer-diagnostics-stop-line-hardening.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-stop-line-hardening.md)
- [2026-05-03-p1-internal-renderer-diagnostics-stop-line-hardening-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-diagnostics-stop-line-hardening-closure-review.md)
- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)
- [2026-05-02-p1-renderer-backend-tail-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-tail-milestone-manifest.md)
- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)
- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)

## Diagnostics Branch Closed State

Current canonical diagnostics tail endpoint remains:

- `CjguiInternalRendererNoOpLocalOutputReadiness`
- `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`

Closed state:

- Diagnostics branch 当前不再继续新增 readiness / receipt / record / publication / output tail。
- `Readiness` 只表示 internal value pipeline 可继续评估，不代表 side effect permission。
- `NoOutput` / `NoWrite` / `NoSideEffect` / `NoOp` 只表示 stop-line value facts，不代表真实 output、write、logging、file sink、telemetry、observer callback、event bus 或 public diagnostics。
- `Sink` / `Output` / `Write` / `Real` / `LocalDebug` 只是 diagnostics runway vocabulary，不是 implementation permission。
- 当前没有明确 duplicate fields、duplicate builders、low-value owner、self-wrapping owner、manifest drift 或 build-level dead code evidence 支持 targeted consolidation。

Public allowlist 不变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Future Diagnostics Reopening Rule

未来若要重开真实 diagnostics output / logging / file sink / telemetry / observer callback / event bus / public diagnostics，必须先做 docs-only preflight，并提供 concrete evidence：

- privacy：raw payload policy、dehydrated fact boundary、data minimization。
- opt-in：debug-only / local-only opt-in rule 与 default-off behavior。
- redaction：redaction policy、enforcement point、serialization boundary。
- lifecycle：owner、creation、cleanup、shutdown、failure rollback。
- thread-safety：main-thread / worker-thread boundary、concurrency policy、backpressure。
- artifact：file / stdout / stderr / external artifact 是否允许，以及 retention / cleanup。
- retention：retention duration、retention hint mapping、deletion policy。
- failure rollback：partial write、duplicate write、failed write、no-op fallback。

没有这些 evidence 时，不得实现真实 logging、telemetry、observer callback、event bus、public diagnostics、file sink、stdout / stderr sink、artifact retention、backend handler、command buffer、renderer state write、render failure callback 或 render permission。

## Renderer Non-diagnostics Reopening Context

Renderer command / packet path 当前已有可回到的 backend-agnostic endpoints：

- Command packet validation endpoint：`CjguiInternalRendererCommandValidationResult` / `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`。
- Packet normalization endpoint：`CjguiInternalRendererPacketNormalizationResult` / `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`。
- Upstream command / batching truth：`CjguiInternalRenderCommandPacket` 与 `CjguiInternalRenderBatchingPacket`，仍是 backend-agnostic value facts。

下一步如果回到非 diagnostics 路线，必须继续保持：

- no backend packet implementation。
- no command buffer。
- no renderer state write。
- no render permission。
- no sorting side effect。
- no draw-call merge / GPU batching。
- no dirty-region / diff / patch / incremental render。
- no public surface expansion。

## Candidate Comparison

### A. P1 internal Renderer command packet post-normalization handoff preflight decision

选择为下一阶段 opening。

理由：

- Diagnostics branch 已经完成 milestone、audit、audit manifest 与 stop-line hardening，应停止 diagnostics tail。
- Command packet validation 与 packet normalization 已有 manifest endpoint，可以 docs-only 评估是否存在真正 downstream owner，而不是继续 diagnostics readiness wrapper。
- 该候选回到 command / normalization / validation 后的 backend-agnostic runway，仍不接 backend、command buffer、renderer state write 或 render execution。
- 下一轮先做 preflight，可防止直接把 normalized packet 包成 receipt / publication / readiness wrapper。

### B. P1 internal Renderer backend shell continuation preflight decision

可选但谨慎，不作为默认。

Backend shell tail 曾触发 Same-shape Boundary Brake。除非能证明新增 owner truth、entry contract、consumer 或 integration evidence，否则不应回到 shell continuation。

### C. P1 internal Renderer command packet ordering / material grouping hardening boundary bundle implementation

可选但不作为默认。

只有 normalization manifest 暴露 ordering facts、material grouping hints 或 full-rebuild packet facts 表达不足时才进入 hardening。当前更稳的是先做 post-normalization handoff preflight，判断是否存在 downstream owner。

### D. Diagnostics real output preflight

暂缓。

Diagnostics branch 本轮正式封账；hardening 未发现真实 output ready evidence。

### E. Diagnostics targeted consolidation preflight

暂缓。

Audit manifest 未发现 duplicate / low-value / self-wrapping evidence。

### F. Real logging / telemetry / observer callback / event bus / public diagnostics implementation

拒绝。

### G. File / stdout / stderr / artifact sink implementation

拒绝。

### H. Metal / AppKit / command buffer / render execution / renderer state write

拒绝，过早。

Command / normalization preflight 不批准 backend implementation、platform adapter、command buffer、draw call、renderer state write 或 render permission。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍保持 full DisplayList / command list rebuild only。

### J. Public surface expansion

拒绝。

Public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 branch closure 生效：

- diagnostics tail 到此关闭，不继续新增 `Readiness` 包装。
- 不批准 diagnostics receipt / record / publication / output tail。
- 不因 `NoOpLocalOutputReadiness` 的存在而误判为真实 diagnostics output permission。
- 下一轮即使选择 command packet post-normalization handoff，也必须先做 docs-only preflight，证明 downstream owner truth / consumer / gate / integration evidence，不得把 normalized packet 直接包成 handoff receipt、publication 或 backend readiness。

## Decision

最终 decision：

- Renderer diagnostics no-output / no-op branch closed。
- Current canonical diagnostics tail remains `CjguiInternalRendererNoOpLocalOutputReadiness` / `cjguiInternalExecuteDefaultRendererRealLocalOutputNoOpDraft()`。
- 下一步回到 renderer command packet / normalized packet 非 diagnostics 路线。

最终 next opening：

`P1 internal Renderer command packet post-normalization handoff preflight decision`

下一轮必须 docs-only preflight。它应评估 `CjguiInternalRendererPacketNormalizationResult` 后是否存在明确 downstream owner / handoff gate / value-style consumer；不得直接接 backend、command buffer、render execution、renderer state write、dirty-region、Widget / Layout / Text / IME / Accessibility、public surface expansion，也不得新增 normalized packet receipt / record / publication thin wrapper。

## Downstream Post-normalization Handoff Preflight

`P1 internal Renderer command packet post-normalization handoff preflight decision` 已由 [2026-05-03-p1-renderer-command-packet-post-normalization-handoff-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-post-normalization-handoff-preflight-decision.md) 完成。

Preflight 结论：当前 downstream consumer / gate / integration evidence 不足，不批准 post-normalization handoff implementation，不复用旧 `runtime_renderer_handoff.cj` 的 batching-packet receipt 语义，也不新建 `runtime_renderer_packet_handoff.cj`。

新的 next opening 是：

`P1 internal Renderer command packet ordering / material grouping hardening boundary bundle implementation`
