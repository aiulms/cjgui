# P1 Renderer backend tail milestone manifest

日期：2026-05-02

状态：manifest stabilization

## Purpose

本 manifest 将 renderer backend no-render tail 封成 milestone，防止 handoff -> adapter -> contract -> capability -> selection -> binding 之后继续凭惯性新增同构 owner file。

本 manifest 不是为了文档空转。它固定：

- current owner chain。
- canonical tail endpoint。
- current truth。
- backend / render stop-line。
- milestone 后的下一阶段候选出口。

## Same-shape Boundary Brake

Same-shape Boundary Brake 已触发。近期 renderer backend tail 连续出现多个结构高度相似的 value boundary：

- 多个 owner file 行数接近。
- 每个 owner 都由 3-5 个 value type、对应 builders、default draft 组成。
- 每个 owner 都重复 open / defer / blocked / inconsistent fail-closed 分支。
- 每个 owner 都只消费上一层 readiness / receipt，并输出下一层 no-render readiness。
- 主要差异是 backend adapter、contract、capability、selection、binding 等名词替换。

这些边界已经把 future backend adapter runway 从 packet handoff 推进到 binding 前置事实，当前仍有审计价值；但继续直接实现 adapter lifecycle 将缺少新的 owner truth，容易成为同构 thin wrapper。

因此当前选择 milestone / manifest stabilization，而不是新增 `runtime_renderer_adapter_lifecycle.cj`。

## Current Owner Chain

当前 renderer backend no-render tail owner chain：

1. `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_handoff.cj`
2. `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_adapter.cj`
3. `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_contract.cj`
4. `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_capability.cj`
5. `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_adapter_selection.cj`
6. `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_adapter_binding.cj`

## Canonical Endpoint

当前 canonical tail endpoint：

- `CjguiInternalRendererNoRenderBindingReadiness`
- `cjguiInternalExecuteDefaultRendererAdapterBindingDraft()`

该 endpoint 只表示 adapter binding boundary 可继续评估。它不是具体平台 adapter binding，不是 backend object，不是 platform resource permission，不是 render permission，也不是 renderer state write。

## Current Truth

当前 truth 是 renderer backend no-render tail milestone facts：

- renderer packet handoff receipt facts。
- backend adapter candidate / capability placeholder / adapter admission / no-render readiness facts。
- backend contract / capability set / adapter contract admission / no-render contract readiness facts。
- backend capability profile / feature placeholder / constraint profile / no-render capability readiness facts。
- adapter selection policy / candidate family / selection admission / no-render selection readiness facts。
- adapter binding intent / candidate / admission / no-render binding readiness facts。

这些 facts 共同表达：

- future backend adapter runway readiness。
- backend-agnostic facts。
- platform-free facts。
- no-render value facts。
- full rebuild renderer input runway 的 backend tail checkpoint。

它们不表示真实 renderer state，也不授权任何平台资源或绘制执行。

## Explicit Non-Truth

当前 milestone 明确不是：

- platform adapter。
- Metal / AppKit adapter。
- CAMetalLayer / MTLDevice / command buffer。
- native handle / raw pointer / platform object。
- renderer state write。
- render permission。
- draw call / GPU batching / draw-call merge。
- dirty-region / diff / patch / incremental render。
- Widget / Layout / Text / IME / Accessibility / ECS。
- public runtime API / public C ABI。

## Full Rebuild Policy

P1 仍保持 full DisplayList / command list / batching packet rebuild only。

本 milestone 不打开：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental command update。
- incremental batching update。
- partial repaint。
- render cache。
- actual draw-call merge。
- GPU batching。

## Stop-line

继续禁止：

- no runtime code in this milestone round。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no concrete platform capability or adapter promise。
- no render side effect / draw call execution。
- no real draw op semantics。
- no real GPU batching / draw-call merge。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Next Stage Candidate Comparison

### A. P1 internal Renderer backend shell preflight decision

选择。

理由：

- Backend tail 已封账后，下一步应评估是否存在 backend shell / adapter shell 的抽象入口。
- 这能把问题从“继续 no-render readiness 自包”转成“是否需要一个 backend shell owner / vocabulary / stop-line”。
- 仍是 docs-only preflight，不直接写 backend code。
- 不接具体平台对象，不选择 Metal / AppKit。
- 不创建 command buffer、GPU device、native handle 或 renderer state。

### B. P1 internal Renderer platform abstraction preflight decision

可选但暂缓。

