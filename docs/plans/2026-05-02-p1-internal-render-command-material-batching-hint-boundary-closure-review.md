# P1 internal RenderCommand material / batching hint boundary closure review

日期：2026-05-02

状态：implementation closure

## Result

`P1 internal RenderCommand material / batching hint boundary bundle implementation` 已完成。

修改 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`

该实现保持同一 Scene / Renderer owner / truth，只消费 `CjguiInternalRenderCommandPacket`，把 command packet 投影为 material / ordering / batching hint value facts。

## Added Symbols

- `CjguiInternalRenderMaterialHint`
- `CjguiInternalRenderBatchKey`
- `CjguiInternalRenderOrderingHint`
- `CjguiInternalRenderBatchingPlan`
- `CjguiInternalRenderBatchingPacket`
- `cjguiInternalBuildRenderMaterialHint`
- `cjguiInternalBuildRenderBatchKey`
- `cjguiInternalBuildRenderOrderingHint`
- `cjguiInternalBuildRenderBatchingPlan`
- `cjguiInternalBuildRenderBatchingPacket`
- `cjguiInternalExecuteDefaultRenderBatchingHintDraft`

## Boundary

The new material / batching hint layer is internal and value-style:

- `CjguiInternalRenderMaterialHint` preserves material key / command kind / z-order / clip / version facts.
- `CjguiInternalRenderBatchKey` is a hint key, not a real graphics pipeline key.
- `CjguiInternalRenderOrderingHint` records ordering facts without sorting side effects.
- `CjguiInternalRenderBatchingPlan` is a dehydrated plan, not real draw-call merge.
- `CjguiInternalRenderBatchingPacket` is the new backend-agnostic hint endpoint.

It does not create a backend packet, command buffer, render pass, platform object, native handle, raw pointer, graphics device resource, or batching engine.

## Full Rebuild Decision

P1 remains full DisplayList / command list rebuild only.

The batching plan carries full rebuild hint facts and explicitly avoids command merge / incremental batch update. It does not implement dirty region, repaint boundary, display list diff, display list patch, partial repaint, render cache, actual draw-call merge, or GPU batching.

## Stop-line

Stop-line remained intact:

- no Metal / AppKit / backend / CAMetalLayer / command buffer.
- no native handle / raw pointer / platform object.
- no render side effect.
- no actual drawing op semantics.
- no real draw-call merge / GPU batching implementation.
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

- `CjguiInternalRenderCommandPacket`
- `cjguiInternalExecuteDefaultRenderCommandShapeDraft`

Both returned UNKNOWN / not found because the new Scene / Renderer owner has not been indexed yet. No HIGH / CRITICAL risk was reported. `gitnexus_detect_changes(scope=unstaged)` was run after implementation; risk level was low with 0 affected processes. New / untracked owner symbols remain GitNexus UNKNOWN until the repo is re-indexed.

## Verification

- `cjpm build --target-dir /tmp/cjgui-render-command-material-batching-hint-target --skip-script`：通过；仅出现既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- closure reachable from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`：通过。
- forbidden file check：通过；`runtime_state.cj` 未触碰，仍为 10065 行，`runtime/cjgui/cjpm.toml` / smoke tracked source / harness / native bridge / entry / `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md` 未修改。
- public declaration scan：通过；allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line scan：通过；新增源码行未出现 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer / real draw-call merge / GPU batching / Widget / Layout / Text / IME / Accessibility / dirty-region / diff / patch / public symbol。

## Next Opening

`P1 internal RenderCommand material / batching hint closure / next renderer command-boundary decision`
