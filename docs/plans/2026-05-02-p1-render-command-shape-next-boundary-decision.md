# P1 RenderCommand shape next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Current Facts

- `P1 internal RenderCommand / DisplayList command shape boundary bundle implementation` 已完成。
- 修改 owner file：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- 当前新增 endpoint 是 `CjguiInternalRenderCommandPacket` / `cjguiInternalExecuteDefaultRenderCommandShapeDraft()`。
- `RenderCommand` / `RenderCommandList` / `RenderCommandPacket` 只从 `CjguiInternalRendererInputPacket` 投影 command-shape facts。
- command kind 仍是 placeholder，不是真实 draw op。
- P1 仍是 full DisplayList rebuild only。
- 当前没有 dirty-region、diff、patch 或 incremental render。
- 当前没有 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer。
- 当前没有 render side effect，没有 Widget / Layout / Text / IME / Accessibility / ECS implementation。
- public symbol allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Decision

选择 A：`P1 internal RenderCommand / DisplayList command shape manifest stabilization bundle implementation`。

RenderCommand 是 Scene / Renderer input runway 的第二个关键概念。上一刀已经证明 renderer input packet 可以被投影成 command-shape facts，但这些 facts 仍只是 dehydrated / backend-agnostic / placeholder value facts。下一步先做 manifest stabilization，固定 owner / truth / stop-line，比继续细化 material / batching hint 更安全，也能防止后续把 placeholder command kind 误读为真实 drawing op 或 backend permission。

## Candidate Comparison

- A. RenderCommand / DisplayList command shape manifest stabilization：选择。它固定 command-shape owner / truth / stop-line，明确 placeholder command kind 不是真实 draw op，且 P1 仍 full rebuild only。
- B. command attribute / material / batching hint boundary：暂缓。它是自然下一步，但应等 command-shape manifest 固定后再细化 material key、batch hint、ordering facts。
- C. real draw op semantics：拒绝。当前 command kind 是 placeholder，不能直接升级为真实绘制语义。
- D. renderer backend / Metal preflight：拒绝。`CjguiInternalRenderCommandPacket` 不是 backend permission，也不是 command buffer 或 render pass。
- E. Widget / Layout / Text / IME / Accessibility：暂缓。Scene / Renderer input 和 command shape 仍在 contract 层，不应抢先实现上层 UI 系统。
- F. Dirty region / incremental render preflight：暂缓。P1 明确 full DisplayList rebuild only，增量渲染只保留 future hint，不实现 diff / patch。
- G. ECS implementation：拒绝。当前只吸收 stable id / flat value facts，不实现 ECS engine。
- H. Runtime / Queue / Action integration：暂缓。当前 renderer direction 使用 minimal default scene，不应马上读取 lower-level mutable facts。
- I. public surface expansion：拒绝。public shell milestone 已封账，public allowlist 不扩第二个 symbol。
- J. tail consolidation：不选择。当前没有明确 dead helper、重复 projection 或 same-owner self-wrapping；新 command-shape layer 需要 manifest 封账，不是 cleanup。

## Manifest Stabilization Scope

下一轮应以 docs / manifest stabilization 为主，可新增：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-display-list-command-shape-manifest.md`

Manifest 应固定：

- `runtime/cjgui/src/runtime_scene_renderer_input.cj` 是 Scene / Renderer input 与 RenderCommand command-shape 的同一 owner。
- `CjguiInternalRenderCommandPacket` 是 current command-shape endpoint，不是真实 renderer state、backend packet、command buffer 或 draw-call permission。
- `CjguiInternalRenderCommandKind` 是 placeholder kind，不是真实 drawing op taxonomy。
- `CjguiInternalRenderCommand` 只携带 stable node id / bounds / clip / z-order / material key / version / invalidation hint 等 value facts。
- `CjguiInternalRenderCommandList` 只表达 full rebuild command list facts，不表达 incremental command patch。
- P1 full DisplayList rebuild only；dirty-region / repaint boundary / diff / patch / partial repaint 继续禁止。

## Stop-line

下一轮仍不得：

- 新增 runtime code，除非只补注释且先明确说明。
- 接 Metal / AppKit / Objective-C / backend / platform object。
- 接 native handle / raw pointer / CAMetalLayer / command buffer。
- render 或实现真实 draw op semantics。
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

`P1 internal RenderCommand / DisplayList command shape manifest stabilization bundle implementation`
