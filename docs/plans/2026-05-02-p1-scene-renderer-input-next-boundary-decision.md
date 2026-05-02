# P1 Scene / Renderer input next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Current Facts

- `P1 internal Scene / Renderer input contract boundary bundle implementation` 已完成。
- 新 owner file 已建立：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- 当前 endpoint 是 `CjguiInternalRendererInputPacket` / `cjguiInternalExecuteDefaultSceneRendererInputDraft()`。
- 当前 pipeline 是 minimal default scene -> render node -> full display list -> renderer input packet。
- 该 owner 不读取 Queue / Action / Runtime lower-level mutable facts。
- 该 owner 不接 Metal / AppKit / backend / native handle / raw pointer。
- 该 owner 不 render，不实现 Widget / Layout / Text / IME / Accessibility。
- 该 owner 不做 dirty-region / diff / patch / ECS。
- P1 仍明确 full DisplayList rebuild only，并预留 stable id / bounds / clip / z-order / material key / version / repaint hint。
- public symbol allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Decision

选择 A：`P1 internal Scene / Renderer input manifest stabilization bundle implementation`。

Scene / Renderer input 是 Queue / public shell milestone 后的新大方向第一刀。`CjguiInternalRendererInputPacket` 已经足够证明 semantic scene -> dehydrated display list -> renderer input packet 的最小 value pipeline 可以成立，但术语和 stop-line 还需要先封账。下一步先做 manifest stabilization，比直接进入 `RenderCommand` / draw op 更稳，也能防止后续误把 renderer input packet 当成 backend permission。

## Candidate Comparison

- A. Scene / Renderer input manifest stabilization：选择。它固定 `SceneSnapshot` / `RenderNode` / `DisplayList` / `RendererInputPacket` 的 owner / truth / stop-line，适合新方向第一刀后的封账。
- B. RenderCommand / DisplayList command shape boundary：暂缓。它是自然下一步，但应等 manifest 明确 full rebuild、no backend、no layout/text/a11y 后再细化 command / draw op / batch hint。
- C. Renderer backend / Metal preflight：拒绝。当前 renderer input packet 不是 backend permission，P1 仍不接 Metal / AppKit。
- D. Widget / Layout model：暂缓。Scene / Renderer input contract 尚需 manifest 固化，Widget / Layout 不应抢先成为 truth owner。
- E. Text / IME / Accessibility model：暂缓。当前只预留 semantic hints，不实现系统。
- F. Dirty region / incremental render preflight：暂缓。P1 明确 full rebuild only，增量渲染仅保留字段与 hint。
- G. ECS implementation：拒绝。当前只吸收 stable id / flat value facts，不实现 ECS engine。
- H. Runtime state / Queue / Action integration：暂缓。第一刀使用 minimal default scene，不应马上读取 lower-level mutable facts，也不得靠近 `runtime_state.cj`。
- I. Public API expansion：拒绝。public shell milestone 已封账，本阶段不扩第二个 public symbol。
- J. Tail consolidation：不选择。当前没有明确 dead helper、重复 projection 或 self-wrapping；新 owner 需要的是 manifest 封账，不是 cleanup。

## Manifest Stabilization Scope

下一轮应以 docs / manifest 为主，可新增：

- `docs/plans/2026-05-02-p1-scene-renderer-input-manifest.md`

Manifest 应固定：

- `runtime_scene_renderer_input.cj` 是 Scene / Renderer input contract owner。
- `CjguiInternalSceneSnapshot` 是 semantic scene value，不是 Widget tree、Layout tree 或 runtime global state。
- `CjguiInternalRenderNode` 是 scene-to-render projection，不是 layout result、hit-test system 或 accessibility system。
- `CjguiInternalRenderDisplayList` 是 dehydrated flat display list facts，不是 backend command buffer。
- `CjguiInternalRendererInputPacket` 是 current canonical endpoint，不是 renderer backend permission。
- P1 full DisplayList rebuild only；dirty-region / diff / patch / repaint boundary 继续禁止。
- stable id / bounds / clip / z-order / material key / version / repaint hint 只是预留 facts。

## Stop-line

下一轮仍不得：

- 新增 runtime code，除非只补注释或极少 derived helper 且先另行说明。
- 接 Metal / AppKit / Objective-C / backend / platform object。
- 接 native handle / raw pointer / command buffer / layer。
- render。
- 实现 Widget / Layout / Text / IME / Accessibility。
- 实现 dirty-region / repaint boundary / diff / patch。
- 实现 ECS engine。
- 读取 Queue / Action / Runtime lower-level mutable facts。
- 修改 `runtime_state.cj`。
- 修改 `runtime/cjgui/cjpm.toml`。
- 扩 public surface 或新增第二个 public symbol。

## Public Surface

public symbol allowlist 继续保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 decision 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Opening

`P1 internal Scene / Renderer input manifest stabilization bundle implementation`
