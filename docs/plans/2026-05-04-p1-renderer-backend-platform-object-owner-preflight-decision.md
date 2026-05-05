# P1 Renderer backend platform object owner preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮评估是否可以打开 backend platform object owner runway。

本轮不修改 `.cj`，不新建 runtime owner，不运行 build / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 backend object、platform object、native handle、raw pointer，不创建 `MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder 或 pipeline state，不 commit / present / submit GPU work，不写 renderer state，不接 public API / C ABI。

## Inputs Read

- [2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [cangjie-1.1-owner-tooling-ffi-capability-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/cangjie-1.1-owner-tooling-ffi-capability-intake.md)

## Decision

允许打开 backend platform object owner runway。

下一步选择：

`P1 internal Renderer backend platform object owner value boundary bundle implementation`

下一步仍只能是 internal value boundary，不是真实 platform object creation。它不得创建 backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不得定义真实 retain / release FFI 调用，不得修改 bridge、smoke 或 harness，不得 GPU submission、render execution、renderer state write、public API 或 C ABI expansion。

## Proposed Runtime Boundary

默认候选 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object.cj`

建议唯一 runtime input：

- `CjguiInternalRendererNoBackendReadyReadiness`
- `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`

Docs evidence 可以引用 bridge preflight / cleanup closure / Metal reference pack / platform resource owner manifest / Cangjie owner tooling FFI intake，但不得作为多 runtime input。

允许 output truth 仅限：

- backend platform object owner intent value facts。
- native resource ownership policy value facts。
- lifecycle teardown policy value facts。
- confinement failure policy value facts。
- no-platform-object-readiness value facts。

## Required Boundary Truth

下一轮 value boundary 必须明确：

- platform object owner 不等于 `MTLDevice` owner。
- platform object owner 不等于 `CAMetalLayer` owner。
- platform object owner 不等于 backend implementation。
- no-platform-object-readiness 不是 platform object permission、native handle permission、backend-ready permission、Metal device permission、render permission、GPU submission permission 或 renderer state write permission。
- native resource ownership policy 只表达 future ownership vocabulary，不创建 native handle / raw pointer。
- lifecycle teardown policy 只表达 future teardown ordering facts，不定义真实 retain / release FFI 调用。
- confinement failure policy 只表达 failure / degraded / no-draw containment facts，不观察真实 native failure。
- Default draft 只消费 no-backend-ready endpoint，并 fail closed on blocked / inconsistent input。

## Evidence Sufficiency

Evidence 足够选择 A：

