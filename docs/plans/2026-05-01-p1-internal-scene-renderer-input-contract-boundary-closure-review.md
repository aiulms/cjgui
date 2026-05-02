# P1 internal Scene / Renderer input contract boundary closure review

日期：2026-05-01

状态：implementation closure

## Result

`P1 internal Scene / Renderer input contract boundary bundle implementation` 已完成。

新增 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_scene_renderer_input.cj`

## Added Symbols

- `CjguiInternalSceneVersion`
- `CjguiInternalRenderNodeId`
- `CjguiInternalRenderBounds`
- `CjguiInternalRenderClip`
- `CjguiInternalRenderMaterialKey`
- `CjguiInternalRenderInvalidationHint`
- `CjguiInternalSceneSnapshot`
- `CjguiInternalRenderNode`
- `CjguiInternalRenderDisplayList`
- `CjguiInternalRendererInputPacket`
- `cjguiInternalBuildDefaultSceneVersion`
- `cjguiInternalBuildDefaultRenderNodeId`
- `cjguiInternalBuildDefaultRenderBounds`
- `cjguiInternalBuildDefaultRenderClip`
- `cjguiInternalBuildDefaultRenderMaterialKey`
- `cjguiInternalBuildDefaultRenderInvalidationHint`
- `cjguiInternalBuildDefaultSceneSnapshot`
- `cjguiInternalBuildRenderNodeFromScene`
- `cjguiInternalBuildFullRenderDisplayList`
- `cjguiInternalBuildRendererInputPacket`
- `cjguiInternalExecuteDefaultSceneRendererInputDraft`

## Boundary

The owner defines only internal value-style Scene / Renderer input facts:

- Minimal default `SceneSnapshot`.
- `RenderNode` projection from the scene.
- Full-rebuild `RenderDisplayList`.
- `RendererInputPacket` canonical endpoint.

It does not consume Queue / Action / Runtime lower-level mutable facts. It does not read or write runtime global state and does not use `runtime_state.cj`.

## Full Rebuild Decision

P1 remains full DisplayList rebuild only.

The implementation reserves stable id / bounds / clip / z-order / material key / scene version / display list version / repaint hint facts, but it does not implement:

- Dirty Region.
- Repaint Boundary.
- DisplayList diff.
- DisplayList patch.
- render cache / atlas / batching.

## Stop-line

The implementation does not:

- connect a platform backend.
- accept platform objects, native handles, or raw pointers.
- create GPU devices, layers, or command streams.
- render.
- implement Widget / Layout / Text / IME / Accessibility.
- implement ECS storage / query scheduler.
- modify `runtime_state.cj`.
- modify `runtime/cjgui/cjpm.toml`.
- add a public symbol.

## GitNexus

New owner symbols are not expected to be indexed yet. No existing runtime symbol was modified, so no pre-edit symbol impact was required. `gitnexus_detect_changes(scope=unstaged)` reported low risk with 0 affected processes.

## Verification

- `cjpm build --target-dir /tmp/cjgui-scene-renderer-input-contract-boundary-target --skip-script`：通过；仅出现既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- closure reachable from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`：通过。
- forbidden file check：通过；`runtime_state.cj` 未触碰，仍为 10065 行。
- platform / backend scan：通过；新 owner 未出现 Metal / AppKit / Objective-C / native handle / raw pointer / CAMetalLayer / command buffer 等实现入口。
- feature stop-line scan：通过；新 owner 未实现 Widget / Layout / Text / IME / Accessibility、dirty-region、diff、patch 或 ECS。
- public declaration scan：通过；allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Next Opening

`P1 internal Scene / Renderer input contract closure / next renderer-input boundary decision`
