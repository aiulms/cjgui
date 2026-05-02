# P1 internal RenderCommand material / batching hint manifest stabilization closure review

日期：2026-05-02

状态：manifest stabilization closure

## Result

`P1 internal RenderCommand material / batching hint manifest stabilization bundle implementation` 已完成。

本轮新增：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md`

本轮没有修改 runtime code，没有修改 `runtime_scene_renderer_input.cj`，没有新增 runtime symbol。

## Manifest Conclusion

RenderCommand material / batching hint 已封为 manifest：

- owner file 是 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- current batching truth 是 internal value-style `CjguiInternalRenderBatchingPacket`。
- default endpoint 是 `cjguiInternalExecuteDefaultRenderBatchingHintDraft()`。
- batching truth 只从 `CjguiInternalRenderCommandPacket` 投影。
- batching truth 不是 backend batch object，不是真实 GPU batching plan，不是真实 draw-call merge，也不是 renderer state write。

## Current Pipeline

当前 material / batching hint pipeline：

1. `CjguiInternalRenderCommandPacket`
2. `CjguiInternalRenderMaterialHint`
3. `CjguiInternalRenderBatchKey`
4. `CjguiInternalRenderOrderingHint`
5. `CjguiInternalRenderBatchingPlan`
6. `CjguiInternalRenderBatchingPacket`

## Boundary

Material / batching hint 仍是 internal value facts：

- material hint 是 backend-agnostic value fact。
- batch key 是 hint，不是真实 GPU pipeline key。
- ordering hint 不执行排序副作用。
- batching plan 是 dehydrated plan，不是真实 draw-call merge。
- batching packet 是 future backend handoff 前的 value packet，不是 backend command buffer。

它不创建 backend packet、command buffer、render pass、platform object、native handle、raw pointer、graphics device resource、batching engine 或 renderer state。

## Full Rebuild Decision

P1 仍保持 full DisplayList / command list / batching packet rebuild only。

本轮不批准：

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

## Stop-line

Material / batching hint stop-line 保持：

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
- no `runtime/cjgui/cjpm.toml` change。
- no public surface expansion。

## Public Symbol Allowlist

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本轮未新增第二个 public symbol，未修改 Bool-only signature，未新增 structured public return。

## GitNexus

本轮为 docs-only manifest stabilization，未修改 `.cj` symbol，因此未运行 symbol impact。

`gitnexus_detect_changes(scope=unstaged)` 已运行，risk level 为 low，affected processes 为 0。由于 scope 覆盖整个 unstaged 工作区，报告中包含前序未提交文档 / 索引映射痕迹；本轮实际 write set 仍为 README / tracker / plans manifest / runtime README docs-only scope。`runtime_state.cj` 未触碰，仍为 10065 行。

## Verification

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- new-doc whitespace check：通过。
- manifest / closure reachable from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`：通过。
- README / runtime README can find material / batching manifest or current status：通过。
- forbidden file check：通过；本轮未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan：通过；allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- source stop-line scan：通过；本轮没有 runtime source diff，未新增 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer / real draw-call merge / GPU batching / Widget / Layout / Text / IME / Accessibility / dirty-region / diff / patch / public symbol。
- build / smoke：本轮没有修改 `.cj` runtime code，默认不运行。

## Next Opening

`P1 internal Renderer packet handoff boundary bundle implementation`