- Real backend first-slice decision 已判定 platform object / native resource ownership 是真实 backend 第一刀。
- Backend-readiness manifest 提供 no-backend-ready endpoint、platform lifecycle gate、execution admission gate 与 state visibility gate，但明确不授权 platform object creation。
- Backend / Metal reference pack 固定 future Metal / AppKit resources 必须 backend-local，且 `MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state 不得进入 core packet truth。
- Platform resource owner manifest 已有 resource confinement policy / no-platform-resource readiness，但仍只是 value facts，缺少真实 platform object owner vocabulary。
- Bridge boundary preflight 已记录 handle lifecycle、main-thread owner、narrow bridge shape、error categories、capability query、teardown ordering 和 verification strategy。
- Bridge cleanup closure 证明 lab bridge 内部持有和销毁 native objects 可行，但也明确没有正式 GUI runtime、handle table、generation table、message queue 或 long-term ABI。
- Cangjie 1.1 owner / FFI intake 确认 C FFI 是可用基础，但没有 Rust 级线性 owner / move-only resource / borrow checker；`CPointer`、platform handle 和 native object 必须封在 owner-local API 后，不能暴露成 high-level truth。
- Risk ledger 明确 GPU resource lifecycle、FFI ownership、main-thread exclusivity、runloop overfitting、pixel hash illusion 和 foreign surface containment 是 first-slice 风险。

Evidence 不足以直接实现：

- 还没有正式 runtime platform object owner。
- 还没有正式 handle table / generation table。
- 还没有 native retain / release / destroy ABI shape。
- 还没有 real no-draw backend shell。
- 还没有 device / layer ownership truth。
- 还没有 command queue / drawable / command buffer real lifecycle truth。
- `labs/macos_bridge_smoke` 仍是 lab-only feasibility evidence，不能成为 runtime truth。

## Candidate Comparison

### A. P1 internal Renderer backend platform object owner value boundary bundle implementation

推荐。

Evidence 足以新增 internal-only value facts owner。该 boundary 的新增语义是 native resource ownership / lifecycle teardown / confinement failure / no-platform-object-readiness，不是 real platform object creation。

### B. Metal device-layer owner preflight

暂缓。

必须晚于 platform object ownership vocabulary。否则会把具体 `MTLDevice` / `CAMetalLayer` owner 放在更基础的 native resource confinement 之前。

### C. No-draw backend shell preflight

暂缓。

通常应等 backend platform object owner manifest 后再拆。No-draw shell 需要明确 platform object absence、teardown、failure/no-draw facts，否则容易退化成 no-backend-ready wrapper。

### D. FFI handle lifecycle reference hardening docs

暂缓。

现有 bridge preflight、cleanup closure、risk ledger 和 Cangjie FFI intake 已足以支撑 value boundary。若下一轮实现发现 create / retain / release / teardown / failure 表达不足，再选择 docs hardening。

### E. Direct platform object / native handle implementation

拒绝。

本轮不批准创建 platform object、native handle 或 raw pointer。

### F. Direct Metal device / CAMetalLayer implementation

拒绝。

Platform object owner 不等于 `MTLDevice` / `CAMetalLayer` owner。

### G. Command queue / drawable / command buffer implementation

拒绝。

这些必须晚于 platform object owner、device-layer owner 和 real lifecycle preflight。

### H. GPU submission / render execution

拒绝。

Current branch 仍然 no-submit / no-render-execution。

### I. Renderer state write

拒绝。

Current branch 仍然 no-state-write。

### J. Public API / C ABI expansion

拒绝。

Public allowlist 不变；bridge smoke 的 experimental C ABI 不能升级为 runtime public surface。

### K. Receipt / record / publication / backend-ready permission wrapper

拒绝。

这些会把 no-backend-ready endpoint 换名包装，缺少 native resource ownership / lifecycle teardown / confinement failure 新语义。

### L. Consolidation

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前需要的是 value boundary，不是 consolidation。

## Same-shape Boundary Brake

本轮不能把 `CjguiInternalRendererNoBackendReadyReadiness` 包成：

- platform object receipt / record / publication。
- native-handle readiness wrapper。
- backend implementation wrapper。
- Metal device readiness wrapper。
- backend-ready permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

若下一轮选择 A，必须证明新增的是 native resource ownership / lifecycle teardown / confinement failure / no-platform-object-readiness 语义。

## Future Stop-line

下一轮即使实现 value boundary，也继续禁止：

- no platform object creation。
- no backend object creation。
- no native handle。
- no raw pointer。
- no bridge / smoke / harness modification。
- no `MTLDevice`。
- no `CAMetalLayer`。
- no command queue。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no command buffer commit。
- no drawable present。
- no GPU submission。
- no render execution。
- no renderer state write。
- no public API。
- no public C ABI expansion。
- no diagnostics output。
- no telemetry。
- no observer。
- no event bus。

## Downstream

Unique next opening:

`P1 internal Renderer backend platform object owner value boundary bundle implementation`

下一轮允许新增 internal-only runtime owner file，但必须严格保持 no-platform-object / no-native-handle / no-render 边界。

## Downstream Backend Platform Object Owner Value Boundary

Renderer backend platform object owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md)

该 implementation 新增 `runtime/cjgui/src/runtime_renderer_backend_platform_object.cj`，只消费 `CjguiInternalRendererNoBackendReadyReadiness`，canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`。它只形成 backend platform object owner intent / native resource ownership policy / lifecycle teardown policy / confinement failure policy / no-platform-object-readiness value facts，不创建 platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state，不定义真实 retain / release / destroy FFI 调用，不改 bridge / smoke / harness，不 GPU submission、不 render execution、不写 renderer state、不扩 public API / C ABI。

唯一 next opening：

`P1 internal Renderer backend platform object owner closure / next platform object decision`

## Downstream Backend Platform Object Owner Next-boundary Decision

Renderer backend platform object owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()` 已足够作为当前 no-platform-object endpoint，并选择下一步先做 manifest stabilization。

Same-shape Boundary Brake 继续刹住 `NoPlatformObjectReadiness`：不得把它包成 platform object receipt / record / publication、native-handle readiness wrapper、backend implementation wrapper、Metal device readiness wrapper、GPU-submission wrapper 或 render-permission wrapper。

唯一 next opening：

`P1 internal Renderer backend platform object owner manifest stabilization bundle implementation`

## Downstream Backend Platform Object Owner Manifest Stabilization

Renderer backend platform object owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md)

该 manifest stabilization 固定 `runtime_renderer_backend_platform_object.cj` owner / truth / canonical endpoint / stop-line，并继续拒绝 platform object receipt / record / publication、native-handle readiness wrapper、backend implementation wrapper、Metal device readiness wrapper、GPU-submission wrapper、render-permission wrapper、direct platform object / native handle implementation、Metal / AppKit implementation、renderer state write 或 public API / C ABI expansion。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner preflight decision`
