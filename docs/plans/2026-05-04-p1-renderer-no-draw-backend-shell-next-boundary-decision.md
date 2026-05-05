# P1 Renderer no-draw backend shell next-boundary decision

日期：2026-05-04

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoBackendShellReadiness` 是否已经足够作为当前 no-backend-shell endpoint，并决定下一步是否先做 manifest stabilization，还是进入 command queue / drawable real lifecycle、real platform object implementation 或 command buffer commit / GPU submission 相关 preflight。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 backend shell object / backend object / platform object / native handle / raw pointer，不接 `MTLDevice` / `CAMetalLayer`，不接 Objective-C / Metal / AppKit / FFI，不创建 command queue / drawable / command buffer / render pass / encoder / pipeline state，不 commit / present / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_no_draw_backend_shell.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj)
- [2026-05-04-p1-internal-renderer-no-draw-backend-shell-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-no-draw-backend-shell-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md)
- [2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)

## Decision

`CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()` 已足够作为当前 no-backend-shell endpoint。

下一步选择：

`P1 internal Renderer no-draw backend shell manifest stabilization bundle implementation`

下一轮仍必须 docs-only。目标是固定 `runtime_renderer_no_draw_backend_shell.cj` 的 owner / truth / canonical endpoint / stop-line，并封账 no-backend-shell endpoint；不得新增 runtime code，不得创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder 或 pipeline state，不得调用 FFI / Objective-C / Metal / AppKit API，不得 commit / present / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

## Endpoint Sufficiency

`CjguiInternalRendererNoBackendShellReadiness` 已覆盖当前 no-draw backend shell value boundary 所需的 endpoint truth：

- preserves upstream `CjguiInternalRendererNoMetalDeviceLayerReadiness` through shell intent / lifecycle / no-draw execution gate / teardown policy。
- seals no-backend-shell readiness as value facts。
- carries explicit no backend shell object / backend object / platform object facts。
- carries explicit no resource token / pointer-like resource facts。
- carries explicit no device / layer / queue / drawable / command buffer / render pass / encoder / pipeline state facts。
- carries explicit no command buffer commit / drawable present / GPU submission / render execution facts。
- carries explicit no renderer state mutation / bridge-smoke-harness-entry change / external API surface facts。
- carries explicit anti-wrapper facts：no backend-shell-ready permission、no backend implementation wrapper、no GPU-submission wrapper、no render-permission wrapper、no receipt / record / publication、no thin wrapper。

因此当前 endpoint 已能表达 no-draw backend shell intent / backend shell lifecycle policy / no-draw execution gate / shell teardown policy / no-backend-shell readiness facts，不需要再新增 no-draw backend shell receipt、record、publication 或 readiness tail wrapper。

## Candidate Comparison

### A. P1 internal Renderer no-draw backend shell manifest stabilization bundle implementation

推荐。

理由：value boundary closure 已证明 `CjguiInternalRendererNoBackendShellReadiness` 是当前 canonical endpoint。下一步应固定 owner file、current truth、default draft、open / defer / blocked fail-closed path、stop-line 和 Same-shape Boundary Brake，而不是继续向真实 backend implementation 靠近。

### B. Command queue / drawable real lifecycle preflight

暂缓。

Command queue / drawable real lifecycle 仍应晚于 no-draw backend shell manifest。当前 no-backend-shell endpoint 不授予 command queue permission、drawable acquisition permission、command buffer creation / commit permission、GPU submission permission 或 render permission。

### C. Real platform object implementation preflight

暂缓。

Backend platform object owner manifest 只封账 no-platform-object value facts；no-draw backend shell endpoint 也不授予 platform object creation、native handle、raw pointer 或 real lifecycle implementation permission。真实 platform object implementation 必须晚于 no-draw shell manifest 并重新评估 owner / teardown / failure / bridge confinement。

### D. Command buffer commit / GPU submission preflight

暂缓。

该方向仍过早。当前 endpoint 明确 no command buffer commit、no drawable present、no GPU submission、no render execution，且没有 command queue / drawable real lifecycle owner。

### E. No-draw backend shell receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererNoBackendShellReadiness` 换名包装成同构 tail，缺少新增 lifecycle / no-draw / teardown / failure 语义。

