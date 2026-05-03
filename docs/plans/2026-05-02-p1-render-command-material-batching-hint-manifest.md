# P1 RenderCommand material / batching hint manifest

日期：2026-05-02

状态：manifest stabilization

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`

当前 material / batching truth：

- internal value-style `CjguiInternalRenderBatchingPacket`。
- default endpoint 是 `cjguiInternalExecuteDefaultRenderBatchingHintDraft()`。
- 它只从 `CjguiInternalRenderCommandPacket` 投影 material / ordering / batching hint facts。

该 truth 不是 backend batch object，不是真实 GPU batching plan，不是 renderer backend command buffer，不是真实 draw-call merge，也不是 renderer state write。

## Current Pipeline

当前 material / batching hint pipeline：

1. `CjguiInternalRenderCommandPacket`
2. `CjguiInternalRenderMaterialHint`
3. `CjguiInternalRenderBatchKey`
4. `CjguiInternalRenderOrderingHint`
5. `CjguiInternalRenderBatchingPlan`
6. `CjguiInternalRenderBatchingPacket`

当前 default path：

- minimal default scene -> render node -> full display list -> renderer input packet。
- renderer input packet -> placeholder command kind / render command。
- render command -> full rebuild command list。
- command list -> backend-agnostic command packet。
- command packet -> material hint / batch key / ordering hint。
- material / ordering hints -> full rebuild batching plan。
- batching plan -> backend-agnostic batching packet。

## Material / Batching Shape

`CjguiInternalRenderMaterialHint` 是 backend-agnostic value fact：

- material key。
- command kind。
- z-order。
- clip。
- scene / display / command version。

`CjguiInternalRenderBatchKey` 是 hint：

- 它可以把 material key / command kind / clip / version 收束成未来 batching 审计 key。
- 它不是真实 GPU pipeline key。
- 它不授权 pipeline state、shader state、render pass 或 backend resource。

`CjguiInternalRenderOrderingHint` 是 value fact：

- 它保留 z-order / command order / full rebuild ordering facts。
- 它不执行排序副作用。
- 它不表示 backend scheduler、draw queue 或 render pass ordering 已经存在。

`CjguiInternalRenderBatchingPlan` 是 dehydrated plan：

- 它只描述 future backend handoff 前的 batching hint shape。
- 它不是真实 draw-call merge。
- 它不是真实 GPU batching。
- 它不创建 batching engine、command buffer、platform object 或 renderer state。

`CjguiInternalRenderBatchingPacket` 是 future backend handoff 前的 value packet：

- 它是 backend-agnostic hint endpoint。
- 它不是 backend command buffer。
- 它不是 renderer backend packet。
- 它不是 draw-call permission。

## Full Rebuild Policy

P1 仍保持 full DisplayList / command list / batching packet rebuild only。

当前不实现：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental command update。
- incremental batching update。
- partial repaint。
- render cache。
- actual draw-call merge。
- GPU batching。

当前仅预留审计位置：

- stable node id。
- bounds。
- clip。
- z-order。
- material key。
- scene / display list / command list version。
- invalidation / repaint hint。
- batch key hint。
- ordering hint。

这些字段只为未来 renderer packet handoff / backend preflight 留出契约位置，不表示当前已经实现 backend batching 或 incremental render。

## Stop-line

继续禁止：

- no Metal / AppKit / backend / CAMetalLayer / command buffer。
- no native handle / raw pointer / platform object。
- no render side effect。
- no real draw op semantics。
- no real GPU pipeline key。
- no real draw-call merge / GPU batching。
- no Widget / Layout / Text / IME / Accessibility implementation。
- no ECS engine。
- no dirty-region / diff / patch implementation。
- no Queue / Action / Runtime lower-level mutable facts。
- no `runtime_state.cj` touch。
- no public surface expansion。
- no `runtime/cjgui/cjpm.toml` change。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Boundary Recommendation

Renderer packet handoff boundary 已落地：

- [2026-05-02-p1-internal-renderer-packet-handoff-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-handoff-boundary-closure-review.md)

它只消费 `CjguiInternalRenderBatchingPacket`，把 Scene / Renderer input owner 的 backend-agnostic output 交给 future adapter 前的 handoff facts。它仍满足：

- 不接 backend / Metal / AppKit。
- 不创建 CAMetalLayer / command buffer。
- 不 render。
- 不实现真实 draw op、真实 draw-call merge 或真实 GPU batching。
- 不做 dirty-region / diff / patch。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不触碰 `runtime_state.cj`。

Renderer backend-adapter value boundary 已落地：

- [2026-05-02-p1-internal-renderer-backend-adapter-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-backend-adapter-value-boundary-closure-review.md)

它只消费 `CjguiInternalRendererPacketHandoffReceipt`，把 handoff receipt 投影为 backend adapter candidate / capability placeholder / adapter admission / no-render readiness value facts。它仍满足：

- 不接 backend / Metal / AppKit implementation。
- 不创建 CAMetalLayer / MTLDevice / command buffer / GPU device。
- 不接 native handle / raw pointer / platform object。
- 不 render。
- 不实现真实 draw op、真实 draw-call merge 或真实 GPU batching。
- 不做 dirty-region / diff / patch。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不触碰 `runtime_state.cj`。

下一步自然候选：

- `P1 internal Renderer backend-adapter value boundary closure / next renderer backend contract decision`

下一轮应先做 docs-only next-boundary decision，判断 no-render readiness 后是否进入 backend contract decision、backend-adapter manifest stabilization、backend contract value boundary 或继续暂缓 backend。

Renderer backend contract value boundary 已落地：

- [2026-05-02-p1-internal-renderer-backend-contract-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-backend-contract-value-boundary-closure-review.md)

它只消费 `CjguiInternalRendererBackendNoRenderReadiness`，把 adapter readiness 投影为 backend contract / capability set / adapter contract admission / no-render contract readiness value facts。它仍满足：

- 不接 backend / Metal / AppKit implementation。
- 不创建 CAMetalLayer / MTLDevice / command buffer / GPU device。
- 不接 native handle / raw pointer / platform object。
- 不 render。
- 不实现真实 draw op、真实 draw-call merge 或真实 GPU batching。
- 不做 dirty-region / diff / patch。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不触碰 `runtime_state.cj`。

Renderer backend capability profile boundary 已落地：

- [2026-05-02-p1-internal-renderer-backend-capability-profile-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-backend-capability-profile-boundary-closure-review.md)

它只消费 `CjguiInternalRendererBackendNoRenderContractReadiness`，把 contract readiness 投影为 backend capability profile / feature placeholder / constraint profile / no-render capability readiness value facts。它仍满足：

- 不接 backend / Metal / AppKit implementation。
- 不创建 CAMetalLayer / MTLDevice / command buffer / GPU device。
- 不接 native handle / raw pointer / platform object。
- 不写具体平台能力枚举承诺。
- 不 render。
- 不实现真实 draw op、真实 draw-call merge 或真实 GPU batching。
- 不做 dirty-region / diff / patch。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不触碰 `runtime_state.cj`。

当前下一步自然候选：

- `P1 internal Renderer backend capability profile closure / next renderer adapter selection decision`

下一轮应先做 docs-only next-boundary decision，判断 no-render capability readiness 后是否进入 renderer adapter selection decision、capability manifest stabilization、adapter selection value boundary 或继续暂缓 backend。

Renderer adapter selection value boundary 已落地：

- [2026-05-02-p1-internal-renderer-adapter-selection-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-adapter-selection-value-boundary-closure-review.md)

它只消费 `CjguiInternalRendererBackendNoRenderCapabilityReadiness`，把 capability readiness 投影为 adapter selection policy / adapter candidate family / selection admission / no-render selection readiness value facts。它仍满足：

- 不选择具体平台 adapter，不写 Metal / AppKit adapter。
- 不创建 CAMetalLayer / MTLDevice / command buffer / GPU device。
- 不接 native handle / raw pointer / platform object。
- 不写具体平台能力或 adapter 承诺。
- 不 render。
- 不实现真实 draw op、真实 draw-call merge 或真实 GPU batching。
- 不做 dirty-region / diff / patch。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不触碰 `runtime_state.cj`。

当前下一步自然候选：

- `P1 internal Renderer adapter selection value boundary closure / next renderer adapter binding decision`

下一轮应先做 docs-only next-boundary decision，判断 no-render selection readiness 后是否进入 renderer adapter binding decision、adapter selection manifest stabilization、binding value boundary 或继续暂缓 backend。

Renderer adapter binding value boundary 已落地：

- [2026-05-02-p1-internal-renderer-adapter-binding-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-adapter-binding-value-boundary-closure-review.md)

它只消费 `CjguiInternalRendererNoRenderSelectionReadiness`，把 selection readiness 投影为 adapter binding intent / adapter binding candidate / binding admission / no-render binding readiness value facts。它仍满足：

- 不绑定具体平台 adapter，不写 Metal / AppKit adapter。
- 不创建 CAMetalLayer / MTLDevice / command buffer / GPU device。
- 不接 native handle / raw pointer / platform object。
- 不写具体平台能力或 adapter 承诺。
- 不 render。
- 不实现真实 draw op、真实 draw-call merge 或真实 GPU batching。
- 不做 dirty-region / diff / patch。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不触碰 `runtime_state.cj`。

Renderer adapter binding next-lifecycle decision 已完成：

- [2026-05-02-p1-renderer-adapter-binding-next-lifecycle-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-adapter-binding-next-lifecycle-decision.md)

该 decision 不批准直接进入 adapter lifecycle implementation。理由是 handoff -> backend adapter -> contract -> capability -> selection -> binding 已形成高度同构 no-render backend tail；在当前 stop-line 下，adapter lifecycle 还不能拥有资源 acquire / release、真实平台 lifecycle phase、backend object 或 renderer state truth，继续 implementation 容易变成 binding 后的 thin wrapper。

Renderer backend tail milestone manifest 已完成：

- [2026-05-02-p1-renderer-backend-tail-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-tail-milestone-manifest.md)
- [2026-05-02-p1-internal-renderer-backend-tail-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-backend-tail-milestone-stabilization-closure-review.md)

Manifest 固定 `CjguiInternalRendererNoRenderBindingReadiness` / `cjguiInternalExecuteDefaultRendererAdapterBindingDraft()` 为当前 backend no-render tail canonical endpoint。Same-shape Boundary Brake 生效：当前不继续新增 lifecycle wrapper，而是转向 backend shell preflight。

Renderer backend shell preflight decision 已完成：

- [2026-05-02-p1-renderer-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-shell-preflight-decision.md)

该 preflight 选择 `P1 internal Renderer backend shell value boundary bundle implementation`。下一轮可新建 `runtime_renderer_backend_shell.cj`，只消费 `CjguiInternalRendererNoRenderBindingReadiness`，表达 backend shell intent / candidate / admission / no-render shell readiness internal value facts；它仍不批准 backend implementation、Metal / AppKit adapter、CAMetalLayer / MTLDevice、command buffer、native handle / raw pointer、render execution、draw call 或 renderer state write，也不得退化成 lifecycle / receipt / record 同构尾巴。

Renderer backend shell value boundary 已落地：

- [2026-05-02-p1-internal-renderer-backend-shell-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-backend-shell-value-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererBackendNoRenderShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellDraft()`。它只消费 `CjguiInternalRendererNoRenderBindingReadiness`，把 backend tail canonical endpoint 投影为 future backend shell owner truth / vocabulary / entry contract / no platform shell / no stable backend interface promise facts；仍不是 backend implementation、平台对象、图形执行资源、renderer state write 或 render permission。

