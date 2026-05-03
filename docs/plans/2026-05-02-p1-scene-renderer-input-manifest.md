# P1 Scene / Renderer input manifest

日期：2026-05-02

状态：manifest stabilization

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`

当前 truth：

- internal value-style renderer input candidate facts。
- 当前 canonical endpoint 是 `CjguiInternalRendererInputPacket` / `cjguiInternalExecuteDefaultSceneRendererInputDraft()`。
- 这不是真实 renderer state，不是 backend state，不是 platform resource，不是 runtime global state。

该 owner 的默认输入是 minimal default scene input，不读取 Queue / Action / Runtime lower-level mutable facts。

## Current Pipeline

当前 Scene / Renderer input 第一刀 pipeline：

1. `CjguiInternalSceneVersion`
2. `CjguiInternalRenderNodeId`
3. `CjguiInternalRenderBounds`
4. `CjguiInternalRenderClip`
5. `CjguiInternalRenderMaterialKey`
6. `CjguiInternalRenderInvalidationHint`
7. `CjguiInternalSceneSnapshot`
8. `CjguiInternalRenderNode`
9. `CjguiInternalRenderDisplayList`
10. `CjguiInternalRendererInputPacket`

当前 RenderCommand / DisplayList command shape extension：

1. `CjguiInternalRenderCommandKind`
2. `CjguiInternalRenderCommand`
3. `CjguiInternalRenderCommandList`
4. `CjguiInternalRenderCommandPacket`

Default draft：

- `cjguiInternalExecuteDefaultSceneRendererInputDraft()`
- `cjguiInternalExecuteDefaultRenderCommandShapeDraft()`

Default path：

- minimal default scene snapshot。
- scene -> render node。
- render node -> full display list。
- display list -> renderer input packet。
- renderer input packet -> render command list -> render command packet。

## Scene / DisplayList Layering

`CjguiInternalSceneSnapshot` / `CjguiInternalRenderNode` 保留 semantic layer：

- semantic scene identity。
- hierarchy placeholder。
- future AI projection hints。
- future hit-test / accessibility projection hints only。

这些 facts 不是 Widget tree、Layout tree、Text system、IME system、Accessibility system 或 runtime global state。

`CjguiInternalRenderDisplayList` / `CjguiInternalRendererInputPacket` 表达 dehydrated renderer input layer：

- flat display list facts。
- backend-agnostic input packet。
- full rebuild metadata。
- renderer boundary candidate facts。

这些 facts 不是 backend command buffer，不是 platform object，不是 native handle，也不执行 rendering。

`CjguiInternalRenderCommand` / `CjguiInternalRenderCommandList` / `CjguiInternalRenderCommandPacket` 表达 dehydrated command-shape layer：

- node-placeholder command kind。
- stable node id / bounds / clip / z-order / material key / version / invalidation hint projection。
- full rebuild command list facts。
- backend-agnostic command packet。

这些 facts 不是真实 drawing op，不是 backend submission，不创建 command buffer，也不触发 rendering。

## Full Rebuild Policy

P1 默认 full DisplayList rebuild only。

当前不实现：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental renderer cache。

当前只预留 value facts / hints：

- stable id。
- bounds。
- clip。
- z-order。
- material key。
- scene version。
- display list version。
- repaint / invalidation hint。

这些字段只表示未来增量渲染可以审计的契约位置，不表示当前已经实现增量渲染。

## Stop-line

继续禁止：

- no Metal / AppKit / backend / CAMetalLayer / command buffer。
- no native handle / raw pointer / platform object。
- no render side effect。
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

当前 command-shape boundary 已落地，并已由独立 manifest 固定 owner / truth / stop-line：

- [2026-05-02-p1-render-command-display-list-command-shape-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-display-list-command-shape-manifest.md)

下一步自然候选：

- `P1 internal RenderCommand material / batching hint boundary bundle implementation`

下一轮仍应只细化 backend-agnostic material / batching / ordering facts，不接 backend、不 render。继续满足：

- 不接 backend / Metal / AppKit。
- 不创建 CAMetalLayer / command buffer。
- 不 render。
- 不实现 Widget / Layout / Text / IME / Accessibility。
- 不做 dirty-region / diff / patch。
- 不触碰 `runtime_state.cj`。

## Downstream Packet Owner-truth Milestone

Renderer packet owner-truth milestone 已完成：

- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md)

Milestone 将 `CjguiInternalRendererInputPacket` 固定为 command packet 非 diagnostics owner chain 的第一层，并确认当前 canonical packet truth 已推进到 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`。它不批准 backend、command buffer、render execution、renderer state write、dirty-region、Widget / Layout / Text / IME / Accessibility 或 public surface expansion。