该方向可评估 platform abstraction owner / vocabulary，但容易过早靠近 Metal / AppKit、native handle、platform object。建议先做 backend shell preflight，确认是否需要 platform abstraction，以及抽象入口是否必须存在。

### C. P1 internal Renderer command packet validation boundary bundle implementation

可选但暂缓。

该方向回到 render command packet，做 backend-agnostic validation / packet integrity facts，有助于避免继续 backend tail。但当前 backend tail 刚封 milestone，下一步先做 backend shell preflight 更能回答“tail 后是否进入 shell”。

### D. P1 internal Renderer backend tail consolidation bundle implementation

暂缓。

目前未发现明确 dead helper、duplicate projection 或 self-wrapping helper 可安全清理。若 milestone 后发现同构 owner 有可合并或可标注 diagnostics-only 的部分，再进入 consolidation。

### E. Direct adapter lifecycle implementation

拒绝。

除非未来出现真实 lifecycle owner truth，否则 lifecycle 在当前 stop-line 下只会把 binding readiness 包成 lifecycle readiness。当前没有平台资源 acquire / release、backend object、command buffer、native handle、render execution 或 renderer state truth。

### F. Metal / AppKit / CAMetalLayer / command buffer / render execution

拒绝。过早，且会绕过 no-backend / no-render stop-line。

### G. Dirty-region / Widget / Layout / Text / IME / Accessibility / ECS

暂缓。P1 当前仍是 full rebuild renderer input runway，不实现这些系统。

### H. Public surface expansion

拒绝。public allowlist 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer backend shell preflight decision`

下一轮应保持 docs-only，评估 backend shell / adapter shell owner、truth、vocabulary、stop-line 与 implementation readiness。它不批准 backend implementation、Metal / AppKit adapter、CAMetalLayer / MTLDevice、command buffer、native handle / raw pointer、render execution、draw call 或 renderer state write。

## Follow-up Preflight Result

Renderer backend shell preflight 已完成：

- [2026-05-02-p1-renderer-backend-shell-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-shell-preflight-decision.md)

该 preflight 选择：

`P1 internal Renderer backend shell value boundary bundle implementation`

Backend shell 被限定为 future backend adapter 的 internal value shell owner。下一轮若 implementation，应新建 `runtime/cjgui/src/runtime_renderer_backend_shell.cj`，只消费 `CjguiInternalRendererNoRenderBindingReadiness`，表达 shell intent / shell candidate / shell admission / no-render shell readiness facts；不得回到 adapter lifecycle / receipt / record 同构尾巴，也不得接 Metal / AppKit、native handle、command buffer、renderer state write 或 render permission。

## Downstream Backend Shell Boundary

Renderer backend shell value boundary 已落地：

- [2026-05-02-p1-internal-renderer-backend-shell-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-backend-shell-value-boundary-closure-review.md)

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_backend_shell.cj`

当前 downstream endpoint：

- `CjguiInternalRendererBackendNoRenderShellReadiness`
- `cjguiInternalExecuteDefaultRendererBackendShellDraft()`

该 endpoint 只表示 future backend shell boundary 可以继续评估。它新增 shell owner truth / vocabulary / entry contract / no platform shell / no stable backend interface promise facts，因此不是 adapter lifecycle / receipt / record wrapper。下一步应进入 closure / next shell contract decision，而不是继续同构尾巴。

## Packet Integrity Exit

Renderer backend shell next-contract decision 已完成：

- [2026-05-02-p1-renderer-backend-shell-next-contract-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-backend-shell-next-contract-decision.md)

该 decision 没有继续批准 shell contract wrapper，而是选择 `P1 internal Renderer command packet validation boundary bundle implementation`。

Renderer command packet validation boundary 已落地：

- [2026-05-02-p1-internal-renderer-command-packet-validation-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-command-packet-validation-boundary-closure-review.md)

该 boundary 新建 `runtime/cjgui/src/runtime_renderer_command_validation.cj`，只消费 `CjguiInternalRenderBatchingPacket`，把 backend shell tail 的出口转回 command / batching packet integrity gate。它不接平台后端、不写 renderer state、不触发绘制，也不继续 lifecycle / receipt / record 同构尾巴。

Renderer command packet validation manifest 已完成：

- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)

该 manifest 固定 `CjguiInternalRendererCommandValidationResult` / `cjguiInternalExecuteDefaultRendererCommandValidationDraft()` 为 packet integrity canonical endpoint。它确认 validation 是从 backend shell tail 回到 packet integrity 的出口；下一阶段进入 packet normalization preflight，而不是回到 backend shell contract / lifecycle 或 validation receipt / record / publication 同构尾巴。