Renderer backend shell next-contract decision 已完成：

- [2026-05-02-p1-renderer-backend-shell-next-contract-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-shell-next-contract-decision.md)

该 decision 选择 `P1 internal Renderer command packet validation boundary bundle implementation`。理由是 backend shell 已经包含 entry contract / no stable backend interface facts；继续 shell contract readiness 会有同构自包风险。下一刀回到 command / batching packet integrity：只表达 backend-agnostic validation facts，不接 backend、不 render、不写 renderer state。

Renderer command packet validation boundary 已落地：

- [2026-05-02-p1-internal-renderer-command-packet-validation-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-command-packet-validation-boundary-closure-review.md)

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_command_validation.cj`

当前 downstream endpoint：

- `CjguiInternalRendererCommandValidationResult`
- `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`

该 endpoint 只消费 `CjguiInternalRenderBatchingPacket`，校验 command packet 与 batching packet 是否保留 full rebuild only、stable node id、bounds、clip、z-order、material key、version、invalidation hint、placeholder command kind、batch key hint、ordering hint 和 dehydrated batching plan。它不是 backend shell、platform adapter、backend implementation、renderer state write、绘制许可或 command buffer readiness。

Renderer command packet validation manifest 已完成：

- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)
- [2026-05-02-p1-internal-renderer-command-packet-validation-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-command-packet-validation-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererCommandValidationResult` / `cjguiInternalExecuteDefaultRendererCommandValidationDraft()` 为 validation canonical endpoint。Same-shape Boundary Brake 生效：下一阶段不新增 validation receipt / record / publication，而是先进入 packet normalization preflight。

