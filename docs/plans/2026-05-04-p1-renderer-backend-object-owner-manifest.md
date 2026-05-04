# P1 Renderer backend object owner manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_backend_object.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-backend-object endpoint。

它不是 backend implementation manifest，不是 Metal / AppKit implementation plan，不是 platform object owner manifest，不是 command buffer commit / GPU submission / render execution manifest，也不是 renderer state write manifest。它只记录 backend object owner intent、backend lifecycle ownership policy、backend acceptance gate、platform confinement guard 与 no-backend-object readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_object.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoRenderExecutionReadiness`
- `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoBackendObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`

Current truth：

- backend object owner intent value facts。
- backend lifecycle ownership policy value facts。
- backend acceptance gate value facts。
- platform confinement guard value facts。
- no-backend-object readiness value facts。

## Current Pipeline

当前 backend object owner value pipeline：

1. `CjguiInternalRendererNoRenderExecutionReadiness`
2. `CjguiInternalRendererBackendObjectOwnerIntent`
3. `CjguiInternalRendererBackendLifecycleOwnershipPolicy`
4. `CjguiInternalRendererBackendAcceptanceGate`
5. `CjguiInternalRendererPlatformConfinementGuard`
6. `CjguiInternalRendererNoBackendObjectReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 backend object。
- 不创建 platform object。
- 不创建或引用 `MTLDevice` / `CAMetalLayer`。
- 不创建 command queue / drawable / command buffer / render pass descriptor / encoder / pipeline state。
- 不 commit command buffer。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不注册 callback。
- 不暴露 native handle / raw pointer。

## Value Semantics

`CjguiInternalRendererBackendObjectOwnerIntent` 只表达 future backend object owner intent，不是 backend object implementation、backend readiness、platform resource permission、renderer state write gate 或 public API。

`CjguiInternalRendererBackendLifecycleOwnershipPolicy` 只表达 future init / active / teardown / failure / rollback lifecycle facts；它不创建 backend object，不管理真实 backend lifecycle，不 retain / release platform resources。

`CjguiInternalRendererBackendAcceptanceGate` 只表达 future backend acceptance constraints；它不授予 backend readiness，不打开 backend implementation，不授予 command buffer commit / GPU submission / render execution permission。

`CjguiInternalRendererPlatformConfinementGuard` 只表达 future platform object confinement facts；它不持有 platform object，不持有 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer / render pass descriptor / encoder / pipeline state，不把 platform objects 放进 core packet。

`CjguiInternalRendererNoBackendObjectReadiness` 是当前 no-backend-object endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表 backend permission、platform resource permission、command buffer commit permission、GPU submission permission、render execution permission、renderer state write permission、frame pacing permission 或 public surface expansion。

## Relationship Facts

Backend object owner 与 platform resource owner / command queue / drawable / command buffer / render pass / encoder / draw call / pipeline state / render execution no-op 的关系只能作为 dehydrated lifecycle facts 表达：

- backend owner identity facts。
- backend lifecycle phase facts。
- lifecycle coverage acceptance facts。
- platform confinement facts。
- no-submit acceptance facts。
- no-draw rollback facts。
- failure / rollback / no-render path facts。
- future platform object confinement policy vocabulary。

这些 facts 不能携带 backend object、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass descriptor、encoder、pipeline state、GPU object、native handle、raw pointer、completion callback、present callback、command queue callback、observer callback、telemetry event、log sink、diagnostics output、frame scheduler、display link 或 renderer state write。

## Explicit Non-Truth

`CjguiInternalRendererNoBackendObjectReadiness` 明确不是：

- backend permission。
- backend object permission。
- backend-readiness final gate。
- backend-readiness wrapper。
- platform resource permission。
- platform object permission。
- command queue permission。
- drawable acquisition permission。
- command buffer commit permission。
- GPU submission permission。
- render execution permission。
- renderer state write permission。
- frame pacing permission。
- frame scheduler permission。
- display link permission。
- Metal / AppKit implementation。
- `MTLDevice` ownership。
- `CAMetalLayer` ownership。
- command queue ownership。
- drawable ownership。
- command buffer ownership。
- render pass descriptor ownership。
- encoder ownership。
- pipeline state ownership。
- native handle / raw pointer surface。
- backend object receipt / record / publication。
- renderer-state-write readiness wrapper。
- command-buffer-commit wrapper。
- GPU-submission wrapper。
- frame-pacing readiness wrapper。
- public API / public C ABI。

