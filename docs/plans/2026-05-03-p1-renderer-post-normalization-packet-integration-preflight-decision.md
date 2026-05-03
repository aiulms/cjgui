# P1 Renderer post-normalization packet integration preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Purpose

本 preflight 从 renderer diagnostics branch 回到 command packet / normalized packet 非 diagnostics 路线，评估 `CjguiInternalRendererPacketOrderingHardeningResult` 后是否存在足够 downstream owner / consumer / gate / integration evidence，可以打开 post-normalization packet integration runway。

本轮不批准 runtime implementation，不新增 `.cj`，不运行 build / smoke。

## Inputs Reviewed

- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)
- [2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-manifest-stabilization-closure-review.md)
- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)
- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)
- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)
- [2026-05-02-p1-renderer-backend-tail-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-tail-milestone-manifest.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Current Endpoint

当前 upstream endpoint 是：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

它只表达 ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts。它不执行排序，不做 draw-call merge / GPU batching，不改 packet，不是 backend packet、command buffer、renderer state write、render execution 或 render permission。

## Evidence Assessment

当前 evidence 不足以批准 `P1 internal Renderer post-normalization packet integration value boundary bundle implementation`。

已有事实：

- Normalization manifest 已固定 `CjguiInternalRendererPacketNormalizationResult`，但它只表达 normalized packet / ordering / material grouping backend-agnostic value facts。
- Ordering / material grouping manifest 已固定 `CjguiInternalRendererPacketOrderingHardeningResult`，但它只补强 no-sort / no-merge / hint preservation gate。
- 旧 `runtime_renderer_handoff.cj` 属于 backend no-render tail 起点，只消费 `CjguiInternalRenderBatchingPacket`，endpoint 是 `CjguiInternalRendererPacketHandoffReceipt`。
- Backend tail milestone 已记录 handoff -> adapter -> contract -> capability -> selection -> binding 一度触发 Same-shape Boundary Brake。

仍缺失的 evidence：

- 没有明确 downstream consumer。
- 没有明确 integration gate owner。
- 没有明确 non-backend integration lifecycle。
- 没有 build-level or manifest-level evidence 证明 integration owner 不会成为 ordering hardening result 的 receipt / record / publication thin wrapper。
- 没有证据支持复用旧 `runtime_renderer_handoff.cj` 的 batching-packet handoff receipt 语义。

因此本轮选择先做 owner-truth / evidence stabilization，而不是实现 integration wrapper。

## Future Owner Guard

如果未来 evidence 足够，候选 owner 可以是：

- `runtime/cjgui/src/runtime_renderer_packet_integration.cj`

但本 preflight 不批准创建该文件。未来若打开 runtime boundary，必须先证明：

- 输入只消费 `CjguiInternalRendererPacketOrderingHardeningResult`。
- 输出 truth 只能是 packet integration intent / integration candidate / integration gate / no-backend integration readiness value facts。
- integration gate 不得是 ordering hardening result receipt / record / publication。
- owner 不复用旧 `runtime_renderer_handoff.cj` 的 batching-packet handoff receipt 语义。

## Stop-line

继续禁止：

- no runtime code in this preflight round。
- no `.cj` modifications。
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

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮继续生效。

本 preflight 明确拒绝把 `CjguiInternalRendererPacketOrderingHardeningResult` 包成：

- packet integration receipt。
- packet integration record。
- packet integration publication。
- hardening readiness wrapper。
- post-normalization handoff wrapper。
- backend readiness wrapper。

如果没有 concrete downstream owner / consumer / gate / integration evidence，继续新增 runtime owner 只会重复旧 backend tail 的 self-wrapping 风险。当前更稳的动作是固定 packet integration owner-truth / evidence requirements。

## Candidate Comparison

### A. P1 internal Renderer post-normalization packet integration value boundary bundle implementation

暂缓。

只有 preflight 能证明 downstream consumer / gate / integration evidence 足够时才应选择。当前 evidence 不足，因此不批准新建 `runtime_renderer_packet_integration.cj`，也不批准任何 integration readiness implementation。

### B. P1 internal Renderer packet integration manifest / owner-truth preflight stabilization

选择。

理由：

- 当前问题不是 runtime 缺口，而是 downstream owner / consumer / gate evidence 仍不够。
- 先固定 integration owner-truth、input-only rule、output truth、old handoff avoidance、backend stop-line，可以防止把 ordering hardening result 包成 thin wrapper。
- 仍保持 docs-only，不接 backend / command buffer / renderer state / render execution。

### C. P1 internal Renderer backend-readiness preflight decision

暂缓。

Backend-readiness 仍太靠近 backend packet、command buffer、renderer state write 和 render permission。没有 integration owner-truth evidence 前，不应进入 backend readiness。

### D. Packet integration receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### E. Backend shell continuation

谨慎暂缓。

Backend shell / backend tail 曾触发 Same-shape Boundary Brake。除非未来有新的 owner truth、consumer、gate 或 integration evidence，不应回到 shell continuation。

### F. Backend / command buffer / render execution / renderer state write

拒绝。

Ordering hardening endpoint 不是 backend permission、command buffer readiness、renderer state write gate 或 render execution gate。

### G. Metal / AppKit / platform resource / native handle

拒绝。

当前 packet integration preflight 不持有平台资源，不允许创建、传递或承诺 native handle / raw pointer / platform object。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍固定 full DisplayList / command list rebuild。UI system、layout、text、IME、accessibility、dirty-region、diff / patch 需要独立 owner truth。

### I. Diagnostics branch reopening

暂缓。

Diagnostics branch 已通过 milestone / audit / hardening 正式封账，本轮不重开 diagnostics tail。

### J. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### K. Consolidation

暂缓。

只有发现 duplicate fields、duplicate builders、low-value helper、self-wrapping owner、manifest drift 或 build-level dead code evidence 时才开。当前 preflight 没有这类 evidence。

## Decision

最终选择：

`P1 internal Renderer packet integration manifest / owner-truth preflight stabilization`

结论：`CjguiInternalRendererPacketOrderingHardeningResult` 目前不足以直接进入 runtime integration boundary。下一轮应继续 docs-only，固定 packet integration owner / truth / evidence requirements / old handoff avoidance / no-backend stop-line；不得新建 integration wrapper、receipt、record、publication、backend readiness、command buffer readiness、renderer state write 或 render permission。

## Downstream Owner-truth Manifest

Renderer packet integration owner-truth preflight manifest 已完成：

- [2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-integration-owner-truth-preflight-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-integration-owner-truth-preflight-stabilization-closure-review.md)

该 manifest 固定当前不批准 `runtime_renderer_packet_integration.cj`、不批准 integration receipt / record / publication、不复用旧 `runtime_renderer_handoff.cj` batching-packet handoff receipt 语义，并将下一步转为：

`P1 internal Renderer packet owner-truth milestone stabilization bundle implementation`
