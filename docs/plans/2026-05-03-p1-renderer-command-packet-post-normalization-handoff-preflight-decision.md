# P1 Renderer command packet post-normalization handoff preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Purpose

本 preflight 从 diagnostics branch closure 回到 renderer command packet / normalized packet 的非 diagnostics 路线，评估 `CjguiInternalRendererPacketNormalizationResult` 后是否可以进入 post-normalization handoff runway。

本轮只做 decision，不修改 `.cj`，不实现 handoff wrapper，不接 backend / command buffer / render execution / renderer state write。

## Inputs Reviewed

- [2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md)
- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)
- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)
- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)
- [2026-05-02-p1-renderer-backend-tail-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-tail-milestone-manifest.md)

## Current Endpoint

Current post-normalization input:

- `CjguiInternalRendererPacketNormalizationResult`
- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`

Normalization truth 已固定：

- backend-agnostic normalized packet candidate facts。
- normalized ordering facts。
- normalized material grouping hint facts。
- no-render / no-backend / no-command-buffer normalization result facts。
- P1 full rebuild only。

当前 normalization endpoint 不是 backend packet、command buffer、renderer state write、render permission、sorting side effect、draw-call merge、GPU batching、diff / patch 或 public API。

## Handoff Evidence Review

本轮未发现足够 strong downstream consumer / gate / integration evidence 来批准 post-normalization handoff implementation。

现有 `runtime/cjgui/src/runtime_renderer_handoff.cj` 不适合作为本轮 post-normalization handoff owner：

- 它只消费 `CjguiInternalRenderBatchingPacket`，不是 `CjguiInternalRendererPacketNormalizationResult`。
- 它的 canonical endpoint 是 `CjguiInternalRendererPacketHandoffReceipt`。
- 它属于较早的 batching-packet handoff / backend no-render tail 起点。
- 后续 handoff -> adapter -> contract -> capability -> selection -> binding 已触发 Same-shape Boundary Brake，并由 backend tail milestone 封账。

因此：

- 本轮不复用 `runtime_renderer_handoff.cj`。
- 本轮不新建 `runtime_renderer_packet_handoff.cj`。
- 若未来重新打开 post-normalization handoff，必须先证明 concrete downstream owner / consumer / gate / integration evidence；届时可考虑新 owner，但输入应只允许 `CjguiInternalRendererPacketNormalizationResult`，且输出只能是 post-normalization handoff intent / consumer candidate / admission / no-render handoff readiness value facts。

## Handoff Truth If Reopened Later

未来若 handoff evidence 充足，handoff truth 也只能是：

- post-normalization handoff intent。
- consumer candidate。
- handoff admission。
- no-render handoff readiness value facts。

它不得成为：

- normalized packet receipt / record / publication。
- backend packet readiness。
- backend shell continuation。
- command buffer readiness。
- renderer state write readiness。
- render permission。
- sorting side effect。
- draw-call merge / GPU batching。
- dirty-region / diff / patch。

## Candidate Comparison

### A. P1 internal Renderer command packet post-normalization handoff value boundary bundle implementation

不选择。

理由：

- 当前只有 normalization endpoint 自身的 `canFutureRendererBoundaryUseNormalizedPacket` 之类 future-boundary facts。
- 没有新的 concrete downstream consumer / gate / integration evidence。
- 现有 `runtime_renderer_handoff.cj` 是旧 batching-packet handoff receipt owner，不适合复用。
- 直接实现新 handoff owner 风险较高，容易把 `CjguiInternalRendererPacketNormalizationResult` 包成 handoff receipt / record / publication thin wrapper。

### B. P1 internal Renderer command packet ordering / material grouping hardening boundary bundle implementation

选择为下一阶段 opening。

理由：

- Handoff evidence 不足，但 normalization vocabulary 仍可在 backend-agnostic 范围内增强。
- Hardening 可以围绕 normalized ordering facts、material grouping hints、batch key hint、stable packet facts、full rebuild only 与 no-sort / no-merge stop-line 建立更明确的 value gate。
- 这比直接 handoff 更安全：它仍留在 command / normalized packet integrity 路线内，不接 backend、command buffer 或 render execution。
- 它新增的语义应是 ordering basis / material grouping scope / hint preservation / no-side-effect hardening，而不是 handoff receipt。

### C. P1 internal Renderer packet normalization manifest hardening docs bundle implementation

不选择为默认。

当前 normalization manifest 已固定 owner / truth / endpoint / stop-line；主要问题不是文档 stop-line 不清，而是下一步缺少 handoff evidence。下一刀更适合以 value boundary 强化 ordering / grouping 语义。

### D. Backend shell continuation

谨慎暂缓。

Backend shell / backend tail 曾触发 Same-shape Boundary Brake。当前刚从 diagnostics branch 回到 packet path，不应立即回到 backend shell continuation。

### E. Diagnostics branch reopening

暂缓。

Diagnostics branch 刚完成 milestone closure，不应重新打开 diagnostics tail。

### F. Normalized packet receipt / record / publication

拒绝。

这会直接把 normalization endpoint 包成 thin wrapper，违反 Same-shape Boundary Brake。

### G. Backend / command buffer / render execution / renderer state write

拒绝。

Post-normalization preflight 不批准 backend packet、command buffer、draw call、renderer state write 或 render permission。

### H. Metal / AppKit / platform resource / native handle

拒绝。

当前仍不接平台资源、不创建 native handle / raw pointer / platform object。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍是 full DisplayList / command list rebuild only。

### J. Public surface expansion

拒绝。

Public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### K. Consolidation

暂缓。

本轮未发现明确 duplicate / low-value helper / self-wrapping evidence 支持 consolidation。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过拒绝 premature handoff 生效：

- 不把 `CjguiInternalRendererPacketNormalizationResult` 直接包成 handoff receipt / record / publication。
- 不复用旧 `CjguiInternalRendererPacketHandoffReceipt` 语义来承载 post-normalization facts。
- 在 downstream consumer / gate / integration evidence 不足时，选择 ordering / material grouping hardening，而不是新增 handoff wrapper。

下一轮若进入 hardening implementation，必须证明新增语义是 ordering basis、material grouping scope、hint preservation、full rebuild invariant、no-sort / no-merge gate，而不是 normalization result thin wrapper。

## Decision

Preflight 结论：

- 当前不批准 post-normalization handoff implementation。
- 当前不复用 `runtime_renderer_handoff.cj`。
- 当前不新建 `runtime_renderer_packet_handoff.cj`。
- 下一步选择 command packet ordering / material grouping hardening。

最终 next opening：

`P1 internal Renderer command packet ordering / material grouping hardening boundary bundle implementation`

下一轮若实现，应只消费 `CjguiInternalRendererPacketNormalizationResult`，只输出 internal backend-agnostic ordering / material grouping hardening value facts；不得接 backend、Metal / AppKit、command buffer、renderer state write、render execution、draw call、GPU batching、sorting side effect、dirty-region、diff / patch、Widget / Layout / Text / IME / Accessibility 或 public surface expansion。