当前没有 backend object、platform object、native handle、raw pointer、command buffer commit、GPU submission、render execution、renderer state write、backend implementation、Metal implementation、AppKit implementation、frame scheduler 或 display link。

## Reference Evidence

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 支撑本 manifest 的 evidence：

- `MTLDevice` 是 command queue / buffers / textures 等 device-specific objects 的根，应属于 future backend/platform owner。
- `MTLCommandQueue` 创建 command buffers，应属于 future backend owner，不进入 core packet。
- `MTLCommandBuffer` commit 后不可复用，completion / presentation / resource retention 是 backend-local lifecycle concern。
- `CAMetalLayer` owns drawable pool，drawable acquisition must be late-bound and backend-local。
- Render pass descriptor / encoder / draw call / pipeline state 都是 backend-local lifecycle concerns。
- Resize / scale / color / frame pacing 可以作为 dehydrated facts 过界，但不能携带 platform object。
- Frame pacing remains platform/backend owner policy question, not backend object readiness.

这些 evidence 支撑 backend object owner truth，但不批准 backend implementation、platform object creation、command buffer commit、GPU submission、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- backend object receipt / record / publication。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- command-buffer-commit wrapper。
- GPU-submission wrapper。
- frame-pacing readiness wrapper。
- backend object implementation。
- platform object implementation。
- public surface expansion。

`CjguiInternalRendererNoBackendObjectReadiness` 已经是当前 no-backend-object endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 frame pacing / renderer state write / backend readiness，必须先做 docs-only preflight，并引用本 manifest 与 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。不得直接实现 frame scheduler / display link、backend、platform objects、command buffer commit、GPU submission、render execution 或 renderer state write。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no backend object creation。
- no platform object creation。
- no Metal / AppKit implementation。
- no `MTLDevice` / `CAMetalLayer` ownership。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation。
- no command buffer commit。
- no GPU submission。
- no render pass descriptor creation。
- no encoder creation。
- no pipeline state creation。
- no render execution。
- no draw call execution。
- no renderer state write。
- no frame scheduler / display link implementation。
- no native handle / raw pointer / platform resource token。
- no callback registration。
- no observer callback / event bus / telemetry / logging / public diagnostics。
- no backend-readiness wrapper。
- no renderer-state-write readiness wrapper。
- no command-buffer-commit wrapper。
- no GPU-submission wrapper。
- no frame-pacing readiness wrapper。
- no backend object receipt / record / publication。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer frame pacing owner preflight decision

推荐为下一阶段 opening。

理由：

- Backend object owner manifest 已固定 no-backend-object endpoint。
- Backend / Metal reference pack 已明确 frame pacing / display refresh 是独立 owner question。
- Frame pacing owner preflight 可以 docs-only 评估 frame pacing owner / lifecycle / readiness runway，但不得实现 frame scheduler、display link、render loop、backend object、platform object、command buffer commit、GPU submission、render execution 或 renderer state write。

### B. P1 internal Renderer renderer state write preflight decision

暂缓。

Renderer state write remains a hard stop-line. It should usually wait until frame pacing and backend-readiness questions are separated, otherwise it can be mistaken for backend acceptance or render completion truth.

### C. P1 internal Renderer backend-readiness value boundary revisit decision

暂缓。

Backend object owner truth is now fixed, but frame pacing owner evidence still needs docs-only separation before backend-readiness can be revisited without becoming a wrapper.

### D. Backend object hardening

Only if a gap is found.

Current manifest did not find lifecycle / acceptance / confinement expression gaps. If future review finds ambiguity, harden docs before downstream runtime boundary.

### E. Backend / Metal implementation

拒绝。

### F. Platform object / native handle implementation

拒绝。

### G. Command buffer commit / GPU submission / render execution implementation

拒绝。

### H. Renderer state write implementation

拒绝。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### J. Public surface expansion

拒绝。

### K. Consolidation

Only if clear duplicate / low-value helper / self-wrapping evidence appears.

Current risk is downstream thin wrapping, not consolidation need.

