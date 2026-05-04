# P1 Renderer backend-readiness manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_backend_readiness.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-backend-ready endpoint。

它不是 backend implementation manifest，不是 Metal / AppKit implementation plan，不是 platform resource implementation plan，不是 command buffer commit / GPU submission plan，也不是 renderer state write manifest。它只记录 backend readiness intent、platform lifecycle gate、execution admission gate、state visibility gate 与 no-backend-ready readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_readiness.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoStateWriteReadiness`
- `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoBackendReadyReadiness`
- `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`

Current truth：

- backend readiness intent value facts。
- platform lifecycle gate value facts。
- execution admission gate value facts。
- state visibility gate value facts。
- no-backend-ready readiness value facts。

## Current Pipeline

当前 backend-readiness value pipeline：

1. `CjguiInternalRendererNoStateWriteReadiness`
2. `CjguiInternalRendererBackendReadinessIntent`
3. `CjguiInternalRendererPlatformLifecycleGate`
4. `CjguiInternalRendererExecutionAdmissionGate`
5. `CjguiInternalRendererStateVisibilityGate`
6. `CjguiInternalRendererNoBackendReadyReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 backend object。
- 不创建 platform object。
- 不创建或引用 `MTLDevice` / `CAMetalLayer`。
- 不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state。
- 不提交 command buffer。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不写或触碰 `runtime_state.cj`。
- 不注册 callback / observer / event bus / telemetry。
- 不暴露 native handle / raw pointer。
- 不开放 public diagnostics / public API / C ABI。
- 不新增 module-level `var`。
- 不新增 public declaration。

## Value Semantics

`CjguiInternalRendererBackendReadinessIntent` 只表达 future backend-readiness owner intent。它不是 backend-ready permission、backend implementation、render permission、GPU submission wrapper、receipt、record 或 publication。

`CjguiInternalRendererPlatformLifecycleGate` 只表达 future platform lifecycle coverage facts。它不创建 platform object，不创建 backend object，不创建或引用 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder 或 pipeline state，不持有 native handle / raw pointer。

`CjguiInternalRendererExecutionAdmissionGate` 只表达 future no-submit / no-render admission facts。它不提交 command buffer，不提交 GPU work，不执行 render，不创建 encoder / render pass / pipeline state，不观察真实 completion。

`CjguiInternalRendererStateVisibilityGate` 只表达 future state visibility / rollback / no-write facts。它不写 renderer state，不写或触碰 `runtime_state.cj`，不记录 frame completion，不开放 external API surface。

`CjguiInternalRendererNoBackendReadyReadiness` 是当前 no-backend-ready endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表 backend-ready permission、render permission、GPU submission permission、command buffer commit permission、platform object permission、renderer state write permission、public diagnostics permission 或 public API permission。

## Explicit Non-Truth

`CjguiInternalRendererNoBackendReadyReadiness` 明确不是：

- backend-ready permission。
- backend implementation permission。
- backend object permission。
- platform object permission。
- platform resource permission。
- `MTLDevice` ownership。
- `CAMetalLayer` ownership。
- command queue ownership。
- drawable ownership。
- command buffer ownership。
- command buffer commit permission。
- GPU submission permission。
- render pass ownership。
- encoder ownership。
- pipeline state ownership。
- render execution permission。
- render permission。
- renderer state write permission。
- frame completion record。
- diagnostics publication。
- public diagnostics permission。
- public API permission。
- public C ABI。
- backend-readiness receipt / record / publication。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- platform-object wrapper。
- renderer-state-write wrapper。

当前没有 backend implementation、Metal implementation、AppKit implementation、backend object、platform object、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state、native handle、raw pointer、command buffer commit、GPU submission、render execution、renderer state write、frame completion recording、diagnostics / event bus / observer / telemetry 或 public API expansion。

## Relationship Facts

Backend-readiness 与 renderer state write no-write / frame pacing owner / backend object owner / render execution no-op / platform lifecycle manifests 的关系只能作为 dehydrated value facts 表达：

- no-state-write input preservation facts。
- future backend-readiness intent facts。
- platform lifecycle coverage facts。
- backend object lifecycle coverage facts。
- frame pacing coverage facts。
- no-submit admission facts。
- no-render execution facts。
- no-command-commit facts。
- state visibility facts。
- rollback / no-draw / no-write facts。
- no-backend-ready stop-line facts。

这些 facts 不能携带 backend object、platform object、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass descriptor、encoder、pipeline state、GPU object、native handle、raw pointer、completion callback、present callback、observer callback、event bus、telemetry event、diagnostics output、frame scheduler、display link、renderer state object 或 public API handle。

## Evidence Chain

