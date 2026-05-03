# P1 Renderer packet integration owner-truth preflight manifest

日期：2026-05-03

状态：owner-truth / evidence manifest stabilization

## Purpose

本 manifest 将 post-normalization packet integration preflight 的结论封账，固定当前不批准 integration runtime owner 的判断，并明确未来 reopening 条件。

本 manifest 不创建 `runtime_renderer_packet_integration.cj`，不批准 backend readiness，也不把 ordering hardening result 包成 integration receipt / record / publication。

## Current Upstream Endpoint

当前 canonical upstream endpoint 仍是：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

该 endpoint 只表达 ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts。

它不执行排序，不做 draw-call merge / GPU batching，不改 packet，不是 backend packet、command buffer、renderer state write、render execution 或 render permission。

## Current Decision

当前不批准：

- 新建 `runtime/cjgui/src/runtime_renderer_packet_integration.cj`。
- packet integration receipt。
- packet integration record。
- packet integration publication。
- integration readiness wrapper。
- backend readiness wrapper。
- 复用旧 `runtime_renderer_handoff.cj` 的 batching-packet handoff receipt 语义。

当前缺口是 downstream owner / consumer / gate / integration evidence 不足。

这不是 validation 失败、normalization 失败或 ordering / material grouping hardening 失败。`CjguiInternalRendererPacketOrderingHardeningResult` 已经足够作为当前 ordering / material grouping endpoint；缺的是后继 integration owner truth。

## Old Handoff Avoidance

旧 `runtime_renderer_handoff.cj` 属于 backend no-render tail 的起点：

- 只消费 `CjguiInternalRenderBatchingPacket`。
- canonical endpoint 是 `CjguiInternalRendererPacketHandoffReceipt`。
- downstream 曾进入 backend adapter / contract / capability / selection / binding tail。

Backend tail milestone 已记录该路线触发 Same-shape Boundary Brake。因此当前 packet integration runway 不应复用旧 handoff receipt 语义，也不应把 ordering hardening result 改名成新的 handoff receipt。

## Future Reopening Conditions

未来若重新开启 packet integration runtime boundary，必须先提供 concrete evidence：

- 明确 downstream owner 名称与责任。
- 明确 consumer / gate / acceptance 语义。
- 明确 input 只允许消费 `CjguiInternalRendererPacketOrderingHardeningResult`。
- 明确 output truth 只能是 packet integration intent / integration candidate / integration gate / no-backend integration readiness value facts。
- 明确为什么不是 receipt / record / publication thin wrapper。
- 明确为什么不复用旧 `runtime_renderer_handoff.cj` batching-packet handoff receipt。
- 明确不接 backend / command buffer / render execution / renderer state write。
- 明确不接 Metal / AppKit / platform resource / native handle / raw pointer。

没有这些 evidence 时，继续优先 hardening / docs stabilization / milestone，而不是 runtime boundary。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 owner-truth manifest 生效。

本 manifest 的作用是刹住 ordering -> integration 的薄包装：

- 拒绝 integration readiness wrapper。
- 拒绝 backend readiness wrapper。
- 拒绝 handoff receipt wrapper。
- 拒绝 packet integration receipt / record / publication。
- 拒绝把 `CjguiInternalRendererPacketOrderingHardeningResult` 解释成 backend readiness、command buffer readiness、renderer state write 或 render permission。

若未来 evidence 不足，继续寻找 runtime integration owner 只会重复旧 backend tail 的同构风险。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no `runtime_renderer_packet_integration.cj` creation。
- no backend / backend shell continuation implementation。
- no Metal / AppKit / platform resource。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no renderer state write。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no diagnostics branch reopening。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Candidate Comparison

### A. P1 internal Renderer command packet backend-readiness preflight decision

谨慎暂缓。

它只能作为 docs-only preflight 评估 backend-readiness owner / gate evidence，不得实现 backend。但当前 integration owner evidence 已不足，直接跳到 backend-readiness 仍太靠近 backend packet、command buffer、renderer state write 与 render permission。

### B. P1 internal Renderer packet owner-truth milestone stabilization bundle implementation

选择为下一阶段 opening。

理由：

- command packet -> validation -> normalization -> ordering 的 owner chain 已经形成。
- integration runtime owner 当前 evidence 不足。
- milestone 能总结 owner chain、canonical tail、stop-line 与 reopening conditions，避免继续追无证据 integration。
- 仍是 docs-only，不实现 backend、integration wrapper 或 render execution。

### C. P1 internal Renderer backend shell / adapter non-diagnostics branch revisit decision

暂缓。

Backend shell / adapter tail 曾触发 Same-shape Boundary Brake。除非出现新的 owner truth 或 consumer evidence，不应回到 backend shell continuation。

### D. Command packet hardening follow-up

暂缓。

只有发现 validation / normalization / ordering 表达不足时才开。当前缺口不是 upstream packet facts 失败。

### E. Integration runtime boundary

拒绝。

当前 downstream owner / consumer / gate / integration evidence 不足。

### F. Receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### G. Backend / command buffer / render execution / renderer state write

拒绝。

当前 packet owner-truth manifest 不批准 backend packet、command buffer、render execution、renderer state write 或 render permission。

### H. Metal / AppKit / platform resource / native handle

拒绝。

当前不持有平台资源，不创建 native handle / raw pointer / platform object。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍是 full DisplayList / command list rebuild。UI system、layout、text、IME、accessibility、dirty-region、diff / patch 需要独立 owner truth。

### J. Diagnostics branch reopening

暂缓。

Diagnostics branch 已封账，本轮不重开 diagnostics tail。

### K. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### L. Consolidation

暂缓。

只有发现 duplicate fields、duplicate builders、low-value helper、self-wrapping owner、manifest drift 或 build-level dead code evidence 时才开。当前没有这类 evidence。

## Decision

最终 next opening：

`P1 internal Renderer packet owner-truth milestone stabilization bundle implementation`

下一轮应保持 docs-only，总结 command packet -> validation -> normalization -> ordering 的 owner chain，固定 canonical tail、current truth、stop-line 与 future reopening conditions。它不批准 integration runtime boundary、backend readiness、receipt / record / publication、command buffer、renderer state write、render execution 或 public surface expansion。

## Downstream Packet Owner-truth Milestone

Renderer packet owner-truth milestone 已完成：

- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md)

该 milestone 固定 command packet 非 diagnostics owner chain，并确认 current canonical packet truth 是 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`。下一步转向 docs-only `P1 internal Renderer backend / Metal reference pack decision`，为未来 backend-readiness preflight 收集官方资料，而不是继续 integration wrapper。