## Decision

This manifest stabilizes and closes the backend object owner endpoint.

Unique next opening:

`P1 internal Renderer frame pacing owner preflight decision`

The next round must be docs-only. It should evaluate frame pacing owner / lifecycle / readiness evidence and must not implement frame scheduler, display link, render loop, backend, Metal / AppKit, platform object, command buffer commit, GPU submission, render execution or renderer state write.

## Downstream Frame Pacing Owner Preflight

Renderer frame pacing owner preflight 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md)

该 preflight 以 `CjguiInternalRendererNoBackendObjectReadiness` 为唯一 future runtime input，判定下一步可以进入 frame pacing owner internal value boundary。该 downstream 只允许表达 frame pacing owner intent / display timing policy / frame request gate / pacing failure policy / no-frame-scheduler readiness value facts；不批准 frame scheduler、display link、render loop、timer、backend object creation、platform object creation、native handle、command buffer commit、GPU submission、render execution 或 renderer state write。

## Downstream Frame Pacing Owner Value Boundary Closure

Renderer frame pacing owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md)

该 closure 新增 `runtime/cjgui/src/runtime_renderer_frame_pacing.cj`，只消费 `CjguiInternalRendererNoBackendObjectReadiness`，canonical endpoint 是 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`。它证明 frame pacing owner 有 display timing / frame request gate / pacing failure / no-frame-scheduler 语义，不是 no-backend-object receipt / record / publication、backend-readiness wrapper 或 renderer-state-write wrapper。下一步必须先做 docs-only `P1 internal Renderer frame pacing owner closure / next frame pacing decision`。

## Downstream Frame Pacing Owner Next-boundary Decision

Renderer frame pacing owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()` 已足够作为当前 no-frame-scheduler endpoint，并选择下一步 docs-only `P1 internal Renderer frame pacing owner manifest stabilization bundle implementation`。该 downstream 不批准 frame pacing receipt / record / publication、backend-readiness wrapper、renderer-state-write readiness wrapper、command-buffer-commit wrapper、GPU-submission wrapper、real scheduler / display link / render loop、backend / Metal / AppKit implementation 或 renderer state write。

## Downstream Frame Pacing Owner Manifest Stabilization

Renderer frame pacing owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-frame-pacing-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-manifest-stabilization-closure-review.md)

该 manifest 固定 frame pacing owner endpoint，确认 `CjguiInternalRendererNoFrameSchedulerReadiness` 不是 scheduler permission、display-link permission、backend readiness、renderer-state-write readiness、render permission 或 GPU-submission permission。下一步转向 docs-only `P1 internal Renderer renderer state write preflight decision`；不批准 renderer state write implementation、backend-readiness wrapper、command-buffer-commit wrapper、GPU-submission wrapper、real scheduler / display link / render loop、backend / Metal / AppKit implementation 或 platform object implementation。

## Downstream Renderer State Write Preflight

Renderer state write preflight 已完成：

- [2026-05-04-p1-renderer-state-write-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-preflight-decision.md)

该 preflight 引用本 manifest 的 `CjguiInternalRendererNoBackendObjectReadiness` 作为 docs evidence，而不是 runtime input。下一步若实现 no-write value boundary，只能消费 `CjguiInternalRendererNoFrameSchedulerReadiness`，只输出 renderer state write intent / state mutation policy / commit visibility guard / rollback state policy / no-state-write readiness value facts；不批准 backend object creation、backend readiness implementation、platform object creation、native handle、command buffer commit、GPU submission、render execution、renderer state write、public diagnostics 或 public API。

## Downstream Backend-readiness Final Preflight

Renderer backend-readiness final preflight 已完成：

- [2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md)

该 final preflight 引用本 manifest 的 backend lifecycle ownership / backend acceptance gate / platform confinement / no-backend-object evidence 作为 docs evidence，而不是 runtime input。下一步若进入 backend-readiness value boundary，只能消费 `CjguiInternalRendererNoStateWriteReadiness`，只输出 backend readiness intent / platform lifecycle gate / execution admission gate / state visibility gate / no-backend-ready readiness value facts；不批准 backend object creation、platform object creation、native handle、command buffer commit、GPU submission、render execution、renderer state write 或 public API。
