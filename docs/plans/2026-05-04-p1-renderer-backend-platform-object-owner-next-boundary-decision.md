# P1 Renderer backend platform object owner next-boundary decision

日期：2026-05-04

状态：docs-only next-boundary decision

## Scope

本轮只评估 `CjguiInternalRendererNoPlatformObjectReadiness` 是否已经足够作为当前 no-platform-object endpoint，并决定下一步是否先做 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 platform object、native handle、raw pointer，不接 Metal / AppKit / backend implementation。

## Inputs Read

- [runtime_renderer_backend_platform_object.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object.cj)
- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)

## Endpoint Assessment

`CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()` 已足够作为当前 no-platform-object endpoint。

理由：

- Owner file 已存在于 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object.cj`。
- Default draft 只消费 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`。
- Endpoint truth 已覆盖 backend platform object owner intent / native resource ownership policy / lifecycle teardown policy / confinement failure policy / no-platform-object readiness value facts。
- Open path 从 no-backend-ready endpoint 出发，形成 owner-local native resource vocabulary、future lifecycle teardown order facts、confinement failure / degraded no-draw facts，并封住 no platform object / no backend object / no native resource token / no pointer-like resource。
- Defer path 保持 defer，不伪造 platform object readiness。
- Blocked / inconsistent path fail-closed blocked。
- Closure 已记录 build / smoke / source scan / forbidden path scan / public declaration scan 与 GitNexus detect fallback，证明该 endpoint 是 internal value boundary，不是 platform object permission boundary。

## Boundary Meaning

当前 endpoint 只代表：

- backend platform object owner intent value facts。
- native resource ownership policy value facts。
- lifecycle teardown policy value facts。
- confinement failure policy value facts。
- no-platform-object readiness value facts。

当前 endpoint 明确不是：

- platform object permission。
- native handle permission。
- raw pointer permission。
- Metal device permission。
- backend implementation permission。
- render permission。
- GPU submission permission。
- command buffer commit permission。
- renderer state write permission。
- public API permission。
- platform object receipt / record / publication。
- native-handle readiness wrapper。
- backend implementation wrapper。
- Metal device readiness wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

## Candidate Comparison

### A. P1 internal Renderer backend platform object owner manifest stabilization bundle implementation

推荐为唯一 next opening。

理由：

- `CjguiInternalRendererNoPlatformObjectReadiness` 已经足够作为当前 no-platform-object endpoint。
- 下一步应固定 `runtime_renderer_backend_platform_object.cj` 的 owner / truth / canonical endpoint / stop-line，而不是继续包一层 tail wrapper。
- Manifest 可以把 owner file、canonical endpoint、default draft、唯一 runtime input、current truth、Same-shape Boundary Brake 与 future platform implementation stop-line 写清楚。
- 下一步仍必须 docs-only，不得创建 platform object、native handle、raw pointer、`MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不得修改 bridge / smoke / harness，不得 GPU submission、render execution、renderer state write 或 public API。

### B. Metal device-layer owner preflight

暂缓。

Device / layer ownership 必须晚于 platform object owner manifest。否则会跳过 native resource ownership / teardown / confinement vocabulary，直接靠近 `MTLDevice` / `CAMetalLayer` implementation。

### C. No-draw backend shell preflight

暂缓。

No-draw shell 需要 platform object absence、teardown、failure / no-draw facts 先 manifest-stabilized。当前直接进入 shell preflight 容易退化成 backend shell wrapper。

### D. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 必须晚于 platform object owner manifest 和后续 device / layer owner preflight。当前还没有真实 platform object owner permission。

### E. Backend platform object owner hardening

仅在发现不足时选择。

当前 value boundary closure 未发现 native resource ownership / lifecycle teardown / confinement failure 表达不足；所以本轮不选择 hardening。

### F. Platform object receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererNoPlatformObjectReadiness` 做成同构 tail wrapper，缺少新的 owner truth、consumer、lifecycle 或 implementation permission evidence。

### G. Native-handle readiness wrapper

拒绝。

当前 endpoint 明确没有 native handle / raw pointer，也不授予 handle readiness。

### H. Backend implementation wrapper

拒绝。

Backend platform object owner facts 不是 backend implementation permission。

### I. Metal device readiness wrapper

拒绝。

Platform object owner 不等于 `MTLDevice` owner，也不等于 `CAMetalLayer` owner。

### J. GPU-submission wrapper / render-permission wrapper

拒绝。

当前 endpoint 继续 no-submit / no-render；不得从 no-platform-object facts 推导 GPU submission 或 render permission。

### K. Direct platform object / native handle / backend / Metal / AppKit implementation

拒绝。

本 decision 不批准真实 implementation。

### L. Public API / C ABI expansion

拒绝。

public allowlist 仍只能保持 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### M. Consolidation

暂缓。

仅在明确 duplicate / low-value helper / self-wrapping evidence 出现时选择。当前没有这类 evidence；当前需要 manifest stabilization，不是 consolidation。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 decision 生效。

`CjguiInternalRendererNoPlatformObjectReadiness` 不再继续包装成 tail wrapper。当前 endpoint 只代表 backend platform object owner intent / native resource ownership policy / lifecycle teardown policy / confinement failure policy / no-platform-object readiness value facts。

不得把它包装成：

- platform object receipt / record / publication。
- native-handle readiness wrapper。
- backend implementation wrapper。
- Metal device readiness wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- scheduler / frame-pacing readiness wrapper。
- public API / public C ABI wrapper。

若未来靠近 Metal device-layer owner、no-draw backend shell、command queue / drawable real lifecycle、platform object creation、native handle、bridge / smoke / harness changes、GPU submission、render execution、renderer state write 或 public API，必须先做 docs-only preflight，并提供 reference pack / owner manifest evidence。

## Stop-line

继续禁止：

- no `.cj` modifications in this docs-only round。
- no platform object creation。
- no backend object creation。
- no native handle / raw pointer。
- no real retain / release / destroy FFI call。
- no bridge / smoke / harness / native entry modification。
- no `MTLDevice` / `CAMetalLayer` creation or ownership。
- no command queue / drawable / command buffer / render pass / encoder / pipeline state creation。
- no command buffer commit。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` touch。
- no diagnostics / event bus / observer / telemetry / public diagnostics。
- no public API / public C ABI expansion。

## Decision

`CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()` 已足够作为当前 no-platform-object endpoint。

唯一 next opening：

`P1 internal Renderer backend platform object owner manifest stabilization bundle implementation`

下一轮仍必须 docs-only，固定 `runtime_renderer_backend_platform_object.cj` owner / truth / canonical endpoint / stop-line；不得创建 platform object、native handle、raw pointer、`MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不得修改 bridge / smoke / harness，不得 GPU submission、render execution、renderer state write 或 public API。

## Downstream Backend Platform Object Owner Manifest Stabilization

Renderer backend platform object owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md)

该 manifest stabilization 固定 `runtime_renderer_backend_platform_object.cj` owner / truth / canonical endpoint / stop-line。`CjguiInternalRendererNoPlatformObjectReadiness` 继续只代表 backend platform object owner intent / native resource ownership policy / lifecycle teardown policy / confinement failure policy / no-platform-object readiness value facts，不代表 platform object permission、native handle permission、Metal device permission、backend implementation permission、render permission、GPU submission permission 或 public API permission。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner preflight decision`
