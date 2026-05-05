# P1 Renderer no-draw backend shell preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮评估是否可以打开 no-draw backend shell runway。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 backend object / platform object / native handle / raw pointer，不创建 `MTLDevice` / `CAMetalLayer`，不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state，不调用 FFI / Objective-C / Metal / AppKit API，不 commit / present / submit GPU work，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-metal-device-layer-owner-manifest-stabilization-closure-review.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md)
- [2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

允许打开 no-draw backend shell runway。

下一步选择：

`P1 internal Renderer no-draw backend shell value boundary bundle implementation`

下一步仍只能是 internal value boundary，不是真实 backend shell implementation。它不得创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder 或 pipeline state；不得调用 FFI / Objective-C / Metal / AppKit API；不得修改 bridge、smoke、harness 或 native entry；不得 commit / present / submit GPU work；不得执行 render；不得写 renderer state；不得扩 public API / C ABI。

## Proposed Runtime Boundary

默认候选 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj`

建议唯一 runtime input：

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`

Docs evidence 可以引用 backend-readiness branch milestone、backend platform object owner manifest、Metal device-layer owner manifest、backend / Metal reference pack、real backend implementation preflight、real backend first-slice owner preflight、risk ledger 和 bridge smoke history，但不得作为多 runtime input，也不得把 `labs/macos_bridge_smoke` 的 Objective-C / Metal implementation 升格为 runtime truth。

允许 output truth 仅限：

- no-draw backend shell intent value facts。
- backend shell lifecycle policy value facts。
- no-draw execution gate value facts。
- shell teardown policy value facts。
- no-backend-shell-readiness value facts。

## Required Boundary Truth

下一轮 value boundary 必须明确：

- No-draw backend shell 只表达 future backend shell lifecycle intent，不创建 backend shell object。
- Backend shell lifecycle policy 只表达 future init / active / degraded / teardown lifecycle facts，不创建 backend object，不管理真实 platform lifecycle。
- No-draw execution gate 只表达 no-draw / no-submit / no-render admission facts，不执行 render，不提交 GPU work，不 commit command buffer，不 present drawable。
- Shell teardown policy 只表达 future teardown ordering / failure rollback / idempotent cleanup facts，不调用 retain / release / destroy FFI，不修改 bridge / smoke / harness。
- No-backend-shell readiness 不是 backend-ready permission、backend implementation permission、backend object permission、platform object permission、Metal object permission、GPU submission permission、render permission、renderer state write permission、diagnostics permission、public API permission 或 C ABI permission。
- Default draft 只消费 no-metal-device-layer endpoint，并 fail closed on blocked / inconsistent input。

## Reference Evidence

Evidence 足够选择 A：

- Metal device-layer owner manifest 已封账 `CjguiInternalRendererNoMetalDeviceLayerReadiness`，并固定 device selection、layer binding、scale-color-space 与 no-device / no-layer stop-line。No-draw backend shell 可以在该 endpoint 之后表达 backend shell lifecycle 与 no-draw fallback facts，而不触碰真实 Metal objects。
- Backend platform object owner manifest 已固定 native resource ownership / lifecycle teardown / confinement failure vocabulary，并继续禁止 platform object / native handle / raw pointer。No-draw shell 可引用这些 facts 作为 docs evidence，但不得创建 platform object。
- Backend-readiness branch milestone 已证明 packet truth 到 no-backend-ready tail 的 value chain 已封账；real backend implementation preflight 和 first-slice owner preflight 均要求先拆 owner / lifecycle / teardown / failure / smoke strategy，而不是直接实现 backend。
- Backend / Metal reference pack 固定 `MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state、completion / presentation / resource retention 都必须 future backend-local；no-draw shell 正好可以先表达 shell lifecycle / no-draw path，不进入 GPU object materialization。
- Risk ledger 固定 GPU resource lifecycle、FFI ownership、main-thread exclusivity、runloop overfitting、pixel hash illusion 与 foreign surface containment 是真实 implementation 风险；no-draw shell preflight 可以把这些风险留在 docs-only value facts 中，不提前创建资源。

Evidence 不足以直接实现：

- 还没有 runtime no-draw backend shell owner。
- 还没有正式 backend object / platform object / native handle representation。
- 还没有 bridge ownership ABI 或 handle table / generation table。
- 还没有 real backend shell init / active / teardown implementation permission。
- 还没有 command queue / drawable real lifecycle owner。
- 还没有 command buffer commit / GPU submission gate implementation permission。
- `labs/macos_bridge_smoke` 仍是 lab-only feasibility evidence，不能成为 runtime owner truth、public ABI、visual correctness truth 或 backend shell lifecycle implementation。

## Candidate Comparison

### A. P1 internal Renderer no-draw backend shell value boundary bundle implementation

推荐。

Evidence 足以新增 internal-only value facts owner。该 boundary 的新增语义是 shell lifecycle / no-draw execution gate / teardown / no-backend-shell-readiness，不是真实 backend shell implementation。

### B. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 应晚于 no-draw shell owner manifest，或至少等 no-draw backend shell owner truth 固定后再评估。当前仍没有 backend shell endpoint、command queue real owner、drawable real owner 或 GPU submission permission。

### C. Backend shell reference hardening docs

暂缓。

现有 milestone、platform object manifest、Metal device-layer manifest、reference pack 和 risk ledger 足以支撑 value boundary。若下一轮实现发现 lifecycle / no-draw / teardown evidence 表达不足，再选择 docs hardening。

### D. Real platform object implementation preflight

暂缓。

Platform object implementation 仍太靠近真实 native resource creation。应先固定 no-draw backend shell value facts，再重新评估 real platform object implementation。

### E. Direct no-draw backend implementation

拒绝。

本轮不批准真实 backend shell object、backend object、platform object 或 runtime backend implementation。

### F. Direct Metal / AppKit / Objective-C implementation

拒绝。

不得调用 FFI / Objective-C / Metal / AppKit API，不得修改 bridge、smoke、harness 或 native entry。

### G. Command buffer commit / GPU submission / render execution

拒绝。

Current branch 仍然 no-submit / no-render-execution。

### H. Renderer state write

拒绝。

Current branch 仍然 no-state-write。

### I. Public API / C ABI expansion

拒绝。

Public allowlist 不变；bridge smoke 的 experimental C ABI 不能升级为 runtime public surface。

### J. Receipt / record / publication / backend-ready permission wrapper

拒绝。

这些会把 no-metal-device-layer endpoint 换名包装，缺少 shell lifecycle / no-draw execution gate / teardown / no-backend-shell-readiness 新语义。

### K. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前需要的是 no-draw backend shell value boundary，不是 consolidation。

## Same-shape Boundary Brake

本轮不能把 `CjguiInternalRendererNoMetalDeviceLayerReadiness` 包成：

- no-draw backend shell receipt / record / publication。
- backend-shell-ready permission wrapper。
- backend implementation wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- public API / C ABI wrapper。

若下一轮选择 A，必须证明新增的是 shell lifecycle / no-draw execution gate / teardown / no-backend-shell-readiness 语义，而不是 no-metal-device-layer tail wrapper。

## Future Stop-line

下一轮即使实现 value boundary，也继续禁止：

- no backend shell object creation。
- no backend object creation。
- no platform object creation。
- no native handle。
- no raw pointer。
- no `MTLDevice` creation。
- no `CAMetalLayer` creation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation。
- no render pass creation。
- no encoder creation。
- no pipeline state creation。
- no bridge / smoke / harness / native entry modification。
- no FFI / Objective-C / Metal / AppKit API call。
- no command buffer commit。
- no drawable present。
- no GPU submission。
- no render execution。
- no renderer state write。
- no public API。
- no public C ABI expansion。
- no diagnostics output / telemetry / observer / event bus。

## Downstream Update

[No-draw backend shell value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-no-draw-backend-shell-value-boundary-closure-review.md) 已完成下一步 opening：新增 `runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj`，只消费 `CjguiInternalRendererNoMetalDeviceLayerReadiness`，canonical endpoint 是 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`。

该 closure 证明新增的是 shell lifecycle / no-draw execution gate / teardown / no-backend-shell-readiness 语义，不是 no-metal-device-layer receipt / record / publication、backend-shell-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper 或 render-permission wrapper。下一步转为 docs-only `P1 internal Renderer no-draw backend shell closure / next no-draw backend decision`。

[No-draw backend shell next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()` 足够作为当前 no-backend-shell endpoint，并选择下一步先做 manifest stabilization，而不是 command queue / drawable real lifecycle、real platform object implementation、command buffer commit / GPU submission 或 wrapper。

[No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) 与 [manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-no-draw-backend-shell-manifest-stabilization-closure-review.md) 已固定 `runtime_renderer_no_draw_backend_shell.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`。下一步转为 docs-only `P1 internal Renderer command queue / drawable real lifecycle preflight decision`，不得创建 command queue、drawable、command buffer、render pass、encoder、pipeline state、backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`，不得 GPU submission、render execution、renderer state write 或 public API / C ABI。

## Unique Next Opening

`P1 internal Renderer command queue / drawable real lifecycle preflight decision`

下一轮必须 docs-only，评估 command queue / drawable real lifecycle owner、queue / drawable acquisition relation、failure / no-draw fallback、GPU submission gate 与 backend shell relation。继续禁止真实 backend shell implementation、backend object、platform object、native handle、raw pointer、`MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state、FFI / Objective-C / Metal / AppKit API、GPU submission、render execution、renderer state write、public API / C ABI。
