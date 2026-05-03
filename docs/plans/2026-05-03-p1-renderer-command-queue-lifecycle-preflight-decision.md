# P1 Renderer command queue lifecycle preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Purpose

本 preflight 基于 platform resource owner manifest 与 backend / Metal reference pack，评估是否可以打开 command queue lifecycle runway。

本轮只做 decision，不批准创建 command queue，不批准创建任何 platform object，不修改 `.cj`，不运行 build / smoke。

Upstream references：

- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md)

## Current Anchor

Current platform resource owner endpoint：

- `CjguiInternalRendererNoPlatformResourceReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`

Current owner file：

- `runtime/cjgui/src/runtime_renderer_platform_resource.cj`

当前 `CjguiInternalRendererNoPlatformResourceReadiness` 已封账为 no-platform-resource endpoint。它不是 backend readiness、platform resource permission、command queue permission、drawable acquisition permission、command buffer permission、render permission 或 renderer state write。

Command queue lifecycle preflight 若继续推进，必须把这个 endpoint 作为唯一 runtime input。Backend / Metal reference pack 与 platform resource owner manifest 只能作为 docs evidence，不应成为 runtime input type。

## Reference Evidence

Reference pack 支撑 command queue lifecycle runway 的 evidence：

- Apple Metal command structure 资料固定 `MTLDevice` 是创建 command queue / buffers / textures 等 device-specific objects 的根。
- `MTLCommandQueue` 创建 command buffers，并组织 command buffers 的执行顺序。
- `MTLCommandBuffer` 承载 encoded commands，最终被 commit 到 GPU；commit 后不可复用。
- Command encoder 将 render / compute / blit commands 追加进 command buffer，因此 command queue lifecycle 不能等同于 command buffer lifecycle、render pass lifecycle 或 render execution。
- Command buffer completion / presentation callback、resource retention、failure status 都属于 future backend-local lifecycle，不能反向污染 core packet。
- `CAMetalLayer` / drawable acquisition 是 separate late-bound lifecycle；command queue owner truth 不应提前获取 drawable。
- Frame pacing 可能来自 `MTKView` draw loop、AppKit display link、`CADisplayLink`、`CVDisplayLink` 或 future scheduler owner；command queue readiness 不能推导 frame callback readiness。

这些 evidence 足以证明 command queue lifecycle 有独立 owner / ownership / creation guard / lifetime / no-command-queue 语义，可以打开 value boundary runway。

## Decision

允许打开 command queue lifecycle runway，但下一步也只能是 internal value boundary，不是真实 command queue。

下一阶段选择：

`P1 internal Renderer command queue lifecycle value boundary bundle implementation`

建议下一步 owner：

- `runtime/cjgui/src/runtime_renderer_command_queue.cj`

该 owner 必须只表达 value facts，不创建 `MTLCommandQueue`，不创建 `MTLDevice`，不创建 drawable，不创建 command buffer，不创建 render pass / encoder，不提交 GPU work。

## Runtime Input Decision

下一轮 runtime owner 的输入应只消费：

- `CjguiInternalRendererNoPlatformResourceReadiness`

理由：

- platform resource owner manifest 已把 no-platform-resource endpoint 封账为 command queue 前的 canonical runtime anchor。
- Reference pack 是 docs evidence，不是 runtime fact。
- 不应回退消费 `CjguiInternalRendererPacketOrderingHardeningResult`，否则会绕过 platform resource owner truth。
- 不应复用旧 `runtime_renderer_handoff.cj` 或任何 receipt / record / publication 语义。

## Output Truth Shape

下一轮如果实现，只允许输出 internal value facts：

- command queue lifecycle intent。
- queue ownership policy。
- queue creation guard。
- queue lifetime policy。
- no-command-queue readiness。

这些 facts 必须明确：

- 当前没有 `MTLCommandQueue`。
- 当前没有 `MTLDevice`。
- 当前没有 `CAMetalLayer`。
- 当前没有 drawable。
- 当前没有 command buffer。
- 当前没有 render pass / encoder。
- 当前没有 native handle / raw pointer。
- 当前没有 backend object。
- 当前没有 render permission。

## Dehydrated Facts

可脱水表达的 facts：

- queue owner identity。
- lifetime phase。
- creation guard。
- shutdown / rollback policy。
- frame pacing relationship。

这些 facts 只能是 value facts。它们不得携带 `MTLCommandQueue`、`MTLDevice`、`CAMetalLayer`、drawable、command buffer、native handle、raw pointer、callback、display link object 或 backend-local resource token。

## Never-in-core Objects

以下对象绝不能进入 core packet、renderer packet、command queue lifecycle value facts、Action / Queue / Runtime lower-level mutable facts 或 public surface：

- `MTLCommandQueue`。
- `MTLDevice`。
- `CAMetalLayer`。
- drawable。
- command buffer。
- native handle。
- raw pointer。

## Ownership Relation

Command queue 与相关 platform resources 的关系只能以 value facts 表达：

- device 是 future backend / platform owner 持有的根 resource。
- command queue 只能由 future backend owner 从 device 派生并持有。
- layer / drawable lifecycle 独立于 command queue lifecycle；drawable acquisition 仍必须 late-bound。
- command buffer 只能由 future command queue lifecycle 下游创建，是 per-frame / per-submit backend object。
- render pass / encoder 只能在 future command buffer lifecycle 内创建。

