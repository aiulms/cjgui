# P1 Renderer packet owner-truth milestone manifest

日期：2026-05-03

状态：milestone stabilization

## Purpose

本 milestone 总结并封账 renderer command packet 非 diagnostics runway 的 owner / truth / canonical endpoint chain。

当前 packet truth 已到 ordering / material grouping hardening endpoint。Integration / backend-readiness 的 downstream owner / consumer / gate evidence 暂不足，因此本 milestone 不批准新建 runtime owner，不批准 post-normalization handoff wrapper，不批准 backend-readiness wrapper，也不批准 command buffer / render execution / renderer state write。

## Packet Owner Chain

当前 renderer command packet 非 diagnostics owner chain：

1. Scene / Renderer input：`CjguiInternalRendererInputPacket` / `cjguiInternalExecuteDefaultSceneRendererInputDraft()`
2. RenderCommand shape：`CjguiInternalRenderCommandPacket` / `cjguiInternalExecuteDefaultRenderCommandShapeDraft()`
3. Material / batching hint：`CjguiInternalRenderBatchingPacket` / `cjguiInternalExecuteDefaultRenderBatchingHintDraft()`
4. Renderer packet handoff legacy tail：`CjguiInternalRendererPacketHandoffReceipt`
5. Backend no-render tail：adapter / contract / capability / selection / binding / shell milestones
6. Validation：`CjguiInternalRendererCommandValidationResult` / `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`
7. Normalization：`CjguiInternalRendererPacketNormalizationResult` / `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`
8. Ordering / material grouping hardening：`CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

The legacy packet handoff / backend no-render tail is retained as historical context and backend runway evidence, not as proof for post-normalization integration. It cannot be reused as the current normalized / ordering packet integration owner.

## Current Canonical Packet Truth

Current canonical packet truth for the non-diagnostics runway：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

Current truth：

- renderer input facts。
- render command shape facts。
- material / batching hint facts。
- command / batching packet validation facts。
- normalized packet candidate facts。
- normalized ordering facts。
- normalized material grouping hint facts。
- ordering basis facts。
- material grouping scope facts。
- hint preservation policy facts。
- no-sort-no-merge gate facts。

The canonical packet truth is backend-agnostic and value-style. It does not mutate packets, does not sort, does not merge draw calls, does not build backend packets, and does not authorize rendering.

## Legacy Tail Status

`CjguiInternalRendererPacketHandoffReceipt` and the backend no-render tail remain documented as a legacy / historical branch:

- handoff receipt。
- backend adapter candidate / no-render readiness。
- backend contract / no-render contract readiness。
- backend capability profile / no-render capability readiness。
- adapter selection / no-render selection readiness。
- adapter binding / no-render binding readiness。
- backend shell / no-render shell readiness。

This branch helped expose backend runway vocabulary, but it also triggered Same-shape Boundary Brake. It must not be treated as evidence that post-normalization packet integration is ready.

## Current Explicit Non-decisions

当前明确不批准：

- no `runtime_renderer_packet_integration.cj`。
- no post-normalization handoff wrapper。
- no normalized packet receipt / record / publication。
- no ordering packet receipt / record / publication。
- no integration receipt / record / publication。
- no backend readiness wrapper。
- no command buffer readiness wrapper。
- no backend packet generation。
- no command buffer。
- no render execution。
- no renderer state write。
- no render permission。

## Evidence Gap

当前缺口是 downstream owner / consumer / gate / integration evidence 不足。

这不是以下 owner 的失败：

- Scene / Renderer input。
- RenderCommand shape。
- Material / batching hint。
- Validation。
- Normalization。
- Ordering / material grouping hardening。

Future integration or backend-readiness work needs concrete downstream evidence rather than another tail wrapper.

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 milestone 生效。

本 milestone 的目的就是刹住 packet integration / backend-readiness 薄包装：

- 不把 `CjguiInternalRendererPacketOrderingHardeningResult` 包成 integration readiness。
- 不把 ordering hardening result 包成 backend readiness。
- 不把 normalized / ordering packet 包成 receipt / record / publication。
- 不复用旧 `runtime_renderer_handoff.cj` batching-packet handoff receipt 作为 post-normalization integration evidence。

未来若要开 integration 或 backend-readiness，必须先 docs-only preflight，并提供：

- concrete downstream owner evidence。
- concrete consumer / gate / acceptance evidence。
- concrete platform lifecycle evidence if backend-readiness is involved。
- explicit proof that the new boundary is not receipt / record / publication / readiness thin wrapper。

## Stop-line

继续禁止：

- no runtime code in this milestone round。
- no `.cj` modifications。
- no new runtime owner。
- no backend implementation。
- no backend shell / adapter continuation implementation。
- no Metal / AppKit implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no platform resource / native handle / raw pointer / platform object。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no diagnostics branch reopening。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 milestone 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer backend readiness evidence preflight decision

谨慎暂缓。

该方向只能做 docs-only preflight，评估 backend-readiness owner / gate evidence，不得实现 backend。当前 packet integration evidence 仍不足，直接评估 backend readiness 可能过早靠近 backend packet、command buffer、renderer state write 与 render permission。

### B. P1 internal Renderer backend / Metal reference pack decision

选择为下一阶段 opening。

理由：

- 在真正靠近 backend / Metal 前，需要小而硬的官方参考包。
- Reference pack 可以收集 Metal / AppKit / CAMetalLayer / lifecycle / frame pacing 的官方资料，为未来 backend-readiness preflight 提供硬依据。
- 它仍是 docs-only，不改变代码，不打开 backend implementation，不创建 command buffer 或 platform object。

### C. Renderer command packet hardening follow-up

暂缓。

只有发现 validation / normalization / ordering 表达不足时才开。当前 evidence gap 不在 packet facts 本身。

### D. Backend shell / adapter revisit

暂缓。

Backend shell / adapter tail 曾触发 Same-shape Boundary Brake。没有新的 owner truth / platform lifecycle evidence 前，不应回到该尾巴。

### E. Packet integration runtime boundary

拒绝。

当前 downstream owner / consumer / gate / integration evidence 不足。

### F. Receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### G. Backend / command buffer / render execution / renderer state write

拒绝。

当前 milestone 不批准 backend implementation、command buffer、render execution、renderer state write 或 render permission。

### H. Metal / AppKit / platform resource / native handle implementation

拒绝。

Reference pack 可以收集资料，但不实现 Metal / AppKit、platform resource、native handle 或 raw pointer。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍是 full DisplayList / command list rebuild。UI system、layout、text、IME、accessibility、dirty-region、diff / patch 需要独立 owner truth。

### J. Diagnostics branch reopening

暂缓。

Diagnostics branch 已封账，本 milestone 不重开 diagnostics tail。

### K. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### L. Consolidation

暂缓。

只有发现 duplicate fields、duplicate builders、low-value helper、self-wrapping owner、manifest drift 或 build-level dead code evidence 时才开。当前没有这类 evidence。

## Decision

最终 next opening：

`P1 internal Renderer backend / Metal reference pack decision`

下一轮应保持 docs-only，小范围收集官方 Metal / AppKit / CAMetalLayer / lifecycle / frame pacing 资料，为未来 backend-readiness preflight 提供硬依据。它不批准 backend implementation、command buffer、renderer state write、render execution、platform resource / native handle、public surface expansion 或 dirty-region / UI system implementation。

## Downstream Backend / Metal Reference Pack Decision

Renderer backend / Metal reference pack decision 已完成：

- [2026-05-03-p1-renderer-backend-metal-reference-pack-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack-decision.md)

该 decision 确认 current canonical packet truth 仍是 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`，并选择下一步进入 docs-only `P1 internal Renderer backend / Metal reference pack bundle implementation`。