### F. Backend-shell-ready permission wrapper

拒绝。

`NoBackendShellReadiness` 不是 backend shell permission、backend-ready permission、backend implementation permission 或 runtime backend shell object permission。

### G. Backend implementation wrapper

拒绝。

当前没有 backend shell object、backend object、platform object、native handle / raw pointer、Metal / AppKit / Objective-C / FFI implementation、bridge ownership ABI 或 real backend lifecycle owner truth。

### H. GPU-submission wrapper

拒绝。

当前 no-draw execution gate 明确 no-submit / no-render。GPU submission / command buffer commit 必须等真实 command queue / drawable / command buffer owner evidence 后再 docs-only preflight。

### I. Render-permission wrapper

拒绝。

No-backend-shell endpoint 不是 render permission、draw permission、render execution permission、renderer state write permission 或 public API permission。

### J. Public API / C ABI expansion

拒绝。

Public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`；本 branch 不开放 public diagnostics、public runtime API 或 public C ABI。

### K. Consolidation

暂缓。

仅在明确 duplicate / low-value / self-wrapping evidence 出现时选择。当前 evidence 指向 manifest stabilization，而不是 consolidation。

## Same-shape Boundary Brake

`CjguiInternalRendererNoBackendShellReadiness` 不再继续包装成 tail wrapper。

当前 endpoint 只代表：

- no-draw backend shell intent value facts。
- backend shell lifecycle policy value facts。
- no-draw execution gate value facts。
- shell teardown policy value facts。
- no-backend-shell readiness value facts。

它不是：

- backend shell permission。
- backend implementation permission。
- backend object permission。
- platform object permission。
- native handle / raw pointer permission。
- `MTLDevice` / `CAMetalLayer` permission。
- command queue / drawable permission。
- command buffer creation / commit permission。
- GPU submission permission。
- render permission。
- renderer state write permission。
- diagnostics / event bus / observer / telemetry permission。
- public API / public C ABI permission。

继续新增 receipt / record / publication、backend-shell-ready wrapper、backend implementation wrapper、GPU-submission wrapper 或 render-permission wrapper 会退化为 same-shape tail wrapping，必须拒绝。

## Downstream Stop-line

下一轮 manifest stabilization 继续禁止：

- no `.cj` modifications。
- no backend shell object creation。
- no backend object creation。
- no platform object creation。
- no native handle。
- no raw pointer。
- no `MTLDevice` / `CAMetalLayer` creation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation / commit。
- no render pass / encoder / pipeline state creation。
- no FFI / Objective-C / Metal / AppKit API call。
- no bridge / smoke / harness / native entry modification。
- no drawable present。
- no GPU submission。
- no render execution。
- no renderer state write。
- no diagnostics output / telemetry / observer / event bus。
- no public API / public C ABI expansion。

## Downstream Manifest Stabilization

[No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) 与 [manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-no-draw-backend-shell-manifest-stabilization-closure-review.md) 已完成本 decision 推荐的 docs-only manifest 封账。

Manifest 固定：

- owner file：`runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj`
- canonical endpoint：`CjguiInternalRendererNoBackendShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`
- current truth：no-draw backend shell intent / backend shell lifecycle policy / no-draw execution gate / shell teardown policy / no-backend-shell readiness value facts

Downstream next opening 改为：

`P1 internal Renderer command queue / drawable real lifecycle preflight decision`

该 opening 仍必须 docs-only，不得创建 command queue、drawable、command buffer、render pass、encoder、pipeline state、backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`，不得调用 FFI / Objective-C / Metal / AppKit API，不得 commit / present / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

## Unique Next Opening

`P1 internal Renderer command queue / drawable real lifecycle preflight decision`
