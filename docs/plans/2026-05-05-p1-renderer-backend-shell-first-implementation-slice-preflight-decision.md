# P1 Renderer backend shell first implementation slice preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮选择 real backend shell 的第一实现切口。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [Real backend shell implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [Real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [Command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- `labs/macos_bridge_smoke/scripts/*.sh` read-only for feasibility / teardown / smoke evidence only.

## Decision

选择 A：`backend shell skeleton / no-resource implementation slice`。

唯一 next opening：

`P1 internal Renderer backend shell skeleton no-resource value boundary bundle implementation`

下一轮若执行，也只能新增 internal value boundary。它不得创建 backend shell object、backend object、platform object、native handle、raw pointer、Metal / AppKit / Objective-C / FFI resource、command buffer、drawable、render pass、encoder、pipeline state 或 GPU work。

## Why A Wins

Current evidence is strong enough to introduce a no-resource backend shell skeleton owner, but not strong enough to touch native bridge, platform object creation, Metal device/layer creation, command queue creation, drawable acquisition or command submission.

A is the narrowest safe first implementation slice because it can add new semantics without crossing resource boundaries:

- backend shell skeleton intent.
- lifecycle envelope for future create / active / degraded / teardown phases.
- no-resource guard.
- failure rollback policy.
- teardown / confinement stop-line facts.
- no-backend-shell-skeleton-resource readiness value facts.

This is new owner / lifecycle / failure / teardown vocabulary. It is not a receipt, not a record, not a publication, and not a backend-ready permission wrapper.

B is not selected because native resource bridge vocabulary is still too close to handle ownership, FFI teardown, bridge ABI shape and platform resource lifetime. The risk ledger explicitly warns about FFI ownership, GPU lifecycle, thin-bridge thickness illusion and AppKit / runloop overfitting. A gives us a smaller staging point before reopening bridge questions.

## First Slice Shape

Default owner candidate for the next value boundary:

- `runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj`

Default runtime input candidate:

- `CjguiInternalRendererNoGpuSubmissionReadiness`
- `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`

Reasoning:

- `CjguiInternalRendererNoGpuSubmissionReadiness` is the latest stabilized renderer backend branch tail.
- It gives command submission intent / commit policy / presentation gate / GPU submission failure facts only.
- Earlier endpoints remain docs evidence, not additional runtime inputs.
- A single runtime input prevents a multi-tail wrapper and keeps ownership local.

Candidate internal-only facts for the next slice:

- `CjguiInternalRendererBackendShellSkeletonIntent`
- `CjguiInternalRendererBackendShellLifecycleEnvelope`
- `CjguiInternalRendererBackendShellNoResourceGuard`
- `CjguiInternalRendererBackendShellFailureRollbackPolicy`
- `CjguiInternalRendererBackendShellNoResourceReadiness`
- matching builders
- `cjguiInternalExecuteDefaultRendererBackendShellSkeletonNoResourceDraft()`

The exact symbol names may be adjusted by the next implementation card, but the semantics must remain equivalent and no-resource.

## Allowed Truth For The Next Slice

The first implementation slice may only express internal value facts:

- future backend shell skeleton intent.
- future lifecycle envelope facts.
- no-resource guard facts.
- failure / rollback facts.
- teardown ordering facts.
- platform / Metal confinement facts.
- no-resource backend shell readiness facts.

It may not express:

- real backend shell object existence.
- backend implementation readiness.
- backend-ready permission.
- platform object permission.
- native handle permission.
- Metal device/layer permission.
- command queue permission.
- drawable permission.
- command buffer permission.
- GPU submission permission.
- render permission.
- renderer state write permission.
- public API or C ABI permission.

## Resource Lifetime / Teardown / Failure Stop-line

The next slice must keep resource lifetime as a future policy, not as a resource operation.

Allowed:

- dehydrated create / active / degraded / teardown phase names.
- failure rollback reason facts.
- no-draw fallback facts.
- idempotent teardown intent facts.
- platform confinement facts.
- explicit no-resource facts.

Forbidden:

