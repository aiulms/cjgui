# P1 internal Renderer Metal device-layer owner manifest stabilization closure review

日期：2026-05-04

状态：closure review

## Scope

本轮执行 `P1 internal Renderer Metal device-layer owner manifest stabilization bundle implementation`。

本轮必须 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 `MTLDevice` / `CAMetalLayer`，不接 Objective-C / Metal / AppKit / FFI，不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state，不 commit / present / submit GPU work，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_metal_device_layer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer.cj)
- [2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md)
- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

## Manifest Added

新增 manifest：

- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

该 manifest 固定：

- owner file：`runtime/cjgui/src/runtime_renderer_metal_device_layer.cj`
- canonical endpoint：`CjguiInternalRendererNoMetalDeviceLayerReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`
- current truth：Metal device-layer owner intent / device selection policy / layer binding policy / scale-color-space policy / no-metal-device-layer-readiness value facts

## Manifest Conclusion

`CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()` 已封账为当前 no-metal-device-layer endpoint。

Current truth 仍然只限 internal value facts：

- Metal device-layer owner intent。
- Device selection policy。
- Layer binding policy。
- Scale-color-space policy。
- No-metal-device-layer readiness。

This is not a real Metal / AppKit / backend implementation runway. It is a stabilized endpoint for future docs-only no-draw backend shell preflight.

## Boundary Conclusion

The manifest explicitly fixes these boundaries:

- `MetalDeviceSelectionPolicy` 不创建 `MTLDevice`，不查询真实 device，不调用 Metal API，不授予 device-ready permission。
- `MetalLayerBindingPolicy` 不创建、绑定、持有或配置 `CAMetalLayer`，不 acquire drawable，不授予 layer-ready permission。
- `MetalScaleColorSpacePolicy` 不读取真实 display scale / color space，不读取 `NSView` / `NSWindow` / `NSScreen` / platform layer，只表达 dehydrated policy facts。
- `NoMetalDeviceLayerReadiness` 不是 `MTLDevice` permission、`CAMetalLayer` permission、platform object permission、native handle permission、backend implementation permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。
- Current state has no `MTLDevice`, no `CAMetalLayer`, no platform object, no native handle, no raw pointer, no command queue, no drawable, no command buffer, no render pass, no encoder, no pipeline state, no command buffer commit, no drawable present, no GPU submission, no render execution, no renderer state write, no bridge / smoke / harness / native entry change and no public API / C ABI expansion.

## Same-shape Boundary Brake

Same-shape Boundary Brake is active in this manifest.

This round explicitly rejects:

- Metal device-layer receipt / record / publication。
- native-handle readiness wrapper。
- device-ready permission wrapper。
- layer-ready permission wrapper。
- backend implementation wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- public API / C ABI wrapper。

`CjguiInternalRendererNoMetalDeviceLayerReadiness` is not a tail wrapper over `CjguiInternalRendererNoPlatformObjectReadiness`. The preserved semantics are device selection, layer binding, scale-color-space policy and no-metal-device-layer readiness.

Future no-draw backend shell, command queue / drawable real lifecycle, real Metal object, Objective-C / Metal / AppKit / FFI bridge, command buffer commit, GPU submission, render execution or renderer state write work must first pass docs-only preflight.

## Next-stage Candidate Summary

### A. P1 internal Renderer no-draw backend shell preflight decision

Recommended.

It is the narrowest next docs-only question after the device-layer endpoint is manifest-stabilized. It should evaluate backend shell lifecycle, no-device / no-layer fallback, teardown / failure path and smoke strategy without creating backend or Metal objects.

### B. Command queue / drawable real lifecycle preflight

Deferred.

It should wait until no-draw backend shell owner questions are clearer, or at least until this device-layer manifest is the stable input evidence.

### C. Metal device-layer hardening

Deferred unless evidence shows device selection / layer binding / scale-color-space expression is insufficient.

### D. Direct `MTLDevice` / `CAMetalLayer` implementation

Rejected.

### E. Direct Objective-C / Metal / AppKit bridge modification

Rejected.

### F. Command buffer commit / GPU submission / render execution

Rejected.

### G. Renderer state write

Rejected.

### H. Public API / C ABI expansion

Rejected.

### I. Receipt / record / publication

Rejected.

### J. Consolidation

Deferred unless explicit duplicate / self-wrapping evidence appears.

## Synchronized Docs

Updated references:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-next-boundary-decision.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## Validation

Validation results:

- `git diff --check` passed.
- Markdown absolute link missing target check passed within project docs scope, avoiding `reference_repos/` external mirror noise; 597 Markdown files checked.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability passed for the new manifest, this closure and the next opening.
- Forbidden path check passed: no tracked `.cj` diff, protected path status empty, and `runtime_state.cj` remains 10065 lines.
- Public declaration scan passed; still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` reported low risk, affected count `0`, affected processes `[]`.
- This docs-only manifest round did not run `cjpm build` or smoke, by requirement.

## Decision

This manifest stabilization closes the renderer Metal device-layer owner no-metal-device-layer endpoint.

Unique next opening:

`P1 internal Renderer no-draw backend shell preflight decision`

The next round must remain docs-only and must not implement backend / Metal / AppKit / FFI, create platform objects, create `MTLDevice` / `CAMetalLayer`, create command queue / drawable / command buffer / render pass / encoder / pipeline state, commit / present / submit GPU work, write renderer state or expand public API / C ABI.
