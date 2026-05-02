# P1 RenderCommand material / batching next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Current Facts

- `P1 internal RenderCommand material / batching hint boundary bundle implementation` 已完成。
- 当前 owner file 是 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- 当前 endpoint 是 `CjguiInternalRenderBatchingPacket` / `cjguiInternalExecuteDefaultRenderBatchingHintDraft()`。
- Material / batching hint 只消费 `CjguiInternalRenderCommandPacket`，输出 backend-agnostic value facts。
- `CjguiInternalRenderBatchKey` 只是 hint，不是真实 GPU pipeline key。
- `CjguiInternalRenderOrderingHint` 不执行排序副作用。
- `CjguiInternalRenderBatchingPlan` 是 dehydrated plan，不是真实 draw-call merge 或 GPU batching。
- P1 仍是 full DisplayList / command list rebuild only。
- 当前没有 dirty-region、diff、patch 或 incremental render。
- 当前没有 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer。
- 当前没有 render side effect，没有 real draw op、Widget / Layout / Text / IME / Accessibility / ECS implementation。
- public symbol allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Decision

选择 A：`P1 internal RenderCommand material / batching hint manifest stabilization bundle implementation`。

Material / batching hint 是渲染方向中最容易被误读成真实 renderer backend 能力的一层。`BatchKey`、`OrderingHint`、`BatchingPlan` 目前都只是 backend-agnostic value facts，不是 GPU pipeline key、排序执行、draw-call merge 或 batch scheduler。下一步先做 manifest stabilization，固定 owner / truth / stop-line，比直接进入 renderer packet handoff 或 backend preflight 更安全。

## Candidate Comparison

- A. RenderCommand material / batching hint manifest stabilization：选择。它固定 `MaterialHint` / `BatchKey` / `OrderingHint` / `BatchingPlan` / `BatchingPacket` 的 owner / truth / stop-line，防止 batching 术语误开 backend / GPU batching。
- B. Renderer packet handoff boundary：暂缓。它是自然下一步，但应等 material / batching manifest 固定后再消费 `CjguiInternalRenderBatchingPacket` 并交给 downstream backend-adapter candidate owner。
- C. backend / Metal preflight：拒绝。当前 batching packet 不是 backend permission，也不是 command buffer 或 render pass。
- D. real draw op semantics：拒绝。当前 command kind 与 batching hint 都不承诺真实 drawing op。
- E. real GPU batching / draw-call merge：拒绝。当前 batching plan 明确是 dehydrated plan，不执行合批。
- F. Dirty region / incremental render preflight：暂缓。P1 仍 full rebuild only，增量渲染只保留 future hint。
- G. Widget / Layout / Text / IME / Accessibility：暂缓。Scene / Renderer input runway 仍在 renderer contract 层。
- H. ECS implementation：拒绝。当前只吸收 stable id / flat facts，不实现 ECS engine。
- I. Runtime / Queue / Action integration：暂缓。当前 default scene / renderer path 不读取 lower-level mutable facts，也不得靠近 `runtime_state.cj`。
- J. public surface expansion：拒绝。public shell milestone 已封账，public allowlist 不扩第二个 symbol。
- K. tail consolidation：不选择。当前没有明确 dead helper、重复 projection 或 same-owner self-wrapping；新 material / batching layer 需要 manifest 封账，不是 cleanup。

## Manifest Stabilization Scope

下一轮应以 docs / manifest stabilization 为主，可新增：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md`

Manifest 应固定：

- `runtime/cjgui/src/runtime_scene_renderer_input.cj` 是 Scene / Renderer input、RenderCommand command-shape 与 material / batching hint 的同一 owner。
- `CjguiInternalRenderBatchingPacket` 是 current material / batching hint endpoint，不是真实 renderer state、backend packet、command buffer、draw-call merge 或 GPU batching permission。
- `CjguiInternalRenderMaterialHint` 只保留 material key / command kind / z-order / clip / version facts，不绑定 material resource。
- `CjguiInternalRenderBatchKey` 只是 hint key，不是真实 GPU pipeline key。
- `CjguiInternalRenderOrderingHint` 只是 ordering value fact，不执行排序副作用。
- `CjguiInternalRenderBatchingPlan` 是 dehydrated plan，不是真实 draw-call merge。
- P1 full DisplayList / command list rebuild only；dirty-region / repaint boundary / diff / patch / partial repaint 继续禁止。

## Stop-line

下一轮仍不得：

- 新增 runtime code，除非只补注释且先明确说明。
- 接 Metal / AppKit / Objective-C / backend / platform object。
- 接 native handle / raw pointer / CAMetalLayer / command buffer。
- render 或实现真实 draw op semantics。
- 实现真实 GPU batching / draw-call merge / batch scheduler。
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

`P1 internal RenderCommand material / batching hint manifest stabilization bundle implementation`
