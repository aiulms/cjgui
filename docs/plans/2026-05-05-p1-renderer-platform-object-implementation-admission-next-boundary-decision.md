# P1 Renderer platform object implementation admission next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` 是否已经足够作为当前 no-platform-object-implementation endpoint，并决定下一步是否进入 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle 或 raw pointer；不新增 C ABI，不新增 FFI declaration，不调用 bridge，不调用 retain / release / destroy；不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## Inputs Read

- [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj)
- [Platform object implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-value-boundary-closure-review.md)
- [Platform object implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-preflight-decision.md)
- [Native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## Decision

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` is sufficient as the current no-platform-object-implementation endpoint.

选择 A：`P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation`。

唯一 next opening：

`P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation`

## Endpoint Conclusion

Current endpoint truth is exactly:

- platform object implementation intent value facts.
- native handle admission policy value facts.
- platform object lifecycle admission guard value facts.
- teardown failure policy value facts.
- no-platform-object-implementation readiness value facts.

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` is not platform object implementation permission, native handle permission, C ABI permission, FFI permission, Metal / AppKit bridge permission, GPU submission permission, render permission, renderer state write permission or public API permission.

The default draft consumes only `CjguiInternalRendererNoNativeResourceBridgeReadiness` via `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`. Native resource bridge, backend platform object owner and smoke evidence remain evidence only where they are not the runtime input.

## Boundary Facts

`CjguiInternalRendererPlatformObjectImplementationIntent` only records future platform object implementation intent facts. It does not create a backend shell object, backend object, platform object, Metal / AppKit object, bridge surface or implementation permission.

`CjguiInternalRendererNativeHandleAdmissionPolicy` only records native handle admission facts. It does not create, save, expose or retain native handle, raw pointer, pointer-like resource or foreign resource token.

`CjguiInternalRendererPlatformObjectLifecycleAdmissionGuard` only records lifecycle admission facts. It does not create platform object, call bridge code, add FFI declaration, call Metal / AppKit / Objective-C / FFI or modify bridge / smoke / harness / native entry.

`CjguiInternalRendererPlatformObjectTeardownFailurePolicy` only records teardown ordering and failure rollback facts. It does not execute retain / release / destroy, resource finalization, rollback callback, completion callback, telemetry output or renderer state mutation.

## Candidate Comparison

### A. P1 internal Renderer platform object implementation admission manifest stabilization bundle implementation

推荐。

The current endpoint is complete enough to freeze owner / truth / canonical endpoint / stop-line. Manifest stabilization should document `runtime_renderer_platform_object_admission.cj`, `CjguiInternalRendererNoPlatformObjectImplementationReadiness`, `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()` and the no-platform-object-implementation truth without adding code.

### B. Native handle token preflight

暂缓。

Handle identity, nullability and ownership-token questions should wait until the admission manifest is sealed. Current native handle admission facts are enough for this endpoint.

### C. Native teardown contract hardening

暂缓。

Choose only if the manifest review finds teardown ordering or failure rollback facts insufficient. Current teardown failure policy is enough for endpoint closure.

### D. Metal device-layer implementation preflight

暂缓。

Device / layer implementation remains downstream of platform object admission stabilization. Current endpoint does not grant `MTLDevice` or `CAMetalLayer` permission.

### E. Real backend shell implementation preflight

暂缓。

Real backend shell implementation should wait until platform object admission facts are manifest-stabilized and still requires separate preflight.

### F. Real platform object creation preflight

暂缓。

Real platform object creation remains too early until admission stop-lines and native bridge constraints are frozen.

### G. Direct platform object implementation

拒绝。

### H. Direct native handle / raw pointer implementation

拒绝。

### I. Direct C ABI / FFI declaration

拒绝。

### J. Direct retain / release / destroy implementation

拒绝。

### K. Direct Metal / AppKit / Objective-C implementation

拒绝。

### L. GPU submission / render execution

拒绝。

### M. Renderer state write

拒绝。

### N. Public API / C ABI expansion

拒绝。

### O. Receipt / record / publication

拒绝。

### P. Consolidation

仅在明确 duplicate / self-wrapping evidence 出现时选择。Current evidence shows a real endpoint that should be manifest-stabilized, not collapsed.

## Same-shape Boundary Brake

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` must not be wrapped into another tail wrapper.

This decision explicitly rejects:

- platform-object permission wrapper.
- native-handle permission wrapper.
- C-ABI permission wrapper.
- FFI permission wrapper.
- Metal-device permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.
- public API wrapper.

Future work near native handle token, native teardown contract, Metal device-layer implementation, real backend shell implementation, real platform object creation, GPU submission, render execution or renderer state write must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight opens a narrower runway:

- no `.cj` modifications in this decision round.
- no backend shell object.
- no backend object.
- no platform object.
- no native handle.
- no raw pointer.
- no C ABI.
- no FFI declaration.
- no bridge call.
- no retain / release / destroy.
- no `MTLDevice`.
- no `CAMetalLayer`.
- no `MTLCommandQueue`.
- no drawable.
- no command buffer.
- no `commit`.
- no `present`.
- no `nextDrawable`.
- no Metal / AppKit / Objective-C / FFI call.
- no GPU submission.
- no render execution.
- no renderer state write.
- no public API expansion.
- no receipt / record / publication.

## Validation Plan

This docs-only decision should be verified with:

- `git diff --check`
- new decision no-index whitespace check.
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- forbidden check: no tracked `.cj` diff, no protected path diff / status, `runtime_state.cj` line count remains `10065`.
- public declaration scan still finds only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

Build and smoke must not be run in this docs-only round.

## Downstream Platform Object Implementation Admission Manifest Stabilization

Renderer platform object implementation admission manifest stabilization 已完成：

- [2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-platform-object-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 [runtime_renderer_platform_object_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_admission.cj) 的 owner / truth / canonical endpoint / stop-line。

Canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`。Current truth 仅限 platform object implementation intent / native handle admission policy / platform object lifecycle admission guard / teardown failure policy / no-platform-object-implementation readiness value facts。

Same-shape Boundary Brake：本 manifest 封账并拒绝 platform-object permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、Metal-device permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、receipt / record / publication。

唯一 downstream next opening：

`P1 internal Renderer Metal device-layer implementation preflight decision`
