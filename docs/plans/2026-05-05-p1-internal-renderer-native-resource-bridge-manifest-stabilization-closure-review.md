# P1 internal Renderer native resource bridge manifest stabilization closure review

日期：2026-05-05

状态：docs-only closure review

## Scope

本轮执行 `P1 internal Renderer native resource bridge manifest stabilization bundle implementation`。

本轮必须 docs-only：没有修改 `.cj`，没有运行 `cjpm build` / smoke，没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮没有创建 backend shell object、backend object、platform object、native handle 或 raw pointer；没有新增 C ABI、FFI declaration 或 bridge call；没有调用 retain / release / destroy；没有创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；没有调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；没有提交 GPU work，没有执行 render，没有写 renderer state，没有扩 public API。

## Files Updated

New docs:

- [2026-05-05-p1-renderer-native-resource-bridge-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-native-resource-bridge-manifest-stabilization-closure-review.md)

Synchronized docs:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-preflight-decision.md)
- [2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-next-boundary-decision.md)
- [2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)

## Manifest Conclusion

The native resource bridge owner is fixed:

- Owner file: [runtime_renderer_native_resource_bridge.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_resource_bridge.cj)
- Runtime input: `CjguiInternalRendererNoResourceBackendShellReadiness`
- Canonical endpoint: `CjguiInternalRendererNoNativeResourceBridgeReadiness`
- Default draft: `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`

Current truth is exactly:

- native resource bridge intent value facts.
- handle confinement policy value facts.
- bridge call admission guard value facts.
- native teardown contract policy value facts.
- no-native-resource-bridge readiness value facts.

`NativeHandleConfinementPolicy` does not create, save or expose native handle / raw pointer.

`BridgeCallAdmissionGuard` does not call bridge and does not add FFI declaration.

`NativeTeardownContractPolicy` does not execute retain / release / destroy.

`NoNativeResourceBridgeReadiness` is not native bridge implementation permission, native handle permission, C ABI permission, FFI permission, platform object permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

## Boundary Conclusion

The current endpoint has no backend shell object, no backend object, no platform object, no native handle, no raw pointer, no pointer-like resource, no foreign resource token, no C ABI, no FFI declaration, no bridge call, no retain / release / destroy call, no Metal / AppKit / Objective-C call, no GPU work, no render execution, no renderer state mutation and no external API surface.

The manifest keeps `CjguiInternalRendererNoResourceBackendShellReadiness` as the only runtime input. Backend platform object owner, Metal device-layer owner, backend / Metal reference pack, risk ledger and smoke evidence remain docs evidence only and are not runtime inputs.

## Same-shape Boundary Brake

This round is a manifest closure, not another wrapper.

It explicitly rejects:

- native bridge receipt / record / publication.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- platform-object permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API wrapper.

`CjguiInternalRendererNoNativeResourceBridgeReadiness` is not to be wrapped into a new tail endpoint. It only represents native resource bridge intent / handle confinement policy / bridge call admission guard / native teardown contract policy / no-native-resource-bridge readiness value facts.

Future work approaching platform object implementation, native handle token, native teardown contract, Metal device-layer implementation or real bridge / FFI must first pass docs-only preflight.

## Next Stage Candidate Comparison

### A. P1 internal Renderer platform object implementation preflight decision

推荐。

Native resource bridge is now closed as value-only no-native-resource-bridge truth. The next safe question is docs-only: whether platform object create / retain / release / teardown / failure / confinement evidence is enough to approach an implementation preflight.

### B. Native handle token preflight

暂缓。

Handle token identity / nullability / ownership should wait until platform object implementation preflight proves a narrower need.

### C. Native teardown contract hardening

暂缓，仅在 teardown contract / failure rollback expression proves insufficient.

### D. Metal device-layer implementation preflight

暂缓。

Device / layer implementation remains downstream of platform object implementation risk.

### E. Real backend shell implementation preflight

暂缓。

Real backend shell implementation still needs native bridge and platform object implementation risks to be evaluated first.

### F. Direct native bridge implementation

拒绝。

### G. Direct native handle / raw pointer implementation

拒绝。

### H. Direct C ABI / FFI declaration

拒绝。

### I. Direct retain / release / destroy implementation

拒绝。

### J. Direct Metal / AppKit / Objective-C implementation

拒绝。

### K. GPU submission / render execution

拒绝。

### L. Renderer state write

拒绝。

### M. Public API / C ABI expansion

拒绝。

### N. Receipt / record / publication

拒绝。

### O. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

## Validation

Completed:

- `git diff --check` passed.
- New manifest / closure no-index whitespace check passed with no whitespace diagnostics. `git diff --no-index` returned the expected new-file diff status.
- Markdown absolute link missing target check passed for 629 project markdown files, excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability found the manifest, closure, `CjguiInternalRendererNoNativeResourceBridgeReadiness`, `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()` and the unique next opening.
- Forbidden check found no tracked `.cj` diff and no protected path status for `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER.
- `runtime_state.cj` line count remains `10065`.
- Public declaration scan still finds only `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` reported risk `low`, `changed_count=13`, `changed_files=7`, `affected_count=0` and no affected processes.

Build and smoke were intentionally not run in this docs-only round.

## Unique Next Opening

`P1 internal Renderer platform object implementation preflight decision`
