# P1 internal Renderer Metal device-layer implementation admission manifest stabilization closure review

日期：2026-05-05

状态：docs-only manifest stabilization closure

## Scope

本轮完成 Metal device-layer implementation admission manifest 封账，固定 `runtime_renderer_metal_device_layer_admission.cj` 的 owner / truth / canonical endpoint / stop-line，并把 renderer backend branch 的下一步推进到 real command queue implementation preflight。

本轮 docs-only：未修改 `.cj`，未运行 `cjpm build` / smoke，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮没有创建 backend shell object、backend object、platform object、native handle 或 raw pointer；没有新增 C ABI 或 FFI declaration；没有调用 bridge、retain / release / destroy、`commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；没有创建 `MTLDevice`、绑定 `CAMetalLayer`、创建 `MTLCommandQueue`、drawable 或 command buffer；没有提交 GPU work、执行 render、写 renderer state 或扩 public API。

## Inputs Read

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)
- [Metal device-layer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md)
- [Metal device-layer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-metal-device-layer-implementation-admission-value-boundary-closure-review.md)
- [Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)

## Docs Updated

- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [Metal device-layer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-next-boundary-decision.md)
- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## Manifest Result

Owner file：

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)

Runtime input：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

Current truth：

- Metal device-layer implementation intent value facts.
- device creation admission policy value facts.
- layer binding admission guard value facts.
- scale-color-space admission policy value facts.
- no-metal-device-layer-implementation readiness value facts.

## Boundary Conclusion

`CjguiInternalRendererMetalDeviceLayerImplementationIntent` only records future Metal device-layer implementation intent value facts. It is not device-ready permission, layer-ready permission, native-handle permission, C ABI / FFI permission, backend implementation permission, GPU submission permission, render permission or public API permission.

`CjguiInternalRendererMetalDeviceCreationAdmissionPolicy` only records future device creation admission facts. It does not create `MTLDevice`, query a real device, create command queue, hold native handle, expose raw pointer or call Metal / AppKit / Objective-C / FFI.

`CjguiInternalRendererMetalLayerBindingAdmissionGuard` only records future layer binding admission facts. It does not create, bind, configure or hold `CAMetalLayer`; it does not acquire drawable, create platform object, call bridge code or grant backend implementation permission.

`CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy` only records dehydrated drawable size / backing scale / pixel format / color-space admission facts. It does not query real screen, real layer or real color space, and it does not mutate renderer state.

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` is the sealed no-metal-device-layer-implementation endpoint. It is not `MTLDevice` permission, `CAMetalLayer` permission, native handle permission, raw pointer permission, C ABI permission, FFI permission, bridge call permission, platform object permission, GPU submission permission, render permission, renderer state write permission, diagnostics permission or public API permission.

## Same-shape Boundary Brake

This manifest stabilization closes the endpoint rather than wrapping it.

Rejected wrapper shapes:

- device-ready permission wrapper.
- layer-ready permission wrapper.
- native-handle permission wrapper.
- C-ABI / FFI permission wrapper.
- platform-object wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.
- public API wrapper.

Future work near real command queue implementation, real backend shell implementation, native handle token, real `MTLDevice` / `CAMetalLayer`, GPU submission or renderer state write must first pass docs-only preflight.

## Candidate Conclusion

下一阶段推荐 A：`P1 internal Renderer real command queue implementation preflight decision`。

B real backend shell implementation preflight、C native handle token preflight、D Metal device creation admission hardening、E Metal layer binding admission hardening、F scale / color-space / resize admission hardening 均暂缓。G direct `MTLDevice` creation implementation、H direct `CAMetalLayer` creation / binding implementation、I direct native handle / raw pointer implementation、J direct C ABI / FFI declaration、K direct Metal / AppKit / Objective-C implementation、L GPU submission / render execution、M renderer state write、N public API / C ABI expansion、O receipt / record / publication 均拒绝。P consolidation 仅在明确 duplicate / low-value / self-wrapping evidence 出现时选择。

## Validation

- `git diff --check`: passed.
- New manifest / closure no-index whitespace check: passed.
- Markdown absolute link missing target check: scoped to project docs / README scopes, excluding `reference_repos/`; checked `639` markdown files, missing targets `0`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability: passed for the new manifest, closure and `P1 internal Renderer real command queue implementation preflight decision`.
- Forbidden path check: passed; no tracked `.cj` diff, no protected path diff / status, and `runtime_state.cj` remained `10065` lines.
- Public declaration scan: still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`, affected processes `[]`, changed count `10`, affected count `0`, changed files `8`.

Build and smoke were not run because this is a docs-only round.

## Next Opening

唯一 next opening：

`P1 internal Renderer real command queue implementation preflight decision`