Reference pack 只服务未来 backend-readiness preflight，范围限制在官方 Metal command buffer / render pass lifecycle、`CAMetalLayer` drawable lifecycle、AppKit view / resize lifecycle、frame pacing、Retina scale / color space 与 resource ownership evidence。它不批准 backend implementation、command buffer、renderer state write、render execution、platform resource owner boundary 或 public surface expansion。

## Downstream Backend / Metal Reference Pack

Renderer backend / Metal reference pack 已完成：

- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-internal-renderer-backend-metal-reference-pack-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-backend-metal-reference-pack-closure-review.md)

该 reference pack 只记录 future backend-readiness preflight 的官方依据和问题清单。它确认 Metal command buffer / render pass lifecycle、`CAMetalLayer` drawable lifecycle、AppKit view / resize / backing scale、frame pacing 与 resource ownership 都必须留在 future backend / platform owner 评估内，不能反向进入 current packet truth。

下一步转向 docs-only `P1 internal Renderer backend-readiness preflight decision`，评估是否具备 backend owner / platform resource confinement / command queue and command buffer lifecycle / drawable acquisition / no-draw rollback path evidence。仍不批准 backend implementation、command buffer、renderer state write、render execution 或 public surface expansion。

## Downstream Backend-readiness Preflight

Renderer backend-readiness preflight 已完成：

- [2026-05-03-p1-renderer-backend-readiness-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-readiness-preflight-decision.md)

该 preflight 保持 current canonical packet truth 为 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`，并判定不批准把该 endpoint 包成 backend-readiness wrapper。当前缺口转向 platform resource owner truth：`MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer 的 owner、confinement、lifecycle、no-draw failure path 需要先做 docs-only preflight。

最终 next opening 是 `P1 internal Renderer platform resource owner preflight decision`。

## Downstream Platform Resource Owner Preflight

Renderer platform resource owner preflight 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md)

该 preflight 继续保持 current canonical packet truth 为 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`，并判定下一步若实现 platform resource owner value boundary，runtime input 只能消费该 ordering hardening endpoint；reference pack / backend-readiness docs 只提供 constraints，不是 runtime facts。

最终 next opening 是 `P1 internal Renderer platform resource owner value boundary bundle implementation`。该 next opening 仍不批准 backend、Metal / AppKit、`MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、render pass、render encoder、native handle、raw pointer、renderer state write 或 render execution。
