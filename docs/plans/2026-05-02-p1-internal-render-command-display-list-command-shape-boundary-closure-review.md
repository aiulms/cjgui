# P1 internal RenderCommand / DisplayList command shape boundary closure review

日期：2026-05-02

状态：implementation closure

## Result

`P1 internal RenderCommand / DisplayList command shape boundary bundle implementation` 已完成。

修改 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`

该实现保持同一 Scene / Renderer owner / truth，只消费 `CjguiInternalRendererInputPacket`，把已有 renderer input packet 投影为 command-shape value facts。

## Added Symbols

- `CjguiInternalRenderCommandKind`
- `CjguiInternalRenderCommand`
- `CjguiInternalRenderCommandList`
- `CjguiInternalRenderCommandPacket`
- `cjguiInternalDefaultRenderCommandKind`
- `cjguiInternalBuildRenderCommandFromNode`
- `cjguiInternalBuildRenderCommandList`
- `cjguiInternalBuildRenderCommandPacket`
- `cjguiInternalExecuteDefaultRenderCommandShapeDraft`

## Boundary

The new command-shape layer is internal and value-style:

- `CjguiInternalRenderCommandKind` is a placeholder kind. The default is node placeholder, not real drawing op.
- `CjguiInternalRenderCommand` preserves stable node id / bounds / clip / z-order / material key / scene version / display list version / invalidation hint.
- `CjguiInternalRenderCommandList` expresses full rebuild command list facts.
- `CjguiInternalRenderCommandPacket` is backend-agnostic command-shape endpoint.

It does not create a backend packet, command buffer, render pass, platform object, native handle, or raw pointer.

## Full Rebuild Decision

P1 remains full DisplayList rebuild only.

The command list carries full rebuild command-shape facts and explicitly avoids incremental command update / backend submission. It does not implement dirty region, repaint boundary, display list diff, display list patch, partial repaint, render cache, or batching.

## Stop-line

Stop-line remained intact:

- no Metal / AppKit / backend / CAMetalLayer / command buffer.
- no native handle / raw pointer / platform object.
- no render side effect.
- no actual drawing op semantics.
- no Widget / Layout / Text / IME / Accessibility implementation.
- no ECS engine.
- no dirty-region / diff / patch implementation.
- no Queue / Action / Runtime lower-level mutable facts.
- no `runtime_state.cj` touch.
- no `runtime/cjgui/cjpm.toml` change.
- no public surface expansion.

## Public Symbol Allowlist

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本轮未新增 public symbol，未修改 Bool-only signature，未新增 structured public return。

## GitNexus

Pre-edit impact was requested for:

- `CjguiInternalRendererInputPacket`
- `cjguiInternalExecuteDefaultSceneRendererInputDraft`

Both returned UNKNOWN / not found because the new Scene / Renderer owner has not been indexed yet. No HIGH / CRITICAL risk was reported. `gitnexus_detect_changes(scope=unstaged)` was run after implementation; indexed diff risk was low with 0 affected processes. New / untracked owner symbols remain GitNexus UNKNOWN until the repo is re-indexed.

## Verification

- `cjpm build --target-dir /tmp/cjgui-render-command-display-list-command-shape-target --skip-script`：通过；仅出现既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- closure reachable from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`：通过。
- forbidden file check：通过；`runtime_state.cj` 未触碰，仍为 10065 行，`runtime/cjgui/cjpm.toml` / smoke tracked source / harness / native bridge / entry / `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md` 未修改。
- public declaration scan：通过；allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line scan：通过；新增源码行未出现 Metal / AppKit / Objective-C / native handle / raw pointer / CAMetalLayer / command buffer / dirty-region / diff / patch / ECS / Widget / Layout / Text / IME / Accessibility / public symbol。

## Next Opening

`P1 internal RenderCommand / DisplayList command shape closure / next renderer command-boundary decision`
