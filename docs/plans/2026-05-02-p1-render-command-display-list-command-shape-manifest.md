# P1 RenderCommand / DisplayList command shape manifest

日期：2026-05-02

状态：manifest stabilization

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`

当前 command truth：

- internal value-style `CjguiInternalRenderCommandPacket`。
- default draft endpoint 是 `cjguiInternalExecuteDefaultRenderCommandShapeDraft()`。
- 它只从 `CjguiInternalRendererInputPacket` 投影 command-shape facts。

该 truth 不是真实 renderer backend command buffer，不是真实 draw call，不是 platform object，不是 native handle，也不是 renderer state write。

## Current Pipeline

当前 RenderCommand / DisplayList command-shape pipeline：

1. `CjguiInternalRendererInputPacket`
2. `CjguiInternalRenderCommandKind`
3. `CjguiInternalRenderCommand`
4. `CjguiInternalRenderCommandList`
5. `CjguiInternalRenderCommandPacket`

当前 material / batching hint extension：

1. `CjguiInternalRenderMaterialHint`
2. `CjguiInternalRenderBatchKey`
3. `CjguiInternalRenderOrderingHint`
4. `CjguiInternalRenderBatchingPlan`
5. `CjguiInternalRenderBatchingPacket`

当前 default path：

- minimal default scene -> render node -> full display list -> renderer input packet。
- renderer input packet -> placeholder command kind。
- renderer input packet root node -> render command。
- renderer input packet + render command -> full rebuild command list。
- command list -> backend-agnostic render command packet。
- command packet -> material hint / batch key / ordering hint。
- material / ordering hints -> full rebuild batching plan。
- batching plan -> backend-agnostic batching packet。

## Command Shape

`CjguiInternalRenderCommandKind` 是 placeholder kind：

- 它可以标记 no-op / node-placeholder / future fill-rect placeholder 这类 command-shape 位置。
- 当前默认仍是 node placeholder。
- 它不是真实 drawing op taxonomy。
- 它不授权 backend draw call、render pass、command buffer 或 GPU submission。

`CjguiInternalRenderCommand` 保留 dehydrated render facts：

- stable node id。
- bounds。
- clip。
- z-order。
- material key。
- scene version。
- display list version。
- invalidation / repaint hint。

这些 facts 只描述 command shape，不描述真实 drawing semantics。

`CjguiInternalRenderCommandList` / `CjguiInternalRenderCommandPacket` 是 backend-agnostic dehydrated facts：

- command list 是 full rebuild list。
- command packet 是 command-shape endpoint。
- 它们不是 renderer backend packet，不是 command buffer，不是 draw-call queue，也不触发 rendering。

`CjguiInternalRenderMaterialHint` / `RenderBatchKey` / `RenderOrderingHint` / `RenderBatchingPlan` / `RenderBatchingPacket` 表达 material / batching hint layer，并已由独立 manifest 固定 owner / truth / stop-line：

- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)

- material hint 保留 material key / command kind / z-order / clip / version facts。
- batch key 只是 hint，不是真实 GPU pipeline key。
- ordering hint 是 value fact，不执行排序副作用。
- batching plan 是 dehydrated plan，不是真实 draw-call merge。
- batching packet 是 backend-agnostic hint endpoint，不是 batching engine。

## Full Rebuild Policy

P1 仍保持 full DisplayList / command list rebuild only。

当前不实现：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental command update。
- partial repaint。
- render cache。
- actual draw-call merge。
- GPU batching。

当前仅预留审计位置：

- stable id。
- bounds。
- clip。
- z-order。
- material key。
- scene / display list / command list version。
- invalidation / repaint hint。

这些字段只为未来增量渲染 preflight 留出契约位置，不表示当前已经实现 incremental render。

## Stop-line

继续禁止：

- no Metal / AppKit / backend / CAMetalLayer / command buffer。
- no native handle / raw pointer / platform object。
- no render side effect。
- no real draw op semantics。
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

当前 material / batching hint manifest 已完成：

- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)

下一步自然候选：

- `P1 internal Renderer packet handoff boundary bundle implementation`

下一轮应只消费 `CjguiInternalRenderBatchingPacket`，表达 renderer packet handoff / backend-adjacent candidate value facts。继续满足：

- 不接 backend / Metal / AppKit。
- 不创建 CAMetalLayer / command buffer。
- 不 render。
- 不实现真实 draw op 或真实 draw-call merge。
- 不做 dirty-region / diff / patch。
- 不触碰 `runtime_state.cj`。
