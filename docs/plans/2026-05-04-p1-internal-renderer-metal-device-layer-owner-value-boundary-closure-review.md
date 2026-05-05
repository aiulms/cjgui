# P1 internal Renderer Metal device-layer owner value boundary closure review

日期：2026-05-04

状态：closure review

## Scope

本轮执行 `P1 internal Renderer Metal device-layer owner value boundary bundle implementation`。

允许新增一个 internal-only runtime owner file，但必须严格保持 no-device / no-layer / no-platform-resource / no-render 边界。本轮不创建或引用真实 `MTLDevice`、`CAMetalLayer`、platform object、native handle、raw pointer、command queue、drawable、command buffer、render pass、encoder 或 pipeline state；不调用 FFI / Objective-C / Metal / AppKit API；不修改 bridge、smoke、harness 或 native entry；不提交 / present / submit GPU work；不执行 render；不写 renderer state；不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Inputs Read

- [runtime_renderer_backend_platform_object.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object.cj)
- [2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- Adjacent renderer owner naming / fail-closed patterns in backend platform object, backend readiness and state-write no-write owners.

## GitNexus Impact

GitNexus impact was run before editing the downstream owner:

- `CjguiInternalRendererNoPlatformObjectReadiness`: `UNKNOWN` / target not found, affected count `0`.
- `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft`: `UNKNOWN` / target not found, affected count `0`.

Interpretation：these are recent renderer owner symbols present in source but not indexed yet. No HIGH / CRITICAL risk was returned, so implementation proceeded with source existence plus `cjpm build` fallback verification.

## Runtime Owner Added

New owner file:

- [runtime_renderer_metal_device_layer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj)

The file is package-internal by default and adds no `public` symbols, no module-level `var`, no C ABI, no native handle, no raw pointer, no imports, no real device, no real layer, no platform object and no platform implementation.

## New Internal Symbols

- `CjguiInternalRendererMetalDeviceLayerOwnerIntent`
- `CjguiInternalRendererMetalDeviceSelectionPolicy`
- `CjguiInternalRendererMetalLayerBindingPolicy`
- `CjguiInternalRendererMetalScaleColorSpacePolicy`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalBuildRendererMetalDeviceLayerOwnerIntent`
- `cjguiInternalBuildRendererMetalDeviceSelectionPolicy`
- `cjguiInternalBuildRendererMetalLayerBindingPolicy`
- `cjguiInternalBuildRendererMetalScaleColorSpacePolicy`
- `cjguiInternalBuildRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft`

Canonical endpoint:

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`

## Boundary Conclusion

The implementation opens only a no-metal-device-layer internal value boundary:

- Open path consumes only `CjguiInternalRendererNoPlatformObjectReadiness`.
- Open path forms Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts.
- Defer-only upstream facts remain defer and do not forge device-layer readiness.
- Blocked or inconsistent upstream facts fail closed.
- `MetalDeviceLayerOwnerIntent` describes future device-layer owner intent only; it is not device creation and not layer creation permission.
- `MetalDeviceSelectionPolicy` describes future device choice / capability fallback / no-device fallback facts only; it does not query or create a device and does not grant queue creation permission.
- `MetalLayerBindingPolicy` describes future layer-hosting / drawable-pool boundary / no-layer fallback facts only; it does not create a layer, acquire a drawable or configure platform state.
- `MetalScaleColorSpacePolicy` describes dehydrated drawable-size / backing-scale / pixel-format / color-space facts only; it does not read platform view state and does not configure layer state.
- `NoMetalDeviceLayerReadiness` confirms current no device, no layer, no platform resource materialization, no foreign resource token, no pointer-like resource, no command queue / drawable / command buffer / render pass / encoder / pipeline state, no command buffer commit, no GPU submission, no render execution, no renderer state write, no bridge / smoke / harness / native entry change and no external API surface.

## Same-shape Boundary Brake

Same-shape Boundary Brake is active in code and docs.

This owner is not a `CjguiInternalRendererNoPlatformObjectReadiness` receipt / record / publication thin wrapper. The new facts are:

- Metal device-layer owner intent facts.
- device selection / device choice / no-device fallback facts.
- layer binding / layer-hosting / no-layer fallback facts.
- drawable pool boundary facts without drawable acquisition.
- scale / color-space dehydrated facts.
- no-metal-device-layer readiness facts.

The owner deliberately does not mix in no-draw backend shell truth, command queue / drawable real lifecycle, command buffer commit, GPU submission, render execution, renderer state write, backend implementation, device-ready permission, layer-ready permission, public API, diagnostics, event bus, observer or telemetry.

Source fields and comments explicitly preserve `didAvoidThinWrapper`, `didAvoidDeviceReadyPermission`, `didAvoidLayerReadyPermission`, `didAvoidForeignResourceReadinessWrapper`, `didAvoidBackendImplementationWrapper`, `didAvoidGpuSubmissionWrapper` and `didAvoidReceiptRecordPublication`, proving this is not a same-shape tail wrapper.

## Stop-line

This closure confirms the implementation still forbids:

- `MTLDevice` creation or ownership.
- `CAMetalLayer` creation or ownership.
- platform object creation.
- native handle / raw pointer surface.
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
- device-ready / layer-ready permission wrappers.
- public API / public C ABI expansion.

## Synchronized Docs

Updated references:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## Validation

Validation results:

- Initial bare `cjpm build --target-dir /tmp/cjgui-renderer-metal-device-layer-owner-value-boundary-target --skip-script` failed because `cjpm` was not in PATH.
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-metal-device-layer-owner-value-boundary-target --skip-script` passed with existing unused warnings and `cjpm build success`.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed; auto-close log assertions passed.
- `git diff --check` passed.
- Markdown absolute link missing target check passed within project docs scope, avoiding `reference_repos/` external mirror noise.
- Closure reachability check passed; README / GUI_TASK_TRACKER / docs plans README / runtime README can find this closure and the next opening.
- Forbidden path check passed; only the allowed new `.cj` owner file is changed, and did not touch `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke tracked source, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER; `runtime_state.cj` remains 10065 lines.
- Public declaration scan passed; still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- New owner stop-line source scan passed; the new file has no imports, no `public`, no module-level `var`, no C ABI / native handle / raw pointer patterns, no real device / layer platform API call shapes, and no command commit / GPU submission / render execution / renderer state write implementation patterns.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: low risk; affected processes `[]`; this round's new renderer owner is recent/untracked and not indexed yet, so source existence and build are fallback evidence.

## Decision

`CjguiInternalRendererNoMetalDeviceLayerReadiness` is now the current no-metal-device-layer value boundary endpoint for Metal device-layer owner vocabulary.

Unique next opening:

`P1 internal Renderer Metal device-layer owner closure / next device-layer decision`

The next round must be docs-only. It should evaluate whether `CjguiInternalRendererNoMetalDeviceLayerReadiness` is sufficient as the no-metal-device-layer endpoint and whether to stabilize it with a manifest before any no-draw backend shell, command queue / drawable real lifecycle, platform object implementation, `MTLDevice` / `CAMetalLayer` creation, command buffer commit, GPU submission, render execution or renderer state write preflight.
