# P1 Renderer backend object owner preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮 docs-only 基于 backend-readiness revisit preflight、render execution no-op manifest 与 backend / Metal reference pack，评估是否可以打开 backend object owner runway。

本轮不修改 `.cj`，不实现 backend / Metal / AppKit / CAMetalLayer / backend object / platform resource / command buffer / render execution / renderer state write，不运行 build / smoke。

## Read Inputs

- [2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Preflight Decision

允许打开 backend object owner runway，但下一步也只能是 internal value boundary，不是真实 backend object。

选择下一阶段：

`P1 internal Renderer backend object owner value boundary bundle implementation`

下一步候选 owner 可以新建 `runtime/cjgui/src/runtime_renderer_backend_object.cj` 或等价 internal-only owner。它必须只消费 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`，不能回退到 platform resource、command queue、drawable、command buffer、render pass、encoder、draw call、pipeline state 或旧 handoff receipt 作为 runtime input。

Output truth 只能是：

- backend object owner intent value facts。
- backend lifecycle ownership policy value facts。
- backend acceptance gate value facts。
- platform confinement guard value facts。
- no-backend-object readiness value facts。

Backend object owner readiness 明确不等于 backend object creation、backend implementation、Metal / AppKit implementation、platform resource permission、command buffer permission、GPU submission permission、render execution permission、renderer state write permission 或 public surface expansion。

## Why Evidence Is Sufficient For A Value Boundary

Backend-readiness revisit 已确认 lifecycle evidence 充足但 backend object owner truth 缺失。本轮补足的是 preflight 层面的 owner-truth shape：backend object owner 可以作为 future backend-local aggregate owner，负责把已封账的 platform / queue / drawable / command buffer / render pass / encoder / draw call / pipeline / no-render-execution facts 收束成 owner intent、lifecycle policy、acceptance gate 与 platform confinement guard。

该新增语义不是 `CjguiInternalRendererNoRenderExecutionReadiness` 的 receipt / record / publication，因为它必须回答：

- Future backend object owner 是谁。
- Future backend object 的 init / active / teardown / failure / rollback / no-render phases 如何作为 value facts 表达。
- Backend acceptance gate 如何判断 lifecycle coverage，而不授予 backend implementation permission。
- Platform confinement guard 如何说明 future platform resources 只能由 backend owner 持有。
- No-backend-object readiness 如何明确当前没有 backend object、platform object、native handle、command buffer commit、GPU submission 或 renderer state write。

## Relationship To Existing Endpoints

### Render execution no-op

[Render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 固定 `CjguiInternalRendererNoRenderExecutionReadiness`。Backend object owner value boundary 可以把它作为唯一 runtime input，读取 no-submit / completion observation / rollback-no-draw facts，但不得把它包装成 backend readiness。

### Platform resource owner

[Platform resource owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md) 固定 `CjguiInternalRendererNoPlatformResourceReadiness`。Backend object owner 与它的关系只能作为 policy relationship：future device / layer / command queue / drawable / command buffer / render pass / encoder 只能被 future backend/platform owner 持有，不能进入 core packet。

### Command queue lifecycle

[Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoCommandQueueReadiness`。Backend object owner 只能记录 future backend object 对 command queue lifecycle 的 ownership relation，不创建 command queue，不管理真实 queue lifetime。

### Drawable acquisition lifecycle

[Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoDrawableReadiness`。Backend object owner 只能表达 future backend-local drawable acquisition confinement、late acquisition relation、failure / no-draw fallback relation，不获取 drawable。

### Command buffer lifecycle

[Command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoCommandBufferReadiness`。Backend object owner 只能表达 future command buffer lifecycle confinement、single-use relation、commit prohibition relation，不创建或 commit command buffer。

### Render pass lifecycle

[Render pass lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoRenderPassReadiness`。Backend object owner 只能表达 future render pass descriptor / attachment confinement relation，不创建 descriptor、attachment、texture 或 encoder。

### Encoder lifecycle

[Encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoEncoderReadiness`。Backend object owner 只能表达 future encoding scope confinement and acceptance relation，不 begin / end encoding，不绑定 pipeline or resources。

### Draw call lifecycle

[Draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoDrawCallReadiness`。Backend object owner 只能 express draw-call lifecycle coverage relation and no-draw fallback relation，不发 draw command。

### Pipeline state lifecycle

[Pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md) 固定 `CjguiInternalRendererNoPipelineStateReadiness`。Backend object owner 只能 express future shader / descriptor / compatibility coverage relation，不加载 shader library / function，不创建 descriptor，不 compile / cache / bind pipeline。

## Forbidden Objects In Core

以下对象绝不能进入 core packet、backend object owner value facts 的 resource field、public API 或 C ABI：

- backend object。
- `MTLDevice`。
- `CAMetalLayer`。
- command queue。
- drawable。
- command buffer。
- render pass descriptor。
- render command encoder。
- pipeline state。
- shader library / function。
- texture / attachment object。
- native handle。
- raw pointer。
- GPU object。
- platform resource token。

这些名词只能作为 forbidden concept、future policy target 或 dehydrated relationship vocabulary 出现在 docs / string value facts 中，不得作为 runtime type、import、field ownership、function call、callback registration 或 resource handle。

## Backend Object Lifecycle Value Facts

如果下一轮实现 value boundary，backend object lifecycle 只能被表达为 dehydrated value facts：

- `init` phase：future construction intent and construction guard facts only，不创建 backend object。
- `active` phase：future ownership coverage / acceptance gate facts only，不持有 platform object。
- `teardown` phase：future shutdown guard and release-order facts only，不释放真实资源。
- `failure` phase：failure classification / backend-local no-backend facts only，不注册 callback、不写 log、不发 telemetry。
- `rollback` phase：rollback intent and no-draw fallback facts only，不 mutate renderer state。
- `no-render` path：no-submit / no-draw / no-backend-object readiness facts only，不执行 render。

Backend object owner value boundary 不能表达 real lifecycle management、resource retain / release、callback registration、platform bridge binding、command buffer commit、GPU submission、drawable presentation、renderer state write 或 public diagnostics。

## Reference Evidence

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 支撑本 preflight 的具体 evidence：

- `MTLDevice` 是创建 command queue / buffers / textures 等 device-specific objects 的根，应属于 future backend/platform owner。
- `MTLCommandQueue` 创建 command buffers，应属于 future backend owner，不进入 core packet。
- `MTLCommandBuffer` commit 后不可复用，completion / presentation / resource retention 是 backend-local lifecycle concern。
- `MTLRenderPassDescriptor` / attachments / encoders / draw calls 属于 backend-local render pass / encoding concern，不是 renderer packet truth。
- `CAMetalLayer` owns drawable pool，drawable acquisition must be late-bound and backend-local。
- Resize / scale / color / frame pacing can cross as dehydrated facts only。
- Frame pacing remains platform/backend owner policy question, not packet readiness。

该 evidence 支撑 A 的 value boundary，但不批准 backend implementation。

## Candidate Comparison

### A. P1 internal Renderer backend object owner value boundary bundle implementation

选择。

当前 evidence 已足以证明 backend object owner 有新增 owner / lifecycle / acceptance gate / platform confinement / no-backend-object 语义。下一轮仍只能新建 internal-only value owner，不创建 backend object，不创建 platform object，不提交 command buffer，不 GPU submission，不写 renderer state。

### B. P1 internal Renderer backend object owner reference hardening docs bundle implementation

暂缓。

Reference pack 与 lifecycle manifests 已足够支撑 owner-truth preflight。当前缺口不是官方链接不足，而是需要把 backend object owner value boundary 的 no-object shape 固定下来。

### C. Frame pacing owner preflight

暂缓。

Frame pacing owner 仍是 future question，但 backend object owner value boundary 可以先把 frame pacing 标记为 dehydrated relation / unresolved owner slot。若下一轮发现 backend object owner 无法表达 pacing relation，再拆 frame pacing owner preflight。

### D. Renderer state write preflight

暂缓。

Renderer state write 仍是 hard stop-line。通常应等 backend object owner truth 与 backend-readiness revisit 之后再评估，避免把 state write 误读为 backend object acceptance。

### E. Backend-readiness value boundary revisit

暂缓。

必须等 backend object owner truth 先形成 value facts 后，才能重新评估 backend-readiness value boundary。

### F. Backend / Metal implementation

拒绝。

### G. Platform object / native handle implementation

拒绝。

### H. Command buffer commit / GPU submission / render execution implementation

拒绝。

### I. Renderer state write implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

### L. Receipt / record / publication

拒绝。

Backend object owner value boundary 不能成为 backend-object receipt / record / publication，也不能成为 no-render-execution receipt / publication wrapper。

### M. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

本轮允许 A 的前提是：backend object owner value boundary 必须新增 owner / lifecycle / acceptance gate / platform confinement / no-backend-object readiness 语义。

明确拒绝：

- 把 `CjguiInternalRendererNoRenderExecutionReadiness` 直接包成 backend object readiness wrapper。
- backend object receipt / record / publication。
- backend-readiness wrapper。
- command-buffer-commit readiness wrapper。
- GPU-submission wrapper。
- renderer-state-write readiness wrapper。
- backend implementation。

若下一轮选择 A，仍必须禁止 backend object creation、platform object creation、native handle、raw pointer、command buffer commit、GPU submission、render execution 和 renderer state write。

## Decision

本轮批准打开 backend object owner runway，但只批准下一轮 internal value boundary。

唯一 next opening：

`P1 internal Renderer backend object owner value boundary bundle implementation`

下一轮若执行，默认 owner 为 `runtime/cjgui/src/runtime_renderer_backend_object.cj` 或等价 internal-only owner；只消费 `CjguiInternalRendererNoRenderExecutionReadiness`；只输出 backend object owner intent / backend lifecycle ownership policy / backend acceptance gate / platform confinement guard / no-backend-object readiness value facts。

下一轮仍不得创建 backend object、不得创建 platform object、不得引入 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer / render pass descriptor / encoder / pipeline state / native handle / raw pointer、不得 commit command buffer、不得 GPU submission、不得执行 render、不得写 renderer state、不得扩 public surface。

## Downstream Implementation Closure

Renderer backend object owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-backend-object-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-object-owner-value-boundary-closure-review.md)

该 implementation 新增 `runtime/cjgui/src/runtime_renderer_backend_object.cj`，只消费 `CjguiInternalRendererNoRenderExecutionReadiness`，并固定当前 endpoint 为 `CjguiInternalRendererNoBackendObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`。它只表达 backend object owner intent / backend lifecycle ownership policy / backend acceptance gate / platform confinement guard / no-backend-object readiness value facts；不批准 backend object creation、platform object creation、native handle、raw pointer、command buffer commit、GPU submission、render execution、renderer state write、frame pacing owner truth 或 backend-readiness final gate。

Renderer backend object owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererNoBackendObjectReadiness` 已足够作为当前 no-backend-object endpoint，并选择下一轮 `P1 internal Renderer backend object owner manifest stabilization bundle implementation`。Frame pacing owner preflight、renderer state write preflight 与 backend-readiness value boundary revisit 均暂缓到 manifest 后。

Renderer backend object owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-object-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-object-owner-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_backend_object.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoBackendObjectReadiness`。下一步只允许 docs-only `P1 internal Renderer frame pacing owner preflight decision`，不允许 backend-readiness wrapper、renderer-state-write readiness wrapper、frame-pacing readiness wrapper、backend implementation、platform object implementation、command buffer commit、GPU submission 或 render execution。

## Validation

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过；范围限定 project docs / README / tracker / runtime README，避开 `reference_repos/` 外部镜像噪音。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过，均能找到本 preflight decision 与唯一 next opening。
- Forbidden check：通过；tracked diff 未包含 `.cj` runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- Public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk `low`，changed_count `13`，changed_files `7`，affected_processes `[]`。
- 本轮 docs-only，未运行 `cjpm build`，未运行 smoke。
