# P1 internal RenderCommand / DisplayList command shape manifest stabilization closure review

日期：2026-05-02

状态：manifest stabilization closure

## Result

`P1 internal RenderCommand / DisplayList command shape manifest stabilization bundle implementation` 已完成。

本轮新增：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-display-list-command-shape-manifest.md`

本轮没有修改 runtime code，没有修改 `runtime_scene_renderer_input.cj`，没有新增 runtime symbol。

## Manifest Conclusion

RenderCommand / DisplayList command shape 已封为 manifest：

- owner file 是 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- current command truth 是 internal value-style `CjguiInternalRenderCommandPacket`。
- default endpoint 是 `cjguiInternalExecuteDefaultRenderCommandShapeDraft()`。
- command truth 只从 `CjguiInternalRendererInputPacket` 投影。
- command truth 不是真实 renderer backend command buffer，不是真实 draw call，也不是 renderer state write。

## Current Pipeline

当前 command-shape pipeline：

1. `CjguiInternalRendererInputPacket`
2. `CjguiInternalRenderCommandKind`
3. `CjguiInternalRenderCommand`
4. `CjguiInternalRenderCommandList`
5. `CjguiInternalRenderCommandPacket`

## Boundary

Command shape 仍是 internal value facts：

- command kind 是 placeholder，不是真实 drawing op taxonomy。
- command 保留 stable node id / bounds / clip / z-order / material key / version / invalidation hint。
- command list 表达 full rebuild command list facts。
- command packet 是 backend-agnostic dehydrated endpoint。

它不创建 backend packet、command buffer、render pass、platform object、native handle 或 raw pointer。

## Full Rebuild Decision

P1 仍保持 full DisplayList / command list rebuild only。

本轮不批准：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental command update。
- partial repaint。
- render cache。

## Stop-line

RenderCommand stop-line 保持：

- no Metal / AppKit / backend / CAMetalLayer / command buffer。
- no native handle / raw pointer / platform object。
- no render side effect。
- no real draw op semantics。
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

`gitnexus_detect_changes(scope=unstaged)` 已运行；risk level 为 low，affected processes 为 0。该结果覆盖当前 unstaged 工作区，GitNexus 对新文档 / 未跟踪文档的索引映射可能不完整；本轮实际 write set 仍为 docs / manifest / tracker / README scope。`runtime_state.cj` 未触碰，仍为 10065 行。

## Verification

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- manifest / closure reachable from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`：通过。
- README / runtime README can find RenderCommand manifest or current status：通过。
- forbidden file check：通过；`runtime_state.cj` 未触碰，仍为 10065 行，`runtime/cjgui/cjpm.toml` / smoke tracked source / harness / native bridge / entry / `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md` 未修改。
- public declaration scan：通过；allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- source stop-line scan：通过；本轮未修改 runtime source，未新增 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer / Widget / Layout / Text / IME / Accessibility / dirty-region / diff / patch / public symbol。
- build / smoke：未运行，因为本轮没有修改 `.cj` runtime code。

## Next Opening

`P1 internal RenderCommand material / batching hint boundary bundle implementation`
