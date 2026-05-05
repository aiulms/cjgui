# P1 internal Renderer native resource bridge value boundary closure review

日期：2026-05-05

状态：implementation closure

## Scope

本轮新增 internal-only runtime owner，用于封装 native resource bridge 前的 value boundary。它只建立 native bridge intent、handle confinement、bridge call admission、native teardown contract 与 no-native-resource-bridge readiness facts。

本轮允许新增：

- [runtime_renderer_native_resource_bridge.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj)

本轮未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮没有创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；没有新增 C ABI 或 FFI declaration；没有调用 bridge、retain / release / destroy、`commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；没有提交 GPU work、执行 render、写 renderer state、扩 public API 或新增 module-level `var`。

## Inputs Read

- [runtime_renderer_backend_shell_skeleton.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj)
- [Native resource bridge preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md)
- [Backend shell skeleton manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## GitNexus Impact

Pre-change GitNexus impact was run before editing:

- `CjguiInternalRendererNoResourceBackendShellReadiness`: `UNKNOWN / not found`, impacted count `0`.
- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft`: `UNKNOWN / not found`, impacted count `0`.

No HIGH / CRITICAL impact was reported. Both symbols are recent owner additions that are not yet indexed, so this closure records them as not indexed and relies on source existence, build, smoke, stop-line scans and `detect_changes(scope=unstaged)` as the safety fallback.

## Runtime Owner Added

Owner file:

- [runtime_renderer_native_resource_bridge.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj)

Runtime input:

- `CjguiInternalRendererNoResourceBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`

Canonical endpoint:

- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`

New internal symbols:

- `CjguiInternalRendererNativeResourceBridgeIntent`
- `CjguiInternalRendererNativeHandleConfinementPolicy`
- `CjguiInternalRendererBridgeCallAdmissionGuard`
- `CjguiInternalRendererNativeTeardownContractPolicy`
- `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- `cjguiInternalBuildRendererNativeResourceBridgeIntent`
- `cjguiInternalBuildRendererNativeHandleConfinementPolicy`
- `cjguiInternalBuildRendererBridgeCallAdmissionGuard`
- `cjguiInternalBuildRendererNativeTeardownContractPolicy`
- `cjguiInternalBuildRendererNoNativeResourceBridgeReadiness`
- `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`

## Boundary Conclusion

`CjguiInternalRendererNativeResourceBridgeIntent` only records future native resource bridge intent value facts. It is not bridge implementation permission, backend implementation permission, platform object permission, native handle permission, GPU submission permission, render permission or public API permission.

`CjguiInternalRendererNativeHandleConfinementPolicy` only records handle confinement value facts. It does not create, save, expose or retain a native handle, raw pointer, pointer-like resource, platform object or backend object.

`CjguiInternalRendererBridgeCallAdmissionGuard` only records future bridge call admission value facts. It does not call bridge code, define a C ABI, define an FFI declaration, call Metal / AppKit / Objective-C / FFI or modify bridge / smoke / harness / native entry.

`CjguiInternalRendererNativeTeardownContractPolicy` only records teardown ordering, failure rollback and no-resource-finalization value facts. It does not execute retain / release / destroy, resource finalization, callback registration, telemetry output, bridge side effect or renderer state mutation.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` is the current no-native-resource-bridge endpoint. It is not native bridge permission, native handle permission, raw pointer permission, platform object permission, Metal device permission, backend implementation permission, GPU submission permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

Open path produces value facts only. Deferred path stays deferred. Blocked and inconsistent input paths fail closed and preserve the no-resource / no-bridge / no-state-write stop-line.

## Same-shape Boundary Brake

This implementation adds handle confinement / bridge call admission / teardown contract / no-native-resource-bridge semantics.

It does not wrap:

- `CjguiInternalRendererNoResourceBackendShellReadiness`
- `CjguiInternalRendererNoPlatformObjectReadiness`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- backend / Metal reference pack evidence
- `labs/macos_bridge_smoke` evidence

Rejected wrapper shapes:

- native bridge receipt / record / publication.
- native-handle permission wrapper.
- raw-pointer permission wrapper.
- platform-object permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API / C ABI wrapper.

The new endpoint deliberately seals no-native-resource-bridge readiness facts rather than claiming native bridge readiness or backend implementation readiness.

## Validation

- GitNexus impact: both requested symbols returned `UNKNOWN / not found`; no HIGH / CRITICAL impact.
- `cjpm build --target-dir /tmp/cjgui-renderer-native-resource-bridge-value-boundary-target --skip-script`: bare `cjpm` was not in PATH, then toolchain env retry passed with existing unused warnings and `cjpm build success`.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed; auto-close log assertions passed, and the script explicitly reported it is not user-visible window verification.
- `git diff --check`: passed.
- New file no-index whitespace checks: no whitespace diagnostics for the runtime owner or this closure file.
- Markdown absolute link missing target check: checked project docs / README scopes, excluding `reference_repos/`; missing targets `0`.
- Reachability: README, GUI task tracker, docs/plans README and runtime README all find the closure and next opening.
- Forbidden path check: protected paths remained untouched and `runtime_state.cj` stayed at `10065` lines.
- Public declaration scan: still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- New owner stop-line scan: no real Metal / AppKit / FFI call terms, native-handle / raw-pointer phrases, C ABI phrase, bridge-call phrase, retain / release / destroy tokens, `commit` / `present` / `nextDrawable`, `public`, or module-level `var` were found in the new source.
- GitNexus `detect_changes(scope=unstaged)`: risk `low`, affected processes `[]`; changed files are docs / README sections according to the current index, while the new recent owner remains outside indexed symbol resolution.

## Next Opening

唯一 next opening：

`P1 internal Renderer native resource bridge closure / next native resource bridge decision`
