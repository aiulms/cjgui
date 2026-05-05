# P1 internal Renderer no-draw backend shell value boundary closure review

日期：2026-05-04

状态：closure review

## Scope

本轮执行 `P1 internal Renderer no-draw backend shell value boundary bundle implementation`。

允许新增一个 internal-only runtime owner file，但必须严格保持 no-backend-shell-object / no-platform-object / no-native-handle / no-render 边界。本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder 或 pipeline state；不调用 FFI / Objective-C / Metal / AppKit API；不修改 bridge、smoke、harness 或 native entry；不提交 / present / submit GPU work；不执行 render；不写 renderer state；不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Inputs Read

- [runtime_renderer_metal_device_layer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj)
- [2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- Adjacent renderer owner naming / fail-closed patterns in Metal device-layer, backend platform object and backend-readiness owners.

## GitNexus Impact

GitNexus impact was run before editing the downstream owner:

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`: `UNKNOWN` / target not found, affected count `0`.
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft`: `UNKNOWN` / target not found, affected count `0`.

Interpretation：these are recent renderer owner symbols present in source but not indexed yet. No HIGH / CRITICAL risk was returned, so implementation proceeded with source existence plus `cjpm build` fallback verification.

## Runtime Owner Added

New owner file:

- [runtime_renderer_no_draw_backend_shell.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj)

The file is package-internal by default and adds no `public` symbols, no module-level `var`, no C ABI, no native handle, no raw pointer, no imports, no backend shell object, no backend object, no platform object and no platform implementation.

## New Internal Symbols

- `CjguiInternalRendererNoDrawBackendShellIntent`
- `CjguiInternalRendererBackendShellLifecyclePolicy`
- `CjguiInternalRendererNoDrawExecutionGate`
- `CjguiInternalRendererShellTeardownPolicy`
- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalBuildRendererNoDrawBackendShellIntent`
- `cjguiInternalBuildRendererBackendShellLifecyclePolicy`
- `cjguiInternalBuildRendererNoDrawExecutionGate`
- `cjguiInternalBuildRendererShellTeardownPolicy`
- `cjguiInternalBuildRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft`

Canonical endpoint:

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`

## Boundary Conclusion

The implementation opens only a no-backend-shell internal value boundary:

- Open path consumes only `CjguiInternalRendererNoMetalDeviceLayerReadiness`.
- Open path forms no-draw backend shell intent / backend shell lifecycle policy / no-draw execution gate / shell teardown policy / no-backend-shell-readiness value facts.
- Defer-only upstream facts remain defer and do not forge backend shell readiness.
- Blocked or inconsistent upstream facts fail closed.
- `NoDrawBackendShellIntent` describes future no-draw backend shell intent only; it is not backend shell object creation and not backend-ready permission.
- `BackendShellLifecyclePolicy` describes future init / active / degraded / teardown facts only; it does not create a backend object and does not manage a real lifecycle.
- `NoDrawExecutionGate` describes no-draw / no-submit / no-render admission facts only; it does not commit command buffers, present drawables, submit GPU work or execute render.
- `ShellTeardownPolicy` describes future teardown ordering / failure rollback / idempotent cleanup facts only; it does not call foreign teardown, modify bridge / smoke / harness or write renderer state.
- `NoBackendShellReadiness` confirms current no backend shell object, no backend object, no platform object, no resource token, no pointer-like resource, no device / layer, no command queue / drawable / command buffer / render pass / encoder / pipeline state, no command buffer commit, no drawable present, no GPU submission, no render execution, no renderer state write, no bridge / smoke / harness / native entry change and no external API surface.

## Same-shape Boundary Brake

Same-shape Boundary Brake is active in code and docs.

This owner is not a `CjguiInternalRendererNoMetalDeviceLayerReadiness` receipt / record / publication thin wrapper. The new facts are:

- no-draw backend shell owner intent facts.
- backend shell lifecycle policy facts.
- no-draw execution gate facts.
- no-submit / no-render admission facts.
- shell teardown / rollback / idempotent cleanup facts.
- no-backend-shell readiness facts.

The owner deliberately does not mix in command queue / drawable real lifecycle, backend implementation, backend shell ready permission, GPU submission, render execution, renderer state write, diagnostics, event bus, observer, telemetry, public API or C ABI.

Source fields and comments explicitly preserve `didAvoidThinWrapper`, `didAvoidBackendShellReadyPermission`, `didAvoidBackendImplementationWrapper`, `didAvoidGpuSubmissionWrapper`, `didAvoidRenderPermissionWrapper` and `didAvoidReceiptRecordPublication`, proving this is not a same-shape tail wrapper.

## Stop-line

This closure confirms the implementation still forbids:

- backend shell object creation.
- backend object creation.
- platform object creation.
- native handle / raw pointer surface.
- `MTLDevice` / `CAMetalLayer` creation or ownership.
- command queue / drawable / command buffer / render pass / encoder / pipeline state creation or ownership.
- FFI / Objective-C / Metal / AppKit API calls.
- bridge / smoke / harness / native entry modification.
- command buffer commit.
- drawable present.
- GPU submission.
- render execution.
- renderer state write.
- backend implementation.
- receipt / record / publication wrappers.
- backend-shell-ready / backend implementation / GPU-submission / render-permission wrappers.
- public API / public C ABI expansion.

## Synchronized Docs

Updated references:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## Validation

Validation results:

- Initial bare `cjpm build --target-dir /tmp/cjgui-renderer-no-draw-backend-shell-value-boundary-target --skip-script` failed because `cjpm` was not in PATH.
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-no-draw-backend-shell-value-boundary-target --skip-script` passed with existing unused warnings and `cjpm build success`.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed; auto-close log assertions passed.
- `git diff --check` passed.
- Markdown absolute link missing target check passed within project docs scope, avoiding `reference_repos/` external mirror noise.
- Closure reachability check passed; README / GUI_TASK_TRACKER / docs plans README / runtime README can find this closure and the next opening.
- Forbidden path check passed; this round's only new runtime source is the allowed no-draw backend shell owner, and it did not touch `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke tracked source, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER; `runtime_state.cj` remains 10065 lines. Existing prior untracked renderer owner/docs remain in the worktree and were not reverted.
- Public declaration scan passed; still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- New owner stop-line source scan passed; the new file has no imports, no `public`, no module-level `var`, no C ABI / native handle / raw pointer patterns, no real backend shell / backend object / platform object implementation patterns, no device / layer platform API call shapes, and no command commit / GPU submission / render execution / renderer state write implementation patterns.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: low risk; affected processes `[]`; this round's new renderer owner is recent/untracked and not indexed yet, so source existence and build are fallback evidence.

## Decision

`CjguiInternalRendererNoBackendShellReadiness` is now the current no-backend-shell value boundary endpoint for no-draw backend shell vocabulary.

Unique next opening:

`P1 internal Renderer no-draw backend shell closure / next no-draw backend decision`

The next round must be docs-only. It should evaluate whether `CjguiInternalRendererNoBackendShellReadiness` is sufficient as the no-backend-shell endpoint and whether to stabilize it with a manifest before any command queue / drawable real lifecycle, real backend shell implementation, platform object implementation, `MTLDevice` / `CAMetalLayer` creation, command buffer commit, GPU submission, render execution or renderer state write preflight.
