# P1 Renderer real backend implementation preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮评估 renderer backend-readiness branch milestone 之后，是否可以从 `CjguiInternalRendererNoBackendReadyReadiness` 靠近真实 backend implementation。

本轮不修改 `.cj`，不新建 runtime owner，不运行 build / smoke，不批准 backend / Metal / AppKit implementation，不创建 platform object，不 commit / present / submit GPU work，不写 renderer state，不接 public API，不接 browser / foreign surface，不接 diagnostics output / telemetry / observer / event bus。

## Inputs Read

- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-readiness-branch-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-branch-milestone-stabilization-closure-review.md)
- [2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [gui-framework-pitfalls-intelligence.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/gui-framework-pitfalls-intelligence.md)

## Decision

可以靠近真实 backend implementation，但不能直接实现。

`CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()` 已经足以作为 backend-readiness branch 的 no-backend-ready tail；它只证明 value facts chain 完整，可以启动真实 backend 第一刀的更窄 docs-only preflight。它不是 backend-ready permission、implementation-readiness wrapper、platform object permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

下一步选择：

`P1 internal Renderer real backend first-slice owner preflight decision`

下一步仍必须 docs-only，目标是决定真实 backend 第一刀应切在 platform object owner、Metal device / layer owner、command queue / drawable owner、no-draw backend shell，还是其他更小 owner。下一步不实现 backend，不创建平台对象，不提交 GPU work。

## Required Real Backend Owners

真实 backend 最小实现前至少需要以下 owner / gate 的 decision evidence：

- backend platform object owner：定义 future backend object 与 platform object 的创建者、持有者、destroy / teardown 顺序、failure category。
- Metal device / layer / command queue owner：定义 future device、layer、command queue 的生命周期、thread affinity、capability query、degraded / recoverable path。
- drawable acquisition real owner：定义 late acquisition、timeout / unavailable / nil handling、resize / scale / color-space relation、release timing。
- command buffer commit / GPU submission gate：定义 command buffer creation / commit ownership、completion / failure observation、resource retention until completion。
- render pass / encoder / pipeline state materialization owner：定义 descriptor / attachment / encoder / pipeline state materialization boundaries without leaking them into core packet truth。
- no-draw / failure / teardown path：定义 no-draw result、teardown ordering、rollback and destroy idempotence before any happy-path render。
- renderer state write relation：定义 completion / present / no-draw facts can or cannot become renderer state writes, and which owner is allowed to mutate state.
- smoke / visual verification strategy：define auto-close, lifecycle logs, first-frame evidence, manual visual fallback, and why screenshot / pixel hash is only smoke evidence until a future baseline policy exists.

## Evidence Usable Now

- Backend-readiness branch milestone proves the value-fact chain is closed from packet truth through platform resource, command queue, drawable, command buffer, render pass, encoder, draw call, pipeline state, render execution no-op, backend object owner, frame pacing, state write no-write, and backend-readiness tail.
- Backend / Metal reference pack provides official evidence for command queue / command buffer / drawable / render pass / encoder / pipeline / frame pacing resource relations.
- AppKit / Metal bridge boundary preflight provides handle lifecycle, main-thread owner, structured error category, narrow C ABI, capability query, teardown ordering, and verification strategy questions.
- macOS bridge smoke closure proves Cangjie can enter a C ABI bridge, reach AppKit / Metal, show a Metal clear window, auto-close, and return successfully.
- Bridge cleanup closure proves a lab-only bridge can hold native objects internally, run capability checks, produce lifecycle logs, and auto-close through a destroy path.
- Risk ledger and pitfalls research confirm the high-risk areas: GPU resource lifecycle, FFI ownership, main-thread exclusivity, AppKit runloop overfitting, pixel hash determinism, platform abstraction leakage, and foreign surface containment.

## Evidence Still Not Runtime Truth

- All renderer owner endpoints remain no-op / no-write / no-backend-ready value facts.
- The reference pack is docs evidence only, not runtime input.
- `labs/macos_bridge_smoke` is an experiment; it cannot define formal runtime owner truth, public ABI, platform handle model, multi-window lifecycle, cross-thread queue, diagnostics surface, visual baseline, or renderer state write.
- The smoke bridge's native object ownership is useful as teardown evidence, but it is not a reusable runtime backend object.
- Last-error C ABI from the bridge cleanup remains experimental and cannot become public diagnostics or a long-term contract without a new preflight.
- Manual visual confirmation and screenshot attempts are smoke evidence only; they cannot become renderer correctness truth or golden baseline policy.

## Candidate Comparison

### A. P1 internal Renderer real backend first-slice owner preflight decision

谨慎推荐。

The branch now has enough value-fact and reference evidence to ask where the first real backend slice belongs. This must stay docs-only and must compare owner / lifecycle / teardown / failure / verification evidence before any implementation.

### B. P1 internal Renderer platform object implementation preflight decision

暂缓。

Platform object ownership is a strong candidate, but picking it directly would skip the first-slice comparison. It should be reconsidered after the first-slice owner preflight decides whether platform object owner is the safest first cut.

### C. P1 internal Renderer command buffer commit / GPU submission preflight decision

暂缓。

This is too close to real GPU execution while platform object owner, device / layer owner, command queue owner, drawable owner, teardown, and no-draw strategy are still not runtime truths.

### D. P1 internal Renderer no-draw Metal backend shell implementation preflight decision

暂缓。

A no-draw backend shell may become the first implementation candidate, but it still needs owner, teardown, no-draw, capability, and smoke strategy comparison before being selected.

### E. Renderer state write real preflight

暂缓。

State write no-write facts exist, but real state mutation must wait until backend owner, GPU submission / completion, no-draw, and verification paths are better constrained.

### F. Dirty-region / invalidation preflight

暂缓。

Dirty-region and invalidation are UI / renderer integration concerns; opening them before real backend owner truth would create scheduling and redraw ambiguity.

### G. AI-native operability / occlusion gate preflight

暂缓。

This remains a registered future radar. It does not alter the current renderer backend branch and must not compete with backend owner decisions.

### H. Direct Metal / AppKit backend implementation

拒绝。

Backend-readiness milestone does not grant implementation permission.

### I. Direct command buffer commit / GPU submission / render execution

拒绝。

The current chain explicitly ends in no-submit and no-render-execution facts.

### J. Direct renderer state write or `runtime_state.cj`

拒绝。

State write remains no-write. `runtime_state.cj` is not part of this branch.

### K. Public API / public C ABI expansion

拒绝。

The public allowlist remains unchanged.

### L. Receipt / record / publication / backend-ready permission wrapper

拒绝。

The no-backend-ready tail is already closed; adding another wrapper would be self-wrapping, not new owner evidence.

### M. Consolidation

暂缓。

Only choose consolidation if a future review finds explicit duplicate / low-value / self-wrapping evidence. The current need is first-slice owner decision.

## Same-shape Boundary Brake

This preflight stops `CjguiInternalRendererNoBackendReadyReadiness` from becoming a real-backend receipt, implementation-readiness wrapper, backend-ready permission wrapper, GPU-submission wrapper, render-permission wrapper, platform-object wrapper, diagnostics wrapper, or public API wrapper.

Any future move toward implementation must add new owner / lifecycle / teardown / failure / verification evidence. It must not continue the no-backend-ready tail with another same-shape value wrapper.

## Stop-line

This decision explicitly does not create:

- `MTLDevice`
- `CAMetalLayer`
- command queue
- drawable
- command buffer
- render pass
- encoder
- pipeline state
- command buffer commit
- drawable present
- GPU submission
- renderer state write
- public API
- browser / foreign surface
- diagnostics output
- telemetry
- observer
- event bus

## Downstream

Unique next opening:

`P1 internal Renderer real backend first-slice owner preflight decision`

The next preflight must remain docs-only and compare first-slice owner candidates before any runtime owner or backend code is added.

## Downstream First-slice Owner Preflight

Renderer real backend first-slice owner preflight 已完成：

- [2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md)

该 preflight 选择下一轮 docs-only `P1 internal Renderer backend platform object owner preflight decision`。理由是 platform object / native resource 的 create / retain / release / teardown / failure / confinement 是所有后续 Metal device / layer / command queue / drawable owner 的硬前置；no-draw backend shell 在该 ownership 未冻结前容易退化成 backend shell wrapper。

它不批准 internal value boundary、runtime owner、backend implementation、Metal / AppKit implementation、platform object creation、command buffer commit、GPU submission、render execution、renderer state write、public API、diagnostics output、telemetry、observer 或 event bus。

Unique next opening:

`P1 internal Renderer backend platform object owner preflight decision`