- creating backend shell object.
- creating backend object.
- creating platform object.
- creating or storing native handle.
- creating or storing raw pointer.
- defining real retain / release / destroy FFI calls.
- calling bridge code.
- modifying bridge / smoke / harness / native entry.
- calling Metal / AppKit / Objective-C / FFI.
- creating `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable or command buffer.
- calling `commit`, `present` or `nextDrawable`.
- registering callbacks, observers, event bus hooks or telemetry.
- writing renderer state or `runtime_state.cj`.

## Evidence Assessment

### No-draw backend shell evidence

`CjguiInternalRendererNoBackendShellReadiness` gives shell lifecycle, no-draw execution gate and shell teardown vocabulary.

It is not backend shell object permission, backend implementation permission, backend object permission, platform object permission, GPU submission permission, render permission, renderer state write permission, public API permission or C ABI permission.

### Backend platform object evidence

`CjguiInternalRendererNoPlatformObjectReadiness` gives native resource ownership, lifecycle teardown and confinement failure vocabulary.

It is not platform object creation, native handle, raw pointer, bridge ABI, FFI call, Metal device permission or backend implementation permission.

### Metal device-layer evidence

`CjguiInternalRendererNoMetalDeviceLayerReadiness` gives device selection, layer binding and scale / color-space vocabulary.

It is not `MTLDevice`, `CAMetalLayer`, command queue, drawable, Metal API, AppKit API, Objective-C call or FFI permission.

### Real command queue evidence

`CjguiInternalRendererNoRealCommandQueueReadiness` gives queue creation policy, ownership guard and teardown vocabulary.

It is not `MTLCommandQueue` permission, command buffer permission, drawable permission, GPU submission permission, render permission or backend implementation permission.

### Real drawable evidence

`CjguiInternalRendererNoRealDrawableReadiness` gives drawable availability, acquisition guard and presentation ownership vocabulary.

It is not drawable acquisition permission, `nextDrawable` permission, drawable present permission, command buffer permission, GPU submission permission or backend implementation permission.

### Command submission evidence

`CjguiInternalRendererNoGpuSubmissionReadiness` gives command submission intent, command buffer commit policy, drawable presentation gate and GPU submission failure vocabulary.

It is not command buffer permission, drawable present permission, GPU submission permission, render permission, backend implementation permission, renderer state write permission, public API permission or C ABI permission.

### Backend / Metal reference evidence

The reference pack proves the real backend will eventually need device, layer, command queue, drawable, command buffer, render pass, encoder, pipeline state, completion and resource retention ownership.

It does not approve any of those objects now. It only supports choosing a safer no-resource owner before those real resources are reopened.

### Smoke evidence

`labs/macos_bridge_smoke` proves feasibility of C ABI, Objective-C bridge, AppKit window, Metal clear, teardown logs, auto-close smoke, screenshot feasibility and target-window verification on this machine.

It remains feasibility / teardown / smoke evidence only. It cannot become runtime truth, backend shell owner truth, backend object lifecycle truth, public ABI truth, renderer state write truth, visual baseline truth or GPU submission correctness proof.

## Candidate Comparison

### A. Backend shell skeleton / no-resource implementation slice

选择。

This next slice may add an internal-only no-resource value boundary. It should establish backend shell skeleton owner vocabulary, lifecycle envelope, failure rollback, teardown and confinement facts without creating resources.

### B. Native resource bridge preflight

暂缓。

This is useful only after the no-resource skeleton defines the shell owner and teardown vocabulary. Opening bridge / handle ownership now would pull the first implementation slice too close to native handle, raw pointer, FFI ownership and smoke / bridge modification risk.

### C. Platform object implementation preflight

暂缓。

Platform object create / retain / release / teardown / failure needs the no-resource skeleton stop-line first. Current platform object owner manifest remains value facts only.

### D. Metal device-layer implementation preflight

暂缓。

Device / layer creation owner is downstream of platform object and no-resource backend shell skeleton vocabulary. Current device-layer manifest remains value facts only.

### E. Real command queue implementation preflight

暂缓。

Command queue implementation must wait until backend shell / platform object first slice is stabilized.

### F. Real drawable acquisition implementation preflight

暂缓。

Drawable acquisition depends on backend shell and command queue / layer ownership clarity.

### G. Command buffer commit / GPU submission implementation preflight

暂缓。

Still too close to GPU work. Current command submission endpoint is explicitly no-gpu-submission.

### H. Direct backend shell implementation

拒绝。

This preflight does not approve direct backend shell object implementation.

### I. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, resource token or pointer-like storage is approved.

### J. Direct Metal / AppKit / Objective-C / FFI implementation

拒绝。

No Metal, AppKit, Objective-C, FFI or bridge call is approved.

### K. GPU submission / render execution

拒绝。

No command buffer commit, drawable present, GPU submission, render execution, render pass, encoder, pipeline state or draw call is approved.

### L. Renderer state write

拒绝。

No renderer state mutation and no `runtime_state.cj` write are approved.

### M. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged.

### N. Receipt / record / publication

拒绝。

Do not add backend shell receipt / record / publication, backend-ready permission wrapper, resource wrapper, GPU wrapper or render-permission wrapper.

### O. Consolidation

暂缓。

No duplicate / low-value / self-wrapping evidence was found. Current evidence points to a narrow no-resource value boundary, not deletion.

## Same-shape Boundary Brake

The next slice must not wrap any existing readiness endpoint or milestone into a permission-shaped tail.

Do not wrap:

- `CjguiInternalRendererNoBackendShellReadiness`
- `CjguiInternalRendererNoPlatformObjectReadiness`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `CjguiInternalRendererNoRealDrawableReadiness`
- `CjguiInternalRendererNoGpuSubmissionReadiness`
- backend-readiness branch milestone
- backend / Metal reference pack
- smoke evidence

Forbidden wrapper shapes:

- backend-shell-ready permission wrapper.
- native-handle wrapper.
- platform-object wrapper.
- Metal-device wrapper.
- layer-ready wrapper.
- queue-ready wrapper.
- drawable-ready wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.

The next value boundary must prove new semantics:

- skeleton owner.
- lifecycle envelope.
- no-resource guard.
- failure rollback.
- teardown / confinement stop-line.
- no-resource readiness facts.

## CJGUI Host Sovereignty

Future backend shell work must keep CJGUI host / Action Router / semantic truth sovereignty.

It must not introduce:

- browser host as primary runtime owner.
- WebView host as primary renderer.
- browser kernel as main rendering authority.
- foreign surface as main input owner.
- external surface as semantic truth owner.
- AI action bypass around CJGUI owner / gateway boundaries.

## Validation Plan

This docs-only decision should be verified with:

- `git diff --check`
- new decision no-index whitespace check.
- Markdown absolute link missing target check scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- forbidden check: no tracked `.cj` diff, no protected path diff / status, `runtime_state.cj` line count remains `10065`.
- public declaration scan still finds only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

Build and smoke must not be run in this docs-only round.

## Unique Next Opening

`P1 internal Renderer backend shell skeleton no-resource value boundary bundle implementation`

## Downstream Backend Shell Skeleton No-resource Value Boundary

Backend shell skeleton no-resource value boundary 已完成：

- [2026-05-05-p1-internal-renderer-backend-shell-skeleton-no-resource-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-no-resource-value-boundary-closure-review.md)

该 implementation 新增 internal-only `runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj`，只消费 `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`。

Downstream next opening：

`P1 internal Renderer backend shell skeleton closure / next backend shell skeleton decision`

## Downstream Backend Shell Skeleton Next-boundary Decision

Backend shell skeleton next-boundary decision 已完成：

- [2026-05-05-p1-renderer-backend-shell-skeleton-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()` 已足够作为当前 no-resource-backend-shell endpoint。下一步选择 docs-only `P1 internal Renderer backend shell skeleton manifest stabilization bundle implementation`。

Same-shape Boundary Brake 继续生效：不得把 no-resource-backend-shell endpoint 包成 backend-shell-ready permission wrapper、native-handle wrapper、platform-object wrapper、Metal-device wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、receipt / record / publication。

## Downstream Backend Shell Skeleton Manifest Stabilization

Backend shell skeleton manifest stabilization 已完成：

- [2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [2026-05-05-p1-internal-renderer-backend-shell-skeleton-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-manifest-stabilization-closure-review.md)

该 manifest 封账 no-resource-backend-shell endpoint。下一步转向 docs-only `P1 internal Renderer native resource bridge preflight decision`，仍不得创建 native handle、raw pointer、platform object、Metal / AppKit / Objective-C / FFI resource、GPU work、render execution、renderer state write 或 public API / C ABI。