[Backend-readiness next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()` 足够作为当前 no-backend-ready endpoint，并选择本 manifest stabilization。

[Backend-readiness value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-value-boundary-closure-review.md) 已确认 owner file、canonical endpoint、default draft 与 value pipeline。

[Backend-readiness final preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md) 只批准 internal value boundary，不批准真实 backend / Metal / AppKit implementation。

[State write no-write manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md) 固定 upstream `CjguiInternalRendererNoStateWriteReadiness`，并明确它不是 renderer state write permission、backend readiness、GPU submission permission、frame completion permission、render permission 或 public API permission。

[Frame pacing owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md) 与 [backend object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md) 只作为 docs evidence。它们不成为 runtime input，也不授予 backend readiness、platform object creation、command buffer commit、GPU submission、render execution 或 renderer state write permission。

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 支撑本 manifest 的 lifecycle evidence，但不批准 implementation。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- backend-readiness receipt / record / publication。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- platform-object wrapper。
- renderer-state-write wrapper。
- command-buffer-commit wrapper。
- public diagnostics / public API wrapper。
- real backend implementation。
- platform resource implementation。
- public surface expansion。

`CjguiInternalRendererNoBackendReadyReadiness` 已经是当前 no-backend-ready endpoint。继续新增 receipt / record / publication 或 permission wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 implementation permission evidence。

若未来靠近真实 backend、platform resource、GPU submission、command buffer commit、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API，必须先做 docs-only preflight，并引用本 manifest、[2026-05-04-p1-renderer-backend-readiness-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-next-boundary-decision.md) 与 backend / Metal reference evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no backend implementation。
- no Metal implementation。
- no AppKit implementation。
- no backend object creation。
- no platform object creation。
- no `MTLDevice` / `CAMetalLayer` ownership。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation。
- no command buffer commit。
- no GPU submission。
- no render pass creation。
- no encoder creation。
- no pipeline state creation。
- no render execution。
- no draw call execution。
- no renderer state write。
- no `runtime_state.cj` touch。
- no frame completion recording。
- no callback / observer / event bus / telemetry / diagnostics publication。
- no native handle / raw pointer / platform resource token。
- no module-level `var`。
- no public declaration。
- no public diagnostics / public API / public C ABI。
- no backend-readiness receipt / record / publication。
- no backend-ready permission wrapper。
- no GPU-submission wrapper。
- no render-permission wrapper。
- no platform-object wrapper。
- no renderer-state-write wrapper。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer backend readiness branch milestone stabilization bundle implementation

推荐为下一阶段 opening。

理由：

- Backend-readiness manifest 已固定 no-backend-ready endpoint。
- Renderer backend readiness branch 已从 backend / Metal reference pack、platform resource、command queue、drawable、command buffer、render pass、encoder、draw call、pipeline state、render execution no-op、backend object、frame pacing、state write no-write 收束到 no-backend-ready endpoint。
- 下一步应 docs-only 总结整条 branch milestone、canonical endpoint、evidence chain、stop-line 与 future reopening conditions，而不是继续新增 readiness wrapper。

### B. Real backend implementation preflight

暂缓。

No-backend-ready manifest 不是 backend-ready permission。进入真实 backend 前仍需要新的 docs-only preflight，并且必须重新证明 platform object lifecycle、bridge confinement、command buffer commit、GPU submission、failure / rollback 与 renderer state write policy。

### C. Platform resource implementation preflight

暂缓。

Platform resource owner 当前仍是 no-platform-resource value facts；本 manifest 不授权 platform object creation。

### D. Command buffer commit / GPU submission preflight

暂缓。

Render execution no-op 与 backend-readiness manifest 都明确 no-submit。该方向仍太接近真实 GPU submission。

### E. Renderer state write real preflight

暂缓。

State write no-write manifest 已封账，但本 manifest 不授权真实 renderer state mutation 或 frame completion recording。

### F. Backend / Metal / AppKit implementation

拒绝。

### G. Public surface expansion

拒绝。

### H. Receipt / record / publication

拒绝。

### I. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前需要 branch milestone stabilization，不是 consolidation。

## Decision

This manifest stabilizes and closes the renderer backend-readiness no-backend-ready endpoint.

Unique next opening:

`P1 internal Renderer backend readiness branch milestone stabilization bundle implementation`

下一轮必须 docs-only，总结 backend readiness branch owner / truth / evidence chain / stop-line / reopening conditions；不得实现 backend、Metal、AppKit、platform object、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。

## Downstream Branch Milestone Stabilization

Renderer backend-readiness branch milestone stabilization 已完成：

- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-readiness-branch-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-branch-milestone-stabilization-closure-review.md)

该 milestone 固定本 manifest 的 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()` 为 renderer backend-readiness branch canonical tail，并选择下一步 docs-only `P1 internal Renderer real backend implementation preflight decision`。它不改变本 manifest 的 no-backend-ready stop-line，不批准 backend implementation、platform object、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。
