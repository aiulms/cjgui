# P1 Scene / Renderer input preflight decision

日期：2026-05-01

状态：docs-only preflight

## Current Facts

- Queue / public shell milestone 已封账。
- 当前唯一 public symbol allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- 本轮不扩 public surface，不新增第二个 public symbol。
- 当前 next phase 已选择 Scene / Renderer input preflight。
- Future radar 已记录：[2026-05-01-p1-ai-native-architecture-radar-future-plan.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-ai-native-architecture-radar-future-plan.md)。
- Radar 明确 P1 只吸收 Scene / DisplayList / ECS 神韵，不接 Metal，不做 dirty region，不实现 renderer。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Preflight Conclusion

选择 A：`P1 internal Scene / Renderer input contract boundary bundle implementation`。

下一轮应新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj` 或等价 owner，定义 internal-only value-style Scene / Renderer input contract。第一刀只建立 semantic scene 与 dehydrated display list / renderer input packet 的中间契约，不接 backend，不 render，不实现 widget / layout / text / IME / accessibility。

## Upstream Truth

第一刀不直接从现有 Queue / Action / Runtime lower-level mutable facts 派生 scene truth。原因：

- Queue / public shell runway 证明了 boundary governance，但它不是 UI tree truth。
- 当前没有稳定 Widget Tree / UI Tree / Scene owner。
- 直接读取 lower-level mutable queue / runtime facts 会绕过 owner chain，也容易把 queue facts 误升格为 rendering truth。
- `runtime_state.cj` 处于 10065 行 critical warning，不应作为 Scene / Renderer input 的第一刀 owner。

因此第一刀应建立独立 renderer-input owner。若没有稳定 upstream UI tree truth，则先定义 minimal default scene input / empty semantic scene，不读 lower-level mutable facts。

## Scene / DisplayList Layering

P1 应采用双层模型：

- `SceneSnapshot` / `RenderNode`：保留 semantic / hierarchy / hit-test / accessibility / AI projection hints。
- `DisplayList` / `RenderCommandList`：脱水、扁平、可批处理、backend-agnostic。
- `RendererInputPacket`：将 display list 与 version / rebuild metadata 封成后续 renderer backend 的输入 candidate。

该分层让上游保留语义，避免 backend 直接消费 state tree、queue facts 或 widget tree；下游只面对 flat value facts。

## Full Rebuild Strategy

P1 默认 full DisplayList rebuild。

当前不做：

- Dirty Region。
- Repaint Boundary。
- DisplayList diff。
- DisplayList patch。
- render cache / atlas / batching。

但第一刀必须预留未来增量字段：

- stable id。
- bounds。
- clip。
- z-order。
- material key。
- scene version。
- display list version。
- repaint / invalidation hint。

这些字段只作为 value facts / hints，不表示 P1 已经实现 incremental render。

## Backend / Platform Stop-line

本 preflight 明确拒绝：

- Metal。
- AppKit。
- Objective-C bridge。
- platform object。
- native handle。
- raw pointer。
- renderer backend implementation。
- public C ABI。

下一轮 implementation 不得修改 `runtime/cjgui/cjpm.toml`，不得接 native bridge、smoke harness 或 entry files。

## Widget / Layout / Text / Accessibility Stop-line

本 preflight 明确拒绝实现：

- Widget / DSL。
- Layout。
- Text shaping。
- IME。
- Accessibility system。
- Hit-test implementation。

Scene / Renderer input 可以预留 semantic / hit-test / accessibility / AI projection hints，但这些只是 fields / value facts，不是系统实现。

## Runtime State Stop-line

下一轮不得触碰 `runtime_state.cj`。Scene / Renderer input owner 必须新建独立 file，避免继续扩大 critical file，也避免把 renderer input truth 放入 runtime global state。

## Candidate Comparison

- A. Scene / Renderer input contract boundary implementation：选择。新建 `runtime_scene_renderer_input.cj`，定义 value-style `SceneSnapshot` / `RenderNode` / `DisplayList` / `RendererInputPacket` candidate，不接 backend，不 render。
- B. Renderer backend / Metal preflight：拒绝。太早靠近 platform backend，且 P1 radar 明确不接 Metal。
- C. Widget / Layout model：暂缓。Scene / Renderer input contract 应先于 widget DSL 和 layout model。
- D. Text / IME / Accessibility model：暂缓。第一刀只预留 semantic fields / hints，不实现系统。
- E. Dirty region / incremental render preflight：暂缓。P1 先 full rebuild，字段预留即可。
- F. ECS implementation：拒绝。只吸收 stable id / flat component facts，不实现 ECS engine。
- G. Public API expansion：拒绝。public shell milestone 已封账，不继续扩 public surface。
- H. Runtime state integration：拒绝。太靠近 critical `runtime_state.cj` 和 global runtime state。

## Next Implementation Shape

建议下一轮：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- 定义 internal-only value-style types:
- `CjguiInternalSceneSnapshot`
- `CjguiInternalRenderNode`
- `CjguiInternalRenderDisplayList`
- `CjguiInternalRendererInputPacket`

可选但不要过多：

- `CjguiInternalRenderCommand`
- `CjguiInternalRenderInvalidationHint`

Default draft：

- 构造 minimal empty/default scene。
- 从 scene 生成 full display list。
- 从 display list 生成 renderer input packet。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不 render。

## Verification Expectations

下一轮 implementation 应验证：

- `cjpm build --target-dir <scene-renderer-input-target> --skip-script`。
- smoke guard。
- `git diff --check`。
- Markdown absolute link check。
- GitNexus detect_changes。
- forbidden check：不修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- platform scan：不出现 Metal / AppKit / Objective-C / platform object / native handle / raw pointer intake。
- feature scan：不出现 Widget / Layout / Text / IME / Accessibility implementation。

## Next Opening

`P1 internal Scene / Renderer input contract boundary bundle implementation`