当前 command queue lifecycle runway 不能提前承诺 backend object layout、resource handle、handle table、platform callback、command buffer submission、drawable acquisition 或 render pass construction。

## No-draw / Failure / Rollback Path

No-draw / failure / rollback path 应以 value facts 表达：

- platform owner absent。
- device owner unavailable。
- command queue owner unavailable。
- command queue creation guard blocked。
- lifecycle phase not open。
- shutdown / rollback policy blocks queue use。
- frame pacing relationship incomplete。
- drawable lifecycle not opened。
- command buffer lifecycle not opened。
- backend execution intentionally not opened。
- no command buffer created。
- no render submitted。

这些 facts 不抛异常，不写日志，不回调 observer，不发布事件，不创建 backend object，不触发 render execution。

## Candidate Comparison

### A. P1 internal Renderer command queue lifecycle value boundary bundle implementation

选择。

理由：

- Reference pack 与 platform resource owner manifest 已证明 command queue lifecycle 有新增 owner / ownership / creation guard / lifetime / no-command-queue 语义。
- 下一轮可以只消费 `CjguiInternalRendererNoPlatformResourceReadiness`，输出 command queue lifecycle intent / queue ownership policy / queue creation guard / queue lifetime policy / no-command-queue readiness value facts。
- 它仍不创建 `MTLCommandQueue`、`MTLDevice`、drawable、command buffer、render pass、encoder、backend object 或 platform object。

### B. P1 internal Renderer command queue lifecycle reference hardening docs bundle implementation

暂缓。

当前 reference pack 已足够支持 value boundary。若后续发现 command queue ownership、lifetime、shutdown / rollback、frame pacing relationship 证据不足，再开 docs hardening。

### C. Drawable acquisition lifecycle preflight

暂缓。

通常应等 command queue lifecycle owner truth 后再开。Drawable acquisition 属于 `CAMetalLayer` / drawable pool late-bound lifecycle，不能由 command queue preflight 直接批准。

### D. Command buffer lifecycle preflight

暂缓。

必须等 command queue lifecycle owner truth 与 drawable acquisition owner truth 后再拆。Command buffer 生命周期太靠近 command submission 与 render execution。

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍可能变成 wrapper。等 command queue / drawable lifecycle 进一步拆清后再评估。

### F. Command queue / Metal implementation

拒绝。

### G. Command buffer / render execution / renderer state write

拒绝。

### H. Metal / AppKit / platform resource / native handle implementation

拒绝。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### J. Public surface expansion

拒绝。

Public allowlist remains only：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

### K. Receipt / record / publication

拒绝。

不得新增 command queue receipt / record / publication，也不得把 `CjguiInternalRendererNoPlatformResourceReadiness` 包成 command queue readiness wrapper。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 preflight 生效：

- 证明 command queue lifecycle 有新增 ownership / creation guard / lifetime / no-command-queue 语义。
- 不把 `CjguiInternalRendererNoPlatformResourceReadiness` 直接包成 command queue readiness wrapper。
- 不把 reference pack 变成 runtime readiness wrapper。
- 不新增 receipt / record / publication。
- 不批准 backend-readiness wrapper。

若下一轮选择 value boundary，仍必须禁止 `MTLCommandQueue` / command buffer / platform object implementation。

## Stop-line

继续禁止：

- no runtime code in this preflight round。
- no `.cj` modifications。
- no command queue creation。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no `MTLCommandQueue` / `MTLDevice` / `CAMetalLayer` creation。
- no drawable acquisition。
- no command buffer creation or submission。
- no render pass / render encoder creation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no receipt / record / publication wrapper。
- no backend-readiness wrapper。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Next Opening

`P1 internal Renderer command queue lifecycle value boundary bundle implementation`

下一轮允许新增 internal-only runtime owner file，但必须保持 no-command-queue / no-backend / no-render boundary。不得创建 `MTLCommandQueue`、`MTLDevice`、`CAMetalLayer`、drawable、command buffer、render pass、render encoder、native handle 或 raw pointer。

## Downstream Value Boundary Closure

Renderer command queue lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-value-boundary-closure-review.md)

新增 owner `runtime/cjgui/src/runtime_renderer_command_queue.cj` 只消费 `CjguiInternalRendererNoPlatformResourceReadiness`，canonical endpoint 是 `CjguiInternalRendererNoCommandQueueReadiness` / `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`。下一步进入 docs-only `P1 internal Renderer command queue lifecycle closure / next command queue decision`。

## Downstream Next-boundary Decision

Renderer command queue lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-command-queue-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoCommandQueueReadiness` 已足够作为当前 no-command-queue lifecycle endpoint，并选择 `P1 internal Renderer command queue lifecycle manifest stabilization bundle implementation` 作为唯一 next opening。

## Downstream Manifest Stabilization

Renderer command queue lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 封账 no-command-queue lifecycle endpoint。Drawable acquisition lifecycle 与 command buffer lifecycle 仍只能经 docs-only preflight 打开。
