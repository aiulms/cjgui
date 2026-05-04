# P1 Renderer backend-readiness next-boundary decision

日期：2026-05-04

状态：next-boundary decision

## Scope

本轮是 docs-only decision。它不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮只评估 `CjguiInternalRendererNoBackendReadyReadiness` 是否已经足够作为当前 no-backend-ready endpoint，并决定下一步是否进入 manifest stabilization。它不批准 backend implementation、platform object creation、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。

## Inputs Read

- [runtime_renderer_backend_readiness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_readiness.cj)
- [2026-05-04-p1-internal-renderer-backend-readiness-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md)
- [2026-05-04-p1-renderer-state-write-no-write-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)

## Endpoint Assessment

`CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()` 已足够作为当前 no-backend-ready endpoint。

理由：

- Owner file 已存在于 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_readiness.cj`。
- 唯一 runtime input 是 `CjguiInternalRendererNoStateWriteReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`。
- Endpoint truth 已覆盖 backend readiness intent / platform lifecycle gate / execution admission gate / state visibility gate / no-backend-ready readiness value facts。
- Open path 从 no-state-write endpoint 出发，继续确认 no backend object、no platform object、no command buffer commit、no GPU submission、no render execution、no renderer state mutation、no external API surface。
- Defer path 保持 defer，不伪造 backend-ready。
- Blocked / inconsistent path fail-closed blocked。
- Closure 已记录 build / smoke / source scan / forbidden path scan / public declaration scan 与 GitNexus detect fallback，证明本 endpoint 是 internal value boundary，不是 permission boundary。

## Boundary Meaning

当前 endpoint 只代表：

- backend readiness intent value facts。
- platform lifecycle gate value facts。
- execution admission gate value facts。
- state visibility gate value facts。
- no-backend-ready readiness value facts。

当前 endpoint 明确不是：

- backend-ready permission。
- backend implementation permission。
- platform object permission。
- render permission。
- GPU submission permission。
- command buffer commit permission。
- renderer state write permission。
- public diagnostics permission。
- public API permission。
- backend-readiness receipt / record / publication。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- platform-object wrapper。

## Candidate Comparison

### A. P1 internal Renderer backend-readiness manifest stabilization bundle implementation

推荐为唯一 next opening。

理由：

- `CjguiInternalRendererNoBackendReadyReadiness` 已经足够作为当前 no-backend-ready endpoint。
- 下一步应固定 `runtime_renderer_backend_readiness.cj` 的 owner / truth / canonical endpoint / stop-line，而不是继续包一层 tail wrapper。
- Manifest 可以把 canonical endpoint、default draft、唯一 runtime input、current truth、Same-shape Boundary Brake 和 non-permission stop-line 写清楚。
- 下一步仍必须 docs-only，不得实现 backend、platform object、GPU submission、render execution、renderer state write、public diagnostics 或 public API。

### B. Real backend implementation preflight

暂缓。

No-backend-ready endpoint 尚未 manifest stabilization，且 real backend implementation 太靠近 platform object creation、command buffer commit 与 GPU submission。不能直接选择。

### C. Platform resource implementation

暂缓。

Platform resource owner 已作为 no-platform-resource value facts 封账；当前不批准创建 device / layer / command queue / drawable / command buffer / render pass / encoder / pipeline state。

### D. Command buffer commit / GPU submission

暂缓并继续禁止。

当前 render execution no-op 与 backend-readiness endpoint 都明确 no-submit；不能把 no-backend-ready endpoint解释为 commit / submission runway。

### E. Renderer state write

暂缓并继续禁止。

State write no-write manifest 已封账；backend-readiness endpoint 只能引用 no-state-write facts，不得写 renderer state 或记录 frame completion。

### F. Frame pacing hardening

暂缓。

Frame pacing owner manifest 已固定 no-frame-scheduler endpoint；当前未发现 display timing / request gate / pacing failure facts 阻塞 backend-readiness manifest stabilization。

### G. Backend-readiness receipt / record / publication

拒绝。

该方向会把 `CjguiInternalRendererNoBackendReadyReadiness` 做成同构 tail wrapper，缺少新的 owner truth、consumer、lifecycle 或 implementation permission evidence。

### H. Backend-ready permission wrapper

拒绝。

Backend-readiness endpoint 不是 backend-ready permission，也不能转化为 permission wrapper。

### I. GPU-submission wrapper

拒绝。

当前 no-submit stop-line 已由 render execution no-op / backend-readiness endpoint 固定。

### J. Render-permission wrapper

拒绝。

当前 no-render stop-line 已固定；不得从 readiness facts 推导 render permission。

### K. Platform-object wrapper

拒绝。

当前 no-platform-object stop-line 已固定；不得从 readiness facts 推导 platform object ownership。

### L. Dirty-region / UI integration

暂缓。

### M. Public surface expansion

拒绝。

### N. Consolidation

暂缓。

仅在明确 duplicate / low-value helper / self-wrapping evidence 出现时选择。当前需要 manifest stabilization，不是 consolidation。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 decision 生效。

`CjguiInternalRendererNoBackendReadyReadiness` 不再继续包装成 tail wrapper。当前 endpoint 只代表 backend readiness intent / platform lifecycle gate / execution admission gate / state visibility gate / no-backend-ready readiness value facts。

不得把它包装成：

- backend-readiness receipt / record / publication。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- platform-object wrapper。
- renderer-state-write wrapper。
- public diagnostics / public API wrapper。

若下一步选择 manifest stabilization，manifest 必须继续写清 `NoBackendReadyReadiness` 不是 backend-ready permission、render permission、GPU submission permission、platform object permission、renderer state write permission 或 public API permission。

## Decision

`CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()` 已足够作为当前 no-backend-ready endpoint。

唯一 next opening：

`P1 internal Renderer backend-readiness manifest stabilization bundle implementation`

下一轮必须 docs-only，固定 `runtime_renderer_backend_readiness.cj` owner / truth / canonical endpoint / stop-line；不得实现 backend、Metal、AppKit、platform object、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。

## Downstream Backend-readiness Manifest Stabilization

Renderer backend-readiness manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-readiness-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-manifest-stabilization-closure-review.md)

该 manifest stabilization 固定 `runtime_renderer_backend_readiness.cj` owner / truth / canonical endpoint / stop-line，继续拒绝 backend-readiness receipt / record / publication、backend-ready permission wrapper、GPU-submission wrapper、render-permission wrapper、platform-object wrapper、backend implementation、platform object creation、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。下一步进入 docs-only `P1 internal Renderer backend readiness branch milestone stabilization bundle implementation`。