Renderer packet normalization boundary 已落地：

- [2026-05-02-p1-internal-renderer-packet-normalization-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-normalization-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererPacketNormalizationResult` / `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`。它只消费 `CjguiInternalRendererCommandValidationResult`，表达 backend-agnostic normalized packet candidate / ordering facts / material grouping hints / normalization result；它不执行 sorting side effect，不做真实 draw-call merge / GPU batching，不生成 backend packet / command buffer，也不写 renderer state。

Renderer packet normalization manifest 已完成：

- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)
- [2026-05-02-p1-internal-renderer-packet-normalization-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-normalization-manifest-stabilization-closure-review.md)

该 manifest 固定 normalization owner / truth / canonical endpoint / stop-line，并选择下一阶段进入 `P1 internal Renderer packet error taxonomy boundary bundle implementation`。下一阶段仍只做 backend-agnostic value facts，不进入 backend packet、command buffer、sorting side effect、draw-call merge、GPU batching、diff / patch 或 render execution。

Renderer command packet ordering / material grouping manifest 已完成：

- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)
- [2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-manifest-stabilization-closure-review.md)

该 downstream manifest 固定 `runtime_renderer_packet_ordering.cj` owner / truth / canonical endpoint / stop-line。`CjguiInternalRendererPacketOrderingHardeningResult` 只表达 ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts；它不执行排序，不做真实 draw-call merge / GPU batching，不改 packet，不接 backend / command buffer / renderer state write / render execution。

## Downstream Packet Owner-truth Milestone

Renderer packet owner-truth milestone 已完成：

- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md)

Milestone 将 `CjguiInternalRenderBatchingPacket` 固定为 command packet 非 diagnostics owner chain 的 material / batching hint 层，并将旧 `CjguiInternalRendererPacketHandoffReceipt` / backend no-render tail 标记为 legacy context。当前 canonical packet truth 是 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`；不批准复用旧 handoff receipt 作为 post-normalization integration evidence。
