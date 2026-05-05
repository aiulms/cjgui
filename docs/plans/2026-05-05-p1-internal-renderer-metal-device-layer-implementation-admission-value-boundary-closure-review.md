# P1 internal Renderer Metal device-layer implementation admission value boundary closure review

日期：2026-05-05

状态：implementation closure

## Scope

本轮新增 internal-only runtime owner，用于封住真实 Metal device-layer implementation 之前的 admission value boundary。它只建立 Metal device-layer implementation intent、device creation admission policy、layer binding admission guard、scale-color-space admission policy 与 no-metal-device-layer-implementation readiness facts。

本轮允许新增：

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)

本轮未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮没有创建 backend shell object、backend object、platform object、native handle 或 raw pointer；没有新增 C ABI 或 FFI declaration；没有调用 bridge、retain / release / destroy、`commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；没有创建 `MTLDevice`、绑定 `CAMetalLayer`、创建 `MTLCommandQueue`、drawable 或 command buffer；没有提交 GPU work、执行 render、写 renderer state、扩 public API 或新增 module-level `var`。

## Inputs Read

- [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)
- [Metal device-layer implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-preflight-decision.md)
- [Platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## GitNexus Impact

Pre-change GitNexus impact was run before editing:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`: `UNKNOWN / not found`, impacted count `0`.
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft`: `UNKNOWN / not found`, impacted count `0`.

No HIGH / CRITICAL impact was reported. Both symbols are recent owner additions that are not yet indexed, so this closure records them as not indexed and relies on source existence, build, smoke, stop-line scans and `detect_changes(scope=unstaged)` as the safety fallback.

## Runtime Owner Added

Owner file:

- [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj)

Runtime input:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

Canonical endpoint:

- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

New internal symbols:

- `CjguiInternalRendererMetalDeviceLayerImplementationIntent`
- `CjguiInternalRendererMetalDeviceCreationAdmissionPolicy`
- `CjguiInternalRendererMetalLayerBindingAdmissionGuard`
- `CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy`
- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalBuildRendererMetalDeviceLayerImplementationIntent`
- `cjguiInternalBuildRendererMetalDeviceCreationAdmissionPolicy`
- `cjguiInternalBuildRendererMetalLayerBindingAdmissionGuard`
- `cjguiInternalBuildRendererMetalScaleColorSpaceAdmissionPolicy`
- `cjguiInternalBuildRendererNoMetalDeviceLayerImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft()`

## Boundary Conclusion

`CjguiInternalRendererMetalDeviceLayerImplementationIntent` only records future Metal device-layer implementation intent value facts. It is not device-ready permission, layer-ready permission, platform-object permission, native-handle permission, backend implementation permission, GPU submission permission, render permission or public API permission.

`CjguiInternalRendererMetalDeviceCreationAdmissionPolicy` only records future device creation admission facts. It does not create `MTLDevice`, query a real device, create command queue, hold native handle or call Metal / AppKit / Objective-C / FFI.

`CjguiInternalRendererMetalLayerBindingAdmissionGuard` only records future layer binding admission facts. It does not create, bind, configure or hold `CAMetalLayer`; it does not acquire drawable, create platform object, call bridge code or grant backend implementation permission.

`CjguiInternalRendererMetalScaleColorSpaceAdmissionPolicy` only records dehydrated drawable size / backing scale / pixel format / color-space admission facts. It does not query real screen, real layer or real color space, and it does not mutate renderer state.

`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` is the current no-metal-device-layer-implementation endpoint. It is not `MTLDevice` permission, `CAMetalLayer` permission, platform object permission, native handle permission, C ABI permission, FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

Open path produces value facts only. Deferred path stays deferred. Blocked and inconsistent input paths fail closed and preserve the no-device / no-layer / no-platform-object / no-native-handle / no-bridge / no-state-write stop-line.

## Same-shape Boundary Brake

This implementation adds device creation admission / layer binding admission / scale-color-space admission / no-metal-device-layer-implementation semantics.

It does not wrap:

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- platform object implementation admission manifest evidence
- native resource bridge manifest evidence
- Metal device-layer owner manifest evidence
- `labs/macos_bridge_smoke` evidence

Rejected wrapper shapes:

- Metal device-layer implementation receipt / record / publication.
- device-ready permission wrapper.
- layer-ready permission wrapper.
- native-handle permission wrapper.
- C-ABI / FFI permission wrapper.
- platform-object wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API wrapper.

The new endpoint deliberately seals no-metal-device-layer-implementation readiness facts rather than claiming device readiness, layer readiness, backend implementation readiness or bridge readiness.

## Validation

- GitNexus impact: both requested symbols returned `UNKNOWN / not found`; no HIGH / CRITICAL impact.
- Bare `cjpm build --target-dir /tmp/cjgui-renderer-metal-device-layer-admission-value-boundary-target --skip-script`: `cjpm` was not in PATH.
- `PATH=/Users/jiangxuanyang/cangjie-toolchains/cangjie/bin:/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin:$PATH CANGJIE_HOME=/Users/jiangxuanyang/cangjie-toolchains/cangjie cjpm build --target-dir /tmp/cjgui-renderer-metal-device-layer-admission-value-boundary-target --skip-script`: passed with existing unused warnings and `cjpm build success`.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed; auto-close log assertions passed, and the script explicitly reported it is not user-visible window verification.
- `git diff --check`: passed.
- New file no-index whitespace checks: passed for [runtime_renderer_metal_device_layer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_admission.cj) and this closure file.
- Markdown absolute link missing target check: checked project docs / README scopes, excluding `reference_repos/`; missing targets `0`.
- Reachability: README, GUI task tracker, docs/plans README and runtime README all find the closure and next opening.
- Forbidden path check: protected paths remained untouched, no tracked `.cj` diff was present, and `runtime_state.cj` stayed at `10065` lines.
- Public declaration scan: precise source scan still finds only `public func cjguiExperimentalQueueSubmitShellReady(): Bool`; a broad text scan also matched a prohibitive comment in `platform_adapter.cj`.
- New owner stop-line scan: strict source scan found no real Metal / AppKit / FFI calls, public declarations, module-level `var`, native pointer types, C ABI / FFI declarations, bridge calls, retain / release / destroy calls, `commit` / `present` / `nextDrawable` calls or `runtime_state` references.
- GitNexus `detect_changes(scope=unstaged)`: risk `low`, affected processes `[]`, changed count `10`, affected count `0`, changed files `8`; recent new owner/docs remain partly outside indexed symbol resolution.

## Next Opening

唯一 next opening：

`P1 internal Renderer Metal device-layer implementation admission closure / next Metal device-layer implementation decision`
