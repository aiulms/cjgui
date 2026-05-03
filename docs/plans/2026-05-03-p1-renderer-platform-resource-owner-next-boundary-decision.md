# P1 Renderer platform resource owner next boundary decision

日期：2026-05-03

状态：docs-only next-boundary decision

## Purpose

本 decision 评估 `CjguiInternalRendererNoPlatformResourceReadiness` 是否已经足够作为当前 platform resource owner endpoint，并决定下一步是否先做 manifest stabilization。

本轮不修改 `.cj`，不实现 backend / Metal / AppKit / CAMetalLayer / command buffer / render execution / renderer state write，不运行 build / smoke。

Upstream references：

- [2026-05-03-p1-internal-renderer-platform-resource-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)

## Current Endpoint Assessment

Current platform resource owner endpoint：

- `CjguiInternalRendererNoPlatformResourceReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`

Owner file：

- [runtime_renderer_platform_resource.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_resource.cj)

Current upstream packet truth remains：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

`CjguiInternalRendererNoPlatformResourceReadiness` is sufficient as the current no-platform-resource endpoint because it seals all current value facts needed before platform lifecycle work:

- platform resource owner intent。
- resource confinement policy。
- drawable acquisition policy。
- command queue ownership policy。
- no-platform-resource readiness。

The endpoint explicitly remains value-only. It is not a command queue lifecycle owner, drawable acquisition lifecycle owner, backend-readiness wrapper, backend owner, platform resource holder, command buffer readiness, render execution gate, renderer state write permission, public API, native handle, or raw pointer surface.

## Decision

选择下一阶段：

`P1 internal Renderer platform resource owner manifest stabilization bundle implementation`

理由：

- `CjguiInternalRendererNoPlatformResourceReadiness` 已足够作为当前 platform resource owner endpoint。
- 继续直接拆 command queue lifecycle 或 drawable acquisition lifecycle 会过早靠近真实 platform resource lifecycle。
- Manifest stabilization 可以先固定 owner / truth / canonical endpoint / stop-line，避免 no-platform-resource endpoint 后继续长 receipt / record / publication 或 backend-readiness wrapper。
- Backend / Metal reference pack 仍只是 docs evidence，不是 runtime input，也不是 implementation permission。

## Candidate Comparison

### A. P1 internal Renderer platform resource owner manifest stabilization bundle implementation

推荐并选择。

它只做 docs / manifest stabilization，固定 `runtime_renderer_platform_resource.cj` 的 owner / truth / canonical endpoint / stop-line。它不新增 runtime code，不创建 platform resource，不进入 backend readiness wrapper。

### B. Command queue lifecycle preflight

暂缓到 manifest 后再评估。

Command queue lifecycle 太靠近 future backend owner lifecycle。必须先封账 no-platform-resource endpoint，防止把 readiness 误读成 command queue permission。

### C. Drawable acquisition lifecycle preflight

暂缓到 manifest 后再评估。

Drawable acquisition lifecycle 太靠近 `CAMetalLayer` drawable pool、late-bound acquisition、timeout / unavailable path。当前只允许 value facts，不允许真实 acquisition。

### D. Platform resource owner hardening

暂缓。

仅在发现 resource confinement / acquisition / ownership 表达不足时选择。当前 closure 已证明 intent / confinement / acquisition / queue ownership / no-platform-resource readiness 语义齐备。

### E. Platform resource receipt / record / publication

拒绝。

这是 thin wrapper 风险最高的方向，会把 `CjguiInternalRendererNoPlatformResourceReadiness` 改名包装。

### F. Backend-readiness wrapper

拒绝。

当前 backend-readiness evidence 曾因 platform owner truth 不足而停下；现在应先封 platform resource owner manifest，而不是把 no-platform-resource endpoint 包成 backend-readiness wrapper。

### G. Backend / Metal implementation

拒绝。

### H. Command buffer / render execution / renderer state write

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

Public allowlist remains only:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前主要任务是 manifest stabilization。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效：

- `CjguiInternalRendererNoPlatformResourceReadiness` 已经是当前 no-platform-resource endpoint。
- 不批准 platform resource receipt / record / publication。
- 不批准 backend-readiness wrapper。
- 不批准 command queue readiness wrapper。
- 不批准 drawable acquisition readiness wrapper。

若未来靠近 command queue / drawable / platform resource lifecycle，必须先 docs-only preflight，不能直接实现。

## Stop-line

继续禁止：

- no runtime code in this decision round。
- no `.cj` modifications。
- no backend / Metal / AppKit implementation。
- no `MTLDevice` / `CAMetalLayer` creation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation or submission。
- no render pass / encoder creation。
- no render execution / draw call。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no receipt / record / publication wrapper。
- no backend-readiness wrapper。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Next Opening

`P1 internal Renderer platform resource owner manifest stabilization bundle implementation`

下一轮仍必须 docs / manifest stabilization，不得修改 `.cj`，不得实现 backend / Metal / AppKit / CAMetalLayer / command queue / drawable / command buffer / render execution / renderer state write。Manifest 必须固定 owner file、canonical endpoint、default draft、current truth、explicit non-truth、Same-shape Boundary Brake 与后续 command queue / drawable lifecycle reopening 条件。

## Downstream Manifest Stabilization

Renderer platform resource owner manifest stabilization 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_platform_resource.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoPlatformResourceReadiness` / `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`。下一步选择 docs-only `P1 internal Renderer command queue lifecycle preflight decision`，不得直接创建 command queue、drawable、command buffer、backend object、platform object、render pass、encoder、native handle 或 raw pointer。
